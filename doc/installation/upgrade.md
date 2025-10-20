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

{{< alert type="note" >}}

**Zero-downtime upgrades** are only available for cloud-native GitLab instances by using
[GitLab Operator](https://docs.gitlab.com/operator/gitlab_upgrades/).

{{< /alert >}}

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

## Upgrade GitLab

To upgrade GitLab:

1. Consider [turning on maintenance mode](https://docs.gitlab.com/administration/maintenance_mode/) during the upgrade.
1. [Upgrade GitLab Runner](https://docs.gitlab.com/runner/install/) to the same version as your target GitLab version.
1. Follow the [deployment documentation](deployment.md) step by step.
1. Extract your previously provided values:

   ```shell
   helm get values gitlab > gitlab.yaml
   ```

1. Decide on all the values you need to carry through as you upgrade. You should only keep a minimal set of values that
   you want to explicitly set and pass those during the upgrade process. You should otherwise rely on GitLab default
   values.
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

After you upgrade:

1. If enabled, [turn off maintenance mode](https://docs.gitlab.com/administration/maintenance_mode/#disable-maintenance-mode).
1. Run [upgrade health checks](https://docs.gitlab.com/update/plan_your_upgrade/#run-upgrade-health-checks).

## Upgrade the bundled PostgreSQL

Only perform these steps if you are using the bundled PostgreSQL chart (`postgresql.install` is `true`).

To upgrade the bundled PostgreSQL:

1. Decide [which version of PostgreSQL](https://docs.gitlab.com/install/requirements/#postgresql) to upgrade to.
1. [Prepare the existing database](database_upgrade.md#prepare-the-existing-database).
1. [Delete existing PostgreSQL data](database_upgrade.md#delete-existing-postgresql-data).
1. Update the `postgresql.image.tag` value to the required version of PostgreSQL and
   [reinstall the chart](database_upgrade.md#upgrade-gitlab) to create a new PostgreSQL database.
1. [Restore the database](database_upgrade.md#restore-the-database).
