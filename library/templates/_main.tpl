{{- /*
Main entry point for gitlab-base library chart.
This template bridges the Runway manifest format to the gitlab.lib.* templates.
*/}}
{{- define "gitlab-base" }}
{{ include "gitlab-base.namespace" . }}
---
{{ include "gitlab-base.pdb" . }}
---
{{ include "gitlab-base.deployment" . }}
---
{{ include "gitlab-base.service" . }}
{{- include "gitlab-base.serviceMetrics" . }}
---
{{ include "gitlab-base.serviceAccount" . }}
---
{{ include "gitlab-base.vpa" . }}
{{- if .Values.spec.scalability }}
---
{{ include "gitlab-base.hpa" . }}
{{- end }}
{{- end -}}

{{- /*
Deployment wrapper that calls gitlab.lib.deployment with proper parameters
*/}}
{{- define "gitlab-base.deployment" -}}
{{- $podSpec := include "gitlab-base.podSpec" . -}}
{{- include "gitlab.lib.deployment" (dict 
    "root" .
    "name" (include "gitlab.serviceName" .)
    "chart" .Chart.Name
    "podSpec" $podSpec
  ) -}}
{{- end -}}

{{- /*
Namespace template for Runway services
*/}}
{{- define "gitlab-base.namespace" -}}
apiVersion: v1
kind: Namespace
metadata:
  name: {{ include "gitlab.serviceName" . }}
  labels:
    istio-injection: enabled
{{- end -}}

{{- /*
Pod spec template for Runway services
*/}}
{{- define "gitlab-base.podSpec" -}}
metadata:
  labels:
    {{- include "gitlab.selectorLabels" . | nindent 4 }}
spec:
  securityContext:
    fsGroup: 65533
    runAsUser: 100
  terminationGracePeriodSeconds: 60
  serviceAccountName: {{ include "gitlab.serviceName" . }}
  automountServiceAccountToken: false
  containers:
  - name: app
    image: {{ .Values.spec.image | quote }}
    imagePullPolicy: Always
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      privileged: false
      readOnlyRootFilesystem: true
      runAsNonRoot: true
{{- if .Values.spec.command }}
    command: {{ toJson .Values.spec.command }}
{{- end }}
    env:
      - name: PORT
        value: {{ .Values.spec.container_port | default 8080 | quote }}
      - name: TMPDIR
        value: "/tmp"
{{- range $k, $v := .Values.spec.environment | default dict }}
      - name: {{ $k }}
        value: {{ $v | quote }}
{{- end }}
    resources:
{{- if .Values.spec.resources }}
{{ toYaml .Values.spec.resources | indent 6 }}
{{- else }}
      requests:
        cpu: "500m"
        memory: "512Mi"
      limits:
        cpu: "1000m"
        memory: "1Gi"
{{- end }}
{{- with .Values.spec.startup_probe }}
    startupProbe:
      httpGet:
        path: {{ .path | quote }}
        port: {{ $.Values.spec.container_port | default 8080 }}
      initialDelaySeconds: {{ .period_seconds | default 10 }}
      timeoutSeconds: {{ .timeout_seconds | default 1 }}
      periodSeconds: {{ .period_seconds | default 10 }}
      failureThreshold: {{ .failure_threshold | default 3 }}
{{- end }}
{{- with .Values.spec.liveness_probe }}
    livenessProbe:
      httpGet:
        path: {{ .path | quote }}
        port: {{ $.Values.spec.container_port | default 8080 }}
      initialDelaySeconds: {{ .period_seconds | default 10 }}
      timeoutSeconds: {{ .timeout_seconds | default 1 }}
      periodSeconds: {{ .period_seconds | default 10 }}
      failureThreshold: {{ .failure_threshold | default 3 }}
{{- end }}
    ports:
      - name: http
        containerPort: {{ .Values.spec.container_port | default 8080 }}
    volumeMounts:
      - name: "tmp"
        mountPath: "/tmp"
  volumes:
    - name: "tmp"
      emptyDir:
        sizeLimit: 128Mi
{{- end -}}

{{- /*
Service template for Runway services
*/}}
{{- define "gitlab-base.service" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "gitlab.serviceName" . }}
  namespace: {{ include "gitlab.serviceName" . }}
  labels:
    {{- include "gitlab.standardLabels" . | nindent 4 }}
spec:
  type: ClusterIP
  ports:
    - port: {{ .Values.spec.container_port | default 8080 }}
      targetPort: {{ .Values.spec.container_port | default 8080 }}
      protocol: TCP
      name: http
  selector:
    {{- include "gitlab.selectorLabels" . | nindent 4 }}
{{- end -}}

{{- /*
ServiceAccount template for Runway services
*/}}
{{- define "gitlab-base.serviceAccount" -}}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ include "gitlab.serviceName" . }}
  namespace: {{ include "gitlab.serviceName" . }}
  labels:
    {{- include "gitlab.standardLabels" . | nindent 4 }}
{{- end -}}

{{- /*
HPA template for Runway services
*/}}
{{- define "gitlab-base.hpa" -}}
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: {{ include "gitlab.serviceName" . }}
  namespace: {{ include "gitlab.serviceName" . }}
  labels:
    {{- include "gitlab.standardLabels" . | nindent 4 }}
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "gitlab.serviceName" . }}
  minReplicas: {{ .Values.spec.scalability.min_instances | default 1 }}
  maxReplicas: {{ .Values.spec.scalability.max_instances | default 10 }}
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: {{ .Values.spec.scalability.cpu_utilization | default 70 }}
{{- end -}}

{{- /*
PodDisruptionBudget template for Runway services
*/}}
{{- define "gitlab-base.pdb" -}}
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: {{ include "gitlab.serviceName" . }}
  namespace: {{ include "gitlab.serviceName" . }}
  labels:
    {{- include "gitlab.standardLabels" . | nindent 4 }}
spec:
  maxUnavailable: {{ .Values.spec | dig "scalability" "max_unavailable" 1 }}
  selector:
    matchLabels:
      {{- include "gitlab.selectorLabels" . | nindent 6 }}
{{- end -}}

{{- /*
Metrics Service template for Runway services
Creates a service exposing metrics ports based on observability.scrape_targets
*/}}
{{- define "gitlab-base.serviceMetrics" -}}
{{- $targets := dig "observability" "scrape_targets" (list) .Values.spec }}
{{- if ne (len $targets) 0 }}
---
apiVersion: v1
kind: Service
metadata:
  name: metrics
  namespace: {{ include "gitlab.serviceName" . }}
  labels:
    {{- include "gitlab.standardLabels" . | nindent 4 }}
spec:
  selector:
    {{- include "gitlab.selectorLabels" . | nindent 4 }}
  type: ClusterIP
  ports:
  {{- range $i, $target := $targets }}
    {{- $hostPort := splitList ":" $target }}
    {{- if eq (len $hostPort) 2 }}
      {{- $port := index $hostPort 1 }}
      - name: {{ printf "metrics-%d" $i | quote }}
        port: {{ $port | int }}
        targetPort: {{ $port | int }}
        protocol: TCP
    {{- end }}
  {{- end }}
{{- end }}
{{- end -}}

{{- /*
VerticalPodAutoscaler template for Runway services
*/}}
{{- define "gitlab-base.vpa" -}}
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: {{ include "gitlab.serviceName" . }}
  namespace: {{ include "gitlab.serviceName" . }}
  labels:
    {{- include "gitlab.standardLabels" . | nindent 4 }}
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: {{ include "gitlab.serviceName" . }}
  updatePolicy:
    updateMode: "Initial"
    minReplicas: {{ .Values.spec | dig "scalability" "min_instances" 1 }}
  resourcePolicy:
    containerPolicies:
      - containerName: "*"
        controlledResources: ["memory"]
        controlledValues: "RequestsAndLimits"
        maxAllowed:
          memory: {{ .Values.spec | dig "resources" "limits" "memory" "1Gi" }}
{{- end -}}
