---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 목표
---

이 이니셔티브의 핵심 목표는 다음과 같습니다:

1. 수평으로 쉽게 확장 가능
1. 쉬운 배포, 업그레이드, 유지 관리
1. 클라우드 서비스 공급자의 광범위한 지원
1. Kubernetes 및 Helm에 대한 초기 지원, 향후 다른 스케줄러를 지원할 수 있는 유연성

## 스케줄러 {#scheduler}

업계 전반에서 성숙하고 널리 지원되는 Kubernetes에 대한 지원으로 시작할 것입니다. 하지만 우리는 설계 과정에서 다른 스케줄러에 대한 지원을 방해할 수 있는 결정을 피하도록 노력할 것입니다. 이는 특히 OpenShift 및 Tectonic과 같은 다운스트림 Kubernetes 프로젝트에 해당합니다. 향후 Docker Swarm 및 Mesosphere와 같은 다른 스케줄러도 지원될 수 있습니다.

우리는 Kubernetes의 확장 및 자체 복구 기능을 지원하는 것을 목표로 합니다:

- 준비 상태 및 상태 확인을 통해 Pod가 제대로 작동하는지 확인하고, 그렇지 않으면 재활용합니다
- 카나리 및 롤링 배포를 지원하는 트랙
- [자동 확장](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

우리는 표준 Kubernetes 기능을 활용하려고 노력할 것입니다:

- 구성 관리를 위한 ConfigMaps. 이를 Docker 컨테이너에 매핑하거나 전달합니다
- 민감한 데이터를 위한 시크릿

Consul도 사용할 수 있으므로, 다른 설치 방법과의 일관성을 위해 이를 대신 사용할 수 있습니다.

## Helm 차트 {#helm-charts}

<!-- vale gitlab_base.SubstitutionWarning = NO -->

각 GitLab 특정 컨테이너/서비스의 배포를 관리하기 위한 Helm 차트가 생성될 것입니다. 우리는 또한 번들된 차트를 포함하여 전체 배포를 더 쉽게 만들 것입니다. 이는 모든 기능이 포함된 Omnibus 기반 솔루션보다 Docker 및 Kubernetes 레이어에서 훨씬 더 복잡하기 때문에 이 작업에 특히 중요합니다. Helm은 이 복잡성을 관리하고 `values.yaml` 파일을 통해 설정을 관리할 수 있는 쉬운 최상위 인터페이스를 제공할 수 있습니다.

우리는 3단계 Helm 차트 세트를 제공할 계획입니다:

![Helm 차트 구조](../images/charts.png)
