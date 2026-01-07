{{- /*
Helpers ported from runway-base, adapted for gitlab-base library chart.
Naming convention: gitlab.* to match existing library template expectations.
*/}}

{{- /*
Service name - base name for all resources
*/}}
{{- define "gitlab.serviceName" -}}
  {{ .Values.metadata.name | default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end -}}

{{- /*
Create chart name and version used by the helm.sh/chart label.
*/}}
{{- define "gitlab.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- /*
Selector labels - used for pod selection
*/}}
{{- define "gitlab.selectorLabels" -}}
app.kubernetes.io/name: {{ .Values.metadata.name | default .Chart.Name }}
app.kubernetes.io/instance: {{ printf "%s-%s" (.Values.metadata.name | default .Chart.Name) .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- /*
Standard labels - common labels for all resources
*/}}
{{- define "gitlab.standardLabels" -}}
helm.sh/chart: {{ include "gitlab.chart" . }}
{{ include "gitlab.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/part-of: {{ .Values.metadata.name | default .Chart.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- /*
Common labels - alias for standardLabels
*/}}
{{- define "gitlab.commonLabels" -}}
{{ include "gitlab.standardLabels" . }}
{{- end }}

{{- /*
App kubernetes.io labels
*/}}
{{- define "gitlab.app.kubernetes.io.labels" -}}
{{ include "gitlab.standardLabels" . }}
{{- end }}

{{- /*
Pod labels - labels specifically for pods
*/}}
{{- define "gitlab.podLabels" -}}
{{ include "gitlab.selectorLabels" . }}
{{- end }}

{{- /*
Service labels
*/}}
{{- define "gitlab.serviceLabels" -}}
{{ include "gitlab.standardLabels" . }}
{{- end }}

{{- /*
Service account name
*/}}
{{- define "gitlab.serviceAccount.name" -}}
{{ .Values.metadata.name | default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- /*
Deployment annotations - empty by default
*/}}
{{- define "gitlab.deploymentAnnotations" -}}
{{- if .Values.spec.annotations }}
{{ toYaml .Values.spec.annotations }}
{{- end }}
{{- end }}

{{- /*
Service annotations - empty by default
*/}}
{{- define "gitlab.serviceAnnotations" -}}
{{- if .Values.spec.service_annotations }}
{{ toYaml .Values.spec.service_annotations }}
{{- end }}
{{- end }}

{{- /*
Cert-manager annotations - empty by default
*/}}
{{- define "gitlab.certmanager_annotations" -}}
{{- end }}

{{- /*
Image pull policy
*/}}
{{- define "gitlab.image.pullPolicy" -}}
imagePullPolicy: {{ .pullPolicy | default "IfNotPresent" }}
{{- end }}

{{- /*
Configure image for init containers
*/}}
{{- define "gitlab.configure.image" -}}
{{- end }}

{{- /*
Container security context
*/}}
{{- define "gitlab.containerSecurityContext" -}}
{{- if .Values.spec.securityContext }}
securityContext:
{{ toYaml .Values.spec.securityContext | indent 2 }}
{{- end }}
{{- end }}

{{- /*
Init container security context
*/}}
{{- define "gitlab.init.containerSecurityContext" -}}
{{- if .Values.spec.initSecurityContext }}
securityContext:
{{ toYaml .Values.spec.initSecurityContext | indent 2 }}
{{- end }}
{{- end }}

{{- /*
Pod security context
*/}}
{{- define "gitlab.podSecurityContext" -}}
{{- if .Values.spec.podSecurityContext }}
securityContext:
{{ toYaml .Values.spec.podSecurityContext | indent 2 }}
{{- end }}
{{- end }}

{{- /*
Automount service account token
*/}}
{{- define "gitlab.automountServiceAccountToken" -}}
automountServiceAccountToken: {{ .Values.spec.automountServiceAccountToken | default true }}
{{- end }}

{{- /*
Node selector
*/}}
{{- define "gitlab.nodeSelector" -}}
{{- if .Values.spec.nodeSelector }}
nodeSelector:
{{ toYaml .Values.spec.nodeSelector | indent 2 }}
{{- end }}
{{- end }}

{{- /*
Priority class name
*/}}
{{- define "gitlab.priorityClassName" -}}
{{- if .Values.spec.priorityClassName }}
priorityClassName: {{ .Values.spec.priorityClassName }}
{{- end }}
{{- end }}

{{- /*
HPA behavior
*/}}
{{- define "gitlab.hpa.behavior" -}}
{{- if .behavior }}
behavior:
{{ toYaml .behavior | indent 2 }}
{{- end }}
{{- end }}

{{- /*
HPA metrics
*/}}
{{- define "gitlab.hpa.metrics" -}}
{{- if .metrics }}
metrics:
{{ toYaml .metrics | indent 2 }}
{{- else }}
metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: {{ .cpuUtilization | default 70 }}
{{- end }}
{{- end }}

{{- /*
KEDA ScaledObject enabled check
*/}}
{{- define "gitlab.keda.scaledobject.enabled" -}}
{{- if .enabled }}true{{- else }}false{{- end }}
{{- end }}

{{- /*
KEDA ScaledObject spec
*/}}
{{- define "gitlab.keda.scaledobject.spec" -}}
{{- if .spec }}
{{ toYaml .spec }}
{{- end }}
{{- end }}
