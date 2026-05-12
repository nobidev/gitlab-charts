---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du chart GitLab-Gitaly
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le sous-chart `gitaly` fournit un déploiement configurable de serveurs Gitaly.

## Prérequis {#requirements}

Ce chart dépend de l'accès au service Workhorse, soit dans le cadre du chart GitLab complet, soit fourni en tant que service externe accessible depuis le cluster Kubernetes sur lequel ce chart est déployé.

## Choix de conception {#design-choices}

Le conteneur Gitaly utilisé dans ce chart contient également la base de code GitLab Shell afin d'effectuer les actions sur les dépôts Git qui n'ont pas encore été portées dans Gitaly. Le conteneur Gitaly inclut une copie du conteneur GitLab Shell, et par conséquent nous devons également configurer GitLab Shell dans ce chart.

## Configuration {#configuration}

Le chart `gitaly` est configuré en deux parties : [services externes](#external-services) et [paramètres du chart](#chart-settings).

Gitaly est par défaut déployé en tant que composant lors du déploiement du chart GitLab. Si vous déployez Gitaly séparément, `global.gitaly.enabled` doit être défini sur `false` et une configuration supplémentaire devra être effectuée comme décrit dans la [documentation Gitaly externe](../../../advanced/external-gitaly/_index.md).

### Options de ligne de commande d'installation {#installation-command-line-options}

Le tableau ci-dessous contient toutes les configurations de charts possibles qui peuvent être fournies à la commande `helm install` via les flags `--set`.

| Paramètre                                                | Défaut                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `annotations`                                            |                                                         | Annotations de pod |
| `backup.goCloudUrl`                                      |                                                         | URL de stockage d'objets pour les [sauvegardes Gitaly côté serveur](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups). |
| `common.labels`                                          | `{}`                                                    | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `podLabels`                                              |                                                         | Labels de pod supplémentaires. Ne sera pas utilisé pour les sélecteurs. |
| `external[].hostname`                                    | `- ""`                                                  | nom d'hôte du nœud externe |
| `external[].name`                                        | `- ""`                                                  | nom du stockage du nœud externe |
| `external[].port`                                        | `- ""`                                                  | port du nœud externe |
| `extraContainers`                                        |                                                         | Chaîne de style littéral multiligne contenant une liste de conteneurs à inclure |
| `extraInitContainers`                                    |                                                         | Liste de conteneurs init supplémentaires à inclure |
| `extraVolumeMounts`                                      |                                                         | Liste de montages de volumes supplémentaires à effectuer |
| `extraVolumes`                                           |                                                         | Liste de volumes supplémentaires à créer |
| `extraEnv`                                               |                                                         | Liste de variables d'environnement supplémentaires à exposer |
| `extraEnvFrom`                                           |                                                         | Liste de variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| `gitaly.serviceName`                                     |                                                         | Le nom du service Gitaly généré. Remplace `global.gitaly.serviceName` et prend par défaut la valeur `<RELEASE-NAME>-gitaly` |
| `gpgSigning.enabled`                                     | `false`                                                 | Indique si la [signature GPG Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits) doit être utilisée. |
| `gpgSigning.secret`                                      |                                                         | Le nom du secret utilisé pour la signature GPG Gitaly. |
| `gpgSigning.key`                                         |                                                         | La clé dans le secret GPG contenant la clé de signature GPG de Gitaly. |
| `image.pullPolicy`                                       | `Always`                                                | Politique de récupération des images Gitaly |
| `image.pullSecrets`                                      |                                                         | Secrets pour le dépôt d'images |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitaly`       | Dépôt d'images Gitaly |
| `image.tag`                                              | `master`                                                | Tag d'image Gitaly |
| `init.image.repository`                                  |                                                         | Image initContainer |
| `init.image.tag`                                         |                                                         | Tag d'image initContainer |
| `init.containerSecurityContext`                          |                                                         | Spécifique à initContainer : [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                 | Spécifique à initContainer :  Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                  | Spécifique à initContainer :  Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                             | Spécifique à initContainer :  Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur |
| `internal.names[]`                                       | `- default`                                             | Noms ordonnés des stockages StatefulSet |
| `serviceLabels`                                          | `{}`                                                    | Labels de service supplémentaires |
| `service.externalPort`                                   | `8075`                                                  | Port exposé du service Gitaly |
| `service.internalPort`                                   | `8075`                                                  | Port interne Gitaly |
| `service.name`                                           | `gitaly`                                                | Le nom du port de service derrière lequel se trouve Gitaly dans l'objet Service. |
| `service.type`                                           | `ClusterIP`                                             | Type de service Gitaly |
| `service.clusterIP`                                      | `None`                                                  | Vous pouvez spécifier votre propre adresse IP de cluster dans le cadre d'une demande de création de service. Cela suit les mêmes conventions que le clusterIP de l'objet Service de Kubernetes. Ceci ne doit pas être défini si `service.type` est LoadBalancer. |
| `service.loadBalancerIP`                                 |                                                         | Une adresse IP éphémère sera créée si elle n'est pas définie. Cela suit les mêmes conventions que la configuration loadbalancerIP de l'objet Service de Kubernetes. |
| `serviceAccount.annotations`                             | `{}`                                                    | Annotations ServiceAccount |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                 | Indique si le token d'accès ServiceAccount par défaut doit être monté dans les pods |
| `serviceAccount.create`                                  | `false`                                                 | Indique si un ServiceAccount doit être créé |
| `serviceAccount.enabled`                                 | `false`                                                 | Indique si un ServiceAccount doit être utilisé |
| `serviceAccount.name`                                    |                                                         | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé |
| `securityContext.fsGroup`                                | `1000`                                                  | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.fsGroupChangePolicy`                    |                                                         | Politique de changement de propriété et d'autorisation du volume (nécessite Kubernetes 1.23) |
| `securityContext.runAsUser`                              | `1000`                                                  | ID utilisateur sous lequel le pod doit être démarré |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                        | Profil Seccomp à utiliser |
| `shareProcessNamespace`                                  | `false`                                                 | Permet de rendre les processus du conteneur visibles pour tous les autres conteneurs du même pod |
| `containerSecurityContext`                               |                                                         | Remplace le [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel le conteneur Gitaly est démarré |
| `containerSecurityContext.runAsUser`                     | `1000`                                                  | Permet de remplacer l'ID utilisateur du contexte de sécurité spécifique sous lequel le conteneur Gitaly est démarré |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                 | Contrôle si un processus du conteneur Gitaly peut obtenir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                  | Contrôle si le conteneur Gitaly s'exécute avec un utilisateur non root |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                             | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `tolerations`                                            | `[]`                                                    | Labels de tolérance pour l'affectation des pods |
| `affinity`                                               | `{}`                                                    | [Règles d'affinité](../_index.md#affinity) pour l'affectation des pods |
| `persistence.accessMode`                                 | `ReadWriteOnce`                                         | Mode d'accès de persistance Gitaly |
| `persistence.annotations`                                |                                                         | Annotations de persistance Gitaly |
| `persistence.enabled`                                    | `true`                                                  | Indicateur d'activation de la persistance Gitaly |
| `persistance.labels`                                     |                                                         | Labels de persistance Gitaly |
| `persistence.matchExpressions`                           |                                                         | Correspondances d'expressions de labels à lier |
| `persistence.matchLabels`                                |                                                         | Correspondances de valeurs de labels à lier |
| `persistence.size`                                       | `50Gi`                                                  | Taille du volume de persistance Gitaly |
| `persistence.storageClass`                               |                                                         | storageClassName pour le provisionnement |
| `persistence.subPath`                                    |                                                         | Chemin de montage du volume de persistance Gitaly |
| `priorityClassName`                                      |                                                         | priorityClassName du StatefulSet Gitaly |
| `logging.level`                                          |                                                         | Niveau de log   |
| `logging.format`                                         | `json`                                                  | Format de log  |
| `logging.sentryDsn`                                      |                                                         | URL DSN Sentry - Exceptions du serveur Go |
| `logging.sentryEnvironment`                              |                                                         | Environnement Sentry à utiliser pour la journalisation |
| `shell.concurrency[]`                                    |                                                         | Simultanéité de chaque point de terminaison RPC. Voir [Limiter la simultanéité RPC](https://docs.gitlab.com/administration/gitaly/concurrency_limiting/#limit-rpc-concurrency) et [Activer l'adaptabilité pour la simultanéité RPC](https://docs.gitlab.com/administration/gitaly/concurrency_limiting/#enable-adaptiveness-for-rpc-concurrency) pour les clés de configuration. |
| `packObjectsCache.enabled`                               | `false`                                                 | Activer le cache pack-objects de Gitaly |
| `packObjectsCache.dir`                                   | `/home/git/repositories/+gitaly/PackObjectsCache`       | Répertoire où les fichiers de cache sont stockés |
| `packObjectsCache.max_age`                               | `5m`                                                    | Durée de vie des entrées du cache |
| `packObjectsCache.min_occurrences`                       | `1`                                                     | Nombre minimum requis pour créer une entrée de cache |
| `git.catFileCacheSize`                                   |                                                         | Taille du cache utilisée par le processus Git cat-file |
| `git.config[]`                                           | `[]`                                                    | Configuration Git que Gitaly doit définir lors du lancement de commandes Git |
| `prometheus.grpcLatencyBuckets`                          |                                                         | Buckets correspondant aux latences d'histogramme sur les appels de méthode GRPC à enregistrer par Gitaly. Une forme de chaîne du tableau (par exemple, `"[1.0, 1.5, 2.0]"`) est requise en entrée |
| `statefulset.strategy`                                   | `{}`                                                    | Permet de configurer la stratégie de mise à jour utilisée par le StatefulSet |
| `statefulset.livenessProbe.initialDelaySeconds`          | `0`                                                     | Délai avant que la sonde de vivacité soit initiée. Si startupProbe est activé, cette valeur sera définie sur 0. |
| `statefulset.livenessProbe.periodSeconds`                | `10`                                                    | Fréquence d'exécution de la sonde de vivacité |
| `statefulset.livenessProbe.timeoutSeconds`               | `3`                                                     | Délai d'expiration de la sonde de vivacité |
| `statefulset.livenessProbe.successThreshold`             | `1`                                                     | Nombre minimum de succès consécutifs pour que la sonde de vivacité soit considérée comme réussie après un échec |
| `statefulset.livenessProbe.failureThreshold`             | `3`                                                     | Nombre minimum d'échecs consécutifs pour que la sonde de vivacité soit considérée comme échouée après un succès |
| `statefulset.readinessProbe.initialDelaySeconds`         | `0`                                                     | Délai avant que la sonde de disponibilité soit initiée. Si startupProbe est activé, cette valeur sera définie sur 0. |
| `statefulset.readinessProbe.periodSeconds`               | `5`                                                     | Fréquence d'exécution de la sonde de disponibilité |
| `statefulset.readinessProbe.timeoutSeconds`              | `3`                                                     | Délai d'expiration de la sonde de disponibilité |
| `statefulset.readinessProbe.successThreshold`            | `1`                                                     | Nombre minimum de succès consécutifs pour que la sonde de disponibilité soit considérée comme réussie après un échec |
| `statefulset.readinessProbe.failureThreshold`            | `3`                                                     | Nombre minimum d'échecs consécutifs pour que la sonde de disponibilité soit considérée comme échouée après un succès |
| `statefulset.startupProbe.enabled`                       | `true`                                                  | Indique si une sonde de démarrage est activée. |
| `statefulset.startupProbe.initialDelaySeconds`           | `1`                                                     | Délai avant que la sonde de démarrage soit initiée |
| `statefulset.startupProbe.periodSeconds`                 | `1`                                                     | Fréquence d'exécution de la sonde de démarrage |
| `statefulset.startupProbe.timeoutSeconds`                | `1`                                                     | Quand la sonde de démarrage expire |
| `statefulset.startupProbe.successThreshold`              | `1`                                                     | Nombre minimum de succès consécutifs pour que la sonde de démarrage soit considérée comme réussie après avoir échoué |
| `statefulset.startupProbe.failureThreshold`              | `60`                                                    | Nombre minimum d'échecs consécutifs pour que la sonde de démarrage soit considérée comme ayant échoué après avoir réussi |
| `metrics.enabled`                                        | `false`                                                 | Indique si un point de terminaison de métriques doit être disponible pour la collecte |
| `metrics.port`                                           | `9236`                                                  | Port du point de terminaison de métriques |
| `metrics.path`                                           | `/metrics`                                              | Chemin du point de terminaison de métriques |
| `metrics.serviceMonitor.enabled`                         | `false`                                                 | Indique si un ServiceMonitor doit être créé pour permettre à l'opérateur Prometheus de gérer la collecte de métriques ; notez que son activation supprime les annotations de collecte `prometheus.io` |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                    | Labels supplémentaires à ajouter au ServiceMonitor |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                    | Configuration de point de terminaison supplémentaire pour le ServiceMonitor |
| `metrics.metricsPort`                                    |                                                         | **DEPRECATED** Utilisez `metrics.port` |
| `gomemlimit.enabled`                                     | `true`                                                  | Cela définira automatiquement la variable d'environnement `GOMEMLIMIT` pour le conteneur Gitaly sur `resources.limits.memory`, si cette limite est également définie. Les utilisateurs peuvent remplacer cette valeur en définissant cette valeur sur false et en définissant `GOMEMLIMIT` dans `extraEnv`. Cela doit répondre aux [critères de format documentés](https://pkg.go.dev/runtime#hdr-Environment_Variables). |
| `cgroups.enabled`                                        | `false`                                                 | Gitaly dispose d'un contrôle des cgroups intégré. Lorsqu'il est configuré, Gitaly affecte les processus Git à un cgroup en fonction du dépôt sur lequel la commande Git opère. Ce paramètre activera les cgroups de dépôt. Notez que seuls les cgroups v2 seront pris en charge s'ils sont activés. |
| `cgroups.initContainer.image.repository`                 | `registry.com/gitlab-org/build/cng/gitaly-init-cgroups` | Dépôt d'images Gitaly |
| `cgroups.initContainer.image.tag`                        | `master`                                                | Tag d'image Gitaly |
| `cgroups.initContainer.image.pullPolicy`                 | `IfNotPresent`                                          | Politique de récupération des images Gitaly |
| `cgroups.mountpoint`                                     | `/etc/gitlab-secrets/gitaly-pod-cgroup`                 | Emplacement de montage du répertoire cgroup parent. |
| `cgroups.hierarchyRoot`                                  | `gitaly`                                                | Cgroup parent sous lequel Gitaly crée des groupes, et dont le propriétaire est supposé être l'utilisateur et le groupe sous lesquels Gitaly s'exécute. |
| `cgroups.memoryBytes`                                    |                                                         | La limite mémoire totale imposée collectivement à tous les processus Git que Gitaly lance. 0 signifie aucune limite. |
| `cgroups.cpuShares`                                      |                                                         | La limite CPU imposée collectivement à tous les processus Git que Gitaly lance. 0 signifie aucune limite. Le maximum est de 1024 parts, ce qui représente 100 % du CPU. |
| `cgroups.cpuQuotaUs`                                     |                                                         | Utilisé pour limiter les processus des cgroups s'ils dépassent cette valeur de quota. Nous définissons cpuQuotaUs à 100 ms, donc 1 cœur correspond à 100000\. 0 signifie aucune limite. |
| `cgroups.repositories.count`                             |                                                         | Le nombre de cgroups dans le pool de cgroups. Chaque fois qu'une nouvelle commande Git est lancée, Gitaly l'affecte à l'un de ces cgroups en fonction du dépôt concerné par la commande. Un algorithme de hachage circulaire affecte les commandes Git à ces cgroups, de sorte qu'une commande Git pour un dépôt est toujours affectée au même cgroup. |
| `cgroups.repositories.memoryBytes`                       |                                                         | La limite mémoire totale imposée à tous les processus Git contenus dans un cgroup de dépôt. 0 signifie aucune limite. Cette valeur ne peut pas dépasser celle du memoryBytes de niveau supérieur. |
| `cgroups.repositories.cpuShares`                         |                                                         | La limite CPU imposée à tous les processus Git contenus dans un cgroup de dépôt. 0 signifie aucune limite. Le maximum est de 1024 parts, ce qui représente 100 % du CPU. Cette valeur ne peut pas dépasser celle du cpuShares de niveau supérieur. |
| `cgroups.repositories.cpuQuotaUs`                        |                                                         | Le cpuQuotaUs imposé à tous les processus Git contenus dans un cgroup de dépôt. Un processus Git ne peut pas utiliser plus que le quota donné. Nous définissons cpuQuotaUs à 100 ms, donc 1 cœur correspond à 100000\. 0 signifie aucune limite. |
| `cgroups.repositories.maxCgroupsPerRepo`                 | `1`                                                     | Le nombre de cgroups de dépôt sur lesquels les processus Git ciblant un dépôt spécifique peuvent être distribués. Cela permet de configurer des limites CPU et mémoire plus conservatrices pour les cgroups de dépôt tout en autorisant des charges de travail en rafale. Par exemple, avec un `maxCgroupsPerRepo` de `2` et une limite `memoryBytes` de 10 Go, des opérations Git indépendantes sur un dépôt spécifique peuvent consommer jusqu'à 20 Go de mémoire. |
| `gracefulRestartTimeout`                                 | `25`                                                    | Période de grâce d'arrêt de Gitaly, durée d'attente pour que les requêtes en cours se terminent (en secondes). Le `terminationGracePeriodSeconds` du pod est défini sur cette valeur + 5 secondes. |
| `timeout.uploadPackNegotiation`                          |                                                         | Voir [Configurer les délais de négociation](https://docs.gitlab.com/administration/settings/gitaly_timeouts/#configure-the-negotiation-timeouts). |
| `timeout.uploadArchiveNegotiation`                       |                                                         | Voir [Configurer les délais de négociation](https://docs.gitlab.com/administration/settings/gitaly_timeouts/#configure-the-negotiation-timeouts). |
| `dailyMaintenance.disabled`                              |                                                         | Permet de désactiver la maintenance quotidienne en arrière-plan. |
| `dailyMaintenance.duration`                              |                                                         | Durée maximale de la maintenance quotidienne en arrière-plan. Par exemple "1h" ou "45m". |
| `dailyMaintenance.startHour`                             |                                                         | Minute de début de la maintenance quotidienne en arrière-plan. |
| `dailyMaintenance.startMinute`                           |                                                         | Minute de début de la maintenance quotidienne en arrière-plan. |
| `dailyMaintenance.storages`                              |                                                         | Tableau de noms de stockages pour effectuer la maintenance quotidienne en arrière-plan. Par exemple [ "default" ]. |
| `bundleUri.goCloudUrl`                                   |                                                         | Voir la [documentation sur les URI de bundle](https://docs.gitlab.com/administration/gitaly/bundle_uris/). |

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

Des informations supplémentaires sur les registres privés et leurs méthodes d'authentification sont disponibles dans la [documentation Kubernetes](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Voici un exemple d'utilisation de `pullSecrets`

```yaml
image:
  repository: my.gitaly.repository
  tag: latest
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

### affinity {#affinity}

Pour plus d'informations, voir [`affinity`](../_index.md#affinity).

### annotations {#annotations}

`annotations` vous permet d'ajouter des annotations aux pods Gitaly.

Voici un exemple d'utilisation de `annotations` :

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### priorityClassName {#priorityclassname}

`priorityClassName` vous permet d'attribuer une [PriorityClass](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) aux pods Gitaly.

Voici un exemple d'utilisation de `priorityClassName` :

```yaml
priorityClassName: persistence-enabled
```

### `git.config` {#gitconfig}

`git.config` vous permet d'ajouter une configuration à toutes les commandes Git lancées par Gitaly. Accepte la configuration telle que documentée dans `git-config(1)` sous forme de paires `key` / `value`, comme indiqué ci-dessous.

```yaml
git:
  config:
    - key: "pack.threads"
      value: 4
    - key: "fsck.missingSpaceBeforeDate"
      value: ignore
```

### cgroups {#cgroups}

Pour éviter l'épuisement des ressources, Gitaly utilise les **cgroups** pour affecter les processus Git à un cgroup en fonction du dépôt sur lequel on opère. Chaque cgroup a des limites de mémoire et de CPU, assurant la stabilité du système et évitant la saturation des ressources.

Veuillez noter que le `initContainer` qui s'exécute avant le démarrage de Gitaly doit être **executed as root**. Ce conteneur configurera les permissions afin que Gitaly puisse gérer les cgroups. Par conséquent, il montera un volume sur le système de fichiers pour avoir un accès en écriture à `/sys/fs/cgroup`.

[Exemple de sursouscription](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configuring-oversubscription)

```yaml
cgroups:
  enabled: true
  # Total limit across all repository cgroups
  memoryBytes: 64424509440 # 60GiB
  cpuShares: 1024
  cpuQuotaUs: 1200000 # 12 cores
  # Per repository limits, 1000 repository cgroups
  repositories:
    count: 1000
    memoryBytes: 32212254720 # 30GiB
    cpuShares: 512
    cpuQuotaUs: 400000 # 4 cores
```

## Services externes {#external-services}

Ce chart doit être attaché au service Workhorse.

### Workhorse {#workhorse}

```yaml
workhorse:
  host: workhorse.example.com
  serviceName: webservice
  port: 8181
```

| Nom          |  Type   | Défaut      | Description |
|:--------------|:-------:|:-------------|:------------|
| `host`        | String  |              | Le nom d'hôte du serveur Workhorse. Cela peut être omis au profit de `serviceName`. |
| `port`        | Integer | `8181`       | Le port sur lequel se connecter au serveur Workhorse. |
| `serviceName` | String  | `webservice` | Le nom du `service` qui opère le serveur Workhorse. Si cet attribut est présent et que `host` ne l'est pas, le chart créera le modèle du nom d'hôte du service (et du `.Release.Name` actuel) à la place de la valeur `host`. Cela est pratique lorsque Workhorse est utilisé dans le cadre du chart GitLab global. |

## Paramètres du chart {#chart-settings}

Les valeurs suivantes sont utilisées pour configurer les pods Gitaly.

> [!note] Gitaly utilise un token d'authentification pour s'authentifier auprès des services Workhorse et Sidekiq. Le secret et la clé du token d'authentification proviennent de la valeur `global.gitaly.authToken`. De plus, le conteneur Gitaly dispose d'une copie de GitLab Shell, qui possède une configuration pouvant être définie. Le authToken Shell provient des valeurs `global.shell.authToken`.

### Persistance du dépôt Git {#git-repository-persistence}

Ce chart provisionne un PersistentVolumeClaim et monte un volume persistant correspondant pour les données du dépôt Git. Vous aurez besoin d'un stockage physique disponible dans le cluster Kubernetes pour que cela fonctionne. Si vous préférez utiliser emptyDir, désactivez PersistentVolumeClaim avec : `persistence.enabled: false`.

Les paramètres de persistance pour Gitaly sont utilisés dans un volumeClaimTemplate qui doit être valide pour tous vos pods Gitaly. Vous ne devriez *pas* inclure de paramètres destinés à référencer un volume spécifique unique (tel que `volumeName`). Si vous souhaitez référencer un volume spécifique, vous devez créer manuellement le PersistentVolumeClaim.

Vous ne pouvez pas les modifier via nos paramètres une fois déployés. Dans [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/), le `VolumeClaimTemplate` est immuable.

```yaml
persistence:
  enabled: true
  storageClass: standard
  accessMode: ReadWriteOnce
  size: 50Gi
  matchLabels: {}
  matchExpressions: []
  subPath: "data"
  annotations: {}
```

| Nom               |  Type   | Défaut         | Description |
|:-------------------|:-------:|:----------------|:------------|
| `accessMode`       | String  | `ReadWriteOnce` | Définit l'accessMode demandé dans le PersistentVolumeClaim. Voir la [documentation sur les modes d'accès Kubernetes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#access-modes) pour plus de détails. |
| `enabled`          | Boolean | `true`          | Définit si un PersistentVolumeClaim doit être utilisé pour les données du dépôt. Si `false`, un volume emptyDir est utilisé. |
| `matchExpressions` |  Tableau  |                 | Accepte un tableau d'objets de conditions de label à faire correspondre lors du choix d'un volume à lier. Ceci est utilisé dans la section `PersistentVolumeClaim` `selector`. Consultez la [documentation sur les volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector). |
| `matchLabels`      |   Map   |                 | Accepte une Map de noms de labels et de valeurs de labels à faire correspondre lors du choix d'un volume à lier. Ceci est utilisé dans la section `PersistentVolumeClaim` `selector`. Consultez la [documentation sur les volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector). |
| `size`             | String  | `50Gi`          | La taille minimale de volume à demander pour la persistance des données. |
| `storageClass`     | String  |                 | Définit le storageClassName sur le Volume Claim pour le provisionnement dynamique. Lorsqu'il n'est pas défini ou null, le provisionnement par défaut sera utilisé. S'il est défini sur un trait d'union, le provisionnement dynamique est désactivé. |
| `subPath`          | String  |                 | Définit le chemin dans le volume à monter, plutôt que la racine du volume. La racine est utilisée si le subPath est vide. |
| `annotations`      |   Map   |                 | Définit les annotations sur le Volume Claim pour le provisionnement dynamique. Voir la [documentation sur les annotations Kubernetes](https://kubernetes.io/docs/concepts/overview/working-with-objects/annotations/) pour plus de détails. |

### Exécution de Gitaly sur TLS {#running-gitaly-over-tls}

> [!note] Cette section traite de Gitaly exécuté à l'intérieur du cluster à l'aide des charts Helm. Si vous utilisez une instance Gitaly externe et souhaitez utiliser TLS pour communiquer avec elle, reportez-vous à [la documentation Gitaly externe](../../../advanced/external-gitaly/_index.md#connecting-to-external-gitaly-over-tls).

Gitaly prend en charge la communication avec d'autres composants via TLS. Cela est contrôlé par les paramètres `global.gitaly.tls.enabled` et `global.gitaly.tls.secretName`. Suivez les étapes pour exécuter Gitaly sur TLS :

1. Le chart Helm s'attend à ce qu'un certificat soit fourni pour la communication via TLS avec Gitaly. Ce certificat doit s'appliquer à tous les nœuds Gitaly présents. Ainsi, tous les noms d'hôte de chacun de ces nœuds Gitaly doivent être ajoutés en tant que Subject Alternate Name (SAN) au certificat.

   Pour connaître les noms d'hôte à utiliser, vérifiez le fichier `/srv/gitlab/config/gitlab.yml` dans le pod Toolbox et vérifiez les différents champs `gitaly_address` spécifiés sous la clé `repositories.storages` dans ce fichier.

   ```shell
   kubectl exec -it <Toolbox pod> -- grep gitaly_address /srv/gitlab/config/gitlab.yml
   ```

Un script de base pour générer des certificats signés personnalisés pour les pods Gitaly internes [est disponible dans ce dépôt](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/generate_certificates.sh). Les utilisateurs peuvent utiliser ce script ou s'y référer pour générer des certificats avec les attributs SAN appropriés.

1. Créez un secret TLS k8s à l'aide du certificat créé.

   ```shell
   kubectl create secret tls gitaly-server-tls --cert=gitaly.crt --key=gitaly.key
   ```

1. Redéployez le chart Helm en passant `--set global.gitaly.tls.enabled=true`.

### Hooks de serveur globaux {#global-server-hooks}

Le StatefulSet Gitaly prend en charge les [hooks de serveur globaux](https://docs.gitlab.com/administration/server_hooks/#create-a-global-server-hook-for-all-repositories). Les scripts de hook s'exécutent sur le pod Gitaly et sont donc limités aux outils disponibles dans le [conteneur Gitaly](https://gitlab.com/gitlab-org/build/CNG/-/blob/master/gitaly/Dockerfile).

Les hooks sont renseignés à l'aide de [ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/) et peuvent être utilisés en définissant les valeurs suivantes de manière appropriée :

1. `global.gitaly.hooks.preReceive.configmap`
1. `global.gitaly.hooks.postReceive.configmap`
1. `global.gitaly.hooks.update.configmap`

Pour renseigner le ConfigMap, vous pouvez pointer `kubectl` vers un répertoire de scripts :

```shell
kubectl create configmap MAP_NAME --from-file /PATH/TO/SCRIPT/DIR
```

### Signature GPG des commits créés par GitLab {#gpg-signing-commits-created-by-gitlab}

Gitaly a la capacité de [signer par GPG tous les commits](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-commit-signing-for-gitlab-ui-commits) créés via l'interface utilisateur GitLab, par exemple le WebIDE, ainsi que les commits créés par GitLab, tels que les commits de fusion et les squashes.

1. Créez un secret k8s en utilisant votre clé privée GPG.

   ```shell
   kubectl create secret generic gitaly-gpg-signing-key --from-file=signing_key=/path/to/gpg_signing_key.gpg
   ```

1. Activez la signature GPG dans votre `values.yaml`.

   ```yaml
   gitlab:
     gitaly:
       gpgSigning:
         enabled: true
         secret: gitaly-gpg-signing-key
         key: signing_key
   ```

### Sauvegardes côté serveur {#server-side-backups}

Le chart prend en charge les [sauvegardes Gitaly côté serveur](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups). Pour les utiliser :

1. Créez un bucket pour stocker les sauvegardes.
1. Configurez les identifiants du stockage d'objets et l'URL de stockage.

   ```yaml
   gitlab:
     gitaly:
       extraEnvFrom:
          # Mount the exisitign object store secret to the expected environment variables.
          AWS_ACCESS_KEY_ID:
            secretKeyRef:
              name: <Rails object store secret>
              key: aws_access_key_id
          AWS_SECRET_ACCESS_KEY:
            secretKeyRef:
              name: <Rails object store secret>
              key: aws_secret_access_key
       backup:
         # This is the connection string for Gitaly server side backups.
         goCloudUrl: <object store connection URL>
   ```

   Pour les variables d'environnement attendues et le format d'URL de stockage pour votre backend de stockage d'objets, consultez la [documentation Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#configure-server-side-backups).

1. [Activer les sauvegardes côté serveur avec `backup-utility`](../../../backup-restore/backup.md#server-side-repository-backups).
