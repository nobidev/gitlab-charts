---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configure Gateway API and Envoy Gateway extensions
---

GitLab chart supports Gateway API and bundles [Envoy Gateway](https://gateway.envoyproxy.io/) as one available provider.
Since GitLab 19.0, GitLab chart defaults to Gateway API with the bundled Envoy Gateway chart. NGINX Ingress is deprecated
but remains available until its full removal in GitLab 20.0.

## Global configuration

| Name                                                |  Type   | Default        | Description |
|:----------------------------------------------------|:-------:|:---------------|:------------|
| `global.gatewayApi.enabled`                         | Boolean | true           | Enable deployment of GatewayAPI resources. Default flipped to `true` in GitLab 19.0. |
| `global.gatewayApi.configureCertmanager`            | Boolean | true           | Configure cert-manager to get certificates from Let's Encrypt via a Gateway API HTTP-01 solver. Requires `certmanager-issuer.email`. |
| `global.gatewayApi.gatewayRef.name`                 | String  |                | Gateway name rendered to all Gateway API resources. Use this to reference an externally managed Gateway and to disable the Gateway provided by the chart. |
| `global.gatewayApi.gatewayRef.namespace`            | String  |                | Gateway namespace rendered to all Gateway API resources. Use this to reference an externally managed Gateway in another namespace and to disable the Gateway provided by the chart. |
| `global.gatewayApi.httpToHttpsRedirect`             | Boolean | true           | Create an HTTPRoute that redirects all HTTP traffic to HTTPS with a 301 status code. Only effective when `protocol` is `HTTPS` and the Gateway is managed (no `gatewayRef`). |
| `global.gatewayApi.installEnvoy`                    | Boolean | true           | Install Envoy Gateway subchart and configure a `GatewayClass` and [Envoy Gateway API extensions](../../charts/envoygateway/_index.md). Default flipped to `true` in GitLab 19.0. |

### Configuring managed Gateway API resources

GitLab chart allows you to customize the managed `Gateway`, `GatewayClass`, and Envoy Gateway extensions.

| Name                           |  Type   | Default        | Description |
|:-------------------------------|:-------:|:---------------|:------------|
| `gatewayApiResources.class.name`                   | String  | `gitlab-gw`    | Name of the Gateway class bound to the Gateway. |
| `gatewayApiResources.class.controllerName`         | String  | `gateway.envoyproxy.io/gitlab-gatewayclass-controller` | Controller name of the GatewayClass. |
| `gatewayApiResources.gateway.addresses`            | Array   | false          | Array of addresses to be added to the Gateway. |
| `gatewayApiResources.gateway.protocol`             | String  | `HTTPS`        | Default listener protocol. |
| `gatewayApiResources.gateway.annotations`          | Map     | `{}`           | Annotations to add to the managed Gateway. |
| `gatewayApiResources.gateway.infrastructure`       | Object  | `{}`           | [GatewayInfrastructure](https://gateway-api.sigs.k8s.io/reference/spec/#gatewayinfrastructure) added to the managed Gateway. |
| `gatewayApiResources.gateway.listeners`            | Object  |                | Listener configuration for the managed Gateway. See below for an example. |

#### Listener configuration

The default listener config only specifies a protocol for listeners with
a predefined protocol. Listeners where the protocol depends on your setup
inherit the root level protocol:

```yaml
protocol: HTTPS
listeners:
  http-default:
    protocol: HTTP
  gitlab-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: gitlab-tls
  gitlab-web-geo:
    tls:
      mode: Terminate
      certificateRefs:
        - name: gitlab-web-geo-tls
  gitlab-smartcard-web:
    protocol: ""
    tls:
      mode: Terminate
      certificateRefs:
        - name: gitlab-smartcard-tls
  gitlab-ssh:
    protocol: "TCP"
  registry-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: registry-tls
  pages-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: pages-tls
  kas-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: kas-tls
  kas-workspaces-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: kas-workspaces-tls
  openbao-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: openbao-tls
```

#### Envoy Gateway extensions

If the bundled Envoy Gateway is used, you can customize the `EnvoyProxy` and optionally create a `ClientTrafficPolicy`
and a `SecurityPolicy` bound to the managed `Gateway`.

| Name                                                |  Type   | Default        | Description |
|:----------------------------------------------------|:-------:|:---------------|:------------|
| `gatewayApiResources.envoy.proxySpec`               | Object  | see values     | `EnvoyProxy` specification. Only enabled if `global.gatewayApi.installEnvoy` is true.|
| `gatewayApiResources.envoy.clientTrafficPolicySpec` | Object  | see values     | Envoy's `ClientTrafficPolicy` specification. Only enabled if `global.gatewayApi.installEnvoy` is true.|
| `gatewayApiResources.envoy.securityPolicySpec`      | Object  | see values     | Envoy's `SecurityPolicy` specification. Only enabled if `global.gatewayApi.installEnvoy` is true.|

#### Envoy Gateway metrics

The bundled Prometheus is set up to collect metrics from both Envoy Gateway and the managed
Envoy Proxy. If you have Prometheus Operator custom resource definitions (CRDs) enabled,
a ServiceMonitor will be created for Envoy Gateway and a PodMonitor will be created for Envoy Proxy.

```yaml
gatewayApiResources:
  envoy:
    metrics:
      envoyGateway:
        serviceMonitor:
          enabled: false
          additionalLabels: {}
          endpointConfig: {}
      envoyProxy:
        podMonitor:
          enabled: false
          additionalLabels: {}
          endpointConfig: {}
```

#### Route configuration

The Webservice, KAS, Registry, and GitLab Pages are exposed via an `HTTPRoute` while GitLab Shell
is exposed via a `TCPRoute`. The routes can be customized at the chart level:

```yaml
subchart:
  gatewayRoute:
    # Enable/disable this route, defaults to `global.gatewayApi.enabled`.
    enabled: true
    # Gateway section, defaults to matching listener.
    sectionName: "section"
    # Gateway reference, defaults to managed Gateway or globally configured external Gateway.
    gatewayName: "gateway"
    gatewayNamespace: "release-namespace"
    # Extra annotations
    annotations: {}
    # Timeout configuration
    timeouts:
      request: 15s
      backendRequest: 15s
    # Gateway API filters applied to the route rules
    filters: []
```

Timeouts are supported on all routes except KAS (which uses a `BackendTrafficPolicy` for its
GRPC/WSS requirements). Filters are supported on all `HTTPRoute` resources.

The `filters` field accepts a list of
[Gateway API HTTPRouteFilter](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPRouteFilter)
objects. Common filter types include `RequestHeaderModifier`, `ResponseHeaderModifier`,
`RequestRedirect`, `URLRewrite`, and `RequestMirror`.

Header sanitization example:

```yaml
registry:
  gatewayRoute:
    filters:
    - type: ResponseHeaderModifier
      responseHeaderModifier:
        set:
        - name: X-Content-Type-Options
          value: nosniff
        remove:
        - X-Powered-By
```

If you configure multiple webservice deployments, the route rules (including filters) can be
customized per rule. Check the [Webservice Gateway API documentation](../../charts/gitlab/webservice/_index.md#gateway-api)
for details.

#### HTTP-only mode

To expose GitLab over HTTP (for example, when TLS is terminated upstream), set the chart-managed
Gateway to HTTP:

```yaml
global:
  hosts:
    https: false
gatewayApiResources:
  gateway:
    protocol: HTTP
```

When the bundled Envoy Gateway is used, also configure `KeepUnchanged` on the gateway-wide
`ClientTrafficPolicy`:

```yaml
gatewayApiResources:
  envoy:
    clientTrafficPolicySpec:
      path:
        escapedSlashesAction: KeepUnchanged
```

This is required because when multiple HTTP listeners share the same port, Envoy Gateway does
not accept section-scoped `ClientTrafficPolicy` resources that the chart renders for HTTPS.
As a result, the escaped-slash handling must be configured globally.

### TLS between Gateway and backend services

When TLS is enabled on a backend service (Webservice, KAS, or Registry), the chart creates a
`BackendTLSPolicy` resource that instructs the Gateway to establish a TLS connection.

Unlike the NGINX Ingress implementation, where certificate verification can be disabled (for
example with `workhorse.tls.verify: false` for self-signed certificates), Gateway API always
verifies the backend TLS connection. A CA certificate secret must therefore be provided for
verification to succeed.

#### Enable internal TLS for Webservice

Backend TLS for Webservice requires
[Workhorse TLS](../../charts/gitlab/webservice/_index.md#gitlab-workhorse) to be enabled globally.
The validation hostname defaults to the service DNS name (`<service-name>.<namespace>.svc`) and
can be overridden with `webservice.backendTLSPolicy.hostname`:

```yaml
global:
  workhorse:
    tls:
      enabled: true
gitlab:
  webservice:
    workhorse:
      tls:
        enabled: true
        caSecretName: workhorse-tls-ca
    backendTLSPolicy:
      hostname: workhorse.example.internal
```

For information on configuring optional deployment-level overrides, see the
[Webservice Gateway API documentation](../../charts/gitlab/webservice/_index.md#tls-between-gateway-and-workhorse).

#### Enable internal TLS for GitLab Relay (KAS)

Backend TLS for KAS is controlled by `global.kas.tls.enabled`. The validation hostname defaults
to the service DNS name (`<service-name>.<namespace>.svc`) and can be overridden with
`kas.backendTLSPolicy.hostname`:

> [!warning]
> GitLab Workspaces does not yet support internal TLS. If you use Workspaces,
> do not enable internal TLS for GitLab Relay because it will cause protocol and TLS errors.

```yaml
global:
  kas:
    tls:
      enabled: true
      caSecretName: kas-tls-ca
gitlab:
  kas:
    backendTLSPolicy:
      hostname: kas.example.internal
```

#### Enable internal TLS for Registry

Backend TLS for Registry is controlled by `registry.tls.enabled`. The validation hostname defaults
to the service DNS name (`<service-name>.<namespace>.svc`) and can be overridden with
`registry.backendTLSPolicy.hostname`:

```yaml
global:
  hosts:
    registry:
      protocol: https
registry:
  tls:
    enabled: true
    caSecretName: registry-tls-ca
  backendTLSPolicy:
    hostname: registry.example.internal
```

### GitLab Geo

To configure [GitLab Geo](https://docs.gitlab.com/administration/geo/) using the Gateway API, an
additional hostname can be configured by setting `global.geo.gatewayApi.additionalHostname`.

The flag should be set to the internal URL on primary sites and to the external/unified
URL on secondary sites. Check the [Geo setup guide](../geo/_index.md) for more
information.

### Using an external Gateway API provider

The chart can be configured to use an external Gateway API provider, but not every provider meets
the requirements to expose GitLab. The chart is only tested with the bundled Envoy Gateway. Support
for other providers is offered on a best-effort basis and we welcome contributions that document
working configurations with other Gateway API providers.

There are two ways to opt out of the bundled Envoy Gateway:

- Set `global.gatewayApi.installEnvoy: false` to skip the Envoy Gateway subchart and Envoy-specific
  custom resources. The chart still renders the `Gateway`, route resources, and any
  `BackendTLSPolicy` resources. You provide the `GatewayClass`.
- Set `global.gatewayApi.gatewayRef.name` and `global.gatewayApi.gatewayRef.namespace` to reference
  an externally managed `Gateway`. The chart skips the managed `Gateway` and all listener
  configuration. You provide the `Gateway`, its listeners, and the `GatewayClass`.

The two options can be combined. For more information, see the
[configuration recipes](#configuration-recipes).

#### Requirements

The provider must support the following standard Gateway API resources and features:

- `Gateway`, `HTTPRoute`, and `BackendTLSPolicy` from `gateway.networking.k8s.io/v1`.
- `TCPRoute` from `gateway.networking.k8s.io/v1alpha2` (for the GitLab Shell SSH listener). Skip
  this if `gitlab-shell.enabled` is `false`.
- `RegularExpression` path matches on `HTTPRoute` (Webservice uses these for long-running Git
  over HTTP paths: `^/.*/ssh-receive-pack$` and `^/.*/ssh-upload-pack$`).
- The `RequestRedirect` filter on `HTTPRoute` if you rely on the chart-managed HTTP-to-HTTPS
  redirect (only rendered for a chart-managed `Gateway`).

In addition, your provider must be configured for the following behaviors that the Gateway API
specification leaves implementation-defined:

- **Preserve URL-encoded forward slashes (`%2F`) in request paths.** GitLab APIs commonly identify
  projects with a URL-encoded path (for example, `/api/v4/projects/group%2Fproject`). If the
  provider unescapes or rejects these requests, the GitLab API will not work. With the bundled
  Envoy Gateway, the chart sets `path.escapedSlashesAction: KeepUnchanged` on a `ClientTrafficPolicy`
  for the `gitlab-web`, `gitlab-web-geo`, and `gitlab-smartcard-web` listeners. Other providers
  need an equivalent configuration on the listeners that serve GitLab API traffic.
- **Cross-serve HTTP/1.1 and gRPC (HTTP/2) on the GitLab Relay (KAS) hostname.** KAS exposes both
  gRPC and HTTP (including WebSocket) endpoints on the same hostname and port. With the bundled
  Envoy Gateway, the chart sets `useClientProtocol: true` on a `BackendTrafficPolicy`. Other
  providers must forward gRPC as HTTP/2 to the backend while still accepting HTTP/1.1 from clients.
- **Smartcard mutual TLS** (if `global.appConfig.smartcard.enabled` is `true`). The provider must
  validate client certificates on the smartcard listener and forward the certificate to Workhorse
  in the `X-Forwarded-Client-Cert` header (the bundled Envoy Gateway configures this through a
  `ClientTrafficPolicy`).

If you use `global.gatewayApi.configureCertmanager`, the cert-manager installation in the cluster
must have [Gateway API support enabled](https://cert-manager.io/docs/usage/gateway/#enabling-gateway-api-support),
independent of which Gateway API provider you choose. cert-manager solves HTTP-01
challenges by attaching an `HTTPRoute` to a `Gateway`, so your `Gateway` must expose an HTTP
listener that cert-manager can route challenges through.

This list of requirements is not exhaustive and providers may surface additional requirements in practice.
If you get GitLab working on another Gateway API provider, please contribute updates to this documentation.

#### Additional requirements

The behaviors described under [Requirements](#requirements) are
configured automatically when the bundled Envoy Gateway is installed (`installEnvoy: true`). When
it is disabled, the chart skips its Envoy-specific custom resources and you become responsible for
configuring the equivalent behavior on your provider:

- Preserving escaped slashes.
- Cross-serving HTTP and HTTP/2 for KAS.
- Smartcard mutual TLS, if applicable.

When `global.gatewayApi.gatewayRef` is set, the chart additionally skips the managed `Gateway` and
everything attached to it. You are responsible for:

- Exposing listeners on your external `Gateway` that the chart's routes can attach to. Routes
  attach by `sectionName`; the defaults match the listener names in the
  [example listener configuration](#listener-configuration) (`gitlab-web`, `gitlab-web-geo`,
  `gitlab-smartcard-web`, `registry-web`, `pages-web`, `kas-web`, `kas-workspaces-web`,
  `gitlab-ssh`, `openbao-web`). Each sub-chart accepts a `gatewayRoute.sectionName` override if
  your listener names differ.
- Configuring an HTTP-to-HTTPS redirect on your `Gateway` if you need one. The
  `global.gatewayApi.httpToHttpsRedirect` flag only applies to the chart-managed `Gateway`.
- Annotating your `Gateway` for TLS certificates. The chart still creates a cert-manager `Issuer`
  when `global.gatewayApi.configureCertmanager` is `true`, but it does not annotate your
  externally managed `Gateway`. Add `cert-manager.io/issuer: RELEASE-gw-issuer` (replacing
  `RELEASE` with your Helm release name) to your `Gateway` to reuse the Issuer, or manage TLS
  certificates yourself.

#### Configuration recipes

##### Use an externally managed Gateway

To use an external `Gateway` instead of the chart-managed one, disable Envoy Gateway and point at
your `Gateway`:

```yaml
global:
  gatewayApi:
    enabled: true
    # Skip the Envoy Gateway subchart and Envoy-specific custom resources.
    installEnvoy: false
    gatewayRef:
      name: "custom-gateway"
      namespace: "custom-gateway-namespace"
```

##### Use the chart-managed Gateway with an external GatewayClass

To keep the chart-managed `Gateway` resource but bind it to a `GatewayClass` you manage yourself,
disable the bundled Envoy Gateway and reference your `GatewayClass` by name:

```yaml
global:
  gatewayApi:
    enabled: true
    # Skip the Envoy Gateway subchart and Envoy-specific custom resources.
    installEnvoy: false
gatewayApiResources:
  class:
    # Name of the GatewayClass backed by your Gateway API controller.
    name: custom-class
```

##### Use an externally managed Envoy Gateway

You can also use Envoy Gateway as an external provider (for example, when it is installed
cluster-wide by your platform team). Set `installEnvoy: false` to disable the bundled subchart,
then either reference an external `Gateway` through `gatewayRef` or point at the
externally-installed `GatewayClass`. The chart only renders Envoy-specific custom resources when
`installEnvoy` is `true`, so you must configure escaped slash handling, KAS gRPC forwarding, and
smartcard mutual TLS yourself on that external Envoy Gateway installation.
