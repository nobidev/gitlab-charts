---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Chart Helm GitLab
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour installer une version cloud-native de GitLab, utilisez le chart Helm GitLab. Ce chart contient tous les composants nécessaires pour démarrer et peut évoluer pour des déploiements à grande échelle.

Pour les installations basées sur OpenShift, utilisez [GitLab Operator](https://docs.gitlab.com/operator/), sinon vous devez mettre à jour vous-même les [contraintes de contexte de sécurité](https://docs.gitlab.com/operator/security_context_constraints/).

> [!note]
> Le chart Helm GitLab nécessite un PostgreSQL externe, Redis et un stockage d'objets pour les déploiements en production. Les versions intégrées de ces services sont incluses à des fins d'évaluation uniquement. Pour la production, suivez les [architectures de référence Cloud Native Hybrid](installation/_index.md#use-the-reference-architectures).

Pour un déploiement en production, vous devez avoir une solide connaissance pratique de Kubernetes. Cette méthode de déploiement implique une gestion, une observabilité et des concepts différents de ceux des déploiements traditionnels.

Le chart Helm GitLab est composé de plusieurs [sous-charts](charts/gitlab/_index.md), chacun pouvant être installé séparément.

## En savoir plus {#learn-more}

- [Tester le chart GitLab sur GKE ou EKS](quickstart/_index.md)
- [Migrer du package Linux vers le chart GitLab](installation/migration/_index.md)
- [Préparer le déploiement](installation/_index.md)
- [Déployer](installation/deployment.md)
- [Afficher les options de déploiement](installation/command-line-options.md)
- [Configurer les variables globales](charts/globals.md)
- [Afficher les sous-charts](charts/gitlab/_index.md)
- [Afficher les options de configuration avancées](advanced/_index.md)
- [Afficher les décisions architecturales](architecture/_index.md)
- Contribuez au développement en consultant la [documentation développeur](development/_index.md) et les [directives de contribution](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/CONTRIBUTING.md)
- Créer un [ticket](https://gitlab.com/gitlab-org/charts/gitlab/-/issues)
- Créer une [merge request](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests)
- Consulter les informations de [dépannage](troubleshooting/_index.md)
