#!/usr/bin/env bash

# Waits until the GitLab Helm chart version is available on charts.gitlab.io,
# then exits with success or failure based on the result.
#
# Usage: wait_for_charts_availability.sh <version>
# Example: wait_for_charts_availability.sh 8.5.0

set -euo pipefail

CHART_VERSION="${1:?chart version is required}"
CHART_REPO_URL="https://charts.gitlab.io/"
POLL_INTERVAL=${POLL_INTERVAL:-30}
MAX_WAIT_SECONDS=${MAX_WAIT_SECONDS:-5400}  # 90 minutes

if ! [[ "${POLL_INTERVAL}" =~ ^[0-9]+$ ]] || ! [[ "${MAX_WAIT_SECONDS}" =~ ^[0-9]+$ ]]; then
  echo "Error: POLL_INTERVAL and MAX_WAIT_SECONDS must be positive integers"
  exit 1
fi

echo "Waiting for GitLab Helm chart version ${CHART_VERSION} to be available on ${CHART_REPO_URL}"

if ! helm repo add gitlab "${CHART_REPO_URL}" 2>/dev/null && ! helm repo update gitlab 2>/dev/null; then
  echo "Error: failed to add or update Helm repo ${CHART_REPO_URL}"
  exit 1
fi

elapsed=0
while [[ $elapsed -lt $MAX_WAIT_SECONDS ]]; do
  if helm repo update gitlab && helm show chart gitlab/gitlab --version "${CHART_VERSION}" > /dev/null 2>&1; then
    echo "GitLab Helm chart version ${CHART_VERSION} is available on ${CHART_REPO_URL}"
    exit 0
  fi

  echo "Chart version ${CHART_VERSION} not yet available (elapsed: ${elapsed}s), retrying in ${POLL_INTERVAL}s..."
  sleep "${POLL_INTERVAL}"
  elapsed=$((elapsed + POLL_INTERVAL))
done

echo "Timed out after ${MAX_WAIT_SECONDS}s waiting for GitLab Helm chart version ${CHART_VERSION} on ${CHART_REPO_URL}"
exit 1
