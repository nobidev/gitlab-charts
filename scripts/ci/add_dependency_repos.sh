#!/bin/bash
#
# Add all Helm repos this chart depends on.

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add gitlab https://charts.gitlab.io/
helm repo add traefik https://helm.traefik.io/traefik
helm repo add haproxy https://haproxytech.github.io/helm-charts
helm repo add ai-gateway https://gitlab.com/api/v4/projects/gitlab-org%2fcharts%2fai-gateway-helm-chart/packages/helm/devel
