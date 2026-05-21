---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 설계 결정 사항
---

본 문서는 이 저장소의 Helm 차트 설계에 관한 이유와 결정 사항을 수집합니다. 제안을 환영합니다. [결정 내리기](decision-making.md)에서 우리가 결정을 적용하는 방식을 확인하세요.

## 문제가 될 수 있는 구성 감지 시도 {#attempt-to-catch-problematic-configurations}

이러한 차트의 복잡성과 유연성 수준으로 인해, 예측 불가능하거나 완전히 작동하지 않는 배포를 야기할 수 있는 구성을 생성할 수 있는 겹치는 부분이 있습니다. 알려진 문제가 있는 설정 조합을 방지하기 위해 사용자의 구성이 작동하지 않음을 감지하고 경고하도록 설계된 템플릿 로직을 구현했습니다.

이것은 지원 중단의 동작을 복제하지만, 기능 구성을 보장하는 것에 특정합니다.

다음에서 소개: [!757 checkConfig: add methods to test for known errors](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/757)

## 지원 중단을 통한 주요 변경 {#breaking-changes-via-deprecation}

이러한 차트 개발 중 기존 배포의 속성 변경이 필요한 개선 사항을 만드는 경우가 있습니다. 두 가지 예는 MinIO 사용 구성의 중앙화와 외부 객체 스토리지 구성의 속성에서 보안(우리의 선호도 준수)으로의 마이그레이션이었습니다.

작동하지 않을 주요 변경을 포함하는 업데이트된 버전의 이 차트를 사용자가 실수로 배포하는 것을 방지하는 수단으로서, 우리는 [지원 중단](../development/_index.md#handling-configuration-deprecations) 알림을 구현하기로 선택했습니다. 이들은 속성이 재배치, 변경, 대체 또는 완전히 제거되었는지 감지한 후 사용자에게 구성에 수행해야 할 변경 사항을 알려주도록 설계되었습니다. 여기에는 사용자에게 속성을 보안으로 대체하는 방법에 대한 문서를 보도록 알리는 것이 포함될 수 있습니다. 이러한 알림으로 인해 Helm `install` 또는 `upgrade` 명령이 구문 분석 오류로 중지되고, 처리해야 할 항목의 전체 목록이 출력됩니다. 우리는 사용자가 오류, 수정, 반복의 루프에 빠지지 않도록 주의했습니다.

배포를 성공적으로 수행하려면 모든 지원 중단이 해결되어야 합니다. 우리는 사용자가 예기치 않은 동작이나 디버깅이 필요한 완전한 실패를 경험하는 것보다 주요 변경에 대해 알림을 받는 것을 선호할 것으로 생각합니다.

다음에서 소개: [!396 Deprecations: implement buffered list of deprecations](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/396)

## initContainer에서 환경보다 보안 선호 {#preference-of-secrets-in-initcontainer-over-environment}

컨테이너 생태계의 대부분은 환경 변수를 통해 구성할 수 있는 기능을 가지고 있거나 예상합니다. 이 [구성 관행](https://12factor.net/config) 은 [The Twelve-Factor App](https://12factor.net)의 개념에서 비롯되었습니다. 이것은 여러 배포 환경에서 구성을 크게 단순화하지만, 컨테이너의 환경을 통해 암호 및 개인 키와 같은 연결 보안을 전달할 때 보안 문제가 남아 있습니다.

대부분의 컨테이너 생태계는 실행 중인 컨테이너의 상태를 검사하는 간단한 방법을 제공하며, 보통 환경을 포함합니다. [Docker](https://www.docker.com/)를 예로 들면, 데몬과 통신할 수 있는 모든 프로세스가 실행 중인 모든 컨테이너의 상태를 쿼리할 수 있습니다. 즉, [`dind`](https://hub.docker.com/r/gitlab/dind/)와 같은 권한 있는 컨테이너가 있으면 해당 컨테이너는 주어진 노드의 _모든_ 컨테이너의 환경을 검사하고 내에 포함된 _모든_ 보안을 노출할 수 있습니다. [완전한 DevOps 수명 주기](https://about.gitlab.com/blog/from-dev-to-devops/) 의 일부로서 [`dind`](https://hub.docker.com/r/gitlab/dind/)는 레지스트리로 푸시되고 이후에 배포될 컨테이너를 구축하기 위해 정기적으로 사용됩니다.

이러한 우려로 인해 우리는 [initContainers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)를 통해 민감한 정보의 채우기를 선호하기로 결정했습니다.

관련 문제:

- [\#90](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/90)
- [\#114](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/114)

## 서브 차트는 전역 차트에서 배포됨 {#sub-charts-are-deployed-from-global-chart}

이 저장소의 모든 서브 차트는 전역 차트를 통해 배포되도록 설계되었습니다. 각 구성 요소는 여전히 개별적으로 배포할 수 있지만, 전역 차트에 의해 촉진되는 공통 속성 세트를 사용합니다.

이 결정은 전체 저장소의 사용과 유지 관리를 단순화합니다.

관련 문제:

- [\#352](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/352)

## `gitlab/*`에 대한 템플릿 부분은 가능한 한 전역이어야 함 {#template-partials-for-gitlab-should-be-global-whenever-possible}

`gitlab/*` 서브 차트의 모든 템플릿 부분은 가능한 한 전역 또는 GitLab 서브 차트 `templates/_helpers.tpl`의 일부여야 합니다. [포크된 차트](#forked-charts)의 템플릿은 해당 차트의 일부로 유지됩니다. 이것은 이러한 포크의 유지 관리 영향을 줄입니다.

이것의 이점은 직설적입니다:

- DRY 동작 향상으로 유지 관리가 더 용이합니다. 단일 항목이면 충분할 때 여러 서브 차트에 걸쳐 동일한 함수의 중복을 가질 이유가 없어야 합니다.
- 템플릿 명명 충돌 감소. 모든 [차트 전체의 부분이 함께 컴파일됨](https://helm.sh/docs/chart_template_guide/named_templates/#declaring-and-using-templates-with-define-and-template), 따라서 우리는 이들을 전역 동작처럼 취급할 수 있습니다.

관련 문제:

- [\#352](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/352)

## Envoy Gateway 번들링 {#bundling-envoy-gateway}

우리는 공식 [Envoy Gateway](https://gateway.envoyproxy.io/) 차트를 패키징하여 이전에 번들된 NGINX Ingress 차트에서의 전환을 지원하고 원활한 설치 프로세스를 보장합니다.

### Gateway API 배경 {#gateway-api-background}

[Gateway API](https://gateway-api.sigs.k8s.io/)는 Kubernetes의 Ingress API의 후속이며, 더 표현력 있는 라우팅 기능과 더 나은 관심 분리를 제공하도록 설계되었습니다. 구성 책임을 혼동한 Ingress와 달리 Gateway API는 3가지 고유한 역할을 정의합니다:

- **Infrastructure Provider**:  Gateway 컨트롤러 구현(예: Envoy Gateway, Istio, Kong)을 설치 및 관리하고 GatewayClass 리소스를 정의합니다.
- **Cluster Operator**:  로드 밸런서를 프로비저닝하고 네트워크 경계를 정의하는 Gateway 리소스를 구성합니다.
- **Application Developer**(예: GitLab, Inc):  Gateway에 연결하고 해당 서비스로 트래픽을 라우팅하는 Route 리소스(HTTPRoute, TCPRoute 등)를 생성합니다.

이러한 분리를 통해 조직은 네트워킹 책임을 분할할 수 있습니다: 인프라 팀은 컨트롤러 및 게이트웨이 인프라를 관리하고, 애플리케이션 팀은 클러스터 수준 권한이 필요 없이 자신의 라우팅을 관리합니다.

### Gateway 컨트롤러를 번들화하는 이유? {#why-bundle-a-gateway-controller}

GitLab과 Envoy Gateway를 패키징하면 Gateway API의 의도된 페르소나 분리에서 의도적으로 벗어납니다. Gateway API 모델에서 인프라 공급자(응용 프로그램이 아님)는 컨트롤러를 설치하고, 클러스터 운영자는 응용 프로그램 배포와 별도로 Gateway를 프로비저닝합니다.

그러나 번들화는 GitLab의 사용 사례에 대해 중요한 이점을 제공하지만 일부 위험을 가집니다.

### 이점 {#advantages}

- GitLab 노출을 위해 검증되고 사전 구성된 네트워킹 솔루션을 제공합니다.
- 기존 번들된 Ingress 컨트롤러에서의 전환을 간소화합니다.
- GitLab 관리 인프라(.com, Dedicated 포함) 및 GitLab Environment Toolkit 전반에 걸쳐 채택을 단순화합니다.
- 많은 클라우드 제공자의 Gateway 구현은 TCPRoute를 지원하지 않으며, 이는 SSH 트래픽을 위해 GitLab을 노출하기 위한 요구 사항입니다.
- 정부 전용 Dedicated를 포함한 FIPS 고객에게 현재 FIPS 빌드를 제공하는 GitLab의 번들된 NGINX Ingress에서의 마이그레이션 경로를 제공합니다.
- Envoy Gateway는 표준 Gateway API에 대한 강력한 확장을 제공합니다. 이러한 확장은 표준 Gateway API에서 사용할 수 없는 고급 구성을 활성화합니다.
- 다른 [GitLab 기능](https://gitlab.com/gitlab-org/architecture/auth-architecture/design-doc/-/blob/0d779e8aae72db3f1f045c69d0e693739f2f5fc8/decisions/005_adopt_envoy.md)이 의존할 Envoy 채택을 활성화합니다.
- 고객은 여전히 번들된 Envoy Gateway 대신 사용할 선호하는 Gateway API 컨트롤러를 배포하도록 선택할 수 있습니다.

GitLab 애플리케이션 내 Gateway의 구현은 Gateway API의 규정된 페르소나를 따르는 고객을 고려하고 클러스터 운영자가 게이트웨이를 직접 관리하도록 선택할 수 있도록 옵션을 유지합니다. 마찬가지로, Gateway에 대한 특별하거나 비정상적인 구성 요구 사항이 있는 고객은 게이트웨이를 직접 관리 및 구성하도록 권장됩니다.

GitLab 차트는 가능한 한 표준 및 안정적인 Gateway API 리소스를 사용합니다. 실험적 또는 공급자 특정 리소스는 선택적 기능이거나 표준 또는 안정적인 리소스(예: SSH를 통한 Git, gRPC 교차 제공, KAS용 WSS 트래픽 또는 Smartcard 지원)로 구성할 수 없는 기능에만 사용됩니다.

### 고려 사항 {#considerations}

- Gateway API와 Envoy Gateway는 특정 클러스터 리소스 정의가 필요합니다. [Helm은 CRD 업그레이드를 지원하지 않음](https://helm.sh/docs/v3/chart_best_practices/custom_resource_definitions)이므로 수동 개입이 필요할 수 있습니다.
- 애플리케이션과 함께 Gateway API 컨트롤러를 패키징하면 의도된 [사용자 페르소나 분리](https://gateway-api.sigs.k8s.io/)에서 벗어납니다.
- FIPS 호환 배포는 공식 업스트림 버전이 아닌 대체 이미지를 활용해야 합니다. GitLab 소유 FIPS 빌드는 현재 [진행 중인 작업](https://gitlab.com/gitlab-org/build/CNG/-/merge_requests/2716)입니다.

## 포크된 차트 {#forked-charts}

다음 차트는 우리의 [포크 및 새 차트에 대한 지침](../development/readiness/_index.md)에 따라 이 저장소에서 포크 또는 재작성되었습니다.

### Redis {#redis}

GitLab Helm 차트의 `3.0` 릴리스를 사용하면 더 이상 [업스트림 Redis 차트](https://github.com/bitnami/charts/tree/main/bitnami/redis)를 포크하지 않고 대신 종속성으로 포함합니다.

### Redis HA {#redis-ha}

Redis-HA는 `3.0` 이전에 우리가 릴리스에 포함한 차트였습니다. 이제 제거되었으며 선택적 HA 지원을 추가한 [업스트림 Redis 차트](https://github.com/bitnami/charts/tree/main/bitnami/redis)로 대체되었습니다.

### MinIO {#minio}

우리의 [MinIO 차트](../charts/minio/_index.md) 는 업스트림 [MinIO](https://github.com/helm/charts/tree/master/stable/minio)에서 변경되었습니다.

- 속성에서 새로운 것을 만드는 대신 기존 Kubernetes 보안을 사용합니다.
- 환경을 통해 민감한 키 제공을 제거합니다.
- `defaultBuckets`를 통해 여러 버킷 생성을 자동화하여 `defaultBucket.*` 속성을 대신합니다.

### 레지스트리 {#registry}

우리의 [레지스트리 차트](../charts/registry/_index.md) 는 업스트림 [`docker-registry`](https://github.com/helm/charts/tree/master/stable/docker-registry)에서 변경되었습니다.

- 자동으로 차트 내 MinIO 서비스 사용을 활성화합니다.
- GitLab 서비스에 대한 인증을 자동으로 연결합니다.

### NGINX Ingress {#nginx-ingress}

우리의 [NGINX Ingress 차트](../charts/nginx/_index.md) 는 업스트림 [NGINX Ingress](https://github.com/kubernetes/ingress-nginx)에서 변경되었습니다.

- TCP ConfigMap을 차트 외부에 있도록 허용하는 기능 추가
- Ingress 클래스가 릴리스 이름을 기반으로 템플릿되도록 허용하는 기능 추가

## 차트 전체에서 사용되는 Kubernetes 버전 {#kubernetes-version-used-throughout-chart}

다양한 Kubernetes 버전에 대한 지원을 최대화하려면 현재 Kubernetes의 안정적인 릴리스보다 1개의 마이너 버전이 낮은 `kubectl`를 사용하세요. 이것은 최소 3개 이상의 Kubernetes 마이너 버전에 대한 지원을 허용해야 합니다. `kubectl` 버전에 대한 추가 논의는 [문제 1509](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1509)를 참조하세요.

관련 문제:

- [`charts/gitlab#1509`](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1509)
- [`charts/gitlab#1583`](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1583)

관련 병합 요청:

- [`charts/gitlab!1053`](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/1053)
- [`build/CNG!329`](https://gitlab.com/gitlab-org/build/CNG/-/merge_requests/329)
- [`gitlab-build-images!251`](https://gitlab.com/gitlab-org/gitlab-build-images/-/merge_requests/251)

## CNG과 함께 제공되는 이미지 변형 {#image-variants-shipped-with-cng}

날짜:  2022-02-10

[CNG 프로젝트](https://gitlab.com/gitlab-org/build/CNG)는 Debian과 UBI를 기반으로 한 이미지를 제공합니다. 두 배포판에 대한 구성을 유지하기로 결정한 것은 다음을 기반으로 했습니다:

- Debian 기반 이미지를 배포하는 이유:
  - 추적 기록, 선례
  - 배포판에 대한 친숙도
  - 커뮤니티 vs "엔터프라이즈"
  - 인지된 공급업체 잠금 부재
- UBI 기반 이미지를 배포하는 이유:
  - 일부 고객 환경에서 필요
  - RHEL 인증 및 OpenShift Marketplace / RedHat 카탈로그 포함에 필요

이 항목에 대한 추가 논의는 [문제 #3095](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3095)에서 찾을 수 있습니다.

## Kubernetes 릴리스 지원 정책 {#kubernetes-release-support-policy}

날짜:  2024-03-26

GitLab은 공식적으로 Kubernetes의 3개의 마이너 릴리스를 지원합니다: `N`, `N-1`, `N-2`. `N`는 다음 중 하나입니다:

- Kubernetes의 최신 릴리스 마이너 버전(정규화를 마친 경우).
- 가장 최근의 마이너 버전(정규화를 마치지 못했거나 시작하지 않은 경우).

예를 들어, 사용 가능한 현재 릴리스가 `1.28`, `1.27`, `1.26`, `1.25`이고 `1.28` 릴리스를 정규화하지 않은 경우 `N`는 `1.27`이 되며 `1.25`, `1.26`, `1.27`의 릴리스를 공식적으로 지원하게 됩니다. 이것이 이 표에 표시된 대로입니다.

| 릴리스 | 참조 |
|---------|-----------|
| `1.27`  | `N`       |
| `1.26`  | `N-1`     |
| `1.25`  | `N-2`     |

세부 정보는 [배포 팀 Kubernetes 및 OpenShift 릴리스 지원 정책](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/distribution/k8s-release-support-policy/)에서 찾을 수 있습니다.

## OpenShift 릴리스 지원 정책 {#openshift-release-support-policy}

날짜:  2024-03-26

GitLab은 공식적으로 OpenShift의 4개의 마이너 릴리스를 지원합니다 -- `N`, `N-1`, `N-2` 및 `N-3`. Kubernetes와 같이 `N`는 다음 중 하나입니다:

- OpenShift의 최신 릴리스 마이너 버전(정규화를 마친 경우).
- 가장 최근의 마이너 버전(정규화를 마치지 못했거나 시작하지 않은 경우).

예를 들어, 사용 가능한 현재 릴리스가 `4.14`, `4.13`, `4.12`, `4.11`이고 4.15 릴리스를 정규화하지 않은 경우 `N`는 `4.14`이 되며 `4.14`, `4.13`, `4.12`, `4.11`의 릴리스를 공식적으로 지원하게 됩니다. 이것이 이 표에 표시된 대로입니다.

| 릴리스 | 참조 |
|---------|-----------|
| `4.14`  | `N`       |
| `4.13`  | `N-1`     |
| `4.12`  | `N-2`     |
| `4.11`  | `N-2`     |

세부 정보는 [배포 팀 Kubernetes 및 OpenShift 릴리스 지원 정책](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/distribution/k8s-release-support-policy/)에서 찾을 수 있습니다.
