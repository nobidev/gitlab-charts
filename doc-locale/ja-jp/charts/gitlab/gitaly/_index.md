---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab-Gitalyチャートの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

`gitaly`サブチャートは、Gitalyサーバーの設定可能なデプロイメントを提供します。

## 要件 {#requirements}

このチャートは、完全なGitLabチャートの一部として、またはこのチャートがデプロイされるKubernetesクラスターから到達可能な外部サービスとして提供される、Workhorseサービスへのアクセスに依存します。

## 設計上の選択 {#design-choices}

このチャートで使用されているGitalyコンテナには、まだGitalyに移植されていないGitリポジトリに対してアクションを実行するために、GitLab Shellのコードベースも含まれています。Gitalyコンテナには、GitLab Shellコンテナのコピーが含まれており、その結果、このチャート内でGitLab Shellも設定する必要があります。

## 構成 {#configuration}

`gitaly`チャートは、[外部サービス](#external-services)と[チャート設定](#chart-settings)の2つの部分で構成されています。

Gitalyは、デフォルトでGitLabチャートをデプロイする際のコンポーネントとしてデプロイされます。Gitalyを個別にデプロイする場合は、`global.gitaly.enabled`を`false`に設定する必要があり、[外部Gitalyドキュメント](../../../advanced/external-gitaly/_index.md)に記載されているように追加の構成を実行する必要があります。

### インストールコマンドラインオプション {#installation-command-line-options}

以下の表に、`--set`フラグを使用して`helm install`コマンドに指定できる、可能性のあるすべてのチャート構成を示します。

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `annotations`                                            |                                                         | Podアノテーション |
| `backup.goCloudUrl`                                      |                                                         | [サーバー側のGitalyバックアップ](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)のオブジェクトストレージURL。 |
| `common.labels`                                          | `{}`                                                    | このチャートによって作成されたすべてのオブジェクトに適用される補足ラベル。 |
| `podLabels`                                              |                                                         | 補足的なPodラベル。セレクターには使用されません。 |
| `external[].hostname`                                    | `- ""`                                                  | 外部ノードのホスト名 |
| `external[].name`                                        | `- ""`                                                  | 外部ノードストレージの名前 |
| `external[].port`                                        | `- ""`                                                  | 外部ノードのポート |
| `extraContainers`                                        |                                                         | 含めるコンテナのリストを含む複数行のリテラルスタイル文字列 |
| `extraInitContainers`                                    |                                                         | 含める追加のinitコンテナのリスト |
| `extraVolumeMounts`                                      |                                                         | 実行する追加のボリュームマウントのリスト |
| `extraVolumes`                                           |                                                         | 作成する追加のボリュームのリスト |
| `extraEnv`                                               |                                                         | 公開する追加の環境変数のリスト |
| `extraEnvFrom`                                           |                                                         | 公開する他のデータソースからの追加の環境変数のリスト |
| `gitaly.serviceName`                                     |                                                         | 生成されたGitalyサービスの名前。`global.gitaly.serviceName`をオーバーライドし、デフォルトは`<RELEASE-NAME>-gitaly` |
| `gpgSigning.enabled`                                     | `false`                                                 | [Gitaly GPG署名](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)を使用するかどうか。 |
| `gpgSigning.secret`                                      |                                                         | Gitaly GPG署名に使用されるシークレットの名前。 |
| `gpgSigning.key`                                         |                                                         | GitalyのGPG署名キーを含むGPGシークレットのキー。 |
| `image.pullPolicy`                                       | `Always`                                                | Gitalyイメージのプルポリシー |
| `image.pullSecrets`                                      |                                                         | イメージリポジトリのシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitaly`       | Gitalyイメージリポジトリ |
| `image.tag`                                              | `master`                                                | Gitalyイメージタグ |
| `init.image.repository`                                  |                                                         | initContainerイメージ |
| `init.image.tag`                                         |                                                         | initContainerイメージタグ |
| `init.containerSecurityContext`                          |                                                         | initContainer固有の[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                 | initContainer固有:プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                  | initContainer固有:コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                             | initContainer固有:コンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `internal.names[]`                                       | `- default`                                             | StatefulSetストレージの順序付けられた名前 |
| `serviceLabels`                                          | `{}`                                                    | 補足サービスラベル |
| `service.externalPort`                                   | `8075`                                                  | Gitalyサービスが公開するポート |
| `service.internalPort`                                   | `8075`                                                  | Gitalyの内部ポート |
| `service.name`                                           | `gitaly`                                                | GitalyがServiceオブジェクトの背後にあるServiceポートの名前。 |
| `service.type`                                           | `ClusterIP`                                             | Gitalyサービスタイプ |
| `service.clusterIP`                                      | `None`                                                  | Service作成リクエストの一部として、独自のクラスターIPアドレスを指定できます。これは、KubernetesのServiceオブジェクトのclusterIPと同じ規則に従います。`service.type`がLoadBalancerの場合、これは設定しないでください。 |
| `service.loadBalancerIP`                                 |                                                         | 設定されていない場合は、一時的なIPアドレスが作成されます。これは、KubernetesのServiceオブジェクトのloadbalancerIP構成と同じ規則に従います。 |
| `serviceAccount.annotations`                             | `{}`                                                    | ServiceAccountアノテーション |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                 | デフォルトのServiceAccountアクセストークンをPodにマウントするかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                 | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                 | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.name`                                    |                                                         | ServiceAccountの名前。設定しない場合、完全なチャート名が使用されます |
| `securityContext.fsGroup`                                | `1000`                                                  | Podを開始するグループID |
| `securityContext.fsGroupChangePolicy`                    |                                                         | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.runAsUser`                              | `1000`                                                  | Podを開始するユーザーID |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                        | 使用するSeccompプロファイル |
| `shareProcessNamespace`                                  | `false`                                                 | コンテナプロセスを同じPod内の他のすべてのコンテナに表示できるようにします |
| `containerSecurityContext`                               |                                                         | Gitalyコンテナが開始されるコンテナ[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をオーバーライドします |
| `containerSecurityContext.runAsUser`                     | `1000`                                                  | Gitalyコンテナが起動される特定のセキュリティコンテキストユーザーIDのオーバーライドを許可します |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                 | Gitalyコンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                  | Gitalyコンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                             | Gitalyコンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `tolerations`                                            | `[]`                                                    | Podの割り当ての容認ラベル |
| `affinity`                                               | `{}`                                                    | Pod割り当ての[アフィニティルール](../_index.md#affinity) |
| `persistence.accessMode`                                 | `ReadWriteOnce`                                         | Gitaly永続性アクセスモード |
| `persistence.annotations`                                |                                                         | Gitaly永続性アノテーション |
| `persistence.enabled`                                    | `true`                                                  | Gitaly永続性フラグを有効にする |
| `persistance.labels`                                     |                                                         | Gitaly永続性ラベル |
| `persistence.matchExpressions`                           |                                                         | バインドするラベル式の一致 |
| `persistence.matchLabels`                                |                                                         | バインドするラベル値の一致 |
| `persistence.size`                                       | `50Gi`                                                  | Gitaly永続ボリュームサイズ |
| `persistence.storageClass`                               |                                                         | プロビジョニングのstorageClassName |
| `persistence.subPath`                                    |                                                         | Gitaly永続ボリュームのマウントパス |
| `priorityClassName`                                      |                                                         | Gitaly StatefulSet priorityClassName |
| `logging.level`                                          |                                                         | ログレベル   |
| `logging.format`                                         | `json`                                                  | ログ形式  |
| `logging.sentryDsn`                                      |                                                         | Sentry DSN URL - Goサーバーからの例外 |
| `logging.sentryEnvironment`                              |                                                         | ログの生成に使用されるSentry環境 |
| `shell.concurrency[]`                                    |                                                         | 各RPCエンドポイントの並行処理。構成キーについては、[RPC並行処理の制限](https://docs.gitlab.com/administration/gitaly/concurrency_limiting/#limit-rpc-concurrency)と[RPC並行処理の適応性の有効化](https://docs.gitlab.com/administration/gitaly/concurrency_limiting/#enable-adaptiveness-for-rpc-concurrency)を参照してください。 |
| `packObjectsCache.enabled`                               | `false`                                                 | Gitaly pack-objectsキャッシュを有効にします |
| `packObjectsCache.dir`                                   | `/home/git/repositories/+gitaly/PackObjectsCache`       | キャッシュファイルが格納されるディレクトリ |
| `packObjectsCache.max_age`                               | `5m`                                                    | キャッシュエントリの有効期間 |
| `packObjectsCache.min_occurrences`                       | `1`                                                     | キャッシュエントリを作成するために必要な最小カウント |
| `git.catFileCacheSize`                                   |                                                         | Git cat-fileプロセスで使用されるキャッシュサイズ |
| `git.config[]`                                           | `[]`                                                    | GitalyがGitコマンドを起動するときに設定する必要があるGit設定 |
| `prometheus.grpcLatencyBuckets`                          |                                                         | Gitalyによって記録されるGRPCメソッド呼び出しのヒストグラムレイテンシーに対応するバケット。配列の文字列形式（たとえば、`"[1.0, 1.5, 2.0]"`）が入力として必要です |
| `statefulset.strategy`                                   | `{}`                                                    | StatefulSetで使用される更新ストラテジーを構成できます |
| `statefulset.livenessProbe.initialDelaySeconds`          | `0`                                                     | Livenessプローブが開始されるまでの遅延。startupProbeが有効になっている場合、これは0に設定されます。 |
| `statefulset.livenessProbe.periodSeconds`                | `10`                                                    | Livenessプローブを実行する頻度 |
| `statefulset.livenessProbe.timeoutSeconds`               | `3`                                                     | Livenessプローブがタイムアウトしたとき |
| `statefulset.livenessProbe.successThreshold`             | `1`                                                     | 失敗後にlivenessプローブが成功したと見なされるための最小連続成功数 |
| `statefulset.livenessProbe.failureThreshold`             | `3`                                                     | 成功後にlivenessプローブが失敗したと見なされるための最小連続失敗数 |
| `statefulset.readinessProbe.initialDelaySeconds`         | `0`                                                     | Readinessプローブが開始されるまでの遅延。startupProbeが有効になっている場合、これは0に設定されます。 |
| `statefulset.readinessProbe.periodSeconds`               | `5`                                                     | Readinessプローブを実行する頻度 |
| `statefulset.readinessProbe.timeoutSeconds`              | `3`                                                     | Readinessプローブがタイムアウトしたとき |
| `statefulset.readinessProbe.successThreshold`            | `1`                                                     | 失敗後にreadinessプローブが成功したと見なされるための最小連続成功数 |
| `statefulset.readinessProbe.failureThreshold`            | `3`                                                     | 成功後にreadinessプローブが失敗したと見なされるための最小連続失敗数 |
| `statefulset.startupProbe.enabled`                       | `true`                                                  | スタートアッププローブを有効にするかどうか。 |
| `statefulset.startupProbe.initialDelaySeconds`           | `1`                                                     | スタートアッププローブが開始されるまでの遅延 |
| `statefulset.startupProbe.periodSeconds`                 | `1`                                                     | スタートアッププローブを実行する頻度 |
| `statefulset.startupProbe.timeoutSeconds`                | `1`                                                     | スタートアッププローブがタイムアウトしたとき |
| `statefulset.startupProbe.successThreshold`              | `1`                                                     | 失敗後にスタートアッププローブが成功したと見なされるための最小連続成功数 |
| `statefulset.startupProbe.failureThreshold`              | `60`                                                    | 成功後にスタートアッププローブが失敗したと見なされるための最小連続失敗数 |
| `metrics.enabled`                                        | `false`                                                 | メトリクスのエンドポイントをスクレイピングに使用できるようにするかどうか |
| `metrics.port`                                           | `9236`                                                  | メトリクスのエンドポイントポート |
| `metrics.path`                                           | `/metrics`                                              | メトリクスのエンドポイントパス |
| `metrics.serviceMonitor.enabled`                         | `false`                                                 | Prometheus Operatorがメトリクスのスクレイピングを管理できるようにするためにServiceMonitorを作成するかどうか。これを有効にすると、`prometheus.io`スクレイプアノテーションが削除されることに注意してください |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                    | ServiceMonitorに追加する追加のラベル |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                    | ServiceMonitorの追加のエンドポイント構成 |
| `metrics.metricsPort`                                    |                                                         | **非推奨** `metrics.port`を使用します |
| `gomemlimit.enabled`                                     | `true`                                                  | この設定により、その制限も設定されている場合、Gitalyコンテナの`GOMEMLIMIT`環境変数が`resources.limits.memory`に自動的に設定されます。ユーザーは、この値をfalseに設定し、`extraEnv`で`GOMEMLIMIT`を設定することで、この値をオーバーライドできます。これは、[ドキュメント化された形式の基準](https://pkg.go.dev/runtime#hdr-Environment_Variables)を満たしている必要があります。 |
| `cgroups.enabled`                                        | `false`                                                 | Gitalyには、組み込みのcgroups制御があります。構成すると、Gitalyはが動作しているリポジトリに基づいて、プロセスをcgroupに割り当てます。このパラメータは、リポジトリのcgroupを有効にします。有効にした場合、cgroups v2のみがサポートされることに注意してください。 |
| `cgroups.initContainer.image.repository`                 | `registry.com/gitlab-org/build/cng/gitaly-init-cgroups` | Gitalyイメージリポジトリ |
| `cgroups.initContainer.image.tag`                        | `master`                                                | Gitalyイメージタグ |
| `cgroups.initContainer.image.pullPolicy`                 | `IfNotPresent`                                          | Gitalyイメージのプルポリシー |
| `cgroups.mountpoint`                                     | `/etc/gitlab-secrets/gitaly-pod-cgroup`                 | 親cgroupがマウントされている場所。 |
| `cgroups.hierarchyRoot`                                  | `gitaly`                                                | Gitalyがグループを作成する親cgroup。Gitalyが実行するユーザーとグループが所有することが想定されています。 |
| `cgroups.memoryBytes`                                    |                                                         | Gitalyがするすべてのプロセスにまとめて課せられる合計メモリ制限。0は制限がないことを意味します。 |
| `cgroups.cpuShares`                                      |                                                         | Gitalyがするすべてのプロセスにまとめて課せられるCPU制限。0は制限がないことを意味します。最大は1024シェアで、CPUの100％を表します。 |
| `cgroups.cpuQuotaUs`                                     |                                                         | cgroupのプロセスがこのクォータ値を超えた場合に、cgroupのプロセスをスロットルするために使用されます。cpuQuotaUsを100msに設定して、1コアが100000になるようにします。0は制限がないことを意味します。 |
| `cgroups.repositories.count`                             |                                                         | cgroupsプール内のcgroupの数。新しいがされるたびに、Gitalyはが対象とするリポジトリに基づいて、これらのcgroupの1つに割り当てます。巡回ハッシュアルゴリズムは、これらのcgroupにを割り当てるため、リポジトリのは常に同じcgroupに割り当てられます。 |
| `cgroups.repositories.memoryBytes`                       |                                                         | リポジトリcgroupに含まれるすべてのプロセスに課せられる合計メモリ制限。0は制限がないことを意味します。この値は、最上位のmemoryBytesの値を超えることはできません。 |
| `cgroups.repositories.cpuShares`                         |                                                         | リポジトリcgroupに含まれるすべてのプロセスに課せられるCPU制限。0は制限がないことを意味します。最大は1024シェアで、CPUの100％を表します。この値は、最上位のcpuSharesの値を超えることはできません。 |
| `cgroups.repositories.cpuQuotaUs`                        |                                                         | リポジトリcgroupに含まれるすべてのプロセスに課せられるcpuQuotaUs。プロセスは、指定されたクォータを超えることはできません。cpuQuotaUsを100msに設定して、1コアが100000になるようにします。0は制限がないことを意味します。 |
| `cgroups.repositories.maxCgroupsPerRepo`                 | `1`                                                     | 特定のリポジトリを対象とするプロセスを分散できるリポジトリcgroupの数。これにより、バースト的なを許可しながら、リポジトリcgroupに対してより保守的なCPUおよびメモリ制限を構成できます。たとえば、`2`の`maxCgroupsPerRepo`と10GBの`memoryBytes`制限がある場合、特定のリポジトリに対する独立したオペレーションは最大20GBのメモリを消費する可能性があります。 |
| `gracefulRestartTimeout`                                 | `25`                                                    | Gitalyシャットダウン猶予期間。インフライトが完了するまで待機する時間（秒）。Podの`terminationGracePeriodSeconds`は、この値+ 5秒に設定されます。 |
| `timeout.uploadPackNegotiation`                          |                                                         | [ネゴシエーションタイムアウトの構成](https://docs.gitlab.com/administration/settings/gitaly_timeouts/#configure-the-negotiation-timeouts)を参照してください。 |
| `timeout.uploadArchiveNegotiation`                       |                                                         | [ネゴシエーションタイムアウトの構成](https://docs.gitlab.com/administration/settings/gitaly_timeouts/#configure-the-negotiation-timeouts)を参照してください。 |
| `dailyMaintenance.disabled`                              |                                                         | 毎日のバックグラウンドメンテナンスを無効にすることができます。 |
| `dailyMaintenance.duration`                              |                                                         | 毎日のバックグラウンドメンテナンスの最大期間。たとえば、「1時間」または「45分」。 |
| `dailyMaintenance.startHour`                             |                                                         | 毎日のバックグラウンドメンテナンスの開始時間。 |
| `dailyMaintenance.startMinute`                           |                                                         | 毎日のバックグラウンドメンテナンスの開始時間。 |
| `dailyMaintenance.storages`                              |                                                         | 毎日のバックグラウンドメンテナンスを実行するストレージ名の配列。例：\[「default」]。 |
| `bundleUri.goCloudUrl`                                   |                                                         | [バンドルURIドキュメント](https://docs.gitlab.com/administration/gitaly/bundle_uris/)を参照してください。 |

## チャート構成の例 {#chart-configuration-examples}

### extraEnv {#extraenv}

`extraEnv`を使用すると、Pod内のすべてのコンテナで追加のを公開できます。

以下は、`extraEnv`の使用例です。

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

コンテナが開始されると、が公開されていることを確認できます。

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom`を使用すると、Pod内のすべてのコンテナで、他のデータソースからの追加のを公開できます。

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

`pullSecrets`を使用すると、プライベートに対してして、Podのイメージをプルできます。

プライベートとその方法に関する追加の詳細は、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)にあります。

以下は、`pullSecrets`の使用例です

```yaml
image:
  repository: my.gitaly.repository
  tag: latest
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

このセクションでは、ServiceAccountを作成するかどうか、およびデフォルトのアクセストークンをPodにマウントするかどうかを制御します。

| 名前                           |  タイプ   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   マップ   | `{}`    | ServiceAccountアノテーション。 |
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをPodにマウントするかどうかを制御します。特定のサイドカーが適切に機能するために（たとえば、Istio）、これを有効にする必要がない限り、有効にしないでください。 |
| `create`                       | ブール値 | `false` | ServiceAccountを作成するかどうかを示します。 |
| `enabled`                      | ブール値 | `false` | ServiceAccountを使用するかどうかを示します。 |
| `name`                         | 文字列  |         | ServiceAccountの名前。設定しない場合、完全なチャート名が使用されます。 |

### tolerations {#tolerations}

`tolerations`を使用すると、taintされたノードでPodをスケジュールできます

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

`annotations`を使用すると、Gitaly Podにアノテーションを追加できます。

以下は、`annotations`の使用例です。

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### priorityClassName {#priorityclassname}

`priorityClassName`を使用すると、Gitaly Podに[PriorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)をできます。

以下は、`priorityClassName`の使用例です。

```yaml
priorityClassName: persistence-enabled
```

### `git.config` {#gitconfig}

`git.config`を使用すると、Gitalyによってされたすべてのに構成を追加できます。`key` / `value`ペアで、`git-config(1)`に記載されている構成を受け入れます（以下を参照）。

```yaml
git:
  config:
    - key: "pack.threads"
      value: 4
    - key: "fsck.missingSpaceBeforeDate"
      value: ignore
```

### cgroups {#cgroups}

リソースの枯渇を防ぐために、Gitalyは**cgroups**を使用して、動作中のに基づいてプロセスをcgroupにします。各cgroupには、メモリとCPUの制限があり、システムの安定性を確保し、リソースの飽和を防ぎます。

Gitalyの起動前に実行される`initContainer`は、**rootとして実行**する必要があることに注意してください。このコンテナは、Gitalyがcgroupを管理できるように、権限を設定します。したがって、`/sys/fs/cgroup`への書き込みアクセス権を持つために、ファイルシステムにボリュームをマウントします。

[過剰サブスクリプションの例](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configuring-oversubscription)

```yaml
cgroups:
  enabled: true
  # Total limit across all repository cgroups
  memoryBytes: 64424509440 # 60GiB
  cpuShares: 1024
  cpuQuotaUs: 1200000 # 12 cores
  # Per repository limits, 1000 repository cgroups
  repositories:
    count: 1000
    memoryBytes: 32212254720 # 30GiB
    cpuShares: 512
    cpuQuotaUs: 400000 # 4 cores
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

| 名前          |  種類   | デフォルト      | 説明 |
|:--------------|:-------:|:-------------|:------------|
| `host`        | 文字列  |              | Workhorseサーバーのホスト名。これは、`serviceName`の代わりに省略できます。 |
| `port`        | 整数 | `8181`       | Workhorseサーバーへの接続に使用するポート。 |
| `serviceName` | 文字列  | `webservice` | WorkhorseサーバーをOperateしている`service`の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりに、サービス（および現在の`.Release.Name`）のホスト名をテンプレート化します。これは、Workhorseを全体的なGitLabチャートの一部として使用する場合に便利です。 |

## チャート設定 {#chart-settings}

以下の値は、Gitalyポッドの設定に使用されます。

{{< alert type="note" >}}

Gitalyは認証トークンを使用して、WorkhorseおよびSidekiqサービスで認証します。認証トークンのシークレットとキーは、`global.gitaly.authToken`値から取得されます。さらに、GitalyコンテナにはGitLab Shellのコピーがあり、設定できる設定がいくつかあります。Shellの認証トークンは、`global.shell.authToken`値から取得されます。

{{< /alert >}}

### Gitリポジトリの永続化 {#git-repository-persistence}

このチャートは、PersistentVolumeClaimをプロビジョニングし、Gitリポジトリ データに対応する永続ボリュームをマウントします。これが機能するには、Kubernetesクラスターで使用可能な物理ストレージが必要です。emptyDirを使用する場合は、`persistence.enabled: false`でPersistentVolumeClaimを無効にします。

{{< alert type="note" >}}

Gitalyの永続性の設定は、すべてのGitalyポッドに対して有効であるvolumeClaimTemplateで使用されます。単一の特定のボリューム（`volumeName`など）を参照するための*設定*を含めないでください。特定のボリュームを参照する場合は、PersistentVolumeClaimを手動でCreateする必要があります。

{{< /alert >}}

{{< alert type="note" >}}

これらの設定は、デプロイ後に変更できません。[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)では、`VolumeClaimTemplate`は不変です。{{< /alert >}}

```yaml
persistence:
  enabled: true
  storageClass: standard
  accessMode: ReadWriteOnce
  size: 50Gi
  matchLabels: {}
  matchExpressions: []
  subPath: "data"
  annotations: {}
```

| 名前               |  種類   | デフォルト         | 説明 |
|:-------------------|:-------:|:----------------|:------------|
| `accessMode`       | 文字列  | `ReadWriteOnce` | PersistentVolumeClaimでリクエストされたaccessModeを設定します。詳細については、[Kubernetes Access Modes Documentation](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes)を参照してください。 |
| `enabled`          | ブール値 | `true`          | リポジトリデータにPersistentVolumeClaimsを使用するかどうかを設定します。`false`の場合、emptyDirボリュームが使用されます。 |
| `matchExpressions` |  配列  |                 | バインドするボリュームを選択するときに照合するラベル条件オブジェクトの配列を受け入れます。これは、`PersistentVolumeClaim` `selector`セクションで使用されます。[ボリューム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)のドキュメントを参照してください。 |
| `matchLabels`      |   マップ   |                 | バインドするボリュームを選択するときに照合するラベル名とラベル値のマップを受け入れます。これは、`PersistentVolumeClaim` `selector`セクションで使用されます。[ボリューム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)のドキュメントを参照してください。 |
| `size`             | 文字列  | `50Gi`          | データの永続化のためにリクエストする最小ボリュームサイズ。 |
| `storageClass`     | 文字列  |                 | 動的プロビジョニングのために、ボリュームリクエストでstorageClassNameを設定します。設定解除されているかnullの場合、デフォルトのプロビジョニングツールが使用されます。ハイフンに設定すると、動的プロビジョニングが無効になります。 |
| `subPath`          | 文字列  |                 | ボリュームルートではなく、マウントするボリューム内のパスを設定します。subPathが空の場合、ルートが使用されます。 |
| `annotations`      |   マップ   |                 | 動的プロビジョニングのために、ボリュームリクエストでアノテーションを設定します。詳細については、[Kubernetes Annotations Documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/)を参照してください。 |

### TLS {#running-gitaly-over-tls}経由でGitalyを実行する

{{< alert type="note" >}}

このセクションでは、Helm Chartを使用してクラスター内で実行されているGitalyについて説明します。外部Gitaly [インスタンス](../../../advanced/external-gitaly/_index.md#connecting-to-external-gitaly-over-tls)を使用しており、TLSを使用して通信する場合は、[外部Gitalyのドキュメント](../../../advanced/external-gitaly/_index.md#connecting-to-external-gitaly-over-tls)を参照してください

{{< /alert >}}

Gitalyは、TLS経由で他のコンポーネントと通信することをサポートしています。これは、`global.gitaly.tls.enabled`および`global.gitaly.tls.secretName`の設定によって制御されます。TLS経由でGitalyを実行するには、次の手順に従います。

1. Helm Chartは、TLS経由でGitalyと通信するために証明書が提供されることを想定しています。この証明書は、存在するすべてのGitalyノードに適用される必要があります。したがって、これらの各Gitalyノードのすべてのホスト名を、証明書にサブジェクト代替名（SAN）として追加する必要があります。

   使用するホスト名を知るには、Toolboxポッドの`/srv/gitlab/config/gitlab.yml`ファイルを確認し、その中の`repositories.storages`キーの下に指定されているさまざまな`gitaly_address`フィールドを確認します。

   ```shell
   kubectl exec -it <Toolbox pod> -- grep gitaly_address /srv/gitlab/config/gitlab.yml
   ```

{{< alert type="note" >}}

内部Gitaly [ポッド](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/generate_certificates.sh)用のカスタム署名付き[証明書](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/generate_certificates.sh)を生成するための基本[スクリプト](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/generate_certificates.sh)は、[このリポジトリにあります](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/generate_certificates.sh)。ユーザーは、そのスクリプトを使用して、適切なSAN属性を持つ証明書を生成できます。

{{< /alert >}}

1. 作成された証明書を使用して、K8s TLSシークレットをCreateします。

   ```shell
   kubectl create secret tls gitaly-server-tls --cert=gitaly.crt --key=gitaly.key
   ```

1. `--set global.gitaly.tls.enabled=true`を渡すことにより、Helm Chartを再デプロイします。

### グローバルサーバーフック {#global-server-hooks}

Gitaly StatefulSetは、[グローバルサーバーフック](https://docs.gitlab.com/administration/server_hooks/#create-a-global-server-hook-for-all-repositories)を[サポート](https://docs.gitlab.com/administration/server_hooks/#create-a-global-server-hook-for-all-repositories)しています。フックスクリプトはGitalyポッドで実行されるため、[Gitalyコンテナ](https://gitlab.com/gitlab-org/build/CNG/-/blob/master/gitaly/Dockerfile)で使用可能なツールに制限されます。

[フック](https://kubernetes.io/docs/concepts/configuration/configmap/)は、[ConfigMap](https://kubernetes.io/docs/concepts/configuration/configmap/)を使用して[入力された](https://kubernetes.io/docs/concepts/configuration/configmap/)ものであり、必要に応じて次の値を設定することで使用できます。

1. `global.gitaly.hooks.preReceive.configmap`
1. `global.gitaly.hooks.postReceive.configmap`
1. `global.gitaly.hooks.update.configmap`

ConfigMapに入力するには、`kubectl`にスクリプトディレクトリを指定します。

```shell
kubectl create configmap MAP_NAME --from-file /PATH/TO/SCRIPT/DIR
```

### GitLab {#gpg-signing-commits-created-by-gitlab}でCreateされたGPG署名コミット

Gitalyは、GitLab [UI](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)（WebIDEなど）を[パス](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)して[Create](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)されたすべての[GPG](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)署名[コミット](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)、および[マージコミット](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)や[スカッシュ](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)など、GitLabで[Create](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)された[コミット](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)を[GPG](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits) [署名（する）](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits)できます。

1. GPGプライベートキーを使用して、k8sシークレットをCreateします。

   ```shell
   kubectl create secret generic gitaly-gpg-signing-key --from-file=signing_key=/path/to/gpg_signing_key.gpg
   ```

1. `values.yaml`でGPG署名（する）を有効にします。

   ```yaml
   gitlab:
     gitaly:
       gpgSigning:
         enabled: true
         secret: gitaly-gpg-signing-key
         key: signing_key
   ```

### サーバーバックアップ {#server-side-backups}

このチャートは、[Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)サーバーサイド[バックアップ](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)を[サポート](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)しています。使用するには：

1. バックアップを保存するバケットをCreateします。
1. オブジェクトストアの認証情報とストレージURLをConfigureします。

   ```yaml
   gitlab:
     gitaly:
       extraEnvFrom:
          # Mount the exisitign object store secret to the expected environment variables.
          AWS_ACCESS_KEY_ID:
            secretKeyRef:
              name: <Rails object store secret>
              key: aws_access_key_id
          AWS_SECRET_ACCESS_KEY:
            secretKeyRef:
              name: <Rails object store secret>
              key: aws_secret_access_key
       backup:
         # This is the connection string for Gitaly server side backups.
         goCloudUrl: <object store connection URL>
   ```

   予想される[環境変数](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)と[オブジェクト](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)ストレージ[バックエンド](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)のストレージURL形式については、[Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups)ドキュメントを参照してください。

1. [`backup-utility`でサーバーサイドバックアップを有効にする](../../../backup-restore/backup.md#server-side-repository-backups)。
