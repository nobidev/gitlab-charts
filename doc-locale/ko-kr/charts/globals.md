---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 글로벌을 사용하여 차트 구성
---

{{< details >}}

- 계층:  무료, 프리미엄, 궁극
- 제공:  GitLab 자체 관리

{{< /details >}}

래퍼 Helm 차트를 설치할 때 구성 중복을 줄이기 위해 `global` 섹션의 `values.yaml`에서 여러 구성 설정을 사용할 수 있습니다. 이러한 글로벌 설정은 여러 차트에서 사용되며, 다른 모든 설정은 각 차트 내에서 범위가 지정됩니다. [Helm 글로벌 문서](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/#global-chart-values)를 참조하여 글로벌 변수가 어떻게 작동하는지에 대한 자세한 정보를 확인하세요.

## 호스트 설정 구성 {#configure-host-settings}

GitLab 글로벌 호스트 설정은 `global.hosts` 키 아래에 위치합니다.

```yaml
global:
  hosts:
    domain: example.com
    hostSuffix: staging
    https: false
    externalIP:
    gitlab:
      name: gitlab.example.com
      https: false
    registry:
      name: registry.example.com
      https: false
    minio:
      name: minio.example.com
      https: false
    smartcard:
      name: smartcard.example.com
    kas:
      name: kas.example.com
    pages:
      name: pages.example.com
      https: false
    ssh: gitlab.example.com
```

| 이름                      |  유형   | 기본값       | 설명 |
|:--------------------------|:-------:|:--------------|:------------|
| `domain`                  | 문자열  | `example.com` | 기본 도메인입니다. GitLab과 Registry는 이 설정의 하위 도메인에서 노출됩니다. 기본값은 `example.com`이지만 `name` 속성이 구성된 호스트에는 사용되지 않습니다. `gitlab.name`, `minio.name` 및 `registry.name` 섹션을 아래에서 참조하세요. |
| `externalIP`              |         | `nil`         | 공급자로부터 청구될 외부 IP 주소를 설정합니다. 이는 더 복잡한 `nginx.service.loadBalancerIP` 대신 [NGINX 차트](nginx/_index.md#configuring-nginx)로 템플릿화됩니다. |
| `externalGeoIP`           |         | `nil`         | `externalIP`과 동일하지만 [NGINX Geo 차트](nginx/_index.md#gitlab-geo)의 경우입니다. 통합 URL을 사용하는 [GitLab Geo](../advanced/geo/_index.md) 사이트에 대해 정적 IP를 구성하는 데 필요합니다. `externalIP`와 다르게 해야 합니다. |
| `https`                   | 부울 | `true`        | true로 설정된 경우 NGINX 차트가 인증서에 액세스할 수 있는지 확인해야 합니다. Ingress 앞에 TLS 종료가 있는 경우 [`global.ingress.tls.enabled`](#configure-ingress-settings)를 살펴보고 싶을 수도 있습니다. 외부 URL이 `https` 대신 `http://`을 사용하도록 false로 설정합니다. |
| `hostSuffix`              | 문자열  |               | [아래를 참조하세요](#hostsuffix). |
| `gitlab.https`            | 부울 | `false`       | `hosts.https` 또는 `gitlab.https`가 `true`이면 GitLab 외부 URL은 `http://` 대신 `https://`를 사용합니다. |
| `gitlab.name`             | 문자열  |               | GitLab의 호스트명입니다. 설정된 경우 `global.hosts.domain` 및 `global.hosts.hostSuffix` 설정에 관계없이 이 호스트명이 사용됩니다. |
| `gitlab.hostnameOverride` | 문자열  |               | Webservice의 Ingress 구성에서 사용되는 호스트명을 재정의합니다. GitLab이 호스트명을 내부 호스트명으로 다시 작성하는 WAF 뒤에서 도달할 수 있어야 하는 경우에 유용합니다(예: `gitlab.example.com` --> `gitlab.cluster.local`). |
| `gitlab.serviceName`      | 문자열  | `webservice`  | GitLab 서버를 운영하는 `service`의 이름입니다. 차트는 서비스의 호스트명(및 현재 `.Release.Name`)을 템플릿화하여 적절한 내부 `serviceName`을 생성합니다. |
| `gitlab.servicePort`      | 문자열  | `workhorse`   | GitLab 서버에 도달할 수 있는 `service`의 명명된 포트입니다. |
| `keda.enabled`            | 부울 | `false`       | [KEDA](https://keda.sh/) `ScaledObjects`를 `HorizontalPodAutoscalers` 대신 사용합니다 |
| `minio.https`             | 부울 | `false`       | `hosts.https` 또는 `minio.https`가 `true`이면 MinIO 외부 URL은 `http://` 대신 `https://`를 사용합니다. |
| `minio.name`              | 문자열  | `minio`       | MinIO의 호스트명입니다. 설정된 경우 `global.hosts.domain` 및 `global.hosts.hostSuffix` 설정에 관계없이 이 호스트명이 사용됩니다. |
| `minio.serviceName`       | 문자열  | `minio`       | MinIO 서버를 운영하는 `service`의 이름입니다. 차트는 서비스의 호스트명(및 현재 `.Release.Name`)을 템플릿화하여 적절한 내부 `serviceName`을 생성합니다. |
| `minio.servicePort`       | 문자열  | `minio`       | MinIO 서버에 도달할 수 있는 `service`의 명명된 포트입니다. |
| `registry.https`          | 부울 | `false`       | `hosts.https` 또는 `registry.https`가 `true`이면 Registry 외부 URL은 `http://` 대신 `https://`를 사용합니다. |
| `registry.name`           | 문자열  | `registry`    | Registry의 호스트명입니다. 설정된 경우 `global.hosts.domain` 및 `global.hosts.hostSuffix` 설정에 관계없이 이 호스트명이 사용됩니다. |
| `registry.serviceName`    | 문자열  | `registry`    | Registry 서버를 운영하는 `service`의 이름입니다. 차트는 서비스의 호스트명(및 현재 `.Release.Name`)을 템플릿화하여 적절한 내부 `serviceName`을 생성합니다. |
| `registry.servicePort`    | 문자열  | `registry`    | Registry 서버에 도달할 수 있는 `service`의 명명된 포트입니다. |
| `smartcard.name`          | 문자열  | `smartcard`   | 스마트카드 인증의 호스트명입니다. 설정된 경우 `global.hosts.domain` 및 `global.hosts.hostSuffix` 설정에 관계없이 이 호스트명이 사용됩니다. |
| `kas.name`                | 문자열  | `kas`         | KAS의 호스트명입니다. 설정된 경우 `global.hosts.domain` 및 `global.hosts.hostSuffix` 설정에 관계없이 이 호스트명이 사용됩니다. |
| `kas.https`               | 부울 | `false`       | `hosts.https` 또는 `kas.https`가 `true`이면 KAS 외부 URL은 `ws://` 대신 `wss://`를 사용합니다. |
| `pages.name`              | 문자열  | `pages`       | GitLab Pages의 호스트명입니다. 설정된 경우 `global.hosts.domain` 및 `global.hosts.hostSuffix` 설정에 관계없이 이 호스트명이 사용됩니다. |
| `pages.https`             | 문자열  |               | `global.pages.https` 또는 `global.hosts.pages.https` 또는 `global.hosts.https`이 `true`이면 프로젝트 설정 UI의 GitLab Pages URL은 `http://` 대신 `https://`를 사용합니다. |
| `ssh`                     | 문자열  |               | SSH를 통해 저장소를 복제하는 호스트명입니다. 설정된 경우 `global.hosts.domain` 및 `global.hosts.hostSuffix` 설정에 관계없이 이 호스트명이 사용됩니다. |

### `hostSuffix` {#hostsuffix}

`hostSuffix`은(는) 기본 `domain`을 사용하여 호스트명을 조립할 때 하위 도메인에 추가되지만 자체 `name`이 설정된 호스트에는 사용되지 않습니다.

기본값은 설정 해제 상태입니다. 설정된 경우 접미사는 하이픈으로 하위 도메인에 추가됩니다. 아래 예제는 `gitlab-staging.example.com` 및 `registry-staging.example.com`와 같은 외부 호스트명을 사용하게 됩니다:

```yaml
global:
  hosts:
    domain: example.com
    hostSuffix: staging
```

## 수평 Pod 자동 스케일러 설정 구성 {#configure-horizontal-pod-autoscaler-settings}

GitLab 글로벌 HPA 호스트 설정은 `global.hpa` 키 아래에 위치합니다:

| 이름         |  유형  | 기본값 | 설명 |
|:-------------|:------:|:--------|:------------|
| `apiVersion` | 문자열 |         | `HorizontalPodAutoscaler` 객체 정의에서 사용할 API 버전입니다. |

## `PodDisruptionBudget` 설정 구성 {#configure-poddisruptionbudget-settings}

GitLab 글로벌 PDB 호스트 설정은 `global.pdb` 키 아래에 위치합니다:

| 이름         |  유형  | 기본값 | 설명 |
|:-------------|:------:|:--------|:------------|
| `apiVersion` | 문자열 |         | `PodDisruptionBudget` 객체 정의에서 사용할 API 버전입니다. |

## `CronJob` 설정 구성 {#configure-cronjob-settings}

GitLab 글로벌 `CronJobs` 호스트 설정은 `global.batch.cronJob` 키 아래에 위치합니다:

| 이름         |  유형  | 기본값 | 설명 |
|:-------------|:------:|:--------|:------------|
| `apiVersion` | 문자열 |         | `CronJob` 객체 정의에서 사용할 API 버전입니다. |

## 모니터링 설정 구성 {#configure-monitoring-settings}

GitLab 글로벌 설정 `ServiceMonitors` 및 `PodMonitors`는 `global.monitoring` 키 아래에 위치합니다:

| 이름      |  유형   | 기본값 | 설명 |
|:----------|:-------:|:--------|:------------|
| `enabled` | 부울 | `false` | `monitoring.coreos.com/v1` API의 가용성에 관계없이 모니터링 리소스를 활성화합니다. |

## Ingress 설정 구성 {#configure-ingress-settings}

GitLab 글로벌 Ingress 호스트 설정은 `global.ingress` 키 아래에 위치합니다:

| 이름                           |  유형   | 기본값        | 설명 |
|:-------------------------------|:-------:|:---------------|:------------|
| `apiVersion`                   | 문자열  |                | Ingress 객체 정의에서 사용할 API 버전입니다. |
| `annotations.*annotation-key*` | 문자열  |                | `annotation-key`이(가) 모든 Ingress에서 주석으로 값과 함께 사용될 문자열입니다. 예: `global.ingress.annotations."nginx\.ingress\.kubernetes\.io/enable-access-log"=true`. 기본적으로 제공되는 글로벌 주석이 없습니다. |
| `configureCertmanager`         | 부울 | `false`        | [아래를 참조하세요](#globalingressconfigurecertmanager). |
| `useNewIngressForCerts`        | 부울 | `false`        | [아래를 참조하세요](#globalingressusenewingressforcerts). |
| `class`                        | 문자열  | `gitlab-nginx` | `Ingress` 리소스에서 `kubernetes.io/ingress.class` 주석 또는 `spec.IngressClassName`을(를) 제어하는 글로벌 설정입니다. 비활성화하려면 `none`로 설정하거나 빈 상태로 `""`을(를) 설정합니다. 참고: `none` 또는 `""`의 경우 `nginx-ingress.enabled=false`을(를) 설정하여 차트가 불필요한 Ingress 리소스를 배포하지 않도록 합니다. |
| `enabled`                      | 부울 | `false`        | 지원하는 서비스에 대해 Ingress 객체를 생성할지 여부를 제어하는 글로벌 설정입니다. GitLab 19.0 이후로 차트의 기본값은 Gateway API입니다. Ingress로 돌아가려면 `true`로 설정합니다. |
| `tls.enabled`                  | 부울 | `true`         | `false`로 설정하면 GitLab의 TLS가 비활성화됩니다. Ingress 앞에 TLS 종료 프록시가 있는 경우와 같이 Ingress의 TLS 종료를 사용할 수 없는 경우에 유용합니다. https를 완전히 비활성화하려면 `false`와 함께 [`global.hosts.https`](#configure-host-settings)로 설정해야 합니다. |
| `tls.secretName`               | 문자열  |                | `global.hosts.domain`에서 사용되는 도메인에 대한 **wildcard** 인증서와 키를 포함하는 [Kubernetes TLS Secret](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)의 이름입니다. |
| `path`                         | 문자열  | `/`            | `path` 항목의 [Ingress 객체](https://kubernetes.io/docs/concepts/services-networking/ingress/) 기본값 |
| `pathType`                     | 문자열  | `Prefix`       | [경로 유형](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types)을(를) 사용하면 경로 일치 방법을 지정할 수 있습니다. 현재 기본값은 `Prefix`이지만 사용 사례에 따라 `ImplementationSpecific` 또는 `Exact`를 사용할 수 있습니다. |
| `provider`                     | 문자열  | `nginx`        | 사용할 Ingress 공급자를 정의하는 글로벌 설정입니다. `nginx`이(가) 기본 공급자로 사용됩니다. |

샘플 [다양한 클라우드 공급자를 위한 구성](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/examples)은(는) 예제 폴더에서 찾을 수 있습니다.

- [`AWS`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/ingress.yaml)
- [`GKE`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/gke/ingress.yaml)

### Ingress 경로 {#ingress-path}

이 차트는 `global.ingress.path`을(를) 활용하여 Ingress 객체에 대한 `path` 항목의 정의를 변경해야 하는 사용자를 지원합니다. 많은 사용자는 이 설정이 필요하지 않으므로 구성하지 않아야 합니다.

`path` 정의가 `/*`로 끝나야 하는 사용자의 경우 로드 밸런서/프록시 동작과 일치하도록 (예: GCP에서 `ingress.class: gce`, AWS에서 `ingress.class: alb`, 또는 다른 공급자)합니다.

이 설정은 이 차트 전체의 Ingress 리소스의 모든 `path` 항목이 이렇게 렌더링되도록 보장합니다. 유일한 예외는 `path`를 지정해야 하는 [`gitlab/webservice` 배포 설정](gitlab/webservice/_index.md#deployments-settings)을 채울 때입니다.

### 클라우드 공급자 로드밸런서 {#cloud-provider-loadbalancers}

다양한 클라우드 공급자의 LoadBalancer 구현은 이 차트의 일부로 배포된 Ingress 리소스 및 NGINX 컨트롤러의 구성에 영향을 미칩니다. 다음 표는 예제를 제공합니다.

| 공급자 | 계층 | 예제 스니펫 |
|:---------|------:|:----------------|
| AWS      |     4 | [`aws/elb-layer4-loadbalancer`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/elb-layer4-loadbalancer.yaml) |
| AWS      |     7 | [`aws/elb-layer7-loadbalancer`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/elb-layer7-loadbalancer.yaml) |
| AWS      |     7 | [`aws/alb-full`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/alb-full.yaml) |

### `global.ingress.configureCertmanager` {#globalingressconfigurecertmanager}

Ingress 객체에 대한 [cert-manager](https://cert-manager.io/docs/installation/helm/)의 자동 구성을 제어하는 글로벌 설정입니다. `true`인 경우 `certmanager-issuer.email`이(가) 설정되어 있어야 합니다.

`false`이고 `global.ingress.tls.secretName`가 설정되지 않았으며 `global.ingress.tls.enabled`이(가) true이거나 설정 해제된 경우 이는 모든 Ingress 객체에 대해 **wildcard** 인증서를 생성하는 자동 자체 서명 인증서 생성을 활성화합니다.

외부 `cert-manager`을(를) 사용하려면 다음을 제공해야 합니다:

- `gitlab.webservice.ingress.tls.secretName`
- `registry.ingress.tls.secretName`
- `minio.ingress.tls.secretName`
- `global.ingress.annotations`

### `global.ingress.useNewIngressForCerts` {#globalingressusenewingressforcerts}

`cert-manager`의 동작을 변경하여 새 Ingress를 동적으로 생성할 때마다 ACME 챌린지 검증을 수행하는 글로벌 설정입니다.

기본 논리(`global.ingress.useNewIngressForCerts`이(가) `false`일 때)는 검증을 위해 기존 Ingress를 재사용합니다. 이 기본값은 일부 상황에 적합하지 않습니다. 플래그를 `true`으로 설정하면 각 검증에 대해 새 Ingress 객체가 생성됩니다.

`global.ingress.useNewIngressForCerts`은(는) GKE Ingress 컨트롤러와 함께 사용할 때 `true`로 설정할 수 없습니다.

## Gateway API {#gateway-api}

Gateway API 및 번들된 Envoy Gateway와 관련된 모든 설정에 대한 정보는 [Gateway API](../advanced/gateway-api/_index.md)를 참조하세요.

## GitLab 버전 {#gitlab-version}

> [!note]
> 이 값은 개발 목적 또는 GitLab 지원의 명시적 요청으로만 사용해야 합니다. 프로덕션 환경의 구성 파일에서 이 값을 사용하지 않도록 하세요. [Helm을 사용하여 배포](../installation/deployment.md#deploy-using-helm)에서 설명한 대로 버전을 설정합니다.

차트의 기본 이미지 태그에 사용되는 GitLab 버전은 `global.gitlabVersion` 키를 사용하여 변경할 수 있습니다:

```shell
--set global.gitlabVersion=11.0.1
```

이는 `webservice`, `sidekiq` 및 `migration` 차트에서 사용되는 기본 이미지 태그에 영향을 미칩니다. `gitaly`, `gitlab-shell` 및 `gitlab-runner` 이미지 태그는 GitLab 버전과 호환되는 버전으로 개별적으로 업데이트해야 합니다.

## 모든 이미지 태그에 접미사 추가 {#adding-suffix-to-all-image-tags}

Helm 차트에서 사용되는 모든 이미지의 이름에 접미사를 추가하려면 `global.image.tagSuffix` 키를 사용할 수 있습니다. 이 사용 사례의 예는 GitLab의 FIPS 호환 컨테이너 이미지를 사용하려는 경우입니다. 모두 `-fips` 확장명으로 빌드됩니다.

```shell
--set global.image.tagSuffix="-fips"
```

## 모든 컨테이너의 사용자 정의 시간대 {#custom-time-zone-for-all-containers}

모든 GitLab 컨테이너에 대한 사용자 정의 시간대를 설정하려면 `global.time_zone` 키를 사용할 수 있습니다. [tz 데이터베이스 시간대 목록](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)에서 사용 가능한 값에 대해 `TZ identifier`를 참조하세요. 기본값은 `UTC`입니다.

```shell
--set global.time_zone="America/Chicago"
```

## PostgreSQL 설정 구성 {#configure-postgresql-settings}

GitLab 글로벌 PostgreSQL 설정은 `global.psql` 키 아래에 위치합니다.

```yaml
global:
  psql:
    host: psql.example.com
    port: 5432
    database: gitlabhq_production
    username: gitlab
    applicationName:
    preparedStatements: false
    databaseTasks: true
    connectTimeout:
    keepalives:
    keepalivesIdle:
    keepalivesInterval:
    keepalivesCount:
    tcpUserTimeout:
    password:
      useSecret: true
      secret: gitlab-postgres
      key: psql-password
      file:
```

| 이름                 |  유형   | 기본값               | 설명 |
|:---------------------|:-------:|:----------------------|:------------|
| `host`               | 문자열  |                       | 외부 PostgreSQL 서버의 호스트명입니다. 필수. |
| `database`           | 문자열  | `gitlabhq_production` | PostgreSQL 서버에서 사용할 데이터베이스의 이름입니다. |
| `password.useSecret` | 부울 | `true`                | PostgreSQL 암호를 비밀 또는 파일에서 읽을지 여부를 제어합니다. |
| `password.file`      | 문자열  |                       | PostgreSQL 암호를 포함하는 파일의 경로를 정의합니다. `password.useSecret`이(가) true인 경우 무시됩니다 |
| `password.key`       | 문자열  |                       | PostgreSQL의 `password.key` 속성은 암호를 포함하는 비밀의 키 이름을 정의합니다. `password.useSecret`이(가) false인 경우 무시됩니다. |
| `password.secret`    | 문자열  |                       | PostgreSQL의 `password.secret` 속성은 당겨올 Kubernetes `Secret`의 이름을 정의합니다. `password.useSecret`이(가) false인 경우 무시됩니다. |
| `port`               | 정수 | `5432`                | PostgreSQL 서버에 연결할 포트입니다. |
| `username`           | 문자열  | `gitlab`              | 데이터베이스에 인증할 사용자명입니다. |
| `preparedStatements` | 부울 | `false`               | PostgreSQL 서버와 통신할 때 준비된 명령문을 사용할지 여부입니다. |
| `databaseTasks`      | 부울 | `true`                | GitLab이 지정된 데이터베이스에 대해 데이터베이스 작업을 수행해야 하는지 여부입니다. 호스트/포트/데이터베이스가 `main`과(와) 일치할 때 자동으로 비활성화됩니다. |
| `connectTimeout`     | 정수 |                       | 데이터베이스 연결을 기다릴 시간(초)입니다. |
| `keepalives`         | 정수 |                       | 클라이언트 측 TCP `keepalives`이(가) 사용되는지 여부를 제어합니다(`1`, 켜짐을 의미함, `0`, 꺼짐을 의미함). |
| `keepalivesIdle`     | 정수 |                       | TCP가 서버로 keepalive 메시지를 보내야 한다고 판단하기 전의 비활성 시간(초)입니다. 값이 0이면 시스템 기본값을 사용합니다. |
| `keepalivesInterval` | 정수 |                       | 서버에서 인정되지 않은 TCP keepalive 메시지를 재전송할 시간(초)입니다. 값이 0이면 시스템 기본값을 사용합니다. |
| `keepalivesCount`    | 정수 |                       | 클라이언트의 서버 연결이 중단된 것으로 간주되기 전에 손실될 수 있는 TCP `keepalives` 개수입니다. 값이 0이면 시스템 기본값을 사용합니다. |
| `tcpUserTimeout`     | 정수 |                       | 연결이 강제로 종료되기 전에 전송된 데이터가 승인받지 못한 상태로 남아 있을 수 있는 밀리초 수입니다. 값이 0이면 시스템 기본값을 사용합니다. |
| `applicationName`    | 문자열  |                       | 데이터베이스에 연결하는 애플리케이션의 이름입니다. 비활성화하려면 빈 문자열(`""`)로 설정합니다. 기본적으로 실행 중인 프로세스의 이름(예: `sidekiq`, `puma`)으로 설정됩니다. |

### 차트당 PostgreSQL {#postgresql-per-chart}

일부 복잡한 배포에서는 PostgreSQL에 대해 서로 다른 구성으로 이 차트의 다른 부분을 구성하고 싶을 수 있습니다. `v4.2.0`부터 `global.psql` 내에서 사용 가능한 모든 속성을 차트별로 설정할 수 있습니다(예: `gitlab.sidekiq.psql`). 로컬 설정은 제공된 경우 글로벌 값을 재정의하고 `global.psql`에서 제공되지 않은 항목을 상속합니다(`psql.load_balancing` 제외).

[PostgreSQL 로드 밸런싱](#postgresql-load-balancing)은(는) 설계상 글로벌에서 상속되지 않습니다.

### PostgreSQL SSL {#postgresql-ssl}

SSL 지원은 상호 TLS만 해당입니다. [issue #2034](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2034) 및 [issue #1817](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1817)을(를) 참조하세요.

GitLab을 상호 TLS를 통해 PostgreSQL 데이터베이스에 연결하려면 클라이언트 키, 클라이언트 인증서 및 서버 인증서 기관이 포함된 비밀을 만들어 서로 다른 비밀 키로 만듭니다. 그런 다음 `global.psql.ssl` 매핑을 사용하여 비밀의 구조를 설명합니다.

```yaml
global:
  psql:
    ssl:
      secret: db-example-ssl-secrets # Name of the secret
      clientCertificate: cert.pem    # Secret key storing the certificate
      clientKey: key.pem             # Secret key of the certificate's key
      serverCA: server-ca.pem        # Secret key containing the CA for the database server
```

| 이름                |  유형  | 기본값 | 설명 |
|:--------------------|:------:|:--------|:------------|
| `secret`            | 문자열 |         | 다음 키를 포함하는 Kubernetes `Secret`의 이름 |
| `clientCertificate` | 문자열 |         | `Secret` 내의 클라이언트 인증서를 포함하는 키의 이름입니다. |
| `clientKey`         | 문자열 |         | `Secret` 내의 클라이언트 인증서의 키 파일을 포함하는 키의 이름입니다. |
| `serverCA`          | 문자열 |         | `Secret` 내의 서버 인증서 기관을 포함하는 키의 이름입니다. |

`extraEnv` 값을 올바른 키로 지정하도록 설정해야 할 수 있습니다.

```yaml
global:
  extraEnv:
      PGSSLCERT: '/etc/gitlab/postgres/ssl/client-certificate.pem'
      PGSSLKEY: '/etc/gitlab/postgres/ssl/client-key.pem'
      PGSSLROOTCERT: '/etc/gitlab/postgres/ssl/server-ca.pem'
```

### PostgreSQL 로드 밸런싱 {#postgresql-load-balancing}

이 기능에는 [외부 PostgreSQL](../advanced/external-db/_index.md)의 사용이 필요합니다. 이 차트는 PostgreSQL을 HA 방식으로 배포하지 않기 때문입니다.

GitLab의 Rails 컴포넌트는 [PostgreSQL 클러스터를 활용하여 읽기 전용 쿼리 로드 밸런싱](https://docs.gitlab.com/administration/postgresql/database_load_balancing/)을(를) 수행할 수 있습니다.

이 기능은 두 가지 방식으로 구성할 수 있습니다:

- 보조 서버의 정적 호스트명 목록 사용
- DNS 기반 서비스 검색 메커니즘 사용

정적 호스트명 목록을 사용한 구성은 간단합니다:

```yaml
global:
  psql:
    host: primary.database
    load_balancing:
       hosts:
       - secondary-1.database
       - secondary-2.database
```

서비스 검색의 구성은 더 복잡할 수 있습니다. 이 구성, 파라미터 및 관련 동작에 대한 전체 세부 정보는 [GitLab Administration documentation](https://docs.gitlab.com/administration/) 의 [Service Discovery](https://docs.gitlab.com/administration/postgresql/database_load_balancing/#service-discovery)를 참조하세요.

```yaml
global:
  psql:
    host: primary.database
    load_balancing:
      discover:
        record:  secondary.postgresql.service.consul
        # record_type: A
        # nameserver: localhost
        # port: 8600
        # interval: 60
        # disconnect_timeout: 120
        # use_tcp: false
        # max_replica_pools: 30
```

[stale read 처리](https://docs.gitlab.com/administration/postgresql/database_load_balancing/#handling-stale-reads)와 관련하여 추가적인 튜닝도 가능합니다. GitLab Administration documentation은 이러한 항목을 자세히 다루며 `load_balancing` 아래에 직접 속성을 추가할 수 있습니다.

```yaml
global:
  psql:
    load_balancing:
      max_replication_difference: # See documentation
      max_replication_lag_time:   # See documentation
      replica_check_interval:     # See documentation
```

## Redis 설정 구성 {#configure-redis-settings}

GitLab 글로벌 Redis 설정은 `global.redis` 키 아래에 위치합니다.

외부 Redis 인스턴스가 필요합니다. 구성하려면 [고급 문서](../advanced/external-redis/_index.md)를 따르세요.

```yaml
global:
  redis:
    host: redis.example.com
    database: 7
    port: 6379
    auth:
      enabled: true
      secret: gitlab-redis
      key: redis-password
    scheme:
```

| 이름             |  유형   | 기본값 | 설명 |
|:-----------------|:-------:|:--------|:------------|
| `connectTimeout` | 정수 |         | Redis 연결을 기다릴 시간(초)입니다. 값을 지정하지 않으면 클라이언트 기본값은 1초입니다. |
| `readTimeout`    | 정수 |         | Redis 읽기를 기다릴 시간(초)입니다. 값을 지정하지 않으면 클라이언트 기본값은 1초입니다. |
| `writeTimeout`   | 정수 |         | Redis 쓰기를 기다릴 시간(초)입니다. 값을 지정하지 않으면 클라이언트 기본값은 1초입니다. |
| `host`           | 문자열  |         | Redis 서버의 호스트명입니다. `redisYmlOverride`을(를) 사용하지 않을 때 필수입니다. |
| `port`           | 정수 | `6379`  | Redis 서버에 연결할 포트입니다. |
| `database`       | 정수 | `0`     | Redis 서버에서 연결할 데이터베이스입니다. |
| `user`           | 문자열  |         | Redis에 대해 인증하는 데 사용되는 사용자(Redis 6.0+)입니다. |
| `auth.enabled`   | 부울 | `true`  | `auth.enabled`은(는) Redis 인스턴스로 암호를 사용할지 여부를 전환합니다. |
| `auth.key`       | 문자열  |         | Redis의 `auth.key` 속성은 암호를 포함하는 비밀의 키 이름을 정의합니다. |
| `auth.secret`    | 문자열  |         | Redis의 `auth.secret` 속성은 당겨올 Kubernetes `Secret`의 이름을 정의합니다. |
| `scheme`         | 문자열  | `redis` | Redis URL을 생성하는 데 사용할 URI 스킴입니다. 유효한 값은 `redis`, `rediss` 및 `tcp`입니다. `rediss` (SSL 암호화된 연결) 스킴을 사용하는 경우 서버에서 사용하는 인증서는 시스템의 신뢰할 수 있는 체인의 일부여야 합니다. 이는 [사용자 정의 인증서 기관](#custom-certificate-authorities) 목록에 추가하여 수행할 수 있습니다. |
| `redisTLS`       | 객체  |         | Redis 연결을 위한 TLS 구성입니다. 아래 [Redis TLS 구성](#redis-tls-configuration)을(를) 참조하세요. |

### Redis Sentinel 지원 {#redis-sentinel-support}

GitLab 차트는 [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/) 클러스터에 연결을 지원합니다. `global.redis.host`를 Sentinel 마스터 이름(`sentinel.conf`에 지정됨)으로 설정하고 Sentinel 노드를 `global.redis.sentinels` 아래에 나열합니다.

```yaml
global:
  redis:
    host: redis.example.com
    port: 6379
    sentinels:
      - host: sentinel1.example.com
        port: 26379
      - host: sentinel2.example.com
        port: 26379
    auth:
      enabled: true
      secret: gitlab-redis
      key: redis-password
```

| 이름                |  유형   | 기본값 | 설명 |
|:--------------------|:-------:|:--------|:------------|
| `host`              | 문자열  |         | `host` 속성은 `sentinel.conf`에 지정된 대로 클러스터 이름으로 설정해야 합니다. |
| `sentinels.[].host` | 문자열  |         | Redis HA 설정을 위한 Redis Sentinel 서버의 호스트명입니다. |
| `sentinels.[].port` | 정수 | `26379` | Redis Sentinel 서버에 연결할 포트입니다. |

일반 [Redis 설정 구성](#configure-redis-settings)의 이전 Redis 속성은 위의 표에서 다시 지정되지 않는 한 Sentinel 지원에 계속 적용됩니다.

#### Redis Sentinel 암호 지원 {#redis-sentinel-password-support}

{{< history >}}

- GitLab 17.1에서 [도입됨](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3792).

{{< /history >}}

```yaml
global:
  redis:
    host: redis.example.com
    port: 6379
    sentinels:
      - host: sentinel1.example.com
        port: 26379
      - host: sentinel2.example.com
        port: 26379
    auth:
      enabled: true
      secret: gitlab-redis
      key: redis-password
    sentinelAuth:
      enabled: false
      secret: gitlab-redis-sentinel
      key: sentinel-password
```

| 이름                   |  유형   | 기본값 | 설명 |
|:-----------------------|:-------:|:--------|:------------|
| `sentinelAuth.enabled` | 부울 | `false` | `sentinelAuth.enabled`은(는) Redis Sentinel 인스턴스로 암호를 사용할지 여부를 전환합니다. |
| `sentinelAuth.key`     | 문자열  |         | Redis의 `sentinelAuth.key` 속성은 암호를 포함하는 비밀의 키 이름을 정의합니다. |
| `sentinelAuth.secret`  | 문자열  |         | Redis의 `sentinelAuth.secret` 속성은 당겨올 Kubernetes `Secret`의 이름을 정의합니다. |

`global.redis.sentinelAuth`을(를) 사용하여 모든 Sentinel 인스턴스에 대해 Sentinel 암호를 구성할 수 있습니다.

`sentinelAuth`은(는) [Redis 인스턴스 특정 설정](#multiple-redis-support) 또는 [`global.redis.redisYmlOverride`](../advanced/external-redis/_index.md#redisyml-override)으로 재정의할 수 없습니다.

### 여러 Redis 지원 {#multiple-redis-support}

GitLab 차트는 현재 서로 다른 지속성 클래스에 대해 별도의 Redis 인스턴스로 실행할 수 있습니다:

| 인스턴스          | 목적 |
|:------------------|:--------|
| `actioncable`     | ActionCable을(를) 위한 Pub/Sub 큐 백엔드 |
| `cache`           | 캐시된 데이터 저장 |
| `kas`             | KAS 특정 데이터 저장 |
| `queues`          | Sidekiq 백그라운드 작업 저장 |
| `rateLimiting`    | RackAttack 및 Application Limits를 위한 속도 제한 사용법 저장 |
| `repositoryCache` | 저장소 관련 데이터 저장 |
| `sessions`        | 사용자 세션 데이터 저장 |
| `sharedState`     | 분산 잠금 같은 다양한 지속적 데이터 저장 |
| `traceChunks`     | 작업 추적을 임시로 저장 |
| `workhorse`       | Workhorse를 위한 Pub/sub 큐 백엔드 |

임의 개수의 인스턴스를 지정할 수 있습니다. 지정되지 않은 모든 인스턴스는 `global.redis.host`으로 지정된 기본 Redis 인스턴스에서 처리됩니다. 유일한 예외는 [GitLab agent server (KAS)](gitlab/kas/_index.md)입니다. 다음 순서대로 Redis 구성을 찾습니다:

1. `global.redis.kas`
1. `global.redis.sharedState`
1. `global.redis.host`

예:

```yaml
global:
  redis:
    host: redis.example
    port: 6379
    auth:
      enabled: true
      secret: redis-secret
      key: redis-password
    actioncable:
      host: cable.redis.example
      port: 6379
      auth:
        enabled: true
        secret: cable-secret
        key: cable-password
    cache:
      host: cache.redis.example
      port: 6379
      auth:
        enabled: true
        secret: cache-secret
        key: cache-password
    kas:
      host: kas.redis.example
      port: 6379
      auth:
        enabled: true
        secret: kas-secret
        key: kas-password
    queues:
      host: queues.redis.example
      port: 6379
      auth:
        enabled: true
        secret: queues-secret
        key: queues-password
    rateLimiting:
      host: rateLimiting.redis.example
      port: 6379
      auth:
        enabled: true
        secret: rateLimiting-secret
        key: rateLimiting-password
    repositoryCache:
      host: repositoryCache.redis.example
      port: 6379
      auth:
        enabled: true
        secret: repositoryCache-secret
        key: repositoryCache-password
    sessions:
      host: sessions.redis.example
      port: 6379
      auth:
        enabled: true
        secret: sessions-secret
        key: sessions-password
    sharedState:
      host: shared.redis.example
      port: 6379
      auth:
        enabled: true
        secret: shared-secret
        key: shared-password
    traceChunks:
      host: traceChunks.redis.example
      port: 6379
      auth:
        enabled: true
        secret: traceChunks-secret
        key: traceChunks-password
    workhorse:
      host: workhorse.redis.example
      port: 6379
      auth:
        enabled: true
        secret: workhorse-secret
        key: workhorse-password
```

다음 표는 Redis 인스턴스의 각 사전에 대한 속성을 설명합니다.

| 이름                |  유형   | 기본값 | 설명 |
|:--------------------|:-------:|:--------|:------------|
| `.host`             | 문자열  |         | 사용할 데이터베이스가 있는 Redis 서버의 호스트명입니다. |
| `.port`             | 정수 | `6379`  | Redis 서버에 연결할 포트입니다. |
| `.auth.enabled` | 부울 | `true`  | `auth.enabled`은(는) Redis 인스턴스로 암호를 사용할지 여부를 전환합니다. |
| `.auth.key`     | 문자열  |         | Redis의 `auth.key` 속성은 암호를 포함하는 비밀의 키 이름을 정의합니다. |
| `.auth.secret`  | 문자열  |         | Redis의 `auth.secret` 속성은 당겨올 Kubernetes `Secret`의 이름을 정의합니다. |

기본 Redis 정의는 분리되지 않은 추가적인 지속성 클래스가 있기 때문에 필요합니다.

각 인스턴스 정의는 Redis Sentinel 지원을 사용할 수도 있습니다. Sentinel 구성은 **are not shared** Sentinel을 사용하는 각 인스턴스에 대해 지정되어야 합니다. Sentinel 서버를 구성하는 데 사용되는 속성에 대해 [Sentinel 구성](#redis-sentinel-support)을(를) 참조하세요.

### 보안 Redis 스킴(SSL) 지정 {#specify-secure-redis-scheme-ssl}

Redis와의 SSL 연결 방법:

1. 구성을 업데이트하여 `rediss` (두 배의 `s`) 스킴 파라미터를 사용하세요.
1. 구성에서 `authClients`을(를) `false`로 설정합니다:

   ```yaml
   global:
     redis:
       scheme: rediss
   redis:
     tls:
       enabled: true
       authClients: false
   ```

   이 구성은 [Redis가 기본적으로 상호 TLS를 사용](https://redis.io/docs/latest/operate/oss_and_stack/management/security/encryption/)하기 때문에 필요하며 모든 차트 컴포넌트가 지원하지는 않습니다.

1. 외부 Redis 서버에서 TLS를 구성하고 차트 컴포넌트가 Redis 인증서를 생성하는 데 사용되는 인증서 기관을 신뢰하는지 확인합니다.
1. 선택 사항입니다. 사용자 정의 인증서 기관을 사용하는 경우 [Custom Certificate Authorities](#custom-certificate-authorities) 글로벌 구성을 참조하세요.

### Redis TLS 구성 {#redis-tls-configuration}

`rediss` 스킴을 사용할 때 `redisTLS` 설정을 사용하여 Redis 연결에 대한 클라이언트 인증서 및 CA 인증서를 선택적으로 구성할 수 있습니다:

```yaml
global:
  redis:
    scheme: rediss
    redisTLS:
      cert:
        secret: redis-client-cert
        key: cert
      key:
        secret: redis-client-key
        key: key
      caFile:
        secret: redis-ca
        key: ca.crt
```

`redisTLS` 구성은 다음을 지원합니다:

| 이름                |  유형  | 기본값 | 설명 |
|:--------------------|:------:|:--------|:------------|
| `cert.secret`       | 문자열 |         | 클라이언트 인증서를 포함하는 Kubernetes 비밀 이름 |
| `cert.key`          | 문자열 |         | 클라이언트 인증서를 포함하는 비밀의 키 |
| `key.secret`        | 문자열 |         | 클라이언트 개인 키를 포함하는 Kubernetes 비밀 이름 |
| `key.key`           | 문자열 |         | 클라이언트 개인 키를 포함하는 비밀의 키 |
| `caFile.secret`     | 문자열 |         | CA 인증서를 포함하는 Kubernetes 비밀 이름 |
| `caFile.key`        | 문자열 |         | CA 인증서를 포함하는 비밀의 키 |

세 가지 모두(`cert`, `key` 및 `caFile`)는 선택 사항입니다. 지정하지 않으면 시스템은 기본 CA 인증서를 사용합니다.

#### Sentinel TLS 구성 {#sentinel-tls-configuration}

Redis Sentinel을 TLS와 함께 사용할 때 `sentinelTLS` 설정을 사용하여 Sentinel 연결에 대한 클라이언트 인증서 및 CA 인증서를 구성할 수 있습니다:

```yaml
global:
  redis:
    sentinels:
      - host: sentinel1.example.com
        port: 26379
      - host: sentinel2.example.com
        port: 26379
    sentinelTLS:
      enabled: true
      cert:
        secret: sentinel-client-cert
        key: cert
      key:
        secret: sentinel-client-key
        key: key
      caFile:
        secret: sentinel-ca
        key: ca.crt
```

`sentinelTLS` 구성은 다음을 지원합니다:

| 이름                |  유형   | 기본값 | 설명 |
|:--------------------|:-------:|:--------|:------------|
| `enabled`           | 부울 | `false` | Sentinel 연결에 대해 TLS를 활성화하려면 `true`으로 설정합니다 |
| `cert.secret`       | 문자열  |         | 클라이언트 인증서를 포함하는 Kubernetes 비밀 이름 |
| `cert.key`          | 문자열  |         | 클라이언트 인증서를 포함하는 비밀의 키 |
| `key.secret`        | 문자열  |         | 클라이언트 개인 키를 포함하는 Kubernetes 비밀 이름 |
| `key.key`           | 문자열  |         | 클라이언트 개인 키를 포함하는 비밀의 키 |
| `caFile.secret`     | 문자열  |         | CA 인증서를 포함하는 Kubernetes 비밀 이름 |
| `caFile.key`        | 문자열  |         | CA 인증서를 포함하는 비밀의 키 |

모든 인증서 옵션은 선택 사항입니다. 지정하지 않으면 시스템은 기본 CA 인증서를 사용합니다.

### 암호가 없는 Redis 서버 {#password-less-redis-servers}

Google Cloud Memorystore와 같은 일부 Redis 서비스는 암호 및 관련 `AUTH` 명령을 사용하지 않습니다. 암호의 사용 및 요구 사항은 다음 구성 설정을 통해 비활성화할 수 있습니다:

```yaml
global:
  redis:
    auth:
      enabled: false
    host: ${REDIS_PRIVATE_IP}
```

## Registry 설정 구성 {#configure-registry-settings}

글로벌 Registry 설정은 `global.registry` 키 아래에 위치합니다.

```yaml
global:
  registry:
    bucket: registry
    certificate:
    httpSecret:
    notificationSecret:
    notifications: {}
    ## Settings used by other services, referencing registry:
    enabled: true
    host:
    api:
      protocol: http
      serviceName: registry
      port: 5000
    tokenIssuer: gitlab-issuer
```

`bucket`, `certificate`, `httpSecret` 및 `notificationSecret` 설정에 대한 더 자세한 내용은 [registry chart](registry/_index.md) 내 문서를 참조하세요.

`enabled`, `host`, `api` 및 `tokenIssuer`에 대한 자세한 내용은 [명령줄 옵션](../installation/command-line-options.md) 및 [Webservice](gitlab/webservice/_index.md) 문서를 참조하세요

`host`은(는) 자동 생성되는 외부 registry 호스트명 참조를 재정의하는 데 사용됩니다.

### `notifications` {#notifications}

이 설정은 [Registry 알림](https://distribution.github.io/distribution/about/notifications/)을 구성하는 데 사용됩니다. 업스트림 사양에 따라 맵을 입력하지만 Kubernetes 비밀로 민감한 헤더를 제공하는 추가 기능을 포함합니다. 예를 들어 Authorization 헤더에 민감한 데이터가 포함되고 다른 헤더에는 정규 데이터가 포함된 다음 스니펫을 생각해 보세요:

```yaml
global:
  registry:
    notifications:
      events:
        includereferences: true
      endpoints:
        - name: CustomListener
          url: https://mycustomlistener.com
          timeout: 500mx
          # DEPRECATED: use `maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243.
          # When using `maxretries`, `threshold` is ignored: https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#endpoints
          threshold: 5
          maxretries: 5
          backoff: 1s
          headers:
            X-Random-Config: [plain direct]
            Authorization:
              secret: registry-authorization-header
              key: password
```

이 예제에서 헤더 `X-Random-Config`는 정규 헤더이며 값은 `values.yaml` 파일에 일반 텍스트로 또는 `--set` 플래그를 통해 제공될 수 있습니다. 하지만 헤더 `Authorization`는 민감한 헤더이므로 Kubernetes 비밀에서 탑재하는 것이 좋습니다. 비밀 구조에 대한 자세한 내용은 [비밀 문서](../installation/secrets.md#registry-sensitive-notification-headers)를 참조하세요

## Gitaly 설정 구성 {#configure-gitaly-settings}

글로벌 Gitaly 설정은 `global.gitaly` 키 아래에 위치합니다.

```yaml
global:
  gitaly:
    internal:
      names:
        - default
        - default2
    external:
      - name: node1
        hostname: node1.example.com
        port: 8075
    authToken:
      secret: gitaly-secret
      key: token
    tls:
      enabled: true
      secretName: gitlab-gitaly-tls
```

### Gitaly 호스트 {#gitaly-hosts}

[Gitaly](https://gitlab.com/gitlab-org/gitaly)는 Git 저장소에 대한 고수준 RPC 액세스를 제공하고 GitLab에서 만든 모든 Git 호출을 처리하는 서비스입니다.

관리자는 다음과 같은 방식으로 Gitaly 노드를 사용하도록 선택할 수 있습니다:

- [차트에 내부](#internal)로 `StatefulSet`의 일부로 [Gitaly 차트](gitlab/gitaly/_index.md)를 통해.
- [차트 외부](#external)로 외부 애완동물로.
- [혼합 환경](#mixed)을 사용하여 내부 및 외부 노드 모두.

새 프로젝트에 사용할 노드를 관리하는 방법에 대한 자세한 내용은 [Repository Storage Paths](https://docs.gitlab.com/administration/repository_storage_paths/) 문서를 참조하세요.

`gitaly.host`이(가) 제공되면 `gitaly.internal` 및 `gitaly.external` 속성이 *무시됩니다*. [deprecated Gitaly settings](#deprecated-gitaly-settings)를 참조하세요.

Gitaly 인증 토큰은 이 시점에 모든 Gitaly 서비스(내부 또는 외부)에 대해 동일해야 합니다. 이들이 정렬되어 있는지 확인하세요. 자세한 내용은 [issue #1992](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1992)를 참조하세요.

#### `internal` {#internal}

`internal` 키는 현재 한 가지 키 `names`로만 구성되며, 이는 차트에서 관리할 [저장소 이름](https://docs.gitlab.com/administration/repository_storage_paths/)입니다. 나열된 각 이름에 대해 *논리적 순서로* 하나의 포드가 생성되며 `${releaseName}-gitaly-${ordinal}`으로 이름이 지정됩니다. 여기서 `ordinal`는 `names` 목록 내의 인덱스입니다. 동적 프로비저닝이 활성화된 경우 `PersistentVolumeClaim`이(가) 일치합니다.

이 목록의 기본값은 `['default']`이며 하나의 [저장소 경로](https://docs.gitlab.com/administration/repository_storage_paths/)와 관련된 1개의 포드를 제공합니다.

`gitaly.internal.names`에서 항목을 추가하거나 제거하여 이 항목의 수동 확장이 필요합니다. 축소할 때 다른 노드로 이동되지 않은 모든 저장소는 사용할 수 없게 됩니다. Gitaly 차트는 `StatefulSet`이므로 동적으로 프로비저닝된 디스크는 *회수되지 않습니다*. 즉, 데이터 디스크가 유지되며 `names` 목록에 노드를 다시 추가하여 세트를 다시 확장할 때 데이터에 액세스할 수 있습니다.

샘플 [여러 내부 노드의 구성](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-internal.yaml)은(는) 예제 폴더에서 찾을 수 있습니다.

#### `external` {#external}

`external` 키는 클러스터 외부의 Gitaly 노드에 대한 구성을 제공합니다. 이 목록의 각 항목에는 다음 키가 있습니다:

- `name`: [저장소](https://docs.gitlab.com/administration/repository_storage_paths/)의 이름입니다. [`name: default` 항목이 필요](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#gitlab-requires-a-default-repository-storage)합니다.
- `address`: (선택 사항) Gitaly 서비스의 전체 URI(예: `dns://8.8.8.8:53/gitaly.example.com` 또는 TLS의 경우 `dns+tls://8.8.8.8:53/gitaly.example.com`). 지정된 경우 이는 `hostname` 및 `port`보다 우선합니다. [고급 구성 가이드](../advanced/external-gitaly/_index.md#dns-address-format)를 참조하여 자세히 알아보세요.
- `hostname`: Gitaly 서비스의 호스트입니다. `address`가 지정되지 않은 경우 필수입니다.
- `port`: (선택 사항) 호스트에 도달할 포트 번호입니다. `8075`로 기본값이 지정됩니다. `address`이 지정된 경우 무시됩니다.
- `tlsEnabled`: (선택 사항) `global.gitaly.tls.enabled`를 이 특정 항목에 대해 재정의합니다. `address`이 지정된 경우 무시됩니다.

외부 Gitaly 서비스 사용을 위한 [고급 구성](../advanced/_index.md) 가이드를 제공합니다. [고급 구성](../advanced/external-gitaly/_index.md) 가이드를 제공합니다. 예제 폴더에서 샘플 [여러 외부 서비스의 구성](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-external.yaml)을 찾을 수도 있습니다.

외부 [Praefect](https://docs.gitlab.com/administration/gitaly/praefect/)를 사용하여 가용성이 높은 Gitaly 서비스를 제공할 수 있습니다. 두 가지의 구성은 클라이언트의 관점에서 차이가 없기 때문에 교환할 수 있습니다.

#### 혼합 {#mixed}

내부 및 외부 Gitaly 노드를 모두 사용할 수 있지만 다음을 주의해야 합니다:

- 항상 [`default`이라는 노드가 있어야 하며](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#gitlab-requires-a-default-repository-storage) 내부에서는 기본적으로 제공됩니다.
- 외부 노드가 먼저 채워지고 그 다음에 내부.

예제 폴더에서 [내부 및 외부 노드의 혼합 구성](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-mixed.yaml)을 찾을 수 있습니다.

### `authToken` {#authtoken}

Gitaly용 `authToken` 속성에는 두 개의 하위 키가 있습니다:

- `secret`는 가져올 Kubernetes `Secret`의 이름을 정의합니다.
- `key`는 위의 시크릿에서 `authToken`를 포함하는 키의 이름을 정의합니다.

모든 Gitaly 노드는 **must**해야 합니다.

### 더 이상 사용되지 않는 Gitaly 설정 {#deprecated-gitaly-settings}

| 이름                         |  유형   | 기본값 | 설명 |
|:-----------------------------|:-------:|:--------|:------------|
| `host` *(더 이상 사용되지 않음)*        | 문자열  |         | 사용할 Gitaly 서버의 호스트명입니다. 이는 `serviceName` 대신 생략할 수 있습니다. 이 설정을 사용하면 `internal` 또는 `external`의 모든 값을 재정의합니다. |
| `port` *(더 이상 사용되지 않음)*        | 정수 | `8075`  | Gitaly 서버에 연결할 포트입니다. |
| `serviceName` *(더 이상 사용되지 않음)* | 문자열  |         | Gitaly 서버를 운영하는 `service`의 이름입니다. 이것이 있고 `host`가 없으면 차트는 서비스의 호스트명과 현재 `.Release.Name`을(를) `host` 값 대신에 템플릿합니다. 이는 Gitaly를 전체 GitLab 차트의 일부로 사용할 때 편리합니다. |

### TLS 설정 {#tls-settings}

Gitaly를 TLS를 통해 제공하도록 구성하는 것은 [Gitaly 차트의 문서](gitlab/gitaly/_index.md#running-gitaly-over-tls)에 자세히 설명되어 있습니다.

## Praefect 설정 구성 {#configure-praefect-settings}

전역 Praefect 설정은 `global.praefect` 키 아래에 있습니다.

Praefect는 기본적으로 비활성화되어 있습니다. 추가 설정 없이 활성화하면 3개의 Gitaly 복제본이 생성되고 Praefect 데이터베이스는 기본 PostgreSQL 인스턴스에서 수동으로 생성해야 합니다.

### Praefect 활성화 {#enable-praefect}

Praefect를 기본 설정으로 활성화하려면 `global.praefect.enabled=true`을(를) 설정하세요.

자세한 내용은 [Gitaly 클러스터(Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/)를 참조하세요.

### Praefect의 전역 설정 {#global-settings-for-praefect}

```yaml
global:
  praefect:
    enabled: false
    virtualStorages:
    - name: default
      gitalyReplicas: 3
      maxUnavailable: 1
    dbSecret: {}
    psql: {}
```

| 이름              | 유형    | 기본값    | 설명 |
|-------------------|---------|------------|-------------|
| `enabled`         | 부울 | `false`    | Praefect를 활성화할지 여부입니다. |
| `virtualStorages` | 목록    |            | 원하는 가상 스토리지 목록(각각 Gitaly `StatefulSet`으로 지원)입니다. 기본값은 [여러 가상 스토리지](https://docs.gitlab.com/administration/gitaly/praefect/#multiple-virtual-storages)를 참조하세요. |
| `dbSecret.secret` | 문자열  |            | 데이터베이스 인증에 사용할 시크릿의 이름입니다. |
| `dbSecret.key`    | 문자열  |            | `dbSecret.secret`에 있는 키의 이름입니다. |
| `psql.host`       | 문자열  |            | 사용할 데이터베이스 서버의 호스트명입니다(외부 데이터베이스 사용 시). |
| `psql.port`       | 문자열  |            | 데이터베이스 서버의 포트 번호입니다(외부 데이터베이스 사용 시). |
| `psql.user`       | 문자열  | `praefect` | 사용할 데이터베이스 사용자입니다. |
| `psql.dbName`     | 문자열  | `praefect` | 사용할 데이터베이스의 이름입니다. |

## MinIO 설정 구성 {#configure-minio-settings}

GitLab 전역 MinIO 설정은 `global.minio` 키 아래에 있습니다. 이러한 설정에 대한 자세한 내용은 [MinIO 차트](minio/_index.md)의 문서를 참조하세요.

```yaml
global:
  minio:
    enabled: true
    credentials: {}
```

## `appConfig` 설정 구성 {#configure-appconfig-settings}

[Webservice](gitlab/webservice/_index.md) , [Sidekiq](gitlab/sidekiq/_index.md) , 및 [Gitaly](gitlab/gitaly/_index.md) 차트는 여러 설정을 공유하며, 이는 `global.appConfig` 키로 구성됩니다.

```yaml
global:
  appConfig:
    # cdnHost:
    relativeUrlRoot: ""
    contentSecurityPolicy:
      enabled: false
      report_only: true
      # directives: {}
    enableUsagePing: true
    enableSeatLink: true
    enableImpersonation: true
    applicationSettingsCacheSeconds: 60
    usernameChangingEnabled: true
    issueClosingPattern:
    defaultTheme:
    defaultColorMode:
    defaultSyntaxHighlightingTheme:
    defaultProjectsFeatures:
      issues: true
      mergeRequests: true
      wiki: true
      snippets: true
      builds: true
      containerRegistry: true
    webhookTimeout:
    gravatar:
      plainUrl:
      sslUrl:
    extra:
      googleAnalyticsId:
      matomoUrl:
      matomoSiteId:
      matomoDisableCookies:
      oneTrustId:
      googleTagManagerNonceId:
      bizible:
    object_store:
      enabled: false
      proxy_download: true
      storage_options: {}
      connection: {}
    lfs:
      enabled: true
      proxy_download: true
      bucket: git-lfs
      connection: {}
    artifacts:
      enabled: true
      proxy_download: true
      bucket: gitlab-artifacts
      connection: {}
    uploads:
      enabled: true
      proxy_download: true
      bucket: gitlab-uploads
      connection: {}
    packages:
      enabled: true
      proxy_download: true
      bucket: gitlab-packages
      connection: {}
    externalDiffs:
      enabled:
      when:
      proxy_download: true
      bucket: gitlab-mr-diffs
      connection: {}
    terraformState:
      enabled: false
      bucket: gitlab-terraform-state
      connection: {}
    ciSecureFiles:
      enabled: false
      bucket: gitlab-ci-secure-files
      connection: {}
    dependencyProxy:
      enabled: false
      bucket: gitlab-dependency-proxy
      connection: {}
    backups:
      bucket: gitlab-backups
    microsoft_graph_mailer:
      enabled: false
      user_id: "YOUR-USER-ID"
      tenant: "YOUR-TENANT-ID"
      client_id: "YOUR-CLIENT-ID"
      client_secret:
        secret:
        key: secret
      azure_ad_endpoint: "https://login.microsoftonline.com"
      graph_endpoint: "https://graph.microsoft.com"
    incomingEmail:
      enabled: false
      address: ""
      host: "imap.gmail.com"
      port: 993
      ssl: true
      startTls: false
      user: ""
      password:
        secret:
        key: password
      mailbox: inbox
      idleTimeout: 60
      inboxMethod: "imap"
      clientSecret:
        key: secret
      pollInterval: 60
      deliveryMethod: webhook
      authToken: {}

    serviceDeskEmail:
      enabled: false
      address: ""
      host: "imap.gmail.com"
      port: 993
      ssl: true
      startTls: false
      user: ""
      password:
        secret:
        key: password
      mailbox: inbox
      idleTimeout: 60
      inboxMethod: "imap"
      clientSecret:
        key: secret
      pollInterval: 60
      deliveryMethod: webhook
      authToken: {}

    cron_jobs: {}
    sentry:
      enabled: false
      dsn:
      clientside_dsn:
      environment:
    gitlab_docs:
      enabled: false
      host: ""
    oidcProvider:
      openidIdTokenExpireInSeconds: 120
    smartcard:
      enabled: false
      CASecret:
      clientCertificateRequiredHost:
    sidekiq:
      routingRules: []
```

### 일반 애플리케이션 설정 {#general-application-settings}

{{< history >}}

- `relativeUrlRoot` 설정은 GitLab 18.4에서 [도입](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6121)되었습니다.

{{< /history >}}

Rails 애플리케이션의 일반적인 속성을 조정하는 데 사용할 수 있는 `appConfig` 설정이 아래에 설명되어 있습니다:

| 이름                                |  유형   | 기본값 | 설명 |
|:------------------------------------|:-------:|:--------|:------------|
| `cdnHost`                           | 문자열  | (비어 있음) | 정적 자산을 제공할 CDN의 기본 URL을 설정합니다(예: `https://mycdnsubdomain.fictional-cdn.com`). |
| `relativeUrlRoot`                   | 문자열  | (비어 있음) | GitLab에 대한 [상대 URL 루트](#configure-a-relative-url-root)를 설정합니다(예: `/gitlab`). 구성하면 GitLab은 루트 경로 대신 지정된 경로에서 액세스할 수 있습니다. |
| `contentSecurityPolicy`             | 구조  |         | [아래를 참조하세요](#content-security-policy). |
| `enableUsagePing`                   | 부울 | `true`  | [사용 ping 지원](https://docs.gitlab.com/administration/settings/usage_statistics/)을 비활성화할 수 있는 플래그입니다. |
| `enableSeatLink`                    | 부울 | `true`  | 시트 링크 지원을 비활성화할 수 있는 플래그입니다. |
| `enableImpersonation`               |         | `nil`   | [관리자의 사용자 가장](https://docs.gitlab.com/api/rest/authentication/#disable-impersonation)을 비활성화할 수 있는 플래그입니다. |
| `applicationSettingsCacheSeconds`   | 정수 | `60`    | [애플리케이션 설정 캐시](https://docs.gitlab.com/administration/application_settings_cache/)를 무효화하기 위한 간격 값(초 단위)입니다. |
| `usernameChangingEnabled`           | 부울 | `true`  | 사용자가 사용자명을 변경할 수 있는지 여부를 결정하는 플래그입니다. |
| `issueClosingPattern`               | 문자열  | (비어 있음) | [자동으로 이슈를 종료하는 패턴](https://docs.gitlab.com/administration/issue_closing_pattern/)입니다. |
| `defaultTheme`                      | 정수 |         | [GitLab 인스턴스의 기본 테마의 숫자 ID](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/lib/gitlab/themes.rb#L17-27)입니다. 테마의 ID를 나타내는 숫자를 사용합니다. |
| `defaultColorMode`                  | 정수 |         | [GitLab 인스턴스의 기본 색상 모드](https://gitlab.com/gitlab-org/gitlab/-/blob/66788a1de8c3dd3c5566d0f30fe1c2a1bae64bf9/lib/gitlab/color_modes.rb#L17-19)입니다. 색상 모드의 ID를 나타내는 숫자를 사용합니다. |
| `defaultSyntaxHighlightingTheme`    | 정수 |         | [GitLab 인스턴스의 기본 구문 강조 테마](https://gitlab.com/gitlab-org/gitlab/-/blob/66788a1de8c3dd3c5566d0f30fe1c2a1bae64bf9/lib/gitlab/color_schemes.rb#L12-17)입니다. 구문 강조 테마의 ID를 나타내는 숫자를 사용합니다. |
| `defaultProjectsFeatures.*feature*` | 부울 | `true`  | [아래를 참조하세요](#defaultprojectsfeatures). |
| `gitTimeout`                        | 정수 | `nil`   | GitLab Shell을 통해 수행되는 Git 가져오기, 가져오기 및 복제 작업의 시간 초과(초 단위)입니다. |
| `webhookTimeout`                    | 정수 | (비어 있음) | 훅이 [실패한 것으로 간주되기 전](https://docs.gitlab.com/user/project/integrations/webhooks/#auto-disabled-webhooks)의 대기 시간(초 단위)입니다. |
| `graphQlTimeout`                    | 정수 | (비어 있음) | Rails가 [GraphQL 요청을 완료](https://docs.gitlab.com/api/graphql/#limits)해야 하는 시간(초 단위)입니다. |

#### 콘텐츠 보안 정책 {#content-security-policy}

콘텐츠 보안 정책(CSP)을 설정하면 JavaScript 크로스 사이트 스크립팅(XSS) 공격을 방어하는 데 도움이 될 수 있습니다. 구성 세부 정보는 GitLab 설명서를 참조하세요. [콘텐츠 보안 정책 설명서](https://docs.gitlab.com/omnibus/settings/configuration/#set-a-content-security-policy)

GitLab은 자동으로 CSP에 대한 안전한 기본값을 제공합니다.

```yaml
global:
  appConfig:
    contentSecurityPolicy:
      enabled: true
      report_only: false
```

사용자 지정 CSP를 추가하려면:

```yaml
global:
  appConfig:
    contentSecurityPolicy:
      enabled: true
      report_only: false
      directives:
        default_src: "'self'"
        script_src: "'self' 'unsafe-inline' 'unsafe-eval' https://www.recaptcha.net https://apis.google.com"
        frame_ancestors: "'self'"
        frame_src: "'self' https://www.recaptcha.net/ https://content.googleapis.com https://content-compute.googleapis.com https://content-cloudbilling.googleapis.com https://content-cloudresourcemanager.googleapis.com"
        img_src: "* data: blob:"
        style_src: "'self' 'unsafe-inline'"
```

CSP 규칙을 잘못 구성하면 GitLab이 제대로 작동하지 않을 수 있습니다. 정책을 롤아웃하기 전에 `report_only`을(를) `true`로 변경하여 구성을 테스트할 수도 있습니다.

#### 상대 URL 루트 구성 {#configure-a-relative-url-root}

{{< details >}}

- 상태:  베타

{{< /details >}}

> [!warning]
> GitLab에 대한 상대 URL 구성에는 [Geo의 알려진 문제](https://gitlab.com/gitlab-org/gitlab/-/issues/456427) 와 [테스트 제한](https://gitlab.com/gitlab-org/gitlab/-/issues/439943)이 있습니다. 이미 상대 URL을 사용 중이고 서브도메인으로 마이그레이션하려면 [마이그레이션 가이드](https://docs.gitlab.com/administration/operations/migrate_to_subdomain)를 참조하세요.

GitLab을 자신의 도메인이나 서브도메인에 설치해야 하지만 필요한 경우 상대 URL 아래에 설치할 수 있습니다. 예를 들어 `https://example.com/gitlab`입니다.

모든 웹 서비스 배포의 인그레스가 이 경로를 앞에 붙일 것입니다.

```yaml
global:
  appConfig:
    relativeUrlRoot: "/gitlab"
  hosts:
    domain: example.com
    gitlab:
      name: example.com
```

#### `defaultProjectsFeatures` {#defaultprojectsfeatures}

기본적으로 새 프로젝트를 생성할 때 각 기능을 포함할지 여부를 결정하는 플래그입니다. 모든 플래그는 기본적으로 `true`입니다.

```yaml
defaultProjectsFeatures:
  issues: true
  mergeRequests: true
  wiki: true
  snippets: true
  builds: true
  containerRegistry: true
```

### Gravatar/Libravatar 설정 {#gravatarlibravatar-settings}

기본적으로 차트는 gravatar.com에서 사용 가능한 Gravatar 아바타 서비스와 함께 작동합니다. 그러나 필요한 경우 사용자 지정 Libravatar 서비스도 사용할 수 있습니다:

| 이름                |  유형  | 기본값 | 설명 |
|:--------------------|:------:|:--------|:------------|
| `gravatar.plainURL` | 문자열 | (비어 있음) | [Libravatar 인스턴스에 대한 HTTP URL(gravatar.com 대신)](https://docs.gitlab.com/administration/libravatar/)입니다. |
| `gravatar.sslUrl`   | 문자열 | (비어 있음) | [Libravatar 인스턴스에 대한 HTTPS URL(gravatar.com 대신)](https://docs.gitlab.com/administration/libravatar/)입니다. |

### GitLab 인스턴스에 분석 서비스 연결 {#hooking-analytics-services-to-the-gitlab-instance}

Google Analytics 및 Matomo와 같은 분석 서비스를 구성하기 위한 설정은 `appConfig` 아래의 `extra` 키 아래에 정의됩니다:

| 이름                            |  유형   | 기본값 | 설명 |
|:--------------------------------|:-------:|:--------|:------------|
| `extra.googleAnalyticsId`       | 문자열  | (비어 있음) | Google Analytics의 추적 ID입니다. |
| `extra.matomoSiteId`            | 문자열  | (비어 있음) | Matomo 사이트 ID입니다. |
| `extra.matomoUrl`               | 문자열  | (비어 있음) | Matomo URL입니다. |
| `extra.matomoDisableCookies`    | 부울 | (비어 있음) | Matomo 쿠키를 비활성화합니다(Matomo 스크립트의 `disableCookies`에 해당) |
| `extra.oneTrustId`              | 문자열  | (비어 있음) | OneTrust ID입니다. |
| `extra.googleTagManagerNonceId` | 문자열  | (비어 있음) | Google Tag Manager ID입니다. |
| `extra.bizible`                 | 부울 | `false` | Bizible 스크립트를 활성화하려면 true로 설정 |

### 통합 개체 저장소 {#consolidated-object-storage}

개체 저장소에 대한 개별 설정을 구성하는 방법을 설명하는 다음 섹션 외에도 공유 구성의 사용을 용이하게 하기 위해 통합 개체 저장소 구성을 추가했습니다. `object_store`을(를) 사용하여 `connection`를 한 번 구성할 수 있으며, 개별적으로 `connection` 속성으로 구성하지 않은 모든 개체 저장소 지원 기능에 사용됩니다.

```yaml
object_store:
  enabled: true
  proxy_download: true
  storage_options:
  connection:
    secret:
    key:
```

| 이름              |  유형   | 기본값 | 설명 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | 부울 | `false` | 통합 개체 저장소 사용을 활성화합니다. |
| `proxy_download`  | 부울 | `true`  | `bucket`에서 직접 다운로드하는 대신 GitLab을 통한 모든 다운로드의 프록시를 활성화합니다. |
| `storage_options` | 문자열  | `{}`    | [아래를 참조하세요](#storage_options). |
| `connection`      | 문자열  | `{}`    | [아래를 참조하세요](#connection). |

속성 구조가 공유되며 여기의 모든 속성은 아래의 개별 항목으로 재정의될 수 있습니다. `connection` 속성 구조는 동일합니다.

> [!note]
> `bucket`, `enabled`, 및 `proxy_download` 속성은 기본값에서 벗어나고자 할 경우 항목별로 구성해야 하는 유일한 속성입니다(`global.appConfig.artifacts.bucket`, ...).

`AWS` 공급자의 경우 [연결](#connection)(포함된 MinIO와 같은 모든 S3 호환 공급자)을 사용할 때 GitLab Workhorse는 모든 저장소 관련 업로드를 오프로드할 수 있습니다. 이 통합 구성을 사용할 때 자동으로 활성화됩니다.

### 버킷 지정 {#specify-buckets}

각 개체 유형은 다른 버킷에 저장되어야 합니다. 기본적으로 GitLab은 각 유형에 대해 다음 버킷 이름을 사용합니다:

| 개체 유형                  | 버킷 이름 |
|------------------------------|-------------|
| CI 아티팩트                 | `gitlab-artifacts` |
| Git LFS                      | `git-lfs`   |
| 패키지                     | `gitlab-packages` |
| 업로드                      | `gitlab-uploads` |
| 외부 병합 요청 차이 | `gitlab-mr-diffs` |
| Terraform 상태              | `gitlab-terraform-state` |
| CI 보안 파일              | `gitlab-ci-secure-files` |
| 종속성 프록시             | `gitlab-dependency-proxy` |
| 페이지                        | `gitlab-pages` |

이러한 기본값을 사용하거나 버킷 이름을 구성할 수 있습니다:

```shell
--set global.appConfig.artifacts.bucket=<BUCKET NAME> \
--set global.appConfig.lfs.bucket=<BUCKET NAME> \
--set global.appConfig.packages.bucket=<BUCKET NAME> \
--set global.appConfig.uploads.bucket=<BUCKET NAME> \
--set global.appConfig.externalDiffs.bucket=<BUCKET NAME> \
--set global.appConfig.terraformState.bucket=<BUCKET NAME> \
--set global.appConfig.ciSecureFiles.bucket=<BUCKET NAME> \
--set global.appConfig.dependencyProxy.bucket=<BUCKET NAME>
```

#### `storage_options` {#storage_options}

`storage_options`는 [S3 서버 측 암호화](https://docs.gitlab.com/administration/object_storage/#server-side-encryption-headers)를 구성하는 데 사용됩니다.

S3 버킷에서 기본 암호화를 설정하는 것이 암호화를 활성화하는 가장 쉬운 방법이지만 [암호화된 개체만 업로드되도록 버킷 정책을 설정](https://repost.aws/knowledge-center/s3-bucket-store-kms-encrypted-objects)할 수도 있습니다. 이를 수행하려면 `storage_options` 구성 섹션에서 적절한 암호화 헤더를 전송하도록 GitLab을 구성해야 합니다:

| 설정                             | 설명 |
|-------------------------------------|-------------|
| `server_side_encryption`            | 암호화 모드(`AES256` 또는 `aws:kms`) |
| `server_side_encryption_kms_key_id` | Amazon 리소스 이름입니다. `server_side_encryption`에서 `aws:kms`이(가) 사용될 때만 필요합니다. [KMS 암호화 사용에 대한 Amazon 설명서](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html)를 참조하세요 |

예:

```yaml
  enabled: true
  proxy_download: true
  connection:
    secret: gitlab-rails-storage
    key: connection
  storage_options:
    server_side_encryption: aws:kms
    server_side_encryption_kms_key_id: arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab
```

### LFS, 아티팩트, 업로드, 패키지, 외부 MR 차이 및 종속성 프록시 {#lfs-artifacts-uploads-packages-external-mr-diffs-and-dependency-proxy}

이러한 설정에 대한 자세한 내용은 아래에 나와 있습니다. 문서는 `bucket` 속성의 기본값을 제외하고는 구조가 동일하므로 개별적으로 반복되지 않습니다.

```yaml
  enabled: true
  proxy_download: true
  bucket:
  connection:
    secret:
    key:
```

| 이름             |  유형   | 기본값                                                      | 설명 |
|:-----------------|:-------:|:-------------------------------------------------------------|:------------|
| `enabled`        | 부울 | LFS, 아티팩트, 업로드 및 패키지의 경우 `true`로 기본값이 설정됩니다 | 개체 저장소와 함께 이러한 기능의 사용을 활성화합니다. |
| `proxy_download` | 부울 | `true`                                                       | `bucket`에서 직접 다운로드하는 대신 GitLab을 통한 모든 다운로드의 프록시를 활성화합니다. |
| `bucket`         | 문자열  | 다양함                                                      | 개체 저장소 공급자에서 사용할 버킷의 이름입니다. 기본값은 서비스에 따라 `git-lfs`, `gitlab-artifacts`, `gitlab-uploads` 또는 `gitlab-packages`입니다. |
| `connection`     | 문자열  | `{}`                                                         | [아래를 참조하세요](#connection). |

#### `connection` {#connection}

`connection` 속성은 Kubernetes Secret으로 전환되었습니다. 이 시크릿의 내용은 YAML 형식의 파일이어야 합니다. 기본값은 `{}`이고 `global.minio.enabled`가 `true`인 경우 무시됩니다.

이 속성에는 두 개의 하위 키가 있습니다: `secret` 및 `key`.

- `secret`는 Kubernetes Secret의 이름입니다. 이 값은 외부 개체 저장소를 사용하는 데 필요합니다.
- `key`는 YAML 블록을 포함하는 시크릿의 키 이름입니다. `connection`로 기본값이 지정됩니다.

유효한 구성 키는 [GitLab 작업 아티팩트 관리](https://docs.gitlab.com/administration/cicd/secure_files/#s3-compatible-connection-settings) 설명서에서 찾을 수 있습니다. 이것은 [Fog](https://github.com/fog/fog.github.com)와 일치하며 공급자 모듈 간에 다릅니다.

[AWS](https://fog.github.io/storage/#using-amazon-s3-and-fog) 및 [Google](https://fog.github.io/storage/#google-cloud-storage) 공급자의 예는 [`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)에서 찾을 수 있습니다.

- [`rails.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.s3.yaml)
- [`rails.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.gcs.yaml)
- [`rails.azurerm.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.azurerm.yaml)

`connection`의 내용을 포함하는 YAML 파일을 만들었으면 이 파일을 사용하여 Kubernetes에 시크릿을 만듭니다.

```shell
kubectl create secret generic gitlab-rails-storage \
    --from-file=connection=rails.yaml
```

#### `when`(외부 MR 차이만 해당) {#when-only-for-external-mr-diffs}

`externalDiffs` 설정에는 [개체 저장소에 특정 차이를 조건부로 저장](https://docs.gitlab.com/administration/merge_request_diffs/#alternative-in-database-storage)하기 위한 추가 키 `when`이(가) 있습니다. 이 설정은 기본적으로 차트에서 비어 있으며 Rails 코드에 의해 기본값을 할당하도록 남겨져 있습니다.

#### `cdn`(CI 아티팩트만 해당) {#cdn-only-for-ci-artifacts}

`artifacts` 설정에는 [Google Cloud Storage 버킷 앞에 Google CDN을 구성](../advanced/external-object-storage/_index.md#google-cloud-cdn)하기 위한 추가 키 `cdn`이(가) 있습니다.

### 수신 이메일 설정 {#incoming-email-settings}

수신 이메일 설정은 [명령줄 옵션 페이지](../installation/command-line-options.md#incoming-email-configuration)에 설명되어 있습니다.

### KAS 설정 {#kas-settings}

#### 사용자 지정 시크릿 {#custom-secret}

선택적으로 KAS `secret` 이름과 `key`을(를) Helm의 `--set variable` 옵션을 사용하여 사용자 지정할 수 있습니다:

```shell
--set global.appConfig.gitlab_kas.secret=custom-secret-name \
--set global.appConfig.gitlab_kas.key=custom-secret-key \
```

또는 `values.yaml`을(를) 구성하여:

```yaml
global:
  appConfig:
    gitlab_kas:
      secret: "custom-secret-name"
      key: "custom-secret-key"
```

시크릿 값을 사용자 지정하려면 [시크릿 설명서](../installation/secrets.md#gitlab-kas-secret)를 참조하세요.

#### 사용자 지정 URL {#custom-urls}

KAS에서 사용하는 URL은 Helm의 `--set variable` 옵션을 사용하여 사용자 지정할 수 있습니다:

```shell
--set global.appConfig.gitlab_kas.externalUrl="wss://custom-kas-url.example.com" \
--set global.appConfig.gitlab_kas.internalUrl="grpc://custom-internal-url" \
--set global.appConfig.gitlab_kas.clientTimeoutSeconds=10 # Optional, default is 5 seconds
```

또는 `values.yaml`을(를) 구성하여:

```yaml
global:
  appConfig:
    gitlab_kas:
      externalUrl: "wss://custom-kas-url.example.com"
      internalUrl: "grpc://custom-internal-url"
      clientTimeoutSeconds: 10 # Optional, default is 5 seconds
```

#### 외부 KAS {#external-kas}

GitLab 백엔드는 차트에서 관리하지 않는 외부 KAS 서버를 명시적으로 활성화하고 필요한 URL을 구성하여 인식할 수 있습니다. Helm의 `--set variable` 옵션을 사용하여 다음을 수행할 수 있습니다:

```shell
--set global.appConfig.gitlab_kas.enabled=true \
--set global.appConfig.gitlab_kas.externalUrl="wss://custom-kas-url.example.com" \
--set global.appConfig.gitlab_kas.internalUrl="grpc://custom-internal-url" \
--set global.appConfig.gitlab_kas.clientTimeoutSeconds=10 # Optional, default is 5 seconds
```

또는 `values.yaml`을(를) 구성하여:

```yaml
global:
  appConfig:
    gitlab_kas:
      enabled: true
      externalUrl: "wss://custom-kas-url.example.com"
      internalUrl: "grpc://custom-internal-url"
      clientTimeoutSeconds: 10 # Optional, default is 5 seconds
```

#### TLS 설정 {#tls-settings-1}

KAS는 `kas` 포드와 다른 GitLab 차트 컴포넌트 간의 TLS 통신을 지원합니다.

전제 조건:

- [GitLab 15.5.1 이상](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101571#note_1146419137)을 사용하세요. `global.gitlabVersion: <version>`를 사용하여 GitLab 버전을 설정할 수 있습니다. 초기 배포 후 이미지 업데이트를 강제로 수행해야 하는 경우 `global.image.pullPolicy: Always`을(를) 설정하세요.
- [인증서 기관](../advanced/internal-tls/_index.md)을(를) 생성하고 `kas` 포드가 신뢰할 인증서를 생성합니다.

`kas`를 구성하여 생성한 인증서를 사용하려면 다음 값을 설정하세요.

| 값                         | 설명 |
|-------------------------------|-------------|
| `global.kas.tls.enabled`      | 인증서 볼륨을 마운트하고 `kas` 엔드포인트에 대한 TLS 통신을 활성화합니다. |
| `global.kas.tls.secretName`   | 인증서를 저장하는 Kubernetes TLS 시크릿을 지정합니다. |
| `global.kas.tls.verify`       | `true`인 경우 NGINX Ingress에 KAS의 백엔드 TLS 인증서 검증을 지시합니다. 자체 서명된 인증서의 경우 `false`로 설정해야 합니다. [Gateway API](../advanced/gateway-api/_index.md#tls-between-gateway-and-backend-services)를 사용하는 경우 Gateway API 컨트롤러는 항상 인증서를 검증합니다. |
| `global.kas.tls.caSecretName` | 사용자 지정 CA를 저장하는 Kubernetes TLS 시크릿을 지정합니다. |

예를 들어 차트를 배포하기 위해 `values.yaml` 파일에서 다음을 사용할 수 있습니다:

```yaml
.internal-ca: &internal-ca gitlab-internal-tls-ca # The secret name you used to share your TLS CA.
.internal-tls: &internal-tls gitlab-internal-tls # The secret name you used to share your TLS certificate.

global:
  certificates:
    customCAs:
    - secret: *internal-ca
  hosts:
    domain: gitlab.example.com # Your gitlab domain
  kas:
    tls:
      enabled: true
      secretName: *internal-tls
      caSecretName: *internal-ca
```

### Knowledge Graph 설정 {#knowledge-graph-settings}

이러한 설정을 사용하여 [GitLab Knowledge Graph](https://gitlab.com/gitlab-org/orbit/knowledge-graph) 통합을 구성하세요.

```yaml
global:
  appConfig:
    knowledgeGraph:
      enabled: false
      jwtSecret:
        secret:
        key:
      grpcEndpoint:
```

| 이름                | 유형    | 기본값 | 설명 |
|:--------------------|:-------:|:--------|:------------|
| `enabled`           | 부울 | `false` | Knowledge Graph 통합을 활성화 또는 비활성화합니다. |
| `jwtSecret.secret`  | 문자열  |         | 공유 JWT 키를 포함하는 Kubernetes 시크릿의 이름입니다. |
| `jwtSecret.key`     | 문자열  |         | JWT 공유 키 값을 보유하는 시크릿 내의 키입니다. |
| `grpcEndpoint`      | 문자열  |         | Knowledge Graph 서비스의 gRPC 엔드포인트입니다(예: `gkg.example.com:50054`). |

### LDAP {#ldap}

`ldap.servers` 설정은 [LDAP](https://docs.gitlab.com/administration/auth/ldap/) 사용자 인증의 구성을 허용합니다. 소스에서 설치할 때처럼 `gitlab.yml`의 적절한 LDAP 서버 구성으로 변환될 맵으로 제시됩니다.

암호 구성은 암호를 보유하는 `secret`을(를) 제공하여 수행할 수 있습니다. 이 암호는 런타임에 GitLab 구성에 주입됩니다.

예제 구성 스니펫:

```yaml
ldap:
  preventSignin: false
  servers:
    # 'main' is the GitLab 'provider ID' of this LDAP server
    main:
      label: 'LDAP'
      host: '_your_ldap_server'
      port: 636
      uid: 'sAMAccountName'
      bind_dn: 'cn=administrator,cn=Users,dc=domain,dc=net'
      base: 'dc=domain,dc=net'
      password:
        secret: my-ldap-password-secret
        key: the-key-containing-the-password
```

전역 차트를 사용할 때 예제 `--set` 구성 항목:

```shell
--set global.appConfig.ldap.servers.main.label='LDAP' \
--set global.appConfig.ldap.servers.main.host='your_ldap_server' \
--set global.appConfig.ldap.servers.main.port='636' \
--set global.appConfig.ldap.servers.main.uid='sAMAccountName' \
--set global.appConfig.ldap.servers.main.bind_dn='cn=administrator\,cn=Users\,dc=domain\,dc=net' \
--set global.appConfig.ldap.servers.main.base='dc=domain\,dc=net' \
--set global.appConfig.ldap.servers.main.password.secret='my-ldap-password-secret' \
--set global.appConfig.ldap.servers.main.password.key='the-key-containing-the-password'
```

> [!note]
> 쉼표는 Helm `--set` 항목 내에서 [특수 문자](https://helm.sh/docs/intro/using_helm/#the-format-and-limitations-of---set)로 간주됩니다. `bind_dn`와 같은 값의 쉼표를 이스케이프합니다: `--set global.appConfig.ldap.servers.main.bind_dn='cn=administrator\,cn=Users\,dc=domain\,dc=net'`.

#### LDAP 웹 로그인 비활성화 {#disable-ldap-web-sign-in}

SAML과 같은 대안이 선호될 때 웹 UI를 통해 LDAP 자격 증명을 사용하는 것을 방지하는 것이 유용할 수 있습니다. 이를 통해 LDAP을 그룹 동기화에 사용할 수 있으면서도 SAML 정체성 공급자가 사용자 지정 2FA와 같은 추가 검사를 처리할 수 있습니다.

LDAP 웹 로그인을 비활성화하면 사용자가 로그인 페이지에서 LDAP 탭을 볼 수 없습니다. 이는 [Git 액세스에 LDAP 자격 증명 사용](https://docs.gitlab.com/administration/settings/sign_in_restrictions/#allow-password-authentication-for-git-over-https)을 비활성화하지 않습니다.

LDAP 웹 로그인 사용을 비활성화하려면 `global.appConfig.ldap.preventSignin: true`을(를) 설정하세요.

#### 사용자 지정 CA 또는 자체 서명된 LDAP 인증서 사용 {#using-a-custom-ca-or-self-signed-ldap-certificates}

LDAP 서버가 사용자 지정 CA 또는 자체 서명된 인증서를 사용하는 경우 다음을 수행해야 합니다:

1. 사용자 지정 CA/자체 서명된 인증서가 클러스터/네임스페이스에 시크릿 또는 ConfigMap으로 생성되었는지 확인합니다:

   ```shell
   # Secret
   kubectl -n gitlab create secret generic my-custom-ca-secret --from-file=unique_name.crt=my-custom-ca.pem

   # ConfigMap
   kubectl -n gitlab create configmap my-custom-ca-configmap --from-file=unique_name.crt=my-custom-ca.pem
   ```

1. 그런 다음 다음을 지정합니다:

   ```shell
   # Configure a custom CA from a Secret
   --set global.certificates.customCAs[0].secret=my-custom-ca-secret

   # Or from a ConfigMap
   --set global.certificates.customCAs[0].configMap=my-custom-ca-configmap

   # Configure the LDAP integration to trust the custom CA
   --set global.appConfig.ldap.servers.main.ca_file=/etc/ssl/certs/unique_name.pem
   ```

이렇게 하면 CA 인증서가 `/etc/ssl/certs/unique_name.pem`의 관련 포드에 마운트되고 LDAP 구성에서 사용이 지정됩니다.

[사용자 지정 인증 기관](#custom-certificate-authorities)을 참조하여 자세한 내용을 확인하세요.

### `duoAuth` {#duoauth}

이러한 설정을 사용하여 [Cisco Duo를 사용한 이중 인증(2FA)](https://docs.gitlab.com/user/profile/account/two_factor_authentication/#enable-two-factor-authentication)을 활성화하세요.

```yaml
global:
  appConfig:
    duoAuth:
      enabled:
      hostname:
      integrationKey:
      secretKey:
      #  secret:
      #  key:
```

| 이름             |  유형   | 기본값 | 설명 |
|:-----------------|:-------:|:--------|:------------|
| `enabled`        | 부울 | `false` | Cisco Duo와의 통합을 활성화 또는 비활성화 |
| `hostname`       | 문자열  |         | Cisco Duo API 호스트명 |
| `integrationKey` | 문자열  |         | Cisco Duo API 통합 키 |
| `secretKey`      |         |         | Cisco Duo API 시크릿 키로 [시크릿 이름 및 키 이름으로 구성](#configure-the-cisco-duo-secret-key)해야 합니다 |

### Cisco Duo 시크릿 키 구성 {#configure-the-cisco-duo-secret-key}

GitLab Helm 차트에서 Cisco Duo 인증 통합을 구성하려면 Cisco Duo 인증 secret_key 값을 포함하는 `global.appConfig.duoAuth.secretKey.secret` 설정에 시크릿을 제공해야 합니다.

Cisco Duo 계정 `secretKey`을(를) 저장하기 위해 Kubernetes 시크릿 개체를 만들려면 명령줄에서 다음을 실행하세요:

```shell
kubectl create secret generic <secret_object_name> --from-literal=secretKey=<duo_secret_key_value>
```

### OmniAuth {#omniauth}

GitLab은 OmniAuth를 활용하여 사용자가 GitHub, Google 및 기타 인기 있는 서비스를 사용하여 로그인할 수 있도록 합니다. 확장된 설명서는 GitLab의 [OmniAuth 설명서](https://docs.gitlab.com/integration/omniauth/#configure-common-settings)에서 찾을 수 있습니다.

```yaml
omniauth:
  enabled: false
  autoSignInWithProvider:
  syncProfileFromProvider: []
  syncProfileAttributes: ['email']
  allowSingleSignOn: ['saml']
  blockAutoCreatedUsers: true
  autoLinkLdapUser: false
  autoLinkSamlUser: false
  autoLinkUser: ['openid_connect']
  externalProviders: []
  allowBypassTwoFactor: []
  providers: []
  # - secret: gitlab-google-oauth2
  #   key: provider
  # - name: group_saml
```

| 이름                      | 유형             | 기본값 |
|:--------------------------|:-----------------|:--------|
| `allowBypassTwoFactor`    | 부울 또는 배열 | `false` |
| `allowSingleSignOn`       | 부울 또는 배열 | `['saml']` |
| `autoLinkLdapUser`        | 부울          | `false` |
| `autoLinkSamlUser`        | 부울          | `false` |
| `autoLinkUser`            | 부울 또는 배열 | `false` |
| `autoSignInWithProvider`  |                  | `nil`   |
| `blockAutoCreatedUsers`   | 부울          | `true`  |
| `enabled`                 | 부울          | `false` |
| `externalProviders`       |                  | `[]`    |
| `providers`               |                  | `[]`    |
| `syncProfileAttributes`   |                  | `['email']` |
| `syncProfileFromProvider` |                  | `[]`    |

#### `providers` {#providers}

`providers`는 소스에서 설치할 때처럼 `gitlab.yml`를 채우는 데 사용되는 맵의 배열로 제시됩니다. GitLab 설명서에서 [지원되는 공급자](https://docs.gitlab.com/integration/omniauth/#supported-providers)의 사용 가능한 선택을 참조하세요. `[]`로 기본값이 지정됩니다.

이 속성에는 두 개의 하위 키가 있습니다: `secret` 및 `key`:

- `secret`: *(필수)* 공급자 블록을 포함하는 Kubernetes `Secret`의 이름입니다.
- `key`: *(선택)* 공급자 블록을 포함하는 `Secret`의 키 이름입니다. 기본값은 `provider`

또는 공급자의 이름 이외의 다른 구성이 없는 경우 `name` 속성만 포함하는 두 번째 양식을 사용할 수 있으며, 선택적으로 `label` 또는 `icon` 속성을 사용할 수 있습니다. 적격 공급자는 다음과 같습니다:

- [`group_saml`](https://docs.gitlab.com/integration/saml/#configure-group-saml-sso-on-gitlab-self-managed)
- [`kerberos`](https://docs.gitlab.com/integration/saml/#configure-group-saml-sso-on-gitlab-self-managed)

이러한 항목의 `Secret`는 [OmniAuth 공급자](https://docs.gitlab.com/integration/omniauth/)에 설명된 YAML 또는 JSON 형식 블록을 포함합니다. 이 시크릿을 만들려면 이러한 항목의 검색에 대한 적절한 지시를 따르고 YAML 또는 JSON 파일을 만드세요.

Google OAuth 2.0 구성의 예:

```yaml
name: google_oauth2
label: Google
app_id: 'APP ID'
app_secret: 'APP SECRET'
args:
  access_type: offline
  approval_prompt: ''
```

SAML 구성 예:

```yaml
name: saml
label: 'SAML'
args:
  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
  idp_cert_fingerprint: 'xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx'
  idp_sso_target_url: 'https://SAML_IDP/app/xxxxxxxxx/xxxxxxxxx/sso/saml'
  issuer: 'https://gitlab.example.com'
  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
```

Microsoft Azure OAuth 2.0 OmniAuth 공급자 구성 예:

```yaml
name: azure_activedirectory_v2
label: Azure
args:
  client_id: '<CLIENT_ID>'
  client_secret: '<CLIENT_SECRET>'
  tenant_id: '<TENANT_ID>'
```

이 내용을 `provider.yaml`로 저장한 다음 시크릿을 만들 수 있습니다:

```shell
kubectl create secret generic -n NAMESPACE SECRET_NAME --from-file=provider=provider.yaml
```

만들어진 후 `providers`는 아래와 같이 구성에 맵을 제공하여 활성화됩니다:

```yaml
omniauth:
  providers:
    - secret: gitlab-google-oauth2
    - secret: azure_activedirectory_v2
    - secret: gitlab-azure-oauth2
    - secret: gitlab-cas3
```

[그룹 SAML](https://docs.gitlab.com/integration/saml/#configuring-group-saml-on-a-self-managed-gitlab-instance) 구성 예:

```yaml
omniauth:
  providers:
    - name: group_saml
```

전역 차트를 사용할 때 예제 구성 `--set` 항목:

```shell
--set global.appConfig.omniauth.providers[0].secret=gitlab-google-oauth2 \
```

`--set` 인수를 사용하는 복잡성으로 인해 사용자가 `helm`에 전달되는 YAML 스니펫을 사용하고 싶을 수 있습니다 `-f omniauth.yaml`.

### Cron 작업 관련 설정 {#cron-jobs-related-settings}

Sidekiq에는 cron 스타일 일정을 사용하여 정기적으로 실행되도록 구성할 수 있는 유지 관리 작업이 포함되어 있습니다. 몇 가지 예가 아래에 포함되어 있습니다. 샘플 [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/config/gitlab.yml.example)의 `cron_jobs` 및 `ee_cron_jobs` 섹션을 참조하여 더 많은 작업 예를 확인하세요.

이러한 설정은 Sidekiq, Webservice(UI에서 도구 설명 표시) 및 Toolbox(디버깅 목적) 포드 간에 공유됩니다.

```yaml
global:
  appConfig:
    cron_jobs:
      stuck_ci_jobs_worker:
        cron: "0 * * * *"
      pipeline_schedule_worker:
        cron: "3-59/10 * * * *"
      expire_build_artifacts_worker:
        cron: "*/7 * * * *"
```

### Sentry 설정 {#sentry-settings}

이러한 설정을 사용하여 [GitLab 오류 보고 Sentry](https://docs.gitlab.com/omnibus/settings/configuration/#error-reporting-and-logging-with-sentry)을 활성화하세요.

```yaml
global:
  appConfig:
    sentry:
      enabled:
      dsn:
      clientside_dsn:
      environment:
```

| 이름             |  유형   | 기본값 | 설명 |
|:-----------------|:-------:|:--------|:------------|
| `enabled`        | 부울 | `false` | 통합을 활성화 또는 비활성화 |
| `dsn`            | 문자열  |         | 백엔드 오류의 Sentry DSN |
| `clientside_dsn` | 문자열  |         | 프론트엔드 오류의 Sentry DSN |
| `environment`    | 문자열  |         | [Sentry 환경](https://docs.sentry.io/concepts/key-terms/environments/)을 참조하세요 |

### `gitlab_docs` 설정 {#gitlab_docs-settings}

`gitlab_docs`을(를) 활성화하기 위해 이러한 설정을 사용하세요.

```yaml
global:
  appConfig:
    gitlab_docs:
      enabled:
      host:
```

| 이름      |  유형   | 기본값 | 설명 |
|:----------|:-------:|:--------|:------------|
| `enabled` | 부울 | `false` | `gitlab_docs`을(를) 활성화 또는 비활성화 |
| `host`    | 문자열  | `""`    | docs 호스트   |

### OpenID Connect 토큰 만료 {#openid-connect-token-expiration}

OpenID Connect(OIDC) 공급자 토큰 만료를 구성합니다.

```yaml
global:
  appConfig:
    oidcProvider:
      openidIdTokenExpireInSeconds: 120
```

| 이름                           | 유형    | 기본값 | 설명 |
|--------------------------------|---------|---------|-------------|
| `openidIdTokenExpireInSeconds` | 정수 | 120     | ID 토큰이 만료되기 전의 기간(초 단위)입니다. |

### 스마트카드 인증 설정 {#smartcard-authentication-settings}

```yaml
global:
  appConfig:
    smartcard:
      enabled: false
      CASecret:
      clientCertificateRequiredHost:
      sanExtensions: false
      requiredForGitAccess: false
```

| 이름                            |  유형   | 기본값 | 설명 |
|:--------------------------------|:-------:|:--------|:------------|
| `enabled`                       | 부울 | `false` | 스마트카드 인증을 활성화 또는 비활성화 |
| `CASecret`                      | 문자열  |         | CA 인증서를 포함하는 시크릿의 이름 |
| `clientCertificateRequiredHost` | 문자열  |         | 스마트카드 인증에 사용할 호스트명입니다. 기본적으로 제공되거나 계산된 스마트카드 호스트명이 사용됩니다. |
| `sanExtensions`                 | 부울 | `false` | SAN 확장의 사용을 활성화하여 사용자를 인증서와 일치시킵니다. |
| `requiredForGitAccess`          | 부울 | `false` | Git 액세스를 위해 스마트카드 로그인을 포함한 브라우저 세션이 필요합니다. |

스마트카드 인증은 [번들된 Envoy Gateway](envoygateway/_index.md)로 즉시 작동하며 추가 설정이 필요하지 않습니다. 대신 [번들된 NGINX Ingress](nginx/_index.md)를 사용하려면 코드 조각 주석을 활성화해야 합니다.

코드 조각 주석을 활성화하면 사용자 지정 NGINX 구성을 주석을 통해 주입할 수 있으며, 이는 특정 환경에서 보안 위험을 초래할 수 있습니다. 주석을 활성화하기 전에 [업스트림 설명서](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#allow-snippet-annotations)를 검토하세요.

```yaml
nginx-ingress:
  enabled: true
  controller:
    config:
      allow-snippet-annotations: "true"
      annotations-risk-level: "Critical"
```

### Sidekiq 라우팅 규칙 설정 {#sidekiq-routing-rules-settings}

GitLab은 작업자의 작업을 예약하기 전에 원하는 큐로 라우팅하는 것을 지원합니다. Sidekiq 클라이언트는 작업을 구성된 라우팅 규칙 목록과 비교합니다. 규칙은 첫 번째부터 마지막으로 평가되며, 주어진 작업자에 대한 일치가 발견되는 즉시 해당 작업자의 처리가 중지됩니다(첫 번째 일치 승리). 작업자가 규칙과 일치하지 않으면 작업자 이름에서 생성된 큐 이름으로 돌아갑니다.

기본적으로 라우팅 규칙은 구성되지 않거나(빈 배열로 표시됨) 모든 작업은 작업자 이름에서 생성된 큐로 라우팅됩니다.

라우팅 규칙 목록은 쿼리 및 해당 큐의 정렬된 튜플 배열입니다:

- 쿼리는 [작업자 일치 쿼리](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#worker-matching-query) 구문을 따릅니다.
- `<queue_name>`는 [`sidekiq.pods`](gitlab/sidekiq/_index.md#per-pod-settings) 아래에 정의된 유효한 Sidekiq 큐 이름 `sidekiq.pods[].queues`과(와) 일치해야 합니다. 큐 이름이 `nil` 또는 빈 문자열인 경우 작업자는 작업자 이름으로 생성된 큐로 라우팅됩니다. [Sidekiq 구성의 전체 예](gitlab/sidekiq/_index.md#full-example-of-sidekiq-configuration)를 참조로 확인하세요.

쿼리는 모든 작업자와 일치하는 와일드카드 일치 `*`를 지원합니다. 결과적으로 와일드카드 쿼리는 목록 끝에 있어야 하거나 이후 규칙이 무시됩니다:

```yaml
global:
  appConfig:
    sidekiq:
      routingRules:
      - ["resource_boundary=cpu", "cpu-boundary"]
      - ["feature_category=pages", null]
      - ["feature_category=search", "search"]
      - ["feature_category=memory|resource_boundary=memory", "memory-bound"]
      - ["*", "default"]
```

## Rails 설정 구성 {#configure-rails-settings}

GitLab 제품군의 대부분은 Rails를 기반으로 합니다. 따라서 이 프로젝트의 많은 컨테이너는 이 스택으로 작동합니다. 이러한 설정은 모든 컨테이너에 적용되며 전역 대 개별적으로 설정하는 간편한 액세스 방법을 제공합니다.

```yaml
global:
  rails:
    bootsnap:
      enabled: true
```

## Workhorse 설정 구성 {#configure-workhorse-settings}

GitLab 제품군의 여러 컴포넌트는 GitLab Workhorse를 통해 API와 통신합니다. 이는 현재 Webservice 차트의 일부입니다. 이러한 설정은 GitLab Workhorse와 접촉해야 하는 모든 차트에서 사용되며 전역으로 개별적으로 설정하는 간편한 액세스를 제공합니다.

```yaml
global:
  workhorse:
    serviceName: webservice-default
    host: api.example.com
    port: 8181
```

| 이름          | 유형    | 기본값              | 설명 |
|:--------------|:--------|:---------------------|:------------|
| `serviceName` | 문자열  | `webservice-default` | 내부 API 트래픽을 지시할 서비스의 이름입니다. 릴리스 이름을 포함하지 마세요. 템플릿으로 만들어집니다. `gitlab.webservice.deployments`의 항목과 일치해야 합니다. [`gitlab/webservice` 차트](gitlab/webservice/_index.md#deployments-settings)를 참조하세요 |
| `scheme`      | 문자열  | `http`               | API 엔드포인트의 구성표 |
| `host`        | 문자열  |                      | API 엔드포인트의 정규화된 호스트명 또는 IP 주소입니다. `serviceName`의 존재를 무시합니다. |
| `port`        | 정수 | `8181`               | 관련 API 서버의 포트 번호입니다. |
| `tls.enabled` | 부울 | `false`              | `true`로 설정되면 Workhorse에 대한 TLS 지원을 활성화합니다. |

### Bootsnap 캐시 {#bootsnap-cache}

우리의 Rails 코드베이스는 [Shopify Bootsnap](https://github.com/Shopify/bootsnap) Gem을 사용합니다. 여기의 설정은 해당 동작을 구성하는 데 사용됩니다.

`bootsnap.enabled`는 이 기능의 활성화를 제어합니다. 기본값은 `true`입니다.

테스트에 따르면 Bootsnap을 활성화하면 전체 애플리케이션 성능이 향상되었습니다. 사전 컴파일된 캐시를 사용할 수 있을 때 일부 애플리케이션 컨테이너는 33% 이상의 이득을 봅니다. 현재 GitLab은 컨테이너와 함께 이 사전 컴파일된 캐시를 제공하지 않아 "겨우" 14%의 이득을 초래합니다. 사전 컴파일된 캐시 없이 이러한 이득에는 비용이 있으며, 각 Pod의 초기 시작 시 작은 IO의 집중적인 급증이 발생합니다. 이로 인해 문제가 될 수 있는 환경에서 Bootsnap 사용을 비활성화하는 방법을 노출했습니다.

가능하면 이를 활성화된 상태로 두는 것이 좋습니다.

## GitLab Shell 구성 {#configure-gitlab-shell}

[GitLab Shell](gitlab/gitlab-shell/_index.md) 차트의 전역 구성을 위한 여러 항목이 있습니다.

```yaml
global:
  shell:
    port:
    authToken: {}
    hostKeys: {}
    tcp:
      proxyProtocol: false
```

| 이름                |  유형   | 기본값 | 설명 |
|:--------------------|:-------:|:--------|:------------|
| `port`              | 정수 | `22`    | 구체적인 설명서는 아래의 [`port`](#port)를 참조하세요. |
| `authToken`         |         |         | GitLab Shell 차트 관련 문서의 [`authToken`](gitlab/gitlab-shell/_index.md#authtoken)를 참조하세요. |
| `hostKeys`          |         |         | GitLab Shell 차트 관련 문서의 [`hostKeys`](gitlab/gitlab-shell/_index.md#hostkeyssecret)를 참조하세요. |
| `tcp.proxyProtocol` | 부울 | `false` | 구체적인 설명서는 아래의 [TCP 프록시 프로토콜](#tcp-proxy-protocol)을 참조하세요. |

### 포트 {#port}

Ingress에서 SSH 트래픽을 전달하는 데 사용되는 포트와 `global.shell.port`를 통해 GitLab에서 제공하는 SSH URL에 사용되는 포트를 제어할 수 있습니다. 이는 서비스가 수신하는 포트와 프로젝트 UI에서 제공되는 SSH 복제 URL에 반영됩니다.

```yaml
global:
  shell:
    port: 32022
```

`global.shell.port`과(와) `nginx-ingress.controller.service.type=NodePort`를 결합하여 NGINX 컨트롤러 서비스 개체에 대한 NodePort를 설정할 수 있습니다. `nginx-ingress.controller.service.nodePorts.gitlab-shell`이(가) 설정된 경우 NGINX의 NodePort를 설정할 때 `global.shell.port`을(를) 재정의합니다.

```yaml
global:
  shell:
    port: 32022

nginx-ingress:
  controller:
    service:
      type: NodePort
```

### TCP 프록시 프로토콜 {#tcp-proxy-protocol}

SSH Ingress에서 [프록시 프로토콜](https://www.haproxy.com/blog/use-the-proxy-protocol-to-preserve-a-clients-ip-address) 처리를 활성화하여 프록시 프로토콜 헤더를 추가하는 업스트림 프록시에서의 연결을 올바르게 처리할 수 있습니다. 이렇게 하면 SSH가 추가 헤더를 수신하는 것을 방지하고 SSH를 중단하지 않습니다.

프록시 프로토콜 처리를 활성화해야 하는 일반적인 환경은 AWS를 사용하고 ELB가 클러스터에 대한 인바운드 연결을 처리하는 경우입니다. [AWS 계층 4 로드 밸런서 예](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/elb-layer4-loadbalancer.yaml)를 참고하여 올바르게 설정할 수 있습니다.

```yaml
global:
  shell:
    tcp:
      proxyProtocol: true # default false
```

## GitLab Pages 구성 {#configure-gitlab-pages}

다른 차트에서 사용되는 전역 GitLab Pages 설정은 `global.pages` 키 아래에 문서화되어 있습니다.

```yaml
global:
  pages:
    enabled:
    accessControl:
    path:
    host:
    port:
    https:
    externalHttp:
    externalHttps:
    customDomainMode:
    artifactsServer:
    objectStore:
      enabled:
      bucket:
      proxy_download: true
      connection: {}
        secret:
        key:
    localStore:
      enabled: false
      path:
    apiSecret: {}
      secret:
      key:
    namespaceInPath: false
```

| 이름                            |  유형   | 기본값                    | 설명 |
|:--------------------------------|:-------:|:---------------------------|:------------|
| `enabled`                       | 부울 | `false`                    | 클러스터에 GitLab Pages 차트를 설치할지 여부를 결정합니다 |
| `accessControl`                 | 부울 | `false`                    | GitLab Pages 액세스 제어를 활성화합니다 |
| `path`                          | 문자열  | `/srv/gitlab/shared/pages` | Pages 배포 관련 파일을 저장할 경로입니다. 참고:  기본적으로 사용되지 않습니다. 개체 저장소가 사용되기 때문입니다. |
| `host`                          | 문자열  |                            | Pages 루트 도메인입니다. |
| `port`                          | 문자열  |                            | UI에서 Pages URL을 구성하는 데 사용할 포트입니다. 설정하지 않으면 Pages의 HTTPS 상황에 따라 기본값 80 또는 443이 설정됩니다. |
| `https`                         | 부울 | `true`                     | GitLab UI가 Pages에 대한 HTTPS URL을 표시할지 여부입니다. `global.hosts.pages.https` 및 `global.hosts.https`보다 우선순위가 높습니다. |
| `externalHttp`                  |  목록   | `[]`                       | HTTP 요청이 Pages 데몬에 도달하는 IP 주소 목록입니다. [사용자 정의 도메인](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/) 지원을 위해서입니다. |
| `externalHttps`                 |  목록   | `[]`                       | HTTPS 요청이 Pages 데몬에 도달하는 IP 주소 목록입니다. [사용자 정의 도메인](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/) 지원을 위해서입니다. |
| `customDomainMode`              | 문자열  |                            | [사용자 정의 도메인](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/)을 활성화하도록 구성합니다: `http` 또는 `https`. |
| `artifactsServer`               | 부울 | `true`                     | GitLab Pages에서 아티팩트 보기를 활성화합니다. |
| `objectStore.enabled`           | 부울 | `true`                     | Pages용 객체 저장소 사용을 활성화합니다. |
| `objectStore.bucket`            | 문자열  | `gitlab-pages`             | Pages와 관련된 콘텐츠를 저장하는 데 사용할 버킷입니다. |
| `objectStore.connection.secret` | 문자열  |                            | 객체 저장소의 연결 세부 정보를 포함하는 시크릿입니다. |
| `objectStore.connection.key`    | 문자열  |                            | 연결 세부 정보가 저장되는 연결 시크릿 내의 키입니다. |
| `localStore.enabled`            | 부울 | `false`                    | Pages와 관련된 콘텐츠에 로컬 저장소 사용을 활성화합니다(`objectStore` 대신). |
| `localStore.path`               | 문자열  | `/srv/gitlab/shared/pages` | 페이지 파일이 저장될 경로입니다. `localStore`이(가) true로 설정된 경우에만 사용됩니다. |
| `apiSecret.secret`              | 문자열  |                            | Base64로 인코딩된 형식의 32비트 API 키를 포함하는 시크릿입니다. |
| `apiSecret.key`                 | 문자열  |                            | API 키가 저장되는 API 키 시크릿 내의 키입니다. |
| `namespaceInPath`               | 부울 | `false`                    | (베타) URL 경로의 네임스페이스를 활성화 또는 비활성화하여 와일드카드 DNS 설정 없이 지원합니다. 자세한 내용은 [와일드카드 DNS 없이 Pages 도메인 설정 설명서](gitlab/gitlab-pages/_index.md#pages-domain-without-wildcard-dns)를 참조하세요. |

## Webservice 구성 {#configure-webservice}

전역 Webservice 설정(다른 차트에서도 사용됨)은 `global.webservice` 키 아래에 있습니다.

```yaml
global:
  webservice:
    workerTimeout: 60
```

### `workerTimeout` {#workertimeout}

Webservice 마스터 프로세스에 의해 Webservice 워커 프로세스가 종료되는 타임아웃(초)을 구성합니다. 기본값은 60초입니다.

`global.webservice.workerTimeout` 설정은 최대 요청 지속 시간에 영향을 주지 않습니다. 최대 요청 지속 시간을 설정하려면 다음 환경 변수를 설정하세요:

```yaml
gitlab:
  webservice:
    workerTimeout: 60
    extraEnv:
      GITLAB_RAILS_RACK_TIMEOUT: "60"
      GITLAB_RAILS_WAIT_TIMEOUT: "90"
```

## 사용자 정의 인증서 기관 {#custom-certificate-authorities}

> [!note]
> 이러한 설정은 번들된 타사 차트에 영향을 주지 않습니다.

일부 사용자는 TLS 서비스용 내부 발급 SSL 인증서를 사용할 때와 같은 사용자 정의 인증서 기관을 추가해야 할 수 있습니다. 이 기능을 제공하기 위해 시크릿 또는 ConfigMap을 통해 이러한 사용자 정의 루트 인증서 기관을 애플리케이션에 주입하는 메커니즘을 제공합니다.

시크릿 또는 ConfigMap을 만들려면:

```shell
# Create a Secret from a certificate file
kubectl create secret generic secret-custom-ca --from-file=unique_name.crt=/path/to/cert

# Create a ConfigMap from a certificate file
kubectl create configmap cm-custom-ca --from-file=unique_name.crt=/path/to/cert
```

시크릿 또는 ConfigMap을 구성하거나 둘 다 구성하려면 전역 설정에서 지정하세요:

```yaml
global:
  certificates:
    customCAs:
      - secret: secret-custom-CAs           # Mount all keys of a Secret
      - secret: secret-custom-CAs           # Mount only the specified keys of a Secret
        keys:
          - unique_name.crt
      - configMap: cm-custom-CAs            # Mount all keys of a ConfigMap
      - configMap: cm-custom-CAs            # Mount only the specified keys of a ConfigMap
        keys:
          - unique_name_1.crt
          - unique_name_2.crt
```

> [!note]
> 시크릿의 키 이름에 있는 `.crt` 확장자는 [Debian update-ca-certificates 패키지](https://manpages.debian.org/bullseye/ca-certificates/update-ca-certificates.8.en.html)에 중요합니다. 이 단계는 사용자 정의 CA 파일이 해당 확장자로 마운트되고 인증서 `initContainers`에서 처리되도록 합니다. 이전에 인증서 도우미 이미지가 Alpine 기반이었을 때는 [설명서](https://gitlab.alpinelinux.org/alpine/ca-certificates/-/blob/master/update-ca-certificates.8)에서 필요하다고 명시했지만 파일 확장자가 실제로 필요하지 않았습니다. UBI 기반 `update-ca-trust` 유틸리티는 동일한 요구 사항이 없는 것으로 보입니다.

PEM으로 인코딩된 CA 인증서를 보유한 모든 키가 포함된 시크릿 또는 ConfigMap을 원하는 개수만큼 제공할 수 있습니다. 이러한 항목은 `global.certificates.customCAs` 아래에 항목으로 구성됩니다. `keys:`가 마운트할 특정 키 목록과 함께 제공되지 않는 한 모든 키가 마운트됩니다. 모든 시크릿 및 ConfigMap에 걸쳐 마운트된 모든 키는 고유해야 합니다. 시크릿 및 ConfigMap의 이름은 자유롭게 지정할 수 있지만 *충돌하는 키 이름을 포함하면 안 됩니다*.

## 애플리케이션 리소스 {#application-resource}

GitLab은 선택적으로 클러스터 내에서 GitLab 애플리케이션을 식별하기 위해 생성할 수 있는 [애플리케이션 리소스](https://github.com/kubernetes-sigs/application)를 포함할 수 있습니다. [애플리케이션 CRD](https://github.com/kubernetes-sigs/application#installing-the-crd) 버전 `v1beta1`이(가) 이미 클러스터에 배포되어 있어야 합니다.

활성화하려면 `global.application.create`을(를) `true`로 설정하세요:

```yaml
global:
  application:
    create: true
```

Google GKE Marketplace와 같은 일부 환경에서는 ClusterRole 리소스 생성을 허용하지 않습니다. 다음 값을 설정하여 애플리케이션 사용자 정의 리소스 정의 및 Cloud Native GitLab과 함께 패키지된 관련 차트의 ClusterRole 구성 요소를 비활성화합니다.

```yaml
global:
  application:
    allowClusterRoles: false
nginx:
  controller:
    scope:
      enabled: true
gitlab-runner:
  rbac:
    clusterWideAccess: false
installCertmanager: false
```

## GitLab 기본 이미지 {#gitlab-base-image}

GitLab Helm 차트는 다양한 초기화 작업을 위해 공통 GitLab 기본 이미지를 사용합니다. 이 이미지는 UBI 빌드를 지원하고 다른 이미지와 레이어를 공유합니다.

## 서비스 계정 {#service-accounts}

GitLab Helm 차트를 사용하면 포드가 사용자 정의 [서비스 계정](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)을(를) 사용하여 실행할 수 있습니다. 이는 `global.serviceAccount`의 다음 설정으로 구성됩니다:

```yaml
global:
  serviceAccount:
    enabled: false
    create: true
    annotations: {}
    automountServiceAccountToken: false
    ## Name to be used for serviceAccount, otherwise defaults to chart fullname
    # name:
```

- `global.serviceAccount.enabled` 설정은 `spec.serviceAccountName`을(를) 통해 각 구성 요소에 대한 서비스 계정 참조를 제어합니다.
- `global.serviceAccount.create` 설정은 Helm을 통한 서비스 계정 객체 생성을 제어합니다.
- `global.serviceAccount.name` 설정은 서비스 계정 객체 이름과 각 구성 요소에서 참조하는 이름을 제어합니다.
- `global.serviceAccount.automountServiceAccountToken` 설정은 기본 ServiceAccount 액세스 토큰을 포드에 마운트할지 여부를 제어합니다. 특정 사이드카(예: Istio)가 제대로 작동하는 데 필요한 경우를 제외하고는 이를 활성화하지 않아야 합니다.

> [!note]
> `global.serviceAccount.create=true`를 `global.serviceAccount.name`과(와) 함께 사용하지 마세요. 차트가 동일한 이름의 여러 ServiceAccount 객체를 만들도록 지시하기 때문입니다. 대신 전역 이름을 지정하는 경우 `global.serviceAccount.create=false`를 사용하세요.

## 주석 {#annotations}

배포, 서비스 및 Ingress 객체에 사용자 정의 주석을 적용할 수 있습니다.

```yaml
global:
  deployment:
    annotations:
      environment: production

  service:
    annotations:
      environment: production

  ingress:
    annotations:
      environment: production
```

## 노드 선택기 {#node-selector}

사용자 정의 `nodeSelector`을(를) 모든 구성 요소에 전역적으로 적용할 수 있습니다. 모든 전역 기본값을 각 하위 차트에서 개별적으로 재정의할 수도 있습니다.

```yaml
global:
  nodeSelector:
    disktype: ssd
```

> [!note]
> 외부에서 유지 관리되는 차트는 현재 `global.nodeSelector`을(를) 존중하지 않을 수 있으며 사용 가능한 차트 값에 따라 별도로 구성해야 할 수 있습니다. Prometheus, cert-manager, Redis 등이 포함됩니다.

## 레이블 {#labels}

### 공통 레이블 {#common-labels}

레이블은 `common.labels` 구성을 사용하여 다양한 객체로 생성되는 거의 모든 객체에 적용할 수 있습니다. 이는 `global` 키 아래에 적용하거나 특정 차트 구성 아래에 적용할 수 있습니다. 예:

```yaml
global:
  common:
    labels:
      environment: production
gitlab:
  gitlab-shell:
    common:
      labels:
        foo: bar
```

위의 예제 구성을 사용하면 Helm 차트에서 배포하는 거의 모든 구성 요소에 레이블 집합 `environment: production`이(가) 제공됩니다. GitLab Shell 차트의 모든 구성 요소는 레이블 집합 `foo: bar`을(를) 받습니다. 일부 차트는 추가 중첩을 허용합니다. 예를 들어 Sidekiq 및 Webservice 차트는 구성 요구 사항에 따라 추가 배포를 허용합니다:

```yaml
gitlab:
  sidekiq:
    pods:
      - name: pod-0
        common:
          labels:
            baz: bat
```

위의 예제에서 `pod-0` Sidekiq 배포와 관련된 모든 구성 요소는 또한 레이블 집합 `baz: bat`을(를) 받습니다. 자세한 내용은 Sidekiq 및 Webservice 차트를 참조하세요.

일부 차트는 이 레이블 구성에서 제외됩니다. [GitLab 구성 요소 하위 차트](gitlab/_index.md)만 이러한 추가 레이블을 받습니다.

### `pod` {#pod}

레이블을 다양한 배포 및 작업에 적용할 수 있습니다. 이러한 레이블은 이 Helm 차트에서 구성된 기존 또는 사전 구성된 레이블을 보완합니다. 이러한 보완 레이블은 **not** `matchSelectors`용으로.

```yaml
global:
  pod:
    labels:
      environment: production
```

### `service` {#service}

레이블을 서비스에 적용할 수 있습니다. 이러한 레이블은 이 Helm 차트에서 구성된 기존 또는 사전 구성된 레이블을 보완합니다.

```yaml
global:
  service:
    labels:
      environment: production
```

## 추적 {#tracing}

GitLab Helm 차트는 추적을 지원하며 다음과 같이 구성할 수 있습니다:

```yaml
global:
  tracing:
    connection:
      string: 'opentracing://jaeger?http_endpoint=http%3A%2F%2Fjaeger.example.com%3A14268%2Fapi%2Ftraces&sampler=const&sampler_param=1'
    urlTemplate: 'http://jaeger-ui.example.com/search?service={{ service }}&tags=%7B"correlation_id"%3A"{{ correlation_id }}"%7D'
```

- `global.tracing.connection.string`은(는) 추적 범위를 보낼 위치를 구성하는 데 사용됩니다. [GitLab 추적 설명서](https://docs.gitlab.com/development/distributed_tracing/)에서 자세히 알아볼 수 있습니다.
- `global.tracing.urlTemplate`은(는) GitLab 성능 표시줄에서 추적 정보 URL 렌더링을 위한 템플릿으로 사용됩니다.

## `extraEnv` {#extraenv}

`extraEnv`을(를) 사용하면 GitLab 차트(`charts/gitlab/charts`)를 통해 배포된 포드의 모든 컨테이너에서 추가 환경 변수를 노출할 수 있습니다. 전역 수준에서 설정된 추가 환경 변수는 차트 수준에서 제공된 변수로 병합되며, 차트 수준에서 제공된 변수에 우선순위가 지정됩니다.

`extraEnv`의 사용 예는 다음과 같습니다:

```yaml
global:
  extraEnv:
    SOME_KEY: some_value
    SOME_OTHER_KEY: some_other_value
```

## `extraEnvFrom` {#extraenvfrom}

`extraEnvFrom`을(를) 사용하면 모든 컨테이너의 다른 데이터 원본에서 추가 환경 변수를 노출할 수 있습니다. 추가 환경 변수는 `global` 수준(`global.extraEnvFrom`)에서 설정하고 하위 차트 수준(`<subchart_name>.extraEnvFrom`)에서도 설정할 수 있습니다.

Sidekiq 및 Webservice 차트는 추가 로컬 재정의를 지원합니다. 자세한 내용은 해당 설명서를 참조하세요.

`extraEnvFrom`의 사용 예는 다음과 같습니다:

```yaml
global:
  extraEnvFrom:
    MY_NODE_NAME:
      fieldRef:
        fieldPath: spec.nodeName
    MY_CPU_REQUEST:
      resourceFieldRef:
        containerName: test-container
        resource: requests.cpu
gitlab:
  kas:
    extraEnvFrom:
      CONFIG_STRING:
        configMapKeyRef:
          name: useful-config
          key: some-string
          # optional: boolean
```

> [!note]
> 구현은 다양한 콘텐츠 유형으로 값 이름을 재사용하는 것을 지원하지 않습니다. 동일한 이름을 유사한 콘텐츠로 재정의할 수 있지만 `secretKeyRef`, `configMapKeyRef` 등과 같은 출처를 혼합하면 안 됩니다.

## OAuth 설정 구성 {#configure-oauth-settings}

OAuth 통합은 지원하는 서비스에 대해 즉시 구성됩니다. `global.oauth`에 지정된 서비스는 배포 중에 GitLab에 OAuth 클라이언트 애플리케이션으로 자동 등록됩니다. 기본적으로 이 목록에는 액세스 제어가 활성화된 경우 GitLab Pages가 포함됩니다.

```yaml
global:
  oauth:
    gitlab-pages: {}
    # secret
    # appid
    # appsecret
    # redirectUri
    # authScope
```

| 이름           | 유형   | 기본값 | 설명 |
|:---------------|:-------|:--------|:------------|
| `secret`       | 문자열 |         | 서비스의 OAuth 자격 증명을 포함하는 시크릿의 이름입니다. |
| `appIdKey`     | 문자열 |         | 서비스의 앱 ID가 저장되는 시크릿의 키입니다. 설정되는 기본값은 `appid`입니다. |
| `appSecretKey` | 문자열 |         | 서비스의 앱 시크릿이 저장되는 시크릿의 키입니다. 설정되는 기본값은 `appsecret`입니다. |
| `redirectUri`  | 문자열 |         | 권한 부여에 성공한 후 사용자를 리디렉션할 URI입니다. |
| `authScope`    | 문자열 | `api`   | GitLab API를 사용한 인증에 사용되는 범위입니다. |

시크릿에 대한 자세한 내용은 [시크릿 설명서](../installation/secrets.md#oauth-integration)를 참조하세요.

## Kerberos {#kerberos}

GitLab Helm 차트에서 Kerberos 통합을 구성하려면 `global.appConfig.kerberos.keytab.secret` 설정에 GitLab 호스트의 서비스 주체가 있는 Kerberos [keytab](https://web.mit.edu/kerberos/krb5-devel/doc/basic/keytab_def.html)을 포함하는 시크릿을 제공해야 합니다. Kerberos 관리자는 keytab 파일이 없는 경우 만드는 것을 도와줄 수 있습니다.

다음 코드 조각을 사용하여 시크릿을 만들 수 있습니다(`gitlab` 네임스페이스에 차트를 설치 중이고 `gitlab.keytab`가 서비스 주체를 포함하는 keytab 파일이라고 가정):

```shell
kubectl create secret generic gitlab-kerberos-keytab --namespace=gitlab --from-file=keytab=./gitlab.keytab
```

`global.appConfig.kerberos.enabled=true`을(를) 설정하여 Git용 Kerberos 통합을 활성화합니다. 또한 `kerberos` 공급자를 브라우저의 티켓 기반 인증을 위해 활성화된 [OmniAuth](https://docs.gitlab.com/integration/omniauth/) 공급자 목록에 추가합니다.

`false`로 설정된 경우 Helm 차트는 여전히 도구 상자, Sidekiq 및 Webservice 포드에 `keytab`을(를) 마운트하며, Kerberos에 대해 수동으로 구성된 [OmniAuth 설정](#omniauth)과 함께 사용할 수 있습니다.

`global.appConfig.kerberos.krb5Config`에서 Kerberos 클라이언트 구성을 제공할 수 있습니다.

```yaml
global:
  appConfig:
    kerberos:
      enabled: true
      keytab:
        secret: gitlab-kerberos-keytab
        key: keytab
      servicePrincipalName: ""
      krb5Config: |
        [libdefaults]
            default_realm = EXAMPLE.COM
      dedicatedPort:
        enabled: false
        port: 8443
        https: true
      simpleLdapLinkingAllowedRealms:
        - example.com
```

자세한 내용은 [Kerberos 설명서](https://docs.gitlab.com/integration/kerberos/)를 참조하세요.

### Kerberos 전용 포트 {#dedicated-port-for-kerberos}

GitLab은 Git 작업에 HTTP 프로토콜을 사용할 때 [Kerberos 협상을 위한 전용 포트](https://docs.gitlab.com/integration/kerberos/#http-git-access-with-kerberos-token-passwordless-authentication) 사용을 지원하여 인증 교환에서 `negotiate` 헤더가 나타날 때 기본 인증으로 대체되는 Git의 제한을 해결합니다.

전용 포트의 사용은 현재 GitLab CI/CD를 사용할 때 필요합니다. GitLab Runner 도우미는 GitLab에서 복제할 URL 내 자격 증명에 의존합니다.

이는 `global.appConfig.kerberos.dedicatedPort` 설정으로 활성화할 수 있습니다:

```yaml
global:
  appConfig:
    kerberos:
      [...]
      dedicatedPort:
        enabled: true
        port: 8443
        https: true
```

이를 통해 Kerberos 협상 전용 GitLab UI에서 추가 복제 URL이 활성화됩니다. `https: true` 설정은 URL 생성 전용이며 추가 TLS 구성을 노출하지 않습니다. TLS는 GitLab용 Ingress에서 종료되고 구성됩니다.

> [!note]
> [`nginx-ingress` Helm 차트의 포크](nginx/_index.md) - `dedicatedPort`를 지정하면 차트의 `nginx-ingress` 컨트롤러에서 사용할 포트가 현재 노출되지 않습니다. 클러스터 운영자는 이 포트를 직접 노출해야 합니다. [이 차트 문제](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3531)를 따라 자세한 내용과 가능한 해결 방법을 확인하세요.

### LDAP 사용자 정의 허용 영역 {#ldap-custom-allowed-realms}

`global.appConfig.kerberos.simpleLdapLinkingAllowedRealms`은(는) 사용자의 LDAP DN이 사용자의 Kerberos 영역과 일치하지 않을 때 LDAP 및 Kerberos 식별을 연결하는 데 사용되는 도메인 집합을 지정하는 데 사용할 수 있습니다. 자세한 내용은 [Kerberos 통합 설명서의 사용자 정의 허용 영역 섹션](https://docs.gitlab.com/integration/kerberos/#custom-allowed-realms)을(를) 참조하세요.

## 발신 이메일 {#outgoing-email}

발신 이메일 구성은 `global.smtp.*`, `global.appConfig.microsoft_graph_mailer.*` 및 `global.email.*`을(를) 통해 사용할 수 있습니다.

```yaml
global:
  email:
    display_name: 'GitLab'
    from: 'gitlab@example.com'
    reply_to: 'noreply@example.com'
  smtp:
    enabled: true
    address: 'smtp.example.com'
    tls: true
    authentication: 'plain'
    user_name: 'example'
    password:
      secret: 'smtp-password'
      key: 'password'
  appConfig:
    microsoft_graph_mailer:
      enabled: false
      user_id: "YOUR-USER-ID"
      tenant: "YOUR-TENANT-ID"
      client_id: "YOUR-CLIENT-ID"
      client_secret:
        secret:
        key: secret
      azure_ad_endpoint: "https://login.microsoftonline.com"
      graph_endpoint: "https://graph.microsoft.com"
```

사용 가능한 구성 옵션에 대한 자세한 내용은 [발신 이메일 설명서](../installation/command-line-options.md#outgoing-email-configuration)에서 확인할 수 있습니다.

자세한 예제는 [Linux 패키지 SMTP 설정 설명서](https://docs.gitlab.com/omnibus/settings/smtp/)에서 찾을 수 있습니다.

## 플랫폼 {#platform}

`platform` 키는 GKE 또는 EKS와 같은 특정 플랫폼을 대상으로 하는 특정 기능을 위해 예약되어 있습니다.

## 선호도 {#affinity}

선호도 구성은 `global.antiAffinity` 및 `global.affinity`을(를) 통해 사용할 수 있습니다. 선호도를 통해 노드 레이블 또는 이미 노드에서 실행 중인 포드의 레이블을 기반으로 포드가 스케줄될 수 있는 노드를 제한할 수 있습니다. 이렇게 하면 클러스터 전체에 포드를 분산하거나 특정 노드를 선택하여 노드 장애 시 복원력을 보장할 수 있습니다.

```yaml
global:
  antiAffinity: soft
  affinity:
    podAntiAffinity:
      topologyKey: "kubernetes.io/hostname"
```

| 이름                                   | 유형   | 기본값                  | 설명 |
|:---------------------------------------|:-------|:-------------------------|:------------|
| `antiAffinity`                         | 문자열 | `soft`                   | 포드에 적용할 포드 반선호도입니다. |
| `affinity.podAntiAffinity.topologyKey` | 문자열 | `kubernetes.io/hostname` | 포드 반선호도 토폴로지 키입니다. |

- `global.antiAffinity`은(는) 두 가지 값을 사용할 수 있습니다:
  - `soft`: Kubernetes 스케줄러가 규칙을 적용하려고 하지만 결과를 보장하지 않는 `preferredDuringSchedulingIgnoredDuringExecution` 반선호도를 정의합니다.
  - `hard`: 포드를 노드에 스케줄하기 위해 규칙을 충족해야 하는 `requiredDuringSchedulingIgnoredDuringExecution` 반선호도를 정의합니다.
- `global.affinity.podAntiAffinity.topologyKey`은(는) 노드를 논리적 영역으로 나누는 데 사용되는 노드 특성을 정의합니다. 가장 일반적인 `topologyKey` 값은:
  - `kubernetes.io/hostname`
  - `topology.kubernetes.io/zone`
  - `topology.kubernetes.io/region`

[포드 간 선호도 및 반선호도](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity)에 대한 Kubernetes 참조입니다.

## 포드 우선순위 및 선점 {#pod-priority-and-preemption}

포드 우선순위는 `global.priorityClassName` 또는 하위 차트별로 `priorityClassName`을(를) 통해 구성할 수 있습니다. 포드 우선순위를 설정하면 스케줄러가 우선순위가 낮은 포드를 제거하여 보류 중인 포드의 스케줄링을 가능하게 합니다.

```yaml
global:
  priorityClassName: system-cluster-critical
```

| 이름                | 유형   | 기본값 | 설명 |
|:--------------------|:-------|:--------|:------------|
| `priorityClassName` | 문자열 |         | 포드에 할당된 우선순위 클래스입니다. |

## 로그 회전 {#log-rotation}

{{< history >}}

- GitLab 15.6에서 [도입](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger/-/merge_requests/10)됨.

{{< /history >}}

기본적으로 GitLab Helm 차트는 로그를 회전하지 않습니다. 이로 인해 오랫동안 실행되는 컨테이너의 임시 저장소 문제가 발생할 수 있습니다.

로그 회전을 활성화하려면 `GITLAB_LOGGER_TRUNCATE_LOGS` 환경 변수를 `true`로 설정하세요. 자세한 내용은 [GitLab Logger 설명서](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger#configuration)를 참조하세요. 특히 다음에 대한 정보를 참조하세요:

- [`GITLAB_LOGGER_TRUNCATE_INTERVAL`](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger#truncate-logs-interval).
- [`GITLAB_LOGGER_MAX_FILESIZE`](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger#max-log-file-size).

## 작업 {#jobs}

원래 GitLab의 작업은 Helm `.Release.Revision`으로 접미사가 붙어 있었는데, 아무것도 변경되지 않았는데도 `helm upgrade --install`을(를) 실행할 때 항상 작업을 업데이트하게 되므로 이상적이지 않았습니다. 또한 `helm template`을(를) 기반으로 하는 워크플로우가 제대로 작동하는 것을 방해했으며, 예를 들어 ArgoCD를 사용할 때입니다. 이름에 `.Release.Revision`을(를) 사용하기로 한 결정은 작업이 한 번만 실행될 수 있다는 전제 조건과 `helm uninstall`이(가) 작업을 삭제하지 않을 것이라는 전제 조건을 기반으로 했으며, 이는 (이제) 잘못된 것입니다.

GitLab Helm 차트 7.9 이상에서 작업 이름은 기본적으로 차트의 앱 버전과 차트의 값을 기반으로 하는 해시로 접미사가 붙어 있으며, 여기에는 `global.gitlabVersion`도 포함될 수 있습니다. 이 방식을 통해 작업 이름은 여러 `helm template` 및 `helm upgrade --install` 실행(아무것도 변경되지 않은 경우)에서 안정적으로 유지되며, 배포 중 오류 없이 작업의 변경 불가능한 필드의 값을 수정할 수도 있습니다(새로운 이름으로 인해 작업이 새 이름으로 대체됨).

`global.job.nameSuffixOverride`을(를) 설정하여 기본적으로 생성되는 해시를 사용자 정의 접미사로 재정의할 수 있습니다. 필드는 템플릿 작성을 지원하므로 이름 접미사로 `.Release.Revision`의 이전 동작을 재현할 수 있습니다:

```yaml
global:
  job:
    nameSuffixOverride: '{{ .Release.Revision }}'
```

예를 들어 모든 버전에 대해 `latest`과 같은 부동 태그로 작업 중인 경우 의도적으로 항상 변경을 트리거하려면 기본적으로 생성된 해시를 타임스탬프와 같은 동적 값으로 재정의할 수 있습니다:

```yaml
global:
  job:
    nameSuffixOverride: '{{ dateInZone "2006-01-02-15-04-05" (now) "UTC" }}'
```

또는 명령줄에서 `helm`과(와) 함께 사용할 수 있습니다:

```shell
helm <command> <options> --set global.job.nameSuffixOverride=$(date +%Y-%m-%d-%H-%M-%S)
```

| 이름                 | 유형   | 기본값 | 설명 |
|:---------------------|:-------|:--------|:------------|
| `nameSuffixOverride` | 문자열 |         | 자동 생성된 해시를 바꿀 사용자 정의 접미사 |

## Traefik {#traefik}

Traefik 설정은 `globals.traefik`을(를) 통해 구성할 수 있습니다.

```yaml
global:
  traefik:
    apiVersion: ""
```

| 이름         | 유형   | 기본값 | 설명 |
|:-------------|:-------|:--------|:------------|
| `apiVersion` | 문자열 |         | Traefik 리소스의 기본 `apiVersion`을(를) 재정의합니다. |
