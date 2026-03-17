---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: IAM Auth Service configuration
---

## Overview

The IAM Auth Service integration is an **experimental feature** currently available only on **gitlab.com** for testing a pre-release service. This feature is subject to change and should not be used in production environments outside of gitlab.com.

## Status

- **Availability**: gitlab.com only
- **Stability**: Experimental (subject to change)
- **Support**: Limited to gitlab.com infrastructure team

## Configuration

The IAM Auth Service can be configured through the Helm chart values under `global.appConfig.iamAuthService`.

### Basic configuration

```yaml
global:
  appConfig:
    iamAuthService:
      enabled: true
      host: iam-auth.example.com
      port: 8080
      authToken:
        secret: gitlab-iam-auth-token
        key: authToken
```

### Configuration options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable or disable IAM Auth Service integration |
| `host` | string | - | Hostname of the IAM Auth Service |
| `port` | integer | - | Port number of the IAM Auth Service |
| `authToken.secret` | string | `gitlab-iam-auth-token` | Kubernetes secret name containing the authentication token |
| `authToken.key` | string | `authToken` | Key within the secret containing the authentication token |

## Secret generation

When IAM Auth Service is enabled, the Helm chart automatically generates a service authentication token and stores it in a Kubernetes secret. The token is generated using cryptographically secure random bytes and is base64-encoded.

The secret is created during the initial deployment and persists across upgrades. If the secret already exists, it will not be regenerated.

## Important notes

- This feature is **not** intended for use outside of gitlab.com
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
