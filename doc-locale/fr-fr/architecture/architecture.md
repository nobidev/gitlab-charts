---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Architecture
---

Nous prévoyons de prendre en charge trois niveaux de composants :

1. Conteneurs Docker
1. Ordonnanceur (Kubernetes)
1. Outil de configuration de niveau supérieur (Helm)

La méthode principale que les clients utiliseraient pour effectuer l'installation serait le [chart Helm](https://helm.sh/) dans ce dépôt. À un moment donné dans le futur, nous pourrons également proposer d'autres méthodes de déploiement, comme Amazon CloudFormation ou Docker Swarm.

## Images de conteneurs Docker {#docker-container-images}

Comme base, nous allons créer un conteneur Docker pour chaque service. Cela permettra une mise à l'échelle horizontale plus facile avec une taille d'image et une complexité réduites. La configuration doit être transmise de manière standard pour Docker, peut-être via des variables d'environnement ou un fichier monté. Cela fournit une interface commune et propre avec le logiciel d'ordonnancement.

### Images Docker GitLab {#gitlab-docker-images}

L'application GitLab est construite à l'aide d'images Docker contenant des services spécifiques à GitLab. Les environnements de build pour ces images se trouvent dans le [dépôt CNG](https://gitlab.com/gitlab-org/build/CNG).

Les composants GitLab suivants ont des images dans le dépôt CNG.

- Gitaly
- GitLab Elasticsearch Indexer
- [mail_room](https://github.com/tpitale/mail_room)
- GitLab Exporter
- GitLab Shell
- Sidekiq
- GitLab Toolbox
- Webservice
- Workhorse

Les charts suivants sont des charts dupliqués qui utilisent également des images Docker spécifiques à GitLab.

Images Docker utilisées pour `initContainers` et divers `Job`s.

- alpine-certificates
- kubectl

### Images Docker officielles {#official-docker-images}

Nous exploitons les conteneurs officiels existants suivants pour les services sous-jacents :

- Docker Distribution ([Docker Registry 2.0](https://github.com/distribution/distribution))
- Prometheus
- NGINX Ingress
- cert-manager
- Redis
- PostgreSQL

## Le chart GitLab {#the-gitlab-chart}

Il s'agit du chart GitLab de niveau supérieur (`gitlab`), qui configure toutes les ressources nécessaires pour une configuration complète de GitLab. Cela inclut les charts GitLab, PostgreSQL, Redis, Ingress et de gestion des certificats.

À ce niveau élevé, un client peut prendre des décisions telles que :

- S'il souhaite utiliser le chart PostgreSQL intégré ou utiliser une base de données externe comme Amazon RDS for PostgreSQL.
- Apporter ses propres certificats SSL ou utiliser Let's Encrypt.
- Utiliser un équilibreur de charge ou un Ingress dédié.

Les clients qui souhaitent démarrer rapidement et facilement doivent commencer avec ce chart.

### Structure de ces charts {#structure-of-these-charts}

Le chart GitLab principal est un chart parapluie, composé de nombreux autres charts. Chaque sous-chart est documenté individuellement et organisé dans une structure qui correspond à la structure du répertoire [charts](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts).

Les composants non-GitLab sont packagés et documentés au niveau supérieur. Les services de composants GitLab sont documentés sous le chart [GitLab](../charts/gitlab/_index.md) :

- [NGINX](../charts/nginx/_index.md)
- [MinIO](../charts/minio/_index.md)
- [Registry](../charts/registry/_index.md)
- GitLab/[Gitaly](../charts/gitlab/gitaly/_index.md)
- GitLab/[GitLab Exporter](../charts/gitlab/gitlab-exporter/_index.md)
- GitLab/[GitLab Shell](../charts/gitlab/gitlab-shell/_index.md)
- GitLab/[Migrations](../charts/gitlab/migrations/_index.md)
- GitLab/[Sidekiq](../charts/gitlab/sidekiq/_index.md)
- GitLab/[Webservice](../charts/gitlab/webservice/_index.md)

### Liste des composants {#components-list}

Une liste des composants déployés lors de l'utilisation du chart, ainsi que des instructions de configuration si nécessaire, est disponible sur la page [liste des composants de l'architecture](https://docs.gitlab.com/development/architecture/#component-list).

## Décisions de conception {#design-decisions}

La documentation des décisions prises concernant l'architecture de ces charts peut être trouvée dans la documentation [Décisions de conception](decisions.md)
