---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Runner 차트 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

GitLab Runner 서브차트는 CI 작업을 실행하기 위한 GitLab Runner를 제공합니다. 기본적으로 활성화되어 있으며 S3 호환 객체 저장소를 사용한 캐싱 지원과 함께 즉시 사용할 수 있습니다.

> [!note] 번들로 제공되는 GitLab Runner는 평가 목적으로만 제공됩니다. 프로덕션 배포의 경우 [보안 및 성능상의 이유로](https://docs.gitlab.com/install/requirements/#gitlab-runner) GitLab Runner를 별도의 머신에 설치하세요. 자세한 정보는 [참조 아키텍처 설명서](../../../installation/_index.md#use-the-reference-architectures)를 참조하세요.

## 요구 사항 {#requirements}

GitLab 16.0에서는 runner 인증 토큰을 사용하여 runner를 등록하는 새로운 runner 생성 워크플로우를 도입했습니다. 등록 토큰을 사용하는 레거시 워크플로우는 더 이상 지원되지 않으며 GitLab 17.0에서 기본적으로 비활성화됩니다. GitLab 18.0에서 제거될 예정입니다.

권장 워크플로우를 사용하려면:

- [인증 토큰을 생성합니다.](https://docs.gitlab.com/ci/runners/new_creation_workflow/#prevent-your-runner-registration-workflow-from-breaking)
- 구성이 [`shared-secrets`](../../shared-secrets.md) 작업으로 처리되지 않으므로 runner secret(`<release>-gitlab-runner-secret`)을 수동으로 업데이트하세요.
- `gitlab-runner.runners.locked`을(를) `null`(으)로 설정하세요:

  ```yaml
  gitlab-runner:
    runners:
      locked: null
  ```

레거시 워크플로우를 사용하려는 경우(권장하지 않음):

- [레거시 워크플로우를 다시 활성화](https://docs.gitlab.com/administration/settings/continuous_integration/#enable-runner-registrations-tokens)해야 합니다.
- 등록 토큰은 [`shared-secrets`](../../shared-secrets.md) Job으로 채워집니다.
- GitLab 18.0 이전에 새 워크플로우로 마이그레이션해야 합니다. GitLab 18.0에서는 레거시 워크플로우에 대한 지원이 제거됩니다.

## 구성 {#configuration}

자세한 정보는 [사용 및 구성](https://docs.gitlab.com/runner/install/kubernetes/)에 대한 설명서를 참조하세요.

## 독립 실행형 runner 배포 {#deploying-a-stand-alone-runner}

기본적으로 `gitlabUrl`을(를) 추론하고 등록 토큰을 자동으로 생성한 후 `migrations` 차트를 통해 생성합니다. 이 동작은 실행 중인 GitLab 인스턴스와 함께 배포하려는 경우에는 작동하지 않습니다.

이 경우 `gitlabUrl` 값을 실행 중인 GitLab 인스턴스의 URL로 설정해야 합니다. 실행 중인 GitLab에서 제공하는 `registrationToken`으로 `gitlab-runner` secret을 수동으로 생성하고 채워야 합니다.

## Docker-in-Docker 사용 {#using-docker-in-docker}

Docker-in-Docker를 실행하려면 runner 컨테이너가 필요한 기능에 액세스할 수 있도록 권한을 가져야 합니다. `privileged` 값을 `true`(으)로 설정하면 활성화됩니다. 이것이 `true`(으)로 기본 설정되지 않는 이유에 대해서는 [업스트림 설명서](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#use-privileged-containers-for-the-runners)를 참조하세요.

### 보안 고려사항 {#security-concerns}

권한이 있는 컨테이너는 확장된 기능을 가지고 있으며, 예를 들어 실행되는 호스트에서 임의의 파일을 마운트할 수 있습니다. 컨테이너가 격리된 환경에서 실행되는지 확인하여 중요한 것이 옆에서 실행되지 않도록 하세요.

## 기본 runner 구성 {#default-runner-configuration}

GitLab 차트에 사용된 기본 runner 구성은 기본적으로 포함된 MinIO를 캐시로 사용하도록 사용자 지정되었습니다. runner `config` 값을 설정하는 경우 자신의 캐시 구성도 구성해야 합니다.

```yaml
gitlab-runner:
  runners:
    config: |
      [[runners]]
        [runners.kubernetes]
        image = "ubuntu:22.04"
        {{- if .Values.global.minio.enabled }}
        [runners.cache]
          Type = "s3"
          Path = "gitlab-runner"
          Shared = true
          [runners.cache.s3]
            ServerAddress = {{ include "gitlab-runner.cache-tpl.s3ServerAddress" . }}
            BucketName = "runner-cache"
            BucketLocation = "us-east-1"
            Insecure = false
        {{ end }}
```

모든 사용자 지정 GitLab Runner 차트 구성은 [최상위 수준 `values.yaml` 파일](https://gitlab.com/gitlab-org/charts/gitlab/raw/master/values.yaml)에서 `gitlab-runner` 키 아래에 있습니다.
