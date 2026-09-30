#!/bin/bash

# Sourced from scripts/ci/autodevops.sh. So we should not set flags, like `set -eo...`, as it impacts the caller shell.

# Externally managed Traefik Ingress controller.
#
# The GitLab chart bundles the NGINX Ingress, Traefik and HAProxy subcharts, all
# of which are deprecated and removed in 20.0. To keep the Ingress resources the
# chart renders under test after that removal, this installs the UPSTREAM
# Traefik chart into its own namespace, before and independently of the GitLab
# chart — the way an operator running their own Ingress controller would.
#
# Traefik also serves Git over SSH, through the IngressRouteTCP the GitLab Shell
# chart renders when `global.ingress.provider` is `traefik`.
#
# See: doc/advanced/external-ingress/_index.md
#      doc/charts/traefik/_index.md

TRAEFIK_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TRAEFIK_CHART_REPO="${TRAEFIK_CHART_REPO:-https://traefik.github.io/charts}"
TRAEFIK_CHART_VERSION="${TRAEFIK_CHART_VERSION:-41.6.0}"

function traefik_values_file() {
  echo -n "${TRAEFIK_LIB_DIR}/../values/traefik/traefik.values.yaml"
}

function deploy_external_traefik() {
  local chart
  # Alias `traefik-upstream`, not `traefik`: scripts/ci/add_dependency_repos.sh
  # already registers `traefik` for the legacy helm.traefik.io repo the bundled
  # subchart is pinned to, and `helm repo add` rejects the same name with a
  # different URL.
  chart="$(ensure_external_chart traefik-upstream "${TRAEFIK_CHART_REPO}" traefik \
    "${TRAEFIK_CHART_VERSION}" --version "${TRAEFIK_CHART_VERSION}")"

  echo "Installing externally managed Traefik (chart ${TRAEFIK_CHART_VERSION}) into namespace $(traefik_namespace)"
  helm upgrade --install "$(traefik_release_name)" "${chart}" \
    --namespace "$(traefik_namespace)" --create-namespace \
    -f "$(traefik_values_file)" \
    --wait --timeout 300s \
    --hide-notes

  # The GitLab chart renders an IngressRouteTCP for GitLab Shell, and picks its
  # apiVersion from the cluster's capabilities, so the CRD the Traefik chart
  # ships has to be Established before the GitLab chart is templated.
  kubectl wait --for=condition=Established --timeout=120s \
    crd/ingressroutetcps.traefik.io
}

function remove_external_traefik() {
  echo "Removing externally managed Traefik"
  helm uninstall "$(traefik_release_name)" -n "$(traefik_namespace)" --ignore-not-found
  kubectl delete namespace "$(traefik_namespace)" --ignore-not-found
}
