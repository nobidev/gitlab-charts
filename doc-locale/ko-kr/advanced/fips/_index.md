---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: FIPS 호환 이미지로 GitLab 차트 구성
---

GitLab은 [FIPS 호환](https://docs.gitlab.com/development/fips_gitlab/) 버전의 이미지를 제공하므로 FIPS가 활성화된 클러스터에서 GitLab을 실행할 수 있습니다.

이러한 이미지는 [Red Hat Universal Base Images](https://access.redhat.com/articles/4238681)를 기반으로 합니다. 완전히 호환되는 FIPS 모드에서 작동하려면 모든 호스트가 FIPS 모드로 구성되어야 합니다.

## 샘플 값 {#sample-values}

GitLab 차트 값에 대한 예제를 [`examples/fips/values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/fips/values.yaml)에서 제공하며, 이는 FIPS 호환 GitLab 배포를 구축하는 데 도움이 될 수 있습니다.

`nginx-ingress.controller` 키 아래의 주석을 참고하여 FIPS 호환 NGINX Ingress Controller 이미지를 사용하기 위한 관련 구성을 확인하세요. 이 이미지는 우리의 [NGINX Ingress Controller 포크](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-ingress-nginx)에서 유지 관리됩니다.
