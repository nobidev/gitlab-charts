#!/bin/bash

# Sourced from scripts/ci/autodevops.sh. So we should not set flags, like `set -eo...`, as it impacts the caller shell.
#
# Provisions Postgres, Valkey, and Garage via the gitlab-dev-stack umbrella
# chart (https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-dev-stack) as
# a single helm release, replacing the three per-component installers in
# cloudnativepg.sh, valkey.sh, and garage.sh.
#
# The CloudNativePG operator is NOT bundled with gitlab-dev-stack; it must be
# pre-installed cluster-wide on the target cluster (which matches how the
# existing cloudnativepg.sh script behaves on native GKE/EKS).

DEV_STACK_CHART="${DEV_STACK_CHART:-oci://registry.gitlab.com/gitlab-org/cloud-native/charts/gitlab-dev-stack/gitlab-dev-stack}"

function render_dev_stack_values() {
    mkdir -p "${VALUES_DIR}/dev-stack"
    env \
        DEV_STACK_RELEASE_NAME="$(dev_stack_release_name)" \
        CNPG_POSTGRESQL_TAG="${CNPG_POSTGRESQL_TAG}" \
        GARAGE_APP_VERSION="${GARAGE_APP_VERSION}" \
            envsubst < "${SCRIPT_DIR}/values/dev-stack/values.yaml.tmpl" \
                > "${VALUES_DIR}/dev-stack/values.yaml"
}

function deploy_dev_stack() {
    if [ -z "${NAMESPACE}" ]; then
        echo "Error: NAMESPACE environment variable is not set"
        exit 1
    fi

    # Isolated clusters (vcluster, k3d) don't share the cluster-wide CNPG
    # operator that native GKE/EKS environments have, so install it first.
    # Reuses install_cnpg_operator from cloudnativepg.sh.
    if is_ci_deployment && (is_vcluster_deployment || is_k3d_deployment); then
        echo "Installing CloudNativePG operator"
        install_cnpg_operator
    fi

    echo "Installing/upgrading gitlab-dev-stack as $(dev_stack_release_name)"

    local version_flag=""
    if [ -n "${DEV_STACK_CHART_VERSION}" ]; then
        version_flag="--version ${DEV_STACK_CHART_VERSION}"
    fi

    render_dev_stack_values

    helm upgrade --install "$(dev_stack_release_name)" "${DEV_STACK_CHART}" \
        ${version_flag} \
        -n "${NAMESPACE}" \
        -f "${VALUES_DIR}/dev-stack/values.yaml" \
        --wait --timeout 600s --hide-notes
}

function remove_dev_stack() {
    echo "Removing gitlab-dev-stack"
    helm uninstall "$(dev_stack_release_name)" -n "${NAMESPACE}" --ignore-not-found --wait

    # Mirror remove_external_postgresql: tear the operator down on local or
    # vcluster (k3d gets nuked wholesale, no per-namespace cleanup needed).
    if is_local_deployment || (is_ci_deployment && is_vcluster_deployment); then
        echo "Removing CloudNativePG operator"
        helm uninstall "$(cnpg_release_name)" -n "${NAMESPACE}" --wait --ignore-not-found
    fi
}
