{{/*
Common KEDA ScaledObject template
Params:
  - root: $ (root context)
  - name: ScaledObject name (string)
  - labels: additional labels (dict)
  - scaleTargetRef: target reference (dict with apiVersion, kind, name)
  - kedaCfg: KEDA configuration dict (for spec generation)
  - enabled: whether KEDA is enabled (bool, optional)

Usage:
  {{- $kedaCfg := (dict "global" .Values.global "hpa" .Values.hpa "keda" .Values.keda "resources" .Values.resources) -}}
  {{- $kedaEnabled := include "gitlab.keda.scaledobject.enabled" $kedaCfg -}}
  {{- if $kedaEnabled }}
  {{- include "gitlab.lib.keda.scaledObject" (dict 
       "root" $ 
       "name" "myapp"
       "scaleTargetRef" (dict "apiVersion" "apps/v1" "kind" "Deployment" "name" "myapp")
       "kedaCfg" $kedaCfg
     ) }}
  {{- end }}
*/}}
{{- define "gitlab.lib.keda.scaledObject" -}}
{{- $root := .root -}}
{{- $name := .name | required "ScaledObject name is required" -}}
{{- $labels := .labels | default dict -}}
{{- $scaleTargetRef := .scaleTargetRef | required "scaleTargetRef is required" -}}
{{- $kedaCfg := .kedaCfg | required "kedaCfg is required" -}}
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
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
  {{- include "gitlab.keda.scaledobject.spec" $kedaCfg | nindent 2 }}
{{- end -}}
