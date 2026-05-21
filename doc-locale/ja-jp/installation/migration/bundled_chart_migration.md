---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: バンドルされたRedis、PostgreSQL、MinIOチャートから移行する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

本番システムを設定する際は、バンドルされたRedis、MinIO、PostgreSQLから、外部で管理されている代替手段に移行する必要があります。

> [!warning]バンドルされたRedis、MinIO、およびPostgreSQLは[非推奨](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart)であり、GitLab 19.0で削除されます。

このガイドでは、[Valkey](https://valkey.io/)、[Garage](https://garagehq.deuxfleurs.fr/)、[CloudNativePG](https://cloudnative-pg.io/)といったクラウドネイティブの代替手段に移行することを前提としています。

この移行プロセスを実行するには、次の手順を実行する必要があります:

- 外部サービスをプロビジョニングする: 選択した外部サービスをデプロイし、設定します。
- データをバックアップする: バンドルされたPostgreSQLおよびMinIOサービスからすべてのデータのバックアップを作成します。
- GitLabを再設定する: バンドルされたサービスの代わりに外部サービスを使用するようにGitLabの設定を更新します。
- 新しいサービスに復元する: 新しくプロビジョニングされた外部サービスにバックアップデータを復元する。
- 古いサービスをクリーンアップする: 移行が完了したことを確認したら、古いバンドルされたサービスとその永続ボリュームを手動で削除します。

## はじめる前 {#before-you-begin}

バンドルされたRedis、MinIO、PostgreSQLからの移行を開始する前に:

- [インストール要件](https://docs.gitlab.com/install/requirements/)に合致するサービスを評価します。インフラストラクチャのニーズと組織の要件を満たす、クラウドプロバイダーのサービスやその他の代替手段を検討してください。一般的なリファレンスアーキテクチャの考慮事項や推奨プロバイダーについては、[リファレンスアーキテクチャに関するドキュメント](https://docs.gitlab.com/administration/reference_architectures/#recommended-cloud-providers-and-services)を参照してください。
- この移行の後、GitLabチャートをアップグレードしても、RedisまたはPostgreSQLデプロイはアップグレードされなくなります。GitLabのメジャーアップグレードでは、Valkey/RedisまたはPostgreSQLのより新しいバージョンが必要になる場合があります。このガイドに従う前、またはGitLabのメジャーアップグレードを行う前に、ご使用のGitLabバージョンの[要件](https://docs.gitlab.com/install/requirements)を確認してください。
- MinIO、Redis、PostgreSQLの永続ボリューム要件の現在のサイズとデータの使用状況を確認してください。このガイドでは、PostgreSQL用に5 GiB、Valkey用に2 GiB、Garage用に5 GiB（3回レプリケート）を設定しますが、調整が必要になる場合があります。
- このドキュメントに記載されているサードパーティアプリケーションの設定やトラブルシューティングについて、GitLabは支援できないことに注意してください。GitLab側では、最小限の構成において、適切に整形されたデータをサードパーティに送信していることのみを確認できます。
- この移行に伴うダウンタイムを計画してください。新しい外部サービスにデータをインポートしている間、GitLabにはアクセスできなくなります。

## GitLabをバックアップする {#backup-gitlab}

まず、現在のデータをすべて[バックアップ](../../backup-restore/_index.md)し、バックアップIDを書き留めます。

次の点に注意してください:

- MinIOを移行する場合は、バックアップアーカイブをローカルマシンにダウンロードする必要があります。
- MinIOのみを移行する場合は、オブジェクトストレージのバケットのみをバックアップする必要があります。
- Redisのみを移行する場合は、バックアップと復元の手順をスキップできます。
- PostgreSQLのみを移行する場合は、`db`を除くすべてのコンポーネントのバックアップを[スキップ](../../backup-restore/backup.md#skipping-components)できます。
- [レジストリメタデータデータベース](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)を有効にしている場合、そのメタデータは[デフォルトのバックアップ/復元プロセス](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#backup-with-metadata-database)の対象外です。

## 外部サービスをプロビジョニングする {#provision-external-services}

バンドルされたRedis、PostgreSQL、MinIOチャートを置き換えるには、外部で管理されている代替手段をプロビジョニングします。利用可能なオプションの概要については、[推奨されるプロバイダーとサービス](https://docs.gitlab.com/administration/reference_architectures/#recommended-cloud-providers-and-services)を確認し、[現在の最小要件](https://docs.gitlab.com/install/requirements/)を満たしていることを確認してください。

### 外部ValkeyまたはRedisをプロビジョニングする {#provision-external-valkey-or-redis}

1. 外部ValkeyまたはRedisサービスをプロビジョニングします。たとえば、公式の[Valkey Helmチャート](https://github.com/valkey-io/valkey-helm)を使用します:

   これにより、再起動後もデータを保持する独立したValkeyインスタンスをセットアップします。認証情報は、`<RELEASE>-auth`という名前のシークレットに保存されます。

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

1. Valkeyが起動して実行中であることを確認します:

   ```script
   $ kubectl get deployment -n <NAMESPACE> -l app.kubernetes.io/name=valkey
   NAME     READY   UP-TO-DATE   AVAILABLE   AGE
   valkey   1/1     1            1           30m
   ```

### 外部PostgreSQLをプロビジョニングする {#provision-external-postgresql}

外部PostgreSQLサービスをプロビジョニングします。たとえば、[CloudNativePG](https://cloudnative-pg.io/docs/1.28/installation_upgrade)を使用します:

1. CloudNativePG Operatorをインストールします:

   ```shell
   kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.28/releases/cnpg-1.28.0.yaml
   ```

1. GitLab用のPostgreSQLクラスターをプロビジョニングします（[レジストリメタデータデータベース](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)は対象です）:

   クラスターをカスタマイズするには、[クラスターAPI](https://cloudnative-pg.io/docs/1.28/cloudnative-pg.v1/#postgresqlcnpgiov1)を確認してください。

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

### 外部オブジェクトストレージ用にGarageをプロビジョニングする {#provision-garage-for-external-object-storage}

バンドルされたMinIOから移行するには、独自の外部オブジェクトストレージソリューションをプロビジョニングする必要があります。

オプションの1つとして[Garage](https://garagehq.deuxfleurs.fr/)があります。Garageをインストールする前に、Garageのドキュメントで以下を確認してください:

- [クラスターへのデプロイ](https://garagehq.deuxfleurs.fr/documentation/cookbook/real-world/)。
- [Kubernetesへのデプロイ](https://garagehq.deuxfleurs.fr/documentation/cookbook/kubernetes/)。

前提条件: 

- Garage Appのバージョン2.2.0。

1. Garage Helmチャートをインストールします:

   ```shell
   helm plugin install https://github.com/aslafy-z/helm-git
   helm repo add garage "git+https://git.deuxfleurs.fr/Deuxfleurs/garage.git@script/helm?ref=v2.2.0"
   helm install garage garage/garage -n <NAMESPACE> \
     --set persistence.data.size=5Gi \
     --set persistence.meta.size=250Mi
   ```

1. Garageが起動して実行中であることを確認します:

   ```shell
   $ kubectl get statefulsets.apps -n garage -l app.kubernetes.io/name=garage
   NAME     READY   AGE
   garage   3/3     36s
   ```

1. クラスターのレイアウトを初期化します。

   > [!note]この例では、Garageのレイアウトを3つのゾーン、ゾーンごとに1つのノードでプロビジョニングし、デフォルトの3つのレプリケーションファクターを使用します。[Garageの本番環境における推奨事項](https://garagehq.deuxfleurs.fr/documentation/cookbook/real-world/)を確認し、要件に合わせてこれらの設定を調整してください。

   GitLabは、プライマリのオブジェクトデータとバックアップの両方を同じストレージバックエンド（この例ではGarage）に保存します。そのため、オブジェクトストレージまたは永続化レイヤーで障害が発生すると、両方のデータセットに影響する可能性があります。したがって、定期的に[GitLabをバックアップ](../../backup-restore/_index.md)することに加え、[Garageの障害からの回復](https://garagehq.deuxfleurs.fr/documentation/operations/recovering/)についても把握しておく必要があります。

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

1. GitLabバケットを作成します:

   > [!note]次のコマンドは、GitLabチャートのデフォルトのバケット名を使用します。以前にバケット名をカスタマイズした場合は、必要に応じてこれ以降の手順で調整してください。

   ```shell
   buckets=("git-lfs" "gitlab-artifacts" "gitlab-backups" "gitlab-ci-secure-files" \
            "gitlab-dependency-proxy" "gitlab-mr-diffs" "gitlab-packages" "gitlab-pages" \
            "gitlab-terraform-state" "gitlab-uploads" "registry" "runner-cache" "tmp" )
   for bucket in "${buckets[@]}"; do
     kubectl exec -n <NAMESPACE> <GARAGE_POD>  -- /garage bucket create "${bucket}";
   done
   ```

1. APIキーを作成し、アクセスキーとシークレットキーを書き留めて、作成したバケットへのアクセスを許可します:

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

1. バックアップ/復元用のアクセスを設定するシークレットを作成します:

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

1. レジストリへのアクセスを設定するシークレットを作成する:

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

## 外部サービスへ移行する {#migrate-to-external-services}

すべての代替手段をプロビジョニングしたら、バンドルされているMinIO、Redis、PostgreSQLを無効にできます。

1. まず、MinIOの永続ボリュームが当面は保持されるようにしてください。

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

   > [!note] RedisとPostgreSQLの永続ボリュームは、Helmではなく、そのStatefulSetによって管理されます。デフォルトの保持ポリシーは[`Retain`](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#persistentvolumeclaim-retention)です。このポリシーを変更していない限り、StatefulSetを削除してもこれら2つのボリュームは削除されません。

1. 新しくプロビジョニングしたサービスを指すように値を更新します:

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

   詳細については、関連する[Redis](../../advanced/external-redis/_index.md)、[PostgreSQL](../../advanced/external-db/_index.md)、[オブジェクトストレージ](../../advanced/external-object-storage/_index.md)のドキュメントを確認してください。

1. PostgreSQLを移行する場合は、移行を無効にした状態でGitLabインスタンスをアップグレードします:

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml --set gitlab.migrations.enabled=false
   ```

1. MinIOを移行する場合は、バックアップをToolboxにコピーし、新しいオブジェクトストレージにアップロードします:

   ```shell
   # Find Toolbox Pod
   kubectl get pods -l app=toolbox
   # Copy backup archive to Pod
   kubectl cp LOCAL_BACKUP_ARCHIVE.tar <TOOLBOX_POD>:/tmp
   # Upload archive to backup bucket
   s3cmd put /tmp/LOCAL_BACKUP_ARCHIVE.tar s3://gitlab-backups/
   ```

1. PostgreSQLまたはMinIOを移行する場合は、[ワークロードをスケールダウンし、バックアップを復元](../../backup-restore/restore.md#restoring-the-backup-file)します。
1. アップグレードが完了したら、GitLabインスタンスをアップグレードして、保留中の移行を実行します。

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml
   ```

1. GitLabが動作していることを確認します。
1. 新しいバックアップを実行して、[バックアップ](../../backup-restore/backup.md)が意図したとおりに動作することを確認します。
1. バンドルされているPostgreSQL、MinIO、Redisに関連するシークレットとPersistentVolumeClaimsを削除します。

   ```shell
   kubectl delete pvc <RELEASE>-minio redis-data-<RELEASE>-redis-master-0 data-<RELEASE>-postgresql-0
   kubectl delete secret <RELEASE>-postgresql-password <RELEASE>-redis-secret <RELEASE>-minio-secret <RELEASE>-minio-tls
   ```
