---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer du paquet Linux vers le chart Helm
---

{{< details >}}

- Édition :  version gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Ce guide vous aidera à migrer d'une installation GitLab basée sur un paquet vers le chart Helm.

## Prérequis {#prerequisites}

Avant la migration, vérifiez les prérequis suivants :

- L'instance GitLab basée sur un paquet doit être opérationnelle. Exécutez `gitlab-ctl status` et confirmez qu'aucun service ne signale un état `down`.
- Il est recommandé de [vérifier l'intégrité](https://docs.gitlab.com/administration/raketasks/check/) des dépôts Git avant la migration.
- Un déploiement basé sur les charts Helm exécutant la même version de GitLab que l'installation basée sur un paquet est requis.
- Le stockage d'objets doit être configuré comme service externe avant de déployer le chart Helm GitLab. Consultez l'article [Configurer le stockage d'objets externe](https://docs.gitlab.com/charts/advanced/external-object-storage/) pour en savoir plus.
- PostgreSQL et Redis doivent être configurés en tant que services externes avant de déployer le chart Helm GitLab. Consultez [la base de données externe](../../advanced/external-db/_index.md) et [Redis externe](../../advanced/external-redis/_index.md).

## Étapes de migration {#migration-steps}

1. Migrez toutes les données existantes de l'installation basée sur un paquet vers le stockage d'objets :

   1. [Migrez vers le stockage d'objets](https://docs.gitlab.com/administration/object_storage/#migrate-to-object-storage).

   2. Accédez à l'instance GitLab basée sur un paquet et assurez-vous que les données migrées sont disponibles. Par exemple, vérifiez si les avatars des utilisateurs, des groupes et des projets s'affichent correctement, si les images et autres fichiers ajoutés aux tickets se chargent correctement, etc.

2. [Créez une archive tar de sauvegarde](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/) et [excluez tous les répertoires déjà migrés](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#excluding-specific-directories-from-the-backup).

   Pour les sauvegardes locales (par défaut), le fichier de sauvegarde est stocké sous `/var/opt/gitlab/backups`, sauf si vous avez [explicitement modifié l'emplacement](https://docs.gitlab.com/omnibus/settings/backups/#manually-manage-backup-directory). Pour les [sauvegardes sur stockage distant](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#upload-backups-to-a-remote-cloud-storage), le fichier de sauvegarde est stocké dans le compartiment configuré.
3. [Restaurez depuis l'installation basée sur un paquet](../../backup-restore/restore.md) vers le chart Helm, en commençant par les secrets. Vous devrez migrer les valeurs de `/etc/gitlab/gitlab-secrets.json` vers le fichier YAML qui sera utilisé par Helm.
4. Redémarrez tous les pods pour vous assurer que les modifications sont appliquées :

   ```shell
   kubectl delete pods -lrelease=<helm release name>
   ```

5. Accédez au déploiement basé sur Helm et confirmez que les projets, groupes, utilisateurs, tickets, etc. qui existaient dans l'installation basée sur un paquet sont restaurés. Vérifiez également si les fichiers importés (avatars, fichiers importés dans les tickets, etc.) se chargent correctement.
