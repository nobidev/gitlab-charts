{{/* ######### KAS related templates */}}

{{- define "gitlab.kas.mountSecrets" -}}
{{- if (or .Values.global.kas.enabled .Values.global.appConfig.gitlab_kas.enabled) -}}
# mount secret for kas
- secret:
    name: {{ template "gitlab.kas.secret" . }}
    items:
      - key: {{ template "gitlab.kas.key" . }}
        path: kas/.gitlab_kas_secret
{{- end -}}
{{- end -}}{{/* "gitlab.kas.mountSecrets" */}}

{{/*
Returns the KAS external URL (for external agentk connections)
*/}}
{{- define "gitlab.appConfig.kas.externalUrl" -}}
{{-   if .Values.global.appConfig.gitlab_kas.externalUrl -}}
{{-     .Values.global.appConfig.gitlab_kas.externalUrl -}}
{{-   else -}}
{{-     $hostname := include "gitlab.kas.hostname" . -}}
{{-     $https := or .Values.global.hosts.https .Values.global.hosts.kas.https -}}
{{-     if and $https (eq (include "gitlab.kas.grpc.available" .) "true") -}}
{{-       printf "grpcs://%s" $hostname -}}
{{-     else if $https -}}
{{-       printf "wss://%s" $hostname -}}
{{-     else -}}
{{-       printf "ws://%s" $hostname -}}
{{-     end -}}
{{-   end -}}
{{- end -}}

{{/*
Whether the KAS gRPC Ingress is rendered. Takes a dict with:
  "local":    the kas chart's `ingress.grpc.enabled` (tri-state, kas chart only)
  "global":   `global.kas.ingress.grpc.enabled` (tri-state)
  "provider": `global.ingress.provider`
An explicit boolean wins, local before global. When both are unset the Ingress is
rendered for the NGINX provider only, because that is the provider the template can
annotate for gRPC.
*/}}
{{- define "gitlab.kas.ingress.grpc.enabled" -}}
{{-   if kindIs "bool" .local -}}
{{-     .local -}}
{{-   else if kindIs "bool" .global -}}
{{-     .global -}}
{{-   else -}}
{{-     eq (default "" .provider) "nginx" -}}
{{-   end -}}
{{- end -}}

{{/*
Returns "true" when native gRPC from agentk reaches KAS through the chart's networking:
with Gateway API (Envoy forwards the client protocol on the KAS HTTPRoute), or with the
KAS gRPC Ingress. Never with a relative URL root, because the gRPC path cannot be prefixed.
Only reads `global` values, because it is evaluated from the webservice, sidekiq and
toolbox charts, which cannot see the kas chart's values. Prefer
`global.kas.ingress.grpc.enabled` over the kas chart's local toggle for that reason.
An explicit `global.kas.ingress.grpc.enabled` is trusted as is. When it is unset, the
gRPC Ingress only counts if Ingress is enabled globally (`global.ingress.enabled`, unset
means enabled, like `gitlab.ingress.enabled`) and the provider is NGINX. That keeps
WebSocket as the advertised protocol when routing is handled outside the chart.
*/}}
{{- define "gitlab.kas.grpc.available" -}}
{{-   $relativeUrlRoot := default "" .Values.global.appConfig.relativeUrlRoot -}}
{{-   $globalToggle := .Values.global.kas.ingress.grpc.enabled -}}
{{-   $ingressEnabled := true -}}
{{-   if kindIs "bool" .Values.global.ingress.enabled -}}
{{-     $ingressEnabled = .Values.global.ingress.enabled -}}
{{-   end -}}
{{-   $grpcIngress := false -}}
{{-   if kindIs "bool" $globalToggle -}}
{{-     $grpcIngress = $globalToggle -}}
{{-   else -}}
{{-     $grpcIngress = and $ingressEnabled (eq (default "" .Values.global.ingress.provider) "nginx") -}}
{{-   end -}}
{{-   if and (eq $relativeUrlRoot "") (or .Values.global.gatewayApi.enabled $grpcIngress) -}}
true
{{-   end -}}
{{- end -}}

{{- define "gitlab.kas.internal.scheme" -}}
{{- printf "%s" (ternary "grpcs" "grpc" (eq $.Values.global.kas.tls.enabled true)) -}}
{{- end -}}

{{/*
Returns the KAS internal URL (for GitLab backend connections)
*/}}
{{- define "gitlab.appConfig.kas.internalUrl" -}}
{{-   if .Values.global.appConfig.gitlab_kas.internalUrl -}}
{{-     .Values.global.appConfig.gitlab_kas.internalUrl -}}
{{-   else -}}
{{-     $serviceHost := include "gitlab.kas.serviceHost" . -}}
{{-     $scheme := include "gitlab.kas.internal.scheme" . -}}
{{-     $port := .Values.global.kas.service.apiExternalPort -}}
{{-     printf "%s://%s:%s" $scheme $serviceHost (toString $port) -}}
{{-   end -}}
{{- end -}}

{{/*
Returns the KAS client timeout in seconds
*/}}
{{- define "gitlab.appConfig.kas.clientTimeoutSeconds" -}}
{{- with .Values.global.appConfig.gitlab_kas.clientTimeoutSeconds -}}
client_timeout_seconds: {{ . }}
{{- end -}}
{{- end -}}

{{/*
Return the KAS service host
*/}}
{{- define "gitlab.kas.serviceHost" -}}
{{-     $serviceName := include "gitlab.kas.serviceName" . -}}
{{-     include "gitlab.assembleServiceAddress" (dict "name" $serviceName "context" $) -}}
{{- end -}}

{{/*
Return the KAS service name
*/}}
{{- define "gitlab.kas.serviceName" -}}
{{- include "gitlab.other.fullname" (dict "context" . "chartName" "kas") -}}
{{- end -}}

