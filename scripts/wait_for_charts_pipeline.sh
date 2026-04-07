#!/bin/bash

# Polls a charts.gitlab.io pipeline until it completes, then exits with
# success or failure based on the pipeline result.
#
# Usage: wait_for_charts_pipeline.sh <pipeline_id>

set -euo pipefail

PIPELINE_ID="${1:?pipeline ID is required}"
GITLAB_COM_TOKEN="${COM_CHARTS_READ_TOKEN:?COM_CHARTS_READ_TOKEN is required}"
CHARTS_PROJECT_ID="2860651"
GITLAB_COM_API="https://gitlab.com/api/v4"
PIPELINE_URL="https://gitlab.com/charts/charts.gitlab.io/-/pipelines/${PIPELINE_ID}"
POLL_INTERVAL=${POLL_INTERVAL:-30}
MAX_WAIT_SECONDS=${MAX_WAIT_SECONDS:-5400}  # 90 minutes

echo "Waiting for charts.gitlab.io pipeline: ${PIPELINE_URL}"

elapsed=0
while [[ $elapsed -lt $MAX_WAIT_SECONDS ]]; do
  response=$(curl -fS --silent --header "PRIVATE-TOKEN: ${GITLAB_COM_TOKEN}" "${GITLAB_COM_API}/projects/${CHARTS_PROJECT_ID}/pipelines/${PIPELINE_ID}")
  status=$(echo "${response}" | jq -r '.status')

  echo "Pipeline status: ${status} (elapsed: ${elapsed}s)"

  case "${status}" in
    "success")
      echo "charts.gitlab.io pipeline ${PIPELINE_ID} succeeded: ${PIPELINE_URL}"
      exit 0
      ;;
    "failed"|"canceled"|"canceling"|"skipped")
      echo "charts.gitlab.io pipeline ${PIPELINE_ID} failed with status '${status}': ${PIPELINE_URL}"
      exit 1
      ;;
    *)
      sleep "${POLL_INTERVAL}"
      elapsed=$((elapsed + POLL_INTERVAL))
      ;;
  esac
done

echo "Timed out after ${MAX_WAIT_SECONDS}s waiting for charts.gitlab.io pipeline ${PIPELINE_ID}: ${PIPELINE_URL}"
exit 1
