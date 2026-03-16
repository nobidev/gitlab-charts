{{/* ######### iam-auth related templates */}}

{{/*
Return the iam-auth service token secret
*/}}

{{- define "gitlab.iamAuth.secret" -}}
{{- default (printf "%s-iam-auth-secret" .Release.Name) .Values.global.appConfig.iam_auth_service.secret | quote -}}
{{- end -}}

{{- define "gitlab.iamAuth.key" -}}
{{- default "iam_auth_service_token" .Values.global.appConfig.iam_auth_service.key | quote -}}
{{- end -}}

{{/*
Mount secret for iam-auth service token
*/}}
{{- define "gitlab.iamAuth.mountSecrets" -}}
{{- if .Values.global.appConfig.iam_auth_service.enabled -}}
# mount secret for iam-auth service token
- secret:
    name: {{ template "gitlab.iamAuth.secret" . }}
    items:
      - key: {{ template "gitlab.iamAuth.key" . }}
        path: iam-auth/.gitlab_iam_auth_secret
{{- end -}}
{{- end -}}{{/* "gitlab.iamAuth.mountSecrets" */}}

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
