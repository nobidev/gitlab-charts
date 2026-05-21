---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenBaoチャート
---

{{< details >}}

- プラン: Ultimate
- 提供形態: GitLab.com、GitLab Self-Managed
- ステータス: 実験的機能

{{< /details >}}

{{< history >}}

- GitLab 18.3で`ci_tanukey_ui`および`secrets_manager`[フラグ](https://docs.gitlab.com/administration/feature_flags/)とともに[実験的機能](https://docs.gitlab.com/policy/development_stages_support/#experiment)として導入されました。デフォルトでは無効になっています。
- GitLab 18.4で`ci_tanukey_ui`[フラグ](https://docs.gitlab.com/administration/feature_flags/)は`secrets_manager`にマージされました。
- GitLab 18.8で一部のユーザーがクローズドベータ版を利用できるようになりました。

{{< /history >}}

> [!flag] この機能の利用可否は、機能フラグによって制御されます。詳細については、履歴を参照してください。

[OpenBaoチャート](https://gitlab.com/gitlab-org/cloud-native/charts/openbao)を使用してOpenBaoをインストールできます。OpenBaoは、[GitLab Secrets Manager](https://docs.gitlab.com/ci/secrets/secrets_manager/)を有効にするために必要です。

## 既知の問題 {#known-issues}

- ダウンタイムなしでOpenBaoをアップグレードすることはできません。ゼロダウンタイムアップグレードについて、[OpenBaoチャートのイシュー13](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/issues/13)で提案されています。
- [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator)を使用してOpenBaoをデプロイすることはできません。
- OpenBaoイメージのFIPSバリアントのビルド作業は進行中ですが、OpenBaoはFIPS検証済みではありません。FIPS検証については[GitLabイシュー574875](https://gitlab.com/gitlab-org/gitlab/-/issues/574875)で追跡されています。

## GitLab Secrets ManagerとOpenBaoをセットアップする {#setup-gitlab-secret-manager-and-openbao}

1. 既存のGitLabインスタンスで、OpenBaoを有効にします:

   ```yaml
   # Enable OpenBao integration
   global:
     openbao:
       enabled: true
   # Install bundled OpenBao
   openbao:
     install: true
   ```

1. GitLabの上部のバーで、**検索または移動先**を選択して、プロジェクトを見つけます。
1. **設定 > 一般**を選択します。
1. **可視性、プロジェクトの機能、権限**を展開します。
1. **シークレットマネージャー**の切替をオンにして、Secrets Managerがプロビジョニングされるまで待ちます。

## Geo設定 {#geo-configuration}

{{< history >}}

- `jwt_audience`はGitLab 18.10で[導入されました](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4837)。

{{< /history >}}

[GitLab Geo](https://docs.gitlab.com/ee/administration/geo/)のデプロイでは、セカンダリサイトはプライマリサイトとは異なるURLを使用してOpenBaoに到達する場合があります。GitLab OpenBaoの認証におけるJWTオーディエンスクレームは、OpenBaoで`bound_audiences`に設定されているものと一致する必要があります。各サイトでOpenBaoのURLが異なる場合、`jwt_audience`を共有値（通常はプライマリサイトのOpenBao URL）に設定して、JWTがどのサイトで生成されたかに関わらずOpenBaoで受け入れられるようにします。

セカンダリサイトを設定します:

```yaml
global:
  openbao:
    enabled: true
    # Site-specific URL for this Geo secondary
    url: https://openbao.secondary.example.com:8200
    # Shared audience - must match OpenBao bound_audiences (e.g. primary site URL)
    jwt_audience: https://openbao.shared.example.com:8200
```

OpenBao `config.initialize.boundAudiences`が`jwt_audience`の値を含むことを確認します。バンドルされたOpenBaoチャートを使用する場合、`boundAudiences`は外部OpenBaoホスト名にデフォルトで設定されます。Geoの場合、`jwt_audience`として使用される共有URLを含めるためにこれをオーバーライドする必要がある場合があります。

フェイルオーバーシナリオで、セカンダリサイトがプライマリにプロモートされる場合、設定から`jwt_audience`を省略します。プロモートされたプライマリは自身のURLを使用し、オーディエンスは当該URLにデフォルト設定されます。

## OpenBaoのアップグレードをロールバックする {#rolling-back-openbao-upgrades}

OpenBaoのアップグレードでは、下位互換性のないPostgreSQLデータの変更が行われる可能性があります。そのため、OpenBaoのアップグレードをロールバックする必要が生じた場合に互換性の問題を引き起こすことがあります。

OpenBaoをアップグレードする前に、必ず[バックアップ](#back-up-openbao)してください。OpenBaoのアップグレードをロールバックする必要がある場合は、OpenBaoのバージョンに一致するデータベースバックアップも復元してください。

詳細については、[OpenBaoのアップグレードドキュメント](https://openbao.org/docs/upgrading/)を参照してください。

## OpenBaoをバックアップする {#back-up-openbao}

OpenBaoを完全にバックアップするには、以下が必要です:

- アンシールキー。これらのキーは、復元後にOpenBaoデータにアクセスするために不可欠です。OpenBaoシークレットの[シークレットバックアップ手順](../../backup-restore/backup.md#back-up-the-secrets)に従ってください。
- PostgreSQLデータベース。

デフォルトでは、OpenBaoのPostgreSQLデータは、チャートの組み込みバックアップ手順の一部としてバックアップされます。

別のデータベース（論理または物理）を使用するようにOpenBaoを設定している場合は、そのデータベースを手動でバックアップする必要があります。デフォルトのバックアップツールは、他の外部データベースを認識しないため、標準のPostgreSQLセットアップのみを対象としています。同期の問題を回避するために、GitLabデータベースとOpenBaoデータベースは同時にバックアップする必要があります。

## OpenBaoを復元する {#restore-openbao}

デフォルトでは、OpenBaoのPostgreSQLデータは、チャートの組み込み復元手順の一部として復元されます。

別のデータベース（論理または物理）を使用するようにOpenBaoを設定している場合は、OpenBaoデータベースのバックアップは組み込みのバックアップユーティリティで復元できず、手動で復元する必要があります。

OpenBaoのバックアップを復元する前に、OpenBaoをスケールダウンしていることを確認してください。OpenBaoはデータベーススキーマを再作成しようとするため、予期しないエラーが発生する可能性があります。OpenBaoをスケールダウンするには、以下を実行します:

```shell
kubectl scale deploy -lapp=openbao,release=<helm release name> -n <namespace> --replicas=0
```

## OpenBaoの設定オプション {#openbao-configuration-options}

次の表は、利用可能なOpenBaoの設定オプションをすべて示しています。

### インストールコマンドラインオプション {#installation-command-line-options}

以下の表は、`--set`フラグを使用して`helm install`コマンドに指定できるチャート設定をすべて示しています。

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `logLevel`                                               | info                                                    | OpenBaoのログレベル。 |
| `logRequestLevel`                                        | off                                                     | OpenBaoのリクエストログレベル。リクエストログを有効にするには、これを`logLevel`と同じ値、またはそれより高いレベルに設定します。 |
| `logFormat`                                              | `json`                                                  | OpenBaoのログ形式。`json`または`standard`のいずれか。 |
| `serviceAccount.create`                                  | true                                                    | OpenBaoのサービスアカウントを作成します。 |
| `serviceAccount.automount`                               | true                                                    | |
| `serviceAccount.annotations`                             | `{}`                                                    | 追加のサービスアカウントアノテーション。 |
| `serviceAccount.name`                                    |                                                         | 生成されたサービスアカウント名をオーバーライドします。 |
| `role.create`                                            |                                                         | 必要なRBAC権限を持つロールを作成します。 |
| `securityContext.capabilities`                           | `{ drop: ["ALL"] }`                                     | |
| `securityContext.runAsNonRoot`                           | true                                                    | |
| `securityContext.allowPrivilegeEscalation`               | false                                                   | |
| `securityContext.runAsUser`                              | 65532                                                   | |
| `podSecurityContext.seccompProfile`                      | `RuntimeDefault`                                        | |
| `podSecurityContext.runAsUser`                           | 65532                                                   | |
| `podSecurityContext.fsGroup`                             | 65532                                                   | |
| `serviceActive.type`                                     | ClusterIP                                               | アクティブなOpenBaoポッドのサービスタイプ。 |
| `serviceActive.annotations`                              | `{}`                                                    | アクティブなOpenBaoポッドのサービスアノテーション。 |
| `serviceInactive.type`                                   | ClusterIP                                               | スタンバイのOpenBaoポッドのサービスタイプ。 |
| `serviceInactive.annotations`                            | `{}`                                                    | スタンバイのOpenBaoポッドのサービスアノテーション。 |
| `resources`                                              | `{}`                                                    | リソースの制限とリクエスト。 |
| `autoscaling.minReplicas`                                | 2                                                       | OpenBaoの最小レプリカ数。 |
| `autoscaling.maxReplicas`                                | 2                                                       | OpenBaoの最大レプリカ数。 |
| `autoscaling.targetCPUUtilizationPercentage`             | 80                                                      | オートスケールの目標CPU使用率。 |
| `autoscaling.targetCPUMemoryPercentage`                  |                                                         | オートスケールの目標メモリ使用率。 |
| `livenessProbe`                                          |                                                         | OpenBaoのlivenessプローブ。デフォルトについては、[OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml)を確認してください。 |
| `readinessProbe`                                         |                                                         | OpenBaoのreadinessプローブ。デフォルトについては、[OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml)を確認してください。 |
| `nodeSelector`                                           | {}                                                      | ノードセレクターラベル。 |
| `tolerations`                                            | []                                                      | ポッドの割り当て用のtolerationラベル。 |
| `affinity`                                               | {}                                                      | ポッドの割り当て用のaffinityラベル。 |
| `config.ui`                                              | false                                                   | OpenBao UIを有効にします。 |
| `config.clusterPort`                                     | 8201                                                    | OpenBaoのクラスターポート。 |
| `config.apiPort`                                         | 8200                                                    | OpenBaoのAPIポート。 |
| `config.cacheSize`                                       | 8200                                                    | 物理ストレージサブシステムが使用する読み取りキャッシュのサイズ（エントリ数）。 |
| `config.maxRequestSize`                                  | 786432                                                  | 最大リクエストサイズ（バイト単位）。デフォルトは768 KBです。 |
| `config.maxRequestJsonMemory`                            | 1048576                                                 | JSON解析後のリクエストボディの最大サイズ（バイト単位）。デフォルトは1 MBです。 |

### コンテナイメージのオプション {#container-image-options}

OpenBaoチャートは、OpenBaoをデプロイするために[クラウドネイティブGitLabコンテナイメージ](https://gitlab.com/gitlab-org/build/CNG)をデプロイします。OpenBaoのビルドには、アップストリームバージョンからの[修正](https://gitlab.com/gitlab-org/govern/secrets-management/openbao-internal)が含まれています。その結果、一部の機能が標準のOpenBaoリリースと異なる場合があります。

| パラメータ                                                | デフォルト                                                   | 説明 |
|----------------------------------------------------------|-----------------------------------------------------------|-------------|
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-openbao` | OpenBaoイメージのリポジトリ。 |
| `image.pullPolicy`                                       | `IfNotPresent`                                            | イメージのプルポリシー。 |
| `image.tag`                                              |                                                           | これをオーバーライドして、カスタムのOpenBaoバージョンをデプロイします。 |
| `imagePullSecrets`                                       | `[]`                                                      | プライベートリポジトリからイメージをプルするためのシークレット。 |

### IngressおよびTLSの設定オプション {#ingress-and-tls-configuration-options}

OpenBaoチャートは、デフォルトでIngress終端のTLS暗号化を使用します。

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `global.openbao.host`                                    | `openbao.<GitLab Domain>`                                 | OpenBaoホスト。GitLab webserviceとOpenBaoチャートの設定に使用されます。 |
| `global.openbao.url`                                     | ホストから派生                                       | GitLab用OpenBao URL。存在する場合は、完全なURIである必要があります。 |
| `global.openbao.jwt_audience`                            | `url`と同じ                                           | OpenBao認証用のJWTオーディエンスクレーム。サイトが異なるURLを使用する場合、[Geoデプロイ](#geo-configuration)のために設定します。OpenBao `bound_audiences`と一致する必要があります。 |
| `global.openbao.psql`                                    | `{}`                                                    | OpenBaoデータベース設定 (ホスト、データベース、ユーザー名、パスワード)。 |
| `ingress.enabled`                                        | true                                                    | RunnerがOpenBaoに到達できるように、OpenBao Ingressを有効にします。 |
| `ingress.hostname`                                       | グローバルホスト設定に基づく外部OpenBaoホスト。     | Ingressでマッチさせるホスト名。 |
| `ingress.tls.enabled`                                    | true                                                    | Ingress TLSを有効にします。 |
| `ingress.tls.secretName`                                 |                                                         | [Kubernetes TLSシークレット](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)の名前。デフォルトではcertmanagerによって管理されます。 |
| `ingress.annotations`                                    | true                                                    | Ingressにレンダリングされるアノテーション。NGINX以外のIngressコントローラー用にOpenBaoを設定する場合に使用します。 |
| `ingress.configureCertmanager`                           | グローバルcertmanager設定                               | certmanagerを使用してTLS証明書を管理します。 |
| `ingress.certmanagerIssuer`                              | `<release>-issuer`                                       | certmanager発行者の名前。 |
| `ingress.sslPassthroughNginx`                            | false                                                   | 受信TLS接続をOpenBaoにパススルーするように、Ingressにアノテーションを付与します。certmanagerが設定されている場合、新しいHTTP01チャレンジは別のIngress経由で行われます。 |
| `config.tlsDisable`                                      | true                                                    | 内部TLSを無効にします。無効にすると、Ingress TLSパススルーも無効になります。 |
| `config.metricsListener.tlsDisable`                      | true                                                    | メトリクスリスナーの内部TLSを無効にします。 |

OpenBaoは、エンドツーエンドでTLS暗号化した状態で運用する必要があります。エンドツーエンドTLSを有効にするには、OpenBaoがTLS接続を受け付けるように設定し、NGINX Ingressを介してTLS接続をパススルーさせます:

```yaml
global:
  ingress:
    useNewIngressForCerts: true
config:
  tlsDisable: false
ingress:
  sslPassthroughNginx: true
```

> [!note] SSLパススルーを有効にするには、cert-managerがHTTP01チャレンジを完了するために別のIngressを作成する必要があります。バンドルされているcertmanagerと`Issuer`を使用する場合は、[`global.ingress.useNewIngressForCerts`](../globals.md#globalingressusenewingressforcerts)を設定して、発行者によって正しい`IngressClass`が設定されるようにしてください。

### ゲートウェイAPI {#gateway-api}

OpenBaoチャートでは、`HTTPRoute`を介してトラフィックを公開できます。[ゲートウェイAPIがグローバルに有効になっている](../globals.md#gateway-api)場合、管理対象の`Gateway`リソース内にOpenBao用のリスナーが作成されます。

| パラメータ                  | デフォルト                                                 | 説明 |
|----------------------------|---------------------------------------------------------|-------------|
| `gatewayRoute.enabled`     | デフォルトは`global.gatewayApi.enabled`の値です。        | `HTTPRoute`を介してOpenBaoを公開できるようにします。 |
| `gatewayRoute.sectionName` | openbao-web                                             | `HTTPRoute`が使用するゲートウェイセクション。 |
| `gatewayRoute.gatewayName` | GitLabチャートが管理するゲートウェイ                            | `HTTPRoute`が使用するゲートウェイ名。 |
| `gatewayRoute.annotations` | `{}`                                                    | `HTTPRoute`の追加のアノテーション。 |
| `gatewayRoute.timeouts`    | `{}`                                                    | `HTTPRoute`のカスタムタイムアウト設定。 |

### モニタリングの設定オプション {#monitoring-configuration-options}

OpenBaoは、Prometheusメトリクスを公開するように事前設定されています。これらのメトリクスは、バンドルされているPrometheusサブチャートによってスクレイプされます。

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.telemetry.enabled`                               | true                                                    | テレメトリとモニタリングを有効にします。 |
| `config.telemetry.disableHostname`                       | true                                                    | ゲージ値のプレフィックスとしてローカルホスト名を付与します。 |
| `config.telemetry.prometheusRetentionTime`               | `24h`                                                   | メトリクスの保持期間。 |
| `config.telemetry.metricsPrefix`                         | `openbao`                                               | すべてのメトリクスのプレフィックス。 |
| `config.telemetry.usageGaugePeriod`                      | 0                                                       | トークン数、エンティティ数、シークレット数など、高カーディナリティの使用状況データを収集する間隔。 |
| `config.telemetry.numLeaseMetricsBuckets`                | 1                                                       | リースの期限切れバケット数。 |
| `config.metricsListener.enabled`                         | true                                                    | メトリクスのリクエストを処理するために2番目のAPIポートを有効にします。このリスナーはすべてのAPIリクエストを処理できますが、メトリクスのリクエストは認証なしで処理します。 |
| `config.metricsListener.tlsDisable`                      | true                                                    | メトリクスリスナーの内部TLSを無効にします。 |
| `config.metricsListener.port`                            | 8209                                                    | メトリクスリスナーのポート。 |
| `config.metricsListener.unauthenticatedMetricsAccess`    | true                                                    | メトリクスのリクエストを認証なしで処理できるようにします。 |
| `podMonitor.enabled`                                     | false                                                   | Prometheus Operator用のPodMonitorリソースを有効にします。クラスターにPrometheus Operatorがインストールされている必要があります。 |
| `podMonitor.additionalLabels`                            | `{}`                                                    | PodMonitorリソースに追加するラベル。 |
| `podMonitor.selectorLabels`                              | `{}`                                                    | スクレイプ対象のポッドを絞り込むための追加のセレクターラベル。 |
| `podMonitor.endpointConfig`                              | `{}`                                                    | 追加のエンドポイント設定（例: `interval`、`scrapeTimeout`）。 |

### アンシールおよび初期化オプション {#unsealing-and-initialization-options}

OpenBaoチャートは、相互に排他的な2つの自動アンシール方式をサポートしています:

- [静的自動アンシール](https://openbao.org/docs/configuration/seal/static/) (デフォルト)
- [AWS KMSアンシール](https://openbao.org/docs/configuration/seal/awskms/)

また、OpenBaoの宣言的な[自己初期化](https://openbao.org/docs/configuration/self-init/)も使用します。

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.unseal.static.enabled`                           | true                                                    | 静的自動アンシールを有効にします。 |
| `config.unseal.static.currentKeyId`                      | `static-unseal-0`                                       | 現在の静的アンシールキーのID。 |
| `config.unseal.static.currentKey`                        | `/srv/openbao/keys/static-unseal-0`                     | 現在の静的アンシールキーのパス。 |
| `config.unseal.static.previousKeyId`                     |                                                         | 以前の静的アンシールキーのID。 |
| `config.unseal.static.previousKey`                       | `/srv/openbao/keys/static-unseal-1`                     | 以前の静的アンシールキーのパス。以前のキーIDも設定されている場合にのみレンダリングされます。 |
| `config.unseal.awskms.enabled`                           | false                                                   | AWS KMS自動アンシールを有効にします。 |
| `config.unseal.awskms.kmsKeyId`                          |                                                         | KMSキーID、ARN、またはエイリアス（例：`alias/my-openbao-key`）。`config.unseal.awskms.enabled`が`true`の場合に必須です。 |
| `config.unseal.awskms.region`                            |                                                         | KMSキーが存在するAWSリージョン。 |
| `config.unseal.awskms.endpoint`                          |                                                         | オプションのカスタムKMSエンドポイントURL（例: VPCエンドポイント）。 |
| `config.initialize.enabled`                              | true                                                    | OpenBaoの自己初期化を有効にします。 |
| `config.initialize.oidcDiscoveryUrl`                     | 外部GitLabホスト                                    | OIDCディスカバリURL。デフォルトは外部GitLabホスト名です。 |
| `config.initialize.boundIssuer`                          | 外部GitLabホスト                                    | 発行者URL。デフォルトは外部GitLabホスト名です。 |
| `config.initialize.boundAudiences`                       | 外部OpenBaoホスト                                   | OIDCロールのオーディエンス。デフォルトは外部OpenBaoホスト名です。 |
| `staticUnsealSecret.generate`                            | false                                                   | OpenBaoを自動アンシールするための静的キーを生成します。GitLabチャートのshared-secretチャートによって管理されるため、デフォルトはfalseです。 |
| `initializeTpl`                                          |                                                         | OpenBaoを自己初期化するために渡されるテンプレート。デフォルトについては、[OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml)を確認してください。 |

#### AWS KMSアンシール {#aws-kms-unsealing}

AWS KMSアンシールは、アンシールキーをAWS KMSキーに委任し、静的キーシークレットを管理する必要をなくします。

AWS (EKS、EC2)で実行する場合、明示的なAWS認証情報が不要となるように、[IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)またはインスタンスプロファイルを使用します。OpenBaoサービスアカウントにIAMロールのARNをアノテーション付けします:

```yaml
openbao:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::<account-id>:role/<role-name>"
  config:
    unseal:
      static:
        enabled: false
      awskms:
        enabled: true
        kmsKeyId: "alias/my-openbao-key"
        region: "us-east-1"
```

IAMロールには、KMSキーに対する`kms:Encrypt`、`kms:Decrypt`、および`kms:DescribeKey`のパーミッションが必要です。

### 監査イベントストリーミングオプション {#audit-event-streaming-options}

OpenBaoチャートは、イベントをGitLabにストリーミングするための[監査デバイス](https://openbao.org/docs/audit/)を設定します。

| パラメータ                                                | デフォルト                                                 | 説明 |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `global.openbao.httpAudit.secret`                        | `<release>-openbao-audit-secret`                        | OpenBaoとGitLab間で共有するトークンを保存するシークレットの名前。 |
| `global.openbao.httpAudit.key`                           | `token`                                                 | 共有トークンを保存するシークレットキー。 |
| `config.audit.http.enabled`                              | true                                                    | HTTPを使用して監査イベントをGitLabにストリーミングする機能を有効にします。 |
| `config.audit.http.streamingUri`                         | 内部workhorseのURL                                  | 監査イベントのストリーミング先のエンドポイント。 |
| `config.audit.http.authTokenPath`                        | `/srv/openbao/audit/gitlab-auth`                        | GitLabと共有するトークンがマウントされるパス。 |
| `httpAuditSecret.generate`                               | false                                                   | 認証付き監査のためにGitLabと共有するシークレットを生成します。GitLabチャートのshared-secretチャートによって管理されるため、デフォルトはfalseです。 |
| `initializeTpl`                                          |                                                         | OpenBao監査を設定するために渡されるテンプレート。デフォルトについては、[OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml)を確認してください。 |

## データベース設定 {#database-configuration}

OpenBaoは、Railsバックエンドからのデータ分離のために、**separate logical database** (`openbao`をデフォルト) を使用します。

ホスト、データベース、ユーザー名、パスワードで`global.openbao.psql`または`openbao.config.storage.postgresql.connection`を設定します。データベースは手動で作成する必要があります。**パスワードが必要です**。メインのGitLabデータベースからは継承されません。

外部データベースを設定するには:

1. データベースサーバーでPostgreSQLユーザーとデータベースを作成します:

   ```sql
   -- Create the OpenBao user
   CREATE USER openbao WITH PASSWORD '<password>';

   -- Create the OpenBao database
   CREATE DATABASE openbao OWNER openbao;
   ```

1. パスワードを含むKubernetesシークレットを作成します:

   ```shell
   kubectl create secret -n bao generic openbao-db-password --from-literal=password="<password>"
   ```

1. 外部データベースに接続するようにOpenBaoを設定します:

   ```yaml
   global:
     openbao:
       psql:
         host: "psql.openbao.example.com"
         port: 5432
         database: openbao
         username: openbao
         password:
           secret: openbao-db-password
           key: password
   ```

   これは`global.openbao.psql`を使用します。これは、Toolboxからバックアップおよび復元する操作のためにアクセスできるため、推奨される場所です。高度な接続オプション（`sslMode`、`connectTimeout`、またはキープアライブチューニングなど）を設定するには、グローバル設定とともに`openbao.config.storage.postgresql.connection`を使用します。

1. OpenBaoをデプロイまたはアップグレードします。起動すると、OpenBaoは指定されたデータベース内にデータベーススキーマを自動的に作成します。
