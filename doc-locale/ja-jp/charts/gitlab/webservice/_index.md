---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Webserviceチャートの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

`webservice`サブチャートは、GitLab Railsウェブサーバーに、ポッドごとに2つのWebserviceワーカーを提供します。これは、単一のポッドがGitLabであらゆるWebリクエストを処理するために必要な最小限の数です。

このチャートのポッドは、`gitlab-workhorse`と`webservice`の2つのコンテナを使用します。[GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab/-/tree/master/workhorse)はポート`8181`でリッスンし、ポッドへの受信トラフィックの宛先は_常に_これでなければなりません。`webservice`はGitLabの[Railsコードベース](https://gitlab.com/gitlab-org/gitlab)を格納し、`8080`でリッスンし、メトリクスの収集を目的としてアクセスできます。`webservice`は、通常のトラフィックを直接受信しないでください。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされているKubernetesクラスターから到達可能な外部サービスとして、Redis、PostgreSQL、Gitaly、およびRegistryサービスに依存します。

## 設定 {#configuration}

`webservice`チャートは、次のように構成されています。[グローバル設定](#global-settings)、[デプロイメント設定](#deployments-settings)、[Ingress設定](#ingress-settings)、[外部サービス](#external-services)、[チャート設定](#chart-settings)。

## インストール コマンドライン オプション {#installation-command-line-options}

以下のテーブルには、`helm install`コマンドに`--set`フラグを使用して指定できる、可能なすべてのチャート構成が記載されています。

| パラメータ                                                     | デフォルト                                                         | 説明 |
|---------------------------------------------------------------|-----------------------------------------------------------------|-------------|
| `annotations`                                                 |                                                                 | Podアノテーション |
| `podLabels`                                                   |                                                                 | 補足的なPodラベル。セレクターには使用されません。 |
| `common.labels`                                               |                                                                 | このチャートによって作成されたすべてのオブジェクトに適用される補足的なラベル。 |
| `deployment.terminationGracePeriodSeconds`                    | `30`                                                            | Kubernetesがポッドの終了を待機する秒数。これは`shutdown.blackoutSeconds`よりも長くする必要があります。 |
| `deployment.livenessProbe.initialDelaySeconds`                | `20`                                                            | Livenessプローブが開始されるまでの遅延 |
| `deployment.livenessProbe.periodSeconds`                      | `60`                                                            | Livenessプローブの実行頻度 |
| `deployment.livenessProbe.timeoutSeconds`                     | `30`                                                            | Livenessプローブがタイムアウトするタイミング |
| `deployment.livenessProbe.successThreshold`                   | `1`                                                             | Livenessプローブが失敗後に成功したと見なされるための最小連続成功数 |
| `deployment.livenessProbe.failureThreshold`                   | `3`                                                             | Livenessプローブが成功後に失敗したと見なされるための最小連続失敗数 |
| `deployment.readinessProbe.initialDelaySeconds`               | `0`                                                             | Readinessプローブが開始されるまでの遅延 |
| `deployment.readinessProbe.periodSeconds`                     | `10`                                                            | Readinessプローブの実行頻度 |
| `deployment.readinessProbe.timeoutSeconds`                    | `2`                                                             | Readinessプローブがタイムアウトするタイミング |
| `deployment.readinessProbe.successThreshold`                  | `1`                                                             | Readinessプローブが失敗後に成功したと見なされるための最小連続成功数 |
| `deployment.readinessProbe.failureThreshold`                  | `3`                                                             | Readinessプローブが成功後に失敗したと見なされるための最小連続失敗数 |
| `deployment.strategy`                                         | `{}`                                                            | デプロイメントで使用されるアップデートストラテジーを構成できます。指定されていない場合、クラスターのデフォルトが使用されます。 |
| `enabled`                                                     | `true`                                                          | Webserviceが有効なフラグ |
| `extraContainers`                                             |                                                                 | 含めるコンテナのリストを含む複数行のリテラル スタイル文字列 |
| `extraInitContainers`                                         |                                                                 | 含める追加のinitコンテナのリスト |
| `extras.google_analytics_id`                                  | `nil`                                                           | フロントエンド用のGoogle Analytics ID |
| `extraVolumeMounts`                                           |                                                                 | 実行する追加ボリューム マウントのリスト |
| `extraVolumes`                                                |                                                                 | 作成する追加ボリュームのリスト |
| `extraEnv`                                                    |                                                                 | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                                |                                                                 | 公開する他のデータソースからの追加の環境変数のリスト |
| `gitlab.webservice.workhorse.image`                           | `registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ee`  | Workhorseイメージリポジトリ |
| `gitlab.webservice.workhorse.tag`                             |                                                                 | Workhorseイメージtag |
| `hpa.behavior`                                                | `{scaleDown: {stabilizationWindowSeconds: 300 }}`               | 動作には、スケールアップおよびスケールダウン動作の仕様が含まれています（`autoscaling/v2beta2`以上が必要です）。 |
| `hpa.customMetrics`                                           | `[]`                                                            | カスタムメトリクスには、必要なレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で構成された平均CPU使用率のデフォルトの使用をオーバーライドします）。 |
| `hpa.cpu.targetType`                                          | `AverageValue`                                                  | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.cpu.targetAverageValue`                                  | `1`                                                             | オートスケールCPUターゲット値を設定します。 |
| `hpa.cpu.targetAverageUtilization`                            |                                                                 | オートスケールCPUターゲット使用率を設定します。 |
| `hpa.memory.targetType`                                       |                                                                 | オートスケールメモリターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.memory.targetAverageValue`                               |                                                                 | オートスケールメモリターゲット値を設定します。 |
| `hpa.memory.targetAverageUtilization`                         |                                                                 | オートスケールメモリターゲット使用率を設定します。 |
| `hpa.targetAverageValue`                                      |                                                                 | **非推奨**オートスケールCPUターゲット値を設定します。 |
| `sshHostKeys.mount`                                           | `false`                                                         | 公開SSH鍵を含むGitLab Shellシークレットをマウントするかどうか。 |
| `sshHostKeys.mountName`                                       | `ssh-host-keys`                                                 | マウントされたボリュームの名前。 |
| `sshHostKeys.types`                                           | `[dsa,rsa,ecdsa,ed25519]`                                       | マウントするSSHキータイプのリスト。 |
| `image.pullPolicy`                                            | `Always`                                                        | Webserviceイメージのプルポリシー |
| `image.pullSecrets`                                           |                                                                 | イメージリポジトリのシークレット |
| `image.repository`                                            | `registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ee` | Webserviceイメージリポジトリ |
| `image.tag`                                                   |                                                                 | Webserviceイメージtag |
| `init.image.repository`                                       |                                                                 | initContainerイメージ |
| `init.image.tag`                                              |                                                                 | initContainerイメージtag |
| `init.containerSecurityContext.runAsUser`                     | `1000`                                                          | initContainer固有:コンテナを開始するユーザーID |
| `init.containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                         | initContainer固有:プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`                  | `true`                                                          | initContainer固有:コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                     | initContainer固有:コンテナの[Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `keda.enabled`                                                | `false`                                                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                        | `30`                                                            | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                                         | `300`                                                           | リソースを0にスケールバックする前に、最後のトリガーがアクティブであると報告されてから待機する期間 |
| `keda.minReplicaCount`                                        | `minReplicas`                                                   | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `keda.maxReplicaCount`                                        | `maxReplicas`                                                   | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `keda.fallback`                                               |                                                                 | KEDAフォールバック構成については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                                | `keda-hpa-{scaled-object-name}`                                 | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`                          |                                                                 | `ScaledObject`の削除後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                               | `hpa.behavior`                                                  | スケールアップおよびスケールダウン動作の仕様。 |
| `keda.triggers`                                               |                                                                 | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。`hpa.cpu`と`hpa.memory`から計算されたトリガーがデフォルトです |
| `metrics.enabled`                                             | `true`                                                          | メトリクス エンドポイントをスクレイピングに使用できるようにするかどうか |
| `metrics.port`                                                | `8083`                                                          | メトリクス エンドポイント ポート |
| `metrics.path`                                                | `/metrics`                                                      | メトリクス エンドポイント パス |
| `metrics.serviceMonitor.enabled`                              | `false`                                                         | Prometheus Operatorがメトリクス スクレイピングを管理できるようにするServiceMonitorを作成するかどうか。これを有効にすると、`prometheus.io`スクレイプ アノテーションが削除されることに注意してください |
| `metrics.serviceMonitor.additionalLabels`                     | `{}`                                                            | ServiceMonitorに追加する追加ラベル |
| `metrics.serviceMonitor.endpointConfig`                       | `{}`                                                            | ServiceMonitorの追加のエンドポイント構成 |
| `metrics.annotations`                                         |                                                                 | **非推奨**明示的なメトリクス アノテーションを設定します。テンプレート コンテンツに置き換えられました。 |
| `metrics.tls.enabled`                                         |                                                                 | メトリクス/web_exporterエンドポイントに対してTLSが有効。デフォルトは`tls.enabled`です。 |
| `metrics.tls.secretName`                                      |                                                                 | メトリクス/web_exporterエンドポイントTLS証明書とキーのシークレット。デフォルトは`tls.secretName`です。 |
| `minio.bucket`                                                | `git-lfs`                                                       | MinIOを使用する場合のストレージ バケットの名前 |
| `minio.port`                                                  | `9000`                                                          | MinIOサービスのポート |
| `minio.serviceName`                                           | `minio-svc`                                                     | MinIOサービスの名前 |
| `monitoring.ipWhitelist`                                      | `[0.0.0.0/0]`                                                   | モニタリング エンドポイントの許可リストに追加するIPのリスト |
| `monitoring.exporter.enabled`                                 | `false`                                                         | Prometheusメトリクスを公開するためにウェブサーバーを有効にします。メトリクス ポートがモニタリングexporterポートに設定されている場合、これは`metrics.enabled`によって上書きされます |
| `monitoring.exporter.port`                                    | `8083`                                                          | メトリクスexporterに使用するポート番号 |
| `psql.password.key`                                           | `psql-password`                                                 | psqlシークレットのpsqlパスワードへのキー |
| `psql.password.secret`                                        | `gitlab-postgres`                                               | psqlシークレット名 |
| `psql.port`                                                   |                                                                 | PostgreSQLサーバーポートを設定します。`global.psql.port`よりも優先されます |
| `puma.disableWorkerKiller`                                    | `true`                                                          | Puma workerメモリキラーを無効にします。 |
| `puma.workerMaxMemory`                                        |                                                                 | Puma workerキラーの最大メモリ（メガバイト単位） |
| `puma.threads.min`                                            | `4`                                                             | Pumaスレッドの最小量 |
| `puma.threads.max`                                            | `4`                                                             | Pumaスレッドの最大量 |
| `rack_attack.git_basic_auth`                                  | `{}`                                                            | 詳細については、[GitLabドキュメント](https://docs.gitlab.com/administration/settings/protected_paths/)を参照してください |
| `redis.serviceName`                                           | `redis`                                                         | Redisサービス名 |
| `global.registry.api.port`                                    | `5000`                                                          | レジストリポート |
| `global.registry.api.protocol`                                | `http`                                                          | レジストリプロトコル |
| `global.registry.api.serviceName`                             | `registry`                                                      | レジストリサービス名 |
| `global.registry.enabled`                                     | `true`                                                          | すべてのプロジェクトメニューでレジストリリンクを追加/削除します |
| `global.registry.tokenIssuer`                                 | `gitlab-issuer`                                                 | レジストリトークン発行者 |
| `replicaCount`                                                | `1`                                                             | Webserviceレプリカの数 |
| `resources.requests.cpu`                                      | `300m`                                                          | Webservice最小CPU |
| `resources.requests.memory`                                   | `1.5G`                                                          | Webservice最小メモリ |
| `service.externalPort`                                        | `8080`                                                          | Webservice公開ポート |
| `securityContext.fsGroup`                                     | `1000`                                                          | ポッドを開始するグループID |
| `securityContext.runAsUser`                                   | `1000`                                                          | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`                         |                                                                 | ボリュームの所有権と権限を変更するためのポリシー (Kubernetes 1.23が必要) |
| `securityContext.seccompProfile.type`                         | `RuntimeDefault`                                                | 使用するSeccompプロファイル |
| `containerSecurityContext`                                    |                                                                 | コンテナの開始に使用される[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `containerSecurityContext.runAsUser`                          | `1000`                                                          | コンテナの開始に使用される特定のセキュリティコンテキストユーザーIDの上書きを許可します |
| `containerSecurityContext.allowPrivilegeEscalation`           | `false`                                                         | Gitalyコンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                       | `true`                                                          | Gitalyコンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`                  | `[ "ALL" ]`                                                     | Gitalyコンテナの[Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.automountServiceAccountToken`                 | `false`                                                         | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                       | `false`                                                         | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                      | `false`                                                         | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                         |                                                                 | ServiceAccountの名前。設定しない場合、完全なチャート名が使用されます |
| `serviceLabels`                                               | `{}`                                                            | 補足的なサービスラベル |
| `service.internalPort`                                        | `8080`                                                          | Webservice内部ポート |
| `service.type`                                                | `ClusterIP`                                                     | Webserviceサービスタイプ |
| `service.workhorseExternalPort`                               | `8181`                                                          | Workhorse公開ポート |
| `service.workhorseInternalPort`                               | `8181`                                                          | Workhorse内部ポート |
| `service.loadBalancerIP`                                      |                                                                 | LoadBalancerに割り当てるIPアドレス（クラウドプロバイダーでサポートされている場合） |
| `service.loadBalancerSourceRanges`                            |                                                                 | LoadBalancerへのアクセスを許可されているIP CIDRのリスト（サポートされている場合）。service.type = LoadBalancerに必須 |
| `shell.authToken.key`                                         | `secret`                                                        | ShellシークレットのShellトークンへのキー |
| `shell.authToken.secret`                                      | `{Release.Name}-gitlab-shell-secret`                            | Shellトークンシークレット |
| `shell.port`                                                  | `nil`                                                           | UIによって生成されたSSH URLで使用するポート番号 |
| `shutdown.blackoutSeconds`                                    | `10`                                                            | シャットダウンの受信後にWebserviceを実行し続ける秒数。これは`deployment.terminationGracePeriodSeconds`よりも短くする必要があります |
| `tls.enabled`                                                 | `false`                                                         | Webservice TLSが有効 |
| `tls.secretName`                                              | `{Release.Name}-webservice-tls`                                 | Webservice TLSシークレット。`secretName`は[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を指している必要があります。 |
| `tolerations`                                                 | `[]`                                                            | ポッド割り当ての容認ラベル |
| `trusted_proxies`                                             | `[]`                                                            | 詳細については、[GitLabドキュメント](https://docs.gitlab.com/install/installation/#adding-your-trusted-proxies)を参照してください |
| `workhorse.logFormat`                                         | `json`                                                          | ログ形式。有効な形式：`json`、`structured`、`text` |
| `workerProcesses`                                             | `2`                                                             | Webserviceワーカーの数 |
| `workhorse.keywatcher`                                        | `true`                                                          | RedisにWorkhorseをサブスクライブします。これは`/api/*`へのリクエストを処理するあらゆるデプロイメントで**必須**ですが、他のデプロイメントでは安全に無効にできます |
| `workhorse.shutdownTimeout`                                   | `global.webservice.workerTimeout + 1`（秒）                 | すべてのWebリクエストがWorkhorseからクリアされるまで待機する時間。例：`1min`、`65s`。 |
| `workhorse.trustedCIDRsForPropagation`                        |                                                                 | 相関IDの伝播を信頼できるCIDRブロックのリスト。これが機能するには、`workhorse.extraArgs`でも`-propagateCorrelationID`オプションを使用する必要があります。詳細については、[Workhorseドキュメント](https://docs.gitlab.com/development/workhorse/configuration/#propagate-correlation-ids)を参照してください。 |
| `workhorse.trustedCIDRsForXForwardedFor`                      |                                                                 | `X-Forwarded-For` HTTPヘッダーを介して実際のクライアントIPを解決するために使用できるCIDRブロックのリスト。これは`workhorse.trustedCIDRsForPropagation`で使用されます。詳細については、[Workhorseドキュメント](https://docs.gitlab.com/development/workhorse/configuration/#trusted-proxies)を参照してください。 |
| `workhorse.metadata.zipReaderLimitBytes`                      |                                                                 | zipリーダーを制限するオプションのバイト数。GitLab 16.9で導入されました。詳細については、[Workhorseドキュメント](https://docs.gitlab.com/development/workhorse/configuration/#metadata-options)を参照してください。 |
| `workhorse.containerSecurityContext`                          |                                                                 | コンテナの開始に使用される[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `workhorse.containerSecurityContext.runAsUser`                | `1000`                                                          | コンテナを開始するユーザーID |
| `workhorse.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                         | コンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `workhorse.containerSecurityContext.runAsNonRoot`             | `true`                                                          | コンテナを非rootユーザーで実行するかどうかを制御します |
| `workhorse.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                     | Gitalyコンテナの[Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `workhorse.livenessProbe.initialDelaySeconds`                 | `20`                                                            | Livenessプローブが開始されるまでの遅延 |
| `workhorse.livenessProbe.periodSeconds`                       | `60`                                                            | Livenessプローブの実行頻度 |
| `workhorse.livenessProbe.timeoutSeconds`                      | `30`                                                            | Livenessプローブがタイムアウトするタイミング |
| `workhorse.livenessProbe.successThreshold`                    | `1`                                                             | Livenessプローブが失敗後に成功したと見なされるための最小連続成功数 |
| `workhorse.livenessProbe.failureThreshold`                    | `3`                                                             | Livenessプローブが成功後に失敗したと見なされるための最小連続失敗数 |
| `workhorse.monitoring.exporter.enabled`                       | `false`                                                         | Prometheusメトリクスを公開するためにworkhorseを有効にします。これは`workhorse.metrics.enabled`によってオーバーライドされます |
| `workhorse.monitoring.exporter.port`                          | `9229`                                                          | workhorse Prometheusメトリクスに使用するポート番号 |
| `workhorse.monitoring.exporter.tls.enabled`                   | `false`                                                         | `true`に設定すると、メトリクス エンドポイントでTLSが有効になります。[WorkhorseでTLSが有効になっている](#gitlab-workhorse)必要があります。 |
| `workhorse.metrics.enabled`                                   | `true`                                                          | workhorseメトリクス エンドポイントをスクレイピングに使用できるようにするかどうか |
| `workhorse.metrics.port`                                      | `8083`                                                          | Workhorseメトリクス エンドポイントポート |
| `workhorse.metrics.path`                                      | `/metrics`                                                      | Workhorseメトリクス エンドポイントパス |
| `workhorse.metrics.serviceMonitor.enabled`                    | `false`                                                         | Prometheus OperatorがWorkhorseメトリクス スクレイピングを管理できるようにするServiceMonitorを作成するかどうか |
| `workhorse.metrics.serviceMonitor.additionalLabels`           | `{}`                                                            | Workhorse ServiceMonitorに追加する追加ラベル |
| `workhorse.metrics.serviceMonitor.endpointConfig`             | `{}`                                                            | Workhorse ServiceMonitorの追加のエンドポイント構成 |
| `workhorse.readinessProbe.initialDelaySeconds`                | `0`                                                             | Readinessプローブが開始されるまでの遅延 |
| `workhorse.readinessProbe.periodSeconds`                      | `10`                                                            | Readinessプローブの実行頻度 |
| `workhorse.readinessProbe.timeoutSeconds`                     | `2`                                                             | Readinessプローブがタイムアウトするタイミング |
| `workhorse.readinessProbe.successThreshold`                   | `1`                                                             | Readinessプローブが失敗後に成功したと見なされるための最小連続成功数 |
| `workhorse.readinessProbe.failureThreshold`                   | `3`                                                             | Readinessプローブが成功後に失敗したと見なされるための最小連続失敗数 |
| `workhorse.imageScaler.maxProcs`                              | `2`                                                             | 同時に実行できるイメージスケーリングプロセスの最大数 |
| `workhorse.imageScaler.maxFileSizeBytes`                      | `250000`                                                        | スケーラーで処理されるイメージの最大ファイルサイズ（バイト単位） |
| `workhorse.tls.verify`                                        | `true`                                                          | `true`に設定すると、NGINX IngressはWorkhorseのTLS証明書を強制的に検証します。カスタムCAの場合は、`workhorse.tls.caSecretName`も設定する必要があります。自己署名証明書の場合は、`false`に設定する必要があります。 |
| `workhorse.tls.secretName`                                    | `{Release.Name}-workhorse-tls`                                  | TLSキーと証明書のペアを含む[TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)の名前。これは、Workhorse TLSが有効な場合に必要です。 |
| `workhorse.tls.caSecretName`                                  |                                                                 | CA証明書を含むシークレットの名前。これは**TLSシークレット** [ではありません](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)。キー`ca.crt`のみが必要です。これは、NGINXがWorkhorseのTLS証明書を検証するために使用されます。 |
| `webServer`                                                   | `puma`                                                          | リクエストの処理に使用されるWebサーバー(Webservice/Puma)を選択します |
| `priorityClassName`                                           | `""`                                                            | ポッド`priorityClassName`の設定を許可します。これは、削除の場合にポッドの優先度を制御するために使用されます |

## チャート構成の例 {#chart-configuration-examples}

### `extraEnv` {#extraenv}

`extraEnv`を使用すると、ポッド内のすべてのコンテナに追加の環境変数を公開できます。

以下は、`extraEnv`の使用例です。

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

コンテナが起動されると、環境変数が公開されていることを確認できます。

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

### `extraEnvFrom` {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナで、他のデータソースからの追加の環境変数を公開できます。後続の変数は、[デプロイメント](#deployments-settings)ごとにオーバーライドできます。

以下は、`extraEnvFrom`の使用例です。

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

`pullSecrets`を使用すると、プライベートレジストリに対して認証を行い、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法の詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)を参照してください。

以下は、`pullSecrets`の使用例です。

```yaml
image:
  repository: my.webservice.repository
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
| `automountServiceAccountToken` | ブール | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。特定のサイドカーが適切に機能するために必要でない限り（たとえば、Istio）、これを有効にしないでください。 |
| `create`                       | ブール | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | Boolean | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | String  |         | ServiceAccountの名前。設定されていない場合、完全なチャート名が使用されます。 |

### `tolerations` {#tolerations}

`tolerations`を使用すると、taintされたワーカーノードでポッドをスケジュールできます

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

### `annotations` {#annotations}

`annotations`を使用すると、Webserviceポッドにアノテーションを追加できます。次に例を示します。

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### `strategy` {#strategy}

`deployment.strategy`を使用すると、デプロイの更新ストラテジーを変更できます。これは、デプロイが更新されたときにポッドがどのように再作成されるかを定義します。指定されていない場合、クラスターのデフォルトが使用されます。たとえば、ローリングアップデートの開始時に追加のポッドを作成せず、利用不可ポッドの最大数を50% に変更する場合は、次のようにします。

```yaml
deployment:
  strategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 50%
```

更新ストラテジーのタイプを`Recreate`に変更することもできますが、新しいポッドのスケジュール前にすべてのポッドが強制終了されるため、注意が必要です。新しいポッドが開始されるまで、Web UIは使用できません。この場合、`rollingUpdate`を定義する必要はなく、`type`のみを定義します。

```yaml
deployment:
  strategy:
    type: Recreate
```

詳細については、[Kubernetes](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)ドキュメントを参照してください。

### TLS {#tls}

Webserviceポッドは2つのコンテナを実行します。

- `gitlab-workhorse`
- `webservice`

#### `gitlab-workhorse` {#gitlab-workhorse}

Workhorseは、Webとメトリクスエンドポイントの両方でTLSをサポートします。これにより、Workhorseと他のコンポーネント（特に`nginx-ingress`、`gitlab-shell`、および`gitaly`）間の通信が保護されます。TLS証明書には、共通名 (CN) またはサブジェクト代替名 (SAN) にWorkhorseサービス ホスト名 (例: `RELEASE-webservice-default.default.svc`) を含める必要があります。

[Webserviceの複数のデプロイ](#deployments-settings)が存在する可能性があるため、異なるサービス名に対してTLS証明書を準備する必要があります。これは、複数のSANまたはワイルドカード証明書のいずれかによって実現できます。

TLS証明書が生成されたら、その証明書の[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を作成します。また、`ca.crt`キーを使用して、TLS証明書のCA証明書のみを含む別のシークレットを作成する必要があります。

`global.workhorse.tls.enabled`を`true`に設定すると、`gitlab-workhorse`コンテナに対してTLSを有効にできます。必要に応じて、カスタムシークレット名を`gitlab.webservice.workhorse.tls.secretName`および`global.certificates.customCAs`にパスできます。

`gitlab.webservice.workhorse.tls.verify`が`true` (これはデフォルトです) の場合、CA証明書のシークレット名を`gitlab.webservice.workhorse.tls.caSecretName`にもパスする必要があります。これは、自己署名証明書とカスタムCAに必要です。このシークレットは、NGINXがWorkhorseのTLS証明書を検証するために使用します。

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

`gitlab-workhorse`コンテナのメトリクスエンドポイントのTLSは、`global.workhorse.tls.enabled`から継承されます。メトリクスエンドポイントのTLSは、Workhorseに対してTLSが有効になっている場合にのみ使用できます。メトリクスリスナーは、`gitlab.webservice.workhorse.tls.secretName`で指定されたものと同じTLS証明書を使用します。

メトリクスエンドポイントに使用されるTLS証明書では、特に含まれているPrometheus Helm ChartChart>を使用している場合に、含まれているサブジェクトの代替名 (SAN) について追加の考慮事項が必要になる場合があります。詳細については、[TLSが有効なエンドポイントをスクレイピングするようにPrometheusを設定する](../../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints)を参照してください。

#### `webservice` {#webservice}

TLSを有効にする主なユースケースcase>は、[Prometheusメトリクスをスクレイピング](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/)するためにHTTPS経由で暗号化を提供することです。

PrometheusがHTTPSを使用して`/metrics/`エンドポイントをスクレイピングするには、証明書の`CommonName`属性または`SubjectAlternativeName`エントリの追加設定が必要です。これらの要件については、[TLSが有効なエンドポイントをスクレイピングするようにPrometheusを設定する](../../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints)を参照してください。

`gitlab.webservice.tls.enabled`設定により、`webservice`コンテナでTLSを有効にできます。

```yaml
gitlab:
  webservice:
    tls:
      enabled: true
      # secretName: gitlab-webservice-tls
```

`secretName`は、[Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)を指すto>必要があります。たとえば、ローカル証明書とキーを使用してTLSシークレットを作成するには、次のようにします。

```shell
kubectl create secret tls <secret name> --cert=path/to/puma.crt --key=path/to/puma.key
```

## このチャートのCommunity Editionの使用 {#using-the-community-edition-of-this-chart}

デフォルトでは、Helm ChartChart>はGitLab Enterprise EditionEdition> を使用します。必要に応じて、代わりにCommunity Editionを使用できます。[2つの違い](https://about.gitlab.com/install/ce-or-ee/)について詳しく見てください。

Community Editionを使用するには、`image.repository`を`registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ce`に、`workhorse.image`を`registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ce`に設定します。

## グローバル設定 {#global-settings}

チャート間でいくつかの一般的なグローバル設定を共有します。GitLabやレジストリのホスト名など、一般的な設定オプションについては、[グローバルドキュメント](../../globals.md)を参照してください。

## デプロイ設定 {#deployments-settings}

このチャートには、複数のデプロイオブジェクトとそれらに関連するリソースを作成する機能があります。この機能により、パスベースのルーティングを使用して、複数のポッドセット間でGitLabアプリケーションへのリクエストを分散型できます。

このマップのキー（この例では`default`）は、それぞれの「名前」です。`default`には、`RELEASE-webservice-default`で作成されたデプロイ、サービス、HorizontalPodAutoscaler、PodDisruptionBudget、およびオプションのIngressがあります。

指定されていないプロパティは、`gitlab-webservice`チャートのデフォルトから継承されます。

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
```

### デプロイIngress {#deployments-ingress}

各`deployments`エントリは、チャート全体の[Ingress設定](#ingress-settings)から継承されます。ここに表示される値は、そこに指定された値をオーバーライドします。`path`を除き、すべての設定はそれらと同じです。

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

`path`プロパティはIngressの`path`プロパティに直接入力されたもので、各サービスに向けられたURIパスを制御できます。上記の例では、`default`はキャッチオールパスとして機能し、`api`は`/api`の下のすべてのトラフィックを受信しました

`path`を空に設定すると、特定のデプロイに関連付けられたIngressリソースが作成されなくなります。以下を参照してください。`internal-api`は外部トラフィックを受信しません。

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

| 名前                              |  タイプ   | デフォルト                   | 説明 |
|:----------------------------------|:-------:|:--------------------------|:------------|
| `ingress.apiVersion`              | String  |                           | `apiVersion`フィールドで使用する値。 |
| `ingress.annotations`             |   Map   | [以下](#annotations)を参照してください。 | これらのアノテーションは、すべてのIngressに使用されます。次に例を示します。`ingress.annotations."nginx\.ingress\.kubernetes\.io/enable-access-log"=true`。 |
| `ingress.configureCertmanager`    | Boolean |                           | Ingressアノテーション`cert-manager.io/issuer`および`acme.cert-manager.io/http01-edit-in-place`を切り替えます。詳細については、[GitLab PagesのTLS要件](../../../installation/tls.md)を参照してください。 |
| `ingress.enabled`                 | Boolean | `false`                   | それらをサポートするサービスのIngressオブジェクトを作成するかどうかを制御する設定。`false`の場合、`global.ingress.enabled`設定 値が使用されます。 |
| `ingress.proxyBodySize`           | String  | `512m`                    | [以下](#proxybodysize)を参照してください。 |
| `ingress.serviceUpstream`         | Boolean | `true`                    | [以下](#serviceupstream)を参照してください。 |
| `ingress.tls.enabled`             | Boolean | `true`                    | `false`に設定すると、GitLab WebserviceのTLSが無効になります。これは、Ingressコントローラーの前にTLS終端プロキシがある場合のように、IngressレベルでTLS終端を使用できない場合に特に役立ちます。 |
| `ingress.tls.secretName`          | String  | （空）                   | GitLab URLの有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定されていない場合、代わりに`global.ingress.tls.secretName`値が使用されます。 |
| `ingress.tls.smardcardSecretName` | String  | （空）                   | 有効になっている場合、GitLabスマートカードURLの有効な証明書とキーを含むKubernetes TLS SEcretの名前。設定されていない場合、代わりに`global.ingress.tls.secretName`値が使用されます。 |
| `ingress.tls.useGeoClass`         | Boolean | `false`                   | IngressClassをGeo Ingressクラス (`global.geo.ingressClass`) でオーバーライドします。プライマリGeoサイトに必要です。 |

### アノテーション {#annotations-1}

`annotations`は、Webservice Ingressにアノテーションを設定するために使用されます。

### `serviceUpstream` {#serviceupstream}

これにより、NGINXにアップストリームとしてサービス自体に直接接続するように指示することで、Webserviceポッドへのトラフィックをより均等に分散させることができます。詳細については、[NGINXドキュメント](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md#service-upstream)を参照してください。

これをオーバーライドするには、次のように設定します。

```yaml
gitlab:
  webservice:
    ingress:
      serviceUpstream: "false"
```

### `proxyBodySize` {#proxybodysize}

`proxyBodySize`は、NGINXプロキシの最大本文サイズを設定するために使用されます。これは通常、デフォルトよりも大きいDockerイメージを許可するために必要です。これは、[Linuxパッケージインストール](https://docs.gitlab.com/omnibus/settings/nginx/#use-an-existing-passenger-and-nginx-installation)の`nginx['client_max_body_size']`設定と同等です。代替オプションとして、次の2つのパラメータのいずれかを使用して本文サイズを設定することもできます。

- `gitlab.webservice.ingress.annotations."nginx\.ingress\.kubernetes\.io/proxy-body-size"`
- `global.ingress.annotations."nginx\.ingress\.kubernetes\.io/proxy-body-size"`

### 追加のIngress {#extra-ingress}

`extraIngress.enabled=true`を設定すると、追加のIngressをデプロイできます。Ingressは、`-extra`サフィックスが付いたデフォルトのIngressとして名前が付けられ、デフォルトのIngressと同じ設定をサポートします。

## リソース {#resources}

### メモリリクエスト/制限 {#memory-requestslimits}

各ポッドは`workerProcesses`と同じ数の作業者を起動するため、各作業者がある程度のベースラインメモリを使用します。推奨事項：

- 作業者あたり最小1.25 GB (`requests.memory`)
- 作業者あたり最大1.5 GB、さらにプライマリ用に1 GB (`limits.memory`)

必要なリソースは、ユーザーによって生成されるワークロードに依存し、GitLabアプリケーションの変更またはアップグレードに基づいて将来変更される可能性があることに注意してください。

デフォルト：

```yaml
workerProcesses: 2
resources:
  requests:
    memory: 2.5G # = 2 * 1.25G
# limits:
#   memory: 4G   # = (2 * 1.5G) + 950M
```

4人の作業者が設定されている場合：

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

Redisドキュメントは、[グローバル](../../globals.md#configure-redis-settings)ページに統合されています。最新のRedis設定オプションについては、このページを参照してください。

### PostgreSQL {#postgresql}

PostgreSQLドキュメントは、[グローバル](../../globals.md#configure-postgresql-settings)ページに統合されています。最新のPostgreSQL設定オプションについては、このページを参照してください。

### Gitaly {#gitaly}

Gitalyは[グローバル設定](../../globals.md)によって設定されます。[Gitaly設定ドキュメント](../../globals.md#configure-gitaly-settings)を参照してください。

### MinIO {#minio}

```yaml
minio:
  serviceName: 'minio-svc'
  port: 9000
```

| 名前          |  タイプ   | デフォルト     | 説明 |
|:--------------|:-------:|:------------|:------------|
| `port`        | Integer | `9000`      | MinIO `Service`に到達するためのポート番号。 |
| `serviceName` | String  | `minio-svc` | MinIOポッドによって公開される`Service`の名前。 |

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

| 名前                 |  タイプ   | デフォルト         | 説明 |
|:---------------------|:-------:|:----------------|:------------|
| `api.host`           | String  |                 | 使用するレジストリサーバーのホスト名。これは、`api.serviceName`の代わりに省略できます。 |
| `api.port`           | Integer | `5000`          | レジストリAPIへの接続に使用するポート。 |
| `api.protocol`       | String  |                 | Webserviceが レジストリAPIに到達するために使用する必要があるプロトコル。 |
| `api.serviceName`    | String  | `registry`      | レジストリサーバーを操作している`service`の名前。これが存在し、`api.host`が存在しない場合、チャートはサービスのホスト名 (および現在の`.Release.Name`) を`api.host`値の代わりにテンプレート化します。これは、GitLabチャート全体の一部としてレジストリを使用する場合に便利です。 |
| `certificate.key`    | String  |                 | `auth.token.rootcertbundle`として[registry](https://hub.docker.com/_/registry/)コンテナに提供される証明書バンドルを格納する`Secret`の`key`の名前。 |
| `certificate.secret` | String  |                 | GitLabインスタンスによって作成されたトークンを検証するために使用される証明書バンドルを格納する[Kubernetesシークレット](https://kubernetes.io/docs/concepts/configuration/secret/)の名前。 |
| `host`               | String  |                 | GitLab UIでDockerコマンドをユーザーに提供するために使用する外部ホスト名。`registry.hostname`テンプレートで設定された値にフォールバックします。これにより、`global.hosts`で設定された値に基づいてレジストリのホスト名が決定されます。詳細については、[グローバルドキュメント](../../globals.md)を参照してください。 |
| `port`               | Integer |                 | ホスト名で使用される外部ポート。ポート`80`または`443`を使用すると、URLが`http`/`https`で形成されます。他のすべてのポートは`http`を使用し、ホスト名の最後にポートを付加します (例: `http://registry.example.com:8443`)。 |
| `tokenIssuer`        | String  | `gitlab-issuer` | 認証トークン発行者の名前。これは、送信時にトークンに組み込まれるため、レジストリの設定で使用されている名前と一致する必要があります。デフォルトの`gitlab-issuer`は、レジストリチャートで使用しているデフォルトと同じです。 |

## チャート設定 {#chart-settings}

次の値は、Webserviceポッドを設定するために使用されます。

| 名前              |  タイプ   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `workerProcesses` | Integer | `2`     | ポッドごとに実行するWebservice作業者の数。GitLabが適切に機能するためには、クラスターで使用可能な作業者が少なくとも`2`人必要です。`workerProcesses`を増やすと、作業者1人あたり約`400MB`ずつ必要なメモリが増加するため、それに応じてポッドの`resources`を更新する必要があります。 |
| `minReplicas`     | Integer | `2`     | レプリカの最小数 |
| `maxReplicas`     | Integer | `10`    | レプリカの最大数 |
| `maxUnavailable`  | Integer | `1`     | 利用できなくなるポッドの最大数の制限 |

### メトリクス {#metrics}

`metrics.enabled`の値を有効にすると、GitLabを使用して ポートを公開できます。ポッドにはPrometheusアノテーションが付与されるか、`metrics.serviceMonitor.enabled`が`true`の場合、Prometheus Operator ServiceMonitorが作成されます。メトリクスは`/-/metrics`エンドポイントから代替的にスクレイピングできますが、これには[GitLab Prometheusメトリクス](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/)が管理者エリアで有効になっている必要があります。GitLab Workhorseは`workhorse.metrics.enabled`経由で公開することもできますが、Prometheusアノテーションを使用して収集することはできないため、`workhorse.metrics.serviceMonitor.enabled`を`true`にするか、外部Prometheusが必要になります。

### GitLab Shell {#gitlab-shell}

GitLab Shellは、Webserviceとの通信で認証を使用します。共有を使用して、をGitLab ShellおよびWebserviceと共有します。

```yaml
shell:
  authToken:
    secret: gitlab-shell-secret
    key: secret
  port:
```

| 名前               |  種類   |  | 説明 |
|:-------------------|:-------:|:--------|:------------|
| `authToken.key`    | 文字列  |         | 認証を含む (下記) のキーの名前を定義します。 |
| `authToken.secret` | 文字列  |         | プル元のKubernetes `Secret`の名前を定義します。 |
| `port`             | 整数 | `22`    | GitLab UI内でSSH URLの生成に使用する番号。`global.shell.port`によって制御されます。 |

### WebServerオプション {#webserver-options}

現在ののは、Puma Webサーバーをします。

Puma固有のオプション:

| 名前                   |  種類   |  | 説明 |
|:-----------------------|:-------:|:--------|:------------|
| `puma.workerMaxMemory` | 整数 |         | Puma  killerの最大メモリ (メガバイト単位) |
| `puma.threads.min`     | 整数 | `4`     | Pumaの最小量 |
| `puma.threads.max`     | 整数 | `4`     | Pumaの最大量 |

## `networkpolicy` {#configuring-the-networkpolicy}の

このセクションでは、[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を制御します。このはオプションであり、特定のに対するポッドのとを制限するために使用されます。

| 名前              |  種類   |  | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | このは、`NetworkPolicy`を有効にします |
| `ingress.enabled` | ブール値 | `false` | `true`に設定すると、`Ingress`ポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべての接続がされます。 |
| `ingress.rules`   |  配列  | `[]`    | ポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください |
| `egress.enabled`  | ブール値 | `false` | `true`に設定すると、`Egress`ポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべての接続がされます。 |
| `egress.rules`    |  配列  | `[]`    | ポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください |

### ネットワークポリシーの例 {#example-network-policy}

webserviceサービスでは、有効になっている場合、Prometheusの接続、NGINXおよびいくつかのGitLabからのトラフィックが必要です。通常、さまざまな場所への接続が必要です。この例では、次のネットワークポリシーを追加します。

-  を許可:
  - `gitaly`、`gitlab-pages`、`gitlab-shell`、`kas`、`mailroom`、および`nginx-ingress`のから`8181`へのを許可
  - `Prometheus`から`8080`、`8083`、および`9229`へのを許可
-  を許可:
  - `gitaly`から`8075`への
  - `kas`から`8153`への
  - `kube-dns`から`53`への
  - `registry`から`5000`への
  - 外部データベース`172.16.0.10/32`から`5432`への
  - 外部Redis `172.16.0.11/32`から`6379`への
  - インターネット`0.0.0.0/0`から`443`へ
  - S3または  のAWSのようなから`443`への`172.16.1.0/24`

_提供されている例は単なる例であり、完全ではない可能性があることに注意してください_

_Webserviceには、[外部オブジェクトストレージ](../../../advanced/external-object-storage)のイメージに対するパブリックインターネットへのアウトバウンド接続が必要であることに注意してください_

この例は、`kube-dns`が`kube-system`にデプロイされ、`prometheus`が`monitoring`にデプロイされ、`nginx-ingress`が`nginx-ingress`にデプロイされたという前提に基づいています。

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

`service.type`が`LoadBalancer`に設定されている場合、オプションで`service.loadBalancerIP`を指定して、ユーザー指定のIPで`LoadBalancer`を作成できます (クラウドプロバイダーがしている場合)。

`service.type`が`LoadBalancer`に設定されている場合、`LoadBalancer`にアクセスできる  範囲を制限するには、`service.loadBalancerSourceRanges`も設定する必要があります (クラウドプロバイダーがしている場合)。これは現在、[  が公開されている](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2500)問題が原因で必要です。

`LoadBalancer`サービスタイプの詳細については、[ Kubernetesドキュメント](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)を参照してください

```yaml
service:
  type: LoadBalancer
  loadBalancerIP: 1.2.3.4
  loadBalancerSourceRanges:
  - 10.0.0.0/8
```

## KEDAの設定 {#configuring-keda}

この`keda`セクションでは、標準の`HorizontalPodAutoscalers`の代わりに、[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。このはオプションであり、カスタムまたは外部に基づいてオートスケールする必要がある場合に使用できます。

ほとんどのは、該当する場合、`hpa`セクションで設定された値に設定されます。

以下がtrueの場合、CPUとメモリのトリガーは、`hpa`セクションで設定されたCPUとメモリのしきい値に基づいて自動的に追加されます。

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`もゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらのの詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  種類   |                          | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーで確認する間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | 最後トリガーがアクティブと報告されてから、リソースを0にスケールバックするまで待機する期間 |
| `minReplicaCount`               | 整数 | `minReplicas`                   | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `maxReplicaCount`               | 整数 | `maxReplicas`                   | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `fallback`                      |   マップ   |                                 | KEDAの[フォールバック](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)の設定については、ドキュメントを参照してください |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | ターゲットリソースを、`ScaledObject`が削除された後、元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   | `hpa.behavior`                  | アップスケーリングとダウンスケーリングの仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。`hpa.cpu`および`hpa.memory`からコンピュートされたトリガーにデフォルト設定されています |
