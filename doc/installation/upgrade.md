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
1. Extract your previously provided values:

   ```shell
   helm get values gitlab > gitlab.yaml
   ```

1. Decide on all the values you need to carry through as you upgrade. You should only keep a minimal set of values that
   you want to explicitly set and pass those during the upgrade process. You should otherwise rely on GitLab default
   values.

### Upgrade with zero downtime

Upgrade a live GitLab environment without taking it offline.

#### Requirements

The zero-downtime upgrade process requires:

- A multi-node GitLab Helm chart deployment with multiple replicas configured for Webservice and Sidekiq.
- Upgrade one minor release at a time. So from 18.0 to 18.1, not to 18.2. If you skip releases, database modifications might be run in the wrong sequence and leave the database schema in a broken state.

#### Considerations

When considering a zero-downtime upgrade, be aware that:

- [Gitaly in Kubernetes does not support zero-downtime upgrades](https://gitlab.com/gitlab-org/gitaly/-/work_items/6934) and requires downtime.
- Most of the time, you can safely upgrade from a patch release to the next minor release if the patch release is not the latest. For example, upgrading from 18.0.5 to 18.1.0 should be safe even if 18.0.6 exists. We do recommend you check the [version-specific upgrade](https://docs.gitlab.com/update/versions/) notes for the version you are upgrading to.
- Ensure your deployment has sufficient resources to run both old and new pods simultaneously during the rolling update. The amount of additional resources required depends on your maxSurge settings. For example, with maxSurge: 10%, you need 10% additional capacity for the new pods to use.

#### Recommended deployment settings

To ensure smooth rolling updates, the settings below are required to control the upgrade process and achieve zero downtime.

These settings are baseline recommendations. You will need to adjust them based on your deployment's resource availability, replica counts, and performance requirements. Ensure you have sufficient cluster resources to support the `maxSurge` setting, which temporarily creates additional pods during an upgrade.

> [!warning]
> If you have an existing GitLab deployment without these rolling update settings configured, you must apply them
> before attempting a zero-downtime upgrade. Applying these settings for the first time triggers a rolling
> restart of your pods, which may cause brief service interruptions.
>
> To minimize impact, apply these settings during a maintenance window before your planned upgrade. After configured,
> future upgrades can be performed with zero downtime.

  ```yaml
  global:
    extraEnv:
      BYPASS_SCHEMA_VERSION: true
  gitlab:
    webservice:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 60
    sidekiq:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 600
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
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 300
      minReadySeconds: 10
  ```

> [!note]
> When configuring the `terminationGracePeriodSeconds` for Sidekiq, you will need to consider your longest running jobs to ensure that they have enough time to complete before the grave period expires.

These settings ensure:

- At least one pod is always available during updates.
- New pods are brought up before old ones are terminated.
- Pods have time to gracefully shut down and drain connections.
- Pods are stable before being considered ready.

#### Upgrade process

> [!note]
> The deployment names used below are examples based on a default GitLab Helm chart installation. Deployment names may vary depending on your configuration, such as when deploying multiple Sidekiq queues.
>
> To find the correct deployment names for your installation:
>
> ```shell
> kubectl get deployments -lapp=webservice -n <namespace>
> kubectl get deployments -lapp=sidekiq -n <namespace>
> ```

To upgrade GitLab:

1. Pause deployments:

   ```shell
   kubectl rollout pause deployment/gitlab-webservice-default
   kubectl rollout pause deployment/gitlab-sidekiq-all-in-1-v2
   ```

1. Begin the upgrade to the new version:
   
   ```shell
   helm upgrade gitlab gitlab/gitlab \
   --version <GitLab Helm chart version> \
   -f values.yaml \
   --set gitlab.migrations.extraEnv.SKIP_POST_DEPLOYMENT_MIGRATIONS=true
   ```

1. Wait for pre-migrations and upgrades to complete:

   ```shell
   kubectl get jobs -lrelease=gitlab,chart=migrations-<GitLab version> -n <namespace>
   kubectl wait --for=condition=complete job/<job name> --timeout=600s
   ```

1. Unpause deployments for Sidekiq:

   ```shell
   kubectl rollout resume deployment/gitlab-sidekiq-all-in-1-v2
   kubectl rollout status deployment/gitlab-sidekiq-all-in-1-v2 --timeout=15m
   ```

1. Unpause deployments for Webservice:

   ```shell
   kubectl rollout resume deployment/gitlab-webservice-default
   kubectl rollout status deployment/gitlab-webservice-default --timeout=15m
   ```

1. Run post-migrations:

   ```shell
   helm upgrade gitlab gitlab/gitlab \
   --version <GitLab Helm chart version> \
   -f values.yaml
   ```

1. Wait for post-migrations to complete:

   ```shell
   kubectl get jobs -lrelease=gitlab,chart=migrations-<GitLab version> -n <namespace>
   kubectl wait --for=condition=complete job/<job name> --timeout=600s
   ```

   > [!note]
   > Depending on your deployment, a `600s` wait time for the migrations to complete might not be enough. You can increase this timeout to fit your needs or periodically check up on the job to ensure it is complete before moving onto the next step.

### Upgrade with downtime

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

## After you upgrade

1. If enabled, [turn off maintenance mode](https://docs.gitlab.com/administration/maintenance_mode/#disable-maintenance-mode).
1. Run [upgrade health checks](https://docs.gitlab.com/update/plan_your_upgrade/#run-upgrade-health-checks).

## Related topics 

1. [Zero downtime upgrades for Linux package installations](https://docs.gitlab.com/update/zero_downtime/)
1. [Upgrade paths](https://docs.gitlab.com/update/upgrade_paths/)
1. [GitLab upgrade notes](https://docs.gitlab.com/update/versions/)
