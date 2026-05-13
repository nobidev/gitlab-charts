---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트의 클라우드 공급자 설정
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab 차트를 배포하기 전에 선택한 클라우드 공급자를 위한 리소스를 구성해야 합니다.

GitLab 차트는 최소 8개의 vCPU와 30GB RAM을 가진 클러스터에 맞도록 설계되었습니다. 비프로덕션 인스턴스를 배포하려는 경우 기본값을 줄여서 더 작은 클러스터에 맞출 수 있습니다.

## 지원되는 Kubernetes 릴리스 {#supported-kubernetes-releases}

GitLab Helm 차트는 다음 Kubernetes 릴리스를 지원합니다:

| Kubernetes 릴리스 | 상태      | 최소 GitLab 버전 |
|--------------------|-------------|------------------------|
| 1.35               | 지원됨   | 18.9                   |
| 1.34               | 지원됨   | 18.6                   |
| 1.33               | 지원됨   | 18.1                   |
| 1.32               | 더 이상 지원되지 않음  | 17.11                  |
| 1.31               | 지원되지 않음 | 17.6                   |

GitLab Helm 차트는 한 번에 3개의 Kubernetes 마이너 버전을 지원하고 초기 릴리스 후 3개월 후에 새로운 Kubernetes 릴리스를 지원할 계획입니다.

자세한 내용은 [Kubernetes 지원 정책을 참조하세요](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/systems/distribution/k8s-release-support-policy/).

위에 나열된 릴리스보다 최신인 릴리스의 호환성 문제에 대해 [이슈 추적기](https://gitlab.com/gitlab-org/charts/gitlab/-/issues)에 보고해주시기 바랍니다.

일부 GitLab 기능은 더 이상 지원되지 않는 릴리스 또는 위에 나열된 릴리스보다 오래된 릴리스에서 작동하지 않을 수 있습니다.

일부 구성 요소(예: [Kubernetes용 에이전트](https://docs.gitlab.com/user/clusters/agent/) 및 [GitLab Operator](https://docs.gitlab.com/operator/installation/))의 경우 GitLab은 다양한 클러스터 릴리스를 지원할 수 있습니다.

> [!warning] [GitLab 컨테이너 이미지](../_index.md#container-images)는 x86-64 및 ARM64 아키텍처에 배포할 수 있습니다. FIPS 검증 이미지는 x86-64에서만 사용할 수 있습니다. ARM64 FIPS 상태는 [이슈 2285](https://gitlab.com/gitlab-org/build/CNG/-/issues/2285)를 참조하세요.

- 환경에 대한 클러스터 토폴로지 권장사항은 [참조 아키텍처](https://docs.gitlab.com/administration/reference_architectures/#available-reference-architectures)를 참조하세요.
- 3개의 vCPU 12GB 클러스터에 맞도록 리소스를 조정하는 예제는 [최소 GKE 예제 값 파일](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-gke-minimum.yaml)을 참조하세요.

## 특정 클라우드 공급자를 위한 지침 {#instructions-for-specific-cloud-providers}

사용자 환경에서 Kubernetes 클러스터를 생성하고 연결하세요:

- [Azure Kubernetes Service](aks.md)
- [Amazon EKS](eks.md)
- [Google Kubernetes Engine](gke.md)
- [OpenShift](openshift.md)
- [Oracle Container Engine for Kubernetes](oke.md)
