---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Helm 차트에서 Linux 패키지로 마이그레이션
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

Helm 설치에서 Linux 패키지(Omnibus) 설치로 마이그레이션하려면:

1. 오른쪽 위 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **개요 > 컴포넌트**를 선택하여 GitLab의 현재 버전을 확인합니다.
1. 깨끗한 컴퓨터를 준비하고 [Linux 패키지를 설치](https://docs.gitlab.com/update/package/)하여 GitLab Helm 차트 버전과 일치하도록 합니다.
1. 마이그레이션 전에 GitLab Helm 차트 인스턴스에서 [Git 저장소의 무결성을 확인](https://docs.gitlab.com/administration/raketasks/check/)합니다.
1. [GitLab Helm 차트 인스턴스의 백업을 만들고](../../backup-restore/backup.md) [비밀을 백업](../../backup-restore/backup.md#back-up-the-secrets)했는지 확인합니다.
1. Linux 패키지 인스턴스에서 `/etc/gitlab/gitlab-secrets.json`을 백업합니다.
1. [yq](https://github.com/mikefarah/yq) 도구(버전 4.21.1 이상)를 `kubectl` 명령을 실행하는 워크스테이션에 설치합니다.
1. 워크스테이션에서 `/etc/gitlab/gitlab-secrets.json` 파일의 복사본을 만듭니다.
1. GitLab Helm 차트 인스턴스에서 비밀을 가져오려면 다음 명령을 실행합니다. `GITLAB_NAMESPACE`과 `RELEASE`를 적절한 값으로 바꿉니다:

   ```shell
   kubectl get secret -n GITLAB_NAMESPACE RELEASE-rails-secret -ojsonpath='{.data.secrets\.yml}' | yq '@base64d | from_yaml | .production' -o json > rails-secrets.json
   yq eval-all 'select(filename == "gitlab-secrets.json").gitlab_rails = select(filename == "rails-secrets.json") | select(filename == "gitlab-secrets.json")' -ojson  gitlab-secrets.json rails-secrets.json > gitlab-secrets-updated.json
   ```

1. 결과는 `gitlab-secrets-updated.json`이며, 이를 사용하여 Linux 패키지 인스턴스에서 `/etc/gitlab/gitlab-secrets.json`의 이전 버전을 바꿀 수 있습니다.
1. `/etc/gitlab/gitlab-secrets.json`을 바꾼 후 Linux 패키지 인스턴스를 다시 구성합니다:

   ```shell
   sudo gitlab-ctl reconfigure
   ```

1. Linux 패키지 인스턴스에서 [객체 저장소를 구성](https://docs.gitlab.com/administration/object_storage/)하고, LFS, 아티팩트, 업로드 등을 테스트하여 작동하는지 확인합니다.
1. 컨테이너 레지스트리를 사용하는 경우 [해당 객체 저장소를 별도로 구성](https://docs.gitlab.com/administration/packages/container_registry/#use-object-storage)합니다. 통합 객체 저장소를 지원하지 않습니다.
1. Helm 차트 인스턴스에 연결된 객체 저장소의 데이터를 Linux 패키지 인스턴스에 연결된 새 저장소와 동기화합니다. 몇 가지 주의 사항:

   - S3 호환 저장소의 경우 `s3cmd` 유틸리티를 사용하여 데이터를 복사합니다.
   - Linux 패키지 인스턴스에서 MinIO와 같은 S3 호환 객체 저장소를 사용하려는 경우 `/etc/gitlab/gitlab.rb`에서 `endpoint`을 MinIO로 가리키도록 구성하고 `path_style`을 `true`로 설정합니다.
   - 새 Linux 패키지 인스턴스에서 이전 객체 저장소를 다시 사용할 수 있습니다. 이 경우 두 객체 저장소 간의 데이터를 동기화할 필요가 없습니다. 그러나 기본 제공 MinIO 인스턴스를 사용하는 경우 GitLab Helm 차트를 제거할 때 저장소가 프로비전 해제될 수 있습니다.

1. GitLab Helm 백업을 Linux 패키지 GitLab 인스턴스의 `/var/opt/gitlab/backups`로 복사하고 [복원을 수행](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations)합니다.
1. (선택 사항) Git SSH 클라이언트의 호스트 불일치 오류를 방지하도록 SSH 호스트 키를 복원합니다:

   1. [`<name>-gitlab-shell-host-keys` 시크릿](../secrets.md#ssh-host-keys)을 다음 스크립트를 사용하여 파일로 변환합니다(필수 도구: `jq`, `base64` 및 `kubectl`):

      ```shell
      mkdir ssh
      HOSTKEYS_JSON="hostkeys.json"
      GITLAB_NAMESPACE="my_namespace"
      kubectl get secret -n ${GITLAB_NAMESPACE} gitlab-gitlab-shell-host-keys -o json > ${HOSTKEYS_JSON}

      for k in $(jq -r '.data | keys | .[]' ${HOSTKEYS_JSON}); \
      do \
        jq -r --arg host_key ${k} '.data[$host_key]' ${HOSTKEYS_JSON}  | base64 --decode > ssh/$k ; \
      done
      ```

   1. 변환된 파일을 GitLab Rails 노드로 업로드합니다.
   1. 대상 Rails 노드에서:
      1. `/etc/ssh/` 디렉터리를 백업합니다(예시):

         ```shell
         sudo tar -czvf /root/ssh_dir.tar.gz -C /etc ssh
         ```

      1. 기존 호스트 키를 제거합니다:

         ```shell
         sudo find /etc/ssh -type f -name "/etc/ssh/ssh_*_key*" -delete
         ```

      1. 변환된 호스트 키 파일을 (`/etc/ssh`) 위치에 이동합니다:

         ```shell
         for f in ssh/*; do sudo install -b -D  -o root -g root -m 0600 $f /etc/${f} ; done
         ```

      1. SSH 데몬을 다시 시작합니다:

         ```shell
         sudo systemctl restart ssh.service
         ```

1. 복원이 완료된 후 [doctor Rake 작업](https://docs.gitlab.com/administration/raketasks/check/)을 실행하여 시크릿이 유효한지 확인합니다.
1. 모든 항목을 확인한 후 GitLab Helm 차트 인스턴스를 [제거](../uninstall.md)할 수 있습니다.
