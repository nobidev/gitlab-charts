#!/bin/bash

source scripts/ci/autodevops.sh

echo "CI_ENVIRONMENT_SLUG=${CI_ENVIRONMENT_SLUG}"
echo "CI_COMMIT_SHORT_SHA=${CI_COMMIT_SHORT_SHA}"
echo "HOST_SUFFIX=${HOST_SUFFIX}"
echo "KUBE_INGRESS_BASE_DOMAIN=${KUBE_INGRESS_BASE_DOMAIN}"
echo "DOMAIN=${DOMAIN}"
echo "VARIABLES_FILE=${VARIABLES_FILE}"
echo "KUBE_NAMESPACE=${KUBE_NAMESPACE}"
echo "NAMESPACE=${NAMESPACE}"
echo "VCLUSTER_NAME=${VCLUSTER_NAME}"
echo "VCLUSTER_K8S_VERSION=${VCLUSTER_K8S_VERSION}"

deploy_external_components
deploy
wait_for_deploy
check_domain_ip

# Generate variables file
echo "export GITLAB_RELEASE_NAME=$(gitlab_release_name)"                           >> "${VARIABLES_FILE}"
echo "export GITLAB_URL=gitlab-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"         >> "${VARIABLES_FILE}"
echo "export GITLAB_ROOT_DOMAIN=${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"        >> "${VARIABLES_FILE}"
echo "export REGISTRY_URL=registry-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"     >> "${VARIABLES_FILE}"
echo "export S3_ENDPOINT=https://minio-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}" >> "${VARIABLES_FILE}"
echo "export QA_GITLAB_REVISION=$(get_qa_revision)"                                >> "${VARIABLES_FILE}"