#!/bin/bash

# Deploy PostgreSQL using the the CloudNativePG helm chart into the same namespace
# as the GitLab namespace.
# Should currently only be used for vcluster-based review environments to:
#   1. Avoid CRD conflicts.
#   2. Avoid resource conflicts in native review environments where mutliple review deploysments exist in the same namespace.
function deploy_external_postgresql() {
  echo "Installing external PostgreSQL"

  VERSION_FLAG=""
  if [ -n "${CN_PG_VERSION}" ]; then
    VERSION_FLAG="--version ${CN_PG_VERSION}"
  fi

  helm repo add cnpg https://cloudnative-pg.github.io/charts
  helm upgrade cnpg cnpg/cloudnative-pg \
    --install \
    ${VERSION_FLAG} \
    --namespace ${NAMESPACE} \
    --set config.clusterWide=false \
    --wait \
    --hide-notes \
    -f scripts/ci/values/cnpg.values.yaml

  local image="ghcr.io/cloudnative-pg/postgresql:${CN_PG_POSTGRESQL_TAG}"

cat <<EOF | kubectl apply -n "${NAMESPACE}" -f -
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: gitlab-cluster
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

  kubectl wait --timeout 180s --for=condition=Ready -n "${NAMESPACE}" "clusters/gitlab-cluster"
}

function remove_external_postgres() {
    echo "Removing GitLab CNPG Cluster"
    kubectl delete -n "${NAMESPACE}" --wait --ignore-not-found=true cluster gitlab-cluster
    
    echo "Removing CNPG"
    helm uninstall cnpg -n "${NAMESPACE}" --wait --ignore-not-found
}