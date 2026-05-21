---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sauvegarde et restauration
---

Ce document explique l'implémentation technique de la sauvegarde et de la restauration vers/depuis CNG.

## Pod Toolbox {#toolbox-pod}

Le [chart toolbox](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts/gitlab/charts/toolbox) déploie un pod dans le cluster. Ce pod servira de point d'entrée pour interagir avec les autres conteneurs du cluster.

En utilisant ce pod, l'utilisateur peut exécuter des commandes à l'aide de `kubectl exec -it <pod name> -- <arbitrary command>`

Le Toolbox exécute un conteneur à partir de l'[image Toolbox](https://gitlab.com/gitlab-org/build/CNG/tree/master/gitlab-toolbox).

L'image contient des [scripts personnalisés](https://gitlab.com/gitlab-org/build/CNG/-/tree/master/gitlab-toolbox/scripts/bin) qui doivent être appelés comme commandes par l'utilisateur. Ces scripts servent à exécuter des tâches Rake, des sauvegardes, des restaurations et quelques scripts auxiliaires pour interagir avec le stockage d'objets.

## Utilitaire de sauvegarde {#backup-utility}

L'[utilitaire de sauvegarde](https://gitlab.com/gitlab-org/build/CNG/-/blob/master/gitlab-toolbox/scripts/bin/backup-utility) est l'un des scripts du conteneur toolbox et, comme son nom l'indique, c'est un script utilisé pour effectuer des sauvegardes mais qui gère également la restauration d'une sauvegarde existante.

### Sauvegardes {#backups}

Le script de l'utilitaire de sauvegarde, lorsqu'il est exécuté sans arguments, crée une archive tar de sauvegarde et la téléverse vers le stockage d'objets.

#### Séquence d'exécution {#sequence-of-execution}

Les sauvegardes sont effectuées en suivant les étapes ci-dessous, dans l'ordre :

1. Sauvegarder la base de données (si non ignorée) à l'aide de la [tâche Rake de sauvegarde GitLab](https://gitlab.com/gitlab-org/build/CNG/-/blob/f65867afa54f6d0033e19f9e9038ec680abd5eb2/gitlab-toolbox/scripts/bin/backup-utility#L217)
1. Sauvegarder les dépôts (si non ignorés) à l'aide de la [tâche Rake de sauvegarde GitLab](https://gitlab.com/gitlab-org/build/CNG/-/blob/f65867afa54f6d0033e19f9e9038ec680abd5eb2/gitlab-toolbox/scripts/bin/backup-utility#L220)
1. Pour chacun des backends de stockage d'objets
   1. Si le backend de stockage d'objets est marqué comme devant être ignoré, ignorer ce backend de stockage.
   1. Archiver les données existantes dans le bucket de stockage d'objets correspondant en le nommant `<bucket-name>.tar`
   1. Déplacer l'archive tar vers l'emplacement de sauvegarde sur le disque
1. Écrire un fichier `backup_information.yml` qui contient des métadonnées identifiant la version de GitLab, l'heure de la sauvegarde et les éléments ignorés.
1. Créer un fichier tar contenant les fichiers tar individuels ainsi que `backup_information.yml`
1. Téléverser le fichier tar résultant dans le bucket `gitlab-backups` du stockage d'objets.

#### Arguments de ligne de commande {#command-line-arguments}

- `--skip <component>`

  Vous pouvez ignorer des parties du processus de sauvegarde en utilisant `--skip <component>` pour chaque composant que vous souhaitez ignorer dans le processus de sauvegarde. Les composants pouvant être ignorés sont répertoriés dans [Exclure des données spécifiques de la sauvegarde](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#excluding-specific-data-from-the-backup).

- `-t <timestamp-override-value>`

  Cela vous donne un contrôle partiel sur le nom de la sauvegarde : lorsque vous spécifiez ce flag, la sauvegarde créée sera nommée `<timestamp-override-value>_gitlab_backup.tar`. La valeur par défaut est l'horodatage UNIX actuel, postfixé avec la date actuelle formatée selon `YYYY_mm_dd`.

- `--backend <backend>`

  Configure le backend de stockage d'objets à utiliser pour les sauvegardes. Peut être soit `s3` soit `gcs`. La valeur par défaut est `s3`.

- `--storage-class <storage-class-name>`

  Il est également possible de spécifier la classe de stockage dans laquelle la sauvegarde est stockée en utilisant `--storage-class <storage-class-name>`, ce qui vous permet de réduire les coûts de stockage des sauvegardes. Si non spécifié, la valeur par défaut du backend de stockage sera utilisée.

  Ce nom de classe de stockage est transmis tel quel à l'argument de classe de stockage de votre backend spécifié.

#### Bucket de sauvegarde GitLab {#gitlab-backup-bucket}

Le nom par défaut du bucket utilisé pour stocker les sauvegardes est `gitlab-backups`. Cette valeur est configurable à l'aide de la variable d'environnement `BACKUP_BUCKET_NAME`.

#### Sauvegarde vers Google Cloud Storage {#backing-up-to-google-cloud-storage}

Par défaut, l'utilitaire de sauvegarde utilise `s3cmd` pour téléverser et télécharger des artefacts depuis le stockage d'objets. Bien que cela puisse fonctionner avec Google Cloud Storage (GCS), cela nécessite l'utilisation de l'API d'interopérabilité qui implique des compromis indésirables en matière d'authentification et d'autorisation. Lors de l'utilisation de Google Cloud Storage pour les sauvegardes, vous pouvez configurer le script de l'utilitaire de sauvegarde pour utiliser l'interface CLI native de Cloud Storage, `gsutil`, afin d'effectuer le téléversement et le téléchargement de vos artefacts en définissant la variable d'environnement `BACKUP_BACKEND` sur `gcs`.

### Sauvegarde et restauration de la base de données de métadonnées du registre {#registry-metadata-database-backup-and-restore}

La [base de données de métadonnées du registre de conteneurs](../charts/registry/metadata_database.md) est une base de données PostgreSQL distincte appartenant au registre, et non à GitLab Rails. Étant donné que la tâche Rake de sauvegarde GitLab standard ne couvre que la base de données Rails, la sauvegarde et la restauration de la base de données de métadonnées du registre nécessitent que ses propres identifiants de base de données soient disponibles dans le pod Toolbox.

Lorsqu'il est configuré, le chart monte les fichiers suivants sous `/etc/gitlab/registry-db/` afin que les outils de sauvegarde et de restauration puissent se connecter à la base de données du registre indépendamment de la base de données Rails :

- `connection.env` — paramètres de connexion (hôte, port, nom de la base de données, mode SSL, chemins des certificats). Provient du `ConfigMap` du chart du registre.
- `backup-user.env` / `restore-user.env` — substitutions du nom d'utilisateur de la base de données pour la sauvegarde et la restauration. Provient d'un `ConfigMap` Toolbox.
- `backup-pass` / `restore-pass` — mots de passe correspondants. Provient d'un `Secret` Kubernetes.

Des utilisateurs distincts pour la sauvegarde et la restauration sont pris en charge afin que les opérateurs puissent suivre le principe du moindre privilège (par exemple, un utilisateur en lecture seule pour les sauvegardes et un utilisateur avec accès en écriture pour les restaurations).

Toutes les sources de volumes sont marquées `optional: true`, de sorte que le pod Toolbox continue de fonctionner normalement lorsque la base de données de métadonnées du registre n'est pas configurée.

Consultez la [configuration du Toolbox](../charts/gitlab/toolbox/_index.md#registry-metadata-database-credentials) pour les instructions d'installation.

### Restauration {#restore}

L'utilitaire de sauvegarde, lorsqu'il reçoit l'argument `--restore`, tente de restaurer depuis une sauvegarde existante vers l'instance en cours d'exécution. Cette sauvegarde peut provenir d'une installation via un package Linux ou d'une installation via un chart Helm CNG, à condition que l'instance sauvegardée et l'instance en cours d'exécution utilisent la même version de GitLab. La restauration attend un fichier dans le bucket de sauvegarde en utilisant `-t <backup-name>` ou une URL distante en utilisant `-f <url>`.

Lorsqu'un paramètre `-t` est fourni, il recherche dans le bucket de sauvegarde dans le stockage d'objets une archive tar de sauvegarde portant ce nom. Lorsqu'un paramètre `-f` est fourni, il suppose que l'URL donnée est un URI valide d'une archive tar de sauvegarde dans un emplacement accessible depuis le conteneur.

Après avoir récupéré l'archive tar de sauvegarde, la séquence d'exécution est la suivante :

1. Pour les dépôts et la base de données, exécuter la [tâche Rake de sauvegarde GitLab](https://gitlab.com/gitlab-org/gitlab-foss/-/blob/master/lib/tasks/gitlab/backup.rake)
1. Pour chacun des backends de stockage d'objets :
   - archiver les données existantes dans le bucket de stockage d'objets correspondant en le nommant `<backup-name>.tar`
   - le téléverser dans le bucket `tmp` du stockage d'objets
   - nettoyer le bucket correspondant
   - restaurer le contenu de la sauvegarde dans le bucket correspondant

> [!note]
> Si la restauration échoue, l'utilisateur devra revenir à une sauvegarde précédente en utilisant les données du répertoire `tmp` du bucket de sauvegarde, ce qui est un processus manuel.
