---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Upgrade GitLab Helm chart instances
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Upgrade a GitLab Helm chart instance to a later version of GitLab.

## Prerequisites

Before upgrading a GitLab Helm chart instance:

1. Consult [information you need before you upgrade](https://docs.gitlab.com/update/plan_your_upgrade/).
1. Because GitLab Helm chart versions don't follow the same numbering as GitLab versions, see
   [version mappings](version_mappings.md) to find the GitLab Helm chart version you need.
1. See the [CHANGELOG](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/CHANGELOG.md) corresponding to the
   specific release you want to upgrade to.
1. If you're upgrading from versions of the GitLab Helm chart version earlier than 8.x, see the
   [GitLab documentation archives](https://docs.gitlab.com/archives/) to access older versions of the documentation.
1. Perform a [backup](../backup-restore/_index.md).

## Upgrade a GitLab Helm chart instance

To upgrade a GitLab Helm chart instance:

1. Consider [turning on maintenance mode](https://docs.gitlab.com/administration/maintenance_mode/) during the upgrade
   to restrict users from write operations to help not disturb any workflows.
1. [Upgrade GitLab Runner](https://docs.gitlab.com/runner/install/) to the same version as your target GitLab version.
1. Follow the [deployment documentation](deployment.md) step by step.
1. Extract your previously provided values:

   ```shell
   helm get values gitlab > gitlab.yaml
   ```

1. Decide on all the values you need to carry through as you upgrade. You should only keep a minimal set of values that
   you want to explicitly set and pass those during the upgrade process. You should otherwise rely on GitLab default
   values.

### Upgrade with Zero Downtime

Zero-downtime upgrades let you upgrade a live GitLab environment without taking it offline.

#### Requirements

The zero-downtime upgrade process requires:

- A multi-node GitLab Helm chart deployment with multiple replicas configured for Webservice and Sidekiq.
- For any external services (PostgreSQL, Redis, Gitaly), HA mechanisms must be configured. Any services that are not deployed in an HA fashion must be upgraded separately with downtime.
- Upgrade one minor release at a time. So from 18.0 to 18.1, not to 18.2. If you skip releases, database modifications might be run in the wrong sequence and leave the database schema in a broken state.

#### Considerations

When considering a zero-downtime upgrade, be aware that:

- [Gitaly in Kubernetes does not currently support zero-downtime upgrades](https://gitlab.com/gitlab-org/gitaly/-/work_items/6934) and will require downtime.
- Most of the time, you can safely upgrade from a patch release to the next minor release if the patch release is not the latest. For example, upgrading from 18.0.5 to 18.1.0 should be safe even if 18.0.6 exists. We do recommend you check the version-specific upgrade notes for the version you are upgrading to.
- Ensure your deployment has sufficient resources to run both old and new pods simultaneously during the rolling update.

#### Recommended deployment settings

To ensure smooth rolling updates, the settings below are required to control the upgrade process and achieve zero downtime.

These settings are baseline recommendations. You may need to adjust them based on your deployment's resource availability, replica counts, and performance requirements. Ensure you have sufficient cluster resources to support the `maxSurge` setting, which temporarily creates additional pods during an upgrade.

```yaml
gitlab:
  webservice:
    deployment:
      strategy:
        type: RollingUpdate
        rollingUpdate:
          maxSurge: "10%"
          maxUnavailable: 0
    terminationGracePeriodSeconds: 60
    minReadySeconds: 10
  sidekiq:
    deployment:
      strategy:
        type: RollingUpdate
        rollingUpdate:
          maxSurge: "10%"
          maxUnavailable: 0
    terminationGracePeriodSeconds: 60
    minReadySeconds: 10
  gitlab-shell:
    deployment:
      strategy:
        type: RollingUpdate
        rollingUpdate:
          maxSurge: "10%"
          maxUnavailable: 0
    terminationGracePeriodSeconds: 60
  registry:
    deployment:
      strategy:
        type: RollingUpdate
        rollingUpdate:
          maxSurge: "10%"
          maxUnavailable: 0
    terminationGracePeriodSeconds: 60

nginx-ingress:
  controller:
    deployment:
      strategy:
        type: RollingUpdate
        rollingUpdate:
          maxSurge: 1
          maxUnavailable: 0
    terminationGracePeriodSeconds: 300
    minReadySeconds: 10
```

These settings ensure:

- At least one pod is always available during updates.
- New pods are brought up before old ones are terminated.
- Pods have time to gracefully shut down and drain connections.
- Pods are stable before being considered ready.

{{< alert type="note" >}}

If you have an existing GitLab deployment without these rolling update settings configured, you must apply them
before attempting a zero-downtime upgrade. Applying these settings for the first time will trigger a rolling
restart of your pods, which may cause brief service interruptions.

To minimize impact, apply these settings during a maintenance window before your planned upgrade. Once configured,
future upgrades can be performed with zero downtime.

{{< /alert >}}

#### Upgrade process

1. Pause deployments

```shell
kubectl patch deployment gitlab-webservice-default -p '{"spec":{"paused":true}}'
kubectl patch deployment gitlab-sidekiq-all-in-1-v2 -p '{"spec":{"paused":true}}'
```

1. Begin Helm upgrade to new version
   
```shell
helm upgrade gitlab gitlab/gitlab \
  --version 9.1.6 \
  -f values.yaml \
  --set global.extraEnv.SKIP_POST_DEPLOYMENT_MIGRATIONS=true
```

1. Wait for pre-migrations and upgrades to complete

```shell
kubectl get jobs -n <namespace> | grep migrations
kubectl wait --for=condition=complete job/<job name> --timeout=600s
```

1. Run post-migrations

```shell
helm upgrade gitlab gitlab/gitlab \
  -f values.yaml 
```

1. Wait for post-migrations to complete

```shell
kubectl get jobs -n default | grep migrations
kubectl wait --for=condition=complete job/<job name> --timeout=600s
```

1. Unpause deployments for Sidekiq

```shell
kubectl patch deployment gitlab-sidekiq-all-in-1 -p '{"spec":{"paused":false}}'
kubectl rollout status deployment/gitlab-sidekiq-all-in-1-v2 --timeout=15m
```

1. Unpause deployments for Webservice

```shell
kubectl patch deployment gitlab-webservice-default -p '{"spec":{"paused":false}}'
kubectl rollout status deployment/gitlab-webservice-default --timeout=15m
```

### Upgrade with Downtime

1. Perform the upgrade, with values extracted and reviewed in previous steps:

   ```shell
   helm upgrade gitlab gitlab/gitlab \
     --version <new version> \
     -f gitlab.yaml \
     --set gitlab.migrations.enabled=true \
     --set ...
   ```

   During a major database upgrade, you should set `gitlab.migrations.enabled` to `false`.
   Ensure that you explicitly set it back to `true` for future updates.

#### Upgrade the bundled PostgreSQL

Only perform these steps if you are using the bundled PostgreSQL chart (`postgresql.install` is `true`).

To upgrade the bundled PostgreSQL:

1. Decide [which version of PostgreSQL](https://docs.gitlab.com/install/requirements/#postgresql) to upgrade to.
1. [Prepare the existing database](database_upgrade.md#prepare-the-existing-database).
1. [Delete existing PostgreSQL data](database_upgrade.md#delete-existing-postgresql-data).
1. Update the `postgresql.image.tag` value to the required version of PostgreSQL and
   [reinstall the chart](database_upgrade.md#upgrade-gitlab) to create a new PostgreSQL database.
1. [Restore the database](database_upgrade.md#restore-the-database).

## After you upgrade

1. If enabled, [turn off maintenance mode](https://docs.gitlab.com/administration/maintenance_mode/#disable-maintenance-mode).
1. Run [upgrade health checks](https://docs.gitlab.com/update/plan_your_upgrade/#run-upgrade-health-checks).

## Related Topics 

1. [Zero downtime upgrades for Linux package installations](https://docs.gitlab.com/update/zero_downtime/)
1. [Upgrade paths](https://docs.gitlab.com/update/upgrade_paths/)
1. [GitLab upgrade notes](https://docs.gitlab.com/update/versions/)
