# Image used by `./scripts/local-qa.sh specs`. It joins the k3d cluster's
# docker network at run time, so the chart's nip.io hostnames resolve to
# the in-network Ingress IP — the same way the gitlab-qa container does —
# avoiding the host-side routing issues you hit when running `bundle exec
# rspec` directly from macOS against docker container IPs.
#
# Pinned to Ubuntu 24.04 + the distro ruby. Native extensions get the
# build-essential / libffi-dev / zlib1g-dev triplet most Bundler-installed
# gems need. kubectl is required by spec/features/backups_spec.rb (it
# shells out to `kubectl exec` into the toolbox pod).

FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ARG KUBECTL_VERSION=v1.33.6

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ruby ruby-dev build-essential git curl ca-certificates \
        libffi-dev zlib1g-dev \
        tzdata \
    && rm -rf /var/lib/apt/lists/*

# Ruby's tzinfo gem looks at /usr/share/zoneinfo (system tzdata package).
# Without TZ pinned to something explicit, fugit's `require 'tzinfo'` raises
# TZInfo::DataSourceNotFound on minimal Ubuntu installs even after tzdata
# is on disk, because the gem's auto-detection logic is conservative.
ENV TZ=Etc/UTC

# Install kubectl for the host's architecture (works under buildx/QEMU too).
RUN arch="$(dpkg --print-architecture)" \
    && curl -sLo /usr/local/bin/kubectl \
        "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${arch}/kubectl" \
    && chmod +x /usr/local/bin/kubectl \
    && kubectl version --client=true

# Docker CLI for spec/features/backups_spec.rb — it shells out to
# `docker login`, `docker tag`, `docker push`, `docker pull` against the
# chart's container registry. We only need the client binary; the spec
# runner mounts /var/run/docker.sock from the host daemon at run time.
ARG DOCKER_CLI_VERSION=28.0.1
RUN arch="$(uname -m)" \
    && curl -fLo /tmp/docker.tgz \
        "https://download.docker.com/linux/static/stable/${arch}/docker-${DOCKER_CLI_VERSION}.tgz" \
    && tar -xz -C /usr/local/bin --strip-components=1 -f /tmp/docker.tgz docker/docker \
    && rm /tmp/docker.tgz \
    && docker --version

RUN gem install --no-document bundler

WORKDIR /workspace
