---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Configurer le chart GitLab avec un stockage d'objets externe"
---

Configurez le chart Helm GitLab avec un stockage d'objets externe, requis pour les déploiements en production.

> [!note] À partir de GitLab 19.0, le chart Helm GitLab n'intégrera plus MinIO. Pour plus d'informations, consultez l'[annonce de dépréciation](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart) et [migrez](../../installation/migration/bundled_chart_migration.md) vers une alternative externe.

GitLab s'appuie sur le stockage d'objets pour les données persistantes hautement disponibles dans Kubernetes. GitLab prend en charge deux types de méthodes d'authentification pour les principaux fournisseurs de stockage d'objets cloud : les identifiants statiques et les identifiants temporaires via des services spécifiques au cloud.

## Identifiants statiques {#static-credentials}

Ces identifiants sont des clés d'accès et des secrets à longue durée de vie pour tous les fournisseurs :

- AWS S3 : ID de clé d'accès + clé d'accès secrète
- Google Cloud Storage : Fichier de clé JSON de compte de service
- Azure Blob Storage : Nom du compte de stockage + clé d'accès, ou ID client + ID de locataire + secret client

## Identifiants temporaires via Cloud IAM {#temporary-credentials-through-cloud-iam}

GitLab peut récupérer des mécanismes d'identité de charge de travail spécifiques au fournisseur pour des identifiants dynamiques à courte durée de vie :

- AWS S3 : [IAM Roles for Service Accounts (IRSA)](aws-iam-roles.md)
- Google Cloud Storage : [Workload Identity Federation](gke-workload-identity.md)
- Azure Blob Storage : [Workload Identity for Azure Kubernetes Service](azure-workload-identity.md)

Ces mécanismes d'identifiants temporaires améliorent la sécurité en :

- Éliminant les identifiants statiques à longue durée de vie.
- Fournissant une rotation automatisée des identifiants.
- Permettant un contrôle d'accès granulaire.
- Prenant en charge la journalisation d'audit de l'utilisation des identifiants.
- S'intégrant aux politiques IAM du fournisseur cloud.

## Désactiver MinIO {#disable-minio}

> [!warning] À partir de GitLab 19.0, le chart Helm GitLab n'intégrera plus MinIO. Pour plus d'informations, consultez l'[annonce de dépréciation](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart) et [migrez](../../installation/migration/bundled_chart_migration.md) vers une alternative externe.

Par défaut, une solution de stockage compatible S3 nommée `minio` est déployée avec le chart. Pour les déploiements de qualité production, nous recommandons d'utiliser une solution de stockage d'objets hébergée telle que Google Cloud Storage ou AWS S3.

Pour désactiver MinIO, définissez cette option puis suivez la documentation correspondante ci-dessous :

```shell
--set global.minio.enabled=false
```

Un [exemple de la configuration complète](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/values-external-objectstorage.yaml) est disponible dans les [exemples](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples).

## Azure Blob Storage {#azure-blob-storage}

La prise en charge directe du stockage Azure Blob est disponible pour les [pièces jointes téléchargées, les artefacts de job CI, LFS et d'autres types d'objets pris en charge via les paramètres consolidés](https://docs.gitlab.com/administration/object_storage/#storage-specific-configuration). Dans les versions précédentes de GitLab, une [passerelle Azure MinIO](azure-minio-gateway.md) était nécessaire.

> [!note] GitLab [ne prend pas en charge](https://github.com/minio/minio/issues/9978) la passerelle Azure MinIO comme stockage pour le Docker Registry. Veuillez vous référer à l'[exemple Azure correspondant](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.azure.yaml) lors de la [configuration du Docker Registry](#docker-registry-images).

Bien qu'Azure utilise le mot conteneur pour désigner une collection de blobs, GitLab standardise l'utilisation du terme bucket.

Le stockage Azure Blob nécessite l'utilisation des [paramètres de stockage d'objets consolidés](../../charts/globals.md#consolidated-object-storage). Un nom de compte de stockage Azure unique et une clé unique doivent être utilisés pour plusieurs conteneurs Azure Blob. La personnalisation des paramètres `connection` individuels par type d'objet (par exemple, `artifacts`, `uploads`, etc.) n'est pas autorisée.

Pour activer le stockage Azure Blob, consultez [`rails.azurerm.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azurerm.yaml) comme exemple pour définir la `connection` Azure. Vous pouvez charger ceci en tant que secret via :

```shell
kubectl create secret generic gitlab-rails-storage --from-file=connection=rails.azurerm.yml
```

Ensuite, désactivez MinIO et définissez ces paramètres globaux :

```shell
--set global.minio.enabled=false
--set global.appConfig.object_store.enabled=true
--set global.appConfig.object_store.connection.secret=gitlab-rails-storage
```

Assurez-vous de créer des conteneurs Azure pour les [noms par défaut ou définissez les noms de conteneurs dans la configuration des buckets](../../charts/globals.md#specify-buckets).

> [!note] Si vous constatez des échecs de requêtes avec `Requests to the local network are not allowed`, consultez la [section Dépannage](#troubleshooting).

## Images du Docker Registry {#docker-registry-images}

La configuration du stockage d'objets pour le chart `registry` s'effectue via la clé `registry.storage` et la clé `global.registry.bucket`.

```shell
--set registry.storage.secret=registry-storage
--set registry.storage.key=config
--set global.registry.bucket=bucket-name
```

> [!note] Le nom du bucket doit être défini à la fois dans le secret et dans `global.registry.bucket`. Le secret est utilisé par le serveur de registre, et la variable globale est utilisée par les sauvegardes GitLab.

Créez le secret conformément à la [documentation du chart de registre sur le stockage](../../charts/registry/_index.md#storage), puis configurez le chart pour utiliser ce secret.

Des exemples pour les pilotes [S3](https://distribution.github.io/distribution/storage-drivers/s3/) (stockages compatibles S3, mais la passerelle Azure MinIO n'est pas prise en charge, voir [Azure Blob Storage](#azure-blob-storage) ), [Azure](https://distribution.github.io/distribution/storage-drivers/azure/) et [GCS](https://distribution.github.io/distribution/storage-drivers/gcs/) sont disponibles dans [`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage).

- [`registry.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.s3.yaml)
- [`registry.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.gcs.yaml)
- [`registry.azure.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.azure.yaml)

### Configuration du registre {#registry-configuration}

1. Choisissez le service de stockage à utiliser.
1. Copiez le fichier approprié vers `registry-storage.yaml`.
1. Modifiez avec les valeurs correctes pour l'environnement.
1. Suivez la [documentation du chart de registre sur le stockage](../../charts/registry/_index.md#storage) pour créer le secret.
1. Configurez le chart comme indiqué dans la documentation.

## LFS, artefacts, uploads, packages, diffs externes, état Terraform, proxy de dépendances, fichiers sécurisés {#lfs-artifacts-uploads-packages-external-diffs-terraform-state-dependency-proxy-secure-files}

La configuration du stockage d'objets pour LFS, les artefacts, les uploads, les packages, les diffs externes, l'état Terraform, les fichiers sécurisés et le pseudonymiseur s'effectue via les clés suivantes :

- `global.appConfig.lfs`
- `global.appConfig.artifacts`
- `global.appConfig.uploads`
- `global.appConfig.packages`
- `global.appConfig.externalDiffs`
- `global.appConfig.dependencyProxy`
- `global.appConfig.terraformState`
- `global.appConfig.ciSecureFiles`

Notez également que :

- Vous devez créer des buckets pour les [noms par défaut ou les noms personnalisés dans la configuration des buckets](../../charts/globals.md#specify-buckets).
- Un bucket différent est nécessaire pour chacun, sinon l'exécution d'une restauration depuis une sauvegarde ne fonctionne pas correctement.
- Le stockage des diffs de merge request sur un stockage externe n'est pas activé par défaut. Ainsi, pour que les paramètres de stockage d'objets pour `externalDiffs` prennent effet, la clé `global.appConfig.externalDiffs.enabled` doit avoir la valeur `true`.
- La fonctionnalité proxy de dépendances n'est pas activée par défaut. Ainsi, pour que les paramètres de stockage d'objets pour `dependencyProxy` prennent effet, la clé `global.appConfig.dependencyProxy.enabled` doit avoir la valeur `true`.

Voici un exemple des options de configuration :

```shell
--set global.appConfig.lfs.bucket=gitlab-lfs-storage
--set global.appConfig.lfs.connection.secret=object-storage
--set global.appConfig.lfs.connection.key=connection

--set global.appConfig.artifacts.bucket=gitlab-artifacts-storage
--set global.appConfig.artifacts.connection.secret=object-storage
--set global.appConfig.artifacts.connection.key=connection

--set global.appConfig.uploads.bucket=gitlab-uploads-storage
--set global.appConfig.uploads.connection.secret=object-storage
--set global.appConfig.uploads.connection.key=connection

--set global.appConfig.packages.bucket=gitlab-packages-storage
--set global.appConfig.packages.connection.secret=object-storage
--set global.appConfig.packages.connection.key=connection

--set global.appConfig.externalDiffs.bucket=gitlab-externaldiffs-storage
--set global.appConfig.externalDiffs.connection.secret=object-storage
--set global.appConfig.externalDiffs.connection.key=connection

--set global.appConfig.terraformState.bucket=gitlab-terraform-state
--set global.appConfig.terraformState.connection.secret=object-storage
--set global.appConfig.terraformState.connection.key=connection

--set global.appConfig.dependencyProxy.bucket=gitlab-dependencyproxy-storage
--set global.appConfig.dependencyProxy.connection.secret=object-storage
--set global.appConfig.dependencyProxy.connection.key=connection

--set global.appConfig.ciSecureFiles.bucket=gitlab-ci-secure-files
--set global.appConfig.ciSecureFiles.connection.secret=object-storage
--set global.appConfig.ciSecureFiles.connection.key=connection
```

Consultez la [documentation charts/globals sur appConfig](../../charts/globals.md#configure-appconfig-settings) pour tous les détails.

Créez le ou les secrets conformément à la [documentation sur les détails de connexion](../../charts/globals.md#connection), puis configurez le chart pour utiliser les secrets fournis. Notez que le même secret peut être utilisé pour tous.

Des exemples pour les fournisseurs [AWS](https://fog.github.io/storage/#using-amazon-s3-and-fog) (tout compatible S3 comme [Azure utilisant MinIO](azure-minio-gateway.md) ) et [Google](https://fog.github.io/storage/#google-cloud-storage) sont disponibles dans [`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage).

- [`rails.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.s3.yaml)
- [`rails.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.gcs.yaml)
- [`rails.azure.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azure.yaml)
- [`rails.azurerm.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.azurerm.yaml)

### Chiffrement S3 {#s3-encryption}

GitLab prend en charge [Amazon KMS](https://aws.amazon.com/kms/) pour [chiffrer les données stockées dans les buckets S3](https://docs.gitlab.com/administration/object_storage/#encrypted-s3-buckets). Vous pouvez activer cette fonctionnalité de deux manières :

- Dans AWS, [configurez le bucket S3 pour utiliser le chiffrement par défaut](https://docs.aws.amazon.com/AmazonS3/latest/dev/bucket-encryption.html).
- Dans GitLab, activez les [en-têtes de chiffrement côté serveur](../../charts/globals.md#storage_options).

Ces deux options ne sont pas mutuellement exclusives. Vous pouvez définir une politique de chiffrement par défaut, mais aussi activer les en-têtes de chiffrement côté serveur pour remplacer ces paramètres par défaut.

Consultez la [documentation GitLab sur les buckets S3 chiffrés](https://docs.gitlab.com/administration/object_storage/#encrypted-s3-buckets) pour plus de détails.

### Configuration appConfig {#appconfig-configuration}

1. Choisissez le service de stockage à utiliser.
1. Copiez le fichier approprié vers `rails.yaml`.
1. Modifiez avec les valeurs correctes pour l'environnement.
1. Suivez la [documentation sur les détails de connexion](../../charts/globals.md#connection) pour créer le secret.
1. Configurez le chart comme indiqué dans la documentation.

## Sauvegardes {#backups}

Les sauvegardes sont également stockées dans le stockage d'objets et doivent être configurées pour pointer vers l'extérieur plutôt que vers le service MinIO inclus. La procédure de sauvegarde/restauration utilise deux buckets distincts :

- Un bucket pour stocker les sauvegardes (`global.appConfig.backups.bucket`)
- Un bucket temporaire pour préserver les données existantes pendant le processus de restauration (`global.appConfig.backups.tmpBucket`)

Les systèmes de stockage d'objets compatibles AWS S3, Google Cloud Storage et Azure Blob Storage sont des backends pris en charge. Vous pouvez configurer le type de backend en définissant `global.appConfig.backups.objectStorage.backend` sur `s3` pour AWS S3, `gcs` pour Google Cloud Storage, ou `azure` pour Azure Blob Storage. Vous devez également fournir une configuration de connexion via la clé `gitlab.toolbox.backups.objectStorage.config`.

Lors de l'utilisation de Google Cloud Storage avec un secret, le projet GCP doit être défini avec la valeur `global.appConfig.backups.objectStorage.config.gcpProject`.

Pour le stockage compatible S3 :

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.config.secret=storage-config
--set gitlab.toolbox.backups.objectStorage.config.key=config
```

Pour Google Cloud Storage (GCS) avec un secret :

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.backend=gcs
--set gitlab.toolbox.backups.objectStorage.config.gcpProject=my-gcp-project-id
--set gitlab.toolbox.backups.objectStorage.config.secret=storage-config
--set gitlab.toolbox.backups.objectStorage.config.key=config
```

Pour Google Cloud Storage (GCS) avec [Workload Identity Federation pour GKE](gke-workload-identity.md), seuls le backend et les buckets doivent être définis. Assurez-vous que `gitlab.toolbox.backups.objectStorage.config.secret` et `gitlab.toolbox.backups.objectStorage.config.key` ne sont pas définis, afin que le cluster utilise les [identifiants par défaut de l'application Google](https://cloud.google.com/docs/authentication/application-default-credentials) :

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.backend=gcs
```

Pour Azure Blob Storage :

```shell
--set global.appConfig.backups.bucket=gitlab-backup-storage
--set global.appConfig.backups.tmpBucket=gitlab-tmp-storage
--set gitlab.toolbox.backups.objectStorage.backend=azure
--set gitlab.toolbox.backups.objectStorage.config.secret=storage-config
--set gitlab.toolbox.backups.objectStorage.config.key=config
```

Consultez la [documentation sur le stockage d'objets pour la sauvegarde/restauration](../../backup-restore/_index.md#object-storage) pour tous les détails.

> [!note] Pour sauvegarder ou restaurer des fichiers depuis d'autres emplacements de stockage d'objets, le fichier de configuration doit être configuré pour s'authentifier en tant qu'utilisateur disposant d'un accès suffisant en lecture/écriture sur tous les buckets GitLab.

### Exemple de stockage des sauvegardes {#backups-storage-example}

1. Créez le fichier `storage.config` :

   - Sur Amazon S3, le contenu doit être au [format de fichier de configuration s3cmd](https://s3tools.org/kb/item14.htm)

     ```ini
     [default]
     access_key = AWS_ACCESS_KEY
     secret_key = AWS_SECRET_KEY
     bucket_location = us-east-1
     multipart_chunk_size_mb = 128 # default is 15 (MB)
     ```

   - Sur Google Cloud Storage, vous pouvez créer le fichier en créant un compte de service avec le rôle `storage.admin` puis en [créant une clé de compte de service](https://cloud.google.com/iam/docs/keys-create-delete#creating_service_account_keys). Voici un exemple d'utilisation de la CLI `gcloud` pour créer le fichier.

     ```shell
     export PROJECT_ID=$(gcloud config get-value project)
     gcloud iam service-accounts create gitlab-gcs --display-name "Gitlab Cloud Storage"
     gcloud projects add-iam-policy-binding --role roles/storage.admin ${PROJECT_ID} --member=serviceAccount:gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com
     gcloud iam service-accounts keys create --iam-account gitlab-gcs@${PROJECT_ID}.iam.gserviceaccount.com storage.config
     ```

   - Sur Azure Storage

     ```ini
     [default]
     # Setup endpoint: hostname of the Web App
     host_base = https://your_minio_setup.azurewebsites.net
     host_bucket = https://your_minio_setup.azurewebsites.net
     # Leave as default
     bucket_location = us-west-1
     use_https = True
     multipart_chunk_size_mb = 128 # default is 15 (MB)

     # Setup access keys
     # Access Key = Azure Storage Account name
     access_key = AZURE_ACCOUNT_NAME
     # Secret Key = Azure Storage Account Key
     secret_key = AZURE_ACCOUNT_KEY

     # Use S3 v4 signature APIs
     signature_v2 = False
     ```

1. Créer le secret

   ```shell
   kubectl create secret generic storage-config --from-file=config=storage.config
   ```

## Google Cloud CDN {#google-cloud-cdn}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/98010) dans GitLab 15.5.

{{< /history >}}

Vous pouvez utiliser [Google Cloud CDN](https://cloud.google.com/cdn) pour mettre en cache et récupérer des données depuis le bucket d'artefacts. Cela peut contribuer à améliorer les performances et à réduire les coûts de sortie réseau.

La configuration de Cloud CDN s'effectue via les clés suivantes :

- `global.appConfig.artifacts.cdn.secret`
- `global.appConfig.artifacts.cdn.key` (la valeur par défaut est `cdn`)

Pour utiliser Cloud CDN :

1. Configurez [Cloud CDN pour utiliser le bucket d'artefacts comme backend](https://cloud.google.com/cdn/docs/setting-up-cdn-with-bucket).
1. Créez une [clé pour les URL signées](https://cloud.google.com/cdn/docs/using-signed-urls).
1. Accordez au [compte de service Cloud CDN l'autorisation de lire depuis le bucket](https://cloud.google.com/cdn/docs/using-signed-urls#configuring_permissions).
1. Préparez un fichier YAML avec les paramètres en utilisant l'exemple dans [`rails.googlecdn.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/cdn/rails.googlecdn.yaml). Vous devrez renseigner les informations suivantes :
   - `url` : URL de base de l'hôte CDN de l'étape 1
   - `key_name` : Nom de la clé de l'étape 2
   - `key` : Le secret réel de l'étape 2
1. Chargez ce fichier YAML dans un secret Kubernetes sous la clé `cdn`. Par exemple, pour créer un secret `gitlab-rails-cdn` :

   ```shell
   kubectl create secret generic gitlab-rails-cdn --from-file=cdn=rails.googlecdn.yml
   ```

1. Définissez `global.appConfig.artifacts.cdn.secret` sur `gitlab-rails-cdn`. Si vous définissez cela via un paramètre `helm`, utilisez :

    ```shell
    --set global.appConfig.artifacts.cdn.secret=gitlab-rails-cdn
    ```

## Dépannage {#troubleshooting}

### Azure Blob : `URL [FILTERED] is blocked: Requests to the local network are not allowed` {#azure-blob-url-filtered-is-blocked-requests-to-the-local-network-are-not-allowed}

Cela se produit lorsque le nom d'hôte Azure Blob est résolu en une [adresse IP RFC1918 (locale / privée)](https://learn.microsoft.com/en-us/azure/storage/common/storage-private-endpoints#dns-changes-for-private-endpoints). Pour contourner ce problème, autorisez les [requêtes sortantes](https://docs.gitlab.com/security/webhooks/#allowlist-for-local-requests) pour votre nom d'hôte Azure Blob (`yourinstance.blob.core.windows.net`).
