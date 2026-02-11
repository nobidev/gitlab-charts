---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Envoyゲートウェイを使用する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed
- ステータス: ベータ版

{{< /details >}}

GitLabチャートは、バンドルされているNGINX IngressからゲートウェイAPIへの移行をサポートするために、バンドルされたEnvoyゲートウェイを備えています。

## Envoyゲートウェイの設定 {#configuring-envoy-gateway}

設定の詳細については、[Envoy Gateway](https://gateway.envoyproxy.io/docs/)と[Envoy Gateway Helm Chart](https://github.com/envoyproxy/gateway/tree/main/charts/gateway-helm)を設定してください。

## ゲートウェイAPIリソースの設定 {#configuring-gateway-api-resources}

GitLabチャートは、`Gateway`、`EnvoyProxy`、`EnvoyPatchPolicy`、および各コンポーネントのルートの事前設定デプロイをサポートしています。

詳細については、[グローバルゲートウェイAPIのドキュメント](../globals.md#gateway-api)を確認してください。

## バンドルされたNGINX Ingressからの移行 {#migrating-from-the-bundled-nginx-ingress}

{{< alert type="warning" >}}

この移行により、ダウンタイムが発生します。

{{< /alert >}}

（NGINX）IngressからゲートウェイAPIおよびEnvoyゲートウェイに移行するには:

1. EnvoyおよびゲートウェイAPI CRDをインストールします:

   ```script
   helm template eg-crds oci://docker.io/envoyproxy/gateway-crds-helm \
     --version v1.6.0 \
     --set crds.gatewayAPI.enabled=true \
     --set crds.envoyGateway.enabled=true \
     | kubectl apply --server-side -f -
   ```

1. そうでない場合は、クラウドプロバイダーを介してゲートウェイAPI CRDをインストールするか、[手動で適用](https://gateway-api.sigs.k8s.io/guides/#installing-gateway-api)してクラスターに適用します。

1. NGINX IngressおよびIngressリソースを無効にします:

   ```yaml
   # Disable bundled NGINX Ingress controller.
   nginx-ingress:
     enabled: false

   global:
     # Disable rendering of Ingress resources.
     ingress:
       enabled: false
   ```

1. ゲートウェイAPIのCertmanagerを設定します:

   ```yaml
   # Configure bundled certmanager for Gateway API support.
   certmanager:
     config:
       apiVersion: controller.config.cert-manager.io/v1alpha1
       kind: ControllerConfiguration
       enableGatewayAPI: true

   global:
     gatewayApi:
       configureCertmanager: true
   ```

1. EnvoyおよびゲートウェイAPIリソースを有効にします:

   ```yaml
   global:
     # Disable rendering of Ingress resources.
     gatewayApi:
       # Install a Gateway and Routes for each component.
       enabled: true
       # Install the bundled Envoy Gateway chart, a GatewayClass, a EnvoyPatchPolicy, and the EnvoyProxy resources.
       installEnvoy: true
       # Create a Gateway API compatible certmanager Issuer and configure the Gateway to use it.
       class:
         create: true
   ```

1. オプション: 静的IPアドレスをバインドするようにゲートウェイを設定します。`global.hosts.externalIP`を介して設定されたIPがデフォルトで再利用されます。

   ```yaml
   # Depending on your cloud provider you might to migrate additional annotations.
   global:
     hosts:
       # Only used by Envoy if bundled NGINX Ingress is disabled and no custom
       # gateway addresses are defined.
       externalIP: "127.0.0.1"
     gatewayApi:
       addresses:
        - type: IPAddress
          value: "127.1.1.1"
   ```

1. 更新された値でGitLabチャートのリリースをアップグレードします。
