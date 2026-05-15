---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du chart GitLab Pages
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le sous-chart `gitlab-pages` fournit un daemon pour servir des sites web statiques à partir de projets GitLab.

## Prérequis {#requirements}

Ce chart dépend de l'accès aux services Workhorse, soit dans le cadre du chart GitLab complet, soit fourni en tant que service externe accessible depuis le cluster Kubernetes sur lequel ce chart est déployé.

## Configuration {#configuration}

Le chart `gitlab-pages` est configuré comme suit :  [Paramètres globaux](#global-settings) et [Paramètres du chart](#chart-settings).

## Paramètres globaux {#global-settings}

Nous partageons certains paramètres globaux communs entre nos charts. Voir la [Documentation Globals](../../globals.md#configure-gitlab-pages) pour plus de détails.

## Paramètres du chart {#chart-settings}

Les tableaux des deux sections suivantes contiennent toutes les configurations de chart possibles qui peuvent être fournies à la commande `helm install` en utilisant les indicateurs `--set`.

### Paramètres généraux {#general-settings}

| Paramètre                                                | Défaut                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                    | [Règles d'affinité](../_index.md#affinity) pour l'attribution des pods |
| `annotations`                                            |                                                         | Annotations de pod |
| `common.labels`                                          | `{}`                                                    | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `deployment.strategy`                                    | `{}`                                                    | Permet de configurer la stratégie de mise à jour utilisée par le déploiement. Si non fourni, la valeur par défaut du cluster est utilisée. |
| `extraEnv`                                               |                                                         | Liste de variables d'environnement supplémentaires à exposer |
| `extraEnvFrom`                                           |                                                         | Liste de variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`       | Behavior contient les spécifications pour le comportement de mise à l'échelle automatique ascendant et descendant (nécessite `autoscaling/v2beta2` ou version supérieure) |
| `hpa.customMetrics`                                      | `[]`                                                    | Les métriques personnalisées contiennent les spécifications à utiliser pour calculer le nombre de réplicas souhaité (remplace l'utilisation par défaut de la consommation CPU moyenne configurée dans `targetAverageUtilization`) |
| `hpa.cpu.targetType`                                     | `AverageValue`                                          | Définit le type cible du CPU pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.cpu.targetAverageValue`                             | `100m`                                                  | Définit la valeur cible CPU pour la mise à l'échelle automatique |
| `hpa.cpu.targetAverageUtilization`                       |                                                         | Définit la consommation cible CPU pour la mise à l'échelle automatique |
| `hpa.memory.targetType`                                  |                                                         | Définit le type cible de la mémoire pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.memory.targetAverageValue`                          |                                                         | Définit la valeur cible mémoire pour la mise à l'échelle automatique |
| `hpa.memory.targetAverageUtilization`                    |                                                         | Définit la consommation cible mémoire pour la mise à l'échelle automatique |
| `hpa.minReplicas`                                        | `1`                                                     | Nombre minimum de réplicas |
| `hpa.maxReplicas`                                        | `10`                                                    | Nombre maximum de réplicas |
| `hpa.targetAverageValue`                                 |                                                         | **DEPRECATED** Définit la valeur cible CPU pour la mise à l'échelle automatique |
| `image.pullPolicy`                                       | `IfNotPresent`                                          | Politique de récupération de l'image GitLab |
| `image.pullSecrets`                                      |                                                         | Secrets pour le dépôt d'images |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-pages` | Dépôt d'images GitLab Pages |
| `image.tag`                                              |                                                         | tag d'image   |
| `init.image.repository`                                  |                                                         | Image initContainer |
| `init.image.tag`                                         |                                                         | Tag d'image initContainer |
| `init.containerSecurityContext`                          |                                                         | Propre à initContainer : [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                 | Propre à initContainer :  Contrôle si un processus peut acquérir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                  | Propre à initContainer :  Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                             | Propre à initContainer :  Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur |
| `keda.enabled`                                           | `false`                                                 | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` à la place de `HorizontalPodAutoscalers` |
| `keda.pollingInterval`                                   | `30`                                                    | L'intervalle auquel vérifier chaque déclencheur |
| `keda.cooldownPeriod`                                    | `300`                                                   | La période d'attente après que le dernier déclencheur a signalé une activité avant de remettre la ressource à l'échelle à 0 |
| `keda.minReplicaCount`                                   | `hpa.minReplicas`                                       | Nombre minimum de réplicas vers lesquels KEDA peut réduire la ressource. |
| `keda.maxReplicaCount`                                   | `hpa.maxReplicas`                                       | Nombre maximum de réplicas vers lesquels KEDA peut augmenter la ressource. |
| `keda.fallback`                                          |                                                         | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                         | Le nom de la ressource HPA que KEDA créera. |
| `keda.restoreToOriginalReplicaCount`                     |                                                         | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `keda.behavior`                                          | `hpa.behavior`                                          | Les spécifications pour le comportement de mise à l'échelle ascendant et descendant. |
| `keda.triggers`                                          |                                                         | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |
| `metrics.enabled`                                        | `true`                                                  | Si un endpoint de métriques doit être rendu disponible pour la collecte |
| `metrics.port`                                           | `9235`                                                  | Port de l'endpoint de métriques |
| `metrics.path`                                           | `/metrics`                                              | Chemin de l'endpoint de métriques |
| `metrics.serviceMonitor.enabled`                         | `false`                                                 | Si un ServiceMonitor doit être créé pour permettre à Prometheus Operator de gérer la collecte des métriques ; notez que l'activation de cette option supprime les annotations de collecte `prometheus.io` |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                    | Labels supplémentaires à ajouter au ServiceMonitor |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                    | Configuration d'endpoint supplémentaire pour le ServiceMonitor |
| `metrics.annotations`                                    |                                                         | **DEPRECATED** Définit des annotations de métriques explicites. Remplacé par le contenu du template. |
| `metrics.tls.enabled`                                    | `false`                                                 | TLS activé pour l'endpoint de métriques |
| `metrics.tls.secretName`                                 | `{Release.Name}-pages-metrics-tls`                      | Secret pour le certificat et la clé TLS de l'endpoint de métriques |
| `priorityClassName`                                      |                                                         | [Classe de priorité](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) assignée aux pods. |
| `podLabels`                                              |                                                         | Labels de pod supplémentaires. Ne sera pas utilisé pour les sélecteurs. |
| `resources.requests.cpu`                                 | `900m`                                                  | CPU minimum de GitLab Pages |
| `resources.requests.memory`                              | `2G`                                                    | Mémoire minimum de GitLab Pages |
| `securityContext.fsGroup`                                | `1000`                                                  | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.runAsUser`                              | `1000`                                                  | ID d'utilisateur sous lequel le pod doit être démarré |
| `securityContext.fsGroupChangePolicy`                    |                                                         | Politique de modification de la propriété et des permissions du volume (nécessite Kubernetes 1.23) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                        | Profil Seccomp à utiliser |
| `containerSecurityContext`                               |                                                         | Remplacer le [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel le conteneur est démarré |
| `containerSecurityContext.runAsUser`                     | `1000`                                                  | Permet de remplacer l'ID d'utilisateur du contexte de sécurité spécifique sous lequel le conteneur est démarré |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                 | Contrôle si un processus du conteneur peut acquérir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                  | Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                             | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `service.externalPort`                                   | `8090`                                                  | Port exposé de GitLab Pages |
| `service.internalPort`                                   | `8090`                                                  | Port interne de GitLab Pages |
| `service.name`                                           | `gitlab-pages`                                          | Nom du service GitLab Pages |
| `service.annotations`                                    |                                                         | Annotations pour tous les services Pages. |
| `service.primary.annotations`                            |                                                         | Annotations pour le service principal uniquement. |
| `service.metrics.annotations`                            |                                                         | Annotations pour le service de métriques uniquement. |
| `service.customDomains.annotations`                      |                                                         | Annotations pour le service de domaines personnalisés uniquement. |
| `service.customDomains.type`                             | `LoadBalancer`                                          | Type de service créé pour gérer les domaines personnalisés |
| `service.customDomains.internalHttpsPort`                | `8091`                                                  | Port sur lequel le daemon Pages écoute les requêtes HTTPS |
| `service.customDomains.internalHttpsPort`                | `8091`                                                  | Port sur lequel le daemon Pages écoute les requêtes HTTPS |
| `service.customDomains.nodePort.http`                    |                                                         | Port de nœud à ouvrir pour les connexions HTTP. Valide uniquement si `service.customDomains.type` est `NodePort` |
| `service.customDomains.nodePort.https`                   |                                                         | Port de nœud à ouvrir pour les connexions HTTPS. Valide uniquement si `service.customDomains.type` est `NodePort` |
| `service.sessionAffinity`                                | `None`                                                  | Type d'affinité de session. La valeur doit être `ClientIP` ou `None` (cette option n’a de sens que pour le trafic provenant de l’intérieur du cluster) |
| `service.sessionAffinityConfig`                          |                                                         | Configuration de l'affinité de session. Si `service.sessionAffinity` == `ClientIP`, la durée de session persistante par défaut est de 3 heures (`10800`) |
| `serviceAccount.annotations`                             | `{}`                                                    | Annotations du ServiceAccount |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                 | Indique si le token d'accès par défaut du ServiceAccount doit être monté dans les pods |
| `serviceAccount.create`                                  | `false`                                                 | Indique si un ServiceAccount doit être créé |
| `serviceAccount.enabled`                                 | `false`                                                 | Indique si un ServiceAccount doit être utilisé |
| `serviceAccount.name`                                    |                                                         | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé |
| `serviceLabels`                                          | `{}`                                                    | Labels de service supplémentaires |
| `tolerations`                                            | `[]`                                                    | Labels de tolérance pour l'attribution des pods |

### Paramètres spécifiques à Pages {#pages-specific-settings}

| Paramètre                   | Défaut | Description |
|-----------------------------|---------|-------------|
| `artifactsServerTimeout`    | `10`    | Délai d'attente (en secondes) pour une requête mandatée vers le serveur d'artefacts |
| `artifactsServerUrl`        |         | URL d'API vers laquelle mandater les requêtes d'artefacts |
| `extraVolumeMounts`         |         | Liste de montages de volumes supplémentaires à ajouter |
| `extraVolumes`              |         | Liste de volumes supplémentaires à créer |
| `gitlabCache.cleanup`       | int     | Voir :  [Paramètres globaux de Pages](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabCache.expiry`        | int     | Voir :  [Paramètres globaux de Pages](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabCache.refresh`       | int     | Voir :  [Paramètres globaux de Pages](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabClientHttpTimeout`   |         | Délai d'expiration de la connexion du client HTTP à l'API GitLab en secondes |
| `gitlabClientJwtExpiry`     |         | Durée d'expiration du token JWT en secondes |
| `gitlabRetrieval.interval`  | int     | Voir :  [Paramètres globaux de Pages](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabRetrieval.retries`   | int     | Voir :  [Paramètres globaux de Pages](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabRetrieval.timeout`   | int     | Voir :  [Paramètres globaux de Pages](https://docs.gitlab.com/administration/pages/#global-settings) |
| `gitlabServer`              |         | FQDN du serveur GitLab |
| `headers`                   | `[]`    | Spécifiez les en-têtes HTTP supplémentaires à envoyer au client avec chaque réponse. Plusieurs en-têtes peuvent être donnés sous forme de tableau, l'en-tête et la valeur formant une seule chaîne, par exemple `['my-header: myvalue', 'my-other-header: my-other-value']` |
| `insecureCiphers`           | `false` | Utiliser la liste par défaut des suites de chiffrement, qui peut contenir des suites non sécurisées comme 3DES et RC4 |
| `internalGitlabServer`      |         | Serveur GitLab interne utilisé pour les requêtes API |
| `logFormat`                 | `json`  | Format de sortie des journaux |
| `logVerbose`                | `false` | Journalisation détaillée |
| `maxConnections`            |         | Limite du nombre de connexions simultanées aux listeners HTTP, HTTPS ou proxy |
| `maxURILength`              |         | Limite la longueur de l'URI, 0 pour illimité. Pour le paramètre par défaut, voir [les paramètres globaux de GitLab Pages](https://docs.gitlab.com/administration/pages/#global-settings) pour `max_uri_length` |
| `propagateCorrelationId`    |         | Réutilise le Correlation-ID existant de l'en-tête de requête entrante `X-Request-ID` si présent |
| `redirectHttp`              | `false` | Rediriger les pages de HTTP vers HTTPS |
| `sentry.enabled`            | `false` | Activer le reporting Sentry |
| `sentry.dsn`                |         | L'adresse à laquelle envoyer les rapports de plantage Sentry |
| `sentry.environment`        |         | L'environnement pour le reporting de plantage Sentry |
| `serverShutdowntimeout`     | `30s`   | Délai d'arrêt du serveur GitLab Pages en secondes |
| `statusUri`                 |         | Le chemin d'URL pour une page de statut |
| `tls.minVersion`            |         | Spécifie la version SSL/TLS minimale |
| `tls.maxVersion`            |         | Spécifie la version SSL/TLS maximale |
| `useHTTPProxy`              | `false` | Utilisez cette option lorsque GitLab Pages est derrière un proxy inverse. |
| `useProxyV2`                | `false` | Forcer les requêtes HTTPS à utiliser le protocole PROXYv2. |
| `zipCache.cleanup`          | int     | Voir :  [Configuration de la diffusion Zip et du cache](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipCache.expiration`       | int     | Voir :  [Configuration de la diffusion Zip et du cache](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipCache.refresh`          | int     | Voir :  [Configuration de la diffusion Zip et du cache](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipOpenTimeout`            | int     | Voir :  [Configuration de la diffusion Zip et du cache](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `zipHTTPClientTimeout`      | int     | Voir :  [Configuration de la diffusion Zip et du cache](https://docs.gitlab.com/administration/pages/#zip-serving-and-cache-configuration) |
| `rateLimitSourceIP`         |         | Voir :  [Limites de débit GitLab Pages](https://docs.gitlab.com/administration/pages/#rate-limits). |
| `rateLimitSourceIPBurst`    |         | Voir :  [Limites de débit GitLab Pages](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitDomain`           |         | Voir :  [Limites de débit GitLab Pages](https://docs.gitlab.com/administration/pages/#rate-limits). |
| `rateLimitDomainBurst`      |         | Voir :  [Limites de débit GitLab Pages](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitTLSSourceIP`      |         | Voir :  [Limites de débit GitLab Pages](https://docs.gitlab.com/administration/pages/#rate-limits). |
| `rateLimitTLSSourceIPBurst` |         | Voir :  [Limites de débit GitLab Pages](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitTLSDomain`        |         | Voir :  [Limites de débit GitLab Pages](https://docs.gitlab.com/administration/pages/#rate-limits). |
| `rateLimitTLSDomainBurst`   |         | Voir :  [Limites de débit GitLab Pages](https://docs.gitlab.com/administration/pages/#rate-limits) |
| `rateLimitSubnetsAllowList` |         | Voir :  [Limites de débit GitLab Pages](#rate-limits) |
| `serverReadTimeout`         | `5s`    | Voir :  [Paramètres globaux de GitLab Pages](https://docs.gitlab.com/administration/pages/#global-settings) |
| `serverReadHeaderTimeout`   | `1s`    | Voir :  [Paramètres globaux de GitLab Pages](https://docs.gitlab.com/administration/pages/#global-settings) |
| `serverWriteTimeout`        | `5m`    | Voir :  [Paramètres globaux de GitLab Pages](https://docs.gitlab.com/administration/pages/#global-settings) |
| `serverKeepAlive`           | `15s`   | Voir :  [Paramètres globaux de GitLab Pages](https://docs.gitlab.com/administration/pages/#global-settings) |
| `authTimeout`               | `5s`    | Voir :  [Paramètres globaux de GitLab Pages](https://docs.gitlab.com/administration/pages/#global-settings) |
| `authCookieSessionTimeout`  | `10m`   | Voir :  [Paramètres globaux de GitLab Pages](https://docs.gitlab.com/administration/pages/#global-settings) |

### Configuration de `ingress` {#configuring-the-ingress}

Cette section contrôle l'Ingress de GitLab Pages.

| Nom                   |  Type   | Défaut | Description |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | Chaîne  |         | Valeur à utiliser dans le champ `apiVersion`. |
| `annotations`          | Chaîne  |         | Ce champ correspond exactement au standard `annotations` pour [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/). |
| `configureCertmanager` | Booléen | `false` | Active/désactive l'annotation Ingress `cert-manager.io/issuer` et `acme.cert-manager.io/http01-edit-in-place`. L'acquisition d'un certificat TLS pour GitLab Pages via cert-manager est désactivée car l'acquisition d'un certificat générique nécessite un Issuer cert-manager avec un [solveur DNS01](https://cert-manager.io/docs/configuration/acme/dns01/) , et l'Issuer déployé par ce chart ne fournit qu'un [solveur HTTP01](https://cert-manager.io/docs/configuration/acme/http01/). Pour plus d'informations, voir les [exigences TLS pour GitLab Pages](../../../installation/tls.md). |
| `enabled`              | Booléen |         | Paramètre qui contrôle si des objets Ingress doivent être créés pour les services qui les prennent en charge. Si non défini, le paramètre `global.ingress.enabled` est utilisé. |
| `tls.enabled`          | Booléen |         | Lorsque défini à `false`, vous désactivez TLS pour le sous-chart Pages. Ceci est principalement utile dans les cas où vous ne pouvez pas utiliser la terminaison TLS au niveau `ingress-level`, comme lorsque vous avez un proxy de terminaison TLS devant l'Ingress Controller. |
| `tls.secretName`       | Chaîne  |         | Le nom du Secret TLS Kubernetes qui contient un certificat et une clé valides pour l'URL de Pages. Si non défini, `global.ingress.tls.secretName` est utilisé à la place. Non défini par défaut. |

## Exemples de configuration du chart {#chart-configuration-examples}

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

`extraVolumeMounts` vous permet de configurer des volumeMounts supplémentaires sur tous les conteneurs à l'échelle du chart.

Voici un exemple d'utilisation de `extraVolumeMounts` :

```yaml
extraVolumeMounts: |
  - name: example-volume
    mountPath: /etc/example
```

### Configuration de `networkpolicy` {#configuring-the-networkpolicy}

Cette section contrôle la [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). Cette configuration est facultative et permet de limiter le trafic Egress et Ingress des pods vers des endpoints spécifiques.

| Nom              |  Type   | Défaut | Description |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | Booléen | `false` | Ce paramètre active la `NetworkPolicy` |
| `ingress.enabled` | Booléen | `false` | Lorsque défini à `true`, la politique réseau `Ingress` est activée. Cela bloquera toutes les connexions Ingress sauf si des règles sont spécifiées. |
| `ingress.rules`   |  Tableau  | `[]`    | Règles pour la politique Ingress, pour plus de détails voir <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> et l'exemple ci-dessous |
| `egress.enabled`  | Booléen | `false` | Lorsque défini à `true`, la politique réseau `Egress` est activée. Cela bloquera toutes les connexions egress sauf si des règles sont spécifiées. |
| `egress.rules`    |  Tableau  | `[]`    | Règles pour la politique egress, pour plus de détails voir <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> et l'exemple ci-dessous |

### Exemple de politique réseau {#example-network-policy}

Le service `gitlab-pages` nécessite des connexions Ingress sur les ports 80 et 443 et des connexions Egress vers divers endpoints jusqu'au port workhorse par défaut 8181. Cet exemple ajoute la politique réseau suivante :

- Autorise les requêtes Ingress :
  - Depuis le pod `nginx-ingress` vers le port `8090`
  - Depuis le pod `prometheus` vers le port `9235`
- Autorise les requêtes Egress :
  - Vers `kube-dns` sur le port `53`
  - Vers le pod `webservice` sur le port `8181`
  - Vers des endpoints comme l'endpoint VPC AWS pour S3 `172.16.1.0/24` sur le port `443`

L'exemple fourni n'est qu'un exemple et peut ne pas être complet. L'exemple est basé sur l'hypothèse que `kube-dns` a été déployé dans l'espace de nommage `kube-system`, `prometheus` a été déployé dans l'espace de nommage `monitoring` et `nginx-ingress` a été déployé dans l'espace de nommage `nginx-ingress`.

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
          - port: 9235
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 8090
  egress:
    enabled: true
    rules:
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
              cidr: 172.16.1.0/24
        ports:
          - port: 443
      - to:
          - podSelector:
              matchLabels:
                app: webservice
        ports:
          - port: 8181
```

### Accès TLS à GitLab Pages {#tls-access-to-gitlab-pages}

Pour bénéficier de l'accès TLS à la fonctionnalité GitLab Pages, vous devez :

1. Créez un certificat générique dédié pour votre domaine GitLab Pages dans ce format : `*.pages.<yourdomain>`.

1. Créez le secret dans Kubernetes :

   ```shell
   kubectl create secret tls tls-star-pages-<mysecret> --cert=<path/to/fullchain.pem> --key=<path/to/privkey.pem>
   ```

1. Configurez GitLab Pages pour utiliser ce secret :

   ```yaml
   gitlab:
     gitlab-pages:
       ingress:
         tls:
           secretName: tls-star-pages-<mysecret>
   ```

1. Créez une entrée DNS chez votre fournisseur DNS avec le nom `*.pages.<yourdomaindomain>` pointant vers votre LoadBalancer.

### Domaine Pages sans DNS générique {#pages-domain-without-wildcard-dns}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5570) en tant que version [bêta](https://docs.gitlab.com/policy/development_stages_support/#beta) dans GitLab 17.2.
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/483365) dans GitLab 17.4.

{{< /history >}}

> [!warning]
> GitLab Pages ne prend en charge qu'un seul schéma d'URL à la fois :  Soit avec un DNS générique, soit sans DNS générique. Si vous activez `namespaceInPath`, les sites web GitLab Pages existants ne seront accessibles que sur des domaines sans DNS générique.

1. Activez `namespaceInPath` dans les paramètres globaux de Pages.

   ```yaml
   global:
     pages:
       namespaceInPath: true
   ```

1. Créez une entrée DNS chez votre fournisseur DNS avec le nom `pages.<yourdomaindomain>` pointant vers votre LoadBalancer.

#### Accès TLS au domaine GitLab Pages sans DNS générique {#tls-access-to-gitlab-pages-domain-without-wildcard-dns}

1. Créez un certificat pour votre domaine GitLab Pages dans ce format : `pages.<yourdomain>`.
1. Créez le secret dans Kubernetes :

   ```shell
   kubectl create secret tls tls-star-pages-<mysecret> --cert=<path/to/fullchain.pem> --key=<path/to/privkey.pem>
   ```

1. Configurez GitLab Pages pour utiliser ce secret :

   ```yaml
   gitlab:
     gitlab-pages:
       ingress:
         tls:
           secretName: tls-star-pages-<mysecret>
   ```

#### Configurer le contrôle d'accès {#configure-access-control}

1. Activez `accessControl` dans les paramètres globaux de Pages.

   ```yaml
   global:
     pages:
       accessControl: true
   ```

1. Facultatif. Si [l'accès TLS](#tls-access-to-gitlab-pages-domain-without-wildcard-dns) est configuré, mettez à jour l'URI de redirection dans l'[application OAuth système](https://docs.gitlab.com/integration/oauth_provider/#create-an-instance-wide-application) de GitLab Pages pour utiliser le protocole HTTPS.

> [!warning]
> GitLab Pages ne met pas à jour l'application OAuth, et la valeur `authRedirectUri` par défaut est mise à jour vers `https://pages.<yourdomaindomain>/projects/auth`. Lors de l'accès à un site Pages privé, si vous rencontrez l'erreur « L'URI de redirection incluse n'est pas valide », mettez à jour l'URI de redirection dans l'[application OAuth système](https://docs.gitlab.com/integration/oauth_provider/#create-an-instance-wide-application) de GitLab Pages vers `https://pages.<yourdomaindomain>/projects/auth`.

### Limites de débit {#rate-limits}

Vous pouvez appliquer des limites de débit pour minimiser le risque d'attaque par déni de service (DoS). Une [documentation détaillée sur les limites de débit](https://docs.gitlab.com/administration/pages/#rate-limits) est disponible.

Pour autoriser certaines plages IP (sous-réseaux) à contourner toutes les limites de débit :

- `rateLimitSubnetsAllowList` :  Définit la liste d'autorisation avec les plages IP (sous-réseaux) qui doivent contourner toutes les limites de débit.

#### Configurer la liste d'autorisation des sous-réseaux pour les limites de débit {#configure-rate-limits-subnets-allow-list}

Définissez la liste d'autorisation avec les plages IP (sous-réseaux) dans `charts/gitlab/charts/gitlab-pages/values.yaml` :

```yaml
gitlab:
  gitlab-pages:
    rateLimitSubnetsAllowList:
     - "1.2.3.4/24"
     - "2001:db8::1/32"
```

### Configuration de KEDA {#configuring-keda}

Cette section `keda` active l'installation de [KEDA](https://keda.sh/) `ScaledObjects` à la place des `HorizontalPodAutoscalers` classiques. Cette configuration est facultative et peut être utilisée lorsqu'une mise à l'échelle automatique basée sur des métriques personnalisées ou externes est nécessaire.

La plupart des paramètres utilisent par défaut les valeurs définies dans la section `hpa` le cas échéant.

Si les conditions suivantes sont remplies, des déclencheurs CPU et mémoire sont ajoutés automatiquement en fonction des seuils CPU et mémoire définis dans la section `hpa` :

- `triggers` n'est pas défini.
- Le paramètre `request.cpu.request` ou `request.memory.request` correspondant est également défini à une valeur non nulle.

Si aucun déclencheur n'est défini, le `ScaledObject` n'est pas créé.

Consultez la [documentation KEDA](https://keda.sh/docs/2.10/concepts/scaling-deployments/) pour plus de détails sur ces paramètres.

| Nom                            |  Type   | Défaut                         | Description |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | Booléen | `false`                         | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` à la place de `HorizontalPodAutoscalers` |
| `pollingInterval`               | Entier | `30`                            | L'intervalle auquel vérifier chaque déclencheur |
| `cooldownPeriod`                | Entier | `300`                           | La période d'attente après que le dernier déclencheur a signalé une activité avant de remettre la ressource à l'échelle à 0 |
| `minReplicaCount`               | Entier | `hpa.minReplicas`               | Nombre minimum de réplicas vers lesquels KEDA peut réduire la ressource. |
| `maxReplicaCount`               | Entier | `hpa.maxReplicas`               | Nombre maximum de réplicas vers lesquels KEDA peut augmenter la ressource. |
| `fallback`                      |   Map   |                                 | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `hpaName`                       | Chaîne  | `keda-hpa-{scaled-object-name}` | Le nom de la ressource HPA que KEDA créera. |
| `restoreToOriginalReplicaCount` | Booléen |                                 | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `behavior`                      |   Map   | `hpa.behavior`                  | Les spécifications pour le comportement de mise à l'échelle ascendant et descendant. |
| `triggers`                      |  Tableau  |                                 | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |

### serviceAccount {#serviceaccount}

Cette section contrôle si un ServiceAccount doit être créé et si le token d'accès par défaut doit être monté dans les pods.

| Nom                           |  Type   | Défaut | Description |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   Map   | `{}`    | Annotations du ServiceAccount. |
| `automountServiceAccountToken` | Booléen | `false` | Contrôle si le token d'accès par défaut du ServiceAccount doit être monté dans les pods. Vous ne devez pas activer ceci sauf si cela est requis par certains sidecars pour fonctionner correctement (par exemple, Istio). |
| `create`                       | Booléen | `false` | Indique si un ServiceAccount doit être créé. |
| `enabled`                      | Booléen | `false` | Indique si un ServiceAccount doit être utilisé. |
| `name`                         | Chaîne  |         | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé. |

### affinity {#affinity}

Pour plus d'informations, voir [`affinity`](../_index.md#affinity).
