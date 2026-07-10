#!/bin/bash

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

# Pebble (in-cluster ACME test server) is opt-in: only HTTPS k3d jobs deploy it
# to exercise the chart's cert-manager integration. See scripts/ci/lib/pebble.sh.
function use_pebble() {
  [[ "${DEPLOY_PEBBLE}" == "true" ]]
}

# common_openshift_values returns values needed to deploy Garage
# and Valkey into OpenShift clusters.
function common_openshift_values() {
  echo "--set podSecurityContext.fsGroup=null --set podSecurityContext.runAsUser=null --set podSecurityContext.runAsGroup=null"
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
