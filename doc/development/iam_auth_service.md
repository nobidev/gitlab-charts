---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: IAM Auth Service configuration
---

## Overview

The IAM Auth Service integration is an **experimental feature** currently available only on **GitLab.com** for testing a pre-release service. This feature is subject to change and should not be used in production environments outside of GitLab.com.

## Status

- **Availability**: GitLab.com only
- **Stability**: Experimental (subject to change)
- **Support**: Limited to GitLab.com infrastructure team

## Configuration

The IAM Auth Service can be configured through the Helm chart values under `global.appConfig.iamAuthService`.

### Basic configuration

```yaml
global:
  appConfig:
    iamAuthService:
      enabled: true
      http:
        host: iam-auth.example.com
        port: 443
      grpc:
        host: iam-auth.example.com
        port: 5004
      authToken:
        secret: gitlab-iam-auth-token
        key: authToken
```

### Configuration options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable or disable IAM Auth Service integration |
| `http.host` | string |  | Hostname of the HTTP endpoint |
| `http.port` | integer |  | Port number of the HTTP endpoint |
| `grpc.host` | string |  | Hostname of the gRPC endpoint |
| `grpc.port` | integer |  | Port number of the gRPC endpoint |
| `jwtAudience` | string | `gitlab-rails` | The value used for the `aud` scope in JWTs sent to this service |
| `authToken.secret` | string |  | Kubernetes secret name containing the authentication token |
| `authToken.key` | string | `iam_auth_service_token` | Key within the secret containing the authentication token |

## Secret generation

When IAM Auth Service is enabled, the Helm chart automatically generates a service authentication token and stores it in a Kubernetes secret. The token is generated using cryptographically secure random bytes and converted to alpha-numeric text.

The secret is created during the initial deployment and persists across upgrades. If the secret already exists, it will not be regenerated.

## Important notes

- This feature is **not** intended for use outside of GitLab.com
- Configuration changes may occur without notice
- The service endpoint and authentication mechanism may change
- Do not rely on this feature for production deployments
- Report issues or feedback to the GitLab SSCS - Authentication team

## Future considerations

As the IAM Auth Service matures, this feature may be:

- Moved to general availability with full documentation
- Deprecated in favor of alternative authentication mechanisms
- Significantly changed in behavior or configuration

Users should monitor GitLab release notes and this documentation for updates on the status of this experimental feature.
