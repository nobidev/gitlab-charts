{{/* Common templates for PodDisruptionBudget */}}

{{/*
Returns the appropriate apiVersion for PodDisruptionBudget.

It expects a dictionary with three entries:
  - `global` which contains global PDB settings, e.g. .Values.global.pdb
  - `local` which contains local PDB settings, e.g. .Values.sidekiq.pdb
  - `context` which is the parent context (either `.` or `$`)
*/}}
{{- define "gitlab.pdb.apiVersion" -}}
{{-   $local := default dict .local -}}
{{-   if (get $local "apiVersion") -}}
{{-     .local.apiVersion -}}
{{-   else if .global.apiVersion -}}
{{-     .global.apiVersion -}}
{{-   else -}}
{{-     print "policy/v1" -}}
{{-   end -}}
{{- end -}}
