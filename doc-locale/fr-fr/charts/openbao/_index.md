---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Chart OpenBao
---

{{< details >}}

- Niveau :  Ultimate
- Offre :  GitLab.com, GitLab Self-Managed
- Statut :  Expérience

{{< /details >}}

{{< history >}}

- Introduit en tant qu'[expérimentation](https://docs.gitlab.com/policy/development_stages_support/#experiment) dans GitLab 18.3 [avec des feature flags](https://docs.gitlab.com/administration/feature_flags/) nommés `ci_tanukey_ui` et `secrets_manager`. Désactivé par défaut.
- [Flag](https://docs.gitlab.com/administration/feature_flags/) `ci_tanukey_ui` a été fusionné dans `secrets_manager` dans GitLab 18.4.
- Rendu disponible pour certains utilisateurs en bêta fermée dans GitLab 18.8.

{{< /history >}}

> [!flag]
> La disponibilité de cette fonctionnalité est contrôlée par un feature flag. Pour plus d'informations, consultez l'historique.

Vous pouvez utiliser le [chart OpenBao](https://gitlab.com/gitlab-org/cloud-native/charts/openbao) pour installer OpenBao, qui est requis pour activer le [gestionnaire de secrets GitLab](https://docs.gitlab.com/ci/secrets/secrets_manager/).

## Problèmes connus {#known-issues}

- Vous ne pouvez pas mettre à niveau OpenBao sans interruption de service. Les mises à niveau sans interruption de service sont proposées dans le [ticket 13 du chart OpenBao](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/issues/13).
- Vous ne pouvez pas déployer OpenBao avec [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator).
- Une variante FIPS de l'image OpenBao est en cours de construction, mais OpenBao n'est pas validé FIPS. La validation FIPS est suivie dans le [ticket GitLab 574875](https://gitlab.com/gitlab-org/gitlab/-/issues/574875).

## Configurer le gestionnaire de secrets GitLab et OpenBao {#setup-gitlab-secret-manager-and-openbao}

1. Sur une instance GitLab existante, activez OpenBao :

   ```yaml
   # Enable OpenBao integration
   global:
     openbao:
       enabled: true
   # Install bundled OpenBao
   openbao:
     install: true
   ```

1. Dans GitLab, dans la barre supérieure, sélectionnez **Rechercher ou aller à** et trouvez votre projet.
1. Sélectionnez **Paramètres > Général**.
1. Développez **Visibilité, fonctionnalités du projet, autorisations**.
1. Activez le bouton bascule **Secrets Manager** et attendez que le gestionnaire de secrets soit provisionné.

## Configuration Geo {#geo-configuration}

{{< history >}}

- `jwt_audience` a été [introduit](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4837) dans GitLab 18.10.

{{< /history >}}

Dans les déploiements [GitLab Geo](https://docs.gitlab.com/ee/administration/geo/), les sites secondaires peuvent utiliser des URL différentes pour atteindre OpenBao par rapport au site principal. La revendication d'audience JWT dans l'authentification GitLab OpenBao doit correspondre à `bound_audiences` configuré dans OpenBao. Lorsque chaque site possède une URL OpenBao différente, définissez `jwt_audience` sur la valeur partagée (généralement l'URL OpenBao du site principal) afin que les JWT soient acceptés par OpenBao quel que soit le site qui les a générés.

Configurez le site secondaire :

```yaml
global:
  openbao:
    enabled: true
    # Site-specific URL for this Geo secondary
    url: https://openbao.secondary.example.com:8200
    # Shared audience - must match OpenBao bound_audiences (e.g. primary site URL)
    jwt_audience: https://openbao.shared.example.com:8200
```

Assurez-vous qu'OpenBao `config.initialize.boundAudiences` inclut la valeur `jwt_audience`. Lors de l'utilisation du chart OpenBao intégré, `boundAudiences` utilise par défaut le nom d'hôte OpenBao externe ; pour Geo, vous devrez peut-être le remplacer pour inclure l'URL partagée utilisée comme `jwt_audience`.

Dans les scénarios de basculement, lorsqu'un site secondaire est promu en site principal, omettez `jwt_audience` de la configuration. Le site principal promu utilise sa propre URL, et l'audience utilise par défaut cette URL.

## Restauration des mises à niveau d'OpenBao {#rolling-back-openbao-upgrades}

Les mises à niveau d'OpenBao peuvent apporter des modifications aux données PostgreSQL qui ne sont pas rétrocompatibles, ce qui peut entraîner des problèmes de compatibilité si la mise à niveau d'OpenBao doit être annulée.

Vous devriez toujours [effectuer une sauvegarde](#back-up-openbao) avant de mettre à niveau OpenBao. Si vous devez annuler une mise à niveau d'OpenBao, restaurez également la sauvegarde de la base de données correspondant à la version d'OpenBao.

Pour plus d'informations, consultez la [documentation de mise à niveau d'OpenBao](https://openbao.org/docs/upgrading/).

## Sauvegarder OpenBao {#back-up-openbao}

Pour sauvegarder complètement OpenBao, vous avez besoin des éléments suivants :

- Clés de déscellement. Ces clés sont essentielles pour accéder à vos données OpenBao après la restauration. Suivez les [procédures de sauvegarde des secrets](../../backup-restore/backup.md#back-up-the-secrets) pour les secrets OpenBao.
- La base de données PostgreSQL.

Par défaut, les données PostgreSQL d'OpenBao sont sauvegardées dans le cadre de la procédure de sauvegarde intégrée du chart.

Si vous avez configuré OpenBao pour utiliser une base de données différente (logique ou physique), cette base de données doit être sauvegardée manuellement. L'outil de sauvegarde par défaut ne couvre que la configuration PostgreSQL standard, car il n'a pas connaissance des autres bases de données externes. Pour éviter tout problème de synchronisation, les bases de données GitLab et OpenBao doivent être sauvegardées en même temps.

## Restaurer OpenBao {#restore-openbao}

Par défaut, les données PostgreSQL d'OpenBao sont restaurées dans le cadre de la procédure de restauration intégrée du chart.

Si vous avez configuré OpenBao pour utiliser une base de données différente (logique ou physique), la sauvegarde de la base de données OpenBao ne peut pas être restaurée par l'utilitaire de sauvegarde intégré et doit être restaurée manuellement.

Avant de restaurer une sauvegarde OpenBao, assurez-vous qu'OpenBao est mis à l'échelle vers le bas, car il tentera de recréer son schéma de base de données, ce qui peut entraîner des erreurs inattendues. Pour mettre à l'échelle OpenBao vers le bas, exécutez :

```shell
kubectl scale deploy -lapp=openbao,release=<helm release name> -n <namespace> --replicas=0
```

## Options de configuration d'OpenBao {#openbao-configuration-options}

Les tableaux suivants répertorient toutes les options de configuration OpenBao disponibles.

### Options de ligne de commande pour l'installation {#installation-command-line-options}

Le tableau ci-dessous contient toutes les configurations de charts possibles qui peuvent être fournies à la commande `helm install` via les flags `--set`.

| Paramètre                                                | Défaut                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `logLevel`                                               | info                                                    | Niveau de journalisation d'OpenBao. |
| `logRequestLevel`                                        | off                                                     | Niveau de journalisation des requêtes OpenBao. Pour activer la journalisation des requêtes, définissez ce paramètre sur la même valeur que `logLevel` ou sur un niveau supérieur. |
| `logFormat`                                              | `json`                                                  | Format de journalisation d'OpenBao. `json` ou `standard`. |
| `serviceAccount.create`                                  | true                                                    | Créer un compte de service pour OpenBao. |
| `serviceAccount.automount`                               | true                                                    | |
| `serviceAccount.annotations`                             | `{}`                                                    | Annotations supplémentaires du compte de service. |
| `serviceAccount.name`                                    |                                                         | Remplacer le nom de compte de service généré. |
| `role.create`                                            |                                                         | Créer un rôle avec les autorisations RBAC nécessaires. |
| `securityContext.capabilities`                           | `{ drop: ["ALL"] }`                                     | |
| `securityContext.runAsNonRoot`                           | true                                                    | |
| `securityContext.allowPrivilegeEscalation`               | false                                                   | |
| `securityContext.runAsUser`                              | 65532                                                   | |
| `podSecurityContext.seccompProfile`                      | `RuntimeDefault`                                        | |
| `podSecurityContext.runAsUser`                           | 65532                                                   | |
| `podSecurityContext.fsGroup`                             | 65532                                                   | |
| `serviceActive.type`                                     | ClusterIP                                               | Type de service du pod OpenBao actif. |
| `serviceActive.annotations`                              | `{}`                                                    | Annotations de service du pod OpenBao actif. |
| `serviceInactive.type`                                   | ClusterIP                                               | Type de service des pods OpenBao en veille. |
| `serviceInactive.annotations`                            | `{}`                                                    | Annotations de service des pods OpenBao en veille. |
| `resources`                                              | `{}`                                                    | Limites et demandes de ressources. |
| `autoscaling.minReplicas`                                | 2                                                       | Nombre minimal de réplicas OpenBao. |
| `autoscaling.maxReplicas`                                | 2                                                       | Nombre maximal de réplicas OpenBao. |
| `autoscaling.targetCPUUtilizationPercentage`             | 80                                                      | Utilisation cible du CPU pour la mise à l'échelle automatique. |
| `autoscaling.targetCPUMemoryPercentage`                  |                                                         | Utilisation cible de la mémoire pour la mise à l'échelle automatique. |
| `livenessProbe`                                          |                                                         | Sonde de vivacité d'OpenBao. Consultez les [valeurs OpenBao](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) pour la valeur par défaut. |
| `readinessProbe`                                         |                                                         | Sonde de disponibilité d'OpenBao. Consultez les [valeurs OpenBao](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) pour la valeur par défaut. |
| `nodeSelector`                                           | {}                                                      | Labels de sélection de nœud. |
| `tolerations`                                            | []                                                      | Labels de tolérance pour l'affectation des pods. |
| `affinity`                                               | {}                                                      | Labels d'affinité pour l'affectation des pods. |
| `config.ui`                                              | false                                                   | Activer l'interface utilisateur OpenBao. |
| `config.clusterPort`                                     | 8201                                                    | Port du cluster OpenBao. |
| `config.apiPort`                                         | 8200                                                    | Port API d'OpenBao. |
| `config.cacheSize`                                       | 8200                                                    | Taille du cache de lecture utilisé par le sous-système de stockage physique, exprimée en nombre d'entrées. |
| `config.maxRequestSize`                                  | 786432                                                  | Taille maximale des requêtes en octets. La valeur par défaut est 768 Ko. |
| `config.maxRequestJsonMemory`                            | 1048576                                                 | Taille maximale du corps de requête analysé en JSON, en octets. La valeur par défaut est 1 Mo. |

### Options d'image de conteneur {#container-image-options}

Le chart OpenBao déploie une [image de conteneur GitLab cloud-native](https://gitlab.com/gitlab-org/build/CNG) pour déployer OpenBao. La version d'OpenBao inclut des [modifications](https://gitlab.com/gitlab-org/govern/secrets-management/openbao-internal) par rapport à la version amont. En conséquence, certaines fonctionnalités peuvent différer des releases standard d'OpenBao.

| Paramètre                                                | Défaut                                                   | Description |
|----------------------------------------------------------|-----------------------------------------------------------|-------------|
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-openbao` | Dépôt de l'image OpenBao. |
| `image.pullPolicy`                                       | `IfNotPresent`                                            | Politique de récupération d'image. |
| `image.tag`                                              |                                                           | Remplacez cette valeur pour déployer une version personnalisée d'OpenBao. |
| `imagePullSecrets`                                       | `[]`                                                      | Secrets pour récupérer des images depuis des dépôts privés. |

### Options de configuration Ingress et TLS {#ingress-and-tls-configuration-options}

Le chart OpenBao utilise par défaut le chiffrement TLS terminé par Ingress.

| Paramètre                                                | Défaut                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `global.openbao.host`                                    | `openbao.<GitLab Domain>`                                 | Hôte OpenBao. Utilisé pour configurer le webservice GitLab et le chart OpenBao. |
| `global.openbao.url`                                     | Dérivé de l'hôte                                       | URL OpenBao pour GitLab. Si présente, doit être un URI complet. |
| `global.openbao.jwt_audience`                            | Identique à `url`                                           | Revendication d'audience JWT pour l'authentification OpenBao. À définir pour les [déploiements Geo](#geo-configuration) lorsque les sites utilisent des URL différentes. Doit correspondre à OpenBao `bound_audiences`. |
| `global.openbao.psql`                                    | `{}`                                                    | Configuration de la base de données OpenBao (hôte, base de données, nom d'utilisateur, mot de passe). |
| `ingress.enabled`                                        | true                                                    | Activer l'Ingress OpenBao pour permettre au runner d'atteindre OpenBao. |
| `ingress.hostname`                                       | Hôte OpenBao externe basé sur la configuration globale des hôtes.     | Nom d'hôte que l'Ingress doit faire correspondre. |
| `ingress.tls.enabled`                                    | true                                                    | Activer le TLS Ingress. |
| `ingress.tls.secretName`                                 |                                                         | Nom du [secret TLS Kubernetes](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls). Géré par certmanager par défaut. |
| `ingress.annotations`                                    | true                                                    | Annotations rendues dans l'Ingress. Utilisez ceci pour configurer OpenBao pour les contrôleurs Ingress non-NGINX. |
| `ingress.configureCertmanager`                           | Configuration globale de certmanager                               | Utiliser certmanager pour gérer le certificat TLS. |
| `ingress.certmanagerIssuer`                              | `<release>-issuer`                                       | Nom de l'émetteur certmanager. |
| `ingress.sslPassthroughNginx`                            | false                                                   | Annoter l'Ingress pour transmettre les connexions TLS entrantes à OpenBao. Si certmanager est configuré, les nouveaux défis HTTP01 seront transmis via un autre Ingress. |
| `config.tlsDisable`                                      | true                                                    | Désactiver le TLS interne. Si désactivé, le passage TLS de l'Ingress est également désactivé. |
| `config.metricsListener.tlsDisable`                      | true                                                    | Désactiver le TLS interne de l'écouteur de métriques. |

Vous devriez exploiter OpenBao avec un TLS chiffré de bout en bout. Pour activer le TLS de bout en bout, configurez OpenBao pour qu'il attende une connexion TLS et transmettez la connexion TLS via NGINX Ingress :

```yaml
global:
  ingress:
    useNewIngressForCerts: true
config:
  tlsDisable: false
ingress:
  sslPassthroughNginx: true
```

> [!note]
> L'activation du passage SSL nécessite que cert-manager crée un autre Ingress pour compléter les défis HTTP01. Si vous utilisez certmanager intégré et `Issuer`, assurez-vous que l'émetteur définit le bon `IngressClass` en configurant [`global.ingress.useNewIngressForCerts`](../globals.md#globalingressusenewingressforcerts).

### Gateway API {#gateway-api}

Le chart OpenBao permet d'exposer le trafic via un `HTTPRoute`. Si [Gateway API est activé globalement](../globals.md#gateway-api), un écouteur pour OpenBao sera créé dans la ressource `Gateway` gérée.

| Paramètre                  | Défaut                                                 | Description |
|----------------------------|---------------------------------------------------------|-------------|
| `gatewayRoute.enabled`     | Par défaut, valeur de `global.gatewayApi.enabled`        | Activer l'exposition d'OpenBao via un `HTTPRoute`. |
| `gatewayRoute.sectionName` | openbao-web                                             | Section de passerelle à utiliser par le `HTTPRoute`. |
| `gatewayRoute.gatewayName` | Passerelle gérée par le chart GitLab                            | Nom de la passerelle à utiliser par le `HTTPRoute`. |
| `gatewayRoute.annotations` | `{}`                                                    | Annotations supplémentaires pour le `HTTPRoute`. |
| `gatewayRoute.timeouts`    | `{}`                                                    | Configuration de délai d'attente personnalisé pour le `HTTPRoute`. |

### Options de configuration de surveillance {#monitoring-configuration-options}

OpenBao est préconfiguré pour exposer des métriques Prometheus qui seront collectées par le sous-chart Prometheus intégré.

| Paramètre                                                | Défaut                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.telemetry.enabled`                               | true                                                    | Activer la télémétrie et la surveillance. |
| `config.telemetry.disableHostname`                       | true                                                    | Préfixer les valeurs de jauge avec le nom d'hôte local. |
| `config.telemetry.prometheusRetentionTime`               | `24h`                                                   | Durée de rétention des métriques. |
| `config.telemetry.metricsPrefix`                         | `openbao`                                               | Préfixe pour toutes les métriques. |
| `config.telemetry.usageGaugePeriod`                      | 0                                                       | Intervalle de collecte des données d'utilisation à haute cardinalité, telles que les comptages de jetons, d'entités et de secrets. |
| `config.telemetry.numLeaseMetricsBuckets`                | 1                                                       | Nombre de compartiments d'expiration pour les baux. |
| `config.metricsListener.enabled`                         | true                                                    | Activer un second port API pour traiter les requêtes de métriques. L'écouteur peut traiter toutes les requêtes API, mais traite les requêtes de métriques sans authentification. |
| `config.metricsListener.tlsDisable`                      | true                                                    | Désactiver le TLS interne de l'écouteur de métriques. |
| `config.metricsListener.port`                            | 8209                                                    | Port de l'écouteur de métriques. |
| `config.metricsListener.unauthenticatedMetricsAccess`    | true                                                    | Autoriser le traitement des requêtes de métriques sans authentification. |
| `podMonitor.enabled`                                     | false                                                   | Activer la ressource PodMonitor pour Prometheus Operator. Nécessite l'installation de Prometheus Operator dans le cluster. |
| `podMonitor.additionalLabels`                            | `{}`                                                    | Labels supplémentaires à ajouter à la ressource PodMonitor. |
| `podMonitor.selectorLabels`                              | `{}`                                                    | Labels de sélecteur supplémentaires pour filtrer les pods à collecter. |
| `podMonitor.endpointConfig`                              | `{}`                                                    | Configuration d'endpoint supplémentaire (par exemple, `interval`, `scrapeTimeout`). |

### Options de déscellement et d'initialisation {#unsealing-and-initialization-options}

Le chart OpenBao prend en charge deux méthodes de déscellement automatique mutuellement exclusives :

- [déscellement automatique statique](https://openbao.org/docs/configuration/seal/static/) (par défaut)
- [déscellement AWS KMS](https://openbao.org/docs/configuration/seal/awskms/)

Il utilise également [l'auto-initialisation](https://openbao.org/docs/configuration/self-init/) déclarative d'OpenBao.

| Paramètre                                                | Défaut                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.unseal.static.enabled`                           | true                                                    | Activer le déscellement automatique statique. |
| `config.unseal.static.currentKeyId`                      | `static-unseal-0`                                       | Identifiant de la clé de déscellement statique actuelle. |
| `config.unseal.static.currentKey`                        | `/srv/openbao/keys/static-unseal-0`                     | Chemin de la clé de déscellement statique actuelle. |
| `config.unseal.static.previousKeyId`                     |                                                         | Identifiant de la clé de déscellement statique précédente. |
| `config.unseal.static.previousKey`                       | `/srv/openbao/keys/static-unseal-1`                     | Chemin de la clé de déscellement statique précédente. Rendu uniquement si l'identifiant de la clé précédente est également défini. |
| `config.unseal.awskms.enabled`                           | false                                                   | Activer le déscellement automatique AWS KMS. |
| `config.unseal.awskms.kmsKeyId`                          |                                                         | ID de clé KMS, ARN ou alias (par exemple, `alias/my-openbao-key`). Requis lorsque `config.unseal.awskms.enabled` est `true`. |
| `config.unseal.awskms.region`                            |                                                         | Région AWS où réside la clé KMS. |
| `config.unseal.awskms.endpoint`                          |                                                         | URL d'endpoint KMS personnalisé facultatif (par exemple, un endpoint VPC). |
| `config.initialize.enabled`                              | true                                                    | Activer l'auto-initialisation d'OpenBao. |
| `config.initialize.oidcDiscoveryUrl`                     | Hôte GitLab externe                                    | URL de découverte OIDC. Par défaut, le nom d'hôte GitLab externe. |
| `config.initialize.boundIssuer`                          | Hôte GitLab externe                                    | URL de l'émetteur. Par défaut, le nom d'hôte GitLab externe. |
| `config.initialize.boundAudiences`                       | Hôte OpenBao externe                                   | Audiences du rôle OIDC. Par défaut, le nom d'hôte OpenBao externe. |
| `staticUnsealSecret.generate`                            | false                                                   | Générer une clé statique pour désceller automatiquement OpenBao. Par défaut, false, car géré par le chart shared-secret des charts GitLab. |
| `initializeTpl`                                          |                                                         | Modèle transmis pour auto-initialiser OpenBao. Consultez les [valeurs OpenBao](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) pour la valeur par défaut. |

#### Déscellement AWS KMS {#aws-kms-unsealing}

Le déscellement AWS KMS délègue la clé de déscellement à une clé AWS KMS, éliminant ainsi la nécessité de gérer un secret de clé statique.

Lors de l'exécution sur AWS (EKS, EC2), utilisez [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html) ou un profil d'instance afin qu'aucun identifiant AWS explicite ne soit requis. Annotez le compte de service OpenBao avec l'ARN du rôle IAM :

```yaml
openbao:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::<account-id>:role/<role-name>"
  config:
    unseal:
      static:
        enabled: false
      awskms:
        enabled: true
        kmsKeyId: "alias/my-openbao-key"
        region: "us-east-1"
```

Le rôle IAM doit disposer des autorisations `kms:Encrypt`, `kms:Decrypt` et `kms:DescribeKey` sur la clé KMS.

### Options de diffusion des événements d'audit {#audit-event-streaming-options}

Le chart OpenBao configure des [dispositifs d'audit](https://openbao.org/docs/audit/) pour diffuser des événements vers GitLab.

| Paramètre                                                | Défaut                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `global.openbao.httpAudit.secret`                        | `<release>-openbao-audit-secret`                        | Nom du secret stockant le jeton partagé entre OpenBao et GitLab. |
| `global.openbao.httpAudit.key`                           | `token`                                                 | Clé secrète stockant le jeton partagé. |
| `config.audit.http.enabled`                              | true                                                    | Activer la diffusion des événements d'audit via HTTP vers GitLab. |
| `config.audit.http.streamingUri`                         | URL interne du workhorse                                  | Endpoint vers lequel diffuser les événements d'audit. |
| `config.audit.http.authTokenPath`                        | `/srv/openbao/audit/gitlab-auth`                        | Chemin auquel le jeton partagé avec GitLab est monté. |
| `httpAuditSecret.generate`                               | false                                                   | Générer un secret à partager avec GitLab pour l'audit authentifié. Par défaut, false, car géré par le chart shared-secret des charts GitLab. |
| `initializeTpl`                                          |                                                         | Modèle transmis pour configurer l'audit OpenBao. Consultez les [valeurs OpenBao](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) pour la valeur par défaut. |

## Configuration de la base de données {#database-configuration}

OpenBao utilise une **separate logical database** (`openbao` par défaut) pour isoler les données du backend Rails.

Configurez `global.openbao.psql` ou `openbao.config.storage.postgresql.connection` avec l'hôte, la base de données, le nom d'utilisateur et le mot de passe. Vous devez créer la base de données manuellement. **Le mot de passe est requis** et n'est pas hérité de la base de données GitLab principale.

Pour configurer une base de données externe :

1. Créez un utilisateur et une base de données PostgreSQL sur votre serveur de base de données :

   ```sql
   -- Create the OpenBao user
   CREATE USER openbao WITH PASSWORD '<password>';

   -- Create the OpenBao database
   CREATE DATABASE openbao OWNER openbao;
   ```

1. Créez un secret Kubernetes contenant le mot de passe :

   ```shell
   kubectl create secret -n bao generic openbao-db-password --from-literal=password="<password>"
   ```

1. Configurez OpenBao pour se connecter à votre base de données externe :

   ```yaml
   global:
     openbao:
       psql:
         host: "psql.openbao.example.com"
         port: 5432
         database: openbao
         username: openbao
         password:
           secret: openbao-db-password
           key: password
   ```

   Ceci utilise `global.openbao.psql`, qui est l'emplacement préféré car il est également accessible par Toolbox pour les opérations de sauvegarde et de restauration. Pour définir des options de connexion avancées (telles que `sslMode`, `connectTimeout` ou le réglage du keepalive), utilisez `openbao.config.storage.postgresql.connection` en complément des paramètres globaux.

1. Déployez ou mettez à niveau OpenBao. Au démarrage, OpenBao crée automatiquement son schéma de base de données dans la base de données spécifiée.
