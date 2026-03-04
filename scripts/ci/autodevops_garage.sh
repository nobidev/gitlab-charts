#!/bin/bash

# Sourced from scripts/ci/autodevops.sh. So we should not set flags, like `set -eo...`, as it impacts the caller shell.

function deploy_external_garage() {
    if [ -z "${NAMESPACE}" ]; then
        echo "Error: NAMESPACE environment variable is not set"
        exit 1
    fi

    echo "Installing external Garage"

    # default to v2.2.0 as that is the first version we tested with
    # garage charts are not tagged, we use the garage app release versions to get the charts
    helm plugin install https://github.com/aslafy-z/helm-git --verify=false
    helm repo add garage "git+https://git.deuxfleurs.fr/Deuxfleurs/garage.git@script/helm?ref=v${GARAGE_APP_VERSION:-2.2.0}"
    helm repo update

    helm upgrade --install garage garage/garage \
        -n "${NAMESPACE}" \
        --set garage.replicationFactor=1 \
        --set deployment.replicaCount=1 \
        --set persistence.enabled=false \
        --set resources.requests.memory="256Mi" \
        --set resources.requests.cpu="100m" \
        --set resources.limits.memory="512Mi" \
        --set resources.limits.cpu="500m" \
        --wait --timeout=300s

    kubectl wait --for=condition=ready pod \
        -l app.kubernetes.io/name=garage \
        --namespace="${NAMESPACE}" \
        --timeout=300s

    GARAGE_POD=$(kubectl get pod -n "${NAMESPACE}" \
    -l app.kubernetes.io/name=garage \
    -o jsonpath='{.items[0].metadata.name}')

    echo "Using Garage pod: ${GARAGE_POD}"

    local NODE_ID
    NODE_ID=$(kubectl exec -n "${NAMESPACE}" "${GARAGE_POD}" -- \
        /garage status 2>/dev/null | grep -oE '[0-9a-f]{16}' | head -1)

    if [ -z "${NODE_ID}" ]; then
        echo "ERROR: Could not detect Garage node ID. Full status output:"
        kubectl exec -n "${NAMESPACE}" "${GARAGE_POD}" -- /garage status
        exit 1
    fi
    echo "Detected Garage node ID: ${NODE_ID}"

    kubectl exec -n "${NAMESPACE}" "${GARAGE_POD}" -- /garage layout assign -z ci -c 1G "${NODE_ID}"
    kubectl exec -n "${NAMESPACE}" "${GARAGE_POD}" -- /garage layout apply --version 1

    # https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/
    local buckets=(
        "git-lfs"
        "gitlab-artifacts"
        "gitlab-backups"
        "gitlab-ci-secure-files"
        "gitlab-dependency-proxy"
        "gitlab-mr-diffs"
        "gitlab-packages"
        "gitlab-pages"
        "gitlab-terraform-state"
        "gitlab-uploads"
        "registry"
        "runner-cache"
        "tmp"
    )

    for bucket in "${buckets[@]}"; do
        kubectl exec -n "${NAMESPACE}" "${GARAGE_POD}" -- \
            /bin/sh -c "/garage bucket create '${bucket}' || echo 'Bucket ${bucket} might already exist'"
    done

    # create API key and capture credentials, or should we use create_password instead?
    local KEY_OUTPUT
    KEY_OUTPUT=$(kubectl exec -n "${NAMESPACE}" "${GARAGE_POD}" -- \
        /garage key create gitlab-app-key)

    local GARAGE_ACCESS_KEY GARAGE_SECRET_KEY
    GARAGE_ACCESS_KEY=$(echo "${KEY_OUTPUT}" | grep 'Key ID:' | awk '{print $3}')
    GARAGE_SECRET_KEY=$(echo "${KEY_OUTPUT}" | grep 'Secret key:' | awk '{print $3}')

    if [ -z "$GARAGE_ACCESS_KEY" ] || [ -z "$GARAGE_SECRET_KEY" ]; then
        echo "Error: Failed to extract access key or secret key from garage output"
        exit 1
    fi

    # access to buckets
    for bucket in "${buckets[@]}"; do
        kubectl exec -n "${NAMESPACE}" "${GARAGE_POD}" -- /garage bucket allow \
            --read --write --key gitlab-app-key "${bucket}"
    done

    # https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/
    kubectl create secret generic gitlab-object-storage \
        --namespace "${NAMESPACE}" \
        --from-literal=config="$(cat <<EOF
provider: AWS
region: garage
aws_access_key_id: ${GARAGE_ACCESS_KEY}
aws_secret_access_key: ${GARAGE_SECRET_KEY}
endpoint: "http://garage.${NAMESPACE}.svc.cluster.local:3900"
path_style: true
EOF
)" --dry-run=client -o yaml | kubectl apply -f -

    kubectl create secret generic gitlab-object-storage-s3cmd \
        --namespace "${NAMESPACE}" \
        --from-literal=config="$(cat <<EOF
[default]
access_key = ${GARAGE_ACCESS_KEY}
secret_key = ${GARAGE_SECRET_KEY}
host_base = garage.${NAMESPACE}.svc.cluster.local:3900
host_bucket = garage.${NAMESPACE}.svc.cluster.local:3900
use_https = False
EOF
)" --dry-run=client -o yaml | kubectl apply -f -

    kubectl create secret generic gitlab-registry-storage \
        --namespace "${NAMESPACE}" \
        --from-literal=config="$(cat <<EOF
s3:
  accesskey: ${GARAGE_ACCESS_KEY}
  secretkey: ${GARAGE_SECRET_KEY}
  bucket: registry
  region: garage
  regionendpoint: http://garage.${NAMESPACE}.svc.cluster.local:3900
  secure: false
  v4auth: true
  pathstyle: true
EOF
)" --dry-run=client -o yaml | kubectl apply -f -

    echo "Garage installation complete"
}

function remove_external_garage() {
    echo "Removing external Garage"
    helm uninstall garage -n "${NAMESPACE}" --ignore-not-found
    kubectl delete secret \
        gitlab-object-storage \
        gitlab-object-storage-s3cmd \
        gitlab-registry-storage \
        -n "${NAMESPACE}" --ignore-not-found
}
