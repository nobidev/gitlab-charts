{{/* ######### iam-auth related templates */}}

{{/*
Return the iam-auth service token secret
*/}}

{{- define "gitlab.iam-auth.secret" -}}
{{- default (printf "%s-iam-auth-secret" .Release.Name) .Values.global.appConfig.iam_auth_service.secret | quote -}}
{{- end -}}

{{- define "gitlab.iam-auth.key" -}}
{{- default "iam_auth_service_token" .Values.global.appConfig.iam_auth_service.key | quote -}}
{{- end -}}

{{/*
Mount secret for iam-auth service token
*/}}
{{- define "gitlab.iam-auth.mountSecrets" -}}
{{- if .Values.global.appConfig.iam_auth_service.enabled -}}
# mount secret for iam-auth service token
- secret:
    name: {{ template "gitlab.iam-auth.secret" . }}
    items:
      - key: {{ template "gitlab.iam-auth.key" . }}
        path: iam-auth/.gitlab_iam_auth_secret
{{- end -}}
{{- end -}}{{/* "gitlab.iam-auth.mountSecrets" */}}

{{/*
Configuration for iam-auth service in gitlab.yml
*/}}
{{- define "gitlab.appConfig.iam_auth_service" -}}
{{- if .Values.global.appConfig.iam_auth_service.enabled -}}
iam_auth_service:
  enabled: true
  secret_file: /etc/gitlab/iam-auth/.gitlab_iam_auth_secret
{{- end -}}
{{- end -}}
