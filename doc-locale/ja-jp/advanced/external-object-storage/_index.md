---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部オブジェクトストレージでGitLabチャートを設定する
---

GitLabは、Kubernetes内の可用性の高い永続的なデータのためにオブジェクトストレージに依存しています。GitLabは、主要なクラウドオブジェクトストレージプロバイダー向けに、クラウド固有のサービスを介した静的な認証情報と一時的な認証情報の2種類の認証方法をサポートしています。

### 静的な認証情報 {#static-credentials}

これらの認証情報は、すべてのプロバイダーにとって有効期間の長いアクセスキーとシークレットです。

- AWS S3:アクセスキーID + シークレットアクセスキー
- Google Cloud Storage:サービスアカウントJSONキーファイル
- Azure Blob Storage:ストレージアカウント名 + アクセスキー、またはクライアントID + テナントID + クライアントシークレット

### Cloud IAMを介した一時的な認証情報 {#temporary-credentials-through-cloud-iam}

GitLabは、動的な短期間の認証情報のために、プロバイダー固有のワークロード アイデンティティメカニズムを取得できます。

- AWS S3:[サービスアカウント](aws-iam-roles.md)のIAMロール（IRSA）
- Google Cloud Storage:[ワークロードアイデンティティフェデレーション](gke-workload-identity.md)
- Azure Blob Storage:Azure [Kubernetes](azure-workload-identity.md) [Service](azure-workload-identity.md)の[ワークロード](azure-workload-identity.md) [アイデンティティ](azure-workload-identity.md)

これらの一時的な認証情報メカニズムにより、次の方法でセキュリティが向上します。

- 有効期間の長い静的な認証情報を排除します。
- 認証情報の自動ローテーションを提供します。
- きめ細かいアクセストークン アクセス制御を有効にします。
- 認証情報の使用状況のログの生成をサポートします。
- クラウドプロバイダーIAMポリシーと統合します。

## MinIOを無効にする {#disable-minio}

デフォルトでは、`minio`という名前のS3互換ストレージソリューションがチャートとともにデプロイされます。本番環境品質のデプロイメントでは、Google Cloud StorageやAWS S3のようなホスティングされたオブジェクトストレージソリューションを使用することをお勧めします。

MinIOを無効にするには、このオプションを設定し、以下の関連ドキュメントに従ってください。

```shell
--set global.minio.enabled=false
```

[完全な設定の例](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/values-external-objectstorage.yaml)が、[例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples)で提供されています。

## Azure Blob Storage {#azure-blob-storage}

Azure Blob [ストレージ](https://docs.gitlab.com/administration/object_storage/#storage-specific-configuration)の直接[サポート](https://docs.gitlab.com/administration/object_storage/#storage-specific-configuration)は、[アップロードされた添付ファイル、CIジョブ アーティファクト、LFS、および統合された設定を介してサポートされるその他のオブジェクトタイプで利用できます](https://docs.gitlab.com/administration/object_storage/#storage-specific-configuration)。以前のGitLabバージョンでは、[Azure MinIOゲートウェイ](azure-minio-gateway.md)が必要でした。

{{< alert type="note" >}}

GitLabは、Docker [レジストリ](https://github.com/minio/minio/issues/9978)の[ストレージ](https://github.com/minio/minio/issues/9978)としてAzure MinIO [ゲートウェイ](https://github.com/minio/minio/issues/9978)を[サポート](https://github.com/minio/minio/issues/9978) [しません](https://github.com/minio/minio/issues/9978)。[対応するAzureの例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.azure.yaml)を参照して、[Dockerレジストリ](#docker-registry-images)を設定してください。

{{< /alert >}}

Azureはコンテナという単語をblobのコレクションを示すために使用しますが、GitLabはバケットという用語で標準化されています。

Azure Blob [ストレージ](../../charts/globals.md#consolidated-object-storage)では、[統合されたオブジェクトストレージ設定](../../charts/globals.md#consolidated-object-storage)を使用する必要があります。単一のAzureストレージアカウント名とキーを、複数のAzureblobコンテナで使用する必要があります。オブジェクトタイプごとの個別の`connection`設定（たとえば、`artifacts`、`uploads`など）のカスタマイズは許可されていません。

Azure Blob [ストレージ](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azurerm.yaml)を有効にするには、Azure `connection`を定義する例として[`rails.azurerm.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azurerm.yaml)を参照してください。これは、次のコマンドでシークレットとして読み込むことができます。

```shell
kubectl create secret generic gitlab-rails-storage --from-file=connection=rails.azurerm.yml
```

次に、MinIOを無効にして、これらのグローバル設定を設定します。

```shell
--set global.minio.enabled=false
--set global.appConfig.object_store.enabled=true
--set global.appConfig.object_store.connection.secret=gitlab-rails-storage
```

[デフォルト](../../charts/globals.md#specify-buckets)名

{{< alert type="note" >}}

`Requests to the local network are not allowed`で失敗するリクエストが発生した場合は、[トラブルシューティング](#troubleshooting)セクション

{{< /alert >}}

## Dockerレジストリイメージ {#docker-registry-images}

`registry`チャートのオブジェクトストレージの設定は、`registry.storage`キーと`global.registry.bucket`キーを介して行われます。

```shell
--set registry.storage.secret=registry-storage
--set registry.storage.key=config
--set global.registry.bucket=bucket-name
```

{{< alert type="note" >}}

バケット名は、シークレットと`global.registry.bucket`の両方で設定する必要があります。このシークレットはレジストリサーバーで使用され、グローバルはGitLabバックアップで使用されます。

{{< /alert >}}

[ストレージに関するレジストリ チャートのドキュメント](../../charts/registry/_index.md#storage)に従って[シークレット](../../charts/registry/_index.md#storage)を作成し、この[シークレット](../../charts/registry/_index.md#storage)を使用するように[チャート](../../charts/registry/_index.md#storage)を[設定](../../charts/registry/_index.md#storage)します。

[S3](https://distribution.github.io/distribution/storage-drivers/s3/)（S3互換[ストレージ](https://distribution.github.io/distribution/storage-drivers/s3/)。[Azure Blob Storage](#azure-blob-storage)を参照）、[Azure](https://distribution.github.io/distribution/storage-drivers/azure/)、および[GCS](https://distribution.github.io/distribution/storage-drivers/gcs/)ドライバーの例は、[`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)にあります。

- [`registry.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.s3.yaml)
- [`registry.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.gcs.yaml)
- [`registry.azure.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.azure.yaml)

### レジストリ 設定 {#registry-configuration}

1. 使用するストレージ サービスを決定します。
1. 適切なファイルを`registry-storage.yaml`にコピーします。
1. 環境に適した値で編集します。
1. [シークレット](../../charts/registry/_index.md#storage)を作成するには、[ストレージに関するレジストリ チャートのドキュメント](../../charts/registry/_index.md#storage)に従ってください。
1. ドキュメント化されているようにチャートを設定します。

## LFS、アーティファクト、アップロード、パッケージ、外部差分、Terraformステート、依存プロキシ、セキュアファイル {#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy-secure-files}

LFS、アーティファクト、アップロード、パッケージ、外部差分、Terraformステート、セキュアファイル、および仮名化子のオブジェクトストレージの設定は、次のキーを介して行われます。

- `global.appConfig.lfs`
- `global.appConfig.artifacts`
- `global.appConfig.uploads`
- `global.appConfig.packages`
- `global.appConfig.externalDiffs`
- `global.appConfig.dependencyProxy`
- `global.appConfig.terraformState`
- `global.appConfig.ciSecureFiles`

次の点にも注意してください。

- [デフォルト](../../charts/globals.md#specify-buckets)名
- それぞれに異なるバケットが必要です。そうでない場合、バックアップからの復元が正しく機能しません。
- MR差分を外部ストレージに保存することはデフォルトで有効になっていないため、`externalDiffs`のオブジェクトストレージ 設定を有効にするには、`global.appConfig.externalDiffs.enabled`キーに`true`値が必要です。
- 依存プロキシ 機能はデフォルトで有効になっていないため、`dependencyProxy`のオブジェクトストレージ 設定を有効にするには、`global.appConfig.dependencyProxy.enabled`キーに`true`値が必要です。

以下は、設定オプションの例です。

```shell
--set global.appConfig.lfs.bucket=gitlab-lfs-storage
--set global.appConfig.lfs.connection.secret=object-storage
--set global.appConfig.lfs.connection.key=connection

--set global.appConfig.artifacts.bucket=gitlab-artifacts-storage
--set global.appConfig.artifacts.connection.secret=object-storage
--set global.appConfig.artifacts.connection.key=connection

--set global.appConfig.uploads.bucket=gitlab-uploads-storage
--set global.appConfig.uploads.connection.secret=object-storage
--set global.appConfig.uploads.connection.key=connection

--set global.appConfig.packages.bucket=gitlab-packages-storage
--set global.appConfig.packages.connection.secret=object-storage
--set global.appConfig.packages.connection.key=connection

--set global.appConfig.externalDiffs.bucket=gitlab-externaldiffs-storage
--set global.appConfig.externalDiffs.connection.secret=object-storage
--set global.appConfig.externalDiffs.connection.key=connection

--set global.appConfig.terraformState.bucket=gitlab-terraform-state
--set global.appConfig.terraformState.connection.secret=object-storage
--set global.appConfig.terraformState.connection.key=connection

--set global.appConfig.dependencyProxy.bucket=gitlab-dependencyproxy-storage
--set global.appConfig.dependencyProxy.connection.secret=object-storage
--set global.appConfig.dependencyProxy.connection.key=connection

--set global.appConfig.ciSecureFiles.bucket=gitlab-ci-secure-files
--set global.appConfig.ciSecureFiles.connection.secret=object-storage
--set global.appConfig.ciSecureFiles.connection.key=connection
```

詳細については、[appConfigに関するチャート/globalsのドキュメント](../../charts/globals.md#configure-appconfig-settings)を参照してください。

[接続](../../charts/globals.md#connection)の詳細[ドキュメント](../../charts/globals.md#connection)同じシークレットをすべてに使用できます。

[AWS](https://fog.github.io/storage/#using-amazon-s3-and-fog)（[MinIOを使用したAzure](azure-minio-gateway.md)のようなS3互換）および[Google](https://fog.github.io/storage/#google-cloud-storage)プロバイダーの例は、[`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)にあります。

- [`rails.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.s3.yaml)
- [`rails.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.gcs.yaml)
- [`rails.azure.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azure.yaml)
- [`rails.azurerm.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azurerm.yaml)

### S3暗号化 {#s3-encryption}

GitLabは、[S3](https://aws.amazon.com/kms/) [バケット](https://aws.amazon.com/kms/)に[保存](https://docs.gitlab.com/administration/object_storage/#encrypted-s3-buckets)されているデータを[暗号化](https://aws.amazon.com/kms/)するために[Amazon KMS](https://aws.amazon.com/kms/)をサポートしています。これを有効にするには、次の2つの方法があります。

- AWSで、[デフォルト](https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html)の[暗号化](https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html)を使用するようにS3[バケット](https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html)を[設定](https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html)します。
- GitLabで、[サーバー側の暗号化](../../charts/globals.md#storage_options) [ヘッダー](../../charts/globals.md#storage_options)を有効にします。

これら2つのオプションは、相互に排他的ではありません。デフォルトの暗号化 ポリシーを設定できますが、サーバー側の暗号化 ヘッダーを有効にして、それらのデフォルトを上書きすることもできます。

詳細については、[暗号化](https://docs.gitlab.com/administration/object_storage/#encrypted-s3-buckets)されたS3[バケット](https://docs.gitlab.com/administration/object_storage/#encrypted-s3-buckets)に関するGitLab[ドキュメント](https://docs.gitlab.com/administration/object_storage/#encrypted-s3-buckets)

### appConfig設定 {#appconfig-configuration}

1. 使用するストレージ サービスを決定します。
1. 適切なファイルを`rails.yaml`にコピーします。
1. 環境に適した値で編集します。
1. [シークレット](../../charts/globals.md#connection)を作成するには、[接続](../../charts/globals.md#connection)の詳細[ドキュメント](../../charts/globals.md#connection)
1. ドキュメント化されているようにチャートを設定します。

## バックアップ {#backups}

バックアップもオブジェクトストレージに保存され、含まれているMinIOサービスではなく、外部を指すように設定する必要があります。バックアップ/復元手順では、2つの個別のバケットを使用します。

- バックアップを保存するためのバケット（`global.appConfig.backups.bucket`）
- 復元プロセス中に既存のデータを保持するための一時バケット（`global.appConfig.backups.tmpBucket`）

AWS S3互換のオブジェクトストレージシステム、Google Cloud Storage、およびAzure Blob Storageがサポートされているバックエンドです。`global.appConfig.backups.objectStorage.backend`をAWS S3の場合は`s3`、Google Cloud Storageの場合は`gcs`、Azure Blob Storageの場合は`azure`に設定して、バックエンドタイプを設定できます。`gitlab.toolbox.backups.objectStorage.config`キーを介して接続 設定も指定する必要があります。

シークレットでGoogle Cloud Storageを使用する場合、`global.appConfig.backups.objectStorage.config.gcpProject`値を使用してGCPプロジェクトを設定する必要があります。

S3互換ストレージの場合:

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.config.secret=storage-config
--set gitlab.toolbox.backups.objectStorage.config.key=config
```

シークレットを使用したGoogle Cloud Storage（GCS）の場合:

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.backend=gcs
--set gitlab.toolbox.backups.objectStorage.config.gcpProject=my-gcp-project-id
--set gitlab.toolbox.backups.objectStorage.config.secret=storage-config
--set gitlab.toolbox.backups.objectStorage.config.key=config
```

[GKE](gke-workload-identity.md)の[ワークロードアイデンティティフェデレーション](gke-workload-identity.md)を使用したGoogle Cloud Storage（GCS）の場合、[バックエンド](gke-workload-identity.md)と[バケット](gke-workload-identity.md)のみを設定する必要があります。`gitlab.toolbox.backups.objectStorage.config.secret`と`gitlab.toolbox.backups.objectStorage.config.key`が設定されていないことを確認して、クラスターが[GoogleのApplication Default Credentials](https://cloud.google.com/docs/authentication/application-default-credentials)を使用するようにします。

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.backend=gcs
```

Azure Blob Storageの場合:

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.backend=azure
--set gitlab.toolbox.backups.objectStorage.config.secret=storage-config
--set gitlab.toolbox.backups.objectStorage.config.key=config
```

詳細については、[バックアップ/復元オブジェクトストレージ](../../backup-restore/_index.md#object-storage)の[ドキュメント](../../backup-restore/_index.md#object-storage)

{{< alert type="note" >}}

他のオブジェクトストレージの場所からファイルをバックアップまたは復元するには、すべてのGitLabバケットへの読み取り/書き込みに十分な権限を持つユーザーとして認証するように設定ファイルを設定する必要があります。

{{< /alert >}}

### バックアップ ストレージの例 {#backups-storage-example}

1. `storage.config`ファイルを作成します。

   - Amazon S3では、コンテンツは[s3cmd設定ファイル形式](https://s3tools.org/kb/item14.htm)である必要があります

     ```ini
     [default]
     access_key = AWS_ACCESS_KEY
     secret_key = AWS_SECRET_KEY
     bucket_location = us-east-1
     multipart_chunk_size_mb = 128 # default is 15 (MB)
     ```

   - Google Cloud Storageでは、`storage.admin`ロールを持つサービスアカウントを作成し、[サービスアカウントキーを作成する](https://cloud.google.com/iam/docs/keys-create-delete#creating_service_account_keys)ことでファイルを作成できます。以下は、`gcloud` CLIを使用してファイルを作成する例です。

     ```shell
     export PROJECT_ID=$(gcloud config get-value project)
     gcloud iam service-accounts create gitlab-gcs --display-name "Gitlab Cloud Storage"
     gcloud projects add-iam-policy-binding --role roles/storage.admin ${PROJECT_ID} --member=serviceAccount:gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com
     gcloud iam service-accounts keys create --iam-account gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com storage.config
     ```

   - Azure Storageの場合

     ```ini
     [default]
     # Setup endpoint: hostname of the Web App
     host_base = https://your_minio_setup.azurewebsites.net
     host_bucket = https://your_minio_setup.azurewebsites.net
     # Leave as default
     bucket_location = us-west-1
     use_https = True
     multipart_chunk_size_mb = 128 # default is 15 (MB)

     # Setup access keys
     # Access Key = Azure Storage Account name
     access_key = AZURE_ACCOUNT_NAME
     # Secret Key = Azure Storage Account Key
     secret_key = AZURE_ACCOUNT_KEY

     # Use S3 v4 signature APIs
     signature_v2 = False
     ```

1. シークレットを作成します

   ```shell
   kubectl create secret generic storage-config --from-file=config=storage.config
   ```

## Google Cloud CDN {#google-cloud-cdn}

{{< history >}}

- GitLab 15.5で[導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98010)されました。

{{< /history >}}

[Google Cloud CDN](https://cloud.google.com/cdn)を使用して、[アーティファクト](https://cloud.google.com/cdn) [バケット](https://cloud.google.com/cdn)からデータを[キャッシュ](https://cloud.google.com/cdn)して[フェッチ](https://cloud.google.com/cdn)できます。これは、パフォーマンスを向上させ、ネットワーク構築 エグレスコストを削減するのに役立ちます。

Cloud CDNの設定は、次のキーを介して行われます。

- `global.appConfig.artifacts.cdn.secret`
- `global.appConfig.artifacts.cdn.key`（デフォルトは`cdn`）

Cloud CDNを使用するには:

1. [アーティファクト](https://cloud.google.com/cdn/docs/setting-up-cdn-with-bucket) [バケット](https://cloud.google.com/cdn/docs/setting-up-cdn-with-bucket)を[バックエンド](https://cloud.google.com/cdn/docs/setting-up-cdn-with-bucket)として使用するようにCloud [CDN](https://cloud.google.com/cdn/docs/setting-up-cdn-with-bucket)を設定
1. [署名](https://cloud.google.com/cdn/docs/using-signed-urls)付きURLのキーを作成
1. [バケット](https://cloud.google.com/cdn/docs/using-signed-urls#configuring_permissions)から読み取る[権限](https://cloud.google.com/cdn/docs/using-signed-urls#configuring_permissions)をCloud [CDN](https://cloud.google.com/cdn/docs/using-signed-urls#configuring_permissions) [サービスアカウント](https://cloud.google.com/cdn/docs/using-signed-urls#configuring_permissions)に付与
1. [`rails.googlecdn.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/cdn/rails.googlecdn.yaml)の例を使用して、パラメータを含む[YAML](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/cdn/rails.googlecdn.yaml)ファイルを用意します。次の情報を入力する必要があります。
   - `url`:手順1からのCDNホストのベースURL
   - `key_name`:手順2のキー名
   - `key`:手順2からの実際のシークレット
1. `cdn`キーの下に、このYAMLファイルをKubernetesのシークレットに読み込むします。たとえば、`gitlab-rails-cdn`というシークレットを作成するには:

   ```shell
   kubectl create secret generic gitlab-rails-cdn --from-file=cdn=rails.googlecdn.yml
   ```

1. `global.appConfig.artifacts.cdn.secret`を`gitlab-rails-cdn`に設定します。`helm`パラメータを介してこれを設定する場合は、次を使用します。

    ```shell
    --set global.appConfig.artifacts.cdn.secret=gitlab-rails-cdn
    ```

## トラブルシューティング {#troubleshooting}

### Azure Blob:URL \[FILTERED]がブロックされています:ローカルネットワークへのリクエストは許可されていません {#azure-blob-url-filtered-is-blocked-requests-to-the-local-network-are-not-allowed}

これは、Azure Blobホスト名が[RFC1918（ローカル/プライベート）IPアドレス](https://learn.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#dns-changes-for-private-endpoints)に[解決](https://learn.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#dns-changes-for-private-endpoints)された場合に発生します。回避策として、Azure Blobホスト名（`yourinstance.blob.core.windows.net`）の[送信](https://docs.gitlab.com/security/webhooks/#allowlist-for-local-requests)リクエスト
