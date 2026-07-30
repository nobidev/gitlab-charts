#!/bin/bash

set -e # Exit on first failure.

# Auto DevOps variables and functions
[[ "$TRACE" ]] && set -x


SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/helpers.sh"
source "$SCRIPT_DIR/lib/valkey.sh"
source "$SCRIPT_DIR/lib/cloudnativepg.sh"
source "$SCRIPT_DIR/lib/garage.sh"

PROJECT_ROOT="${SCRIPT_DIR}/../.."
VALUES_DIR="${PROJECT_ROOT}/.values"

function deploy_external_components() {
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

function deploy() {
  if [ -z "${NAMESPACE}" ]; then
    echo "Error: NAMESPACE is not set"
    exit 1
  fi

  helm dependency update .
  prepare_values

  CI_CONFIGURATION=""
  # Substuite environment variables in values file
  if is_ci_deployment; then
    echo "CI deployment detected"
    kubectl create secret generic -n "${NAMESPACE}" "$(gitlab_release_name)-gitlab-initial-root-password" \
      --from-literal=password="$ROOT_PASSWORD" -o yaml --dry-run=client \
      | kubectl replace --force -f -

    kubectl create secret generic -n "${NAMESPACE}" "$(gitlab_release_name)-gitlab-license" \
      --from-literal=license="$QA_EE_LICENSE" -o yaml --dry-run=client \
      | kubectl replace --force -f -

    CI_CONFIGURATION="-f ${VALUES_DIR}/ci-base.values.yaml -f ${VALUES_DIR}/ci-scale.values.yaml -f ${VALUES_DIR}/ci-license.values.yaml -f ci.digests.yaml"
  fi

  if use_nginx_ingress; then
    echo "Exposing GitLab via NGINX Ingress in $(external_protocol) mode"
    NETWORKING_CONFIGURATION="-f ${VALUES_DIR}/ingress-$(external_protocol).values.yaml"
  else
    echo "Exposing GitLab via Gateway API in $(external_protocol) mode"
    NETWORKING_CONFIGURATION="-f ${VALUES_DIR}/gatewayapi-$(external_protocol).values.yaml"
  fi

  if [ -n "${REVIEW_APPS_SENTRY_DSN}" ] && [ -n "${REVIEW_APPS_SENTRY_ENVIRONMENT}" ]; then
    echo "Sentry deployment detected"
    SENTRY_CONFIGURATION="-f ${VALUES_DIR}/sentry.values.yaml"
  fi

  VALKEY_CONFIGURATION=""
  if use_external_valkey; then
    echo "External Valkey deployment detected"
    VALKEY_CONFIGURATION="-f ${VALUES_DIR}/external-valkey.values.yaml"
  fi

  POSTGRESQL_CONFIGURATION="-f ${VALUES_DIR}/bundled-postgresql.values.yaml"
  if use_external_postgresql; then
    echo "External PostgreSQL deployment detected"
    POSTGRESQL_CONFIGURATION="-f ${VALUES_DIR}/external-postgresql.values.yaml"
  fi

  GARAGE_CONFIGURATION=""
  if use_external_garage; then
      echo "External object storage (Garage) deployment detected"
      GARAGE_CONFIGURATION="-f ${VALUES_DIR}/external-garage.values.yaml"
  fi

  helm upgrade --install \
    --wait --timeout 900s \
    ${CI_CONFIGURATION} \
    ${SENTRY_CONFIGURATION} \
    ${NETWORKING_CONFIGURATION} \
    ${VALKEY_CONFIGURATION} \
    ${POSTGRESQL_CONFIGURATION} \
    ${GARAGE_CONFIGURATION} \
    --namespace="$NAMESPACE" \
    $HELM_EXTRA_ARGS \
    "$(gitlab_release_name)" \
    "${PROJECT_ROOT}"
}

function prepare_values() {
  mkdir -p "${VALUES_DIR}"

  for f in ./scripts/ci/values/gitlab-chart/*; do
    env \
      GITLAB_RELEASE_NAME="$(gitlab_release_name)" \
      VALKEY_RELEASE_NAME="$(valkey_release_name)" \
      VALKEY_AUTH_SECRET="$(valkey_auth_secret)" \
      VALKEY_AUTH_SECRET_KEY="$(valkey_auth_secret_key)" \
      CNPG_CLUSTER_HOST="$(cnpg_cluster_host)" \
      CNPG_CLUSTER_SECRET="$(cnpg_cluster_secret)" \
      CNPG_CLUSTER_REGISTRY_SECRET="$(cnpg_cluster_registry_secret)" \
      GARAGE_RELEASE_NAME="$(garage_release_name)" \
        envsubst < "$f" > "${VALUES_DIR}/$(basename $f)"
  done
}

function check_kas_status() {
  iteration=0
  kasState=""

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

function wait_for_deploy {
  iteration=0

  # Watch for a `webservice` Pod to come online.
  webserviceState=0
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
    echo "ERROR: In order to deploy, KUBE_INGRESS_BASE_DOMAIN must be set as a variable at the group or project level, or manually added in .gitlab-cy.yml"
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
