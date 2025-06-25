---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-Sidekiqチャートの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 製品:GitLab Self-Managed

{{< /details >}}

`sidekiq`サブチャートは、Sidekiqワーカーの構成可能なデプロイメントを提供します。これは、個々のスケーラビリティと構成を備えた複数の`Deployment`にわたるキューの分離を提供するように明示的に設計されています。

このチャートはデフォルトの`pods:`宣言を提供しますが、空の定義を提供すると、ワーカーは*ありません*。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされるKubernetesクラスターから到達可能な外部サービスとして、Redis、PostgreSQL、およびGitalyサービスへのアクセスに依存します。

## 設計上の選択 {#design-choices}

このチャートは、複数の`Deployment`と関連する`ConfigMap`を作成します。コマンド長に関する懸念を回避するために、コンテナの`command`への`environment`属性または追加の引数を使用する代わりに、`ConfigMap`の動作を利用する方が明確であると判断されました。この選択により、多数の`ConfigMap`が作成されますが、各ポッドが何をする必要があるかについて非常に明確な定義が提供されます。

## 設定 {#configuration}

`sidekiq`チャートは、チャート全体の[外部サービス](#external-services)、[チャート全体のデフォルト](#chart-wide-defaults)、および[ポッドごとの定義](#per-pod-settings)の3つの部分で構成されています。

## インストールコマンドラインオプション {#installation-command-line-options}

以下の表に、`--set`フラグを使用して`helm install`コマンドに指定できるすべての可能なチャート設定を示します。

| パラメータ                                                | デフォルト                                                      | 説明 |
|----------------------------------------------------------|--------------------------------------------------------------|-------------|
| `annotations`                                            |                                                              | ポッドアノテーション |
| `podLabels`                                              |                                                              | 補足的なポッドラベル。セレクターには使用されません。 |
| `common.labels`                                          |                                                              | このチャートによって作成されたすべてのオブジェクトに適用される補足ラベル。 |
| `concurrency`                                            | `20`                                                         | Sidekiqのデフォルトの並行処理 |
| `deployment.strategy`                                    | `{}`                                                         | デプロイメントで使用される更新戦略を構成できます |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                         | ポッドが正常に終了するために必要なオプションの秒単位の時間。 |
| `enabled`                                                | `true`                                                       | Sidekiqが有効なフラグ |
| `extraContainers`                                        |                                                              | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列 |
| `extraInitContainers`                                    |                                                              | 含める追加のinitコンテナのリスト |
| `extraVolumeMounts`                                      |                                                              | 構成する追加のボリュームマウントの文字列テンプレート |
| `extraVolumes`                                           |                                                              | 構成する追加のボリュームの文字列テンプレート |
| `extraEnv`                                               |                                                              | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                              | 公開する他のデータソースからの追加の環境変数のリスト |
| `gitaly.serviceName`                                     | `gitaly`                                                     | Gitalyサービス名 |
| `health_checks.port`                                     | `3808`                                                       | ヘルスチェックサーバーのポート |
| `hpa.behaviour`                                          | `{scaleDown: {stabilizationWindowSeconds: 300 }}`            | Behaviorには、アップスケールとダウンスケールの動作の仕様が含まれています（`autoscaling/v2beta2`以上が必要です）。 |
| `hpa.customMetrics`                                      | `[]`                                                         | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で構成された平均CPU使用率のデフォルトの使用を上書きします）。 |
| `hpa.cpu.targetType`                                     | `AverageValue`                                               | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`                             | `350m`                                                       | オートスケールCPUターゲット値を設定します |
| `hpa.cpu.targetAverageUtilization`                       |                                                              | オートスケールCPUターゲット使用率を設定します |
| `hpa.memory.targetType`                                  |                                                              | オートスケールメモリーターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`                          |                                                              | オートスケールメモリーターゲット値を設定します |
| `hpa.memory.targetAverageUtilization`                    |                                                              | オートスケールメモリーターゲット使用率を設定します |
| `hpa.targetAverageValue`                                 |                                                              | **非推奨**オートスケールCPUターゲット値を設定します |
| `keda.enabled`                                           | `false`                                                      | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                   | `30`                                                         | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                                    | `300`                                                        | 最後のアクティブと報告されたトリガーの後にリソースを0にスケールバックするまで待機する期間 |
| `keda.minReplicaCount`                                   |                                                              | KEDAがリソースをスケールダウンする最小レプリカ数。デフォルトは`minReplicas`です |
| `keda.maxReplicaCount`                                   |                                                              | KEDAがリソースをスケールアップする最大レプリカ数。デフォルトは`maxReplicas`です |
| `keda.fallback`                                          |                                                              | KEDAフォールバック構成。ドキュメント[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                           |                                                              | KEDAが作成するHPAリソースの名前。デフォルトは`keda-hpa-{scaled-object-name}`です |
| `keda.restoreToOriginalReplicaCount`                     |                                                              | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                          |                                                              | アップスケールとダウンスケールの動作の仕様。デフォルトは`hpa.behavior`です |
| `keda.triggers`                                          |                                                              | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。デフォルトは、`hpa.cpu`および`hpa.memory`から計算されたトリガーです |
| `minReplicas`                                            | `2`                                                          | レプリカの最小数 |
| `maxReplicas`                                            | `10`                                                         | レプリカの最大数 |
| `maxUnavailable`                                         | `1`                                                          | 使用できないポッドの最大数の制限 |
| `image.pullPolicy`                                       | `Always`                                                     | Sidekiqイメージのプルポリシー |
| `image.pullSecrets`                                      |                                                              | イメージリポジトリのシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ee` | Sidekiqイメージリポジトリ |
| `image.tag`                                              |                                                              | Sidekiqイメージタグ |
| `init.image.repository`                                  |                                                              | initContainerイメージ |
| `init.image.tag`                                         |                                                              | initContainerイメージタグ |
| `init.containerSecurityContext`                          |                                                              | initContainer固有の[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                       | initContainer固有:コンテナを開始するユーザーID |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | initContainer固有:プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                       | initContainer固有:コンテナをroot以外のユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                  | initContainer固有:コンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `logging.format`                                         | `json`                                                       | JSON以外のログの場合は`text`に設定します |
| `metrics.enabled`                                        | `true`                                                       | スクレイピングに使用できるメトリクスエンドポイントを作成する必要がある場合 |
| `metrics.port`                                           | `3807`                                                       | メトリクスエンドポイントポート |
| `metrics.path`                                           | `/metrics`                                                   | メトリクスエンドポイントのパス |
| `metrics.log_enabled`                                    | `false`                                                      | `sidekiq_exporter.log`に書き込まれたメトリクスサーバーログを有効または無効にします |
| `metrics.podMonitor.enabled`                             | `false`                                                      | Prometheus Operatorがメトリクスのスクレイピングを管理できるようにするために、PodMonitorを作成する必要がある場合 |
| `metrics.podMonitor.additionalLabels`                    | `{}`                                                         | PodMonitorに追加する追加のラベル |
| `metrics.podMonitor.endpointConfig`                      | `{}`                                                         | PodMonitorの追加のエンドポイント構成 |
| `metrics.annotations`                                    |                                                              | **非推奨**明示的なメトリクスアノテーションを設定します。テンプレートコンテンツに置き換えられました。 |
| `metrics.tls.enabled`                                    | `false`                                                      | `metrics/sidekiq_exporter`エンドポイントに対してTLSが有効になっています |
| `metrics.tls.secretName`                                 | `{Release.Name}-sidekiq-metrics-tls`                         | `metrics/sidekiq_exporter`エンドポイントTLS証明書とキーのシークレット |
| `psql.password.key`                                      | `psql-password`                                              | psqlシークレットのpsqlパスワードへのキー |
| `psql.password.secret`                                   | `gitlab-postgres`                                            | psqlパスワードシークレット |
| `psql.port`                                              |                                                              | PostgreSQLサーバーポートを設定します。`global.psql.port`よりも優先されます |
| `redis.serviceName`                                      | `redis`                                                      | Redisサービス名 |
| `resources.requests.cpu`                                 | `900m`                                                       | Sidekiqに必要な最小CPU |
| `resources.requests.memory`                              | `2G`                                                         | Sidekiqに必要な最小限のメモリ |
| `resources.limits.memory`                                |                                                              | Sidekiqが許可する最大メモリ |
| `timeout`                                                | `25`                                                         | Sidekiqジョブのタイムアウト |
| `tolerations`                                            | `[]`                                                         | ポッド割り当ての容認ラベル |
| `memoryKiller.daemonMode`                                | `true`                                                       | `false`の場合、レガシーメモリーキラーモードを使用します |
| `memoryKiller.maxRss`                                    | `2000000`                                                    | 遅延シャットダウンがトリガーされる前の最大RSS（キロバイト単位） |
| `memoryKiller.graceTime`                                 | `900`                                                        | トリガーされたシャットダウン前に待機する時間（秒単位） |
| `memoryKiller.shutdownWait`                              | `30`                                                         | 既存のジョブが終了するために、トリガーされたシャットダウン後に経過する時間（秒単位） |
| `memoryKiller.hardLimitRss`                              |                                                              | デーモンモードで即時シャットダウンがトリガーされる前の最大RSS（キロバイト単位） |
| `memoryKiller.checkInterval`                             | `3`                                                          | メモリーチェック間の時間 |
| `livenessProbe.initialDelaySeconds`                      | `20`                                                         | 活性プローブが開始されるまでの遅延 |
| `livenessProbe.periodSeconds`                            | `60`                                                         | 活性プローブを実行する頻度 |
| `livenessProbe.timeoutSeconds`                           | `30`                                                         | 活性プローブがタイムアウトするタイミング |
| `livenessProbe.successThreshold`                         | `1`                                                          | 失敗後に活性プローブが成功したと見なされるための最小連続成功数 |
| `livenessProbe.failureThreshold`                         | `3`                                                          | 成功後に活性プローブが失敗したと見なされるための最小連続失敗数 |
| `readinessProbe.initialDelaySeconds`                     | `0`                                                          | 準備プローブが開始されるまでの遅延 |
| `readinessProbe.periodSeconds`                           | `10`                                                         | 準備プローブを実行する頻度 |
| `readinessProbe.timeoutSeconds`                          | `2`                                                          | 準備プローブがタイムアウトするタイミング |
| `readinessProbe.successThreshold`                        | `1`                                                          | 失敗後に準備プローブが成功したと見なされるための最小連続成功数 |
| `readinessProbe.failureThreshold`                        | `3`                                                          | 成功後に準備プローブが失敗したと見なされるための最小連続失敗数 |
| `securityContext.fsGroup`                                | `1000`                                                       | ポッドを開始するグループID |
| `securityContext.runAsUser`                              | `1000`                                                       | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                                              | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                             | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                              | コンテナの開始に使用されるオーバーライドコンテナ[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `containerSecurityContext.runAsUser`                     | `1000`                                                       | コンテナの開始に使用される特定のセキュリティコンテキストを上書きできます |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                      | コンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                       | コンテナをroot以外のユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                  | Gitalyコンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.annotations`                             | `{}`                                                         | ServiceAccountアノテーション |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                      | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                      | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                      | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                              | ServiceAccountの名前。設定されていない場合、完全なチャート名が使用されます |
| `priorityClassName`                                      | `""`                                                         | ポッドの`priorityClassName`の設定を許可します。これは、削除の場合にポッドの優先度を制御するために使用されます |

## チャート設定の例 {#chart-configuration-examples}

### リソース {#resources}

`resources`を使用すると、Sidekiqポッドが消費できるリソース（メモリーと仮想CPU）の最小量と最大量を構成できます。

Sidekiqポッドのワークロードは、デプロイメントによって大きく異なります。一般的に言って、各Sidekiqプロセスは約1つの仮想CPUと2 GiBのメモリーを消費すると理解されています。垂直方向のスケーリングは、通常、この`vCPU:Memory`の`1:2`比率に合わせる必要があります。

以下は、`resources`の使用例です:

```yaml
resources:
  limits:
    memory: 5G
  requests:
    memory: 2G
    cpu: 900m
```

### extraEnv {#extraenv}

`extraEnv`を使用すると、依存関係コンテナに追加の環境変数を公開できます。

以下は、`extraEnv`の使用例です:

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

コンテナの起動時に、環境変数が公開されていることを確認できます:

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

特定のポッドに対して`extraEnv`を設定することもできます:

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

これにより、`mailers`ポッド内のアプリケーションコンテナに対してのみ`SOME_POD_KEY`が設定されます。ポッドレベルの`extraEnv`設定は、[initコンテナ](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)に追加されません。

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナ内の他のデータソースから追加の環境変数を公開できます。後続の変数は、Sidekiqポッドごとに上書きできます。

以下は、`extraEnvFrom`の使用例です:

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

`extraVolumes`を使用すると、チャート全体の追加ボリュームを構成できます。

以下は、`extraVolumes`の使用例です:

```yaml
extraVolumes: |
  - name: example-volume
    persistentVolumeClaim:
      claimName: example-pvc
```

### extraVolumeMounts {#extravolumemounts}

`extraVolumeMounts`を使用すると、チャート全体のすべてのコンテナで追加のvolumeMountsを構成できます。

以下は、`extraVolumeMounts`の使用例です:

```yaml
extraVolumeMounts: |
  - name: example-volume-mount
    mountPath: /etc/example
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに対して認証して、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法の詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)を参照してください。

以下は、`pullSecrets`の使用例です:

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

| 名前                           |  タイプ   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountアノテーション。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。特定のサイドカーが適切に動作するために必要な場合を除き、これは有効にしないでください（たとえば、Istio）。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定されていない場合、完全なチャート名が使用されます。 |

### 許容 {#tolerations}

`tolerations`を使用すると、tainted workerノードでポッドをスケジュールできます

以下は、`tolerations`の使用例です:

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

以下は、`annotations`の使用例です:

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## このチャートのCommunity Editionの使用 {#using-the-community-edition-of-this-chart}

デフォルトでは、HelmチャートはGitLab Enterprise Editionを使用します。必要に応じて、代わりにCommunity Editionを使用できます。[2つの違い](https://about.gitlab.com/install/ce-or-ee/)について詳しくはこちらをご覧ください。

Community Editionを使用するには、`image.repository`を`registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ce`に設定します。

## 外部サービス {#external-services}

このチャートは、Webサービスチャートと同じRedis、PostgreSQL、およびGitalyインスタンスにアタッチする必要があります。外部サービスの値は、すべてのSidekiqポッド間で共有される`ConfigMap`に入力されます。

### Redis {#redis}

```yaml
redis:
  host: rank-racoon-redis
  port: 6379
  sentinels:
    - host: sentinel1.example.com
      port: 26379
  password:
    secret: gitlab-redis
    key: redis-password
```

| 名前                |  タイプ   | デフォルト | 説明 |
|:--------------------|:-------:|:--------|:------------|
| `host`              | 文字列  |         | 使用するデータベースを持つRedisサーバーのホスト名。これは、`serviceName`の代わりに使用できます。Redis Sentinelを使用している場合、`host`属性は、`sentinel.conf`で指定されているクラスター名に設定する必要があります。 |
| `password.key`      | 文字列  |         | Redisの`password.key`属性は、パスワードを含むシークレット（下記）のキーの名前を定義します。 |
| `password.secret`   | 文字列  |         | Redisの`password.secret`属性は、プル元のKubernetes `Secret`の名前を定義します。 |
| `port`              | 整数 | `6379`  | Redisサーバーに接続するポート。 |
| `serviceName`       | 文字列  | `redis` | Redisデータベースを操作している`service`の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービス（および現在の`.Release.Name`）のホスト名をテンプレート化します。これは、RedisをGitLabチャート全体の一部として使用する場合に便利です。 |
| `sentinels.[].host` | 文字列  |         | Redis HAセットアップ用のRedis Sentinelサーバーのホスト名。 |
| `sentinels.[].port` | 整数 | `26379` | Redis Sentinelサーバーに接続するポート。 |

{{< alert type="note" >}}

現在のRedis Sentinelサポートは、GitLabチャートとは別にデプロイされたSentinelのみをサポートします。その結果、GitLabチャートを介したRedisのデプロイメントは、`redis.install=false`で無効にする必要があります。Redisパスワードを含むシークレットは、GitLabチャートをデプロイする前に手動で作成する必要があります。

{{< /alert >}}

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

| 名前                 |  タイプ   | デフォルト               | 説明 |
|:---------------------|:-------:|:----------------------|:------------|
| `host`               | 文字列  |                       | 使用するデータベースを持つPostgreSQLサーバーのホスト名。これは、`postgresql.install=true`（デフォルトの非本番環境）の場合に省略できます。 |
| `serviceName`        | 文字列  |                       | PostgreSQLデータベースを操作している`service`の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名をテンプレート化します。 |
| `database`           | 文字列  | `gitlabhq_production` | PostgreSQLサーバーで使用するデータベースの名前。 |
| `password.key`       | 文字列  |                       | PostgreSQLの`password.key`属性は、パスワードを含むシークレット内のキーの名前を定義します（下記参照）。 |
| `password.secret`    | 文字列  |                       | PostgreSQLの`password.secret`属性は、プル元のKubernetes `Secret`の名前を定義します。 |
| `port`               | 整数 | `5432`                | PostgreSQLサーバーへの接続に使用するポート。 |
| `username`           | 文字列  | `gitlab`              | データベースへの認証に使用するユーザー名。 |
| `preparedStatements` | ブール値 | `false`               | PostgreSQLサーバーとの通信時にプリペアドステートメントを使用するかどうか。 |

### Gitaly {#gitaly}

```YAML
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

| 名前               |  種類   | デフォルト  | 説明 |
|:-------------------|:-------:|:---------|:------------|
| `host`             | 文字列  |          | 使用するGitalyサーバー のホスト名。これは、`serviceName`の代わり省略できます。 |
| `serviceName`      | 文字列  | `gitaly` | Gitalyサーバーを操作している`service`の名前。これが存在し、`host`が存在しない場合、このチャートは`host`値の代わりに、サービス（および現在の`.Release.Name`）のホスト名をテンプレート化します。これは、GitLabチャート全体の一部としてGitalyを使用する場合に便利です。 |
| `port`             | 整数 | `8075`   | Gitalyサーバーへの接続に使用するポート。 |
| `authToken.key`    | 文字列  |          | authTokenを含む以下のシークレット内のキーの名前。 |
| `authToken.secret` | 文字列  |          | プル元のKubernetes `Secret`の名前。 |

## メトリクス {#metrics}

デフォルトでは、Prometheusメトリクスのexporterがポッドごとに有効になっています。[GitLab Prometheusメトリクス](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/)が管理者エリアで有効になっている場合にのみ、メトリクスを使用できます。exporterは、ポート`3807`の`/metrics`エンドポイントを公開します。メトリクスが有効になっている場合、Prometheusサーバーが公開されたメトリクスを検出してスクレイピングできるように、各ポッドにアノテーションが追加されます。

## チャート全体のデフォルト {#chart-wide-defaults}

以下の値は、ポッドごとに値が表示されない場合に、チャート全体で使用されます。

| 名前                         |  種類   | デフォルト   | 説明 |
|:-----------------------------|:-------:|:----------|:------------|
| `concurrency`                | 整数 | `25`      | 同時に処理するタスク数。 |
| `timeout`                    | 整数 | `4`       | Sidekiqのシャットダウン・タイムアウト。SidekiqがTERMシグナルを受信してから、プロセスを強制的にシャットダウンするまでの秒数。 |
| `memoryKiller.checkInterval` | 整数 | `3`       | メモリーチェックの間隔（秒単位） |
| `memoryKiller.maxRss`        | 整数 | `2000000` | 遅延シャットダウンがトリガーされる前の最大RSS（キロバイト単位） |
| `memoryKiller.graceTime`     | 整数 | `900`     | トリガーされたシャットダウンの前に待機する時間（秒単位） |
| `memoryKiller.shutdownWait`  | 整数 | `30`      | トリガーされたシャットダウン後に既存のジョブが完了するまでの時間（秒単位） |
| `minReplicas`                | 整数 | `2`       | レプリカの最小数 |
| `maxReplicas`                | 整数 | `10`      | レプリカの最大数 |
| `maxUnavailable`             | 整数 | `1`       | 利用できなくなるポッドの最大数の制限 |

{{< alert type="note" >}}

[Sidekiqメモリーキラーの詳細なドキュメント](https://docs.gitlab.com/administration/sidekiq/sidekiq_memory_killer/)は、Linuxパッケージのドキュメントにあります。

{{< /alert >}}

## ポッドごとの設定 {#per-pod-settings}

`pods`宣言は、workerポッドのすべての属性の宣言を提供します。これらは`Deployment`にテンプレート化され、Sidekiqインスタンス用に個別の`ConfigMap`が設定されます。

{{< alert type="note" >}}

設定はデフォルトで、すべてのキューを監視するように設定された単一のポッドが含まれます。podsセクションを変更すると、異なるポッド構成で*デフォルトのポッドが上書き*されます。デフォルトに加えて、新しいポッドが追加されることはありません。

{{< /alert >}}

| 名前                                  |  種類   | デフォルト        | 説明 |
|:--------------------------------------|:-------:|:---------------|:------------|
| `concurrency`                         | 整数 |                | 同時に処理するタスク数。指定されていない場合、チャート全体のデフォルトからプルされます。 |
| `name`                                | 文字列  |                | このポッドの`Deployment`と`ConfigMap`の命名に使用されます。短く保ち、2つのエントリ間で複製しないでください。 |
| `queues`                              | 文字列  |                | [下記参照](#queues)。 |
| `timeout`                             | 整数 |                | Sidekiqのシャットダウン・タイムアウト。SidekiqがTERMシグナルを受信してから、プロセスを強制的にシャットダウンするまでの秒数。指定されていない場合、チャート全体のデフォルトからプルされます。この値は、`terminationGracePeriodSeconds`より**小さく**する必要があります。 |
| `resources`                           |         |                | 各ポッドは独自の`resources`要件を示すことができ、存在する場合、これはそのために作成された`Deployment`に追加されます。これらは、Kubernetesドキュメントと一致します。 |
| `nodeSelector`                        |         |                | 各ポッドは`nodeSelector`属性で構成でき、存在する場合、そのために作成された`Deployment`に追加されます。これらの定義はKubernetesドキュメントと一致します。 |
| `memoryKiller.checkInterval`          | 整数 | `3`            | メモリーチェックの間隔 |
| `memoryKiller.maxRss`                 | 整数 | `2000000`      | 特定のポッドの最大RSSをオーバーライドします。 |
| `memoryKiller.graceTime`              | 整数 | `900`          | 特定のポッドでトリガーされたシャットダウンの前に待機する時間をオーバーライドします |
| `memoryKiller.shutdownWait`           | 整数 | `30`           | 特定のポッドでトリガーされたシャットダウン後に既存のジョブを完了するまでの時間をオーバーライドします |
| `minReplicas`                         | 整数 | `2`            | レプリカの最小数 |
| `maxReplicas`                         | 整数 | `10`           | レプリカの最大数 |
| `maxUnavailable`                      | 整数 | `1`            | 利用できなくなるポッドの最大数の制限 |
| `podLabels`                           |   マップ   | `{}`           | 補足的なポッドのラベル。セレクターには使用されません。 |
| `strategy`                            |         | `{}`           | デプロイで使用される更新ストラテジを設定できます |
| `extraVolumes`                        | 文字列  |                | 指定されたポッドの追加ボリュームを構成します。 |
| `extraVolumeMounts`                   | 文字列  |                | 指定されたポッドの追加ボリュームマウントを構成します。 |
| `priorityClassName`                   | 文字列  | `""`           | ポッドの`priorityClassName`の設定を許可します。これは、立ち退きが発生した場合にポッドの優先度を制御するために使用されます |
| `hpa.customMetrics`                   |  配列  | `[]`           | カスタム メトリクスには、必要なレプリカ数を計算するために使用するが含まれます（`targetAverageUtilization`で構成された平均CPU使用率のデフォルトの使用を上書きします） |
| `hpa.cpu.targetType`                  | 文字列  | `AverageValue` | オートスケールCPUのターゲットをオーバーライドします。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`          | 文字列  | `350m`         | オートスケールCPUのターゲット値を上書きします |
| `hpa.cpu.targetAverageUtilization`    | 整数 |                | オートスケールCPUのターゲット使用率をオーバーライドします |
| `hpa.memory.targetType`               | 文字列  |                | オートスケールメモリーのターゲットをオーバーライドします。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`       | 文字列  |                | オートスケールメモリーのターゲット値を上書きします |
| `hpa.memory.targetAverageUtilization` | 整数 |                | オートスケールメモリーのターゲット使用率を上書きします |
| `hpa.targetAverageValue`              | 文字列  |                | **非推奨**オートスケールCPUのターゲット値を上書きします |
| `keda.enabled`                        | ブール値 | `false`        | KEDAの有効化をオーバーライドします |
| `keda.pollingInterval`                | 整数 | `30`           | KEDAポーリングの間隔をオーバーライドします |
| `keda.cooldownPeriod`                 | 整数 | `300`          | KEDAのクールダウン期間をオーバーライドします |
| `keda.minReplicaCount`                | 整数 |                | KEDAがリソースをスケールダウンする最小レプリカ数をオーバーライドします。デフォルトはです |
| `keda.maxReplicaCount`                | 整数 |                | KEDAがリソースをスケールアップする最大レプリカ数をオーバーライドします。デフォルトはです |
| `keda.fallback`                       |   マップ   |                | KEDAフォールバックをオーバーライドします。ドキュメントを参照してください |
| `keda.hpaName`                        | 文字列  |                | KEDAが作成するHPAリソースの名前をオーバーライドします。デフォルトはです |
| `keda.restoreToOriginalReplicaCount`  | ブール値 |                | が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                       |   マップ   |                | アップスケールとダウンスケールのの。デフォルトはです |
| `keda.triggers`                       |  配列  |                | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。デフォルトはとから計算されたトリガーです |
| `extraEnv`                            |   マップ   |                | 公開する追加の環境変数のリスト。チャート全体のがこれにマージされ、ポッドからのが優先されます |
| `extraEnvFrom`                        |   マップ   |                | 公開する他のデータソースからの追加の環境変数のリスト |
| `terminationGracePeriodSeconds`       | 整数 | `30`           | ポッドが正常に終了するために必要なオプションの秒単位の期間。 |

### キュー {#queues}

`queues`値は、処理されるキューのコンマ区切りリストを含む文字列です。デフォルトでは設定されておらず、すべてのキューが処理されることを意味します。

文字列にスペースを含めないでください。`merge,post_receive,process_commit`は機能しますが、`merge, post_receive, process_commit`は機能しません。

ジョブが追加されたが、少なくとも1つのポッドアイテムの一部として表されていないキューは*処理されません*。すべてのキューの完全なリストについては、GitLabソースのこれらのファイルを参照してください。

1. [`app/workers/all_queues.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/all_queues.yml)
1. [`ee/app/workers/all_queues.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/all_queues.yml)

`gitlab.sidekiq.pods[].queues`の設定に加えて、`global.appConfig.sidekiq.routingRules`も設定する必要があります。詳細については、[Sidekiqルーティング ルール設定](../../globals.md#sidekiq-routing-rules-settings)を参照してください。

### `pod`エントリの例 {#example-pod-entry}

```YAML
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

### Sidekiqの完全な例 {#full-example-of-sidekiq-configuration}

以下は、インポート関連のジョブ用の個別のSidekiqポッド、個別のRedisインスタンスを使用するエクスポート関連のジョブ用のSidekiqポッド、およびその他すべてのジョブ用の別のポッドを使用した、Sidekiqの完全な例です。

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

## `networkpolicy`の設定 {#configuring-the-networkpolicy}

このセクションでは、[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を制御します。このはオプションであり、ポッドのエグレスとIngressを特定のエンドポイントに制限するために使用されます。

| 名前              |  種類   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | この設定により、ネットワークが有効になります |
| `ingress.enabled` | ブール値 | `false` | `true`に設定すると、`Ingress`ネットワークがアクティブになります。これにより、ルールが指定されていない限り、すべてのIngress接続がブロックされます。 |
| `ingress.rules`   |  配列  | `[]`    | Ingressのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください |
| `egress.enabled`  | ブール値 | `false` | `true`に設定すると、`Egress`ネットワークがアクティブになります。これにより、ルールが指定されていない限り、すべてのエグレス接続がブロックされます。 |
| `egress.rules`    |  配列  | `[]`    | エグレスのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください |

### ネットワークの例 {#example-network-policy}

Sidekiqサービスは、有効になっている場合にPrometheus exporterのみにIngressを必要とし、通常はさまざまな場所へのエグレスを必要とします。この例では、次のネットワークを追加します。

- Ingressリクエストを許可します。
  - `Prometheus`ポッドからポート`3807`へ
- エグレスリクエストを許可します。
  - `kube-dns`からポート`53`へ
  - `gitaly`ポッドからポート`8075`へ
  - `registry`ポッドからポート`5000`へ
  - `kas`ポッドからポート`8153`へ
  - 外部データベース`172.16.0.10/32`からポート`5432`へ
  - 外部Redis `172.16.0.11/32`からポート`6379`へ
  - 外部Elasticsearch `172.16.0.12/32`からポート`443`へ
  - メールゲートウェイ`172.16.0.13/32`からポート`587`へ
  - S3またはSTSのAWS VPCのようなへ`172.16.1.0/24`ポート`443`
  - 内部サブネット`172.16.2.0/24`からポート`443`にWebhookを送信する

*提供されている例は単なる例であり、完全ではない可能性があることに注意してください*

{{< alert type="note" >}}

Sidekiqサービスには、ローカルが利用できない場合、[外部オブジェクトストレージ](../../../advanced/external-object-storage)上のイメージへのパブリックインターネットへのアウトバウンドが必要です。  

{{< /alert >}}

この例は、`kube-dns`が`kube-system`に、`prometheus`が`monitoring`に、`nginx-ingress`が`nginx-ingress`にデプロイされたという前提に基づいています。

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

## KEDAの設定 {#configuring-keda}

この`keda`セクションでは、[KEDA](https://keda.sh/) `ScaledObjects`のインストールを、通常の`HorizontalPodAutoscalers`の代わりに行います。このはオプションであり、カスタムメトリクスまたは外部メトリクスに基づいてオートスケールが必要な場合に使用できます。

ほとんどのは、該当する場合、`hpa`セクションで設定されたにデフォルト設定されます。

以下がtrueの場合、CPUおよびメモリーのトリガーは、`hpa`セクションで設定されたCPUおよびメモリーのに基づいて自動的に追加されます。

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定もゼロ以外のに設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらのの詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  種類   | デフォルト | 説明 |
|:--------------------------------|:-------:|:--------|:------------|
| `enabled`                       | ブール値 | `false` | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用する |
| `pollingInterval`               | 整数 | `30`    | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`   | 最後のアクティブなトリガーがされてから、リソースを0にスケールバックするまで待機する期間 |
| `minReplicaCount`               | 整数 |         | KEDAがリソースをスケールダウンする最小レプリカ数。デフォルトは`minReplicas`です |
| `maxReplicaCount`               | 整数 |         | KEDAがリソースをスケールアップする最大レプリカ数。デフォルトは`maxReplicas`です |
| `fallback`                      |   マップ   |         | KEDAフォールバック、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | 文字列  |         | KEDAが作成するHPAリソースの名前。デフォルトは`keda-hpa-{scaled-object-name}` |
| `restoreToOriginalReplicaCount` | ブール値 |         | ターゲットが、`ScaledObject`削除後に元の数にスケールバックされるかどうかを指定します |
| `behavior`                      |      |         | アップスケーリングとダウンスケーリングの。デフォルトは`hpa.behavior`です。 |
| `triggers`                      |    |         | ターゲットのをアクティブにするのリスト。デフォルトは`hpa.cpu`と`hpa.memory`からされたです |
