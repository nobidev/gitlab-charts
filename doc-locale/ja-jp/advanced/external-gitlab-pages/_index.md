---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部GitLab PagesでGitLabチャートを設定する
---

このドキュメントでは、Linuxパッケージを使用して、クラスターの外部で設定されたGitLab PagesインスタンスでこのHelmチャートを設定する方法について説明します。[イシュー418259](https://gitlab.com/gitlab-org/gitlab/-/issues/418259)は、Helm Chartを使用して外部GitLab Pagesを持つLinuxパッケージ インスタンスのドキュメントを追加することを提案しています。

## 要件 {#requirements}

1. [外部オブジェクトストレージ](../external-object-storage/_index.md)は、本番環境インスタンスに推奨されるため、使用する必要があります。
1. GitLab Pagesとやり取りするための、Pages用の32バイト長のAPIシークレットキーのBase64エンコード形式。

## 既知の制限事項 {#known-limitations}

1. [GitLab Pagesアクセス制御](https://docs.gitlab.com/user/project/pages/pages_access_control/)は、デフォルトではサポートされていません。

## 外部GitLab Pagesインスタンスを設定する {#configure-external-gitlab-pages-instance}

1. Linuxパッケージを使用して[GitLabをインストール](https://about.gitlab.com/install/)します。

1. `/etc/gitlab/gitlab.rb`ファイルを編集し、その内容を次のスニペットに置き換えます。構成に合わせて以下の値を更新します。

   ```ruby
   roles ['pages_role']

   # Root domain where Pages will be served.
   pages_external_url '<Pages root domain>'  # Example: 'http://pages.example.io'

   # Information regarding GitLab instance
   gitlab_pages['gitlab_server'] = '<GitLab URL>'  # Example: 'https://gitlab.example.com'
   gitlab_pages['api_secret_key'] = '<Base64 encoded form of API secret key>'
   ```

1. `sudo gitlab-ctl reconfigure`を実行して変更を適用します。

## チャートを設定する {#configure-the-chart}

1. Pagesデプロイメントを格納するために、オブジェクトストレージに`gitlab-pages`という名前のバケットを作成します。

1. APIシークレットキーのBase64エンコード形式を値として持つシークレット`gitlab-pages-api-key`を作成します。

   ```shell
   kubectl create secret generic gitlab-pages-api-key --from-literal="shared_secret=<Base 64 encoded API Secret Key>"
   ```

1. 次の構成スニペットを参照して、必要なエントリをvaluesファイルに追加します。

   ```yaml
   global:
     pages:
       path: '/srv/gitlab/shared/pages'
       host: <Pages root domain>
       port: '80'  # Set to 443 if Pages is served over HTTPS
       https: false  # Set to true if Pages is served over HTTPS
       artifactsServer: true
       objectStore:
         enabled: true
         bucket: 'gitlab-pages'
       apiSecret:
         secret: gitlab-pages-api-key
         key: shared_secret
     extraEnv:
       PAGES_UPDATE_LEGACY_STORAGE: true  # Bypass automatic disabling of disk storage
   ```

   {{< alert type="note" >}}

`PAGES_UPDATE_LEGACY_STORAGE`環境変数をtrueに設定すると、機能フラグ`pages_update_legacy_storage`が有効になり、Pagesがローカルディスクにデプロイされます。オブジェクトストレージに移行する際は、この変数を削除することを忘れないでください。

   {{< /alert >}}

1. この構成を使用して[チャートをデプロイ](../../installation/deployment.md#deploy-using-helm)します。
