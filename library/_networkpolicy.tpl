{{/*
Common NetworkPolicy template
Params:
  - root: $ (root context)
  - name: NetworkPolicy name (string)
  - labels: additional labels (dict)
  - selectorLabels: pod selector labels (dict)
  - annotations: annotations (dict)
  - enabled: whether networkpolicy is enabled (bool)
  - policyTypes: list of policy types (["Ingress", "Egress"])
  - ingress: ingress rules (dict with enabled and rules)
  - egress: egress rules (dict with enabled and rules)

Usage:
  {{- include "gitlab.lib.networkPolicy" (dict 
       "root" $ 
       "name" "myapp-netpol"
       "enabled" .Values.networkpolicy.enabled
       "selectorLabels" (include "myapp.selectorLabels" . | fromYaml)
       "ingress" .Values.networkpolicy.ingress
       "egress" .Values.networkpolicy.egress
     ) }}
*/}}
{{- define "gitlab.lib.networkPolicy" -}}
{{- $root := .root -}}
{{- if .enabled }}
{{- $name := .name | required "NetworkPolicy name is required" -}}
{{- $labels := .labels | default dict -}}
{{- $selectorLabels := .selectorLabels | default dict -}}
{{- $annotations := .annotations | default dict -}}
{{- $ingress := .ingress | default dict -}}
{{- $egress := .egress | default dict -}}
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: {{ $name }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    {{- include "gitlab.standardLabels" $root | nindent 4 }}
    {{- include "gitlab.commonLabels" $root | nindent 4 }}
    {{- with $labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
spec:
  podSelector:
    matchLabels:
      {{- include "gitlab.selectorLabels" $root | nindent 6 }}
      {{- with $selectorLabels }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
  policyTypes:
    {{- if $egress.enabled }}
    - Egress
    {{- end }}
    {{- if $ingress.enabled }}
    - Ingress
    {{- end }}
  {{- if $ingress.enabled }}
  ingress:
    {{- toYaml $ingress.rules | nindent 4 }}
  {{- end }}
  {{- if $egress.enabled }}
  egress:
    {{- toYaml $egress.rules | nindent 4 }}
  {{- end }}
{{- end }}
{{- end -}}
