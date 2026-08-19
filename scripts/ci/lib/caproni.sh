#!/bin/bash
#
# Helpers for the Caproni-based CI review environment.
#
# Caproni (https://gitlab.com/gitlab-org/caproni) is the deployment interface for
# GitLab cloud-native development. This library lets the chart's CI deploy the
# working-tree chart through it, so chart authors find out in their own pipeline when
# a change breaks the path Caproni users take. See gitlab-org/charts/gitlab#6505.
#
# Sourced by scripts/ci/caproni_deploy.sh, which also sources autodevops.sh (for
# prepare_values, create_admin_pat, get_qa_*) and k3d.sh (for k3d_docker_host_ip,
# k3d_install, k3d_collect_debug).

# Directory holding caproni.yaml and the values files it references.
CAPRONI_DIR="${CAPRONI_DIR:-scripts/ci/caproni}"
# Merge target. caproni accepts a single values_file per deployer, so the inputs the
# k3d path passes as separate -f flags are deep-merged into this one file.
CAPRONI_VALUES_FILE="${CAPRONI_VALUES_FILE:-${CAPRONI_DIR}/.values/gitlab.values.yaml}"

# caproni_install installs caproni and yq. k3d, kubectl, helm, envsubst and the
# Docker CLI come from k3d_install, which this calls: the Caproni environment runs on
# k3d and needs exactly the same toolchain.
function caproni_install() {
  # Same detection as k3d_install, but caproni's release assets use goreleaser's
  # naming, which keeps x86_64 and shortens aarch64 to arm64.
  local arch caproni_arch
  arch=$(uname -m)
  case "$arch" in
    x86_64)  arch="amd64"; caproni_arch="x86_64" ;;
    aarch64) arch="arm64"; caproni_arch="arm64" ;;
    *) echo "Unsupported architecture: $arch"; exit 1 ;;
  esac

  k3d_install

  if ! command -v yq &>/dev/null; then
    local yq_version="${YQ_VERSION:-4.53.3}"
    echo "Installing yq v${yq_version}"
    curl -Lso /usr/local/bin/yq \
      "https://github.com/mikefarah/yq/releases/download/v${yq_version}/yq_linux_${arch}"
    chmod +x /usr/local/bin/yq
    echo "yq $(yq --version) installed"
  else
    echo "yq already available: $(yq --version)"
  fi

  if ! command -v caproni &>/dev/null; then
    local caproni_version="${CAPRONI_VERSION:-4.0.0}"
    echo "Installing caproni v${caproni_version} (${caproni_arch})"
    # Pinned generic-package download rather than mise. This repository has no mise
    # bootstrap in CI, and pulling one in for a single binary would be a larger
    # change than the pattern k3d_install already establishes.
    curl -Lo /tmp/caproni.tgz \
      "https://gitlab.com/api/v4/projects/gitlab-org%2Fcaproni/packages/generic/caproni/${caproni_version}/caproni_${caproni_version}_Linux_${caproni_arch}.tar.gz"
    tar -xz -C /usr/local/bin -f /tmp/caproni.tgz caproni
    chmod +x /usr/local/bin/caproni
    echo "caproni $(caproni version) installed"
  else
    echo "caproni already available: $(caproni version)"
  fi
}

# caproni_merge_values deep-merges the values inputs into CAPRONI_VALUES_FILE.
#
# Expects prepare_values() to have populated .values/ already. Merge order matches
# the -f order in deploy() in autodevops.sh, so later files win, and yq's `*`
# operator deep-merges maps and replaces arrays exactly as helm's -f coalescing does.
function caproni_merge_values() {
  local values_dir="${PROJECT_ROOT:-.}/.values"
  local digests="${PROJECT_ROOT:-.}/ci.digests.yaml"

  mkdir -p "$(dirname "${CAPRONI_VALUES_FILE}")"

  # ci-license.values.yaml points global.gitlab.license.secret at a Secret that
  # autodevops.sh's deploy() creates before `helm upgrade`. Caproni has no
  # pre-deploy hook carrying a kubeconfig, so that Secret cannot exist yet, and the
  # migrations Job mounts it unconditionally once the value is set - leaving the
  # reference in place would stop that pod from ever starting. Drop the reference
  # and keep the GITLAB_LICENSE_MODE / CUSTOMER_PORTAL_URL env; the license is
  # applied post-deploy by caproni_activate_license instead.
  yq 'del(.global.gitlab.license)' \
    "${values_dir}/ci-license.values.yaml" > "${values_dir}/ci-license.caproni.values.yaml"

  if [ ! -f "${digests}" ]; then
    echo "ERROR: ${digests} not found. The job needs the pin_image_versions artifact."
    return 1
  fi

  yq eval-all '. as $item ireduce ({}; . * $item)' \
    "${values_dir}/ci-base.values.yaml" \
    "${values_dir}/ci-scale.values.yaml" \
    "${values_dir}/ci-license.caproni.values.yaml" \
    "${values_dir}/gatewayapi-http.values.yaml" \
    "${CAPRONI_DIR}/values-gitlab.yaml" \
    "${digests}" \
    > "${CAPRONI_VALUES_FILE}"

  echo "Merged caproni values into ${CAPRONI_VALUES_FILE}"

  # Fail loudly rather than 15 minutes into a helm wait.
  if [ "$(yq '.global.gitlab.license // "absent"' "${CAPRONI_VALUES_FILE}")" != "absent" ]; then
    echo "ERROR: global.gitlab.license survived the merge; the migrations Job will not start."
    return 1
  fi
}

# caproni_activate_license applies the EE activation code through the toolbox pod.
#
# The k3d path instead creates a `<release>-gitlab-license` Secret before installing,
# which the migrations Job mounts, so GitLab boots already licensed. Caproni offers no
# equivalent pre-deploy step, so this runs afterwards and GitLab is briefly unlicensed.
# Modelled on scripts/activate-license.sh in gitlab-org/gitlab-caproni.
function caproni_activate_license() {
  if [ -z "${QA_EE_ACTIVATION_CODE}" ]; then
    echo "QA_EE_ACTIVATION_CODE is unset; leaving the instance unlicensed."
    return 0
  fi

  wait_for_toolbox

  local toolbox_pod
  toolbox_pod=$(kubectl get pods -n "${NAMESPACE}" \
    -lrelease="$(gitlab_release_name)",app=toolbox \
    -o custom-columns=":metadata.name" --no-headers | tr -d '[:space:]')

  if [ -z "${toolbox_pod}" ]; then
    echo "ERROR: no toolbox pod found for release $(gitlab_release_name) in ${NAMESPACE}"
    return 1
  fi

  echo "Activating EE license via ${toolbox_pod}"
  # `env VAR=... gitlab-rails runner -` with the script on stdin, rather than passing
  # the code as an argument, so the activation code never appears in the process list
  # or in the job log. Matches scripts/activate-license.sh in gitlab-org/gitlab-caproni.
  kubectl exec -i -n "${NAMESPACE}" "${toolbox_pod}" -c toolbox -- \
    env ACTIVATION_CODE="${QA_EE_ACTIVATION_CODE}" gitlab-rails runner - <<'RUBY'
code = ENV.fetch('ACTIVATION_CODE')
if License.current&.cloud?
  puts "License already active"
else
  license = License.create!(data: code.gsub("\\n", "\n"), cloud: true)
  puts "License activated: #{license.plan}"
end
RUBY
}
