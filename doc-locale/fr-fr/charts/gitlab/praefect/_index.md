---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du chart Praefect
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed
- Statut :  Expérience

{{< /details >}}

> [!warning] Le chart Praefect est encore en cours de développement. Cette version expérimentale n'est pas encore adaptée à un usage en production. Les mises à niveau peuvent nécessiter une intervention manuelle importante. Consultez notre [Epic de release GA Praefect](https://gitlab.com/groups/gitlab-org/charts/-/epics/33) pour plus d'informations.

Le chart Praefect est utilisé pour gérer le [Gitaly Cluster (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/) au sein d'une installation GitLab déployée avec les charts Helm.

## Problèmes connus {#known-issues}

1. La base de données doit être [créée manuellement](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2310).
1. La taille du cluster est fixe :  [Gitaly Cluster (Praefect) ne prend pas en charge la mise à l'échelle automatique](https://gitlab.com/gitlab-org/gitaly/-/issues/2997).
1. L'utilisation d'une instance Praefect dans le cluster pour gérer des instances Gitaly en dehors du cluster n'est [pas prise en charge](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2662).

## Prérequis {#requirements}

Ce chart utilise le chart Gitaly. Les paramètres de `global.gitaly` sont utilisés pour configurer les instances créées par ce chart. La documentation de ces paramètres est disponible dans la [documentation du chart Gitaly](../gitaly/_index.md).

_Important_ : `global.gitaly.tls` est indépendant de `global.praefect.tls`. Ils sont configurés séparément.

Par défaut, ce chart crée 3 réplicas Gitaly.

## Configuration {#configuration}

Le chart est désactivé par défaut. Pour l'activer dans le cadre d'un déploiement de chart, définissez `global.praefect.enabled=true`.

### Réplicas {#replicas}

Le nombre par défaut de réplicas à déployer est 3. Cette valeur peut être modifiée en définissant `global.praefect.virtualStorages[].gitalyReplicas` avec le nombre de réplicas souhaité. Par exemple :

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
```

### Stockages virtuels multiples {#multiple-virtual-storages}

Il est possible de configurer plusieurs stockages virtuels (voir la documentation de [Gitaly Cluster (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/)). Par exemple :

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
```

Cela créera deux ensembles de ressources pour Gitaly. Cela inclut deux StatefulSets Gitaly (un par stockage virtuel).

Les administrateurs peuvent ensuite [configurer l'emplacement de stockage des nouveaux dépôts](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored).

### Persistance {#persistence}

Il est possible de fournir une configuration de persistance par stockage virtuel.

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
      persistence:
        enabled: true
        size: 50Gi
        accessMode: ReadWriteOnce
        storageClass: storageclass1
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
      persistence:
        enabled: true
        size: 100Gi
        accessMode: ReadWriteOnce
        storageClass: storageclass2
```

## defaultReplicationFactor {#defaultreplicationfactor}

`defaultReplicationFactor` peut être configuré sur chaque stockage virtuel. (voir la documentation [configure replication-factor](https://docs.gitlab.com/administration/gitaly/praefect/#configure-replication-factor)).

```yaml
global:
  praefect:
    enabled: true
    virtualStorages:
    - name: default
      gitalyReplicas: 5
      maxUnavailable: 2
      defaultReplicationFactor: 3
    - name: secondary
      gitalyReplicas: 4
      maxUnavailable: 1
      defaultReplicationFactor: 2
```

### Migration vers Praefect {#migrating-to-praefect}

> [!note] Les wikis de groupe [ne peuvent pas être déplacés via l'API](https://docs.gitlab.com/api/project_repository_storage_moves/).

Lors de la migration d'instances Gitaly autonomes vers une configuration Praefect, `global.praefect.replaceInternalGitaly` peut être défini sur `false`. Cela garantit que les instances Gitaly existantes sont préservées pendant la création des nouvelles instances Gitaly gérées par Praefect.

```yaml
global:
  praefect:
    enabled: true
    replaceInternalGitaly: false
    virtualStorages:
    - name: virtualStorage2
      gitalyReplicas: 5
      maxUnavailable: 2
```

> [!note] Lors de la migration vers Praefect, aucun stockage virtuel de Praefect ne peut être nommé `default`. Cela est dû au fait qu'il doit exister en permanence au moins un stockage nommé `default`, et ce nom est donc déjà utilisé par la configuration non-Praefect.

Les instructions pour [migrer vers Gitaly Cluster (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/#migrate-to-gitaly-cluster-praefect) peuvent ensuite être suivies pour déplacer les données du stockage `default` vers `virtualStorage2`. Si des stockages supplémentaires ont été définis sous `global.gitaly.internal.names`, veillez à migrer également les dépôts de ces stockages.

Une fois les dépôts migrés vers `virtualStorage2`, `replaceInternalGitaly` peut être redéfini sur `true` si un stockage nommé `default` est ajouté dans la configuration Praefect.

```yaml
global:
  praefect:
    enabled: true
    replaceInternalGitaly: true
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
    - name: virtualStorage2
      gitalyReplicas: 5
      maxUnavailable: 2
```

Les instructions pour [migrer vers Gitaly Cluster (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/#migrate-to-gitaly-cluster-praefect) peuvent à nouveau être suivies pour déplacer les données de `virtualStorage2` vers le stockage `default` nouvellement ajouté, si souhaité.

Enfin, consultez la [documentation sur les chemins de stockage des dépôts](https://docs.gitlab.com/administration/repository_storage_paths/#choose-where-new-repositories-are-stored) pour configurer l'emplacement de stockage des nouveaux dépôts.

### Création de la base de données {#creating-the-database}

Praefect utilise sa propre base de données pour suivre son état. Celle-ci doit être créée manuellement pour que Praefect soit fonctionnel.

1. Connectez-vous à votre instance de base de données. La commande de connexion exacte peut varier selon votre configuration.

   ```shell
   psql -U postgres -d template1
   ```

1. Créez l'utilisateur de la base de données :

   ```sql
   CREATE ROLE praefect WITH LOGIN;
   ```

1. Définissez le mot de passe de l'utilisateur de la base de données.

   Par défaut, le job `shared-secrets` génère un secret pour vous.

   1. Récupérez le mot de passe :

      ```shell
      kubectl get secret RELEASE_NAME-praefect-dbsecret -o jsonpath="{.data.secret}" | base64 --decode
      ```

   1. Définissez le mot de passe dans l'invite `psql` :

      ```sql
      \password praefect
      ```

1. Créez la base de données :

   ```sql
   CREATE DATABASE praefect WITH OWNER praefect;
   ```

### Exécution de Praefect via TLS {#running-praefect-over-tls}

Praefect prend en charge la communication avec les clients et les nœuds Gitaly via TLS. Cela est contrôlé par les paramètres `global.praefect.tls.enabled` et `global.praefect.tls.secretName`. Pour exécuter Praefect via TLS, suivez ces étapes :

1. Le chart Helm attend qu'un certificat soit fourni pour la communication via TLS avec Praefect. Ce certificat doit s'appliquer à tous les nœuds Praefect présents. Par conséquent, tous les noms d'hôte de chacun de ces nœuds doivent être ajoutés en tant que Subject Alternate Name (SAN) au certificat, ou bien vous pouvez utiliser des caractères génériques.

   Pour connaître les noms d'hôte à utiliser, vérifiez le fichier `/srv/gitlab/config/gitlab.yml` dans le Toolbox Pod et consultez les différents champs `gitaly_address` spécifiés sous la clé `repositories.storages` dans ce fichier.

   ```shell
   kubectl exec -it <Toolbox Pod> -- grep gitaly_address /srv/gitlab/config/gitlab.yml
   ```

Un script de base pour générer des certificats signés personnalisés pour les Pods Praefect internes [est disponible dans ce dépôt](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/generate_certificates.sh). Les utilisateurs peuvent utiliser ce script ou s'y référer pour générer des certificats avec les attributs SAN appropriés.

1. Créez un Secret TLS en utilisant le certificat créé.

   ```shell
   kubectl create secret tls <secret name> --cert=praefect.crt --key=praefect.key
   ```

1. Redéployez le chart Helm en passant `--set global.praefect.tls.enabled=true`.

Lors de l'exécution de Gitaly via TLS, un nom de secret doit être fourni pour chaque stockage virtuel.

```yaml
global:
  gitaly:
    tls:
      enabled: true
  praefect:
    enabled: true
    tls:
      enabled: true
      secretName: praefect-tls
    virtualStorages:
    - name: default
      gitalyReplicas: 4
      maxUnavailable: 1
      tlsSecretName: default-tls
    - name: vs2
      gitalyReplicas: 5
      maxUnavailable: 2
      tlsSecretName: vs2-tls
```

### Options de ligne de commande d'installation {#installation-command-line-options}

Le tableau ci-dessous contient toutes les configurations de charts possibles qui peuvent être fournies à la commande `helm install` via les flags `--set`.

| Paramètre                                                | Défaut                                           | Description |
|----------------------------------------------------------|---------------------------------------------------|-------------|
| common.labels                                            | `{}`                                              | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| failover.enabled                                         | true                                              | Indique si Praefect doit effectuer un basculement en cas de défaillance d'un nœud |
| failover.readonlyAfter                                   | false                                             | Indique si les nœuds doivent être en mode lecture seule après un basculement |
| autoMigrate                                              | true                                              | Exécuter automatiquement les migrations au démarrage |
| image.repository                                         | `registry.gitlab.com/gitlab-org/build/cng/gitaly` | Le dépôt d'images par défaut à utiliser. Praefect est intégré dans l'image Gitaly |
| podLabels                                                | `{}`                                              | Labels de Pod supplémentaires. Ne sera pas utilisé pour les sélecteurs. |
| ntpHost                                                  | `pool.ntp.org`                                    | Configurer le serveur NTP que Praefect doit interroger pour obtenir l'heure actuelle. |
| service.name                                             | `praefect`                                        | Le nom du service à créer |
| service.type                                             | ClusterIP                                         | Le type de service à créer |
| service.internalPort                                     | 8075                                              | Le numéro de port interne sur lequel le pod Praefect sera en écoute |
| service.externalPort                                     | 8075                                              | Le numéro de port que le service Praefect doit exposer dans le cluster |
| init.resources                                           |                                                   |             |
| init.image                                               |                                                   |             |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                           | Spécifique à initContainer :  Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                            | Spécifique à initContainer :  Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                       | Spécifique à initContainer :  Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur |
| extraEnvFrom                                             |                                                   | Liste des variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| logging.level                                            |                                                   | Niveau de log   |
| logging.format                                           | `json`                                            | Format de log  |
| logging.sentryDsn                                        |                                                   | URL DSN Sentry - Exceptions du serveur Go |
| logging.sentryEnvironment                                |                                                   | Environnement Sentry à utiliser pour la journalisation |
| `metrics.enabled`                                        | `true`                                            | Indique si un endpoint de métriques doit être disponible pour le scraping |
| `metrics.port`                                           | `9236`                                            | Port de l'endpoint de métriques |
| `metrics.separate_database_metrics`                      | `true`                                            | Si la valeur est true, les scrapings de métriques n'effectueront pas de requêtes sur la base de données ; définir la valeur sur false [peut entraîner des problèmes de performance](https://gitlab.com/gitlab-org/gitaly/-/issues/3796) |
| `metrics.path`                                           | `/metrics`                                        | Chemin de l'endpoint de métriques |
| `metrics.serviceMonitor.enabled`                         | `false`                                           | Indique si un ServiceMonitor doit être créé pour permettre à l'opérateur Prometheus de gérer le scraping des métriques ; notez que l'activation de cette option supprime les annotations de scraping `prometheus.io` |
| `affinity`                                               | `{}`                                              | [Règles d'affinité](../_index.md#affinity) pour l'assignation des pods |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                              | Labels supplémentaires à ajouter au ServiceMonitor |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                              | Configuration d'endpoint supplémentaire pour le ServiceMonitor |
| securityContext.runAsUser                                | 1000                                              |             |
| securityContext.fsGroup                                  | 1000                                              |             |
| securityContext.fsGroupChangePolicy                      |                                                   | Politique de modification de la propriété et des permissions du volume (nécessite Kubernetes 1.23) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                  | Profil Seccomp à utiliser |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                           | Contrôle si un processus du conteneur peut obtenir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                            | Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                       | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `serviceAccount.annotations`                             | `{}`                                              | Annotations ServiceAccount |
| `serviceAccount.automountServiceAccountToken`            | `false`                                           | Indique si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods |
| `serviceAccount.create`                                  | `false`                                           | Indique si un ServiceAccount doit être créé |
| `serviceAccount.enabled`                                 | `false`                                           | Indique si un ServiceAccount doit être utilisé |
| `serviceAccount.name`                                    |                                                   | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé |
| serviceLabels                                            | `{}`                                              | Labels de service supplémentaires |
| statefulset.strategy                                     | `{}`                                              | Permet de configurer la stratégie de mise à jour utilisée par le statefulset |

### serviceAccount {#serviceaccount}

Cette section contrôle si un ServiceAccount doit être créé et si le jeton d'accès par défaut doit être monté dans les pods.

| Nom                           |  Type   | Défaut | Description |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   Map   | `{}`    | Annotations ServiceAccount. |
| `automountServiceAccountToken` | Boolean | `false` | Contrôle si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods. Vous ne devez pas activer cette option, sauf si elle est requise par certains sidecars pour fonctionner correctement (par exemple, Istio). |
| `create`                       | Boolean | `false` | Indique si un ServiceAccount doit être créé. |
| `enabled`                      | Boolean | `false` | Indique si un ServiceAccount doit être utilisé. |
| `name`                         | String  |         | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé. |

### affinity {#affinity}

Pour plus d'informations, consultez [`affinity`](../_index.md#affinity).
