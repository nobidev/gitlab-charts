{{/* ######### iam-auth service related templates */}}

{{/*
Return the iam-auth service token secret
*/}}

{{- define "gitlab.iamAuthService.authToken.secret" -}}
{{- default (printf "%s-iam-auth-secret" .Release.Name) .Values.global.appConfig.iamAuthService.secret | quote -}}
{{- end -}}

{{- define "gitlab.iamAuthService.authToken.key" -}}
{{- default "iam_auth_service_token" .Values.global.appConfig.iamAuthService.key | quote -}}
{{- end -}}

{{/*
Mount secret for iam-auth service token
*/}}
{{- define "gitlab.iamAuthService.mountSecrets" -}}
{{- if .Values.global.appConfig.iamAuthService.enabled -}}
# mount secret for iam-auth service token
- secret:
    name: {{ template "gitlab.iamAuthService.authToken.secret" . }}
    items:
      - key: {{ template "gitlab.iamAuthService.authToken.key" . }}
        path: iam-auth/.gitlab_iam_auth_secret
{{- end -}}
{{- end -}}
