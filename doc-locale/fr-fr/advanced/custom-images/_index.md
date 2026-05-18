---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser des images Docker personnalisées pour le chart GitLab
---

Dans certains scénarios (p. ex. les environnements hors ligne), vous pouvez préférer utiliser vos propres images plutôt que de les télécharger depuis Internet. Cela nécessite de spécifier votre propre registre/dépôt d'images Docker pour chacun des charts qui composent la release GitLab.

## Format d'image par défaut {#default-image-format}

Notre format par défaut pour l'image inclut dans la plupart des cas le chemin complet vers l'image, à l'exclusion du tag :

```yaml
image:
  repository: repo.example.com/image
  tag: custom-tag
```

Le résultat final sera `repo.example.com/image:custom-tag`.

## Images et tags actuels {#current-images-and-tags}

Lors de la planification d'une mise à niveau, votre `values.yaml` actuel et la version cible du chart GitLab peuvent être utilisés pour générer un [template Helm](https://helm.sh/docs/helm/helm_template/). Ce template contiendra les images et leurs tags respectifs qui seront nécessaires pour la version spécifiée du chart.

```shell
# Gather the latest values
helm get values gitlab > gitlab.yaml

# Use the gitlab.yaml to find the images and tags
helm template versionfinder gitlab/gitlab -f gitlab.yaml --version 7.3.0 | grep 'image:' | tr -d '[[:blank:]]' | sort --unique
```

Cette commande peut également être utilisée pour vérifier toutes les configurations personnalisées.

## Exemple de fichier de valeurs {#example-values-file}

Il existe un [exemple de fichier de valeurs](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/custom-images/values.yaml) qui montre comment configurer un registre/dépôt Docker personnalisé et un tag. Vous pouvez copier les sections pertinentes de ce fichier pour vos propres releases.

> [!note]
> Certains des charts (notamment les charts tiers) ont parfois des conventions légèrement différentes pour spécifier le registre/dépôt d'images et le tag. Vous pouvez trouver la documentation des charts tiers sur le [Artifact Hub](https://artifacthub.io/).
