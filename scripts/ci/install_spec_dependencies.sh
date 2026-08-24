#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
HELM_VERSION=${HELM_VERSION:-4.2.3}
GOMPLATE_VERSION=${GOMPLATE_VERSION:-v5.0.0}
DOCKER_VERSION=${DOCKER_VERSION:-28.1.0}
DEBIAN_VERSION_NUMBER=${DEBIAN_VERSION_NUMBER:-13}
# Strip "-slim" suffix from DEBIAN_VERSION if present
DEBIAN_VERSION=${DEBIAN_VERSION:-"trixie"}
DEBIAN_VERSION_CLEAN=${DEBIAN_VERSION%%-*}
# Docker apt packages carry a "-1" package revision (e.g. 5:28.1.0-1~debian.13~trixie).
DOCKER_DEB_VERSION="5:${DOCKER_VERSION}-1~debian.${DEBIAN_VERSION_NUMBER}~${DEBIAN_VERSION_CLEAN}"
KUBECTL_VERSION=${KUBECTL_VERSION:-1.28.3}
TARGET_DIR=${TARGET_DIR:-"/usr/local/bin"}

apt-get update -qq
apt-get install -y --no-install-recommends \
    curl ca-certificates gnupg lsb-release

DOCKER_INSTALLED_VERSION=""
if command -v docker; then
    DOCKER_INSTALLED_VERSION=$(docker version --format '{{ .Client.Version }}')
    echo "Docker ${DOCKER_INSTALLED_VERSION} already installed"
    echo "Expected version: ${DOCKER_VERSION}"
fi

if [ "${STRICT_VERSIONS:-false}" == "true" ] && [ "${DOCKER_INSTALLED_VERSION}" != "${DOCKER_VERSION}" ] || [ -z "${DOCKER_INSTALLED_VERSION}" ]; then
    echo "Installing Docker version ${DOCKER_DEB_VERSION}"
    # Updated Docker repository setup for Debian Bookworm
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | \
        tee /etc/apt/sources.list.d/docker.list > /dev/null

    apt-get update -qq
    apt-get install -y --no-install-recommends docker-ce-cli=${DOCKER_DEB_VERSION}
fi
# Sometimes, `docker:dind` service is not ready yet, causing exit code of 1
# We only care about the client, anyways!
docker version --format 'Effective: docker-{{ .Client.Version }}' || true

GOMPLATE_INSTALLED_VERSION=""
if command -v gomplate; then
    GOMPLATE_INSTALLED_VERSION=$(gomplate -v | cut -d' ' -f3)
    echo "gomplate-${GOMPLATE_INSTALLED_VERSION} already installed"
    echo "Expected version: ${GOMPLATE_VERSION}"
fi

if [ "${STRICT_VERSIONS:-false}" == "true" ] && [ "${GOMPLATE_INSTALLED_VERSION}" != "${GOMPLATE_VERSION}" ] || [ -z "${GOMPLATE_INSTALLED_VERSION}" ]; then
    GOMPLATE_ARCH=$(uname -m); case "$GOMPLATE_ARCH" in x86_64) GOMPLATE_ARCH="amd64";; aarch64) GOMPLATE_ARCH="arm64";; esac
    echo "Installing gomplate-${GOMPLATE_VERSION} (${GOMPLATE_ARCH})"
    curl -o gomplate -sSL https://github.com/hairyhenderson/gomplate/releases/download/${GOMPLATE_VERSION}/gomplate_linux-${GOMPLATE_ARCH}
    chmod +x gomplate
    mv gomplate ${TARGET_DIR}/gomplate
fi
echo -n "Effective: "; gomplate -v 2>/dev/null || echo "gomplate installation failed"

HELM_INSTALLED_VERSION=""
if command -v helm; then
    echo "Helm already installed"
    echo "Expected version: ${HELM_VERSION}"
    HELM_INSTALLED_VERSION=$(helm version --template '{{.Version}}' | sed -e 's/^v//' )
    echo "Installed version: ${HELM_INSTALLED_VERSION}"
fi

if [ "${STRICT_VERSIONS:-false}" == "true" ] && [ "${HELM_INSTALLED_VERSION}" != "${HELM_VERSION}" ] || [ -z "${HELM_INSTALLED_VERSION}" ]; then
    HELM_ARCH=$(uname -m); case "$HELM_ARCH" in x86_64) HELM_ARCH="amd64";; aarch64) HELM_ARCH="arm64";; esac
    echo "Installing helm-${HELM_VERSION} (${HELM_ARCH})"
    curl -Ls https://get.helm.sh/helm-v${HELM_VERSION}-linux-${HELM_ARCH}.tar.gz | tar zxf -
    chmod +x linux-${HELM_ARCH}/helm
    mv linux-${HELM_ARCH}/helm ${TARGET_DIR}/helm
    rm -rf linux-${HELM_ARCH}/
fi
helm version --template 'Effective: {{.Version}}' 2>/dev/null || echo "helm installation failed"

KUBECTL_INSTALLED_VERSION=""
if command -v kubectl; then
    echo "Kubectl already installed"
    echo "Expected version: ${KUBECTL_VERSION}"
    KUBECTL_INSTALLED_VERSION=$(kubectl version --client=true -o yaml | awk '/gitVersion/ { sub("^v","",$2); print $2; }')
    echo "Installed kubectl version: ${KUBECTL_INSTALLED_VERSION}"
fi

if [ "${STRICT_VERSIONS:-false}" == "true" ] && [ "${KUBECTL_INSTALLED_VERSION}" != "${KUBECTL_VERSION}" ] || [ -z "${KUBECTL_INSTALLED_VERSION}" ]; then
    KUBECTL_ARCH=$(uname -m); case "$KUBECTL_ARCH" in x86_64) KUBECTL_ARCH="amd64";; aarch64) KUBECTL_ARCH="arm64";; esac
    echo "Installing kubectl-${KUBECTL_VERSION} (${KUBECTL_ARCH})"
    curl -LsO https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${KUBECTL_ARCH}/kubectl
    chmod +x kubectl
    mv kubectl ${TARGET_DIR}/kubectl
fi
kubectl version --client=true -o yaml 2>/dev/null || echo "kubectl installation failed"
