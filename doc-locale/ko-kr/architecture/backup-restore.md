---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 백업 및 복원
---

이 문서는 CNG로의 백업 및 복원의 기술적 구현을 설명합니다.

## 도구 상자 포드 {#toolbox-pod}

[도구 상자 차트](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts/gitlab/charts/toolbox)는 클러스터에 포드를 배포합니다. 이 포드는 클러스터의 다른 컨테이너와 상호 작용하기 위한 진입점 역할을 합니다.

이 포드를 사용하여 `kubectl exec -it <pod name> -- <arbitrary command>`를 사용하여 명령을 실행할 수 있습니다.

도구 상자는 [도구 상자 이미지](https://gitlab.com/gitlab-org/build/CNG/tree/master/gitlab-toolbox)에서 컨테이너를 실행합니다.

이미지에는 사용자가 명령으로 호출할 수 있는 [사용자 정의 스크립트](https://gitlab.com/gitlab-org/build/CNG/-/tree/master/gitlab-toolbox/scripts/bin)가 포함되어 있습니다. 이러한 스크립트는 Rake 작업, 백업, 복원 및 객체 저장소와 상호 작용하기 위한 일부 도우미 스크립트를 실행하기 위한 것입니다.

## 백업 유틸리티 {#backup-utility}

[백업 유틸리티](https://gitlab.com/gitlab-org/build/CNG/-/blob/master/gitlab-toolbox/scripts/bin/backup-utility)는 도구 상자 컨테이너의 스크립트 중 하나이며 이름에서 알 수 있듯이 백업을 수행하기 위해 사용되지만 기존 백업의 복원도 처리하는 스크립트입니다.

### 백업 {#backups}

백업 유틸리티 스크립트는 인수 없이 실행될 때 백업 tar를 생성하고 객체 저장소에 업로드합니다.

#### 실행 순서 {#sequence-of-execution}

백업은 다음 단계에 따라 순서대로 만들어집니다:

1. [GitLab 백업 Rake 작업](https://gitlab.com/gitlab-org/build/CNG/-/blob/f65867afa54f6d0033e19f9e9038ec680abd5eb2/gitlab-toolbox/scripts/bin/backup-utility#L217)을 사용하여 데이터베이스를 백업합니다(생략되지 않은 경우).
1. [GitLab 백업 Rake 작업](https://gitlab.com/gitlab-org/build/CNG/-/blob/f65867afa54f6d0033e19f9e9038ec680abd5eb2/gitlab-toolbox/scripts/bin/backup-utility#L220)을 사용하여 저장소를 백업합니다(생략되지 않은 경우).
1. 각 객체 저장소 백엔드에 대해
   1. 객체 저장소 백엔드가 건너뛰기로 표시된 경우 이 저장소 백엔드를 건너뜁니다.
   1. 해당 객체 저장소 버킷의 기존 데이터를 `<bucket-name>.tar`로 이름 지정하여 Tar 형식으로 저장합니다.
   1. tar를 디스크의 백업 위치로 이동합니다.
1. `backup_information.yml` 파일을 작성합니다. 이 파일에는 GitLab 버전, 백업 시간 및 건너뛴 항목을 식별하는 메타데이터가 포함되어 있습니다.
1. 개별 tar 파일과 `backup_information.yml`를 포함하는 tar 파일을 생성합니다.
1. 결과 tar 파일을 객체 저장소 `gitlab-backups` 버킷에 업로드합니다.

#### 명령줄 인수 {#command-line-arguments}

- `--skip <component>`

  `--skip <component>`을 사용하여 백업 프로세스에서 건너뛸 모든 구성 요소에 대해 백업 프로세스의 일부를 건너뛸 수 있습니다. 건너뛸 수 있는 구성 요소는 [백업에서 특정 데이터 제외](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#excluding-specific-data-from-the-backup)에서 찾을 수 있습니다.

- `-t <timestamp-override-value>`

  이렇게 하면 백업 이름을 부분적으로 제어할 수 있습니다. 이 플래그를 지정하면 생성된 백업의 이름이 `<timestamp-override-value>_gitlab_backup.tar`가 됩니다. 기본값은 현재 UNIX 타임스탬프이며 `YYYY_mm_dd`로 형식화된 현재 날짜가 뒤에 붙습니다.

- `--backend <backend>`

  백업에 사용할 객체 저장소 백엔드를 구성합니다. `s3` 또는 `gcs`일 수 있습니다. 기본값은 `s3`입니다.

- `--storage-class <storage-class-name>`

  또한 `--storage-class <storage-class-name>`을 사용하여 백업이 저장된 저장소 클래스를 지정하여 백업 저장소 비용을 절약할 수 있습니다. 지정하지 않으면 저장소 백엔드의 기본값을 사용합니다.

  이 저장소 클래스 이름은 지정된 백엔드의 저장소 클래스 인수로 그대로 전달됩니다.

#### GitLab 백업 버킷 {#gitlab-backup-bucket}

백업을 저장하는 데 사용되는 버킷의 기본 이름은 `gitlab-backups`입니다. 이는 `BACKUP_BUCKET_NAME` 환경 변수를 사용하여 구성할 수 있습니다.

#### Google Cloud Storage로 백업 {#backing-up-to-google-cloud-storage}

기본적으로 백업 유틸리티는 `s3cmd`을 사용하여 객체 저장소에서 아티팩트를 업로드하고 다운로드합니다. 이것은 Google Cloud Storage(GCS)에서 작동할 수 있지만 상호 운용성 API를 사용해야 하므로 인증 및 권한 부여에 바람직하지 않은 절충이 생깁니다. Google Cloud Storage에 백업할 때 백업 유틸리티 스크립트를 구성하여 Cloud Storage 기본 CLI인 `gsutil`을 사용하여 아티팩트의 업로드 및 다운로드를 수행할 수 있습니다. `BACKUP_BACKEND` 환경 변수를 `gcs`로 설정하면 됩니다.

### 레지스트리 메타데이터 데이터베이스 백업 및 복원 {#registry-metadata-database-backup-and-restore}

[컨테이너 레지스트리 메타데이터 데이터베이스](../charts/registry/metadata_database.md)는 GitLab Rails가 아닌 레지스트리가 소유한 별도의 PostgreSQL 데이터베이스입니다. 표준 GitLab 백업 Rake 작업은 Rails 데이터베이스만 다루므로 레지스트리 메타데이터 데이터베이스를 백업 및 복원하려면 Toolbox 포드 내에서 자체 데이터베이스 자격 증명을 사용할 수 있어야 합니다.

구성된 경우 차트는 `/etc/gitlab/registry-db/` 아래에 다음 파일을 마운트하므로 백업 및 복원 도구가 Rails 데이터베이스와 독립적으로 레지스트리 데이터베이스에 연결할 수 있습니다:

- `connection.env` — 연결 매개변수(호스트, 포트, 데이터베이스 이름, SSL 모드, 인증서 경로). 레지스트리 차트의 `ConfigMap`에서 가져옵니다.
- `backup-user.env` / `restore-user.env` — 백업 및 복원에 대한 데이터베이스 사용자 이름 재정의. Toolbox `ConfigMap`에서 가져옵니다.
- `backup-pass` / `restore-pass` — 해당 비밀번호. Kubernetes `Secret`에서 가져옵니다.

별도의 백업 및 복원 사용자가 지원되므로 운영자는 최소 권한의 원칙을 따를 수 있습니다(예: 백업을 위한 읽기 전용 사용자, 복원을 위한 쓰기 권한이 있는 사용자).

모든 볼륨 소스는 `optional: true`로 표시되므로 레지스트리 메타데이터 데이터베이스가 구성되지 않은 경우에도 Toolbox 포드가 정상적으로 작동합니다.

설정 지침은 [Toolbox 구성](../charts/gitlab/toolbox/_index.md#registry-metadata-database-credentials)을 참조하세요.

### 복원 {#restore}

백업 유틸리티는 `--restore` 인수가 주어지면 기존 백업에서 실행 중인 인스턴스로의 복원을 시도합니다. 이 백업은 Linux 패키지 설치 또는 CNG Helm 차트 설치에서 수행할 수 있습니다. 백업된 인스턴스와 실행 중인 인스턴스가 모두 동일한 버전의 GitLab을 실행하는 경우입니다. 복원은 `-t <backup-name>`을 사용하여 백업 버킷의 파일 또는 `-f <url>`을 사용하여 원격 URL을 예상합니다.

`-t` 매개변수가 주어지면 객체 저장소의 백업 버킷에서 해당 이름의 백업 tar를 찾습니다. `-f` 매개변수가 주어지면 주어진 URL이 컨테이너에서 액세스할 수 있는 위치의 백업 tar의 유효한 URI라고 예상합니다.

백업 tar를 가져온 후 실행 순서는 다음과 같습니다:

1. 리포지토리 및 데이터베이스의 경우 [GitLab 백업 Rake 작업](https://gitlab.com/gitlab-org/gitlab-foss/-/blob/master/lib/tasks/gitlab/backup.rake)을 실행합니다.
1. 각 객체 저장소 백엔드에 대해:
   - 해당 객체 저장소 버킷의 기존 데이터를 `<backup-name>.tar`로 이름 지정하여 Tar 형식으로 저장합니다.
   - 객체 저장소의 `tmp` 버킷에 업로드합니다.
   - 해당 버킷을 정리합니다.
   - 백업 콘텐츠를 해당 버킷으로 복원합니다.

> [!note]
> 복원이 실패하면 사용자는 백업 버킷의 `tmp` 디렉토리의 데이터를 사용하여 이전 백업으로 되돌려야 하며, 이는 수동 프로세스입니다.
