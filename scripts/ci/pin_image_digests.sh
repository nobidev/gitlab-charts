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
# Auxiliary file populated by get_digest as a side effect. Each line is
# `<component>\t<build-pipeline URL>`. Subshell-safe (every tag_and_digest
# runs in $(...) so a bash variable wouldn't propagate). Read by
# check_cng_pipeline_consistency after render_digests_file completes.
CNG_PIPELINE_URLS_FILE="${CNG_PIPELINE_URLS_FILE:-$PROJECT_ROOT/cng_pipeline_urls.txt}"

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
# As a side effect, records the image's `build-pipeline` label (the CNG pipeline
# URL that built it) to CNG_PIPELINE_URLS_FILE for the later consistency check.
# Echo output is the digest only — callers and bats tests are unchanged.
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
  pipeline_url=""

  while [ $attempt -le $max_retries ]; do
    # Try to fetch digest + build-pipeline label in a single skopeo inspect.
    # All error details are captured in skopeo_errors.log for later analysis.
    if output=$(skopeo inspect docker://registry.gitlab.com/gitlab-org/build/cng/$component:$tag --format '{{.Digest}}|{{index .Labels "build-pipeline"}}' --no-tags 2>>"skopeo_errors.log"); then
      digest="${output%%|*}"
      pipeline_url="${output#*|}"
      # Subshell-safe side-channel: write to a file rather than a variable.
      printf '%s\t%s\n' "${component}" "${pipeline_url}" >> "${CNG_PIPELINE_URLS_FILE}"
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
  rm -f $DIGESTS_FILE $CNG_PIPELINE_URLS_FILE
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

# Verifies all pinned CNG images came from the same CNG build pipeline. CNG
# bakes the originating pipeline URL into a `build-pipeline` label on each
# image, recorded by get_digest into CNG_PIPELINE_URLS_FILE during pin
# resolution (so no extra skopeo round trips are needed here).
#
# CNG content-addressable builds skip rebuilds when a component's inputs
# haven't changed, so per-component :master tags can drift across successive
# CNG pipelines. A drifted set means the chart pinned images from potentially
# different gitlab-org/gitlab commits, which causes schema drift between
# migrations and webservice and produces "Progress deadline exceeded" rollout
# timeouts on webservice and sidekiq.
# See: https://gitlab.com/gitlab-org/charts/gitlab/-/work_items/6478
function check_cng_pipeline_consistency() {
  echo ""
  echo "Verifying CNG build-pipeline consistency across pinned components..."

  if [ ! -s "${CNG_PIPELINE_URLS_FILE}" ]; then
    echo "WARN: ${CNG_PIPELINE_URLS_FILE} is empty or missing; skipping consistency check."
    return 0
  fi

  # Each line is `<component>\t<build-pipeline URL>`. Drop entries with empty
  # URL (older CNG images without the label) and dedup (toolbox is pinned twice).
  filtered=$(awk -F'\t' '$2 != ""' "${CNG_PIPELINE_URLS_FILE}" | sort -u)
  if [ -z "${filtered}" ]; then
    echo "WARN: no pinned image carried a build-pipeline label; skipping consistency check."
    return 0
  fi

  unique_pipelines=$(printf '%s\n' "${filtered}" | awk -F'\t' '{print $2}' | sort -u)
  pipeline_count=$(printf '%s\n' "${unique_pipelines}" | wc -l | tr -d ' ')

  while IFS= read -r pl; do
    comps=$(printf '%s\n' "${filtered}" | awk -F'\t' -v p="${pl}" '$2 == p { print "    " $1 }')
    comp_count=$(printf '%s\n' "${comps}" | wc -l | tr -d ' ')
    suffix=""
    [ "${comp_count}" -ne 1 ] && suffix="s"
    printf '  pipeline %s (%d component%s):\n%s\n' "${pl}" "${comp_count}" "${suffix}" "${comps}"
  done <<< "${unique_pipelines}"

  if [ "${pipeline_count}" -le 1 ]; then
    echo "OK: all pinned CNG images came from the same build pipeline."
    return 0
  fi

  cat >&2 <<MSG

ERROR: CNG image-tag drift detected — pinned :master images come from ${pipeline_count} different CNG build pipelines.

This typically happens when CNG content-addressable builds skip unchanged
components: each component's :master tag stays at whichever earlier pipeline
last rebuilt it. The chart pins those :master digests, so the resulting set
spans multiple CNG pipelines (and therefore potentially multiple
gitlab-org/gitlab commits). Mismatched Rails-stack source SHAs cause schema
drift between migrations and webservice, producing "Progress deadline
exceeded" rollout timeouts on webservice and sidekiq.

Retry this job once a more recent CNG master pipeline run has touched every
pinned component, or follow up at:
https://gitlab.com/gitlab-org/charts/gitlab/-/work_items/6478

MSG
  return 1
}

(return 0 2>/dev/null) && SOURCED=1 || SOURCED=0
main
