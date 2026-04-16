#!/bin/bash

# Deploy Valkey using the official Valkey helm chart into the same namespace
# as the GitLab namespace.
function deploy_external_valkey() {
  echo "Installing/upgrading external Valkey"

  VERSION_FLAG=""
  if [ -n "${VALKEY_CHART_VERSION}" ]; then
    VERSION_FLAG="--version ${VALKEY_CHART_VERSION}"
  fi

  # Create auth secret if it doesn't exist yet.
  kubectl get secret "$(valkey_auth_secret)" -n "${NAMESPACE}" &>/dev/null || \
    kubectl create secret generic "$(valkey_auth_secret)" -n "${NAMESPACE}" \
      --from-literal="$(valkey_auth_secret_key)"="$(valkey_password)"

  helm repo add valkey https://valkey.io/valkey-helm/
  helm upgrade --install "$(valkey_release_name)" valkey/valkey \
    -n "${NAMESPACE}" \
    ${VERSION_FLAG} \
    --set dataStorage.enabled=true \
    --set dataStorage.size=100Mi \
    --set dataStorage.keepPvc=false \
    --set metrics.enabled=true \
    --set auth.enabled=true \
    --set auth.aclUsers.default.permissions="~* &* +@all" \
    --set auth.usersExistingSecret="$(valkey_auth_secret)" \
    $(valkey_openshift_values) \
    --hide-notes
}

function remove_external_valkey() {
    echo "Removing external Valkey"
    kubectl delete secret -n "${NAMESPACE}" "$(valkey_auth_secret)" --ignore-not-found
    helm uninstall "$(valkey_release_name)" -n "${NAMESPACE}" --wait --ignore-not-found
}

function valkey_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 10
}

function valkey_openshift_values() {
  if is_openshift_deployment; then
    echo "--set podSecurityContext.fsGroup=null --set podSecurityContext.runAsUser=null --set podSecurityContext.runAsGroup=null --set securityContext.runAsUser=null"
  fi
}