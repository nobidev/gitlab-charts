---
stage: Software Supply Chain Security
group: Authentication
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: IAM Data Access Service configuration
---

## Overview

The IAM Data Access Service integration is an **experimental feature** currently available only on **GitLab.com** for testing a pre-release service. This feature is subject to change and should not be used in production environments outside of GitLab.com.

## Status

- **Availability**: GitLab.com only
- **Stability**: Experimental (subject to change)
- **Support**: Limited to GitLab.com infrastructure team

## Configuration

The IAM Data Access Service can be configured through the Helm chart values under `global.appConfig.iamDataAccessService`.

The service is optional: it is only configured when `grpc.host` is set. Self-managed
installations that leave it unset render no configuration, generate no secret, and are
not subject to its configuration checks. GitLab.com configures the gRPC endpoint through
its own deployment values.

### Basic configuration

```yaml
global:
  appConfig:
    iamDataAccessService:
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
| `grpc.host` | string |  | Hostname of the gRPC endpoint. Setting this configures the service. |
| `grpc.port` | integer |  | Port number of the gRPC endpoint. Required when `grpc.host` is set. |
| `authToken.secret` | string | `<Release.Name>-iam-data-access-secret` | Kubernetes secret name containing the authentication token |
| `authToken.key` | string | `iam_data_access_service_token` | Key within the secret containing the authentication token |

## Secret generation

When the IAM Data Access Service is configured (`grpc.host` is set), the Helm chart automatically generates a service authentication token and stores it in a Kubernetes secret. The token is generated using cryptographically secure random bytes and converted to alpha-numeric text.

The secret is created during the initial deployment and persists across upgrades. If the secret already exists, it will not be regenerated.

## Important notes

- This feature is **not** intended for use outside of GitLab.com
- Configuration changes may occur without notice
- The service endpoint and authentication mechanism may change
- Do not rely on this feature for production deployments
- Report issues or feedback to the GitLab SSCS - Authentication team
