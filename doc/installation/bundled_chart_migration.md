---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Migrate from the bundled Redis, PostgreSQL and MinIO
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This guide explains how to migrate from the bundled MinIO, Redis, and PostgreSQL to externally
managed alternatives such as Valkey, CloudNativePG, and Garage.

{{< alert type="warning" >}}

Depending on your requirements, existing infrastructure, and personal preferences, solutions
other than the self-managed components described in this guide may be more suitable. 

Please evaluate cloud provider services or Omnibus-managed PostgreSQL and Redis as alternatives.
For more information, see the [reference architecture documentation](https://docs.gitlab.com/administration/reference_architectures/).

Note that GitLab can only offer best-effort support for the components covered in this guide.

{{< /alert >}}

## Backup GitLab

First [backup](../backup-restore/_index.md) all of the current data and note the backup ID.
If you are migration of MinIO, you will need to download the backup archive to a local
machine.

## Provision external services

To replace the bundled MinIO, Redis and Valkey charts provision externally managed replacements.
For an overview on the available options check the [recommended providers and services](https://docs.gitlab.com/administration/reference_architectures/#recommended-cloud-providers-and-services)
and make sure they meet the [current minimum requirements](https://docs.gitlab.com/install/requirements/)
are met.

### Provision external Valkey/Redis

Provision your external Valkey/Redis service. For example using the official [valkey Helm chart](https://github.com/valkey-io/valkey-helm):

```shell
helm repo add valkey https://valkey.io/valkey-helm/
helm install valkey valkey/valkey \
  --set dataStorage.enabled=true \
  --set dataStorage.size=2Gi \
  --set auth.enabled=true \
  --set auth.aclUsers.default.permissions="~* &* +@all" \
  --set auth.aclUsers.default.password=default-password
```

### Provision external PostgreSQL

1. Provision your external PostgreSQL service. For example using [CloudNativePG](https://cloudnative-pg.io/documentation/current/installation_upgrade/):

   1. Install the CloudNativePG Operator:

      ```shell
      kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.28/releases/cnpg-1.28.0.yaml
      ```

   1. Provision a PostgreSQL cluster for GitLab:

      ```yaml
      apiVersion: postgresql.cnpg.io/v1
      kind: Cluster
      metadata:
        name: gitlab-rails-db
        namespace: gitlab
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
      ```

### Provision external object storage

Provision your external object storage solution, for example [Garage](https://garagehq.deuxfleurs.fr/):

1. Install the Garage Helm chart.

   ```shell
   helm plugin install https://github.com/aslafy-z/helm-git
   helm repo add garage git+https://git.deuxfleurs.fr/Deuxfleurs/garage.git@script/helm?ref=main-v1
   helm install garage garage/garage --set persistence.data.size=5Gi --set persistence.meta.size=250Mi
   ```

1. Initialize the cluster layout:

   ```shell
   Check node IDs
   kubectl exec garage-0  -- /garage status
   Assign nodes to gitlab zone
   kubectl exec garage-0  -- /garage layout assign -z gitlab -c 5G <node IDs>
   ```

1. Create the GitLab buckets

   ```shell
   kubectl exec garage-0  -- /garage bucket create git-lfs
   kubectl exec garage-0  -- /garage bucket create gitlab-artifacts
   kubectl exec garage-0  -- /garage bucket create gitlab-backups
   kubectl exec garage-0  -- /garage bucket create gitlab-ci-secure-files
   kubectl exec garage-0  -- /garage bucket create gitlab-dependency-proxy
   kubectl exec garage-0  -- /garage bucket create gitlab-mr-diffs
   kubectl exec garage-0  -- /garage bucket create gitlab-packages
   kubectl exec garage-0  -- /garage bucket create gitlab-pages
   kubectl exec garage-0  -- /garage bucket create gitlab-terraform-state
   kubectl exec garage-0  -- /garage bucket create gitlab-uploads
   kubectl exec garage-0  -- /garage bucket create registry
   kubectl exec garage-0  -- /garage bucket create runner-cache
   kubectl exec garage-0  -- /garage bucket create tmp
   ```

1. Create a API key and grant access to the created buckets:

   ```shell
   kubectl exec garage-0  -- /garage key create gitlab-app-key
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key git-lfs
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key gitlab-artifacts
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key gitlab-backups
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key gitlab-ci-secure-files
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key gitlab-dependency-proxy
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key gitlab-mr-diffs
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key gitlab-packages
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key gitlab-pages
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key gitlab-terraform-state
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key gitlab-uploads
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key registry
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key runner-cache
   kubectl exec garage-0  -- /garage bucket allow --read --write --key gitlab-app-key tmp
   ```

1. Create a Secret configuring the object storage access:

   ```shell
   cat <<EOF | kubectl create secret generic gitlab-object-storage --from-file=config=/dev/stdin
   provider: AWS
   region: garage
   aws_access_key_id: GARAGE_ACCESS_KEY
   aws_secret_access_key: GARAGE_SECRET_KEY
   endpoint: "http://garage.NAMESPACE.svc.cluster.local:3900"
   path_style: true
   EOF
   ```

1. Create a Secret configuring access for backup/restore:

   ```shell
   cat <<EOF | kubectl create secret generic gitlab-object-storage-s3cmd --from-file=config=/dev/stdin
   [default]
   access_key = GARAGE_ACCESS_KEY
   secret_key = GARAGE_SECRET_KEY
   host_base = garage.NAMESPACE.svc.cluster.local:3900
   host_bucket = garage.NAMESPACE.svc.cluster.local:3900
   use_https = False
   EOF
   ```

## Configure and upgrade GitLab

With all replacements provisioned, you can now disable the bundled MinIO, Redis, and
PostgreSQL. 

1. Update your values to point to the newly provisioned services:

   ```yaml
   global:
     # Configure DB managed by CloudNativePG.
     psql:
       host: gitlab-rails-db-rw.NAMESPACE.svc.cluster.local
       password:
        secret: gitlab-rails-db-app
        key: password
     # Configure Valkey service.
     redis:
       host: valkey.NAMESPACE.svc.cluster.local
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

1. Upgrade your GitLab instance with migrations disabled.

   ```shell
   helm upgrade gitlab gitlab/gitlab -f your-values.yaml --set gitlab.migrations.enabled=false
   ```

1. Copy your backup to the toolbox and upload it to your new Object Storage.

   ```shell
   kubectl cp LOCAL_BACKUP_ARCHIVE.tar TOOLBOX_POD:/tmp
   s3cmd put /tmp/LOCAL_BACKUP_ARCHIVE.tar s3://gitlab-backups/
   ```

1. [Restore the backup](../backup-restore/restore.md):

   ```shell
   kubectl exec -ti TOOLBOX_POD -- bash
   backup-utility --restore -t BACKUP_ID
   ```

1. Upgrade your GitLab instance with migrations enabled.

   ```shell
   helm upgrade gitlab gitlab/gitlab -f your-values.yaml
   ```

1. Confirm GitLab is operational.

1. Confirm [backups](../backup-restore/backup.md) work as intended by doing a fresh backup.

1. Delete Secrets and PersistentVolumeClaims related to the bundled PostgreSQL, MinIO, and Redis.

   ```shell
   kubectl delete pvc gitlab-minio redis-data-gitlab-redis-master-0 data-gitlab-postgresql-0
   kubectl delete secret gitlab-postgresql-password gitlab-redis-secret gitlab-minio-secret gitlab-minio-tls
   ```
