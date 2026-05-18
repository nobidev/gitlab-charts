---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Toolbox
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le chart Toolbox est utilisé pour exécuter des tâches de maintenance périodiques au sein de l'application GitLab. Ces tâches comprennent les sauvegardes, la réindexation de la base de données, la maintenance Sidekiq et les tâches Rake.

## Configuration {#configuration}

Les paramètres de configuration suivants sont les paramètres par défaut fournis par le chart Toolbox :

```yaml
gitlab:
  ## doc/charts/gitlab/toolbox
  toolbox:
    enabled: true
    replicas: 1
    backups:
      cron:
        enabled: false
        concurrencyPolicy: Replace
        failedJobsHistoryLimit: 1
        schedule: "0 1 * * *"
        successfulJobsHistoryLimit: 3
        suspend: false
        backoffLimit: 6
        safeToEvict: false
        restartPolicy: "OnFailure"
        resources:
          requests:
            cpu: 50m
            memory: 350M
        persistence:
          enabled: false
          accessMode: ReadWriteOnce
          useGenericEphemeralVolume: false
          size: 10Gi
      objectStorage:
        backend: s3
        config: {}
      registry:
        database: {}
    databaseReindex:
      cron:
        enabled: false
        concurrencyPolicy: Replace
        failedJobsHistoryLimit: 1
        schedule: "12 * * * 0,6"
        successfulJobsHistoryLimit: 3
        suspend: false
        backoffLimit: 6
        safeToEvict: false
        restartPolicy: "OnFailure"
        resources:
          requests:
            cpu: 200m
            memory: 400M
    persistence:
      enabled: false
      accessMode: 'ReadWriteOnce'
      size: '10Gi'
    resources:
      requests:
        cpu: '50m'
        memory: '350M'
    securityContext:
      fsGroup: '1000'
      runAsUser: '1000'
      runAsGroup: '1000'
    containerSecurityContext:
      runAsUser: '1000'
    affinity: {}
```

| Paramètre                                                | Défaut                                                      | Description |
|----------------------------------------------------------|--------------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                         | [Règles d'affinité](../_index.md#affinity) pour l'assignation des pods |
| `annotations`                                            | `{}`                                                         | Annotations à ajouter aux pods et aux jobs Toolbox |
| `common.labels`                                          | `{}`                                                         | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `antiAffinityLabels.matchLabels`                         |                                                              | Labels pour définir les options d'anti-affinité |
| `backups.cron.activeDeadlineSeconds`                     | `null`                                                       | Secondes de délai actif du CronJob de sauvegarde (si null, aucun délai actif n'est appliqué) |
| `backups.cron.ttlSecondsAfterFinished`                   | `null`                                                       | Durée de vie du job du CronJob de sauvegarde après la fin (si null, aucune durée de vie n'est appliquée) |
| `backups.cron.safeToEvict`                               | `false`                                                      | Annotation safe-to-evict pour la mise à l'échelle automatique |
| `backups.cron.backoffLimit`                              | `6`                                                          | Limite de backoff du CronJob de sauvegarde |
| `backups.cron.concurrencyPolicy`                         | `Replace`                                                    | Politique de simultanéité des jobs Kubernetes |
| `backups.cron.enabled`                                   | `false`                                                      | Indicateur d'activation du CronJob de sauvegarde |
| `backups.cron.extraArgs`                                 |                                                              | Chaîne d'arguments à passer à l'utilitaire de sauvegarde |
| `backups.cron.failedJobsHistoryLimit`                    | `1`                                                          | Nombre de jobs de sauvegarde échoués listés dans l'historique |
| `backups.cron.persistence.accessMode`                    | `ReadWriteOnce`                                              | Mode d'accès à la persistance du cron de sauvegarde |
| `backups.cron.persistence.enabled`                       | `false`                                                      | Indicateur d'activation de la persistance du cron de sauvegarde |
| `backups.cron.persistence.matchExpressions`              |                                                              | Correspondances d'expressions de labels à lier |
| `backups.cron.persistence.matchLabels`                   |                                                              | Correspondances de valeurs de labels à lier |
| `backups.cron.persistence.useGenericEphemeralVolume`     | `false`                                                      | Utiliser un [volume éphémère générique](https://kubernetes.io/docs/concepts/storage/ephemeral-volumes/#generic-ephemeral-volumes) |
| `backups.cron.persistence.size`                          | `10Gi`                                                       | Taille du volume de persistance du cron de sauvegarde |
| `backups.cron.persistence.storageClass`                  |                                                              | Nom du StorageClass pour le provisionnement |
| `backups.cron.persistence.subPath`                       |                                                              | Chemin de montage du volume de persistance du cron de sauvegarde |
| `backups.cron.persistence.volumeName`                    |                                                              | Nom du volume persistant existant |
| `backups.cron.resources.requests.cpu`                    | `50m`                                                        | CPU minimum requis pour le cron de sauvegarde |
| `backups.cron.resources.requests.memory`                 | `350M`                                                       | Mémoire minimum requise pour le cron de sauvegarde |
| `backups.cron.restartPolicy`                             | `OnFailure`                                                  | Politique de redémarrage du cron de sauvegarde (`Never` ou `OnFailure`) |
| `backups.cron.schedule`                                  | `0 1 * * *`                                                  | Chaîne de planification au format cron |
| `backups.cron.startingDeadlineSeconds`                   | `null`                                                       | Délai de démarrage du job cron de sauvegarde, en secondes (si null, aucun délai de démarrage n'est appliqué) |
| `backups.cron.successfulJobsHistoryLimit`                | `3`                                                          | Nombre de jobs de sauvegarde réussis listés dans l'historique |
| `backups.cron.suspend`                                   | `false`                                                      | Le job cron de sauvegarde est suspendu |
| `backups.cron.timeZone`                                  | `""`                                                         | Fuseau horaire pour la planification des sauvegardes. Pour plus d'informations, consultez la [documentation Kubernetes](https://kubernetes.io/docs/concepts/workloads/controllers/cron-jobs/#time-zones). Utilise le fuseau horaire du cluster si non spécifié. |
| `backups.cron.tolerations`                               | `""`                                                         | Tolérances à ajouter au job cron de sauvegarde |
| `backups.cron.nodeSelector`                              | `""`                                                         | Sélection du nœud pour le job cron de sauvegarde |
| `backups.objectStorage.backend`                          | `s3`                                                         | Fournisseur de stockage d'objets à utiliser (`s3`, `gcs` ou `azure`) |
| `backups.objectStorage.config.gcpProject`                | `""`                                                         | Projet GCP à utiliser lorsque le backend est `gcs` |
| `backups.objectStorage.config.key`                       | `""`                                                         | Clé contenant les identifiants dans le secret |
| `backups.objectStorage.config.secret`                    | `""`                                                         | Secret des identifiants du stockage d'objets |
| `backups.registry.database.backupUser`                   |                                                              | Nom d'utilisateur pour la connexion à la base de données de métadonnées du registre lors des sauvegardes |
| `backups.registry.database.restoreUser`                  |                                                              | Nom d'utilisateur pour la connexion à la base de données de métadonnées du registre lors des restaurations |
| `backups.registry.database.password.secret`              | `RELEASE-toolbox-registry-database-password`                 | Nom du secret Kubernetes contenant le mot de passe de la base de données du registre pour la sauvegarde et la restauration |
| `backups.registry.database.password.backupPasswordKey`   | `backupPassword`                                             | Clé dans le secret contenant le mot de passe de la base de données de sauvegarde |
| `backups.registry.database.password.restorePasswordKey`  | `restorePassword`                                            | Clé dans le secret contenant le mot de passe de la base de données de restauration |
| `databaseReindex.cron.enabled`                           | `false`                                                      | Indique si le CronJob de réindexation de la base de données est activé |
| `common.labels`                                          | `{}`                                                         | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `deployment.strategy`                                    | `{ type: 'Recreate' }`                                       | Permet de configurer la stratégie de mise à jour utilisée par le déploiement |
| `enabled`                                                | `true`                                                       | Indicateur d'activation du Toolbox |
| `extra`                                                  | `{}`                                                         | Bloc YAML pour la [configuration `gitlab.yml` supplémentaire](https://gitlab.com/gitlab-org/gitlab/-/blob/8d2b59dbf232f17159d63f0359fa4793921896d5/config/gitlab.yml.example#L1193-1199) |
| `image.pullPolicy`                                       | `IfNotPresent`                                               | Politique de téléchargement de l'image Toolbox |
| `image.pullSecrets`                                      |                                                              | Secrets de téléchargement de l'image Toolbox |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee` | Dépôt de l'image Toolbox |
| `image.tag`                                              | `master`                                                     | Tag de l'image Toolbox |
| `init.image.repository`                                  |                                                              | Dépôt de l'image d'initialisation Toolbox |
| `init.image.tag`                                         |                                                              | Tag de l'image d'initialisation Toolbox |
| `init.resources`                                         | `{ requests: { cpu: '50m' }}`                                | Exigences en ressources du conteneur d'initialisation Toolbox |
| `init.containerSecurityContext`                          |                                                              | Spécifique à l'initContainer : [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | Spécifique à initContainer :  Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsUser`                | `1000`                                                       | Spécifique à initContainer :  ID utilisateur sous lequel le conteneur doit être démarré |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | Spécifique à initContainer :  Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                       | Spécifique à initContainer :  Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                  | Spécifique à initContainer :  Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur |
| `nodeSelector`                                           |                                                              | Sélection du nœud pour le Toolbox et les jobs de sauvegarde |
| `persistence.accessMode`                                 | `ReadWriteOnce`                                              | Mode d'accès à la persistance du Toolbox |
| `persistence.enabled`                                    | `false`                                                      | Indicateur d'activation de la persistance du Toolbox |
| `persistence.matchExpressions`                           |                                                              | Correspondances d'expressions de labels à lier |
| `persistence.matchLabels`                                |                                                              | Correspondances de valeurs de labels à lier |
| `persistence.size`                                       | `10Gi`                                                       | Taille du volume de persistance du Toolbox |
| `persistence.storageClass`                               |                                                              | Nom du StorageClass pour le provisionnement |
| `persistence.subPath`                                    |                                                              | Chemin de montage du volume de persistance du Toolbox |
| `persistence.volumeName`                                 |                                                              | Nom du PersistentVolume existant |
| `podLabels`                                              | `{}`                                                         | Labels pour l'exécution des pods Toolbox |
| `priorityClassName`                                      |                                                              | [Classe de priorité](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) attribuée aux pods. |
| `replicas`                                               | `1`                                                          | Nombre de pods Toolbox à exécuter |
| `resources.requests`                                     | `{ cpu: '50m', memory: '350M' }`                             | Ressources minimales demandées par le Toolbox |
| `securityContext.fsGroup`                                | `1000`                                                       | ID de groupe du système de fichiers sous lequel le pod doit être démarré |
| `securityContext.runAsUser`                              | `1000`                                                       | ID utilisateur sous lequel le pod doit être démarré |
| `securityContext.runAsGroup`                             | `1000`                                                       | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.fsGroupChangePolicy`                    |                                                              | Politique de modification de la propriété et des permissions du volume (nécessite Kubernetes 1.23) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                             | Profil Seccomp à utiliser |
| `containerSecurityContext`                               |                                                              | Remplace le [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel le conteneur est démarré |
| `containerSecurityContext.runAsUser`                     | `1000`                                                       | Permet de remplacer le contexte de sécurité spécifique sous lequel le conteneur est démarré |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                      | Contrôle si un processus du conteneur peut obtenir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                       | Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                  | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `serviceAccount.annotations`                             | `{}`                                                         | Annotations pour le ServiceAccount |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                      | Indique si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods |
| `serviceAccount.enabled`                                 | `false`                                                      | Indique si un ServiceAccount doit être utilisé |
| `serviceAccount.create`                                  | `false`                                                      | Indique si un ServiceAccount doit être créé |
| `serviceAccount.name`                                    |                                                              | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé |
| `tolerations`                                            |                                                              | Tolérances à ajouter au Toolbox |
| `extraEnvFrom`                                           |                                                              | Liste des variables d'environnement supplémentaires provenant d'autres sources de données à exposer |

## Configuration des sauvegardes {#configuring-backups}

Les informations relatives à la configuration des sauvegardes se trouvent dans la [documentation de sauvegarde et de restauration](../../../backup-restore/_index.md). Des informations supplémentaires sur l'implémentation technique des sauvegardes sont disponibles dans la [documentation de l'architecture de sauvegarde et de restauration](../../../architecture/backup-restore.md).]

### Identifiants de la base de données de métadonnées du registre {#registry-metadata-database-credentials}

Si vous utilisez la [base de données de métadonnées du registre de conteneurs](../../registry/metadata_database.md), vous pouvez configurer le Toolbox pour recevoir les détails de connexion à la base de données du registre pour les opérations de sauvegarde et de restauration. Les paramètres de connexion (hôte, port, nom de la base de données, paramètres SSL) sont automatiquement récupérés depuis le `ConfigMap` du chart du registre. Vous devez uniquement fournir les noms d'utilisateurs de la base de données et le secret de mot de passe dans les valeurs du Toolbox :

```yaml
gitlab:
  toolbox:
    backups:
      registry:
        database:
          backupUser: registry_backup
          restoreUser: registry_restore
          password:
            secret: gitlab-toolbox-registry-database-password
            backupPasswordKey: backupPassword
            restorePasswordKey: restorePassword
```

Le nom du secret par défaut est `RELEASE-toolbox-registry-database-password`, où `RELEASE` est remplacé par le nom de la release Helm (généralement `gitlab`). Créez le secret Kubernetes avant le déploiement :

```shell
kubectl create secret generic <RELEASE>-toolbox-registry-database-password \
  --from-literal=backupPassword=<backup_password> \
  --from-literal=restorePassword=<restore_password>
```

Les identifiants sont montés dans le pod Toolbox à l'emplacement `/etc/gitlab/registry-db/` et sont disponibles aussi bien dans le déploiement Toolbox de longue durée que dans le CronJob de sauvegarde.

#### Permissions requises pour la base de données {#required-database-permissions}

Les utilisateurs de sauvegarde et de restauration nécessitent différents niveaux de privilèges sur la base de données de métadonnées du registre. Lors de l'utilisation du PostgreSQL intégré avec le paquet Linux (Omnibus), ces utilisateurs et permissions sont créés automatiquement. Pour un PostgreSQL externe, créez les utilisateurs manuellement.

L'**backup user** nécessite un accès en lecture seule pour `pg_dump` :

```sql
-- Create the backup user
CREATE ROLE registry_backup WITH LOGIN PASSWORD '<backup_password>'
  NOINHERIT NOCREATEDB NOSUPERUSER NOREPLICATION;

-- The partitions schema must exist (created by registry migrations)
-- Grant connect and read-only privileges
GRANT CONNECT ON DATABASE registry TO registry_backup;

GRANT USAGE ON SCHEMA public TO registry_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO registry_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO registry_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE registry IN SCHEMA public
  GRANT SELECT ON TABLES TO registry_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE registry IN SCHEMA public
  GRANT SELECT ON SEQUENCES TO registry_backup;

GRANT USAGE ON SCHEMA partitions TO registry_backup;
GRANT SELECT ON ALL TABLES IN SCHEMA partitions TO registry_backup;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA partitions TO registry_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE registry IN SCHEMA partitions
  GRANT SELECT ON TABLES TO registry_backup;
ALTER DEFAULT PRIVILEGES FOR ROLE registry IN SCHEMA partitions
  GRANT SELECT ON SEQUENCES TO registry_backup;
```

Les instructions `ALTER DEFAULT PRIVILEGES` garantissent que l'utilisateur de sauvegarde reçoit automatiquement `SELECT` sur toutes les tables ou séquences que le propriétaire du registre (`registry`) crée à l'avenir.

L'**restore user** nécessite des privilèges superutilisateur pour recréer le schéma, définir le rôle sur le propriétaire d'objet d'origine et créer des déclencheurs :

```sql
CREATE ROLE registry_restore WITH LOGIN PASSWORD '<restore_password>'
  SUPERUSER;
```

## Configurer la réindexation périodique de la base de données {#configure-periodic-database-reindexing}

{{< details >}}

Statut :  Expérience

{{< /details >}}

La [réindexation de la base de données](https://docs.gitlab.com/omnibus/settings/database/#automatic-database-reindexing) peut être exécutée périodiquement pour :

- Créer et supprimer des index de manière asynchrone.
- Exécuter la validation des contraintes PostgreSQL en arrière-plan.
- Réindexer les index PostgreSQL pour réduire le [gonflement des index](https://wiki.postgresql.org/wiki/Index_Maintenance#Index_Bloat).

La réindexation est effectuée par la tâche Rake [`gitlab:db:reindex`](https://gitlab.com/gitlab-org/gitlab/blob/9a05e533daeb1013d4c974dd6b3ba066f68585ba/lib/tasks/gitlab/db.rake#L393-402). Le chart Toolbox fournit un CronJob pour exécuter la tâche Rake périodiquement.

Activez ce CronJob en définissant la valeur `databaseReindex.cron.enabled` sur `true`. Le job s'exécutera automatiquement :

1. Sélectionner les deux index présentant le plus de [gonflement des index](https://wiki.postgresql.org/wiki/Index_Maintenance#Index_Bloat).
1. Réindexer ces index en arrière-plan.

Définissez la planification du CronJob en utilisant la valeur `databaseReindex.cron.schedule`. Vous devez exécuter la réindexation pendant les périodes de faible trafic. Par exemple, la réindexation de la base de données s'exécute pour GitLab.com le samedi et le dimanche.

> [!note]
> Si vous êtes administrateur d'une instance du paquet Linux, vous pouvez activer la réindexation périodique de la base de données en [suivant les instructions correspondantes](https://docs.gitlab.com/omnibus/settings/database/#automatic-database-reindexing).

## Configuration de la persistance {#persistence-configuration}

Les stockages persistants pour les sauvegardes et les restaurations sont configurés séparément. Veuillez examiner les considérations suivantes lors de la configuration de GitLab pour les opérations de sauvegarde et de restauration.

Les sauvegardes utilisent les propriétés `backups.cron.persistence.*` et les restaurations utilisent les propriétés `persistence.*`. Les descriptions supplémentaires concernant la configuration d'un stockage de persistance utiliseront uniquement la clé de propriété finale (par ex. `.enabled` ou `.size`) et le préfixe approprié devra être ajouté.

Les stockages de persistance sont désactivés par défaut ; ainsi, `.enabled` doit être défini sur `true` pour une sauvegarde ou une restauration de toute taille appréciable. De plus, soit `.storageClass` doit être spécifié pour qu'un PersistentVolume soit créé par Kubernetes, soit un PersistentVolume doit être créé manuellement. Si `.storageClass` est spécifié comme `-`, le PersistentVolume sera créé en utilisant le [StorageClass par défaut](https://kubernetes.io/docs/tasks/administer-cluster/change-default-storage-class/) tel que spécifié dans le cluster Kubernetes.

Si le PersistentVolume est créé manuellement, le volume peut être spécifié en utilisant la propriété `.volumeName` ou en utilisant les propriétés du sélecteur `.matchLables` / `.matchExpressions`.

Dans la plupart des cas, la valeur par défaut de `.accessMode` fournira des contrôles adéquats pour que seul le Toolbox accède aux PersistentVolumes. Veuillez consulter la documentation du pilote CSI installé dans le cluster Kubernetes pour vous assurer que le paramètre est correct.

### Considérations relatives aux sauvegardes {#backup-considerations}

Une opération de sauvegarde nécessite un espace disque pour stocker les composants individuels en cours de sauvegarde avant qu'ils ne soient écrits dans le stockage d'objets de sauvegarde. La quantité d'espace disque dépend des facteurs suivants :

- Nombre de projets et quantité de données stockées sous chaque projet
- Taille de la base de données PostgresSQL (tickets, MRs, etc.)
- Taille de chaque backend de stockage d'objets

Une fois la taille approximative déterminée, la propriété `backups.cron.persistence.size` peut être définie pour que les sauvegardes puissent commencer.

### Considérations relatives aux restaurations {#restore-considerations}

Lors de la restauration d'une sauvegarde, la sauvegarde doit être extraite sur le disque avant que les fichiers ne soient remplacés sur l'instance en cours d'exécution. La taille de cet espace disque de restauration est contrôlée par la propriété `persistence.size`. Gardez à l'esprit qu'à mesure que la taille de l'installation GitLab augmente, la taille de l'espace disque de restauration doit également augmenter en conséquence. Dans la plupart des cas, la taille de l'espace disque de restauration doit être identique à celle de l'espace disque de sauvegarde.

## Outils inclus dans le Toolbox {#toolbox-included-tools}

Le conteneur Toolbox contient des outils GitLab utiles tels que la console Rails, les tâches Rake, etc. Ces commandes permettent de vérifier l'état des migrations de la base de données, d'exécuter des tâches Rake pour les tâches administratives et d'interagir avec la console Rails :

```shell
# locate the Toolbox pod
kubectl get pods -lapp=toolbox

# Launch a shell inside the pod
kubectl exec -it <Toolbox pod name> -- bash

# open Rails console
gitlab-rails console -e production

# execute a Rake task
gitlab-rake gitlab:env:info
```

### `affinity` {#affinity}

Pour plus d'informations, consultez [`affinity`](../_index.md#affinity).
