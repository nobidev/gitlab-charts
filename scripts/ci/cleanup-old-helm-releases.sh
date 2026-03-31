#!/bin/bash

_context=${KCTX:+"--context=${KCTX}"}
NAMESPACE=${NAMESPACE:-"helm-charts-win"}
DAYS_AGO=${DAYS_AGO:-2}
if date --version &>/dev/null; then
  TS=$(date --date "${DAYS_AGO} days ago" '+%s')
else
  TS=$(date -v-${DAYS_AGO}d '+%s')
fi
_filter=${FILTER:+"grep ${FILTER}"}
_filter=${_filter:-"cat"}

list(){
  helm ${_context} --namespace="${NAMESPACE}" ls -o json \
    | jq -r --argjson timestamp "$TS" '.[] | select (.updated | sub("\\..*";"Z") | sub("\\s";"T") | fromdate < $timestamp) | "\(.name) \(.updated)"' \
    | ${_filter}
}

reap(){
  list | cut -d' ' -f1 | xargs -n1 helm ${_context} --namespace="${NAMESPACE}" uninstall
}

if [ "$1" == "reap" ]; then
  reap
else
  list
fi
