#!/bin/bash
set -euo pipefail

KUBECTL=${KUBECTL:-kubectl}
HELM=${HELM:-helm}
NAMESPACE=${NAMESPACE:-helm-charts-win}
NAMESPACE_SCOPED_RESOURCES="ingress,svc,pdb,hpa,deploy,statefulset,replicaset,job,pod,secret,configmap,pvc,role,rolebinding,sa"

_context=()
_helm_context=()
if [ -n "${KCTX:-}" ]; then
  _context=("--context" "${KCTX}")
  _helm_context=("--kube-context" "${KCTX}")
fi

ghost_releases=$(comm -23 \
    <("${KUBECTL}" "${_context[@]}" -n "${NAMESPACE}" get ${NAMESPACE_SCOPED_RESOURCES} -ojson \
        | jq -r '.items[] | select(.metadata.name | test("rvw-")) | select(.metadata.labels | has("release")) | .metadata.labels.release' \
        | sort -u) \
    <("${HELM}" "${_helm_context[@]}" ls -n "${NAMESPACE}" -q | sort -u))

echo_ghosts(){
  echo "====================="
  echo "Ghost releases found:"
  echo "====================="
  echo "${ghost_releases}"
  echo "====================="
}

reap_ghosts(){
  for rel in $ghost_releases; do
    if [ "${DRY_RUN:-}" == "true" ]; then
      echo "DRY_RUN enabled — would delete resources for release: ${rel}"
    else
      "${KUBECTL}" "${_context[@]}" delete -n "${NAMESPACE}" ${NAMESPACE_SCOPED_RESOURCES} \
        -l "release=${rel}" --ignore-not-found --force --grace-period=0
    fi
  done
}

echo_ghosts

cmd=${1:-""}
if [ "${cmd}" == "reap" ]; then
  reap_ghosts
fi
