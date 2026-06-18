{{/*
Ensures that grpc.host is configured when iamDataAccessService grpc is partially set
(e.g. a port without a host). The service is optional: a fully-unset grpc is valid.
*/}}
{{- define "gitlab.checkConfig.iamDataAccessService.grpc.host" -}}
  {{- with .Values.global.appConfig.iamDataAccessService -}}
    {{- if dig "grpc" "port" 0 . -}}
      {{- if not (dig "grpc" "host" "" .) }}
iamDataAccessService:
    grpc.host is required when iamDataAccessService grpc is configured. Please set `global.appConfig.iamDataAccessService.grpc.host`.
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.iamDataAccessService.grpc.host */}}

{{/*
Ensures that grpc.port is configured when iamDataAccessService grpc is configured
(i.e. a host is set). The service is optional: a fully-unset grpc is valid.
*/}}
{{- define "gitlab.checkConfig.iamDataAccessService.grpc.port" -}}
  {{- with .Values.global.appConfig.iamDataAccessService -}}
    {{- if dig "grpc" "host" "" . -}}
      {{- if not (dig "grpc" "port" 0 .) }}
iamDataAccessService:
    grpc.port is required when iamDataAccessService grpc is configured. Please set `global.appConfig.iamDataAccessService.grpc.port`.
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.iamDataAccessService.grpc.port */}}
