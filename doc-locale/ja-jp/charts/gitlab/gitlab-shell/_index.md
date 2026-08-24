---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Shellチャートの使用
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

`gitlab-shell` GitLab Shell Helmチャートは、GitLabへのGitアクセス用に設定されたサーバーを提供します。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされているKubernetesクラスタから到達可能な外部サービスとして提供されるWorkhorseサービスへのアクセスに依存します。

## 設計上の選択 {#design-choices}

SSHレプリカを容易にサポートし、SSH認証キーの共有ストレージの使用を避けるために、GitLab認証キーエンドポイントに対して認証するために、SSH [AuthorizedKeysCommand](https://man.openbsd.org/sshd_config#AuthorizedKeysCommand)を使用しています。その結果、これらのポッド内のAuthorizedKeysファイルを永続化または更新しません。

## 設定 {#configuration}

`gitlab-shell`チャートは、[外部サービス](#external-services)と[チャートの設定](#chart-settings)の2つの部分で構成されています。Ingressを介して公開されるポートは、`global.shell.port`で構成され、`22`がデフォルトです。Serviceの外部ポートも`global.shell.port`によって制御されます。

## インストールコマンドラインオプション {#installation-command-line-options}

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                    | [アフィニティルール](../_index.md#affinity)（ポッドの割り当て用） |
| `annotations`                                            |                                                         | ポッドの注釈 |
| `podLabels`                                              |                                                         | 追加のポッドラベル。セレクターには使用されません。 |
| `common.labels`                                          |                                                         | このチャートによって作成されたすべてのオブジェクトに適用される追加のラベル。 |
| `config.ciphers`                                         | 説明を参照してください。                                        | 許可される暗号を特定します。デフォルトは、[Goでサポートされているアルゴリズム](https://pkg.go.dev/golang.org/x/crypto/ssh#SupportedAlgorithms)です。FIPSビルドについては、[FIPS承認済み暗号](https://gitlab.com/gitlab-org/labkit/-/blob/7bb8cb3b9f0eca4a40744520ee87a696f85c9645/fips/ssh.go#L17-20)を参照してください。 |
| `config.kexAlgorithms`                                   | 説明を参照してください。                                        | 利用可能なKEX（キー交換）アルゴリズムを指定します。デフォルトは、[Goでサポートされているアルゴリズム](https://pkg.go.dev/golang.org/x/crypto/ssh#SupportedAlgorithms)です。FIPSビルドについては、[FIPS承認済みキー交換アルゴリズム](https://gitlab.com/gitlab-org/labkit/-/blob/7bb8cb3b9f0eca4a40744520ee87a696f85c9645/fips/ssh.go#L13)を参照してください。 |
| `config.macs`                                            | 説明を参照してください。                                        | 利用可能なMAC（メッセージ認証コード）アルゴリズムを指定します。デフォルトは、[Goでサポートされているアルゴリズム](https://pkg.go.dev/golang.org/x/crypto/ssh#SupportedAlgorithms)です。FIPSビルドについては、[FIPS承認済みMAC](https://gitlab.com/gitlab-org/labkit/-/blob/7bb8cb3b9f0eca4a40744520ee87a696f85c9645/fips/ssh.go#L24-27)を参照してください。 |
| `config.clientAliveInterval`                             | `0`                                                     | それ以外の場合はアイドル状態の接続でのキープアライブpingの間隔。デフォルト値0は、このpingを無効にします。 |
| `config.loginGraceTime`                                  | `60`                                                    | ユーザーが正常にログインしていない場合、サーバーが切断するまでの時間を指定します |
| `config.maxStartups.full`                                | `100`                                                   | 認証されていない接続数が指定された数に達すると、SSHd拒否確率が直線的に増加し、すべての認証されていない接続試行が拒否されます |
| `config.maxStartups.rate`                                | `30`                                                    | 認証されていない接続が多すぎる場合、SSHdは指定された確率で接続を拒否します（オプション） |
| `config.maxStartups.start`                               | `10`                                                    | 現在、指定された数を超える認証されていない接続がある場合、SSHdはいくつかの確率で接続試行を拒否します（オプション） |
| `config.proxyProtocol`                                   | `false`                                                 | `gitlab-sshd`デーモンのPROXYプロトコルサポートを有効にします |
| `config.proxyPolicy`                                     | `"use"`                                                 | PROXYプロトコルを処理するためのポリシーを指定します。値は、`use, require, ignore, reject`のいずれかである必要があります |
| `config.proxyHeaderTimeout`                              | `"500ms"`                                               | `gitlab-sshd`がPROXYプロトコルヘッダーの読み取りをあきらめる前に待機する最大時間。単位（`ms`、`s`、または`m`）を含める必要があります。 |
| `config.publicKeyAlgorithms`                             | `[]`                                                    | 公開キーアルゴリズムのカスタムリスト。空の場合、デフォルトのアルゴリズムが使用されます。 |
| `config.gssapi.enabled`                                  | `false`                                                 | `gitlab-sshd`デーモンのGSS-APIサポートを有効にします |
| `config.gssapi.keytab.secret`                            |                                                         | gssapi-with-mic認証方式のキータブを保持するKubernetesシークレットの名前 |
| `config.gssapi.keytab.key`                               | `keytab`                                                | Kubernetesシークレット内のキータブを保持するキー |
| `config.gssapi.krb5Config`                               |                                                         | GitLab Shellコンテナ内の`/etc/krb5.conf`ファイルの内容 |
| `config.gssapi.servicePrincipalName`                     |                                                         | `gitlab-sshd`デーモンで使用されるKerberosサービス名 |
| `config.lfs.pureSSHProtocol`                             | `false`                                                 | LFS Pure SSHプロトコルサポートを有効にします |
| `config.pat.enabled`                                     | `true`                                                  | SSHを使用したPATを有効にします |
| `config.pat.allowedScopes`                               | `[]`                                                    | SSHで生成されたPATに許可されるスコープの配列 |
| `opensshd.supplemental_config`                           |                                                         | 追加構成、`sshd_config`に追加。[manページ](https://manpages.debian.org/trixie/openssh-server/sshd_config.5.en.html)への厳密なアラインメント |
| `deployment.livenessProbe.initialDelaySeconds`           | `10`                                                    | Livenessプローブが開始されるまでの遅延 |
| `deployment.livenessProbe.periodSeconds`                 | `10`                                                    | Livenessプローブを実行する頻度 |
| `deployment.livenessProbe.timeoutSeconds`                | `3`                                                     | Livenessプローブがタイムアウトした場合 |
| `deployment.livenessProbe.successThreshold`              | `1`                                                     | 障害発生後、Livenessプローブが成功したと見なされるための最小連続成功数 |
| `deployment.livenessProbe.failureThreshold`              | `3`                                                     | 成功後、Livenessプローブが失敗したと見なされるための最小連続失敗数 |
| `deployment.readinessProbe.initialDelaySeconds`          | `10`                                                    | Readinessプローブが開始されるまでの遅延 |
| `deployment.readinessProbe.periodSeconds`                | `5`                                                     | Readinessプローブを実行する頻度 |
| `deployment.readinessProbe.timeoutSeconds`               | `3`                                                     | Readinessプローブがタイムアウトした場合 |
| `deployment.readinessProbe.successThreshold`             | `1`                                                     | 障害発生後、Readinessプローブが成功したと見なされるための最小連続成功数 |
| `deployment.readinessProbe.failureThreshold`             | `2`                                                     | 成功後、Readinessプローブが失敗したと見なされるための最小連続失敗数 |
| `deployment.strategy`                                    | `{}`                                                    | デプロイで使用される更新ストラテジを構成できます |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                    | Kubernetesがポッドの強制終了を待機する秒数 |
| `enabled`                                                | `true`                                                  | Shell有効フラグ |
| `extraContainers`                                        |                                                         | 含めるコンテナのリストを含む複数行のリテラルスタイルの文字列 |
| `extraInitContainers`                                    |                                                         | 含める追加のinitコンテナのリスト |
| `extraVolumeMounts`                                      |                                                         | 実行する追加のボリュームマウントのリスト |
| `extraVolumes`                                           |                                                         | 作成する追加のボリュームのリスト |
| `extraEnv`                                               |                                                         | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                         | 公開する他のデータソースからの追加の環境変数のリスト |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`       | 動作には、アップスケールおよびダウンスケール動作の仕様が含まれています（`autoscaling/v2beta2`以上が必要です） |
| `hpa.customMetrics`                                      | `[]`                                                    | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で構成された平均CPU使用率のデフォルトの使用をオーバーライドします） |
| `hpa.cpu.targetType`                                     | `AverageValue`                                          | オートスケールCPUターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`                             | `100m`                                                  | オートスケールCPUターゲット値を設定します |
| `hpa.cpu.targetAverageUtilization`                       |                                                         | オートスケールCPUターゲット使用率を設定します |
| `hpa.memory.targetType`                                  |                                                         | オートスケールメモリターゲットタイプを設定します。`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`                          |                                                         | オートスケールメモリターゲット値を設定します |
| `hpa.memory.targetAverageUtilization`                    |                                                         | オートスケールメモリターゲット使用率を設定します |
| `hpa.targetAverageValue`                                 |                                                         | **非推奨** オートスケールCPUターゲット値を設定します |
| `image.pullPolicy`                                       | `IfNotPresent`                                          | Shellイメージプルポリシー |
| `image.pullSecrets`                                      |                                                         | イメージリポジトリのシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-shell` | Shellイメージリポジトリ |
| `image.tag`                                              | `master`                                                | Shellイメージタグ |
| `init.image.repository`                                  |                                                         | initContainerイメージ |
| `init.image.tag`                                         |                                                         | initContainerイメージタグ |
| `init.containerSecurityContext`                          |                                                         | initContainer固有の[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                 | initContainer固有: プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                  | initContainer固有: コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                             | initContainer固有: コンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `keda.enabled`                                           | `false`                                                 | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                   | `30`                                                    | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                                    | `300`                                                   | 最後トリガーがアクティブであると報告されてから、リソースを0にスケールバックするまで待機する期間 |
| `keda.minReplicaCount`                                   | `minReplicas`                                           | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `keda.maxReplicaCount`                                   | `maxReplicas`                                           | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `keda.fallback`                                          |                                                         | KEDAフォールバック構成、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                         | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`                     |                                                         | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                          | `hpa.behavior`                                          | アップスケールおよびダウンスケール動作の仕様。 |
| `keda.triggers`                                          |                                                         | ターゲットリソースのスケールをアクティブにするトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーにデフォルト設定されています |
| `logging.format`                                         | `json`                                                  | 非構造化ログの場合は`text`に設定 |
| `logging.sshdLogLevel`                                   | `ERROR`                                                 | 基になるSSHデーモンのログレベル |
| `priorityClassName`                                      |                                                         | に割り当てられる[Priority class](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |
| `replicaCount`                                           | `1`                                                     | Shellレプリカ |
| `serviceLabels`                                          | `{}`                                                    | 追加のサービスラベル |
| `service.allocateLoadBalancerNodePorts`                  | Kubernetesのデフォルト値を使用するように設定されていません。               | ロードバランサーサービスでのNodePort割り当てを無効にすることができます。[ドキュメント](https://kubernetes.io/docs/concepts/services-networking/service/#load-balancer-nodeport-allocation)を参照してください |
| `service.externalTrafficPolicy`                          | `Cluster`                                               | Shellサービス外部トラフィックポリシー（クラスタまたはローカル） |
| `service.internalPort`                                   | `2222`                                                  | Shell内部ポート |
| `service.nodePort`                                       |                                                         | 設定されている場合、shell nodePortを設定します |
| `service.name`                                           | `gitlab-shell`                                          | Shellサービス名 |
| `service.type`                                           | `ClusterIP`                                             | Shellサービスタイプ |
| `service.loadBalancerIP`                                 |                                                         | ロードバランサーに割り当てるIPアドレス（サポートされている場合） |
| `service.loadBalancerSourceRanges`                       |                                                         | ロードバランサーへのアクセスを許可されたIP CIDRのリスト（サポートされている場合） |
| `serviceAccount.annotations`                             | `{}`                                                    | ServiceAccountの注釈 |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                 | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                 | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                 | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                         | ServiceAccountの名前。設定されていない場合、チャートのフルネームが使用されます |
| `securityContext.fsGroup`                                | `1000`                                                  | ポッドを開始するグループID |
| `securityContext.runAsUser`                              | `1000`                                                  | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                                         | ボリュームの所有権と許可を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                        | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                         | コンテナの起動元の[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `containerSecurityContext.runAsUser`                     | `1000`                                                  | コンテナの起動元の特定のセキュリティコンテキストを上書きできるようにします |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                 | コンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                  | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                             | Gitalyコンテナの[Linuxケイパビリティ](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `sshDaemon`                                              | `openssh`                                               | 実行するSSHデーモンを選択します。可能な値（`openssh`、`gitlab-sshd`） |
| `tolerations`                                            | `[]`                                                    | ポッド割り当ての容認ラベル |
| `traefik.entrypoint`                                     | `gitlab-shell`                                          | traefikを使用する場合、GitLab Shellに使用するtraefikエントリポイント。デフォルトは`gitlab-shell`です。 |
| `traefik.tcpMiddlewares`                                 | `[]`                                                    | traefikを使用する場合、IngressRouteTCPリソースに追加するTCPミドルウェア。デフォルトでは、ミドルウェアはありません |
| `workhorse.serviceName`                                  | `webservice`                                            | Workhorseサービス名（デフォルトでは、Workhorseはwebserviceポッド / Serviceの一部です） |
| `metrics.enabled`                                        | `false`                                                 | メトリクスエンドポイントをスクレイプできるようにする必要がある場合（`sshDaemon=gitlab-sshd`が必要です）。 |
| `metrics.port`                                           | `9122`                                                  | メトリクスエンドポイントポート |
| `metrics.path`                                           | `/metrics`                                              | メトリクスエンドポイントパス |
| `metrics.serviceMonitor.enabled`                         | `false`                                                 | Prometheus Operatorがメトリクスのスクレイプを管理できるようにServiceMonitorを作成する必要がある場合は、これを有効にすると、`prometheus.io`スクレイプ注釈が削除されることに注意してください |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                    | ServiceMonitorに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                    | ServiceMonitorの追加のエンドポイント構成 |
| `metrics.annotations`                                    |                                                         | **非推奨** 明示的なメトリクス注釈を設定します。テンプレートコンテンツに置き換えられました。 |

## チャート設定 {#chart-configuration-examples}

### extraEnv {#extraenv}

`extraEnv`を使用すると、ポッド内のすべてのコンテナに追加の環境変数を公開できます。

`extraEnv`の使用例を以下に示します:

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

コンテナが起動されると、環境変数が公開されていることを確認できます:

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`を使用すると、内のすべてので、他のデータソースからの追加のを公開できます。

`extraEnvFrom`の使用例を以下に示します:

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
  CONFIG_STRING:
    configMapKeyRef:
      name: useful-config
      key: some-string
      # optional: boolean
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに対して認証して、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法の詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)を参照してください。

`pullSecrets`の使用例を以下に示します:

```yaml
image:
  repository: my.shell.repository
  tag: latest
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  型   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountの注釈。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのをにマウントするかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定されていない場合、チャートのフルネームが使用されます。 |

### livenessProbe/readinessProbe {#livenessprobereadinessprobe}

`deployment.livenessProbe`と`deployment.readinessProbe`は、一部のシナリオでポッドの終了を制御するのに役立つメカニズムを提供します。

大規模なリポジトリは、通常実行時間の長い接続に一致するように、livenessプローブとreadinessプローブの時間を調整するとメリットがあります。`clone`および`push`操作中の潜在的な中断を最小限に抑えるために、readinessプローブの期間をlivenessプローブの期間よりも短く設定します。`terminationGracePeriodSeconds`を増やし、スケジューラがポッドを終了する前に、これらの操作により多くの時間を与えます。より大きなリポジトリのワークロードで安定性と効率性を高めるために、GitLab Shellポッドを調整するための開始ポイントとして、以下の例を検討してください。

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
  terminationGracePeriodSeconds: 300
```

この構成に関する追加の詳細については、公式の[Kubernetesドキュメント](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)を参照してください。

### tolerations {#tolerations}

`tolerations`を使用すると、taintされたワーカーノードでポッドをスケジュールできます

`tolerations`の使用例を以下に示します:

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

### affinity {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。

### annotations {#annotations}

`annotations`を使用すると、注釈をGitLab Shellポッドに追加できます。

`annotations`の使用例を以下に示します。

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## 外部サービス {#external-services}

このチャートは、Workhorseサービスに接続する必要があります。

### Workhorse {#workhorse}

```yaml
workhorse:
  host: workhorse.example.com
  serviceName: webservice
  port: 8181
```

| 名前          |  型   | デフォルト      | 説明 |
|:--------------|:-------:|:-------------|:------------|
| `host`        | 文字列  |              | Workhorseサーバーのホスト名。`serviceName`の代わりとして省略できます。 |
| `port`        | 整数 | `8181`       | Workhorseサーバーに接続するポート。 |
| `serviceName` | 文字列  | `webservice` | Workhorseサーバーを操作している`service`の名前。デフォルトでは、Workhorseはwebserviceポッド / Serviceの一部です。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名（および現在の`.Release.Name`）をテンプレート処理します。これは、を全体の一部として使用する場合に便利です。 |

## チャートの設定 {#chart-settings}

次の値は、GitLab Shellポッドを構成するために使用されます。

### hostKeys.secret {#hostkeyssecret}

SSHホストキーを取得するKubernetes `secret`の名前。シークレット内のキーは、GitLab Shellで使用するために、キー名`ssh_host_`で始まる必要があります。

### authToken {#authtoken}

GitLab Shellは、Workhorseとの通信で認証トークンを使用します。共有シークレットを使用して、GitLab ShellおよびWorkhorseとトークンを共有します。

```yaml
authToken:
 secret: gitlab-shell-secret
 key: secret
```

| 名前               |  型  | デフォルト | 説明 |
|:-------------------|:------:|:--------|:------------|
| `authToken.key`    | 文字列 |         | は、上記ののうちを含むの名前を定義します。 |
| `authToken.secret` | 文字列 |         | `Secret`は、プル元のの名前を定義します。 |

### ロードバランサーサービス {#loadbalancer-service}

`service.type`が`LoadBalancer`に設定されている場合は、オプションで`service.loadBalancerIP`を指定して、ユーザー指定のIPで`LoadBalancer`を作成できます（クラウドクラウドプロバイダーがサポートしている場合）。

（クラウドプロバイダーがサポートしている場合）、`LoadBalancer`にアクセスできるCIDR範囲を制限するために、オプションで`service.loadBalancerSourceRanges`のリストを指定することもできます。

`LoadBalancer`サービスタイプの詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)を参照してください。

```yaml
service:
  type: LoadBalancer
  loadBalancerIP: 1.2.3.4
  loadBalancerSourceRanges:
  - 5.6.7.8/32
  - 10.0.0.0/8
```

### OpenSSHの追加設定 {#openssh-supplemental-configuration}

OpenSSHの`sshd`（`.sshDaemon: openssh`経由）を使用する場合、追加の設定を行う方法は2つあります。`.opensshd.supplemental_config`、および`/etc/ssh/sshd_config.d/*.conf`へのスニペットのマップ。

提供される設定は、_必ず_`sshd_config`の機能要件を満たしている必要があります。[マニュアルページ](https://man.openbsd.org/sshd_config)を必ずお読みください。

#### opensshd.supplemental_config {#opensshdsupplemental_config}

`.opensshd.supplemental_config`の内容は、コンテナ内の`sshd_config`ファイルの末尾に直接配置されます。この値は、複数行の文字列である必要があります。

例: `ssh-rsa`キー交換アルゴリズムを使用して、古いクライアントを有効にする。`ssh-rsa`などの非推奨アルゴリズムを有効にすると、[重大なセキュリティ脆弱性](https://www.openssh.com/txt/release-8.8)が発生することに注意してください。これらの変更により、公開されているGitLabインスタンスでの悪用の可能性が**大幅に拡大**します。

```yaml
opensshd:
    supplemental_config: |-
      HostKeyAlgorithms +ssh-rsa,ssh-rsa-cert-v01@openssh.com
      PubkeyAcceptedAlgorithms +ssh-rsa,ssh-rsa-cert-v01@openssh.com
      CASignatureAlgorithms +ssh-rsa
```

#### sshd_config.d {#sshd_configd}

`sshd`に完全な設定スニペットを提供するには、`/etc/ssh/sshd_config.d`にコンテンツをマウントし、ファイルが`*.conf`と一致するようにします。これらは、_後_デフォルトの設定に含まれており、アプリケーションがコンテナおよびチャート内で機能するために必要であることに注意してください。これらの値は、_しません_ `sshd_config`の内容をオーバーライドするのではなく、それらを拡張します。

例: `extraVolumes`および`extraVolumeMounts`を介して、ConfigMapの単一のアイテムをコンテナにマウントする:

```yaml
extraVolumes: |
  - name: gitlab-sshdconfig-extra
    configMap:
      name: gitlab-sshdconfig-extra

extraVolumeMounts: |
  - name: gitlab-sshdconfig-extra
    mountPath: /etc/ssh/sshd_config.d/extra.conf
    subPath: extra.conf
```

### `networkpolicy`の設定 {#configuring-the-networkpolicy}

このセクションでは、[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を制御します。この設定はオプションであり、特定のエンドポイントへのポッドのエグレスとIngressを制限するために使用されます。

| 名前              |  型   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | この設定により、`NetworkPolicy`が有効になります |
| `ingress.enabled` | ブール値 | `false` | `true`に設定すると、`Ingress`ネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのIngress接続がブロックされます。 |
| `ingress.rules`   |  配列  | `[]`    | Ingressポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>および以下の例を参照してください |
| `egress.enabled`  | ブール値 | `false` | `true`に設定すると、`Egress`ネットワークポリシーがアクティブになります。これにより、ルールが指定されていない限り、すべてのエグレス接続がブロックされます。 |
| `egress.rules`    |  配列  | `[]`    | エグレスポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>および以下の例を参照してください |

### ネットワークポリシー {#example-network-policy}

`gitlab-shell`サービスには、ポート22のIngress接続と、デフォルトのworkhorseポート8181へのさまざまなエグレス接続が必要です。この例では、次のネットワークポリシーを追加します:

- Ingressリクエストを許可します:
  - `nginx-ingress`ポッドからポート`2222`へ
  - `prometheus`ポッドからポート`9122`へ

    {{< alert type="note" >}}

    `prometheus`からポート`9122`へのアクセスは、SSHデーモンが`gitlab-sshd`に設定されている場合にのみ必要です

    {{< /alert >}}

- エグレスリクエストを許可します:
  - `webservice`ポッドからポート`8181`へ
  - `gitaly`ポッドからポート`8075`へ

_提供されている例は単なる例であり、完全ではない可能性があることに注意してください_

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
          - port: 2222
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
          - port: 9122
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
                app: webservice
        ports:
          - port: 8181
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

## KEDAの設定 {#configuring-keda}

この`keda`セクションでは、通常の`HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`のインストールを有効にします。この設定はオプションであり、カスタムメトリクスまたは外部メトリクスに基づいてオートスケールが必要な場合に使用できます。

ほとんどの設定は、該当する場合、`hpa`セクションで設定された値にデフォルト設定されます。

次が当てはまる場合、`hpa`セクションで設定されたCPUとメモリのしきい値に基づいて、CPUとメモリのトリガーが自動的に追加されます:

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定も、ゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの設定の詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  型   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーをチェックする間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | 最後のトリガーがアクティブであるとレポートされた後、リソースを0にスケールバックするまで待機する期間 |
| `minReplicaCount`               | 整数 | `minReplicas`                   | KEDAがリソースをスケールダウンする最小レプリカ数。 |
| `maxReplicaCount`               | 整数 | `maxReplicas`                   | KEDAがリソースをスケールアップする最大レプリカ数。 |
| `fallback`                      |   マップ   |                                 | KEDAフォールバック設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   | `hpa.behavior`                  | アップスケールとダウンスケールの動作の仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。`hpa.cpu`および`hpa.memory`から計算されたトリガーにデフォルト設定されます |

`keda`の使用例については、[`examples/keda/gitlab-shell.yml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/keda/gitlab-shell.yml)を参照してください。
