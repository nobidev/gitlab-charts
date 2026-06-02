---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Webservice 차트 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

`webservice` 서브차트는 GitLab Rails 웹서버에 포드당 2개의 Webservice 워커를 제공하며, 이는 단일 포드가 GitLab의 모든 웹 요청을 처리할 수 있기 위한 최소 필수 요구사항입니다.

이 차트의 포드는 `gitlab-workhorse`와 `webservice` 두 개의 컨테이너를 사용합니다. [GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab/-/tree/master/workhorse)는 포트 `8181`에서 수신 대기하며, 포드로의 인바운드 트래픽의 대상이 _항상_ 되어야 합니다. `webservice`는 GitLab [Rails 코드베이스](https://gitlab.com/gitlab-org/gitlab)를 포함하고, `8080`에서 수신 대기하며, 메트릭 수집 목적으로 접근 가능합니다. `webservice`는 직접 정상 트래픽을 받아서는 안 됩니다.

## 요구 사항 {#requirements}

이 차트는 Redis, PostgreSQL, Gitaly 및 Registry 서비스에 따라 달라지며, 이는 완전한 GitLab 차트의 일부이거나 이 차트가 배포된 Kubernetes 클러스터에서 도달 가능한 외부 서비스로 제공될 수 있습니다.

## 구성 {#configuration}

`webservice` 차트는 다음과 같이 구성됩니다:  [전역 설정](#global-settings) , [배포 설정](#deployments-settings) , [Ingress 설정](#ingress-settings) , [외부 서비스](#external-services) 및 [차트 설정](#chart-settings).

## 설치 명령줄 옵션 {#installation-command-line-options}

다음 표에는 `helm install` 명령을 사용하여 제공할 수 있는 모든 가능한 차트 구성이 포함되어 있으며, `--set` 플래그를 사용합니다.

| 매개변수                                                     | 기본값                                                         | 설명 |
|---------------------------------------------------------------|-----------------------------------------------------------------|-------------|
| `annotations`                                                 |                                                                 | 포드 주석 |
| `podLabels`                                                   |                                                                 | 보충 포드 레이블입니다. 선택기에 사용되지 않습니다. |
| `common.labels`                                               |                                                                 | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `deployment.terminationGracePeriodSeconds`                    | `30`                                                            | Kubernetes가 포드 종료를 기다릴 시간(초)입니다. 이는 `shutdown.blackoutSeconds`보다 길어야 합니다. |
| `deployment.livenessProbe.initialDelaySeconds`                | `20`                                                            | 생동성 프로브가 시작되기 전의 지연 |
| `deployment.livenessProbe.periodSeconds`                      | `60`                                                            | 생동성 프로브를 수행하는 빈도 |
| `deployment.livenessProbe.timeoutSeconds`                     | `30`                                                            | 생동성 프로브 시간이 초과될 때 |
| `deployment.livenessProbe.successThreshold`                   | `1`                                                             | 생동성 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `deployment.livenessProbe.failureThreshold`                   | `3`                                                             | 생동성 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `deployment.readinessProbe.initialDelaySeconds`               | `0`                                                             | 준비 프로브가 시작되기 전의 지연 |
| `deployment.readinessProbe.periodSeconds`                     | `10`                                                            | 준비 프로브를 수행하는 빈도 |
| `deployment.readinessProbe.timeoutSeconds`                    | `2`                                                             | 준비 프로브 시간이 초과될 때 |
| `deployment.readinessProbe.successThreshold`                  | `1`                                                             | 준비 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `deployment.readinessProbe.failureThreshold`                  | `3`                                                             | 준비 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `deployment.strategy`                                         | `{}`                                                            | 배포에서 사용하는 업데이트 전략을 구성하도록 허용합니다. 제공되지 않으면 클러스터 기본값이 사용됩니다. |
| `enabled`                                                     | `true`                                                          | Webservice 활성화 플래그 |
| `extraContainers`                                             |                                                                 | 포함할 컨테이너 목록을 포함하는 여러 줄 리터럴 스타일 문자열 |
| `extraInitContainers`                                         |                                                                 | 포함할 추가 init 컨테이너 목록 |
| `extras.google_analytics_id`                                  | `nil`                                                           | 프론트엔드용 Google Analytics ID |
| `extraVolumeMounts`                                           |                                                                 | 수행할 추가 볼륨 마운트 목록 |
| `extraVolumes`                                                |                                                                 | 생성할 추가 볼륨 목록 |
| `extraEnv`                                                    |                                                                 | 노출할 추가 환경 변수 목록 |
| `extraEnvFrom`                                                |                                                                 | 다른 데이터 소스에서 노출할 추가 환경 변수 목록 |
| `gitlab.webservice.workhorse.image`                           | `registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ee`  | Workhorse 이미지 저장소 |
| `gitlab.webservice.workhorse.tag`                             |                                                                 | Workhorse 이미지 태그 |
| `hpa.behavior`                                                | `{scaleDown: {stabilizationWindowSeconds: 300 }}`               | 동작은 상향 및 하향 스케일링 동작의 사양을 포함합니다(`autoscaling/v2beta2` 이상 필요). |
| `hpa.customMetrics`                                           | `[]`                                                            | 사용자 정의 메트릭은 원하는 복제본 수를 계산하는 데 사용할 사양을 포함합니다(`targetAverageUtilization`에 구성된 평균 CPU 활용률의 기본 사용을 재정의함). |
| `hpa.cpu.targetType`                                          | `AverageValue`                                                  | 자동 스케일링 CPU 대상 유형을 설정하고, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.cpu.targetAverageValue`                                  | `1`                                                             | 자동 스케일링 CPU 대상 값을 설정합니다 |
| `hpa.cpu.targetAverageUtilization`                            |                                                                 | 자동 스케일링 CPU 대상 활용률을 설정합니다 |
| `hpa.memory.targetType`                                       |                                                                 | 자동 스케일링 메모리 대상 유형을 설정하고, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.memory.targetAverageValue`                               |                                                                 | 자동 스케일링 메모리 대상 값을 설정합니다 |
| `hpa.memory.targetAverageUtilization`                         |                                                                 | 자동 스케일링 메모리 대상 활용률을 설정합니다 |
| `hpa.targetAverageValue`                                      |                                                                 | **DEPRECATED** 자동 스케일링 CPU 대상 값을 설정합니다 |
| `sshHostKeys.mount`                                           | `false`                                                         | 공개 SSH 키를 포함하는 GitLab Shell 시크릿을 마운트할지 여부. |
| `sshHostKeys.mountName`                                       | `ssh-host-keys`                                                 | 마운트된 볼륨의 이름. |
| `sshHostKeys.types`                                           | `[dsa,rsa,ecdsa,ed25519]`                                       | 마운트할 SSH 키 유형 목록. |
| `image.pullPolicy`                                            | `Always`                                                        | Webservice 이미지 풀 정책 |
| `image.pullSecrets`                                           |                                                                 | 이미지 저장소의 비밀 |
| `image.repository`                                            | `registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ee` | Webservice 이미지 저장소 |
| `image.tag`                                                   |                                                                 | Webservice 이미지 태그 |
| `init.image.repository`                                       |                                                                 | initContainer 이미지 |
| `init.image.tag`                                              |                                                                 | initContainer 이미지 태그 |
| `init.containerSecurityContext.runAsUser`                     | `1000`                                                          | initContainer 특정:  컨테이너를 시작해야 하는 사용자 ID |
| `init.containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                         | initContainer 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `init.containerSecurityContext.runAsNonRoot`                  | `true`                                                          | initContainer 특정:  컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `init.containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                     | initContainer 특정:  컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `keda.enabled`                                                | `false`                                                         | [KEDA](https://keda.sh/) `ScaledObjects`를 `HorizontalPodAutoscalers` 대신 사용합니다 |
| `keda.pollingInterval`                                        | `30`                                                            | 각 트리거를 확인하는 간격 |
| `keda.cooldownPeriod`                                         | `300`                                                           | 마지막 트리거가 활성으로 보고된 후 리소스를 0으로 다시 스케일링할 때까지 기다릴 기간 |
| `keda.minReplicaCount`                                        | `minReplicas`                                                   | KEDA가 리소스를 축소할 최소 복제본 수입니다. |
| `keda.maxReplicaCount`                                        | `maxReplicas`                                                   | KEDA가 리소스를 확장할 최대 복제본 수입니다. |
| `keda.fallback`                                               |                                                                 | KEDA 폴백 구성, [설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)를 참조하세요 |
| `keda.hpaName`                                                | `keda-hpa-{scaled-object-name}`                                 | KEDA가 생성할 HPA 리소스의 이름입니다. |
| `keda.restoreToOriginalReplicaCount`                          |                                                                 | `ScaledObject`이 삭제된 후 대상 리소스를 원래 복제본 수로 다시 스케일링할지 여부를 지정합니다 |
| `keda.behavior`                                               | `hpa.behavior`                                                  | 상향 및 하향 스케일링 동작의 사양입니다. |
| `keda.triggers`                                               |                                                                 | 대상 리소스의 스케일링을 활성화할 트리거 목록, `hpa.cpu` 및 `hpa.memory`에서 계산된 트리거로 기본값 |
| `metrics.enabled`                                             | `true`                                                          | 메트릭 엔드포인트를 스크래핑할 수 있도록 해야 하는지 여부 |
| `metrics.port`                                                | `8083`                                                          | 메트릭 엔드포인트 포트 |
| `metrics.listenAddr`                                          | `0.0.0.0`                                                       | 메트릭 수신 주소. |
| `metrics.path`                                                | `/metrics`                                                      | 메트릭 엔드포인트 경로 |
| `metrics.serviceMonitor.enabled`                              | `false`                                                         | Prometheus Operator가 메트릭 스크래핑을 관리하도록 ServiceMonitor를 생성해야 하는지 여부. 이를 활성화하면 `prometheus.io` 스크래핑 주석이 제거됩니다 |
| `metrics.serviceMonitor.additionalLabels`                     | `{}`                                                            | ServiceMonitor에 추가할 추가 레이블 |
| `metrics.serviceMonitor.endpointConfig`                       | `{}`                                                            | ServiceMonitor의 추가 엔드포인트 구성 |
| `metrics.annotations`                                         |                                                                 | **DEPRECATED** 명시적 메트릭 주석을 설정합니다. 템플릿 콘텐츠로 대체됩니다. |
| `metrics.tls.enabled`                                         |                                                                 | 메트릭/web_exporter 엔드포인트에 대해 TLS 활성화. `tls.enabled`로 기본값이 설정됩니다. |
| `metrics.tls.secretName`                                      |                                                                 | 메트릭/web_exporter 엔드포인트 TLS 인증서 및 키용 시크릿. `tls.secretName`로 기본값이 설정됩니다. |
| `minio.bucket`                                                | `git-lfs`                                                       | MinIO를 사용할 때 저장소 버킷의 이름 |
| `minio.port`                                                  | `9000`                                                          | MinIO 서비스의 포트 |
| `minio.serviceName`                                           | `minio-svc`                                                     | MinIO 서비스의 이름 |
| `monitoring.ipWhitelist`                                      | `[0.0.0.0/0, ::/0]`                                             | 모니터링 엔드포인트를 위해 화이트리스트에 추가할 IP 목록 |
| `monitoring.exporter.listenAddr`                              | `0.0.0.0`                                                       | 메트릭 수신 주소. |
| `monitoring.exporter.enabled`                                 | `false`                                                         | 웹서버가 Prometheus 메트릭을 노출할 수 있게 합니다. 메트릭 포트가 모니터링 익스포터 포트로 설정된 경우 `metrics.enabled`에 의해 무시됩니다. |
| `monitoring.exporter.port`                                    | `8083`                                                          | 메트릭 익스포터에 사용할 포트 번호 |
| `psql.password.key`                                           | `psql-password`                                                 | psql 시크릿의 psql 비밀번호에 대한 키 |
| `psql.password.secret`                                        | `gitlab-postgres`                                               | psql 시크릿 이름 |
| `psql.port`                                                   |                                                                 | PostgreSQL 서버 포트를 설정합니다. `global.psql.port`보다 우선합니다. |
| `puma.disableWorkerKiller`                                    | `true`                                                          | Puma 워커 메모리 killer 비활성화 |
| `puma.workerMaxMemory`                                        |                                                                 | Puma 워커 killer의 최대 메모리(메가바이트) |
| `puma.threads.min`                                            | `4`                                                             | Puma 스레드의 최소 개수 |
| `puma.threads.max`                                            | `4`                                                             | Puma 스레드의 최대 개수 |
| `puma.bindIp6`                                                | `false`                                                         | Puma으로 IPv6 주소 바인딩. 현재 요청 속도 제한과 관련된 [알려진 문제](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6084) 때문에 false로 기본값이 지정됩니다. |
| `rack_attack.git_basic_auth`                                  | `{}`                                                            | 자세한 내용은 [GitLab 설명서](https://docs.gitlab.com/administration/settings/protected_paths/)를 참조하세요. |
| `global.registry.api.port`                                    | `5000`                                                          | Registry 포트 |
| `global.registry.api.protocol`                                | `http`                                                          | Registry 프로토콜 |
| `global.registry.api.serviceName`                             | `registry`                                                      | Registry 서비스 이름 |
| `global.registry.enabled`                                     | `true`                                                          | 모든 프로젝트 메뉴에서 registry 링크 추가/제거 |
| `global.registry.tokenIssuer`                                 | `gitlab-issuer`                                                 | Registry 토큰 발급자 |
| `replicaCount`                                                | `1`                                                             | Webservice 복제본 수 |
| `resources.requests.cpu`                                      | `300m`                                                          | Webservice 최소 CPU |
| `resources.requests.memory`                                   | `1.5G`                                                          | Webservice 최소 메모리 |
| `service.externalPort`                                        | `8080`                                                          | Webservice 노출 포트 |
| `securityContext.fsGroup`                                     | `1000`                                                          | 포드를 시작해야 하는 그룹 ID |
| `securityContext.runAsUser`                                   | `1000`                                                          | 포드를 시작해야 하는 사용자 ID |
| `securityContext.fsGroupChangePolicy`                         |                                                                 | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `securityContext.seccompProfile.type`                         | `RuntimeDefault`                                                | 사용할 Seccomp 프로필 |
| `containerSecurityContext`                                    |                                                                 | 컨테이너가 시작되는 컨테이너 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)를 재정의합니다 |
| `containerSecurityContext.runAsUser`                          | `1000`                                                          | 컨테이너가 시작되는 특정 보안 컨텍스트 사용자 ID를 덮어쓰도록 허용합니다 |
| `containerSecurityContext.allowPrivilegeEscalation`           | `false`                                                         | Gitaly 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `containerSecurityContext.runAsNonRoot`                       | `true`                                                          | Gitaly 컨테이너가 root가 아닌 사용자로 실행되는지 여부를 제어합니다. |
| `containerSecurityContext.capabilities.drop`                  | `[ "ALL" ]`                                                     | Gitaly 컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `serviceAccount.automountServiceAccountToken`                 | `false`                                                         | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다 |
| `serviceAccount.create`                                       | `false`                                                         | ServiceAccount를 생성해야 하는지 여부를 나타냅니다 |
| `serviceAccount.enabled`                                      | `false`                                                         | ServiceAccount를 사용해야 하는지 여부를 나타냅니다 |
| `serviceAccount.name`                                         |                                                                 | ServiceAccount의 이름입니다. 설정하지 않으면 전체 차트 이름이 사용됩니다 |
| `serviceLabels`                                               | `{}`                                                            | 보충 서비스 레이블 |
| `service.internalPort`                                        | `8080`                                                          | Webservice 내부 포트 |
| `service.type`                                                | `ClusterIP`                                                     | Webservice 서비스 유형 |
| `service.workhorseExternalPort`                               | `8181`                                                          | Workhorse 노출 포트 |
| `service.workhorseInternalPort`                               | `8181`                                                          | Workhorse 내부 포트 |
| `service.loadBalancerIP`                                      |                                                                 | LoadBalancer에 할당할 IP 주소 (클라우드 공급자가 지원하는 경우) |
| `service.loadBalancerSourceRanges`                            |                                                                 | LoadBalancer에 액세스할 수 있는 IP CIDR 목록 (지원되는 경우) service.type = LoadBalancer에 필요 |
| `shell.authToken.key`                                         | `secret`                                                        | 셸 시크릿의 셸 토큰에 대한 키 |
| `shell.authToken.secret`                                      | `{Release.Name}-gitlab-shell-secret`                            | 셸 토큰 시크릿 |
| `shell.port`                                                  | `nil`                                                           | UI에서 생성된 SSH URL에 사용할 포트 번호 |
| `shutdown.blackoutSeconds`                                    | `10`                                                            | 종료를 받은 후 Webservice를 실행하는 시간(초). `deployment.terminationGracePeriodSeconds`보다 짧아야 합니다. 활성화된 경우 workhorse 헬스체크 리스너의 종료 지연을 구성합니다. |
| `tls.enabled`                                                 | `false`                                                         | Webservice TLS 활성화 |
| `tls.secretName`                                              | `{Release.Name}-webservice-tls`                                 | Webservice TLS 시크릿. `secretName`은(는) [Kubernetes TLS 시크릿](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)을(를) 가리켜야 합니다. |
| `tolerations`                                                 | `[]`                                                            | 포드 할당을 위한 용인 레이블 |
| `trusted_proxies`                                             | `[]`                                                            | 자세한 내용은 [GitLab 설명서](https://docs.gitlab.com/install/installation/#adding-your-trusted-proxies)를 참조하세요. |
| `workhorse.logFormat`                                         | `json`                                                          | 로깅 형식. 유효한 형식: `json`, `structured`, `text` |
| `workerProcesses`                                             | `2`                                                             | Webservice 워커 수 |
| `workhorse.keywatcher`                                        | `true`                                                          | workhorse를 Redis에 구독합니다. 이는 `/api/*`에 대한 요청을 제공하는 모든 배포에 **required**이지만 다른 배포에서는 안전하게 비활성화할 수 있습니다. |
| `workhorse.shutdownTimeout`                                   | `global.webservice.workerTimeout + 1` (초)                 | Workhorse에서 모든 웹 요청을 지우기를 기다리는 시간. 예: `1min`, `65s`. |
| `workhorse.adoptCfRayHeader`                                  | `false`                                                         | 수신 `Cf-Ray` 헤더를 존재하는 경우 Correlation-ID로 채택합니다. 자세한 내용은 [Workhorse 설명서](https://docs.gitlab.com/development/workhorse/configuration/#propagate-correlation-ids)를 참조하세요. |
| `workhorse.trustedCIDRsForPropagation`                        |                                                                 | correlation ID 전파를 신뢰할 수 있는 CIDR 블록 목록. `-propagateCorrelationID` 옵션도 `workhorse.extraArgs`에서 사용해야 이것이 작동합니다. 자세한 내용은 [Workhorse 설명서](https://docs.gitlab.com/development/workhorse/configuration/#propagate-correlation-ids)를 참조하세요. |
| `workhorse.trustedCIDRsForXForwardedFor`                      |                                                                 | `X-Forwarded-For` HTTP 헤더를 통해 실제 클라이언트 IP를 확인하는 데 사용할 수 있는 CIDR 블록 목록. 이는 `workhorse.trustedCIDRsForPropagation`와 함께 사용됩니다. 자세한 내용은 [Workhorse 설명서](https://docs.gitlab.com/development/workhorse/configuration/#trusted-proxies)를 참조하세요. |
| `workhorse.metadata.zipReaderLimitBytes`                      |                                                                 | zip 리더를 제한할 선택적 바이트 수. GitLab 16.9에서 도입됨. 자세한 내용은 [Workhorse 설명서](https://docs.gitlab.com/development/workhorse/configuration/#metadata-options)를 참조하세요. |
| `workhorse.containerSecurityContext`                          |                                                                 | 컨테이너가 시작되는 컨테이너 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)를 재정의합니다 |
| `workhorse.containerSecurityContext.runAsUser`                | `1000`                                                          | 컨테이너를 시작해야 하는 사용자 ID |
| `workhorse.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                         | 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `workhorse.containerSecurityContext.runAsNonRoot`             | `true`                                                          | 컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `workhorse.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                     | Gitaly 컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `workhorse.livenessProbe.initialDelaySeconds`                 | `20`                                                            | 생동성 프로브가 시작되기 전의 지연 |
| `workhorse.livenessProbe.periodSeconds`                       | `60`                                                            | 생동성 프로브를 수행하는 빈도 |
| `workhorse.livenessProbe.timeoutSeconds`                      | `30`                                                            | 생동성 프로브 시간이 초과될 때 |
| `workhorse.livenessProbe.successThreshold`                    | `1`                                                             | 생동성 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `workhorse.livenessProbe.failureThreshold`                    | `3`                                                             | 생동성 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `workhorse.healthcheckListener.enabled`                       | `false`                                                         | workhorse 헬스체크 리스너를 활성화하고 기본 Puma readiness 프로브를 비활성화합니다. readiness 상태를 더 안정적으로 감지하고 결함이 더 적게 발생합니다. GitLab 18.5에서 도입됨. |
| `workhorse.healthcheckListener.port`                          | `8182`                                                          | 헬스체크 리스너에 사용할 포트 번호. |
| `workhorse.healthcheckListener.pumaControl`                   | `true`                                                          | Puma readiness 엔드포인트 대신 Puma 제어 애플리케이션을 쿼리합니다. |
| `workhorse.healthcheckListener.checkInterval`                 | `10s`                                                           | 업스트림 Puma 서버의 연속 헬스 상태 확인 간의 시간 간격. |
| `workhorse.healthcheckListener.timeout`                       | `5s`                                                            | Puma 확인 요청의 타임아웃. |
| `workhorse.healthcheckListener.maxConsecutiveFailures`        | `1`                                                             | workhorse를 준비되지 않은 것으로 표시하기 전의 실패 횟수. |
| `workhorse.healthcheckListener.minSuccessfullProbes`          | `1`                                                             | workhorse가 준비 완료로 간주되기 전의 성공적인 프로브 수. |
| `workhorse.healthcheckListener.railsSkipInterval`             | `0s`                                                            | 요청이 성공적으로 처리된 후 Puma readiness 확인을 다시 시작하기 전의 시간 지연. 기본적으로 비활성화됩니다. |
| `workhorse.loadShedding.enabled`                              | `false`                                                         | 부하 분산을 활성화하여 Puma의 요청 백로그가 임계값을 초과할 때 `503`을(를) 반환합니다. |
| `workhorse.loadShedding.backlogThreshold`                     | `50`                                                            | 부하 분산을 시작할 백로그 임계값. |
| `workhorse.loadShedding.backlogHysteresis`                    | `0.8`                                                           | 비활성화를 위한 이력 인수 (0.0~1.0). 백로그가 임계값 * 이력 이하로 떨어지면 부하 분산이 비활성화됩니다. |
| `workhorse.loadShedding.retryAfterSeconds`                    | `0`                                                             | 부하 분산 시 Retry-After 헤더 값(초). 즉시 재시도(Kubernetes에 권장)의 경우 0을 사용합니다. |
| `workhorse.loadShedding.statusCode`                           | `503`                                                           | 부하 분산 시 반환할 HTTP 상태 코드. 다른 `503` 오류와 구분하기 위해 `529` 같은 사용자 지정 코드를 사용합니다. |
| `workhorse.loadShedding.strategy`                             | `max`                                                           | 효과적인 백로그를 계산하는 전략: "max" (기본값) 또는 "sum". |
| `workhorse.loadShedding.checkInterval`                        | `1s`                                                            | Puma의 백로그 메트릭을 샘플링하는 빈도. 헬스 확인 간격과 무관합니다. |
| `workhorse.loadShedding.timeout`                              | `5s`                                                            | 제어 서버 요청의 타임아웃. |
| `workhorse.monitoring.exporter.enabled`                       | `false`                                                         | workhorse가 Prometheus 메트릭을 노출할 수 있게 합니다. `workhorse.metrics.enabled`에 의해 무시됩니다. |
| `workhorse.monitoring.exporter.port`                          | `9229`                                                          | workhorse Prometheus 메트릭에 사용할 포트 번호 |
| `workhorse.monitoring.exporter.tls.enabled`                   | `false`                                                         | `true`로 설정하면 메트릭 엔드포인트에서 TLS를 활성화합니다. [Workhorse에 대해 TLS를 활성화](#gitlab-workhorse)해야 합니다. |
| `workhorse.metrics.enabled`                                   | `true`                                                          | workhorse 메트릭 엔드포인트를 스크래핑에 사용할 수 있게 할지 여부 |
| `workhorse.metrics.port`                                      | `8083`                                                          | Workhorse 메트릭 엔드포인트 포트 |
| `workhorse.metrics.path`                                      | `/metrics`                                                      | Workhorse 메트릭 엔드포인트 경로 |
| `workhorse.metrics.serviceMonitor.enabled`                    | `false`                                                         | Prometheus Operator가 Workhorse 메트릭 스크래핑을 관리하도록 ServiceMonitor를 생성할지 여부 |
| `workhorse.metrics.serviceMonitor.additionalLabels`           | `{}`                                                            | Workhorse ServiceMonitor에 추가할 추가 레이블 |
| `workhorse.metrics.serviceMonitor.endpointConfig`             | `{}`                                                            | Workhorse ServiceMonitor의 추가 엔드포인트 구성 |
| `workhorse.readinessProbe.initialDelaySeconds`                | `0`                                                             | 준비 프로브가 시작되기 전의 지연 |
| `workhorse.readinessProbe.periodSeconds`                      | `10`                                                            | 준비 프로브를 수행하는 빈도 |
| `workhorse.readinessProbe.timeoutSeconds`                     | `2`                                                             | 준비 프로브 시간이 초과될 때 |
| `workhorse.readinessProbe.successThreshold`                   | `1`                                                             | 준비 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `workhorse.readinessProbe.failureThreshold`                   | `3`                                                             | 준비 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `workhorse.imageScaler.maxProcs`                              | `2`                                                             | 동시에 실행될 수 있는 최대 이미지 확장 프로세스 수 |
| `workhorse.imageScaler.maxFileSizeBytes`                      | `250000`                                                        | 스케일러로 처리할 이미지의 최대 파일 크기(바이트) |
| `workhorse.tls.verify`                                        | `true`                                                          | `true`로 설정하면 NGINX Ingress가 Workhorse의 TLS 인증서를 확인하도록 합니다. 사용자 지정 CA의 경우 `workhorse.tls.caSecretName`도 설정해야 합니다. 자체 서명 인증서의 경우 `false`로 설정해야 합니다. [Gateway API](../../../advanced/gateway-api/_index.md#tls-between-gateway-and-backend-services)를 사용하는 경우 Gateway API 컨트롤러는 항상 인증서를 확인합니다. |
| `workhorse.tls.secretName`                                    | `{Release.Name}-workhorse-tls`                                  | TLS 키 및 인증서 쌍을 포함하는 [TLS 시크릿](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)의 이름. 이는 Workhorse TLS가 활성화되어 있을 때 필요합니다. |
| `workhorse.tls.caSecretName`                                  |                                                                 | CA 인증서를 포함하는 시크릿의 이름. 이는 **은 아님** [TLS 시크릿](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)이며 `ca.crt` 키만 포함해야 합니다. 이는 NGINX의 TLS 확인에 사용됩니다. |
| `workhorse.circuitBreaker.enabled`                            | `false`                                                         | 서킷 브레이커 활성화 여부 |
| `workhorse.circuitBreaker.timeout`                            | `60`                                                            | 열려 있을 때 서킷 브레이커를 반개방으로 전환하는 기간(초) |
| `workhorse.circuitBreaker.interval`                           | `180`.                                                          | 닫혀 있을 때 서킷 브레이커가 연속 실패를 지우기까지의 기간(초) |
| `workhorse.circuitBreaker.maxRequests`                        | `1`.                                                            | 반개방 상태일 때 서킷 브레이커를 열기 위한 실패한 요청 수 |
| `workhorse.circuitBreaker.consecutiveFailures`                | `5`.                                                            | 닫혀 있을 때 서킷 브레이커를 열기 위한 연속 실패 요청 수 |
| `webServer`                                                   | `puma`                                                          | 요청 처리에 사용될 웹 서버(Webservice/Puma)를 선택합니다. |
| `priorityClassName`                                           | `""`                                                            | 포드 `priorityClassName`을(를) 구성할 수 있습니다. 이는 제거 시 포드 우선순위를 제어하는 데 사용됩니다. |
| `antiAffinity`                                           | `""`                                                         | 차트 전역 값의 antiAffinity 값을 덮어쓸 수 있습니다. 기본값은 전역에서 읽혀지며 `soft` 또는 `hard`로 설정할 수 있습니다. |

## 차트 구성 예시 {#chart-configuration-examples}

### `extraEnv` {#extraenv}

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

### `extraEnvFrom` {#extraenvfrom}

`extraEnvFrom`을(를) 사용하면 포드의 모든 컨테이너에서 다른 데이터 소스의 추가 환경 변수를 노출할 수 있습니다. 후속 변수는 [배포](#deployments-settings)당 재정의될 수 있습니다.

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
deployments:
  default:
    extraEnvFrom:
      CONFIG_STRING:
        configMapKeyRef:
          name: useful-config
          key: some-string
          # optional: boolean
```

### `image.pullSecrets` {#imagepullsecrets}

`pullSecrets`을(를) 사용하면 개인 레지스트리에 인증하여 포드의 이미지를 가져올 수 있습니다.

개인 레지스트리 및 해당 인증 방법에 대한 추가 세부사항은 [Kubernetes 설명서](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)에서 찾을 수 있습니다.

다음은 `pullSecrets`의 예시 사용입니다:

```yaml
image:
  repository: my.webservice.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

이 섹션에서는 ServiceAccount를 생성해야 하는지 여부와 기본 액세스 토큰을 Pod에 마운트해야 하는지 여부를 제어합니다.

| 이름                           |  유형   | 기본값 | 설명 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   맵   | `{}`    | ServiceAccount 주석. |
| `automountServiceAccountToken` | 부울 | `false` | 기본 ServiceAccount 액세스 토큰이 Pod에 마운트되어야 하는지 여부를 제어합니다. 특정 사이드카가 제대로 작동하도록 필요한 경우가 아니면(예: Istio) 이를 활성화하지 않아야 합니다. |
| `create`                       | 부울 | `false` | ServiceAccount를 생성해야 하는지 여부를 나타냅니다. |
| `enabled`                      | 부울 | `false` | ServiceAccount를 사용해야 하는지 여부를 나타냅니다. |
| `name`                         | 문자열  |         | ServiceAccount의 이름입니다. 설정하지 않은 경우 전체 차트 이름이 사용됩니다. |

### `tolerations` {#tolerations}

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

### `annotations` {#annotations}

`annotations`을(를) 사용하면 Webservice 포드에 어노테이션을 추가할 수 있습니다. 예를 들어:

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### `strategy` {#strategy}

`deployment.strategy`을(를) 사용하면 배포 업데이트 전략을 변경할 수 있습니다. 배포가 업데이트될 때 포드를 다시 생성하는 방식을 정의합니다. 제공되지 않으면 클러스터 기본값이 사용됩니다. 예를 들어 순환 업데이트가 시작될 때 추가 포드를 생성하지 않고 최대 사용 불가능 포드를 50%로 변경하려는 경우:

```yaml
deployment:
  strategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 50%
```

업데이트 전략의 유형을 `Recreate`로 변경할 수도 있지만 모든 포드를 종료한 후 새 포드를 스케줄하고 새 포드가 시작될 때까지 웹 UI를 사용할 수 없으므로 주의하세요. 이 경우 `rollingUpdate`을(를) 정의할 필요가 없으며 `type`만 필요합니다:

```yaml
deployment:
  strategy:
    type: Recreate
```

자세한 내용은 [Kubernetes 설명서](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)를 참조하세요.

### TLS {#tls}

Webservice 포드는 두 개의 컨테이너를 실행합니다:

- `gitlab-workhorse`
- `webservice`

#### `gitlab-workhorse` {#gitlab-workhorse}

Workhorse는 웹 및 메트릭 엔드포인트 모두에 대해 TLS를 지원합니다. 이는 Workhorse와 다른 구성 요소, 특히 `nginx-ingress`, `gitlab-shell` 및 `gitaly` 간의 통신을 보호합니다. TLS 인증서는 Workhorse Service 호스트 이름(예: `RELEASE-webservice-default.default.svc`)을 CN(Common Name) 또는 SAN(Subject Alternate Name)에 포함해야 합니다.

[Webservice의 여러 배포](#deployments-settings)가 존재할 수 있으므로 다양한 서비스 이름에 대한 TLS 인증서를 준비해야 합니다. 이는 여러 SAN 또는 와일드카드 인증서로 달성할 수 있습니다.

TLS 인증서가 생성되면 [Kubernetes TLS 시크릿](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)을 생성합니다. `ca.crt` 키가 있는 TLS 인증서의 CA 인증서만 포함하는 다른 시크릿을 생성해야 합니다.

`gitlab-workhorse` 컨테이너에 대해 TLS를 활성화하려면 `global.workhorse.tls.enabled`을(를) `true`로 설정합니다. `gitlab.webservice.workhorse.tls.secretName` 및 `global.certificates.customCAs`에 사용자 지정 시크릿 이름을 전달할 수 있습니다.

`gitlab.webservice.workhorse.tls.verify`이(가) `true` (기본값)일 때 CA 인증서 시크릿 이름도 `gitlab.webservice.workhorse.tls.caSecretName`에 전달해야 합니다. 이는 자체 서명 인증서 및 사용자 지정 CA에 필요합니다. 이 시크릿은 NGINX에서 Workhorse의 TLS 인증서를 확인하는 데 사용됩니다.

```yaml
global:
  workhorse:
    tls:
      enabled: true
  certificates:
    customCAs:
      - secret: gitlab-workhorse-ca
gitlab:
  webservice:
    workhorse:
      tls:
        verify: true
        # secretName: gitlab-workhorse-tls
        caSecretName: gitlab-workhorse-ca
      monitoring:
        exporter:
          enabled: true
          tls:
            enabled: true
```

`gitlab-workhorse` 컨테이너의 메트릭 엔드포인트에 대한 TLS는 `global.workhorse.tls.enabled`에서 상속됩니다. 메트릭 엔드포인트에서 TLS는 Workhorse에 대해 TLS가 활성화될 때만 사용 가능합니다. 메트릭 리스너는 `gitlab.webservice.workhorse.tls.secretName`에 의해 지정된 동일한 TLS 인증서를 사용합니다.

메트릭 엔드포인트에 사용되는 TLS 인증서는 포함된 주체 대체 이름(SAN), 특히 포함된 Prometheus Helm 차트를 사용하는 경우 추가 고려 사항이 필요할 수 있습니다. 자세한 내용은 [TLS 지원 엔드포인트를 스크래핑하도록 Prometheus 구성](../../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints)을 참조하세요.

#### `webservice` {#webservice}

TLS를 활성화하는 주요 사용 사례는 [Prometheus 메트릭 스크래핑](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/)을 위해 HTTPS를 통한 암호화를 제공하는 것입니다.

Prometheus가 HTTPS를 사용하여 `/metrics/` 엔드포인트를 스크래핑하려면 인증서의 `CommonName` 속성 또는 `SubjectAlternativeName` 항목에 대한 추가 구성이 필요합니다. 이러한 요구사항에 대해 [TLS 지원 엔드포인트를 스크래핑하도록 Prometheus 구성](../../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints)을 참조하세요.

TLS는 `webservice` 컨테이너에서 `gitlab.webservice.tls.enabled` 설정으로 활성화할 수 있습니다:

```yaml
gitlab:
  webservice:
    tls:
      enabled: true
      # secretName: gitlab-webservice-tls
```

`secretName`은(는) [Kubernetes TLS 시크릿](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)을(를) 가리켜야 합니다. 예를 들어 로컬 인증서 및 키로 TLS 시크릿을 생성하려면:

```shell
kubectl create secret tls <secret name> --cert=path/to/puma.crt --key=path/to/puma.key
```

## 이 차트의 Community Edition 사용 {#using-the-community-edition-of-this-chart}

기본적으로 Helm 차트는 GitLab Enterprise Edition을 사용합니다. 원하는 경우 Community Edition을 대신 사용할 수 있습니다. [두 가지 간의 차이점](https://about.gitlab.com/install/ce-or-ee/)에 대해 자세히 알아보세요.

Community Edition을 사용하려면 `image.repository`을(를) `registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ce`로 설정하고 `workhorse.image`을(를) `registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ce`로 설정합니다.

## 전역 설정 {#global-settings}

차트 간에 공통 전역 설정을 공유합니다. [전역 문서](../../globals.md)에서 GitLab 및 Registry 호스트명과 같은 일반적인 구성 옵션을 참조하세요.

## 배포 설정 {#deployments-settings}

이 차트는 여러 배포 객체 및 관련 리소스를 생성할 수 있습니다. 이 기능을 사용하면 GitLab 애플리케이션에 대한 요청을 경로 기반 라우팅을 사용하여 여러 포드 세트 간에 분배할 수 있습니다.

이 맵의 키(`default` 이 예)는 각각의 "이름"입니다. `default`는 `RELEASE-webservice-default`으로 생성된 배포, 서비스, HorizontalPodAutoscaler, PodDisruptionBudget 및 선택적 Ingress를 가집니다.

제공하지 않은 모든 속성은 `gitlab-webservice` 차트 기본값에서 상속됩니다.

```yaml
deployments:
  default:
    ingress:
      path: # Does not inherit or default. Leave blank to disable Ingress.
      pathType: Prefix
      provider: nginx
      annotations:
        # inherits `ingress.anntoations`
      proxyConnectTimeout: # inherits `ingress.proxyConnectTimeout`
      proxyReadTimeout:    # inherits `ingress.proxyReadTimeout`
      proxyBodySize:       # inherits `ingress.proxyBodySize`
    deployment:
      annotations: # map
      labels: # map
      # inherits `deployment`
    pod:
      labels: # additional labels to .podLabels
      annotations: # map
        # inherit from .Values.annotations
    service:
      labels: # additional labels to .serviceLabels
      annotations: # additional annotations to .service.annotations
        # inherits `service.annotations`
    hpa:
      minReplicas: # defaults to .minReplicas
      maxReplicas: # defaults to .maxReplicas
      metrics: # optional replacement of HPA metrics definition
      # inherits `hpa`
    pdb:
      maxUnavailable: # inherits `maxUnavailable`
    resources: # `resources` for `webservice` container
      # inherits `resources`
    workhorse: # map
      # inherits `workhorse`
    extraEnv: #
      # inherits `extraEnv`
    extraEnvFrom: #
      # inherits `extraEnvFrom`
    puma: # map
      # inherits `puma`
    workerProcesses: # inherits `workerProcesses`
    shutdown:
      # inherits `shutdown`
    nodeSelector: # map
      # inherits `nodeSelector`
    tolerations: # array
      # inherits `tolerations`
    priorityClassName: # inherits `priorityClassName`
```

### 배포 Ingress {#deployments-ingress}

각 `deployments` 항목은 차트 전체 [Ingress 설정](#ingress-settings)을 상속합니다. 여기서 제공하는 모든 값은 거기에서 제공하는 값을 재정의합니다. `path` 외에 모든 설정은 동일합니다.

```yaml
webservice:
  deployments:
    default:
      ingress:
        path: /
    api:
      ingress:
        path: /api
```

`path` 속성이 직접 Ingress의 `path` 속성에 채워지며 각 서비스로 지정되는 URI 경로를 제어할 수 있습니다. 위의 예에서 `default`은 전체 경로로 작동하고 `api`은 `/api` 아래의 모든 트래픽을 수신합니다.

`path`을 비워 지정된 배포가 관련 Ingress 리소스를 생성하지 않도록 비활성화할 수 있습니다. 아래를 참조하세요. 여기서 `internal-api`는 외부 트래픽을 받지 않습니다.

```yaml
webservice:
  deployments:
    default:
      ingress:
        path: /
    api:
      ingress:
        path: /api
    internal-api:
      ingress:
        path:
```

## Ingress 설정 {#ingress-settings}

| 이름                              |  유형   | 기본값                   | 설명 |
|:----------------------------------|:-------:|:--------------------------|:------------|
| `ingress.apiVersion`              | 문자열  |                           | `apiVersion` 필드에서 사용할 값입니다. |
| `ingress.annotations`             |   맵   | [아래](#annotations)를 참조하세요. | 이러한 어노테이션은 모든 Ingress에 사용됩니다. 예: `ingress.annotations."nginx\.ingress\.kubernetes\.io/enable-access-log"=true`. |
| `ingress.configureCertmanager`    | 부울 |                           | Ingress 주석 `cert-manager.io/issuer` 및 `acme.cert-manager.io/http01-edit-in-place`를 토글합니다. 자세한 내용은 [GitLab Pages에 대한 TLS 요구 사항](../../../installation/tls.md)을 참조하세요. |
| `ingress.enabled`                 | 부울 | `false`                   | Ingress 객체를 생성할 서비스를 지원하는지 여부를 제어하는 설정입니다. `false`인 경우 `global.ingress.enabled` 설정 값이 사용됩니다. |
| `ingress.proxyBodySize`           | 문자열  | `512m`                    | [아래를 참조하세요.](#proxybodysize) |
| `ingress.serviceUpstream`         | 부울 | `true`                    | [아래를 참조하세요.](#serviceupstream) |
| `ingress.tls.enabled`             | 부울 | `true`                    | `false`로 설정하면 GitLab Webservice에 대해 TLS를 비활성화합니다. 이는 TLS 종료를 Ingress 수준에서 사용할 수 없는 경우에 주로 유용합니다. 예를 들어 Ingress 컨트롤러 앞에 TLS를 종료하는 프록시가 있는 경우입니다. |
| `ingress.tls.secretName`          | 문자열  | (비어 있음)                   | GitLab URL에 대해 유효한 인증서 및 키를 포함하는 Kubernetes TLS 시크릿의 이름. 설정하지 않으면 `global.ingress.tls.secretName` 값이 대신 사용됩니다. |
| `ingress.tls.smardcardSecretName` | 문자열  | (비어 있음)                   | 활성화된 경우 GitLab smartcard URL에 대해 유효한 인증서 및 키를 포함하는 Kubernetes TLS 시크릿의 이름. 설정하지 않으면 `global.ingress.tls.secretName` 값이 대신 사용됩니다. |
| `ingress.tls.useGeoClass`         | 부울 | `false`                   | IngressClass를 Geo Ingress 클래스(`global.geo.ingressClass`)로 재정의합니다. 기본 Geo 사이트에 필요합니다. |

### 주석 {#annotations-1}

`annotations`은 Webservice Ingress에 어노테이션을 설정하는 데 사용됩니다.

### `serviceUpstream` {#serviceupstream}

이는 NGINX에 Webservice 포드로의 트래픽을 더 균등하게 분산하도록 지시하여 직접 서비스 자체와 접촉하도록 함으로써 트래픽 균형을 더 잘 맞추는 데 도움이 됩니다. 자세한 내용은 [NGINX 문서](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md#service-upstream)를 참조하세요.

이를 재정의하려면 다음을 설정합니다:

```yaml
gitlab:
  webservice:
    ingress:
      serviceUpstream: "false"
```

### `proxyBodySize` {#proxybodysize}

`proxyBodySize`은 NGINX 프록시 최대 본문 크기를 설정하는 데 사용됩니다. 이는 기본값보다 더 큰 Docker 이미지를 허용하기 위해 일반적으로 필요합니다. 이는 [Linux 패키지 설치](https://docs.gitlab.com/omnibus/settings/nginx/#use-an-existing-passenger-and-nginx-installation)의 `nginx['client_max_body_size']` 구성과 동등합니다. 대안으로 다음 두 매개변수 중 하나를 사용하여 본문 크기를 설정할 수 있습니다:

- `gitlab.webservice.ingress.annotations."nginx\.ingress\.kubernetes\.io/proxy-body-size"`
- `global.ingress.annotations."nginx\.ingress\.kubernetes\.io/proxy-body-size"`

### 추가 Ingress {#extra-ingress}

`extraIngress.enabled=true`을(를) 설정하여 추가 Ingress를 배포할 수 있습니다. Ingress의 이름은 기본 Ingress의 `-extra` 접미사이며 기본 Ingress와 동일한 설정을 지원합니다.

## Gateway API {#gateway-api}

GitLab 차트가 [Gateway API를 통해 노출](../../globals.md#gateway-api)되도록 구성된 경우 각 배포가 webservice 차트의 `HTTPRoute`에 규칙으로 추가됩니다.

`HTTPRoute`의 규칙을 가지지 않도록 지정된 배포를 비활성화할 수 있습니다. 배포에 `.rules=[]`을(를) 설정합니다.

```yaml
webservice:
  deployments:
    default:
      gatewayRoute:
        rules:
        - matches:
          - path:
              type: PathPrefix
              value: /
          timeouts:
            request: "20s"
            backendRequest: "20s"
          filters:
          - type: RequestHeaderModifier
            requestHeaderModifier:
              remove:
              - X-Forwarded-Host
    api:
      gatewayRoute:
        rules:
        - matches:
          - path:
              type: PathPrefix
              value: /api
    internal-api:
      gatewayRoute:
        rules: []
```

각 규칙은 `matches`, `timeouts` 및 `filters`을(를) 지원합니다. 필터는 [Gateway API HTTPRouteFilter](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPRouteFilter) 객체 목록을 수락합니다.

### Gateway와 Workhorse 간 TLS {#tls-between-gateway-and-workhorse}

[Workhorse TLS](#gitlab-workhorse)가 활성화되면 배포당 `BackendTLSPolicy`을(를) 구성할 수 있으므로 Gateway가 각 Workhorse 백엔드로의 TLS 연결을 확인합니다. `workhorse.tls.enabled: true`을(를) 설정하고 배포 수준에서 CA 시크릿을 제공합니다:

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
    deployments:
      api:
        workhorse:
          tls:
            enabled: true
            caSecretName: workhorse-api-tls-ca
```

유효성 검사 호스트명의 기본값은 서비스 DNS 이름(`<service-name>.<namespace>.svc`)입니다. `backendTLSPolicy.hostname`으로 이를 재정의합니다:

```yaml
gitlab:
  webservice:
    backendTLSPolicy:
      hostname: workhorse.example.internal
```

전체 세부사항은 [Gateway API](../../../advanced/gateway-api/_index.md#tls-between-gateway-and-backend-services) 설명서를 참조하세요.

## 리소스 {#resources}

### 메모리 요청/제한 {#memory-requestslimits}

각 포드는 `workerProcesses`과 같은 워커의 수를 생성하고, 각 워커는 기본 메모리 양을 사용합니다. 다음을 권장합니다:

- 워커당 최소 1.25GB (`requests.memory`)
- 워커당 최대 1.5GB, 주요 포드에 1GB 추가 (`limits.memory`)

필요한 리소스는 사용자가 생성한 워크로드에 따라 달라지며 GitLab 애플리케이션의 변경 또는 업그레이드에 따라 향후 변경될 수 있습니다.

기본값:

```yaml
workerProcesses: 2
resources:
  requests:
    memory: 2.5G # = 2 * 1.25G
# limits:
#   memory: 4G   # = (2 * 1.5G) + 950M
```

4명의 워커가 구성된 경우:

```yaml
workerProcesses: 4
resources:
  requests:
    memory: 5G   # = 4 * 1.25G
# limits:
#   memory: 7G   # = (4 * 1.5G) + 950M
```

## 외부 서비스 {#external-services}

### Redis {#redis}

Redis 설명서는 [globals](../../globals.md#configure-redis-settings) 페이지에 통합되었습니다. 최신 Redis 구성 옵션을 보려면 이 페이지를 참조하세요.

### PostgreSQL {#postgresql}

PostgreSQL 설명서는 [globals](../../globals.md#configure-postgresql-settings) 페이지에 통합되었습니다. 최신 PostgreSQL 구성 옵션을 보려면 이 페이지를 참조하세요.

`dependencies` `initContainer`는 Webservice 배포에서 다음을 확인하는 스크립트를 실행합니다:

- GitLab의 종속성을 사용할 수 있는지 여부.
- PostgreSQL의 데이터베이스 마이그레이션이 실행되었는지 여부.

Webservice 차트의 `extraEnv` 구성 키를 사용하여 이 스크립트의 동작을 제어할 수 있습니다. 두 환경 변수가 지원됩니다:

- `BYPASS_POST_DEPLOYMENT=true`: 모든 정규 마이그레이션이 실행되고 배포 후 마이그레이션만 보류 중인 경우 종속성 확인이 통과합니다.
- `BYPASS_SCHEMA_VERSION=true` (권장하지 않음):  일반 마이그레이션이 실행되지 않았더라도 종속성 확인이 통과합니다. 이 환경 변수를 사용하면 데이터베이스 스키마가 애플리케이션 코드의 기대와 일치하지 않기 때문에 Rails 배포가 시작 후 오류로 실행될 수 있습니다.

### Gitaly {#gitaly}

```yaml
global:
  gitaly:
    ## These settings are used by Gitaly clients: GitLab Rails, GitLab Shell, Workhorse.
    client:
      maxAttempts: 4
      maxBackoff: '1.4s'
```

| 이름             |  유형   | 기본값  | 설명                                                                                                                         |
|:-----------------|:-------:|:---------|:------------------------------------------------------------------------------------------------------------------------------------|
| `maxAttempts`    | 정수 | `4`      | 실패 시 Gitaly 클라이언트가 클라이언트에 오류를 반환하기 전에 요청을 다시 전송을 시도할 최대 횟수. |
| `maxBackoff`     | 문자열  | `'1.4s'` | Gitaly 클라이언트가 클라이언트에 오류를 반환하기 전에 요청을 재시도할 최대 시간(초).                  |

다른 Gitaly 설정은 [전역 설정](../../globals.md)으로 구성됩니다. [Gitaly 구성 설명서](../../globals.md#configure-gitaly-settings)를 참조하세요.

### MinIO {#minio}

```yaml
minio:
  serviceName: 'minio-svc'
  port: 9000
```

| 이름          |  유형   | 기본값     | 설명 |
|:--------------|:-------:|:------------|:------------|
| `port`        | 정수 | `9000`      | MinIO `Service`에 도달할 포트 번호. |
| `serviceName` | 문자열  | `minio-svc` | MinIO 포드에서 노출되는 `Service`의 이름. |

### 레지스트리 {#registry}

```yaml
registry:
  host: registry.example.com
  port: 443
  api:
    protocol: http
    host: registry.example.com
    serviceName: registry
    port: 5000
  tokenIssuer: gitlab-issuer
  certificate:
    secret: gitlab-registry
    key: registry-auth.key
```

| 이름                 |  유형   | 기본값         | 설명 |
|:---------------------|:-------:|:----------------|:------------|
| `api.host`           | 문자열  |                 | 사용할 Registry 서버의 호스트 이름. 이를 `api.serviceName` 대신 생략할 수 있습니다. |
| `api.port`           | 정수 | `5000`          | Registry API에 연결할 포트. |
| `api.protocol`       | 문자열  |                 | Webservice가 Registry API에 도달하는 데 사용해야 하는 프로토콜. |
| `api.serviceName`    | 문자열  | `registry`      | Registry 서버를 운영 중인 `service`의 이름. 이것이 존재하고 `api.host`이(가) 없으면 차트가 서비스 호스트 이름 및 현재 `.Release.Name`을(를) `api.host` 값 대신 템플릿화합니다. 이는 Registry를 전체 GitLab 차트의 일부로 사용할 때 편합니다. |
| `certificate.key`    | 문자열  |                 | `key` in `Secret`의 이름으로 [registry](https://hub.docker.com/_/registry/) 컨테이너에 `auth.token.rootcertbundle`로 제공될 인증서 번들을 포함합니다. |
| `certificate.secret` | 문자열  |                 | GitLab 인스턴스에서 생성한 토큰을 확인하는 데 사용할 인증서 번들을 포함하는 [Kubernetes 시크릿](https://kubernetes.io/docs/concepts/configuration/secret/)의 이름. |
| `host`               | 문자열  |                 | GitLab UI에서 사용자에게 Docker 명령을 제공하는 데 사용할 외부 호스트 이름. `registry.hostname` 템플릿에 설정된 값으로 돌아갑니다. `global.hosts`에서 설정된 값에 따라 registry 호스트 이름을 결정합니다. 자세한 내용은 [전역 설명서](../../globals.md)를 참조하세요. |
| `port`               | 정수 |                 | 호스트 이름에서 사용되는 외부 포트. 포트 `80` 또는 `443`를 사용하면 URL이 `http`/`https`로 형성됩니다. 다른 포트는 모두 `http`을 사용하고 호스트 이름 끝에 포트를 추가합니다. 예: `http://registry.example.com:8443`. |
| `tokenIssuer`        | 문자열  | `gitlab-issuer` | Auth 토큰 발급자의 이름. 이는 Registry의 구성에서 사용되는 이름과 일치해야 하며 전송될 때 토큰에 통합됩니다. `gitlab-issuer`의 기본값은 Registry 차트에서 사용하는 기본값과 동일합니다. |

## 차트 설정 {#chart-settings}

다음 값은 Webservice Pod를 구성하는 데 사용됩니다.

| 이름              |  유형   | 기본값 | 설명 |
|:------------------|:-------:|:--------|:------------|
| `workerProcesses` | 정수 | `2`     | 포드당 실행할 Webservice 워커 수. GitLab이 제대로 기능하려면 클러스터에 최소 `2` 워커가 있어야 합니다. `workerProcesses`를 증가하면 워커당 약 `400MB`만큼 필요한 메모리가 증가하므로 포드 `resources`를 이에 따라 업데이트해야 합니다. |
| `minReplicas`     | 정수 | `2`     | 최소 복제본 수 |
| `maxReplicas`     | 정수 | `10`    | 최대 복제본 수 |
| `maxUnavailable`  | 정수 | `1`     | 사용할 수 없는 Pod의 최대 개수 제한 |

### 메트릭 {#metrics}

`metrics.enabled` 값으로 메트릭을 활성화하고 GitLab 모니터링 익스포터를 사용하여 메트릭 포트를 노출합니다. 포드는 Prometheus 어노테이션이 제공되거나 `metrics.serviceMonitor.enabled`이(가) `true`인 경우 Prometheus Operator ServiceMonitor가 생성됩니다. 메트릭을 `/-/metrics` 엔드포인트에서 대신 스크래핑할 수 있지만 이를 위해서는 [GitLab Prometheus 메트릭](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/)이 관리 영역에서 활성화되어야 합니다. GitLab Workhorse 메트릭은 `workhorse.metrics.enabled`을 통해서도 노출될 수 있지만 Prometheus 어노테이션을 사용하여 수집할 수 없으므로 `workhorse.metrics.serviceMonitor.enabled`을 `true`로 설정하거나 외부 Prometheus 구성이 필요합니다.

### GitLab Shell {#gitlab-shell}

GitLab Shell은 Webservice와의 통신에서 Auth 토큰을 사용합니다. 공유 시크릿을 사용하여 GitLab Shell과 Webservice 간 토큰을 공유합니다.

```yaml
shell:
  authToken:
    secret: gitlab-shell-secret
    key: secret
  port:
```

| 이름               |  유형   | 기본값 | 설명 |
|:-------------------|:-------:|:--------|:------------|
| `authToken.key`    | 문자열  |         | authToken을 포함하는 시크릿(아래)의 키 이름을 정의합니다. |
| `authToken.secret` | 문자열  |         | 끌어올 Kubernetes `Secret`의 이름을 정의합니다. |
| `port`             | 정수 | `22`    | GitLab UI 내에서 SSH URL 생성에 사용할 포트 번호. `global.shell.port`에 의해 제어됨. |

### WebServer 옵션 {#webserver-options}

현재 차트 버전은 Puma 웹 서버를 지원합니다.

Puma 고유 옵션:

| 이름                   |  유형   | 기본값 | 설명 |
|:-----------------------|:-------:|:--------|:------------|
| `puma.workerMaxMemory` | 정수 |         | Puma 워커 killer의 최대 메모리(메가바이트) |
| `puma.threads.min`     | 정수 | `4`     | Puma 스레드의 최소 개수 |
| `puma.threads.max`     | 정수 | `4`     | Puma 스레드의 최대 개수 |

### Workhorse 로드 셰딩 {#workhorse-load-shedding}

{{< history >}}

- GitLab 18.9에서 [도입되었습니다](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/work_items/28055).
- `statusCode` 매개변수는 GitLab 18.10에서 [추가되었습니다](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225993).

{{< /history >}}

로드 셰딩은 요청 백로그가 구성된 임계값을 초과할 때 구성된 HTTP 상태 코드를 반환하여 Puma이 과부하되지 않도록 보호하고 역방향 프록시가 다른 인스턴스로 요청을 재시도할 수 있도록 합니다.

로드 셰딩을 활성화하려면 `loadShedding` 매개변수를 구성하세요:

```yaml
gitlab:
  webservice:
    workhorse:
      loadShedding:
        enabled: true
        backlogThreshold: 50
        retryAfterSeconds: 0
        statusCode: 503
        strategy: max
```

- `backlogThreshold`은(는) 로드 셰딩을 트리거하는 백로그된 요청의 수를 지정합니다.
- `retryAfterSeconds`은(는) 응답의 `Retry-After` 헤더에 대한 값을 설정합니다.
- `statusCode`은(는) 로드 셰딩 시 반환할 HTTP 상태 코드를 설정합니다(기본값: `503`). `529`와(과) 같은 사용자 지정 코드를 사용하여 로드 셰딩 응답과 데이터베이스 시간 초과 또는 Gitaly 문제로 인한 다른 `503` 오류를 구분합니다.
- `strategy`은(는) 효과적인 백로그를 계산하는 방식을 결정합니다:
  - `max`: 모든 Puma 워커의 최대 백로그를 사용합니다(기본값).
  - `sum`: 모든 Puma 워커의 백로그 합계를 사용합니다.

#### 프록시 구성 {#proxy-configuration}

로드 셰딩이 효과적으로 작동하려면 역방향 프록시가 `503` 응답을 받을 때 요청을 재시도하도록 구성되어야 합니다. 이렇게 하면 요청이 정상 인스턴스에 분배됩니다.

NGINX 예제의 경우 Ingress에서 다음 주석을 구성하세요:

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/proxy-next-upstream: "http_503"
    nginx.ingress.kubernetes.io/proxy-next-upstream-tries: "3"
    nginx.ingress.kubernetes.io/proxy-next-upstream-timeout: "10s"
```

이 설정은 NGINX에 다음을 지시합니다:

- `503` 응답에서 재시도합니다(로드 셰딩이 생성함).
- 포기하기 전에 최대 3번 시도합니다.
- 재시도를 위해 최대 10초 대기합니다.

`503` 응답에서만 재시도해야 하며, 이는 로드 셰딩이 생성하는 특정 신호입니다. `504`(게이트웨이 시간 초과) 또는 오류 조건과 같은 다른 상태 코드에서의 재시도를 피하세요. 이는 모든 백엔드에서 실패할 수 있는 요청을 재시도하여 중단 중에 로드를 증폭시킬 수 있습니다.

다른 역방향 프록시의 경우 동등한 재시도 구성에 대한 설명서를 참조하세요. 핵심은 `503` 응답이 다른 백엔드 인스턴스로의 재시도를 트리거하도록 하는 것입니다.

## `networkpolicy` 구성 {#configuring-the-networkpolicy}

이 섹션은 [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)를 제어합니다. 이 구성은 선택 사항이며 포드의 Egress 및 Ingress를 특정 엔드포인트로 제한하는 데 사용됩니다.

| 이름              |  유형   | 기본값 | 설명 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | 부울 | `false` | 이 설정은 `NetworkPolicy`을 활성화합니다 |
| `ingress.enabled` | 부울 | `false` | `true`로 설정하면 `Ingress` 네트워크 정책이 활성화됩니다. 규칙을 지정하지 않으면 모든 Ingress 연결이 차단됩니다. |
| `ingress.rules`   |  배열  | `[]`    | Ingress 정책에 대한 규칙, 자세한 내용은 <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> 및 아래 예제를 참조하세요 |
| `egress.enabled`  | 부울 | `false` | `true`로 설정하면 `Egress` 네트워크 정책이 활성화됩니다. 규칙을 지정하지 않으면 모든 egress 연결이 차단됩니다. |
| `egress.rules`    |  배열  | `[]`    | egress 정책에 대한 규칙, 자세한 내용은 <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> 및 아래 예제를 참조하세요 |

### 예제 네트워크 정책 {#example-network-policy}

webservice 서비스는 Prometheus 내보내기(활성화된 경우)의 Ingress 연결, NGINX Ingress에서 오는 트래픽 및 여러 GitLab Pod이 필요합니다. 일반적으로 다양한 위치로의 Egress 연결이 필요합니다. 이 예제는 다음 네트워크 정책을 추가합니다:

- Ingress 요청 허용:
  - `gitaly`, `gitlab-pages`, `gitlab-shell`, `kas`, `mailroom` 및 `nginx-ingress` Pod에서 포트 `8181`로
  - `Prometheus` Pod에서 포트 `8080`, `8083` 및 `9229`로
- Egress 요청 허용:
  - `gitaly` 포드에서 `8075`포트로
  - `kas` 포드에서 `8153`포트로
  - `kube-dns`에서 `53`포트로
  - `registry` 포드에서 `5000`포트로
  - 외부 데이터베이스 `172.16.0.10/32`에서 `5432`포트로
  - 외부 Redis `172.16.0.11/32`에서 `6379`포트로
  - 인터넷 `0.0.0.0/0`에서 포트 `443`로
  - AWS VPC 엔드포인트(S3 또는 STS용) `172.16.1.0/24`과 같은 엔드포인트에서 `443`포트로

제공된 예제는 단지 예제일 뿐이며 완전하지 않을 수 있습니다. Webservice는 [외부 객체 저장소](../../../advanced/external-object-storage)의 이미지를 위해 공개 인터넷으로의 아웃바운드 연결이 필요합니다. 이 예제는 `kube-dns`이 네임스페이스 `kube-system`에 배포되었고, `prometheus`이 네임스페이스 `monitoring`에 배포되었으며, `nginx-ingress`가 네임스페이스 `nginx-ingress`에 배포되었다는 가정을 기반으로 합니다.

```yaml
networkpolicy:
  enabled: true
  ingress:
    enabled: true
    rules:
      - from:
          - podSelector:
              matchLabels:
                app: gitaly
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: gitlab-pages
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: gitlab-shell
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: kas
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: mailroom
        ports:
          - port: 8181
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 8181
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
          - port: 9229
          - port: 8080
          - port: 8083
  egress:
    enabled: true
    rules:
      - to:
          - podSelector:
              matchLabels:
                app: gitaly
        ports:
          - port: 8075
      - to:
          - podSelector:
              matchLabels:
                app: kas
        ports:
          - port: 8153
      - to:
          - ipBlock:
              cidr: 0.0.0.0/0
              except:
                - 10.0.0.0/8
        ports:
          - port: 443
      - to:
          - ipBlock:
              cidr: 172.16.0.10/32
        ports:
          - port: 5432
      - to:
          - ipBlock:
              cidr: 172.16.0.11/32
        ports:
          - port: 6379
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
```

### `LoadBalancer` 서비스 {#loadbalancer-service}

`service.type`이(가) `LoadBalancer`(으)로 설정되어 있으면 `service.loadBalancerIP`을(를) 선택적으로 지정하여 클라우드 제공자가 지원하는 경우 사용자 지정 IP를 사용하는 `LoadBalancer`(을)를 생성할 수 있습니다.

`service.type`이(가) `LoadBalancer`(으)로 설정되어 있으면 `service.loadBalancerSourceRanges`을(를) 설정하여 클라우드 제공자가 지원하는 경우 `LoadBalancer`에 액세스할 수 있는 CIDR 범위를 제한해야 합니다. 이는 현재 [메트릭 포트가 노출된](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2500) 문제로 인해 필요합니다.

`LoadBalancer` 서비스 유형에 대한 추가 정보는 [Kubernetes 설명서](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)에서 찾을 수 있습니다

```yaml
service:
  type: LoadBalancer
  loadBalancerIP: 1.2.3.4
  loadBalancerSourceRanges:
  - 10.0.0.0/8
```

## KEDA 구성 {#configuring-keda}

이 `keda` 섹션은 [KEDA](https://keda.sh/) `ScaledObjects`의 설치를 일반 `HorizontalPodAutoscalers` 대신 활성화합니다. 이 구성은 선택 사항이며 사용자 지정 또는 외부 메트릭을 기반으로 자동 크기 조정이 필요할 때 사용할 수 있습니다.

대부분의 설정은 `hpa` 섹션에 설정된 값으로 기본값을 설정합니다.

다음이 참이면 `hpa` 섹션에 설정된 CPU 및 메모리 임계값을 기반으로 CPU 및 메모리 트리거가 자동으로 추가됩니다:

- `triggers`이 설정되지 않았습니다.
- 해당 `request.cpu.request` 또는 `request.memory.request` 설정도 0이 아닌 값으로 설정됩니다.

트리거가 설정되지 않으면 `ScaledObject`은 생성되지 않습니다.

[KEDA 설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/)를 참조하여 이러한 설정에 대한 자세한 내용을 확인하세요.

| 이름                            |  유형   | 기본값                         | 설명 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | 부울 | `false`                         | [KEDA](https://keda.sh/) `ScaledObjects`를 `HorizontalPodAutoscalers` 대신 사용합니다 |
| `pollingInterval`               | 정수 | `30`                            | 각 트리거를 확인하는 간격 |
| `cooldownPeriod`                | 정수 | `300`                           | 마지막 트리거가 활성으로 보고된 후 리소스를 0으로 다시 스케일링할 때까지 기다릴 기간 |
| `minReplicaCount`               | 정수 | `minReplicas`                   | KEDA가 리소스를 축소할 최소 복제본 수입니다. |
| `maxReplicaCount`               | 정수 | `maxReplicas`                   | KEDA가 리소스를 확장할 최대 복제본 수입니다. |
| `fallback`                      |   맵   |                                 | KEDA 폴백 구성, [설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)를 참조하세요 |
| `hpaName`                       | 문자열  | `keda-hpa-{scaled-object-name}` | KEDA가 생성할 HPA 리소스의 이름입니다. |
| `restoreToOriginalReplicaCount` | 부울 |                                 | `ScaledObject`이 삭제된 후 대상 리소스를 원래 복제본 수로 다시 스케일링할지 여부를 지정합니다 |
| `behavior`                      |   맵   | `hpa.behavior`                  | 상향 및 하향 스케일링 동작의 사양입니다. |
| `triggers`                      |  배열  |                                 | 대상 리소스의 스케일링을 활성화할 트리거 목록, `hpa.cpu` 및 `hpa.memory`에서 계산된 트리거로 기본값 |
