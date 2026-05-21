---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "번들 Redis, PostgreSQL 및 MinIO 차트에서 마이그레이션"
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

프로덕션 시스템을 구성할 때 번들 Redis, MinIO 및 PostgreSQL에서 외부에서 관리하는 대안으로 마이그레이션해야 합니다.

> [!warning]
> 번들 Redis, MinIO 및 PostgreSQL은 [더 이상 사용되지 않으며](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart) GitLab 19.0에서 제거될 예정입니다.

이 가이드는 [Valkey](https://valkey.io/) , [Garage](https://garagehq.deuxfleurs.fr/) 및 [CloudNativePG](https://cloudnative-pg.io/)와 같은 Cloud Native 대안으로 마이그레이션한다고 가정합니다.

이 마이그레이션 프로세스를 위해서는 다음 단계를 수행해야 합니다:

- 외부 서비스 프로비전:  선택한 외부 서비스를 배포하고 구성합니다.
- 데이터 백업:  번들 PostgreSQL 및 MinIO 서비스의 모든 데이터 백업을 생성합니다.
- GitLab 재구성:  번들 서비스 대신 외부 서비스를 사용하도록 GitLab 구성을 업데이트합니다.
- 새 서비스로 복원:  백업 데이터를 새로 프로비전된 외부 서비스로 복원합니다.
- 이전 서비스 정리:  마이그레이션이 완료되었음을 확인한 후 이전 번들 서비스 및 해당 영구 볼륨을 수동으로 삭제합니다.

## 시작하기 전에 {#before-you-begin}

번들 Redis, MinIO 또는 PostgreSQL에서 마이그레이션하기 전에:

- [설치 요구 사항](https://docs.gitlab.com/install/requirements/)과 일치하는 서비스를 평가합니다. 인프라 요구 사항과 조직 요구 사항을 충족하는 클라우드 제공자 서비스 또는 기타 대안을 고려합니다. 일반적인 참조 아키텍처 고려 사항 및 권장 제공자는 [참조 아키텍처 설명서](https://docs.gitlab.com/administration/reference_architectures/#recommended-cloud-providers-and-services)를 참조하세요.
- 이 마이그레이션의 결과로 GitLab 차트를 업그레이드하면 더 이상 Redis 또는 PostgreSQL 배포를 업그레이드하지 않습니다. 주요 GitLab 업그레이드는 Valkey/Redis 또는 PostgreSQL의 최신 버전이 필요할 수 있습니다. 이 가이드를 따르기 전에 또는 주요 GitLab 업그레이드를 수행하기 전에 GitLab 버전의 [요구 사항](https://docs.gitlab.com/install/requirements)을 확인하세요.
- MinIO, Redis 및 PostgreSQL 영구 볼륨 청구의 현재 크기 및 데이터 사용량을 확인합니다. 이 가이드는 PostgreSQL의 경우 5GiB, Valkey의 경우 2GiB, Garage의 경우 5GiB(3배로 복제)를 구성하며, 조정이 필요할 수 있습니다.
- GitLab은 이 문서에서 언급한 타사 애플리케이션의 구성 또는 문제 해결에 도움을 드릴 수 없습니다. GitLab 자체가 최소 구성으로 타사에 올바른 형식의 데이터를 전송하고 있는지 확인할 수 있습니다.
- 이 마이그레이션을 위해 다운타임을 계획합니다. 새 외부 서비스로 데이터를 가져오는 동안 GitLab에 접근할 수 없습니다.

## GitLab 백업 {#backup-gitlab}

먼저 현재 데이터 [백업](../../backup-restore/_index.md)하고 백업 ID를 기록합니다.

다음 사항을 참고하세요:

- MinIO를 마이그레이션하는 경우 백업 아카이브를 로컬 머신으로 다운로드해야 합니다.
- MinIO만 마이그레이션하는 경우 객체 저장소 버킷만 백업해야 합니다.
- Redis만 마이그레이션하는 경우 백업 및 복원 단계를 건너뛸 수 있습니다.
- PostgreSQL만 마이그레이션하는 경우 `db` 외에 모든 구성 요소 백업을 [건너뛸](../../backup-restore/backup.md#skipping-components) 수 있습니다.
- [Registry Metadata Database](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/) 를 활성화한 경우 메타데이터 데이터는 [기본 백업/복원 프로세스](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#backup-with-metadata-database)에 포함되지 않습니다.

## 외부 서비스 프로비전 {#provision-external-services}

번들 Redis, PostgreSQL 및 MinIO 차트를 교체하려면 외부에서 관리하는 대체 제품을 프로비전합니다. 사용 가능한 옵션 개요는 [권장 제공자 및 서비스](https://docs.gitlab.com/administration/reference_architectures/#recommended-cloud-providers-and-services) 를 확인하고 [현재 최소 요구 사항](https://docs.gitlab.com/install/requirements/)을 충족하는지 확인하세요.

### 외부 Valkey 또는 Redis 프로비전 {#provision-external-valkey-or-redis}

1. 외부 Valkey 또는 Redis 서비스를 프로비전합니다. 예를 들어 공식 [Valkey Helm 차트](https://github.com/valkey-io/valkey-helm)를 사용하여:

   이는 재시작 시 데이터를 유지하는 독립적인 Valkey 인스턴스를 설정합니다. 인증 자격 증명은 `<RELEASE>-auth` 이름의 Secret에 저장됩니다.

   ```shell
   helm repo add valkey https://valkey.io/valkey-helm/
   helm install valkey valkey/valkey -n <NAMESPACE> \
     --set dataStorage.enabled=true \
     --set dataStorage.size=2Gi \
     --set metrics.enabled=true \
     --set auth.enabled=true \
     --set auth.aclUsers.default.permissions="~* &* +@all" \
     --set auth.aclUsers.default.password="<RANDOM PASSWORD>"
   ```

1. Valkey가 작동 중인지 확인합니다:

   ```script
   $ kubectl get deployment -n <NAMESPACE> -l app.kubernetes.io/name=valkey
   NAME     READY   UP-TO-DATE   AVAILABLE   AGE
   valkey   1/1     1            1           30m
   ```

### 외부 PostgreSQL 프로비전 {#provision-external-postgresql}

외부 PostgreSQL 서비스를 프로비전합니다. 예를 들어 [CloudNativePG](https://cloudnative-pg.io/docs/1.28/installation_upgrade)를 사용하여:

1. CloudNativePG 운영자를 설치합니다:

   ```shell
   kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.28/releases/cnpg-1.28.0.yaml
   ```

1. GitLab용 PostgreSQL 클러스터를 프로비전합니다([Registry Metadata Database](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)는 포함되지 않음):

   [Cluster API](https://cloudnative-pg.io/docs/1.28/cloudnative-pg.v1/#postgresqlcnpgiov1)를 확인하여 클러스터를 사용자 정의합니다.

   ```yaml
   apiVersion: postgresql.cnpg.io/v1
   kind: Cluster
   metadata:
     name: gitlab-rails-db
     namespace: <NAMESPACE>
   spec:
     instances: 1
     imageName: ghcr.io/cloudnative-pg/postgresql:17
     storage:
       size: 5Gi
     bootstrap:
       initdb:
         database: gitlabhq_production
         owner: gitlab
         postInitSQL:
           - CREATE EXTENSION IF NOT EXISTS pg_trgm;
           - CREATE EXTENSION IF NOT EXISTS btree_gist;
           - CREATE EXTENSION IF NOT EXISTS plpgsql;
           - CREATE EXTENSION IF NOT EXISTS amcheck;
           - CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
   ```

1. PostgreSQL 클러스터가 정상인지 확인합니다:

   ```script
   $ kubectl get clusters -n <NAMESPACE>
   NAME                 AGE   INSTANCES   READY   STATUS                     PRIMARY
   gitlab-rails-db      20m   1           1       Cluster in healthy state   gitlab-rails-db-1
   ```

### 외부 객체 저장소용 Garage 프로비전 {#provision-garage-for-external-object-storage}

번들 MinIO에서 마이그레이션하려면 자신의 외부 객체 저장소 솔루션을 프로비전해야 합니다.

한 가지 옵션은 [Garage](https://garagehq.deuxfleurs.fr/)입니다. Garage를 설치하기 전에 Garage 설명서를 검토하세요:

- [클러스터에 배포](https://garagehq.deuxfleurs.fr/documentation/cookbook/real-world/).
- [Kubernetes에 배포](https://garagehq.deuxfleurs.fr/documentation/cookbook/kubernetes/).

전제 조건:

- Garage App 버전 2.2.0.

1. Garage Helm 차트를 설치합니다:

   ```shell
   helm plugin install https://github.com/aslafy-z/helm-git
   helm repo add garage "git+https://git.deuxfleurs.fr/Deuxfleurs/garage.git@script/helm?ref=v2.2.0"
   helm install garage garage/garage -n <NAMESPACE> \
     --set persistence.data.size=5Gi \
     --set persistence.meta.size=250Mi
   ```

1. Garage가 작동 중인지 확인합니다:

   ```shell
   $ kubectl get statefulsets.apps -n garage -l app.kubernetes.io/name=garage
   NAME     READY   AGE
   garage   3/3     36s
   ```

1. 클러스터 레이아웃을 초기화합니다.

   > [!note]
   > 이 예제는 3개의 영역, 영역당 1개 노드가 있는 Garage 레이아웃을 프로비전하며 기본 복제 계수 3을 사용합니다. [Garage 프로덕션 권장 사항](https://garagehq.deuxfleurs.fr/documentation/cookbook/real-world/)을 검토하고 요구 사항에 맞게 이러한 설정을 조정합니다.

   GitLab은 동일한 저장소 백엔드(이 경우 Garage)에 기본 객체 데이터와 백업을 모두 저장하므로, 객체 저장소 또는 지속성 계층의 모든 장애는 두 데이터 세트 모두에 영향을 미칠 수 있습니다. 따라서 정기적으로 [GitLab을 백업](../../backup-restore/_index.md) 하는 것 외에도 [Garage 장애에서 복구](https://garagehq.deuxfleurs.fr/documentation/operations/recovering/)하는 방법을 숙지해야 합니다.

   ```shell
   # Check node IDs
   kubectl exec <GARAGE_POD>  -- /garage status

   # Assign nodes to gitlab zone
   kubectl exec <GARAGE_POD>  -- /garage layout assign -z gitlab1 -c 5G <Node ID 1>
   kubectl exec <GARAGE_POD>  -- /garage layout assign -z gitlab2 -c 5G <Node ID 2>
   kubectl exec <GARAGE_POD>  -- /garage layout assign -z gitlab3 -c 5G <Node ID 3>

   # Apply the layout
   kubectl exec <GARAGE_POD>  -- /garage layout apply --version 1
   ```

1. GitLab 버킷을 생성합니다:

   > [!note]
   > 다음 명령은 GitLab 차트의 기본 버킷 이름을 사용합니다. 이전에 버킷 이름을 사용자 정의한 경우 여기 및 아래 단계에서 이에 따라 조정합니다.

   ```shell
   buckets=("git-lfs" "gitlab-artifacts" "gitlab-backups" "gitlab-ci-secure-files" \
            "gitlab-dependency-proxy" "gitlab-mr-diffs" "gitlab-packages" "gitlab-pages" \
            "gitlab-terraform-state" "gitlab-uploads" "registry" "runner-cache" "tmp" )
   for bucket in "${buckets[@]}"; do
     kubectl exec -n <NAMESPACE> <GARAGE_POD>  -- /garage bucket create "${bucket}";
   done
   ```

1. API 키를 생성하고 액세스 및 비밀 키를 기록하고 생성된 버킷에 대한 액세스 권한을 부여합니다:

   ```shell
   # Create GitLab key. Note down the access and secret key.
   # For ease of access we can create a variable 'KEY_OUTPUT' and store
   # the output of 'kubectl exec -n <NAMESPACE> <GARAGE_POD>  -- /garage key create gitlab-app-key'
   # and then parse the values for 'GARAGE_ACCESS_KEY' and 'GARAGE_SECRET_KEY'
   local KEY_OUTPUT
   KEY_OUTPUT=$(kubectl exec -n <NAMESPACE> <GARAGE_POD> -- \
       /garage key create gitlab-app-key)

   local GARAGE_ACCESS_KEY GARAGE_SECRET_KEY
   GARAGE_ACCESS_KEY=$(echo "${KEY_OUTPUT}" | grep 'Key ID:' | awk '{print $3}')
   GARAGE_SECRET_KEY=$(echo "${KEY_OUTPUT}" | grep 'Secret key:' | awk '{print $3}')

   # Grant permissions to the GitLab key.
   for bucket in "${buckets[@]}"; do
     kubectl exec -n <NAMESPACE> <GARAGE_POD>  -- /garage bucket allow --read --write --key gitlab-app-key "${bucket}";
   done
   ```

1. 객체 저장소 액세스를 구성하는 Secret을 생성합니다. `GARAGE_ACCESS_KEY`, `GARAGE_SECRET_KEY` 및 `NAMESPACE` 자리 표시자를 바꾸어야 합니다:

   ```shell
   cat <<EOF | kubectl create secret generic gitlab-object-storage --from-file=config=/dev/stdin
   provider: AWS
   region: garage
   aws_access_key_id: <GARAGE_ACCESS_KEY>
   aws_secret_access_key: <GARAGE_SECRET_KEY>
   endpoint: "http://garage.<NAMESPACE>.svc.cluster.local:3900"
   path_style: true
   EOF
   ```

1. 백업/복원용 액세스를 구성하는 Secret을 생성합니다:

   ```shell
   cat <<EOF | kubectl create secret generic gitlab-object-storage-s3cmd --from-file=config=/dev/stdin
   [default]
   access_key = <GARAGE_ACCESS_KEY>
   secret_key = <GARAGE_SECRET_KEY>
   host_base = garage.<NAMESPACE>.svc.cluster.local:3900
   host_bucket = garage.<NAMESPACE>.svc.cluster.local:3900
   use_https = False
   EOF
   ```

1. 레지스트리용 액세스를 구성하는 Secret을 생성합니다:

   ```shell
   cat <<EOF | kubectl create secret generic gitlab-registry-storage --from-file=config=/dev/stdin
   s3:
     accesskey: ${GARAGE_ACCESS_KEY}
     secretkey: ${GARAGE_SECRET_KEY}
     bucket: registry
     region: garage
     regionendpoint: http://garage.${NAMESPACE}.svc.cluster.local:3900
     secure: false
     v4auth: true
     pathstyle: true
   EOF
   ```

## 외부 서비스로 마이그레이션 {#migrate-to-external-services}

모든 대체 제품이 프로비전되면 번들 MinIO, Redis 및 PostgreSQL을 비활성화할 수 있습니다.

1. MinIO 영구 볼륨은 지금을 위해 유지되도록 합니다.

   ```yaml
   minio:
     persistence:
       # keep: true # Only available in GitLab chart 9.8+
       annotations:
         helm.sh/resource-policy: "keep"
   ```

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml
   kubectl annotate pvc <RELEASE>-minio --list
   ```

   > [!note]
   > Redis 및 PostgreSQL 영구 볼륨은 Helm 대신 StatefulSet에 의해 관리됩니다. 기본 보존 정책은 [`Retain`](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#persistentvolumeclaim-retention)입니다. 이 정책을 수정하지 않은 경우, StatefulSet을 제거할 때 이 두 볼륨이 삭제되지 않습니다.

1. 새로 프로비전된 서비스를 가리키도록 값을 업데이트합니다:

   ```yaml
   global:
     # Configure DB managed by CloudNativePG.
     psql:
       host: gitlab-rails-db-rw.<NAMESPACE>.svc.cluster.local
       password:
        secret: gitlab-rails-db-app
        key: password
     # Configure Valkey service.
     redis:
       host: valkey.<NAMESPACE>.svc.cluster.local
       auth:
        secret: valkey-auth # <VALKEY RELEASE>-auth
        key: default-password
     # Configure Garage as object storage.
     appConfig:
       object_store:
         enabled: true
         # If you aren't exposing Garage through the Ingress Gateway API, set object storage download proxying to true
         proxy_download: true
         connection:
           secret: gitlab-object-storage
           key: config
       # Set to buckets created in Garage. Can be omitted if you used the default bucket names.
       artifacts:
         bucket: gitlab-artifacts
       lfs:
         bucket: git-lfs
       uploads:
         bucket: gitlab-uploads
       packages:
         bucket: gitlab-packages
       externalDiffs:
         enabled: true
         bucket: gitlab-mr-diffs
       terraformState:
         enabled: true
         bucket: gitlab-terraform-state
       ciSecureFiles:
         enabled: true
         bucket: gitlab-ci-secure-files
       dependencyProxy:
         enabled: true
         bucket: gitlab-dependency-proxy
     # Disable bundled MinIO.
     minio:
       enabled: false
   # Configure backup/restore to use Garage backend.
   gitlab:
     toolbox:
       backups:
         objectStorage:
           config:
             secret: gitlab-object-storage-s3cmd
             key: config
   # Disable Registry redirect if not exposing Garage via Ingress/Gateway API
   registry:
     storage:
       secret: gitlab-registry-storage
       key: config
       redirect:
         disable: true
   # Disable bundled PostgreSQL and Redis.
   postgresql:
     install: false
   redis:
     install: false
   ```

   관련 [Redis](../../advanced/external-redis/_index.md) , [PostgreSQL](../../advanced/external-db/_index.md) 및 [객체 저장소](../../advanced/external-object-storage/_index.md) 설명서를 확인하세요.

1. PostgreSQL을 마이그레이션하는 경우 마이그레이션이 비활성화된 상태에서 GitLab 인스턴스를 업그레이드합니다:

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml --set gitlab.migrations.enabled=false
   ```

1. MinIO를 마이그레이션하는 경우 백업을 도구 상자로 복사하고 새 객체 저장소로 업로드합니다:

   ```shell
   # Find Toolbox Pod
   kubectl get pods -l app=toolbox
   # Copy backup archive to Pod
   kubectl cp LOCAL_BACKUP_ARCHIVE.tar <TOOLBOX_POD>:/tmp
   # Upload archive to backup bucket
   s3cmd put /tmp/LOCAL_BACKUP_ARCHIVE.tar s3://gitlab-backups/
   ```

1. PostgreSQL 또는 MinIO를 마이그레이션하는 경우 [워크로드를 축소하고 백업을 복원](../../backup-restore/restore.md#restoring-the-backup-file)하세요.
1. 업그레이드가 완료된 후 보류 중인 마이그레이션을 실행하도록 GitLab 인스턴스를 업그레이드합니다.

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml
   ```

1. GitLab이 작동 중인지 확인합니다.
1. [백업](../../backup-restore/backup.md)이 새 백업을 수행하여 의도대로 작동하는지 확인합니다.
1. 번들 PostgreSQL, MinIO 및 Redis와 관련된 Secret 및 PersistentVolumeClaim을 삭제합니다.

   ```shell
   kubectl delete pvc <RELEASE>-minio redis-data-<RELEASE>-redis-master-0 data-<RELEASE>-postgresql-0
   kubectl delete secret <RELEASE>-postgresql-password <RELEASE>-redis-secret <RELEASE>-minio-secret <RELEASE>-minio-tls
   ```
