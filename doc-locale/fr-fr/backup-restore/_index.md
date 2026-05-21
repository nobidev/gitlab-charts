---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sauvegarder et restaurer une instance GitLab
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le chart Helm GitLab fournit un pod utilitaire issu du sous-chart Toolbox qui sert d'interface pour la sauvegarde et la restauration des instances GitLab. Il est équipé d'un exécutable `backup-utility` qui interagit avec les autres pods nécessaires à cette tâche. Les détails techniques sur le fonctionnement de l'utilitaire se trouvent dans la [documentation sur l'architecture](../architecture/backup-restore.md).

## Prérequis {#prerequisites}

- Les procédures de sauvegarde et de restauration décrites ici n'ont été testées qu'avec des API compatibles S3. La prise en charge d'autres services de stockage d'objets, comme Google Cloud Storage, sera testée dans les prochaines révisions.
- Lors de la restauration, l'archive tarball de sauvegarde doit être extraite sur le disque. Cela signifie que le pod Toolbox doit disposer d'un disque de [taille nécessaire disponible](../charts/gitlab/toolbox/_index.md#restore-considerations).
- Ce chart repose sur l'utilisation du [stockage d'objets](#object-storage) pour les objets `artifacts`, `uploads`, `packages`, `registry` et `lfs`, et ne les migre pas automatiquement lors de la restauration. Si vous restaurez une sauvegarde effectuée depuis une autre instance, vous devez migrer votre instance existante vers le stockage d'objets avant d'effectuer la sauvegarde. Consultez le [ticket 646](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/646).

## Procédures de sauvegarde et de restauration {#backup-and-restoring-procedures}

- [Sauvegarder une installation GitLab](backup.md)
- [Restaurer une installation GitLab](restore.md)

## Stockage d'objets {#object-storage}

Nous fournissons une instance MinIO prête à l'emploi lors de l'utilisation de ces charts, sauf si un [stockage d'objets externe](../advanced/external-object-storage/_index.md) est spécifié. Le Toolbox se connecte par défaut au MinIO inclus, sauf si des paramètres spécifiques sont fournis. Le Toolbox peut également être configuré pour effectuer des sauvegardes vers Amazon S3 ou Google Cloud Storage (GCS).

### Sauvegardes vers S3 {#backups-to-s3}

Le Toolbox utilise `s3cmd` par défaut pour se connecter au stockage d'objets, sauf si vous [spécifiez un autre outil s3 à utiliser](backup.md#specify-s3-tool-to-use). Pour configurer la connectivité vers un stockage d'objets externe, `gitlab.toolbox.backups.objectStorage.config.secret` doit être spécifié et pointe vers un secret Kubernetes contenant un fichier `.s3cfg`. `gitlab.toolbox.backups.objectStorage.config.key` doit être spécifié s'il est différent de la valeur par défaut `config`. Cela pointe vers la clé contenant le contenu d'un fichier [`.s3cfg`](https://s3tools.org/kb/item14.htm).

Il devrait ressembler à ceci :

```shell
helm install gitlab gitlab/gitlab \
  --set gitlab.toolbox.backups.objectStorage.config.secret=my-s3cfg \
  --set gitlab.toolbox.backups.objectStorage.config.key=config .
```

De plus, deux emplacements de compartiments doivent être configurés : l'un pour stocker les sauvegardes et l'autre, un compartiment temporaire, utilisé lors de la restauration d'une sauvegarde.

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
```

### Sauvegardes vers Google Cloud Storage (GCS) {#backups-to-google-cloud-storage-gcs}

Pour effectuer des sauvegardes vers GCS, vous devez d'abord définir `gitlab.toolbox.backups.objectStorage.backend` sur `gcs`. Cela garantit que le Toolbox utilise l'interface CLI `gsutil` lors du stockage et de la récupération des objets.

De plus, deux emplacements de compartiments doivent être configurés : l'un pour stocker les sauvegardes et l'autre, un compartiment temporaire, utilisé lors de la restauration d'une sauvegarde.

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
```

L'utilitaire de sauvegarde a besoin d'accéder à ces compartiments. Il existe deux façons d'accorder l'accès :

- Spécification des identifiants dans un secret Kubernetes.
- Configuration de la [Fédération d'identités de charge de travail pour GKE](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity).

#### Identifiants GCS {#gcs-credentials}

Tout d'abord, définissez `gitlab.toolbox.backups.objectStorage.config.gcpProject` sur l'ID de projet du projet GCP qui contient vos compartiments de stockage.

Vous devez créer un secret Kubernetes avec le contenu d'une clé JSON de compte de service active, où le compte de service dispose du rôle `storage.admin` pour les compartiments que vous utiliserez pour la sauvegarde. Voici un exemple d'utilisation de `gcloud` et `kubectl` pour créer le secret.

```shell
export PROJECT_ID=$(gcloud config get-value project)
gcloud iam service-accounts create gitlab-gcs --display-name "Gitlab Cloud Storage"
gcloud projects add-iam-policy-binding --role roles/storage.admin ${PROJECT_ID} --member=serviceAccount:gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com
gcloud iam service-accounts keys create --iam-account gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com storage.config
kubectl create secret generic storage-config --from-file=config=storage.config
```

Configurez votre chart Helm comme suit pour utiliser la clé de compte de service afin de vous authentifier auprès de GCS pour les sauvegardes :

```shell
helm install gitlab gitlab/gitlab \
  --set gitlab.toolbox.backups.objectStorage.config.secret=storage-config \
  --set gitlab.toolbox.backups.objectStorage.config.key=config \
  --set gitlab.toolbox.backups.objectStorage.config.gcpProject=my-gcp-project-id \
  --set gitlab.toolbox.backups.objectStorage.backend=gcs
```

#### Configuration de la Fédération d'identités de charge de travail pour GKE {#configuring-workload-identity-federation-for-gke}

Consultez la [documentation sur la Fédération d'identités de charge de travail pour GKE avec le chart GitLab](../advanced/external-object-storage/gke-workload-identity.md).

Lors de la création d'une stratégie d'autorisation IAM référençant le ServiceAccount Kubernetes, accordez le rôle `roles/storage.objectAdmin`.

Pour les sauvegardes, assurez-vous que les identifiants d'application par défaut de Google sont utilisés en vérifiant que `gitlab.toolbox.backups.objectStorage.config.secret`, `gitlab.toolbox.backups.objectStorage.config.key` et `gitlab.toolbox.backups.objectStorage.config.gcpProject` ne sont PAS définis.

### Sauvegardes vers le stockage Blob Azure {#backups-to-azure-blob-storage}

Le stockage Blob Azure peut être utilisé pour stocker les sauvegardes en définissant `gitlab.toolbox.backups.objectStorage.backend` sur `azure`. Cela permet au Toolbox d'utiliser la copie incluse de `azcopy` pour transmettre et récupérer les fichiers de sauvegarde vers le stockage Blob Azure.

Pour utiliser le stockage Blob Azure, vous devez créer un compte de stockage dans un groupe de ressources existant. Créez un secret de configuration avec le nom, la clé d'accès et l'hôte blob de votre compte de stockage.

Créez un fichier de configuration contenant les paramètres :

```yaml
# azure-backup-conf.yaml
azure_storage_account_name: <storage account>
azure_storage_access_key: <access key value>
azure_storage_domain: blob.core.windows.net # optional
```

La commande `kubectl` suivante peut être utilisée pour créer le secret Kubernetes :

```shell
kubectl create secret generic backup-azure-creds \
  --from-file=config=azure-backup-conf.yaml
```

Une fois le secret créé, le chart Helm GitLab peut être configuré en ajoutant les paramètres de sauvegarde à vos valeurs déployées ou en fournissant les paramètres sur la ligne de commande Helm. Par exemple :

```shell
helm install gitlab gitlab/gitlab \
  --set gitlab.toolbox.backups.objectStorage.config.secret=backup-azure-creds \
  --set gitlab.toolbox.backups.objectStorage.config.key=config \
  --set gitlab.toolbox.backups.objectStorage.backend=azure
```

La clé d'accès du secret est utilisée pour générer et actualiser des jetons de signature d'accès partagé (SAS) à durée de vie plus courte afin d'accéder au compte de stockage.

De plus, deux compartiments/conteneurs doivent être créés au préalable : l'un pour stocker les sauvegardes et l'autre, un compartiment temporaire, utilisé lors de la restauration d'une sauvegarde. Ajoutez les noms des compartiments à vos valeurs ou paramètres. Par exemple :

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
```

## Base de données de métadonnées du registre {#registry-metadata-database}

Si vous avez activé la [base de données de métadonnées du registre de conteneurs](../charts/registry/metadata_database.md), vous pouvez configurer le Toolbox pour accéder à la base de données du registre lors des opérations de sauvegarde et de restauration. Cela nécessite de définir les identifiants de la base de données du registre dans les valeurs du chart Toolbox. Consultez la section [identifiants de la base de données de métadonnées du registre](../charts/gitlab/toolbox/_index.md#registry-metadata-database-credentials) dans la documentation du chart Toolbox pour les détails de configuration.

## Dépannage {#troubleshooting}

### Problèmes d'éviction de pod {#pod-eviction-issues}

Comme les sauvegardes sont assemblées localement en dehors de la cible de stockage d'objets, un espace disque temporaire est nécessaire. L'espace requis peut dépasser la taille de l'archive de sauvegarde réelle. La configuration par défaut utilise le système de fichiers du pod Toolbox pour stocker les données temporaires. Si vous constatez qu'un pod est évincé en raison de ressources insuffisantes, vous devez associer un volume persistant au pod pour stocker les données temporaires. Sur GKE, ajoutez les paramètres suivants à votre commande Helm :

```shell
--set gitlab.toolbox.persistence.enabled=true
```

Si vos sauvegardes sont exécutées dans le cadre du cron job de sauvegarde inclus, vous devrez également activer la persistance pour le cron job :

```shell
--set gitlab.toolbox.backups.cron.persistence.enabled=true
```

Pour d'autres fournisseurs, vous devrez peut-être créer un volume persistant. Consultez notre [documentation sur le stockage](../installation/storage.md) pour des exemples sur la façon de procéder.

### Erreurs « Bucket not found » {#bucket-not-found-errors}

Si vous voyez des erreurs `Bucket not found` lors des sauvegardes, vérifiez que les identifiants sont configurés pour votre compartiment.

La commande dépend du fournisseur de services cloud :

- Pour AWS S3, les identifiants sont stockés sur le pod toolbox dans `~/.s3cfg`. Exécutez :

  ```shell
  s3cmd ls
  ```

- Pour GCP GCS, exécutez :

  ```shell
  gsutil ls
  ```

Vous devriez voir une liste des compartiments disponibles.

### Erreurs  « AccessDeniedException : 403 » dans GCP {#accessdeniedexception-403-errors-in-gcp}

Une erreur comme `[Error] AccessDeniedException: 403 <GCP Account> does not have storage.objects.list access to the Google Cloud Storage bucket.` se produit généralement lors d'une sauvegarde ou d'une restauration d'une instance GitLab, en raison d'autorisations manquantes.

Les opérations de sauvegarde et de restauration utilisent tous les compartiments de l'environnement. Vérifiez donc que tous les compartiments de votre environnement ont été créés et que le compte GCP peut accéder (lister, lire et écrire) à tous les compartiments :

1. Trouvez votre pod toolbox :

   ```shell
   kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
   ```

1. Récupérez tous les compartiments dans l'environnement du pod. Remplacez `<toolbox-pod-name>` par le nom réel de votre pod toolbox, mais laissez `"BUCKET_NAME"` tel quel :

   ```shell
   kubectl describe pod <toolbox-pod-name> | grep "BUCKET_NAME"
   ```

1. Vérifiez que vous avez accès à chaque compartiment de l'environnement :

   ```shell
   # List
   gsutil ls gs://<bucket-to-validate>/

   # Read
   gsutil cp gs://<bucket-to-validate>/<object-to-get> <save-to-location>

   # Write
   gsutil cp -n <local-file> gs://<bucket-to-validate>/
   ```

### Erreur « ERROR: `/home/git/.s3cfg`: None » lors de l'exécution de `backup-utility` avec `--backend s3` {#error-homegits3cfg-none-error-when-running-backup-utility-with---backend-s3}

Cette erreur se produit lorsqu'un secret Kubernetes contenant un fichier `.s3cfg` n'a pas été spécifié via la valeur `gitlab.toolbox.backups.objectStorage.config.secret`.

Pour résoudre ce problème, suivez les instructions dans [sauvegardes vers S3](_index.md#backups-to-s3).

### Erreurs « PermissionError: File not writable » avec S3 {#permissionerror-file-not-writable-errors-using-s3}

Une erreur comme `[Error] WARNING: <file> not writable: Operation not permitted` se produit si l'utilisateur toolbox ne dispose pas des autorisations pour écrire des fichiers correspondant aux autorisations stockées des éléments du compartiment.

Pour éviter cela, configurez `s3cmd` pour ne pas conserver le propriétaire, le mode et les horodatages du fichier en ajoutant l'indicateur suivant à votre fichier `.s3cfg` référencé via `gitlab.toolbox.backups.objectStorage.config.secret`.

```toml
preserve_attrs = False
```

### Dépôts ignorés lors de la restauration {#repositories-skipped-on-restore}

À partir de GitLab 16.6/Chart 7.6, les dépôts peuvent être ignorés lors de la restauration si l'archive de sauvegarde a été renommée. Pour éviter cela, ne renommez pas les archives de sauvegarde et renommez les sauvegardes avec leurs noms d'origine (`{backup_id}_gitlab_backup.tar`).

L'ID de sauvegarde d'origine peut être extrait de la structure du répertoire de sauvegarde du dépôt : `repositories/@hashed/*/*/*/{backup_id}/LATEST`

### Erreur : `cannot drop view pg_stat_statements because extension pg_stat_statements requires it` {#error-cannot-drop-view-pg_stat_statements-because-extension-pg_stat_statements-requires-it}

Vous pouvez rencontrer cette erreur lors de la restauration d'une sauvegarde sur votre instance de chart Helm. Utilisez les étapes suivantes comme solution de contournement :

1. Dans votre pod `toolbox`, ouvrez la console DB :

   ```shell
   /srv/gitlab/bin/rails dbconsole -p
   ```

1. Supprimez l'extension :

   ```shell
   DROP EXTENSION pg_stat_statements;
   ```

1. Effectuez le processus de restauration.
1. Une fois la restauration terminée, recréez l'extension dans la console DB :

   ```shell
   CREATE EXTENSION pg_stat_statements;
   ```

Si vous rencontrez le même problème avec l'extension `pg_buffercache`, suivez les mêmes étapes ci-dessus pour la supprimer et la recréer.

Vous trouverez plus de détails sur cette erreur dans le ticket [\#2469](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2469).

### Échec de la sauvegarde Toolbox lors du téléversement {#toolbox-backup-failing-on-upload}

Une sauvegarde peut échouer lors d'une tentative de téléversement vers le stockage d'objets avec une erreur comme :

```plaintext
An error occurred (XAmzContentSHA256Mismatch) when calling the UploadPart operation: The Content-SHA256 you specified did not match what we received
```

Cela peut être causé par une incompatibilité de l'outil `awscli` et de votre service de stockage d'objets. Ce problème a été signalé lors de l'utilisation de Dell ECS S3 Storage.

Pour éviter ce problème, vous pouvez [désactiver la protection de l'intégrité des données](backup.md#data-integrity-protection-with-awscli).

### Erreur : paramètre de configuration non reconnu « transaction_timeout » {#error-unrecognized-configuration-parameter-transaction_timeout}

Le chart GitLab déploie un toolbox pour des tâches telles que la sauvegarde et la restauration, qui est actuellement livré avec les bibliothèques clientes PostgreSQL 17.

Les bibliothèques clientes sont rétrocompatibles. Ainsi, si vous utilisez PostgreSQL 16, les sauvegardes et restaurations fonctionneront toujours, mais vous pourriez voir cette erreur :

```plaintext
ERROR:  unrecognized configuration parameter "transaction_timeout"
```

Cela se produit car pg_dump est rétrocompatible, mais ne garantit pas que les restaurations fonctionneront de manière transparente entre différentes versions de serveur.

Pour plus de détails, consultez la [documentation de `pg_dump`](https://www.postgresql.org/docs/current/app-pgdump.html).

L'outil de sauvegarde vous demandera si vous souhaitez ignorer cette erreur, ce qui est sans danger dans ce cas.
