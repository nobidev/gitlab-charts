---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer du package Linux vers le chart Helm
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Ce guide vous aidera à migrer d'une installation GitLab basée sur un package vers le chart Helm.

## Prérequis {#prerequisites}

Avant la migration, quelques prérequis doivent être satisfaits :

- L'instance GitLab basée sur un package doit être opérationnelle. Exécutez `gitlab-ctl status` et confirmez qu'aucun service ne signale un état `down`.
- Il est recommandé de [vérifier l'intégrité](https://docs.gitlab.com/administration/raketasks/check/) des dépôts Git avant la migration.
- Un déploiement basé sur les charts Helm exécutant la même version de GitLab que l'installation basée sur un package est requis.
- Le chart MinIO intégré n'est pas prêt pour la production. Consultez les [architectures de référence](https://docs.gitlab.com/administration/reference_architectures/) pour configurer un déploiement de qualité production. Si vous souhaitez migrer depuis MinIO intégré, consultez le [guide de migration](bundled_chart_migration.md).
- PostgreSQL et Redis doivent être configurés en tant que services externes avant de déployer le chart Helm GitLab. Consultez [la base de données externe](../../advanced/external-db/_index.md) et [Redis externe](../../advanced/external-redis/_index.md).

## Étapes de migration {#migration-steps}

1. Migrez toutes les données existantes de l'installation basée sur un package vers le stockage objet :

   1. [Migrer vers le stockage objet](https://docs.gitlab.com/administration/object_storage/#migrate-to-object-storage).

   1. Visitez l'instance GitLab basée sur un package et assurez-vous que les données migrées sont disponibles. Par exemple, vérifiez si les avatars des utilisateurs, des groupes et des projets s'affichent correctement, si les images et autres fichiers ajoutés aux tickets se chargent correctement, etc.

1. [Créez une archive tar de sauvegarde](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/) et [excluez tous les répertoires déjà migrés](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#excluding-specific-directories-from-the-backup).

   Pour les sauvegardes locales (par défaut), le fichier de sauvegarde est stocké sous `/var/opt/gitlab/backups`, sauf si vous avez [explicitement modifié l'emplacement](https://docs.gitlab.com/omnibus/settings/backups/#manually-manage-backup-directory). Pour les [sauvegardes sur stockage distant](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#upload-backups-to-a-remote-cloud-storage), le fichier de sauvegarde est stocké dans le bucket configuré.
1. [Restaurez depuis l'installation basée sur un package](../../backup-restore/restore.md) vers le chart Helm, en commençant par les secrets. Vous devrez migrer les valeurs de `/etc/gitlab/gitlab-secrets.json` vers le fichier YAML qui sera utilisé par Helm.
1. Redémarrez tous les pods pour vous assurer que les modifications sont appliquées :

   ```shell
   kubectl delete pods -lrelease=<helm release name>
   ```

1. Visitez le déploiement basé sur Helm et confirmez que les projets, groupes, utilisateurs, tickets, etc. qui existaient dans l'installation basée sur un package sont restaurés. Vérifiez également si les fichiers téléversés (avatars, fichiers téléversés dans les tickets, etc.) se chargent correctement.
