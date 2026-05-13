---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 컨테이너 레지스트리 사용
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

`registry` 서브 차트는 Kubernetes에서 완전한 클라우드 네이티브 GitLab 배포를 위한 레지스트리 구성 요소를 제공합니다. 이 서브 차트는 [업스트림 차트](https://github.com/docker/distribution-library-image) 를 기반으로 하며 GitLab [컨테이너 레지스트리](https://gitlab.com/gitlab-org/container-registry)를 포함합니다.

이 차트는 3개의 주요 부분으로 구성됩니다:

- [Service](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/service.yaml),
- [Deployment](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/deployment.yaml),
- [ConfigMap](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/configmap.yaml).

모든 구성은 [레지스트리 구성 설명서](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads)에 따라 처리되며, `/etc/docker/registry/config.yml` 변수는 `Deployment`에 제공되고 `ConfigMap`에서 채워집니다. `ConfigMap`는 업스트림 기본값을 재정의하지만 [이에 기반합니다](https://github.com/docker/distribution-library-image/blob/master/config-example.yml). 자세한 내용은 아래를 참조하십시오:

- [`distribution/cmd/registry/config-example.yml`](https://github.com/docker/distribution/blob/master/cmd/registry/config-example.yml)
- [`distribution-library-image/config-example.yml`](https://github.com/docker/distribution-library-image/blob/master/config-example.yml)

## 설계 선택 {#design-choices}

Kubernetes `Deployment`는 이 차트의 배포 방법으로 선택되어 인스턴스의 간단한 확장을 허용하면서 [롤링 업데이트](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)를 허용합니다.

이 차트는 2개의 필수 시크릿과 1개의 선택적 시크릿을 사용합니다:

### 필수 {#required}

- `global.registry.certificate.secret`: 연결된 GitLab 인스턴스에서 제공한 인증 토큰을 확인하기 위해 공용 인증서 번들을 포함할 전역 시크릿입니다. GitLab을 인증 끝점으로 사용하는 [설명서](https://docs.gitlab.com/administration/packages/container_registry/#use-an-external-container-registry-with-gitlab-as-an-auth-endpoint)를 참조하십시오.
- `global.registry.httpSecret.secret`: 레지스트리 포드 간의 [공유 시크릿](https://distribution.github.io/distribution/about/configuration/#http)을 포함할 전역 시크릿입니다.

### 선택 사항 {#optional}

- `profiling.stackdriver.credentials.secret`: Stackdriver 프로파일링이 활성화되어 있고 명시적 서비스 계정 자격 증명을 제공해야 하는 경우, 이 시크릿의 값(기본적으로 `credentials` 키에 있음)은 GCP 서비스 계정 JSON 자격 증명입니다. GKE를 사용하고 [워크로드 ID](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)를 사용하여 워크로드에 서비스 계정을 제공하는 경우(또는 노드 서비스 계정, 다만 이는 권장되지 않음), 이 시크릿은 필수가 아니므로 제공되지 않아야 합니다. 어느 경우든 서비스 계정에는 `roles/cloudprofiler.agent` 역할 또는 동등한 [수동 권한](https://cloud.google.com/profiler/docs/iam#roles)이 필요합니다.

## 구성 {#configuration}

아래에서 구성의 주요 섹션을 모두 설명하겠습니다. 부모 차트에서 구성할 때 이 값은 다음과 같습니다:

```yaml
registry:
  enabled:
  maintenance:
    readonly:
      enabled: false
    uploadpurging:
      enabled: true
      age: 168h
      interval: 24h
      dryrun: false
  image:
    tag: 'v4.15.2-gitlab'
    pullPolicy: IfNotPresent
  annotations:
  service:
    type: ClusterIP
    name: registry
  httpSecret:
    secret:
    key:
  authEndpoint:
  tokenIssuer:
  certificate:
    secret: gitlab-registry
    key: registry-auth.crt
  deployment:
    terminationGracePeriodSeconds: 30
  draintimeout: '0'
  hpa:
    minReplicas: 2
    maxReplicas: 10
    cpu:
      targetAverageUtilization: 75
    behavior:
      scaleDown:
        stabilizationWindowSeconds: 300
  storage:
    secret:
    key: storage
    extraKey:
  validation:
    disabled: true
    manifests:
      referencelimit: 0
      payloadsizelimit: 0
      urls:
        allow: []
        deny: []
  notifications: {}
  tolerations: []
  affinity: {}
  ingress:
    enabled: false
    tls:
      enabled: true
      secretName: redis
    annotations:
    configureCertmanager:
    proxyReadTimeout:
    proxyBodySize:
    proxyBuffering:
  networkpolicy:
    enabled: false
    egress:
      enabled: false
      rules: []
    ingress:
      enabled: false
      rules: []
  serviceAccount:
    create: false
    automountServiceAccountToken: false
  tls:
    enabled: false
    secretName:
    verify: true
    caSecretName:
    cipherSuites:
```

이 차트를 독립형으로 배포하기로 선택한 경우 최상위 수준에서 `registry`를 제거하십시오.

## 설치 매개 변수 {#installation-parameters}

| 매개 변수                                                | 기본값                                                              | 설명 |
|----------------------------------------------------------|----------------------------------------------------------------------|-------------|
| `annotations`                                            |                                                                      | Pod 주석 |
| `podLabels`                                              |                                                                      | 보충 Pod 레이블입니다. 선택기에 사용되지 않습니다. |
| `common.labels`                                          |                                                                      | 이 차트에서 생성한 모든 객체에 적용되는 보충 레이블입니다. |
| `authAutoRedirect`                                       | `true`                                                               | 자동 인증 리다이렉트(Windows 클라이언트가 작동하려면 true여야 함) |
| `authEndpoint`                                           | `global.hosts.gitlab.name`                                           | 인증 끝점(호스트 및 포트만) |
| `certificate.secret`                                     | `gitlab-registry`                                                    | JWT 인증서 |
| `debug.addr.port`                                        | `5001`                                                               | 포트 디버그  |
| `debug.tls.enabled`                                      | `false`                                                              | 레지스트리의 디버그 포트에 대해 TLS를 활성화합니다. 라이브니스 및 준비 상태 프로브뿐만 아니라 메트릭 끝점(활성화된 경우)에 영향을 미칩니다. |
| `debug.tls.secretName`                                   |                                                                      | 레지스트리 디버그 끝점에 대한 유효한 인증서와 키를 포함하는 Kubernetes TLS 시크릿의 이름입니다. 설정되지 않고 `debug.tls.enabled=true` - 디버그 TLS 구성이 레지스트리의 TLS 인증서로 기본 설정됩니다. |
| `debug.prometheus.enabled`                               | `false`                                                              | **DEPRECATED** `metrics.enabled` 사용 |
| `debug.prometheus.path`                                  | `""`                                                                 | **DEPRECATED** `metrics.path` 사용 |
| `metrics.enabled`                                        | `false`                                                              | 메트릭 끝점을 스크래핑에 사용할 수 있도록 해야 하는 경우 |
| `metrics.path`                                           | `/metrics`                                                           | 메트릭 끝점 경로 |
| `metrics.serviceMonitor.enabled`                         | `false`                                                              | Prometheus 운영자가 메트릭 스크래핑을 관리하도록 ServiceMonitor를 만들어야 하는 경우 `prometheus.io` 스크래핑 주석을 제거합니다. |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                                 | ServiceMonitor에 추가할 추가 레이블 |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                                 | ServiceMonitor에 대한 추가 끝점 구성 |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                                 | 포드가 정상적으로 종료하는 데 필요한 초 단위의 선택적 지속 시간입니다. |
| `deployment.strategy`                                    | `{}`                                                                 | 배포에서 사용하는 업데이트 전략을 구성할 수 있습니다. |
| `draintimeout`                                           | `'0'`                                                                | SIGTERM 신호를 받은 후 HTTP 연결이 드레인되기를 기다리는 시간(예: `'10s'`) |
| `relativeurls`                                           | `false`                                                              | 레지스트리가 Location 헤더에서 상대 URL을 반환하도록 활성화합니다. |
| `enabled`                                                | `true`                                                               | 레지스트리 플래그 활성화 |
| `api.enabled`                                            | `true`                                                               | Service, Deployment, HPA 및 PDB 리소스를 활성화합니다. |
| `extraContainers`                                        |                                                                      | 포함할 컨테이너 목록을 포함하는 여러 줄 리터럴 스타일 문자열 |
| `extraInitContainers`                                    |                                                                      | 포함할 추가 init 컨테이너 목록 |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`                    | 동작에는 상향 및 하향 확장 동작의 사양이 포함됩니다(`autoscaling/v2beta2` 이상 필요). |
| `hpa.customMetrics`                                      | `[]`                                                                 | 사용자 지정 메트릭에는 원하는 사양이 포함되어 있으며 `targetAverageUtilization`에서 구성된 기본 평균 CPU 사용률 사용을 재정의합니다. |
| `hpa.cpu.targetType`                                     | `Utilization`                                                        | 자동 확장 CPU 대상 유형을 설정합니다. `Utilization` 또는 `AverageValue`여야 합니다. |
| `hpa.cpu.targetAverageValue`                             |                                                                      | 자동 확장 CPU 대상 값 설정 |
| `hpa.cpu.targetAverageUtilization`                       | `75`                                                                 | 자동 확장 CPU 대상 사용률 설정 |
| `hpa.memory.targetType`                                  |                                                                      | 자동 확장 메모리 대상 유형을 설정합니다. `Utilization` 또는 `AverageValue`여야 합니다. |
| `hpa.memory.targetAverageValue`                          |                                                                      | 자동 확장 메모리 대상 값 설정 |
| `hpa.memory.targetAverageUtilization`                    |                                                                      | 자동 확장 메모리 대상 사용률 설정 |
| `hpa.minReplicas`                                        | `2`                                                                  | 최소 복제본 수 |
| `hpa.maxReplicas`                                        | `10`                                                                 | 최대 복제본 수 |
| `httpSecret`                                             |                                                                      | HTTPS 시크릿 |
| `extraEnvFrom`                                           |                                                                      | 다른 데이터 소스에서 노출할 추가 환경 변수 목록 |
| `image.pullPolicy`                                       |                                                                      | 레지스트리 이미지의 풀 정책 |
| `image.pullSecrets`                                      |                                                                      | 이미지 저장소에 사용할 시크릿 |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry` | 레지스트리 이미지 |
| `image.tag`                                              | `v4.15.2-gitlab`                                                     | 사용할 이미지의 버전 |
| `init.image.repository`                                  |                                                                      | initContainer 이미지 |
| `init.image.tag`                                         |                                                                      | initContainer 이미지 태그 |
| `init.containerSecurityContext`                          |                                                                      | initContainer 특정 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                               | initContainer 특정:  컨테이너를 시작할 사용자 ID |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                              | initContainer 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다. |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                               | initContainer 특정:  컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다. |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                          | initContainer 특정:  컨테이너에 대한 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다. |
| `keda.enabled`                                           | `false`                                                              | [KEDA](https://keda.sh/) `ScaledObjects`를 `HorizontalPodAutoscalers` 대신 사용 |
| `keda.pollingInterval`                                   | `30`                                                                 | 각 트리거를 확인하는 간격 |
| `keda.cooldownPeriod`                                    | `300`                                                                | 마지막 트리거가 활성 상태로 보고된 후 리소스를 0으로 다시 확장하기 전에 대기할 기간 |
| `keda.minReplicaCount`                                   | `hpa.minReplicas`                                                    | KEDA가 리소스를 축소할 최소 복제본 수입니다. |
| `keda.maxReplicaCount`                                   | `hpa.maxReplicas`                                                    | KEDA가 리소스를 확장할 최대 복제본 수입니다. |
| `keda.fallback`                                          |                                                                      | KEDA 폴백 구성을 위해 [설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)를 참조하십시오. |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                                      | KEDA가 만들 HPA 리소스의 이름입니다. |
| `keda.restoreToOriginalReplicaCount`                     |                                                                      | `ScaledObject`가 삭제된 후 대상 리소스를 원래 복제본 수로 다시 확장할지 여부를 지정합니다. |
| `keda.behavior`                                          | `hpa.behavior`                                                       | 상향 및 하향 확장 동작의 사양입니다. |
| `keda.triggers`                                          |                                                                      | 대상 리소스의 확장을 활성화하기 위한 트리거 목록으로, `hpa.cpu` 및 `hpa.memory`에서 계산된 트리거로 기본값이 설정됩니다. |
| `log`                                                    | `{level: info, fields: {service: registry}}`                         | 로깅 옵션을 구성합니다. |
| `minio.bucket`                                           | `global.registry.bucket`                                             | 레거시 레지스트리 버킷 이름 |
| `maintenance.readonly.enabled`                           | `false`                                                              | 레지스트리의 읽기 전용 모드 활성화 |
| `maintenance.uploadpurging.enabled`                      | `true`                                                               | 업로드 제거 활성화 |
| `maintenance.uploadpurging.age`                          | `168h`                                                               | 지정된 기간보다 오래된 업로드 제거 |
| `maintenance.uploadpurging.interval`                     | `24h`                                                                | 업로드 제거가 수행되는 빈도 |
| `maintenance.uploadpurging.dryrun`                       | `false`                                                              | 삭제하지 않고 제거될 업로드만 나열 |
| `priorityClassName`                                      |                                                                      | 포드에 할당된 [우선순위 클래스](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)입니다. |
| `reporting.sentry.enabled`                               | `false`                                                              | Sentry를 사용한 보고 활성화 |
| `reporting.sentry.dsn`                                   |                                                                      | Sentry DSN(데이터 원본 이름) |
| `reporting.sentry.environment`                           |                                                                      | Sentry [환경](https://docs.sentry.io/concepts/key-terms/environments/) |
| `profiling.stackdriver.enabled`                          | `false`                                                              | Stackdriver를 사용한 지속적인 프로파일링 활성화 |
| `profiling.stackdriver.credentials.secret`               | `gitlab-registry-profiling-creds`                                    | 자격 증명을 포함하는 시크릿의 이름 |
| `profiling.stackdriver.credentials.key`                  | `credentials`                                                        | 자격 증명이 저장된 시크릿 키 |
| `profiling.stackdriver.service`                          | `RELEASE-registry` (템플릿 서비스 이름)                          | 프로필을 기록할 Stackdriver 서비스의 이름 |
| `profiling.stackdriver.projectid`                        | 실행 중인 GCP 프로젝트                                            | 프로필을 보고할 GCP 프로젝트 |
| `database.configure`                                     | `false`                                                              | 레지스트리 차트에서 데이터베이스 구성을 채우되 활성화하지 않습니다. [기존 레지스트리를 가져올](metadata_database.md#enable-for-and-import-existing-registries) 때 필수입니다. |
| `database.enabled`                                       | `false`                                                              | 메타데이터 데이터베이스를 활성화합니다. 이는 시험적 기능이며 프로덕션 환경에서 사용해서는 안 됩니다. |
| `database.host`                                          | `global.psql.host`                                                   | 데이터베이스 서버 호스트 이름입니다. |
| `database.port`                                          | `global.psql.port`                                                   | 데이터베이스 서버 포트입니다. |
| `database.user`                                          |                                                                      | 데이터베이스 사용자 이름입니다. |
| `database.password.secret`                               | `RELEASE-registry-database-password`                                 | 데이터베이스 비밀번호를 포함하는 시크릿의 이름입니다. |
| `database.password.key`                                  | `password`                                                           | 데이터베이스 비밀번호가 저장된 시크릿 키입니다. |
| `database.name`                                          |                                                                      | 데이터베이스 이름입니다. |
| `database.sslmode`                                       |                                                                      | SSL 모드입니다. `disable`, `allow`, `prefer`, `require`, `verify-ca` 또는 `verify-full` 중 하나일 수 있습니다. |
| `database.ssl.secret`                                    | `global.psql.ssl.secret`                                             | 클라이언트 인증서, 키 및 인증 기관을 포함하는 시크릿입니다. 기본 PostgreSQL SSL 시크릿로 기본값이 설정됩니다. |
| `database.ssl.clientCertificate`                         | `global.psql.ssl.clientCertificate`                                  | 클라이언트 인증서를 참조하는 시크릿 내의 키입니다. |
| `database.ssl.clientKey`                                 | `global.psql.ssl.clientKey`                                          | 클라이언트 키를 참조하는 시크릿 내의 키입니다. |
| `database.ssl.serverCA`                                  | `global.psql.ssl.serverCA`                                           | 인증 기관(CA)을 참조하는 시크릿 내의 키입니다. |
| `database.connecttimeout`                                | `0`                                                                  | 연결을 기다리는 최대 시간입니다. 0 또는 지정되지 않으면 무기한 대기를 의미합니다. |
| `database.draintimeout`                                  | `0`                                                                  | 종료 시 모든 연결을 드레인할 최대 시간입니다. 0 또는 지정되지 않으면 무기한 대기를 의미합니다. |
| `database.preparedstatements`                            | `false`                                                              | 준비된 명령문을 활성화합니다. PgBouncer와의 호환성을 위해 기본적으로 비활성화됩니다. |
| `database.primary`                                       | `false`                                                              | 주 데이터베이스 서버를 대상으로 합니다. 레지스트리 `database.migrations`를 실행할 때 대상으로 지정할 전용 FQDN을 지정하는 데 사용됩니다. `host`는 지정되지 않을 때 `database.migrations`를 실행하는 데 사용됩니다. |
| `database.pool.maxidle`                                  | `0`                                                                  | 유휴 연결 풀의 최대 연결 수입니다. `maxopen`이 `maxidle`보다 작으면 `maxidle`은 `maxopen` 제한과 일치하도록 감소합니다. 0 또는 지정되지 않으면 유휴 연결이 없음을 의미합니다. |
| `database.pool.maxopen`                                  | `0`                                                                  | 데이터베이스에 대한 열린 최대 연결 수입니다. `maxopen`이 `maxidle`보다 작으면 `maxidle`은 `maxopen` 제한과 일치하도록 감소합니다. 0 또는 지정되지 않으면 무제한 열린 연결을 의미합니다. |
| `database.pool.maxlifetime`                              | `0`                                                                  | 연결을 재사용할 수 있는 최대 시간입니다. 만료된 연결은 재사용 전에 느리게 닫힐 수 있습니다. 0 또는 지정되지 않으면 무제한 재사용을 의미합니다. |
| `database.pool.maxidletime`                              | `0`                                                                  | 연결이 유휴 상태일 수 있는 최대 시간입니다. 만료된 연결은 재사용 전에 느리게 닫힐 수 있습니다. 0 또는 지정되지 않으면 무제한 기간을 의미합니다. |
| `database.loadBalancing.enabled`                         | `false`                                                              | 데이터베이스 로드 밸런싱을 활성화합니다. 이는 시험적 기능이며 프로덕션 환경에서 사용해서는 안 됩니다. |
| `database.loadBalancing.nameserver.host`                 | `localhost`                                                          | DNS 레코드를 찾는 데 사용할 네임서버의 호스트입니다. |
| `database.loadBalancing.nameserver.port`                 | `8600`                                                               | DNS 레코드를 찾는 데 사용할 네임서버의 포트입니다. |
| `database.loadBalancing.record`                          |                                                                      | 조회할 SRV 레코드입니다. 이 옵션은 서비스 검색이 작동하는 데 필수입니다. |
| `database.loadBalancing.replicaCheckInterval`            | `1m`                                                                 | 복제본의 상태를 확인하는 사이의 최소 시간입니다. |
| `database.migrations.enabled`                            | `true`                                                               | 초기 배포 및 차트 업그레이드 시 마이그레이션을 자동으로 실행하도록 마이그레이션 작업을 활성화합니다. 마이그레이션은 실행 중인 레지스트리 포드 내에서 수동으로도 실행할 수 있습니다. |
| `database.migrations.activeDeadlineSeconds`              | `3600`                                                               | 마이그레이션 작업에서 [activeDeadlineSeconds](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup)를 설정합니다. |
| `database.migrations.annotations`                        | `{}`                                                                 | 마이그레이션 작업에 추가할 추가 주석입니다. |
| `database.migrations.backoffLimit`                       | `6`                                                                  | 마이그레이션 작업에서 [backoffLimit](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup)를 설정합니다. |
| `database.backgroundMigrations.enabled`                  | `false`                                                              | 데이터베이스에 대한 백그라운드 마이그레이션을 활성화합니다. 레지스트리 메타데이터 데이터베이스의 시험적 기능입니다. 프로덕션에서 사용하지 마십시오. 작동 방식에 대한 자세한 설명은 [사양](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/database-background-migrations.md?ref_type=heads)을 참조하십시오. |
| `database.backgroundMigrations.jobInterval`              |                                                                      | 각 백그라운드 마이그레이션 작업 워커 실행 사이의 수면 간격입니다. 지정되지 않으면 [레지스트리에서 설정한 기본값](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#backgroundmigrations)입니다. |
| `database.backgroundMigrations.maxJobRetries`            |                                                                      | 실패한 백그라운드 마이그레이션 작업의 최대 재시도 횟수입니다. 지정되지 않으면 [레지스트리에서 설정한 기본값](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#backgroundmigrations)입니다. |
| `database.metrics.enabled`                               | `false`                                                              | `true`로 설정하면 데이터베이스 메트릭 수집을 활성화합니다. 이는 시험적 기능이며 프로덕션에서 사용해서는 안 됩니다. 레지스트리 4.27.0 이상, 메타데이터 데이터베이스(`database.enabled: true`)와 분산 잠금을 위한 Redis 캐시(`redis.cache.enabled: true`)가 필요합니다. |
| `database.metrics.interval`                              | `10s`                                                                | 데이터베이스에서 메트릭을 수집하는 간격입니다. |
| `database.metrics.leaseDuration`                         | `30s`                                                                | 메트릭 수집기가 Redis 잠금을 유지하는 기간입니다. `interval`보다 길어야 동일한 인스턴스에 의한 연속 수집을 보장합니다. |
| `gc.disabled`                                            | `true`                                                               | `true`로 설정하면 온라인 GC 워커가 비활성화됩니다. |
| `gc.maxbackoff`                                          | `24h`                                                                | 오류가 발생할 때 워커 실행 사이에 절전하는 데 사용되는 최대 지수 백오프 기간입니다. 처리할 작업이 없을 때도 적용되지만 `gc.noidlebackoff`이 `true`인 경우는 제외됩니다. 33%까지의 무작위 지터 계수가 항상 추가되므로 이것이 절대 최대값이 아님을 참고하시기 바랍니다. |
| `gc.noidlebackoff`                                       | `false`                                                              | `true`로 설정하면 처리할 작업이 없을 때 워커 실행 간 지수 백오프가 비활성화됩니다. |
| `gc.transactiontimeout`                                  | `10s`                                                                | 각 워커 실행의 데이터베이스 트랜잭션 타임아웃입니다. 각 워커는 시작 시 데이터베이스 트랜잭션을 시작합니다. 이 타임아웃을 초과하면 워커 실행이 취소되어 정지되거나 장시간 실행 중인 트랜잭션을 방지합니다. |
| `gc.blobs.disabled`                                      | `false`                                                              | `true`로 설정하면 Blob에 대한 GC 워커가 비활성화됩니다. |
| `gc.blobs.interval`                                      | `5s`                                                                 | 각 워커 실행 사이의 초기 수면 간격입니다. |
| `gc.blobs.storagetimeout`                                | `5s`                                                                 | 저장소 작업의 타임아웃입니다. 저장소 백엔드에서 고아 Blob 삭제 요청의 기간을 제한하는 데 사용됩니다. |
| `gc.manifests.disabled`                                  | `false`                                                              | `true`로 설정하면 매니페스트용 GC 워커가 비활성화됩니다. |
| `gc.manifests.interval`                                  | `5s`                                                                 | 각 워커 실행 사이의 초기 수면 간격입니다. |
| `gc.reviewafter`                                         | `24h`                                                                | 가비지 수집기가 검토용 레코드를 선택해야 하는 최소 시간입니다. `-1`은 대기 없음을 의미합니다. |
| `securityContext.fsGroup`                                | `1000`                                                               | 포드를 시작할 그룹 ID |
| `securityContext.runAsUser`                              | `1000`                                                               | 포드를 시작할 사용자 ID |
| `securityContext.fsGroupChangePolicy`                    |                                                                      | 볼륨의 소유권 및 권한 변경 정책(Kubernetes 1.23 필요) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                                     | 사용할 Seccomp 프로필 |
| `containerSecurityContext`                               |                                                                      | 컨테이너를 시작할 컨테이너 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)를 재정의합니다. |
| `containerSecurityContext.runAsUser`                     | `1000`                                                               | 컨테이너를 시작할 특정 보안 컨텍스트 사용자 ID를 덮어쓸 수 있습니다. |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                              | Gitaly 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다. |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                               | 컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다. |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                          | Gitaly 컨테이너에 대한 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다. |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                              | 기본 ServiceAccount 액세스 토큰을 포드에 마운트할지 여부를 나타냅니다. |
| `serviceAccount.enabled`                                 | `false`                                                              | ServiceAccount를 사용할지 여부를 나타냅니다. |
| `serviceLabels`                                          | `{}`                                                                 | 보충 서비스 레이블 |
| `tokenService`                                           | `container_registry`                                                 | JWT 토큰 서비스 |
| `tokenIssuer`                                            | `gitlab-issuer`                                                      | JWT 토큰 발급자 |
| `tolerations`                                            | `[]`                                                                 | 포드 할당을 위한 허용 레이블 |
| `affinity`                                               | `{}`                                                                 | 포드 할당을 위한 선호도 규칙 |
| `middleware.storage`                                     |                                                                      | 미들웨어 저장소에 대한 구성 레이어([예를 들어 s3](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#example-middleware-configuration)) |
| `redis.cache.enabled`                                    | `false`                                                              | `true`로 설정하면 Redis 캐시가 활성화됩니다. 이 기능은 [메타데이터 데이터베이스](#database)가 활성화되어야 합니다. 저장소 메타데이터가 구성된 Redis 인스턴스에 캐시됩니다. |
| `redis.cache.host`                                       | `<Redis URL>`                                                        | Redis 인스턴스의 호스트 이름입니다. 비어 있으면 값이 `global.redis.host:global.redis.port`로 채워집니다. |
| `redis.cache.port`                                       | `6379`                                                               | Redis 인스턴스의 포트입니다. |
| `redis.cache.cluster`                                    | `[]`                                                                 | 호스트 및 포트가 있는 주소 목록입니다. |
| `redis.cache.sentinels`                                  | `[]`                                                                 | 호스트 및 포트가 있는 Sentinel 목록입니다. |
| `redis.cache.mainname`                                   |                                                                      | 주 서버의 이름입니다. Sentinel에만 적용 가능합니다. |
| `redis.cache.username`                                   |                                                                      | Redis 인스턴스에 연결하는 데 사용되는 사용자 이름입니다. |
| `redis.cache.password.enabled`                           | `false`                                                              | 레지스트리에서 사용하는 Redis 캐시가 비밀번호로 보호되는지 여부를 나타냅니다. |
| `redis.cache.password.secret`                            | `gitlab-redis-secret`                                                | Redis 비밀번호를 포함하는 시크릿의 이름입니다. `shared-secrets` 기능이 활성화된 경우 자동으로 생성됩니다. |
| `redis.cache.password.key`                               | `redis-password`                                                     | Redis 비밀번호가 저장된 시크릿 키입니다. |
| `redis.cache.sentinelpassword.enabled`                   | `false`                                                              | Redis Sentinel이 비밀번호로 보호되는지 여부를 나타냅니다. `redis.cache.sentinelpassword`이 비어 있으면 `global.redis.sentinelAuth`의 값이 사용됩니다. `redis.cache.sentinels`이 정의된 경우에만 사용됩니다. |
| `redis.cache.sentinelpassword.secret`                    | `gitlab-redis-secret`                                                | Redis Sentinel 비밀번호를 포함하는 시크릿의 이름입니다. |
| `redis.cache.sentinelpassword.key`                       | `redis-sentinel-password`                                            | Redis Sentinel 비밀번호가 저장된 시크릿 키입니다. |
| `redis.cache.db`                                         | `0`                                                                  | 각 연결에 사용할 데이터베이스의 이름입니다. |
| `redis.cache.dialtimeout`                                | `0s`                                                                 | Redis 인스턴스에 연결하기 위한 타임아웃입니다. 기본값은 타임아웃이 없습니다. |
| `redis.cache.readtimeout`                                | `0s`                                                                 | Redis 인스턴스에서 읽기 위한 타임아웃입니다. 기본값은 타임아웃이 없습니다. |
| `redis.cache.writetimeout`                               | `0s`                                                                 | Redis 인스턴스에 쓰기 위한 타임아웃입니다. 기본값은 타임아웃이 없습니다. |
| `redis.cache.tls.enabled`                                | `false`                                                              | `true`로 설정하여 TLS를 활성화합니다. |
| `redis.cache.tls.insecure`                               | `false`                                                              | `true`로 설정하여 TLS를 통해 연결할 때 서버 이름 확인을 비활성화합니다. |
| `redis.cache.pool.size`                                  | `10`                                                                 | 소켓 연결의 최대 수입니다. 기본값은 10개 연결입니다. |
| `redis.cache.pool.maxlifetime`                           | `1h`                                                                 | 클라이언트가 연결을 폐기하는 연결 나이입니다. 기본값은 오래된 연결을 닫지 않는 것입니다. |
| `redis.cache.pool.idletimeout`                           | `300s`                                                               | 비활성 연결을 닫기 전에 대기할 시간입니다. |
| `redis.rateLimiting.enabled`                             | `false`                                                              | `true`로 설정하면 Redis 속도 제한이 활성화됩니다. 이 기능은 개발 중입니다. |
| `redis.rateLimiting.host`                                | `<Redis URL>`                                                        | Redis 인스턴스의 호스트 이름입니다. 비어 있으면 값이 `global.redis.host:global.redis.port`로 채워집니다. |
| `redis.rateLimiting.port`                                | `6379`                                                               | Redis 인스턴스의 포트입니다. |
| `redis.rateLimiting.cluster`                             | `[]`                                                                 | 호스트 및 포트가 있는 주소 목록입니다. |
| `redis.rateLimiting.sentinels`                           | `[]`                                                                 | 호스트 및 포트가 있는 Sentinel 목록입니다. |
| `redis.rateLimiting.mainname`                            |                                                                      | 주 서버의 이름입니다. Sentinel에만 적용 가능합니다. |
| `redis.rateLimiting.username`                            |                                                                      | Redis 인스턴스에 연결하는 데 사용되는 사용자 이름입니다. |
| `redis.rateLimiting.password.enabled`                    | `false`                                                              | Redis 인스턴스가 비밀번호로 보호되는지 여부를 나타냅니다. |
| `redis.rateLimiting.password.secret`                     | `gitlab-redis-secret`                                                | Redis 비밀번호를 포함하는 시크릿의 이름입니다. `shared-secrets` 기능이 활성화된 경우 자동으로 생성됩니다. |
| `redis.rateLimiting.password.key`                        | `redis-password`                                                     | Redis 비밀번호가 저장된 시크릿 키입니다. |
| `redis.rateLimiting.sentinelpassword.enabled`                   | `false`                                                              | Redis Sentinel이 비밀번호로 보호되는지 여부를 나타냅니다. `redis.rateLimiting.sentinelpassword`이 비어 있으면 `global.redis.sentinelAuth`의 값이 사용됩니다. `redis.rateLimiting.sentinels`이 정의된 경우에만 사용됩니다. |
| `redis.rateLimiting.sentinelpassword.secret`                    | `gitlab-redis-secret`                                                | Redis Sentinel 비밀번호를 포함하는 시크릿의 이름입니다. |
| `redis.rateLimiting.sentinelpassword.key`                       | `redis-sentinel-password`                                            | Redis Sentinel 비밀번호가 저장된 시크릿 키입니다. |
| `redis.rateLimiting.db`                                  | `0`                                                                  | 각 연결에 사용할 데이터베이스의 이름입니다. |
| `redis.rateLimiting.dialtimeout`                         | `0s`                                                                 | Redis 인스턴스에 연결하기 위한 타임아웃입니다. 기본값은 타임아웃이 없습니다. |
| `redis.rateLimiting.readtimeout`                         | `0s`                                                                 | Redis 인스턴스에서 읽기 위한 타임아웃입니다. 기본값은 타임아웃이 없습니다. |
| `redis.rateLimiting.writetimeout`                        | `0s`                                                                 | Redis 인스턴스에 쓰기 위한 타임아웃입니다. 기본값은 타임아웃이 없습니다. |
| `redis.rateLimiting.tls.enabled`                         | `false`                                                              | `true`로 설정하여 TLS를 활성화합니다. |
| `redis.rateLimiting.tls.insecure`                        | `false`                                                              | `true`로 설정하여 TLS를 통해 연결할 때 서버 이름 확인을 비활성화합니다. |
| `redis.rateLimiting.pool.size`                           | `10`                                                                 | 소켓 연결의 최대 수입니다. |
| `redis.rateLimiting.pool.maxlifetime`                    | `1h`                                                                 | 클라이언트가 연결을 폐기하는 연결 나이입니다. 기본값은 오래된 연결을 닫지 않는 것입니다. |
| `redis.rateLimiting.pool.idletimeout`                    | `300s`                                                               | 비활성 연결을 닫기 전에 대기할 시간입니다. |
| `redis.loadBalancing.enabled`                            | `false`                                                              | `true`로 설정하면 [로드 밸런싱](#load-balancing)을 위한 Redis 연결이 활성화됩니다. |
| `redis.loadBalancing.host`                               | `<Redis URL>`                                                        | Redis 인스턴스의 호스트 이름입니다. 비어 있으면 값이 `global.redis.host:global.redis.port`로 채워집니다. |
| `redis.loadBalancing.port`                               | `6379`                                                               | Redis 인스턴스의 포트입니다. |
| `redis.loadBalancing.cluster`                            | `[]`                                                                 | 호스트 및 포트가 있는 주소 목록입니다. |
| `redis.loadBalancing.sentinels`                          | `[]`                                                                 | 호스트 및 포트가 있는 Sentinel 목록입니다. |
| `redis.loadBalancing.mainname`                           |                                                                      | 주 서버의 이름입니다. Sentinel에만 적용 가능합니다. |
| `redis.loadBalancing.username`                           |                                                                      | Redis 인스턴스에 연결하는 데 사용되는 사용자 이름입니다. |
| `redis.loadBalancing.password.enabled`                   | `false`                                                              | Redis 인스턴스가 비밀번호로 보호되는지 여부를 나타냅니다. |
| `redis.loadBalancing.password.secret`                    | `gitlab-redis-secret`                                                | Redis 비밀번호를 포함하는 시크릿의 이름입니다. `shared-secrets` 기능이 활성화된 경우 자동으로 생성됩니다. |
| `redis.loadBalancing.password.key`                       | `redis-password`                                                     | Redis 비밀번호가 저장된 시크릿 키입니다. |
| `redis.loadBalancing.db`                                 | `0`                                                                  | 각 연결에 사용할 데이터베이스의 이름입니다. |
| `redis.loadBalancing.dialtimeout`                        | `0s`                                                                 | Redis 인스턴스에 연결하기 위한 타임아웃입니다. 기본값은 타임아웃이 없습니다. |
| `redis.loadBalancing.readtimeout`                        | `0s`                                                                 | Redis 인스턴스에서 읽기 위한 타임아웃입니다. 기본값은 타임아웃이 없습니다. |
| `redis.loadBalancing.writetimeout`                       | `0s`                                                                 | Redis 인스턴스에 쓰기 위한 타임아웃입니다. 기본값은 타임아웃이 없습니다. |
| `redis.loadBalancing.tls.enabled`                        | `false`                                                              | `true`로 설정하여 TLS를 활성화합니다. |
| `redis.loadBalancing.tls.insecure`                       | `false`                                                              | `true`로 설정하여 TLS를 통해 연결할 때 서버 이름 확인을 비활성화합니다. |
| `redis.loadBalancing.pool.size`                          | `10`                                                                 | 소켓 연결의 최대 수입니다. |
| `redis.loadBalancing.pool.maxlifetime`                   | `1h`                                                                 | 클라이언트가 연결을 폐기하는 연결 나이입니다. 기본값은 오래된 연결을 닫지 않는 것입니다. |
| `redis.loadBalancing.pool.idletimeout`                   | `300s`                                                               | 비활성 연결을 닫기 전에 대기할 시간입니다. |

## 차트 구성 예제 {#chart-configuration-examples}

### `pullSecrets` {#pullsecrets}

`pullSecrets`를 사용하면 포드의 이미지를 가져오기 위해 프라이빗 레지스트리에 인증할 수 있습니다.

프라이빗 레지스트리 및 인증 방법에 대한 추가 세부 정보는 [Kubernetes 설명서](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)에서 찾을 수 있습니다.

다음은 `pullSecrets`의 예제 사용입니다:

```yaml
image:
  repository: my.registry.repository
  tag: latest
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

이 섹션은 ServiceAccount를 만들어야 하는지, 기본 액세스 토큰을 포드에 마운트해야 하는지를 제어합니다.

| 이름                           |  유형   | 기본값 | 설명 |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | 부울 | `false` | 기본 ServiceAccount 액세스 토큰을 포드에 마운트할지 여부를 제어합니다. 특정 사이드카가 제대로 작동해야 하는 경우(예: Istio)가 아니면 이를 활성화하면 안 됩니다. |
| `enabled`                      | 부울 | `false` | ServiceAccount를 사용할지 여부를 나타냅니다. |

### `tolerations` {#tolerations}

`tolerations`을 사용하면 오염된 워커 노드에 포드를 예약할 수 있습니다.

다음은 `tolerations`의 예제 사용입니다:

```yaml
tolerations:
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoExecute"
```

### `affinity` {#affinity}

`affinity`은 다음 중 하나 또는 모두를 설정할 수 있는 선택적 매개 변수입니다:

- `podAntiAffinity` 규칙:
  - `topology key`에 해당하는 식과 일치하는 포드와 동일한 도메인에 포드를 예약하지 않습니다.
  - `podAntiAffinity` 규칙의 두 가지 모드 설정: 필수(`requiredDuringSchedulingIgnoredDuringExecution`) 및 선호(`preferredDuringSchedulingIgnoredDuringExecution`). `values.yaml`에서 `antiAffinity` 변수를 사용하여 설정을 `soft`로 설정하면 선호 모드가 적용되거나 `hard`로 설정하면 필수 모드가 적용됩니다.
- `nodeAffinity` 규칙:
  - 특정 영역 또는 영역에 속하는 노드에 포드를 예약합니다.
  - `nodeAffinity` 규칙의 두 가지 모드 설정: 필수(`requiredDuringSchedulingIgnoredDuringExecution`) 및 선호(`preferredDuringSchedulingIgnoredDuringExecution`). `soft`로 설정하면 선호 모드가 적용됩니다. `hard`로 설정하면 필수 모드가 적용됩니다. 이 규칙은 `registry` 차트, `webservice` 및 `sidekiq`를 제외한 모든 서브 차트가 포함된 `gitlab` 차트에만 구현됩니다.

`nodeAffinity`은 [`In` 연산자](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#operators)만 구현합니다.

자세한 내용은 [관련 Kubernetes 설명서](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)를 참조하십시오.

다음 예제는 `affinity`를 설정하고 `nodeAffinity` 및 `antiAffinity`을 `hard`로 설정합니다:

```yaml
nodeAffinity: "hard"
antiAffinity: "hard"
affinity:
  nodeAffinity:
    key: "test.com/zone"
    values:
    - us-east1-a
    - us-east1-b
  podAntiAffinity:
    topologyKey: "test.com/hostname"
```

### `annotations` {#annotations}

`annotations`을 사용하면 레지스트리 포드에 주석을 추가할 수 있습니다.

다음은 `annotations`의 예제 사용입니다.

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## 서브 차트 활성화 {#enable-the-sub-chart}

우리가 선택한 구획화된 서브 차트 구현 방식에는 주어진 배포에서 원하지 않을 수 있는 구성 요소를 비활성화할 수 있는 기능이 포함됩니다. 이러한 이유로 결정해야 할 첫 번째 설정은 `enabled`입니다.

기본적으로 레지스트리는 기본적으로 활성화됩니다. 비활성화하려면 `enabled: false`를 설정하십시오.

## 응용 프로그램에 필요한 리소스 활성화 {#enable-resources-required-for-the-application}

Service, Deployment, HPA 및 PDB 리소스는 `registry.api.enabled` 값으로 활성화됩니다(기본값: `true`).

GitLab.com에서 이 설정이 어떻게 사용되는지에 대해 [GitLab.com의 컨테이너 레지스트리 배후 배포 마이그레이션](../../development/registry_post_deployment_migrations_on_gitlab_com.md)에서 자세히 알아보십시오.

## `image` 구성 {#configuring-the-image}

이 섹션에서는 이 서브 차트의 [Deployment](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/deployment.yaml)에서 사용하는 컨테이너 이미지의 설정에 대해 설명합니다. 레지스트리 및 `pullPolicy`의 포함된 버전을 변경할 수 있습니다.

기본 설정:

- `tag: 'v4.15.2-gitlab'`
- `pullPolicy: 'IfNotPresent'`

## `service` 구성 {#configuring-the-service}

이 섹션은 [Service](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/service.yaml)의 이름과 유형을 제어합니다. 이 설정은 [`values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/values.yaml)로 채워집니다.

기본적으로 Service는 다음과 같이 구성됩니다:

| 이름             |  유형  | 기본값     | 설명 |
|:-----------------|:------:|:------------|:------------|
| `name`           | 문자열 | `registry`  | 서비스의 이름을 구성합니다. |
| `type`           | 문자열 | `ClusterIP` | 서비스의 유형을 구성합니다. |
| `externalPort`   |  정수   | `5000`      | Service에서 노출하는 포트 |
| `internalPort`   |  정수   | `5000`      | 서비스에서 요청을 받기 위해 Pod에서 사용하는 포트 |
| `clusterIP`      | 문자열 | `null`      | 필요에 따라 사용자 지정 클러스터 IP를 구성할 수 있습니다. |
| `loadBalancerIP` | 문자열 | `null`      | 필요에 따라 사용자 지정 LoadBalancer IP 주소를 구성할 수 있습니다. |

## `ingress` 구성 {#configuring-the-ingress}

이 섹션은 레지스트리 Ingress를 제어합니다.

| 이름                   |  유형   | 기본값 | 설명 |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | 문자열  |         | `apiVersion` 필드에 사용할 값입니다. |
| `annotations`          | 문자열  |         | 이 필드는 [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)의 표준 `annotations`와 정확히 일치합니다. |
| `configureCertmanager` | 부울 |         | Ingress 주석 `cert-manager.io/issuer` 및 `acme.cert-manager.io/http01-edit-in-place`를 전환합니다. 자세한 내용은 [GitLab Pages의 TLS 요구 사항](../../installation/tls.md)을 참조하십시오. |
| `enabled`              | 부울 | `false` | 이를 지원하는 서비스에 대해 Ingress 객체를 만들지 여부를 제어하는 설정입니다. `false` 경우 `global.ingress.enabled` 설정이 사용됩니다. |
| `tls.enabled`          | 부울 | `true`  | `false`로 설정하면 레지스트리 서브 차트에 대해 TLS를 비활성화합니다. 이는 주로 `ingress-level`에서 TLS 종료를 사용할 수 없는 경우(예: Ingress Controller 앞에 TLS 종료 프록시가 있을 때) 유용합니다. |
| `tls.secretName`       | 문자열  |         | 레지스트리 URL에 대한 유효한 인증서와 키를 포함하는 Kubernetes TLS 시크릿의 이름입니다. 설정되지 않으면 `global.ingress.tls.secretName`이 대신 사용됩니다. 기본값은 설정되지 않습니다. |
| `tls.cipherSuites`     |  배열  | `[]`    | 컨테이너 레지스트리가 TLS 핸드셰이크 중에 클라이언트에 제시할 암호화 스위트 목록입니다. |

## TLS 구성 {#configuring-tls}

컨테이너 레지스트리는 `nginx-ingress`을 포함한 다른 구성 요소와의 통신을 보호하는 TLS를 지원합니다.

TLS를 구성하기 위한 필수 사항:

- TLS 인증서는 공통 이름(CN) 또는 주체 대체 이름(SAN)에 레지스트리 Service 호스트 이름(예: `RELEASE-registry.default.svc`)을 포함해야 합니다.
- TLS 인증서를 생성한 후:
  - [Kubernetes TLS 시크릿](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets) 만들기
  - `ca.crt` 키만 있는 TLS 인증서의 CA 인증서만 포함하는 다른 시크릿을 만듭니다.

TLS를 활성화하려면:

1. `registry.tls.enabled`을 `true`로 설정합니다.
1. `global.hosts.registry.protocol`을 `https`로 설정합니다.
1. 시크릿 이름을 `registry.tls.secretName` 및 `global.certificates.customCAs`에 전달합니다.

`registry.tls.verify`이 `true`일 때 CA 인증서 시크릿 이름을 `registry.tls.caSecretName`에 전달해야 합니다. 이는 자체 서명 인증서 및 사용자 지정 인증 기관에 필요합니다. 이 시크릿은 NGINX에서 레지스트리의 TLS 인증서를 확인하는 데 사용됩니다. [Gateway API](../../advanced/gateway-api/_index.md#tls-between-gateway-and-backend-services)를 사용하는 경우 Gateway API 컨트롤러는 항상 인증서를 확인합니다.

예를 들어:

```yaml
global:
  certificates:
    customCAs:
    - secret: registry-tls-ca
  hosts:
    registry:
      protocol: https

registry:
  tls:
    enabled: true
    secretName: registry-tls
    verify: true
    caSecretName: registry-tls-ca
```

### 컨테이너 레지스트리 암호화 스위트 {#container-registry-cipher-suites}

일반적으로 `tls.cipherSuites` 옵션은 레지스트리가 독립형 모드로 배포되고/또는 최신 암호화 스위트를 지원하지 않는 비표준 Ingress가 사용되는 매우 비정상적인 구성에서만 사용해야 합니다. 표준 GitLab 배포에서 NGINX Ingress는 현재 TLS1.3인 컨테이너 레지스트리 백엔드에서 지원하는 가장 높은 TLS 버전을 선택합니다. TLS1.3은 암호 구성을 허용하지 않으며 기본적으로 안전합니다. 어떤 이유로 TLS1.3을 사용할 수 없는 경우, 컨테이너 레지스트리에서 사용하는 기본 TLS1.2 암호화 목록도 NGINX Ingress 기본 설정과 호환되며 똑같이 안전합니다.

### 디버그 포트에 대해 TLS 구성 {#configuring-tls-for-the-debug-port}

레지스트리 디버그 포트도 TLS를 지원합니다. 디버그 포트는 Kubernetes 라이브니스 및 준비 상태 검사와 Prometheus에 대한 `/metrics` 끝점 노출에 사용됩니다(활성화된 경우).

`registry.debug.tls.enabled`를 `true`로 설정하여 TLS를 활성화할 수 있습니다. [Kubernetes TLS 시크릿](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)을 `registry.debug.tls.secretName`에 제공하여 디버그 포트의 TLS 구성에 사용할 수 있습니다. 전용 시크릿을 지정하지 않으면 디버그 구성이 레지스트리의 일반 TLS 구성과 `registry.tls.secretName` 공유로 대체됩니다.

Prometheus가 `/metrics/` 끝점을 `https`를 사용하여 스크래핑하려면 인증서의 CommonName 속성 또는 SubjectAlternativeName 항목에 대한 추가 구성이 필요합니다. 해당 요구 사항은 [TLS 지원 끝점을 스크래핑하도록 Prometheus 구성](../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints)을 참조하십시오.

## `networkpolicy` 구성 {#configuring-the-networkpolicy}

이 섹션은 레지스트리 [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)를 제어합니다. 이 구성은 선택 사항이며 레지스트리의 송출 및 인그레스를 특정 끝점으로 제한하는 데 사용됩니다. 및 특정 끝점으로 인그레스합니다.

| 이름              |  유형   | 기본값 | 설명 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | 부울 | `false` | 이 설정은 레지스트리에 대해 `NetworkPolicy`를 활성화합니다. |
| `ingress.enabled` | 부울 | `false` | `true`로 설정하면 `Ingress` 네트워크 정책이 활성화됩니다. 이는 규칙을 지정하지 않으면 모든 인그레스 연결을 차단합니다. |
| `ingress.rules`   |  배열  | `[]`    | 인그레스 정책 규칙으로 <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> 및 아래 예제를 참조하십시오. |
| `egress.enabled`  | 부울 | `false` | `true`로 설정하면 `Egress` 네트워크 정책이 활성화됩니다. 이는 규칙을 지정하지 않으면 모든 송출 연결을 차단합니다. |
| `egress.rules`    |  배열  | `[]`    | 송출 정책 규칙의 경우 <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> 및 아래 예제를 참조하십시오. |

### 모든 내부 끝점에 대한 연결을 방지하기 위한 예제 정책 {#example-policy-for-preventing-connections-to-all-internal-endpoints}

레지스트리 서비스는 일반적으로 개체 저장소로의 송출 연결, Docker 클라이언트의 인그레스 연결 및 DNS 조회를 위한 kube-dns가 필요합니다. 이는 레지스트리 서비스에 다음 네트워크 제한을 추가합니다:

- 인그레스 요청 허용:
  - 포드 `sidekiq`, `webservice` 및 `nginx-ingress`에서 포트 `5000`로
  - `Prometheus` 포드에서 포트 `9235`로
- 송출 요청 허용:
  - `kube-dns`에서 포트 `53`로
  - AWS VPC 끝점 S3 또는 STS `172.16.1.0/24`와 같은 끝점에서 포트 `443`로
  - 인터넷 `0.0.0.0/0`에서 포트 `443`로

_레지스트리 서비스에 끝점을 사용하지 않는 경우 [외부 개체 저장소](../../advanced/external-object-storage)의 이미지에 대해 공개 인터넷으로의 아웃바운드 연결이 필요합니다_

예제는 `kube-dns`이 `kube-system` 네임스페이스에 배포되었고 `prometheus`이 `monitoring` 네임스페이스에 배포되었으며 `nginx-ingress`이 `nginx-ingress` 네임스페이스에 배포되었다는 가정을 기반으로 합니다.

```yaml
networkpolicy:
  enabled: true
  ingress:
    enabled: true
    rules:
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 5000
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: monitoring
            podSelector:
              matchLabels:
                app: prometheus
                component: server
                release: gitlab
        ports:
          - port: 9235
      - from:
          - podSelector:
              matchLabels:
                app: sidekiq
        ports:
          - port: 5000
      - from:
          - podSelector:
              matchLabels:
                app: webservice
        ports:
          - port: 5000
  egress:
    enabled: true
    rules:
      - to:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: kube-system
            podSelector:
              matchLabels:
                k8s-app: kube-dns
        ports:
          - port: 53
            protocol: UDP
      - to:
          - ipBlock:
              cidr: 172.16.1.0/24
        ports:
          - port: 443
      - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
            - 10.0.0.0/8
```

## KEDA 구성 {#configuring-keda}

이 `keda` 섹션은 [KEDA](https://keda.sh/) `ScaledObjects`를 일반 `HorizontalPodAutoscalers` 대신 설치하도록 활성화합니다. 이 구성은 선택 사항이며 사용자 지정 또는 외부 메트릭을 기반으로 자동 확장이 필요한 경우에 사용할 수 있습니다.

대부분의 설정은 해당되는 경우 `hpa` 섹션에 설정된 값으로 기본값이 설정됩니다.

다음이 모두 참이면 CPU 및 메모리 트리거가 `hpa` 섹션에 설정된 CPU 및 메모리 임계값을 기반으로 자동으로 추가됩니다:

- `triggers`이 설정되지 않았습니다.
- 해당하는 `request.cpu.request` 또는 `request.memory.request` 설정도 0이 아닌 값으로 설정됩니다.

트리거가 설정되지 않으면 `ScaledObject`이 만들어지지 않습니다.

해당 설정에 대한 자세한 내용은 [KEDA 설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/)를 참조하십시오.

| 이름                            |  유형   | 기본값                         | 설명 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | 부울 | `false`                         | [KEDA](https://keda.sh/) `ScaledObjects`를 `HorizontalPodAutoscalers` 대신 사용 |
| `pollingInterval`               | 정수 | `30`                            | 각 트리거를 확인하는 간격 |
| `cooldownPeriod`                | 정수 | `300`                           | 마지막 트리거가 활성 상태로 보고된 후 리소스를 0으로 다시 확장하기 전에 대기할 기간 |
| `minReplicaCount`               | 정수 | `hpa.minReplicas`               | KEDA가 리소스를 축소할 최소 복제본 수입니다. |
| `maxReplicaCount`               | 정수 | `hpa.maxReplicas`               | KEDA가 리소스를 확장할 최대 복제본 수입니다. |
| `fallback`                      |   지도   |                                 | KEDA 폴백 구성을 위해 [설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)를 참조하십시오. |
| `hpaName`                       | 문자열  | `keda-hpa-{scaled-object-name}` | KEDA가 만들 HPA 리소스의 이름입니다. |
| `restoreToOriginalReplicaCount` | 부울 |                                 | `ScaledObject`가 삭제된 후 대상 리소스를 원래 복제본 수로 다시 확장할지 여부를 지정합니다. |
| `behavior`                      |   지도   | `hpa.behavior`                  | 상향 및 하향 확장 동작의 사양입니다. |
| `triggers`                      |  배열  |                                 | 대상 리소스의 확장을 활성화하기 위한 트리거 목록으로, `hpa.cpu` 및 `hpa.memory`에서 계산된 트리거로 기본값이 설정됩니다. |

### 모든 내부 끝점에 대한 연결을 방지하기 위한 예제 정책 {#example-policy-for-preventing-connections-to-all-internal-endpoints-1}

레지스트리 서비스는 일반적으로 개체 저장소로의 송출 연결, Docker 클라이언트의 인그레스 연결 및 DNS 조회를 위한 kube-dns가 필요합니다. 이는 레지스트리 서비스에 다음 네트워크 제한을 추가합니다:

- 로컬 네트워크에 대한 모든 송출 요청 `10.0.0.0/8` 포트 53이 허용됩니다(kubeDNS의 경우).
- 로컬 네트워크 `10.0.0.0/8`에 대한 다른 송출 요청은 제한됩니다.
- `10.0.0.0/8` 외부의 송출 요청이 허용됩니다.

_레지스트리 서비스에 [외부 개체 저장소](../../advanced/external-object-storage)의 이미지에 대해 공개 인터넷으로의 아웃바운드 연결이 필요합니다_

```yaml
networkpolicy:
  enabled: true
  egress:
    enabled: true
    # The following rules enable traffic to all external
    # endpoints, except the local
    # network (except DNS requests)
    rules:
      - to:
        - ipBlock:
            cidr: 10.0.0.0/8
        ports:
        - port: 53
          protocol: UDP
      - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
            - 10.0.0.0/8
```

## 레지스트리 구성 정의 {#defining-the-registry-configuration}

이 차트의 다음 속성은 기본 [레지스트리](https://hub.docker.com/_/registry/) 컨테이너 구성과 관련이 있습니다. GitLab과의 통합을 위해 가장 중요한 값만 노출됩니다. 이 통합의 경우 [Docker Distribution](https://github.com/docker/distribution)의 `auth.token.x` 설정을 사용하여 JWT [인증 토큰](https://distribution.github.io/distribution/spec/auth/token/)을 통해 레지스트리에 대한 인증을 제어합니다.

### `httpSecret` {#httpsecret}

필드 `httpSecret`는 `secret` 및 `key`의 두 항목을 포함하는 맵입니다.

이 키의 내용은 `http.secret` 값의 [registry](https://hub.docker.com/_/registry/)와 연관되어 있습니다. 이 값은 암호화된 난수 문자열로 채워져야 합니다.

`shared-secrets` 작업이 제공되지 않으면 이 시크릿을 자동으로 생성합니다. 이는 보안된 128자 영숫자 문자열로 base64로 인코딩되어 채워집니다.

이 시크릿을 수동으로 생성하려면:

```shell
kubectl create secret generic gitlab-registry-httpsecret --from-literal=secret=strongrandomstring
```

### 알림 시크릿 {#notification-secret}

알림 시크릿은 주요 및 보조 사이트 간의 컨테이너 레지스트리 데이터 동기화 관리를 위한 Geo를 포함하여 다양한 방식으로 GitLab 애플리케이션에 콜백하는 데 사용됩니다.

`notificationSecret` 시크릿 객체는 제공되지 않으면 `shared-secrets` 기능이 활성화될 때 자동으로 생성됩니다.

이 시크릿을 수동으로 생성하려면:

```shell
kubectl create secret generic gitlab-registry-notification --from-literal=secret=[\"strongrandomstring\"]
```

그런 다음 이 구성을 진행하여 `secret` 값이 위에서 생성한 시크릿 이름으로 설정되어 있는지 확인합니다.

```yaml
global:
  # To provide your own secret
  registry:
    notificationSecret:
        secret: gitlab-registry-notification
        key: secret
```

Geo를 활용하고 컨테이너 레지스트리를 복제하려면 다음 두 단계를 따르십시오:

1. 주요 사이트 구성에서:

   ```yaml
   global:
     # To provide your own secret, as described above
     registry:
       notificationSecret:
           secret: gitlab-registry-notification
           key: secret
     geo:
       registry:
         replication:
           enabled: true
   ```

1. 보조 사이트 구성에서:

   ```yaml
   global:
     geo:
       registry:
         replication:
           enabled: true
           primaryApiUrl: <URL to primary registry>
   ```

   `primaryApiUrl`은 보조 사이트에서 주요 사이트에 대한 풀 작업을 수행하는 데 사용됩니다.

### Redis 캐시 시크릿 {#redis-cache-secret}

Redis 캐시 시크릿은 `global.redis.auth.enabled`이 `true`로 설정되면 사용됩니다.

`shared-secrets` 기능이 활성화되면 `gitlab-redis-secret` 시크릿 객체가 제공되지 않으면 자동으로 생성됩니다.

이 시크릿을 수동으로 생성하려면 [Redis 암호 지침](../../installation/secrets.md#redis-password)을 참조하십시오.

### `authEndpoint` {#authendpoint}

`authEndpoint` 필드는 문자열로, [registry](https://hub.docker.com/_/registry/)가 인증할 GitLab 인스턴스의 URL을 제공합니다.

값에는 프로토콜과 호스트명만 포함되어야 합니다. 차트 템플릿이 필요한 요청 경로를 자동으로 추가합니다. 결과 값은 컨테이너 내 `auth.token.realm`에 채워집니다. 예: `authEndpoint: "https://gitlab.example.com"`

기본적으로 이 필드는 [전역 설정](../globals.md)에 의해 설정된 GitLab 호스트명 구성으로 채워집니다.

### `certificate` {#certificate}

`certificate` 필드는 `secret`와 `key`의 두 항목을 포함하는 맵입니다.

`secret`은 GitLab 인스턴스에서 생성한 토큰을 확인하는 데 사용할 인증서 번들을 보유한 [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/)의 이름을 포함하는 문자열입니다.

`key`은 `Secret`의 `key` 이름으로, [registry](https://hub.docker.com/_/registry/) 컨테이너에 `auth.token.rootcertbundle`로 제공할 인증서 번들을 보유합니다.

기본 예:

```yaml
certificate:
  secret: gitlab-registry
  key: registry-auth.crt
```

### 준비 상태 및 활성 상태 프로브 {#readiness-and-liveness-probe}

기본적으로 포트 `5001`에서 `/debug/health`을 확인하도록 구성된 준비 상태 및 활성 상태 프로브가 있습니다(이는 디버그 포트).

### `validation` {#validation}

`validation` 필드는 레지스트리의 Docker 이미지 유효성 검사 프로세스를 제어하는 맵입니다. 이미지 유효성 검사가 활성화되면 레지스트리는 Windows 이미지를 외부 레이어로 거부합니다. 단, `manifests.urls.allow` 필드가 유효성 검사 섹션 내에서 명시적으로 설정되어 있는 경우는 제외입니다. 이 필드는 이러한 레이어 URL을 허용하도록 설정됩니다.

유효성 검사는 매니페스트 푸시 중에만 발생하므로 레지스트리에 이미 있는 이미지는 이 섹션의 값 변경의 영향을 받지 않습니다.

이미지 유효성 검사는 기본적으로 비활성화됩니다.

이미지 유효성 검사를 활성화하려면 `registry.validation.disabled: false`을 명시적으로 설정해야 합니다.

#### `manifests` {#manifests}

`manifests` 필드는 매니페스트에 특정한 유효성 검사 정책의 구성을 허용합니다.

`urls` 섹션에는 `allow`와 `deny` 필드가 모두 포함됩니다. URL을 포함하는 매니페스트 레이어가 유효성 검사를 통과하려면 해당 레이어는 `allow` 필드의 정규식 중 하나와 일치해야 하며 `deny` 필드의 정규식과는 일치하지 않아야 합니다.

|        이름        | 유형  | 기본값 | 설명 |
|:------------------:|:-----:|:--------|:-----------:|
|  `referencelimit`  |  정수  | `0`     | 단일 매니페스트가 가질 수 있는 레이어, 이미지 구성 및 기타 매니페스트와 같은 참조의 최대 개수입니다. `0`로 설정되면(기본값) 이 유효성 검사는 비활성화됩니다. |
| `payloadsizelimit` |  정수  | `0`     | 매니페스트 페이로드의 최대 데이터 크기(바이트 단위)입니다. `0`로 설정되면(기본값) 이 유효성 검사는 비활성화됩니다. |
|    `urls.allow`    | 배열 | `[]`    | 매니페스트의 레이어에서 URL을 활성화하는 정규식 목록입니다. 비어 있으면(기본값) URL이 있는 레이어는 거부됩니다. |
|    `urls.deny`     | 배열 | `[]`    | 매니페스트의 레이어에서 URL을 제한하는 정규식 목록입니다. 비어 있으면(기본값) `urls.allow` 목록을 통과한 URL이 있는 레이어는 거부되지 않습니다. |

### `notifications` {#notifications}

`notifications` 필드는 [Registry 알림](https://distribution.github.io/distribution/about/notifications/#configuration)을 구성하는 데 사용됩니다. 기본값으로 빈 해시를 갖습니다.

|    이름     | 유형  | 기본값 | 설명 |
|:-----------:|:-----:|:--------|:-----------:|
| `endpoints` | 배열 | `[]`    | 각 항목이 [엔드포인트](https://distribution.github.io/distribution/about/configuration/#endpoints)에 해당하는 항목 목록 |
|  `events`   | 해시  | `{}`    | [이벤트](https://distribution.github.io/distribution/about/configuration/#events) 알림에 제공된 정보 |

예 설정은 다음과 같습니다:

```yaml
notifications:
  endpoints:
    - name: FooListener
      url: https://foolistener.com/event
      timeout: 500ms
      # DEPRECATED: use `maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243.
      # When using `maxretries`, `threshold` is ignored: https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#endpoints
      threshold: 10
      maxretries: 10
      backoff: 1s
    - name: BarListener
      url: https://barlistener.com/event
      timeout: 100ms
      # DEPRECATED: use `maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243.
      # When using `maxretries`, `threshold` is ignored: https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#endpoints
      threshold: 3
      maxretries: 5
      backoff: 1s
  events:
    includereferences: true
```

<!-- vale gitlab.Spelling = NO -->

### `hpa` {#hpa}

<!-- vale gitlab.Spelling = YES -->

`hpa` 필드는 객체로, 세트의 일부로 생성할 [registry](https://hub.docker.com/_/registry/) 인스턴스의 수를 제어합니다. 이는 `minReplicas` 값이 `2`, `maxReplicas` 값이 10이고 `cpu.targetAverageUtilization`을 75%로 구성하는 기본값으로 설정됩니다.

### `storage` {#storage}

```yaml
storage:
  secret:
  key: config
  extraKey:
```

`storage` 필드는 Kubernetes Secret 및 관련 키에 대한 참조입니다. 이 시크릿의 내용은 [Registry 구성: `storage`](https://distribution.github.io/distribution/about/configuration/#storage)에서 직접 가져옵니다. 자세한 내용은 해당 설명서를 참조하세요.

[AWS s3](https://distribution.github.io/distribution/storage-drivers/s3/) 및 [Google GCS](https://distribution.github.io/distribution/storage-drivers/gcs/) 드라이버의 예는 [`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)에서 찾을 수 있습니다:

- [`registry.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.s3.yaml)
- [`registry.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.gcs.yaml)

S3의 경우 [레지스트리 스토리지 권한](https://distribution.github.io/distribution/storage-drivers/s3/#s3-permission-scopes)을 올바르게 부여해야 합니다. 스토리지 구성에 대한 자세한 내용은 관리 설명서의 [컨테이너 레지스트리 스토리지 드라이버](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-storage-driver)를 참조하세요.

`storage` 블록의 _내용_을 시크릿에 배치하고 다음을 `storage` 맵의 항목으로 제공합니다:

- `secret`: YAML 블록을 보유하는 Kubernetes Secret의 이름입니다.
- `key`: 시크릿에서 사용할 키의 이름입니다. `config`로 기본값입니다.
- `extraKey`: _(선택사항)_ 시크릿의 추가 키 이름이며, 컨테이너 내 `/etc/docker/registry/storage/${extraKey}`로 마운트됩니다. 이는 `gcs` 드라이버에 `keyfile`을 제공하는 데 사용할 수 있습니다.

```shell
# Example using S3
kubectl create secret generic registry-storage \
    --from-file=config=registry-storage.yaml

# Example using GCS with JSON key
# - Note: `registry.storage.extraKey=gcs.json`
kubectl create secret generic registry-storage \
    --from-file=config=registry-storage.yaml \
    --from-file=gcs.json=example-project-382839-gcs-bucket.json
```

[스토리지 드라이버의 리디렉션을 비활성화](https://docs.gitlab.com/administration/packages/container_registry/#disable-redirect-for-storage-driver)하여 모든 트래픽이 다른 백엔드로 리디렉션되는 대신 Registry 서비스를 통해 흐르도록 할 수 있습니다:

```yaml
storage:
  secret: example-secret
  key: config
  redirect:
    disable: true
```

`filesystem` 드라이버를 사용하도록 선택한 경우:

- 이 데이터에 대한 영구 볼륨을 제공해야 합니다.
- [`hpa.minReplicas`](#hpa)을 `1`으로 설정해야 합니다.
- [`hpa.maxReplicas`](#hpa)을 `1`으로 설정해야 합니다.

복원력과 단순성을 위해 `s3`, `gcs`, `azure` 또는 기타 호환 가능한 객체 스토리지와 같은 외부 서비스를 사용하는 것이 좋습니다.

> [!note] 차트는 사용자가 지정하지 않으면 기본적으로 이 구성에 `delete.enabled: true`를 채웁니다. 이는 MinIO의 기본 사용 및 Linux 패키지와 일치하도록 예상된 동작을 유지합니다. 사용자가 제공한 모든 값이 이 기본값을 대체합니다.

### `middleware.storage` {#middlewarestorage}

`middleware.storage`의 구성은 [업스트림 규칙](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#middleware)을 따릅니다:

구성은 상당히 일반적이며 유사한 패턴을 따릅니다:

```yaml
middleware:
  # See https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#middleware
  storage:
    - name: cloudfront
      options:
        baseurl: https://abcdefghijklmn.cloudfront.net/
        # `privatekey` is auto-populated with the content from the privatekey Secret.
        privatekeySecret:
          secret: cloudfront-secret-name
          # "key" value is going to be used to generate filename for PEM storage:
          #   /etc/docker/registry/middleware.storage/<index>/<key>
          key: private-key-ABC.pem
        keypairid: ABCEDFGHIJKLMNOPQRST
```

위의 코드 내 `options.privatekeySecret`은 `generic` Kubernetes 시크릿로, 그 내용은 PEM 파일 내용에 해당합니다:

```shell
kubectl create secret generic cloudfront-secret-name --type=kubernetes.io/ssh-auth --from-file=private-key-ABC.pem=pk-ABCEDFGHIJKLMNOPQRST.pem
```

`privatekey` 업스트림에서 사용되는 것이 차트에서 `privatekey` 시크릿으로 자동으로 채워지며 지정된 경우 **ignored**됩니다.

#### `keypairid` 변형 {#keypairid-variants}

다양한 공급업체는 동일한 구성에 대해 다른 필드명을 사용합니다:

|   공급업체   | 필드명 |
|:----------:|:----------:|
| Google CDN | `keyname`  |
| CloudFront | `keypairid` |

> [!note] 현재는 `middleware.storage` 섹션의 구성만 지원됩니다.

### `debug` {#debug}

디버그 포트는 기본적으로 활성화되며 활성 상태/준비 상태 프로브에 사용됩니다. 또한 Prometheus 메트릭은 `metrics` 값을 통해 활성화할 수 있습니다.

```yaml
debug:
  addr:
    port: 5001

metrics:
  enabled: true
```

### `health` {#health}

`health` 속성은 선택사항이며 스토리지 드라이버의 백엔드 스토리지에 대한 정기적인 상태 확인에 대한 선호도를 포함합니다. 자세한 내용은 Docker [구성 설명서](https://distribution.github.io/distribution/about/configuration/#health)를 참조하세요.

```yaml
health:
  storagedriver:
    enabled: false
    interval: 10s
    threshold: 3
```

### `reporting` {#reporting}

`reporting` 속성은 선택사항이며 [보고](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#reporting)를 활성화합니다.

```yaml
reporting:
  sentry:
    enabled: true
    dsn: 'https://<key>@sentry.io/<project>'
    environment: 'production'
```

### `profiling` {#profiling}

`profiling` 속성은 선택사항이며 [연속 프로파일링](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#profiling)을 활성화합니다.

```yaml
profiling:
  stackdriver:
    enabled: true
    credentials:
      secret: gitlab-registry-profiling-creds
      key: credentials
    service: gitlab-registry
```

### `database` {#database}

{{< history >}}

- GitLab 16.4에서 [베타](https://docs.gitlab.com/policy/development_stages_support/#beta) 기능으로 [도입](https://gitlab.com/groups/gitlab-org/-/epics/5521)되었습니다.
- GitLab 17.3에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)합니다.

{{< /history >}}

`database` 속성은 선택사항이며 [메타데이터 데이터베이스](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#database)를 활성화합니다.

이 기능을 활성화하기 전에 [관리 설명서](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)를 참조하세요.

> [!note] 이 기능은 PostgreSQL 13 이상을 필요로 합니다.

```yaml
database:
  enabled: true
  host: registry.db.example.com
  port: 5432
  user: registry
  password:
    secret: gitlab-postgresql-password
    key: postgresql-registry-password
  dbname: registry
  sslmode: verify-full
  ssl:
    secret: gitlab-registry-postgresql-ssl
    clientKey: client-key.pem
    clientCertificate: client-cert.pem
    serverCA: server-ca.pem
  connecttimeout: 5s
  draintimeout: 2m
  preparedstatements: false
  primary: 'primary.record.fqdn'
  pool:
    maxidle: 25
    maxopen: 25
    maxlifetime: 5m
    maxidletime: 5m
  migrations:
    enabled: true
    activeDeadlineSeconds: 3600
    backoffLimit: 6
  backgroundMigrations:
    enabled: true
    maxJobRetries: 3
    jobInterval: 10s
```

#### 로드 밸런싱 {#load-balancing}

> [!warning] 이는 활발히 개발 중인 실험 기능이므로 프로덕션에서 사용할 수 없습니다.

`loadBalancing` 섹션은 [데이터베이스 로드 밸런싱](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#loadbalancing) 구성을 허용합니다. 이 기능을 작동하려면 해당 [Redis 연결](#redis-for-database-load-balancing)을 활성화해야 합니다.

#### 데이터베이스 관리 {#manage-the-database}

[컨테이너 레지스트리 메타데이터 데이터베이스](metadata_database.md) 페이지를 참조하여 데이터베이스 생성 및 유지 관리에 대한 자세한 정보를 얻으세요.

### `gc` 속성 {#gc-property}

`gc` 속성은 [온라인 가비지 컬렉션](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#gc) 옵션을 제공합니다.

온라인 가비지 컬렉션은 [메타데이터 데이터베이스](#database)를 활성화해야 합니다. 데이터베이스를 사용할 때 온라인 가비지 컬렉션을 사용해야 하지만 유지 관리 및 디버깅을 위해 온라인 가비지 컬렉션을 일시적으로 비활성화할 수 있습니다.

```yaml
gc:
  disabled: false
  maxbackoff: 24h
  noidlebackoff: false
  transactiontimeout: 10s
  reviewafter: 24h
  manifests:
    disabled: false
    interval: 5s
  blobs:
    disabled: false
    interval: 5s
    storagetimeout: 5s
```

### Redis 캐시 {#redis-cache}

> [!note] Redis 캐시는 버전 16.4 이상의 베타 기능입니다. 이 기능을 활성화하기 전에 [피드백 문제](https://gitlab.com/gitlab-org/gitlab/-/issues/423459) 및 관련 설명서를 검토하세요.

`redis.cache` 속성은 선택사항이며 [Redis 캐시](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#cache-1)와 관련된 옵션을 제공합니다. 레지스트리와 함께 `redis.cache`을 사용하려면 [메타데이터 데이터베이스](#database)를 활성화해야 합니다.

예를 들어:

```yaml
redis:
  cache:
    enabled: true
    host: localhost
    port: 16379
    password:
      secret: gitlab-redis-secret
      key: redis-password
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
    tls:
      enabled: true
      insecure: true
    pool:
      size: 10
      maxlifetime: 1h
      idletimeout: 300s
```

#### 클러스터 {#cluster}

`redis.cache.cluster` 속성은 Redis 클러스터에 연결할 호스트 및 포트 목록입니다. 예를 들어:

```yaml
redis:
  cache:
    enabled: true
    host: redis.example.com
    cluster:
      - host: host1.example.com
        port: 6379
      - host: host2.example.com
        port: 6379
```

#### 센티널 {#sentinels}

`redis.cache`은 `global.redis.sentinels` 구성을 사용할 수 있습니다. 로컬 값을 제공할 수 있으며 전역 값보다 우선 적용됩니다. 예를 들어:

```yaml
redis:
  cache:
    enabled: true
    host: redis.example.com
    sentinels:
      - host: sentinel1.example.com
        port: 16379
      - host: sentinel2.example.com
        port: 16379
```

#### 센티널 암호 지원 {#sentinel-password-support}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3805)되었습니다.

{{< /history >}}

`redis.cache`은 또한 Redis Sentinel에 대한 인증 암호를 사용하는 [`global.redis.sentinelAuth` 구성](../globals.md#redis-sentinel-password-support)을 사용할 수 있습니다. 로컬 값을 제공할 수 있으며 전역 값보다 우선 적용됩니다. 예를 들어:

```yaml
redis:
  cache:
    enabled: true
    host: redis.example.com
    sentinels:
      - host: sentinel1.example.com
        port: 16379
      - host: sentinel2.example.com
        port: 16379
    sentinelpassword:
      enabled: true
      secret: registry-redis-sentinel
      key: password
```

### Redis 속도 제한기 {#redis-rate-limiter}

> [!warning] Redis 속도 제한은 [개발 중](https://gitlab.com/groups/gitlab-org/-/epics/13237)입니다. 더 많은 기능 세부 정보가 사용 가능해지면 이 섹션에 추가될 것입니다.

`redis.rateLimiting` 속성은 선택사항이며 [Redis 속도 제한기](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#ratelimiter)와 관련된 옵션을 제공합니다.

예를 들어:

```yaml
redis:
  rateLimiting:
    enabled: true
    host: localhost
    port: 16379
    username: registry
    password:
      secret: gitlab-redis-secret
      key: redis-password
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
    tls:
      enabled: true
      insecure: true
    pool:
      size: 10
      maxlifetime: 1h
      idletimeout: 300s
```

### 데이터베이스 로드 밸런싱용 Redis {#redis-for-database-load-balancing}

{{< details >}}

상태:  실험

{{< /details >}}

{{< history >}}

- Charts 8.11에서 [도입](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4180)되었습니다.

{{< /history >}}

> [!warning] [데이터베이스 로드 밸런싱](#load-balancing)은 활발히 개발 중인 실험 기능이므로 프로덕션에서 사용할 수 없습니다. [에픽 8591](https://gitlab.com/groups/gitlab-org/-/epics/8591)을 사용하여 진행 상황을 추적하고 피드백을 공유하세요.

`redis.loadBalancing` 속성은 선택사항이며 [데이터베이스 로드 밸런싱을 위한 Redis 연결](https://gitlab.com/gitlab-org/container-registry/-/blob/b4d71f24a9ae31288401a3459228aa7f8d3dd8f0/docs/configuration.md#loadbalancing-1)과 관련된 옵션을 제공합니다.

예를 들어:

```yaml
redis:
  loadBalancing:
    enabled: true
    host: localhost
    port: 16379
    username: registry
    password:
      secret: gitlab-redis-secret
      key: redis-password
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
    tls:
      enabled: true
      insecure: true
    pool:
      size: 10
      maxlifetime: 1h
      idletimeout: 300s
```

## 가비지 컬렉션 {#garbage-collection}

Docker Registry는 시간이 지남에 따라 불필요한 데이터를 쌓아 [가비지 컬렉션](https://distribution.github.io/distribution/about/garbage-collection/)을 사용하여 해제할 수 있습니다. [현재](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1586) 기준으로 이 차트를 사용하여 가비지 컬렉션을 실행하는 완전히 자동화되거나 예약된 방법이 없습니다.

> [!warning] [메타데이터 데이터베이스](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#gc) 와 함께 [온라인 가비지 컬렉션](#database)을 사용해야 합니다. 메타데이터 데이터베이스와 함께 수동 가비지 컬렉션을 사용하면 데이터 손실이 발생합니다. 온라인 가비지 컬렉션은 수동으로 가비지 컬렉션을 실행할 필요를 완전히 대체합니다.

### 수동 가비지 컬렉션 {#manual-garbage-collection}

수동 가비지 컬렉션을 하려면 먼저 레지스트리를 읽기 전용 모드로 전환해야 합니다. Helm을 사용하여 GitLab 차트를 이미 설치했고 `mygitlab`이라고 명명했으며 네임스페이스 `gitlabns`에 설치했다고 가정합니다. 아래 명령의 이 값들을 실제 구성에 따라 바꿉니다.

```shell
# Because of https://github.com/helm/helm/issues/2948 we can't rely on --reuse-values, so let's get our current config.
helm get values mygitlab > mygitlab.yml
# Upgrade Helm installation and configure the registry to be read-only.
# The --wait parameter makes Helm wait until all ressources are in ready state, so we are safe to continue.
helm upgrade mygitlab gitlab/gitlab -f mygitlab.yml --set registry.maintenance.readonly.enabled=true --wait
# Our registry is in r/o mode now, so let's get the name of one of the registry Pods.
# Note down the Pod name and replace the '<registry-pod>' placeholder below with that value.
# Replace the single quotes to double quotes (' => ") if you are using this with Windows' cmd.exe.
kubectl get pods -n gitlabns -l app=registry -o jsonpath='{.items[0].metadata.name}'
# Run the actual garbage collection. Check the registry's manual if you really want the '-m' parameter.
kubectl exec -n gitlabns <registry-pod> -- /bin/registry garbage-collect -m /etc/docker/registry/config.yml
# Reset registry back to original state.
helm upgrade mygitlab gitlab/gitlab -f mygitlab.yml --wait
# All done :)
```

### 컨테이너 레지스트리에 대한 관리 명령 실행 {#running-administrative-commands-against-the-container-registry}

관리 명령은 `registry` 바이너리 및 필요한 구성을 모두 사용할 수 있는 Registry 포드에서만 컨테이너 레지스트리에 대해 실행할 수 있습니다. [Issue #2629](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2629)는 도구 상자 포드에서 이 기능을 제공하는 방법에 대해 논의하기 위해 열려 있습니다.

관리 명령을 실행하려면:

1. Registry 포드에 연결:

   ```shell
   kubectl exec -it <registry-pod> -- bash
   ```

1. Registry 포드 내부에서 `registry` 바이너리는 `PATH`에서 사용 가능하며 직접 사용할 수 있습니다. 구성 파일은 `/etc/docker/registry/config.yml`에서 사용 가능합니다. 다음 예는 데이터베이스 마이그레이션의 상태를 확인합니다:

   ```shell
   registry database migrate status /etc/docker/registry/config.yml
   ```

자세한 내용 및 기타 사용 가능한 명령은 관련 설명서를 참조하세요:

- [일반 Registry 설명서](https://docs.docker.com/registry/)
- [GitLab 특정 Registry 설명서](https://gitlab.com/gitlab-org/container-registry/-/tree/master/docs-gitlab)

## Registry 속도 제한기 구성 {#registry-rate-limiter-configuration}

Registry는 컨테이너 레지스트리 인스턴스로의 트래픽을 제어하기 위해 속도 제한으로 구성할 수 있습니다. 이는 레지스트리를 남용, DoS 공격 또는 과도한 사용으로부터 보호합니다.

### 참고 {#notes}

- 속도 제한을 하려면 Redis를 `registry.redis.rateLimiting` 설정을 통해 올바르게 구성해야 합니다.
- 속도 제한은 기본적으로 비활성화됩니다. `registry.rateLimiter.enabled: true`을 설정하여 활성화합니다.
- 제한 자가 우선 순위 순서대로 적용됩니다(가장 낮은 값이 먼저).
- `log_only` 옵션은 속도 제한을 적용하기 전에 테스트하는 데 유용할 수 있습니다.

### 속도 제한기 구성 {#rate-limiter-configuration}

컨테이너 레지스트리에 대해 속도 제한을 활성화하고 구성하려면 `registry.rateLimiter` 설정을 사용할 수 있습니다:

```yaml
registry:
  rateLimiter:
    enabled: true
    limiters:
      - name: global_rate_limit
        description: "Global IP rate limit"
        log_only: false
        match:
          type: IP
        precedence: 10
        limit:
          rate: 5000
          period: "minute"
          burst: 8000
        action:
          warn_threshold: 0.7
          warn_action: "log"
          hard_action: "block"
```

### 제한 자 구성 {#limiters-configuration}

속도 제한기는 속도 제한 규칙을 정의하는 제한기 목록을 사용합니다. 각 제한기에는 다음 속성이 있습니다:

- `name`: 제한기에 대한 고유 식별자
- `description`: 제한기의 목적에 대한 인간이 읽을 수 있는 설명
- `log_only`: `true`로 설정하면 위반만 적용 없이 로깅됩니다.
- `precedence`: 제한기를 평가하는 순서를 정의합니다(가장 낮은 값이 먼저).
- `match`: 요청 일치 기준
- `limit`: 속도 제한 매개변수
- `action`: 제한에 도달할 때 취할 작업

### 제한 구성 {#limit-configuration}

`limit` 섹션은 실제 속도 제한 매개변수를 정의합니다:

```yaml
limit:
  rate: 100       # Number of requests allowed
  period: "minute" # Time period (second, minute, hour, day)
  burst: 200      # Allowed burst capacity
```

### 작업 구성 {#action-configuration}

`action` 섹션은 제한에 접근하거나 도달할 때 발생하는 것을 정의합니다:

```yaml
action:
  warn_threshold: 0.7      # Percentage of limit to trigger warning
  warn_action: "log"       # Action when warning threshold is reached
  hard_action: "block"     # Action when limit is reached
```

### 예 {#examples}

#### 전역 IP 속도 제한 {#global-ip-rate-limit}

이 예는 단일 IP 주소의 모든 요청을 제한합니다:

```yaml
- name: global_rate_limit
  description: "Global IP rate limit"
  log_only: false
  match:
    type: IP
  precedence: 10
  limit:
    rate: 5000
    period: "minute"
    burst: 8000
  action:
    warn_threshold: 0.7
    warn_action: "log"
    hard_action: "block"
```
