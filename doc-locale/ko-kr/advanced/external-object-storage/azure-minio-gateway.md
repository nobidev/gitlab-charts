---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트 사용 시 Azure MinIO 게이트웨이
---

[MinIO](https://min.io/)는 S3 호환 API를 노출하는 객체 스토리지 서버이며, Azure Blob Storage에 대한 요청을 프록시할 수 있는 게이트웨이 기능을 가지고 있습니다. 게이트웨이를 설정하기 위해 Azure의 Linux용 Web App을 사용할 것입니다.

시작하기 전에 Azure CLI를 설치했고 로그인(`az login`)했는지 확인하세요. 아직 리소스 그룹이 없다면 [리소스 그룹](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/overview#resource-groups)을 생성하세요:

```shell
az group create --name "gitlab-azure-minio" --location "WestUS"
```

## 스토리지 계정 {#storage-account}

리소스 그룹에 스토리지 계정을 생성합니다. 스토리지 계정의 이름은 전역적으로 고유해야 합니다:

```shell
az storage account create \
    --name "gitlab-azure-minio-storage" \
    --kind BlobStorage \
    --sku Standard_LRS \
    --access-tier Cool \
    --resource-group "gitlab-azure-minio" \
    --location "WestUS"
```

스토리지 계정의 계정 키를 검색합니다:

```shell
az storage account show-connection-string \
    --name "gitlab-azure-minio-storage" \
    --resource-group "gitlab-azure-minio"
```

출력은 다음 형식이어야 합니다:

```json
{
    "connectionString": "DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=gitlab-azure-minio-storage;AccountKey=h0tSyeTebs+..."
}
```

## Linux용 Web App에 MinIO 배포 {#deploy-minio-to-web-app-on-linux}

먼저 동일한 리소스 그룹에 App Service Plan을 생성해야 합니다.

```shell
az appservice plan create \
    --name "gitlab-azure-minio-app-plan" \
    --is-linux \
    --sku B1 \
    --resource-group "gitlab-azure-minio" \
    --location "WestUS"
```

[`minio/minio`](https://hub.docker.com/r/minio/minio) Docker 컨테이너로 구성된 Web app을 생성합니다. 지정한 이름은 웹 앱의 URL에 사용됩니다:

```shell
az webapp create \
    --name "gitlab-minio-app" \
    --deployment-container-image-name "minio/minio" \
    --plan "gitlab-azure-minio-app-plan" \
    --resource-group "gitlab-azure-minio"
```

Web app은 이제 `https://gitlab-minio-app.azurewebsites.net`에서 액세스할 수 있어야 합니다.

마지막으로 시작 명령을 설정하고 웹 앱에서 사용할 스토리지 계정 이름 및 키를 저장하는 환경 변수 `MINIO_ACCESS_KEY` 및 `MINIO_SECRET_KEY`을 생성해야 합니다.

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

## 결론 {#conclusion}

이 게이트웨이는 s3 호환성이 있는 모든 클라이언트에서 사용할 수 있습니다. 웹 애플리케이션 URL은 `s3 endpoint`이 되고, 스토리지 계정 이름은 `accesskey`, 스토리지 계정 키는 `secretkey`이 됩니다.

## 참고 {#reference}

<!-- vale gitlab.Spelling = NO -->

이 가이드는 [Alessandro Segala의 같은 주제에 대한 블로그 게시물](https://withblue.ink/2017/10/29/how-to-use-s3cmd-and-any-other-amazon-s3-compatible-app-with-azure-blob-storage.html)에서 참고하여 작성되었습니다.

<!-- vale gitlab.Spelling = YES -->
