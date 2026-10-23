---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: CI setup and use
---

## CI Variables

| Variable           | Default Value                        | Description |
|--------------------|--------------------------------------|-------------|
| `LIMIT_TO`         | `""`                                 | Limit pipeline execution to a specific logical block. Available blocks: `eks131`, `gke130`, `gke131`, `gke131a`, `vcluster`. Empty value implies absence of limits - i.e. all components shall be considered for execution. |
| `SKIP_JOB_REGEX`   | `""`                                 | Regular expression of review trigger job names to skip. For example, `/^k3d_arm64/` skips the `k3d_arm64` job. Empty value skips no jobs. |
| `DOCKERHUB_PREFIX` | `docker.io`                          | Override the prefix of DockerHub images. Allows to pull DockerHub from the dependency proxy or another mirror. |
| `DOCKER_MIRROR`    | `https://mirror.gcr.io`              | Default Docker mirror in DinD jobs. |
| `DOCKER_OPTIONS`   | `--registry-mirror ${DOCKER_MIRROR}` | Flags passed to the Docker daemon. |
| `GITLAB_VERSION`   | `""`                                 | CNG image tag to test, for example `master-nix`. Empty value uses the tag derived from `Chart.yaml`. |
| `CNG_REGISTRY`     | `registry.gitlab.com/gitlab-org/build/cng` | Registry holding the CNG images, for example `registry.gitlab.com/gitlab-org/build/cng-mirror`. |

### LIMIT_TO

`LIMIT_TO` allows to isolate singular logical block of pipeline and *only* execute that block skipping all other blocks. This allows for faster iteration as developer may choose to test only a singular platform before code is ready for more thorough testing. It also allows for external pipeline invocations for very specific scenarios.

`LIMIT_TO` accepts only a single value.

Empty value implies that there are no limits and that pipeline shall be executed in full.

### SKIP_JOB_REGEX

`SKIP_JOB_REGEX` allows to skip review trigger jobs whose name matches the
given regular expression. The expression is matched against the full job name,
so anchors should be used for exact targeting. For example, `/^k3d_arm64/`
skips the `k3d_arm64` job while leaving all other review jobs in place.

This is primarily useful for upstream triggers, such as CNG testing images
that are known not to work on certain platforms - for example, amd64-only
images can skip `k3d_arm64` without losing the rest of the review coverage.

Empty value implies that no jobs are skipped.

### CNG image variables

Upstream [CNG](https://gitlab.com/gitlab-org/build/CNG) pipelines trigger
chart test pipelines with `GITLAB_VERSION` to select the image tag. A CNG
fork or mirror, such as `gitlab-org/build/CNG-mirror`, also passes
`CNG_REGISTRY` with its own `CI_REGISTRY_IMAGE`, so the chart tests pull the
images that pipeline built instead of the canonical registry.

The `pin_image_versions` job passes both variables to
`scripts/ci/pin_image_digests.sh`. The script resolves image digests from
`CNG_REGISTRY` and writes per-component `repository` and `tag` values into
the `ci.digests.yaml` artifact used by the review and test deployments. A
missing image fails the lookup, so a misconfigured registry stops the
pipeline instead of silently testing other images.

To pull from a private registry, set `CNG_REGISTRY_USERNAME` and
`CNG_REGISTRY_PASSWORD`. The script logs in with `skopeo` only when
`CNG_REGISTRY_PASSWORD` is set.

The chart `values.yaml` defaults are unchanged. `CNG_REGISTRY` affects only
pipelines that set the variable.

### Docker and DockerHub variables

By default, CI uses some images from DockerHub. The shared runners by use a
mirror to avoid hitting DockerHub rate limits. If your fork uses custom
runnners, that don't use caching or mirroring, you should enable the [dependency proxy](https://docs.gitlab.com/user/packages/dependency_proxy/)
by setting the `DOCKERHUB_PREFIX` to your proxy, for example
`DOCKERHUB_PREFIX: ${CI_DEPENDENCY_PROXY_GROUP_IMAGE_PREFIX}`.

The container build context by default uses the gcr DockerHub mirror. This
behavior can be changed by overriding the `DOCKER_OPTIONS` or `DOCKER_MIRROR`
variables.
