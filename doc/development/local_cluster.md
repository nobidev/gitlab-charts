---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Reproducing the CI QA flow locally on k3d
---

This page is the recipe for running the same QA flow CI runs (the
`review_gke135` → `review_specs_gke135` → `qa_gke135` sequence) against
a local [k3d](https://k3d.io) cluster on your laptop. The goal is to be
able to reproduce a green CI QA shard without invoking CI.

The CI scripts under `scripts/ci/` are the source of truth for what
gets deployed. After the Stage A and Stage B refactors, those same
scripts run unchanged from a developer shell — the only local-only
glue is the cluster bootstrap, the env seed, the parallel-QA loop, and
the Allure-report merge.

## Prerequisites

Install with [Homebrew](https://brew.sh) on macOS (`brew install <pkg>`);
Linux users have these via their package manager or [mise](https://mise.jdx.dev/).

| Tool       | Pinned version | Where used                                          |
| ---------- | -------------- | --------------------------------------------------- |
| Docker     | any            | k3d runtime; runs the `gitlab-ee-qa` container.    |
| `k3d`      | `5.8.3`        | Cluster lifecycle (matches CI's `K3D_VERSION`).    |
| `helm`     | `4.1.4`        | Chart install (matches CI's `HELM_VERSION`).       |
| CNPG chart | `0.28.0`       | CloudNativePG operator install.                     |
| dev-stack  | `1.5.0`        | GitLab-dev-stack umbrella chart.                    |
| garage     | `2.3.0`        | Object storage (matches `.gitlab-ci.yml`).         |
| CNPG       | `17`           | PostgreSQL image tag (matches `.gitlab-ci.yml`).   |
| `kubectl`  | any 1.28+      | Cluster interaction.                                |
| `skopeo`   | any            | `scripts/ci/pin_image_digests.sh`.                  |
| `envsubst` | any            | Provided by `gettext` (`brew install gettext`).    |
| `jq`       | any            | LB-IP discovery via `k3d cluster list -o json`.    |
| `gitlab-qa` gem | `15.7.2`  | E2E test harness (matches CI's `GITLAB_QA_VERSION`).|
| `allure`   | any 2.x        | Report merge (`brew install allure`).               |
| `bundle`   | any            | `bundle exec rspec` for the chart feature specs.    |

Quick check:

```shell
docker info >/dev/null && k3d version && helm version --short \
  && kubectl version --client && skopeo --version \
  && envsubst --version | head -1 && jq --version
```

## One-time setup

### 1. Shared Docker network + pull-through registry caches

The k3d cluster, the registry caches, and the `gitlab-ee-qa` container all
need to live on the same Docker network so they can resolve each other by
name. Create the network once, then create two k3d-managed registries
that proxy the upstreams which actually matter for iteration speed:
`quay.io` (cert-manager, jetstack) and `registry.gitlab.com` (the
multi-GB CNG image set). The cache survives cluster recreation, so
those images only download once per machine.

```shell
docker network inspect k3d-gitlab-local >/dev/null 2>&1 \
  || docker network create k3d-gitlab-local

k3d registry create quay-cache \
  --proxy-remote-url https://quay.io \
  --default-network k3d-gitlab-local
k3d registry create gitlab-cache \
  --proxy-remote-url https://registry.gitlab.com \
  --default-network k3d-gitlab-local
```

The `k3d registry create` command prepends `k3d-` to each container,
yielding `k3d-quay-cache` and `k3d-gitlab-cache`. These are the names
`registries.yaml` refers to, which the cluster
wires into containerd as registry mirrors.

`skopeo inspect` in `scripts/ci/pin_image_digests.sh`
deliberately bypasses the cache and hits canonical `registry.gitlab.com`
to read authoritative manifest digests — the cache only serves *image
pulls* during deploy.

> **Why no Docker.io cache?** A pull-through `registry:2` proxying
> Docker.io was observed mis-serving OCI image-index bytes under
> per-arch config blob digests, surfacing as `failed size validation:
> 316621 != <small_number>` errors on the k3s control plane's
> `rancher/mirrored-*` and `library/busybox` image pulls. Those images
> are small enough that direct Docker.io pulls (no cache) are fine;
> dropping the mirror avoids the whole class of bug. If you want it
> back, add `docker.io: { endpoint: [http://k3d-docker-cache:5000] }`
> to `registries.yaml` and an additional
> `k3d registry create docker-cache --proxy-remote-url https://docker.io`.

### 2. k3d cluster

```shell
k3d cluster create gitlab-local \
  --servers 1 \
  --network k3d-gitlab-local \
  --k3s-arg "--disable=traefik@server:*" \
  --port "80:80@loadbalancer" \
  --port "443:443@loadbalancer" \
  --port "22:22@loadbalancer" \
  --registry-config scripts/registries.yaml
```

The three `--port` mappings make the k3d-bundled serverLoadBalancer forward
HTTP / HTTPS / SSH traffic into the cluster's NGINX-Ingress controller, so
the `serverLoadBalancer.IP.IP` k3d reports below is the IP that actually
answers requests for `gitlab.${LB_IP}.nip.io`. (Without the mappings,
NGINX-Ingress would still get a klipper-lb-allocated IP, but it'd be the
node IP — one higher than the serverLoadBalancer IP — and `nip.io`
resolution wouldn't match.)

Notes on the flags:

- `--network k3d-gitlab-local` puts the API server, the load balancer, and
  every node container on the shared network so the registry caches
  resolve and the QA container can reach the cluster directly.
- `--k3s-arg "--disable=traefik@server:*"` disables the k3d-bundled
  Traefik — the GitLab chart provides its own `NGINX-Ingress` controller
  via the `k3d.ingress` overlay (matching CI's `gke135` behavior).
- The three `--port` mappings forward HTTP / HTTPS / SSH from the host
  into the k3d serverLoadBalancer (see the explanation above).

After creation, discover the LB IP — this becomes part of the chart's
hostname via `nip.io`:

```shell
LB_IP=$(k3d cluster list gitlab-local -o json \
  | jq -r '.[0].serverLoadBalancer.IP.IP')
echo "$LB_IP"          # e.g. 172.20.0.4
```

### 3. CloudNativePG operator

`gitlab-dev-stack` requires the CNPG operator to be installed cluster-wide
*before* its release lands (the chart deliberately doesn't bundle CRDs).

```shell
helm repo add cnpg https://cloudnative-pg.github.io/charts
helm upgrade --install cnpg cnpg/cloudnative-pg \
  --version 0.28.0 -n cnpg-system --create-namespace --wait
```

## Environment seed (per-shell)

A direnv-friendly snippet to drop into `.envrc.local` (or `eval`/export
inline in your shell):

```shell
# Cluster + namespace
export NAMESPACE=default
export KUBE_NAMESPACE="${NAMESPACE}"
export USE_DEV_STACK=true
export GITLAB_RELEASE_NAME=gitlab
export DEV_STACK_RELEASE_NAME=gitlab-dev-stack
export HOST_SUFFIX=""

# `k3d cluster create` (run in the bootstrap step above) already merged
# the cluster's entry into ~/.kube/config and set k3d-gitlab-local as
# the current context. Re-assert it here in case you've switched to a
# different cluster in the meantime.
kubectl config use-context k3d-gitlab-local

# nip.io: gitlab.${LB_IP}.nip.io and registry.${LB_IP}.nip.io resolve back
# to the chart's nginx-ingress LB IP on the shared docker network.
export LB_IP=$(k3d cluster list gitlab-local -o json \
  | jq -r '.[0].serverLoadBalancer.IP.IP')
export KUBE_INGRESS_BASE_DOMAIN="${LB_IP}.nip.io"
export GITLAB_URL="gitlab.${KUBE_INGRESS_BASE_DOMAIN}"

# Versions pinned to match .gitlab-ci.yml — keep these in sync if CI bumps.
export CNPG_POSTGRESQL_TAG=17
export GARAGE_APP_VERSION=2.3.0

# QA passwords reuse the same SHA-256 derivation CI uses — see scripts/ci/qa.sh.
export QA_DOCKER_NETWORK=k3d-gitlab-local
# Optional: paste your EE license here so the chart's EE-feature scenarios
# don't get skipped by gitlab-qa smoke. The Secret name matches the
# scripts/ci/values/gitlab-chart/ci-license.values.yaml template.
# export QA_EE_LICENSE="$(cat ~/.gitlab-ee-license)"
```

## Deploy the chart

The deploy is now a single command — `bash scripts/ci/autodevops.sh`
runs the same orchestrator CI's `.review_gke135` job runs, taught to
detect local mode and skip the CI-only secret-creation step.

```shell
# 1. (optional but recommended) Pin every CNG image to its current digest.
GITLAB_VERSION=master bash scripts/ci/pin_image_digests.sh
# → produces ci.digests.yaml; auto-layered by autodevops.sh when present.

# 2. Pre-create the EE license Secret. ci-license.values.yaml is layered
#    unconditionally by the dual-mode autodevops.sh, so the chart will
#    fail to mount it if missing (migrations Pod stays in
#    "MountVolume.SetUp failed for volume "init-migrations-secrets":
#     secret "<release>-gitlab-license" not found"). Create it empty if
#    you don't have a license — EE features will degrade gracefully.
#    Release name locally is "dev-gitlab" (release_name_base = "dev"
#    when CI_PIPELINE_ID is unset, then helm appends -gitlab).
source scripts/ci/lib/helpers.sh
RELEASE="$(release_name_base)-gitlab"
kubectl create secret generic -n "${NAMESPACE}" \
  "${RELEASE}-gitlab-license" \
  --from-literal=license="${QA_EE_LICENSE:-}" \
  -o yaml --dry-run=client | kubectl apply -f -

# 3. Deploy. autodevops.sh handles ensure_namespace → deploy_external_components
#    (gitlab-dev-stack) → deploy_chart (helm upgrade --install with the
#    full CI values stack) → wait_for_pods.
bash scripts/ci/autodevops.sh
```

After it returns, the GitLab webservice + KAS Pods are both Ready and
the chart hostname is reachable at `http://gitlab.${LB_IP}.nip.io`.

Fetch the root password the chart auto-generated:

```shell
export GITLAB_PASSWORD=$(kubectl get secret \
  "${GITLAB_RELEASE_NAME}-gitlab-initial-root-password" \
  -n "${NAMESPACE}" -o jsonpath='{.data.password}' | base64 -d)
```

## Chart-level feature specs (cheap pre-flight)

Reproduces CI's `review_specs_gke135` job. Mirrors the
`scripts/ci/run_specs.sh` path:

```shell
export PROTOCOL=http
export GITLAB_ROOT_DOMAIN="${KUBE_INGRESS_BASE_DOMAIN}"
export REGISTRY_URL="registry.${KUBE_INGRESS_BASE_DOMAIN}"

# Mint an admin PAT against this deployed instance for the specs that need it.
source scripts/ci/autodevops.sh
export GITLAB_ADMIN_TOKEN="$(create_admin_pat)"

bundle exec rspec -c -f d spec -t "type:feature"
```

## Five-way parallel QA against one deployed cluster

Reproduces CI's `qa_gke135` job (`.qa_branch` has `parallel: 5`). The
deploy is shared — only the test set splits via
`CI_NODE_INDEX` / `CI_NODE_TOTAL`. `gitlab-qa` 15.7.2 forwards those env
vars into the inner `gitlab-ee-qa` container automatically (CI doesn't
set `EXTRA_DOCKER_RUN_ARGS` for them and the parallel jobs work, so
local does the same — verify on the first run that each shard sees a
different test count).

The knapsack splitter inside `gitlab-ee-qa` expects **0-based** node
indexes (0 ≤ index < total). GitLab CI's own `CI_NODE_INDEX` is
1-based and GitLab CI rewrites it to 0-based before forwarding; when
driving the shards by hand we use the 0-based numbering directly, both
for `CI_NODE_INDEX` and for the per-shard artifact directories so the
on-disk layout matches what each shard's `CI_NODE_INDEX` says.

```shell
gem install gitlab-qa -v 15.7.2
source scripts/ci/qa.sh && qa_export_passwords

if [ -n "${QA_GITLAB_REVISION:-}" ]; then
  QA_IMAGE="registry.gitlab.com/gitlab-org/gitlab/gitlab-ee-qa:${QA_GITLAB_REVISION}"
else
  QA_IMAGE="gitlab/gitlab-ee-qa:nightly"
fi

for i in 0 1 2 3 4; do
  (
    export CI_NODE_INDEX=$i CI_NODE_TOTAL=5
    export QA_ARTIFACTS_DIR="$PWD/qa-shard-$i"
    mkdir -p "$QA_ARTIFACTS_DIR"

    QA_DOCKER_NETWORK=k3d-gitlab-local \
    SIGNUP_DISABLED=true \
    QA_DEBUG=true \
    QA_GENERATE_ALLURE_REPORT=true \
    GITLAB_USERNAME=root GITLAB_PASSWORD="$GITLAB_PASSWORD" \
    GITLAB_ADMIN_USERNAME=root GITLAB_ADMIN_PASSWORD="$GITLAB_PASSWORD" \
    gitlab-qa Test::Instance::Any --qa-image "$QA_IMAGE" \
      EE "http://${GITLAB_URL}" -- \
      --tag smoke --tag ~skip_live_env --tag ~orchestrated \
      > "qa-shard-$i.log" 2>&1
  ) &
done
wait
```

Five parallel headless Chrome + QA containers are memory-heavy. Drop to
`for i in 1 2 3` if you don't have ~16 GB free; the env-split works at
any `N`.

`QA_DOCKER_NETWORK=k3d-gitlab-local` attaches the inner `gitlab-ee-qa`
container to the same network the cluster uses, so it can resolve
`gitlab.${LB_IP}.nip.io` directly without `--add-host` workarounds.

## Allure report

CI delegates report aggregation to the
`gitlab.com/gitlab-org/quality/pipeline-common/allure-report` component,
which uploads the HTML to S3 and posts an MR comment. Locally we only
need the merge + generate step:

```shell
rm -rf allure-merged && mkdir allure-merged
cp -r qa-shard-*/gitlab-qa-run-*/**/allure-results/. allure-merged/
allure serve allure-merged          # ephemeral; opens browser
# or persist:
allure generate allure-merged -o allure-report --clean
open allure-report/index.html
```

## Teardown

```shell
# Per-deploy iteration: helm uninstall + sweep stray resources.
bash -c 'source scripts/ci/autodevops.sh; teardown'

# Full reset: delete the cluster. Caches survive (image data preserved).
k3d cluster delete gitlab-local
```

Removing the registry caches too:

```shell
k3d registry delete k3d-quay-cache k3d-gitlab-cache
docker network rm k3d-gitlab-local
```

## Troubleshooting

- `kubectl get pods -n cnpg-system` shows the CNPG operator. If it's
  missing the dev-stack `Cluster` CR apply will fail with
  "no matches for kind 'Cluster'".
- `FailedCreatePodSandBox` with `failed size validation: 316621 != 901`
  (or similar) on a freshly created cluster typically means a
  `registry:2` pull-through cache mis-served an OCI image-index. The
  doc above intentionally omits the Docker.io cache for that reason;
  if you re-added it, drop the Docker.io entry from `registries.yaml`
  and recreate the cluster.
- `helm get values gitlab -n default --all` shows the full rendered
  values stack the chart was deployed with — useful for comparing local
  vs. CI behavior.
- The `${ARTIFACTS_DIR}/k3d-debug/` tree (after running
  `scripts/ci/k3d.sh::k3d_collect_debug`) bundles pod events, logs from
  not-Running pods, and the literal `-f` inputs `helm upgrade` consumed.
- `${ARTIFACTS_DIR}` defaults to `${CI_PROJECT_DIR:-$(pwd)}`. Set
  `ARTIFACTS_DIR=/tmp/gitlab-local-debug` to redirect everything
  (`.values/`, `k3d-debug/`, `skopeo_errors.log`, `k3d-kubeconfig.yaml`)
  out of the working tree.

## What stays local-only

After the Stage A and Stage B refactors, the only code that lives
exclusively on a developer's laptop is roughly this page itself:

1. The shared Docker network creation.
1. The three `k3d registry create` lines.
1. The `k3d cluster create gitlab-local` line.
1. The LB-IP discovery one-liner.
1. The parallel-QA `for` loop.
1. The Allure merge + serve.

Everything else — the chart install (`scripts/ci/autodevops.sh`), the
digest pinner (`scripts/ci/pin_image_digests.sh`), the chart specs
(`scripts/ci/run_specs.sh`), the QA helpers (`scripts/ci/qa.sh`), and
the dev-stack values renderer
(`scripts/ci/values/dev-stack/values.yaml.tmpl` → envsubst) — is shared
with CI. When CI surprises you, reproducing the failure locally is one
command, not a rewrite.
