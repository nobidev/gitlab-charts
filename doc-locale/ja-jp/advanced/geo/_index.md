---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab GeoでGitLabチャートを設定する
---

GitLab Geoは、地理的に分散したアプリケーションのデプロイを可能にします。

外部データベースサービスも使用できますが、これらの[ドキュメント](https://docs.gitlab.com/omnibus/)では、PostgreSQL用の[Linux package](https://docs.gitlab.com/omnibus/)を使用して、最も[プラットフォーム](https://docs.gitlab.com/omnibus/)に[依存しない](https://docs.gitlab.com/omnibus/)ガイドを提供し、`gitlab-ctl`に含まれる自動化を利用することに重点を置いています。

このガイドでは、両方のクラスターが同じ外部URLを持ちます。この機能は、チャートのバージョン7.3以降でサポートされています。[Geoサイトの統合URLの設定](https://docs.gitlab.com/administration/geo/secondary_proxy/#set-up-a-unified-url-for-geo-sites)を参照してください。オプションで、[セカンダリサイトに個別のURLを設定](#configure-a-separate-url-for-the-secondary-site-optional)できます。

既知の[イシュー](https://docs.gitlab.com/administration/geo/#known-issues)については、[Geoドキュメント](https://docs.gitlab.com/administration/geo/#known-issues)を参照してください。

{{< alert type="note" >}}

Geoのすべての側面（主に`site`と`node`の区別）を説明する[定義された用語](https://docs.gitlab.com/administration/geo/glossary/)を参照してください。

{{< /alert >}}

## 要件 {#requirements}

GitLab GeoをGitLab Helm Chartで使用するには、次の要件を満たす必要があります。

- [外部PostgreSQL](../external-db/_index.md)サービスの使用。チャートに含まれるPostgresSQLは外部ネットワークに公開されておらず、[レプリケーション](../external-db/_index.md)に必要なWAL[サポート](../external-db/_index.md)がないため。
- 提供されるデータベースは以下をサポートする必要があります。
  - レプリケーションをサポートします。
  - プライマリデータベースは、プライマリサイトおよびすべてのセカンダリデータベースノード（レプリケーション用）から到達可能である必要があります。
  - セカンダリデータベースは、セカンダリサイトからのみ到達可能である必要があります。
  - プライマリデータベースノードとセカンダリデータベースノード間のSSLをサポートします。
- プライマリサイトは、すべてのセカンダリサイトからHTTP(S)経由で到達可能である必要があります。セカンダリサイトは、プライマリサイトからHTTP(S)経由でアクセス可能である必要があります。
- 完全な[要件](https://docs.gitlab.com/administration/geo/#requirements-for-running-geo)リストについては、[Geoの実行要件](https://docs.gitlab.com/administration/geo/#requirements-for-running-geo)を参照してください。

## 概要 {#overview}

このガイドでは、Linuxパッケージを使用して作成された2つのデータベースノードを使用し、必要なPostgreSQLサービスのみを設定し、GitLab Helm Chartの2つのデプロイを使用します。これは、_最小_限必要な_設定_であるように意図されています。このドキュメントには、アプリケーションからデータベースへのSSL、他のデータベースプロバイダーのサポート、または[セカンダリサイトをプライマリにプロモートすること](https://docs.gitlab.com/administration/geo/disaster_recovery/)は含まれていません。

以下の概要は、次の順序で実行する必要があります。

1. [Linuxパッケージデータベースノードを設定](#set-up-linux-package-database-nodes)
1. [Kubernetesクラスターを設定](#set-up-kubernetes-clusters)
1. [情報を収集](#collect-information)
1. [プライマリデータベースを設定](#configure-primary-database)
1. [Geoプライマリサイトとしてチャートをデプロイ](#deploy-chart-as-geo-primary-site)
1. [Geoプライマリサイトを設定](#set-the-geo-primary-site)
1. [セカンダリデータベースを設定](#configure-secondary-database)
1. [プライマリサイトからセカンダリサイトにシークレットをコピー](#copy-secrets-from-the-primary-site-to-the-secondary-site)
1. [Geoセカンダリサイトとしてチャートをデプロイ](#deploy-chart-as-geo-secondary-site)
1. [プライマリ経由でGeoセカンダリサイトを追加](#add-secondary-geo-site-via-primary)
1. [運用状態を確認](#confirm-operational-status)
1. [セカンダリサイトに個別のURLを設定（オプション）](#configure-a-separate-url-for-the-secondary-site-optional)
1. [レジストリ](#registry)
1. [Cert-managerと統合URL](#cert-manager-and-unified-url)

## Linuxパッケージデータベースノードを設定する {#set-up-linux-package-database-nodes}

このプロセスでは、2つのノードが必要です。1つはプライマリデータベースノード、もう1つはセカンダリデータベースノードです。オンプレミスまたはクラウドプロバイダーから、マシンインフラストラクチャの任意のプロバイダーを使用できます。

通信が必要であることに注意してください。

- レプリケーションのための2つのデータベースノード間。
- 各データベースノードとそれぞれのKubernetesデプロイメント間：
  - プライマリは、TCPポート`5432`を公開する必要があります。
  - セカンダリは、TCPポート`5432`および`5431`を公開する必要があります。

[Linuxパッケージでサポートされているオペレーティングシステム](https://docs.gitlab.com/install/requirements/#operating-systems)をインストールし、次に[Linuxパッケージをインストール](https://about.gitlab.com/install/)します。インストール時に`EXTERNAL_URL`環境変数を指定しないでください。これは、パッケージを再設定する前に最小限の設定ファイルを提供するからです。

オペレーティングシステムとGitLabパッケージをインストールしたら、使用するサービスに対して設定を作成できます。その前に、情報を収集する必要があります。

## Kubernetesクラスターを設定する {#set-up-kubernetes-clusters}

このプロセスでは、2つのKubernetesクラスターを使用する必要があります。これらは、オンプレミスまたはクラウドプロバイダーから、任意のプロバイダーからのものでもかまいません。

通信が必要であることに注意してください。

- それぞれのデータベースノードへ：
  - プライマリはTCP `5432`へ送信します。
  - セカンダリはTCP `5432`と`5431`へ送信します。
- HTTPS経由の両方のKubernetes Ingress間。

プロビジョニングされる各クラスターには、次のものが必要です。

- これらのチャートのベースラインインストールをサポートするのに十分なリソース。
- 永続ストレージへのアクセス：
  - [外部オブジェクトストレージ](../external-object-storage/_index.md)を使用している場合、MinIOは不要です。
  - [外部Gitaly](../external-gitaly/_index.md)を使用している場合、Gitalyは不要です。
  - [外部Redis](../external-redis/_index.md)を使用している場合、Redisは不要です。

## 情報を収集する {#collect-information}

設定を続行するには、さまざまなソースから次の情報を収集する必要があります。これらを収集し、このドキュメントの残りの部分で使用するためのノートを作成します。

- プライマリデータベース：
  - IPアドレス
  - ホスト名（オプション）
- セカンダリデータベース：
  - IPアドレス
  - ホスト名（オプション）
- プライマリ クラスター：
  - 外部URL
  - 内部URL
  - ノードのIPアドレス
- セカンダリ クラスター：
  - 内部URL
  - ノードのIPアドレス
- データベースパスワード（_パスワードを事前に決定する必要があります_）：
  - `gitlab` （`postgresql['sql_user_password']`、`global.psql.password`で使用）
  - `gitlab_geo` （`geo_postgresql['sql_user_password']`、`global.geo.psql.password`で使用）
  - `gitlab_replicator` （レプリケーションに必要）
- GitLabライセンスファイル

各クラスターの内部URLは、クラスターに固有である必要があります。これにより、すべてのクラスターが他のすべてのクラスターにリクエストを送信できるようになります。次に例を示します。

- すべてのクラスターの外部URL：`https://gitlab.example.com`
- プライマリ クラスターの内部URL：`https://london.gitlab.example.com`
- セカンダリ クラスターの内部URL：`https://shanghai.gitlab.example.com`

このガイドでは、DNSの設定については説明しません。

`gitlab`および`gitlab_geo`データベースユーザーパスワードは、ベアパスワードとPostgreSQLハッシュパスワードの2つの形式で存在する必要があります。ハッシュ形式を取得するには、Linuxパッケージインストールインスタンスの1つで次のコマンドを実行します。これにより、パスワードを入力して確認するように求められた後、適切なハッシュ値が出力され、ノートを作成できます。

1. `gitlab-ctl pg-password-md5 gitlab`
1. `gitlab-ctl pg-password-md5 gitlab_geo`

## プライマリデータベースを設定 {#configure-primary-database}

_このセクションは、プライマリLinuxパッケージインストールデータベースノードで実行されます。_

プライマリデータベースノードのLinuxパッケージインストールを設定するには、この設定例から作業します。

```ruby
### Geo Primary
external_url 'http://gitlab.example.com'
roles ['geo_primary_role']
# The unique identifier for the Geo node.
gitlab_rails['geo_node_name'] = 'London Office'
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

いくつかのアイテムを置き換える必要があります。

- `external_url`は、プライマリサイトのホスト名を反映するように更新する必要があります。
- `gitlab_rails['geo_node_name']`は、サイトの一意の名前に置き換える必要があります。[共通設定](https://docs.gitlab.com/administration/geo_sites/#common-settings)の名前フィールドを参照してください。
- `gitlab_user_password_hash`は、`gitlab`パスワードのハッシュ形式に置き換える必要があります。
- `postgresql['md5_auth_cidr_addresses']`は、明示的なIPアドレスのリスト、またはCIDR表記のアドレスブロックになるように更新できます。

`md5_auth_cidr_addresses`は`[ '127.0.0.1/24', '10.41.0.0/16']`の形式である必要があります。Linuxパッケージの自動化がこれを使用して接続するため、このリストに`127.0.0.1`を含めることが重要です。このリストのアドレスには、セカンダリデータベースのIPアドレス（ホスト名ではない）と、プライマリKubernetesクラスターのすべてのノードを含める必要があります。これは`['0.0.0.0/0']`のままにすることも_できます_が、_ベストプラクティスではありません_。

上記の設定が準備されたら：

1. コンテンツを`/etc/gitlab/gitlab.rb`に配置します
1. `gitlab-ctl reconfigure`を実行します。TCPでサービスがリッスンしていないことに関してイシューが発生した場合は、`gitlab-ctl restart postgresql`を使用して直接再起動してみてください。
1. `gitlab-ctl set-replication-password`を実行して、`gitlab_replicator`ユーザーのパスワードを設定します。
1. プライマリデータベースノードの公開証明書を取得します。これは、セカンダリデータベースがレプリケートできるようにするために必要です（この出力を保存します）。

   ```shell
   cat ~gitlab-psql/data/server.crt
   ```

## Geoプライマリサイトとしてチャートをデプロイする {#deploy-chart-as-geo-primary-site}

_このセクションは、プライマリサイトのKubernetesクラスターで実行されます。_

この[チャート](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml)をGeo[プライマリ](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml)として[デプロイ](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml)するには、[この設定例から開始](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml)します。

1. チャートが使用するデータベースパスワードを含むシークレットを作成します。次の`PASSWORD`を`gitlab`データベースユーザーのパスワードに置き換えます。

   ```shell
   kubectl --namespace gitlab create secret generic geo --from-literal=postgresql-password=PASSWORD
   ```

1. [設定例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml)に基づいて`primary.yaml`ファイルを作成し、正しい値を反映するように設定を更新します。

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
   # configure Geo Nginx Controller for internal Geo site traffic
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
   # External DB, disable
   postgresql:
     install: false
   ```

   <!-- markdownlint-disable MD044 -->
   - [`global.hosts.domain`](../../charts/globals.md#configure-host-settings)
   - [`global.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - `global.geo.nodeName`は[管理者エリアのGeoサイトの名前フィールド](https://docs.gitlab.com/administration/geo_sites/#common-settings)と一致する必要があります
   - セカンダリから転送されたGeoトラフィックの[Ingress](../../charts/nginx/_index.md#gitlab-geo) [コントローラー](../../charts/nginx/_index.md#gitlab-geo)を有効にするには、[`nginx-ingress-geo.enabled`](../../charts/nginx/_index.md#gitlab-geo)を設定します。
   - Geoトラフィック用に、[プライマリ](../../charts/gitlab/webservice/_index.md#ingress-settings)Geoサイトの[`gitlab.webservice`](../../charts/gitlab/webservice/_index.md#ingress-settings) [Ingress](../../charts/gitlab/webservice/_index.md#ingress-settings)を[設定](../../charts/gitlab/webservice/_index.md#ingress-settings)します。
   - また、次のような追加の設定も設定します。
     - [SSL/TLSの設定](../../installation/tools.md#tls-certificates)
     - [外部Redisの使用](../external-redis/_index.md)
     - [外部オブジェクトストレージの使用](../external-object-storage/_index.md)
   <!-- markdownlint-enable MD044 -->

1. この設定を使用してチャートをデプロイします。

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f primary.yaml
   ```

   {{< alert type="note" >}}

   これは、`gitlab`名前空間を使用していることを前提としています。別の名前空間を使用する場合は、このドキュメントの残りの部分全体で`--namespace gitlab`でも置き換える必要があります。

   {{< /alert >}}

1. デプロイが完了し、アプリケーションがオンラインになるまで待ちます。アプリケーションに到達できるようになったら、ログインします。

1. GitLabに[サイン](https://docs.gitlab.com/administration/license/)インし、[GitLabサブスクリプションをアクティブ化](https://docs.gitlab.com/administration/license/)します。

   {{< alert type="note" >}}

   このステップは、Geoが機能するために必要です。

   {{< /alert >}}

## Geoプライマリサイトを設定する {#set-the-geo-primary-site}

チャートがデプロイされ、ライセンスがアップロードされたので、これをプライマリサイトとして設定できます。これは、Toolbox Podを介して行います。

1. Toolbox Podを検索

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. `kubectl exec`で`gitlab-rake geo:set_primary_node`を実行します：

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake geo:set_primary_node
   ```

1. Rails runnerコマンドを使用して、プライマリサイトの内部URLを設定します。`https://primary.gitlab.example.com`を実際の内部URLに置き換えます：

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rails runner "GeoNode.primary_node.update!(internal_url: 'https://primary.gitlab.example.com')"
   ```

1. Geo設定の状態をチェックします。

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake gitlab:geo:check
   ```

   以下のような出力が表示されるはずです。

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

   - Kubernetesコンテナはホストクロックにアクセスできないため、`Exception: getaddrinfo: Servname not supported for ai_socktype`を心配しないでください。これは_OK_です。
   - `OpenSSH configured to use AuthorizedKeysCommand ... no`は_想定_されています。このRakeタスクはローカルSSHサーバーをチェックしていますが、実際には`gitlab-shell`チャートに存在し、別の場所にデプロイされ、すでに適切に設定されています。

## セカンダリデータベースを設定 {#configure-secondary-database}

_このセクションは、セカンダリLinuxパッケージインストールデータベースノードで実行されます。_

セカンダリデータベースノードのLinuxパッケージインストールを設定するには、この設定例から作業します。

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

いくつかのアイテムを置き換える必要があります。

- `gitlab_rails['geo_node_name']`は、サイトの一意の名前に置き換える必要があります。[共通設定](https://docs.gitlab.com/administration/geo_sites/#common-settings)の名前フィールドを参照してください。
- `gitlab_user_password_hash`は、`gitlab`パスワードのハッシュ形式に置き換える必要があります。
- `postgresql['md5_auth_cidr_addresses']`は、明示的なIPアドレスのリスト、またはCIDR表記のアドレスブロックになるように更新する必要があります。
- `gitlab_geo_user_password_hash`は、`gitlab_geo`パスワードのハッシュ形式に置き換える必要があります。
- `geo_postgresql['md5_auth_cidr_addresses']`は、明示的なIPアドレスのリスト、またはCIDR表記のアドレスブロックになるように更新する必要があります。
- `gitlab_user_password`は更新する必要があり、LinuxがPostgreSQLのを自動化できるようにするためにここで使用されます。

`md5_auth_cidr_addresses`は、`[ '127.0.0.1/24', '10.41.0.0/16']`の形式にする必要があります。Linuxの自動化がこれを使用して接続するため、このリストに`127.0.0.1`を含めることが重要です。このリストのアドレスには、セカンダリKubernetesのすべてのノードのIPアドレスを含める必要があります。この_は_`['0.0.0.0/0']`のままにすることもできますが、_ベストプラクティスではありません_。

上記のを作成した後:

1. **プライマリ**サイトのPostgreSQLノードへのTCPを確認します。

   ```shell
   openssl s_client -connect <primary_node_ip>:5432 </dev/null
   ```

   出力は次のようになります。

   ```plaintext
   CONNECTED(00000003)
   write:errno=0
   ```

   {{< alert type="note" >}}

   この手順が失敗した場合は、間違ったIPアドレスを使用しているか、ファイアウォールがサーバーへのアクセスをしている可能性があります。IPアドレスを確認し、パブリックアドレスとプライベートアドレスの違いに注意し、ファイアウォールが存在する場合は、**セカンダリ**PostgreSQLノードがTCP5432で**プライマリ**PostgreSQLノードにできることを確認してください。

   {{< /alert >}}

1. `/etc/gitlab/gitlab.rb`にコンテンツを配置します
1. `gitlab-ctl reconfigure`を実行します。サービスがTCPでリッスンしていないことに関して問題が発生した場合は、`gitlab-ctl restart postgresql`で直接再起動してみてください。
1. 上記のプライマリPostgreSQLノードの証明書の内容を`primary.crt`に配置します
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

   PostgreSQLは、TLSを検証する際に、その正確な証明書のみを認識するようになります。証明書は、プライベートキーへのアクセス権を持つユーザーのみができます。これは、**プライマリ** PostgreSQLノードに**のみ**存在します。

1. `gitlab-psql`ユーザーが**プライマリ**サイトのPostgreSQLにできることをテストします（デフォルトのLinuxデータベース名は`gitlabhq_production`です）。

   ```shell
   sudo \
      -u gitlab-psql /opt/gitlab/embedded/bin/psql \
      --list \
      -U gitlab_replicator \
      -d "dbname=gitlabhq_production sslmode=verify-ca" \
      -W \
      -h <primary_database_node_ip>
   ```

   `gitlab_replicator`ユーザーに対して収集されたパスワードを入力するように求められたら、パスワードを入力します。すべてが正しく機能していれば、**プライマリ** PostgreSQLノードのデータベースのリストが表示されます。

   ここへのの失敗は、TLSが正しくないことを示しています。**プライマリ** PostgreSQLノードの`~gitlab-psql/data/server.crt`の内容が、**セカンダリ** PostgreSQLノードの`~gitlab-psql/.postgresql/root.crt`の内容と一致していることを確認します。

1. データベースをします。`PRIMARY_DATABASE_HOST`をプライマリPostgreSQLノードのIPまたはホスト名に置き換えます:

   ```shell
   gitlab-ctl replicate-geo-database --slot-name=geo_2 --host=PRIMARY_DATABASE_HOST --sslmode=verify-ca
   ```

1. が完了したら、Linuxをもう一度再して、セカンダリPostgreSQLノードの`pg_hba.conf`が正しいことを確認する必要があります:

   ```shell
   gitlab-ctl reconfigure
   ```

## サイトからサイトにをコピーします {#copy-secrets-from-the-primary-site-to-the-secondary-site}

サイトのKubernetesからサイトのKubernetesにいくつかのをコピーします。

- `gitlab-geo-gitlab-shell-host-keys`
- `gitlab-geo-rails-secret`
- `gitlab-geo-registry-secret`（のが有効な場合）。

1. `kubectl`コンテキストをプライマリのコンテキストに変更します。
1. からこれらのを収集します。

   ```shell
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-gitlab-shell-host-keys > ssh-host-keys.yaml
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-rails-secret > rails-secrets.yaml
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-registry-secret > registry-secrets.yaml
   ```

1. `kubectl`コンテキストをセカンダリのコンテキストに変更します。
1. これらのを適用します。

   ```shell
   kubectl --namespace gitlab apply -f ssh-host-keys.yaml
   kubectl --namespace gitlab apply -f rails-secrets.yaml
   kubectl --namespace gitlab apply -f registry-secrets.yaml
   ```

次に、データベースパスワードを含むを作成します。以下のパスワードを適切なに置き換えます。

```shell
kubectl --namespace gitlab create secret generic geo \
   --from-literal=postgresql-password=gitlab_user_password \
   --from-literal=geo-postgresql-password=gitlab_geo_user_password
```

## セカンダリサイトとしてをします {#deploy-chart-as-geo-secondary-site}

_このセクションは、セカンダリサイトのKubernetesで実行されます。_

このをセカンダリサイトとしてするには、[この例から開始します](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/secondary.yaml)。

1. [の例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/secondary.yaml)に基づいて`secondary.yaml`ファイルを作成し、正しいを反映するようにを更新します:

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
   # Optional for secondary sites: Configure Geo Nginx Controller for internal Geo site traffic.
   # nginx-ingress-geo:
   #   enabled: true
   gitlab:
     webservice:
       # Configure a Ingress for internal Geo traffic
       extraIngress:
         enabled: true
         hostname: shanghai.gitlab.example.com
   # External DB, disable
   postgresql:
     install: false
   ```

   <!-- markdownlint-disable MD044 -->
   - [`global.hosts.domain`](../../charts/globals.md#configure-host-settings)
   - [`global.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - [`global.geo.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - `global.geo.nodeName`は[管理者エリアのサイトの[名前]フィールド](https://docs.gitlab.com/administration/geo_sites/#common-settings)と一致する必要があります
   - `nginx-ingress-geo.enabled`を設定して、内部トラフィック用に事前にされた を有効にすることもできます。[これにより、サイトをプライマリにすることが容易になります](../../charts/nginx/_index.md#gitlab-geo)。
   - [gitlab.webservice](../../charts/gitlab/webservice/_index.md#ingress-settings)の追加の をして、セカンダリサイトの内部URLに送信されるトラフィックを処理します。
   - その他の追加もします。次に例を示します。
     - [SSL/TLSの](../../installation/tools.md#tls-certificates)
     - [外部Redisの使用](../external-redis/_index.md)
     - [外部オブジェクトストレージの使用](../external-object-storage/_index.md)
   - 外部データベースの場合、`global.psql.host`はセカンダリの読み取り専用データベースであり、`global.geo.psql.host`は のトラッキングデータベースです
   <!-- markdownlint-enable MD044 -->

1. このを使用してをします:

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f secondary.yaml
   ```

1. が完了し、アプリケーションがオンラインになるまで待ちます。

## 経由でセカンダリサイトを追加します {#add-secondary-geo-site-via-primary}

両方のデータベースがされ、アプリケーションがされたので、サイトにサイトが存在することを伝える必要があります:

1. **プライマリ**サイトにアクセスします。
1. 左側のサイドバーの一番下にある**管理者エリア**を選択します。
1. **サイトを追加**を選択します。
1. **セカンダリ**サイトを追加します。URLには完全なGitLab URLを使用します。
1. セカンダリサイトの`global.geo.nodeName`を持つ名前を入力します。これらのは常に文字どおり完全に一致する必要があります。
1. 内部URL（例：`https://shanghai.gitlab.example.com`）を入力します。
1. オプションで、**セカンダリ**サイトでするグループまたはストレージを選択します。すべてをするには、空白のままにします。
1. **ノードを追加**を選択します。

**セカンダリ**サイトが管理パネルに追加されると、**プライマリ**サイトからの不足しているデータのが自動的に開始されます。このプロセスは「埋め戻し」と呼ばれます。その間、**プライマリ**サイトは各**セカンダリ**サイトに変更を通知し始め、**セカンダリ**サイトはそれらの変更を迅速にできます。

## 稼働を確認します {#confirm-operational-status}

最後の手順は、完全にされたら、Toolboxを介してセカンダリサイトの を再確認することです。

1. Toolboxを検索します:

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. `kubectl exec`を使用してにアタッチします:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- bash -l
   ```

1. のを確認します:

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   出力は次のようになります。

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

   - Kubernetesコンテナはホストクロックにアクセスできないため、`Exception: getaddrinfo: Servname not supported for ai_socktype`を心配しないでください。_これはOK_です。
   - `OpenSSH configured to use AuthorizedKeysCommand ... no`_が想定されます_。このはローカルサーバーをチェックしていますが、これは実際には`gitlab-shell`に存在し、別の場所にされ、すでに適切にされています。

## サイトの別のURLをします（オプション） {#configure-a-separate-url-for-the-secondary-site-optional}

サイトとサイトの単一の統合URLは、通常、ユーザーにとってより便利です。たとえば、次のことができます。

- 両方のサイトをの背後に配置します。
- クラウドプロバイダーのを使用して、ユーザーを最寄りのサイトにルーティングします。

場合によっては、ユーザーにアクセスするサイトを制御させたいことがあります。このために、 サイトをして、一意の外部URLを使用できます。次に例を示します。

- の外部URL：`https://gitlab.example.com`
- の外部URL：`https://shanghai.gitlab.example.com`

1. `secondary.yaml`を編集し、`webservice`がこれらのを処理できるように、セカンダリの外部URLを更新します。

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

1. GitLabでセカンダリサイトの外部URLを更新して、必要な場所でURLを使用できるようにします。
   - 管理者の使用:
     1. **プライマリ**サイトにアクセスします。
     1. 左側のサイドバーの一番下にある**管理者エリア**を選択します。
     1. **サイト**を選択します。
     1. 鉛筆を選択して、**セカンダリサイトを編集**します。
     1. 外部URL（例：`https://shanghai.gitlab.example.com`）を編集します。
     1. **変更の保存**を選択します。

1. セカンダリサイトのを再します:

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f secondary.yaml
   ```

1. が完了し、アプリケーションがオンラインになるまで待ちます。

## {#registry}

セカンダリ[レジストリ](https://docs.gitlab.com/administration/geo/replication/container_registry/#configure-container-registry-replication)をプライマリ[レジストリ](https://docs.gitlab.com/administration/geo/replication/container_registry/#configure-container-registry-replication)と[同期](../../charts/registry/_index.md#notification-secret)するには、[レジストリ](https://docs.gitlab.com/administration/geo/replication/container_registry/#configure-container-registry-replication)の[レプリケーション](https://docs.gitlab.com/administration/geo/replication/container_registry/#configure-container-registry-replication)を[通知シークレット](../../charts/registry/_index.md#notification-secret)を使用して[設定](https://docs.gitlab.com/administration/geo/replication/container_registry/#configure-container-registry-replication)できます。

## Cert-managerと統合URL {#cert-manager-and-unified-url}

の統合URLは、位置情報認識ルーティング（たとえば、Amazon Route 53またはGoogle Cloudの使用）でよく使用されます。これにより、ドメイン名が管理下にあることをするために[HTTP01](https://letsencrypt.org/docs/challenge-types/#http-01-challenge)が使用されている場合に問題が発生する可能性があります。

1つのサイトの証明書をすると、Let'sは名をしているサイトにする必要があります。が別のサイトにされる場合、統合URLの証明書は発行またはされません。

cert-managerで証明書を確実に作成および[更新](https://cert-manager.io/docs/configuration/acme/http01/#setting-nameservers-for-http-01-solver-propagation-checks)するには、統合ホスト名を[Geo](https://cert-manager.io/docs/configuration/acme/http01/#setting-nameservers-for-http-01-solver-propagation-checks)サイトのアドレスに[解決](https://cert-manager.io/docs/configuration/acme/http01/#setting-nameservers-for-http-01-solver-propagation-checks)することがわかっているサーバーに[Challenge](https://cert-manager.io/docs/configuration/acme/http01/#setting-nameservers-for-http-01-solver-propagation-checks) [ネームサーバー](https://cert-manager.io/docs/configuration/acme/http01/#setting-nameservers-for-http-01-solver-propagation-checks)を[設定](https://cert-manager.io/docs/configuration/acme/http01/#setting-nameservers-for-http-01-solver-propagation-checks)するか、[DNS01](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) [Issuer](https://cert-manager.io/docs/configuration/acme/dns01/)を[設定](https://cert-manager.io/docs/configuration/acme/http01/#setting-nameservers-for-http-01-solver-propagation-checks)します。
