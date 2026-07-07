---
status: Experimental / Internal Use Only
group: Tenant Scale
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: TLS Configuration for Cells Components (Development Only)
---

## Context

As part of the ongoing development of [Cells architecture](https://docs.gitlab.com/ee/development/cells/), TLS configuration has been introduced to support secure communication between the monolith and cell services (e.g., the Topology Service).

At present, TLS-related settings for Cells are placed under:

```yaml
global:
  appConfig:
    cell:
      topologyServiceClient:
        tls:
          enabled: true
          secret: topology-service-tls
```

This aligns with how other sensitive settings (e.g., `client_secret`) are stored under `appConfig`.

### Consumers

The `global.appConfig.cell.topologyServiceClient` block is shared by multiple
components that talk to the Topology Service:

- **Rails** (`webservice`, `sidekiq`, `toolbox`, `migrations`): mounts the
  secret as `tls.crt` / `tls.key` under `/srv/gitlab/config/topology-service/`
  and renders the `topology_service_client` block in `gitlab.yml`.
- **GitLab Shell** (SSH router → Topology Service gRPC): uses an explicit
  opt-in flag, `config.topologyService.enabled`, that is separate from the
  global Cells setting. When enabled, GitLab Shell renders a `topology_service`
  block in `config.yml`. The two concerns are independent:

  - `config.topologyService.enabled` (default `false`) controls whether GitLab
    Shell connects to the Topology Service at all. Set this explicitly; it does
    not inherit the global Cells setting.
  - mTLS is driven by `global.appConfig.cell.enabled`. When GitLab Shell opts
    in and `global.appConfig.cell.enabled` is `true`, the client config includes
    the `tls` section and the mTLS cert/key are mounted and copied. When
    `global.appConfig.cell.enabled` is `false`, the `tls` section is omitted
    and no certs are mounted.
  - The chart defaults `config.topologyService.cellEndpoint.scheme` to `https`
    and `config.topologyService.cellEndpoint.port` to `8181`. Override these
    values for deployments with a different internal API endpoint. The port
    always overrides any port returned by the Topology Service. For more
    information, see [GitLab Shell work item 860](https://gitlab.com/gitlab-org/gitlab-shell/-/work_items/860).

  Example with mTLS enabled (`global.appConfig.cell.enabled: true`):

  ```yaml
  topology_service:
    enabled: true
    address: <topologyServiceClient.address>
    tls:
      enabled: true
      cert_file: /etc/gitlab-secrets/shell/topology-service/tls.crt
      key_file: /etc/gitlab-secrets/shell/topology-service/tls.key
    cell_endpoint:
      scheme: https   # http | https
      port: 8181      # internal API port
  ```

  Example without mTLS (`global.appConfig.cell.enabled: false`):

  ```yaml
  topology_service:
    enabled: true
    address: <topologyServiceClient.address>
    cell_endpoint:
      scheme: https   # http | https
      port: 8181      # internal API port
  ```

  When `config.topologyService.enabled` is `false` (the default), no
  `topology_service` config is emitted, so GitLab Self-Managed and GDK
  deployments are unaffected.

  > [!note]
  > GitLab Shell loads the client certificate once at startup (no hot-reload).
  > After the mounted certificate is rotated (for example by cert-manager),
  > restart the GitLab Shell pods (rolling update) to pick up the new certificate.

---

## Design Discussion & Known Deviation

While placing TLS config under `appConfig.cell` is functional, it's worth noting that:

- Most GitLab components follow the pattern: `global.{component}.tls`
  - Examples: `global.gitaly.tls`, `global.praefect.tls`, `global.kas.tls`, `global.ingress.tls`
- The current approach mixes TLS configuration (an operational concern) with `appConfig` (intended primarily for application runtime settings).

This decision was made for speed and simplicity during the experimental phase but may warrant refactoring in the future.

---

## Naming Note

Another known inconsistency is that the top-level key uses `cell` (singular), while the feature itself is referred to as **Cells** across documentation and architecture discussions. Future cleanup may involve renaming to `global.cells`.

---

## Future Considerations

- Refactor the config structure:
  - Move `tls` to `global.cell.topologyServiceClient.tls` or
  - Rename `appConfig.cell` to `cells` entirely
- Add tests to prevent regressions when restructuring
- Create a user-facing doc once Cells become an officially supported feature
- Review all settings implemented under the experimental `appConfig.cell` structure

---

## Summary

For now, TLS secrets used by Cells-related components (like the Topology Service) live under `global.appConfig.cell`. This is subject to change, and any future consumer-facing exposure will be preceded by a cleanup and proper documentation pass.

> ✅ **Developers:** When adding new Cells-related configuration, consider documenting your additions under `doc/development/cells/` to avoid future gaps.
