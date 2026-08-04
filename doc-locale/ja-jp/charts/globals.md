---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: グローバル変数を使用してチャートを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

ラッパーHelmチャートのインストール時に同じ設定を何度も重複してすることを軽減するため、いくつかの設定は`global`の`values.yaml`セクションで設定できます。これらのグローバル設定は複数のチャートを通じて使用されますが、他のすべての設定はそのチャート内がスコーピングされます。グローバル変数の仕組みの詳細については、[グローバル変数に関するHelmドキュメント](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/#global-chart-values)を参照してください。

## ホストを設定する {#configure-host-settings}

GitLabグローバルホストの設定は、`global.hosts`キーの下にあります。

```yaml
global:
  hosts:
    domain: example.com
    hostSuffix: staging
    https: false
    externalIP:
    gitlab:
      name: gitlab.example.com
      https: false
    registry:
      name: registry.example.com
      https: false
    smartcard:
      name: smartcard.example.com
    kas:
      name: kas.example.com
    pages:
      name: pages.example.com
      https: false
    ssh: gitlab.example.com
```

| 名前                      |  型   | デフォルト       | 説明 |
|:--------------------------|:-------:|:--------------|:------------|
| `domain`                  | 文字列  | `example.com` | ベースドメイン。GitLabとレジストリは、この設定のサブドメインで公開されます。そのデフォルトは`example.com`ですが、`name`プロパティが設定されているホストには使用されません。下の`gitlab.name`と`registry.name`のセクションを参照してください。 |
| `externalIP`              |         | `nil`         | プロバイダーから要求される外部IPアドレスを設定します。これは、より複雑な`nginx.service.loadBalancerIP`の代わりに、[NGINXチャート](nginx/_index.md#configuring-nginx)内でテンプレート処理されて使用されます。 |
| `externalGeoIP`           |         | `nil`         | `externalIP`と同じですが、[NGINX Geoチャート](nginx/_index.md#gitlab-geo)用です。統合URLを使用して[GitLab Geo](../advanced/geo/_index.md)サイトの静的IPを設定するために必要です。`externalIP`とは異なっている必要があります。 |
| `https`                   | ブール値 | `true`        | trueに設定されている場合は、NGINXチャートが証明書にアクセスできることを確認する必要があります。Ingressの前にTLSターミネーションがある場合は、[`global.ingress.tls.enabled`](#configure-ingress-settings)を調べるとよいでしょう。外部URLでは、`https`の代わりに`http://`を使用するため、falseに設定します。 |
| `hostSuffix`              | 文字列  |               | [下記を参照](#hostsuffix)。 |
| `gitlab.https`            | ブール値 | `false`       | `hosts.https`または`gitlab.https`が`true`の場合、GitLab外部URLでは`http://`ではなく`https://`を使用します。 |
| `gitlab.name`             | 文字列  |               | GitLabのホスト名。設定されている場合、`global.hosts.domain`と`global.hosts.hostSuffix`の設定に関係なくこのホスト名が使用されます。 |
| `gitlab.hostnameOverride` | 文字列  |               | WebserviceのIngress設定で使用されているホスト名をオーバーライドします。ホスト名を内部ホスト名に書き換えるWAFの背後からGitLabに到達可能でなければならないという場合に役立ちます（例: `gitlab.example.com` --> `gitlab.cluster.local`）。 |
| `gitlab.serviceName`      | 文字列  | `webservice`  | GitLabサーバーを操作している`service`の名前。チャートにより、サービス（および現在の`.Release.Name`）のホスト名がテンプレート処理され、適切な内部`serviceName`が作成されます。 |
| `gitlab.servicePort`      | 文字列  | `workhorse`   | GitLabサーバーに到達できる`service`の名前付きポート。 |
| `keda.enabled`            | ブール値 | `false`       | `HorizontalPodAutoscalers`の代わりに[KEDA](https://keda.sh/) `ScaledObjects`を使用します |
| `registry.https`          | ブール値 | `false`       | `hosts.https`または`registry.https`が`true`の場合、レジストリの外部URLでは`http://`ではなく`https://`を使用します。 |
| `registry.name`           | 文字列  | `registry`    | レジストリのホスト名。設定されている場合、`global.hosts.domain`と`global.hosts.hostSuffix`の設定に関係なくこのホスト名が使用されます。 |
| `registry.serviceName`    | 文字列  | `registry`    | レジストリサーバーを操作している`service`の名前。チャートにより、サービス（および現在の`.Release.Name`）のホスト名がテンプレート処理され、適切な内部`serviceName`が作成されます。 |
| `registry.servicePort`    | 文字列  | `registry`    | レジストリサーバーに到達できる`service`の名前付きポート。 |
| `smartcard.name`          | 文字列  | `smartcard`   | スマートカード認証のホスト名。設定されている場合、`global.hosts.domain`と`global.hosts.hostSuffix`の設定に関係なくこのホスト名が使用されます。 |
| `kas.name`                | 文字列  | `kas`         | KASのホスト名。設定されている場合、`global.hosts.domain`と`global.hosts.hostSuffix`の設定に関係なくこのホスト名が使用されます。 |
| `kas.https`               | ブール値 | `false`       | `hosts.https`または`kas.https`が`true`の場合、KAS外部URLでは`ws://`ではなく`wss://`を使用します。 |
| `pages.name`              | 文字列  | `pages`       | GitLab Pagesのホスト名。設定されている場合、`global.hosts.domain`と`global.hosts.hostSuffix`の設定に関係なくこのホスト名が使用されます。 |
| `pages.https`             | 文字列  |               | `global.pages.https`、`global.hosts.pages.https`、または`global.hosts.https`が`true`の場合、プロジェクト設定UIにおいて、GitLab PagesのURLには`http://`ではなく`https://`を使用します。 |
| `ssh`                     | 文字列  |               | SSH経由でリポジトリを複製するためのホスト名。設定されている場合、`global.hosts.domain`と`global.hosts.hostSuffix`の設定に関係なくこのホスト名が使用されます。 |

### `hostSuffix` {#hostsuffix}

ベース`domain`を使用してホスト名を構成する際には`hostSuffix`がサブドメインに付加されますが、独自の`name`が設定されているホストには使用されません。

デフォルトでは未設定です。設定されている場合、サブドメインにハイフンとこのサフィックスが付加されます。以下の例では、`gitlab-staging.example.com`や`registry-staging.example.com`のような外部ホスト名が使用されることになります:

```yaml
global:
  hosts:
    domain: example.com
    hostSuffix: staging
```

## Horizontal Pod Autoscalerを設定する {#configure-horizontal-pod-autoscaler-settings}

HPAのGitLabグローバルホストの設定は、`global.hpa`キーの下にあります:

| 名前         |  型  | デフォルト | 説明 |
|:-------------|:------:|:--------|:------------|
| `apiVersion` | 文字列 |         | `HorizontalPodAutoscaler`オブジェクトの定義で使用するAPIバージョン。 |

## `PodDisruptionBudget`を設定する {#configure-poddisruptionbudget-settings}

PDBのGitLabグローバルホストの設定は、`global.pdb`キーの下にあります:

| 名前         |  型  | デフォルト | 説明 |
|:-------------|:------:|:--------|:------------|
| `apiVersion` | 文字列 |         | `PodDisruptionBudget`オブジェクトの定義で使用するAPIバージョン。 |

## `CronJob`を設定する {#configure-cronjob-settings}

`CronJobs`のGitLabグローバルホスト設定は、`global.batch.cronJob`キーの下にあります。

| 名前         |  型  | デフォルト | 説明 |
|:-------------|:------:|:--------|:------------|
| `apiVersion` | 文字列 |         | `CronJob`オブジェクトの定義で使用するAPIバージョン。 |

## モニタリングを設定する {#configure-monitoring-settings}

`ServiceMonitors`および`PodMonitors`のGitLabグローバル設定は、`global.monitoring`キーの下にあります。

| 名前      |  型   | デフォルト | 説明 |
|:----------|:-------:|:--------|:------------|
| `enabled` | ブール値 | `false` | `monitoring.coreos.com/v1` APIの可用性に関係なく、モニタリングリソースを有効にします。 |

## Ingressを設定する {#configure-ingress-settings}

IngressのGitLabグローバルホストの設定は、`global.ingress`キーの下にあります。

| 名前                           |  型   | デフォルト        | 説明 |
|:-------------------------------|:-------:|:---------------|:------------|
| `apiVersion`                   | 文字列  |                | Ingressオブジェクトの定義で使用するAPIバージョン。 |
| `annotations.*annotation-key*` | 文字列  |                | `annotation-key`は、あらゆるIngressでアノテーションとして値とともに使用される文字列です。例: `global.ingress.annotations."nginx\.ingress\.kubernetes\.io/enable-access-log"=true`。デフォルトの場合、グローバルアノテーションは提供されません。 |
| `configureCertmanager`         | ブール値 | `false`        | [下記を参照](#globalingressconfigurecertmanager)。 |
| `useNewIngressForCerts`        | ブール値 | `false`        | [下記を参照](#globalingressusenewingressforcerts)。 |
| `class`                        | 文字列  | `gitlab-nginx` | `Ingress`リソースの`kubernetes.io/ingress.class`アノテーションまたは`spec.IngressClassName`を制御するグローバル設定。無効にする場合は`none`、空にする場合は`""`に設定します。注: `none`または`""`の場合、不要なIngressリソースがチャートによってデプロイされないようにするため、`nginx-ingress.enabled=false`に設定してください。 |
| `enabled`                      | ブール値 | `false`        | サービスでサポートするIngressオブジェクトを作成するかどうかを制御するためのグローバル設定。GitLab 19.0以降、チャートはデフォルトでGateway APIを使用します。`true`に設定するとIngressに戻ります。 |
| `tls.enabled`                  | ブール値 | `true`         | `false`に設定すると、GitLabのTLSが無効になります。これは、IngressのTLSターミネーションを使用できない場合（TLSターミネーションプロキシがIngressコントローラーの前にある場合など）に役立ちます。httpsを完全に無効にする場合は、[`global.hosts.https`](#configure-host-settings)とともに`false`に設定する必要があります。 |
| `tls.secretName`               | 文字列  |                | `global.hosts.domain`で使用されるドメインの**ワイルドカード**証明書とキーが含まれる[Kubernetes TLS Secret](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)の名前。 |
| `path`                         | 文字列  | `/`            | [Ingressオブジェクト](https://kubernetes.io/docs/concepts/services-networking/ingress/)の`path`エントリのデフォルト |
| `pathType`                     | 文字列  | `Prefix`       | [パスタイプ](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types)を使用すると、パスのマッチング方法を指定できます。現在のデフォルトは`Prefix`ですが、ユースケースに応じて`ImplementationSpecific`や`Exact`も使用できます。 |
| `provider`                     | 文字列  | `nginx`        | 使用するIngressプロバイダーを定義するグローバル設定。`nginx`がデフォルトのプロバイダーとして使用されます。 |

[さまざまなクラウドプロバイダーの設定](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/examples)のサンプルが、examplesフォルダーにあります。

- [`AWS`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/ingress.yaml)
- [`GKE`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/gke/ingress.yaml)

### Ingressパス {#ingress-path}

このチャートでは、Ingressオブジェクトの`path`エントリの定義を変更する必要があるユーザーを支援する手段として、`global.ingress.path`を採用しています。多くのユーザーはこの設定を必要としないため、設定しないでください。

GCPで`ingress.class: gce`、AWSで`ingress.class: alb`を利用する場合など、プロバイダーの必要に応じてロードバランサー/プロキシの動作に一致するように、`path`の定義を`/*`で終了させる必要があるユーザー向けです。

この設定により、このチャート全体としてIngressリソースのすべての`path`エントリのレンダリングでこれが使用されるようになります。唯一の例外として、[`gitlab/webservice`デプロイの設定](gitlab/webservice/_index.md#deployments-settings)にデータを入力する場合には`path`を指定する必要があります。

### クラウドプロバイダーのロードバランサー {#cloud-provider-loadbalancers}

さまざまなクラウドプロバイダーのロードバランサーの実装は、このチャートの一部としてデプロイされるIngressリソースとNGINXコントローラーの設定に影響を与えます。次の表に例を示します。

| プロバイダー | レイヤー | サンプルスニペット |
|:---------|------:|:----------------|
| AWS      |     4 | [`aws/elb-layer4-loadbalancer`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/elb-layer4-loadbalancer.yaml) |
| AWS      |     7 | [`aws/elb-layer7-loadbalancer`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/elb-layer7-loadbalancer.yaml) |
| AWS      |     7 | [`aws/alb-full`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/alb-full.yaml) |

### `global.ingress.configureCertmanager` {#globalingressconfigurecertmanager}

Ingressオブジェクトの[cert-manager](https://cert-manager.io/docs/installation/helm/)の自動設定を制御するグローバル設定。`true`の場合は、`certmanager-issuer.email`が設定されている必要があります。

`false`の場合、かつ`global.ingress.tls.secretName`が未設定で、`global.ingress.tls.enabled`がtrueまたは未設定の場合は、自己署名証明書の自動生成がアクティブになり、すべてのIngressオブジェクトに対して**ワイルドカード**証明書が作成されます。

外部`cert-manager`を使用する場合は、以下を指定する必要があります。

- `gitlab.webservice.ingress.tls.secretName`
- `registry.ingress.tls.secretName`
- `global.ingress.annotations`

### `global.ingress.useNewIngressForCerts` {#globalingressusenewingressforcerts}

`cert-manager`の動作を変更して、毎回動的に作成される新しいIngressを使用してACMEチャレンジ検証を実行するようにするためのグローバル設定。

デフォルトのロジック（`global.ingress.useNewIngressForCerts`が`false`の場合）は、検証のために既存のIngressを再利用します。このデフォルトは、状況によっては適切ではありません。フラグを`true`に設定すると、検証のたびに新しいIngressオブジェクトが作成されます。

GKE Ingressコントローラーで使用する場合、`global.ingress.useNewIngressForCerts`を`true`に設定することはできません。

## ゲートウェイAPI {#gateway-api}

Gateway APIおよびバンドルされたEnvoy Gatewayに関連するすべての設定については、[Gateway API](../advanced/gateway-api/_index.md)を参照してください。

## GitLabバージョン {#gitlab-version}

> [!note]
> この値は開発目的のみ、またはGitLabサポートからの明示的な要求があった場合にのみ使用してください。本番環境の設定ファイルでは、この値を使用しないでください。代わりに、[Helmを使用したデプロイ](../installation/deployment.md#deploy-using-helm)の説明に従ってバージョンを設定してください。

チャートのデフォルトイメージタグで使用されているGitLabのバージョンは、`global.gitlabVersion`キーを使用して変更できます。

```shell
--set global.gitlabVersion=11.0.1
```

これは、`webservice`、`sidekiq`、および`migration`のチャートで使用されるデフォルトのイメージタグに影響します。`gitaly`、`gitlab-shell`、および`gitlab-runner`のイメージタグは、個別に更新して、GitLabバージョンと互換性のあるバージョンにする必要があります。

## すべてのイメージタグにサフィックスを追加する {#adding-suffix-to-all-image-tags}

Helmチャートで使用されるすべてのイメージの名前にサフィックスを追加する場合は、`global.image.tagSuffix`キーを使用することができます。このユースケースの例としては、GitLabからFIPS準拠のコンテナイメージを使用する場合があり、それらはすべてイメージタグに拡張子`-fips`を付けて構成されます。

```shell
--set global.image.tagSuffix="-fips"
```

## すべてのコンテナのカスタムタイムゾーン {#custom-time-zone-for-all-containers}

すべてのGitLabコンテナに対してカスタムタイムゾーンを設定する場合は、`global.time_zone`キーを使用することができます。使用可能な値については、[tzデータベースのタイムゾーンのリスト](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)の`TZ identifier`を参照してください。デフォルトは`UTC`です。

```shell
--set global.time_zone="America/Chicago"
```

## PostgreSQLを設定する {#configure-postgresql-settings}

GitLabのグローバルPostgreSQLの設定は、`global.psql`キーの下にあります。

```yaml
global:
  psql:
    host: psql.example.com
    port: 5432
    database: gitlabhq_production
    username: gitlab
    applicationName:
    preparedStatements: false
    databaseTasks: true
    connectTimeout:
    keepalives:
    keepalivesIdle:
    keepalivesInterval:
    keepalivesCount:
    tcpUserTimeout:
    password:
      useSecret: true
      secret: gitlab-postgres
      key: psql-password
      file:
```

| 名前                 |  型   | デフォルト               | 説明 |
|:---------------------|:-------:|:----------------------|:------------|
| `host`               | 文字列  |                       | 外部PostgreSQLサーバーのホスト名です。必須。 |
| `database`           | 文字列  | `gitlabhq_production` | PostgreSQLサーバーで使用するデータベースの名前。 |
| `password.useSecret` | ブール値 | `true`                | PostgreSQLのパスワードをシークレットまたはファイルから読み取るかどうかを制御します。 |
| `password.file`      | 文字列  |                       | PostgreSQLのパスワードを含むファイルへのパスを定義します。`password.useSecret`がtrueの場合、無視されます。 |
| `password.key`       | 文字列  |                       | PostgreSQLの`password.key`属性は、パスワードを含むシークレット（下記）内のキーの名前を定義します。`password.useSecret`がfalseの場合、無視されます。 |
| `password.secret`    | 文字列  |                       | PostgreSQLの`password.secret`属性は、プル元のKubernetes `Secret`の名前を定義します。`password.useSecret`がfalseの場合、無視されます。 |
| `port`               | 整数 | `5432`                | PostgreSQLサーバーへの接続に使用するポート。 |
| `username`           | 文字列  | `gitlab`              | データベースへの認証に使用するユーザー名。 |
| `preparedStatements` | ブール値 | `false`               | PostgreSQLサーバーとの通信時にプリペアドステートメントを使用するかどうか。 |
| `databaseTasks`      | ブール値 | `true`                | GitLabが特定のデータベースに対してデータベースタスクを実行するかどうか。共有ホスト/ポート/データベースが`main`と一致する場合、自動的に無効になります。 |
| `connectTimeout`     | 整数 |                       | データベース接続を待機する秒数。 |
| `keepalives`         | 整数 |                       | クライアント側のTCP `keepalives`を使用するかどうかを制御します（`1`はオン、`0`はオフを意味します）。 |
| `keepalivesIdle`     | 整数 |                       | TCPがキープアライブメッセージをサーバーに送信するまでの非アクティブ状態の秒数。値がゼロの場合は、システムのデフォルトを使用します。 |
| `keepalivesInterval` | 整数 |                       | サーバーによって確認応答されないTCPキープアライブメッセージを再送信するまでの秒数。値がゼロの場合は、システムのデフォルトを使用します。 |
| `keepalivesCount`    | 整数 |                       | サーバーへのクライアント接続が切断されたと見なされるまでに失われる可能性のあるTCP `keepalives`の数。値がゼロの場合は、システムのデフォルトを使用します。 |
| `tcpUserTimeout`     | 整数 |                       | 送信されたデータが確認応答されない場合に接続が強制的に閉じられるまでのミリ秒数。値がゼロの場合は、システムのデフォルトを使用します。 |
| `applicationName`    | 文字列  |                       | データベースに接続しているアプリケーションの名前。無効にするには、空白文字列（`""`）に設定します。デフォルトでは、これは実行中のプロセスの名前（`sidekiq`、`puma`など）に設定されます。 |

### チャートごとのPostgreSQL {#postgresql-per-chart}

一部の複雑なデプロイでは、このチャートの異なる部分をPostgreSQLの異なる設定で構成することが要件となる場合があります。`v4.2.0`時点では、`global.psql`内で使用可能なすべての属性は、`gitlab.sidekiq.psql`などのチャート単位で設定できます。ローカル設定は、`global.psql`に存在しないものを継承して提供されると、グローバル値をオーバーライドします。ただし、`psql.load_balancing`は例外です。

[PostgreSQLロードバランシング](#postgresql-load-balancing)は、設計上、グローバルから継承されることはありません。

### PostgreSQL SSL {#postgresql-ssl}

SSLサポートは相互TLSのみです。[イシュー#2034](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2034)と[イシュー#1817](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1817)を参照してください。

相互TLS経由でGitLabをPostgreSQLデータベースに接続する場合は、クライアントキー、クライアント証明書、およびサーバー認証局を異なるシークレットキーとして含むシークレットを作成します。次に、`global.psql.ssl`マッピングを使用してシークレットの構造を記述します。

```yaml
global:
  psql:
    ssl:
      secret: db-example-ssl-secrets # Name of the secret
      clientCertificate: cert.pem    # Secret key storing the certificate
      clientKey: key.pem             # Secret key of the certificate's key
      serverCA: server-ca.pem        # Secret key containing the CA for the database server
```

| 名前                |  型  | デフォルト | 説明 |
|:--------------------|:------:|:--------|:------------|
| `secret`            | 文字列 |         | 次のキーを含むKubernetes `Secret`の名前。 |
| `clientCertificate` | 文字列 |         | `Secret`内で、クライアント証明書を含むキーの名前。 |
| `clientKey`         | 文字列 |         | `Secret`内で、クライアント証明書のキーファイルを含むキーの名前。 |
| `serverCA`          | 文字列 |         | `Secret`内で、サーバーの認証局を含むキーの名前。 |

正しいキーを指すように環境変数をエクスポートするために、`extraEnv`値を設定する必要がある場合もあります。

```yaml
global:
  extraEnv:
      PGSSLCERT: '/etc/gitlab/postgres/ssl/client-certificate.pem'
      PGSSLKEY: '/etc/gitlab/postgres/ssl/client-key.pem'
      PGSSLROOTCERT: '/etc/gitlab/postgres/ssl/server-ca.pem'
```

### PostgreSQLのロードバランシング {#postgresql-load-balancing}

この機能を使用するには、[外部PostgreSQL](../advanced/external-db/_index.md)を使用する必要があります。このチャートはHA方式でPostgreSQLをデプロイしないためです。

GitLabのRailsコンポーネントには、[PostgreSQLクラスターを利用して読み取り専用クエリの負荷分散を行う](https://docs.gitlab.com/administration/postgresql/database_load_balancing/)機能があります。

この機能は、次の2つの方法で設定できます。

- セカンダリのホスト名の静的リストを使用します。
- DNSベースのサービスディスカバリメカニズムを使用する。

分かりやすいのは静的リストによる設定です。

```yaml
global:
  psql:
    host: primary.database
    load_balancing:
       hosts:
       - secondary-1.database
       - secondary-2.database
```

サービスディスカバリの設定はもっと複雑になることがあります。この設定、パラメータ、およびそれらに関連する動作の詳細については、[GitLab管理ドキュメント](https://docs.gitlab.com/administration/)の[サービスディスカバリ](https://docs.gitlab.com/administration/postgresql/database_load_balancing/#service-discovery)を参照してください。

```yaml
global:
  psql:
    host: primary.database
    load_balancing:
      discover:
        record:  secondary.postgresql.service.consul
        # record_type: A
        # nameserver: localhost
        # port: 8600
        # interval: 60
        # disconnect_timeout: 120
        # use_tcp: false
        # max_replica_pools: 30
```

さらに、[ステイル読み取りの処理](https://docs.gitlab.com/administration/postgresql/database_load_balancing/#handling-stale-reads)に関しても、追加の調整が可能です。これらの項目についてはGitLab管理ドキュメントで詳しく説明されており、これらの属性は`load_balancing`の下に直接追加できます。

```yaml
global:
  psql:
    load_balancing:
      max_replication_difference: # See documentation
      max_replication_lag_time:   # See documentation
      replica_check_interval:     # See documentation
```

## Redisを設定する {#configure-redis-settings}

GitLabグローバルRedisの設定は、`global.redis`キーの下にあります。

外部Redisインスタンスが必要です。設定するには、[高度なドキュメント](../advanced/external-redis/_index.md)を参照してください。

```yaml
global:
  redis:
    host: redis.example.com
    database: 7
    port: 6379
    auth:
      enabled: true
      secret: gitlab-redis
      key: redis-password
    scheme:
```

| 名前             |  型   | デフォルト | 説明 |
|:-----------------|:-------:|:--------|:------------|
| `connectTimeout` | 整数 |         | Redis接続を待機する秒数。値を指定しない場合、クライアントのデフォルトは1秒です。 |
| `readTimeout`    | 整数 |         | Redisの読み取りを待機する秒数。値を指定しない場合、クライアントのデフォルトは1秒です。 |
| `writeTimeout`   | 整数 |         | Redisの書き込みを待機する秒数。値を指定しない場合、クライアントのデフォルトは1秒です。 |
| `host`           | 文字列  |         | Redisサーバーのホスト名です。`redisYmlOverride`を使用しない場合は必須です。 |
| `port`           | 整数 | `6379`  | Redisサーバーへの接続に使用するポート。 |
| `database`       | 整数 | `0`     | Redisサーバー上の接続先データベース。 |
| `user`           | 文字列  |         | Redisに認証するために使用するユーザー名（Redis 6.0以降）。 |
| `auth.enabled`   | ブール値 | `true`  | `auth.enabled`は、Redisインスタンスでパスワードを使用するかどうかの切替機能を提供します。 |
| `auth.key`       | 文字列  |         | Redisの`auth.key`属性は、パスワードを含むシークレット（下記）内のキーの名前を定義します。 |
| `auth.secret`    | 文字列  |         | Redisの`auth.secret`属性は、プル元のKubernetes `Secret`の名前を定義します。 |
| `scheme`         | 文字列  | `redis` | Redis URLを生成するために使用するURIスキーム。有効な値は、`redis`、`rediss`、および`tcp`です。`rediss`（SSL暗号化された接続）スキームを使用する場合、サーバーで使用される証明書は、システムで信頼するチェーンの一部である必要があります。これを実現するには、[カスタム認証局](#custom-certificate-authorities)のリストに追加してください。 |
| `redisTLS`       | オブジェクト  |         | Redis接続用のTLS設定。以下の[Redis TLS設定](#redis-tls-configuration)を参照してください。 |

### Redis Sentinelのサポート {#redis-sentinel-support}

GitLabチャートは、[Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/)クラスターへの接続をサポートしています。`sentinel.conf`で指定されているSentinelマスター名に`global.redis.host`を設定し、`global.redis.sentinels`の下にSentinelノードをリストします。

```yaml
global:
  redis:
    host: redis.example.com
    port: 6379
    sentinels:
      - host: sentinel1.example.com
        port: 26379
      - host: sentinel2.example.com
        port: 26379
    auth:
      enabled: true
      secret: gitlab-redis
      key: redis-password
```

| 名前                |  型   | デフォルト | 説明 |
|:--------------------|:-------:|:--------|:------------|
| `host`              | 文字列  |         | `host`属性には、`sentinel.conf`で指定されているクラスター名を設定する必要があります。 |
| `sentinels.[].host` | 文字列  |         | Redis HA設定用のRedis Sentinelサーバーのホスト名。 |
| `sentinels.[].port` | 整数 | `26379` | Redis Sentinelサーバーへの接続に使用するポート。 |

一般的な[Redis設定](#configure-redis-settings)にある先行するすべてのRedis属性は、上記の表で再指定されていない限り、Sentinelサポートでも引き続き適用されます。

#### Redis Sentinelのパスワードサポート {#redis-sentinel-password-support}

{{< history >}}

- GitLab 17.1で[導入](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3792)されました。

{{< /history >}}

```yaml
global:
  redis:
    host: redis.example.com
    port: 6379
    sentinels:
      - host: sentinel1.example.com
        port: 26379
      - host: sentinel2.example.com
        port: 26379
    auth:
      enabled: true
      secret: gitlab-redis
      key: redis-password
    sentinelAuth:
      enabled: false
      secret: gitlab-redis-sentinel
      key: sentinel-password
```

| 名前                   |  型   | デフォルト | 説明 |
|:-----------------------|:-------:|:--------|:------------|
| `sentinelAuth.enabled` | ブール値 | `false` | `sentinelAuth.enabled`は、Redis Sentinelインスタンスでパスワードを使用するかどうかの切替機能を提供します。 |
| `sentinelAuth.key`     | 文字列  |         | Redisの`sentinelAuth.key`属性は、パスワードを含むシークレット（下記）内のキーの名前を定義します。 |
| `sentinelAuth.secret`  | 文字列  |         | Redisの`sentinelAuth.secret`属性は、プル元のKubernetes `Secret`の名前を定義します。 |

`global.redis.sentinelAuth`を使用して、すべてのSentinelインスタンスのSentinelパスワードを設定できます。

`sentinelAuth`は、[Redisインスタンス固有の設定](#multiple-redis-support)、または[`global.redis.redisYmlOverride`](../advanced/external-redis/_index.md#redisyml-override)でオーバーライドできないことに注意してください。

### 複数のRedisのサポート {#multiple-redis-support}

GitLabチャートには、さまざまな永続クラス用に別個のRedisインスタンスで実行するためのサポートが含まれています。現在のところ、次のとおりです。

| インスタンス          | 目的 |
|:------------------|:--------|
| `actioncable`     | ActionCableのPub/Subキューバックエンド |
| `cache`           | キャッシュされたデータを保存する |
| `kas`             | KAS固有のデータを保存する |
| `queues`          | Sidekiqバックグラウンドジョブを保存する |
| `rateLimiting`    | RackAttackとアプリケーション制限のためのレート制限の利用状況を保存する |
| `repositoryCache` | リポジトリ関連データを保存する |
| `sessions`        | ユーザーセッションデータを保存する |
| `sharedState`     | 分散ロックなど、さまざまな永続データを保存する |
| `traceChunks`     | ジョブトレースを一時的に保存する |
| `workhorse`       | WorkhorseのPub/subキューバックエンド |

インスタンスの数に制限はありません。指定されていないインスタンスは、`global.redis.host`で指定されたプライマリRedisインスタンスによって処理されます。唯一の例外は、[GitLabエージェントサーバー（KAS）](gitlab/kas/_index.md)であり、Redis設定を次の順序で検索します。

1. `global.redis.kas`
1. `global.redis.sharedState`
1. `global.redis.host`

例: 

```yaml
global:
  redis:
    host: redis.example
    port: 6379
    auth:
      enabled: true
      secret: redis-secret
      key: redis-password
    actioncable:
      host: cable.redis.example
      port: 6379
      auth:
        enabled: true
        secret: cable-secret
        key: cable-password
    cache:
      host: cache.redis.example
      port: 6379
      auth:
        enabled: true
        secret: cache-secret
        key: cache-password
    kas:
      host: kas.redis.example
      port: 6379
      auth:
        enabled: true
        secret: kas-secret
        key: kas-password
    queues:
      host: queues.redis.example
      port: 6379
      auth:
        enabled: true
        secret: queues-secret
        key: queues-password
    rateLimiting:
      host: rateLimiting.redis.example
      port: 6379
      auth:
        enabled: true
        secret: rateLimiting-secret
        key: rateLimiting-password
    repositoryCache:
      host: repositoryCache.redis.example
      port: 6379
      auth:
        enabled: true
        secret: repositoryCache-secret
        key: repositoryCache-password
    sessions:
      host: sessions.redis.example
      port: 6379
      auth:
        enabled: true
        secret: sessions-secret
        key: sessions-password
    sharedState:
      host: shared.redis.example
      port: 6379
      auth:
        enabled: true
        secret: shared-secret
        key: shared-password
    traceChunks:
      host: traceChunks.redis.example
      port: 6379
      auth:
        enabled: true
        secret: traceChunks-secret
        key: traceChunks-password
    workhorse:
      host: workhorse.redis.example
      port: 6379
      auth:
        enabled: true
        secret: workhorse-secret
        key: workhorse-password
```

次の表に、Redisインスタンスの各ディクショナリの属性を示します。

| 名前                |  型   | デフォルト | 説明 |
|:--------------------|:-------:|:--------|:------------|
| `.host`             | 文字列  |         | 使用するデータベースが格納されているRedisサーバーのホスト名。 |
| `.port`             | 整数 | `6379`  | Redisサーバーへの接続に使用するポート。 |
| `.auth.enabled` | ブール値 | `true`  | `auth.enabled`は、Redisインスタンスでパスワードを使用するかどうかの切替機能を提供します。 |
| `.auth.key`     | 文字列  |         | Redisの`auth.key`属性は、パスワードを含むシークレット（下記）内のキーの名前を定義します。 |
| `.auth.secret`  | 文字列  |         | Redisの`auth.secret`属性は、プル元のKubernetes `Secret`の名前を定義します。 |

分離されていない追加の永続クラスがあるため、プライマリRedisの定義が必要です。

インスタンス定義ごとに、Redis Sentinelのサポートも使用できます。Sentinelの設定は**共有されません**。Sentinelを使用するインスタンスごとに指定する必要があります。Sentinelサーバーの設定に使用する属性については、[Sentinelの設定](#redis-sentinel-support)を参照してください。

例えば、`cache`インスタンスを個別に定義する場合、`sentinels`リストはそのインスタンスの下に繰り返して記述する必要があります。これは`global.redis.sentinels`から**継承**されません。これを省略すると、インスタンスはSentinel経由ではなく直接接続します:

```yaml
global:
  redis:
    host: mymaster
    sentinels:
      - host: sentinel1.example.com
        port: 26379
      - host: sentinel2.example.com
        port: 26379
    cache:
      host: mymaster
      sentinels:
        - host: sentinel1.example.com
          port: 26379
        - host: sentinel2.example.com
          port: 26379
      auth:
        enabled: true
        secret: cache-secret
        key: cache-password
```

### セキュアなRedisスキーム（SSL）を指定する {#specify-secure-redis-scheme-ssl}

SSLでRedisに接続するには、次のようにします。

1. `rediss`（`s`は2個）スキームパラメータを使用するように設定を更新します。
1. 設定で、`authClients`を`false`に設定します。

   ```yaml
   global:
     redis:
       scheme: rediss
   redis:
     tls:
       enabled: true
       authClients: false
   ```

   [Redisのデフォルトは相互TLS](https://redis.io/docs/latest/operate/oss_and_stack/management/security/encryption/)であり、それはすべてのチャートコンポーネントでサポートしているわけではないため、この設定は必須です。

1. 外部RedisサーバーでTLSを設定し、チャートコンポーネントがRedis証明書の作成に使用された認証局を信頼していることを確認してください。
1. 任意。カスタム公開認証局を使用する場合については、[カスタム認証局](#custom-certificate-authorities)のグローバル設定を参照してください。

### Redis TLS設定 {#redis-tls-configuration}

`rediss`スキームを使用する場合、`redisTLS`設定を使用して、Redis接続用のクライアント証明書とCA証明書をオプションで設定できます:

```yaml
global:
  redis:
    scheme: rediss
    redisTLS:
      cert:
        secret: redis-client-cert
        key: cert
      key:
        secret: redis-client-key
        key: key
      caFile:
        secret: redis-ca
        key: ca.crt
```

`redisTLS`設定は以下をサポートします:

| 名前                |  型  | デフォルト | 説明 |
|:--------------------|:------:|:--------|:------------|
| `cert.secret`       | 文字列 |         | クライアント証明書を含むKubernetesシークレット名 |
| `cert.key`          | 文字列 |         | クライアント証明書を含むシークレット内のキー。 |
| `key.secret`        | 文字列 |         | クライアント秘密キーを含むKubernetesシークレット名 |
| `key.key`           | 文字列 |         | クライアント秘密キーを含むシークレット内のキー。 |
| `caFile.secret`     | 文字列 |         | CA証明書を含むKubernetesシークレット名 |
| `caFile.key`        | 文字列 |         | CA証明書を含むシークレット内のキー。 |

これら3つ（`cert`、`key`、および`caFile`）はすべてオプションです。指定しない場合、システムはデフォルトのCA証明書を使用します。

#### Sentinel TLS設定 {#sentinel-tls-configuration}

TLSでRedis Sentinelを使用する場合、`sentinelTLS`設定を使用して、Sentinel接続用のクライアント証明書とCA証明書を設定できます:

```yaml
global:
  redis:
    sentinels:
      - host: sentinel1.example.com
        port: 26379
      - host: sentinel2.example.com
        port: 26379
    sentinelTLS:
      enabled: true
      cert:
        secret: sentinel-client-cert
        key: cert
      key:
        secret: sentinel-client-key
        key: key
      caFile:
        secret: sentinel-ca
        key: ca.crt
```

`sentinelTLS`設定は以下をサポートします:

| 名前                |  型   | デフォルト | 説明 |
|:--------------------|:-------:|:--------|:------------|
| `enabled`           | ブール値 | `false` | Sentinel接続でTLSを有効にするには`true`に設定します。 |
| `cert.secret`       | 文字列  |         | クライアント証明書を含むKubernetesシークレット名 |
| `cert.key`          | 文字列  |         | クライアント証明書を含むシークレット内のキー。 |
| `key.secret`        | 文字列  |         | クライアント秘密キーを含むKubernetesシークレット名 |
| `key.key`           | 文字列  |         | クライアント秘密キーを含むシークレット内のキー。 |
| `caFile.secret`     | 文字列  |         | CA証明書を含むKubernetesシークレット名 |
| `caFile.key`        | 文字列  |         | CA証明書を含むシークレット内のキー。 |

すべての証明書オプションはオプションです。指定しない場合、システムはデフォルトのCA証明書を使用します。

### パスワードレスRedisサーバー {#password-less-redis-servers}

Google Cloud Memorystoreなどの一部のRedisサービスでは、パスワードとそれに関連する`AUTH`コマンドを使用しません。パスワードの使用と要件は、次の設定により無効にできます。

```yaml
global:
  redis:
    auth:
      enabled: false
    host: ${REDIS_PRIVATE_IP}
```

## レジストリを設定する {#configure-registry-settings}

レジストリのグローバル設定は、`global.registry`キーの下にあります。

```yaml
global:
  registry:
    bucket: registry
    certificate:
    httpSecret:
    notificationSecret:
    notifications: {}
    ## Settings used by other services, referencing registry:
    enabled: true
    host:
    api:
      protocol: http
      serviceName: registry
      port: 5000
    tokenIssuer: gitlab-issuer
```

`bucket`、`certificate`、`httpSecret`、`notificationSecret`の設定の詳細については、[レジストリチャート](registry/_index.md)内のドキュメントを参照してください。

`enabled`、`host`、`api`、`tokenIssuer`の詳細については、[コマンドラインオプション](../installation/command-line-options.md)および[Webservice](gitlab/webservice/_index.md)のドキュメントを参照してください。

`host`は、自動生成された外部レジストリホスト名参照をオーバーライドするために使用されます。

### コンテナレジストリの無効化 {#disabling-the-container-registry}

独立した2つの設定があります:

- `global.registry.enabled`はコンテナレジストリのインテグレーションを制御します。つまり、GitLabアプリケーションがレジストリと通信するかどうかです。これは、例えばプロジェクトの削除や転送の際にアプリケーションが使用する設定です。
- `registry.enabled`は、**バンドルされたRegistryデプロイ**が作成されるかどうかを制御します。

コンテナレジストリ機能を完全に無効にするには、`global.registry.enabled: false`を設定します。到達可能なレジストリがない状態でインテグレーションを有効にしておくと、プロジェクトの削除や転送などの操作が`Failed to open TCP connection to gitlab-registry:5000`のようなエラーで失敗します（[イシュー24110](https://gitlab.com/gitlab-org/gitlab/-/issues/24110)を参照）。バンドルされたレジストリのデプロイも停止するには、さらに`registry.enabled: false`を設定します:

```yaml
# Fully disable the Container Registry integration and stop deploying the bundled registry:
global:
  registry:
    enabled: false
registry:
  enabled: false
```

バンドルされたレジストリの代わりに外部レジストリを使用するには、`registry.enabled: false` （バンドルされたデプロイなし）を設定し、`global.registry.enabled: true`を維持したまま、`global.registry.host`と`global.registry.api`を外部レジストリに向けます:

```yaml
# Use an external registry (no bundled deployment, integration stays on):
global:
  registry:
    enabled: true
    host: registry.example.com
    api:
      protocol: https
      port: 5000
registry:
  enabled: false
```

### `notifications` {#notifications}

この設定は、[レジストリの通知](https://distribution.github.io/distribution/about/notifications/)を設定するために使用されます。これは、（アップストリームの仕様に従って）マップを取り込みますが、Kubernetes Secretとして機密ヘッダーを提供するという機能が追加されています。たとえば、認証ヘッダーには機密データが含まれ、他のヘッダーには標準のデータが含まれている次のスニペットについて考えてみましょう。

```yaml
global:
  registry:
    notifications:
      events:
        includereferences: true
      endpoints:
        - name: CustomListener
          url: https://mycustomlistener.com
          timeout: 500mx
          # DEPRECATED: use `maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243.
          # When using `maxretries`, `threshold` is ignored: https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#endpoints
          threshold: 5
          maxretries: 5
          backoff: 1s
          headers:
            X-Random-Config: [plain direct]
            Authorization:
              secret: registry-authorization-header
              key: password
```

この例の場合、ヘッダー`X-Random-Config`は標準のヘッダーであり、その値は`values.yaml`ファイル内に、または`--set`フラグを介してプレーンテキストで指定できます。ただし、ヘッダー`Authorization`は機密ヘッダーであるため、Kubernetes Secretからマウントすることをおすすめします。シークレットの構造の詳細については、[シークレットに関するドキュメント](../installation/secrets.md#registry-sensitive-notification-headers)を参照してください。

## Gitalyを設定する {#configure-gitaly-settings}

Gitalyのグローバル設定は、`global.gitaly`キーの下にあります。

```yaml
global:
  gitaly:
    internal:
      names:
        - default
        - default2
    external:
      - name: node1
        hostname: node1.example.com
        port: 8075
    authToken:
      secret: gitaly-secret
      key: token
    tls:
      enabled: true
      secretName: gitlab-gitaly-tls
```

### Gitalyホスト {#gitaly-hosts}

[Gitaly](https://gitlab.com/gitlab-org/gitaly)は、Gitリポジトリへの高レベルRPCアクセスを提供するサービスであり、GitLabによってなされるすべてのGit呼び出しを処理します。

管理者は、次の方法でGitalyノードを使用することを選択できます:

- [チャート内部](#internal)（[Gitalyチャート](gitlab/gitaly/_index.md)を介して`StatefulSet`の一部として）。
- [チャートの外部](#external)（外部ペットとして）。
- 内部ノードと外部ノードの両方を使用する[混合環境](#mixed)。

新規プロジェクト用に使用されるノードの管理の詳細については、[リポジトリストレージパス](https://docs.gitlab.com/administration/repository_storage_paths/)のドキュメントを参照してください。

`gitaly.host`が指定されている場合、`gitaly.internal`プロパティと`gitaly.external`プロパティは*無視されます*。[非推奨のGitaly設定](#deprecated-gitaly-settings)を参照してください。

現時点で、Gitaly認証トークンは、内部または外部のすべてのGitalyサービスで同一であることが期待されています。これらが揃っていることを確認してください。詳細については、[イシュー#1992](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1992)を参照してください。

#### `internal` {#internal}

現在のところ、`internal`キーは1つのキー`names`だけで構成されており、これはチャートによって管理される[ストレージ名](https://docs.gitlab.com/administration/repository_storage_paths/)のリストです。リスト内の名前ごとに（*論理的な順序*で）、1つのポッドが起動します。その名前は`${releaseName}-gitaly-${ordinal}`です（`ordinal`は`names`リスト内のインデックス）。動的なプロビジョニングが有効になっている場合、`PersistentVolumeClaim`は一致します。

このリストのデフォルトは`['default']`であり、1つの[ストレージパス](https://docs.gitlab.com/administration/repository_storage_paths/)に対して関連する1つのポッドを提供します。

このアイテムは手動スケーリングが必要です。そのためには、`gitaly.internal.names`の中のエントリを追加または削除します。スケールダウンすると、別のノードに移動されていないリポジトリは使用できなくなります。Gitalyチャートは`StatefulSet`であるため、動的にプロビジョニングされたディスクは*再利用されません*。つまり、データディスクは存続しており、`names`リストにノードを再度追加してセットを再びスケールアップすると、データディスク上のデータにアクセスできます。

[複数の内部ノードの設定](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-internal.yaml)のサンプルがexamplesフォルダーにあります。

#### `external` {#external}

`external`キーは、クラスターの外部にあるGitalyノードの設定を提供します。このリストの各項目には、以下のキーがあります:

- `name`: [ストレージ](https://docs.gitlab.com/administration/repository_storage_paths/)の名前。[`name: default`のエントリが必要です](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#gitlab-requires-a-default-repository-storage)。
- `address`: （オプション）Gitalyサービスの完全なURI (例: TLSの場合は`dns://8.8.8.8:53/gitaly.example.com`または`dns+tls://8.8.8.8:53/gitaly.example.com`)。これを指定した場合、`hostname`および`port`よりも優先されます。詳細については、[高度な設定ガイド](../advanced/external-gitaly/_index.md#dns-address-format)を参照してください。
- `hostname`: Gitalyサービスのホスト。`address`が指定されていない場合は必須です。
- `port`: （オプション）ホストに到達するためのポート番号。デフォルトは`8075`です。`address`が指定されている場合は無視されます。
- `tlsEnabled`: （オプション）この特定のエントリの`global.gitaly.tls.enabled`をオーバーライドします。`address`が指定されている場合は無視されます。

GitLabでは、[外部Gitalyサービスの使用](../advanced/external-gitaly/_index.md)に関する[高度な設定](../advanced/_index.md)ガイドを提供しています。examplesフォルダーには、[複数の外部サービスの設定](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-external.yaml)の例もあります。

可用性の高いGitalyサービスを提供するために、外部[Praefect](https://docs.gitlab.com/administration/gitaly/praefect/)を使用することもできます。クライアントにとっては違いがないため、2つの設定は交換可能です。

#### 混合 {#mixed}

内部Gitalyノードと外部Gitalyノードの両方を使用することは可能ですが、次の点に注意してください。

- [`default`というノードが常に存在する必要があります](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#gitlab-requires-a-default-repository-storage)。内部ではこれがデフォルトで提供されます。
- 外部ノードが最初に入力され、次に内部が入力されます。

[examples](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-mixed.yaml)フォルダーに、内部ノードと外部ノードの混合設定の例があります。

### `authToken` {#authtoken}

Gitalyの`authToken`属性には、次の2つのサブキーがあります。

- `secret`は、プル元のKubernetes `Secret`の名前を定義します。
- `key`は、上記のシークレットのうち`authToken`を含むキーの名前を定義します。

すべてのGitalyノードは、同じ認証トークンを**共有する必要があります**。

### 非推奨のGitaly設定 {#deprecated-gitaly-settings}

| 名前                         |  型   | デフォルト | 説明 |
|:-----------------------------|:-------:|:--------|:------------|
| `host` *（非推奨）*        | 文字列  |         | 使用するGitalyサーバーのホスト名。`serviceName`の代わりとして省略できます。この設定を使用すると、`internal`または`external`の値がオーバーライドされます。 |
| `port` *（非推奨）*        | 整数 | `8075`  | Gitalyサーバーへの接続に使用するポート。 |
| `serviceName` *（非推奨）* | 文字列  |         | Gitalyサーバーを操作している`service`の名前。これが存在し、`host`が存在しない場合、チャートは`host`値の代わりにサービスのホスト名（および現在の`.Release.Name`）をテンプレート処理します。これは、GitalyをGitLabチャート全体の一部として使用する場合に便利です。 |

### TLSの設定 {#tls-settings}

TLS経由で動作するようにGitalyを設定する方法について詳しくは、[Gitalyチャートのドキュメント](gitlab/gitaly/_index.md#running-gitaly-over-tls)をご覧ください。

## Praefectを設定する {#configure-praefect-settings}

Praefectのグローバル設定は、`global.praefect`キーの下にあります。

Praefectはデフォルトで無効になっています。追加の設定なしで有効にした場合、Gitalyレプリカが3つ作成され、デフォルトのPostgreSQLインスタンス上にPraefectデータベースを手動で作成する必要があります。

### Praefectを有効にする {#enable-praefect}

デフォルト設定でPraefectを有効にするには、`global.praefect.enabled=true`を設定します。

詳細については、[Gitaly Cluster (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/)を参照してください。

### Praefectのグローバル設定 {#global-settings-for-praefect}

```yaml
global:
  praefect:
    enabled: false
    virtualStorages:
    - name: default
      gitalyReplicas: 3
      maxUnavailable: 1
    dbSecret: {}
    psql: {}
```

| 名前              | 型    | デフォルト    | 説明 |
|-------------------|---------|------------|-------------|
| `enabled`         | ブール値 | `false`    | Praefectを有効にするかどうか。 |
| `virtualStorages` | リスト    |            | 必要な仮想ストレージのリスト（それぞれをGitaly `StatefulSet`で処理）デフォルトについては、[複数の仮想ストレージ](https://docs.gitlab.com/administration/gitaly/praefect/#multiple-virtual-storages)を参照してください。 |
| `dbSecret.secret` | 文字列  |            | データベースの認証に使用するシークレットの名前。 |
| `dbSecret.key`    | 文字列  |            | 使用する`dbSecret.secret`の中のキーの名前。 |
| `psql.host`       | 文字列  |            | 使用するデータベースサーバーのホスト名（外部データベースを使用する場合）。 |
| `psql.port`       | 文字列  |            | データベースサーバーのポート番号（外部データベースを使用する場合）。 |
| `psql.user`       | 文字列  | `praefect` | 使用するデータベースユーザー。 |
| `psql.dbName`     | 文字列  | `praefect` | 使用するデータベースの名前。 |

## `appConfig`を設定する {#configure-appconfig-settings}

[Webservice](gitlab/webservice/_index.md)、[Sidekiq](gitlab/sidekiq/_index.md)、および[Gitaly](gitlab/gitaly/_index.md)のチャートでは複数の設定が共有されており、それらは`global.appConfig`キーで設定されます。

```yaml
global:
  appConfig:
    # cdnHost:
    relativeUrlRoot: ""
    contentSecurityPolicy:
      enabled: false
      report_only: true
      # directives: {}
    enableUsagePing: true
    enableSeatLink: true
    enableImpersonation: true
    applicationSettingsCacheSeconds: 60
    usernameChangingEnabled: true
    issueClosingPattern:
    defaultTheme:
    defaultColorMode:
    defaultSyntaxHighlightingTheme:
    defaultProjectsFeatures:
      issues: true
      mergeRequests: true
      wiki: true
      snippets: true
      builds: true
      containerRegistry: true
    webhookTimeout:
    gravatar:
      plainUrl:
      sslUrl:
    extra:
      googleAnalyticsId:
      matomoUrl:
      matomoSiteId:
      matomoDisableCookies:
      oneTrustId:
      googleTagManagerNonceId:
      bizible:
    object_store:
      enabled: false
      proxy_download: true
      storage_options: {}
      connection: {}
    lfs:
      enabled: true
      proxy_download: true
      bucket: git-lfs
      connection: {}
    artifacts:
      enabled: true
      proxy_download: true
      bucket: gitlab-artifacts
      connection: {}
    uploads:
      enabled: true
      proxy_download: true
      bucket: gitlab-uploads
      connection: {}
    packages:
      enabled: true
      proxy_download: true
      bucket: gitlab-packages
      connection: {}
    externalDiffs:
      enabled:
      when:
      proxy_download: true
      bucket: gitlab-mr-diffs
      connection: {}
    terraformState:
      enabled: false
      bucket: gitlab-terraform-state
      connection: {}
    ciSecureFiles:
      enabled: false
      bucket: gitlab-ci-secure-files
      connection: {}
    agentPlanContent:
      enabled: false
      bucket: gitlab-agent-plan-content
      connection: {}
    dependencyProxy:
      enabled: false
      bucket: gitlab-dependency-proxy
      connection: {}
    backups:
      bucket: gitlab-backups
    microsoft_graph_mailer:
      enabled: false
      user_id: "YOUR-USER-ID"
      tenant: "YOUR-TENANT-ID"
      client_id: "YOUR-CLIENT-ID"
      client_secret:
        secret:
        key: secret
      azure_ad_endpoint: "https://login.microsoftonline.com"
      graph_endpoint: "https://graph.microsoft.com"
    incomingEmail:
      enabled: false
      address: ""
      host: "imap.gmail.com"
      port: 993
      ssl: true
      startTls: false
      user: ""
      password:
        secret:
        key: password
      mailbox: inbox
      idleTimeout: 60
      inboxMethod: "imap"
      clientSecret:
        key: secret
      pollInterval: 60
      deliveryMethod: webhook
      authToken: {}

    serviceDeskEmail:
      enabled: false
      address: ""
      host: "imap.gmail.com"
      port: 993
      ssl: true
      startTls: false
      user: ""
      password:
        secret:
        key: password
      mailbox: inbox
      idleTimeout: 60
      inboxMethod: "imap"
      clientSecret:
        key: secret
      pollInterval: 60
      deliveryMethod: webhook
      authToken: {}

    cron_jobs: {}
    sentry:
      enabled: false
      dsn:
      clientside_dsn:
      environment:
    gitlab_docs:
      enabled: false
      host: ""
    oidcProvider:
      openidIdTokenExpireInSeconds: 120
    smartcard:
      enabled: false
      CASecret:
      clientCertificateRequiredHost:
    sidekiq:
      routingRules: []
```

### 一般的なアプリケーション設定 {#general-application-settings}

{{< history >}}

- `relativeUrlRoot`設定はGitLab 18.4で[導入](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6121)されました。

{{< /history >}}

Railsアプリケーションの一般的なプロパティを微調整するために使用できる`appConfig`設定について、以下に説明します。

| 名前                                |  型   | デフォルト | 説明 |
|:------------------------------------|:-------:|:--------|:------------|
| `cdnHost`                           | 文字列  | （空） | 静的アセットを処理するための、CDNのベースURLを設定します（`https://mycdnsubdomain.fictional-cdn.com`など）。 |
| `relativeUrlRoot`                   | 文字列  | （空） | GitLabの[相対URLルート](#configure-a-relative-url-root)を設定します (例: `/gitlab`)。設定すると、GitLabはルートパスの代わりに、指定されたパスでアクセスできるようになります。 |
| `contentSecurityPolicy`             | 構造体  |         | [下記を参照](#content-security-policy)。 |
| `enableUsagePing`                   | ブール値 | `true`  | [pingの使用のサポート](https://docs.gitlab.com/administration/settings/usage_statistics/)を無効にするフラグ。 |
| `enableSeatLink`                    | ブール値 | `true`  | シートリンクサポートを無効にするためのフラグ。 |
| `enableImpersonation`               |         | `nil`   | [管理者によるユーザーの代理](https://docs.gitlab.com/api/rest/authentication/#disable-impersonation)を無効にするフラグ。 |
| `applicationSettingsCacheSeconds`   | 整数 | `60`    | [アプリケーション設定キャッシュ](https://docs.gitlab.com/administration/application_settings_cache/)を無効にする間隔の値（秒単位）。 |
| `usernameChangingEnabled`           | ブール値 | `true`  | ユーザーがユーザー名を変更できるかどうかを決定するフラグ。 |
| `issueClosingPattern`               | 文字列  | （空） | [イシューを自動的に完了するパターン](https://docs.gitlab.com/administration/issue_closing_pattern/)。 |
| `defaultTheme`                      | 整数 |         | [GitLabインスタンスのデフォルトテーマの数値ID](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/lib/gitlab/themes.rb#L17-27)。テーマのIDを示す数値を指定します。 |
| `defaultColorMode`                  | 整数 |         | [GitLabインスタンスのデフォルトのカラーモード](https://gitlab.com/gitlab-org/gitlab/-/blob/66788a1de8c3dd3c5566d0f30fe1c2a1bae64bf9/lib/gitlab/color_modes.rb#L17-19)。カラーモードのIDを示す数値を指定します。 |
| `defaultSyntaxHighlightingTheme`    | 整数 |         | [GitLabインスタンスのデフォルト構文ハイライトのテーマ](https://gitlab.com/gitlab-org/gitlab/-/blob/66788a1de8c3dd3c5566d0f30fe1c2a1bae64bf9/lib/gitlab/color_schemes.rb#L12-17)。構文ハイライトテーマのIDを示す数値を指定します。 |
| `defaultProjectsFeatures.*feature*` | ブール値 | `true`  | [下記を参照](#defaultprojectsfeatures)。 |
| `gitTimeout`                        | 整数 | `nil`   | GitLab Shellを介して実行されるGitインポート、フェッチ、およびクローン操作のタイムアウト（秒単位）。 |
| `webhookTimeout`                    | 整数 | （空） | [フックが失敗したと見なされる](https://docs.gitlab.com/user/project/integrations/webhooks/#auto-disabled-webhooks)までの待機時間（秒単位）。 |
| `graphQlTimeout`                    | 整数 | （空） | Railsが[GraphQLリクエストを完了](https://docs.gitlab.com/api/graphql/#limits)するまでの時間（秒単位）。 |

#### コンテンツセキュリティポリシー {#content-security-policy}

コンテンツセキュリティポリシー（CSP）を設定することは、JavaScriptクロスサイトスクリプティング（XSS）攻撃を阻止するのに役立ちます。設定の詳細については、GitLabドキュメントを参照してください。[コンテンツセキュリティポリシーのドキュメント](https://docs.gitlab.com/omnibus/settings/configuration/#set-a-content-security-policy)

CSPの安全なデフォルト値は、GitLabにより自動的に提供されます。

```yaml
global:
  appConfig:
    contentSecurityPolicy:
      enabled: true
      report_only: false
```

カスタムCSPを追加するには、次のようにします。

```yaml
global:
  appConfig:
    contentSecurityPolicy:
      enabled: true
      report_only: false
      directives:
        default_src: "'self'"
        script_src: "'self' 'unsafe-inline' 'unsafe-eval' https://www.recaptcha.net https://apis.google.com"
        frame_ancestors: "'self'"
        frame_src: "'self' https://www.recaptcha.net/ https://content.googleapis.com https://content-compute.googleapis.com https://content-cloudbilling.googleapis.com https://content-cloudresourcemanager.googleapis.com"
        img_src: "* data: blob:"
        style_src: "'self' 'unsafe-inline'"
```

CSPルールを不適切に設定すると、GitLabが正常に動作しなくなる可能性があります。ポリシーを実際にロールアウトしていく前に、`report_only`を`true`に変更して設定をテストするとよいかもしれません。

#### 相対URLルートを設定する {#configure-a-relative-url-root}

{{< details >}}

- ステータス: ベータ版

{{< /details >}}

> [!warning]
> GitLabの相対URLを設定すると、[Geo](https://gitlab.com/gitlab-org/gitlab/-/issues/456427)で既知のイシューがあり、[テストに制限](https://gitlab.com/gitlab-org/gitlab/-/issues/439943)があります。すでに相対URLを使用しており、サブドメインに移行する場合は、[移行ガイド](https://docs.gitlab.com/administration/operations/migrate_to_subdomain/)を参照してください。

GitLabは独自のドメインまたはサブドメインにインストールする必要がありますが、必要に応じて相対URLでインストールできます。例: `https://example.com/gitlab`。

すべてのWebサービスデプロイのIngressには、このプレフィックスが付加されます。

```yaml
global:
  appConfig:
    relativeUrlRoot: "/gitlab"
  hosts:
    domain: example.com
    gitlab:
      name: example.com
```

#### `defaultProjectsFeatures` {#defaultprojectsfeatures}

新規プロジェクト作成時に、対応する各機能をデフォルトで有効にするかどうかを決定するフラグ。どのフラグもデフォルトは`true`です。

```yaml
defaultProjectsFeatures:
  issues: true
  mergeRequests: true
  wiki: true
  snippets: true
  builds: true
  containerRegistry: true
```

### Gravatar/Libravatarの設定 {#gravatarlibravatar-settings}

デフォルトでは、チャートはgravatar.comで利用可能なGravatarアバターサービスと連携します。ただし、必要に応じてカスタムLibravatarサービスを使用することもできます。

| 名前                |  型  | デフォルト | 説明 |
|:--------------------|:------:|:--------|:------------|
| `gravatar.plainURL` | 文字列 | （空） | [LibravatarインスタンスのHTTP URL（gravatar.comの使用に代わるもの）](https://docs.gitlab.com/administration/libravatar/)。 |
| `gravatar.sslUrl`   | 文字列 | （空） | [LibravatarインスタンスのHTTPS URL（gravatar.comの使用に代わるもの）](https://docs.gitlab.com/administration/libravatar/)。 |

### GitLabインスタンスに対するAnalyticsサービスのフック {#hooking-analytics-services-to-the-gitlab-instance}

Google AnalyticsやMatomoなどのAnalyticsサービス設定は、`appConfig`の下の`extra`キーで定義されています。

| 名前                            |  型   | デフォルト | 説明 |
|:--------------------------------|:-------:|:--------|:------------|
| `extra.googleAnalyticsId`       | 文字列  | （空） | Google AnalyticsのトラッキングID。 |
| `extra.matomoSiteId`            | 文字列  | （空） | MatomoサイトID。 |
| `extra.matomoUrl`               | 文字列  | （空） | Matomo URL。 |
| `extra.matomoDisableCookies`    | ブール値 | （空） | Matomoクッキーを無効にする（Matomoスクリプトの`disableCookies`に対応）。 |
| `extra.oneTrustId`              | 文字列  | （空） | OneTrust ID。 |
| `extra.googleTagManagerNonceId` | 文字列  | （空） | GoogleタグマネージャーID。 |
| `extra.bizible`                 | ブール値 | `false` | Bizibleスクリプトを有効にする場合はtrueに設定。 |

### 統合されたオブジェクトストレージ {#consolidated-object-storage}

以下のセクションではオブジェクトストレージの個々の設定方法について説明していますが、これに加えて、これらの項目に共通の設定を使いやすくするため、統合されたオブジェクトストレージ設定を追加しました。`object_store`を活用すると、`connection`を一度だけ設定すれば、オブジェクトストレージでサポートされる機能のうち、個別に`connection`プロパティが設定されていないものすべてに対してその接続設定が使用されます。

```yaml
object_store:
  enabled: true
  proxy_download: true
  storage_options:
  connection:
    secret:
    key:
```

| 名前              |  型   | デフォルト | 説明 |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | ブール値 | `false` | 統合されたオブジェクトストレージの使用を有効にします。 |
| `proxy_download`  | ブール値 | `true`  | GitLab経由のすべてのダウンロードについて、`bucket`から直接ダウンロードする代わりにプロキシを有効にします。 |
| `storage_options` | 文字列  | `{}`    | [下記を参照](#storage_options)。 |
| `connection`      | 文字列  | `{}`    | [下記を参照](#connection)。 |

プロパティの構造は共有されており、ここに示されているすべてのプロパティは、以下の個々の項目によってオーバーライドできます。`connection`プロパティの構造は同じです。

> [!note]
> `bucket`、`enabled`、および`proxy_download`プロパティは、デフォルト値から逸脱したい場合にのみ、項目レベル（`global.appConfig.artifacts.bucket`など）で設定する必要がある唯一のプロパティです。

[接続](#connection)に`AWS`プロバイダー（任意のS3互換プロバイダー）を使用する場合、GitLab Workhorseはストレージ関連のすべてのアップロードをオフロードできます。この統合された設定を使用すると、この機能は自動的に有効になります。

### バケットを指定する {#specify-buckets}

オブジェクトは、タイプごとに異なるバケットに格納する必要があります。デフォルトで、GitLabがタイプごとに使用するバケット名は次のとおりです。

> [!note]
> エージェントプランコンテンツバケットは現在開発中であり、GitLab.comでのみ使用されています。セルフマネージドのユーザーは、まだこのバケットをプロビジョニングする必要はありません。

| オブジェクトタイプ                    | バケット名 |
|--------------------------------|-------------|
| CIアーティファクト                   | `gitlab-artifacts` |
| Git LFS                        | `git-lfs`   |
| パッケージ                       | `gitlab-packages` |
| アップロード                        | `gitlab-uploads` |
| 外部マージリクエストの差分   | `gitlab-mr-diffs` |
| Terraformステート                | `gitlab-terraform-state` |
| CIセキュアファイル                | `gitlab-ci-secure-files` |
| エージェントプランコンテンツ（オプション）  | `gitlab-agent-plan-content` |
| 依存プロキシ               | `gitlab-dependency-proxy` |
| Pages                          | `gitlab-pages` |

これらのデフォルトを使用するか、またはバケット名を設定することができます。

```shell
--set global.appConfig.artifacts.bucket=<BUCKET NAME> \
--set global.appConfig.lfs.bucket=<BUCKET NAME> \
--set global.appConfig.packages.bucket=<BUCKET NAME> \
--set global.appConfig.uploads.bucket=<BUCKET NAME> \
--set global.appConfig.externalDiffs.bucket=<BUCKET NAME> \
--set global.appConfig.terraformState.bucket=<BUCKET NAME> \
--set global.appConfig.ciSecureFiles.bucket=<BUCKET NAME> \
--set global.appConfig.agentPlanContent.bucket=<BUCKET NAME> \
--set global.appConfig.dependencyProxy.bucket=<BUCKET NAME>
```

#### `storage_options` {#storage_options}

`storage_options`は、[S3サーバー側の暗号化](https://docs.gitlab.com/administration/object_storage/#server-side-encryption-headers)を設定するために使用されます。

暗号化を有効にする最も簡単な方法はS3バケットでデフォルトの暗号化を設定することですが、[暗号化されたオブジェクトだけがアップロードされるようにバケットポリシーを設定する](https://repost.aws/knowledge-center/s3-bucket-store-kms-encrypted-objects)こともできます。そのためには、`storage_options`設定セクションで適切な暗号化ヘッダーを送信するようにGitLabを設定する必要があります。

| 設定                             | 説明 |
|-------------------------------------|-------------|
| `server_side_encryption`            | 暗号化モード（`AES256`または`aws:kms`）。 |
| `server_side_encryption_kms_key_id` | Amazonリソース名。これが必要になるのは`server_side_encryption`で`aws:kms`を使用する場合だけです。[KMS暗号化の使用に関するAmazonドキュメント](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html)を参照してください。 |

例: 

```yaml
  enabled: true
  proxy_download: true
  connection:
    secret: gitlab-rails-storage
    key: connection
  storage_options:
    server_side_encryption: aws:kms
    server_side_encryption_kms_key_id: arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab
```

### LFS、アーティファクト、アップロード、パッケージ、外部MR差分、依存プロキシ {#lfs-artifacts-uploads-packages-external-mr-diffs-and-dependency-proxy}

これらの設定の詳細を以下に示します。`bucket`プロパティのデフォルト値を除けば、構造的に同じなので、ドキュメントを個別に繰り返すことはしません。

```yaml
  enabled: true
  proxy_download: true
  bucket:
  connection:
    secret:
    key:
```

| 名前             |  型   | デフォルト                                                      | 説明 |
|:-----------------|:-------:|:-------------------------------------------------------------|:------------|
| `enabled`        | ブール値 | LFS、アーティファクト、アップロード、およびパッケージのデフォルトは`true` | オブジェクトストレージでこれらの機能の使用を有効にします。 |
| `proxy_download` | ブール値 | `true`                                                       | GitLab経由のすべてのダウンロードについて、`bucket`から直接ダウンロードする代わりにプロキシを有効にします。 |
| `bucket`         | 文字列  | さまざま                                                      | オブジェクトストレージプロバイダーから使用するバケットの名前。サービスに応じて、デフォルトは`git-lfs`、`gitlab-artifacts`、`gitlab-uploads`、`gitlab-packages`のどれかになります。 |
| `connection`     | 文字列  | `{}`                                                         | [下記を参照](#connection)。 |

#### `connection` {#connection}

`connection`プロパティは、Kubernetes Secretに移行されました。このシークレットの内容はYAML形式のファイルである必要があります。

このプロパティには、`secret`と`key`の2つのサブキーがあります。

- `secret`はKubernetes Secretの名前です。外部オブジェクトストレージを使用するには、この値が必要です。
- `key`は、YAMLブロックが含まれるシークレット内でのキーの名前です。デフォルトは`connection`です。

有効な設定キーについては、[GitLabジョブアーティファクトの管理](https://docs.gitlab.com/administration/cicd/secure_files/#s3-compatible-connection-settings)のドキュメントに記載されています。これは[Fog](https://github.com/fog/fog.github.com)に対応しており、プロバイダーモジュールに応じて異なります。

[AWS](https://fog.github.io/storage/#using-amazon-s3-and-fog)と[Google](https://fog.github.io/storage/#google-cloud-storage)プロバイダーの場合の例が、[`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)にあります。

- [`rails.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.s3.yaml)
- [`rails.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.gcs.yaml)
- [`rails.azurerm.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.azurerm.yaml)

`connection`の内容を含むYAMLファイルを作成したら、このファイルを使用してKubernetesにシークレットを作成します。

```shell
kubectl create secret generic gitlab-rails-storage \
    --from-file=connection=rails.yaml
```

#### `when`（外部MR差分のみ） {#when-only-for-external-mr-diffs}

`externalDiffs`の設定には、[オブジェクトストレージに特定の差分を条件付きで保存する](https://docs.gitlab.com/administration/merge_request_diffs/#alternative-in-database-storage)ための追加キー`when`があります。Railsコードによってデフォルト値が割り当てられるようにするため、チャートではこの設定がデフォルトで空のままになっています。

#### `cdn`（CIアーティファクトのみ） {#cdn-only-for-ci-artifacts}

`artifacts`の設定には、[Google Cloud Storageバケットの前段にGoogle CDNを設定する](../advanced/external-object-storage/_index.md#google-cloud-cdn)ための追加キー`cdn`があります。

### 受信メールの設定 {#incoming-email-settings}

受信メールの設定については、[コマンドラインオプション](../installation/command-line-options.md#incoming-email-configuration)のページで説明されています。

### KASの設定 {#kas-settings}

#### カスタムシークレット {#custom-secret}

オプションとして、KAS `secret`の名前と`key`をカスタマイズできます。そのためには、以下のようにしてHelmの`--set variable`オプションを使用するか、

```shell
--set global.appConfig.gitlab_kas.secret=custom-secret-name \
--set global.appConfig.gitlab_kas.key=custom-secret-key \
```

または、`values.yaml`を以下のように設定します。

```yaml
global:
  appConfig:
    gitlab_kas:
      secret: "custom-secret-name"
      key: "custom-secret-key"
```

シークレット値をカスタマイズする場合は、[シークレットに関するドキュメント](../installation/secrets.md#gitlab-kas-secret)を参照してください。

#### カスタムURL {#custom-urls}

GitLabバックエンドでKASに使用されるURLは、Helmの`--set variable`オプションを使用してカスタマイズできます。

```shell
--set global.appConfig.gitlab_kas.externalUrl="wss://custom-kas-url.example.com" \
--set global.appConfig.gitlab_kas.internalUrl="grpc://custom-internal-url" \
--set global.appConfig.gitlab_kas.clientTimeoutSeconds=10 # Optional, default is 5 seconds
```

または、`values.yaml`を以下のように設定します。

```yaml
global:
  appConfig:
    gitlab_kas:
      externalUrl: "wss://custom-kas-url.example.com"
      internalUrl: "grpc://custom-internal-url"
      clientTimeoutSeconds: 10 # Optional, default is 5 seconds
```

#### 外部KAS {#external-kas}

外部KASサーバー（チャートによって管理されていないもの）は、それを明示的に有効にして必要なURLを設定することにより、GitLabバックエンドに認識させることができます。そのためには、以下のようにしてHelmの`--set variable`オプションを使用するか、

```shell
--set global.appConfig.gitlab_kas.enabled=true \
--set global.appConfig.gitlab_kas.externalUrl="wss://custom-kas-url.example.com" \
--set global.appConfig.gitlab_kas.internalUrl="grpc://custom-internal-url" \
--set global.appConfig.gitlab_kas.clientTimeoutSeconds=10 # Optional, default is 5 seconds
```

または、`values.yaml`を以下のように設定します。

```yaml
global:
  appConfig:
    gitlab_kas:
      enabled: true
      externalUrl: "wss://custom-kas-url.example.com"
      internalUrl: "grpc://custom-internal-url"
      clientTimeoutSeconds: 10 # Optional, default is 5 seconds
```

#### TLSの設定 {#tls-settings-1}

KASは、`kas`ポッドとその他のGitLabチャートコンポーネントとの間でTLS通信をサポートします。

前提条件: 

- [GitLab 15.5.1](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101571#note_1146419137)以降を使用します。GitLabのバージョンは、`global.gitlabVersion: <version>`で設定できます。初期デプロイ後にイメージの更新を強制する必要がある場合は、`global.image.pullPolicy: Always`も設定します。
- `kas`ポッドが信頼する[認証局](../advanced/internal-tls/_index.md)と証明書を作成します。

作成した証明書を使用するように`kas`を設定するには、次の値を設定します。

| 値                         | 説明 |
|-------------------------------|-------------|
| `global.kas.tls.enabled`      | 証明書ボリュームをマウントし、`kas`エンドポイントへのTLS通信を有効にします。 |
| `global.kas.tls.secretName`   | 証明書の保存場所となるKubernetes TLSシークレットを指定します。 |
| `global.kas.tls.verify`       | `true`の場合、NGINX IngressはKASのバックエンドTLS証明書を検証するよう指示されます。自己署名証明書の場合は`false`に設定する必要があります。[Gateway API](../advanced/gateway-api/_index.md#tls-between-gateway-and-backend-services)を使用する場合、Gateway APIコントローラーは常に証明書を検証します。 |
| `global.kas.tls.caSecretName` | カスタムCAの保存場所となるKubernetes TLSシークレットを指定します。 |

たとえば、チャートをデプロイするには、`values.yaml`ファイルで以下を使用することができます。

```yaml
.internal-ca: &internal-ca gitlab-internal-tls-ca # The secret name you used to share your TLS CA.
.internal-tls: &internal-tls gitlab-internal-tls # The secret name you used to share your TLS certificate.

global:
  certificates:
    customCAs:
    - secret: *internal-ca
  hosts:
    domain: gitlab.example.com # Your gitlab domain
  kas:
    tls:
      enabled: true
      secretName: *internal-tls
      caSecretName: *internal-ca
```

### ナレッジグラフ設定 {#knowledge-graph-settings}

これらの設定を使用して、[GitLabナレッジグラフ](https://gitlab.com/gitlab-org/orbit/knowledge-graph)インテグレーションを設定します。

```yaml
global:
  appConfig:
    knowledgeGraph:
      enabled: false
      jwtSecret:
        secret:
        key:
      grpcEndpoint:
```

| 名前                | 型    | デフォルト | 説明 |
|:--------------------|:-------:|:--------|:------------|
| `enabled`           | ブール値 | `false` | ナレッジグラフインテグレーションを有効または無効にします。 |
| `jwtSecret.secret`  | 文字列  |         | 共有JWTキーを含むKubernetesシークレット名。 |
| `jwtSecret.key`     | 文字列  |         | JWT共有キー値を保持するシークレット内のキー。 |
| `grpcEndpoint`      | 文字列  |         | ナレッジグラフサービスのgRPCエンドポイント (例: `gkg.example.com:50054`)。 |

### LDAP {#ldap}

`ldap.servers`の設定により、[LDAP](https://docs.gitlab.com/administration/auth/ldap/)ユーザー認証を設定できます。これはマップとして提示され、ソースからのインストールと同じようにして、`gitlab.yml`の中の適切なLDAPサーバー設定に変換されます。

パスワードを設定するには、パスワードを保持する`secret`を指定します。このパスワードは、ランタイム時にGitLabの設定に挿入されます。

設定スニペットの例:

```yaml
ldap:
  preventSignin: false
  servers:
    # 'main' is the GitLab 'provider ID' of this LDAP server
    main:
      label: 'LDAP'
      host: '_your_ldap_server'
      port: 636
      uid: 'sAMAccountName'
      bind_dn: 'cn=administrator,cn=Users,dc=domain,dc=net'
      base: 'dc=domain,dc=net'
      password:
        secret: my-ldap-password-secret
        key: the-key-containing-the-password
```

グローバルチャートを使用する場合の`--set`設定項目の例:

```shell
--set global.appConfig.ldap.servers.main.label='LDAP' \
--set global.appConfig.ldap.servers.main.host='your_ldap_server' \
--set global.appConfig.ldap.servers.main.port='636' \
--set global.appConfig.ldap.servers.main.uid='sAMAccountName' \
--set global.appConfig.ldap.servers.main.bind_dn='cn=administrator\,cn=Users\,dc=domain\,dc=net' \
--set global.appConfig.ldap.servers.main.base='dc=domain\,dc=net' \
--set global.appConfig.ldap.servers.main.password.secret='my-ldap-password-secret' \
--set global.appConfig.ldap.servers.main.password.key='the-key-containing-the-password'
```

> [!note]
> カンマはHelm `--set`アイテム内では[特殊文字](https://helm.sh/docs/intro/using_helm/#the-format-and-limitations-of---set)とみなされます。`bind_dn`のような値のカンマはエスケープしてください: `--set global.appConfig.ldap.servers.main.bind_dn='cn=administrator\,cn=Users\,dc=domain\,dc=net'`。

#### LDAP Webサインインを無効にする {#disable-ldap-web-sign-in}

SAMLなどの代替手段を優先したい場合、Web UIでのLDAP認証を無効にすると便利です。これにより、グループ同期にLDAPを使用しつつ、SAML Identity Providerがカスタム2FAなどの追加チェックを処理できるようになります。

LDAPウェブサインインが無効になっている場合、ユーザーはサインインページにLDAPタブを見ることができません。これは[Gitアクセス用のLDAP認証情報の使用](https://docs.gitlab.com/administration/settings/sign_in_restrictions/#allow-password-authentication-for-git-over-https)を無効にするものではありません。

WebサインインにLDAPを使用することを無効にするには、`global.appConfig.ldap.preventSignin: true`を設定します。

#### カスタムCAまたは自己署名LDAP証明書を使用する {#using-a-custom-ca-or-self-signed-ldap-certificates}

LDAPサーバーでカスタムCAまたは自己署名証明書を使用する場合は、以下を実行する必要があります。

1. カスタムCA/自己署名証明書がクラスター/ネームスペース内のシークレットまたはConfigMapとして作成されていることを確認します。

   ```shell
   # Secret
   kubectl -n gitlab create secret generic my-custom-ca-secret --from-file=unique_name.crt=my-custom-ca.pem

   # ConfigMap
   kubectl -n gitlab create configmap my-custom-ca-configmap --from-file=unique_name.crt=my-custom-ca.pem
   ```

1. その上で、以下を指定します。

   ```shell
   # Configure a custom CA from a Secret
   --set global.certificates.customCAs[0].secret=my-custom-ca-secret

   # Or from a ConfigMap
   --set global.certificates.customCAs[0].configMap=my-custom-ca-configmap

   # Configure the LDAP integration to trust the custom CA
   --set global.appConfig.ldap.servers.main.ca_file=/etc/ssl/certs/unique_name.pem
   ```

これにより、CA証明書が`/etc/ssl/certs/unique_name.pem`の関連するポッドにマウントされ、LDAP設定でそれを使用することが指定されます。

詳細については、[カスタムCA](#custom-certificate-authorities)を参照してください。

### `duoAuth` {#duoauth}

これらの設定を使用して、[Cisco Duoを使用した2要素認証（2FA）](https://docs.gitlab.com/user/profile/account/two_factor_authentication/#enable-two-factor-authentication)を有効にします。

```yaml
global:
  appConfig:
    duoAuth:
      enabled:
      hostname:
      integrationKey:
      secretKey:
      #  secret:
      #  key:
```

| 名前             |  型   | デフォルト | 説明 |
|:-----------------|:-------:|:--------|:------------|
| `enabled`        | ブール値 | `false` | Cisco Duoとのインテグレーションを有効または無効にします |
| `hostname`       | 文字列  |         | Cisco Duo APIホスト名 |
| `integrationKey` | 文字列  |         | Cisco Duo APIインテグレーションキー |
| `secretKey`      |         |         | シークレット名とキー名で[設定する必要がある](#configure-the-cisco-duo-secret-key)Cisco Duo APIシークレットキー |

### Cisco Duoシークレットキーを設定する {#configure-the-cisco-duo-secret-key}

GitLabヘルムチャートでCisco Duo認証インテグレーションを設定するには、Cisco Duo認証secret_key値を含む`global.appConfig.duoAuth.secretKey.secret`設定にシークレットを指定する必要があります。

Cisco Duoアカウント`secretKey`を保存するためのKubernetesシークレットオブジェクトを作成するには、コマンドラインから次を実行します:

```shell
kubectl create secret generic <secret_object_name> --from-literal=secretKey=<duo_secret_key_value>
```

### OmniAuth {#omniauth}

GitLabでは、OmniAuthを利用することにより、ユーザーがGitHub、Google、その他の一般的なサービスを使用してサインインできるようになっています。詳細については、GitLabの[OmniAuthドキュメント](https://docs.gitlab.com/integration/omniauth/#configure-common-settings)を参照してください。

```yaml
omniauth:
  enabled: false
  autoSignInWithProvider:
  syncProfileFromProvider: []
  syncProfileAttributes: ['email']
  allowSingleSignOn: ['saml']
  blockAutoCreatedUsers: true
  autoLinkLdapUser: false
  autoLinkSamlUser: false
  autoLinkUser: ['openid_connect']
  externalProviders: []
  allowBypassTwoFactor: []
  providers: []
  # - secret: gitlab-google-oauth2
  #   key: provider
  # - name: group_saml
```

| 名前                      | 型             | デフォルト |
|:--------------------------|:-----------------|:--------|
| `allowBypassTwoFactor`    | ブール値または配列 | `false` |
| `allowSingleSignOn`       | ブール値または配列 | `['saml']` |
| `autoLinkLdapUser`        | ブール値          | `false` |
| `autoLinkSamlUser`        | ブール値          | `false` |
| `autoLinkUser`            | ブール値または配列 | `false` |
| `autoSignInWithProvider`  |                  | `nil`   |
| `blockAutoCreatedUsers`   | ブール値          | `true`  |
| `enabled`                 | ブール値          | `false` |
| `externalProviders`       |                  | `[]`    |
| `providers`               |                  | `[]`    |
| `syncProfileAttributes`   |                  | `['email']` |
| `syncProfileFromProvider` |                  | `[]`    |

#### `providers` {#providers}

`providers`は、ソースからインストールする場合と同じように、`gitlab.yml`の設定に使用されるマップの配列として提示されます。[サポートされているプロバイダー](https://docs.gitlab.com/integration/omniauth/#supported-providers)の利用可能な選択については、GitLabドキュメントを参照してください。デフォルトは`[]`です。

このプロパティには、`secret`と`key`の2つのサブキーがあります。

- `secret`: *（必須）*プロバイダーブロックを含むKubernetes `Secret`の名前。
- `key`: *（オプション）*`Secret`の中で、プロバイダーブロックを含むキーの名前。デフォルトは`provider`です。

あるいは、プロバイダーに名前以外の設定がない場合、`name`属性だけを指定した2番目の形式を使うことができます。オプションとして`label`または`icon`の属性も指定できます。対象となるプロバイダーは次のとおりです。

- [`group_saml`](https://docs.gitlab.com/integration/saml/#configure-group-saml-sso-on-gitlab-self-managed)
- [`kerberos`](https://docs.gitlab.com/integration/saml/#configure-group-saml-sso-on-gitlab-self-managed)

[OmniAuthプロバイダー](https://docs.gitlab.com/integration/omniauth/)で説明されているように、これらのエントリの`Secret`にはYAML形式またはJSON形式のブロックが含まれています。このシークレットを作成するには、これらの項目を取得するための適切な手順に従い、YAMLまたはJSONのファイルを作成します。

Google OAuth 2.0の設定例:

```yaml
name: google_oauth2
label: Google
app_id: 'APP ID'
app_secret: 'APP SECRET'
args:
  access_type: offline
  approval_prompt: ''
```

SAMLの設定例:

```yaml
name: saml
label: 'SAML'
args:
  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
  idp_cert_fingerprint: 'xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx'
  idp_sso_target_url: 'https://SAML_IDP/app/xxxxxxxxx/xxxxxxxxx/sso/saml'
  issuer: 'https://gitlab.example.com'
  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
```

Microsoft Azure OAuth 2.0 OmniAuthプロバイダーの設定例:

```yaml
name: azure_activedirectory_v2
label: Azure
args:
  client_id: '<CLIENT_ID>'
  client_secret: '<CLIENT_SECRET>'
  tenant_id: '<TENANT_ID>'
```

この内容は`provider.yaml`として保存でき、そこからシークレットを作成できます。

```shell
kubectl create secret generic -n NAMESPACE SECRET_NAME --from-file=provider=provider.yaml
```

それが作成されたら、以下に示すように、設定の中にマップを提供することにより`providers`が有効になります。

```yaml
omniauth:
  providers:
    - secret: gitlab-google-oauth2
    - secret: azure_activedirectory_v2
    - secret: gitlab-azure-oauth2
    - secret: gitlab-cas3
```

[グループSAML](https://docs.gitlab.com/integration/saml/#configure-group-saml-sso-on-gitlab-self-managed)の設定例:

```yaml
omniauth:
  providers:
    - name: group_saml
```

グローバルチャートを使用する場合の`--set`設定項目の例:

```shell
--set global.appConfig.omniauth.providers[0].secret=gitlab-google-oauth2 \
```

`--set`引数は使い方が複雑であるため、ユーザーによっては、YAMLスニペットを使用し、`-f omniauth.yaml`を使って`helm`に渡す方法を選択するかもしれません。

### cronジョブ関連の設定 {#cron-jobs-related-settings}

Sidekiqには、cronスタイルのスケジュールを使用して定期的に実行されるように設定できるメンテナンスジョブが含まれています。いくつかの例を以下に示します。ジョブのその他の例については、サンプル[`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/config/gitlab.yml.example)の`cron_jobs`と`ee_cron_jobs`のセクションを参照してください。

これらの設定は、Sidekiq、Webサービス（UIにツールチップを表示するため）、およびToolbox（デバッグ目的）のポッドの間で共有されます。

```yaml
global:
  appConfig:
    cron_jobs:
      stuck_ci_jobs_worker:
        cron: "0 * * * *"
      pipeline_schedule_worker:
        cron: "3-59/10 * * * *"
      expire_build_artifacts_worker:
        cron: "*/7 * * * *"
```

### Sentryの設定 {#sentry-settings}

これらの設定は、[SentryによるGitLabエラーレポート](https://docs.gitlab.com/omnibus/settings/configuration/#error-reporting-and-logging-with-sentry)を有効にするために使用します。

```yaml
global:
  appConfig:
    sentry:
      enabled:
      dsn:
      clientside_dsn:
      environment:
```

| 名前             |  型   | デフォルト | 説明 |
|:-----------------|:-------:|:--------|:------------|
| `enabled`        | ブール値 | `false` | インテグレーションを有効または無効にする |
| `dsn`            | 文字列  |         | バックエンドエラーのSentry DNS |
| `clientside_dsn` | 文字列  |         | フロントエンドエラーのSentry DNS |
| `environment`    | 文字列  |         | [Sentry環境](https://docs.sentry.io/concepts/key-terms/environments/)を参照 |

### `gitlab_docs` の設定 {#gitlab_docs-settings}

これらの設定は、`gitlab_docs`を有効にするために使用します。

```yaml
global:
  appConfig:
    gitlab_docs:
      enabled:
      host:
```

| 名前      |  型   | デフォルト | 説明 |
|:----------|:-------:|:--------|:------------|
| `enabled` | ブール値 | `false` | `gitlab_docs`を有効または無効にする |
| `host`    | 文字列  | `""`    | ドキュメントホスト   |

### OpenID Connectトークンの有効期限 {#openid-connect-token-expiration}

OpenID Connect（OIDC）プロバイダーのトークンの有効期限を設定します。

```yaml
global:
  appConfig:
    oidcProvider:
      openidIdTokenExpireInSeconds: 120
```

| 名前                           | 型    | デフォルト | 説明 |
|--------------------------------|---------|---------|-------------|
| `openidIdTokenExpireInSeconds` | 整数 | 120     | IDトークンが有効期限切れになるまでの時間（秒単位）。 |

### スマートカード認証の設定 {#smartcard-authentication-settings}

```yaml
global:
  appConfig:
    smartcard:
      enabled: false
      CASecret:
      clientCertificateRequiredHost:
      sanExtensions: false
      requiredForGitAccess: false
```

| 名前                            |  型   | デフォルト | 説明 |
|:--------------------------------|:-------:|:--------|:------------|
| `enabled`                       | ブール値 | `false` | スマートカード認証を有効または無効にする。 |
| `CASecret`                      | 文字列  |         | CA証明書が格納されているシークレットの名前。 |
| `clientCertificateRequiredHost` | 文字列  |         | スマートカード認証に使用するホスト名。デフォルトでは、指定された、または計算によるスマートカードホスト名が使用されます。 |
| `sanExtensions`                 | ブール値 | `false` | ユーザーと証明書を照合するためにSAN拡張機能を使用できるようにします。 |
| `requiredForGitAccess`          | ブール値 | `false` | Gitアクセスのためのスマートカードサインインでブラウザセッションを必須にします。 |

スマートカード認証は、[バンドルされたEnvoy Gateway](envoygateway/_index.md)で特別な設定なしにすぐに使用できます。代わりに[バンドルされたNGINX Ingress](nginx/_index.md)を使用するには、スニペットアノテーションを有効にする必要があります。

スニペットアノテーションを有効にすると、カスタムNGINX設定をアノテーションを介して挿入できるようになりますが、これは特定の環境でセキュリティリスクをもたらす可能性があります。アノテーションを有効にする前に、[アップストリームドキュメント](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#allow-snippet-annotations)を確認してください。

```yaml
nginx-ingress:
  enabled: true
  controller:
    config:
      allow-snippet-annotations: "true"
      annotations-risk-level: "Critical"
```

### Sidekiqルーティングルールの設定 {#sidekiq-routing-rules-settings}

GitLabでは、ジョブのスケジュールを設定する前に、ワーカーから目的のキューへのジョブルーティングがサポートされています。Sidekiqクライアントは、設定されたルーティングルールリストに基づいてジョブを照合します。ルールは先頭から順に評価され、特定のワーカーで一致した時点で、そのワーカーの処理は停止されます（最初の一致が優先されます）。ワーカーがどのルールにも一致しない場合、ワーカー名から生成されるキュー名に戻ります。

デフォルトの場合、ルーティングルールは未設定です（または空の配列で示されます）。すべてのジョブは、ワーカー名から生成されるキューにルーティングされます。

ルーティングルールリストは、クエリとそれに対応するキューのタプルを要素とする順序付き配列です。

- クエリは、[ワーカー一致クエリ](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#worker-matching-query)の構文に従います。
- `<queue_name>`は、[`sidekiq.pods`](gitlab/sidekiq/_index.md#per-pod-settings)で定義されている有効なSidekiqキュー名`sidekiq.pods[].queues`と一致する必要があります。キュー名（queue_name）が`nil`または空の文字列の場合、ワーカーはワーカー名から生成されるキューにルーティングされます。参考として、[Sidekiqの完全な設定例](gitlab/sidekiq/_index.md#full-example-of-sidekiq-configuration)をご覧ください。

クエリは、ワイルドカード`*`による一致をサポートしており、これはすべてのワーカーに一致します。そのため、ワイルドカードを使用したクエリはリストの最後に配置する必要があります。そうしないと、それ以降のルールは無視されます。

```yaml
global:
  appConfig:
    sidekiq:
      routingRules:
      - ["resource_boundary=cpu", "cpu-boundary"]
      - ["feature_category=pages", null]
      - ["feature_category=search", "search"]
      - ["feature_category=memory|resource_boundary=memory", "memory-bound"]
      - ["*", "default"]
```

## Railsを設定する {#configure-rails-settings}

GitLabスイートの大部分はRailsを基盤としています。そのため、このプロジェクト内の多くのコンテナはこのスタックで動作します。以下の設定は、それらのコンテナすべてに適用され、個別ではなくグローバルに設定するための簡単なアクセス手段となります。

```yaml
global:
  rails:
    bootsnap:
      enabled: true
```

## Workhorseを設定する {#configure-workhorse-settings}

GitLabスイートのいくつかのコンポーネントは、GitLab Workhorseを介してAPIと通信します。現在、これはWebserviceチャートの一部となっています。これらの設定は、GitLab Workhorseに接続する必要があるすべてのチャートで使用され、個別ではなくグローバルに設定するための簡単なアクセス手段となります。

```yaml
global:
  workhorse:
    serviceName: webservice-default
    host: api.example.com
    port: 8181
```

| 名前          | 型    | デフォルト              | 説明 |
|:--------------|:--------|:---------------------|:------------|
| `serviceName` | 文字列  | `webservice-default` | 内部APIトラフィックの宛先となるサービスの名前。リリース名はテンプレート処理されるため、含めないでください。`gitlab.webservice.deployments`のエントリと一致する必要があります。[`gitlab/webservice`チャート](gitlab/webservice/_index.md#deployments-settings)を参照してください。 |
| `scheme`      | 文字列  | `http`               | APIエンドポイントのスキーム |
| `host`        | 文字列  |                      | APIエンドポイントの完全修飾ホスト名またはIPアドレス。`serviceName`があればそれをオーバーライドします。 |
| `port`        | 整数 | `8181`               | 関連するAPIサーバーのポート番号。 |
| `tls.enabled` | ブール値 | `false`              | `true`に設定すると、WorkhorseのTLSサポートが有効になります。 |

### Bootsnapキャッシュ {#bootsnap-cache}

当社のRailsコードベースは、[Bootsnap](https://github.com/rails/bootsnap) gemを利用しています。その動作を設定するため、以下の設定が使用されます。

`bootsnap.enabled`は、この機能をアクティブにするかどうかを制御します。デフォルトは`true`です。

テストの結果、Bootsnapを有効にすると、アプリケーションのパフォーマンスが全体として向上することが示されました。プリコンパイル済みキャッシュが利用可能な場合、一部のアプリケーションコンテナでは33％を超える性能向上が見られます。現時点で、GitLabではコンテナにこのプリコンパイル済みキャッシュが同梱されていないため、「わずか」14％の向上にとどまっています。ただし、プリコンパイル済みキャッシュが存在しない場合、この性能向上の代償として、各ポッドの初回起動時に小規模なIOが集中的に多数発生します。このため、Bootsnapの使用が問題となる環境でBootsnapの使用を無効にする手段が公開されています。

可能な場合は、これを有効にしておくことをおすすめします。

## GitLab Shellを設定する {#configure-gitlab-shell}

[GitLab Shell](gitlab/gitlab-shell/_index.md)チャートのグローバル設定には、複数の項目があります。

```yaml
global:
  shell:
    port:
    authToken: {}
    hostKeys: {}
    tcp:
      proxyProtocol: false
```

| 名前                |  型   | デフォルト | 説明 |
|:--------------------|:-------:|:--------|:------------|
| `port`              | 整数 | `22`    | 詳細については、下記の[`port`](#port)のドキュメントを参照してください。 |
| `authToken`         |         |         | GitLab Shellチャートの[`authToken`](gitlab/gitlab-shell/_index.md#authtoken)に関するドキュメントを参照してください。 |
| `hostKeys`          |         |         | GitLab Shellチャートの[`hostKeys`](gitlab/gitlab-shell/_index.md#hostkeyssecret)に関するドキュメントを参照してください。 |
| `tcp.proxyProtocol` | ブール値 | `false` | 詳細については、下記の[TCPプロキシプロトコル](#tcp-proxy-protocol)を参照してください。 |

### ポート {#port}

IngressがSSHトラフィックを渡すために使用するポートと、GitLabから提供されるSSH URLで使用されるポートは、`global.shell.port`により制御できます。これは、サービスがリッスンするポートと、プロジェクトUIで提供されるSSHクローンURLに反映されます。

```yaml
global:
  shell:
    port: 32022
```

`global.shell.port`と`nginx-ingress.controller.service.type=NodePort`を組み合わせることにより、NGINXコントローラーのServiceオブジェクトのNodePortを設定できます。`nginx-ingress.controller.service.nodePorts.gitlab-shell`が設定されている場合、NGINXのNodePortを設定すると`global.shell.port`がオーバーライドされることに注意してください。

```yaml
global:
  shell:
    port: 32022

nginx-ingress:
  controller:
    service:
      type: NodePort
```

### TCPプロキシプロトコル {#tcp-proxy-protocol}

SSH Ingressで[プロキシプロトコル](https://www.haproxy.com/blog/use-the-proxy-protocol-to-preserve-a-clients-ip-address)の処理を有効にすると、プロキシプロトコルヘッダーを追加するアップストリームプロキシからの接続を適切に処理できます。それにより、SSHが追加のヘッダーを受信してSSHが損なわれるのを防ぐことができます。

プロキシプロトコルの処理を有効にすることが必要になる環境としてよくあるのは、クラスターへの受信接続を処理するELBでAWSを使用している場合です。そのための適切な設定については、[AWSレイヤー4ロードバランサーの例](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/elb-layer4-loadbalancer.yaml)を参照してください。

```yaml
global:
  shell:
    tcp:
      proxyProtocol: true # default false
```

## GitLab Pagesを設定する {#configure-gitlab-pages}

他のチャートで使用されるグローバルGitLab Pages設定についてのドキュメントは、`global.pages`キーの下にあります。

```yaml
global:
  pages:
    enabled:
    accessControl:
    path:
    host:
    port:
    https:
    externalHttp:
    externalHttps:
    customDomainMode:
    artifactsServer:
    objectStore:
      enabled:
      bucket:
      proxy_download: true
      connection: {}
        secret:
        key:
    localStore:
      enabled: false
      path:
    apiSecret: {}
      secret:
      key:
    namespaceInPath: false
```

| 名前                            |  型   | デフォルト                    | 説明 |
|:--------------------------------|:-------:|:---------------------------|:------------|
| `enabled`                       | ブール値 | `false`                    | クラスターにGitLab Pagesチャートをインストールするかどうかを決定します。 |
| `accessControl`                 | ブール値 | `false`                    | GitLab Pagesへのアクセス制御を有効にします。 |
| `path`                          | 文字列  | `/srv/gitlab/shared/pages` | Pagesデプロイ関連のファイルを保存するパス。注: オブジェクトストレージが使用されるため、デフォルトでは未使用です。 |
| `host`                          | 文字列  |                            | Pagesルートドメイン。 |
| `port`                          | 文字列  |                            | UIでPagesのURLを構成するために使用されるポート。設定されていない場合、PagesのHTTPS状況に基づいて80または443がデフォルト値として設定されます。 |
| `https`                         | ブール値 | `true`                     | GitLab UIにPagesのHTTPS URLを表示するかどうか。`global.hosts.pages.https`と`global.hosts.https`のどちらよりも優先されます。 |
| `externalHttp`                  |  リスト   | `[]`                       | HTTPリクエストがPagesデーモンに到達するまでのIPアドレスのリスト。[カスタムドメイン](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/)のサポート。 |
| `externalHttps`                 |  リスト   | `[]`                       | HTTPSリクエストがPagesデーモンに到達するまでのIPアドレスのリスト。[カスタムドメイン](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/)のサポート。 |
| `customDomainMode`              | 文字列  |                            | [カスタムドメイン](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/)を有効にするように設定します。`http`または`https`。 |
| `artifactsServer`               | ブール値 | `true`                     | GitLab Pagesでアーティファクトの表示を有効にします。 |
| `objectStore.enabled`           | ブール値 | `true`                     | Pagesでオブジェクトストレージの使用を有効にします。 |
| `objectStore.bucket`            | 文字列  | `gitlab-pages`             | Pagesに関連するコンテンツの保存に使用されるバケット。 |
| `objectStore.connection.secret` | 文字列  |                            | オブジェクトストレージの接続詳細を含むシークレット。 |
| `objectStore.connection.key`    | 文字列  |                            | 接続シークレットのうち、接続の詳細が格納されるキー。 |
| `localStore.enabled`            | ブール値 | `false`                    | Pagesに関連するコンテンツに（`objectStore`ではなく）ローカルストレージを使用できるようにします。 |
| `localStore.path`               | 文字列  | `/srv/gitlab/shared/pages` | Pagesのファイル保存先のパス。`localStore`がtrueに設定されている場合にのみ使用されます。 |
| `apiSecret.secret`              | 文字列  |                            | Base64エンコード形式の32ビットAPIキーを内容とするシークレット。 |
| `apiSecret.key`                 | 文字列  |                            | APIキーシークレットのうち、APIキーが格納されるキー。 |
| `namespaceInPath`               | ブール値 | `false`                    | （ベータ版）ワイルドカードDNSを使用しない設定をサポートするため、URLパスでのネームスペースを有効または無効にします。詳細については、[ワイルドカードDNSを使用しないPagesドメインのドキュメント](gitlab/gitlab-pages/_index.md#pages-domain-without-wildcard-dns)を参照してください。 |

## Webserviceを設定する {#configure-webservice}

（他のチャートでも使用される）Webserviceのグローバル設定についてのドキュメントは、`global.webservice`キーの下にあります。

```yaml
global:
  webservice:
    workerTimeout: 60
```

### `workerTimeout` {#workertimeout}

WebサービスワーカープロセスがWebサービスマスタープロセスによって強制終了されるまでのリクエストタイムアウト（秒単位）を設定します。デフォルト値は60秒です。

`global.webservice.workerTimeout`の設定は、最大リクエスト時間には影響しません。最大リクエスト時間を設定するには、次の環境変数を設定します。

```yaml
gitlab:
  webservice:
    workerTimeout: 60
    extraEnv:
      GITLAB_RAILS_RACK_TIMEOUT: "60"
      GITLAB_RAILS_WAIT_TIMEOUT: "90"
```

## カスタム認証局 {#custom-certificate-authorities}

> [!note]
> これらの設定は、バンドルされたサードパーティのチャートには影響しません。

社内で発行されたSSL証明書をTLSサービスで使用する場合など、カスタム認証局（CA）を追加する必要が生じることがあります。この機能を提供するため、シークレットまたはConfigMapを通じて、アプリケーションにカスタムルート認証局を適用するためのメカニズムが用意されています。

シークレットまたはConfigMapを作成するには、次のようにします。

```shell
# Create a Secret from a certificate file
kubectl create secret generic secret-custom-ca --from-file=unique_name.crt=/path/to/cert

# Create a ConfigMap from a certificate file
kubectl create configmap cm-custom-ca --from-file=unique_name.crt=/path/to/cert
```

シークレットまたはConfigMap（またはその両方）を設定するには、グローバルでそれらを指定します。

```yaml
global:
  certificates:
    customCAs:
      - secret: secret-custom-ca           # Mount all keys of a Secret
      - secret: secret-custom-ca           # Mount only the specified keys of a Secret
        keys:
          - unique_name.crt
      - configMap: cm-custom-ca            # Mount all keys of a ConfigMap
      - configMap: cm-custom-ca            # Mount only the specified keys of a ConfigMap
        keys:
          - unique_name_1.crt
          - unique_name_2.crt
```

> [!note]
> シークレットのキー名にある`.crt`拡張子は、[Debian update-ca-certificatesパッケージ](https://manpages.debian.org/bullseye/ca-certificates/update-ca-certificates.8.en.html)にとって重要です。この手順を実行すれば、カスタムCAファイルがその拡張子でマウントされ、証明書`initContainers`で処理されることが保証されます。以前は、[ドキュメント](https://gitlab.alpinelinux.org/alpine/ca-certificates/-/blob/master/update-ca-certificates.8)の記述とは異なり、証明書ヘルパーイメージがalpineベースだった場合、実際にはファイル拡張子が必須ではありませんでした。UBIベースの`update-ca-trust`ユーティリティには、同じ要件はないようです。

任意の数のシークレットまたはConfigMapを指定し、それぞれに、PEMエンコードのCA証明書を保持するキーを必要な数だけ設定できます。これらは、`global.certificates.customCAs`の下のエントリとして設定します。マウントする特定のキーのリストを`keys:`に指定しない限り、すべてのキーがマウントされます。すべてのシークレットおよびConfigMapにわたるマウント対象のキーは、いずれも一意でなければなりません。シークレットとConfigMapには任意の名前を付けることができますが、キー名が*競合してはいけません*。

## アプリケーションリソース {#application-resource}

GitLabには、オプションで[アプリケーションリソース](https://github.com/kubernetes-sigs/application)を含めることができます。これは、クラスター内でGitLabアプリケーションを識別するために作成できます。バージョン`v1beta1`の[Application CRD](https://github.com/kubernetes-sigs/application)がすでにクラスターにデプロイされている必要があります。

有効にするには、`global.application.create`を`true`に設定します。

```yaml
global:
  application:
    create: true
```

Google GKE Marketplaceなどの一部の環境においては、ClusterRoleリソースの作成が許可されていません。以下の値を設定することにより、アプリケーションカスタムリソース定義に含まれるClusterRoleのコンポーネントと、クラウドネイティブGitLabに同梱の関連チャートを無効にしてください。

```yaml
global:
  application:
    allowClusterRoles: false
nginx:
  controller:
    scope:
      enabled: true
gitlab-runner:
  rbac:
    clusterWideAccess: false
installCertmanager: false
```

## GitLabベースイメージ {#gitlab-base-image}

GitLab Helmチャートでは、さまざまな初期化タスクのために1つの共通のGitLabベースイメージを使用します。このイメージではUBIビルドがサポートされており、レイヤーを他のイメージと共有します。

## サービスアカウント {#service-accounts}

GitLab Helmチャートでは、カスタム[サービスアカウント](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/)を使用してポッドを実行することができます。これは、`global.serviceAccount`で次のように設定します。

```yaml
global:
  serviceAccount:
    enabled: false
    create: true
    annotations: {}
    automountServiceAccountToken: false
    ## Name to be used for serviceAccount, otherwise defaults to chart fullname
    # name:
```

- `global.serviceAccount.enabled`の設定は、各コンポーネントでの`spec.serviceAccountName`を介したサービスアカウントへの参照を制御します。
- `global.serviceAccount.create`の設定は、Helmを介したサービスアカウントオブジェクトの作成を制御します。
- `global.serviceAccount.name`の設定は、サービスアカウントのオブジェクト名と、各コンポーネントが参照する名前を制御します。
- `global.serviceAccount.automountServiceAccountToken`の設定は、デフォルトのServiceAccountアクセストークンをポッドにマウントする必要があるかどうかを制御します。これは、特定のサイドカーが正常に機能するために必要という場合（Istioなど）を除き、有効にしないようにしてください。

> [!note]
> `global.serviceAccount.create=true`と`global.serviceAccount.name`を一緒に使用しないでください。これは、チャートが同じ名前で複数のServiceAccountオブジェクトを作成するように指示するためです。グローバル名を指定する場合は、代わりに`global.serviceAccount.create=false`を使用します。

## アノテーション {#annotations}

Deployment、Service、Ingressの各オブジェクトには、カスタムアノテーションを適用できます。

```yaml
global:
  deployment:
    annotations:
      environment: production

  service:
    annotations:
      environment: production

  ingress:
    annotations:
      environment: production
```

## ノードセレクター {#node-selector}

カスタム`nodeSelector`をすべてのコンポーネントにグローバルに適用できます。グローバルのデフォルト値があるなら、各サブチャートで個別にそれをオーバーライドすることもできます。

```yaml
global:
  nodeSelector:
    disktype: ssd
```

> [!note]
> 外部でメンテナンスされているチャートは、現時点では`global.nodeSelector`を尊重せず、利用可能なチャートの値に基づいて別途設定する必要がある場合があります。これにはPrometheus、cert-manager、およびその他のサブチャートが含まれます。

## トレランス {#tolerations}

カスタム`tolerations`はすべてのコンポーネントにグローバルに適用できます。グローバルのデフォルト値があるなら、各サブチャートで個別にそれをオーバーライドすることもできます。

```yaml
global:
  tolerations:
    - key: "key1"
      operator: "Equal"
      value: "value1"
      effect: "NoSchedule"
```

> [!note]
> 外部でメンテナンスされているチャートは、現時点では`global.tolerations`を尊重せず、利用可能なチャートの値に基づいて別途設定する必要がある場合があります。これにはPrometheus、cert-manager、およびその他のサブチャートが含まれます。

## DNS設定 {#dns-configuration}

ポッドレベルの[`dnsConfig`](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-dns-config)は、すべてのGitLabコンポーネントにグローバルに適用できます。最も一般的なユースケースは、`ndots`の値を下げて、完全修飾された外部ホスト名（S3エンドポイントなど）を解決する際にKubernetesが生成するNXDOMAIN応答の数を減らすことです。これにより、DNSパフォーマンスを大幅に向上させることができます。

```yaml
global:
  dnsConfig:
    options:
      - name: ndots
        value: "2"
```

グローバルデフォルトは、サブチャートレベルで`dnsConfig`を設定することで、任意のGitLabサブチャートで上書きできます。例えば、Sidekiqを除くすべてにグローバルデフォルトを適用する場合:

```yaml
global:
  dnsConfig:
    options:
      - name: ndots
        value: "2"

gitlab:
  sidekiq:
    dnsConfig:
      options:
        - name: ndots
          value: "3"
```

未設定（デフォルト）の場合、`dnsConfig`は出力されず、Kubernetesのデフォルトが適用され、既存のクラスター動作が維持されます。

> [!note]
> 外部でメンテナンスされているチャートは、現時点では`global.dnsConfig`を尊重せず、利用可能なチャートの値に基づいて別途設定する必要がある場合があります。これにはPrometheus、cert-manager、およびその他のサブチャートが含まれます。

## ラベル {#labels}

### 共通ラベル {#common-labels}

ラベルは、設定`common.labels`を使用することにより、さまざまなオブジェクトによって作成されるほぼすべてのオブジェクトに適用できます。これは、`global`キーの下、または特定のチャートの設定の下で適用できます。例: 

```yaml
global:
  common:
    labels:
      environment: production
gitlab:
  gitlab-shell:
    common:
      labels:
        foo: bar
```

上記の設定例の場合、Helmチャートによってデプロイされるほぼすべてのコンポーネントに、ラベルセット`environment: production`が指定されています。GitLab Shellチャートのすべてのコンポーネントが、ラベルセット`foo: bar`を受け取ることになります。一部のチャートでは、追加のネストが可能です。たとえば、SidekiqチャートとWebserviceチャートでは、設定のニーズに応じて追加のデプロイが可能です。

```yaml
gitlab:
  sidekiq:
    pods:
      - name: pod-0
        common:
          labels:
            baz: bat
```

上記の例では、`pod-0` Sidekiqデプロイに関連付けられているすべてのコンポーネントも、`baz: bat`のラベルセットを受け取ります。詳細については、SidekiqチャートとWebserviceチャートを参照してください。

ここで利用している一部のチャートは、このラベル設定から除外されています。これらの追加ラベルを受け取るのは、[GitLabコンポーネントのサブチャート](gitlab/_index.md)だけです。

### `pod` {#pod}

カスタムラベルは、さまざまなデプロイとジョブに適用できます。これらのラベルは、このHelmチャートによって構築される既存のラベルまたは事前設定済みラベルを補完するものです。これらの補足ラベルは、`matchSelectors`では**利用されません**。

```yaml
global:
  pod:
    labels:
      environment: production
```

### `service` {#service}

カスタムラベルをサービスに適用することができます。これらのラベルは、このHelmチャートによって構築される既存のラベルまたは事前設定済みラベルを補完するものです。

```yaml
global:
  service:
    labels:
      environment: production
```

## トレーシング {#tracing}

GitLab Helmチャートではトレーシングがサポートされており、それは次のようにして設定できます。

```yaml
global:
  tracing:
    connection:
      string: 'opentracing://jaeger?http_endpoint=http%3A%2F%2Fjaeger.example.com%3A14268%2Fapi%2Ftraces&sampler=const&sampler_param=1'
    urlTemplate: 'http://jaeger-ui.example.com/search?service={{ service }}&tags=%7B"correlation_id"%3A"{{ correlation_id }}"%7D'
```

- `global.tracing.connection.string`は、トレーシングスパンの送信先を設定するために使用します。詳細については、[GitLabトレーシングのドキュメント](https://docs.gitlab.com/development/distributed_tracing/)を参照してください
- `global.tracing.urlTemplate`は、GitLabパフォーマンスバーでのトレーシング情報URLレンダリングのためのテンプレートとして使用します。

## `extraEnv` {#extraenv}

`extraEnv`を使用すると、GitLabチャート（`charts/gitlab/charts`）によりデプロイされるポッド内のすべてのコンテナで、追加の環境変数を公開できます。グローバルレベルで設定された追加の環境変数は、チャートレベルで指定された変数にマージされ、チャートレベルで指定された変数が優先されます。

`extraEnv`の使用例を以下に示します。

```yaml
global:
  extraEnv:
    SOME_KEY: some_value
    SOME_OTHER_KEY: some_other_value
```

## `extraEnvFrom` {#extraenvfrom}

`extraEnvFrom`を使用すると、ポッド内のすべてのコンテナで、他のデータソースからの追加の環境変数を公開できます。追加の環境変数は、`global`レベル（`global.extraEnvFrom`）およびサブチャートレベル（`<subchart_name>.extraEnvFrom`）で設定できます。

SidekiqチャートとWebserviceチャートでは、追加のローカルオーバーライドがサポートされています。詳細については、それぞれのドキュメントを参照してください。

`extraEnvFrom`の使用例を以下に示します。

```yaml
global:
  extraEnvFrom:
    MY_NODE_NAME:
      fieldRef:
        fieldPath: spec.nodeName
    MY_CPU_REQUEST:
      resourceFieldRef:
        containerName: test-container
        resource: requests.cpu
gitlab:
  kas:
    extraEnvFrom:
      CONFIG_STRING:
        configMapKeyRef:
          name: useful-config
          key: some-string
          # optional: boolean
```

> [!note]
> 実装は、異なるコンテンツタイプで値名を再利用することをサポートしていません。同じ名前を類似の内容でオーバーライドすることは可能ですが、`secretKeyRef`や`configMapKeyRef`などのソースが混在しないようにしてください。

## OAuthを設定する {#configure-oauth-settings}

OAuthインテグレーションは、サポートするサービスに合わせてすぐに利用できる設定になっています。`global.oauth`で指定されているサービスは、デプロイ中に、OAuthクライアントアプリケーションとして自動的にGitLabに登録されます。デフォルトでは、アクセス制御が有効になっている場合、このリストにGitLab Pagesが含まれています。

```yaml
global:
  oauth:
    gitlab-pages: {}
    # secret
    # appid
    # appsecret
    # redirectUri
    # authScope
```

| 名前           | 型   | デフォルト | 説明 |
|:---------------|:-------|:--------|:------------|
| `secret`       | 文字列 |         | サービスのOAuth認証情報を含むシークレットの名前。 |
| `appIdKey`     | 文字列 |         | シークレットのうち、サービスのアプリIDが格納されるキー。設定されるデフォルト値は`appid`です。 |
| `appSecretKey` | 文字列 |         | シークレットのうち、サービスのアプリシークレットが格納されるキー。設定されるデフォルト値は`appsecret`です。 |
| `redirectUri`  | 文字列 |         | 認証が成功した後、ユーザーがリダイレクトされる先のURI。 |
| `authScope`    | 文字列 | `api`   | GitLab APIでの認証に使用されるスコープ。 |

シークレットの詳細については、[シークレットのドキュメント](../installation/secrets.md#oauth-integration)を参照してください。

## Kerberos {#kerberos}

GitLab HelmチャートでKerberosインテグレーションを設定するには、GitLabホストのサービスプリンシパルを指定したKerberos [keytab](https://web.mit.edu/kerberos/krb5-devel/doc/basic/keytab_def.html)を含むシークレットを、`global.appConfig.kerberos.keytab.secret`設定に指定する必要があります。keytabファイルがない場合は、Kerberos管理者にお問い合わせください。

次のスニペットを使用してシークレットを作成できます（`gitlab`ネームスペースにチャートをインストールしており、サービスプリンシパルを含むkeytabファイルが`gitlab.keytab`であると仮定しています）。

```shell
kubectl create secret generic gitlab-kerberos-keytab --namespace=gitlab --from-file=keytab=./gitlab.keytab
```

GitのKerberosインテグレーションは、`global.appConfig.kerberos.enabled=true`を設定することにより有効になります。これにより、ブラウザでのチケットベース認証のために有効な[OmniAuth](https://docs.gitlab.com/integration/omniauth/)プロバイダーのリストに、`kerberos`プロバイダーも追加されます。

`false`のままにした場合も、Helmチャートは、ツールボックス、Sidekiq、およびWebサービスのポッドに`keytab`をマウントします。それを、Kerberos用に手動で設定された[OmniAuth設定](#omniauth)で使用することができます。

Kerberosクライアントの設定は、`global.appConfig.kerberos.krb5Config`で指定できます。

```yaml
global:
  appConfig:
    kerberos:
      enabled: true
      keytab:
        secret: gitlab-kerberos-keytab
        key: keytab
      servicePrincipalName: ""
      krb5Config: |
        [libdefaults]
            default_realm = EXAMPLE.COM
      dedicatedPort:
        enabled: false
        port: 8443
        https: true
      simpleLdapLinkingAllowedRealms:
        - example.com
```

詳細については、[Kerberosのドキュメント](https://docs.gitlab.com/integration/kerberos/)を参照してください。

### Kerberosの専用ポート {#dedicated-port-for-kerberos}

GitLabでは、Git操作にHTTPプロトコルを使用する場合、認証交換で`negotiate`ヘッダーが含まれていると基本認証にフォールバックするというGitの制限の回避策として、[Kerberosネゴシエーション専用ポート](https://docs.gitlab.com/integration/kerberos/#http-git-access-with-kerberos-token-passwordless-authentication)の使用がサポートされています。

現在のところ、GitLab CI/CDを使用する場合に専用ポートの使用は必須です。GitLab Runnerのヘルパーは、GitLabからのクローン作成で、URL内の認証情報に依存しているためです。

これは、`global.appConfig.kerberos.dedicatedPort`の設定により有効にすることができます。

```yaml
global:
  appConfig:
    kerberos:
      [...]
      dedicatedPort:
        enabled: true
        port: 8443
        https: true
```

これにより、GitLab UIでKerberosネゴシエーション専用の追加クローンURLが有効になります。`https: true`の設定はURL生成専用であり、追加のTLS設定は公開されていません。TLSは、Ingressの中でGitLab用に終端処理され、設定されます。

> [!note]
> [当社の`nginx-ingress` Helmチャートのフォーク](nginx/_index.md)における現在の制限により、`dedicatedPort`を指定しても、チャートの`nginx-ingress`コントローラーで使用するポートが現在公開されません。クラスターのオペレーターが、このポートを自分で公開する必要があります。詳細および可能な回避策については、[こちらのチャートイシュー](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3531)を参照してください。

### LDAPカスタム許可レルム {#ldap-custom-allowed-realms}

ユーザーのLDAP DNがユーザーのKerberosレルムと一致しない場合、LDAPのアイデンティティとKerberosのアイデンティティをリンクするために使用されるドメインのセットを、`global.appConfig.kerberos.simpleLdapLinkingAllowedRealms`により指定できます。詳細については、[Kerberosインテグレーションのドキュメントにあるカスタム許可レルムのセクション](https://docs.gitlab.com/integration/kerberos/#custom-allowed-realms)を参照してください。

## 送信メール {#outgoing-email}

送信メールは、`global.smtp.*`、`global.appConfig.microsoft_graph_mailer.*`、`global.email.*`により設定できます。

```yaml
global:
  email:
    display_name: 'GitLab'
    from: 'gitlab@example.com'
    reply_to: 'noreply@example.com'
  smtp:
    enabled: true
    address: 'smtp.example.com'
    tls: true
    authentication: 'plain'
    user_name: 'example'
    # Alternatively, read the username from a Kubernetes Secret:
    # user_name_secret:
    #   secret: 'smtp-username'
    #   key: 'username'
    password:
      secret: 'smtp-password'
      key: 'password'
  appConfig:
    microsoft_graph_mailer:
      enabled: false
      user_id: "YOUR-USER-ID"
      tenant: "YOUR-TENANT-ID"
      client_id: "YOUR-CLIENT-ID"
      client_secret:
        secret:
        key: secret
      azure_ad_endpoint: "https://login.microsoftonline.com"
      graph_endpoint: "https://graph.microsoft.com"
```

使用可能な設定オプションの詳細については、[送信メールのドキュメント](../installation/command-line-options.md#outgoing-email-configuration)を参照してください。

[LinuxパッケージのSMTP設定のドキュメント](https://docs.gitlab.com/omnibus/settings/smtp/)に、詳しい例が含まれています。

## プラットフォーム {#platform}

`platform`キーは、GKEやEKSなどの特定のプラットフォームをターゲットとする特定の機能のために予約されています。

## アフィニティ {#affinity}

アフィニティは、`global.antiAffinity`と`global.affinity`により設定できます。アフィニティを使用すると、ノードのラベルまたはノードですでに実行されているポッドのラベルに基づいて、ポッドをスケジュール可能なノードを制限できます。これにより、ポッドをクラスター全体に分散させたり、特定のノードを選択したりできるため、ノードが失敗した場合の回復力が向上します。

```yaml
global:
  antiAffinity: soft
  affinity:
    podAntiAffinity:
      topologyKey: "kubernetes.io/hostname"
```

| 名前                                   | 型   | デフォルト                  | 説明 |
|:---------------------------------------|:-------|:-------------------------|:------------|
| `antiAffinity`                         | 文字列 | `soft`                   | ポッドに適用するポッドアンチアフィニティ。 |
| `affinity.podAntiAffinity.topologyKey` | 文字列 | `kubernetes.io/hostname` | ポッドアンチアフィニティのトポロジキー。 |

- `global.antiAffinity`には、次の2つの値を指定できます。
  - `soft`: `preferredDuringSchedulingIgnoredDuringExecution`アンチアフィニティを定義します。この場合、Kubernetesスケジューラーが、結果を保証せずにルールの適用を試みます。
  - `hard`: ノードにスケジュールされるポッドのルールを満たす必要のある`requiredDuringSchedulingIgnoredDuringExecution`のアンチアフィニティを定義します。
- `global.affinity.podAntiAffinity.topologyKey`は、それらを論理ゾーンに分割するために使用されるノード属性を定義します。最も一般的な`topologyKey`値は次のとおりです。
  - `kubernetes.io/hostname`
  - `topology.kubernetes.io/zone`
  - `topology.kubernetes.io/region`

[ポッド間アフィニティとアンチアフィニティ](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity)に関するKubernetesのリファレンス

## ポッドの優先度とプリエンプション {#pod-priority-and-preemption}

ポッドの優先度は、`global.priorityClassName`により、またはサブチャートごとに`priorityClassName`により設定できます。ポッドの優先順位を設定することで、スケジューラに低優先順位のポッドを退去させ、保留中のポッドのスケジューリングを可能にするよう指示できます。

```yaml
global:
  priorityClassName: system-cluster-critical
```

| 名前                | 型   | デフォルト | 説明 |
|:--------------------|:-------|:--------|:------------|
| `priorityClassName` | 文字列 |         | ポッドに割り当てられる優先度クラス。 |

## ログローテーション {#log-rotation}

{{< history >}}

- GitLab 15.6で[導入](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger/-/merge_requests/10)されました。

{{< /history >}}

デフォルトでは、GitLab Helmチャートはログローテーションを実行しません。これにより、長時間実行されるコンテナで、一時的なストレージの問題が発生する可能性があります。

ログローテーションを有効にするには、`GITLAB_LOGGER_TRUNCATE_LOGS`環境変数を`true`に設定します。詳細については、[GitLab Loggerのドキュメント](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger#configuration)を参照してください。特に、以下の情報を参照してください。

- [`GITLAB_LOGGER_TRUNCATE_INTERVAL`](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger#truncate-logs-interval)。
- [`GITLAB_LOGGER_MAX_FILESIZE`](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger#max-log-file-size)。

## ジョブ {#jobs}

元々、GitLabのジョブには、Helmの`.Release.Revision`がサフィックスとして付いていましたが、`helm upgrade --install`を実行するたびに、何も変更されていなくても常にジョブが更新されてしまうため、理想的な方法ではありませんでした。また、ArgoCDを使用している場合など、`helm template`に基づくワークフローとの連携が正しく動作しない原因にもなっていました。ジョブ名に`.Release.Revision`を使用するという判断は、ジョブが1回しか実行されず、かつ`helm uninstall`がジョブを削除しないという前提に基づいていましたが、これは（現在では）間違っています。

GitLab Helmチャート7.9以降では、ジョブ名にはデフォルトで、チャートのアプリバージョンとチャートの値（`global.gitlabVersion`を含む可能性がある）に基づくハッシュがサフィックスとして付与されます。このアプローチにより、（何も変更されていない場合は）`helm template`や`helm upgrade --install`を複数回実行してもジョブ名は安定して維持されます。また、ジョブの不変フィールドの値を変更した場合でも（名前が新しくなることで新しいジョブに置き換えられ）、デプロイ中にエラーが発生しなくなります。

`global.job.nameSuffixOverride`を設定することにより、デフォルトで生成されるハッシュを、カスタムサフィックスでオーバーライドすることができます。このフィールドはテンプレート処理をサポートしているため、`.Release.Revision`を名前のサフィックスとして使用していた以前の動作を再現することができます。

```yaml
global:
  job:
    nameSuffixOverride: '{{ .Release.Revision }}'
```

すべてのバージョンで`latest`のような浮動タグ付けを使用しているなどの理由で、意図的に常に変更をトリガーする場合、デフォルトで生成されるハッシュを、タイムスタンプなどの動的な値でオーバーライドすることができます。

```yaml
global:
  job:
    nameSuffixOverride: '{{ dateInZone "2006-01-02-15-04-05" (now) "UTC" }}'
```

または、コマンドラインで`helm`を使用することもできます。

```shell
helm <command> <options> --set global.job.nameSuffixOverride=$(date +%Y-%m-%d-%H-%M-%S)
```

| 名前                 | 型   | デフォルト | 説明 |
|:---------------------|:-------|:--------|:------------|
| `nameSuffixOverride` | 文字列 |         | 自動的に生成されるハッシュを置き換えるカスタムサフィックス |

## Traefik {#traefik}

Traefikは、`globals.traefik`により設定できます。

```yaml
global:
  traefik:
    apiVersion: ""
```

| 名前         | 型   | デフォルト | 説明 |
|:-------------|:-------|:--------|:------------|
| `apiVersion` | 文字列 |         | Traefikのリソースのデフォルトの`apiVersion`をオーバーライドします |

## デプロイされたStatefulSetsおよびデプロイの古いリビジョン保持数を設定する {#configure-the-number-of-old-revisions-retained-for-the-deployed-statefulsets-and-deployments}

`global.revisionHistoryLimit`設定により、すべてのGitLabサブチャートで`revisionHistoryLimit`オプションを設定できます。このオプションは、それぞれのサブチャートの`values.yaml`ファイルで、チャートごとに上書きできます。

```yaml
global:
  revisionHistoryLimit: 10
```

| 名前                   | 型    | デフォルト | 説明                                               |
|:-----------------------|:--------|:--------|:----------------------------------------------------------|
| `revisionHistoryLimit` | 整数 |         | すべてのGitLabサブチャートに対して`revisionHistoryLimit`を設定します。 |
