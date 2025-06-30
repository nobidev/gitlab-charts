---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabインスタンスのバックアップとリストア
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

GitLab Helmチャートは、GitLabインスタンスのバックアップとリストアを目的としたインターフェースとして機能するToolboxサブチャートからユーティリティポッドを提供します。このタスクに必要な他のポッドとやり取りする`backup-utility`実行可能ファイルが搭載されています。ユーティリティの動作方法に関する技術的な詳細は、[アーキテクチャドキュメント](../architecture/backup-restore.md)に記載されています。

## 前提要件 {#prerequisites}

- ここに記載されているバックアップとリストアの手順は、S3互換のAPIでのみテストされています。Google Cloud Storageなどの他のオブジェクトストレージサービスのサポートは、将来の改訂でテストされる予定です。

- リストア中、バックアップtarボールをディスクに抽出する必要があります。つまり、Toolboxポッドには[必要なサイズのディスク](../charts/gitlab/toolbox/_index.md#restore-considerations)が必要です。

- このチャートは、`artifacts`、`uploads`、`packages`、`registry`、`lfs`オブジェクトに[オブジェクトストレージ](#object-storage)を使用しており、リストア中にこれらを移行することはありません。別のインスタンスから取得したバックアップをリストアする場合は、バックアップを実行する前に、既存のインスタンスをオブジェクトストレージを使用するように移行する必要があります。[イシュー646](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/646)を参照してください。

## バックアップとリストアの手順 {#backup-and-restoring-procedures}

- [GitLabインストールのバックアップ](backup.md)
- [GitLabインストールのリストア](restore.md)

## オブジェクトストレージ {#object-storage}

[外部オブジェクトストレージ](../advanced/external-object-storage/_index.md)が指定されていない限り、このチャートを使用すると、MinIOインスタンスがすぐに使用できるようになります。特定の設定が指定されていない限り、Toolboxはデフォルトで含まれているMinIOに接続します。Toolboxは、Amazon S3またはGoogle Cloud Storage（GCS）にバックアップするように構成することもできます。

### S3へのバックアップ {#backups-to-s3}

[別のS3ツールを使用するように指定](../backup-restore/backup.md#specify-s3-tool-to-use)しない限り、Toolboxはデフォルトで`s3cmd`を使用してオブジェクトストレージに接続します。外部オブジェクトストレージへの接続を構成するには、`gitlab.toolbox.backups.objectStorage.config.secret`を指定する必要があります。これは、`.s3cfg`ファイルを含むKubernetesシークレットを指します。`config`のデフォルトと異なる場合は、`gitlab.toolbox.backups.objectStorage.config.key`を指定する必要があります。これは、`.s3cfg`ファイルの内容を含むキーを指します。

次のように表示されます。

```shell
helm install gitlab gitlab/gitlab \
  --set gitlab.toolbox.backups.objectStorage.config.secret=my-s3cfg \
  --set gitlab.toolbox.backups.objectStorage.config.key=config .
```

s3cmd `.s3cfg`ファイルのドキュメントは[こちら](https://s3tools.org/kb/item14.htm)にあります

さらに、2つのバケットの場所を構成する必要があります。1つはバックアップを保存するため、もう1つはバックアップのリストア時に使用される一時バケットです。

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
```

### Google Cloud Storage (GCS) へのバックアップ {#backups-to-google-cloud-storage-gcs}

GCSにバックアップするには、まず`gitlab.toolbox.backups.objectStorage.backend`を`gcs`に設定する必要があります。これにより、Toolboxはオブジェクトの保存と取得時に`gsutil` CLIを使用するようになります。

さらに、2つのバケットの場所を構成する必要があります。1つはバックアップを保存するため、もう1つはバックアップのリストア時に使用される一時バケットです。

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
```

バックアップユーティリティは、これらのバケットへのアクセスを必要とします。アクセスを許可する方法は2つあります。

- Kubernetesシークレットで認証情報を指定します。
- [GKEのワークロードアイデンティティフェデレーション](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity)の設定。

#### GCS認証情報 {#gcs-credentials}

まず、`gitlab.toolbox.backups.objectStorage.config.gcpProject`を、ストレージバケットを含むGCPプロジェクトのプロジェクトIDに設定します。

サービスアカウントにバックアップに使用するバケットの`storage.admin`ロールがあるアクティブなサービスアカウントJSONキーの内容を含むKubernetesシークレットを作成する必要があります。以下は、`gcloud`と`kubectl`を使用してシークレットを作成する例です。

```shell
export PROJECT_ID=$(gcloud config get-value project)
gcloud iam service-accounts create gitlab-gcs --display-name "Gitlab Cloud Storage"
gcloud projects add-iam-policy-binding --role roles/storage.admin ${PROJECT_ID} --member=serviceAccount:gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts keys create --iam-account gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com storage.config
kubectl create secret generic storage-config --from-file=config=storage.config
```

サービスアカウントキーを使用してバックアップのためにGCSに対して認証するには、次のようにHelmチャートを構成します。

```shell
helm install gitlab gitlab/gitlab \
  --set gitlab.toolbox.backups.objectStorage.config.secret=storage-config \
  --set gitlab.toolbox.backups.objectStorage.config.key=config \
  --set gitlab.toolbox.backups.objectStorage.config.gcpProject=my-gcp-project-id \
  --set gitlab.toolbox.backups.objectStorage.backend=gcs
```

#### GKEのワークロードアイデンティティフェデレーションの設定 {#configuring-workload-identity-federation-for-gke}

[GitLabチャートを使用したGKEのワークロードアイデンティティフェデレーションに関するドキュメント](../advanced/external-object-storage/gke-workload-identity.md)を参照してください。

Kubernetes ServiceAccountを参照するIAM許可ポリシーを作成する場合は、`roles/storage.objectAdmin`ロールを付与します。

バックアップの場合、`gitlab.toolbox.backups.objectStorage.config.secret`、`gitlab.toolbox.backups.objectStorage.config.key`、および`gitlab.toolbox.backups.objectStorage.config.gcpProject`が設定されていないことを確認して、Googleのアプリケーションのデフォルト認証情報が使用されるようにします。

### Azure blobストレージへのバックアップ {#backups-to-azure-blob-storage}

`gitlab.toolbox.backups.objectStorage.backend`を`azure`に設定することで、Azure blobストレージをバックアップの保存に使用できます。これにより、Toolboxは含まれている`azcopy`のコピーを使用して、バックアップファイルをAzure blobストレージに送信および取得できます。

Azure blobストレージを使用するには、既存のリソースグループにストレージアカウントを作成する必要があります。ストレージアカウントの名前、アクセスキー、およびblobホストを使用して設定シークレットを作成します。

パラメータを含む設定ファイルを作成します。

```yaml
# azure-backup-conf.yaml
azure_storage_account_name: <storage account>
azure_storage_access_key: <access key value>
azure_storage_domain: blob.core.windows.net # optional
```

次の`kubectl`コマンドを使用して、Kubernetesシークレットを作成できます。

```shell
kubectl create secret generic backup-azure-creds \
  --from-file=config=azure-backup-conf.yaml
```

シークレットが作成されると、デプロイされた値にバックアップ設定を追加するか、Helmコマンドラインで設定を提供することにより、GitLab Helmチャートを構成できます。次に例を示します。

```shell
helm install gitlab gitlab/gitlab \
  --set gitlab.toolbox.backups.objectStorage.config.secret=backup-azure-creds \
  --set gitlab.toolbox.backups.objectStorage.config.key=config \
  --set gitlab.toolbox.backups.objectStorage.backend=azure
```

シークレットからのアクセスキーは、ストレージアカウントにアクセスするためにより短寿命の共有アクセス署名（SAS）トークンを生成および更新するために使用されます。

さらに、2つのバケット/コンテナを事前に作成する必要があります。1つはバックアップを保存するため、もう1つはバックアップのリストア時に使用される一時バケットです。バケット名を値または設定に追加します。次に例を示します。

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
```

## トラブルシューティング {#troubleshooting}

### ポッドの削除に関するイシュー {#pod-eviction-issues}

バックアップはオブジェクトストレージターゲットの外部でローカルに組み立てられるため、一時的なディスク容量が必要です。必要な領域は、実際のバックアップアーカイブのサイズを超える可能性があります。デフォルト設定では、Toolboxポッドのファイルシステムを使用して一時データを保存します。リソース不足が原因でポッドが削除されている場合は、一時データを保持するために永続ボリュームをポッドに接続する必要があります。GKEで、次の設定をHelmコマンドに追加します。

```shell
--set gitlab.toolbox.persistence.enabled=true
```

バックアップが付属のバックアップcronジョブの一部として実行されている場合は、cronジョブの永続性を有効にすることをお勧めします。

```shell
--set gitlab.toolbox.backups.cron.persistence.enabled=true
```

他のプロバイダーの場合は、永続ボリュームを作成する必要があるかもしれません。これを行う方法の例については、[ストレージに関するドキュメント](../installation/storage.md)を参照してください。

### 「バケットが見つかりません」エラー {#bucket-not-found-errors}

バックアップ中に`Bucket not found`エラーが表示される場合は、バケットに対して認証情報が構成されていることを確認してください。

コマンドはクラウドサービスプロバイダーによって異なります。

- AWS S3の場合、認証情報はツールボックスポッドの`~/.s3cfg`に保存されます。実行:

  ```shell
  s3cmd ls
  ```

- GCP GCSの場合は、次を実行します。

  ```shell
  gsutil ls
  ```

利用可能なバケットのリストが表示されます。

### 「AccessDeniedException: GCPの403」エラー {#accessdeniedexception-403-errors-in-gcp}

`[Error] AccessDeniedException: 403 <GCP Account> does not have storage.objects.list access to the Google Cloud Storage bucket.`のようなエラーは、権限がないために、GitLabインスタンスのバックアップまたはリストア中に通常発生します。

バックアップおよびリストアオペレーションは環境内のすべてのバケットを使用するため、環境内のすべてのバケットが作成されていること、およびGCPアカウントがすべてのバケットにアクセス（リスト、読み取り、および書き込み）できることを確認してください。

1. ツールボックスポッドを見つけます。

   ```shell
   kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
   ```

1. ポッドの環境内のすべてのバケットを取得します。`<toolbox-pod-name>`を実際のツールボックスポッド名に置き換えますが、`"BUCKET_NAME"`はそのままにします。

   ```shell
   kubectl describe pod <toolbox-pod-name> | grep "BUCKET_NAME"
   ```

1. 環境内のすべてのバケットへのアクセス権があることを確認します。

   ```shell
   # List
   gsutil ls gs://<bucket-to-validate>/

   # Read
   gsutil cp gs://<bucket-to-validate>/<object-to-get> <save-to-location>

   # Write
   gsutil cp -n <local-file> gs://<bucket-to-validate>/
   ```

### 「エラー：`/home/git/.s3cfg`:`--backend s3`で`backup-utility`を実行した場合のNone」エラー {#error-homegits3cfg-none-error-when-running-backup-utility-with---backend-s3}

このエラーは、`.s3cfg`ファイルを含むKubernetesシークレットが`gitlab.toolbox.backups.objectStorage.config.secret`値を介して指定されていない場合に発生します。

この問題を解決するには、[S3へのバックアップ](_index.md#backups-to-s3)の手順に従ってください。

### 「PermissionError: S3を使用したファイル書き込み不可」エラー {#permissionerror-file-not-writable-errors-using-s3}

ツールボックスユーザーがバケットアイテムの保存されている権限と一致するファイルを書き込む権限を持っていない場合、`[Error] WARNING: <file> not writable: Operation not permitted`のようなエラーが発生します。

これを防ぐには、`gitlab.toolbox.backups.objectStorage.config.secret`を介して参照される`.s3cfg`ファイルに次のフラグを追加して、ファイル所有者、モード、およびタイムスタンプを保持しないように`s3cmd`を構成します。

```toml
preserve_attrs = False
```

### リストア時にスキップされたリポジトリ {#repositories-skipped-on-restore}

GitLab 16.6/Chart 7.6以降では、バックアップアーカイブの名前が変更された場合、リストア時にリポジトリがスキップされることがあります。これを回避するには、バックアップアーカイブの名前を変更せず、バックアップを元の名前（`{backup_id}_gitlab_backup.tar`）に変更します。

元のバックアップIDは、リポジトリバックアップディレクトリ構造から抽出できます：`repositories/@hashed/*/*/*/{backup_id}/LATEST`
