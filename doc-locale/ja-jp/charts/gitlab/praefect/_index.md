---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Praefectチャートの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed
- 状態:実験

{{< /details >}}

{{< alert type="warning" >}}

Praefectチャートはまだ開発中です。この実験的なバージョンは、まだ本番環境での使用には適していません。アップグレードには、大幅な手動による介入が必要になる場合があります。詳細については、[Praefect GAリリースエピック](https://gitlab.com/groups/gitlab-org/charts/-/epics/33)を参照してください。

{{< /alert >}}

Praefectチャートは、Helm ChartでデプロイされたGitLabインストール内の[Gitalyクラスター](https://docs.gitlab.com/administration/gitaly/praefect/)を管理するために使用されます。

## 既知の制限事項と問題 {#known-limitations-and-issues}

1. データベースは[手動で作成](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2310)する必要があります。
1. クラスターサイズは固定されています:[Gitalyクラスターは現在、オートスケールをサポートしていません](https://gitlab.com/gitlab-org/gitaly/-/issues/2997)。
1. クラスター内のPraefectインスタンスを使用して、クラスター外のGitalyインスタンスを管理することは[サポートされていません](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2662)。

## 要件 {#requirements}

このチャートはGitalyチャートを使用します。`global.gitaly`の設定は、このチャートで作成されたインスタンスの設定に使用されます。これらの設定のドキュメントは、[Gitalyチャートのドキュメント](../gitaly/_index.md)にあります。

_重要_:`global.gitaly.tls`は`global.praefect.tls`とは独立しています。これらは個別に構成されます。

デフォルトでは、このチャートは3つのGitalyレプリカを作成します。

## 設定 {#configuration}

このチャートはデフォルトで無効になっています。チャートのデプロイの一部として有効にするには、`global.praefect.enabled=true`を設定します。

### レプリカ {#replicas}

デプロイするレプリカのデフォルト数は3です。これは、必要なレプリカ数を指定して`global.praefect.virtualStorages[].gitalyReplicas`を設定することで変更できます。例:

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
```

### 複数の仮想ストレージ {#multiple-virtual-storages}

複数の仮想ストレージを設定できます([Gitalyクラスター](https://docs.gitlab.com/administration/gitaly/praefect/)のドキュメントを参照)。例:

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
```

これにより、Gitalyのリソースが2セット作成されます。これには、2つのGitaly StatefulSet (仮想ストレージごとに1つ)が含まれます。

次に、[管理者は新しいリポジトリの保存場所を設定](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored)できます。

### 永続性 {#persistence}

仮想ストレージごとに永続性の設定を指定できます。

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
      persistence:
        enabled: true
        size: 50Gi
        accessMode: ReadWriteOnce
        storageClass: storageclass1
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
      persistence:
        enabled: true
        size: 100Gi
        accessMode: ReadWriteOnce
        storageClass: storageclass2
```

## defaultReplicationFactor {#defaultreplicationfactor}

`defaultReplicationFactor`は、各仮想ストレージで構成できます(「[レプリケーション係数の構成](https://docs.gitlab.com/administration/gitaly/praefect/#configure-replication-factor)」ドキュメントを参照)。

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 5
      maxUnavailable: 2
      defaultReplicationFactor: 3
    - name: secondary
      gitalyReplicas: 4
      maxUnavailable: 1
      defaultReplicationFactor: 2
```

### Praefectへの移行 {#migrating-to-praefect}

{{< alert type="note" >}}

グループWikiは、[APIを使用して移動することはできません](https://docs.gitlab.com/api/project_repository_storage_moves/)。

{{< /alert >}}

スタンドアロンGitalyインスタンスからPraefectセットアップに移行する場合、`global.praefect.replaceInternalGitaly`を`false`に設定できます。これにより、新しいPraefect管理対象Gitalyインスタンスが作成されている間、既存のGitalyインスタンスが確実に保持されます。

```yaml
global:
  praefect:
    enabled: true
    replaceInternalGitaly: false
    virtualStorages:
    - name: virtualStorage2
      gitalyReplicas: 5
      maxUnavailable: 2
```

{{< alert type="note" >}}

Praefectへの移行時に、Praefectのどの仮想ストレージも`default`という名前にすることはできません。これは、常に少なくとも1つのストレージに`default`という名前を付ける必要があるため、名前はPraefect以外の構成ですでに使用されているためです。

{{< /alert >}}

次に、[Gitalyクラスターに移行](https://docs.gitlab.com/administration/gitaly/#migrating-to-gitaly-cluster)する手順に従って、`default`ストレージから`virtualStorage2`にデータを移動できます。追加のストレージが`global.gitaly.internal.names`で定義されている場合は、それらのストレージからリポジトリも移行してください。

リポジトリが`virtualStorage2`に移行された後、Praefect構成に`default`という名前のストレージが追加された場合、`replaceInternalGitaly`を`true`に戻すことができます。

```yaml
global:
  praefect:
    enabled: true
    replaceInternalGitaly: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
    - name: virtualStorage2
      gitalyReplicas: 5
      maxUnavailable: 2
```

必要に応じて、[Gitalyクラスターに移行](https://docs.gitlab.com/administration/gitaly/#migrating-to-gitaly-cluster)する手順に再度従って、`virtualStorage2`から新しく追加された`default`ストレージにデータを移動できます。

最後に、[リポジトリストレージパスのドキュメント](https://docs.gitlab.com/administration/repository_storage_paths/#choose-where-new-repositories-are-stored)を参照して、新しいリポジトリの保存場所を設定します。

### データベースの作成 {#creating-the-database}

Praefectは、独自のデータベースを使用して状態を追跡します。Praefectが機能するためには、これを手動で作成する必要があります。

{{< alert type="note" >}}

これらの手順では、バンドルされたPostgreSQLサーバーを使用していることを前提としています。独自のサーバーを使用している場合は、接続方法に多少の違いがあります。

{{< /alert >}}

1. データベースインスタンスにログインします:

   ```shell
   kubectl exec -it $(kubectl get pods -l app.kubernetes.io/name=postgresql -o custom-columns=NAME:.metadata.name --no-headers) -- bash
   ```

   ```shell
   PGPASSWORD=$(echo $POSTGRES_POSTGRES_PASSWORD) psql -U postgres -d template1
   ```

1. データベースユーザーを作成します:

   ```sql
   CREATE ROLE praefect WITH LOGIN;
   ```

1. データベースユーザーのパスワードを設定します。

   デフォルトでは、`shared-secrets`ジョブはシークレットを生成します。

   1. パスワードをフェッチします:

      ```shell
      kubectl get secret RELEASE_NAME-praefect-dbsecret -o jsonpath="{.data.secret}" | base64 --decode
      ```

   1. `psql`プロンプトでパスワードを設定します:

      ```sql
      \password praefect
      ```

1. データベースを作成します:

   ```sql
   CREATE DATABASE praefect WITH OWNER praefect;
   ```

### TLS経由でのPraefectの実行 {#running-praefect-over-tls}

Praefectは、クライアントおよびGitalyノードとのTLS経由での通信をサポートします。これは、`global.praefect.tls.enabled`および`global.praefect.tls.secretName`の設定によって制御されます。TLS経由でPraefectを実行するには、次の手順に従います:

1. Helm Chartは、TLS経由でPraefectと通信するために証明書が提供されることを想定しています。この証明書は、存在するすべてのPraefectノードに適用される必要があります。したがって、これらの各ノードのすべてのホスト名を証明書のサブジェクト代替名 (SAN)として追加するか、またはワイルドカードを使用できます。

   使用するホスト名を知るには、Toolbox Podの`/srv/gitlab/config/gitlab.yml`ファイルを確認し、その中の`repositories.storages`キーの下に指定されているさまざまな`gitaly_address`フィールドを確認します。

   ```shell
   kubectl exec -it <Toolbox Pod> -- grep gitaly_address /srv/gitlab/config/gitlab.yml
   ```

{{< alert type="note" >}}

内部Praefectポッド用のカスタム署名付き証明書を生成するための基本スクリプトは、[このリポジトリにあります](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/generate_certificates.sh)。ユーザーはそのスクリプトを使用して、適切なSAN属性を持つ証明書を生成したり、参照したりできます。

{{< /alert >}}

1. 作成した証明書を使用してTLSシークレットを作成します。

   ```shell
   kubectl create secret tls <secret name> --cert=praefect.crt --key=praefect.key
   ```

1. `--set global.praefect.tls.enabled=true`を渡してHelm Chartを再デプロイします。

TLS経由でGitalyを実行する場合は、仮想ストレージごとにシークレット名を指定する必要があります。

```yaml
global:
  gitaly:
    tls:
      enabled: true
  praefect:
    enabled: true
    tls:
      enabled: true
      secretName: praefect-tls
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
      tlsSecretName: default-tls
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
      tlsSecretName: vs2-tls
```

### コマンドラインオプションのインストール {#installation-command-line-options}

次のテーブルには、`--set`フラグを使用して`helm install`コマンドに指定できるすべての可能なチャート構成が含まれています。

| パラメータ                                                | デフォルト                                           | 説明 |
|----------------------------------------------------------|---------------------------------------------------|-------------|
| common.labels                                            | `{}`                                              | このチャートで作成されたすべてのオブジェクトに適用される追加ラベル。 |
| failover.enabled                                         | true                                              | Praefectがノード障害時にフェイルオーバーを実行するかどうか |
| failover.readonlyAfter                                   | false                                             | ノードがフェイルオーバー後に読み取り専用モードになるかどうか |
| autoMigrate                                              | true                                              | スタートアップ時に移行を自動的に実行する |
| image.repository                                         | `registry.gitlab.com/gitlab-org/build/cng/gitaly` | 使用するデフォルトのイメージリポジトリ。PraefectはGitalyイメージの一部としてバンドルされています |
| podLabels                                                | `{}`                                              | 補足のポッドラベル。セレクターには使用されません。 |
| ntpHost                                                  | `pool.ntp.org`                                    | Praefectが現在の時刻を要求するNTPサーバーを構成します。 |
| service.name                                             | `praefect`                                        | 作成するサービスの名前 |
| service.type                                             | ClusterIP                                         | 作成するサービスの種類 |
| service.internalPort                                     | 8075                                              | Praefectポッドがリッスンする内部ポート番号 |
| service.externalPort                                     | 8075                                              | Praefectサービスがクラスターで公開するポート番号 |
| init.resources                                           |                                                   |             |
| init.image                                               |                                                   |             |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                           | initContainer固有:プロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                            | initContainer固有:コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                       | initContainer固有:コンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| extraEnvFrom                                             |                                                   | 公開する他のデータソースからの追加の環境変数のリスト |
| logging.level                                            |                                                   | ログレベル   |
| logging.format                                           | `json`                                            | ログ形式  |
| logging.sentryDsn                                        |                                                   | Sentry DSN URL - Goサーバーからの例外 |
| logging.sentryEnvironment                                |                                                   | ログの生成に使用するSentry環境 |
| `metrics.enabled`                                        | `true`                                            | メトリックエンドポイントをスクレイピングに使用できるようにするかどうか |
| `metrics.port`                                           | `9236`                                            | メトリックエンドポイントポート |
| `metrics.separate_database_metrics`                      | `true`                                            | trueの場合、メトリクスのスクレイピングはデータベースクエリを実行しません。falseに設定すると、[パフォーマンスの問題が発生する可能性があります](https://gitlab.com/gitlab-org/gitaly/-/issues/3796) |
| `metrics.path`                                           | `/metrics`                                        | メトリックエンドポイントパス |
| `metrics.serviceMonitor.enabled`                         | `false`                                           | ServiceMonitorを作成してPrometheus Operatorがメトリクスのスクレイピングを管理できるようにするかどうか。これを有効にすると、`prometheus.io`スクレイピングアノテーションが削除されることに注意してください |
| `affinity`                                               | `{}`                                              | ポッド割り当ての[アフィニティルール](../_index.md#affinity) |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                              | ServiceMonitorに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                              | ServiceMonitorの追加のエンドポイント設定 |
| securityContext.runAsUser                                | 1000                                              |             |
| securityContext.fsGroup                                  | 1000                                              |             |
| securityContext.fsGroupChangePolicy                      |                                                   | ボリュームの所有権と権限を変更するためのポリシー(Kubernetes 1.23が必要) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                  | 使用するSeccompプロファイル |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                           | コンテナのプロセスが、その親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                            | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                       | Gitalyコンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.annotations`                             | `{}`                                              | ServiceAccountアノテーション |
| `serviceAccount.automountServiceAccountToken`            | `false`                                           | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                           | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                           | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                   | ServiceAccountの名前。設定しない場合、チャートのフルネームが使用されます |
| serviceLabels                                            | `{}`                                              | 補足のサービスラベル |
| statefulset.strategy                                     | `{}`                                              | statefulsetで使用される更新ストラテジを構成できます |

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  種類   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountアノテーション。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。特定のサイドカーが適切に動作するために必要な場合を除き、これを有効にしないでください(たとえば、Istio)。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定しない場合、チャートのフルネームが使用されます。 |

### アフィニティ {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。
