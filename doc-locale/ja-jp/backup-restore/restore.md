---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabインスタンスの復元
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

LinuxパッケージやGitLab Helmチャートなどの他のインストール方法を使用した既存のGitLabインスタンスのバックアップtarballを取得するには、[ドキュメントに記載されている](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)手順に従ってください。

別のインスタンスから取得したバックアップを復元する場合は、バックアップを実行する前に、既存のインスタンスをオブジェクトストレージを使用するように移行する必要があります。[イシュー646](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/646)を参照してください。

バックアップは、作成されたGitLabの同じバージョンに復元することをお勧めします。

GitLabのバックアップの復元は、チャートで提供されているToolboxポッドで`backup-utility`コマンドを実行することで行われます。

初めて復元を実行する前に、[オブジェクトストレージ](_index.md)へのアクセスに対して[Toolboxが適切に設定されている](_index.md#object-storage)ことを確認する必要があります

GitLab Helmチャートで提供されるバックアップユーティリティは、次のいずれかの場所からのtarballの復元をサポートしています

1. インスタンスに関連付けられたオブジェクトストレージサービス内の`gitlab-backups`バケット。これはデフォルトのシナリオです。
1. ポッドからアクセスできるパブリックURL。
1. `kubectl cp`を使用してToolboxポッドにコピーできるローカルファイル

## シークレットの復元 {#restoring-the-secrets}

### railsシークレットの復元 {#restore-the-rails-secrets}

{{<alert type="note">}}

[GitLab Environment Toolkit (GET)](https://docs.gitlab.com/install/install_methods/#gitlab-environment-toolkit-get)を使用してデプロイされたハイブリッド環境は、復元を実行する際に考慮する必要がある、OmnibusノードとKubernetes間の自動シークレット同期を実行します。詳細については、GETドキュメントの[こちらのセクション](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_post_considerations.md#restores)を参照してください。

{{</alert>}}

GitLabチャートは、railsシークレットがYAMLコンテンツを含むKubernetes Secretとして提供されることを想定しています。Linuxパッケージインスタンスからrailsシークレットを復元する場合、シークレットは`/etc/gitlab/gitlab-secrets.json`ファイルにJSON形式で保存されます。ファイルを変換し、シークレットをYAML形式で作成するには:

1. ファイル`/etc/gitlab/gitlab-secrets.json`を、`kubectl`コマンドを実行するワークステーションにコピーします。

1. ワークステーションに[yq](https://github.com/mikefarah/yq)ツール（バージョン4.21.1以降）をインストールします。

1. 次のコマンドを実行して、`gitlab-secrets.json`をYAML形式に変換します:

   ```shell
   yq -P '{"production": .gitlab_rails}' gitlab-secrets.json -o yaml >> gitlab-secrets.yaml
   ```

1. 新しい`gitlab-secrets.yaml`ファイルに次の内容が含まれていることを確認してください:

   ```YAML
   production:
     db_key_base: <your key base value>
     secret_key_base: <your secret key base value>
     otp_key_base: <your otp key base value>
     openid_connect_signing_key: <your openid signing key>
     active_record_encryption_primary_key:
     - 'your active record encryption primary key'
     active_record_encryption_deterministic_key:
     - 'your active record encryption deterministic key'
     active_record_encryption_key_derivation_salt: 'your active record key derivation salt'
   ```

YAMLファイルからrailsシークレットを復元するには:

1. railsシークレットのオブジェクト名を検索します:

   ```shell
   kubectl get secrets | grep rails-secret
   ```

1. 既存のシークレットを削除します:

   ```shell
   kubectl delete secret <rails-secret-name>
   ```

1. 古いシークレットと同じ名前を使用して新しいシークレットを作成し、ローカルYAMLファイルを渡します

   ```shell
   kubectl create secret generic <rails-secret-name> --from-file=secrets.yml=gitlab-secrets.yaml
   ```

### ポッドの再起動 {#restart-the-pods}

新しいシークレットを使用するには、Webservice、Sidekiq、Toolboxの各ポッドを再起動する必要があります。これらのポッドを再起動する最も安全な方法は、次を実行することです:

```shell
kubectl delete pods -lapp=sidekiq,release=<helm release name>
kubectl delete pods -lapp=webservice,release=<helm release name>
kubectl delete pods -lapp=toolbox,release=<helm release name>
```

## バックアップファイルの復元 {#restoring-the-backup-file}

GitLabインスタンスを復元する手順は次のとおりです

1. チャートをデプロイして、実行中のGitLabインスタンスがあることを確認します。次のコマンドを実行して、Toolboxポッドが有効になっていて実行されていることを確認します

   ```shell
   kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
   ```

1. 上記のいずれかの場所でtarballを準備します。`<backup_ID>_gitlab_backup.tar`形式で名前が付けられていることを確認してください。[バックアップID](https://docs.gitlab.com/administration/backup_restore/backup_archive_process/#backup-id)についてお読みください。

1. 後で再起動するために、データベースクライアントの現在のレプリカ数に注意してください:

   ```shell
   kubectl get deploy -n <namespace> -lapp=sidekiq,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
   kubectl get deploy -n <namespace> -lapp=webservice,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
   kubectl get deploy -n <namespace> -lapp=prometheus,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
   ```

1. データベースのクライアントを停止して、ロックが復元プロセスを妨げないようにします:

   ```shell
   kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=0
   kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=0
   kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=0
   ```

1. バックアップユーティリティを実行してtarballを復元します

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility --restore -t <backup_ID>
   ```

   ここで、`<backup_ID>`は、`gitlab-backups`バケットに格納されているtarballの名前から取得されます。パブリックURLを提供する場合は、次のコマンドを使用します:

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility --restore -f <URL>
   ```

    形式が`file:///<path>`である限り、ローカルパスをURLとして指定できます

1. このプロセスには、tarballのサイズに応じて時間がかかります。
1. 復元プロセスでは、データベースの既存のコンテンツが消去され、既存のリポジトリが一時的な場所に移動され、tarballのコンテンツが抽出されます。リポジトリはディスク上の対応する場所に移動され、アーティファクト、アップロード、LFSなどの他のデータは、オブジェクトストレージ内の対応するバケットにアップロードされます。

1. アプリケーションを再起動します:

   ```shell
   kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=<value>
   kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=<value>
   kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=<value>
   ```

{{< alert type="note" >}}

復元中、バックアップtarballをディスクに展開する必要があります。これは、Toolboxポッドに必要なサイズのディスクを使用できる必要があることを意味します。詳細および設定については、[Toolboxドキュメント](../charts/gitlab/toolbox/_index.md#persistence-configuration)を参照してください。

{{< /alert >}}

### runner登録トークンの復元 {#restore-the-runner-registration-token}

復元後、正しい登録トークンがなくなったため、含まれているrunnerはインスタンスに登録できなくなります。更新するには、これらの[トラブルシューティングの手順](../troubleshooting/_index.md#included-gitlab-runner-failing-to-register)に従ってください。

## Kubernetes関連の設定の有効化 {#enable-kubernetes-related-settings}

復元されたバックアップがチャートの既存のインストールからのものではない場合、復元後にいくつかのKubernetes固有の機能を有効にする必要もあります。[インクリメンタルCIジョブログの生成](https://docs.gitlab.com/administration/cicd/job_logs/#incremental-logging-architecture)など。

1. 次のコマンドを実行して、Toolboxポッドを見つけます

   ```shell
   kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
   ```

1. インスタンス設定スクリプトを実行して、必要な機能を有効にします

   ```shell
   kubectl exec <Toolbox pod name> -it -- gitlab-rails runner -e production /scripts/custom-instance-setup
   ```

## ポッドの再起動 {#restart-the-pods-1}

新しい変更を使用するには、WebserviceとSidekiqのポッドを再起動する必要があります。これらのポッドを再起動する最も安全な方法は、次を実行することです:

```shell
kubectl delete pods -lapp=sidekiq,release=<helm release name>
kubectl delete pods -lapp=webservice,release=<helm release name>
```

## (オプション) rootユーザーのパスワードのリセット {#optional-reset-the-root-users-password}

復元プロセスでは、バックアップの値で`gitlab-initial-root-password`シークレットは更新されません。`root`としてログインするには、バックアップに含まれている元のパスワードを使用します。パスワードにアクセスできなくなった場合は、次の手順に従ってリセットしてください。

1. コマンドを実行してWebserviceポッドにアタッチします

   ```shell
   kubectl exec <Webservice pod name> -it -- bash
   ```

1. 次のコマンドを実行して、`root`ユーザーのパスワードをリセットします。`#{password}`を任意のパスワードに置き換えます

   ```shell
   /srv/gitlab/bin/rails runner "user = User.first; user.password='#{password}'; user.password_confirmation='#{password}'; user.save!"
   ```

## 追加情報 {#additional-information}

- [GitLabチャートのバックアップ/復元入門](_index.md)
- [GitLabインストールのバックアップ](backup.md)
