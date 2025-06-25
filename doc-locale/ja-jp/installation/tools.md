---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートの前提要件
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

KubernetesクラスターにGitLabをデプロイする前に、以下の前提要件をインストールし、インストール時に使用するオプションを決定します。

## 前提要件 {#prerequisites}

### kubectl {#kubectl}

[Kubernetesのドキュメント](https://kubernetes.io/docs/tasks/tools/#kubectl)に従って、`kubectl`をインストールします。インストールするのバージョンは、クラスターで実行されているバージョンの[マイナーリリース1つ以内](https://kubernetes.io/releases/version-skew-policy/#kubectl)である必要があります。

### Helm {#helm}

[Helmのドキュメント](https://helm.sh/docs/intro/install/)に従って、Helm v3.10.3以降をインストールします。

### PostgreSQL {#postgresql}

デフォルトでは、GitLabチャートには、[`bitnami/PostgreSQL`](https://artifacthub.io/packages/helm/bitnami/postgresql)によって提供される、クラスター内PostgreSQLのデプロイメントが含まれています。このデプロイメントはトライアル目的のみであり、**本番環境での使用は推奨されません**。

[外部の本番環境対応PostgreSQLインスタンス](../advanced/external-db/_index.md)をセットアップする必要があります。推奨されるデフォルトのバージョン:

- PostgreSQL 13（GitLabチャート6.0以降）。
- PostgreSQL 14（GitLabチャート8.0以降）。

GitLabチャート4.0.0の時点では、レプリケーションは内部で利用可能ですが、デフォルトでは有効になっていません。このような機能は、GitLabによって負荷テストされていません。

### Redis {#redis}

デフォルトでは、GitLabチャートには、[`bitnami/Redis`](https://artifacthub.io/packages/helm/bitnami/redis)によって提供される、クラスター内Redisのデプロイメントが含まれています。このデプロイメントはトライアル目的のみであり、**本番環境での使用は推奨されません**。

[外部の本番環境対応Redisインスタンス](../advanced/external-redis/_index.md)をセットアップする必要があります。利用可能なすべての設定については、[Redisグローバルドキュメント](../charts/globals.md#configure-redis-settings)を参照してください。

GitLabチャート4.0.0の時点では、レプリケーションは内部で利用可能ですが、デフォルトでは有効になっていません。このような機能は、GitLabによって負荷テストされていません。

### Gitaly {#gitaly}

デフォルトでは、GitLabチャートには、クラスター内Gitalyのデプロイメントが含まれています。本番環境の場合、KubernetesでのGitalyの実行はサポートされていません。[Gitalyは、従来の仮想マシンでのみサポートされています](https://docs.gitlab.com/administration/reference_architectures/#stateful-components-in-kubernetes)。

[外部の本番環境対応Gitalyインスタンス](../advanced/external-gitaly/_index.md)をセットアップする必要があります。利用可能なすべての設定については、[Gitalyグローバルドキュメント](../charts/globals.md#configure-gitaly-settings)を参照してください。

## その他のオプションの決定 {#decide-on-other-options}

GitLabをデプロイする際、`helm install`で次のオプションを使用します。

### シークレット {#secrets}

SSH鍵などのシークレットを作成する必要があります。デフォルトでは、これらのシークレットはデプロイメント中に自動的に生成されますが、指定する場合は、[シークレットドキュメント](secrets.md)に従ってください。

### ネットワーキングとDNS {#networking-and-dns}

デフォルトでは、サービスを公開するために、GitLabは`Ingress`オブジェクトで設定された名前ベースの仮想サーバーを使用します。これらのオブジェクトは、`type: LoadBalancer`のKubernetes `Service`オブジェクトです。

チャートの適切なIPアドレスに`gitlab`、`registry`、および`minio`（有効な場合）を解決するレコードを含むドメインを指定する必要があります。

次に例を示します。`helm install`で以下を使用します。

```shell
--set global.hosts.domain=example.com
```

カスタムドメインのサポートを有効にすると、デフォルトで`<pages domain>`である`*.<pages domain>`サブドメインは`pages.<global.hosts.domain>`になります。ドメインは、`--set global.pages.externalHttp`または`--set global.pages.externalHttps`によってPagesに割り当てられた外部IPに解決されます。

カスタムドメインを使用するには、GitLab Pagesは、カスタムドメインを対応する`<namespace>.<pages domain>`ドメインにポイントするCNAMEレコードを使用できます。

#### `external-dns`を使用した動的IPアドレス {#dynamic-ip-addresses-with-external-dns}

[`external-dns`](https://github.com/kubernetes-sigs/external-dns)のような自動DNS登録サービスを使用する場合は、GitLabに追加のDNS設定は必要ありません。ただし、`external-dns`をクラスターにデプロイする必要があります。プロジェクトページ[には、](https://github.com/kubernetes-sigs/external-dns#deploying-to-a-cluster)サポートされているプロバイダーごとに包括的なガイドがあります。

{{< alert type="note" >}}

GitLab Pagesのカスタムドメインのサポートを有効にした場合、`external-dns`はPagesドメイン（デフォルトでは`pages.<global.hosts.domain>`）では機能しなくなります。Pages専用の外部IPアドレスにドメインをポイントするように、DNSエントリを手動で設定する必要があります。

{{< /alert >}}

提供されているスクリプトを使用して[GKEクラスター](cloud/gke.md)をプロビジョニングする場合、`external-dns`はクラスターに自動的にインストールされます。

#### 静的IPアドレス {#static-ip-addresses}

DNSレコードを手動で設定する場合は、すべて静的IPアドレスを指す必要があります。たとえば、`example.com`を選択し、`10.10.10.10`の静的IPアドレスがある場合、`gitlab.example.com`、`registry.example.com`、および`minio.example.com`（MinIOを使用している場合）はすべて`10.10.10.10`に解決される必要があります。

GKEを使用している場合は、[外部IPとDNSエントリの作成](cloud/gke.md#creating-the-external-ip)の詳細をお読みください。このプロセスの詳細については、クラウドまたはDNSプロバイダーのドキュメントを参照してください。

次に例を示します。`helm install`で以下を使用します。

```shell
--set global.hosts.externalIP=10.10.10.10
```

#### Istioプロトコル選択との互換性 {#compatibility-with-istio-protocol-selection}

サービスポート名は、Istioの[明示的なポート選択](https://istio.io/latest/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection)と互換性のある規則に従います。たとえば、`tls-gitaly`や`https-metrics`のように、`<protocol>-<suffix>`のように見えます。

GitalyとKASはgRPCを使用しますが、[Issue #3822](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3822)と[Issue #4908](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4908)の発見により、代わりに`tcp`プレフィックスを使用することに注意してください。

### 永続性 {#persistence}

デフォルトでは、GitLabチャートは、動的プロビジョナーが基盤となる永続ボリュームを作成することを期待して、ボリューム要求を作成します。`storageClass`をカスタマイズするか、手動でボリュームを作成して割り当てる場合は、[ストレージドキュメント](storage.md)を確認してください。

{{< alert type="note" >}}

最初のデプロイ後、ストレージ設定を変更するには、Kubernetesオブジェクトを手動で編集する必要があります。したがって、ストレージの移行作業を余分に行わないように、本番環境インスタンスをデプロイする前に事前に計画しておくことをお勧めします。

{{< /alert >}}

### TLS証明書 {#tls-certificates}

TLS証明書を必要とするHTTPSでGitLabを実行する必要があります。デフォルトでは、GitLabチャートは無料のTLS証明書を取得するために[`cert-manager`](https://github.com/cert-manager/cert-manager)をインストールして設定します。

独自のワイルドカード証明書がある場合、または`cert-manager`が既にインストールされている場合、またはTLS証明書を取得する他の方法がある場合は、[TLSオプション](tls.md)の詳細をお読みください。

デフォルト設定では、TLS証明書を登録するためにメールアドレスを指定する必要があります。次に例を示します。`helm install`で以下を使用します。

```shell
--set certmanager-issuer.email=me@example.com
```

### Prometheus {#prometheus}

KubernetesおよびGitLabチャートによって作成されたオブジェクトへのメトリクスの収集を制限するためにカスタマイズされた`prometheus.yml`ファイル以外に、[アップストリームPrometheusチャート](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration)を使用し、独自のデフォルトからの値をオーバーライドしません。ただし、デフォルトでは、`alertmanager`、`node-exporter`、`pushgateway`、および`kube-stat-metrics`を無効にします。

`prometheus.yml`ファイルは、`gitlab.com/prometheus_scrape`アノテーションを持つリソースからメトリックを収集するようにPrometheusに指示します。さらに、`gitlab.com/prometheus_path`および`gitlab.com/prometheus_port`アノテーションを使用して、メトリクスの検出方法を設定できます。これらのアノテーションはそれぞれ、`prometheus.io/{scrape,path,port}`アノテーションに匹敵します。

PrometheusのインストールでGitLabアプリケーションを監視している場合、または監視する場合は、元のアノテーション`prometheus.io/*`が適切なポッドとサービスに引き続き追加されます。これにより、既存のユーザーのメトリクス収集の継続性が可能になり、デフォルトのPrometheus設定を使用して、GitLabアプリケーションメトリクスと、Kubernetesクラスターで実行されている他のアプリケーションの両方をキャプチャできます。

設定オプションの網羅的なリストについては、[アップストリームPrometheusチャートドキュメント](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration)を参照し、要件チャートとしてこれを使用するため、それらが`prometheus`のサブキーであることを確認してください。

たとえば、永続ストレージのリクエストは、次のように制御できます。

```yaml
prometheus:
  alertmanager:
    enabled: false
    persistentVolume:
      enabled: false
      size: 2Gi
  prometheus-pushgateway:
    enabled: false
    persistentVolume:
      enabled: false
      size: 2Gi
  server:
    persistentVolume:
      enabled: true
      size: 8Gi
```

#### TLS対応エンドポイントをスクレイピングするようにPrometheusを設定する {#configure-prometheus-to-scrape-tls-enabled-endpoints}

指定されたexporterがTLSを許可し、チャート設定がexporterのエンドポイントのTLS設定を公開する場合、PrometheusはTLS対応エンドポイントからメトリクスをスクレイピングするように設定できます。

Prometheus [スクレイプ設定](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config)に[Kubernetesサービスディスカバリ](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config)とTLSを使用する場合、いくつかの注意事項があります。

- [ポッド](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#pod)および[サービスエンドポイント](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#endpoints)ディスカバリロールの場合、Prometheusはポッドの内部アドレスを使用して、スクレイプターゲットのアドレスを設定します。TLS証明書を検証するには、Prometheusは、メトリクスエンドポイント用に作成された証明書に設定された共通名（CN）を使用するか、サブジェクトの代替名（SAN）拡張機能に含まれる名前を使用して構成する必要があります。名前は解決する必要はなく、[有効なDNS名](https://datatracker.ietf.org/doc/html/rfc1034#section-3.1)である任意の文字列にすることができます。
- exporterのエンドポイントに使用される証明書が自己署名されているか、Prometheusベースイメージに存在しない場合、Prometheusポッドはexporterのエンドポイントに使用される証明書に署名した認証局（CA）の証明書をマウントする必要があります。Prometheusは、[ベースイメージ](https://github.com/prometheus/busybox)内のDebianからの`ca-bundle`を使用します。
- Prometheusは、スクレイプ設定のそれぞれに適用される[tls_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#tls_config)を使用して、これらの項目の両方を設定することをサポートしています。Prometheusには、ポッドアノテーションやその他の検出された属性に基づいてPrometheusターゲットラベルを設定するための堅牢な[relabel_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config)メカニズムがありますが、`tls_config.server_name`および`tls_config.ca_file`を設定することは、`relabel_config`を使用して行うことはできません。詳細については、[このPrometheusプロジェクトイシュー](https://github.com/prometheus/prometheus/issues/4827)を参照してください。

これらの注意事項を考慮すると、最も単純な設定は、「名前」とをexporterエンドポイントに使用されるすべての証明書間で共有することです。

1. `tls_config.server_name`（たとえば、`metrics.gitlab`）に使用する単一の任意の名前を選択します。
1. exporterエンドポイントをTLS暗号化するために使用される各証明書のSANリストにその名前を追加します。
1. 同じからすべての証明書を発行します:
   - 証明書をクラスターシークレットとして追加します。
   - [Prometheusチャート](https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/values.yaml)の`extraSecretMounts:`設定を使用して、そのシークレットをPrometheusサーバーコンテナにマウントします。
   - Prometheus `scrape_config`の`tls_config.ca_file`としてそれを設定します。

[Prometheus TLS値の例](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/prometheus/values-tls.yaml)は、この共有設定の例を示しています:

1. ポッド/エンドポイント`scrape_config`ロールの場合、`tls_config.server_name`を`metrics.gitlab`に設定します。
1. `metrics.gitlab`がexporterエンドポイントに使用されるすべての証明書のSANリストに追加されていると仮定します。
1. 証明書が、Prometheusチャートがデプロイされているのと同じネームスペースで作成された、シークレットキーも`metrics.gitlab.tls-ca`という名前の`metrics.gitlab.tls-ca`という名前のシークレットに追加されていると仮定します（たとえば、`kubectl create secret generic --namespace=gitlab metrics.gitlab.tls-ca --from-file=metrics.gitlab.tls-ca=./ca.pem`）。
1. `extraSecretMounts:`エントリを使用して、その`metrics.gitlab.tls-ca`シークレットを`/etc/ssl/certs/metrics.gitlab.tls-ca`にマウントします。
1. `tls_config.ca_file`を`/etc/ssl/certs/metrics.gitlab.tls-ca`に設定します。

#### Exporterエンドポイント {#exporter-endpoints}

GitLabチャートに含まれるすべてのメトリクスエンドポイントがTLSをサポートしているわけではありません。エンドポイントがTLS対応可能で、TLS対応になっている場合は、`gitlab.com/prometheus_scheme: "https"`アノテーションと`prometheus.io/scheme: "https"`アノテーションも設定されます。これらのアノテーションは、`relabel_config`と組み合わせてPrometheus `__scheme__`ターゲットラベルを設定するために使用できます。[Prometheus TLSの値の例](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/prometheus/values-tls.yaml)には、`gitlab.com/prometheus_scheme: "https"`アノテーションを使用して`__scheme__`をターゲットとする`relabel_config`が含まれています。

次のテーブルは、デプロイメント（またはGitalyとPraefectの両方を使用している場合:`gitlab.com/prometheus_scrape: true`アノテーションが適用されたStatefulSets）およびサービスエンドポイントを一覧表示します。

以下のドキュメントリンクで、コンポーネントがSANエントリの追加について言及している場合は、Prometheus `tls_config.server_name`に使用することにしたSANも必ず追加してください。

| サービス | メトリクスポート（デフォルト） | TLSをサポートしていますか？ | 注釈/ドキュメント/イシュー |
| ---     | ---                   | ---           | ---              |
| [Gitaly](../charts/gitlab/gitaly/_index.md)                   | 9236  | はい | `global.gitaly.tls.enabled=true`を使用して有効化<br>デフォルトのシークレット:`RELEASE-gitaly-tls`<br>[ドキュメント:TLS経由でのGitalyの実行](../charts/gitlab/gitaly/_index.md#running-gitaly-over-tls) |
| [GitLab Exporter](../charts/gitlab/gitlab-exporter/_index.md) | 9168  | はい | `gitlab.gitlab-exporter.tls.enabled=true`を使用して有効化<br>デフォルトのシークレット:`RELEASE-gitlab-exporter-tls` |
| [GitLab Pages](../charts/gitlab/gitlab-pages/_index.md)       | 9235  | はい | `gitlab.gitlab-pages.metrics.tls.enabled=true`を使用して有効化<br>デフォルトのシークレット:`RELEASE-pages-metrics-tls`<br>[ドキュメント:一般設定](../charts/gitlab/gitlab-pages/_index.md#general-settings) |
| [GitLab Runner](../charts/gitlab/gitlab-runner/_index.md)     | 9252  | いいえ  | [イシュー - メトリクスエンドポイントへのTLSサポートの追加](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29176) |
| [GitLab Shell](../charts/gitlab/gitlab-shell/_index.md)       | 9122  | いいえ  | GitLab Shellメトリクスexporterは、[`gitlab-sshd`](https://docs.gitlab.com/administration/operations/gitlab_sshd/)を使用する場合にのみ有効になります。TLSを必要とする環境には、OpenSSHをお勧めします |
| [KAS](../charts/gitlab/kas/_index.md)                         | 8151  | はい | `global.kas.customConfig.observability.listen.certificate_file`および`global.kas.customConfig.observability.listen.key_file`オプションを使用して設定できます |
| [Praefect](../charts/gitlab/praefect/_index.md)               | 9236  | はい | `global.praefect.tls.enabled=true`を使用して有効化<br>デフォルトのシークレット:`RELEASE-praefect-tls`<br>[ドキュメント:TLS経由でのPraefectの実行](../charts/gitlab/praefect/_index.md#running-praefect-over-tls) |
| [レジストリ](../charts/registry/_index.md)                      | 5100  | はい | `registry.debug.tls.enabled=true`を使用して有効化<br>[ドキュメント:レジストリ - デバッグポートのTLSの設定](../charts/registry/_index.md#configuring-tls-for-the-debug-port) |
| [Sidekiq](../charts/gitlab/sidekiq/_index.md)                 | 3807  | はい | `gitlab.sidekiq.metrics.tls.enabled=true`を使用して有効化<br>デフォルトのシークレット:`RELEASE-sidekiq-metrics-tls`<br>[ドキュメント:インストールコマンドラインオプション](../charts/gitlab/sidekiq/_index.md#installation-command-line-options) |
| [Webservice](../charts/gitlab/sidekiq/_index.md)              | 8083  | はい | `gitlab.webservice.metrics.tls.enabled=true`を使用して有効化<br>デフォルトのシークレット:`RELEASE-webservice-metrics-tls`<br>[ドキュメント:インストールコマンドラインオプション](../charts/gitlab/webservice/_index.md#installation-command-line-options) |
| [Ingress-NGINX](../charts/nginx/_index.md)                    | 10254 | いいえ  | メトリクス/ヘルスチェックポートでTLSをサポートしていません |

webserviceポッドの場合、公開されるポートはwebserviceコンテナ内のスタンドアロンのWebrick exporterです。Workhorseコンテナポートはスクレイピングされません。詳細については、[Webserviceメトリクスのドキュメント](../charts/gitlab/webservice/_index.md#metrics)を参照してください。

### 送信メール {#outgoing-email}

デフォルトでは、送信メールは無効になっています。有効にするには、`global.smtp`および`global.email`設定を使用して、SMTPサーバーの詳細を入力します。これらの設定の詳細については、[コマンドラインオプション](command-line-options.md#outgoing-email-configuration)を参照してください。

SMTPサーバーが認証を必要とする場合は、[シークレットドキュメント](secrets.md#smtp-password)でパスワードの提供に関するセクションを必ずお読みください。`--set global.smtp.authentication=""`を使用して認証設定を無効にすることができます。

KubernetesクラスターがGKEにある場合、SMTP [ポート25がブロックされている](https://cloud.google.com/compute/docs/tutorials/sending-mail/#using_standard_email_ports)ことに注意してください。

### 受信メール {#incoming-email}

受信[メール](../charts/gitlab/mailroom/_index.md#incoming-email)の設定については、[mailroomチャート](../charts/gitlab/mailroom/_index.md#incoming-email)に記載されています。

### サービスデスク {#service-desk-email}のメール

受信[メール](../charts/gitlab/mailroom/_index.md#service-desk-email)の設定については、[mailroomチャート](../charts/gitlab/mailroom/_index.md#service-desk-email)に記載されています。

### RBAC {#rbac}

GitLabチャートは[RBAC](rbac.md)の作成と使用がデフォルトです。クラスターでRBACが有効になっていない場合は、次の設定を無効にする必要があります。

```shell
--set certmanager.rbac.create=false
--set nginx-ingress.rbac.createRole=false
--set prometheus.rbac.create=false
--set gitlab-runner.rbac.create=false
```

## 次の手順 {#next-steps}

[クラウドプロバイダーをセットアップしてクラスターを作成する](cloud/_index.md)。
