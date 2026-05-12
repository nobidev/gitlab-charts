---
stage: GitLab Duo Self-Hosted
group: Custom models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Chart AI Gateway
---

{{< details >}}

- Niveau : Premium, Ultimate
- Offre : GitLab Self-Managed
- Statut : Expérience

{{< /details >}}

Le chart AI Gateway déploie l'AI Gateway en tant que sous-chart aux côtés de votre instance GitLab. Il active GitLab Duo Self-Hosted et la GitLab Duo Agent Platform sur Kubernetes. Cette fonctionnalité est une [expérience](https://docs.gitlab.com/ee/policy/experiment-beta-support.html).

Prérequis :

- TLS est requis pour l'URL GitLab. En mode production, l'AI Gateway exige que le point de terminaison GitLab soit sécurisé pour effectuer l'authentification avec l'instance GitLab. Cette configuration étant définie correctement par défaut, aucune action n'est requise.
- L'une ou l'autre des options suivantes :
  - Une licence cloud appliquée avec la [facturation à l'utilisation](https://docs.gitlab.com/subscriptions/gitlab_credits/) activée.
  - Une licence hors ligne avec l'addon [GitLab Duo Agent Platform Self-Hosted](https://docs.gitlab.com/subscriptions/subscription-add-ons/#gitlab-duo-agent-platform-self-hosted).

## Problèmes connus {#known-issues}

TLS n'est pas activé pour l'AI Gateway. Le trafic interne vers le service AI Gateway n'est pas sécurisé. Ce service n'étant pas accessible en externe, nous ne pensons pas que ce problème connu soit une source de préoccupation.

## Configurer et déployer le chart {#configure-and-deploy-the-chart}

Pour configurer et déployer le chart :

1. Déployez le chart avec la configuration suivante :

   ```yaml
   global:
     hosts:
       domain: <YOUR_DOMAIN>

   ai-gateway:
     install: true
   ```

1. Une fois le chart déployé et votre instance disponible, dans le coin supérieur droit de votre instance GitLab, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **GitLab Duo**.
1. Sélectionnez **Modifier la configuration** et :
   1. Remplacez l'**URL de la passerelle d'IA locale** par `http://<RELEASE_NAME>-ai-gateway`.
   1. Remplacez l'**URL locale du service GitLab Duo Agent Platform** par `<RELEASE_NAME>-ai-gateway:50052`.
   1. Désactivez **Utiliser TLS pour le service GitLab Duo Agent Platform**.
   1. Si vous utilisez une licence hors ligne, assurez-vous de sélectionner un modèle pour les fonctionnalités **Suggestions de code** et **GitLab Duo Agent Platform**. Pour plus d'informations, consultez [configurer GitLab pour utiliser des modèles auto-hébergés](https://docs.gitlab.com/administration/gitlab_duo_self_hosted/configure_duo_features/).
1. Sélectionnez **Sauvegarder les modifications**.
1. Sur la page **GitLab Duo** (`/admin/gitlab_duo`), sélectionnez **Lancer l'état des services** pour vérifier que tout fonctionne correctement.
