---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Installer GitLab avec Helm
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Installez GitLab sur Kubernetes en utilisant le chart Helm GitLab natif cloud.

En supposant que vous ayez déjà installé et configuré les [prérequis](tools.md) , vous pouvez [déployer GitLab](deployment.md) avec la commande `helm`.

> [!note]
> Le chart Helm GitLab nécessite PostgreSQL, Redis et un stockage objet externes. Pour la production, suivez l'[architecture de référence Cloud Native Hybrid](#use-the-reference-architectures).

Pour un déploiement en production, vous devez avoir une solide connaissance pratique de Kubernetes. Cette méthode de déploiement implique une gestion, une observabilité et des concepts différents de ceux des déploiements traditionnels.

Dans un déploiement en production :

- PostgreSQL et Redis doivent s'exécuter en dehors du cluster sur des instances PaaS ou de calcul. Cette configuration est nécessaire pour faire évoluer et assurer de manière fiable les différentes charges de travail présentes dans les environnements GitLab en production.
- Vous devez utiliser Cloud PaaS pour PostgreSQL, Redis et le stockage objet pour tous les stockages non liés aux dépôts Git.

Si Kubernetes n'est pas requis pour votre instance GitLab, consultez les [architectures de référence](https://docs.gitlab.com/administration/reference_architectures/) pour des alternatives plus simples.

## Images de conteneurs {#container-images}

Le chart Helm GitLab utilise les images de conteneurs [Cloud Native GitLab (CNG)](https://gitlab.com/gitlab-org/build/CNG) pour déployer GitLab. Outre les images CNG pour GitLab lui-même, la configuration par défaut utilise MinIO pour le stockage objet dans les déploiements hors production.

PostgreSQL, Redis et un stockage objet externes sont requis. Reportez-vous à la documentation suivante pour savoir comment configurer le chart afin d'utiliser des services externes.

1. [Base de données externe](../advanced/external-db/_index.md)
1. [Redis externe](../advanced/external-redis/_index.md)
1. [Stockage objet externe](../advanced/external-object-storage/_index.md)

## Configurer le chart Helm pour utiliser des données stateful externes {#configure-the-helm-chart-to-use-external-stateful-data}

Configurez le chart pour pointer vers un stockage objet externe, Redis, PostgreSQL et les services Gitaly correspondant à l'[architecture de référence](https://docs.gitlab.com/administration/reference_architectures/) sélectionnée.

### Utiliser les architectures de référence {#use-the-reference-architectures}

L'architecture de référence pour le déploiement d'instances GitLab sur Kubernetes est appelée [Cloud Native Hybrid](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid), précisément parce que tous les services GitLab ne peuvent pas s'exécuter dans le cluster pour des implémentations de niveau production. Tous les composants GitLab stateful doivent être déployés en dehors du cluster Kubernetes.

Les tailles d'architectures de référence Cloud Native Hybrid disponibles sont listées sur la page [Architectures de référence](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid). Par exemple, voici l'[architecture de référence Cloud Native Hybrid](https://docs.gitlab.com/administration/reference_architectures/3k_users/#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) pour 3 000 utilisateurs.

### Utiliser l'Infrastructure as Code (IaC) et les ressources de construction {#use-infrastructure-as-code-iac-and-builder-resources}

GitLab développe une Infrastructure as Code capable de configurer la combinaison de charts Helm et d'infrastructure cloud complémentaire :

- [GitLab Environment Toolkit IaC](https://gitlab.com/gitlab-org/gitlab-environment-toolkit).
- [Modèle d'implémentation : Provisionner GitLab cloud native hybrid sur AWS EKS](https://docs.gitlab.com/solutions/cloud/aws/gitlab_instance_on_aws/) :  Cette ressource fournit une nomenclature testée avec le GitLab Performance Toolkit et utilise le calculateur de coûts AWS pour la budgétisation.

## Mises à niveau sans interruption de service {#zero-downtime-upgrades}

Les mises à niveau sans interruption de service vous permettent de mettre à niveau GitLab sans interruption de service. Pour activer cette fonctionnalité, vous devez configurer des stratégies de mise à jour progressive lors de votre installation initiale. Si vous ajoutez ces paramètres à un déploiement existant ultérieurement, cela déclenchera des redémarrages de pods et pourra entraîner une brève interruption de service.

> [!warning]
> Atteindre une disponibilité sans interruption dans le cadre d'une mise à niveau est particulièrement difficile pour toute application distribuée. La documentation a été testée telle quelle sur nos architectures de référence HA et a abouti à une indisponibilité effectivement non observable. Cependant, sachez que les résultats peuvent varier en fonction de la composition spécifique de votre système.
>
> Pendant la mise à niveau, les utilisateurs peuvent rencontrer temporairement des incohérences d'interface ou des erreurs HTTP 404 pour des ressources, car les requêtes sont routées entre des pods exécutant des versions différentes ; ces problèmes se résolvent généralement avec un rechargement de page.

Pour configurer votre déploiement pour des mises à niveau sans interruption de service, veillez à inclure les paramètres de mise à jour progressive des [Paramètres de déploiement recommandés](upgrade.md#recommended-deployment-settings).

Pour les procédures de mise à niveau complètes, consultez la documentation [Mise à niveau sans interruption de service](upgrade.md#upgrade-with-zero-downtime).
