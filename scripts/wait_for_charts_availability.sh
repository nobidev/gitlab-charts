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
MAX_WAIT_SECONDS=${MAX_WAIT_SECONDS:-600}  # 10 minutes
HELM_SHOW_TIMEOUT_SECONDS=${HELM_SHOW_TIMEOUT_SECONDS:-30}

if ! [[ "${POLL_INTERVAL}" =~ ^[1-9][0-9]*$ ]] || ! [[ "${MAX_WAIT_SECONDS}" =~ ^[1-9][0-9]*$ ]] || ! [[ "${HELM_SHOW_TIMEOUT_SECONDS}" =~ ^[1-9][0-9]*$ ]]; then
  echo "Error: POLL_INTERVAL, MAX_WAIT_SECONDS, and HELM_SHOW_TIMEOUT_SECONDS must be positive integers greater than zero"
  exit 1
fi

echo "Waiting for GitLab Helm chart version ${CHART_VERSION} to be available on ${CHART_REPO_URL}"

helm repo add gitlab "${CHART_REPO_URL}" 2>/dev/null || true

if ! helm repo update; then
  echo "Error: failed to update Helm repos"
  exit 1
fi

SECONDS=0
while [[ $SECONDS -lt $MAX_WAIT_SECONDS ]]; do
  if timeout "${HELM_SHOW_TIMEOUT_SECONDS}s" helm show chart gitlab/gitlab --version "${CHART_VERSION}" > /dev/null 2>&1; then
    echo "GitLab Helm chart version ${CHART_VERSION} is available on ${CHART_REPO_URL}"
    exit 0
  fi

  echo "Chart version ${CHART_VERSION} not yet available (elapsed: ${SECONDS}s), retrying in ${POLL_INTERVAL}s..."
  sleep "${POLL_INTERVAL}"
done

echo "Timed out after ${MAX_WAIT_SECONDS}s waiting for GitLab Helm chart version ${CHART_VERSION} on ${CHART_REPO_URL}"
exit 1
