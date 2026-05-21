---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Webserviceチャートを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

この`webservice`サブチャートは、GitLab Railsウェブサーバーにポッドごとに2つのWebserviceワーカーを提供します。これは、単一のポッドがGitLabであらゆるウェブリクエストを処理するために最低限必要な数です。

このチャートのポッドは、2つのコンテナ、`gitlab-workhorse`と`webservice`を使用します。[GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab/-/tree/master/workhorse)はポート`8181`でリッスンし、ポッドへの受信トラフィックの_常に_宛先である必要があります。`webservice`はGitLabの[Railsコードベース](https://gitlab.com/gitlab-org/gitlab)を格納し、`8080`でリッスンしており、メトリクス収集の目的でアクセス可能です。`webservice`は通常のトラフィックを直接受信すべきではありません。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされているKubernetesクラスターから到達可能な外部サービスとして提供されるRedis、PostgreSQL、Gitaly、およびレジストリサービスに依存しています。

## 設定 {#configuration}

この`webservice`チャートは次のように設定されます: [グローバル設定](#global-settings) 、[デプロイ設定](#deployments-settings) 、[Ingress設定](#ingress-settings) 、[外部サービス](#external-services) 、および[チャート設定](#chart-settings)。

## インストールコマンドラインオプション {#installation-command-line-options}

以下の表には、`helm install`コマンドで`--set`フラグを使用して指定できるすべてのチャートの設定が含まれています。

| パラメータ                                                     | デフォルト                                                         | 説明 |
|---------------------------------------------------------------|-----------------------------------------------------------------|-------------|
| `annotations`                                                 |                                                                 | ポッドアノテーション |
| `podLabels`                                                   |                                                                 | 補足的なポッドラベル。セレクターには使用されません。 |
| `common.labels`                                               |                                                                 | このチャートによって作成されたすべてのオブジェクトに適用される補足ラベル。 |
| `deployment.terminationGracePeriodSeconds`                    | `30`                                                            | Kubernetesがポッドが終了するのを待つ秒数。これは`shutdown.blackoutSeconds`よりも長くする必要があります。 |
| `deployment.livenessProbe.initialDelaySeconds`                | `20`                                                            | ライブネスプローブが開始される前の遅延 |
| `deployment.livenessProbe.periodSeconds`                      | `60`                                                            | ライブネスプローブを実行する頻度 |
| `deployment.livenessProbe.timeoutSeconds`                     | `30`                                                            | ライブネスプローブがタイムアウトするとき |
| `deployment.livenessProbe.successThreshold`                   | `1`                                                             | ライブネスプローブが失敗した後に成功と見なされるための最小連続成功数 |
| `deployment.livenessProbe.failureThreshold`                   | `3`                                                             | ライブネスプローブが成功した後に失敗と見なされるための最小連続失敗数 |
| `deployment.readinessProbe.initialDelaySeconds`               | `0`                                                             | レディネスプローブが開始される前の遅延 |
| `deployment.readinessProbe.periodSeconds`                     | `10`                                                            | レディネスプローブを実行する頻度 |
| `deployment.readinessProbe.timeoutSeconds`                    | `2`                                                             | レディネスプローブがタイムアウトするとき |
| `deployment.readinessProbe.successThreshold`                  | `1`                                                             | レディネスプローブが失敗した後に成功と見なされるための最小連続成功数 |
| `deployment.readinessProbe.failureThreshold`                  | `3`                                                             | レディネスプローブが成功した後に失敗と見なされるための最小連続失敗数 |
| `deployment.strategy`                                         | `{}`                                                            | デプロイで使用される更新戦略を設定できます。指定しない場合、クラスターのデフォルトが使用されます。 |
| `enabled`                                                     | `true`                                                          | Webservice有効化フラグ |
| `extraContainers`                                             |                                                                 | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列 |
| `extraInitContainers`                                         |                                                                 | 追加のinitコンテナのリスト |
| `extras.google_analytics_id`                                  | `nil`                                                           | フロントエンド用のGoogle Analytics ID |
| `extraVolumeMounts`                                           |                                                                 | 追加でマウントするボリュームのリスト |
| `extraVolumes`                                                |                                                                 | 作成する追加ボリュームのリスト |
| `extraEnv`                                                    |                                                                 | 追加の環境変数のリスト |
| `extraEnvFrom`                                                |                                                                 | 他のデータソースから公開する追加の環境変数のリスト |
| `gitlab.webservice.workhorse.image`                           | `registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ee`  | Workhorseイメージリポジトリ |
| `gitlab.webservice.workhorse.tag`                             |                                                                 | Workhorseイメージタグ |
| `hpa.behavior`                                                | `{scaleDown: {stabilizationWindowSeconds: 300 }}`               | 動作は、スケールアップおよびスケールダウン動作の仕様を含みます（`autoscaling/v2beta2`以降が必要）。 |
| `hpa.customMetrics`                                           | `[]`                                                            | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれます（`targetAverageUtilization`で設定された平均CPU使用率のデフォルト使用をオーバーライドします）。 |
| `hpa.cpu.targetType`                                          | `AverageValue`                                                  | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.cpu.targetAverageValue`                                  | `1`                                                             | オートスケールCPUターゲット値を設定します。 |
| `hpa.cpu.targetAverageUtilization`                            |                                                                 | オートスケールCPUターゲット使用率を設定します。 |
| `hpa.memory.targetType`                                       |                                                                 | オートスケールメモリターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.memory.targetAverageValue`                               |                                                                 | オートスケールメモリターゲット値を設定します。 |
| `hpa.memory.targetAverageUtilization`                         |                                                                 | オートスケールメモリターゲット使用率を設定します。 |
| `hpa.targetAverageValue`                                      |                                                                 | **DEPRECATED**：オートスケールCPUターゲット値を設定します。 |
| `sshHostKeys.mount`                                           | `false`                                                         | 公開SSHキーを含むGitLab Shellのシークレットをマウントするかどうか。 |
| `sshHostKeys.mountName`                                       | `ssh-host-keys`                                                 | マウントされたボリュームの名前。 |
| `sshHostKeys.types`                                           | `[dsa,rsa,ecdsa,ed25519]`                                       | マウントするSSHキータイプの一覧。 |
| `image.pullPolicy`                                            | `Always`                                                        | Webserviceイメージプルポリシー |
| `image.pullSecrets`                                           |                                                                 | イメージリポジトリ用のシークレット |
| `image.repository`                                            | `registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ee` | Webserviceイメージリポジトリ |
| `image.tag`                                                   |                                                                 | Webserviceイメージタグ |
| `init.image.repository`                                       |                                                                 | initContainerイメージ |
| `init.image.tag`                                              |                                                                 | initContainerイメージタグ |
| `init.containerSecurityContext.runAsUser`                     | `1000`                                                          | initContainer固有: コンテナを開始するユーザーID |
| `init.containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                         | initContainer固有: プロセスが親プロセスよりも多くの権限を取得できるかどうかを制御します。 |
| `init.containerSecurityContext.runAsNonRoot`                  | `true`                                                          | initContainer固有: コンテナが非rootユーザーで実行されるかどうかを制御します。 |
| `init.containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                     | initContainer固有: コンテナから[Linuxケーパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します。 |
| `keda.enabled`                                                | `false`                                                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                        | `30`                                                            | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                                         | `300`                                                           | 最後のトリガーがアクティブを報告してから、リソースを0にスケールバックするまでの待機期間 |
| `keda.minReplicaCount`                                        | `minReplicas`                                                   | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `keda.maxReplicaCount`                                        | `maxReplicas`                                                   | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `keda.fallback`                                               |                                                                 | KEDAフォールバック設定。[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください。 |
| `keda.hpaName`                                                | `keda-hpa-{scaled-object-name}`                                 | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`                          |                                                                 | `ScaledObject`が削除された後、ターゲットリソースが元のレプリカ数にスケールバックされるべきかどうかを指定します。 |
| `keda.behavior`                                               | `hpa.behavior`                                                  | スケールアップおよびスケールダウン動作の仕様。 |
| `keda.triggers`                                               |                                                                 | ターゲットリソースのスケールをアクティブ化するトリガーのリスト。`hpa.cpu`と`hpa.memory`から計算されたトリガーにデフォルトで設定されます。 |
| `metrics.enabled`                                             | `true`                                                          | メトリクスエンドポイントをスクレイプ可能にするかどうか。 |
| `metrics.port`                                                | `8083`                                                          | メトリクスエンドポイントポート |
| `metrics.listenAddr`                                          | `0.0.0.0`                                                       | メトリクスリスニングアドレス。 |
| `metrics.path`                                                | `/metrics`                                                      | メトリクスエンドポイントパス |
| `metrics.serviceMonitor.enabled`                              | `false`                                                         | Prometheus Operatorがメトリクスのスクレイプを管理できるようにServiceMonitorを作成する場合、これを有効にすると`prometheus.io`のスクレイプアノテーションが削除されることに注意してください。 |
| `metrics.serviceMonitor.additionalLabels`                     | `{}`                                                            | ServiceMonitorに追加する追加ラベル |
| `metrics.serviceMonitor.endpointConfig`                       | `{}`                                                            | ServiceMonitorの追加エンドポイント設定 |
| `metrics.annotations`                                         |                                                                 | **DEPRECATED**：明示的なメトリクスアノテーションを設定します。テンプレートコンテンツに置き換えられます。 |
| `metrics.tls.enabled`                                         |                                                                 | メトリクス/web_exporterエンドポイントでTLSを有効にします。`tls.enabled`がデフォルトです。 |
| `metrics.tls.secretName`                                      |                                                                 | メトリクス/web_exporterエンドポイントのTLS証明書とキー用のシークレット。`tls.secretName`がデフォルトです。 |
| `minio.bucket`                                                | `git-lfs`                                                       | MinIO使用時のストレージバケット名 |
| `minio.port`                                                  | `9000`                                                          | MinIOサービス用のポート |
| `minio.serviceName`                                           | `minio-svc`                                                     | MinIOサービス名 |
| `monitoring.ipWhitelist`                                      | `[0.0.0.0/0, ::/0]`                                             | モニタリングエンドポイントでホワイトリストに登録するIPのリスト |
| `monitoring.exporter.listenAddr`                              | `0.0.0.0`                                                       | メトリクスリスニングアドレス。 |
| `monitoring.exporter.enabled`                                 | `false`                                                         | ウェブサーバーがPrometheusメトリクスを公開できるようにします。メトリクスポートがモニタリングexporterポートに設定されている場合、これは`metrics.enabled`によってオーバーライドされます。 |
| `monitoring.exporter.port`                                    | `8083`                                                          | メトリクスexporterに使用するポート番号 |
| `psql.password.key`                                           | `psql-password`                                                 | psqlシークレット内のpsqlパスワードへのキー |
| `psql.password.secret`                                        | `gitlab-postgres`                                               | psqlシークレット名 |
| `psql.port`                                                   |                                                                 | PostgreSQLサーバーポートを設定します。`global.psql.port`よりも優先されます。 |
| `puma.disableWorkerKiller`                                    | `true`                                                          | Pumaワーカーメモリキラーを無効にします。 |
| `puma.workerMaxMemory`                                        |                                                                 | Pumaワーカーキラーの最大メモリ（メガバイト単位） |
| `puma.threads.min`                                            | `4`                                                             | Pumaスレッドの最小数 |
| `puma.threads.max`                                            | `4`                                                             | Pumaスレッドの最大数 |
| `puma.bindIp6`                                                | `false`                                                         | PumaでIPv6アドレスをバインドします。現在、レート制限に関連する[既知の問題](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6084)のため、デフォルトではfalseです。 |
| `rack_attack.git_basic_auth`                                  | `{}`                                                            | 詳細は[GitLabドキュメント](https://docs.gitlab.com/administration/settings/protected_paths/)を参照してください。 |
| `redis.serviceName`                                           | `redis`                                                         | Redisサービス名 |
| `global.registry.api.port`                                    | `5000`                                                          | レジストリポート |
| `global.registry.api.protocol`                                | `http`                                                          | レジストリプロトコル |
| `global.registry.api.serviceName`                             | `registry`                                                      | レジストリサービス名 |
| `global.registry.enabled`                                     | `true`                                                          | すべてのプロジェクトメニューにレジストリリンクを追加/削除します。 |
| `global.registry.tokenIssuer`                                 | `gitlab-issuer`                                                 | レジストリトークン発行者 |
| `replicaCount`                                                | `1`                                                             | Webserviceレプリカ数 |
| `resources.requests.cpu`                                      | `300m`                                                          | Webserviceの最小CPU |
| `resources.requests.memory`                                   | `1.5G`                                                          | Webserviceの最小メモリ |
| `service.externalPort`                                        | `8080`                                                          | Webservice公開ポート |
| `securityContext.fsGroup`                                     | `1000`                                                          | ポッドを開始するグループID |
| `securityContext.runAsUser`                                   | `1000`                                                          | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`                         |                                                                 | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要） |
| `securityContext.seccompProfile.type`                         | `RuntimeDefault`                                                | 使用するSeccompプロファイル |
| `containerSecurityContext`                                    |                                                                 | コンテナが開始される際のコンテナ[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします。 |
| `containerSecurityContext.runAsUser`                          | `1000`                                                          | コンテナが開始される特定のセキュリティコンテキストユーザーIDを上書きすることができます。 |
| `containerSecurityContext.allowPrivilegeEscalation`           | `false`                                                         | Gitalyコンテナのプロセスがその親プロセスよりも多くの権限を取得できるかどうかを制御します。 |
| `containerSecurityContext.runAsNonRoot`                       | `true`                                                          | Gitalyコンテナが非rootユーザーで実行されるかどうかを制御します。 |
| `containerSecurityContext.capabilities.drop`                  | `[ "ALL" ]`                                                     | Gitalyコンテナから[Linuxケーパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します。 |
| `serviceAccount.automountServiceAccountToken`                 | `false`                                                         | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します。 |
| `serviceAccount.create`                                       | `false`                                                         | ServiceAccountを作成する必要があるかどうかを示します。 |
| `serviceAccount.enabled`                                      | `false`                                                         | ServiceAccountを使用するかどうかを示します。 |
| `serviceAccount.name`                                         |                                                                 | ServiceAccountの名前。設定されていない場合、完全なチャート名が使用されます。 |
| `serviceLabels`                                               | `{}`                                                            | 補足的なサービスラベル |
| `service.internalPort`                                        | `8080`                                                          | Webservice内部ポート |
| `service.type`                                                | `ClusterIP`                                                     | Webserviceサービスタイプ |
| `service.workhorseExternalPort`                               | `8181`                                                          | Workhorse公開ポート |
| `service.workhorseInternalPort`                               | `8181`                                                          | Workhorse内部ポート |
| `service.loadBalancerIP`                                      |                                                                 | LoadBalancerに割り当てるIPアドレス（クラウドプロバイダーがサポートしている場合） |
| `service.loadBalancerSourceRanges`                            |                                                                 | LoadBalancerへのアクセスを許可するIP CIDRのリスト（サポートされている場合）。service.type = LoadBalancerに必要です。 |
| `shell.authToken.key`                                         | `secret`                                                        | shellシークレット内のshellトークンへのキー |
| `shell.authToken.secret`                                      | `{Release.Name}-gitlab-shell-secret`                            | Shellトークンシークレット |
| `shell.port`                                                  | `nil`                                                           | GitLab UIによって生成されるSSH URLで使用するポート番号 |
| `shutdown.blackoutSeconds`                                    | `10`                                                            | シャットダウンを受信後、Webserviceの実行を継続する秒数。`deployment.terminationGracePeriodSeconds`より短くなければなりません。また、Workhorseヘルスチェックリスナーが有効になっている場合は、そのシャットダウン遅延を設定します。 |
| `tls.enabled`                                                 | `false`                                                         | Webservice TLSを有効にします。 |
| `tls.secretName`                                              | `{Release.Name}-webservice-tls`                                 | Webservice TLSシークレット。`secretName`は[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を指す必要があります。 |
| `tolerations`                                                 | `[]`                                                            | ポッド割り当て用のラベル。 |
| `trusted_proxies`                                             | `[]`                                                            | 詳細は[GitLabドキュメント](https://docs.gitlab.com/install/installation/#adding-your-trusted-proxies)を参照してください。 |
| `workhorse.logFormat`                                         | `json`                                                          | ログ形式。有効な形式：`json`、`structured`、`text` |
| `workerProcesses`                                             | `2`                                                             | Webserviceワーカー数 |
| `workhorse.keywatcher`                                        | `true`                                                          | WorkhorseをRedisにサブスクライブします。これは`/api/*`へのリクエストを処理するすべてのデプロイで**required**ですが、他のデプロイでは安全に無効にできます。 |
| `workhorse.shutdownTimeout`                                   | `global.webservice.workerTimeout + 1`（秒）                 | すべてのウェブリクエストがWorkhorseからクリアされるのを待つ時間。例：`1min`、`65s`。 |
| `workhorse.adoptCfRayHeader`                                  | `false`                                                         | 着信`Cf-Ray`ヘッダーが存在する場合、それを相関IDとして採用します。詳細は[Workhorseドキュメント](https://docs.gitlab.com/development/workhorse/configuration/#propagate-correlation-ids)を参照してください。 |
| `workhorse.trustedCIDRsForPropagation`                        |                                                                 | 相関IDの伝播に信頼できるCIDRブロックのリスト。これが機能するには、`workhorse.extraArgs`でも`-propagateCorrelationID`オプションを使用する必要があります。詳細は[Workhorseドキュメント](https://docs.gitlab.com/development/workhorse/configuration/#propagate-correlation-ids)を参照してください。 |
| `workhorse.trustedCIDRsForXForwardedFor`                      |                                                                 | `X-Forwarded-For` HTTPヘッダーを介して実際のクライアントIPを解決するために使用できるCIDRブロックのリスト。これは`workhorse.trustedCIDRsForPropagation`とともに使用されます。詳細は[Workhorseドキュメント](https://docs.gitlab.com/development/workhorse/configuration/#trusted-proxies)を参照してください。 |
| `workhorse.metadata.zipReaderLimitBytes`                      |                                                                 | zipリーダーを制限するオプションのバイト数。GitLab 16.9で導入されました。詳細は[Workhorseドキュメント](https://docs.gitlab.com/development/workhorse/configuration/#metadata-options)を参照してください。 |
| `workhorse.containerSecurityContext`                          |                                                                 | コンテナが開始される際のコンテナ[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします。 |
| `workhorse.containerSecurityContext.runAsUser`                | `1000`                                                          | コンテナを開始するユーザーID |
| `workhorse.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                         | コンテナのプロセスがその親プロセスよりも多くの権限を取得できるかどうかを制御します。 |
| `workhorse.containerSecurityContext.runAsNonRoot`             | `true`                                                          | コンテナが非rootユーザーで実行されるかどうかを制御します。 |
| `workhorse.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                     | Gitalyコンテナから[Linuxケーパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します。 |
| `workhorse.livenessProbe.initialDelaySeconds`                 | `20`                                                            | ライブネスプローブが開始される前の遅延 |
| `workhorse.livenessProbe.periodSeconds`                       | `60`                                                            | ライブネスプローブを実行する頻度 |
| `workhorse.livenessProbe.timeoutSeconds`                      | `30`                                                            | ライブネスプローブがタイムアウトするとき |
| `workhorse.livenessProbe.successThreshold`                    | `1`                                                             | ライブネスプローブが失敗した後に成功と見なされるための最小連続成功数 |
| `workhorse.livenessProbe.failureThreshold`                    | `3`                                                             | ライブネスプローブが成功した後に失敗と見なされるための最小連続失敗数 |
| `workhorse.healthcheckListener.enabled`                       | `false`                                                         | Workhorseヘルスチェックリスナーを有効にし、デフォルトのPumaレディネスプローブを無効にします。レディネスヘルスステータスをより信頼性が高く、Flakyさが少なく検出できます。GitLab 18.5で導入されました。 |
| `workhorse.healthcheckListener.port`                          | `8182`                                                          | ヘルスチェックリスナーに使用するポート番号。 |
| `workhorse.healthcheckListener.pumaControl`                   | `true`                                                          | Pumaレディネスエンドポイントの代わりにPumaコントロールアプリケーションをクエリする。 |
| `workhorse.healthcheckListener.checkInterval`                 | `10s`                                                           | アップストリームPumaサーバーの連続したヘルスステータスチェック間の時間間隔。 |
| `workhorse.healthcheckListener.timeout`                       | `5s`                                                            | Pumaチェックリクエストのタイムアウト。 |
| `workhorse.healthcheckListener.maxConsecutiveFailures`        | `1`                                                             | Workhorseを準備ができていないとマークするまでの失敗回数。 |
| `workhorse.healthcheckListener.minSuccessfullProbes`          | `1`                                                             | Workhorseが準備完了と見なされるまでの成功プローブ数。 |
| `workhorse.healthcheckListener.railsSkipInterval`             | `0s`                                                            | リクエストが正常に処理された後、Pumaレディネスチェックを再開するまでの時間遅延。デフォルトでは無効になっています。 |
| `workhorse.loadShedding.enabled`                              | `false`                                                         | Pumaのリクエストバックログがしきい値を超えたときに`503`を返すようにロードシェディングを有効にします。 |
| `workhorse.loadShedding.backlogThreshold`                     | `50`                                                            | ロードシェディングを開始するバックログしきい値。 |
| `workhorse.loadShedding.backlogHysteresis`                    | `0.8`                                                           | 非アクティブ化のヒステリシス係数（0.0～1.0）。バックログがしきい値 * ヒステリシスを下回ると、ロードシェディングは非アクティブ化されます。 |
| `workhorse.loadShedding.retryAfterSeconds`                    | `0`                                                             | ロードシェディング時のレスポンス内のRetry-Afterヘッダー値（秒単位）。即時リトライには0を使用します（Kubernetesに推奨）。 |
| `workhorse.loadShedding.statusCode`                           | `503`                                                           | ロードシェディング時に返すHTTPステータスコード。ロードシェディングを他の`503`エラーと区別するために、`529`のようなカスタムコードを使用します。 |
| `workhorse.loadShedding.strategy`                             | `max`                                                           | 実効バックログを計算する戦略：「max」（デフォルト）または「sum」。 |
| `workhorse.loadShedding.checkInterval`                        | `1s`                                                            | Pumaのバックログメトリクスをサンプリングする頻度。ヘルスチェック間隔とは独立しています。 |
| `workhorse.loadShedding.timeout`                              | `5s`                                                            | コントロールサーバーリクエストのタイムアウト。 |
| `workhorse.monitoring.exporter.enabled`                       | `false`                                                         | WorkhorseがPrometheusメトリクスを公開できるようにします。これは`workhorse.metrics.enabled`によってオーバーライドされます。 |
| `workhorse.monitoring.exporter.port`                          | `9229`                                                          | Workhorse Prometheusメトリクスに使用するポート番号 |
| `workhorse.monitoring.exporter.tls.enabled`                   | `false`                                                         | `true`に設定すると、メトリクスエンドポイントでTLSを有効にします。Workhorseで[TLSが有効になっている](#gitlab-workhorse)必要があります。 |
| `workhorse.metrics.enabled`                                   | `true`                                                          | Workhorseメトリクスエンドポイントをスクレイプ可能にするかどうか。 |
| `workhorse.metrics.port`                                      | `8083`                                                          | Workhorseメトリクスエンドポイントポート |
| `workhorse.metrics.path`                                      | `/metrics`                                                      | Workhorseメトリクスエンドポイントパス |
| `workhorse.metrics.serviceMonitor.enabled`                    | `false`                                                         | Prometheus OperatorがWorkhorseメトリクスのスクレイプを管理できるようにServiceMonitorを作成するかどうか。 |
| `workhorse.metrics.serviceMonitor.additionalLabels`           | `{}`                                                            | Workhorse ServiceMonitorに追加する追加ラベル |
| `workhorse.metrics.serviceMonitor.endpointConfig`             | `{}`                                                            | Workhorse ServiceMonitorの追加エンドポイント設定 |
| `workhorse.readinessProbe.initialDelaySeconds`                | `0`                                                             | レディネスプローブが開始される前の遅延 |
| `workhorse.readinessProbe.periodSeconds`                      | `10`                                                            | レディネスプローブを実行する頻度 |
| `workhorse.readinessProbe.timeoutSeconds`                     | `2`                                                             | レディネスプローブがタイムアウトするとき |
| `workhorse.readinessProbe.successThreshold`                   | `1`                                                             | レディネスプローブが失敗した後に成功と見なされるための最小連続成功数 |
| `workhorse.readinessProbe.failureThreshold`                   | `3`                                                             | レディネスプローブが成功した後に失敗と見なされるための最小連続失敗数 |
| `workhorse.imageScaler.maxProcs`                              | `2`                                                             | 同時に実行できるイメージスケールプロセスの最大数 |
| `workhorse.imageScaler.maxFileSizeBytes`                      | `250000`                                                        | スケーラーによって処理される画像の最大ファイルサイズ（バイト単位） |
| `workhorse.tls.verify`                                        | `true`                                                          | `true`に設定すると、NGINX IngressはWorkhorseのTLS証明書を強制的に検証します。カスタム認証局の場合、`workhorse.tls.caSecretName`も設定する必要があります。自己署名証明書の場合は`false`に設定する必要があります。 |
| `workhorse.tls.secretName`                                    | `{Release.Name}-workhorse-tls`                                  | TLSキーと証明書のペアを含む[TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)の名前。これはWorkhorse TLSが有効な場合に必要です。 |
| `workhorse.tls.caSecretName`                                  |                                                                 | CA証明書を含むシークレットの名前。これは**等しくない** [TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)であり、`ca.crt`キーのみを持つ必要があります。これはNGINXによるTLS検証に使用されます。 |
| `workhorse.circuitBreaker.enabled`                            | `false`                                                         | サーキットブレーカーが有効になっているかどうか |
| `workhorse.circuitBreaker.timeout`                            | `60`                                                            | オープン時にサーキットブレーカーをハーフオープンに移行する期間（秒） |
| `workhorse.circuitBreaker.interval`                           | `180`。                                                          | クローズ時にサーキットブレーカーが連続失敗をクリアするまでの期間（秒） |
| `workhorse.circuitBreaker.maxRequests`                        | `1`。                                                            | ハーフオープン時にサーキットブレーカーをオープンにするための失敗リクエスト数 |
| `workhorse.circuitBreaker.consecutiveFailures`                | `5`。                                                            | クローズ時にサーキットブレーカーをオープンにするための連続失敗リクエスト数 |
| `webServer`                                                   | `puma`                                                          | リクエスト処理に使用されるウェブサーバー（Webservice/Puma）を選択します。 |
| `priorityClassName`                                           | `""`                                                            | ポッドの`priorityClassName`を設定できます。これは立ち退きの場合にポッドの優先順位を制御するために使用されます。 |
| `antiAffinity`                                           | `""`                                                         | チャートのグローバル値からantiAffinity値を上書きすることができます。デフォルトはグローバルから読み取られ、`soft`または`hard`に設定できます。 |

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

`extraEnvFrom`を使用すると、他のデータソースからの追加の環境変数を、ポッド内のすべてのコンテナで公開できます。後続の変数は、[デプロイ](#deployments-settings)ごとにオーバーライドできます。

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
deployments:
  default:
    extraEnvFrom:
      CONFIG_STRING:
        configMapKeyRef:
          name: useful-config
          key: some-string
          # optional: boolean
```

### `image.pullSecrets` {#imagepullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに認証することで、ポッド用のイメージをプルすることができます。

プライベートレジストリとそれらの認証方法に関する追加の詳細は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)で確認できます。

`pullSecrets`の使用例を以下に示します。

```yaml
image:
  repository: my.webservice.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

このセクションは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountアノテーション。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成する必要があるかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定されていない場合、完全なチャート名が使用されます。 |

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

### `annotations` {#annotations}

`annotations`を使用すると、Webserviceポッドにアノテーションを追加できます。例: 

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### `strategy` {#strategy}

`deployment.strategy`を使用すると、デプロイの更新戦略を変更できます。デプロイが更新されたときにポッドがどのように再作成されるかを定義します。指定しない場合、クラスターのデフォルトが使用されます。たとえば、ローリングアップデート開始時に追加のポッドを作成せず、最大利用不可ポッドを50%に変更したい場合:

```yaml
deployment:
  strategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 50%
```

更新戦略のタイプを`Recreate`に変更することもできますが、これは新しいポッドをスケジュールする前にすべてのポッドを強制終了するため、新しいポッドが起動するまでウェブUIが利用できなくなることに注意してください。この場合、`rollingUpdate`を定義する必要はなく、`type`のみで構いません:

```yaml
deployment:
  strategy:
    type: Recreate
```

詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)を参照してください。

### TLS {#tls}

Webserviceポッドは2つのコンテナを実行します:

- `gitlab-workhorse`
- `webservice`

#### `gitlab-workhorse` {#gitlab-workhorse}

Workhorseはウェブおよびメトリクスエンドポイントの両方でTLSをサポートします。これにより、Workhorseと他のコンポーネント、特に`nginx-ingress`、`gitlab-shell`、および`gitaly`間の通信が保護されます。TLS証明書には、Workhorseサービスのホスト名（例：`RELEASE-webservice-default.default.svc`）をCommon Name（CN）またはSubject Alternate Name（SAN）に含める必要があります。

Webserviceの[複数のデプロイ](#deployments-settings)が存在する可能性があるため、異なるサービス名に対応するTLS証明書を準備する必要があることに注意してください。これは複数のSANまたはワイルドカード証明書によって実現できます。

TLS証明書が生成されたら、それ用の[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を作成します。また、TLS証明書のCA証明書のみを含む別のシークレットを`ca.crt`キーで作成する必要があります。

`global.workhorse.tls.enabled`を`true`に設定することで、`gitlab-workhorse`コンテナでTLSを有効にできます。カスタムシークレット名を`gitlab.webservice.workhorse.tls.secretName`および`global.certificates.customCAs`にそれぞれ渡すことができます。

`gitlab.webservice.workhorse.tls.verify`が`true`（デフォルト）の場合、CA証明書のシークレット名を`gitlab.webservice.workhorse.tls.caSecretName`に渡す必要もあります。これは自己署名証明書およびカスタム認証局に必要です。このシークレットは、NGINXがWorkhorseのTLS証明書を検証するために使用します。

```yaml
global:
  workhorse:
    tls:
      enabled: true
  certificates:
    customCAs:
      - secret: gitlab-workhorse-ca
gitlab:
  webservice:
    workhorse:
      tls:
        verify: true
        # secretName: gitlab-workhorse-tls
        caSecretName: gitlab-workhorse-ca
      monitoring:
        exporter:
          enabled: true
          tls:
            enabled: true
```

`gitlab-workhorse`コンテナのメトリクスエンドポイントにおけるTLSは`global.workhorse.tls.enabled`から継承されます。メトリクスエンドポイントにおけるTLSは、WorkhorseでTLSが有効な場合にのみ利用可能であることに注意してください。このメトリクスリスナーは、`gitlab.webservice.workhorse.tls.secretName`で指定されたものと同じTLS証明書を使用します。

メトリクスエンドポイントに使用されるTLS証明書は、特に含まれるPrometheus Helmチャートを使用する場合、含まれるSubject Alternative Names（SANs）について追加の考慮事項を必要とする場合があります。詳細については、[Prometheusをスクレイプ可能なTLS有効エンドポイントに設定する](../../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints)を参照してください。

#### `webservice` {#webservice}

TLSを有効にする主なユースケースは、[Prometheusメトリクスをスクレイプ](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/)するためのHTTPS経由の暗号化を提供することです。

PrometheusがHTTPSを使用して`/metrics/`エンドポイントをスクレイプするには、証明書の`CommonName`属性または`SubjectAlternativeName`エントリに追加の設定が必要です。これらの要件については、[Prometheusをスクレイプ可能なTLS有効エンドポイントに設定する](../../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints)を参照してください。

`gitlab.webservice.tls.enabled`設定により、`webservice`コンテナでTLSを有効にできます:

```yaml
gitlab:
  webservice:
    tls:
      enabled: true
      # secretName: gitlab-webservice-tls
```

`secretName`は[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を指す必要があります。例えば、ローカル証明書とキーを持つTLSシークレットを作成するには:

```shell
kubectl create secret tls <secret name> --cert=path/to/puma.crt --key=path/to/puma.key
```

## このチャートのCommunity Editionを使用する {#using-the-community-edition-of-this-chart}

デフォルトの場合、HelmチャートではGitLabのEnterprise Editionを使用します。必要であれば、代わりにCommunity Editionを使用できます。両者の[違い](https://about.gitlab.com/install/ce-or-ee/)について詳しくはこちら。

Community Editionを使用するには、`image.repository`を`registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ce`に、`workhorse.image`を`registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ce`に設定します。

## グローバル設定 {#global-settings}

いくつかの一般的なグローバル設定をチャート間で共有しています。共通の設定オプション（GitLabやレジストリのホスト名など）については、[Globalsドキュメント](../../globals.md)を参照してください。

## デプロイ設定 {#deployments-settings}

このチャートは、複数のデプロイオブジェクトとそれに関連するリソースを作成する機能を持っています。この機能により、GitLabアプリケーションへのリクエストは、パスベースのルーティングを使用して複数のポッドセット間で分散されます。

このマップのキー（この例では`default`）は、それぞれの「名前」です。`default`には、デプロイ、サービス、HorizontalPodAutoscaler、PodDisruptionBudget、およびオプションで`RELEASE-webservice-default`で作成されたIngressが設定されます。

提供されていないプロパティは、`gitlab-webservice`チャートのデフォルトから継承されます。

```yaml
deployments:
  default:
    ingress:
      path: # Does not inherit or default. Leave blank to disable Ingress.
      pathType: Prefix
      provider: nginx
      annotations:
        # inherits `ingress.anntoations`
      proxyConnectTimeout: # inherits `ingress.proxyConnectTimeout`
      proxyReadTimeout:    # inherits `ingress.proxyReadTimeout`
      proxyBodySize:       # inherits `ingress.proxyBodySize`
    deployment:
      annotations: # map
      labels: # map
      # inherits `deployment`
    pod:
      labels: # additional labels to .podLabels
      annotations: # map
        # inherit from .Values.annotations
    service:
      labels: # additional labels to .serviceLabels
      annotations: # additional annotations to .service.annotations
        # inherits `service.annotations`
    hpa:
      minReplicas: # defaults to .minReplicas
      maxReplicas: # defaults to .maxReplicas
      metrics: # optional replacement of HPA metrics definition
      # inherits `hpa`
    pdb:
      maxUnavailable: # inherits `maxUnavailable`
    resources: # `resources` for `webservice` container
      # inherits `resources`
    workhorse: # map
      # inherits `workhorse`
    extraEnv: #
      # inherits `extraEnv`
    extraEnvFrom: #
      # inherits `extraEnvFrom`
    puma: # map
      # inherits `puma`
    workerProcesses: # inherits `workerProcesses`
    shutdown:
      # inherits `shutdown`
    nodeSelector: # map
      # inherits `nodeSelector`
    tolerations: # array
      # inherits `tolerations`
    priorityClassName: # inherits `priorityClassName`
```

### デプロイIngress {#deployments-ingress}

各`deployments`エントリは、チャート全体の[Ingress設定](#ingress-settings)を継承します。ここで提示される値は、そちらで提供される値をオーバーライドします。`path`を除き、すべての設定は同じです。

```yaml
webservice:
  deployments:
    default:
      ingress:
        path: /
    api:
      ingress:
        path: /api
```

`path`プロパティはIngressの`path`プロパティに直接入力され、各サービスに送信されるURIパスを制御できます。上記の例では、`default`がキャッチオールパスとして機能し、`api`が`/api`以下のすべてのトラフィックを受信しました。

`path`を空に設定することで、特定のデプロイに関連付けられたIngressリソースが作成されないように無効にできます。以下を参照してください。`internal-api`は外部トラフィックを受信しません。

```yaml
webservice:
  deployments:
    default:
      ingress:
        path: /
    api:
      ingress:
        path: /api
    internal-api:
      ingress:
        path:
```

## Ingress設定 {#ingress-settings}

| 名前                              |  型   | デフォルト                   | 説明 |
|:----------------------------------|:-------:|:--------------------------|:------------|
| `ingress.apiVersion`              | 文字列  |                           | `apiVersion`フィールドで使用する値。 |
| `ingress.annotations`             |   マップ   | [下記](#annotations)を参照 | これらのアノテーションはすべてのIngressに使用されます。例: `ingress.annotations."nginx\.ingress\.kubernetes\.io/enable-access-log"=true`。 |
| `ingress.configureCertmanager`    | ブール値 |                           | Ingressアノテーション`cert-manager.io/issuer`と`acme.cert-manager.io/http01-edit-in-place`を切り替えます。詳細については、[GitLab PagesのTLS要件](../../../installation/tls.md)を参照してください。 |
| `ingress.enabled`                 | ブール値 | `false`                   | サポートするサービス用のIngressオブジェクトを作成するかどうかを制御する設定。`false`の場合、`global.ingress.enabled`設定値が使用されます。 |
| `ingress.proxyBodySize`           | 文字列  | `512m`                    | [下記を参照](#proxybodysize)。 |
| `ingress.serviceUpstream`         | ブール値 | `true`                    | [下記を参照](#serviceupstream)。 |
| `ingress.tls.enabled`             | ブール値 | `true`                    | `false`に設定すると、GitLab WebserviceのTLSが無効になります。これは主に、IngressレベルでTLS終端を使用できない場合（Ingressコントローラーの前にTLS終端プロキシがある場合など）に有用です。 |
| `ingress.tls.secretName`          | 文字列  | （空）                   | GitLab URLの有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定されていない場合、代わりに`global.ingress.tls.secretName`値が使用されます。 |
| `ingress.tls.smardcardSecretName` | 文字列  | （空）                   | 有効な場合、GitLabスマートカードURLの有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定されていない場合、代わりに`global.ingress.tls.secretName`値が使用されます。 |
| `ingress.tls.useGeoClass`         | ブール値 | `false`                   | IngressClassをGeo Ingressクラス（`global.geo.ingressClass`）でオーバーライドします。プライマリGeoサイトに必要です。 |

### アノテーション {#annotations-1}

`annotations`はWebservice Ingressにアノテーションを設定するために使用されます。

### `serviceUpstream` {#serviceupstream}

これにより、NGINXにサービス自体をアップストリームとして直接コンタクトさせることで、Webserviceポッドへのトラフィックをより均等に分散するのに役立ちます。詳細については、[NGINXドキュメント](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md#service-upstream)を参照してください。

これをオーバーライドするには、以下を設定します:

```yaml
gitlab:
  webservice:
    ingress:
      serviceUpstream: "false"
```

### `proxyBodySize` {#proxybodysize}

`proxyBodySize`は、NGINXプロキシの最大ボディサイズを設定するために使用されます。これは、デフォルトよりも大きなDockerイメージを許可するために一般的に必要です。これは[Linuxパッケージインストール](https://docs.gitlab.com/omnibus/settings/nginx/#use-an-existing-passenger-and-nginx-installation)における`nginx['client_max_body_size']`設定と同等です。代替オプションとして、以下の2つのパラメータのいずれかでもボディサイズを設定できます:

- `gitlab.webservice.ingress.annotations."nginx\.ingress\.kubernetes\.io/proxy-body-size"`
- `global.ingress.annotations."nginx\.ingress\.kubernetes\.io/proxy-body-size"`

### 追加Ingress {#extra-ingress}

`extraIngress.enabled=true`を設定することで、追加のIngressをデプロイできます。このIngressは、デフォルトのIngressに`-extra`サフィックスを付けて命名され、デフォルトのIngressと同じ設定をサポートします。

## ゲートウェイAPI {#gateway-api}

GitLabチャートが[Gateway API経由で公開](../../globals.md#gateway-api)されるように設定されている場合、各デプロイはwebserviceチャートの`HTTPRoute`へのルールとして追加されます。

`.rules=[]`をデプロイに設定することで、特定のデプロイが`HTTPRoute`にルールを持つことを無効にできます。

```yaml
webservice:
  deployments:
    default:
      gatewayRoute:
        rules:
        - matches:
          - path:
              type: PathPrefix
              value: /
            timeouts:
              request: "20s"
              backendRequest: "20s"
    api:
      gatewayRoute:
        rules:
        - matches:
          - path:
              type: PathPrefix
              value: /api
    internal-api:
      gatewayRoute:
        rules: []
```

## リソース {#resources}

### メモリリクエスト/制限 {#memory-requestslimits}

各ポッドは`workerProcesses`に等しい数のワーカーを起動し、それぞれが一定量のメモリを使用します。推奨事項:

- ワーカーあたり最小1.25GB（`requests.memory`）
- ワーカーあたり最大1.5GB、プライマリ用に1GB追加（`limits.memory`）

必要なリソースは、ユーザーによって生成されるワークロードに依存し、将来、GitLabアプリケーションの変更やアップグレードに基づいて変更される可能性があることに注意してください。

デフォルト: 

```yaml
workerProcesses: 2
resources:
  requests:
    memory: 2.5G # = 2 * 1.25G
# limits:
#   memory: 4G   # = (2 * 1.5G) + 950M
```

4つのワーカーが設定されている場合:

```yaml
workerProcesses: 4
resources:
  requests:
    memory: 5G   # = 4 * 1.25G
# limits:
#   memory: 7G   # = (4 * 1.5G) + 950M
```

## 外部サービス {#external-services}

### Redis {#redis}

Redisドキュメントは[グローバル](../../globals.md#configure-redis-settings)ページに統合されました。最新のRedis設定オプションについては、このページを参照してください。

### PostgreSQL {#postgresql}

PostgreSQLドキュメントは[グローバル](../../globals.md#configure-postgresql-settings)ページに統合されました。最新のPostgreSQL設定オプションについては、このページを参照してください。

Webserviceデプロイ内の`dependencies` `initContainer`は、スクリプトを実行して以下をチェックします:

- GitLabの依存関係が利用可能かどうか。
- PostgreSQL用のデータベース移行が実行されたかどうか。

Webserviceチャートの`extraEnv`設定キーを使用して、これらのスクリプトの動作を制御できます。2つの環境変数がサポートされています:

- `BYPASS_POST_DEPLOYMENT=true`: すべての通常の移行が実行され、デプロイ後の移行のみが保留中の場合、依存関係チェックは合格します。
- `BYPASS_SCHEMA_VERSION=true`（推奨されません）: 通常の移行が実行されていない場合でも、依存関係チェックは合格します。この環境変数を使用すると、データベーススキーマがアプリケーションコードの期待値と一致しないため、Railsデプロイは起動後にエラーになる可能性があります。

### Gitaly {#gitaly}

```yaml
global:
  gitaly:
    ## These settings are used by Gitaly clients: GitLab Rails, GitLab Shell, Workhorse.
    client:
      maxAttempts: 4
      maxBackoff: '1.4s'
```

| 名前             |  型   | デフォルト  | 説明                                                                                                                         |
|:-----------------|:-------:|:---------|:------------------------------------------------------------------------------------------------------------------------------------|
| `maxAttempts`    | 整数 | `4`      | 失敗した場合に、Gitalyクライアントがクライアントにエラーを返す前に、リクエストを再送信しようとする最大回数。 |
| `maxBackoff`     | 文字列  | `'1.4s'` | Gitalyクライアントがクライアントにエラーを返す前に、リクエストを再試行する最大時間（秒単位）。                  |

その他のGitaly設定は、[グローバル設定](../../globals.md)によって設定されます。[Gitaly設定ドキュメント](../../globals.md#configure-gitaly-settings)を参照してください。

### MinIO {#minio}

```yaml
minio:
  serviceName: 'minio-svc'
  port: 9000
```

| 名前          |  型   | デフォルト     | 説明 |
|:--------------|:-------:|:------------|:------------|
| `port`        | 整数 | `9000`      | MinIO `Service`に到達するためのポート番号。 |
| `serviceName` | 文字列  | `minio-svc` | MinIOポッドによって公開される`Service`の名前。 |

### レジストリ {#registry}

```yaml
registry:
  host: registry.example.com
  port: 443
  api:
    protocol: http
    host: registry.example.com
    serviceName: registry
    port: 5000
  tokenIssuer: gitlab-issuer
  certificate:
    secret: gitlab-registry
    key: registry-auth.key
```

| 名前                 |  型   | デフォルト         | 説明 |
|:---------------------|:-------:|:----------------|:------------|
| `api.host`           | 文字列  |                 | 使用するレジストリサーバーのホスト名。`api.serviceName`の代わりとして省略できます。 |
| `api.port`           | 整数 | `5000`          | レジストリAPIに接続するためのポート。 |
| `api.protocol`       | 文字列  |                 | WebserviceがレジストリAPIに到達するために使用すべきプロトコル。 |
| `api.serviceName`    | 文字列  | `registry`      | レジストリサーバーを操作している`service`の名前。これが存在し、`api.host`が存在しない場合、チャートは`api.host`値の代わりにサービスのホスト名（および現在の`.Release.Name`）をテンプレート処理します。これは、レジストリをGitLabチャート全体の一部として使用する場合に便利です。 |
| `certificate.key`    | 文字列  |                 | [レジストリ](https://hub.docker.com/_/registry/)コンテナに`auth.token.rootcertbundle`として提供される証明書バンドルを格納する`Secret`内の`key`の名前。 |
| `certificate.secret` | 文字列  |                 | GitLabインスタンスによって作成されたトークンを検証するために使用される証明書バンドルを格納する[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/)の名前。 |
| `host`               | 文字列  |                 | GitLab UIでユーザーにDockerコマンドを提供するために使用する外部ホスト名。`registry.hostname`テンプレートで設定された値にフォールバックします。`global.hosts`で設定された値に基づいてレジストリホスト名を決定します。詳細については、[Globalsドキュメント](../../globals.md)を参照してください。 |
| `port`               | 整数 |                 | ホスト名で使用される外部ポート。ポート`80`または`443`を使用すると、URLは`http`/`https`で形成されます。他のポートはすべて`http`を使用し、ホスト名の最後にポートを追加します。例：`http://registry.example.com:8443`。 |
| `tokenIssuer`        | 文字列  | `gitlab-issuer` | 認証トークン発行者の名前。これは、送信時にトークンに組み込まれるため、レジストリの設定で使用されている名前と一致する必要があります。`gitlab-issuer`のデフォルトは、レジストリチャートで私たちが使用するデフォルトと同じです。 |

## チャート設定 {#chart-settings}

以下の値はWebserviceポッドを設定するために使用されます。

| 名前              |  型   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `workerProcesses` | 整数 | `2`     | ポッドごとに実行するWebserviceワーカーの数。GitLabが正しく機能するには、クラスター内に少なくとも`2`のワーカーが利用可能である必要があります。`workerProcesses`を増やすと、ワーカーあたり約`400MB`のメモリが必要になるため、ポッド`resources`をそれに応じて更新する必要があることに注意してください。 |
| `minReplicas`     | 整数 | `2`     | 最小レプリカ数 |
| `maxReplicas`     | 整数 | `10`    | 最大レプリカ数 |
| `maxUnavailable`  | 整数 | `1`     | 利用不可となるポッドの最大数の制限 |

### メトリクス {#metrics}

メトリクスは`metrics.enabled`の値で有効にでき、GitLabモニタリングexporterを使用してメトリクスポートを公開します。ポッドにはPrometheusアノテーションが与えられるか、`metrics.serviceMonitor.enabled`が`true`の場合はPrometheus Operator ServiceMonitorが作成されます。メトリクスは代わりに`/-/metrics`エンドポイントからスクレイプできますが、これには管理者エリアで[GitLab Prometheusメトリクス](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/)が有効になっている必要があります。GitLab Workhorseメトリクスも`workhorse.metrics.enabled`を介して公開できますが、これらはPrometheusアノテーションを使用して収集できないため、`workhorse.metrics.serviceMonitor.enabled`が`true`であるか、または外部Prometheus設定が必要です。

### GitLab Shell {#gitlab-shell}

GitLab Shellは、Webserviceとの通信で認証トークンを使用します。共有シークレットを使用して、トークンをGitLab ShellとWebserviceで共有します。

```yaml
shell:
  authToken:
    secret: gitlab-shell-secret
    key: secret
  port:
```

| 名前               |  型   | デフォルト | 説明 |
|:-------------------|:-------:|:--------|:------------|
| `authToken.key`    | 文字列  |         | authTokenを含むシークレット（下記）内のキーの名前を定義します。 |
| `authToken.secret` | 文字列  |         | プルするKubernetes `Secret`の名前を定義します。 |
| `port`             | 整数 | `22`    | GitLab UI内でSSH URLを生成する際に使用するポート番号。`global.shell.port`によって制御されます。 |

### ウェブサーバーオプション {#webserver-options}

現在のバージョンのチャートはPumaウェブサーバーをサポートしています。

Puma固有のオプション:

| 名前                   |  型   | デフォルト | 説明 |
|:-----------------------|:-------:|:--------|:------------|
| `puma.workerMaxMemory` | 整数 |         | Pumaワーカーキラーの最大メモリ（メガバイト単位） |
| `puma.threads.min`     | 整数 | `4`     | Pumaスレッドの最小数 |
| `puma.threads.max`     | 整数 | `4`     | Pumaスレッドの最大数 |

### Workhorseロードシェディング {#workhorse-load-shedding}

{{< history >}}

- GitLab 18.9で[導入](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/work_items/28055)されました。
- `statusCode`パラメータがGitLab 18.10で[追加されました](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225993)。

{{< /history >}}

ロードシェディングは、リクエストバックログが設定されたしきい値を超えたときに設定されたHTTPステータスコードを返すことでPumaが過負荷になるのを防ぎ、リバースプロキシが他のインスタンスへのリクエストを再試行できるようにします。

ロードシェディングを有効にするには、`loadShedding`パラメータを設定します:

```yaml
gitlab:
  webservice:
    workhorse:
      loadShedding:
        enabled: true
        backlogThreshold: 50
        retryAfterSeconds: 0
        statusCode: 503
        strategy: max
```

- `backlogThreshold`は、ロードシェディングをトリガーする滞留リクエストの数を指定します。
- `retryAfterSeconds`は、レスポンスの`Retry-After`ヘッダーの値を設定します。
- `statusCode`は、ロードシェディング時に返すHTTPステータスコードを設定します（デフォルト：`503`）。データベースのタイムアウトやGitalyの問題によって引き起こされる他の`503`エラーからロードシェディングを区別するために、`529`のようなカスタムコードを使用します。
- `strategy`は、実効バックログがどのように計算されるかを決定します:
  - `max`: すべてのPumaワーカーにおける最大バックログを使用します（デフォルト）。
  - `sum`: すべてのPumaワーカーにおけるすべてのバックログの合計を使用します。

#### プロキシ設定 {#proxy-configuration}

ロードシェディングを効果的に機能させるには、リバースプロキシが`503`レスポンスを受信したときにリクエストを再試行するように設定されている必要があります。これにより、リクエストが正常なインスタンスに分散されることが保証されます。

NGINXの例として、Ingressに次のアノテーションを設定します:

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/proxy-next-upstream: "http_503"
    nginx.ingress.kubernetes.io/proxy-next-upstream-tries: "3"
    nginx.ingress.kubernetes.io/proxy-next-upstream-timeout: "10s"
```

これらの設定はNGINXに以下を指示します:

- `503`レスポンスで再試行します（ロードシェディングが生成します）。
- 諦めるまでに3回まで試行します。
- 再試行のために最大10秒待ちます。

ロードシェディングが生成する特定のシグナルである`503`レスポンスでのみ再試行すべきです。他のステータスコード（`504`など）やエラー条件での再試行は避けてください。これらは、すべてのバックエンドで失敗する可能性のあるリクエストを再試行することで、停止中の負荷を増幅させる可能性があります。

他のリバースプロキシについては、同等の再試行設定についてそれぞれのドキュメントを参照してください。重要なキーは、`503`レスポンスが他のバックエンドインスタンスへの再試行をトリガーすることを保証することです。

## この`networkpolicy`を設定する {#configuring-the-networkpolicy}

このセクションは[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を制御します。この設定はオプションであり、ポッドのエグレスとIngressを特定のエンドポイントに制限するために使用されます。

| 名前              |  型   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | この設定により`NetworkPolicy`が有効になります。 |
| `ingress.enabled` | ブール値 | `false` | `true`に設定すると、`Ingress`ネットワークポリシーがアクティブ化されます。これにより、ルールが指定されていない限り、すべてのIngress接続がブロックされます。 |
| `ingress.rules`   |  配列  | `[]`    | Ingressポリシーのルール。詳細は<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください。 |
| `egress.enabled`  | ブール値 | `false` | `true`に設定すると、`Egress`ネットワークポリシーがアクティブ化されます。これにより、ルールが指定されていない限り、すべてのエグレス接続がブロックされます。 |
| `egress.rules`    |  配列  | `[]`    | エグレスポリシーのルール。詳細は<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください。 |

### ネットワークポリシーの例 {#example-network-policy}

webserviceサービスは、有効な場合はPrometheus exporter用のIngress接続、NGINX Ingressからのトラフィック、およびいくつかのGitLabポッドを必要とします。通常、さまざまな場所へのエグレス接続が必要です。この例では、以下のネットワークポリシーを追加します:

- Ingressリクエストを許可します:
  - ポッド`gitaly`、`gitlab-pages`、`gitlab-shell`、`kas`、`mailroom`、および`nginx-ingress`からポート`8181`へ
  - `Prometheus`ポッドからポート`8080`、`8083`、`9229`へ
- エグレスリクエストを許可します:
  - `gitaly`ポッドへのポート`8075`
  - `kas`ポッドへのポート`8153`
  - `kube-dns`へのポート`53`
  - `registry`ポッドへのポート`5000`
  - 外部データベース`172.16.0.10/32`へのポート`5432`
  - 外部Redis `172.16.0.11/32`へのポート`6379`
  - インターネット`0.0.0.0/0`へのポート`443`
  - AWS VPCエンドポイント（S3またはSTS用）などのエンドポイント`172.16.1.0/24`へのポート`443`

提供されている例は単なる例であり、完全ではない可能性があります。Webserviceは、[外部オブジェクトストレージ](../../../advanced/external-object-storage)上のイメージのために、パブリックインターネットへの送信接続を必要とします。この例は、`kube-dns`が`kube-system`ネームスペースにデプロイされ、`prometheus`が`monitoring`ネームスペースにデプロイされ、`nginx-ingress`が`nginx-ingress`ネームスペースにデプロイされたという前提に基づいています。

```yaml
networkpolicy:
  enabled: true
  ingress:
    enabled: true
    rules:
      - from:
          - podSelector:
              matchLabels:
                app: gitaly
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: gitlab-pages
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: gitlab-shell
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: kas
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: mailroom
        ports:
          - port: 8181
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 8181
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
          - port: 9229
          - port: 8080
          - port: 8083
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
          - ipBlock:
              cidr: 0.0.0.0/0
              except:
                - 10.0.0.0/8
        ports:
          - port: 443
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
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: kube-system
            podSelector:
              matchLabels:
                k8s-app: kube-dns
        ports:
          - port: 53
            protocol: UDP
```

### `LoadBalancer`サービス {#loadbalancer-service}

`service.type`が`LoadBalancer`に設定されている場合、オプションで`service.loadBalancerIP`を指定して、ユーザー指定のIPを持つ`LoadBalancer`を作成できます（クラウドプロバイダーがサポートしている場合）。

`service.type`が`LoadBalancer`に設定されている場合、`LoadBalancer`にアクセスできるCIDR範囲を制限するために`service.loadBalancerSourceRanges`も設定する必要があります（クラウドプロバイダーがサポートしている場合）。これは、[メトリクスポートが公開されている](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2500)問題により現在必要です。

`LoadBalancer`サービスタイプに関する追加情報は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)で確認できます。

```yaml
service:
  type: LoadBalancer
  loadBalancerIP: 1.2.3.4
  loadBalancerSourceRanges:
  - 10.0.0.0/8
```

## KEDAを設定する {#configuring-keda}

この`keda`セクションは、通常の`HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この設定はオプションであり、カスタムまたは外部メトリクスに基づいてオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する場合、`hpa`セクションで設定された値にデフォルトで設定されます。

以下が真の場合、CPUおよびメモリトリガーは`hpa`セクションで設定されたCPUおよびメモリしきい値に基づいて自動的に追加されます:

- `triggers`は設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定もゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの設定の詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  型   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | 最後のトリガーがアクティブを報告してから、リソースを0にスケールバックするまでの待機期間 |
| `minReplicaCount`               | 整数 | `minReplicas`                   | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `maxReplicaCount`               | 整数 | `maxReplicas`                   | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `fallback`                      |   マップ   |                                 | KEDAフォールバック設定。[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください。 |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | `ScaledObject`が削除された後、ターゲットリソースが元のレプリカ数にスケールバックされるべきかどうかを指定します。 |
| `behavior`                      |   マップ   | `hpa.behavior`                  | スケールアップおよびスケールダウン動作の仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケールをアクティブ化するトリガーのリスト。`hpa.cpu`と`hpa.memory`から計算されたトリガーにデフォルトで設定されます。 |
