---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Passerelle Azure MinIO lors de l'utilisation du chart GitLab"
---

[MinIO](https://min.io/) est un serveur de stockage d'objets qui expose des API compatibles S3 et dispose d'une fonctionnalité de passerelle permettant de router les requêtes vers Azure Blob Storage. Pour configurer notre passerelle, nous utiliserons Azure Web App on Linux.

Pour commencer, assurez-vous d'avoir installé Azure CLI et d'être connecté (`az login`). Procédez à la création d'un [groupe de ressources](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/overview#resource-groups), si vous n'en avez pas déjà un :

```shell
az group create --name "gitlab-azure-minio" --location "WestUS"
```

## Compte de stockage {#storage-account}

Créez un compte de stockage dans votre groupe de ressources. Le nom du compte de stockage doit être globalement unique :

```shell
az storage account create \
    --name "gitlab-azure-minio-storage" \
    --kind BlobStorage \
    --sku Standard_LRS \
    --access-tier Cool \
    --resource-group "gitlab-azure-minio" \
    --location "WestUS"
```

Récupérez la clé de compte pour le compte de stockage :

```shell
az storage account show-connection-string \
    --name "gitlab-azure-minio-storage" \
    --resource-group "gitlab-azure-minio"
```

La sortie doit être au format suivant :

```json
{
    "connectionString": "DefaultEndpointsProtocol=https;EndpointSuffix=core.windows.net;AccountName=gitlab-azure-minio-storage;AccountKey=h0tSyeTebs+..."
}
```

## Déployer MinIO sur Web App on Linux {#deploy-minio-to-web-app-on-linux}

Tout d'abord, nous devons créer un plan App Service dans le même groupe de ressources.

```shell
az appservice plan create \
    --name "gitlab-azure-minio-app-plan" \
    --is-linux \
    --sku B1 \
    --resource-group "gitlab-azure-minio" \
    --location "WestUS"
```

Créez une application Web configurée avec le conteneur Docker [`minio/minio`](https://hub.docker.com/r/minio/minio). Le nom que vous spécifiez sera utilisé dans l'URL de l'application Web :

```shell
az webapp create \
    --name "gitlab-minio-app" \
    --deployment-container-image-name "minio/minio" \
    --plan "gitlab-azure-minio-app-plan" \
    --resource-group "gitlab-azure-minio"
```

L'application Web devrait maintenant être accessible à l'adresse `https://gitlab-minio-app.azurewebsites.net`.

Enfin, nous devons configurer la commande de démarrage et créer des variables d'environnement qui stockeront le nom et la clé de notre compte de stockage pour être utilisés par l'application Web, `MINIO_ACCESS_KEY` et `MINIO_SECRET_KEY`.

```shell
az webapp config appsettings set \
    --settings "MINIO_ACCESS_KEY=gitlab-azure-minio-storage" "MINIO_SECRET_KEY=h0tSyeTebs+..." "PORT=9000" \
    --name "gitlab-minio-app" \
    --resource-group "gitlab-azure-minio"

# Startup command
az webapp config set \
    --startup-file "gateway azure" \
    --name "gitlab-minio-app" \
    --resource-group "gitlab-azure-minio"
```

## Conclusion {#conclusion}

Vous pouvez utiliser cette passerelle avec n'importe quel client compatible S3. L'URL de votre application Web sera le `s3 endpoint`, le nom du compte de stockage sera votre `accesskey`, et la clé du compte de stockage sera votre `secretkey`.

## Référence {#reference}

<!-- vale gitlab.Spelling = NO -->

Ce guide a été adapté pour la postérité à partir de [l'article de blog d'Alessandro Segala sur le même sujet.](https://withblue.ink/2017/10/29/how-to-use-s3cmd-and-any-other-amazon-s3-compatible-app-with-azure-blob-storage.html)

<!-- vale gitlab.Spelling = YES -->
