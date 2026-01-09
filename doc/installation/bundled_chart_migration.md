---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate from the bundled Redis, PostgreSQL, and MinIO charts
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

When configuring a production system, you should migrate from the bundled Redis, MinIO, and PostgreSQL to externally
managed alternatives.

This guide assumes you're migrating to Cloud Native alternatives such as [Valkey](https://valkey.io/), [Garage](https://garagehq.deuxfleurs.fr/), and [CloudNativePG](https://cloudnative-pg.io/) respectively.

## Before you begin

Before you begin migrating from the bundled Redis, MinIO, or PostgreSQL:

- Evaluate services that align with the [installation requirements](https://docs.gitlab.com/install/requirements/).
  Consider cloud provider services or other alternatives that meet your infrastructure needs and organizational requirements.
  For general reference architecture considerations and recommended providers, see the
  [reference architecture documentation](https://docs.gitlab.com/administration/reference_architectures/#recommended-cloud-providers-and-services).
- As a result of this migration, upgrading the GitLab chart will no longer upgrade your Redis or
  PostgreSQL deployments. Major GitLab upgrades may require newer versions of Valkey/Redis or PostgreSQL.
  Before following this guide, or before doing a major GitLab upgrade, check the
  [requirements](https://docs.gitlab.com/install/requirements) for your GitLab version.
- Check the current size and data usage of your MinIO, Redis, and PostgreSQL persistent volume claims.
  The guide configures 5 GiB for PostgreSQL, 2 GiB for Valkey, and 5 GiB (replicated 3 times) for Garage
  which might need adjustment.
- Note that GitLab cannot assist with the configuration or troubleshooting of third-party applications
  mentioned in this document. We can ensure that GitLab itself is sending properly formatted data to a
  third party in the bare-minimum configuration.
- Plan in downtime for this migration. During the import of the data into the new external services,
  GitLab won't be accesible.

## Backup GitLab

First [back up](../backup-restore/_index.md) all of the current data and note the backup ID.

Please note that:

- If you are migrating of MinIO, you will need to download the backup archive to a local machine.
- If you are only migrating MinIO, you will need to backup the object storage buckets only.
- If you are only migrating Redis, you can skip the backup and restore steps.
- If you are only migrating PostgreSQL, you can [skip](../backup-restore/backup.md#skipping-components) backing
  up all components but the `db`.
- If you enabled the [Registry Metadata Database](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/)
  the metadata data will not be covered by the [default backup/restore process](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#backup-with-metadata-database).

## Provision external services

To replace the bundled Redis, PostgreSQL, and MinIO charts, provision externally managed replacements.
For an overview on the available options check the [recommended providers and services](https://docs.gitlab.com/administration/reference_architectures/#recommended-cloud-providers-and-services)
and make sure they meet the [current minimum requirements](https://docs.gitlab.com/install/requirements/).

### Provision external Valkey or Redis

Provision your external Valkey or Redis service. For example, by using the official [valkey Helm chart](https://github.com/valkey-io/valkey-helm):

```shell
helm repo add valkey https://valkey.io/valkey-helm/
helm install valkey valkey/valkey -n <NAMSPACE> \
  --set dataStorage.enabled=true \
  --set dataStorage.size=2Gi \
  --set metrics.enabled=true \
  --set auth.enabled=true \
  --set auth.aclUsers.default.permissions="~* &* +@all" \
  --set auth.aclUsers.default.password="<RANDOM PASSWORD>"
```

### Provision external PostgreSQL

Provision your external PostgreSQL service. For example, by using [CloudNativePG](https://cloudnative-pg.io/docs/1.28/installation_upgrade):

1. Install the CloudNativePG Operator:

   ```shell
   kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.28/releases/cnpg-1.28.0.yaml
   ```

1. Provision a PostgreSQL cluster for GitLab (the [Registry Metadata Database](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/) is not covered):

  {{< alert type="note" >}}

  Check the [Cluster API](https://cloudnative-pg.io/docs/1.28/cloudnative-pg.v1/#postgresqlcnpgiov1) to customize your cluster.

  {{< /alert >}}

   ```yaml
   apiVersion: postgresql.cnpg.io/v1
   kind: Cluster
   metadata:
     name: gitlab-rails-db
     namespace: <NAMESPACE>
   spec:
     instances: 1
     imageName: ghcr.io/cloudnative-pg/postgresql:17
     storage:
       size: 5Gi
     bootstrap:
       initdb:
         database: gitlabhq_production
         owner: gitlab
         postInitSQL:
           - CREATE EXTENSION IF NOT EXISTS pg_trgm;
           - CREATE EXTENSION IF NOT EXISTS btree_gist;
           - CREATE EXTENSION IF NOT EXISTS plpgsql;
           - CREATE EXTENSION IF NOT EXISTS amcheck;
           - CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
   ```

### Provision external object storage

To migrate away from the bundled MinIO, provision an external object storage solution.

One option is [Garage](https://garagehq.deuxfleurs.fr/). Before installing it, review their
[deployment guide](https://garagehq.deuxfleurs.fr/documentation/cookbook/real-world/) and
[Kubernetes documentation](https://garagehq.deuxfleurs.fr/documentation/cookbook/kubernetes/).

1. Install the Garage Helm chart:

   ```shell
   helm plugin install https://github.com/aslafy-z/helm-git
   helm repo add garage "git+https://git.deuxfleurs.fr/Deuxfleurs/garage.git@script/helm?ref=main-v1"
   helm install garage garage/garage -n <NAMESPACE> \
     --set persistence.data.size=5Gi \
     --set persistence.meta.size=250Mi
   ```

1. Initialize the cluster layout.

  {{< alert type="note" >}}
  
  This example provisions a Garage layout with three zones, one node per zone, and uses the default replication
  factor of three. Review the [Garage production recommendations](https://garagehq.deuxfleurs.fr/documentation/cookbook/real-world/)
  and adjust these settings to suit your requirements.
  
  {{< /alert >}}

   Since GitLab stores both primary object data and backups in the same storage backend (Garage in this case), any
   failures at the object storage or persistence layer could affect both datasets. Therefore, in addition to
   [backing up GitLab](../backup-restore/_index.md) regularly, you should also familiarize yourself with
   [recovering from Garage failures](https://garagehq.deuxfleurs.fr/documentation/operations/recovering/).

   ```shell
   # Check node IDs
   kubectl exec garage-0  -- /garage status

   # Assign nodes to gitlab zone
   kubectl exec garage-0  -- /garage layout assign -z gitlab1 -c 5G <Node ID 1>
   kubectl exec garage-0  -- /garage layout assign -z gitlab2 -c 5G <Node ID 2>
   kubectl exec garage-0  -- /garage layout assign -z gitlab3 -c 5G <Node ID 3>

   # Apply the layout
   kubectl exec garage-0  -- /garage layout apply --version 1
   ```

1. Create the GitLab buckets:

  {{< alert type="note" >}}
  
  The following command uses the default bucket names from the GitLab chart. If you've customized your bucket names
  previously, adjust them accordingly here and in the steps below.
  
  {{< /alert >}}
   
   ```shell
   buckets=("git-lfs" "gitlab-artifacts" "gitlab-backups" "gitlab-ci-secure-files" \
            "gitlab-dependency-proxy" "gitlab-mr-diffs" "gitlab-packages" "gitlab-pages" \
            "gitlab-terraform-state" "gitlab-uploads" "registry" "runner-cache" "tmp" )
   for bucket in "${buckets[@]}"; do
     kubectl exec -n <NAMESPACE> garage-0  -- /garage bucket create "${bucket}";
   done
   ```

1. Create a API key, note the acess and secret key, and grant access to the created buckets:

   ```shell
   # Create GitLab key. Note down the access and secret key.
   kubectl exec -n <NAMESPACE> garage-0  -- /garage key create gitlab-app-key
   # Grant permissions to the GitLab key.
   for bucket in "${buckets[@]}"; do
     kubectl exec -n <NAMESPACE> garage-0  -- /garage bucket allow --read --write --key gitlab-app-key "${bucket}";
   done
   ```

1. Create a Secret configuring the object storage access. Make sure to replace the `GARAGE_ACCESS_KEY`,
   `GARAGE_SECRET_KEY`, and `NAMESPACE` palceholders:

   ```shell
   cat <<EOF | kubectl create secret generic gitlab-object-storage --from-file=config=/dev/stdin
   provider: AWS
   region: garage
   aws_access_key_id: <GARAGE_ACCESS_KEY>
   aws_secret_access_key: <GARAGE_SECRET_KEY>
   endpoint: "http://garage.<NAMESPACE>.svc.cluster.local:3900"
   path_style: true
   EOF
   ```

1. Create a Secret configuring access for backup/restore:

   ```shell
   cat <<EOF | kubectl create secret generic gitlab-object-storage-s3cmd --from-file=config=/dev/stdin
   [default]
   access_key = <GARAGE_ACCESS_KEY>
   secret_key = <GARAGE_SECRET_KEY>
   host_base = garage.<NAMESPACE>.svc.cluster.local:3900
   host_bucket = garage.<NAMESPACE>.svc.cluster.local:3900
   use_https = False
   EOF
   ```

## Configure and upgrade GitLab

With all replacements provisioned, you can now disable the bundled MinIO, Redis, and
PostgreSQL. 

1. Ensure the MinIO persistent volume will be retained for now.

   ```yaml
   minio:
     persistence:
       # keep: true # Only available in GitLab chart 9.8+
       annotations:
         helm.sh/resource-policy: "keep"
   ```

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml
   kubectl annotate pvc <RELEASE>-minio --list
   ```
  
  {{< alert type="note" >}}

  The Redis and PostgreSQL persistent volumes are managed by their StatefulSet
  instead of Helm. The default retention policy is [`Retain`](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#persistentvolumeclaim-retention).
  Unless you modified this policy, these two volumes will not be deleted when you remove
  their StatefulSet.
  
  {{< /alert >}}

1. Update your values to point to the newly provisioned services:

   ```yaml
   global:
     # Configure DB managed by CloudNativePG.
     psql:
       host: gitlab-rails-db-rw.<NAMESPACE>.svc.cluster.local
       password:
        secret: gitlab-rails-db-app
        key: password
     # Configure Valkey service.
     redis:
       host: valkey.<NAMESPACE>.svc.cluster.local
       auth:
        secret: valkey-auth
        key: default-password
     # Configure Garage as object storage.
     appConfig:
       object_store:
         enabled: true
         connection:
           secret: gitlab-object-storage
           key: config
     # Disable bundled MinIO.
     minio:
       enabled: false
   # Configure backup/restore to use Garage backend.
   gitlab:
     toolbox:
       backups:
         objectStorage:
           config:
             secret: gitlab-object-storage-s3cmd
             key: config

   # Disable bundled PostgreSQL and Redis.
   postgresql:
     install: false
   redis:
     install: false
   ```

   Check the related [Redis](../advanced/external-redis/_index.md), [PostgreSQL](../advanced/external-db/_index.md),
   and [object storage](../advanced/external-object-storage/_index.md) documentation for more
   information.

1. If you are migrating PostgreSQL, upgrade your GitLab instance with migrations disabled:

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml --set gitlab.migrations.enabled=false
   ```

1. If you are migrating MinIO, copy your backup to the toolbox and upload it to your new object storage:

   ```shell
   kubectl cp LOCAL_BACKUP_ARCHIVE.tar TOOLBOX_POD:/tmp
   s3cmd put /tmp/LOCAL_BACKUP_ARCHIVE.tar s3://gitlab-backups/
   ```

1. If you are migrating PostgreSQL or MinIO, [scale down the workloads and restore the backup](../backup-restore/restore.md#restoring-the-backup-file).
1. After the upgrade is complete, upgrade your GitLab instance to run any pending migrations.

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml
   ```

1. Confirm GitLab is operational.

1. Confirm [backups](../backup-restore/backup.md) work as intended by doing a fresh backup.

1. Delete Secrets and PersistentVolumeClaims related to the bundled PostgreSQL, MinIO, and Redis.

   ```shell
   kubectl delete pvc <RELEASE>-minio redis-data-<RELEASE>-redis-master-0 data-<RELEASE>-postgresql-0
   kubectl delete secret <RELEASE>-postgresql-password <RELEASE>-redis-secret <RELEASE>-minio-secret <RELEASE>-minio-tls
   ```
