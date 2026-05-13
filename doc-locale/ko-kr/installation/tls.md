---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트용 TLS 구성
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 차트는 NGINX Ingress Controller를 사용하여 TLS 종료를 수행할 수 있습니다. 배포를 위한 TLS 인증서를 획득하는 방법을 선택할 수 있습니다. [글로벌 Ingress 설정](../charts/globals.md#configure-ingress-settings)에서 자세한 내용을 확인할 수 있습니다.

## 옵션 1: cert-manager 및 Let's Encrypt {#option-1-cert-manager-and-lets-encrypt}

Let's Encrypt는 무료이고 자동화되며 개방적인 인증 기관입니다. 인증서는 다양한 도구를 사용하여 자동으로 요청할 수 있습니다. 이 차트는 인기 있는 선택인 [cert-manager](https://github.com/cert-manager/cert-manager)와 통합할 수 있도록 준비되어 있습니다.

*이미 cert-manager를 사용 중인 경우*, `global.ingress.annotations`를 사용하여 cert-manager 배포에 대한 [적절한 주석](https://cert-manager.io/docs/usage/ingress/#supported-annotations)을 구성할 수 있습니다.

*아직 클러스터에 cert-manager를 설치하지 않은 경우*, 이 차트의 종속성으로 설치하고 구성할 수 있습니다.

### 내부 cert-manager 및 Issuer {#internal-cert-manager-and-issuer}

```shell
helm repo update
helm dep update
helm install gitlab gitlab/gitlab \
  --set certmanager-issuer.email=you@example.com
```

`cert-manager` 설치는 `installCertmanager` 설정으로 제어되며 기본값은 `true`입니다. cert-manager를 차트에 연결하는 것은 Gateway API의 경우 `global.gatewayApi.configureCertmanager`(GitLab 19.0 이후 기본 라우팅 경로, 기본값 `true`) 및 NGINX Ingress의 경우 `global.ingress.configureCertmanager`(기본값 `false`, Ingress를 사용할 때 `true`로 설정)으로 제어됩니다. 기본적으로 발급자 이메일만 제공하면 됩니다.

### 외부 cert-manager 및 내부 Issuer {#external-cert-manager-and-internal-issuer}

외부 `cert-manager`를 사용할 수 있지만 Issuer를 이 차트의 일부로 제공할 수 있습니다.

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set certmanager-issuer.email=you@example.com \
  --set global.ingress.annotations."kubernetes\.io/tls-acme"=true
```

### 외부 cert-manager 및 Issuer (외부) {#external-cert-manager-and-issuer-external}

외부 `cert-manager` 및 `Issuer` 리소스를 사용하려면 자체 서명된 인증서가 활성화되지 않도록 여러 항목을 제공해야 합니다.

1. 외부 `cert-manager`을(를) 활성화하기 위한 주석(자세한 내용은 [설명서](https://cert-manager.io/docs/usage/ingress/#supported-annotations) 참조)
1. 각 서비스의 TLS 시크릿 이름(이는 [자체 서명된 동작](#option-4-use-auto-generated-self-signed-wildcard-certificate)을 비활성화함)

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.annotations."kubernetes\.io/tls-acme"=true \
  --set gitlab.webservice.ingress.tls.secretName=RELEASE-gitlab-tls \
  --set registry.ingress.tls.secretName=RELEASE-registry-tls \
  --set minio.ingress.tls.secretName=RELEASE-minio-tls \
  --set gitlab.kas.ingress.tls.secretName=RELEASE-kas-tls
```

## 옵션 2:  고유한 와일드카드 인증서 사용 {#option-2-use-your-own-wildcard-certificate}

전체 체인 인증서와 키를 `Secret`(으)로 클러스터에 추가합니다. 예:

```shell
kubectl create secret tls <tls-secret-name> --cert=<path/to-full-chain.crt> --key=<path/to.key>
```

다음 옵션을 포함합니다.

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.tls.secretName=<tls-secret-name>
```

### AWS ACM을 사용하여 인증서 관리 {#use-aws-acm-to-manage-certificates}

AWS ACM을 사용하여 와일드카드 인증서를 생성하는 경우 ACM 인증서를 다운로드할 수 없으므로 시크릿을 통해 지정할 수 없습니다. 대신 `nginx-ingress.controller.service.annotations`(으)로 지정합니다:

```yaml
nginx-ingress:
  controller:
    service:
      annotations:
        ...
        service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:{region}:{user id}:certificate/{id}
```

## 옵션 3:  서비스당 개별 인증서 사용 {#option-3-use-individual-certificate-per-service}

전체 체인 인증서를 클러스터에 시크릿으로 추가한 다음 해당 시크릿 이름을 각 Ingress에 전달합니다.

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.tls.enabled=true \
  --set gitlab.webservice.ingress.tls.secretName=RELEASE-gitlab-tls \
  --set registry.ingress.tls.secretName=RELEASE-registry-tls \
  --set minio.ingress.tls.secretName=RELEASE-minio-tls \
  --set gitlab.kas.ingress.tls.secretName=RELEASE-kas-tls
```

> [!note] GitLab 인스턴스가 다른 서비스와 통신하도록 구성하는 경우 Helm 차트를 통해 이러한 서비스에 대한 [인증서 체인을 제공](../charts/globals.md#custom-certificate-authorities)해야 할 수도 있습니다.

## 옵션 4:  자동 생성된 자체 서명된 와일드카드 인증서 사용 {#option-4-use-auto-generated-self-signed-wildcard-certificate}

이 차트는 자동 생성된 자체 서명된 와일드카드 인증서를 제공할 수 있는 기능도 제공합니다. Let's Encrypt가 선택지가 아니지만 SSL을 통한 보안이 여전히 필요한 환경에서 유용할 수 있습니다. 이 기능은 [shared-secrets](../charts/shared-secrets.md) 작업으로 제공됩니다.

> [!note]
>
> - `gitlab-runner` 차트는 자체 서명된 인증서와 제대로 작동하지 않습니다. 아래에 표시된 대로 비활성화하는 것이 좋습니다.
> - `--set global.ingress.tls.enabled=false`과(와) 같은 것으로 TLS를 전역적으로 비활성화하면 자체 서명된 인증서가 생성되지 않습니다.

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set gitlab-runner.install=false
```

`shared-secrets` 작업은 CA 인증서, 와일드카드 인증서 및 모든 외부에서 액세스 가능한 서비스에서 사용할 인증서 체인을 생성합니다. 이러한 항목을 포함하는 시크릿은 `RELEASE-wildcard-tls`, `RELEASE-wildcard-tls-ca`, `RELEASE-wildcard-tls-chain`입니다. `RELEASE-wildcard-tls-ca`에는 배포된 GitLab 인스턴스에 액세스할 사용자 및 시스템에 배포할 수 있는 공개 CA 인증서가 포함되어 있습니다. `RELEASE-wildcard-tls-chain`에는 CA 인증서와 와일드카드 인증서가 모두 포함되어 있으며 `gitlab-runner.certsSecretName=RELEASE-wildcard-tls-chain`을(를) 통해 GitLab Runner에 직접 사용할 수도 있습니다.

## GitLab Pages용 TLS 요구 사항 {#tls-requirement-for-gitlab-pages}

[TLS 지원이 포함된 GitLab Pages](https://docs.gitlab.com/administration/pages/#wildcard-domains-with-tls-support)의 경우 `*.<pages domain>`(기본값 `<pages domain>`은 `pages.<base domain>`)에 적용되는 와일드카드 인증서가 필요합니다.

와일드카드 인증서가 필요하므로 cert-manager 및 Let's Encrypt에 의해 자동으로 생성될 수 없습니다. 따라서 cert-manager는 기본적으로 GitLab Pages에서 비활성화됩니다(`gitlab-pages.ingress.configureCertmanager` 참조). 따라서 와일드카드 인증서가 포함된 자신의 k8s 시크릿을 제공해야 합니다. `global.ingress.annotations`를 사용하여 외부 cert-manager가 구성되어 있는 경우 `gitlab-pages.ingress.annotations`에서도 이러한 주석을 재정의하고 싶을 수 있습니다.

기본적으로 이 시크릿의 이름은 `<RELEASE>-pages-tls`입니다. `gitlab.gitlab-pages.ingress.tls.secretName` 설정을 사용하여 다른 이름을 지정할 수 있습니다:

```shell
helm install gitlab gitlab/gitlab \
  --set global.pages.enabled=true \
  --set gitlab.gitlab-pages.ingress.tls.secretName=<secret name>
```

## 문제 해결 {#troubleshooting}

이 섹션에는 발생할 수 있는 문제에 대한 가능한 해결 방법이 포함되어 있습니다.

### SSL 종료 오류 {#ssl-termination-errors}

Let's Encrypt를 TLS 공급자로 사용 중이고 인증서 관련 오류가 발생하는 경우 이를 디버깅할 수 있는 몇 가지 옵션이 있습니다:

1. [letsdebug](https://letsdebug.net/)를 사용하여 도메인을 확인하면 발생 가능한 오류를 찾을 수 있습니다.
1. letsdebug에서 오류를 반환하지 않으면 cert-manager와 관련된 문제가 있는지 확인하세요:

   ```shell
   kubectl describe certificate,order,challenge --all-namespaces
   ```

   오류가 표시되면 인증서 객체를 제거하여 새 인증서를 강제로 요청하세요.

1. 위의 어느 것도 작동하지 않으면 [기존 cert-manager 리소스](https://cert-manager.io/docs/installation/kubectl/#uninstalling)를 제거하고 cert-manager를 다시 설치하는 것을 고려하세요. 내부 cert-manager를 사용하는 경우 이름에 `certmanager`가 있는 배포를 삭제하고 Helm Chart를 다시 설치하세요. 예를 들어 `gitlab`라고 이름이 지정된 릴리스를 가정합니다:

   ```shell
   kubectl -n <namespace> delete deployment gitlab-certmanager gitlab-certmanager-cainjector gitlab-certmanager-webhook
   helm upgrade --install -n <namespace> gitlab gitlab/gitlab
   ```
