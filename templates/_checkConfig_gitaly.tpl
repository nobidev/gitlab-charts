{{/*
Protect against problems in storage names within repositories configuration.
- Ensure that one (and only one) storage is named 'default'.
- Ensure no duplicates

Collects the list of storage names by rendering the 'gitlab.appConfig.repositories'
template, and grabbing any lines that start with exactly 4 spaces.
*/}}
{{- define "gitlab.checkConfig.gitaly.storageNames" -}}
{{- $errorMsg := list -}}
{{- $config := include "gitlab.appConfig.repositories" $ -}}
{{- $storages := list }}
{{- range (splitList "\n" $config) -}}
{{-   if (regexMatch "^    [^ ]" . ) -}}
{{-     $storages = append $storages (trim . | trimSuffix ":") -}}
{{-   end }}
{{- end }}
{{- if gt (len $storages) (len (uniq $storages)) -}}
{{-   $errorMsg = append $errorMsg (printf "Each storage name must be unique. Current storage names: %s" $storages | sortAlpha | join ", ") -}}
{{- end -}}
{{- if not (has "default" $storages) -}}
{{-   $errorMsg = append $errorMsg ("There must be one (and only one) storage named 'default'.") -}}
{{- end }}
{{- if not (empty $errorMsg) }}
gitaly:
{{- range $msg := $errorMsg }}
    {{ $msg }}
{{- end }}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.gitaly.storageNames */}}

{{/*
Ensure that if a user is migrating to Praefect, none of the Praefect virtual storage
names are 'default', as it should already be used by the non-Praefect storage configuration.
*/}}
{{- define "gitlab.checkConfig.praefect.storageNames" -}}
{{- if and $.Values.global.gitaly.enabled $.Values.global.praefect.enabled (not $.Values.global.praefect.replaceInternalGitaly) -}}
{{-   range $i, $vs := $.Values.global.praefect.virtualStorages -}}
{{-     if eq $vs.name "default" -}}
praefect:
    Praefect is enabled, but `global.praefect.replaceInternalGitaly=false`. In this scenario,
    none of the Praefect virtual storage names can be 'default'. Please modify
    `global.praefect.virtualStorages[{{ $i }}].name`.
{{-     end }}
{{-   end }}
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.praefect.storageNames */}}

{{/*
Ensure that defaultReplicationFactor is greater then 0, and less than gitalyReplicas's number
*/}}
{{- define "gitlab.checkConfig.praefect.defaultReplicationFactor" -}}
{{- if and $.Values.global.gitaly.enabled $.Values.global.praefect.enabled -}}
{{-   range $i, $vs := $.Values.global.praefect.virtualStorages -}}
{{-     $gitalyReplicas := int (default 1 $vs.gitalyReplicas) -}}
{{-     $defaultReplicationFactor := int (default 1 $vs.defaultReplicationFactor) -}}
{{-     if or ( gt $defaultReplicationFactor $gitalyReplicas ) ( lt $defaultReplicationFactor 1 ) -}}
praefect:
    Praefect is enabled but 'defaultReplicationFactor' is not correct.
    'defaultReplicationFactor' is greater than 1, less than 'gitalyReplicas'.
    Please modify `global.praefect.virtualStorages[{{ $i }}].defaultReplicationFactor`.
{{-     end }}
{{-   end }}
{{- end }}
{{- end }}
{{/* END gitlab.checkConfig.praefect.defaultReplicationFactor */}}

{{/*
Ensure a certificate is provided when Gitaly is enabled and is instructed to
listen over TLS */}}
{{- define "gitlab.checkConfig.gitaly.tls" -}}
{{- $errorMsg := list -}}
{{- if and $.Values.global.gitaly.enabled $.Values.global.gitaly.tls.enabled -}}
{{-   if $.Values.global.praefect.enabled -}}
{{-     range $i, $vs := $.Values.global.praefect.virtualStorages -}}
{{-       if not $vs.tlsSecretName }}
{{-         $errorMsg = append $errorMsg (printf "global.praefect.virtualStorages[%d].tlsSecretName not specified ('%s')" $i $vs.name) -}}
{{-       end }}
{{-     end }}
{{-   end }}
{{- end }}
{{- if not (empty $errorMsg) }}
gitaly:
{{- range $msg := $errorMsg }}
    {{ $msg }}
{{- end }}
    This configuration is not supported.
{{- end -}}
{{- end -}}
{{/* END gitlab.checkConfig.gitaly.tls */}}

{{/* Check configuration of Gitaly external repos */}}
{{- define "gitlab.checkConfig.gitaly.extern.repos" -}}
{{-   if (and (not .Values.global.gitaly.enabled) (not .Values.global.gitaly.external) ) }}
gitaly:
    external Gitaly repos needs to be specified if global.gitaly.enabled is not set
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.gitaly.extern.repos */}}

{{/* Check that both GPG secret and key are set */}}
{{- define "gitlab.checkConfig.gitaly.gpgSigning" -}}
{{-   if and $.Values.global.gitaly.enabled $.Values.gitlab.gitaly.gpgSigning.enabled -}}
{{-     if not (and $.Values.gitlab.gitaly.gpgSigning.secret $.Values.gitlab.gitaly.gpgSigning.key) -}}
gitaly:
    secret and key must be set if gitlab.gitaly.gpgSigning.enabled is set
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.gitaly.gpgSigning */}}

{{/*
Ensure that gitlab.gitaly.storagePathFormat is below the repository volume
mount and has exactly one %s verb for the storage name. Quotes, backslashes,
and control characters would break the TOML string and the shell script.
The chart puts each storage name into the path, so the storage names must be
plain path elements. This also keeps the names literal in the shell script.
*/}}
{{- define "gitlab.checkConfig.gitaly.storagePathFormat" -}}
{{-   if $.Values.global.gitaly.enabled -}}
{{-     with $.Values.gitlab.gitaly.storagePathFormat -}}
{{-       if or (not (regexMatch "^/home/git/repositories/[^%\"'\\\\[:cntrl:]]*%s[^%\"'\\\\[:cntrl:]]*$" .)) (contains "/../" (printf "%s/" .)) }}
gitaly:
    `gitlab.gitaly.storagePathFormat` must be an absolute path below
    /home/git/repositories with exactly one `%s` for the storage name, and no
    other `%`, quote, backslash, control character, or `..` path element.
    Current value: {{ . | quote }}
{{-       end -}}
{{-       range (coalesce $.Values.gitlab.gitaly.internal.names $.Values.global.gitaly.internal.names) }}
{{-         if or (not (regexMatch "^[A-Za-z0-9._-]+$" (toString .))) (eq (toString .) ".") (eq (toString .) "..") }}
gitaly:
    When `gitlab.gitaly.storagePathFormat` is set, each storage name in
    `internal.names` must contain only letters, digits, `.`, `_`, and `-`, and
    must not be `.` or `..`. Current value: {{ . | quote }}
{{-         end -}}
{{-       end -}}
{{-     end -}}
{{-   end -}}
{{- end -}}
{{/* END gitlab.checkConfig.gitaly.storagePathFormat */}}
