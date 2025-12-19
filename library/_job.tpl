{{/*
Common Job template
Params:
  - root: $ (root context)
  - name: job name (string)
  - chart: chart name (string)
  - labels: additional labels (dict)
  - annotations: additional annotations (dict)
  - backoffLimit: backoff limit (optional, default 6)
  - completions: completions (optional)
  - parallelism: parallelism (optional)
  - activeDeadlineSeconds: active deadline (optional)
  - ttlSecondsAfterFinished: TTL after finished (optional)
  - completionMode: completion mode (optional, e.g., "Indexed")
  - podSpec: pod spec template (include this from calling chart)
  
Usage:
  {{- include "gitlab.lib.job" (dict 
       "root" $ 
       "name" "myjob"
       "backoffLimit" 3
       "podSpec" (include "myjob.podSpec" .)
     ) }}

Note: The podSpec should include restartPolicy (typically "OnFailure" or "Never")
*/}}
{{- define "gitlab.lib.job" -}}
{{- $root := .root -}}
{{- $name := .name | required "job name is required" -}}
{{- $chart := .chart | default "gitlab" -}}
{{- $labels := .labels | default dict -}}
{{- $annotations := .annotations | default dict -}}
apiVersion: batch/v1
kind: Job
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
  backoffLimit: {{ .backoffLimit | default 6 }}
  {{- with .completions }}
  completions: {{ . }}
  {{- end }}
  {{- with .parallelism }}
  parallelism: {{ . }}
  {{- end }}
  {{- with .activeDeadlineSeconds }}
  activeDeadlineSeconds: {{ . }}
  {{- end }}
  {{- with .ttlSecondsAfterFinished }}
  ttlSecondsAfterFinished: {{ . }}
  {{- end }}
  {{- with .completionMode }}
  completionMode: {{ . }}
  {{- end }}
  template:
{{ .podSpec | indent 4 }}
{{- end -}}

{{/*
Common CronJob template
Params:
  - root: $ (root context)
  - name: cronjob name (string)
  - chart: chart name (string)
  - labels: additional labels (dict)
  - annotations: additional annotations (dict)
  - schedule: cron schedule (string, required)
  - concurrencyPolicy: concurrency policy (optional, default "Allow")
  - successfulJobsHistoryLimit: successful jobs history limit (optional, default 3)
  - failedJobsHistoryLimit: failed jobs history limit (optional, default 1)
  - suspend: whether to suspend (optional, default false)
  - jobTemplate: job template spec (include this from calling chart)
  
Usage:
  {{- include "gitlab.lib.cronJob" (dict 
       "root" $ 
       "name" "mycronjob"
       "schedule" "0 * * * *"
       "jobTemplate" (include "mycronjob.jobTemplate" .)
     ) }}
*/}}
{{- define "gitlab.lib.cronJob" -}}
{{- $root := .root -}}
{{- $name := .name | required "cronjob name is required" -}}
{{- $schedule := .schedule | required "schedule is required" -}}
{{- $chart := .chart | default "gitlab" -}}
{{- $labels := .labels | default dict -}}
{{- $annotations := .annotations | default dict -}}
apiVersion: batch/v1
kind: CronJob
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
  schedule: {{ $schedule | quote }}
  concurrencyPolicy: {{ .concurrencyPolicy | default "Allow" }}
  successfulJobsHistoryLimit: {{ .successfulJobsHistoryLimit | default 3 }}
  failedJobsHistoryLimit: {{ .failedJobsHistoryLimit | default 1 }}
  {{- if hasKey . "suspend" }}
  suspend: {{ .suspend }}
  {{- end }}
  jobTemplate:
{{ .jobTemplate | indent 4 }}
{{- end -}}
