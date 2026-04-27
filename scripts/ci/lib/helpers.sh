#!/bin/bash

function is_ci_deployment() {
  [[ -n "${CI_PIPELINE_ID}" ]]
}

function is_local_deployment() {
  ! is_ci_deployment
}

function is_vcluster_deployment() {
  [[ -n "${VCLUSTER_K8S_VERSION}" ]]
}

function is_openshift_deployment() {
  [[ -n "${OPENSHIFT_DEPLOYMENT}" ]]
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

# common_openshift_values returns values needed to deploy Garage
# and Valkey into OpenShift clusters.
function common_openshift_values() {
  echo "--set podSecurityContext.fsGroup=null --set podSecurityContext.runAsUser=null --set podSecurityContext.runAsGroup=null"
}

function use_nginx_ingress() {
  [[ "${USE_NGINX_INGRESS}" == "true" ]]
}
