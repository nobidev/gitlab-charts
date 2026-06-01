---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab-Gitaly 차트 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

`gitaly` 하위 차트는 Gitaly 서버의 구성 가능한 배포를 제공합니다.

## 요구 사항 {#requirements}

이 차트는 Workhorse 서비스에 대한 액세스에 따라 달라지며, 완전한 GitLab 차트의 일부이거나 이 차트가 배포되는 Kubernetes 클러스터에서 도달할 수 있는 외부 서비스로 제공될 수 있습니다.

## 설계 선택 사항 {#design-choices}

이 차트에서 사용되는 Gitaly 컨테이너에는 Gitaly로 아직 포팅되지 않은 Git 리포지토리에 대한 작업을 수행하기 위해 GitLab Shell 코드베이스도 포함되어 있습니다. Gitaly 컨테이너에는 GitLab Shell 컨테이너 사본이 포함되어 있으므로 이 차트 내에서 GitLab Shell을 구성해야 합니다.

## 구성 {#configuration}

`gitaly` 차트는 [외부 서비스](#external-services) 및 [차트 설정](#chart-settings)의 두 부분으로 구성됩니다.

Gitaly는 GitLab 차트를 배포할 때 기본적으로 구성 요소로 배포됩니다. Gitaly를 별도로 배포하는 경우 `global.gitaly.enabled`을(를) `false`(으)로 설정해야 하며, [외부 Gitaly 문서](../../../advanced/external-gitaly/_index.md)에 설명된 대로 추가 구성을 수행해야 합니다.

### 설치 명령줄 옵션 {#installation-command-line-options}

아래 표에는 `helm install` 명령에 `--set` 플래그를 사용하여 제공할 수 있는 모든 가능한 차트 구성이 포함되어 있습니다.

| 매개변수                                                | 기본값                                                 | 설명 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `annotations`                                            |                                                         | 포드 주석 |
| `backup.goCloudUrl`                                      |                                                         | [서버 측 Gitaly 백업](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)용 개체 저장소 URL입니다. |
| `common.labels`                                          | `{}`                                                    | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `podLabels`                                              |                                                         | 보충 포드 레이블입니다. 선택기에 사용되지 않습니다. |
| `external[].hostname`                                    | `- ""`                                                  | 외부 노드의 호스트 이름 |
| `external[].name`                                        | `- ""`                                                  | 외부 노드 스토리지의 이름 |
| `external[].port`                                        | `- ""`                                                  | 외부 노드의 포트 |
| `extraContainers`                                        |                                                         | 포함할 컨테이너 목록을 포함하는 여러 줄 리터럴 스타일 문자열 |
| `extraInitContainers`                                    |                                                         | 포함할 추가 init 컨테이너 목록 |
| `extraVolumeMounts`                                      |                                                         | 수행할 추가 볼륨 마운트 목록 |
| `extraVolumes`                                           |                                                         | 생성할 추가 볼륨 목록 |
| `extraEnv`                                               |                                                         | 노출할 추가 환경 변수 목록 |
| `extraEnvFrom`                                           |                                                         | 다른 데이터 소스에서 노출할 추가 환경 변수 목록 |
| `gitaly.serviceName`                                     |                                                         | 생성된 Gitaly 서비스의 이름입니다. `global.gitaly.serviceName`을(를) 재정의하고 `<RELEASE-NAME>-gitaly`(으)로 기본값으로 설정합니다. |
| `gpgSigning.enabled`                                     | `false`                                                 | [Gitaly GPG 서명](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)을(를) 사용해야 하는지 여부입니다. |
| `gpgSigning.secret`                                      |                                                         | Gitaly GPG 서명에 사용되는 암호의 이름입니다. |
| `gpgSigning.key`                                         |                                                         | Gitaly의 GPG 서명 키를 포함하는 GPG 암호의 키입니다. |
| `image.pullPolicy`                                       | `Always`                                                | Gitaly 이미지 풀 정책 |
| `image.pullSecrets`                                      |                                                         | 이미지 저장소의 비밀 |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitaly`       | Gitaly 이미지 리포지토리 |
| `image.tag`                                              | `master`                                                | Gitaly 이미지 태그 |
| `init.image.repository`                                  |                                                         | initContainer 이미지 |
| `init.image.tag`                                         |                                                         | initContainer 이미지 태그 |
| `init.containerSecurityContext`                          |                                                         | initContainer 특정 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                 | initContainer 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                  | initContainer 특정:  컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                             | initContainer 특정:  컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `internal.names[]`                                       | `- default`                                             | StatefulSet 스토리지의 순서가 지정된 이름 |
| `serviceLabels`                                          | `{}`                                                    | 보충 서비스 레이블 |
| `service.externalPort`                                   | `8075`                                                  | Gitaly 서비스 노출 포트 |
| `service.internalPort`                                   | `8075`                                                  | Gitaly 내부 포트 |
| `service.name`                                           | `gitaly`                                                | Gitaly가 Service 객체의 Service 포트 뒤에 있는 Service 포트의 이름입니다. |
| `service.type`                                           | `ClusterIP`                                             | Gitaly 서비스 유형 |
| `service.clusterIP`                                      | `None`                                                  | Service 생성 요청의 일부로 자신의 클러스터 IP 주소를 지정할 수 있습니다. 이는 Kubernetes의 Service 객체의 clusterIP와 동일한 규칙을 따릅니다. `service.type`(이)가 LoadBalancer인 경우 이를 설정하면 안 됩니다. |
| `service.loadBalancerIP`                                 |                                                         | 설정하지 않으면 임시 IP 주소가 생성됩니다. 이는 Kubernetes의 Service 객체의 loadbalancerIP 구성과 동일한 규칙을 따릅니다. |
| `serviceAccount.annotations`                             | `{}`                                                    | ServiceAccount 주석 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                 | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다 |
| `serviceAccount.create`                                  | `false`                                                 | ServiceAccount를 생성해야 하는지 여부를 나타냅니다 |
| `serviceAccount.enabled`                                 | `false`                                                 | ServiceAccount를 사용해야 하는지 여부를 나타냅니다 |
| `serviceAccount.name`                                    |                                                         | ServiceAccount의 이름입니다. 설정하지 않으면 전체 차트 이름이 사용됩니다 |
| `securityContext.fsGroup`                                | `1000`                                                  | 포드를 시작해야 하는 그룹 ID |
| `securityContext.fsGroupChangePolicy`                    |                                                         | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `securityContext.runAsUser`                              | `1000`                                                  | 포드를 시작해야 하는 사용자 ID |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                        | 사용할 Seccomp 프로필 |
| `shareProcessNamespace`                                  | `false`                                                 | 컨테이너 프로세스를 동일한 Pod의 다른 모든 컨테이너에 표시할 수 있습니다. |
| `containerSecurityContext`                               |                                                         | Gitaly 컨테이너가 시작되는 컨테이너 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) 재정의 |
| `containerSecurityContext.runAsUser`                     | `1000`                                                  | Gitaly 컨테이너가 시작되는 특정 보안 컨텍스트 사용자 ID의 덮어쓰기 허용 |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                 | Gitaly 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                  | Gitaly 컨테이너가 root가 아닌 사용자로 실행되는지 여부를 제어합니다. |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                             | Gitaly 컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `tolerations`                                            | `[]`                                                    | 포드 할당을 위한 용인 레이블 |
| `affinity`                                               | `{}`                                                    | 포드 할당을 위한 [선호도 규칙](../_index.md#affinity) |
| `persistence.accessMode`                                 | `ReadWriteOnce`                                         | Gitaly 지속성 액세스 모드 |
| `persistence.annotations`                                |                                                         | Gitaly 지속성 주석 |
| `persistence.enabled`                                    | `true`                                                  | Gitaly 지속성 활성화 플래그 |
| `persistance.labels`                                     |                                                         | Gitaly 지속성 레이블 |
| `persistence.matchExpressions`                           |                                                         | 바인딩할 레이블 표현식 일치 |
| `persistence.matchLabels`                                |                                                         | 바인딩할 레이블 값 일치 |
| `persistence.size`                                       | `50Gi`                                                  | Gitaly 지속성 볼륨 크기 |
| `persistence.storageClass`                               |                                                         | 프로비저닝을 위한 storageClassName |
| `persistence.subPath`                                    |                                                         | Gitaly 지속성 볼륨 탑재 경로 |
| `priorityClassName`                                      |                                                         | Gitaly StatefulSet priorityClassName |
| `logging.level`                                          |                                                         | 로그 수준   |
| `logging.format`                                         | `json`                                                  | 로그 형식  |
| `logging.sentryDsn`                                      |                                                         | Sentry DSN URL - Go 서버의 예외 |
| `logging.sentryEnvironment`                              |                                                         | 로깅에 사용할 Sentry 환경 |
| `shell.concurrency[]`                                    |                                                         | 각 RPC 엔드포인트의 동시성입니다. 구성 키에 대해 [RPC 동시성 제한](https://docs.gitlab.com/administration/gitaly/concurrency_limiting/#limit-rpc-concurrency) 및 [RPC 동시성 적응성 활성화](https://docs.gitlab.com/administration/gitaly/concurrency_limiting/#enable-adaptiveness-for-rpc-concurrency)를 참조하세요. |
| `packObjectsCache.enabled`                               | `false`                                                 | Gitaly pack-objects 캐시를 활성화합니다. |
| `packObjectsCache.dir`                                   | `/home/git/repositories/+gitaly/PackObjectsCache`       | 캐시 파일이 저장되는 디렉터리 |
| `packObjectsCache.max_age`                               | `5m`                                                    | 캐시 항목 수명 |
| `packObjectsCache.min_occurrences`                       | `1`                                                     | 캐시 항목을 생성하기 위해 필요한 최소 개수 |
| `git.catFileCacheSize`                                   |                                                         | Git cat-file 프로세스에서 사용하는 캐시 크기 |
| `git.config[]`                                           | `[]`                                                    | Gitaly가 Git 명령을 생성할 때 설정해야 하는 Git 구성 |
| `prometheus.grpcLatencyBuckets`                          |                                                         | Gitaly에서 기록할 GRPC 메서드 호출의 히스토그램 지연에 해당하는 버킷입니다. 배열의 문자열 형식(예: `"[1.0, 1.5, 2.0]"`)이 입력으로 필요합니다. |
| `statefulset.strategy`                                   | `{}`                                                    | StatefulSet에서 사용하는 업데이트 전략을 구성할 수 있습니다. |
| `statefulset.livenessProbe.initialDelaySeconds`          | `0`                                                     | 생동성 프로브가 시작되기 전의 지연입니다. startupProbe가 활성화된 경우 이는 0으로 설정됩니다. |
| `statefulset.livenessProbe.periodSeconds`                | `10`                                                    | 생동성 프로브를 수행하는 빈도 |
| `statefulset.livenessProbe.timeoutSeconds`               | `3`                                                     | 생동성 프로브 시간이 초과될 때 |
| `statefulset.livenessProbe.successThreshold`             | `1`                                                     | 생동성 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `statefulset.livenessProbe.failureThreshold`             | `3`                                                     | 생동성 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `statefulset.readinessProbe.initialDelaySeconds`         | `0`                                                     | 준비 프로브가 시작되기 전의 지연입니다. startupProbe가 활성화된 경우 이는 0으로 설정됩니다. |
| `statefulset.readinessProbe.periodSeconds`               | `5`                                                     | 준비 프로브를 수행하는 빈도 |
| `statefulset.readinessProbe.timeoutSeconds`              | `3`                                                     | 준비 프로브 시간이 초과될 때 |
| `statefulset.readinessProbe.successThreshold`            | `1`                                                     | 준비 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `statefulset.readinessProbe.failureThreshold`            | `3`                                                     | 준비 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `statefulset.startupProbe.enabled`                       | `true`                                                  | 시작 프로브가 활성화되었는지 여부입니다. |
| `statefulset.startupProbe.initialDelaySeconds`           | `1`                                                     | 시작 프로브가 시작되기 전의 지연 |
| `statefulset.startupProbe.periodSeconds`                 | `1`                                                     | 시작 프로브를 수행하는 빈도 |
| `statefulset.startupProbe.timeoutSeconds`                | `1`                                                     | 시작 프로브 시간이 초과될 때 |
| `statefulset.startupProbe.successThreshold`              | `1`                                                     | 시작 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `statefulset.startupProbe.failureThreshold`              | `60`                                                    | 시작 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `metrics.enabled`                                        | `false`                                                 | 메트릭 엔드포인트를 스크래핑할 수 있도록 해야 하는지 여부 |
| `metrics.port`                                           | `9236`                                                  | 메트릭 엔드포인트 포트 |
| `metrics.path`                                           | `/metrics`                                              | 메트릭 엔드포인트 경로 |
| `metrics.serviceMonitor.enabled`                         | `false`                                                 | Prometheus Operator가 메트릭 스크래핑을 관리하도록 ServiceMonitor를 생성해야 하는지 여부. 이를 활성화하면 `prometheus.io` 스크래핑 주석이 제거됩니다 |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                    | ServiceMonitor에 추가할 추가 레이블 |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                    | ServiceMonitor의 추가 엔드포인트 구성 |
| `metrics.metricsPort`                                    |                                                         | **DEPRECATED** `metrics.port` 사용 |
| `gomemlimit.enabled`                                     | `true`                                                  | 이는 Gitaly 컨테이너의 `GOMEMLIMIT` 환경 변수를 `resources.limits.memory`(으)로 자동으로 설정합니다(해당 제한도 설정된 경우). 이 값을 false로 설정하고 `GOMEMLIMIT`을(를) `extraEnv`에 설정하여 이 값을 재정의할 수 있습니다. 이는 [문서화된 형식 기준](https://pkg.go.dev/runtime#hdr-Environment_Variables)을(를) 충족해야 합니다. |
| `cgroups.enabled`                                        | `false`                                                 | Gitaly에는 기본 제공 cgroups 제어 기능이 있습니다. 구성된 경우 Gitaly는 Git 명령이 작동하는 리포지토리를 기반으로 Git 프로세스를 cgroup에 할당합니다. 이 매개변수는 리포지토리 cgroups를 활성화합니다. cgroups v2만 활성화된 경우 지원됩니다. |
| `cgroups.initContainer.image.repository`                 | `registry.com/gitlab-org/build/cng/gitaly-init-cgroups` | Gitaly 이미지 리포지토리 |
| `cgroups.initContainer.image.tag`                        | `master`                                                | Gitaly 이미지 태그 |
| `cgroups.initContainer.image.pullPolicy`                 | `IfNotPresent`                                          | Gitaly 이미지 풀 정책 |
| `cgroups.mountpoint`                                     | `/etc/gitlab-secrets/gitaly-pod-cgroup`                 | 부모 cgroup 디렉터리가 탑재되는 위치입니다. |
| `cgroups.hierarchyRoot`                                  | `gitaly`                                                | Gitaly가 그룹을 생성하는 부모 cgroup이며, Gitaly가 실행되는 사용자 및 그룹이 소유할 것으로 예상됩니다. |
| `cgroups.memoryBytes`                                    |                                                         | Gitaly가 생성하는 모든 Git 프로세스에 집합적으로 부과되는 총 메모리 제한입니다. 0은 제한이 없음을 의미합니다. |
| `cgroups.cpuShares`                                      |                                                         | Gitaly가 생성하는 모든 Git 프로세스에 집합적으로 부과되는 CPU 제한입니다. 0은 제한이 없음을 의미합니다. 최대값은 1024개의 공유이며, 이는 CPU의 100%를 나타냅니다. |
| `cgroups.cpuQuotaUs`                                     |                                                         | 이 할당 값을 초과하는 경우 cgroups의 프로세스를 조절하는 데 사용됩니다. cpuQuotaUs를 100ms로 설정하므로 1개 코어는 100000입니다. 0은 제한이 없음을 의미합니다. |
| `cgroups.repositories.count`                             |                                                         | cgroups 풀의 cgroups 수입니다. 새로운 Git 명령이 생성될 때마다 Gitaly는 명령이 실행되는 리포지토리를 기반으로 이러한 cgroups 중 하나에 할당합니다. 순환 해싱 알고리즘은 Git 명령을 이러한 cgroups에 할당하므로 리포지토리에 대한 Git 명령은 항상 동일한 cgroup에 할당됩니다. |
| `cgroups.repositories.memoryBytes`                       |                                                         | 리포지토리 cgroup에 포함된 모든 Git 프로세스에 부과되는 총 메모리 제한입니다. 0은 제한이 없음을 의미합니다. 이 값은 최상위 memoryBytes를 초과할 수 없습니다. |
| `cgroups.repositories.cpuShares`                         |                                                         | 리포지토리 cgroup에 포함된 모든 Git 프로세스에 부과되는 CPU 제한입니다. 0은 제한이 없음을 의미합니다. 최대값은 1024개의 공유이며, 이는 CPU의 100%를 나타냅니다. 이 값은 최상위 cpuShares를 초과할 수 없습니다. |
| `cgroups.repositories.cpuQuotaUs`                        |                                                         | 리포지토리 cgroup에 포함된 모든 Git 프로세스에 부과되는 cpuQuotaUs입니다. Git 프로세스는 주어진 할당량보다 더 많이 사용할 수 없습니다. cpuQuotaUs를 100ms로 설정하므로 1개 코어는 100000입니다. 0은 제한이 없음을 의미합니다. |
| `cgroups.repositories.maxCgroupsPerRepo`                 | `1`                                                     | 특정 리포지토리를 대상으로 하는 Git 프로세스를 분산할 수 있는 리포지토리 cgroups의 수입니다. 이를 통해 리포지토리 cgroups에 대해 더 보수적인 CPU 및 메모리 제한을 구성할 수 있으며 여전히 버스트 워크로드를 허용합니다. 예를 들어 `maxCgroupsPerRepo`(이)가 `2`이고 `memoryBytes` 제한이 10GB인 경우 특정 리포지토리에 대한 독립적인 Git 작업은 최대 20GB의 메모리를 소비할 수 있습니다. |
| `gracefulRestartTimeout`                                 | `25`                                                    | Gitaly 종료 유예 기간, 진행 중인 요청이 완료될 때까지 기다리는 시간(초)입니다. Pod `terminationGracePeriodSeconds`이(가) 이 값 + 5초로 설정됩니다. |
| `timeout.uploadPackNegotiation`                          |                                                         | [협상 시간 초과 구성](https://docs.gitlab.com/administration/settings/gitaly_timeouts/#configure-the-negotiation-timeouts)을 참조하세요. |
| `timeout.uploadArchiveNegotiation`                       |                                                         | [협상 시간 초과 구성](https://docs.gitlab.com/administration/settings/gitaly_timeouts/#configure-the-negotiation-timeouts)을 참조하세요. |
| `dailyMaintenance.disabled`                              |                                                         | 일일 백그라운드 유지 관리를 비활성화할 수 있습니다. |
| `dailyMaintenance.duration`                              |                                                         | 일일 백그라운드 유지 관리의 최대 기간입니다. 예를 들어 "1h" 또는 "45m"입니다. |
| `dailyMaintenance.startHour`                             |                                                         | 일일 백그라운드 유지 관리의 시작 분입니다. |
| `dailyMaintenance.startMinute`                           |                                                         | 일일 백그라운드 유지 관리의 시작 분입니다. |
| `dailyMaintenance.storages`                              |                                                         | 일일 백그라운드 유지 관리를 수행할 스토리지 이름의 배열입니다. 예를 들어 [ "default" ]입니다. |
| `bundleUri.goCloudUrl`                                   |                                                         | [Bundle URI 문서](https://docs.gitlab.com/administration/gitaly/bundle_uris/)를 참조하세요. |

## 차트 구성 예시 {#chart-configuration-examples}

### extraEnv {#extraenv}

`extraEnv`을(를) 통해 Pod의 모든 컨테이너에서 추가 환경 변수를 노출할 수 있습니다.

다음은 `extraEnv`의 예시 사용입니다:

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

컨테이너가 시작되면 환경 변수가 노출되는지 확인할 수 있습니다:

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`을(를) 사용하면 포드의 모든 컨테이너에서 다른 데이터 소스의 추가 환경 변수를 노출할 수 있습니다.

다음은 `extraEnvFrom`의 예시 사용입니다:

```yaml
extraEnvFrom:
  MY_NODE_NAME:
    fieldRef:
      fieldPath: spec.nodeName
  MY_CPU_REQUEST:
    resourceFieldRef:
      containerName: test-container
      resource: requests.cpu
  SECRET_THING:
    secretKeyRef:
      name: special-secret
      key: special_token
      # optional: boolean
  CONFIG_STRING:
    configMapKeyRef:
      name: useful-config
      key: some-string
      # optional: boolean
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets`을(를) 사용하면 개인 레지스트리에 인증하여 포드의 이미지를 가져올 수 있습니다.

비공개 레지스트리 및 해당 인증 방법에 대한 추가 정보는 [Kubernetes 문서](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)에서 찾을 수 있습니다.

다음은 `pullSecrets`의 사용 예입니다.

```yaml
image:
  repository: my.gitaly.repository
  tag: latest
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

이 섹션에서는 ServiceAccount를 생성해야 하는지 여부와 기본 액세스 토큰을 Pod에 마운트해야 하는지 여부를 제어합니다.

| 이름                           |  유형   | 기본값 | 설명 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   맵   | `{}`    | ServiceAccount 주석. |
| `automountServiceAccountToken` | 부울 | `false` | 기본 ServiceAccount 액세스 토큰이 Pod에 마운트되어야 하는지 여부를 제어합니다. 특정 사이드카가 제대로 작동하도록 필요한 경우가 아니면(예: Istio) 이를 활성화하지 않아야 합니다. |
| `create`                       | 부울 | `false` | ServiceAccount를 생성해야 하는지 여부를 나타냅니다. |
| `enabled`                      | 부울 | `false` | ServiceAccount를 사용해야 하는지 여부를 나타냅니다. |
| `name`                         | 문자열  |         | ServiceAccount의 이름입니다. 설정하지 않은 경우 전체 차트 이름이 사용됩니다. |

### tolerations {#tolerations}

`tolerations`을(를) 사용하면 오염된 워커 노드에 Pod를 스케줄할 수 있습니다.

다음은 `tolerations`의 예시 사용입니다:

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

### affinity {#affinity}

자세한 내용은 [`affinity`](../_index.md#affinity)를 참조하세요.

### 주석 {#annotations}

`annotations`을(를) 통해 Gitaly Pod에 주석을 추가할 수 있습니다.

다음은 `annotations`의 예시 사용입니다:

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### priorityClassName {#priorityclassname}

`priorityClassName`을(를) 통해 Gitaly Pod에 [PriorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)를 할당할 수 있습니다.

다음은 `priorityClassName`의 예시 사용입니다:

```yaml
priorityClassName: persistence-enabled
```

### `git.config` {#gitconfig}

`git.config`을(를) 통해 Gitaly에서 생성한 모든 Git 명령에 구성을 추가할 수 있습니다. `git-config(1)`에 문서화된 구성을 허용하며 아래와 같이 `key` / `value` 쌍으로 표시됩니다.

```yaml
git:
  config:
    - key: "pack.threads"
      value: 4
    - key: "fsck.missingSpaceBeforeDate"
      value: ignore
```

### cgroups {#cgroups}

소진을 방지하기 위해 Gitaly는 **cgroups**를 사용하여 Git 프로세스를 작동 중인 리포지토리를 기반으로 cgroup에 할당합니다. 각 cgroup에는 메모리 및 CPU 제한이 있어 시스템 안정성을 보장하고 리소스 포화를 방지합니다.

Gitaly가 시작되기 전에 실행되는 `initContainer`은(는) **executed as root**되어야 합니다. 이 컨테이너는 Gitaly가 cgroups를 관리할 수 있도록 권한을 구성합니다. 따라서 `/sys/fs/cgroup`에 쓰기 액세스 권한을 가지기 위해 파일 시스템에 볼륨을 탑재합니다.

[과도한 가입의 예](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configuring-oversubscription)

```yaml
cgroups:
  enabled: true
  # Total limit across all repository cgroups
  memoryBytes: 64424509440 # 60GiB
  cpuShares: 1024
  cpuQuotaUs: 1200000 # 12 cores
  # Per repository limits, 1000 repository cgroups
  repositories:
    count: 1000
    memoryBytes: 32212254720 # 30GiB
    cpuShares: 512
    cpuQuotaUs: 400000 # 4 cores
```

## 외부 서비스 {#external-services}

이 차트는 Workhorse 서비스에 연결되어야 합니다.

### Workhorse {#workhorse}

```yaml
workhorse:
  host: workhorse.example.com
  serviceName: webservice
  port: 8181
```

| 이름          |  유형   | 기본값      | 설명 |
|:--------------|:-------:|:-------------|:------------|
| `host`        | 문자열  |              | Workhorse 서버의 호스트 이름입니다. 이를 `serviceName` 대신 생략할 수 있습니다. |
| `port`        | 정수 | `8181`       | Workhorse 서버에 연결할 포트입니다. |
| `serviceName` | 문자열  | `webservice` | Workhorse 서버를 운영하는 `service`의 이름입니다. 이것이 존재하고 `host`이(가) 없으면 차트가 서비스 호스트 이름 및 현재 `.Release.Name`을(를) `host` 값 대신 템플릿화합니다. 이는 Workhorse를 전체 GitLab 차트의 일부로 사용할 때 편리합니다. |

## 차트 설정 {#chart-settings}

다음 값은 Gitaly Pod을 구성하는 데 사용됩니다.

> [!note]
> Gitaly는 Auth Token을 사용하여 Workhorse 및 Sidekiq 서비스로 인증합니다. Auth Token 암호 및 키는 `global.gitaly.authToken` 값에서 가져옵니다. 또한 Gitaly 컨테이너에는 GitLab Shell의 사본이 있으며 설정할 수 있는 구성이 있습니다. Shell authToken은 `global.shell.authToken` 값에서 가져옵니다.

### Git 리포지토리 지속성 {#git-repository-persistence}

이 차트는 PersistentVolumeClaim을 프로비저닝하고 Git 리포지토리 데이터에 대한 해당 지속성 볼륨을 탑재합니다. 이것이 작동하려면 Kubernetes 클러스터에서 물리적 스토리지를 사용할 수 있어야 합니다. emptyDir를 사용하려면 `persistence.enabled: false`으로 PersistentVolumeClaim을 비활성화하십시오.

Gitaly의 지속성 설정은 모든 Gitaly Pod에 유효해야 하는 volumeClaimTemplate에서 사용됩니다. 특정 볼륨(예: `volumeName`)을 참조하기 위한 설정을 포함하면 *안 됩니다.* 특정 볼륨을 참조하려면 PersistentVolumeClaim을 수동으로 생성해야 합니다.

배포한 후에는 이러한 설정을 변경할 수 없습니다. [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)에서 `VolumeClaimTemplate`은(는) 변경할 수 없습니다.

```yaml
persistence:
  enabled: true
  storageClass: standard
  accessMode: ReadWriteOnce
  size: 50Gi
  matchLabels: {}
  matchExpressions: []
  subPath: "data"
  annotations: {}
```

| 이름               |  유형   | 기본값         | 설명 |
|:-------------------|:-------:|:----------------|:------------|
| `accessMode`       | 문자열  | `ReadWriteOnce` | PersistentVolumeClaim에서 요청한 accessMode를 설정합니다. 자세한 내용은 [Kubernetes Access Modes Documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)을(를) 참조하세요. |
| `enabled`          | 부울 | `true`          | 리포지토리 데이터에 PersistentVolumeClaims를 사용할지 여부를 설정합니다. `false`인 경우 emptyDir 볼륨이 사용됩니다. |
| `matchExpressions` |  배열  |                 | 바인드할 볼륨을 선택할 때 일치시킬 레이블 조건 객체의 배열을 허용합니다. 이는 `PersistentVolumeClaim` `selector` 섹션에서 사용됩니다. [볼륨 설명서](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)를 참조하세요. |
| `matchLabels`      |   맵   |                 | 바인드할 볼륨을 선택할 때 일치시킬 레이블 이름과 레이블 값의 맵을 허용합니다. 이는 `PersistentVolumeClaim` `selector` 섹션에서 사용됩니다. [볼륨 설명서](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)를 참조하세요. |
| `size`             | 문자열  | `50Gi`          | 데이터 지속성에 대해 요청할 최소 볼륨 크기입니다. |
| `storageClass`     | 문자열  |                 | 동적 프로비저닝을 위해 Volume Claim에서 storageClassName을 설정합니다. 설정하지 않거나 null인 경우 기본 프로비저너가 사용됩니다. 하이픈으로 설정하면 동적 프로비저닝이 비활성화됩니다. |
| `subPath`          | 문자열  |                 | 볼륨의 루트 대신 탑재할 볼륨 내의 경로를 설정합니다. subPath가 비어 있으면 루트가 사용됩니다. |
| `annotations`      |   맵   |                 | 동적 프로비저닝을 위해 Volume Claim에서 주석을 설정합니다. 자세한 내용은 [Kubernetes 주석 문서](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)를 참조하세요. |

### TLS을 통해 Gitaly 실행 {#running-gitaly-over-tls}

> [!note]
> 이 섹션은 Helm 차트를 사용하여 클러스터 내부에서 Gitaly가 실행되는 것을 말합니다. 외부 Gitaly 인스턴스를 사용하고 있고 TLS를 사용하여 이와 통신하려는 경우 [외부 Gitaly 문서](../../../advanced/external-gitaly/_index.md#connecting-to-external-gitaly-over-tls)를 참조하세요.

Gitaly는 TLS를 통해 다른 구성 요소와 통신하도록 지원합니다. 이는 설정 `global.gitaly.tls.enabled` 및 `global.gitaly.tls.secretName`에 의해 제어됩니다. TLS를 통해 Gitaly를 실행하는 단계를 따릅니다:

1. Helm 차트는 Gitaly와 TLS를 통해 통신하기 위해 제공할 인증서를 예상합니다. 이 인증서는 존재하는 모든 Gitaly 노드에 적용되어야 합니다. 따라서 이러한 각 Gitaly 노드의 모든 호스트 이름을 Subject Alternate Name (SAN)으로 인증서에 추가해야 합니다.

   사용할 호스트 이름을 알아보려면 Toolbox Pod의 `/srv/gitlab/config/gitlab.yml` 파일을 확인하고 `repositories.storages` 키 아래에 지정된 다양한 `gitaly_address` 필드를 확인하세요.

   ```shell
   kubectl exec -it <Toolbox pod> -- grep gitaly_address /srv/gitlab/config/gitlab.yml
   ```

내부 Gitaly Pod용 사용자 지정 서명 인증서를 생성하는 기본 스크립트는 [이 리포지토리에서 찾을 수 있습니다](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/generate_certificates.sh). 적절한 SAN 속성을 사용하여 인증서를 생성하기 위해 해당 스크립트를 사용하거나 참조할 수 있습니다.

1. 생성된 인증서를 사용하여 k8s TLS 암호를 생성합니다.

   ```shell
   kubectl create secret tls gitaly-server-tls --cert=gitaly.crt --key=gitaly.key
   ```

1. `--set global.gitaly.tls.enabled=true`을(를) 전달하여 Helm 차트를 다시 배포합니다.

### 글로벌 서버 후크 {#global-server-hooks}

Gitaly StatefulSet은 [글로벌 서버 후크](https://docs.gitlab.com/administration/server_hooks/#create-a-global-server-hook-for-all-repositories)를 지원합니다. 후크 스크립트는 Gitaly Pod에서 실행되며, [Gitaly 컨테이너](https://gitlab.com/gitlab-org/build/CNG/-/blob/master/gitaly/Dockerfile)에서 사용 가능한 도구로 제한됩니다.

후크는 [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)을(를) 사용하여 채워지며 다음 값을 적절하게 설정하여 사용할 수 있습니다:

1. `global.gitaly.hooks.preReceive.configmap`
1. `global.gitaly.hooks.postReceive.configmap`
1. `global.gitaly.hooks.update.configmap`

ConfigMap을 채우기 위해 `kubectl`을(를) 스크립트 디렉터리로 지정할 수 있습니다:

```shell
kubectl create configmap MAP_NAME --from-file /PATH/TO/SCRIPT/DIR
```

### GitLab에서 생성한 GPG 서명 커밋 {#gpg-signing-commits-created-by-gitlab}

Gitaly는 GitLab UI(예: WebIDE)를 통해 생성된 커밋뿐만 아니라 GitLab에서 생성한 커밋(예: 병합 커밋 및 스쿼시)에 [GPG 서명할 수 있습니다](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits).

1. GPG 개인 키를 사용하여 k8s 암호를 생성합니다.

   ```shell
   kubectl create secret generic gitaly-gpg-signing-key --from-file=signing_key=/path/to/gpg_signing_key.gpg
   ```

1. `values.yaml`에서 GPG 서명을 활성화합니다.

   ```yaml
   gitlab:
     gitaly:
       gpgSigning:
         enabled: true
         secret: gitaly-gpg-signing-key
         key: signing_key
   ```

### 서버 측 백업 {#server-side-backups}

차트는 [Gitaly 서버 측 백업](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)을(를) 지원합니다. 이를 사용하려면:

1. 백업을 저장할 버킷을 생성합니다.
1. 개체 저장소 자격 증명 및 저장소 URL을 구성합니다.

   ```yaml
   gitlab:
     gitaly:
       extraEnvFrom:
          # Mount the exisitign object store secret to the expected environment variables.
          AWS_ACCESS_KEY_ID:
            secretKeyRef:
              name: <Rails object store secret>
              key: aws_access_key_id
          AWS_SECRET_ACCESS_KEY:
            secretKeyRef:
              name: <Rails object store secret>
              key: aws_secret_access_key
       backup:
         # This is the connection string for Gitaly server side backups.
         goCloudUrl: <object store connection URL>
   ```

   개체 저장소 백엔드에 대한 예상 환경 변수 및 저장소 URL 형식에 대해 [Gitaly 문서](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)를 참조하세요.

1. [`backup-utility`을(를) 사용하여 서버 측 백업을 활성화합니다](../../../backup-restore/backup.md#server-side-repository-backups).
