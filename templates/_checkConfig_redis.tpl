
{{/*
Ensure that `global.redis.host` is present when not using redis.yml override
*/}}
{{- define "gitlab.checkConfig.redis" -}}
{{-   if and (empty .Values.global.redis.host) (empty .Values.global.redis.redisYmlOverride) }}
redis:
  You must configure an Redis connection. Please set `global.redis.host` or `global.redis.redisYmlOverride`.
  See https://docs.gitlab.com/charts/advanced/external-redis/.
{{-   end -}}
{{- end -}}
