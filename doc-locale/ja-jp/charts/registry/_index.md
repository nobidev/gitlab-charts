---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナレジストリの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

`registry`サブチャートは、Kubernetes上の完全なクラウドネイティブGitLabデプロイメントにRegistryコンポーネントを提供します。このサブチャートは、[アップストリームチャート](https://github.com/docker/distribution-library-image)に基づいており、GitLab [コンテナレジストリ](https://gitlab.com/gitlab-org/container-registry)が含まれています。

このチャートは、主に次の3つの部分で構成されています。

- [サービス](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/service.yaml)、
- [デプロイ](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/deployment.yaml)、
- [ConfigMap](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/configmap.yaml)。

すべての設定は、`/etc/docker/registry/config.yml`変数を使用して、[Registry設定ドキュメント](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads)に従って処理され、`ConfigMap`から`Deployment`に入力されます。`ConfigMap`はアップストリームのデフォルトをオーバーライドしますが、[それらに基づいています](https://github.com/docker/distribution-library-image/blob/master/config-example.yml)。詳細については、以下を参照してください。

- [`distribution/cmd/registry/config-example.yml`](https://github.com/docker/distribution/blob/master/cmd/registry/config-example.yml)
- [`distribution-library-image/config-example.yml`](https://github.com/docker/distribution-library-image/blob/master/config-example.yml)

## 設計の選択 {#design-choices}

Kubernetes `Deployment`は、インスタンスの簡単なスケーリングを可能にすると同時に、[ローリングアップデート](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/)を可能にするために、このチャートのデプロイ方法として選択されました。

このチャートでは、2つの必須シークレットと1つのオプションのシークレットを使用します。

### 必須 {#required}

- `global.registry.certificate.secret`:関連付けられたGitLabインスタンスによって提供される認証トークンを検証するための公開証明書バンドルを含むグローバルシークレット。認証エンドポイントとしてGitLabを使用する方法については、[ドキュメント](https://docs.gitlab.com/administration/packages/container_registry/#use-an-external-container-registry-with-gitlab-as-an-auth-endpoint)を参照してください。
- `global.registry.httpSecret.secret`:レジストリポッド間の[共有シークレット](https://distribution.github.io/distribution/about/configuration/#http)を含むグローバルシークレット。

### オプション {#optional}

- `profiling.stackdriver.credentials.secret`:Stackdriver profilingが有効になっていて、明示的なサービスアカウント認証情報を提供する必要がある場合、このシークレットの値 (`credentials`キー (デフォルト)) はGCPサービスアカウントJSON認証情報です。GKEを使用していて、[ワークロードアイデンティティ](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) (またはノードサービスアカウント (推奨されません)) を使用してサービスアカウントをワークロードに提供している場合、このシークレットは不要であり、提供しないでください。どちらの場合も、サービスアカウントにはロール`roles/cloudprofiler.agent`または同等の[手動権限](https://cloud.google.com/profiler/docs/iam#roles)が必要です。

## 設定 {#configuration}

以下に、設定の主要なセクションについて説明します。親チャートから設定する場合、これらの値は次のようになります。

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

このチャートをスタンドアロンとしてデプロイする場合は、最上位レベルにある`registry`を削除します。

## インストールパラメータ {#installation-parameters}

| パラメータ                                                | デフォルト                                                              | 説明 |
|----------------------------------------------------------|----------------------------------------------------------------------|-------------|
| `annotations`                                            |                                                                      | Podアノテーション |
| `podLabels`                                              |                                                                      | 補助的なPodラベル。セレクターには使用されません。 |
| `common.labels`                                          |                                                                      | このチャートによって作成されたすべてのオブジェクトに適用される補助ラベル。 |
| `authAutoRedirect`                                       | `true`                                                               | 認証自動リダイレクト (Windowsクライアントが動作するにはtrueである必要があります) |
| `authEndpoint`                                           | `global.hosts.gitlab.name`                                           | 認証エンドポイント (ホストとポートのみ) |
| `certificate.secret`                                     | `gitlab-registry`                                                    | JWT証明書 |
| `debug.addr.port`                                        | `5001`                                                               | デバッグポート  |
| `debug.tls.enabled`                                      | `false`                                                              | レジストリのデバッグポートに対してTLSを有効にします。メトリクスのエンドポイント (有効な場合) だけでなく、稼働状態および準備状態のプローブにも影響します |
| `debug.tls.secretName`                                   |                                                                      | レジストリのデバッグエンドポイントの有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定されておらず、`debug.tls.enabled=true`の場合、デバッグTLS設定はデフォルトでレジストリのTLS証明書になります。 |
| `debug.prometheus.enabled`                               | `false`                                                              | **非推奨** `metrics.enabled`を使用 |
| `debug.prometheus.path`                                  | `""`                                                                 | **非推奨** `metrics.path`を使用 |
| `metrics.enabled`                                        | `false`                                                              | メトリクスのエンドポイントをスクレイピングに使用できるようにする必要がある場合 |
| `metrics.path`                                           | `/metrics`                                                           | メトリクスのエンドポイントパス |
| `metrics.serviceMonitor.enabled`                         | `false`                                                              | ServiceMonitorを作成してPrometheus Operatorがメトリクスのスクレイピングを管理できるようにする場合、これを有効にすると、`prometheus.io`スクレイプアノテーションが削除されることに注意してください |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                                 | ServiceMonitorに追加する追加ラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                                 | ServiceMonitorの追加のエンドポイント構成 |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                                 | Podが正常に終了するために必要なオプションの秒単位の期間。 |
| `deployment.strategy`                                    | `{}`                                                                 | デプロイメントで使用される更新戦略を構成できます |
| `draintimeout`                                           | `'0'`                                                                | SIGTERMシグナルを受信した後、HTTP接続のドレインを待機する時間 (例: `'10s'`) |
| `relativeurls`                                           | `false`                                                              | ロケーションヘッダーでレジストリが相対URLを返すようにします。 |
| `enabled`                                                | `true`                                                               | レジストリフラグを有効にする |
| `extraContainers`                                        |                                                                      | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列 |
| `extraInitContainers`                                    |                                                                      | 含める追加のinitコンテナのリスト |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`                    | Behaviorには、アップスケールおよびダウンスケールBehaviorの仕様が含まれています (`autoscaling/v2beta2`以上が必要です) |
| `hpa.customMetrics`                                      | `[]`                                                                 | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています (デフォルトの`targetAverageUtilization`で構成された平均CPU使用率の使用をオーバーライドします) |
| `hpa.cpu.targetType`                                     | `Utilization`                                                        | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`                             |                                                                      | オートスケールCPUターゲット値を設定する |
| `hpa.cpu.targetAverageUtilization`                       | `75`                                                                 | オートスケールCPUターゲット使用率を設定する |
| `hpa.memory.targetType`                                  |                                                                      | オートスケールメモリーターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`                          |                                                                      | オートスケールメモリーターゲット値を設定する |
| `hpa.memory.targetAverageUtilization`                    |                                                                      | オートスケールメモリーターゲット使用率を設定する |
| `hpa.minReplicas`                                        | `2`                                                                  | レプリカの最小数 |
| `hpa.maxReplicas`                                        | `10`                                                                 | レプリカの最大数 |
| `httpSecret`                                             |                                                                      | HTTPSシークレット |
| `extraEnvFrom`                                           |                                                                      | 公開する他のデータソースからの追加の環境変数のリスト |
| `image.pullPolicy`                                       |                                                                      | レジストリイメージのプルポリシー |
| `image.pullSecrets`                                      |                                                                      | イメージリポジトリに使用するシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry` | レジストリイメージ |
| `image.tag`                                              | `v4.15.2-gitlab`                                                     | 使用するイメージのバージョン |
| `init.image.repository`                                  |                                                                      | initContainerイメージ |
| `init.image.tag`                                         |                                                                      | initContainerイメージtag |
| `init.containerSecurityContext`                          |                                                                      | initContainer固有の[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                               | initContainer固有:コンテナを開始するユーザーID |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                              | initContainer固有:プロセスが親プロセスよりも多くの権限を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                               | initContainer固有:コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                          | initContainer固有:コンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `keda.enabled`                                           | `false`                                                              | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用 |
| `keda.pollingInterval`                                   | `30`                                                                 | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                                    | `300`                                                                | リソースを0にスケールバックする前に、最後のトリガーがアクティブとレポートされてから待機する期間 |
| `keda.minReplicaCount`                                   | `hpa.minReplicas`                                                    | KEDAがリソースをスケールダウンするレプリカの最小数。 |
| `keda.maxReplicaCount`                                   | `hpa.maxReplicas`                                                    | KEDAがリソースをスケールアップするレプリカの最大数。 |
| `keda.fallback`                                          |                                                                      | KEDAフォールバック構成については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                                      | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`                     |                                                                      | `ScaledObject`の削除後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                          | `hpa.behavior`                                                       | アップスケールおよびダウンスケールBehaviorの仕様。 |
| `keda.triggers`                                          |                                                                      | ターゲットリソースのスケーリングをアクティブ化するトリガーのリスト。デフォルトでは、`hpa.cpu`および`hpa.memory`から計算されたトリガーになります |
| `log`                                                    | `{level: info, fields: {service: registry}}`                         | ログ記録オプションを設定する |
| `minio.bucket`                                           | `global.registry.bucket`                                             | レガシーレジストリバケット名 |
| `maintenance.readonly.enabled`                           | `false`                                                              | レジストリの読み取り専用モードを有効にする |
| `maintenance.uploadpurging.enabled`                      | `true`                                                               | アップロードのパージを有効にする |
| `maintenance.uploadpurging.age`                          | `168h`                                                               | 指定された期間より古いアップロードをパージする |
| `maintenance.uploadpurging.interval`                     | `24h`                                                                | アップロードのパージが実行される頻度 |
| `maintenance.uploadpurging.dryrun`                       | `false`                                                              | 削除せずにパージされるアップロードのみを一覧表示する |
| `priorityClassName`                                      |                                                                      | ポッドに割り当てられた[優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |
| `reporting.sentry.enabled`                               | `false`                                                              | Sentryを使用したレポート作成を有効にする |
| `reporting.sentry.dsn`                                   |                                                                      | Sentry DSN (データソース名) |
| `reporting.sentry.environment`                           |                                                                      | Sentry [環境](https://docs.sentry.io/concepts/key-terms/environments/) |
| `profiling.stackdriver.enabled`                          | `false`                                                              | Stackdriverを使用した継続的なプロファイリングを有効にする |
| `profiling.stackdriver.credentials.secret`               | `gitlab-registry-profiling-creds`                                    | 認証情報を含むシークレットの名前 |
| `profiling.stackdriver.credentials.key`                  | `credentials`                                                        | 認証情報が格納されているシークレットキー |
| `profiling.stackdriver.service`                          | `RELEASE-registry` (テンプレート化されたサービス名)                          | プロファイルを記録するStackdriverサービスの名前 |
| `profiling.stackdriver.projectid`                        | 実行中のGCPプロジェクト                                            | プロファイルをレポートするGCPプロジェクト |
| `database.configure`                                     | `false`                                                              | 有効にせずに、レジストリチャートにデータベース設定を入力します。[既存のレジストリを移行する](metadata_database.md#existing-registries)場合に必要です。 |
| `database.enabled`                                       | `false`                                                              | メタデータデータベースを有効にします。これは試験的な機能であり、本番環境で使用しないでください。 |
| `database.host`                                          | `global.psql.host`                                                   | データベースサーバーのホスト名。 |
| `database.port`                                          | `global.psql.port`                                                   | データベースサーバーポート。 |
| `database.user`                                          |                                                                      | データベースユーザー名。 |
| `database.password.secret`                               | `RELEASE-registry-database-password`                                 | データベースパスワードを含むシークレットの名前。 |
| `database.password.key`                                  | `password`                                                           | データベースパスワードが格納されているシークレットキー。 |
| `database.name`                                          |                                                                      | データベース名。 |
| `database.sslmode`                                       |                                                                      | SSLモード。`disable`、`allow`、`prefer`、`require`、`verify-ca`、または`verify-full`のいずれか。 |
| `database.ssl.secret`                                    | `global.psql.ssl.secret`                                             | クライアント証明書、キー、認証局を含むシークレット。デフォルトはメインのPostgreSQL SSLシークレットです。 |
| `database.ssl.clientCertificate`                         | `global.psql.ssl.clientCertificate`                                  | クライアント証明書を参照するシークレット内のキー。 |
| `database.ssl.clientKey`                                 | `global.psql.ssl.clientKey`                                          | クライアントキーを参照するシークレット内のキー。 |
| `database.ssl.serverCA`                                  | `global.psql.ssl.serverCA`                                           | 認証局 (CA) を参照するシークレット内のキー。 |
| `database.connecttimeout`                                | `0`                                                                  | 接続を待機する最大時間。0または指定されていない場合は、無期限に待機することを意味します。 |
| `database.draintimeout`                                  | `0`                                                                  | シャットダウン時にすべての接続をドレインするまで待機する最大時間。0または指定されていない場合は、無期限に待機することを意味します。 |
| `database.preparedstatements`                            | `false`                                                              | 準備されたステートメントを有効にします。PgBouncerとの互換性のために、デフォルトで無効になっています。 |
| `database.primary`                                       | `false`                                                              | ターゲットプライマリデータベースサーバー。これは、registry `database.migrations`の実行時にターゲットとする専用のFQDNを指定するために使用されます。指定されていない場合、`host`は`database.migrations`の実行に使用されます。 |
| `database.pool.maxidle`                                  | `0`                                                                  | アイドル接続プール内の接続の最大数。`maxopen`が`maxidle`より小さい場合、`maxidle`は`maxopen`の制限に合わせて縮小されます。0または指定されていない場合は、アイドル接続がないことを意味します。 |
| `database.pool.maxopen`                                  | `0`                                                                  | データベースへのオープン接続の最大数。`maxopen`が`maxidle`より小さい場合、`maxidle`は`maxopen`の制限に合わせて縮小されます。0または指定されていない場合は、無制限のオープン接続を意味します。 |
| `database.pool.maxlifetime`                              | `0`                                                                  | 接続を再利用できる最大時間。期限切れの接続は、再利用前に遅延的に閉じられる場合があります。0または指定されていない場合は、無制限の再利用を意味します。 |
| `database.pool.maxidletime`                              | `0`                                                                  | 接続がアイドル状態になる可能性がある最大時間。期限切れの接続は、再利用前に遅延的に閉じられる場合があります。0または指定されていない場合は、無制限の期間を意味します。 |
| `database.loadBalancing.enabled`                         | `false`                                                              | データベースのロードバランシングを有効にします。これは試験的な機能であり、本番環境で使用しないでください。 |
| `database.loadBalancing.nameserver.host`                 | `localhost`                                                          | DNSレコードのルックアップに使用するネームサーバーのホスト。 |
| `database.loadBalancing.nameserver.port`                 | `8600`                                                               | DNSレコードのルックアップに使用するネームサーバーのポート。 |
| `database.loadBalancing.record`                          |                                                                      | ルックアップするSRVレコード。このオプションは、サービスディスカバリが機能するために必要です。 |
| `database.loadBalancing.replicaCheckInterval`            | `1m`                                                                 | レプリカの状態をチェックする最小時間。 |
| `database.migrations.enabled`                            | `true`                                                               | Chartの最初のデプロイメントおよびアップグレード時に、移行ジョブが自動的に移行を実行できるようにします。移行は、実行中のRegistryポッド内から手動で実行することもできます。 |
| `database.migrations.activeDeadlineSeconds`              | `3600`                                                               | 移行ジョブで[activeDeadlineSeconds](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup)を設定します。 |
| `database.migrations.annotations`                        | `{}`                                                                 | 移行ジョブに追加する追加のアノテーション。 |
| `database.migrations.backoffLimit`                       | `6`                                                                  | 移行ジョブで[backoffLimit](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup)を設定します。 |
| `database.backgroundMigrations.enabled`                  | `false`                                                              | データベースのバックグラウンド移行を有効にします。これはRegistryメタデータデータベースの実験的な機能です。本番環境では使用しないでください。動作の詳細な説明については、[仕様](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/database-background-migrations.md?ref_type=heads)を参照してください。 |
| `database.backgroundMigrations.jobInterval`              |                                                                      | 各バックグラウンド移行ジョブワーカーの実行間のスリープ間隔。指定されていない場合、[デフォルト値はレジストリによって設定されます](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#backgroundmigrations)。 |
| `database.backgroundMigrations.maxJobRetries`            |                                                                      | 失敗したバックグラウンド移行ジョブの最大再試行回数。指定されていない場合、[デフォルト値はレジストリによって設定されます](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#backgroundmigrations)。 |
| `gc.disabled`                                            | `true`                                                               | `true`に設定すると、オンラインGCワーカーが無効になります。 |
| `gc.maxbackoff`                                          | `24h`                                                                | エラーが発生した場合に、ワーカーの実行間でスリープするために使用される最大指数バックオフ期間。`gc.noidlebackoff`が`true`でない限り、処理するタスクがない場合にも適用されます。最大33% のランダム化されたジッター係数が常に加算されるため、これは絶対的な最大値ではないことに注意してください。 |
| `gc.noidlebackoff`                                       | `false`                                                              | `true`に設定すると、処理するタスクがない場合に、ワーカーの実行間の指数バックオフが無効になります。 |
| `gc.transactiontimeout`                                  | `10s`                                                                | 各ワーカーの実行のデータベーストランザクションのタイムアウト。各ワーカーは、開始時にデータベーストランザクションを開始します。このタイムアウトを超過すると、停止または長時間実行されるトランザクションを回避するために、ワーカーの実行はキャンセルされます。 |
| `gc.blobs.disabled`                                      | `false`                                                              | `true`に設定すると、blobのGCワーカーが無効になります。 |
| `gc.blobs.interval`                                      | `5s`                                                                 | 各ワーカーの実行間の最初のスリープ間隔。 |
| `gc.blobs.storagetimeout`                                | `5s`                                                                 | ストレージ操作のタイムアウト。ストレージバックエンドでぶら下がっているblobを削除するリクエストの期間を制限するために使用されます。 |
| `gc.manifests.disabled`                                  | `false`                                                              | `true`に設定すると、マニフェストのGCワーカーが無効になります。 |
| `gc.manifests.interval`                                  | `5s`                                                                 | 各ワーカーの実行間の最初のスリープ間隔。 |
| `gc.reviewafter`                                         | `24h`                                                                | ガベージコレクターがレビュー用にレコードをピックアップする必要がある最小時間。`-1`は待機しないことを意味します。 |
| `securityContext.fsGroup`                                | `1000`                                                               | ポッドを開始するグループID |
| `securityContext.runAsUser`                              | `1000`                                                               | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                                                      | ボリュームの所有権と権限を変更するためのポリシー (Kubernetes 1.23が必要) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                                     | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                                      | コンテナが開始される[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `containerSecurityContext.runAsUser`                     | `1000`                                                               | コンテナが開始される特定のsecurityContextユーザーIDを上書きできるようにします |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                              | Gitalyコンテナのプロセスが親プロセスよりも多くの権限を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                               | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                          | Gitalyコンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                              | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                              | ServiceAccountを使用するかどうかを示します |
| `serviceLabels`                                          | `{}`                                                                 | 補助的なサービスラベル |
| `tokenService`                                           | `container_registry`                                                 | JWTトークンサービス |
| `tokenIssuer`                                            | `gitlab-issuer`                                                      | JWTトークン発行者 |
| `tolerations`                                            | `[]`                                                                 | ポッド割り当ての容認ラベル |
| `affinity`                                               | `{}`                                                                 | ポッド割り当てのアフィニティルール |
| `middleware.storage`                                     |                                                                      | ミドルウェアストレージの構成レイヤー ([インスタンスのS3](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#example-middleware-configuration)) |
| `redis.cache.enabled`                                    | `false`                                                              | `true`に設定すると、Redisキャッシュが有効になります。この機能は、[メタデータデータベース](#database)が有効になっているかどうかによって異なります。リポジトリメタデータは、構成されたRedisインスタンスにキャッシュされます。 |
| `redis.cache.host`                                       | `<Redis URL>`                                                        | Redisインスタンスのホスト名。空の場合、値は`global.redis.host:global.redis.port`として入力されます。 |
| `redis.cache.port`                                       | `6379`                                                               | Redisインスタンスのポート。 |
| `redis.cache.sentinels`                                  | `[]`                                                                 | ホストとポートを持つセンチネルを一覧表示します。 |
| `redis.cache.mainname`                                   |                                                                      | メインサーバー名。Sentinelにのみ適用されます。 |
| `redis.cache.password.enabled`                           | `false`                                                              | Registryで使用されるRedisキャッシュがパスワードで保護されているかどうかを示します。 |
| `redis.cache.password.secret`                            | `gitlab-redis-secret`                                                | Redisパスワードを含むシークレットの名前。`shared-secrets`機能が有効になっている場合、これが指定されていない場合は自動的に作成されます。 |
| `redis.cache.password.key`                               | `redis-password`                                                     | Redisパスワードが格納されているシークレットキー。 |
| `redis.cache.sentinelpassword.enabled`                   | `false`                                                              | Redis Sentinelがパスワードで保護されているかどうかを示します。`redis.cache.sentinelpassword`が空の場合、`global.redis.sentinelAuth`の値が使用されます。`redis.cache.sentinels`が定義されている場合にのみ使用されます。 |
| `redis.cache.sentinelpassword.secret`                    | `gitlab-redis-secret`                                                | Redis Sentinelパスワードを格納しているシークレットの名前。 |
| `redis.cache.sentinelpassword.key`                       | `redis-sentinel-password`                                            | Redis Sentinelパスワードが格納されているシークレットキー。 |
| `redis.cache.db`                                         | `0`                                                                  | 各接続に使用するデータベースの名前。 |
| `redis.cache.dialtimeout`                                | `0s`                                                                 | Redisインスタンスへの接続のタイムアウト。デフォルトでは、タイムアウトはありません。 |
| `redis.cache.readtimeout`                                | `0s`                                                                 | Redisインスタンスからの読み取りのタイムアウト。デフォルトでは、タイムアウトはありません。 |
| `redis.cache.writetimeout`                               | `0s`                                                                 | Redisインスタンスへの書き込みのタイムアウト。デフォルトでは、タイムアウトはありません。 |
| `redis.cache.tls.enabled`                                | `false`                                                              | TLSを有効にするには、`true`に設定します。 |
| `redis.cache.tls.insecure`                               | `false`                                                              | TLS経由で接続する際にサーバー名の検証を無効にするには、`true`に設定します。 |
| `redis.cache.pool.size`                                  | `10`                                                                 | ソケット接続の最大数。デフォルトは10接続です。 |
| `redis.cache.pool.maxlifetime`                           | `1h`                                                                 | クライアントが接続を再試行する接続時間。デフォルトでは、古くなった接続は閉じません。 |
| `redis.cache.pool.idletimeout`                           | `300s`                                                               | 非アクティブな接続を閉じるまでの待機時間。 |
| `redis.rateLimiting.enabled`                             | `false`                                                              | `true`に設定すると、Redisレートリミッターが有効になります。この機能は開発中です。 |
| `redis.rateLimiting.host`                                | `<Redis URL>`                                                        | Redisインスタンスのホスト名。空の場合、値は`global.redis.host:global.redis.port`として入力されます。 |
| `redis.rateLimiting.port`                                | `6379`                                                               | Redisインスタンスのポート。 |
| `redis.rateLimiting.cluster`                             | `[]`                                                                 | ホストとポートを持つアドレスのリスト。 |
| `redis.rateLimiting.sentinels`                           | `[]`                                                                 | ホストとポートを持つSentinelのリスト。 |
| `redis.rateLimiting.mainname`                            |                                                                      | mainサーバー名。Sentinelにのみ適用できます。 |
| `redis.rateLimiting.username`                            |                                                                      | Redisインスタンスへの接続に使用されるユーザー名。 |
| `redis.rateLimiting.password.enabled`                    | `false`                                                              | Redisインスタンスがパスワードで保護されているかどうかを示します。 |
| `redis.rateLimiting.password.secret`                     | `gitlab-redis-secret`                                                | Redisパスワードを格納しているシークレットの名前。`shared-secrets`機能が有効になっている場合、これが指定されていない場合は、自動的に作成されます。 |
| `redis.rateLimiting.password.key`                        | `redis-password`                                                     | Redisパスワードが格納されているシークレットキー。 |
| `redis.rateLimiting.db`                                  | `0`                                                                  | 各接続に使用するデータベースの名前。 |
| `redis.rateLimiting.dialtimeout`                         | `0s`                                                                 | Redisインスタンスへの接続のタイムアウト。デフォルトでは、タイムアウトはありません。 |
| `redis.rateLimiting.readtimeout`                         | `0s`                                                                 | Redisインスタンスからの読み取りのタイムアウト。デフォルトでは、タイムアウトはありません。 |
| `redis.rateLimiting.writetimeout`                        | `0s`                                                                 | Redisインスタンスへの書き込みのタイムアウト。デフォルトでは、タイムアウトはありません。 |
| `redis.rateLimiting.tls.enabled`                         | `false`                                                              | TLSを有効にするには、`true`に設定します。 |
| `redis.rateLimiting.tls.insecure`                        | `false`                                                              | TLS経由で接続する際にサーバー名の検証を無効にするには、`true`に設定します。 |
| `redis.rateLimiting.pool.size`                           | `10`                                                                 | ソケット接続の最大数。 |
| `redis.rateLimiting.pool.maxlifetime`                    | `1h`                                                                 | クライアントが接続を再試行するまでの接続時間。デフォルトでは、古くなった接続は閉じません。 |
| `redis.rateLimiting.pool.idletimeout`                    | `300s`                                                               | 無効な接続を閉じるまでに待機する時間。 |
| `redis.loadBalancing.enabled`                            | `false`                                                              | `true`に設定すると、[ロードバランシング](#load-balancing)のRedis接続が有効になります。 |
| `redis.loadBalancing.host`                               | `<Redis URL>`                                                        | Redisインスタンスのホスト名。空の場合、値は`global.redis.host:global.redis.port`として入力されます。 |
| `redis.loadBalancing.port`                               | `6379`                                                               | Redisインスタンスのポート。 |
| `redis.loadBalancing.cluster`                            | `[]`                                                                 | ホストとポートを持つアドレスのリスト。 |
| `redis.loadBalancing.sentinels`                          | `[]`                                                                 | ホストとポートを持つSentinelのリスト。 |
| `redis.loadBalancing.mainname`                           |                                                                      | mainサーバー名。Sentinelにのみ適用できます。 |
| `redis.loadBalancing.username`                           |                                                                      | Redisインスタンスへの接続に使用されるユーザー名。 |
| `redis.loadBalancing.password.enabled`                   | `false`                                                              | Redisインスタンスがパスワードで保護されているかどうかを示します。 |
| `redis.loadBalancing.password.secret`                    | `gitlab-redis-secret`                                                | Redisパスワードを格納しているシークレットの名前。`shared-secrets`機能が有効になっている場合、これが指定されていない場合は、自動的に作成されます。 |
| `redis.loadBalancing.password.key`                       | `redis-password`                                                     | Redisパスワードが格納されているシークレットキー。 |
| `redis.loadBalancing.db`                                 | `0`                                                                  | 各接続に使用するデータベースの名前。 |
| `redis.loadBalancing.dialtimeout`                        | `0s`                                                                 | Redisインスタンスへの接続のタイムアウト。デフォルトでは、タイムアウトはありません。 |
| `redis.loadBalancing.readtimeout`                        | `0s`                                                                 | Redisインスタンスからの読み取りのタイムアウト。デフォルトでは、タイムアウトはありません。 |
| `redis.loadBalancing.writetimeout`                       | `0s`                                                                 | Redisインスタンスへの書き込みのタイムアウト。デフォルトでは、タイムアウトはありません。 |
| `redis.loadBalancing.tls.enabled`                        | `false`                                                              | TLSを有効にするには、`true`に設定します。 |
| `redis.loadBalancing.tls.insecure`                       | `false`                                                              | TLS経由で接続する際にサーバー名の検証を無効にするには、`true`に設定します。 |
| `redis.loadBalancing.pool.size`                          | `10`                                                                 | ソケット接続の最大数。 |
| `redis.loadBalancing.pool.maxlifetime`                   | `1h`                                                                 | クライアントが接続を再試行するまでの接続時間。デフォルトでは、古くなった接続は閉じません。 |
| `redis.loadBalancing.pool.idletimeout`                   | `300s`                                                               | 無効な接続を閉じるまでに待機する時間。 |

## チャート設定の例 {#chart-configuration-examples}

### `pullSecrets` {#pullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに認証して、ポッドのコンテナイメージをプルできます。

プライベートレジストリとその認証方式に関する追加の詳細は、[Kubernetesのドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)にあります。

以下は、`pullSecrets`の使用例です。

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

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  種類   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。特定のサイドカーが適切に動作するために必要な場合を除き、これを有効にしないでください（Istioなど）。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |

### `tolerations` {#tolerations}

`tolerations`を使用すると、taintedワーカーノードでポッドをスケジュールできます

以下は、`tolerations`の使用例です。

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

`affinity`はオプションのパラメータで、以下の一方または両方を設定できます。

- 次の`podAntiAffinity`ルール：
  - `topology key`に対応する式に一致するポッドと同じドメインにポッドをスケジュールしません。
  - 必要な (`requiredDuringSchedulingIgnoredDuringExecution`) モードと優先 (`preferredDuringSchedulingIgnoredDuringExecution`) モードの2つのモードを`podAntiAffinity`ルールに設定します。`values.yaml`の`antiAffinity`変数を使用して、優先モードが適用されるように設定を`soft`に設定するか、必須モードが適用されるように`hard`に設定します。
- 次の`nodeAffinity`ルール：
  - 特定のゾーンに属するノードにポッドをスケジュールします。
  - 必要な (`requiredDuringSchedulingIgnoredDuringExecution`) モードと優先 (`preferredDuringSchedulingIgnoredDuringExecution`) モードの2つのモードを`nodeAffinity`ルールに設定します。`soft`に設定すると、優先モードが適用されます。`hard`に設定すると、必要なモードが適用されます。このルールは、`registry`チャートと、`webservice`と`sidekiq`を除くすべてのサブチャートとともに`gitlab`チャートにのみ実装されます。

`nodeAffinity`は、[`In`演算子](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#operators)のみを実装します。

詳細については、[関連するKubernetesドキュメント](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)を参照してください。

次の例では、`nodeAffinity`と`antiAffinity`の両方が`hard`に設定された状態で、`affinity`を設定します。

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

`annotations`を使用すると、レジストリ ポッドにアノテーションを追加できます。

以下は、`annotations`の使用例です

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## サブチャートを有効にする {#enable-the-sub-chart}

コンパートメント化されたサブチャートを実装するために選択した方法には、特定のデプロイで不要なコンポーネントを無効にする機能が含まれています。このため、最初に決定する必要がある設定は`enabled`です。

デフォルト無効にする場合は、`enabled: false`を設定します。

## `image`の設定 {#configuring-the-image}

このセクションでは、このサブチャートの[deployment](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/deployment.yaml)で使用されるコンテナイメージの設定について詳しく説明します。レジストリと`pullPolicy`に含まれるバージョンを変更できます。

デフォルト 設定：

- `tag: 'v4.15.2-gitlab'`
- `pullPolicy: 'IfNotPresent'`

## `service`の設定 {#configuring-the-service}

このセクションでは、[Service](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/service.yaml)の名前と種類を制御します。これらの設定は、[`values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/values.yaml)によって入力された状態になります。

デフォルト

| 名前             |  種類  | デフォルト     | 説明 |
|:-----------------|:------:|:------------|:------------|
| `name`           | 文字列 | `registry`  | サービスの名前を設定します |
| `type`           | 文字列 | `ClusterIP` | サービスの種類を設定します |
| `externalPort`   |  整数   | `5000`      | Serviceによって公開されるポート |
| `internalPort`   |  整数   | `5000`      | サービスからのリクエストを受け入れるためにポッドによって利用されるポート |
| `clusterIP`      | 文字列 | `null`      | 必要に応じてカスタムクラスターIPを設定できるようにします |
| `loadBalancerIP` | 文字列 | `null`      | 必要に応じてカスタムLoadBalancer IPアドレスを設定できるようにします |

## `ingress`の設定 {#configuring-the-ingress}

このセクションでは、レジストリIngressを制御します。

| 名前                   |  種類   | デフォルト | 説明 |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | 文字列  |         | `apiVersion`フィールドで使用する値。 |
| `annotations`          | 文字列  |         | このフィールドは、[Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)の標準`annotations`と完全に一致します。 |
| `configureCertmanager` | ブール値 |         | Ingressアノテーション`cert-manager.io/issuer`および`acme.cert-manager.io/http01-edit-in-place`を切り替えます。詳細については、[GitLab PagesのTLS要件](../../installation/tls.md)を参照してください。 |
| `enabled`              | ブール値 | `false` | サービスをサポートするIngressオブジェクトを作成するかどうかを制御する設定。`false`の場合、`global.ingress.enabled`設定が使用されます。 |
| `tls.enabled`          | ブール値 | `true`  | `false`に設定すると、レジストリサブチャートのTLSが無効になります。これは主に、`ingress-level`でTLS終端を使用できない場合に役立ちます（Ingressコントローラーの前にTLS終端プロキシがある場合など）。 |
| `tls.secretName`       | 文字列  |         | レジストリURLの有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定しない場合、代わりに`global.ingress.tls.secretName`が使用されます。デフォルト |
| `tls.cipherSuites`     |  配列  | `[]`    | TLSハンドシェイク中にコンテナ レジストリがクライアントに提示する必要がある暗号スイートのリスト。 |

## TLSの設定 {#configuring-tls}

コンテナ レジストリは、`nginx-ingress`を含む他のコンポーネントとの通信を保護するTLSをサポートします。

TLSを設定するための前提要件：

- TLS証明書には、共通名（CN）またはサブジェクト代替名（SAN）のレジストリサービスホスト名（たとえば、`RELEASE-registry.default.svc`）を含める必要があります。
- TLS証明書が生成された後：
  - [Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を作成します
  - `ca.crt`キーを使用して、TLS証明書のCA証明書のみを含む別のシークレットを作成します。

TLSを有効にする手順：

1. `registry.tls.enabled`を`true`に設定します。
1. `global.hosts.registry.protocol`を`https`に設定します。
1. `registry.tls.secretName`と`global.certificates.customCAs`にシークレット名を適宜渡します。

`registry.tls.verify`が`true`の場合、CA証明書シークレット名を`registry.tls.caSecretName`に渡す必要があります。これは、自己署名証明書とカスタム公開認証局（CA）に必要です。このシークレットは、レジストリのTLS証明書を検証するために、NGINXによって使用されます。

次に例を示します。

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

### コンテナ レジストリ暗号スイート {#container-registry-cipher-suites}

通常、`tls.cipherSuites`オプションは、レジストリがスタンドアロンモードでデプロイされている、または最新の暗号スイートをサポートしていないデフォルト標準のGitLabデプロイでは、NGINX Ingressは、コンテナ レジストリ バックエンドでサポートされている最高のTLSバージョン（現在はTLS1.3）を選択します。TLS1.3では暗号を設定できず、デフォルトで安全です。何らかの理由でTLS1.3が利用できない場合、コンテナ レジストリが使用しているデフォルトのTLS1.2暗号リストも、NGINX Ingressのデフォルトの設定と互換性があり、安全です。

### デバッグポートのTLSの設定 {#configuring-tls-for-the-debug-port}

レジストリデバッグポートもTLSをサポートします。デバッグポートは、Kubernetesの活性と準備状況のチェックに使用されるだけでなく、Prometheusの`/metrics`エンドポイントも公開します（有効な場合）。

TLSを有効にするには、`registry.debug.tls.enabled`を`true`に設定します。[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)は、デバッグポートのTLS設定での使用専用として`registry.debug.tls.secretName`で指定できます。専用のシークレットが指定されていない場合、デバッグ設定は、レジストリの通常のTLS設定で`registry.tls.secretName`を共有するようにフォールバックします。

Prometheusが`https`を使用して`/metrics/`エンドポイントをスクレイピングするには、証明書のCommonName属性またはSubjectAlternativeNameエントリに追加の設定が必要です。これらの要件については、[TLS対応のエンドポイントをスクレイピングするようにPrometheusを設定する](../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints)を参照してください。

## `networkpolicy`の設定 {#configuring-the-networkpolicy}

このセクションでは、レジストリ[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を制御します。この設定はオプションであり、特定のエンドポイントへのレジストリのエグレスとIngressを制限するために使用されます。エンドポイントへのIngress。

| 名前              |  種類   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | この`NetworkPolicy`の設定を有効にします。 |
| `ingress.enabled` | ブール値 | `false` | `true`に設定すると、`Ingress`ネットワークポリシーが有効になります。これにより、ルールが指定されていない限り、すべてのIngress接続がブロックされます。 |
| `ingress.rules`   |  配列  | `[]`    | Ingressポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください |
| `egress.enabled`  | ブール値 | `false` | `true`に設定すると、`Egress`ネットワークポリシーが有効になります。これにより、ルールが指定されていない限り、すべてのエグレス接続がブロックされます。 |
| `egress.rules`    |  配列  | `[]`    | エグレスポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください |

### すべての内部エンドポイントへの接続を阻止するためのポリシー例 {#example-policy-for-preventing-connections-to-all-internal-endpoints}

通常、レジストリサービスは、オブジェクトストレージへのエグレス接続、DockerクライアントからのIngress接続、およびDNSルックアップ用のkube-dnsを必要とします。これにより、レジストリサービスに次のネットワーク制限が追加されます。

- Ingressリクエストを許可します。
  - ポッド`sidekiq`、`webservice`、`nginx-ingress`からポート`5000`へ
  - `Prometheus`ポッドからポート`9235`へ
- エグレスリクエストを許可します。
  - `kube-dns`からポート`53`へ
  - S3またはSTS `172.16.1.0/24`のAWS VPCエンドポイントなどのエンドポイントからポート`443`へ
  - インターネット`0.0.0.0/0`からポート`443`へ

_注：[レジストリ](../../advanced/external-object-storage)サービスには、（エンドポイントが使用されていない場合）外部オブジェクトストレージ上のイメージへの送信接続が必要です_  

この例は、`kube-dns`がネームスペース`kube-system`にデプロイされ、`prometheus`がネームスペース`monitoring`にデプロイされ、`nginx-ingress`がネームスペース`nginx-ingress`にデプロイされたという前提に基づいています。

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

## KEDA {#configuring-keda}の設定

この`keda`セクションでは、[KEDA](https://keda.sh/)`ScaledObjects`のインストールを、`HorizontalPodAutoscalers`の代わりに有効にします。この設定はオプションであり、カスタムメトリクスまたは外部メトリクスに基づいたオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する場合、`hpa`セクションで設定された値にデフォルト設定されます。

次がtrueの場合、CPUとメモリのトリガーは、`hpa`セクションで設定されたCPUとメモリのしきい値に基づいて自動的に追加されます。

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`の設定も、ゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの[設定](https://keda.sh/docs/2.10/concepts/scaling-deployments/)の詳細については、KEDAドキュメントを参照してください。

| 名前                            |  種類   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | [KEDA](https://keda.sh/) `ScaledObjects`を`HorizontalPodAutoscalers`の代わりに使用します |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | 最後トリガーがアクティブであるとレポートされてから、リソースを0にスケールバックするまでの待機時間 |
| `minReplicaCount`               | 整数 | `hpa.minReplicas`               | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `maxReplicaCount`               | 整数 | `hpa.maxReplicas`               | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `fallback`                      |   マップ   |                                 | [KEDA](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)フォールバック 設定、ドキュメントを参照してください |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | `ScaledObject`の削除後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   | `hpa.behavior`                  | アップスケールとダウンスケールの動作の仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケーリングをアクティブ化するトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されるトリガーにデフォルト設定されます |

### すべての内部エンドポイントへの接続を阻止するためのポリシー例 {#example-policy-for-preventing-connections-to-all-internal-endpoints-1}

通常、レジストリサービスは、オブジェクトストレージへのエグレス接続、DockerクライアントからのIngress接続、およびDNSルックアップ用のkube-dnsを必要とします。これにより、レジストリサービスに次のネットワーク構築制限が追加されます。

- `10.0.0.0/8`ポート53上のローカルネットワークへのすべてのエグレス リクエストが許可されます（kubeDNSの場合）
- `10.0.0.0/8`上のローカルネットワークへの他のエグレス リクエストは制限されています
- `10.0.0.0/8`の外部 エグレス リクエストは許可されています

_注：[レジストリ](../../advanced/external-object-storage)サービスには、外部オブジェクトストレージ上のイメージに対するパブリックインターネットへの送信接続が必要です_

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

## レジストリ 設定の定義 {#defining-the-registry-configuration}

この[チャート](https://hub.docker.com/_/registry/)の次のプロパティは、基盤となるレジストリ コンテナの設定に関係します。GitLabとのインテグレーションのために最も重要な値のみが公開されます。このインテグレーションでは、JWT [認証](https://github.com/docker/distribution) [トークン](https://distribution.github.io/distribution/spec/auth/token/)を介してレジストリへの認証を制御するDockerディストリビューションの`auth.token.x`設定を使用します。

### `httpSecret` {#httpsecret}

フィールド`httpSecret`は、`secret`と`key`の2つのアイテムを含むマップです。

このキーが参照するコンテンツは、[レジストリ](https://hub.docker.com/_/registry/)の`http.secret`値に関連付けられています。この値には、暗号で生成されたランダムな文字列が入力されている必要があります。

`shared-secrets`ジョブは、指定されていない場合、このシークレットを自動的に作成します。これは、base64エンコードされた、安全に生成された128文字の英数字文字列で入力されます。

このシークレットを手動で作成するには：

```shell
kubectl create secret generic gitlab-registry-httpsecret --from-literal=secret=strongrandomstring
```

### 通知 {#notification-secret}シークレット

通知 シークレットは、さまざまな方法でGitLabアプリケーションにコールバックするために使用されます。たとえば、Geoがプライマリサイトとセカンダリサイト間でコンテナレジストリデータを同期するのを支援するなどです。

`notificationSecret`シークレット オブジェクトは、`shared-secrets`機能が有効になっている場合、指定されていない場合に自動的に作成されます。

このシークレットを手動で作成するには：

```shell
kubectl create secret generic gitlab-registry-notification --from-literal=secret=[\"strongrandomstring\"]
```

次に、設定に進みます

```yaml
global:
  # To provide your own secret
  registry:
    notificationSecret:
        secret: gitlab-registry-notification
        key: secret

  # If utilising Geo, and wishing to sync the container registry.
  # Define this in the primary site configs only.
  geo:
    registry:
      replication:
        enabled: true
        primaryApiUrl: <URL to primary registry>
```

`secret`値が上記で作成されたシークレットの名前に設定されていることを確認します

### Redisキャッシュ シークレット {#redis-cache-secret}

Redisキャッシュ シークレットは、`global.redis.auth.enabled`が`true`に設定されている場合に使用されます。

`shared-secrets`機能が有効になっている場合、`gitlab-redis-secret`シークレット オブジェクトは、指定されていない場合に自動的に作成されます。

この[シークレット](../../installation/secrets.md#redis-password)を手動で作成するには、Redisパスワードの手順を参照してください。

### `authEndpoint` {#authendpoint}

`authEndpoint`フィールドは文字列で、[レジストリ](https://hub.docker.com/_/registry/)が認証するGitLabインスタンスへのURLを提供します。

この値には、プロトコルとホスト名のみを含める必要があります。チャートテンプレートは、必要なリクエスト パスを自動的に追加します。結果として得られる`auth.token.realm`の値は、コンテナ内で入力されます。次に例を示します。`authEndpoint: "https://gitlab.example.com"`

デフォルトでは、このフィールドには、[グローバル設定](../globals.md)で設定されたGitLabホスト名の設定が入力されます。

### `certificate` {#certificate}

`certificate`フィールドは、`secret`と`key`の2つの項目を含むマップです。

`secret`は、GitLabインスタンスによって作成されたトークンを検証するために使用される証明書[バンドル](https://kubernetes.io/docs/concepts/configuration/secret/)を格納する[Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/)の名前を含む文字列です。

`key`は、[レジストリ](https://hub.docker.com/_/registry/)コンテナに`auth.token.rootcertbundle`として提供される証明書バンドルを格納する`Secret`内の`key`の名前です。

デフォルトの例:

```yaml
certificate:
  secret: gitlab-registry
  key: registry-auth.crt
```

### readinessプローブとlivenessプローブ {#readiness-and-liveness-probe}

デフォルトでは、デバッグポートである`5001`ポートで`/debug/health`をチェックするように設定されたreadinessプローブとlivenessプローブがあります。

### `validation` {#validation}

`validation`フィールドは、レジストリ内のDockerイメージ検証プロセスを制御するマップです。イメージ検証が有効になっている場合、`manifests.urls.allow`フィールドがそれらのレイヤーのURLを許可するように明示的に設定されていない限り、レジストリは外部レイヤーを持つWindowsイメージを拒否します。

検証はmanifestのプッシュ中にのみ行われるため、レジストリに既に存在するイメージは、このセクションの値の変更の影響を受けません。

イメージ検証はデフォルトでオフになっています。

イメージ検証を有効にするには、`registry.validation.disabled: false`を明示的に設定する必要があります。

#### `manifests` {#manifests}

`manifests`フィールドを使用すると、manifestに固有の検証ポリシーを設定できます。

`urls`セクションには、`allow`フィールドと`deny`フィールドの両方が含まれています。検証をpassするURLを含むmanifestのレイヤーの場合、そのレイヤーは`allow`フィールド内の正規表現のいずれかと一致する必要があり、`deny`フィールド内の正規表現と一致してはなりません。

|        名前        | 種類  | デフォルト | 説明 |
|:------------------:|:-----:|:--------|:-----------:|
|  `referencelimit`  |  Int  | `0`     | 単一のmanifestが持つことができるレイヤー、イメージ設定、その他のmanifestなどのreferenceの最大数。`0`（デフォルト）に設定すると、この検証は無効になります。 |
| `payloadsizelimit` |  Int  | `0`     | manifestのペイロードの最大データサイズ（バイト単位）。`0`（デフォルト）に設定すると、この検証は無効になります。 |
|    `urls.allow`    | 配列 | `[]`    | manifestのレイヤー内のURLを有効にする正規表現のリスト。空のまま（デフォルト）にすると、URLを含むレイヤーは拒否されます。 |
|    `urls.deny`     | 配列 | `[]`    | manifestのレイヤー内のURLを制限する正規表現のリスト。空のまま（デフォルト）にすると、`urls.allow`リストをpassしたURLを持つレイヤーは拒否されません |

### `notifications` {#notifications}

`notifications`フィールドは、[レジストリ](https://distribution.github.io/distribution/about/notifications/#configuration)の通知を設定するために使用されます。デフォルト値として空のハッシュがあります。

|    名前     | 種類  | デフォルト | 説明 |
|:-----------:|:-----:|:--------|:-----------:|
| `endpoints` | 配列 | `[]`    | 各項目が[エンドポイント](https://distribution.github.io/distribution/about/configuration/#endpoints)に対応する項目のリスト |
|  `events`   | ハッシュ  | `{}`    | [イベント](https://distribution.github.io/distribution/about/configuration/#events)の通知で提供される情報 |

設定例を次に示します。

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

`hpa`フィールドは、セットの一部として作成する[レジストリ](https://hub.docker.com/_/registry/)インスタンスの数を制御するオブジェクトです。これは、`minReplicas`の値`2`、`maxReplicas`の値10、および`cpu.targetAverageUtilization`を75％に設定します。

### `storage` {#storage}

```yaml
storage:
  secret:
  key: config
  extraKey:
```

`storage`フィールドは、Kubernetesシークレットと関連付けられたキーへの参照です。このシークレットの内容は、[レジストリ](https://distribution.github.io/distribution/about/configuration/#storage)の設定から直接取得されます: `storage`詳細については、そのドキュメントを参照してください。

[AWS S3](https://distribution.github.io/distribution/storage-drivers/s3/)および[Google GCS](https://distribution.github.io/distribution/storage-drivers/gcs/)ドライバーの例は、[`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)にあります:

- [`registry.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.s3.yaml)
- [`registry.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.gcs.yaml)

[S3](https://distribution.github.io/distribution/storage-drivers/s3/#s3-permission-scopes)の場合、レジストリストレージに適切な[権限](https://distribution.github.io/distribution/storage-drivers/s3/#s3-permission-scopes)があることを確認してください。ストレージの設定の詳細については、[コンテナレジストリストレージドライバー](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-storage-driver)を管理ドキュメントで参照してください。

`storage`ブロックの_コンテンツ_を_シークレット_に配置し、次の項目を`storage`マップへの項目として提供します:

- `secret`: YAMLブロックをホスティングするKubernetesシークレットの名前。
- `key`: 使用するシークレット内のキーの名前。デフォルトは`config`です。
- `extraKey`: _（オプション）_シークレット内の追加の_キー_の名前。これは、コンテナ内の`/etc/docker/registry/storage/${extraKey}`に_マウント_されます。これは、`gcs`ドライバーの`keyfile`を提供するために使用できます。

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

[ストレージドライバーのリダイレクトを無効にする](https://docs.gitlab.com/administration/packages/container_registry/#disable-redirect-for-storage-driver)ことで、すべてのトラフィックが別のバックエンドにリダイレクトされる代わりに、レジストリサービスを通過するようにすることができます:

```yaml
storage:
  secret: example-secret
  key: config
  redirect:
    disable: true
```

`filesystem`ドライバーを使用することを選択した場合:

- このデータの永続ボリュームを提供する必要があります。
- [`hpa.minReplicas`](#hpa)を`1`に設定する必要があります
- [`hpa.maxReplicas`](#hpa)を`1`に設定する必要があります

回復と簡素化のために、`s3`、`gcs`、`azure`などの外部サービス、またはその他の互換性のあるオブジェクトストレージを使用することをお勧めします。

{{< alert type="note" >}}

ユーザーが指定しない場合、チャートはデフォルトでこの設定に`delete.enabled: true`を入力します。これにより、MinIOのデフォルトの使用だけでなく、Linuxパッケージとの整合性が維持されます。ユーザーが指定した値は、このデフォルトよりも優先されます。

{{< /alert >}}

### `middleware.storage` {#middlewarestorage}

`middleware.storage`の[設定](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#middleware)は、アップストリームの規則に従います:

設定は非常にgenericであり、同様のパターンに従います:

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

上記のコード内`options.privatekeySecret`は、PEMファイルのコンテンツに対応する`generic` Kubernetesシークレットのコンテンツです。

```shell
kubectl create secret generic cloudfront-secret-name --type=kubernetes.io/ssh-auth --from-file=private-key-ABC.pem=pk-ABCEDFGHIJKLMNOPQRST.pem
```

アップストリームで使用される`privatekey`は、チャートによって`privatekey`シークレットから自動的に入力され、指定されている場合は**無視**されます。

#### `keypairid`バリアント {#keypairid-variants}

さまざまなベンダーが、同じ構成に異なるフィールド名を使用します:

|   ベンダー   | フィールド名 |
|:----------:|:----------:|
| Google CDN | `keyname`  |
| CloudFront | `keypairid` |

{{< alert type="note" >}}

現時点では、`middleware.storage`セクションの設定のみがサポートされています。

{{< /alert >}}

### `debug` {#debug}

デバッグポートはデフォルトで有効になっており、liveness/readinessプローブに使用されます。さらに、Prometheusメトリクスは、`metrics`値を介して有効にできます。

```yaml
debug:
  addr:
    port: 5001

metrics:
  enabled: true
```

### `health` {#health}

`health`プロパティはオプションであり、ストレージドライバーのバックエンドストレージで定期的なヘルスチェックの環境設定を含みます。詳細については、Docker [設定](https://distribution.github.io/distribution/about/configuration/#health)ドキュメントを参照してください。

```yaml
health:
  storagedriver:
    enabled: false
    interval: 10s
    threshold: 3
```

### `reporting` {#reporting}

`reporting`プロパティはオプションで、[レポート作成](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#reporting)を有効にします

```yaml
reporting:
  sentry:
    enabled: true
    dsn: 'https://<key>@sentry.io/<project>'
    environment: 'production'
```

### `profiling` {#profiling}

`profiling`プロパティはオプションで、[継続的プロファイリング](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#profiling)を有効にします

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

- [GitLab](https://gitlab.com/groups/gitlab-org/-/epics/5521) 16.4で[ベータ](https://docs.gitlab.com/policy/development_stages_support/#beta)機能として[導入](https://gitlab.com/groups/gitlab-org/-/epics/5521)されました。
- [一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)はGitLab 17.3で行われました。

{{< /history >}}

`database`プロパティはオプションで、[metadataデータベース](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#database)を有効にします。

この[機能](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)を有効にする前に、管理ドキュメントを参照してください。

{{< alert type="note" >}}

この機能を使用するには、PostgreSQL 13以降が必要です。

{{< /alert >}}

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

{{< alert type="warning" >}}

これは活発な開発中の実験的な機能であり、本番環境で使用してはなりません。

{{< /alert >}}

`loadBalancing`セクションでは、[データベース](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#loadbalancing)のロードバランシングを設定できます。この機能を動作させるには、対応する[Redis](#redis-for-database-load-balancing)接続を有効にする必要があります。

#### データベースの管理 {#manage-the-database}

[データベース](metadata_database.md)の作成と保持の詳細については、コンテナレジストリmetadataデータベースのページを参照してください。

### `gc`プロパティ {#gc-property}

`gc`プロパティは、[オンラインガベージコレクション](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#gc)オプションを提供します。

[オンラインガベージコレクション](#database)には、metadataデータベースが有効になっている必要があります。データベースを使用する場合はオンラインガベージコレクションを使用する必要がありますが、メンテナンスとデバッグのために一時的にオンラインガベージコレクションを無効にすることができます。

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

{{< alert type="note" >}}

Redisキャッシュは、バージョン16.4以降のベータ版の機能です。この[機能](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)を有効にする前に、フィードバックのイシューと関連ドキュメントを確認してください。

{{< /alert >}}

`redis.cache`プロパティはオプションで、[Redisキャッシュ](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#cache-1)に関連するオプションを提供します。`redis.cache`をレジストリで使用するには、[metadataデータベース](#database)を有効にする必要があります。

次に例を示します。

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

#### クラスタ {#cluster}

`redis.rateLimiting.cluster`プロパティは、Redisクラスタへの接続に使用するホストとポートのリストです。次に例を示します。

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

#### Sentinels {#sentinels}

`redis.cache`は`global.redis.sentinels`構成を使用できます。ローカル値を提供でき、グローバル値よりも優先されます。次に例を示します。

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

- GitLab 17.2で[導入](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3805)されました。

{{< /history >}}

`redis.cache`は、Redis Sentinelの認証パスワードを使用するために、[`global.redis.sentinelAuth`構成](../globals.md#redis-sentinel-password-support)も使用できます。ローカル値を提供でき、グローバル値よりも優先されます。次に例を示します。

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

### Redisレート制限機構 {#redis-rate-limiter}

{{< alert type="warning" >}}

Redisレート制限機構は[開発中](https://gitlab.com/groups/gitlab-org/-/epics/13237)です。より詳細な機能については、使用可能になり次第、このセクションに追加します。

{{< /alert >}}

`redis.rateLimiting`プロパティはオプションで、[Redisレート制限機構](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#ratelimiter)に関連するオプションを提供します。

次に例を示します。

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

### データベースロードバランシング用のRedis {#redis-for-database-load-balancing}

{{< details >}}

状態:実験

{{< /details >}}

{{< history >}}

- [チャート](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4180) 8.11で[導入](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4180)されました。

{{< /history >}}

{{< alert type="warning" >}}

[データベース](#load-balancing)の負荷分散は現在開発中の試験的な機能であり、本番環境で使用しないでください。進捗状況を追跡し、[フィードバック](https://gitlab.com/groups/gitlab-org/-/epics/8591)を共有するには、エピック8591を使用してください。

{{< /alert >}}

`redis.loadBalancing`プロパティはオプションで、[データベース](https://gitlab.com/gitlab-org/container-registry/-/blob/b4d71f24a9ae31288401a3459228aa7f8d3dd8f0/docs/configuration.md#loadbalancing-1)の負荷分散のためのRedis接続に関連するオプションを提供します。

次に例を示します。

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

Dockerレジストリは、時間が経つにつれて不要なデータを蓄積します。これは[ガベージコレクション](https://distribution.github.io/distribution/about/garbage-collection/)を使用して解放できます。現在のところ、この[チャート](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1586)でガベージコレクションを実行するための完全に自動化された、またはスケジュールされた方法はありません。

{{< alert type="warning" >}}

[metadataデータベース](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#gc)で[オンラインガベージコレクション](#database)を使用する必要があります。metadataデータベースで手動ガベージコレクションを使用すると、データが失われます。オンラインガベージコレクションは、手動でガベージコレクションを実行する必要性を完全に置き換えます。

{{< /alert >}}

### 手動ガベージコレクション {#manual-garbage-collection}

手動ガベージコレクションでは、最初にレジストリを読み取り専用モードにする必要があります。Helmを使用してGitLabチャートを既にインストールし、`mygitlab`という名前を付け、`gitlabns`ネームスペースにインストールしたと仮定しましょう。実際の設定に従って、以下のコマンドでこれらの値を置き換えてください。

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

### コンテナレジストリに対する管理コマンドの実行 {#running-administrative-commands-against-the-container-registry}

管理コマンドは、`registry`バイナリと必要な設定の両方が利用可能なレジストリポッドからのみ、コンテナレジストリに対して実行できます。ツールボックス[ポッド](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2629)からこの機能性を提供する方法について議論するために、[イシュー](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2629)\#2629が開かれています。

管理コマンドを実行するには:

1. レジストリポッドに接続します:

   ```shell
   kubectl exec -it <registry-pod> -- bash
   ```

1. レジストリポッド内に入ると、`registry`バイナリは`PATH`で使用できるようになり、直接使用できます。設定ファイルは`/etc/docker/registry/config.yml`で利用できます。次の例では、データベース移行の状態を確認します:

   ```shell
   registry database migrate status /etc/docker/registry/config.yml
   ```

詳細およびその他の使用可能なコマンドについては、関連ドキュメントを参照してください:

- [一般的なレジストリドキュメント](https://docs.docker.com/registry/)
- [GitLab](https://gitlab.com/gitlab-org/container-registry/-/tree/master/docs-gitlab)固有のレジストリドキュメント

## レジストリレート制限機構設定 {#registry-rate-limiter-configuration}

レジストリは、コンテナレジストリインスタンスへのトラフィックを制御するためにレート制限機構で設定できます。これは、レジストリを不正使用、DoS攻撃、または過度の使用から保護するのに役立ちます。

### ノート {#notes}

- レート制限は、`registry.redis.rateLimiting`の設定でRedisが適切に構成されている必要があります。
- レート制限はデフォルトで無効になっています。有効にするには、`registry.rateLimiter.enabled: true`を設定します。
- リミッターは優先順位に従って適用されます（値が低いものが最初）。
- `log_only`オプションは、レート制限を適用する前にテストする場合に役立ちます。

### レート制限の設定 {#rate-limiter-configuration}

コンテナレジストリのレート制限を有効化および構成するには、`registry.rateLimiter`設定を使用します。

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

レートリミッターは、リミッターのリストを使用してレート制限ルールを定義します。各リミッターには、次のプロパティがあります。

- `name`:リミッターの固有識別子
- `description`:リミッターの目的を人間が読める形式で記述したもの
- `log_only`:`true`に設定すると、違反は適用されずにログに記録されるだけです
- `precedence`:リミッターが評価される順序を定義します（値が低いものが最初）
- `match`:リクエストを照合するための基準
- `limit`:レート制限パラメータ
- `action`:制限に達したときに実行する行動

### 制限の設定 {#limit-configuration}

`limit`セクションでは、実際値のレート制限パラメータを定義します。

```yaml
limit:
  rate: 100       # Number of requests allowed
  period: "minute" # Time period (second, minute, hour, day)
  burst: 200      # Allowed burst capacity
```

### アクションの設定 {#action-configuration}

`action`セクションでは、制限に近づいた場合または制限に達した場合に何が起こるかを定義します。

```yaml
action:
  warn_threshold: 0.7      # Percentage of limit to trigger warning
  warn_action: "log"       # Action when warning threshold is reached
  hard_action: "block"     # Action when limit is reached
```

### 例 {#examples}

#### グローバルIPレート制限 {#global-ip-rate-limit}

この例では、単一のIPアドレスからのすべてのリクエストを制限します。

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
