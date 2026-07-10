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

echo "Waiting for ACME Issuer ${issuer} to be Ready (registered against Pebble)"
kubectl wait "issuer/${issuer}" -n "${ns}" --for=condition=Ready --timeout=300s

# cert-manager's gateway-shim creates the Certificates asynchronously from the
# Gateway listeners; wait for them to appear before waiting on readiness.
# 3 = gitlab, registry, kas.
expected_certs=3
echo "Waiting for ${expected_certs} Certificate resources to be created"
for _ in $(seq 1 60); do
  count=$(kubectl get certificates -n "${ns}" -o name 2>/dev/null | wc -l)
  [ "${count}" -ge "${expected_certs}" ] && break
  sleep 5
done
kubectl get certificates -n "${ns}"

echo "Waiting for all Certificates to be Ready (ACME HTTP-01 issuance)"
kubectl wait certificates -n "${ns}" --all --for=condition=Ready --timeout=600s

for host in gitlab registry kas; do
  fqdn="${host}-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"
  echo "Verifying served certificate for ${fqdn}"
  # Chain verification against Pebble's issuing root (transcript kept as artifact).
  echo | openssl s_client -connect "${fqdn}:443" -servername "${fqdn}" \
    -CAfile "${issuing_root}" -verify_return_error \
    > "${pki_dir}/s_client-${host}.txt" 2>&1
  # SAN covers the hostname.
  echo | openssl s_client -connect "${fqdn}:443" -servername "${fqdn}" 2>/dev/null \
    | openssl x509 -noout -ext subjectAltName | grep -q "${fqdn}"
  # Transport-level trust as a plain HTTPS client (no --fail: registry/kas
  # return 4xx bodies at /; only certificate validation is asserted here).
  curl -s -o /dev/null --cacert "${issuing_root}" "https://${fqdn}/"
done

echo "cert-manager verification passed: Issuer Ready, Certificates issued, served chains valid"
