---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 객체 저장소를 사용하여 GitLab 차트 구성
---

프로덕션 배포에 필요한 외부 객체 저장소를 사용하여 GitLab Helm 차트를 구성합니다.

> [!note] GitLab 19.0부터 GitLab Helm 차트는 더 이상 MinIO를 포함하지 않습니다. 자세한 내용은 [지원 중단 공지](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart) 를 참조하고 [마이그레이션](../../installation/migration/bundled_chart_migration.md)하여 외부 대안을 사용하세요.

GitLab은 Kubernetes에서 고가용성의 영속적 데이터를 위해 객체 저장소를 사용합니다. GitLab은 주요 클라우드 객체 저장소 제공자에 대한 두 가지 유형의 인증 방법을 지원합니다: 정적 자격 증명과 클라우드 특정 서비스를 통한 임시 자격 증명입니다.

## 정적 자격 증명 {#static-credentials}

이러한 자격 증명은 모든 제공자에 대한 장기적 액세스 키와 암호입니다:

- AWS S3: 액세스 키 ID + 비밀 액세스 키
- Google Cloud Storage:  서비스 계정 JSON 키 파일
- Azure Blob Storage:  저장소 계정 이름 + 액세스 키 또는 클라이언트 ID + 테넌트 ID + 클라이언트 암호

## Cloud IAM을 통한 임시 자격 증명 {#temporary-credentials-through-cloud-iam}

GitLab은 동적, 단기 자격 증명을 위해 제공자별 워크로드 ID 메커니즘을 검색할 수 있습니다:

- AWS S3: [서비스 계정용 IAM 역할(IRSA)](aws-iam-roles.md)
- Google Cloud Storage:  [워크로드 ID 페더레이션](gke-workload-identity.md)
- Azure Blob Storage:  [Azure Kubernetes Service용 워크로드 ID](azure-workload-identity.md)

이러한 임시 자격 증명 메커니즘은 다음을 통해 보안을 개선합니다:

- 장기적 정적 자격 증명을 제거합니다.
- 자동화된 자격 증명 회전을 제공합니다.
- 세밀한 액세스 제어를 활성화합니다.
- 자격 증명 사용의 감사 로깅을 지원합니다.
- 클라우드 제공자 IAM 정책과 통합합니다.

## MinIO 비활성화 {#disable-minio}

> [!warning] GitLab 19.0부터 GitLab Helm 차트는 더 이상 MinIO를 포함하지 않습니다. 자세한 내용은 [지원 중단 공지](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart) 를 참조하고 [마이그레이션](../../installation/migration/bundled_chart_migration.md)하여 외부 대안을 사용하세요.

기본적으로 `minio`이라는 S3 호환 저장소 솔루션이 차트와 함께 배포됩니다. 프로덕션 품질의 배포를 위해 Google Cloud Storage 또는 AWS S3과 같은 호스팅된 객체 저장소 솔루션을 사용하는 것을 권장합니다.

MinIO를 비활성화하려면 이 옵션을 설정하고 아래 관련 문서를 따르세요:

```shell
--set global.minio.enabled=false
```

[전체 구성의 예](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/values-external-objectstorage.yaml) 가 [예제](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples)에서 제공되었습니다.

## Azure Blob 저장소 {#azure-blob-storage}

Azure Blob 저장소에 대한 직접 지원은 [업로드된 첨부 파일, CI 작업 아티팩트, LFS 및 통합 설정을 통해 지원되는 기타 객체 유형](https://docs.gitlab.com/administration/object_storage/#storage-specific-configuration)에 사용 가능합니다. 이전 GitLab 버전에서는 [Azure MinIO 게이트웨이](azure-minio-gateway.md)가 필요했습니다.

> [!note] GitLab은 Docker Registry의 저장소로 [Azure MinIO 게이트웨이를 지원하지 않습니다](https://github.com/minio/minio/issues/9978). [해당 Azure 예제](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.azure.yaml) 를 [Docker Registry 설정](#docker-registry-images)할 때 참조하세요.

Azure에서는 blob의 모음을 나타내기 위해 컨테이너라는 단어를 사용하지만 GitLab은 버킷이라는 용어를 표준화합니다.

Azure Blob 저장소는 [통합 객체 저장소 설정](../../charts/globals.md#consolidated-object-storage)의 사용을 요구합니다. 단일 Azure 저장소 계정 이름과 키는 여러 Azure blob 컨테이너에서 사용되어야 합니다. 개별 `connection` 설정을 객체 유형(예: `artifacts`, `uploads` 등)별로 사용자 지정할 수 없습니다.

Azure Blob 저장소를 활성화하려면 [`rails.azurerm.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azurerm.yaml)를 참조하여 Azure `connection`을(를) 정의합니다. 이를 다음과 같이 시크릿으로 로드할 수 있습니다:

```shell
kubectl create secret generic gitlab-rails-storage --from-file=connection=rails.azurerm.yml
```

그 다음 MinIO를 비활성화하고 이러한 전역 설정을 설정합니다:

```shell
--set global.minio.enabled=false
--set global.appConfig.object_store.enabled=true
--set global.appConfig.object_store.connection.secret=gitlab-rails-storage
```

[기본 이름 또는 버킷 구성에서 컨테이너 이름 설정](../../charts/globals.md#specify-buckets)하기 위해 Azure 컨테이너를 만들어야 합니다.

> [!note] `Requests to the local network are not allowed`으로 요청이 실패하면 [문제 해결 섹션](#troubleshooting)을 참조하세요.

## Docker Registry 이미지 {#docker-registry-images}

`registry` 차트의 객체 저장소 구성은 `registry.storage` 키와 `global.registry.bucket` 키를 통해 수행됩니다.

```shell
--set registry.storage.secret=registry-storage
--set registry.storage.key=config
--set global.registry.bucket=bucket-name
```

> [!note] 버킷 이름은 시크릿과 `global.registry.bucket` 모두에서 설정되어야 합니다. 시크릿은 레지스트리 서버에서 사용되고 전역은 GitLab 백업에서 사용됩니다.

[레지스트리 차트 저장소 설명서](../../charts/registry/_index.md#storage)에 따라 시크릿을 생성한 다음 이 시크릿을 사용하도록 차트를 구성합니다.

[S3](https://distribution.github.io/distribution/storage-drivers/s3/) (S3 호환 저장소이지만 Azure MinIO 게이트웨이는 지원되지 않음, [Azure Blob Storage](#azure-blob-storage) 참조), [Azure](https://distribution.github.io/distribution/storage-drivers/azure/) 및 [GCS](https://distribution.github.io/distribution/storage-drivers/gcs/) 드라이버의 예제는 [`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)에서 찾을 수 있습니다.

- [`registry.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.s3.yaml)
- [`registry.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.gcs.yaml)
- [`registry.azure.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.azure.yaml)

### 레지스트리 구성 {#registry-configuration}

1. 사용할 저장소 서비스를 결정합니다.
1. 적절한 파일을 `registry-storage.yaml`으로 복사합니다.
1. 환경에 맞는 올바른 값으로 편집합니다.
1. [레지스트리 차트 저장소 설명서](../../charts/registry/_index.md#storage)를 따라 시크릿을 생성합니다.
1. 문서에 따라 차트를 구성합니다.

## LFS, 아티팩트, 업로드, 패키지, 외부 Diff, Terraform 상태, 종속성 프록시, 보안 파일 {#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy-secure-files}

LFS, 아티팩트, 업로드, 패키지, 외부 Diff, Terraform 상태, 보안 파일 및 익명화기의 객체 저장소 구성은 다음 키를 통해 수행됩니다:

- `global.appConfig.lfs`
- `global.appConfig.artifacts`
- `global.appConfig.uploads`
- `global.appConfig.packages`
- `global.appConfig.externalDiffs`
- `global.appConfig.dependencyProxy`
- `global.appConfig.terraformState`
- `global.appConfig.ciSecureFiles`

다음 사항도 참고하세요:

- [기본 이름 또는 버킷 구성의 사용자 지정 이름](../../charts/globals.md#specify-buckets)의 버킷을 생성해야 합니다.
- 각각 다른 버킷이 필요하지 않으면 백업에서 복원하는 것이 제대로 작동하지 않습니다.
- MR Diff를 외부 저장소에 저장하는 것은 기본적으로 활성화되어 있지 않으므로 `externalDiffs`에 대한 객체 저장소 설정이 적용되려면 `global.appConfig.externalDiffs.enabled` 키가 `true` 값을 가져야 합니다.
- 종속성 프록시 기능은 기본적으로 활성화되어 있지 않으므로 `dependencyProxy`에 대한 객체 저장소 설정이 적용되려면 `global.appConfig.dependencyProxy.enabled` 키가 `true` 값을 가져야 합니다.

다음은 구성 옵션의 예입니다:

```shell
--set global.appConfig.lfs.bucket=gitlab-lfs-storage
--set global.appConfig.lfs.connection.secret=object-storage
--set global.appConfig.lfs.connection.key=connection

--set global.appConfig.artifacts.bucket=gitlab-artifacts-storage
--set global.appConfig.artifacts.connection.secret=object-storage
--set global.appConfig.artifacts.connection.key=connection

--set global.appConfig.uploads.bucket=gitlab-uploads-storage
--set global.appConfig.uploads.connection.secret=object-storage
--set global.appConfig.uploads.connection.key=connection

--set global.appConfig.packages.bucket=gitlab-packages-storage
--set global.appConfig.packages.connection.secret=object-storage
--set global.appConfig.packages.connection.key=connection

--set global.appConfig.externalDiffs.bucket=gitlab-externaldiffs-storage
--set global.appConfig.externalDiffs.connection.secret=object-storage
--set global.appConfig.externalDiffs.connection.key=connection

--set global.appConfig.terraformState.bucket=gitlab-terraform-state
--set global.appConfig.terraformState.connection.secret=object-storage
--set global.appConfig.terraformState.connection.key=connection

--set global.appConfig.dependencyProxy.bucket=gitlab-dependencyproxy-storage
--set global.appConfig.dependencyProxy.connection.secret=object-storage
--set global.appConfig.dependencyProxy.connection.key=connection

--set global.appConfig.ciSecureFiles.bucket=gitlab-ci-secure-files
--set global.appConfig.ciSecureFiles.connection.secret=object-storage
--set global.appConfig.ciSecureFiles.connection.key=connection
```

[charts/globals appConfig 설명서](../../charts/globals.md#configure-appconfig-settings)를 참조하여 전체 세부 정보를 확인하세요.

[연결 세부 정보 설명서](../../charts/globals.md#connection)에 따라 시크릿을 생성한 다음 제공된 시크릿을 사용하도록 차트를 구성합니다. 참고: 모든 시크릿에 동일한 시크릿을 사용할 수 있습니다.

[AWS](https://fog.github.io/storage/#using-amazon-s3-and-fog) (Azure MinIO 사용 등 모든 S3 호환 저장소인 [Azure using MinIO](azure-minio-gateway.md) ) 및 [Google](https://fog.github.io/storage/#google-cloud-storage) 제공자의 예제는 [`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)에서 찾을 수 있습니다.

- [`rails.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.s3.yaml)
- [`rails.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.gcs.yaml)
- [`rails.azure.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azure.yaml)
- [`rails.azurerm.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azurerm.yaml)

### S3 암호화 {#s3-encryption}

GitLab은 [Amazon KMS](https://aws.amazon.com/kms/) 를 지원하여 [S3 버킷에 저장된 데이터를 암호화](https://docs.gitlab.com/administration/object_storage/#encrypted-s3-buckets)합니다. 이를 두 가지 방법으로 활성화할 수 있습니다:

- AWS에서 [기본 암호화를 사용하도록 S3 버킷을 구성](https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html)합니다.
- GitLab에서 [서버 측 암호화 헤더](../../charts/globals.md#storage_options)를 활성화합니다.

이 두 옵션은 상호 배타적이지 않습니다. 기본 암호화 정책을 설정할 수 있지만 서버 측 암호화 헤더를 활성화하여 해당 기본값을 재정의할 수도 있습니다.

[암호화된 S3 버킷에 대한 GitLab 설명서](https://docs.gitlab.com/administration/object_storage/#encrypted-s3-buckets)를 참조하여 자세한 내용을 확인하세요.

### appConfig 구성 {#appconfig-configuration}

1. 사용할 저장소 서비스를 결정합니다.
1. 적절한 파일을 `rails.yaml`으로 복사합니다.
1. 환경에 맞는 올바른 값으로 편집합니다.
1. [연결 세부 정보 설명서](../../charts/globals.md#connection)를 따라 시크릿을 생성합니다.
1. 문서에 따라 차트를 구성합니다.

## 백업 {#backups}

백업도 객체 저장소에 저장되며 포함된 MinIO 서비스가 아닌 외부를 가리키도록 구성해야 합니다. 백업/복원 절차는 두 개의 별도 버킷을 사용합니다:

- 백업을 저장하기 위한 버킷(`global.appConfig.backups.bucket`)
- 복원 중에 기존 데이터를 보존하기 위한 임시 버킷(`global.appConfig.backups.tmpBucket`)

AWS S3 호환 객체 저장소 시스템, Google Cloud Storage 및 Azure Blob Storage가 지원되는 백엔드입니다. `global.appConfig.backups.objectStorage.backend`을(를) `s3`(AWS S3용), `gcs`(Google Cloud Storage용) 또는 `azure`(Azure Blob Storage용)로 설정하여 백엔드 유형을 구성할 수 있습니다. `gitlab.toolbox.backups.objectStorage.config` 키를 통해 연결 구성도 제공해야 합니다.

Google Cloud Storage와 시크릿을 사용할 때 GCP 프로젝트는 `global.appConfig.backups.objectStorage.config.gcpProject` 값으로 설정해야 합니다.

S3 호환 저장소의 경우:

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.config.secret=storage-config
--set gitlab.toolbox.backups.objectStorage.config.key=config
```

Google Cloud Storage(GCS)와 시크릿의 경우:

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.backend=gcs
--set gitlab.toolbox.backups.objectStorage.config.gcpProject=my-gcp-project-id
--set gitlab.toolbox.backups.objectStorage.config.secret=storage-config
--set gitlab.toolbox.backups.objectStorage.config.key=config
```

Google Cloud Storage(GCS)와 [GKE용 워크로드 ID 페더레이션](gke-workload-identity.md)의 경우 백엔드와 버킷만 설정해야 합니다. `gitlab.toolbox.backups.objectStorage.config.secret`와 `gitlab.toolbox.backups.objectStorage.config.key`이 설정되지 않도록 하여 클러스터가 [Google의 애플리케이션 기본 자격 증명](https://cloud.google.com/docs/authentication/application-default-credentials)을 사용하도록 합니다:

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.backend=gcs
```

Azure Blob Storage의 경우:

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.backend=azure
--set gitlab.toolbox.backups.objectStorage.config.secret=storage-config
--set gitlab.toolbox.backups.objectStorage.config.key=config
```

[백업/복원 객체 저장소 설명서](../../backup-restore/_index.md#object-storage)를 참조하여 전체 세부 정보를 확인하세요.

> [!note] 다른 객체 저장소 위치에서 파일을 백업하거나 복원하려면 구성 파일이 모든 GitLab 버킷에 읽기/쓰기할 충분한 액세스 권한이 있는 사용자로 인증하도록 구성되어야 합니다.

### 백업 저장소 예제 {#backups-storage-example}

1. `storage.config` 파일을 생성합니다:

   - Amazon S3에서 내용은 [s3cmd 구성 파일 형식](https://s3tools.org/kb/item14.htm)이어야 합니다.

     ```ini
     [default]
     access_key = AWS_ACCESS_KEY
     secret_key = AWS_SECRET_KEY
     bucket_location = us-east-1
     multipart_chunk_size_mb = 128 # default is 15 (MB)
     ```

   - Google Cloud Storage에서 `storage.admin` 역할을 가진 서비스 계정을 생성한 다음 [서비스 계정 키를 생성](https://cloud.google.com/iam/docs/keys-create-delete#creating_service_account_keys)하여 파일을 생성할 수 있습니다. 다음은 `gcloud` CLI를 사용하여 파일을 생성하는 예입니다.

     ```shell
     export PROJECT_ID=$(gcloud config get-value project)
     gcloud iam service-accounts create gitlab-gcs --display-name "Gitlab Cloud Storage"
     gcloud projects add-iam-policy-binding --role roles/storage.admin ${PROJECT_ID} --member=serviceAccount:gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com
     gcloud iam service-accounts keys create --iam-account gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com storage.config
     ```

   - Azure Storage에서

     ```ini
     [default]
     # Setup endpoint: hostname of the Web App
     host_base = https://your_minio_setup.azurewebsites.net
     host_bucket = https://your_minio_setup.azurewebsites.net
     # Leave as default
     bucket_location = us-west-1
     use_https = True
     multipart_chunk_size_mb = 128 # default is 15 (MB)

     # Setup access keys
     # Access Key = Azure Storage Account name
     access_key = AZURE_ACCOUNT_NAME
     # Secret Key = Azure Storage Account Key
     secret_key = AZURE_ACCOUNT_KEY

     # Use S3 v4 signature APIs
     signature_v2 = False
     ```

1. 시크릿을 생성합니다.

   ```shell
   kubectl create secret generic storage-config --from-file=config=storage.config
   ```

## Google Cloud CDN {#google-cloud-cdn}

{{< history >}}

- GitLab 15.5에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98010)되었습니다.

{{< /history >}}

[Google Cloud CDN](https://cloud.google.com/cdn)을 사용하여 아티팩트 버킷에서 데이터를 캐시하고 가져올 수 있습니다. 이는 성능을 개선하고 네트워크 송신 비용을 줄이는 데 도움이 될 수 있습니다.

Cloud CDN 구성은 다음 키를 통해 수행됩니다:

- `global.appConfig.artifacts.cdn.secret`
- `global.appConfig.artifacts.cdn.key` (기본값은 `cdn`)

Cloud CDN을 사용하려면:

1. [아티팩트 버킷을 백엔드로 사용하도록 Cloud CDN을 설정](https://cloud.google.com/cdn/docs/setting-up-cdn-with-bucket)합니다.
1. [서명된 URL에 대한 키](https://cloud.google.com/cdn/docs/using-signed-urls)를 생성합니다.
1. [버킷에서 읽기 권한을 갖도록 Cloud CDN 서비스 계정에 권한을 부여](https://cloud.google.com/cdn/docs/using-signed-urls#configuring_permissions)합니다.
1. [`rails.googlecdn.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/cdn/rails.googlecdn.yaml)의 예제를 사용하여 매개변수가 있는 YAML 파일을 준비합니다. 다음 정보를 입력해야 합니다:
   - `url`: 1단계의 CDN 호스트의 기본 URL
   - `key_name`: 2단계의 키 이름
   - `key`: 2단계의 실제 시크릿
1. 이 YAML 파일을 `cdn` 키 아래의 Kubernetes 시크릿에 로드합니다. 예를 들어 `gitlab-rails-cdn` 시크릿을 생성하려면:

   ```shell
   kubectl create secret generic gitlab-rails-cdn --from-file=cdn=rails.googlecdn.yml
   ```

1. `global.appConfig.artifacts.cdn.secret`을 `gitlab-rails-cdn`로 설정하세요. `helm` 매개변수를 통해 설정하는 경우 다음을 사용합니다:

    ```shell
    --set global.appConfig.artifacts.cdn.secret=gitlab-rails-cdn
    ```

## 문제 해결 {#troubleshooting}

### Azure Blob: `URL [FILTERED] is blocked: Requests to the local network are not allowed` {#azure-blob-url-filtered-is-blocked-requests-to-the-local-network-are-not-allowed}

이는 Azure Blob 호스트명이 [RFC1918(로컬/프라이빗) IP 주소](https://learn.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#dns-changes-for-private-endpoints)로 확인될 때 발생합니다. 해결 방법으로 Azure Blob 호스트명(`yourinstance.blob.core.windows.net`)에 대해 [아웃바운드 요청](https://docs.gitlab.com/security/webhooks/#allowlist-for-local-requests)을 허용합니다.
