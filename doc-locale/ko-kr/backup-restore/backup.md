---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 설치 백업
---

{{< details >}}

- 계층:  무료, 프리미엄, 얼티밋
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab 백업은 차트에서 제공하는 Toolbox 포드에서 `backup-utility` 명령을 실행하여 작성됩니다. 이 차트의 [Cron 기반 백업](#cron-based-backup) 기능을 활성화하여 백업을 자동화할 수도 있습니다.

처음 백업을 실행하기 전에 [Toolbox가 제대로 구성되어](../charts/gitlab/toolbox/_index.md#configuration) [객체 스토리지](_index.md#object-storage)에 액세스할 수 있도록 해야 합니다.

GitLab Helm 차트 기반 설치를 백업하려면 다음 단계를 따르세요.

## 백업 생성 {#create-the-backup}

1. 다음 명령을 실행하여 toolbox 포드가 실행 중인지 확인합니다.

   ```shell
   kubectl get pods -lrelease=<release_name>,app=toolbox
   ```

   `<release_name>`을 Helm 릴리스의 이름(보통 `gitlab`)으로 바꿉니다.

1. 백업 유틸리티 실행

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility
   ```

1. 객체 스토리지 서비스에서 `gitlab-backups` 버킷을 방문하고 tarball이 추가되었는지 확인합니다. `<backup_ID>_gitlab_backup.tar` 형식으로 명명됩니다. [백업 ID](https://docs.gitlab.com/administration/backup_restore/backup_archive_process/#backup-id)에 대해 읽어보세요.
1. 이 tarball은 복원에 필요합니다.

## Cron 기반 백업 {#cron-based-backup}

> [!note]
> Helm 차트로 생성된 Kubernetes CronJob은 jobTemplate에 `cluster-autoscaler.kubernetes.io/safe-to-evict: "false"` 주석을 설정합니다. GKE Autopilot과 같은 일부 Kubernetes 환경은 이 주석을 설정하지 못하고 백업에 대한 Job 포드를 생성하지 않습니다. 이 주석은 `gitlab.toolbox.backups.cron.safeToEvict` 매개변수를 `true`로 설정하여 변경할 수 있습니다. 이렇게 하면 작업이 생성될 수 있지만 제거되어 백업이 손상될 위험이 있습니다.

Cron 기반 백업은 [Kubernetes 일정](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs)으로 정의된 대로 정기적인 간격으로 수행되도록 이 차트에서 활성화될 수 있습니다.

다음 매개변수를 설정해야 합니다:

- `gitlab.toolbox.backups.cron.enabled`: Cron 기반 백업을 활성화하려면 true로 설정합니다.
- `gitlab.toolbox.backups.cron.schedule`: Kubernetes 일정 문서에 따라 설정합니다.
- `gitlab.toolbox.backups.cron.extraArgs`: [backup-utility](https://gitlab.com/gitlab-org/build/CNG/blob/master/gitlab-toolbox/scripts/bin/backup-utility)에 대한 추가 인수를 선택적으로 설정합니다(`--skip db` 또는 `--s3tool awscli` 등).

## 백업 유틸리티 추가 인수 {#backup-utility-extra-arguments}

백업 유틸리티는 일부 추가 인수를 사용할 수 있습니다.

### 구성 요소 건너뛰기 {#skipping-components}

`--skip` 인수를 사용하여 구성 요소를 건너뜁니다. 유효한 구성 요소 이름은 [백업에서 특정 데이터 제외](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#excluding-specific-data-from-the-backup)에서 찾을 수 있습니다.

각 구성 요소에는 자체 `--skip` 인수가 있어야 합니다. 예:

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --skip db --skip lfs
```

### 백업만 정리 {#cleanup-backups-only}

새 백업을 만들지 않고 백업 정리를 실행합니다.

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --cleanup
```

### 사용할 S3 도구 지정 {#specify-s3-tool-to-use}

`backup-utility` 명령은 기본적으로 `s3cmd`을 사용하여 객체 스토리지에 연결합니다. `s3cmd`이 다른 S3 도구보다 덜 안정적인 경우 이 추가 인수를 재정의할 수 있습니다.

GitLab이 CI 작업 아티팩트 스토리지로 S3 버킷을 사용하고 기본 `s3cmd` CLI 도구를 사용 중일 때 백업 작업이 `ERROR: S3 error: 404 (NoSuchKey): The specified key does not exist.`로 충돌하는 [알려진 문제](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3338)가 있습니다. `s3cmd`에서 `awscli`로 전환하면 백업 작업이 성공적으로 실행될 수 있습니다. 자세한 내용은 [문제 3338](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3338)을 참조하세요.

사용할 S3 CLI 도구는 `s3cmd` 또는 `awscli`일 수 있습니다.

 ```shell
 kubectl exec <Toolbox pod name> -it -- backup-utility --s3tool awscli
 ```

#### awscli로 MinIO 사용 {#using-minio-with-awscli}

`awscli`을 사용할 때 MinIO를 객체 스토리지로 사용하려면 다음 매개변수를 설정합니다:

```yaml
gitlab:
  toolbox:
    extraEnvFrom:
      AWS_ACCESS_KEY_ID:
        secretKeyRef:
          name: <MINIO-SECRET-NAME>
          key: accesskey
      AWS_SECRET_ACCESS_KEY:
        secretKeyRef:
          name: <MINIO-SECRET-NAME>
          key: secretkey
    extraEnv:
      AWS_DEFAULT_REGION: us-east-1 # MinIO default
    backups:
      cron:
        enabled: true
        schedule: "@daily"
        extraArgs: "--s3tool awscli --aws-s3-endpoint-url <MINIO-INGRESS-URL>"
```

S3 CLI 도구 `s5cmd` 지원은 현재 조사 중입니다. [문제 523](https://gitlab.com/gitlab-org/build/CNG/-/issues/523)을 참조하여 진행 상황을 추적하세요.

#### `awscli`로 데이터 무결성 보호 {#data-integrity-protection-with-awscli}

toolbox에 포함된 `awscli` 도구의 최신 버전은 기본적으로 데이터 무결성 보호를 강제합니다. 객체 스토리지 서비스가 이 기능을 지원하지 않으면 이 요구사항을 다음과 같이 비활성화할 수 있습니다:

```yaml
extraEnv:
  AWS_REQUEST_CHECKSUM_CALCULATION: WHEN_REQUIRED
```

구성은 toolbox 포드 `extraEnv` 또는 전역 `extraEnv`일 수 있습니다.

### 서버 측 저장소 백업 {#server-side-repository-backups}

{{< history >}}

- GitLab 17.0에서 [도입되었습니다](https://gitlab.com/gitlab-org/gitlab/-/issues/438393).

{{< /history >}}

백업 보관소에 큰 저장소 백업을 저장하는 대신, 각 저장소를 호스팅하는 Gitaly 노드가 백업을 생성하고 이를 객체 스토리지로 스트리밍하도록 저장소 백업을 구성할 수 있습니다. 이는 백업을 생성하고 복원하는 데 필요한 네트워크 리소스를 줄이는 데 도움이 됩니다.

[서버 측 저장소 백업 생성](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#create-server-side-repository-backups)을 참조하세요.

### 다른 인수 {#other-arguments}

사용 가능한 모든 인수의 전체 목록을 보려면 다음 명령을 실행합니다:

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --help
```

## 암호 백업 {#back-up-the-secrets}

보안 예방 조치로 백업에 포함되지 않은 Rails 암호 복사본도 저장해야 합니다. 데이터베이스를 포함하는 전체 백업을 암호 복사본과 별도로 유지하는 것이 좋습니다.

1. Rails 암호에 대한 개체 이름을 찾습니다.

   ```shell
   kubectl get secrets | grep rails-secret
   ```

1. Rails 암호의 복사본 저장

   ```shell
   kubectl get secrets <rails-secret-name> -o jsonpath="{.data['secrets\.yml']}" | base64 --decode > gitlab-secrets.yaml
   ```

1. `gitlab-secrets.yaml`을 안전한 위치에 저장합니다. 백업을 복원하려면 필요합니다.

## 추가 정보 {#additional-information}

- [GitLab 차트 백업/복원 소개](_index.md)
- [GitLab 설치 복원](restore.md)
