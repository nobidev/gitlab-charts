{{- define "gitlab.appConfig.mobile_push.configuration" -}}
{{- if .Values.global.appConfig.mobile_push.apns.auth_key.secret }}
mobile_push:
  apns:
    auth_key_path: /etc/gitlab/mobile_push/apns_auth_key.p8
    key_id: {{ .Values.global.appConfig.mobile_push.apns.key_id | quote }}
    team_id: {{ .Values.global.appConfig.mobile_push.apns.team_id | quote }}
{{-   if .Values.global.appConfig.mobile_push.apns.topic }}
    topic: {{ .Values.global.appConfig.mobile_push.apns.topic | quote }}
{{-   end }}
{{- end }}
{{- end -}}{{/* "gitlab.appConfig.mobile_push.configuration" */}}

{{- define "gitlab.appConfig.mobile_push.volume" -}}
{{- if .Values.global.appConfig.mobile_push.apns.auth_key.secret }}
# volume for mobile push APNs auth key
- name: mobile-push-apns-auth-key
  secret:
    secretName: {{ .Values.global.appConfig.mobile_push.apns.auth_key.secret }}
{{- end -}}
{{- end -}}{{/* "gitlab.appConfig.mobile_push.volume" */}}

{{- define "gitlab.appConfig.mobile_push.volumeMount" -}}
{{- if .Values.global.appConfig.mobile_push.apns.auth_key.secret }}
# volume mount for mobile push APNs auth key
- mountPath: "/etc/gitlab/mobile_push/apns_auth_key.p8"
  subPath: {{ .Values.global.appConfig.mobile_push.apns.auth_key.key }}
  name: mobile-push-apns-auth-key
  readOnly: true
{{- end -}}
{{- end -}}{{/* "gitlab.appConfig.mobile_push.volumeMount" */}}
