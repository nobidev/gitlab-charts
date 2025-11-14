{{- define "gitlab.gatewayApi.class" -}}
{{- .Values.global.gatewayApi.class -}}
{{- end -}}

{{- define "gitlab.gatewayApi.gateway" -}}
{{ printf "%s-gw" .Release.Name }}
{{- end -}}

{{- define "gitlab.gatewayApi.certmanager.issuer" -}}
{{ .Release.Name }}-gw-issuer
{{- end -}}

{{- define "gitlab.gatewayApi.certmanager.annotations" -}}
{{- if .Values.global.gatewayApi.configureCertmanager -}}
cert-manager.io/issuer: {{ include "gitlab.gatewayApi.certmanager.issuer" . }}
{{- end -}}
{{- end -}}