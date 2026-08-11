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

## Starting a chart with NATS

Configure the NATS connection details, then start the chart:

```shell
helm upgrade --install gitlab . \
  --timeout 600s \
  --set global.hosts.domain=YOUR_IP.nip.io \
  --set global.hosts.externalIP=YOUR_IP \
  --set global.appConfig.nats.servers[0]="tls://nats.example.com:4222" \
  --set global.appConfig.nats.tls.enabled=true \
  --set global.appConfig.nats.tls.secret=nats-client-tls \
  -f examples/kind/values-base.yaml \
  -f examples/kind/values-no-ssl.yaml
```

To connect without TLS, for example against a local development server, set only
`servers` and leave `tls.enabled` unset:

```shell
helm upgrade --install gitlab . \
  --set global.appConfig.nats.servers[0]="nats://127.0.0.1:4222"
```

## Enabling audit event streaming through NATS

Configuring the connection does not route audit events through NATS on its own. After
NATS is configured, an administrator must enable the `use_nats_for_audit_streaming`
application setting. Until then, Rails continues to use the Sidekiq delivery path.
