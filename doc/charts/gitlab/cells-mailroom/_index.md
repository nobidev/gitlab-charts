---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Using the Cells Mailroom chart
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

> [!warning]
> This chart is experimental and intended for the GitLab [Cells](https://docs.gitlab.com/development/cells/)
> architecture. It is disabled by default.

The Cells Mailroom chart deploys the cells-aware mailroom service. Like the
[Mailroom](../mailroom/_index.md) chart it polls the incoming email and Service
Desk mailboxes, but instead of posting each email to Workhorse it asks the
Topology Service which cell owns the email and forwards it to that cell's
internal API. It is deployed once for all cells, not per cell.

For what the service does, how it identifies and routes email, and the meaning
of each configuration setting, see the service documentation:
[`cells-mailroom/DEPLOYMENT.md`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/cells-mailroom/DEPLOYMENT.md).

## Configuration

The service reuses the `global.appConfig.incomingEmail` and
`global.appConfig.serviceDeskEmail` settings shared with the
[Mailroom](../mailroom/_index.md) chart, plus the
`global.appConfig.cell.topologyServiceClient` settings shared with the Rails
components, so it routes to the same mailboxes and Topology Service as the rest
of the deployment.

Enable it and provide the JWT signing key under the subchart:

```yaml
global:
  appConfig:
    cell:
      enabled: true
      topologyServiceClient:
        address: topology-service.example.com:443
        tls:
          enabled: true
          secret: topology-service-tls
    incomingEmail:
      enabled: true
      address: "incoming+%{key}@example.com"
      user: incoming@example.com
      password:
        secret: incoming-email-password
gitlab:
  cells-mailroom:
    enabled: true
    signingKey:
      secret: cells-mailroom-signing-key
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `enabled` | `false` | Deploy the service. |
| `image.repository` | `registry.gitlab.com/gitlab-org/build/cng/gitlab-cells-mailroom` | Image. |
| `signingKey.secret` | | Secret holding the PEM-encoded EC private key used to sign forwarded requests (required when enabled). |
| `signingKey.key` | `tls.key` | Key within `signingKey.secret`. |
| `cellEndpoint.scheme` | `https` | Scheme used to reach a cell's internal API. |
| `cellEndpoint.port` | `8181` | Cell internal API port. Replaces the port the Topology Service returns. |
| `healthCheck.port` | `8080` | Port for the `/liveness` server. The liveness probe uses the same port. |

### Asymmetric JWT verification on the cells

Forwarded requests are signed with an asymmetric JWT (ES256). Each cell verifies
them with the matching public key, configured through
`global.appConfig.incomingEmail.publicKeyFiles` and
`global.appConfig.serviceDeskEmail.publicKeyFiles`. Each entry names a secret and
key holding a PEM-encoded public key:

```yaml
global:
  appConfig:
    incomingEmail:
      publicKeyFiles:
        - secret: incoming-email-mailroom-public-key
          key: tls.pub
```

These are mounted into the Webservice pods, which serve the internal API that
verifies the token, and listed under `public_key_files` in `gitlab.yml`
alongside the existing symmetric `authToken`.
