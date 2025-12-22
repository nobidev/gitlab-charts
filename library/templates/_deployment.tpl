{{/*
Common Deployment template
Params:
  - root: $ (root context)
  - name: deployment name (string)
  - chart: chart name (string)
  - labels: additional labels (dict)
  - selectorLabels: selector labels (dict)
  - annotations: additional annotations (dict)
  - replicas: number of replicas (optional, omit if HPA is used)
  - strategy: deployment strategy (optional)
  - minReadySeconds: minReadySeconds (optional)
  - podSpec: pod spec template (include this from calling chart)
  
Usage:
  {{- include "gitlab.lib.deployment" (dict 
       "root" $ 
       "name" "myapp"
       "chart" .Chart.Name
       "podSpec" (include "myapp.podSpec" .)
     ) }}
*/}}
{{- define "gitlab.lib.deployment" -}}
{{- $root := .root -}}
{{- $name := .name | required "deployment name is required" -}}
{{- $chart := .chart | default "gitlab" -}}
{{- $labels := .labels | default dict -}}
{{- $selectorLabels := .selectorLabels | default dict -}}
{{- $annotations := .annotations | default dict -}}
apiVersion: apps/v1
kind: Deployment
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
  selector:
    matchLabels:
      {{- include "gitlab.selectorLabels" $root | nindent 6 }}
      {{- with $selectorLabels }}
      {{- toYaml . | nindent 6 }}
      {{- end }}
  {{- with .strategy }}
  strategy:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .minReadySeconds }}
  minReadySeconds: {{ . }}
  {{- end }}
  template:
{{ .podSpec | indent 4 }}
{{- end -}}

{{/*
Common Pod Template for Deployment
Params:
  - root: $ (root context)
  - values: values context (can be $ or subchart values)
  - labels: additional pod labels (dict)
  - annotations: additional pod annotations (dict)
  - configChecksum: checksum for config files (string)
  - podSecurityContext: pod security context (optional)
  - nodeSelector: node selector (optional)
  - tolerations: tolerations (optional)
  - affinity: affinity rules (optional)
  - topologySpreadConstraints: topology spread constraints (optional)
  - priorityClassName: priority class name (optional)
  - serviceAccountName: service account name (optional)
  - automountServiceAccountToken: whether to automount SA token (optional)
  - terminationGracePeriodSeconds: termination grace period (optional)
  - initContainers: init containers spec (string)
  - containers: main containers spec (string)
  - volumes: volumes spec (string)
  - imagePullSecrets: image pull secrets (string)
*/}}
{{- define "gitlab.lib.podTemplate" -}}
{{- $root := .root -}}
{{- $values := .values | default $root.Values -}}
{{- $labels := .labels | default dict -}}
{{- $annotations := .annotations | default dict -}}
metadata:
  labels:
    {{- include "gitlab.standardLabels" $root | nindent 4 }}
    {{- include "gitlab.commonLabels" $root | nindent 4 }}
    {{- include "gitlab.app.kubernetes.io.labels" $root | nindent 4 }}
    {{- include "gitlab.podLabels" $root | nindent 4 }}
    {{- with $labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  annotations:
    {{- if .configChecksum }}
    checksum/config: {{ .configChecksum }}
    {{- end }}
    cluster-autoscaler.kubernetes.io/safe-to-evict: {{ .safeToEvict | default "true" | quote }}
    {{- with $annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  {{- with .topologySpreadConstraints }}
  topologySpreadConstraints:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .tolerations }}
  tolerations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if .nodeSelector }}
  {{- include "gitlab.nodeSelector" (dict "Values" (dict "global" (dict "nodeSelector" $values.global.nodeSelector) "nodeSelector" .nodeSelector)) | nindent 2 }}
  {{- else if $values.global.nodeSelector }}
  {{- include "gitlab.nodeSelector" $root | nindent 2 }}
  {{- end }}
  {{- if .priorityClassName }}
  {{- include "gitlab.priorityClassName" (dict "Values" (dict "global" (dict "priorityClassName" $values.global.priorityClassName) "priorityClassName" .priorityClassName)) | nindent 2 }}
  {{- else if $values.global.priorityClassName }}
  {{- include "gitlab.priorityClassName" $root | nindent 2 }}
  {{- end }}
  {{- if .podSecurityContext }}
  {{- include "gitlab.podSecurityContext" .podSecurityContext | nindent 2 }}
  {{- else if $values.securityContext }}
  {{- include "gitlab.podSecurityContext" $values.securityContext | nindent 2 }}
  {{- end }}
  {{- with .affinity }}
  affinity:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if .serviceAccountName }}
  serviceAccountName: {{ .serviceAccountName }}
  {{- else if or $values.serviceAccount.enabled $values.global.serviceAccount.enabled }}
  serviceAccountName: {{ include "gitlab.serviceAccount.name" $root }}
  {{- end }}
  {{- if .automountServiceAccountToken }}
  {{- include "gitlab.automountServiceAccountToken" $root | nindent 2 }}
  {{- end }}
  {{- with .terminationGracePeriodSeconds }}
  terminationGracePeriodSeconds: {{ . | int }}
  {{- end }}
  {{- if .imagePullSecrets }}
{{ .imagePullSecrets | indent 2 }}
  {{- end }}
  {{- if .initContainers }}
  initContainers:
{{ .initContainers | indent 4 }}
  {{- end }}
  containers:
{{ .containers | indent 4 }}
  {{- if .volumes }}
  volumes:
{{ .volumes | indent 4 }}
  {{- end }}
{{- end -}}

{{/*
Common Init Container - Configure
Params:
  - root: $ (root context)
  - image: init image name
  - imageCfg: image configuration
  - command: command to run (optional, defaults to ['sh', '/config/configure'])
  - env: environment variables (string, optional)
  - volumeMounts: volume mounts (string)
  - resources: resources (optional)
*/}}
{{- define "gitlab.lib.initContainer.configure" -}}
{{- $root := .root -}}
{{- $command := .command | default (list "sh" "/config/configure") -}}
- name: configure
  command: {{ $command | toJson }}
  image: {{ include "gitlab.configure.image" (dict "root" $root "image" .image) | quote }}
  {{- include "gitlab.image.pullPolicy" .imageCfg | nindent 2 }}
  {{- include "gitlab.init.containerSecurityContext" $root | nindent 2 }}
  {{- if .env }}
  env:
{{ .env | indent 4 }}
  {{- end }}
  {{- if .volumeMounts }}
  volumeMounts:
{{ .volumeMounts | indent 4 }}
  {{- end }}
  {{- with .resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}

{{/*
Common Init Container - Dependencies
Params:
  - root: $ (root context)
  - image: main application image
  - imageCfg: image configuration
  - env: environment variables (string, optional)
  - volumeMounts: volume mounts (string)
  - resources: resources (optional)
*/}}
{{- define "gitlab.lib.initContainer.dependencies" -}}
{{- $root := .root -}}
- name: dependencies
  image: {{ .image | quote }}
  {{- include "gitlab.image.pullPolicy" .imageCfg | nindent 2 }}
  {{- include "gitlab.init.containerSecurityContext" $root | nindent 2 }}
  args:
    - /scripts/wait-for-deps
  {{- if .env }}
  env:
{{ .env | indent 4 }}
  {{- end }}
  {{- if .volumeMounts }}
  volumeMounts:
{{ .volumeMounts | indent 4 }}
  {{- end }}
  {{- with .resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}

{{/*
Common Container specification
Params:
  - root: $ (root context)
  - name: container name
  - image: image (full path with tag)
  - imageCfg: image configuration for pullPolicy
  - securityContext: container security context (optional)
  - ports: ports list (optional)
  - env: environment variables (string, optional)
  - volumeMounts: volume mounts (string, optional)
  - livenessProbe: liveness probe spec (optional)
  - readinessProbe: readiness probe spec (optional)
  - startupProbe: startup probe spec (optional)
  - lifecycle: lifecycle hooks (optional)
  - resources: resource requirements (optional)
*/}}
{{- define "gitlab.lib.container" -}}
{{- $root := .root -}}
- name: {{ .name | required "container name is required" }}
  image: {{ .image | required "container image is required" | quote }}
  {{- include "gitlab.image.pullPolicy" .imageCfg | nindent 2 }}
  {{- if .securityContext }}
  {{- include "gitlab.containerSecurityContext" $root | nindent 2 }}
  {{- end }}
  {{- with .ports }}
  ports:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- if .env }}
  env:
{{ .env | indent 4 }}
  {{- end }}
  {{- if .volumeMounts }}
  volumeMounts:
{{ .volumeMounts | indent 4 }}
  {{- end }}
  {{- with .livenessProbe }}
  livenessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .readinessProbe }}
  readinessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .startupProbe }}
  startupProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .lifecycle }}
  lifecycle:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
{{- end -}}
