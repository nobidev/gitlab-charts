---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab-Migrationsチャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`migrations`サブチャートは、GitLabで使用されるデータベースのseed/移行を処理する単一の[ジョブ](https://kubernetes.io/docs/concepts/workloads/controllers/job/)を提供します。このチャートは、GitLab Railsコードベースを使用して実行されます。

[ClickHouse](../../../development/clickhouse.md)が有効になっている場合、このサブチャートは[ClickHouse](../../../development/clickhouse.md)の移行も実行します。

移行後、このジョブはデータベースのアプリケーション設定も編集して、[writes to authorized keys file](https://docs.gitlab.com/administration/operations/fast_ssh_key_lookup/#setting-up-fast-lookup-via-gitlab-shell)を無効にします。このチャートでは、承認済みキーファイルへの書き込みをサポートする代わりに、GitLab承認済みキーAPIとSSH `AuthorizedKeysCommand`の使用のみをサポートしています。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされるKubernetesクラスターから到達可能な外部サービスとして提供されるRedisおよびPostgreSQLに依存します。

もしClickHouseがインスタンスで有効になっている場合、このチャートもClickHouseに依存します。

## 設計上の選択肢 {#design-choices}

この`migrations`チャートは、チャートがインストールされるたびに、または新しい[チャートバージョン](https://helm.sh/docs/topics/charts/#charts-and-versioning) 、[appバージョン](https://helm.sh/docs/topics/charts/#the-appversion-field) 、あるいは何らかの値が変更されてチャートがアップグレードされるたびに、新しい移行[ジョブ](https://kubernetes.io/docs/concepts/workloads/controllers/job/)を作成します。

`helm install`と`helm upgrade`を使ってこのチャートをインストールおよびアップグレードすると、このチャートによって作成されたジョブは、次のチャートアップグレードまでクラスター内にオブジェクトとして残ります。これは、移行ログを監視できるようにするためです。ログシッピングの何らかの形式が導入されれば、これらのオブジェクトの永続性について再検討できます。

デプロイが`helm template`および`kubectl apply`または同様のツールによって生成されたマニフェストを使用して行われる場合、古い移行ジョブオブジェクトはクラスターから削除されません。

このチャートで使用されているコンテナには、現在ここでは使用されていない追加の最適化機能がいくつかあります。主に、Railsアプリケーションを起動して確認する必要なく、移行が既に最新である場合に、移行の実行を素早くスキップする機能です。この最適化には、移行ステータスの永続化が必要です。現在、このチャートでは行っていません。将来的には、このチャートに移行ステータスに対するストレージサポートを導入する予定です。

## 設定 {#configuration}

この`migrations`チャートは、外部サービスとチャート設定の2つの部分で設定されます。

## インストールコマンドラインオプション {#installation-command-line-options}

以下の表には、`helm install`コマンドに`--set`フラグを使用して指定できるすべてのチャート設定が含まれています

| パラメータ                                                | デフォルト                                                      | 説明 |
|----------------------------------------------------------|--------------------------------------------------------------|-------------|
| `common.labels`                                          | `{}`                                                         | このチャートによって作成されるすべてのオブジェクトに適用される補足的なラベル。 |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee` | 移行イメージリポジトリ |
| `image.tag`                                              |                                                              | 移行イメージタグ |
| `image.pullPolicy`                                       | `Always`                                                     | 移行プルポリシー |
| `image.pullSecrets`                                      |                                                              | イメージリポジトリのシークレット |
| `init.image.repository`                                  | `registry.gitlab.com/gitlab-org/build/cng/gitlab-base`       | `initContainer`イメージリポジトリ |
| `init.image.tag`                                         | `master`                                                     | `initContainer`イメージタグ |
| `init.image.containerSecurityContext`                    | `{}`                                                         | `initContainer` `securityContext`オーバーライド |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | `initContainer`固有: プロセスがその親プロセスよりも多くの特権を獲得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                       | `initContainer`固有: このコンテナが非rootユーザーで実行されるかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                  | `initContainer`固有: このコンテナの[Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `enabled`                                                | `true`                                                       | 移行有効化フラグ |
| `tolerations`                                            | `[]`                                                         | ポッド割り当てのトレランスラベル |
| `affinity`                                               | `{}`                                                         | ポッド割り当ての[Affinity rules](../_index.md#affinity) |
| `annotations`                                            | `{}`                                                         | ジョブスペックのアノテーション |
| `podAnnotations`                                         | `{}`                                                         | ポッドスペックのアノテーション |
| `podLabels`                                              |                                                              | 補足的なポッドラベル。セレクターには使用されません。 |
| `redis.serviceName`                                      | `redis`                                                      | Redisサービス名 |
| `psql.serviceName`                                       | `release-postgresql`                                         | PostgreSQLを提供するサービス名 |
| `psql.password.secret`                                   | `gitlab-postgres`                                            | `psql`シークレット |
| `psql.password.key`                                      | `psql-password`                                              | `psql`シークレット内の`psql`パスワードのキー |
| `psql.port`                                              |                                                              | PostgreSQLサーバーポートを設定します。`global.psql.port`よりも優先されます |
| `resources.requests.cpu`                                 | `250m`                                                       | GitLab移行の最小CPU |
| `resources.requests.memory`                              | `200Mi`                                                      | GitLab移行の最小メモリ |
| `securityContext.fsGroup`                                | `1000`                                                       | ポッドが開始されるべきグループID |
| `securityContext.runAsUser`                              | `1000`                                                       | ポッドが開始されるべきユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                                              | ボリュームの所有権と権限を変更するポリシー（Kubernetes 1.23が必要） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                             | 使用するSeccompプロファイル |
| `containerSecurityContext.runAsUser`                     | `1000`                                                       | このコンテナが開始されるコンテナの[`securityContext`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                      | このコンテナのプロセスがその親プロセスよりも多くの特権を獲得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                       | このコンテナが非rootユーザーで実行されるかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                  | Gitalyコンテナの[Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.annotations`                             | `{}`                                                         | ServiceAccountアノテーション |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                      | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                      | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                      | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                              | ServiceAccountの名前。設定されていない場合、完全なチャート名が使用されます。 |
| `extraInitContainers`                                    |                                                              | 含める追加のinitコンテナのリスト |
| `extraContainers`                                        |                                                              | 含めるコンテナのリストを含む複数行リテラルスタイルの文字列 |
| `extraVolumes`                                           |                                                              | 作成する追加ボリュームのリスト |
| `extraVolumeMounts`                                      |                                                              | 実行する追加ボリュームマウントのリスト |
| `extraEnv`                                               |                                                              | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                              | 他のデータソースから公開する追加の環境変数のリスト |
| `priorityClassName`                                      |                                                              | ポッドに割り当てられた[Priority class](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |

## チャート設定例 {#chart-configuration-examples}

### `extraEnv` {#extraenv}

`extraEnv`を使用すると、ポッド内のすべてのコンテナで追加の環境変数を公開できます。

`extraEnv`の使用例を以下に示します。

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

コンテナが起動すると、環境変数が公開されていることを確認できます:

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

### `extraEnvFrom` {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナで他のデータソースからの追加の環境変数を公開できます。

`extraEnvFrom`の使用例を以下に示します。

```yaml
extraEnvFrom:
  MY_NODE_NAME:
    fieldRef:
      fieldPath: spec.nodeName
  MY_CPU_REQUEST:
    resourceFieldRef:
      containerName: test-container
      resource: requests.cpu
  SECRET_THING:
    secretKeyRef:
      name: special-secret
      key: special_token
      # optional: boolean
  CONFIG_STRING:
    configMapKeyRef:
      name: useful-config
      key: some-string
      # optional: boolean
```

### `image.pullSecrets` {#imagepullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに認証することで、ポッド用のイメージをプルできます。

プライベートレジストリとその認証方法に関する追加の詳細は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)で確認できます。

`pullSecrets`の使用例を以下に示します。

```yaml
image:
  repository: my.migrations.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountアノテーション。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定されていない場合、完全なチャート名が使用されます。 |

### `affinity` {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。

## このチャートのCommunity Editionの使用 {#using-the-community-edition-of-this-chart}

デフォルトの場合、HelmチャートではGitLabのEnterprise Editionを使用します。必要に応じて、Community Editionを使用することもできます。[2つのエディションの違い](https://about.gitlab.com/install/ce-or-ee/)の詳細については、こちらをご覧ください。

Community Editionを使用するには、`image.repository`を`registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ce`に設定します

## 外部サービス {#external-services}

### Redis {#redis}

```yaml
redis:
  host: redis.example.com
  serviceName: redis
  port: 6379
  sentinels:
    - host: sentinel1.example.com
      port: 26379
  password:
    secret: gitlab-redis
    key: redis-password
```

#### `host` {#host}

使用するデータベースが格納されているRedisサーバーのホスト名。`serviceName`の代わりとして省略できます。Redis Sentinelを使用する場合、`host`属性は`sentinel.conf`で指定されたクラスター名に設定する必要があります。

#### `serviceName` {#servicename}

Redisデータベースを操作している`service`の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名（および現在の`.Release.Name`）をテンプレート処理します。これは、RedisをGitLabチャート全体の一部として使用する場合に便利です。これは`redis`にデフォルト設定されます。

#### `port` {#port}

Redisサーバーへの接続に使用するポート。`6379`がデフォルトです。

#### `password` {#password}

Redisの`password`属性には2つのサブキーがあります:

- `secret`は、イメージをプルするKubernetes `Secret`の名前を定義します
- `key`は、上記のシークレット内のパスワードを含むキーの名前を定義します。

#### `sentinels` {#sentinels}

`sentinels`属性は、Redis HAクラスターへの接続を可能にします。サブキーは各Sentinel接続を記述します。

- `host`はSentinelサービスのホスト名を定義します
- `port`はSentinelサービスに接続するためのポート番号を定義し、`26379`にデフォルト設定されます

> [!note]現在のRedis Sentinelサポートは、GitLabチャートとは別にデプロイされたSentinelのみをサポートしています。そのため、`redis.install=false`に設定して、GitLabチャートによるRedisのデプロイを無効にする必要があります。Redisパスワードを含むシークレットは、GitLabチャートをデプロイする前に手動で作成する必要があります。

### PostgreSQL {#postgresql}

```yaml
psql:
  host: psql.example.com
  serviceName: pgbouncer
  port: 5432
  database: gitlabhq_production
  username: gitlab
  preparedStatements: false
  password:
    secret: gitlab-postgres
    key: psql-password
```

#### `host` {#host-1}

使用するデータベースを持つPostgreSQLサーバーのホスト名。`postgresql.install=true` （デフォルトは非本番環境）の場合、これは省略できます。

#### `serviceName` {#servicename-1}

PostgreSQLデータベースを操作するサービスの名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名をテンプレート処理します。

#### `port` {#port-1}

PostgreSQLサーバーへの接続に使用するポート。`5432`がデフォルトです。

#### `database` {#database}

PostgreSQLサーバーで使用するデータベースの名前。デフォルトは`gitlabhq_production`です。

#### `preparedStatements` {#preparedstatements}

PostgreSQLサーバーとの通信時にプリペアドステートメントを使用するかどうか。`false`がデフォルトです。

#### `username` {#username}

データベースへの認証に使用するユーザー名。これは`gitlab`にデフォルト設定されます

#### `password` {#password-1}

PostgreSQLの`password`属性には2つのサブキーがあります:

- `secret`は、プル元のKubernetes `Secret`の名前を定義します。
- `key`は、上記のシークレット内のパスワードを含むキーの名前を定義します。

### ClickHouse (オプション) {#clickhouse-optional}

``` yaml
global:
  clickhouse:
    enabled: true
    main:
      url: https://clickhouse.example.com
      database: default
      username: default
      password:
        secret: gitlab-clickhouse-password
        key: main_password
```

もしClickHouseがインスタンスで有効になっている場合、このチャートはClickHouseデータベースの移行も実行します。ClickHouseの設定は、`global.clickhouse`キーの下に提供する必要があります。

#### `main.url` {#mainurl}

ClickHouseインスタンスのURL。

#### `main.database` {#maindatabase}

ClickHouse内のデータベース名。

#### `main.username` {#mainusername}

ClickHouseで認証するために使用するユーザー名。

#### `main.password` {#mainpassword}

ClickHouseの`password`属性には2つのサブキーが含まれます:

- `secret`は、イメージをプルするKubernetesシークレットの名前を定義します。
- `key`は、上記の`secret`シークレット内のパスワードを含むキーの名前を定義します。
