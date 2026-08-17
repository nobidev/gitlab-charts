{{/*
Ensure that the mobile push APNs settings are complete when an auth key is provided
*/}}
{{- define "gitlab.checkConfig.mobilePush.apns" -}}
{{- with $.Values.global.appConfig.mobilePush.apns }}
{{-   if .authKey.secret }}
{{-     if not .keyId }}
mobilePush:
    When configuring mobile push APNs, be sure to specify the key ID of the APNs
    auth key (`global.appConfig.mobilePush.apns.keyId`).
    See https://docs.gitlab.com/charts/charts/globals#mobile-push-notification-settings
{{-     end -}}
{{-     if not .teamId }}
mobilePush:
    When configuring mobile push APNs, be sure to specify the Apple team ID that
    owns the APNs auth key (`global.appConfig.mobilePush.apns.teamId`).
    See https://docs.gitlab.com/charts/charts/globals#mobile-push-notification-settings
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.mobilePush.apns */}}
