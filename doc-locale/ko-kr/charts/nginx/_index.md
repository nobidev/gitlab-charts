---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: NGINX 사용
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

> [!warning] NGINX Ingress는 더 이상 지원되지 않으며 2026년 3월 이후 보안 패치를 받지 않습니다. GitLab 19.0에서는 번들로 제공되는 NGINX Ingress가 기본적으로 비활성화되며 20.0에서 전체 제거가 계획되어 있습니다.
>
> 자세한 내용은 [지원 중단 공지](https://docs.gitlab.com/update/deprecations/#support-for-nginx-ingress)를 참조하세요. [번들로 제공되는 Envoy Gateway](../envoygateway/_index.md) 또는 [외부 Ingress 컨트롤러](../../advanced/external-ingress/_index.md)로 가능한 한 빨리 마이그레이션해야 합니다.

Ingress 컨트롤러로 사용할 완전한 NGINX 배포를 제공합니다. 모든 Kubernetes 공급자가 NGINX [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)를 기본적으로 지원하는 것은 아니며, 호환성을 보장합니다.

> [!note]
>
> - GitLab NGINX 차트는 업스트림 NGINX Helm 차트의 포크입니다. [NGINX 포크 조정사항](#adjustments-to-the-nginx-fork)을 참조하여 우리 포크에서 수정한 사항을 자세히 확인하세요.
> - 하나의 `global.hosts.domain` 값만 가능합니다. 여러 도메인에 대한 지원은 [이슈 3147](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3147)에서 추적하고 있습니다.

## NGINX 구성 {#configuring-nginx}

[NGINX 차트 문서](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/nginx-ingress/README.md#configuration)를 참조하여 구성 세부 사항을 확인하세요.

### 전역 설정 {#global-settings}

차트 간에 공통 전역 설정을 공유합니다. [전역 문서](../globals.md)에서 GitLab 및 Registry 호스트명과 같은 일반적인 구성 옵션을 참조하세요.

## 전역 설정을 사용하여 호스트 구성 {#configure-hosts-using-the-global-settings}

GitLab 서버 및 Registry 서버의 호스트명은 우리의 [전역 설정](../globals.md) 차트를 사용하여 구성할 수 있습니다.

## GitLab Geo {#gitlab-geo}

두 번째 NGINX 하위 차트가 번들로 제공되고 GitLab Geo 트래픽을 위해 사전 구성되며, 기본 컨트롤러와 동일한 설정을 지원합니다. 컨트롤러는 `nginx-ingress-geo.enabled=true`로 활성화할 수 있습니다.

이 컨트롤러는 들어오는 `X-Forwarded-*` 헤더를 수정하지 않도록 구성됩니다. Geo 트래픽에 다른 공급자를 사용하려면 동일하게 수행해야 합니다.

기본 컨트롤러 값(`nginx-ingress-geo.controller.ingressClassResource.controllerValue`)은 `k8s.io/nginx-ingress-geo`로 설정되고 IngressClass 이름은 `{ReleaseName}-nginx-geo`로 설정되어 기본 컨트롤러와의 간섭을 방지합니다. IngressClass 이름은 `global.geo.ingressClass`로 재정의할 수 있습니다.

사용자 지정 헤더 처리는 보조 사이트에서 전달된 트래픽을 처리하기 위해 기본 Geo 사이트에서만 필요합니다. 사이트가 기본 사이트로 승격될 예정인 경우 보조 사이트에서만 사용해야 합니다.

장애 조치 중에 IngressClass를 변경하면 다른 컨트롤러가 들어오는 트래픽을 처리하게 됩니다. 다른 컨트롤러에는 다른 로드 밸런서 IP가 할당되어 있으므로 DNS 구성에 추가 변경이 필요할 수 있습니다.

모든 Geo 사이트에서 Geo Ingress 컨트롤러를 활성화하고 기본 및 추가 webservice Ingress를 관련 IngressClass(`useGeoClass=true`)를 사용하도록 구성하여 이를 피할 수 있습니다.

## 주석 값 단어 차단 목록 {#annotation-value-word-blocklist}

{{< history >}}

- [GitLab Helm 차트 6.6](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2713)에서 도입되었습니다.

{{< /history >}}

클러스터 운영자가 생성된 NGINX 구성을 더 강력하게 제어해야 하는 상황에서 NGINX Ingress는 [구성 스니펫](https://kubernetes.github.io/ingress-nginx/examples/customization/configuration-snippets/)을 허용하며, 이는 표준 주석 및 ConfigMap 항목으로 처리되지 않는 원시 NGINX 구성의 "스니펫"을 삽입합니다.

이러한 구성 스니펫의 단점은 클러스터 운영자가 LUA 스크립팅 및 유사한 구성을 포함하는 Ingress 개체를 배포할 수 있다는 것이며, 이는 GitLab 설치 및 클러스터 자체의 보안을 손상시킬 수 있으며, serviceaccount 토큰 및 비밀 노출을 포함합니다.

[CVE-2021-25742](https://nvd.nist.gov/vuln/detail/CVE-2021-25742) 및 [이 업스트림 `ingress-nginx` 이슈](https://github.com/kubernetes/ingress-nginx/issues/7837)를 참조하여 추가 세부 사항을 확인하세요.

GitLab의 Helm 차트 배포에서 CVE-2021-25742를 완화하기 위해 [주석-값-단어-차단 목록](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/v6.6.0/values.yaml#L836) 을 설정했으며, [`nginx-ingress` 커뮤니티의 제안된 설정](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#annotation-value-word-blocklist)을 사용합니다.

GitLab Ingress 구성에서 구성 스니펫을 사용하거나 구성 스니펫을 사용하는 타사 Ingress 개체와 함께 GitLab NGINX Ingress 컨트롤러를 사용하는 경우, GitLab 타사 도메인을 방문할 때 `404` 오류가 발생할 수 있으며 `nginx-controller` 로그에 "유효하지 않은 단어" 오류가 발생합니다. 이 경우, 귀하의 `nginx-ingress.controller.config.annotation-value-word-blocklist` 설정을 검토하고 조정하세요.

또한 [`nginx-controller` 로그의 "유효하지 않은 단어" 오류 및 우리 차트 문제 해결 문서의 `404` 오류](../../troubleshooting/_index.md#invalid-word-errors-in-the-nginx-controller-logs-and-404-errors)를 참조하세요.

## NGINX 포크 조정사항 {#adjustments-to-the-nginx-fork}

> [!note] 우리의 [포크](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts/nginx-ingress) 는 [GitHub](https://github.com/kubernetes/ingress-nginx)에서 가져온 것입니다.

NGINX 포크에 다음 조정사항이 적용되었습니다:

- SSH에 대해 GitLab Shell을 노출하기 위해 외부 TCP ConfigMap을 지원합니다.
- HPA 또는 PDB 값과 같은 전역 차트 구성을 지원하기 위한 다양한 변경사항입니다.
- 업그레이드 시 손상을 방지하기 위해 새로운 선택자 레이블을 사용하지 마세요.
- 통합 URL로 GitLab Geo 설정을 위해 필요한 일부 설정을 템플릿화하기 위한 다양한 변경사항입니다.

포크에 적용된 모든 패치에 대해 [소스 디렉토리](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/scripts/nginx-patches)를 확인하세요.
