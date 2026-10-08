---
stage: Package
group: Container Registry
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Artifact Registry configuration
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

This integration connects GitLab to an Artifact Registry deployment. Artifact Registry
also needs the [IAM Data Access Service](iam_data_access_service.md) integration.

On GitLab Self-Managed, Artifact Registry is in closed beta. Use it only with help from
GitLab engineering.

## Configuration

The Artifact Registry connection can be configured through the Helm chart values under `global.appConfig.artifactRegistry`.

The integration is disabled by default.

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

- Configuration options, the service endpoint, and the authentication mechanism may change in later releases while the feature is in beta.
- Report issues or feedback to the GitLab Package - Container Registry team.
