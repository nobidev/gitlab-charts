#!/bin/bash

# Auto DevOps variables and functions
[[ "$TRACE" ]] && set -x
export CI_APPLICATION_REPOSITORY=$CI_REGISTRY_IMAGE/$CI_COMMIT_SHORT_SHA
export CI_APPLICATION_TAG=$CI_COMMIT_SHA
export CI_CONTAINER_NAME=ci_job_build_${CI_JOB_ID}

# Derive the Helm RELEASE argument from CI_ENVIRONMENT_SLUG
if [[ $CI_ENVIRONMENT_SLUG =~ ^[^-]+-review ]]; then
  # if multiarch deployment is on - we will be deploying *two*
  # charts - one for "amd64" and second for "arm64" thus the need
  # to avoid name collision:
  if [ "${REVIEW_ARCH}" == "arm64" ]; then
    RELEASE_NAME="rvw-a-${REVIEW_REF_PREFIX}${CI_COMMIT_SHORT_SHA}"
  else
    RELEASE_NAME=rvw-${REVIEW_REF_PREFIX}${CI_COMMIT_SHORT_SHA}
  fi
  # if a "review", use $REVIEW_REF_PREFIX$CI_COMMIT_SHORT_SHA
  # Trim release name to leave room for prefixes/suffixes
  RELEASE_NAME=${RELEASE_NAME:0:30}
  # Trim any hyphens in the suffix
  RELEASE_NAME=${RELEASE_NAME%-}
else
  # otherwise, use CI_ENVIRONMENT_SLUG
  if [ "${REVIEW_ARCH}" == "arm64" ]; then
    RELEASE_NAME="a-${CI_ENVIRONMENT_SLUG}"
  else
    RELEASE_NAME=$CI_ENVIRONMENT_SLUG
  fi
fi
export RELEASE_NAME

function previousDeployFailed() {
  set +e
  echo "Checking for previous deployment of $RELEASE_NAME"
  deployment_status=$(helm status $RELEASE_NAME >/dev/null 2>&1)
  status=$?
  # if `status` is `0`, deployment exists, has a status
  if [ $status -eq 0 ]; then
    echo "Previous deployment found, checking status"
    deployment_status=$(helm status $RELEASE_NAME | grep ^STATUS | cut -d' ' -f2)
    echo "Previous deployment state: $deployment_status"
    if [[ "$deployment_status" == "FAILED" || "$deployment_status" == "PENDING_UPGRADE" || "$deployment_status" == "PENDING_INSTALL" ]]; then
      status=0;
    else
      status=1;
    fi
  else
    echo "Previous deployment NOT found."
  fi
  set -e
  return $status
}

function deploy() {
  if [ -z "${NAMESPACE}" ]; then
    echo "Error: NAMESPACE is not set"
    exit 1
  fi

  echo "REVIEW_ARCH: $REVIEW_ARCH"
  # Cleanup and previous installs, as FAILED and PENDING_UPGRADE will cause errors with `upgrade`
  if [ "$RELEASE_NAME" != "production" ] && previousDeployFailed ; then
    echo "Deployment in bad state, cleaning up $RELEASE_NAME"
    delete
    cleanup
  fi

  #ROOT_PASSWORD=$(cat /dev/urandom | LC_TYPE=C tr -dc "[:alpha:]" | head -c 16)
  #echo "Generated root login: $ROOT_PASSWORD"
  kubectl create secret generic -n "${NAMESPACE}" "${RELEASE_NAME}-gitlab-initial-root-password" --from-literal=password=$ROOT_PASSWORD -o yaml --dry-run=client | kubectl replace --force -f -

  echo "${QA_EE_LICENSE}" > /tmp/license.gitlab
  kubectl create secret generic -n "${NAMESPACE}" "${RELEASE_NAME}-gitlab-license" --from-file=license=/tmp/license.gitlab -o yaml --dry-run=client | kubectl replace --force -f -

  # YAML_FILE=""${KUBE_INGRESS_BASE_DOMAIN//\./-}.yaml"

  helm dependency update .

  WAIT="--wait --timeout 900s"

  PROMETHEUS_INSTALL="false"

  # Only enable Prometheus on `master`. To override, set PROMETHEUS_INSTALL_OVERRIDE="false".
  if [ "$CI_COMMIT_REF_NAME" == "master" ] && [ "${PROMETHEUS_INSTALL_OVERRIDE}" != "false" ]; then
    PROMETHEUS_INSTALL="true"
  fi

  cat << CIYAML > ci.prometheus.yaml
  prometheus:
    install: ${PROMETHEUS_INSTALL}
    server:
      retention: "3d"
      extraArgs:
        storage.tsdb.retention.size: "1GB"
      resources:
        requests:
          memory: 2Gi
        limits:
          memory: 4Gi
CIYAML

  # helm's --set argument dislikes special characters, pass them as YAML
  cat << CIYAML > ci.details.yaml
  ci:
    title: |
      ${CI_COMMIT_TITLE}
    sha: "${CI_COMMIT_SHA}"
    branch: "${CI_COMMIT_REF_NAME}"
    job:
      url: "${CI_JOB_URL}"
    pipeline:
      url: "${CI_PIPELINE_URL}"
    environment: "${CI_ENVIRONMENT_SLUG}"
CIYAML

  # configure CI resources, intentionally trimmed.
  cat << CIYAML > ci.scale.yaml
  gitlab:
    webservice:
      minReplicas: 1    # 2
      maxReplicas: 3    # 10
      resources:
        requests:
          cpu: 500m     # 900m
          memory: 1500M # 2.5G
    sidekiq:
      minReplicas: 1    # 1
      maxReplicas: 2    # 10
      resources:
        requests:
          cpu: 500m     # 900m
          memory: 1000M # 2G
    gitlab-shell:
      minReplicas: 1    # 2
      maxReplicas: 2    # 10
    toolbox:
      enabled: true
  nginx-ingress:
    controller:
      replicaCount: 1   # 2
  redis:
    resources:
      requests:
        cpu: 100m
  minio:
    resources:
      requests:
        cpu: 100m
CIYAML
  
  DOMAIN="-$HOST_SUFFIX.$KUBE_INGRESS_BASE_DOMAIN"
  envsubst < ./scripts/ci/values/vcluster.externaldns.values.yaml > ./vcluster.externaldns.values.yaml
  envsubst < ./scripts/ci/values/ingress.values.yaml > ./ingress.values.yaml
  envsubst < ./scripts/ci/values/gatewayapi.values.yaml > ./gatewayapi.values.yaml

  NETWORKING_CONF="-f ingress.values.yaml"
  if [ -n "${USE_GATEWAY_API}" ]; then
    echo "USE_GATEWAY_API detected"
    NETWORKING_CONF="-f gatewayapi.values.yaml"
  fi
  
  if [ -n "${VCLUSTER_NAME}" ]; then
    echo "VCLUSTER deployment detected"
    NETWORKING_CONF="${NETWORKING_CONF} -f vcluster.externaldns.values.yaml"
  fi

  # PostgreSQL max_connection defaults to 100, which is apparently not enough to pass QA.
  cat << CIYAML > ci.psql.yaml
  postgresql:
    primary:
      extendedConfiguration: |-
        max_connections = 200
CIYAML

  if [ -n "${REVIEW_APPS_SENTRY_DSN}" ] && [ -n "${REVIEW_APPS_SENTRY_ENVIRONMENT}" ]; then
    echo "REVIEW_APPS_SENTRY_* detected, enabling Sentry"
    cat << CIYAML > ci.sentry.yaml
    global:
      appConfig:
        sentry:
          enabled: true
          dsn: "${REVIEW_APPS_SENTRY_DSN}"
          environment: "${REVIEW_APPS_SENTRY_ENVIRONMENT}"
CIYAML

    SENTRY_CONFIGURATION="-f ci.sentry.yaml"
  fi

  ARCH_CONFIGURATION=""
  if [ "${REVIEW_ARCH}" == "arm64" ]; then
    # The bundled MinIO chart is not being updated anymore.
    # Override the image for arm64 because the current default image is only build for amd64.
    ARCH_CONFIGURATION="-f scripts/ci/values/arm64.values.yaml"
    # Patch the minio chart to accomodate for CLI changes in the new minio/mc version.
    git apply ./scripts/ci/patches/arm64.minio.patch
  fi

  helm upgrade --install \
    $WAIT \
    ${SENTRY_CONFIGURATION} \
    ${ARCH_CONFIGURATION} \
    ${NETWORKING_CONF} \
    -f ci.details.yaml \
    -f ci.scale.yaml \
    -f ci.psql.yaml \
    -f ci.digests.yaml \
    -f ci.prometheus.yaml \
    --set releaseOverride="$RELEASE_NAME" \
    --set global.hosts.hostSuffix="$HOST_SUFFIX" \
    --set global.hosts.domain="$KUBE_INGRESS_BASE_DOMAIN" \
    --set global.appConfig.initialDefaults.signupEnabled=false \
    --set installCertmanager=false \
    --set global.extraEnv.GITLAB_LICENSE_MODE="test" \
    --set global.extraEnv.CUSTOMER_PORTAL_URL="https://customers.staging.gitlab.com" \
    --set global.gitlab.license.secret="$RELEASE_NAME-gitlab-license" \
    --namespace="$NAMESPACE" \
    "${gitlab_version_args[@]}" \
    --version="$CI_PIPELINE_ID-$CI_JOB_ID" \
    $HELM_EXTRA_ARGS \
    "$RELEASE_NAME" \
    .
}

function check_kas_status() {
  iteration=0
  kasState=""

  while [ "${kasState[1]}" != "Running" ]; do
    if [ $iteration -eq 0 ]; then
      echo ""
      echo -n "Waiting for KAS deploy to complete.";
    else
      echo -n "."
    fi

    iteration=$((iteration+1))
    kasState=($(kubectl get pods -n "$NAMESPACE" -lrelease=${RELEASE_NAME},app=kas | awk '{print $3}'))
    sleep 5;
  done
}

function wait_for_deploy {
  iteration=0

  # Watch for a `webservice` Pod to come online.
  webserviceState=0
  while [ "$webserviceState" -lt 2 ]; do
    # This will always return at least one line, `NAME`
    webserviceState=($(kubectl get pods -n "$NAMESPACE" -lrelease=${RELEASE_NAME},app=webservice --field-selector status.phase=Running -o=custom-columns=NAME:.metadata.name | wc -l))
    if [ $iteration -eq 0 ]; then
      echo -n "Waiting for deploy to complete.";
    else
      echo -n "."
    fi
    sleep 5;
  done

  check_kas_status

  echo ""
}

function ensure_namespace() {
  kubectl describe namespace "$NAMESPACE" || kubectl create namespace "$NAMESPACE"
}

function set_context() {
  if [ -z ${AGENT_NAME+x} ] || [ -z ${AGENT_PROJECT_PATH+x} ]; then
    echo "No AGENT_NAME or AGENT_PROJECT_PATH set, using the default"
  else
    kubectl config get-contexts
    kubectl config use-context ${AGENT_PROJECT_PATH}:${AGENT_NAME}
    kubectl config set-context --current --namespace=${NAMESPACE}
  fi
}

function check_kube_domain() {
  if [ -z ${KUBE_INGRESS_BASE_DOMAIN+x} ]; then
    echo "ERROR: In order to deploy, KUBE_INGRESS_BASE_DOMAIN must be set as a variable at the group or project level, or manually added in .gitlab-cy.yml"
    false
  else
    true
  fi
}

function check_domain_ip() {
  # Expect the `DOMAIN` is a wildcard.
  domain_ip=$(getent hosts gitlab$DOMAIN 2>/dev/null | awk '{print $1}')

  if [ -z $domain_ip ]; then
    echo "ERROR: There was a problem resolving the IP of 'gitlab$DOMAIN'. Be sure you have configured a DNS entry."
    false
  else
    export DOMAIN_IP=$domain_ip
    echo "Found IP for gitlab$DOMAIN: $DOMAIN_IP"
    true
  fi
}

function create_secret() {
  kubectl create secret -n "$NAMESPACE" \
    docker-registry gitlab-registry-docker \
    --docker-server="$CI_REGISTRY" \
    --docker-username="$CI_REGISTRY_USER" \
    --docker-password="$CI_REGISTRY_PASSWORD" \
    --docker-email="$GITLAB_USER_EMAIL" \
    -o yaml --dry-run=client | kubectl replace -n "$NAMESPACE" --force -f -
}

function delete() {
  helm uninstall "$RELEASE_NAME" || true
}

function cleanup() {
  kubectl -n "$NAMESPACE" delete --ignore-not-found=true \
    $(get_resources "ingress,svc,pdb,hpa,deploy,statefulset,replicaset,job,pod,secret,configmap,clusterrole,clusterrolebinding,role,rolebinding,sa") \
    || true

  pvcs=$(get_resources "pvc")
  for pvc in ${pvcs}; do
    pv=$(kubectl -n "$NAMESPACE" get pvc "$pvc" -o jsonpath='{.spec.volumeName}' 2>&1)
    volumeHandle=$(kubectl get pv "$pv" -o jsonpath='{.spec.csi.volumeHandle}' 2>&1)
    # Delete PVC only, PV and volume should be handled by reclaim policy
    echo "Deleting $pvc (PV: $pv, CSI volume: $volumeHandle)"
    kubectl -n "$NAMESPACE" delete pvc "$pvc" || true
  done
}

function get_resources() {
  kubectl -n "$NAMESPACE" get "$1" --no-headers 2>&1 \
    | grep "$RELEASE_NAME" \
    | awk '{print $1}' \
    | xargs
}
