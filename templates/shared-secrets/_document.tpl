{{/*
gitlab.secrets.document renders the GitLabSecrets document of the release.

Both backends read it. `provider: controller` applies it as a resource, and the secretgen
backend of `provider: job` mounts it from the hook ConfigMap and runs the secretgen binary
of the GitLab Operator on it. Its apiVersion and kind are the schema version the binary
reads.
*/}}
{{- define "gitlab.secrets.document" -}}
apiVersion: apps.gitlab.com/v2alpha1
kind: GitLabSecrets
metadata:
  name: {{ .Release.Name }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "gitlab.standardLabels" . | nindent 4 }}
    {{- include "gitlab.commonLabels" . | nindent 4 }}
spec:
  secrets:
  {{- range $secret := include "gitlab.secrets.load" . | fromYamlArray }}
    - name: {{ $secret.name | quote }}
      type: {{ default "Opaque" $secret.type }}
      generators:
        {{- range $generator := $secret.generators }}
        {{-   $clean := omit $generator "file" "certFile" "keyFile" }}
        {{-   if hasKey $generator "fields" }}
        {{-     $fields := list }}
        {{-     range $field := $generator.fields }}
        {{-       $fields = append $fields (omit $field "note") }}
        {{-     end }}
        {{-     $clean = merge (dict "fields" $fields) (omit $clean "fields") }}
        {{-   end }}
        {{-   toYaml (list $clean) | nindent 8 }}
        {{- end }}
  {{- end }}
{{- if eq (include "gitlab.shared-secrets.selfSignedTls.required" .) "true" }}
{{-   $selfsign := (index .Values "shared-secrets").selfsign }}
{{-   $certname := include "gitlab.wildcard-self-signed-cert-name" . }}
  certificates:
    - authority:
        commonName: {{ $selfsign.caSubject | quote }}
        organization: {{ .Release.Namespace | quote }}
        organizationalUnit: {{ .Release.Name | quote }}
        algorithm: {{ $selfsign.keyAlgorithm | quote }}
        keySize: {{ $selfsign.keySize | int }}
      domain: {{ .Values.global.hosts.domain | quote }}
      {{- /* What the Job's cfssl-self-sign issues; selfsign.expiry applies to neither backend (charts/gitlab#6693). */}}
      caDays: 1825
      certDays: 365
      {{- /* The wildcard certificate, as a kubernetes.io/tls Secret. */}}
      tlsSecret: {{ $certname | quote }}
      {{- /* The authority on its own, mounted into every pod's trusted CA bundle. */}}
      caSecret: {{ printf "%s-ca" $certname | quote }}
      caKey: cfssl_ca
      {{- /* Authority and certificate concatenated, consumed by GitLab Runner. */}}
      chainSecret: {{ printf "%s-chain" $certname | quote }}
      chainKey: {{ printf "%s.crt" (include "gitlab.gitlab.hostname" .) | quote }}
{{- end }}
{{- end -}}
