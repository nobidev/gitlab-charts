---
stage: Systems
group: Distribution
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Shared Data ConfigMap
---

## Overview

{{< alert type="warning" >}}
The `shared-data` ConfigMap is strictly for internal use by GitLab charts and should NEVER be used by external charts or applications that connect to GitLab.
{{< /alert >}}

The `shared-data` ConfigMap is an **internal implementation detail** of the GitLab Helm chart. It provides a mechanism for GitLab subcharts to share runtime configuration information without relying on Helm values.

Key points:

- **Not a public API**: The structure, content, and availability of this ConfigMap may change at any time without notice or deprecation warnings.
- **No stability guarantees**: Data keys may be added, modified, or removed between any GitLab releases.
- **Internal implementation detail**: This ConfigMap exists solely to facilitate communication between GitLab subcharts.
- **External integrations**: If you're building external applications or charts that integrate with GitLab, use the documented public APIs and configuration methods instead.

## Purpose

The shared-data ConfigMap solves a specific problem in the GitLab Helm chart architecture:

When using the GitLab chart with the embedded PostgreSQL subchart, certain components (like the Container Registry) need to know at runtime whether they're connecting to the GitLab-managed PostgreSQL instance or an external database. This information affects how features like the registry database "prefer" mode should behave.

Traditional Helm values are evaluated at template rendering time, but some decisions need to be made at container runtime, 
and globals were getting too overused. The shared-data ConfigMap bridges this gap by providing runtime-accessible configuration data.

## How It's Used Internally

The shared-data ConfigMap is mounted as environment variables (using `envFrom` with prefix):

- **All ConfigMap keys are automatically exposed as environment variables**
- Kubernetes automatically converts keys to environment variable names
- Key naming: `postgresql-subchart-enabled` → Environment variable: `GL_SHARED_DATA_POSTGRESQL_SUBCHART_ENABLED`
- The `GL_SHARED_DATA_` prefix is automatically added
- Hyphens are converted to underscores, and the name is uppercased
- **No need to explicitly define each variable** - new keys automatically become available

**Implementation:**

```yaml
envFrom:
{{- include "gitlab.sharedData.envFrom" $ | nindent 10 }}
```

This single template call automatically exposes all ConfigMap keys as environment variables.

### Example: Container Registry

The Container Registry uses this ConfigMap to determine whether to enable the database "prefer" mode:

- If `POSTGRESQL_SUBCHART_ENABLED` is `"true"`, the registry can safely use `database.enabled: "prefer"`
- If `POSTGRESQL_SUBCHART_ENABLED` is `"false"`, the registry overrides prefer mode to `"false"` because it cannot guarantee the external database is properly configured

This prevents migration failures when using external PostgreSQL databases that may not have the registry database pre-created.

**Consider backward compatibility**

- New keys should be optional
- Consuming code should handle missing keys gracefully with defaults
- Example in shell: `VALUE="${GL_SHARED_DATA_MY_NEW_KEY:-default_value}"`
- Example in Gomplate: `{%- $value := env.Getenv "GL_SHARED_DATA_MY_NEW_KEY" | default "default_value" %}`
