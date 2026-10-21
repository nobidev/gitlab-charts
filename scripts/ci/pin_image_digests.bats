#!/bin/bash
set -e

# This script tests the behavior of the pin_image_digests.sh
# script using bats
#
# Dependencies:
# - skopeo  # from script being tested
# - bats
# - helm
#
# Usage:
# $ bats scripts/ci/pin_image_digests_test.sh

setup() {
  unset GITLAB_VERSION # set by CNG-triggered pipelines
  unset CI_MERGE_REQUEST_TARGET_BRANCH_NAME # backports to stable branches use the stable branch tag
}

@test "tag_and_digest, on master branch" {
  CHART_FILE='Chart.master.yaml'
  echo 'appVersion: master' > $CHART_FILE

  expected='^master@sha256:[[:xdigit:]]{64}$'

  source scripts/ci/pin_image_digests.sh
  run tag_and_digest 'gitlab-webservice-ee'

  [ "$status" -eq 0 ]
  [[ "$output" =~ $expected ]]
}

@test "tag_and_digest, with GITLAB_VERSION" {
  GITLAB_VERSION='v16.8.0'

  expected="^$GITLAB_VERSION@sha256:[[:xdigit:]]{64}$"

  source scripts/ci/pin_image_digests.sh
  run tag_and_digest 'gitlab-webservice-ee'

  [ "$status" -eq 0 ]
  [[ "$output" =~ $expected ]]
}

@test "tag_and_digest, on stable branch" {
  CI_COMMIT_BRANCH='7-8-stable'
  CHART_FILE='Chart.stable.yaml'
  echo 'appVersion: v16.8.0' > $CHART_FILE

  expected='^[0-9]+-[0-9]+-stable@sha256:[[:xdigit:]]{64}$'

  source scripts/ci/pin_image_digests.sh
  run tag_and_digest 'gitlab-webservice-ee'

  [ "$status" -eq 0 ]
  [[ "$output" =~ $expected ]]
}

@test "tag_and_digest, on merge request branch targeting stable" {
  CI_MERGE_REQUEST_TARGET_BRANCH_NAME='7-8-stable'

  expected='^[0-9]+-[0-9]+-stable@sha256:[[:xdigit:]]{64}$'

  source scripts/ci/pin_image_digests.sh
  run tag_and_digest 'gitlab-webservice-ee'

  [ "$status" -eq 0 ]
  [[ "$output" =~ $expected ]]
}

# Images missing from render_digests_file fall back to `global.gitlabVersion`,
# whose release tag is not published yet while a release is being prepared.
@test "rendering digests file with helm template" {
  DIGESTS_FILE="$BATS_TEST_TMPDIR/ci.digests.yaml"
  REQUIRED_VALUES_FILE="$BATS_TEST_TMPDIR/required.values.yaml"
  source scripts/ci/pin_image_digests.sh

  # Use the stable image tag matching the chart's appVersion (for example
  # `19-1-stable` for `v19.1.9`, or `master` on master), as stable branch
  # pipelines do. The `vX.Y.Z` tag is not published yet while a stable
  # branch prepares a release.
  GITLAB_VERSION=$(get_image_branch_for_gitlab_app_version "$(awk '/^appVersion:/ { print $2 }' "$CHART_FILE")")

  render_digests_file

  # Read the tag back instead of calling tag_and_digest again, which could
  # resolve a newer digest.
  image_tag=$(awk '/gitlabBase:/ { found = 1 } found && /tag:/ { gsub(/"/, "", $2); print $2; exit }' "$DIGESTS_FILE")
  [ -n "$image_tag" ]

  expected="image: \"registry.gitlab.com/gitlab-org/build/cng/gitlab-base:$image_tag\""

  cat << CIYAML > $REQUIRED_VALUES_FILE
certmanager-issuer:
  email: ci@gitlab.com
CIYAML

  helm dependency build
  run helm template . -f $REQUIRED_VALUES_FILE -f $DIGESTS_FILE

  [ "$status" -eq 0 ]
  [[ "$output" =~ $expected ]]

  unpinned=$(echo "$output" \
    | grep -oE "registry\.gitlab\.com/gitlab-org/build/cng/[^\"'[:space:]]+" \
    | grep -v '@sha256:' | sort -u || true)

  if [ -n "$unpinned" ]; then
    echo "CNG images not pinned by render_digests_file:"
    echo "$unpinned"
    return 1
  fi
}
