---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab-Sidekiqチャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`sidekiq`サブチャートは、Sidekiqワーカーの構成可能なデプロイを提供し、個別のスケーラビリティと構成を備えた複数の`Deployment`にわたるキューの分離を提供するように明示的に設計されています。

このチャートはデフォルトの`pods:`宣言を提供しますが、空の定義を提供すると、*ワーカー*はいません。

## 要件 {#requirements}

このチャートは、Redis、PostgreSQL、およびGitalyサービスへのアクセスに依存します。GitLabチャート全体の一部として、またはこのチャートがデプロイされているKubernetesクラスターから到達可能な外部サービスとして提供されます。

## 設計の選択肢 {#design-choices}

このチャートは、複数の`Deployment`と関連する`ConfigMap`を作成します。コマンドの長さに関する懸念を避けるため、`environment`属性やコンテナの`command`への追加の引数を使用するよりも、`ConfigMap`の動作を利用する方が明確になります。この選択により、多数の`ConfigMap`が生成されますが、各ポッドが何をすべきかについて非常に明確な定義が提供されます。

## 設定 {#configuration}

この`sidekiq`チャートは、[チャート全体の外部サービス](#external-services) 、[チャート全体のデフォルト](#chart-wide-defaults) 、および[ポッドごとの定義](#per-pod-settings)の3つの部分で構成されています。

## コマンドラインオプションのインストール {#installation-command-line-options}

以下の表には、`helm install`コマンドに`--set`フラグを使用して指定できるすべての可能なチャートの構成が含まれています:

| パラメータ                                                | デフォルト                                                      | 説明 |
|----------------------------------------------------------|--------------------------------------------------------------|-------------|
| `annotations`                                            |                                                              | ポッドアノテーション |
| `podLabels`                                              |                                                              | 補足ポッドラベル。セレクターには使用されません。 |
| `common.labels`                                          |                                                              | このチャートによって作成されたすべてのオブジェクトに適用される補足ラベル。 |
| `concurrency`                                            | `20`                                                         | Sidekiqデフォルトの並行処理 |
| `deployment.strategy`                                    | `{}`                                                         | デプロイによって利用される更新戦略を構成できます |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                         | ポッドが正常に終了するために必要なオプションの時間（秒単位）。 |
| `enabled`                                                | `true`                                                       | Sidekiq有効フラグ |
| `extraContainers`                                        |                                                              | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列 |
| `extraInitContainers`                                    |                                                              | 含める追加のinitコンテナのリスト |
| `extraVolumeMounts`                                      |                                                              | 追加のボリュームマウントを構成するための文字列テンプレート |
| `extraVolumes`                                           |                                                              | 追加のボリュームを構成するための文字列テンプレート |
| `extraEnv`                                               |                                                              | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                              | 他のデータソースから公開する追加の環境変数のリスト |
| `gitaly.serviceName`                                     | `gitaly`                                                     | Gitalyサービス名 |
| `health_checks.port`                                     | `3808`                                                       | ヘルスチェックサーバーポート |
| `health_checks.listenAddr`                               | `*`                                                          | ヘルスチェックリスニングアドレス。 |
| `hpa.behaviour`                                          | `{scaleDown: {stabilizationWindowSeconds: 300 }}`            | 動作には、スケールアップとスケールダウンの動作に関する仕様が含まれています（`autoscaling/v2beta2`以上が必要です）。 |
| `hpa.customMetrics`                                      | `[]`                                                         | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で構成された平均CPU使用率のデフォルト使用をオーバーライドします）。 |
| `hpa.cpu.targetType`                                     | `AverageValue`                                               | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.cpu.targetAverageValue`                             | `350m`                                                       | オートスケールCPUターゲット値を設定します。 |
| `hpa.cpu.targetAverageUtilization`                       |                                                              | オートスケールCPUターゲット使用率を設定します。 |
| `hpa.memory.targetType`                                  |                                                              | オートスケールメモリターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.memory.targetAverageValue`                          |                                                              | オートスケールメモリターゲット値を設定します。 |
| `hpa.memory.targetAverageUtilization`                    |                                                              | オートスケールメモリターゲット使用率を設定します。 |
| `hpa.targetAverageValue`                                 |                                                              | **DEPRECATED**オートスケールCPUターゲット値を設定します。 |
| `keda.enabled`                                           | `false`                                                      | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                   | `30`                                                         | 各トリガーを確認する間隔 |
| `keda.cooldownPeriod`                                    | `300`                                                        | 最後にアクティブと報告されたトリガーの後、リソースを0にスケールダウンするまでの待機期間 |
| `keda.minReplicaCount`                                   |                                                              | KEDAがリソースをスケールダウンする最小レプリカ数。`minReplicas`がデフォルトです。 |
| `keda.maxReplicaCount`                                   |                                                              | KEDAがリソースをスケールアップする最大レプリカ数。`maxReplicas`がデフォルトです。 |
| `keda.fallback`                                          |                                                              | KEDAフォールバック構成。[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください。 |
| `keda.hpaName`                                           |                                                              | KEDAが作成するHPAリソースの名前。`keda-hpa-{scaled-object-name}`がデフォルトです。 |
| `keda.restoreToOriginalReplicaCount`                     |                                                              | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します。 |
| `keda.behavior`                                          |                                                              | スケールアップおよびスケールダウン動作の仕様。`hpa.behavior`がデフォルトです。 |
| `keda.triggers`                                          |                                                              | ターゲットリソースのスケールをアクティブ化するトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーがデフォルトです。 |
| `minReplicas`                                            | `2`                                                          | 最小レプリカ数 |
| `maxReplicas`                                            | `10`                                                         | 最大レプリカ数 |
| `maxUnavailable`                                         | `1`                                                          | 利用できないポッドの最大数 |
| `image.pullPolicy`                                       | `Always`                                                     | Sidekiqイメージプルポリシー |
| `image.pullSecrets`                                      |                                                              | イメージリポジトリのシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ee` | Sidekiqイメージリポジトリ |
| `image.tag`                                              |                                                              | Sidekiqイメージタグ |
| `init.image.repository`                                  |                                                              | initコンテナイメージ |
| `init.image.tag`                                         |                                                              | initコンテナイメージタグ |
| `init.containerSecurityContext`                          |                                                              | initコンテナ固有の[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                       | initコンテナ固有: コンテナを起動するユーザーID |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | initコンテナ固有: プロセスが親プロセスよりも多くの権限を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                       | initコンテナ固有: コンテナが非ルートユーザーで実行されるかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                  | initコンテナ固有: コンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `logging.format`                                         | `json`                                                       | 非JSONログの場合は`text`に設定します |
| `metrics.enabled`                                        | `true`                                                       | メトリクスエンドポイントをスクレイプに利用可能にする場合 |
| `metrics.port`                                           | `3807`                                                       | メトリクスエンドポイントのポート |
| `metrics.listenAddr`                                     | `*`                                                          | メトリクスエンドポイントのリッスンアドレス。 |
| `metrics.path`                                           | `/metrics`                                                   | メトリクスエンドポイントのパス |
| `metrics.log_enabled`                                    | `false`                                                      | `sidekiq_exporter.log`に書き込まれるメトリクスサーバーログを有効または無効にします |
| `metrics.podMonitor.enabled`                             | `false`                                                      | Prometheus Operatorがメトリクスのスクレイプを管理できるようにPodMonitorを作成する場合 |
| `metrics.podMonitor.additionalLabels`                    | `{}`                                                         | PodMonitorに追加する追加のラベル |
| `metrics.podMonitor.endpointConfig`                      | `{}`                                                         | PodMonitorの追加のエンドポイント構成 |
| `metrics.annotations`                                    |                                                              | **DEPRECATED**明示的なメトリクスアノテーションを設定します。テンプレートコンテンツに置き換えられます。 |
| `metrics.tls.enabled`                                    | `false`                                                      | `metrics/sidekiq_exporter`エンドポイントでTLSが有効になっています |
| `metrics.tls.secretName`                                 | `{Release.Name}-sidekiq-metrics-tls`                         | `metrics/sidekiq_exporter`エンドポイントTLS証明書とキーのシークレット |
| `psql.password.key`                                      | `psql-password`                                              | psqlシークレット内のpsqlパスワードへのキー |
| `psql.password.secret`                                   | `gitlab-postgres`                                            | psqlパスワードシークレット |
| `psql.port`                                              |                                                              | PostgreSQLサーバーポートを設定します。`global.psql.port`よりも優先されます。 |
| `redis.serviceName`                                      | `redis`                                                      | Redisサービス名 |
| `resources.requests.cpu`                                 | `900m`                                                       | Sidekiqの最小必要CPU |
| `resources.requests.memory`                              | `2G`                                                         | Sidekiqの最小必要メモリ |
| `resources.limits.memory`                                |                                                              | Sidekiqの最大許容メモリ |
| `timeout`                                                | `25`                                                         | Sidekiqジョブタイムアウト |
| `tolerations`                                            | `[]`                                                         | ポッド割り当てのトレランスラベル |
| `memoryKiller.daemonMode`                                | `true`                                                       | `false`の場合、レガシーメモリキラーモードを使用します |
| `memoryKiller.maxRss`                                    | `2000000`                                                    | キロバイトで表現される、遅延シャットダウンがトリガーされる前の最大RSS |
| `memoryKiller.graceTime`                                 | `900`                                                        | トリガーされたシャットダウンの前に待機する時間（秒単位） |
| `memoryKiller.shutdownWait`                              | `30`                                                         | トリガーされたシャットダウン後に既存のジョブが完了するまでの時間（秒単位） |
| `memoryKiller.hardLimitRss`                              |                                                              | デーモンモードで即時シャットダウンがトリガーされる前の最大RSS（キロバイト単位） |
| `memoryKiller.checkInterval`                             | `3`                                                          | メモリチェック間の時間量 |
| `livenessProbe.initialDelaySeconds`                      | `20`                                                         | ライブネスプローブが開始されるまでの遅延 |
| `livenessProbe.periodSeconds`                            | `60`                                                         | ライブネスプローブを実行する頻度 |
| `livenessProbe.timeoutSeconds`                           | `30`                                                         | ライブネスプローブがタイムアウトするとき |
| `livenessProbe.successThreshold`                         | `1`                                                          | ライブネスプローブが失敗した後に成功と見なされる最小連続成功数 |
| `livenessProbe.failureThreshold`                         | `3`                                                          | ライブネスプローブが成功した後に失敗したと見なされる最小連続失敗数 |
| `readinessProbe.initialDelaySeconds`                     | `0`                                                          | レディネスプローブが開始されるまでの遅延 |
| `readinessProbe.periodSeconds`                           | `10`                                                         | レディネスプローブを実行する頻度 |
| `readinessProbe.timeoutSeconds`                          | `2`                                                          | レディネスプローブがタイムアウトするとき |
| `readinessProbe.successThreshold`                        | `1`                                                          | レディネスプローブが失敗した後に成功と見なされる最小連続成功数 |
| `readinessProbe.failureThreshold`                        | `3`                                                          | レディネスプローブが成功した後に失敗したと見なされる最小連続失敗数 |
| `securityContext.fsGroup`                                | `1000`                                                       | ポッドを起動するグループID |
| `securityContext.runAsUser`                              | `1000`                                                       | ポッドを起動するユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                                              | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                             | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                              | コンテナが起動されるコンテナ[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `containerSecurityContext.runAsUser`                     | `1000`                                                       | コンテナが起動される特定のセキュリティコンテキストを上書きすることを許可します |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                      | コンテナのプロセスが親プロセスよりも多くの権限を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                       | コンテナが非ルートユーザーで実行されるかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                  | Gitalyコンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.annotations`                             | `{}`                                                         | ServiceAccountアノテーション |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                      | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                      | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                      | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                              | ServiceAccountの名前。設定されていない場合、完全なチャート名が使用されます |
| `priorityClassName`                                      | `""`                                                         | ポッドの`priorityClassName`を構成できるようにします。これは、削除の場合にポッドの優先度を制御するために使用されます。 |
| `antiAffinity`                                           | `""`                                                         | チャートグローバル値からのantiAffinity値を上書きすることを許可します。デフォルトはグローバルから読み取り込まれ、`soft`または`hard`に設定できます。 |

## チャート構成の例 {#chart-configuration-examples}

### リソース {#resources}

`resources`を使用すると、Sidekiqポッドが消費できるリソース（メモリとCPU）の最小量と最大量を構成できます。

Sidekiqポッドのワークロードは、デプロイによって大きく異なります。一般的に、各Sidekiqプロセスは約1 vCPUと2 GBのメモリを消費すると理解されています。垂直スケールは、一般的に`1:2`の`vCPU:Memory`比率に合わせるべきです。

`resources`の使用例を以下に示します。

```yaml
resources:
  limits:
    memory: 5G
  requests:
    memory: 2G
    cpu: 900m
```

### extraEnv {#extraenv}

`extraEnv`を使用して、依存関係コンテナに追加の環境変数を公開します。

たとえば、`SOME_KEY`と`SOME_OTHER_KEY`の環境変数を公開するには、次のようにします:

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

コンテナが起動したら、`env`コマンドを実行し、変数名をgrepして環境変数が公開されていることを確認します。例: 

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

特定のポッドに対して`extraEnv`を設定することもできます。例: 

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
pods:
  - name: mailers
    queues: mailers
    extraEnv:
      SOME_POD_KEY: some_pod_value
  - name: catchall
```

これにより、`mailers`ポッド内のアプリケーションコンテナにのみ`SOME_POD_KEY`が設定されます。ポッドレベルの`extraEnv`設定は、[initコンテナ](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)に追加されません。

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナで他のデータソースから追加の環境変数を公開できます。その後の変数はSidekiqポッドごとにオーバーライドできます。

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
pods:
  - name: immediate
    extraEnvFrom:
      CONFIG_STRING:
        configMapKeyRef:
          name: useful-config
          key: some-string
          # optional: boolean
```

### extraVolumes {#extravolumes}

`extraVolumes`を使用すると、チャート全体で追加ボリュームを構成できます。

`extraVolumes`の使用例を以下に示します。

```yaml
extraVolumes: |
  - name: example-volume
    persistentVolumeClaim:
      claimName: example-pvc
```

### extraVolumeMounts {#extravolumemounts}

`extraVolumeMounts`を使用すると、チャート全体のすべてのコンテナにボリュームマウントを追加構成できます。

`extraVolumeMounts`の使用例を以下に示します。

```yaml
extraVolumeMounts: |
  - name: example-volume-mount
    mountPath: /etc/example
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに対して認証し、ポッド用のイメージをプルできます。

プライベートレジストリとその認証方法に関する追加の詳細は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)で確認できます。

`pullSecrets`の使用例を以下に示します。

```yaml
image:
  repository: my.sidekiq.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountアノテーション。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定されていない場合、完全なチャート名が使用されます。 |

### トレランス {#tolerations}

`tolerations`は、汚染されたワーカーノードにポッドをスケジュールできるようにします

`tolerations`の使用例を以下に示します。

```yaml
tolerations:
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoExecute"
```

### アノテーション {#annotations}

`annotations`を使用すると、Sidekiqポッドにアノテーションを追加できます。

`annotations`の使用例を以下に示します。

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## このチャートのCommunity Editionの使用 {#using-the-community-edition-of-this-chart}

デフォルトの場合、HelmチャートではGitLabのEnterprise Editionを使用します。必要に応じて、Community Editionを使用できます。[両者の違い](https://about.gitlab.com/install/ce-or-ee/)については、こちらをご覧ください。

Community Editionを使用するには、`image.repository`を`registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ce`に設定します。

## 外部サービス {#external-services}

このチャートは、Webserviceチャートと同じRedis、PostgreSQL、およびGitalyインスタンスにアタッチする必要があります。外部サービスの値は、すべてのSidekiqポッドで共有される`ConfigMap`に入力されます。

### Redis {#redis}

```yaml
redis:
  host: rank-racoon-redis
  port: 6379
  sentinels:
    - host: sentinel1.example.com
      port: 26379
      ssl: false
  password:
    secret: gitlab-redis
    key: redis-password
```

| 名前                |  型   | デフォルト | 説明 |
|:--------------------|:-------:|:--------|:------------|
| `host`              | 文字列  |         | 使用するデータベースが格納されているRedisサーバーのホスト名。`serviceName`の代わりとして省略できます。Redis Sentinelsを使用している場合、`host`属性は`sentinel.conf`で指定されているクラスター名に設定する必要があります。 |
| `password.key`      | 文字列  |         | Redisの`password.key`属性は、パスワードを含むシークレット（下記）内のキーの名前を定義します。 |
| `password.secret`   | 文字列  |         | Redisの`password.secret`属性は、プル元のKubernetes `Secret`の名前を定義します。 |
| `port`              | 整数 | `6379`  | Redisサーバーへの接続に使用するポート。 |
| `serviceName`       | 文字列  | `redis` | Redisデータベースを操作している`service`の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名（および現在の`.Release.Name`）をテンプレート処理します。これは、RedisをGitLabチャート全体の一部として使用する場合に便利です。 |
| `sentinels.[].host` | 文字列  |         | Redis HA設定用のRedis Sentinelサーバーのホスト名。 |
| `sentinels.[].port` | 整数 | `26379` | Redis Sentinelサーバーへの接続に使用するポート。 |

> [!note]現在のRedis Sentinelサポートは、GitLabチャートとは別にデプロイされたSentinelsのみをサポートしています。そのため、`redis.install=false`に設定して、GitLabチャートによるRedisのデプロイを無効にする必要があります。GitLabチャートをデプロイする前に、Redisパスワードを含むシークレットを手動で作成する必要があります。

### PostgreSQL {#postgresql}

```yaml
psql:
  host: rank-racoon-psql
  serviceName: pgbouncer
  port: 5432
  database: gitlabhq_production
  username: gitlab
  preparedStatements: false
  password:
    secret: gitlab-postgres
    key: psql-password
```

| 名前                 |  型   | デフォルト               | 説明 |
|:---------------------|:-------:|:----------------------|:------------|
| `host`               | 文字列  |                       | 使用するデータベースを持つPostgreSQLサーバーのホスト名。`postgresql.install=true`（デフォルトは非本番環境）の場合、これは省略できます。 |
| `serviceName`        | 文字列  |                       | PostgreSQLデータベースを操作している`service`の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名をテンプレート処理します。 |
| `database`           | 文字列  | `gitlabhq_production` | PostgreSQLサーバーで使用するデータベースの名前。 |
| `password.key`       | 文字列  |                       | PostgreSQLの`password.key`属性は、パスワードを含むシークレット（下記）内のキーの名前を定義します。 |
| `password.secret`    | 文字列  |                       | PostgreSQLの`password.secret`属性は、プル元のKubernetes `Secret`の名前を定義します。 |
| `port`               | 整数 | `5432`                | PostgreSQLサーバーへの接続に使用するポート。 |
| `username`           | 文字列  | `gitlab`              | データベースへの認証に使用するユーザー名。 |
| `preparedStatements` | ブール値 | `false`               | PostgreSQLサーバーとの通信時にプリペアドステートメントを使用するかどうか。 |

Sidekiqデプロイの`dependencies` `initContainer`は、次のことを確認するスクリプトを実行します:

- GitLabの依存関係が利用可能かどうか。
- PostgreSQLのデータベース移行が実行されているかどうか。

Sidekiqチャートの`extraEnv`構成キーを使用して、これらのスクリプトの動作を制御できます。次の2つの環境変数がサポートされています:

- `BYPASS_POST_DEPLOYMENT=true`: すべての通常の移行が実行され、デプロイ後の移行のみが保留中の場合、依存関係チェックは合格します
- `BYPASS_SCHEMA_VERSION=true` (非推奨): 通常の移行が実行されていなくても、依存関係チェックは合格します。この環境変数を使用すると、データベーススキーマがアプリケーションコードデプロイが起動後にエラーが発生する可能性があります。

### Gitaly {#gitaly}

```yaml
gitaly:
  internal:
    names:
      - default
      - default2
  external:
    - name: node1
      hostname: node1.example.com
      port: 8079
  authToken:
    secret: gitaly-secret
    key: token
```

| 名前               |  型   | デフォルト  | 説明 |
|:-------------------|:-------:|:---------|:------------|
| `host`             | 文字列  |          | 使用するGitalyサーバーのホスト名。`serviceName`の代わりとして省略できます。 |
| `serviceName`      | 文字列  | `gitaly` | Gitalyサーバーを操作している`service`の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名（および現在の`.Release.Name`）をテンプレート処理します。これは、GitalyをGitLabチャート全体の一部として使用する場合に便利です。 |
| `port`             | 整数 | `8075`   | Gitalyサーバーへの接続に使用するポート。 |
| `authToken.key`    | 文字列  |          | 以下のシークレットでauthTokenを含むキーの名前。 |
| `authToken.secret` | 文字列  |          | Kubernetes `Secret`の名前をプルします。 |

## メトリクス {#metrics}

デフォルトでは、Prometheusメトリクスexporterはポッドごとに有効になっています。メトリクスは、[GitLab Prometheusメトリクス](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/)が管理者エリアで有効になっている場合にのみ利用できます。exporterは`/metrics`エンドポイントをポート`3807`で公開します。メトリクスが有効になっている場合、アノテーションが各ポッドに追加され、Prometheusサーバーが公開されたメトリクスを検出してスクレイプできるようになります。

## チャート全体のデフォルト {#chart-wide-defaults}

以下の値は、ポッドごとに値が提示されない場合、チャート全体で使用されます。

| 名前                         |  型   | デフォルト   | 説明 |
|:-----------------------------|:-------:|:----------|:------------|
| `concurrency`                | 整数 | `25`      | 同時に処理するタスクの数。 |
| `timeout`                    | 整数 | `4`       | Sidekiqシャットダウンタイムアウト。SidekiqがTERMシグナルを受け取ってから、プロセスが強制的にシャットダウンされるまでの秒数。 |
| `memoryKiller.checkInterval` | 整数 | `3`       | メモリチェック間の時間（秒単位） |
| `memoryKiller.maxRss`        | 整数 | `2000000` | キロバイトで表現される、遅延シャットダウンがトリガーされる前の最大RSS |
| `memoryKiller.graceTime`     | 整数 | `900`     | トリガーされたシャットダウンの前に待機する時間（秒単位） |
| `memoryKiller.shutdownWait`  | 整数 | `30`      | トリガーされたシャットダウン後に既存のジョブが完了するまでの時間（秒単位） |
| `minReplicas`                | 整数 | `2`       | 最小レプリカ数 |
| `maxReplicas`                | 整数 | `10`      | 最大レプリカ数 |
| `maxUnavailable`             | 整数 | `1`       | 利用できないポッドの最大数 |

> [!note] Sidekiqメモリキラーの[詳細ドキュメント](https://docs.gitlab.com/administration/sidekiq/sidekiq_memory_killer/)は、Linuxパッケージドキュメントで入手できます。

## HPAスケールの無効化 {#disable-hpa-scaling}

デフォルトでは、Sidekiqチャートは水平ポッドオートスケール（HPA）を有効にして、CPU使用率に基づいてポッドを自動的にスケールします。HPAスケールを無効にし、代わりに固定レプリカ数を使用するには、チャートレベルで`minReplicas`を`maxReplicas`と等しく設定して、すべてのポッドのHPAを無効にします:

```yaml
gitlab:
  sidekiq:
    minReplicas: 3
    maxReplicas: 3  # Setting equal to minReplicas disables HPA scaling
    concurrency: 25
    pods:
      - name: default
```

## ポッドごとの設定 {#per-pod-settings}

`pods`宣言は、ワーカーポッドのすべての属性の宣言を提供します。これらは、Sidekiqインスタンスごとに個別の`ConfigMap`とともに、`Deployment`にテンプレート化されます。

[!note]
> 設定は、すべてのキューを監視するようにセットアップされた単一のポッドを含むことをデフォルトとします。ポッドセクションに変更を加えると、*デフォルトポッドを上書きする*ことになり、別のポッド構成になります。デフォルトに加えて新しいポッドは追加されません。

| 名前                                  |  型   | デフォルト        | 説明 |
|:--------------------------------------|:-------:|:---------------|:------------|
| `concurrency`                         | 整数 |                | 同時に処理するタスクの数。提供されていない場合は、チャート全体のデフォルトからプルされます。 |
| `name`                                | 文字列  |                | このポッドの`Deployment`と`ConfigMap`に名前を付けるために使用されます。短く保ち、2つのエントリ間で重複させないでください。 |
| `queues`                              | 文字列  |                | [下記を参照](#queues)。 |
| `timeout`                             | 整数 |                | Sidekiqシャットダウンタイムアウト。SidekiqがTERMシグナルを受け取ってから、プロセスが強制的にシャットダウンされるまでの秒数。提供されていない場合は、チャート全体のデフォルトからプルされます。この値は**must**`terminationGracePeriodSeconds`より小さくなければなりません。 |
| `resources`                           |         |                | 各ポッドは独自の`resources`要件を提示できます。これは、存在する場合、そのために作成された`Deployment`に追加されます。これらはKubernetesドキュメントと一致します。 |
| `nodeSelector`                        |         |                | 各ポッドは、存在する場合、そのために作成された`Deployment`に追加される`nodeSelector`属性で構成できます。これらの定義はKubernetesドキュメントと一致します。 |
| `memoryKiller.checkInterval`          | 整数 | `3`            | メモリチェック間の時間量 |
| `memoryKiller.maxRss`                 | 整数 | `2000000`      | 特定のポッドの最大RSSをオーバーライドします。 |
| `memoryKiller.graceTime`              | 整数 | `900`          | 特定のポッドのトリガーされたシャットダウンの前に待機する時間をオーバーライドします |
| `memoryKiller.shutdownWait`           | 整数 | `30`           | 特定のポッドに対して、トリガーされたシャットダウン後に既存のジョブが完了するまでの時間をオーバーライドします |
| `minReplicas`                         | 整数 | `2`            | 最小レプリカ数 |
| `maxReplicas`                         | 整数 | `10`           | 最大レプリカ数 |
| `maxUnavailable`                      | 整数 | `1`            | 利用できないポッドの最大数 |
| `podLabels`                           |   マップ   | `{}`           | 補足ポッドラベル。セレクターには使用されません。 |
| `strategy`                            |         | `{}`           | デプロイによって利用される更新戦略を構成できます |
| `extraVolumes`                        | 文字列  |                | 特定のポッドの追加ボリュームを構成します。 |
| `extraVolumeMounts`                   | 文字列  |                | 特定のポッドの追加ボリュームマウントを構成します。 |
| `priorityClassName`                   | 文字列  | `""`           | ポッドの`priorityClassName`を構成できるようにします。これは、削除の場合にポッドの優先度を制御するために使用されます。 |
| `hpa.customMetrics`                   |  配列  | `[]`           | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で構成された平均CPU使用率のデフォルト使用をオーバーライドします）。 |
| `hpa.cpu.targetType`                  | 文字列  | `AverageValue` | オートスケールCPUターゲットタイプをオーバーライドします。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.cpu.targetAverageValue`          | 文字列  | `350m`         | オートスケールCPUターゲット値をオーバーライドします |
| `hpa.cpu.targetAverageUtilization`    | 整数 |                | オートスケールCPUターゲット使用率をオーバーライドします |
| `hpa.memory.targetType`               | 文字列  |                | オートスケールメモリターゲットタイプをオーバーライドします。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.memory.targetAverageValue`       | 文字列  |                | オートスケールメモリターゲット値をオーバーライドします |
| `hpa.memory.targetAverageUtilization` | 整数 |                | オートスケールメモリターゲット使用率をオーバーライドします |
| `hpa.targetAverageValue`              | 文字列  |                | **DEPRECATED**オートスケールCPUターゲット値をオーバーライドします |
| `keda.enabled`                        | ブール値 | `false`        | KEDAの有効化をオーバーライドします |
| `keda.pollingInterval`                | 整数 | `30`           | KEDAのポーリングの間隔をオーバーライドします |
| `keda.cooldownPeriod`                 | 整数 | `300`          | KEDAのクールダウン期間をオーバーライドします |
| `keda.minReplicaCount`                | 整数 |                | KEDAの最小レプリカ数をオーバーライドします |
| `keda.maxReplicaCount`                | 整数 |                | KEDAの最大レプリカ数をオーバーライドします |
| `keda.fallback`                       |   マップ   |                | KEDAフォールバック構成をオーバーライドします |
| `keda.hpaName`                        | 文字列  |                | KEDA HPA名をオーバーライドします |
| `keda.restoreToOriginalReplicaCount`  | ブール値 |                | 元のレプリカ数の復元を有効にすることをオーバーライドします |
| `keda.behavior`                       |   マップ   |                | KEDA HPA動作をオーバーライドします |
| `keda.triggers`                       |  配列  |                | KEDAトリガーをオーバーライドします |
| `extraEnv`                            |   マップ   |                | 公開する追加の環境変数のリスト。チャート全体の値がこれにマージされ、ポッドからの値が優先されます |
| `extraEnvFrom`                        |   マップ   |                | 他のデータソースから公開する追加の環境変数のリスト |
| `terminationGracePeriodSeconds`       | 整数 | `30`           | ポッドが正常に終了するために必要なオプションの時間（秒単位）。 |

### キュー {#queues}

`queues`値は、処理されるキューのコンマ区切りリストを含む文字列です。デフォルトでは、すべてのキューが処理されることを意味し、設定されていません。

文字列にはスペースを含めないでください。`merge,post_receive,process_commit`は機能しますが、`merge, post_receive, process_commit`は機能しません。

ジョブが追加されたが、少なくとも1つのポッドエントリの一部として表現されていないキューは、*処理されません*。すべてのキューの完全なリストについては、GitLabソースのこれらのファイルを参照してください:

1. [`app/workers/all_queues.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/all_queues.yml)
1. [`ee/app/workers/all_queues.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/all_queues.yml)

`gitlab.sidekiq.pods[].queues`を構成することに加えて、`global.appConfig.sidekiq.routingRules`も構成する必要があります。詳細については、[Sidekiqルーティングルール設定](../../globals.md#sidekiq-routing-rules-settings)を参照してください。

### 例`pod`エントリ {#example-pod-entry}

```yaml
pods:
  - name: immediate
    concurrency: 10
    minReplicas: 2  # defaults to inherited value
    maxReplicas: 10 # defaults to inherited value
    maxUnavailable: 5 # defaults to inherited value
    queues: merge,post_receive,process_commit
    extraVolumeMounts: |
      - name: example-volume-mount
        mountPath: /etc/example
    extraVolumes: |
      - name: example-volume
        persistentVolumeClaim:
          claimName: example-pvc
    resources:
      limits:
        cpu: 800m
        memory: 2Gi
    hpa:
      cpu:
        targetType: Value
        targetAverageValue: 350m
```

### Sidekiq構成の完全な例 {#full-example-of-sidekiq-configuration}

以下は、別のSidekiqポッドをインポート関連のジョブに、別のRedisインスタンスを使用したエクスポート関連のジョブに、そして別のポッドをその他すべてに使用するSidekiq構成の完全な例です。

```yaml
...
global:
  appConfig:
    sidekiq:
      routingRules:
      - ["feature_category=importers", "import"]
      - ["feature_category=exporters", "export", "queues_shard_extra_shard"]
      - ["*", "default"]
  redis:
    redisYmlOverride:
      queues_shard_extra_shard: ...
...
gitlab:
  sidekiq:
    pods:
    - name: import
      queues: import
    - name: export
      queues: export
      extraEnv:
        SIDEKIQ_SHARD_NAME: queues_shard_extra_shard # to match key in global.redis.redisYmlOverride
    - name: default
...
```

## `networkpolicy`の構成 {#configuring-the-networkpolicy}

このセクションでは、[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を制御します。この構成はオプションであり、ポッドのエグレスとIngressを特定のエンドポイントに制限するために使用されます。

| 名前              |  型   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | この設定はネットワークポリシーを有効にします |
| `ingress.enabled` | ブール値 | `false` | `true`に設定すると、`Ingress`ネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのIngress接続がブロックされます。 |
| `ingress.rules`   |  配列  | `[]`    | Ingressポリシーのルール。詳細は<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください |
| `egress.enabled`  | ブール値 | `false` | `true`に設定すると、`Egress`ネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのエグレス接続がブロックされます。 |
| `egress.rules`    |  配列  | `[]`    | エグレスポリシーのルール。詳細は<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください |

### ネットワークポリシーの例 {#example-network-policy}

Sidekiqサービスは、有効になっている場合はPrometheus exporterのみのIngress接続を必要とし、通常はさまざまな場所へのエグレス接続を必要とします。この例では、次のネットワークポリシーを追加します:

- Ingressリクエストを許可します:
  - `Prometheus`ポッドからポート`3807`へ
- エグレスリクエストを許可します:
  - `kube-dns`からポート`53`へ
  - `gitaly`ポッドからポート`8075`へ
  - `registry`ポッドからポート`5000`へ
  - `kas`ポッドからポート`8153`へ
  - 外部データベース`172.16.0.10/32`からポート`5432`へ
  - 外部Redis `172.16.0.11/32`からポート`6379`へ
  - 外部Elasticsearch `172.16.0.12/32`からポート`443`へ
  - メールゲートウェイ`172.16.0.13/32`からポート`587`へ
  - AWS VPCエンドポイント（S3またはSTS用）`172.16.1.0/24`からポート`443`へ
  - 内部サブネット`172.16.2.0/24`からポート`443`へWebhookを送信します

提供されている例はあくまで例であり、完全ではない可能性があります。Sidekiqサービスは、ローカルエンドポイントが利用できない場合、[外部オブジェクトストレージ](../../../advanced/external-object-storage)上のイメージに対してパブリックインターネットへの送信接続を必要とします。この例は、`kube-dns`が`kube-system`ネームスペースにデプロイされ、`prometheus`が`monitoring`ネームスペースにデプロイされ、`nginx-ingress`が`nginx-ingress`ネームスペースにデプロイされたという前提に基づいています。

```yaml
networkpolicy:
  enabled: true
  ingress:
    enabled: true
    rules:
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: monitoring
            podSelector:
              matchLabels:
                app: prometheus
                component: server
                release: gitlab
        ports:
          - port: 3807
  egress:
    enabled: true
    rules:
      - to:
          - podSelector:
              matchLabels:
                app: gitaly
        ports:
          - port: 8075
      - to:
          - podSelector:
              matchLabels:
                app: kas
        ports:
          - port: 8153
      - to:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: kube-system
            podSelector:
              matchLabels:
                k8s-app: kube-dns
        ports:
          - port: 53
            protocol: UDP
      - to:
          - ipBlock:
              cidr: 172.16.0.10/32
        ports:
          - port: 5432
      - to:
          - ipBlock:
              cidr: 172.16.0.11/32
        ports:
          - port: 6379
      - to:
          - ipBlock:
              cidr: 172.16.0.12/32
        ports:
          - port: 25
      - to:
          - ipBlock:
              cidr: 172.16.0.13/32
        ports:
          - port: 443
      - to:
          - ipBlock:
              cidr: 172.16.1.0/24
        ports:
          - port: 443
      - to:
          - ipBlock:
              cidr: 172.16.2.0/24
        ports:
          - port: 443
```

## KEDAの構成 {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この構成はオプションであり、カスタムメトリクスまたは外部メトリクスに基づくオートスケールが必要な場合に使用できます。

ほとんどの設定は、適用可能な場合は`hpa`セクションで設定された値にデフォルト設定されます。

以下が真の場合、CPUおよびメモリのトリガーは、`hpa`セクションで設定されたCPUおよびメモリのしきい値に基づいて自動的に追加されます:

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定もゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの設定の詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  型   | デフォルト | 説明 |
|:--------------------------------|:-------:|:--------|:------------|
| `enabled`                       | ブール値 | `false` | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`    | 各トリガーを確認する間隔 |
| `cooldownPeriod`                | 整数 | `300`   | 最後にアクティブと報告されたトリガーの後、リソースを0にスケールダウンするまでの待機期間 |
| `minReplicaCount`               | 整数 |         | KEDAがリソースをスケールダウンする最小レプリカ数。`minReplicas`がデフォルトです。 |
| `maxReplicaCount`               | 整数 |         | KEDAがリソースをスケールアップする最大レプリカ数。`maxReplicas`がデフォルトです。 |
| `fallback`                      |   マップ   |         | KEDAフォールバック構成。[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください。 |
| `hpaName`                       | 文字列  |         | KEDAが作成するHPAリソースの名前。`keda-hpa-{scaled-object-name}`がデフォルトです。 |
| `restoreToOriginalReplicaCount` | ブール値 |         | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します。 |
| `behavior`                      |   マップ   |         | スケールアップおよびスケールダウン動作の仕様。`hpa.behavior`がデフォルトです。 |
| `triggers`                      |  配列  |         | ターゲットリソースのスケールをアクティブ化するトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーがデフォルトです。 |
