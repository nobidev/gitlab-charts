---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: バンドルされているPostgreSQLバージョンをアップグレードする
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

{{< alert type="note" >}}

これらの手順は、バンドルされたPostgreSQLチャート(`postgresql.install`がfalseではない)を使用している場合の手順であり、外部PostgreSQLセットアップの場合の手順ではありません。

{{< /alert >}}

{{< alert type="warning" >}}

バンドルされたbitnami PostgreSQLチャートは、本番環境に対応していません。本番環境に対応したGitLabチャートのデプロイメントには、外部データベースを使用してください。

{{< /alert >}}

バンドルされたPostgreSQLチャートを使用してPostgreSQLの新しいメジャーバージョンに変更するには、既存のデータベースのバックアップを作成し、新しいデータベースに復元します。

{{< alert type="note" >}}

このチャートの`9.0.0`リリースの過程で、`14.8.0`から`16.6.0`にデフォルトのPostgreSQLバージョンをアップグレードしました。これは、[PostgreSQLチャート](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)バージョンを`12.5.2`から`13.4.4`にアップグレードすることで行われます。

{{< /alert >}}

これは、ドロップインリプレースメントではありません。データベースをアップグレードするには、手動による手順を実行する必要があります。手順は[アップグレード手順](#steps-for-upgrading-the-bundled-postgresql)に記載されています。

## バンドルされたPostgreSQLをアップグレードする手順 {#steps-for-upgrading-the-bundled-postgresql}

これは、アップストリームのPostgreSQLチャートの[イシュー](https://github.com/bitnami/charts/issues/16707)が原因です。PostgreSQLのパスワードに環境変数を使用せず、ファイルの使用を希望する場合は、次の手順を実行する前に、手動で[既存のPostgreSQLパスワードシークレットを編集](#edit-the-existing-postgresql-passwords-secret)し、PostgreSQLチャートのパスワードファイルを有効にする必要があります。

### 既存のデータベースを準備する {#prepare-the-existing-database}

以下の点に注意してください。

- バンドルされたPostgreSQLチャート(`postgresql.install`がfalse)を使用していない場合は、これらの手順に従う必要はありません。
- 複数のチャートが同じネームスペースにインストールされている場合。Helmリリースの名前をデータベースアップグレードスクリプトに渡す必要がある場合があります。後で提供されるコマンド例で、`bash -s STAGE`を`bash -s -- -r RELEASE STAGE`に置き換えます。
- チャートを`kubectl`コンテキストのデフォルト以外のネームスペースにインストールした場合は、ネームスペースをデータベースアップグレードスクリプトに渡す必要があります。後で提供されるコマンド例で、`bash -s STAGE`を`bash -s -- -n NAMESPACE STAGE`に置き換えます。このオプションは、`-r RELEASE`とともに使用できます。`kubectl config set-context --current --namespace=NAMESPACE`を実行するか、kubectxの[`kubens`](https://github.com/ahmetb/kubectx)を使用して、コンテキストのデフォルトのネームスペースを設定できます。

`pre`ステージでは、Toolboxのbackup-utilityスクリプトを使用してデータベースのバックアップが作成され、設定済みのS3バケット (デフォルトではMinIO) に保存されます。

```shell
# GITLAB_RELEASE should be the version of the chart you are installing, starting with 'v': v6.0.0
curl -s "https://gitlab.com/gitlab-org/charts/gitlab/-/raw/${GITLAB_RELEASE}/scripts/database-upgrade" | bash -s pre
```

### 既存のPostgreSQLデータを削除する {#delete-existing-postgresql-data}

{{< alert type="note" >}}

PostgreSQLのデータ形式が変更されたため、アップグレードするには、リリースをアップグレードする前に、既存のPostgreSQL StatefulSetを削除する必要があります。StatefulSetは次の手順で再作成されます。

{{< /alert >}}

{{< alert type="warning" >}}

前の手順でデータベースのバックアップを作成したことを確認してください。バックアップがないと、GitLabデータが失われます。

{{< /alert >}}

```shell
kubectl delete statefulset RELEASE-NAME-postgresql
kubectl delete pvc data-RELEASE_NAME-postgresql-0
```

### GitLabをアップグレードする {#upgrade-gitlab}

[標準的な手順](upgrade.md#steps)に従ってGitLabをアップグレードしてください。追加事項は以下のとおりです。

アップグレードコマンドで次のフラグを使用して、移行を無効にします。

1. `--set gitlab.migrations.enabled=false`

バンドルされたPostgreSQLについては、後の手順でデータベースの移行を実行します。

### データベースを復元する {#restore-the-database}

以下の点に注意してください。

- bash連想配列を使用する必要があるため、スクリプトを正常に実行するには、Bash 4.0以降を使用する必要があります。

1. Toolboxポッドのアップグレードが完了するまで待ちます。RELEASE_NAMEは、`helm list`のGitLabリリースの名前である必要があります

   ```shell
   kubectl rollout status -w deployment/RELEASE_NAME-toolbox
   ```

1. Toolboxポッドが正常にデプロイされたら、`post`ステップを実行します。

   ```shell
   # GITLAB_RELEASE should be the version of the chart you are installing, starting with 'v': v6.0.0
   curl -s "https://gitlab.com/gitlab-org/charts/gitlab/-/raw/${GITLAB_RELEASE}/scripts/database-upgrade" | bash -s post
   ```

   この手順では、次のことを行います。

   1. `webservice`、`sidekiq`、および`gitlab-exporter`デプロイメントのレプリカを0に設定します。これにより、バックアップの復元中に他のアプリケーションがデータベースを変更できなくなります。
   1. プレステージで作成されたバックアップからデータベースを復元します。
   1. 新しいバージョンのデータベース移行を実行します。
   1. 最初の手順からデプロイメントを再開します。

### データベースのアップグレードプロセスのトラブルシューティング {#troubleshooting-database-upgrade-process}

- アップグレード中にエラーが発生した場合は、詳細について`gitlab-upgrade-check`ポッドの説明を確認すると役立つ場合があります。

  ```shell
  kubectl get pods -lrelease=RELEASE,app=gitlab
  kubectl describe pod <gitlab-upgrade-check-pod-full-name>
  ```

## 既存のPostgreSQLパスワードシークレットを編集する {#edit-the-existing-postgresql-passwords-secret}

{{< alert type="note" >}}

これは、`7.0.0`のアップグレードのみを対象とし、PostgreSQLサービスコンテナ内でパスワードファイルの使用を強制する場合のみを対象としています。

{{< /alert >}}

[PostgreSQLチャート](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)の新しいバージョンでは、シークレット内のパスワードを参照するために異なるキーが使用されます。`postgresql-password`および`postgresql-postgres-password`の代わりに、`password`および`postgres-password`が使用されるようになりました。これらのキーは、値を変更せずに`RELEASE-postgresql-password`シークレットで変更_する_必要があります。

このシークレットは、最初にGitLabチャートによって生成され、アップグレード中またはアップグレード後には変更されません。したがって、シークレットを編集してキーを変更する必要があります。

シークレットを編集したら、Helmアップグレードの値で_必ず`postgresql.auth.usePasswordFiles`を`true`に設定**してください。デフォルトは`false`です。

次のスクリプトは、シークレットのパッチ適用に役立ちます。

1. 最初に、既存のシークレットのバックアップを作成します。次のコマンドは、`-backup`という名前のサフィックスが付いた新しいシークレットにコピーします。

   ```shell
   kubectl get secrets ${RELEASE}-postgresql-password -o yaml | sed 's/name: \(.*\)$/name: \1-backup/' | kubectl apply -f -
   ```

1. パッチが正しく表示されることを確認します。

   ```shell
   kubectl get secret ${RELEASE}-postgresql-password \
     -o go-template='{"data":{"password":"{{index .data "postgresql-password"}}","postgres-password":"{{index .data "postgresql-postgres-password"}}","postgresql-password":null,"postgresql-postgres-password":null}}'
   ```

1. 次に、適用します。

   ```shell
   kubectl patch secret ${RELEASE}-postgresql-password --patch "$(
     kubectl get secret ${RELEASE}-postgresql-password \
       -o go-template='{"data":{"password":"{{index .data "postgresql-password"}}","postgres-password":"{{index .data "postgresql-postgres-password"}}","postgresql-password":null,"postgresql-postgres-password":null}}')"
   ```
