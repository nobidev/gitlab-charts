#!/bin/bash

# Sourced from scripts/ci/autodevops.sh. So we should not set flags, like `set -eo...`, as it impacts the caller shell.

# Pebble is Let's Encrypt's miniature ACME test server, used by cert-manager's
# own e2e suite. It runs inside the k3d cluster so the chart's cert-manager
# ACME integration can be exercised end-to-end without a public IP: Pebble's
# HTTP-01 validation request originates in-cluster and reaches the Gateway
# through the nip.io hostname mapped to the k3d loadbalancer.
#
# Deployed via the jupyterhub/pebble-helm-chart, which also generates Pebble's
# ACME API TLS leaf at pod start, signed by a STATIC root shipped in the
# chart's ConfigMap (key root-cert.pem) — that root is what cert-manager
# mounts as SSL_CERT_FILE (see gatewayapi-https-k3d.values.yaml). The root's
# private key is public upstream: CI-only trust, never for anything real.
#
# See: https://github.com/letsencrypt/pebble
#      https://github.com/jupyterhub/pebble-helm-chart

PEBBLE_CHART_REPO="${PEBBLE_CHART_REPO:-https://jupyterhub.github.io/helm-chart/}"
PEBBLE_CHART_VERSION="${PEBBLE_CHART_VERSION:-1.5.0}"

function pebble_pki_dir() {
  echo -n "${CI_PROJECT_DIR:-$(pwd)}/pebble-pki"
}

# True when the file parses as an X.509 certificate. Used instead of grepping for
# the PEM header, which also passes on a body truncated mid-transfer.
function pebble_pem_is_cert() {
  openssl x509 -noout -in "${1}" >/dev/null 2>&1
}

function deploy_pebble() {
  # HOST_SUFFIX and KUBE_INGRESS_BASE_DOMAIN name the Secret key the runner
  # looks up, so an empty one fails much later and less obviously.
  if [ -z "${NAMESPACE}" ] || [ -z "${HOST_SUFFIX}" ] || [ -z "${KUBE_INGRESS_BASE_DOMAIN}" ]; then
    echo "ERROR: NAMESPACE, HOST_SUFFIX and KUBE_INGRESS_BASE_DOMAIN must all be set" \
         "(NAMESPACE='${NAMESPACE}' HOST_SUFFIX='${HOST_SUFFIX}'" \
         "KUBE_INGRESS_BASE_DOMAIN='${KUBE_INGRESS_BASE_DOMAIN}')"
    exit 1
  fi

  local pki_dir
  pki_dir="$(pebble_pki_dir)"
  mkdir -p "${pki_dir}"

  echo "Installing Pebble (in-cluster ACME test server)"
  # - coredns disabled: challenge lookups go through regular cluster DNS,
  #   which resolves the nip.io hostnames fine. The chart's bundled CoreDNS
  #   (with an injectable corefileSegment) remains the supported fallback if
  #   that path ever proves flaky.
  # - nodePorts nulled: renders a plain ClusterIP Service; per-job k3d
  #   clusters have no use for host ports.
  helm upgrade --install pebble pebble \
    --repo "${PEBBLE_CHART_REPO}" \
    --version "${PEBBLE_CHART_VERSION}" \
    -n "${NAMESPACE}" \
    --set coredns.enabled=false \
    --set pebble.nodePort=null \
    --set pebble.mgmtNodePort=null \
    --wait --timeout 180s

  # Local copy of the chart's static API root, used to verify the management
  # API below. The leaf's SANs include localhost/127.0.0.1, so a plain
  # port-forward fetch verifies without hostname tricks.
  kubectl get configmap pebble -n "${NAMESPACE}" \
    -o jsonpath="{.data['root-cert\.pem']}" > "${pki_dir}/root-cert.pem"
  if ! pebble_pem_is_cert "${pki_dir}/root-cert.pem"; then
    echo "ERROR: configmap/pebble in ${NAMESPACE} has no parseable root-cert.pem"
    exit 1
  fi

  pebble_fetch_issuing_root
}

# Pebble regenerates its issuing root on every process start, so it can only be
# fetched at runtime (management API /roots/0). It is the trust anchor for:
# - global.certificates.customCAs (GitLab pods trusting their own external URL)
# - gitlab-runner.certsSecretName (runner registration; the key must be named
#   <gitlab-hostname>.crt per the runner chart's self-signed cert convention)
# - the job shell (SSL_CERT_FILE for RSpec) and scripts/ci/verify_certmanager.sh
function pebble_fetch_issuing_root() {
  local pki_dir root_pem pf_pid fetched
  pki_dir="$(pebble_pki_dir)"
  root_pem="${pki_dir}/issuing-root.pem"

  echo "Fetching Pebble's dynamically-generated issuing root CA"
  kubectl port-forward -n "${NAMESPACE}" svc/pebble 8444:8444 >/dev/null 2>&1 &
  pf_pid=$!

  fetched=false
  for _ in $(seq 1 30); do
    if curl -sf --cacert "${pki_dir}/root-cert.pem" \
         "https://localhost:8444/roots/0" -o "${root_pem}" \
       && pebble_pem_is_cert "${root_pem}"; then
      fetched=true
      break
    fi
    sleep 2
  done
  kill "${pf_pid}" 2>/dev/null || true

  if [ "${fetched}" != "true" ]; then
    echo "ERROR: could not fetch Pebble issuing root from the management API (/roots/0)"
    exit 1
  fi

  kubectl create secret generic pebble-issuing-ca -n "${NAMESPACE}" \
    --from-file=pebble-issuing-ca.crt="${root_pem}" \
    --from-file="gitlab-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}.crt"="${root_pem}" \
    --dry-run=client -o yaml | kubectl apply -f -
}

function remove_pebble() {
  echo "Removing Pebble"
  helm uninstall pebble -n "${NAMESPACE}" --ignore-not-found
  kubectl delete secret pebble-issuing-ca -n "${NAMESPACE}" --ignore-not-found
}
