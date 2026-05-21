---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Envoy Gateway로 마이그레이션
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

GitLab 19.0부터 GitLab 차트는 번들된 NGINX Ingress를 비활성화하고 Gateway API 및 번들된 Envoy Gateway를 기본값으로 사용합니다. HAProxy 및 Traefik을 포함한 모든 번들된 Ingress 컨트롤러는 더 이상 사용되지 않으며 20.0에서 제거될 예정입니다. Ingress는 더 이상 사용되지 않으며 20.0 이후에도 계속 사용할 수 있지만 [외부 Ingress 컨트롤러](../../advanced/external-ingress/_index.md)가 필요합니다.

번들된 NGINX Ingress에서 Gateway API로 마이그레이션하는 방법은 다음과 같습니다:

- [1단계 마이그레이션](#migrate-in-one-step)
- 다운타임 없이 [다단계 마이그레이션](#migrate-with-zero-downtime)을 수행합니다.

## 1단계로 마이그레이션 {#migrate-in-one-step}

> [!warning]
> 마이그레이션 중에 약 5분의 다운타임이 예상됩니다. 실제 시간은 배포, 인프라 및 구성에 따라 달라질 수 있습니다. 다운타임 없는 접근 방식을 원하면 [다운타임 없이 마이그레이션](#migrate-with-zero-downtime)을 참조하세요.

(NGINX) Ingress에서 Gateway API 및 Envoy Gateway로 마이그레이션하려면:

1. Envoy 및 Gateway API CRD 설치:

   ```script
   helm template eg-crds oci://docker.io/envoyproxy/gateway-crds-helm \
     --version v1.7.2 \
     --set crds.gatewayAPI.enabled=true \
     --set crds.envoyGateway.enabled=true \
     | kubectl apply --server-side -f -
   ```

1. 그렇지 않으면 클라우드 공급자를 통해 Gateway API CRD를 설치하거나 [수동으로 적용](https://gateway-api.sigs.k8s.io/guides/#installing-gateway-api)하세요.

1. NGINX Ingress 및 Ingress 리소스 비활성화:

   ```yaml
   # Disable bundled NGINX Ingress controller.
   nginx-ingress:
     enabled: false

   global:
     # Disable rendering of Ingress resources.
     ingress:
       enabled: false
   ```

1. Gateway API용 Certmanager 구성:

   ```yaml
   # Configure bundled certmanager for Gateway API support.
   certmanager:
     config:
       apiVersion: controller.config.cert-manager.io/v1alpha1
       kind: ControllerConfiguration
       enableGatewayAPI: true

   global:
     gatewayApi:
       configureCertmanager: true
   ```

1. Envoy 및 Gateway API 리소스 활성화:

   ```yaml
   global:
     # Disable rendering of Ingress resources.
     gatewayApi:
       # Install a Gateway and Routes for each component.
       enabled: true
       # Install the bundled Envoy Gateway chart, a GatewayClass, a EnvoyPatchPolicy, and the EnvoyProxy resources.
       installEnvoy: true
   ```

1. Gateway를 정적 IP 주소에 바인드하도록 구성합니다. 기본적으로 `global.hosts.externalIP`을 통해 구성된 IP가 재사용됩니다.

   ```yaml
   # Depending on your cloud provider you might to migrate additional annotations.
   global:
     hosts:
       # Only used by Envoy if bundled NGINX Ingress is disabled and no custom
       # gateway addresses are defined.
       externalIP: "10.10.0.1"
   gatewayApiResources:
     gateway:
       addresses:
       - type: IPAddress
         value: "10.10.0.2"
       infrastructure:
         annotations: {}
   ```

   {{< tabs >}}

   {{< tab title="GKE" >}}

   `global.hosts.externalIP` 또는 `gatewayApiResources.gateway.addresses`를 사용하는 대신 프로비저닝된 LoadBalancer에 대한 주석을 구성하세요:

   ```yaml
   gatewayApiResources:
     gateway:
       infrastructure:
         annotations:
           networking.gke.io/load-balancer-type: External
           networking.gke.io/load-balancer-ip-addresses: gitlab-ip-address
           cloud.google.com/l4-rbs: enabled
   ```

   {{< /tab >}}

   {{< tab title="EKS" >}}

   EKS LoadBalancer를 마이그레이션하려면 NGINX 컨트롤러 서비스에서 Envoy Gateway 구성으로 주석을 마이그레이션하세요:

   ```yaml
   gatewayApiResources:
     gateway:
       infrastructure:
         annotations:
           service.beta.kubernetes.io/aws-load-balancer-type: nlb
           service.beta.kubernetes.io/aws-load-balancer-eip-allocations: "gitlab-allocation-id"
           service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. 업데이트된 값으로 GitLab 차트 릴리스를 업그레이드하세요.

## 다운타임 없이 마이그레이션 {#migrate-with-zero-downtime}

다운타임 없는 마이그레이션을 수행하려면 NGINX Ingress 및 Envoy Gateway를 나란히 실행하여 두 LoadBalancer가 동시에 작동할 수 있도록 허용할 수 있습니다. Envoy Gateway가 GitLab 트래픽을 처리하도록 완전히 구성되면 GitLab DNS 레코드를 업데이트하여 Envoy Gateway 관리 LoadBalancer를 가리키도록 하세요.

1. NGINX Ingress를 비활성화하지 않으면서 Envoy Gateway 및 Gateway API 리소스를 활성화하세요:

   ```yaml
   nginx-ingress:
     enabled: true

   global:
     hosts:
       # External LoadBalancer IP bound by NGINX Ingress
       externalIp: "10.10.0.1"
     # Enable Gateway API and configure another
     gatewayApi:
       enabled: true
       installEnvoy: true
   gatewayApiResources:
     gateway:
       addresses:
        - type: IPAddress
          value: "10.10.0.2"
       infrastructure:
         annotations: {}
   ```

1. 관리 Gateway에 대한 TLS 인증서 또는 certmanager 발급자를 구성하세요:

   > [!note]
   > GitLab 차트에서 제공하는 Issuer는 이 목적으로 사용할 수 없습니다. 발급자는 [HTTP01](https://cert-manager.io/docs/configuration/acme/http01/)을 사용하므로 DNS 레코드가 업데이트될 때까지 인증서를 검색할 수 없습니다.

   1. [DNS01 Issuer](https://cert-manager.io/docs/configuration/acme/dns01/) 를 구성하거나 [리스너](../../charts/globals.md)를 사용자 정의하여 기존 인증서를 사용하세요.

   1. 사용자 정의 Issuer를 생성한 경우 certmanager의 Gateway API 지원을 활성화하고 관리 Gateway에 주석을 추가하세요:

      ```yaml
      # Enable Gateway API support for bundled certmanager.
      certmanager:
        config:
          apiVersion: controller.config.cert-manager.io/v1alpha1
          kind: ControllerConfiguration
          enableGatewayAPI: true

      global:
        gatewayApi:
          # Do not configure HTTP01 issues.
          configureCertmanager: false
      gatewayApiResources:
        gateway:
          # Annotate Gateway to use custom DNS01 issuer.
          annotations:
            cert-manager.io/issuer: gitlab-dns01
      ```

1. 도메인이 Envoy Gateway LoadBalancer의 IP로 확인되는 경우 GitLab에 도달할 수 있는지 확인하세요:

   ```script
   $ curl -Lso /dev/null \
     --write-out 'Status: %{http_code} TLS: %{ssl_verify_result} (0=OK)' \
     --resolve gitlab.example.com:443:10.10.0.2 \
     "https://gitlab.example.com"
   Status: 200 TLS: 0 (0=OK)
   ```

1. DNS 항목을 업데이트하여 Envoy Gateway LoadBalancer로 확인되도록 하세요.
1. 모든 클라이언트로 DNS 항목이 전파될 때까지 기다립니다.
1. NGINX Ingress 및 Ingress 객체 비활성화:

   ```yaml
   nginx-ingress:
     enabled: false

   global:
     ingress:
       enabled: false
   ```
