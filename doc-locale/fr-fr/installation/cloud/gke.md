---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Préparation des ressources GKE pour le chart GitLab
---

{{< details >}}

- Édition :  version gretuite, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Pour une instance GitLab entièrement fonctionnelle, vous aurez besoin de quelques ressources avant de déployer le chart GitLab. Voici comment ces charts sont déployés et testés dans GitLab.

## Création du cluster GKE {#creating-the-gke-cluster}

Pour démarrer plus facilement, un script est fourni pour automatiser la création du cluster. Il est également possible de créer un cluster manuellement.

Prérequis :

- Installez les [prérequis](../tools.md).
- Installez le [SDK Google](https://cloud.google.com/sdk/docs/install).

### Création du cluster via un script {#scripted-cluster-creation}

Un [script de bootstrap](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/gke_bootstrap_script.sh) a été créé pour automatiser une grande partie du processus de configuration pour les utilisateurs sur GCP/GKE.

Le script va :

1. Créer un nouveau cluster GKE.
1. Autoriser le cluster à modifier les enregistrements DNS.
1. Configurer `kubectl` et le connecter au cluster.

Le script lit divers paramètres à partir des variables d'environnement et de l'argument `up` pour le démarrage ou `down` pour le nettoyage.

Le tableau ci-dessous décrit toutes les variables.

| Variable              | Valeur par défaut                     | Description |
|-----------------------|-----------------------------------|-------------|
| `ADMIN_USER`          | Utilisateur gcloud actuel               | L'utilisateur auquel attribuer l'accès cluster-admin lors de la configuration |
| `AUTOSCALE_MAX_NODES` | `NUM_NODES`                       | Le nombre maximum de nœuds jusqu'auquel l'autoscaler peut faire évoluer le cluster |
| `AUTOSCALE_MIN_NODES` | `0`                               | Le nombre minimum de nœuds jusqu'auquel l'autoscaler peut réduire le cluster |
| `CLUSTER_NAME`        | `gitlab-cluster`                  | Le nom du cluster. |
| `CLUSTER_VERSION`     | GKE par défaut, consultez les [notes de release GKE](https://cloud.google.com/kubernetes-engine/docs/release-notes) | La version de votre cluster GKE |
| `INT_NETWORK`         | default                           | L'espace IP à utiliser dans ce cluster |
| `MACHINE_TYPE`        | `n2d-standard-4`                  | Le type des instances du cluster |
| `NUM_NODES`           | `2`                               | Le nombre de nœuds requis |
| `PREEMPTIBLE`         | `false`                           | Moins cher, les clusters durent au *maximum* 24 h, aucun SLA sur les nœuds/disques |
| `PROJECT`             | Pas de valeur par défaut, doit être défini  | L'identifiant de votre projet GCP |
| `RBAC_ENABLED`        | `true`                            | Si vous savez si le contrôle d'accès basé sur les rôles est activé sur votre cluster, définissez cette variable |
| `REGION`              | `us-central1`                     | La région où se trouve votre cluster |
| `SUBNETWORK`          | Par défaut                           | Le sous-réseau à utiliser dans ce cluster |
| `USE_STATIC_IP`       | `false`                           | Crée une IP statique pour GitLab au lieu d'une adresse IP éphémère avec un DNS géré |
| `ZONE_EXTENSION`      | `b`                               | L'extension (`a`, `b`, `c`) du nom de zone où se trouvent les instances de votre cluster |

Exécutez le script en transmettant les paramètres souhaités. Il peut fonctionner avec les paramètres par défaut, à l'exception de `PROJECT` qui est obligatoire :

```shell
PROJECT=<gcloud project id> ./scripts/gke_bootstrap_script.sh up
```

Le script peut également être utilisé pour nettoyer les ressources GKE créées :

```shell
PROJECT=<gcloud project id> ./scripts/gke_bootstrap_script.sh down
```

Une fois le cluster créé, passez à la [création de l'entrée DNS](#dns-entry).

### Création manuelle du cluster {#manual-cluster-creation}

Deux ressources doivent être créées dans GCP : un cluster Kubernetes et une adresse IP externe.

#### Création du cluster Kubernetes {#creating-the-kubernetes-cluster}

Pour provisionner le cluster Kubernetes manuellement, suivez les [instructions GKE](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-zonal-cluster).

- Nous recommandons un cluster avec au moins 2 nœuds, chacun disposant de 4 vCPU et de 15 Go de RAM.
- Notez la région du cluster, elle sera nécessaire à l'étape suivante.

#### Création de l'adresse IP externe {#creating-the-external-ip}

Une adresse IP externe est requise pour que votre cluster soit accessible. L'adresse IP externe doit être régionale et se trouver dans la même région que le cluster lui-même. Une adresse IP globale ou en dehors de la région du cluster **ne fonctionnera pas**.

Pour créer une adresse IP statique, exécutez :

`gcloud compute addresses create ${CLUSTER_NAME}-external-ip --region $REGION --project $PROJECT`

Pour obtenir l'adresse de l'IP nouvellement créée :

`gcloud compute addresses describe ${CLUSTER_NAME}-external-ip --region $REGION --project $PROJECT --format='value(address)'`

Nous utiliserons cette adresse IP pour la lier à un nom DNS dans la section suivante.

## Entrée DNS {#dns-entry}

Si vous avez créé votre cluster manuellement ou utilisé l'option `USE_STATIC_IP` lors de la création via un script, vous aurez besoin d'un domaine public avec une entrée DNS de type A avec caractère générique pointant vers l'adresse IP que nous venons de créer.

Suivez le [guide de démarrage rapide Google DNS](https://cloud.google.com/dns/docs/set-up-dns-records-domain-name) pour créer l'entrée DNS.

## Prochaines étapes {#next-steps}

Poursuivez avec l'[installation du chart](../deployment.md) une fois que le cluster est opérationnel et que l'adresse IP statique et l'entrée DNS sont prêtes.
