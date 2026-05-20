---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer le chart GitLab avec une base de données externe
---

Configurez le chart Helm GitLab avec une instance PostgreSQL externe, requise pour tous les déploiements.

Prérequis :

- Un déploiement de la [version requise de PostgreSQL](https://docs.gitlab.com/install/requirements/#postgresql). Si vous n'en avez pas, envisagez une solution cloud comme [AWS RDS PostgreSQL](https://aws.amazon.com/rds/postgresql/) ou [GCP Cloud SQL](https://cloud.google.com/sql/). Pour une solution alternative, envisagez [le package Linux](external-omnibus-psql.md).
- Une base de données vide nommée `gitlabhq_production` par défaut.
- Un utilisateur disposant d'un accès complet à la base de données. Consultez la [documentation sur les bases de données externes](https://docs.gitlab.com/administration/postgresql/external/) pour plus de détails.
- Un [Secret Kubernetes](https://kubernetes.io/docs/concepts/configuration/secret/) contenant le mot de passe de l'utilisateur de la base de données.
- Les [extensions `amcheck`, `pg_trgm` et `btree_gist`](https://docs.gitlab.com/install/postgresql_extensions/). Si vous ne fournissez pas à GitLab un compte avec l'indicateur Superuser, assurez-vous que ces extensions sont chargées avant de procéder à l'installation de la base de données.

Prérequis réseau :

- Assurez-vous que la base de données est accessible depuis le cluster. Vérifiez que vos politiques de pare-feu autorisent le trafic.
- Si vous prévoyez d'utiliser PostgreSQL comme cluster d'équilibrage de charge et le DNS Kubernetes pour la découverte de services, configurez le service secondaire PostgreSQL comme un service sans en-tête (headless) afin de permettre la création d'enregistrements DNS `A` pour chaque instance secondaire. Pour un exemple, consultez [`examples/database/values-loadbalancing-discover.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/database/values-loadbalancing-discover.yaml).

Pour configurer le chart GitLab afin d'utiliser une base de données externe :

1. Définissez les paramètres suivants :

   - `global.psql.host` : À définir avec le nom d'hôte de la base de données externe ; il peut s'agir d'un domaine ou d'une adresse IP.
   - `global.psql.password.secret` : Le nom du [secret contenant le mot de passe de la base de données pour l'utilisateur `gitlab`](../../installation/secrets.md#postgresql-password).
   - `global.psql.password.key` : Dans le secret, la clé qui contient le mot de passe.

1. Facultatif. Les éléments suivants peuvent être personnalisés davantage si vous n'utilisez pas les valeurs par défaut :

   - `global.psql.port` : Le port sur lequel la base de données est disponible. La valeur par défaut est `5432`.
   - `global.psql.database` : Le nom de la base de données.
   - `global.psql.username` : L'utilisateur ayant accès à la base de données.

1. Facultatif. Si vous utilisez une connexion TLS mutuelle à la base de données, définissez les paramètres suivants :

   - `global.psql.ssl.secret` : Un secret contenant le certificat client, la clé et l'autorité de certification.
   - `global.psql.ssl.serverCA` : Dans le secret, la clé qui fait référence à l'autorité de certification (CA).
   - `global.psql.ssl.clientCertificate` : Dans le secret, la clé qui fait référence au certificat client.
   - `global.psql.ssl.clientKey` : Dans le secret, le client.

1. Lorsque vous déployez le chart GitLab, ajoutez les valeurs en utilisant l'option `--set`. Par exemple :

   ```shell
   helm install gitlab gitlab/gitlab
     --set global.psql.host=psql.example
     --set global.psql.password.secret=gitlab-postgresql-password
     --set global.psql.password.key=postgres-password
   ```
