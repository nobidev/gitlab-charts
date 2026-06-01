{{- define "gkg.gitlabBaseUrl" -}}
{{- .Values.gitlab.baseUrl | default (include "gitlab.workhorse.url" .) -}}
{{- end }}

{{- define "gkg.natsUrl" -}}
{{- $depsNats := printf "nats://%s-nats.%s.svc.cluster.local" .Values.gitlabDeps.releaseName (.Values.gitlabDeps.namespace | default .Release.Namespace) -}}
{{- .Values.nats.url | default $depsNats -}}
{{- end }}

{{- define "gitlab.gkg.signingSecret.name" -}}
{{- printf "%s-gkg-signing-jwt" .Release.Name -}}
{{- end -}}

{{- define "gitlab.gkg.verifyingSecret.name" -}}
{{- printf "%s-gkg-verifying-jwt" .Release.Name -}}
{{- end -}}
