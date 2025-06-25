---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Toolbox
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

Toolboxポッドは、GitLabアプリケーション内で定期的なハウスキーピングタスクを実行するために使用されます。これらのタスクには、バックアップ、Sidekiqのメンテナンス、Rakeタスクが含まれます。

## 設定 {#configuration}

次の設定は、Toolboxチャートによって提供されるデフォルト設定です。

```yaml
gitlab:
  ## doc/charts/gitlab/toolbox
  toolbox:
    enabled: true
    replicas: 1
    backups:
      cron:
        enabled: false
        concurrencyPolicy: Replace
        failedJobsHistoryLimit: 1
        schedule: "0 1 * * *"
        successfulJobsHistoryLimit: 3
        suspend: false
        backoffLimit: 6
        safeToEvict: false
        restartPolicy: "OnFailure"
        resources:
          requests:
            cpu: 50m
            memory: 350M
        persistence:
          enabled: false
          accessMode: ReadWriteOnce
          useGenericEphemeralVolume: false
          size: 10Gi
      objectStorage:
        backend: s3
        config: {}
    persistence:
      enabled: false
      accessMode: 'ReadWriteOnce'
      size: '10Gi'
    resources:
      requests:
        cpu: '50m'
        memory: '350M'
    securityContext:
      fsGroup: '1000'
      runAsUser: '1000'
      runAsGroup: '1000'
    containerSecurityContext:
      runAsUser: '1000'
    affinity: {}
```

| パラメータ                                                | デフォルト                                                      | 説明 |
|----------------------------------------------------------|--------------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                         | ポッド割り当ての[アフィニティルール](../_index.md#affinity) |
| `annotations`                                            | `{}`                                                         | Toolboxポッドおよびジョブに追加するアノテーション |
| `common.labels`                                          | `{}`                                                         | このチャートで作成されたすべてのオブジェクトに適用される追加のラベル。 |
| `antiAffinityLabels.matchLabels`                         |                                                              | アンチアフィニティオプションを設定するためのラベル |
| `backups.cron.activeDeadlineSeconds`                     | `null`                                                       | バックアップCronジョブのアクティブなデッドライン秒数（nullの場合、アクティブなデッドラインは適用されません） |
| `backups.cron.ttlSecondsAfterFinished`                   | `null`                                                       | バックアップCronジョブが完了後に存続する時間（nullの場合、time to liveは適用されません） |
| `backups.cron.safeToEvict`                               | `false`                                                      | オートスケール対応のsafe-to-evictアノテーション |
| `backups.cron.backoffLimit`                              | `6`                                                          | バックアップCronジョブのバックオフ制限 |
| `backups.cron.concurrencyPolicy`                         | `Replace`                                                    | Kubernetesジョブの並行処理ポリシー |
| `backups.cron.enabled`                                   | `false`                                                      | バックアップCronジョブの有効フラグ |
| `backups.cron.extraArgs`                                 |                                                              | バックアップユーティリティに渡す引数の文字列 |
| `backups.cron.failedJobsHistoryLimit`                    | `1`                                                          | 履歴に表示する失敗したバックアップジョブの数 |
| `backups.cron.persistence.accessMode`                    | `ReadWriteOnce`                                              | バックアップcronの永続性アクセスモード |
| `backups.cron.persistence.enabled`                       | `false`                                                      | バックアップcronの永続性を有効にするフラグ |
| `backups.cron.persistence.matchExpressions`              |                                                              | バインドするラベル式のマッチ |
| `backups.cron.persistence.matchLabels`                   |                                                              | バインドするラベル値のマッチ |
| `backups.cron.persistence.useGenericEphemeralVolume`     | `false`                                                      | [汎用的な一時ボリューム](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/#generic-ephemeral-volumes)を使用する |
| `backups.cron.persistence.size`                          | `10Gi`                                                       | バックアップcronの永続ボリュームサイズ |
| `backups.cron.persistence.storageClass`                  |                                                              | プロビジョニング用のStorageClass名 |
| `backups.cron.persistence.subPath`                       |                                                              | バックアップcronの永続ボリュームのマウントパス |
| `backups.cron.persistence.volumeName`                    |                                                              | 既存の永続ボリューム名 |
| `backups.cron.resources.requests.cpu`                    | `50m`                                                        | バックアップcronに必要な最小CPU |
| `backups.cron.resources.requests.memory`                 | `350M`                                                       | バックアップcronに必要な最小メモリ |
| `backups.cron.restartPolicy`                             | `OnFailure`                                                  | バックアップcronの再起動ポリシー（`Never`または`OnFailure`） |
| `backups.cron.schedule`                                  | `0 1 * * *`                                                  | Cron形式のスケジュール文字列 |
| `backups.cron.startingDeadlineSeconds`                   | `null`                                                       | バックアップcronジョブの開始デッドライン（秒単位）（nullの場合、開始デッドラインは適用されません） |
| `backups.cron.successfulJobsHistoryLimit`                | `3`                                                          | 履歴に表示する成功したバックアップジョブの数 |
| `backups.cron.suspend`                                   | `false`                                                      | バックアップcronジョブは一時停止されます |
| `backups.cron.timeZone`                                  | `""`                                                         | バックアップスケジュールのタイムゾーン。詳細については、[Kubernetesドキュメント](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones)を参照してください。指定しない場合、クラスターのタイムゾーンを使用します。 |
| `backups.cron.tolerations`                               | `""`                                                         | バックアップcronジョブに追加するToleration |
| `backups.cron.nodeSelector`                              | `""`                                                         | バックアップcronジョブのノード選択 |
| `backups.objectStorage.backend`                          | `s3`                                                         | 使用するオブジェクトストレージプロバイダー（`s3`、`gcs`、または`azure`） |
| `backups.objectStorage.config.gcpProject`                | `""`                                                         | バックエンドが`gcs`の場合に使用するGCPプロジェクト |
| `backups.objectStorage.config.key`                       | `""`                                                         | シークレットに認証情報を含むキー |
| `backups.objectStorage.config.secret`                    | `""`                                                         | オブジェクトストレージの認証情報のシークレット |
| `common.labels`                                          | `{}`                                                         | このチャートで作成されたすべてのオブジェクトに適用される追加のラベル。 |
| `deployment.strategy`                                    | ``{ `type`: `Recreate` }``                                   | デプロイメントで使用される更新ストラテジを構成できます |
| `enabled`                                                | `true`                                                       | Toolboxの有効化フラグ |
| `extra`                                                  | `{}`                                                         | [追加の`gitlab.yml`設定](https://gitlab.com/gitlab-org/gitlab/-/blob/8d2b59dbf232f17159d63f0359fa4793921896d5/config/gitlab.yml.example#L1193-1199)のYAMLブロック |
| `image.pullPolicy`                                       | `IfNotPresent`                                               | Toolboxイメージのプルポリシー |
| `image.pullSecrets`                                      |                                                              | Toolboxイメージプルシークレット |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee` | Toolboxイメージリポジトリ |
| `image.tag`                                              | `master`                                                     | Toolboxイメージタグ |
| `init.image.repository`                                  |                                                              | Toolbox initイメージリポジトリ |
| `init.image.tag`                                         |                                                              | Toolbox initイメージタグ |
| `init.resources`                                         | ``{ `requests`: { `cpu`: `50m` }}``                          | Toolbox initコンテナのリソース要件 |
| `init.containerSecurityContext`                          |                                                              | initContainer固有の[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | initContainer固有:プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                       | initContainer固有:コンテナを開始するユーザーID |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | initContainer固有:プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                       | initContainer固有:コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                  | initContainer固有:コンテナの[Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `nodeSelector`                                           |                                                              | Toolboxおよびバックアップジョブのノード選択 |
| `persistence.accessMode`                                 | `ReadWriteOnce`                                              | Toolboxの永続性アクセスモード |
| `persistence.enabled`                                    | `false`                                                      | Toolboxの永続性を有効にするフラグ |
| `persistence.matchExpressions`                           |                                                              | バインドするラベル式のマッチ |
| `persistence.matchLabels`                                |                                                              | バインドするラベル値のマッチ |
| `persistence.size`                                       | `10Gi`                                                       | Toolboxの永続ボリュームサイズ |
| `persistence.storageClass`                               |                                                              | プロビジョニング用のStorageClass名 |
| `persistence.subPath`                                    |                                                              | Toolboxの永続ボリュームのマウントパス |
| `persistence.volumeName`                                 |                                                              | 既存のPersistentVolume名 |
| `podLabels`                                              | `{}`                                                         | Toolboxポッドを実行するためのラベル |
| `priorityClassName`                                      |                                                              | ポッドに割り当てられた[優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)。 |
| `replicas`                                               | `1`                                                          | 実行するToolboxポッドの数 |
| `resources.requests`                                     | ``{ `cpu`: `50m`, `memory`: `350M` }``                       | Toolboxに必要な最小リソース |
| `securityContext.fsGroup`                                | `1000`                                                       | ポッドを開始するファイルシステムグループID |
| `securityContext.runAsUser`                              | `1000`                                                       | ポッドを開始するユーザーID |
| `securityContext.runAsGroup`                             | `1000`                                                       | ポッドを開始するグループID |
| `securityContext.fsGroupChangePolicy`                    |                                                              | ボリュームの所有権と権限を変更するためのポリシー（Kubernetes 1.23が必要です） |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                             | 使用するSeccompプロファイル |
| `containerSecurityContext`                               |                                                              | コンテナを開始するコンテナの[セキュリティコンテキスト](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)を上書きします |
| `containerSecurityContext.runAsUser`                     | `1000`                                                       | コンテナを開始する特定のセキュリティコンテキストの上書きを許可します |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                      | コンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                       | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                  | Gitalyコンテナの[Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.annotations`                             | `{}`                                                         | ServiceAccountのアノテーション |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                      | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `serviceAccount.enabled`                                 | `false`                                                      | ServiceAccountを使用するかどうかを示します |
| `serviceAccount.create`                                  | `false`                                                      | ServiceAccountを作成するかどうかを示します |
| `serviceAccount.name`                                    |                                                              | ServiceAccountの名前。設定しない場合、チャート名全体が使用されます |
| `tolerations`                                            |                                                              | Toolboxに追加するToleration |
| `extraEnvFrom`                                           |                                                              | 公開する他のデータソースからの追加の環境変数のリスト |

## バックアップの設定 {#configuring-backups}

[バックアップと復元に関するドキュメント](../../../backup-restore/_index.md)でのバックアップの設定に関する情報。バックアップの実行方法に関する技術的な実装に関する追加情報は、[バックアップと復元のアーキテクチャドキュメント](../../../architecture/backup-restore.md)にあります。]

## 永続性の設定 {#persistence-configuration}

バックアップと復元の永続ストアは、個別に構成されます。バックアップおよび復元操作のためにGitLabを構成する場合は、次の考慮事項を確認してください。

バックアップは`backups.cron.persistence.*`プロパティを使用し、復元は`persistence.*`プロパティを使用します。永続ストアの構成に関する詳細な説明では、最後のプロパティキー（例：`.enabled`または`.size`）のみを使用し、適切なプレフィックスを追加する必要があります。

永続ストアはデフォルトで無効になっているため、重要なサイズのバックアップまたは復元を行うには、`.enabled`を`true`に設定する必要があります。さらに、`.storageClass`をKubernetesによってPersistentVolumeを作成するために指定するか、PersistentVolumeを手動で作成する必要があります。`.storageClass`が「-」として指定されている場合、PersistentVolumeは、Kubernetesクラスターで指定されている[デフォルトのStorageClass](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/)を使用して作成されます。

PersistentVolumeを手動で作成する場合、`.volumeName`プロパティを使用するか、セレクター`.matchLables`/`.matchExpressions`プロパティを使用してボリュームを指定できます。

ほとんどの場合、`.accessMode`のデフォルト値は、ToolboxのみがPersistentVolumeにアクセスするための適切な制御を提供します。設定が正しいことを確認するには、KubernetesクラスターにインストールされているCSIドライバーのドキュメントを参照してください。

### バックアップに関する考慮事項 {#backup-considerations}

バックアップ操作では、バックアップオブジェクトストアに書き込まれる前に、バックアップされる個々のコンポーネントを保持するために、ある程度のディスク容量が必要です。ディスク容量の量は、次の要因によって異なります。

- プロジェクトの数と各プロジェクトに保存されているデータの量
- PostgresSQLデータベースのサイズ（イシュー、MRなど）
- 各オブジェクトストアバックエンドのサイズ

おおよそのサイズが決定されると、バックアップを開始できるように`backups.cron.persistence.size`プロパティを設定できます。

### 復元に関する考慮事項 {#restore-considerations}

バックアップの復元中、実行中のインスタンスでファイルを置き換える前に、バックアップをディスクに抽出する必要があります。この復元ディスク領域のサイズは、`persistence.size`プロパティによって制御されます。GitLabインストールのサイズが大きくなるにつれて、復元ディスク領域のサイズもそれに応じて大きくする必要があることに注意してください。ほとんどの場合、復元ディスク領域のサイズは、バックアップディスク領域と同じサイズである必要があります。

## Toolboxに含まれるツール {#toolbox-included-tools}

Toolboxコンテナには、Railsコンソール、Rakeタスクなど、便利なGitLabツールが含まれています。これらのコマンドを使用すると、データベース移行のステータスを確認したり、管理タスクのRakeタスクを実行したり、Railsコンソールを操作したりできます。

```shell
# locate the Toolbox pod
kubectl get pods -lapp=toolbox

# Launch a shell inside the pod
kubectl exec -it <Toolbox pod name> -- bash

# open Rails console
gitlab-rails console -e production

# execute a Rake task
gitlab-rake gitlab:env:info
```

### アフィニティ {#affinity}

詳細については、[`affinity`](../_index.md#affinity)を参照してください。
