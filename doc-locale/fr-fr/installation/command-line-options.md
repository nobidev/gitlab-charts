---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Options de déploiement du chart Helm GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab auto-géré

{{< /details >}}

Cette page répertorie les valeurs couramment utilisées du chart GitLab. Pour obtenir la liste complète des options disponibles, reportez-vous à la documentation de chaque sous-chart.

Vous pouvez passer des valeurs à la commande `helm install` en utilisant un fichier YAML et le flag `--values <values file>` ou en utilisant plusieurs flags `--set`. Il est recommandé d'utiliser un fichier de valeurs qui contient uniquement les remplacements nécessaires pour votre release.

Pour la source du fichier `values.yaml` par défaut, consultez le [dépôt du chart GitLab](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/values.yaml). Ces contenus changent au fil des releases, mais vous pouvez utiliser Helm lui-même pour les récupérer par version :

```shell
helm inspect values gitlab/gitlab
```

## Configuration de base {#basic-configuration}

| Paramètre                                            | Défaut                                       | Description |
|------------------------------------------------------|-----------------------------------------------|-------------|
| `gitlab.migrations.initialRootPassword.key`          | `password`                                    | Clé pointant vers le mot de passe du compte root dans le secret des migrations |
| `gitlab.migrations.initialRootPassword.secret`       | `{Release.Name}-gitlab-initial-root-password` | Nom global du secret contenant le mot de passe du compte root |
| `global.gitlab.license.key`                          | `license`                                     | Clé pointant vers la licence Enterprise dans le secret de licence |
| `global.gitlab.license.secret`                       | _none_                                        | Nom global du secret contenant la licence Enterprise |
| `global.application.create`                          | `false`                                       | Créer une [ressource Application](https://github.com/kubernetes-sigs/application) pour GitLab |
| `global.edition`                                     | `ee`                                          | L'édition de GitLab à installer. Enterprise Edition (`ee`) ou Community Edition (`ce`) |
| `global.gitaly.enabled`                              | `true`                                        | Flag d'activation de Gitaly |
| `global.hosts.domain`                                | Requis                                      | Nom de domaine qui sera utilisé pour tous les services exposés publiquement |
| `global.hosts.externalIP`                            | Requis                                      | IP statique à attribuer au contrôleur NGINX Ingress |
| `global.hosts.ssh`                                   | `gitlab.{global.hosts.domain}`                | Nom de domaine qui sera utilisé pour l'accès Git SSH |
| `global.imagePullPolicy`                             | `IfNotPresent`                                | DÉPRÉCIÉ :  Utilisez `global.image.pullPolicy` à la place |
| `global.image.pullPolicy`                            | _none_ (le comportement par défaut est `IfNotPresent`)   | Définir l'imagePullPolicy par défaut pour tous les charts |
| `global.image.pullSecrets`                           | _none_                                        | Définir les imagePullSecrets par défaut pour tous les charts (utiliser une liste de paires `name` et valeur) |
| `global.minio.enabled`                               | `true`                                        | Flag d'activation de MinIO |
| `global.psql.host`                                   | Requis                                      | Nom d'hôte de l'instance PostgreSQL externe |
| `global.psql.password.key`                           | Requis                                      | Clé pointant vers le mot de passe PostgreSQL dans le secret PostgreSQL |
| `global.psql.password.secret`                        | Requis                                      | Nom global du secret contenant le mot de passe PostgreSQL |
| `global.registry.bucket`                             | `registry`                                    | Nom du bucket du registre de conteneurs |
| `global.service.annotations`                         | `{}`                                          | Annotations à ajouter à chaque `Service` |
| `global.rails.sessionStore.sessionCookieTokenPrefix` | `""`                                          | Préfixe pour les cookies de session générés |
| `global.deployment.annotations`                      | `{}`                                          | Annotations à ajouter à chaque `Deployment` |
| `global.time_zone`                                   | UTC                                           | Fuseau horaire global |

## Configuration TLS {#tls-configuration}

| Paramètre                                           | Défaut | Description |
|-----------------------------------------------------|---------|-------------|
| `certmanager-issuer.email`                          | `false` | E-mail pour le compte Let's Encrypt |
| `gitlab.webservice.ingress.tls.secretName`          | _none_  | `Secret` existant contenant le certificat TLS et la clé pour GitLab |
| `gitlab.webservice.ingress.tls.smartcardSecretName` | _none_  | `Secret` existant contenant le certificat TLS et la clé pour le domaine d'authentification par carte à puce GitLab |
| `global.hosts.https`                                | `true`  | Servir via https |
| `global.ingress.configureCertmanager`               | `false` | Configurer cert-manager pour obtenir des certificats auprès de Let's Encrypt (utilisé uniquement lorsque l'Ingress est activé) |
| `global.gatewayApi.configureCertmanager`            | `true`  | Configurer cert-manager pour obtenir des certificats auprès de Let's Encrypt via un solveur HTTP-01 de l'API Gateway |
| `global.ingress.tls.secretName`                     | _none_  | `Secret` existant contenant le certificat TLS générique et la clé |
| `minio.ingress.tls.secretName`                      | _none_  | `Secret` existant contenant le certificat TLS et la clé pour MinIO |
| `registry.ingress.tls.secretName`                   | _none_  | `Secret` existant contenant le certificat TLS et la clé pour le registre de conteneurs |

## Configuration des e-mails sortants {#outgoing-email-configuration}

| Paramètre                         | Défaut               | Description |
|-----------------------------------|-----------------------|-------------|
| `global.email.display_name`       | `GitLab`              | Nom qui apparaît comme expéditeur des e-mails envoyés par GitLab |
| `global.email.from`               | `gitlab@example.com`  | Adresse e-mail qui apparaît comme expéditeur des e-mails envoyés par GitLab |
| `global.email.reply_to`           | `noreply@example.com` | Adresse de réponse indiquée dans les e-mails envoyés par GitLab |
| `global.email.smime.certName`     | `tls.crt`             | Valeur de clé d'objet Secret pour localiser le fichier de certificat S/MIME |
| `global.email.smime.enabled`      | `false`               | Ajouter les signatures S/MIME aux e-mails sortants |
| `global.email.smime.keyName`      | `tls.key`             | Valeur de clé d'objet Secret pour localiser le fichier de clé S/MIME |
| `global.email.smime.secretName`   | `""`                  | Objet Secret Kubernetes pour trouver le certificat X.509 ([Certificat S/MIME](secrets.md#smime-certificate) pour la création) |
| `global.email.subject_suffix`     | `""`                  | Suffixe dans l'objet de tous les e-mails sortants de GitLab |
| `global.smtp.address`             | `smtp.mailgun.org`    | Nom d'hôte ou IP du serveur de messagerie distant |
| `global.smtp.authentication`      | `plain`               | Type d'authentification SMTP (« plain », « login », « cram_md5 » ou « » pour aucune authentification) |
| `global.smtp.domain`              | `""`                  | Domaine HELO optionnel pour SMTP |
| `global.smtp.enabled`             | `false`               | Activer les e-mails sortants |
| `global.smtp.openssl_verify_mode` | `peer`                | Mode de vérification TLS (« none », « peer », « client_once » ou « fail_if_no_peer_cert ») |
| `global.smtp.password.key`        | `password`            | Clé dans `global.smtp.password.secret` qui contient le mot de passe SMTP |
| `global.smtp.password.secret`     | `""`                  | Nom d'un `Secret` contenant le mot de passe SMTP |
| `global.smtp.port`                | `2525`                | Port pour SMTP |
| `global.smtp.starttls_auto`       | `false`               | Utiliser STARTTLS si activé sur le serveur de messagerie |
| `global.smtp.tls`                 | _none_                | Active SMTP/TLS (SMTPS :  SMTP via une connexion TLS directe) |
| `global.smtp.user_name`           | `""`                  | Nom d'utilisateur pour l'authentification SMTP https |
| `global.smtp.open_timeout`        | `30`                  | Secondes à attendre lors d'une tentative d'ouverture de connexion. |
| `global.smtp.read_timeout`        | `60`                  | Secondes à attendre lors de la lecture d'un bloc. |
| `global.smtp.pool`                | `false`               | Active le pool de connexions SMTP |

### Paramètres du programme de messagerie Microsoft Graph {#microsoft-graph-mailer-settings}

| Paramètre                                                      | Défaut                             | Description |
|----------------------------------------------------------------|-------------------------------------|-------------|
| `global.appConfig.microsoft_graph_mailer.enabled`              | `false`                             | Activer les e-mails sortants via l'API Microsoft Graph |
| `global.appConfig.microsoft_graph_mailer.user_id`              | `""`                                | L'identifiant unique de l'utilisateur qui utilise l'API Microsoft Graph |
| `global.appConfig.microsoft_graph_mailer.tenant`               | `""`                                | Le tenant du répertoire sur lequel l'application prévoit d'opérer, au format GUID ou nom de domaine |
| `global.appConfig.microsoft_graph_mailer.client_id`            | `""`                                | L'ID d'application assigné à votre app. Vous pouvez trouver cette information dans le portail où vous avez enregistré votre app |
| `global.appConfig.microsoft_graph_mailer.client_secret.key`    | `secret`                            | Clé dans `global.appConfig.microsoft_graph_mailer.client_secret.secret` qui contient le secret client que vous avez généré pour votre app dans le portail d'enregistrement d'application |
| `global.appConfig.microsoft_graph_mailer.client_secret.secret` | `""`                                | Nom d'un `Secret` contenant le secret client que vous avez généré pour votre app dans le portail d'enregistrement d'application |
| `global.appConfig.microsoft_graph_mailer.azure_ad_endpoint`    | `https://login.microsoftonline.com` | L'URL du point de terminaison Azure Active Directory |
| `global.appConfig.microsoft_graph_mailer.graph_endpoint`       | `https://graph.microsoft.com`       | L'URL du point de terminaison Microsoft Graph |

## Configuration des e-mails entrants {#incoming-email-configuration}

### Paramètres communs {#common-settings}

Consultez la [documentation des exemples de configuration des e-mails entrants](https://docs.gitlab.com/administration/incoming_email/#configuration-examples) pour plus d'informations.

| Paramètre                                            | Défaut                                    | Description |
|------------------------------------------------------|--------------------------------------------|-------------|
| `global.appConfig.incomingEmail.address`             | vide                                      | L'adresse e-mail pour référencer l'élément auquel on répond (exemple : `gitlab-incoming+%{key}@gmail.com`). Notez que le suffixe `+%{key}` doit être inclus dans son intégralité dans l'adresse e-mail et ne doit pas être remplacé par une autre valeur. |
| `global.appConfig.incomingEmail.enabled`             | `false`                                    | Activer les e-mails entrants |
| `global.appConfig.incomingEmail.deleteAfterDelivery` | `true`                                     | Indique si les messages doivent être marqués comme supprimés. Pour IMAP, les messages marqués comme supprimés sont purgés si `expungedDeleted` est défini sur `true`. Pour Microsoft Graph, définissez cette valeur sur false pour conserver les messages dans la boîte de réception, car les messages supprimés sont automatiquement purgés après un certain temps. |
| `global.appConfig.incomingEmail.expungeDeleted`      | `false`                                    | Indique si les messages doivent être purgés (supprimés définitivement) de la boîte aux lettres lorsqu'ils sont marqués comme supprimés après la livraison. Pertinent uniquement pour IMAP car Microsoft Graph purge automatiquement les messages supprimés. |
| `global.appConfig.incomingEmail.logger.logPath`      | `/dev/stdout`                              | Chemin où écrire les journaux structurés JSON ; définir sur "" pour désactiver cette journalisation |
| `global.appConfig.incomingEmail.inboxMethod`         | `imap`                                     | Lire les e-mails avec IMAP (`imap`) ou l'API Microsoft Graph avec OAuth2 (`microsoft_graph`) |
| `global.appConfig.incomingEmail.deliveryMethod`      | `webhook`                                  | Comment mailroom peut envoyer le contenu d'un e-mail à l'application Rails pour traitement. Soit `sidekiq` soit `webhook` |
| `gitlab.appConfig.incomingEmail.authToken.key`       | `authToken`                                | Clé du token d'e-mail entrant dans le secret d'e-mail entrant. Effectif lorsque la méthode de livraison est webhook. |
| `gitlab.appConfig.incomingEmail.authToken.secret`    | `{Release.Name}-incoming-email-auth-token` | Secret d'authentification des e-mails entrants. Effectif lorsque la méthode de livraison est webhook. |

### Paramètres IMAP {#imap-settings}

| Paramètre                                        | Défaut    | Description |
|--------------------------------------------------|------------|-------------|
| `global.appConfig.incomingEmail.host`            | vide      | Hôte pour IMAP |
| `global.appConfig.incomingEmail.idleTimeout`     | `60`       | Le délai d'expiration de la commande IDLE |
| `global.appConfig.incomingEmail.mailbox`         | `inbox`    | Boîte aux lettres où arriveront les e-mails entrants. |
| `global.appConfig.incomingEmail.password.key`    | `password` | Clé dans `global.appConfig.incomingEmail.password.secret` qui contient le mot de passe IMAP |
| `global.appConfig.incomingEmail.password.secret` | vide      | Nom d'un `Secret` contenant le mot de passe IMAP |
| `global.appConfig.incomingEmail.port`            | `993`      | Port pour IMAP |
| `global.appConfig.incomingEmail.ssl`             | `true`     | Indique si le serveur IMAP utilise SSL |
| `global.appConfig.incomingEmail.startTls`        | `false`    | Indique si le serveur IMAP utilise StartTLS |
| `global.appConfig.incomingEmail.user`            | vide      | Nom d'utilisateur pour l'authentification IMAP |

### Paramètres Microsoft Graph {#microsoft-graph-settings}

| Paramètre                                            | Défaut | Description |
|------------------------------------------------------|---------|-------------|
| `global.appConfig.incomingEmail.tenantId`            | vide   | L'ID de tenant pour votre Microsoft Azure Active Directory |
| `global.appConfig.incomingEmail.clientId`            | vide   | L'ID client pour votre application OAuth2 |
| `global.appConfig.incomingEmail.clientSecret.key`    | vide   | Clé dans `appConfig.incomingEmail.clientSecret.secret` qui contient le secret client OAuth2 |
| `global.appConfig.incomingEmail.clientSecret.secret` | secret  | Nom d'un `Secret` contenant le secret client OAuth2 |
| `global.appConfig.incomingEmail.pollInterval`        | `60`    | L'intervalle en secondes pour vérifier les nouveaux e-mails |
| `global.appConfig.incomingEmail.azureAdEndpoint`     | vide   | L'URL du point de terminaison Azure Active Directory (exemple : `https://login.microsoftonline.com`) |
| `global.appConfig.incomingEmail.graphEndpoint`       | vide   | L'URL du point de terminaison Microsoft Graph (exemple : `https://graph.microsoft.com`) |

Consultez les [instructions pour créer des secrets](secrets.md).

## Configuration des e-mails Service Desk {#service-desk-email-configuration}

Comme prérequis pour Service Desk, le service de messagerie entrant doit être [configuré](#incoming-email-configuration). Notez que l'adresse e-mail pour la messagerie entrante et Service Desk doit utiliser le [sous-adressage e-mail](https://docs.gitlab.com/administration/incoming_email/#email-sub-addressing). Lors de la définition des adresses e-mail dans chaque section, le tag ajouté au nom d'utilisateur doit être `+%{key}`.

### Paramètres communs {#common-settings-1}

| Paramètre                                               | Défaut                                        | Description |
|---------------------------------------------------------|------------------------------------------------|-------------|
| `global.appConfig.serviceDeskEmail.address`             | vide                                          | L'adresse e-mail pour référencer l'élément auquel on répond (exemple : `project_contact+%{key}@gmail.com`) |
| `global.appConfig.serviceDeskEmail.enabled`             | `false`                                        | Activer les e-mails Service Desk |
| `global.appConfig.serviceDeskEmail.deleteAfterDelivery` | `true`                                         | Indique si les messages doivent être marqués comme supprimés. Pour IMAP, les messages marqués comme supprimés sont purgés si `expungedDeleted` est défini sur `true`. Pour Microsoft Graph, définissez cette valeur sur false pour conserver les messages dans la boîte de réception, car les messages supprimés sont automatiquement purgés après un certain temps. |
| `global.appConfig.serviceDeskEmail.expungeDeleted`      | `false`                                        | Indique si les messages doivent être purgés (supprimés définitivement) de la boîte aux lettres lorsqu'ils sont marqués comme supprimés après la livraison. Pertinent uniquement pour IMAP car Microsoft Graph purge automatiquement les messages supprimés. |
| `global.appConfig.serviceDeskEmail.logger.logPath`      | `/dev/stdout`                                  | Chemin où écrire les journaux structurés JSON ; définir sur "" pour désactiver cette journalisation |
| `global.appConfig.serviceDeskEmail.inboxMethod`         | `imap`                                         | Lire les e-mails avec IMAP (`imap`) ou l'API Microsoft Graph avec OAuth2 (`microsoft_graph`) |
| `global.appConfig.serviceDeskEmail.deliveryMethod`      | `webhook`                                      | Comment mailroom peut envoyer le contenu d'un e-mail à l'application Rails pour traitement. Soit `sidekiq` soit `webhook` |
| `gitlab.appConfig.serviceDeskEmail.authToken.key`       | `authToken`                                    | Clé du token d'e-mail Service Desk dans le secret d'e-mail Service Desk. Effectif lorsque la méthode de livraison est webhook. |
| `gitlab.appConfig.serviceDeskEmail.authToken.secret`    | `{Release.Name}-service-desk-email-auth-token` | Secret d'authentification des e-mails service-desk. Effectif lorsque la méthode de livraison est webhook. |

### Paramètres IMAP {#imap-settings-1}

| Paramètre                                           | Défaut    | Description |
|-----------------------------------------------------|------------|-------------|
| `global.appConfig.serviceDeskEmail.host`            | vide      | Hôte pour IMAP |
| `global.appConfig.serviceDeskEmail.idleTimeout`     | `60`       | Le délai d'expiration de la commande IDLE |
| `global.appConfig.serviceDeskEmail.mailbox`         | `inbox`    | Boîte aux lettres où arriveront les e-mails Service Desk. |
| `global.appConfig.serviceDeskEmail.password.key`    | `password` | Clé dans `global.appConfig.serviceDeskEmail.password.secret` qui contient le mot de passe IMAP |
| `global.appConfig.serviceDeskEmail.password.secret` | vide      | Nom d'un `Secret` contenant le mot de passe IMAP |
| `global.appConfig.serviceDeskEmail.port`            | `993`      | Port pour IMAP |
| `global.appConfig.serviceDeskEmail.ssl`             | `true`     | Indique si le serveur IMAP utilise SSL |
| `global.appConfig.serviceDeskEmail.startTls`        | `false`    | Indique si le serveur IMAP utilise StartTLS |
| `global.appConfig.serviceDeskEmail.user`            | vide      | Nom d'utilisateur pour l'authentification IMAP |

### Paramètres Microsoft Graph {#microsoft-graph-settings-1}

| Paramètre                                               | Défaut | Description |
|---------------------------------------------------------|---------|-------------|
| `global.appConfig.serviceDeskEmail.tenantId`            | vide   | L'ID de tenant pour votre Microsoft Azure Active Directory |
| `global.appConfig.serviceDeskEmail.clientId`            | vide   | L'ID client pour votre application OAuth2 |
| `global.appConfig.serviceDeskEmail.clientSecret.key`    | vide   | Clé dans `appConfig.serviceDeskEmail.clientSecret.secret` qui contient le secret client OAuth2 |
| `global.appConfig.serviceDeskEmail.clientSecret.secret` | secret  | Nom d'un `Secret` contenant le secret client OAuth2 |
| `global.appConfig.serviceDeskEmail.pollInterval`        | `60`    | L'intervalle en secondes pour vérifier les nouveaux e-mails |
| `global.appConfig.serviceDeskEmail.azureAdEndpoint`     | vide   | L'URL du point de terminaison Azure Active Directory (exemple : `https://login.microsoftonline.com`) |
| `global.appConfig.serviceDeskEmail.graphEndpoint`       | vide   | L'URL du point de terminaison Microsoft Graph (exemple : `https://graph.microsoft.com`) |

Consultez les [instructions pour créer des secrets](secrets.md).

## Configuration des fonctionnalités de projet par défaut {#default-project-features-configuration}

| Paramètre                                                    | Défaut | Description |
|--------------------------------------------------------------|---------|-------------|
| `global.appConfig.defaultProjectsFeatures.builds`            | `true`  | Activer les builds de projet |
| `global.appConfig.defaultProjectsFeatures.containerRegistry` | `true`  | Activer les fonctionnalités de projet du registre de conteneurs |
| `global.appConfig.defaultProjectsFeatures.issues`            | `true`  | Activer les tickets de projet |
| `global.appConfig.defaultProjectsFeatures.mergeRequests`     | `true`  | Activer les merge requests de projet |
| `global.appConfig.defaultProjectsFeatures.snippets`          | `true`  | Activer les snippets de projet |
| `global.appConfig.defaultProjectsFeatures.wiki`              | `true`  | Activer les wikis de projet |

## GitLab Shell {#gitlab-shell}

| Paramètre                        | Défaut | Description |
|----------------------------------|---------|-------------|
| `global.shell.authToken`         |         | Secret contenant le secret partagé |
| `global.shell.hostKeys`          |         | Secret contenant les clés d'hôte SSH |
| `global.shell.port`              |         | Numéro de port à exposer sur l'Ingress pour SSH |
| `global.shell.tcp.proxyProtocol` | `false` | Activer ProxyProtocol dans l'Ingress SSH |

## Paramètres RBAC {#rbac-settings}

| Paramètre                              | Défaut | Description |
|----------------------------------------|---------|-------------|
| `certmanager.rbac.create`              | `true`  | Créer et utiliser des ressources RBAC |
| `gitlab-runner.rbac.create`            | `true`  | Créer et utiliser des ressources RBAC |
| `nginx-ingress.rbac.create`            | `false` | Créer et utiliser les ressources RBAC par défaut |
| `nginx-ingress.rbac.createClusterRole` | `false` | Créer et utiliser le rôle de cluster |
| `nginx-ingress.rbac.createRole`        | `true`  | Créer et utiliser le rôle namespacé |
| `prometheus.rbac.create`               | `true`  | Créer et utiliser des ressources RBAC |

Si vous définissez `nginx-ingress.rbac.create` sur `false` pour configurer vous-même les règles RBAC, vous devrez peut-être ajouter des règles RBAC spécifiques [en fonction de votre version de chart](../releases/8_0.md#upgrade-to-86x-851-843-836).

## Configuration avancée de NGINX Ingress {#advanced-nginx-ingress-configuration}

Préfixez les valeurs NGINX Ingress avec `nginx-ingress`. Par exemple, définissez le tag d'image du contrôleur en utilisant `nginx-ingress.controller.image.tag`.

Consultez le [chart `nginx-ingress`](../charts/nginx/_index.md).

## Configuration Redis externe {#external-redis-configuration}

Consultez [Configurer le chart GitLab avec un Redis externe](../advanced/external-redis/_index.md) pour les instructions de configuration complètes.

## Configuration avancée du registre de conteneurs {#advanced-registry-configuration}

| Paramètre                                           | Défaut                                     | Description |
|-----------------------------------------------------|---------------------------------------------|-------------|
| `registry.authEndpoint`                             | Non défini par défaut                        | Point de terminaison d'authentification |
| `registry.enabled`                                  | `true`                                      | Activer le registre Docker |
| `registry.httpSecret`                               |                                             | Secret Https |
| `registry.minio.bucket`                             | `registry`                                  | Nom du bucket du registre de conteneurs MinIO |
| `registry.service.annotations`                      | `{}`                                        | Annotations à ajouter au `Service` |
| `registry.securityContext.fsGroup`                  | `1000`                                      | ID de groupe sous lequel le pod doit être démarré |
| `registry.securityContext.runAsUser`                | `1000`                                      | ID d'utilisateur sous lequel le pod doit être démarré |
| `registry.tokenIssuer`                              | `gitlab-issuer`                             | Émetteur de token JWT |
| `registry.tokenService`                             | `container_registry`                        | Service de token JWT |
| `registry.profiling.stackdriver.enabled`            | `false`                                     | Activer le profilage continu avec Stackdriver |
| `registry.profiling.stackdriver.credentials.secret` | `gitlab-registry-profiling-creds`           | Nom du secret contenant les informations d'identification |
| `registry.profiling.stackdriver.credentials.key`    | `credentials`                               | Clé du secret dans laquelle les informations d'identification sont stockées |
| `registry.profiling.stackdriver.service`            | `RELEASE-registry` (nom de Service généré par template) | Nom du service Stackdriver sous lequel enregistrer les profils |
| `registry.profiling.stackdriver.projectid`          | Projet GCP en cours d'exécution                   | Projet GCP auquel signaler les profils |

## Configuration MinIO avancée {#advanced-minio-configuration}

| Paramètre                            | Défaut                        | Description |
|--------------------------------------|--------------------------------|-------------|
| `minio.defaultBuckets`               | `[{"name": "registry"}]`       | Buckets MinIO par défaut |
| `minio.image`                        | `minio/minio`                  | Image MinIO |
| `minio.imagePullPolicy`              |                                | Politique de tirage d'image MinIO |
| `minio.imageTag`                     | `RELEASE.2017-12-28T01-21-00Z` | Tag d'image MinIO |
| `minio.minioConfig.browser`          | `on`                           | Flag du navigateur MinIO |
| `minio.minioConfig.domain`           |                                | Domaine MinIO |
| `minio.minioConfig.region`           | `us-east-1`                    | Région MinIO |
| `minio.mountPath`                    | `/export`                      | Chemin de montage du fichier de configuration MinIO |
| `minio.persistence.accessMode`       | `ReadWriteOnce`                | Mode d'accès à la persistance MinIO |
| `minio.persistence.enabled`          | `true`                         | Flag d'activation de la persistance MinIO |
| `minio.persistence.matchExpressions` |                                | Correspondances d'expressions de labels MinIO à lier |
| `minio.persistence.matchLabels`      |                                | Correspondances de valeurs de labels MinIO à lier |
| `minio.persistence.size`             | `10Gi`                         | Taille du volume de persistance MinIO |
| `minio.persistence.storageClass`     |                                | storageClassName MinIO pour le provisionnement |
| `minio.persistence.subPath`          |                                | Chemin de montage du volume de persistance MinIO |
| `minio.persistence.volumeName`       |                                | Nom du volume persistant MinIO existant |
| `minio.resources.requests.cpu`       | `250m`                         | CPU minimum demandé par MinIO |
| `minio.resources.requests.memory`    | `256Mi`                        | Mémoire minimum demandée par MinIO |
| `minio.service.annotations`          | `{}`                           | Annotations à ajouter au `Service` |
| `minio.servicePort`                  | `9000`                         | Port du service MinIO |
| `minio.serviceType`                  | `ClusterIP`                    | Type de service MinIO |

## Configuration GitLab avancée {#advanced-gitlab-configuration}

| Paramètre                                                  | Défaut                                                         | Description |
|------------------------------------------------------------|-----------------------------------------------------------------|-------------|
| `gitlab-runner.checkInterval`                              | `30s`                                                           | intervalle de sondage |
| `gitlab-runner.concurrent`                                 | `20`                                                            | nombre de jobs simultanés |
| `gitlab-runner.imagePullPolicy`                            | `IfNotPresent`                                                  | politique de tirage d'image |
| `gitlab-runner.image`                                      | `gitlab/gitlab-runner:alpine-v10.5.0`                           | image du runner |
| `gitlab-runner.gitlabUrl`                                  | URL externe GitLab                                             | URL que le runner utilise pour s'enregistrer auprès du serveur GitLab |
| `gitlab-runner.install`                                    | `true`                                                          | installer le chart `gitlab-runner` |
| `gitlab-runner.rbac.clusterWideAccess`                     | `false`                                                         | déployer des conteneurs de jobs à l'échelle du cluster |
| `gitlab-runner.rbac.create`                                | `true`                                                          | indique s'il faut créer un compte de service RBAC |
| `gitlab-runner.rbac.serviceAccountName`                    | `default`                                                       | nom du compte de service RBAC à créer |
| `gitlab-runner.resources.limits.cpu`                       |                                                                 | ressources du runner |
| `gitlab-runner.resources.limits.memory`                    |                                                                 | ressources du runner |
| `gitlab-runner.resources.requests.cpu`                     |                                                                 | ressources du runner |
| `gitlab-runner.resources.requests.memory`                  |                                                                 | ressources du runner |
| `gitlab-runner.runners.privileged`                         | `false`                                                         | exécuter en mode privilégié, nécessaire pour `dind` |
| `gitlab-runner.runners.cache.secretName`                   | `gitlab-minio`                                                  | secret pour obtenir `accesskey` et `secretkey` |
| `gitlab-runner.runners.config`                             | Voir la [documentation du chart](../charts/gitlab/gitlab-runner/_index.md#default-runner-configuration) | Configuration du runner sous forme de chaîne |
| `gitlab-runner.unregisterRunners`                          | `true`                                                          | Désenregistre tous les runners dans le `config.toml` local lors de l'installation du chart. Si le token est préfixé par `glrt-`, le gestionnaire de runner est supprimé, et non le runner. Le gestionnaire de runner est identifié par le runner et la machine qui contient le `config.toml`. Si le runner a été enregistré avec un token d'enregistrement, le runner est supprimé. |
| `gitlab.geo-logcursor.securityContext.fsGroup`             | `1000`                                                          | ID de groupe sous lequel le pod doit être démarré |
| `gitlab.geo-logcursor.securityContext.runAsUser`           | `1000`                                                          | ID d'utilisateur sous lequel le pod doit être démarré |
| `gitlab.gitaly.authToken.key`                              | `token`                                                         | Clé du token Gitaly dans le secret |
| `gitlab.gitaly.authToken.secret`                           | `{.Release.Name}-gitaly-secret`                                 | Nom du secret Gitaly |
| `gitlab.gitaly.image.pullPolicy`                           |                                                                 | Politique de tirage d'image Gitaly |
| `gitlab.gitaly.image.repository`                           | `registry.gitlab.com/gitlab-org/build/cng/gitaly`               | Dépôt d'image Gitaly |
| `gitlab.gitaly.image.tag`                                  | `master`                                                        | Tag d'image Gitaly |
| `gitlab.gitaly.persistence.accessMode`                     | `ReadWriteOnce`                                                 | Mode d'accès à la persistance Gitaly |
| `gitlab.gitaly.persistence.enabled`                        | `true`                                                          | Flag d'activation de la persistance Gitaly |
| `gitlab.gitaly.persistence.matchExpressions`               |                                                                 | Correspondances d'expressions de labels à lier |
| `gitlab.gitaly.persistence.matchLabels`                    |                                                                 | Correspondances de valeurs de labels à lier |
| `gitlab.gitaly.persistence.size`                           | `50Gi`                                                          | Taille du volume de persistance Gitaly |
| `gitlab.gitaly.persistence.storageClass`                   |                                                                 | storageClassName pour le provisionnement |
| `gitlab.gitaly.persistence.subPath`                        |                                                                 | Chemin de montage du volume de persistance Gitaly |
| `gitlab.gitaly.persistence.volumeName`                     |                                                                 | Nom du volume persistant existant |
| `gitlab.gitaly.securityContext.fsGroup`                    | `1000`                                                          | ID de groupe sous lequel le pod doit être démarré |
| `gitlab.gitaly.securityContext.runAsUser`                  | `1000`                                                          | ID d'utilisateur sous lequel le pod doit être démarré |
| `gitlab.gitaly.service.annotations`                        | `{}`                                                            | Annotations à ajouter au `Service` |
| `gitlab.gitaly.service.externalPort`                       | `8075`                                                          | Port exposé du service Gitaly |
| `gitlab.gitaly.service.internalPort`                       | `8075`                                                          | Port interne Gitaly |
| `gitlab.gitaly.service.name`                               | `gitaly`                                                        | Nom du service Gitaly |
| `gitlab.gitaly.service.type`                               | `ClusterIP`                                                     | Type de service Gitaly |
| `gitlab.gitaly.serviceName`                                | `gitaly`                                                        | Nom du service Gitaly |
| `gitlab.gitaly.shell.authToken.key`                        | `secret`                                                        | Clé Shell   |
| `gitlab.gitaly.shell.authToken.secret`                     | `{Release.Name}-gitlab-shell-secret`                            | Secret Shell |
| `gitlab.gitlab-exporter.securityContext.fsGroup`           | `1000`                                                          | ID de groupe sous lequel le pod doit être démarré |
| `gitlab.gitlab-exporter.securityContext.runAsUser`         | `1000`                                                          | ID d'utilisateur sous lequel le pod doit être démarré |
| `gitlab.gitlab-shell.authToken.key`                        | `secret`                                                        | Clé du secret d'authentification Shell |
| `gitlab.gitlab-shell.authToken.secret`                     | `{Release.Name}-gitlab-shell-secret`                            | Secret d'authentification Shell |
| `gitlab.gitlab-shell.enabled`                              | `true`                                                          | Flag d'activation Shell |
| `gitlab.gitlab-shell.image.pullPolicy`                     |                                                                 | Politique de tirage d'image Shell |
| `gitlab.gitlab-shell.image.repository`                     | `registry.gitlab.com/gitlab-org/build/cng/gitlab-shell`         | Dépôt d'image Shell |
| `gitlab.gitlab-shell.image.tag`                            | `master`                                                        | Tag d'image Shell |
| `gitlab.gitlab-shell.replicaCount`                         | `1`                                                             | Réplicas Shell |
| `gitlab.gitlab-shell.securityContext.fsGroup`              | `1000`                                                          | ID de groupe sous lequel le pod doit être démarré |
| `gitlab.gitlab-shell.securityContext.runAsUser`            | `1000`                                                          | ID d'utilisateur sous lequel le pod doit être démarré |
| `gitlab.gitlab-shell.service.annotations`                  | `{}`                                                            | Annotations à ajouter au `Service` |
| `gitlab.gitlab-shell.service.internalPort`                 | `2222`                                                          | Port interne Shell |
| `gitlab.gitlab-shell.service.name`                         | `gitlab-shell`                                                  | Nom du service Shell |
| `gitlab.gitlab-shell.service.type`                         | `ClusterIP`                                                     | Type de service Shell |
| `gitlab.gitlab-shell.webservice.serviceName`               | hérité de `global.webservice.serviceName`                  | Nom du service Webservice |
| `gitlab.mailroom.securityContext.fsGroup`                  | `1000`                                                          | ID de groupe sous lequel le pod doit être démarré |
| `gitlab.mailroom.securityContext.runAsUser`                | `1000`                                                          | ID d'utilisateur sous lequel le pod doit être démarré |
| `gitlab.migrations.bootsnap.enabled`                       | `true`                                                          | Flag d'activation de Bootsnap pour les migrations |
| `gitlab.migrations.enabled`                                | `true`                                                          | Flag d'activation des migrations |
| `gitlab.migrations.image.pullPolicy`                       |                                                                 | Politique de tirage des migrations |
| `gitlab.migrations.image.repository`                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee`    | Dépôt d'image des migrations |
| `gitlab.migrations.image.tag`                              | `master`                                                        | Tag d'image des migrations |
| `gitlab.migrations.psql.password.key`                      | `psql-password`                                                 | Clé du mot de passe PostgreSQL dans le secret PostgreSQL |
| `gitlab.migrations.psql.password.secret`                   | `gitlab-postgres`                                               | Secret PostgreSQL |
| `gitlab.migrations.psql.port`                              |                                                                 | Définir le port du serveur PostgreSQL. Est prioritaire sur `global.psql.port` |
| `gitlab.migrations.securityContext.fsGroup`                | `1000`                                                          | ID de groupe sous lequel le pod doit être démarré |
| `gitlab.migrations.securityContext.runAsUser`              | `1000`                                                          | ID d'utilisateur sous lequel le pod doit être démarré |
| `gitlab.sidekiq.concurrency`                               | `20`                                                            | Concurrence par défaut de Sidekiq |
| `gitlab.sidekiq.enabled`                                   | `true`                                                          | Flag d'activation de Sidekiq |
| `gitlab.sidekiq.gitaly.authToken.key`                      | `token`                                                         | Clé du token Gitaly dans le secret Gitaly |
| `gitlab.sidekiq.gitaly.authToken.secret`                   | `{.Release.Name}-gitaly-secret`                                 | Secret Gitaly |
| `gitlab.sidekiq.gitaly.serviceName`                        | `gitaly`                                                        | Nom du service Gitaly |
| `gitlab.sidekiq.image.pullPolicy`                          |                                                                 | Politique de tirage d'image Sidekiq |
| `gitlab.sidekiq.image.repository`                          | `registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ee`    | Dépôt d'image Sidekiq |
| `gitlab.sidekiq.image.tag`                                 | `master`                                                        | Tag d'image Sidekiq |
| `gitlab.sidekiq.psql.password.key`                         | `psql-password`                                                 | Clé du mot de passe PostgreSQL dans le secret PostgreSQL |
| `gitlab.sidekiq.psql.password.secret`                      | `gitlab-postgres`                                               | Secret du mot de passe PostgreSQL |
| `gitlab.sidekiq.psql.port`                                 |                                                                 | Définir le port du serveur PostgreSQL. Est prioritaire sur `global.psql.port` |
| `gitlab.sidekiq.replicas`                                  | `1`                                                             | Réplicas Sidekiq |
| `gitlab.sidekiq.resources.requests.cpu`                    | `100m`                                                          | CPU minimum requis par Sidekiq |
| `gitlab.sidekiq.resources.requests.memory`                 | `600M`                                                          | Mémoire minimum requise par Sidekiq |
| `gitlab.sidekiq.securityContext.fsGroup`                   | `1000`                                                          | ID de groupe sous lequel le pod doit être démarré |
| `gitlab.sidekiq.securityContext.runAsUser`                 | `1000`                                                          | ID d'utilisateur sous lequel le pod doit être démarré |
| `gitlab.sidekiq.timeout`                                   | `5`                                                             | Délai d'expiration du job Sidekiq |
| `gitlab.toolbox.annotations`                               | `{}`                                                            | Annotations à ajouter à la toolbox |
| `gitlab.toolbox.backups.cron.enabled`                      | `false`                                                         | Flag d'activation du CronJob de sauvegarde |
| `gitlab.toolbox.backups.cron.extraArgs`                    |                                                                 | Chaîne d'arguments à passer à l'utilitaire de sauvegarde |
| `gitlab.toolbox.backups.cron.persistence.accessMode`       | `ReadWriteOnce`                                                 | Mode d'accès à la persistance du cron de sauvegarde |
| `gitlab.toolbox.backups.cron.persistence.enabled`          | `false`                                                         | Flag d'activation de la persistance du cron de sauvegarde |
| `gitlab.toolbox.backups.cron.persistence.matchExpressions` |                                                                 | Correspondances d'expressions de labels à lier |
| `gitlab.toolbox.backups.cron.persistence.matchLabels`      |                                                                 | Correspondances de valeurs de labels à lier |
| `gitlab.toolbox.backups.cron.persistence.size`             | `10Gi`                                                          | Taille du volume de persistance du cron de sauvegarde |
| `gitlab.toolbox.backups.cron.persistence.storageClass`     |                                                                 | storageClassName pour le provisionnement |
| `gitlab.toolbox.backups.cron.persistence.subPath`          |                                                                 | Chemin de montage du volume de persistance du cron de sauvegarde |
| `gitlab.toolbox.backups.cron.persistence.volumeName`       |                                                                 | Nom du volume persistant existant |
| `gitlab.toolbox.backups.cron.resources.requests.cpu`       | `50m`                                                           | CPU minimum requis par le cron de sauvegarde |
| `gitlab.toolbox.backups.cron.resources.requests.memory`    | `350M`                                                          | Mémoire minimum requise par le cron de sauvegarde |
| `gitlab.toolbox.backups.cron.schedule`                     | `0 1 * * *`                                                     | Chaîne de planification de style cron |
| `gitlab.toolbox.backups.objectStorage.backend`             | `s3`                                                            | Fournisseur de stockage d'objets à utiliser (`s3`, `gcs` ou `azure`) |
| `gitlab.toolbox.backups.objectStorage.config.gcpProject`   | `""`                                                            | Projet GCP à utiliser lorsque le backend est `gcs` |
| `gitlab.toolbox.backups.objectStorage.config.key`          | `""`                                                            | Clé contenant les informations d'identification dans le secret |
| `gitlab.toolbox.backups.objectStorage.config.secret`       | `""`                                                            | Secret des informations d'identification du stockage d'objets |
| `gitlab.toolbox.backups.objectStorage.config`              | `{}`                                                            | Informations d'authentification pour le stockage d'objets |
| `gitlab.toolbox.bootsnap.enabled`                          | `true`                                                          | Activer le cache Bootsnap dans la Toolbox |
| `gitlab.toolbox.enabled`                                   | `true`                                                          | Flag d'activation de la Toolbox |
| `gitlab.toolbox.image.pullPolicy`                          | `IfNotPresent`                                                  | Politique de tirage d'image de la Toolbox |
| `gitlab.toolbox.image.repository`                          | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee`    | Dépôt d'image de la Toolbox |
| `gitlab.toolbox.image.tag`                                 | `master`                                                        | Tag d'image de la Toolbox |
| `gitlab.toolbox.init.image.repository`                     |                                                                 | Dépôt d'image d'initialisation de la Toolbox |
| `gitlab.toolbox.init.image.tag`                            |                                                                 | Tag d'image d'initialisation de la Toolbox |
| `gitlab.toolbox.init.resources.requests.cpu`               | `50m`                                                           | CPU minimum requis par l'initialisation de la Toolbox |
| `gitlab.toolbox.persistence.accessMode`                    | `ReadWriteOnce`                                                 | Mode d'accès à la persistance de la Toolbox |
| `gitlab.toolbox.persistence.enabled`                       | `false`                                                         | Flag d'activation de la persistance de la Toolbox |
| `gitlab.toolbox.persistence.matchExpressions`              |                                                                 | Correspondances d'expressions de labels à lier |
| `gitlab.toolbox.persistence.matchLabels`                   |                                                                 | Correspondances de valeurs de labels à lier |
| `gitlab.toolbox.persistence.size`                          | `10Gi`                                                          | Taille du volume de persistance de la Toolbox |
| `gitlab.toolbox.persistence.storageClass`                  |                                                                 | storageClassName pour le provisionnement |
| `gitlab.toolbox.persistence.subPath`                       |                                                                 | Chemin de montage du volume de persistance de la Toolbox |
| `gitlab.toolbox.persistence.volumeName`                    |                                                                 | Nom du volume persistant existant |
| `gitlab.toolbox.psql.port`                                 |                                                                 | Définir le port du serveur PostgreSQL. Est prioritaire sur `global.psql.port` |
| `gitlab.toolbox.resources.requests.cpu`                    | `50m`                                                           | CPU minimum requis par la Toolbox |
| `gitlab.toolbox.resources.requests.memory`                 | `350M`                                                          | Mémoire minimum requise par la Toolbox |
| `gitlab.toolbox.securityContext.fsGroup`                   | `1000`                                                          | ID de groupe sous lequel le pod doit être démarré |
| `gitlab.toolbox.securityContext.runAsUser`                 | `1000`                                                          | ID d'utilisateur sous lequel le pod doit être démarré |
| `gitlab.webservice.enabled`                                | `true`                                                          | Flag d'activation du webservice |
| `gitlab.webservice.gitaly.authToken.key`                   | `token`                                                         | Clé du token Gitaly dans le secret Gitaly |
| `gitlab.webservice.gitaly.authToken.secret`                | `{.Release.Name}-gitaly-secret`                                 | Nom du secret Gitaly |
| `gitlab.webservice.gitaly.serviceName`                     | `gitaly`                                                        | Nom du service Gitaly |
| `gitlab.webservice.image.pullPolicy`                       |                                                                 | Politique de tirage d'image du webservice |
| `gitlab.webservice.image.repository`                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ee` | Dépôt d'image du webservice |
| `gitlab.webservice.image.tag`                              | `master`                                                        | Tag d'image du webservice |
| `gitlab.webservice.psql.password.key`                      | `psql-password`                                                 | Clé du mot de passe PostgreSQL dans le secret PostgreSQL |
| `gitlab.webservice.psql.password.secret`                   | `gitlab-postgres`                                               | Nom du secret PostgreSQL |
| `gitlab.webservice.psql.port`                              |                                                                 | Définir le port du serveur PostgreSQL. Est prioritaire sur `global.psql.port` |
| `global.registry.enabled`                                  | `true`                                                          | Activer le registre de conteneurs. Copie de `registry.enabled` |
| `global.registry.api.port`                                 | `5000`                                                          | Port du registre de conteneurs |
| `global.registry.api.protocol`                             | `http`                                                          | Protocole du registre de conteneurs |
| `global.registry.api.serviceName`                          | `registry`                                                      | Nom du service du registre de conteneurs |
| `global.registry.tokenIssuer`                              | `gitlab-issuer`                                                 | Émetteur de token du registre de conteneurs |
| `gitlab.webservice.replicaCount`                           | `1`                                                             | Nombre de réplicas du webservice |
| `gitlab.webservice.resources.requests.cpu`                 | `200m`                                                          | CPU minimum du webservice |
| `gitlab.webservice.resources.requests.memory`              | `1.4G`                                                          | Mémoire minimum du webservice |
| `gitlab.webservice.securityContext.fsGroup`                | `1000`                                                          | ID de groupe sous lequel le pod doit être démarré |
| `gitlab.webservice.securityContext.runAsUser`              | `1000`                                                          | ID d'utilisateur sous lequel le pod doit être démarré |
| `gitlab.webservice.service.annotations`                    | `{}`                                                            | Annotations à ajouter au `Service` |
| `gitlab.webservice.http.enabled`                           | `true`                                                          | HTTP activé pour le webservice |
| `gitlab.webservice.service.externalPort`                   | `8080`                                                          | Port exposé du webservice |
| `gitlab.webservice.service.internalPort`                   | `8080`                                                          | Port interne du webservice |
| `gitlab.webservice.tls.enabled`                            | `false`                                                         | TLS activé pour le webservice |
| `gitlab.webservice.tls.secretName`                         | `{Release.Name}-webservice-tls`                                 | Nom du secret de la clé TLS du webservice |
| `gitlab.webservice.service.tls.externalPort`               | `8081`                                                          | Port TLS exposé du webservice |
| `gitlab.webservice.service.tls.internalPort`               | `8081`                                                          | Port TLS interne du webservice |
| `gitlab.webservice.service.type`                           | `ClusterIP`                                                     | Type de service du webservice |
| `gitlab.webservice.service.workhorseExternalPort`          | `8181`                                                          | Port exposé de Workhorse |
| `gitlab.webservice.service.workhorseInternalPort`          | `8181`                                                          | Port interne de Workhorse |
| `gitlab.webservice.shell.authToken.key`                    | `secret`                                                        | Clé du token Shell dans le secret Shell |
| `gitlab.webservice.shell.authToken.secret`                 | `{Release.Name}-gitlab-shell-secret`                            | Secret du token Shell |
| `gitlab.webservice.workerProcesses`                        | `2`                                                             | Nombre de workers du webservice |
| `gitlab.webservice.workerTimeout`                          | `60`                                                            | Délai d'expiration du worker du webservice |
| `gitlab.webservice.workhorse.extraArgs`                    | `""`                                                            | Chaîne de paramètres supplémentaires pour workhorse |
| `gitlab.webservice.workhorse.image`                        | `registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ee`  | Dépôt d'image Workhorse |
| `gitlab.webservice.workhorse.sentryDSN`                    | `""`                                                            | DSN pour l'instance Sentry pour le signalement d'erreurs |
| `gitlab.webservice.workhorse.tag`                          |                                                                 | Tag d'image Workhorse |

## Charts externes {#external-charts}

GitLab utilise plusieurs autres charts. Ces charts sont [traités comme des relations parent-enfant](https://helm.sh/docs/topics/charts/#chart-dependencies). Assurez-vous que toutes les propriétés que vous souhaitez configurer sont fournies sous la forme `chart-name.property`.

### Prometheus {#prometheus}

Préfixez les valeurs Prometheus avec `prometheus`. Par exemple, définissez la valeur de stockage de persistance en utilisant `prometheus.server.persistentVolume.size`. Pour désactiver Prometheus, définissez `prometheus.install=false`.

Consultez la [documentation du chart Prometheus](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus) pour la liste exhaustive des options de configuration.

## Apporter vos propres images {#bringing-your-own-images}

Dans certains scénarios (c'est-à-dire les environnements hors ligne), vous pouvez souhaiter apporter vos propres images plutôt que de les télécharger depuis Internet. Cela nécessite de spécifier votre propre registre/dépôt d'images Docker pour chacun des charts qui constituent la release GitLab.

Consultez la [documentation des images personnalisées](../advanced/custom-images/_index.md) pour plus d'informations.
