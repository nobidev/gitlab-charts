---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Toolbox
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

Toolbox 차트는 GitLab 애플리케이션 내에서 주기적인 하우스키핑 작업을 실행하는 데 사용됩니다. 이러한 작업에는 백업, 데이터베이스 재인덱싱, Sidekiq 유지 보수 및 Rake 작업이 포함됩니다.

## 구성 {#configuration}

다음 구성 설정은 Toolbox 차트에서 제공하는 기본 설정입니다:

```yaml
gitlab:
  ## doc/charts/gitlab/toolbox
  toolbox:
    enabled: true
    replicas: 1
    backups:
      cron:
        enabled: false
        concurrencyPolicy: Replace
        failedJobsHistoryLimit: 1
        schedule: "0 1 * * *"
        successfulJobsHistoryLimit: 3
        suspend: false
        backoffLimit: 6
        safeToEvict: false
        restartPolicy: "OnFailure"
        resources:
          requests:
            cpu: 50m
            memory: 350M
        persistence:
          enabled: false
          accessMode: ReadWriteOnce
          useGenericEphemeralVolume: false
          size: 10Gi
      objectStorage:
        backend: s3
        config: {}
      registry:
        database: {}
    databaseReindex:
      cron:
        enabled: false
        concurrencyPolicy: Replace
        failedJobsHistoryLimit: 1
        schedule: "12 * * * 0,6"
        successfulJobsHistoryLimit: 3
        suspend: false
        backoffLimit: 6
        safeToEvict: false
        restartPolicy: "OnFailure"
        resources:
          requests:
            cpu: 200m
            memory: 400M
    persistence:
      enabled: false
      accessMode: 'ReadWriteOnce'
      size: '10Gi'
    resources:
      requests:
        cpu: '50m'
        memory: '350M'
    securityContext:
      fsGroup: '1000'
      runAsUser: '1000'
      runAsGroup: '1000'
    containerSecurityContext:
      runAsUser: '1000'
    affinity: {}
```

| 매개변수                                                | 기본값                                                      | 설명 |
|----------------------------------------------------------|--------------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                         | 포드 할당을 위한 [선호도 규칙](../_index.md#affinity) |
| `annotations`                                            | `{}`                                                         | Toolbox Pods 및 Jobs에 추가할 Annotations |
| `common.labels`                                          | `{}`                                                         | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `antiAffinityLabels.matchLabels`                         |                                                              | 안티 어피니티 옵션을 설정하기 위한 레이블 |
| `backups.cron.activeDeadlineSeconds`                     | `null`                                                       | Backup CronJob 활성 마감 시간 초(null인 경우 활성 마감이 적용되지 않음) |
| `backups.cron.ttlSecondsAfterFinished`                   | `null`                                                       | Backup CronJob 완료 후 작업 유지 시간(null인 경우 유지 시간이 적용되지 않음) |
| `backups.cron.safeToEvict`                               | `false`                                                      | 자동 확장 안전-제거 annotation |
| `backups.cron.backoffLimit`                              | `6`                                                          | Backup CronJob 백오프 한계 |
| `backups.cron.concurrencyPolicy`                         | `Replace`                                                    | Kubernetes Job 동시성 정책 |
| `backups.cron.enabled`                                   | `false`                                                      | Backup CronJob 활성화 플래그 |
| `backups.cron.extraArgs`                                 |                                                              | 백업 유틸리티에 전달할 인수의 문자열 |
| `backups.cron.failedJobsHistoryLimit`                    | `1`                                                          | 히스토리의 실패한 백업 작업 목록 수 |
| `backups.cron.persistence.accessMode`                    | `ReadWriteOnce`                                              | Backup cron 지속성 접근 모드 |
| `backups.cron.persistence.enabled`                       | `false`                                                      | Backup cron 지속성 활성화 플래그 |
| `backups.cron.persistence.matchExpressions`              |                                                              | 바인딩할 레이블 표현식 일치 |
| `backups.cron.persistence.matchLabels`                   |                                                              | 바인딩할 레이블 값 일치 |
| `backups.cron.persistence.useGenericEphemeralVolume`     | `false`                                                      | [generic ephemeral volume](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/#generic-ephemeral-volumes) 사용 |
| `backups.cron.persistence.size`                          | `10Gi`                                                       | Backup cron 지속성 볼륨 크기 |
| `backups.cron.persistence.storageClass`                  |                                                              | 프로비저닝을 위한 StorageClass 이름 |
| `backups.cron.persistence.subPath`                       |                                                              | Backup cron 지속성 볼륨 마운트 경로 |
| `backups.cron.persistence.volumeName`                    |                                                              | 기존 persistent volume 이름 |
| `backups.cron.resources.requests.cpu`                    | `50m`                                                        | Backup cron 최소 필요 CPU |
| `backups.cron.resources.requests.memory`                 | `350M`                                                       | Backup cron 최소 필요 메모리 |
| `backups.cron.restartPolicy`                             | `OnFailure`                                                  | Backup cron 재시작 정책(`Never` 또는 `OnFailure`) |
| `backups.cron.schedule`                                  | `0 1 * * *`                                                  | Cron 스타일 스케줄 문자열 |
| `backups.cron.startingDeadlineSeconds`                   | `null`                                                       | Backup cron 작업 시작 마감 시간(초)(null인 경우 시작 마감이 적용되지 않음) |
| `backups.cron.successfulJobsHistoryLimit`                | `3`                                                          | 히스토리의 성공한 백업 작업 목록 수 |
| `backups.cron.suspend`                                   | `false`                                                      | Backup cron 작업 일시 중단 됨 |
| `backups.cron.timeZone`                                  | `""`                                                         | 백업 스케줄의 시간대입니다. 자세한 정보는 [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones)을 참조하십시오. 지정하지 않으면 클러스터 시간대를 사용합니다. |
| `backups.cron.tolerations`                               | `""`                                                         | Backup cron 작업에 추가할 Tolerations |
| `backups.cron.nodeSelector`                              | `""`                                                         | Backup cron 작업 노드 선택 |
| `backups.objectStorage.backend`                          | `s3`                                                         | 사용할 객체 저장소 제공자(`s3`, `gcs` 또는 `azure`) |
| `backups.objectStorage.config.gcpProject`                | `""`                                                         | 백엔드가 `gcs`일 때 사용할 GCP 프로젝트 |
| `backups.objectStorage.config.key`                       | `""`                                                         | 비밀에 포함된 자격증명 키 |
| `backups.objectStorage.config.secret`                    | `""`                                                         | 객체 저장소 자격증명 비밀 |
| `backups.registry.database.backupUser`                   |                                                              | 백업 중 레지스트리 메타데이터 데이터베이스 연결의 사용자 이름 |
| `backups.registry.database.restoreUser`                  |                                                              | 복원 중 레지스트리 메타데이터 데이터베이스 연결의 사용자 이름 |
| `backups.registry.database.password.secret`              | `RELEASE-toolbox-registry-database-password`                 | 백업 및 복원을 위한 레지스트리 데이터베이스 암호를 포함하는 Kubernetes 비밀의 이름 |
| `backups.registry.database.password.backupPasswordKey`   | `backupPassword`                                             | 백업 데이터베이스 암호를 포함하는 비밀 내의 키 |
| `backups.registry.database.password.restorePasswordKey`  | `restorePassword`                                            | 복원 데이터베이스 암호를 포함하는 비밀 내의 키 |
| `databaseReindex.cron.enabled`                           | `false`                                                      | 데이터베이스 재인덱싱 CronJob이 활성화되었는지 여부를 나타냅니다. |
| `common.labels`                                          | `{}`                                                         | 이 차트에서 생성한 모든 개체에 적용되는 보충 레이블입니다. |
| `deployment.strategy`                                    | `{ type: 'Recreate' }`                                       | 배포에서 사용할 업데이트 전략을 구성할 수 있습니다 |
| `enabled`                                                | `true`                                                       | Toolbox 활성화 플래그 |
| `extra`                                                  | `{}`                                                         | [extra `gitlab.yml` configuration](https://gitlab.com/gitlab-org/gitlab/-/blob/8d2b59dbf232f17159d63f0359fa4793921896d5/config/gitlab.yml.example#L1193-1199)을 위한 YAML 블록 |
| `image.pullPolicy`                                       | `IfNotPresent`                                               | Toolbox 이미지 풀 정책 |
| `image.pullSecrets`                                      |                                                              | Toolbox 이미지 풀 비밀 |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee` | Toolbox 이미지 저장소 |
| `image.tag`                                              | `master`                                                     | Toolbox 이미지 태그 |
| `init.image.repository`                                  |                                                              | Toolbox init 이미지 저장소 |
| `init.image.tag`                                         |                                                              | Toolbox init 이미지 태그 |
| `init.resources`                                         | `{ requests: { cpu: '50m' }}`                                | Toolbox init 컨테이너 리소스 요구사항 |
| `init.containerSecurityContext`                          |                                                              | initContainer 특정 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | initContainer 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                       | initContainer 특정:  컨테이너를 시작해야 하는 사용자 ID |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | initContainer 특정:  프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                       | initContainer 특정:  컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                  | initContainer 특정:  컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `nodeSelector`                                           |                                                              | Toolbox 및 백업 작업 노드 선택 |
| `persistence.accessMode`                                 | `ReadWriteOnce`                                              | Toolbox 지속성 접근 모드 |
| `persistence.enabled`                                    | `false`                                                      | Toolbox 지속성 활성화 플래그 |
| `persistence.matchExpressions`                           |                                                              | 바인딩할 레이블 표현식 일치 |
| `persistence.matchLabels`                                |                                                              | 바인딩할 레이블 값 일치 |
| `persistence.size`                                       | `10Gi`                                                       | Toolbox 지속성 볼륨 크기 |
| `persistence.storageClass`                               |                                                              | 프로비저닝을 위한 StorageClass 이름 |
| `persistence.subPath`                                    |                                                              | Toolbox 지속성 볼륨 마운트 경로 |
| `persistence.volumeName`                                 |                                                              | 기존 PersistentVolume 이름 |
| `podLabels`                                              | `{}`                                                         | Toolbox Pods 실행을 위한 레이블 |
| `priorityClassName`                                      |                                                              | 포드에 할당된 [우선순위 클래스](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/). |
| `replicas`                                               | `1`                                                          | 실행할 Toolbox Pods의 수 |
| `resources.requests`                                     | `{ cpu: '50m', memory: '350M' }`                             | Toolbox 최소 요청 리소스 |
| `securityContext.fsGroup`                                | `1000`                                                       | pod를 시작해야 하는 파일 시스템 그룹 ID |
| `securityContext.runAsUser`                              | `1000`                                                       | 포드를 시작해야 하는 사용자 ID |
| `securityContext.runAsGroup`                             | `1000`                                                       | 포드를 시작해야 하는 그룹 ID |
| `securityContext.fsGroupChangePolicy`                    |                                                              | 볼륨의 소유권 및 권한을 변경하는 정책(Kubernetes 1.23 필요) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                             | 사용할 Seccomp 프로필 |
| `containerSecurityContext`                               |                                                              | 컨테이너가 시작되는 컨테이너 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)를 재정의합니다 |
| `containerSecurityContext.runAsUser`                     | `1000`                                                       | 컨테이너가 시작되는 특정 보안 컨텍스트를 덮어쓸 수 있습니다 |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                      | 컨테이너의 프로세스가 부모 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                       | 컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                  | Gitaly 컨테이너의 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `serviceAccount.annotations`                             | `{}`                                                         | ServiceAccount의 주석 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                      | 기본 ServiceAccount 액세스 토큰을 포드에 마운트해야 하는지 여부를 나타냅니다 |
| `serviceAccount.enabled`                                 | `false`                                                      | ServiceAccount를 사용해야 하는지 여부를 나타냅니다 |
| `serviceAccount.create`                                  | `false`                                                      | ServiceAccount를 생성해야 하는지 여부를 나타냅니다 |
| `serviceAccount.name`                                    |                                                              | ServiceAccount의 이름입니다. 설정하지 않으면 전체 차트 이름이 사용됩니다 |
| `tolerations`                                            |                                                              | Toolbox에 추가할 Tolerations |
| `extraEnvFrom`                                           |                                                              | 다른 데이터 소스에서 노출할 추가 환경 변수 목록 |

## 백업 구성 {#configuring-backups}

[문서 백업 및 복원](../../../backup-restore/_index.md)에서 백업 구성에 대한 정보입니다. 백업이 수행되는 방식의 기술적 구현에 대한 추가 정보는 [아키텍처 문서 백업 및 복원](../../../architecture/backup-restore.md)에서 찾을 수 있습니다.]

### 레지스트리 메타데이터 데이터베이스 자격 증명 {#registry-metadata-database-credentials}

[컨테이너 레지스트리 메타데이터 데이터베이스](../../registry/metadata_database.md)를 사용하는 경우 백업 및 복원 작업을 위해 레지스트리 데이터베이스 연결 세부 정보를 받도록 Toolbox를 구성할 수 있습니다. 연결 매개 변수(호스트, 포트, 데이터베이스 이름, SSL 설정)는 레지스트리 차트의 `ConfigMap`에서 자동으로 가져옵니다. Toolbox 값에서 데이터베이스 사용자 이름 및 암호 비밀만 제공하면 됩니다:

```yaml
gitlab:
  toolbox:
    backups:
      registry:
        database:
          backupUser: registry_backup
          restoreUser: registry_restore
          password:
            secret: gitlab-toolbox-registry-database-password
            backupPasswordKey: backupPassword
            restorePasswordKey: restorePassword
```

기본 비밀 이름은 `RELEASE-toolbox-registry-database-password`이며, 여기서 `RELEASE`는 Helm 릴리스 이름(일반적으로 `gitlab`)으로 바뀝니다. 배포 전에 Kubernetes 비밀을 생성하십시오:

```shell
kubectl create secret generic <RELEASE>-toolbox-registry-database-password \
  --from-literal=backupPassword=<backup_password> \
  --from-literal=restorePassword=<restore_password>
```

자격증명은 `/etc/gitlab/registry-db/`의 Toolbox pod에 마운트되고 장기 실행 Toolbox 배포 및 백업 CronJob 모두에서 사용 가능합니다.

#### 데이터베이스 권한 필요 {#required-database-permissions}

백업 및 복원 사용자는 레지스트리 메타데이터 데이터베이스에서 다른 권한 수준이 필요합니다. Linux 패키지(Omnibus)와 함께 번들로 제공되는 PostgreSQL을 사용하는 경우 이러한 사용자 및 권한은 자동으로 생성됩니다. 외부 PostgreSQL의 경우 사용자를 수동으로 생성하십시오.

**사용자 백업**은 `pg_dump`에 대한 읽기 전용 액세스가 필요합니다:

```sql
-- Create the backup user
CREATE ROLE registry_backup WITH LOGIN PASSWORD '<backup_password>'
  NOINHERIT NOCREATEDB NOSUPERUSER NOREPLICATION;

-- The partitions schema must exist (created by registry migrations)
-- Grant connect and read-only privileges
GRANT CONNECT ON DATABASE registry TO registry_backup;

GRANT USAGE ON SCHEMA public TO registry_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO registry_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO registry_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE registry IN SCHEMA public
  GRANT SELECT ON TABLES TO registry_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE registry IN SCHEMA public
  GRANT SELECT ON SEQUENCES TO registry_backup;

GRANT USAGE ON SCHEMA partitions TO registry_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA partitions TO registry_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA partitions TO registry_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE registry IN SCHEMA partitions
  GRANT SELECT ON TABLES TO registry_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE registry IN SCHEMA partitions
  GRANT SELECT ON SEQUENCES TO registry_backup;
```

`ALTER DEFAULT PRIVILEGES` 문은 백업 사용자가 레지스트리 소유자(`registry`)가 향후 생성하는 모든 테이블 또는 시퀀스에 대해 `SELECT`을 자동으로 수신하도록 합니다.

**사용자 복원**은 스키마를 다시 만들고, 원래 객체 소유자의 역할을 설정하고, 트리거를 만들기 위해 슈퍼유저 권한이 필요합니다:

```sql
CREATE ROLE registry_restore WITH LOGIN PASSWORD '<restore_password>'
  SUPERUSER;
```

## 주기적인 데이터베이스 재인덱싱 구성 {#configure-periodic-database-reindexing}

{{< details >}}

상태: 실험

{{< /details >}}

[데이터베이스 재인덱싱](https://docs.gitlab.com/omnibus/settings/database/#automatic-database-reindexing)을 주기적으로 실행할 수 있습니다:

- 비동기적으로 인덱스를 만들고 삭제합니다.
- 백그라운드에서 PostgreSQL 제약 조건 검증을 실행합니다.
- PostgreSQL 인덱스를 재인덱싱하여 [index bloat](https://wiki.postgresql.org/wiki/Index_Maintenance#Index_Bloat)을 줄입니다.

재인덱싱은 [`gitlab:db:reindex`](https://gitlab.com/gitlab-org/gitlab/blob/9a05e533daeb1013d4c974dd6b3ba066f68585ba/lib/tasks/gitlab/db.rake#L393-402) Rake 작업에 의해 수행됩니다. Toolbox 차트는 Rake 작업을 주기적으로 실행하기 위한 CronJob을 제공합니다.

값 `databaseReindex.cron.enabled`을 `true`로 설정하여 이 CronJob을 활성화합니다. 작업이 자동으로:

1. 가장 많은 [index bloat](https://wiki.postgresql.org/wiki/Index_Maintenance#Index_Bloat)을 가진 두 개의 인덱스를 선택합니다.
1. 백그라운드에서 해당 인덱스를 재인덱싱합니다.

`databaseReindex.cron.schedule` 값을 사용하여 CronJob의 스케줄을 설정합니다. 트래픽이 적은 기간 동안 재인덱싱을 실행해야 합니다. 예를 들어 데이터베이스 재인덱싱은 GitLab.com에서 토요일과 일요일에 실행됩니다.

> [!note]
> Linux 패키지 인스턴스 관리자인 경우 [관련 지침을 따라](https://docs.gitlab.com/omnibus/settings/database/#automatic-database-reindexing) 수행하여 주기적인 데이터베이스 재인덱싱을 활성화할 수 있습니다.

## 지속성 구성 {#persistence-configuration}

백업 및 복원을 위한 지속성 저장소는 별도로 구성됩니다. GitLab을 백업 및 복원 작업으로 구성할 때 다음 고려 사항을 검토하십시오.

`backups.cron.persistence.*` 속성을 사용하여 백업하고 `persistence.*` 속성을 사용하여 복원합니다. 지속성 저장소 구성에 대한 추가 설명은 최종 속성 키(예: `.enabled` 또는 `.size`)만 사용하고 적절한 접두사를 추가해야 합니다.

지속성 저장소는 기본적으로 비활성화되므로 `.enabled`을 `true`로 설정하여 상당한 크기의 백업 또는 복원을 수행해야 합니다. 또한 `.storageClass`을 지정하여 Kubernetes에서 PersistentVolume을 생성하거나 PersistentVolume을 수동으로 만들어야 합니다. `.storageClass`이 `-`로 지정되면 Kubernetes 클러스터에 지정된 [기본 StorageClass](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/)을 사용하여 PersistentVolume이 생성됩니다.

PersistentVolume을 수동으로 생성하면 `.volumeName` 속성을 사용하거나 선택자 `.matchLables` / `.matchExpressions` 속성을 사용하여 볼륨을 지정할 수 있습니다.

대부분의 경우 `.accessMode`의 기본값은 Toolbox만 PersistentVolumes에 접근할 수 있도록 적절한 제어를 제공합니다. Kubernetes 클러스터에 설치된 CSI 드라이버의 설명서를 참조하여 설정이 올바른지 확인하십시오.

### 구성 요소 백업 {#backup-considerations}

백업 작업은 백업 객체 저장소에 작성되기 전에 백업 중인 개별 구성 요소를 보유할 충분한 디스크 공간이 필요합니다. 디스크 공간의 양은 다음 요소에 따라 달라집니다:

- 프로젝트 수 및 각 프로젝트에 저장된 데이터의 양
- PostgresSQL 데이터베이스의 크기(이슈, MR 등)
- 각 객체 저장소 백엔드의 크기

대략적인 크기가 결정되면 `backups.cron.persistence.size` 속성을 설정하여 백업을 시작할 수 있습니다.

### 복원 고려 사항 {#restore-considerations}

백업 복원 중에 백업을 디스크로 추출한 후 실행 중인 인스턴스의 파일을 바꿔야 합니다. 이 복원 디스크 공간의 크기는 `persistence.size` 속성으로 제어됩니다. GitLab 설치 크기가 증가하면 복원 디스크 공간의 크기도 적절하게 증가해야 합니다. 대부분의 경우 복원 디스크 공간의 크기는 백업 디스크 공간의 크기와 동일해야 합니다.

## Toolbox에 포함된 도구 {#toolbox-included-tools}

Toolbox 컨테이너에는 Rails 콘솔, Rake 작업 등과 같은 유용한 GitLab 도구가 포함되어 있습니다. 이러한 명령을 사용하면 데이터베이스 마이그레이션 상태를 확인하고, 관리 작업을 위한 Rake 작업을 실행하고, Rails 콘솔과 상호작용할 수 있습니다:

```shell
# locate the Toolbox pod
kubectl get pods -lapp=toolbox

# Launch a shell inside the pod
kubectl exec -it <Toolbox pod name> -- bash

# open Rails console
gitlab-rails console -e production

# execute a Rake task
gitlab-rake gitlab:env:info
```

### `affinity` {#affinity}

자세한 내용은 [`affinity`](../_index.md#affinity)를 참조하세요.
