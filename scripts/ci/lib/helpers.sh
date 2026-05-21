#!/bin/bash

# ARTIFACTS_DIR is the parent of everything a CI job (or a local dev run)
# emits onto disk — rendered values files, debug bundles, skopeo error logs.
# Defaults to the CI project root (so existing CI artifact paths like
# `./k3d-debug/` and `./.values/` keep landing where they always did) or
# the current working directory when running locally without CI envvars.
: "${ARTIFACTS_DIR:=${CI_PROJECT_DIR:-$(pwd)}}"
export ARTIFACTS_DIR

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

function is_openshift_deployment() {
  [[ -n "${OPENSHIFT_DEPLOYMENT}" ]]
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

function valkey_release_name() {
  echo -n "$(release_name_base)-valkey"
}

function valkey_auth_secret() {
  echo -n "$(valkey_release_name)-auth"
}

function valkey_auth_secret_key() {
  echo -n "default"
}

function cnpg_release_name() {
  echo -n "$(release_name_base)-cnpg"
}

function cnpg_cluster_name() {
  echo -n "$(release_name_base)-cluster"
}

function cnpg_cluster_host() {
  echo -n "$(cnpg_cluster_name)-rw"
}

function cnpg_cluster_secret() {
  echo -n "$(cnpg_cluster_name)-app"
}

function cnpg_cluster_registry_secret() {
  echo -n "$(cnpg_cluster_name)-registry-app"
}

function use_external_valkey() {
  [[ "${SKIP_EXTERNAL_VALKEY}" != "true" ]]
}

function use_external_postgresql() {
  [[ "${SKIP_EXTERNAL_POSTGRESQL}" != "true" ]]
}

function garage_release_name() {
  echo -n "$(release_name_base)-garage"
}

function use_external_garage() {
  [[ "${SKIP_EXTERNAL_GARAGE}" != "true" ]]
}

function dev_stack_release_name() {
  echo -n "$(release_name_base)-stack"
}

# When true, provision Postgres/Valkey/Garage via the gitlab-dev-stack umbrella
# chart instead of the per-component installers in valkey.sh/cloudnativepg.sh/garage.sh.
function use_dev_stack() {
  [[ "${USE_DEV_STACK}" == "true" ]]
}

# common_openshift_values returns values needed to deploy Garage
# and Valkey into OpenShift clusters.
function common_openshift_values() {
  echo "--set podSecurityContext.fsGroup=null --set podSecurityContext.runAsUser=null --set podSecurityContext.runAsGroup=null"
}

function use_nginx_ingress() {
  [[ "${USE_NGINX_INGRESS}" == "true" ]]
}
