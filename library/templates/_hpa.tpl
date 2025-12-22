{{/*
Common HorizontalPodAutoscaler template
Params:
  - root: $ (root context)
  - name: HPA name (string)
  - labels: additional labels (dict)
  - scaleTargetRef: target reference (dict with apiVersion, kind, name)
  - minReplicas: minimum replicas (int)
  - maxReplicas: maximum replicas (int)
  - hpaCfg: HPA configuration dict (for metrics and behavior)

Usage:
  {{- $hpaCfg := (dict "global" $.Values.global.hpa "local" .Values.hpa "context" $) -}}
  {{- include "gitlab.lib.hpa" (dict 
       "root" $ 
       "name" "myapp"
       "scaleTargetRef" (dict "apiVersion" "apps/v1" "kind" "Deployment" "name" "myapp")
       "minReplicas" 2
       "maxReplicas" 10
       "hpaCfg" $hpaCfg
     ) }}
*/}}
{{- define "gitlab.lib.hpa" -}}
{{- $root := .root -}}
{{- $name := .name | required "HPA name is required" -}}
{{- $labels := .labels | default dict -}}
{{- $scaleTargetRef := .scaleTargetRef | required "scaleTargetRef is required" -}}
{{- $minReplicas := .minReplicas | required "minReplicas is required" -}}
{{- $maxReplicas := .maxReplicas | required "maxReplicas is required" -}}
{{- $hpaCfg := .hpaCfg -}}
apiVersion: {{ template "gitlab.hpa.apiVersion" $hpaCfg }}
kind: HorizontalPodAutoscaler
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
  scaleTargetRef:
    apiVersion: {{ $scaleTargetRef.apiVersion | default "apps/v1" }}
    kind: {{ $scaleTargetRef.kind | required "scaleTargetRef.kind is required" }}
    name: {{ $scaleTargetRef.name | required "scaleTargetRef.name is required" }}
  minReplicas: {{ $minReplicas }}
  maxReplicas: {{ $maxReplicas }}
  {{- include "gitlab.hpa.metrics" $hpaCfg | nindent 2 }}
  {{- include "gitlab.hpa.behavior" $hpaCfg | nindent 2 }}
{{- end -}}
