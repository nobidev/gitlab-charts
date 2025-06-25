---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Mailroomチャートの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimateプラン
- 提供:GitLab Self-Managed

{{< /details >}}

Mailroomチャートは、[受信メール](https://docs.gitlab.com/administration/incoming_email/)を処理します。

## 設定 {#configuration}

```yaml
image:
  repository: registry.gitlab.com/gitlab-org/build/cng/gitlab-mailroom
  # tag: v0.9.1
  pullSecrets: []
  # pullPolicy: IfNotPresent

enabled: true

init:
  image: {}
    # repository:
    # tag:
  resources:
    requests:
      cpu: 50m

annotations: {}

# Tolerations for pod scheduling
tolerations: []
affinity: {}
podLabels: {}

hpa:
  minReplicas: 1
  maxReplicas: 2
  cpu:
    targetAverageUtilization: 75

  # Note that the HPA is limited to autoscaling/v2beta1, autoscaling/v2beta2 and autoscaling/v2
  customMetrics: []
  behavior: {}

networkpolicy:
  enabled: false
  egress:
    enabled: false
    rules: []
  ingress:
    enabled: false
    rules: []
  annotations: {}

resources:
  # limits:
  #  cpu: 1
  #  memory: 2G
  requests:
    cpu: 50m
    memory: 150M

## Allow to overwrite under which User and Group we're running.
securityContext:
  runAsUser: 1000
  fsGroup: 1000

## Enable deployment to use a serviceAccount
serviceAccount:
  enabled: false
  create: false
  annotations: {}
  ## Name to be used for serviceAccount, otherwise defaults to chart fullname
  # name:
```

| パラメータ                                     | デフォルト                                                    | 説明 |
|-----------------------------------------------|------------------------------------------------------------|-------------|
| `affinity`                                    | `{}`                                                       | ポッド割り当ての[アフィニティルール](../_index.md#affinity) |
| `annotations`                                 | `{}`                                                       | Podアノテーション。 |
| `deployment.strategy`                         | `{}`                                                       | デプロイで使用される更新戦略を構成できます |
| `enabled`                                     | `true`                                                     | Mailroomの有効化フラグ |
| `hpa.behavior`                                | `{scaleDown: {stabilizationWindowSeconds: 300 }}`          | 動作には、アップスケールとダウンスケールの動作の仕様が含まれています（`autoscaling/v2beta2`以上が必要です） |
| `hpa.customMetrics`                           | `[]`                                                       | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で設定された平均CPU使用率のデフォルトの使用を上書きします） |
| `hpa.cpu.targetType`                          | `Utilization`                                              | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`                  |                                                            | オートスケールCPUターゲット値を設定します |
| `hpa.cpu.targetAverageUtilization`            | `75`                                                       | オートスケールCPUターゲット使用率を設定します |
| `hpa.memory.targetType`                       |                                                            | オートスケールメモリターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`               |                                                            | オートスケールメモリターゲット値を設定します |
| `hpa.memory.targetAverageUtilization`         |                                                            | オートスケールメモリターゲット使用率を設定します |
| `hpa.maxReplicas`                             | `2`                                                        | レプリカの最大数 |
| `hpa.minReplicas`                             | `1`                                                        | レプリカの最小数 |
| `image.pullPolicy`                            | `IfNotPresent`                                             | Mailroomイメージプルポリシー |
| `extraEnvFrom`                                |                                                            | 公開する他のデータソースからの追加の環境変数のリスト |
| `image.pullSecrets`                           |                                                            | Mailroomイメージプルシークレット |
| `image.registry`                              |                                                            | Mailroomイメージレジストリ |
| `image.repository`                            | `registry.gitlab.com/gitlab-org/build/cng/gitlab-mailroom` | Mailroomイメージリポジトリ |
| `image.tag`                                   |                                                            | Mailroomイメージtag |
| `init.image.repository`                       |                                                            | Mailroom initイメージリポジトリ |
| `init.image.tag`                              |                                                            | Mailroom initイメージtag |
| `init.resources`                              | `{ requests: { cpu: 50m }}`                                | Mailroom initコンテナリソース要件 |
| `init.containerSecurityContext`               |                                                            | initContainerコンテナ固有の[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `keda.enabled`                                | `false`                                                    | `ScaledObjects`[KEDA](https://keda.sh/)を[使用](https://keda.sh/)して、`HorizontalPodAutoscalers`の代わりに使用します |
| `keda.pollingInterval`                        | `30`                                                       | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                         | `300`                                                      | 最後のアクティブとレポートされたトリガーの後に、リソースを0にスケールバックするまで待機する期間 |
| `keda.minReplicaCount`                        | `hpa.minReplicas`                                          | KEDAがリソースをスケールダウンするレプリカの最小数。 |
| `keda.maxReplicaCount`                        | `hpa.maxReplicas`                                          | KEDAがリソースをスケールアップするレプリカの最大数。 |
| `keda.fallback`                               |                                                            | KEDA [フォールバック](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)構成については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                | `keda-hpa-{scaled-object-name}`                            | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`          |                                                            | `ScaledObject`の削除後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                               | `hpa.behavior`                                             | アップスケールとダウンスケールの動作の仕様。 |
| `keda.triggers`                               |                                                            | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーにデフォルト設定します |
| `podLabels`                                   | `{}`                                                       | Mailroomポッドを実行するためのラベル |
| `common.labels`                               | `{}`                                                       | このチャートで作成されたすべてのオブジェクトに適用される補足ラベル。 |
| `resources`                                   | `{ requests: { cpu: 50m, memory: 150M }}`                  | Mailroomリソース要件 |
| `networkpolicy.annotations`                   | `{}`                                                       | NetworkPolicyに追加するアノテーション |
| `networkpolicy.egress.enabled`                | `false`                                                    | NetworkPolicyのエグレスルールを有効にするフラグ |
| `networkpolicy.egress.rules`                  | `[]`                                                       | NetworkPolicyのエグレスルールのリストを定義する |
| `networkpolicy.enabled`                       | `false`                                                    | NetworkPolicyを使用するためのフラグ |
| `networkpolicy.ingress.enabled`               | `false`                                                    | NetworkPolicyの`ingress`ルールを有効にするフラグ |
| `networkpolicy.ingress.rules`                 | `[]`                                                       | NetworkPolicyの`ingress`ルールのリストを定義する |
| `securityContext.fsGroup`                     | `1000`                                                     | ポッドを開始するグループID |
| `securityContext.runAsUser`                   | `1000`                                                     | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`         |                                                            | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要） |
| `containerSecurityContext`                    |                                                            | コンテナが起動されるコンテナの[オーバーライド](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `containerSecurityContext.runAsUser`          | `1000`                                                     | コンテナが起動される特定のセキュリティコンテキストを上書きできるようにします |
| `serviceAccount.annotations`                  | `{}`                                                       | ServiceAccountのアノテーション |
| `serviceAccount.automountServiceAccountToken` | `false`                                                    | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.enabled`                      | `false`                                                    | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.create`                       | `false`                                                    | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.name`                         |                                                            | ServiceAccountの名前。設定されていない場合、チャートのフルネームが使用されます |
| `tolerations`                                 |                                                            | Mailroomに追加するTolerations |
| `priorityClassName`                           |                                                            | [ポッド](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)に[割り当て](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)られた[優先](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)度クラス。 |

## KEDAの設定 {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`ではなく、[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この設定はオプションであり、カスタムまたは外部メトリクスに基づいてオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する場合は`hpa`セクションで設定された値にデフォルト設定されます。

次がtrueの場合、CPUおよびメモリトリガーは、`hpa`セクションで設定されたCPUおよびメモリしきい値に基づいて自動的に追加されます。

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`の設定も、ゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの[設定](https://keda.sh/docs/2.10/concepts/scaling-deployments/)の詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  種類   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | `ScaledObjects`[KEDA](https://keda.sh/)を[使用](https://keda.sh/)して、`HorizontalPodAutoscalers`の代わりに使用します |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | 最後のアクティブとレポートされたトリガーの後に、リソースを0にスケールバックするまで待機する期間 |
| `minReplicaCount`               | 整数 | `hpa.minReplicas`               | KEDAがリソースをスケールダウンするレプリカの最小数。 |
| `maxReplicaCount`               | 整数 | `hpa.maxReplicas`               | KEDAがリソースをスケールアップするレプリカの最大数。 |
| `fallback`                      |   マップ   |                                 | KEDA [フォールバック](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)構成については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | `ScaledObject`の削除後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   | `hpa.behavior`                  | アップスケールとダウンスケールの動作の仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーにデフォルト設定します |

## 受信メール {#incoming-email}

デフォルトでは、受信メールは無効になっています。受信メールを読む方法は2つあります:

- [IMAP](#imap)
- [Microsoft Graph](#microsoft-graph)

まず、[共通設定](../../../installation/command-line-options.md#common-settings)を設定して有効にします。次に、[IMAP設定](../../../installation/command-line-options.md#imap-settings)または[Microsoft Graph設定](../../../installation/command-line-options.md#microsoft-graph-settings)を構成します。

これらの方法は、`values.yaml`で構成できます。次の例を参照してください:

- [IMAPでの受信メール](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-incoming-email.yaml)
- [Microsoft Graphでの受信メール](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-msgraph.yaml)

### IMAP {#imap}

IMAPの受信メールを有効にするには、`global.appConfig.incomingEmail`設定を使用して、IMAPサーバーと認証情報の詳細を提供します。

さらに、ターゲットのIMAPアカウントをGitLabがメール受信に[使用](https://docs.gitlab.com/administration/incoming_email/)できることを確認するには、[IMAPメールアカウントの要件](https://docs.gitlab.com/administration/incoming_email/)を[レビュー](https://docs.gitlab.com/administration/incoming_email/)する必要があります。いくつかの一般的なメールサービスも同じページに記載されており、受信メールの設定に役立ちます。

IMAPパスワードは、[シークレットガイド](../../../installation/secrets.md#imap-password-for-incoming-emails)に記載されているように、Kubernetes [シークレット](../../../installation/secrets.md#imap-password-for-incoming-emails)として作成する必要があります。

### Microsoft Graph {#microsoft-graph}

[Azure Active Directoryアプリケーションの作成に関するGitLabドキュメント](https://docs.gitlab.com/administration/incoming_email/#microsoft-graph)を参照してください。

テナントID、クライアントID、クライアントシークレットを提供します。これらの[設定](../../../installation/command-line-options.md#incoming-email-configuration)の詳細については、[コマンドラインオプション](../../../installation/command-line-options.md#incoming-email-configuration)を参照してください。

[シークレットガイド](../../../installation/secrets.md#microsoft-graph-client-secret-for-incoming-emails)の説明に従って、クライアント[シークレット](../../../installation/secrets.md#microsoft-graph-client-secret-for-incoming-emails)を含むKubernetes [シークレット](../../../installation/secrets.md#microsoft-graph-client-secret-for-incoming-emails)を作成します。

### メールによる返信 {#reply-by-email}

メールによる返信[機能](../../../installation/command-line-options.md#outgoing-email-configuration)を[使用](../../../installation/command-line-options.md#outgoing-email-configuration)するには、[ユーザー](../../../installation/command-line-options.md#outgoing-email-configuration)が通知メールに返信して[イシュー](../../../installation/command-line-options.md#outgoing-email-configuration)とMRにコメントできるようにするには、[送信メール](../../../installation/command-line-options.md#outgoing-email-configuration)と受信メールの[設定](../../../installation/command-line-options.md#outgoing-email-configuration)を構成する必要があります。

### サービスデスクのメール {#service-desk-email}

デフォルトでは、サービスデスクのメールは無効になっています。

受信メールと同様に、[共通設定](../../../installation/command-line-options.md#common-settings-1)を設定して有効にします。次に、[IMAP設定](../../../installation/command-line-options.md#imap-settings-1)または[Microsoft Graph設定](../../../installation/command-line-options.md#microsoft-graph-settings-1)を構成します。

これらのオプションは、`values.yaml`でも構成できます。次の例を参照してください:

- [IMAPを使用したサービスデスク](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-service-desk-email.yaml)
- [Microsoft Graphを使用したサービスデスク](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-msgraph.yaml)

サービスデスクのメールは、[受信メール](#incoming-email)を構成することを_要求_します。

#### IMAP {#imap-1}

`global.appConfig.serviceDeskEmail`設定を使用して、IMAPサーバーと認証情報の詳細を提供します。これらの設定の詳細については、[コマンドラインオプション](../../../installation/command-line-options.md#service-desk-email-configuration)を参照してください。

[シークレットガイド](../../../installation/secrets.md#imap-password-for-service-desk-emails)の説明に従って、IMAPパスワードを含むKubernetes [シークレット](../../../installation/secrets.md#imap-password-for-service-desk-emails)を作成します。

#### Microsoft Graph {#microsoft-graph-1}

[Azure Active Directoryアプリケーションの作成に関するGitLabドキュメント](https://docs.gitlab.com/administration/incoming_email/#microsoft-graph)を参照してください。

`global.appConfig.serviceDeskEmail`設定を使用して、テナントID、クライアントID、クライアントシークレットを提供します。これらの設定の詳細については、[コマンドラインオプション](../../../installation/command-line-options.md#service-desk-email-configuration)を参照してください。

[シークレットガイド](../../../installation/secrets.md#imap-password-for-service-desk-emails)の説明に従って、クライアント[シークレット](../../../installation/secrets.md#imap-password-for-service-desk-emails)を含むKubernetes [シークレット](../../../installation/secrets.md#imap-password-for-service-desk-emails)も作成する必要があります。

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  種類   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountアノテーション。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。特定のサイドカーが適切に動作するために必要な場合（たとえば、Istio）、これを有効にしないでください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定されていない場合は、チャートのフルネームが使用されます。 |

### アフィニティ {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。
