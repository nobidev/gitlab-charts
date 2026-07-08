---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Validations of values using JSON Schema
---

Helm 3 introduced support for validation of values using
[schema files](https://helm.sh/docs/topics/charts/#schema-files) which follow
[JSON Schema](https://json-schema.org/). Helm charts in this repository also makes use
of this feature by defining `values.schema.json` file for each sub-chart.

Guidelines for developers regarding usage of schema files:

- If you are adding a new entry to or modifying an existing entry in the `values.yaml`
  file of a subchart, you must update the respective `values.schema.json` file to match
  this change.
- The first iteration of this task is expected to be completed when all the sub-charts
  are equipped with a schema file. You can check the progress of the first iteration in
  the [related epic](https://gitlab.com/groups/gitlab-org/charts/-/epics/8). Future
  iterations will focus on improving and polishing these schema files and enhance their
  efficiency and usability.
- All settings configurable via `values.yaml` must have type validations (ensure they
  accept only the correct data types as values) implemented in the `values.schema.json`
  file. This must be completed in the first iteration.
- During the first iteration, validation of required fields can be limited to ensuring
  the settings a user has defined in their `values.yaml` file is sufficient to spin up a
  pod with just that component, and without any error being reported in the logs. In
  future iterations, this should be expanded to ensure the pod is, in fact, functional.
  This involves deeper testing.

## Generate values artifacts from proto (experimental)

An experimental pipeline treats a Protocol Buffer definition as the single
source of truth for the chart values surface. One `buf generate` run produces
three artifacts from [`proto/charts/values/v1/values.proto`](../../proto/charts/values/v1/values.proto):

- Go types (`protoc-gen-go`) that the GitLab Operator imports for typed access
  to chart values, instead of freeform YAML.
- `protovalidate` constraints (`buf.validate`) enforced at runtime in Go.
- A `values.schema.json` (`protoschema-jsonschema`) for Helm native validation.

The proto models the in-repo values surface: the `global` settings, each GitLab
sub-chart (`gitaly`, `praefect`, `gitlab-shell`, `webservice`, `sidekiq`, `kas`,
`gitlab-pages`, `gitlab-exporter`, `geo-logcursor`, `mailroom`, `migrations`,
`toolbox`), the `registry` and `certmanager-issuer` charts, and top-level chart
concerns (`upgradeCheck`, `shared-secrets`, `gatewayApiResources`). Each
sub-chart is modeled in its own file under
[`proto/charts/values/v1/`](../../proto/charts/values/v1/), composed into
`GitLabValues` by [`values.proto`](../../proto/charts/values/v1/values.proto).

Bundled external charts (for example `prometheus`, `nginx-ingress`,
`gitlab-runner`, `gitlab-zoekt`, `openbao`, `cert-manager`, and the Gateway API
implementation) are out of scope: they are maintained in their own repositories.
Opaque Kubernetes passthrough blocks (resources, affinity, tolerations,
securityContext, and similar) are modeled as `google.protobuf.Struct`. This does
not replace the hand-maintained `values.schema.json` files described above.

### Regenerate the artifacts

Install `buf` (pinned in [`mise.toml`](../../mise.toml)) and run:

```shell
mise install buf
./scripts/generate-values.sh
```

The script runs `buf generate` and then a post-processing step
([`tools/helm-schema-postprocess`](../../tools/helm-schema-postprocess)) that
applies GitLab-specific annotations to the JSON Schema. The outputs are the
generated Go module in `pkg/values` and `out/values.schema.json`. Commit any
changes. CI regenerates the artifacts and fails when the committed output is
stale.

### Editor autocompletion and validation

The generated `out/values.schema.json` doubles as an editor schema. Add this
directive to the top of a values file to get autocompletion and validation in
editors that use the YAML language server:

```yaml
# yaml-language-server: $schema=./out/values.schema.json
```

The schema validates types, enums, ranges, and (through `additionalProperties`)
misspelled keys, while tolerating how `values.yaml` is actually written. The
post-processor:

- makes optional fields nullable, because a key left empty takes a default
  (often derived by a template function);
- keeps `additionalProperties: false` on modeled messages, so a misspelled key
  is flagged, but allows the bundled external sub-charts (`prometheus`,
  `nginx-ingress`, `gitlab-runner`, and so on) as unchecked passthrough at the
  root; and
- sets `required` only from `(buf.validate.field).required` annotations, not
  from proto presence.

Two layers of validation work together. The schema covers structure, types, and
unconditional required fields for editing and Helm. `protovalidate` is the
authoritative runtime validator on the generated Go types, and is where
cross-field and conditional rules belong (for example "set `global.psql.host`
or `global.psql.main.host`"), mirroring the checks in `templates/_checkConfig_*.tpl`.
`protovalidate` also enforces everything the JSON Schema cannot express, such as
CEL rules.

### Annotations

The custom options in
[`proto/gitlab/config/annotations.proto`](../../proto/gitlab/config/annotations.proto)
control the generated JSON Schema:

- `helm_naming` sets a message-wide naming convention. `CAMEL_CASE` converts
  proto `snake_case` field names to `lowerCamelCase` property names.
- `helm_name` overrides the property name for a single field. It takes
  precedence over `helm_naming`, and expresses names a convention cannot, such
  as `gitlab-shell`.
- `lifecycle_stage` marks a field's maturity. The post-processor surfaces it as
  an `x-gitlab-lifecycle-stage` vendor extension.

### Ownership boundary

Service teams own their configuration proto in their own repo. The Operate team
owns the chart-level `values.proto` that composes service configs into the
values structure, and the generation pipeline. This aligns with the
[Component Ownership Model](https://handbook.gitlab.com/handbook/engineering/infrastructure/production/component-ownership-model/).

## Validating immutable fields

Some fields in the Kubernetes spec are immutable. Ensure that no changes to
immutable fields would impact customer upgrades.

### Statefulset

A Statefulset contains a set of immutable fields. Ensure
that none of the fields that are not allowed to be modified
are indeed not modified. This negatively impacts the ability
to perform upgrades. Example error message:

```plaintext
Error: UPGRADE FAILED: cannot patch "a-gitaly" with kind StatefulSet
  StatefulSet.apps "a-gitaly" is invalid
  spec: Forbidden:
    updates to statefulset spec for fields other than
    'replicas', 'template', and 'updateStrategy'
    are forbidden
```
