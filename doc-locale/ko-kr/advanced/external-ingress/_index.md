---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 Ingress Controller로 GitLab 차트 구성
---

이 chart는 `Ingress`리소스를 번들로 제공되는 NGINX Ingress와 함께 구성합니다. chart가 Ingress에서 Gateway API로의 마이그레이션을 진행 중이지만, 외부 Ingress controller와 함께 Ingress를 계속 사용할 수 있습니다.

## 외부 Ingress controller 준비 {#prepare-the-external-ingress-controller}

### NGINX {#nginx}

> [!warning]
> NGINX Ingress는 더 이상 사용되지 않으며 2026년 3월 이후에는 보안 패치를 받지 않습니다. [공식 공지](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)를 읽어보세요.

[외부 NGINX Ingress 설명서](nginx.md)를 확인하여 GitLab과 함께 사용할 외부 NGINX Ingress 배포를 구성하고 준비하세요.

### Traefik {#traefik}

Traefik은 GitLab Shell(GitLab의 SSH 데몬)을 위해 포트 22를 노출하도록 구성해야 합니다:

```yaml
ports:
  gitlab-shell:
    expose: true
    port: 2222
    exposedPort: 22
```

## GitLab Ingress 옵션 사용자 정의 {#customize-the-gitlab-ingress-options}

NGINX Ingress Controller는 주석을 사용하여 특정 `Ingress`을 서비스할 Ingress Controller를 표시합니다([문서](https://github.com/kubernetes/ingress-nginx#annotation-ingressclass) 참조). `global.ingress.class` 설정을 사용하여 이 chart와 함께 사용할 Ingress 클래스를 구성할 수 있습니다. Helm 옵션에서 이를 설정해야 합니다.

```shell
--set global.ingress.class=myingressclass
```

반드시 필요하지는 않지만, 외부 Ingress Controller를 사용하는 경우 이 chart에서 기본적으로 배포되는 Ingress Controller를 비활성화할 수 있습니다:

```shell
--set nginx-ingress.enabled=false
```

## 사용자 정의 인증서 관리 {#custom-certificate-management}

외부 Ingress Controller를 사용하는 경우 외부 cert-manager 인스턴스를 사용하거나 다른 사용자 정의 방식으로 인증서를 관리할 수도 있습니다. TLS 옵션에 대한 전체 설명서는 [GitLab chart에 대한 TLS 구성](../../installation/tls.md)을 참조하세요. 하지만 이 논의의 목적상, cert-manager chart를 비활성화하고 GitLab 구성 요소 chart에서 기본 인증서 리소스를 찾지 않도록 설정해야 하는 두 가지 값은 다음과 같습니다:

```shell
--set installCertmanager=false
--set global.ingress.configureCertmanager=false
```
