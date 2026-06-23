{{/*
Returns the AI Gateway hostname.
Reads ai-gateway.host.name directly (operator-specified FQDN).
Fails with a clear error if empty when external access is enabled.
*/}}
{{- define "ai-gateway.hostname" -}}
{{- $aiGatewayValues := index .Values "ai-gateway" -}}
{{- $hostname := dig "host" "name" "" $aiGatewayValues -}}
{{- if and (empty $hostname) (dig "externalAccess" "enabled" false $aiGatewayValues) -}}
{{-   fail "ai-gateway.host.name must be set when ai-gateway.externalAccess.enabled is true" -}}
{{- end -}}
{{- $hostname -}}
{{- end -}}

{{/*
Returns the AI Gateway service name (for use in Ingress/HTTPRoute backends).
*/}}
{{- define "gitlab.aiGateway.serviceName" -}}
{{- include "gitlab.other.fullname" (dict "context" . "chartName" "ai-gateway") -}}
{{- end -}}

{{/*
Returns the TLS secret name for the AI Gateway ingress.
Uses ai-gateway.host.tls.secretName first, then falls back to cert-manager or wildcard self-signed.
*/}}
{{- define "gitlab.aiGateway.tlsSecret" -}}
{{- $aiGatewayValues := index .Values "ai-gateway" -}}
{{- $localSecretName := dig "host" "tls" "secretName" "" $aiGatewayValues -}}
{{- if $localSecretName -}}
{{-   $localSecretName -}}
{{- else if .Values.global.ingress.configureCertmanager -}}
{{-   printf "%s-ai-gateway-tls" .Release.Name -}}
{{- else -}}
{{-   include "gitlab.wildcard-self-signed-cert-name" . -}}
{{- end -}}
{{- end -}}

{{/*
Override ai-gateway.gitlab.url helper
In production mode the AIGW requires the gitlab url to be https for the key exachange to work
Other it will fail for security reason
*/}}
{{- define "ai-gateway.gitlab.url" -}}
{{- include "gitlab.gitlab.url" . }}
{{- end -}}
{{/*
Override ai-gateway.gitlab.apiUrl helper
*/}}
{{- define "ai-gateway.gitlab.apiUrl" -}}
{{- include "ai-gateway.gitlab.url" . -}}/api/v4
{{- end -}}

{{/*
Override Duo Workflow key secret helpers
*/}}
{{- define "ai-gateway.duoWorkflowSigningKey.secret" -}}
{{- default (printf "%s-ai-gateway-duo-workflow-signing-secret" .Release.Name) -}}
{{- end -}}

{{- define "ai-gateway.duoWorkflowSigningKey.key" -}}
duoWorkflowSigningKey
{{- end -}}

{{- define "ai-gateway.duoWorkflowValidationKey.secret" -}}
{{- default (printf "%s-ai-gateway-duo-workflow-validation-secret" .Release.Name) -}}
{{- end -}}

{{- define "ai-gateway.duoWorkflowValidationKey.key" -}}
duoWorkflowValidationKey
{{- end -}}

{{/*
Override AI Gateway key secret helpers
*/}}
{{- define "ai-gateway.aigwSigningKey.secret" -}}
{{- default (printf "%s-ai-gateway-aigw-signing-secret" .Release.Name) -}}
{{- end -}}

{{- define "ai-gateway.aigwSigningKey.key" -}}
aigwSigningKey
{{- end -}}

{{- define "ai-gateway.aigwValidationKey.secret" -}}
{{- default (printf "%s-ai-gateway-aigw-validation-secret" .Release.Name) -}}
{{- end -}}

{{- define "ai-gateway.aigwValidationKey.key" -}}
aigwValidationKey
{{- end -}}
