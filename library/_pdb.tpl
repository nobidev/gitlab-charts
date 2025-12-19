{{/*
Common PodDisruptionBudget template
Params:
  - root: $ (root context)
  - name: PDB name (string)
  - labels: additional labels (dict)
  - selectorLabels: selector labels (dict)
  - maxUnavailable: max unavailable pods (int or string, optional)
  - minAvailable: min available pods (int or string, optional)
  - pdbCfg: PDB configuration dict for API version

Usage:
  {{- $pdbCfg := (dict "global" $.Values.global.pdb "local" .Values.pdb "context" $) -}}
  {{- include "gitlab.lib.pdb" (dict 
       "root" $ 
       "name" "myapp"
       "maxUnavailable" 1
       "selectorLabels" (include "myapp.selectorLabels" . | fromYaml)
       "pdbCfg" $pdbCfg
     ) }}
*/}}
{{- define "gitlab.lib.pdb" -}}
{{- $root := .root -}}
{{- $name := .name | required "PDB name is required" -}}
{{- $labels := .labels | default dict -}}
{{- $selectorLabels := .selectorLabels | default dict -}}
{{- $pdbCfg := .pdbCfg -}}
apiVersion: {{ template "gitlab.pdb.apiVersion" $pdbCfg }}
kind: PodDisruptionBudget
metadata:
  name: {{ $name }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    {{- include "gitlab.standardLabels" $root | nindent 4 }}
    {{- include "gitlab.commonLabels" $root | nindent 4 }}
    {{- with $labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- if .maxUnavailable }}
  maxUnavailable: {{ .maxUnavailable }}
  {{- end }}
  {{- if .minAvailable }}
  minAvailable: {{ .minAvailable }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "gitlab.selectorLabels" $root | nindent 6 }}
      {{- with $selectorLabels }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
{{- end -}}
