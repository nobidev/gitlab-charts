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
> Expect approximately 5 minutes of downtime during migration - The actual time may differ
> depending on your deployment, infrastructure and configuration. For a zero-downtime approach,
> see [zero downtime migration](#zero-downtime-migration).

To migrate from (NGINX) Ingress to Gateway API and Envoy Gateway:

1. Install Envoy and Gateway API CRDs:

   ```script
   helm template eg-crds oci://docker.io/envoyproxy/gateway-crds-helm \
     --version v1.7.0 \
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

1. Configure the Gateway to bind a static IP address. By default the IP configured via `global.hosts.externalIP`
   is reused.

   ```yaml
   # Depending on your cloud provider you might to migrate additional annotations.
   global:
     hosts:
       # Only used by Envoy if bundled NGINX Ingress is disabled and no custom
       # gateway addresses are defined.
       externalIP: "10.10.0.1"
     gatewayApi:
       addresses:
        - type: IPAddress
          value: "10.10.0.2"
       gateway:
         infrastructure:
           annotations: {}
   ```
   
   {{< tabs >}}

   {{< tab title="GKE" >}}

   Instead of using `global.hosts.externalIP` or `global.hosts.gatewayApi.addresses`, configure the
   annotations for the provisioned LoadBalancer:

   ```yaml
   global:
     gatewayApi:
       gateway:
         infrastructure:
           annotations:
             networking.gke.io/load-balancer-type: External
             networking.gke.io/load-balancer-ip-addresses: gitlab-ip-address
             cloud.google.com/l4-rbs: enabled
   ```

   {{< /tab >}}
   
   {{< tab title="EKS" >}}

   To migrate a EKS LoadBalancer migrate your annotations from the NGINX controller Service to
   the Envoy Gateway configuration:   

   ```yaml
   global:
     gatewayApi:
       gateway:
         infrastructure:
           annotations:
             service.beta.kubernetes.io/aws-load-balancer-type: nlb
             service.beta.kubernetes.io/aws-load-balancer-eip-allocations: "gitlab-allocation-id"
             service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
   ```
   
   {{< /tab >}}

   {{< /tabs >}}

1. Upgrade your GitLab chart release with the updated values.

## Zero downtime migration

To perform a zero-downtime migration, you can run NGINX Ingress and Envoy Gateway side by side, allowing
two LoadBalancers to operate simultaneously. Once Envoy Gateway is fully configured to handle GitLab traffic,
update the GitLab DNS records to point to the Envoy Gateway-managed LoadBalancer.

1. Enable Envoy Gateway and Gateway API resources without disabling NGINX Ingress.

   ```yaml
   nginx-ingress:
     enabled: true

   global:
     hosts:
       # External LoadBalancer IP bound by NGINX Ingress
       externalIp: "10.10.0.1"
     # Enable Gateway API and configure another
     gatewayApi:
       enabled: true
       installEnvoy: true
       addresses:
        - type: IPAddress
          value: "10.10.0.2"
       gateway:
         infrastructure:
           annotations: {}
   ```

1. Configure your TLS certificates or a certmanager issuer for the managed Gateway.

   Note: You can't use the Issuer provided by GitLab chart for this purpose. The issuer
   uses HTTP01 which won't be able to retrieve certificates until your DNS records have
   been updated.

   1. Configure a [DNS01 Issuer](https://cert-manager.io/docs/configuration/acme/dns01/) or
      customize the [listeners](../globals.md#gateway-api) to use already existing certificates.

   1. If you created a custom Issuer, enable certmanager's Gateway API support and annotate
      the managed Gateway:

      ```yaml
      # Enable Gateway API support for bundled certmanager.
      certmanager:
        config:
          apiVersion: controller.config.cert-manager.io/v1alpha1
          kind: ControllerConfiguration
          enableGatewayAPI: true

      global:
        gatewayApi:
          # Do not configure HTTP01 issues.
          configureCertmanager: false
          gateway:
            # Annotate Gateway to use custom DNS01 issuer.
            annotations:
              cert-manager.io/issuer: gitlab-dns01
      ```

1. Ensure GitLab is reachable if the domain would resolve to the IP of the Envoy Gateway LoadBalancer:

   ```script
   $ curl -Lso /dev/null \
     --write-out 'Status: %{http_code} TLS: %{ssl_verify_result} (0=OK)' \
     --resolve gitlab.example.com:443:10.10.0.2 \
     "https://gitlab.example.com"
   Status: 200 TLS: 0 (0=OK)
   ```

1. Update your DNS entries to resolve to the Envoy Gateway LoadBalancer.
1. Wait for the DNS entries to propagate to all clients.
1. Disable NGINX Ingress and Ingress objects:

   ```yaml
   nginx-ingress:
     enabled: false

   global:
     ingress:
       enabled: false
   ```
