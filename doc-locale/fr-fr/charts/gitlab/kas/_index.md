---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser le chart `kas` GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le sous-chart `kas` fournit un déploiement configurable du [serveur d'agent GitLab (KAS)](https://docs.gitlab.com/administration/clusters/kas/). Le serveur d'agent est un composant que vous installez avec GitLab. Il est nécessaire pour gérer l'[agent GitLab pour Kubernetes](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent).

Ce chart dépend de l'accès à l'API GitLab et aux serveurs Gitaly. Lorsque vous activez ce chart, un Ingress est déployé.

Pour consommer un minimum de ressources, le conteneur `kas` utilise une image distroless. Les services déployés sont exposés par un Ingress, qui utilise le [proxy WebSocket](https://nginx.org/en/docs/http/websocket.html) pour la communication. Ce proxy permet des connexions de longue durée avec le composant externe, [`agentk`](https://docs.gitlab.com/user/clusters/agent/install/). `agentk` est l'homologue de l'agent côté cluster Kubernetes.

La route pour accéder au service dépend de votre [configuration Ingress](#specify-an-ingress).

Pour plus d'informations, consultez l'[architecture de l'agent GitLab pour Kubernetes](https://gitlab.com/gitlab-org/cluster-integration/gitlab-agent/-/blob/master/doc/architecture.md).

## Désactiver le serveur d'agent {#disable-the-agent-server}

Le serveur d'agent GitLab (`kas`) est activé par défaut. Pour le désactiver sur votre instance GitLab, définissez la propriété Helm `global.kas.enabled` sur `false`.

Par exemple :

```shell
helm upgrade --install kas --set global.kas.enabled=false
```

### Spécifier un Ingress {#specify-an-ingress}

Lorsque vous utilisez l'Ingress du chart avec la configuration par défaut, le service pour le serveur d'agent est accessible sur un sous-domaine. Par exemple, pour `global.hosts.domain: example.com`, le serveur d'agent est accessible à `kas.example.com`.

L'[Ingress KAS](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/charts/gitlab/charts/kas/templates/ingress.yaml) peut utiliser un domaine différent de celui de `global.hosts.domain`.

Définissez `global.hosts.kas.name`, par exemple :

```shell
global.hosts.kas.name: kas.my-other-domain.com
```

Cet exemple utilise `kas.my-other-domain.com` comme hôte pour l'Ingress KAS uniquement. Le reste des services (y compris GitLab, Registry, MinIO, etc.) utilisent le domaine spécifié dans `global.hosts.domain`.

### Prise en charge de l'Ingress gRPC {#grpc-ingress-support}

Le service KAS prend en charge le trafic gRPC via le même port que le trafic WebSocket, en utilisant le routage basé sur les chemins avec correspondance regex pour distinguer les deux protocoles.

> [!warning]
> L'Ingress gRPC n'est pas pris en charge lorsque [`global.appConfig.relativeUrlRoot`](../../globals.md#configure-a-relative-url-root) est défini sur une valeur non vide.

#### Prise en charge des contrôleurs {#controller-support}

- **NGINX Ingress Controller** :  Entièrement pris en charge avec configuration automatique
- **Other Controllers** :  Tout contrôleur prenant en charge la correspondance de chemin basée sur les regex peut être utilisé

#### Modèle de chemin {#path-pattern}

L'Ingress gRPC utilise le modèle de chemin suivant :

```regex
/gitlab\.agent\.(.+)
```

Ce modèle assure un routage correct du trafic gRPC vers le service KAS tout en maintenant la fonctionnalité WebSocket sur le même port.

#### Configuration {#configuration}

Pour activer l'Ingress gRPC, définissez `gitlab.kas.ingress.grpc.enabled` et assurez-vous que KAS s'exécute sous son propre sous-domaine :

```yaml
gitlab:
  kas:
    ingress:
      grpc:
        enabled: true
```

Aucune configuration supplémentaire n'est nécessaire lors de l'utilisation du NGINX Ingress Controller, car il est configuré automatiquement. Pour les autres contrôleurs, ajoutez les annotations pertinentes pour prendre en charge gRPC, assurez-vous qu'ils prennent en charge la correspondance de chemin basée sur les regex et configurez-les pour router le modèle de chemin spécifié vers le service KAS.

### Options de ligne de commande d'installation {#installation-command-line-options}

Vous pouvez passer ces paramètres à la commande `helm install` en utilisant les flags `--set`.

| Paramètre                                                | Défaut                                               | Description |
|----------------------------------------------------------|-------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                  | [Règles d'affinité](../_index.md#affinity) pour l'affectation des pods |
| `annotations`                                            | `{}`                                                  | Annotations du pod. |
| `common.labels`                                          | `{}`                                                  | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `securityContext.runAsUser`                              | `65532`                                               | ID utilisateur sous lequel le pod doit être démarré |
| `securityContext.runAsGroup`                             | `65534`                                               | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.fsGroup`                                | `65532`                                               | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.fsGroupChangePolicy`                    |                                                       | Politique de changement de propriété et d'autorisation du volume (nécessite Kubernetes 1.23) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                      | Profil Seccomp à utiliser |
| `containerSecurityContext.runAsUser`                     | `65532`                                               | Remplace l'ID utilisateur du [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel le conteneur est démarré |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                               | Contrôle si un processus du conteneur peut obtenir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                | Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                           | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `extraContainers`                                        |                                                       | Chaîne de style littéral multiligne contenant une liste de conteneurs à inclure. |
| `extraEnv`                                               |                                                       | Liste de variables d'environnement supplémentaires à exposer |
| `extraEnvFrom`                                           |                                                       | Liste de variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| `init.containerSecurityContext`                          |                                                       | Remplacements du securityContext du conteneur init |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                               | Spécifique à initContainer :  Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                | Spécifique à initContainer :  Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                           | Spécifique à initContainer :  Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-kas` | Dépôt d'images. |
| `image.tag`                                              | `v13.7.0`                                             | Tag d'image.  |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`     | Behavior contient les spécifications pour le comportement de mise à l'échelle vers le haut et vers le bas (nécessite `autoscaling/v2beta2` ou supérieur). |
| `hpa.customMetrics`                                      | `[]`                                                  | Les métriques personnalisées contiennent les spécifications à utiliser pour calculer le nombre de réplicas souhaité (remplace l'utilisation par défaut de la consommation CPU moyenne configurée dans `targetAverageUtilization`). |
| `hpa.cpu.targetType`                                     | `AverageValue`                                        | Définit le type cible du CPU pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue`. |
| `hpa.cpu.targetAverageValue`                             | `100m`                                                | Définit la valeur cible CPU pour la mise à l'échelle automatique. |
| `hpa.cpu.targetAverageUtilization`                       |                                                       | Définit l'utilisation cible CPU pour la mise à l'échelle automatique. |
| `hpa.memory.targetType`                                  |                                                       | Définit le type cible de la mémoire pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue`. |
| `hpa.memory.targetAverageValue`                          |                                                       | Définit la valeur cible mémoire pour la mise à l'échelle automatique. |
| `hpa.memory.targetAverageUtilization`                    |                                                       | Définit l'utilisation cible mémoire pour la mise à l'échelle automatique. |
| `hpa.targetAverageValue`                                 |                                                       | **DEPRECATED** Définit la valeur cible CPU pour la mise à l'échelle automatique |
| `ingress.enabled`                                        | `true` si `global.kas.enabled=true`                   | Vous pouvez utiliser `kas.ingress.enabled` pour l'activer ou le désactiver explicitement. Si non défini, vous pouvez éventuellement utiliser `global.ingress.enabled` dans le même but. |
| `ingress.apiVersion`                                     |                                                       | Valeur à utiliser dans le champ `apiVersion`. |
| `ingress.annotations`                                    | `{}`                                                  | Annotations Ingress. |
| `ingress.tls`                                            | `{}`                                                  | Configuration TLS de l'Ingress. |
| `ingress.agentPath`                                      | `/`                                                   | Chemin Ingress pour le point de terminaison de l'API agent. |
| `ingress.k8sApiPath`                                     | `/k8s-proxy`                                          | Chemin Ingress pour le point de terminaison de l'API Kubernetes. |
| `keda.enabled`                                           | `false`                                               | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` à la place de `HorizontalPodAutoscalers` |
| `keda.pollingInterval`                                   | `30`                                                  | L'intervalle auquel vérifier chaque déclencheur |
| `keda.cooldownPeriod`                                    | `300`                                                 | La période d'attente après que le dernier déclencheur a signalé une activité avant de remettre la ressource à l'échelle à 0 |
| `keda.minReplicaCount`                                   |                                                       | Nombre minimum de réplicas vers lequel KEDA réduira la ressource, par défaut `minReplicas` |
| `keda.maxReplicaCount`                                   |                                                       | Nombre maximum de réplicas vers lequel KEDA augmentera la ressource, par défaut `maxReplicas` |
| `keda.fallback`                                          |                                                       | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `keda.hpaName`                                           |                                                       | Le nom de la ressource HPA que KEDA créera, par défaut `keda-hpa-{scaled-object-name}` |
| `keda.restoreToOriginalReplicaCount`                     |                                                       | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `keda.behavior`                                          |                                                       | Les spécifications pour le comportement de mise à l'échelle ascendante et descendante, par défaut `hpa.behavior` |
| `keda.triggers`                                          |                                                       | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |
| `metrics.enabled`                                        | `true`                                                | Si un point de terminaison de métriques doit être rendu disponible pour le scraping. |
| `metrics.path`                                           | `/metrics`                                            | Chemin du point de terminaison des métriques. |
| `metrics.serviceMonitor.enabled`                         | `false`                                               | Si un ServiceMonitor doit être créé pour permettre à Prometheus Operator de gérer le scraping des métriques. L'activation supprime les annotations de scrape `prometheus.io`. Il ne peut pas être activé en même temps que `metrics.podMonitor.enabled`. |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                  | Labels supplémentaires à ajouter au ServiceMonitor. |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                  | Configuration de point de terminaison supplémentaire pour le ServiceMonitor. |
| `metrics.podMonitor.enabled`                             | `false`                                               | Si un PodMonitor doit être créé pour permettre à Prometheus Operator de gérer le scraping des métriques. L'activation supprime les annotations de scrape `prometheus.io`. Il ne peut pas être activé en même temps que `metrics.serviceMonitor.enabled`. |
| `metrics.podMonitor.additionalLabels`                    | `{}`                                                  | Labels supplémentaires à ajouter au PodMonitor. |
| `metrics.podMonitor.endpointConfig`                      | `{}`                                                  | Configuration de point de terminaison supplémentaire pour le PodMonitor. |
| `maxReplicas`                                            | `10`                                                  | HPA `maxReplicas`. |
| `maxUnavailable`                                         | `1`                                                   | HPA `maxUnavailable`. |
| `minReplicas`                                            | `2`                                                   | HPA `maxReplicas`. |
| `nodeSelector`                                           |                                                       | Définir un [nodeSelector](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#nodeselector) pour les `Pod`s de ce `Deployment`, le cas échéant. |
| `observability.port`                                     | `8151`                                                | Port du point de terminaison d'observabilité. Utilisé pour les points de terminaison de métriques et de sondes. |
| `observability.livenessProbe.path`                       | `/liveness`                                           | URI pour le point de terminaison de la sonde de vivacité. Cette valeur doit correspondre à la valeur `observability.liveness_probe.url_path` de la configuration du service KAS. |
| `observability.readinessProbe.path`                      | `/readiness`                                          | URI pour le point de terminaison de la sonde de disponibilité. Cette valeur doit correspondre à la valeur `observability.readiness_probe.url_path` de la configuration du service KAS. |
| `serviceAccount.annotations`                             | `{}`                                                  | Annotations du compte de service. |
| `podLabels`                                              | `{}`                                                  | Labels de pod supplémentaires. Non utilisé pour les sélecteurs. |
| `serviceLabels`                                          | `{}`                                                  | Labels de service supplémentaires. |
| `common.labels`                                          |                                                       | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `resources.requests.cpu`                                 | `100m`                                                | Requête CPU minimale par pod KAS |
| `resources.requests.memory`                              | `256Mi`                                               | Requête mémoire minimale par pod KAS. |
| `service.externalPort`                                   | `8150`                                                | Port externe (pour les connexions `agentk`). |
| `service.internalPort`                                   | `8150`                                                | Port interne (pour les connexions `agentk`). |
| `service.apiInternalPort`                                | `8153`                                                | Port interne pour l'API interne (pour le backend GitLab). |
| `service.loadBalancerIP`                                 | `nil`                                                 | Une IP d'équilibreur de charge personnalisée lorsque `service.type` est `LoadBalancer`. |
| `service.loadBalancerSourceRanges`                       | `nil`                                                 | Une liste de plages sources d'équilibreur de charge personnalisées lorsque `service.type` est `LoadBalancer`. |
| `service.kubernetesApiPort`                              | `8154`                                                | Port externe pour exposer l'API Kubernetes proxifiée. |
| `service.privateApiPort`                                 | `8155`                                                | Port interne pour exposer l'API privée de `kas` (pour la communication `kas` -> `kas`). |
| `serviceAccount.annotations`                             | `{}`                                                  | Annotations ServiceAccount. |
| `serviceAccount.automountServiceAccountToken`            | `false`                                               | Indique si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods. |
| `serviceAccount.create`                                  | `false`                                               | Indique si un ServiceAccount doit être créé. |
| `serviceAccount.enabled`                                 | `false`                                               | Indique si un ServiceAccount doit être utilisé. |
| `serviceAccount.name`                                    |                                                       | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé. |
| `websocketToken.secret`                                  | Généré automatiquement                                         | Le nom du secret à utiliser pour la signature et la vérification du jeton WebSocket. |
| `websocketToken.key`                                     | Généré automatiquement                                         | Le nom de la clé dans `websocketToken.secret` à utiliser. |
| `privateApi.secret`                                      | Généré automatiquement                                         | Le nom du secret à utiliser pour l'authentification auprès de la base de données. |
| `privateApi.key`                                         | Généré automatiquement                                         | Le nom de la clé dans `privateApi.secret` à utiliser. |
| `global.kas.service.apiExternalPort`                     | `8153`                                                | Port externe pour l'API interne (pour le backend GitLab). |
| `service.type`                                           | `ClusterIP`                                           | Type de service. |
| `tolerations`                                            | `[]`                                                  | Labels de tolérance pour l'affectation des pods. |
| `customConfig`                                           | `{}`                                                  | Si spécifié, fusionne la configuration `kas` par défaut avec ces valeurs en donnant la priorité à celles définies ici. |
| `deployment.minReadySeconds`                             | `0`                                                   | Nombre minimum de secondes devant s'écouler avant qu'un pod `kas` soit considéré comme prêt. |
| `deployment.strategy`                                    | `{}`                                                  | Permet de configurer la stratégie de mise à jour utilisée par le déploiement. |
| `deployment.terminationGracePeriodSeconds`               | `300`                                                 | Durée en secondes pendant laquelle un pod est autorisé à s'arrêter après avoir reçu SIGTERM. |
| `priorityClassName`                                      |                                                       | [Classe de priorité](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) assignée aux pods. |

## Activer la communication TLS {#enable-tls-communication}

Activez la communication TLS entre vos pods `kas` et les autres composants du chart GitLab, via l'[attribut KAS global](../../globals.md#tls-settings-1).

## Tester le chart `kas` {#test-the-kas-chart}

Pour installer le chart :

1. Créez votre propre cluster Kubernetes.
1. Consultez la branche de travail du merge request.
1. Installez (ou mettez à niveau) GitLab avec `kas` activé par défaut depuis votre branche de chart locale :

   ```shell
   helm upgrade --force --install gitlab . \
     --timeout 600s \
     --set global.hosts.domain=your.domain.com \
     --set global.hosts.externalIP=XYZ.XYZ.XYZ.XYZ \
     --set certmanager-issuer.email=your@email.com
   ```

1. Utilisez le GDK pour exécuter le processus de configuration et d'utilisation de l'[agent GitLab pour Kubernetes](https://docs.gitlab.com/user/clusters/agent/) :  (Vous pouvez également suivre les étapes pour configurer et utiliser l'agent manuellement.)

   1. Depuis votre dépôt GDK GitLab, accédez au dossier QA : `cd qa`.
   1. Exécutez la commande suivante pour lancer le test QA :

      ```shell
      GITLAB_USERNAME=$ROOT_USER
      GITLAB_PASSWORD=$ROOT_PASSWORD
      GITLAB_ADMIN_USERNAME=$ROOT_USER
      GITLAB_ADMIN_PASSWORD=$ROOT_PASSWORD
      bundle exec bin/qa Test::Instance::All https://your.gitlab.domain/ -- --tag orchestrated --tag quarantine qa/specs/features/ee/api/7_configure/kubernetes/kubernetes_agent_spec.rb
      ```

      Vous pouvez également personnaliser la version de `agentk` à installer avec une variable d'environnement : `GITLAB_AGENTK_VERSION=v13.7.1`

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

## Activer la journalisation de débogage {#enable-debug-logging}

Pour activer la journalisation de débogage pour le sous-chart KAS, ajoutez ce qui suit à la section `kas` de votre fichier `values.yaml` :

```yaml
customConfig:
   observability:
      logging:
         level: debug
         grpc_level: debug
```
