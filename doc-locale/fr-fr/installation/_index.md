---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Installer GitLab avec Helm
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Installez GitLab sur Kubernetes à l'aide du chart Helm cloud-native de GitLab.

Si vous avez déjà installé et configuré les [prérequis](tools.md),
vous pouvez [déployer GitLab](deployment.md) avec la commande `helm`.

> [!note]
> Le chart Helm de GitLab nécessite des services PostgreSQL, Redis et de stockage objet externes pour les déploiements en production.
> Les versions intégrées de ces services sont fournies uniquement à des fins d'évaluation.
> Pour la production, suivez l'[architecture de référence Cloud Native Hybrid](#utiliser-les-architectures-de-référence).

Pour un déploiement en production, vous devez posséder une solide connaissance pratique de Kubernetes.
Cette méthode de déploiement implique une gestion, une observabilité et des concepts différents de ceux des déploiements traditionnels.

Dans un déploiement en production :

- Les composants avec état, tels que PostgreSQL, Redis ou Gitaly (un plan de données pour le stockage des dépôts Git),
  doivent s'exécuter en dehors du cluster, sur des services PaaS ou des instances de calcul. Cette configuration est nécessaire
  pour assurer l'évolutivité et la fiabilité des différentes charges de travail rencontrées dans les environnements GitLab de production.
- Vous devez utiliser des services Cloud PaaS pour PostgreSQL, Redis et le stockage objet pour tout le stockage hors dépôts Git.

Si Kubernetes n'est pas requis pour votre instance GitLab, consultez les
[architectures de référence](https://docs.gitlab.com/administration/reference_architectures/)
pour découvrir des alternatives plus simples.

## Images de conteneurs

Le chart Helm de GitLab utilise les images de conteneurs [Cloud Native GitLab (CNG)](https://gitlab.com/gitlab-org/build/CNG)
pour déployer GitLab. Outre les images CNG pour GitLab, la configuration par défaut
utilise des images publiées par des tiers (par exemple, Bitnami) pour déployer PostgreSQL, Redis et MinIO
afin de simplifier les déploiements hors production.

Les instances de production ne doivent pas déployer ces services tiers (avec état)
via le chart GitLab, comme indiqué ci-dessus.

Consultez la documentation suivante pour savoir comment configurer le chart
afin d'utiliser des services externes.

1. [Base de données externe](../advanced/external-db/_index.md)
1. [Redis externe](../advanced/external-redis/_index.md)
1. [Stockage objet externe](../advanced/external-object-storage/_index.md)

> [!note]
> Depuis décembre 2024, [Bitnami a modifié sa politique de build](https://github.com/bitnami/containers/issues/75671)
> pour ne mettre à jour que la dernière version majeure stable de chaque application dans le catalogue gratuit. Le chart GitLab
> continuera d'utiliser par défaut les images disponibles publiquement.
>
> En juillet 2025, [Bitnami a annoncé](https://github.com/bitnami/containers/issues/75671) que l'accès aux charts
> et images sécurisés et versionnés nécessiterait un abonnement à Bitnami Secure Images, une offre payante.
>
> Par conséquent, les versions de ces charts Bitnami configurées par GitLab deviendront obsolètes.
> Les équipes qui déploient ces charts Bitnami à des fins hors production doivent veiller à utiliser
> des images à jour et corrigées, adaptées à leurs exigences de sécurité.
>
> À partir de GitLab 19.0, le chart Helm de GitLab n'intégrera plus les charts Bitnami en raison
> de plusieurs changements liés aux licences, à la maintenance du projet et à la disponibilité des images publiques.
>
> Pour en savoir plus, consultez
> l'[annonce de dépréciation](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart)
> et [migrez](migration/bundled_chart_migration.md) vers des alternatives externes.

## Configurer le chart Helm pour utiliser des données avec état externes

Pour les déploiements de production, vous devez configurer le chart pour qu'il pointe
vers des services externes de stockage objet, Valkey/Redis, PostgreSQL et Gitaly,
conformes à l'[architecture de référence](https://docs.gitlab.com/administration/reference_architectures/) sélectionnée.

À des fins de démonstration et de test, le chart Helm de GitLab intègre les charts MinIO, Bitnami
PostgreSQL et Bitnami Redis. Cependant, en raison de plusieurs changements liés au projet et aux licences,
l'intégration de ces charts est dépréciée et leur suppression est prévue dans
GitLab 19.0.

Pour en savoir plus, consultez
l'[annonce de dépréciation](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart)
et [migrez](migration/bundled_chart_migration.md) vers des alternatives externes.

### Utiliser les architectures de référence

L'architecture de référence pour le déploiement d'instances GitLab sur Kubernetes s'appelle [Cloud Native Hybrid](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid), précisément parce que tous les services GitLab ne peuvent pas s'exécuter dans le cluster pour des implémentations de production. Tous les composants GitLab avec état doivent être déployés en dehors du cluster Kubernetes.

Les tailles d'architectures de référence Cloud Native Hybrid disponibles
sont répertoriées sur la page [Architectures de référence](https://docs.gitlab.com/administration/reference_architectures/#cloud-native-hybrid).
Par exemple, voici l'[architecture de référence Cloud Native Hybrid](https://docs.gitlab.com/administration/reference_architectures/3k_users/#cloud-native-hybrid-reference-architecture-with-helm-charts-alternative) pour 3 000 utilisateurs.

### Utiliser l'Infrastructure as Code (IaC) et les ressources de déploiement

GitLab développe de l'Infrastructure as Code capable de configurer la combinaison de charts Helm et d'infrastructure cloud complémentaire :

- [GitLab Environment Toolkit IaC](https://gitlab.com/gitlab-org/gitlab-environment-toolkit).
- [Modèle d'implémentation : provisionner GitLab Cloud Native Hybrid sur AWS EKS](https://docs.gitlab.com/solutions/cloud/aws/gitlab_instance_on_aws/) :
  cette ressource fournit une nomenclature testée avec le GitLab Performance Toolkit
  et utilise le calculateur de coûts AWS pour l'estimation budgétaire.

## Mises à niveau sans interruption de service

Les mises à niveau sans interruption de service vous permettent de mettre à niveau GitLab sans interruption. Pour activer cette fonctionnalité, vous devez configurer les stratégies de mise à jour progressive lors de l'installation initiale. Si vous ajoutez ces paramètres à un déploiement existant ultérieurement, cela déclenchera le redémarrage des pods et pourra entraîner une brève interruption.

> [!warning]
> Garantir l'absence totale d'interruption lors d'une mise à niveau est particulièrement complexe pour toute application distribuée. La documentation a été testée telle quelle sur nos architectures de référence haute disponibilité et n'a révélé aucune interruption observable. Cependant, les résultats peuvent varier en fonction de la configuration spécifique de votre système.
>
> Pendant la mise à niveau, les utilisateurs peuvent temporairement constater des incohérences dans l'interface ou des erreurs HTTP 404 pour les ressources statiques, car les requêtes sont réparties entre des pods exécutant des versions différentes. Ces problèmes se résolvent généralement en actualisant la page.

Pour configurer votre déploiement en vue de mises à niveau sans interruption, veillez à inclure les paramètres de mise à jour progressive décrits dans les [Paramètres de déploiement recommandés](upgrade.md#recommended-deployment-settings).

Pour les procédures complètes de mise à niveau, consultez la documentation [Mise à niveau sans interruption de service](upgrade.md#upgrade-with-zero-downtime).
