---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab `kas` 차트 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

`kas` 하위 차트는 [GitLab 에이전트 서버(KAS)](https://docs.gitlab.com/administration/clusters/kas/)의 구성 가능한 배포를 제공합니다. 에이전트 서버는 GitLab과 함께 설치하는 컴포넌트입니다. [GitLab Kubernetes 에이전트](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent)를 관리하기 위해 필요합니다.

이 차트는 GitLab API 및 Gitaly 서버에 대한 액세스에 따라 달라집니다. 이 차트를 활성화하면 Ingress가 배포됩니다.

최소 리소스를 사용하기 위해 `kas` 컨테이너는 distroless 이미지를 사용합니다. 배포된 서비스는 통신을 위해 [WebSocket 프록싱](https://nginx.org/en/docs/http/websocket.html)을 사용하는 Ingress에 의해 노출됩니다. 이 프록시는 외부 컴포넌트 [`agentk`](https://docs.gitlab.com/user/clusters/agent/install/)와의 장시간 연결을 허용합니다. `agentk`는 Kubernetes 클러스터 측 에이전트 대응물입니다.

서비스에 액세스하기 위한 경로는 [Ingress 구성](#specify-an-ingress)에 따라 달라집니다.

자세한 내용은 [GitLab Kubernetes 에이전트 아키텍처](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md)를 참조하세요.

## 에이전트 서버 비활성화 {#disable-the-agent-server}

GitLab 에이전트 서버(`kas`)는 기본적으로 활성화되어 있습니다. GitLab 인스턴스에서 비활성화하려면 Helm 속성 `global.kas.enabled`을 `false`으로 설정하세요.

예를 들어:

```shell
helm upgrade --install kas --set global.kas.enabled=false
```

### Ingress 지정 {#specify-an-ingress}

차트의 Ingress를 기본 구성과 함께 사용할 때 에이전트 서버 서비스는 하위 도메인에서 접근 가능합니다. 예를 들어 `global.hosts.domain: example.com`의 경우 에이전트 서버는 `kas.example.com`에서 접근 가능합니다.

[KAS Ingress](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/kas/templates/ingress.yaml)는 `global.hosts.domain`와 다른 도메인을 사용할 수 있습니다.

`global.hosts.kas.name`을 설정하세요(예를 들어):

```shell
global.hosts.kas.name: kas.my-other-domain.com
```

이 예제는 `kas.my-other-domain.com`을 KAS Ingress만의 호스트로 사용합니다. 나머지 서비스(GitLab, Registry, MinIO 등 포함)는 `global.hosts.domain`에 지정된 도메인을 사용합니다.

### gRPC Ingress 지원 {#grpc-ingress-support}

KAS 서비스는 WebSocket 트래픽과 동일한 포트를 통해 gRPC 트래픽을 지원하며, 두 프로토콜을 구분하기 위해 정규식 매칭을 사용한 경로 기반 라우팅을 사용합니다.

> [!warning]
> [`global.appConfig.relativeUrlRoot`](../../globals.md#configure-a-relative-url-root)이 비어 있지 않은 값으로 설정된 경우 gRPC Ingress는 지원되지 않습니다.

#### 컨트롤러 지원 {#controller-support}

- **NGINX Ingress 컨트롤러**:  자동 구성으로 완전히 지원됨
- **기타 컨트롤러**:  정규식 기반 경로 매칭을 지원하는 모든 컨트롤러를 사용할 수 있습니다

#### 경로 패턴 {#path-pattern}

gRPC Ingress는 다음 경로 패턴을 사용합니다:

```regex
/gitlab\.agent\.(.+)
```

이 패턴은 gRPC 트래픽을 KAS 서비스로 적절하게 라우팅하면서 동일한 포트에서 WebSocket 기능을 유지합니다.

#### 구성 {#configuration}

gRPC Ingress를 활성화하려면 `gitlab.kas.ingress.grpc.enabled`을 설정하고 KAS가 자체 하위 도메인 아래에서 실행 중인지 확인하세요:

```yaml
gitlab:
  kas:
    ingress:
      grpc:
        enabled: true
```

NGINX Ingress 컨트롤러를 사용할 때는 자동으로 설정되므로 추가 구성이 필요하지 않습니다. 다른 컨트롤러의 경우 gRPC를 지원하기 위해 관련 주석을 추가하고 정규식 기반 경로 매칭을 지원하는지 확인한 후 지정된 경로 패턴을 KAS 서비스로 라우팅하도록 구성하세요.

### 설치 명령줄 옵션 {#installation-command-line-options}

`helm install` 명령에 이러한 매개변수를 `--set` 플래그를 사용하여 전달할 수 있습니다.

| 매개변수                                                | 기본값                                               | 설명 |
|----------------------------------------------------------|-------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                  | 포드 할당을 위한 [선호도 규칙](../_index.md#affinity) |
| `annotations`                                            | `{}`                                                  | 포드 주석입니다. |
| `common.labels`                                          | `{}`                                                  | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `securityContext.runAsUser`                              | `65532`                                               | 포드를 시작해야 하는 사용자 ID |
| `securityContext.runAsGroup`                             | `65534`                                               | 포드를 시작해야 하는 그룹 ID |
| `securityContext.fsGroup`                                | `65532`                                               | 포드를 시작해야 하는 그룹 ID |
| `securityContext.fsGroupChangePolicy`                    |                                                       | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                      | 사용할 Seccomp 프로필 |
| `containerSecurityContext.runAsUser`                     | `65532`                                               | 컨테이너 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) 사용자 ID 재정의(컨테이너가 시작되는) |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                               | 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                | 컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                           | Gitaly 컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `extraContainers`                                        |                                                       | 포함할 컨테이너 목록을 포함하는 다중 라인 리터럴 스타일 문자열입니다. |
| `extraEnv`                                               |                                                       | 노출할 추가 환경 변수 목록 |
| `extraEnvFrom`                                           |                                                       | 다른 데이터 소스에서 노출할 추가 환경 변수 목록 |
| `init.containerSecurityContext`                          |                                                       | init 컨테이너 securityContext 재정의 |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                               | initContainer 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                | initContainer 특정:  컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                           | initContainer 특정:  컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-kas` | 이미지 저장소입니다. |
| `image.tag`                                              | `v13.7.0`                                             | 이미지 태그입니다.  |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`     | 동작에는 상향 및 하향 스케일링 동작에 대한 사양이 포함되어 있습니다(`autoscaling/v2beta2` 이상 필요). |
| `hpa.customMetrics`                                      | `[]`                                                  | 사용자 정의 메트릭은 원하는 복제본 수를 계산하는 데 사용할 사양이 포함되어 있습니다(`targetAverageUtilization`에서 구성된 기본 평균 CPU 활용률 사용 재정의). |
| `hpa.cpu.targetType`                                     | `AverageValue`                                        | 자동 스케일링 CPU 대상 유형을 설정하며, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.cpu.targetAverageValue`                             | `100m`                                                | 자동 스케일링 CPU 대상 값을 설정하세요. |
| `hpa.cpu.targetAverageUtilization`                       |                                                       | 자동 스케일링 CPU 대상 활용률을 설정하세요. |
| `hpa.memory.targetType`                                  |                                                       | 자동 스케일링 메모리 대상 유형을 설정하며, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.memory.targetAverageValue`                          |                                                       | 자동 스케일링 메모리 대상 값을 설정하세요. |
| `hpa.memory.targetAverageUtilization`                    |                                                       | 자동 스케일링 메모리 대상 활용률을 설정하세요. |
| `hpa.targetAverageValue`                                 |                                                       | **DEPRECATED** 자동 스케일링 CPU 대상 값을 설정합니다 |
| `ingress.enabled`                                        | `true` if `global.kas.enabled=true`                   | `kas.ingress.enabled`을 사용하여 명시적으로 켜거나 끌 수 있습니다. 설정되지 않은 경우 같은 목적으로 `global.ingress.enabled`을 선택적으로 사용할 수 있습니다. |
| `ingress.apiVersion`                                     |                                                       | `apiVersion` 필드에서 사용할 값입니다. |
| `ingress.annotations`                                    | `{}`                                                  | Ingress 주석입니다. |
| `ingress.tls`                                            | `{}`                                                  | Ingress TLS 구성입니다. |
| `ingress.agentPath`                                      | `/`                                                   | 에이전트 API 엔드포인트의 Ingress 경로입니다. |
| `ingress.k8sApiPath`                                     | `/k8s-proxy`                                          | Kubernetes API 엔드포인트의 Ingress 경로입니다. |
| `keda.enabled`                                           | `false`                                               | [KEDA](https://keda.sh/) `ScaledObjects`를 `HorizontalPodAutoscalers` 대신 사용합니다 |
| `keda.pollingInterval`                                   | `30`                                                  | 각 트리거를 확인하는 간격 |
| `keda.cooldownPeriod`                                    | `300`                                                 | 마지막 트리거가 활성으로 보고된 후 리소스를 0으로 다시 스케일링할 때까지 기다릴 기간 |
| `keda.minReplicaCount`                                   |                                                       | KEDA가 리소스를 축소할 최소 복제본 수이며, `minReplicas`로 기본값 |
| `keda.maxReplicaCount`                                   |                                                       | KEDA가 리소스를 확대할 최대 복제본 수이며, `maxReplicas`로 기본값 |
| `keda.fallback`                                          |                                                       | KEDA 폴백 구성, [설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)를 참조하세요 |
| `keda.hpaName`                                           |                                                       | KEDA가 생성할 HPA 리소스의 이름이며, `keda-hpa-{scaled-object-name}`로 기본값 |
| `keda.restoreToOriginalReplicaCount`                     |                                                       | `ScaledObject`이 삭제된 후 대상 리소스를 원래 복제본 수로 다시 스케일링할지 여부를 지정합니다 |
| `keda.behavior`                                          |                                                       | 상향 및 하향 스케일링 동작에 대한 사양이며, `hpa.behavior`로 기본값 |
| `keda.triggers`                                          |                                                       | 대상 리소스의 스케일링을 활성화할 트리거 목록, `hpa.cpu` 및 `hpa.memory`에서 계산된 트리거로 기본값 |
| `metrics.enabled`                                        | `true`                                                | 메트릭 엔드포인트를 스크래핑할 수 있도록 해야 하는 경우입니다. |
| `metrics.path`                                           | `/metrics`                                            | 메트릭 엔드포인트 경로입니다. |
| `metrics.serviceMonitor.enabled`                         | `false`                                               | 메트릭 스크래핑을 관리하도록 Prometheus Operator를 활성화하기 위해 ServiceMonitor를 생성해야 하는 경우입니다. 활성화하면 `prometheus.io` 스크래핑 주석이 제거됩니다. `metrics.podMonitor.enabled`과 함께 활성화할 수 없습니다. |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                  | ServiceMonitor에 추가할 추가 레이블입니다. |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                  | ServiceMonitor에 대한 추가 엔드포인트 구성입니다. |
| `metrics.podMonitor.enabled`                             | `false`                                               | 메트릭 스크래핑을 관리하도록 Prometheus Operator를 활성화하기 위해 PodMonitor를 생성해야 하는 경우입니다. 활성화하면 `prometheus.io` 스크래핑 주석이 제거됩니다. `metrics.serviceMonitor.enabled`과 함께 활성화할 수 없습니다. |
| `metrics.podMonitor.additionalLabels`                    | `{}`                                                  | PodMonitor에 추가할 추가 레이블입니다. |
| `metrics.podMonitor.endpointConfig`                      | `{}`                                                  | PodMonitor에 대한 추가 엔드포인트 구성입니다. |
| `maxReplicas`                                            | `10`                                                  | HPA `maxReplicas`입니다. |
| `maxUnavailable`                                         | `1`                                                   | HPA `maxUnavailable`입니다. |
| `minReplicas`                                            | `2`                                                   | HPA `maxReplicas`입니다. |
| `nodeSelector`                                           |                                                       | 이 `Deployment`의 `Pod`에 대한 [nodeSelector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)를 정의하세요(존재하는 경우). |
| `observability.port`                                     | `8151`                                                | 관찰성 엔드포인트 포트입니다. 메트릭 및 프로브 엔드포인트에 사용됩니다. |
| `observability.livenessProbe.path`                       | `/liveness`                                           | 활성성 프로브 엔드포인트의 URI입니다. 이 값은 KAS 서비스 구성의 `observability.liveness_probe.url_path` 값과 일치해야 합니다. |
| `observability.readinessProbe.path`                      | `/readiness`                                          | 준비도 프로브 엔드포인트의 URI입니다. 이 값은 KAS 서비스 구성의 `observability.readiness_probe.url_path` 값과 일치해야 합니다. |
| `serviceAccount.annotations`                             | `{}`                                                  | 서비스 계정 주석입니다. |
| `podLabels`                                              | `{}`                                                  | 보충 포드 레이블입니다. 선택자에 사용되지 않습니다. |
| `serviceLabels`                                          | `{}`                                                  | 보충 서비스 레이블입니다. |
| `common.labels`                                          |                                                       | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `resources.requests.cpu`                                 | `100m`                                                | KAS 포드당 최소 CPU 요청 |
| `resources.requests.memory`                              | `256Mi`                                               | KAS 포드당 최소 메모리 요청 메모리입니다. |
| `service.externalPort`                                   | `8150`                                                | 외부 포트(`agentk` 연결용). |
| `service.internalPort`                                   | `8150`                                                | 내부 포트(`agentk` 연결용). |
| `service.apiInternalPort`                                | `8153`                                                | 내부 API의 내부 포트(GitLab 백엔드용). |
| `service.loadBalancerIP`                                 | `nil`                                                 | `service.type`이 `LoadBalancer`인 경우의 사용자 정의 로드 밸런서 IP입니다. |
| `service.loadBalancerSourceRanges`                       | `nil`                                                 | `service.type`이 `LoadBalancer`인 경우의 사용자 정의 로드 밸런서 소스 범위 목록입니다. |
| `service.kubernetesApiPort`                              | `8154`                                                | 프록시된 Kubernetes API를 노출할 외부 포트입니다. |
| `service.privateApiPort`                                 | `8155`                                                | `kas`' 프라이빗 API를 노출할 내부 포트(`kas` -> `kas` 통신용). |
| `serviceAccount.annotations`                             | `{}`                                                  | ServiceAccount 주석. |
| `serviceAccount.automountServiceAccountToken`            | `false`                                               | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다. |
| `serviceAccount.create`                                  | `false`                                               | ServiceAccount를 생성해야 하는지 여부를 나타냅니다. |
| `serviceAccount.enabled`                                 | `false`                                               | ServiceAccount를 사용해야 하는지 여부를 나타냅니다. |
| `serviceAccount.name`                                    |                                                       | ServiceAccount의 이름입니다. 설정하지 않은 경우 전체 차트 이름이 사용됩니다. |
| `websocketToken.secret`                                  | 자동 생성됨                                         | WebSocket 토큰 서명 및 확인에 사용할 시크릿의 이름입니다. |
| `websocketToken.key`                                     | 자동 생성됨                                         | `websocketToken.secret`의 사용할 키의 이름입니다. |
| `privateApi.secret`                                      | 자동 생성됨                                         | 데이터베이스를 통해 인증하는 데 사용할 시크릿의 이름입니다. |
| `privateApi.key`                                         | 자동 생성됨                                         | `privateApi.secret`의 사용할 키의 이름입니다. |
| `global.kas.service.apiExternalPort`                     | `8153`                                                | 내부 API의 외부 포트(GitLab 백엔드용). |
| `service.type`                                           | `ClusterIP`                                           | 서비스 유형입니다. |
| `tolerations`                                            | `[]`                                                  | 포드 할당을 위한 허용 레이블입니다. |
| `customConfig`                                           | `{}`                                                  | 기본 `kas` 구성과 병합하여 여기에 정의된 값에 우선순위를 부여합니다. |
| `deployment.minReadySeconds`                             | `0`                                                   | `kas` 포드가 준비되었다고 간주되기 전에 경과해야 하는 최소 초 수입니다. |
| `deployment.strategy`                                    | `{}`                                                  | 배포에서 사용하는 업데이트 전략을 구성하도록 합니다. |
| `deployment.terminationGracePeriodSeconds`               | `300`                                                 | SIGTERM을 수신한 후 포드가 종료되는 데 허용되는 시간(초)입니다. |
| `priorityClassName`                                      |                                                       | 포드에 할당된 [우선순위 클래스](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/). |

## TLS 통신 활성화 {#enable-tls-communication}

`kas` 포드와 다른 GitLab 차트 컴포넌트 간의 TLS 통신을 활성화합니다([global KAS 속성](../../globals.md#tls-settings-1) 참조).

## `kas` 차트 테스트 {#test-the-kas-chart}

차트를 설치하려면:

1. 자신의 Kubernetes 클러스터를 생성합니다.
1. 병합 요청의 작업 분기를 체크아웃합니다.
1. 로컬 차트 분기에서 기본적으로 `kas` 활성화로 GitLab을 설치(또는 업그레이드)합니다:

   ```shell
   helm upgrade --force --install gitlab . \
     --timeout 600s \
     --set global.hosts.domain=your.domain.com \
     --set global.hosts.externalIP=XYZ.XYZ.XYZ.XYZ \
     --set certmanager-issuer.email=your@email.com
   ```

1. GDK를 사용하여 [GitLab Kubernetes 에이전트](https://docs.gitlab.com/user/clusters/agent/)를 구성하고 사용하는 프로세스를 실행합니다:  (에이전트를 수동으로 구성하고 사용하는 단계를 따를 수도 있습니다.)

   1. GDK GitLab 저장소에서 QA 폴더로 이동합니다: `cd qa`.
   1. QA 테스트를 실행할 다음 명령을 실행합니다:

      ```shell
      GITLAB_USERNAME=$ROOT_USER
      GITLAB_PASSWORD=$ROOT_PASSWORD
      GITLAB_ADMIN_USERNAME=$ROOT_USER
      GITLAB_ADMIN_PASSWORD=$ROOT_PASSWORD
      bundle exec bin/qa Test::Instance::All https://your.gitlab.domain/ -- --tag orchestrated --tag quarantine qa/specs/features/ee/api/7_configure/kubernetes/kubernetes_agent_spec.rb
      ```

      `agentk` 버전을 환경 변수와 함께 설치하도록 사용자 정의할 수도 있습니다: `GITLAB_AGENTK_VERSION=v13.7.1`

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

## 디버그 로깅 활성화 {#enable-debug-logging}

KAS 하위 차트에 대한 디버그 로깅을 활성화하려면 `kas` 섹션의 `values.yaml` 파일에 다음을 추가하세요:

```yaml
customConfig:
   observability:
      logging:
         level: debug
         grpc_level: debug
```
