# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

The GitLab Helm chart (`gitlab/gitlab`) deploys all GitLab components on Kubernetes. It composes sub-charts for GitLab services and bundles external dependencies (PostgreSQL, Redis, cert-manager, NGINX ingress, Prometheus).

## Commands

```bash
bundle install                              # Install Ruby test dependencies
bundle exec rspec                           # Run all chart tests
bundle exec rspec spec/path/to_spec.rb      # Run single spec
bundle exec rubocop                         # Lint Ruby code

helm dependency update                      # Fetch/update chart dependencies
helm lint .                                 # Lint the chart
helm template . -f values.yaml              # Render templates locally
```

## Architecture

### Chart Structure
- `Chart.yaml` — chart metadata; lists bundled dependencies (PostgreSQL 13, Redis 18, cert-manager, prometheus, nginx-ingress)
- `charts/` — GitLab sub-charts, one per service component
- `templates/` — top-level shared templates (RBAC, secrets, etc.)
- `values.yaml` — default configuration values
- `examples/` — reference configs for different deployment sizes

### GitLab Sub-charts (`charts/`)
Each GitLab service is its own sub-chart:
- `webservice/` — Rails web workers (Puma)
- `sidekiq/` — background job workers
- `gitaly/` — Git RPC service
- `gitlab-shell/` — SSH access
- `kas/` — Kubernetes Agent Server
- `registry/` — Container registry
- `toolbox/` — backup/restore toolbox pod
- `migrations/` — database migration jobs
- `gitlab-runner/` — optional bundled runner

### External Dependencies (bundled)
- **PostgreSQL** — `bitnami/postgresql`
- **Redis** — `bitnami/redis`
- **cert-manager** — `jetstack/cert-manager`
- **NGINX ingress** — `ingress-nginx/ingress-nginx`
- **Prometheus** — `prometheus-community/prometheus`

### Key Design Decisions
- No NFS required — object storage (S3-compatible) for all shared data
- No root privileges required for any component
- All inter-service communication uses Kubernetes Services
- Secrets managed via Kubernetes Secret objects
- Horizontal scaling via standard Kubernetes HPA

### Configuration Hierarchy
`global` values in `values.yaml` propagate to all sub-charts. Each sub-chart can override at its own level. The `gitlab.yml.erb` template in each service's ConfigMap is generated from Helm values.

## CI Pipeline

`.gitlab-ci.yml` stages: `test → preflight → staging → review`

Uses Knapsack for parallel RSpec test distribution across CI nodes.
