#!/usr/bin/env bash
#
# Local CI QA driver — automates the recipe in doc/development/local_cluster.md
# (and local-ci-docs.md). Run with no arguments for the full sequence; pass a
# subcommand to run one stage in isolation.
#
# Subcommands:
#   up        Create the shared network, pull-through registry caches, the k3d
#             cluster, and the CloudNativePG operator. Idempotent — already-up
#             pieces are skipped.
#   deploy    Run `bash scripts/ci/autodevops.sh` against the cluster. Creates
#             the EE license Secret (empty if $QA_EE_LICENSE is unset).
#   specs     Run the chart feature specs (`bundle exec rspec -t type:feature`).
#   qa        Run gitlab-qa Test::Instance::Any in parallel. $QA_SHARDS controls
#             fan-out (default 5; set to 1 for a single shard).
#   report    Merge per-shard Allure results and open the HTML.
#   down      Uninstall the releases and delete the cluster. Caches survive.
#   all       up → deploy → qa → report. Default. Skip QA with --skip-qa.
#
# Host dependencies (must be on $PATH before invoking):
#   docker     Container runtime — drives k3d, the dind sidecar, the spec
#              runner, and gitlab-qa.
#   k3d        Creates/destroys the local cluster and its registry caches.
#   kubectl    Cluster interaction (waits, secret reads, context switching).
#   helm       Installs CloudNativePG and renders/applies the chart.
#   jq         Parses k3d's JSON output (LB IP discovery in seed_env).
#   yq         Reads KUBECTL_VERSION / DOCKER_VERSION from .gitlab-ci.yml
#              when building the local-qa-specs image (cmd_specs).
#   skopeo    Used by scripts/ci/pin_image_digests.sh during cmd_deploy.
#   envsubst   Used by scripts/ci/autodevops.sh value templating.
#   gem        Bootstraps gitlab-qa for cmd_qa.
#   gitlab-qa  E2E test runner (installed via `gem install gitlab-qa`).
#   allure     Generates the merged Allure report in cmd_report.
#   tmux       Optional — live-tails per-shard logs when QA_SHARDS > 1.
#
# Env knobs (override before running):
#   QA_SHARDS=5                 Parallel shard count.
#   QA_EE_LICENSE=…             EE license content. REQUIRED for deploy/qa
#                               (fails fast if unset). Export from your
#                               password manager before running.
#   GITLAB_QA_VERSION=15.7.2    gitlab-qa gem version (matches .gitlab-ci.yml).
#   CNPG_CHART_VERSION=0.28.0
#   CNPG_POSTGRESQL_TAG=17      Match .gitlab-ci.yml.
#   GARAGE_APP_VERSION=2.3.0    Match .gitlab-ci.yml.
#
# Usage:
#   ./scripts/local-qa.sh             # full pipeline including QA
#   ./scripts/local-qa.sh up          # just the cluster + CNPG
#   ./scripts/local-qa.sh deploy      # just autodevops.sh
#   ./scripts/local-qa.sh all --skip-qa
#   ./scripts/local-qa.sh down

# Strict mode minus -u: scripts/ci/lib/helpers.sh references env vars like
# ${CI_PIPELINE_ID} without `:-` defaults, so `set -u` would trip the moment
# it's sourced. The lib is shared with non-strict CI callers; we match that
# convention here rather than patching every bare expansion.
set -eo pipefail

# ──────────────────────────────────────────────────────────────────────────────
# Config + helpers
# ──────────────────────────────────────────────────────────────────────────────

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${PROJECT_ROOT}"

CLUSTER_NAME="gitlab-local"
DOCKER_NETWORK="k3d-gitlab-local"
CACHES=("quay-cache:https://quay.io" "gitlab-cache:https://registry.gitlab.com")

# Everything the QA stage emits lives under ${LOCAL_QA_DIR}: per-shard
# QA_ARTIFACTS_DIR (qa-shard-N/), the gitlab-qa stdout/stderr logs
# (qa-shard-N.log), and the merged Allure inputs / generated report
# (allure-merged/, allure-report/). The directory is in .gitignore.
LOCAL_QA_DIR="${LOCAL_QA_DIR:-${PROJECT_ROOT}/local-qa}"

# tmux session name spawned to live-watch parallel shard logs. Skipped
# when QA_SHARDS == 1 (no benefit) or when tmux is not on PATH.
TMUX_SESSION="${TMUX_SESSION:-local-qa}"

: "${QA_SHARDS:=5}"
: "${GITLAB_QA_VERSION:=15.7.2}"
: "${CNPG_CHART_VERSION:=0.28.0}"
: "${CNPG_POSTGRESQL_TAG:=17}"
: "${GARAGE_APP_VERSION:=2.3.0}"
export CNPG_POSTGRESQL_TAG GARAGE_APP_VERSION

log()   { printf '\033[36m[local-qa]\033[0m %s\n' "$*"; }
warn()  { printf '\033[33m[local-qa] WARN\033[0m %s\n' "$*"; }
die()   { printf '\033[31m[local-qa] FATAL\033[0m %s\n' "$*" >&2; exit 1; }

require() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || die "missing required tool: $cmd"
  done
}

# QA_EE_LICENSE feeds the gitlab-license Secret (cmd_deploy) and is consumed by
# gitlab-qa (cmd_qa). Without it the deploy still completes but EE-only test
# specs silently skip or fail at runtime — fail fast instead.
require_ee_license() {
  [[ -n "${QA_EE_LICENSE:-}" ]] \
    || die "QA_EE_LICENSE is unset — export it (or load from your password manager) before running deploy/qa"
}

# Pre-seed the env the autodevops.sh orchestrator and the QA loop expect. Idempotent.
seed_env() {
  source "${PROJECT_ROOT}/scripts/ci/lib/helpers.sh"
  export NAMESPACE="${NAMESPACE:-default}"
  export KUBE_NAMESPACE="${NAMESPACE}"
  export USE_DEV_STACK="${USE_DEV_STACK:-true}"
  export K3D_MODE="${K3D_MODE:-true}"
  export K3D_USE_NGINX_INGRESS="${K3D_USE_NGINX_INGRESS:-1}"
  export HOST_SUFFIX="${HOST_SUFFIX:-}"

  # Source DEV_STACK_CHART_VERSION from .gitlab-ci.yml so local runs track
  # what CI ships — avoids the silent drift the hardcoded fallbacks above
  # (CNPG/GARAGE) suffer from. Only read once per shell.
  if [[ -z "${DEV_STACK_CHART_VERSION:-}" ]]; then
    require yq
    DEV_STACK_CHART_VERSION="$(yq '.variables.DEV_STACK_CHART_VERSION' "${PROJECT_ROOT}/.gitlab-ci.yml")"
    [[ -n "${DEV_STACK_CHART_VERSION}" && "${DEV_STACK_CHART_VERSION}" != "null" ]] \
      || die "could not read DEV_STACK_CHART_VERSION from .gitlab-ci.yml"
    export DEV_STACK_CHART_VERSION
  fi
  export QA_DOCKER_NETWORK="${QA_DOCKER_NETWORK:-${DOCKER_NETWORK}}"

  # k3d merges the new cluster's entry into the user's default kubeconfig
  # (${KUBECONFIG:-~/.kube/config}) on `k3d cluster create`, and removes it
  # on `k3d cluster delete`. We don't write a separate kubeconfig file —
  # we just guarantee the current-context is pointed at this cluster, in
  # case the user has switched to another context since up.
  if k3d cluster list "${CLUSTER_NAME}" >/dev/null 2>&1; then
    kubectl config use-context "k3d-${CLUSTER_NAME}" >/dev/null 2>&1 \
      || warn "kubectl context k3d-${CLUSTER_NAME} not found in default kubeconfig"
    LB_IP="$(k3d cluster list "${CLUSTER_NAME}" -o json | jq -r '.[0].serverLoadBalancer.IP.IP')"
    export LB_IP
    export KUBE_INGRESS_BASE_DOMAIN="${LB_IP}.nip.io"
    export GITLAB_URL="gitlab.${KUBE_INGRESS_BASE_DOMAIN}"
  fi
}

# ──────────────────────────────────────────────────────────────────────────────
# Subcommands
# ──────────────────────────────────────────────────────────────────────────────

cmd_up() {
  log "==> up: provisioning docker network, registry caches, k3d cluster, CNPG operator"
  require docker k3d helm kubectl jq envsubst skopeo

  if ! docker network inspect "${DOCKER_NETWORK}" >/dev/null 2>&1; then
    log "creating docker network ${DOCKER_NETWORK}"
    docker network create "${DOCKER_NETWORK}" >/dev/null
  else
    log "docker network ${DOCKER_NETWORK} already exists"
  fi

  for entry in "${CACHES[@]}"; do
    name="${entry%%:*}"
    upstream="${entry#*:}"
    if k3d registry list "k3d-${name}" >/dev/null 2>&1; then
      log "registry cache k3d-${name} already running"
    else
      log "creating registry cache k3d-${name} (proxy → ${upstream})"
      k3d registry create "${name}" --proxy-remote-url "${upstream}" \
        --default-network "${DOCKER_NETWORK}" >/dev/null
    fi
  done

  if k3d cluster list "${CLUSTER_NAME}" >/dev/null 2>&1; then
    log "k3d cluster ${CLUSTER_NAME} already exists"
  else
    log "creating k3d cluster ${CLUSTER_NAME}"
    k3d cluster create "${CLUSTER_NAME}" \
      --servers 1 --network "${DOCKER_NETWORK}" \
      --k3s-arg "--disable=traefik@server:*" \
      --port "80:80@loadbalancer" \
      --port "443:443@loadbalancer" \
      --port "22:22@loadbalancer" \
      --registry-config "${PROJECT_ROOT}/scripts/registries.yaml" >/dev/null
  fi

  # `k3d cluster create` above already merged the new cluster into the user's
  # default kubeconfig and set k3d-${CLUSTER_NAME} as the current context.
  # seed_env re-asserts the context in case something switched it.
  seed_env
  log "kubectl context: $(kubectl config current-context)"
  kubectl wait --for=condition=Ready --timeout=120s -n kube-system pods --all >/dev/null

  helm repo add cnpg https://cloudnative-pg.github.io/charts >/dev/null 2>&1 || true
  log "installing CloudNativePG operator (chart ${CNPG_CHART_VERSION})"
  helm upgrade --install cnpg cnpg/cloudnative-pg --version "${CNPG_CHART_VERSION}" \
    -n cnpg-system --create-namespace --wait >/dev/null

  log "cluster ready (LB_IP=${LB_IP}, KUBE_INGRESS_BASE_DOMAIN=${KUBE_INGRESS_BASE_DOMAIN})"
}

cmd_deploy() {
  log "==> deploy: running autodevops.sh against k3d cluster ${CLUSTER_NAME}"
  require_ee_license
  seed_env
  [[ -n "${LB_IP:-}" ]] || die "no cluster found — run ./scripts/local-qa.sh up first"

  local release
  release="$(release_name_base)-gitlab"
  log "release base: ${release} (namespace=${NAMESPACE}, domain=${KUBE_INGRESS_BASE_DOMAIN})"
  log "creating ${release}-gitlab-license Secret (empty if no QA_EE_LICENSE)"
  kubectl create secret generic "${release}-gitlab-license" -n "${NAMESPACE}" \
    --from-literal=license="${QA_EE_LICENSE:-}" \
    -o yaml --dry-run=client | kubectl apply -f - >/dev/null

  if [[ ! -f "${PROJECT_ROOT}/ci.digests.yaml" ]]; then
    log "pinning CNG image digests (skopeo via canonical registry)"
    GITLAB_VERSION="${GITLAB_VERSION:-master}" bash "${PROJECT_ROOT}/scripts/ci/pin_image_digests.sh"
  else
    log "ci.digests.yaml already present — skipping pin step"
  fi

  log "running bash scripts/ci/autodevops.sh"
  bash "${PROJECT_ROOT}/scripts/ci/autodevops.sh"
  log "deploy complete (helm releases below)"
  helm ls -A
}

cmd_specs() {
  log "==> specs: running chart feature specs (bundle exec rspec -t type:feature)"
  seed_env
  [[ -n "${LB_IP:-}" ]] || die "no cluster found — run ./scripts/local-qa.sh up first"
  require docker
  log "target: http://gitlab.${KUBE_INGRESS_BASE_DOMAIN} (LB=${LB_IP}, network=${DOCKER_NETWORK})"

  # The chart's Ingress hostnames resolve to a docker container IP that
  # macOS routes for curl but not for Ruby's raw connect(2). Run rspec
  # inside a sibling container on the same docker network as the cluster,
  # the same trick QA uses — see scripts/local-qa-specs.Dockerfile.
  local image="local-qa-specs:latest"
  local dockerfile="${PROJECT_ROOT}/scripts/local-qa-specs.Dockerfile"
  if ! docker image inspect "${image}" >/dev/null 2>&1; then
    require yq
    local ci_yaml="${PROJECT_ROOT}/.gitlab-ci.yml"
    local kubectl_v docker_v
    kubectl_v="$(yq '.variables.KUBECTL_VERSION' "${ci_yaml}")"
    docker_v="$(yq '.variables.DOCKER_VERSION' "${ci_yaml}")"
    [[ -n "${kubectl_v}" && "${kubectl_v}" != "null" ]] || die "could not read KUBECTL_VERSION from ${ci_yaml}"
    [[ -n "${docker_v}"  && "${docker_v}"  != "null" ]] || die "could not read DOCKER_VERSION from ${ci_yaml}"
    log "building ${image} from ${dockerfile} (kubectl v${kubectl_v}, docker ${docker_v}, one-time, ~1 min)"
    docker build \
      --build-arg "KUBECTL_VERSION=v${kubectl_v}" \
      --build-arg "DOCKER_CLI_VERSION=${docker_v}" \
      -t "${image}" -f "${dockerfile}" "${PROJECT_ROOT}/scripts" >/dev/null
  else
    log "spec runner image ${image} already built — reusing (docker rmi to rebuild)"
  fi

  source "${PROJECT_ROOT}/scripts/ci/autodevops.sh"
  log "minting admin PAT via toolbox"
  local admin_token
  admin_token="$(create_admin_pat)"
  [[ -n "${admin_token}" ]] || die "create_admin_pat returned empty"

  # The host kubeconfig points kubectl at 0.0.0.0:<random> (the k3d
  # serverlb's host port). Inside a sibling container that means the
  # container's own loopback — useless. Rewrite the server URL to the
  # in-network hostname; the cluster's TLS cert SAN covers
  # k3d-${CLUSTER_NAME}-serverlb so verification still works.
  mkdir -p "${LOCAL_QA_DIR}"
  local internal_kubeconfig="${LOCAL_QA_DIR}/kubeconfig-internal.yaml"
  log "writing in-network kubeconfig → ${internal_kubeconfig}"
  k3d kubeconfig get "${CLUSTER_NAME}" \
    | sed -E 's|server: https://0\.0\.0\.0:[0-9]+|server: https://k3d-'"${CLUSTER_NAME}"'-serverlb:6443|' \
    > "${internal_kubeconfig}"

  local bundle_cache="${LOCAL_QA_DIR}/bundle"
  mkdir -p "${bundle_cache}"
  log "bundle cache: ${bundle_cache}"

  # The deployed chart's release name is e.g. `dev-gitlab` (helm appends
  # `-gitlab` to release_name_base). spec/gitlab_test_helper.rb's
  # `release_name` reads $GITLAB_RELEASE_NAME and falls back to "gitlab",
  # so without this export the `kubectl scale -l app=...,release=gitlab`
  # selector matches no objects and scale_rails_down dies with
  # "error: no objects passed to scale".
  local release
  release="$(release_name_base)-gitlab"
  log "GITLAB_RELEASE_NAME=${release}"

  # The chart's initial-root-password Secret is auto-created by the deploy;
  # specs that hit /api/v4 expect $GITLAB_PASSWORD set.
  log "fetching initial root password from ${release}-gitlab-initial-root-password"
  local gitlab_password
  gitlab_password="$(kubectl get secret \
    "${release}-gitlab-initial-root-password" \
    -n "${NAMESPACE}" -o jsonpath='{.data.password}' | base64 -d)"

  # backups_spec.rb shells out to `docker login/push/pull` against the
  # chart's registry, which is exposed via the cluster's Ingress on HTTP
  # only — the daemon's default HTTPS pull fails TLS:
  #   tls: failed to verify certificate: x509: certificate is valid for
  #   ingress.local, not registry.192.168.117.5.nip.io
  # CI handles this with DOCKER_OPTIONS="--insecure-registry 172.16.0.0/12"
  # on its DinD service. We do the same: ephemeral `docker:dind` sidecar
  # on ${DOCKER_NETWORK}, configured with --insecure-registry covering
  # the bridge subnet. The spec runner points DOCKER_HOST at it so the
  # user's orbstack/colima daemon config stays untouched.
  local dind_container="local-qa-dind"
  local docker_subnet
  docker_subnet="$(docker network inspect "${DOCKER_NETWORK}" \
    --format '{{(index .IPAM.Config 0).Subnet}}')"
  log "starting ephemeral docker:dind on ${DOCKER_NETWORK} (insecure-registry=${docker_subnet})"
  docker rm -f "${dind_container}" >/dev/null 2>&1 || true
  docker run -d --rm --privileged \
    --name "${dind_container}" \
    --network "${DOCKER_NETWORK}" \
    -e DOCKER_TLS_CERTDIR= \
    docker:dind \
    --host=tcp://0.0.0.0:2375 \
    --insecure-registry="${docker_subnet}" >/dev/null
  # Wait for the DinD daemon to be reachable.
  local dind_ready=0
  for _ in $(seq 1 30); do
    if docker exec "${dind_container}" docker info >/dev/null 2>&1; then
      dind_ready=1
      break
    fi
    sleep 1
  done
  [[ "${dind_ready}" -eq 1 ]] || die "docker:dind sidecar did not come up"
  log "docker:dind ready at tcp://${dind_container}:2375"
  trap "docker rm -f '${dind_container}' >/dev/null 2>&1 || true" RETURN

  log "running bundle exec rspec inside ${image} on ${DOCKER_NETWORK}"
  local rspec_rc=0
  docker run --rm -t \
    --network "${DOCKER_NETWORK}" \
    -v "${PROJECT_ROOT}":/workspace \
    -v "${bundle_cache}":/bundle-cache \
    -v "${internal_kubeconfig}":/root/.kube/config:ro \
    -w /workspace \
    -e BUNDLE_PATH=/bundle-cache \
    -e PROTOCOL=http \
    -e GITLAB_URL="gitlab.${KUBE_INGRESS_BASE_DOMAIN}" \
    -e GITLAB_ROOT_DOMAIN="${KUBE_INGRESS_BASE_DOMAIN}" \
    -e REGISTRY_URL="registry.${KUBE_INGRESS_BASE_DOMAIN}" \
    -e GITLAB_RELEASE_NAME="${release}" \
    -e GITLAB_ADMIN_TOKEN="${admin_token}" \
    -e GITLAB_PASSWORD="${gitlab_password}" \
    -e DOCKER_HOST="tcp://${dind_container}:2375" \
    -e KUBE_NAMESPACE="${NAMESPACE}" \
    -e NAMESPACE="${NAMESPACE}" \
    "${image}" \
    bash -c 'bundle install -j "$(nproc)" --quiet && bundle exec rspec -c -f d spec -t "type:feature"' || rspec_rc=$?
  if [[ "${rspec_rc}" -eq 0 ]]; then
    log "specs passed"
  else
    warn "specs failed (rc=${rspec_rc})"
  fi
  return "${rspec_rc}"
}

cmd_qa() {
  log "==> qa: running gitlab-qa Test::Instance::Any in ${QA_SHARDS} parallel shard(s)"
  require_ee_license
  seed_env
  [[ -n "${LB_IP:-}" ]] || die "no cluster found — run ./scripts/local-qa.sh up first"
  require gem gitlab-qa

  source "${PROJECT_ROOT}/scripts/ci/qa.sh"
  qa_export_passwords

  # Pre-mint an admin PAT via the toolbox and hand it to gitlab-qa as
  # GITLAB_QA_ADMIN_ACCESS_TOKEN. Without this, gitlab-qa's `before(:suite)`
  # hook tries to fabricate the PAT through the UI (via
  # qa/page/profile/personal_access_tokens.rb::go_to_new_token_form), which
  # currently crashes on `gitlab/gitlab-ee-qa:nightly` with
  #   NameError: uninitialized constant QA::Runtime::API::Client::AuthorizationError
  # CI's k3d job does the same thing (.gitlab/ci/k3d-review-apps.gitlab-ci.yml
  # exports GITLAB_QA_ADMIN_ACCESS_TOKEN from $GITLAB_ADMIN_TOKEN).
  source "${PROJECT_ROOT}/scripts/ci/autodevops.sh"
  log "minting admin PAT via toolbox for GITLAB_QA_ADMIN_ACCESS_TOKEN"
  export GITLAB_QA_ADMIN_ACCESS_TOKEN
  GITLAB_QA_ADMIN_ACCESS_TOKEN="$(create_admin_pat)"
  [[ -n "${GITLAB_QA_ADMIN_ACCESS_TOKEN}" ]] || die "create_admin_pat returned empty"

  export GITLAB_PASSWORD
  GITLAB_PASSWORD="$(kubectl get secret \
    "$(release_name_base)-gitlab-gitlab-initial-root-password" \
    -n "${NAMESPACE}" -o jsonpath='{.data.password}' | base64 -d)"

  local qa_image="${QA_IMAGE:-gitlab/gitlab-ee-qa:nightly}"
  mkdir -p "${LOCAL_QA_DIR}"
  log "running ${QA_SHARDS} parallel gitlab-qa shard(s) against ${GITLAB_URL}"
  log "shard artifacts → ${LOCAL_QA_DIR}/qa-shard-{0..$((QA_SHARDS - 1))}/"

  # knapsack inside gitlab-ee-qa expects 0-based node indexes
  # (0 ≤ index < total); we use the same numbering for shard dirs / logs
  # so the on-disk layout matches what each shard's CI_NODE_INDEX says.
  local pids=()
  for ((i = 0; i < QA_SHARDS; i++)); do
    log "  spawning shard ${i}/${QA_SHARDS} → ${LOCAL_QA_DIR}/qa-shard-${i}.log"
    (
      export CI_NODE_INDEX="$i" CI_NODE_TOTAL="${QA_SHARDS}"
      export QA_ARTIFACTS_DIR="${LOCAL_QA_DIR}/qa-shard-${i}"
      mkdir -p "${QA_ARTIFACTS_DIR}"
      QA_DOCKER_NETWORK="${QA_DOCKER_NETWORK}" \
      SIGNUP_DISABLED=true QA_DEBUG=true QA_GENERATE_ALLURE_REPORT=true \
      GITLAB_USERNAME=root GITLAB_PASSWORD="${GITLAB_PASSWORD}" \
      GITLAB_ADMIN_USERNAME=root GITLAB_ADMIN_PASSWORD="${GITLAB_PASSWORD}" \
      gitlab-qa Test::Instance::Any --qa-image "${qa_image}" \
        EE "http://${GITLAB_URL}" -- \
        --tag smoke --tag ~skip_live_env --tag ~orchestrated \
        > "${LOCAL_QA_DIR}/qa-shard-${i}.log" 2>&1
    ) &
    pids+=("$!")
  done

  # For parallel runs, spawn a detached tmux session with one window per
  # shard tailing its log. Single-shard runs use the controlling terminal
  # and don't need it. The session is left up when shards finish so the
  # caller can scroll through final output; kill with
  # `tmux kill-session -t ${TMUX_SESSION}` when done.
  if [[ "${QA_SHARDS}" -gt 1 ]] && command -v tmux >/dev/null 2>&1; then
    tmux kill-session -t "${TMUX_SESSION}" 2>/dev/null || true
    tmux new-session -d -s "${TMUX_SESSION}" -n "shard-0" \
      "tail -F '${LOCAL_QA_DIR}/qa-shard-0.log'"
    for ((i = 1; i < QA_SHARDS; i++)); do
      tmux new-window -t "${TMUX_SESSION}" -n "shard-${i}" \
        "tail -F '${LOCAL_QA_DIR}/qa-shard-${i}.log'"
    done
    log "live shard logs: \`tmux attach -t ${TMUX_SESSION}\` (Ctrl-b n/p switches windows)"
  elif [[ "${QA_SHARDS}" -gt 1 ]]; then
    warn "tmux not installed — install \`brew install tmux\` to live-watch parallel shards"
  fi

  local rc=0
  for pid in "${pids[@]}"; do
    wait "$pid" || rc=$?
  done
  log "all shards complete (last non-zero rc=${rc})"
  return "${rc}"
}

cmd_report() {
  log "==> report: merging Allure results from ${LOCAL_QA_DIR}/qa-shard-*/"
  require allure
  local merged="${LOCAL_QA_DIR}/allure-merged"
  rm -rf "${merged}"
  mkdir -p "${merged}"

  # Each shard writes gitlab-qa-run-*/<scenario>/allure-results.
  local count=0
  shopt -s nullglob
  for d in "${LOCAL_QA_DIR}"/qa-shard-*/gitlab-qa-run-*/*/allure-results; do
    cp -r "${d}/." "${merged}/"
    count=$((count + 1))
  done
  shopt -u nullglob

  if [[ "${count}" -eq 0 ]]; then
    warn "no allure-results found under ${LOCAL_QA_DIR}/qa-shard-*/gitlab-qa-run-*/ — did the QA step run?"
    return 0
  fi
  log "merged results from ${count} shard director(ies); opening allure serve"
  allure serve "${merged}"
}

cmd_down() {
  log "==> down: tearing down k3d cluster ${CLUSTER_NAME}"
  seed_env || true
  local release
  release="$(release_name_base 2>/dev/null || echo dev)-gitlab"

  if k3d cluster list "${CLUSTER_NAME}" >/dev/null 2>&1; then
    log "deleting k3d cluster ${CLUSTER_NAME} (release base was ${release})"
    k3d cluster delete "${CLUSTER_NAME}" >/dev/null
    log "k3d cluster ${CLUSTER_NAME} deleted"
  else
    log "no k3d cluster ${CLUSTER_NAME} to delete"
  fi
  log "caches and ${DOCKER_NETWORK} kept; remove manually if no longer needed"
}

cmd_all() {
  local skip_qa=0
  for arg in "$@"; do
    case "${arg}" in
      --skip-qa) skip_qa=1 ;;
      *) die "unknown all-mode flag: ${arg}" ;;
    esac
  done

  log "==> all: up → deploy → qa → report (skip_qa=${skip_qa})"
  cmd_up
  cmd_deploy
  local qa_rc=0
  if [[ "${skip_qa}" -eq 0 ]]; then
    cmd_specs
    # QA shard failures must not skip the report — we still want the Allure
    # artifacts assembled so the failure can be investigated. Capture the rc
    # and re-raise after cmd_report so callers/CI still see non-zero.
    cmd_qa || qa_rc=$?
    [[ "${qa_rc}" -ne 0 ]] && warn "cmd_qa exited with rc=${qa_rc} — proceeding to report"
    cmd_report
  else
    log "--skip-qa: skipping qa + report steps"
  fi
  log "done. GitLab URL: http://${GITLAB_URL}"
  log "  root password: kubectl get secret \$(release_name_base)-gitlab-gitlab-initial-root-password -n ${NAMESPACE} -o jsonpath='{.data.password}' | base64 -d"
  return "${qa_rc}"
}

# ──────────────────────────────────────────────────────────────────────────────
# Dispatch
# ──────────────────────────────────────────────────────────────────────────────

case "${1:-all}" in
  up)     shift || true; cmd_up     "$@" ;;
  deploy) shift || true; cmd_deploy "$@" ;;
  specs)  shift || true; cmd_specs  "$@" ;;
  qa)     shift || true; cmd_qa     "$@" ;;
  report) shift || true; cmd_report "$@" ;;
  down)   shift || true; cmd_down   "$@" ;;
  all)    shift || true; cmd_all    "$@" ;;
  -h|--help)
    sed -n '2,40p' "$0"
    ;;
  *)
    die "unknown subcommand: $1 (run --help for usage)"
    ;;
esac
