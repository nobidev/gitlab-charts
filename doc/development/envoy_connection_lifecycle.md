---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Validate the Envoy connection lifecycle for Webservice
---

When Envoy Gateway is used, the chart sets `connectionIdleTimeout` on the Webservice
`BackendTrafficPolicy` so that Envoy closes pooled upstream connections that have
carried no requests. For the default value and how to override it, see
[Gateway timeouts](../charts/gitlab/webservice/_index.md#gateway-timeouts).

Use the following steps on a deployed environment to check that the policy has reached
Envoy, and that upstream connections to Webservice drain after traffic stops.

## Find the Envoy proxy pod and Webservice route

Set the namespace of the GitLab release, then find the chart-managed `Gateway`,
the Envoy proxy pod that serves it, and the Webservice `HTTPRoute`:

```shell
NAMESPACE=<release-namespace>

GATEWAY=$(kubectl get gateway -n "$NAMESPACE" -o jsonpath='{.items[0].metadata.name}')
ENVOY_POD=$(kubectl get pods -A -l "gateway.envoyproxy.io/owning-gateway-name=$GATEWAY" \
  -o jsonpath='{.items[0].metadata.namespace}/{.items[0].metadata.name}')
ROUTE=$(kubectl get httproute -n "$NAMESPACE" -l app=webservice -o jsonpath='{.items[0].metadata.name}')
```

Envoy names the upstream cluster for each route rule `httproute/<namespace>/<route>/rule/<index>`,
so the Webservice clusters all start with `httproute/$NAMESPACE/$ROUTE/`.

## Check the effective idle timeout

The Envoy admin interface listens on port `19000` inside the proxy pod. Port-forward to it:

```shell
kubectl port-forward -n "${ENVOY_POD%%/*}" "${ENVOY_POD##*/}" 19000:19000
```

In a separate terminal, read the idle timeout from the Webservice clusters in the
configuration dump:

```shell
curl -s localhost:19000/config_dump | jq --arg prefix "httproute/$NAMESPACE/$ROUTE/" '
  .configs[]
  | select(."@type" | endswith("ClustersConfigDump"))
  | .dynamic_active_clusters[].cluster
  | select(.name | startswith($prefix))
  | {name, idle_timeout: .typed_extension_protocol_options."envoy.extensions.upstreams.http.v3.HttpProtocolOptions".common_http_protocol_options.idle_timeout}'
```

The `idle_timeout` should match
`gitlab.webservice.backendTrafficPolicy.spec.timeout.http.connectionIdleTimeout`.
If it is missing, the `BackendTrafficPolicy` has not been applied to the route.
Check its status with:

```shell
kubectl get backendtrafficpolicy -n "$NAMESPACE" -o yaml
```

The policy should report an `Accepted` condition of `True` for the `Gateway`.

## Watch upstream connections drain

Envoy exposes Prometheus statistics on port `19001` inside the proxy pod. Port-forward to it:

```shell
kubectl port-forward -n "${ENVOY_POD%%/*}" "${ENVOY_POD##*/}" 19001:19001
```

While sending traffic through the `Gateway`, and after it stops, watch the active
upstream connections for the Webservice clusters:

```shell
watch -n 2 "curl -s localhost:19001/stats/prometheus \
  | grep -E '^envoy_cluster_upstream_cx_(active|overflow)\{' \
  | grep 'envoy_cluster_name=\"httproute/$NAMESPACE/$ROUTE/'"
```

- `envoy_cluster_upstream_cx_active` rises with load, then falls back after the
  connections have been idle for longer than `connectionIdleTimeout`.
- `envoy_cluster_upstream_cx_overflow` counts requests that hit the upstream circuit
  breaker connection limit, and should stay at `0`.

If `envoy_cluster_upstream_cx_active` keeps rising across bursts of traffic and does not
fall back between them, idle connections are not being closed. Check the effective idle
timeout as described in the previous section.
