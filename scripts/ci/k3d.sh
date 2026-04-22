#!/bin/bash

# k3d cluster lifecycle for per-job isolated review environments.
# Each CI job creates its own k3d cluster, eliminating shared host contention.
# See: https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6421

K3D_VERSION="${K3D_VERSION:-5.8.3}"

function k3d_cluster_name() {
  # Include CI_JOB_ID so multiple jobs in the same pipeline (parallel QA) never collide
  echo -n "k3d-rvw-${CI_PIPELINE_ID}-${CI_JOB_ID}"
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
    --image "${K3D_K8S_IMAGE}" \
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
  local cluster_name
  cluster_name=$(k3d_cluster_name)
  k3d cluster delete "${cluster_name}" || true
}

function k3d_info() {
  echo "k3d cluster: $(k3d_cluster_name)"
  echo "  K8s image:  ${K3D_K8S_IMAGE}"
  echo "  KUBECONFIG: ${KUBECONFIG}"
  echo "  Domain:     ${KUBE_INGRESS_BASE_DOMAIN}"
}
