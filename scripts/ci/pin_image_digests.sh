#!/bin/bash
set -e

# This script collects the current digest for each specified image
# and writes the results into a Helm values file. This allows us
# to ensure that each image is running from the same CNG image build,
# and are therefore aligned - especially in relation to the migrations.
#
# Dependencies:
# - skopeo
#
# Debug Files:
# - skopeo_errors.log: Captures detailed error output from skopeo for debugging
#   This file should be included as a CI artifact to help diagnose registry issues
#
# Usage:
# $ bash ./scripts/ci/pin_image_digests.sh

PROJECT_ROOT="$(dirname -- "${BASH_SOURCE[0]}")/../.."
DIGESTS_FILE="${DIGESTS_FILE:-$PROJECT_ROOT/ci.digests.yaml}"
CHART_FILE="${CHART_FILE:-$PROJECT_ROOT/Chart.yaml}"

function main() {
  if [ $SOURCED -eq 0 ]; then
    render_digests_file
    check_cng_pipeline_consistency
  fi
}

function get_gitlab_app_version_for_branch() {
  git fetch origin "${1}" --quiet
  git show origin/"${1}":Chart.yaml | grep 'appVersion:' | awk '{print $2}'
}

function get_image_branch_for_gitlab_app_version() {
  # turn vX.Y.Z / X.Y.Z into X-Y-stable
  echo "${1}" | sed -E 's/^v?([0-9]+)\.([0-9]+)\.([0-9]+)$/\1-\2-stable/'
}

# Gets the correct image tag to use.
# Usage:
#   `get_tag gitlab-webservice-ee`
function get_tag() {
  # Use the gitlab version from the environment or use stable images when on the stable branch
  gitlab_app_version=$(grep 'appVersion:' $CHART_FILE | awk '{ print $2}')

  if [[ -n "${GITLAB_VERSION}" ]]; then
    image_branch=$GITLAB_VERSION
  elif [[ "${CI_COMMIT_BRANCH}" =~ -stable$ ]] && [[ "${gitlab_app_version}" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    image_branch=$(get_image_branch_for_gitlab_app_version "${gitlab_app_version}")
  elif [[ "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}" =~ -stable$ ]]; then
    stable_gitlab_app_version=$(get_gitlab_app_version_for_branch "${CI_MERGE_REQUEST_TARGET_BRANCH_NAME}")
    image_branch=$(get_image_branch_for_gitlab_app_version "${stable_gitlab_app_version}")
  fi

  if [[ -n "$image_branch" ]]; then
    echo -n "$image_branch"
  else
    echo -n "$gitlab_app_version"
  fi
}

# Gets the current digest for the given image name and image tag.
# Usage:
#   `get_digest gitlab-webservice-ee master`
function get_digest() {
  component=$1
  tag=$2

  # Retry configuration
  max_retries=${GET_DIGEST_MAX_RETRIES:-3}
  base_delay=${GET_DIGEST_BASE_DELAY:-2}
  attempt=1
  digest=""

  while [ $attempt -le $max_retries ]; do
    # Try to get the digest, with failures logged silently
    # All error details are captured in skopeo_errors.log for later analysis
    if digest=$(skopeo inspect docker://registry.gitlab.com/gitlab-org/build/cng/$component:$tag --format "{{.Digest}}" --no-tags 2>>"skopeo_errors.log"); then
      # Success - return the digest without any logging
      echo -n "${digest}"
      return 0
    fi

    # Only log retry information if this isn't the last attempt
    if [ $attempt -lt $max_retries ]; then
      delay=$((base_delay * (2 ** (attempt - 1))))
      echo "Retry $attempt/$max_retries: Failed to get digest for $component:$tag, retrying in ${delay}s..." >&2
      sleep $delay
    fi

    attempt=$((attempt + 1))
  done

  # Only log error after retries have been exhausted
  echo "Error: Failed to get digest for $component:$tag after $max_retries attempts" >&2
  echo "Detailed error information:" >&2
  cat skopeo_errors.log >&2
  return 1
}

# Gets the tag and digest to use in `<component>.image.tag`.
# Usage:
#   `tag_and_digest gitlab-webservice-ee`
function tag_and_digest() {
  component=$1
  tag=$(get_tag $component)
  
  if ! digest=$(get_digest $component $tag); then
    echo "Error: Failed to get digest for $component, exiting" >&2
    exit 1
  fi

  echo -n "${tag}@${digest}"
}

# Render image digests to a file that is later provided for chart values.
# Usage:
#   `render_digests_file`
function render_digests_file() {
  rm -f $DIGESTS_FILE
  cat << CIYAML > $DIGESTS_FILE
# generated: $(date)
global:
  gitlabBase:
    image:
      tag: "$(tag_and_digest gitlab-base)"
  certificates:
    image:
      tag: "$(tag_and_digest certificates)"
  kubectl:
    image:
      tag: "$(tag_and_digest kubectl)"
gitlab:
  gitaly:
    image:
      tag: "$(tag_and_digest gitaly)"
  gitlab-exporter:
    image:
      tag: "$(tag_and_digest gitlab-exporter)"
  gitlab-shell:
    image:
      tag: "$(tag_and_digest gitlab-shell)"
  kas:
    image:
      tag: "$(tag_and_digest gitlab-kas)"
  migrations:
    image:
      tag: "$(tag_and_digest gitlab-toolbox-ee)"
  sidekiq:
    image:
      tag: "$(tag_and_digest gitlab-sidekiq-ee)"
  toolbox:
    image:
      tag: "$(tag_and_digest gitlab-toolbox-ee)"
  webservice:
    image:
      tag: "$(tag_and_digest gitlab-webservice-ee)"
    workhorse:
      tag: "$(tag_and_digest gitlab-workhorse-ee)"
registry:
  image:
    tag: "$(tag_and_digest gitlab-container-registry)"
CIYAML

  echo "Finished writing $DIGESTS_FILE."

}

# Reads a single label off an image by digest. Echoes the label value (possibly
# empty) on success, or empty + non-zero on skopeo failure.
# Usage:
#   `get_label_for_digest gitlab-toolbox-ee sha256:abc… build-pipeline`
function get_label_for_digest() {
  component=$1
  digest=$2
  label=$3

  skopeo inspect \
    --override-os linux --override-arch amd64 --no-tags \
    --format "{{index .Labels \"${label}\"}}" \
    "docker://registry.gitlab.com/gitlab-org/build/cng/${component}@${digest}" \
    2>>"skopeo_errors.log"
}

# Returns 0 if every argument is identical, 1 otherwise. Isolated so the
# comparison logic is unit-testable without skopeo.
# Usage:
#   `_pipelines_match url-a url-a url-a`  # exit 0
#   `_pipelines_match url-a url-a url-b`  # exit 1
function _pipelines_match() {
  first=$1
  shift
  for v in "$@"; do
    [ "${v}" = "${first}" ] || return 1
  done
  return 0
}

# Verifies the Rails-derived CNG images (toolbox, sidekiq, webservice) that we
# just pinned all came from the same CNG build pipeline. CNG bakes the
# originating pipeline URL into a `build-pipeline` label on each image. When a
# CNG master pipeline partially fails, the floating `:master` tags can end up
# pointing at different CNG pipelines (and therefore different gitlab-org/gitlab
# commits) for different components, which means the chart's migrations Job
# runs the schema for one commit while webservice expects newer migrations from
# another — producing "Progress deadline exceeded" rollout timeouts on
# webservice and sidekiq.
# See: https://gitlab.com/gitlab-org/charts/gitlab/-/work_items/6478
function check_cng_pipeline_consistency() {
  components="gitlab-toolbox-ee gitlab-sidekiq-ee gitlab-webservice-ee"
  has_unlabeled=0
  pipeline_urls=""
  report=""

  echo ""
  echo "Verifying CNG build-pipeline consistency for Rails-derived images..."

  for component in ${components}; do
    tag=$(get_tag "${component}")
    if ! digest=$(get_digest "${component}" "${tag}"); then
      echo "ERROR: could not resolve digest for ${component} during consistency check" >&2
      return 1
    fi

    pipeline_url=$(get_label_for_digest "${component}" "${digest}" "build-pipeline" || true)

    if [ -z "${pipeline_url}" ]; then
      report="${report}  ${component}: <no build-pipeline label>
"
      has_unlabeled=1
      continue
    fi

    pipeline_urls="${pipeline_urls} ${pipeline_url}"
    report="${report}  ${component}: ${pipeline_url}
"
  done

  printf '%s' "${report}"

  if [ "${has_unlabeled}" -eq 1 ]; then
    echo "WARN: at least one image lacks the build-pipeline label; skipping consistency check."
    return 0
  fi

  if _pipelines_match ${pipeline_urls}; then
    echo "OK: all Rails-derived images built by the same CNG pipeline."
    return 0
  fi

  cat >&2 <<'MSG'

ERROR: CNG image-tag drift detected.

The Rails-derived CNG images this pipeline pinned were built by different CNG
build pipelines, meaning they may have been built from different
gitlab-org/gitlab commits. Deploying this combination causes schema drift: the
migrations container runs the schema for one commit while the webservice
container expects newer migrations from another, producing "Progress deadline
exceeded" rollout timeouts on webservice and sidekiq.

Drifting images and their CNG build pipelines:
MSG
  printf '%s' "${report}" >&2
  cat >&2 <<'MSG'

This is typically caused by a partial failure in a CNG master pipeline where
some component builds succeed and push :master while others leave older
:master tags in place. Retry this job once the next successful CNG master
pipeline run has finished.

Root-cause discussion: https://gitlab.com/gitlab-org/charts/gitlab/-/work_items/6478
MSG
  return 1
}

(return 0 2>/dev/null) && SOURCED=1 || SOURCED=0
main
