---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du chart GitLab-Sidekiq
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le sous-chart `sidekiq` fournit un déploiement configurable des workers Sidekiq, explicitement conçu pour permettre la séparation des files d'attente entre plusieurs `Deployment`s avec une scalabilité et une configuration individuelles.

Bien que ce chart fournisse une déclaration `pods:` par défaut, si vous fournissez une définition vide, vous n'aurez *aucun* worker.

## Prérequis {#requirements}

Ce chart dépend de l'accès aux services Redis, PostgreSQL et Gitaly fournis en tant que services externes accessibles depuis le cluster Kubernetes sur lequel ce chart est déployé.

## Choix de conception {#design-choices}

Ce chart crée plusieurs `Deployment`s et `ConfigMap`s associés. Il a été décidé qu'il serait plus clair d'utiliser les comportements de `ConfigMap` plutôt que d'utiliser des attributs `environment` ou des arguments supplémentaires à la `command` pour les conteneurs, afin d'éviter tout problème lié à la longueur des commandes. Ce choix entraîne un grand nombre de `ConfigMap`s, mais fournit des définitions très claires de ce que chaque pod doit faire.

## Configuration {#configuration}

Le chart `sidekiq` est configuré en trois parties : [services externes](#external-services) à l'échelle du chart, [paramètres par défaut à l'échelle du chart](#chart-wide-defaults) et [définitions par pod](#per-pod-settings).

## Options de ligne de commande pour l'installation {#installation-command-line-options}

Le tableau ci-dessous contient toutes les configurations possibles des charts qui peuvent être fournies à la commande `helm install` à l'aide des drapeaux `--set` :

| Paramètre                                                | Défaut                                                      | Description |
|----------------------------------------------------------|--------------------------------------------------------------|-------------|
| `annotations`                                            |                                                              | Annotations de pod |
| `podLabels`                                              |                                                              | Labels de pod supplémentaires. Ne sera pas utilisé pour les sélecteurs. |
| `common.labels`                                          |                                                              | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `concurrency`                                            | `20`                                                         | Concurrence par défaut de Sidekiq |
| `deployment.strategy`                                    | `{}`                                                         | Permet de configurer la stratégie de mise à jour utilisée par le déploiement |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                         | Durée facultative en secondes dont le pod a besoin pour se terminer correctement. |
| `enabled`                                                | `true`                                                       | Indicateur d'activation de Sidekiq |
| `extraContainers`                                        |                                                              | Chaîne de style littéral multiligne contenant une liste de conteneurs à inclure |
| `extraInitContainers`                                    |                                                              | Liste des conteneurs init supplémentaires à inclure |
| `extraVolumeMounts`                                      |                                                              | Modèle de chaîne de montages de volumes supplémentaires à configurer |
| `extraVolumes`                                           |                                                              | Modèle de chaîne de volumes supplémentaires à configurer |
| `extraEnv`                                               |                                                              | Liste de variables d'environnement supplémentaires à exposer |
| `extraEnvFrom`                                           |                                                              | Liste des variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| `gitaly.serviceName`                                     | `gitaly`                                                     | Nom du service Gitaly |
| `health_checks.port`                                     | `3808`                                                       | Port du serveur de vérification d'état |
| `health_checks.listenAddr`                               | `*`                                                          | Adresse d'écoute de la vérification d'état. |
| `hpa.behaviour`                                          | `{scaleDown: {stabilizationWindowSeconds: 300 }}`            | Behavior contient les spécifications pour le comportement de mise à l'échelle automatique ascendant et descendant (nécessite `autoscaling/v2beta2` ou version supérieure) |
| `hpa.customMetrics`                                      | `[]`                                                         | Les métriques personnalisées contiennent les spécifications à utiliser pour calculer le nombre de réplicas souhaité (remplace l'utilisation par défaut de la consommation CPU moyenne configurée dans `targetAverageUtilization`) |
| `hpa.cpu.targetType`                                     | `AverageValue`                                               | Définit le type cible du CPU pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.cpu.targetAverageValue`                             | `350m`                                                       | Définit la valeur cible CPU pour la mise à l'échelle automatique |
| `hpa.cpu.targetAverageUtilization`                       |                                                              | Définit la consommation cible CPU pour la mise à l'échelle automatique |
| `hpa.memory.targetType`                                  |                                                              | Définit le type cible de la mémoire pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.memory.targetAverageValue`                          |                                                              | Définit la valeur cible mémoire pour la mise à l'échelle automatique |
| `hpa.memory.targetAverageUtilization`                    |                                                              | Définit la consommation cible mémoire pour la mise à l'échelle automatique |
| `hpa.targetAverageValue`                                 |                                                              | **DEPRECATED** Définit la valeur cible CPU pour la mise à l'échelle automatique |
| `keda.enabled`                                           | `false`                                                      | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` à la place de `HorizontalPodAutoscalers` |
| `keda.pollingInterval`                                   | `30`                                                         | L'intervalle auquel vérifier chaque déclencheur |
| `keda.cooldownPeriod`                                    | `300`                                                        | La période d'attente après que le dernier déclencheur a signalé une activité avant de remettre la ressource à l'échelle à 0 |
| `keda.minReplicaCount`                                   |                                                              | Nombre minimum de réplicas vers lequel KEDA réduira la ressource, par défaut `minReplicas` |
| `keda.maxReplicaCount`                                   |                                                              | Nombre maximum de réplicas vers lequel KEDA augmentera la ressource, par défaut `maxReplicas` |
| `keda.fallback`                                          |                                                              | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `keda.hpaName`                                           |                                                              | Le nom de la ressource HPA que KEDA créera, par défaut `keda-hpa-{scaled-object-name}` |
| `keda.restoreToOriginalReplicaCount`                     |                                                              | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `keda.behavior`                                          |                                                              | Les spécifications pour le comportement de mise à l'échelle ascendante et descendante, par défaut `hpa.behavior` |
| `keda.triggers`                                          |                                                              | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |
| `minReplicas`                                            | `2`                                                          | Nombre minimum de réplicas |
| `maxReplicas`                                            | `10`                                                         | Nombre maximum de réplicas |
| `maxUnavailable`                                         | `1`                                                          | Limite du nombre maximum de pods pouvant être indisponibles |
| `image.pullPolicy`                                       | `Always`                                                     | Politique de téléchargement de l'image Sidekiq |
| `image.pullSecrets`                                      |                                                              | Secrets pour le dépôt d'images |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ee` | Dépôt d'images Sidekiq |
| `image.tag`                                              |                                                              | Tag d'image Sidekiq |
| `init.image.repository`                                  |                                                              | Image du conteneur init |
| `init.image.tag`                                         |                                                              | Tag d'image du conteneur init |
| `init.containerSecurityContext`                          |                                                              | Spécifique au conteneur init : [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                       | Spécifique au conteneur init :  ID utilisateur sous lequel le conteneur doit être démarré |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | Spécifique au conteneur init :  Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                       | Spécifique au conteneur init :  Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                  | Spécifique au conteneur init :  Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur |
| `logging.format`                                         | `json`                                                       | Définir sur `text` pour les journaux non-JSON |
| `metrics.enabled`                                        | `true`                                                       | Si un endpoint de métriques doit être rendu disponible pour le scraping |
| `metrics.port`                                           | `3807`                                                       | Port de l'endpoint de métriques |
| `metrics.listenAddr`                                     | `*`                                                          | Adresse d'écoute de l'endpoint de métriques. |
| `metrics.path`                                           | `/metrics`                                                   | Chemin de l'endpoint de métriques |
| `metrics.log_enabled`                                    | `false`                                                      | Active ou désactive les journaux du serveur de métriques écrits dans `sidekiq_exporter.log` |
| `metrics.podMonitor.enabled`                             | `false`                                                      | Si un PodMonitor doit être créé pour permettre à l'opérateur Prometheus de gérer le scraping des métriques |
| `metrics.podMonitor.additionalLabels`                    | `{}`                                                         | Labels supplémentaires à ajouter au PodMonitor |
| `metrics.podMonitor.endpointConfig`                      | `{}`                                                         | Configuration d'endpoint supplémentaire pour le PodMonitor |
| `metrics.annotations`                                    |                                                              | **DEPRECATED** Définir des annotations de métriques explicites. Remplacé par le contenu du modèle. |
| `metrics.tls.enabled`                                    | `false`                                                      | TLS activé pour l'endpoint `metrics/sidekiq_exporter` |
| `metrics.tls.secretName`                                 | `{Release.Name}-sidekiq-metrics-tls`                         | Secret pour le certificat et la clé TLS de l'endpoint `metrics/sidekiq_exporter` |
| `psql.password.key`                                      | `psql-password`                                              | Clé du mot de passe psql dans le secret psql |
| `psql.password.secret`                                   | `gitlab-postgres`                                            | Secret du mot de passe psql |
| `psql.port`                                              |                                                              | Définit le port du serveur PostgreSQL. A la priorité sur `global.psql.port` |
| `resources.requests.cpu`                                 | `900m`                                                       | CPU minimum requis pour Sidekiq |
| `resources.requests.memory`                              | `2G`                                                         | Mémoire minimum requise pour Sidekiq |
| `resources.limits.memory`                                |                                                              | Mémoire maximum autorisée pour Sidekiq |
| `timeout`                                                | `25`                                                         | Délai d'expiration du job Sidekiq |
| `tolerations`                                            | `[]`                                                         | Labels de tolérance pour l'affectation de pods |
| `memoryKiller.daemonMode`                                | `true`                                                       | Si `false`, utilise le mode hérité du memory killer |
| `memoryKiller.maxRss`                                    | `2000000`                                                    | RSS maximum avant le déclenchement de l'arrêt différé exprimé en kilo-octets |
| `memoryKiller.graceTime`                                 | `900`                                                        | Temps d'attente avant un arrêt déclenché exprimé en secondes |
| `memoryKiller.shutdownWait`                              | `30`                                                         | Durée après un arrêt déclenché pour que les jobs existants se terminent, exprimée en secondes |
| `memoryKiller.hardLimitRss`                              |                                                              | RSS maximum avant le déclenchement d'un arrêt immédiat exprimé en kilo-octets en mode daemon |
| `memoryKiller.checkInterval`                             | `3`                                                          | Durée entre les vérifications de mémoire |
| `livenessProbe.initialDelaySeconds`                      | `20`                                                         | Délai avant le lancement de la sonde de vivacité |
| `livenessProbe.periodSeconds`                            | `60`                                                         | Fréquence d'exécution de la sonde de vivacité |
| `livenessProbe.timeoutSeconds`                           | `30`                                                         | Délai d'expiration de la sonde de vivacité |
| `livenessProbe.successThreshold`                         | `1`                                                          | Nombre minimum de succès consécutifs pour que la sonde de vivacité soit considérée comme réussie après un échec |
| `livenessProbe.failureThreshold`                         | `3`                                                          | Nombre minimum d'échecs consécutifs pour que la sonde de vivacité soit considérée comme échouée après un succès |
| `readinessProbe.initialDelaySeconds`                     | `0`                                                          | Délai avant le lancement de la sonde de disponibilité |
| `readinessProbe.periodSeconds`                           | `10`                                                         | Fréquence d'exécution de la sonde de disponibilité |
| `readinessProbe.timeoutSeconds`                          | `2`                                                          | Délai d'expiration de la sonde de disponibilité |
| `readinessProbe.successThreshold`                        | `1`                                                          | Nombre minimum de succès consécutifs pour que la sonde de disponibilité soit considérée comme réussie après un échec |
| `readinessProbe.failureThreshold`                        | `3`                                                          | Nombre minimum d'échecs consécutifs pour que la sonde de disponibilité soit considérée comme échouée après un succès |
| `securityContext.fsGroup`                                | `1000`                                                       | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.runAsUser`                              | `1000`                                                       | ID utilisateur sous lequel le pod doit être démarré |
| `securityContext.fsGroupChangePolicy`                    |                                                              | Politique de modification de la propriété et des permissions du volume (nécessite Kubernetes 1.23) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                             | Profil Seccomp à utiliser |
| `containerSecurityContext`                               |                                                              | Remplace le [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel il est démarré |
| `containerSecurityContext.runAsUser`                     | `1000`                                                       | Permet de remplacer le contexte de sécurité spécifique sous lequel le conteneur est démarré |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                      | Contrôle si un processus du conteneur peut obtenir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                       | Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                  | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `serviceAccount.annotations`                             | `{}`                                                         | Annotations du ServiceAccount |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                      | Indique si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods |
| `serviceAccount.create`                                  | `false`                                                      | Indique si un ServiceAccount doit être créé |
| `serviceAccount.enabled`                                 | `false`                                                      | Indique si un ServiceAccount doit être utilisé |
| `serviceAccount.name`                                    |                                                              | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé |
| `priorityClassName`                                      | `""`                                                         | Permet de configurer `priorityClassName` des pods, utilisé pour contrôler la priorité des pods en cas d'éviction |
| `antiAffinity`                                           | `""`                                                         | Vous permet de remplacer les valeurs antiAffinity des valeurs globales du chart, la valeur par défaut est lue depuis les paramètres globaux et peut être définie sur `soft` ou `hard` |

## Exemples de configuration du chart {#chart-configuration-examples}

### resources {#resources}

`resources` vous permet de configurer la quantité minimale et maximale de ressources (mémoire et CPU) qu'un pod Sidekiq peut consommer.

Les charges de travail des pods Sidekiq varient considérablement selon les déploiements. En règle générale, on considère que chaque processus Sidekiq consomme environ 1 vCPU et 2 Go de mémoire. La mise à l'échelle verticale doit généralement s'aligner sur ce ratio `1:2` de `vCPU:Memory`.

Voici un exemple d'utilisation de `resources` :

```yaml
resources:
  limits:
    memory: 5G
  requests:
    memory: 2G
    cpu: 900m
```

### extraEnv {#extraenv}

Utilisez `extraEnv` pour exposer des variables d'environnement supplémentaires dans le conteneur des dépendances.

Par exemple, pour exposer les variables d'environnement `SOME_KEY` et `SOME_OTHER_KEY` :

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

Lorsque le conteneur est démarré, vérifiez que les variables d'environnement sont exposées en exécutant la commande `env` et en filtrant le nom des variables. Par exemple :

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

Vous pouvez également définir `extraEnv` pour un pod spécifique. Par exemple :

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
pods:
  - name: mailers
    queues: mailers
    extraEnv:
      SOME_POD_KEY: some_pod_value
  - name: catchall
```

Cela définira `SOME_POD_KEY` uniquement pour les conteneurs d'application dans le pod `mailers`. Les paramètres `extraEnv` au niveau du pod ne sont pas ajoutés aux [conteneurs init](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/).

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom` vous permet d'exposer des variables d'environnement supplémentaires provenant d'autres sources de données dans tous les conteneurs des pods. Les variables suivantes peuvent être remplacées par pod Sidekiq.

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
pods:
  - name: immediate
    extraEnvFrom:
      CONFIG_STRING:
        configMapKeyRef:
          name: useful-config
          key: some-string
          # optional: boolean
```

### extraVolumes {#extravolumes}

`extraVolumes` vous permet de configurer des volumes supplémentaires à l'échelle du chart.

Voici un exemple d'utilisation de `extraVolumes` :

```yaml
extraVolumes: |
  - name: example-volume
    persistentVolumeClaim:
      claimName: example-pvc
```

### extraVolumeMounts {#extravolumemounts}

`extraVolumeMounts` vous permet de configurer des montages de volumes supplémentaires sur tous les conteneurs à l'échelle du chart.

Voici un exemple d'utilisation de `extraVolumeMounts` :

```yaml
extraVolumeMounts: |
  - name: example-volume-mount
    mountPath: /etc/example
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets` vous permet de vous authentifier auprès d'un registre privé pour télécharger des images pour un pod.

Des détails supplémentaires sur les registres privés et leurs méthodes d'authentification sont disponibles dans [la documentation Kubernetes](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Voici un exemple d'utilisation de `pullSecrets` :

```yaml
image:
  repository: my.sidekiq.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

Cette section contrôle si un ServiceAccount doit être créé et si le jeton d'accès par défaut doit être monté dans les pods.

| Nom                           |  Type   | Défaut | Description |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   Map   | `{}`    | Annotations du ServiceAccount. |
| `automountServiceAccountToken` | Boolean | `false` | Contrôle si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods. Vous ne devez pas activer cette option sauf si elle est requise par certains sidecars pour fonctionner correctement (par exemple, Istio). |
| `create`                       | Boolean | `false` | Indique si un ServiceAccount doit être créé. |
| `enabled`                      | Boolean | `false` | Indique si un ServiceAccount doit être utilisé. |
| `name`                         | String  |         | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé. |

### tolerations {#tolerations}

`tolerations` vous permet de planifier des pods sur des nœuds worker avec des teintes

Voici un exemple d'utilisation de `tolerations` :

```yaml
tolerations:
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoExecute"
```

### annotations {#annotations}

`annotations` vous permet d'ajouter des annotations aux pods Sidekiq.

Voici un exemple d'utilisation de `annotations` :

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## Utilisation de la Community Edition de ce chart {#using-the-community-edition-of-this-chart}

Par défaut, les charts Helm utilisent l'édition Enterprise de GitLab. Si vous le souhaitez, vous pouvez utiliser la Community Edition à la place. En savoir plus sur les [différences entre les deux](https://about.gitlab.com/install/ce-or-ee/).

Pour utiliser la Community Edition, définissez `image.repository` sur `registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ce`.

## Services externes {#external-services}

Ce chart doit être connecté aux mêmes instances Redis, PostgreSQL et Gitaly que le chart Webservice. Les valeurs des services externes seront renseignées dans un `ConfigMap` partagé entre tous les pods Sidekiq.

### Redis {#redis}

```yaml
redis:
  host: rank-racoon-redis
  port: 6379
  sentinels:
    - host: sentinel1.example.com
      port: 26379
      ssl: false
  password:
    secret: gitlab-redis
    key: redis-password
```

| Nom                |  Type   | Défaut | Description |
|:--------------------|:-------:|:--------|:------------|
| `host`              | String  |         | Le nom d'hôte du serveur Redis avec la base de données à utiliser. Si vous utilisez des sentinelles Redis, l'attribut `host` doit être défini sur le nom du cluster tel que spécifié dans le fichier `sentinel.conf`. |
| `password.key`      | String  |         | L'attribut `password.key` pour Redis définit le nom de la clé dans le secret (ci-dessous) qui contient le mot de passe. |
| `password.secret`   | String  |         | L'attribut `password.secret` pour Redis définit le nom du `Secret` Kubernetes à partir duquel extraire les données. |
| `port`              | Integer | `6379`  | Le port sur lequel se connecter au serveur Redis. |
| `sentinels.[].host` | String  |         | Le nom d'hôte du serveur Redis Sentinel pour une configuration Redis HA. |
| `sentinels.[].port` | Integer | `26379` | Le port sur lequel se connecter au serveur Redis Sentinel. |

### PostgreSQL {#postgresql}

```yaml
psql:
  host: rank-racoon-psql
  port: 5432
  database: gitlabhq_production
  username: gitlab
  preparedStatements: false
  password:
    secret: gitlab-postgres
    key: psql-password
```

| Nom                 |  Type   | Défaut               | Description |
|:---------------------|:-------:|:----------------------|:------------|
| `host`               | String  |                       | Le nom d'hôte du serveur PostgreSQL avec la base de données à utiliser. |
| `database`           | String  | `gitlabhq_production` | Le nom de la base de données à utiliser sur le serveur PostgreSQL. |
| `password.key`       | String  |                       | L'attribut `password.key` pour PostgreSQL définit le nom de la clé dans le secret (ci-dessous) qui contient le mot de passe. |
| `password.secret`    | String  |                       | L'attribut `password.secret` pour PostgreSQL définit le nom du `Secret` Kubernetes à partir duquel extraire les données. |
| `port`               | Integer | `5432`                | Le port sur lequel se connecter au serveur PostgreSQL. |
| `username`           | String  | `gitlab`              | Le nom d'utilisateur avec lequel s'authentifier à la base de données. |
| `preparedStatements` | Boolean | `false`               | Si les instructions préparées doivent être utilisées lors des communications avec le serveur PostgreSQL. |

Le `dependencies` `initContainer` dans le déploiement Sidekiq exécute des scripts pour vérifier :

- Si les dépendances de GitLab sont disponibles.
- Si les migrations de base de données pour PostgreSQL ont été exécutées.

Vous pouvez utiliser la clé de configuration `extraEnv` du chart Sidekiq pour contrôler le comportement de ces scripts. Deux variables d'environnement sont prises en charge :

- `BYPASS_POST_DEPLOYMENT=true` :  La vérification des dépendances réussit si toutes les migrations régulières ont été exécutées et que seules les migrations post-déploiement sont en attente
- `BYPASS_SCHEMA_VERSION=true` (non recommandé) :  La vérification des dépendances réussit même si les migrations régulières n'ont pas été exécutées. L'utilisation de cette variable d'environnement peut entraîner des erreurs dans le déploiement Rails après le démarrage, car le schéma de base de données ne correspond pas aux attentes du code de l'application.

### Gitaly {#gitaly}

```yaml
gitaly:
  internal:
    names:
      - default
      - default2
  external:
    - name: node1
      hostname: node1.example.com
      port: 8079
  authToken:
    secret: gitaly-secret
    key: token
```

| Nom               |  Type   | Défaut  | Description |
|:-------------------|:-------:|:---------|:------------|
| `host`             | String  |          | Le nom d'hôte du serveur Gitaly à utiliser. Cela peut être omis au profit de `serviceName`. |
| `serviceName`      | String  | `gitaly` | Le nom du `service` qui gère le serveur Gitaly. Si cet attribut est présent et que `host` ne l'est pas, le chart créera le modèle du nom d'hôte du service (et du `.Release.Name` actuel) à la place de la valeur `host`. Cela est pratique lors de l'utilisation de Gitaly dans le cadre du chart GitLab global. |
| `port`             | Integer | `8075`   | Le port sur lequel se connecter au serveur Gitaly. |
| `authToken.key`    | String  |          | Le nom de la clé dans le secret ci-dessous qui contient le jeton d'authentification. |
| `authToken.secret` | String  |          | Le nom du `Secret` Kubernetes à partir duquel extraire les données. |

## Métriques {#metrics}

Par défaut, un exportateur de métriques Prometheus est activé par pod. Les métriques ne sont disponibles que lorsque les [métriques GitLab Prometheus](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/) sont activées dans la zone d'administration. L'exportateur expose un endpoint `/metrics` sur le port `3807`. Lorsque les métriques sont activées, des annotations sont ajoutées à chaque pod permettant à un serveur Prometheus de découvrir et de scraper les métriques exposées.

## Paramètres par défaut à l'échelle du chart {#chart-wide-defaults}

Les valeurs suivantes seront utilisées à l'échelle du chart, dans le cas où une valeur n'est pas fournie par pod.

| Nom                         |  Type   | Défaut   | Description |
|:-----------------------------|:-------:|:----------|:------------|
| `concurrency`                | Integer | `25`      | Le nombre de tâches à traiter simultanément. |
| `timeout`                    | Integer | `4`       | Le délai d'arrêt de Sidekiq. Le nombre de secondes après lesquelles Sidekiq reçoit le signal TERM avant de forcer l'arrêt de ses processus. |
| `memoryKiller.checkInterval` | Integer | `3`       | Durée en secondes entre les vérifications de mémoire |
| `memoryKiller.maxRss`        | Integer | `2000000` | RSS maximum avant le déclenchement de l'arrêt différé exprimé en kilo-octets |
| `memoryKiller.graceTime`     | Integer | `900`     | Temps d'attente avant un arrêt déclenché exprimé en secondes |
| `memoryKiller.shutdownWait`  | Integer | `30`      | Durée après un arrêt déclenché pour que les jobs existants se terminent, exprimée en secondes |
| `minReplicas`                | Integer | `2`       | Nombre minimum de réplicas |
| `maxReplicas`                | Integer | `10`      | Nombre maximum de réplicas |
| `maxUnavailable`             | Integer | `1`       | Limite du nombre maximum de pods pouvant être indisponibles |

> [!note] [La documentation détaillée du memory killer Sidekiq est disponible](https://docs.gitlab.com/administration/sidekiq/sidekiq_memory_killer/) dans la documentation du package Linux.

## Désactiver la mise à l'échelle HPA {#disable-hpa-scaling}

Par défaut, le chart Sidekiq active la mise à l'échelle automatique horizontale des pods (HPA) pour mettre à l'échelle automatiquement les pods en fonction de l'utilisation du CPU. Pour désactiver la mise à l'échelle HPA et utiliser des nombres de réplicas fixes à la place, définissez `minReplicas` égal à `maxReplicas` au niveau du chart pour désactiver HPA pour tous les pods :

```yaml
gitlab:
  sidekiq:
    minReplicas: 3
    maxReplicas: 3  # Setting equal to minReplicas disables HPA scaling
    concurrency: 25
    pods:
      - name: default
```

## Paramètres par pod {#per-pod-settings}

La déclaration `pods` permet de déclarer tous les attributs d'un pod worker. Ceux-ci seront modélisés en `Deployment`s, avec des `ConfigMap`s individuels pour leurs instances Sidekiq.

[!note]
> Les paramètres sont configurés par défaut pour inclure un seul pod configuré pour surveiller toutes les files d'attente. Toute modification apportée à la section pods *remplacera le pod par défaut* par une configuration de pod différente. Cela n'ajoutera pas un nouveau pod en plus du pod par défaut.

| Nom                                  |  Type   | Défaut        | Description |
|:--------------------------------------|:-------:|:---------------|:------------|
| `concurrency`                         | Integer |                | Le nombre de tâches à traiter simultanément. Si non fourni, la valeur par défaut à l'échelle du chart sera utilisée. |
| `name`                                | String  |                | Utilisé pour nommer le `Deployment` et le `ConfigMap` pour ce pod. Il doit rester court et ne doit pas être dupliqué entre deux entrées. |
| `queues`                              | String  |                | [Voir ci-dessous](#queues). |
| `timeout`                             | Integer |                | Le délai d'arrêt de Sidekiq. Le nombre de secondes après lesquelles Sidekiq reçoit le signal TERM avant de forcer l'arrêt de ses processus. Si non fourni, la valeur par défaut à l'échelle du chart sera utilisée. Cette valeur **must** être inférieure à `terminationGracePeriodSeconds`. |
| `resources`                           |         |                | Chaque pod peut présenter ses propres exigences en matière de `resources`, qui seront ajoutées au `Deployment` créé pour lui, si elles sont présentes. Celles-ci correspondent à la documentation Kubernetes. |
| `nodeSelector`                        |         |                | Chaque pod peut être configuré avec un attribut `nodeSelector`, qui sera ajouté au `Deployment` créé pour lui, si présent. Ces définitions correspondent à la documentation Kubernetes. |
| `memoryKiller.checkInterval`          | Integer | `3`            | Durée entre les vérifications de mémoire |
| `memoryKiller.maxRss`                 | Integer | `2000000`      | Remplace le RSS maximum pour un pod donné. |
| `memoryKiller.graceTime`              | Integer | `900`          | Remplace le temps d'attente avant un arrêt déclenché pour un pod donné |
| `memoryKiller.shutdownWait`           | Integer | `30`           | Remplace la durée après un arrêt déclenché pour que les jobs existants se terminent pour un pod donné |
| `minReplicas`                         | Integer | `2`            | Nombre minimum de réplicas |
| `maxReplicas`                         | Integer | `10`           | Nombre maximum de réplicas |
| `maxUnavailable`                      | Integer | `1`            | Limite du nombre maximum de pods pouvant être indisponibles |
| `podLabels`                           |   Map   | `{}`           | Labels de pod supplémentaires. Ne sera pas utilisé pour les sélecteurs. |
| `strategy`                            |         | `{}`           | Permet de configurer la stratégie de mise à jour utilisée par le déploiement |
| `extraVolumes`                        | String  |                | Configure des volumes supplémentaires pour le pod donné. |
| `extraVolumeMounts`                   | String  |                | Configure des montages de volumes supplémentaires pour le pod donné. |
| `priorityClassName`                   | String  | `""`           | Permet de configurer `priorityClassName` des pods, utilisé pour contrôler la priorité des pods en cas d'éviction |
| `hpa.customMetrics`                   |  Tableau  | `[]`           | Les métriques personnalisées contiennent les spécifications à utiliser pour calculer le nombre de réplicas souhaité (remplace l'utilisation par défaut de la consommation CPU moyenne configurée dans `targetAverageUtilization`) |
| `hpa.cpu.targetType`                  | String  | `AverageValue` | Remplace le type cible du CPU pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.cpu.targetAverageValue`          | String  | `350m`         | Remplace la valeur cible CPU pour la mise à l'échelle automatique |
| `hpa.cpu.targetAverageUtilization`    | Integer |                | Remplace l'utilisation cible CPU pour la mise à l'échelle automatique |
| `hpa.memory.targetType`               | String  |                | Remplace le type cible de la mémoire pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.memory.targetAverageValue`       | String  |                | Remplace la valeur cible mémoire pour la mise à l'échelle automatique |
| `hpa.memory.targetAverageUtilization` | Integer |                | Remplace l'utilisation cible mémoire pour la mise à l'échelle automatique |
| `hpa.targetAverageValue`              | String  |                | **DEPRECATED** Remplace la valeur cible CPU pour la mise à l'échelle automatique |
| `keda.enabled`                        | Boolean | `false`        | Remplace l'activation de KEDA |
| `keda.pollingInterval`                | Integer | `30`           | Remplace l'intervalle d'interrogation de KEDA |
| `keda.cooldownPeriod`                 | Integer | `300`          | Remplace la période de refroidissement de KEDA |
| `keda.minReplicaCount`                | Integer |                | Remplace le nombre minimum de réplicas KEDA |
| `keda.maxReplicaCount`                | Integer |                | Remplace le nombre maximum de réplicas KEDA |
| `keda.fallback`                       |   Map   |                | Remplace la configuration de secours KEDA |
| `keda.hpaName`                        | String  |                | Remplace le nom HPA de KEDA |
| `keda.restoreToOriginalReplicaCount`  | Boolean |                | Remplace l'activation de la restauration du nombre de réplicas d'origine |
| `keda.behavior`                       |   Map   |                | Remplace le comportement HPA de KEDA |
| `keda.triggers`                       |  Tableau  |                | Remplace les déclencheurs KEDA |
| `extraEnv`                            |   Map   |                | Liste des variables d'environnement supplémentaires à exposer. La valeur à l'échelle du chart est fusionnée dans celle-ci, avec les valeurs du pod ayant la priorité |
| `extraEnvFrom`                        |   Map   |                | Liste de variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| `terminationGracePeriodSeconds`       | Integer | `30`           | Durée facultative en secondes dont le pod a besoin pour se terminer correctement. |

### queues {#queues}

La valeur `queues` est une chaîne contenant une liste de files d'attente à traiter, séparées par des virgules. Par défaut, elle n'est pas définie, ce qui signifie que toutes les files d'attente seront traitées.

La chaîne ne doit pas contenir d'espaces : `merge,post_receive,process_commit` fonctionnera, mais `merge, post_receive, process_commit` ne fonctionnera pas.

Toute file d'attente à laquelle des jobs sont ajoutés mais qui n'est pas représentée dans au moins un élément de pod *ne sera pas traitée*. Pour obtenir une liste complète de toutes les files d'attente, consultez ces fichiers dans le code source de GitLab :

1. [`app/workers/all_queues.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/workers/all_queues.yml)
1. [`ee/app/workers/all_queues.yml`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/ee/app/workers/all_queues.yml)

En plus de configurer `gitlab.sidekiq.pods[].queues`, vous devez également configurer `global.appConfig.sidekiq.routingRules`. Pour plus d'informations, consultez [les paramètres des règles de routage Sidekiq](../../globals.md#sidekiq-routing-rules-settings).

### Exemple d'entrée `pod` {#example-pod-entry}

```yaml
pods:
  - name: immediate
    concurrency: 10
    minReplicas: 2  # defaults to inherited value
    maxReplicas: 10 # defaults to inherited value
    maxUnavailable: 5 # defaults to inherited value
    queues: merge,post_receive,process_commit
    extraVolumeMounts: |
      - name: example-volume-mount
        mountPath: /etc/example
    extraVolumes: |
      - name: example-volume
        persistentVolumeClaim:
          claimName: example-pvc
    resources:
      limits:
        cpu: 800m
        memory: 2Gi
    hpa:
      cpu:
        targetType: Value
        targetAverageValue: 350m
```

### Exemple complet de configuration Sidekiq {#full-example-of-sidekiq-configuration}

Voici un exemple complet de configuration Sidekiq utilisant un pod Sidekiq séparé pour les jobs liés à l'import, un pod Sidekiq pour les jobs liés à l'export utilisant une instance Redis séparée et un autre pod pour tout le reste.

```yaml
...
global:
  appConfig:
    sidekiq:
      routingRules:
      - ["feature_category=importers", "import"]
      - ["feature_category=exporters", "export", "queues_shard_extra_shard"]
      - ["*", "default"]
  redis:
    redisYmlOverride:
      queues_shard_extra_shard: ...
...
gitlab:
  sidekiq:
    pods:
    - name: import
      queues: import
    - name: export
      queues: export
      extraEnv:
        SIDEKIQ_SHARD_NAME: queues_shard_extra_shard # to match key in global.redis.redisYmlOverride
    - name: default
...
```

## Configuration de `networkpolicy` {#configuring-the-networkpolicy}

Cette section contrôle la [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). Cette configuration est facultative et est utilisée pour limiter l'Egress et l'Ingress des pods à des endpoints spécifiques.

| Nom              |  Type   | Défaut | Description |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | Boolean | `false` | Ce paramètre active la politique réseau |
| `ingress.enabled` | Boolean | `false` | Lorsque défini sur `true`, la politique réseau `Ingress` sera activée. Cela bloquera toutes les connexions Ingress sauf si des règles sont spécifiées. |
| `ingress.rules`   |  Tableau  | `[]`    | Règles pour la politique Ingress, pour plus de détails voir <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> et l'exemple ci-dessous |
| `egress.enabled`  | Boolean | `false` | Lorsque défini sur `true`, la politique réseau `Egress` sera activée. Cela bloquera toutes les connexions egress sauf si des règles sont spécifiées. |
| `egress.rules`    |  Tableau  | `[]`    | Règles pour la politique egress, pour plus de détails voir <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> et l'exemple ci-dessous |

### Exemple de politique réseau {#example-network-policy}

Le service Sidekiq nécessite des connexions Ingress uniquement pour l'exportateur Prometheus si activé, et nécessite normalement des connexions Egress vers divers endroits. Cet exemple ajoute la politique réseau suivante :

- Autorise les requêtes Ingress :
  - Du pod `Prometheus` vers le port `3807`
- Autorise les requêtes Egress :
  - Vers `kube-dns` sur le port `53`
  - Vers le pod `gitaly` sur le port `8075`
  - Vers le pod `registry` sur le port `5000`
  - Vers le pod `kas` sur le port `8153`
  - Vers la base de données externe `172.16.0.10/32` sur le port `5432`
  - Vers Redis externe `172.16.0.11/32` sur le port `6379`
  - Vers Elasticsearch externe `172.16.0.12/32` sur le port `443`
  - Vers la passerelle de messagerie `172.16.0.13/32` sur le port `587`
  - Vers les endpoints tels que AWS VPC endpoint pour S3 ou STS `172.16.1.0/24` sur le port `443`
  - Vers les sous-réseaux internes `172.16.2.0/24` sur le port `443` pour envoyer des webhooks

L'exemple fourni n'est qu'un exemple et peut ne pas être complet. Le service Sidekiq nécessite une connectivité sortante vers l'internet public pour les images sur le [stockage d'objets externe](../../../advanced/external-object-storage) si aucun endpoint local n'est disponible. L'exemple est basé sur l'hypothèse que `kube-dns` a été déployé dans l'espace de nommage `kube-system`, `prometheus` a été déployé dans l'espace de nommage `monitoring` et `nginx-ingress` a été déployé dans l'espace de nommage `nginx-ingress`.

```yaml
networkpolicy:
  enabled: true
  ingress:
    enabled: true
    rules:
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: monitoring
            podSelector:
              matchLabels:
                app: prometheus
                component: server
                release: gitlab
        ports:
          - port: 3807
  egress:
    enabled: true
    rules:
      - to:
          - podSelector:
              matchLabels:
                app: gitaly
        ports:
          - port: 8075
      - to:
          - podSelector:
              matchLabels:
                app: kas
        ports:
          - port: 8153
      - to:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: kube-system
            podSelector:
              matchLabels:
                k8s-app: kube-dns
        ports:
          - port: 53
            protocol: UDP
      - to:
          - ipBlock:
              cidr: 172.16.0.10/32
        ports:
          - port: 5432
      - to:
          - ipBlock:
              cidr: 172.16.0.11/32
        ports:
          - port: 6379
      - to:
          - ipBlock:
              cidr: 172.16.0.12/32
        ports:
          - port: 25
      - to:
          - ipBlock:
              cidr: 172.16.0.13/32
        ports:
          - port: 443
      - to:
          - ipBlock:
              cidr: 172.16.1.0/24
        ports:
          - port: 443
      - to:
          - ipBlock:
              cidr: 172.16.2.0/24
        ports:
          - port: 443
```

## Configuration de KEDA {#configuring-keda}

Cette section `keda` active l'installation de [KEDA](https://keda.sh/) `ScaledObjects` à la place des `HorizontalPodAutoscalers` classiques. Cette configuration est facultative et peut être utilisée lorsqu'il est nécessaire d'effectuer une mise à l'échelle automatique basée sur des métriques personnalisées ou externes.

La plupart des paramètres utilisent par défaut les valeurs définies dans la section `hpa` le cas échéant.

Si les conditions suivantes sont remplies, des déclencheurs CPU et mémoire sont ajoutés automatiquement en fonction des seuils CPU et mémoire définis dans la section `hpa` :

- `triggers` n'est pas défini.
- Le paramètre `request.cpu.request` ou `request.memory.request` correspondant est également défini sur une valeur non nulle.

Si aucun déclencheur n'est défini, le `ScaledObject` n'est pas créé.

Consultez la [documentation KEDA](https://keda.sh/docs/2.10/concepts/scaling-deployments/) pour plus de détails sur ces paramètres.

| Nom                            |  Type   | Défaut | Description |
|:--------------------------------|:-------:|:--------|:------------|
| `enabled`                       | Boolean | `false` | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` à la place de `HorizontalPodAutoscalers` |
| `pollingInterval`               | Integer | `30`    | L'intervalle auquel vérifier chaque déclencheur |
| `cooldownPeriod`                | Integer | `300`   | La période d'attente après que le dernier déclencheur a signalé une activité avant de remettre la ressource à l'échelle à 0 |
| `minReplicaCount`               | Integer |         | Nombre minimum de réplicas vers lequel KEDA réduira la ressource, par défaut `minReplicas` |
| `maxReplicaCount`               | Integer |         | Nombre maximum de réplicas vers lequel KEDA augmentera la ressource, par défaut `maxReplicas` |
| `fallback`                      |   Map   |         | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `hpaName`                       | String  |         | Le nom de la ressource HPA que KEDA créera, par défaut `keda-hpa-{scaled-object-name}` |
| `restoreToOriginalReplicaCount` | Boolean |         | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `behavior`                      |   Map   |         | Les spécifications pour le comportement de mise à l'échelle ascendante et descendante, par défaut `hpa.behavior` |
| `triggers`                      |  Tableau  |         | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |
