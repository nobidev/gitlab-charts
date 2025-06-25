---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: オブジェクトストレージにMinIOを使用する
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

このチャートは、[`stable/minio`](https://github.com/helm/charts/tree/master/stable/minio)バージョン[`0.4.3`](https://github.com/helm/charts/tree/aaaf98b5d25c26cc2d483925f7256f2ce06be080/stable/minio)に基づいており、ほとんどの設定をそこから継承します。

## 設計上の選択 {#design-choices}

[アップストリームチャート](https://github.com/helm/charts/tree/master/stable/minio)に関する設計上の選択は、プロジェクトのReadmeにあります。

GitLabは、シークレットの設定を簡素化し、環境変数でのシークレットの使用をすべて削除するために、そのチャートを変更することを選択しました。GitLabは、シークレットを`config.json`に投入するのを制御するために`initContainer`を追加し、チャート全体の`enabled`フラグを追加しました。

このチャートは、1つのシークレットのみを使用します。

- `global.minio.credentials.secret`:`accesskey`および`secretkey`の値を格納するグローバルシークレットで、バケットへの認証に使用されます。

## 設定 {#configuration}

以下に、設定の主要なセクションをすべて説明します。親チャートから設定する場合、これらの値は次のようになります。

```yaml
minio:
  init:
  ingress:
    enabled:
    apiVersion:
    tls:
      enabled:
      secretName:
    annotations:
    configureCertmanager:
    proxyReadTimeout:
    proxyBodySize:
    proxyBuffering:
  tolerations:
  persistence:  # Upstream
    volumeName:
    matchLabels:
    matchExpressions:
    annotations:
  serviceType:  # Upstream
  servicePort:  # Upstream
  defaultBuckets:
  minioConfig:  # Upstream
```

### コマンドラインオプションのインストール {#installation-command-line-options}

次の表に、`--set`フラグを使用して`helm install`コマンドに指定できる、可能なすべてのチャート設定を示します。

| パラメータ                                                | デフォルト                        | 説明 |
|----------------------------------------------------------|--------------------------------|-------------|
| `common.labels`                                          | `{}`                           | このチャートによって作成されたすべてのオブジェクトに適用される補助ラベル。 |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                        | initContainer固有:プロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                         | initContainer固有:コンテナを非rootユーザーで実行するかどうかを制御します |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                    | initContainer固有:コンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `defaultBuckets`                                         | `[{"name": "registry"}]`       | MinIOデフォルトバケット |
| `deployment.strategy`                                    | ``{ `type`: `Recreate` }``     | デプロイで使用される更新戦略を構成できます |
| `image`                                                  | `minio/minio`                  | MinIOイメージ |
| `imagePullPolicy`                                        | `Always`                       | MinIOイメージプルポリシー |
| `imageTag`                                               | `RELEASE.2017-12-28T01-21-00Z` | MinIOイメージtag |
| `minioConfig.browser`                                    | `on`                           | MinIOブラウザフラグ |
| `minioConfig.domain`                                     |                                | MinIOドメイン |
| `minioConfig.region`                                     | `us-east-1`                    | MinIOリージョン |
| `minioMc.image`                                          | `minio/mc`                     | MinIO mcイメージ |
| `minioMc.tag`                                            | `latest`                       | MinIO mcイメージtag |
| `mountPath`                                              | `/export`                      | MinIO設定ファイルのマウントパス |
| `persistence.accessMode`                                 | `ReadWriteOnce`                | MinIO永続性アクセスモード |
| `persistence.annotations`                                |                                | MinIO PersistentVolumeClaimアノテーション |
| `persistence.enabled`                                    | `true`                         | MinIO永続性フラグを有効にする |
| `persistence.matchExpressions`                           |                                | バインドするMinIOラベル式の一致 |
| `persistence.matchLabels`                                |                                | バインドするMinIOラベル値の一致 |
| `persistence.size`                                       | `10Gi`                         | MinIO永続ボリュームサイズ |
| `persistence.storageClass`                               |                                | プロビジョニング用のMinIO storageClassName |
| `persistence.subPath`                                    |                                | MinIO永続ボリュームマウントパス |
| `persistence.volumeName`                                 |                                | MinIO既存の永続ボリューム名 |
| `priorityClassName`                                      |                                | ポッドに割り当てられた[優先](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)クラス。 |
| `pullSecrets`                                            |                                | イメージのシークレット |
| `resources.requests.cpu`                                 | `250m`                         | MinIOがする最小CPU |
| `resources.requests.memory`                              | `256Mi`                        | MinIOがする最小メモリ |
| `securityContext.fsGroup`                                | `1000`                         | ポッドを開始するグループID |
| `securityContext.runAsUser`                              | `1000`                         | ポッドを開始するユーザーID |
| `securityContext.fsGroupChangePolicy`                    |                                | ボリュームの所有権とを変更するための (Kubernetes 1.23が必要) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`               | 使用するSeccompプロファイル |
| `containerSecurityContext.runAsUser`                     | `1000`                         | コンテナの起動元の特定のセキュリティコンテキストを上書きできます |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                        | Gitalyコンテナのプロセスが親プロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`                  | `true`                         | コンテナを非rootユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                    | Gitalyコンテナの[Linux機能](https://man7.org/linux/man-pages/man7/capabilities.7.html)を削除します |
| `serviceAccount.automountServiceAccountToken`            | `false`                        | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを示します |
| `servicePort`                                            | `9000`                         | MinIOサービス |
| `serviceType`                                            | `ClusterIP`                    | MinIOサービスタイプ |
| `tolerations`                                            | `[]`                           | ポッドの容認 |
| `jobAnnotations`                                         | `{}`                           | ジョブのアノテーション |

## チャート設定例 {#chart-configuration-examples}

### `pullSecrets` {#pullsecrets}

`pullSecrets`を使用すると、プライベートに対してして、ポッドのイメージをできます。

プライベートレジストリとその[認証](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)方法に関する追加の詳細は、[Kubernetes](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod)ドキュメントにあります。

以下は`pullSecrets`の使用例です。

```yaml
image: my.minio.repository
imageTag: latest
imagePullPolicy: Always
pullSecrets:
- name: my-secret-name
- name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

このセクションでは、デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。

| 名前                           |  種類   | デフォルト | 説明 |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | ブール値 | `false` | デフォルトのServiceAccountアクセストークンをポッドにマウントするかどうかを制御します。特定のサイドカーが適切に動作するために必要な場合を除き、これを有効にしないでください (たとえば、Istio)。 |

### `tolerations` {#tolerations}

`tolerations`を使用すると、taintされたノードでポッドをスケジュールできます

以下は`tolerations`の使用例です。

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

## サブチャートを有効にする {#enable-the-sub-chart}

コンパートメント化されたサブチャートを実装するために私たちが選択した方法は、特定ので不要なコンポーネントを無効にする機能を含みます。このため、最初に決定する必要がある設定は`enabled:`です。

デフォルトでは、MinIOはすぐに使用できるように有効になっていますが、本番環境での使用は推奨されません。無効にする準備ができたら、`--set global.minio.enabled: false`を実行します。

## `initContainer`を設定する {#configure-the-initcontainer}

めったに変更されませんが、`initContainer`の動作は、次の項目を使用して変更できます。

```yaml
init:
  image:
    repository:
    tag:
    pullPolicy: IfNotPresent
  script:
```

### initContainerイメージ {#initcontainer-image}

initContainerイメージは、通常のイメージと同じです。デフォルトでは、チャートローカルの値は空のままになり、グローバル設定である`global.gitlabBase.image.repository`および現在の`global.gitlabVersion`に関連付けられたイメージtagは、initContainerイメージのpopulatedに使用されます。グローバル設定は、チャートローカルの値（例：`minio.init.image.tag`）で上書きできます。

### initContainerスクリプト {#initcontainer-script}

initContainerには、次の項目が渡されます。

- `/config`にマウントされた認証項目を含むシークレット。通常は`accesskey`および`secretkey`です。
- `config.json`テンプレートを含むConfigMapと、`sh`で実行されるスクリプトを含む`configure`が`/config`にマウントされます。
- `/minio`にマウントされた`emptyDir`。デーモンのコンテナにされます。

initContainerは、`/config/configure`スクリプトを使用して、完成した設定で`/minio/config.json`をpopulateすることが期待されています。`minio-config` [コンテナ](https://min.io)がそのタスクを完了すると、`/minio` [ディレクトリ](https://min.io)が`minio` [コンテナ](https://min.io)に渡され、[MinIO](https://min.io)サーバーに`config.json`を提供するために使用されます。

## Ingressの設定 {#configuring-the-ingress}

これらのは、MinIO Ingressを制御します。

| 名前                   |  種類   | デフォルト | 説明 |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | 文字列  |         | `apiVersion`フィールドで使用する値。 |
| `annotations`          | 文字列  |         | このフィールドは、[Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)の標準`annotations`と完全に一致します。 |
| `enabled`              | ブール値 | `false` | それをサポートするサービスに対してIngressオブジェクトを作成するかどうかを制御する。`false`の場合、`global.ingress.enabled`が使用されます。 |
| `configureCertmanager` | ブール値 |         | Ingressアノテーション`cert-manager.io/issuer`と`acme.cert-manager.io/http01-edit-in-place`を切り替えます。詳細については、[GitLab PagesのTLS要件](../../installation/tls.md)を参照してください。 |
| `tls.enabled`          | ブール値 | `true`  | `false`に設定すると、MinIOのTLSを無効にします。これは、IngressレベルでTLSターミネーションを使用できない場合に特に役立ちます。たとえば、Ingressコントローラーの前にTLSターミネーションプロキシがある場合などです。 |
| `tls.secretName`       | 文字列  |         | MinIO URLの有効な証明書とを含むKubernetes TLSの名前。設定されていない場合、代わりに`global.ingress.tls.secretName`が使用されます。 |

## イメージの設定 {#configuring-the-image}

`image`、`imageTag`、`imagePullPolicy`のデフォルトは、[アップストリームでドキュメント化](https://github.com/helm/charts/tree/master/stable/minio#configuration)されています。

## 永続 {#persistence}

このチャートは`PersistentVolumeClaim`をプロビジョニングし、対応する永続ボリュームをデフォルトの場所`/export`にマウントします。これが機能するには、Kubernetesクラスターで使用可能な物理ストレージが必要です。`emptyDir`を使用する場合は、`PersistentVolumeClaim`を`persistence.enabled: false`で無効にします。

[`persistence`](https://github.com/helm/charts/tree/master/stable/minio#persistence)の動作は、[アップストリームでドキュメント化](https://github.com/helm/charts/tree/master/stable/minio#configuration)されています。

GitLabにはいくつかの項目が追加されています。

```yaml
persistence:
  volumeName:
  matchLabels:
  matchExpressions:
```

| 名前               |  種類  | デフォルト | 説明 |
|:-------------------|:------:|:--------|:------------|
| `volumeName`       | 文字列 | `false` | `volumeName`が指定されている場合、`PersistentVolumeClaim`は、動的に`PersistentVolume`を作成する代わりに、指定された名前で`PersistentVolume`を使用します。これは、アップストリームの動作を上書きします。 |
| `matchLabels`      |  マップ   | `true`  | バインドするボリュームを選択するときに、照合する名と値のマップを受け入れます。これは、`PersistentVolumeClaim` `selector`セクションで使用されます。[ボリュームドキュメント](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)を参照してください。 |
| `matchExpressions` | 配列  |         | バインドするボリュームを選択するときに、照合する条件オブジェクトの配列を受け入れます。これは、`PersistentVolumeClaim` `selector`セクションで使用されます。[ボリュームドキュメント](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector)を参照してください。 |

## `defaultBuckets` {#defaultbuckets}

`defaultBuckets`は、*インストール*時にMinIOポッドにバケットを自動的に作成するメカニズムを提供します。このプロパティには、最大3つのプロパティ ( `name`、`policy`、および`purge`) を持つ項目の配列が含まれています。

```yaml
defaultBuckets:
  - name: public
    policy: public
    purge: true
  - name: private
  - name: public-read
    policy: download
```

| 名前     |  種類   | デフォルト | 説明 |
|:---------|:-------:|:--------|:------------|
| `name`   | 文字列  |         | 作成されるバケットの名前。指定された値は、[AWSバケット命名規則](https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html)に準拠している必要があります。つまり、に準拠し、長さが3 ～ 63文字の文字列で文字a ～ z、0 ～ 9、および - (ハイフン) のみを含む必要があります。`name`プロパティは、すべての_エントリ_に_必須_です。 |
| `policy` |         | `none`  | `policy`の値は、MinIOのバケットのアクセスを制御します。`policy`プロパティは必須ではなく、デフォルト値は`none`です。**匿名**アクセスに関して、可能な値は次のとおりです: `none` (匿名アクセスなし)、`download` (匿名の読み取り専用アクセス)、`upload` (匿名の書き込み専用アクセス) または`public` (匿名の読み取り/書き込みアクセス)。 |
| `purge`  | ブール値 |         | `purge`プロパティは、インストール時に既存のバケットを強制的に削除するための手段として提供されます。これは、[永続](#persistence)性のvolumeNameプロパティに既存の`PersistentVolume`を使用する場合にのみ有効になります。動的に作成された`PersistentVolume`を使用する場合、これはチャートのインストール時にのみ発生し、作成されたばかりの`PersistentVolume`にデータが存在しないため、有効な効果はありません。このプロパティは必須ではありませんが、バケットを強制的にパージするには、`true`の値でこのプロパティを指定できます`mc rm -r --force`。 |

## セキュリティコンテキスト {#security-context}

これらのオプションを使用すると、ポッドの起動に使用される`user`および/または`group`を制御できます。

セキュリティコンテキストの詳細については、公式の[Kubernetesドキュメント](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/)を参照してください。

## サービスタイプとポート {#service-type-and-port}

これらは[アップストリームでドキュメント化](https://github.com/helm/charts/tree/master/stable/minio#configuration)されており、キーの概要は次のとおりです。

```yaml
## Expose the MinIO service to be accessed from outside the cluster (LoadBalancer service).
## or access it from within the cluster (ClusterIP service). Set the service type and the port to serve it.
## ref: http://kubernetes.io/docs/user-guide/services/
##
serviceType: LoadBalancer
servicePort: 9000
```

チャートは`type: NodePort`であるとは想定されていないため、そのように設定**しないでください**。

## アップストリーム項目 {#upstream-items}

次の[アップストリームドキュメント](https://github.com/helm/charts/tree/master/stable/minio)も、このチャートに完全に適用されます。

- `resources`
- `nodeSelector`
- `minioConfig`

`minioConfig`設定の詳細な説明については、[MinIO通知ドキュメント](https://min.io/docs/minio/kubernetes/upstream/index.html)を参照してください。これには、バケットオブジェクトがアクセスまたは変更されたときにを公開する方法の詳細が含まれています。
