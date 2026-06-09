#!/bin/bash
# Deploy GitLab chart to a k3d cluster and write the VARIABLES_FILE consumed
# by downstream spec/QA steps within the same job.

source scripts/ci/autodevops.sh
source scripts/ci/k3d.sh

echo "CI_COMMIT_SHORT_SHA=${CI_COMMIT_SHORT_SHA}"
echo "HOST_SUFFIX=${HOST_SUFFIX}"
echo "KUBE_INGRESS_BASE_DOMAIN=${KUBE_INGRESS_BASE_DOMAIN}"
echo "VARIABLES_FILE=${VARIABLES_FILE}"
echo "KUBE_NAMESPACE=${KUBE_NAMESPACE}"
echo "NAMESPACE=${NAMESPACE}"
echo "K3D_K8S_IMAGE=${K3D_K8S_IMAGE}"

mkdir -p "$(dirname "${VARIABLES_FILE}")"

deploy_external_components
deploy
wait_for_deploy
# check_domain_ip is skipped: nip.io resolves immediately without DNS propagation

if ! use_nginx_ingress; then
  # Wait for ClientTrafficPolicy resources to be reconciled by the Envoy Gateway
  # controller before running tests.  Without this, there is a race where tests
  # start before the escaped-slash policy takes effect, causing 307/404 errors on
  # API paths that include %2F (e.g. root%2Fproject).
  echo "Waiting for ClientTrafficPolicy reconciliation (up to 120s)..."
  kubectl wait clienttrafficpolicies.gateway.envoyproxy.io \
    --for=condition=Accepted \
    --all \
    -n "${NAMESPACE}" \
    --timeout=120s \
    && echo "ClientTrafficPolicy accepted." \
    || echo "Warning: ClientTrafficPolicy not yet accepted — proceeding anyway."
fi

echo "export GITLAB_RELEASE_NAME=$(gitlab_release_name)"                          >> "${VARIABLES_FILE}"
echo "export GITLAB_URL=gitlab-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"        >> "${VARIABLES_FILE}"
echo "export GITLAB_ROOT_DOMAIN=${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"       >> "${VARIABLES_FILE}"
echo "export REGISTRY_URL=registry-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"    >> "${VARIABLES_FILE}"
echo "export QA_GITLAB_REVISION=$(get_qa_revision)"                               >> "${VARIABLES_FILE}"
echo "export PROTOCOL=$(external_protocol)"                                       >> "${VARIABLES_FILE}"

_admin_pat=$(create_admin_pat)
if [ -z "${_admin_pat}" ]; then
  echo "ERROR: create_admin_pat returned empty — cannot proceed without admin token"
  exit 1
fi
# The CI/CD GITLAB_QA_ADMIN_ACCESS_TOKEN belongs to the shared vcluster instance;
# export the fresh PAT as GITLAB_ADMIN_TOKEN so the QA job can re-export it.
echo "export GITLAB_ADMIN_TOKEN=${_admin_pat}"                                     >> "${VARIABLES_FILE}"
