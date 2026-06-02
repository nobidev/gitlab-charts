---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab-Sidekiq 차트 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

`sidekiq` 서브 차트는 Sidekiq 워커의 구성 가능한 배포를 제공하며, 개별 확장성과 구성을 통해 여러 `Deployment`에 걸쳐 큐의 분리를 제공하도록 명시적으로 설계되었습니다.

이 차트는 기본 `pods:` 선언을 제공하지만, 빈 정의를 제공하면 *워커가 없을* 것입니다.

## 요구 사항 {#requirements}

이 차트는 이 차트가 배포되는 Kubernetes 클러스터에서 도달 가능한 외부 서비스로 제공되는 Redis, PostgreSQL 및 Gitaly 서비스에 대한 액세스에 따라 다릅니다.

## 설계 선택 사항 {#design-choices}

이 차트는 여러 `Deployment`과 관련된 `ConfigMap`을 생성합니다. `ConfigMap` 동작을 사용하는 것이 더 명확할 것으로 결정되었으며, 컨테이너에 대해 `environment` 속성이나 `command`에 대한 추가 인수를 사용하는 대신, 명령 길이에 대한 우려를 피하기 위해 결정되었습니다. 이 선택으로 인해 많은 수의 `ConfigMap`이 발생하지만, 각 Pod이 수행해야 하는 작업에 대한 매우 명확한 정의를 제공합니다.

## 구성 {#configuration}

`sidekiq` 차트는 세 부분으로 구성됩니다: 차트 전체 [외부 서비스](#external-services) , [차트 전체 기본값](#chart-wide-defaults) 및 [Pod별 정의](#per-pod-settings).

## 설치 명령줄 옵션 {#installation-command-line-options}

아래 표에는 `helm install` 명령에 `--set` 플래그를 사용하여 제공할 수 있는 모든 가능한 차트 구성이 포함되어 있습니다:

| 매개변수                                                | 기본값                                                      | 설명 |
|----------------------------------------------------------|--------------------------------------------------------------|-------------|
| `annotations`                                            |                                                              | 포드 주석 |
| `podLabels`                                              |                                                              | 보충 포드 레이블입니다. 선택기에 사용되지 않습니다. |
| `common.labels`                                          |                                                              | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `concurrency`                                            | `20`                                                         | Sidekiq 기본 동시성 |
| `deployment.strategy`                                    | `{}`                                                         | 배포에서 사용할 업데이트 전략을 구성할 수 있습니다 |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                         | Pod이 정상적으로 종료되어야 하는 선택적 기간(초). |
| `enabled`                                                | `true`                                                       | Sidekiq 활성화 플래그 |
| `extraContainers`                                        |                                                              | 포함할 컨테이너 목록을 포함하는 여러 줄 리터럴 스타일 문자열 |
| `extraInitContainers`                                    |                                                              | 포함할 추가 init 컨테이너 목록 |
| `extraVolumeMounts`                                      |                                                              | 구성할 추가 볼륨 마운트의 문자열 템플릿 |
| `extraVolumes`                                           |                                                              | 구성할 추가 볼륨의 문자열 템플릿 |
| `extraEnv`                                               |                                                              | 노출할 추가 환경 변수 목록 |
| `extraEnvFrom`                                           |                                                              | 다른 데이터 소스에서 노출할 추가 환경 변수 목록 |
| `gitaly.serviceName`                                     | `gitaly`                                                     | Gitaly 서비스 이름 |
| `health_checks.port`                                     | `3808`                                                       | 상태 확인 서버 포트 |
| `health_checks.listenAddr`                               | `*`                                                          | 상태 확인 수신 주소. |
| `hpa.behaviour`                                          | `{scaleDown: {stabilizationWindowSeconds: 300 }}`            | 동작은 상향 및 하향 스케일링 동작의 사양을 포함합니다(`autoscaling/v2beta2` 이상 필요). |
| `hpa.customMetrics`                                      | `[]`                                                         | 사용자 정의 메트릭은 원하는 복제본 수를 계산하는 데 사용할 사양을 포함합니다(`targetAverageUtilization`에 구성된 평균 CPU 활용률의 기본 사용을 재정의함). |
| `hpa.cpu.targetType`                                     | `AverageValue`                                               | 자동 스케일링 CPU 대상 유형을 설정하고, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.cpu.targetAverageValue`                             | `350m`                                                       | 자동 스케일링 CPU 대상 값을 설정합니다 |
| `hpa.cpu.targetAverageUtilization`                       |                                                              | 자동 스케일링 CPU 대상 활용률을 설정합니다 |
| `hpa.memory.targetType`                                  |                                                              | 자동 스케일링 메모리 대상 유형을 설정하고, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.memory.targetAverageValue`                          |                                                              | 자동 스케일링 메모리 대상 값을 설정합니다 |
| `hpa.memory.targetAverageUtilization`                    |                                                              | 자동 스케일링 메모리 대상 활용률을 설정합니다 |
| `hpa.targetAverageValue`                                 |                                                              | **DEPRECATED** 자동 스케일링 CPU 대상 값을 설정합니다 |
| `keda.enabled`                                           | `false`                                                      | [KEDA](https://keda.sh/) `ScaledObjects`를 `HorizontalPodAutoscalers` 대신 사용합니다 |
| `keda.pollingInterval`                                   | `30`                                                         | 각 트리거를 확인하는 간격 |
| `keda.cooldownPeriod`                                    | `300`                                                        | 마지막 트리거가 활성으로 보고된 후 리소스를 0으로 다시 스케일링할 때까지 기다릴 기간 |
| `keda.minReplicaCount`                                   |                                                              | KEDA가 리소스를 축소할 최소 복제본 수이며, `minReplicas`로 기본값 |
| `keda.maxReplicaCount`                                   |                                                              | KEDA가 리소스를 확대할 최대 복제본 수이며, `maxReplicas`로 기본값 |
| `keda.fallback`                                          |                                                              | KEDA 폴백 구성, [설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)를 참조하세요 |
| `keda.hpaName`                                           |                                                              | KEDA가 생성할 HPA 리소스의 이름이며, `keda-hpa-{scaled-object-name}`로 기본값 |
| `keda.restoreToOriginalReplicaCount`                     |                                                              | `ScaledObject`이 삭제된 후 대상 리소스를 원래 복제본 수로 다시 스케일링할지 여부를 지정합니다 |
| `keda.behavior`                                          |                                                              | 상향 및 하향 스케일링 동작에 대한 사양이며, `hpa.behavior`로 기본값 |
| `keda.triggers`                                          |                                                              | 대상 리소스의 스케일링을 활성화할 트리거 목록, `hpa.cpu` 및 `hpa.memory`에서 계산된 트리거로 기본값 |
| `minReplicas`                                            | `2`                                                          | 최소 복제본 수 |
| `maxReplicas`                                            | `10`                                                         | 최대 복제본 수 |
| `maxUnavailable`                                         | `1`                                                          | 사용할 수 없는 Pod의 최대 개수 제한 |
| `image.pullPolicy`                                       | `Always`                                                     | Sidekiq 이미지 풀 정책 |
| `image.pullSecrets`                                      |                                                              | 이미지 저장소의 비밀 |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ee` | Sidekiq 이미지 저장소 |
| `image.tag`                                              |                                                              | Sidekiq 이미지 태그 |
| `init.image.repository`                                  |                                                              | initContainer 이미지 |
| `init.image.tag`                                         |                                                              | initContainer 이미지 태그 |
| `init.containerSecurityContext`                          |                                                              | initContainer 특정 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                       | initContainer 특정:  컨테이너를 시작해야 하는 사용자 ID |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | initContainer 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                       | initContainer 특정:  컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                  | initContainer 특정:  컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `logging.format`                                         | `json`                                                       | JSON이 아닌 로그의 경우 `text`로 설정합니다 |
| `metrics.enabled`                                        | `true`                                                       | 메트릭 엔드포인트를 스크래핑할 수 있도록 해야 하는지 여부 |
| `metrics.port`                                           | `3807`                                                       | 메트릭 엔드포인트 포트 |
| `metrics.listenAddr`                                     | `*`                                                          | 메트릭 엔드포인트 수신 주소. |
| `metrics.path`                                           | `/metrics`                                                   | 메트릭 엔드포인트 경로 |
| `metrics.log_enabled`                                    | `false`                                                      | `sidekiq_exporter.log`에 작성된 메트릭 서버 로그를 활성화하거나 비활성화합니다 |
| `metrics.podMonitor.enabled`                             | `false`                                                      | Prometheus Operator가 메트릭 스크래핑을 관리할 수 있도록 PodMonitor를 생성해야 하는지 여부 |
| `metrics.podMonitor.additionalLabels`                    | `{}`                                                         | PodMonitor에 추가할 추가 레이블 |
| `metrics.podMonitor.endpointConfig`                      | `{}`                                                         | PodMonitor에 대한 추가 엔드포인트 구성 |
| `metrics.annotations`                                    |                                                              | **DEPRECATED** 명시적 메트릭 주석을 설정합니다. 템플릿 콘텐츠로 대체됩니다. |
| `metrics.tls.enabled`                                    | `false`                                                      | `metrics/sidekiq_exporter` 엔드포인트에 대해 TLS를 활성화했습니다 |
| `metrics.tls.secretName`                                 | `{Release.Name}-sidekiq-metrics-tls`                         | `metrics/sidekiq_exporter` 엔드포인트 TLS 인증서 및 키의 비밀 |
| `psql.password.key`                                      | `psql-password`                                              | psql 비밀의 psql 암호에 대한 키 |
| `psql.password.secret`                                   | `gitlab-postgres`                                            | psql 암호 비밀 |
| `psql.port`                                              |                                                              | PostgreSQL 서버 포트를 설정합니다. `global.psql.port`보다 우선합니다. |
| `resources.requests.cpu`                                 | `900m`                                                       | Sidekiq 최소 필요 CPU |
| `resources.requests.memory`                              | `2G`                                                         | Sidekiq 최소 필요 메모리 |
| `resources.limits.memory`                                |                                                              | Sidekiq 최대 허용 메모리 |
| `timeout`                                                | `25`                                                         | Sidekiq 작업 시간 제한 |
| `tolerations`                                            | `[]`                                                         | 포드 할당을 위한 용인 레이블 |
| `memoryKiller.daemonMode`                                | `true`                                                       | `false`이면 레거시 메모리 킬러 모드를 사용합니다 |
| `memoryKiller.maxRss`                                    | `2000000`                                                    | 지연된 종료가 트리거되기 전의 최대 RSS(킬로바이트 단위) |
| `memoryKiller.graceTime`                                 | `900`                                                        | 종료 트리거 전에 대기할 시간(초 단위) |
| `memoryKiller.shutdownWait`                              | `30`                                                         | 종료 트리거 후 기존 작업이 완료되는 데 걸리는 시간(초 단위) |
| `memoryKiller.hardLimitRss`                              |                                                              | 데몬 모드에서 즉시 종료가 트리거되기 전의 최대 RSS(킬로바이트 단위) |
| `memoryKiller.checkInterval`                             | `3`                                                          | 메모리 확인 사이의 시간 |
| `livenessProbe.initialDelaySeconds`                      | `20`                                                         | 생동성 프로브가 시작되기 전의 지연 |
| `livenessProbe.periodSeconds`                            | `60`                                                         | 생동성 프로브를 수행하는 빈도 |
| `livenessProbe.timeoutSeconds`                           | `30`                                                         | 생동성 프로브 시간이 초과될 때 |
| `livenessProbe.successThreshold`                         | `1`                                                          | 생동성 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `livenessProbe.failureThreshold`                         | `3`                                                          | 생동성 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `readinessProbe.initialDelaySeconds`                     | `0`                                                          | 준비 프로브가 시작되기 전의 지연 |
| `readinessProbe.periodSeconds`                           | `10`                                                         | 준비 프로브를 수행하는 빈도 |
| `readinessProbe.timeoutSeconds`                          | `2`                                                          | 준비 프로브 시간이 초과될 때 |
| `readinessProbe.successThreshold`                        | `1`                                                          | 준비 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `readinessProbe.failureThreshold`                        | `3`                                                          | 준비 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `securityContext.fsGroup`                                | `1000`                                                       | 포드를 시작해야 하는 그룹 ID |
| `securityContext.runAsUser`                              | `1000`                                                       | 포드를 시작해야 하는 사용자 ID |
| `securityContext.fsGroupChangePolicy`                    |                                                              | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                             | 사용할 Seccomp 프로필 |
| `containerSecurityContext`                               |                                                              | 컨테이너가 시작되는 컨테이너 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)를 재정의합니다 |
| `containerSecurityContext.runAsUser`                     | `1000`                                                       | 컨테이너가 시작되는 특정 보안 컨텍스트를 덮어쓸 수 있습니다 |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                      | 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                       | 컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                  | Gitaly 컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `serviceAccount.annotations`                             | `{}`                                                         | ServiceAccount 주석 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                      | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다 |
| `serviceAccount.create`                                  | `false`                                                      | ServiceAccount를 생성해야 하는지 여부를 나타냅니다 |
| `serviceAccount.enabled`                                 | `false`                                                      | ServiceAccount를 사용해야 하는지 여부를 나타냅니다 |
| `serviceAccount.name`                                    |                                                              | ServiceAccount의 이름입니다. 설정하지 않으면 전체 차트 이름이 사용됩니다 |
| `priorityClassName`                                      | `""`                                                         | 포드 `priorityClassName`을(를) 구성할 수 있습니다. 이는 제거 시 포드 우선순위를 제어하는 데 사용됩니다. |
| `antiAffinity`                                           | `""`                                                         | 차트 전역 값의 antiAffinity 값을 덮어쓸 수 있습니다. 기본값은 전역에서 읽혀지며 `soft` 또는 `hard`로 설정할 수 있습니다. |

## 차트 구성 예시 {#chart-configuration-examples}

### 리소스 {#resources}

`resources`을(를) 사용하면 Sidekiq Pod이 사용할 수 있는 리소스(메모리 및 CPU)의 최소 및 최대 양을 구성할 수 있습니다.

Sidekiq Pod 워크로드는 배포 간에 크게 다릅니다. 일반적으로 각 Sidekiq 프로세스는 약 1vCPU와 2GB의 메모리를 소비하는 것으로 이해됩니다. 수직 확장은 일반적으로 이 `1:2` `vCPU:Memory` 비율에 맞춰야 합니다.

다음은 `resources`의 예시 사용입니다:

```yaml
resources:
  limits:
    memory: 5G
  requests:
    memory: 2G
    cpu: 900m
```

### extraEnv {#extraenv}

`extraEnv`을 사용하여 종속성 컨테이너에서 추가 환경 변수를 노출합니다.

예를 들어 `SOME_KEY` 및 `SOME_OTHER_KEY` 환경 변수를 노출하려면:

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

컨테이너가 시작되면 `env` 명령을 실행하고 변수의 이름을 그리핑하여 환경 변수가 노출되었는지 확인합니다. 예를 들어:

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

특정 Pod에 대해 `extraEnv`을 설정할 수도 있습니다. 예를 들어:

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
pods:
  - name: mailers
    queues: mailers
    extraEnv:
      SOME_POD_KEY: some_pod_value
  - name: catchall
```

이렇게 하면 `SOME_POD_KEY`이 `mailers` Pod의 애플리케이션 컨테이너에만 설정됩니다. Pod 수준 `extraEnv` 설정은 [초기 컨테이너](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)에 추가되지 않습니다.

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`을(를) 사용하면 포드의 모든 컨테이너에서 다른 데이터 소스의 추가 환경 변수를 노출할 수 있습니다. 이후 변수는 Sidekiq Pod별로 재정의할 수 있습니다.

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
pods:
  - name: immediate
    extraEnvFrom:
      CONFIG_STRING:
        configMapKeyRef:
          name: useful-config
          key: some-string
          # optional: boolean
```

### extraVolumes {#extravolumes}

`extraVolumes`을 사용하면 차트 전체에서 추가 볼륨을 구성할 수 있습니다.

다음은 `extraVolumes`의 예시 사용입니다:

```yaml
extraVolumes: |
  - name: example-volume
    persistentVolumeClaim:
      claimName: example-pvc
```

### extraVolumeMounts {#extravolumemounts}

`extraVolumeMounts`을 사용하면 차트 전체에 모든 컨테이너에서 추가 volumeMounts를 구성할 수 있습니다.

다음은 `extraVolumeMounts`의 예시 사용입니다:

```yaml
extraVolumeMounts: |
  - name: example-volume-mount
    mountPath: /etc/example
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets`을(를) 사용하면 개인 레지스트리에 인증하여 포드의 이미지를 가져올 수 있습니다.

개인 레지스트리 및 해당 인증 방법에 대한 추가 세부사항은 [Kubernetes 설명서](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)에서 찾을 수 있습니다.

다음은 `pullSecrets`의 예시 사용입니다:

```yaml
image:
  repository: my.sidekiq.repository
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

### 주석 {#annotations}

`annotations`을(를) 사용하면 Sidekiq Pod에 주석을 추가할 수 있습니다.

다음은 `annotations`의 예시 사용입니다:

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## 이 차트의 Community Edition 사용 {#using-the-community-edition-of-this-chart}

기본적으로 Helm 차트는 GitLab Enterprise Edition을 사용합니다. 원하는 경우 Community Edition을 대신 사용할 수 있습니다. [두 가지 간의 차이점](https://about.gitlab.com/install/ce-or-ee/)에 대해 자세히 알아보세요.

커뮤니티 에디션을 사용하려면 `image.repository`을 `registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ce`로 설정하세요.

## 외부 서비스 {#external-services}

이 차트는 Webservice 차트와 동일한 Redis, PostgreSQL 및 Gitaly 인스턴스에 연결되어야 합니다. 외부 서비스의 값은 모든 Sidekiq Pod에서 공유되는 `ConfigMap`에 채워집니다.

### Redis {#redis}

```yaml
redis:
  host: rank-racoon-redis
  port: 6379
  sentinels:
    - host: sentinel1.example.com
      port: 26379
      ssl: false
  password:
    secret: gitlab-redis
    key: redis-password
```

| 이름                |  유형   | 기본값 | 설명 |
|:--------------------|:-------:|:--------|:------------|
| `host`              | 문자열  |         | 사용할 데이터베이스가 있는 Redis 서버의 호스트 이름입니다. Redis Sentinels를 사용하는 경우 `host` 속성을 `sentinel.conf`에 지정된 클러스터 이름으로 설정해야 합니다. |
| `password.key`      | 문자열  |         | Redis의 `password.key` 속성은 암호를 포함하는 보안 (아래)의 키 이름을 정의합니다. |
| `password.secret`   | 문자열  |         | Redis의 `password.secret` 속성은 가져올 Kubernetes `Secret`의 이름을 정의합니다. |
| `port`              | 정수 | `6379`  | Redis 서버에 연결할 포트입니다. |
| `sentinels.[].host` | 문자열  |         | Redis HA 설정을 위한 Redis Sentinel 서버의 호스트 이름. |
| `sentinels.[].port` | 정수 | `26379` | Redis Sentinel 서버에 연결할 포트. |

### PostgreSQL {#postgresql}

```yaml
psql:
  host: rank-racoon-psql
  port: 5432
  database: gitlabhq_production
  username: gitlab
  preparedStatements: false
  password:
    secret: gitlab-postgres
    key: psql-password
```

| 이름                 |  유형   | 기본값               | 설명 |
|:---------------------|:-------:|:----------------------|:------------|
| `host`               | 문자열  |                       | 사용할 데이터베이스가 있는 PostgreSQL 서버의 호스트 이름입니다. |
| `database`           | 문자열  | `gitlabhq_production` | PostgreSQL 서버에서 사용할 데이터베이스의 이름입니다. |
| `password.key`       | 문자열  |                       | PostgreSQL의 `password.key` 속성은 암호를 포함하는 보안 (아래)의 키 이름을 정의합니다. |
| `password.secret`    | 문자열  |                       | PostgreSQL의 `password.secret` 속성은 가져올 Kubernetes `Secret`의 이름을 정의합니다. |
| `port`               | 정수 | `5432`                | PostgreSQL 서버에 연결할 포트입니다. |
| `username`           | 문자열  | `gitlab`              | 데이터베이스에 인증할 사용자 이름입니다. |
| `preparedStatements` | 부울 | `false`               | PostgreSQL 서버와의 통신 시 준비된 명령문을 사용할지 여부입니다. |

`dependencies` `initContainer` in Sidekiq 배포는 다음을 확인하는 스크립트를 실행합니다:

- GitLab의 종속성을 사용할 수 있는지 여부.
- PostgreSQL의 데이터베이스 마이그레이션이 실행되었는지 여부.

Sidekiq 차트의 `extraEnv` 구성 키를 사용하여 이러한 스크립트의 동작을 제어할 수 있습니다. 두 환경 변수가 지원됩니다:

- `BYPASS_POST_DEPLOYMENT=true`: 모든 정규 마이그레이션이 실행되고 배포 후 마이그레이션만 보류 중인 경우 종속성 확인이 통과합니다.
- `BYPASS_SCHEMA_VERSION=true` (권장하지 않음):  일반 마이그레이션이 실행되지 않았더라도 종속성 확인이 통과합니다. 이 환경 변수를 사용하면 데이터베이스 스키마가 애플리케이션 코드의 기대와 일치하지 않기 때문에 Rails 배포가 시작 후 오류로 실행될 수 있습니다.

### Gitaly {#gitaly}

```yaml
gitaly:
  internal:
    names:
      - default
      - default2
  external:
    - name: node1
      hostname: node1.example.com
      port: 8079
  authToken:
    secret: gitaly-secret
    key: token
```

| 이름               |  유형   | 기본값  | 설명 |
|:-------------------|:-------:|:---------|:------------|
| `host`             | 문자열  |          | 사용할 Gitaly 서버의 호스트 이름. 이를 `serviceName` 대신 생략할 수 있습니다. |
| `serviceName`      | 문자열  | `gitaly` | Gitaly 서버를 운영하는 `service`의 이름. 이것이 존재하고 `host`이(가) 없으면 차트가 서비스 호스트 이름 및 현재 `.Release.Name`을(를) `host` 값 대신 템플릿화합니다. 이는 GitLab 차트 전체의 일부로 Gitaly를 사용할 때 편리합니다. |
| `port`             | 정수 | `8075`   | Gitaly 서버에 연결할 포트. |
| `authToken.key`    | 문자열  |          | authToken을 포함하는 아래 보안의 키 이름. |
| `authToken.secret` | 문자열  |          | 가져올 Kubernetes `Secret`의 이름입니다. |

## 메트릭 {#metrics}

기본적으로 Prometheus 메트릭 내보내기가 Pod별로 활성화됩니다. 메트릭은 관리자 영역에서 [GitLab Prometheus 메트릭](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/)이 활성화된 경우에만 사용 가능합니다. 내보내기 프로그램은 포트 `3807`에서 `/metrics` 엔드포인트를 노출합니다. 메트릭이 활성화되면 각 포드에 주석이 추가되어 Prometheus 서버가 노출된 메트릭을 검색하고 스크래핑할 수 있습니다.

## 차트 전체 기본값 {#chart-wide-defaults}

다음 값은 Pod별 기반에서 값이 표시되지 않는 경우 차트 전체에서 사용됩니다.

| 이름                         |  유형   | 기본값   | 설명 |
|:-----------------------------|:-------:|:----------|:------------|
| `concurrency`                | 정수 | `25`      | 동시에 처리할 작업 수. |
| `timeout`                    | 정수 | `4`       | Sidekiq 종료 시간 제한. Sidekiq가 TERM 신호를 받은 후 프로세스를 강제 종료하기 전의 시간(초). |
| `memoryKiller.checkInterval` | 정수 | `3`       | 메모리 확인 사이의 시간(초 단위) |
| `memoryKiller.maxRss`        | 정수 | `2000000` | 지연된 종료가 트리거되기 전의 최대 RSS(킬로바이트 단위) |
| `memoryKiller.graceTime`     | 정수 | `900`     | 종료 트리거 전에 대기할 시간(초 단위) |
| `memoryKiller.shutdownWait`  | 정수 | `30`      | 종료 트리거 후 기존 작업이 완료되는 데 걸리는 시간(초 단위) |
| `minReplicas`                | 정수 | `2`       | 최소 복제본 수 |
| `maxReplicas`                | 정수 | `10`      | 최대 복제본 수 |
| `maxUnavailable`             | 정수 | `1`       | 사용할 수 없는 Pod의 최대 개수 제한 |

> [!note]
> [Sidekiq 메모리 킬러의 자세한 문서를 사용할 수 있습니다](https://docs.gitlab.com/administration/sidekiq/sidekiq_memory_killer/) Linux 패키지 문서에서.

## HPA 확장 비활성화 {#disable-hpa-scaling}

기본적으로 Sidekiq 차트는 CPU 활용률을 기반으로 Pod을 자동으로 확장하기 위해 수평 Pod 자동 확장(HPA)을 활성화합니다. HPA 확장을 비활성화하고 대신 고정 복제본 수를 사용하려면 `minReplicas`을 `maxReplicas`과 같게 설정하여 모든 Pod에 대해 HPA를 비활성화하세요:

```yaml
gitlab:
  sidekiq:
    minReplicas: 3
    maxReplicas: 3  # Setting equal to minReplicas disables HPA scaling
    concurrency: 25
    pods:
      - name: default
```

## Pod별 설정 {#per-pod-settings}

`pods` 선언은 워커 Pod의 모든 속성 선언을 제공합니다. 이들은 `Deployment`로 템플릿화되며, Sidekiq 인스턴스에 대해 개별 `ConfigMap`이 포함됩니다.

[!note]
> 설정은 모든 큐를 모니터링하도록 설정된 단일 Pod을 포함하도록 기본값을 설정합니다. Pod 섹션을 변경하면 *기본 Pod을 덮어씁니다* 다른 Pod 구성으로. 기본값 외에 새 Pod을 추가하지 않습니다.

| 이름                                  |  유형   | 기본값        | 설명 |
|:--------------------------------------|:-------:|:---------------|:------------|
| `concurrency`                         | 정수 |                | 동시에 처리할 작업 수. 제공되지 않으면 차트 전체 기본값에서 가져옵니다. |
| `name`                                | 문자열  |                | 이 Pod에 대해 `Deployment` 및 `ConfigMap`의 이름을 지정하는 데 사용됩니다. 짧게 유지해야 하며 항목 간에 중복되지 않아야 합니다. |
| `queues`                              | 문자열  |                | [아래 참조](#queues). |
| `timeout`                             | 정수 |                | Sidekiq 종료 시간 제한. Sidekiq가 TERM 신호를 받은 후 프로세스를 강제 종료하기 전의 시간(초). 제공되지 않으면 차트 전체 기본값에서 가져옵니다. 이 값은 **must** `terminationGracePeriodSeconds`. |
| `resources`                           |         |                | 각 Pod은 자신의 `resources` 요구 사항을 제시할 수 있으며, 존재하는 경우 생성된 `Deployment`에 추가됩니다. 이들은 Kubernetes 문서와 일치합니다. |
| `nodeSelector`                        |         |                | 각 Pod을 `nodeSelector` 속성으로 구성할 수 있으며, 존재하는 경우 생성된 `Deployment`에 추가됩니다. 이 정의들은 Kubernetes 문서와 일치합니다. |
| `memoryKiller.checkInterval`          | 정수 | `3`            | 메모리 확인 사이의 시간 |
| `memoryKiller.maxRss`                 | 정수 | `2000000`      | 주어진 Pod에 대한 최대 RSS를 재정의합니다. |
| `memoryKiller.graceTime`              | 정수 | `900`          | 주어진 Pod에 대해 종료 트리거 전에 대기할 시간을 재정의합니다 |
| `memoryKiller.shutdownWait`           | 정수 | `30`           | 주어진 Pod에 대해 종료 트리거 후 기존 작업이 완료되는 데 걸리는 시간을 재정의합니다 |
| `minReplicas`                         | 정수 | `2`            | 최소 복제본 수 |
| `maxReplicas`                         | 정수 | `10`           | 최대 복제본 수 |
| `maxUnavailable`                      | 정수 | `1`            | 사용할 수 없는 Pod의 최대 개수 제한 |
| `podLabels`                           |   맵   | `{}`           | 보충 포드 레이블입니다. 선택기에 사용되지 않습니다. |
| `strategy`                            |         | `{}`           | 배포에서 사용할 업데이트 전략을 구성할 수 있습니다 |
| `extraVolumes`                        | 문자열  |                | 주어진 Pod에 대해 추가 볼륨을 구성합니다. |
| `extraVolumeMounts`                   | 문자열  |                | 주어진 Pod에 대해 추가 볼륨 마운트를 구성합니다. |
| `priorityClassName`                   | 문자열  | `""`           | 포드 `priorityClassName`을(를) 구성할 수 있습니다. 이는 제거 시 포드 우선순위를 제어하는 데 사용됩니다. |
| `hpa.customMetrics`                   |  배열  | `[]`           | 사용자 정의 메트릭은 원하는 복제본 수를 계산하는 데 사용할 사양을 포함합니다(`targetAverageUtilization`에 구성된 평균 CPU 활용률의 기본 사용을 재정의함). |
| `hpa.cpu.targetType`                  | 문자열  | `AverageValue` | 자동 확장 CPU 대상 유형을 재정의하며, `Utilization` 또는 `AverageValue` 중 하나여야 합니다 |
| `hpa.cpu.targetAverageValue`          | 문자열  | `350m`         | 자동 확장 CPU 대상 값을 재정의합니다 |
| `hpa.cpu.targetAverageUtilization`    | 정수 |                | 자동 확장 CPU 대상 활용률을 재정의합니다 |
| `hpa.memory.targetType`               | 문자열  |                | 자동 확장 메모리 대상 유형을 재정의하며, `Utilization` 또는 `AverageValue` 중 하나여야 합니다 |
| `hpa.memory.targetAverageValue`       | 문자열  |                | 자동 확장 메모리 대상 값을 재정의합니다 |
| `hpa.memory.targetAverageUtilization` | 정수 |                | 자동 확장 메모리 대상 활용률을 재정의합니다 |
| `hpa.targetAverageValue`              | 문자열  |                | **DEPRECATED** 자동 확장 CPU 대상 값을 재정의합니다 |
| `keda.enabled`                        | 부울 | `false`        | KEDA 활성화를 재정의합니다 |
| `keda.pollingInterval`                | 정수 | `30`           | KEDA 폴링 간격을 재정의합니다 |
| `keda.cooldownPeriod`                 | 정수 | `300`          | KEDA 냉각 기간을 재정의합니다 |
| `keda.minReplicaCount`                | 정수 |                | KEDA 최소 복제본 수를 재정의합니다 |
| `keda.maxReplicaCount`                | 정수 |                | KEDA 최대 복제본 수를 재정의합니다 |
| `keda.fallback`                       |   맵   |                | KEDA 폴백 구성을 재정의합니다 |
| `keda.hpaName`                        | 문자열  |                | KEDA HPA 이름을 재정의합니다 |
| `keda.restoreToOriginalReplicaCount`  | 부울 |                | 원래 복제본 수 복원 활성화를 재정의합니다 |
| `keda.behavior`                       |   맵   |                | KEDA HPA 동작을 재정의합니다 |
| `keda.triggers`                       |  배열  |                | KEDA 트리거를 재정의합니다 |
| `extraEnv`                            |   맵   |                | 노출할 추가 환경 변수 목록. 차트 전체 값이 이것으로 병합되며, Pod의 값이 우선합니다 |
| `extraEnvFrom`                        |   맵   |                | 노출할 다른 데이터 소스의 추가 환경 변수 목록 |
| `terminationGracePeriodSeconds`       | 정수 | `30`           | Pod이 정상적으로 종료되어야 하는 선택적 기간(초). |

### 큐 {#queues}

`queues` 값은 처리할 쉼표로 구분된 큐 목록을 포함하는 문자열입니다. 기본적으로 설정되지 않아 모든 큐가 처리됨을 의미합니다.

문자열에는 공백이 포함되면 안 됩니다: `merge,post_receive,process_commit`이 작동하지만 `merge, post_receive, process_commit`은(는) 작동하지 않습니다.

작업이 추가되지만 최소한 하나의 Pod 항목의 일부로 표시되지 않는 모든 큐 *처리되지 않습니다*. GitLab 소스의 모든 큐의 전체 목록은 이 파일을 참조하세요:

1. [`app/workers/all_queues.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/all_queues.yml)
1. [`ee/app/workers/all_queues.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/all_queues.yml)

`gitlab.sidekiq.pods[].queues`을 구성하는 것 외에도 `global.appConfig.sidekiq.routingRules`을 구성해야 합니다. 자세한 내용은 [Sidekiq 라우팅 규칙 설정](../../globals.md#sidekiq-routing-rules-settings)을 참조하세요.

### 예 `pod` 항목 {#example-pod-entry}

```yaml
pods:
  - name: immediate
    concurrency: 10
    minReplicas: 2  # defaults to inherited value
    maxReplicas: 10 # defaults to inherited value
    maxUnavailable: 5 # defaults to inherited value
    queues: merge,post_receive,process_commit
    extraVolumeMounts: |
      - name: example-volume-mount
        mountPath: /etc/example
    extraVolumes: |
      - name: example-volume
        persistentVolumeClaim:
          claimName: example-pvc
    resources:
      limits:
        cpu: 800m
        memory: 2Gi
    hpa:
      cpu:
        targetType: Value
        targetAverageValue: 350m
```

### Sidekiq 구성의 전체 예 {#full-example-of-sidekiq-configuration}

다음은 가져오기 관련 작업을 위한 별도의 Sidekiq Pod, 별도의 Redis 인스턴스를 사용하는 내보내기 관련 작업을 위한 Sidekiq Pod 및 다른 모든 항목을 위한 또 다른 Pod을 사용하는 Sidekiq 구성의 전체 예입니다.

```yaml
...
global:
  appConfig:
    sidekiq:
      routingRules:
      - ["feature_category=importers", "import"]
      - ["feature_category=exporters", "export", "queues_shard_extra_shard"]
      - ["*", "default"]
  redis:
    redisYmlOverride:
      queues_shard_extra_shard: ...
...
gitlab:
  sidekiq:
    pods:
    - name: import
      queues: import
    - name: export
      queues: export
      extraEnv:
        SIDEKIQ_SHARD_NAME: queues_shard_extra_shard # to match key in global.redis.redisYmlOverride
    - name: default
...
```

## `networkpolicy` 구성 {#configuring-the-networkpolicy}

이 섹션은 [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)를 제어합니다. 이 구성은 선택 사항이며 포드의 Egress 및 Ingress를 특정 엔드포인트로 제한하는 데 사용됩니다.

| 이름              |  유형   | 기본값 | 설명 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | 부울 | `false` | 이 설정은 네트워크 정책을 활성화합니다 |
| `ingress.enabled` | 부울 | `false` | `true`로 설정하면 `Ingress` 네트워크 정책이 활성화됩니다. 규칙을 지정하지 않으면 모든 Ingress 연결이 차단됩니다. |
| `ingress.rules`   |  배열  | `[]`    | Ingress 정책에 대한 규칙, 자세한 내용은 <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> 및 아래 예제를 참조하세요 |
| `egress.enabled`  | 부울 | `false` | `true`로 설정하면 `Egress` 네트워크 정책이 활성화됩니다. 규칙을 지정하지 않으면 모든 egress 연결이 차단됩니다. |
| `egress.rules`    |  배열  | `[]`    | egress 정책에 대한 규칙, 자세한 내용은 <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> 및 아래 예제를 참조하세요 |

### 예제 네트워크 정책 {#example-network-policy}

Sidekiq 서비스는 활성화된 경우 Prometheus 내보내기 프로그램에만 수신 연결이 필요하며, 일반적으로 다양한 위치로 송신 연결이 필요합니다. 이 예에서는 다음 네트워크 정책을 추가합니다:

- Ingress 요청 허용:
  - `Prometheus` 포드로부터 `3807`포트로
- Egress 요청 허용:
  - `kube-dns`에서 `53`포트로
  - `gitaly` 포드에서 `8075`포트로
  - `registry` 포드에서 `5000`포트로
  - `kas` 포드에서 `8153`포트로
  - 외부 데이터베이스 `172.16.0.10/32`에서 `5432`포트로
  - 외부 Redis `172.16.0.11/32`에서 `6379`포트로
  - 외부 Elasticsearch `172.16.0.12/32`에서 `443`포트로
  - 메일 게이트웨이 `172.16.0.13/32`에서 `587`포트로
  - AWS VPC 엔드포인트(S3 또는 STS용) `172.16.1.0/24`과 같은 엔드포인트에서 `443`포트로
  - 내부 서브넷 `172.16.2.0/24`에서 포트 `443`로 웹후크를 전송하기 위해

제공된 예제는 단지 예제일 뿐이며 완전하지 않을 수 있습니다. Sidekiq 서비스는 로컬 엔드포인트가 없는 경우 [외부 개체 저장소](../../../advanced/external-object-storage)의 이미지에 대해 공개 인터넷으로의 아웃바운드 연결이 필요합니다. 이 예제는 `kube-dns`이 네임스페이스 `kube-system`에 배포되었고, `prometheus`이 네임스페이스 `monitoring`에 배포되었으며, `nginx-ingress`가 네임스페이스 `nginx-ingress`에 배포되었다는 가정을 기반으로 합니다.

```yaml
networkpolicy:
  enabled: true
  ingress:
    enabled: true
    rules:
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
          - port: 3807
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
              cidr: 172.16.0.10/32
        ports:
          - port: 5432
      - to:
          - ipBlock:
              cidr: 172.16.0.11/32
        ports:
          - port: 6379
      - to:
          - ipBlock:
              cidr: 172.16.0.12/32
        ports:
          - port: 25
      - to:
          - ipBlock:
              cidr: 172.16.0.13/32
        ports:
          - port: 443
      - to:
          - ipBlock:
              cidr: 172.16.1.0/24
        ports:
          - port: 443
      - to:
          - ipBlock:
              cidr: 172.16.2.0/24
        ports:
          - port: 443
```

## KEDA 구성 {#configuring-keda}

이 `keda` 섹션은 [KEDA](https://keda.sh/) `ScaledObjects`의 설치를 일반 `HorizontalPodAutoscalers` 대신 활성화합니다. 이 구성은 선택 사항이며 사용자 지정 또는 외부 메트릭을 기반으로 자동 크기 조정이 필요할 때 사용할 수 있습니다.

대부분의 설정은 `hpa` 섹션에 설정된 값으로 기본값을 설정합니다.

다음이 참이면 `hpa` 섹션에 설정된 CPU 및 메모리 임계값을 기반으로 CPU 및 메모리 트리거가 자동으로 추가됩니다:

- `triggers`이 설정되지 않았습니다.
- 해당 `request.cpu.request` 또는 `request.memory.request` 설정도 0이 아닌 값으로 설정됩니다.

트리거가 설정되지 않으면 `ScaledObject`은 생성되지 않습니다.

[KEDA 설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/)를 참조하여 이러한 설정에 대한 자세한 내용을 확인하세요.

| 이름                            |  유형   | 기본값 | 설명 |
|:--------------------------------|:-------:|:--------|:------------|
| `enabled`                       | 부울 | `false` | [KEDA](https://keda.sh/) `ScaledObjects`를 `HorizontalPodAutoscalers` 대신 사용합니다 |
| `pollingInterval`               | 정수 | `30`    | 각 트리거를 확인하는 간격 |
| `cooldownPeriod`                | 정수 | `300`   | 마지막 트리거가 활성으로 보고된 후 리소스를 0으로 다시 스케일링할 때까지 기다릴 기간 |
| `minReplicaCount`               | 정수 |         | KEDA가 리소스를 축소할 최소 복제본 수이며, `minReplicas`로 기본값 |
| `maxReplicaCount`               | 정수 |         | KEDA가 리소스를 확대할 최대 복제본 수이며, `maxReplicas`로 기본값 |
| `fallback`                      |   맵   |         | KEDA 폴백 구성, [설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)를 참조하세요 |
| `hpaName`                       | 문자열  |         | KEDA가 생성할 HPA 리소스의 이름이며, `keda-hpa-{scaled-object-name}`로 기본값 |
| `restoreToOriginalReplicaCount` | 부울 |         | `ScaledObject`이 삭제된 후 대상 리소스를 원래 복제본 수로 다시 스케일링할지 여부를 지정합니다 |
| `behavior`                      |   맵   |         | 상향 및 하향 스케일링 동작에 대한 사양이며, `hpa.behavior`로 기본값 |
| `triggers`                      |  배열  |         | 대상 리소스의 스케일링을 활성화할 트리거 목록, `hpa.cpu` 및 `hpa.memory`에서 계산된 트리거로 기본값 |
