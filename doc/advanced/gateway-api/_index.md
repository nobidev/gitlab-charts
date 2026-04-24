---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configure Gateway API and Envoy Gateway extensions
---

{{< details >}}

- Status: Beta

{{< /details >}}

> [!warning]
> Gateway API support is currently under active development. Please be aware that:
>
> 1. Complete validation across all deployment scenarios has not yet been fully verified.
> 1. Configuration values and default settings for Gateway API features are subject to change without notice.
> 1. The Gateway API resources are currently only tested with [Envoy Gateway](https://gateway.envoyproxy.io/).
>    Other Gateway API controllers might need additional configuration.
>
> For more information, see [work item 5](https://gitlab.com/groups/gitlab-com/gl-infra/software-delivery/operate/-/work_items/5).

GitLab chart supports Gateway API and bundles [Envoy Gateway](https://gateway.envoyproxy.io/) as one available provider.

## Global configuration

| Name                                                |  Type   | Default        | Description |
|:----------------------------------------------------|:-------:|:---------------|:------------|
| `global.gatewayApi.enabled`                         | Boolean | false          | Enable deployment of GatewayAPI resources. |
| `global.gatewayApi.gatewayRef.name`                 | String  |                | Gateway name rendered to all Gateway API resources. Use this to reference an externally managed Gateway and to disable the Gateway provided by the chart. |
| `global.gatewayApi.gatewayRef.namespace`            | String  |                | Gateway namespace rendered to all Gateway API resources. Use this to reference an externally managed Gateway in another namespace and to disable the Gateway provided by the chart. |
| `global.gatewayApi.httpToHttpsRedirect`             | Boolean | true           | Create an HTTPRoute that redirects all HTTP traffic to HTTPS with a 301 status code. Only effective when `protocol` is `HTTPS` and the Gateway is managed (no `gatewayRef`). |
| `global.gatewayApi.installEnvoy`                    | Boolean | false          | Install Envoy Gateway subchart and configure a `GatewayClass` and [Envoy Gateway API extensions](../../charts/envoygateway/_index.md). |

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
  minio-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: minio-tls
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
|:----------------------------------------------- ----|:-------:|:---------------|:------------|
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
```

If you configure multiple webservice deployment, the route rules can be customized further.
Check the [Webservice Gateway API documentation](../../charts/gitlab/webservice/_index.md#gateway-api)
for details.

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

The chart can be configured to use an external Gateway API provider, yet not every provider
meets the requirements to expose GitLab.

Make sure your Gateway API provider does support:

1. `HTTPRoutes`, `TCPRoute` (for SSH), and `GRPCRoutes` (for future KAS features)
1. `RegularExpression` matches in `HTTPRoutes`

Note that we only test with the bundled Envoy Gateway chart. Support for other providers is
offered on a best-effort basis. We welcome any contributions that document working
configurations with other Gateway API providers.

#### Setting up external Gateway API providers

{{< tabs >}}

{{< tab title="Envoy Gateway" >}}

- For GitLab to work with Envoy Gateway escaped slashed in traffic have to remain unchanged. This can
  be configured with a [PatchPolicy](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/0e07dbab91c9ba4df48c9424b769e92a219e7528/templates/envoypatchpolicy.yaml#L21).
- Note that `EnvoyPatchPolicies` are disabled by default and Envoy Gateway must be
  [configured to enable them](https://gateway.envoyproxy.io/docs/tasks/extensibility/envoy-patch-policy/#enable-envoypatchpolicy).

{{< /tab >}}

{{< /tabs >}}

#### Configure an externally managed Gateway

To configure GitLab chart to use an external Gateway, disable the chart-managed `Gateway`
and configure your externally managed Gateway:

```yaml
global:
  gatewayApi:
    enabled: true
    # Don't install Envoy Gateway subchart and custom resources.
    installEnvoy: false
    gatewayRef:
      name: "custom-gateway"
      namespace: "custom-gateway-namespace"
```

#### Configure an externally managed GatewayClass

To configure GitLab chart to use the chart-managed `Gateway` resource, but an external `GatewayClass`,
disable the bundled Envoy Gateway and configure your `GatewayClass`:

```yaml
global:
  gatewayApi:
    enabled: true
    # Don't install Envoy Gateway subchart and custom resources.
    installEnvoy: false
    class:
      # Name of the GatewayClass backed by your Gateway API controller.
      name: custom-class
```
