---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab-Spamcheck 차트 사용
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab 자체 관리

{{< /details >}}

`spamcheck` 하위 차트는 GitLab에서 원래 GitLab.com의 증가하는 스팸 문제에 대처하기 위해 개발했으며 나중에 GitLab Self-Managed에서 사용하기 위해 공개된 anti-spam 엔진인 [Spamcheck](https://gitlab.com/gitlab-org/spamcheck)의 배포를 제공합니다.

## 요구 사항 {#requirements}

이 차트는 GitLab API에 대한 액세스에 따라 달라집니다.

## 구성 {#configuration}

### Spamcheck 활성화 {#enable-spamcheck}

`spamcheck`는 기본적으로 비활성화되어 있습니다. GitLab 인스턴스에서 활성화하려면 Helm 속성 `global.spamcheck.enabled`을(를) `true`(으)로 설정합니다. 예를 들어:

```shell
helm upgrade --force --install gitlab . \
--set global.hosts.domain='your.domain.com' \
--set global.hosts.externalIP=XYZ.XYZ.XYZ.XYZ \
--set certmanager-issuer.email='me@example.com' \
--set global.spamcheck.enabled=true
```

### Spamcheck를 사용하도록 GitLab 구성 {#configure-gitlab-to-use-spamcheck}

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **설정 > 리포트**를 선택합니다.
1. **스팸 및 안티봇 보호**를 확장합니다.
1. 스팸 확인 설정을 업데이트합니다:
   1. **외부 API 엔드포인트를 통한 스팸 확인 활성화** 확인란을 확인합니다
   1. 외부 스팸 확인 엔드포인트의 URL에 `grpc://gitlab-spamcheck.default.svc:8001`을(를) 사용합니다. 여기서 `default`은(는) GitLab이 배포되는 Kubernetes 네임스페이스로 바뀝니다.
   1. **스팸 확인 API 키**는 비어 있도록 둡니다.
1. **변경사항 저장**을 선택합니다.

## 설치 명령줄 옵션 {#installation-command-line-options}

아래 표에는 `helm install` 명령에 `--set` 플래그를 사용하여 제공할 수 있는 모든 가능한 차트 구성이 포함되어 있습니다.

| 매개변수                                       | 기본값                                                                                              | 설명 |
|-------------------------------------------------|------------------------------------------------------------------------------------------------------|-------------|
| `affinity`                                      | `{}`                                                                                                 | 포드 할당을 위한 [선호도 규칙](../_index.md#affinity) |
| `annotations`                                   | `{}`                                                                                                 | 포드 주석 |
| `common.labels`                                 | `{}`                                                                                                 | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `deployment.livenessProbe.initialDelaySeconds`  | `20`                                                                                                 | 생동성 프로브가 시작되기 전의 지연 |
| `deployment.livenessProbe.periodSeconds`        | `60`                                                                                                 | 생동성 프로브를 수행하는 빈도 |
| `deployment.livenessProbe.timeoutSeconds`       | `30`                                                                                                 | 생동성 프로브 시간이 초과될 때 |
| `deployment.livenessProbe.successThreshold`     | `1`                                                                                                  | 생동성 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `deployment.livenessProbe.failureThreshold`     | `3`                                                                                                  | 생동성 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `deployment.readinessProbe.initialDelaySeconds` | `0`                                                                                                  | 준비 프로브가 시작되기 전의 지연 |
| `deployment.readinessProbe.periodSeconds`       | `10`                                                                                                 | 준비 프로브를 수행하는 빈도 |
| `deployment.readinessProbe.timeoutSeconds`      | `2`                                                                                                  | 준비 프로브 시간이 초과될 때 |
| `deployment.readinessProbe.successThreshold`    | `1`                                                                                                  | 준비 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `deployment.readinessProbe.failureThreshold`    | `3`                                                                                                  | 준비 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `deployment.strategy`                           | `{}`                                                                                                 | 배포에서 사용하는 업데이트 전략을 구성하도록 허용합니다. 제공되지 않으면 클러스터 기본값이 사용됩니다. |
| `hpa.behavior`                                  | `{scaleDown: {stabilizationWindowSeconds: 300 }}`                                                    | 동작은 상향 및 하향 스케일링 동작의 사양을 포함합니다(`autoscaling/v2beta2` 이상 필요). |
| `hpa.customMetrics`                             | `[]`                                                                                                 | 사용자 정의 메트릭은 원하는 복제본 수를 계산하는 데 사용할 사양을 포함합니다(`targetAverageUtilization`에 구성된 평균 CPU 활용률의 기본 사용을 재정의함). |
| `hpa.cpu.targetType`                            | `AverageValue`                                                                                       | 자동 스케일링 CPU 대상 유형을 설정하고, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.cpu.targetAverageValue`                    | `100m`                                                                                               | 자동 스케일링 CPU 대상 값을 설정합니다 |
| `hpa.cpu.targetAverageUtilization`              |                                                                                                      | 자동 스케일링 CPU 대상 활용률을 설정합니다 |
| `hpa.memory.targetType`                         |                                                                                                      | 자동 스케일링 메모리 대상 유형을 설정하고, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.memory.targetAverageValue`                 |                                                                                                      | 자동 스케일링 메모리 대상 값을 설정합니다 |
| `hpa.memory.targetAverageUtilization`           |                                                                                                      | 자동 스케일링 메모리 대상 활용률을 설정합니다 |
| `hpa.targetAverageValue`                        |                                                                                                      | **DEPRECATED** 자동 스케일링 CPU 대상 값을 설정합니다 |
| `image.registry`                                |                                                                                                      | Spamcheck 이미지 레지스트리 |
| `image.repository`                              | `registry.gitlab.com/gitlab-com/gl-security/engineering-and-research/automation-team/spam/spamcheck` | Spamcheck 이미지 저장소 |
| `image.tag`                                     |                                                                                                      | Spamcheck 이미지 태그 |
| `image.digest`                                  |                                                                                                      | Spamcheck 이미지 다이제스트 |
| `keda.enabled`                                  | `false`                                                                                              | [KEDA](https://keda.sh/) `ScaledObjects`를 `HorizontalPodAutoscalers` 대신 사용합니다 |
| `keda.pollingInterval`                          | `30`                                                                                                 | 각 트리거를 확인하는 간격 |
| `keda.cooldownPeriod`                           | `300`                                                                                                | 마지막 트리거가 활성으로 보고된 후 리소스를 0으로 다시 스케일링할 때까지 기다릴 기간 |
| `keda.minReplicaCount`                          | `hpa.minReplicas`                                                                                    | KEDA가 리소스를 축소할 최소 복제본 수입니다. |
| `keda.maxReplicaCount`                          | `hpa.maxReplicas`                                                                                    | KEDA가 리소스를 확장할 최대 복제본 수입니다. |
| `keda.fallback`                                 |                                                                                                      | KEDA 폴백 구성, [설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)를 참조하세요 |
| `keda.hpaName`                                  | `keda-hpa-{scaled-object-name}`                                                                      | KEDA가 생성할 HPA 리소스의 이름입니다. |
| `keda.restoreToOriginalReplicaCount`            |                                                                                                      | `ScaledObject`이 삭제된 후 대상 리소스를 원래 복제본 수로 다시 스케일링할지 여부를 지정합니다 |
| `keda.behavior`                                 | `hpa.behavior`                                                                                       | 상향 및 하향 스케일링 동작의 사양입니다. |
| `keda.triggers`                                 |                                                                                                      | 대상 리소스의 스케일링을 활성화할 트리거 목록, `hpa.cpu` 및 `hpa.memory`에서 계산된 트리거로 기본값 |
| `listenAddr`                                    | `[::]`                                                                                               | 내부 수신 대기 주소입니다. |
| `logging.level`                                 | `info`                                                                                               | 로그 수준   |
| `maxReplicas`                                   | `10`                                                                                                 | HPA `maxReplicas` |
| `maxUnavailable`                                | `1`                                                                                                  | HPA `maxUnavailable` |
| `minReplicas`                                   | `2`                                                                                                  | HPA `maxReplicas` |
| `podLabels`                                     | `{}`                                                                                                 | 보충 포드 레이블입니다. 선택자에 사용되지 않습니다. |
| `resources.requests.cpu`                        | `100m`                                                                                               | Spamcheck 최소 CPU |
| `resources.requests.memory`                     | `100M`                                                                                               | Spamcheck 최소 메모리 |
| `securityContext.fsGroup`                       | `1000`                                                                                               | 포드를 시작해야 하는 그룹 ID |
| `securityContext.runAsUser`                     | `1000`                                                                                               | 포드를 시작해야 하는 사용자 ID |
| `securityContext.fsGroupChangePolicy`           |                                                                                                      | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `serviceLabels`                                 | `{}`                                                                                                 | 보충 서비스 레이블 |
| `service.externalPort`                          | `8001`                                                                                               | Spamcheck 외부 포트 |
| `service.internalPort`                          | `8001`                                                                                               | Spamcheck 내부 포트 |
| `service.type`                                  | `ClusterIP`                                                                                          | Spamcheck 서비스 유형 |
| `serviceAccount.automountServiceAccountToken`   | `false`                                                                                              | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다 |
| `serviceAccount.create`                         | `false`                                                                                              | ServiceAccount를 생성해야 하는지 여부를 나타냅니다 |
| `serviceAccount.enabled`                        | `false`                                                                                              | ServiceAccount를 사용해야 하는지 여부를 나타냅니다 |
| `tolerations`                                   | `[]`                                                                                                 | 포드 할당을 위한 용인 레이블 |
| `extraEnvFrom`                                  | `{}`                                                                                                 | 다른 데이터 소스에서 노출할 추가 환경 변수 목록 |
| `priorityClassName`                             |                                                                                                      | 포드에 할당된 [우선순위 클래스](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/). |

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
| `minReplicaCount`               | 정수 | `hpa.minReplicas`               | KEDA가 리소스를 축소할 최소 복제본 수입니다. |
| `maxReplicaCount`               | 정수 | `hpa.maxReplicas`               | KEDA가 리소스를 확장할 최대 복제본 수입니다. |
| `fallback`                      |   맵   |                                 | KEDA 폴백 구성, [설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)를 참조하세요 |
| `hpaName`                       | 문자열  | `keda-hpa-{scaled-object-name}` | KEDA가 생성할 HPA 리소스의 이름입니다. |
| `restoreToOriginalReplicaCount` | 부울 |                                 | `ScaledObject`이 삭제된 후 대상 리소스를 원래 복제본 수로 다시 스케일링할지 여부를 지정합니다 |
| `behavior`                      |   맵   | `hpa.behavior`                  | 상향 및 하향 스케일링 동작의 사양입니다. |
| `triggers`                      |  배열  |                                 | 대상 리소스의 스케일링을 활성화할 트리거 목록, `hpa.cpu` 및 `hpa.memory`에서 계산된 트리거로 기본값 |

## 차트 구성 예시 {#chart-configuration-examples}

### `serviceAccount` {#serviceaccount}

이 섹션에서는 ServiceAccount를 생성해야 하는지 여부와 기본 액세스 토큰을 Pod에 마운트해야 하는지 여부를 제어합니다.

| 이름                           |  유형   | 기본값 | 설명 |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | 부울 | `false` | 기본 ServiceAccount 액세스 토큰이 Pod에 마운트되어야 하는지 여부를 제어합니다. 특정 사이드카가 제대로 작동하도록 필요한 경우가 아니면(예: Istio) 이를 활성화하지 않아야 합니다. |
| `create`                       | 부울 | `false` | ServiceAccount를 생성해야 하는지 여부를 나타냅니다. |
| `enabled`                      | 부울 | `false` | ServiceAccount를 사용해야 하는지 여부를 나타냅니다. |

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

`annotations`을(를) 통해 Spamcheck Pod에 주석을 추가할 수 있습니다. 예를 들어:

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### 리소스 {#resources}

`resources`을(를) 통해 Spamcheck Pod가 사용할 수 있는 리소스(메모리 및 CPU)의 최소 및 최대 양을 구성할 수 있습니다.

예를 들어:

```yaml
resources:
  requests:
    memory: 100m
    cpu: 100M
```

### livenessProbe/readinessProbe {#livenessprobereadinessprobe}

`deployment.livenessProbe` 및 `deployment.readinessProbe`은(는) 컨테이너가 broken 상태에 있을 때와 같이 특정 시나리오에서 Spamcheck Pod의 종료를 제어하는 데 도움이 되는 메커니즘을 제공합니다.

예를 들어:

```yaml
deployment:
  livenessProbe:
    initialDelaySeconds: 10
    periodSeconds: 20
    timeoutSeconds: 3
    successThreshold: 1
    failureThreshold: 10
  readinessProbe:
    initialDelaySeconds: 10
    periodSeconds: 5
    timeoutSeconds: 2
    successThreshold: 1
    failureThreshold: 3
```

이 구성에 대한 추가 세부 정보는 공식 [Kubernetes 설명서](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)를 참조하세요.
