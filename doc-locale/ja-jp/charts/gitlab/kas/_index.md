---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab `kas` チャートの使用
---

{{< details >}}

- プラン:Free, Premium, Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

`kas`サブチャートは、[GitLabエージェントサーバー (KAS)](https://docs.gitlab.com/administration/clusters/kas/)の設定可能なデプロイメントを提供します。エージェントサーバーは、GitLabと一緒にインストールするコンポーネントです。[Kubernetes向けGitLabエージェント](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent)を管理するために必要です。

このチャートは、GitLab APIとGitalyサーバーへのアクセスに依存します。このチャートを有効にすると、Ingressがデプロイされます。

リソースの消費を最小限に抑えるため、`kas`コンテナはDistrolessイメージを使用します。デプロイされたサービスはIngressによって公開され、通信には[WebSocketプロキシ](https://nginx.org/en/docs/http/websocket.html)を使用します。このプロキシにより、外部コンポーネントである[`agentk`](https://docs.gitlab.com/user/clusters/agent/install/)との長期的な接続が可能になります。`agentk`は、Kubernetesクラスター側のエージェントの対応物です。

サービスへのアクセスルートは、[Ingress設定](#specify-an-ingress)によって異なります。

詳細については、[Kubernetes向けGitLabエージェントのアーキテクチャ](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md)を参照してください。

## エージェントサーバーを無効にする {#disable-the-agent-server}

GitLabエージェントサーバー（`kas`）はデフォルトで有効になっています。GitLabインスタンスで無効にするには、Helmプロパティ`global.kas.enabled`を`false`に設定します。

例:

```shell
helm upgrade --install kas --set global.kas.enabled=false
```

### Ingressを指定する {#specify-an-ingress}

チャートのIngressをデフォルト設定で使用すると、エージェントサーバーのサービスはサブドメインで到達可能になります。たとえば、`global.hosts.domain: example.com`の場合、エージェントサーバーは`kas.example.com`で到達可能です。

[KAS Ingress](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/kas/templates/ingress.yaml)は、`global.hosts.domain`とは異なるドメインを使用できます。

`global.hosts.kas.name`を設定します。例:

```shell
global.hosts.kas.name: kas.my-other-domain.com
```

この例では、`kas.my-other-domain.com`をKAS Ingressのみのホストとして使用します。その他のサービス（GitLab、Registry、MinIOなどを含む）は、`global.hosts.domain`で指定されたドメインを使用します。

### インストールコマンドラインオプション {#installation-command-line-options}

これらのパラメータを`helm install`コマンドに渡すには、`--set`フラグを使用します。

| パラメータ                                                | デフォルト                                               | 説明 |
|----------------------------------------------------------|-------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                  | ポッドの割り当ての[アフィニティルール](../_index.md#affinity) |
| `annotations`                                            | `{}`                                                  | Podアノテーション。 |
| `common.labels`                                          | `{}`                                                  | このチャートによって作成されたすべてのオブジェクトに適用される補助ラベル。 |
| `securityContext.runAsUser`                              | `65532`                                               | ポッドを開始するユーザーID |
| `securityContext.runAsGroup`                             | `65534`                                               | ポッドを開始するグループID |
| `securityContext.fsGroup`                                | `65532`                                               | ポッドを開始するグループID |
| `securityContext.fsGroupChangePolicy`                    |                                                       | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                      | 使用するSeccompプロファイル |
| `containerSecurityContext.runAsUser`                     | `65532`                                               | コンテナを開始するコンテナの[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)ユーザーIDをオーバーライドします |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                               | コンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                           | Gitalyコンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `extraContainers`                                        |                                                       | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列。 |
| `extraEnv`                                               |                                                       | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                       | 公開する他のデータソースからの追加の環境変数のリスト |
| `init.containerSecurityContext`                          |                                                       | initコンテナのsecurityContextのオーバーライド |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                               | initContainer固有:プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                | initContainer固有:コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                           | initContainer固有:コンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-kas` | イメージリポジトリ。 |
| `image.tag`                                              | `v13.7.0`                                             | イメージtag。  |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`     | Behaviorには、アップスケールとダウンスケールのが含まれています（`autoscaling/v2beta2`以上が必要です）。 |
| `hpa.customMetrics`                                      | `[]`                                                  | カスタムには、必要なレプリカ数を計算するために使用するが含まれています（`targetAverageUtilization`で構成された平均CPU使用率のデフォルトの使用をオーバーライドします）。 |
| `hpa.cpu.targetType`                                     | `AverageValue`                                        | オートスケールのCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.cpu.targetAverageValue`                             | `100m`                                                | オートスケールのCPUターゲットを設定します。 |
| `hpa.cpu.targetAverageUtilization`                       |                                                       | オートスケールのCPUターゲット使用率を設定します。 |
| `hpa.memory.targetType`                                  |                                                       | オートスケールのメモリーターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります。 |
| `hpa.memory.targetAverageValue`                          |                                                       | オートスケールのメモリーターゲットを設定します。 |
| `hpa.memory.targetAverageUtilization`                    |                                                       | オートスケールのメモリーターゲット使用率を設定します。 |
| `hpa.targetAverageValue`                                 |                                                       | **非推奨**オートスケールのCPUターゲットを設定します |
| `ingress.enabled`                                        | `global.kas.enabled=true`の場合`true`                   | `kas.ingress.enabled`を使用して、明示的にオンまたはオフにすることができます。設定されていない場合は、オプションで`global.ingress.enabled`を同じ目的で使用できます。 |
| `ingress.apiVersion`                                     |                                                       | `apiVersion`フィールドで使用する。 |
| `ingress.annotations`                                    | `{}`                                                  | Ingressアノテーション。 |
| `ingress.tls`                                            | `{}`                                                  | Ingress TLS。 |
| `ingress.agentPath`                                      | `/`                                                   | エージェントAPIのIngressパス。 |
| `ingress.k8sApiPath`                                     | `/k8s-proxy`                                          | Kubernetes APIのIngressパス。 |
| `keda.enabled`                                           | `false`                                               | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用する |
| `keda.pollingInterval`                                   | `30`                                                  | 各をチェックする間隔 |
| `keda.cooldownPeriod`                                    | `300`                                                 | 最後がアクティブと報告されてから、リソースを0にスケールバックするまで待機する期間 |
| `keda.minReplicaCount`                                   |                                                       | KEDAがリソースをスケールダウンするレプリカの最小数。デフォルトは`minReplicas` |
| `keda.maxReplicaCount`                                   |                                                       | KEDAがリソースをスケールアップするレプリカの最大数。デフォルトは`maxReplicas` |
| `keda.fallback`                                          |                                                       | KEDA構成については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                           |                                                       | KEDAが作成するHPAリソースの名前。デフォルトは`keda-hpa-{scaled-object-name}` |
| `keda.restoreToOriginalReplicaCount`                     |                                                       | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                          |                                                       | アップスケールとダウンスケールのの。デフォルトは`hpa.behavior` |
| `keda.triggers`                                          |                                                       | ターゲットリソースのをアクティブにするのリスト。デフォルトは`hpa.cpu`と`hpa.memory`から計算された |
| `metrics.enabled`                                        | `true`                                                | のエンドポイントをスクレイピングに使用できるようにするかどうか。 |
| `metrics.path`                                           | `/metrics`                                            | エンドポイントパス。 |
| `metrics.serviceMonitor.enabled`                         | `false`                                               | Prometheus Operatorがのスクレイピングを管理できるようにするために、ServiceMonitorを作成するかどうか。有効にすると、`prometheus.io`スクレイピングアノテーションが削除されます。これは、`metrics.podMonitor.enabled`と一緒に有効にすることはできません。 |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                  | ServiceMonitorに追加する追加の。 |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                  | ServiceMonitorの追加の構成。 |
| `metrics.podMonitor.enabled`                             | `false`                                               | Prometheus Operatorがのスクレイピングを管理できるようにするために、PodMonitorを作成するかどうか。有効にすると、`prometheus.io`スクレイピングアノテーションが削除されます。これは、`metrics.serviceMonitor.enabled`と一緒に有効にすることはできません。 |
| `metrics.podMonitor.additionalLabels`                    | `{}`                                                  | PodMonitorに追加する追加の。 |
| `metrics.podMonitor.endpointConfig`                      | `{}`                                                  | PodMonitorの追加の構成。 |
| `maxReplicas`                                            | `10`                                                  | HPA `maxReplicas`。 |
| `maxUnavailable`                                         | `1`                                                   | HPA `maxUnavailable`。 |
| `minReplicas`                                            | `2`                                                   | HPA `maxReplicas`。 |
| `nodeSelector`                                           |                                                       | 存在する場合は、この`Deployment`の`Pod`の[ノードセレクター](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector)を定義します。 |
| `observability.port`                                     | `8151`                                                | 可観測性ポート。とプローブに使用されます。 |
| `observability.livenessProbe.path`                       | `/liveness`                                           | livenessプローブのURI。このは、KASサービス構成の`observability.liveness_probe.url_path`と一致する必要があります。 |
| `observability.readinessProbe.path`                      | `/readiness`                                          | readinessプローブのURI。このは、KASサービス構成の`observability.readiness_probe.url_path`と一致する必要があります。 |
| `serviceAccount.annotations`                             | `{}`                                                  | サービスアカウントのアノテーション。 |
| `podLabels`                                              | `{}`                                                  | 補足Pod。セレクターには使用されません。 |
| `serviceLabels`                                          | `{}`                                                  | 補足サービス。 |
| `common.labels`                                          |                                                       | このチャートによって作成されたすべてのオブジェクトに適用される補助ラベル。 |
| `resources.requests.cpu`                                 | `100m`                                                | KASポッドごとの最小CPU |
| `resources.requests.memory`                              | `256Mi`                                               | KASポッドメモリーごとの最小メモリー。 |
| `service.externalPort`                                   | `8150`                                                | 外部ポート（`agentk`接続用）。 |
| `service.internalPort`                                   | `8150`                                                | 内部ポート（`agentk`接続用）。 |
| `service.apiInternalPort`                                | `8153`                                                | 内部API（GitLabバックエンド用）の内部ポート。 |
| `service.loadBalancerIP`                                 | `nil`                                                 | `service.type`が`LoadBalancer`の場合のカスタムロードバランサーIP。 |
| `service.loadBalancerSourceRanges`                       | `nil`                                                 | `service.type`が`LoadBalancer`の場合のカスタムロードバランサーソース範囲のリスト。 |
| `service.kubernetesApiPort`                              | `8154`                                                | プロキシされたKubernetes APIを公開する外部ポート。 |
| `service.privateApiPort`                                 | `8155`                                                | `kas`のプライベートAPIを公開する内部ポート（`kas` -> `kas`通信用）。 |
| `serviceAccount.annotations`                             | `{}`                                                  | ServiceAccountのアノテーション。 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                               | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します。 |
| `serviceAccount.create`                                  | `false`                                               | ServiceAccountを作成するかどうかを示します。 |
| `serviceAccount.enabled`                                 | `false`                                               | ServiceAccountを使用するかどうかを示します。 |
| `serviceAccount.name`                                    |                                                       | ServiceAccountの名前。設定されていない場合は、チャートのフルネームが使用されます。 |
| `websocketToken.secret`                                  | 自動生成                                         | WebSocketの署名と検証に使用するシークレットの名前。 |
| `websocketToken.key`                                     | 自動生成                                         | 使用する`websocketToken.secret`内のキーの名前。 |
| `privateApi.secret`                                      | 自動生成                                         | データベースとの認証に使用するシークレットの名前。 |
| `privateApi.key`                                         | 自動生成                                         | 使用する`privateApi.secret`内のキーの名前。 |
| `global.kas.service.apiExternalPort`                     | `8153`                                                | 内部API（GitLabバックエンド用）の外部ポート。 |
| `service.type`                                           | `ClusterIP`                                           | サービスタイプ。 |
| `tolerations`                                            | `[]`                                                  | ポッドの割り当てのToleration。 |
| `customConfig`                                           | `{}`                                                  | 指定された場合、デフォルトの`kas`構成をこれらのとマージし、ここで定義されたを優先します。 |
| `deployment.minReadySeconds`                             | `0`                                                   | `kas`ポッドが準備完了と見なされるまでに経過する必要がある最小秒数。 |
| `deployment.strategy`                                    | `{}`                                                  | デプロイメントで使用される更新戦略を構成できます。 |
| `deployment.terminationGracePeriodSeconds`               | `300`                                                 | SIGTERMを受信した後、Podがシャットダウンに費やすことができる時間（秒単位）。 |
| `priorityClassName`                                      |                                                       | ポッドに[優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)が割り当てられています。 |

## TLS通信を有効にする {#enable-tls-communication}

`kas`ポッドと他のGitLabチャートコンポーネント間のTLS通信を、[グローバルKAS属性](../../globals.md#tls-settings-1)を介して有効にします。

## `kas`チャートをテストする {#test-the-kas-chart}

チャートをインストールするには:

1. 独自のKubernetesクラスターを作成します。
1. マージリクエストの作業をチェックアウトします。
1. ローカルチャートからデフォルトで`kas`が有効になっているGitLabをインストール（または）します:

   ```shell
   helm upgrade --force --install gitlab . \
     --timeout 600s \
     --set global.hosts.domain=your.domain.com \
     --set global.hosts.externalIP=XYZ.XYZ.XYZ.XYZ \
     --set certmanager-issuer.email=your@email.com
   ```

1. GDKを使用して、[Kubernetes向けGitLabエージェント](https://docs.gitlab.com/user/clusters/agent/)を設定および使用するプロセスを実行します:（エージェントを手動で設定して使用する手順に従うこともできます。）

   1. GDK GitLabリポジトリから、QAフォルダーに移動します:`cd qa`。
   1. QAを実行するには、次のコマンドを実行します:

      ```shell
      GITLAB_USERNAME=$ROOT_USER
      GITLAB_PASSWORD=$ROOT_PASSWORD
      GITLAB_ADMIN_USERNAME=$ROOT_USER
      GITLAB_ADMIN_PASSWORD=$ROOT_PASSWORD
      bundle exec bin/qa Test::Instance::All https://your.gitlab.domain/ -- --tag orchestrated --tag quarantine qa/specs/features/ee/api/7_configure/kubernetes/kubernetes_agent_spec.rb
      ```

      環境変数`GITLAB_AGENTK_VERSION=v13.7.1`を使用してインストールする`agentk`をカスタマイズすることもできます

## KEDAを設定する {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。このはオプションであり、カスタムまたは外部に基づいてオートスケールが必要な場合に使用できます。

ほとんどのは、該当する場合、`hpa`セクションで設定されたにデフォルト設定されます。

以下が真の場合、`hpa`セクションで設定されたCPUとメモリーのに基づいて、CPUとメモリーのが自動的に追加されます:

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`の設定もゼロ以外のに設定されています。

が設定されていない場合、`ScaledObject`は作成されません。

これらのの詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  タイプ   | デフォルト | 説明 |
|:--------------------------------|:-------:|:--------|:------------|
| `enabled`                       | ブール値 | `false` | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用する |
| `pollingInterval`               | 整数 | `30`    | 各をチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`   | 最後がアクティブと報告されてから、リソースを0にスケールバックするまで待機する期間 |
| `minReplicaCount`               | 整数 |         | KEDAがリソースをスケールダウンするレプリカの最小数。デフォルトは`minReplicas` |
| `maxReplicaCount`               | 整数 |         | KEDAがリソースをスケールアップするレプリカの最大数。デフォルトは`maxReplicas` |
| `fallback`                      |   マップ   |         | KEDA構成については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | 文字列  |         | KEDAが作成するHPAリソースの名前。デフォルトは`keda-hpa-{scaled-object-name}` |
| `restoreToOriginalReplicaCount` | ブール値 |         | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   |         | アップスケールとダウンスケールのの。デフォルトは`hpa.behavior` |
| `triggers`                      |  配列  |         | ターゲットリソースのをアクティブにするのリスト。デフォルトは`hpa.cpu`と`hpa.memory`から計算された |

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  タイプ   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountのアノテーション。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。特定のサイドカーが正常に動作するために必要な場合を除き、これを有効にしないでください（たとえば、Istio）。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定されていない場合は、チャートのフルネームが使用されます。 |

### affinity {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。

## デバッグログを有効にする {#enable-debug-logging}

KASサブチャートのデバッグログを有効にするには、`values.yaml`ファイルの`kas`セクションに以下を追加します:

```yaml
customConfig:
   observability:
      logging:
         level: debug
         grpc_level: debug
```
