---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du chart GitLab-Spamcheck
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le sous-chart `spamcheck` fournit un déploiement de [Spamcheck](https://gitlab.com/gitlab-org/spamcheck), un moteur anti-spam développé par GitLab initialement pour lutter contre la quantité croissante de spam sur GitLab.com, et rendu public par la suite pour être utilisé dans GitLab Self-Managed.

## Prérequis {#requirements}

Ce chart dépend de l'accès à l'API GitLab.

## Configuration {#configuration}

### Activer Spamcheck {#enable-spamcheck}

`spamcheck` est désactivé par défaut. Pour l'activer sur votre instance GitLab, définissez la propriété Helm `global.spamcheck.enabled` sur `true`, par exemple :

```shell
helm upgrade --force --install gitlab . \
--set global.hosts.domain='your.domain.com' \
--set global.hosts.externalIP=XYZ.XYZ.XYZ.XYZ \
--set certmanager-issuer.email='me@example.com' \
--set global.spamcheck.enabled=true
```

### Configurer GitLab pour utiliser Spamcheck {#configure-gitlab-to-use-spamcheck}

1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Paramètres > Rapports**.
1. Développez **Protection anti‐spam et anti‐robot**.
1. Mettez à jour les paramètres de Spam Check :
   1. Cochez la case **Activer Spam Check via le point de terminaison d'une API externe**
   1. Pour l'URL du point de terminaison externe de Spam Check, utilisez `grpc://gitlab-spamcheck.default.svc:8001`, où `default` est remplacé par l'espace de nommage Kubernetes dans lequel GitLab est déployé.
   1. Laissez le champ **Clé d'API de Spamcheck** vide.
1. Sélectionnez **Sauvegarder les modifications**.

## Options de ligne de commande d'installation {#installation-command-line-options}

Le tableau ci-dessous contient toutes les configurations de charts possibles qui peuvent être fournies à la commande `helm install` via les flags `--set`.

| Paramètre                                       | Défaut                                                                                              | Description |
|-------------------------------------------------|------------------------------------------------------------------------------------------------------|-------------|
| `affinity`                                      | `{}`                                                                                                 | [Règles d'affinité](../_index.md#affinity) pour l'affectation des pods |
| `annotations`                                   | `{}`                                                                                                 | Annotations de pod |
| `common.labels`                                 | `{}`                                                                                                 | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `deployment.livenessProbe.initialDelaySeconds`  | `20`                                                                                                 | Délai avant le lancement de la sonde de vivacité |
| `deployment.livenessProbe.periodSeconds`        | `60`                                                                                                 | Fréquence d'exécution de la sonde de vivacité |
| `deployment.livenessProbe.timeoutSeconds`       | `30`                                                                                                 | Délai d'expiration de la sonde de vivacité |
| `deployment.livenessProbe.successThreshold`     | `1`                                                                                                  | Nombre minimum de succès consécutifs pour que la sonde de vivacité soit considérée comme réussie après un échec |
| `deployment.livenessProbe.failureThreshold`     | `3`                                                                                                  | Nombre minimum d'échecs consécutifs pour que la sonde de vivacité soit considérée comme échouée après un succès |
| `deployment.readinessProbe.initialDelaySeconds` | `0`                                                                                                  | Délai avant le lancement de la sonde de disponibilité |
| `deployment.readinessProbe.periodSeconds`       | `10`                                                                                                 | Fréquence d'exécution de la sonde de disponibilité |
| `deployment.readinessProbe.timeoutSeconds`      | `2`                                                                                                  | Délai d'expiration de la sonde de disponibilité |
| `deployment.readinessProbe.successThreshold`    | `1`                                                                                                  | Nombre minimum de succès consécutifs pour que la sonde de disponibilité soit considérée comme réussie après un échec |
| `deployment.readinessProbe.failureThreshold`    | `3`                                                                                                  | Nombre minimum d'échecs consécutifs pour que la sonde de disponibilité soit considérée comme échouée après un succès |
| `deployment.strategy`                           | `{}`                                                                                                 | Permet de configurer la stratégie de mise à jour utilisée par le déploiement. Si non fourni, la valeur par défaut du cluster est utilisée. |
| `hpa.behavior`                                  | `{scaleDown: {stabilizationWindowSeconds: 300 }}`                                                    | Behavior contient les spécifications pour le comportement de mise à l'échelle automatique ascendant et descendant (nécessite `autoscaling/v2beta2` ou version supérieure) |
| `hpa.customMetrics`                             | `[]`                                                                                                 | Les métriques personnalisées contiennent les spécifications à utiliser pour calculer le nombre de réplicas souhaité (remplace l'utilisation par défaut de la consommation CPU moyenne configurée dans `targetAverageUtilization`) |
| `hpa.cpu.targetType`                            | `AverageValue`                                                                                       | Définit le type cible du CPU pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.cpu.targetAverageValue`                    | `100m`                                                                                               | Définit la valeur cible CPU pour la mise à l'échelle automatique |
| `hpa.cpu.targetAverageUtilization`              |                                                                                                      | Définit la consommation cible CPU pour la mise à l'échelle automatique |
| `hpa.memory.targetType`                         |                                                                                                      | Définit le type cible de la mémoire pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.memory.targetAverageValue`                 |                                                                                                      | Définit la valeur cible mémoire pour la mise à l'échelle automatique |
| `hpa.memory.targetAverageUtilization`           |                                                                                                      | Définit la consommation cible mémoire pour la mise à l'échelle automatique |
| `hpa.targetAverageValue`                        |                                                                                                      | **DEPRECATED** Définit la valeur cible CPU pour la mise à l'échelle automatique |
| `image.registry`                                |                                                                                                      | Registre d'images Spamcheck |
| `image.repository`                              | `registry.gitlab.com/gitlab-com/gl-security/engineering-and-research/automation-team/spam/spamcheck` | Dépôt d'images Spamcheck |
| `image.tag`                                     |                                                                                                      | Tag d'image Spamcheck |
| `image.digest`                                  |                                                                                                      | Digest d'image Spamcheck |
| `keda.enabled`                                  | `false`                                                                                              | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` à la place de `HorizontalPodAutoscalers` |
| `keda.pollingInterval`                          | `30`                                                                                                 | L'intervalle auquel vérifier chaque déclencheur |
| `keda.cooldownPeriod`                           | `300`                                                                                                | La période d'attente après que le dernier déclencheur a signalé une activité avant de remettre la ressource à l'échelle à 0 |
| `keda.minReplicaCount`                          | `hpa.minReplicas`                                                                                    | Nombre minimum de réplicas vers lesquels KEDA peut réduire la ressource. |
| `keda.maxReplicaCount`                          | `hpa.maxReplicas`                                                                                    | Nombre maximum de réplicas vers lesquels KEDA peut augmenter la ressource. |
| `keda.fallback`                                 |                                                                                                      | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `keda.hpaName`                                  | `keda-hpa-{scaled-object-name}`                                                                      | Le nom de la ressource HPA que KEDA créera. |
| `keda.restoreToOriginalReplicaCount`            |                                                                                                      | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `keda.behavior`                                 | `hpa.behavior`                                                                                       | Les spécifications pour le comportement de mise à l'échelle ascendant et descendant. |
| `keda.triggers`                                 |                                                                                                      | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |
| `listenAddr`                                    | `[::]`                                                                                               | Adresse d'écoute interne. |
| `logging.level`                                 | `info`                                                                                               | Niveau de log   |
| `maxReplicas`                                   | `10`                                                                                                 | HPA `maxReplicas` |
| `maxUnavailable`                                | `1`                                                                                                  | HPA `maxUnavailable` |
| `minReplicas`                                   | `2`                                                                                                  | HPA `maxReplicas` |
| `podLabels`                                     | `{}`                                                                                                 | Labels de pod supplémentaires. Non utilisé pour les sélecteurs. |
| `resources.requests.cpu`                        | `100m`                                                                                               | CPU minimum de Spamcheck |
| `resources.requests.memory`                     | `100M`                                                                                               | Mémoire minimum de Spamcheck |
| `securityContext.fsGroup`                       | `1000`                                                                                               | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.runAsUser`                     | `1000`                                                                                               | ID utilisateur sous lequel le pod doit être démarré |
| `securityContext.fsGroupChangePolicy`           |                                                                                                      | Politique de changement de propriété et d'autorisation du volume (nécessite Kubernetes 1.23) |
| `serviceLabels`                                 | `{}`                                                                                                 | Labels de service supplémentaires |
| `service.externalPort`                          | `8001`                                                                                               | Port externe de Spamcheck |
| `service.internalPort`                          | `8001`                                                                                               | Port interne de Spamcheck |
| `service.type`                                  | `ClusterIP`                                                                                          | Type de service Spamcheck |
| `serviceAccount.automountServiceAccountToken`   | `false`                                                                                              | Indique si le token d'accès ServiceAccount par défaut doit être monté dans les pods |
| `serviceAccount.create`                         | `false`                                                                                              | Indique si un ServiceAccount doit être créé |
| `serviceAccount.enabled`                        | `false`                                                                                              | Indique si un ServiceAccount doit être utilisé |
| `tolerations`                                   | `[]`                                                                                                 | Labels de tolérance pour l'affectation des pods |
| `extraEnvFrom`                                  | `{}`                                                                                                 | Liste de variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| `priorityClassName`                             |                                                                                                      | [Classe de priorité](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) assignée aux pods. |

## Configuration de KEDA {#configuring-keda}

Cette section `keda` active l'installation de [KEDA](https://keda.sh/) `ScaledObjects` à la place des `HorizontalPodAutoscalers` classiques. Cette configuration est facultative et peut être utilisée lorsqu'il est nécessaire d'effectuer une mise à l'échelle automatique basée sur des métriques personnalisées ou externes.

La plupart des paramètres utilisent par défaut les valeurs définies dans la section `hpa` le cas échéant.

Si les conditions suivantes sont remplies, des déclencheurs CPU et mémoire sont ajoutés automatiquement en fonction des seuils CPU et mémoire définis dans la section `hpa` :

- `triggers` n'est pas défini.
- Le paramètre `request.cpu.request` ou `request.memory.request` correspondant est également défini sur une valeur non nulle.

Si aucun déclencheur n'est défini, le `ScaledObject` n'est pas créé.

Consultez la [documentation KEDA](https://keda.sh/docs/2.10/concepts/scaling-deployments/) pour plus de détails sur ces paramètres.

| Nom                            |  Type   | Défaut                         | Description |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | Boolean | `false`                         | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` à la place de `HorizontalPodAutoscalers` |
| `pollingInterval`               | Integer | `30`                            | L'intervalle auquel vérifier chaque déclencheur |
| `cooldownPeriod`                | Integer | `300`                           | La période d'attente après que le dernier déclencheur a signalé une activité avant de remettre la ressource à l'échelle à 0 |
| `minReplicaCount`               | Integer | `hpa.minReplicas`               | Nombre minimum de réplicas vers lesquels KEDA peut réduire la ressource. |
| `maxReplicaCount`               | Integer | `hpa.maxReplicas`               | Nombre maximum de réplicas vers lesquels KEDA peut augmenter la ressource. |
| `fallback`                      |   Map   |                                 | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `hpaName`                       | String  | `keda-hpa-{scaled-object-name}` | Le nom de la ressource HPA que KEDA créera. |
| `restoreToOriginalReplicaCount` | Boolean |                                 | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `behavior`                      |   Map   | `hpa.behavior`                  | Les spécifications pour le comportement de mise à l'échelle ascendant et descendant. |
| `triggers`                      |  Tableau  |                                 | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |

## Exemples de configuration du chart {#chart-configuration-examples}

### `serviceAccount` {#serviceaccount}

Cette section contrôle si un ServiceAccount doit être créé et si le token d'accès par défaut doit être monté dans les pods.

| Nom                           |  Type   | Défaut | Description |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | Boolean | `false` | Contrôle si le token d'accès ServiceAccount par défaut doit être monté dans les pods. Vous ne devriez pas activer cela sauf si cela est requis par certains sidecars pour fonctionner correctement (par exemple, Istio). |
| `create`                       | Boolean | `false` | Indique si un ServiceAccount doit être créé. |
| `enabled`                      | Boolean | `false` | Indique si un ServiceAccount doit être utilisé. |

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

`annotations` vous permet d'ajouter des annotations aux pods Spamcheck. Par exemple :

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### resources {#resources}

`resources` vous permet de configurer la quantité minimale et maximale de ressources (mémoire et CPU) qu'un pod Spamcheck peut consommer.

Par exemple :

```yaml
resources:
  requests:
    memory: 100m
    cpu: 100M
```

### livenessProbe/readinessProbe {#livenessprobereadinessprobe}

`deployment.livenessProbe` et `deployment.readinessProbe` fournissent un mécanisme pour aider à contrôler la terminaison des pods Spamcheck dans certains scénarios, par exemple lorsqu'un conteneur est dans un état défaillant.

Par exemple :

```yaml
deployment:
  livenessProbe:
    initialDelaySeconds: 10
    periodSeconds: 20
    timeoutSeconds: 3
    successThreshold: 1
    failureThreshold: 10
  readinessProbe:
    initialDelaySeconds: 10
    periodSeconds: 5
    timeoutSeconds: 2
    successThreshold: 1
    failureThreshold: 3
```

Consultez la [documentation officielle de Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) pour plus de détails sur cette configuration.
