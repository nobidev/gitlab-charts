---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CertManager Issuer 생성을 위한 certmanager-issuer 사용
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 차트는 [Jetstack의 CertManager Helm 차트](https://cert-manager.io/docs/installation/helm/)를 위한 헬퍼입니다. GitLab Ingresses의 TLS 인증서를 요청할 때 CertManager에서 사용하는 Issuer 객체를 자동으로 프로비저닝합니다.

## 구성 {#configuration}

다음은 구성의 주요 섹션을 설명합니다. 상위 차트에서 구성할 때 이러한 값들은:

```yaml
certmanager-issuer:
  # Configure an ACME Issuer in cert-manager. Only used if global.ingress.configureCertmanager is true.
  server: https://acme-v02.api.letsencrypt.org/directory

  # Provide an email to associate with your TLS certificates
  # email:

  rbac:
    create: true

  resources:
    requests:
      cpu: 50m

  # Priority class assigned to pods
  priorityClassName: ""

  common:
    labels: {}
```

## 설치 매개변수 {#installation-parameters}

이 표에는 `helm install` 명령어를 사용하여 `--set` 플래그로 제공할 수 있는 모든 가능한 차트 구성이 포함되어 있습니다:

| 매개변수                                           | 기본값                                          | 설명 |
|-----------------------------------------------------|--------------------------------------------------|-------------|
| `server`                                            | `https://acme-v02.api.letsencrypt.org/directory` | [ACME CertManager Issuer](https://cert-manager.io/docs/configuration/acme/)와 함께 사용하기 위한 Let's Encrypt 서버입니다. |
| `email`                                             |                                                  | TLS 인증서와 연결할 이메일을 제공해야 합니다. Let's Encrypt는 이 주소를 사용하여 만료되는 인증서와 계정 관련 문제에 대해 연락합니다. |
| `rbac.create`                                       | `true`                                           | `true`일 때 CertManager Issuer 객체를 조작할 수 있도록 RBAC 관련 리소스를 생성합니다. |
| `resources.requests.cpu`                            | `50m`                                            | Issuer 생성 Job에 요청된 CPU 리소스입니다. |
| `common.labels`                                     |                                                  | ServiceAccount, Job, ConfigMap 및 Issuer에 적용할 공통 레이블입니다. |
| `priorityClassName`                                 |                                                  | Pod에 할당된 [Priority class](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)입니다. |
| `containerSecurityContext`                          |                                                  | Certmanager가 시작되는 컨테이너 [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)를 재정의합니다 |
| `containerSecurityContext.runAsUser`                | `65534`                                          | 컨테이너가 시작되어야 하는 사용자 ID입니다 |
| `containerSecurityContext.runAsGroup`               | `65534`                                          | 컨테이너가 시작되어야 하는 그룹 ID입니다 |
| `containerSecurityContext.allowPrivilegeEscalation` | `false`                                          | 프로세스가 상위 프로세스보다 더 많은 권한을 얻을 수 있는지 여부를 제어합니다 |
| `containerSecurityContext.runAsNonRoot`             | `true`                                           | 컨테이너가 비루트 사용자로 실행되는지 여부를 제어합니다 |
| `containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                      | 컨테이너에 대한 [Linux 기능](https://man7.org/linux/man-pages/man7/capabilities.7.html)을 제거합니다 |
| `ttlSecondsAfterFinished`                           | `1800`                                           | 완료된 작업이 계단식 제거 대상이 되는 시기를 제어합니다. |
