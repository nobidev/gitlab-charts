---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Shell 차트 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

`gitlab-shell` 하위 차트는 Git SSH 액세스를 위해 구성된 SSH 서버를 제공합니다.

## 요구 사항 {#requirements}

이 차트는 Workhorse 서비스에 대한 액세스가 필요하며, 완전한 GitLab 차트의 일부이거나 이 차트가 배포되는 Kubernetes 클러스터에서 도달할 수 있는 외부 서비스로 제공될 수 있습니다.

## 설계 선택 사항 {#design-choices}

SSH 복제본을 쉽게 지원하고 SSH 승인된 키에 대한 공유 스토리지 사용을 피하기 위해 SSH [AuthorizedKeysCommand](https://man.openbsd.org/sshd_config#AuthorizedKeysCommand)를 사용하여 GitLab 승인된 키 엔드포인트에 대해 인증합니다. 그 결과, 이러한 Pod 내에서 AuthorizedKeys 파일을 유지하거나 업데이트하지 않습니다.

## 구성 {#configuration}

`gitlab-shell` 차트는 [외부 서비스](#external-services) 및 [차트 설정](#chart-settings)의 두 부분으로 구성됩니다. Ingress를 통해 노출되는 포트는 `global.shell.port`로 구성되며 기본값은 `22`입니다. Service의 외부 포트도 `global.shell.port`에 의해 제어됩니다.

## 설치 명령줄 옵션 {#installation-command-line-options}

| 매개변수                                                | 기본값                                                 | 설명 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                    | 포드 할당을 위한 [선호도 규칙](../_index.md#affinity) |
| `annotations`                                            |                                                         | 포드 주석 |
| `podLabels`                                              |                                                         | 보충 포드 레이블입니다. 선택기에 사용되지 않습니다. |
| `common.labels`                                          |                                                         | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `config.ciphers`                                         | 설명을 참조하세요.                                        | 허용되는 암호를 지정합니다. [Go 지원 알고리즘](https://pkg.go.dev/golang.org/x/crypto/ssh#SupportedAlgorithms)으로 기본 설정됩니다. FIPS 빌드의 경우 [FIPS 승인 암호](https://gitlab.com/gitlab-org/labkit/-/blob/7bb8cb3b9f0eca4a40744520ee87a696f85c9645/fips/ssh.go#L17-20)를 참조하세요. |
| `config.kexAlgorithms`                                   | 설명을 참조하세요.                                        | 사용 가능한 KEX(키 교환) 알고리즘을 지정합니다. [Go 지원 알고리즘](https://pkg.go.dev/golang.org/x/crypto/ssh#SupportedAlgorithms)으로 기본 설정됩니다. FIPS 빌드의 경우 [FIPS 승인 키 교환 알고리즘](https://gitlab.com/gitlab-org/labkit/-/blob/7bb8cb3b9f0eca4a40744520ee87a696f85c9645/fips/ssh.go#L13)을 참조하세요. |
| `config.macs`                                            | 설명을 참조하세요.                                        | 사용 가능한 MAC(메시지 인증 코드) 알고리즘을 지정합니다. [Go 지원 알고리즘](https://pkg.go.dev/golang.org/x/crypto/ssh#SupportedAlgorithms)으로 기본 설정됩니다. FIPS 빌드의 경우 [FIPS 승인 MAC](https://gitlab.com/gitlab-org/labkit/-/blob/7bb8cb3b9f0eca4a40744520ee87a696f85c9645/fips/ssh.go#L24-27)을 참조하세요. |
| `config.clientAliveInterval`                             | `0`                                                     | 그 외의 경우 유휴 연결에 대한 keepalive 핑 간격입니다. 기본값 0은 이 핑을 비활성화합니다. |
| `config.loginGraceTime`                                  | `60`                                                    | 사용자가 성공적으로 로그인하지 못한 경우 서버가 연결을 끊을 시간을 지정합니다. |
| `config.maxStartups.full`                                | `100`                                                   | SSHd 거부 확률이 선형적으로 증가하며 인증되지 않은 연결 수가 지정된 수에 도달하면 모든 인증되지 않은 연결 시도가 거부됩니다. |
| `config.maxStartups.rate`                                | `30`                                                    | 인증되지 않은 연결이 너무 많을 때 SSHd는 지정된 확률로 연결을 거부합니다(선택 사항). |
| `config.maxStartups.start`                               | `10`                                                    | 현재 인증되지 않은 연결이 지정된 수보다 많으면 SSHd는 일부 확률로 연결 시도를 거부합니다(선택 사항). |
| `config.proxyProtocol`                                   | `false`                                                 | `gitlab-sshd` 데몬에 대한 PROXY 프로토콜 지원을 활성화합니다. |
| `config.proxyPolicy`                                     | `"use"`                                                 | PROXY 프로토콜 처리를 위한 정책을 지정합니다. 값은 `use, require, ignore, reject` 중 하나여야 합니다. |
| `config.proxyHeaderTimeout`                              | `"500ms"`                                               | `gitlab-sshd`이 PROXY 프로토콜 헤더 읽기를 포기하기 전에 대기할 최대 지속 시간입니다. 단위를 포함해야 합니다: `ms`, `s` 또는 `m`. |
| `config.publicKeyAlgorithms`                             | `[]`                                                    | 공개 키 알고리즘의 사용자 지정 목록입니다. 비어 있으면 기본 알고리즘이 사용됩니다. |
| `config.gssapi.enabled`                                  | `false`                                                 | `gitlab-sshd` 데몬에 대한 GSS-API 지원을 활성화합니다. |
| `config.gssapi.keytab.secret`                            |                                                         | gssapi-with-mic 인증 방법을 위한 keytab을 보유하는 Kubernetes 비밀의 이름입니다. |
| `config.gssapi.keytab.key`                               | `keytab`                                                | Kubernetes 비밀에서 keytab을 보유하는 키입니다. |
| `config.gssapi.krb5Config`                               |                                                         | GitLab Shell 컨테이너의 `/etc/krb5.conf` 파일 내용입니다. |
| `config.gssapi.servicePrincipalName`                     |                                                         | `gitlab-sshd` 데몬에서 사용할 Kerberos 서비스 이름입니다. |
| `config.lfs.pureSSHProtocol`                             | `false`                                                 | LFS Pure SSH 프로토콜 지원을 활성화합니다. |
| `config.pat.enabled`                                     | `true`                                                  | SSH를 사용한 PAT 활성화 |
| `config.pat.allowedScopes`                               | `[]`                                                    | SSH로 생성된 PAT에 대해 허용되는 범위의 배열입니다. |
| `config.trustedUserCAKeys.secret`                        |                                                         | 인스턴스 수준 SSH 인증서 인증을 위한 신뢰할 수 있는 사용자 CA 공개 키를 포함하는 Kubernetes 비밀의 이름입니다. `sshDaemon`이 `gitlab-sshd`일 때만 적용됩니다. |
| `config.trustedUserCAKeys.keys`                          | `[]`                                                    | 비밀 내에 CA 공개 키 데이터를 포함하는 키 이름 목록(예: `["ca1.pub", "ca2.pub"]`). 이러한 CA 키로 서명된 인증서는 인증을 위해 신뢰되며, 인증서의 `KeyId`이 GitLab 사용자 이름으로 사용됩니다. |
| `opensshd.supplemental_config`                           |                                                         | `sshd_config`에 추가되는 추가 구성입니다. [설명서](https://manpages.debian.org/bookworm/openssh-server/sshd_config.5.en.html)에 엄격하게 정렬합니다. |
| `deployment.livenessProbe.initialDelaySeconds`           | `10`                                                    | 생동성 프로브가 시작되기 전의 지연 |
| `deployment.livenessProbe.periodSeconds`                 | `10`                                                    | 생동성 프로브를 수행하는 빈도 |
| `deployment.livenessProbe.timeoutSeconds`                | `3`                                                     | 생동성 프로브 시간이 초과될 때 |
| `deployment.livenessProbe.successThreshold`              | `1`                                                     | 생동성 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `deployment.livenessProbe.failureThreshold`              | `3`                                                     | 생동성 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `deployment.readinessProbe.initialDelaySeconds`          | `10`                                                    | 준비 프로브가 시작되기 전의 지연 |
| `deployment.readinessProbe.periodSeconds`                | `5`                                                     | 준비 프로브를 수행하는 빈도 |
| `deployment.readinessProbe.timeoutSeconds`               | `3`                                                     | 준비 프로브 시간이 초과될 때 |
| `deployment.readinessProbe.successThreshold`             | `1`                                                     | 준비 프로브가 실패한 후 성공한 것으로 간주되기 위한 최소 연속 성공 횟수 |
| `deployment.readinessProbe.failureThreshold`             | `2`                                                     | 준비 프로브가 성공한 후 실패한 것으로 간주되기 위한 최소 연속 실패 횟수 |
| `deployment.strategy`                                    | `{}`                                                    | 배포에서 사용할 업데이트 전략을 구성할 수 있습니다 |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                    | Kubernetes이 Pod가 강제로 종료될 때까지 대기할 시간(초) |
| `enabled`                                                | `true`                                                  | Shell 활성화 플래그 |
| `extraContainers`                                        |                                                         | 포함할 컨테이너 목록을 포함하는 여러 줄 리터럴 스타일 문자열 |
| `extraInitContainers`                                    |                                                         | 포함할 추가 init 컨테이너 목록 |
| `extraVolumeMounts`                                      |                                                         | 수행할 추가 볼륨 마운트 목록 |
| `extraVolumes`                                           |                                                         | 생성할 추가 볼륨 목록 |
| `extraEnv`                                               |                                                         | 노출할 추가 환경 변수 목록 |
| `extraEnvFrom`                                           |                                                         | 다른 데이터 소스에서 노출할 추가 환경 변수 목록 |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`       | 동작은 상향 및 하향 스케일링 동작의 사양을 포함합니다(`autoscaling/v2beta2` 이상 필요). |
| `hpa.customMetrics`                                      | `[]`                                                    | 사용자 정의 메트릭은 원하는 복제본 수를 계산하는 데 사용할 사양을 포함합니다(`targetAverageUtilization`에 구성된 평균 CPU 활용률의 기본 사용을 재정의함). |
| `hpa.cpu.targetType`                                     | `AverageValue`                                          | 자동 스케일링 CPU 대상 유형을 설정하고, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.cpu.targetAverageValue`                             | `100m`                                                  | 자동 스케일링 CPU 대상 값을 설정합니다 |
| `hpa.cpu.targetAverageUtilization`                       |                                                         | 자동 스케일링 CPU 대상 활용률을 설정합니다 |
| `hpa.memory.targetType`                                  |                                                         | 자동 스케일링 메모리 대상 유형을 설정하고, `Utilization` 또는 `AverageValue` 중 하나여야 합니다. |
| `hpa.memory.targetAverageValue`                          |                                                         | 자동 스케일링 메모리 대상 값을 설정합니다 |
| `hpa.memory.targetAverageUtilization`                    |                                                         | 자동 스케일링 메모리 대상 활용률을 설정합니다 |
| `hpa.targetAverageValue`                                 |                                                         | **DEPRECATED** 자동 스케일링 CPU 대상 값을 설정합니다 |
| `image.pullPolicy`                                       | `IfNotPresent`                                          | Shell 이미지 풀 정책 |
| `image.pullSecrets`                                      |                                                         | 이미지 저장소의 비밀 |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-shell` | Shell 이미지 저장소 |
| `image.tag`                                              | `master`                                                | Shell 이미지 태그 |
| `init.image.repository`                                  |                                                         | initContainer 이미지 |
| `init.image.tag`                                         |                                                         | initContainer 이미지 태그 |
| `init.containerSecurityContext`                          |                                                         | initContainer 특정 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                 | initContainer 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                  | initContainer 특정:  컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                             | initContainer 특정:  컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `keda.enabled`                                           | `false`                                                 | [KEDA](https://keda.sh/) `ScaledObjects`를 `HorizontalPodAutoscalers` 대신 사용합니다 |
| `keda.pollingInterval`                                   | `30`                                                    | 각 트리거를 확인하는 간격 |
| `keda.cooldownPeriod`                                    | `300`                                                   | 마지막 트리거가 활성으로 보고된 후 리소스를 0으로 다시 스케일링할 때까지 기다릴 기간 |
| `keda.minReplicaCount`                                   | `minReplicas`                                           | KEDA가 리소스를 축소할 최소 복제본 수입니다. |
| `keda.maxReplicaCount`                                   | `maxReplicas`                                           | KEDA가 리소스를 확장할 최대 복제본 수입니다. |
| `keda.fallback`                                          |                                                         | KEDA 폴백 구성, [설명서](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)를 참조하세요 |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                         | KEDA가 생성할 HPA 리소스의 이름입니다. |
| `keda.restoreToOriginalReplicaCount`                     |                                                         | `ScaledObject`이 삭제된 후 대상 리소스를 원래 복제본 수로 다시 스케일링할지 여부를 지정합니다 |
| `keda.behavior`                                          | `hpa.behavior`                                          | 상향 및 하향 스케일링 동작의 사양입니다. |
| `keda.triggers`                                          |                                                         | 대상 리소스의 스케일링을 활성화할 트리거 목록, `hpa.cpu` 및 `hpa.memory`에서 계산된 트리거로 기본값 |
| `logging.format`                                         | `json`                                                  | 구조화되지 않은 로그의 경우 `text`로 설정합니다. |
| `logging.sshdLogLevel`                                   | `ERROR`                                                 | 기본 SSH 데몬의 로그 수준 |
| `priorityClassName`                                      |                                                         | 포드에 할당된 [우선순위 클래스](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/). |
| `replicaCount`                                           | `1`                                                     | Shell 복제본 |
| `serviceLabels`                                          | `{}`                                                    | 보충 서비스 레이블 |
| `service.allocateLoadBalancerNodePorts`                  | 설정되지 않음, Kubernetes 기본값을 사용하려면.               | LoadBalancer 서비스에서 NodePort 할당을 비활성화하고 [설명서](https://kubernetes.io/docs/concepts/services-networking/service/#load-balancer-nodeport-allocation)를 참조하세요. |
| `service.externalTrafficPolicy`                          | `Cluster`                                               | Shell 서비스 외부 트래픽 정책(클러스터 또는 로컬) |
| `service.internalPort`                                   | `2222`                                                  | Shell 내부 포트 |
| `service.nodePort`                                       |                                                         | 설정된 경우 Shell nodePort를 설정합니다. |
| `service.name`                                           | `gitlab-shell`                                          | Shell 서비스 이름 |
| `service.type`                                           | `ClusterIP`                                             | Shell 서비스 유형 |
| `service.loadBalancerIP`                                 |                                                         | LoadBalancer에 할당할 IP 주소(지원하는 경우) |
| `service.loadBalancerSourceRanges`                       |                                                         | LoadBalancer에 액세스할 수 있는 IP CIDR 목록(지원하는 경우) |
| `serviceAccount.annotations`                             | `{}`                                                    | ServiceAccount 주석 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                 | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다 |
| `serviceAccount.create`                                  | `false`                                                 | ServiceAccount를 생성해야 하는지 여부를 나타냅니다 |
| `serviceAccount.enabled`                                 | `false`                                                 | ServiceAccount를 사용해야 하는지 여부를 나타냅니다 |
| `serviceAccount.name`                                    |                                                         | ServiceAccount의 이름입니다. 설정하지 않으면 전체 차트 이름이 사용됩니다 |
| `securityContext.fsGroup`                                | `1000`                                                  | 포드를 시작해야 하는 그룹 ID |
| `securityContext.runAsUser`                              | `1000`                                                  | 포드를 시작해야 하는 사용자 ID |
| `securityContext.fsGroupChangePolicy`                    |                                                         | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                        | 사용할 Seccomp 프로필 |
| `containerSecurityContext`                               |                                                         | 컨테이너가 시작되는 컨테이너 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)를 재정의합니다 |
| `containerSecurityContext.runAsUser`                     | `1000`                                                  | 컨테이너가 시작되는 특정 보안 컨텍스트를 덮어쓸 수 있습니다 |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                 | 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                  | 컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                             | Gitaly 컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `sshDaemon`                                              | `openssh`                                               | 실행할 SSH 데몬을 선택합니다. 가능한 값(`openssh`, `gitlab-sshd`) |
| `tolerations`                                            | `[]`                                                    | 포드 할당을 위한 용인 레이블 |
| `traefik.entrypoint`                                     | `gitlab-shell`                                          | traefik 사용 시 GitLab Shell에 사용할 traefik entrypoint입니다. `gitlab-shell`로 기본 설정됩니다. |
| `traefik.tcpAnnotations`                                 | `{}`                                                    | traefik 사용 시 IngressRouteTCP 리소스에 추가할 주석입니다. 기본적으로 주석이 없습니다. |
| `traefik.tcpMiddlewares`                                 | `[]`                                                    | traefik 사용 시 IngressRouteTCP 리소스에 추가할 TCP 미들웨어입니다. 기본적으로 미들웨어가 없습니다. |
| `workhorse.serviceName`                                  | `webservice`                                            | Workhorse 서비스 이름(기본적으로 Workhorse는 webservice Pod/서비스의 일부임) |
| `metrics.enabled`                                        | `false`                                                 | 메트릭 엔드포인트를 스크래핑에 사용 가능하게 해야 하는지 여부(`sshDaemon=gitlab-sshd` 필요). |
| `metrics.port`                                           | `9122`                                                  | 메트릭 엔드포인트 포트 |
| `metrics.path`                                           | `/metrics`                                              | 메트릭 엔드포인트 경로 |
| `metrics.serviceMonitor.enabled`                         | `false`                                                 | Prometheus Operator가 메트릭 스크래핑을 관리하도록 ServiceMonitor를 생성해야 하는지 여부. 이를 활성화하면 `prometheus.io` 스크래핑 주석이 제거됩니다 |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                    | ServiceMonitor에 추가할 추가 레이블 |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                    | ServiceMonitor의 추가 엔드포인트 구성 |
| `metrics.annotations`                                    |                                                         | **DEPRECATED** 명시적 메트릭 주석을 설정합니다. 템플릿 콘텐츠로 대체됩니다. |

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
  repository: my.shell.repository
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

### livenessProbe/readinessProbe {#livenessprobereadinessprobe}

`deployment.livenessProbe` 및 `deployment.readinessProbe`는 일부 시나리오에서 Pod의 종료를 제어하는 데 도움이 되는 메커니즘을 제공합니다.

더 큰 리포지토리는 생존 및 준비 프로브 시간을 일반적인 장기 실행 연결과 일치하도록 조정하면 이점을 얻습니다. 준비 프로브 지속 시간을 생존 프로브 지속 시간보다 짧게 설정하여 `clone` 및 `push` 작업 중 잠재적 중단을 최소화합니다. `terminationGracePeriodSeconds`을 증가시키고 스케줄러가 Pod를 종료하기 전에 이러한 작업에 더 많은 시간을 제공합니다. 아래의 예를 시작점으로 사용하여 더 큰 리포지토리 워크로드를 위해 GitLab Shell Pod를 조정하여 안정성 및 효율성을 높입니다.

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
  terminationGracePeriodSeconds: 300
```

이 구성에 대한 추가 세부 사항은 공식 [Kubernetes 설명서](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)를 참조하세요.

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

`annotations`을 사용하면 GitLab Shell Pod에 주석을 추가할 수 있습니다.

다음은 `annotations`의 사용 예입니다.

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
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
| `serviceName` | 문자열  | `webservice` | Workhorse 서버를 운영하는 `service`의 이름입니다. 기본적으로 Workhorse는 webservice Pod/서비스의 일부입니다. 이것이 존재하고 `host`이(가) 없으면 차트가 서비스 호스트 이름 및 현재 `.Release.Name`을(를) `host` 값 대신 템플릿화합니다. 이는 Workhorse를 전체 GitLab 차트의 일부로 사용할 때 편리합니다. |

## 차트 설정 {#chart-settings}

다음 값은 GitLab Shell Pod를 구성하는 데 사용됩니다.

### hostKeys.secret {#hostkeyssecret}

SSH 호스트 키를 가져올 Kubernetes `secret`의 이름입니다. 비밀의 키는 GitLab Shell에서 사용하기 위해 키 이름 `ssh_host_`으로 시작해야 합니다.

### authToken {#authtoken}

GitLab Shell은 Workhorse와의 통신에서 인증 토큰을 사용합니다. 공유 비밀을 사용하여 토큰을 GitLab Shell 및 Workhorse와 공유합니다.

```yaml
authToken:
 secret: gitlab-shell-secret
 key: secret
```

| 이름               |  유형  | 기본값 | 설명 |
|:-------------------|:------:|:--------|:------------|
| `authToken.key`    | 문자열 |         | 인증 토큰을 포함하는 위의 비밀에 있는 키의 이름입니다. |
| `authToken.secret` | 문자열 |         | 가져올 Kubernetes `Secret`의 이름입니다. |

### LoadBalancer 서비스 {#loadbalancer-service}

`service.type`이(가) `LoadBalancer`(으)로 설정되어 있으면 `service.loadBalancerIP`을(를) 선택적으로 지정하여 클라우드 제공자가 지원하는 경우 사용자 지정 IP를 사용하는 `LoadBalancer`(을)를 생성할 수 있습니다.

또한 `service.loadBalancerSourceRanges`의 목록을 선택적으로 지정하여 `LoadBalancer`에 액세스할 수 있는 CIDR 범위를 제한할 수 있습니다(클라우드 제공자가 지원하는 경우).

`LoadBalancer` 서비스 유형에 대한 추가 정보는 [Kubernetes 설명서](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)에서 찾을 수 있습니다

```yaml
service:
  type: LoadBalancer
  loadBalancerIP: 1.2.3.4
  loadBalancerSourceRanges:
  - 5.6.7.8/32
  - 10.0.0.0/8
```

### OpenSSH 추가 구성 {#openssh-supplemental-configuration}

OpenSSH의 `sshd`을 사용하는 경우(`.sshDaemon: openssh` 경유) 추가 구성을 두 가지 방법으로 제공할 수 있습니다: `.opensshd.supplemental_config` 및 `/etc/ssh/sshd_config.d/*.conf`에 구성 스니펫을 마운트하는 방법입니다.

제공된 모든 구성은 _반드시_ `sshd_config`의 기능 요구 사항을 충족해야 합니다. [설명서](https://man.openbsd.org/sshd_config)를 읽어보세요.

#### opensshd.supplemental_config {#opensshdsupplemental_config}

`.opensshd.supplemental_config`의 콘텐츠는 컨테이너 내의 `sshd_config` 파일 끝에 직접 배치됩니다. 이 값은 다중 행 문자열이어야 합니다.

`ssh-rsa` 키 교환 알고리즘을 사용하여 이전 클라이언트를 활성화하는 예입니다. `ssh-rsa`와 같은 사용되지 않은 알고리즘을 활성화하면 [중요한 보안 취약점](https://www.openssh.com/txt/release-8.8)이 생성됩니다. 이러한 변경을 통해 공개적으로 노출된 GitLab 인스턴스에서 악용 가능성이 **significantly amplified**됩니다.

```yaml
opensshd:
    supplemental_config: |-
      HostKeyAlgorithms +ssh-rsa,ssh-rsa-cert-v01@openssh.com
      PubkeyAcceptedAlgorithms +ssh-rsa,ssh-rsa-cert-v01@openssh.com
      CASignatureAlgorithms +ssh-rsa
```

#### sshd_config.d {#sshd_configd}

`sshd`에 전체 구성 스니펫을 제공할 수 있습니다. `/etc/ssh/sshd_config.d`에 콘텐츠를 마운트하고 파일이 `*.conf`과 일치합니다. 이러한 값은 _이후_에 포함되며, 이는 애플리케이션이 컨테이너 및 차트 내에서 기능하기 위해 필요한 기본 구성입니다. 이러한 값은 `sshd_config`의 내용을 재정의하지 _않으며_, 확장합니다.

`extraVolumes` 및 `extraVolumeMounts`를 통해 ConfigMap의 단일 항목을 컨테이너에 마운트하는 예입니다:

```yaml
extraVolumes: |
  - name: gitlab-sshdconfig-extra
    configMap:
      name: gitlab-sshdconfig-extra

extraVolumeMounts: |
  - name: gitlab-sshdconfig-extra
    mountPath: /etc/ssh/sshd_config.d/extra.conf
    subPath: extra.conf
```

### 인스턴스 수준 SSH 인증서(`gitlab-sshd`) {#instance-level-ssh-certificates-gitlab-sshd}

`gitlab-sshd`를 사용하는 경우(`sshDaemon: gitlab-sshd` 경유) 신뢰할 수 있는 CA 키를 사용하여 인스턴스 수준 SSH 인증서 인증을 구성할 수 있습니다. CA 키 생성, 인증서 발급, 보안 고려 사항 및 문제 해결을 포함한 전체 개요는 [`gitlab-sshd`를 사용한 인스턴스 수준 SSH 인증서](https://docs.gitlab.com/administration/operations/gitlab_sshd_ssh_certificates/)를 참조하세요.

차트를 구성하려면:

1. 하나 이상의 CA 공개 키를 포함하는 Kubernetes 비밀을 생성합니다:

   ```shell
   kubectl create secret generic my-ssh-ca-keys --from-file=ca.pub=ssh_user_ca.pub
   ```

1. Helm 값을 설정하여 비밀을 참조합니다:

   ```yaml
   gitlab:
     gitlab-shell:
       sshDaemon: gitlab-sshd
        config:
          trustedUserCAKeys:
            secret: my-ssh-ca-keys
            keys:
              - ca.pub
   ```

   `secret` 필드는 Kubernetes 비밀의 이름입니다. `keys` 필드는 CA 공개 키 데이터를 포함하는 그 비밀 내의 키 이름을 나열합니다. 각 키는 `gitlab-sshd`에 마운트되고 `trusted_user_ca_keys` 파일 경로로 전달됩니다.

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

`gitlab-shell` 서비스는 포트 22의 Ingress 연결과 기본 Workhorse 포트 8181로의 다양한 송신 연결을 필요로 합니다. 이 예제는 다음 네트워크 정책을 추가합니다:

- Ingress 요청 허용:
  - `nginx-ingress` 포드로부터 `2222`포트로
  - `prometheus` 포드로부터 `9122`포트로

    `prometheus`에서 포트 `9122`로의 액세스는 SSH 데몬이 `gitlab-sshd`로 설정된 경우에만 필요합니다.

- Egress 요청 허용:
  - `webservice` 포드에서 `8181`포트로
  - `gitaly` 포드에서 `8075`포트로

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
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 2222
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
          - port: 9122
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
                app: webservice
        ports:
          - port: 8181
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

[`examples/keda/gitlab-shell.yml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/keda/gitlab-shell.yml)을 참조하여 `keda`의 사용 예를 확인하세요.
