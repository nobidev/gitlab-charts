---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Base de données de métadonnées du registre de conteneurs
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [Introduite](https://gitlab.com/groups/gitlab-org/-/epics/5521) dans GitLab 16.4 en tant que fonctionnalité [bêta](https://docs.gitlab.com/policy/development_stages_support/#beta).
- [Disponible généralement](https://gitlab.com/gitlab-org/gitlab/-/issues/423459) dans GitLab 17.3.

{{< /history >}}

La base de données de métadonnées offre de nombreuses nouvelles fonctionnalités de registre de conteneurs, notamment la collecte des déchets en ligne, et améliore l'efficacité de nombreuses opérations de registre.

Si vous disposez de registres de conteneurs existants, vous pouvez migrer vers la base de données de métadonnées.

Certaines fonctionnalités activées par la base de données sont uniquement disponibles pour GitLab.com et le provisionnement automatique de la base de données pour la base de données du registre n'est pas disponible. Consultez la section de support des fonctionnalités dans la [documentation d'administration](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#metadata-database-feature-support) pour connaître le statut des fonctionnalités liées à la base de données du registre de conteneurs.

## Créer une base de données de métadonnées externe {#create-an-external-metadata-database}

En production, vous devez créer une base de données de métadonnées externe.

Prérequis :

- Configurez un [serveur PostgreSQL externe](../../advanced/external-db/_index.md).

Après avoir configuré le serveur PostgreSQL externe :

1. Créez un secret pour le mot de passe de la base de données de métadonnées :

   ```shell
   kubectl create secret generic RELEASE_NAME-registry-database-password --from-literal=password=<your_registry_password>
   ```

1. Connectez-vous à votre serveur de base de données.
1. Utilisez les commandes SQL suivantes pour créer l'utilisateur et la base de données :

   ```sql
   -- Create the registry user
   CREATE USER registry WITH PASSWORD '<your_registry_password>';

   -- Create the registry database
   CREATE DATABASE registry OWNER registry;
   ```

1. Pour les services gérés dans le cloud, accordez des rôles supplémentaires selon les besoins :

   {{< tabs >}}

   {{< tab title="Amazon RDS" >}}

   ```sql
   GRANT rds_superuser TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Azure database" >}}

   ```sql
   GRANT azure_pg_admin TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Google Cloud SQL" >}}

   ```sql
   GRANT cloudsqlsuperuser TO registry;
   ```

   {{< /tab >}}

   {{< /tabs >}}

## Créer une base de données de métadonnées intégrée {#create-a-built-in-metadata-database}

> [!warning]
> Vous pouvez utiliser la base de données de métadonnées cloud native intégrée à des fins d'évaluation uniquement. Vous ne devez pas l'utiliser en production.

## Activer la base de données de métadonnées {#enable-the-metadata-database}

Après avoir créé la base de données, activez-la. Des étapes supplémentaires sont requises lors de la migration d'un registre de conteneurs existant.

### Prérequis {#prerequisites}

Prérequis :

- GitLab 17.3 ou version ultérieure.
- Un déploiement de la [version requise de PostgreSQL](https://docs.gitlab.com/install/requirements/#postgresql), accessible depuis les pods de registre.
- Accès au cluster Kubernetes et au déploiement Helm en local.
- Accès SSH aux pods de registre.

Lisez également la section [avant de commencer](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#before-you-start) du guide d'administration du registre.

> [!note]
> Pour obtenir la liste des durées d'importation pour divers registres de test et d'utilisateurs, consultez [ce tableau dans le ticket 423459](https://gitlab.com/gitlab-org/gitlab/-/issues/423459#completed-tests-and-user-reports). Votre déploiement de registre est unique et vos durées d'importation pourraient être plus longues que celles signalées dans le ticket.

### Activer pour les nouveaux registres {#enable-for-new-registries}

Pour activer la base de données pour un nouveau registre de conteneurs :

1. Obtenez les valeurs Helm actuelles pour votre release et enregistrez-les dans un fichier. Par exemple, pour une release nommée `gitlab` et un fichier nommé `values.yml` :

   ```shell
   helm get values gitlab > values.yml
   ```

1. Ajoutez les lignes suivantes à votre fichier `values.yml` :

   ```yaml
   registry:
     enabled: true
     database:
       enabled: true
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full
       # these settings are inherited from `global.psql.ssl`
       ssl:
         secret: gitlab-registry-postgresql-ssl # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. Facultatif. Vérifiez que les migrations de schéma ont été appliquées correctement. Vous pouvez :

   - Consulter la sortie du journal du job de migrations, par exemple :

     ```shell
     kubectl logs jobs/gitlab-registry-migrations-1
     ...
     OK: applied 154 migrations in 13.752s
     ```

   - Ou bien, connectez-vous à la base de données Postgres et interrogez la table `schema_migrations` :

     ```sql
     SELECT * FROM schema_migrations;
     ```

     Assurez-vous que l'horodatage de la colonne `applied_at` est renseigné pour toutes les lignes.

Le registre est prêt à utiliser la base de données de métadonnées !

### Activer et importer les registres existants {#enable-for-and-import-existing-registries}

Vous pouvez importer les données de votre registre de conteneurs existant en une ou trois étapes. Quelques facteurs influent sur la durée de la migration :

- La taille de vos données de registre existantes.
- Les spécifications de votre instance PostgresSQL.
- Le nombre de pods de registre en cours d'exécution dans votre cluster.
- La latence réseau entre le registre, PostgresSQL et votre stockage d'objets configuré.

> [!note]
> Les travaux d'automatisation du processus d'importation sont suivis dans le ticket [5293](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5293).

Avant de tenter l'importation en une ou trois étapes, obtenez les valeurs Helm actuelles pour votre release et enregistrez-les dans un fichier. Par exemple, pour une release nommée `gitlab` et un fichier nommé `values.yml` :

```shell
helm get values gitlab > values.yml
```

#### Importer en une étape {#import-in-one-step}

Lors d'une importation en une étape, tenez compte des points suivants :

- Le registre doit rester en mode `read-only` pendant l'importation.
- Si le pod sur lequel l'importation est en cours d'exécution est arrêté, vous pouvez reprendre l'importation sans recommencer depuis le début. Voir [Reprendre les importations interrompues](#resume-interrupted-imports).

Pour importer un registre de conteneurs existant dans la base de données de métadonnées en une étape :

1. Trouvez la section `registry:` dans le fichier `values.yml` et ajoutez la section `database`. Définissez :
   - `database.configure` sur `true`.
   - `database.enabled` sur `false`.
   - `maintenance.readonly.enabled` sur `true`.
   - `migrations.enabled` sur `true`.

   ```yaml
   registry:
     enabled: true
     maintenance:
       readonly:
         enabled: true  # must remain set to true while the migration is executed
     database:
       configure: true  # must be true for the migration step
       enabled: false  # must be false!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. Mettez à niveau votre installation Helm pour appliquer les modifications dans votre déploiement :

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. Connectez-vous à l'un des pods de registre via SSH, par exemple pour un pod nommé `gitlab-registry-5ddcd9f486-bvb57` :

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. Accédez au répertoire personnel, puis exécutez la commande suivante :

   ```shell
   cd ~
   /usr/bin/registry database import /etc/docker/registry/config.yml
   ```

1. Si la commande s'est terminée avec succès, toutes les images sont maintenant entièrement importées. Vous pouvez maintenant activer la base de données et désactiver le mode lecture seule dans la configuration :

   ```yaml
   registry:
     enabled: true
     maintenance:
       readonly:
         enabled: false
     database:
       configure: true  # once database.enabled is set to true, this option can be removed
       enabled: true
       name: registry
       user: registry
       password:
         secret: gitlab-registry-database-password
         key: password
       migrations:
         enabled: true
   ```

1. Mettez à niveau votre installation Helm pour appliquer les modifications dans votre déploiement :

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

Vous pouvez maintenant utiliser la base de données de métadonnées pour toutes les opérations !

#### Importer en trois étapes {#import-in-three-steps}

Vous pouvez importer les données d'un registre de conteneurs existant dans la base de données de métadonnées en trois étapes distinctes, ce qui est recommandé si :

- Le registre contient une grande quantité de données.
- Vous devez minimiser les interruptions de service pendant la migration.

Pour importer en trois étapes, vous devez :

1. Pré-importer les dépôts
1. Importer toutes les données de dépôt
1. Importer les blobs communs

> [!note]
> Des utilisateurs ont signalé que l'importation de la première étape s'est effectuée à [des débits de 2 à 4 To par heure](https://gitlab.com/gitlab-org/gitlab/-/issues/423459). À la vitesse la plus lente, les registres de plus de 100 To de données pourraient prendre plus de 48 heures.

##### Étape 1. Pré-importer les dépôts {#step-1-pre-import-repositories}

Pour les instances de grande taille, ce processus peut prendre des heures voire des jours, selon la taille de votre registre. Vous pouvez continuer à utiliser le registre pendant ce processus.

> [!note]
> Si l'importation est interrompue, vous pouvez la reprendre sans recommencer depuis le début. Voir [Reprendre les importations interrompues](#resume-interrupted-imports).

1. Trouvez la section `registry:` dans le fichier `values.yml` et ajoutez la section `database`. Définissez :
   - `database.configure` sur `true`.
   - `database.enabled` sur `false`.
   - `migrations.enabled` sur `true`.

   ```yaml
   registry:
     enabled: true
     database:
       configure: true
       enabled: false  # must be false!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. Enregistrez le fichier et mettez à niveau votre installation Helm pour appliquer les modifications dans votre déploiement :

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. Connectez-vous à l'un des pods de registre via SSH. Par exemple, pour un pod nommé `gitlab-registry-5ddcd9f486-bvb57` :

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. Accédez au répertoire personnel, puis exécutez la commande suivante :

   ```shell
   cd ~
   /usr/bin/registry database import --step-one /etc/docker/registry/config.yml
   ```

La première étape est terminée lorsque `registry import complete` s'affiche.

> [!note]
> Vous devriez essayer de planifier l'étape suivante dès que possible afin de réduire la durée d'interruption de service requise. Idéalement, moins d'une semaine après la fin de la première étape. Toute nouvelle donnée écrite dans le registre avant l'étape suivante allongera la durée de cette étape.

##### Étape 2. Importer toutes les données de dépôt {#step-2-import-all-repository-data}

Cette étape nécessite que le registre soit défini en mode `read-only`. Prévoyez suffisamment de temps pour l'interruption de service lors de ce processus.

1. Définissez le registre en mode `read-only` dans votre fichier `values.yml` :

   ```yaml
   registry:
     enabled: true
     maintenance:
       readonly:
         enabled: true   # must be true!
     database:
       configure: true
       enabled: false  # must be false!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. Enregistrez le fichier et mettez à niveau votre installation Helm pour appliquer les modifications dans votre déploiement :

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. Connectez-vous à l'un des pods de registre via SSH. Par exemple, pour un pod nommé `gitlab-registry-5ddcd9f486-bvb57` :

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. Accédez au répertoire personnel, puis exécutez la commande suivante :

   ```shell
   cd ~
   /usr/bin/registry database import --step-two /etc/docker/registry/config.yml
   ```

1. Si la commande s'est terminée avec succès, toutes les images sont maintenant entièrement importées. Vous pouvez maintenant activer la base de données et désactiver le mode lecture seule dans la configuration :

   ```yaml
   registry:
     enabled: true
     maintenance:        # this section can be removed
       readonly:
         enabled: false
     database:
       configure: true  # once database.enabled is set to true, this option can be removed
       enabled: true   # must be true!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. Enregistrez le fichier et mettez à niveau votre installation Helm pour appliquer les modifications dans votre déploiement :

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

Vous pouvez maintenant utiliser la base de données de métadonnées pour toutes les opérations !

##### Étape 3. Importer les blobs communs {#step-3-import-common-blobs}

Le registre utilise désormais entièrement la base de données pour ses métadonnées, mais il n'a pas encore accès aux blobs de couche potentiellement inutilisés.

Pour terminer le processus, exécutez la dernière étape de la migration :

```shell
cd ~
/usr/bin/registry database import --step-three /etc/docker/registry/config.yml
```

Une fois la commande terminée avec succès, le registre est maintenant entièrement migré vers la base de données !

#### Reprendre les importations interrompues {#resume-interrupted-imports}

{{< history >}}

- [Introduite](https://gitlab.com/gitlab-org/container-registry/-/issues/1162) dans GitLab 18.5.

{{< /history >}}

Si une importation est interrompue, la réexécution de la commande d'importation ignore automatiquement les dépôts qui ont été pré-importés au cours des 72 dernières heures. L'indicateur `--pre-import-skip-recent` contrôle cette durée.

Pour personnaliser la durée d'omission, ajoutez `--pre-import-skip-recent` à votre commande d'importation (fonctionne avec n'importe quelle variante d'importation, y compris `--step-one`, `--step-two`, `--step-three`, ou une importation en une étape) :

- Ignorer les dépôts importés au cours des 6 dernières heures :

  ```shell
  /usr/bin/registry database import --pre-import-skip-recent 6h /etc/docker/registry/config.yml
  ```

- Désactiver l'omission (tout réimporter) :

  ```shell
  /usr/bin/registry database import --pre-import-skip-recent 0 /etc/docker/registry/config.yml
  ```

Pour les unités de durée valides, consultez [les chaînes de durée Go](https://pkg.go.dev/time#ParseDuration).

## Sauvegarde et restauration {#backup-and-restore}

Pour inclure la base de données de métadonnées du registre dans les opérations de sauvegarde et de restauration de Toolbox, configurez le chart Toolbox avec les identifiants de la base de données du registre. Consultez la section [identifiants de la base de données de métadonnées du registre](../gitlab/toolbox/_index.md#registry-metadata-database-credentials) dans la documentation du chart Toolbox.

## Migrations de base de données {#database-migrations}

Le registre de conteneurs prend en charge deux types de migrations :

- **Regular schema migrations** :  Modifications apportées à la structure de la base de données qui doivent être exécutées avant le déploiement du nouveau code applicatif. Elles doivent être rapides pour éviter les retards de déploiement.
- **Post-deployment migrations** :  Modifications apportées à la structure de la base de données qui peuvent être exécutées pendant que l'application est en cours d'exécution. Utilisées pour des opérations plus longues telles que la création d'index sur des tables volumineuses, afin d'éviter les délais de démarrage et les longues interruptions lors des mises à niveau.

### Appliquer les migrations de base de données {#apply-database-migrations}

Par défaut, le chart de registre applique automatiquement les migrations de schéma régulières et les migrations post-déploiement si `database.migrations.enabled` est défini sur `true`.

Pour réduire les interruptions de service lors des mises à niveau, vous pouvez ignorer les migrations post-déploiement et les appliquer manuellement après le démarrage de l'application :

1. Définissez la variable d'environnement `SKIP_POST_DEPLOYMENT_MIGRATIONS` sur `true` en utilisant `ExtraEnv` pour le déploiement du registre :

   ```yaml
   registry:
     extraEnv:
       SKIP_POST_DEPLOYMENT_MIGRATIONS: true
   ```

1. Après la mise à niveau, [connectez-vous à un pod de registre](_index.md#running-administrative-commands-against-the-container-registry).
1. Appliquez les migrations post-déploiement en attente :

   ```shell
   registry database migrate up /etc/docker/registry/config.yml
   ```

> [!note]
> La commande `migrate up` propose des indicateurs supplémentaires qui peuvent être utilisés pour contrôler la façon dont les migrations sont appliquées. Exécutez `registry database migrate up --help` pour plus de détails.

## Dépannage {#troubleshooting}

### Erreur : `panic: interface conversion: interface {} is nil, not bool` {#error-panic-interface-conversion-interface--is-nil-not-bool}

Lors de l'importation de registres existants, vous pourriez voir cette erreur :

```shell
panic: interface conversion: interface {} is nil, not bool
```

Il s'agit d'un ticket [connu](https://gitlab.com/gitlab-org/container-registry/-/merge_requests/2041) qui est corrigé dans la version de registre `v4.15.2-gitlab` et dans GitLab 17.9 et versions ultérieures.

Pour contourner ce problème, mettez à niveau la version de votre registre :

1. Dans votre fichier `values.yml`, définissez le tag d'image du registre :

   ```yaml
   registry:
     image:
       tag: v4.15.2-gitlab
   ```

1. Mettez à niveau votre installation Helm :

   ```shell
   helm upgrade gitlab -f values.yml
   ```

Vous pouvez également mettre à jour manuellement la configuration du registre :

- Dans `/etc/docker/registry/config.yml`, définissez `parallelwalk` sur `false` pour votre fournisseur de stockage. Par exemple, avec S3 :

  ```yaml
  storage:
    s3:
      parallelwalk: false
  ```
