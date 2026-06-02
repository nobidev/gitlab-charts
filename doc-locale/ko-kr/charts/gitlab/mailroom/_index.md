---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mailroom 차트 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

Mailroom 차트는 [수신 이메일](https://docs.gitlab.com/administration/incoming_email/)을 처리합니다.

## 구성 {#configuration}

```yaml
image:
  repository: registry.gitlab.com/gitlab-org/build/cng/gitlab-mailroom
  # tag: v0.9.1
  pullSecrets: []
  # pullPolicy: IfNotPresent

enabled: true

init:
  image: {}
    # repository:
    # tag:
  resources:
    requests:
      cpu: 50m

annotations: {}

# Tolerations for pod scheduling
tolerations: []
affinity: {}
podLabels: {}

hpa:
  minReplicas: 1
  maxReplicas: 2
  cpu:
    targetAverageUtilization: 75

  # Note that the HPA is limited to autoscaling/v2beta1, autoscaling/v2beta2 and autoscaling/v2
  customMetrics: []
  behavior: {}

networkpolicy:
  enabled: false
  egress:
    enabled: false
    rules: []
  ingress:
    enabled: false
    rules: []
  annotations: {}

resources:
  # limits:
  #  cpu: 1
  #  memory: 2G
  requests:
    cpu: 50m
    memory: 150M

## Allow to overwrite under which User and Group we're running.
securityContext:
  runAsUser: 1000
  fsGroup: 1000

## Enable deployment to use a serviceAccount
serviceAccount:
  enabled: false
  create: false
  annotations: {}
  ## Name to be used for serviceAccount, otherwise defaults to chart fullname
  # name:
```

| 매개변수                                     | 기본값                                                    | 설명 |
|-----------------------------------------------|------------------------------------------------------------|-------------|
| `affinity`                                    | `{}`                                                       | 포드 할당을 위한 [선호도 규칙](../_index.md#affinity) |
| `annotations`                                 | `{}`                                                       | 포드 주석입니다. |
| `deployment.strategy`                         | `{}`                                                       | 배포에서 사용할 업데이트 전략을 구성할 수 있습니다 |
| `enabled`                                     | `true`                                                     | Mailroom 활성화 플래그 |
| `hpa.behavior`                                | `{scaleDown: {stabilizationWindowSeconds: 300 }}`          | 동작은 상향 및 하향 스케일링 동작의 사양을 포함합니다(`autoscaling/v2beta2` 이상 필요). |
| `hpa.customMetrics`                           | `[]`                                                       | 사용자 정의 메트릭은 원하는 복제본 수를 계산하는 데 사용할 사양을 포함합니다(`targetAverageUtilization`에 구성된 평균 CPU 활용률의 기본 사용을 재정의함). |
| `hpa.cpu.targetType`                          | `Utilization`                                              | 자동 스케일링 CPU 대상 유형을 설정하고, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.cpu.targetAverageValue`                  |                                                            | 자동 스케일링 CPU 대상 값을 설정합니다 |
| `hpa.cpu.targetAverageUtilization`            | `75`                                                       | 자동 스케일링 CPU 대상 활용률을 설정합니다 |
| `hpa.memory.targetType`                       |                                                            | 자동 스케일링 메모리 대상 유형을 설정하고, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.memory.targetAverageValue`               |                                                            | 자동 스케일링 메모리 대상 값을 설정합니다 |
| `hpa.memory.targetAverageUtilization`         |                                                            | 자동 스케일링 메모리 대상 활용률을 설정합니다 |
| `hpa.maxReplicas`                             | `2`                                                        | 최대 복제본 수 |
| `hpa.minReplicas`                             | `1`                                                        | 최소 복제본 수 |
| `image.pullPolicy`                            | `IfNotPresent`                                             | Mailroom 이미지 가져오기 정책 |
| `extraEnvFrom`                                |                                                            | 다른 데이터 소스에서 노출할 추가 환경 변수 목록 |
| `image.pullSecrets`                           |                                                            | Mailroom 이미지 가져오기 시크릿 |
| `image.registry`                              |                                                            | Mailroom 이미지 레지스트리 |
| `image.repository`                            | `registry.gitlab.com/gitlab-org/build/cng/gitlab-mailroom` | Mailroom 이미지 저장소 |
| `image.tag`                                   |                                                            | Mailroom 이미지 태그 |
| `init.image.repository`                       |                                                            | Mailroom 초기화 이미지 저장소 |
| `init.image.tag`                              |                                                            | Mailroom 초기화 이미지 태그 |
| `init.resources`                              | `{ requests: { cpu: 50m }}`                                | Mailroom 초기화 컨테이너 리소스 요구사항 |
| `init.containerSecurityContext`               |                                                            | initContainer 컨테이너 특정 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `keda.enabled`                                | `false`                                                    | [KEDA](https://keda.sh/) `ScaledObjects`를 `HorizontalPodAutoscalers` 대신 사용합니다 |
| `keda.pollingInterval`                        | `30`                                                       | 각 트리거를 확인하는 간격 |
| `keda.cooldownPeriod`                         | `300`                                                      | 마지막 트리거가 활성으로 보고된 후 리소스를 0으로 다시 스케일링할 때까지 기다릴 기간 |
| `keda.minReplicaCount`                        | `hpa.minReplicas`                                          | KEDA가 리소스를 축소할 최소 복제본 수입니다. |
| `keda.maxReplicaCount`                        | `hpa.maxReplicas`                                          | KEDA가 리소스를 확장할 최대 복제본 수입니다. |
| `keda.fallback`                               |                                                            | KEDA 폴백 구성, [설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)를 참조하세요 |
| `keda.hpaName`                                | `keda-hpa-{scaled-object-name}`                            | KEDA가 생성할 HPA 리소스의 이름입니다. |
| `keda.restoreToOriginalReplicaCount`          |                                                            | `ScaledObject`이 삭제된 후 대상 리소스를 원래 복제본 수로 다시 스케일링할지 여부를 지정합니다 |
| `keda.behavior`                               | `hpa.behavior`                                             | 상향 및 하향 스케일링 동작의 사양입니다. |
| `keda.triggers`                               |                                                            | 대상 리소스의 스케일링을 활성화할 트리거 목록, `hpa.cpu` 및 `hpa.memory`에서 계산된 트리거로 기본값 |
| `podLabels`                                   | `{}`                                                       | 실행 중인 Mailroom Pod의 레이블 |
| `common.labels`                               | `{}`                                                       | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `resources`                                   | `{ requests: { cpu: 50m, memory: 150M }}`                  | Mailroom 리소스 요구사항 |
| `networkpolicy.annotations`                   | `{}`                                                       | NetworkPolicy에 추가할 주석 |
| `networkpolicy.egress.enabled`                | `false`                                                    | NetworkPolicy의 송신 규칙을 활성화하는 플래그 |
| `networkpolicy.egress.rules`                  | `[]`                                                       | NetworkPolicy의 송신 규칙 목록을 정의합니다. |
| `networkpolicy.enabled`                       | `false`                                                    | NetworkPolicy 사용 플래그 |
| `networkpolicy.ingress.enabled`               | `false`                                                    | NetworkPolicy의 `ingress` 규칙을 활성화하는 플래그 |
| `networkpolicy.ingress.rules`                 | `[]`                                                       | NetworkPolicy의 `ingress` 규칙 목록을 정의합니다. |
| `securityContext.fsGroup`                     | `1000`                                                     | 포드를 시작해야 하는 그룹 ID |
| `securityContext.runAsUser`                   | `1000`                                                     | 포드를 시작해야 하는 사용자 ID |
| `securityContext.fsGroupChangePolicy`         |                                                            | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `containerSecurityContext`                    |                                                            | 컨테이너가 시작되는 컨테이너 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)를 재정의합니다 |
| `containerSecurityContext.runAsUser`          | `1000`                                                     | 컨테이너가 시작되는 특정 보안 컨텍스트를 덮어쓸 수 있습니다 |
| `serviceAccount.annotations`                  | `{}`                                                       | ServiceAccount의 주석 |
| `serviceAccount.automountServiceAccountToken` | `false`                                                    | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다 |
| `serviceAccount.enabled`                      | `false`                                                    | ServiceAccount를 사용해야 하는지 여부를 나타냅니다 |
| `serviceAccount.create`                       | `false`                                                    | ServiceAccount를 생성해야 하는지 여부를 나타냅니다 |
| `serviceAccount.name`                         |                                                            | ServiceAccount의 이름입니다. 설정하지 않으면 전체 차트 이름이 사용됩니다 |
| `tolerations`                                 |                                                            | Mailroom에 추가할 허용 |
| `priorityClassName`                           |                                                            | 포드에 할당된 [우선순위 클래스](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/). |

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

## 수신 이메일 {#incoming-email}

기본적으로 수신 이메일은 비활성화됩니다. 수신 이메일을 읽는 두 가지 방법이 있습니다:

- [IMAP](#imap)
- [Microsoft Graph](#microsoft-graph)

먼저 [일반 설정](../../../installation/command-line-options.md#common-settings)을 설정하여 활성화합니다. 그런 다음 [IMAP 설정](../../../installation/command-line-options.md#imap-settings) 또는 [Microsoft Graph 설정](../../../installation/command-line-options.md#microsoft-graph-settings)을 구성합니다.

이러한 메서드는 `values.yaml`에서 구성할 수 있습니다. 다음 예제를 참조하세요:

- [IMAP을 사용한 수신 이메일](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-incoming-email.yaml)
- [Microsoft Graph를 사용한 수신 이메일](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-msgraph.yaml)

### IMAP {#imap}

IMAP 수신 이메일을 활성화하려면 `global.appConfig.incomingEmail` 설정을 사용하여 IMAP 서버 및 액세스 자격 증명의 세부 정보를 제공합니다.

또한 [IMAP 이메일 계정의 요구사항](https://docs.gitlab.com/administration/incoming_email/)을 검토하여 대상 IMAP 계정을 GitLab에서 이메일 수신에 사용할 수 있는지 확인해야 합니다. 또한 여러 일반적인 이메일 서비스가 동일한 페이지에 문서화되어 수신 이메일 설정을 지원합니다.

IMAP 암호는 [보안 정보](../../../installation/secrets.md#imap-password-for-incoming-emails)에 설명된 대로 Kubernetes 시크릿으로 생성해야 합니다.

### Microsoft Graph {#microsoft-graph}

[Azure Active Directory 애플리케이션 생성에 대한 GitLab 설명서](https://docs.gitlab.com/administration/incoming_email/#microsoft-graph)를 참조하세요.

테넌트 ID, 클라이언트 ID 및 클라이언트 시크릿을 제공합니다. [명령줄 옵션](../../../installation/command-line-options.md#incoming-email-configuration)에서 이러한 설정에 대한 세부 정보를 찾을 수 있습니다.

[보안 정보](../../../installation/secrets.md#microsoft-graph-client-secret-for-incoming-emails)에 설명된 대로 클라이언트 시크릿을 포함하는 Kubernetes 시크릿을 생성합니다.

### 이메일로 회신 {#reply-by-email}

사용자가 알림 이메일에 회신하여 문제 및 MR에 대한 댓글을 달 수 있는 이메일로 회신 기능을 사용하려면 [발신 이메일](../../../installation/command-line-options.md#outgoing-email-configuration) 및 수신 이메일 설정을 모두 구성해야 합니다.

### Service Desk 이메일 {#service-desk-email}

기본적으로 Service Desk 이메일은 비활성화됩니다.

수신 이메일과 마찬가지로 [일반 설정](../../../installation/command-line-options.md#common-settings-1)을 설정하여 활성화합니다. 그런 다음 [IMAP 설정](../../../installation/command-line-options.md#imap-settings-1) 또는 [Microsoft Graph 설정](../../../installation/command-line-options.md#microsoft-graph-settings-1)을 구성합니다.

이러한 옵션은 `values.yaml`에서도 구성할 수 있습니다. 다음 예제를 참조하세요:

- [IMAP을 사용한 Service Desk](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-service-desk-email.yaml)
- [Microsoft Graph를 사용한 Service Desk](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-msgraph.yaml)

Service Desk 이메일은 [수신 이메일](#incoming-email)이 구성되어야 _필요_합니다.

#### IMAP {#imap-1}

`global.appConfig.serviceDeskEmail` 설정을 사용하여 IMAP 서버 및 액세스 자격 증명의 세부 정보를 제공합니다. [명령줄 옵션](../../../installation/command-line-options.md#service-desk-email-configuration)에서 이러한 설정에 대한 세부 정보를 찾을 수 있습니다.

[보안 정보](../../../installation/secrets.md#imap-password-for-service-desk-emails)에 설명된 대로 IMAP 암호를 포함하는 Kubernetes 시크릿을 생성합니다.

#### Microsoft Graph {#microsoft-graph-1}

[Azure Active Directory 애플리케이션 생성에 대한 GitLab 설명서](https://docs.gitlab.com/administration/incoming_email/#microsoft-graph)를 참조하세요.

`global.appConfig.serviceDeskEmail` 설정을 사용하여 테넌트 ID, 클라이언트 ID 및 클라이언트 시크릿을 제공합니다. [명령줄 옵션](../../../installation/command-line-options.md#service-desk-email-configuration)에서 이러한 설정에 대한 세부 정보를 찾을 수 있습니다.

[보안 정보](../../../installation/secrets.md#imap-password-for-service-desk-emails)에 설명된 대로 클라이언트 시크릿을 포함하는 Kubernetes 시크릿을 생성해야 합니다.

### serviceAccount {#serviceaccount}

이 섹션에서는 ServiceAccount를 생성해야 하는지 여부와 기본 액세스 토큰을 Pod에 마운트해야 하는지 여부를 제어합니다.

| 이름                           |  유형   | 기본값 | 설명 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   맵   | `{}`    | ServiceAccount 주석. |
| `automountServiceAccountToken` | 부울 | `false` | 기본 ServiceAccount 액세스 토큰이 Pod에 마운트되어야 하는지 여부를 제어합니다. 특정 사이드카가 제대로 작동하도록 필요한 경우가 아니면(예: Istio) 이를 활성화하지 않아야 합니다. |
| `create`                       | 부울 | `false` | ServiceAccount를 생성해야 하는지 여부를 나타냅니다. |
| `enabled`                      | 부울 | `false` | ServiceAccount를 사용해야 하는지 여부를 나타냅니다. |
| `name`                         | 문자열  |         | ServiceAccount의 이름입니다. 설정하지 않은 경우 전체 차트 이름이 사용됩니다. |

### affinity {#affinity}

자세한 내용은 [`affinity`](../_index.md#affinity)를 참조하세요.
