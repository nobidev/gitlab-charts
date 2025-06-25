---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートをアップグレードする
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

GitLabインストールをアップグレードする前に、アップグレード先の特定[リリース](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/CHANGELOG.md)に対応する[変更履歴](version_mappings.md#release-notes-for-each-supported-version)を確認し、新しいGitLabチャートバージョンに関連する可能性のある[リリースノート](version_mappings.md#release-notes-for-each-supported-version)を探す必要があります。

アップグレードは、サポートされている[アップグレードパス](https://docs.gitlab.com/update/#upgrade-paths)に従う必要があります。GitLabチャートのバージョン番号はGitLabのバージョン番号と同じではないため、両者間の[バージョンマッピング](version_mappings.md)を参照してください。

{{< alert type="note" >}}

**ゼロ・ダウンタイム・アップグレード**はGitLabチャートでは利用できませんが、[GitLab Operator](https://docs.gitlab.com/operator/gitlab_upgrades/)を使用することで実現できます。

{{< /alert >}}

最初に[バックアップ](../backup-restore/_index.md)を取ることをお勧めします。また、現在の値の一部は非推奨になっている可能性があるため、`helm upgrade --set key=value`構文または`-f values.yaml`を使用してすべての値を指定する必要があります。`--reuse-values`を使用しないでください。

以前の`--set`引数は、`helm get values <release name>`で適切に取得できます。これをファイル(`helm get values <release name> > gitlab.yaml`)にリダイレクトすると、`-f`経由でこのファイルを安全に渡すことができます。したがって、`helm upgrade gitlab gitlab/gitlab -f gitlab.yaml`。これにより、`--reuse-values`の動作が安全に置き換えられます

## 手順 {#steps}

{{< alert type="note" >}}

チャートの`7.0`バージョンにアップグレードする場合は、[7.0の手動アップグレード手順](#upgrade-to-version-70)に従ってください。チャートの`6.0`バージョンにアップグレードする場合は、[6.0の手動アップグレード手順](#upgrade-to-version-60)に従ってください。以前のバージョンのチャートにアップグレードする場合は、[以前のバージョンのアップグレード手順](#older-upgrade-instructions)に従ってください。

{{< /alert >}}

アップグレードする前に、設定した値を振り返り、設定を「過剰に構成」していないか確認してください。変更された値の小さなリストを保持し、ほとんどのチャートのデフォルトを活用することを想定しています。以下に示す方法で、多数の設定を明示的に設定した場合:

- 計算された設定をコピーする
- すべての設定をコピーし、実際にはデフォルト値と同じ値を明示的に定義する

構成構造がバージョン間で変更されている可能性があり、設定の適用に問題が発生するため、アップグレード中に問題が発生する可能性が非常に高くなります。これを確認する方法については、次の手順で説明します。

GitLabを新しいバージョンにアップグレードする手順は、次のとおりです。

1. アップグレード先の特定のバージョンの[変更履歴](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/CHANGELOG.md)を確認します。
1. [デプロイメントドキュメント](deployment.md)を手順ごとに確認してください。
1. 以前に指定した値を取得します:

   ```shell
   helm get values gitlab > gitlab.yaml
   ```

1. アップグレード時に引き継ぐ必要のあるすべての値を決定します。GitLabには適切なデフォルト値があり、アップグレード中に上記のコマンドからすべての値を渡すことができますが、チャートのバージョン間で構成が変更され、適切にマップされないシナリオが発生する可能性があります。明示的に設定する値の最小限のセットを保持し、アップグレードプロセス中にそれらを渡すことをお勧めします。
1. 前の手順で抽出した値を使用して、アップグレードを実行します:

   ```shell
   helm upgrade gitlab gitlab/gitlab \
     --version <new version> \
     -f gitlab.yaml \
     --set gitlab.migrations.enabled=true \
     --set ...
   ```

メジャーデータベースのアップグレード中に、`gitlab.migrations.enabled`を`false`に設定するように求められます。今後のアップデートのために、明示的に`true`に戻してください。

## バンドルされたPostgreSQLチャートをアップグレードする {#upgrade-the-bundled-postgresql-chart}

{{< alert type="note" >}}

バンドルされたPostgreSQLチャート(`postgresql.install`がfalse)を使用していない場合は、この手順を実行する必要はありません。

{{< /alert >}}

### バンドルされたPostgreSQLをバージョン13にアップグレードする {#upgrade-the-bundled-postgresql-to-version-13}

PostgreSQL 13は、GitLab 14.1以降でサポートされています。[PostgreSQL 13には、大幅なパフォーマンスの改善](https://www.postgresql.org/about/news/postgresql-13-released-2077/)がもたらされています。

バンドルされたPostgreSQLをバージョン13にアップグレードするには、次の手順が必要です。

1. [既存のデータベースを準備](database_upgrade.md#prepare-the-existing-database)します。
1. [既存のPostgreSQLデータを削除](database_upgrade.md#delete-existing-postgresql-data)します。
1. `postgresql.image.tag`の値を`13.6.0`に更新し、[チャートを再インストール](database_upgrade.md#upgrade-gitlab)して、新しいPostgreSQL 13データベースを作成します。
1. [データベースを復元](database_upgrade.md#restore-the-database)します。

## バージョン7.0にアップグレードする {#upgrade-to-version-70}

{{< alert type="warning" >}}

チャートの`6.x`バージョンから最新の`7.0`リリースにアップグレードする場合は、まず、アップグレードが機能するように、最新の`6.11.x`パッチリリースに更新する必要があります。[7.0リリースノート](../releases/7_0.md)には、サポートされているアップグレードパスが記載されています。

{{< /alert >}}

`7.0.x`リリースでは、アップグレードを実行するために手動による手順が必要になる場合があります。

- クラスター内Redisサービスを提供するために、バンドルされた[`bitnami/Redis`](https://artifacthub.io/packages/helm/bitnami/redis)サブチャートを使用している場合、GitLabチャートのバージョン7.0にアップグレードする前に、RedisのStatefulSetを手動で削除する必要があります。以下の[バンドルされたRedisサブチャートのアップグレード](#update-the-bundled-redis-sub-chart)の設定に従ってください。

### バンドルされたRedisサブチャートをアップデートする {#update-the-bundled-redis-sub-chart}

GitLabチャートのリリース7.0では、バンドルされた[`bitnami/Redis`](https://artifacthub.io/packages/helm/bitnami/redis)サブチャートが、以前にインストールされた`11.3.4`から`16.13.2`バージョンに更新されます。サブチャートの`redis-master` StatefulSetに適用される`matchLabels`の変更により、StatefulSetを手動で削除せずにアップグレードすると、次のエラーが発生します:

```shell
Error: UPGRADE FAILED: cannot patch "gitlab-redis-master" with kind StatefulSet: StatefulSet.apps "gitlab-redis-master" is invalid: spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', 'updateStrategy' and 'minReadySeconds' are forbidden
```

`RELEASE-redis-master`のStatefulSetを削除するには:

1. `webservice`、`sidekiq`、`kas`、および`gitlab-exporter`デプロイメントの場合、レプリカを`0`にスケールダウンします:

   ```shell
   kubectl scale deployment --replicas 0 --selector 'app in (webservice, sidekiq, kas, gitlab-exporter)' --namespace <namespace>
   ```

1. `RELEASE-redis-master` StatefulSetを削除します:

   ```shell
   kubectl delete statefulset RELEASE-redis-master --namespace <namespace>
   ```

   - `<namespace>`は、GitLabチャートをインストールしたネームスペースに置き換える必要があります。

次に、[標準のアップグレード手順](#steps)に従います。Helmが変更をマージする方法により、最初の手順でスケールダウンしたデプロイメントを手動でスケールアップする必要がある場合があります。

### `global.redis.password`の使用 {#use-of-globalredispassword}

`global.redis.password`の使用による構成タイプの競合を緩和するために、`global.redis.password`の使用を非推奨とし、`global.redis.auth`を推奨することにしました。

非推奨通知の表示に加えて、`helm upgrade`から次の警告メッセージが表示された場合:

```plaintext
coalesce.go:199: warning: destination for password is a table. Ignoring non-table value
```

これは、`global.redis.password`を値ファイルに設定していることを示しています。

### Ingressの`useNewIngressForCerts` {#usenewingressforcerts-on-ingresses}

既存のチャートを`7.x`から 以降のバージョンにアップグレードし、`global.ingress.useNewIngressForCerts`を`true`に変更する場合は、既存のcert-manager `Certificate`オブジェクトを更新して、`acme.cert-manager.io/http01-override-ingress-name`アノテーションを削除する必要もあります。

この属性が`false` (デフォルト) に設定されている場合、この変更を行う必要があります。このアノテーションはデフォルトで証明書に追加され、cert-managerはそれを使用して、その証明書に使用するIngressメソッドを識別します。この属性を`false`に変更しただけでは、アノテーションは自動的に削除されません。手動によるアクションが必要です。そうしないと、cert-managerは、既存のIngressの古い動作を使用し続けます。

## バージョン6.0にアップグレードする {#upgrade-to-version-60}

{{< alert type="warning" >}}

チャートの`5.x`バージョンから最新の`6.0`リリースにアップグレードする場合は、まず、アップグレードが機能するように、最新の`5.10.x`パッチリリースに更新する必要があります。[6.0リリースノート](../releases/6_0.md)には、サポートされているアップグレードパスが記載されています。

{{< /alert >}}

`6.0`リリースにアップグレードするには、最初に最新の`5.10.x`パッチリリースを適用する必要があります。`6.0`では追加の手動による変更は必要ないため、[通常のリリースアップグレード手順に従う](#steps)ことができます。

## 以前のアップグレード手順 {#older-upgrade-instructions}

5.xよりも前のバージョンのGitLabチャートからアップグレードする場合は、[GitLabドキュメントアーカイブ](https://docs.gitlab.com/archives/)を参照して、以前のバージョンのドキュメントにアクセスしてください。
