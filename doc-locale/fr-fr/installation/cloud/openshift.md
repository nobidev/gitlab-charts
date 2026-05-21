---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Préparation des ressources OpenShift pour le chart GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Ce document vous guide dans l'utilisation des scripts d'automatisation de ce projet pour créer un cluster OpenShift dans Google Cloud.

## Préparation {#preparation}

Tout d'abord, vous devez disposer d'un compte Red Hat associé à votre adresse e-mail GitLab. Contactez notre intermédiaire auprès de l'Alliance Red Hat ; il se chargera de vous envoyer un e-mail d'invitation à créer un compte. Une fois votre compte Red Hat activé, vous aurez accès aux licences et abonnements nécessaires pour exécuter OpenShift.

Pour lancer un cluster dans Google Cloud, une zone Cloud DNS publique doit être connectée à un domaine enregistré et configurée dans Google Cloud DNS. Si aucun domaine n'est encore disponible, suivez les étapes [de ce guide](https://github.com/openshift/installer/blob/master/docs/user/gcp/dns.md) pour en créer un.

### Obtenir les outils CLI et le Pull Secret {#get-the-cli-tools-and-pull-secret}

Deux outils CLI sont nécessaires pour créer un cluster OpenShift (`openshift-install`) puis interagir avec le cluster (`oc`).

Un pull secret est nécessaire pour récupérer des images depuis le registre Docker privé de Red Hat. Chaque développeur dispose d'un pull secret différent associé à son compte Red Hat.

Pour obtenir les outils CLI et votre pull secret, accédez au [cloud de Red Hat](https://cloud.redhat.com/openshift/install/gcp/installer-provisioned) et connectez-vous avec votre compte Red Hat. Sur cette page, téléchargez la dernière version du programme d'installation et des outils de ligne de commande à l'aide des liens fournis. Extrayez ces packages et placez `openshift-install` et `oc` dans votre `PATH`.

Copiez le pull secret dans votre presse-papiers et écrivez le contenu dans un fichier `pull_secret` à la racine de ce dépôt. Ce fichier est ignoré par Git.

### Créer un compte de service Google Cloud (GCP) {#create-a-google-cloud-gcp-service-account}

Suivez [ces instructions](https://docs.openshift.com/container-platform/4.9/installing/installing_gcp/installing-gcp-account.html#installation-gcp-service-account_installing-gcp-account) pour créer un compte de service dans le projet Google Cloud `cloud-native`. Associez tous les rôles marqués comme Requis dans ce document. Une fois le compte de service créé, générez une clé JSON et enregistrez-la sous `gcloud.json` à la racine de ce dépôt. Ce fichier est ignoré par Git.

## Créer votre cluster OpenShift {#create-your-openshift-cluster}

Pour créer le cluster OpenShift :

1. Clonez le dépôt GitLab Operator :

   ```shell
   git clone https://gitlab.com/gitlab-org/cloud-native/gitlab-operator.git
   ```

1. Exécutez le script pour créer le cluster OpenShift dans Google Cloud :

   ```shell
   cd gitlab-operator
   ./scripts/create_openshift_cluster.sh
   ```

Il s'agira d'un cluster à 6 nœuds avec 3 nœuds de plan de contrôle (master) et 3 nœuds worker. Le processus prend environ 40 minutes. Suivez les instructions à la fin de la sortie console pour vous connecter au cluster.

Une fois créé, vous devriez pouvoir voir votre cluster enregistré dans [Red Hat cloud](https://cloud.redhat.com/openshift/). Tous les journaux d'installation et les métadonnées seront stockés dans le répertoire `install-$CLUSTER_NAME/` de ce dépôt. Ce répertoire est ignoré par Git.

### Options de configuration {#configuration-options}

La configuration peut être appliquée lors de l'exécution en définissant des variables d'environnement. Toutes les options ont des valeurs par défaut, donc aucune option n'est obligatoire.

| Variable                         | Valeur par défaut                                      | Description |
|----------------------------------|----------------------------------------------|-------------|
| `CLUSTER_NAME`                   | `ocp-$USER`                                  | Nom du cluster |
| `BASE_DOMAIN`                    | `k8s-ft.win`                                 | Domaine racine du cluster |
| `GCP_PROJECT_ID`                 | `cloud-native-182609`                        | ID du projet Google Cloud |
| `GCP_REGION`                     | `us-central1`                                | Région Google Cloud du cluster |
| `GOOGLE_APPLICATION_CREDENTIALS` | `gcloud.json`                                | Chemin vers le fichier JSON du compte de service Google Cloud |
| `GOOGLE_CREDENTIALS`             | Contenu de `$GOOGLE_APPLICATION_CREDENTIALS` | Contenu du fichier JSON du compte de service Google Cloud |
| `PULL_SECRET_FILE`               | `pull_secret`                                | Chemin vers le fichier pull secret Red Hat |
| `PULL_SECRET`                    | Contenu de `$PULL_SECRET_FILE`               | Contenu du fichier pull secret Red Hat |
| `SSH_PUBLIC_KEY_FILE`            | `$HOME/.ssh/id_rsa.pub`                      | Chemin vers le fichier de clé publique SSH |
| `SSH_PUBLIC_KEY`                 | Contenu de `$SSH_PUBLIC_KEY_FILE`            | Contenu du fichier de clé publique SSH |
| `LOG_LEVEL`                      | `info`                                       | Niveau de verbosité de la sortie `openshift-install` |
| `INSTALL_DIR`                    | `install-$CLUSTER_NAME`                      | Répertoire pour les ressources d'installation, utile pour lancer plusieurs clusters |

> [!note]
> Les variables `CLUSTER_NAME` et `BASE_DOMAIN` sont combinées pour construire le nom de domaine du cluster.

## Détruire votre cluster OpenShift {#destroy-your-openshift-cluster}

Pour détruire le cluster OpenShift :

1. Clonez le dépôt GitLab Operator :

   ```shell
   git clone https://gitlab.com/gitlab-org/cloud-native/gitlab-operator.git
   ```

1. Exécutez le script pour détruire le cluster OpenShift dans Google Cloud. Cela prend environ 4 minutes :

   ```shell
   cd gitlab-operator
   ./scripts/destroy_openshift_cluster.sh
   ```

La configuration peut être appliquée lors de l'exécution en définissant les variables d'environnement suivantes. Toutes les options ont des valeurs par défaut, aucune option n'est obligatoire.

| Variable                         | Valeur par défaut                                      | Description |
|----------------------------------|----------------------------------------------|-------------|
| `GOOGLE_APPLICATION_CREDENTIALS` | `gcloud.json`                                | Chemin vers le fichier JSON du compte de service Google Cloud |
| `GOOGLE_CREDENTIALS`             | Contenu de `$GOOGLE_APPLICATION_CREDENTIALS` | Contenu du fichier JSON du compte de service Google Cloud |
| `LOG_LEVEL`                      | `info`                                       | Niveau de verbosité de la sortie `openshift-install` |
| `INSTALL_DIR`                    | `install-$CLUSTER_NAME`                      | Répertoire pour les ressources d'installation, utile pour lancer plusieurs clusters |

## Étapes suivantes {#next-steps}

Lorsque le cluster est opérationnel, vous pouvez continuer en [installant GitLab](https://docs.gitlab.com/operator/).

## Ressources {#resources}

- [Code source de `openshift-installer`](https://github.com/openshift/installer)
- [Code source de `oc`](https://github.com/openshift/oc)
- [Packages `openshift-installer` et `oc`](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/)
- [Documentation sur l'architecture d'OpenShift Container Project (OCP)](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.9/html/architecture/architecture)
- [Documentation OpenShift GCP](https://docs.openshift.com/container-platform/4.9/installing/installing_gcp/installing-gcp-account.html)
- [Guide de dépannage OpenShift](https://docs.openshift.com/container-platform/4.9/support/troubleshooting/troubleshooting-installations.html)
