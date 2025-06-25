---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabインストールのバックアップ
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

GitLabのバックアップは、チャートで提供されているToolboxポッドで`backup-utility`コマンドを実行することで行われます。このチャートの[Cronベースのバックアップ](#cron-based-backup)機能を有効にすることで、バックアップを自動化することもできます。

初めてバックアップを実行する前に、[オブジェクトストレージ](_index.md#object-storage)にアクセスするために[Toolboxが適切に設定](../charts/gitlab/toolbox/_index.md#configuration)されていることを確認する必要があります。

GitLab Helmチャートベースのインストールをバックアップするには、次の手順に従います。

## バックアップを作成する {#create-the-backup}

1. 次のコマンドを実行して、Toolboxポッドが実行されていることを確認します

   ```shell
   kubectl get pods -lrelease=<release_name>,app=toolbox
   ```

   `<release_name>`をHelmリリース名（通常は`gitlab`）に置き換えます。

1. バックアップユーティリティを実行します

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility
   ```

1. オブジェクトストレージサービスの`gitlab-backups`バケットにアクセスし、tarボールが追加されていることを確認します。`<backup_ID>_gitlab_backup.tar`の形式で名前が付けられます。[バックアップID](https://docs.gitlab.com/administration/backup_restore/backup_archive_process/#backup-id)の詳細をお読みください。

1. このtarボールは、リストアに必要です。

## Cronベースのバックアップ {#cron-based-backup}

{{< alert type="note" >}}

Helm Chartによって作成されたKubernetes CronJobは、jobTemplateに`cluster-autoscaler.kubernetes.io/safe-to-evict: "false"`アノテーションを設定します。GKE Autopilotなどの一部のKubernetes環境では、このアノテーションの設定が許可されておらず、バックアップ用のジョブポッドは作成されません。このアノテーションは、`gitlab.toolbox.backups.cron.safeToEvict`パラメータを`true`に設定することで変更できます。これにより、ジョブの作成は許可されますが、削除されてバックアップが破損するリスクがあります。

{{< /alert >}}

このチャートでCronベースのバックアップを有効にして、[Kubernetesスケジュール](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#schedule)で定義されているように定期的に実行できます。

次のパラメータを設定する必要があります。

- `gitlab.toolbox.backups.cron.enabled`:Cronベースのバックアップを有効にするには、trueに設定します
- `gitlab.toolbox.backups.cron.schedule`:Kubernetesスケジュールのドキュメントに従って設定します
- `gitlab.toolbox.backups.cron.extraArgs`:[backup-utility](https://gitlab.com/gitlab-org/build/CNG/blob/master/gitlab-toolbox/scripts/bin/backup-utility)の追加の引数をオプションで設定します（`--skip db`や`--s3tool awscli`など）。

## バックアップユーティリティの追加引数 {#backup-utility-extra-arguments}

バックアップユーティリティは、いくつかの追加の引数を受け取ることができます。

### コンポーネントのスキップ {#skipping-components}

`--skip`引数を使用して、コンポーネントをスキップします。有効なコンポーネント名は、[バックアップから特定のデータを除外する](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#excluding-specific-data-from-the-backup)にあります。

各コンポーネントには、独自の`--skip`引数が必要です。次に例を示します。

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --skip db --skip lfs
```

### バックアップのみをクリーンアップする {#cleanup-backups-only}

新しいバックアップを作成せずに、バックアップのクリーンアップを実行します。

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --cleanup
```

### 使用するS3ツールを指定する {#specify-s3-tool-to-use}

`backup-utility`コマンドは、デフォルトで`s3cmd`を使用してオブジェクトストレージに接続します。`s3cmd`が他のS3ツールよりも信頼性が低い場合に、この追加の引数をオーバーライドすることがあります。

GitLabがS3バケットをCIジョブアーティファクトストレージとして使用し、デフォルトの`s3cmd` CLIツールが使用されている場合、バックアップジョブが`ERROR: S3 error: 404 (NoSuchKey): The specified key does not exist.`でクラッシュする[既知の問題](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3338)があります。`s3cmd`から`awscli`に切り替えることで、バックアップジョブを正常に実行できます。詳細については、[issue 3338](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3338)を参照してください。

使用するS3 CLIツールは、`s3cmd`または`awscli`のいずれかです。

 ```shell
 kubectl exec <Toolbox pod name> -it -- backup-utility --s3tool awscli
 ```

#### awscliでのMinIOの使用 {#using-minio-with-awscli}

`awscli`を使用するときにMinIOをオブジェクトストレージとして使用するには、次のパラメータを設定します。

```yaml
gitlab:
  toolbox:
    extraEnvFrom:
      AWS_ACCESS_KEY_ID:
        secretKeyRef:
          name: <MINIO-SECRET-NAME>
          key: accesskey
      AWS_SECRET_ACCESS_KEY:
        secretKeyRef:
          name: <MINIO-SECRET-NAME>
          key: secretkey
    extraEnv:
      AWS_DEFAULT_REGION: us-east-1 # MinIO default
    backups:
      cron:
        enabled: true
        schedule: "@daily"
        extraArgs: "--s3tool awscli --aws-s3-endpoint-url <MINIO-INGRESS-URL>"
```

{{< alert type="note" >}}

S3 CLIツール`s5cmd`のサポートは調査中です。進捗状況を追跡するには、[issue 523](https://gitlab.com/gitlab-org/build/CNG/-/issues/523)を参照してください。

{{< /alert >}}

#### `awscli`によるデータ整合性保護 {#data-integrity-protection-with-awscli}

Toolboxに含まれる最新バージョンの`awscli`ツールは、デフォルトでデータ整合性保護を適用します。オブジェクトストレージサービスがこの機能をサポートしていない場合、この要件は次のように無効にできます。

```yaml
extraEnv:
  AWS_REQUEST_CHECKSUM_CALCULATION: WHEN_REQUIRED
```

設定は、Toolboxポッド`extraEnv`またはグローバル`extraEnv`のいずれかになります。

### サーバーサイドリポジトリのバックアップ {#server-side-repository-backups}

{{< history >}}

- GitLab 17.0で[導入](https://gitlab.com/gitlab-org/gitlab/-/issues/438393)。

{{< /history >}}

バックアップアーカイブに大きなリポジトリバックアップを格納する代わりに、各リポジトリをホストするGitalyノードがバックアップの作成とそのオブジェクトストレージへのストリーミングを担当するように、リポジトリバックアップを設定できます。これにより、バックアップの作成とリストアに必要なネットワークリソースを削減できます。

[サーバーサイドリポジトリバックアップの作成](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#create-server-side-repository-backups)を参照してください。

### その他の引数 {#other-arguments}

利用可能な引数の完全なリストを表示するには、次のコマンドを実行します。

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --help
```

## シークレットのバックアップ {#back-up-the-secrets}

セキュリティ上の予防措置として、レールシークレットのコピーを保存する必要もあります。これらはバックアップには含まれていません。データベースを含む完全なバックアップを、シークレットのコピーとは別に保管することをお勧めします。

1. レールシークレットのオブジェクト名を見つけます

   ```shell
   kubectl get secrets | grep rails-secret
   ```

1. レールシークレットのコピーを保存します

   ```shell
   kubectl get secrets <rails-secret-name> -o jsonpath="{.data['secrets\.yml']}" | base64 --decode > gitlab-secrets.yaml
   ```

1. `gitlab-secrets.yaml`を安全な場所に保管してください。バックアップを復元するには、これが必要です。

## 追加情報 {#additional-information}

- [GitLabチャートのバックアップ/リストアの概要](_index.md)
- [GitLabインストールの復元](restore.md)
