{{- define "gitlab.appConfig.mobilePush.configuration" -}}
{{- if .Values.global.appConfig.mobilePush.apns.authKey.secret }}
mobile_push:
  apns:
    auth_key_path: /etc/gitlab/mobile_push/apns_auth_key.p8
    key_id: {{ .Values.global.appConfig.mobilePush.apns.keyId | quote }}
    team_id: {{ .Values.global.appConfig.mobilePush.apns.teamId | quote }}
{{-   if .Values.global.appConfig.mobilePush.apns.topic }}
    topic: {{ .Values.global.appConfig.mobilePush.apns.topic | quote }}
{{-   end }}
{{- end }}
{{- end -}}{{/* "gitlab.appConfig.mobilePush.configuration" */}}

{{- define "gitlab.appConfig.mobilePush.mountSecrets" -}}
{{- if .Values.global.appConfig.mobilePush.apns.authKey.secret }}
# mount secret for mobile push APNs auth key
- secret:
    name: {{ .Values.global.appConfig.mobilePush.apns.authKey.secret }}
    items:
      - key: {{ .Values.global.appConfig.mobilePush.apns.authKey.key }}
        path: mobile_push/apns_auth_key.p8
{{- end -}}
{{- end -}}{{/* "gitlab.appConfig.mobilePush.mountSecrets" */}}
