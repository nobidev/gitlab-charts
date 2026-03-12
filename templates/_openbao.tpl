{{/*
Returns the hostname.
If the hostname is set in `global.hosts.openbao.name`, that will be returned,
otherwise the hostname will be assembled using `openbao` as the prefix, and the `gitlab.assembleHost` function.
*/}}
{{- define "gitlab.openbao.hostname" -}}
{{- coalesce .Values.global.openbao.host .Values.global.hosts.openbao.name (include "gitlab.assembleHost"  (dict "name" "openbao" "context" . )) -}}
{{- end -}}

{{/*
Returns the OpenBao Url, ex: `http://openbao.example.com`

Populated from one of:
- Direct setting of URL
- Populated by  "gitlab.openbao.hostname", plus `https` boolean
*/}}
{{- define "gitlab.openbao.url" -}}
{{- if $.Values.global.openbao.url -}}
{{-   $.Values.global.openbao.url -}}
{{- else if or .Values.global.openbao.https .Values.global.hosts.https .Values.global.hosts.openbao.https -}}
{{-   printf "https://%s" (include "gitlab.openbao.hostname" .) -}}
{{- else -}}
{{-   printf "http://%s" (include "gitlab.openbao.hostname" .) -}}
{{- end -}}
{{- end -}}

{{/*
Returns the OpenBao internal hostname.
If the hostname is set in `global.openbao.internal_host`, that will be returned,
otherwise falls back to the regular hostname.
*/}}
{{- define "gitlab.openbao.internal_hostname" -}}
{{- coalesce .Values.global.openbao.internal_host (include "gitlab.openbao.hostname" .) -}}
{{- end -}}

{{/*
Returns the OpenBao internal URL, ex: `https://openbao.internal.net`

Populated from one of:
- Direct setting of internal_url
- Populated by "gitlab.openbao.internal_hostname", plus `https` boolean
- Empty if neither internal_url nor internal_host are set
*/}}
{{- define "gitlab.openbao.internal_url" -}}
{{- if $.Values.global.openbao.internal_url -}}
{{-   $.Values.global.openbao.internal_url -}}
{{- else if $.Values.global.openbao.internal_host -}}
{{-   if has true (list .Values.global.openbao.https .Values.global.hosts.https .Values.global.hosts.openbao.https) -}}
{{-    printf "https://%s" .Values.global.openbao.internal_host -}}
{{-   else -}}
{{-    printf "http://%s" .Values.global.openbao.internal_host -}}
{{-   end -}}
{{- end -}}
{{- end -}}

{{/*
Returns the OpenBao JWT audience for Geo deployments.

When secondary Geo sites use different URLs to reach OpenBao, the JWT audience claim
must match OpenBao's bound_audiences. Set this to the shared audience value (e.g.
the primary site's OpenBao URL) when url differs per site.

OpenBao uses a separate
logical database for isolation from the Rails main database. This avoids
database seeding issues when OpenBao is enabled during fresh installation.

Populated from:
- Direct setting of global.openbao.jwt_audience
- Empty when not set (GitLab defaults to url)
*/}}
{{- define "gitlab.openbao.jwt_audience" -}}
{{- $.Values.global.openbao.jwt_audience | default "" -}}
{{- end -}}
{{- define "gitlab.openbao.database" -}}
{{- $values := .Values | mustToJson | fromJson -}}
{{- $oba := index $values "openbao" | default dict -}}
{{- $psql := index $oba "psql" | default dict -}}
{{- $globalOba := index (index $values "global" | default dict) "openbao" | default dict -}}
{{- $globalPsql := index $globalOba "psql" | default dict -}}
{{- $conn := index (index (index (index $values "config" | default dict) "storage" | default dict) "postgresql" | default dict) "connection" | default dict -}}
{{/* connection.database wins when set; else openbao.psql, global.openbao.psql, default */}}
{{- coalesce (index $conn "database") (index $psql "database") (index (index $values "psql" | default dict) "database") (index $globalPsql "database") "openbao" -}}
{{- end -}}

{{/*
Render the OpenBao postgresql configuration yaml.

* Uses global.openbao.psql and openbao.config.storage.postgresql.connection.
* global.openbao.psql is the preferred source so toolbox can access it for backup/restore.
* When host is empty and bundled PostgreSQL is used, defaults to the postgresql service.
*/}}
{{- define "openbao.postgresql.configuration" -}}
{{- $globalPsql := index (.Values.global | default dict) "psql" | default dict -}}
{{- $globalObaPsql := index (index (.Values.global | default dict) "openbao" | default dict) "psql" | default dict -}}
{{- $obaPsql := .Values.psql | default dict -}}
{{- $conn := (((.Values.config).storage).postgresql).connection | default dict | deepCopy -}}
{{- $connection := merge $globalPsql $globalObaPsql $obaPsql $conn -}}
{{- range $k, $v := $conn -}}
{{-   if and (ne (printf "%v" $v) "") (has $k (list "keepalives" "keepalivesIdle" "keepalivesInterval" "keepalivesCount" "tcpUserTimeout" "connectTimeout" "sslMode")) -}}
{{-     $_ := set $connection $k $v -}}
{{-   end -}}
{{- end -}}
{{- $host := index $connection "host" | default "" -}}
{{- if eq (printf "%s" $host) "" -}}
{{-   $globalOba := index (index (.Values.global | default dict) "openbao" | default dict) -}}
{{-   $share := true -}}
{{-   if hasKey .Values "sharePostgresqlServer" -}}
{{-     $share = index .Values "sharePostgresqlServer" -}}
{{-   else if hasKey $globalOba "sharePostgresqlServer" -}}
{{-     $share = index $globalOba "sharePostgresqlServer" -}}
{{-   end -}}
{{-   if $share -}}
{{-     $_ := set $connection "host" (printf "%s-postgresql.%s.svc" .Release.Name .Release.Namespace) -}}
{{-     $_ := set $connection "username" "gitlab" -}}
{{-   end -}}
{{- end -}}
{{- if not (index $connection "port") -}}
{{-   $_ := set $connection "port" 5432 -}}
{{- end -}}
{{/* Database: connection.database wins when set; else gitlab.openbao.database (openbao.psql, global.openbao.psql, etc.) */}}
{{- $_ := set $connection "database" (include "gitlab.openbao.database" .) -}}
{{- if not (index $connection "username") -}}
{{-   $_ := set $connection "username" "openbao" -}}
{{- end -}}
{{- if not (index $connection "password") -}}
{{-   include "database.datamodel.prepare" $ -}}
{{-   $psqlSecret := dict "secret" (include "gitlab.psql.password.secret" $.Values.local.psql.main) "key" (include "gitlab.psql.password.key" $.Values.local.psql.main) -}}
{{-   $_ := set $connection "password" $psqlSecret -}}
{{- end -}}
{{ $connection | toYaml }}
{{- end -}}

{{- define "gitlab.openbao.configureCertmanager" -}}
{{ pluck "configureCertmanager" .Values.ingress .Values.global.ingress (dict "configureCertmanager" false) | first }}
{{- end }}

{{- define "gitlab.openbao.unseal.secret" -}}
{{- printf "%s-openbao-unseal" .Release.Name -}}
{{- end -}}

{{- define "gitlab.openbao.unseal.key" -}}
key
{{- end -}}

{{- define "gitlab.openbao.authenticationTokenSecretFilePath.secret" -}}
{{- .Values.global.openbao.httpAudit.secret | default (printf "%s-openbao-audit-secret" .Release.Name) -}}
{{- end -}}

{{- define "gitlab.openbao.authenticationTokenSecretFilePath.key" -}}
{{- .Values.global.openbao.httpAudit.key }}
{{- end -}}
