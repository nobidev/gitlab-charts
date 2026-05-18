---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du chart GitLab Webservice
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le sous-chart `webservice` fournit le serveur web GitLab Rails avec deux workers Webservice par pod, ce qui est le minimum nécessaire pour qu'un seul pod puisse traiter toute requête web dans GitLab.

Les pods de ce chart utilisent deux conteneurs : `gitlab-workhorse` et `webservice`. [GitLab Workhorse](https://gitlab.com/gitlab-org/gitlab/-/tree/master/workhorse) écoute sur le port `8181` et doit _toujours_ être la destination du trafic entrant vers le pod. Le `webservice` héberge la [base de code Rails](https://gitlab.com/gitlab-org/gitlab) de GitLab, écoute sur `8080` et est accessible à des fins de collecte de métriques. `webservice` ne doit jamais recevoir de trafic normal directement.

## Prérequis {#requirements}

Ce chart dépend des services Redis, PostgreSQL, Gitaly et Registry, soit dans le cadre du chart GitLab complet, soit fournis comme services externes accessibles depuis le cluster Kubernetes sur lequel ce chart est déployé.

## Configuration {#configuration}

Le chart `webservice` est configuré comme suit :  [Paramètres globaux](#global-settings) , [Paramètres des déploiements](#deployments-settings) , [Paramètres Ingress](#ingress-settings) , [Services externes](#external-services) et [Paramètres du chart](#chart-settings).

## Options de ligne de commande d'installation {#installation-command-line-options}

Le tableau ci-dessous contient toutes les configurations de chart possibles pouvant être fournies à la commande `helm install` via les flags `--set`.

| Paramètre                                                     | Défaut                                                         | Description |
|---------------------------------------------------------------|-----------------------------------------------------------------|-------------|
| `annotations`                                                 |                                                                 | Annotations de pod |
| `podLabels`                                                   |                                                                 | Labels de Pod supplémentaires. Ne sera pas utilisé pour les sélecteurs. |
| `common.labels`                                               |                                                                 | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `deployment.terminationGracePeriodSeconds`                    | `30`                                                            | Secondes pendant lesquelles Kubernetes attendra qu'un pod se termine ; notez que cela doit être supérieur à `shutdown.blackoutSeconds` |
| `deployment.livenessProbe.initialDelaySeconds`                | `20`                                                            | Délai avant le lancement de la sonde de vivacité |
| `deployment.livenessProbe.periodSeconds`                      | `60`                                                            | Fréquence d'exécution de la sonde de vivacité |
| `deployment.livenessProbe.timeoutSeconds`                     | `30`                                                            | Délai d'expiration de la sonde de vivacité |
| `deployment.livenessProbe.successThreshold`                   | `1`                                                             | Nombre minimum de succès consécutifs pour que la sonde de vivacité soit considérée comme réussie après un échec |
| `deployment.livenessProbe.failureThreshold`                   | `3`                                                             | Nombre minimum d'échecs consécutifs pour que la sonde de vivacité soit considérée comme échouée après un succès |
| `deployment.readinessProbe.initialDelaySeconds`               | `0`                                                             | Délai avant le lancement de la sonde de disponibilité |
| `deployment.readinessProbe.periodSeconds`                     | `10`                                                            | Fréquence d'exécution de la sonde de disponibilité |
| `deployment.readinessProbe.timeoutSeconds`                    | `2`                                                             | Délai d'expiration de la sonde de disponibilité |
| `deployment.readinessProbe.successThreshold`                  | `1`                                                             | Nombre minimum de succès consécutifs pour que la sonde de disponibilité soit considérée comme réussie après un échec |
| `deployment.readinessProbe.failureThreshold`                  | `3`                                                             | Nombre minimum d'échecs consécutifs pour que la sonde de disponibilité soit considérée comme échouée après un succès |
| `deployment.strategy`                                         | `{}`                                                            | Permet de configurer la stratégie de mise à jour utilisée par le déploiement. Si non fourni, la valeur par défaut du cluster est utilisée. |
| `enabled`                                                     | `true`                                                          | Indicateur d'activation de Webservice |
| `extraContainers`                                             |                                                                 | Chaîne de style littéral multiligne contenant une liste de conteneurs à inclure |
| `extraInitContainers`                                         |                                                                 | Liste de conteneurs init supplémentaires à inclure |
| `extras.google_analytics_id`                                  | `nil`                                                           | ID Google Analytics pour le frontend |
| `extraVolumeMounts`                                           |                                                                 | Liste de montages de volumes supplémentaires à effectuer |
| `extraVolumes`                                                |                                                                 | Liste de volumes supplémentaires à créer |
| `extraEnv`                                                    |                                                                 | Liste de variables d'environnement supplémentaires à exposer |
| `extraEnvFrom`                                                |                                                                 | Liste des variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| `gitlab.webservice.workhorse.image`                           | `registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ee`  | Dépôt d'images Workhorse |
| `gitlab.webservice.workhorse.tag`                             |                                                                 | Tag d'image Workhorse |
| `hpa.behavior`                                                | `{scaleDown: {stabilizationWindowSeconds: 300 }}`               | Behavior contient les spécifications pour le comportement de mise à l'échelle automatique ascendant et descendant (nécessite `autoscaling/v2beta2` ou version supérieure) |
| `hpa.customMetrics`                                           | `[]`                                                            | Les métriques personnalisées contiennent les spécifications à utiliser pour calculer le nombre de réplicas souhaité (remplace l'utilisation par défaut de la consommation CPU moyenne configurée dans `targetAverageUtilization`) |
| `hpa.cpu.targetType`                                          | `AverageValue`                                                  | Définit le type cible du CPU pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.cpu.targetAverageValue`                                  | `1`                                                             | Définit la valeur cible CPU pour la mise à l'échelle automatique |
| `hpa.cpu.targetAverageUtilization`                            |                                                                 | Définit la consommation cible CPU pour la mise à l'échelle automatique |
| `hpa.memory.targetType`                                       |                                                                 | Définit le type cible de la mémoire pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.memory.targetAverageValue`                               |                                                                 | Définit la valeur cible mémoire pour la mise à l'échelle automatique |
| `hpa.memory.targetAverageUtilization`                         |                                                                 | Définit la consommation cible mémoire pour la mise à l'échelle automatique |
| `hpa.targetAverageValue`                                      |                                                                 | **DEPRECATED** Définit la valeur cible CPU pour la mise à l'échelle automatique |
| `sshHostKeys.mount`                                           | `false`                                                         | Indique s'il faut monter le secret GitLab Shell contenant les clés SSH publiques. |
| `sshHostKeys.mountName`                                       | `ssh-host-keys`                                                 | Nom du volume monté. |
| `sshHostKeys.types`                                           | `[dsa,rsa,ecdsa,ed25519]`                                       | Liste des types de clés SSH à monter. |
| `image.pullPolicy`                                            | `Always`                                                        | Politique de récupération d'image Webservice |
| `image.pullSecrets`                                           |                                                                 | Secrets pour le dépôt d'images |
| `image.repository`                                            | `registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ee` | Dépôt d'images Webservice |
| `image.tag`                                                   |                                                                 | Tag d'image Webservice |
| `init.image.repository`                                       |                                                                 | Image initContainer |
| `init.image.tag`                                              |                                                                 | Tag d'image initContainer |
| `init.containerSecurityContext.runAsUser`                     | `1000`                                                          | Spécifique à initContainer :  ID utilisateur sous lequel le conteneur doit être démarré |
| `init.containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                         | Spécifique à initContainer :  Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsNonRoot`                  | `true`                                                          | Spécifique à initContainer :  Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `init.containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                     | Spécifique à initContainer :  Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur |
| `keda.enabled`                                                | `false`                                                         | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` à la place de `HorizontalPodAutoscalers` |
| `keda.pollingInterval`                                        | `30`                                                            | L'intervalle auquel vérifier chaque déclencheur |
| `keda.cooldownPeriod`                                         | `300`                                                           | La période d'attente après que le dernier déclencheur a signalé une activité avant de remettre la ressource à l'échelle à 0 |
| `keda.minReplicaCount`                                        | `minReplicas`                                                   | Nombre minimum de réplicas vers lesquels KEDA peut réduire la ressource. |
| `keda.maxReplicaCount`                                        | `maxReplicas`                                                   | Nombre maximum de réplicas vers lesquels KEDA peut augmenter la ressource. |
| `keda.fallback`                                               |                                                                 | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `keda.hpaName`                                                | `keda-hpa-{scaled-object-name}`                                 | Le nom de la ressource HPA que KEDA créera. |
| `keda.restoreToOriginalReplicaCount`                          |                                                                 | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `keda.behavior`                                               | `hpa.behavior`                                                  | Les spécifications pour le comportement de mise à l'échelle ascendant et descendant. |
| `keda.triggers`                                               |                                                                 | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |
| `metrics.enabled`                                             | `true`                                                          | Indique si un endpoint de métriques doit être disponible pour le scraping |
| `metrics.port`                                                | `8083`                                                          | Port de l'endpoint de métriques |
| `metrics.listenAddr`                                          | `0.0.0.0`                                                       | Adresse d'écoute des métriques. |
| `metrics.path`                                                | `/metrics`                                                      | Chemin de l'endpoint de métriques |
| `metrics.serviceMonitor.enabled`                              | `false`                                                         | Indique si un ServiceMonitor doit être créé pour permettre à l'opérateur Prometheus de gérer le scraping des métriques ; notez que l'activation de cette option supprime les annotations de scraping `prometheus.io` |
| `metrics.serviceMonitor.additionalLabels`                     | `{}`                                                            | Labels supplémentaires à ajouter au ServiceMonitor |
| `metrics.serviceMonitor.endpointConfig`                       | `{}`                                                            | Configuration d'endpoint supplémentaire pour le ServiceMonitor |
| `metrics.annotations`                                         |                                                                 | **DEPRECATED** Définit des annotations de métriques explicites. Remplacé par le contenu du template. |
| `metrics.tls.enabled`                                         |                                                                 | TLS activé pour l'endpoint metrics/web_exporter. Par défaut `tls.enabled`. |
| `metrics.tls.secretName`                                      |                                                                 | Secret pour le certificat TLS et la clé de l'endpoint metrics/web_exporter. Par défaut `tls.secretName`. |
| `minio.bucket`                                                | `git-lfs`                                                       | Nom du bucket de stockage, lors de l'utilisation de MinIO |
| `minio.port`                                                  | `9000`                                                          | Port du service MinIO |
| `minio.serviceName`                                           | `minio-svc`                                                     | Nom du service MinIO |
| `monitoring.ipWhitelist`                                      | `[0.0.0.0/0, ::/0]`                                             | Liste des adresses IP à autoriser pour les endpoints de monitoring |
| `monitoring.exporter.listenAddr`                              | `0.0.0.0`                                                       | Adresse d'écoute des métriques. |
| `monitoring.exporter.enabled`                                 | `false`                                                         | Active le serveur web pour exposer les métriques Prometheus, remplacé par `metrics.enabled` si le port de métriques est défini sur le port de l'exportateur de monitoring |
| `monitoring.exporter.port`                                    | `8083`                                                          | Numéro de port à utiliser pour l'exportateur de métriques |
| `psql.password.key`                                           | `psql-password`                                                 | Clé du mot de passe psql dans le secret psql |
| `psql.password.secret`                                        | `gitlab-postgres`                                               | Nom du secret psql |
| `psql.port`                                                   |                                                                 | Définit le port du serveur PostgreSQL. A la priorité sur `global.psql.port` |
| `puma.disableWorkerKiller`                                    | `true`                                                          | Désactive le worker memory killer de Puma |
| `puma.workerMaxMemory`                                        |                                                                 | La mémoire maximale (en mégaoctets) pour le worker killer de Puma |
| `puma.threads.min`                                            | `4`                                                             | Nombre minimal de threads Puma |
| `puma.threads.max`                                            | `4`                                                             | Nombre maximal de threads Puma |
| `puma.bindIp6`                                                | `false`                                                         | Lier des adresses IPv6 avec Puma. Par défaut false en raison d'un [problème connu](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6084) lié à la limite de débit. |
| `rack_attack.git_basic_auth`                                  | `{}`                                                            | Voir la [documentation GitLab](https://docs.gitlab.com/administration/settings/protected_paths/) pour plus de détails |
| `global.registry.api.port`                                    | `5000`                                                          | Port du Registry |
| `global.registry.api.protocol`                                | `http`                                                          | Protocole du Registry |
| `global.registry.api.serviceName`                             | `registry`                                                      | Nom du service Registry |
| `global.registry.enabled`                                     | `true`                                                          | Ajouter/Supprimer le lien du Registry dans le menu de tous les projets |
| `global.registry.tokenIssuer`                                 | `gitlab-issuer`                                                 | Émetteur de jeton du Registry |
| `replicaCount`                                                | `1`                                                             | Nombre de réplicas Webservice |
| `resources.requests.cpu`                                      | `300m`                                                          | CPU minimum Webservice |
| `resources.requests.memory`                                   | `1.5G`                                                          | Mémoire minimale Webservice |
| `service.externalPort`                                        | `8080`                                                          | Port exposé de Webservice |
| `securityContext.fsGroup`                                     | `1000`                                                          | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.runAsUser`                                   | `1000`                                                          | ID utilisateur sous lequel le pod doit être démarré |
| `securityContext.fsGroupChangePolicy`                         |                                                                 | Politique de modification de la propriété et des permissions du volume (nécessite Kubernetes 1.23) |
| `securityContext.seccompProfile.type`                         | `RuntimeDefault`                                                | Profil Seccomp à utiliser |
| `containerSecurityContext`                                    |                                                                 | Remplace le [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel le conteneur est démarré |
| `containerSecurityContext.runAsUser`                          | `1000`                                                          | Permet de remplacer l'ID utilisateur du contexte de sécurité spécifique sous lequel le conteneur est démarré |
| `containerSecurityContext.allowPrivilegeEscalation`           | `false`                                                         | Contrôle si un processus du conteneur Gitaly peut obtenir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`                       | `true`                                                          | Contrôle si le conteneur Gitaly s'exécute avec un utilisateur non root |
| `containerSecurityContext.capabilities.drop`                  | `[ "ALL" ]`                                                     | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `serviceAccount.automountServiceAccountToken`                 | `false`                                                         | Indique si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods |
| `serviceAccount.create`                                       | `false`                                                         | Indique si un ServiceAccount doit être créé |
| `serviceAccount.enabled`                                      | `false`                                                         | Indique si un ServiceAccount doit être utilisé |
| `serviceAccount.name`                                         |                                                                 | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé |
| `serviceLabels`                                               | `{}`                                                            | Labels de service supplémentaires |
| `service.internalPort`                                        | `8080`                                                          | Port interne de Webservice |
| `service.type`                                                | `ClusterIP`                                                     | Type de service Webservice |
| `service.workhorseExternalPort`                               | `8181`                                                          | Port exposé de Workhorse |
| `service.workhorseInternalPort`                               | `8181`                                                          | Port interne de Workhorse |
| `service.loadBalancerIP`                                      |                                                                 | Adresse IP à attribuer au LoadBalancer (si pris en charge par le fournisseur cloud) |
| `service.loadBalancerSourceRanges`                            |                                                                 | Liste des CIDR IP autorisés à accéder au LoadBalancer (si pris en charge). Requis pour service.type = LoadBalancer |
| `shell.authToken.key`                                         | `secret`                                                        | Clé du jeton shell dans le secret shell |
| `shell.authToken.secret`                                      | `{Release.Name}-gitlab-shell-secret`                            | Secret du jeton shell |
| `shell.port`                                                  | `nil`                                                           | Numéro de port à utiliser dans les URLs SSH générées par l'interface utilisateur |
| `shutdown.blackoutSeconds`                                    | `10`                                                            | Nombre de secondes pendant lesquelles Webservice continue de fonctionner après la réception de l'arrêt. Doit être inférieur à `deployment.terminationGracePeriodSeconds`. Configure également le délai d'arrêt de l'écouteur de vérification de santé workhorse s'il est activé. |
| `tls.enabled`                                                 | `false`                                                         | TLS Webservice activé |
| `tls.secretName`                                              | `{Release.Name}-webservice-tls`                                 | Secrets TLS Webservice. `secretName` doit pointer vers un [secret TLS Kubernetes](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets). |
| `tolerations`                                                 | `[]`                                                            | Labels de tolérance pour l'affectation des pods |
| `trusted_proxies`                                             | `[]`                                                            | Voir la [documentation GitLab](https://docs.gitlab.com/install/installation/#adding-your-trusted-proxies) pour plus de détails |
| `workhorse.logFormat`                                         | `json`                                                          | Format de journalisation. Formats valides : `json`, `structured`, `text` |
| `workerProcesses`                                             | `2`                                                             | Nombre de workers Webservice |
| `workhorse.keywatcher`                                        | `true`                                                          | Abonne Workhorse à Redis. Ceci est **required** par tout déploiement traitant des requêtes vers `/api/*`, mais peut être désactivé sans risque pour les autres déploiements |
| `workhorse.shutdownTimeout`                                   | `global.webservice.workerTimeout + 1` (secondes)                 | Temps d'attente pour que toutes les requêtes web se vident de Workhorse. Exemples : `1min`, `65s`. |
| `workhorse.adoptCfRayHeader`                                  | `false`                                                         | Adopter l'en-tête entrant `Cf-Ray` comme Correlation-ID s'il est présent. Voir la [documentation Workhorse](https://docs.gitlab.com/development/workhorse/configuration/#propagate-correlation-ids) pour plus de détails. |
| `workhorse.trustedCIDRsForPropagation`                        |                                                                 | Une liste de blocs CIDR qui peuvent être approuvés pour la propagation d'un ID de corrélation. L'option `-propagateCorrelationID` doit également être utilisée dans `workhorse.extraArgs` pour que cela fonctionne. Voir la [documentation Workhorse](https://docs.gitlab.com/development/workhorse/configuration/#propagate-correlation-ids) pour plus de détails. |
| `workhorse.trustedCIDRsForXForwardedFor`                      |                                                                 | Une liste de blocs CIDR pouvant être utilisés pour résoudre l'adresse IP réelle du client via l'en-tête HTTP `X-Forwarded-For`. Utilisé avec `workhorse.trustedCIDRsForPropagation`. Voir la [documentation Workhorse](https://docs.gitlab.com/development/workhorse/configuration/#trusted-proxies) pour plus de détails. |
| `workhorse.metadata.zipReaderLimitBytes`                      |                                                                 | Le nombre optionnel d'octets pour limiter le lecteur zip. Introduit dans GitLab 16.9. Voir la [documentation Workhorse](https://docs.gitlab.com/development/workhorse/configuration/#metadata-options) pour plus de détails. |
| `workhorse.containerSecurityContext`                          |                                                                 | Remplace le [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel le conteneur est démarré |
| `workhorse.containerSecurityContext.runAsUser`                | `1000`                                                          | ID utilisateur sous lequel le conteneur doit être démarré |
| `workhorse.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                         | Contrôle si un processus du conteneur peut obtenir plus de privilèges que son processus parent |
| `workhorse.containerSecurityContext.runAsNonRoot`             | `true`                                                          | Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `workhorse.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                     | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `workhorse.livenessProbe.initialDelaySeconds`                 | `20`                                                            | Délai avant le lancement de la sonde de vivacité |
| `workhorse.livenessProbe.periodSeconds`                       | `60`                                                            | Fréquence d'exécution de la sonde de vivacité |
| `workhorse.livenessProbe.timeoutSeconds`                      | `30`                                                            | Délai d'expiration de la sonde de vivacité |
| `workhorse.livenessProbe.successThreshold`                    | `1`                                                             | Nombre minimum de succès consécutifs pour que la sonde de vivacité soit considérée comme réussie après un échec |
| `workhorse.livenessProbe.failureThreshold`                    | `3`                                                             | Nombre minimum d'échecs consécutifs pour que la sonde de vivacité soit considérée comme échouée après un succès |
| `workhorse.healthcheckListener.enabled`                       | `false`                                                         | Active l'écouteur de vérification de santé Workhorse et désactive la sonde de disponibilité Puma par défaut. Permet de détecter l'état de disponibilité de manière plus fiable et avec moins d'instabilité. Introduit dans GitLab 18.5. |
| `workhorse.healthcheckListener.port`                          | `8182`                                                          | Numéro de port à utiliser pour l'écouteur de vérification de santé. |
| `workhorse.healthcheckListener.pumaControl`                   | `true`                                                          | Interroge l'application de contrôle Puma au lieu de l'endpoint de disponibilité Puma. |
| `workhorse.healthcheckListener.checkInterval`                 | `10s`                                                           | Intervalle de temps entre les vérifications consécutives de l'état de santé du serveur Puma en amont. |
| `workhorse.healthcheckListener.timeout`                       | `5s`                                                            | Délai d'expiration des requêtes de vérification Puma. |
| `workhorse.healthcheckListener.maxConsecutiveFailures`        | `1`                                                             | Nombre d'échecs avant de marquer Workhorse comme non prêt. |
| `workhorse.healthcheckListener.minSuccessfullProbes`          | `1`                                                             | Nombre de sondes réussies avant que Workhorse soit considéré comme prêt. |
| `workhorse.healthcheckListener.railsSkipInterval`             | `0s`                                                            | Délai avant la reprise des vérifications de disponibilité Puma après le traitement réussi d'une requête. Désactivé par défaut. |
| `workhorse.loadShedding.enabled`                              | `false`                                                         | Active le délestage de charge pour retourner `503` lorsque le backlog de requêtes de Puma dépasse le seuil. |
| `workhorse.loadShedding.backlogThreshold`                     | `50`                                                            | Seuil de backlog à partir duquel commencer le délestage de charge. |
| `workhorse.loadShedding.backlogHysteresis`                    | `0.8`                                                           | Facteur d'hystérésis pour la désactivation (de 0,0 à 1,0). Le délestage de charge se désactive lorsque le backlog descend en dessous du seuil * l'hystérésis. |
| `workhorse.loadShedding.retryAfterSeconds`                    | `0`                                                             | Valeur de l'en-tête Retry-After en secondes lors du délestage de charge. Utilisez 0 pour une nouvelle tentative immédiate (recommandé pour Kubernetes). |
| `workhorse.loadShedding.statusCode`                           | `503`                                                           | Code de statut HTTP à retourner lors du délestage de charge. Utilisez un code personnalisé tel que `529` pour distinguer les réponses de délestage de charge des autres erreurs `503`. |
| `workhorse.loadShedding.strategy`                             | `max`                                                           | Stratégie de calcul du backlog effectif : « max » (par défaut) ou « sum ». |
| `workhorse.loadShedding.checkInterval`                        | `1s`                                                            | Fréquence d'échantillonnage des métriques de backlog de Puma. Indépendant de l'intervalle de vérification de santé. |
| `workhorse.loadShedding.timeout`                              | `5s`                                                            | Délai d'expiration pour les requêtes du serveur de contrôle. |
| `workhorse.monitoring.exporter.enabled`                       | `false`                                                         | Active Workhorse pour exposer les métriques Prometheus, remplacé par `workhorse.metrics.enabled` |
| `workhorse.monitoring.exporter.port`                          | `9229`                                                          | Numéro de port à utiliser pour les métriques Prometheus de Workhorse |
| `workhorse.monitoring.exporter.tls.enabled`                   | `false`                                                         | Lorsque défini sur `true`, active le TLS sur l'endpoint de métriques. Nécessite que [le TLS soit activé pour Workhorse](#gitlab-workhorse). |
| `workhorse.metrics.enabled`                                   | `true`                                                          | Indique si un endpoint de métriques Workhorse doit être disponible pour la collecte |
| `workhorse.metrics.port`                                      | `8083`                                                          | Port de l'endpoint de métriques Workhorse |
| `workhorse.metrics.path`                                      | `/metrics`                                                      | Chemin de l'endpoint de métriques Workhorse |
| `workhorse.metrics.serviceMonitor.enabled`                    | `false`                                                         | Indique si un ServiceMonitor doit être créé pour permettre à Prometheus Operator de gérer la collecte des métriques Workhorse |
| `workhorse.metrics.serviceMonitor.additionalLabels`           | `{}`                                                            | Labels supplémentaires à ajouter au ServiceMonitor Workhorse |
| `workhorse.metrics.serviceMonitor.endpointConfig`             | `{}`                                                            | Configuration d'endpoint supplémentaire pour le ServiceMonitor Workhorse |
| `workhorse.readinessProbe.initialDelaySeconds`                | `0`                                                             | Délai avant le lancement de la sonde de disponibilité |
| `workhorse.readinessProbe.periodSeconds`                      | `10`                                                            | Fréquence d'exécution de la sonde de disponibilité |
| `workhorse.readinessProbe.timeoutSeconds`                     | `2`                                                             | Délai d'expiration de la sonde de disponibilité |
| `workhorse.readinessProbe.successThreshold`                   | `1`                                                             | Nombre minimum de succès consécutifs pour que la sonde de disponibilité soit considérée comme réussie après un échec |
| `workhorse.readinessProbe.failureThreshold`                   | `3`                                                             | Nombre minimum d'échecs consécutifs pour que la sonde de disponibilité soit considérée comme échouée après un succès |
| `workhorse.imageScaler.maxProcs`                              | `2`                                                             | Le nombre maximum de processus de mise à l'échelle d'images pouvant s'exécuter simultanément |
| `workhorse.imageScaler.maxFileSizeBytes`                      | `250000`                                                        | La taille de fichier maximale en octets pour les images à traiter par le scaler |
| `workhorse.tls.verify`                                        | `true`                                                          | Lorsque défini sur `true`, force NGINX Ingress à vérifier le certificat TLS de Workhorse. Pour une CA personnalisée, vous devez également définir `workhorse.tls.caSecretName`. Doit être défini sur `false` pour les certificats auto-signés. Si vous utilisez [Gateway API](../../../advanced/gateway-api/_index.md#tls-between-gateway-and-backend-services), le contrôleur Gateway API vérifie toujours le certificat. |
| `workhorse.tls.secretName`                                    | `{Release.Name}-workhorse-tls`                                  | Le nom du [secret TLS](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets) qui contient la paire de clé et de certificat TLS. Ceci est requis lorsque TLS est activé pour Workhorse. |
| `workhorse.tls.caSecretName`                                  |                                                                 | Le nom du Secret qui contient le certificat CA. Ceci **n'est pas** un [secret TLS](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets) et doit avoir uniquement la clé `ca.crt`. Utilisé pour la vérification TLS par NGINX. |
| `workhorse.circuitBreaker.enabled`                            | `false`                                                         | Indique si le disjoncteur est activé |
| `workhorse.circuitBreaker.timeout`                            | `60`                                                            | La durée (s) pour faire passer le disjoncteur à l'état semi-ouvert lorsqu'il est ouvert |
| `workhorse.circuitBreaker.interval`                           | `180`.                                                          | La durée (s) jusqu'à ce que le disjoncteur efface les échecs consécutifs lorsqu'il est fermé |
| `workhorse.circuitBreaker.maxRequests`                        | `1`.                                                            | Le nombre de requêtes échouées pour ouvrir le disjoncteur lorsqu'il est semi-ouvert |
| `workhorse.circuitBreaker.consecutiveFailures`                | `5`.                                                            | Le nombre de requêtes consécutives échouées pour ouvrir le disjoncteur lorsqu'il est fermé |
| `webServer`                                                   | `puma`                                                          | Sélectionne le serveur web (Webservice/Puma) qui sera utilisé pour le traitement des requêtes |
| `priorityClassName`                                           | `""`                                                            | Permet de configurer `priorityClassName` des pods, utilisé pour contrôler la priorité des pods en cas d'éviction |
| `antiAffinity`                                           | `""`                                                         | Vous permet de remplacer les valeurs antiAffinity des valeurs globales du chart, la valeur par défaut est lue depuis les paramètres globaux et peut être définie sur `soft` ou `hard` |

## Exemples de configuration du chart {#chart-configuration-examples}

### `extraEnv` {#extraenv}

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

### `extraEnvFrom` {#extraenvfrom}

`extraEnvFrom` vous permet d'exposer des variables d'environnement supplémentaires provenant d'autres sources de données dans tous les conteneurs des pods. Les variables suivantes peuvent être remplacées par [déploiement](#deployments-settings).

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
deployments:
  default:
    extraEnvFrom:
      CONFIG_STRING:
        configMapKeyRef:
          name: useful-config
          key: some-string
          # optional: boolean
```

### `image.pullSecrets` {#imagepullsecrets}

`pullSecrets` vous permet de vous authentifier auprès d'un registre privé pour extraire des images pour un pod.

Des informations supplémentaires sur les registres privés et leurs méthodes d'authentification sont disponibles dans [la documentation Kubernetes](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Voici un exemple d'utilisation de `pullSecrets` :

```yaml
image:
  repository: my.webservice.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

Cette section contrôle si un ServiceAccount doit être créé et si le jeton d'accès par défaut doit être monté dans les pods.

| Nom                           |  Type   | Défaut | Description |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   Map   | `{}`    | Annotations ServiceAccount. |
| `automountServiceAccountToken` | Boolean | `false` | Contrôle si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods. Vous ne devez pas activer cette option, sauf si elle est requise par certains sidecars pour fonctionner correctement (par exemple, Istio). |
| `create`                       | Boolean | `false` | Indique si un ServiceAccount doit être créé. |
| `enabled`                      | Boolean | `false` | Indique si un ServiceAccount doit être utilisé. |
| `name`                         | String  |         | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé. |

### `tolerations` {#tolerations}

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

### `annotations` {#annotations}

`annotations` vous permet d'ajouter des annotations aux pods Webservice. Par exemple :

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

### `strategy` {#strategy}

`deployment.strategy` vous permet de modifier la stratégie de mise à jour du déploiement. Il définit comment les pods seront recréés lors de la mise à jour d'un déploiement. Si non fourni, la valeur par défaut du cluster est utilisée. Par exemple, si vous ne souhaitez pas créer de pods supplémentaires lors du démarrage de la mise à jour progressive et modifier les pods indisponibles maximaux à 50 % :

```yaml
deployment:
  strategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 50%
```

Vous pouvez également modifier le type de stratégie de mise à jour sur `Recreate`, mais faites attention car cela supprimera tous les pods avant d'en planifier de nouveaux, et l'interface web sera indisponible jusqu'au démarrage des nouveaux pods. Dans ce cas, vous n'avez pas besoin de définir `rollingUpdate`, uniquement `type` :

```yaml
deployment:
  strategy:
    type: Recreate
```

Pour plus de détails, voir la [documentation Kubernetes](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy).

### TLS {#tls}

Un pod Webservice exécute deux conteneurs :

- `gitlab-workhorse`
- `webservice`

#### `gitlab-workhorse` {#gitlab-workhorse}

Workhorse prend en charge TLS pour les endpoints web et métriques. Cela sécurisera la communication entre Workhorse et d'autres composants, notamment `nginx-ingress`, `gitlab-shell` et `gitaly`. Le certificat TLS doit inclure le nom d'hôte du service Workhorse (par ex. `RELEASE-webservice-default.default.svc`) dans le Common Name (CN) ou le Subject Alternate Name (SAN).

Notez que [plusieurs déploiements de Webservice](#deployments-settings) peuvent exister, vous devez donc préparer le certificat TLS pour différents noms de service. Cela peut être réalisé par plusieurs SAN ou un certificat wildcard.

Une fois le certificat TLS généré, créez un [secret TLS Kubernetes](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets) pour celui-ci. Vous devez également créer un autre Secret qui contient uniquement le certificat CA du certificat TLS avec la clé `ca.crt`.

Le TLS peut être activé pour le conteneur `gitlab-workhorse` en définissant `global.workhorse.tls.enabled` sur `true`. Vous pouvez passer des noms de Secret personnalisés à `gitlab.webservice.workhorse.tls.secretName` et `global.certificates.customCAs` respectivement.

Lorsque `gitlab.webservice.workhorse.tls.verify` est `true` (c'est le cas par défaut), vous devez également passer le nom du Secret du certificat CA à `gitlab.webservice.workhorse.tls.caSecretName`. Ceci est nécessaire pour les certificats auto-signés et les CA personnalisées. Ce Secret est utilisé par NGINX pour vérifier le certificat TLS de Workhorse.

```yaml
global:
  workhorse:
    tls:
      enabled: true
  certificates:
    customCAs:
      - secret: gitlab-workhorse-ca
gitlab:
  webservice:
    workhorse:
      tls:
        verify: true
        # secretName: gitlab-workhorse-tls
        caSecretName: gitlab-workhorse-ca
      monitoring:
        exporter:
          enabled: true
          tls:
            enabled: true
```

Le TLS sur les endpoints de métriques du conteneur `gitlab-workhorse` est hérité de `global.workhorse.tls.enabled`. Notez que le TLS sur l'endpoint de métriques n'est disponible que lorsque TLS est activé pour Workhorse. L'écouteur de métriques utilise le même certificat TLS que celui spécifié par `gitlab.webservice.workhorse.tls.secretName`.

Les certificats TLS utilisés pour les endpoints de métriques peuvent nécessiter des considérations supplémentaires pour les Subject Alternative Names (SAN) inclus, notamment lors de l'utilisation du chart Helm Prometheus inclus. Pour plus d'informations, voir [Configurer Prometheus pour collecter les endpoints TLS activés](../../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints).

#### `webservice` {#webservice}

Le principal cas d'utilisation de l'activation de TLS est de fournir un chiffrement via HTTPS pour la [collecte des métriques Prometheus](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/).

Pour que Prometheus collecte l'endpoint `/metrics/` via HTTPS, une configuration supplémentaire est requise pour l'attribut `CommonName` du certificat ou une entrée `SubjectAlternativeName`. Voir [Configuration de Prometheus pour collecter les endpoints TLS activés](../../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints) pour ces exigences.

TLS peut être activé sur le conteneur `webservice` via les paramètres `gitlab.webservice.tls.enabled` :

```yaml
gitlab:
  webservice:
    tls:
      enabled: true
      # secretName: gitlab-webservice-tls
```

`secretName` doit pointer vers un [secret TLS Kubernetes](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets). Par exemple, pour créer un secret TLS avec un certificat et une clé locaux :

```shell
kubectl create secret tls <secret name> --cert=path/to/puma.crt --key=path/to/puma.key
```

## Utilisation de l'édition Community de ce chart {#using-the-community-edition-of-this-chart}

Par défaut, les charts Helm utilisent l'édition Enterprise de GitLab. Si vous le souhaitez, vous pouvez utiliser la Community Edition à la place. En savoir plus sur les [différences entre les deux](https://about.gitlab.com/install/ce-or-ee/).

Pour utiliser l'édition Community, définissez `image.repository` sur `registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ce` et `workhorse.image` sur `registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ce`.

## Paramètres globaux {#global-settings}

Nous partageons certains paramètres globaux communs entre nos charts. Voir la [documentation Globals](../../globals.md) pour les options de configuration communes, telles que les noms d'hôtes GitLab et Registry.

## Paramètres des déploiements {#deployments-settings}

Ce chart a la capacité de créer plusieurs objets Deployment et leurs ressources associées. Cette fonctionnalité permet de distribuer les requêtes vers l'application GitLab entre plusieurs ensembles de Pods via un routage basé sur les chemins.

Les clés de cette Map (`default` dans cet exemple) sont le « nom » de chacun. `default` aura un Deployment, un Service, un HorizontalPodAutoscaler, un PodDisruptionBudget et un Ingress optionnel créés avec `RELEASE-webservice-default`.

Toute propriété non fournie héritera des valeurs par défaut du chart `gitlab-webservice`.

```yaml
deployments:
  default:
    ingress:
      path: # Does not inherit or default. Leave blank to disable Ingress.
      pathType: Prefix
      provider: nginx
      annotations:
        # inherits `ingress.anntoations`
      proxyConnectTimeout: # inherits `ingress.proxyConnectTimeout`
      proxyReadTimeout:    # inherits `ingress.proxyReadTimeout`
      proxyBodySize:       # inherits `ingress.proxyBodySize`
    deployment:
      annotations: # map
      labels: # map
      # inherits `deployment`
    pod:
      labels: # additional labels to .podLabels
      annotations: # map
        # inherit from .Values.annotations
    service:
      labels: # additional labels to .serviceLabels
      annotations: # additional annotations to .service.annotations
        # inherits `service.annotations`
    hpa:
      minReplicas: # defaults to .minReplicas
      maxReplicas: # defaults to .maxReplicas
      metrics: # optional replacement of HPA metrics definition
      # inherits `hpa`
    pdb:
      maxUnavailable: # inherits `maxUnavailable`
    resources: # `resources` for `webservice` container
      # inherits `resources`
    workhorse: # map
      # inherits `workhorse`
    extraEnv: #
      # inherits `extraEnv`
    extraEnvFrom: #
      # inherits `extraEnvFrom`
    puma: # map
      # inherits `puma`
    workerProcesses: # inherits `workerProcesses`
    shutdown:
      # inherits `shutdown`
    nodeSelector: # map
      # inherits `nodeSelector`
    tolerations: # array
      # inherits `tolerations`
    priorityClassName: # inherits `priorityClassName`
```

### Ingress des déploiements {#deployments-ingress}

Chaque entrée `deployments` héritera des [paramètres Ingress](#ingress-settings) à l'échelle du chart. Toute valeur présentée ici remplacera celles fournies là-bas. En dehors de `path`, tous les paramètres sont identiques à ceux-là.

```yaml
webservice:
  deployments:
    default:
      ingress:
        path: /
    api:
      ingress:
        path: /api
```

La propriété `path` est directement renseignée dans la propriété `path` de l'Ingress et permet de contrôler les chemins URI dirigés vers chaque service. Dans l'exemple ci-dessus, `default` agit comme chemin fourre-tout, et `api` reçoit tout le trafic sous `/api`

Vous pouvez désactiver la création d'une ressource Ingress associée à un déploiement donné en définissant `path` sur vide. Voir ci-dessous, où `internal-api` ne recevra jamais de trafic externe.

```yaml
webservice:
  deployments:
    default:
      ingress:
        path: /
    api:
      ingress:
        path: /api
    internal-api:
      ingress:
        path:
```

## Paramètres Ingress {#ingress-settings}

| Nom                              |  Type   | Défaut                   | Description |
|:----------------------------------|:-------:|:--------------------------|:------------|
| `ingress.apiVersion`              | String  |                           | Valeur à utiliser dans le champ `apiVersion`. |
| `ingress.annotations`             |   Map   | Voir [ci-dessous](#annotations) | Ces annotations seront utilisées pour chaque Ingress. Par exemple : `ingress.annotations."nginx\.ingress\.kubernetes\.io/enable-access-log"=true`. |
| `ingress.configureCertmanager`    | Boolean |                           | Active/désactive l'annotation Ingress `cert-manager.io/issuer` et `acme.cert-manager.io/http01-edit-in-place`. Pour plus d'informations, voir les [exigences TLS pour GitLab Pages](../../../installation/tls.md). |
| `ingress.enabled`                 | Boolean | `false`                   | Paramètre qui contrôle la création d'objets Ingress pour les services qui les prennent en charge. Lorsque `false`, la valeur du paramètre `global.ingress.enabled` est utilisée. |
| `ingress.proxyBodySize`           | String  | `512m`                    | [Voir ci-dessous](#proxybodysize). |
| `ingress.serviceUpstream`         | Boolean | `true`                    | [Voir ci-dessous](#serviceupstream). |
| `ingress.tls.enabled`             | Boolean | `true`                    | Lorsque défini sur `false`, vous désactivez TLS pour GitLab Webservice. Ceci est principalement utile dans les cas où vous ne pouvez pas utiliser la terminaison TLS au niveau de l'Ingress, par exemple lorsque vous avez un proxy qui termine TLS avant le contrôleur Ingress. |
| `ingress.tls.secretName`          | String  | (vide)                   | Le nom du secret TLS Kubernetes qui contient un certificat et une clé valides pour l'URL GitLab. Si non défini, la valeur `global.ingress.tls.secretName` est utilisée à la place. |
| `ingress.tls.smardcardSecretName` | String  | (vide)                   | Le nom du secret TLS Kubernetes qui contient un certificat et une clé valides pour l'URL de la smartcard GitLab si activée. Si non défini, la valeur `global.ingress.tls.secretName` est utilisée à la place. |
| `ingress.tls.useGeoClass`         | Boolean | `false`                   | Remplace l'IngressClass par la classe Ingress Geo (`global.geo.ingressClass`). Requis pour les sites Geo primaires. |

### annotations {#annotations-1}

`annotations` est utilisé pour définir des annotations sur l'Ingress Webservice.

### `serviceUpstream` {#serviceupstream}

Cela aide à équilibrer le trafic vers les pods Webservice de manière plus uniforme en indiquant à NGINX de contacter directement le Service lui-même en tant qu'upstream. Pour plus d'informations, voir la [documentation NGINX](https://github.com/kubernetes/ingress-nginx/blob/main/docs/user-guide/nginx-configuration/annotations.md#service-upstream).

Pour remplacer cela, définissez :

```yaml
gitlab:
  webservice:
    ingress:
      serviceUpstream: "false"
```

### `proxyBodySize` {#proxybodysize}

`proxyBodySize` est utilisé pour définir la taille maximale du corps du proxy NGINX. Ceci est généralement requis pour permettre une image Docker plus grande que la valeur par défaut. C'est l'équivalent de la configuration `nginx['client_max_body_size']` dans une [installation de package Linux](https://docs.gitlab.com/omnibus/settings/nginx/#use-an-existing-passenger-and-nginx-installation). En alternative, vous pouvez également définir la taille du corps avec l'un des deux paramètres suivants :

- `gitlab.webservice.ingress.annotations."nginx\.ingress\.kubernetes\.io/proxy-body-size"`
- `global.ingress.annotations."nginx\.ingress\.kubernetes\.io/proxy-body-size"`

### Ingress supplémentaire {#extra-ingress}

Un Ingress supplémentaire peut être déployé en définissant `extraIngress.enabled=true`. L'Ingress est nommé comme l'Ingress par défaut avec le suffixe `-extra` et prend en charge les mêmes paramètres que l'Ingress par défaut.

## Gateway API {#gateway-api}

Si le chart GitLab est configuré pour être exposé [via Gateway API](../../globals.md#gateway-api), chaque déploiement sera ajouté en tant que règle au `HTTPRoute` du chart Webservice.

Vous pouvez désactiver la création d'une règle dans le `HTTPRoute` pour un déploiement donné en définissant `.rules=[]` pour ce déploiement.

```yaml
webservice:
  deployments:
    default:
      gatewayRoute:
        rules:
        - matches:
          - path:
              type: PathPrefix
              value: /
          timeouts:
            request: "20s"
            backendRequest: "20s"
          filters:
          - type: RequestHeaderModifier
            requestHeaderModifier:
              remove:
              - X-Forwarded-Host
    api:
      gatewayRoute:
        rules:
        - matches:
          - path:
              type: PathPrefix
              value: /api
    internal-api:
      gatewayRoute:
        rules: []
```

Chaque règle prend en charge `matches`, `timeouts` et `filters`. Les filtres acceptent une liste d'objets [Gateway API HTTPRouteFilter](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPRouteFilter).

### TLS entre Gateway et Workhorse {#tls-between-gateway-and-workhorse}

Lorsque le [TLS Workhorse](#gitlab-workhorse) est activé, vous pouvez configurer un `BackendTLSPolicy` par déploiement afin que le Gateway vérifie les connexions TLS à chaque backend Workhorse. Définissez `workhorse.tls.enabled: true` et fournissez un secret CA au niveau du déploiement :

```yaml
global:
  workhorse:
    tls:
      enabled: true
gitlab:
  webservice:
    workhorse:
      tls:
        enabled: true
        caSecretName: workhorse-tls-ca
    deployments:
      api:
        workhorse:
          tls:
            enabled: true
            caSecretName: workhorse-api-tls-ca
```

Le nom d'hôte de validation correspond par défaut au nom DNS du service (`<service-name>.<namespace>.svc`). Remplacez-le avec `backendTLSPolicy.hostname` :

```yaml
gitlab:
  webservice:
    backendTLSPolicy:
      hostname: workhorse.example.internal
```

Pour tous les détails, voir la documentation de [Gateway API](../../../advanced/gateway-api/_index.md#tls-between-gateway-and-backend-services).

## Ressources {#resources}

### Requêtes/limites de mémoire {#memory-requestslimits}

Chaque pod génère un nombre de workers égal à `workerProcesses`, chacun utilisant une quantité de mémoire de base. Nous recommandons :

- Un minimum de 1,25 Go par worker (`requests.memory`)
- Un maximum de 1,5 Go par worker, plus 1 Go pour le primaire (`limits.memory`)

Notez que les ressources requises dépendent de la charge de travail générée par les utilisateurs et peuvent évoluer à l'avenir en fonction des modifications ou des mises à niveau de l'application GitLab.

Par défaut :

```yaml
workerProcesses: 2
resources:
  requests:
    memory: 2.5G # = 2 * 1.25G
# limits:
#   memory: 4G   # = (2 * 1.5G) + 950M
```

Avec 4 workers configurés :

```yaml
workerProcesses: 4
resources:
  requests:
    memory: 5G   # = 4 * 1.25G
# limits:
#   memory: 7G   # = (4 * 1.5G) + 950M
```

## Services externes {#external-services}

### Redis {#redis}

La documentation Redis a été regroupée dans la page [globals](../../globals.md#configure-redis-settings). Veuillez consulter cette page pour les dernières options de configuration Redis.

### PostgreSQL {#postgresql}

La documentation PostgreSQL a été regroupée dans la page [globals](../../globals.md#configure-postgresql-settings). Veuillez consulter cette page pour les dernières options de configuration PostgreSQL.

Le `dependencies` `initContainer` dans le déploiement Webservice exécute des scripts pour vérifier :

- Si les dépendances de GitLab sont disponibles.
- Si les migrations de base de données pour PostgreSQL ont été exécutées.

Vous pouvez utiliser la clé de configuration `extraEnv` du chart Webservice pour contrôler le comportement de ces scripts. Deux variables d'environnement sont prises en charge :

- `BYPASS_POST_DEPLOYMENT=true` :  La vérification des dépendances réussit si toutes les migrations régulières ont été exécutées et que seules les migrations post-déploiement sont en attente
- `BYPASS_SCHEMA_VERSION=true` (non recommandé) :  La vérification des dépendances réussit même si les migrations régulières n'ont pas été exécutées. L'utilisation de cette variable d'environnement peut entraîner des erreurs dans le déploiement Rails après le démarrage, car le schéma de base de données ne correspond pas aux attentes du code de l'application.

### Gitaly {#gitaly}

```yaml
global:
  gitaly:
    ## These settings are used by Gitaly clients: GitLab Rails, GitLab Shell, Workhorse.
    client:
      maxAttempts: 4
      maxBackoff: '1.4s'
```

| Nom             |  Type   | Défaut  | Description                                                                                                                         |
|:-----------------|:-------:|:---------|:------------------------------------------------------------------------------------------------------------------------------------|
| `maxAttempts`    | Integer | `4`      | Le nombre maximum de tentatives que les clients Gitaly effectueront pour renvoyer une requête avant de retourner une erreur au client, en cas d'échec. |
| `maxBackoff`     | String  | `'1.4s'` | La durée maximale, en secondes, pendant laquelle les clients Gitaly réessaieront une requête avant de retourner une erreur au client.                  |

Les autres paramètres Gitaly sont configurés par les [paramètres globaux](../../globals.md). Veuillez consulter la [documentation de configuration Gitaly](../../globals.md#configure-gitaly-settings).

### MinIO {#minio}

```yaml
minio:
  serviceName: 'minio-svc'
  port: 9000
```

| Nom          |  Type   | Défaut     | Description |
|:--------------|:-------:|:------------|:------------|
| `port`        | Integer | `9000`      | Numéro de port pour accéder au `Service` MinIO. |
| `serviceName` | String  | `minio-svc` | Nom du `Service` exposé par le pod MinIO. |

### Registry {#registry}

```yaml
registry:
  host: registry.example.com
  port: 443
  api:
    protocol: http
    host: registry.example.com
    serviceName: registry
    port: 5000
  tokenIssuer: gitlab-issuer
  certificate:
    secret: gitlab-registry
    key: registry-auth.key
```

| Nom                 |  Type   | Défaut         | Description |
|:---------------------|:-------:|:----------------|:------------|
| `api.host`           | String  |                 | Le nom d'hôte du serveur Registry à utiliser. Cela peut être omis au profit de `api.serviceName`. |
| `api.port`           | Integer | `5000`          | Le port auquel se connecter pour l'API Registry. |
| `api.protocol`       | String  |                 | Le protocole que Webservice doit utiliser pour accéder à l'API Registry. |
| `api.serviceName`    | String  | `registry`      | Le nom du `service` qui fait fonctionner le serveur Registry. Si cet attribut est présent et que `api.host` ne l'est pas, le chart créera le modèle du nom d'hôte du service (et du `.Release.Name` actuel) à la place de la valeur `api.host`. Ceci est pratique lors de l'utilisation du Registry dans le cadre du chart GitLab global. |
| `certificate.key`    | String  |                 | Le nom de la `key` dans le `Secret` qui contient le bundle de certificats qui sera fourni au conteneur [registry](https://hub.docker.com/_/registry/) en tant que `auth.token.rootcertbundle`. |
| `certificate.secret` | String  |                 | Le nom du [Secret Kubernetes](https://kubernetes.io/docs/concepts/configuration/secret/) qui contient le bundle de certificats utilisé pour vérifier les jetons créés par la ou les instances GitLab. |
| `host`               | String  |                 | Le nom d'hôte externe à utiliser pour fournir des commandes Docker aux utilisateurs dans l'interface GitLab. Utilise comme valeur de repli celle définie dans le template `registry.hostname`. Qui détermine le nom d'hôte du Registry en fonction des valeurs définies dans `global.hosts`. Voir la [documentation Globals](../../globals.md) pour plus d'informations. |
| `port`               | Integer |                 | Le port externe utilisé dans le nom d'hôte. L'utilisation du port `80` ou `443` entraînera la formation des URLs avec `http`/`https`. Les autres ports utiliseront tous `http` et ajouteront le port à la fin du nom d'hôte, par exemple `http://registry.example.com:8443`. |
| `tokenIssuer`        | String  | `gitlab-issuer` | Le nom de l'émetteur du jeton d'authentification. Doit correspondre au nom utilisé dans la configuration du Registry, car il est incorporé dans le jeton lors de son envoi. La valeur par défaut `gitlab-issuer` est la même valeur par défaut que celle utilisée dans le chart Registry. |

## Paramètres du chart {#chart-settings}

Les valeurs suivantes sont utilisées pour configurer les Pods Webservice.

| Nom              |  Type   | Défaut | Description |
|:------------------|:-------:|:--------|:------------|
| `workerProcesses` | Integer | `2`     | Le nombre de workers Webservice à exécuter par pod. Vous devez disposer d'au moins `2` workers disponibles dans votre cluster pour que GitLab fonctionne correctement. Notez que l'augmentation de `workerProcesses` augmentera la mémoire requise d'environ `400MB` par worker ; vous devez donc mettre à jour les `resources` du pod en conséquence. |
| `minReplicas`     | Integer | `2`     | Nombre minimum de réplicas |
| `maxReplicas`     | Integer | `10`    | Nombre maximum de réplicas |
| `maxUnavailable`  | Integer | `1`     | Limite du nombre maximum de pods pouvant être indisponibles |

### Métriques {#metrics}

Les métriques peuvent être activées avec la valeur `metrics.enabled` et utilisent l'exportateur de monitoring GitLab pour exposer un port de métriques. Les pods reçoivent soit des annotations Prometheus, soit, si `metrics.serviceMonitor.enabled` est `true`, un Prometheus Operator ServiceMonitor est créé. Les métriques peuvent également être collectées depuis l'endpoint `/-/metrics`, mais cela nécessite que les [métriques Prometheus GitLab](https://docs.gitlab.com/administration/monitoring/prometheus/gitlab_metrics/) soient activées dans la zone d'administration. Les métriques GitLab Workhorse peuvent également être exposées via `workhorse.metrics.enabled`, mais elles ne peuvent pas être collectées à l'aide des annotations Prometheus et nécessitent donc que `workhorse.metrics.serviceMonitor.enabled` soit `true` ou une configuration Prometheus externe.

### GitLab Shell {#gitlab-shell}

GitLab Shell utilise un jeton d'authentification dans sa communication avec Webservice. Partagez le jeton avec GitLab Shell et Webservice à l'aide d'un Secret partagé.

```yaml
shell:
  authToken:
    secret: gitlab-shell-secret
    key: secret
  port:
```

| Nom               |  Type   | Défaut | Description |
|:-------------------|:-------:|:--------|:------------|
| `authToken.key`    | String  |         | Définit le nom de la clé dans le secret (ci-dessous) qui contient l'authToken. |
| `authToken.secret` | String  |         | Définit le nom du `Secret` Kubernetes depuis lequel extraire. |
| `port`             | Integer | `22`    | Le numéro de port à utiliser pour générer les URLs SSH dans l'interface GitLab. Contrôlé par `global.shell.port`. |

### Options du serveur web {#webserver-options}

La version actuelle du chart prend en charge le serveur web Puma.

Options uniques de Puma :

| Nom                   |  Type   | Défaut | Description |
|:-----------------------|:-------:|:--------|:------------|
| `puma.workerMaxMemory` | Integer |         | La mémoire maximale (en mégaoctets) pour le worker killer de Puma |
| `puma.threads.min`     | Integer | `4`     | Nombre minimal de threads Puma |
| `puma.threads.max`     | Integer | `4`     | Nombre maximal de threads Puma |

### Délestage de charge de Workhorse {#workhorse-load-shedding}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/work_items/28055) dans GitLab 18.9.
- Le paramètre `statusCode` [ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/225993) dans GitLab 18.10.

{{< /history >}}

Le délestage de charge protège Puma d'une surcharge en retournant un code de statut HTTP configuré lorsque le backlog de requêtes dépasse un seuil configuré, afin de permettre au proxy inverse de réessayer les requêtes vers d'autres instances.

Pour activer le délestage de charge, configurez les paramètres `loadShedding` :

```yaml
gitlab:
  webservice:
    workhorse:
      loadShedding:
        enabled: true
        backlogThreshold: 50
        retryAfterSeconds: 0
        statusCode: 503
        strategy: max
```

- `backlogThreshold` spécifie le nombre de requêtes en attente qui déclenchent le délestage de charge.
- `retryAfterSeconds` définit la valeur de l'en-tête `Retry-After` dans la réponse.
- `statusCode` définit le code de statut HTTP à retourner lors du délestage de charge (par défaut : `503`). Utilisez un code personnalisé tel que `529` pour distinguer les réponses de délestage de charge des autres erreurs `503` causées par des délais d'expiration de base de données ou des problèmes Gitaly.
- `strategy` détermine comment le backlog effectif est calculé :
  - `max` :  Utilise le backlog maximum parmi tous les workers Puma (par défaut).
  - `sum` :  Utilise la somme de tous les backlogs parmi les workers Puma.

#### Configuration du proxy {#proxy-configuration}

Pour que le délestage de charge fonctionne efficacement, votre proxy inverse doit être configuré pour réessayer les requêtes lorsqu'il reçoit une réponse `503`. Cela garantit que les requêtes sont distribuées vers des instances saines.

Pour un exemple NGINX, configurez les annotations suivantes sur l'Ingress :

```yaml
ingress:
  annotations:
    nginx.ingress.kubernetes.io/proxy-next-upstream: "http_503"
    nginx.ingress.kubernetes.io/proxy-next-upstream-tries: "3"
    nginx.ingress.kubernetes.io/proxy-next-upstream-timeout: "10s"
```

Ces paramètres indiquent à NGINX de :

- Réessayer pour les réponses `503` (que le délestage de charge génère).
- Essayer jusqu'à 3 fois avant d'abandonner.
- Attendre jusqu'à 10 secondes pour les nouvelles tentatives.

Vous ne devez réessayer que pour les réponses `503`, qui constituent le signal spécifique que le délestage de charge génère. Évitez de réessayer pour d'autres codes de statut comme `504` (Gateway Timeout) ou des conditions d'erreur, car ceux-ci peuvent amplifier la charge lors de pannes en réessayant des requêtes susceptibles d'échouer sur tous les backends.

Pour les autres proxies inverses, consultez leur documentation pour une configuration de nouvelle tentative équivalente. L'essentiel est de s'assurer que les réponses `503` déclenchent des nouvelles tentatives vers d'autres instances backend.

## Configuration de `networkpolicy` {#configuring-the-networkpolicy}

Cette section contrôle la [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). Cette configuration est facultative et est utilisée pour limiter l'Egress et l'Ingress des pods à des endpoints spécifiques.

| Nom              |  Type   | Défaut | Description |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | Boolean | `false` | Ce paramètre active la `NetworkPolicy` |
| `ingress.enabled` | Boolean | `false` | Lorsque défini sur `true`, la politique réseau `Ingress` sera activée. Cela bloquera toutes les connexions Ingress sauf si des règles sont spécifiées. |
| `ingress.rules`   |  Tableau  | `[]`    | Règles pour la politique Ingress, pour plus de détails voir <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> et l'exemple ci-dessous |
| `egress.enabled`  | Boolean | `false` | Lorsque défini sur `true`, la politique réseau `Egress` sera activée. Cela bloquera toutes les connexions egress sauf si des règles sont spécifiées. |
| `egress.rules`    |  Tableau  | `[]`    | Règles pour la politique egress, pour plus de détails voir <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> et l'exemple ci-dessous |

### Exemple de politique réseau {#example-network-policy}

Le service webservice nécessite des connexions Ingress pour l'exportateur Prometheus si activé, le trafic provenant de l'Ingress NGINX et de plusieurs pods GitLab. Il nécessite généralement des connexions Egress vers divers endroits. Cet exemple ajoute la politique réseau suivante :

- Autorise les requêtes Ingress :
  - Depuis les pods `gitaly`, `gitlab-pages`, `gitlab-shell`, `kas` , `mailroom` et `nginx-ingress` vers le port `8181`
  - Depuis le pod `Prometheus` vers les ports `8080`, `8083` et `9229`
- Autorise les requêtes Egress :
  - Vers le pod `gitaly` sur le port `8075`
  - Vers le pod `kas` sur le port `8153`
  - Vers `kube-dns` sur le port `53`
  - Vers le pod `registry` sur le port `5000`
  - Vers la base de données externe `172.16.0.10/32` sur le port `5432`
  - Vers Redis externe `172.16.0.11/32` sur le port `6379`
  - Vers Internet `0.0.0.0/0` sur le port `443`
  - Vers les endpoints tels que AWS VPC endpoint pour S3 ou STS `172.16.1.0/24` sur le port `443`

L'exemple fourni n'est qu'un exemple et peut ne pas être complet. Le Webservice nécessite une connectivité sortante vers l'Internet public pour les images sur [le stockage d'objets externe](../../../advanced/external-object-storage). L'exemple est basé sur l'hypothèse que `kube-dns` a été déployé dans l'espace de nommage `kube-system`, `prometheus` a été déployé dans l'espace de nommage `monitoring` et `nginx-ingress` a été déployé dans l'espace de nommage `nginx-ingress`.

```yaml
networkpolicy:
  enabled: true
  ingress:
    enabled: true
    rules:
      - from:
          - podSelector:
              matchLabels:
                app: gitaly
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: gitlab-pages
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: gitlab-shell
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: kas
        ports:
          - port: 8181
      - from:
          - podSelector:
              matchLabels:
                app: mailroom
        ports:
          - port: 8181
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 8181
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
          - port: 9229
          - port: 8080
          - port: 8083
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
          - ipBlock:
              cidr: 0.0.0.0/0
              except:
                - 10.0.0.0/8
        ports:
          - port: 443
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
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: kube-system
            podSelector:
              matchLabels:
                k8s-app: kube-dns
        ports:
          - port: 53
            protocol: UDP
```

### Service `LoadBalancer` {#loadbalancer-service}

Si `service.type` est défini sur `LoadBalancer`, vous pouvez éventuellement spécifier `service.loadBalancerIP` pour créer le `LoadBalancer` avec une IP spécifiée par l'utilisateur (si votre fournisseur cloud le prend en charge).

Lorsque `service.type` est défini sur `LoadBalancer`, vous devez également définir `service.loadBalancerSourceRanges` pour restreindre les plages CIDR pouvant accéder au `LoadBalancer` (si votre fournisseur cloud le prend en charge). Cela est actuellement requis en raison d'un problème où [les ports de métriques sont exposés](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2500).

Des informations supplémentaires sur le type de service `LoadBalancer` sont disponibles dans [la documentation Kubernetes](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)

```yaml
service:
  type: LoadBalancer
  loadBalancerIP: 1.2.3.4
  loadBalancerSourceRanges:
  - 10.0.0.0/8
```

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
| `minReplicaCount`               | Integer | `minReplicas`                   | Nombre minimum de réplicas vers lesquels KEDA peut réduire la ressource. |
| `maxReplicaCount`               | Integer | `maxReplicas`                   | Nombre maximum de réplicas vers lesquels KEDA peut augmenter la ressource. |
| `fallback`                      |   Map   |                                 | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `hpaName`                       | String  | `keda-hpa-{scaled-object-name}` | Le nom de la ressource HPA que KEDA créera. |
| `restoreToOriginalReplicaCount` | Boolean |                                 | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `behavior`                      |   Map   | `hpa.behavior`                  | Les spécifications pour le comportement de mise à l'échelle ascendant et descendant. |
| `triggers`                      |  Tableau  |                                 | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |
