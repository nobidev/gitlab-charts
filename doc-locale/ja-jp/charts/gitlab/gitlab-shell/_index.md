---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Shellチャートの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

`gitlab-shell`サブチャートは、Git SSHアクセスをGitLabに対して行うように設定されたSSHサーバーを提供します。

## 要件 {#requirements}

このチャートは、Workhorseサービスへのアクセスに依存します。Workhorseサービスは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされるKubernetesクラスターからアクセス可能な外部サービスとして提供されます。

## 設計上の選択 {#design-choices}

SSHレプリカを容易にサポートし、SSH Authorized Keysに共有ストレージを使用することを避けるために、GitLab authorized keysエンドポイントに対して認証するために、SSH [AuthorizedKeysCommand](https://man.openbsd.org/sshd_config#AuthorizedKeysCommand)を使用しています。その結果、これらのポッド内のAuthorizedKeysファイルを永続化または更新することはありません。

## 設定 {#configuration}

`gitlab-shell`チャートは、[外部サービス](#external-services)と[チャート設定](#chart-settings)の2つの部分で構成されています。Ingressを介して公開されるポートは`global.shell.port`で設定され、デフォルトは`22`です。Serviceの外部ポートも`global.shell.port`によって制御されます。

## インストール コマンドライン オプション {#installation-command-line-options}

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                    | ポッド割り当ての[アフィニティルール](../_index.md#affinity) |
| `annotations`                                            |                                                         | Podアノテーション |
| `podLabels`                                              |                                                         | 補足的なPodラベル。セレクターには使用されません。 |
| `common.labels`                                          |                                                         | このチャートによって作成されたすべてのオブジェクトに適用される補足的なラベル。 |
| `config.ciphers`                                         | 説明をご覧ください。                                        | 許可されている暗号を指定します。デフォルトは`[aes128-gcm@openssh.com, chacha20-poly1305@openssh.com, aes256-gcm@openssh.com, aes128-ctr, aes192-ctr, aes256-ctr]`です。 |
| `config.kexAlgorithms`                                   | 説明をご覧ください。                                        | 利用可能なKEX（キー交換）アルゴリズムを指定します。デフォルトは`[curve25519-sha256, curve25519-sha256@libssh.org, ecdh-sha2-nistp256, ecdh-sha2-nistp384, ecdh-sha2-nistp521, diffie-hellman-group14-sha256, diffie-hellman-group14-sha1]`です。 |
| `config.macs`                                            | 説明をご覧ください。                                        | 利用可能なMAC（メッセージ認証コード）アルゴリズムを指定します。デフォルトは`[hmac-sha2-256-etm@openssh.com, hmac-sha2-512-etm@openssh.com, hmac-sha2-256, hmac-sha2-512, hmac-sha1]`です。 |
| `config.clientAliveInterval`                             | `0`                                                     | それ以外の場合はアイドル状態の接続でのキープアライブpingの間隔。デフォルト値の0は、このpingを無効にします |
| `config.loginGraceTime`                                  | `60`                                                    | ユーザーが正常にログインしなかった場合にサーバーが切断するまでの時間を指定します |
| `config.maxStartups.full`                                | `100`                                                   | SSHdの拒否確率は線形に増加し、認証されていない接続数が指定された数に達すると、認証されていないすべての接続試行が拒否されます |
| `config.maxStartups.rate`                                | `30`                                                    | 認証されていない接続が多すぎる場合、SSHdは指定された確率で接続を拒否します（オプション） |
| `config.maxStartups.start`                               | `10`                                                    | 現在、指定された数よりも多くの認証されていない接続がある場合、SSHdはある確率で接続試行を拒否します（オプション） |
| `config.proxyProtocol`                                   | `false`                                                 | `gitlab-sshd`デーモンのPROXYプロトコルサポートを有効にします |
| `config.proxyPolicy`                                     | `"use"`                                                 | PROXYプロトコルを処理するためのポリシーを指定します。値は、`use, require, ignore, reject`のいずれかである必要があります |
| `config.proxyHeaderTimeout`                              | `"500ms"`                                               | `gitlab-sshd`がPROXYプロトコルヘッダーの読み取りをあきらめるまで待機する最大時間。`ms`、`s`、または`m`の単位を含める必要があります。 |
| `config.publicKeyAlgorithms`                             | `[]`                                                    | 公開キーアルゴリズムのカスタムリスト。空の場合、デフォルトのアルゴリズムが使用されます。 |
| `config.gssapi.enabled`                                  | `false`                                                 | `gitlab-sshd`デーモンのGSS-APIサポートを有効にします |
| `config.gssapi.keytab.secret`                            |                                                         | gssapi-with-mic認証方式のkeytabを保持するKubernetesシークレットの名前 |
| `config.gssapi.keytab.key`                               | `keytab`                                                | Kubernetesシークレットでkeytabを保持するキー |
| `config.gssapi.krb5Config`                               |                                                         | GitLab Shellコンテナ内の`/etc/krb5.conf`ファイルの内容 |
| `config.gssapi.servicePrincipalName`                     |                                                         | `gitlab-sshd`デーモンで使用されるKerberosサービス名 |
| `config.lfs.pureSSHProtocol`                             | `false`                                                 | LFS Pure SSHプロトコルサポートを有効にします |
| `config.pat.enabled`                                     | `true`                                                  | SSHを使用したPATを有効にします |
| `config.pat.allowedScopes`                               | `[]`                                                    | SSHで生成されたPATに許可されるスコープの配列 |
| `opensshd.supplemental_config`                           |                                                         | 補足設定は、`sshd_config`に追加されます。[man page](https://manpages.debian.org/bookworm/openssh-server/sshd_config.5.en.html)に厳密に準拠 |
| `deployment.livenessProbe.initialDelaySeconds`           | `10`                                                    | livenessプローブが開始されるまでの遅延 |
| `deployment.livenessProbe.periodSeconds`                 | `10`                                                    | livenessプローブを実行する頻度 |
| `deployment.livenessProbe.timeoutSeconds`                | `3`                                                     | livenessプローブがタイムアウトすると |
| `deployment.livenessProbe.successThreshold`              | `1`                                                     | 失敗した後、livenessプローブが成功したと見なされるための最小連続成功数 |
| `deployment.livenessProbe.failureThreshold`              | `3`                                                     | 成功した後、livenessプローブが失敗したと見なされるための最小連続失敗数 |
| `deployment.readinessProbe.initialDelaySeconds`          | `10`                                                    | readinessプローブが開始されるまでの遅延 |
| `deployment.readinessProbe.periodSeconds`                | `5`                                                     | readinessプローブを実行する頻度 |
| `deployment.readinessProbe.timeoutSeconds`               | `3`                                                     | readinessプローブがタイムアウトすると |
| `deployment.readinessProbe.successThreshold`             | `1`                                                     | 失敗した後、readinessプローブが成功したと見なされるための最小連続成功数 |
| `deployment.readinessProbe.failureThreshold`             | `2`                                                     | 成功した後、readinessプローブが失敗したと見なされるための最小連続失敗数 |
| `deployment.strategy`                                    | `{}`                                                    | デプロイメントで使用される更新ストラテジを構成できます |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                    | Kubernetesがポッドの強制終了を待機する秒数 |
| `enabled`                                                | `true`                                                  | Shell有効フラグ |
| `extraContainers`                                        |                                                         | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列 |
| `extraInitContainers`                                    |                                                         | 含める追加のinitコンテナのリスト |
| `extraVolumeMounts`                                      |                                                         | 実行する追加のボリュームマウントのリスト |
| `extraVolumes`                                           |                                                         | 作成する追加のボリュームのリスト |
| `extraEnv`                                               |                                                         | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                         | 公開する他のデータソースからの追加の環境変数のリスト |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`       | Behaviorには、スケールアップおよびスケールダウンの動作の仕様が含まれています（`autoscaling/v2beta2`以上が必要です） |
| `hpa.customMetrics`                                      | `[]`                                                    | カスタムメトリクスには、目的のレプリカ数を計算するために使用する仕様が含まれています（`targetAverageUtilization`で構成された平均CPU使用率のデフォルトの使用をオーバーライドします） |
| `hpa.cpu.targetType`                                     | `AverageValue`                                          | オートスケールCPUターゲットタイプを設定します。これは、`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.cpu.targetAverageValue`                             | `100m`                                                  | オートスケールCPUターゲット値を設定します |
| `hpa.cpu.targetAverageUtilization`                       |                                                         | オートスケールCPUターゲット使用率を設定します |
| `hpa.memory.targetType`                                  |                                                         | オートスケールメモリーターゲットタイプを設定します。これは、`Utilization`または`AverageValue`のいずれかである必要があります |
| `hpa.memory.targetAverageValue`                          |                                                         | オートスケールメモリーターゲット値を設定します |
| `hpa.memory.targetAverageUtilization`                    |                                                         | オートスケールメモリーターゲット使用率を設定します |
| `hpa.targetAverageValue`                                 |                                                         | **非推奨**オートスケールCPUターゲット値を設定します |
| `image.pullPolicy`                                       | `IfNotPresent`                                          | Shellイメージプルポリシー |
| `image.pullSecrets`                                      |                                                         | イメージリポジトリのシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-shell` | Shellイメージリポジトリ |
| `image.tag`                                              | `master`                                                | Shellイメージtag |
| `init.image.repository`                                  |                                                         | initContainerイメージ |
| `init.image.tag`                                         |                                                         | initContainerイメージtag |
| `init.containerSecurityContext`                          |                                                         | initContainer固有の[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                 | initContainer固有:プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                  | initContainer固有:コンテナが非rootユーザーで実行されるかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                             | initContainer固有:コンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `keda.enabled`                                           | `false`                                                 | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `keda.pollingInterval`                                   | `30`                                                    | 各トリガーをチェックする間隔 |
| `keda.cooldownPeriod`                                    | `300`                                                   | リソースを0にスケールバックする前に、最後のトリガーがアクティブを報告した後で待機する期間 |
| `keda.minReplicaCount`                                   | `minReplicas`                                           | KEDAがリソースをスケールダウンするレプリカの最小数。 |
| `keda.maxReplicaCount`                                   | `maxReplicas`                                           | KEDAがリソースをスケールアップするレプリカの最大数。 |
| `keda.fallback`                                          |                                                         | KEDAフォールバック設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                         | KEDAが作成するHPAリソースの名前。 |
| `keda.restoreToOriginalReplicaCount`                     |                                                         | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `keda.behavior`                                          | `hpa.behavior`                                          | スケールアップおよびスケールダウンの動作の仕様。 |
| `keda.triggers`                                          |                                                         | ターゲットリソースのスケーリングをアクティブ化するトリガーのリスト。デフォルトでは、`hpa.cpu`および`hpa.memory`から計算されたトリガー |
| `logging.format`                                         | `json`                                                  | 非構造化ログの場合は`text`に設定 |
| `logging.sshdLogLevel`                                   | `ERROR`                                                 | 基盤となるSSHデーモンのログレベル |
| `priorityClassName`                                      |                                                         | ポッドに割り当てられた[優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |
| `replicaCount`                                           | `1`                                                     | Shellレプリカ |
| `serviceLabels`                                          | `{}`                                                    | 補足サービスラベル |
| `service.allocateLoadBalancerNodePorts`                  | Kubernetesのデフォルト値を使用するように設定されていません。               | ロードバランサーサービスでNodePort割り当てを無効にすることができます。[ドキュメント](https://kubernetes.io/docs/concepts/services-networking/service/#load-balancer-nodeport-allocation)を参照してください |
| `service.externalTrafficPolicy`                          | `Cluster`                                               | Shellサービス外部トラフィックポリシー（クラスターまたはローカル） |
| `service.internalPort`                                   | `2222`                                                  | Shell内部ポート |
| `service.nodePort`                                       |                                                         | 設定されている場合は、shell nodePortを設定します |
| `service.name`                                           | `gitlab-shell`                                          | Shellサービス名 |
| `service.type`                                           | `ClusterIP`                                             | Shellサービスタイプ |
| `service.loadBalancerIP`                                 |                                                         | ロードバランサーに割り当てるIPアドレス（サポートされている場合） |
| `service.loadBalancerSourceRanges`                       |                                                         | ロードバランサーへのアクセスを許可されたIP CIDRのリスト（サポートされている場合） |
| `serviceAccount.annotations`                             | `{}`                                                    | ServiceAccountアノテーション |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                 | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                 | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                 | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                         | ServiceAccountの名前。設定されていない場合、完全なチャート名が使用されます |
| `securityContext.fsGroup`                                | `1000`                                                  | ポッドを開始するグループID |
| `securityContext.runAsUser`                              | `1000`                                                  | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                                         | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                        | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                         | コンテナが開始される[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `containerSecurityContext.runAsUser`                     | `1000`                                                  | コンテナが開始される特定のsecurity contextを上書きできます |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                 | コンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                  | コンテナが非rootユーザーで実行されるかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                             | Gitalyコンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `sshDaemon`                                              | `openssh`                                               | 実行するSSHデーモンを選択します。使用可能な値（`openssh`、`gitlab-sshd`） |
| `tolerations`                                            | `[]`                                                    | ポッド割り当てのTolerationラベル |
| `traefik.entrypoint`                                     | `gitlab-shell`                                          | traefikを使用する場合、GitLab Shellに使用するtraefikエントリポイント。デフォルトは`gitlab-shell`です |
| `traefik.tcpMiddlewares`                                 | `[]`                                                    | traefikを使用する場合、IngressRouteTCPリソースに追加するTCPミドルウェア。デフォルトではミドルウェアはありません |
| `workhorse.serviceName`                                  | `webservice`                                            | Workhorseサービス名（デフォルトでは、Workhorseはwebservice Pod / Serviceの一部です） |
| `metrics.enabled`                                        | `false`                                                 | メトリクスのスクレイピングに使用できるメトリクスエンドポイントを作成する必要がある場合（`sshDaemon=gitlab-sshd`が必要です）。 |
| `metrics.port`                                           | `9122`                                                  | メトリクスエンドポイントポート |
| `metrics.path`                                           | `/metrics`                                              | メトリクスエンドポイントパス |
| `metrics.serviceMonitor.enabled`                         | `false`                                                 | Prometheus Operatorがメトリクスのスクレイピングを管理できるようにServiceMonitorを作成する必要がある場合、これを有効にすると`prometheus.io`スクレイピングアノテーションが削除されることに注意してください |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                    | ServiceMonitorに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                    | ServiceMonitorの追加のエンドポイント設定 |
| `metrics.annotations`                                    |                                                         | **非推奨**明示的なメトリクスアノテーションを設定します。テンプレートコンテンツに置き換えられました。 |

## チャート設定の例 {#chart-configuration-examples}

### extraEnv {#extraenv}

`extraEnv`を使用すると、ポッド内のすべてのコンテナで追加の環境変数を公開できます。

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

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナで、他のデータソースからの追加の環境変数を公開できます。

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
  CONFIG_STRING:
    configMapKeyRef:
      name: useful-config
      key: some-string
      # optional: boolean
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets`を使用すると、プライベートレジストリに対して認証して、ポッドのイメージをプルできます。

プライベートレジストリとその認証方法に関する追加の詳細は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)にあります。

以下は、`pullSecrets`の使用例です。

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

| 名前                           |  タイプ   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountアノテーション。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。特定のサイドカーが適切に動作するために必要な場合を除き、これを有効にしないでください（たとえば、Istio）。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定されていない場合、完全なチャート名が使用されます。 |

### livenessProbe/readinessProbe {#livenessprobereadinessprobe}

`deployment.livenessProbe`および`deployment.readinessProbe`は、一部のシナリオでPodの終了を制御するのに役立つメカニズムを提供します。

大規模なリポジトリでは、livenessプローブとreadinessプローブの時間を調整して、一般的な長時間実行接続に一致させると効果的です。`clone`および`push`操作中の潜在的な中断を最小限に抑えるために、readinessプローブの期間をlivenessプローブの期間よりも短く設定します。`terminationGracePeriodSeconds`を増やし、スケジューラーがポッドを終了する前に、これらの操作により多くの時間を与えます。より大きなリポジトリワークロードで安定性と効率を高めるためにGitLab Shellポッドを調整するための開始点として、以下の例を検討してください。

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

### affinity {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。

### annotations {#annotations}

`annotations`を使用すると、アノテーションをGitLab Shellポッドに追加できます。

以下は、`annotations`の使用例です

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## 外部サービス {#external-services}

このチャートは、Workhorseサービスにアタッチする必要があります。

### Workhorse {#workhorse}

```yaml
workhorse:
  host: workhorse.example.com
  serviceName: webservice
  port: 8181
```

| 名前          |  タイプ   | デフォルト      | 説明 |
|:--------------|:-------:|:-------------|:------------|
| `host`        | 文字列  |              | Workhorseサーバーのホスト名。これは、`serviceName`の代わりに省略できます。 |
| `port`        | 整数 | `8181`       | Workhorseサーバーに接続するポート。 |
| `serviceName` | 文字列  | `webservice` | Workhorseサーバーを操作している`service`の名前。デフォルトでは、Workhorseはwebservice Pod / Serviceの一部です。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりに、サービス（および現在の`.Release.Name`）のホスト名をテンプレート化します。これは、Workhorseを全体のGitLabチャートの一部として使用する場合に便利です。 |

## チャート設定 {#chart-settings}

次の値は、GitLab Shell Podを構成するために使用されます。

### hostKeys.secret {#hostkeyssecret}

SSHホストキーを取得するKubernetes `secret`の名前。シークレット内のキーは、GitLab Shellで使用されるために、キー名`ssh_host_`で始まる必要があります。

### authToken {#authtoken}

GitLab Shellは、Workhorseとの通信で認証トークンを使用します。共有シークレットを使用して、GitLab ShellとWorkhorseでトークンを共有します。

```yaml
authToken:
 secret: gitlab-shell-secret
 key: secret
```

| 名前               |  タイプ  | デフォルト | 説明 |
|:-------------------|:------:|:--------|:------------|
| `authToken.key`    | 文字列 |         | 上記のシークレットに含まれる認証トークンを含むキーの名前。 |
| `authToken.secret` | 文字列 |         | 取得元のKubernetes `Secret`の名前。 |

### LoadBalancer Service {#loadbalancer-service}

`service.type`が`LoadBalancer`に設定されている場合、オプションで`service.loadBalancerIP`を指定して、ユーザー指定のIPで`LoadBalancer`を作成できます (クラウドプロバイダーがサポートしている場合)。

また、オプションで`service.loadBalancerSourceRanges`のリストを指定して、`LoadBalancer`にアクセスできるCIDR範囲を制限できます (クラウドプロバイダーがサポートしている場合)。

`LoadBalancer`サービスタイプの詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)を参照してください。

```yaml
service:
  type: LoadBalancer
  loadBalancerIP: 1.2.3.4
  loadBalancerSourceRanges:
  - 5.6.7.8/32
  - 10.0.0.0/8
```

### OpenSSH補足設定 {#openssh-supplemental-configuration}

OpenSSHの`sshd` ( `.sshDaemon: openssh`経由) を使用する場合、`.opensshd.supplemental_config`と、`/etc/ssh/sshd_config.d/*.conf`への設定スニペットのマウントという2つの方法で補足設定を提供できます。

指定された設定はすべて、`sshd_config`の機能_要件_を満たしている_必要_があります。[マニュアル](https://man.openbsd.org/sshd_config)ページを[必ず](https://man.openbsd.org/sshd_config)お読みください。

#### opensshd.supplemental_config {#opensshdsupplemental_config}

`.opensshd.supplemental_config`の内容は、コンテナ内の`sshd_config`ファイルの末尾に直接配置されます。この値は、複数行の文字列である必要があります。

`ssh-rsa`キー交換アルゴリズムを使用する古いクライアントを有効にする例。`ssh-rsa`などの[非推奨](https://www.openssh.com/txt/release-8.8)のアルゴリズムを有効にすると、[重大なセキュリティの脆弱性](https://www.openssh.com/txt/release-8.8)が発生することに注意してください。これらの変更により、公開されているGitLab **インスタンス**で悪用される**可能性**が**大幅に高まり**ます。

```yaml
opensshd:
    supplemental_config: |-
      HostKeyAlgorithms +ssh-rsa,ssh-rsa-cert-v01@openssh.com
      PubkeyAcceptedAlgorithms +ssh-rsa,ssh-rsa-cert-v01@openssh.com
      CASignatureAlgorithms +ssh-rsa
```

#### sshd_config.d {#sshd_configd}

`/etc/ssh/sshd_config.d`にコンテンツをマウントして`sshd`に完全な設定スニペットを提供できます。ファイルは`*.conf`に一致します。これらは、コンテナ内および_チャート_内でアプリケーションが_機能_するために_必要_なデフォルト設定_後_に含まれていることに注意してください。これらの値は`sshd_config`の_内容_を_上書き_しませんが、拡張します。

`extraVolumes`および`extraVolumeMounts`を介して、ConfigMapの単一のアイテムをコンテナにマウントする例:

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

このセクションでは、[NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/)を[制御](https://kubernetes.io/docs/concepts/services-networking/network-policies/)します。この設定はオプションであり、特定のエンドポイントに対するポッドのエグレスとIngressを制限するために使用されます。

| 名前              |  タイプ   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | この設定は`NetworkPolicy`を有効にします |
| `ingress.enabled` | ブール値 | `false` | `true`に設定すると、`Ingress`ネットワークポリシーが有効になります。これにより、ルールが指定されていない限り、すべてのIngress接続がブロックされます。 |
| `ingress.rules`   |  配列  | `[]`    | Ingressポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください |
| `egress.enabled`  | ブール値 | `false` | `true`に設定すると、`Egress`ネットワークポリシーが有効になります。これにより、ルールが指定されていない限り、すべてのエグレス接続がブロックされます。 |
| `egress.rules`    |  配列  | `[]`    | エグレスポリシーのルール。詳細については、<https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource>と以下の例を参照してください |

### ネットワークポリシーの例 {#example-network-policy}

`gitlab-shell`サービスには、ポート22のIngress接続と、デフォルトのWorkhorseポート8181へのさまざまなエグレス接続が必要です。この例では、次のネットワークポリシーを追加します。

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

この`keda`セクションでは、[KEDA](https://keda.sh/) `ScaledObjects`を通常の`HorizontalPodAutoscalers`の代わりにインストールできます。この設定はオプションであり、カスタムまたは外部メトリクスに基づいてオートスケールが必要な場合に使用できます。

ほとんどの設定は、`hpa`セクションで設定された値にデフォルトで設定されます(該当する場合)。

次の条件が満たされる場合、`hpa`セクションで設定されたCPUおよびメモリーのしきい値に基づいて、CPUおよびメモリーのトリガーが自動的に追加されます。

- `triggers`が設定されていません。
- 対応する`request.cpu.request`または`request.memory.request`設定もゼロ以外の値に設定されています。

トリガーが設定されていない場合、`ScaledObject`は作成されません。

これらの設定の詳細については、[KEDAドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/)を参照してください。

| 名前                            |  タイプ   | デフォルト                         | 説明 |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | ブール値 | `false`                         | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用する |
| `pollingInterval`               | 整数 | `30`                            | 各トリガーのチェック間隔 |
| `cooldownPeriod`                | 整数 | `300`                           | リソースを0にスケールバックする前に、最後のアクティブなトリガーがレポートされてから待機する期間 |
| `minReplicaCount`               | 整数 | `minReplicas`                   | KEDAがリソースをスケールダウンするレプリカの最小数。 |
| `maxReplicaCount`               | 整数 | `maxReplicas`                   | KEDAがリソースをスケールアップするレプリカの最大数。 |
| `fallback`                      |   マップ   |                                 | KEDAフォールバック設定については、[ドキュメント](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback)を参照してください |
| `hpaName`                       | 文字列  | `keda-hpa-{scaled-object-name}` | KEDAが作成するHPAリソースの名前。 |
| `restoreToOriginalReplicaCount` | ブール値 |                                 | `ScaledObject`が削除された後、ターゲットリソースを元のレプリカ数にスケールバックするかどうかを指定します |
| `behavior`                      |   マップ   | `hpa.behavior`                  | スケールアップとスケールダウンの動作の仕様。 |
| `triggers`                      |  配列  |                                 | ターゲットリソースのスケーリングをアクティブにするトリガーのリスト。`hpa.cpu`と`hpa.memory`から計算されたトリガーにデフォルト設定されます |

`keda`の使用例については、[`examples/keda/gitlab-shell.yml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/keda/gitlab-shell.yml)を[参照](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/keda/gitlab-shell.yml)してください。
