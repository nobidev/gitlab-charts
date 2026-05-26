---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Traefik 사용
---

{{< details >}}

- 계층:  무료, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

[Traefik Helm 차트](https://artifacthub.io/packages/helm/traefik/traefik) 는 [번들로 제공되는 NGINX Helm 차트](../nginx/_index.md)를 Ingress 컨트롤러로 대체할 수 있습니다.

Traefik은 [기본 Kubernetes Ingress](https://doc.traefik.io/traefik/providers/kubernetes-ingress/) 객체를 [IngressRoute](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute) 객체로 변환합니다.

Traefik은 또한 [IngressRouteTCP](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroutetcp) 객체를 통해 Git over SSH를 지원하며, 이 객체는 [`global.ingress.provider`](../globals.md#configure-ingress-settings)이 `traefik`로 구성될 때 GitLab Shell 차트에 의해 배포됩니다.

## Traefik 구성 {#configuring-traefik}

[Traefik Helm 차트 설명서](https://github.com/traefik/traefik-helm-chart/tree/master/traefik)에서 구성 세부 정보를 확인하세요.

[Traefik 예제 구성](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-traefik-ingress.yaml)에서 GitLab Helm 차트로 테스트된 값에 대한 자세한 YAML을 확인하세요.

### 전역 설정 {#global-settings}

우리는 차트 간에 몇 가지 공통 전역 설정을 공유합니다. [전역 Ingress 설명서](../globals.md#configure-ingress-settings)에서 GitLab 및 Registry 호스트명과 같은 공통 구성 옵션을 확인하세요.

### FIPS 호환 Traefik {#fips-compliant-traefik}

[Traefik Enterprise](https://doc.traefik.io/traefik-enterprise/)는 FIPS 준수를 제공합니다. Traefik Enterprise는 라이선스가 필요하며, 이 차트에 포함되지 않습니다.

Traefik Enterprise에 대한 자세한 정보를 위한 링크는 다음과 같습니다:

- [Traefik Enterprise 기능](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
- [Traefik Enterprise FIPS 이미지](https://doc.traefik.io/traefik-enterprise/operations/fips-image/)
- [Traefik Enterprise Helm 차트](https://doc.traefik.io/traefik-enterprise/installing/kubernetes/helm/)
- [ArtifactHub의 Traefik Enterprise Operator](https://artifacthub.io/packages/olm/community-operators/traefikee-operator)
- [RedHat 카탈로그의 Traefik Enterprise 인증 OpenShift Operator](https://catalog.redhat.com/software/container-stacks/detail/5e98745a6c5dcb34dfbb1a0a)
