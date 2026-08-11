---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: NATS messaging
---

The GitLab chart can configure GitLab Rails to connect to an external
[NATS](https://nats.io/) JetStream server. NATS is used for audit event streaming.

> [!warning]
> NATS support is experimental and intended for testing purposes only at the moment.

The chart does not deploy NATS. You must provide an external NATS server.

## Configuration

NATS is configured under `global.appConfig.nats`. The chart renders the `nats` block
into `gitlab.yml` for the Webservice, Sidekiq, and Toolbox components.

| Parameter                                | Description |
|------------------------------------------|-------------|
| `global.appConfig.nats.servers`          | List of NATS server URLs. For example, `tls://nats.example.com:4222`. |
| `global.appConfig.nats.connectTimeout`   | Connection timeout in seconds. |
| `global.appConfig.nats.streamReplicas`   | JetStream stream replication factor. Use `1` for single-node and `3` for clustered deployments. |
| `global.appConfig.nats.tls.enabled`      | Whether to connect over mutual TLS. |
| `global.appConfig.nats.tls.secret`       | Name of the secret that holds the client certificate. |

An empty or absent `servers` list means NATS is not configured. In that case, the
`nats` block is omitted from `gitlab.yml` and Rails falls back to the Sidekiq delivery
path for audit event streaming.

## Mutual TLS

The GitLab NATS clusters use `verify_and_map`. Each client must present a client
certificate whose common name (CN) maps to a NATS user. When `tls.enabled` is `true`,
the referenced secret must contain these keys:

- `ca.crt`
- `tls.crt`
- `tls.key`

The chart mounts these files into each component and points `gitlab.yml` at the mounted
paths under `/srv/gitlab/config/nats/`.

### Per-component client certificates

Because `verify_and_map` maps each certificate CN to a distinct NATS user, each Rails
component can use its own client certificate. Set `global.appConfig.nats.tls.secret` as
a shared default, then override it per component:

- `gitlab.webservice.nats.tls.secret`
- `gitlab.sidekiq.nats.tls.secret`
- `gitlab.toolbox.nats.tls.secret`

A component that does not set its own secret uses the shared
`global.appConfig.nats.tls.secret`.

## Enabling audit event streaming through NATS

Configuring the connection does not route audit events through NATS on its own. After
NATS is configured, an administrator must enable the `use_nats_for_audit_streaming`
application setting. Until then, Rails continues to use the Sidekiq delivery path.

## Test plan and development setup

Use this procedure to check authentication and mutual TLS between GitLab Rails and NATS.
The commands use the `gitlab` namespace and the `gl` release name.

### Issue the certificates

1. Prepare a [development Kubernetes cluster](environment_setup.md#kubernetes-cluster).
1. [Set up the common GitLab dependencies](external-dependencies.md#quick-start).
   Do not install GitLab yet.
1. [Install cert-manager](https://cert-manager.io/docs/installation/) to issue the
   certificates for mutual TLS.
1. Create the certificate authority, the server certificate, and the client certificate:

   ```shell
   kubectl apply -f examples/nats/mtls.certs.yaml
   ```

### Install a NATS server

1. Add the NATS chart repository:

   ```shell
   helm repo add nats https://nats-io.github.io/k8s/helm/charts/
   helm repo update
   ```

1. Create a `nats.values.yaml` file:

   ```yaml
   config:
     jetstream:
       enabled: true
     nats:
       tls:
         enabled: true
         secretName: server-cert-secret
         merge:
           verify: true
   tlsCA:
     enabled: true
     secretName: my-ca-secret
   ```

1. Install the NATS chart:

   ```shell
   helm upgrade --install nats nats/nats -n gitlab -f nats.values.yaml
   ```

### Install GitLab with NATS configured

1. Create a `gitlab.nats.values.yaml` file:

   ```yaml
   global:
     appConfig:
       nats:
         tls:
           enabled: true
           secret: client-cert-secret
         servers:
           - "tls://nats.gitlab.svc.cluster.local:4222"
         connectTimeout: 2
         streamReplicas: 1
   ```

1. Install the GitLab chart:

   ```shell
   helm upgrade --install gl . -n gitlab \
     -f .values/dev-external.values.yaml \
     -f gitlab.nats.values.yaml \
     --set global.hosts.domain=example.com \
     --set certmanager-issuer.email=test@example.com \
     --set installCertmanager=false
   ```

   `installCertmanager=false` skips the bundled cert-manager, because cert-manager is
   already installed in the cluster. The domain and the issuer email do not have to be
   valid, because this procedure needs no external connectivity.

### Check the client connection

1. Wait for the rollout to complete.
1. Open a Rails console in the Toolbox pod:

   ```shell
   kubectl exec -tin gitlab deployments/gl-toolbox -- gitlab-rails console
   ```

1. Publish a message to a test subject:

   ```ruby
   client = Gitlab::Nats.client
   client.publish('test.subject', '{"test": "data"}', message_id: 'test-123')
   # => NATS::JetStream::Error::NoStreamResponse: nats: no response from stream
   client.connected?
   # => true
   ```

> [!note]
> The `NoStreamResponse` error is expected, because no stream serves the test subject.
> A connected client confirms that Rails authenticated to NATS over mutual TLS.
