---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 아키텍처
---

3가지 계층의 컴포넌트를 지원할 계획입니다:

1. Docker 컨테이너
1. 스케줄러(Kubernetes)
1. 상위 수준 구성 도구(Helm)

고객이 설치할 때 사용할 주요 방법은 이 저장소의 [Helm 차트](https://helm.sh/)입니다. 향후 Amazon CloudFormation 또는 Docker Swarm과 같은 다른 배포 방법도 제공할 수 있습니다.

## Docker 컨테이너 이미지 {#docker-container-images}

기초로서 각 서비스에 대한 Docker 컨테이너를 만들 것입니다. 이를 통해 더 쉬운 수평 확장과 감소된 이미지 크기 및 복잡성을 가능하게 합니다. 구성은 Docker를 위해 표준 방식으로 전달되어야 하며, 환경 변수 또는 마운트된 파일일 수 있습니다. 이는 스케줄러 소프트웨어와의 깔끔한 공통 인터페이스를 제공합니다.

### GitLab Docker 이미지 {#gitlab-docker-images}

GitLab 애플리케이션은 GitLab 특정 서비스를 포함하는 Docker 이미지를 사용하여 구축됩니다. 이러한 이미지의 빌드 환경은 [CNG 저장소](https://gitlab.com/gitlab-org/build/CNG)에서 찾을 수 있습니다.

다음 GitLab 컴포넌트는 CNG 저장소에 이미지를 가지고 있습니다.

- Gitaly
- GitLab Elasticsearch 인덱서
- [mail_room](https://github.com/tpitale/mail_room)
- GitLab Exporter
- GitLab Shell
- Sidekiq
- GitLab Toolbox
- Webservice
- Workhorse

다음은 GitLab 특정 Docker 이미지를 사용하는 포크된 차트입니다.

`initContainers`과 다양한 `Job`에 사용되는 Docker 이미지입니다.

- alpine-certificates
- kubectl

### 공식 Docker 이미지 {#official-docker-images}

기본 서비스를 위해 다음의 기존 공식 컨테이너를 활용합니다:

- Docker 배포([Docker Registry 2.0](https://github.com/distribution/distribution))
- Prometheus
- NGINX Ingress
- cert-manager
- Redis
- PostgreSQL

## GitLab 차트 {#the-gitlab-chart}

이것은 최상위 수준의 GitLab 차트(`gitlab`)이며, GitLab의 완전한 구성을 위한 모든 필요한 리소스를 구성합니다. 여기에는 GitLab, PostgreSQL, Redis, Ingress 및 인증서 관리 차트가 포함됩니다.

이 높은 수준에서 고객은 다음과 같은 결정을 할 수 있습니다:

- 포함된 PostgreSQL 차트를 사용할지 또는 Amazon RDS for PostgreSQL과 같은 외부 데이터베이스를 사용할지 여부.
- 자신의 SSL 인증서를 가져오거나 Let's Encrypt를 활용할 여부.
- 로드 밸런서 또는 전용 Ingress를 사용할 여부.

빠르고 쉽게 시작하고 싶은 고객은 이 차트로 시작해야 합니다.

### 이러한 차트의 구조 {#structure-of-these-charts}

주요 GitLab 차트는 여러 다른 차트로 이루어진 개요 차트입니다. 각 하위 차트는 개별적으로 문서화되며, [charts](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts) 디렉토리 구조와 일치하는 구조로 배치됩니다.

비 GitLab 컴포넌트는 최상위 수준에서 패키징 및 문서화됩니다. GitLab 컴포넌트 서비스는 [GitLab](../charts/gitlab/_index.md) 차트 아래에 문서화됩니다:

- [NGINX](../charts/nginx/_index.md)
- [MinIO](../charts/minio/_index.md)
- [Registry](../charts/registry/_index.md)
- GitLab/[Gitaly](../charts/gitlab/gitaly/_index.md)
- GitLab/[GitLab Exporter](../charts/gitlab/gitlab-exporter/_index.md)
- GitLab/[GitLab Shell](../charts/gitlab/gitlab-shell/_index.md)
- GitLab/[Migrations](../charts/gitlab/migrations/_index.md)
- GitLab/[Sidekiq](../charts/gitlab/sidekiq/_index.md)
- GitLab/[Webservice](../charts/gitlab/webservice/_index.md)

### 컴포넌트 목록 {#components-list}

차트를 사용할 때 배포되는 컴포넌트 목록과 필요한 경우 구성 지침은 [아키텍처 컴포넌트 목록](https://docs.gitlab.com/development/architecture/#component-list) 페이지에서 확인할 수 있습니다.

## 설계 결정 {#design-decisions}

이러한 차트의 아키텍처에 대해 내린 결정에 대한 문서는 [설계 결정](decisions.md) 문서에서 찾을 수 있습니다.
