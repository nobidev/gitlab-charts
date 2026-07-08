#!/usr/bin/env bash
# Regenerate the proto-derived chart values artifacts from the single source of
# truth in proto/charts/values/v1/values.proto:
#
#   pkg/values/**            Go types (for the GitLab Operator) + protovalidate
#   out/jsonschema/**        base JSON Schema from protoschema-jsonschema
#   out/values.schema.json   post-processed schema (helm_naming + lifecycle)
#
# CI runs this and fails if the committed output changes (drift check). See
# doc/development/validation.md.

set -euo pipefail

project_root="$(realpath "$(dirname -- "${BASH_SOURCE[0]}")/..")"
cd "$project_root"

# Prefer a buf on PATH; fall back to the mise-managed install.
if command -v buf >/dev/null 2>&1; then
  BUF=buf
elif command -v mise >/dev/null 2>&1; then
  BUF="$(mise which buf)"
else
  echo "error: buf not found. Run 'mise install buf' or add buf to your PATH." >&2
  exit 1
fi

echo "--- buf dep update"
"$BUF" dep update

# Targeted cleanup of only the generated artifacts. buf.gen.yaml intentionally
# does not set `clean: true`, because the generated Go shares pkg/values with
# the hand-written go.mod and validate.go.
echo "--- clean generated artifacts"
find pkg/values -name '*.pb.go' -delete
rm -rf out/jsonschema

echo "--- buf generate (Go types + protovalidate + base JSON Schema)"
"$BUF" generate

echo "--- post-process JSON Schema (helm_naming + lifecycle annotations)"
# protoschema-jsonschema emits one self-contained bundle per message; we only
# consume the top-level GitLabValues bundle (it inlines every referenced $def).
go -C tools/helm-schema-postprocess run . \
  --input "$project_root/out/jsonschema/charts.values.v1.GitLabValues.schema.strict.bundle.json" \
  --output "$project_root/out/values.schema.json"

# out/jsonschema is a build intermediate (hundreds of per-message bundles). Only
# out/values.schema.json is committed and consumed.
rm -rf "$project_root/out/jsonschema"

echo "--- done: out/values.schema.json"
