#!/bin/bash

# Deploy PostgreSQL using the the CloudNativePG helm chart into the same namespace
# as the GitLab namespace.
# Should currently only be used for vcluster-based review environments to:
#   1. Avoid CRD conflicts.
#   2. Avoid resource conflicts in native review environments where mutliple review deploysments exist in the same namespace.
function deploy_external_postgresql() {
  # Install operator for isolated clusters (vcluster, k3d) that don't have a
  # shared CNPG operator. Native GKE/EKS environments use a cluster-wide install.
  if is_ci_deployment && (is_vcluster_deployment || is_k3d_deployment); then
    echo "Installing CloudNativePG"
    install_cnpg_operator
  fi
  echo "Installing CloudNativePG PostgreSQL Cluster"
  create_cnpg_cluster
}

function install_cnpg_operator {
  VERSION_FLAG=""
  if [ -n "${CNPG_CHART_VERSION}" ]; then
    VERSION_FLAG="--version ${CNPG_CHART_VERSION}"
  fi

  helm repo add cnpg https://cloudnative-pg.github.io/charts
  helm upgrade "$(cnpg_release_name)" cnpg/cloudnative-pg \
    --install \
    ${VERSION_FLAG} \
    --namespace ${NAMESPACE} \
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

function create_cnpg_cluster {
  local image="ghcr.io/cloudnative-pg/postgresql:${CNPG_POSTGRESQL_TAG}"
  local cluster_cr=$(cat <<EOF
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: "$(cnpg_cluster_name)"
  namespace: "${NAMESPACE}"
spec:
  instances: 1
  imageName: "${image}"
  storage:
    size: 3Gi
  postgresql:
    parameters:
      max_connections: "200"
      shared_buffers: "256MB"
  bootstrap:
    initdb:
      database: gitlabhq_production
      owner: gitlab
      postInitSQL:
        - CREATE EXTENSION IF NOT EXISTS pg_trgm;
        - CREATE EXTENSION IF NOT EXISTS btree_gist;
        - CREATE EXTENSION IF NOT EXISTS plpgsql;
        - CREATE EXTENSION IF NOT EXISTS amcheck;
        - CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
EOF
)

  # Apply cluster CR with retries because webhook may not be up: https://github.com/cloudnative-pg/charts/issues/674
  # Once applied, wait for PostgreSQL to be ready.
  for i in $(seq 1 5); do
    sleep 5
    if echo "$cluster_cr" | kubectl apply -n "${NAMESPACE}" -f -; then
      kubectl wait --timeout 180s --for=condition=Ready -n "${NAMESPACE}" "clusters/$(cnpg_cluster_name)"
      return 0
    fi
  done

  return 1
}

function remove_external_postgresql() {
    echo "Removing CloudNativePG PostgreSQL Cluster"
    kubectl delete -n "${NAMESPACE}" --wait --ignore-not-found=true cluster "$(cnpg_cluster_name)"
    
    if is_local_deployment || (is_ci_deployment && is_vcluster_deployment); then
      echo "Removing CloudNativePG"
      helm uninstall "$(cnpg_release_name)" -n "${NAMESPACE}" --wait --ignore-not-found
    fi
}