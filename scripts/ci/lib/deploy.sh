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

function deploy_external_components() {
  if use_dev_stack; then
    deploy_dev_stack
    return
  fi

  if use_external_valkey; then
    deploy_external_valkey
  fi

  if use_external_postgresql; then
    deploy_external_postgresql
  fi

  if use_external_garage; then
      deploy_external_garage
  fi
}

function remove_external_components() {
  if use_dev_stack; then
    remove_dev_stack
    return
  fi

  if use_external_valkey; then
    remove_external_valkey
  fi

  if use_external_postgresql; then
    remove_external_postgresql
  fi

  if use_external_garage; then
      remove_external_garage
  fi
}

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
  # we don't have $ROOT_PASSWORD or $QA_EE_LICENSE in the ambient env.
  if is_ci_deployment; then
    echo "CI deployment detected — pre-creating root-password + license Secrets"
    kubectl create secret generic -n "${NAMESPACE}" "$(gitlab_release_name)-gitlab-initial-root-password" \
      --from-literal=password="$ROOT_PASSWORD" -o yaml --dry-run=client \
      | kubectl replace --force -f -

    kubectl create secret generic -n "${NAMESPACE}" "$(gitlab_release_name)-gitlab-license" \
      --from-literal=license="$QA_EE_LICENSE" -o yaml --dry-run=client \
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

  local NETWORKING_CONFIGURATION
  if is_k3d_deployment; then
    echo "K3D deployment detected"
    if [ -n "${K3D_USE_NGINX_INGRESS}" ]; then
      echo "K3D_USE_NGINX_INGRESS set: using NGINX ingress"
      NETWORKING_CONFIGURATION="-f ${VALUES_DIR}/k3d.ingress.values.yaml"
    else
      echo "Using Envoy Gateway API (default for k3d)"
      NETWORKING_CONFIGURATION="-f ${VALUES_DIR}/k3d.gatewayapi.values.yaml"
    fi
  else
    NETWORKING_CONFIGURATION="-f ${VALUES_DIR}/gatewayapi.values.yaml"
    if use_nginx_ingress; then
      echo "NGINX Ingress deployment detected"
      NETWORKING_CONFIGURATION="-f ${VALUES_DIR}/ingress.values.yaml"
    fi
  fi

  local SENTRY_CONFIGURATION=""
  if [ -n "${REVIEW_APPS_SENTRY_DSN}" ] && [ -n "${REVIEW_APPS_SENTRY_ENVIRONMENT}" ]; then
    echo "Sentry deployment detected"
    SENTRY_CONFIGURATION="-f ${VALUES_DIR}/sentry.values.yaml"
  fi

  local VALKEY_CONFIGURATION=""
  local POSTGRESQL_CONFIGURATION="-f ${VALUES_DIR}/bundled-postgresql.values.yaml"
  local GARAGE_CONFIGURATION=""
  local DEV_STACK_CONFIGURATION=""

  if use_dev_stack; then
    echo "gitlab-dev-stack deployment detected — wiring GitLab to umbrella secrets"
    # Replaces the three external-* overlays: a single overlay points the
    # GitLab chart at the *-conn Secrets emitted by gitlab-dev-stack.
    POSTGRESQL_CONFIGURATION=""
    DEV_STACK_CONFIGURATION="-f ${VALUES_DIR}/dev-stack.values.yaml"
  else
    if use_external_valkey; then
      echo "External Valkey deployment detected"
      VALKEY_CONFIGURATION="-f ${VALUES_DIR}/external-valkey.values.yaml"
    fi

    if use_external_postgresql; then
      echo "External PostgreSQL deployment detected"
      POSTGRESQL_CONFIGURATION="-f ${VALUES_DIR}/external-postgresql.values.yaml"
    fi

    if use_external_garage; then
        echo "External object storage (Garage) deployment detected"
        GARAGE_CONFIGURATION="-f ${VALUES_DIR}/external-garage.values.yaml"
    fi
  fi

  helm upgrade --install \
    --wait --timeout 900s \
    ${CI_CONFIGURATION} \
    ${SENTRY_CONFIGURATION} \
    ${NETWORKING_CONFIGURATION} \
    ${VALKEY_CONFIGURATION} \
    ${POSTGRESQL_CONFIGURATION} \
    ${GARAGE_CONFIGURATION} \
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
      VALKEY_RELEASE_NAME="$(valkey_release_name)" \
      VALKEY_AUTH_SECRET="$(valkey_auth_secret)" \
      VALKEY_AUTH_SECRET_KEY="$(valkey_auth_secret_key)" \
      CNPG_CLUSTER_HOST="$(cnpg_cluster_host)" \
      CNPG_CLUSTER_SECRET="$(cnpg_cluster_secret)" \
      CNPG_CLUSTER_REGISTRY_SECRET="$(cnpg_cluster_registry_secret)" \
      GARAGE_RELEASE_NAME="$(garage_release_name)" \
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
