---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部IngressコントローラーでGitLabチャートを構成する
---

このチャートは、バンドルされたNGINX Ingressで`Ingress`リソースを構成します。このチャートは、IngressからGateway APIへの移行を試みていますが、外部IngressコントローラーでIngressを引き続き使用できます。

## 外部Ingressコントローラーを準備する {#prepare-the-external-ingress-controller}

### NGINX {#nginx}

{{< alert type="warning" >}}

NGINX Ingressは非推奨となり、2026年3月以降はセキュリティパッチを受け取ることはありません。

詳細については、[公式発表](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)をお読みください。

{{< /alert >}}

GitLabで使用する外部NGINX Ingressデプロイを構成および準備するには、[外部NGINX Ingressドキュメント](nginx.md)を確認してください。

### Traefik {#traefik}

GitLab Shell（GitLabのSSHデーモン）のポート22を公開するようにTraefikを構成する必要があります:

```yaml
ports:
  gitlab-shell:
    expose: true
    port: 2222
    exposedPort: 22
```

## GitLab Ingressオプションをカスタマイズする {#customize-the-gitlab-ingress-options}

NGINX Ingressコントローラーは、どのIngressコントローラーが特定の`Ingress`Ingressを処理するかを示す注釈を使用します（[ドキュメント](https://github.com/kubernetes/ingress-nginx#annotation-ingressclass)を参照）。`global.ingress.class`設定を使用して、このチャートで使用するIngressクラスを構成できます。必ずHelmオプションでこれを設定してください。

```shell
--set global.ingress.class=myingressclass
```

必ずしも必須ではありませんが、外部Ingressコントローラーを使用している場合は、このチャートでデフォルトでデプロイされるIngressコントローラーを無効にすることをお勧めします:

```shell
--set nginx-ingress.enabled=false
```

## カスタム証明書管理 {#custom-certificate-management}

外部Ingressコントローラーを使用している場合は、外部cert-managerインスタンスを使用するか、他のカスタム方法で証明書を管理することもできます。TLSオプションの詳細については、[GitLabチャートのTLSの構成](../../installation/tls.md)を参照してください。ただし、このディスカッションの目的のために、cert-managerチャートを無効にし、GitLabコンポーネントチャートに組み込みの証明書リソースを検索しないように指示するために設定する必要がある2つの値を次に示します:

```shell
--set installCertmanager=false
--set global.ingress.configureCertmanager=false
```
