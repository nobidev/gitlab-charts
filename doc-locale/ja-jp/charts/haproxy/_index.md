---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#designated-technical-writers
title: HAProxyの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

[HAProxy Helm Chart](https://github.com/haproxytech/helm-charts/tree/main/kubernetes-ingress)は、[バンドルされたNGINX Helm Chart](../nginx/_index.md)をIngressコントローラーとして置き換えることができ、Kubernetesの[追加のIngressコントローラーのリスト](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/#additional-controllers)に記載されています。

HAProxyは、SSH経由のGitもサポートします。

主にツールでの過去の経験から[NGINX](../nginx/_index.md)をデフォルトで使用していますが、HAProxyは有効な代替手段であり、特にHAProxyの経験が豊富なユーザーにとってはより好ましい場合があります。さらに、[FIPSコンプライアンス](#fips-compliant-haproxy)を提供しますが、[NGINX Ingressコントローラー](https://github.com/kubernetes/ingress-nginx)は現在提供していません。

## HAProxyの設定 {#configuring-haproxy}

構成の詳細については、[HAProxy Helm Chartドキュメント](https://www.haproxy.com/documentation/kubernetes-ingress/enterprise/configuration-reference/)または[Helm values file](https://github.com/haproxytech/helm-charts/blob/main/kubernetes-ingress/values.yaml)を参照してください。

GitLab Helm Chartでテストされた値の詳細なYAMLについては、[HAProxy構成例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-haproxy-ingress.yaml)を参照してください。

### グローバル設定 {#global-settings}

一部の一般的なグローバル設定は、チャート間で共有されています。GitLabやレジストリのホスト名など、一般的な構成オプションについては、[グローバルIngressドキュメント](../globals.md#configure-ingress-settings)を参照してください。

### FIPS準拠HAProxy {#fips-compliant-haproxy}

[HAProxy Enterprise](https://www.haproxy.com/products/haproxy-enterprise-kubernetes-ingress-controller)は、FIPSコンプライアンスを提供します。HAProxy Enterpriseにはライセンスが必要です。

HAProxy Enterpriseの詳細については、以下のリンクを参照してください。

- [HAProxy Enterpriseランディングページ](https://www.haproxy.com/products/haproxy-enterprise)
- [HAProxy FIPSコンプライアンスのブログ記事](https://www.haproxy.com/blog/become-fips-compliant-with-haproxy-enterprise-on-red-hat-enterprise-linux-8)
- [認定OpenShift Operator](https://catalog.redhat.com/software/container-stacks/detail/5ec3f9fc110f56bd24f2dd57)
- [プライベートレジストリからイメージを使用する方法](https://github.com/haproxytech/helm-charts/blob/kubernetes-ingress-1.22.0/haproxy/README.md#installing-from-a-private-registry)
- [HAProxy Enterpriseイメージを見つける方法](https://www.haproxy.com/documentation/haproxy-enterprise/getting-started/installation/docker/)
