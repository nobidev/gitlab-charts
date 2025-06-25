---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#designated-technical-writers
title: Traefikの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

[Traefik Helm Chart](https://artifacthub.io/packages/helm/traefik/traefik)は、Ingressコントローラーとして[バンドルされたNGINX Helm Chart](../nginx/_index.md)を置き換えることができます。

Traefikは、ネイティブの[Kubernetes Ingress](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)オブジェクトを[IngressRoute](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute)オブジェクトに変換します。

Traefikは[IngressRouteTCP](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroutetcp)オブジェクトを介してSSH経由のGitもサポートしています。[`global.ingress.provider`](../globals.md#configure-ingress-settings)が`traefik`として構成されている場合、これらはGitLab Shell Chartによってデプロイされます。

## Traefikの構成 {#configuring-traefik}

構成の詳細については、[Traefik Helm Chartのドキュメント](https://github.com/traefik/traefik-helm-chart/tree/master/traefik)を参照してください。

[Traefikの構成例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-traefik-ingress.yaml)には、GitLab Helm Chartでテストされた値の詳細なYAMLが含まれています。

### グローバル設定 {#global-settings}

このチャートでは、いくつかの共通のグローバル設定を共有しています。GitLabやレジストリのホスト名など、一般的な構成オプションについては、[グローバルIngressのドキュメント](../globals.md#configure-ingress-settings)を参照してください。

### FIPS準拠のTraefik {#fips-compliant-traefik}

[Traefik Enterprise](https://doc.traefik.io/traefik-enterprise/)は、FIPSコンプライアンスを提供します。Traefik Enterpriseにはライセンスが必要ですが、このチャートには含まれていません。

Traefik Enterpriseの詳細については、以下のリンクを参照してください。

- [Traefik Enterpriseの機能](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
- [Traefik Enterprise FIPSイメージ](https://doc.traefik.io/traefik-enterprise/operations/fips-image/)
- [Traefik Enterprise Helm Chart](https://doc.traefik.io/traefik-enterprise/installing/kubernetes/helm/)
- [ArtifactHub上のTraefik Enterprise Operator](https://artifacthub.io/packages/olm/community-operators/traefikee-operator)
- [RedHatカタログ上のTraefik Enterprise Certified OpenShift Operator](https://catalog.redhat.com/software/container-stacks/detail/5e98745a6c5dcb34dfbb1a0a)
