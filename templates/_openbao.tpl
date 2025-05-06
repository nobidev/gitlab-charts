{{/*
Returns the hostname.
If the hostname is set in `global.hosts.openbao.name`, that will be returned,
otherwise the hostname will be assembled using `openbao` as the prefix, and the `gitlab.assembleHost` function.
*/}}
{{- define "gitlab.openbao.hostname" -}}
{{- coalesce .Values.global.hosts.openbao.name (include "gitlab.assembleHost"  (dict "name" "openbao" "context" . )) -}}
{{- end -}}

{{/*
Returns the OpenBao Url, ex: `http://openbao.example.com`
*/}}
{{- define "gitlab.openbao.url" -}}
{{- if or .Values.global.hosts.https .Values.global.hosts.openbao.https -}}
{{-   printf "https://%s" (include "gitlab.openbao.hostname" .) -}}
{{- else -}}
{{-   printf "http://%s" (include "gitlab.openbao.hostname" .) -}}
{{- end -}}
{{- end -}}


