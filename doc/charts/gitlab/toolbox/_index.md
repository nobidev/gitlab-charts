---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Toolbox
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The Toolbox chart is used to execute periodic housekeeping tasks within the GitLab
application. These tasks include backups, database reindexing, Sidekiq maintenance, and Rake tasks.

## Configuration

The following configuration settings are the default settings provided by the
Toolbox chart:

```yaml
gitlab:
  ## doc/charts/gitlab/toolbox
  toolbox:
    enabled: true
    replicas: 1
    backups:
      cron:
        enabled: false
        concurrencyPolicy: Replace
        failedJobsHistoryLimit: 1
        schedule: "0 1 * * *"
        successfulJobsHistoryLimit: 3
        suspend: false
        backoffLimit: 6
        safeToEvict: false
        restartPolicy: "OnFailure"
        resources:
          requests:
            cpu: 50m
            memory: 350M
        persistence:
          enabled: false
          accessMode: ReadWriteOnce
          useGenericEphemeralVolume: false
          size: 10Gi
      objectStorage:
        backend: s3
        config: {}
      registry:
        database: {}
      openbao:
        database: {}
    databaseReindex:
      cron:
        enabled: false
        concurrencyPolicy: Replace
        failedJobsHistoryLimit: 1
        schedule: "12 * * * 0,6"
        successfulJobsHistoryLimit: 3
        suspend: false
        backoffLimit: 6
        safeToEvict: false
        restartPolicy: "OnFailure"
        resources:
          requests:
            cpu: 200m
            memory: 400M
    persistence:
      enabled: false
      accessMode: 'ReadWriteOnce'
      size: '10Gi'
    resources:
      requests:
        cpu: '50m'
        memory: '350M'
    securityContext:
      fsGroup: '1000'
      runAsUser: '1000'
      runAsGroup: '1000'
    containerSecurityContext:
      runAsUser: '1000'
    affinity: {}
```

| Parameter                                                | Default                                                      | Description |
|----------------------------------------------------------|--------------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                         | [Affinity rules](../_index.md#affinity) for pod assignment |
| `annotations`                                            | `{}`                                                         | Annotations to add to the Toolbox Pods and Jobs |
| `common.labels`                                          | `{}`                                                         | Supplemental labels that are applied to all objects created by this chart. |
| `antiAffinityLabels.matchLabels`                         |                                                              | Labels for setting anti-affinity options |
| `backups.cron.activeDeadlineSeconds`                     | `null`                                                       | Backup CronJob active deadline seconds (if null, no active deadline is applied) |
| `backups.cron.ttlSecondsAfterFinished`                   | `null`                                                       | Backup CronJob job time to live after finished (if null, no time to liveis applied) |
| `backups.cron.safeToEvict`                               | `false`                                                      | Autoscaling safe-to-evict annotation |
| `backups.cron.backoffLimit`                              | `6`                                                          | Backup CronJob backoff limit |
| `backups.cron.concurrencyPolicy`                         | `Replace`                                                    | Kubernetes Job concurrency policy |
| `backups.cron.enabled`                                   | `false`                                                      | Backup CronJob enabled flag |
| `backups.cron.extraArgs`                                 |                                                              | String of arguments to pass to the backup utility |
| `backups.cron.failedJobsHistoryLimit`                    | `1`                                                          | Number of failed backup jobs list in history |
| `backups.cron.persistence.accessMode`                    | `ReadWriteOnce`                                              | Backup cron persistence access mode |
| `backups.cron.persistence.enabled`                       | `false`                                                      | Backup cron enable persistence flag |
| `backups.cron.persistence.matchExpressions`              |                                                              | Label-expression matches to bind |
| `backups.cron.persistence.matchLabels`                   |                                                              | Label-value matches to bind |
| `backups.cron.persistence.useGenericEphemeralVolume`     | `false`                                                      | Use a [generic ephemeral volume](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/#generic-ephemeral-volumes) |
| `backups.cron.persistence.size`                          | `10Gi`                                                       | Backup cron persistence volume size |
| `backups.cron.persistence.storageClass`                  |                                                              | StorageClass name for provisioning |
| `backups.cron.persistence.subPath`                       |                                                              | Backup cron persistence volume mount path |
| `backups.cron.persistence.volumeName`                    |                                                              | Existing persistent volume name |
| `backups.cron.resources.requests.cpu`                    | `50m`                                                        | Backup cron minimum needed CPU |
| `backups.cron.resources.requests.memory`                 | `350M`                                                       | Backup cron minimum needed memory |
| `backups.cron.restartPolicy`                             | `OnFailure`                                                  | Backup cron restart policy (`Never` or `OnFailure`) |
| `backups.cron.schedule`                                  | `0 1 * * *`                                                  | Cron style schedule string |
| `backups.cron.startingDeadlineSeconds`                   | `null`                                                       | Backup cron job starting deadline, in seconds (if null, no starting deadline is applied) |
| `backups.cron.successfulJobsHistoryLimit`                | `3`                                                          | Number of successful backup jobs list in history |
| `backups.cron.suspend`                                   | `false`                                                      | Backup cron job is suspended |
| `backups.cron.timeZone`                                  | `""`                                                         | Time zone for the backup schedule. For more information, see the [Kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones). Uses the cluster time zone if not specified. |
| `backups.cron.tolerations`                               | `""`                                                         | Tolerations to add to the backup cron job |
| `backups.cron.nodeSelector`                              | `""`                                                         | Backup cron job node selection |
| `backups.objectStorage.backend`                          | `s3`                                                         | Object storage provider to use (`s3`, `gcs` or `azure`) |
| `backups.objectStorage.config.gcpProject`                | `""`                                                         | GCP Project to use when backend is `gcs` |
| `backups.objectStorage.config.key`                       | `""`                                                         | Key containing credentials in secret |
| `backups.objectStorage.config.secret`                    | `""`                                                         | Object storage credentials secret |
| `backups.registry.database.backupUser`                   |                                                              | Username for the registry metadata database connection during backups |
| `backups.registry.database.restoreUser`                  |                                                              | Username for the registry metadata database connection during restores |
| `backups.registry.database.password.secret`              | `RELEASE-toolbox-registry-database-password`                 | Name of the Kubernetes secret containing the registry database password for backup and restore |
| `backups.registry.database.password.backupPasswordKey`   | `backupPassword`                                             | Key within the secret that contains the backup database password |
| `backups.registry.database.password.restorePasswordKey`  | `restorePassword`                                            | Key within the secret that contains the restore database password |
| `backups.openbao.database.backupUser`                    |                                                              | Username for the OpenBao database connection during backups |
| `backups.openbao.database.restoreUser`                   |                                                              | Username for the OpenBao database connection during restores |
| `backups.openbao.database.password.secret`               | `RELEASE-toolbox-openbao-database-password`                  | Name of the Kubernetes secret containing the OpenBao database password for backup and restore |
| `backups.openbao.database.password.backupPasswordKey`    | `backupPassword`                                             | Key within the secret that contains the backup database password |
| `backups.openbao.database.password.restorePasswordKey`   | `restorePassword`                                            | Key within the secret that contains the restore database password |
| `databaseReindex.cron.enabled`                           | `false`                                                      | Indicates whether the database reindexing CronJob is enabled |
| `common.labels`                                          | `{}`                                                         | Supplemental labels that are applied to all objects created by this chart. |
| `deployment.strategy`                                    | `{ type: 'Recreate' }`                                       | Allows one to configure the update strategy utilized by the deployment |
| `enabled`                                                | `true`                                                       | Toolbox enablement flag |
| `extra`                                                  | `{}`                                                         | YAML block for [extra `gitlab.yml` configuration](https://gitlab.com/gitlab-org/gitlab/-/blob/8d2b59dbf232f17159d63f0359fa4793921896d5/config/gitlab.yml.example#L1193-1199) |
| `image.pullPolicy`                                       | `IfNotPresent`                                               | Toolbox image pull policy |
| `image.pullSecrets`                                      |                                                              | Toolbox image pull secrets |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee` | Toolbox image repository |
| `image.tag`                                              | `master`                                                     | Toolbox image tag |
| `init.image.repository`                                  |                                                              | Toolbox init image repository |
| `init.image.tag`                                         |                                                              | Toolbox init image tag |
| `init.resources`                                         | `{ requests: { cpu: '50m' }}`                                | Toolbox init container resource requirements |
| `init.containerSecurityContext`                          |                                                              | initContainer specific [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | initContainer specific: Controls whether a process can gain more privileges than its parent process |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                       | initContainer specific: User ID under which the container should be started |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | initContainer specific: Controls whether a process can gain more privileges than its parent process |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                       | initContainer specific: Controls whether the container runs with a non-root user |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                  | initContainer specific: Removes [Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html) for the container |
| `nodeSelector`                                           |                                                              | Toolbox and backup job node selection |
| `persistence.accessMode`                                 | `ReadWriteOnce`                                              | Toolbox persistence access mode |
| `persistence.enabled`                                    | `false`                                                      | Toolbox enable persistence flag |
| `persistence.matchExpressions`                           |                                                              | Label-expression matches to bind |
| `persistence.matchLabels`                                |                                                              | Label-value matches to bind |
| `persistence.size`                                       | `10Gi`                                                       | Toolbox persistence volume size |
| `persistence.storageClass`                               |                                                              | StorageClass name for provisioning |
| `persistence.subPath`                                    |                                                              | Toolbox persistence volume mount path |
| `persistence.volumeName`                                 |                                                              | Existing PersistentVolume name |
| `podLabels`                                              | `{}`                                                         | Labels for running Toolbox Pods |
| `priorityClassName`                                      |                                                              | [Priority class](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) assigned to pods. |
| `replicas`                                               | `1`                                                          | Number of Toolbox Pods to run |
| `resources.requests`                                     | `{ cpu: '50m', memory: '350M' }`                             | Toolbox minimum requested resources |
| `securityContext.fsGroup`                                | `1000`                                                       | File System Group ID under which the pod should be started |
| `securityContext.runAsUser`                              | `1000`                                                       | User ID under which the pod should be started |
| `securityContext.runAsGroup`                             | `1000`                                                       | Group ID under which the pod should be started |
| `securityContext.fsGroupChangePolicy`                    |                                                              | Policy for changing ownership and permission of the volume (requires Kubernetes 1.23) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                             | Seccomp profile to use |
| `containerSecurityContext`                               |                                                              | Override container [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) under which the container is started |
| `containerSecurityContext.runAsUser`                     | `1000`                                                       | Allow to overwrite the specific security context under which the container is started |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                      | Controls whether a process of the container can gain more privileges than its parent process |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                       | Controls whether the container runs with a non-root user |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                  | Removes [Linux capabilities](https://man7.org/linux/man-pages/man7/capabilities.7.html) for the Gitaly container |
| `serviceAccount.annotations`                             | `{}`                                                         | Annotations for ServiceAccount |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                      | Indicates whether or not the default ServiceAccount access token should be mounted in pods |
| `serviceAccount.enabled`                                 | `false`                                                      | Indicates whether or not to use a ServiceAccount |
| `serviceAccount.create`                                  | `false`                                                      | Indicates whether or not a ServiceAccount should be created |
| `serviceAccount.name`                                    |                                                              | Name of the ServiceAccount. If not set, the full chart name is used |
| `tolerations`                                            |                                                              | Tolerations to add to the Toolbox |
| `extraEnvFrom`                                           |                                                              | List of extra environment variables from other data sources to expose |

## Configuring backups

Information concerning configuring backups in the
[backup and restore documentation](../../../backup-restore/_index.md). Additional
information about the technical implementation of how the backups are
performed can be found in the
[backup and restore architecture documentation](../../../architecture/backup-restore.md).]

### Registry metadata database credentials

If you use the [container registry metadata database](../../registry/metadata_database.md),
you can configure the Toolbox to receive registry database connection details
for backup and restore operations. The connection parameters (host, port,
database name, SSL settings) are sourced automatically from the registry
chart's `ConfigMap`. You only need to supply the database usernames and
password secret in the Toolbox values:

```yaml
gitlab:
  toolbox:
    backups:
      registry:
        database:
          backupUser: registry_backup
          restoreUser: registry_restore
          password:
            secret: gitlab-toolbox-registry-database-password
            backupPasswordKey: backupPassword
            restorePasswordKey: restorePassword
```

The default secret name is `RELEASE-toolbox-registry-database-password`, where
`RELEASE` is replaced by the Helm release name (usually `gitlab`). Create the
Kubernetes secret before deploying:

```shell
kubectl create secret generic <RELEASE>-toolbox-registry-database-password \
  --from-literal=backupPassword=<backup_password> \
  --from-literal=restorePassword=<restore_password>
```

The credentials are mounted into the Toolbox pod at
`/etc/gitlab/registry-db/` and are available in both the long-running
Toolbox deployment and the backup CronJob.

#### Required database permissions

The backup and restore users require different privilege levels on the
registry metadata database. When using the bundled PostgreSQL with
Linux package (Omnibus), these users and permissions are created
automatically. For external PostgreSQL, create the users manually.

The **backup user** needs read-only access for `pg_dump`:

```sql
-- Create the backup user
CREATE ROLE registry_backup WITH LOGIN PASSWORD '<backup_password>'
  NOINHERIT NOCREATEDB NOSUPERUSER NOREPLICATION;

-- The partitions schema must exist (created by registry migrations)
-- Grant connect and read-only privileges
GRANT CONNECT ON DATABASE registry TO registry_backup;

GRANT USAGE ON SCHEMA public TO registry_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO registry_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO registry_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE registry IN SCHEMA public
  GRANT SELECT ON TABLES TO registry_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE registry IN SCHEMA public
  GRANT SELECT ON SEQUENCES TO registry_backup;

GRANT USAGE ON SCHEMA partitions TO registry_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA partitions TO registry_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA partitions TO registry_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE registry IN SCHEMA partitions
  GRANT SELECT ON TABLES TO registry_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE registry IN SCHEMA partitions
  GRANT SELECT ON SEQUENCES TO registry_backup;
```

The `ALTER DEFAULT PRIVILEGES` statements ensure the backup user
automatically receives `SELECT` on any tables or sequences the registry
owner (`registry`) creates in the future.

The **restore user** needs superuser privileges to recreate the schema,
set role to the original object owner, and create triggers:

```sql
CREATE ROLE registry_restore WITH LOGIN PASSWORD '<restore_password>'
  SUPERUSER;
```

### OpenBao database credentials

If you use the [OpenBao chart](../../openbao/_index.md), configure the Toolbox with OpenBao
database credentials for backup and restore. Connection parameters (host, port, database name, SSL mode)
are sourced from `global.openbao.psql`. When SSL is enabled, the certificates come from `global.psql.ssl`.

Assuming `global.openbao.psql` is already configured for the OpenBao chart, you only need to supply
the database usernames and password secret in the Toolbox values:

```yaml
gitlab:
  toolbox:
    backups:
      openbao:
        database:
          backupUser: openbao_backup
          restoreUser: openbao_restore
          password:
            secret: gitlab-toolbox-openbao-database-password
            backupPasswordKey: backupPassword
            restorePasswordKey: restorePassword
```

The default secret name is `RELEASE-toolbox-openbao-database-password`, where
`RELEASE` is replaced by the Helm release name (defaults to `gitlab`). Create the
Kubernetes secret with the backup and restore passwords.

```shell
kubectl create secret generic <RELEASE>-toolbox-openbao-database-password \
  --from-literal=backupPassword=<backup_password> \
  --from-literal=restorePassword=<restore_password>
```

The credentials are mounted into the Toolbox pod at `/etc/gitlab/openbao-db/`. They are
available in the long-running Toolbox deployment, and in the backup cron job when
`backups.cron.enabled` is `true`.

If the credential files are missing, the OpenBao database backup is skipped with a warning.
If the files exist but the password file is unreadable or empty, the backup fails with an error.

#### Required database permissions

The backup and restore users require different privilege levels on the OpenBao database.
Create these users in PostgreSQL before running a backup or restore.

The backup user needs read-only access for `pg_dump`:

```sql
CREATE ROLE openbao_backup WITH LOGIN PASSWORD '<backup_password>'
  NOINHERIT NOCREATEDB NOSUPERUSER NOREPLICATION;

GRANT CONNECT ON DATABASE openbao TO openbao_backup;

GRANT USAGE ON SCHEMA public TO openbao_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO openbao_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO openbao_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE openbao IN SCHEMA public
  GRANT SELECT ON TABLES TO openbao_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE openbao IN SCHEMA public
  GRANT SELECT ON SEQUENCES TO openbao_backup;
```

The `ALTER DEFAULT PRIVILEGES` statements ensure the backup user automatically receives
`SELECT` on any tables or sequences the OpenBao owner creates in the future. Replace `openbao` as the owner role
in the example with whatever you set as `global.openbao.psql.username`.

The restore user needs `SUPERUSER` because the dump produced by `pg_dump` includes
`ALTER TABLE ... OWNER TO <owner>` statements (`pg_dump` runs without `--no-owner`). Applying
these requires either the original owner role or `SUPERUSER`, but `SUPERUSER` is the simplest option
for the restore user.

```sql
CREATE ROLE openbao_restore WITH LOGIN PASSWORD '<restore_password>'
  SUPERUSER;
```

## Configure periodic database reindexing

{{< details >}}

Status: Experiment

{{< /details >}}

[Database reindexing](https://docs.gitlab.com/omnibus/settings/database/#automatic-database-reindexing) can be executed periodically to:

- Create and delete indexes asynchronously.
- Run PostgreSQL constraint validation in the background.
- Reindex PostgreSQL indexes to reduce [index bloat](https://wiki.postgresql.org/wiki/Index_Maintenance#Index_Bloat).

Reindexing is performed by the [`gitlab:db:reindex`](https://gitlab.com/gitlab-org/gitlab/blob/9a05e533daeb1013d4c974dd6b3ba066f68585ba/lib/tasks/gitlab/db.rake#L393-402)
Rake task. The Toolbox chart provides a CronJob to run the Rake task periodically.

Enable this CronJob by setting the value `databaseReindex.cron.enabled` to `true`. The job will automatically:

1. Select two indexes with the most [index bloat](https://wiki.postgresql.org/wiki/Index_Maintenance#Index_Bloat).
1. Reindex those indexes in the background.

Set the schedule for the CronJob using the `databaseReindex.cron.schedule` value. You should run the reindexing during low traffic periods. For example,
database reindexing runs for GitLab.com on Saturday and Sunday.

> [!note]
> If you are a Linux package instance administrator, you can enable periodic database reindexing by
> [following relevant instructions](https://docs.gitlab.com/omnibus/settings/database/#automatic-database-reindexing).

## Persistence configuration

The persistent stores for backups and restorations are configured separately.
Please review the following considerations when configuring GitLab for
backup and restore operations.

Backups use the `backups.cron.persistence.*` properties and restorations
use the `persistence.*` properties. Further descriptions concerning the
configuration of a persistence store will use just the final property key
(e.g. `.enabled` or `.size`) and the appropriate prefix will need to be
added.

The persistence stores are disabled by default, thus `.enabled` needs to
be set to `true` for a backup or restoration of any appreciable size.
In addition, either `.storageClass` needs to be specified for a PersistentVolume
to be created by Kubernetes or a PersistentVolume needs to be manually created.
If `.storageClass` is specified as `-`, then the PersistentVolume will be
created using the [default StorageClass](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/)
as specified in the Kubernetes cluster.

If the PersistentVolume is created manually, then the volume can be specified
using the `.volumeName` property or by using the selector `.matchLables` /
`.matchExpressions` properties.

In most cases the default value of `.accessMode` will provide adequate
controls for only Toolbox accessing the PersistentVolumes. Please consult
the documentation for the CSI driver installed in the Kubernetes cluster to
ensure that the setting is correct.

### Backup considerations

A backup operation needs an amount of disk space to hold the individual
components that are being backed up before they are written to the backup
object store. The amount of disk space depends on the following factors:

- Number of projects and the amount of data stored under each project
- Size of the PostgresSQL database (issues, MRs, etc.)
- Size of each object store backend

Once the rough size has been determined, the `backups.cron.persistence.size`
property can be set so that backups can commence.

### Restore considerations

During the restoration of a backup, the backup needs to be extracted to disk
before the files are replaced on the running instance. The size of this
restoration disk space is controlled by the `persistence.size` property. Be
mindful that as the size of the GitLab installation grows the size of the
restoration disk space also needs to grow accordingly. In most cases the
size of the restoration disk space should be the same size as the backup
disk space.

## Toolbox included tools

The Toolbox container contains useful GitLab tools such as Rails console,
Rake tasks, etc. These commands allow one to check the status of the database
migrations, execute Rake tasks for administrative tasks, interact with
the Rails console:

```shell
# locate the Toolbox pod
kubectl get pods -lapp=toolbox

# Launch a shell inside the pod
kubectl exec -it <Toolbox pod name> -- bash

# open Rails console
gitlab-rails console -e production

# execute a Rake task
gitlab-rake gitlab:env:info
```

### `affinity`

For more information, see [`affinity`](../_index.md#affinity).
