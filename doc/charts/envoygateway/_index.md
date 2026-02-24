---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Using Envoy Gateway
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Beta

{{< /details >}}

GitLab chart bundled Envoy Gateway to support migrating from the bundled NGINX Ingress towards Gateway API.

## Configuring Envoy Gateway

To configure [Envoy Gateway](https://gateway.envoyproxy.io/docs/) and [Envoy Gateway Helm chart](https://github.com/envoyproxy/gateway/tree/main/charts/gateway-helm)
for configuration details.

## Configuring Gateway API resources

GitLab chart supports deploying a pre-configured `Gateway`, `EnvoyProxy`, `EnvoyPatchPolicy`, and
routes for each component.

For more information check the [global Gateway API documentation](../globals.md#gateway-api).

## Migrating from the bundled NGINX Ingress

> [!warning]
> This migration results in downtime.

To migrate from (NGINX) Ingress to Gateway API and Envoy Gateway:

1. Install Envoy and Gateway API CRDs:

   ```script
   helm template eg-crds oci://docker.io/envoyproxy/gateway-crds-helm \
     --version v1.6.0 \
     --set crds.gatewayAPI.enabled=true \
     --set crds.envoyGateway.enabled=true \
     | kubectl apply --server-side -f -
   ```

1. If not, install the Gateway API CRDs through your cloud provider or [manually apply](https://gateway-api.sigs.k8s.io/guides/#installing-gateway-api)
   to your cluster.

1. Disable NGINX Ingress and Ingress resources:

   ```yaml
   # Disable bundled NGINX Ingress controller.
   nginx-ingress:
     enabled: false

   global:
     # Disable rendering of Ingress resources.
     ingress:
       enabled: false
   ```

1. Configure Certmanager for Gateway API:

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

1. Enable Envoy and Gateway API resources:

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

1. Optional: Configure the Gateway to bind a static IP address. By default the IP configured via `global.hosts.externalIP`
   is reused.

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

1. Upgrade your GitLab chart release with the updated values.
