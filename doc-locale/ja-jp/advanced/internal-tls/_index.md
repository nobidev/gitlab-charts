---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのコンポーネント間でTLSを使用する
---

GitLabチャートは、さまざまなコンポーネント間でトランスポート層セキュリティ（TLS）を使用できます。これには、有効にするサービス用の証明書を提供し、それらの証明書と、それらに署名した公開認証局（CA）を利用するようにそれらのサービスを設定する必要があります。

## 準備 {#preparation}

各チャートには、そのサービスのTLSを有効にする方法、および適切な設定を保証するために必要なさまざまな設定に関するドキュメントがあります。

### 内部使用向けの証明書の生成 {#generating-certificates-for-internal-use}

{{< alert type="note" >}}

GitLabは、高度なPKIインフラストラクチャ、または認証局を提供することを目的としていません。

{{< /alert >}}

このドキュメントでは、**概念実証**スクリプトを以下に提供します。これは、自己署名公開認証局（CA）を生成するために[CloudflareのCFSSL](https://github.com/cloudflare/cfssl/)を使用し、すべてのサービスに使用できるワイルドカード証明書を生成します。

このスクリプト:

- CAキーペアを生成します。
- すべてのGitLabコンポーネントサービスエンドポイントを提供する証明書に署名します。
- 2つのKubernetesシークレット オブジェクトを作成します。
  - サーバー証明書とキーペアを持つ`kuberetes.io/tls`タイプのシークレット。
  - `Opaque`タイプの**シークレット**。これは、Ingress CAの公開証明書のみを`ca.crt`として含みます。

前提要件:

- Bash、または互換性のあるShell。
- `cfssl`がShellで使用可能であり、`PATH`内に存在すること。
- `kubectl`が使用可能で、GitLabを後でインストールするKubernetesクラスターを指すように構成されていること。
  - スクリプトを実行する前に、これらの証明書をインストールするネームスペースを作成しておくようにしてください。

このスクリプトの内容をコンピューターにコピーして、結果のファイルを実行可能ファイルにすることができます。`poc-gitlab-internal-tls.sh`をお勧めします。

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

{{< alert type="note" >}}

この_スクリプト_は、CAのプライベートキーを保持しません。これは概念実証ヘルパーであり、_本番環境_での使用を意図したものではありません。

{{< /alert >}}

このスクリプトは、2つの環境変数が設定されていることを想定しています。

1. `NAMESPACE`:GitLabを後でインストールするKubernetesネームスペース。これは、`default`と同様に、`kubectl`にデフォルト設定されています。
1. `RELEASE`:GitLabを後でインストールするために使用するHelmリリース名。これは`gitlab`にデフォルト設定されています。

このスクリプトを操作するには、2つの変数を`export`するか、スクリプト名の前にそれらの値を付加することができます。

```shell
export NAMESPACE=testing
export RELEASE=gitlab

./poc-gitlab-internal-tls.sh
```

スクリプトの実行後、作成された2つのシークレットが見つかり、一時的な作業ディレクトリにはすべての証明書とそのキーが含まれます。

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

#### 必要な証明書のCNとSAN {#required-certificate-cn-and-sans}

さまざまなGitLabコンポーネントは、それぞれのサービスのDNS名を使用して相互に通信します。GitLabチャートによって生成されたIngressオブジェクトは、`tls.verify: true`（これはデフォルトです）の場合、検証する名前をNGINXに提供する必要があります。この結果、各GitLabコンポーネントは、サービスのDNSエントリに受け入れ可能なサービスの名前またはワイルドカードを含むSANを持つ証明書を受け取る必要があります。

- `service-name.namespace.svc`
- `*.namespace.svc`

証明書_内_でこれらのSANを確保できないと、機能しないインスタンスになり、「接続の失敗」または「SSL検証の失敗」を指す、かなり意味不明なログが表示されます。

必要に応じて、`helm template`を使用して、すべてのサービスオブジェクト名の完全なリストを取得できます。GitLabがTLSなしでデプロイされている場合、それらの名前についてKubernetesにクエリできます:

`kubectl -n ${NAMESPACE} get service -lrelease=${RELEASE}`

## 設定 {#configuration}

[設定](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/internal-tls/)の例は、[examples/internal-tls](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/internal-tls/)にあります。

このドキュメントでは、`shared-cert-values.yaml`を提供しました。これは、上記の内部使用向けの証明書の生成の[スクリプト](#generating-certificates-for-internal-use)で生成された証明書を使用するようにGitLabコンポーネントを構成します。

設定するキー項目:

1. グローバル[カスタムCA証明書](../../charts/globals.md#custom-certificate-authorities)。
1. サービスリスナーごとのTLS。（各[チャート](../../charts/_index.md)のドキュメントのcharts/を参照してください）

このプロセスは、YAMLのネイティブアンカー機能を利用することで大幅に簡略化されます。`shared-cert-values.yaml`の切り詰められた スニペットはこれを示しています:

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

## 結果 {#result}

すべてのコンポーネントがサービスリスナーでTLSを提供するように構成されている場合、すべてのGitLabコンポーネント間のすべての通信は、NGINX Ingressから各GitLabコンポーネントへの接続を含め、TLSセキュリティでネットワークを通過します。

_NGINX_ Ingressは受信TLSを終了し、トラフィックを渡す適切なサービスを決定し、次にGitLabコンポーネントへの新しいTLS接続を形成します。ここに示されているように構成されている場合、_CA_に対してGitLabコンポーネントによって提供される証明書も_検証_します。

これは、Toolboxポッドに接続し、さまざまなコンポーネントサービスにクエリすることで検証できます。そのような例の1つは、NGINX Ingressが使用するWebserviceポッドのプライマリサービスポートへの接続です。

```plaintext
$ kubectl -n ${NAMESPACE} get pod -lapp=toolbox,release=${RELEASE}
NAME                              READY   STATUS    RESTARTS   AGE
gitlab-toolbox-5c447bfdb4-pfmpc   1/1     Running   0          65m
$ kubectl exec -ti gitlab-toolbox-5c447bfdb4-pfmpc -c toolbox -- \
    curl -Iv "https://gitlab-webservice-default.testing.svc:8181"
```

出力は、次の例と同様である必要があります:

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

## トラブルシューティング {#troubleshooting}

GitLabインスタンスがブラウザーからアクセスできないように見える場合、HTTP 503エラーをレンダリングすると、NGINX IngressはGitLabコンポーネントの証明書の検証で問題が発生している可能性があります。

これを回避するには、一時的に`gitlab.webservice.workhorse.tls.verify`を`false`に設定します。

NGINX Ingressコントローラーは接続でき、証明書の検証に関する問題について、`nginx.conf`にメッセージが表示されます。

シークレットにアクセスできない場合のコンテンツ例:

```plaintext
# Location denied. Reason: "error obtaining certificate: local SSL certificate
  testing/gitlab-internal-tls-ca was not found"
return 503;
```

これが原因で発生する一般的な問題:

- CA証明書がシークレット内の`ca.crt`という名前のキーにありません。
- シークレットが正しく提供されていないか、ネームスペース内に存在しない可能性があります。
