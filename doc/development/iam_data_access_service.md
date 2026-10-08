---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: IAM Data Access Service configuration
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

GitLab calls the IAM Data Access Service over gRPC. Artifact Registry depends on it.

On GitLab Self-Managed, this integration is part of the Artifact Registry closed beta.
Use it only with help from GitLab engineering.

## Configuration

The IAM Data Access Service can be configured through the Helm chart values under `global.appConfig.iamDataAccessService`.

The integration is disabled by default. You need it only if you install Artifact Registry.

### Basic configuration

```yaml
global:
  appConfig:
    iamDataAccessService:
      enabled: true
      grpc:
        host: iam-data-access.example.com
        port: 5005
      authToken:
        secret: gitlab-iam-data-access-token
        key: authToken
```

### Configuration options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable or disable IAM Data Access Service integration |
| `grpc.host` | string |  | Hostname of the gRPC endpoint. Required when enabled. |
| `grpc.port` | integer |  | Port number of the gRPC endpoint. Required when enabled. |
| `grpc.secure` | boolean | `true` | Use TLS for the gRPC connection. Set to `false` only when the connection runs over a trusted network. |
| `authToken.secret` | string | `<Release.Name>-iam-data-access-secret` | Kubernetes secret name containing the authentication token |
| `authToken.key` | string | `iam_data_access_service_token` | Key within the secret containing the authentication token |

## Secret generation

When the IAM Data Access Service is enabled, the Helm chart automatically generates a service authentication token and stores it in a Kubernetes secret. The token is generated using cryptographically secure random bytes and converted to alpha-numeric text.

The secret is created during the initial deployment and persists across upgrades.

To supply your own token, create the secret before you enable the integration, using the
name and key set in `authToken`. The chart does not replace a secret that already exists.

## Important notes

- Configuration options, the service endpoint, and the authentication mechanism may change in later releases while the feature is in beta.
- Report issues or feedback to the GitLab SSCS - Authentication team.
