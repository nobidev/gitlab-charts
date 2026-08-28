#!/bin/bash

# Sourced from scripts/ci/autodevops.sh. So we should not set flags, like
# `set -eo...`, as it impacts the caller shell.
#
# Holds the chart-install, wait-for-readiness, teardown, and helper
# functions that scripts/ci/autodevops.sh previously embedded inline.
# Keeping them in a library lets a developer source this file alone and
# call a single function (deploy_chart, wait_for_pods, teardown) without
# pulling in the full orchestrator.
#
# Required env (set by caller or main() in autodevops.sh):
#   NAMESPACE                  Target kubectl namespace.
#   KUBE_INGRESS_BASE_DOMAIN   For non-k3d deployments only.
# Optional env:
#   ARTIFACTS_DIR              Where rendered values land. Default: per
#                              lib/helpers.sh ($CI_PROJECT_DIR or pwd).
#   HELM_EXTRA_ARGS            Forwarded verbatim to `helm upgrade`.
#   TRACE                      `set -x` for verbose tracing.

# SCRIPT_DIR/PROJECT_ROOT are derived from THIS file's location, so the lib
# stays portable regardless of who sources it.
_DEPLOY_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="${SCRIPT_DIR:-${_DEPLOY_LIB_DIR}/..}"
PROJECT_ROOT="${PROJECT_ROOT:-${_DEPLOY_LIB_DIR}/../../..}"
VALUES_DIR="${VALUES_DIR:-${ARTIFACTS_DIR:-${CI_PROJECT_DIR:-${PROJECT_ROOT}}}/.values}"

# deploy_chart renders the values stack and runs `helm upgrade --install`.
# Historical name `deploy` is kept as an alias for existing CI YAML callers.
function deploy_chart() {
  if [ -z "${NAMESPACE}" ]; then
    echo "Error: NAMESPACE is not set"
    return 1
  fi

  helm dependency update "${PROJECT_ROOT}"
  prepare_values

  # CI-only side effects: pre-create the root-password + license Secrets so
  # the chart picks them up. Locally the developer is expected to create the
  # equivalent Secrets out-of-band (see doc/development/local_cluster.md) —
  # we don't have $ROOT_PASSWORD or $QA_EE_ACTIVATION_CODE in the ambient env.
  if is_ci_deployment; then
    echo "CI deployment detected — pre-creating root-password + license Secrets"
    kubectl create secret generic -n "${NAMESPACE}" "$(gitlab_release_name)-gitlab-initial-root-password" \
      --from-literal=password="$ROOT_PASSWORD" -o yaml --dry-run=client \
      | kubectl replace --force -f -

    kubectl create secret generic -n "${NAMESPACE}" "$(gitlab_release_name)-gitlab-license" \
      --from-literal=license="$QA_EE_ACTIVATION_CODE" -o yaml --dry-run=client \
      | kubectl replace --force -f -
  fi

  # Values stack: the same ci-base / ci-scale / ci-license overlays CI uses
  # also drive local k3d deploys (KUBE_INGRESS_BASE_DOMAIN, HOST_SUFFIX, and
  # GITLAB_RELEASE_NAME are envsubst'd by prepare_values for both contexts).
  # ci.digests.yaml is produced by scripts/ci/pin_image_digests.sh and
  # layered only if the developer/CI generated it.
  local CI_CONFIGURATION="-f ${VALUES_DIR}/ci-base.values.yaml -f ${VALUES_DIR}/ci-scale.values.yaml -f ${VALUES_DIR}/ci-license.values.yaml"
  if [ -f "${PROJECT_ROOT}/ci.digests.yaml" ]; then
    CI_CONFIGURATION="${CI_CONFIGURATION} -f ${PROJECT_ROOT}/ci.digests.yaml"
  elif is_ci_deployment; then
    echo "WARNING: ci.digests.yaml not found in PROJECT_ROOT — image digests will not be pinned." >&2
  fi

  # One overlay per (controller, protocol) pair. external_protocol defaults to
  # http for k3d and https elsewhere; see lib/helpers.sh.
  local NETWORKING_CONFIGURATION
  if use_nginx_ingress; then
    echo "Exposing GitLab via NGINX Ingress in $(external_protocol) mode"
    NETWORKING_CONFIGURATION="-f ${VALUES_DIR}/ingress-$(external_protocol).values.yaml"
  else
    echo "Exposing GitLab via Gateway API in $(external_protocol) mode"
    NETWORKING_CONFIGURATION="-f ${VALUES_DIR}/gatewayapi-$(external_protocol).values.yaml"
  fi

  local SENTRY_CONFIGURATION=""
  if [ -n "${REVIEW_APPS_SENTRY_DSN}" ] && [ -n "${REVIEW_APPS_SENTRY_ENVIRONMENT}" ]; then
    echo "Sentry deployment detected"
    SENTRY_CONFIGURATION="-f ${VALUES_DIR}/sentry.values.yaml"
  fi

  # Postgres, Valkey, and object storage always come from the gitlab-dev-stack
  # umbrella release (scripts/ci/lib/dev_stack.sh). This overlay points the
  # GitLab chart at the *-conn Secrets and Services that release emits.
  local DEV_STACK_CONFIGURATION="-f ${VALUES_DIR}/dev-stack.values.yaml"

  helm upgrade --install \
    --wait --timeout 900s \
    ${CI_CONFIGURATION} \
    ${SENTRY_CONFIGURATION} \
    ${NETWORKING_CONFIGURATION} \
    ${DEV_STACK_CONFIGURATION} \
    --namespace="$NAMESPACE" \
    $HELM_EXTRA_ARGS \
    "$(gitlab_release_name)" \
    "${PROJECT_ROOT}"
}

# Alias preserved for existing CI YAML and k3d_deploy.sh.
function deploy() { deploy_chart "$@"; }

function prepare_values() {
  mkdir -p "${VALUES_DIR}"

  local values_src="${SCRIPT_DIR}/values/gitlab-chart"
  if [ ! -d "${values_src}" ]; then
    # Fall back to the cwd-relative path the script historically used —
    # CI runs from $CI_PROJECT_DIR where this matches.
    values_src="./scripts/ci/values/gitlab-chart"
  fi

  for f in "${values_src}"/*; do
    env \
      GITLAB_RELEASE_NAME="$(gitlab_release_name)" \
      DEV_STACK_RELEASE_NAME="$(dev_stack_release_name)" \
      NAMESPACE="${NAMESPACE}" \
        envsubst < "$f" > "${VALUES_DIR}/$(basename "$f")"
  done
}

function check_kas_status() {
  local iteration=0
  local kasState=""

  while [ "${kasState[1]}" != "Running" ]; do
    if [ $iteration -eq 0 ]; then
      echo ""
      echo -n "Waiting for KAS deploy to complete.";
    else
      echo -n "."
    fi

    iteration=$((iteration+1))
    kasState=($(kubectl get pods -n "$NAMESPACE" -lrelease=$(gitlab_release_name),app=kas | awk '{print $3}'))
    sleep 5;
  done
}

# wait_for_pods polls for webservice + kas Pods to reach Running.
# Historical name `wait_for_deploy` kept as an alias.
function wait_for_pods {
  local iteration=0

  # Watch for a `webservice` Pod to come online.
  local webserviceState=0
  while [ "$webserviceState" -lt 2 ]; do
    # This will always return at least one line, `NAME`
    webserviceState=($(kubectl get pods -n "$NAMESPACE" -lrelease=$(gitlab_release_name),app=webservice --field-selector status.phase=Running -o=custom-columns=NAME:.metadata.name | wc -l))
    if [ $iteration -eq 0 ]; then
      echo -n "Waiting for deploy to complete.";
    else
      echo -n "."
    fi
    sleep 5;
  done

  check_kas_status

  echo ""
}

function wait_for_deploy() { wait_for_pods "$@"; }

function ensure_namespace() {
  kubectl describe namespace "$NAMESPACE" || kubectl create namespace "$NAMESPACE"
}

function set_context() {
  if is_k3d_deployment; then
    echo "K3D_MODE: using local k3d kubeconfig (${KUBECONFIG})"
    return
  fi
  if [ -z ${AGENT_NAME+x} ] || [ -z ${AGENT_PROJECT_PATH+x} ]; then
    echo "No AGENT_NAME or AGENT_PROJECT_PATH set, using the default"
  else
    kubectl config get-contexts
    kubectl config use-context ${AGENT_PROJECT_PATH}:${AGENT_NAME}
    kubectl config set-context --current --namespace=${NAMESPACE}
  fi
}

function check_kube_domain() {
  if [ -z ${KUBE_INGRESS_BASE_DOMAIN+x} ]; then
    echo "ERROR: In order to deploy, KUBE_INGRESS_BASE_DOMAIN must be set as a variable at the group or project level, or manually added in .gitlab-ci.yml"
    false
  else
    true
  fi
}

function check_domain_ip() {
  # Expect the `DOMAIN` is a wildcard.
  domain_ip=$(getent hosts gitlab$DOMAIN 2>/dev/null | awk '{print $1}')

  if [ -z $domain_ip ]; then
    echo "ERROR: There was a problem resolving the IP of 'gitlab$DOMAIN'. Be sure you have configured a DNS entry."
    false
  else
    export DOMAIN_IP=$domain_ip
    echo "Found IP for gitlab$DOMAIN: $DOMAIN_IP"
    true
  fi
}

# teardown is the umbrella for `delete` + `cleanup` — uninstall the release
# and sweep any stray namespaced resources still labelled with the
# release_name_base prefix. Historical names kept as aliases.
function teardown() {
  delete
  cleanup
}

function delete() {
  helm uninstall "$(gitlab_release_name)" || true
}

function cleanup() {
  kubectl -n "$NAMESPACE" delete --ignore-not-found=true \
    $(get_resources "ingress,svc,pdb,hpa,deploy,statefulset,replicaset,job,pod,secret,configmap,clusterrole,clusterrolebinding,role,rolebinding,sa") \
    || true

  pvcs=$(get_resources "pvc")
  for pvc in ${pvcs}; do
    pv=$(kubectl -n "$NAMESPACE" get pvc "$pvc" -o jsonpath='{.spec.volumeName}' 2>&1)
    volumeHandle=$(kubectl get pv "$pv" -o jsonpath='{.spec.csi.volumeHandle}' 2>&1)
    # Delete PVC only, PV and volume should be handled by reclaim policy
    echo "Deleting $pvc (PV: $pv, CSI volume: $volumeHandle)"
    kubectl -n "$NAMESPACE" delete pvc "$pvc" || true
  done
}

function get_resources() {
  kubectl -n "$NAMESPACE" get "$1" --no-headers 2>&1 \
    | grep "$(release_name_base)" \
    | awk '{print $1}' \
    | xargs
}

function wait_for_toolbox() {
  kubectl wait pods -n "${NAMESPACE}" -l app=toolbox,release="$(gitlab_release_name)" --for condition=Ready --timeout=60s
}

function get_qa_revision() {
  wait_for_toolbox >/dev/null
  toolbox_pod=$(kubectl get pods -lrelease="$(gitlab_release_name)",app=toolbox -o custom-columns=":metadata.name" --no-headers | tr -d '[:space:]')
  kubectl exec -n "${NAMESPACE}" "${toolbox_pod}" -ic toolbox -- cat /srv/gitlab/REVISION
}

# Reads the full GitLab version string (e.g. "19.0.4-ee") from the toolbox pod.
# Used on stable branches where version-tagged QA images are preserved,
# unlike short-lived REVISION-tagged images which may be cleaned up.
function get_qa_version() {
  wait_for_toolbox >/dev/null
  toolbox_pod=$(kubectl get pods -lrelease="$(gitlab_release_name)",app=toolbox -o custom-columns=":metadata.name" --no-headers | tr -d '[:space:]')
  kubectl exec -n "${NAMESPACE}" "${toolbox_pod}" -ic toolbox -- cat /srv/gitlab/VERSION | tr -d '[:space:]'
}

function create_admin_pat() {
  wait_for_toolbox >/dev/null
  local toolbox_pod runner_output token
  toolbox_pod=$(kubectl get pods -n "${NAMESPACE}" -lrelease="$(gitlab_release_name)",app=toolbox -o custom-columns=":metadata.name" --no-headers | tr -d '[:space:]')
  runner_output=$(kubectl exec -n "${NAMESPACE}" "${toolbox_pod}" -ic toolbox -- \
    gitlab-rails runner "
      u = User.find_by_username('root')
      t = u.personal_access_tokens.create!(
        name: 'k3d-qa-admin',
        scopes: [:api],
        expires_at: 1.day.from_now
      )
      puts t.token
    " 2>&1)
  # GitLab 17+ PAT tokens include a routing suffix with dots, e.g. glpat-xxx.01.yyy
  # Match the full token including dots to avoid truncating it.
  token=$(echo "${runner_output}" | grep -oE 'glpat-[A-Za-z0-9._-]+')
  if [ -z "${token}" ]; then
    echo "create_admin_pat: ERROR: no glpat- token found in runner output" >&2
    echo "${runner_output}" >&2
    return 1
  fi
  echo "${token}"
}
