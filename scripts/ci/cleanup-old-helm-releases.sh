#!/bin/bash
set -euo pipefail

NAMESPACE=${NAMESPACE:-"helm-charts-win"}
DAYS_AGO=${DAYS_AGO:-2}

_context=()
if [ -n "${KCTX:-}" ]; then
  _context=("--kube-context=${KCTX}")
fi

if date --version &>/dev/null; then
  TS=$(date --date "${DAYS_AGO} days ago" '+%s')
else
  TS=$(date -v-${DAYS_AGO}d '+%s')
fi

list(){
  helm "${_context[@]}" --namespace="${NAMESPACE}" ls -o json \
    | jq -r --argjson timestamp "$TS" '.[] | select (.updated | sub("\\..*";"Z") | sub("\\s";"T") | fromdate < $timestamp) | "\(.name) \(.updated)"' \
    | { [ -n "${FILTER:-}" ] && grep -F -- "${FILTER}" || cat; }
}

reap(){
  local releases
  releases=$(list | cut -d' ' -f1)
  [ -z "$releases" ] && return 0
  if [ "${DRY_RUN:-}" == "false" ]; then
    echo "$releases" | xargs -n1 helm "${_context[@]}" --namespace="${NAMESPACE}" uninstall
  else
    echo "DRY_RUN enabled — would uninstall:"
    echo "$releases"
  fi
}

if [ "${1:-}" == "reap" ]; then
  reap
else
  list
fi
