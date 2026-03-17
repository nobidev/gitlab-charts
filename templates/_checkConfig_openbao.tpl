{{/*
Ensure a database is configured when OpenBao is installed.

The database must be configured explicitly via global.openbao.psql or
openbao.config.storage.postgresql.connection with host, database, username, and password.
Password is required and is not inherited from the main DB.
*/}}
{{- define "gitlab.checkConfig.openbao.database" -}}
{{- $openbao := .Values.openbao | default dict -}}
{{- if eq true ($openbao.install | default false) -}}
{{- $conn := ((($openbao.config).storage).postgresql).connection | default dict -}}
{{- $globalObaPsql := ((.Values.global).openbao).psql | default dict -}}
{{- $host := coalesce $conn.host $globalObaPsql.host "" -}}
{{- $password := coalesce $conn.password $globalObaPsql.password (dict) -}}
{{- $hasPassword := or (hasKey $password "secret") (hasKey $password "file") -}}
{{- if not $host }}
openbao: no database configured
    It appears OpenBao is enabled but no database was configured. Configure `global.openbao.psql` with host, database, username, and password. See https://docs.gitlab.com/charts/charts/openbao/#database-configuration
{{- end }}
{{- if not $hasPassword }}
openbao: no database password configured
    OpenBao requires an explicit database password. Configure `global.openbao.psql.password` with secret/key or file. Password is not inherited from the main DB. See https://docs.gitlab.com/charts/charts/openbao/#database-configuration
{{- end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.openbao.database */}}
