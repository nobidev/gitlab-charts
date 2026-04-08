---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Helm을 사용한 GitLab 설치
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

클라우드 네이티브 GitLab Helm 차트를 사용하여 Kubernetes에 GitLab을 설치합니다.

[사전 요구 사항](tools.md)을 이미 설치하고 구성한 경우,
`helm` 명령어로 [GitLab을 배포](deployment.md)할 수 있습니다.

> [!note]
> GitLab Helm 차트는 프로덕션 배포 시 외부 PostgreSQL, Redis, 오브젝트 스토리지가 필요합니다.
> 번들로 포함된 서비스는 평가 목적으로만 제공됩니다.
> 프로덕션 환경에서는 [클라우드 네이티브 하이브리드 레퍼런스 아키텍처](#레퍼런스-아키텍처-사용)를 따르십시오.

프로덕션 배포를 위해서는 Kubernetes에 대한 충분한 실무 지식이 필요합니다.
이 배포 방식은 기존 배포와 관리, 관측 가능성, 개념이 다릅니다.

프로덕션 배포 시:

- PostgreSQL, Redis, Gitaly(Git 리포지토리 스토리지 데이터 플레인)와 같은 상태 저장(stateful) 컴포넌트는
  클러스터 외부의 PaaS 또는 컴퓨팅 인스턴스에서 실행해야 합니다. 프로덕션 GitLab 환경의 다양한 워크로드를
  안정적으로 처리하고 확장하려면 이 구성이 필요합니다.
- Git 리포지토리 스토리지를 제외한 모든 스토리지에는 Cloud PaaS의 PostgreSQL, Redis, 오브젝트 스토리지를 사용해야 합니다.

GitLab 인스턴스에 Kubernetes가 필요하지 않은 경우,
[레퍼런스 아키텍처](https://docs.gitlab.com/administration/reference_architectures/)에서
더 간단한 대안을 확인할 수 있습니다.

## 컨테이너 이미지

GitLab Helm 차트는 [Cloud Native GitLab(CNG)](https://gitlab.com/gitlab-org/build/CNG)
컨테이너 이미지를 사용하여 GitLab을 배포합니다. GitLab용 CNG 이미지 외에도 기본 구성에서는
서드파티(예: Bitnami)가 게시한 이미지를 사용하여 PostgreSQL, Redis, MinIO를 배포하며,
비프로덕션 배포를 간소화합니다.

위에서 언급한 대로, 프로덕션 인스턴스에서는 이러한 서드파티 상태 저장(stateful) 서비스를
GitLab 차트로 배포하지 않아야 합니다.

차트에서 외부 서비스를 사용하도록 구성하는 방법은 다음 문서를 참조하십시오.

1. [외부 데이터베이스](../advanced/external-db/_index.md)
1. [외부 Redis](../advanced/external-redis/_index.md)
1. [외부 오브젝트 스토리지](../advanced/external-object-storage/_index.md)

> [!note]
> 2024년 12월부터 [Bitnami가 빌드 정책을 변경](https://github.com/bitnami/containers/issues/75671)하여
> 무료 카탈로그에서는 각 애플리케이션의 최신 안정 메이저 버전만 업데이트합니다. GitLab 차트는
> 계속해서 공개적으로 사용 가능한 이미지를 기본으로 사용합니다.
>
> 2025년 7월, [Bitnami는](https://github.com/bitnami/containers/issues/75671) 보안이 강화되고
> 버전이 관리되는 차트 및 이미지에 액세스하려면 유료 서비스인 Bitnami Secure Images 구독이
> 필요하다고 발표했습니다.
>
> 이에 따라 GitLab에서 구성한 Bitnami 차트 버전은 점차 오래된 버전이 됩니다.
> 비프로덕션 용도로 이러한 Bitnami 차트를 배포하는 팀은 보안 요구 사항에 맞는
> 최신 패치 이미지를 사용해야 합니다.
>
> GitLab 19.0부터 GitLab Helm 차트는 라이선스, 프로젝트 유지 관리, 공개 이미지 가용성의
> 변경으로 인해 Bitnami 차트를 더 이상 번들로 포함하지 않습니다.
>
> 자세한 내용은
> [지원 중단 공지](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart)를
> 참조하고, 외부 대안으로 [마이그레이션](migration/bundled_chart_migration.md)하십시오.

## 외부 상태 저장 데이터를 사용하도록 Helm 차트 구성

프로덕션 수준의 배포에서는 선택한 [레퍼런스 아키텍처](https://docs.gitlab.com/administration/reference_architectures/)에 맞는
외부 오브젝트 스토리지, Valkey/Redis, PostgreSQL, Gitaly 서비스를 가리키도록 차트를 구성해야 합니다.

개념 검증 및 테스트 목적으로 GitLab Helm 차트에는 MinIO, Bitnami PostgreSQL, Bitnami Redis 차트가
번들로 포함되어 있습니다. 그러나 프로젝트 및 라이선스 관련 변경으로 인해 이러한 차트의 번들 포함은
지원 중단되었으며, GitLab 19.0에서 제거될 예정입니다.

자세한 내용은
[지원 중단 공지](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart)를
참조하고, 외부 대안으로 [마이그레이션](migration/bundled_chart_migration.md)하십시오.

### 레퍼런스 아키텍처 사용

Kubernetes에 GitLab 인스턴스를 배포하기 위한 레퍼런스 아키텍처는 [클라우드 네이티브 하이브리드](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid)라고 합니다. 프로덕션 수준의 구현에서는 모든 GitLab 서비스를 클러스터 내에서 실행할 수 없기 때문입니다. 모든 상태 저장 GitLab 컴포넌트는 Kubernetes 클러스터 외부에 배포해야 합니다.

사용 가능한 클라우드 네이티브 하이브리드 레퍼런스 아키텍처 규모는
[레퍼런스 아키텍처](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid) 페이지에서 확인할 수 있습니다.
예를 들어, 3,000명 사용자 규모의 [클라우드 네이티브 하이브리드 레퍼런스 아키텍처](https://docs.gitlab.com/administration/reference_architectures/3k_users/#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative)를 참조하십시오.

### Infrastructure as Code(IaC) 및 빌더 리소스 사용

GitLab은 Helm 차트와 보조 클라우드 인프라의 조합을 구성할 수 있는 Infrastructure as Code를 개발합니다:

- [GitLab Environment Toolkit IaC](https://gitlab.com/gitlab-org/gitlab-environment-toolkit).
- [구현 패턴: AWS EKS에서 GitLab 클라우드 네이티브 하이브리드 프로비저닝](https://docs.gitlab.com/solutions/cloud/aws/gitlab_instance_on_aws/):
  이 리소스는 GitLab Performance Toolkit으로 테스트된 자재 명세서(BOM)를 제공하며,
  예산 산정을 위해 AWS 비용 계산기를 사용합니다.

## 무중단 업그레이드

무중단 업그레이드를 사용하면 서비스 중단 없이 GitLab을 업그레이드할 수 있습니다. 이 기능을 활성화하려면 초기 설치 시 롤링 업데이트 전략을 구성해야 합니다. 기존 배포에 나중에 이 설정을 추가하면 파드가 재시작되어 짧은 다운타임이 발생할 수 있습니다.

> [!warning]
> 분산 애플리케이션에서 업그레이드 중 완전한 무중단을 달성하는 것은 매우 어렵습니다. 이 문서는 고가용성(HA) 레퍼런스 아키텍처에서 테스트되었으며, 사실상 관측 가능한 다운타임이 없었습니다. 그러나 시스템 구성에 따라 결과가 달라질 수 있습니다.
>
> 업그레이드 중에 요청이 서로 다른 버전을 실행하는 파드 간에 라우팅되면서 UI 불일치 또는 정적 리소스에 대한 HTTP 404 오류가 일시적으로 발생할 수 있습니다. 이러한 문제는 일반적으로 페이지를 새로고침하면 해결됩니다.

무중단 업그레이드를 위해 배포를 구성하려면 [권장 배포 설정](upgrade.md#recommended-deployment-settings)의 롤링 업데이트 설정을 포함해야 합니다.

전체 업그레이드 절차는 [무중단 업그레이드](upgrade.md#upgrade-with-zero-downtime) 문서를 참조하십시오.
