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
Ensure no chart-rendered section-scoped ClientTrafficPolicy targets an HTTP listener that shares
its port with other HTTP listeners. Envoy Gateway rejects such a policy, so its settings never apply.
The rejected policy still overrides the gateway-wide policy (gatewayApiResources.envoy.clientTrafficPolicySpec)
on its listener, and because the listeners share one HTTP connection manager, the gateway-wide policy
then does not apply to the port at all when that listener is the first one on it. This happens with gatewayApiResources.gateway.protocol HTTP while
global.hosts.https is true, for example when TLS is terminated upstream of the Gateway.
*/}}
{{- define "gitlab.checkConfig.gatewayApi.envoy.sectionPolicies" -}}
{{- if eq "true" (include "gitlab.gatewayApi.envoy.installPolicies" .) -}}
{{-   $gateway := include (print $.Template.BasePath "/gateway.yaml") . | fromYaml -}}
{{-   $listeners := dict -}}
{{-   $httpListenersPerPort := dict -}}
{{-   range (dig "spec" "listeners" list $gateway) -}}
{{-     $_ := set $listeners .name . -}}
{{-     if eq .protocol "HTTP" -}}
{{-       $port := toString .port -}}
{{-       $_ := set $httpListenersPerPort $port (add1 (get $httpListenersPerPort $port | default 0)) -}}
{{-     end -}}
{{-   end -}}
{{-   $policies := list -}}
{{-   $webservice := .Values.gitlab.webservice -}}
{{-   if $webservice.enabled -}}
{{-     if and (or .Values.global.hosts.https .Values.global.hosts.gitlab.https) $webservice.clientTrafficPolicy.main.spec -}}
{{-       $policies = append $policies (dict "listener" $webservice.gatewayRoute.sectionName "key" "gitlab.webservice.clientTrafficPolicy.main.spec") -}}
{{-     end -}}
{{-     if and (eq "true" (include "gitlab.gatewayApi.gateway.geo.configure" .)) $webservice.clientTrafficPolicy.geo.spec -}}
{{-       $policies = append $policies (dict "listener" $webservice.gatewayRoute.geoSectionName "key" "gitlab.webservice.clientTrafficPolicy.geo.spec") -}}
{{-     end -}}
{{-   end -}}
{{-   $kas := .Values.gitlab.kas -}}
{{-   $kasRoute := ternary .Values.global.gatewayApi.enabled $kas.gatewayRoute.enabled (kindIs "invalid" $kas.gatewayRoute.enabled) -}}
{{-   if and .Values.global.kas.enabled $kasRoute (or .Values.global.hosts.https .Values.global.hosts.kas.https) $kas.clientTrafficPolicy.spec -}}
{{-     $policies = append $policies (dict "listener" $kas.gatewayRoute.sectionName "key" "gitlab.kas.clientTrafficPolicy.spec") -}}
{{-   end -}}
{{-   range $policies -}}
{{-     $listener := get $listeners .listener -}}
{{-     if and $listener (eq $listener.protocol "HTTP") (gt (int (get $httpListenersPerPort (toString $listener.port))) 1) }}
Gateway API:
  The section-scoped ClientTrafficPolicy from `{{ .key }}` targets the `{{ .listener }}`
  listener, which uses HTTP on a port shared with other HTTP listeners. Envoy Gateway rejects
  this policy, and the rejected policy can also stop `gatewayApiResources.envoy.clientTrafficPolicySpec`
  from applying, so escaped slashes and trailing dots in the Host header might not be handled.
  Set `{{ .key }}: null` and configure the gateway-wide policy instead, or use HTTPS for the
  listener. See https://docs.gitlab.com/charts/advanced/gateway-api/#http-only-mode
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- end -}}
