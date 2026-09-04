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
  #
  # NOTE: `kubectl wait --for=condition=Accepted` cannot work here because
  # ClientTrafficPolicy uses Gateway API PolicyStatus, which reports conditions
  # under .status.ancestors[].conditions — not at the top-level .status.conditions
  # that kubectl wait inspects.  We poll the ancestor conditions directly instead.
  echo "Waiting for ClientTrafficPolicy reconciliation (up to 120s)..."
  _ctp_deadline=$(( $(date +%s) + 120 ))
  _ctp_result="timeout"
  while [ "$(date +%s)" -lt "${_ctp_deadline}" ]; do
    # ClientTrafficPolicy resources are created declaratively by the Helm
    # release itself (already applied above), so if none exist at all there
    # is nothing to poll for — only their *status* is filled in
    # asynchronously by the Envoy Gateway controller.
    _ctp_names=$(kubectl get clienttrafficpolicies.gateway.envoyproxy.io \
      -n "${NAMESPACE}" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || true)
    if [ -z "${_ctp_names}" ]; then
      _ctp_result="none"
      break
    fi
    _ctp_statuses=$(kubectl get clienttrafficpolicies.gateway.envoyproxy.io \
      -n "${NAMESPACE}" \
      -o jsonpath='{.items[*].status.ancestors[*].conditions[?(@.type=="Accepted")].status}' \
      2>/dev/null || true)
    # All policies must report "True"; there must be at least one.
    # jsonpath renders multiple matches space-separated on one line, so
    # split on whitespace and match each value exactly.
    if [ -n "${_ctp_statuses}" ] && \
       ! echo "${_ctp_statuses}" | tr ' ' '\n' | grep -qv '^True$'; then
      _ctp_result="accepted"
      break
    fi
    sleep 5
  done
  case "${_ctp_result}" in
    accepted) echo "ClientTrafficPolicy accepted." ;;
    none) echo "No ClientTrafficPolicy resources found; skipping reconciliation wait." ;;
    *) echo "Warning: ClientTrafficPolicy not yet accepted — proceeding anyway." ;;
  esac
fi

echo "export GITLAB_RELEASE_NAME=$(gitlab_release_name)"                          >> "${VARIABLES_FILE}"
echo "export GITLAB_URL=gitlab-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"        >> "${VARIABLES_FILE}"
echo "export GITLAB_ROOT_DOMAIN=${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"       >> "${VARIABLES_FILE}"
echo "export REGISTRY_URL=registry-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"    >> "${VARIABLES_FILE}"
# On stable branches, use VERSION (e.g. 19.0.4-ee) — those image tags are preserved
# by the release pipeline. On master/feature branches, use REVISION (short SHA).
if [[ "${CI_COMMIT_BRANCH}" =~ -stable$ ]] || [[ "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}" =~ -stable$ ]]; then
  echo "export QA_GITLAB_VERSION=$(get_qa_version)"                                 >> "${VARIABLES_FILE}"
else
  echo "export QA_GITLAB_REVISION=$(get_qa_revision)"                               >> "${VARIABLES_FILE}"
fi
echo "export PROTOCOL=$(external_protocol)"                                       >> "${VARIABLES_FILE}"

_admin_pat=$(create_admin_pat)
if [ -z "${_admin_pat}" ]; then
  echo "ERROR: create_admin_pat returned empty — cannot proceed without admin token"
  exit 1
fi
# The CI/CD GITLAB_QA_ADMIN_ACCESS_TOKEN belongs to the shared vcluster instance;
# export the fresh PAT as GITLAB_ADMIN_TOKEN so the QA job can re-export it.
echo "export GITLAB_ADMIN_TOKEN=${_admin_pat}"                                     >> "${VARIABLES_FILE}"
