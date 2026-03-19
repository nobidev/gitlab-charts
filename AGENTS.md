# AGENTS.md

This file provides guidance to AI coding assistants when working with this repository.

## Overview

The GitLab Helm chart (`gitlab/gitlab`) deploys all GitLab foundational components on Kubernetes. It composes sub-charts for GitLab services and bundles external dependencies (cert-manager, Prometheus, Gateway API — see `Chart.yaml` for the authoritative full list).

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
- `Chart.yaml` — chart metadata; lists bundled dependencies (cert-manager, Prometheus, Gateway API — see `Chart.yaml` for pinned versions and the authoritative full list)
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
- **cert-manager** — `jetstack/cert-manager`
- **Prometheus** — `prometheus-community/prometheus`
- **Gateway API** — `gateway-helm`
- **PostgreSQL** and **Redis** — still bundled optionally (`bitnami/postgresql`, `bitnami/redis`), but intended to be replaced by external services
- **NGINX ingress** — still bundled optionally, being superseded by Gateway API

### Key Design Decisions
- Object storage (S3-compatible) is required for shared data
- Components are designed to run without root privileges, though some cluster configurations may require adjustments
- All inter-service communication uses Kubernetes Services
- Secrets managed via Kubernetes Secret objects
- Horizontal scaling via standard Kubernetes HPA

### Configuration Hierarchy
`global` values in `values.yaml` propagate to all sub-charts. Each sub-chart can override at its own level. The `gitlab.yml.erb` template in each service's ConfigMap is generated from Helm values.

**Convention**: Only place values under `global` when they are genuinely consumed by multiple sub-charts. Sub-chart-specific configuration belongs at the sub-chart level, not global — even if it's convenient to centralise it.

See the [development docs](https://docs.gitlab.com/charts/development/) for architecture details, style guide, and contribution guidelines.

## CI Pipeline

`.gitlab-ci.yml` stages: `test → preflight → staging → review`

Uses Knapsack for parallel RSpec test distribution across CI nodes.

## Merge Requests

When creating MRs for this repo, always use the appropriate MR template from `.gitlab/merge_request_templates/`:

- **`Default.md`** — for all code changes (features, bug fixes, refactors, tooling)
- **`Documentation.md`** — for documentation-only changes (branch name must start with `docs-`/`docs/` or end with `-docs`)

The templates include required author/reviewer checklists and quick actions that apply labels and assignment. Always populate the template fully rather than replacing it with a custom description.
