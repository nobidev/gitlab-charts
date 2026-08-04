{{/*
Return the string 'PROXY'

The string 'PROXY' ensures the use of ProxyProtocol decoding in a TCP service.
This string is exactly compared with the string 'PROXY' when using nginx-ingress (in capital letters).
See: https://kubernetes.github.io/ingress-nginx/user-guide/exposing-tcp-udp-services/
*/}}
{{- define "gitlab.shell.tcp.proxyProtocol" -}}
{{- $inbound := "" -}}
{{- if .Values.global.shell.tcp.proxyProtocol -}}
{{-   $inbound = "PROXY" -}}
{{- end -}}
{{- $outbound := "" -}}
{{- if eq "true" (include "gitlab.shell.proxyProtocol.outbound" .) -}}
{{-   $outbound = "PROXY" -}}
{{- end -}}
:{{ $inbound }}:{{ $outbound }}
{{- end -}}

{{/*
Returns "true" if GitLab Shell can accept PROXY headers on the outbound leg
(the proxy-to-Shell connection). Used by the NGINX/HAProxy TCP configs and the
Envoy BackendTrafficPolicy. Independent of global.shell.tcp.proxyProtocol, which
controls the inbound leg.

Only gitlab-sshd can parse PROXY v2 headers (via its proxy_protocol listener
option). OpenSSH has no PROXY protocol support and will misread the binary
header as an SSH version string, breaking the handshake. Within gitlab-sshd,
proxy_protocol must be explicitly enabled (config.proxyProtocol: true) and
proxyPolicy must not be "reject" — without proxy_protocol: true the listener
does not wrap itself in the proxyproto parser, so proxyPolicy is inert.
*/}}
{{- define "gitlab.shell.proxyProtocol.outbound" -}}
{{- if and (eq .Values.sshDaemon "gitlab-sshd") .Values.config.proxyProtocol (not (eq .Values.config.proxyPolicy "reject")) -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}
