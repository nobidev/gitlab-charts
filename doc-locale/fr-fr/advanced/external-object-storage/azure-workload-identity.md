---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Identité de charge de travail Azure avec le chart GitLab
---

La configuration par défaut pour le stockage d'objets externe dans les charts utilise des clés secrètes. [Azure Workload Identity](https://azure.github.io/azure-workload-identity/docs/) permet d'accorder l'accès au stockage d'objets au cluster Kubernetes en utilisant des jetons de courte durée. Consultez la [documentation Microsoft sur le déploiement et la configuration de l'identité de charge de travail sur un cluster Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster).

## Prérequis {#requirements}

Pour utiliser l'identité de charge de travail avec le stockage d'objets, vous avez besoin de :

1. Un cluster AKS avec un émetteur OpenID Connect (OIDC) activé.
1. Une identité managée Azure avec le rôle `Storage Blob Data Contributor` qui lui est attribué.
1. Un compte de service Kubernetes associé à l'identité managée avec l'annotation `azure.workload.identity/client-id: <CLIENT ID>`.

Pour activer l'identité de charge de travail, chaque pod a besoin du label `azure.workload.identity/use: "true"`. Notez qu'il s'agit d'un **label** de pod, et non d'une annotation.

## Configuration du chart {#chart-configuration}

### Registry {#registry}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/container-registry/-/issues/1431) dans GitLab 17.9 en tant que fonctionnalité bêta.

{{< /history >}}

La prise en charge de l'identité de charge de travail pour le registry est en bêta. L'identité de charge de travail peut être activée en définissant les labels de pod :

```plaintext
--set registry.podLabels."azure\.workload\.identity/use"=true
```

Lors de la création du secret [`registry-storage.yaml`](../../charts/registry/_index.md#storage), vous devez :

1. Utiliser les paramètres de stockage `azure_v2`.
1. Définir `credentialstype` sur `default_credentials`.

Par exemple :

```yaml
azure_v2:
  accountname: accountname
  container: containername
  credentialstype: default_credentials
  realm: core.windows.net
```

Le pilote de stockage `azure_v2` prend en charge l'identité de charge de travail, mais le pilote `azure` ne le prend pas en charge. Si vous utilisez actuellement le pilote `azure` et souhaitez utiliser l'identité de charge de travail, migrez vers le pilote `azure_v2`. Consultez la [documentation `azure_v2`](https://gitlab.com/gitlab-org/container-registry/-/blob/3ebb5bffd3f6cfbf4479b1b8a4079d842a1c8025/docs/storage-drivers/azure_v2.md) pour plus de détails.

### LFS, artefacts, téléchargements, paquets {#lfs-artifacts-uploads-packages}

Pour LFS, les artefacts, les téléchargements et les paquets, un rôle IAM peut être spécifié via la clé d'annotations dans la configuration `webservice`, `sidekiq` et `toolbox` :

```shell
--set gitlab.sidekiq.podLabels."azure\.workload\.identity/use"="true"
--set gitlab.webservice.podLabels."azure\.workload\.identity/use"="true"
--set gitlab.toolbox.podLabels."azure\.workload\.identity/use"="true"
```

Pour le secret [`object-storage.yaml`](../../charts/globals.md#connection), omettez `azure_storage_access_key` :

```yaml
provider: AzureRM
azure_storage_account_name: YOUR_AZURE_STORAGE_ACCOUNT_NAME
azure_storage_domain: blob.core.windows.net
```

### Sauvegardes {#backups}

La configuration Toolbox permet de définir des labels de pod :

```shell
--set gitlab.toolbox.podLabels."azure\.workload\.identity/use"="true"
```

Pour le fichier [`azure-backup-conf.yaml`](../../backup-restore/_index.md) stocké dans le secret `gitlab.toolbox.backups.objectStorage.config.secret`, omettez `azure_storage_access_key` :

```yaml
# azure-backup-conf.yaml
azure_storage_account_name: <storage account>
azure_storage_domain: blob.core.windows.net # optional
```

## Dépannage {#troubleshooting}

Vous pouvez tester si l'identité de charge de travail Azure est correctement configurée et que GitLab accède au stockage Azure Blob en vous connectant au pod `toolbox` (remplacez `<namespace>` par l'espace de nommage où se trouve GitLab) :

```shell
kubectl exec -ti $(kubectl get pod -n <namespace> -lapp=toolbox -o jsonpath='{.items[0].metadata.name}') -n <namespace> -- bash
```

Vérifiez d'abord si les variables d'environnement requises sont présentes :

- `AZURE_TENANT_ID`
- `AZURE_FEDERATED_TOKEN_FILE`
- `AZURE_CLIENT_ID`

Par exemple, vous devriez voir quelque chose comme ceci :

```shell
$ env | grep AZURE
AZURE_TENANT_ID=abcdefghi-c2c5-43d6-b426-1d8c9e8e7ad1
AZURE_FEDERATED_TOKEN_FILE=/var/run/secrets/azure/tokens/azure-identity-token
AZURE_AUTHORITY_HOST=https://login.microsoftonline.com/
AZURE_CLIENT_ID=123456789-abcd-12ab-89ca-cb379118f978
```

Ensuite, utilisez `azcopy` pour lister les fichiers dans le conteneur de blobs :

```shell
export AZCOPY_AUTO_LOGIN_TYPE=workload
azcopy --log-level debug list https://<YOUR STORAGE ACCOUNT NAME>.blob.core.windows.net/<YOUR AZURE BLOB CONTAINER NAME>
```

Si l'authentification réussit, vous devriez voir les messages suivants avec le contenu du conteneur de blobs :

```plaintext
INFO: Login with Workload Identity succeeded
INFO: Authenticating to source using Azure AD
```

Si vous voyez une erreur 401 ou 403, vérifiez vos paramètres d'identité managée. Voici quelques erreurs courantes :

1. Vérifiez l'orthographe du compte de stockage Azure et des noms de conteneurs de blobs.
1. Avec `kubectl describe pod <pod>`, vérifiez que le pod possède le label de pod compte de service Kubernetes correct et `azure.workload.identity/use: "true"`.
1. Pour l'identité managée, assurez-vous que les paramètres des informations d'identification fédérées disposent de l'URL d'émetteur, de l'espace de nommage et du compte de service Kubernetes associé corrects. Vous pouvez vérifier cela dans le portail Azure ou en utilisant l'[interface de ligne de commande `az`](https://learn.microsoft.com/en-us/cli/azure/identity).
1. Vérifiez que l'identité managée dispose du `Storage Blob Data Contributor` pour le conteneur de stockage de blobs.
