---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Artifact Registry configuration
---

## Overview

The Artifact Registry integration is an **experimental feature** currently available only on **GitLab.com** for connecting GitLab to a pre-release service. This feature is subject to change and should not be used in production environments outside of GitLab.com.

## Status

- **Availability**: GitLab.com only
- **Stability**: Experimental (subject to change)
- **Support**: Limited to GitLab.com infrastructure team

## Configuration

The Artifact Registry connection can be configured through the Helm chart values under `global.appConfig.artifactRegistry`.

The integration is optional and disabled by default, so self-managed installations are not
required to configure it or supply an endpoint. GitLab.com enables it through its own
deployment values.

When the block is unset, the chart renders no `artifact_registry` section into `gitlab.yml`
and mounts nothing.

### Basic configuration

```yaml
global:
  appConfig:
    artifactRegistry:
      enabled: true
      apiUrl: https://artifact-registry.example.com
      authToken:
        secret: gitlab-artifact-registry-credential
        key: token
```

### Configuration options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enabled` | boolean | `false` | Enable or disable the Artifact Registry integration |
| `apiUrl` | string |  | Service root of the Artifact Registry deployment. Required when enabled. Must be an origin: scheme, host, and optional port, with no path |
| `authToken.secret` | string |  | Kubernetes secret name holding the shared service token. When unset, no token is mounted and calls that require one fail closed |
| `authToken.key` | string | `token` | Key in that secret |

`apiUrl` is the service root, not an API base: GitLab appends its own path to the
value, so a value carrying a path composes the wrong request URL.

## Secret generation

The chart does not generate the service token. The same value has to be
configured on the Artifact Registry service, which validates incoming requests
against its own copy, so a token minted here would authenticate against nothing.

Create the secret before enabling the integration, and name it in
`authToken.secret`:

```shell
kubectl create secret generic gitlab-artifact-registry-credential \
  --from-literal=token="<the same token the Artifact Registry service is configured with>"
```

The token is projected into the webservice, Sidekiq, and toolbox pods at
`/etc/gitlab/artifact-registry/.gitlab_artifact_registry_secret`, which is the
path rendered into `gitlab.yml` as `artifact_registry.service_token.secret_file`.

`apiUrl` and the token are independent: an endpoint can be configured before the
token exists. GitLab then fails closed on the calls that authenticate as the
service rather than refusing to start.

## Important notes

- This feature is not intended for use outside of GitLab.com
- Configuration changes may occur without notice
- The service endpoint and authentication mechanism may change
- Do not rely on this feature for production deployments
- Report issues or feedback to the GitLab Package - Container Registry team
