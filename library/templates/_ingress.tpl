{{/*
Common Ingress template
Params:
  - root: $ (root context)
  - name: Ingress name (string)
  - labels: additional labels (dict)
  - annotations: additional annotations (dict) - chart-specific annotations
  - ingressCfg: ingress configuration dict (for API version and class)
  - host: hostname (string)
  - path: path (string, default from global)
  - pathType: pathType (string, default "Prefix")
  - serviceName: backend service name (string)
  - servicePort: backend service port (int or string)
  - tlsEnabled: whether TLS is enabled (bool)
  - tlsSecret: TLS secret name (string, optional)
  - rules: custom rules (list, optional) - if provided, overrides default single-host rule

Usage:
  {{- $ingressCfg := dict "global" .Values.global.ingress "local" .Values.ingress "context" . -}}
  {{- include "gitlab.lib.ingress" (dict 
       "root" $ 
       "name" "myapp-ingress"
       "ingressCfg" $ingressCfg
       "host" "myapp.example.com"
       "serviceName" "myapp"
       "servicePort" 8080
       "tlsEnabled" true
       "tlsSecret" "myapp-tls"
       "annotations" (dict "my-app/custom" "value")
     ) }}
*/}}
{{- define "gitlab.lib.ingress" -}}
{{- $root := .root -}}
{{- $name := .name | required "Ingress name is required" -}}
{{- $labels := .labels | default dict -}}
{{- $annotations := .annotations | default dict -}}
{{- $ingressCfg := .ingressCfg | required "ingressCfg is required" -}}
{{- $host := .host | required "host is required" -}}
{{- $path := .path | default (coalesce $ingressCfg.local.path $ingressCfg.global.path) -}}
{{- $pathType := .pathType | default (default "Prefix" $ingressCfg.global.pathType) -}}
{{- $serviceName := .serviceName | required "serviceName is required" -}}
{{- $servicePort := .servicePort | required "servicePort is required" -}}
{{- $tlsEnabled := .tlsEnabled | default false -}}
{{- $tlsSecret := .tlsSecret -}}
apiVersion: {{ template "gitlab.ingress.apiVersion" $ingressCfg }}
kind: Ingress
metadata:
  name: {{ $name }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    {{- include "gitlab.standardLabels" $root | nindent 4 }}
    {{- include "gitlab.commonLabels" $root | nindent 4 }}
    {{- with $labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  annotations:
    {{ include "ingress.class.annotation" $ingressCfg }}
    kubernetes.io/ingress.provider: "{{ template "gitlab.ingress.provider" $ingressCfg }}"
    {{- include "gitlab.certmanager_annotations" $root | nindent 4 }}
    {{- with $annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- if $ingressCfg.local.annotations }}
  {{- range $key, $value := $ingressCfg.local.annotations }}
    {{ $key }}: {{ $value | quote }}
  {{- end }}
  {{- end }}
  {{- if $ingressCfg.global.annotations }}
  {{- range $key, $value := $ingressCfg.global.annotations }}
    {{ $key }}: {{ $value | quote }}
  {{- end }}
  {{- end }}
spec:
  {{ include "ingress.class.field" $ingressCfg }}
  {{- if .rules }}
  rules:
    {{- toYaml .rules | nindent 4 }}
  {{- else }}
  rules:
    - host: {{ $host }}
      http:
        paths:
          - path: {{ $path }}
            {{ if or ($root.Capabilities.APIVersions.Has "networking.k8s.io/v1/Ingress") (eq $ingressCfg.global.ingress.apiVersion "networking.k8s.io/v1") -}}
            pathType: {{ $pathType }}
            backend:
              service:
                name: {{ $serviceName }}
                port:
                  {{- if kindIs "int" $servicePort }}
                  number: {{ $servicePort }}
                  {{- else }}
                  name: {{ $servicePort }}
                  {{- end }}
            {{- else -}}
            backend:
              serviceName: {{ $serviceName }}
              servicePort: {{ $servicePort }}
            {{- end -}}
  {{- end }}
  {{- if and $tlsSecret $tlsEnabled }}
  tls:
    - hosts:
      - {{ $host }}
      secretName: {{ $tlsSecret }}
  {{- else }}
  tls: []
  {{- end }}
{{- end -}}
