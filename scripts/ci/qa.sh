#!/bin/bash

# Portable ISO-8601 UTC timestamp; GNU `date --iso-8601` and BSD `date -Iseconds`
# differ enough to break either platform, so use the explicit format string
# that both `date` implementations honour.
export QA_SCRIPT_SOURCED_DATE="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

function qa_export_passwords() {
  for x in {1..6}; do
    export "GITLAB_QA_PASSWORD_${x}"="$(qa_generate_password $x)"
  done
}


# password is sha256sum of:
# - CI_PIPELINE_CREATED_AT, which is stable, but unique per pipeline
# - CI_COMMIT_SHORT_SHA, which is unique per commit/pipelines
# - Input user "number" if provided
function qa_generate_password() {
  local user="${1:-1}"
  local ref="${CI_COMMIT_SHORT_SHA:-abcdef12345678}"
  local created="${CI_PIPELINE_CREATED_AT:-${QA_SCRIPT_SOURCED_DATE}}"

  # `sha256sum` ships with coreutils (Linux/CI runner); macOS dev shells have
  # only `shasum`. Pick whichever is available.
  if command -v sha256sum >/dev/null 2>&1; then
    echo -n "${ref}-${created}-${user}" | sha256sum | cut -f1 -d' '
  else
    echo -n "${ref}-${created}-${user}" | shasum -a 256 | cut -f1 -d' '
  fi
}
