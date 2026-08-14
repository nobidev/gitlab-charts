#!/bin/bash
# Verifies the chart's cert-manager integration end-to-end after an HTTPS k3d
# deploy: the ACME Issuer registers against Pebble, Certificates are issued via
# HTTP-01, and the certificates actually served on :443 chain to Pebble's
# issuing root and cover the expected hostnames.
# Requires: KUBECONFIG, NAMESPACE, HOST_SUFFIX, KUBE_INGRESS_BASE_DOMAIN, and
# pebble-pki/issuing-root.pem (fetched by scripts/ci/lib/pebble.sh).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "${SCRIPT_DIR}/lib/helpers.sh"

ns="${NAMESPACE:-default}"
release="$(gitlab_release_name)"
pki_dir="${CI_PROJECT_DIR:-$(pwd)}/pebble-pki"
issuing_root="${pki_dir}/issuing-root.pem"

if [ ! -f "${issuing_root}" ]; then
  echo "ERROR: ${issuing_root} not found (deploy_pebble must run first)"
  exit 1
fi

# Gateway API path only: k3d NGINX deployments are forced to HTTP (k3d_deploy.sh).
issuer="${release}-gw-issuer"

# Poll and wait budgets, overridable for slower clusters or manual runs.
ISSUER_READY_TIMEOUT="${ISSUER_READY_TIMEOUT:-300s}"
CERT_CREATE_RETRIES="${CERT_CREATE_RETRIES:-60}"
CERT_CREATE_INTERVAL="${CERT_CREATE_INTERVAL:-5}"
CERT_READY_TIMEOUT="${CERT_READY_TIMEOUT:-600s}"

echo "Waiting for ACME Issuer ${issuer} to be Ready (registered against Pebble)"
kubectl wait "issuer/${issuer}" -n "${ns}" --for=condition=Ready --timeout="${ISSUER_READY_TIMEOUT}"

# cert-manager's gateway-shim creates the Certificates asynchronously from the
# Gateway listener certificateRefs; wait for each expected one by name so an
# unrelated Certificate in the namespace can never mask a missing one.
expected_certs="gitlab-tls registry-tls kas-tls"
echo "Waiting for Certificates to be created: ${expected_certs}"
missing=""
for _ in $(seq 1 "${CERT_CREATE_RETRIES}"); do
  missing=""
  for cert in ${expected_certs}; do
    kubectl get "certificate/${cert}" -n "${ns}" >/dev/null 2>&1 || missing="${missing} ${cert}"
  done
  [ -z "${missing}" ] && break
  sleep "${CERT_CREATE_INTERVAL}"
done
kubectl get certificates -n "${ns}" || true
if [ -n "${missing}" ]; then
  echo "ERROR: Certificate(s) not created within $((CERT_CREATE_RETRIES * CERT_CREATE_INTERVAL))s:${missing}"
  echo "cert-manager's gateway-shim may not be running, or the Gateway listeners/issuer annotation are misconfigured."
  exit 1
fi

echo "Waiting for all Certificates to be Ready (ACME HTTP-01 issuance)"
kubectl wait certificates -n "${ns}" --all --for=condition=Ready --timeout="${CERT_READY_TIMEOUT}"

for host in gitlab registry kas; do
  fqdn="${host}-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"
  echo "Verifying served certificate for ${fqdn}"
  # Chain verification against Pebble's issuing root, and RFC 6125 matching of
  # the leaf's SANs — one handshake; transcript kept as artifact.
  echo | openssl s_client -connect "${fqdn}:443" -servername "${fqdn}" \
    -CAfile "${issuing_root}" -verify_hostname "${fqdn}" -verify_return_error \
    > "${pki_dir}/s_client-${host}.txt" 2>&1
  # Transport-level trust as a plain HTTPS client (no --fail: registry/kas
  # return 4xx bodies at /; only certificate validation is asserted here).
  curl -s -o /dev/null --cacert "${issuing_root}" "https://${fqdn}/"
done

echo "cert-manager verification passed: Issuer Ready, Certificates issued, served chains valid"
