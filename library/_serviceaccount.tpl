{{/*
Common ServiceAccount template
Params:
  - root: $ (root context)
  - name: ServiceAccount name (string)
  - labels: additional labels (dict)
  - annotations: annotations (dict)
  - enabled: whether SA is enabled (bool, defaults to checking global/local config)
  - create: whether to create SA (bool, defaults to checking global/local config)
  - imagePullSecrets: list of image pull secrets (optional)
  - secrets: list of secrets to mount (optional)
  - automountServiceAccountToken: whether to automount token (optional)

Usage:
  {{- include "gitlab.lib.serviceAccount" (dict 
       "root" $ 
       "name" (include "gitlab.serviceAccount.name" .)
       "annotations" .Values.serviceAccount.annotations
     ) }}
*/}}
{{- define "gitlab.lib.serviceAccount" -}}
{{- $root := .root -}}
{{- $values := $root.Values -}}
{{- $enabled := .enabled | default (or $values.serviceAccount.enabled $values.global.serviceAccount.enabled) -}}
{{- $create := .create | default (or $values.serviceAccount.create $values.global.serviceAccount.create) -}}
{{- if and $enabled $create }}
{{- $name := .name | required "ServiceAccount name is required" -}}
{{- $labels := .labels | default dict -}}
{{- $annotations := .annotations | default (default $values.serviceAccount.annotations $values.global.serviceAccount.annotations) -}}
apiVersion: v1
kind: ServiceAccount
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
{{- with .imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .secrets }}
secrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if hasKey . "automountServiceAccountToken" }}
automountServiceAccountToken: {{ .automountServiceAccountToken }}
{{- end }}
{{- end }}
{{- end -}}
