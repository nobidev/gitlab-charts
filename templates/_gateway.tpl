{{/*
Returns name of the Gateway class. Consumed by chart managed Gateway and GatewayClass.
*/}}
{{- define "gitlab.gatewayApi.class.name" -}}
{{- .Values.gatewayApiResources.class.name -}}
{{- end -}}

{{/*
Returns the name of the EnvoyProxy resource.
*/}}
{{- define "gitlab.gatewayApi.envoy.config.name" -}}
{{- printf "%s-envoy-proxy" .Release.Name -}}
{{- end -}}

{{- define "gitlab.gatewayApi.gateway.name.default" -}}
{{- printf "%s-gw" .Release.Name -}}
{{- end -}}

{{/*
Returns a target ref to the Gateway resource without namespace and sectionName
for usage in Envoy policy custom resources.
*/}}
{{- define "gitlab.gatewayApi.gatewayRef.local" -}}
- group: gateway.networking.k8s.io
  kind: Gateway
  name: {{ coalesce (.Values.gatewayRoute).gatewayName .Values.global.gatewayApi.gatewayRef.name (include "gitlab.gatewayApi.gateway.name.default" .) | quote }}
{{- end -}}

{{/*
Returns true if envoy policies should be installed. Policies are installed if bundled envoy is installed
and if Gateway is in same namespace.
*/}}
{{- define "gitlab.gatewayApi.envoy.installPolicies" -}}
{{- $installEnvoy := and .Values.global.gatewayApi.enabled .Values.global.gatewayApi.installEnvoy -}}
{{- $gatewayNamespace := (include "gitlab.gatewayApi.gatewayRef" . | fromYamlArray | first).namespace -}}
{{- $gatewayInSameNamespace := eq .Release.Namespace $gatewayNamespace -}}
{{- if and $installEnvoy $gatewayInSameNamespace -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{/*
Returns a target refs to the Gateway resource with a namespace and optionally a section name.
*/}}
{{- define "gitlab.gatewayApi.gatewayRef" -}}
{{- template "gitlab.gatewayApi.gatewayRef.local" . }}
  namespace: {{ coalesce (.Values.gatewayRoute).gatewayNamespace .Values.global.gatewayApi.gatewayRef.namespace .Release.Namespace | quote }}
{{- with .Values.gatewayRoute }}
{{-   with .sectionName }}
  sectionName: {{ . | quote }}
{{-   end }}
{{- end }}
{{- end }}

{{/*
Renders a single listener configuration for the managed Gateway resource.

Input parameters:
local:
  name: Name of the listener
  protocol: Protocol type (HTTPS, HTTP, TCP, or nil)
  hostname: Domain name (e.g., example.com)
  tls:
    mode: TLS termination mode
    certificateRefs: List of certificate references
root:
  protocol: Default protocol (HTTPS or HTTP)

The root protocol serves as a default when no local protocol is specified,
enabling centralized protocol configuration for all HTTP(S) workloads and
listeners through a single setting.

Port assignment is automatically determined based on the selected protocol.
*/}}
{{- define "gitlab.gatewayApi.gateway.listener" -}}
{{- $name := .local.name }}
{{- $protocol := .local.protocol | default .root.protocol | upper }}
{{- $port := 443 }}
{{- if eq "HTTP" $protocol }}
{{-   $port = 80 }}
{{- end }}
{{- if eq "TCP" $protocol }}
{{-   $port = 22 }}
{{- end }}
- name: {{ $name }}
  protocol: {{ $protocol }}
  port: {{ $port }}
  allowedRoutes:
    namespaces:
      from: Same
{{- with .local.hostname }}
  hostname: {{ . | quote }}
{{- end }}
{{- if or (eq "HTTPS" $protocol) (eq "TLS" $protocol) }}
{{-   with .local.tls }}
  tls:
{{-     toYaml . | nindent 4 }}
{{-   end }}
{{- end }}
{{- end -}}

{{/*
Returns true if the http-default listener should be included on the managed Gateway.
Enabled when either configureCertmanager or httpToHttpsRedirect (with HTTPS protocol)
is active, and the Gateway is managed (no external gatewayRef).
*/}}
{{- define "gitlab.gatewayApi.httpDefault.enabled" -}}
{{- $managed := and .Values.global.gatewayApi.enabled (not .Values.global.gatewayApi.gatewayRef) -}}
{{- $certmanager := .Values.global.gatewayApi.configureCertmanager -}}
{{- $redirect := and .Values.global.gatewayApi.httpToHttpsRedirect (eq (upper .Values.gatewayApiResources.gateway.protocol) "HTTPS") -}}
{{- if and $managed (or $certmanager $redirect) -}}
true
{{- end -}}
{{- end -}}

{{/*
Returns true if the HTTP-to-HTTPS redirect HTTPRoute should be rendered.
Enabled when gatewayApi is enabled, httpToHttpsRedirect is true, protocol
is HTTPS, and the Gateway is managed (no external gatewayRef).
*/}}
{{- define "gitlab.gatewayApi.httpRedirect.enabled" -}}
{{- $enabled := and .Values.global.gatewayApi.enabled .Values.global.gatewayApi.httpToHttpsRedirect -}}
{{- $httpsProtocol := eq (upper .Values.gatewayApiResources.gateway.protocol) "HTTPS" -}}
{{- $managedGateway := not .Values.global.gatewayApi.gatewayRef -}}
{{- if and $enabled $httpsProtocol $managedGateway -}}
true
{{- end -}}
{{- end -}}

{{/*
Checks if a Route should be enabled. Defaults to global GatewayAPI toggle but can be 
configured per Route by setting true/false explicitly.
*/}}
{{- define "gitlab.gatewayApi.route.enabled" -}}
{{- if not (eq nil .Values.gatewayRoute.enabled) -}}
{{-   .Values.gatewayRoute.enabled -}}
{{- else }}
{{-   .Values.global.gatewayApi.enabled -}}
{{- end -}}
{{- end -}}

{{/*
Renders the name of the HTTP01 Issuer for managing certificates used by GatewayAPI.
Different from the Issuer used for Ingresses.
*/}}
{{- define "gitlab.gatewayApi.certmanager.issuer" -}}
{{- printf "%s-gw-issuer" .Release.Name -}}
{{- end -}}

{{/*
Renders certmanager annotations for the Gateway resource.
https://cert-manager.io/docs/usage/gateway/
*/}}
{{- define "gitlab.gatewayApi.certmanager.annotations" -}}
{{- if .Values.global.gatewayApi.configureCertmanager -}}
cert-manager.io/issuer: {{ include "gitlab.gatewayApi.certmanager.issuer" . }}
{{- end -}}
{{- end -}}

{{/*
Renders true if Gateway resources should be configured for Geo traffic.
*/}}
{{- define "gitlab.gatewayApi.gateway.geo.configure" -}}
{{ if and .Values.global.geo.enabled .Values.global.geo.gatewayApi.additionalHostname .Values.global.gatewayApi.enabled -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}

{{/*
Envoy Proxy image used with the bundled Envoy Gateway when proxySpec sets none.
The default Envoy Proxy image of the bundled Envoy Gateway still trusts the
compromised eMudhra intermediate CAs. See the upstream remediation:
https://www.envoyproxy.io/docs/envoy/v1.37.11/version_history/v1.37/v1.37.11
*/}}
{{- define "gitlab.gatewayApi.envoy.proxy.image" -}}
docker.io/envoyproxy/envoy:distroless-v1.37.11
{{- end -}}

{{/*
Returns the key of the Envoy workload that a proxySpec.provider.kubernetes map configures:
envoyDaemonSet when it is set, envoyDeployment otherwise. templates/envoy/proxy.yaml drops
envoyDeployment when envoyDaemonSet is set.
*/}}
{{- define "gitlab.gatewayApi.envoy.proxy.workload" -}}
{{- ternary "envoyDaemonSet" "envoyDeployment" (hasKey . "envoyDaemonSet") -}}
{{- end -}}

{{/*
Returns which image field the container of that workload sets: "image", "imageRepository",
or nothing. The EnvoyProxy CRD accepts only one of them, so templates/envoy/proxy.yaml sets
gitlab.gatewayApi.envoy.proxy.image only when this returns nothing.
*/}}
{{- define "gitlab.gatewayApi.envoy.proxy.imageSource" -}}
{{- $workloadSpec := get . (include "gitlab.gatewayApi.envoy.proxy.workload" .) | default dict -}}
{{- $container := get $workloadSpec "container" | default dict -}}
{{- if $container.image -}}
image
{{- else if $container.imageRepository -}}
imageRepository
{{- end -}}
{{- end -}}

{{/*
Returns the Envoy workload key when its container sets imageRepository instead of image while
the bundled Envoy Gateway is installed, so templates/NOTES.txt can warn that the chart does not
set gitlab.gatewayApi.envoy.proxy.image.
*/}}
{{- define "gitlab.gatewayApi.envoy.proxy.imageRepositoryWorkload" -}}
{{- $spec := .Values.gatewayApiResources.envoy.proxySpec -}}
{{- if and .Values.global.gatewayApi.enabled .Values.global.gatewayApi.installEnvoy $spec.provider $spec.provider.kubernetes -}}
{{-   if eq (include "gitlab.gatewayApi.envoy.proxy.imageSource" $spec.provider.kubernetes) "imageRepository" -}}
{{ include "gitlab.gatewayApi.envoy.proxy.workload" $spec.provider.kubernetes }}
{{-   end -}}
{{- end -}}
{{- end -}}
