---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: オブジェクトストレージに組み込みのMinIOサービスを使用します
---

{{< details >}}

- プラン:Free, Premium, Ultimateプラン
- 提供:GitLab Self-Managed

{{< /details >}}

この移行ガイドは、[パッケージベースのインストール](package_to_helm.md)からHelm Chartに移行し、オブジェクトストレージに組み込みのMinIOサービスを使用する場合を対象としています。これはテスト目的により適しています。本番環境で使用する場合は、[外部オブジェクトストレージ](../../advanced/external-object-storage/_index.md)をセットアップすることをお勧めします。

組み込みのMinIOクラスターへのアクセス詳細を把握する最も簡単な方法は、Sidekiq、Webservice、Toolboxポッドで生成される`gitlab.yml`ファイルを確認することです。

Sidekiqポッドから取得するには:

1. Sidekiqポッドの名前を調べます:

   ```shell
   kubectl get pods -lapp=sidekiq
   ```

1. Sidekiqポッドから`gitlab.yml`ファイルを取得します:

   ```shell
   kubectl exec <sidekiq pod name> -- cat /srv/gitlab/config/gitlab.yml
   ```

1. `gitlab.yml`ファイルには、オブジェクトストレージ接続の詳細を含むアップロードのセクションがあります。以下のようなものです:

   ```yaml
   uploads:
     enabled: true
     object_store:
     enabled: true
     remote_directory: gitlab-uploads
     proxy_download: true
     connection:
       provider: AWS
       region: <S3 region>
       aws_access_key_id: "<access key>"
       aws_secret_access_key: "<secret access key>"
       host: <Minio host>
       endpoint: <Minio endpoint>
       path_style: true
   ```

1. この情報を使用して、パッケージベースのデプロイの`/etc/gitlab/gitlab.rb`ファイルで[オブジェクトストレージを設定](https://docs.gitlab.com/administration/uploads/#s3-compatible-connection-settings)します。

   {{< alert type="note" >}}

クラスターの外部からMinIOサービスに接続する場合、MinIOホストURLだけで十分です。Helm Chartベースのインストールは、そのURLへのリクエストを対応するエンドポイントに自動的にリダイレクトするように構成されています。そのため、`/etc/gitlab/gitlab.rb`の接続設定で`endpoint`値を設定する必要はありません。

{{< /alert >}}
