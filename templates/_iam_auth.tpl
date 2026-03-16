{{/* ######### iam-auth related templates */}}

{{/*
Return the iam-auth service token secret
*/}}

{{- define "gitlab.iamAuth.secret" -}}
{{- default (printf "%s-iam-auth-secret" .Release.Name) .Values.global.appConfig.iamAuthService.secret | quote -}}
{{- end -}}

{{- define "gitlab.iamAuth.key" -}}
{{- default "iamAuthService_token" .Values.global.appConfig.iamAuthService.key | quote -}}
{{- end -}}

{{/*
Mount secret for iam-auth service token
*/}}
{{- define "gitlab.iamAuth.mountSecrets" -}}
{{- if .Values.global.appConfig.iamAuthService.enabled -}}
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
{{- define "gitlab.appConfig.iamAuthService" -}}
{{- if .Values.global.appConfig.iamAuthService.enabled -}}
iamAuthService:
  enabled: true
  secret_file: /etc/gitlab/iam-auth/.gitlab_iam_auth_secret
{{- end -}}
{{- end -}}
