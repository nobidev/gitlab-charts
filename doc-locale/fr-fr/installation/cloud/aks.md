---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Préparation des ressources AKS pour le chart GitLab
---

{{< details >}}

- Édition :  version gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Pour une instance GitLab entièrement fonctionnelle, vous avez besoin de quelques ressources avant de déployer le chart GitLab sur [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/fr-fr/azure/aks/what-is-aks).

## Création du cluster AKS {#creating-the-aks-cluster}

Pour faciliter le démarrage, un script est fourni pour automatiser la création du cluster. Il est également possible de créer un cluster manuellement.

Prérequis :

- Installez les [prérequis](../tools.md).
- Installez l'[interface de ligne de commande Azure](https://learn.microsoft.com/fr-fr/cli/azure/install-azure-cli) et utilisez-la pour [vous connecter à Azure](https://learn.microsoft.com/fr-fr/cli/azure/get-started-with-azure-cli#how-to-sign-into-the-azure-cli).
- [Installez `jq`](https://stedolan.github.io/jq/download/).

### Création scriptée du cluster {#scripted-cluster-creation}

Un [script bootstrap](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/aks_bootstrap_script.sh) a été créé pour automatiser une grande partie du processus de configuration pour les utilisateurs sur Azure.

Il accepte un argument `up`, `down` ou `creds`, avec des paramètres facultatifs supplémentaires provenant de variables d'environnement ou d'arguments de ligne de commande :

- Pour créer le cluster :

  ```shell
  ./scripts/aks_bootstrap_script.sh up
  ```

  Cette opération va :

  1. Créer un nouveau groupe de ressources (facultatif).
  1. Créer un nouveau cluster AKS.
  1. Créer une nouvelle adresse IP publique (facultatif).

- Pour nettoyer les ressources AKS créées :

  ```shell
  ./scripts/aks_bootstrap_script.sh down
  ```

  Cette opération va :

  1. Supprimer le groupe de ressources spécifié (facultatif).
  1. Supprimer le cluster AKS.
  1. Supprimer le groupe de ressources créé par le cluster.

  L'argument `down` envoie la commande pour supprimer toutes les ressources et se termine instantanément. La suppression effective peut prendre plusieurs minutes.

- Pour connecter `kubectl` au cluster :

  ```shell
  ./scripts/aks_bootstrap_script.sh creds
  ```

Le tableau ci-dessous décrit toutes les variables disponibles.

| Variable                   | Valeur par défaut      | Portée   | Description |
|----------------------------|--------------------|---------|-------------|
| `-g --resource-group`      | `gitlab-resources` | Tous     | Nom du groupe de ressources à utiliser |
| `-n --cluster-name`        | `gitlab-cluster`   | Tous     | Nom du cluster à utiliser |
| `-r --region`              | `eastus`           | `up`    | Région dans laquelle installer le cluster |
| `-v --cluster-version`     | Dernière version             | `up`    | Version de Kubernetes à utiliser pour créer le cluster |
| `-c --node-count`          | `2`                | `up`    | Nombre de nœuds à utiliser |
| `-s --node-vm-size`        | `Standard_D4s_v3`  | `up`    | Type de nœuds à utiliser |
| `-p --public-ip-name`      | `gitlab-ext-ip`    | `up`    | Nom de l'adresse IP publique à créer |
| `--create-resource-group`  | `false`            | `up`    | Création d'un nouveau groupe de ressources pour contenir toutes les ressources créées |
| `--create-public-ip`       | `false`            | `up`    | Création d'une adresse IP publique à utiliser avec le nouveau cluster |
| `--delete-resource-group`  | `false`            | `down`  | Suppression du groupe de ressources lors de l'utilisation de la commande down |
| `-f --kubectl-config-file` | `~/.kube/config`   | `creds` | Fichier de configuration Kubernetes à mettre à jour – utilisez `-` pour afficher le YAML dans `stdout` à la place |

### Création manuelle du cluster {#manual-cluster-creation}

Un cluster avec 8 vCPU et 30 Go de RAM est recommandé.

Pour les instructions les plus récentes, suivez le [guide pas à pas AKS](https://learn.microsoft.com/fr-fr/azure/aks/learn/quick-kubernetes-deploy-portal) de Microsoft.

## Accès externe à GitLab {#external-access-to-gitlab}

Une adresse IP externe est requise pour que votre cluster soit accessible. Pour les instructions les plus récentes, suivez le guide [Créer une adresse IP statique](https://learn.microsoft.com/fr-fr/azure/aks/static-ip) de Microsoft.

## Prochaines étapes {#next-steps}

Continuez avec l'[installation du chart](../deployment.md) une fois que le cluster est opérationnel et que l'adresse IP statique et l'entrée DNS sont prêtes.
