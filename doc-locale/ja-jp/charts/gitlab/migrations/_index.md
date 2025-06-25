---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-Migrationsチャートの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

`migrations`サブチャートは、GitLabデータベースのシーディング/移行を処理する単一の移行[ジョブ](https://kubernetes.io/docs/concepts/workloads/controllers/job/)を提供します。このチャートは、GitLab Railsのコードベースを使用して実行されます。

移行後、このジョブは、[許可されたキーファイルへの書き込み](https://docs.gitlab.com/administration/operations/fast_ssh_key_lookup/#setting-up-fast-lookup-via-gitlab-shell)をオフにするために、データベース内のアプリケーション設定も編集します。このチャートでは、許可されたキーファイルへの書き込みのサポートの代わりに、SSH `AuthorizedKeysCommand`でGitLab Authorized Keys APIの使用のみをサポートしています。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされているKubernetesクラスターから到達可能な外部サービスとして、RedisおよびPostgreSQLに依存します。

## 設計上の選択 {#design-choices}

`migrations`チャートは、チャートのインストール時、または新しい[チャートバージョン](https://helm.sh/docs/topics/charts/#charts-and-versioning)、[appVersion](https://helm.sh/docs/topics/charts/#the-appversion-field)、またはいずれかの値への変更でチャートがアップグレードされるたびに、新しい移行[ジョブ](https://kubernetes.io/docs/concepts/workloads/controllers/job/)を作成します。

このチャートのインストールとアップグレードに`helm install`と`helm upgrade`を使用すると、このチャートによって作成されたジョブは、次のチャートのアップグレードまでクラスター内のオブジェクトとして残ります。これは、移行ログを監視できるようにするためです。何らかの形式のログの生成が適切に行われると、これらのオブジェクトの永続性を再検討できます。

`helm template`と`kubectl apply`、または同様のツールで生成されたマニフェストを使用してデプロイメントが行われる場合、古い移行ジョブオブジェクトはクラスターから削除されません。

このチャートで使用されているコンテナには、現在ここで使用していない追加の最適化がいくつかあります。主に、Railsアプリケーションを起動して確認しなくても、すでに最新の状態になっている場合は、移行の実行をすばやくスキップできる機能です。この最適化では、移行状態を永続化する必要があります。これは、現時点ではこのチャートでは行っていません。将来的には、このチャートへの移行状態のストレージサポートを導入する予定です。

## 設定 {#configuration}

`migrations`チャートは、外部サービスとチャート設定の2つの部分で構成されています。

## インストールコマンドラインline>オプション {#installation-command-line-options}

下のテーブルに、`--set`フラグを使用して`helm install`コマンドに指定できる、すべての可能なチャート設定が含まれています

| パラメータ                   | 説明                              | デフォルト           |
| --------------------------- | ---------------------------------------- | ----------------  |
| `common.labels`             | このチャートによって作成されたすべてのオブジェクトに適用される補助ラベル。  | `{}` |
| `image.repository`          | 移行イメージリポジトリ              | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee` |
| `image.tag`                 | 移行イメージtag                     |                   |
| `image.pullPolicy`          | 移行プルポリシー                   | `Always`          |
| `image.pullSecrets`         | イメージリポジトリのシークレット         |                   |
| `init.image.repository`     | initContainerイメージリポジトリ           | `registry.gitlab.com/gitlab-org/build/cng/gitlab-base` |
| `init.image.tag`            | initContainerイメージtag                  | `master`          |
| `init.image.containerSecurityContext` | initコンテナsecurityContext上書き | `{}`    |
| `init.containerSecurityContext.allowPrivilegeEscalation` | initContainer固有:プロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します                                                                             | `false`                                                                               |
| `init.containerSecurityContext.runAsNonRoot`             | initContainer固有:コンテナを非rootユーザーで実行するかどうかを制御します                                                                                                | `true`                                                                                |
| `init.containerSecurityContext.capabilities.drop`        | initContainer固有:コンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します                                               | `[ "ALL" ]`                                                                           |
| `enabled`                   | 移行を有効にするフラグ                   | `true`            |
| `tolerations`               | ポッドの割り当ての容認ラベル     | `[]`              |
| `affinity`                  | ポッドの割り当ての[アフィニティルール](../_index.md#affinity)            | `{}`              |
| `annotations`               | ジョブ仕様のアノテーション             | `{}`              |
| `podAnnotations`            | ポッド 仕様のアノテーション             | `{}`              |
| `podLabels`                 | 補助ポッド ラベル。セレクターには使用されません。 |   |
| `redis.serviceName`         | Redisサービス名                       | `redis`           |
| `psql.serviceName`          | PostgreSQLを提供するサービスの名前     | `release-postgresql` |
| `psql.password.secret`      | psqlシークレット                              | `gitlab-postgres` |
| `psql.password.key`         | psqlシークレット内のpsqlパスワードへのキー      | `psql-password`   |
| `psql.port`                 | PostgreSQLサーバーのポートを設定します。`global.psql.port`より優先されます |   |
| `resources.requests.cpu`    | GitLabの移行の最小CPU                  | `250m`                                   |
| `resources.requests.memory` | GitLabの移行の最小メモリ               | `200Mi`                                  |
| `securityContext.fsGroup`   | ポッドを開始するグループID | `1000`                                   |
| `securityContext.runAsUser` | ポッドを開始するユーザーID  | `1000`                                   |
| `securityContext.fsGroupChangePolicy` | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要） |    |
| `securityContext.seccompProfile.type`                    | 使用するSeccompプロファイル                                                                                                                                                          | `RuntimeDefault`                                                                      |
| `containerSecurityContext.runAsUser`  | コンテナの開始元のコンテナ[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします | `1000` |
| `containerSecurityContext.allowPrivilegeEscalation`      | コンテナのプロセスがその親プロセスよりも多くの特権を取得できるかどうかを制御します                                                                                    | `false`                                                                               |
| `containerSecurityContext.runAsNonRoot`                  | コンテナを非rootユーザーで実行するかどうかを制御します                                                                                                                        | `true`                                                                                |
| `containerSecurityContext.capabilities.drop`             | Gitalyコンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します                                                                | `[ "ALL" ]`                                                                           |
| `serviceAccount.annotations` | ServiceAccountアノテーション              | `{}`                                                    |
| `serviceAccount.automountServiceAccountToken`| デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します | `false`    |
| `serviceAccount.create`     | ServiceAccountを作成するかどうかを示します                                      | `false`           |
| `serviceAccount.enabled`    | ServiceAccountを使用するかどうかを示します                                | `false`           |
| `serviceAccount.name`       | ServiceAccountの名前。設定されていない場合、チャートのフルネームが使用されます  |                   |
| `extraInitContainers`       | 含める追加のinitコンテナのリスト |                   |
| `extraContainers`           | 含めるコンテナのリストを含む複数行のリテラル スタイル文字列      |                   |
| `extraVolumes`              | 作成する追加ボリュームのリスト          |                   |
| `extraVolumeMounts`         | 実行する追加ボリュームマウントのリスト       |                   |
| `extraEnv`                  | 公開する追加の環境変数variable>のリスト |              |
| `extraEnvFrom`              | 公開する他のデータソースからの追加の環境変数variable>のリスト|                              |
| `priorityClassName`         | ポッドに割り当てられた[優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |                   |

## チャート設定例 {#chart-configuration-examples}

### extraEnv {#extraenv}

`extraEnv`を使用すると、ポッド内のすべてのコンテナで追加の環境変数variable>を公開できます。

`extraEnv`の使用例を以下に示します:

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

コンテナが起動すると、環境変数variable>が公開されていることを確認できます:

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナで他のデータソースからの追加の環境変数variable>を公開できます。

`extraEnvFrom`の使用例を以下に示します:

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

### image.pullSecrets {#imagepullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに認証して、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法に関する追加の詳細は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)にあります。

`pullSecrets`の使用例を以下に示します:

```YAML
image:
  repository: my.migrations.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  種類   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountアノテーション。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。特定のサイドカーが正常に動作するためにこれが必要な場合（たとえば、Istio）、これを有効にしないでください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定されていない場合、チャートのフルネームが使用されます。 |

### affinity {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。

## このチャートのCommunityエディションの使用 {#using-the-community-edition-of-this-chart}

デフォルトでは、HelmチャートはGitLabのGitLab Enterpriseエディション（EE）を使用します。必要に応じて、代わりにCommunityエディションを使用できます。[2つの違い](https://about.gitlab.com/install/ce-or-ee/)について詳しく見る。

Communityエディションを使用するには、`image.repository`を`registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ce`に設定します

## 外部サービス {#external-services}

### Redis {#redis}

```YAML
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

#### host {#host}

使用するデータベースを持つRedisサーバーのホスト名。これは、`serviceName`の代わりとして省略できます。Redis Sentinelを使用している場合、`host`属性は、`sentinel.conf`で指定されているクラスター名に設定する必要があります。

#### serviceName {#servicename}

Redisデータベースをオペレートしている`service`の名前。これが存在し、`host`が存在しない場合、チャートはサービスのホスト名（および現在の`.Release.Name`）を`host`値の代わりにテンプレート化します。これは、Redisを全体のGitLabチャートの一部として使用する場合に便利です。これはデフォルトで`redis`になります

#### ポート {#port}

Redisサーバーに接続するポート。デフォルトは`6379`です。

#### パスワード {#password}

Redisの`password`属性には、2つのサブキーがあります:

- `secret`は、プルするKubernetes `Secret`の名前を定義します
- `key`は、上記のシークレットに含まれるキーの名前を定義します。

#### センティネル {#sentinels}

`sentinels`属性を使用すると、Redis HAクラスターに接続できます。サブキーは、各Sentinel接続を記述します。

- `host`は、Sentinelサービスのホスト名を定義します
- `port`は、Sentinelサービスに到達するポート番号を定義します（デフォルトは`26379`）。

_注:_現在のRedis Sentinelサポートは、GitLabチャートとは別にデプロイされたSentinelのみをサポートします。その結果、GitLabチャートを介したRedisデプロイメントは、`redis.install=false`で無効にする必要があります。Redisパスワードを含むシークレットは、GitLabチャートをデプロイする前に手動で作成する必要があります。

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

#### ホスト {#host-1}

使用するデータベースを持つPostgreSQLサーバーのホスト名。これは、`postgresql.install=true`の場合（デフォルトは非本番環境）は省略できます。

#### serviceName {#servicename-1}

PostgreSQLデータベースをオペレートしているサービスの名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名をテンプレート化します。

#### ポート {#port-1}

PostgreSQLサーバーに接続するポート。デフォルトは`5432`です。

#### データベース {#database}

PostgreSQLサーバーで使用するデータベースの名前。これはデフォルトで`gitlabhq_production`になります。

#### preparedStatements {#preparedstatements}

PostgreSQLサーバーと接続中にプリペアドステートメントを使用するかどうか。デフォルトは`false`です。

#### ユーザー名 {#username}

データベースに認証するためのユーザー名。これはデフォルトで`gitlab`になります

#### パスワード {#password-1}

PostgreSQLの`password`属性には、サブキーが必要です:

- `secret`は、プルするKubernetes `Secret`の名前を定義します
- `key`は、上記のシークレットに含まれるキーの名前を定義します。
