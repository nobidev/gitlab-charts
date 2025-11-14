{{- define "gitlab.gatewayApi.class.name" -}}
{{- .Values.global.gatewayApi.class.name -}}
{{- end -}}

{{- define "gitlab.gatewayApi.envoyProxy.config.name" -}}
{{- printf "%s-envoy-proxy" .Release.Name -}}
{{- end -}}

{{- define "gitlab.gatewayApi.gateway" -}}
{{ printf "%s-gw" .Release.Name }}
{{- end -}}

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
  hostname: {{ . }}
{{- end }}
{{- with .local.tls }} 
  tls:
{{- toYaml . | nindent 4 }}
{{- end }}
{{- end -}}

{{- define "gitlab.gatewayApi.route.gateway" -}}
{{ .Values.gatewayRoute.gatewayName | default (include "gitlab.gatewayApi.gateway" .) }}
{{- end -}}

{{- define "gitlab.gatewayApi.route.enabled" -}}
{{- if not (eq nil .Values.gatewayRoute.enabled) -}}
{{-   .Values.gatewayRoute.enabled -}}
{{- else }}
{{-   .Values.global.gatewayApi.enabled -}}
{{- end -}}
{{- end -}}

{{- define "gitlab.gatewayApi.certmanager.issuer" -}}
{{- printf "%s-gw-issuer" .Release.Name -}}
{{- end -}}

{{- define "gitlab.gatewayApi.certmanager.annotations" -}}
{{- if .Values.global.gatewayApi.configureCertmanager -}}
cert-manager.io/issuer: {{ include "gitlab.gatewayApi.certmanager.issuer" . }}
{{- end -}}
{{- end -}}