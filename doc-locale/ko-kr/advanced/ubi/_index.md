---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: UBI 기반 이미지로 GitLab 차트 구성
---

GitLab은 [Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) 버전의 이미지를 제공하여 표준 이미지를 UBI 기반 이미지로 대체할 수 있습니다. 이러한 이미지는 표준 이미지와 동일한 태그에 `-ubi` 확장자를 사용합니다.

> [!note]
> GitLab 17.3 이전의 UBI 기반 이미지는 `-ubi8` 확장자를 사용합니다.

GitLab 차트는 UBI를 기반으로 하지 않는 타사 이미지를 사용합니다. 이러한 이미지는 주로 Redis, PostgreSQL 등과 같이 GitLab에 외부 서비스를 제공합니다. 순전히 UBI를 기반으로 한 GitLab 인스턴스를 배포하려면 내부 서비스를 비활성화하고 외부 배포 또는 서비스를 사용해야 합니다.

외부에서 비활성화하고 제공해야 하는 서비스는 다음과 같습니다:

- PostgreSQL
- MinIO (Object Store)
- Redis

비활성화해야 하는 서비스는 다음과 같습니다:

- CertManager (Let's Encrypt 통합)
- Prometheus
- GitLab Runner

## 샘플 값 {#sample-values}

[`examples/ubi/values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/ubi/values.yaml)의 GitLab 차트 값 예제를 제공하며, 이는 순수한 UBI GitLab 배포를 구축하는 데 도움이 될 수 있습니다.
