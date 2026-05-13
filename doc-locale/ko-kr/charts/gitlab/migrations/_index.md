---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab-Migrations 차트 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

`migrations` 하위 차트는 GitLab에서 사용하는 데이터베이스를 시드/마이그레이션하는 단일 마이그레이션 [Job](https://kubernetes.io/docs/concepts/workloads/controllers/job/)을 제공합니다. 차트는 GitLab Rails 코드베이스를 사용하여 실행됩니다.

[ClickHouse](../../../development/clickhouse.md) 가 활성화되면 이 하위 차트는 [ClickHouse](../../../development/clickhouse.md)에 대한 마이그레이션도 실행합니다.

마이그레이션 후, 이 Job은 또한 데이터베이스의 애플리케이션 설정을 편집하여 [인증된 키 파일에 대한 쓰기](https://docs.gitlab.com/administration/operations/fast_ssh_key_lookup/#setting-up-fast-lookup-via-gitlab-shell)를 비활성화합니다. 차트에서는 인증된 키 파일에 쓰기 지원 대신 SSH `AuthorizedKeysCommand`와 함께 GitLab Authorized Keys API의 사용만 지원합니다.

## 요구 사항 {#requirements}

이 차트는 Redis와 PostgreSQL에 종속되며, 완전한 GitLab 차트의 일부이거나 이 차트가 배포된 Kubernetes 클러스터에서 도달 가능한 외부 서비스로 제공됩니다.

설치에 ClickHouse가 활성화되어 있으면 이 차트는 ClickHouse에도 종속됩니다.

## 설계 선택 사항 {#design-choices}

`migrations` 차트는 차트가 설치될 때마다 또는 새로운 [차트 버전](https://helm.sh/docs/topics/charts/#charts-and-versioning) , [appVersion](https://helm.sh/docs/topics/charts/#the-appversion-field) 또는 값의 변경으로 차트가 업그레이드될 때마다 새로운 마이그레이션 [Job](https://kubernetes.io/docs/concepts/workloads/controllers/job/)을 생성합니다.

`helm install`과 `helm upgrade`을 사용하여 이 차트를 설치하고 업그레이드할 때, 이 차트에서 생성된 작업은 다음 차트 업그레이드까지 클러스터의 객체로 남아 있습니다. 이는 마이그레이션 로그를 관찰할 수 있도록 하기 위함입니다. 로그 배송의 어떤 형태가 있으면 이러한 객체의 지속성을 다시 검토할 수 있습니다.

`helm template`과 `kubectl apply`으로 생성된 매니페스트를 사용하여 배포가 이루어지면 이전 마이그레이션 작업 객체는 클러스터에서 제거되지 않습니다.

이 차트에서 사용된 컨테이너는 현재 여기서 사용하지 않는 추가 최적화를 가지고 있습니다. 주로, rails 애플리케이션을 부팅할 필요 없이 마이그레이션이 이미 최신인 경우 마이그레이션 실행을 빠르게 건너뛸 수 있는 기능입니다. 이 최적화는 마이그레이션 상태를 유지해야 합니다. 현재 이 차트에서는 이렇게 하지 않습니다. 향후에는 이 차트에 마이그레이션 상태에 대한 스토리지 지원을 도입할 것입니다.

## 구성 {#configuration}

`migrations` 차트는 두 부분으로 구성됩니다: 외부 서비스 및 차트 설정입니다.

## 설치 명령줄 옵션 {#installation-command-line-options}

아래 표에는 `helm install` 명령에 `--set` 플래그를 사용하여 제공할 수 있는 모든 가능한 차트 구성이 포함되어 있습니다.

| 매개변수                                                | 기본값                                                      | 설명 |
|----------------------------------------------------------|--------------------------------------------------------------|-------------|
| `common.labels`                                          | `{}`                                                         | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee` | 마이그레이션 이미지 저장소 |
| `image.tag`                                              |                                                              | 마이그레이션 이미지 태그 |
| `image.pullPolicy`                                       | `Always`                                                     | 마이그레이션 풀 정책 |
| `image.pullSecrets`                                      |                                                              | 이미지 저장소의 비밀 |
| `init.image.repository`                                  | `registry.gitlab.com/gitlab-org/build/cng/gitlab-base`       | `initContainer` 이미지 저장소 |
| `init.image.tag`                                         | `master`                                                     | `initContainer` 이미지 태그 |
| `init.image.containerSecurityContext`                    | `{}`                                                         | `initContainer` `securityContext` 재정의 |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | `initContainer` 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                       | `initContainer` 특정:  컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                  | `initContainer` 특정:  컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `enabled`                                                | `true`                                                       | 마이그레이션 활성화 플래그 |
| `tolerations`                                            | `[]`                                                         | 포드 할당을 위한 용인 레이블 |
| `affinity`                                               | `{}`                                                         | 포드 할당을 위한 [선호도 규칙](../_index.md#affinity) |
| `annotations`                                            | `{}`                                                         | 작업 사양에 대한 주석 |
| `podAnnotations`                                         | `{}`                                                         | Pod 사양에 대한 주석 |
| `podLabels`                                              |                                                              | 보충 포드 레이블입니다. 선택기에 사용되지 않습니다. |
| `psql.password.secret`                                   | `gitlab-postgres`                                            | `psql` 비밀 |
| `psql.password.key`                                      | `psql-password`                                              | `psql` 비밀의 `psql` 암호에 대한 키 |
| `psql.port`                                              |                                                              | PostgreSQL 서버 포트를 설정합니다. `global.psql.port`보다 우선합니다. |
| `resources.requests.cpu`                                 | `250m`                                                       | GitLab 마이그레이션 최소 CPU |
| `resources.requests.memory`                              | `200Mi`                                                      | GitLab 마이그레이션 최소 메모리 |
| `securityContext.fsGroup`                                | `1000`                                                       | 포드를 시작해야 하는 그룹 ID |
| `securityContext.runAsUser`                              | `1000`                                                       | 포드를 시작해야 하는 사용자 ID |
| `securityContext.fsGroupChangePolicy`                    |                                                              | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                             | 사용할 Seccomp 프로필 |
| `containerSecurityContext.runAsUser`                     | `1000`                                                       | 컨테이너 [`securityContext`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)를 재정의하여 컨테이너를 시작합니다. |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                      | 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                       | 컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                  | Gitaly 컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `serviceAccount.annotations`                             | `{}`                                                         | ServiceAccount 주석 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                      | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다 |
| `serviceAccount.create`                                  | `false`                                                      | ServiceAccount를 생성해야 하는지 여부를 나타냅니다 |
| `serviceAccount.enabled`                                 | `false`                                                      | ServiceAccount를 사용해야 하는지 여부를 나타냅니다 |
| `serviceAccount.name`                                    |                                                              | ServiceAccount의 이름입니다. 설정하지 않으면 전체 차트 이름이 사용됩니다 |
| `extraInitContainers`                                    |                                                              | 포함할 추가 init 컨테이너 목록 |
| `extraContainers`                                        |                                                              | 포함할 컨테이너 목록을 포함하는 여러 줄 리터럴 스타일 문자열 |
| `extraVolumes`                                           |                                                              | 생성할 추가 볼륨 목록 |
| `extraVolumeMounts`                                      |                                                              | 수행할 추가 볼륨 마운트 목록 |
| `extraEnv`                                               |                                                              | 노출할 추가 환경 변수 목록 |
| `extraEnvFrom`                                           |                                                              | 다른 데이터 소스에서 노출할 추가 환경 변수 목록 |
| `priorityClassName`                                      |                                                              | 포드에 할당된 [우선순위 클래스](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/). |

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

### `image.pullSecrets` {#imagepullsecrets}

`pullSecrets`을(를) 사용하여 프라이빗 레지스트리에 인증하여 Pod의 이미지를 가져올 수 있습니다.

개인 레지스트리 및 해당 인증 방법에 대한 추가 세부사항은 [Kubernetes 설명서](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)에서 찾을 수 있습니다.

다음은 `pullSecrets`의 예시 사용입니다:

```yaml
image:
  repository: my.migrations.repository
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

### `affinity` {#affinity}

자세한 내용은 [`affinity`](../_index.md#affinity)를 참조하세요.

## 이 차트의 Community Edition 사용 {#using-the-community-edition-of-this-chart}

기본적으로 Helm 차트는 GitLab Enterprise Edition을 사용합니다. 원하는 경우 대신 Community Edition을 사용할 수 있습니다. [둘 간의 차이](https://about.gitlab.com/install/ce-or-ee/)에 대해 자세히 알아보세요.

Community Edition을 사용하려면 `image.repository`을(를) `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ce`로 설정하세요.

## 외부 서비스 {#external-services}

### Redis {#redis}

```yaml
redis:
  host: redis.example.com
  port: 6379
  sentinels:
    - host: sentinel1.example.com
      port: 26379
  password:
    secret: gitlab-redis
    key: redis-password
```

#### `host` {#host}

사용할 데이터베이스가 있는 Redis 서버의 호스트 이름입니다. Redis Sentinels를 사용하는 경우 `host` 속성을 `sentinel.conf`에 지정된 클러스터 이름으로 설정해야 합니다.

#### `port` {#port}

Redis 서버에 연결할 포트입니다. `6379`로 기본값이 설정됩니다.

#### `password` {#password}

Redis에 대한 `password` 속성에는 두 개의 하위 키가 있습니다:

- `secret`은(는) 가져올 Kubernetes `Secret`의 이름을 정의합니다.
- `key`은(는) 암호를 포함하는 위의 비밀의 키 이름을 정의합니다.

#### `sentinels` {#sentinels}

`sentinels` 속성은 Redis HA 클러스터에 대한 연결을 허용합니다. 하위 키는 각 Sentinel 연결을 설명합니다.

- `host`은(는) Sentinel 서비스의 호스트 이름을 정의합니다.
- `port`은(는) Sentinel 서비스에 도달하기 위한 포트 번호를 정의하며 `26379`로 기본값입니다.

### PostgreSQL {#postgresql}

```yaml
psql:
  host: psql.example.com
  port: 5432
  database: gitlabhq_production
  username: gitlab
  preparedStatements: false
  password:
    secret: gitlab-postgres
    key: psql-password
```

#### `host` {#host-1}

사용할 데이터베이스가 있는 PostgreSQL 서버의 호스트 이름입니다.

#### `port` {#port-1}

PostgreSQL 서버에 연결할 포트입니다. `5432`로 기본값이 설정됩니다.

#### `database` {#database}

PostgreSQL 서버에서 사용할 데이터베이스의 이름입니다. 기본값은 `gitlabhq_production`입니다.

#### `preparedStatements` {#preparedstatements}

PostgreSQL 서버와의 통신 시 준비된 명령문을 사용할지 여부입니다. `false`로 기본값이 설정됩니다.

#### `username` {#username}

데이터베이스에 인증할 사용자 이름입니다. 기본값은 `gitlab`입니다.

#### `password` {#password-1}

PostgreSQL에 대한 `password` 속성에는 두 개의 하위 키가 있습니다:

- `secret`은(는) 가져올 Kubernetes `Secret`의 이름을 정의합니다.
- `key`은(는) 암호를 포함하는 위의 비밀의 키 이름을 정의합니다.

### ClickHouse (선택 사항) {#clickhouse-optional}

``` yaml
global:
  clickhouse:
    enabled: true
    main:
      url: https://clickhouse.example.com
      database: default
      username: default
      password:
        secret: gitlab-clickhouse-password
        key: main_password
```

설치에 ClickHouse가 활성화되어 있으면 이 차트는 ClickHouse 데이터베이스에 대한 마이그레이션도 실행합니다. ClickHouse의 구성은 `global.clickhouse` 키 아래에 제공되어야 합니다.

#### `main.url` {#mainurl}

ClickHouse 인스턴스의 URL입니다.

#### `main.database` {#maindatabase}

ClickHouse의 데이터베이스 이름입니다.

#### `main.username` {#mainusername}

ClickHouse에서 인증하는 데 사용할 사용자 이름입니다.

#### `main.password` {#mainpassword}

ClickHouse에 대한 `password` 속성에는 두 개의 하위 키가 포함됩니다:

- `secret`은(는) 가져올 Kubernetes 비밀의 이름을 정의합니다.
- `key`은(는) 암호를 포함하는 위의 `secret` 내의 키 이름을 정의합니다.
