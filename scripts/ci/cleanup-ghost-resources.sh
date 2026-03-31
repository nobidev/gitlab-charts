#!/bin/bash

KUBECTL=${KUBECTL:-kubectl}
HELM=${HELM:-helm}
NAMESPACE=${NAMESPACE:-helm-charts-win}
ALL_THE_THINGS="ingress,svc,pdb,hpa,deploy,statefulset,replicaset,job,pod,secret,configmap,pvc,secret,clusterrole,clusterrolebinding,role,rolebinding,sa"

_context=""
_helm_context=""
if [ -n "${KCTX}" ]; then
  _context="--context ${KCTX}"
  _helm_context="--kube-context ${KCTX}"
fi

ghost_releases=$(comm -23 \
    <(${KUBECTL} ${_context} -n ${NAMESPACE} get ${ALL_THE_THINGS} -ojson |  jq -r '.items[] | select(.metadata.name | test("rvw-")) | select(.metadata.labels | has("release")).metadata.labels.release' | sort -u) \
    <(${HELM} ${_helm_context} ls -n ${NAMESPACE} -q | sort))

echo_ghosts(){
  echo "====================="
  echo "Ghost releases found:"
  echo "====================="
  echo "${ghost_releases}"
  echo "====================="
}

reap_ghosts(){
  for rel in $ghost_releases
  do
    ${KUBECTL} delete ${_context} -n ${NAMESPACE} ${ALL_THE_THINGS} -lrelease=$rel --force
  done
}

echo_ghosts

cmd=${1:-""}
if [ "${cmd}" == "reap" ]; then
  reap_ghosts
fi
