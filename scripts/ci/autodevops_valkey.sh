#!/bin/bash

# Deploy Valkey using the official Valkey helm chart into the same namespace
# as the GitLab namespace.
# Should currently only be used for vcluster-based review environments
# because native review environments are all deployed into the namespace
# potentially causing conflicts.
function deploy_external_valkey() {
  echo "Installing external Valkey"

  VERSION_FLAG=""
  if [ -n "${VALKEY_CHART_VERSION}" ]; then
    VERSION_FLAG="--version ${VALKEY_CHART_VERSION}"
  fi

  helm repo add valkey https://valkey.io/valkey-helm/
  helm upgrade --install valkey valkey/valkey \
    -n "${NAMESPACE}" \
    ${VERSION_FLAG} \
    --set dataStorage.enabled=true \
    --set dataStorage.size=100Mi \
    --set metrics.enabled=true \
    --set auth.enabled=true \
    --set auth.aclUsers.default.permissions="~* &* +@all" \
    --set auth.aclUsers.default.password="$(valkey_password)" \
    --hide-notes
}

function remove_external_valkey() {
    echo "Removing external Valkey"
    helm uninstall valkey -n "${NAMESPACE}" --wait --ignore-not-found
}

function valkey_password() {
  tr -dc A-Za-z0-9 </dev/urandom | head -c 10
}