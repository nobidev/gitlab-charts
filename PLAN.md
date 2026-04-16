# `common-templates` Integration Plan

## What `common-templates` v1.3.1 provides

The library chart at `https://gitlab.com/gitlab-org/cloud-native/charts/common-templates` exposes six named templates:

| Template | Purpose |
|---|---|
| `gitlab.common.name` | Chart name (≤63 chars) |
| `gitlab.common.fullname` | `<release>-<chart>` (≤63 chars) |
| `gitlab.common.selectorLabels` | **New-style** selector labels (`app.kubernetes.io/*`) |
| `gitlab.common.standardLabels` | **New-style** standard labels (`app.kubernetes.io/*` only) |
| `gitlab.common.legacySelectorLabels` | **Legacy** selector labels (`app:`, `release:`) — deprecated, removed in v20 |
| `gitlab.common.legacyStandardLabels` | **Legacy** standard labels (`app:`, `chart:`, `release:`, `heritage:`) + new `app.kubernetes.io/*` additions — deprecated, removed in v20 |
| `gitlab.common.commonLabels` | User-defined labels from `.Values.common.labels` / `.Values.global.common.labels` |

---

## Identified Differences

### 1. `name` / `fullname` — No meaningful difference

| | GitLab chart (`name`) | `gitlab.common.name` |
|---|---|---|
| Logic | `default .Chart.Name .Values.nameOverride \| trunc 63 \| trimSuffix "-"` | `.Values.nameOverride \| default .Chart.Name \| trunc 63 \| trimSuffix "-"` |

Functionally identical. Same for `fullname` / `gitlab.common.fullname`. No risk.

---

### 2. `gitlab.commonLabels` vs `gitlab.common.commonLabels` — Minor defensive difference

| | Current `gitlab.commonLabels` | `gitlab.common.commonLabels` |
|---|---|---|
| `.Values.common.labels` access | `pluck "labels" (default (dict) .Values.common) \| first` | `.Values.common \| default (dict) \| dig "labels" nil` |
| `.Values.global.common.labels` access | Direct access (panics if `.Values.global` is nil) | `.Values.global \| default (dict) \| dig "common" "labels" nil` (nil-safe) |

The new version is more defensive against nil `.Values.global`. Functionally equivalent in normal use. **No breaking change.**

---

### 3. `gitlab.selectorLabels` vs `gitlab.common.legacySelectorLabels` — Equivalent ✓

**Current `gitlab.selectorLabels`:**
```yaml
app: <chart-name>
release: <release-name>
# + app.kubernetes.io/name: <release-name>  only if global.application.create=true
```

**`gitlab.common.legacySelectorLabels`:**
```yaml
app: <chart-name>
release: <release-name>
# + app.kubernetes.io/name: <release-name>  only if global.application.create=true
```

These are **identical in output**. `legacySelectorLabels` is the safe drop-in replacement for `gitlab.selectorLabels`.

---

### 4. `gitlab.selectorLabels` vs `gitlab.common.selectorLabels` — **BREAKING for selectors**

**Current `gitlab.selectorLabels`:**
```yaml
app: <chart-name>
release: <release-name>
```

**`gitlab.common.selectorLabels` (new-style):**
```yaml
app.kubernetes.io/name: <chart-name>
app.kubernetes.io/instance: <release-name>
```

**⚠️ Critical risk:** `spec.selector.matchLabels` on `Deployment`, `StatefulSet`, `DaemonSet`, and
`PodDisruptionBudget` are **immutable** after creation. Switching from `gitlab.selectorLabels` to
`gitlab.common.selectorLabels` on any existing workload would require deleting and recreating those
resources. This affects every sub-chart that uses `gitlab.selectorLabels` in its selector — which is
nearly all of them: `kas`, `gitlab-shell`, `gitlab-pages`, `sidekiq`, `webservice`, `gitaly`,
`praefect`, `mailroom`, `toolbox`, `gitlab-exporter`, `spamcheck`, `geo-logcursor`, `registry`
(inline), `minio` (inline), and `nginx-ingress` (uses its own `ingress-nginx.selectorLabels`).

---

### 5. `gitlab.standardLabels` vs `gitlab.common.legacyStandardLabels` — Additive additions + one inversion

**Current `gitlab.standardLabels`** (default, `global.application.create=false`):
```yaml
app: <chart-name>
chart: <chart-name>-<version>
release: <release-name>
heritage: Helm
```

**`gitlab.common.legacyStandardLabels`** (default, `global.application.create=false`):
```yaml
app: <chart-name>
release: <release-name>
chart: <chart-name>-<version>
heritage: Helm
app.kubernetes.io/name: <chart-name>       # NEW (added when create=false)
app.kubernetes.io/instance: <release-name> # NEW
app.kubernetes.io/part-of: GitLab          # NEW
app.kubernetes.io/managed-by: Helm         # NEW
helm.sh/chart: <chart-name>-<version>      # NEW
```

The five new `app.kubernetes.io/*` and `helm.sh/chart` labels are **additive** and safe for
non-selector metadata labels.

**⚠️ `global.application.create=true` inversion — significant behavioral difference:**

| | Current `gitlab.standardLabels` | `gitlab.common.legacyStandardLabels` |
|---|---|---|
| `app.kubernetes.io/name` when `create=true` | `<release-name>` (e.g. `"test"`) | **omitted entirely** |
| `app.kubernetes.io/name` when `create=false` | **omitted** | `<chart-name>` (e.g. `"kas"`) |

The logic is **inverted**. The current template adds `app.kubernetes.io/name: <release-name>` when
`global.application.create=true`. The new template adds `app.kubernetes.io/name: <chart-name>` when
`global.application.create=false`, and omits it when `true`. This is a semantic difference for users
who have `global.application.create: true` (non-default).

---

### 6. `gitlab.standardLabels` vs `gitlab.common.standardLabels` — **BREAKING for non-selector metadata**

**`gitlab.common.standardLabels`** (new-style, no legacy labels):
```yaml
app.kubernetes.io/name: <chart-name>
app.kubernetes.io/instance: <release-name>
app.kubernetes.io/part-of: GitLab
app.kubernetes.io/managed-by: Helm
helm.sh/chart: <chart-name>-<version>
```

This **drops** `app:`, `chart:`, `release:`, `heritage:` entirely. The existing
`spec/configuration/labels_spec.rb` test explicitly verifies that all GitLab-owned `Deployment`,
`StatefulSet`, and `Job` resources carry `app`, `chart`, `heritage`, and `release` — so switching to
`gitlab.common.standardLabels` would **fail those tests** and break any tooling or monitoring that
selects on those legacy labels.

---

### 7. `gitlab.app.kubernetes.io.labels` conflict with `gitlab.common.legacyStandardLabels`

The existing `gitlab.app.kubernetes.io.labels` template emits:
```yaml
app.kubernetes.io/name: <release-name>   # e.g. "test"
app.kubernetes.io/version: <version>
```

`gitlab.common.legacyStandardLabels` (when `create=false`) emits:
```yaml
app.kubernetes.io/name: <chart-name>   # e.g. "kas"
```

These two templates are currently used **together** on Deployment metadata and pod templates (e.g.
`kas`, `webservice`, `sidekiq`, `gitlab-shell`, `gitaly`, `praefect`, `mailroom`, `toolbox`,
`spamcheck`, `geo-logcursor`, `gitlab-exporter`, `registry`, `minio`). If
`gitlab.common.legacyStandardLabels` replaces `gitlab.standardLabels` while
`gitlab.app.kubernetes.io.labels` is still also included, the two templates will emit **conflicting
values for `app.kubernetes.io/name`**. In Helm's YAML rendering, the last one wins — but the result
is non-deterministic depending on template ordering, and the intent is unclear.

---

### 8. `registry` deployment — inline selector, not using `gitlab.selectorLabels`

The `registry` deployment uses inline selectors:
```yaml
selector:
  matchLabels:
    app: {{ template "name" . }}
    release: {{ .Release.Name }}
```

This is not using `gitlab.selectorLabels` at all. Same pattern in `minio`. These are safe from the
selector migration concern but should be noted as inconsistencies.

---

### 9. `webservice.spec.selector` — uses `app:` + `release:` directly

The `webservice` sub-chart defines its own `webservice.spec.selector` helper:
```yaml
matchLabels:
  app: {{ template "name" $ }}
  release: {{ $.Release.Name }}
  gitlab.com/webservice-name: <deployment-name>
```

This is also not using `gitlab.selectorLabels` directly. Safe from migration, but inconsistent.

---

### 10. `registry.migration.standardLabels` — parses `gitlab.standardLabels` as YAML

```go
{{- $labels := (include "gitlab.standardLabels" .) | fromYaml }}
{{- $_ := set $labels "app" "registry-migrations" }}
```

If `gitlab.standardLabels` is replaced with `gitlab.common.legacyStandardLabels`, the parsed map
will contain additional keys (`app.kubernetes.io/*`, `helm.sh/chart`). This is safe — the extra keys
are just passed through. However, if `gitlab.common.standardLabels` (new-style, no `app:`) were
used, the `app` key would not exist in the parsed map and the `set` would add it fresh — which is
actually fine, but the intent of the template (to override `app` from the standard labels) would be
subtly different.

---

## Summary of Identified Differences and Risks

### 🔴 Breaking / High Risk

| # | Issue | Affected Resources |
|---|---|---|
| A | **`gitlab.common.selectorLabels` uses `app.kubernetes.io/*` keys** — completely different from current `app:`/`release:` selectors. Using it on any existing workload selector requires delete+recreate. | All `Deployment`, `StatefulSet`, `PodDisruptionBudget` selectors across all sub-charts |
| B | **`gitlab.common.standardLabels` drops legacy labels** (`app`, `chart`, `release`, `heritage`) — fails existing `labels_spec.rb` tests and breaks label-based tooling. | All resources using `gitlab.standardLabels` |

### 🟡 Behavioral Difference / Medium Risk

| # | Issue |
|---|---|
| C | **`app.kubernetes.io/name` logic is inverted** between `gitlab.standardLabels` and `gitlab.common.legacyStandardLabels` when `global.application.create=true`. Current: adds `app.kubernetes.io/name: <release-name>`. New: omits it entirely. |
| D | **`gitlab.app.kubernetes.io.labels` conflicts with `gitlab.common.legacyStandardLabels`** on `app.kubernetes.io/name` — one sets `<release-name>`, the other sets `<chart-name>`. Both are currently applied together on Deployment metadata and pod templates. The conflict must be resolved before migration. |

### 🟢 Safe / Additive

| # | Issue |
|---|---|
| E | `gitlab.common.legacySelectorLabels` is **output-identical** to `gitlab.selectorLabels` — safe drop-in. |
| F | `gitlab.common.legacyStandardLabels` adds 5 new `app.kubernetes.io/*` / `helm.sh/chart` labels to non-selector metadata — additive, safe. |
| G | `gitlab.common.commonLabels` is functionally equivalent to `gitlab.commonLabels` with added nil-safety. |
| H | `gitlab.common.name` / `gitlab.common.fullname` are functionally identical to `name` / `fullname`. |

---

## Recommended Migration Plan

1. **Do not use `gitlab.common.selectorLabels` or `gitlab.common.standardLabels` yet.** These are
   the "new-style" templates intended for a future major version. They require a coordinated
   delete-and-recreate of all workloads.

2. **The safe migration path for this chart is `gitlab.common.legacySelectorLabels` and
   `gitlab.common.legacyStandardLabels`**, which are the backward-compatible wrappers explicitly
   designed for this transition.

3. **Before replacing `gitlab.standardLabels` with `gitlab.common.legacyStandardLabels`**, resolve
   the `app.kubernetes.io/name` conflict with `gitlab.app.kubernetes.io.labels`. Options:
   - Remove `gitlab.app.kubernetes.io.labels` from templates that will use
     `gitlab.common.legacyStandardLabels` (since the new template already emits
     `app.kubernetes.io/name` when `create=false`).
   - Or keep `gitlab.app.kubernetes.io.labels` applied *after* `gitlab.common.legacyStandardLabels`
     so it wins on `app.kubernetes.io/name` (preserving the current `<release-name>` value), but
     this is fragile.

4. **The `global.application.create=true` inversion** (issue C) should be explicitly tested. If any
   users rely on `app.kubernetes.io/name: <release-name>` being present when `create=true`, the
   behavior changes. The `application.yaml` selector already uses
   `app.kubernetes.io/name: {{ .Release.Name }}` directly, so the Application resource itself is
   unaffected — but any external tooling selecting on that label on pods/deployments would be.

5. **`registry` and `minio` inline selectors** (`app:`/`release:` hardcoded) are already consistent
   with the legacy label scheme and require no changes for the `legacySelectorLabels` migration.

6. **Update `spec/configuration/labels_spec.rb`** after migration to verify the new
   `app.kubernetes.io/*` labels are present in addition to the legacy four.

---

## Implications for `app.kubernetes.io/version`

### How it is currently set

`app.kubernetes.io/version` is emitted **exclusively** by `gitlab.app.kubernetes.io.labels`, defined
in `templates/_application.tpl`:

```
{{- define "gitlab.app.kubernetes.io.labels" -}}
{{ include "gitlab.application.labels" . }}
app.kubernetes.io/version: {{ coalesce .Values.imageTag (.image | default (dict)).tag (include "gitlab.versionTag" .) }}
{{- end -}}
```

The version value is resolved via `coalesce` in priority order:
1. `.Values.imageTag` — a chart-level image tag override
2. `.image.tag` — a per-image tag
3. `gitlab.versionTag` — derived from `global.gitlabVersion` or `Chart.AppVersion`

This template is applied to **Deployment and StatefulSet metadata and pod templates** for: `kas`,
`gitlab-shell`, `gitlab-pages`, `sidekiq`, `webservice`, `gitaly` (both statefulsets), `praefect`,
`mailroom`, `toolbox`, `gitlab-exporter`, `spamcheck`, `geo-logcursor`, `registry`, and `minio`. It
is **not** applied to non-workload resources (ConfigMaps, Services, PDBs, HPAs, etc.).

### What `common-templates` provides

**None** of the six `common-templates` templates emit `app.kubernetes.io/version`. It is absent from
`gitlab.common.standardLabels`, `gitlab.common.legacyStandardLabels`, and all others.

`nginx-ingress` has its own separate `ingress-nginx.labels` helper that emits
`app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}` — but that is entirely independent of
`common-templates`.

### Implications

**1. `app.kubernetes.io/version` has no equivalent in `common-templates` — it must be preserved
separately.**

If `gitlab.standardLabels` is replaced with `gitlab.common.legacyStandardLabels`,
`app.kubernetes.io/version` is not affected at all — it comes from `gitlab.app.kubernetes.io.labels`,
which is a separate include. However, as already noted in issue D above,
`gitlab.app.kubernetes.io.labels` also emits `app.kubernetes.io/name: <release-name>`, which
conflicts with the `app.kubernetes.io/name: <chart-name>` emitted by
`gitlab.common.legacyStandardLabels`. Resolving that conflict (e.g. by splitting
`gitlab.app.kubernetes.io.labels` into two separate templates — one for `app.kubernetes.io/name` and
one for `app.kubernetes.io/version`) would be necessary to avoid the collision while retaining the
version label.

**2. The version value is GitLab-application-specific, not chart-version-specific.**

`gitlab.common.legacyStandardLabels` emits `helm.sh/chart: <chart-name>-<chart-version>`, which
encodes the *Helm chart* version. `gitlab.app.kubernetes.io.labels` emits
`app.kubernetes.io/version` set to the *GitLab application image tag* (e.g. `v17.10.0`). These are
semantically different things and both are useful — the chart version for Helm tooling, the image
version for Kiali and service mesh observability. There is no conflict between them, and both should
be retained.

**3. The eventual migration to `gitlab.common.standardLabels` would lose `app.kubernetes.io/version`
unless it is added back explicitly.**

`gitlab.common.standardLabels` (the new-style, non-legacy template) does not include
`app.kubernetes.io/version`. If the chart eventually migrates to it, `app.kubernetes.io/version`
would need to be emitted via a separate include or added to a chart-local helper. This is a future
concern, not an immediate one for the `legacyStandardLabels` migration path.

**4. `app.kubernetes.io/version` is currently absent from non-workload resources.**

Since `gitlab.app.kubernetes.io.labels` is only included on Deployment/StatefulSet metadata and pod
templates, resources like Services, ConfigMaps, HPAs, PDBs, and NetworkPolicies do not carry
`app.kubernetes.io/version`. This is consistent with Kubernetes recommendations (version labels are
most meaningful on workload resources), and `common-templates` does not change this.

### Recommended action

The cleanest resolution to issue D is to **split `gitlab.app.kubernetes.io.labels` into two
helpers**:

- One for `app.kubernetes.io/name` — to be removed or superseded by `gitlab.common.legacyStandardLabels`.
- One for `app.kubernetes.io/version` — to be kept and included independently on workload resources.

This avoids the `app.kubernetes.io/name` collision while ensuring `app.kubernetes.io/version`
(carrying the GitLab application image tag) is not inadvertently dropped during the migration.
