{{/*
Common ConfigMap template
Params:
  - root: $ (root context)
  - name: ConfigMap name (string)
  - labels: additional labels (dict)
  - annotations: annotations (dict)
  - data: configmap data (dict) - values should be pre-rendered strings
  - binaryData: configmap binary data (dict, optional)
  - immutable: make configmap immutable (bool, optional)

Usage:
  {{- include "gitlab.lib.configMap" (dict 
       "root" $ 
       "name" "myapp-config"
       "data" (dict "config.yaml" (include "myapp.config" . | fromYaml | toYaml))
     ) }}

Note: Data values should be pre-rendered as strings. Use `nindent` or `indent` 
      in your data preparation if needed. The template will handle proper YAML formatting.
*/}}
{{- define "gitlab.lib.configMap" -}}
{{- $root := .root -}}
{{- $name := .name | required "ConfigMap name is required" -}}
{{- $labels := .labels | default dict -}}
{{- $annotations := .annotations | default dict -}}
{{- $data := .data | required "ConfigMap data is required" -}}
apiVersion: v1
kind: ConfigMap
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
{{- with .immutable }}
immutable: {{ . }}
{{- end }}
data:
  {{- range $key, $value := $data }}
  {{ $key }}: |
{{ $value | indent 4 }}
  {{- end }}
{{- with .binaryData }}
binaryData:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end -}}
