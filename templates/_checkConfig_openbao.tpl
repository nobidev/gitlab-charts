{{/*
Ensure a database is configured when OpenBao is installed.

When using bundled PostgreSQL (postgresql.install true), the chart uses the bundled
service when host is empty. When using external PostgreSQL, the database must be
configured explicitly via openbao.config.storage.postgresql.connection.
*/}}
{{- define "gitlab.checkConfig.openbao.database" -}}
{{- $openbao := .Values.openbao | default dict -}}
{{- if eq true ($openbao.install | default false) -}}
{{- $psql := .Values.postgresql | default dict -}}
{{- if eq $psql.install false -}}
{{- $conn := index (index (index (index $openbao "config" | default dict) "storage" | default dict) "postgresql" | default dict) "connection" | default dict -}}
{{- $host := index $conn "host" | default "" -}}
{{- if eq (printf "%s" $host) "" }}
openbao: no database configured
    It appears OpenBao is enabled but no database was configured. When using external PostgreSQL, configure `openbao.config.storage.postgresql.connection` with host, database, username, and password. See https://docs.gitlab.com/charts/charts/openbao/#database-configuration
{{- end -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.openbao.database */}}
