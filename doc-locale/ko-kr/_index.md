---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Helm 차트
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

클라우드 네이티브 버전의 GitLab을 설치하려면 GitLab Helm 차트를 사용하세요. 이 차트는 시작하는 데 필요한 모든 구성 요소를 포함하며 대규모 배포로 확장할 수 있습니다.

OpenShift 기반 설치의 경우 [GitLab Operator](https://docs.gitlab.com/operator/) 를 사용하고, 그렇지 않으면 [보안 컨텍스트 제약](https://docs.gitlab.com/operator/security_context_constraints/)을 직접 업데이트해야 합니다.

> [!note]
> GitLab Helm 차트는 프로덕션 배포를 위해 외부 PostgreSQL, Redis 및 객체 저장소가 필요합니다. 이러한 서비스의 번들 버전은 평가 목적으로만 포함됩니다. 프로덕션의 경우 [클라우드 네이티브 하이브리드 참조 아키텍처](installation/_index.md#use-the-reference-architectures)를 따르세요.

프로덕션 배포의 경우 Kubernetes에 대한 강력한 실무 지식이 있어야 합니다. 이 배포 방법은 전통적인 배포와 다른 관리, 관찰성 및 개념을 가지고 있습니다.

GitLab Helm 차트는 여러 [서브차트](charts/gitlab/_index.md)로 구성되며, 각각을 별도로 설치할 수 있습니다.

## 자세히 알아보기 {#learn-more}

- [GKE 또는 EKS에서 GitLab 차트 테스트](quickstart/_index.md)
- [Linux 패키지에서 GitLab 차트로 마이그레이션](installation/migration/_index.md)
- [배포 준비](installation/_index.md)
- [배포](installation/deployment.md)
- [배포 옵션 보기](installation/command-line-options.md)
- [글로벌 구성](charts/globals.md)
- [서브차트 보기](charts/gitlab/_index.md)
- [고급 구성 옵션 보기](advanced/_index.md)
- [아키텍처 결정 보기](architecture/_index.md)
- [개발자 문서](development/_index.md) 와 [기여 지침](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/CONTRIBUTING.md)을 보면서 개발에 기여하세요
- [이슈](https://gitlab.com/gitlab-org/charts/gitlab/-/issues) 생성
- [병합 요청](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests) 생성
- [문제 해결](troubleshooting/_index.md) 정보 보기
