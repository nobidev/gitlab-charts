---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Pagesチャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供: GitLab Self-Managed

{{< /details >}}

`gitlab-pages`サブチャートは、GitLabプロジェクトから静的ウェブサイトを提供するためのデーモンを提供します。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされているKubernetesクラスターから到達可能な外部サービスとして提供される、Workhorseサービスへのアクセスに依存します。

## 設定 {#configuration}

`gitlab-pages`チャートは次のように構成されています: [グローバル設定](#global-settings)および[チャート設定](#chart-settings)。

## グローバル設定 {#global-settings}

いくつかの一般的なグローバル設定をチャート間で共有します。詳細については、[グローバルドキュメント](../../globals.md#configure-gitlab-pages)を参照してください。

## チャート設定 {#chart-settings}

次の2つのセクションのテーブルには、`helm install`コマンドに`--set`フラグを使用して指定できる、可能なすべてのチャート設定が含まれています。

### 一般設定 {#general-settings}

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                    | Pod割り当ての[アフィニティルール](../_index.md#affinity) |
| `annotations`                                            |                                                         | Podアノテーション |
| `common.labels`                                          | `{}`                                                    | このチャートで作成されたすべてのオブジェクトに適用される追加のラベル。 |
| `deployment.strategy`                                    | `{}`                                                    | デプロイで使用される更新戦略を構成できます。指定しない場合、クラスターのデフォルトが使用されます。 |
| `extraEnv`                                               |                                                         | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                         | 公開する他のデータソースからの追加の環境変数のリスト |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`       | Behaviorには、アップスケーリングとダウンスケーリングの動作の`autoscaling/v2beta2`以上が必要です。 |
| `hpa.customMetrics`                                      | `[]`                                                    | カスタムメトリクスには、必要なレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で設定された平均CPU使用率のデフォルトの使用をオーバーライドします）。 |
| `hpa.cpu.targetType`                                     | `AverageValue`                                          | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`                             | `100m`                                                  | オートスケールCPUターゲットを設定します |
| `hpa.cpu.targetAverageUtilization`                       |                                                         | オートスケールCPUターゲット使用率を設定します |
| `hpa.memory.targetType`                                  |                                                         | オートスケールメモリーターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`                          |                                                         | オートスケールメモリーターゲットを設定します |
| `hpa.memory.targetAverageUtilization`                    |                                                         | オートスケールメモリーターゲット使用率を設定します |
| `hpa.minReplicas`                                        | `1`                                                     | レプリカの最小数 |
| `hpa.maxReplicas`                                        | `10`                                                    | レプリカの最大数 |
| `hpa.targetAverageValue`                                 |                                                         | **非推奨**オートスケールCPUターゲットを設定します |
| `image.pullPolicy`                                       | `IfNotPresent`                                          | GitLabイメージプルポリシー |
| `image.pullSecrets`                                      |                                                         | イメージリポジトリのシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-pages` | GitLab Pagesイメージリポジトリ |
| `image.tag`                                              |                                                         | イメージtag   |
| `init.image.repository`                                  |                                                         | initContainerイメージ |
| `init.image.tag`                                         |                                                         | initContainerイメージtag |
| `init.containerSecurityContext`                          |                                                         | initContainer固有の[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                 | initContainer固有:プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                  | initContainer固有:コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                             | initContainer固有:コンテナの[Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `keda.enabled`                                           | `false`                                                 | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                   | `30`                                                    | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                                    | `300`                                                   | リソースを0にスケールバックする前に、最後のトリガーがアクティブと報告されてから待機する期間 |
| `keda.minReplicaCount`                                   | `hpa.minReplicas`                                       | KEDAがリソースをスケールダウンするレプリカの最小数。 |
| `keda.maxReplicaCount`                                   | `hpa.maxReplicas`                                       | KEDAがリソースをスケールアップするレプリカの最大数。 |
| `keda.fallback`                                          |                                                         | KEDAフォールバック構成については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                         | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`                     |                                                         | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                          | `hpa.behavior`                                          | アップスケーリングとダウンスケーリングの動作の。 |
| `keda.triggers`                                          |                                                         | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。デフォルトは`hpa.cpu`および`hpa.memory`から計算されたトリガーです |
| `metrics.enabled`                                        | `true`                                                  | メトリクスエンドポイントをスクレイピングに使用できるようにするかどうか |
| `metrics.port`                                           | `9235`                                                  | メトリクスエンドポイントポート |
| `metrics.path`                                           | `/metrics`                                              | メトリクスエンドポイントパス |
| `metrics.serviceMonitor.enabled`                         | `false`                                                 | Prometheus Operatorがメトリクスのスクレイピングを管理できるようにServiceMonitorを作成するかどうか。これを有効にすると、`prometheus.io`スクレイプアノテーションが削除されることに注意してください |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                    | ServiceMonitorに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                    | ServiceMonitorの追加のエンドポイント構成 |
| `metrics.annotations`                                    |                                                         | **非推奨**明示的なメトリクスアノテーションを設定します。テンプレートコンテンツに置き換えられました。 |
| `metrics.tls.enabled`                                    | `false`                                                 | メトリクスエンドポイントに対してTLSが有効 |
| `metrics.tls.secretName`                                 | `{Release.Name}-pages-metrics-tls`                      | メトリクスエンドポイントTLS証明書とキーのシークレット |
| `priorityClassName`                                      |                                                         | Podに割り当てられた[優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |
| `podLabels`                                              |                                                         | 補足Podラベル。セレクターには使用されません。 |
| `resources.requests.cpu`                                 | `900m`                                                  | GitLab Pagesの最小CPU |
| `resources.requests.memory`                              | `2G`                                                    | GitLab Pagesの最小メモリ |
| `securityContext.fsGroup`                                | `1000`                                                  | Podを開始するグループID |
| `securityContext.runAsUser`                              | `1000`                                                  | Podを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                                         | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                        | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                         | コンテナが開始される[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `containerSecurityContext.runAsUser`                     | `1000`                                                  | コンテナが開始される特定のセキュリティコンテキストユーザーIDの上書きを許可 |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                 | コンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                  | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                             | Gitalyコンテナの[Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `service.externalPort`                                   | `8090`                                                  | GitLab Pagesの公開ポート |
| `service.internalPort`                                   | `8090`                                                  | GitLab Pagesの内部ポート |
| `service.name`                                           | `gitlab-pages`                                          | GitLab Pagesサービス名 |
| `service.annotations`                                    |                                                         | すべてのPagesサービスのアノテーション。 |
| `service.primary.annotations`                            |                                                         | プライマリサービスのみのアノテーション。 |
| `service.metrics.annotations`                            |                                                         | メトリクスサービスのみのアノテーション。 |
| `service.customDomains.annotations`                      |                                                         | カスタムドメインサービスのみのアノテーション。 |
| `service.customDomains.type`                             | `LoadBalancer`                                          | カスタムドメインを処理するために作成されたサービスの種類 |
| `service.customDomains.internalHttpsPort`                | `8091`                                                  | PagesデーモンがHTTPSリクエストをリッスンするポート |
| `service.customDomains.internalHttpsPort`                | `8091`                                                  | PagesデーモンがHTTPSリクエストをリッスンするポート |
| `service.customDomains.nodePort.http`                    |                                                         | HTTP接続用に開かれるノードポート。`service.customDomains.type`が`NodePort`の場合にのみ有効 |
| `service.customDomains.nodePort.https`                   |                                                         | HTTPS接続用に開かれるノードポート。`service.customDomains.type`が`NodePort`の場合にのみ有効 |
| `service.sessionAffinity`                                | `None`                                                  | セッションアフィニティの種類。`ClientIP`または`None`のいずれかである必要があります（これはクラスター内から発信されるトラフィックに対してのみ意味があります） |
| `service.sessionAffinityConfig`                          |                                                         | セッションアフィニティ構成。`service.sessionAffinity` == `ClientIP`の場合、デフォルトのセッションスティッキー時間は3時間（`10800`）です |
| `serviceAccount.annotations`                             | `{}`                                                    | ServiceAccountアノテーション |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                 | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                 | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                 | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                         | ServiceAccountの名前。設定されていない場合、チャートのフルネームが使用されます |
| `serviceLabels`                                          | `{}`                                                    | 補足サービスラベル |
| `tolerations`                                            | `[]`                                                    | Pod割り当てのTolerationラベル |

### Pages固有の設定 {#pages-specific-settings}

| パラメータ                   | デフォルト | 説明 |
|-----------------------------|---------|-------------|
| `artifactsServerTimeout`    | `10`    | アーティファクトサーバーへのプロキシリクエストのタイムアウト（秒単位） |
| `artifactsServerUrl`        |         | アーティファクトリクエストをプロキシするAPI URI |
| `extraVolumeMounts`         |         | 追加する追加ボリュームマウントのリスト |
| `extraVolumes`              |         | 作成する追加ボリュームのリスト |
| `gitlabCache.cleanup`       | int     | 参照:[Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabCache.expiry`        | int     | 参照:[Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabCache.refresh`       | int     | 参照:[Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabClientHttpTimeout`   |         | GitLab API HTTPクライアント接続タイムアウト（秒単位） |
| `gitlabClientJwtExpiry`     |         | JWTトークンの有効期限（秒単位） |
| `gitlabRetrieval.interval`  | int     | 参照:[Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabRetrieval.retries`   | int     | 参照:[Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabRetrieval.timeout`   | int     | 参照:[Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabServer`              |         | GitLabサーバーのFQDN |
| `headers`                   | `[]`    | 各レスポンスでクライアントに送信される追加のHTTPヘッダーを指定します。複数のヘッダーを配列として指定できます。ヘッダーと値を1つの文字列として指定します（例：`['my-header: myvalue', 'my-other-header: my-other-value']`）。 |
| `insecureCiphers`           | `false` | デフォルトの暗号スイートリストを使用します。3DESやRC4などの脆弱なスイートが含まれている可能性があります |
| `internalGitlabServer`      |         | APIリクエストに使用される内部GitLabサーバー |
| `logFormat`                 | `json`  | ログ出力形式 |
| `logVerbose`                | `false` | 冗長なログの生成 |
| `maxConnections`            |         | HTTP、HTTPS、またはプロキシリスナーへの同時接続数の制限 |
| `maxURILength`              |         | URIの長さを制限します。無制限の場合は0。 |
| `propagateCorrelationId`    |         | 受信リクエストヘッダー`X-Request-ID`から既存の相関IDを再利用します（存在する場合） |
| `redirectHttp`              | `false` | HTTPからHTTPSにページをリダイレクト |
| `sentry.enabled`            | `false` | Sentryレポートを有効にする |
| `sentry.dsn`                |         | Sentryクラッシュレポートの送信先アドレス |
| `sentry.environment`        |         | Sentryクラッシュレポートの環境 |
| `serverShutdowntimeout`     | `30s`   | GitLab Pagesサーバーのシャットダウンタイムアウト（秒単位） |
| `statusUri`                 |         | ページのURLパス |
| `tls.minVersion`            |         | 最小SSL/TLSを指定します |
| `tls.maxVersion`            |         | 最大SSL/TLSを指定します |
| `useHTTPProxy`              | `false` | GitLab Pagesがリバースプロキシの背後にある場合は、このオプションを使用します。 |
| `useProxyV2`                | `false` | HTTPSリクエストでPROXYv2プロトコルを強制的に利用します。 |
| `zipCache.cleanup`          | int     | 参照:[Zip提供とキャッシュの構成](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipCache.expiration`       | int     | 参照:[Zip提供とキャッシュの構成](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipCache.refresh`          | int     | 参照:[Zip提供とキャッシュの構成](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipOpenTimeout`            | int     | 参照:[Zip提供とキャッシュの構成](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipHTTPClientTimeout`      | int     | 参照:[Zip提供とキャッシュの構成](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `rateLimitSourceIP`         |         | 参照:[GitLab Pagesのレート制限](https://docs.gitlab.com/administration/pages/#rate-limits)。 |
| `rateLimitSourceIPBurst`    |         | 参照:[GitLab Pagesのレート制限](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitDomain`           |         | 参照:[GitLab Pagesのレート制限](https://docs.gitlab.com/administration/pages/#rate-limits)。 |
| `rateLimitDomainBurst`      |         | 参照:[GitLab Pagesのレート制限](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitTLSSourceIP`      |         | 参照:[GitLab Pagesのレート制限](https://docs.gitlab.com/administration/pages/#rate-limits)。 |
| `rateLimitTLSSourceIPBurst` |         | 参照:[GitLab Pagesのレート制限](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitTLSDomain`        |         | 参照:[GitLab Pagesのレート制限](https://docs.gitlab.com/administration/pages/#rate-limits)。 |
| `rateLimitTLSDomainBurst`   |         | 参照:[GitLab Pagesのレート制限](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitSubnetsAllowList` |         | 参照:[GitLab Pagesのレート制限](#rate-limits) |
| `serverReadTimeout`         | `5s`    | 参照:[GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `serverReadHeaderTimeout`   | `1s`    | 参照:[GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `serverWriteTimeout`        | `5m`    | 参照:[GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `serverKeepAlive`           | `15s`   | 参照:[GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `authTimeout`               | `5s`    | 参照:[GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |
| `authCookieSessionTimeout`  | `10m`   | 参照:[GitLab Pagesグローバル設定](https://docs.gitlab.com/administration/pages/#global-settings) |

### `ingress`の構成 {#configuring-the-ingress}

このセクションでは、GitLab Pages Ingressを制御します。

| 名前                   |  種類   | デフォルト | 説明 |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | String  |         | `apiVersion`フィールドで使用する。 |
| `annotations`          | String  |         | このフィールドは、[Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)の標準`annotations`と完全に一致します。 |
| `configureCertmanager` | Boolean | `false` | Ingressアノテーション`cert-manager.io/issuer`と`acme.cert-manager.io/http01-edit-in-place`を切り替えます。cert-managerを使用したGitLab PagesのTLS証明書の取得は、ワイルドカード証明書の取得には[DNS01ソルバー](https://cert-manager.io/docs/configuration/acme/dns01/)を備えたcert-manager Issuerが必要であり、このチャートによってデプロイされたIssuerは[HTTP01ソルバー](https://cert-manager.io/docs/configuration/acme/http01/)のみを提供するため、無効になっています。詳細については、[GitLab PagesのTLS要件](../../../installation/tls.md)を参照してください。 |
| `enabled`              | Boolean |         | サポートするサービスに対してIngressオブジェクトを作成するかどうかを制御する設定。設定しない場合、`global.ingress.enabled`設定が使用されます。 |
| `tls.enabled`          | Boolean |         | `false`に設定すると、PagesサブチャートのTLSが無効になります。これは主に、Ingressコントローラーの前にTLS終端プロキシがある場合など、`ingress-level`でTLS終端を使用できない場合に役立ちます。 |
| `tls.secretName`       | String  |         | ページURIの有効な証明書とキーを含むKubernetes TLSシークレットの名前。設定しない場合、代わりに`global.ingress.tls.secretName`が使用されます。デフォルトでは設定されていません。 |

## チャート構成の例 {#chart-configuration-examples}

### extraVolumes {#extravolumes}

`extraVolumes`を使用すると、追加ボリュームチャート全体を構成できます。

`extraVolumes`の使用例を以下に示します:

```yaml
extraVolumes: |
  - name: example-volume
    persistentVolumeClaim:
      claimName: example-pvc
```

### extraVolumeMounts {#extravolumemounts}

`extraVolumeMounts`を使用すると、すべてのコンテナチャート全体で追加のvolumeMountを構成できます。

`extraVolumeMounts`の使用例を以下に示します:

```yaml
extraVolumeMounts: |
  - name: example-volume
    mountPath: /etc/example
```

### `networkpolicy`の構成 {#configuring-the-networkpolicy}

このセクションでは、[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を制御します。この構成はオプションであり、PodのエグレスとIngressを特定のエンドポイントに制限するために使用されます。

| 名前              |  種類   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | Boolean | `false` | この設定により、`NetworkPolicy`が有効になります |
| `ingress.enabled` | Boolean | `false` | `true`に設定すると、`Ingress`ネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのIngress接続がブロックされます。 |
| `ingress.rules`   |  Array  | `[]`    | Ingressポリシーのルールについて詳しくは、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>および下記の例を参照してください |
| `egress.enabled`  | Boolean | `false` | `true`に設定すると、`Egress`ネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのエグレス接続がブロックされます。 |
| `egress.rules`    |  Array  | `[]`    | エグレスポリシーのルールについて詳しくは、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>および下記の例を参照してください |

### ネットワークポリシーの例 {#example-network-policy}

`gitlab-pages`サービスには、ポート80および443へのIngress接続と、デフォルトのWorkhorseポート8181へのさまざまなエグレス接続が必要です。この例では、次のネットワークポリシーを追加します。

- Ingressリクエストを許可:
  - `nginx-ingress`ポッドからポート`8090`へ
  - `prometheus`ポッドからポート`9235`へ
- エグレスリクエストを許可:
  - ポート`53`上の`kube-dns`へ
  - ポート`8181`上の`webservice`ポッドへ
  - ポート`443`上のS3用のAWS VPCエンドポイントなどのエンドポイント`172.16.1.0/24`へ

_提供されている例は一例にすぎず、完全ではない可能性があることに注意してください_  

この例は、`kube-dns`がネームスペース`kube-system`に、`prometheus`がネームスペース`monitoring`に、`nginx-ingress`がネームスペース`nginx-ingress`にデプロイされたという前提に基づいています。

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
          - port: 9235
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 8090
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
          - podSelector:
              matchLabels:
                app: webservice
        ports:
          - port: 8181
```

### GitLab PagesへのTLSアクセス {#tls-access-to-gitlab-pages}

GitLab Pagesの機能にTLSアクセスするには、以下を実行する必要があります。

1. この形式でGitLab Pagesドメインの専任のワイルドカード証明書を作成します: `*.pages.<yourdomain>`。

1. Kubernetesでシークレットを作成します:

   ```shell
   kubectl create secret tls tls-star-pages-<mysecret> --cert=<path/to/fullchain.pem> --key=<path/to/privkey.pem>
   ```

1. このシークレットを使用するようにGitLab Pagesを設定します:

   ```yaml
   gitlab:
     gitlab-pages:
       ingress:
         tls:
           secretName: tls-star-pages-<mysecret>
   ```

1. ロードバランサーを指す名前`*.pages.<yourdomaindomain>`でDNSプロバイダーにDNSエントリを作成します。

### ワイルドカードDNSなしのPagesドメイン {#pages-domain-without-wildcard-dns}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5570) [ベータ](https://docs.gitlab.com/policy/development_stages_support/#beta)版としてGitLab 17.2で
- GitLab 17.4で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/483365)。

{{< /history >}}

{{< alert type="warning" >}}

GitLab Pagesは、一度に1つのURLスキームのみをサポートします。ワイルドカードDNSを使用するか、ワイルドカードDNSなしで使用します。`namespaceInPath`を有効にすると、既存のGitLab PagesのWebサイトには、ワイルドカードDNSなしのドメインでのみアクセスできます。

{{< /alert >}}

1. グローバルPages設定で`namespaceInPath`を有効にします。

   ```yaml
   global:
     pages:
       namespaceInPath: true
   ```

1. ロードバランサーを指す名前`pages.<yourdomaindomain>`でDNSプロバイダーにDNSエントリを作成します。

#### ワイルドカードDNSなしのGitLab PagesドメインへのTLSアクセス {#tls-access-to-gitlab-pages-domain-without-wildcard-dns}

1. この形式でGitLab Pagesドメインの証明書を作成します: `pages.<yourdomain>`。
1. Kubernetesでシークレットを作成します:

   ```shell
   kubectl create secret tls tls-star-pages-<mysecret> --cert=<path/to/fullchain.pem> --key=<path/to/privkey.pem>
   ```

1. このシークレットを使用するようにGitLab Pagesを設定します:

   ```yaml
   gitlab:
     gitlab-pages:
       ingress:
         tls:
           secretName: tls-star-pages-<mysecret>
   ```

#### アクセス制御の設定 {#configure-access-control}

1. グローバルPages設定で`accessControl`を有効にします。

   ```yaml
   global:
     pages:
       accessControl: true
   ```

1. 任意。[TLSアクセス](#tls-access-to-gitlab-pages-domain-without-wildcard-dns)が[設定](#tls-access-to-gitlab-pages-domain-without-wildcard-dns)されている場合は、HTTPSプロトコルを使用するように、GitLab Pages [システムOAuthアプリケーション](https://docs.gitlab.com/integration/oauth_provider/#create-an-instance-wide-application)のリダイレクト[URI](#tls-access-to-gitlab-pages-domain-without-wildcard-dns)を更新します。

{{< alert type="warning" >}}

GitLab PagesはOAuthアプリケーションを更新せず、デフォルトの`authRedirectUri`が`https://pages.<yourdomaindomain>/projects/auth`に更新されます。プライベートPagesサイトにアクセス中に、「指定されたリダイレクトURIが無効です」というエラーが発生した場合は、GitLab Pages [システムOAuthアプリケーション](https://docs.gitlab.com/integration/oauth_provider/#create-an-instance-wide-application)のリダイレクトURIを`https://pages.<yourdomaindomain>/projects/auth`に更新します。

{{< /alert >}}

### レート制限 {#rate-limits}

サービス拒否（DoS）攻撃のリスクを最小限に抑えるために、レート制限を適用できます。詳細な[レート制限](https://docs.gitlab.com/administration/pages/#rate-limits)ドキュメントが利用可能です。

特定のIP範囲（サブネット）がすべてのレート制限を回避するのを許可するには:

- `rateLimitSubnetsAllowList`:すべてのレート制限をバイパスする必要があるIP範囲（サブネット）で許可リストを設定します。

#### レート制限サブネット許可リストの設定 {#configure-rate-limits-subnets-allow-list}

`charts/gitlab/charts/gitlab-pages/values.yaml`でIP範囲（サブネット）を使用して、許可リストを設定します:

```yaml
gitlab:
  gitlab-pages:
    rateLimitSubnetsAllowList:
     - "1.2.3.4/24"
     - "2001:db8::1/32"
```

### KEDAの設定 {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`の代わりに、[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この設定はオプションであり、カスタムまたは外部メトリクスに基づいてオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する場合、`hpa`セクションで設定された値にデフォルト設定されます。

次の条件がtrueの場合、`hpa`セクションで設定されたCPUおよびメモリーのしきい値に基づいて、CPUおよびメモリートリガーが自動的に追加されます:

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定もゼロ以外の値に設定されます。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの[設定](https://keda.sh/docs/2.10/concepts/scaling-deployments/)の詳細については、[KEDAのドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  型   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | Boolean | `false`                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用する |
| `pollingInterval`               | Integer | `30`                            | 各トリガーをオンにする間隔 |
| `cooldownPeriod`                | Integer | `300`                           | リソースを0にスケールして戻す前に、アクティブと報告された最後のトリガーの後に待機する期間 |
| `minReplicaCount`               | Integer | `hpa.minReplicas`               | KEDAがリソースをスケールダウンするレプリカの最小数。 |
| `maxReplicaCount`               | Integer | `hpa.maxReplicas`               | KEDAがリソースをスケールアップするレプリカの最大数。 |
| `fallback`                      |   Map   |                                 | KEDA [フォールバック](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) [設定](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | String  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | Boolean |                                 | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールして戻す必要があるかどうかを指定します |
| `behavior`                      |   Map   | `hpa.behavior`                  | アップスケールとダウンスケールの動作の仕様。 |
| `triggers`                      |  Array  |                                 | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト、デフォルトは`hpa.cpu`および`hpa.memory`からコンピューティングされたトリガー |

### サービスアカウント {#serviceaccount}

このセクションでは、サービスアカウントを作成する必要があるかどうか、およびデフォルトのアクセストークンをポッドにマウントする必要があるかどうかを制御します。

| 名前                           |  タイプ   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   Map   | `{}`    | サービスアカウントアノテーション。 |
| `automountServiceAccountToken` | Boolean | `false` | デフォルトのサービスアカウント アクセストークンをポッドにマウントする必要があるかどうかを制御します。特定のサイドカーが正しく動作するために必要な場合（たとえば、Istio）を除き、これを有効にしないでください。 |
| `create`                       | Boolean | `false` | サービスアカウントを作成する必要があるかどうかを示します。 |
| `enabled`                      | Boolean | `false` | サービスアカウントを使用するかどうかを示します。 |
| `name`                         | String  |         | サービスアカウントの名前。設定されていない場合、チャートのフルネームが使用されます。 |

### アフィニティ {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。
