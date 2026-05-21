#!/bin/bash

# Auto DevOps orchestrator.
#
# Runs in CI and locally:
#   - When sourced (`source scripts/ci/autodevops.sh`) it loads every helper
#     and deploy function; the caller invokes them individually. This is how
#     .gitlab-ci.yml, .gitlab/ci/k3d-templates.gitlab-ci.yml, and
#     scripts/ci/k3d_deploy.sh use it.
#   - When executed (`bash scripts/ci/autodevops.sh`) it runs the default
#     deploy sequence end-to-end against the current kubectl context. This
#     is the form used by the local k3d recipe in
#     doc/development/local_cluster.md.
#
# Required env (for executed mode):
#   NAMESPACE                  Target namespace (e.g. `default`).
#   KUBE_INGRESS_BASE_DOMAIN   Hostname suffix (e.g. `1.2.3.4.nip.io`).
# Optional:
#   TRACE=1                    Verbose tracing.
#   See lib/deploy.sh for the full env contract.

# Strict mode only when executed directly. Sourcing should not impose flags
# on the caller's shell. See local-ci-spike.md §"Friction-point catalog".
(return 0 2>/dev/null) || set -e
[[ "$TRACE" ]] && set -x

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR}/../.."

source "$SCRIPT_DIR/lib/helpers.sh"
source "$SCRIPT_DIR/lib/valkey.sh"
source "$SCRIPT_DIR/lib/cloudnativepg.sh"
source "$SCRIPT_DIR/lib/garage.sh"
source "$SCRIPT_DIR/lib/dev_stack.sh"
source "$SCRIPT_DIR/lib/deploy.sh"

# main is the executed-mode entry point. Sourced callers don't trigger it.
function main() {
  if [ -z "${NAMESPACE}" ]; then
    echo "autodevops.sh: NAMESPACE is unset; set it before invoking the script." >&2
    return 1
  fi
  set_context
  ensure_namespace
  deploy_external_components
  deploy_chart
  wait_for_pods
}

# When invoked directly (`bash scripts/ci/autodevops.sh`), run the orchestrator.
(return 0 2>/dev/null) || main "$@"
