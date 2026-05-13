---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenBao 차트
---

{{< details >}}

- 계층:  Ultimate
- 제공:  GitLab.com, GitLab 자체 관리
- 상태: 실험

{{< /details >}}

{{< history >}}

- GitLab 18.3에서 `ci_tanukey_ui` 및 `secrets_manager`로 명명된 [플래그](https://docs.gitlab.com/administration/feature_flags/)가 사용된 [실험](https://docs.gitlab.com/policy/development_stages_support/#experiment)으로 도입되었습니다. 기본적으로 비활성화됩니다.
- [플래그](https://docs.gitlab.com/administration/feature_flags/) `ci_tanukey_ui`는 GitLab 18.4에서 `secrets_manager`로 병합되었습니다.
- GitLab 18.8에서 일부 사용자에게 폐쇄 베타 버전으로 제공되었습니다.

{{< /history >}}

> [!flag] 이 기능의 가용성은 기능 플래그로 제어됩니다. 자세한 내용은 기록을 참조하십시오.

[OpenBao 차트](https://gitlab.com/gitlab-org/cloud-native/charts/openbao) 를 사용하여 [GitLab 시크릿 관리자](https://docs.gitlab.com/ci/secrets/secrets_manager/)를 활성화하는 데 필요한 OpenBao를 설치할 수 있습니다.

## 알려진 문제 {#known-issues}

- 다운타임 없이 OpenBao를 업그레이드할 수 없습니다. Zero downtime 업그레이드가 [OpenBao 차트 문제 13](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/issues/13)에 제안되었습니다.
- [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator)를 사용하여 OpenBao를 배포할 수 없습니다.
- OpenBao 이미지의 FIPS 변형이 이미 구축되고 있지만 OpenBao는 FIPS 검증을 받지 않았습니다. FIPS 검증은 [GitLab 문제 574875](https://gitlab.com/gitlab-org/gitlab/-/issues/574875)에서 추적됩니다.

## GitLab 시크릿 관리자 및 OpenBao 설정 {#setup-gitlab-secret-manager-and-openbao}

1. 기존 GitLab 인스턴스에서 OpenBao를 활성화합니다:

   ```yaml
   # Enable OpenBao integration
   global:
     openbao:
       enabled: true
   # Install bundled OpenBao
   openbao:
     install: true
   ```

1. GitLab에서 상단 표시줄에서 **검색 또는 이동**을 선택하고 프로젝트를 찾습니다.
1. **설정 > 일반**을 선택합니다.
1. **표시 여부, 프로젝트 기능, 권한**을 확장합니다.
1. **Secrets Manager** 토글을 켜고 시크릿 관리자가 프로비저닝될 때까지 기다립니다.

## Geo 설정 {#geo-configuration}

{{< history >}}

- `jwt_audience`은(는) GitLab 18.10에서 [도입](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4837)되었습니다.

{{< /history >}}

[GitLab Geo](https://docs.gitlab.com/ee/administration/geo/) 배포에서 보조 사이트는 기본 사이트와 다른 URL을 사용하여 OpenBao에 도달할 수 있습니다. GitLab OpenBao 인증의 JWT 대상 클레임은 OpenBao에서 구성된 `bound_audiences`와 일치해야 합니다. 각 사이트에 다른 OpenBao URL이 있는 경우 `jwt_audience`을(를) 공유 값(일반적으로 기본 사이트의 OpenBao URL)으로 설정하여 생성 사이트에 관계없이 JWT가 OpenBao에서 수락되도록 합니다.

보조 사이트 설정:

```yaml
global:
  openbao:
    enabled: true
    # Site-specific URL for this Geo secondary
    url: https://openbao.secondary.example.com:8200
    # Shared audience - must match OpenBao bound_audiences (e.g. primary site URL)
    jwt_audience: https://openbao.shared.example.com:8200
```

OpenBao `config.initialize.boundAudiences`에 `jwt_audience` 값이 포함되어 있는지 확인합니다. 번들로 제공되는 OpenBao 차트를 사용할 때 `boundAudiences`는 외부 OpenBao 호스트명으로 기본 설정됩니다. Geo의 경우 `jwt_audience`로 사용되는 공유 URL을 포함하도록 재정의해야 할 수도 있습니다.

장애 조치(failover) 시나리오에서 보조 사이트가 기본 사이트로 승격될 때 구성에서 `jwt_audience`을(를) 생략합니다. 승격된 기본 사이트는 자신의 URL을 사용하며 대상은 해당 URL로 기본 설정됩니다.

## OpenBao 업그레이드 롤백 {#rolling-back-openbao-upgrades}

OpenBao 업그레이드는 PostgreSQL 데이터에 변경을 가할 수 있으므로 역호환되지 않으며, OpenBao 업그레이드를 롤백해야 하는 경우 호환성 문제가 발생할 수 있습니다.

OpenBao를 업그레이드하기 전에 항상 [백업](#back-up-openbao)해야 합니다. OpenBao 업그레이드를 롤백해야 하는 경우 OpenBao 버전과 일치하는 데이터베이스 백업도 복원합니다.

자세한 내용은 [OpenBao 업그레이드 문서](https://openbao.org/docs/upgrading/)를 참조하세요.

## OpenBao 백업 {#back-up-openbao}

OpenBao를 완전히 백업하려면 다음이 필요합니다:

- 해제 키. 이러한 키는 복원 후 OpenBao 데이터에 액세스하는 데 필수적입니다. OpenBao 시크릿의 [시크릿 백업 프로시저](../../backup-restore/backup.md#back-up-the-secrets)를 따르세요.
- PostgreSQL 데이터베이스.

기본적으로 OpenBao PostgreSQL 데이터는 차트의 기본 제공 백업 프로시저의 일부로 백업됩니다.

다른 데이터베이스(논리적 또는 물리적)를 사용하도록 OpenBao를 구성한 경우 이 데이터베이스를 수동으로 백업해야 합니다. 기본 백업 도구는 도구가 다른 외부 데이터베이스를 인식하지 못하기 때문에 표준 PostgreSQL 설정만 다룹니다. 동기화 문제를 피하려면 GitLab과 OpenBao 데이터베이스를 동시에 백업해야 합니다.

## OpenBao 복원 {#restore-openbao}

기본적으로 OpenBao PostgreSQL 데이터는 차트의 기본 제공 복원 프로시저의 일부로 복원됩니다.

다른 데이터베이스(논리적 또는 물리적)를 사용하도록 OpenBao를 구성한 경우 OpenBao 데이터베이스 백업을 기본 제공 백업 유틸리티로 복원할 수 없으며 수동으로 복원해야 합니다.

OpenBao 백업을 복원하기 전에 OpenBao가 스케일 다운되어 있는지 확인하십시오. OpenBao는 데이터베이스 스키마를 다시 생성하려고 시도하므로 예상치 못한 오류가 발생할 수 있습니다. OpenBao를 스케일 다운하려면 다음을 실행합니다:

```shell
kubectl scale deploy -lapp=openbao,release=<helm release name> -n <namespace> --replicas=0
```

## OpenBao 구성 옵션 {#openbao-configuration-options}

다음 표에는 사용 가능한 모든 OpenBao 구성 옵션이 나열됩니다.

### 설치 명령줄 옵션 {#installation-command-line-options}

아래 표에는 `helm install` 명령에 `--set` 플래그를 사용하여 제공할 수 있는 모든 가능한 차트 구성이 포함되어 있습니다.

| 매개변수                                                | 기본값                                                 | 설명 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `logLevel`                                               | info                                                    | OpenBao 로그 수준. |
| `logRequestLevel`                                        | off                                                     | OpenBao 요청 로그 수준. 요청 로깅을 활성화하려면 이를 `logLevel`과(와) 동일한 값으로 설정하거나 더 높은 수준으로 설정하십시오. |
| `logFormat`                                              | `json`                                                  | OpenBao 로그 형식. `json` 또는 `standard`. |
| `serviceAccount.create`                                  | true                                                    | OpenBao에 대한 서비스 계정을 만듭니다. |
| `serviceAccount.automount`                               | true                                                    | |
| `serviceAccount.annotations`                             | `{}`                                                    | 추가 서비스 계정 주석. |
| `serviceAccount.name`                                    |                                                         | 생성된 서비스 계정 이름을 재정의합니다. |
| `role.create`                                            |                                                         | 필요한 RBAC 권한이 있는 역할을 만듭니다. |
| `securityContext.capabilities`                           | `{ drop: ["ALL"] }`                                     | |
| `securityContext.runAsNonRoot`                           | true                                                    | |
| `securityContext.allowPrivilegeEscalation`               | false                                                   | |
| `securityContext.runAsUser`                              | 65532                                                   | |
| `podSecurityContext.seccompProfile`                      | `RuntimeDefault`                                        | |
| `podSecurityContext.runAsUser`                           | 65532                                                   | |
| `podSecurityContext.fsGroup`                             | 65532                                                   | |
| `serviceActive.type`                                     | ClusterIP                                               | 활성 OpenBao Pod의 서비스 유형. |
| `serviceActive.annotations`                              | `{}`                                                    | 활성 OpenBao Pod의 서비스 주석. |
| `serviceInactive.type`                                   | ClusterIP                                               | 대기 중인 OpenBao Pod의 서비스 유형. |
| `serviceInactive.annotations`                            | `{}`                                                    | 대기 중인 OpenBao Pod의 서비스 주석. |
| `resources`                                              | `{}`                                                    | 리소스 제한 및 요청. |
| `autoscaling.minReplicas`                                | 2                                                       | 최소 OpenBao 복제본. |
| `autoscaling.maxReplicas`                                | 2                                                       | 최대 OpenBao 복제본. |
| `autoscaling.targetCPUUtilizationPercentage`             | 80                                                      | 자동 확장의 대상 CPU 사용률. |
| `autoscaling.targetCPUMemoryPercentage`                  |                                                         | 자동 확장의 대상 메모리 사용률. |
| `livenessProbe`                                          |                                                         | OpenBao 활성성 프로브. [OpenBao 값](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml)에서 기본값을 확인하세요. |
| `readinessProbe`                                         |                                                         | OpenBao 준비성 프로브. [OpenBao 값](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml)에서 기본값을 확인하세요. |
| `nodeSelector`                                           | {}                                                      | 노드 선택기 레이블. |
| `tolerations`                                            | []                                                      | 포드 할당을 위한 허용 레이블입니다. |
| `affinity`                                               | {}                                                      | Pod 할당을 위한 선호도 레이블. |
| `config.ui`                                              | false                                                   | OpenBao UI를 활성화합니다. |
| `config.clusterPort`                                     | 8201                                                    | OpenBao 클러스터 포트. |
| `config.apiPort`                                         | 8200                                                    | OpenBao API 포트. |
| `config.cacheSize`                                       | 8200                                                    | 항목 개수로 물리적 저장소 하위 시스템에서 사용하는 읽기 캐시의 크기. |
| `config.maxRequestSize`                                  | 786432                                                  | 최대 요청 크기(바이트). 기본값은 768KB입니다. |
| `config.maxRequestJsonMemory`                            | 1048576                                                 | JSON 구문 분석된 요청 본문의 최대 크기(바이트). 기본값은 1MB입니다. |

### 컨테이너 이미지 옵션 {#container-image-options}

OpenBao 차트는 [클라우드 네이티브 GitLab 컨테이너 이미지](https://gitlab.com/gitlab-org/build/CNG)를 배포하여 OpenBao를 배포합니다. OpenBao 빌드에는 업스트림 버전의 [수정 사항](https://gitlab.com/gitlab-org/govern/secrets-management/openbao-internal)이 포함됩니다. 결과적으로 일부 기능은 표준 OpenBao 릴리스와 다를 수 있습니다.

| 매개변수                                                | 기본값                                                   | 설명 |
|----------------------------------------------------------|-----------------------------------------------------------|-------------|
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-openbao` | OpenBao 이미지의 리포지토리. |
| `image.pullPolicy`                                       | `IfNotPresent`                                            | 이미지 풀 정책. |
| `image.tag`                                              |                                                           | 이를 재정의하여 사용자 정의 OpenBao 버전을 배포합니다. |
| `imagePullSecrets`                                       | `[]`                                                      | 비공개 리포지토리에서 이미지를 가져올 비밀. |

### Ingress 및 TLS 구성 옵션 {#ingress-and-tls-configuration-options}

OpenBao 차트는 기본적으로 Ingress 종료 TLS 암호화를 사용합니다.

| 매개변수                                                | 기본값                                                 | 설명 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `global.openbao.host`                                    | `openbao.<GitLab Domain>`                                 | OpenBao 호스트. GitLab 웹서비스 및 OpenBao 차트를 구성하는 데 사용됩니다. |
| `global.openbao.url`                                     | 호스트에서 파생됨                                       | GitLab용 OpenBao URL. 있는 경우 전체 URI여야 합니다. |
| `global.openbao.jwt_audience`                            | `url`과(와) 동일                                           | OpenBao 인증을 위한 JWT 대상 클레임. [Geo 배포](#geo-configuration)에 대해 설정하여 사이트가 다른 URL을 사용할 때입니다. OpenBao `bound_audiences`과(와) 일치해야 합니다. |
| `global.openbao.psql`                                    | `{}`                                                    | OpenBao 데이터베이스 설정(호스트, 데이터베이스, 사용자 이름, 비밀번호). |
| `ingress.enabled`                                        | true                                                    | Runner가 OpenBao에 도달하도록 OpenBao Ingress를 활성화합니다. |
| `ingress.hostname`                                       | 전역 호스트 구성을 기반으로 한 외부 OpenBao 호스트.     | Ingress가 일치해야 하는 호스트명. |
| `ingress.tls.enabled`                                    | true                                                    | Ingress TLS를 활성화합니다. |
| `ingress.tls.secretName`                                 |                                                         | [Kubernetes TLS 시크릿](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)의 이름. 기본적으로 certmanager에서 관리합니다. |
| `ingress.annotations`                                    | true                                                    | Ingress로 렌더링된 주석. 이를 사용하여 비NGINX Ingress 컨트롤러에 대해 OpenBao를 구성합니다. |
| `ingress.configureCertmanager`                           | 전역 certmanager 구성                               | certmanager를 사용하여 TLS 인증서를 관리합니다. |
| `ingress.certmanagerIssuer`                              | `<release>-issuer`                                       | certmanager 발급자의 이름. |
| `ingress.sslPassthroughNginx`                            | false                                                   | OpenBao에 들어오는 TLS 연결을 통과하도록 Ingress에 주석을 달합니다. certmanager가 구성된 경우 새 HTTP01 챌린지가 다른 Ingress를 통해 전달됩니다. |
| `config.tlsDisable`                                      | true                                                    | 내부 TLS를 비활성화합니다. 비활성화되면 Ingress TLS 통과도 비활성화됩니다. |
| `config.metricsListener.tlsDisable`                      | true                                                    | 메트릭 리스너의 내부 TLS를 비활성화합니다. |

엔드투엔드 암호화된 TLS로 OpenBao를 운영해야 합니다. 엔드투엔드 TLS를 활성화하려면 OpenBao를 구성하여 TLS 연결을 예상하고 TLS 연결을 NGINX Ingress를 통해 전달합니다:

```yaml
global:
  ingress:
    useNewIngressForCerts: true
config:
  tlsDisable: false
ingress:
  sslPassthroughNginx: true
```

> [!note] SSL 통과를 활성화하려면 cert-manager를 사용하여 다른 Ingress를 만들어 HTTP01 챌린지를 완료해야 합니다. 번들로 제공되는 certmanager 및 `Issuer`를 사용하는 경우 발급자가 [`global.ingress.useNewIngressForCerts`](../globals.md#globalingressusenewingressforcerts)를 구성하여 올바른 `IngressClass`를 설정하는지 확인하세요.

### Gateway API {#gateway-api}

OpenBao 차트를 사용하면 `HTTPRoute`을(를) 통해 트래픽을 노출할 수 있습니다. [Gateway API가 전역적으로 활성화](../globals.md#gateway-api)된 경우 관리되는 `Gateway` 리소스에서 OpenBao에 대한 리스너가 생성됩니다.

| 매개변수                  | 기본값                                                 | 설명 |
|----------------------------|---------------------------------------------------------|-------------|
| `gatewayRoute.enabled`     | `global.gatewayApi.enabled`의 값으로 기본 설정        | `HTTPRoute`을(를) 통해 OpenBao를 노출하도록 활성화합니다. |
| `gatewayRoute.sectionName` | openbao-web                                             | `HTTPRoute`에서 사용할 Gateway 섹션. |
| `gatewayRoute.gatewayName` | GitLab 차트 관리 Gateway                            | `HTTPRoute`에서 사용할 Gateway 이름. |
| `gatewayRoute.annotations` | `{}`                                                    | `HTTPRoute`에 대한 추가 주석. |
| `gatewayRoute.timeouts`    | `{}`                                                    | `HTTPRoute`에 대한 사용자 정의 시간 초과 구성. |

### 모니터링 구성 옵션 {#monitoring-configuration-options}

OpenBao는 번들로 제공되는 Prometheus 하위 차트에서 스크랩할 Prometheus 메트릭을 노출하도록 미리 구성되어 있습니다.

| 매개변수                                                | 기본값                                                 | 설명 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.telemetry.enabled`                               | true                                                    | 원격 분석 및 모니터링을 활성화합니다. |
| `config.telemetry.disableHostname`                       | true                                                    | 로컬 호스트명으로 게이지 값을 접두사합니다. |
| `config.telemetry.prometheusRetentionTime`               | `24h`                                                   | 메트릭 보존 시간. |
| `config.telemetry.metricsPrefix`                         | `openbao`                                               | 모든 메트릭의 접두사. |
| `config.telemetry.usageGaugePeriod`                      | 0                                                       | 토큰 개수, 엔티티 개수, 시크릿 개수 등 고 카디널리티 사용 데이터를 수집하는 간격. |
| `config.telemetry.numLeaseMetricsBuckets`                | 1                                                       | 리스의 만료 버킷 수. |
| `config.metricsListener.enabled`                         | true                                                    | 메트릭에 대한 요청을 제공하기 위한 두 번째 API 포트를 활성화합니다. 리스너는 모든 API 요청을 제공할 수 있지만 인증 없이 메트릭에 대한 요청을 제공합니다. |
| `config.metricsListener.tlsDisable`                      | true                                                    | 메트릭 리스너의 내부 TLS를 비활성화합니다. |
| `config.metricsListener.port`                            | 8209                                                    | 메트릭 리스너의 포트. |
| `config.metricsListener.unauthenticatedMetricsAccess`    | true                                                    | 인증 없이 메트릭에 대한 요청을 제공할 수 있도록 허용합니다. |
| `podMonitor.enabled`                                     | false                                                   | Prometheus 운영자에 대한 PodMonitor 리소스를 활성화합니다. 클러스터에 Prometheus 운영자가 설치되어 있어야 합니다. |
| `podMonitor.additionalLabels`                            | `{}`                                                    | PodMonitor 리소스에 추가할 추가 레이블. |
| `podMonitor.selectorLabels`                              | `{}`                                                    | 스크랩할 포드를 필터링하기 위한 추가 선택기 레이블. |
| `podMonitor.endpointConfig`                              | `{}`                                                    | 추가 엔드포인트 구성(예: `interval`, `scrapeTimeout`). |

### 해제 및 초기화 옵션 {#unsealing-and-initialization-options}

OpenBao 차트는 두 가지의 상호 배타적인 자동 해제 방법을 지원합니다:

- [정적 자동 해제](https://openbao.org/docs/configuration/seal/static/)(기본값)
- [AWS KMS 해제](https://openbao.org/docs/configuration/seal/awskms/)

또한 OpenBao 선언적 [자체 초기화](https://openbao.org/docs/configuration/self-init/)를 사용합니다.

| 매개변수                                                | 기본값                                                 | 설명 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.unseal.static.enabled`                           | true                                                    | 정적 자동 해제를 활성화합니다. |
| `config.unseal.static.currentKeyId`                      | `static-unseal-0`                                       | 현재 정적 해제 키의 ID. |
| `config.unseal.static.currentKey`                        | `/srv/openbao/keys/static-unseal-0`                     | 현재 정적 해제 키의 경로. |
| `config.unseal.static.previousKeyId`                     |                                                         | 이전 정적 해제 키의 ID. |
| `config.unseal.static.previousKey`                       | `/srv/openbao/keys/static-unseal-1`                     | 이전 정적 해제 키의 경로. 이전 키 ID도 설정된 경우에만 렌더링됩니다. |
| `config.unseal.awskms.enabled`                           | false                                                   | AWS KMS 자동 해제를 활성화합니다. |
| `config.unseal.awskms.kmsKeyId`                          |                                                         | KMS 키 ID, ARN 또는 별칭(예: `alias/my-openbao-key`). `config.unseal.awskms.enabled`이(가) `true`일 때 필수입니다. |
| `config.unseal.awskms.region`                            |                                                         | KMS 키가 있는 AWS 리전. |
| `config.unseal.awskms.endpoint`                          |                                                         | 선택적 사용자 정의 KMS 엔드포인트 URL(예: VPC 엔드포인트). |
| `config.initialize.enabled`                              | true                                                    | OpenBao 자체 초기화를 활성화합니다. |
| `config.initialize.oidcDiscoveryUrl`                     | 외부 GitLab 호스트                                    | OIDC 검색 URL. 외부 GitLab 호스트명으로 기본 설정됩니다. |
| `config.initialize.boundIssuer`                          | 외부 GitLab 호스트                                    | 발급자 URL. 외부 GitLab 호스트명으로 기본 설정됩니다. |
| `config.initialize.boundAudiences`                       | 외부 OpenBao 호스트                                   | OIDC 역할 대상. 외부 OpenBao 호스트명으로 기본 설정됩니다. |
| `staticUnsealSecret.generate`                            | false                                                   | OpenBao 자동 해제를 위한 정적 키를 생성합니다. GitLab 차트 공유 시크릿 차트에서 관리하므로 기본값은 false입니다. |
| `initializeTpl`                                          |                                                         | OpenBao 자체 초기화에 전달된 템플릿. [OpenBao 값](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml)에서 기본값을 확인하세요. |

#### AWS KMS 해제 {#aws-kms-unsealing}

AWS KMS 해제는 해제 키를 AWS KMS 키에 위임하여 정적 키 시크릿을 관리할 필요를 제거합니다.

AWS(EKS, EC2)에서 실행할 때 명시적 AWS 자격 증명이 필요하지 않도록 [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) 또는 인스턴스 프로파일을 사용합니다. OpenBao 서비스 계정에 IAM 역할 ARN으로 주석을 달기:

```yaml
openbao:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::<account-id>:role/<role-name>"
  config:
    unseal:
      static:
        enabled: false
      awskms:
        enabled: true
        kmsKeyId: "alias/my-openbao-key"
        region: "us-east-1"
```

IAM 역할은 KMS 키에 대해 `kms:Encrypt`, `kms:Decrypt` 및 `kms:DescribeKey` 권한이 있어야 합니다.

### 감사 이벤트 스트리밍 옵션 {#audit-event-streaming-options}

OpenBao 차트는 [감사 장치](https://openbao.org/docs/audit/)를 구성하여 이벤트를 GitLab으로 스트림합니다.

| 매개변수                                                | 기본값                                                 | 설명 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `global.openbao.httpAudit.secret`                        | `<release>-openbao-audit-secret`                        | OpenBao와 GitLab 간에 공유되는 토큰을 저장하는 시크릿의 이름. |
| `global.openbao.httpAudit.key`                           | `token`                                                 | 공유 토큰을 저장하는 시크릿 키. |
| `config.audit.http.enabled`                              | true                                                    | HTTP를 사용하여 감사 이벤트를 GitLab으로 스트리밍할 수 있도록 활성화합니다. |
| `config.audit.http.streamingUri`                         | 내부 워커호스 URL                                  | 감사 이벤트를 스트리밍할 엔드포인트. |
| `config.audit.http.authTokenPath`                        | `/srv/openbao/audit/gitlab-auth`                        | GitLab과 공유되는 토큰이 마운트된 경로. |
| `httpAuditSecret.generate`                               | false                                                   | 인증된 감사를 위해 GitLab과 공유할 시크릿을 생성합니다. GitLab 차트 공유 시크릿 차트에서 관리하므로 기본값은 false입니다. |
| `initializeTpl`                                          |                                                         | OpenBao 감사를 구성하기 위해 전달된 템플릿. [OpenBao 값](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml)에서 기본값을 확인하세요. |

## 데이터베이스 구성 {#database-configuration}

OpenBao는 Rails 백엔드에서 데이터 격리를 위해 **separate logical database**(`openbao` 기본값)를 사용합니다.

`global.openbao.psql` 또는 `openbao.config.storage.postgresql.connection`를 호스트, 데이터베이스, 사용자 이름 및 비밀번호로 구성합니다. 데이터베이스를 수동으로 만들어야 합니다. **비밀번호가 필요합니다**는 주 GitLab 데이터베이스에서 상속되지 않습니다.

외부 데이터베이스를 구성하려면:

1. 데이터베이스 서버에서 PostgreSQL 사용자 및 데이터베이스를 만듭니다:

   ```sql
   -- Create the OpenBao user
   CREATE USER openbao WITH PASSWORD '<password>';

   -- Create the OpenBao database
   CREATE DATABASE openbao OWNER openbao;
   ```

1. 비밀번호가 포함된 Kubernetes 시크릿을 만듭니다:

   ```shell
   kubectl create secret -n bao generic openbao-db-password --from-literal=password="<password>"
   ```

1. 외부 데이터베이스에 연결하도록 OpenBao를 구성합니다:

   ```yaml
   global:
     openbao:
       psql:
         host: "psql.openbao.example.com"
         port: 5432
         database: openbao
         username: openbao
         password:
           secret: openbao-db-password
           key: password
   ```

   이것은 백업 및 복원 작업을 위해 Toolbox에서도 액세스할 수 있으므로 선호하는 위치인 `global.openbao.psql`을(를) 사용합니다. 고급 연결 옵션(예: `sslMode`, `connectTimeout` 또는 keepalive 조정)을 설정하려면 `openbao.config.storage.postgresql.connection`를 전역 설정 옆에 사용합니다.

1. OpenBao를 배포하거나 업그레이드합니다. 시작할 때 OpenBao는 지정된 데이터베이스에서 데이터베이스 스키마를 자동으로 만듭니다.
