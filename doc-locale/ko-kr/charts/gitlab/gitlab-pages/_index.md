---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Pages 차트 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

`gitlab-pages` 부차 차트는 GitLab 프로젝트에서 정적 웹사이트를 제공하기 위한 데몬을 제공합니다.

## 요구 사항 {#requirements}

이 차트는 Workhorse 서비스에 대한 액세스가 필요하며, 완전한 GitLab 차트의 일부이거나 이 차트가 배포되는 Kubernetes 클러스터에서 도달할 수 있는 외부 서비스로 제공될 수 있습니다.

## 구성 {#configuration}

`gitlab-pages` 차트는 다음과 같이 구성됩니다:  [전역 설정](#global-settings) 및 [차트 설정](#chart-settings).

## 전역 설정 {#global-settings}

차트 간에 공통 전역 설정을 공유합니다. [Globals 설명서](../../globals.md#configure-gitlab-pages)를 참조하세요.

## 차트 설정 {#chart-settings}

다음 두 섹션의 표에는 `helm install` 명령에 `--set` 플래그를 사용하여 제공할 수 있는 모든 가능한 차트 구성이 포함되어 있습니다.

### 일반 설정 {#general-settings}

| 매개변수                                                | 기본값                                                 | 설명 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                    | 포드 할당을 위한 [선호도 규칙](../_index.md#affinity) |
| `annotations`                                            |                                                         | 포드 주석 |
| `common.labels`                                          | `{}`                                                    | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `deployment.strategy`                                    | `{}`                                                    | 배포에서 사용하는 업데이트 전략을 구성하도록 허용합니다. 제공되지 않으면 클러스터 기본값이 사용됩니다. |
| `extraEnv`                                               |                                                         | 노출할 추가 환경 변수 목록 |
| `extraEnvFrom`                                           |                                                         | 노출할 다른 데이터 소스의 추가 환경 변수 목록 |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`       | 동작은 상향 및 하향 스케일링 동작의 사양을 포함합니다(`autoscaling/v2beta2` 이상 필요). |
| `hpa.customMetrics`                                      | `[]`                                                    | 사용자 정의 메트릭은 원하는 복제본 수를 계산하는 데 사용할 사양을 포함합니다(`targetAverageUtilization`에 구성된 평균 CPU 활용률의 기본 사용을 재정의함). |
| `hpa.cpu.targetType`                                     | `AverageValue`                                          | 자동 스케일링 CPU 대상 유형을 설정하고, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.cpu.targetAverageValue`                             | `100m`                                                  | 자동 스케일링 CPU 대상 값을 설정합니다 |
| `hpa.cpu.targetAverageUtilization`                       |                                                         | 자동 스케일링 CPU 대상 활용률을 설정합니다 |
| `hpa.memory.targetType`                                  |                                                         | 자동 스케일링 메모리 대상 유형을 설정하고, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.memory.targetAverageValue`                          |                                                         | 자동 스케일링 메모리 대상 값을 설정합니다 |
| `hpa.memory.targetAverageUtilization`                    |                                                         | 자동 스케일링 메모리 대상 활용률을 설정합니다 |
| `hpa.minReplicas`                                        | `1`                                                     | 최소 복제본 수 |
| `hpa.maxReplicas`                                        | `10`                                                    | 최대 복제본 수 |
| `hpa.targetAverageValue`                                 |                                                         | **DEPRECATED** 자동 스케일링 CPU 대상 값을 설정합니다 |
| `image.pullPolicy`                                       | `IfNotPresent`                                          | GitLab 이미지 풀 정책 |
| `image.pullSecrets`                                      |                                                         | 이미지 저장소의 비밀 |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-pages` | GitLab Pages 이미지 저장소 |
| `image.tag`                                              |                                                         | 이미지 태그   |
| `init.image.repository`                                  |                                                         | initContainer 이미지 |
| `init.image.tag`                                         |                                                         | initContainer 이미지 태그 |
| `init.containerSecurityContext`                          |                                                         | initContainer 특정 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                 | initContainer 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                  | initContainer 특정:  컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                             | initContainer 특정:  컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `keda.enabled`                                           | `false`                                                 | [KEDA](https://keda.sh/) `ScaledObjects`를 `HorizontalPodAutoscalers` 대신 사용합니다 |
| `keda.pollingInterval`                                   | `30`                                                    | 각 트리거를 확인하는 간격 |
| `keda.cooldownPeriod`                                    | `300`                                                   | 마지막 트리거가 활성으로 보고된 후 리소스를 0으로 다시 스케일링할 때까지 기다릴 기간 |
| `keda.minReplicaCount`                                   | `hpa.minReplicas`                                       | KEDA가 리소스를 축소할 최소 복제본 수입니다. |
| `keda.maxReplicaCount`                                   | `hpa.maxReplicas`                                       | KEDA가 리소스를 확장할 최대 복제본 수입니다. |
| `keda.fallback`                                          |                                                         | KEDA 폴백 구성, [설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)를 참조하세요 |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                         | KEDA가 생성할 HPA 리소스의 이름입니다. |
| `keda.restoreToOriginalReplicaCount`                     |                                                         | `ScaledObject`이 삭제된 후 대상 리소스를 원래 복제본 수로 다시 스케일링할지 여부를 지정합니다 |
| `keda.behavior`                                          | `hpa.behavior`                                          | 상향 및 하향 스케일링 동작의 사양입니다. |
| `keda.triggers`                                          |                                                         | 대상 리소스의 스케일링을 활성화할 트리거 목록, `hpa.cpu` 및 `hpa.memory`에서 계산된 트리거로 기본값 |
| `metrics.enabled`                                        | `true`                                                  | 메트릭 엔드포인트를 스크래핑할 수 있도록 해야 하는지 여부 |
| `metrics.port`                                           | `9235`                                                  | 메트릭 엔드포인트 포트 |
| `metrics.path`                                           | `/metrics`                                              | 메트릭 엔드포인트 경로 |
| `metrics.serviceMonitor.enabled`                         | `false`                                                 | Prometheus Operator가 메트릭 스크래핑을 관리하도록 ServiceMonitor를 생성해야 하는지 여부. 이를 활성화하면 `prometheus.io` 스크래핑 주석이 제거됩니다 |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                    | ServiceMonitor에 추가할 추가 레이블 |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                    | ServiceMonitor의 추가 엔드포인트 구성 |
| `metrics.annotations`                                    |                                                         | **DEPRECATED** 명시적 메트릭 주석을 설정합니다. 템플릿 콘텐츠로 대체됩니다. |
| `metrics.tls.enabled`                                    | `false`                                                 | 메트릭 엔드포인트에 대해 TLS 활성화됨 |
| `metrics.tls.secretName`                                 | `{Release.Name}-pages-metrics-tls`                      | 메트릭 엔드포인트 TLS 인증서 및 키용 비밀 |
| `priorityClassName`                                      |                                                         | 포드에 할당된 [우선순위 클래스](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/). |
| `podLabels`                                              |                                                         | 보충 포드 레이블입니다. 선택기에 사용되지 않습니다. |
| `resources.requests.cpu`                                 | `900m`                                                  | GitLab Pages 최소 CPU |
| `resources.requests.memory`                              | `2G`                                                    | GitLab Pages 최소 메모리 |
| `securityContext.fsGroup`                                | `1000`                                                  | 포드를 시작해야 하는 그룹 ID |
| `securityContext.runAsUser`                              | `1000`                                                  | 포드를 시작해야 하는 사용자 ID |
| `securityContext.fsGroupChangePolicy`                    |                                                         | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                        | 사용할 Seccomp 프로필 |
| `containerSecurityContext`                               |                                                         | 컨테이너가 시작되는 컨테이너 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)를 재정의합니다 |
| `containerSecurityContext.runAsUser`                     | `1000`                                                  | 컨테이너가 시작되는 특정 보안 컨텍스트 사용자 ID를 덮어쓰도록 허용합니다 |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                 | 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                  | 컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                             | Gitaly 컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `service.externalPort`                                   | `8090`                                                  | GitLab Pages 노출 포트 |
| `service.internalPort`                                   | `8090`                                                  | GitLab Pages 내부 포트 |
| `service.name`                                           | `gitlab-pages`                                          | GitLab Pages 서비스 이름 |
| `service.annotations`                                    |                                                         | 모든 pages 서비스에 대한 주석입니다. |
| `service.primary.annotations`                            |                                                         | 기본 서비스에만 주석을 추가합니다. |
| `service.metrics.annotations`                            |                                                         | 메트릭 서비스에만 주석을 추가합니다. |
| `service.customDomains.annotations`                      |                                                         | 사용자 정의 도메인 서비스에만 주석을 추가합니다. |
| `service.customDomains.type`                             | `LoadBalancer`                                          | 사용자 정의 도메인을 처리하기 위해 생성된 서비스 유형 |
| `service.customDomains.internalHttpsPort`                | `8091`                                                  | Pages 데몬이 HTTPS 요청을 수신하는 포트 |
| `service.customDomains.internalHttpsPort`                | `8091`                                                  | Pages 데몬이 HTTPS 요청을 수신하는 포트 |
| `service.customDomains.nodePort.http`                    |                                                         | HTTP 연결을 위해 열 노드 포트입니다. `service.customDomains.type`이 `NodePort`인 경우에만 유효합니다 |
| `service.customDomains.nodePort.https`                   |                                                         | HTTPS 연결을 위해 열 노드 포트입니다. `service.customDomains.type`이 `NodePort`인 경우에만 유효합니다 |
| `service.sessionAffinity`                                | `None`                                                  | 세션 선호도 유형입니다. `ClientIP` 또는 `None`이어야 합니다(이는 클러스터 내에서 발생하는 트래픽에만 의미가 있음) |
| `service.sessionAffinityConfig`                          |                                                         | 세션 선호도 구성입니다. `service.sessionAffinity` == `ClientIP`인 경우 기본 세션 스티키 시간은 3시간(`10800`)입니다 |
| `serviceAccount.annotations`                             | `{}`                                                    | ServiceAccount 주석 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                 | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다 |
| `serviceAccount.create`                                  | `false`                                                 | ServiceAccount를 생성해야 하는지 여부를 나타냅니다 |
| `serviceAccount.enabled`                                 | `false`                                                 | ServiceAccount를 사용해야 하는지 여부를 나타냅니다 |
| `serviceAccount.name`                                    |                                                         | ServiceAccount의 이름입니다. 설정하지 않으면 전체 차트 이름이 사용됩니다 |
| `serviceLabels`                                          | `{}`                                                    | 보충 서비스 레이블 |
| `tolerations`                                            | `[]`                                                    | 포드 할당을 위한 용인 레이블 |

### Pages 특정 설정 {#pages-specific-settings}

| 매개변수                   | 기본값 | 설명 |
|-----------------------------|---------|-------------|
| `artifactsServerTimeout`    | `10`    | 아티팩트 서버에 대한 프록시된 요청의 시간 초과(초) |
| `artifactsServerUrl`        |         | 아티팩트 요청을 프록시하기 위한 API URL |
| `extraVolumeMounts`         |         | 추가할 추가 볼륨 마운트 목록 |
| `extraVolumes`              |         | 생성할 추가 볼륨 목록 |
| `gitlabCache.cleanup`       | int     | 참조:  [Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabCache.expiry`        | int     | 참조:  [Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabCache.refresh`       | int     | 참조:  [Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabClientHttpTimeout`   |         | GitLab API HTTP 클라이언트 연결 시간 초과(초) |
| `gitlabClientJwtExpiry`     |         | JWT 토큰 만료 시간(초) |
| `gitlabRetrieval.interval`  | int     | 참조:  [Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabRetrieval.retries`   | int     | 참조:  [Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabRetrieval.timeout`   | int     | 참조:  [Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabServer`              |         | GitLab 서버 FQDN |
| `headers`                   | `[]`    | 각 응답으로 클라이언트에 전송해야 하는 추가 HTTP 헤더를 지정합니다. 여러 헤더는 배열로 제공할 수 있으며, 헤더와 값은 하나의 문자열로 제공할 수 있습니다. 예를 들어 `['my-header: myvalue', 'my-other-header: my-other-value']` |
| `insecureCiphers`           | `false` | 기본 암호 스위트 목록을 사용하며, 3DES 및 RC4와 같은 안전하지 않은 암호를 포함할 수 있습니다 |
| `internalGitlabServer`      |         | API 요청에 사용되는 내부 GitLab 서버 |
| `logFormat`                 | `json`  | 로그 출력 형식 |
| `logVerbose`                | `false` | 상세 로깅 |
| `maxConnections`            |         | HTTP, HTTPS 또는 프록시 수신기에 대한 동시 연결 수의 제한 |
| `maxURILength`              |         | URI의 길이를 제한하고, 0은 무제한입니다. 기본 설정의 경우 [GitLab Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings)에서 `max_uri_length`를 참조하세요 |
| `propagateCorrelationId`    |         | 들어오는 요청 헤더 `X-Request-ID`에서 기존 Correlation-ID를 재사용합니다(있는 경우) |
| `redirectHttp`              | `false` | HTTP에서 HTTPS로 페이지 리디렉션 |
| `sentry.enabled`            | `false` | Sentry 보고 활성화 |
| `sentry.dsn`                |         | Sentry 충돌 보고를 보낼 주소 |
| `sentry.environment`        |         | Sentry 충돌 보고의 환경 |
| `serverShutdowntimeout`     | `30s`   | GitLab Pages 서버 종료 시간 초과(초) |
| `statusUri`                 |         | 상태 페이지의 URL 경로 |
| `tls.minVersion`            |         | 최소 SSL/TLS 버전을 지정합니다 |
| `tls.maxVersion`            |         | 최대 SSL/TLS 버전을 지정합니다 |
| `useHTTPProxy`              | `false` | GitLab Pages가 역방향 프록시 뒤에 있을 때 이 옵션을 사용하세요. |
| `useProxyV2`                | `false` | HTTPS 요청이 PROXYv2 프로토콜을 활용하도록 강제합니다. |
| `zipCache.cleanup`          | int     | 참조:  [Zip 서빙 및 캐시 구성](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipCache.expiration`       | int     | 참조:  [Zip 서빙 및 캐시 구성](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipCache.refresh`          | int     | 참조:  [Zip 서빙 및 캐시 구성](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipOpenTimeout`            | int     | 참조:  [Zip 서빙 및 캐시 구성](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipHTTPClientTimeout`      | int     | 참조:  [Zip 서빙 및 캐시 구성](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `rateLimitSourceIP`         |         | 참조:  [GitLab Pages 속도 제한](https://docs.gitlab.com/administration/pages/#rate-limits). |
| `rateLimitSourceIPBurst`    |         | 참조:  [GitLab Pages 속도 제한](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitDomain`           |         | 참조:  [GitLab Pages 속도 제한](https://docs.gitlab.com/administration/pages/#rate-limits). |
| `rateLimitDomainBurst`      |         | 참조:  [GitLab Pages 속도 제한](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitTLSSourceIP`      |         | 참조:  [GitLab Pages 속도 제한](https://docs.gitlab.com/administration/pages/#rate-limits). |
| `rateLimitTLSSourceIPBurst` |         | 참조:  [GitLab Pages 속도 제한](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitTLSDomain`        |         | 참조:  [GitLab Pages 속도 제한](https://docs.gitlab.com/administration/pages/#rate-limits). |
| `rateLimitTLSDomainBurst`   |         | 참조:  [GitLab Pages 속도 제한](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitSubnetsAllowList` |         | 참조:  [GitLab Pages 속도 제한](#rate-limits) |
| `serverReadTimeout`         | `5s`    | 참조:  [GitLab Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings) |
| `serverReadHeaderTimeout`   | `1s`    | 참조:  [GitLab Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings) |
| `serverWriteTimeout`        | `5m`    | 참조:  [GitLab Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings) |
| `serverKeepAlive`           | `15s`   | 참조:  [GitLab Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings) |
| `authTimeout`               | `5s`    | 참조:  [GitLab Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings) |
| `authCookieSessionTimeout`  | `10m`   | 참조:  [GitLab Pages 전역 설정](https://docs.gitlab.com/administration/pages/#global-settings) |

### `ingress` 구성 {#configuring-the-ingress}

이 섹션은 GitLab Pages Ingress를 제어합니다.

| 이름                   |  유형   | 기본값 | 설명 |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | 문자열  |         | `apiVersion` 필드에서 사용할 값입니다. |
| `annotations`          | 문자열  |         | 이 필드는 [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)에 대한 표준 `annotations`과 정확히 일치합니다. |
| `configureCertmanager` | 부울 | `false` | Ingress 주석 `cert-manager.io/issuer` 및 `acme.cert-manager.io/http01-edit-in-place`를 토글합니다. GitLab Pages용 TLS 인증서의 cert-manager를 통한 획득은 와일드카드 인증서 획득이 [DNS01 solver](https://cert-manager.io/docs/configuration/acme/dns01/) 가 있는 cert-manager Issuer가 필요하고 이 차트에 의해 배포된 Issuer는 [HTTP01 solver](https://cert-manager.io/docs/configuration/acme/http01/)만 제공하므로 비활성화됩니다. 자세한 내용은 [GitLab Pages용 TLS 요구사항](../../../installation/tls.md)을 참조하세요. |
| `enabled`              | 부울 |         | Ingress 객체를 생성할 서비스를 지원하는지 여부를 제어하는 설정입니다. 설정되지 않으면 `global.ingress.enabled` 설정이 사용됩니다. |
| `tls.enabled`          | 부울 |         | `false`로 설정하면 Pages 부차 차트에 대한 TLS가 비활성화됩니다. 이는 주로 `ingress-level`에서 TLS 종료를 사용할 수 없는 경우에 유용하며, Ingress Controller 앞에 TLS 종료 프록시가 있는 경우입니다. |
| `tls.secretName`       | 문자열  |         | pages URL에 대한 유효한 인증서 및 키를 포함하는 Kubernetes TLS 비밀의 이름입니다. 설정하지 않으면 `global.ingress.tls.secretName`이 대신 사용됩니다. 기본값은 설정되지 않은 상태입니다. |

## 차트 구성 예시 {#chart-configuration-examples}

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
  - name: example-volume
    mountPath: /etc/example
```

### `networkpolicy` 구성 {#configuring-the-networkpolicy}

이 섹션은 [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)를 제어합니다. 이 구성은 선택 사항이며 포드의 Egress 및 Ingress를 특정 엔드포인트로 제한하는 데 사용됩니다.

| 이름              |  유형   | 기본값 | 설명 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | 부울 | `false` | 이 설정은 `NetworkPolicy`을 활성화합니다 |
| `ingress.enabled` | 부울 | `false` | `true`로 설정하면 `Ingress` 네트워크 정책이 활성화됩니다. 규칙을 지정하지 않으면 모든 Ingress 연결이 차단됩니다. |
| `ingress.rules`   |  배열  | `[]`    | Ingress 정책에 대한 규칙, 자세한 내용은 <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> 및 아래 예제를 참조하세요 |
| `egress.enabled`  | 부울 | `false` | `true`로 설정하면 `Egress` 네트워크 정책이 활성화됩니다. 규칙을 지정하지 않으면 모든 egress 연결이 차단됩니다. |
| `egress.rules`    |  배열  | `[]`    | egress 정책에 대한 규칙, 자세한 내용은 <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> 및 아래 예제를 참조하세요 |

### 예제 네트워크 정책 {#example-network-policy}

`gitlab-pages` 서비스는 포트 80 및 443에 대한 Ingress 연결과 기본 workhorse 포트 8181로의 다양한 Egress 연결이 필요합니다. 이 예제는 다음 네트워크 정책을 추가합니다:

- Ingress 요청 허용:
  - `nginx-ingress` 포드로부터 `8090`포트로
  - `prometheus` 포드로부터 `9235`포트로
- Egress 요청 허용:
  - `kube-dns`에서 `53` 포트로
  - `webservice` 포드에서 `8181`포트로
  - AWS VPC 엔드포인트 S3 `172.16.1.0/24`같은 엔드포인트에서 포트 `443`로

제공된 예제는 단지 예제일 뿐이며 완전하지 않을 수 있습니다. 이 예제는 `kube-dns`이 네임스페이스 `kube-system`에 배포되었고, `prometheus`이 네임스페이스 `monitoring`에 배포되었으며, `nginx-ingress`가 네임스페이스 `nginx-ingress`에 배포되었다는 가정을 기반으로 합니다.

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
          - port: 9235
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 8090
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
          - podSelector:
              matchLabels:
                app: webservice
        ports:
          - port: 8181
```

### GitLab Pages에 대한 TLS 액세스 {#tls-access-to-gitlab-pages}

GitLab Pages 기능에 TLS 액세스를 하려면 다음을 수행해야 합니다:

1. GitLab Pages 도메인에 대한 전용 와일드카드 인증서를 다음 형식으로 생성합니다: `*.pages.<yourdomain>`.

1. Kubernetes에서 비밀을 생성합니다:

   ```shell
   kubectl create secret tls tls-star-pages-<mysecret> --cert=<path/to/fullchain.pem> --key=<path/to/privkey.pem>
   ```

1. GitLab Pages가 이 비밀을 사용하도록 구성합니다:

   ```yaml
   gitlab:
     gitlab-pages:
       ingress:
         tls:
           secretName: tls-star-pages-<mysecret>
   ```

1. DNS 공급자에서 `*.pages.<yourdomaindomain>`이라는 이름의 DNS 항목을 생성하고 LoadBalancer를 가리킵니다.

### 와일드카드 DNS가 없는 Pages 도메인 {#pages-domain-without-wildcard-dns}

{{< history >}}

- GitLab 17.2에서 [도입](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5570) 된 [베타](https://docs.gitlab.com/policy/development_stages_support/#beta)입니다.
- GitLab 17.4에서 [일반적으로 사용 가능](https://gitlab.com/gitlab-org/gitlab/-/issues/483365)합니다.

{{< /history >}}

> [!warning] GitLab Pages는 한 번에 하나의 URL 스키마만 지원합니다:  와일드카드 DNS를 사용하거나 와일드카드 DNS 없이. `namespaceInPath`를 활성화하면 기존 GitLab Pages 웹사이트는 와일드카드 DNS가 없는 도메인에서만 액세스할 수 있습니다.

1. 전역 Pages 설정에서 `namespaceInPath`을 활성화합니다.

   ```yaml
   global:
     pages:
       namespaceInPath: true
   ```

1. DNS 공급자에서 `pages.<yourdomaindomain>`이라는 이름의 DNS 항목을 생성하고 LoadBalancer를 가리킵니다.

#### 와일드카드 DNS가 없는 GitLab Pages 도메인에 대한 TLS 액세스 {#tls-access-to-gitlab-pages-domain-without-wildcard-dns}

1. GitLab Pages 도메인에 대한 인증서를 다음 형식으로 생성합니다: `pages.<yourdomain>`.
1. Kubernetes에서 비밀을 생성합니다:

   ```shell
   kubectl create secret tls tls-star-pages-<mysecret> --cert=<path/to/fullchain.pem> --key=<path/to/privkey.pem>
   ```

1. GitLab Pages가 이 비밀을 사용하도록 구성합니다:

   ```yaml
   gitlab:
     gitlab-pages:
       ingress:
         tls:
           secretName: tls-star-pages-<mysecret>
   ```

#### 액세스 제어 구성 {#configure-access-control}

1. 전역 pages 설정에서 `accessControl`을 활성화합니다.

   ```yaml
   global:
     pages:
       accessControl: true
   ```

1. 선택 사항입니다. [TLS 액세스](#tls-access-to-gitlab-pages-domain-without-wildcard-dns) 가 구성된 경우 GitLab Pages [System OAuth application](https://docs.gitlab.com/integration/oauth_provider/#create-an-instance-wide-application)의 리디렉션 URI를 업데이트하여 HTTPS 프로토콜을 사용합니다.

> [!warning] GitLab Pages는 OAuth 애플리케이션을 업데이트하지 않으며, 기본 `authRedirectUri`는 `https://pages.<yourdomaindomain>/projects/auth`으로 업데이트됩니다. 비공개 Pages 사이트에 액세스하는 동안 '포함된 리디렉션 URI가 유효하지 않습니다' 오류가 발생하면 GitLab Pages [System OAuth application](https://docs.gitlab.com/integration/oauth_provider/#create-an-instance-wide-application)의 리디렉션 URI를 `https://pages.<yourdomaindomain>/projects/auth`으로 업데이트합니다.

### 속도 제한 {#rate-limits}

속도 제한을 적용하여 서비스 거부(DoS) 공격의 위험을 최소화할 수 있습니다. 자세한 [속도 제한 설명서](https://docs.gitlab.com/administration/pages/#rate-limits)를 사용할 수 있습니다.

특정 IP 범위(서브넷)를 모든 속도 제한을 우회하도록 허용하려면:

- `rateLimitSubnetsAllowList`: 모든 속도 제한을 우회해야 하는 IP 범위(서브넷)로 허용 목록을 설정합니다.

#### 속도 제한 서브넷 허용 목록 구성 {#configure-rate-limits-subnets-allow-list}

`charts/gitlab/charts/gitlab-pages/values.yaml`에서 IP 범위(서브넷)를 사용하여 허용 목록을 설정합니다:

```yaml
gitlab:
  gitlab-pages:
    rateLimitSubnetsAllowList:
     - "1.2.3.4/24"
     - "2001:db8::1/32"
```

### KEDA 구성 {#configuring-keda}

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

### serviceAccount {#serviceaccount}

이 섹션에서는 ServiceAccount를 생성해야 하는지 여부와 기본 액세스 토큰을 Pod에 마운트해야 하는지 여부를 제어합니다.

| 이름                           |  유형   | 기본값 | 설명 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   맵   | `{}`    | ServiceAccount 주석. |
| `automountServiceAccountToken` | 부울 | `false` | 기본 ServiceAccount 액세스 토큰이 Pod에 마운트되어야 하는지 여부를 제어합니다. 특정 사이드카가 제대로 작동하도록 필요한 경우가 아니면(예: Istio) 이를 활성화하지 않아야 합니다. |
| `create`                       | 부울 | `false` | ServiceAccount를 생성해야 하는지 여부를 나타냅니다. |
| `enabled`                      | 부울 | `false` | ServiceAccount를 사용해야 하는지 여부를 나타냅니다. |
| `name`                         | 문자열  |         | ServiceAccount의 이름입니다. 설정하지 않으면 차트 전체 이름이 사용됩니다. |

### affinity {#affinity}

자세한 내용은 [`affinity`](../_index.md#affinity)를 참조하세요.
