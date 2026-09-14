#!/bin/bash

# Sourced from scripts/ci/autodevops.sh and scripts/dev_dependencies.sh. So we
# should not set flags, like `set -eo...`, as it impacts the caller shell.
#
# Provisions Postgres, Valkey, and Garage via the gitlab-dev-stack umbrella
# chart (https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-dev-stack) as
# a single helm release. This is the only supported way to provision the
# chart's external dependencies for CI and local development.
#
# The CloudNativePG operator is NOT bundled with gitlab-dev-stack. Native
# GKE/EKS clusters carry a cluster-wide install; isolated clusters (vcluster,
# k3d) and local development get a namespaced one from install_cnpg_operator
# below.

DEV_STACK_CHART_REPO="${DEV_STACK_CHART_REPO:-oci://registry.gitlab.com/gitlab-org/cloud-native/charts/gitlab-dev-stack}"
DEV_STACK_CHART_NAME="${DEV_STACK_CHART_NAME:-gitlab-dev-stack}"

CNPG_CHART_REPO="${CNPG_CHART_REPO:-https://cloudnative-pg.github.io/charts}"

# Release name for the namespaced CloudNativePG operator install. Distinct
# from dev_stack_release_name so the operator can be upgraded or torn down
# independently of the umbrella release.
function cnpg_operator_release_name() {
    echo -n "$(release_name_base)-cnpg"
}

# True when the target cluster has no cluster-wide CloudNativePG operator and
# we therefore have to install a namespaced one ourselves.
function needs_cnpg_operator() {
    is_local_deployment || is_vcluster_deployment || is_k3d_deployment
}

function install_cnpg_operator() {
    local version_flag=()
    if [ -n "${CNPG_CHART_VERSION}" ]; then
        version_flag=(--version "${CNPG_CHART_VERSION}")
    fi

    # Install from a locally cached .tgz rather than a repo reference, so the
    # CI cache (.external_charts_cache) can spare us the download.
    local chart
    chart="$(ensure_external_chart cnpg "${CNPG_CHART_REPO}" cloudnative-pg \
        "${CNPG_CHART_VERSION:-latest}" "${version_flag[@]}")"

    helm upgrade --install "$(cnpg_operator_release_name)" "${chart}" \
        --namespace "${NAMESPACE}" \
        --set config.clusterWide=false \
        --wait \
        --timeout 600s \
        --hide-notes

    # Wait for ALL CNPG CRDs to be Established before creating any CRs.
    # Helm --wait ensures the operator pod is Ready, but CRD Established
    # condition can lag on k3d (poolers in particular hits the default 300s limit).
    kubectl wait --for=condition=Established --timeout=120s \
        crd/backups.postgresql.cnpg.io \
        crd/clusterimagecatalogs.postgresql.cnpg.io \
        crd/clusters.postgresql.cnpg.io \
        crd/imagecatalogs.postgresql.cnpg.io \
        crd/poolers.postgresql.cnpg.io \
        crd/scheduledbackups.postgresql.cnpg.io
}

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
        return 1
    fi

    if needs_cnpg_operator; then
        echo "Installing CloudNativePG operator"
        install_cnpg_operator
    fi

    echo "Installing/upgrading gitlab-dev-stack as $(dev_stack_release_name)"

    local version_flag=()
    if [ -n "${DEV_STACK_CHART_VERSION}" ]; then
        version_flag=(--version "${DEV_STACK_CHART_VERSION}")
    fi

    local chart
    chart="$(ensure_external_chart dev-stack "${DEV_STACK_CHART_REPO}" \
        "${DEV_STACK_CHART_NAME}" "${DEV_STACK_CHART_VERSION:-latest}" "${version_flag[@]}")"

    render_dev_stack_values

    helm upgrade --install "$(dev_stack_release_name)" "${chart}" \
        -n "${NAMESPACE}" \
        -f "${VALUES_DIR}/dev-stack/values.yaml" \
        --wait --timeout 600s --hide-notes

    wait_for_dev_stack_postgres
}

# `helm --wait` only tracks built-in workload kinds, so it returns while the
# CloudNativePG Cluster and Database CRs it created are still reconciling —
# `helm install` reports success against a Postgres that has no databases,
# roles, or extensions yet. The GitLab chart deploy that follows starts its
# migrations Job immediately and fails against that half-built Postgres, so
# wait for the CRs here instead.
function wait_for_dev_stack_postgres() {
    local timeout="${DEV_STACK_PG_WAIT_TIMEOUT:-600}"
    local selector="app.kubernetes.io/instance=$(dev_stack_release_name),app.kubernetes.io/component=postgres"

    echo "Waiting for CloudNativePG clusters to become Ready"
    kubectl wait --for=condition=Ready --timeout="${timeout}s" \
        -n "${NAMESPACE}" -l "${selector}" cluster.postgresql.cnpg.io --all

    # Database CRs expose no conditions, only a boolean `status.applied`. They
    # briefly report `role "<owner>" does not exist` while the Cluster's
    # managed roles are still being created, then reconcile on retry.
    echo "Waiting for CloudNativePG databases to be applied"
    if ! kubectl wait --for=jsonpath='{.status.applied}'=true --timeout="${timeout}s" \
        -n "${NAMESPACE}" -l "${selector}" database.postgresql.cnpg.io --all; then
        kubectl get database.postgresql.cnpg.io -n "${NAMESPACE}" -l "${selector}" \
            -o custom-columns=NAME:.metadata.name,APPLIED:.status.applied,MESSAGE:.status.message >&2
        return 1
    fi
}

function remove_dev_stack() {
    echo "Removing gitlab-dev-stack"
    helm uninstall "$(dev_stack_release_name)" -n "${NAMESPACE}" --ignore-not-found --wait

    # k3d clusters get nuked wholesale, so per-namespace operator cleanup is
    # only worth doing where the cluster outlives the release.
    if needs_cnpg_operator && ! is_k3d_deployment; then
        echo "Removing CloudNativePG operator"
        helm uninstall "$(cnpg_operator_release_name)" -n "${NAMESPACE}" --wait --ignore-not-found
    fi
}
