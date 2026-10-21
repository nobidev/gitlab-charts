---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Deploy the GitLab chart within an Istio service mesh
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Deploy the GitLab Helm chart in a Kubernetes cluster that uses an [Istio](https://istio.io/)
service mesh. Integrating GitLab with Istio provides advantages such as uniform
mutual TLS (mTLS) encryption across services, centralized Ingress routing,
traffic policies, and mesh-wide telemetry.

## Prerequisites

- A running Kubernetes cluster with Istio (version 1.19 or later recommended) installed.
- `kubectl` and `helm` CLIs installed and configured.
- Familiarity with Gateway API resources (`Gateway`, `HTTPRoute`, and `TCPRoute`) and Istio resources
  such as `DestinationRule` and `PeerAuthentication`.

## Sidecar injection

Istio uses Envoy sidecar proxies deployed alongside application containers to intercept and route network traffic.

Istio supports two sidecar models in Kubernetes:

- Native sidecars: Injected as init containers with `restartPolicy: Always`. The kubelet starts the
  proxy before application init containers and terminates it automatically when batch jobs complete.
  Native sidecars are enabled by default in Kubernetes 1.29 and later, and in Istio 1.27 and later.
- Standard sidecars: Injected as regular application containers in `spec.containers`. The kubelet
  does not manage their lifecycle relative to init containers, and the proxy continues running
  indefinitely after batch jobs complete unless manually terminated.

### Configure automatic injection

Enable automatic sidecar injection at the namespace level by labeling the namespace
where GitLab is installed:

```shell
kubectl label namespace gitlab istio-injection=enabled
```

Namespace-level injection is usually the simplest option. If you need to configure
Istio annotations on selected workloads, use each component's `annotations` value.
The chart does not have a `global.pod.annotations` value. To delay
application startup until the proxy is ready on Webservice and Sidekiq pods:

```yaml
gitlab:
  webservice:
    annotations:
      proxy.istio.io/config: '{ "holdApplicationUntilProxyStarts": true }'
  sidekiq:
    annotations:
      proxy.istio.io/config: '{ "holdApplicationUntilProxyStarts": true }'
```

### Manage init container network dependencies

GitLab workloads (such as `webservice` and `sidekiq`) use init containers (for example, `wait-for-deps`
and `dependencies`) to verify database, Redis, and object storage connectivity before the main application
starts.

With standard Istio sidecars (without Istio CNI), `istio-init` is appended after the chart's
init containers, so traffic redirection is not yet active while init containers like `dependencies`
run. However, with Istio CNI, traffic redirection is established at pod network setup before any init
containers run. Because `holdApplicationUntilProxyStarts` only delays regular application containers
(not init containers), init containers can fail to connect to external services before the proxy is ready.

Prefer native sidecars where supported. Kubernetes native sidecars are beta and enabled by default
from Kubernetes 1.29, and stable from Kubernetes 1.33; on Kubernetes 1.28 they require the
`SidecarContainers` feature gate. Istio 1.27 and later enables native sidecars by default when the
Kubernetes version supports them. With native sidecars, the proxy starts before application init
containers and is terminated when a job completes.

When using Istio CNI without native sidecars, if init containers must reach databases or services that
cannot be reached before the proxy starts, configure init container traffic exemptions such as
`traffic.sidecar.istio.io/excludeOutboundPorts` or `traffic.sidecar.istio.io/excludeOutboundIPRanges`.

### Handle batch jobs and migrations

Batch jobs, such as database migrations (`gitlab-migrations`), pre-upgrade validation (`upgradeCheck`),
and certificate or secret generators (`shared-secrets`), run to completion and exit.

Native sidecars are the recommended way to handle batch jobs in an Istio mesh. Because the Kubernetes
kubelet manages sidecar lifecycles, the `istio-proxy` shuts down automatically when the job's main
container exits. This allows all jobs to reach the `Completed` state while remaining inside the mesh
under strict mTLS.

When using standard sidecars without native sidecar support, the `istio-proxy` container continues
running indefinitely after the primary job container exits. As a result, the job does not transition to
the `Completed` state, which causes Helm installations or upgrades to time out.

If you must run standard sidecars, disable injection on jobs that expose pod annotations in chart values:

```yaml
gitlab:
  migrations:
    podAnnotations:
      sidecar.istio.io/inject: "false"
  toolbox:
    annotations:
      sidecar.istio.io/inject: "false"

shared-secrets:
  annotations:
    sidecar.istio.io/inject: "false"

upgradeCheck:
  annotations:
    sidecar.istio.io/inject: "false"

registry:
  annotations:
    sidecar.istio.io/inject: "false"
```

The migration pod setting is `gitlab.migrations.podAnnotations`. `upgradeCheck.annotations` is
especially important because `gitlab-upgrade-check` is an enabled-by-default `pre-upgrade` hook.
`shared-secrets.annotations` applies to self-signed certificate generation jobs.

`registry.annotations` and `gitlab.toolbox.annotations` apply chart-wide to all registry
and toolbox pods, including their primary deployments. Disabling injection on those values pulls the
registry and toolbox out of the mesh entirely, which can cause communication failures (such as toolbox
backups failing to reach Gitaly) when strict mTLS is enforced mesh-wide. The chart also does not expose
per-pod annotation values for the `certmanager-issuer` job. For these reasons, native sidecars are
strongly preferred over manual exemptions.

## Mutual TLS configuration

Istio provides mTLS between workloads in the mesh using the `PeerAuthentication` resource.

### Permissive and strict mTLS modes

When initially deploying GitLab within an Istio mesh, configure `PERMISSIVE` mTLS mode to verify
that all services connect successfully:

```yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: gitlab-mtls
  namespace: gitlab
spec:
  mtls:
    mode: PERMISSIVE
```

After validating connectivity, you can enforce `STRICT` mode. However, ensure that health check
probes and external dependencies are accounted for before switching to strict mTLS.

### Health probes

Kubernetes kubelet health check probes originate from the cluster nodes, not from within the mesh.
By default, Istio automatically rewrites application HTTP probes (`rewriteAppHTTPProbe: true`) so that
the kubelet can reach health endpoints without failing mTLS checks.

If probe rewriting is disabled in your Istio profile, you must either exclude the probe ports from mTLS
or maintain `PERMISSIVE` mode for workloads that expose health checks.

### External services

If you use external PostgreSQL, external Redis, or external object storage that terminate standard TLS
independently of Istio, configure an Istio `DestinationRule` to disable Istio mutual TLS for those endpoints:

```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: external-database
  namespace: gitlab
spec:
  host: postgres.example.internal
  trafficPolicy:
    tls:
      mode: DISABLE
```

## Component protocol and port configurations

Several GitLab components require specific port or protocol handling in Istio.

### GitLab Shell for SSH

GitLab Shell handles Git over SSH. The chart Service exposes port 22 and forwards it to the pod's
target port 2222.

To configure GitLab Shell with Istio:

1. Configure the Gateway listener for raw TCP on port 22. SSH uses raw TCP, not HTTP.
1. Route gateway port 22 to the GitLab Shell Service port 22. The Service forwards traffic to target port 2222 on the pod.
1. Do not exclude port 2222 from inbound traffic capture (`traffic.sidecar.istio.io/excludeInboundPorts`). With Istio auto-mTLS enabled, excluding the port can break SSH connections through the gateway.

### GitLab Workhorse and Webservice

GitLab Workhorse acts as the reverse proxy fronting the Puma application server. In the default
chart configuration, Workhorse and Puma run in the same pod (`webservice`) and communicate over a
local UNIX socket or loopback TCP (`127.0.0.1:8080`), which bypasses the Envoy sidecar proxy.
Workhorse receives external inbound HTTP traffic on port 8181.

To configure an Istio gateway for Workhorse:

1. Ensure the gateway does not restrict request payload sizes or time out prematurely. Git operations
   (such as `git push` with large repositories or Git LFS objects) can send large request bodies.
1. Configure route timeouts appropriate for your workload. Long-running Git operations and streaming
   requests must not be interrupted by gateway timeouts. Istio disables route timeouts by default.
   If you set one, use a valid duration such as `3600s`.

### GitLab KAS for Kubernetes Agent

GitLab KAS (Kubernetes Agent Server) uses two distinct protocols:

- Port 8150 (agent communication): Uses gRPC for bi-directional communication with cluster agents (`agentk`),
  and also serves WebSocket traffic when routed externally.
- Port 8154 (Kubernetes API proxy): Uses HTTP/1.1 and WebSockets to proxy `kubectl` requests.

To configure Istio routing for KAS:

1. Preserve the chart's `tcp-` service port names. Do not force the port to `GRPC`, because the endpoint
   also serves WebSocket traffic. Use `gitlab.kas.service.appProtocol` if your provider requires an
   application protocol hint.
1. Enable WebSocket upgrades on the HTTP routing rules for port 8154.

Because KAS port 8150 also serves WebSocket traffic, review the
[KAS Gateway API guidance](../charts/gitlab/kas/_index.md) before overriding route or protocol
settings for Istio.

## Gateway configuration

In GitLab chart 19.0 and later, Gateway API and the bundled Envoy Gateway are enabled by default. To use an
Istio-managed Gateway API provider and avoid running a second gateway stack, disable the bundled Envoy Gateway
and point the chart at the externally managed Gateway. For provider requirements, see the chart's
[external Gateway API provider guide](gateway-api/_index.md#using-an-external-gateway-api-provider).
The Gateway API example below assumes Istio has Gateway API support
enabled and that its Gateway has listeners matching the chart routes.

### Disable legacy Ingress resources

If you are using legacy Ingress resources instead of Gateway API, disable the bundled NGINX
controller and chart Ingress resources in your Helm values:

```yaml
global:
  ingress:
    enabled: false

nginx-ingress:
  enabled: false
```

### Configure an Istio Gateway API Gateway

#### Prerequisites

- Install the Kubernetes Gateway API CRDs version 1.6 or later (for example,
  `kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.6.2/standard-install.yaml`).
  Istio does not install the Gateway API CRDs automatically, and setting `installEnvoy: false`
  prevents the GitLab chart from installing them. The GitLab chart renders `TCPRoute` using
  `gateway.networking.k8s.io/v1`, which requires Gateway API 1.6 or later.
- The Gateway API provider must support the GitLab chart's HTTPRoute and TCPRoute resources.
  See the [external Gateway API provider requirements](gateway-api/_index.md#using-an-external-gateway-api-provider).
- The TLS certificate secret (for example, `gitlab-tls-cert`) must exist in the Gateway's namespace
  (commonly `istio-system`).

#### Create the Gateway

The chart renders HTTPRoute and TCPRoute resources that attach to the external Gateway referenced by
`global.gatewayApi.gatewayRef`. Configure the Istio Gateway with an HTTPS listener for GitLab Web
and a TCP listener named `gitlab-ssh` on port 22 for GitLab Shell.

The following example includes only GitLab Web and SSH listeners. Add listeners for every other
enabled chart route, or disable components and routes you do not use:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: istio-gateway
  namespace: istio-system
spec:
  gatewayClassName: istio
  listeners:
    - name: gitlab-web
      hostname: gitlab.example.com
      port: 443
      protocol: HTTPS
      tls:
        mode: Terminate
        certificateRefs:
          - kind: Secret
            name: gitlab-tls-cert
      allowedRoutes:
        namespaces:
          from: All
    - name: gitlab-ssh
      port: 22
      protocol: TCP
      allowedRoutes:
        namespaces:
          from: All
```

The chart's HTTP and SSH routes attach to these listeners using their default section names. If
your listener names differ, configure the relevant component's `gatewayRoute.sectionName` value.

## Example values configuration

The following `values.yaml` snippet summarizes the recommended Helm configuration for deploying
GitLab with an Istio service mesh when native sidecars are enabled:

```yaml
global:
  ingress:
    enabled: false
  gatewayApi:
    enabled: true
    installEnvoy: false
    configureCertmanager: false
    gatewayRef:
      name: istio-gateway
      namespace: istio-system

nginx-ingress:
  enabled: false

gitlab:
  gitlab-shell:
    annotations:
      proxy.istio.io/config: '{ "holdApplicationUntilProxyStarts": true }'
  webservice:
    annotations:
      proxy.istio.io/config: '{ "holdApplicationUntilProxyStarts": true }'
  sidekiq:
    annotations:
      proxy.istio.io/config: '{ "holdApplicationUntilProxyStarts": true }'
```

If your cluster does not support native sidecars, add the job injection exemptions described in
[Handle batch jobs and migrations](#handle-batch-jobs-and-migrations) and verify that mesh mTLS policies
permit traffic from workloads excluded from the mesh.

## Troubleshooting

### Migrations job does not terminate

The `gitlab-migrations` pod reaches 1/2 containers completed, but the pod never finishes and Helm times out.
This issue occurs when the `istio-proxy` sidecar container remains running after the database migration task exits.

Prefer native sidecars so hook jobs complete when their main container exits without excluding them from the mesh.
With standard sidecars, disable injection using `gitlab.migrations.podAnnotations."sidecar.istio.io/inject": "false"`;
use `shared-secrets.annotations`, `upgradeCheck.annotations`, and `registry.annotations` for their respective jobs.
The chart does not expose a per-pod injection annotation for `certmanager-issuer`; disable the issuer hook if
your deployment does not need it, or use native sidecars if it must run in the injected namespace.

### Database connectivity errors in init containers

The `wait-for-deps` or `dependencies` containers fail with `connection refused` or timeout errors when connecting to PostgreSQL or Redis.
This occurs primarily with Istio CNI, where traffic redirection is configured before init containers
run, while `istio-proxy` has not yet started. `holdApplicationUntilProxyStarts` only orders regular
containers and does not delay init containers. Without Istio CNI, `istio-init` runs after the chart's
init containers, so init container connectivity is typically unaffected.

Use native sidecars so the proxy starts before init containers. If using Istio CNI with standard
sidecars, exempt required database and dependency ports from outbound redirection (using
`traffic.sidecar.istio.io/excludeOutboundPorts`) on affected workloads.

### Git over SSH connection failures

Git operations such as `git clone git@gitlab.example.com:...` fail with `Connection reset by peer` or protocol mismatch errors.
This can occur when the gateway does not expose raw TCP for SSH, or when traffic is sent to the
wrong port. The GitLab Shell Service port is 22; its target port is 2222.

Ensure the external Gateway exposes a TCP listener on port 22 and that its `allowedRoutes` permits
the GitLab namespace. Do not exclude port 2222 from inbound capture as a general workaround; with
auto-mTLS, that can break SSH through the gateway.

### Git push fails with large files

A `git push` command fails with HTTP 413 or HTTP 504 during large file transfers or LFS uploads.
This issue occurs when Envoy proxy route timeout or buffer size limits are exceeded.

Istio route timeouts are disabled by default. If you configure a timeout, choose a valid duration
long enough for the operation (for example, `3600s`); `0s` is not accepted by Istio. Configure the
gateway's request-body limits if they are lower than the size of the Git operation or LFS upload.
