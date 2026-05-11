---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Style guide
---

This document describes various guidelines and best practices for GitLab Helm chart development.

## Naming Conventions

We are using [camelCase](https://en.wikipedia.org/wiki/Camel_case) for our function names, and properties where they are used in `values.yaml`.
Helm [best practices](https://helm.sh/docs/chart_best_practices/values#naming-conventions) define camelCase as preferred.

Example: `gitlab.assembleHost`

Template functions are placed into namespaces according to the chart they are associated with, and named to match the affected populated value in the target file. Note that chart _global_ functions generally fall under the `gitlab.*` namespace.

Examples:

- `gitlab.redis.host`: provides the host name of the Redis server, as a part of the `gitlab` chart.
- `registry.image.tag`: tag of the registry image, as part of the `registry` chart.

Not acceptable:

- `gitlab.redis-server.host`: kebab-case.
- `registry.RedisServer.Url`: initial capitals.

## Common structure for `values.yaml`

Many charts need to be provided with the same information, for example we need to provide the Redis and PostgreSQL connection settings to multiple charts. Here we outline our standard naming and structure for those settings.

### Connecting to other services

```yaml
redis:
  host: redis.example.com
  port: 8080
    sentinels:
    - host: sentinel1.example.com
      port: 26379
  password:
    secret: gitlab-redis
    key: redis-password
```

- `redis` - the name for what the current chart needs to connect to
- `host` - the hostname of the Redis server. Comment out by default, use `0.0.0.0` as the example. If using Redis Sentinels, the `host` attribute needs to be set to the cluster name as specified in the `sentinel.conf`.
- `port` - the port to connect on. Comment out by default, and use the default port as the example.
- `password`- defines settings for the Kubernetes Secret containing the password.
- `sentinels.[].host` - defines the hostname of Redis Sentinel server for a Redis HA setup.
- `sentinels.[].port` - defines the port on which to connect to the Redis Sentinel server. Defaults to `26379`.

### Sharing secrets

We use secrets to store sensitive information like passwords and share them among the different charts/pods.

The common fields we use them in are:

- **TLS/SSL Certificates** - Sharing TLS/SSL certificates
- **Passwords** - Sharing the Redis password.
- **Auth Tokens** - Sharing the inter-service auth tokens
- **Other Secrets** - Sharing other secrets like JWT certificates and signing keys

### TLS/SSL Certificates

A TLS/SSL certificate is expected to be a valid [Kubernetes TLS Secret](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets).

For example, to set up the registry:

```yaml
registry:
  tls:
    secretName: <TLS secret name>
```

When a TLS certificate is shared between charts, it should be defined as [a global value](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/#global-chart-values).

```yaml
global:
  ingress:
    tls:
      secretName: <TLS secret name>
```

### Passwords

For example, where `redis` was the owning chart, and the other charts need to reference the `redis` password.

The owning chart should define its password secret like the following:

```yaml
password:
  secret: <secret name>
  key: <key name inside the secret to fetch>
```

Other charts should share the same password secret like the following:

```yaml
redis:
  password:
    secret: <secret name>
    key: <key name inside the secret to fetch>
```

### Auth Tokens

The owning chart should define its authToken secret like the following:

```yaml
authToken:
  secret: <secret name>
  key: <key name inside the secret to fetch>
```

Other charts should share the same password secret like the following:

```yaml
gitaly:
  authToken:
    secret: <secret name>
    key: <key name inside the secret to fetch>
```

For example, where `gitaly` was the owning chart, and the other charts need to reference the `gitaly` authToken.

### Other Secrets

Other secrets, such as the JWT signing certificate for the `registry` or the `gitaly` GPG signing
key, use the same format as `authToken` and `password` secrets.

To share such secrets from one chart to other charts, provide a configuration similar to
the example below in which the `registry` JWT signing certificate is shared with other charts.

The owning chart should define its secret like the following:

```yaml
certificate:
  secret: <secret name>
  key: <key name inside the secret to fetch>
```

Other charts should share the same secret like the following:

```yaml
registry:
  certificate:
    secret: <secret name>
    key: <key name inside the secret to fetch>
```

## Preferences on function use

We have evolved a set of preferences for developing these charts, regarding the
various functions available to use in gotmpl, Sprig, and Helm. The following
sections explain some of these, and reasoning behind them

### Use nindent over indent

When possible, make use of the `nindent` function instead of the `indent` function.
This preference is based on readability, and especially for Helm charts as complex
as ours can be. The preferred use of `nindent` has become community wide, and is also
now the default within templates generated by the `helm create` command.

Let's look at two snippet examples, which easily exemplify the reasoning:

Easy to read:

```yaml
  gitlab.yml.erb: |
    production: &base
      gitlab:
        host: {{ template "gitlab.gitlab.hostname" . }}
        https: {{ hasPrefix "https://" (include "gitlab.gitlab.url" .) }}
        {{- with .Values.global.hosts.ssh }}
        ssh_host: {{ . | quote }}
        {{- end }}
        {{- with .Values.global.appConfig }}
        max_request_duration_seconds: {{ default (include "gitlab.appConfig.maxRequestDurationSeconds" $) .maxRequestDurationSeconds }}
        impersonation_enabled: {{ .enableImpersonation }}
        application_settings_cache_seconds: {{ .applicationSettingsCacheSeconds | int }}
        usage_ping_enabled: {{ eq .enableUsagePing true }}
        username_changing_enabled: {{ eq .usernameChangingEnabled true }}
        issue_closing_pattern: {{ .issueClosingPattern | quote }}
        default_theme: {{ .defaultTheme }}
        {{- include "gitlab.appConfig.defaultProjectsFeatures.configuration" $ | nindent 8 }}
        webhook_timeout: {{ .webhookTimeout }}
        {{- end }}
        trusted_proxies:
        {{- if .Values.trusted_proxies }}
          {{- toYaml .Values.trusted_proxies | nindent 10 }}
        {{- end }}
        time_zone: {{ .Values.global.time_zone | quote }}
        {{- include "gitlab.outgoing_email_settings" . | nindent 8 }}
      {{- with .Values.global.appConfig }}
      {{- if .incomingEmail.enabled }}
      {{- include "gitlab.appConfig.incoming_email" . | nindent 6 }}
      {{- end }}
      {{- include "gitlab.appConfig.cronJobs" . | nindent 6 }}
      gravatar:
```

Hard to read:

```yaml
  gitlab.yml.erb: |
    production: &base
      gitlab:
        host: {{ template "gitlab.gitlab.hostname" . }}
        https: {{ hasPrefix "https://" (include "gitlab.gitlab.url" .) }}
{{- with .Values.global.hosts.ssh }}
        ssh_host: {{ . | quote }}
{{- end }}
{{- with .Values.global.appConfig }}
        max_request_duration_seconds: {{ default (include "gitlab.appConfig.maxRequestDurationSeconds" $) .maxRequestDurationSeconds }}
        impersonation_enabled: {{ .enableImpersonation }}
        usage_ping_enabled: {{ eq .enableUsagePing true }}
        username_changing_enabled: {{ eq .usernameChangingEnabled true }}
        issue_closing_pattern: {{ .issueClosingPattern | quote }}
        default_theme: {{ .defaultTheme }}
{{- include "gitlab.appConfig.defaultProjectsFeatures.configuration" $ | indent 8 }}
        webhook_timeout: {{ .webhookTimeout }}
{{- end }}
        trusted_proxies:
{{- if .Values.trusted_proxies }}
{{- toYaml .Values.trusted_proxies | indent 10 }}
{{- end }}
        time_zone: {{ .Values.global.time_zone | quote }}
{{- include "gitlab.outgoing_email_settings" . | indent 8 }}
{{- with .Values.global.appConfig }}
{{- if .incomingEmail.enabled }}
{{- include "gitlab.appConfig.incoming_email" . | indent 6 }}
{{- end }}
{{- include "gitlab.appConfig.cronJobs" . | indent 6 }}
      gravatar:
```

Related issue: [#729 Refactoring: Helm templates](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/729)

### Nested Value Access

When accessing nested values in Helm templates, choose the appropriate safe navigation pattern based on your use case to prevent template rendering failures. Below we describe each case with examples.

#### When to use each approach

- **`dig`**: When you need fallback defaults and the path is known at template time. Best for most use cases.
- **`index`**: When accessing dynamic keys, working with complex nested structures, or naming conventions imcompatible with Go, like kebab-case or snake_case.
- **Parentheses**: For simple cases where you just need safe navigation without defaults.
- **Direct access**: Only when you can guarantee the full path exists (rare in practice).

#### Use `dig` for safe access with fallback defaults

The [`dig` function](https://masterminds.github.io/sprig/dicts.html#dig) provides safe nested access with default values and is often the most robust approach:

```yaml
{{- $host := dig "database" "connection" "host" "localhost" .Values -}}
{{- $port := dig "database" "connection" "port" 5432 .Values -}}
{{- $enabled := dig "registry" "enabled" false .Values.global -}}
```

#### Use `index` for dynamic keys, or naming conventions incompatible with Go

Use [`index`](https://helm.sh/docs/chart_template_guide/function_list/#index) for dynamic keys or Go-incompatible naming like `kebab-case`:

```yaml
{{- $image := index .Values "shared-secrets" "selfsign" "image" -}}
```

#### Use parentheses for simple safe navigation

Parentheses syntax works well for straightforward cases where you need basic safe navigation:

```yaml
{{- $host := (((.Values.database).connection).host) -}}
{{- $port := (((.Values.database).connection).port) -}}
```

But note that if you already know for other means that, for instance, `.Values.database` is present, you can simplify
the safe navitation with `(.Values.database.connection).port`.

#### Avoid direct nested access without safety checks

Direct access should only be used when you can guarantee the full path exists:

```yaml
{{/* ❌ Unsafe - will fail if intermediate objects are null */}}
{{- if .Values.database.connection.host -}}
```

### When to utilize `toYaml` in templates

It is frowned upon to default to utilizing a `toYaml` in the template files as
this will put undue burden on supporting all functionalities of both Kubernetes
and desired community configurations. We primary focus on providing a
reasonable default using the bare minimum configuration. Our secondary focus
would be to provide the ability to override the defaults for more advanced users
of Kubernetes. This should be done on a case-by-case basis as there are
certainly scenarios where either option may be too cumbersome to support, or
provides an unnecessarily complex template to maintain.

An good example of a reasonable default with the ability to override can be
found in the Horizontal Pod Autoscaler configuration for the registry subchart.
We default to providing the bare minimum that can easily be supported, by
exposing a specific configuration of controlling the HPA via the CPU Utilization
and exposing only one configuration option to the community, the
`targetAverageUtilization`. Being that an HPA can provide much more
flexibility, more advanced users may want to target different metrics and as
such, is a perfect example of where we can utilize and if statement allowing the
end user to provide a more complex HPA configuration in place.

```yaml
  metrics:
  {{- if not .Values.hpa.customMetrics }}
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          targetAverageUtilization: {{ .Values.hpa.cpu.targetAverageUtilization }}
  {{- else -}}
    {{- toYaml .Values.hpa.customMetrics | nindent 4 -}}
  {{- end -}}
```

In the above example, the minimum configuration will be a simple change in the
`values.yaml` to update the `targetAverageUtilization`.

Advanced users who have identified a better metric can override this overly
simplistic HPA configuration by setting `.customMetrics` to an array containing
precisely the Kubernetes API compatible configuration for the HPA metrics array.

It is important that we maintain ease of use for the more advanced users to
minimize their own configuration files without it being cumbersome.

## Developing template helpers

A charts template helpers are located in `templates/_helpers.tpl`. These contain the [named templates](https://helm.sh/docs/chart_template_guide/named_templates/)
used within the chart.
When these template files grow large, which they often do, they should be broken down into multiple files under `templates/_xyz.tpl`. This convention
facilitates clarity and maintainability.

When using these templates, there a few things to keep in mind regarding the [Go templating syntax](https://pkg.go.dev/text/template).

You can find common, product-wide templates within the [common-templates](https://gitlab.com/gitlab-org/cloud-native/charts/common-templates) library chart.

### Trapping non-printed values from actions

In the go templating syntax, all actions (indicated by `{{  }}`) are expected
to print a string, with the exception of control structures (define, if, with, range) and variable assignment.

This means you will sometimes need to use variable assignment to trap output that is not meant to be printed.

For example:

```plaintext
{{- $details := .Values.details -}}
{{- $_ := set $details "serviceName" "example" -}}
{{ template "serviceHost" $details }}
```

In the above example, we want to add some additional data to a Map before passing it to a template function for output.
We trapped the output of the `set` function by assigning it to the `$_` variable. Without this assignment, the
template would try to output the result of `set` (which returns the Map it modified) as a string.

### Passing variables between control structures

The go templating syntax [strongly differentiates between initialization (`:=`) and assignment (`=`)](https://pkg.go.dev/text/template#hdr-Variables), and this is impacted by scope.

As a result you can re-initialize a variable that existed outside your control structure (if/with/range), but know that
variables declared within your control structure are not available outside.

For example:

```plaintext
{{- define "exampleTemplate" -}}
{{- $someVar := "default" -}}
{{- if true -}}
{{-   $someVar := "desired" -}}
{{- end -}}
{{- $someVar -}}
{{- end -}}
```

In the above example, calling `exampleTemplate` will always return `default` because the variable that contained `desired` was
only accessible within the `if` control structure.

To work around this issue, we attempt to avoid the problem by using a Dictionary to hold the values we want to change in multiple scopes,
or explicitly use the _assignment operator_ (`=` vs `:=`).

Example of avoiding the issue:

```plaintext
{{- define "exampleTemplate" -}}
{{- if true -}}
{{-   "desired" -}}
{{- else -}}
{{-   "default" -}}
{{- end -}}
```

Example of using a Dictionary:

```plaintext
{{- define "exampleTemplate" -}}
{{- $result := dict "value" "default" -}}
{{- if true -}}
{{-   $_ := set $result "value" "desired" -}}
{{- end -}}
{{- $result.value -}}
{{- end -}}
```

Example of assignment versus initialization (look close!)

```plaintext
{{- define "exampleTemplate" -}}
{{- $someVar := "default" -}}
{{- if true -}}
{{-   $someVar = "desired" -}}
{{- end -}}
{{- $someVar -}}
{{- end -}}
```

Example of using a template:

```plaintext
{{- define "exampleTemplate" -}}
foo:
  bar:
   baz: bat
{{- end -}}
```

And then pulling the above into a variable and configuration:

```plaintext
{{- $fooVar := include "exampleTemplate" . | fromYaml -}}
{{- $barVar := merge $.Values.global.some.config $fooVar -}}
config:
{{ $barVar }}
```

## Templating Configuration Files

These charts make use of cloud-native GitLab containers.
Those containers support the use of either [ERB](https://docs.ruby-lang.org/en/2.7.0/ERB.html)
or [gomplate](https://docs.gomplate.ca/).

**Guidelines**:

1. Use template files within ConfigMaps (example: `gitlab.yml.erb`, `config.toml.tpl`)
   - Entries _must_ use the expected extensions in order to be handled as templates.
1. Use templates to populate Secret contents from mounted file locations. (example: [GitLab Pages `config`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/gitlab-pages/templates/configmap.yml))
1. ERB (`.erb`) can be used for any container using Ruby during run-time execution
1. gomplate (`.tpl`) can be used for any container.

**ERB usage**:

We make use of standard ERB, and you can expect [`json`](https://docs.ruby-lang.org/en/2.7.0/JSON.html) and [`yaml`](https://docs.ruby-lang.org/en/2.7.0/YAML.html) modules to have been pre-loaded.

**gomplate usage**:

We make use of gomplate in order to remove the size and surface of Ruby within
containers. We configure gomplate [syntax](https://docs.gomplate.ca/syntax/) with alternate delimiters of `{% %}`, so not
to collide with Helm's use of `{{ }}`.

### Templating sensitive content

Secrets have the potential contain characters that could result invalid YAML if
not properly encoded or quoted. Especially for complex passwords, we must be
careful how these strings are added into various configuration formats.

**Guidelines**:

1. Quote in the ERB / Gomplate output, _not_ surrounding it.
1. Use a format-native encoder whenever possible.
   - For rendered YAML, use JSON strings because YAML is a superset of JSON.
   - For rendered TOML, use JSON strings because [TOML strings](https://toml.io/en/v0.3.0#string) escape similarly.
1. Be wary of complexity, such as quoted strings _inside_ quoted stings such
   as database connection strings.

#### Example of encoding passwords

Using Gitaly's client secret token as an example. This value is, `gitaly_token`,
is templated into both YAML and TOML.

Let's use `my"$pec!@l"p#assword%'` as an example:

```erb
# YAML
gitaly:
  token: "<%= File.read('gitaly_token').strip =>"

# TOML
[auth]
token = "<%= File.read('gitaly_token').strip %>"
```

Renders to be invalid YAML, and invalid TOML.

```yaml
# YAML
gitaly:
  token: "my"$pec!@l"p#assword%'"
```

> `(<unknown>): did not find expected key while parsing a block mapping at line 3 column 3`

```toml
[auth]
token = "my"$pec!@l"p#assword%'"
```

> `Error on line 2: Expected Comment, Newline, Whitespace, or end of input but "$" found.`

This changed to `<%= File.read('gitaly_token').strip.to_json %>` results valid
content format for YAML and TOML. Note the removal of `"` from outside of `<% %>`.

```yaml
gitaly:
  token: "my\"$pec!@l\"p#assword%'"
```

This same can be done with gomplate: `{% file.Read "gitaly_token" | strings.TrimSpace | data.ToJSON %}`

```yaml
gitaly:
  # gomplate
  token: {% file.Read "./token" | strings.TrimSpace | data.ToJSON %}
  # ERB
  token: <%= File.read('gitaly_token').strip.to_json %>
```

## Adding new GitLab YAML configurations

When adding new GitLab Rails configurations to the chart, evaluate which components require the configuration on a case-by-case basis.

### Components to consider

The following components initialize Rails and may need new configurations:

- **webservice** - The primary Rails application server
- **toolbox** - Utility pod for administrative tasks and backups
- **Sidekiq** - Background job processor
- **Geo** - Geo-specific secondary site configuration
- **migrations** - Database migration jobs

Whether a given configuration should be included in each component depends on its specific purpose and requirements. Evaluate each component individually — not every configuration needs to be present in all of them.

### Implementation approach

When adding a new configuration:

1. Add the configuration to the appropriate shared template file in `charts/gitlab/templates/`:
   - Use `_gitlab.yaml.tpl` for general GitLab YAML configurations
   - Use feature-specific files like `_sidekiq.tpl`, `_geo.tpl`, etc. if the configuration is specific to that feature
   - Create a new `_featurename.tpl` file if no suitable template exists
1. Include the template in each ConfigMap where it is needed using `{{ include "gitlab.appConfig.featurename" . | nindent 6 }}`
1. Document in the merge request why the configuration is or is not needed in each component

## Templating chart notes (NOTES.txt)

Helm's [chart notes feature](https://helm.sh/docs/chart_template_guide/notes_files/) provides
helpful information and follow-up instructions after chart installations and upgrades.

These notes are placed in
[templates/NOTES.txt](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/templates/NOTES.txt).

When working with these notes, there are a few things to keep in mind regarding style to ensure
that the output is legible and actionable.

### Choosing a note category

Two categories, `WARNING` and `NOTICE`, signify each type of entry in the note output.

- `WARNING` signifies that further action is required to optimize the installation
- `NOTICE` highlights important reminders that do not necessarily require further action

Each entry in `NOTES.txt` should start with one of these two categories. For example:

```go
{{- if eq true .Values.some.setting }}
{{ $WARNING }}
This message is a warning.
{{- end }}

{{- if eq true .Values.some.other.setting }}
{{ $NOTICE }}
This message is a notice.
{{- end }}
```

These examples use one of two predefined variables included at the top of the `NOTES.txt`
file that ensure consistent titles and spacing between each entry in the output.
