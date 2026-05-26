---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트에 대한 RBAC 구성
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

Kubernetes 1.7까지는 클러스터 내에 권한이 없었습니다. 1.7 출시 이후, 클러스터 내에서 서비스가 수행할 수 있는 작업을 결정하는 역할 기반 접근 제어 시스템([RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/))이 있습니다.

RBAC는 GitLab의 여러 측면에 영향을 미칩니다:

- Helm을 사용한 GitLab 설치
- Prometheus 모니터링
- GitLab Runner
- 클러스터 내 PostgreSQL 데이터베이스(RBAC가 활성화된 경우)
- 인증서 관리자

## RBAC가 활성화되었는지 확인 {#checking-that-rbac-is-enabled}

현재 클러스터 역할을 나열해보세요. 실패하면 `RBAC`이 비활성화된 것입니다.

이 명령은 `false`이 비활성화되어 있으면 `RBAC`을 출력하고, 그렇지 않으면 `true`을 출력합니다.

`kubectl get clusterroles > /dev/null 2>&1 && echo true || echo false`

## 서비스 계정 {#service-accounts}

GitLab 차트는 특정 작업을 수행하기 위해 서비스 계정을 사용합니다. 이 계정과 관련된 역할은 차트에 의해 생성되고 관리됩니다.

서비스 계정은 다음 표에 설명되어 있습니다. 각 서비스 계정에 대해 표는 다음을 보여줍니다:

- 이름 접미사(접두사는 릴리스 이름).
- 간단한 설명. 예를 들어, 사용 위치 또는 사용 목적.
- 관련 역할 및 어떤 리소스에 대한 접근 수준. 접근 수준은 읽기 전용(R), 쓰기 전용(W) 또는 읽기-쓰기(RW)입니다. 리소스의 그룹 이름은 생략됩니다.
- 역할의 범위는 클러스터(C) 또는 네임스페이스(NS)입니다. 경우에 따라 역할의 범위는 어느 값으로든 구성할 수 있습니다(NS/C로 표시).

| 이름 접미사      | 설명                                                                               | 역할                                                                  | 범위 |
|:-----------------|:------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------|:------|
| `gitlab-runner`  | GitLab Runner는 이 계정으로 실행됩니다.                                          | 모든 리소스(RW)                                                      | NS/C  |
| `ingress-nginx`  | NGINX Ingress가 서비스 접근 지점을 제어하기 위해 사용됩니다.                                   | Secret, Pod, Endpoint, Ingress (R); Event (W); ConfigMap, Service (RW) | NS/C  |
| `shared-secrets` | 공유 암호를 생성하는 작업이 이 계정으로 실행됩니다. (사전 설치/업그레이드 훅에서) | Secret (RW)                                                            | NS    |
| `cert-manager`   | 인증서 관리자를 제어하는 작업이 이 계정으로 실행됩니다.                         | Issuer, Certificate, CertificateRequest, Order (RW)                    | NS/C  |

GitLab 차트는 RBAC도 사용하고 자체 서비스 계정 및 역할 바인딩을 생성하는 다른 차트에 따라 다릅니다. 다음은 개요입니다:

- Prometheus 모니터링은 기본적으로 여러 개의 자체 서비스 계정을 생성합니다. 이들은 모두 클러스터 수준 역할과 연결됩니다. 자세한 내용은 [Prometheus 차트 설명서](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#rbac-configuration)를 참조하세요.
- 인증서 관리자는 기본적으로 서비스 계정을 생성하여 클러스터 수준에서 사용자 정의 리소스와 기본 리소스를 관리합니다. 자세한 내용은 [cert-manager 차트 RBAC 템플릿](https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/templates/rbac.yaml)을 참조하세요.
