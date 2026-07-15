# Local GitLab development with Caproni

[Caproni](https://gitlab.com/gitlab-org/caproni) is a toolkit for local
Kubernetes development environments and Helm-based cloud-native deployments for
GitLab. This example deploys the chart in this repository together with its
external dependencies, so you can test your local chart changes end-to-end.

The chart no longer bundles PostgreSQL, Redis, or MinIO. This example provisions
those dependencies with the
[`gitlab-dev-stack`](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-dev-stack)
chart (PostgreSQL via CloudNativePG, Redis via Valkey, and object storage via
Garage), then deploys GitLab wired to the connection Secrets it creates.

Both releases share the `gitlab` namespace, so those Secrets are found by bare
name. Caproni installs the CloudNativePG operator that `gitlab-dev-stack` uses
to manage PostgreSQL as built-in infrastructure, so you do not deploy it
yourself.

## What this deploys

| Release            | Chart                          | Purpose                                            |
|--------------------|--------------------------------|----------------------------------------------------|
| `gitlab-dev-stack` | `gitlab-dev-stack` (OCI)       | PostgreSQL, Redis, and object storage dependencies |
| `gitlab`           | This repository (local `.tgz`) | The GitLab chart under development                 |

## Prerequisites

- [Caproni](https://gitlab.com/gitlab-org/caproni) 2.16 or later, and a cluster
  driver it supports (for example, `colima` or `k3d`).
- `helm` v3.8 or later (for OCI support).
- Approximately 12 GiB of memory available to the local cluster.

## Deploy

Run these commands from the `examples/caproni/` directory.

> [!important]
> Package the chart before you run `caproni up`. The `.tgz` that `caproni.yaml`
> references lives in `dist/`, which is gitignored and absent from a fresh
> clone. `caproni up` fails with a missing-file error until you create it.

1. Package the local chart. The pinned version keeps the `.tgz` filename stable
   for `caproni.yaml`, then `caproni up` provisions its infrastructure
   (including the CloudNativePG operator) and deploys the dependency stack and
   GitLab.

   ```shell
   helm dependency update ../..
   helm package ../.. --version 0.0.0-local --destination ./dist
   caproni up
   ```

   The first run pulls the cloud-native GitLab images, so it can take around 10
   minutes. GitLab is ready when the `gitlab-webservice-default` pod reports
   `2/2` containers ready.

1. Map the ingress hostname to your cluster so the instance is reachable.

   ```shell
   sudo caproni update-etc-hosts
   ```

GitLab is then available at `http://gitlab.caproni.test`.

## Tear down

```shell
caproni destroy
```

## Customize

- Edit `values-gitlab.yaml` to change GitLab chart settings. It is adapted from
  the `gitlab-dev-stack` chart's
  [`examples/gitlab.yaml`](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-dev-stack/-/blob/main/examples/gitlab.yaml).
- To change the dependencies (for example, PostgreSQL version or bucket list),
  add a `values_file` to the `gitlab-dev-stack` deployer in `caproni.yaml`. The
  chart's defaults already provision every GitLab bucket and both PostgreSQL
  clusters, so no dependency values are required for this example.
