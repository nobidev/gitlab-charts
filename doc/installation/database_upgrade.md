---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Upgrade the bundled PostgreSQL version (removed)
remove_date: '2026-07-31'
redirect_to: '../advanced/external-db/_index.md '
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

The bundled PostgreSQL chart has been [deprecated](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart)
and has been removed from the GitLab Helm chart.

Please [migrate](migration/bundled_chart_migration/) to an [externally managed](../advanced/external-db/_index.md) PostgreSQL.

If you need to upgrade the bundled PostgreSQL installation as part of your migration efforts, the related documentation
is available in the [archive](https://archives.docs.gitlab.com/18.9/charts/installation/database_upgrade/).

