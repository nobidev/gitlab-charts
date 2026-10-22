{{/*
Check if any Gateway API extension uses the deprecated global configuration.
*/}}
{{- define "gitlab.checkConfig.gatewayApi.envoy.global" -}}
{{- $keys := list "envoyProxySpec" "envoyClientTrafficPolicySpec" "envoySecurityPolicySpec" "class" "protocol" "addresses" "listeners" "gateway" "metrics" }}
{{- range $keys }}
{{-   if hasKey $.Values.global.gatewayApi . }}
Gateway API:
  The global.gatewayApi.{{ . }} settings moved away from global configuration. Please check
  https://docs.gitlab.com/charts/charts/envoygateway/ and https://docs.gitlab.com/charts/charts/globals/#gateway-api
  to migrate.
{{-   end }}
{{- end }}
{{- end -}}

{{/*
Check settings that contradict TLS terminated upstream of the Gateway.
*/}}
{{- define "gitlab.checkConfig.gatewayApi.tlsTerminatedUpstream" -}}
{{- if eq "true" (include "gitlab.gatewayApi.tlsTerminatedUpstream" .) }}
{{-   if not .Values.global.hosts.https }}
Gateway API:
  global.gatewayApi.tlsTerminatedUpstream requires global.hosts.https to be true, so that
  GitLab generates HTTPS URLs for the load balancer that terminates TLS.
{{-   end }}
{{-   if .Values.global.appConfig.smartcard.enabled }}
Gateway API:
  Smartcard authentication is not supported with global.gatewayApi.tlsTerminatedUpstream:
  the Gateway must terminate TLS to verify client certificates.
{{-   end }}
{{-   range $name, $listener := .Values.gatewayApiResources.gateway.listeners }}
{{-     if has (upper (default "" $listener.protocol)) (list "HTTPS" "TLS") }}
Gateway API:
  The gatewayApiResources.gateway.listeners.{{ $name }}.protocol setting must not be HTTPS or TLS
  with global.gatewayApi.tlsTerminatedUpstream, because the load balancer terminates TLS.
{{-     end }}
{{-   end }}
{{- end }}
{{- end -}}