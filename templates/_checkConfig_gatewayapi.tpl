{{/*
Check that internalGateway.enabled requires installEnvoy to be true.
*/}}
{{- define "gitlab.checkConfig.gatewayApi.internal.requireInstallEnvoy" -}}
{{- if and .Values.global.gatewayApi.internalGateway (not .Values.global.gatewayApi.installEnvoy) }}
Gateway API (internalGateway):
  gatewayApiResources.internalGateway.enabled requires global.gatewayApi.installEnvoy: true.
  The internal Gateway needs its own managed Envoy data plane.
{{- end }}
{{- end -}}

{{/*
Check that internalGateway.enabled has cloud-provider annotations configured to prevent
accidental creation of a public load balancer.
*/}}
{{- define "gitlab.checkConfig.gatewayApi.internal.requireAnnotations" -}}
{{- if .Values.global.gatewayApi.internalGateway }}
{{-   $kubernetes := (((.Values.gatewayApiResources.internalGateway.envoy.proxySpec).provider).kubernetes) | default dict }}
{{-   $svcAnnotations := (($kubernetes.envoyService).annotations) | default dict }}
{{-   if empty $svcAnnotations }}
Gateway API (internalGateway):
  gatewayApiResources.internalGateway.enabled requires cloud-provider annotations to be set at
  gatewayApiResources.internalGateway.envoy.proxySpec.provider.kubernetes.envoyService.annotations
  to prevent accidental creation of a public load balancer. Example for AWS:
    service.beta.kubernetes.io/aws-load-balancer-internal: "true"
{{-   end }}
{{- end }}
{{- end -}}

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