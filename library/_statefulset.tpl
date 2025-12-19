{{/*
Common StatefulSet template
Params:
  - root: $ (root context)
  - name: statefulset name (string)
  - chart: chart name (string)
  - labels: additional labels (dict)
  - selectorLabels: selector labels (dict)
  - annotations: additional annotations (dict)
  - replicas: number of replicas (optional)
  - serviceName: service name for statefulset (required)
  - podManagementPolicy: pod management policy (optional, default "OrderedReady")
  - updateStrategy: update strategy (optional)
  - minReadySeconds: minReadySeconds (optional)
  - persistentVolumeClaimRetentionPolicy: PVC retention policy (optional)
  - volumeClaimTemplates: persistent volume claim templates (optional)
  - podSpec: pod spec template (include this from calling chart)
  
Usage:
  {{- include "gitlab.lib.statefulSet" (dict 
       "root" $ 
       "name" "myapp"
       "serviceName" "myapp"
       "podSpec" (include "myapp.podSpec" .)
       "volumeClaimTemplates" (include "myapp.volumeClaimTemplates" .)
     ) }}
*/}}
{{- define "gitlab.lib.statefulSet" -}}
{{- $root := .root -}}
{{- $name := .name | required "statefulset name is required" -}}
{{- $serviceName := .serviceName | required "serviceName is required" -}}
{{- $chart := .chart | default "gitlab" -}}
{{- $labels := .labels | default dict -}}
{{- $selectorLabels := .selectorLabels | default dict -}}
{{- $annotations := .annotations | default dict -}}
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: {{ $name }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    {{- include "gitlab.standardLabels" $root | nindent 4 }}
    {{- include "gitlab.commonLabels" $root | nindent 4 }}
    {{- include "gitlab.app.kubernetes.io.labels" $root | nindent 4 }}
    {{- with $labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  annotations:
    {{- include "gitlab.deploymentAnnotations" $root | nindent 4 }}
    {{- with $annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- if .replicas }}
  replicas: {{ .replicas }}
  {{- end }}
  serviceName: {{ $serviceName }}
  {{- with .podManagementPolicy }}
  podManagementPolicy: {{ . }}
  {{- end }}
  selector:
    matchLabels:
      {{- include "gitlab.selectorLabels" $root | nindent 6 }}
      {{- with $selectorLabels }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
  {{- with .updateStrategy }}
  updateStrategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .minReadySeconds }}
  minReadySeconds: {{ . }}
  {{- end }}
  {{- with .persistentVolumeClaimRetentionPolicy }}
  persistentVolumeClaimRetentionPolicy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  template:
{{ .podSpec | indent 4 }}
  {{- if .volumeClaimTemplates }}
  volumeClaimTemplates:
{{ .volumeClaimTemplates | indent 4 }}
  {{- end }}
{{- end -}}

{{/*
Common VolumeClaimTemplate for StatefulSet
Params:
  - name: PVC name (string)
  - accessModes: access modes (list)
  - storageClassName: storage class name (string, optional)
  - storage: storage size (string)
  - labels: labels for PVC (dict, optional)
  - selector: label selector for PVC (dict, optional)
  - volumeMode: volume mode (string, optional, e.g., "Filesystem", "Block")
  - dataSource: data source reference (dict, optional)

Usage:
  {{- include "gitlab.lib.volumeClaimTemplate" (dict 
       "name" "data"
       "accessModes" (list "ReadWriteOnce")
       "storage" "10Gi"
       "storageClassName" "fast"
     ) }}
*/}}
{{- define "gitlab.lib.volumeClaimTemplate" -}}
{{- $name := .name | required "volumeClaimTemplate name is required" -}}
{{- $accessModes := .accessModes | required "accessModes is required" -}}
{{- $storage := .storage | required "storage is required" -}}
- metadata:
    name: {{ $name }}
    {{- with .labels }}
    labels:
      {{- toYaml . | nindent 6 }}
    {{- end }}
  spec:
    accessModes:
      {{- range $accessModes }}
      - {{ . }}
      {{- end }}
    {{- with .storageClassName }}
    storageClassName: {{ . }}
    {{- end }}
    {{- with .volumeMode }}
    volumeMode: {{ . }}
    {{- end }}
    {{- with .selector }}
    selector:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .dataSource }}
    dataSource:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    resources:
      requests:
        storage: {{ $storage }}
{{- end -}}
