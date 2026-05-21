---
stage: GitLab Duo Self-Hosted
group: Custom models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AI Gateway 차트
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab Self-Managed
- 상태:  실험

{{< /details >}}

AI Gateway 차트는 AI Gateway를 GitLab 인스턴스와 함께 하위 차트로 배포합니다. 이것은 Kubernetes에서 GitLab Duo Self-Hosted 및 GitLab Duo Agent Platform을 활성화합니다. 이 기능은 [실험](https://docs.gitlab.com/ee/policy/experiment-beta-support.html)입니다.

전제 조건:

- GitLab URL에는 TLS이 필요합니다. 프로덕션 모드에서 AI 게이트웨이는 GitLab 인스턴스에 대한 인증을 수행하기 위해 GitLab 엔드포인트가 보호되어야 합니다. 이 구성은 기본적으로 올바르게 설정되므로 조치가 필요하지 않습니다.
- 다음 중 하나:
  - [사용량 청구](https://docs.gitlab.com/subscriptions/gitlab_credits/)가 활성화된 클라우드 라이선스가 적용됨.
  - [GitLab Duo Agent Platform Self-Hosted](https://docs.gitlab.com/subscriptions/subscription-add-ons/#gitlab-duo-agent-platform-self-hosted) 추가 기능이 포함된 오프라인 라이선스.

## 알려진 문제 {#known-issues}

AI Gateway에 대해 TLS이 활성화되지 않았습니다. AI Gateway 서비스로의 내부 트래픽이 보호되지 않습니다. 이 서비스는 외부에서 접근할 수 없으므로 이 알려진 문제는 문제가 되지 않을 것으로 예상됩니다.

## 차트 구성 및 배포 {#configure-and-deploy-the-chart}

차트를 구성하고 배포하려면:

1. 다음 구성으로 차트를 배포합니다:

   ```yaml
   global:
     hosts:
       domain: <YOUR_DOMAIN>

   ai-gateway:
     install: true
   ```

1. 차트가 배포되고 인스턴스를 사용할 수 있게 되면 GitLab 인스턴스의 오른쪽 상단 모서리에서 **운영자**를 선택합니다.
1. 왼쪽 사이드바에서 **GitLab Duo**를 선택합니다.
1. **구성 변경**을 선택하고:
   1. **로컬 AI 게이트웨이 URL**을 `http://<RELEASE_NAME>-ai-gateway`로 변경합니다.
   1. **GitLab Duo Agent Platform 서비스의 로컬 URL**을 `<RELEASE_NAME>-ai-gateway:50052`로 변경합니다.
   1. **GitLab Duo Agent 플랫폼 서비스에 TLS를 사용하세요**를 선택 취소합니다.
   1. 오프라인 라이선스를 사용 중인 경우 **코드 제안** 및 **GitLab Duo 에이전트 플랫폼** 기능에 대한 모델을 선택했는지 확인하세요. 자세한 내용은 [GitLab을 자체 호스팅 모델을 사용하도록 구성](https://docs.gitlab.com/administration/gitlab_duo_self_hosted/configure_duo_features/)을 참조하세요.
1. **변경사항 저장**을 선택합니다.
1. **GitLab Duo** 페이지(`/admin/gitlab_duo`)에서 **헬스 체크 실행**을 선택하여 모든 것이 올바르게 작동하는지 확인합니다.
