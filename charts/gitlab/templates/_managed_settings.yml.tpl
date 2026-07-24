{{- define "gitlab.managed_settings.yml" -}}
{{- $managedBy := "GitLab Helm Chart" -}}
{{- $settings := dict -}}
{{- with .Values.global.rails.managedSettings -}}
{{-   with dig "installation" "managedBy" "" . -}}
{{-     $managedBy = . -}}
{{-   end -}}
{{-   with .settings -}}
{{-     if .sidekiqTimezoneOverride -}}
{{-       $_ := set $settings "sidekiq_timezone_override" .sidekiqTimezoneOverride -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{- if $settings -}}
installation:
  managed_by: {{ $managedBy | quote }}
managed_settings:
{{ $settings | toYaml | indent 2 }}
{{- end -}}
{{- end -}}
