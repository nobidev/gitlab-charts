#!/bin/bash

function cluster_connect() {
  if [ -z ${AGENT_NAME+x} ] || [ -z ${AGENT_PROJECT_PATH+x} ]; then
    echo "No AGENT_NAME or AGENT_PROJECT_PATH set, using the default"
  else
    kubectl config get-contexts
    kubectl config use-context ${AGENT_PROJECT_PATH}:${AGENT_NAME}
  fi
}

function vcluster_install() {
  if command -v vcluster &> /dev/null; then
    # Get the installed version
    INSTALLED_VERSION=$(vcluster version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    
    if [ "$INSTALLED_VERSION" = "$VCLUSTER_VERSION" ]; then
        echo "vcluster is installed with the correct version"
        return
    else
        echo "vcluster ${INSTALLED_VERSION} is installed but version mismatch (expected $VCLUSTER_VERSION)"
    fi
  else
    echo "vcluster is not installed"
  fi

  echo "Install vcluster version ${VCLUSTER_VERSION}"
  curl -Lo /tmp/vcluster "https://github.com/loft-sh/vcluster/releases/download/v${VCLUSTER_VERSION}/vcluster-linux-amd64"
  install -c -m 0755 /tmp/vcluster /usr/local/bin
}

function vcluster_name() {
  printf ${VCLUSTER_NAME:0:52}
}

function vcluster_create() {
  envsubst < ./scripts/ci/vcluster.template.yaml > ./vcluster.yaml
  cat vcluster.yaml

  local vcluster_name=$(vcluster_name)
  vcluster create ${vcluster_name} \
    --upgrade \
    --namespace=${vcluster_name} \
    --connect=false \
    --values ./vcluster.yaml

  kubectl annotate namespace ${vcluster_name} janitor/ttl=6h
}

function vcluster_run() {
  vcluster connect $(vcluster_name) -- $@
}

function vcluster_copy_secret() {
  kubectl get secret -n $1 $2 -o yaml \
    | sed '/^  namespace: /d; /^  uid: /d; /^  resourceVersion: /d; /^  creationTimestamp: /d; /^  selfLink: /d; /^status:$/Q;' \
    | vcluster_run kubectl apply -n $3 -f -
}

function vcluster_delete() {
  vcluster delete $(vcluster_name) --delete-configmap --delete-namespace --ignore-not-found
}

function vcluster_info() {
  echo "To connect to the virtual cluster:"
  echo "1. Connect to host cluster via kubectl: ${AGENT_NAME}"
  echo "2. Connect to virtual cluster: vcluster connect $(vcluster_name)"
  echo "3. Open a separate terminal window and run your kubectl and helm commands."
}
