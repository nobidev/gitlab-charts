---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du registre de conteneurs
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab auto-géré

{{< /details >}}

Le sous-chart `registry` fournit le composant Registry pour un déploiement GitLab complet, natif du cloud, sur Kubernetes. Ce sous-chart est basé sur le [chart en amont](https://github.com/docker/distribution-library-image) et contient le [registre de conteneurs](https://gitlab.com/gitlab-org/container-registry) GitLab.

Ce chart est composé de 3 parties principales :

- [Service](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/service.yaml),
- [Deployment](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/deployment.yaml),
- [ConfigMap](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/configmap.yaml).

Toute la configuration est gérée conformément à la [documentation de configuration du Registry](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads) en utilisant les variables `/etc/docker/registry/config.yml` fournies au `Deployment` alimenté depuis le `ConfigMap`. Le `ConfigMap` remplace les valeurs par défaut en amont, mais est [basé sur celles-ci](https://github.com/docker/distribution-library-image/blob/master/config-example.yml). Voir ci-dessous pour plus de détails :

- [`distribution/cmd/registry/config-example.yml`](https://github.com/docker/distribution/blob/master/cmd/registry/config-example.yml)
- [`distribution-library-image/config-example.yml`](https://github.com/docker/distribution-library-image/blob/master/config-example.yml)

## Choix de conception {#design-choices}

Un `Deployment` Kubernetes a été choisi comme méthode de déploiement pour ce chart afin de permettre une mise à l'échelle simple des instances, tout en autorisant les [mises à jour progressives](https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/).

Ce chart utilise deux secrets obligatoires et un optionnel :

### Obligatoire {#required}

- `global.registry.certificate.secret` :  Un secret global qui contiendra le bundle de certificats publics pour vérifier les jetons d'authentification fournis par les instances GitLab associées. Voir la [documentation](https://docs.gitlab.com/administration/packages/container_registry/#use-an-external-container-registry-with-gitlab-as-an-auth-endpoint) sur l'utilisation de GitLab comme point de terminaison d'authentification.
- `global.registry.httpSecret.secret` :  Un secret global qui contiendra le [secret partagé](https://distribution.github.io/distribution/about/configuration/#http) entre les pods du registre.

### Optionnel {#optional}

- `profiling.stackdriver.credentials.secret` :  Si le profilage Stackdriver est activé et que vous devez fournir des identifiants de compte de service explicites, la valeur dans ce secret (dans la clé `credentials` par défaut) correspond aux identifiants JSON du compte de service GCP. Si vous utilisez GKE et fournissez des comptes de service à vos charges de travail via [Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) (ou des comptes de service de nœud, bien que cela ne soit pas recommandé), ce secret n'est pas requis et ne doit pas être fourni. Dans les deux cas, le compte de service nécessite le rôle `roles/cloudprofiler.agent` ou des [autorisations manuelles](https://cloud.google.com/profiler/docs/iam#roles) équivalentes

## Configuration {#configuration}

Nous allons décrire toutes les sections principales de la configuration ci-dessous. Lors de la configuration depuis le chart parent, ces valeurs seront :

```yaml
registry:
  enabled:
  maintenance:
    readonly:
      enabled: false
    uploadpurging:
      enabled: true
      age: 168h
      interval: 24h
      dryrun: false
  image:
    tag: 'v4.15.2-gitlab'
    pullPolicy: IfNotPresent
  annotations:
  service:
    type: ClusterIP
    name: registry
  httpSecret:
    secret:
    key:
  authEndpoint:
  tokenIssuer:
  certificate:
    secret: gitlab-registry
    key: registry-auth.crt
  deployment:
    terminationGracePeriodSeconds: 30
  draintimeout: '0'
  hpa:
    minReplicas: 2
    maxReplicas: 10
    cpu:
      targetAverageUtilization: 75
    behavior:
      scaleDown:
        stabilizationWindowSeconds: 300
  storage:
    secret:
    key: storage
    extraKey:
  validation:
    disabled: true
    manifests:
      referencelimit: 0
      payloadsizelimit: 0
      urls:
        allow: []
        deny: []
  notifications: {}
  tolerations: []
  affinity: {}
  ingress:
    enabled: false
    tls:
      enabled: true
      secretName: redis
    annotations:
    configureCertmanager:
    proxyReadTimeout:
    proxyBodySize:
    proxyBuffering:
  networkpolicy:
    enabled: false
    egress:
      enabled: false
      rules: []
    ingress:
      enabled: false
      rules: []
  serviceAccount:
    create: false
    automountServiceAccountToken: false
  tls:
    enabled: false
    secretName:
    verify: true
    caSecretName:
    cipherSuites:
```

Si vous choisissez de déployer ce chart de manière autonome, supprimez `registry` au niveau supérieur.

## Paramètres d'installation {#installation-parameters}

| Paramètre                                                | Défaut                                                              | Description |
|----------------------------------------------------------|----------------------------------------------------------------------|-------------|
| `annotations`                                            |                                                                      | Annotations du pod |
| `podLabels`                                              |                                                                      | Labels de pod supplémentaires. Ne sera pas utilisé pour les sélecteurs. |
| `common.labels`                                          |                                                                      | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `authAutoRedirect`                                       | `true`                                                               | Redirection automatique d'authentification (doit être true pour que les clients Windows fonctionnent) |
| `authEndpoint`                                           | `global.hosts.gitlab.name`                                           | Point de terminaison d'authentification (hôte et port uniquement) |
| `certificate.secret`                                     | `gitlab-registry`                                                    | Certificat JWT |
| `debug.addr.port`                                        | `5001`                                                               | Port de débogage  |
| `debug.tls.enabled`                                      | `false`                                                              | Activer TLS pour le port de débogage du registre. Affecte les sondes de vivacité et de disponibilité, ainsi que le point de terminaison des métriques (si activé) |
| `debug.tls.secretName`                                   |                                                                      | Le nom du secret TLS Kubernetes qui contient un certificat et une clé valides pour le point de terminaison de débogage du registre. Lorsqu'il n'est pas défini et que `debug.tls.enabled=true` - la configuration TLS de débogage utilisera par défaut le certificat TLS du registre. |
| `debug.prometheus.enabled`                               | `false`                                                              | **DEPRECATED** Utiliser `metrics.enabled` |
| `debug.prometheus.path`                                  | `""`                                                                 | **DEPRECATED** Utiliser `metrics.path` |
| `metrics.enabled`                                        | `false`                                                              | Si un point de terminaison de métriques doit être rendu disponible pour le scraping |
| `metrics.path`                                           | `/metrics`                                                           | Chemin du point de terminaison des métriques |
| `metrics.serviceMonitor.enabled`                         | `false`                                                              | Si un ServiceMonitor doit être créé pour permettre à l'opérateur Prometheus de gérer le scraping des métriques ; notez que l'activation de cette option supprime les annotations de scraping `prometheus.io` |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                                 | Labels supplémentaires à ajouter au ServiceMonitor |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                                 | Configuration d'endpoint supplémentaire pour le ServiceMonitor |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                                 | Durée optionnelle en secondes dont le pod a besoin pour se terminer normalement. |
| `deployment.strategy`                                    | `{}`                                                                 | Permet de configurer la stratégie de mise à jour utilisée par le déploiement |
| `draintimeout`                                           | `'0'`                                                                | Durée d'attente pour que les connexions HTTP se vident après réception d'un signal SIGTERM (par exemple `'10s'`) |
| `relativeurls`                                           | `false`                                                              | Activer le registre pour retourner des URL relatives dans les en-têtes Location. |
| `enabled`                                                | `true`                                                               | Indicateur d'activation du registre |
| `api.enabled`                                            | `true`                                                               | Active les ressources Service, Deployment, HPA et PDB. |
| `extraContainers`                                        |                                                                      | Chaîne de style littéral multiligne contenant une liste de conteneurs à inclure |
| `extraInitContainers`                                    |                                                                      | Liste de conteneurs init supplémentaires à inclure |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`                    | Behavior contient les spécifications pour le comportement de mise à l'échelle ascendante et descendante (nécessite `autoscaling/v2beta2` ou version ultérieure) |
| `hpa.customMetrics`                                      | `[]`                                                                 | Les métriques personnalisées contiennent les spécifications à utiliser pour calculer le nombre de réplicas souhaité (remplace l'utilisation par défaut de l'utilisation moyenne du CPU configurée dans `targetAverageUtilization`) |
| `hpa.cpu.targetType`                                     | `Utilization`                                                        | Définir le type de cible CPU de mise à l'échelle automatique, doit être soit `Utilization` soit `AverageValue` |
| `hpa.cpu.targetAverageValue`                             |                                                                      | Définir la valeur cible CPU de mise à l'échelle automatique |
| `hpa.cpu.targetAverageUtilization`                       | `75`                                                                 | Définir l'utilisation cible CPU de mise à l'échelle automatique |
| `hpa.memory.targetType`                                  |                                                                      | Définir le type de cible mémoire de mise à l'échelle automatique, doit être soit `Utilization` soit `AverageValue` |
| `hpa.memory.targetAverageValue`                          |                                                                      | Définir la valeur cible mémoire de mise à l'échelle automatique |
| `hpa.memory.targetAverageUtilization`                    |                                                                      | Définir l'utilisation cible mémoire de mise à l'échelle automatique |
| `hpa.minReplicas`                                        | `2`                                                                  | Nombre minimum de réplicas |
| `hpa.maxReplicas`                                        | `10`                                                                 | Nombre maximum de réplicas |
| `httpSecret`                                             |                                                                      | Secret HTTPS |
| `extraEnvFrom`                                           |                                                                      | Liste de variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| `image.pullPolicy`                                       |                                                                      | Politique de téléchargement pour l'image du registre |
| `image.pullSecrets`                                      |                                                                      | Secrets à utiliser pour le dépôt d'images |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry` | Image du registre |
| `image.tag`                                              | `v4.15.2-gitlab`                                                     | Version de l'image à utiliser |
| `init.image.repository`                                  |                                                                      | Image du initContainer |
| `init.image.tag`                                         |                                                                      | Tag d'image du initContainer |
| `init.containerSecurityContext`                          |                                                                      | [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) spécifique au initContainer |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                               | Spécifique au initContainer :  ID utilisateur sous lequel le conteneur doit être démarré |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                              | Spécifique au initContainer :  Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                               | Spécifique au initContainer :  Contrôle si le conteneur s'exécute avec un utilisateur non-root |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                          | Spécifique au initContainer :  Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur |
| `keda.enabled`                                           | `false`                                                              | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` au lieu de `HorizontalPodAutoscalers` |
| `keda.pollingInterval`                                   | `30`                                                                 | L'intervalle de vérification de chaque déclencheur |
| `keda.cooldownPeriod`                                    | `300`                                                                | La période d'attente après le dernier déclencheur signalé actif avant de remettre la ressource à l'échelle 0 |
| `keda.minReplicaCount`                                   | `hpa.minReplicas`                                                    | Nombre minimum de réplicas vers lequel KEDA réduira la ressource. |
| `keda.maxReplicaCount`                                   | `hpa.maxReplicas`                                                    | Nombre maximum de réplicas vers lequel KEDA augmentera la ressource. |
| `keda.fallback`                                          |                                                                      | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                                      | Le nom de la ressource HPA que KEDA créera. |
| `keda.restoreToOriginalReplicaCount`                     |                                                                      | Indique si la ressource cible doit être remise à l'échelle au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `keda.behavior`                                          | `hpa.behavior`                                                       | Les spécifications pour le comportement de mise à l'échelle ascendante et descendante. |
| `keda.triggers`                                          |                                                                      | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |
| `log`                                                    | `{level: info, fields: {service: registry}}`                         | Configurer les options de journalisation |
| `minio.bucket`                                           | `global.registry.bucket`                                             | Nom du bucket du registre hérité |
| `maintenance.readonly.enabled`                           | `false`                                                              | Activer le mode lecture seule du registre |
| `maintenance.uploadpurging.enabled`                      | `true`                                                               | Activer la purge des téléchargements |
| `maintenance.uploadpurging.age`                          | `168h`                                                               | Purger les téléchargements plus anciens que l'âge spécifié |
| `maintenance.uploadpurging.interval`                     | `24h`                                                                | Fréquence à laquelle la purge des téléchargements est effectuée |
| `maintenance.uploadpurging.dryrun`                       | `false`                                                              | Lister uniquement les téléchargements qui seront purgés sans les supprimer |
| `priorityClassName`                                      |                                                                      | [Classe de priorité](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) attribuée aux pods. |
| `reporting.sentry.enabled`                               | `false`                                                              | Activer les rapports via Sentry |
| `reporting.sentry.dsn`                                   |                                                                      | Le DSN Sentry (Data Source Name) |
| `reporting.sentry.environment`                           |                                                                      | L'[environnement](https://docs.sentry.io/concepts/key-terms/environments/) Sentry |
| `profiling.stackdriver.enabled`                          | `false`                                                              | Activer le profilage continu via Stackdriver |
| `profiling.stackdriver.credentials.secret`               | `gitlab-registry-profiling-creds`                                    | Nom du secret contenant les identifiants |
| `profiling.stackdriver.credentials.key`                  | `credentials`                                                        | Clé du secret dans laquelle les identifiants sont stockés |
| `profiling.stackdriver.service`                          | `RELEASE-registry` (nom de service basé sur un modèle)                          | Nom du service Stackdriver sous lequel enregistrer les profils |
| `profiling.stackdriver.projectid`                        | Projet GCP en cours d'exécution                                            | Projet GCP auquel rapporter les profils |
| `database.configure`                                     | `false`                                                              | Remplir la configuration de la base de données dans le chart du registre sans l'activer. Requis lors de l'[importation d'un registre existant](metadata_database.md#enable-for-and-import-existing-registries). |
| `database.enabled`                                       | `false`                                                              | Activer la base de données de métadonnées. Il s'agit d'une fonctionnalité expérimentale qui ne doit pas être utilisée dans des environnements de production. |
| `database.host`                                          | `global.psql.host`                                                   | Le nom d'hôte du serveur de base de données. |
| `database.port`                                          | `global.psql.port`                                                   | Le port du serveur de base de données. |
| `database.user`                                          |                                                                      | Le nom d'utilisateur de la base de données. |
| `database.password.secret`                               | `RELEASE-registry-database-password`                                 | Nom du secret contenant le mot de passe de la base de données. |
| `database.password.key`                                  | `password`                                                           | Clé du secret dans laquelle le mot de passe de la base de données est stocké. |
| `database.name`                                          |                                                                      | Le nom de la base de données. |
| `database.sslmode`                                       |                                                                      | Le mode SSL. Peut être l'un des suivants : `disable`, `allow`, `prefer`, `require`, `verify-ca` ou `verify-full`. |
| `database.ssl.secret`                                    | `global.psql.ssl.secret`                                             | Un secret contenant le certificat client, la clé et l'autorité de certification. Par défaut, il s'agit du secret SSL PostgreSQL principal. |
| `database.ssl.clientCertificate`                         | `global.psql.ssl.clientCertificate`                                  | La clé à l'intérieur du secret faisant référence au certificat client. |
| `database.ssl.clientKey`                                 | `global.psql.ssl.clientKey`                                          | La clé à l'intérieur du secret faisant référence à la clé client. |
| `database.ssl.serverCA`                                  | `global.psql.ssl.serverCA`                                           | La clé à l'intérieur du secret faisant référence à l'autorité de certification (CA). |
| `database.connecttimeout`                                | `0`                                                                  | Temps d'attente maximum pour une connexion. Zéro ou non spécifié signifie attendre indéfiniment. |
| `database.draintimeout`                                  | `0`                                                                  | Temps d'attente maximum pour vider toutes les connexions lors de l'arrêt. Zéro ou non spécifié signifie attendre indéfiniment. |
| `database.preparedstatements`                            | `false`                                                              | Activer les instructions préparées. Désactivé par défaut pour la compatibilité avec PgBouncer. |
| `database.primary`                                       | `false`                                                              | Serveur de base de données primaire cible. Ceci est utilisé pour spécifier un FQDN dédié à cibler lors de l'exécution de `database.migrations` du registre. Le `host` sera utilisé pour exécuter `database.migrations` lorsqu'il n'est pas spécifié. |
| `database.pool.maxidle`                                  | `0`                                                                  | Le nombre maximum de connexions dans le pool de connexions inactives. Si `maxopen` est inférieur à `maxidle`, alors `maxidle` est réduit pour correspondre à la limite de `maxopen`. Zéro ou non spécifié signifie aucune connexion inactive. |
| `database.pool.maxopen`                                  | `0`                                                                  | Le nombre maximum de connexions ouvertes à la base de données. Si `maxopen` est inférieur à `maxidle`, alors `maxidle` est réduit pour correspondre à la limite de `maxopen`. Zéro ou non spécifié signifie des connexions ouvertes illimitées. |
| `database.pool.maxlifetime`                              | `0`                                                                  | La durée maximale pendant laquelle une connexion peut être réutilisée. Les connexions expirées peuvent être fermées paresseusement avant la réutilisation. Zéro ou non spécifié signifie une réutilisation illimitée. |
| `database.pool.maxidletime`                              | `0`                                                                  | La durée maximale pendant laquelle une connexion peut être inactive. Les connexions expirées peuvent être fermées paresseusement avant la réutilisation. Zéro ou non spécifié signifie une durée illimitée. |
| `database.loadBalancing.enabled`                         | `false`                                                              | Activer l'équilibrage de charge de la base de données. Il s'agit d'une fonctionnalité expérimentale qui ne doit pas être utilisée dans des environnements de production. |
| `database.loadBalancing.nameserver.host`                 | `localhost`                                                          | L'hôte du serveur de noms à utiliser pour la recherche de l'enregistrement DNS. |
| `database.loadBalancing.nameserver.port`                 | `8600`                                                               | Le port du serveur de noms à utiliser pour la recherche de l'enregistrement DNS. |
| `database.loadBalancing.record`                          |                                                                      | L'enregistrement SRV à rechercher. Cette option est requise pour que la découverte de services fonctionne. |
| `database.loadBalancing.replicaCheckInterval`            | `1m`                                                                 | La durée minimale entre les vérifications de l'état d'un réplica. |
| `database.migrations.enabled`                            | `true`                                                               | Activer le job de migrations pour exécuter automatiquement les migrations lors du déploiement initial et des mises à niveau du Chart. Notez que les migrations peuvent également être exécutées manuellement depuis tout pod Registry en cours d'exécution. |
| `database.migrations.activeDeadlineSeconds`              | `3600`                                                               | Définir [activeDeadlineSeconds](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup) sur le job de migrations. |
| `database.migrations.annotations`                        | `{}`                                                                 | Annotations supplémentaires à ajouter au job de migrations. |
| `database.migrations.backoffLimit`                       | `6`                                                                  | Définir [backoffLimit](https://kubernetes.io/docs/concepts/workloads/controllers/job/#job-termination-and-cleanup) sur le job de migrations. |
| `database.backgroundMigrations.enabled`                  | `false`                                                              | Activer les migrations en arrière-plan pour la base de données. Il s'agit d'une fonctionnalité expérimentale pour la base de données de métadonnées du Registry. Ne pas utiliser en production. Voir la [spécification](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/spec/gitlab/database-background-migrations.md?ref_type=heads) pour une explication détaillée de son fonctionnement. |
| `database.backgroundMigrations.jobInterval`              |                                                                      | L'intervalle de veille entre chaque exécution du worker de job de migration en arrière-plan. Lorsqu'il n'est pas spécifié, [une valeur par défaut est définie par le registre](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#backgroundmigrations). |
| `database.backgroundMigrations.maxJobRetries`            |                                                                      | Le nombre maximum de tentatives pour un job de migration en arrière-plan échoué. Lorsqu'il n'est pas spécifié, [une valeur par défaut est définie par le registre](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#backgroundmigrations). |
| `database.metrics.enabled`                               | `false`                                                              | Lorsqu'il est défini sur `true`, active la collecte des métriques de la base de données. Il s'agit d'une fonctionnalité expérimentale qui ne doit pas être utilisée en production. Nécessite la version 4.27.0 ou ultérieure du registre, la base de données de métadonnées (`database.enabled: true`) et le cache Redis (`redis.cache.enabled: true`) pour le verrouillage distribué. |
| `database.metrics.interval`                              | `10s`                                                                | L'intervalle auquel les métriques sont collectées depuis la base de données. |
| `database.metrics.leaseDuration`                         | `30s`                                                                | La durée pendant laquelle le verrou Redis est maintenu par le collecteur de métriques. Doit être plus long que `interval` pour garantir une collecte continue par la même instance. |
| `gc.disabled`                                            | `true`                                                               | Lorsqu'il est défini sur `true`, les workers GC en ligne sont désactivés. |
| `gc.maxbackoff`                                          | `24h`                                                                | La durée maximale de backoff exponentiel utilisée pour dormir entre les exécutions des workers lorsqu'une erreur se produit. Également appliqué lorsqu'il n'y a pas de tâches à traiter, sauf si `gc.noidlebackoff` est `true`. Veuillez noter que ce n'est pas le maximum absolu, car un facteur de gigue aléatoire allant jusqu'à 33 % est toujours ajouté. |
| `gc.noidlebackoff`                                       | `false`                                                              | Lorsqu'il est défini sur `true`, désactive les backoffs exponentiels entre les exécutions des workers lorsqu'il n'y a pas de tâches à traiter. |
| `gc.transactiontimeout`                                  | `10s`                                                                | Le délai d'expiration des transactions de base de données pour chaque exécution de worker. Chaque worker démarre une transaction de base de données au début. L'exécution du worker est annulée si ce délai d'expiration est dépassé afin d'éviter les transactions bloquées ou de longue durée. |
| `gc.blobs.disabled`                                      | `false`                                                              | Lorsqu'il est défini sur `true`, le worker GC pour les blobs est désactivé. |
| `gc.blobs.interval`                                      | `5s`                                                                 | L'intervalle de veille initial entre chaque exécution de worker. |
| `gc.blobs.storagetimeout`                                | `5s`                                                                 | Le délai d'expiration pour les opérations de stockage. Utilisé pour limiter la durée des requêtes de suppression des blobs orphelins sur le backend de stockage. |
| `gc.manifests.disabled`                                  | `false`                                                              | Lorsqu'il est défini sur `true`, le worker GC pour les manifests est désactivé. |
| `gc.manifests.interval`                                  | `5s`                                                                 | L'intervalle de veille initial entre chaque exécution de worker. |
| `gc.reviewafter`                                         | `24h`                                                                | La durée minimale après laquelle le garbage collector doit récupérer un enregistrement pour révision. `-1` signifie aucune attente. |
| `securityContext.fsGroup`                                | `1000`                                                               | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.runAsUser`                              | `1000`                                                               | ID utilisateur sous lequel le pod doit être démarré |
| `securityContext.fsGroupChangePolicy`                    |                                                                      | Politique de modification de la propriété et des autorisations du volume (nécessite Kubernetes 1.23) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                                     | Profil Seccomp à utiliser |
| `containerSecurityContext`                               |                                                                      | Remplacer le [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel le conteneur est démarré |
| `containerSecurityContext.runAsUser`                     | `1000`                                                               | Permet de remplacer l'ID utilisateur du contexte de sécurité spécifique sous lequel le conteneur est démarré |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                              | Contrôle si un processus du conteneur Gitaly peut obtenir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                               | Contrôle si le conteneur s'exécute avec un utilisateur non-root |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                          | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                              | Indique si le jeton d'accès du ServiceAccount par défaut doit être monté dans les pods |
| `serviceAccount.enabled`                                 | `false`                                                              | Indique si un ServiceAccount doit être utilisé |
| `serviceLabels`                                          | `{}`                                                                 | Labels de service supplémentaires |
| `tokenService`                                           | `container_registry`                                                 | Service de jeton JWT |
| `tokenIssuer`                                            | `gitlab-issuer`                                                      | Émetteur de jeton JWT |
| `tolerations`                                            | `[]`                                                                 | Labels de tolérance pour l'affectation des pods |
| `affinity`                                               | `{}`                                                                 | Règles d'affinité pour l'affectation des pods |
| `middleware.storage`                                     |                                                                      | Couche de configuration pour le stockage middleware ([s3 par exemple](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#example-middleware-configuration)) |
| `redis.cache.enabled`                                    | `false`                                                              | Lorsqu'il est défini sur `true`, le cache Redis est activé. Cette fonctionnalité dépend de l'activation de la [base de données de métadonnées](#database). Les métadonnées du dépôt seront mises en cache sur l'instance Redis configurée. |
| `redis.cache.host`                                       | `<Redis URL>`                                                        | Le nom d'hôte de l'instance Redis. Si vide, la valeur sera remplie avec `global.redis.host:global.redis.port`. |
| `redis.cache.port`                                       | `6379`                                                               | Le port de l'instance Redis. |
| `redis.cache.cluster`                                    | `[]`                                                                 | Liste d'adresses avec hôte et port. |
| `redis.cache.sentinels`                                  | `[]`                                                                 | Liste des sentinelles avec hôte et port. |
| `redis.cache.mainname`                                   |                                                                      | Le nom du serveur principal. Applicable uniquement pour Sentinel. |
| `redis.cache.username`                                   |                                                                      | Le nom d'utilisateur utilisé pour se connecter à l'instance Redis. |
| `redis.cache.password.enabled`                           | `false`                                                              | Indique si le cache Redis utilisé par le Registry est protégé par un mot de passe. |
| `redis.cache.password.secret`                            | `gitlab-redis-secret`                                                | Nom du secret contenant le mot de passe Redis. Il sera automatiquement créé s'il n'est pas fourni, lorsque la fonctionnalité `shared-secrets` est activée. |
| `redis.cache.password.key`                               | `redis-password`                                                     | Clé du secret dans laquelle le mot de passe Redis est stocké. |
| `redis.cache.sentinelpassword.enabled`                   | `false`                                                              | Indique si les Sentinelles Redis sont protégées par un mot de passe. Si `redis.cache.sentinelpassword` est vide, les valeurs de `global.redis.sentinelAuth` sont utilisées. Utilisé uniquement lorsque `redis.cache.sentinels` est défini. |
| `redis.cache.sentinelpassword.secret`                    | `gitlab-redis-secret`                                                | Nom du secret contenant le mot de passe de la Sentinelle Redis. |
| `redis.cache.sentinelpassword.key`                       | `redis-sentinel-password`                                            | Clé du secret dans laquelle le mot de passe de la Sentinelle Redis est stocké. |
| `redis.cache.db`                                         | `0`                                                                  | Le nom de la base de données à utiliser pour chaque connexion. |
| `redis.cache.dialtimeout`                                | `0s`                                                                 | Le délai d'expiration pour la connexion à l'instance Redis. Par défaut, aucun délai d'expiration. |
| `redis.cache.readtimeout`                                | `0s`                                                                 | Le délai d'expiration pour la lecture depuis l'instance Redis. Par défaut, aucun délai d'expiration. |
| `redis.cache.writetimeout`                               | `0s`                                                                 | Le délai d'expiration pour l'écriture vers l'instance Redis. Par défaut, aucun délai d'expiration. |
| `redis.cache.tls.enabled`                                | `false`                                                              | Définir sur `true` pour activer TLS. |
| `redis.cache.tls.insecure`                               | `false`                                                              | Définir sur `true` pour désactiver la vérification du nom de serveur lors de la connexion via TLS. |
| `redis.cache.pool.size`                                  | `10`                                                                 | Le nombre maximum de connexions socket. La valeur par défaut est 10 connexions. |
| `redis.cache.pool.maxlifetime`                           | `1h`                                                                 | L'âge de connexion à partir duquel le client retire une connexion. Par défaut, les connexions âgées ne sont pas fermées. |
| `redis.cache.pool.idletimeout`                           | `300s`                                                               | Durée d'attente avant de fermer les connexions inactives. |
| `redis.rateLimiting.enabled`                             | `false`                                                              | Lorsqu'il est défini sur `true`, le limiteur de débit Redis est activé. Cette fonctionnalité est en cours de développement. |
| `redis.rateLimiting.host`                                | `<Redis URL>`                                                        | Le nom d'hôte de l'instance Redis. Si vide, la valeur sera remplie avec `global.redis.host:global.redis.port`. |
| `redis.rateLimiting.port`                                | `6379`                                                               | Le port de l'instance Redis. |
| `redis.rateLimiting.cluster`                             | `[]`                                                                 | Liste d'adresses avec hôte et port. |
| `redis.rateLimiting.sentinels`                           | `[]`                                                                 | Liste des sentinelles avec hôte et port. |
| `redis.rateLimiting.mainname`                            |                                                                      | Le nom du serveur principal. Applicable uniquement pour Sentinel. |
| `redis.rateLimiting.username`                            |                                                                      | Le nom d'utilisateur utilisé pour se connecter à l'instance Redis. |
| `redis.rateLimiting.password.enabled`                    | `false`                                                              | Indique si l'instance Redis est protégée par un mot de passe. |
| `redis.rateLimiting.password.secret`                     | `gitlab-redis-secret`                                                | Nom du secret contenant le mot de passe Redis. Il sera automatiquement créé s'il n'est pas fourni, lorsque la fonctionnalité `shared-secrets` est activée. |
| `redis.rateLimiting.password.key`                        | `redis-password`                                                     | Clé du secret dans laquelle le mot de passe Redis est stocké. |
| `redis.rateLimiting.sentinelpassword.enabled`                   | `false`                                                              | Indique si les Sentinelles Redis sont protégées par un mot de passe. Si `redis.rateLimiting.sentinelpassword` est vide, les valeurs de `global.redis.sentinelAuth` sont utilisées. Utilisé uniquement lorsque `redis.rateLimiting.sentinels` est défini. |
| `redis.rateLimiting.sentinelpassword.secret`                    | `gitlab-redis-secret`                                                | Nom du secret contenant le mot de passe de la Sentinelle Redis. |
| `redis.rateLimiting.sentinelpassword.key`                       | `redis-sentinel-password`                                            | Clé du secret dans laquelle le mot de passe de la Sentinelle Redis est stocké. |
| `redis.rateLimiting.db`                                  | `0`                                                                  | Le nom de la base de données à utiliser pour chaque connexion. |
| `redis.rateLimiting.dialtimeout`                         | `0s`                                                                 | Le délai d'expiration pour la connexion à l'instance Redis. Par défaut, aucun délai d'expiration. |
| `redis.rateLimiting.readtimeout`                         | `0s`                                                                 | Le délai d'expiration pour la lecture depuis l'instance Redis. Par défaut, aucun délai d'expiration. |
| `redis.rateLimiting.writetimeout`                        | `0s`                                                                 | Le délai d'expiration pour l'écriture vers l'instance Redis. Par défaut, aucun délai d'expiration. |
| `redis.rateLimiting.tls.enabled`                         | `false`                                                              | Définir sur `true` pour activer TLS. |
| `redis.rateLimiting.tls.insecure`                        | `false`                                                              | Définir sur `true` pour désactiver la vérification du nom de serveur lors de la connexion via TLS. |
| `redis.rateLimiting.pool.size`                           | `10`                                                                 | Le nombre maximum de connexions socket. |
| `redis.rateLimiting.pool.maxlifetime`                    | `1h`                                                                 | L'âge de connexion à partir duquel le client retire une connexion. Par défaut, les connexions âgées ne sont pas fermées. |
| `redis.rateLimiting.pool.idletimeout`                    | `300s`                                                               | Durée d'attente avant de fermer les connexions inactives. |
| `redis.loadBalancing.enabled`                            | `false`                                                              | Lorsqu'il est défini sur `true`, la connexion Redis pour l'[équilibrage de charge](#load-balancing) est activée. |
| `redis.loadBalancing.host`                               | `<Redis URL>`                                                        | Le nom d'hôte de l'instance Redis. Si vide, la valeur sera remplie avec `global.redis.host:global.redis.port`. |
| `redis.loadBalancing.port`                               | `6379`                                                               | Le port de l'instance Redis. |
| `redis.loadBalancing.cluster`                            | `[]`                                                                 | Liste d'adresses avec hôte et port. |
| `redis.loadBalancing.sentinels`                          | `[]`                                                                 | Liste des sentinelles avec hôte et port. |
| `redis.loadBalancing.mainname`                           |                                                                      | Le nom du serveur principal. Applicable uniquement pour Sentinel. |
| `redis.loadBalancing.username`                           |                                                                      | Le nom d'utilisateur utilisé pour se connecter à l'instance Redis. |
| `redis.loadBalancing.password.enabled`                   | `false`                                                              | Indique si l'instance Redis est protégée par un mot de passe. |
| `redis.loadBalancing.password.secret`                    | `gitlab-redis-secret`                                                | Nom du secret contenant le mot de passe Redis. Il sera automatiquement créé s'il n'est pas fourni, lorsque la fonctionnalité `shared-secrets` est activée. |
| `redis.loadBalancing.password.key`                       | `redis-password`                                                     | Clé du secret dans laquelle le mot de passe Redis est stocké. |
| `redis.loadBalancing.db`                                 | `0`                                                                  | Le nom de la base de données à utiliser pour chaque connexion. |
| `redis.loadBalancing.dialtimeout`                        | `0s`                                                                 | Le délai d'expiration pour la connexion à l'instance Redis. Par défaut, aucun délai d'expiration. |
| `redis.loadBalancing.readtimeout`                        | `0s`                                                                 | Le délai d'expiration pour la lecture depuis l'instance Redis. Par défaut, aucun délai d'expiration. |
| `redis.loadBalancing.writetimeout`                       | `0s`                                                                 | Le délai d'expiration pour l'écriture vers l'instance Redis. Par défaut, aucun délai d'expiration. |
| `redis.loadBalancing.tls.enabled`                        | `false`                                                              | Définir sur `true` pour activer TLS. |
| `redis.loadBalancing.tls.insecure`                       | `false`                                                              | Définir sur `true` pour désactiver la vérification du nom de serveur lors de la connexion via TLS. |
| `redis.loadBalancing.pool.size`                          | `10`                                                                 | Le nombre maximum de connexions socket. |
| `redis.loadBalancing.pool.maxlifetime`                   | `1h`                                                                 | L'âge de connexion à partir duquel le client retire une connexion. Par défaut, les connexions âgées ne sont pas fermées. |
| `redis.loadBalancing.pool.idletimeout`                   | `300s`                                                               | Durée d'attente avant de fermer les connexions inactives. |

## Exemples de configuration du chart {#chart-configuration-examples}

### `pullSecrets` {#pullsecrets}

`pullSecrets` vous permet de vous authentifier auprès d'un registre privé pour extraire des images pour un pod.

Des détails supplémentaires sur les registres privés et leurs méthodes d'authentification sont disponibles dans la [documentation Kubernetes](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Voici un exemple d'utilisation de `pullSecrets` :

```yaml
image:
  repository: my.registry.repository
  tag: latest
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

Cette section contrôle si un ServiceAccount doit être créé et si le jeton d'accès par défaut doit être monté dans les pods.

| Nom                           |  Type   | Défaut | Description |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | Booléen | `false` | Contrôle si le jeton d'accès du ServiceAccount par défaut doit être monté dans les pods. Vous ne devez pas activer cela à moins que certains sidecars ne l'exigent pour fonctionner correctement (par exemple, Istio). |
| `enabled`                      | Booléen | `false` | Indique si un ServiceAccount doit être utilisé. |

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

### `affinity` {#affinity}

`affinity` est un paramètre optionnel qui vous permet de définir l'un ou les deux :

- Règles `podAntiAffinity` pour :
  - Ne pas planifier les pods dans le même domaine que les pods correspondant à l'expression de la `topology key`.
  - Définir deux modes de règles `podAntiAffinity` : requis (`requiredDuringSchedulingIgnoredDuringExecution`) et préféré (`preferredDuringSchedulingIgnoredDuringExecution`). En utilisant la variable `antiAffinity` dans `values.yaml`, définissez le paramètre sur `soft` pour que le mode préféré soit appliqué, ou définissez-le sur `hard` pour que le mode requis soit appliqué.
- Règles `nodeAffinity` pour :
  - Planifier les pods sur des nœuds appartenant à une zone ou plusieurs zones spécifiques.
  - Définir deux modes de règles `nodeAffinity` : requis (`requiredDuringSchedulingIgnoredDuringExecution`) et préféré (`preferredDuringSchedulingIgnoredDuringExecution`). Lorsqu'il est défini sur `soft`, le mode préféré est appliqué. Lorsqu'il est défini sur `hard`, le mode requis est appliqué. Cette règle est implémentée uniquement pour le chart `registry` et le chart `gitlab` ainsi que tous ses sous-charts sauf `webservice` et `sidekiq`.

`nodeAffinity` n'implémente que l'[opérateur `In`](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#operators).

Pour plus d'informations, voir [la documentation Kubernetes correspondante](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity).

L'exemple suivant définit `affinity`, avec `nodeAffinity` et `antiAffinity` tous deux définis sur `hard` :

```yaml
nodeAffinity: "hard"
antiAffinity: "hard"
affinity:
  nodeAffinity:
    key: "test.com/zone"
    values:
    - us-east1-a
    - us-east1-b
  podAntiAffinity:
    topologyKey: "test.com/hostname"
```

### `annotations` {#annotations}

`annotations` vous permet d'ajouter des annotations aux pods du registre.

Voici un exemple d'utilisation de `annotations`

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## Activer le sous-chart {#enable-the-sub-chart}

La façon dont nous avons choisi d'implémenter les sous-charts compartimentés inclut la possibilité de désactiver les composants que vous ne souhaitez peut-être pas dans un déploiement donné. Pour cette raison, le premier paramètre sur lequel vous devez décider est `enabled`.

Par défaut, le Registry est activé dès l'installation. Si vous souhaitez le désactiver, définissez `enabled: false`.

## Activer les ressources requises pour l'application {#enable-resources-required-for-the-application}

Les ressources Service, Deployment, HPA et PDB sont activées par la valeur `registry.api.enabled` (par défaut : `true`).

Pour en savoir plus sur l'utilisation de ce paramètre sur GitLab.com, consultez [Migrations post-déploiement du registre de conteneurs sur GitLab.com](../../development/registry_post_deployment_migrations_on_gitlab_com.md).

## Configuration de `image` {#configuring-the-image}

Cette section détaille les paramètres de l'image de conteneur utilisée par le [Deployment](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/deployment.yaml) de ce sous-chart. Vous pouvez modifier la version incluse du Registry et `pullPolicy`.

Paramètres par défaut :

- `tag: 'v4.15.2-gitlab'`
- `pullPolicy: 'IfNotPresent'`

## Configuration de `service` {#configuring-the-service}

Cette section contrôle le nom et le type du [Service](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/templates/service.yaml). Ces paramètres seront renseignés par [`values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/registry/values.yaml).

Par défaut, le Service est configuré comme suit :

| Nom             |  Type  | Défaut     | Description |
|:-----------------|:------:|:------------|:------------|
| `name`           | Chaîne | `registry`  | Configure le nom du service |
| `type`           | Chaîne | `ClusterIP` | Configure le type du service |
| `externalPort`   |  Int   | `5000`      | Port exposé par le Service |
| `internalPort`   |  Int   | `5000`      | Port utilisé par le pod pour accepter les requêtes du service |
| `clusterIP`      | Chaîne | `null`      | Permet de configurer une IP de cluster personnalisée si nécessaire |
| `loadBalancerIP` | Chaîne | `null`      | Permet de configurer une adresse IP LoadBalancer personnalisée si nécessaire |

## Configuration de `ingress` {#configuring-the-ingress}

Cette section contrôle l'Ingress du registre.

| Nom                   |  Type   | Défaut | Description |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | Chaîne  |         | Valeur à utiliser dans le champ `apiVersion`. |
| `annotations`          | Chaîne  |         | Ce champ correspond exactement aux `annotations` standard pour [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/). |
| `configureCertmanager` | Booléen |         | Active ou désactive l'annotation Ingress `cert-manager.io/issuer` et `acme.cert-manager.io/http01-edit-in-place`. Pour plus d'informations, consultez les [exigences TLS pour GitLab Pages](../../installation/tls.md). |
| `enabled`              | Booléen | `false` | Paramètre qui contrôle la création d'objets Ingress pour les services qui les prennent en charge. Lorsque `false`, le paramètre `global.ingress.enabled` est utilisé. |
| `tls.enabled`          | Booléen | `true`  | Lorsqu'il est défini sur `false`, vous désactivez TLS pour le sous-chart Registry. Cela est principalement utile dans les cas où vous ne pouvez pas utiliser la terminaison TLS au niveau `ingress-level`, par exemple lorsque vous avez un proxy de terminaison TLS avant le contrôleur Ingress. |
| `tls.secretName`       | Chaîne  |         | Le nom du secret TLS Kubernetes qui contient un certificat et une clé valides pour l'URL du registre. Lorsqu'il n'est pas défini, `global.ingress.tls.secretName` est utilisé à la place. Par défaut, non défini. |
| `tls.cipherSuites`     |  Tableau  | `[]`    | La liste des suites de chiffrement que le registre de conteneurs doit présenter au client lors de la négociation TLS. |

## Configuration de TLS {#configuring-tls}

Le registre de conteneurs prend en charge TLS, ce qui sécurise sa communication avec les autres composants, y compris `nginx-ingress`.

Prérequis pour configurer TLS :

- Le certificat TLS doit inclure le nom d'hôte du service Registry (par exemple, `RELEASE-registry.default.svc`) dans le Nom commun (CN) ou le Nom alternatif du sujet (SAN).
- Après la génération du certificat TLS :
  - Créer un [secret TLS Kubernetes](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets)
  - Créer un autre Secret qui contient uniquement le certificat CA du certificat TLS avec la clé `ca.crt`.

Pour activer TLS :

1. Définir `registry.tls.enabled` sur `true`.
1. Définir `global.hosts.registry.protocol` sur `https`.
1. Passer les noms des secrets à `registry.tls.secretName` et `global.certificates.customCAs` en conséquence.

Lorsque `registry.tls.verify` est `true`, vous devez passer le nom du secret du certificat CA à `registry.tls.caSecretName`. Cela est nécessaire pour les certificats auto-signés et les autorités de certification personnalisées. Ce Secret est utilisé par NGINX pour vérifier le certificat TLS du Registry. Si vous utilisez [l'API Gateway](../../advanced/gateway-api/_index.md#tls-between-gateway-and-backend-services), le contrôleur de l'API Gateway vérifie toujours le certificat.

Par exemple :

```yaml
global:
  certificates:
    customCAs:
    - secret: registry-tls-ca
  hosts:
    registry:
      protocol: https

registry:
  tls:
    enabled: true
    secretName: registry-tls
    verify: true
    caSecretName: registry-tls-ca
```

### Suites de chiffrement du registre de conteneurs {#container-registry-cipher-suites}

Normalement, l'option `tls.cipherSuites` ne doit être utilisée que dans des configurations très inhabituelles où le registre est déployé en mode autonome et/ou un Ingress non-standard est utilisé qui ne prend pas en charge les suites de chiffrement modernes. Dans un déploiement GitLab standard, l'Ingress NGINX choisira la version TLS la plus élevée prise en charge par le backend du registre de conteneurs, qui est actuellement TLS1.3. TLS1.3 ne permet pas de configurer les chiffrements et est sécurisé par défaut. Dans le cas où TLS1.3 n'est pas disponible pour une raison quelconque, la liste de chiffrements TLS1.2 par défaut que le registre de conteneurs utilise est également compatible avec les paramètres par défaut de l'Ingress NGINX et est également sécurisée.

### Configuration de TLS pour le port de débogage {#configuring-tls-for-the-debug-port}

Le port de débogage du Registry prend également en charge TLS. Le port de débogage est utilisé pour les contrôles de vivacité et de disponibilité Kubernetes ainsi que pour exposer un point de terminaison `/metrics` pour Prometheus (si activé).

TLS peut être activé en définissant `registry.debug.tls.enabled` sur `true`. Un [secret TLS Kubernetes](https://kubernetes.io/docs/concepts/configuration/secret/#tls-secrets) peut être fourni dans `registry.debug.tls.secretName` dédié à la configuration TLS du port de débogage. Si un secret dédié n'est pas spécifié, la configuration de débogage utilisera par défaut `registry.tls.secretName` avec la configuration TLS ordinaire du registre.

Pour que Prometheus scrape le point de terminaison `/metrics/` en utilisant `https` \- une configuration supplémentaire est requise pour l'attribut CommonName du certificat ou une entrée SubjectAlternativeName. Voir [Configuration de Prometheus pour scraper les points de terminaison compatibles TLS](../../installation/tools.md#configure-prometheus-to-scrape-tls-enabled-endpoints) pour ces exigences.

## Configuration de `networkpolicy` {#configuring-the-networkpolicy}

Cette section contrôle la [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/) du registre. Cette configuration est optionnelle et est utilisée pour limiter l'egress et l'ingress du registre vers des points de terminaison spécifiques et l'ingress vers des points de terminaison spécifiques.

| Nom              |  Type   | Défaut | Description |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | Booléen | `false` | Ce paramètre active le `NetworkPolicy` pour le registre |
| `ingress.enabled` | Booléen | `false` | Lorsqu'il est défini sur `true`, la politique réseau `Ingress` sera activée. Cela bloquera toutes les connexions Ingress sauf si des règles sont spécifiées. |
| `ingress.rules`   |  Tableau  | `[]`    | Règles pour la politique Ingress, pour plus de détails voir <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> et l'exemple ci-dessous |
| `egress.enabled`  | Booléen | `false` | Lorsqu'il est défini sur `true`, la politique réseau `Egress` sera activée. Cela bloquera toutes les connexions egress sauf si des règles sont spécifiées. |
| `egress.rules`    |  Tableau  | `[]`    | Règles pour la politique egress, pour plus de détails voir <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> et l'exemple ci-dessous |

### Exemple de politique pour empêcher les connexions à tous les points de terminaison internes {#example-policy-for-preventing-connections-to-all-internal-endpoints}

Le service Registry nécessite normalement des connexions egress vers le stockage d'objets, des connexions ingress provenant de clients Docker, et kube-dns pour les recherches DNS. Cela ajoute les restrictions réseau suivantes au service Registry :

- Autorise les requêtes Ingress :
  - Depuis les pods `sidekiq` , `webservice` et `nginx-ingress` vers le port `5000`
  - Depuis le pod `Prometheus` vers le port `9235`
- Autorise les requêtes Egress :
  - Vers `kube-dns` sur le port `53`
  - Vers des points de terminaison comme le point de terminaison AWS VPC pour S3 ou STS `172.16.1.0/24` sur le port `443`
  - Vers Internet `0.0.0.0/0` sur le port `443`

_Notez que le service du registre nécessite une connectivité sortante vers l'Internet public pour les images sur le [stockage d'objets externe](../../advanced/external-object-storage) si aucun point de terminaison n'est utilisé_

L'exemple est basé sur l'hypothèse que `kube-dns` a été déployé dans le namespace `kube-system`, `prometheus` a été déployé dans le namespace `monitoring` et `nginx-ingress` a été déployé dans le namespace `nginx-ingress`.

```yaml
networkpolicy:
  enabled: true
  ingress:
    enabled: true
    rules:
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 5000
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
          - podSelector:
              matchLabels:
                app: sidekiq
        ports:
          - port: 5000
      - from:
          - podSelector:
              matchLabels:
                app: webservice
        ports:
          - port: 5000
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
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
            - 10.0.0.0/8
```

## Configuration de KEDA {#configuring-keda}

Cette section `keda` active l'installation de [KEDA](https://keda.sh/) `ScaledObjects` au lieu des `HorizontalPodAutoscalers` ordinaires. Cette configuration est optionnelle et peut être utilisée lorsqu'il est nécessaire d'effectuer une mise à l'échelle automatique basée sur des métriques personnalisées ou externes.

La plupart des paramètres utilisent par défaut les valeurs définies dans la section `hpa` le cas échéant.

Si les conditions suivantes sont vraies, des déclencheurs CPU et mémoire sont ajoutés automatiquement en fonction des seuils CPU et mémoire définis dans la section `hpa` :

- `triggers` n'est pas défini.
- Le paramètre `request.cpu.request` ou `request.memory.request` correspondant est également défini sur une valeur non nulle.

Si aucun déclencheur n'est défini, le `ScaledObject` n'est pas créé.

Consultez la [documentation KEDA](https://keda.sh/docs/2.10/concepts/scaling-deployments/) pour plus de détails sur ces paramètres.

| Nom                            |  Type   | Défaut                         | Description |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | Booléen | `false`                         | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` au lieu de `HorizontalPodAutoscalers` |
| `pollingInterval`               | Entier | `30`                            | L'intervalle de vérification de chaque déclencheur |
| `cooldownPeriod`                | Entier | `300`                           | La période d'attente après le dernier déclencheur signalé actif avant de remettre la ressource à l'échelle 0 |
| `minReplicaCount`               | Entier | `hpa.minReplicas`               | Nombre minimum de réplicas vers lequel KEDA réduira la ressource. |
| `maxReplicaCount`               | Entier | `hpa.maxReplicas`               | Nombre maximum de réplicas vers lequel KEDA augmentera la ressource. |
| `fallback`                      |   Map   |                                 | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `hpaName`                       | Chaîne  | `keda-hpa-{scaled-object-name}` | Le nom de la ressource HPA que KEDA créera. |
| `restoreToOriginalReplicaCount` | Booléen |                                 | Indique si la ressource cible doit être remise à l'échelle au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `behavior`                      |   Map   | `hpa.behavior`                  | Les spécifications pour le comportement de mise à l'échelle ascendante et descendante. |
| `triggers`                      |  Tableau  |                                 | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |

### Exemple de politique pour empêcher les connexions à tous les points de terminaison internes {#example-policy-for-preventing-connections-to-all-internal-endpoints-1}

Le service Registry nécessite normalement des connexions egress vers le stockage d'objets, des connexions ingress provenant de clients Docker, et kube-dns pour les recherches DNS. Cela ajoute les restrictions réseau suivantes au service Registry :

- Toutes les requêtes egress vers le réseau local sur `10.0.0.0/8` port 53 sont autorisées (pour kubeDNS)
- Les autres requêtes egress vers le réseau local sur `10.0.0.0/8` sont restreintes
- Les requêtes egress en dehors de `10.0.0.0/8` sont autorisées

_Notez que le service du registre nécessite une connectivité sortante vers l'Internet public pour les images sur le [stockage d'objets externe](../../advanced/external-object-storage)_

```yaml
networkpolicy:
  enabled: true
  egress:
    enabled: true
    # The following rules enable traffic to all external
    # endpoints, except the local
    # network (except DNS requests)
    rules:
      - to:
        - ipBlock:
            cidr: 10.0.0.0/8
        ports:
        - port: 53
          protocol: UDP
      - to:
        - ipBlock:
            cidr: 0.0.0.0/0
            except:
            - 10.0.0.0/8
```

## Définition de la configuration du Registry {#defining-the-registry-configuration}

Les propriétés suivantes de ce chart concernent la configuration du conteneur [registry](https://hub.docker.com/_/registry/) sous-jacent. Seules les valeurs les plus critiques pour l'intégration avec GitLab sont exposées. Pour cette intégration, nous utilisons les paramètres `auth.token.x` de [Docker Distribution](https://github.com/docker/distribution) , contrôlant l'authentification au registre via les [jetons d'authentification](https://distribution.github.io/distribution/spec/auth/token/) JWT.

### `httpSecret` {#httpsecret}

Le champ `httpSecret` est une map contenant deux éléments : `secret` et `key`.

Le contenu de la clé référencée correspond à la valeur `http.secret` de [registry](https://hub.docker.com/_/registry/). Cette valeur doit être renseignée avec une chaîne aléatoire générée de manière cryptographique.

Le job `shared-secrets` créera automatiquement ce secret s'il n'est pas fourni. Il sera rempli avec une chaîne alphanumérique de 128 caractères générée de manière sécurisée et encodée en base64.

Pour créer ce secret manuellement :

```shell
kubectl create secret generic gitlab-registry-httpsecret --from-literal=secret=strongrandomstring
```

### Secret de notification {#notification-secret}

Le secret de notification est utilisé pour effectuer des rappels vers l'application GitLab de différentes manières, notamment pour que Geo aide à gérer la synchronisation des données du registre de conteneurs entre les sites primaires et secondaires.

L'objet secret `notificationSecret` sera automatiquement créé s'il n'est pas fourni, lorsque la fonctionnalité `shared-secrets` est activée.

Pour créer ce secret manuellement :

```shell
kubectl create secret generic gitlab-registry-notification --from-literal=secret=[\"strongrandomstring\"]
```

Procédez ensuite à la configuration de ces paramètres, en vous assurant que la valeur `secret` est définie sur le nom du secret créé ci-dessus.

```yaml
global:
  # To provide your own secret
  registry:
    notificationSecret:
        secret: gitlab-registry-notification
        key: secret
```

Si vous utilisez Geo et souhaitez répliquer le registre de conteneurs, suivez les deux étapes suivantes :

1. Dans les configurations du site primaire :

   ```yaml
   global:
     # To provide your own secret, as described above
     registry:
       notificationSecret:
           secret: gitlab-registry-notification
           key: secret
     geo:
       registry:
         replication:
           enabled: true
   ```

1. Dans les configurations du site secondaire :

   ```yaml
   global:
     geo:
       registry:
         replication:
           enabled: true
           primaryApiUrl: <URL to primary registry>
   ```

   Le `primaryApiUrl` est utilisé par le site secondaire pour effectuer des extractions (pulls) depuis le site primaire.

### Secret du cache Redis {#redis-cache-secret}

Le secret du cache Redis est utilisé lorsque `global.redis.auth.enabled` est défini sur `true`.

Lorsque la fonctionnalité `shared-secrets` est activée, l'objet secret `gitlab-redis-secret` est automatiquement créé s'il n'est pas fourni.

Pour créer ce secret manuellement, consultez les [instructions sur le mot de passe Redis](../../installation/secrets.md#redis-password).

### `authEndpoint` {#authendpoint}

Le champ `authEndpoint` est une chaîne fournissant l'URL vers la ou les instances GitLab auprès desquelles le [registry](https://hub.docker.com/_/registry/) s'authentifiera.

La valeur doit inclure uniquement le protocole et le nom d'hôte. Le modèle de chart ajoutera automatiquement le chemin de requête nécessaire. La valeur résultante sera renseignée dans `auth.token.realm` à l'intérieur du conteneur. Par exemple : `authEndpoint: "https://gitlab.example.com"`

Par défaut, ce champ est renseigné avec la configuration du nom d'hôte GitLab définie par les [paramètres globaux](../globals.md).

### `certificate` {#certificate}

Le champ `certificate` est une map contenant deux éléments : `secret` et `key`.

`secret` est une chaîne contenant le nom du [Secret Kubernetes](https://kubernetes.io/docs/concepts/configuration/secret/) qui héberge le bundle de certificats utilisé pour vérifier les tokens créés par la ou les instances GitLab.

`key` est le nom de `key` dans le `Secret` qui héberge le bundle de certificats fourni au conteneur [registry](https://hub.docker.com/_/registry/) en tant que `auth.token.rootcertbundle`.

Exemple par défaut :

```yaml
certificate:
  secret: gitlab-registry
  key: registry-auth.crt
```

### Sonde de disponibilité et de vivacité {#readiness-and-liveness-probe}

Par défaut, une sonde de disponibilité et de vivacité est configurée pour vérifier `/debug/health` sur le port `5001`, qui est le port de débogage.

### `validation` {#validation}

Le champ `validation` est une map qui contrôle le processus de validation des images Docker dans le registre. Lorsque la validation d'image est activée, le registre rejette les images Windows avec des couches étrangères, à moins que le champ `manifests.urls.allow` dans la strophe de validation ne soit explicitement défini pour autoriser ces URL de couches.

La validation n'a lieu que lors du push du manifest, de sorte que les images déjà présentes dans le registre ne sont pas affectées par les modifications apportées aux valeurs de cette section.

La validation d'image est désactivée par défaut.

Pour activer la validation d'image, vous devez définir explicitement `registry.validation.disabled: false`.

#### `manifests` {#manifests}

Le champ `manifests` permet de configurer des politiques de validation propres aux manifests.

La section `urls` contient les champs `allow` et `deny`. Pour que les couches de manifest contenant des URL passent la validation, cette couche doit correspondre à l'une des expressions régulières du champ `allow`, sans correspondre à aucune expression régulière du champ `deny`.

|        Nom        | Type  | Défaut | Description |
|:------------------:|:-----:|:--------|:-----------:|
|  `referencelimit`  |  Int  | `0`     | Le nombre maximum de références, telles que des couches, des configurations d'image et d'autres manifests, qu'un seul manifest peut avoir. Lorsque défini sur `0` (valeur par défaut), cette validation est désactivée. |
| `payloadsizelimit` |  Int  | `0`     | La taille maximale des données en octets des charges utiles de manifest. Lorsque défini sur `0` (valeur par défaut), cette validation est désactivée. |
|    `urls.allow`    | Tableau | `[]`    | Liste d'expressions régulières qui autorisent les URL dans les couches des manifests. Lorsque laissé vide (valeur par défaut), les couches contenant des URL seront rejetées. |
|    `urls.deny`     | Tableau | `[]`    | Liste d'expressions régulières qui restreignent les URL dans les couches des manifests. Lorsque laissé vide (valeur par défaut), aucune couche avec des URL ayant passé la liste `urls.allow` ne sera rejetée |

### `notifications` {#notifications}

Le champ `notifications` est utilisé pour configurer les [notifications du registre](https://distribution.github.io/distribution/about/notifications/#configuration). Sa valeur par défaut est un hash vide.

|    Nom     | Type  | Défaut | Description |
|:-----------:|:-----:|:--------|:-----------:|
| `endpoints` | Tableau | `[]`    | Liste d'éléments où chaque élément correspond à un [endpoint](https://distribution.github.io/distribution/about/configuration/#endpoints) |
|  `events`   | Hash  | `{}`    | Informations fournies dans les notifications d'[événement](https://distribution.github.io/distribution/about/configuration/#events) |

Un exemple de configuration ressemblera à ce qui suit :

```yaml
notifications:
  endpoints:
    - name: FooListener
      url: https://foolistener.com/event
      timeout: 500ms
      # DEPRECATED: use `maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243.
      # When using `maxretries`, `threshold` is ignored: https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#endpoints
      threshold: 10
      maxretries: 10
      backoff: 1s
    - name: BarListener
      url: https://barlistener.com/event
      timeout: 100ms
      # DEPRECATED: use `maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243.
      # When using `maxretries`, `threshold` is ignored: https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#endpoints
      threshold: 3
      maxretries: 5
      backoff: 1s
  events:
    includereferences: true
```

<!-- vale gitlab.Spelling = NO -->

### `hpa` {#hpa}

<!-- vale gitlab.Spelling = YES -->

Le champ `hpa` est un objet qui contrôle le nombre d'instances de [registry](https://hub.docker.com/_/registry/) à créer dans le cadre de l'ensemble. La valeur par défaut est `minReplicas` pour `2`, une valeur de `maxReplicas` de 10, et configure `cpu.targetAverageUtilization` à 75 %.

### `storage` {#storage}

```yaml
storage:
  secret:
  key: config
  extraKey:
```

Le champ `storage` est une référence à un Secret Kubernetes et à la clé associée. Le contenu de ce secret est extrait directement de la [configuration du registre : `storage`](https://distribution.github.io/distribution/about/configuration/#storage). Veuillez consulter cette documentation pour plus de détails.

Des exemples pour les pilotes [AWS S3](https://distribution.github.io/distribution/storage-drivers/s3/) et [Google GCS](https://distribution.github.io/distribution/storage-drivers/gcs/) sont disponibles dans [`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage) :

- [`registry.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.s3.yaml)
- [`registry.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.gcs.yaml)

Pour S3, assurez-vous d'accorder les [autorisations correctes pour le stockage du registre](https://distribution.github.io/distribution/storage-drivers/s3/#s3-permission-scopes). Pour plus d'informations sur la configuration du stockage, consultez le [pilote de stockage du registre de conteneurs](https://docs.gitlab.com/administration/packages/container_registry/#container-registry-storage-driver) dans la documentation d'administration.

Placez le _contenu_ du bloc `storage` dans le secret, et fournissez les éléments suivants dans la map `storage` :

- `secret` : nom du Secret Kubernetes hébergeant le bloc YAML.
- `key` : nom de la clé dans le secret à utiliser. La valeur par défaut est `config`.
- `extraKey` : _(facultatif)_ nom d'une clé supplémentaire dans le secret, qui sera montée dans `/etc/docker/registry/storage/${extraKey}` à l'intérieur du conteneur. Cela peut être utilisé pour fournir le `keyfile` au pilote `gcs`.

```shell
# Example using S3
kubectl create secret generic registry-storage \
    --from-file=config=registry-storage.yaml

# Example using GCS with JSON key
# - Note: `registry.storage.extraKey=gcs.json`
kubectl create secret generic registry-storage \
    --from-file=config=registry-storage.yaml \
    --from-file=gcs.json=example-project-382839-gcs-bucket.json
```

Vous pouvez [désactiver la redirection pour le pilote de stockage](https://docs.gitlab.com/administration/packages/container_registry/#disable-redirect-for-storage-driver), garantissant que tout le trafic passe par le service de registre au lieu d'être redirigé vers un autre backend :

```yaml
storage:
  secret: example-secret
  key: config
  redirect:
    disable: true
```

Si vous choisissez d'utiliser le pilote `filesystem` :

- Vous devrez fournir des volumes persistants pour ces données.
- [`hpa.minReplicas`](#hpa) doit être défini sur `1`
- [`hpa.maxReplicas`](#hpa) doit être défini sur `1`

Dans un souci de résilience et de simplicité, il est recommandé d'utiliser un service externe, tel que `s3`, `gcs`, `azure` ou tout autre stockage d'objets compatible.

> [!note]
> Le chart renseignera `delete.enabled: true` dans cette configuration par défaut si l'utilisateur ne le spécifie pas. Cela permet de maintenir le comportement attendu en accord avec l'utilisation par défaut de MinIO, ainsi qu'avec le package Linux. Toute valeur fournie par l'utilisateur remplacera cette valeur par défaut.

### `middleware.storage` {#middlewarestorage}

La configuration de `middleware.storage` suit la [convention upstream](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#middleware) :

La configuration est assez générique et suit un schéma similaire :

```yaml
middleware:
  # See https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#middleware
  storage:
    - name: cloudfront
      options:
        baseurl: https://abcdefghijklmn.cloudfront.net/
        # `privatekey` is auto-populated with the content from the privatekey Secret.
        privatekeySecret:
          secret: cloudfront-secret-name
          # "key" value is going to be used to generate filename for PEM storage:
          #   /etc/docker/registry/middleware.storage/<index>/<key>
          key: private-key-ABC.pem
        keypairid: ABCEDFGHIJKLMNOPQRST
```

Dans le code ci-dessus, `options.privatekeySecret` est un secret Kubernetes `generic` dont le contenu correspond au contenu d'un fichier PEM :

```shell
kubectl create secret generic cloudfront-secret-name --type=kubernetes.io/ssh-auth --from-file=private-key-ABC.pem=pk-ABCEDFGHIJKLMNOPQRST.pem
```

`privatekey` utilisé en upstream est automatiquement renseigné par le chart à partir du Secret `privatekey` et sera **ignored** s'il est spécifié.

#### Variantes de `keypairid` {#keypairid-variants}

Différents fournisseurs utilisent des noms de champs différents pour le même concept :

|   Fournisseur   | Nom du champ |
|:----------:|:----------:|
| Google CDN | `keyname`  |
| CloudFront | `keypairid` |

> [!note]
> Seule la configuration de la section `middleware.storage` est prise en charge pour le moment.

### `debug` {#debug}

Le port de débogage est activé par défaut et est utilisé pour la sonde de vivacité/disponibilité. De plus, les métriques Prometheus peuvent être activées via les valeurs `metrics`.

```yaml
debug:
  addr:
    port: 5001

metrics:
  enabled: true
```

### `health` {#health}

La propriété `health` est facultative et contient les préférences pour un contrôle de santé périodique du stockage backend du pilote de stockage. Pour plus de détails, consultez la [documentation de configuration](https://distribution.github.io/distribution/about/configuration/#health) Docker.

```yaml
health:
  storagedriver:
    enabled: false
    interval: 10s
    threshold: 3
```

### `reporting` {#reporting}

La propriété `reporting` est facultative et active le [reporting](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#reporting)

```yaml
reporting:
  sentry:
    enabled: true
    dsn: 'https://<key>@sentry.io/<project>'
    environment: 'production'
```

### `profiling` {#profiling}

La propriété `profiling` est facultative et active le [profilage continu](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#profiling)

```yaml
profiling:
  stackdriver:
    enabled: true
    credentials:
      secret: gitlab-registry-profiling-creds
      key: credentials
    service: gitlab-registry
```

### `database` {#database}

{{< history >}}

- [Introduit](https://gitlab.com/groups/gitlab-org/-/epics/5521) dans GitLab 16.4 en tant que fonctionnalité [bêta](https://docs.gitlab.com/policy/development_stages_support/#beta).
- [Généralement disponible](https://gitlab.com/gitlab-org/gitlab/-/issues/423459) dans GitLab 17.3.

{{< /history >}}

La propriété `database` est facultative et active la [base de données de métadonnées](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#database).

Consultez la [documentation d'administration](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/) avant d'activer cette fonctionnalité.

> [!note]
> Cette fonctionnalité nécessite PostgreSQL 13 ou une version plus récente.

```yaml
database:
  enabled: true
  host: registry.db.example.com
  port: 5432
  user: registry
  password:
    secret: gitlab-postgresql-password
    key: postgresql-registry-password
  dbname: registry
  sslmode: verify-full
  ssl:
    secret: gitlab-registry-postgresql-ssl
    clientKey: client-key.pem
    clientCertificate: client-cert.pem
    serverCA: server-ca.pem
  connecttimeout: 5s
  draintimeout: 2m
  preparedstatements: false
  primary: 'primary.record.fqdn'
  pool:
    maxidle: 25
    maxopen: 25
    maxlifetime: 5m
    maxidletime: 5m
  migrations:
    enabled: true
    activeDeadlineSeconds: 3600
    backoffLimit: 6
  backgroundMigrations:
    enabled: true
    maxJobRetries: 3
    jobInterval: 10s
```

#### Équilibrage de charge {#load-balancing}

> [!warning]
> Il s'agit d'une fonctionnalité expérimentale en cours de développement actif qui ne doit pas être utilisée en production.

La section `loadBalancing` permet de configurer l'[équilibrage de charge de la base de données](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#loadbalancing). La [connexion Redis](#redis-for-database-load-balancing) correspondante doit être activée pour que cette fonctionnalité fonctionne.

#### Gérer la base de données {#manage-the-database}

Consultez la page [Base de données de métadonnées du registre de conteneurs](metadata_database.md) pour plus d'informations sur la création et la maintenance de la base de données.

### Propriété `gc` {#gc-property}

La propriété `gc` fournit des options de [collecte des ordures en ligne](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#gc).

La collecte des ordures en ligne nécessite que la [base de données de métadonnées](#database) soit activée. Vous devez utiliser la collecte des ordures en ligne lorsque vous utilisez la base de données, bien que vous puissiez désactiver temporairement la collecte des ordures en ligne pour la maintenance et le débogage.

```yaml
gc:
  disabled: false
  maxbackoff: 24h
  noidlebackoff: false
  transactiontimeout: 10s
  reviewafter: 24h
  manifests:
    disabled: false
    interval: 5s
  blobs:
    disabled: false
    interval: 5s
    storagetimeout: 5s
```

### Cache Redis {#redis-cache}

> [!note]
> Le cache Redis est une fonctionnalité bêta à partir de la version 16.4. Veuillez consulter le [ticket de retour](https://gitlab.com/gitlab-org/gitlab/-/issues/423459) et la documentation associée avant d'activer cette fonctionnalité.

La propriété `redis.cache` est facultative et fournit des options relatives au [cache Redis](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#cache-1). Pour utiliser `redis.cache` avec le registre, la [base de données de métadonnées](#database) doit être activée.

Par exemple :

```yaml
redis:
  cache:
    enabled: true
    host: localhost
    port: 16379
    password:
      secret: gitlab-redis-secret
      key: redis-password
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
    tls:
      enabled: true
      insecure: true
    pool:
      size: 10
      maxlifetime: 1h
      idletimeout: 300s
```

#### Cluster {#cluster}

La propriété `redis.cache.cluster` est une liste d'hôtes et de ports permettant de se connecter à un cluster Redis. Par exemple :

```yaml
redis:
  cache:
    enabled: true
    host: redis.example.com
    cluster:
      - host: host1.example.com
        port: 6379
      - host: host2.example.com
        port: 6379
```

#### Sentinelles {#sentinels}

`redis.cache` peut utiliser la configuration `global.redis.sentinels`. Des valeurs locales peuvent être fournies et prendront la priorité sur les valeurs globales. Par exemple :

```yaml
redis:
  cache:
    enabled: true
    host: redis.example.com
    sentinels:
      - host: sentinel1.example.com
        port: 16379
      - host: sentinel2.example.com
        port: 16379
```

#### Prise en charge du mot de passe Sentinel {#sentinel-password-support}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3805) dans GitLab 17.2.

{{< /history >}}

`redis.cache` peut également utiliser la [configuration `global.redis.sentinelAuth`](../globals.md#redis-sentinel-password-support) pour utiliser un mot de passe d'authentification pour Redis Sentinel. Des valeurs locales peuvent être fournies et prendront la priorité sur les valeurs globales. Par exemple :

```yaml
redis:
  cache:
    enabled: true
    host: redis.example.com
    sentinels:
      - host: sentinel1.example.com
        port: 16379
      - host: sentinel2.example.com
        port: 16379
    sentinelpassword:
      enabled: true
      secret: registry-redis-sentinel
      key: password
```

### Limiteur de débit Redis {#redis-rate-limiter}

> [!warning]
> La limite de débit Redis est [en cours de développement](https://gitlab.com/groups/gitlab-org/-/epics/13237). Des détails supplémentaires sur les fonctionnalités seront ajoutés à cette section au fur et à mesure de leur disponibilité.

La propriété `redis.rateLimiting` est facultative et fournit des options relatives au [limiteur de débit Redis](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#ratelimiter).

Par exemple :

```yaml
redis:
  rateLimiting:
    enabled: true
    host: localhost
    port: 16379
    username: registry
    password:
      secret: gitlab-redis-secret
      key: redis-password
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
    tls:
      enabled: true
      insecure: true
    pool:
      size: 10
      maxlifetime: 1h
      idletimeout: 300s
```

### Redis pour l'équilibrage de charge de la base de données {#redis-for-database-load-balancing}

{{< details >}}

Statut :  Expérience

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4180) dans Charts 8.11.

{{< /history >}}

> [!warning]
> L'[équilibrage de charge de la base de données](#load-balancing) est une fonctionnalité expérimentale en cours de développement actif et ne doit pas être utilisée en production. Utilisez l'epic [8591](https://gitlab.com/groups/gitlab-org/-/epics/8591) pour suivre la progression et partager vos retours.

La propriété `redis.loadBalancing` est facultative et fournit des options relatives à la [connexion Redis pour l'équilibrage de charge de la base de données](https://gitlab.com/gitlab-org/container-registry/-/blob/b4d71f24a9ae31288401a3459228aa7f8d3dd8f0/docs/configuration.md#loadbalancing-1).

Par exemple :

```yaml
redis:
  loadBalancing:
    enabled: true
    host: localhost
    port: 16379
    username: registry
    password:
      secret: gitlab-redis-secret
      key: redis-password
    db: 0
    dialtimeout: 10ms
    readtimeout: 10ms
    writetimeout: 10ms
    tls:
      enabled: true
      insecure: true
    pool:
      size: 10
      maxlifetime: 1h
      idletimeout: 300s
```

## Collecte des ordures {#garbage-collection}

Le registre Docker accumulera des données superflues au fil du temps, qui pourront être libérées grâce à la [collecte des ordures](https://distribution.github.io/distribution/about/garbage-collection/). À ce [jour](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1586), il n'existe pas de méthode entièrement automatisée ou planifiée pour exécuter la collecte des ordures avec ce chart.

> [!warning]
> Vous devez utiliser la [collecte des ordures en ligne](https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md#gc) avec la [base de données de métadonnées](#database). L'utilisation de la collecte des ordures manuelle avec la base de données de métadonnées entraînera une perte de données. La collecte des ordures en ligne remplace entièrement la nécessité d'exécuter manuellement la collecte des ordures.

### Collecte des ordures manuelle {#manual-garbage-collection}

La collecte des ordures manuelle nécessite que le registre soit d'abord en mode lecture seule. Supposons que vous ayez déjà installé le chart GitLab en utilisant Helm, que vous l'ayez nommé `mygitlab` et installé dans le namespace `gitlabns`. Remplacez ces valeurs dans les commandes ci-dessous selon votre configuration réelle.

```shell
# Because of https://github.com/helm/helm/issues/2948 we can't rely on --reuse-values, so let's get our current config.
helm get values mygitlab > mygitlab.yml
# Upgrade Helm installation and configure the registry to be read-only.
# The --wait parameter makes Helm wait until all ressources are in ready state, so we are safe to continue.
helm upgrade mygitlab gitlab/gitlab -f mygitlab.yml --set registry.maintenance.readonly.enabled=true --wait
# Our registry is in r/o mode now, so let's get the name of one of the registry Pods.
# Note down the Pod name and replace the '<registry-pod>' placeholder below with that value.
# Replace the single quotes to double quotes (' => ") if you are using this with Windows' cmd.exe.
kubectl get pods -n gitlabns -l app=registry -o jsonpath='{.items[0].metadata.name}'
# Run the actual garbage collection. Check the registry's manual if you really want the '-m' parameter.
kubectl exec -n gitlabns <registry-pod> -- /bin/registry garbage-collect -m /etc/docker/registry/config.yml
# Reset registry back to original state.
helm upgrade mygitlab gitlab/gitlab -f mygitlab.yml --wait
# All done :)
```

### Exécution de commandes administratives sur le registre de conteneurs {#running-administrative-commands-against-the-container-registry}

Les commandes administratives ne peuvent être exécutées sur le registre de conteneurs que depuis un pod Registry, où le binaire `registry` ainsi que la configuration nécessaire sont disponibles. Le [ticket #2629](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2629) est ouvert pour discuter de la manière de fournir cette fonctionnalité depuis le pod toolbox.

Pour exécuter des commandes administratives :

1. Connectez-vous à un pod Registry :

   ```shell
   kubectl exec -it <registry-pod> -- bash
   ```

1. Une fois à l'intérieur du pod Registry, le binaire `registry` est disponible dans `PATH` et peut être utilisé directement. Le fichier de configuration est disponible à l'emplacement `/etc/docker/registry/config.yml`. L'exemple suivant vérifie le statut de la migration de la base de données :

   ```shell
   registry database migrate status /etc/docker/registry/config.yml
   ```

Pour plus de détails et d'autres commandes disponibles, consultez la documentation pertinente :

- [Documentation générale du registre](https://docs.docker.com/registry/)
- [Documentation du registre spécifique à GitLab](https://gitlab.com/gitlab-org/container-registry/-/tree/master/docs-gitlab)

## Configuration du limiteur de débit du registre {#registry-rate-limiter-configuration}

Le registre peut être configuré avec une limite de débit pour contrôler le trafic vers votre instance de registre de conteneurs. Cela permet de protéger votre registre contre les abus, les attaques DoS ou une utilisation excessive.

### Notes {#notes}

- La limite de débit nécessite que Redis soit correctement configuré via les paramètres `registry.redis.rateLimiting`.
- La limite de débit est désactivée par défaut. Définissez `registry.rateLimiter.enabled: true` pour l'activer.
- Les limiteurs sont appliqués par ordre de priorité (les valeurs les plus basses en premier).
- L'option `log_only` peut être utile pour tester les limites de débit avant de les appliquer.

### Configuration du limiteur de débit {#rate-limiter-configuration}

Pour activer et configurer la limite de débit pour le registre de conteneurs, vous pouvez utiliser les paramètres `registry.rateLimiter` :

```yaml
registry:
  rateLimiter:
    enabled: true
    limiters:
      - name: global_rate_limit
        description: "Global IP rate limit"
        log_only: false
        match:
          type: IP
        precedence: 10
        limit:
          rate: 5000
          period: "minute"
          burst: 8000
        action:
          warn_threshold: 0.7
          warn_action: "log"
          hard_action: "block"
```

### Configuration des limiteurs {#limiters-configuration}

Le limiteur de débit utilise une liste de limiteurs pour définir les règles de limitation de débit. Chaque limiteur possède les propriétés suivantes :

- `name` :  Un identifiant unique pour le limiteur
- `description` :  Une description lisible par l'humain de l'objectif du limiteur
- `log_only` :  Lorsque défini sur `true`, les violations sont uniquement enregistrées sans être appliquées
- `precedence` :  Définit l'ordre dans lequel les limiteurs sont évalués (les valeurs les plus basses en premier)
- `match` :  Critères de correspondance des requêtes
- `limit` :  Les paramètres de limite de débit
- `action` :  Actions à effectuer lorsque les limites sont atteintes

### Configuration des limites {#limit-configuration}

La section `limit` définit les paramètres réels de la limite de débit :

```yaml
limit:
  rate: 100       # Number of requests allowed
  period: "minute" # Time period (second, minute, hour, day)
  burst: 200      # Allowed burst capacity
```

### Configuration des actions {#action-configuration}

La section `action` définit ce qui se passe lorsque les limites sont approchées ou atteintes :

```yaml
action:
  warn_threshold: 0.7      # Percentage of limit to trigger warning
  warn_action: "log"       # Action when warning threshold is reached
  hard_action: "block"     # Action when limit is reached
```

### Exemples {#examples}

#### Limite de débit IP globale {#global-ip-rate-limit}

Cet exemple limite toutes les requêtes provenant d'une seule adresse IP :

```yaml
- name: global_rate_limit
  description: "Global IP rate limit"
  log_only: false
  match:
    type: IP
  precedence: 10
  limit:
    rate: 5000
    period: "minute"
    burst: 8000
  action:
    warn_threshold: 0.7
    warn_action: "log"
    hard_action: "block"
```
