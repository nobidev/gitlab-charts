---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트 구성 요소 간 TLS 사용
---

GitLab 차트는 다양한 구성 요소 간에 전송 계층 보안(TLS)을 사용할 수 있습니다. 이를 위해서는 활성화하려는 서비스에 대한 인증서를 제공하고 이러한 인증서와 서명한 인증 기관(CA)을 사용하도록 이러한 서비스를 구성해야 합니다.

## 준비 {#preparation}

각 차트에는 해당 서비스에 대해 TLS를 활성화하는 방법과 적절한 구성을 보장하는 데 필요한 다양한 설정에 관한 설명서가 있습니다.

### 내부 사용을 위한 인증서 생성 {#generating-certificates-for-internal-use}

> [!note]
> GitLab은 고급 PKI 인프라 또는 인증 기관을 제공하지 않습니다.

이 설명서의 목적상, 아래에 **Proof of Concept** 스크립트를 제공하며, [Cloudflare의 CFSSL](https://github.com/cloudflare/cfssl/)을 사용하여 자체 서명된 인증 기관과 모든 서비스에 사용할 수 있는 와일드카드 인증서를 생성합니다.

이 스크립트:

- CA 키 쌍을 생성합니다.
- 모든 GitLab 구성 요소 서비스 엔드포인트를 서비스하기 위한 인증서에 서명합니다.
- 두 개의 Kubernetes Secret 객체를 생성합니다:
  - `kuberetes.io/tls` 유형의 시크릿(서버 인증서 및 키 쌍 포함)입니다.
  - `Opaque` 유형의 시크릿(CA의 공개 인증서 **only** 포함, NGINX Ingress에 필요한 `ca.crt`)입니다.

필수 조건:

- Bash 또는 호환되는 셸입니다.
- `cfssl`이(가) 셸에서 사용 가능하고 `PATH` 내에 있습니다.
- `kubectl`이(가) 사용 가능하며 나중에 GitLab을 설치할 Kubernetes 클러스터를 가리키도록 구성되어 있습니다.
  - 스크립트를 실행하기 전에 이 인증서를 설치하려는 네임스페이스를 생성했는지 확인하세요.

이 스크립트의 내용을 컴퓨터에 복사하고 결과 파일을 실행 가능하게 만들 수 있습니다. `poc-gitlab-internal-tls.sh`을(를) 제안합니다.

```shell
#!/bin/bash
set -e
#############
## make and change into a working directory
pushd $(mktemp -d)

#############
## setup environment
NAMESPACE=${NAMESPACE:-default}
RELEASE=${RELEASE:-gitlab}
## stop if variable is unset beyond this point
set -u
## known expected patterns for SAN
CERT_SANS="*.${NAMESPACE}.svc,${RELEASE}-metrics.${NAMESPACE}.svc,*.${RELEASE}-gitaly.${NAMESPACE}.svc"

#############
## generate default CA config
cfssl print-defaults config > ca-config.json
## generate a CA
echo '{"CN":"'${RELEASE}.${NAMESPACE}.internal.ca'","key":{"algo":"ecdsa","size":256}}' | \
  cfssl gencert -initca - | \
  cfssljson -bare ca -
## generate certificate
echo '{"CN":"'${RELEASE}.${NAMESPACE}.internal'","key":{"algo":"ecdsa","size":256}}' | \
  cfssl gencert -config=ca-config.json -ca=ca.pem -ca-key=ca-key.pem -profile www -hostname="${CERT_SANS}" - |\
  cfssljson -bare ${RELEASE}-services

#############
## load certificates into K8s
kubectl -n ${NAMESPACE} create secret tls ${RELEASE}-internal-tls \
  --cert=${RELEASE}-services.pem \
  --key=${RELEASE}-services-key.pem
kubectl -n ${NAMESPACE} create secret generic ${RELEASE}-internal-tls-ca \
  --from-file=ca.crt=ca.pem
```

> [!note]
> 이 스크립트는 CA의 개인 키를 _보존하지 않습니다_. 개념 증명 도우미이며 _프로덕션 사용을 위한 것이 아닙니다_.

스크립트에서 두 개의 환경 변수를 설정해야 합니다:

1. `NAMESPACE`: 나중에 GitLab을 설치할 Kubernetes 네임스페이스입니다. 이는 `default`으(로) 기본값이 지정되며, `kubectl`과(와) 마찬가지입니다.
1. `RELEASE`: 나중에 GitLab을 설치하는 데 사용할 Helm 릴리스 이름입니다. 이는 `gitlab`을(를) 기본값으로 합니다.

이 스크립트를 실행하려면 두 변수를 `export`하거나 스크립트 이름 앞에 해당 값을 붙일 수 있습니다.

```shell
export NAMESPACE=testing
export RELEASE=gitlab

./poc-gitlab-internal-tls.sh
```

스크립트가 실행된 후 두 개의 생성된 시크릿을 찾을 수 있으며, 임시 작업 디렉터리에 모든 인증서와 키가 포함되어 있습니다.

```plaintext
$ pwd
/tmp/tmp.swyMgf9mDs
$ kubectl -n ${NAMESPACE} get secret | grep internal-tls
testing-internal-tls      kubernetes.io/tls                     2      11s
testing-internal-tls-ca   Opaque                                1      10s
$ ls -1
ca-config.json
ca.csr
ca-key.pem
ca.pem
testing-services.csr
testing-services-key.pem
testing-services.pem
```

#### 필수 인증서 CN 및 SAN {#required-certificate-cn-and-sans}

다양한 GitLab 구성 요소는 서비스의 DNS 이름을 통해 서로 통신합니다. TLS 인증서 검증을 통과하려면 각 인증서에 구성 요소의 서비스 이름 또는 Kubernetes 서비스 DNS 항목에 허용되는 와일드카드를 포함하는 SAN이 필요합니다.

- `service-name.namespace.svc`
- `*.namespace.svc`

인증서 내에 이러한 SAN을 보장하지 못하면 _작동하지 않는_ 인스턴스 및 "연결 실패" 또는 "SSL 검증 실패"를 참조하는 상당히 불명확한 로그가 발생합니다.

`helm template`을(를) 사용하여 필요한 경우 모든 서비스 객체 이름의 전체 목록을 검색할 수 있습니다. GitLab이 TLS 없이 배포된 경우 Kubernetes에 쿼리하여 해당 이름을 찾을 수 있습니다:

`kubectl -n ${NAMESPACE} get service -lrelease=${RELEASE}`

## Ingress 트래픽 {#ingress-traffic}

기본적으로 Ingress 또는 Gateway API 컨트롤러에서 백엔드 서비스로의 네트워크 트래픽은 암호화되지 않을 것으로 예상됩니다. 이러한 연결에 대해 내부 TLS를 활성화하려면 네트워킹 솔루션에 따라 추가 구성이 필요합니다.

### NGINX Ingress {#nginx-ingress}

내부 TLS가 활성화되면 GitLab 차트는 자동으로 Ingress 객체에 주석을 달아 NGINX Ingress가 백엔드 서비스에 대한 TLS 연결을 시작하고 구성된 CA에 대한 인증서를 확인합니다. 추가 사용자 구성은 필요하지 않습니다.

다른 Ingress 구현을 사용하는 경우 공급자별 주석 또는 구성을 추가하여 컨트롤러와 백엔드 간의 TLS 연결을 활성화해야 합니다.

### Envoy Gateway {#envoy-gateway}

차트는 `BackendTLSPolicy` 리소스를 제공하여 Envoy Gateway 또는 다른 사양 준수 Gateway API 컨트롤러를 구성하여 백엔드와의 TLS 연결을 시작합니다.

자세한 내용은 [Gateway API](../gateway-api/_index.md#tls-between-gateway-and-backend-services) 설명서를 참조하세요.

## 구성 {#configuration}

예제 구성은 [examples/internal-tls](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/internal-tls/)에서 찾을 수 있습니다.

이 설명서의 목적상, GitLab 구성 요소를 구성하여 위의 스크립트로 생성된 인증서를 사용하도록 `shared-cert-values.yaml`을(를) 제공했으며, [내부 사용을 위한 인증서 생성](#generating-certificates-for-internal-use)에서 찾을 수 있습니다.

구성할 주요 항목:

1. 전역 [사용자 정의 인증 기관](../../charts/globals.md#custom-certificate-authorities).
1. 구성 요소별 서비스 리스너용 TLS입니다. ([차트/](../../charts/_index.md) 아래의 각 차트 설명서를 참조하세요)

이 프로세스는 YAML의 기본 앵커 기능을 사용함으로써 크게 단순화됩니다. `shared-cert-values.yaml`의 잘린 조각이 이를 보여줍니다:

```yaml
.internal-ca: &internal-ca gitlab-internal-tls-ca
.internal-tls: &internal-tls gitlab-internal-tls

global:
  certificates:
    customCAs:
    - secret: *internal-ca
  workhorse:
    tls:
      enabled: true
gitlab:
  webservice:
    tls:
      secretName: *internal-tls
    workhorse:
       tls:
          verify: true # default
          secretName: *internal-tls
          caSecretName: *internal-ca
```

## 결과 {#result}

모든 구성 요소가 서비스 리스너에서 TLS를 제공하도록 구성된 경우, GitLab 구성 요소 간의 모든 통신은 NGINX Ingress에서 각 GitLab 구성 요소로의 연결을 포함하여 TLS 보안으로 네트워크를 통과합니다.

NGINX Ingress는 모든 _인바운드_ TLS를 종료하고, 트래픽을 전달할 적절한 서비스를 결정한 다음 GitLab 구성 요소에 대한 새로운 TLS 연결을 형성합니다. 여기에 표시된 대로 구성된 경우, CA에 대한 GitLab 구성 요소에서 제공하는 인증서를 _확인_합니다.

이는 Toolbox Pod에 연결하고 다양한 구성 요소 서비스를 쿼리하여 확인할 수 있습니다. 하나의 예시로, NGINX Ingress가 사용하는 Webservice Pod의 기본 서비스 포트에 연결합니다:

```plaintext
$ kubectl -n ${NAMESPACE} get pod -lapp=toolbox,release=${RELEASE}
NAME                              READY   STATUS    RESTARTS   AGE
gitlab-toolbox-5c447bfdb4-pfmpc   1/1     Running   0          65m
$ kubectl exec -ti gitlab-toolbox-5c447bfdb4-pfmpc -c toolbox -- \
    curl -Iv "https://gitlab-webservice-default.testing.svc:8181"
```

출력은 다음 예제와 유사해야 합니다:

```plaintext
*   Trying 10.60.0.237:8181...
* Connected to gitlab-webservice-default.testing.svc (10.60.0.237) port 8181 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
* ALPN, server did not agree to a protocol
* Server certificate:
*  subject: CN=gitlab.testing.internal
*  start date: Jul 18 19:15:00 2022 GMT
*  expire date: Jul 18 19:15:00 2023 GMT
*  subjectAltName: host "gitlab-webservice-default.testing.svc" matched cert's "*.testing.svc"
*  issuer: CN=gitlab.testing.internal.ca
*  SSL certificate verify ok.
> HEAD / HTTP/1.1
> Host: gitlab-webservice-default.testing.svc:8181
```

## 문제 해결 {#troubleshooting}

GitLab 인스턴스가 브라우저에서 연결할 수 없는 것으로 나타나고 HTTP 503 오류가 표시되면 NGINX Ingress가 GitLab 구성 요소의 인증서를 확인하는 데 문제가 있을 가능성이 있습니다.

`gitlab.webservice.workhorse.tls.verify`을(를) `false`로 설정하여 이 문제를 임시로 해결할 수 있습니다.

NGINX Ingress 컨트롤러에 연결할 수 있으며 `nginx.conf`에서 인증서 확인 문제와 관련된 메시지가 표시됩니다.

시크릿에 도달할 수 없는 예제 내용:

```plaintext
# Location denied. Reason: "error obtaining certificate: local SSL certificate
  testing/gitlab-internal-tls-ca was not found"
return 503;
```

이를 유발하는 일반적인 문제:

- CA 인증서가 시크릿 내의 `ca.crt`이라는 키에 없습니다.
- 시크릿이 제대로 제공되지 않았거나 네임스페이스 내에 존재하지 않을 수 있습니다.
