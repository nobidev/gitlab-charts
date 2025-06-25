---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-Spamcheckチャートの使用
---

{{< details >}}

- プラン:Premium, Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

`spamcheck`サブチャートは、[Spamcheck](https://gitlab.com/gitlab-org/spamcheck)のデプロイを提供します。これは、GitLab.comでのスパムの増加に対抗するためにGitLabによって開発され、後にGitLab Self-Managedで使用するために公開されたアンチスパムエンジンです。

## 要件 {#requirements}

このチャートは、GitLab APIへのアクセスに依存します。

## 設定 {#configuration}

### Spamcheckの有効化 {#enable-spamcheck}

`spamcheck`はデフォルトで無効になっています。GitLabインスタンスで有効にするには、Helmプロパティ`global.spamcheck.enabled`を`true`に設定します。例:

```shell
helm upgrade --force --install gitlab . \
--set global.hosts.domain='your.domain.com' \
--set global.hosts.externalIP=XYZ.XYZ.XYZ.XYZ \
--set certmanager-issuer.email='me@example.com' \
--set global.spamcheck.enabled=true
```

### Spamcheckを使用するようにGitLabを設定する {#configure-gitlab-to-use-spamcheck}

1. 左側のサイドバーの下部にある**管理者エリア**を選択します。
1. **設定 > レポート**を選択します。
1. **スパムとアンチボット対策**を展開します。
1. スパムチェックの設定を更新します。
   1. \[外部APIエンドポイント経由でスパムチェックを有効にする]チェックボックスをオンにします
   1. 外部スパムチェックエンドポイントのURLには`grpc://gitlab-spamcheck.default.svc:8001`を使用します。`default`は、GitLabがデプロイされているKubernetesネームスペースに置き換えられます。
   1. 「スパムチェックAPIキー」は空白のままにします。
1. **変更の保存**を選択します。

## インストール コマンドライン オプション {#installation-command-line-options}

以下のテーブルには、`helm install`コマンドに`--set`フラグを使用して指定できる、すべての可能なチャート設定が含まれています。

| パラメータ                                       | デフォルト                                                                                              | 説明 |
|-------------------------------------------------|------------------------------------------------------------------------------------------------------|-------------|
| `affinity`                                      | `{}`                                                                                                 | ポッド割り当ての[アフィニティルール](../_index.md#affinity) |
| `annotations`                                   | `{}`                                                                                                 | ポッドアノテーション |
| `common.labels`                                 | `{}`                                                                                                 | このチャートによってCreateされたすべてのオブジェクトに適用される追加のラベル。 |
| `deployment.livenessProbe.initialDelaySeconds`  | `20`                                                                                                 | livenessProbeが開始されるまでの遅延 |
| `deployment.livenessProbe.periodSeconds`        | `60`                                                                                                 | livenessProbeを実行する頻度 |
| `deployment.livenessProbe.timeoutSeconds`       | `30`                                                                                                 | livenessProbeがタイムアウトしたとき |
| `deployment.livenessProbe.successThreshold`     | `1`                                                                                                  | livenessProbeが失敗した後、成功したとみなされるための最小連続成功数 |
| `deployment.livenessProbe.failureThreshold`     | `3`                                                                                                  | livenessProbeが成功した後、失敗したとみなされるための最小連続失敗数 |
| `deployment.readinessProbe.initialDelaySeconds` | `0`                                                                                                  | readinessProbeが開始されるまでの遅延 |
| `deployment.readinessProbe.periodSeconds`       | `10`                                                                                                 | readinessProbeを実行する頻度 |
| `deployment.readinessProbe.timeoutSeconds`      | `2`                                                                                                  | readinessProbeがタイムアウトしたとき |
| `deployment.readinessProbe.successThreshold`    | `1`                                                                                                  | readinessProbeが失敗した後、成功したとみなされるための最小連続成功数 |
| `deployment.readinessProbe.failureThreshold`    | `3`                                                                                                  | readinessProbeが成功した後、失敗したとみなされるための最小連続失敗数 |
| `deployment.strategy`                           | `{}`                                                                                                 | デプロイで使用される更新ストラテジーをConfigureできます。指定しない場合、クラスターのデフォルトが使用されます。 |
| `hpa.behavior`                                  | `{scaleDown: {stabilizationWindowSeconds: 300 }}`                                                    | Behaviorには、アップスケールおよびダウンスケールBehaviorの仕様が含まれています（`autoscaling/v2beta2`以降が必要です）。 |
| `hpa.customMetrics`                             | `[]`                                                                                                 | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`でConfigureされた平均CPU使用率のデフォルト使用をオーバーライドします）。 |
| `hpa.cpu.targetType`                            | `AverageValue`                                                                                       | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`                    | `100m`                                                                                               | オートスケールCPUターゲット値を設定します |
| `hpa.cpu.targetAverageUtilization`              |                                                                                                      | オートスケールCPUターゲット使用率を設定します |
| `hpa.memory.targetType`                         |                                                                                                      | オートスケールメモリターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`                 |                                                                                                      | オートスケールメモリターゲット値を設定します |
| `hpa.memory.targetAverageUtilization`           |                                                                                                      | オートスケールメモリターゲット使用率を設定します |
| `hpa.targetAverageValue`                        |                                                                                                      | **非推奨**オートスケールCPUターゲット値を設定します |
| `image.registry`                                |                                                                                                      | Spamcheckイメージレジストリ |
| `image.repository`                              | `registry.gitlab.com/gitlab-com/gl-security/engineering-and-research/automation-team/spam/spamcheck` | Spamcheckイメージリポジトリ |
| `image.tag`                                     |                                                                                                      | Spamcheckイメージtag |
| `image.digest`                                  |                                                                                                      | Spamcheckイメージdigest |
| `keda.enabled`                                  | `false`                                                                                              | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                          | `30`                                                                                                 | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                           | `300`                                                                                                | リソースを0にスケールバックする前に、最後のアクティブとレポートされたトリガーの後に待機する期間 |
| `keda.minReplicaCount`                          | `hpa.minReplicas`                                                                                    | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `keda.maxReplicaCount`                          | `hpa.maxReplicas`                                                                                    | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `keda.fallback`                                 |                                                                                                      | KEDA [フォールバック](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                  | `keda-hpa-{scaled-object-name}`                                                                      | KEDAがCreateするHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`            |                                                                                                      | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                 | `hpa.behavior`                                                                                       | アップスケールおよびダウンスケールBehaviorの仕様。 |
| `keda.triggers`                                 |                                                                                                      | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。`hpa.cpu`および`hpa.memory`からコンピュートされたトリガーにデフォルト設定されます |
| `logging.level`                                 | `info`                                                                                               | ログレベル   |
| `maxReplicas`                                   | `10`                                                                                                 | HPA `maxReplicas` |
| `maxUnavailable`                                | `1`                                                                                                  | HPA `maxUnavailable` |
| `minReplicas`                                   | `2`                                                                                                  | HPA `maxReplicas` |
| `podLabels`                                     | `{}`                                                                                                 | 補足Podラベル。セレクターには使用されません。 |
| `resources.requests.cpu`                        | `100m`                                                                                               | Spamcheck最小CPU |
| `resources.requests.memory`                     | `100M`                                                                                               | Spamcheck最小メモリ |
| `securityContext.fsGroup`                       | `1000`                                                                                               | Podを開始するグループID |
| `securityContext.runAsUser`                     | `1000`                                                                                               | Podを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`           |                                                                                                      | ボリュームの所有権と権限を変更するためのポリシー (Kubernetes 1.23が必要) |
| `serviceLabels`                                 | `{}`                                                                                                 | サービスの補足ラベル |
| `service.externalPort`                          | `8001`                                                                                               | Spamcheck外部ポート |
| `service.internalPort`                          | `8001`                                                                                               | Spamcheck内部ポート |
| `service.type`                                  | `ClusterIP`                                                                                          | Spamcheckサービス タイプ |
| `serviceAccount.automountServiceAccountToken`   | `false`                                                                                              | デフォルトのServiceAccountアクセストークンをPodにマウントするかどうかを示します |
| `serviceAccount.create`                         | `false`                                                                                              | ServiceAccountをCreateするかどうかを示します |
| `serviceAccount.enabled`                        | `false`                                                                                              | ServiceAccountを使用するかどうかを示します |
| `tolerations`                                   | `[]`                                                                                                 | Pod割り当てのTolerationラベル |
| `extraEnvFrom`                                  | `{}`                                                                                                 | 公開する他のデータソースからの追加の環境変数のリスト |
| `priorityClassName`                             |                                                                                                      | [ポッド](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)に割り当てられた[優先](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)クラス。 |

## KEDAのConfigure {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この設定はオプションであり、カスタムメトリクスまたは外部メトリクスに基づいてオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する場合、`hpa`セクションで設定された値にデフォルト設定されます。

以下が当てはまる場合、`hpa`セクションで設定されたCPUおよびメモリしきい値に基づいて、CPUおよびメモリトリガーが自動的に追加されます。

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定も、ゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`はCreateされません。

これらの[設定](https://keda.sh/docs/2.10/concepts/scaling-deployments/)の詳細については、KEDAドキュメントを参照してください。

| 名前                            |  タイプ   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | リソースを0にスケールバックする前に、最後のアクティブとレポートされたトリガーの後に待機する期間 |
| `minReplicaCount`               | 整数 | `hpa.minReplicas`               | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `maxReplicaCount`               | 整数 | `hpa.maxReplicas`               | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `fallback`                      |   マップ   |                                 | KEDA [フォールバック](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAがCreateするHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   | `hpa.behavior`                  | アップスケールおよびダウンスケールBehaviorの仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。`hpa.cpu`および`hpa.memory`からコンピュートされたトリガーにデフォルト設定されます |

## チャート設定の例 {#chart-configuration-examples}

### `serviceAccount` {#serviceaccount}

このセクションでは、ServiceAccountをCreateするかどうか、およびデフォルトのアクセストークンをPodにマウントするかどうかを制御します。

| 名前                           |  タイプ   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをPodにマウントするかどうかを制御します。特定のサイドカーが正常に動作するためにこれが必要な場合を除き（たとえば、Istio）、これを有効にしないでください。 |
| `create`                       | ブール値 | `false` | ServiceAccountをCreateするかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |

### Toleration {#tolerations}

`tolerations`を使用すると、taintされたworkerノードでPodをスケジュールできます

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

### アフィニティ {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。

### アノテーション {#annotations}

`annotations`を使用すると、Spamcheck Podにアノテーションを追加できます。次に例を示します。

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### リソース {#resources}

`resources`を使用すると、Spamcheck Podが消費できるリソース（メモリとCPU）の最小量と最大量をConfigureできます。

次に例を示します。

```yaml
resources:
  requests:
    memory: 100m
    cpu: 100M
```

### livenessProbe/readinessProbe {#livenessprobereadinessprobe}

`deployment.livenessProbe`および`deployment.readinessProbe`は、コンテナが破損状態にある場合など、特定のシナリオでSpamcheck Podの終了を制御するのに役立つメカニズムを提供します。

次に例を示します。

```yaml
deployment:
  livenessProbe:
    initialDelaySeconds: 10
    periodSeconds: 20
    timeoutSeconds: 3
    successThreshold: 1
    failureThreshold: 10
  readinessProbe:
    initialDelaySeconds: 10
    periodSeconds: 5
    timeoutSeconds: 2
    successThreshold: 1
    failureThreshold: 3
```

この[設定](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)に関する追加の詳細については、公式のKubernetesドキュメントを参照してください。
