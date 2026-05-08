
{{- define "gitlab.removal.chart.minio" -}}
{{-   if ((.Values.global).minio).enabled }}
MinIO:
  The bundled MinIO chart has been removed. Please migrate to external
  object storage by following https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/
  and remove the MinIO configuration.
{{-   end -}}
{{- end -}}

{{- define "gitlab.removal.chart.postgresql" -}}
{{-   if (.Values.postgresql).install }}
PostgreSQL:
  The bundled PostgreSQL chart has been removed. Please migrate to external
  PostgreSQL by following https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/
  and remove the PostgreSQL chart configuration.
{{-   end -}}
{{- end -}}

{{- define "gitlab.removal.chart.redis" -}}
{{-   if (.Values.redis).install }}
Redis:
  The bundled Redis chart has been removed. Please migrate to external
  Redis by following https://docs.gitlab.com/charts/installation/migration/bundled_chart_migration/
  and remove the Redis chart configuration.
{{-   end -}}
{{- end -}}