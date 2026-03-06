---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Knowledge Graph
---

The GitLab chart can be configured with
[Knowledge Graph](https://gitlab.com/gitlab-org/orbit/knowledge-graph) support.
For configuration options, see the
[Knowledge Graph settings](../charts/globals.md#knowledge-graph-settings).

## Local development setup

This guide walks through deploying GitLab and the GKG service together
on a local Kubernetes cluster to test the gRPC integration.

### Create the namespace and shared JWT secret

The JWT secret must be exactly 32 random bytes, base64-strict-encoded.
The same value is shared between GitLab Rails and the GKG service for
HMAC-SHA256 token signing and verification.

```shell
kubectl create namespace gitlab

JWT_SECRET=$(openssl rand -base64 32)

# Secret for GitLab
kubectl create secret generic gitlab-kg-jwt \
  --namespace gitlab \
  --from-literal=secret="$JWT_SECRET"

# Secret for GKG (same JWT key, plus placeholder ClickHouse passwords)
kubectl create secret generic gkg-secrets \
  --namespace gitlab \
  --from-literal=gitlab-jwt-verifying-key="$JWT_SECRET" \
  --from-literal=gitlab-jwt-signing-key="$JWT_SECRET" \
  --from-literal=datalake-password="placeholder" \
  --from-literal=graph-password="placeholder" \
  --from-literal=graph-read-password="placeholder"
```

### Deploy the GKG service

Install the GKG chart with only the webserver and health-check enabled.
ClickHouse is not required for connection testing.

```shell
helm upgrade --install gkg oci://registry.gitlab.com/gitlab-org/orbit/gkg-helm-charts/gkg \
  --namespace gitlab \
  --set webserver.enabled=true \
  --set indexer.enabled=false \
  --set dispatcher.enabled=false \
  --set healthCheck.enabled=true \
  --set secrets.existingSecret=gkg-secrets \
  --set clickhouse.graph.host=clickhouse-placeholder \
  --set clickhouse.graph.database=graph \
  --set clickhouse.graph.readUser=readonly \
  --set clickhouse.datalake.host=clickhouse-placeholder \
  --set clickhouse.datalake.database=datalake \
  --timeout 120s
```

### Deploy GitLab with Knowledge Graph enabled

The gRPC client only sends the authorization header to addresses it
recognizes as private (raw IPs) or over TLS. In a local setup without
TLS, use the GKG service cluster IP instead of the DNS name:

```shell
GKG_IP=$(kubectl -n gitlab get svc gkg-webserver -o jsonpath='{.spec.clusterIP}')
```

If the service cluster IP does not fall within an RFC 1918 range in your
environment, use the pod IP instead:

```shell
GKG_IP=$(kubectl -n gitlab get pod -l app.kubernetes.io/name=webserver,app.kubernetes.io/instance=gkg -o jsonpath='{.items[0].status.podIP}')
```

In production, TLS is used and the FQDN works as expected.

```shell
cd /path/to/charts/gitlab
helm dependency update

helm upgrade --install gitlab . \
  --namespace gitlab \
  --set global.appConfig.knowledgeGraph.enabled=true \
  --set global.appConfig.knowledgeGraph.jwtSecret.secret=gitlab-kg-jwt \
  --set global.appConfig.knowledgeGraph.jwtSecret.key=secret \
  --set global.appConfig.knowledgeGraph.grpcEndpoint="${GKG_IP}:50054"
```

Wait for the `webservice` pod to show `2/2 Running`:

```shell
kubectl -n gitlab get pods -w
```

## Verification

After both GitLab and GKG are running, verify the gRPC connection
by calling the Knowledge Graph health endpoint from the Rails console.

```shell
TOOLBOX_POD=$(kubectl -n gitlab get pod -l app=toolbox -o jsonpath='{.items[0].metadata.name}')

kubectl exec $TOOLBOX_POD -n gitlab -it -c toolbox -- gitlab-rails runner "
  client = Analytics::KnowledgeGraph::GrpcClient.new
  user = User.find_by_username('root')
  result = client.get_cluster_health(user: user)
  puts result.inspect
"
```

A successful response looks like:

```ruby
{:status=>"healthy", :timestamp=>"...", :version=>"0.8.0",
 :components=>[{:name=>"gkg-gkg-webserver", :status=>"healthy", ...}, ...]}
```

Without ClickHouse the status is `unhealthy`, but a structured response
confirms the gRPC connection and JWT authentication are working. If the
JWT secret is misconfigured, the call fails with `GRPC::Unauthenticated`.
