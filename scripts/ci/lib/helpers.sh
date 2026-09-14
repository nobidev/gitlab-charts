#!/bin/bash

# ARTIFACTS_DIR is the parent of everything a CI job (or a local dev run)
# emits onto disk — rendered values files, debug bundles, skopeo error logs.
# Defaults to the CI project root (so existing CI artifact paths like
# `./k3d-debug/` and `./.values/` keep landing where they always did) or
# the current working directory when running locally without CI envvars.
: "${ARTIFACTS_DIR:=${CI_PROJECT_DIR:-$(pwd)}}"
export ARTIFACTS_DIR

_HELPERS_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CI_YAML="${CI_YAML:-${_HELPERS_LIB_DIR}/../../../.gitlab-ci.yml}"

# ci_variable echoes a top-level `variables:` entry from .gitlab-ci.yml. Local
# tooling reads dependency versions through it so a developer provisions what
# CI provisions, rather than carrying a second set of defaults that silently
# drift. Requires yq (pinned in mise.toml).
function ci_variable() {
  local name="${1}" value
  value="$(yq ".variables.${name}" "${CI_YAML}")"
  if [ -z "${value}" ] || [ "${value}" = "null" ]; then
    echo "ci_variable: ${name} not found in ${CI_YAML}" >&2
    return 1
  fi
  echo -n "${value}"
}

function is_ci_deployment() {
  [[ -n "${CI_PIPELINE_ID}" ]]
}

function is_local_deployment() {
  ! is_ci_deployment
}

# Note: GitLab chart has no vcluster review environment anymore.
# This is kept for GitLab Operator which sources this script and
# still has vcluster environments.
function is_vcluster_deployment() {
  [[ -n "${VCLUSTER_K8S_VERSION}" ]]
}

function is_k3d_deployment() {
  [[ "${K3D_MODE:-false}" == "true" ]]
}

# release_name_base returns a common prefix for all releases managed
# by the autodevops script
function release_name_base() {
  if is_ci_deployment; then
    echo -n "rvw-${CI_PIPELINE_ID}"
  else
    echo -n "dev"
  fi
}

function gitlab_release_name() {
  echo -n "$(release_name_base)-gitlab"
}

# The gitlab-dev-stack umbrella release provisions Postgres, Valkey, and
# Garage. See scripts/ci/lib/dev_stack.sh.
function dev_stack_release_name() {
  echo -n "$(release_name_base)-stack"
}

# Pebble (in-cluster ACME test server) is opt-in: only HTTPS k3d jobs deploy it
# to exercise the chart's cert-manager integration. See scripts/ci/lib/pebble.sh.
function use_pebble() {
  [[ "${DEPLOY_PEBBLE}" == "true" ]]
}

function use_nginx_ingress() {
  [[ "${USE_NGINX_INGRESS}" == "true" ]]
}

# external_protocol returns the protocol used for external access.
# Defaults to "http" for k3d deployments (no TLS) and "https" otherwise.
# Can be overridden by setting EXTERNAL_PROTOCOL explicitly.
function external_protocol() {
  if [ -n "${EXTERNAL_PROTOCOL}" ]; then
    echo -n "${EXTERNAL_PROTOCOL}"
  elif is_k3d_deployment; then
    echo -n "http"
  else
    echo -n "https"
  fi
}

EXTERNAL_CHARTS_DIR=".external-charts"

# ensure_external_chart pulls <chart> from <repo_url> (registered under
# <alias>, or pulled directly when <repo_url> is an oci:// reference) into a
# directory keyed on <cache_tag> - typically the chart version - skipping the
# pull if already cached, and prints the resulting .tgz path. Extra args are
# passed through to `helm pull` (e.g. --version).
#
# Meant so callers can `helm upgrade --install` from that local path instead
# of a repo/chart reference, which always re-downloads the chart even if an
# identical copy was already fetched by an earlier job.
function ensure_external_chart() {
  local alias="$1" repo_url="$2" chart="$3" cache_tag="$4"
  shift 4
  local dest_dir="${EXTERNAL_CHARTS_DIR}/${alias}-${cache_tag}"
  local dest=""
  if [[ -d "${dest_dir}" ]]; then
    dest="$(find "${dest_dir}" -name '*.tgz' -print -quit)"
  fi

  if [[ -z "${dest}" ]]; then
    mkdir -p "${dest_dir}"
    if [[ "${repo_url}" == oci://* ]]; then
      # OCI registries have no repo index to add; pull the ref directly.
      helm pull "${repo_url}/${chart}" --destination "${dest_dir}" "$@" >&2
    else
      helm repo add "${alias}" "${repo_url}" >&2
      helm pull "${alias}/${chart}" --destination "${dest_dir}" "$@" >&2
    fi
    dest="$(find "${dest_dir}" -name '*.tgz' -print -quit)"
  fi

  echo "${dest}"
}
