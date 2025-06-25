---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートを使用する際のAzure MinIOゲートウェイ
---

[MinIO](https://min.io/)は、S3互換のAPIを公開するオブジェクトストレージサーバーであり、Azure Blob Storageへのリクエストをプロキシできるゲートウェイ機能を備えています。ゲートウェイを設定するには、Linux上のAzure Webアプリを使用します。

開始するには、Azureコマンドラインインターフェース（CLI） がインストールされ、ログインしていることを確認してください(`az login`)。[リソースグループ](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/overview#resource-groups)を作成してください(まだない場合)。

```shell
az group create --name "gitlab-azure-minio" --location "WestUS"
```

## ストレージアカウント {#storage-account}

リソースグループにストレージアカウントを作成します。ストレージアカウントの名前はグローバルに一意である必要があります。

```shell
az storage account create \
    --name "gitlab-azure-minio-storage" \
    --kind BlobStorage \
    --sku Standard_LRS \
    --access-tier Cool \
    --resource-group "gitlab-azure-minio" \
    --location "WestUS"
```

ストレージアカウントのアカウントキーを取得します。

```shell
az storage account show-connection-string \
    --name "gitlab-azure-minio-storage" \
    --resource-group "gitlab-azure-minio"
```

出力は次の形式である必要があります。

```json
{
    "connectionString": "DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=gitlab-azure-minio-storage;AccountKey=h0tSyeTebs+..."
}
```

## Linux上のWebアプリへのMinIOのデプロイ {#deploy-minio-to-web-app-on-linux}

まず、同じリソースグループにApp Serviceプランを作成する必要があります。

```shell
az appservice plan create \
    --name "gitlab-azure-minio-app-plan" \
    --is-linux \
    --sku B1 \
    --resource-group "gitlab-azure-minio" \
    --location "WestUS"
```

[`minio/minio`](https://hub.docker.com/r/minio/minio) Dockerコンテナで構成されたWebアプリを作成します。指定する名前はWebアプリのURLで使用されます。

```shell
az webapp create \
    --name "gitlab-minio-app" \
    --deployment-container-image-name "minio/minio" \
    --plan "gitlab-azure-minio-app-plan" \
    --resource-group "gitlab-azure-minio"
```

これで、Webアプリに`https://gitlab-minio-app.azurewebsites.net`でアクセスできるようになります。

最後に、スタートアップコマンドを設定し、Webアプリで使用するためにストレージアカウント名とキーを格納する環境変数`MINIO_ACCESS_KEY`と`MINIO_SECRET_KEY`を作成する必要があります。

```shell
az webapp config appsettings set \
    --settings "MINIO_ACCESS_KEY=gitlab-azure-minio-storage" "MINIO_SECRET_KEY=h0tSyeTebs+..." "PORT=9000" \
    --name "gitlab-minio-app" \
    --resource-group "gitlab-azure-minio"

# Startup command
az webapp config set \
    --startup-file "gateway azure" \
    --name "gitlab-minio-app" \
    --resource-group "gitlab-azure-minio"
```

## 結論 {#conclusion}

s3互換性のある任意のクライアントでこのゲートウェイを引き続き使用できます。WebアプリケーションURLは`s3 endpoint`、ストレージアカウント名は`accesskey`、ストレージアカウントキーは`secretkey`になります。

## 参照 {#reference}

<!-- vale gitlab.Spelling = NO -->

このガイドは、[同じトピックに関するAlessandro Segalaのブログ投稿](https://withblue.ink/2017/10/29/how-to-use-s3cmd-and-any-other-amazon-s3-compatible-app-with-azure-blob-storage.html)から後世のために翻案されました。

<!-- vale gitlab.Spelling = YES -->
