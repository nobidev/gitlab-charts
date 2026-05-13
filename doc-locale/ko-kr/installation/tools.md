---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트 필수 구성 요소
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

Kubernetes 클러스터에 GitLab을 배포하기 전에 다음 필수 구성 요소를 설치하고 설치할 때 사용할 옵션을 결정하십시오.

## 필수 구성 요소 {#prerequisites}

### kubectl {#kubectl}

`kubectl`을 설치하려면 [Kubernetes 설명서](https://kubernetes.io/docs/tasks/tools/#kubectl)를 참조하십시오. 설치하는 버전은 클러스터에서 실행 중인 버전의 [하나의 부 릴리스 이내](https://kubernetes.io/releases/version-skew-policy/#kubectl)여야 합니다.

### Helm {#helm}

[Helm 설명서](https://helm.sh/docs/intro/install/)를 참조하여 Helm v4.0 이상을 설치하십시오.

GitLab 차트는 공식 EOL인 [2026년 7월로 예상되는](https://helm.sh/community/hips/hip-0012/#the-process--timelines)까지 Helm 3을 계속 지원합니다.

### PostgreSQL {#postgresql}

[외부 PostgreSQL 인스턴스](../advanced/external-db/_index.md)를 설정하십시오.

지원되는 PostgreSQL 버전은 [GitLab 요구 사항](https://docs.gitlab.com/install/requirements/#postgresql)을 확인하십시오.

### Redis {#redis}

[외부 Redis 인스턴스](../advanced/external-redis/_index.md)를 설정하십시오. 사용 가능한 모든 구성 설정은 [Redis 글로벌 설명서](../charts/globals.md#configure-redis-settings)를 참조하십시오.

## 기타 옵션 결정 {#decide-on-other-options}

GitLab을 배포할 때 `helm install`과 함께 다음 옵션을 사용합니다.

### 비밀 {#secrets}

SSH 키와 같은 일부 비밀을 만들어야 합니다. 기본적으로 이러한 비밀은 배포 중에 자동으로 생성되지만, 이를 지정하려면 [비밀 설명서](secrets.md)를 따를 수 있습니다.

### 네트워킹 및 DNS {#networking-and-dns}

기본적으로 서비스를 노출하기 위해 GitLab은 `Ingress` 객체로 구성된 이름 기반 가상 서버를 사용합니다. 이러한 객체는 `Service`의 Kubernetes `type: LoadBalancer` 객체입니다.

`gitlab`, `registry`, `minio` (활성화된 경우)을 차트에 대한 적절한 IP 주소로 확인하는 레코드를 포함하는 도메인을 지정해야 합니다.

예를 들어 `helm install`과 함께 다음을 사용하십시오:

```shell
--set global.hosts.domain=example.com
```

사용자 정의 도메인 지원을 활성화하면, 기본적으로 `<pages domain>`인 `*.<pages domain>` 하위 도메인이 `pages.<global.hosts.domain>`가 됩니다. 도메인은 `--set global.pages.externalHttp` 또는 `--set global.pages.externalHttps`으로 페이지에 할당된 외부 IP로 확인됩니다.

사용자 정의 도메인을 사용하려면 GitLab 페이지가 사용자 정의 도메인을 해당 `<namespace>.<pages domain>` 도메인으로 가리키는 CNAME 레코드를 사용할 수 있습니다.

#### `external-dns`을 사용한 동적 IP 주소 {#dynamic-ip-addresses-with-external-dns}

[`external-dns`](https://github.com/kubernetes-sigs/external-dns)와 같은 자동 DNS 등록 서비스를 사용하려면, GitLab에 대한 추가 DNS 구성이 필요하지 않습니다. 그러나 `external-dns`을 클러스터에 배포해야 합니다. 프로젝트 페이지는 각 지원되는 공급자에 대한 [포괄적인 가이드를 제공합니다](https://github.com/kubernetes-sigs/external-dns#deploying-to-a-cluster).

> [!note] GitLab 페이지에 대한 사용자 정의 도메인 지원을 활성화하면, `external-dns`은 더 이상 페이지 도메인(`pages.<global.hosts.domain>` 기본값)에 대해 작동하지 않습니다. 도메인을 페이지 전용 외부 IP 주소로 가리키도록 DNS 항목을 수동으로 구성해야 합니다.

제공된 스크립트를 사용하여 [GKE 클러스터](cloud/gke.md)를 프로비저닝하면, `external-dns`가 클러스터에 자동으로 설치됩니다.

#### 정적 IP 주소 {#static-ip-addresses}

DNS 레코드를 수동으로 구성하려면 모두 정적 IP 주소를 가리켜야 합니다. 예를 들어 `example.com`을 선택하고 정적 IP 주소가 `10.10.10.10`이면, `gitlab.example.com`, `registry.example.com` 및 `minio.example.com` (MinIO를 사용하는 경우)은 모두 `10.10.10.10`으로 확인되어야 합니다.

GKE를 사용 중인 경우 [외부 IP 및 DNS 항목 생성](cloud/gke.md#creating-the-external-ip)에 대해 자세히 읽어보십시오. 이 프로세스에 대한 추가 도움말은 클라우드 또는 DNS 공급자의 설명서를 참조하십시오.

예를 들어 `helm install`과 함께 다음을 사용하십시오:

```shell
--set global.hosts.externalIP=10.10.10.10
```

#### Istio 프로토콜 선택과의 호환성 {#compatibility-with-istio-protocol-selection}

서비스 포트 이름은 Istio의 [명시적 포트 선택](https://istio.io/latest/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection)과 호환되는 규칙을 따릅니다. `<protocol>-<suffix>` 처럼 보이며, 예를 들어 `tls-gitaly` 또는 `https-metrics`입니다.

Gitaly 및 KAS는 gRPC를 사용하지만 [문제 #3822](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3822) 및 [문제 #4908](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4908)의 발견으로 인해 `tcp` 접두사를 대신 사용합니다.

### 지속성 {#persistence}

기본적으로 GitLab 차트는 동적 프로비저너가 기본 영구 볼륨을 생성할 것으로 예상하여 볼륨 클레임을 생성합니다. `storageClass`을 사용자 정의하거나 볼륨을 수동으로 생성하고 할당하려면 [스토리지 설명서](storage.md)를 검토하십시오.

> [!note] 초기 배포 후 스토리지 설정을 변경하려면 Kubernetes 객체를 수동으로 편집해야 합니다. 따라서 프로덕션 인스턴스를 배포하기 전에 미리 계획하여 추가 스토리지 마이그레이션 작업을 피하는 것이 가장 좋습니다.

### TLS 인증서 {#tls-certificates}

TLS 인증서가 필요한 HTTPS로 GitLab을 실행해야 합니다. 기본적으로 GitLab 차트는 [`cert-manager`](https://github.com/cert-manager/cert-manager)를 설치하고 구성하여 무료 TLS 인증서를 얻습니다.

자신의 와일드카드 인증서가 있거나 이미 `cert-manager`이 설치되어 있거나 TLS 인증서를 얻는 다른 방법이 있으면 [TLS 옵션](tls.md)에 대해 자세히 읽어보십시오.

기본 구성의 경우 TLS 인증서를 등록하는 이메일 주소를 지정해야 합니다. 예를 들어 `helm install`과 함께 다음을 사용하십시오:

```shell
--set certmanager-issuer.email=me@example.com
```

### Prometheus {#prometheus}

우리는 [업스트림 Prometheus 차트](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration)를 사용하며, Kubernetes API 및 GitLab 차트에서 생성한 객체로의 메트릭 수집을 제한하는 사용자 정의된 `prometheus.yml` 파일을 제외한 자체 기본값의 값을 재정의하지 않습니다. 그러나 기본적으로 `alertmanager`, `node-exporter`, `pushgateway` 및 `kube-stat-metrics`을 비활성화합니다.

`prometheus.yml` 파일은 `gitlab.com/prometheus_scrape` 주석이 있는 리소스에서 메트릭을 수집하도록 Prometheus에 지시합니다. 또한 `gitlab.com/prometheus_path` 및 `gitlab.com/prometheus_port` 주석을 사용하여 메트릭이 어떻게 발견되는지 구성할 수 있습니다. 이러한 각 주석은 `prometheus.io/{scrape,path,port}` 주석과 비교할 수 있습니다.

GitLab 애플리케이션을 Prometheus 설치로 모니터링하거나 모니터링하려면 원본 `prometheus.io/*` 주석이 적절한 Pod 및 서비스에 계속 추가됩니다. 이를 통해 기존 사용자를 위한 메트릭 수집의 연속성이 보장되며, 기본 Prometheus 구성을 사용하여 GitLab 애플리케이션 메트릭과 Kubernetes 클러스터에서 실행 중인 다른 애플리케이션을 모두 캡처할 수 있습니다.

[업스트림 Prometheus 차트 설명서](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration)를 참조하여 구성 옵션의 전체 목록을 확인하고 `prometheus`의 하위 키인지 확인하세요. 요구 사항 차트로 사용합니다.

예를 들어 지속적 스토리지에 대한 요청은 다음과 같이 제어할 수 있습니다:

```yaml
prometheus:
  alertmanager:
    enabled: false
    persistentVolume:
      enabled: false
      size: 2Gi
  prometheus-pushgateway:
    enabled: false
    persistentVolume:
      enabled: false
      size: 2Gi
  server:
    persistentVolume:
      enabled: true
      size: 8Gi
```

#### TLS 활성화 엔드포인트를 스크래핑하도록 Prometheus 구성 {#configure-prometheus-to-scrape-tls-enabled-endpoints}

Prometheus는 주어진 익스포터가 TLS를 허용하고 차트 구성이 익스포터의 엔드포인트에 대한 TLS 구성을 노출하는 경우 TLS 활성화 엔드포인트에서 메트릭을 스크래핑하도록 구성할 수 있습니다.

TLS 사용 및 [Kubernetes 서비스 검색](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config) 을 Prometheus [스크래핑 구성](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config)과 함께 사용할 때 몇 가지 주의 사항이 있습니다:

- [pod](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#pod) 및 [서비스 엔드포인트](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#endpoints) 발견 역할의 경우 Prometheus는 Pod의 내부 IP 주소를 사용하여 스크래핑 대상의 주소를 설정합니다. TLS 인증서를 확인하려면 Prometheus는 메트릭 엔드포인트에 대해 생성된 인증서에 설정된 일반 이름(CN)으로 구성하거나 주체 대체 이름(SAN) 확장에 포함된 이름으로 구성해야 합니다. 이름은 확인할 필요가 없으며 [유효한 DNS 이름](https://datatracker.ietf.org/doc/html/rfc1034#section-3.1)인 임의의 문자열일 수 있습니다.
- 익스포터의 엔드포인트에 사용된 인증서가 자체 서명되었거나 Prometheus 기본 이미지에 없는 경우, Prometheus pod는 익스포터의 엔드포인트에 사용된 인증서에 서명한 CA(인증 기관)에 대한 인증서를 마운트해야 합니다. Prometheus는 Debian의 `ca-bundle`을 [기본 이미지에서](https://github.com/prometheus/busybox) 사용합니다.
- Prometheus는 각 스크래핑 구성에 적용되는 [tls_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#tls_config)를 사용하여 이 두 항목을 모두 설정하는 것을 지원합니다. Prometheus에는 Pod 주석 및 기타 발견된 속성을 기반으로 Prometheus 대상 레이블을 설정하기 위한 강력한 [relabel_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config) 메커니즘이 있지만, `tls_config.server_name` 및 `tls_config.ca_file`를 설정하는 것은 `relabel_config`를 사용하여 불가능합니다. 자세한 내용은 [Prometheus 프로젝트 문제](https://github.com/prometheus/prometheus/issues/4827)를 참조하세요.

이러한 주의 사항을 고려할 때, 가장 간단한 구성은 익스포터 엔드포인트에 사용되는 모든 인증서에서 "이름" 및 CA를 공유하는 것입니다:

1. `tls_config.server_name`에 사용할 단일 임의 이름을 선택하십시오 (예: `metrics.gitlab`).
1. TLS 암호화 익스포터 엔드포인트에 사용되는 각 인증서의 SAN 목록에 해당 이름을 추가하십시오.
1. 같은 CA에서 모든 인증서를 발급하십시오:
   - CA 인증서를 클러스터 보안으로 추가하십시오.
   - [Prometheus 차트의](https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/values.yaml) `extraSecretMounts:` 구성을 사용하여 해당 보안을 Prometheus 서버 컨테이너에 마운트하십시오.
   - Prometheus `scrape_config`에 대해 `tls_config.ca_file`로 설정하십시오.

[Prometheus TLS 값 예제](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/prometheus/values-tls.yaml)는 다음을 통해 이 공유 구성의 예제를 제공합니다:

1. pod/엔드포인트 `scrape_config` 역할에 대해 `tls_config.server_name`을 `metrics.gitlab`로 설정합니다.
1. 익스포터 엔드포인트에 사용되는 모든 인증서의 SAN 목록에 `metrics.gitlab`이 추가되었다고 가정합니다.
1. CA 인증서가 `metrics.gitlab.tls-ca`이라는 보안에 추가되었으며 보안 키도 `metrics.gitlab.tls-ca`라고 하며, Prometheus 차트가 배포된 동일한 네임스페이스에서 생성되었습니다 (예: `kubectl create secret generic --namespace=gitlab metrics.gitlab.tls-ca --from-file=metrics.gitlab.tls-ca=./ca.pem`).
1. `metrics.gitlab.tls-ca` 보안을 `/etc/ssl/certs/metrics.gitlab.tls-ca`로 마운트하고 `extraSecretMounts:` 항목을 사용합니다.
1. `tls_config.ca_file`을 `/etc/ssl/certs/metrics.gitlab.tls-ca`로 설정합니다.

#### 익스포터 엔드포인트 {#exporter-endpoints}

GitLab 차트에 포함된 모든 메트릭 엔드포인트가 TLS를 지원하는 것은 아닙니다. 엔드포인트가 TLS 활성화될 수 있고 TLS 활성화된 경우 `gitlab.com/prometheus_scheme: "https"` 주석을 설정하고 `prometheus.io/scheme: "https"` 주석도 설정하며, 이 중 하나를 `relabel_config`과 함께 사용하여 Prometheus `__scheme__` 대상 레이블을 설정할 수 있습니다. [Prometheus TLS 값 예제](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/prometheus/values-tls.yaml)는 `gitlab.com/prometheus_scheme: "https"` 주석을 사용하여 `__scheme__`을 대상으로 하는 `relabel_config`을 포함합니다.

다음 표는 Deployments (또는 Gitaly 및 Praefect 중 하나 또는 둘 다를 사용하는 경우:  StatefulSets) 및 `gitlab.com/prometheus_scrape: true` 주석이 적용된 서비스 엔드포인트를 나열합니다.

아래 설명서 링크에서 구성 요소에서 SAN 항목 추가를 언급하면 Prometheus `tls_config.server_name`에 사용하도록 결정한 SAN도 추가해야 합니다.

| 서비스                                                       | 메트릭 포트 (기본값) | TLS를 지원합니까? | 추가 정보 |
|:--------------------------------------------------------------|:----------------------|:--------------|:-----------------------|
| [Gitaly](../charts/gitlab/gitaly/_index.md)                   | `9236`                | {{< yes >}}   | `global.gitaly.tls.enabled=true`를 사용하여 활성화됨<br><br>기본 보안: `RELEASE-gitaly-tls`<br><br>[설명서: TLS를 통해 Gitaly 실행](../charts/gitlab/gitaly/_index.md#running-gitaly-over-tls) |
| [GitLab 익스포터](../charts/gitlab/gitlab-exporter/_index.md) | `9168`                | {{< yes >}}   | `gitlab.gitlab-exporter.tls.enabled=true`를 사용하여 활성화됨<br><br>기본 보안: `RELEASE-gitlab-exporter-tls` |
| [GitLab 페이지](../charts/gitlab/gitlab-pages/_index.md)       | `9235`                | {{< yes >}}   | `gitlab.gitlab-pages.metrics.tls.enabled=true`를 사용하여 활성화됨<br><br>기본 보안: `RELEASE-pages-metrics-tls`<br><br>[설명서: 일반 설정](../charts/gitlab/gitlab-pages/_index.md#general-settings) |
| [GitLab Runner](../charts/gitlab/gitlab-runner/_index.md)     | `9252`                | {{< no >}}    | [문제 - 메트릭 엔드포인트에 TLS 지원 추가](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29176) |
| [GitLab Shell](../charts/gitlab/gitlab-shell/_index.md)       | `9122`                | {{< no >}}    | GitLab Shell 메트릭 익스포터는 [`gitlab-sshd`](https://docs.gitlab.com/administration/operations/gitlab_sshd/)를 사용할 때만 활성화됩니다. OpenSSH는 TLS가 필요한 환경에 권장됩니다 |
| [KAS](../charts/gitlab/kas/_index.md)                         | `8151`                | {{< yes >}}   | `global.kas.customConfig.observability.listen.certificate_file` 및 `global.kas.customConfig.observability.listen.key_file` 옵션을 사용하여 구성할 수 있습니다 |
| [Praefect](../charts/gitlab/praefect/_index.md)               | `9236`                | {{< yes >}}   | `global.praefect.tls.enabled=true`를 사용하여 활성화됨<br><br>기본 보안: `RELEASE-praefect-tls`<br><br>[설명서: TLS를 통해 Praefect 실행](../charts/gitlab/praefect/_index.md#running-praefect-over-tls) |
| [레지스트리](../charts/registry/_index.md)                      | `5100`                | {{< yes >}}   | `registry.debug.tls.enabled=true`를 사용하여 활성화됨<br><br>[설명서: 레지스트리 - 디버그 포트에 대한 TLS 구성](../charts/registry/_index.md#configuring-tls-for-the-debug-port) |
| [Sidekiq](../charts/gitlab/sidekiq/_index.md)                 | `3807`                | {{< yes >}}   | `gitlab.sidekiq.metrics.tls.enabled=true`를 사용하여 활성화됨<br><br>기본 보안: `RELEASE-sidekiq-metrics-tls`<br><br>[설명서: 설치 명령줄 옵션](../charts/gitlab/sidekiq/_index.md#installation-command-line-options) |
| [웹서비스](../charts/gitlab/sidekiq/_index.md)              | `8083`                | {{< yes >}}   | `gitlab.webservice.metrics.tls.enabled=true`를 사용하여 활성화됨<br><br>기본 보안: `RELEASE-webservice-metrics-tls`<br><br>[설명서: 설치 명령줄 옵션](../charts/gitlab/webservice/_index.md#installation-command-line-options) |
| [Ingress-NGINX](../charts/nginx/_index.md)                    | `10254`               | {{< no >}}    | 메트릭/상태 확인 포트에서 TLS를 지원하지 않습니다 |

웹서비스 pod의 경우 노출되는 포트는 웹서비스 컨테이너의 독립형 webrick 익스포터입니다. workhorse 컨테이너 포트는 스크래핑되지 않습니다. 자세한 내용은 [웹서비스 메트릭 설명서](../charts/gitlab/webservice/_index.md#metrics)를 참조하세요.

### 발신 이메일 {#outgoing-email}

기본적으로 발신 이메일은 비활성화됩니다. `global.smtp` 및 `global.email` 설정을 사용하여 SMTP 서버의 세부 정보를 제공하여 활성화하십시오. 이러한 설정의 세부 정보는 [명령줄 옵션](command-line-options.md#outgoing-email-configuration)에서 확인할 수 있습니다.

SMTP 서버에 인증이 필요한 경우 [비밀 설명서](secrets.md#smtp-password)에서 암호 제공 섹션을 읽어야 합니다. `--set global.smtp.authentication=""`으로 인증 설정을 비활성화할 수 있습니다.

Kubernetes 클러스터가 GKE에 있으면 SMTP [포트 25가 차단됨](https://cloud.google.com/compute/docs/tutorials/sending-mail/#using_standard_email_ports)을 주의하십시오.

### 수신 이메일 {#incoming-email}

수신 이메일의 구성은 [mailroom 차트](../charts/gitlab/mailroom/_index.md#incoming-email)에 설명되어 있습니다.

### 서비스 데스크 이메일 {#service-desk-email}

수신 이메일의 구성은 [mailroom 차트](../charts/gitlab/mailroom/_index.md#service-desk-email)에 설명되어 있습니다.

### RBAC {#rbac}

GitLab 차트는 기본적으로 [RBAC](rbac.md)를 생성하고 사용합니다. 클러스터에 RBAC가 활성화되어 있지 않으면 이러한 설정을 비활성화해야 합니다:

```shell
--set certmanager.rbac.create=false
--set nginx-ingress.rbac.createRole=false
--set prometheus.rbac.create=false
--set gitlab-runner.rbac.create=false
```

## 다음 단계 {#next-steps}

[클라우드 공급자를 설정하고 클러스터를 생성하십시오](cloud/_index.md).
