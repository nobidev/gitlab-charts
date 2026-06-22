---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: コンテナレジストリの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`registry`サブチャートは、Kubernetes上での完全なクラウドネイティブGitLabのデプロイにレジストリコンポーネントを提供します。このサブチャートは、[アップストリームのチャート](https://github.com/docker/distribution-library-image)に基づいており、GitLabの[コンテナレジストリ](https://gitlab.com/gitlab-org/container-registry)を含んでいます。

このチャートは主に3つのパートで構成されています:

- [Service](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/service.yaml)、
- [Deployment](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/deployment.yaml)、
- [ConfigMap](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/configmap.yaml)。

すべての設定は、[レジストリ設定ドキュメント](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads)に従って、`/etc/docker/registry/config.yml`変数を使用して処理され、`ConfigMap`から入力された`Deployment`に提供されます。`ConfigMap`はアップストリームのデフォルトをオーバーライドしますが、[それらに基づいています](https://github.com/docker/distribution-library-image/blob/master/config-example.yml)。詳細については以下を参照してください:

- [`distribution/cmd/registry/config-example.yml`](https://github.com/docker/distribution/blob/master/cmd/registry/config-example.yml)
- [`distribution-library-image/config-example.yml`](https://github.com/docker/distribution-library-image/blob/master/config-example.yml)

## 設計上の選択肢 {#design-choices}

Kubernetesの`Deployment`が、インスタンスのシンプルなスケールを可能にしつつ、[ローリングアップデート](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)も可能にするため、このチャートのデプロイ方法として選択されました。

このチャートは、2つの必須シークレットと1つのオプションシークレットを使用します:

### 必須 {#required}

- `global.registry.certificate.secret`: 関連するGitLabインスタンスから提供される認証トークンを検証するための公開証明書バンドルを含むグローバルシークレット。GitLabを認証エンドポイントとして使用する方法については、[ドキュメント](https://docs.gitlab.com/administration/packages/container_registry/#use-an-external-container-registry-with-gitlab-as-an-auth-endpoint)を参照してください。
- `global.registry.httpSecret.secret`: レジストリポッド間で[共有されるシークレット](https://distribution.github.io/distribution/about/configuration/#http)を含むグローバルシークレット。

### オプション {#optional}

- `profiling.stackdriver.credentials.secret`: Stackdriverプロファイリングが有効で、明示的なサービスアカウント認証情報を提供する必要がある場合、このシークレットの値（デフォルトでは`credentials`キー内）はGCPサービスアカウントのJSON認証情報です。GKEを使用しており、[ワークロードID](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)（またはノードサービスアカウント。ただしこれは推奨されません）を使用してワークロードにサービスアカウントを提供している場合、このシークレットは不要であり、提供すべきではありません。いずれの場合も、サービスアカウントには`roles/cloudprofiler.agent`ロールまたは同等の[手動アクセス許可](https://cloud.google.com/profiler/docs/iam#roles)が必要です

## 設定 {#configuration}

以下に、設定の主要なセクションをすべて説明します。親チャートから設定する場合、これらの値は次のようになります:

```yaml
registry:
  enabled:
  maintenance:
    readonly:
      enabled: false
    uploadpurging:
      enabled: true
      age: 168h
      interval: 24h
      dryrun: false
  image:
    tag: 'v4.15.2-gitlab'
    pullPolicy: IfNotPresent
  annotations:
  service:
    type: ClusterIP
    name: registry
  httpSecret:
    secret:
    key:
  authEndpoint:
  tokenIssuer:
  certificate:
    secret: gitlab-registry
    key: registry-auth.crt
  deployment:
    terminationGracePeriodSeconds: 30
  draintimeout: '0'
  hpa:
    minReplicas: 2
    maxReplicas: 10
    cpu:
      targetAverageUtilization: 75
    behavior:
      scaleDown:
        stabilizationWindowSeconds: 300
  storage:
    secret:
    key: storage
    extraKey:
  validation:
    disabled: true
    manifests:
      referencelimit: 0
      payloadsizelimit: 0
      urls:
        allow: []
        deny: []
  notifications: {}
  tolerations: []
  affinity: {}
  ingress:
    enabled: false
    tls:
      enabled: true
      secretName: redis
    annotations:
    configureCertmanager:
    proxyReadTimeout:
    proxyBodySize:
    proxyBuffering:
  networkpolicy:
    enabled: false
    egress:
      enabled: false
      rules: []
    ingress:
      enabled: false
      rules: []
  serviceAccount:
    create: false
    automountServiceAccountToken: false
  tls:
    enabled: false
    secretName:
    verify: true
    caSecretName:
    cipherSuites:
```

このチャートをスタンドアロンとしてデプロイすることを選択した場合、トップレベルの`registry`を削除してください。

## インストールパラメータ {#installation-parameters}

| パラメータ                                                | デフォルト                                                              | 説明 |
|----------------------------------------------------------|----------------------------------------------------------------------|-------------|
| `annotations`                                            |                                                                      | ポッドアノテーション |
| `podLabels`                                              |                                                                      | 補足のポッドラベル。セレクターには使用されません。 |
| `common.labels`                                          |                                                                      | このチャートによって作成されたすべてのオブジェクトに適用される補足ラベル。 |
| `authAutoRedirect`                                       | `true`                                                               | 認証自動リダイレクト（Windowsクライアントが機能するにはtrueである必要があります） |
| `authEndpoint`                                           | `global.hosts.gitlab.name`                                           | 認証エンドポイント（ホストとポートのみ） |
| `certificate.secret`                                     | `gitlab-registry`                                                    | JWT証明書 |
| `debug.addr.port`                                        | `5001`                                                               | デバッグポート  |
| `debug.tls.enabled`                                      | `false`                                                              | レジストリのデバッグポートのTLSを有効にします。LivenessおよびReadinessプローブ、ならびにメトリクスエンドポイント（有効な場合）に影響します。 |
| `debug.tls.secretName`                                   |                                                                      | レジストリデバッグエンドポイント用の有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定されておらず`debug.tls.enabled=true`の場合、デバッグTLS設定はレジストリのTLS証明書にデフォルトで設定されます。 |
| `debug.prometheus.enabled`                               | `false`                                                              | **DEPRECATED** `metrics.enabled`を使用 |
| `debug.prometheus.path`                                  | `""`                                                                 | **DEPRECATED** `metrics.path`を使用 |
| `metrics.enabled`                                        | `false`                                                              | メトリクスエンドポイントをスクレイプ可能にするかどうか |
| `metrics.path`                                           | `/metrics`                                                           | メトリクスエンドポイントパス |
| `metrics.serviceMonitor.enabled`                         | `false`                                                              | Prometheus Operatorがメトリクスのスクレイプを管理できるようにServiceMonitorを作成する場合、これを有効にすると`prometheus.io`スクレイプアノテーションが削除されることに注意してください。 |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                                 | ServiceMonitorに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                                 | ServiceMonitor用の追加のエンドポイント設定 |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                                 | ポッドが正常に終了するまでに必要なオプションの期間（秒単位）。 |
| `deployment.strategy`                                    | `{}`                                                                 | デプロイによって利用される更新戦略を設定できます。 |
| `draintimeout`                                           | `'0'`                                                                | SIGTERMシグナルを受信した後、HTTP接続がドレインするまで待機する時間（例: `'10s'`） |
| `relativeurls`                                           | `false`                                                              | レジストリがLocationヘッダーで相対URLを返すことを有効にします。 |
| `enabled`                                                | `true`                                                               | レジストリフラグを有効にする |
| `api.enabled`                                            | `true`                                                               | Service、Deployment、HPA、およびPDBリソースを有効にします。 |
| `extraContainers`                                        |                                                                      | 含めるコンテナのリストを含む複数行リテラルスタイルの文字列 |
| `extraInitContainers`                                    |                                                                      | 含める追加のinitコンテナのリスト |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`                    | Behaviorには、スケールアップおよびスケールダウン動作の仕様が含まれます（`autoscaling/v2beta2`以降が必要です）。 |
| `hpa.customMetrics`                                      | `[]`                                                                 | カスタムメトリクスには、必要なレプリカ数を計算するために使用する仕様が含まれます（`targetAverageUtilization`で設定された平均CPU使用率のデフォルト使用をオーバーライドします）。 |
| `hpa.cpu.targetType`                                     | `Utilization`                                                        | オートスケールのCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.cpu.targetAverageValue`                             |                                                                      | オートスケールのCPUターゲット値を設定します。 |
| `hpa.cpu.targetAverageUtilization`                       | `75`                                                                 | オートスケールのCPUターゲット使用率を設定します。 |
| `hpa.memory.targetType`                                  |                                                                      | オートスケールのメモリターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.memory.targetAverageValue`                          |                                                                      | オートスケールのメモリターゲット値を設定します。 |
| `hpa.memory.targetAverageUtilization`                    |                                                                      | オートスケールのメモリターゲット使用率を設定します。 |
| `hpa.minReplicas`                                        | `2`                                                                  | レプリカの最小数 |
| `hpa.maxReplicas`                                        | `10`                                                                 | レプリカの最大数 |
| `httpSecret`                                             |                                                                      | Httpsシークレット |
| `extraEnvFrom`                                           |                                                                      | 他のデータソースから公開する追加の環境変数のリスト |
| `image.pullPolicy`                                       |                                                                      | レジストリイメージのプルポリシー |
| `image.pullSecrets`                                      |                                                                      | イメージリポジトリに使用するシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry` | レジストリイメージ |
| `image.tag`                                              | `v4.15.2-gitlab`                                                     | 使用するイメージのバージョン |
| `init.image.repository`                                  |                                                                      | initContainerイメージ |
| `init.image.tag`                                         |                                                                      | initContainerイメージタグ |
| `init.containerSecurityContext`                          |                                                                      | initContainer固有の[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                               | initContainer固有: コンテナが起動されるユーザーID |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                              | initContainer固有: プロセスがその親プロセスよりも多くの特権を獲得できるかどうかを制御します。 |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                               | initContainer固有: コンテナが非ルートユーザーで実行されるかどうかを制御します。 |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                          | initContainer固有: コンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します。 |
| `keda.enabled`                                           | `false`                                                              | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                   | `30`                                                                 | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                                    | `300`                                                                | 最後のトリガーがアクティブであると報告された後、リソースを0にスケールダウンするまで待機する期間 |
| `keda.minReplicaCount`                                   | `hpa.minReplicas`                                                    | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `keda.maxReplicaCount`                                   | `hpa.maxReplicas`                                                    | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `keda.fallback`                                          |                                                                      | KEDAフォールバック設定。[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください。 |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                                      | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`                     |                                                                      | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します。 |
| `keda.behavior`                                          | `hpa.behavior`                                                       | スケールアップおよびスケールダウン動作の仕様。 |
| `keda.triggers`                                          |                                                                      | ターゲットリソースのスケールをアクティブにするトリガーのリスト。`hpa.cpu`と`hpa.memory`から計算されたトリガーにデフォルトで設定されます。 |
| `log`                                                    | `{level: info, fields: {service: registry}}`                         | ロギングオプションを設定します |
| `minio.bucket`                                           | `global.registry.bucket`                                             | レガシーレジストリバケット名 |
| `maintenance.readonly.enabled`                           | `false`                                                              | レジストリの読み取り専用モードを有効にする |
| `maintenance.uploadpurging.enabled`                      | `true`                                                               | アップロードパージを有効にする |
| `maintenance.uploadpurging.age`                          | `168h`                                                               | 指定された期間より古いアップロードをパージする |
| `maintenance.uploadpurging.interval`                     | `24h`                                                                | アップロードパージが実行される頻度 |
| `maintenance.uploadpurging.dryrun`                       | `false`                                                              | 削除せずにパージされるアップロードをリストするのみ |
| `priorityClassName`                                      |                                                                      | ポッドに割り当てられた[Priority class](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |
| `reporting.sentry.enabled`                               | `false`                                                              | Sentryを使用したレポートを有効にする |
| `reporting.sentry.dsn`                                   |                                                                      | Sentry DSN（Data Source Name） |
| `reporting.sentry.environment`                           |                                                                      | Sentry[環境](https://docs.sentry.io/concepts/key-terms/environments/) |
| `profiling.stackdriver.enabled`                          | `false`                                                              | Stackdriverを使用した継続的プロファイリングを有効にする |
| `profiling.stackdriver.credentials.secret`               | `gitlab-registry-profiling-creds`                                    | 認証情報を含むシークレットの名前 |
| `profiling.stackdriver.credentials.key`                  | `credentials`                                                        | 認証情報が保存されているシークレット内のキー |
| `profiling.stackdriver.service`                          |  `RELEASE-registry`（テンプレート化されたService名）                          | プロファイルを記録するStackdriverサービスの名前 |
| `profiling.stackdriver.projectid`                        | 実行中のGCPプロジェクト                                            | プロファイルを報告するGCPプロジェクト |
| `database.configure`                                     | `false`                                                              | レジストリチャートにデータベース設定を入力しますが、有効にはしません。[既存のレジストリをインポートする場合](metadata_database.md#enable-for-and-import-existing-registries)に必要です。 |
| `database.enabled`                                       | `false`                                                              | メタデータデータベースを有効にします。これは実験的機能であり、本番環境で使用してはなりません。 |
| `database.host`                                          | `global.psql.host`                                                   | データベースサーバーのホスト名。 |
| `database.port`                                          | `global.psql.port`                                                   | データベースサーバーのポート。 |
| `database.user`                                          |                                                                      | データベースのユーザー名。 |
| `database.password.secret`                               | `RELEASE-registry-database-password`                                 | データベースパスワードを含むシークレットの名前。 |
| `database.password.key`                                  | `password`                                                           | データベースパスワードが保存されているシークレット内のキー。 |
| `database.name`                                          |                                                                      | データベース名。 |
| `database.sslmode`                                       |                                                                      | The SSL mode.`disable`、`allow`、`prefer`、`require`、`verify-ca`または`verify-full`のいずれか。 |
| `database.ssl.secret`                                    | `global.psql.ssl.secret`                                             | クライアント証明書、キー、および認証局を含むシークレット。メインのPostgreSQL SSLシークレットにデフォルトで設定されます。 |
| `database.ssl.clientCertificate`                         | `global.psql.ssl.clientCertificate`                                  | クライアント証明書を参照するシークレット内のキー。 |
| `database.ssl.clientKey`                                 | `global.psql.ssl.clientKey`                                          | クライアントキーを参照するシークレット内のキー。 |
| `database.ssl.serverCA`                                  | `global.psql.ssl.serverCA`                                           | 認証局（CA）を参照するシークレット内のキー。 |
| `database.connecttimeout`                                | `0`                                                                  | 接続を待機する最大時間。ゼロまたは未指定は、無期限に待機することを意味します。 |
| `database.draintimeout`                                  | `0`                                                                  | シャットダウン時にすべての接続がドレインするまで待機する最大時間。ゼロまたは未指定は、無期限に待機することを意味します。 |
| `database.preparedstatements`                            | `false`                                                              | プリペアドステートメントを有効にします。PgBouncerとの互換性のためにデフォルトで無効になっています。 |
| `database.primary`                                       | `false`                                                              | ターゲットプライマリデータベースサーバー。これは、レジストリ`database.migrations`を実行する際にターゲットとする専用のFQDNを指定するために使用されます。指定されていない場合、`host`は`database.migrations`の実行に使用されます。 |
| `database.pool.maxidle`                                  | `0`                                                                  | アイドル接続プール内の接続の最大数。`maxopen`が`maxidle`よりも小さい場合、`maxidle`は`maxopen`の制限に一致するように削減されます。ゼロまたは未指定は、アイドル接続がないことを意味します。 |
| `database.pool.maxopen`                                  | `0`                                                                  | データベースへのオープン接続の最大数。`maxopen`が`maxidle`よりも小さい場合、`maxidle`は`maxopen`の制限に一致するように削減されます。ゼロまたは未指定は、無制限のオープン接続を意味します。 |
| `database.pool.maxlifetime`                              | `0`                                                                  | 接続が再利用される最大時間。期限切れの接続は、再利用前に遅延して閉じられる場合があります。ゼロまたは未指定は、無制限の再利用を意味します。 |
| `database.pool.maxidletime`                              | `0`                                                                  | 接続がアイドル状態である最大時間。期限切れの接続は、再利用前に遅延して閉じられる場合があります。ゼロまたは未指定は、無制限の期間を意味します。 |
| `database.loadBalancing.enabled`                         | `false`                                                              | データベースのロードバランシングを有効にします。これは実験的機能であり、本番環境で使用してはなりません。 |
| `database.loadBalancing.nameserver.host`                 | `localhost`                                                          | DNSレコードを検索するために使用するネームサーバーのホスト。 |
| `database.loadBalancing.nameserver.port`                 | `8600`                                                               | DNSレコードを検索するために使用するネームサーバーのポート。 |
| `database.loadBalancing.record`                          |                                                                      | 検索するSRVレコード。このオプションはサービスディスカバリが機能するために必要です。 |
| `database.loadBalancing.replicaCheckInterval`            | `1m`                                                                 | レプリカのステータスを確認する間の最小時間。 |
| `database.migrations.enabled`                            | `true`                                                               | チャートの初期デプロイおよびアップグレード時に、移行ジョブを自動的に実行できるようにします。移行は、実行中のいずれかのレジストリポッド内から手動で実行することもできます。 |
| `database.migrations.activeDeadlineSeconds`              | `3600`                                                               | 移行ジョブの[activeDeadlineSeconds](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup)を設定します。 |
| `database.migrations.annotations`                        | `{}`                                                                 | 移行ジョブに追加する追加のアノテーション。 |
| `database.migrations.backoffLimit`                       | `6`                                                                  | 移行ジョブの[backoffLimit](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup)を設定します。 |
| `database.backgroundMigrations.enabled`                  | `false`                                                              | データベースのバックグラウンド移行を有効にします。これはレジストリメタデータデータベース用の実験的機能です。本番環境では使用しないでください。動作の詳細については、[仕様](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/database-background-migrations.md?ref_type=heads)を参照してください。 |
| `database.backgroundMigrations.jobInterval`              |                                                                      | 各バックグラウンド移行ジョブワーカーの実行間のスリープ間隔。指定されていない場合、[レジストリによってデフォルト値が設定されます](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#backgroundmigrations)。 |
| `database.backgroundMigrations.maxJobRetries`            |                                                                      | 失敗したバックグラウンド移行ジョブの最大再試行回数。指定されていない場合、[レジストリによってデフォルト値が設定されます](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#backgroundmigrations)。 |
| `database.metrics.enabled`                               | `false`                                                              | `true`に設定すると、データベースメトリクス収集が有効になります。これは実験的機能であり、本番環境では使用しないでください。分散ロックには、レジストリ4.27.0以降、メタデータデータベース（`database.enabled: true`）、およびRedisキャッシュ（`redis.cache.enabled: true`）が必要です。 |
| `database.metrics.interval`                              | `10s`                                                                | データベースからメトリクスが収集される間隔。 |
| `database.metrics.leaseDuration`                         | `30s`                                                                | Redisロックがメトリクスコレクターによって保持される期間。同じインスタンスによる継続的な収集を保証するために、`interval`よりも長くする必要があります。 |
| `gc.disabled`                                            | `true`                                                               | `true`に設定すると、オンラインGCワーカーが無効になります。 |
| `gc.maxbackoff`                                          | `24h`                                                                | エラー発生時にワーカー実行間でスリープするために使用される最大指数バックオフ期間。`gc.noidlebackoff`が`true`でない限り、処理すべきタスクがない場合にも適用されます。ランダム化されたジッター係数が常に最大33%追加されるため、これが絶対的な最大値ではないことに注意してください。 |
| `gc.noidlebackoff`                                       | `false`                                                              | `true`に設定すると、処理すべきタスクがない場合のワーカー実行間の指数バックオフが無効になります。 |
| `gc.transactiontimeout`                                  | `10s`                                                                | 各ワーカー実行のデータベーストランザクションタイムアウト。各ワーカーは開始時にデータベーストランザクションを開始します。このタイムアウトを超過すると、ストールした、または長時間実行されるトランザクションを回避するために、ワーカー実行がキャンセルされます。 |
| `gc.blobs.disabled`                                      | `false`                                                              | `true`に設定すると、blob用のGCワーカーが無効になります。 |
| `gc.blobs.interval`                                      | `5s`                                                                 | 各ワーカー実行間の初期スリープ間隔。 |
| `gc.blobs.storagetimeout`                                | `5s`                                                                 | ストレージ操作のタイムアウト。ストレージバックエンド上のぶら下がっているblobを削除するリクエストの期間を制限するために使用されます。 |
| `gc.manifests.disabled`                                  | `false`                                                              | `true`に設定すると、マニフェスト用のGCワーカーが無効になります。 |
| `gc.manifests.interval`                                  | `5s`                                                                 | 各ワーカー実行間の初期スリープ間隔。 |
| `gc.reviewafter`                                         | `24h`                                                                | ガベージコレクターがレビューのためにレコードをピックアップするまでの最小時間。`-1`は待機なしを意味します。 |
| `securityContext.fsGroup`                                | `1000`                                                               | ポッドが起動されるグループID |
| `securityContext.runAsUser`                              | `1000`                                                               | ポッドが起動されるユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                                                      | ボリュームの所有権とアクセス許可を変更するためのポリシー（Kubernetes 1.23以降が必要） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                                     | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                                      | コンテナが起動される[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします。 |
| `containerSecurityContext.runAsUser`                     | `1000`                                                               | コンテナが起動される特定のセキュリティコンテキストユーザーIDを上書きすることを許可します。 |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                              | Gitalyコンテナのプロセスがその親プロセスよりも多くの特権を獲得できるかどうかを制御します。 |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                               | コンテナが非ルートユーザーで実行されるかどうかを制御します。 |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                          | Gitalyコンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します。 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                              | サービスアカウントアクセストークンがポッドにマウントされるべきかどうかを示します。 |
| `serviceAccount.enabled`                                 | `false`                                                              | サービスアカウントを使用するかどうかを示します。 |
| `serviceLabels`                                          | `{}`                                                                 | 補足のサービスラベル |
| `tokenService`                                           | `container_registry`                                                 | JWTトークンサービス |
| `tokenIssuer`                                            | `gitlab-issuer`                                                      | JWTトークン発行者 |
| `tolerations`                                            | `[]`                                                                 | ポッドの割り当てに対するTolerationラベル |
| `affinity`                                               | `{}`                                                                 | ポッドの割り当てに対するアフィニティルール |
| `middleware.storage`                                     |                                                                      | ミドルウェアストレージ（[例：s3](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#example-middleware-configuration)）の設定レイヤー |
| `redis.cache.enabled`                                    | `false`                                                              | `true`に設定すると、Redisキャッシュが有効になります。この機能は、[メタデータデータベース](#database)が有効になっていることに依存します。リポジトリのメタデータは、設定されたRedisインスタンスにキャッシュされます。 |
| `redis.cache.host`                                       | `<Redis URL>`                                                        | Redisインスタンスのホスト名。空の場合、値は`global.redis.host:global.redis.port`として入力されます。 |
| `redis.cache.port`                                       | `6379`                                                               | Redisインスタンスのポート。 |
| `redis.cache.cluster`                                    | `[]`                                                                 | ホストとポートを持つアドレスのリスト。 |
| `redis.cache.sentinels`                                  | `[]`                                                                 | ホストとポートを持つセンチネルをリストします。 |
| `redis.cache.mainname`                                   |                                                                      | メインサーバー名。Sentinelにのみ適用可能です。 |
| `redis.cache.username`                                   |                                                                      | Redisインスタンスに接続するために使用されるユーザー名。 |
| `redis.cache.password.enabled`                           | `false`                                                              | レジストリによって使用されるRedisキャッシュがパスワードで保護されているかどうかを示します。 |
| `redis.cache.password.secret`                            | `gitlab-redis-secret`                                                | Redisパスワードを含むシークレットの名前。`shared-secrets`機能が有効な場合、指定されていなければ自動的に作成されます。 |
| `redis.cache.password.key`                               | `redis-password`                                                     | Redisパスワードが保存されているシークレット内のキー。 |
| `redis.cache.sentinelpassword.enabled`                   | `false`                                                              | Redis Sentinelがパスワードで保護されているかどうかを示します。`redis.cache.sentinelpassword`が空の場合、`global.redis.sentinelAuth`の値が使用されます。`redis.cache.sentinels`が定義されている場合にのみ使用されます。 |
| `redis.cache.sentinelpassword.secret`                    | `gitlab-redis-secret`                                                | Redis Sentinelパスワードを含むシークレットの名前。 |
| `redis.cache.sentinelpassword.key`                       | `redis-sentinel-password`                                            | Redis Sentinelパスワードが保存されているシークレット内のキー。 |
| `redis.cache.db`                                         | `0`                                                                  | 各接続に使用するデータベースの名前。 |
| `redis.cache.dialtimeout`                                | `0s`                                                                 | Redisインスタンスに接続するためのタイムアウト。デフォルトではタイムアウトなし。 |
| `redis.cache.readtimeout`                                | `0s`                                                                 | Redisインスタンスからの読み取りのタイムアウト。デフォルトではタイムアウトなし。 |
| `redis.cache.writetimeout`                               | `0s`                                                                 | Redisインスタンスへの書き込みのタイムアウト。デフォルトではタイムアウトなし。 |
| `redis.cache.tls.enabled`                                | `false`                                                              | TLSを有効にするには`true`に設定します。 |
| `redis.cache.tls.insecure`                               | `false`                                                              | TLS経由で接続するときにサーバー名の検証を無効にするには`true`に設定します。 |
| `redis.cache.pool.size`                                  | `10`                                                                 | ソケット接続の最大数。デフォルトは10接続です。 |
| `redis.cache.pool.maxlifetime`                           | `1h`                                                                 | クライアントが接続を終了する接続の経過時間。デフォルトは、期限切れの接続を閉じないことです。 |
| `redis.cache.pool.idletimeout`                           | `300s`                                                               | 非アクティブな接続を閉じるまでに待機する時間。 |
| `redis.rateLimiting.enabled`                             | `false`                                                              | `true`に設定すると、Redisレート制限が有効になります。この機能は開発中です。 |
| `redis.rateLimiting.host`                                | `<Redis URL>`                                                        | Redisインスタンスのホスト名。空の場合、値は`global.redis.host:global.redis.port`として入力されます。 |
| `redis.rateLimiting.port`                                | `6379`                                                               | Redisインスタンスのポート。 |
| `redis.rateLimiting.cluster`                             | `[]`                                                                 | ホストとポートを持つアドレスのリスト。 |
| `redis.rateLimiting.sentinels`                           | `[]`                                                                 | ホストとポートを持つセンチネルをリストします。 |
| `redis.rateLimiting.mainname`                            |                                                                      | メインサーバー名。Sentinelにのみ適用可能です。 |
| `redis.rateLimiting.username`                            |                                                                      | Redisインスタンスに接続するために使用されるユーザー名。 |
| `redis.rateLimiting.password.enabled`                    | `false`                                                              | Redisインスタンスがパスワードで保護されているかどうかを示します。 |
| `redis.rateLimiting.password.secret`                     | `gitlab-redis-secret`                                                | Redisパスワードを含むシークレットの名前。`shared-secrets`機能が有効な場合、指定されていなければ自動的に作成されます。 |
| `redis.rateLimiting.password.key`                        | `redis-password`                                                     | Redisパスワードが保存されているシークレット内のキー。 |
| `redis.rateLimiting.sentinelpassword.enabled`                   | `false`                                                              | Redis Sentinelがパスワードで保護されているかどうかを示します。`redis.rateLimiting.sentinelpassword`が空の場合、`global.redis.sentinelAuth`の値が使用されます。`redis.rateLimiting.sentinels`が定義されている場合にのみ使用されます。 |
| `redis.rateLimiting.sentinelpassword.secret`                    | `gitlab-redis-secret`                                                | Redis Sentinelパスワードを含むシークレットの名前。 |
| `redis.rateLimiting.sentinelpassword.key`                       | `redis-sentinel-password`                                            | Redis Sentinelパスワードが保存されているシークレット内のキー。 |
| `redis.rateLimiting.db`                                  | `0`                                                                  | 各接続に使用するデータベースの名前。 |
| `redis.rateLimiting.dialtimeout`                         | `0s`                                                                 | Redisインスタンスに接続するためのタイムアウト。デフォルトではタイムアウトなし。 |
| `redis.rateLimiting.readtimeout`                         | `0s`                                                                 | Redisインスタンスからの読み取りのタイムアウト。デフォルトではタイムアウトなし。 |
| `redis.rateLimiting.writetimeout`                        | `0s`                                                                 | Redisインスタンスへの書き込みのタイムアウト。デフォルトではタイムアウトなし。 |
| `redis.rateLimiting.tls.enabled`                         | `false`                                                              | TLSを有効にするには`true`に設定します。 |
| `redis.rateLimiting.tls.insecure`                        | `false`                                                              | TLS経由で接続するときにサーバー名の検証を無効にするには`true`に設定します。 |
| `redis.rateLimiting.pool.size`                           | `10`                                                                 | ソケット接続の最大数。 |
| `redis.rateLimiting.pool.maxlifetime`                    | `1h`                                                                 | クライアントが接続を終了する接続の経過時間。デフォルトは、期限切れの接続を閉じないことです。 |
| `redis.rateLimiting.pool.idletimeout`                    | `300s`                                                               | 非アクティブな接続を閉じるまでに待機する時間。 |
| `redis.loadBalancing.enabled`                            | `false`                                                              | `true`に設定すると、[ロードバランシング](#load-balancing)用のRedis接続が有効になります。 |
| `redis.loadBalancing.host`                               | `<Redis URL>`                                                        | Redisインスタンスのホスト名。空の場合、値は`global.redis.host:global.redis.port`として入力されます。 |
| `redis.loadBalancing.port`                               | `6379`                                                               | Redisインスタンスのポート。 |
| `redis.loadBalancing.cluster`                            | `[]`                                                                 | ホストとポートを持つアドレスのリスト。 |
| `redis.loadBalancing.sentinels`                          | `[]`                                                                 | ホストとポートを持つセンチネルをリストします。 |
| `redis.loadBalancing.mainname`                           |                                                                      | メインサーバー名。Sentinelにのみ適用可能です。 |
| `redis.loadBalancing.username`                           |                                                                      | Redisインスタンスに接続するために使用されるユーザー名。 |
| `redis.loadBalancing.password.enabled`                   | `false`                                                              | Redisインスタンスがパスワードで保護されているかどうかを示します。 |
| `redis.loadBalancing.password.secret`                    | `gitlab-redis-secret`                                                | Redisパスワードを含むシークレットの名前。`shared-secrets`機能が有効な場合、指定されていなければ自動的に作成されます。 |
| `redis.loadBalancing.password.key`                       | `redis-password`                                                     | Redisパスワードが保存されているシークレット内のキー。 |
| `redis.loadBalancing.db`                                 | `0`                                                                  | 各接続に使用するデータベースの名前。 |
| `redis.loadBalancing.dialtimeout`                        | `0s`                                                                 | Redisインスタンスに接続するためのタイムアウト。デフォルトではタイムアウトなし。 |
| `redis.loadBalancing.readtimeout`                        | `0s`                                                                 | Redisインスタンスからの読み取りのタイムアウト。デフォルトではタイムアウトなし。 |
| `redis.loadBalancing.writetimeout`                       | `0s`                                                                 | Redisインスタンスへの書き込みのタイムアウト。デフォルトではタイムアウトなし。 |
| `redis.loadBalancing.tls.enabled`                        | `false`                                                              | TLSを有効にするには`true`に設定します。 |
| `redis.loadBalancing.tls.insecure`                       | `false`                                                              | TLS経由で接続するときにサーバー名の検証を無効にするには`true`に設定します。 |
| `redis.loadBalancing.pool.size`                          | `10`                                                                 | ソケット接続の最大数。 |
| `redis.loadBalancing.pool.maxlifetime`                   | `1h`                                                                 | クライアントが接続を終了する接続の経過時間。デフォルトは、期限切れの接続を閉じないことです。 |
| `redis.loadBalancing.pool.idletimeout`                   | `300s`                                                               | 非アクティブな接続を閉じるまでに待機する時間。 |

## チャート設定の例 {#chart-configuration-examples}

### `pullSecrets` {#pullsecrets}

 `pullSecrets`を使用すると、プライベートレジストリに対して認証し、ポッド用のイメージをプルできます。

プライベートレジストリとその認証方法に関する追加の詳細は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)で確認できます。

`pullSecrets`の使用例を以下に示します。

```yaml
image:
  repository: my.registry.repository
  tag: latest
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

このセクションでは、サービスアカウントを作成するかどうか、およびデフォルトアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトサービスアカウントアクセストークンをポッドにマウントするかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `enabled`                      | ブール値 | `false` | サービスアカウントを使用するかどうかを示します。 |

### `tolerations` {#tolerations}

 `tolerations`を使用すると、汚染されたワーカーノードにポッドをスケジュールできます。

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

### `affinity` {#affinity}

 `affinity`は、以下のいずれかまたは両方を設定できるオプションのパラメータです:

- `podAntiAffinity`ルール:
  - `topology key`に対応する式に一致するポッドと同じドメインにポッドをスケジュールしない。
  - `podAntiAffinity`ルールの2つのモードを設定します: 必須（`requiredDuringSchedulingIgnoredDuringExecution`）と推奨（`preferredDuringSchedulingIgnoredDuringExecution`）。`values.yaml`の`antiAffinity`変数を使用して、推奨モードが適用されるように`soft`に設定するか、必須モードが適用されるように`hard`に設定します。
- `nodeAffinity`ルール:
  - 特定のゾーンまたは複数のゾーンに属するノードにポッドをスケジュールします。
  - `nodeAffinity`ルールの2つのモードを設定します: 必須（`requiredDuringSchedulingIgnoredDuringExecution`）と推奨（`preferredDuringSchedulingIgnoredDuringExecution`）。`soft`に設定すると、推奨モードが適用されます。`hard`に設定すると、必須モードが適用されます。このルールは、`webservice`と`sidekiq`を除くすべてのサブチャートとともに、`registry`チャートと`gitlab`チャートにのみ実装されます。

 `nodeAffinity`は[`In`オペレーター](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#operators)のみを実装します。

詳細については、[関連するKubernetesドキュメント](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)を参照してください。

次の例では、`affinity`を設定し、`nodeAffinity`と`antiAffinity`の両方を`hard`に設定します:

```yaml
nodeAffinity: "hard"
antiAffinity: "hard"
affinity:
  nodeAffinity:
    key: "test.com/zone"
    values:
    - us-east1-a
    - us-east1-b
  podAntiAffinity:
    topologyKey: "test.com/hostname"
```

### `annotations` {#annotations}

 `annotations`を使用すると、レジストリポッドにアノテーションを追加できます。

以下に、`annotations`の使用例を示します。

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## サブチャートを有効にする {#enable-the-sub-chart}

私たちが選択したコンパートメント化されたサブチャートの実装方法は、特定のデプロイで不要なコンポーネントを無効にする機能を含みます。このため、最初に決定すべき設定は`enabled`です。

デフォルトでは、レジストリはすぐに使用できるように有効になっています。無効にしたい場合は、`enabled: false`を設定してください。

## アプリケーションに必要なリソースを有効にする {#enable-resources-required-for-the-application}

Service、Deployment、HPA、PDBリソースは、`registry.api.enabled`の値（デフォルト：`true`）によって有効になります。

この設定がGitLab.comでどのように使用されているかについては、[コンテナレジストリのデプロイ後の移行](../../development/registry_post_deployment_migrations_on_gitlab_com.md)で詳細をご覧ください。

## `image`を設定する {#configuring-the-image}

このセクションでは、このサブチャートの[Deployment](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/deployment.yaml)が使用するコンテナイメージの設定について詳しく説明します。レジストリの含まれるバージョンと`pullPolicy`を変更できます。

デフォルト設定:

- `tag: 'v4.15.2-gitlab'`
- `pullPolicy: 'IfNotPresent'`

## `service`を設定する {#configuring-the-service}

このセクションでは、[Service](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/service.yaml)の名前とタイプを制御します。これらの設定は[`values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/values.yaml)によって入力されます。

デフォルトでは、Serviceは次のように設定されます:

| 名前             |  型  | デフォルト     | 説明 |
|:-----------------|:------:|:------------|:------------|
| `name`           | 文字列 | `registry`  | サービスの名前を設定します |
| `type`           | 文字列 | `ClusterIP` | サービスのタイプを設定します |
| `externalPort`   |  整数   | `5000`      | Serviceによって公開されるポート |
| `internalPort`   |  整数   | `5000`      | サービスからのリクエストを受け入れるためにポッドが使用するポート |
| `clusterIP`      | 文字列 | `null`      | 必要に応じてカスタムCluster IPを設定できます |
| `loadBalancerIP` | 文字列 | `null`      | 必要に応じてカスタムLoadBalancer IPアドレスを設定できます |

## `ingress`を設定する {#configuring-the-ingress}

このセクションでは、レジストリのIngressを制御します。

| 名前                   |  型   | デフォルト | 説明 |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | 文字列  |         | `apiVersion`フィールドで使用する値。 |
| `annotations`          | 文字列  |         | このフィールドは、[KubernetesIngress](https://kubernetes.io/docs/concepts/services-networking/ingress/)の標準`annotations`と完全に一致します。 |
| `configureCertmanager` | ブール値 |         | Ingressアノテーション`cert-manager.io/issuer`と`acme.cert-manager.io/http01-edit-in-place`を切り替えます。詳細については、[GitLab PagesのTLS要件](../../installation/tls.md)を参照してください。 |
| `enabled`              | ブール値 | `false` | それらをサポートするサービス用のIngressオブジェクトを作成するかどうかを制御する設定。`false`の場合、`global.ingress.enabled`設定が使用されます。 |
| `tls.enabled`          | ブール値 | `true`  | `false`に設定すると、レジストリサブチャートのTLSが無効になります。これは主に、Ingressコントローラーの前にTLS終端プロキシがある場合など、`ingress-level`でTLS終端を使用できない場合に役立ちます。 |
| `tls.secretName`       | 文字列  |         | レジストリURL用の有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定されていない場合、代わりに`global.ingress.tls.secretName`が使用されます。デフォルトでは設定されていません。 |
| `tls.cipherSuites`     |  配列  | `[]`    | コンテナレジストリがTLSハンドシェイク中にクライアントに提示すべき暗号スイートのリスト。 |

## TLSを設定する {#configuring-tls}

コンテナレジストリは、`nginx-ingress`を含む他のコンポーネントとの通信を保護するTLSをサポートしています。

TLSを設定するための前提条件:

- TLS証明書には、Common Name (CN) またはSubject Alternate Name (SAN) にレジストリサービスホスト名（例: `RELEASE-registry.default.svc`）を含める必要があります。
- TLS証明書が生成された後:
  - [Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を作成します。
  - `ca.crt`キーを持つTLS証明書のCA証明書のみを含む別のシークレットを作成します。

TLSを有効にするには:

1. `registry.tls.enabled`を`true`に設定します。
1. `global.hosts.registry.protocol`を`https`に設定します。
1. シークレット名を`registry.tls.secretName`と`global.certificates.customCAs`にそれぞれ渡します。

`registry.tls.verify`が`true`の場合、CA証明書シークレット名を`registry.tls.caSecretName`に渡す必要があります。これは、自己署名証明書およびカスタム認証局に必要です。このシークレットは、NGINXによってレジストリのTLS証明書を検証するために使用されます。

例: 

```yaml
global:
  certificates:
    customCAs:
    - secret: registry-tls-ca
  hosts:
    registry:
      protocol: https

registry:
  tls:
    enabled: true
    secretName: registry-tls
    verify: true
    caSecretName: registry-tls-ca
```

### コンテナレジストリの暗号スイート {#container-registry-cipher-suites}

通常、`tls.cipherSuites`オプションは、レジストリがスタンドアロンモードでデプロイされ、かつ最新の暗号スイートをサポートしない非デフォルトIngressが使用されるような、非常にまれな設定でのみ使用されるべきです。標準のGitLabデプロイでは、NGINX Ingressはコンテナレジストリバックエンドがサポートする最高のTLSバージョンを選択します。これは現時点ではTLS1.3です。TLS1.3では暗号の設定は許可されておらず、デフォルトで安全です。何らかの理由でTLS1.3が利用できない場合でも、コンテナレジストリが使用しているデフォルトのTLS1.2暗号リストはNGINX Ingressのデフォルト設定とも互換性があり、同様に安全です。

### デバッグポートのTLSを設定する {#configuring-tls-for-the-debug-port}

レジストリのデバッグポートもTLSをサポートしています。デバッグポートは、KubernetesのLivenessおよびReadinessチェック、ならびにPrometheus用の`/metrics`エンドポイント（有効な場合）の公開に使用されます。

TLSは、`registry.debug.tls.enabled`を`true`に設定することで有効にできます。デバッグポートのTLS設定専用に、`registry.debug.tls.secretName`で[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を提供できます。専用のシークレットが指定されていない場合、デバッグ設定は、レジストリの通常のTLS設定と`registry.tls.secretName`を共有するようにフォールバックします。

Prometheusが`https`を使用して`/metrics/`エンドポイントをスクレイプするには、証明書のCommonName属性またはSubjectAlternativeNameエントリに追加の設定が必要です。それらの要件については、[TLSが有効なエンドポイントをスクレイプするようにPrometheusを設定する](../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints)を参照してください。

## `networkpolicy`を設定する {#configuring-the-networkpolicy}

このセクションでは、レジストリの[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を制御します。この設定はオプションであり、レジストリのエグレスおよびIngressを特定のエンドポイントに制限するために使用されます。

| 名前              |  型   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | この設定により、レジストリの`NetworkPolicy`が有効になります |
| `ingress.enabled` | ブール値 | `false` | `true`に設定すると、`Ingress`Ingressネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのIngress接続がブロックされます。 |
| `ingress.rules`   |  配列  | `[]`    | Ingressポリシーのルール。詳細については<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください。 |
| `egress.enabled`  | ブール値 | `false` | `true`に設定すると、`Egress`Ingressネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのエグレス接続がブロックされます。 |
| `egress.rules`    |  配列  | `[]`    | エグレスポリシーのルール。詳細については<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください。 |

### すべての内部エンドポイントへの接続を防止するポリシーの例 {#example-policy-for-preventing-connections-to-all-internal-endpoints}

レジストリサービスは通常、オブジェクトストレージへのエグレス接続、DockerクライアントからのIngress接続、およびDNSルックアップのためのkube-DNSを必要とします。これにより、レジストリサービスに次のネットワーク制限が追加されます:

- Ingressリクエストを許可:
  - ポッド`sidekiq`、`webservice`、および`nginx-ingress`から`5000`ポートへ
  - `Prometheus`ポッドから`9235`ポートへ
- エグレスリクエストを許可:
  - `kube-dns`から`53`ポートへ
  - AWSVPCエンドポイント（S3またはSTS）のようなエンドポイント`172.16.1.0/24`から`443`ポートへ
  - インターネット`0.0.0.0/0`から`443`ポートへ

 _注意：レジストリサービスは、エンドポイントが使用されていない場合、[外部オブジェクトストレージ](../../advanced/external-object-storage)上のイメージのためにパブリックインターネットへの送信接続を必要とします_

この例は、`kube-dns`が`kube-system`ネームスペースにデプロイされ、`prometheus`が`monitoring`ネームスペースにデプロイされ、`nginx-ingress`が`nginx-ingress`ネームスペースにデプロイされたという前提に基づいています。

```yaml
networkpolicy:
  enabled: true
  ingress:
    enabled: true
    rules:
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 5000
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
          - port: 9235
      - from:
          - podSelector:
              matchLabels:
                app: sidekiq
        ports:
          - port: 5000
      - from:
          - podSelector:
              matchLabels:
                app: webservice
        ports:
          - port: 5000
  egress:
    enabled: true
    rules:
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
              cidr: 172.16.1.0/24
        ports:
          - port: 443
      - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
            - 10.0.0.0/8
```

## KEDAを設定する {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この設定はオプションであり、カスタムまたは外部メトリクスに基づいたオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する場合、`hpa`セクションで設定された値にデフォルトで設定されます。

以下が真の場合、`hpa`セクションで設定されたCPUおよびメモリのしきい値に基づいて、CPUおよびメモリのトリガーが自動的に追加されます:

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定もゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの設定の詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  型   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | 最後のトリガーがアクティブであると報告された後、リソースを0にスケールダウンするまで待機する期間 |
| `minReplicaCount`               | 整数 | `hpa.minReplicas`               | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `maxReplicaCount`               | 整数 | `hpa.maxReplicas`               | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `fallback`                      |   マップ   |                                 | KEDAフォールバック設定。[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください。 |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します。 |
| `behavior`                      |   マップ   | `hpa.behavior`                  | スケールアップおよびスケールダウン動作の仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケールをアクティブにするトリガーのリスト。`hpa.cpu`と`hpa.memory`から計算されたトリガーにデフォルトで設定されます。 |

### すべての内部エンドポイントへの接続を防止するポリシーの例 {#example-policy-for-preventing-connections-to-all-internal-endpoints-1}

レジストリサービスは通常、オブジェクトストレージへのエグレス接続、DockerクライアントからのIngress接続、およびDNSルックアップのためのkube-DNSを必要とします。これにより、レジストリサービスに次のネットワーク制限が追加されます:

- `10.0.0.0/8`ポート53へのすべてのローカルネットワークに対するエグレスリクエストが許可されます（kubeDNS用）。
- `10.0.0.0/8`上のローカルネットワークへの他のエグレスリクエストは制限されます
- `10.0.0.0/8`以外のエグレスリクエストは許可されます

 _注意：レジストリサービスは、[外部オブジェクトストレージ](../../advanced/external-object-storage)上のイメージのためにパブリックインターネットへの送信接続を必要とします_

```yaml
networkpolicy:
  enabled: true
  egress:
    enabled: true
    # The following rules enable traffic to all external
    # endpoints, except the local
    # network (except DNS requests)
    rules:
      - to:
        - ipBlock:
            cidr: 10.0.0.0/8
        ports:
        - port: 53
          protocol: UDP
      - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
            - 10.0.0.0/8
```

## レジストリ設定の定義 {#defining-the-registry-configuration}

このチャートの以下のプロパティは、基盤となる[レジストリ](https://hub.docker.com/_/registry/)コンテナの設定に関連します。GitLabとのインテグレーションに最も重要な値のみが公開されます。このインテグレーションでは、[Docker Distribution](https://github.com/docker/distribution)の`auth.token.x`設定を利用し、JWT [認証トークン](https://distribution.github.io/distribution/spec/auth/token/)を介してレジストリへの認証を制御します。

### `httpSecret` {#httpsecret}

フィールド`httpSecret`は、`secret`と`key`の2つのアイテムを含むマップです。

これが参照するキーの内容は、[レジストリ](https://hub.docker.com/_/registry/)の`http.secret`値と相関します。この値は暗号学的に生成されたランダムな文字列で入力されるべきです。

`shared-secrets`ジョブは、提供されていない場合、このシークレットを自動的に作成します。それは安全に生成された128文字の英数字文字列で満たされ、base64エンコードされます。

このシークレットを手動で作成するには:

```shell
kubectl create secret generic gitlab-registry-httpsecret --from-literal=secret=strongrandomstring
```

### 通知シークレット {#notification-secret}

通知シークレットは、GitLabアプリケーションへのさまざまな呼び出しに使用されます。Geoがプライマリサイトとセカンダリサイト間でコンテナレジストリデータの同期を管理するのに役立つなどです。

`shared-secrets`機能が有効になっている場合、`notificationSecret`シークレットオブジェクトは、提供されていない場合は自動的に作成されます。

このシークレットを手動で作成するには:

```shell
kubectl create secret generic gitlab-registry-notification --from-literal=secret=[\"strongrandomstring\"]
```

次に、これらの設定を進め、`secret`の値が上記で作成されたシークレットの名前に設定されていることを確認してください。

```yaml
global:
  # To provide your own secret
  registry:
    notificationSecret:
        secret: gitlab-registry-notification
        key: secret
```

Geoを利用し、コンテナレジストリをレプリケートすることを希望する場合は、次の2つの手順に従ってください:

1. プライマリサイトの設定で:

   ```yaml
   global:
     # To provide your own secret, as described above
     registry:
       notificationSecret:
           secret: gitlab-registry-notification
           key: secret
     geo:
       registry:
         replication:
           enabled: true
   ```

1. セカンダリサイトの設定で:

   ```yaml
   global:
     geo:
       registry:
         replication:
           enabled: true
           primaryApiUrl: <URL to primary registry>
   ```

   `primaryApiUrl`は、セカンダリサイトがプライマリサイトに対してプルを実行するために使用されます。

### Redisキャッシュシークレット {#redis-cache-secret}

Redisキャッシュシークレットは、`global.redis.auth.enabled`が`true`に設定されている場合に使用されます。

`shared-secrets`機能が有効になっている場合、`gitlab-redis-secret`シークレットオブジェクトは、提供されていない場合は自動的に作成されます。

このシークレットを手動で作成するには、[Redisパスワードの指示](../../installation/secrets.md#redis-password)を参照してください。

### `authEndpoint` {#authendpoint}

`authEndpoint`フィールドは文字列であり、[レジストリ](https://hub.docker.com/_/registry/)が認証するGitLabインスタンスへのURLを提供します。

値にはプロトコルとホスト名のみを含める必要があります。チャートテンプレートは、必要なリクエストパスを自動的に追加します。結果の値は、コンテナ内の`auth.token.realm`に入力されます。例: `authEndpoint: "https://gitlab.example.com"`

デフォルトでは、このフィールドは[グローバル設定](../globals.md)によって設定されたGitLabホスト名設定で入力されます。

### `certificate` {#certificate}

`certificate`フィールドは、`secret`と`key`の2つのアイテムを含むマップです。

 `secret`は、GitLabインスタンスによって作成されたトークンを検証するために使用される証明書バンドルを収容する[Kubernetesシークレット](https://kubernetes.io/docs/concepts/configuration/secret/)の名前を含む文字列です。

 `key`は、[レジストリ](https://hub.docker.com/_/registry/)コンテナに`auth.token.rootcertbundle`として提供される証明書バンドルを収容する`Secret`内の`key`キーの名前です。

デフォルトの例:

```yaml
certificate:
  secret: gitlab-registry
  key: registry-auth.crt
```

### ReadinessおよびLivenessプローブ {#readiness-and-liveness-probe}

デフォルトでは、デバッグポートである`5001`ポートで`/debug/health`をチェックするようにReadinessおよびLivenessプローブが設定されています。

### `validation` {#validation}

`validation`フィールドは、レジストリ内のDockerイメージ検証プロセスを制御するマップです。イメージ検証が有効な場合、レジストリは外国のレイヤーを含むWindowsイメージを拒否します。ただし、検証スタンザ内の`manifests.urls.allow`フィールドが明示的にこれらのレイヤーURLを許可するように設定されている場合は除きます。

検証はマニフェストプッシュ時にのみ行われるため、既にレジストリに存在するイメージは、このセクションの値の変更による影響を受けません。

イメージ検証はデフォルトでオフになっています。

イメージ検証を有効にするには、`registry.validation.disabled: false`を明示的に設定する必要があります。

#### `manifests` {#manifests}

`manifests`フィールドは、マニフェストに固有の検証ポリシーの設定を許可します。

`urls`セクションには`allow`と`deny`の両方のフィールドが含まれています。検証を通過するためのURLを含むマニフェストレイヤーの場合、そのレイヤーは`allow`フィールドのいずれかの正規表現と一致する必要があり、同時に`deny`フィールドのいずれの正規表現とも一致してはなりません。

|        名前        | 型  | デフォルト | 説明 |
|:------------------:|:-----:|:--------|:-----------:|
|  `referencelimit`  |  整数  | `0`     | 単一のマニフェストが持つことができるレイヤー、イメージ設定、その他のマニフェストなどの参照の最大数。`0`（デフォルト）に設定すると、この検証は無効になります。 |
| `payloadsizelimit` |  整数  | `0`     | マニフェストペイロードの最大データサイズ（バイト単位）。`0`（デフォルト）に設定すると、この検証は無効になります。 |
|    `urls.allow`    | 配列 | `[]`    | マニフェストのレイヤー内のURLを有効にする正規表現のリスト。空のままの場合（デフォルト）、URLを含むレイヤーは拒否されます。 |
|    `urls.deny`     | 配列 | `[]`    | マニフェストのレイヤー内のURLを制限する正規表現のリスト。空のままの場合（デフォルト）、`urls.allow`リストを通過したURLを持つレイヤーは拒否されません。 |

### `notifications` {#notifications}

`notifications`フィールドは、[レジストリ通知](https://distribution.github.io/distribution/about/notifications/#configuration)を設定するために使用されます。空のハッシュをデフォルト値として持ちます。

|    名前     | 型  | デフォルト | 説明 |
|:-----------:|:-----:|:--------|:-----------:|
| `endpoints` | 配列 | `[]`    | 各項目が[エンドポイント](https://distribution.github.io/distribution/about/configuration/#endpoints)に対応する項目リスト |
|  `events`   | ハッシュ  | `{}`    | [イベント](https://distribution.github.io/distribution/about/configuration/#events)通知で提供される情報 |

設定例は以下のとおりです:

```yaml
notifications:
  endpoints:
    - name: FooListener
      url: https://foolistener.com/event
      timeout: 500ms
      # DEPRECATED: use `maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243.
      # When using `maxretries`, `threshold` is ignored: https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#endpoints
      threshold: 10
      maxretries: 10
      backoff: 1s
    - name: BarListener
      url: https://barlistener.com/event
      timeout: 100ms
      # DEPRECATED: use `maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243.
      # When using `maxretries`, `threshold` is ignored: https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#endpoints
      threshold: 3
      maxretries: 5
      backoff: 1s
  events:
    includereferences: true
```

<!-- vale gitlab.Spelling = NO -->

### `hpa` {#hpa}

<!-- vale gitlab.Spelling = YES -->

この`hpa`フィールドはオブジェクトで、設定の一部として作成する[レジストリ](https://hub.docker.com/_/registry/)のインスタンス数を制御します。これは`minReplicas`の値が`2`、`maxReplicas`の値が10にデフォルト設定され、`cpu.targetAverageUtilization`を75%に設定します。

### `storage` {#storage}

```yaml
storage:
  secret:
  key: config
  extraKey:
```

この`storage`フィールドは、Kubernetesシークレットと関連付けられたキーへの参照です。このシークレットの内容は、[レジストリ設定: `storage`](https://distribution.github.io/distribution/about/configuration/#storage)から直接取得されます。詳細については、そのドキュメントを参照してください。

[AWS S3](https://distribution.github.io/distribution/storage-drivers/s3/)および[Google GCS](https://distribution.github.io/distribution/storage-drivers/gcs/)ドライバーの例は、[`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)にあります:

- [`registry.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.s3.yaml)
- [`registry.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.gcs.yaml)

S3の場合、正しい[レジストリストレージのパーミッション](https://distribution.github.io/distribution/storage-drivers/s3/#s3-permission-scopes)を付与してください。ストレージの設定に関する詳細については、管理ドキュメントの[コンテナレジストリストレージドライバー](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-storage-driver)を参照してください。

_コンテンツ_を`storage`ブロックからシークレットに配置し、以下の項目を`storage`マップに指定します:

- `secret`: KubernetesシークレットのYAMLブロック名。
- `key`: 使用するシークレット内のキーの名前。`config`がデフォルトです。
- `extraKey`: _（オプション）_コンテナ内の`/etc/docker/registry/storage/${extraKey}`にマウントされるシークレットの追加キー名。これは、`gcs`ドライバー用の`keyfile`を提供するために使用できます。

```shell
# Example using S3
kubectl create secret generic registry-storage \
    --from-file=config=registry-storage.yaml

# Example using GCS with JSON key
# - Note: `registry.storage.extraKey=gcs.json`
kubectl create secret generic registry-storage \
    --from-file=config=registry-storage.yaml \
    --from-file=gcs.json=example-project-382839-gcs-bucket.json
```

[ストレージドライバーのリダイレクトを無効にする](https://docs.gitlab.com/administration/packages/container_registry/#disable-redirect-for-storage-driver)ことで、すべてのトラフィックが別のバックエンドにリダイレクトされるのではなく、Registryサービスを介して流れるようにできます:

```yaml
storage:
  secret: example-secret
  key: config
  redirect:
    disable: true
```

`filesystem`ドライバーを使用する場合:

- このデータには永続ボリュームを提供する必要があります。
- [`hpa.minReplicas`](#hpa)は`1`に設定する必要があります。
- [`hpa.maxReplicas`](#hpa)は`1`に設定する必要があります。

回復性と簡素化のために、`s3`、`gcs`、`azure`などの外部サービスまたはその他の互換性のあるオブジェクトストレージを利用することをお勧めします。

> [!note]
> チャートは、ユーザーが指定しない場合、この設定にデフォルトで`delete.enabled: true`を入力します。これにより、MinIOのデフォルト使用とLinuxパッケージの両方で期待される動作が維持されます。ユーザーが指定した値は、このデフォルトを上書きします。

### `middleware.storage` {#middlewarestorage}

設定は`middleware.storage`が[アップストリームの規則](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#middleware)に従います:

設定はかなり一般的で、同様のパターンに従います:

```yaml
middleware:
  # See https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#middleware
  storage:
    - name: cloudfront
      options:
        baseurl: https://abcdefghijklmn.cloudfront.net/
        # `privatekey` is auto-populated with the content from the privatekey Secret.
        privatekeySecret:
          secret: cloudfront-secret-name
          # "key" value is going to be used to generate filename for PEM storage:
          #   /etc/docker/registry/middleware.storage/<index>/<key>
          key: private-key-ABC.pem
        keypairid: ABCEDFGHIJKLMNOPQRST
```

上記のコードでは、`options.privatekeySecret`はPEMファイルの内容に対応する`generic` Kubernetesシークレットです:

```shell
kubectl create secret generic cloudfront-secret-name --type=kubernetes.io/ssh-auth --from-file=private-key-ABC.pem=pk-ABCEDFGHIJKLMNOPQRST.pem
```

アップストリームで使用される`privatekey`は、チャートから`privatekey`シークレットによって自動的に入力され、指定されている場合は**ignored**。

#### `keypairid`バリアント {#keypairid-variants}

さまざまなベンダーが同じ構成に対して異なるフィールド名を使用しています:

|   ベンダー   | フィールド名 |
|:----------:|:----------:|
| Google CDN | `keyname`  |
| CloudFront | `keypairid` |

> [!note]
> 現時点では、`middleware.storage`セクションの設定のみがサポートされています。

### `debug` {#debug}

デバッグポートはデフォルトで有効になっており、ライブネス/リードネスプローブに使用されます。さらに、Prometheusのメトリクスは`metrics`の値で有効にできます。

```yaml
debug:
  addr:
    port: 5001

metrics:
  enabled: true
```

### `health` {#health}

`health`プロパティはオプションであり、ストレージドライバーのバックエンドストレージに対する定期的なヘルスチェックのプリファレンスを含みます。詳細については、Dockerの[設定ドキュメント](https://distribution.github.io/distribution/about/configuration/#health)を参照してください。

```yaml
health:
  storagedriver:
    enabled: false
    interval: 10s
    threshold: 3
```

### `reporting` {#reporting}

`reporting`プロパティはオプションであり、[レポート](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#reporting)を有効にします。

```yaml
reporting:
  sentry:
    enabled: true
    dsn: 'https://<key>@sentry.io/<project>'
    environment: 'production'
```

### `profiling` {#profiling}

`profiling`プロパティはオプションであり、[継続的なプロファイリング](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#profiling)を有効にします。

```yaml
profiling:
  stackdriver:
    enabled: true
    credentials:
      secret: gitlab-registry-profiling-creds
      key: credentials
    service: gitlab-registry
```

### `database` {#database}

{{< history >}}

- GitLab 16.4で[ベータ](https://docs.gitlab.com/policy/development_stages_support/#beta)機能として[導入](https://gitlab.com/groups/gitlab-org/-/epics/5521)されました。
- GitLab 17.3で[一般公開](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)になりました。

{{< /history >}}

`database`プロパティはオプションであり、[メタデータデータベース](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#database)を有効にします。

この機能を有効にする前に、[管理ドキュメント](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)を参照してください。

> [!note]
> この機能にはPostgreSQL 13以降が必要です。

```yaml
database:
  enabled: true
  host: registry.db.example.com
  port: 5432
  user: registry
  password:
    secret: gitlab-postgresql-password
    key: postgresql-registry-password
  dbname: registry
  sslmode: verify-full
  ssl:
    secret: gitlab-registry-postgresql-ssl
    clientKey: client-key.pem
    clientCertificate: client-cert.pem
    serverCA: server-ca.pem
  connecttimeout: 5s
  draintimeout: 2m
  preparedstatements: false
  primary: 'primary.record.fqdn'
  pool:
    maxidle: 25
    maxopen: 25
    maxlifetime: 5m
    maxidletime: 5m
  migrations:
    enabled: true
    activeDeadlineSeconds: 3600
    backoffLimit: 6
  backgroundMigrations:
    enabled: true
    maxJobRetries: 3
    jobInterval: 10s
```

#### ロードバランシング {#load-balancing}

> [!warning]
> これは活発に開発中の実験的機能であり、本番環境では使用しないでください。

`loadBalancing`セクションでは、[データベースのロードバランシング](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#loadbalancing)を設定できます。この機能が動作するには、対応する[Redis接続](#redis-for-database-load-balancing)を有効にする必要があります。

#### データベースの管理 {#manage-the-database}

データベースの作成と保守に関する詳細は、[Container Registryメタデータデータベース](metadata_database.md)のページを参照してください。

### `gc`プロパティ {#gc-property}

`gc`プロパティは、[オンラインガベージコレクション](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#gc)のオプションを提供します。

オンラインガベージコレクションには、[メタデータデータベース](#database)が有効になっている必要があります。データベースを使用する際は、オンラインガベージコレクションを使用する必要がありますが、メンテナンスやデバッグのために一時的にオンラインガベージコレクションを無効にすることもできます。

```yaml
gc:
  disabled: false
  maxbackoff: 24h
  noidlebackoff: false
  transactiontimeout: 10s
  reviewafter: 24h
  manifests:
    disabled: false
    interval: 5s
  blobs:
    disabled: false
    interval: 5s
    storagetimeout: 5s
```

### Redisキャッシュ {#redis-cache}

> [!note]
> Redisキャッシュは、バージョン16.4以降のベータ機能です。この機能を有効にする前に、[フィードバックイシュー](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)と関連ドキュメントをレビューしてください。

`redis.cache`プロパティはオプションであり、[Redisキャッシュ](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#cache-1)に関連するオプションを提供します。Registryで`redis.cache`を使用するには、[メタデータデータベース](#database)を有効にする必要があります。

例: 

```yaml
redis:
  cache:
    enabled: true
    host: localhost
    port: 16379
    password:
      secret: gitlab-redis-secret
      key: redis-password
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
    tls:
      enabled: true
      insecure: true
    pool:
      size: 10
      maxlifetime: 1h
      idletimeout: 300s
```

#### クラスター {#cluster}

`redis.cache.cluster`プロパティは、Redisクラスターに接続するためのホストとポートのリストです。例: 

```yaml
redis:
  cache:
    enabled: true
    host: redis.example.com
    cluster:
      - host: host1.example.com
        port: 6379
      - host: host2.example.com
        port: 6379
```

#### Sentinel {#sentinels}

`redis.cache`は`global.redis.sentinels`設定を使用できます。ローカル値を指定することができ、グローバル値よりも優先されます。例: 

```yaml
redis:
  cache:
    enabled: true
    host: redis.example.com
    sentinels:
      - host: sentinel1.example.com
        port: 16379
      - host: sentinel2.example.com
        port: 16379
```

#### Sentinelパスワードのサポート {#sentinel-password-support}

{{< history >}}

- GitLab 17.2で[導入されました](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3805)。

{{< /history >}}

`redis.cache`は、Redis Sentinelの認証パスワードを使用するために、[`global.redis.sentinelAuth`設定](../globals.md#redis-sentinel-password-support)も使用できます。ローカル値を指定することができ、グローバル値よりも優先されます。例: 

```yaml
redis:
  cache:
    enabled: true
    host: redis.example.com
    sentinels:
      - host: sentinel1.example.com
        port: 16379
      - host: sentinel2.example.com
        port: 16379
    sentinelpassword:
      enabled: true
      secret: registry-redis-sentinel
      key: password
```

### Redisレートリミッター {#redis-rate-limiter}

> [!warning]
> Redisのレート制限は[開発中](https://gitlab.com/groups/gitlab-org/-/epics/13237)です。より詳しい機能の詳細は、利用可能になり次第このセクションに追加されます。

`redis.rateLimiting`プロパティはオプションであり、[Redisレートリミッター](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#ratelimiter)に関連するオプションを提供します。

例: 

```yaml
redis:
  rateLimiting:
    enabled: true
    host: localhost
    port: 16379
    username: registry
    password:
      secret: gitlab-redis-secret
      key: redis-password
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
    tls:
      enabled: true
      insecure: true
    pool:
      size: 10
      maxlifetime: 1h
      idletimeout: 300s
```

### データベースロードバランシング用Redis {#redis-for-database-load-balancing}

{{< details >}}

ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- Charts 8.11で[導入](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4180)されました。

{{< /history >}}

> [!warning]
> [データベースロードバランシング](#load-balancing)は活発に開発中の実験的機能であり、本番環境では使用しないでください。進捗状況を追跡し、フィードバックを共有するには、[エピック8591](https://gitlab.com/groups/gitlab-org/-/epics/8591)を使用してください。

`redis.loadBalancing`プロパティはオプションであり、[データベースロードバランシングのためのRedis接続](https://gitlab.com/gitlab-org/container-registry/-/blob/b4d71f24a9ae31288401a3459228aa7f8d3dd8f0/docs/configuration.md#loadbalancing-1)に関連するオプションを提供します。

例: 

```yaml
redis:
  loadBalancing:
    enabled: true
    host: localhost
    port: 16379
    username: registry
    password:
      secret: gitlab-redis-secret
      key: redis-password
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
    tls:
      enabled: true
      insecure: true
    pool:
      size: 10
      maxlifetime: 1h
      idletimeout: 300s
```

## ガベージコレクション {#garbage-collection}

Docker Registryは時間の経過とともに余分なデータを蓄積しますが、これは[ガベージコレクション](https://distribution.github.io/distribution/about/garbage-collection/)を使用して解放できます。[現在](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1586)、このチャートでガベージコレクションを完全に自動化またはスケジュールする方法はありません。

> [!warning]
> [メタデータデータベース](#database)を使用する場合は、[オンラインガベージコレクション](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#gc)を使用する必要があります。メタデータデータベースで手動ガベージコレクションを使用すると、データ損失につながります。オンラインガベージコレクションは、手動でガベージコレクションを実行する必要性を完全に置き換えます。

### 手動ガベージコレクション {#manual-garbage-collection}

手動ガベージコレクションには、まずRegistryが読み取り専用モードになっている必要があります。Helmを使用してGitLabチャートをすでにインストールし、それを`mygitlab`と名付け、ネームスペース`gitlabns`にインストールしたと仮定します。以下のコマンドのこれらの値を、実際の設定に従って置き換えてください。

```shell
# Because of https://github.com/helm/helm/issues/2948 we can't rely on --reuse-values, so let's get our current config.
helm get values mygitlab > mygitlab.yml
# Upgrade Helm installation and configure the registry to be read-only.
# The --wait parameter makes Helm wait until all ressources are in ready state, so we are safe to continue.
helm upgrade mygitlab gitlab/gitlab -f mygitlab.yml --set registry.maintenance.readonly.enabled=true --wait
# Our registry is in r/o mode now, so let's get the name of one of the registry Pods.
# Note down the Pod name and replace the '<registry-pod>' placeholder below with that value.
# Replace the single quotes to double quotes (' => ") if you are using this with Windows' cmd.exe.
kubectl get pods -n gitlabns -l app=registry -o jsonpath='{.items[0].metadata.name}'
# Run the actual garbage collection. Check the registry's manual if you really want the '-m' parameter.
kubectl exec -n gitlabns <registry-pod> -- /bin/registry garbage-collect -m /etc/docker/registry/config.yml
# Reset registry back to original state.
helm upgrade mygitlab gitlab/gitlab -f mygitlab.yml --wait
# All done :)
```

### Container Registryに対する管理コマンドの実行 {#running-administrative-commands-against-the-container-registry}

管理コマンドは、`registry`バイナリと必要な設定の両方が利用可能なRegistryポッドからのみ、Container Registryに対して実行できます。ツールボックスポッドからこの機能を提供する方法について議論するため、[イシュー #2629](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2629)がオープンされています。

管理コマンドを実行するには:

1. Registryポッドに接続します:

   ```shell
   kubectl exec -it <registry-pod> -- bash
   ```

1. Registryポッド内では、`registry`バイナリが`PATH`で利用可能であり、直接使用できます。設定ファイルは`/etc/docker/registry/config.yml`にあります。次の例は、データベースの移行のステータスを確認します:

   ```shell
   registry database migrate status /etc/docker/registry/config.yml
   ```

詳細およびその他の利用可能なコマンドについては、関連するドキュメントを参照してください:

- [一般的なRegistryドキュメント](https://docs.docker.com/registry/)
- [GitLab固有のRegistryドキュメント](https://gitlab.com/gitlab-org/container-registry/-/tree/master/docs-gitlab)

## Registryレートリミッター設定 {#registry-rate-limiter-configuration}

Registryは、コンテナRegistryインスタンスへのトラフィックを制御するために、レート制限で設定できます。これは、乱用、DoS攻撃、または過度な使用からRegistryを保護するのに役立ちます。

### 注記 {#notes}

- レート制限には、`registry.redis.rateLimiting`設定を介してRedisが適切に設定されている必要があります。
- レート制限はデフォルトで無効になっています。有効にするには`registry.rateLimiter.enabled: true`を設定します。
- リミッターは、優先順位（最も低い値が最初）に従って適用されます。
- `log_only`オプションは、レート制限を適用する前にテストするのに役立ちます。

### レートリミッター設定 {#rate-limiter-configuration}

コンテナRegistryのレート制限を有効にして設定するには、`registry.rateLimiter`設定を使用できます:

```yaml
registry:
  rateLimiter:
    enabled: true
    limiters:
      - name: global_rate_limit
        description: "Global IP rate limit"
        log_only: false
        match:
          type: IP
        precedence: 10
        limit:
          rate: 5000
          period: "minute"
          burst: 8000
        action:
          warn_threshold: 0.7
          warn_action: "log"
          hard_action: "block"
```

### リミッターの設定 {#limiters-configuration}

レートリミッターは、レート制限ルールを定義するためにリミッターのリストを使用します。各リミッターには次のプロパティがあります:

- `name`: リミッターの一意の識別子
- `description`: リミッターの目的を人間が読み取り可能な形式で記述したもの
- `log_only`: `true`に設定すると、違反は強制適用されずにログに記録されるだけです。
- `precedence`: リミッターが評価される順序を定義します（最も低い値が最初）。
- `match`: リクエストを照合するための基準
- `limit`: レート制限パラメータ
- `action`: 制限に達したときに実行するアクション

### 制限設定 {#limit-configuration}

`limit`セクションは実際のレート制限パラメータを定義します:

```yaml
limit:
  rate: 100       # Number of requests allowed
  period: "minute" # Time period (second, minute, hour, day)
  burst: 200      # Allowed burst capacity
```

### アクション設定 {#action-configuration}

`action`セクションは、制限に近づいたとき、または達したときに何が起こるかを定義します:

```yaml
action:
  warn_threshold: 0.7      # Percentage of limit to trigger warning
  warn_action: "log"       # Action when warning threshold is reached
  hard_action: "block"     # Action when limit is reached
```

### 例 {#examples}

#### グローバルIPレート制限 {#global-ip-rate-limit}

この例では、単一のIPアドレスからのすべてのリクエストを制限します:

```yaml
- name: global_rate_limit
  description: "Global IP rate limit"
  log_only: false
  match:
    type: IP
  precedence: 10
  limit:
    rate: 5000
    period: "minute"
    burst: 8000
  action:
    warn_threshold: 0.7
    warn_action: "log"
    hard_action: "block"
```
