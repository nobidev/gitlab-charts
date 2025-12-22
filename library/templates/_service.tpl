{{/*
Common Service template
Params:
  - root: $ (root context)
  - name: service name (string)
  - type: service type (ClusterIP, NodePort, LoadBalancer) - default ClusterIP
  - labels: additional labels (dict)
  - selectorLabels: selector labels (dict)
  - annotations: additional annotations (dict)
  - ports: list of port definitions (required)
  - clusterIP: cluster IP (optional, for ClusterIP type)
  - loadBalancerIP: load balancer IP (optional, for LoadBalancer type)
  - loadBalancerSourceRanges: source ranges for LB (optional)
  - externalTrafficPolicy: external traffic policy (optional)
  - allocateLoadBalancerNodePorts: whether to allocate node ports (optional)
  - externalIPs: external IPs list (optional)
  - sessionAffinity: session affinity (optional, e.g., "ClientIP")
  - sessionAffinityConfig: session affinity configuration (optional)

Port definition:
  - port: external port
  - targetPort: target port (name or number)
  - protocol: TCP/UDP (default TCP)
  - name: port name
  - nodePort: node port (optional, for NodePort type)
  - appProtocol: application protocol (optional, e.g., "http", "https")

Usage:
  {{- include "gitlab.lib.service" (dict 
       "root" $ 
       "name" "myapp"
       "type" "ClusterIP"
       "ports" (list 
         (dict "port" 8080 "targetPort" "http" "protocol" "TCP" "name" "http")
       )
       "selectorLabels" (include "myapp.selectorLabels" . | fromYaml)
     ) }}
*/}}
{{- define "gitlab.lib.service" -}}
{{- $root := .root -}}
{{- $name := .name | required "service name is required" -}}
{{- $type := .type | default "ClusterIP" -}}
{{- $labels := .labels | default dict -}}
{{- $selectorLabels := .selectorLabels | default dict -}}
{{- $annotations := .annotations | default dict -}}
{{- $ports := .ports | required "service ports are required" -}}
apiVersion: v1
kind: Service
metadata:
  name: {{ $name }}
  namespace: {{ $root.Release.Namespace }}
  labels:
    {{- include "gitlab.standardLabels" $root | nindent 4 }}
    {{- include "gitlab.commonLabels" $root | nindent 4 }}
    {{- include "gitlab.serviceLabels" $root | nindent 4 }}
    {{- with $labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  annotations:
    {{- include "gitlab.serviceAnnotations" $root | nindent 4 }}
    {{- with $annotations }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
spec:
  type: {{ $type }}
  {{- if and (eq $type "ClusterIP") .clusterIP }}
  clusterIP: {{ .clusterIP }}
  {{- end }}
  {{- if and (eq $type "LoadBalancer") .loadBalancerIP }}
  loadBalancerIP: {{ .loadBalancerIP }}
  {{- end }}
  {{- if and (eq $type "LoadBalancer") .loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
    {{- range .loadBalancerSourceRanges }}
    - {{ . | quote }}
    {{- end }}
  {{- end }}
  {{- if or (eq $type "NodePort") (eq $type "LoadBalancer") }}
  {{- with .externalTrafficPolicy }}
  externalTrafficPolicy: {{ . }}
  {{- end }}
  {{- end }}
  {{- if and (eq $type "LoadBalancer") (hasKey . "allocateLoadBalancerNodePorts") }}
  allocateLoadBalancerNodePorts: {{ .allocateLoadBalancerNodePorts }}
  {{- end }}
  {{- with .externalIPs }}
  externalIPs:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with .sessionAffinity }}
  sessionAffinity: {{ . }}
  {{- end }}
  {{- with .sessionAffinityConfig }}
  sessionAffinityConfig:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  ports:
    {{- range $ports }}
    - port: {{ .port | required "port number is required" }}
      targetPort: {{ .targetPort | required "targetPort is required" }}
      protocol: {{ .protocol | default "TCP" }}
      name: {{ .name | required "port name is required" }}
      {{- with .appProtocol }}
      appProtocol: {{ . }}
      {{- end }}
      {{- if and (eq $type "NodePort") .nodePort }}
      nodePort: {{ .nodePort | int64 }}
      {{- end }}
    {{- end }}
  selector:
    {{- include "gitlab.selectorLabels" $root | nindent 4 }}
    {{- with $selectorLabels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
{{- end -}}
