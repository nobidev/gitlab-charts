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
`global.appConfig.serviceDeskEmail.publicKeyFiles`. The keys are fields of one
secret, and each field holds a PEM-encoded public key:

```yaml
global:
  appConfig:
    incomingEmail:
      publicKeyFiles:
        secret: incoming-email-mailroom-public-keys
        keys: [current.pub]
```

The named fields are mounted into the Webservice pods, which serve the internal
API that verifies the token, and listed under `public_key_files` in `gitlab.yml`
alongside the existing symmetric `authToken`. A cell configured with both
accepts either token type, selecting one per request from the token's key ID, so
the in-cell mailroom and cells-mailroom can run at the same time.

#### Rotate a public key

More than one key can be trusted at a time, which is what allows a rotation
without a cutover: publish the new key everywhere first, switch the signer, then
drop the old key.

> [!warning]
> Add the key to the secret before you name its field in `keys`. Naming a field
> the secret does not have leaves the cell unable to verify tokens signed with
> that key.

1. Add the new public key to the secret under a new field, leaving the existing
   fields alone. Name each field so you can tell which key it holds.
1. Add that field to `keys`, keeping the old one, and run `helm upgrade`:

   ```yaml
   global:
     appConfig:
       incomingEmail:
         publicKeyFiles:
           secret: incoming-email-mailroom-public-keys
           keys: [next.pub, current.pub]
   ```

   The cells now accept tokens signed with either key. Changing `keys` changes
   the rendered `gitlab.yml`, which rolls the Webservice pods; the keys are read
   once at startup, so this restart is what puts the new key into use. Editing
   only the secret does not roll the pods and has no effect.
1. Switch cells-mailroom to the new private key (`signingKey`), so it starts
   signing with the key the cells already trust.
1. Once no token is signed with the old key, remove its field from `keys` and
   run `helm upgrade` again. Delete it from the secret afterwards.

Roll back by reversing the order: move the signer back to the old key before
removing the new one from `keys`.
