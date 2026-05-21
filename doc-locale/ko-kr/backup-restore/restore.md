---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 설치 복원
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

기존 GitLab 인스턴스의 백업 tarball을 얻으려면 Linux 패키지 또는 GitLab Helm 차트와 같은 다른 설치 방법을 사용하여 [설명서에 제공된](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/) 지침을 따르세요.

다른 인스턴스에서 가져온 백업을 복원하는 경우 백업을 수행하기 전에 기존 인스턴스를 객체 저장소 사용으로 마이그레이션해야 합니다. [이슈 646](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/646)을 참조하세요.

백업을 생성한 GitLab 버전과 동일한 버전으로 복원하는 것이 좋습니다.

GitLab 백업 복원은 차트에서 제공하는 Toolbox 포드에서 `backup-utility` 명령을 실행하여 수행됩니다.

처음으로 복원을 실행하기 전에 [Toolbox가 올바르게 구성](_index.md) 되어 있으며 [객체 저장소](_index.md#object-storage)에 액세스할 수 있는지 확인해야 합니다.

GitLab Helm 차트에서 제공하는 백업 유틸리티는 다음 위치 중 어느 곳에서나 tarball을 복원할 수 있습니다.

1. 인스턴스와 연결된 객체 저장소 서비스의 `gitlab-backups` 버킷입니다. 이것이 기본 시나리오입니다.
1. 포드에서 액세스할 수 있는 공개 URL입니다.
1. `kubectl cp`을 사용하여 Toolbox 포드에 복사할 수 있는 로컬 파일입니다.

## 비밀 복원 {#restoring-the-secrets}

### Rails 비밀 복원 {#restore-the-rails-secrets}

{{<alert type="note">}}

[GitLab Environment Toolkit (GET)](https://docs.gitlab.com/install/install_methods/#gitlab-environment-toolkit-get)을 사용하여 배포된 하이브리드 환경은 Omnibus 노드와 Kubernetes 간의 자동 비밀 동기화를 수행하며, 이는 복원을 수행할 때 고려해야 합니다. 자세한 내용은 GET 설명서의 [이 섹션](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_post_considerations.md#restores)을 참조하세요.

{{</alert>}}

GitLab 차트는 Rails 비밀을 YAML 형식의 콘텐츠가 있는 Kubernetes 비밀로 제공할 것으로 예상합니다. Linux 패키지 인스턴스에서 Rails 비밀을 복원하는 경우 비밀이 `/etc/gitlab/gitlab-secrets.json` 파일에 JSON 형식으로 저장됩니다. 파일을 변환하고 YAML 형식으로 비밀을 만들려면:

1. `/etc/gitlab/gitlab-secrets.json` 파일을 `kubectl` 명령을 실행하는 워크스테이션으로 복사합니다.
1. [yq](https://github.com/mikefarah/yq) 도구(버전 4.21.1 이상)를 워크스테이션에 설치합니다.
1. 다음 명령을 실행하여 `gitlab-secrets.json`을 YAML 형식으로 변환합니다:

   ```shell
   yq -P '{"production": .gitlab_rails}' gitlab-secrets.json -o yaml >> gitlab-secrets.yaml
   ```

1. 새 `gitlab-secrets.yaml` 파일에 다음 콘텐츠가 있는지 확인합니다:

   ```YAML
   production:
     db_key_base: <your key base value>
     secret_key_base: <your secret key base value>
     otp_key_base: <your otp key base value>
     openid_connect_signing_key: <your openid signing key>
     active_record_encryption_primary_key:
     - 'your active record encryption primary key'
     active_record_encryption_deterministic_key:
     - 'your active record encryption deterministic key'
     active_record_encryption_key_derivation_salt: 'your active record key derivation salt'
   ```

1. `openid_connect_signing_key`과 같은 다중 라인 비밀에 줄 바꿈 문자(`\n`)가 포함되어 있지 않은지 확인합니다. 애플리케이션에서 사용할 때 [디코딩 문제](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3352#note_994430571)를 피하기 위해 다중 라인 비밀을 별도의 라인으로 분할합니다.

YAML 파일에서 Rails 비밀을 복원하려면:

1. Rails 비밀의 객체 이름을 찾습니다:

   ```shell
   kubectl get secrets | grep rails-secret
   ```

1. 기존 비밀을 삭제합니다:

   ```shell
   kubectl delete secret <rails-secret-name>
   ```

1. 기존과 동일한 이름을 사용하여 새 비밀을 만들고 로컬 YAML 파일을 전달합니다.

   ```shell
   kubectl create secret generic <rails-secret-name> --from-file=secrets.yml=gitlab-secrets.yaml
   ```

### 포드 재시작 {#restart-the-pods}

새로운 비밀을 사용하려면 Webservice, Sidekiq 및 Toolbox 포드를 다시 시작해야 합니다. 이러한 포드를 다시 시작하는 가장 안전한 방법은 다음을 실행하는 것입니다:

```shell
kubectl delete pods -lapp=sidekiq,release=<helm release name>
kubectl delete pods -lapp=webservice,release=<helm release name>
kubectl delete pods -lapp=toolbox,release=<helm release name>
```

## 백업 파일 복원 {#restoring-the-backup-file}

GitLab 설치를 복원하는 단계는 다음과 같습니다.

1. 차트를 배포하여 실행 중인 GitLab 인스턴스가 있는지 확인합니다. 다음 명령을 실행하여 Toolbox 포드가 활성화되어 실행 중인지 확인합니다.

   ```shell
   kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
   ```

1. 위의 위치 중 어느 곳에나 tarball을 준비합니다. `<backup_ID>_gitlab_backup.tar` 형식으로 이름이 지정되었는지 확인합니다. [백업 ID](https://docs.gitlab.com/administration/backup_restore/backup_archive_process/#backup-id)가 무엇인지 확인하세요.
1. 후속 재시작을 위해 데이터베이스 클라이언트의 현재 레플리카 수를 기록합니다:

   ```shell
   kubectl get deploy -n <namespace> -lapp=sidekiq,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
   kubectl get deploy -n <namespace> -lapp=webservice,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
   kubectl get deploy -n <namespace> -lapp=prometheus,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
   ```

1. 복원 프로세스에 방해가 되는 잠금을 방지하기 위해 데이터베이스 클라이언트를 중지합니다:

   ```shell
   kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=0
   kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=0
   kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=0
   ```

1. 백업 유틸리티를 실행하여 tarball을 복원합니다.

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility --restore -t <backup_ID>
   ```

   여기서 `<backup_ID>`은 `gitlab-backups` 버킷에 저장된 tarball의 이름에서 가져온 것입니다. 공개 URL을 제공하려는 경우 다음 명령을 사용하세요:

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility --restore -f <URL>
   ```

    다음 형식인 한 로컬 경로를 URL로 제공할 수 있습니다: `file:///<path>`

1. 이 프로세스는 tarball의 크기에 따라 시간이 걸립니다.
1. 복원 프로세스는 기존 데이터베이스 콘텐츠를 삭제하고, 기존 리포지토리를 임시 위치로 이동하고, tarball의 콘텐츠를 추출합니다. 리포지토리는 디스크의 해당 위치로 이동되고 아티팩트, 업로드, LFS 등과 같은 다른 데이터는 객체 저장소의 해당 버킷에 업로드됩니다.
1. 애플리케이션을 다시 시작합니다:

   ```shell
   kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=<value>
   kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=<value>
   kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=<value>
   ```

> [!note]
> 복원 중에 백업 tarball을 디스크에 추출해야 합니다. 이는 Toolbox 포드에 필요한 크기의 디스크가 있어야 함을 의미합니다. 자세한 내용 및 구성은 [Toolbox 설명서](../charts/gitlab/toolbox/_index.md#persistence-configuration)를 참조하세요.

### 러너 등록 토큰 복원 {#restore-the-runner-registration-token}

복원 후 포함된 러너는 더 이상 올바른 등록 토큰이 없기 때문에 인스턴스에 등록할 수 없습니다. 이를 업데이트하려면 다음 [문제 해결 단계](../troubleshooting/_index.md#included-gitlab-runner-failing-to-register)를 따르세요.

## Kubernetes 관련 설정 활성화 {#enable-kubernetes-related-settings}

복원된 백업이 차트의 기존 설치에서 나온 것이 아닌 경우 복원 후 일부 Kubernetes 특정 기능을 활성화해야 합니다. [증분 CI 작업 로깅](https://docs.gitlab.com/administration/cicd/job_logs/#incremental-logging)과 같은.

1. 다음 명령을 실행하여 Toolbox 포드를 찾습니다.

   ```shell
   kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
   ```

1. 필요한 기능을 활성화하려면 인스턴스 설정 스크립트를 실행합니다.

   ```shell
   kubectl exec <Toolbox pod name> -it -- gitlab-rails runner -e production /scripts/custom-instance-setup
   ```

## 포드 재시작 {#restart-the-pods-1}

새로운 변경 사항을 사용하려면 Webservice 및 Sidekiq 포드를 다시 시작해야 합니다. 이러한 포드를 다시 시작하는 가장 안전한 방법은 다음을 실행하는 것입니다:

```shell
kubectl delete pods -lapp=sidekiq,release=<helm release name>
kubectl delete pods -lapp=webservice,release=<helm release name>
```

## (선택 사항) 루트 사용자의 암호 재설정 {#optional-reset-the-root-users-password}

복원 프로세스는 `gitlab-initial-root-password` 비밀을 백업의 값으로 업데이트하지 않습니다. `root`로 로그인하려면 백업에 포함된 원래 암호를 사용하세요. 암호에 더 이상 액세스할 수 없는 경우 아래 단계를 따라 재설정하세요.

1. 다음 명령을 실행하여 Webservice 포드에 연결합니다.

   ```shell
   kubectl exec <Webservice pod name> -it -- bash
   ```

1. 다음 명령을 실행하여 `root` 사용자의 암호를 재설정합니다. `#{password}`을 원하는 암호로 바꾸세요.

   ```shell
   /srv/gitlab/bin/rails runner "user = User.first; user.password='#{password}'; user.password_confirmation='#{password}'; user.save!"
   ```

## 추가 정보 {#additional-information}

- [GitLab 차트 백업/복원 소개](_index.md)
- [GitLab 설치 백업](backup.md)
