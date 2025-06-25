---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部のNGINX IngressコントローラーでGitLabチャートを設定する
---

このチャートは、公式の[NGINX Ingress](https://github.com/kubernetes/ingress-nginx)実装で使用するために`Ingress`リソースを設定します。NGINX Ingressコントローラーは、このチャートの一部としてデプロイされます。クラスター内で既に使用可能な既存のNGINX Ingressコントローラーを再利用したい場合に、このガイドが役立ちます。

## 外部IngressコントローラーのTCPサービス {#tcp-services-in-the-external-ingress-controller}

GitLab Shellコンポーネントでは、ポート22 (デフォルト) でTCPトラフィックが通過する必要があります (変更可能)。IngressはTCPサービスを直接サポートしていないため、追加の設定が必要です。NGINX Ingressコントローラーは、[直接デプロイ](https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md) (Kubernetes仕様ファイルを使用) されたか、[公式Helm Chart](https://github.com/kubernetes/ingress-nginx)を通じてデプロイされた可能性があります。TCPパススルーの設定は、デプロイ方法によって異なります。

### 直接デプロイ {#direct-deployment}

直接デプロイでは、NGINX Ingressコントローラーは`ConfigMap`を使用してTCPサービスを設定します (ドキュメントは[こちら](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md)を参照)。GitLabチャートが`gitlab`ネームスペースにデプロイされ、Helmリリースに`mygitlab`という名前が付けられていると仮定すると、`ConfigMap`は次のようになります。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-configmap-example
data:
  22: "gitlab/mygitlab-gitlab-shell:22"
```

その`ConfigMap`を入手したら、`--tcp-services-configmap`オプションを使用して、NGINX Ingressコントローラーの[ドキュメント](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md)に記載されているように有効にできます。

```yaml
args:
  - /nginx-ingress-controller
  - --tcp-services-configmap=gitlab/tcp-configmap-example
```

最後に、NGINX Ingressコントローラーの`Service`が、80および443に加えて、ポート22を公開していることを確認します。

### Helmデプロイ {#helm-deployment}

[Helm Chart](https://github.com/kubernetes/ingress-nginx)を使用してNGINX Ingressコントローラーをインストールした場合、またはインストールする予定の場合は、コマンドラインを使用して値をチャートに追加する必要があります。

```shell
--set tcp.22="gitlab/mygitlab-gitlab-shell:22"
```

または`values.yaml`ファイル:

```yaml
tcp:
  22: "gitlab/mygitlab-gitlab-shell:22"
```

値の形式は、上記の「直接デプロイ」セクションで説明されているものと同じです。

## GitLab Ingressオプションのカスタマイズ {#customize-the-gitlab-ingress-options}

NGINX Ingressコントローラーは、どのIngressコントローラーが特定の`Ingress`にサービスを提供するかを示すために、アノテーションを使用します (ドキュメント[を参照](https://github.com/kubernetes/ingress-nginx#annotation-ingressclass))。`global.ingress.class`設定を使用して、このチャートで使用するIngressクラスを設定できます。必ず、この設定をHelmオプションで設定してください。

```shell
--set global.ingress.class=myingressclass
```

必ずしも必須ではありませんが、外部Ingressコントローラーを使用している場合は、このチャートでデフォルトでデプロイされるIngressコントローラーを無効にすることをお勧めします。

```shell
--set nginx-ingress.enabled=false
```

## カスタム証明書管理 {#custom-certificate-management}

TLSオプションのスコープ全体は、[別の場所](../../installation/tls.md)に記載されています。

外部Ingressコントローラーを使用している場合は、外部cert-managerインスタンスを使用するか、他のカスタム方法で証明書を管理している場合もあります。TLSオプションに関する完全なドキュメントは[こちら](../../installation/tls.md)にありますが、このディスカッションの目的のために、cert-managerチャートを無効にし、組み込みの証明書リソースを検索しないようにGitLabコンポーネントチャートに指示するために設定する必要がある2つの値を示します。

```shell
--set installCertmanager=false
--set global.ingress.configureCertmanager=false
```
