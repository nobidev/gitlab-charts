---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du chart GitLab-Exporter
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le sous-chart `gitlab-exporter` fournit des métriques Prometheus pour les données spécifiques à l'application GitLab. Il communique directement avec PostgreSQL pour effectuer des requêtes permettant de récupérer des données pour les builds CI, les miroirs de tirage (pull mirrors), etc. De plus, il utilise l'API Sidekiq, qui communique avec Redis pour collecter différentes métriques sur l'état des files d'attente Sidekiq (par exemple, le nombre de jobs).

## Prérequis {#requirements}

Ce chart dépend des services Redis et PostgreSQL, soit dans le cadre du chart GitLab complet, soit fournis en tant que services externes accessibles depuis le cluster Kubernetes sur lequel ce chart est déployé.

## Configuration {#configuration}

Le chart `gitlab-exporter` est configuré comme suit :  [Paramètres globaux](#global-settings) et [Paramètres du chart](#chart-settings).

## Options de ligne de commande d'installation {#installation-command-line-options}

Le tableau ci-dessous contient toutes les configurations de chart possibles qui peuvent être fournies à la commande `helm install` en utilisant les indicateurs `--set`.

| Paramètre                                                | Défaut                                                    | Description |
|----------------------------------------------------------|------------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                       | [Règles d'affinité](../_index.md#affinity) pour l'affectation des pods |
| `annotations`                                            |                                                            | Annotations de pod |
| `common.labels`                                          | `{}`                                                       | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `podLabels`                                              |                                                            | Labels de pod supplémentaires. Ne sera pas utilisé pour les sélecteurs. |
| `common.labels`                                          |                                                            | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `deployment.strategy`                                    | `{}`                                                       | Permet de configurer la stratégie de mise à jour utilisée par le déploiement |
| `enabled`                                                | `true`                                                     | Indicateur d'activation de GitLab Exporter |
| `extraContainers`                                        |                                                            | Chaîne de style littéral multiligne contenant une liste de conteneurs à inclure |
| `extraInitContainers`                                    |                                                            | Liste de conteneurs init supplémentaires à inclure |
| `extraVolumeMounts`                                      |                                                            | Liste de montages de volumes supplémentaires à effectuer |
| `extraVolumes`                                           |                                                            | Liste de volumes supplémentaires à créer |
| `extraEnv`                                               |                                                            | Liste de variables d'environnement supplémentaires à exposer |
| `extraEnvFrom`                                           |                                                            | Liste de variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| `image.pullPolicy`                                       | `IfNotPresent`                                             | Politique de tirage (pull policy) de l'image GitLab |
| `image.pullSecrets`                                      |                                                            | Secrets pour le dépôt d'images |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-exporter` | Dépôt d'images de GitLab Exporter |
| `image.tag`                                              |                                                            | Tag d'image   |
| `init.image.repository`                                  |                                                            | Image initContainer |
| `init.image.tag`                                         |                                                            | Tag d'image initContainer |
| `init.containerSecurityContext`                          |                                                            | Spécifique à initContainer : [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                    | Spécifique à initContainer :  Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                     | Spécifique à initContainer :  Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                | Spécifique à initContainer :  Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur |
| `metrics.enabled`                                        | `true`                                                     | Indique si un point de terminaison de métriques doit être disponible pour la collecte |
| `metrics.port`                                           | `9168`                                                     | Port du point de terminaison de métriques |
| `metrics.path`                                           | `/metrics`                                                 | Chemin du point de terminaison de métriques |
| `metrics.serviceMonitor.enabled`                         | `false`                                                    | Indique si un ServiceMonitor doit être créé pour permettre à l'opérateur Prometheus de gérer la collecte de métriques ; notez que son activation supprime les annotations de collecte `prometheus.io` |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                       | Labels supplémentaires à ajouter au ServiceMonitor |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                       | Configuration de point de terminaison supplémentaire pour le ServiceMonitor |
| `metrics.annotations`                                    |                                                            | **DEPRECATED** Définir des annotations de métriques explicites. Remplacé par le contenu du template. |
| `priorityClassName`                                      |                                                            | [Classe de priorité](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) assignée aux pods. |
| `resources.requests.cpu`                                 | `75m`                                                      | CPU minimum de GitLab Exporter |
| `resources.requests.memory`                              | `100M`                                                     | Mémoire minimum de GitLab Exporter |
| `serviceLabels`                                          | `{}`                                                       | Labels de service supplémentaires |
| `service.externalPort`                                   | `9168`                                                     | Port exposé de GitLab Exporter |
| `service.internalPort`                                   | `9168`                                                     | Port interne de GitLab Exporter |
| `service.name`                                           | `gitlab-exporter`                                          | Nom du service GitLab Exporter |
| `service.type`                                           | `ClusterIP`                                                | Type de service GitLab Exporter |
| `serviceAccount.annotations`                             | `{}`                                                       | Annotations ServiceAccount |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                    | Indique si le token d'accès ServiceAccount par défaut doit être monté dans les pods |
| `serviceAccount.create`                                  | `false`                                                    | Indique si un ServiceAccount doit être créé |
| `serviceAccount.enabled`                                 | `false`                                                    | Indique si un ServiceAccount doit être utilisé |
| `serviceAccount.name`                                    |                                                            | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé |
| `securityContext.fsGroup`                                | `1000`                                                     | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.runAsUser`                              | `1000`                                                     | ID utilisateur sous lequel le pod doit être démarré |
| `securityContext.fsGroupChangePolicy`                    |                                                            | Politique de changement de propriété et d'autorisation du volume (nécessite Kubernetes 1.23) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                           | Profil Seccomp à utiliser |
| `containerSecurityContext`                               |                                                            | Remplacer le [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel le conteneur est démarré |
| `containerSecurityContext.runAsUser`                     | `1000`                                                     | Permet de remplacer l'ID utilisateur du contexte de sécurité spécifique sous lequel le conteneur est démarré |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                    | Contrôle si un processus du conteneur peut obtenir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`                  | `false`                                                    | Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `tolerations`                                            | `[]`                                                       | Labels de tolérance pour l'affectation des pods |
| `psql.port`                                              |                                                            | Définit le port du serveur PostgreSQL. A la priorité sur `global.psql.port` |
| `tls.enabled`                                            | `false`                                                    | TLS de GitLab Exporter activé |
| `tls.secretName`                                         | `{Release.Name}-gitlab-exporter-tls`                       | Secret TLS de GitLab Exporter. Doit pointer vers un [secret TLS Kubernetes](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets). |
| `listenAddr`                                             | `*`                                                       | Adresse d'écoute de GitLab Exporter. |

## Exemples de configuration du chart {#chart-configuration-examples}

### extraEnv {#extraenv}

`extraEnv` vous permet d'exposer des variables d'environnement supplémentaires dans tous les conteneurs des pods.

Voici un exemple d'utilisation de `extraEnv` :

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

Lorsque le conteneur est démarré, vous pouvez confirmer que les variables d'environnement sont exposées :

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom` vous permet d'exposer des variables d'environnement supplémentaires provenant d'autres sources de données dans tous les conteneurs des pods.

Voici un exemple d'utilisation de `extraEnvFrom` :

```yaml
extraEnvFrom:
  MY_NODE_NAME:
    fieldRef:
      fieldPath: spec.nodeName
  MY_CPU_REQUEST:
    resourceFieldRef:
      containerName: test-container
      resource: requests.cpu
  SECRET_THING:
    secretKeyRef:
      name: special-secret
      key: special_token
      # optional: boolean
  CONFIG_STRING:
    configMapKeyRef:
      name: useful-config
      key: some-string
      # optional: boolean
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets` vous permet de vous authentifier auprès d'un registre privé pour récupérer des images pour un pod.

Des informations supplémentaires sur les registres privés et leurs méthodes d'authentification sont disponibles dans [la documentation Kubernetes](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Voici un exemple d'utilisation de `pullSecrets` :

```yaml
image:
  repository: my.image.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

Cette section contrôle si un ServiceAccount doit être créé et si le token d'accès par défaut doit être monté dans les pods.

| Nom                           |  Type   | Défaut | Description |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   Map   | `{}`    | Annotations ServiceAccount. |
| `automountServiceAccountToken` | Boolean | `false` | Contrôle si le token d'accès ServiceAccount par défaut doit être monté dans les pods. Vous ne devriez pas activer cela sauf si cela est requis par certains sidecars pour fonctionner correctement (par exemple, Istio). |
| `create`                       | Boolean | `false` | Indique si un ServiceAccount doit être créé. |
| `enabled`                      | Boolean | `false` | Indique si un ServiceAccount doit être utilisé. |
| `name`                         | String  |         | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé. |

### affinity {#affinity}

Pour plus d'informations, voir [`affinity`](../_index.md#affinity).

### annotations {#annotations}

`annotations` vous permet d'ajouter des annotations aux pods de GitLab Exporter. Par exemple :

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## Paramètres globaux {#global-settings}

Nous partageons certains paramètres globaux communs entre nos charts. Consultez la [documentation sur les paramètres globaux](../../globals.md) pour les options de configuration communes, telles que les noms d'hôte de GitLab et du registre.

## Paramètres du chart {#chart-settings}

Les valeurs suivantes sont utilisées pour configurer le pod GitLab Exporter.

### metrics.enabled {#metricsenabled}

Par défaut, le pod expose un point de terminaison de métriques à l'adresse `/metrics`. Lorsque les métriques sont activées, des annotations sont ajoutées à chaque pod permettant à un serveur Prometheus de découvrir et de scraper les métriques exposées.
