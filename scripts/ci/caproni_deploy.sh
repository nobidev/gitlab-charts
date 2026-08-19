#!/bin/bash
# Deploy this checkout's GitLab chart through Caproni and write the VARIABLES_FILE
# consumed by the spec/QA steps later in the same job.
#
# The Caproni counterpart of scripts/ci/k3d_deploy.sh. Caproni owns the cluster and
# the helm invocations, so the external-component and `helm upgrade` steps that
# k3d_deploy.sh performs are declared in scripts/ci/caproni/caproni.yaml instead.
#
# See gitlab-org/charts/gitlab#6505.

set -eo pipefail

source scripts/ci/autodevops.sh
source scripts/ci/k3d.sh
source scripts/ci/lib/caproni.sh

# --- Environment ------------------------------------------------------------------
#
# nip.io over the Docker-in-Docker daemon's address, derived exactly as
# k3d_create does, so that the job container, that daemon, and the cluster's CoreDNS
# all resolve the GitLab and registry hostnames identically. See the comment on
# cluster.network in scripts/ci/caproni/caproni.yaml.
DOCKER_HOST_IP="$(k3d_docker_host_ip)"
export DOCKER_HOST_IP
export KUBE_INGRESS_BASE_DOMAIN="${DOCKER_HOST_IP}.nip.io"

# Empty, unlike the k3d jobs. Each job gets its own cluster, so gitlab.<ip>.nip.io is
# already unique, and an empty suffix is falsy in gitlab.assembleHost, which keeps the
# chart's hostnames equal to cluster.network.hostname in caproni.yaml.
export HOST_SUFFIX=""

# Must match release.name in caproni.yaml. GITLAB_RELEASE_NAME_OVERRIDE is what makes
# gitlab_release_name() - and so every `-lrelease=` selector in autodevops.sh - agree
# with the name Caproni actually installs under.
export GITLAB_RELEASE_NAME_OVERRIDE="${GITLAB_RELEASE_NAME_OVERRIDE:-gitlab}"

echo "CI_COMMIT_SHORT_SHA=${CI_COMMIT_SHORT_SHA}"
echo "DOCKER_HOST_IP=${DOCKER_HOST_IP}"
echo "KUBE_INGRESS_BASE_DOMAIN=${KUBE_INGRESS_BASE_DOMAIN}"
echo "KUBE_NAMESPACE=${KUBE_NAMESPACE}"
echo "NAMESPACE=${NAMESPACE}"
echo "K3D_K8S_IMAGE=${K3D_K8S_IMAGE}"
echo "GITLAB_RELEASE_NAME=$(gitlab_release_name)"
echo "VARIABLES_FILE=${VARIABLES_FILE}"
echo "KUBECONFIG=${KUBECONFIG}"

mkdir -p "$(dirname "${VARIABLES_FILE}")"

# --- Chart and values -------------------------------------------------------------
#
# Caproni never runs `helm dependency update`, and gateway-helm is a Chart.yaml
# dependency conditional on global.gatewayApi.installEnvoy, which this environment
# enables. Without this the chart cannot render.
echo "Updating chart dependencies..."
helm dependency update .

prepare_values
caproni_merge_values

# --- Cluster, external dependencies, and the chart --------------------------------
#
# One command: k3d cluster, the CloudNativePG operator, gitlab-dev-stack, and the
# chart from ${CI_PROJECT_DIR}. Exits non-zero if any deployer fails.
echo "Bringing up the Caproni environment..."
caproni --debug --config-file "${CAPRONI_DIR}/caproni.yaml" up

# --- Kubeconfig -------------------------------------------------------------------
#
# `caproni kubectl` wraps its own temporary kubeconfig, but spec/spec_helper.rb, the
# helpers in spec/gitlab_test_helper.rb and k3d_collect_debug all shell out to bare
# kubectl, so they need a real one. Written via a temp file rather than redirecting
# straight onto ${KUBECONFIG}, so k3d is never reading a file it is also truncating.
#
# The cluster name is the literal "caproni" because caproni.yaml pins
# cluster.name.strategy to static.
echo "Exporting kubeconfig for bare kubectl..."
k3d kubeconfig get caproni > /tmp/caproni-kubeconfig.raw.yaml
mv /tmp/caproni-kubeconfig.raw.yaml "${KUBECONFIG}"
# The chart is not in the `default` namespace here, and the call sites above mostly
# invoke kubectl without -n, so the context namespace has to carry it.
kubectl config set-context --current --namespace="${NAMESPACE}"
kubectl version --output=json
kubectl get nodes

# --- Envoy Gateway readiness ------------------------------------------------------
#
# Verbatim from k3d_deploy.sh, minus the use_nginx_ingress guard: this environment is
# always Gateway API. Without the wait, tests can start before the escaped-slash
# policy takes effect and API paths containing %2F (root%2Fproject) return 307/404.
echo "Waiting for ClientTrafficPolicy reconciliation (up to 120s)..."
kubectl wait clienttrafficpolicies.gateway.envoyproxy.io \
  --for=condition=Accepted \
  --all \
  -n "${NAMESPACE}" \
  --timeout=120s \
  && echo "ClientTrafficPolicy accepted." \
  || echo "Warning: ClientTrafficPolicy not yet accepted - proceeding anyway."

# --- Post-deploy credentials ------------------------------------------------------
#
# The k3d path pre-creates the root password and license Secrets before installing.
# Caproni has no pre-deploy hook that carries a kubeconfig, so instead the chart
# generates the root password and we read it back, and the license is applied through
# the toolbox pod afterwards.
echo "Reading the chart-generated root password..."
ROOT_PASSWORD="$(kubectl get secret -n "${NAMESPACE}" \
  "$(gitlab_release_name)-gitlab-initial-root-password" \
  -o jsonpath='{.data.password}' | base64 -d)"
if [ -z "${ROOT_PASSWORD}" ]; then
  echo "ERROR: could not read $(gitlab_release_name)-gitlab-initial-root-password"
  exit 1
fi

caproni_activate_license

_admin_pat=$(create_admin_pat)
if [ -z "${_admin_pat}" ]; then
  echo "ERROR: create_admin_pat returned empty - cannot proceed without admin token"
  exit 1
fi

# --- Variables file ---------------------------------------------------------------
#
# Same contract as variables/k3d_deploy, so run_specs.sh, spec/ and the QA template
# need no Caproni-specific handling. Hostnames have no -${HOST_SUFFIX} infix here.
{
  echo "export KUBECONFIG=${KUBECONFIG}"
  echo "export GITLAB_RELEASE_NAME=$(gitlab_release_name)"
  echo "export GITLAB_URL=gitlab.${KUBE_INGRESS_BASE_DOMAIN}"
  echo "export GITLAB_ROOT_DOMAIN=${KUBE_INGRESS_BASE_DOMAIN}"
  echo "export REGISTRY_URL=registry.${KUBE_INGRESS_BASE_DOMAIN}"
  echo "export PROTOCOL=$(external_protocol)"
  echo "export ROOT_PASSWORD=${ROOT_PASSWORD}"
  # .specs resolves GITLAB_PASSWORD from the CI variable at job-setup time; re-export
  # so it tracks the password the chart actually generated.
  echo "export GITLAB_PASSWORD=${ROOT_PASSWORD}"
  # The CI/CD GITLAB_QA_ADMIN_ACCESS_TOKEN belongs to another instance; export the
  # fresh PAT so the QA job can re-export it.
  echo "export GITLAB_ADMIN_TOKEN=${_admin_pat}"
} >> "${VARIABLES_FILE}"

# On stable branches use VERSION (e.g. 19.0.4-ee), whose image tags the release
# pipeline preserves. On master and feature branches use REVISION (short SHA).
if [[ "${CI_COMMIT_BRANCH}" =~ -stable$ ]] || [[ "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}" =~ -stable$ ]]; then
  echo "export QA_GITLAB_VERSION=$(get_qa_version)"   >> "${VARIABLES_FILE}"
else
  echo "export QA_GITLAB_REVISION=$(get_qa_revision)" >> "${VARIABLES_FILE}"
fi

echo "Caproni environment ready at $(external_protocol)://gitlab.${KUBE_INGRESS_BASE_DOMAIN}"
