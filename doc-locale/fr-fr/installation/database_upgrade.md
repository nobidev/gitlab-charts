---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mettre à niveau la version PostgreSQL intégrée (supprimé)
remove_date: '2026-07-31'
redirect_to: '../advanced/external-db/_index.md'
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le chart PostgreSQL intégré a été [déprécié](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart) et a été supprimé du chart Helm de GitLab.

Veuillez [migrer](migration/bundled_chart_migration.md) vers un PostgreSQL [géré en externe](../advanced/external-db/_index.md).

Si vous devez mettre à niveau l'installation PostgreSQL intégrée dans le cadre de vos efforts de migration, la documentation associée est disponible dans l'[archive](https://archives.docs.gitlab.com/18.9/charts/installation/database_upgrade/).
