---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Using the Shared-Secrets Job
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The `shared-secrets` job is responsible for provisioning a variety of secrets
used across the installation, unless otherwise manually specified. This includes:

1. Initial root password
1. Self-signed TLS certificates for all public services: GitLab, Registry, KAS, and GitLab Pages
1. Registry authentication certificates
1. Registry, GitLab Shell, and Gitaly secrets
1. SSH host keys
1. GitLab Rails secret for [encrypted credentials](https://docs.gitlab.com/administration/encrypted_configuration/)

## Installation command line options

The table below contains all the possible configurations that can be supplied to
the `helm install` command using the `--set` flag:

| Parameter                    | Default                                                    | Description |
|------------------------------|------------------------------------------------------------|-------------|
| `enabled`                    | `true`                                                     | [See Below](#disable-functionality) |
| `env`                        | `production`                                               | Rails environment |
| `provider`                   | `job`                                                      | [See Below](#select-a-provisioning-backend) |
| `podLabels`                  |                                                            | Supplemental Pod labels. Will not be used for selectors. |
| `annotations`                |                                                            | Supplemental Pod annotations. |
| `image.pullPolicy`           | `Always`                                                   | **DEPRECATED**: Use `global.kubectl.image.pullPolicy` instead. |
| `image.pullSecrets`          |                                                            | **DEPRECATED**: Use `global.kubectl.image.pullSecrets` instead. |
| `image.repository`           | `registry.gitlab.com/gitlab-org/build/cng/kubectl`         | **DEPRECATED**: Use `global.kubectl.image.repository` instead. |
| `image.tag`                  | `1f8690f03f7aeef27e727396927ab3cc96ac89e7`                 | **DEPRECATED**: Use `global.kubectl.image.tag` instead. |
| `priorityClassName`          |                                                            | [Priority class](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) assigned to pods |
| `rbac.create`                | `true`                                                     | Create RBAC roles and bindings |
| `resources`                  |                                                            | resource requests, limits |
| `securityContext.fsGroup`    | `65534`                                                    | User ID to mount filesystems as |
| `securityContext.runAsUser`  | `65534`                                                    | User ID to run the container as |
| `selfsign.caSubject`         | `GitLab Helm Chart`                                        | selfsign CA Subject |
| `selfsign.image.repository`  | `registry.gitlab.com/gitlab-org/build/cnf/cfssl-self-sign` | selfsign image repository |
| `selfsign.image.pullSecrets` |                                                            | Secrets for the image repository |
| `selfsign.image.tag`         |                                                            | selfsign image tag |
| `selfsign.keyAlgorithm`      | `rsa`                                                      | selfsign cert key algorithm |
| `selfsign.keySize`           | `4096`                                                     | selfsign cert key size |
| `serviceAccount.enabled`     | `true`                                                     | Define serviceAccountName on job(s) |
| `serviceAccount.create`      | `true`                                                     | Create ServiceAccount |
| `serviceAccount.name`        | `RELEASE_NAME-shared-secrets`                              | Service account name to specify on job(s) (and on the serviceAccount itself if `serviceAccount.create=true`) |
| `tolerations`                | `[]`                                                       | Toleration labels for pod assignment |

## Job configuration examples

### `tolerations`

`tolerations` allow you schedule pods on tainted worker nodes

Below is an example use of `tolerations`:

```yaml
tolerations:
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoExecute"
```

## Select a provisioning backend

`provider` selects what provisions the secrets. The secrets themselves, their names, and
their keys are identical either way.

| Value | Description |
|-------|-------------|
| `job` | A `pre-install` and `pre-upgrade` hook job generates the secrets. The default. |
| `controller` | The chart renders an `apps.gitlab.com/v2alpha1` `GitLabSecrets` resource and a controller generates the secrets. No hook job and no RBAC are created. |

`provider: controller` requires the [GitLab Operator](https://docs.gitlab.com/operator/),
which supplies both the CustomResourceDefinition and the controller. Do not use it with
`helm install` directly.

Both providers cover the same ground, including the self-signed wildcard certificate. Under
`provider: controller` the certificate is requested through the `certificates` section of
the `GitLabSecrets` resource instead of the self-signed certificate job.

Setting a `secret` value such as `global.gitaly.authToken.secret` changes which Secret the
chart uses. The chart still creates that Secret if it is missing, and still adds keys that
are absent from it. Existing values are never overwritten, so a Secret you created by hand
keeps the values you set.

> [!note]
> Secrets generated by either backend are not owned by the Helm release, so
> `helm uninstall` does not remove them. For more information, see
> [uninstall](../installation/uninstall.md).

## Disable functionality

Some users may wish to explicitly disable the functionality provided by this job.
To do this, we have provided the `enabled` flag as a boolean, defaulting to `true`.

To disable the job, pass `--set shared-secrets.enabled=false`, or pass the following
in a YAML via the `-f` flag to `helm`:

```yaml
shared-secrets:
  enabled: false
```

> [!note]
> If you disable this job, you **must** manually create all secrets,
> and provide all necessary secret content. See [installation/secrets](../installation/secrets.md#manual-secret-creation-optional)
> for further details.

`enabled: false` disables provisioning entirely, whatever `provider` is set to.

To add a new generated secret to the chart, see
[Add a generated secret](../development/secrets.md).
