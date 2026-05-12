---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Objectifs
---

Nous avons quelques objectifs fondamentaux avec cette initiative :

1. Facile à mettre à l'échelle horizontalement
1. Facile à déployer, mettre à niveau et maintenir
1. Large prise en charge des fournisseurs de services cloud
1. Prise en charge initiale de Kubernetes et Helm, avec la flexibilité de prendre en charge d'autres ordonnanceurs à l'avenir

## Ordonnanceur {#scheduler}

Nous lancerons avec la prise en charge de Kubernetes, qui est mature et largement soutenu dans l'industrie. Dans le cadre de notre conception, cependant, nous essaierons d'éviter les décisions qui empêcheraient la prise en charge d'autres ordonnanceurs. Cela est particulièrement vrai pour les projets Kubernetes en aval comme OpenShift et Tectonic. À l'avenir, d'autres ordonnanceurs pourront également être pris en charge, comme Docker Swarm et Mesosphere.

Nous visons à prendre en charge les capacités de mise à l'échelle et d'auto-réparation de Kubernetes :

- Vérifications de disponibilité et de santé pour s'assurer que les pods fonctionnent, et sinon pour les recycler
- Pistes pour prendre en charge les déploiements canary et progressifs
- [Mise à l'échelle automatique](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

Nous essaierons de tirer parti des fonctionnalités standard de Kubernetes :

- ConfigMaps pour la gestion de la configuration. Ceux-ci seront ensuite mappés ou transmis aux conteneurs Docker
- Secrets pour les données sensibles

Puisque nous pourrions également utiliser Consul, cela pourrait être utilisé à la place pour des raisons de cohérence avec d'autres méthodes d'installation.

## Charts Helm {#helm-charts}

<!-- vale gitlab_base.SubstitutionWarning = NO -->

Un chart Helm sera créé pour gérer le déploiement de chaque conteneur/service spécifique à GitLab. Nous inclurons également des charts groupés pour faciliter le déploiement global. Cela est particulièrement important pour cet effort, car il y aura significativement plus de complexité dans les couches Docker et Kubernetes que dans les solutions tout-en-un basées sur Omnibus. Helm peut aider à gérer cette complexité et fournir une interface de haut niveau simple pour gérer les paramètres via le fichier `values.yaml`.

Nous prévoyons d'offrir un ensemble de charts Helm à trois niveaux :

![Structure des charts Helm](../images/charts.png)
