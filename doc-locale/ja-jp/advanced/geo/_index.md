---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabチャートでGitLab Geoを設定する
---

GitLab Geoは、地理的に分散されたアプリケーションデプロイ機能を提供します。

外部データベースサービスも利用可能ですが、これらのドキュメントは[Linuxパッケージ](https://docs.gitlab.com/omnibus/)のPostgreSQLの使用に焦点を当てており、最もプラットフォームに依存しないガイドを提供し、`gitlab-ctl`に含まれる自動化を利用しています。

このガイドでは、両方のクラスターが同じ外部URLを持っています。この機能はチャートのバージョン7.3以降でサポートされています。[Geoサイトの統合URLを設定する](https://docs.gitlab.com/administration/geo/secondary_proxy/#set-up-a-unified-url-for-geo-sites)を参照してください。必要に応じて、[セカンダリサイトに個別のURLを設定](#configure-a-separate-url-for-the-secondary-site-optional)できます。

既知のイシューについては、[Geoのドキュメント](https://docs.gitlab.com/administration/geo/#known-issues)を参照してください。

> [!note]
> [定義された用語](https://docs.gitlab.com/administration/geo/glossary/)でGeoのすべての側面（主に`site`サイトと`node`ノードの区別）について説明しています。

## 要件 {#requirements}

GitLab GeoをGitLab Helmチャートと併用するには、以下の要件を満たす必要があります:

- [外部PostgreSQL](../external-db/_index.md)サービスを使用すること。なぜなら、チャートに含まれるPostgreSQLは外部ネットワークに公開されておらず、レプリケーションに必要なWALサポートがないためです。
- 提供されるデータベースは次の条件を満たす必要があります:
  - レプリケーションをサポートしていること。
  - プライマリデータベースはプライマリサイト、およびすべてのセカンダリデータベースノード（レプリケーション用）からアクセス可能であること。
  - セカンダリデータベースはセカンダリサイトからのみアクセス可能であること。
  - プライマリとセカンダリのデータベースノード間でSSLをサポートすること。
- プライマリサイトは、すべてのセカンダリサイトからHTTP(S)経由でアクセス可能である必要があります。セカンダリサイトは、プライマリサイトからHTTP(S)経由でアクセス可能である必要があります。
- 要件の全リストについては、[Geoの実行要件](https://docs.gitlab.com/administration/geo/#requirements-for-running-geo)を参照してください。

## 概要 {#overview}

このガイドでは、Linuxパッケージを使用して作成された2つのデータベースノードと、PostgreSQLサービスのみを設定した2つのGitLab Helmチャートのデプロイを使用します。これは_最小限_の必要な設定であることを意図しています。このドキュメントには、アプリケーションからデータベースへのSSL、他のデータベースプロバイダーのサポート、または[セカンダリサイトをプライマリにプロモート](https://docs.gitlab.com/administration/geo/disaster_recovery/)することは含まれていません。

以下の概要は順序に従って実行してください:

1. [Linuxパッケージデータベースノードを設定](#set-up-linux-package-database-nodes)
1. [Kubernetesクラスターを設定](#set-up-kubernetes-clusters)
1. [情報を収集](#collect-information)
1. [プライマリデータベースを設定](#configure-primary-database)
1. [Geoプライマリサイトとしてチャートをデプロイ](#deploy-chart-as-geo-primary-site)
1. [Geoプライマリサイトを設定](#set-the-geo-primary-site)
1. [セカンダリデータベースを設定](#configure-secondary-database)
1. [プライマリサイトからセカンダリサイトへシークレットをコピー](#copy-secrets-from-the-primary-site-to-the-secondary-site)
1. [Geoセカンダリサイトとしてチャートをデプロイ](#deploy-chart-as-geo-secondary-site)
1. [プライマリ経由でセカンダリGeoサイトを追加](#add-secondary-geo-site-via-primary)
1. [稼働状況を確認](#confirm-operational-status)
1. [セカンダリサイトの個別のURLを設定（オプション）](#configure-a-separate-url-for-the-secondary-site-optional)
1. [レジストリ](#registry)
1. [Cert-managerと統合URL](#cert-manager-and-unified-url)

## Linuxパッケージデータベースノードを設定 {#set-up-linux-package-database-nodes}

このプロセスには2つのノードが必要です。一方はプライマリデータベースノード、もう一方はセカンダリデータベースノードです。オンプレミスまたはクラウドプロバイダーから、任意のインフラストラクチャプロバイダーを使用できます。

次の通信が必要であることに留意してください:

- 2つのデータベースノード間のレプリケーションのため。
- 各データベースノードと、それぞれのKubernetesデプロイ間:
  - プライマリはTCPポート`5432`を公開する必要があります。
  - セカンダリはTCPポート`5432` & `5431`を公開する必要があります。

[Linuxパッケージでサポートされているオペレーティングシステム](https://docs.gitlab.com/install/requirements/#operating-systems)をインストールし、その上に[Linuxパッケージ](https://about.gitlab.com/install/)をインストールします。インストール時には`EXTERNAL_URL`環境変数を指定しないでください。設定ファイルを再構成する前に、最小限の設定ファイルを提供します。

オペレーティングシステムとGitLabパッケージのインストール後、使用するサービスの設定を作成できます。その前に、情報を収集する必要があります。

## Kubernetesクラスターを設定 {#set-up-kubernetes-clusters}

このプロセスには、2つのKubernetesクラスターを使用する必要があります。これらは、オンプレミスまたはクラウドプロバイダーのいずれからでも利用できます。

次の通信が必要であることに留意してください:

- 各データベースノードへのアクセス:
  - プライマリのTCP `5432`への送信。
  - セカンダリのTCP `5432`および`5431`への送信。
- 両方のKubernetes Ingress間でHTTPS経由。

プロビジョニングされている各クラスターは、以下を備えている必要があります:

- これらのチャートのベースラインインストールをサポートするのに十分なリソース。
- 永続ストレージへのアクセス:
  - [外部オブジェクトストレージ](../external-object-storage/_index.md)を使用する場合はMinIOは不要です。
  - [外部Gitaly](../external-gitaly/_index.md)を使用する場合はGitalyは不要です。
  - [外部Redis](../external-redis/_index.md)を使用する場合はRedisは不要です。

## 情報を収集 {#collect-information}

設定を続行するには、様々なソースから以下の情報を収集する必要があります。これらを収集し、このドキュメントの残りの部分で使用するためのメモを作成してください。

- プライマリデータベース:
  - IPアドレス
  - ホスト名（オプション）
- セカンダリデータベース:
  - IPアドレス
  - ホスト名（オプション）
- プライマリクラスター:
  - 外部URL
  - 内部URL
  - ノードのIPアドレス
- セカンダリクラスター:
  - 内部URL
  - ノードのIPアドレス
- データベースパスワード（_事前にパスワードを決定しておく必要があります_）:
  - `gitlab`（`postgresql['sql_user_password']`、`global.psql.password`で使用）
  - `gitlab_geo`（`geo_postgresql['sql_user_password']`、`global.geo.psql.password`で使用）
  - `gitlab_replicator`（レプリケーションに必要）
- あなたのGitLabライセンスファイル

各クラスターの内部URLは、すべてのクラスターが他のすべてのクラスターにリクエストを送信できるように、そのクラスターに対して一意である必要があります。例: 

- すべてのクラスターの外部URL: `https://gitlab.example.com`
- プライマリクラスターの内部URL: `https://london.gitlab.example.com`
- セカンダリクラスターの内部URL: `https://shanghai.gitlab.example.com`

このガイドではDNSの設定については扱いません。

`gitlab`と`gitlab_geo`のデータベースユーザーパスワードは、生のパスワードとPostgreSQLのハッシュ化されたパスワードの2つの形式で存在する必要があります。ハッシュ化された形式を取得するには、Linuxパッケージインストールのいずれかのインスタンスで以下のコマンドを実行します。これにより、パスワードを入力して確認した後に、適切なハッシュ値が出力され、それをメモすることができます。

1. `gitlab-ctl pg-password-md5 gitlab`
1. `gitlab-ctl pg-password-md5 gitlab_geo`

## プライマリデータベースを設定 {#configure-primary-database}

_このセクションは、プライマリLinuxパッケージインストールのデータベースノードで実行されます。_

プライマリデータベースノードのLinuxパッケージインストールを設定するには、この設定例を参考にしてください:

```ruby
### Geo Primary
external_url 'http://gitlab.example.com'
roles ['geo_primary_role']
# The unique identifier for the Geo node.
gitlab_rails['geo_node_name'] = 'London Office'
# Allow cross-site origins for ActionCable requests.
gitlab_rails['action_cable_allowed_origins'] = ['https://gitlab.example.com']
gitlab_rails['auto_migrate'] = false
## turn off everything but the DB
sidekiq['enable']=false
puma['enable']=false
gitlab_workhorse['enable']=false
nginx['enable']=false
geo_logcursor['enable']=false
gitaly['enable']=false
redis['enable']=false
gitlab_kas['enable']=false
prometheus_monitoring['enable'] = false
## Configure the DB for network
postgresql['enable'] = true
postgresql['listen_address'] = '0.0.0.0'
postgresql['sql_user_password'] = 'gitlab_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - primary application deployment
# - secondary database node(s)
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
```

以下のいくつかの項目を置き換える必要があります:

- `external_url`は、私たちのプライマリサイトのホスト名を反映するように更新する必要があります。
- `gitlab_rails['geo_node_name']`は、あなたのサイトの一意の名前に置き換える必要があります。[共通設定](https://docs.gitlab.com/administration/geo_sites/#common-settings)の名前フィールドを参照してください。
- `gitlab_rails['action_cable_allowed_origins']`は、すべてのクラスター（プライマリとセカンダリの両方）、または同じ外部URLを持つ場合はそれらの統合URLの**external URLs**を含む配列に置き換える必要があります。
- `gitlab_user_password_hash`は、`gitlab`パスワードのハッシュ化された形式に置き換える必要があります。
- `postgresql['md5_auth_cidr_addresses']`は、明示的なIPアドレスのリスト、またはCIDR表記のアドレスブロックに更新できます。

`md5_auth_cidr_addresses`は`[ '127.0.0.1/24', '10.41.0.0/16']`の形式である必要があります。Linuxパッケージの自動化がこれを使用して接続するため、このリストに`127.0.0.1`を含めることが重要です。このリストのアドレスには、セカンダリデータベースのIPアドレス（ホスト名ではない）、およびプライマリKubernetesクラスターのすべてのノードを含める必要があります。これは`['0.0.0.0/0']`のままにしておく_こともできます_が、_ベストプラクティスではありません_。

上記の設定が準備されたら:

1. コンテンツを`/etc/gitlab/gitlab.rb`に配置します。
1. `gitlab-ctl reconfigure`を実行します。サービスがTCPをリッスンしないことに関するイシューが発生した場合は、`gitlab-ctl restart postgresql`で直接再起動してみてください。
1. `gitlab-ctl set-replication-password`を実行して、`gitlab_replicator`ユーザーのパスワードを設定します。
1. プライマリデータベースノードの公開証明書を取得する。これは、セカンダリデータベースがレプリケートするために必要です（この出力を保存してください）:

   ```shell
   cat ~gitlab-psql/data/server.crt
   ```

## Geoプライマリサイトとしてチャートをデプロイ {#deploy-chart-as-geo-primary-site}

_このセクションは、プライマリサイトのKubernetesクラスターで実行されます。_

このチャートをGeoプライマリとしてデプロイするには、[この設定例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml)から始めます:

1. チャートが使用するデータベースパスワードを含むシークレットを作成します。以下の`PASSWORD`を`gitlab`データベースユーザーのパスワードに置き換えます:

   ```shell
   kubectl --namespace gitlab create secret generic geo --from-literal=postgresql-password=PASSWORD
   ```

1. [設定例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml)に基づいて`primary.yaml`設定ファイルを作成し、正しい値を反映するように設定を更新します:

   ```yaml
   ### Geo Primary
   global:
     # See docs.gitlab.com/charts/charts/globals
     # Configure host & domain
     hosts:
       domain: example.com
       # optionally configure a static IP for the default LoadBalancer
       # externalIP:
       # optionally configure a static IP for the Geo LoadBalancer
       # externalGeoIP:
     # configure DB connection
     psql:
       host: geo-1.db.example.com
       port: 5432
       password:
         secret: geo
         key: postgresql-password
     # configure geo (primary)
     geo:
       nodeName: London Office
       enabled: true
       role: primary
   # External DB, disable
   postgresql:
     install: false
   ```

   <!-- markdownlint-disable MD044 -->
   - [`global.hosts.domain`](../../charts/globals.md#configure-host-settings)
   - [`global.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - `global.geo.nodeName`は、[管理者エリアのGeoサイトの名前フィールド](https://docs.gitlab.com/administration/geo_sites/#common-settings)と一致する必要があります。
   - また、次のような追加の設定も行います:
     - [SSL/TLSの設定](../../installation/tools.md#tls-certificates)
     - [外部Redisの使用](../external-redis/_index.md)
     - [外部オブジェクトストレージの使用](../external-object-storage/_index.md)
   <!-- markdownlint-enable MD044 -->

1. 必要なIngressまたはGateway API設定を`primary.yaml`に追加します。

   {{< tabs >}}

   {{< tab title="NGINX Ingress" >}}

   内部（サイト間）Geoトラフィック用の追加のNGINXコントローラーと、追加のwebservice Ingressを設定します:

   ```yaml
   # Configure Geo Nginx Controller for internal Geo site traffic
   nginx-ingress-geo:
     enabled: true
   gitlab:
     webservice:
       # Use the Geo NGINX controller.
       ingress:
         useGeoClass: true
       # Configure an Ingress for internal Geo traffic
       extraIngress:
         enabled: true
         hostname: gitlab.london.example.com
         useGeoClass: true
   ```

   {{< /tab >}}

   {{< tab title="Envoy Gateway" >}}

   NGINX Ingressベースのアプローチに代わって、[Gateway APIを設定](../../charts/globals.md#gateway-api)し、バンドルされている[Envoy Gateway](../../charts/envoygateway/_index.md)によってGeoを公開することもできます。

   Gateway APIを有効にした後、内部Geoトラフィックのホスト名を設定します:

   ```yaml
   global:
     geo:
       gatewayApi:
         additionalHostname: gitlab.london.example.com
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. この設定を使用してチャートをデプロイします:

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f primary.yaml
   ```

   > [!note]
   > これは、`gitlab`ネームスペースを使用していることを前提としています。別のネームスペースを使用する場合は、このドキュメントの残りの部分でも`--namespace gitlab`内のそれを置き換える必要があります。

1. デプロイが完了し、アプリケーションがオンラインになるまで待ちます。アプリケーションにアクセス可能になったら、ログインします。

1. GitLabにサインインし、[あなたのGitLabサブスクリプションをアクティベート](https://docs.gitlab.com/administration/license/)します。このステップはGeoが機能するために必要です。

## Geoプライマリサイトを設定 {#set-the-geo-primary-site}

チャートがデプロイされ、ライセンスがアップロードされたので、これをプライマリサイトとして設定できます。これはToolboxポッド経由で実行します。

1. Toolboxポッドを見つけます。

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. `kubectl exec`で`gitlab-rake geo:set_primary_node`を実行します:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake geo:set_primary_node
   ```

1. プライマリサイトの内部URLをRailsランナーコマンドで設定します。`https://primary.gitlab.example.com`を実際の内部URLに置き換えます:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rails runner "GeoNode.primary_node.update!(internal_url: 'https://primary.gitlab.example.com')"
   ```

1. Geo設定のステータスを確認します:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake gitlab:geo:check
   ```

   以下のような出力が表示されるはずです:

   ```plaintext
   WARNING: This version of GitLab depends on gitlab-shell 10.2.0, but you're running Unknown. Please update gitlab-shell.
   Checking Geo ...

   GitLab Geo is available ... yes
   GitLab Geo is enabled ... yes
   GitLab Geo secondary database is correctly configured ... not a secondary node
   Database replication enabled? ... not a secondary node
   Database replication working? ... not a secondary node
   GitLab Geo HTTP(S) connectivity ... not a secondary node
   HTTP/HTTPS repository cloning is enabled ... yes
   Machine clock is synchronized ... Exception: getaddrinfo: Servname not supported for ai_socktype
   Git user has default SSH configuration? ... yes
   OpenSSH configured to use AuthorizedKeysCommand ... no
     Reason:
     Cannot find OpenSSH configuration file at: /assets/sshd_config
     Try fixing it:
     If you are not using our official docker containers,
     make sure you have OpenSSH server installed and configured correctly on this system
     For more information see:
     doc/administration/operations/fast_ssh_key_lookup.md
   GitLab configured to disable writing to authorized_keys file ... yes
   GitLab configured to store new projects in hashed storage? ... yes
   All projects are in hashed storage? ... yes

   Checking Geo ... Finished
   ```

   - `Exception: getaddrinfo: Servname not supported for ai_socktype`については心配しないでください。Kubernetesコンテナはホストクロックにアクセスできないためです。_これは問題ありません_。
   - `OpenSSH configured to use AuthorizedKeysCommand ... no`は_想定内です_。このRakeタスクはローカルSSHサーバーをチェックしていますが、これは実際には`gitlab-shell`チャート内に存在し、別の場所にデプロイ済みで、適切に設定されています。

## セカンダリデータベースを設定 {#configure-secondary-database}

_このセクションは、セカンダリLinuxパッケージインストールのデータベースノードで実行されます。_

セカンダリデータベースノードのLinuxパッケージインストールを設定するには、この設定例を参考にしてください:

```ruby
### Geo Secondary
# external_url must match the Primary cluster's external_url
external_url 'http://gitlab.example.com'
roles ['geo_secondary_role']
gitlab_rails['enable'] = true
# The unique identifier for the Geo node.
gitlab_rails['geo_node_name'] = 'Shanghai Office'
gitlab_rails['auto_migrate'] = false
geo_secondary['auto_migrate'] = false
## turn off everything but the DB
sidekiq['enable']=false
puma['enable']=false
gitlab_workhorse['enable']=false
nginx['enable']=false
geo_logcursor['enable']=false
gitaly['enable']=false
redis['enable']=false
prometheus_monitoring['enable'] = false
gitlab_kas['enable']=false
## Configure the DBs for network
postgresql['enable'] = true
postgresql['listen_address'] = '0.0.0.0'
postgresql['sql_user_password'] = 'gitlab_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - secondary application deployment
# - secondary database node(s)
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
geo_postgresql['listen_address'] = '0.0.0.0'
geo_postgresql['sql_user_password'] = 'gitlab_geo_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - secondary application deployment
# - secondary database node(s)
geo_postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
gitlab_rails['db_password']='gitlab_user_password'
```

以下のいくつかの項目を置き換える必要があります:

- `gitlab_rails['geo_node_name']`は、あなたのサイトの一意の名前に置き換える必要があります。[共通設定](https://docs.gitlab.com/administration/geo_sites/#common-settings)の名前フィールドを参照してください。
- `gitlab_user_password_hash`は、`gitlab`パスワードのハッシュ化された形式に置き換える必要があります。
- `postgresql['md5_auth_cidr_addresses']`は、明示的なIPアドレスのリスト、またはCIDR表記のアドレスブロックに更新する必要があります。
- `gitlab_geo_user_password_hash`は、`gitlab_geo`パスワードのハッシュ化された形式に置き換える必要があります。
- `geo_postgresql['md5_auth_cidr_addresses']`は、明示的なIPアドレスのリスト、またはCIDR表記のアドレスブロックに更新する必要があります。
- `gitlab_user_password`は更新する必要があり、LinuxパッケージがPostgreSQLの設定を自動化するためにここで使用されます。

`md5_auth_cidr_addresses`は`[ '127.0.0.1/24', '10.41.0.0/16']`の形式である必要があります。Linuxパッケージの自動化がこれを使用して接続するため、このリストに`127.0.0.1`を含めることが重要です。このリストのアドレスには、セカンダリKubernetesクラスターのすべてのノードのIPアドレスを含める必要があります。これは`['0.0.0.0/0']`のままにしておく_こともできます_が、_ベストプラクティスではありません_。

上記の設定が準備されたら:

1. **プライマリ**サイトのPostgreSQLノードへのTCP接続を確認します:

   ```shell
   openssl s_client -connect <primary_node_ip>:5432 </dev/null
   ```

   出力は次のようになるはずです:

   ```plaintext
   CONNECTED(00000003)
   write:errno=0
   ```

   このステップが失敗した場合、誤ったIPアドレスを使用しているか、ファイアウォールがサーバーへのアクセスを妨げている可能性があります。IPアドレスを確認し、公開アドレスとプライベートアドレスの違いに注意を払い、ファイアウォールが存在する場合は、**セカンダリ** PostgreSQLノードがTCPポート5432で**プライマリ** PostgreSQLノードに接続することを許可されていることを確認してください。

1. コンテンツを`/etc/gitlab/gitlab.rb`に配置します。
1. `gitlab-ctl reconfigure`を実行します。サービスがTCPをリッスンしないことに関するイシューが発生した場合は、`gitlab-ctl restart postgresql`で直接再起動してみてください。
1. 上記のプライマリPostgreSQLノードの証明書コンテンツを`primary.crt`に配置します。
1. **セカンダリ** PostgreSQLノードでPostgreSQL TLS検証を設定します:

   `primary.crt`ファイルをインストールします:

   ```shell
   install \
      -D \
      -o gitlab-psql \
      -g gitlab-psql \
      -m 0400 \
      -T primary.crt ~gitlab-psql/.postgresql/root.crt
   ```

   PostgreSQLはTLS接続を検証する際に、その正確な証明書のみを認識するようになります。証明書は、秘密キーへのアクセス権を持つ人物のみがレプリケートすることができます。秘密キーは**プライマリ** PostgreSQLノードに**only**存在します。

1. `gitlab-psql`ユーザーが**プライマリ**サイトのPostgreSQL（デフォルトのLinuxパッケージデータベース名は`gitlabhq_production`）に接続できることをテストします:

   ```shell
   sudo \
      -u gitlab-psql /opt/gitlab/embedded/bin/psql \
      --list \
      -U gitlab_replicator \
      -d "dbname=gitlabhq_production sslmode=verify-ca" \
      -W \
      -h <primary_database_node_ip>
   ```

   プロンプトが表示されたら、`gitlab_replicator`ユーザーのために以前収集したパスワードを入力します。すべてが正しく機能した場合、**プライマリ** PostgreSQLノードのデータベースリストが表示されるはずです。

   ここでの失敗は、TLS設定が正しくないことを示しています。**プライマリ** PostgreSQLノード上の`~gitlab-psql/data/server.crt`の内容が、**セカンダリ** PostgreSQLノード上の`~gitlab-psql/.postgresql/root.crt`の内容と一致していることを確認してください。

1. データベースをレプリケートする。`PRIMARY_DATABASE_HOST`を、プライマリPostgreSQLノードのIPまたはホスト名に置き換えます:

   ```shell
   gitlab-ctl replicate-geo-database --slot-name=geo_2 --host=PRIMARY_DATABASE_HOST --sslmode=verify-ca
   ```

1. レプリケーションが完了したら、`pg_hba.conf`がセカンダリPostgreSQLノードに対して正しいことを確認するために、Linuxパッケージをもう一度再設定する必要があります:

   ```shell
   gitlab-ctl reconfigure
   ```

## プライマリサイトからセカンダリサイトへシークレットをコピー {#copy-secrets-from-the-primary-site-to-the-secondary-site}

次に、プライマリサイトのKubernetesデプロイからセカンダリサイトのKubernetesデプロイにいくつかのシークレットをコピーします:

- `gitlab-geo-gitlab-shell-host-keys`
- `gitlab-geo-rails-secret`
- レプリケーションが有効な場合は`gitlab-geo-registry-secret`レジストリ。

1. `kubectl`のコンテキストをプライマリのものに変更します。
1. プライマリデプロイからこれらのシークレットを収集します:

   ```shell
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-gitlab-shell-host-keys > ssh-host-keys.yaml
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-rails-secret > rails-secrets.yaml
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-registry-secret > registry-secrets.yaml
   ```

1. `kubectl`のコンテキストをセカンダリのものに変更します。
1. これらのシークレットを適用します:

   ```shell
   kubectl --namespace gitlab apply -f ssh-host-keys.yaml
   kubectl --namespace gitlab apply -f rails-secrets.yaml
   kubectl --namespace gitlab apply -f registry-secrets.yaml
   ```

次に、データベースパスワードを含むシークレットを作成します。以下のパスワードを適切な値に置き換えます:

```shell
kubectl --namespace gitlab create secret generic geo \
   --from-literal=postgresql-password=gitlab_user_password \
   --from-literal=geo-postgresql-password=gitlab_geo_user_password
```

## Geoセカンダリサイトとしてチャートをデプロイ {#deploy-chart-as-geo-secondary-site}

_このセクションは、セカンダリサイトのKubernetesクラスターで実行されます。_

このチャートをGeoセカンダリサイトとしてデプロイするには、[この設定例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/secondary.yaml)から始めます。

1. [設定例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/secondary.yaml)に基づいて`secondary.yaml`設定ファイルを作成し、正しい値を反映するように設定を更新します:

   ```yaml
   ## Geo Secondary
   global:
     # See docs.gitlab.com/charts/charts/globals
     # Configure host & domain
     hosts:
       domain: shanghai.example.com
       # use a unified URL (same external URL as the primary site)
       gitlab:
         name: gitlab.example.com
     # configure DB connection
     psql:
       host: geo-2.db.example.com
       port: 5432
       password:
         secret: geo
         key: postgresql-password
     # configure geo (secondary)
     geo:
       enabled: true
       role: secondary
       nodeName: Shanghai Office
       psql:
         host: geo-2.db.example.com
         port: 5431
         password:
           secret: geo
           key: geo-postgresql-password
   # External DB, disable
   postgresql:
     install: false
   ```

   <!-- markdownlint-disable MD044 -->
   - [`global.hosts.domain`](../../charts/globals.md#configure-host-settings)
   - [`global.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - [`global.geo.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - `global.geo.nodeName`は、[管理者エリアのGeoサイトの名前フィールド](https://docs.gitlab.com/administration/geo_sites/#common-settings)と一致する必要があります。
   - オプションで`nginx-ingress-geo.enabled`を設定して、内部Geoトラフィック用に事前に設定されたIngressコントローラーを有効にします。[これにより、サイトをプライマリにプロモートしやすくなります](../../charts/nginx/_index.md#gitlab-geo)。
   - また、次のような追加の設定も行います:
     - [SSL/TLSの設定](../../installation/tools.md#tls-certificates)
     - [外部Redisの使用](../external-redis/_index.md)
     - [外部オブジェクトストレージの使用](../external-object-storage/_index.md)
   - 外部データベースの場合、`global.psql.host`はセカンダリの読み取り専用レプリカデータベースであり、`global.geo.psql.host`はGeoトラッキングデータベースです。
   <!-- markdownlint-enable MD044 -->

1. 必要なIngressまたはGateway API設定を`secondary.yaml`に追加します。

   {{< tabs >}}

   {{< tab title="NGINX Ingress" >}}

   オプションで追加のNGINXコントローラーを有効にし、内部Geoトラフィック用の追加のwebservice Ingressを設定します:

   ```yaml
   # Optional for secondary sites: Configure Geo Nginx Controller for internal Geo site traffic.
   # nginx-ingress-geo:
   #   enabled: true
   gitlab:
     webservice:
       # Configure an Ingress for internal Geo traffic
       extraIngress:
         enabled: true
         hostname: shanghai.gitlab.example.com
         useGeoClass: false # Set to true if Geo NGINX Ingress is enabled.
   ```

   {{< /tab >}}

   {{< tab title="Envoy Gateway" >}}

   NGINX Ingressベースのアプローチに代わって、[Gateway APIを設定](../../charts/globals.md#gateway-api)し、バンドルされている[Envoy Gateway](../../charts/envoygateway/_index.md)によってGeoを公開することもできます。

   Gateway APIを有効にした後、内部Geoトラフィックのホスト名を設定します:

   ```yaml
   global:
     geo:
       gatewayApi:
         additionalHostname: shanghai.gitlab.example.com
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. この設定を使用してチャートをデプロイします:

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f secondary.yaml
   ```

1. デプロイが完了し、アプリケーションがオンラインになるまで待ちます。

## プライマリ経由でセカンダリGeoサイトを追加 {#add-secondary-geo-site-via-primary}

両方のデータベースが設定され、アプリケーションがデプロイされたので、プライマリサイトにセカンダリサイトが存在することを伝える必要があります:

1. **プライマリ**サイトにアクセスします。
1. 右上隅で、**管理者**を選択します。
1. **Geo > サイトを追加**を選択します。
1. **セカンダリ**サイトを追加します。URLには完全なGitLabのURLを使用します。
1. セカンダリサイトの`global.geo.nodeName`とともに名前を入力します。これらの値は、常に文字単位で正確に一致する必要があります。
1. 内部URLを入力します。例: `https://shanghai.gitlab.example.com`。
1. オプションで、**セカンダリ**サイトによってレプリケートする必要があるグループまたはストレージシャードを選択します。すべてをレプリケートする場合は空白のままにします。
1. **Add node**を選択します。

**セカンダリ**サイトが管理パネルに追加されると、**プライマリ**サイトから不足しているデータのレプリケートを自動的に開始します。このプロセスは「バックフィル」として知られています。その間、**プライマリ**サイトは各**セカンダリ**サイトに変更を通知し始め、それによって**セカンダリ**サイトはそれらの変更を迅速にレプリケートすることができます。

## 稼働状況を確認 {#confirm-operational-status}

最終ステップは、完全に設定された後、Toolboxポッド経由でセカンダリサイト上のGeo設定を再確認することです。

1. Toolboxポッドを見つけます:

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. `kubectl exec`でポッドにアタッチします:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- bash -l
   ```

1. Geo設定のステータスを確認します:

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   以下のような出力が表示されるはずです:

   ```plaintext
   WARNING: This version of GitLab depends on gitlab-shell 10.2.0, but you're running Unknown. Please update gitlab-shell.
   Checking Geo ...

   GitLab Geo is available ... yes
   GitLab Geo is enabled ... yes
   GitLab Geo secondary database is correctly configured ... yes
   Database replication enabled? ... yes
   Database replication working? ... yes
   GitLab Geo HTTP(S) connectivity ...
   * Can connect to the primary node ... yes
   HTTP/HTTPS repository cloning is enabled ... yes
   Machine clock is synchronized ... Exception: getaddrinfo: Servname not supported for ai_socktype
   Git user has default SSH configuration? ... yes
   OpenSSH configured to use AuthorizedKeysCommand ... no
     Reason:
     Cannot find OpenSSH configuration file at: /assets/sshd_config
     Try fixing it:
     If you are not using our official docker containers,
     make sure you have OpenSSH server installed and configured correctly on this system
     For more information see:
     doc/administration/operations/fast_ssh_key_lookup.md
   GitLab configured to disable writing to authorized_keys file ... yes
   GitLab configured to store new projects in hashed storage? ... yes
   All projects are in hashed storage? ... yes

   Checking Geo ... Finished
   ```

   - `Exception: getaddrinfo: Servname not supported for ai_socktype`については心配しないでください。Kubernetesコンテナはホストクロックにアクセスできないためです。_これは問題ありません_。
   - `OpenSSH configured to use AuthorizedKeysCommand ... no`は_想定内です_。このRakeタスクはローカルSSHサーバーをチェックしていますが、これは実際には`gitlab-shell`チャート内に存在し、別の場所にデプロイ済みで、適切に設定されています。

## セカンダリサイトの個別のURLを設定（オプション） {#configure-a-separate-url-for-the-secondary-site-optional}

プライマリサイトとセカンダリサイトの単一の統合URLは、通常、ユーザーにとってより便利です。たとえば、次のことができます:

- 両方のサイトをロードバランサーの背後に配置します。
- クラウドプロバイダーのDNS機能を使用して、ユーザーを最寄りのサイトにルーティングします。

場合によっては、ユーザーにどのサイトにアクセスするかを制御させたい場合があります。この目的のために、セカンダリGeoサイトが固有の外部URLを使用するように設定できます。例: 

- プライマリクラスターの外部URL: `https://gitlab.example.com`
- セカンダリクラスターの外部URL: `https://shanghai.gitlab.example.com`

1. `secondary.yaml`を編集し、セカンダリクラスターの外部URLを更新して、`webservice`チャートがこれらのリクエストを処理できるようにします:

   ```yaml
   global:
     # See docs.gitlab.com/charts/charts/globals
     # Configure host & domain
     hosts:
       domain: example.com
       # use a unique external URL for the secondary site
       gitlab:
         name: shanghai.gitlab.example.com
   ```

1. セカンダリサイトのGitLabの外部URLを更新して、必要な場所でURLを使用できるようにします:
   - 管理者UIを使用する:
     1. **プライマリ**サイトにアクセスします。
     1. 右上隅で、**管理者**を選択します。
     1. **Geo > サイト**を選択します。
     1. 鉛筆アイコンを選択して**Edit the secondary site**します。
     1. 外部URLを編集します。例: `https://shanghai.gitlab.example.com`。
     1. **変更を保存**を選択します。

1. セカンダリサイトのチャートを再デプロイします:

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f secondary.yaml
   ```

1. デプロイが完了し、アプリケーションがオンラインになるまで待ちます。

## レジストリ {#registry}

セカンダリレジストリをプライマリレジストリと同期するには、[通知シークレット](../../charts/registry/_index.md#notification-secret)を使用して[レジストリレプリケーション](https://docs.gitlab.com/administration/geo/replication/container_registry/#configure-container-registry-replication)を設定できます。

## Cert-managerと統合URL {#cert-manager-and-unified-url}

Geoの統合URLは、ジオロケーション対応ルーティング（例えば、Amazon Route 53やGoogle Cloud DNSの使用）でよく使用されますが、ドメイン名が制御下にあることを検証するために[HTTP01チャレンジ](https://letsencrypt.org/docs/challenge-types/#http-01-challenge)が使用される場合、問題を引き起こす可能性があります。

1つのGeoサイトに対して証明書をリクエストすると、Let's EncryptはDNS名をリクエストしているGeoサイトに解決する必要があります。もしDNSが別のGeoサイトに解決する場合、統合URLの証明書は発行または更新されません。

cert-managerで証明書を確実に作成および更新するには、統合ホスト名をGeoサイトのIPアドレスに解決することが知られているサーバーに[チャレンジネームサーバーを設定](https://cert-manager.io/docs/configuration/acme/http01/#setting-nameservers-for-http-01-solver-propagation-checks)するか、[DNS01](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) [発行者](https://cert-manager.io/docs/configuration/acme/dns01/)を設定します。
