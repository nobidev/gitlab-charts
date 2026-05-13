---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Helm을 사용하여 GitLab 설치
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공 방식:  GitLab Self-Managed

{{< /details >}}

클라우드 네이티브 GitLab Helm 차트를 사용하여 Kubernetes에 GitLab을 설치합니다.

[필수 구성 요소](tools.md)를 이미 설치하고 구성했다면 `helm` 명령을 사용하여 [GitLab을 배포](deployment.md)할 수 있습니다.

> [!note] GitLab Helm 차트는 외부 PostgreSQL, Redis 및 오브젝트 스토리지가 필요합니다. 프로덕션 환경의 경우 [클라우드 네이티브 하이브리드 참조 아키텍처](#use-the-reference-architectures)를 따르세요.

프로덕션 배포의 경우 Kubernetes에 대한 강력한 실무 지식이 필요합니다. 이 배포 방법은 전통적인 배포와 다른 관리, 관찰성 및 개념을 가지고 있습니다.

프로덕션 배포에서:

- PostgreSQL 및 Redis는 PaaS 또는 컴퓨팅 인스턴스에서 클러스터 외부에서 실행되어야 합니다. 이 구성은 프로덕션 GitLab 환경에서 발견되는 다양한 워크로드를 확장하고 안정적으로 처리하는 데 필요합니다.
- 모든 비 Git 저장소 스토리지를 위해 Cloud PaaS를 PostgreSQL, Redis 및 오브젝트 스토리지에 사용해야 합니다.

GitLab 인스턴스에 Kubernetes가 필요하지 않은 경우 더 간단한 대안을 위해 [참조 아키텍처](https://docs.gitlab.com/administration/reference_architectures/)를 참조하세요.

## 컨테이너 이미지 {#container-images}

GitLab Helm 차트는 [클라우드 네이티브 GitLab (CNG)](https://gitlab.com/gitlab-org/build/CNG) 컨테이너 이미지를 사용하여 GitLab을 배포합니다. GitLab 자체를 위한 CNG 이미지 외에도 기본 구성은 비프로덕션 배포에서 오브젝트 스토리지를 위해 MinIO를 사용합니다.

외부 PostgreSQL, Redis 및 오브젝트 스토리지가 필요합니다. 차트를 외부 서비스를 사용하도록 구성하는 방법에 대한 지침은 다음 설명서를 참조하세요.

1. [외부 데이터베이스](../advanced/external-db/_index.md)
1. [외부 Redis](../advanced/external-redis/_index.md)
1. [외부 오브젝트 스토리지](../advanced/external-object-storage/_index.md)

## 외부 상태 저장 데이터를 사용하도록 Helm 차트 구성 {#configure-the-helm-chart-to-use-external-stateful-data}

선택한 [참조 아키텍처](https://docs.gitlab.com/administration/reference_architectures/)와 일치하는 외부 오브젝트 스토리지, Redis, PostgreSQL 및 Gitaly 서비스를 가리키도록 차트를 구성합니다.

### 참조 아키텍처 사용 {#use-the-reference-architectures}

Kubernetes에 GitLab 인스턴스를 배포하기 위한 참조 아키텍처를 [클라우드 네이티브 하이브리드](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid)라고 부르는 이유는 프로덕션 수준의 구현을 위해 모든 GitLab 서비스가 클러스터에서 실행될 수 없기 때문입니다. 모든 상태 저장 GitLab 구성 요소는 Kubernetes 클러스터 외부에 배포되어야 합니다.

사용 가능한 클라우드 네이티브 하이브리드 참조 아키텍처 크기는 [참조 아키텍처](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid) 페이지에 나열되어 있습니다. 예를 들어 3,000명 사용자 기준의 [클라우드 네이티브 하이브리드 참조 아키텍처](https://docs.gitlab.com/administration/reference_architectures/3k_users/#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative)는 다음과 같습니다.

### 인프라스트럭처 코드(IaC) 및 빌더 리소스 사용 {#use-infrastructure-as-code-iac-and-builder-resources}

GitLab은 Helm 차트와 추가 클라우드 인프라 조합을 구성할 수 있는 인프라스트럭처 코드를 개발합니다:

- [GitLab Environment Toolkit IaC](https://gitlab.com/gitlab-org/gitlab-environment-toolkit).
- [구현 패턴: AWS EKS에서 GitLab 클라우드 네이티브 하이브리드 프로비저닝](https://docs.gitlab.com/solutions/cloud/aws/gitlab_instance_on_aws/):  이 리소스는 GitLab Performance Toolkit으로 테스트된 Bill of Materials를 제공하고 예산 책정을 위해 AWS Cost Calculator를 사용합니다.

## 무중단 업그레이드 {#zero-downtime-upgrades}

무중단 업그레이드를 통해 서비스 중단 없이 GitLab을 업그레이드할 수 있습니다. 이 기능을 활성화하려면 초기 설치 중에 롤링 업데이트 전략을 구성해야 합니다. 나중에 기존 배포에 이러한 설정을 추가하면 Pod 재시작이 트리거되고 짧은 다운타임이 발생할 수 있습니다.

> [!warning] 업그레이드의 일부로 무중단을 달성하는 것은 분산 애플리케이션의 경우 특히 어렵습니다. 이 문서는 우리의 HA 참조 아키텍처와 비교하여 주어진 대로 테스트되었으며 효과적으로 관찰 가능한 다운타임이 없었습니다. 그러나 특정 시스템 구성에 따라 결과가 다를 수 있다는 점을 유의하세요.
>
> 업그레이드 중에 사용자는 요청이 다양한 버전을 실행하는 Pod 간에 라우팅될 때 UI 불일치 또는 자산에 대한 HTTP 404 오류를 일시적으로 경험할 수 있으며, 이러한 문제는 보통 페이지 새로 고침으로 해결됩니다.

무중단 업그레이드를 위해 배포를 구성하려면 [권장 배포 설정](upgrade.md#recommended-deployment-settings)의 롤링 업데이트 설정을 포함해야 합니다.

완전한 업그레이드 절차는 [무중단 업그레이드](upgrade.md#upgrade-with-zero-downtime) 설명서를 참조하세요.
