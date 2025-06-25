---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのTLSを設定
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

このチャートは、NGINX Ingressコントローラーを使用してTLS終端を実行できます。デプロイメント用のTLS証明書を取得する方法を選択できます。詳細については、[グローバルIngress設定](../charts/globals.md#configure-ingress-settings)を参照してください。

## オプション1：cert-managerとLet's Encrypt {#option-1-cert-manager-and-lets-encrypt}

Let's Encryptは、無料で自動化されたオープンな公開認証局（CA）です。証明書は、さまざまなツールを使用して自動的にリクエストできます。このチャートは、一般的な選択肢である[cert-manager](https://github.com/cert-manager/cert-manager)と統合する準備ができています。

*すでにcert-managerを使用している場合*、`global.ingress.annotations`を使用して、cert-managerデプロイメントに[適切なアノテーション](https://cert-manager.io/docs/usage/ingress/#supported-annotations)を設定できます。

*クラスターにcert-managerがまだインストールされていない場合*、このチャートの依存関係としてインストールして設定できます。

### 内部cert-managerとIssuer {#internal-cert-manager-and-issuer}

```shell
helm repo update
helm dep update
helm install gitlab gitlab/gitlab \
  --set certmanager-issuer.email=you@example.com
```

`cert-manager`のインストールは、`installCertmanager`設定によって制御され、チャートでの使用は、`global.ingress.configureCertmanager`設定によって制御されます。これらは両方ともデフォルトで`true`であるため、デフォルトでは発行者のメールのみを提供する必要があります。

### 外部cert-managerと内部Issuer {#external-cert-manager-and-internal-issuer}

外部`cert-manager`を利用できますが、Issuerをこのチャートの一部として提供します。

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set certmanager-issuer.email=you@example.com \
  --set global.ingress.annotations."kubernetes\.io/tls-acme"=true
```

### 外部cert-managerとIssuer（外部） {#external-cert-manager-and-issuer-external}

外部`cert-manager`と`Issuer`リソースを利用するには、自己署名証明書がアクティブにならないように、いくつかの項目を提供する必要があります。

1. 外部`cert-manager`をアクティブにするためのアノテーション（詳細については[ドキュメント](https://cert-manager.io/docs/usage/ingress/#supported-annotations)を参照してください）
1. 各サービスのTLSシークレットの名前（これにより[自己署名動作](#option-4-use-auto-generated-self-signed-wildcard-certificate)が無効になります）

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

## オプション2:独自のワイルドカード証明書を使用する {#option-2-use-your-own-wildcard-certificate}

完全なチェーン証明書とキーを`Secret`としてクラスターに追加します（例：）。

```shell
kubectl create secret tls <tls-secret-name> --cert=<path/to-full-chain.crt> --key=<path/to.key>
```

次のオプションを含めます

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.tls.secretName=<tls-secret-name>
```

### AWS ACMを使用して証明書を管理する {#use-aws-acm-to-manage-certificates}

AWS ACMを使用してワイルドカード証明書を作成している場合、ACM証明書はダウンロードできないため、シークレット経由で指定することはできません。代わりに、`nginx-ingress.controller.service.annotations`を使用して指定します。

```yaml
nginx-ingress:
  controller:
    service:
      annotations:
        ...
        service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:{region}:{user id}:certificate/{id}
```

## オプション3:サービスごとに個別の証明書を使用する {#option-3-use-individual-certificate-per-service}

完全なチェーン証明書をシークレットとしてクラスターに追加し、それらのシークレット名を各Ingressに渡します。

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

{{< alert type="note" >}}

GitLabインスタンスが他のサービスと通信するように設定している場合は、これらのサービスの[証明書チェーン](../charts/globals.md#custom-certificate-authorities)をHelm Chartを介してGitLabに提供する必要がある場合があります。

{{< /alert >}}

## オプション4:自動生成された自己署名ワイルドカード証明書を使用する {#option-4-use-auto-generated-self-signed-wildcard-certificate}

これらのチャートは、自動生成された自己署名ワイルドカード証明書を提供する機能も提供します。これは、Let's Encryptがオプションではない環境で役立ちますが、SSLによるセキュリティは依然として必要です。この機能は、[shared-secrets](../charts/shared-secrets.md)ジョブによって提供されます。

{{< alert type="note" >}}

`gitlab-runner`チャートは、自己署名証明書では適切に機能しません。以下に示すように、無効にすることをお勧めします。

{{< /alert >}}

{{< alert type="note" >}}

`--set global.ingres.tls.enabled=false`のように、TLSをグローバルに無効にしている場合、自己署名証明書は生成されません。

{{< /alert >}}

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set gitlab-runner.install=false
```

次に、`shared-secrets`ジョブは、CA証明書、ワイルドカード証明書、および外部からアクセス可能なすべてのサービスで使用する証明書チェーンを生成します。これらを含むシークレットは、`RELEASE-wildcard-tls`、`RELEASE-wildcard-tls-ca`、および`RELEASE-wildcard-tls-chain`になります。`RELEASE-wildcard-tls-ca`には、デプロイされたGitLabインスタンスにアクセスするユーザーとシステムに配布できるパブリックCA証明書が含まれています。`RELEASE-wildcard-tls-chain`には、CA証明書とワイルドカード証明書の両方が含まれており、`gitlab-runner.certsSecretName=RELEASE-wildcard-tls-chain`を介してGitLab Runnerに直接使用することもできます。

## GitLab PagesのTLS要件 {#tls-requirement-for-gitlab-pages}

[TLSサポートを備えたGitLab Pages](https://docs.gitlab.com/administration/pages/#wildcard-domains-with-tls-support)の場合、`*.<pages domain>`（`<pages domain>`のデフォルト値は`pages.<base domain>`）に適用可能なワイルドカード証明書が必要です。

ワイルドカード証明書が必要なため、cert-managerとLet's Encryptによって自動的に作成することはできません。したがって、cert-managerは、デフォルトではGitLab Pagesに対して無効になっているため（`gitlab-pages.ingress.configureCertmanager`経由）、ワイルドカード証明書を含む独自のk8sシークレットを提供する必要があります。`global.ingress.annotations`を使用して構成された外部cert-managerがある場合は、`gitlab-pages.ingress.annotations`でそのようなアノテーションをオーバーライドすることもできます。

デフォルトでは、このシークレットの名前は`<RELEASE>-pages-tls`です。`gitlab.gitlab-pages.ingress.tls.secretName`設定を使用して、別の名前を指定できます。

```shell
helm install gitlab gitlab/gitlab \
  --set global.pages.enabled=true \
  --set gitlab.gitlab-pages.ingress.tls.secretName=<secret name>
```

## トラブルシューティング {#troubleshooting}

このセクションでは、発生する可能性のある問題の考えられる解決策について説明します。

### SSL終端エラー {#ssl-termination-errors}

Let's EncryptをTLSプロバイダーとして使用していて、証明書関連のエラーが発生している場合は、これをデバッグするいくつかのオプションがあります。

1. 考えられるエラーがないか、[letsdebug](https://letsdebug.net/)でドメインを確認してください。
1. letsdebugがエラーを返さない場合は、cert-managerに関連する問題があるかどうかを確認してください。

   ```shell
   kubectl describe certificate,order,challenge --all-namespaces
   ```

   エラーが表示された場合は、証明書オブジェクトを削除して、新しい証明書のリクエストを強制してみてください。

1. 上記の方法で解決しない場合は、[既存のcert-managerリソース](https://cert-manager.io/docs/installation/kubectl/#uninstalling)を削除して、cert-managerを再インストールすることを検討してください。内部cert-managerを使用している場合は、名前に`certmanager`を含むデプロイメントを削除し、Helm Chartを再インストールします。たとえば、`gitlab`という名前のリリースを想定します。

   ```shell
   kubectl -n <namespace> delete deployment gitlab-certmanager gitlab-certmanager-cainjector gitlab-certmanager-webhook
   helm upgrade --install -n <namespace> gitlab gitlab/gitlab
   ```
