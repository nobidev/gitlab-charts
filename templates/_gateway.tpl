{{/*
Returns name of the Gateway class. Consumed by chart managed Gateway and GatewayClass.
*/}}
{{- define "gitlab.gatewayApi.class.name" -}}
{{- .Values.global.gatewayApi.class.name -}}
{{- end -}}

{{/*
Returns the name of the EnvoyProxy resource.
*/}}
{{- define "gitlab.gatewayApi.envoyProxy.config.name" -}}
{{- printf "%s-envoy-proxy" .Release.Name -}}
{{- end -}}

{{/*
Returns name of the managed Gateway resource.
*/}}
{{- define "gitlab.gatewayApi.gateway" -}}
{{ printf "%s-gw" .Release.Name }}
{{- end -}}

{{/*
Returns a target refs to the managed Gateway resource.
*/}}
{{- define "gitlab.gatewayApi.gatewayRef" }}
group: gateway.networking.k8s.io
kind: Gateway
name: {{ include "gitlab.gatewayApi.gateway" . }}
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
context:
  The root context ($) for accessing .Release.Name

The root protocol serves as a default when no local protocol is specified,
enabling centralized protocol configuration for all HTTP(S) workloads and
listeners through a single setting.

Port assignment is automatically determined based on the selected protocol.

Certificate secret names are automatically prefixed with the release name
when global.gatewayApi.configureCertmanager is enabled, to match the secret
names created by cert-manager.
*/}}
{{- define "gitlab.gatewayApi.gateway.listener" -}}
{{- $name := .local.name }}
{{- $protocol := .local.protocol | default .root.protocol }}
{{- $port := 443 }}
{{- if eq "HTTP" $protocol }}
{{-   $port = 80 }}
{{- end }}
{{- if eq "TCP" $protocol }}
{{-   $port = 22 }}
{{- end }}
- name: {{ $name }}
  protocol: {{ $protocol | upper }}
  port: {{ $port }}
  allowedRoutes:
    namespaces:
      from: Same
{{- with .local.hostname }}
  hostname: {{ . | quote }}
{{- end }}
{{- if .local.tls }}
  tls:
    mode: {{ .local.tls.mode }}
    certificateRefs:
    {{- range .local.tls.certificateRefs }}
      - name: {{ include "gitlab.gatewayApi.tls.secretName" (dict "name" .name "context" $.context) }}
        {{- if .kind }}
        kind: {{ .kind }}
        {{- end }}
        {{- if .group }}
        group: {{ .group }}
        {{- end }}
    {{- end }}
{{- end }}
{{- end -}}

{{/*
Returns the TLS secret name for Gateway API listeners.
When configureCertmanager is enabled, uses the shared gitlab.tls.secretName helper
to prefix the secret name with the release name, matching the secrets created by cert-manager.
When configureCertmanager is disabled, returns the name as-is from values.yaml.

Input: dict with "name" (the base secret name) and "context" (root context for .Release.Name)
*/}}
{{- define "gitlab.gatewayApi.tls.secretName" -}}
{{- if .context.Values.global.gatewayApi.configureCertmanager -}}
{{-   include "gitlab.tls.secretName" . -}}
{{- else -}}
{{-   .name -}}
{{- end -}}
{{- end -}}

{{/*
Renders the Gateway name referenced from a Route resource.
Defaults to the GitLab chart managed Gateway but can be overriden per Route.
*/}}
{{- define "gitlab.gatewayApi.route.gateway" -}}
{{ .Values.gatewayRoute.gatewayName | default (include "gitlab.gatewayApi.gateway" .) }}
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