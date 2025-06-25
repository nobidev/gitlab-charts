---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-Exporterチャートの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

`gitlab-exporter`サブチャートは、GitLabアプリケーション固有のデータのPrometheusメトリクスを提供します。PostgreSQLと直接通信してクエリを実行し、CIビルド、プルミラーなどのデータを取得します。さらに、Sidekiqを使用してRedisと通信し、Sidekiqキューの状態に関するさまざまなメトリクス (ジョブ数など) を収集します。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされているKubernetesクラスターから到達可能な外部サービスとして提供される、RedisおよびPostgreSQLサービスに依存しています。

## 設定 {#configuration}

`gitlab-exporter`チャートは次のように設定されます。[グローバル設定](#global-settings)および[チャート設定](#chart-settings)。

## インストール コマンドライン オプション {#installation-command-line-options}

以下の表に、`helm install`フラグを使用して`--set`コマンドに指定できる、すべての可能なチャート設定を示します。

| パラメータ                                                | デフォルト                                                    | 説明 |
|----------------------------------------------------------|------------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                       | ポッド割り当ての[アフィニティルール](../_index.md#affinity) |
| `annotations`                                            |                                                            | ポッドアノテーション |
| `common.labels`                                          | `{}`                                                       | このチャートによって作成されたすべてのオブジェクトに適用される追加のラベル。 |
| `podLabels`                                              |                                                            | 補足的なポッドラベル。セレクターには使用されません。 |
| `common.labels`                                          |                                                            | このチャートによって作成されたすべてのオブジェクトに適用される追加のラベル。 |
| `deployment.strategy`                                    | `{}`                                                       | デプロイメントで使用される更新ストラテジを構成できます |
| `enabled`                                                | `true`                                                     | GitLab Exporterが有効なフラグ |
| `extraContainers`                                        |                                                            | 含めるコンテナのリストを含む複数行のリテラル スタイル文字列 |
| `extraInitContainers`                                    |                                                            | 含める追加のinitコンテナのリスト |
| `extraVolumeMounts`                                      |                                                            | 実行する追加のボリューム マウントのリスト |
| `extraVolumes`                                           |                                                            | 作成する追加のボリュームのリスト |
| `extraEnv`                                               |                                                            | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                            | 公開する他のデータソースからの追加の環境変数のリスト |
| `image.pullPolicy`                                       | `IfNotPresent`                                             | GitLabイメージプルポリシー |
| `image.pullSecrets`                                      |                                                            | イメージリポジトリのシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-exporter` | GitLab Exporterイメージリポジトリ |
| `image.tag`                                              |                                                            | イメージtag   |
| `init.image.repository`                                  |                                                            | initContainerイメージ |
| `init.image.tag`                                         |                                                            | initContainerイメージtag |
| `init.containerSecurityContext`                          |                                                            | initContainer固有の[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                    | initContainer固有:プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                     | initContainer固有:コンテナが非rootユーザーで実行されるかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                | initContainer固有:コンテナの[Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `metrics.enabled`                                        | `true`                                                     | メトリクス エンドポイントをスクレイピングに使用できるようにする必要がある場合 |
| `metrics.port`                                           | `9168`                                                     | メトリクス エンドポイントポート |
| `metrics.path`                                           | `/metrics`                                                 | メトリクス エンドポイントパス |
| `metrics.serviceMonitor.enabled`                         | `false`                                                    | Prometheus Operatorがメトリクスのスクレイピングを管理できるようにServiceMonitorを作成する必要がある場合、これを有効にすると`prometheus.io`スクレイピングアノテーションが削除されることに注意してください |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                       | ServiceMonitorに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                       | ServiceMonitorの追加のエンドポイント設定 |
| `metrics.annotations`                                    |                                                            | **非推奨**明示的なメトリクスアノテーションを設定します。テンプレートコンテンツに置き換えられました。 |
| `priorityClassName`                                      |                                                            | ポッドに割り当てられた[優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |
| `resources.requests.cpu`                                 | `75m`                                                      | GitLab Exporterの最小CPU |
| `resources.requests.memory`                              | `100M`                                                     | GitLab Exporterの最小メモリ |
| `serviceLabels`                                          | `{}`                                                       | 補足サービスラベル |
| `service.externalPort`                                   | `9168`                                                     | GitLab Exporterの公開ポート |
| `service.internalPort`                                   | `9168`                                                     | GitLab Exporterの内部ポート |
| `service.name`                                           | `gitlab-exporter`                                          | GitLab Exporterサービス名 |
| `service.type`                                           | `ClusterIP`                                                | GitLab Exporterサービスタイプ |
| `serviceAccount.annotations`                             | `{}`                                                       | ServiceAccountアノテーション |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                    | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                    | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                    | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                            | ServiceAccountの名前。設定しない場合、チャートのフルネームが使用されます |
| `securityContext.fsGroup`                                | `1000`                                                     | ポッドを開始するグループID |
| `securityContext.runAsUser`                              | `1000`                                                     | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                                            | ボリュームの所有権と権限を変更するためのポリシー (Kubernetes 1.23が必要) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                           | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                            | コンテナを開始する[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `containerSecurityContext.runAsUser`                     | `1000`                                                     | コンテナが開始される特定のセキュリティコンテキストユーザーの上書きを許可します |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                    | コンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `false`                                                    | コンテナが非rootユーザーで実行されるかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                | Gitalyコンテナの[Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `tolerations`                                            | `[]`                                                       | ポッド割り当ての容認ラベル |
| `psql.port`                                              |                                                            | PostgreSQLサーバーポートを設定します。`global.psql.port`よりも優先されます |
| `tls.enabled`                                            | `false`                                                    | GitLab Exporterが有効 |
| `tls.secretName`                                         | `{Release.Name}-gitlab-exporter-tls`                       | GitLab Exporterシークレット。[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を指す必要があります。 |

## チャート設定の例 {#chart-configuration-examples}

### extraEnv {#extraenv}

`extraEnv`を使用すると、ポッド内のすべてのコンテナで追加の環境変数を公開できます。

`extraEnv`の使用例を以下に示します:

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

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナで他のデータソースからの追加の環境変数を公開できます。

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

`pullSecrets`を使用すると、プライベートレジストリに対して認証して、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法の詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)を参照してください。

`pullSecrets`の使用例を以下に示します:

```YAML
image:
  repository: my.image.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセス トークンをポッドにマウントするかどうかを制御します。

| 名前                           |  タイプ   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountアノテーション。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。特定のサイドカーが適切に動作するために必要な場合を除き、これを有効にしないでください (たとえば、Istio)。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | ストリング  |         | ServiceAccountの名前。設定しない場合、チャートのフルネームが使用されます。 |

### affinity {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。

### annotations {#annotations}

`annotations`を使用すると、GitLab Exporterポッドにアノテーションを追加できます。次に例を示します:

```YAML
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## グローバル設定 {#global-settings}

チャート間でいくつかの共通グローバル設定を共有します。GitLabやレジストリのホスト名など、一般的な構成オプションについては、[グローバルドキュメント](../../globals.md)を参照してください。

## チャート設定 {#chart-settings}

次の値は、GitLab Exporterポッドを構成するために使用されます。

### metrics.enabled {#metricsenabled}

デフォルトでは、ポッドは`/metrics`でメトリクス エンドポイントを公開します。メトリクスが有効になっている場合、各ポッドにアノテーションが追加され、Prometheusサーバーが公開されたメトリクスを検出してスクレイピングできるようになります。
