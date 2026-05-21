---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabチャートの前提条件
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

KubernetesクラスターにGitLabをデプロイする前に、以下の前提条件をインストールし、インストール時に使用するオプションを決定してください。

## 前提条件 {#prerequisites}

### kubectl {#kubectl}

`kubectl`を[Kubernetes documentation](https://kubernetes.io/docs/tasks/tools/#kubectl)に従ってインストールします。インストールするバージョンは、クラスターで実行されているバージョンと[within one minor release](https://kubernetes.io/releases/version-skew-policy/#kubectl)でなければなりません。

### Helm {#helm}

Helm v4.0以降を[Helm documentation](https://helm.sh/docs/intro/install/)に従ってインストールします。

GitLabチャートは、公式EOL（[estimated in July 2026](https://helm.sh/community/hips/hip-0012/#the-process--timelines)）までHelm 3のサポートを継続します。

### PostgreSQL {#postgresql}

本番環境のデプロイには、[external PostgreSQL instance](../advanced/external-db/_index.md)を設定します。

サポートされているPostgreSQLバージョンについては、[the GitLab requirements](https://docs.gitlab.com/install/requirements/#postgresql)を確認してください。

> [!note] GitLabチャートには、評価目的でのみ[`bitnami/PostgreSQL`](https://artifacthub.io/packages/helm/bitnami/postgresql)によって提供されるバンドルされたPostgreSQLデプロイが含まれています。

### Redis {#redis}

本番環境のデプロイには、[external Redis instance](../advanced/external-redis/_index.md)を設定します。利用可能なすべての設定については、[Redis globals documentation](../charts/globals.md#configure-redis-settings)を参照してください。

> [!note] GitLabチャートには、評価目的でのみ[`bitnami/Redis`](https://artifacthub.io/packages/helm/bitnami/redis)によって提供されるバンドルされたRedisデプロイが含まれています。

### Gitaly {#gitaly}

デフォルトでは、GitLabチャートにはインクラスターGitalyデプロイが含まれています。本番環境では、KubernetesでのGitalyの実行はサポートされていません。[Gitaly is only supported on conventional virtual machines](https://docs.gitlab.com/administration/reference_architectures/#stateful-components-in-kubernetes)。

[external, production-ready Gitaly instance](../advanced/external-gitaly/_index.md)を設定する必要があります。利用可能なすべての設定については、[Gitaly globals documentation](../charts/globals.md#configure-gitaly-settings)を参照してください。

## その他のオプションを決定する {#decide-on-other-options}

GitLabをデプロイする際に、`helm install`とともに以下のオプションを使用します。

### シークレット {#secrets}

SSHキーのようなシークレットを作成する必要があります。デフォルトでは、これらのシークレットはデプロイ中に自動的に生成されますが、それらを指定したい場合は、[secrets documentation](secrets.md)を参照してください。

### ネットワーキングとDNS {#networking-and-dns}

デフォルトでは、サービスを公開するために、GitLabは`Ingress`オブジェクトで設定された名前ベースの仮想サーバーを使用します。これらのオブジェクトは、Kubernetes `Service`の`type: LoadBalancer`オブジェクトです。

`gitlab`、`registry`、および`minio`（有効な場合）を、チャートの適切なIPアドレスに解決するレコードを含むドメインを指定する必要があります。

たとえば、`helm install`とともに次を使用します:

```shell
--set global.hosts.domain=example.com
```

カスタムドメインサポートが有効な場合、デフォルトで`<pages domain>`である`*.<pages domain>`サブドメインは、`pages.<global.hosts.domain>`になります。このドメインは、`--set global.pages.externalHttp`または`--set global.pages.externalHttps`によってPagesに割り当てられた外部IPに解決されます。

カスタムドメインを使用するには、GitLab Pagesは、カスタムドメインを対応する`<namespace>.<pages domain>`ドメインにポイントするCNAMEレコードを使用できます。

#### 動的IPアドレスと`external-dns` {#dynamic-ip-addresses-with-external-dns}

[`external-dns`](https://github.com/kubernetes-sigs/external-dns)のような自動DNS登録サービスを使用する予定がある場合は、GitLabの追加の設定は必要ありません。ただし、`external-dns`をクラスターにデプロイする必要があります。プロジェクトページには、サポートされている各プロバイダー向けの[has a comprehensive guide](https://github.com/kubernetes-sigs/external-dns#deploying-to-a-cluster)があります。

> [!note] GitLab Pagesのカスタムドメインサポートを有効にすると、`external-dns`はPagesドメイン（デフォルトでは`pages.<global.hosts.domain>`）では機能しなくなります。ドメインをPages専用の外部IPアドレスにポイントするように、DNSレコードを手動で設定する必要があります。

[GKE cluster](cloud/gke.md)をプロビジョニングする場合、`external-dns`がクラスターに自動的にインストールされます。

#### 静的IPアドレス {#static-ip-addresses}

手動でDNSレコードを設定する予定がある場合は、すべて静的IPアドレスを指すようにする必要があります。たとえば、`example.com`を選択し、`10.10.10.10`の静的IPアドレスを持っている場合、`gitlab.example.com`、`registry.example.com`、および`minio.example.com`（MinIOを使用している場合）はすべて`10.10.10.10`に解決される必要があります。

GKEを使用している場合は、[creating the external IP and DNS entry](cloud/gke.md#creating-the-external-ip)の詳細を参照してください。このプロセスに関する詳細については、クラウドプロバイダーまたはDNSプロバイダーのドキュメントを参照してください。

たとえば、`helm install`とともに次を使用します:

```shell
--set global.hosts.externalIP=10.10.10.10
```

#### Istioプロトコル選択との互換性 {#compatibility-with-istio-protocol-selection}

サービスポート名は、Istioの[explicit port selection](https://istio.io/latest/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection)と互換性のある規則に従います。これらは`<protocol>-<suffix>`のようになります。たとえば、`tls-gitaly`または`https-metrics`です。

GitalyとKASはgRPCを使用しますが、[Issue #3822](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3822)および[Issue #4908](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4908)の調査結果により、代わりに`tcp`プレフィックスを使用します。

### 永続 {#persistence}

デフォルトでは、GitLabチャートは、動的なプロビジョナーが基盤となる永続ボリュームを作成することを期待してボリュームクレームを作成します。`storageClass`をカスタマイズしたり、ボリュームを手動で作成および割り当てたりする場合は、[storage documentation](storage.md)を参照してください。

> [!note]初期のデプロイ後、ストレージ設定を変更するには、Kubernetesオブジェクトを手動で編集する必要があります。したがって、追加のストレージ移行作業を避けるため、本番環境インスタンスをデプロイする前に事前に計画を立てるのが最善です。

### TLS証明書 {#tls-certificates}

GitLabはHTTPSで実行する必要があります。これにはTLS証明書が必要です。デフォルトでは、GitLabチャートは、無料のTLS証明書を取得するために[`cert-manager`](https://github.com/cert-manager/cert-manager)をインストールして設定します。

独自のワイルドカード証明書をお持ちの場合、またはすでに`cert-manager`をインストールしている場合、あるいはTLS証明書を取得する他の方法がある場合は、[TLS options](tls.md)で詳細を参照してください。

デフォルトの設定では、TLS証明書を登録するためにメールアドレスを指定する必要があります。たとえば、`helm install`とともに次を使用します:

```shell
--set certmanager-issuer.email=me@example.com
```

### Prometheus {#prometheus}

私たちは[upstream Prometheus chart](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration)を使用しており、カスタマイズされた`prometheus.yml`ファイルを除いて、独自のデフォルトから値をオーバーライドしません。このファイルは、Kubernetes APIとGitLabチャートによって作成されたオブジェクトへのメトリクスの収集を制限します。ただし、デフォルトでは、`alertmanager`、`node-exporter`、`pushgateway`、および`kube-stat-metrics`を無効にします。

`prometheus.yml`ファイルは、Prometheusに`gitlab.com/prometheus_scrape`アノテーションを持つリソースからメトリクスを収集するように指示します。さらに、`gitlab.com/prometheus_path`と`gitlab.com/prometheus_port`アノテーションを使用して、メトリクスがどのように検出されるかを設定できます。これらのアノテーションはそれぞれ、`prometheus.io/{scrape,path,port}`アノテーションに匹敵します。

お使いのPrometheusのインストールでGitLabアプリケーションをモニタリングしている、またはモニタリングしたい場合は、元の`prometheus.io/*`アノテーションが適切なポッドとサービスに引き続き追加されます。これにより、既存ユーザーのメトリクス収集の継続性が確保され、デフォルトのPrometheus設定を使用してGitLabアプリケーションメトリクスとKubernetesクラスターで実行されている他のアプリケーションの両方をキャプチャする機能が提供されます。

[upstream Prometheus chart documentation](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration)で設定オプションの網羅的なリストを参照し、これらが`prometheus`のサブキーであることを確認してください。これは要件チャートとして使用するためです。

たとえば、永続ストレージのリクエストは次のように制御できます:

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

#### PrometheusでTLS対応エンドポイントをスクレイプするように設定する {#configure-prometheus-to-scrape-tls-enabled-endpoints}

指定されたexporterがTLSを許可し、チャートの設定がexporterのエンドポイントのTLS設定を公開している場合、PrometheusはTLS対応エンドポイントからメトリクスをスクレイプするように設定できます。

TLSと[Kubernetes Service Discovery](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config)をPrometheusの[scrape configurations](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config)に使用する場合、いくつかの注意点があります:

- [pod](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#pod)と[service endpoints](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#endpoints)のディスカバリロールの場合、Prometheusはポッドの内部IPアドレスを使用して、スクレイプターゲットのアドレスを設定します。TLS証明書を検証するには、Prometheusは、メトリクスエンドポイント用に作成された証明書に設定されているコモンネーム（CN）で設定するか、サブジェクト代替名（SAN）拡張に含まれる名前で設定する必要があります。その名前は解決される必要はなく、[valid DNS name](https://datatracker.ietf.org/doc/html/rfc1034#section-3.1)である任意の文字列でかまいません。
- exporterのエンドポイントに使用される証明書が自己署名されているか、またはPrometheusのベースイメージに存在しない場合、Prometheusポッドは、exporterのエンドポイントに使用される証明書に署名した認証局（CA）の証明書をマウントする必要があります。Prometheusは、Debianから`ca-bundle`を[in its base image](https://github.com/prometheus/busybox)で使用します。
- Prometheusは、これらの両方の項目を[tls_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#tls_config)を使用して設定することをサポートしており、これは各スクレイプ設定に適用されます。Prometheusには、ポッドアノテーションおよびその他の検出された属性に基づいてPrometheusターゲットラベルを設定するための堅牢な[relabel_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config)メカニズムがありますが、`relabel_config`を使用して`tls_config.server_name`と`tls_config.ca_file`を設定することはできません。詳細については、この[Prometheus project issue](https://github.com/prometheus/prometheus/issues/4827)を参照してください。

これらの注意点を考慮すると、最も簡単な設定は、exporterエンドポイントに使用されるすべての証明書で「name」とCAを共有することです:

1. `tls_config.server_name`に使用する単一の任意の名前を選択します（たとえば、`metrics.gitlab`）。
1. その名前を、exporterエンドポイントをTLSで暗号化するために使用される各証明書のSANリストに追加します。
1. すべての証明書を同じCAから発行します:
   - CA証明書をクラスターシークレットとして追加します。
   - そのシークレットを、[Prometheus chart's](https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/values.yaml) `extraSecretMounts:`設定を使用してPrometheusサーバーコンテナにマウントします。
   - それをPrometheusの`scrape_config`の`tls_config.ca_file`として設定します。

[Prometheus TLS values example](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/prometheus/values-tls.yaml)は、この共有設定の例を次のように提供します:

1. ポッド/エンドポイント`scrape_config`ロールの`tls_config.server_name`を`metrics.gitlab`に設定します。
1. `metrics.gitlab`が、exporterエンドポイントに使用されるすべての証明書のSANリストに追加されていると仮定します。
1. CA証明書が、Prometheusチャートがデプロイされている同じネームスペースに作成された`metrics.gitlab.tls-ca`という名前のシークレットに、`metrics.gitlab.tls-ca`という名前のシークレットキーとともに追加されていると仮定します（たとえば、`kubectl create secret generic --namespace=gitlab metrics.gitlab.tls-ca --from-file=metrics.gitlab.tls-ca=./ca.pem`）。
1. その`metrics.gitlab.tls-ca`シークレットを`/etc/ssl/certs/metrics.gitlab.tls-ca`に`extraSecretMounts:`エントリを使用してマウントします。
1. `tls_config.ca_file`を`/etc/ssl/certs/metrics.gitlab.tls-ca`に設定します。

#### Exporterエンドポイント {#exporter-endpoints}

GitLabチャートに含まれるすべてのメトリクスエンドポイントがTLSをサポートしているわけではありません。エンドポイントがTLSを有効にできる場合は、`gitlab.com/prometheus_scheme: "https"`アノテーションと`prometheus.io/scheme: "https"`アノテーションも設定します。これらはいずれも`relabel_config`とともに使用してPrometheus `__scheme__`ターゲットラベルを設定できます。[Prometheus TLS values example](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/prometheus/values-tls.yaml)には、`gitlab.com/prometheus_scheme: "https"`アノテーションを使用して`__scheme__`をターゲットとする`relabel_config`が含まれています。

以下の表に、GitalyとPraefectのいずれかまたは両方を使用する場合のデプロイメントをリストします: StatefulSets）および`gitlab.com/prometheus_scrape: true`アノテーションが適用されているサービスエンドポイント。

以下のドキュメントリンクで、コンポーネントがSANエントリの追加について言及している場合は、Prometheus `tls_config.server_name`に使用することに決めたSANも追加してください。

| サービス                                                       | メトリクスポート（デフォルト） | TLSをサポートしていますか？ | 追加情報 |
|:--------------------------------------------------------------|:----------------------|:--------------|:-----------------------|
| [Gitaly](../charts/gitlab/gitaly/_index.md)                   | `9236`                | {{< yes >}}   | `global.gitaly.tls.enabled=true`を使用して有効化<br><br>デフォルトシークレット: `RELEASE-gitaly-tls`<br><br>[ドキュメント: TLS経由でのGitalyの実行](../charts/gitlab/gitaly/_index.md#running-gitaly-over-tls) |
| [GitLab Exporter](../charts/gitlab/gitlab-exporter/_index.md) | `9168`                | {{< yes >}}   | `gitlab.gitlab-exporter.tls.enabled=true`を使用して有効化<br><br>デフォルトシークレット: `RELEASE-gitlab-exporter-tls` |
| [GitLab Pages](../charts/gitlab/gitlab-pages/_index.md)       | `9235`                | {{< yes >}}   | `gitlab.gitlab-pages.metrics.tls.enabled=true`を使用して有効化<br><br>デフォルトシークレット: `RELEASE-pages-metrics-tls`<br><br>[ドキュメント: 一般設定](../charts/gitlab/gitlab-pages/_index.md#general-settings) |
| [GitLab Runner](../charts/gitlab/gitlab-runner/_index.md)     | `9252`                | {{< no >}}    | [Issue - Add TLS Support for Metrics Endpoint](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29176) |
| [GitLab Shell](../charts/gitlab/gitlab-shell/_index.md)       | `9122`                | {{< no >}}    | GitLab Shellメトリクスexporterは、[`gitlab-sshd`](https://docs.gitlab.com/administration/operations/gitlab_sshd/)を使用している場合にのみ有効になります。TLSを必要とする環境にはOpenSSHが推奨されます。 |
| [KAS](../charts/gitlab/kas/_index.md)                         | `8151`                | {{< yes >}}   | `global.kas.customConfig.observability.listen.certificate_file`および`global.kas.customConfig.observability.listen.key_file`オプションを使用して設定できます。 |
| [Praefect](../charts/gitlab/praefect/_index.md)               | `9236`                | {{< yes >}}   | `global.praefect.tls.enabled=true`を使用して有効化<br><br>デフォルトシークレット: `RELEASE-praefect-tls`<br><br>[ドキュメント: TLS経由でのPraefectの実行](../charts/gitlab/praefect/_index.md#running-praefect-over-tls) |
| [レジストリ](../charts/registry/_index.md)                      | `5100`                | {{< yes >}}   | `registry.debug.tls.enabled=true`を使用して有効化<br><br>[ドキュメント: レジストリ - デバッグポートのTLSの設定](../charts/registry/_index.md#configuring-tls-for-the-debug-port) |
| [Sidekiq](../charts/gitlab/sidekiq/_index.md)                 | `3807`                | {{< yes >}}   | `gitlab.sidekiq.metrics.tls.enabled=true`を使用して有効化<br><br>デフォルトシークレット: `RELEASE-sidekiq-metrics-tls`<br><br>[ドキュメント: インストールコマンドラインオプション](../charts/gitlab/sidekiq/_index.md#installation-command-line-options) |
| [Webservice](../charts/gitlab/sidekiq/_index.md)              | `8083`                | {{< yes >}}   | `gitlab.webservice.metrics.tls.enabled=true`を使用して有効化<br><br>デフォルトシークレット: `RELEASE-webservice-metrics-tls`<br><br>[ドキュメント: インストールコマンドラインオプション](../charts/gitlab/webservice/_index.md#installation-command-line-options) |
| [Ingress-NGINX](../charts/nginx/_index.md)                    | `10254`               | {{< no >}}    | メトリクス/ヘルスチェックポートではTLSをサポートしていません。 |

ウェブサービスポッドの場合、公開ポートはウェブサービスコンテナ内のスタンドアロンのwebrick exporterです。ワークホースコンテナポートはスクレイプされません。追加の詳細については、[Webservice Metrics documentation](../charts/gitlab/webservice/_index.md#metrics)を参照してください。

### 送信メール {#outgoing-email}

デフォルトでは、送信メールは無効になっています。これを有効にするには、`global.smtp`と`global.email`設定を使用してSMTPサーバーの詳細を指定します。これらの設定の詳細については、[command line options](command-line-options.md#outgoing-email-configuration)で確認できます。

SMTPサーバーで認証が必要な場合は、[secrets documentation](secrets.md#smtp-password)でパスワードの提供に関するセクションを必ずお読みください。`--set global.smtp.authentication=""`を使用して認証設定を無効にできます。

お使いのKubernetesクラスターがGKE上にある場合、SMTP [port 25 is blocked](https://cloud.google.com/compute/docs/tutorials/sending-mail/#using_standard_email_ports)に注意してください。

### 受信メール {#incoming-email}

受信メールの設定は、[mailroom chart](../charts/gitlab/mailroom/_index.md#incoming-email)にドキュメント化されています。

### サービスデスクのメール {#service-desk-email}

受信メールの設定は、[mailroom chart](../charts/gitlab/mailroom/_index.md#service-desk-email)にドキュメント化されています。

### RBAC {#rbac}

GitLabチャートは、デフォルトで[RBAC](rbac.md)を作成して使用します。クラスターでRBACが有効になっていない場合は、これらの設定を無効にする必要があります:

```shell
--set certmanager.rbac.create=false
--set nginx-ingress.rbac.createRole=false
--set prometheus.rbac.create=false
--set gitlab-runner.rbac.create=false
```

## 次の手順 {#next-steps}

[Set up your cloud provider and create your cluster](cloud/_index.md)。
