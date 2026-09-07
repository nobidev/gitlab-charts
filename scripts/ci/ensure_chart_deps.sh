#!/bin/bash
#
# Populates ./charts with this chart's dependencies, skipping
# `helm dependency build` if it already matches Chart.lock. Combine with a
# CI cache keyed on Chart.lock (see .chart_deps_cache) to avoid re-downloading
# dependencies that haven't changed.
#
# Helm always re-downloads every dependency on build/update regardless of
# what's already in charts/, hence the manual skip. The stamp file lives
# outside charts/ so Helm's dependency pruning never has to look at it.
set -e

MAX_HELM_REPO_UPDATE_ATTEMPTS=3
HELM_REPO_WAIT_TIMER=5

STAMP_FILE=".chart-lock.sha256"
CURRENT_HASH="$(sha256sum Chart.lock | awk '{print $1}')"

# True only if every dependency Chart.lock declares a repository for (i.e.
# excluding local subcharts) has a matching, non-empty archive in charts/.
# Guards against a stamp file surviving an incomplete/corrupted cache.
charts_complete() {
  while read -r name repository version; do
    [[ "$repository" == '""' ]] && continue
    [[ -s "charts/${name}-${version}.tgz" ]] || return 1
  done < <(awk '/^- name:/{n=$3} /^  repository:/{r=$2} /^  version:/{print n, r, $2}' Chart.lock)
}

if [[ "${FORCE_CHART_DEPS_BUILD:-}" != "true" ]] \
  && [[ -f "$STAMP_FILE" ]] \
  && [[ "$(cat "$STAMP_FILE")" == "$CURRENT_HASH" ]] \
  && charts_complete; then
  echo "charts/ already matches Chart.lock (${CURRENT_HASH}), skipping 'helm dependency build'"
  exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/add_dependency_repos.sh"

echo "Building chart dependencies for Chart.lock (${CURRENT_HASH})..."
while (( MAX_HELM_REPO_UPDATE_ATTEMPTS >= 0 )); do
    if helm dependency build .; then
        echo "$CURRENT_HASH" > "$STAMP_FILE"
        exit 0
    fi

    echo "Failed to build dependencies, trying again in ${HELM_REPO_WAIT_TIMER} seconds..."
    sleep "${HELM_REPO_WAIT_TIMER}"
    (( MAX_HELM_REPO_UPDATE_ATTEMPTS-- ))
done

echo "Failed to build helm dependencies."
exit 1
