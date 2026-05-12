---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sauvegarder une installation GitLab
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Les sauvegardes GitLab sont effectuées en exécutant la commande `backup-utility` dans le pod Toolbox fourni dans le chart. Les sauvegardes peuvent également être automatisées en activant la fonctionnalité [Sauvegarde basée sur Cron](#cron-based-backup) de ce chart.

Avant d'exécuter la sauvegarde pour la première fois, vous devez vous assurer que le [Toolbox est correctement configuré](../charts/gitlab/toolbox/_index.md#configuration) pour accéder au [stockage d'objets](_index.md#object-storage).

Suivez ces étapes pour sauvegarder une installation basée sur le chart Helm de GitLab.

## Créer la sauvegarde {#create-the-backup}

1. Vérifiez que le pod Toolbox est en cours d'exécution en exécutant la commande suivante

   ```shell
   kubectl get pods -lrelease=<release_name>,app=toolbox
   ```

   Remplacez `<release_name>` par le nom de la release Helm, généralement `gitlab`.

1. Exécuter l'utilitaire de sauvegarde

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility
   ```

1. Accédez au bucket `gitlab-backups` dans le service de stockage d'objets et vérifiez qu'une archive tar a été ajoutée. Elle sera nommée selon le format `<backup_ID>_gitlab_backup.tar`. Lisez ce qu'est l'[ID de sauvegarde](https://docs.gitlab.com/administration/backup_restore/backup_archive_process/#backup-id).
1. Cette archive tar est requise pour la restauration.

## Sauvegarde basée sur Cron {#cron-based-backup}

> [!note] Le CronJob Kubernetes créé par le chart Helm définit l'annotation `cluster-autoscaler.kubernetes.io/safe-to-evict: "false"` sur le jobTemplate. Certains environnements Kubernetes, tels que GKE Autopilot, n'autorisent pas la définition de cette annotation et ne créeront pas de pods de job de sauvegarde. Cette annotation peut être modifiée en définissant le paramètre `gitlab.toolbox.backups.cron.safeToEvict` sur `true`, ce qui permettra la création des jobs, mais au risque qu'ils soient évincés et que la sauvegarde soit corrompue.

Les sauvegardes basées sur Cron peuvent être activées dans ce chart pour s'exécuter à intervalles réguliers tels que définis par le [planning Kubernetes](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs).

Vous devez définir les paramètres suivants :

- `gitlab.toolbox.backups.cron.enabled` : Définir sur true pour activer les sauvegardes basées sur Cron
- `gitlab.toolbox.backups.cron.schedule` : Définir conformément à la documentation du planning Kubernetes
- `gitlab.toolbox.backups.cron.extraArgs` : Définir éventuellement des arguments supplémentaires pour [backup-utility](https://gitlab.com/gitlab-org/build/CNG/blob/master/gitlab-toolbox/scripts/bin/backup-utility) (comme `--skip db` ou `--s3tool awscli`)

## Arguments supplémentaires de l'utilitaire de sauvegarde {#backup-utility-extra-arguments}

L'utilitaire de sauvegarde peut accepter des arguments supplémentaires.

### Ignorer des composants {#skipping-components}

Ignorez des composants en utilisant l'argument `--skip`. Les noms de composants valides sont disponibles dans [Exclure des données spécifiques de la sauvegarde](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#excluding-specific-data-from-the-backup).

Chaque composant doit avoir son propre argument `--skip`. Par exemple :

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --skip db --skip lfs
```

### Nettoyage des sauvegardes uniquement {#cleanup-backups-only}

Exécutez le nettoyage des sauvegardes sans créer de nouvelle sauvegarde.

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --cleanup
```

### Spécifier l'outil S3 à utiliser {#specify-s3-tool-to-use}

La commande `backup-utility` utilise `s3cmd` par défaut pour se connecter au stockage d'objets. Vous pouvez vouloir remplacer cet argument supplémentaire dans les cas où `s3cmd` est moins fiable que d'autres outils S3.

Il existe un [problème connu](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3338) où un job de sauvegarde plante avec `ERROR: S3 error: 404 (NoSuchKey): The specified key does not exist.` lorsque GitLab utilise un bucket S3 comme stockage des artefacts de job CI et que l'outil CLI `s3cmd` par défaut est utilisé. Passer de `s3cmd` à `awscli` permet aux jobs de sauvegarde de s'exécuter correctement. Consultez le [problème 3338](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3338) pour plus de détails.

L'outil CLI S3 à utiliser peut être soit `s3cmd` soit `awscli`.

 ```shell
 kubectl exec <Toolbox pod name> -it -- backup-utility --s3tool awscli
 ```

#### Utiliser MinIO avec awscli {#using-minio-with-awscli}

Pour utiliser MinIO comme stockage d'objets lors de l'utilisation de `awscli`, définissez les paramètres suivants :

```yaml
gitlab:
  toolbox:
    extraEnvFrom:
      AWS_ACCESS_KEY_ID:
        secretKeyRef:
          name: <MINIO-SECRET-NAME>
          key: accesskey
      AWS_SECRET_ACCESS_KEY:
        secretKeyRef:
          name: <MINIO-SECRET-NAME>
          key: secretkey
    extraEnv:
      AWS_DEFAULT_REGION: us-east-1 # MinIO default
    backups:
      cron:
        enabled: true
        schedule: "@daily"
        extraArgs: "--s3tool awscli --aws-s3-endpoint-url <MINIO-INGRESS-URL>"
```

La prise en charge de l'outil CLI S3 `s5cmd` est en cours d'investigation. Consultez le [problème 523](https://gitlab.com/gitlab-org/build/CNG/-/issues/523) pour suivre l'avancement.

#### Protection de l'intégrité des données avec `awscli` {#data-integrity-protection-with-awscli}

Les versions récentes de l'outil `awscli` inclus dans le Toolbox appliquent la protection de l'intégrité des données par défaut. Si votre service de stockage d'objets ne prend pas en charge cette fonctionnalité, cette exigence peut être désactivée avec :

```yaml
extraEnv:
  AWS_REQUEST_CHECKSUM_CALCULATION: WHEN_REQUIRED
```

La configuration peut être soit le `extraEnv` du pod Toolbox, soit le `extraEnv` global.

### Sauvegardes de dépôt côté serveur {#server-side-repository-backups}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/issues/438393) dans GitLab 17.0.

{{< /history >}}

Au lieu de stocker de grandes sauvegardes de dépôt dans l'archive de sauvegarde, les sauvegardes de dépôt peuvent être configurées de sorte que le nœud Gitaly qui héberge chaque dépôt soit responsable de la création de la sauvegarde et de sa diffusion vers le stockage d'objets. Cela permet de réduire les ressources réseau nécessaires à la création et à la restauration d'une sauvegarde.

Consultez [Créer des sauvegardes de dépôt côté serveur](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#create-server-side-repository-backups).

### Autres arguments {#other-arguments}

Pour voir la liste complète des arguments disponibles, exécutez la commande suivante :

```shell
kubectl exec <Toolbox pod name> -it -- backup-utility --help
```

## Sauvegarder les secrets {#back-up-the-secrets}

Vous devez également enregistrer une copie des secrets Rails car ceux-ci ne sont pas inclus dans la sauvegarde pour des raisons de sécurité. Nous vous recommandons de conserver votre sauvegarde complète incluant la base de données séparément de la copie des secrets.

1. Trouver le nom d'objet des secrets Rails

   ```shell
   kubectl get secrets | grep rails-secret
   ```

1. Enregistrer une copie des secrets Rails

   ```shell
   kubectl get secrets <rails-secret-name> -o jsonpath="{.data['secrets\.yml']}" | base64 --decode > gitlab-secrets.yaml
   ```

1. Stockez `gitlab-secrets.yaml` dans un emplacement sécurisé. Vous en avez besoin pour restaurer vos sauvegardes.

## Informations supplémentaires {#additional-information}

- [Introduction à la sauvegarde/restauration du chart GitLab](_index.md)
- [Restaurer une installation GitLab](restore.md)
