---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 객체 스토리지용 MinIO 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

> [!note] 번들 MinIO 차트는 프로덕션 준비가 되어 있지 않습니다. 프로덕션 준비가 된 GitLab 차트 배포의 경우 외부 객체 스토리지 솔루션을 사용하세요.
>
> 번들 MinIO 차트에서 마이그레이션하는 방법은 [번들 Redis, PostgreSQL 및 MinIO에서 마이그레이션](../../installation/migration/bundled_chart_migration.md)을 참조하세요.

이 차트는 [`stable/minio`](https://github.com/helm/charts/tree/master/stable/minio) 버전 [`0.4.3`](https://github.com/helm/charts/tree/aaaf98b5d25c26cc2d483925f7256f2ce06be080/stable/minio)을 기반으로 하며 그곳에서 대부분의 설정을 상속합니다.

## 설계 선택 사항 {#design-choices}

[업스트림 차트](https://github.com/helm/charts/tree/master/stable/minio)와 관련된 설계 선택 사항을 프로젝트의 README에서 찾을 수 있습니다.

GitLab은 시크릿 구성을 단순화하고 환경 변수에서 시크릿의 모든 사용을 제거하기 위해 해당 차트를 변경하도록 선택했습니다. GitLab은 시크릿을 `config.json`에 입력하도록 제어하기 위해 `initContainer`를 추가했으며, 차트 전체 `enabled` 플래그도 추가했습니다.

이 차트는 하나의 시크릿만 사용합니다:

- `global.minio.credentials.secret`: 버킷에 대한 인증에 사용할 `accesskey` 및 `secretkey` 값을 포함하는 전역 시크릿입니다.

## 구성 {#configuration}

아래에서 구성의 모든 주요 섹션을 설명합니다. 부모 차트에서 구성할 때 이러한 값은 다음과 같이 됩니다:

```yaml
minio:
  init:
  ingress:
    enabled:
    apiVersion:
    tls:
      enabled:
      secretName:
    annotations:
    configureCertmanager:
    proxyReadTimeout:
    proxyBodySize:
    proxyBuffering:
  tolerations:
  persistence:  # Upstream
    volumeName:
    matchLabels:
    matchExpressions:
    annotations:
  serviceType:  # Upstream
  servicePort:  # Upstream
  defaultBuckets:
  minioConfig:  # Upstream
```

### 설치 명령줄 옵션 {#installation-command-line-options}

아래 표에는 `helm install` 명령에 `--set` 플래그를 사용하여 제공할 수 있는 모든 가능한 차트 구성이 포함되어 있습니다:

| 매개변수                                                | 기본값                        | 설명 |
|----------------------------------------------------------|--------------------------------|-------------|
| `common.labels`                                          | `{}`                           | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                        | initContainer 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                         | initContainer 특정:  컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                    | initContainer 특정:  컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `defaultBuckets`                                         | `[{"name": "registry"}]`       | MinIO 기본 버킷 |
| `deployment.strategy`                                    | `{ type: 'Recreate' }`         | 배포에서 사용할 업데이트 전략을 구성할 수 있습니다 |
| `image`                                                  | `minio/minio`                  | MinIO 이미지 |
| `imagePullPolicy`                                        | `Always`                       | MinIO 이미지 풀 정책 |
| `imageTag`                                               | `RELEASE.2017-12-28T01-21-00Z` | MinIO 이미지 태그 |
| `minioConfig.browser`                                    | `on`                           | MinIO 브라우저 플래그 |
| `minioConfig.domain`                                     |                                | MinIO 도메인 |
| `minioConfig.region`                                     | `us-east-1`                    | MinIO 영역 |
| `minioMc.image`                                          | `minio/mc`                     | MinIO mc 이미지 |
| `minioMc.tag`                                            | `latest`                       | MinIO mc 이미지 태그 |
| `mountPath`                                              | `/export`                      | MinIO 구성 파일 마운트 경로 |
| `persistence.accessMode`                                 | `ReadWriteOnce`                | MinIO 지속성 액세스 모드 |
| `persistence.annotations`                                |                                | MinIO PersistentVolumeClaim 주석 |
| `persistence.enabled`                                    | `true`                         | MinIO 지속성 활성화 플래그 |
| `persistence.matchExpressions`                           |                                | 바인드할 MinIO 레이블-표현식 일치 |
| `persistence.matchLabels`                                |                                | 바인드할 MinIO 레이블-값 일치 |
| `persistence.size`                                       | `10Gi`                         | MinIO 지속성 볼륨 크기 |
| `persistence.storageClass`                               |                                | 프로비저닝을 위한 MinIO storageClassName |
| `persistence.subPath`                                    |                                | MinIO 지속성 볼륨 마운트 경로 |
| `persistence.volumeName`                                 |                                | MinIO 기존 지속형 볼륨 이름 |
| `priorityClassName`                                      |                                | 포드에 할당된 [우선순위 클래스](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/). |
| `pullSecrets`                                            |                                | 이미지 저장소의 비밀 |
| `resources.requests.cpu`                                 | `250m`                         | MinIO 최소 CPU 요청 |
| `resources.requests.memory`                              | `256Mi`                        | MinIO 최소 메모리 요청 |
| `securityContext.fsGroup`                                | `1000`                         | Pod를 시작할 그룹 ID |
| `securityContext.runAsUser`                              | `1000`                         | Pod를 시작할 사용자 ID |
| `securityContext.fsGroupChangePolicy`                    |                                | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`               | 사용할 Seccomp 프로필 |
| `containerSecurityContext.runAsUser`                     | `1000`                         | 컨테이너가 시작되는 특정 보안 컨텍스트를 덮어쓸 수 있습니다 |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                        | Gitaly 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `containerSecurityContext.runAsNonRoot`                  | `true`                         | 컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                    | Gitaly 컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `serviceAccount.automountServiceAccountToken`            | `false`                        | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다 |
| `servicePort`                                            | `9000`                         | MinIO 서비스 포트 |
| `serviceType`                                            | `ClusterIP`                    | MinIO 서비스 유형 |
| `tolerations`                                            | `[]`                           | 포드 할당을 위한 용인 레이블 |
| `jobAnnotations`                                         | `{}`                           | 작업 사양에 대한 주석 |

## 차트 구성 예시 {#chart-configuration-examples}

### `pullSecrets` {#pullsecrets}

`pullSecrets`을(를) 사용하면 개인 레지스트리에 인증하여 포드의 이미지를 가져올 수 있습니다.

개인 레지스트리 및 해당 인증 방법에 대한 추가 세부사항은 [Kubernetes 설명서](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)에서 찾을 수 있습니다.

다음은 `pullSecrets`의 예시 사용입니다:

```yaml
image: my.minio.repository
imageTag: latest
imagePullPolicy: Always
pullSecrets:
- name: my-secret-name
- name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

이 섹션은 기본 ServiceAccount 액세스 토큰이 Pod에 마운트되어야 하는지 여부를 제어합니다.

| 이름                           |  유형   | 기본값 | 설명 |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | 부울 | `false` | 기본 ServiceAccount 액세스 토큰이 Pod에 마운트되어야 하는지 여부를 제어합니다. 특정 사이드카가 제대로 작동하도록 필요한 경우가 아니면(예: Istio) 이를 활성화하지 않아야 합니다. |

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

## 하위 차트 활성화 {#enable-the-sub-chart}

선택한 구획화된 하위 차트를 구현하는 방식에는 지정된 배포에서 원하지 않는 구성 요소를 비활성화할 수 있는 기능이 포함되어 있습니다. 이러한 이유로 가장 먼저 결정해야 할 설정은 `enabled:`입니다.

기본적으로 MinIO는 기본적으로 활성화되어 있지만 프로덕션 사용은 권장되지 않습니다. 이를 비활성화할 준비가 되면 `--set global.minio.enabled: false`을 실행하세요.

## `initContainer` 구성 {#configure-the-initcontainer}

거의 변경되지 않지만 `initContainer` 동작은 다음 항목을 통해 변경할 수 있습니다:

```yaml
init:
  image:
    repository:
    tag:
    pullPolicy: IfNotPresent
  script:
```

### initContainer 이미지 {#initcontainer-image}

initContainer 이미지 설정은 일반 이미지 구성과 동일합니다. 기본적으로 차트-로컬 값은 비워 두고 전역 설정 `global.gitlabBase.image.repository`와 현재 `global.gitlabVersion`와 관련된 이미지 태그가 initContainer 이미지를 채우는 데 사용됩니다. 전역 구성은 차트-로컬 값(예: `minio.init.image.tag`)으로 재정의할 수 있습니다.

### initContainer 스크립트 {#initcontainer-script}

initContainer에는 다음 항목이 전달됩니다:

- `/config`에 마운트된 인증 항목을 포함하는 시크릿(보통 `accesskey`및 `secretkey`) 입니다.
- `config.json` 템플릿을 포함하는 ConfigMap이고 `configure`는 `sh`로 실행할 스크립트를 포함하며 `/config`에 마운트됩니다.
- `/minio`에 마운트된 `emptyDir`은 데몬의 컨테이너에 전달됩니다.

initContainer는 `/config/configure` 스크립트를 사용하여 `/minio/config.json`을 완료된 구성으로 채울 것으로 예상됩니다. `minio-config` 컨테이너가 해당 작업을 완료하면 `/minio` 디렉토리가 `minio` 컨테이너에 전달되고 `config.json`을 [MinIO](https://min.io) 서버에 제공하는 데 사용됩니다.

## Ingress 구성 {#configuring-the-ingress}

이러한 설정은 MinIO Ingress를 제어합니다.

| 이름                   |  유형   | 기본값 | 설명 |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | 문자열  |         | `apiVersion` 필드에서 사용할 값입니다. |
| `annotations`          | 문자열  |         | 이 필드는 [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)에 대한 표준 `annotations`과 정확히 일치합니다. |
| `enabled`              | 부울 | `false` | Ingress 객체를 생성할 서비스를 지원하는지 여부를 제어하는 설정입니다. `false`일 때 `global.ingress.enabled` 설정이 사용됩니다. |
| `configureCertmanager` | 부울 |         | Ingress 주석 `cert-manager.io/issuer` 및 `acme.cert-manager.io/http01-edit-in-place`를 토글합니다. 자세한 내용은 [GitLab Pages에 대한 TLS 요구 사항](../../installation/tls.md)을 참조하세요. |
| `tls.enabled`          | 부울 | `true`  | `false`로 설정하면 MinIO에 대한 TLS가 비활성화됩니다. 이는 주로 Ingress 컨트롤러 앞에 TLS 종료 프록시가 있는 경우처럼 Ingress 수준에서 TLS 종료를 사용할 수 없을 때 유용합니다. |
| `tls.secretName`       | 문자열  |         | MinIO URL에 대한 유효한 인증서 및 키를 포함하는 Kubernetes TLS Secret의 이름입니다. 설정하지 않으면 `global.ingress.tls.secretName`이 대신 사용됩니다. |

## 이미지 구성 {#configuring-the-image}

`image`, `imageTag` 및 `imagePullPolicy` 기본값은 [업스트림에 문서화](https://github.com/helm/charts/tree/master/stable/minio#configuration)되어 있습니다.

## 지속성 {#persistence}

이 차트는 `PersistentVolumeClaim`를 프로비저닝하고 기본 위치 `/export`에 해당 지속형 볼륨을 마운트합니다. 이것이 작동하려면 Kubernetes 클러스터에서 물리적 스토리지를 사용할 수 있어야 합니다. `emptyDir`를 사용하려면 `PersistentVolumeClaim`을 비활성화하세요: `persistence.enabled: false`.

[`persistence`](https://github.com/helm/charts/tree/master/stable/minio#persistence) 에 대한 동작은 [업스트림에 문서화](https://github.com/helm/charts/tree/master/stable/minio#configuration)되어 있습니다.

GitLab은 몇 가지 항목을 추가했습니다:

```yaml
persistence:
  volumeName:
  matchLabels:
  matchExpressions:
```

| 이름               |  유형  | 기본값 | 설명 |
|:-------------------|:------:|:--------|:------------|
| `volumeName`       | 문자열 | `false` | `volumeName`를 제공하면 `PersistentVolumeClaim`는 `PersistentVolume`을 이름으로 사용하여 `PersistentVolume`를 동적으로 생성하는 대신 사용합니다. 이는 업스트림 동작을 재정의합니다. |
| `matchLabels`      |  맵   | `true`  | 바인드할 볼륨을 선택할 때 일치시킬 레이블 이름과 레이블 값의 맵을 허용합니다. 이는 `PersistentVolumeClaim` `selector` 섹션에서 사용됩니다. [볼륨 설명서](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)를 참조하세요. |
| `matchExpressions` | 배열  |         | 바인드할 볼륨을 선택할 때 일치시킬 레이블 조건 객체의 배열을 허용합니다. 이는 `PersistentVolumeClaim` `selector` 섹션에서 사용됩니다. [볼륨 설명서](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)를 참조하세요. |

## `defaultBuckets` {#defaultbuckets}

`defaultBuckets`는 MinIO Pod에서 *설치* 시 버킷을 자동으로 생성하는 메커니즘을 제공합니다. 이 속성에는 최대 3개의 속성 `name`, `policy` 및 `purge`가 있는 항목의 배열이 포함됩니다.

```yaml
defaultBuckets:
  - name: public
    policy: public
    purge: true
  - name: private
  - name: public-read
    policy: download
```

| 이름     |  유형   | 기본값 | 설명 |
|:---------|:-------:|:--------|:------------|
| `name`   | 문자열  |         | 생성된 버킷의 이름입니다. 제공된 값은 [AWS 버킷 명명 규칙](https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html)을 준수해야 하며, DNS와 호환되고 길이 3~63자 문자열에서 a-z, 0-9 및 -(하이픈)의 문자만 포함해야 합니다. `name` 속성은 모든 항목에 필요합니다. |
| `policy` |         | `none`  | `policy`의 값은 MinIO의 버킷의 액세스 정책을 제어합니다. `policy` 속성은 필요하지 않으며 기본값은 `none`입니다. **anonymous** 액세스와 관련하여 가능한 값은 `none`(익명 액세스 없음), `download`(익명 읽기 전용 액세스), `upload`(익명 쓰기 전용 액세스) 또는 `public`(익명 읽기/쓰기 액세스)입니다. |
| `purge`  | 부울 |         | `purge` 속성은 기존 버킷을 강제로 제거하기 위한 수단으로 설치 시간에 제공됩니다. 이는 [지속성](#persistence)의 volumeName 속성에 대해 기존 `PersistentVolume`를 사용할 때만 적용됩니다. 동적으로 생성된 `PersistentVolume`를 사용하면 차트 설치 시에만 발생하고 방금 생성된 `PersistentVolume`에 데이터가 없으므로 이는 가치 있는 효과가 없습니다. 이 속성은 필수가 아니지만 버킷을 강제로 제거하도록 하려면 `true` 값으로 이 속성을 지정할 수 있으며 `mc rm -r --force`를 사용합니다. |

## 보안 컨텍스트 {#security-context}

이러한 옵션은 Pod를 시작하는 데 사용할 `user` 및/또는 `group`을 제어할 수 있습니다.

보안 컨텍스트에 대한 심층적 정보는 공식 [Kubernetes 설명서](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)를 참조하세요.

## 서비스 유형 및 포트 {#service-type-and-port}

이는 [업스트림에 문서화](https://github.com/helm/charts/tree/master/stable/minio#configuration)되어 있으며 주요 요약은 다음과 같습니다:

```yaml
## Expose the MinIO service to be accessed from outside the cluster (LoadBalancer service).
## or access it from within the cluster (ClusterIP service). Set the service type and the port to serve it.
## ref: http://kubernetes.io/docs/user-guide/services/
##
serviceType: LoadBalancer
servicePort: 9000
```

차트는 `type: NodePort`이어야 하지 않으므로 **do not**.

## 업스트림 항목 {#upstream-items}

다음에 대한 [업스트림 설명서](https://github.com/helm/charts/tree/master/stable/minio)도 이 차트에 완전히 적용됩니다:

- `resources`
- `nodeSelector`
- `minioConfig`

`minioConfig` 설정에 대한 추가 설명은 [MinIO 알림 설명서](https://min.io/docs/minio/kubernetes/upstream/index.html)에서 찾을 수 있습니다. 여기에는 버킷 객체에 액세스하거나 변경할 때 알림 게시에 대한 세부 정보가 포함됩니다.
