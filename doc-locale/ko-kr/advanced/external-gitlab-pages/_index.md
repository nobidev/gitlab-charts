---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 GitLab Pages를 사용하여 GitLab 차트 구성하기
---

이 문서는 Linux 패키지를 사용하여 클러스터 외부에서 구성된 GitLab Pages 인스턴스를 사용하여 Helm 차트를 구성하는 방법에 대한 문서를 제공하기 위한 것입니다. [Issue 418259](https://gitlab.com/gitlab-org/gitlab/-/issues/418259)는 Helm 차트를 사용하여 외부 GitLab Pages가 있는 Linux 패키지 인스턴스에 대한 문서 추가를 제안합니다.

## 요구 사항 {#requirements}

1. 프로덕션 인스턴스에 권장되는 [External Object Storage](../external-object-storage/_index.md)를 사용해야 합니다.
1. GitLab Pages와 상호 작용하기 위해 Pages용으로 Base64로 인코딩된 32바이트 길이의 API 시크릿 키입니다.

## 알려진 제한 사항 {#known-limitations}

1. [GitLab Pages Access Control](https://docs.gitlab.com/user/project/pages/pages_access_control/)은 기본적으로 지원되지 않습니다.

## 외부 GitLab Pages 인스턴스 구성 {#configure-external-gitlab-pages-instance}

1. Linux 패키지를 사용하여 [GitLab 설치](https://about.gitlab.com/install/)합니다.

1. `/etc/gitlab/gitlab.rb` 파일을 편집하고 다음 스니펫으로 내용을 바꿉니다. 아래 값을 구성에 맞게 업데이트하세요:

   ```ruby
   roles ['pages_role']

   # Root domain where Pages will be served.
   pages_external_url '<Pages root domain>'  # Example: 'http://pages.example.io'

   # Information regarding GitLab instance
   gitlab_pages['gitlab_server'] = '<GitLab URL>'  # Example: 'https://gitlab.example.com'
   gitlab_pages['api_secret_key'] = '<Base64 encoded form of API secret key>'
   ```

1. `sudo gitlab-ctl reconfigure`을 실행하여 변경 사항을 적용합니다.

## 차트 구성 {#configure-the-chart}

1. Pages 배포를 저장하기 위해 객체 스토리지에서 `gitlab-pages`이라는 버킷을 만듭니다.

1. API 시크릿 키의 Base64 인코딩 형식을 값으로 사용하여 `gitlab-pages-api-key` 시크릿을 만듭니다.

   ```shell
   kubectl create secret generic gitlab-pages-api-key --from-literal="shared_secret=<Base 64 encoded API Secret Key>"
   ```

1. 다음 구성 스니펫을 참조하고 값 파일에 필요한 항목을 추가하세요.

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

   > [!note] `PAGES_UPDATE_LEGACY_STORAGE` 환경 변수를 true로 설정하면 `pages_update_legacy_storage` 기능 플래그가 활성화되어 Pages가 로컬 디스크에 배포됩니다. 객체 스토리지로 마이그레이션할 때 이 변수를 제거하는 것을 잊지 마세요.

1. 이 구성을 사용하여 [차트 배포](../../installation/deployment.md#deploy-using-helm)합니다.
