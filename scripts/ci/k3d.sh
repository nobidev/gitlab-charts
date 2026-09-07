#!/bin/bash

# k3d cluster lifecycle for per-job isolated review environments.
# Each CI job creates its own k3d cluster, eliminating shared host contention.
# See: https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6421

K3D_VERSION="${K3D_VERSION:-5.8.3}"

function k3d_cluster_name() {
  echo -n "gitlab"
}

function k3d_install() {
  local arch docker_arch
  arch=$(uname -m)
  case "$arch" in
    x86_64)  arch="amd64"; docker_arch="x86_64" ;;
    aarch64) arch="arm64"; docker_arch="aarch64" ;;
    *) echo "Unsupported architecture: $arch"; exit 1 ;;
  esac

  # Install envsubst (gettext-base) if not present — used by prepare_values()
  # in autodevops.sh. The debian spec runner image does not include it.
  if ! command -v envsubst &>/dev/null; then
    echo "Installing envsubst (gettext-base)"
    apt-get update -qq && apt-get install -y --no-install-recommends gettext-base
  else
    echo "envsubst already available"
  fi

  # Install Docker CLI if not present — needed for docker login / gitlab-qa.
  # Uses the static binary so no apt repo configuration is required.
  if ! command -v docker &>/dev/null; then
    local docker_version="${DOCKER_VERSION:-28.0.1}"
    echo "Installing Docker CLI v${docker_version} (${docker_arch})"
    curl -Lo /tmp/docker.tgz \
      "https://download.docker.com/linux/static/stable/${docker_arch}/docker-${docker_version}.tgz"
    tar -xz -C /usr/local/bin --strip-components=1 -f /tmp/docker.tgz docker/docker
    echo "Docker CLI $(docker --version) installed"
  else
    echo "Docker CLI already available: $(docker --version)"
  fi

  # Install kubectl if not present — install_spec_dependencies.sh does this for
  # specs jobs but QA jobs don't run that script.
  if ! command -v kubectl &>/dev/null; then
    local kubectl_version="${KUBECTL_VERSION:-1.33.1}"
    echo "Installing kubectl v${kubectl_version}"
    curl -Lso /usr/local/bin/kubectl \
      "https://dl.k8s.io/release/v${kubectl_version}/bin/linux/${arch}/kubectl"
    chmod +x /usr/local/bin/kubectl
    echo "kubectl $(kubectl version --client=true --output=yaml | grep gitVersion) installed"
  else
    echo "kubectl already available: $(kubectl version --client=true --output=yaml | grep gitVersion)"
  fi

  # Install helm if not present — same reasoning as kubectl above.
  if ! command -v helm &>/dev/null; then
    local helm_version="${HELM_VERSION:-4.1.1}"
    echo "Installing helm v${helm_version}"
    curl -Ls "https://get.helm.sh/helm-v${helm_version}-linux-${arch}.tar.gz" \
      | tar -xz -C /usr/local/bin --strip-components=1 "linux-${arch}/helm"
    echo "helm $(helm version --template '{{.Version}}') installed"
  else
    echo "helm already available: $(helm version --template '{{.Version}}')"
  fi

  if command -v k3d &>/dev/null; then
    local installed
    installed=$(k3d version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [ "${installed}" = "${K3D_VERSION}" ]; then
      echo "k3d ${K3D_VERSION} already installed"
      return
    fi
    echo "k3d ${installed} installed but expected ${K3D_VERSION}"
  fi

  echo "Installing k3d v${K3D_VERSION} (${arch})"
  curl -fLo /tmp/k3d "https://github.com/k3d-io/k3d/releases/download/v${K3D_VERSION}/k3d-linux-${arch}"
  install -c -m 0755 /tmp/k3d /usr/local/bin/k3d
  echo "k3d $(k3d version) installed"
}

function k3d_docker_host_ip() {
  # When running with .dind, Docker is at tcp://docker:2375.
  # The DinD host's IP is what we need: k3d will expose ports on it,
  # and nip.io will route back to it from the CI job container.
  if echo "${DOCKER_HOST:-}" | grep -q "docker"; then
    getent hosts docker | awk '{print $1; exit}'
  else
    ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}'
  fi
}

function k3d_create() {
  local cluster_name docker_ip
  cluster_name=$(k3d_cluster_name)
  docker_ip=$(k3d_docker_host_ip)

  echo "Creating k3d cluster '${cluster_name}' (image: ${K3D_K8S_IMAGE})"
  echo "DinD/Docker host IP for port mapping: ${docker_ip}"

  k3d cluster create "${cluster_name}" \
    --image "${DOCKERHUB_PREFIX:-docker.io}/${K3D_K8S_IMAGE}" \
    --api-port "${docker_ip}:6443" \
    --port "22:22@loadbalancer" \
    --port "80:80@loadbalancer" \
    --port "443:443@loadbalancer" \
    --k3s-arg "--disable=traefik@server:0" \
    --wait \
    --timeout 120s

  k3d kubeconfig get "${cluster_name}" > /tmp/k3d-kubeconfig.yaml
  export KUBECONFIG=/tmp/k3d-kubeconfig.yaml

  # nip.io domain: *.IP.nip.io resolves to IP — zero-config DNS for the CI job
  export KUBE_INGRESS_BASE_DOMAIN="${docker_ip}.nip.io"
  echo "Using ingress domain: ${KUBE_INGRESS_BASE_DOMAIN}"

  kubectl wait --for=condition=Ready nodes --all --timeout=120s
}

function k3d_delete() {
  if ! command -v k3d &>/dev/null; then
    echo "k3d not installed, skipping cluster delete"
    return 0
  fi
  local cluster_name
  cluster_name=$(k3d_cluster_name)
  k3d cluster delete "${cluster_name}" || true
}

# Collect debug artifacts (helm values, manifests, pod events, logs) into
# ${CI_PROJECT_DIR}/k3d-debug/ before the cluster is destroyed. Called from
# after_script — all commands are best-effort and must never fail the job.
# See: https://gitlab.com/gitlab-org/charts/gitlab/-/work_items/6478
function k3d_collect_debug() {
  local debug_dir="${CI_PROJECT_DIR:-$(pwd)}/k3d-debug"
  local ns="${NAMESPACE:-default}"
  mkdir -p "${debug_dir}/failed-pod-logs" "${debug_dir}/values-inputs"

  # Source helpers for gitlab_release_name when invoked standalone from
  # after_script (autodevops.sh isn't necessarily sourced there).
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  # shellcheck disable=SC1091
  source "${script_dir}/lib/helpers.sh" 2>/dev/null || true

  local release=""
  if command -v gitlab_release_name &>/dev/null; then
    release=$(gitlab_release_name 2>/dev/null || echo "")
  fi
  echo "k3d_collect_debug: release='${release}' namespace='${ns}' output='${debug_dir}'"

  if command -v helm &>/dev/null && [ -n "${release}" ]; then
    helm get values "${release}" -n "${ns}" --all > "${debug_dir}/helm-values.yaml" 2>&1 || true
    helm get manifest "${release}" -n "${ns}" > "${debug_dir}/helm-manifest.yaml" 2>&1 || true
    helm status "${release}" -n "${ns}" > "${debug_dir}/helm-status.txt" 2>&1 || true
    helm history "${release}" -n "${ns}" > "${debug_dir}/helm-history.txt" 2>&1 || true
  fi

  if command -v kubectl &>/dev/null; then
    kubectl get pods -A -o wide > "${debug_dir}/pods.txt" 2>&1 || true
    kubectl describe pods -n "${ns}" > "${debug_dir}/pods-describe.txt" 2>&1 || true
    kubectl get events -A --sort-by=.lastTimestamp > "${debug_dir}/events.txt" 2>&1 || true
    { kubectl get nodes -o wide; echo "---"; kubectl describe nodes; } > "${debug_dir}/nodes.txt" 2>&1 || true
    # Image strings as scheduled (spec) and as resolved by the kubelet (status/imageID).
    # To answer "were the ci.digests.yaml pins respected?",
    # compare the outputs of ci.digests.yaml and pod-images.txt
    kubectl get pods -A \
      -o jsonpath='{range .items[*]}{.metadata.namespace}/{.metadata.name}{"\n"}{range .spec.containers[*]}  spec:   {.name}={.image}{"\n"}{end}{range .status.containerStatuses[*]}  status: {.name}={.image} imageID={.imageID}{"\n"}{end}{"\n"}{end}' \
      > "${debug_dir}/pod-images.txt" 2>&1 || true

    # cert-manager / ACME state (HTTPS k3d deployments; cheap no-op when the
    # CRDs are absent, i.e. on HTTP-only jobs).
    if kubectl get crd certificates.cert-manager.io >/dev/null 2>&1; then
      local r
      for r in certificates certificaterequests orders challenges issuers; do
        { kubectl get "${r}" -A -o wide; echo "---"; kubectl describe "${r}" -n "${ns}"; } \
          > "${debug_dir}/certmanager-${r}.txt" 2>&1 || true
      done
      kubectl logs -n "${ns}" \
        -l "app.kubernetes.io/name=certmanager,app.kubernetes.io/component=controller" \
        --tail=2000 > "${debug_dir}/certmanager-controller.log" 2>&1 || true
    fi
    if kubectl get crd gateways.gateway.networking.k8s.io >/dev/null 2>&1; then
      { kubectl get gateways,httproutes -A -o wide; echo "---"; kubectl describe gateways,httproutes -n "${ns}"; } \
        > "${debug_dir}/gateway-api.txt" 2>&1 || true
    fi
    kubectl logs -n "${ns}" deployment/pebble --tail=2000 > "${debug_dir}/pebble.log" 2>&1 || true

    # Logs from pods not Running in the release namespace.
    local not_running
    not_running=$(kubectl get pods -n "${ns}" \
      -o jsonpath='{range .items[?(@.status.phase!="Running")]}{.metadata.name}{"\n"}{end}' 2>/dev/null || true)
    while IFS= read -r pod; do
      [ -z "${pod}" ] && continue
      kubectl logs -n "${ns}" "${pod}" --all-containers --tail=500 \
        > "${debug_dir}/failed-pod-logs/${pod}.log" 2>&1 || true
      kubectl logs -n "${ns}" "${pod}" --all-containers --previous --tail=500 \
        > "${debug_dir}/failed-pod-logs/${pod}.previous.log" 2>&1 || true
    done <<< "${not_running}"
  fi

  # Copy the literal -f inputs passed to `helm upgrade` (post-envsubst).
  local project_root="${CI_PROJECT_DIR:-${script_dir}/../..}"
  if [ -d "${project_root}/.values" ]; then
    cp "${project_root}"/.values/*.yaml "${debug_dir}/values-inputs/" 2>/dev/null || true
  fi
  if [ -f "${project_root}/ci.digests.yaml" ]; then
    cp "${project_root}/ci.digests.yaml" "${debug_dir}/values-inputs/" 2>/dev/null || true
  fi

  echo "k3d_collect_debug: collected artifacts:"
  ls -la "${debug_dir}" 2>/dev/null || true
}

function k3d_info() {
  echo "k3d cluster: $(k3d_cluster_name)"
  echo "  K8s image:  ${K3D_K8S_IMAGE}"
  echo "  KUBECONFIG: ${KUBECONFIG}"
  echo "  Domain:     ${KUBE_INGRESS_BASE_DOMAIN}"
}
