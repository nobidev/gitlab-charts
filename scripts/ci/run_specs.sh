#!/bin/bash

# Strict mode only when executed directly, not when sourced. Sourcing a
# `set -e` script into a dev shell terminates that shell on first error
# (see local-ci-spike.md §"Friction-point catalog"). CI invokes this via
# `./scripts/ci/run_specs.sh` so the executed path keeps the original
# behaviour.
(return 0 2>/dev/null) || set -e

if [[ -n "${VARIABLES_FILE}" ]]; then
  source "${VARIABLES_FILE}"
else
  ./scripts/ci/integration_spec_setup.sh
fi

bundle config set --local path 'gems'
bundle config set --local frozen 'true'
bundle install -j $(nproc)

# For tests not being run on a cluster, use knapsack for parallelizing
if [[ "${RSPEC_TAGS}" == "~type:feature" ]] && [[ "${KNAPSACK_GENERATE_REPORT}" != "true" ]]; then
  bundle exec rake "knapsack:rspec[--color --format documentation --tag '${RSPEC_TAGS}']"
else
  bundle exec rspec -c -f d spec -t "${RSPEC_TAGS}"
fi
