---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Praefect 차트 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리
- 상태:  실험

{{< /details >}}

> [!warning]
> Praefect 차트는 아직 개발 중입니다. 이 실험 버전은 아직 프로덕션 사용에 적합하지 않습니다. 업그레이드에는 상당한 수동 개입이 필요할 수 있습니다. 자세한 정보는 [Praefect GA 릴리스 Epic](https://gitlab.com/groups/gitlab-org/charts/-/epics/33)을 참조하세요.

Praefect 차트는 [Gitaly Cluster (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/)를 관리하는 데 사용되며, Helm 차트로 배포된 GitLab 설치 내에서 사용됩니다.

## 알려진 문제 {#known-issues}

1. 데이터베이스는 [수동으로 생성](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2310)해야 합니다.
1. 클러스터 크기가 고정되어 있습니다:  [Gitaly Cluster (Praefect)는 자동 확장을 지원하지 않습니다](https://gitlab.com/gitlab-org/gitaly/-/issues/2997).
1. 클러스터 내 Praefect 인스턴스를 사용하여 클러스터 외부의 Gitaly 인스턴스를 관리하는 것은 [지원되지 않습니다](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2662).

## 요구 사항 {#requirements}

이 차트는 Gitaly 차트를 사용합니다. `global.gitaly`의 설정은 이 차트에서 생성한 인스턴스를 구성하는 데 사용됩니다. 이러한 설정에 대한 설명서는 [Gitaly 차트 설명서](../gitaly/_index.md)에서 찾을 수 있습니다.

_중요_: `global.gitaly.tls`는 `global.praefect.tls`와 무관합니다. 이들은 별도로 구성됩니다.

기본적으로 이 차트는 3개의 Gitaly 복제본을 생성합니다.

## 구성 {#configuration}

차트는 기본적으로 비활성화되어 있습니다. 차트 배포의 일부로 활성화하려면 `global.praefect.enabled=true`을 설정하세요.

### 복제본 {#replicas}

배포할 복제본의 기본 수는 3입니다. 원하는 복제본 수로 `global.praefect.virtualStorages[].gitalyReplicas`을 설정하여 변경할 수 있습니다. 예를 들어:

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
```

### 여러 가상 스토리지 {#multiple-virtual-storages}

여러 가상 스토리지를 구성할 수 있습니다 ([Gitaly Cluster (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/) 설명서 참조). 예를 들어:

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
```

이렇게 하면 Gitaly용 두 가지 리소스 세트가 생성됩니다. 이는 두 개의 Gitaly StatefulSet(가상 스토리지당 하나씩)을 포함합니다.

관리자는 [새 저장소가 저장될 위치를 구성](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored)할 수 있습니다.

### 지속성 {#persistence}

가상 스토리지별로 지속성 구성을 제공할 수 있습니다.

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
      persistence:
        enabled: true
        size: 50Gi
        accessMode: ReadWriteOnce
        storageClass: storageclass1
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
      persistence:
        enabled: true
        size: 100Gi
        accessMode: ReadWriteOnce
        storageClass: storageclass2
```

## defaultReplicationFactor {#defaultreplicationfactor}

`defaultReplicationFactor`은 각 가상 스토리지에서 구성할 수 있습니다. ([복제 인수 구성](https://docs.gitlab.com/administration/gitaly/praefect/#configure-replication-factor) 설명서 참조).

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 5
      maxUnavailable: 2
      defaultReplicationFactor: 3
    - name: secondary
      gitalyReplicas: 4
      maxUnavailable: 1
      defaultReplicationFactor: 2
```

### Praefect로 마이그레이션 {#migrating-to-praefect}

> [!note]
> 그룹 Wiki는 [API를 사용하여 이동할 수 없습니다](https://docs.gitlab.com/api/project_repository_storage_moves/).

독립형 Gitaly 인스턴스에서 Praefect 설정으로 마이그레이션할 때 `global.praefect.replaceInternalGitaly`을 `false`로 설정할 수 있습니다. 이렇게 하면 기존 Gitaly 인스턴스가 보존되고 새로운 Praefect 관리 Gitaly 인스턴스가 생성됩니다.

```yaml
global:
  praefect:
    enabled: true
    replaceInternalGitaly: false
    virtualStorages:
    - name: virtualStorage2
      gitalyReplicas: 5
      maxUnavailable: 2
```

> [!note]
> Praefect로 마이그레이션할 때 Praefect의 가상 스토리지 중 어느 것도 `default`라고 명명할 수 없습니다. 항상 `default`라는 이름의 스토리지가 최소 하나는 있어야 하므로 이 이름은 이미 비-Praefect 구성에서 사용 중입니다.

[Gitaly Cluster (Praefect)로 마이그레이션](https://docs.gitlab.com/administration/gitaly/praefect/#migrate-to-gitaly-cluster-praefect)하기 위한 지침을 따라 `default` 스토리지에서 `virtualStorage2`로 데이터를 이동할 수 있습니다. `global.gitaly.internal.names` 아래에 정의된 추가 스토리지가 있으면 해당 스토리지에서도 저장소를 마이그레이션해야 합니다.

저장소가 `virtualStorage2`로 마이그레이션된 후, `default`라는 스토리지가 Praefect 구성에 추가되면 `replaceInternalGitaly`을 `true`로 다시 설정할 수 있습니다.

```yaml
global:
  praefect:
    enabled: true
    replaceInternalGitaly: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
    - name: virtualStorage2
      gitalyReplicas: 5
      maxUnavailable: 2
```

`virtualStorage2`에서 새로 추가된 `default` 스토리지로 데이터를 이동하기 위해 [Gitaly Cluster (Praefect)로 마이그레이션](https://docs.gitlab.com/administration/gitaly/praefect/#migrate-to-gitaly-cluster-praefect)하기 위한 지침을 다시 따를 수 있습니다(필요한 경우).

마지막으로 [저장소 스토리지 경로 설명서](https://docs.gitlab.com/administration/repository_storage_paths/#choose-where-new-repositories-are-stored)를 참조하여 새 저장소가 저장될 위치를 구성하세요.

### 데이터베이스 생성 {#creating-the-database}

Praefect는 자체 데이터베이스를 사용하여 상태를 추적합니다. Praefect가 기능하려면 이를 수동으로 생성해야 합니다.

1. 데이터베이스 인스턴스에 로그인합니다. 정확한 연결 명령은 설정에 따라 다를 수 있습니다.

   ```shell
   psql -U postgres -d template1
   ```

1. 데이터베이스 사용자를 생성합니다:

   ```sql
   CREATE ROLE praefect WITH LOGIN;
   ```

1. 데이터베이스 사용자 암호를 설정합니다.

   기본적으로 `shared-secrets` Job은 사용자를 위한 암호를 생성합니다.

   1. 암호를 가져옵니다:

      ```shell
      kubectl get secret RELEASE_NAME-praefect-dbsecret -o jsonpath="{.data.secret}" | base64 --decode
      ```

   1. `psql` 프롬프트에서 암호를 설정합니다:

      ```sql
      \password praefect
      ```

1. 데이터베이스를 생성합니다:

   ```sql
   CREATE DATABASE praefect WITH OWNER praefect;
   ```

### TLS를 통한 Praefect 실행 {#running-praefect-over-tls}

Praefect는 TLS를 통해 클라이언트 및 Gitaly 노드와 통신을 지원합니다. 이는 설정 `global.praefect.tls.enabled` 및 `global.praefect.tls.secretName`에 의해 제어됩니다. TLS를 통해 Praefect를 실행하려면 다음 단계를 따르세요:

1. Helm 차트는 Praefect와의 TLS 통신을 위한 인증서가 제공되어야 합니다. 이 인증서는 존재하는 모든 Praefect 노드에 적용되어야 합니다. 따라서 이러한 각 노드의 모든 호스트명은 주체 대체 이름(SAN)으로 인증서에 추가되거나, 와일드카드를 사용할 수 있습니다.

   사용할 호스트명을 알기 위해 Toolbox Pod의 `/srv/gitlab/config/gitlab.yml` 파일을 확인하고 `repositories.storages` 키 아래에 지정된 다양한 `gitaly_address` 필드를 확인하세요.

   ```shell
   kubectl exec -it <Toolbox Pod> -- grep gitaly_address /srv/gitlab/config/gitlab.yml
   ```

내부 Praefect Pod의 사용자 지정 서명 인증서를 생성하는 기본 스크립트는 [이 저장소에서 찾을 수 있습니다](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/generate_certificates.sh). 적절한 SAN 속성을 사용하여 인증서를 생성하기 위해 해당 스크립트를 사용하거나 참조할 수 있습니다.

1. 생성된 인증서를 사용하여 TLS 암호를 생성합니다.

   ```shell
   kubectl create secret tls <secret name> --cert=praefect.crt --key=praefect.key
   ```

1. `--set global.praefect.tls.enabled=true`을(를) 전달하여 Helm 차트를 다시 배포합니다.

Gitaly를 TLS를 통해 실행할 때 각 가상 스토리지에 대해 암호 이름을 제공해야 합니다.

```yaml
global:
  gitaly:
    tls:
      enabled: true
  praefect:
    enabled: true
    tls:
      enabled: true
      secretName: praefect-tls
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
      tlsSecretName: default-tls
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
      tlsSecretName: vs2-tls
```

### 설치 명령줄 옵션 {#installation-command-line-options}

아래 표에는 `helm install` 명령에 `--set` 플래그를 사용하여 제공할 수 있는 모든 가능한 차트 구성이 포함되어 있습니다.

| 매개변수                                                | 기본값                                           | 설명 |
|----------------------------------------------------------|---------------------------------------------------|-------------|
| common.labels                                            | `{}`                                              | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| failover.enabled                                         | true                                              | Praefect가 노드 실패 시 장애 조치를 수행해야 하는지 여부 |
| failover.readonlyAfter                                   | false                                             | 장애 조치 후 노드가 읽기 전용 모드에 있어야 하는지 여부 |
| autoMigrate                                              | true                                              | 시작 시 자동으로 마이그레이션 실행 |
| image.repository                                         | `registry.gitlab.com/gitlab-org/build/cng/gitaly` | 사용할 기본 이미지 저장소. Praefect는 Gitaly 이미지의 일부로 번들됩니다 |
| podLabels                                                | `{}`                                              | 보충 포드 레이블입니다. 선택기에 사용되지 않습니다. |
| ntpHost                                                  | `pool.ntp.org`                                    | Praefect가 현재 시간을 요청해야 하는 NTP 서버를 구성합니다. |
| service.name                                             | `praefect`                                        | 생성할 서비스의 이름 |
| service.type                                             | ClusterIP                                         | 생성할 서비스의 유형 |
| service.internalPort                                     | 8075                                              | Praefect Pod이 수신할 내부 포트 번호 |
| service.externalPort                                     | 8075                                              | Praefect 서비스가 클러스터에서 노출할 포트 번호 |
| init.resources                                           |                                                   |             |
| init.image                                               |                                                   |             |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                           | initContainer 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                            | initContainer 특정:  컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                       | initContainer 특정:  컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| extraEnvFrom                                             |                                                   | 다른 데이터 소스에서 노출할 추가 환경 변수 목록 |
| logging.level                                            |                                                   | 로그 수준   |
| logging.format                                           | `json`                                            | 로그 형식  |
| logging.sentryDsn                                        |                                                   | Sentry DSN URL - Go 서버의 예외 |
| logging.sentryEnvironment                                |                                                   | 로깅에 사용할 Sentry 환경 |
| `metrics.enabled`                                        | `true`                                            | 메트릭 엔드포인트를 스크래핑할 수 있도록 해야 하는지 여부 |
| `metrics.port`                                           | `9236`                                            | 메트릭 엔드포인트 포트 |
| `metrics.separate_database_metrics`                      | `true`                                            | 참이면 메트릭 스크래핑은 데이터베이스 쿼리를 수행하지 않으며, 거짓으로 설정하면 [성능 문제가 발생할 수 있습니다](https://gitlab.com/gitlab-org/gitaly/-/issues/3796) |
| `metrics.path`                                           | `/metrics`                                        | 메트릭 엔드포인트 경로 |
| `metrics.serviceMonitor.enabled`                         | `false`                                           | Prometheus Operator가 메트릭 스크래핑을 관리하도록 ServiceMonitor를 생성해야 하는지 여부. 이를 활성화하면 `prometheus.io` 스크래핑 주석이 제거됩니다 |
| `affinity`                                               | `{}`                                              | 포드 할당을 위한 [선호도 규칙](../_index.md#affinity) |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                              | ServiceMonitor에 추가할 추가 레이블 |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                              | ServiceMonitor의 추가 엔드포인트 구성 |
| securityContext.runAsUser                                | 1000                                              |             |
| securityContext.fsGroup                                  | 1000                                              |             |
| securityContext.fsGroupChangePolicy                      |                                                   | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                  | 사용할 Seccomp 프로필 |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                           | 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                            | 컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                       | Gitaly 컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `serviceAccount.annotations`                             | `{}`                                              | ServiceAccount 주석 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                           | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다 |
| `serviceAccount.create`                                  | `false`                                           | ServiceAccount를 생성해야 하는지 여부를 나타냅니다 |
| `serviceAccount.enabled`                                 | `false`                                           | ServiceAccount를 사용해야 하는지 여부를 나타냅니다 |
| `serviceAccount.name`                                    |                                                   | ServiceAccount의 이름입니다. 설정하지 않으면 전체 차트 이름이 사용됩니다 |
| serviceLabels                                            | `{}`                                              | 보충 서비스 레이블 |
| statefulset.strategy                                     | `{}`                                              | statefulset에서 사용되는 업데이트 전략을 구성할 수 있습니다 |

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
