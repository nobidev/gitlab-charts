---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Décisions de conception
---

Cette documentation recueille le raisonnement et les décisions prises concernant la conception des charts Helm dans ce dépôt. Les propositions sont les bienvenues, voir [Decision Making](decision-making.md) pour savoir comment nous appliquons les décisions.

## Tenter de détecter les configurations problématiques {#attempt-to-catch-problematic-configurations}

En raison de la complexité de ces charts et de leur niveau de flexibilité, il existe des chevauchements où il est possible de produire une configuration qui conduirait à un déploiement imprévisible ou entièrement non fonctionnel. Dans le but de prévenir les combinaisons de paramètres problématiques connus, nous avons implémenté une logique de template conçue pour détecter et avertir l'utilisateur que sa configuration ne fonctionnera pas.

Cela reproduit le comportement des dépréciations, mais est spécifique à la garantie d'une configuration fonctionnelle.

Introduit dans [!757 checkConfig: add methods to test for known errors](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/757)

## Changements importants via la dépréciation {#breaking-changes-via-deprecation}

Au cours du développement de ces charts, nous apportons occasionnellement des améliorations qui nécessitent des modifications des propriétés des déploiements existants. Deux exemples ont été la centralisation de la configuration de l'utilisation de MinIO, et la migration de la configuration du stockage d'objets externe des propriétés vers des secrets (conformément à notre préférence).

Afin d'empêcher un utilisateur de déployer accidentellement une version mise à jour de ces charts qui inclut un changement important par rapport à une configuration qui ne fonctionnerait pas, nous avons choisi d'implémenter des notifications de [dépréciation](../development/_index.md#handling-configuration-deprecations). Celles-ci sont conçues pour détecter les propriétés qui ont été déplacées, modifiées, remplacées ou entièrement supprimées, puis informer l'utilisateur des modifications à apporter à la configuration. Cela peut inclure l'information de l'utilisateur pour consulter la documentation sur la façon de remplacer une propriété par un secret. Ces notifications feront en sorte que les commandes Helm `install` ou `upgrade` s'arrêtent avec une erreur d'analyse, et produiront une liste complète des éléments à traiter. Nous avons veillé à ce qu'un utilisateur ne soit pas placé dans une boucle d'erreur, de correction et de répétition.

Toutes les dépréciations doivent être traitées pour qu'un déploiement réussi puisse avoir lieu. Nous pensons que l'utilisateur préférerait être informé d'un changement important plutôt que de rencontrer un comportement inattendu ou un échec complet nécessitant un débogage.

Introduit dans [!396 Deprecations: implement buffered list of deprecations](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/396)

## Préférence des secrets dans initContainer plutôt que dans l'environnement {#preference-of-secrets-in-initcontainer-over-environment}

Une grande partie de l'écosystème des conteneurs dispose, ou attend, la capacité d'être configurée via des variables d'environnement. Cette [pratique de configuration](https://12factor.net/config) découle du concept de [The Twelve-Factor App](https://12factor.net). Cela simplifie grandement la configuration dans plusieurs environnements de déploiement, mais il subsiste une préoccupation de sécurité concernant le passage de secrets de connexion tels que les mots de passe et les clés privées via l'environnement du conteneur.

La plupart des écosystèmes de conteneurs fournissent une méthode simple pour inspecter l'état d'un conteneur en cours d'exécution, qui inclut généralement l'environnement. En utilisant [Docker](https://www.docker.com/) comme exemple, tout processus capable de communiquer avec le daemon peut interroger l'état de tous les conteneurs en cours d'exécution. Cela signifie que si vous disposez d'un conteneur privilégié tel que [`dind`](https://hub.docker.com/r/gitlab/dind/), ce conteneur peut alors inspecter l'environnement de _n'importe quel_ conteneur sur un nœud donné, et exposer _tous_ les secrets qu'il contient. En tant que partie du [cycle de vie DevOps complet](https://about.gitlab.com/blog/from-dev-to-devops/), [`dind`](https://hub.docker.com/r/gitlab/dind/) est régulièrement utilisé pour construire des conteneurs qui seront envoyés vers un registre puis déployés.

Cette préoccupation est la raison pour laquelle nous avons décidé de préférer le remplissage des informations sensibles via les [initContainers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/).

Problèmes connexes :

- [\#90](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/90)
- [\#114](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/114)

## Les sous-charts sont déployés depuis le chart global {#sub-charts-are-deployed-from-global-chart}

Tous les sous-charts de ce dépôt sont conçus pour être déployés via le chart global. Chaque composant peut toujours être déployé individuellement, mais utilise un ensemble commun de propriétés facilité par le chart global.

Cette décision simplifie à la fois l'utilisation et la maintenance du dépôt dans son ensemble.

Problème connexe :

- [\#352](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/352)

## Les partiels de templates pour `gitlab/*` doivent être globaux dans la mesure du possible {#template-partials-for-gitlab-should-be-global-whenever-possible}

Tous les partiels de templates des sous-charts `gitlab/*` doivent faire partie du chart global ou du sous-chart GitLab `templates/_helpers.tpl` dans la mesure du possible. Les templates provenant des [charts dupliqués](#forked-charts) resteront une partie de ces charts. Cela réduit l'impact de maintenance de ces duplications.

Les avantages sont évidents :

- Comportement DRY accru, conduisant à une maintenance plus facile. Il ne devrait y avoir aucune raison d'avoir des doublons de la même fonction dans plusieurs sous-charts quand une seule entrée suffira.
- Réduction des conflits de nommage des templates. Tous les [partiels d'un chart sont compilés ensemble](https://helm.sh/docs/chart_template_guide/named_templates/#declaring-and-using-templates-with-define-and-template), et nous pouvons donc les traiter comme le comportement global qu'ils représentent.

Problème connexe :

- [\#352](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/352)

## Intégration d'Envoy Gateway {#bundling-envoy-gateway}

Nous intégrons le chart officiel [Envoy Gateway](https://gateway.envoyproxy.io/) pour faciliter les transitions depuis notre chart NGINX Ingress précédemment intégré et garantir un processus d'installation transparent.

### Contexte de l'API Gateway {#gateway-api-background}

L'[API Gateway](https://gateway-api.sigs.k8s.io/) est le successeur de l'API Ingress de Kubernetes, conçue pour offrir des capacités de routage plus expressives et une meilleure séparation des préoccupations. Contrairement à Ingress, qui confondait les responsabilités de configuration, l'API Gateway définit trois rôles distincts :

- **Infrastructure Provider** : Installe et gère l'implémentation du contrôleur Gateway (par exemple, Envoy Gateway, Istio, Kong) et définit les ressources GatewayClass.
- **Cluster Operator** : Configure les ressources Gateway qui provisionnent les équilibreurs de charge et définissent les limites réseau.
- **Application Developer** (par exemple GitLab, Inc) : Crée des ressources Route (HTTPRoute, TCPRoute, etc.) qui s'attachent aux Gateways et acheminent le trafic vers leurs services.

Cette séparation permet aux organisations de diviser les responsabilités réseau : les équipes d'infrastructure gèrent le contrôleur et l'infrastructure gateway, tandis que les équipes d'application gèrent leur propre routage sans avoir besoin d'autorisations au niveau du cluster.

### Pourquoi intégrer un contrôleur Gateway ? {#why-bundle-a-gateway-controller}

L'intégration d'Envoy Gateway avec GitLab diverge intentionnellement de la séparation de personas prévue par l'API Gateway. Dans le modèle d'API Gateway, les fournisseurs d'infrastructure (et non les applications) installeraient les contrôleurs, et les opérateurs de cluster provisionneraient les Gateways séparément des déploiements d'applications.

Cependant, l'intégration offre des avantages critiques pour le cas d'utilisation de GitLab, mais comporte également certains risques.

### Avantages {#advantages}

- Fournit une solution réseau validée et préconfigurée pour l'exposition de GitLab.
- Simplifie la transition depuis les contrôleurs Ingress intégrés existants.
- Simplifie l'adoption dans l'infrastructure gérée par GitLab (y compris .com, Dedicated) et le GitLab Environment Toolkit.
- L'implémentation Gateway de nombreux fournisseurs Cloud ne supporte pas les TCPRoutes, qui sont nécessaires pour exposer GitLab au trafic SSH.
- Offre aux clients FIPS, y compris Dedicated for Government, un chemin de migration depuis le NGINX Ingress intégré, pour lequel GitLab propose actuellement des builds FIPS.
- Envoy Gateway offre de puissantes extensions à l'API Gateway standard. Ces extensions permettent une configuration avancée non disponible avec l'API Gateway standard.
- Permet l'adoption d'Envoy, dont d'autres [fonctionnalités GitLab](https://gitlab.com/gitlab-org/architecture/auth-architecture/design-doc/-/blob/0d779e8aae72db3f1f045c69d0e693739f2f5fc8/decisions/005_adopt_envoy.md) dépendront.
- Les clients peuvent toujours choisir de déployer leur contrôleur API Gateway préféré à la place d'Envoy Gateway intégré.

L'implémentation de la Gateway au sein de l'application GitLab tiendra compte des clients qui souhaitent suivre les personas prescrites de l'API Gateway et maintenir l'option permettant aux Cluster Operators de choisir de gérer eux-mêmes la Gateway. De même, les clients ayant des exigences de configuration spéciales ou inhabituelles pour leurs Gateways seront encouragés à gérer et configurer la Gateway eux-mêmes.

Le chart GitLab utilisera des ressources API Gateway standard et stables dans la mesure du possible. Les ressources expérimentales ou spécifiques à un fournisseur ne sont utilisées que pour des fonctionnalités optionnelles ou pour des fonctionnalités non configurables avec des ressources standard ou stables telles que Git via SSH, le service croisé du trafic gRPC et WSS pour KAS, ou pour le support des Smartcards.

### Considérations {#considerations}

- L'API Gateway et Envoy Gateway nécessitent des définitions de ressources de cluster spécifiques. Étant donné que [Helm ne prend pas en charge les mises à niveau des CRD](https://helm.sh/docs/v3/chart_best_practices/custom_resource_definitions), une intervention manuelle peut être nécessaire.
- L'intégration d'un contrôleur API Gateway aux côtés d'une application diverge de la [séparation des personas d'utilisateurs](https://gateway-api.sigs.k8s.io/) prévue.
- Les déploiements conformes FIPS doivent utiliser des images alternatives plutôt que les versions officielles en amont. Les builds FIPS appartenant à GitLab sont actuellement [en cours de développement](https://gitlab.com/gitlab-org/build/CNG/-/merge_requests/2716).

## Charts dupliqués {#forked-charts}

Les charts suivants ont été dupliqués ou recréés dans ce dépôt conformément à nos [directives pour les duplications et les nouveaux charts](../development/readiness/_index.md)

### Redis {#redis}

Avec la release `3.0` du chart Helm GitLab, nous ne dupliquons plus le [chart Redis en amont](https://github.com/bitnami/charts/tree/main/bitnami/redis), mais l'incluons plutôt comme dépendance.

### Redis HA {#redis-ha}

Redis-HA était un chart que nous incluions dans nos releases avant la `3.0`. Il a maintenant été supprimé et remplacé par le [chart Redis en amont](https://github.com/bitnami/charts/tree/main/bitnami/redis) qui a ajouté la prise en charge optionnelle de la haute disponibilité.

### MinIO {#minio}

Notre [chart MinIO](../charts/minio/_index.md) a été modifié à partir du [MinIO](https://github.com/helm/charts/tree/master/stable/minio) en amont.

- Utilisation des secrets Kubernetes préexistants au lieu d'en créer de nouveaux à partir des propriétés.
- Suppression de la fourniture des clés sensibles via l'environnement.
- Automatiser la création de plusieurs buckets via `defaultBuckets` à la place des propriétés `defaultBucket.*`.

### registry {#registry}

Notre [chart registry](../charts/registry/_index.md) a été modifié à partir du [`docker-registry`](https://github.com/helm/charts/tree/master/stable/docker-registry) en amont.

- Activer automatiquement l'utilisation des services MinIO intégrés au chart.
- Connecter automatiquement l'authentification aux services GitLab.

### NGINX Ingress {#nginx-ingress}

Notre [chart NGINX Ingress](../charts/nginx/_index.md) a été modifié à partir du [NGINX Ingress](https://github.com/kubernetes/ingress-nginx) en amont.

- Ajout d'une fonctionnalité permettant que la ConfigMap TCP soit externe au chart
- Ajout d'une fonctionnalité permettant que la classe Ingress soit templatisée en fonction du nom de release

## Version de Kubernetes utilisée dans tout le chart {#kubernetes-version-used-throughout-chart}

Pour maximiser la prise en charge des différentes versions de Kubernetes, utilisez un `kubectl` qui est d'une version mineure inférieure à la release stable actuelle de Kubernetes. Cela devrait permettre la prise en charge d'au moins trois versions mineures de Kubernetes, voire davantage. Pour plus de discussion sur les versions de `kubectl`, voir le [ticket 1509](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1509).

Problèmes connexes :

- [`charts/gitlab#1509`](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1509)
- [`charts/gitlab#1583`](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1583)

Merge requests connexes :

- [`charts/gitlab!1053`](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/1053)
- [`build/CNG!329`](https://gitlab.com/gitlab-org/build/CNG/-/merge_requests/329)
- [`gitlab-build-images!251`](https://gitlab.com/gitlab-org/gitlab-build-images/-/merge_requests/251)

## Variantes d'images livrées avec CNG {#image-variants-shipped-with-cng}

Date : 2022-02-10

Le [projet CNG](https://gitlab.com/gitlab-org/build/CNG) fournit des images basées sur Debian et UBI. La décision de maintenir la configuration pour les deux distributions était basée sur les éléments suivants :

- Pourquoi nous livrons des images basées sur Debian :
  - Historique, précédent
  - Familiarité avec la distribution
  - Communauté vs « entreprise »
  - Absence de verrouillage perçu chez le fournisseur
- Pourquoi nous livrons des images basées sur UBI :
  - Requis dans certains environnements clients
  - Requis pour la certification RHEL et l'inclusion dans l'OpenShift Marketplace / RedHat Catalog

Une discussion plus approfondie sur ce sujet peut être trouvée dans le [ticket #3095](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3095).

## Politique de prise en charge des releases Kubernetes {#kubernetes-release-support-policy}

Date : 2024-03-26

GitLab prendra officiellement en charge trois releases mineures de Kubernetes : `N`, `N-1` et `N-2`. `N` est soit :

- La dernière version mineure publiée de Kubernetes, si nous avons terminé de la qualifier.
- La version mineure la plus récente suivante, si nous n'avons pas terminé ou commencé à qualifier la version mineure la plus récente.

Par exemple, si les releases actuellement disponibles sont `1.28`, `1.27`, `1.26`, `1.25` et que nous n'avons pas qualifié la release `1.28`, alors `N` serait `1.27` et nous prendrions officiellement en charge les releases `1.25`, `1.26` et `1.27` comme indiqué dans ce tableau.

| Release | Référence |
|---------|-----------|
| `1.27`  | `N`       |
| `1.26`  | `N-1`     |
| `1.25`  | `N-2`     |

Les détails peuvent être trouvés sur la [politique de prise en charge des releases Kubernetes et OpenShift de l'équipe Distribution](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/distribution/k8s-release-support-policy/)

## Politique de prise en charge des releases OpenShift {#openshift-release-support-policy}

Date : 2024-03-26

GitLab prendra officiellement en charge quatre releases mineures d'OpenShift -- `N`, `N-1`, `N-2` et `N-3`. Comme pour Kubernetes, `N` est soit :

- La dernière version mineure publiée d'OpenShift, si nous avons terminé de la qualifier.
- La version mineure la plus récente suivante, si nous n'avons pas terminé ou commencé à qualifier la version mineure la plus récente.

Par exemple, si les releases actuellement disponibles sont `4.14`, `4.13`, `4.12`, `4.11` et que nous n'avons pas qualifié la release 4.15, alors `N` serait `4.14` et nous prendrions officiellement en charge les releases `4.14`, `4.13`, `4.12` et `4.11` comme indiqué dans ce tableau.

| Release | Référence |
|---------|-----------|
| `4.14`  | `N`       |
| `4.13`  | `N-1`     |
| `4.12`  | `N-2`     |
| `4.11`  | `N-2`     |

Les détails peuvent être trouvés sur la [politique de prise en charge des releases Kubernetes et OpenShift de l'équipe Distribution](https://handbook.gitlab.com/handbook/engineering/infrastructure-platforms/gitlab-delivery/distribution/k8s-release-support-policy/)
