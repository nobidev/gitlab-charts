---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab-Exporter 차트 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

`gitlab-exporter` 서브 차트는 GitLab 애플리케이션 관련 데이터에 대한 Prometheus 메트릭을 제공합니다. PostgreSQL과 직접 통신하여 CI 빌드, 풀 미러 등의 데이터를 검색하는 쿼리를 수행합니다. 또한 Sidekiq API를 사용하며, 이는 Redis와 통신하여 Sidekiq 큐 상태에 대한 다양한 메트릭(예: 작업 수)을 수집합니다.

## 요구 사항 {#requirements}

이 차트는 완전한 GitLab 차트의 일부이거나 이 차트가 배포되는 Kubernetes 클러스터에서 도달 가능한 외부 서비스로 제공되는 Redis 및 PostgreSQL 서비스에 따라 다릅니다.

## 구성 {#configuration}

`gitlab-exporter` 차트는 다음과 같이 구성됩니다:  [전역 설정](#global-settings) 및 [차트 설정](#chart-settings).

## 설치 명령줄 옵션 {#installation-command-line-options}

다음 표에는 `helm install` 명령을 사용하여 제공할 수 있는 모든 가능한 차트 구성이 포함되어 있으며, `--set` 플래그를 사용합니다.

| 매개변수                                                | 기본값                                                    | 설명 |
|----------------------------------------------------------|------------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                       | 포드 할당을 위한 [선호도 규칙](../_index.md#affinity) |
| `annotations`                                            |                                                            | 포드 주석 |
| `common.labels`                                          | `{}`                                                       | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `podLabels`                                              |                                                            | 보충 포드 레이블입니다. 선택기에 사용되지 않습니다. |
| `common.labels`                                          |                                                            | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `deployment.strategy`                                    | `{}`                                                       | 배포에서 사용할 업데이트 전략을 구성할 수 있습니다 |
| `enabled`                                                | `true`                                                     | GitLab Exporter 활성화 플래그 |
| `extraContainers`                                        |                                                            | 포함할 컨테이너 목록을 포함하는 여러 줄 리터럴 스타일 문자열 |
| `extraInitContainers`                                    |                                                            | 포함할 추가 init 컨테이너 목록 |
| `extraVolumeMounts`                                      |                                                            | 수행할 추가 볼륨 마운트 목록 |
| `extraVolumes`                                           |                                                            | 생성할 추가 볼륨 목록 |
| `extraEnv`                                               |                                                            | 노출할 추가 환경 변수 목록 |
| `extraEnvFrom`                                           |                                                            | 다른 데이터 소스에서 노출할 추가 환경 변수 목록 |
| `image.pullPolicy`                                       | `IfNotPresent`                                             | GitLab 이미지 풀 정책 |
| `image.pullSecrets`                                      |                                                            | 이미지 저장소의 비밀 |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-exporter` | GitLab Exporter 이미지 저장소 |
| `image.tag`                                              |                                                            | 이미지 태그   |
| `init.image.repository`                                  |                                                            | initContainer 이미지 |
| `init.image.tag`                                         |                                                            | initContainer 이미지 태그 |
| `init.containerSecurityContext`                          |                                                            | initContainer 특정 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                    | initContainer 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                     | initContainer 특정:  컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                | initContainer 특정:  컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `metrics.enabled`                                        | `true`                                                     | 메트릭 엔드포인트를 스크래핑할 수 있도록 해야 하는지 여부 |
| `metrics.port`                                           | `9168`                                                     | 메트릭 엔드포인트 포트 |
| `metrics.path`                                           | `/metrics`                                                 | 메트릭 엔드포인트 경로 |
| `metrics.serviceMonitor.enabled`                         | `false`                                                    | Prometheus Operator가 메트릭 스크래핑을 관리하도록 ServiceMonitor를 생성해야 하는지 여부. 이를 활성화하면 `prometheus.io` 스크래핑 주석이 제거됩니다 |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                       | ServiceMonitor에 추가할 추가 레이블 |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                       | ServiceMonitor의 추가 엔드포인트 구성 |
| `metrics.annotations`                                    |                                                            | **DEPRECATED** 명시적 메트릭 주석을 설정합니다. 템플릿 콘텐츠로 대체됩니다. |
| `priorityClassName`                                      |                                                            | 포드에 할당된 [우선순위 클래스](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/). |
| `resources.requests.cpu`                                 | `75m`                                                      | GitLab Exporter 최소 CPU |
| `resources.requests.memory`                              | `100M`                                                     | GitLab Exporter 최소 메모리 |
| `serviceLabels`                                          | `{}`                                                       | 보충 서비스 레이블 |
| `service.externalPort`                                   | `9168`                                                     | GitLab Exporter 노출 포트 |
| `service.internalPort`                                   | `9168`                                                     | GitLab Exporter 내부 포트 |
| `service.name`                                           | `gitlab-exporter`                                          | GitLab Exporter 서비스 이름 |
| `service.type`                                           | `ClusterIP`                                                | GitLab Exporter 서비스 유형 |
| `serviceAccount.annotations`                             | `{}`                                                       | ServiceAccount 주석 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                    | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다 |
| `serviceAccount.create`                                  | `false`                                                    | ServiceAccount를 생성해야 하는지 여부를 나타냅니다 |
| `serviceAccount.enabled`                                 | `false`                                                    | ServiceAccount를 사용해야 하는지 여부를 나타냅니다 |
| `serviceAccount.name`                                    |                                                            | ServiceAccount의 이름입니다. 설정하지 않으면 전체 차트 이름이 사용됩니다 |
| `securityContext.fsGroup`                                | `1000`                                                     | 포드를 시작해야 하는 그룹 ID |
| `securityContext.runAsUser`                              | `1000`                                                     | 포드를 시작해야 하는 사용자 ID |
| `securityContext.fsGroupChangePolicy`                    |                                                            | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                           | 사용할 Seccomp 프로필 |
| `containerSecurityContext`                               |                                                            | 컨테이너가 시작되는 컨테이너 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)를 재정의합니다 |
| `containerSecurityContext.runAsUser`                     | `1000`                                                     | 컨테이너가 시작되는 특정 보안 컨텍스트 사용자 ID를 덮어쓸 수 있습니다. |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                    | 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `containerSecurityContext.runAsNonRoot`                  | `false`                                                    | 컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                | Gitaly 컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `tolerations`                                            | `[]`                                                       | 포드 할당을 위한 용인 레이블 |
| `psql.port`                                              |                                                            | PostgreSQL 서버 포트를 설정합니다. `global.psql.port`보다 우선합니다. |
| `tls.enabled`                                            | `false`                                                    | GitLab Exporter TLS 활성화 |
| `tls.secretName`                                         | `{Release.Name}-gitlab-exporter-tls`                       | GitLab Exporter TLS 보안 정보입니다. [Kubernetes TLS 보안 정보](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)를 가리켜야 합니다. |
| `listenAddr`                                             | `*`                                                       | GitLab Exporter 수신 주소입니다. |

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

개인 레지스트리 및 해당 인증 방법에 대한 추가 세부사항은 [Kubernetes 설명서](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)에서 찾을 수 있습니다.

다음은 `pullSecrets`의 예시 사용입니다:

```yaml
image:
  repository: my.image.repository
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

### affinity {#affinity}

자세한 내용은 [`affinity`](../_index.md#affinity)를 참조하세요.

### 주석 {#annotations}

`annotations`을 사용하면 GitLab Exporter 포드에 주석을 추가할 수 있습니다. 예를 들어:

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## 전역 설정 {#global-settings}

차트 간에 공통 전역 설정을 공유합니다. [전역 문서](../../globals.md)에서 GitLab 및 Registry 호스트명과 같은 일반적인 구성 옵션을 참조하세요.

## 차트 설정 {#chart-settings}

다음 값은 GitLab Exporter 포드를 구성하는 데 사용됩니다.

### metrics.enabled {#metricsenabled}

기본적으로 포드는 `/metrics`에서 메트릭 엔드포인트를 노출합니다. 메트릭이 활성화되면 각 포드에 주석이 추가되어 Prometheus 서버가 노출된 메트릭을 검색하고 스크래핑할 수 있습니다.
