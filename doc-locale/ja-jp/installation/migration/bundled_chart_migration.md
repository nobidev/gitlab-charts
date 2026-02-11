---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: バンドルされているRedis、PostgreSQL、MinIOチャートからの移行
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

本番環境システムを設定する際は、バンドルされているRedis、MinIO、PostgreSQLから外部で管理されている代替手段に移行する必要があります。

このガイドでは、[Valkey](https://valkey.io/) 、[Garage](https://garagehq.deuxfleurs.fr/) 、[CloudNativePG](https://cloudnative-pg.io/)などのクラウドネイティブの代替手段にそれぞれ移行することを前提としています。

## はじめる前 {#before-you-begin}

バンドルされているRedis、MinIO、PostgreSQLからの移行を開始する前に:

- [インストール要件](https://docs.gitlab.com/install/requirements/)に沿ったサービスを評価します。インフラストラクチャのニーズと組織の要件を満たすクラウドプロバイダーのサービスまたはその他の代替手段を検討してください。一般的なリファレンスアーキテクチャの考慮事項と推奨されるプロバイダーについては、[リファレンスアーキテクチャに関するドキュメント](https://docs.gitlab.com/administration/reference_architectures/#recommended-cloud-providers-and-services)を参照してください。
- この移行の結果、GitLabチャートをアップグレードしても、RedisまたはPostgreSQLデプロイはアップグレードされなくなります。GitLabのメジャーアップグレードでは、Valkey/RedisまたはPostgreSQLの新しいバージョンが必要になる場合があります。このガイドに従うか、GitLabのメジャーアップグレードを行う前に、GitLabバージョンの[要件](https://docs.gitlab.com/install/requirements)を確認してください。
- MinIO、Redis、PostgreSQLの永続ボリュームクレームの現在のサイズとデータの使用状況を確認します。このガイドでは、PostgreSQL用に5 GiB、Valkey用に2 GiB、Garage用に5 GiB（3回レプリケート）が設定されていますが、調整が必要になる場合があります。
- GitLabは、このドキュメントに記載されているサードパーティアプリケーションの設定またはトラブルシューティングを支援できないことに注意してください。GitLab自体は、最小限の設定で、適切にフォーマットされたデータをサードパーティに送信していることを確認できます。
- この移行のためのダウンタイムを計画してください。新しい外部サービスへのデータのインポート中、GitLabにはアクセスできなくなります。

## バックアップGitLab {#backup-gitlab}

まず、現在のすべてのデータを[バックアップ](../../backup-restore/_index.md)し、バックアップIDをメモします。

次の点に注意してください:

- MinIOの移行を実行している場合は、バックアップアーカイブをローカルマシンにダウンロードする必要があります。
- MinIOのみを移行する場合は、オブジェクトストレージバケットのみをバックアップする必要があります。
- Redisのみを移行する場合は、バックアップと復元の手順を省略できます。
- PostgreSQLのみを移行する場合は、`db`以外のすべてのコンポーネントのバックアップを[スキップ](../../backup-restore/backup.md#skipping-components)できます。
- [レジストリメタデータデータベース](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)を有効にした場合、メタデータデータは[デフォルトのバックアップ/復元プロセス](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#backup-with-metadata-database)ではカバーされません。

## 外部サービスをプロビジョニングする {#provision-external-services}

バンドルされているRedis、PostgreSQL、MinIOチャートを置き換えるには、外部で管理されている代替手段をプロビジョニングするします。利用可能なオプションの概要については、[推奨されるプロバイダーとサービス](https://docs.gitlab.com/administration/reference_architectures/#recommended-cloud-providers-and-services)を確認し、[現在の最小要件](https://docs.gitlab.com/install/requirements/)を満たしていることを確認してください。

### 外部ValkeyまたはRedisをプロビジョニングする {#provision-external-valkey-or-redis}

1. 外部ValkeyまたはRedisサービスをプロビジョニングするします。たとえば、公式の[Valkey Helmチャート](https://github.com/valkey-io/valkey-helm)を使用します:

   {{< alert type="note" >}}

   これにより、再起動後もデータを保持する独立したValkeyインスタンスがセットアップされます。認証認証情報は、`<RELEASE>-auth`という名前のシークレットに保存されます。

   {{< /alert >}}

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

1. Valkeyが起動して実行されていることを確認します:

   ```script
   $ kubectl get deployment -n <NAMESPACE> -l app.kubernetes.io/name=valkey
   NAME     READY   UP-TO-DATE   AVAILABLE   AGE
   valkey   1/1     1            1           30m
   ```

### 外部PostgreSQLをプロビジョニングする {#provision-external-postgresql}

外部PostgreSQLサービスをプロビジョニングするします。たとえば、[CloudNativePG](https://cloudnative-pg.io/docs/1.28/installation_upgrade)を使用します:

1. CloudNativePG Operatorをインストールします:

   ```shell
   kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.28/releases/cnpg-1.28.0.yaml
   ```

1. GitLab用のPostgreSQLクラスターをプロビジョニングするします（[レジストリメタデータデータベース](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)は対象外です）:

  {{< alert type="note" >}}

  クラスターをカスタマイズするには、[Cluster API](https://cloudnative-pg.io/docs/1.28/cloudnative-pg.v1/#postgresqlcnpgiov1)を確認してください。

  {{< /alert >}}

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

1. PostgreSQLクラスターが正常であることを確認します:

   ```script
   $ kubectl get clusters -n <NAMESPACE>
   NAME                 AGE   INSTANCES   READY   STATUS                     PRIMARY
   gitlab-rails-db      20m   1           1       Cluster in healthy state   gitlab-rails-db-1
   ```

### 外部オブジェクトストレージをプロビジョニングする {#provision-external-object-storage}

バンドルされているMinIOから移行するには、外部オブジェクトストレージソリューションをプロビジョニングするします。

1つのオプションは[Garage](https://garagehq.deuxfleurs.fr/)です。インストールする前に、[デプロイガイド](https://garagehq.deuxfleurs.fr/documentation/cookbook/real-world/)と[Kubernetesドキュメント](https://garagehq.deuxfleurs.fr/documentation/cookbook/kubernetes/)を確認してください。

1. Garage Helmチャートをインストールします:

   ```shell
   helm plugin install https://github.com/aslafy-z/helm-git
   helm repo add garage "git+https://git.deuxfleurs.fr/Deuxfleurs/garage.git@script/helm?ref=main-v1"
   helm install garage garage/garage -n <NAMESPACE> \
     --set persistence.data.size=5Gi \
     --set persistence.meta.size=250Mi
   ```

1. Garageが起動して実行されていることを確認します:

   ```shell
   $ kubectl get statefulsets.apps -n garage -l app.kubernetes.io/name=garage
   NAME     READY   AGE
   garage   3/3     36s
   ```

1. クラスターのレイアウトを初期化します。

  {{< alert type="note" >}}

  この例では、3つのゾーン、ゾーンごとに1つのノード、デフォルトのレプリケーション係数3を使用したGarageレイアウトをプロビジョニングするします。要件に合わせてこれらの設定を調整するには、[Garageの本番環境に関する推奨事項](https://garagehq.deuxfleurs.fr/documentation/cookbook/real-world/)を確認してください。

  {{< /alert >}}

   GitLabは、プライマリオブジェクトデータとバックアップの両方を同じストレージバックエンド（この場合はGarage）に保存するため、オブジェクトストレージまたは永続レイヤーでの失敗は両方のデータセットに影響を与える可能性があります。したがって、定期的に[GitLabをバックアップする](../../backup-restore/_index.md)ことに加えて、[Garageの失敗からの復元](https://garagehq.deuxfleurs.fr/documentation/operations/recovering/)にも慣れておく必要があります。

   ```shell
   # Check node IDs
   kubectl exec garage-0  -- /garage status

   # Assign nodes to gitlab zone
   kubectl exec garage-0  -- /garage layout assign -z gitlab1 -c 5G <Node ID 1>
   kubectl exec garage-0  -- /garage layout assign -z gitlab2 -c 5G <Node ID 2>
   kubectl exec garage-0  -- /garage layout assign -z gitlab3 -c 5G <Node ID 3>

   # Apply the layout
   kubectl exec garage-0  -- /garage layout apply --version 1
   ```

1. GitLabバケットを作成します:

  {{< alert type="note" >}}

  次のコマンドは、GitLabチャートからのデフォルトのバケット名を使用します。以前にバケット名をカスタマイズした場合は、必要に応じて、以下の手順でそれに応じて調整してください。

  {{< /alert >}}

   ```shell
   buckets=("git-lfs" "gitlab-artifacts" "gitlab-backups" "gitlab-ci-secure-files" \
            "gitlab-dependency-proxy" "gitlab-mr-diffs" "gitlab-packages" "gitlab-pages" \
            "gitlab-terraform-state" "gitlab-uploads" "registry" "runner-cache" "tmp" )
   for bucket in "${buckets[@]}"; do
     kubectl exec -n <NAMESPACE> garage-0  -- /garage bucket create "${bucket}";
   done
   ```

1. APIキーを作成し、アクセスキーとシークレットキーをメモして、作成したバケットへのアクセスを許可します:

   ```shell
   # Create GitLab key. Note down the access and secret key.
   kubectl exec -n <NAMESPACE> garage-0  -- /garage key create gitlab-app-key
   # Grant permissions to the GitLab key.
   for bucket in "${buckets[@]}"; do
     kubectl exec -n <NAMESPACE> garage-0  -- /garage bucket allow --read --write --key gitlab-app-key "${bucket}";
   done
   ```

1. オブジェクトストレージアクセスを設定するシークレットを作成します。`GARAGE_ACCESS_KEY`、`GARAGE_SECRET_KEY`、`NAMESPACE`のプレースホルダーを必ず置き換えてください:

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

1. バックアップ/復元のアクセスを設定するシークレットを作成します:

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

## GitLabを設定してアップグレードする {#configure-and-upgrade-gitlab}

すべての代替手段がプロビジョニングするされたので、バンドルされているMinIO、Redis、PostgreSQLを無効にできます。

1. MinIO永続ボリュームが当面保持されるようにします。

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

  {{< alert type="note" >}}

  RedisおよびPostgreSQL永続ボリュームは、Helmではなく、それらのStatefulSetによって管理されます。デフォルトの保持ポリシーは[`Retain`](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#persistentvolumeclaim-retention)です。このポリシーを変更しない限り、これらの2つのボリュームは、StatefulSetを削除しても削除されません。

  {{< /alert >}}

1. 新しくプロビジョニングするされたサービスを指すように値を更新します:

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
         connection:
           secret: gitlab-object-storage
           key: config
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

   # Disable bundled PostgreSQL and Redis.
   postgresql:
     install: false
   redis:
     install: false
   ```

   詳細については、関連する[Redis](../../advanced/external-redis/_index.md) 、[PostgreSQL](../../advanced/external-db/_index.md) 、および[オブジェクトストレージ](../../advanced/external-object-storage/_index.md)のドキュメントを確認してください。

1. PostgreSQLを移行する場合は、移行を無効にしてGitLabインスタンスをアップグレードします:

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml --set gitlab.migrations.enabled=false
   ```

1. MinIOを移行する場合は、バックアップをツールボックスにコピーし、新しいオブジェクトストレージにアップロードします:

   ```shell
   # Find Toolbox Pod
   kubectl get pods -l app=toolbox
   # Copy backup archive to Pod
   kubectl cp LOCAL_BACKUP_ARCHIVE.tar <TOOLBOX_POD>:/tmp
   # Upload archive to backup bucket
   s3cmd put /tmp/LOCAL_BACKUP_ARCHIVE.tar s3://gitlab-backups/
   ```

1. PostgreSQLまたはMinIOを移行する場合は、[ワークロードをスケールダウンし、バックアップを復元します](../../backup-restore/restore.md#restoring-the-backup-file)。
1. アップグレードが完了したら、GitLabインスタンスをアップグレードして、保留中の移行を実行します。

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml
   ```

1. GitLabが動作していることを確認します。

1. 新しいバックアップを実行して、[バックアップ](../../backup-restore/backup.md)が意図したとおりに動作することを確認します。

1. バンドルされているPostgreSQL、MinIO、およびRedisに関連するシークレットとPersistentVolumeClaimsを削除します。

   ```shell
   kubectl delete pvc <RELEASE>-minio redis-data-<RELEASE>-redis-master-0 data-<RELEASE>-postgresql-0
   kubectl delete secret <RELEASE>-postgresql-password <RELEASE>-redis-secret <RELEASE>-minio-secret <RELEASE>-minio-tls
   ```
