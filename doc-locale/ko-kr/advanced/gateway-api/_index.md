---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Gateway API 및 Envoy Gateway 확장 구성
---

GitLab 차트는 Gateway API를 지원하며 [Envoy Gateway](https://gateway.envoyproxy.io/)를 사용 가능한 공급자 중 하나로 포함합니다. GitLab 19.0부터 GitLab 차트는 번들된 Envoy Gateway 차트와 함께 기본적으로 Gateway API를 사용합니다. NGINX Ingress는 더 이상 사용되지 않지만 GitLab 20.0에서 완전히 제거될 때까지 계속 사용할 수 있습니다.

## 전역 구성 {#global-configuration}

| 이름                                                |  유형   | 기본값        | 설명 |
|:----------------------------------------------------|:-------:|:---------------|:------------|
| `global.gatewayApi.enabled`                         | 부울 | true           | GatewayAPI 리소스의 배포를 활성화합니다. 기본값이 GitLab 19.0에서 `true`로 변경되었습니다. |
| `global.gatewayApi.configureCertmanager`            | 부울 | true           | Gateway API HTTP-01 솔버를 통해 Let's Encrypt에서 인증서를 가져오도록 cert-manager를 구성합니다. `certmanager-issuer.email`이(가) 필요합니다. |
| `global.gatewayApi.gatewayRef.name`                 | 문자열  |                | 모든 Gateway API 리소스에 렌더링되는 Gateway 이름입니다. 이를 사용하여 외부에서 관리되는 Gateway를 참조하고 차트에서 제공하는 Gateway를 비활성화합니다. |
| `global.gatewayApi.gatewayRef.namespace`            | 문자열  |                | 모든 Gateway API 리소스에 렌더링되는 Gateway 네임스페이스입니다. 이를 사용하여 다른 네임스페이스의 외부에서 관리되는 Gateway를 참조하고 차트에서 제공하는 Gateway를 비활성화합니다. |
| `global.gatewayApi.httpToHttpsRedirect`             | 부울 | true           | 모든 HTTP 트래픽을 301 상태 코드로 HTTPS로 리디렉션하는 HTTPRoute를 만듭니다. `protocol`이(가) `HTTPS`일 때만 적용되며 Gateway가 관리되는 경우(`gatewayRef` 없음)에만 유효합니다. |
| `global.gatewayApi.installEnvoy`                    | 부울 | true           | Envoy Gateway 서브차트를 설치하고 `GatewayClass` 및 [Envoy Gateway API 확장](../../charts/envoygateway/_index.md)을(를) 구성합니다. 기본값이 GitLab 19.0에서 `true`로 변경되었습니다. |

### 관리되는 Gateway API 리소스 구성 {#configuring-managed-gateway-api-resources}

GitLab 차트를 사용하면 관리되는 `Gateway`, `GatewayClass`, 및 Envoy Gateway 확장을 사용자 지정할 수 있습니다.

| 이름                           |  유형   | 기본값        | 설명 |
|:-------------------------------|:-------:|:---------------|:------------|
| `gatewayApiResources.class.name`                   | 문자열  | `gitlab-gw`    | Gateway에 바인딩된 Gateway 클래스의 이름입니다. |
| `gatewayApiResources.class.controllerName`         | 문자열  | `gateway.envoyproxy.io/gitlab-gatewayclass-controller` | GatewayClass의 컨트롤러 이름입니다. |
| `gatewayApiResources.gateway.addresses`            | 배열   | 거짓          | Gateway에 추가할 주소의 배열입니다. |
| `gatewayApiResources.gateway.protocol`             | 문자열  | `HTTPS`        | 기본 수신기 프로토콜입니다. |
| `gatewayApiResources.gateway.annotations`          | 맵     | `{}`           | 관리되는 Gateway에 추가할 주석입니다. |
| `gatewayApiResources.gateway.infrastructure`       | 객체  | `{}`           | [GatewayInfrastructure](https://gateway-api.sigs.k8s.io/reference/spec/#gatewayinfrastructure)가(이) 관리되는 Gateway에 추가되었습니다. |
| `gatewayApiResources.gateway.listeners`            | 객체  |                | 관리되는 Gateway의 수신기 구성입니다. 아래에서 예제를 참조하세요. |

#### 수신기 구성 {#listener-configuration}

기본 수신기 구성은 미리 정의된 프로토콜을 사용하는 수신기에 대해서만 프로토콜을 지정합니다. 프로토콜이 설정에 따라 달라지는 수신기는 루트 수준 프로토콜을 상속합니다:

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

#### Envoy Gateway 확장 {#envoy-gateway-extensions}

번들된 Envoy Gateway를 사용하는 경우 `EnvoyProxy`을(를) 사용자 지정하고 선택적으로 `ClientTrafficPolicy` 및 `SecurityPolicy`을(를) 만들어 관리되는 `Gateway`에 바인딩할 수 있습니다.

| 이름                                                |  유형   | 기본값        | 설명 |
|:----------------------------------------------------|:-------:|:---------------|:------------|
| `gatewayApiResources.envoy.proxySpec`               | 객체  | 값 참조     | `EnvoyProxy` 사양입니다. `global.gatewayApi.installEnvoy`이(가) 참일 때만 활성화됩니다.|
| `gatewayApiResources.envoy.clientTrafficPolicySpec` | 객체  | 값 참조     | Envoy의 `ClientTrafficPolicy` 사양입니다. `global.gatewayApi.installEnvoy`이(가) 참일 때만 활성화됩니다.|
| `gatewayApiResources.envoy.securityPolicySpec`      | 객체  | 값 참조     | Envoy의 `SecurityPolicy` 사양입니다. `global.gatewayApi.installEnvoy`이(가) 참일 때만 활성화됩니다.|

#### Envoy Gateway 메트릭 {#envoy-gateway-metrics}

번들된 Prometheus는 Envoy Gateway와 관리되는 Envoy Proxy에서 메트릭을 수집하도록 설정되어 있습니다. Prometheus Operator CRD(사용자 정의 리소스 정의)가 활성화되어 있으면 Envoy Gateway에 대해 ServiceMonitor가 생성되고 Envoy Proxy에 대해 PodMonitor가 생성됩니다.

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

#### 경로 구성 {#route-configuration}

Webservice, KAS, Registry 및 GitLab Pages는 `HTTPRoute`을(를) 통해 노출되고 GitLab Shell은 `TCPRoute`을(를) 통해 노출됩니다. 경로는 차트 수준에서 사용자 지정할 수 있습니다:

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

타임아웃은 KAS를 제외한 모든 경로에서 지원됩니다(KAS는 GRPC/WSS 요구 사항에 `BackendTrafficPolicy`을(를) 사용합니다). 필터는 모든 `HTTPRoute` 리소스에서 지원됩니다.

`filters` 필드는 [Gateway API HTTPRouteFilter](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPRouteFilter) 객체의 목록을 허용합니다. 일반적인 필터 유형에는 `RequestHeaderModifier`, `ResponseHeaderModifier`, `RequestRedirect`, `URLRewrite`, 및 `RequestMirror`이(가) 포함됩니다.

헤더 새니타이제이션 예제:

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

여러 webservice 배포를 구성하는 경우 경로 규칙(필터 포함)을 규칙별로 사용자 지정할 수 있습니다. 자세한 내용은 [Webservice Gateway API 설명서](../../charts/gitlab/webservice/_index.md#gateway-api)를 참조하세요.

### Gateway와 백엔드 서비스 간 TLS {#tls-between-gateway-and-backend-services}

백엔드 서비스(Webservice, KAS 또는 Registry)에서 TLS가 활성화되면 차트는 Gateway에 TLS 연결을 설정하도록 지시하는 `BackendTLSPolicy` 리소스를 만듭니다.

NGINX Ingress 구현과 달리, 인증서 검증을 비활성화할 수 있는 경우(예: 자체 서명된 인증서의 경우 `workhorse.tls.verify: false`)와 달리, Gateway API는 항상 백엔드 TLS 연결을 검증합니다. 따라서 검증이 성공하려면 CA 인증서 비밀을 제공해야 합니다.

#### Webservice에 대한 내부 TLS 활성화 {#enable-internal-tls-for-webservice}

Webservice의 백엔드 TLS는 [Workhorse TLS](../../charts/gitlab/webservice/_index.md#gitlab-workhorse)를 전역적으로 활성화해야 합니다. 검증 호스트명은 기본적으로 서비스 DNS 이름(`<service-name>.<namespace>.svc`)으로 설정되며 `webservice.backendTLSPolicy.hostname`로 재정의할 수 있습니다:

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

선택적 배포 수준 재정의를 구성하는 방법에 대한 자세한 내용은 [Webservice Gateway API 설명서](../../charts/gitlab/webservice/_index.md#tls-between-gateway-and-workhorse)를 참조하세요.

#### GitLab Relay(KAS)에 대한 내부 TLS 활성화 {#enable-internal-tls-for-gitlab-relay-kas}

KAS의 백엔드 TLS는 `global.kas.tls.enabled`에 의해 제어됩니다. 검증 호스트명은 기본적으로 서비스 DNS 이름(`<service-name>.<namespace>.svc`)으로 설정되며 `kas.backendTLSPolicy.hostname`로 재정의할 수 있습니다:

> [!warning]
> GitLab Workspaces는 아직 내부 TLS를 지원하지 않습니다. Workspaces를 사용하는 경우 GitLab Relay에 대한 내부 TLS를 활성화하지 마세요. 프로토콜 및 TLS 오류가 발생하기 때문입니다.

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

#### Registry에 대한 내부 TLS 활성화 {#enable-internal-tls-for-registry}

Registry의 백엔드 TLS는 `registry.tls.enabled`에 의해 제어됩니다. 검증 호스트명은 기본적으로 서비스 DNS 이름(`<service-name>.<namespace>.svc`)으로 설정되며 `registry.backendTLSPolicy.hostname`로 재정의할 수 있습니다:

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

### GitLab Geo {#gitlab-geo}

[GitLab Geo](https://docs.gitlab.com/administration/geo/)를 Gateway API를 사용하여 구성하려면 `global.geo.gatewayApi.additionalHostname`을(를) 설정하여 추가 호스트명을 구성할 수 있습니다.

이 플래그는 주 사이트에서는 내부 URL로, 보조 사이트에서는 외부/통합 URL로 설정해야 합니다. 자세한 내용은 [Geo 설정 가이드](../geo/_index.md)를 참조하세요.

### 외부 Gateway API 공급자 사용 {#using-an-external-gateway-api-provider}

차트는 외부 Gateway API 공급자를 사용하도록 구성할 수 있지만 모든 공급자가 GitLab을 노출하기 위한 요구 사항을 충족하는 것은 아닙니다.

Gateway API 공급자가 다음을 지원하는지 확인하세요:

1. `HTTPRoutes`, `TCPRoute`(SSH의 경우), 및 `GRPCRoutes`(향후 KAS 기능의 경우)
1. `RegularExpression` `HTTPRoutes`의 일치

번들된 Envoy Gateway 차트로만 테스트합니다. 다른 공급자에 대한 지원은 최대한 제공됩니다. 다른 Gateway API 공급자와의 작동 구성을 문서화하는 기여를 환영합니다.

#### 외부 Gateway API 공급자 설정 {#setting-up-external-gateway-api-providers}

{{< tabs >}}

{{< tab title="Envoy Gateway" >}}

- GitLab이 Envoy Gateway에서 작동하려면 트래픽의 이스케이프된 슬래시가 변경되지 않아야 합니다. 이를 [PatchPolicy](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/0e07dbab91c9ba4df48c9424b769e92a219e7528/templates/envoypatchpolicy.yaml#L21)로 구성할 수 있습니다.
- `EnvoyPatchPolicies`은(는) 기본적으로 비활성화되어 있으며 Envoy Gateway는 [이를 활성화하도록 구성](https://gateway.envoyproxy.io/docs/tasks/extensibility/envoy-patch-policy/#enable-envoypatchpolicy)되어야 합니다.

{{< /tab >}}

{{< /tabs >}}

#### 외부에서 관리되는 Gateway 구성 {#configure-an-externally-managed-gateway}

GitLab 차트를 외부 Gateway를 사용하도록 구성하려면 차트에서 관리하는 `Gateway`을(를) 비활성화하고 외부에서 관리되는 Gateway를 구성하세요:

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

#### 외부에서 관리되는 GatewayClass 구성 {#configure-an-externally-managed-gatewayclass}

GitLab 차트를 차트에서 관리하는 `Gateway` 리소스를 사용하지만 외부 `GatewayClass`를 사용하도록 구성하려면 번들된 Envoy Gateway를 비활성화하고 `GatewayClass`을(를) 구성하세요:

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
