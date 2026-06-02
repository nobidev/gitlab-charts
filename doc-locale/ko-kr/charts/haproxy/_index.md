---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: HAProxy 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

[HAProxy Helm Chart](https://github.com/haproxytech/helm-charts/tree/main/kubernetes-ingress) 는 [번들로 제공되는 NGINX Helm 차트](../nginx/_index.md) 를 Ingress 컨트롤러로 대체할 수 있으며, Kubernetes의 [추가 Ingress 컨트롤러 목록](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/#additional-controllers)에 문서화되어 있습니다.

HAProxy는 또한 Git over SSH를 지원합니다.

주로 도구에 대한 역사적 경험으로 인해 기본적으로 [NGINX](../nginx/_index.md)를 사용하지만, HAProxy는 HAProxy에 더 많은 경험이 있는 사용자에게 선호될 수 있는 유효한 대안입니다. 또한 [FIPS 준수](#fips-compliant-haproxy) 를 제공하지만 [NGINX Ingress 컨트롤러](https://github.com/kubernetes/ingress-nginx)는 현재 그렇지 않습니다.

## HAProxy 구성 {#configuring-haproxy}

[HAProxy Helm 차트 문서](https://www.haproxy.com/documentation/kubernetes-ingress/enterprise/configuration-reference/) 또는 [Helm 값 파일](https://github.com/haproxytech/helm-charts/blob/main/kubernetes-ingress/values.yaml)을 참조하세요. 구성 세부 사항은

[HAProxy 예제 구성](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-haproxy-ingress.yaml)을 참조하여 GitLab Helm 차트로 테스트된 값에 대한 자세한 YAML을 확인하세요.

### 전역 설정 {#global-settings}

차트 간에 공통 전역 설정을 공유합니다. [전역 Ingress 문서](../globals.md#configure-ingress-settings)를 참조하여 GitLab 및 레지스트리 호스트명 같은 공통 구성 옵션을 확인하세요.

### FIPS 준수 HAProxy {#fips-compliant-haproxy}

[HAProxy Enterprise](https://www.haproxy.com/products/haproxy-enterprise-kubernetes-ingress-controller)는 FIPS 준수를 제공합니다. HAProxy Enterprise는 라이선스가 필요합니다.

HAProxy Enterprise에 대한 자세한 정보를 위한 링크는 다음과 같습니다:

- [HAProxy Enterprise 랜딩 페이지](https://www.haproxy.com/products/haproxy-enterprise)
- [HAProxy FIPS 준수 블로그 게시물](https://www.haproxy.com/blog/become-fips-compliant-with-haproxy-enterprise-on-red-hat-enterprise-linux-8)
- [Certified OpenShift Operator](https://catalog.redhat.com/software/container-stacks/detail/5ec3f9fc110f56bd24f2dd57)
- [프라이빗 레지스트리에서 이미지를 사용하는 방법](https://github.com/haproxytech/helm-charts/blob/kubernetes-ingress-1.22.0/haproxy/README.md#installing-from-a-private-registry)
- [HAProxy Enterprise 이미지를 찾는 방법](https://www.haproxy.com/documentation/haproxy-enterprise/getting-started/installation/docker/)
