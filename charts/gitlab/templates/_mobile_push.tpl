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

{{- define "gitlab.appConfig.mobilePush.volume" -}}
{{- if .Values.global.appConfig.mobilePush.apns.authKey.secret }}
# volume for mobile push APNs auth key
- name: mobile-push-apns-auth-key
  secret:
    secretName: {{ .Values.global.appConfig.mobilePush.apns.authKey.secret }}
{{- end -}}
{{- end -}}{{/* "gitlab.appConfig.mobilePush.volume" */}}

{{- define "gitlab.appConfig.mobilePush.volumeMount" -}}
{{- if .Values.global.appConfig.mobilePush.apns.authKey.secret }}
# volume mount for mobile push APNs auth key
- mountPath: "/etc/gitlab/mobile_push/apns_auth_key.p8"
  subPath: {{ .Values.global.appConfig.mobilePush.apns.authKey.key }}
  name: mobile-push-apns-auth-key
  readOnly: true
{{- end -}}
{{- end -}}{{/* "gitlab.appConfig.mobilePush.volumeMount" */}}
