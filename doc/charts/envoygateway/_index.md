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

GitLab chart bundles the official Envoy Gateway to support migrating from the bundled NGINX Ingress towards Gateway API.

## Upgrade the Envoy Gateway CRDs

Helm does not upgrade custom resource definitions (CRDs) after installation. For more information,
see the [Helm documentation](https://helm.sh/docs/chart_best_practices/custom_resource_definitions/).
GitLab chart installs the Envoy Gateway and Gateway API CRDs on a new installation only. When a
GitLab chart release bundles a new Envoy Gateway version, upgrade the CRDs yourself.

To upgrade the CRDs:

1. Find the Envoy Gateway version that the target GitLab chart version bundles. It is the
   `gateway-helm` dependency in `Chart.yaml`.
1. Apply the CRDs for that version, before you run `helm upgrade`:

   ```shell
   helm template eg-crds oci://docker.io/envoyproxy/gateway-crds-helm \
     --version v1.9.0 \
     --set crds.gatewayAPI.enabled=true \
     --set crds.envoyGateway.enabled=true \
     | kubectl apply --server-side -f -
   ```

   If Helm installed the CRDs, Helm owns their fields and server-side apply reports conflicts.
   Add `--force-conflicts` to `kubectl apply` to take ownership of those fields.

1. Upgrade the GitLab chart.

Outdated CRDs cause one of two failures:

- The upgrade fails when the chart renders a resource kind or API version that the CRDs do not
  serve. For example, GitLab chart 10.3 renders the GitLab Shell `TCPRoute` as
  `gateway.networking.k8s.io/v1`, which the Gateway API 1.5 CRDs from Envoy Gateway 1.8 do not
  serve. The upgrade fails with
  `no matches for kind "TCPRoute" in version "gateway.networking.k8s.io/v1"`.
- The upgrade succeeds, but the API server prunes fields that the CRDs do not define. Kubernetes
  drops these fields without an error, so the setting has no effect and the resource looks correct
  in Helm output. For example, GitLab chart 10.3 sets `stripTrailingHostDot` on the Webservice
  `ClientTrafficPolicy` resources, which the Envoy Gateway 1.8 CRDs do not define.

## Use Envoy Gateway with GitLab

For information on using Envoy Gateway with GitLab, see:

- [Configure Gateway API and Envoy Gateway extensions](../../advanced/gateway-api/_index.md)
- [Migrate to Envoy Gateway](../../installation/migration/envoy_gateway_migration.md)
- [Envoy Gateway documentation](https://gateway.envoyproxy.io/docs/)
- [Envoy Gateway Helm chart](https://github.com/envoyproxy/gateway/tree/main/charts/gateway-helm)
