#!/bin/bash
# Deploy the GitLab chart to a k3d cluster and write the VARIABLES_FILE consumed
# by downstream spec/QA steps within the same job.
#
# 18.10-specific: this branch's autodevops.sh derives RELEASE_NAME from
# CI_ENVIRONMENT_SLUG (empty for k3d jobs) and has no gitlab_release_name /
# get_qa_revision / create_admin_pat helpers, so this script sets RELEASE_NAME
# explicitly and inlines the toolbox revision + admin-PAT steps.

source scripts/ci/autodevops.sh
source scripts/ci/k3d.sh

# k3d jobs have no CI environment; give the release a unique name from the
# per-job HOST_SUFFIX (set to CI_JOB_ID by .k3d_base).
RELEASE_NAME="rvw-${HOST_SUFFIX}"
RELEASE_NAME="${RELEASE_NAME:0:30}"
RELEASE_NAME="${RELEASE_NAME%-}"
export RELEASE_NAME

echo "CI_COMMIT_SHORT_SHA=${CI_COMMIT_SHORT_SHA}"
echo "HOST_SUFFIX=${HOST_SUFFIX}"
echo "KUBE_INGRESS_BASE_DOMAIN=${KUBE_INGRESS_BASE_DOMAIN}"
echo "VARIABLES_FILE=${VARIABLES_FILE}"
echo "NAMESPACE=${NAMESPACE}"
echo "RELEASE_NAME=${RELEASE_NAME}"
echo "K3D_K8S_IMAGE=${K3D_K8S_IMAGE}"

mkdir -p "$(dirname "${VARIABLES_FILE}")"

deploy_external_components
deploy
wait_for_deploy
# check_domain_ip is skipped: nip.io resolves immediately without DNS propagation

echo "export GITLAB_RELEASE_NAME=${RELEASE_NAME}"                                >> "${VARIABLES_FILE}"
# run_specs.sh sources this file and then runs feature_spec_setup.sh + the spec
# helpers (spec/gitlab_test_helper.rb), which read $RELEASE_NAME to find the
# minio secret and to scope `kubectl scale -l release=...`. Export it explicitly
# (the chart-derived GITLAB_RELEASE_NAME above is a different variable name).
echo "export RELEASE_NAME=${RELEASE_NAME}"                                       >> "${VARIABLES_FILE}"
echo "export GITLAB_URL=gitlab-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"        >> "${VARIABLES_FILE}"
echo "export GITLAB_ROOT_DOMAIN=${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"       >> "${VARIABLES_FILE}"
echo "export REGISTRY_URL=registry-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}"    >> "${VARIABLES_FILE}"
echo "export PROTOCOL=http"                                                       >> "${VARIABLES_FILE}"

# Wait for the toolbox pod and capture the deployed GitLab revision so QA can
# pull the matching gitlab-ee-qa image.
kubectl wait pods -n "${NAMESPACE}" -l app=toolbox,release="${RELEASE_NAME}" --for condition=Ready --timeout=300s
toolbox_pod=$(kubectl get pods -n "${NAMESPACE}" -lrelease="${RELEASE_NAME}",app=toolbox -o custom-columns=":metadata.name" --no-headers | tr -d '[:space:]')
echo "export QA_GITLAB_REVISION=$(kubectl exec -n "${NAMESPACE}" "${toolbox_pod}" -ic toolbox -- cat /srv/gitlab/REVISION)" >> "${VARIABLES_FILE}"

# k3d has no shared admin token; create a fresh admin PAT against this instance.
runner_output=$(kubectl exec -n "${NAMESPACE}" "${toolbox_pod}" -ic toolbox -- \
  gitlab-rails runner "
    u = User.find_by_username('root')
    t = u.personal_access_tokens.create!(
      name: 'k3d-qa-admin',
      scopes: [:api],
      expires_at: 1.day.from_now
    )
    puts t.token
  " 2>&1)
# GitLab 17+ PAT tokens include a routing suffix with dots, e.g. glpat-xxx.01.yyy
admin_pat=$(echo "${runner_output}" | grep -oE 'glpat-[A-Za-z0-9._-]+')
if [ -z "${admin_pat}" ]; then
  echo "ERROR: create admin PAT returned empty — cannot proceed without admin token" >&2
  echo "${runner_output}" >&2
  exit 1
fi
echo "export GITLAB_ADMIN_TOKEN=${admin_pat}"                                     >> "${VARIABLES_FILE}"
