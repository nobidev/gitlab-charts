#!/bin/bash

# Deploy Valkey using the official Valkey helm chart into the same namespace
# as the GitLab namespace.
function deploy_external_valkey() {
  echo "Installing/upgrading external Valkey"

  VERSION_FLAG=""
  if [ -n "${VALKEY_CHART_VERSION}" ]; then
    VERSION_FLAG="--version ${VALKEY_CHART_VERSION}"
  fi

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
    --set auth.aclUsers.default.password="$(valkey_password)" \
    --hide-notes
}

function remove_external_valkey() {
    echo "Removing external Valkey"
    helm uninstall "$(valkey_release_name)" -n "${NAMESPACE}" --wait --ignore-not-found
}

# Returns the Valkey password, reusing the existing one on upgrades to prevent
# Valkey from rotating it. Password changes currently do not result in a new
# rollout of Valkey, which is a known bug to be fixed in
# https://github.com/valkey-io/valkey-helm/pull/128.
function valkey_password() {
  if helm status "$(valkey_release_name)" -n "${NAMESPACE}" &>/dev/null; then
    # Reuse existing password.
    helm get values "$(valkey_release_name)" -n "${NAMESPACE}" -o json | jq -r '.auth.aclUsers.default.password'
  else
    tr -dc A-Za-z0-9 </dev/urandom | head -c 10
  fi
}
