{{/*
Ensure that the mobile push APNs settings are complete when any of them is provided
*/}}
{{- define "gitlab.checkConfig.mobilePush.apns" -}}
{{- with $.Values.global.appConfig.mobilePush.apns }}
{{-   if or .authKey.secret .keyId .teamId .topic }}
{{-     if not .authKey.secret }}
mobilePush:
    When configuring mobile push APNs, be sure to provide the Kubernetes secret
    containing the APNs auth key (`global.appConfig.mobilePush.apns.authKey.secret`).
    See https://docs.gitlab.com/charts/charts/globals#mobile-push-notification-settings
{{-     end -}}
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
