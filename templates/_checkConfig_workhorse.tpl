{{/*
Ensure workhorse monitoring exporter's TLS config is valid
*/}}
{{- define "gitlab.checkConfig.workhorse.exporter.tls.enabled" -}}
{{-   $workhorseTlsEnabled := $.Values.global.workhorse.tls.enabled -}}
{{-   $monitoringTlsOverride := pluck "enabled" $.Values.gitlab.webservice.workhorse.monitoring.exporter.tls (dict "enabled" false) | first -}}
{{-   if and (eq $monitoringTlsOverride true) (not $workhorseTlsEnabled) }}
webservice.workhorse:
  The monitoring exporter TLS depends on the main workhorse listener using TLS.
  Use `global.workhorse.tls.enabled` to enable TLS for the main listener or `gitlab.webservice.workhorse.monitoring.exporter.tls.enabled`
  to disable TLS for the monitoring exporter.
{{-   end -}}
{{- end -}}

{{/*
Ensure Redis Sentinel SSL configuration is consistent
*/}}
{{- define "gitlab.checkConfig.redis.sentinel.ssl" -}}
{{-   if $.Values.global.redis.sentinels -}}
{{-     $sslValues := list -}}
{{-     range $sentinel := $.Values.global.redis.sentinels -}}
{{-       $ssl := dig "ssl" false $sentinel -}}
{{-       $sslValues = append $sslValues $ssl -}}
{{-     end -}}
{{-     $firstSsl := index $sslValues 0 -}}
{{-     range $ssl := $sslValues -}}
{{-       if ne $ssl $firstSsl }}
redis:
  All Sentinel entries must have the same SSL setting. Cannot mix ssl: true and ssl: false.
  Either set ssl: true on all sentinels or ssl: false on all sentinels.
{{-         break -}}
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
