---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 번들된 PostgreSQL 버전 업그레이드(제거됨)
remove_date: '2026-07-31'
redirect_to: '../advanced/external-db/_index.md'
---

{{< details >}}

- 등급:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

번들된 PostgreSQL 차트는 [deprecated](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart) 되었으며 GitLab Helm 차트에서 제거되었습니다.

[migrate](migration/bundled_chart_migration.md) 하여 [externally managed](../advanced/external-db/_index.md) PostgreSQL로 이동해 주세요.

마이그레이션 작업 중 번들된 PostgreSQL 설치를 업그레이드해야 하는 경우 관련 문서를 [archive](https://archives.docs.gitlab.com/18.9/charts/installation/database_upgrade/)에서 확인할 수 있습니다.
