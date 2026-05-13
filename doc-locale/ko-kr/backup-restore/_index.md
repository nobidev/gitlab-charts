---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 인스턴스 백업 및 복원
---

{{< details >}}

- 계층:  무료, 프리미엄, 궁극
- 제공:  GitLab 자가 관리

{{< /details >}}

GitLab Helm 차트는 Toolbox 서브 차트의 유틸리티 포드를 제공하며, 이는 GitLab 인스턴스를 백업 및 복원하기 위한 인터페이스 역할을 합니다. 이는 `backup-utility` 실행 가능 파일이 장착되어 있으며, 이 작업을 위해 필요한 다른 포드들과 상호 작용합니다. 유틸리티 작동 방식에 대한 기술적 세부 사항은 [아키텍처 설명서](../architecture/backup-restore.md)에서 찾을 수 있습니다.

## 전제 조건 {#prerequisites}

- 여기서 설명하는 백업 및 복원 절차는 S3 호환 API로만 테스트되었습니다. Google Cloud Storage와 같은 다른 객체 스토리지 서비스에 대한 지원은 향후 수정 사항에서 테스트될 예정입니다.
- 복원 중에 백업 tarball을 디스크에 추출해야 합니다. 이는 Toolbox 포드에 [필요한 크기의 디스크를 사용 가능해야 함](../charts/gitlab/toolbox/_index.md#restore-considerations)을 의미합니다.
- 이 차트는 [객체 스토리지](#object-storage)를 `artifacts`, `uploads`, `packages`, `registry` 및 `lfs` 객체에 사용하며, 복원 중에 이들을 자동으로 마이그레이션하지 않습니다. 다른 인스턴스에서 가져온 백업을 복원하는 경우, 백업을 수행하기 전에 기존 인스턴스를 객체 스토리지 사용으로 마이그레이션해야 합니다. [문제 646](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/646)을 참조하세요.

## 백업 및 복원 절차 {#backup-and-restoring-procedures}

- [GitLab 설치 백업](backup.md)
- [GitLab 설치 복원](restore.md)

## 객체 스토리지 {#object-storage}

[외부 객체 스토리지](../advanced/external-object-storage/_index.md)를 지정하지 않으면 이 차트를 사용할 때 기본적으로 MinIO 인스턴스를 제공합니다. Toolbox는 특정 설정이 제공되지 않으면 기본적으로 포함된 MinIO에 연결됩니다. Toolbox는 또한 Amazon S3 또는 Google Cloud Storage(GCS)로 백업하도록 구성할 수 있습니다.

### S3로 백업 {#backups-to-s3}

Toolbox는 기본적으로 `s3cmd`을 사용하여 객체 스토리지에 연결합니다. 다만 [다른 S3 도구를 사용하도록 지정](backup.md#specify-s3-tool-to-use)할 수 있습니다. 외부 객체 스토리지 연결을 구성하기 위해 `gitlab.toolbox.backups.objectStorage.config.secret`를 지정해야 하며, 이는 `.s3cfg` 파일을 포함하는 Kubernetes 보안 개체를 가리킵니다. `gitlab.toolbox.backups.objectStorage.config.key`는 기본값 `config`과 다른 경우 지정해야 합니다. 이는 [`.s3cfg`](https://s3tools.org/kb/item14.htm) 파일의 내용을 포함하는 키를 가리킵니다.

다음과 같이 보입니다:

```shell
helm install gitlab gitlab/gitlab \
  --set gitlab.toolbox.backups.objectStorage.config.secret=my-s3cfg \
  --set gitlab.toolbox.backups.objectStorage.config.key=config .
```

또한 두 개의 버킷 위치를 구성해야 하는데, 하나는 백업을 저장하기 위한 것이고 다른 하나는 백업 복원 시 사용되는 임시 버킷입니다.

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
```

### Google Cloud Storage(GCS)로 백업 {#backups-to-google-cloud-storage-gcs}

GCS로 백업하려면 먼저 `gitlab.toolbox.backups.objectStorage.backend`을 `gcs`로 설정해야 합니다. 이는 Toolbox가 객체를 저장하고 검색할 때 `gsutil` CLI를 사용하도록 합니다.

또한 두 개의 버킷 위치를 구성해야 하는데, 하나는 백업을 저장하기 위한 것이고 다른 하나는 백업 복원 시 사용되는 임시 버킷입니다.

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
```

백업 유틸리티는 이러한 버킷에 액세스해야 합니다. 액세스를 부여하는 두 가지 방법이 있습니다:

- Kubernetes 보안 개체에서 자격 증명을 지정합니다.
- [GKE용 워크로드 ID 연합](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity)을 구성합니다.

#### GCS 자격 증명 {#gcs-credentials}

먼저 `gitlab.toolbox.backups.objectStorage.config.gcpProject`을 저장소 버킷을 포함하는 GCP 프로젝트의 프로젝트 ID로 설정합니다.

백업에 사용할 버킷에 대해 `storage.admin` 역할을 가지는 활성 서비스 계정 JSON 키의 내용으로 Kubernetes 보안 개체를 만들어야 합니다. 다음은 `gcloud` 및 `kubectl`을 사용하여 보안 개체를 생성하는 예입니다.

```shell
export PROJECT_ID=$(gcloud config get-value project)
gcloud iam service-accounts create gitlab-gcs --display-name "Gitlab Cloud Storage"
gcloud projects add-iam-policy-binding --role roles/storage.admin ${PROJECT_ID} --member=serviceAccount:gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts keys create --iam-account gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com storage.config
kubectl create secret generic storage-config --from-file=config=storage.config
```

Helm 차트를 다음과 같이 구성하여 GCS로 백업하기 위해 서비스 계정 키를 사용하여 인증합니다:

```shell
helm install gitlab gitlab/gitlab \
  --set gitlab.toolbox.backups.objectStorage.config.secret=storage-config \
  --set gitlab.toolbox.backups.objectStorage.config.key=config \
  --set gitlab.toolbox.backups.objectStorage.config.gcpProject=my-gcp-project-id \
  --set gitlab.toolbox.backups.objectStorage.backend=gcs
```

#### GKE용 워크로드 ID 연합 구성 {#configuring-workload-identity-federation-for-gke}

[GitLab 차트를 사용하여 GKE용 워크로드 ID 연합에 대한 설명서](../advanced/external-object-storage/gke-workload-identity.md)를 참조하세요.

Kubernetes ServiceAccount를 참조하는 IAM 허용 정책을 생성할 때 `roles/storage.objectAdmin` 역할을 부여합니다.

백업의 경우 `gitlab.toolbox.backups.objectStorage.config.secret`, `gitlab.toolbox.backups.objectStorage.config.key` 및 `gitlab.toolbox.backups.objectStorage.config.gcpProject`이 설정되지 않았는지 확인하여 Google의 Application Default Credentials이 사용되도록 합니다.

### Azure Blob 스토리지로 백업 {#backups-to-azure-blob-storage}

Azure Blob 스토리지를 백업을 저장하는 데 사용할 수 있으며 `gitlab.toolbox.backups.objectStorage.backend`을 `azure`로 설정합니다. 이를 통해 Toolbox는 포함된 `azcopy` 복사본을 사용하여 백업 파일을 Azure Blob 스토리지로 전송하고 검색할 수 있습니다.

Azure Blob 스토리지를 사용하려면 기존 리소스 그룹에 스토리지 계정을 생성해야 합니다. 스토리지 계정의 이름, 액세스 키 및 Blob 호스트를 사용하여 구성 보안 개체를 생성합니다.

매개변수를 포함하는 구성 파일을 생성합니다:

```yaml
# azure-backup-conf.yaml
azure_storage_account_name: <storage account>
azure_storage_access_key: <access key value>
azure_storage_domain: blob.core.windows.net # optional
```

다음 `kubectl` 명령을 사용하여 Kubernetes 보안 개체를 생성할 수 있습니다:

```shell
kubectl create secret generic backup-azure-creds \
  --from-file=config=azure-backup-conf.yaml
```

보안 개체가 생성되면 배포된 값에 백업 설정을 추가하거나 Helm 명령줄에서 설정을 제공하여 GitLab Helm 차트를 구성할 수 있습니다. 예를 들어:

```shell
helm install gitlab gitlab/gitlab \
  --set gitlab.toolbox.backups.objectStorage.config.secret=backup-azure-creds \
  --set gitlab.toolbox.backups.objectStorage.config.key=config \
  --set gitlab.toolbox.backups.objectStorage.backend=azure
```

보안 개체의 액세스 키는 더 짧은 수명의 공유 액세스 서명(SAS) 토큰을 생성하고 새로 고쳐 스토리지 계정에 액세스하는 데 사용됩니다.

또한 두 개의 버킷/컨테이너를 미리 생성해야 하는데, 하나는 백업을 저장하기 위한 것이고 다른 하나는 백업 복원 시 사용되는 임시 버킷입니다. 버킷 이름을 값 또는 설정에 추가합니다. 예를 들어:

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
```

## 레지스트리 메타데이터 데이터베이스 {#registry-metadata-database}

[컨테이너 레지스트리 메타데이터 데이터베이스](../charts/registry/metadata_database.md)를 활성화했다면 백업 및 복원 작업 중에 Toolbox가 레지스트리 데이터베이스에 액세스하도록 구성할 수 있습니다. 이를 위해서는 Toolbox 차트 값에 레지스트리 데이터베이스 자격 증명을 설정해야 합니다. 구성 세부 사항은 Toolbox 차트 설명서의 [레지스트리 메타데이터 데이터베이스 자격 증명](../charts/gitlab/toolbox/_index.md#registry-metadata-database-credentials) 섹션을 참조하세요.

## 문제 해결 {#troubleshooting}

### 포드 제거 문제 {#pod-eviction-issues}

백업이 객체 스토리지 대상 외부에서 로컬로 조립되므로 임시 디스크 공간이 필요합니다. 필요한 공간이 실제 백업 아카이브의 크기를 초과할 수 있습니다. 기본 구성은 Toolbox 포드의 파일 시스템을 사용하여 임시 데이터를 저장합니다. 리소스 부족으로 인해 포드가 제거되는 것을 발견하면 임시 데이터를 보관할 지속성 볼륨을 포드에 연결해야 합니다. GKE에서 Helm 명령에 다음 설정을 추가합니다:

```shell
--set gitlab.toolbox.persistence.enabled=true
```

백업이 포함된 백업 cron 작업의 일부로 실행되는 경우, cron 작업에 대해서도 지속성을 활성화하려고 합니다:

```shell
--set gitlab.toolbox.backups.cron.persistence.enabled=true
```

다른 공급자의 경우 지속성 볼륨을 생성해야 할 수도 있습니다. 이를 수행하는 방법에 대한 가능한 예제는 [스토리지 설명서](../installation/storage.md)를 참조하세요.

### "버킷을 찾을 수 없음" 오류 {#bucket-not-found-errors}

`Bucket not found` 오류가 백업 중에 나타나면 버킷에 대해 자격 증명이 구성되어 있는지 확인합니다.

명령은 클라우드 서비스 공급자에 따라 달라집니다:

- AWS S3의 경우 자격 증명이 `~/.s3cfg`의 toolbox 포드에 저장됩니다. 실행:

  ```shell
  s3cmd ls
  ```

- GCP GCS의 경우 실행:

  ```shell
  gsutil ls
  ```

사용 가능한 버킷의 목록이 표시됩니다.

### "AccessDeniedException: 403" GCP의 오류 {#accessdeniedexception-403-errors-in-gcp}

`[Error] AccessDeniedException: 403 <GCP Account> does not have storage.objects.list access to the Google Cloud Storage bucket.` 같은 오류는 일반적으로 권한 누락으로 인해 GitLab 인스턴스의 백업 또는 복원 중에 발생합니다.

백업 및 복원 작업은 환경의 모든 버킷을 사용하므로 환경의 모든 버킷이 생성되었고 GCP 계정이 모든 버킷에 액세스(나열, 읽기 및 쓰기)할 수 있는지 확인합니다:

1. toolbox 포드를 찾으세요:

   ```shell
   kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
   ```

1. 포드 환경의 모든 버킷을 가져옵니다. `<toolbox-pod-name>`을 실제 toolbox 포드 이름으로 바꾸되 `"BUCKET_NAME"`는 그대로 두세요:

   ```shell
   kubectl describe pod <toolbox-pod-name> | grep "BUCKET_NAME"
   ```

1. 환경의 모든 버킷에 액세스할 수 있는지 확인합니다:

   ```shell
   # List
   gsutil ls gs://<bucket-to-validate>/

   # Read
   gsutil cp gs://<bucket-to-validate>/<object-to-get> <save-to-location>

   # Write
   gsutil cp -n <local-file> gs://<bucket-to-validate>/
   ```

### "오류: `/home/git/.s3cfg`:  없음" `backup-utility`을 `--backend s3`로 실행할 때의 오류 {#error-homegits3cfg-none-error-when-running-backup-utility-with---backend-s3}

이 오류는 `.s3cfg` 파일을 포함하는 Kubernetes 보안 개체가 `gitlab.toolbox.backups.objectStorage.config.secret` 값을 통해 지정되지 않았을 때 발생합니다.

이를 해결하려면 [S3로 백업](_index.md#backups-to-s3)의 지침을 따르세요.

### "PermissionError:  파일을 쓸 수 없음" S3 사용 오류 {#permissionerror-file-not-writable-errors-using-s3}

`[Error] WARNING: <file> not writable: Operation not permitted` 같은 오류는 toolbox 사용자에게 버킷 항목의 저장된 권한과 일치하는 파일을 쓸 권한이 없을 때 발생합니다.

이를 방지하려면 `s3cmd`을 구성하여 `.s3cfg` 파일에 추가할 다음 플래그를 `gitlab.toolbox.backups.objectStorage.config.secret`을 통해 참조하여 파일 소유자, 모드 및 타임스탬프를 보존하지 않도록 합니다.

```toml
preserve_attrs = False
```

### 복원 시 건너뛴 리포지토리 {#repositories-skipped-on-restore}

GitLab 16.6/Chart 7.6부터 백업 아카이브의 이름이 변경되었으면 복원 시 리포지토리를 건너뛸 수 있습니다. 이를 피하려면 백업 아카이브의 이름을 바꾸지 마세요 및 백업의 이름을 원래 이름 `{backup_id}_gitlab_backup.tar`으로 바꾸세요.

원본 백업 ID는 리포지토리 백업 디렉터리 구조에서 추출할 수 있습니다: `repositories/@hashed/*/*/*/{backup_id}/LATEST`

### 오류: `cannot drop view pg_stat_statements because extension pg_stat_statements requires it` {#error-cannot-drop-view-pg_stat_statements-because-extension-pg_stat_statements-requires-it}

Helm 차트 인스턴스에서 백업을 복원할 때 이 오류가 발생할 수 있습니다. 다음 단계를 해결 방법으로 사용합니다:

1. `toolbox` 포드 내에서 DB 콘솔을 엽니다:

   ```shell
   /srv/gitlab/bin/rails dbconsole -p
   ```

1. 확장을 삭제합니다:

   ```shell
   DROP EXTENSION pg_stat_statements;
   ```

1. 복원 프로세스를 수행합니다.
1. 복원이 완료되면 DB 콘솔에서 확장을 다시 생성합니다:

   ```shell
   CREATE EXTENSION pg_stat_statements;
   ```

`pg_buffercache` 확장에서 동일한 문제가 발생하면 위의 동일한 단계를 따라 삭제하고 다시 생성합니다.

이 오류에 대한 자세한 내용은 문제 [\#2469](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2469)에서 확인할 수 있습니다.

### 업로드 실패 시 Toolbox 백업 {#toolbox-backup-failing-on-upload}

백업이 다음과 같은 오류로 객체 스토리지에 업로드하려고 할 때 실패할 수 있습니다:

```plaintext
An error occurred (XAmzContentSHA256Mismatch) when calling the UploadPart operation: The Content-SHA256 you specified did not match what we received
```

이는 `awscli` 도구와 객체 스토리지 서비스 간의 비호환성으로 인한 것일 수 있습니다. 이 문제는 Dell ECS S3 스토리지를 사용할 때 보고되었습니다.

이 문제를 피하려면 [데이터 무결성 보호 비활성화](backup.md#data-integrity-protection-with-awscli)를 할 수 있습니다.

### 오류: 인식할 수 없는 구성 매개변수 "transaction_timeout" {#error-unrecognized-configuration-parameter-transaction_timeout}

GitLab 차트는 백업 및 복원과 같은 작업을 위한 toolbox를 배포하며, 현재 PostgreSQL 17 클라이언트 라이브러리와 함께 제공됩니다.

클라이언트 라이브러리는 이전 버전과 호환되므로 PostgreSQL 16을 실행 중인 경우 백업 및 복원이 계속 작동하지만 이 오류가 나타날 수 있습니다:

```plaintext
ERROR:  unrecognized configuration parameter "transaction_timeout"
```

이는 pg_dump가 이전 버전과 호환되지만 다양한 서버 버전 간에 복원이 원활하게 작동한다는 보장이 없기 때문입니다.

자세한 내용은 [`pg_dump` 설명서](https://www.postgresql.org/docs/current/app-pgdump.html)를 참조하세요.

백업 도구는 이 오류를 무시하고 싶은지 물어볼 것이며, 이 경우 무시하는 것이 안전합니다.
