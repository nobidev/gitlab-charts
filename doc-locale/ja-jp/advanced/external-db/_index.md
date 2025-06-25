---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部データベースでGitLabチャートを設定する
---

{{< alert type="warning" >}}

バンドルされているbitnami PostgreSQLチャートは、本番環境に対応していません。本番環境に対応したGitLabチャートのデプロイには、外部データベースを使用してください。

{{< /alert >}}

前提要件:

- [必要なバージョンのPostgreSQL](https://docs.gitlab.com/install/requirements/#postgresql)のデプロイ。お持ちでない場合は、[AWS RDS PostgreSQL](https://aws.amazon.com/rds/postgresql/)や[GCP Cloud SQL](https://cloud.google.com/sql/)のようなクラウドで提供されるソリューションをご検討ください。代替ソリューションとしては、[Linux Package](external-omnibus-psql.md)をご検討ください。
- デフォルトでは`gitlabhq_production`という名前の空のデータベース。
- データベースへのフルアクセス権を持つユーザー。詳細については、[外部データベースのドキュメント](https://docs.gitlab.com/administration/postgresql/external/)を参照してください。
- データベースユーザーのパスワードを持つ[Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/)。
- [`pg_trgm`および`btree_gist` extension](https://docs.gitlab.com/install/postgresql_extensions/)。GitLabにSuperuserフラグを持つアカウントを提供しない場合は、データベースのインストールに進む前に、これらのextensionが読み込むことを確認してください。

ネットワーキングの前提要件:

- データベースがクラスターから到達可能であることを確認してください。ファイアウォールPoliciesがトラフィックを許可していることを確認してください。
- PostgreSQLをロードバランシングクラスターとして使用し、Kubernetes DNSをサービスディスカバリに使用する場合は、`bitnami/postgresql`チャートのインストール時に`--set slave.service.clusterIP=None`を使用します。このSettingsは、PostgreSQLセカンダリinstanceごとにDNS `A`レコードを作成できるように、PostgreSQLセカンダリサービスをヘッドレスサービスとしてConfigureします。

  [Kubernetes](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/database/values-loadbalancing-discover.yaml) DNSをサービスディスカバリに使用する方法の例については、[`examples/database/values-loadbalancing-discover.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/database/values-loadbalancing-discover.yaml)を参照してください。

外部データベースを使用するようにGitLabチャートをConfigureするには:

1. 次のパラメータを設定します:

   - `postgresql.install`:`false`に設定して、埋め込みデータベースを無効にします。
   - `global.psql.host`:外部データベースのホスト名に設定します。ドメインまたはIPアドレスを指定できます。
   - `global.psql.password.secret`:`gitlab`ユーザーのデータベースパスワードを含む[シークレット](../../installation/secrets.md#postgresql-password)の名前。
   - `global.psql.password.key`:シークレット内で、パスワードを含むキー。

1. 任意。デフォルトを使用していない場合は、次の項目をさらにカスタマイズできます:

   - `global.psql.port`:データベースが利用可能なポート。デフォルトは`5432`です。
   - `global.psql.database`:データベースの名前。
   - `global.psql.username`:データベースへのアクセス権を持つユーザー。

1. 任意。相互TLSConnectionをデータベースに使用する場合は、以下を設定します:

   - `global.psql.ssl.secret`:クライアント証明書、キー、およびcertificate authorityを含むシークレット。
   - `global.psql.ssl.serverCA`:シークレット内で、certificate authority (CA) を参照するキー。
   - `global.psql.ssl.clientCertificate`:シークレット内で、クライアント証明書を参照するキー。
   - `global.psql.ssl.clientKey`:シークレットのクライアント。

1. GitLabチャートをデプロイするときは、`--set`フラグを使用して値を追加します。例:

   ```shell
   helm install gitlab gitlab/gitlab
     --set postgresql.install=false
     --set global.psql.host=psql.example
     --set global.psql.password.secret=gitlab-postgresql-password
     --set global.psql.password.key=postgres-password
   ```
