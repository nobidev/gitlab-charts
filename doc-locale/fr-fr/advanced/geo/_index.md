---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer le chart GitLab avec GitLab Geo
---

GitLab Geo offre la possibilité d'avoir des déploiements d'applications géographiquement distribués.

Bien que des services de base de données externes puissent être utilisés, ces documents se concentrent sur l'utilisation du [package Linux](https://docs.gitlab.com/omnibus/) pour PostgreSQL afin de fournir le guide le plus agnostique en termes de plateforme, et tirent parti de l'automatisation incluse dans `gitlab-ctl`.

Dans ce guide, les deux clusters ont la même URL externe. Cette fonctionnalité est prise en charge par le chart depuis la version 7.3. Voir [Configurer une URL unifiée pour les sites Geo](https://docs.gitlab.com/administration/geo/secondary_proxy/#set-up-a-unified-url-for-geo-sites). Vous pouvez éventuellement [configurer une URL distincte pour le site secondaire](#configure-a-separate-url-for-the-secondary-site-optional).

Pour les problèmes connus, consultez la [documentation Geo](https://docs.gitlab.com/administration/geo/#known-issues).

> [!note]
> Consultez les [termes définis](https://docs.gitlab.com/administration/geo/glossary/) pour décrire tous les aspects de Geo (principalement la distinction entre `site` et `node`).

## Prérequis {#requirements}

Pour utiliser GitLab Geo avec le chart Helm GitLab, les prérequis suivants doivent être satisfaits :

- L'utilisation de services [PostgreSQL externes](../external-db/_index.md), car le PostgreSQL inclus avec le chart n'est pas exposé aux réseaux extérieurs et ne dispose pas du support WAL requis pour la réplication.
- La base de données fournie doit :
  - Prendre en charge la réplication.
  - La base de données primaire doit être accessible par le site primaire et tous les nœuds de base de données secondaires (pour la réplication).
  - Les bases de données secondaires n'ont besoin d'être accessibles que par les sites secondaires.
  - Prendre en charge SSL entre les nœuds de base de données primaires et secondaires.
- Le site primaire doit être accessible via HTTP(S) par tous les sites secondaires. Les sites secondaires doivent être accessibles au site primaire via HTTP(S).
- Consultez les [prérequis pour l'exécution de Geo](https://docs.gitlab.com/administration/geo/#requirements-for-running-geo) pour la liste complète des prérequis.

## Vue d'ensemble {#overview}

Ce guide utilise 2 nœuds de base de données créés avec le package Linux, en configurant uniquement les services PostgreSQL nécessaires, et 2 déploiements du chart Helm GitLab. Il est destiné à être la configuration _minimale_ requise. Cette documentation ne couvre pas SSL entre l'application et la base de données, la prise en charge d'autres fournisseurs de bases de données, ni la [promotion d'un site secondaire en site primaire](https://docs.gitlab.com/administration/geo/disaster_recovery/).

Le plan ci-dessous doit être suivi dans l'ordre :

1. [Configurer les nœuds de base de données du package Linux](#set-up-linux-package-database-nodes)
1. [Configurer les clusters Kubernetes](#set-up-kubernetes-clusters)
1. [Collecter les informations](#collect-information)
1. [Configurer la base de données primaire](#configure-primary-database)
1. [Déployer le chart en tant que site Geo primaire](#deploy-chart-as-geo-primary-site)
1. [Définir le site Geo primaire](#set-the-geo-primary-site)
1. [Configurer la base de données secondaire](#configure-secondary-database)
1. [Copier les secrets du site primaire vers le site secondaire](#copy-secrets-from-the-primary-site-to-the-secondary-site)
1. [Déployer le chart en tant que site Geo secondaire](#deploy-chart-as-geo-secondary-site)
1. [Ajouter le site Geo secondaire via le site primaire](#add-secondary-geo-site-via-primary)
1. [Confirmer le statut opérationnel](#confirm-operational-status)
1. [Configurer une URL distincte pour le site secondaire (Optionnel)](#configure-a-separate-url-for-the-secondary-site-optional)
1. [Registry](#registry)
1. [Cert-manager et URL unifiée](#cert-manager-and-unified-url)

## Configurer les nœuds de base de données du package Linux {#set-up-linux-package-database-nodes}

Pour ce processus, deux nœuds sont nécessaires. L'un est le nœud de base de données primaire, l'autre le nœud de base de données secondaire. Vous pouvez utiliser n'importe quel fournisseur d'infrastructure machine, sur site ou chez un fournisseur cloud.

Gardez à l'esprit que la communication est nécessaire :

- Entre les deux nœuds de base de données pour la réplication.
- Entre chaque nœud de base de données et leurs déploiements Kubernetes respectifs :
  - Le nœud primaire doit exposer le port TCP `5432`.
  - Le nœud secondaire doit exposer les ports TCP `5432` & `5431`.

Installez un [système d'exploitation pris en charge par le package Linux](https://docs.gitlab.com/install/requirements/#operating-systems), puis [installez le package Linux](https://about.gitlab.com/install/) dessus. Ne fournissez pas la variable d'environnement `EXTERNAL_URL` lors de l'installation, car nous fournirons un fichier de configuration minimal avant de reconfigurer le package.

Après avoir installé le système d'exploitation et le package GitLab, la configuration peut être créée pour les services qui seront utilisés. Avant de faire cela, des informations doivent être collectées.

## Configurer les clusters Kubernetes {#set-up-kubernetes-clusters}

Pour ce processus, deux clusters Kubernetes doivent être utilisés. Ceux-ci peuvent provenir de n'importe quel fournisseur, sur site ou chez un fournisseur cloud.

Gardez à l'esprit que la communication est nécessaire :

- Vers les nœuds de base de données respectifs :
  - Sortant primaire vers TCP `5432`.
  - Sortant secondaire vers TCP `5432` et `5431`.
- Entre les deux Ingress Kubernetes via HTTPS.

Chaque cluster provisionné doit disposer de :

- Suffisamment de ressources pour prendre en charge une installation de base de ces charts.
- Accès au stockage persistant :
  - MinIO n'est pas requis si vous utilisez le [stockage d'objets externe](../external-object-storage/_index.md).
  - Gitaly n'est pas requis si vous utilisez [Gitaly externe](../external-gitaly/_index.md).
  - Redis n'est pas requis si vous utilisez [Redis externe](../external-redis/_index.md).

## Collecter les informations {#collect-information}

Pour poursuivre la configuration, les informations suivantes doivent être collectées à partir des différentes sources. Collectez-les et prenez des notes pour les utiliser tout au long de cette documentation.

- Base de données primaire :
  - Adresse IP
  - nom d'hôte (optionnel)
- Base de données secondaire :
  - Adresse IP
  - nom d'hôte (optionnel)
- Cluster primaire :
  - URL externe
  - URL interne
  - Adresses IP des nœuds
- Cluster secondaire :
  - URL interne
  - Adresses IP des nœuds
- Mots de passe de la base de données (_les mots de passe doivent être décidés à l'avance_) :
  - `gitlab` (utilisé dans `postgresql['sql_user_password']`, `global.psql.password`)
  - `gitlab_geo` (utilisé dans `geo_postgresql['sql_user_password']`, `global.geo.psql.password`)
  - `gitlab_replicator` (nécessaire pour la réplication)
- Votre fichier de licence GitLab

L'URL interne de chaque cluster doit être unique au cluster, afin que tous les clusters puissent envoyer des requêtes à tous les autres clusters. Par exemple :

- URL externe de tous les clusters : `https://gitlab.example.com`
- URL interne du cluster primaire : `https://london.gitlab.example.com`
- URL interne du cluster secondaire : `https://shanghai.gitlab.example.com`

Ce guide ne couvre pas la configuration du DNS.

Les mots de passe des utilisateurs de base de données `gitlab` et `gitlab_geo` doivent exister sous deux formes : mot de passe brut et mot de passe haché PostgreSQL. Pour obtenir la forme hachée, exécutez les commandes suivantes sur l'une des instances d'installation du package Linux, qui vous demande de saisir et confirmer le mot de passe avant d'afficher une valeur de hachage appropriée à noter.

1. `gitlab-ctl pg-password-md5 gitlab`
1. `gitlab-ctl pg-password-md5 gitlab_geo`

## Configurer la base de données primaire {#configure-primary-database}

_Cette section est effectuée sur le nœud de base de données d'installation du package Linux primaire._

Pour configurer l'installation du package Linux du nœud de base de données primaire, utilisez cet exemple de configuration :

```ruby
### Geo Primary
external_url 'http://gitlab.example.com'
roles ['geo_primary_role']
# The unique identifier for the Geo node.
gitlab_rails['geo_node_name'] = 'London Office'
# Allow cross-site origins for ActionCable requests.
gitlab_rails['action_cable_allowed_origins'] = ['https://gitlab.example.com']
gitlab_rails['auto_migrate'] = false
## turn off everything but the DB
sidekiq['enable']=false
puma['enable']=false
gitlab_workhorse['enable']=false
nginx['enable']=false
geo_logcursor['enable']=false
gitaly['enable']=false
redis['enable']=false
gitlab_kas['enable']=false
prometheus_monitoring['enable'] = false
## Configure the DB for network
postgresql['enable'] = true
postgresql['listen_address'] = '0.0.0.0'
postgresql['sql_user_password'] = 'gitlab_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - primary application deployment
# - secondary database node(s)
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
```

Nous devons remplacer plusieurs éléments :

- `external_url` doit être mis à jour pour refléter le nom d'hôte de notre site primaire.
- `gitlab_rails['geo_node_name']` doit être remplacé par un nom unique pour votre site. Consultez le champ Nom dans [Paramètres communs](https://docs.gitlab.com/administration/geo_sites/#common-settings).
- `gitlab_rails['action_cable_allowed_origins']` doit être remplacé par un tableau contenant les **external URLs** de tous les clusters : primaires et secondaires, ou leur URL unifiée s'ils ont la même URL externe.
- `gitlab_user_password_hash` doit être remplacé par la forme hachée du mot de passe `gitlab`.
- `postgresql['md5_auth_cidr_addresses']` peut être mis à jour pour être une liste d'adresses IP explicites ou de blocs d'adresses en notation CIDR.

Le `md5_auth_cidr_addresses` doit être sous la forme `[ '127.0.0.1/24', '10.41.0.0/16']`. Il est important d'inclure `127.0.0.1` dans cette liste, car l'automatisation du package Linux se connecte en utilisant cette adresse. Les adresses de cette liste doivent inclure l'adresse IP (pas le nom d'hôte) de votre base de données secondaire et tous les nœuds de votre cluster Kubernetes primaire. Ceci _peut_ être laissé comme `['0.0.0.0/0']`, cependant _ce n'est pas la meilleure pratique_.

Une fois la configuration ci-dessus préparée :

1. Placez le contenu dans `/etc/gitlab/gitlab.rb`
1. Exécutez `gitlab-ctl reconfigure`. Si vous rencontrez des problèmes concernant le service qui n'écoute pas sur TCP, essayez de le redémarrer directement avec `gitlab-ctl restart postgresql`.
1. Exécutez `gitlab-ctl set-replication-password` pour définir le mot de passe de l'utilisateur `gitlab_replicator`.
1. Récupérez le certificat public du nœud de base de données primaire, cela est nécessaire pour que la base de données secondaire puisse répliquer (sauvegardez cette sortie) :

   ```shell
   cat ~gitlab-psql/data/server.crt
   ```

## Déployer le chart en tant que site Geo primaire {#deploy-chart-as-geo-primary-site}

_Cette section est effectuée sur le cluster Kubernetes du site primaire._

Pour déployer ce chart en tant que Geo primaire, commencez [à partir de cet exemple de configuration](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml) :

1. Créez un secret contenant le mot de passe de la base de données que le chart doit utiliser. Remplacez `PASSWORD` ci-dessous par le mot de passe de l'utilisateur de base de données `gitlab` :

   ```shell
   kubectl --namespace gitlab create secret generic geo --from-literal=postgresql-password=PASSWORD
   ```

1. Créez un fichier `primary.yaml` basé sur l'[exemple de configuration](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml) et mettez à jour la configuration pour refléter les valeurs correctes :

   ```yaml
   ### Geo Primary
   global:
     # See docs.gitlab.com/charts/charts/globals
     # Configure host & domain
     hosts:
       domain: example.com
       # optionally configure a static IP for the default LoadBalancer
       # externalIP:
       # optionally configure a static IP for the Geo LoadBalancer
       # externalGeoIP:
     # configure DB connection
     psql:
       host: geo-1.db.example.com
       port: 5432
       password:
         secret: geo
         key: postgresql-password
     # configure geo (primary)
     geo:
       nodeName: London Office
       enabled: true
       role: primary
   ```

   <!-- markdownlint-disable MD044 -->
   - [`global.hosts.domain`](../../charts/globals.md#configure-host-settings)
   - [`global.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - `global.geo.nodeName` doit correspondre au [champ Nom d'un site Geo dans la zone d'administration](https://docs.gitlab.com/administration/geo_sites/#common-settings)
   - Configurez également tous les paramètres supplémentaires, tels que :
     - [Configuration de SSL/TLS](../../installation/tools.md#tls-certificates)
     - [Utilisation de Redis externe](../external-redis/_index.md)
     - [utilisation du stockage d'objets externe](../external-object-storage/_index.md)
   <!-- markdownlint-enable MD044 -->

1. Ajoutez la configuration Ingress ou Gateway API nécessaire à votre `primary.yaml`.

   {{< tabs >}}

   {{< tab title="NGINX Ingress" >}}

   Configurez un contrôleur NGINX supplémentaire et un Ingress webservice supplémentaire pour le trafic Geo interne (inter-sites) :

   ```yaml
   # Configure Geo Nginx Controller for internal Geo site traffic
   nginx-ingress-geo:
     enabled: true
   gitlab:
     webservice:
       # Use the Geo NGINX controller.
       ingress:
         useGeoClass: true
       # Configure an Ingress for internal Geo traffic
       extraIngress:
         enabled: true
         hostname: gitlab.london.example.com
         useGeoClass: true
   ```

   {{< /tab >}}

   {{< tab title="Envoy Gateway" >}}

   En alternative à l'approche basée sur NGINX Ingress, vous pouvez exposer Geo en [configurant l'API Gateway](../../charts/globals.md#gateway-api) et le [Envoy Gateway](../../charts/envoygateway/_index.md) intégré.

   Après avoir activé l'API Gateway, configurez le nom d'hôte pour le trafic Geo interne :

   ```yaml
   global:
     geo:
       gatewayApi:
         additionalHostname: gitlab.london.example.com
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Déployez le chart en utilisant cette configuration :

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f primary.yaml
   ```

   > [!note]
   > Cela suppose que vous utilisez l'espace de nommage `gitlab`. Si vous souhaitez utiliser un espace de nommage différent, vous devez également le remplacer dans `--namespace gitlab` tout au long du reste de ce document.

1. Attendez que le déploiement soit terminé et que l'application soit en ligne. Lorsque l'application est accessible, connectez-vous.

1. Connectez-vous à GitLab et [activez votre abonnement GitLab](https://docs.gitlab.com/administration/license/). Cette étape est nécessaire au fonctionnement de Geo.

## Définir le site Geo primaire {#set-the-geo-primary-site}

Maintenant que le chart a été déployé et qu'une licence a été téléchargée, nous pouvons configurer ceci comme site primaire. Nous allons faire cela via le Pod Toolbox.

1. Trouvez le Pod Toolbox

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. Exécutez `gitlab-rake geo:set_primary_node` avec `kubectl exec` :

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake geo:set_primary_node
   ```

1. Définissez l'URL interne du site primaire avec une commande Rails runner. Remplacez `https://primary.gitlab.example.com` par l'URL interne réelle :

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rails runner "GeoNode.primary_node.update!(internal_url: 'https://primary.gitlab.example.com')"
   ```

1. Vérifiez le statut de la configuration Geo :

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake gitlab:geo:check
   ```

   Vous devriez voir une sortie similaire à celle ci-dessous :

   ```plaintext
   WARNING: This version of GitLab depends on gitlab-shell 10.2.0, but you're running Unknown. Please update gitlab-shell.
   Checking Geo ...

   GitLab Geo is available ... yes
   GitLab Geo is enabled ... yes
   GitLab Geo secondary database is correctly configured ... not a secondary node
   Database replication enabled? ... not a secondary node
   Database replication working? ... not a secondary node
   GitLab Geo HTTP(S) connectivity ... not a secondary node
   HTTP/HTTPS repository cloning is enabled ... yes
   Machine clock is synchronized ... Exception: getaddrinfo: Servname not supported for ai_socktype
   Git user has default SSH configuration? ... yes
   OpenSSH configured to use AuthorizedKeysCommand ... no
     Reason:
     Cannot find OpenSSH configuration file at: /assets/sshd_config
     Try fixing it:
     If you are not using our official docker containers,
     make sure you have OpenSSH server installed and configured correctly on this system
     For more information see:
     doc/administration/operations/fast_ssh_key_lookup.md
   GitLab configured to disable writing to authorized_keys file ... yes
   GitLab configured to store new projects in hashed storage? ... yes
   All projects are in hashed storage? ... yes

   Checking Geo ... Finished
   ```

   - Ne vous inquiétez pas de `Exception: getaddrinfo: Servname not supported for ai_socktype`, car les conteneurs Kubernetes n'ont pas accès à l'horloge de l'hôte. _C'est normal_.
   - `OpenSSH configured to use AuthorizedKeysCommand ... no` _est attendu_. Cette tâche Rake vérifie la présence d'un serveur SSH local, qui est en réalité présent dans le chart `gitlab-shell`, déployé ailleurs et déjà configuré de manière appropriée.

## Configurer la base de données secondaire {#configure-secondary-database}

_Cette section est effectuée sur le nœud de base de données d'installation du package Linux secondaire._

Pour configurer l'installation du package Linux du nœud de base de données secondaire, utilisez cet exemple de configuration :

```ruby
### Geo Secondary
# external_url must match the Primary cluster's external_url
external_url 'http://gitlab.example.com'
roles ['geo_secondary_role']
gitlab_rails['enable'] = true
# The unique identifier for the Geo node.
gitlab_rails['geo_node_name'] = 'Shanghai Office'
gitlab_rails['auto_migrate'] = false
geo_secondary['auto_migrate'] = false
## turn off everything but the DB
sidekiq['enable']=false
puma['enable']=false
gitlab_workhorse['enable']=false
nginx['enable']=false
geo_logcursor['enable']=false
gitaly['enable']=false
redis['enable']=false
prometheus_monitoring['enable'] = false
gitlab_kas['enable']=false
## Configure the DBs for network
postgresql['enable'] = true
postgresql['listen_address'] = '0.0.0.0'
postgresql['sql_user_password'] = 'gitlab_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - secondary application deployment
# - secondary database node(s)
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
geo_postgresql['listen_address'] = '0.0.0.0'
geo_postgresql['sql_user_password'] = 'gitlab_geo_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - secondary application deployment
# - secondary database node(s)
geo_postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
gitlab_rails['db_password']='gitlab_user_password'
```

Nous devons remplacer plusieurs éléments :

- `gitlab_rails['geo_node_name']` doit être remplacé par un nom unique pour votre site. Consultez le champ Nom dans [Paramètres communs](https://docs.gitlab.com/administration/geo_sites/#common-settings).
- `gitlab_user_password_hash` doit être remplacé par la forme hachée du mot de passe `gitlab`.
- `postgresql['md5_auth_cidr_addresses']` doit être mis à jour pour être une liste d'adresses IP explicites ou de blocs d'adresses en notation CIDR.
- `gitlab_geo_user_password_hash` doit être remplacé par la forme hachée du mot de passe `gitlab_geo`.
- `geo_postgresql['md5_auth_cidr_addresses']` doit être mis à jour pour être une liste d'adresses IP explicites ou de blocs d'adresses en notation CIDR.
- `gitlab_user_password` doit être mis à jour et est utilisé ici pour permettre au package Linux d'automatiser la configuration PostgreSQL.

Le `md5_auth_cidr_addresses` doit être sous la forme `[ '127.0.0.1/24', '10.41.0.0/16']`. Il est important d'inclure `127.0.0.1` dans cette liste, car l'automatisation du package Linux se connecte en utilisant cette adresse. Les adresses de cette liste doivent inclure les adresses IP de tous les nœuds de votre cluster Kubernetes secondaire. Ceci _peut_ être laissé comme `['0.0.0.0/0']`, cependant _ce n'est pas la meilleure pratique_.

Une fois la configuration ci-dessus préparée :

1. Vérifiez la connectivité TCP au nœud PostgreSQL du site **principal** :

   ```shell
   openssl s_client -connect <primary_node_ip>:5432 </dev/null
   ```

   La sortie doit afficher ce qui suit :

   ```plaintext
   CONNECTED(00000003)
   write:errno=0
   ```

   Si cette étape échoue, vous utilisez peut-être la mauvaise adresse IP ou un pare-feu empêche l'accès au serveur. Vérifiez l'adresse IP en prêtant une attention particulière à la différence entre les adresses publiques et privées, et assurez-vous que, si un pare-feu est présent, le nœud PostgreSQL **secondaire** est autorisé à se connecter au nœud PostgreSQL **principal** sur le port TCP 5432.

1. Placez le contenu dans `/etc/gitlab/gitlab.rb`
1. Exécutez `gitlab-ctl reconfigure`. Si vous rencontrez des problèmes concernant le service qui n'écoute pas sur TCP, essayez de le redémarrer directement avec `gitlab-ctl restart postgresql`.
1. Placez le contenu du certificat du nœud PostgreSQL primaire ci-dessus dans `primary.crt`
1. Configurez la vérification TLS PostgreSQL sur le nœud PostgreSQL **secondaire** :

   Installez le fichier `primary.crt` :

   ```shell
   install \
      -D \
      -o gitlab-psql \
      -g gitlab-psql \
      -m 0400 \
      -T primary.crt ~gitlab-psql/.postgresql/root.crt
   ```

   PostgreSQL ne reconnaîtra désormais que ce certificat exact lors de la vérification des connexions TLS. Le certificat ne peut être répliqué que par quelqu'un ayant accès à la clé privée, qui est **only** présente sur le nœud PostgreSQL **principal**.

1. Testez que l'utilisateur `gitlab-psql` peut se connecter au PostgreSQL du site **principal** (le nom de base de données par défaut du package Linux est `gitlabhq_production`) :

   ```shell
   sudo \
      -u gitlab-psql /opt/gitlab/embedded/bin/psql \
      --list \
      -U gitlab_replicator \
      -d "dbname=gitlabhq_production sslmode=verify-ca" \
      -W \
      -h <primary_database_node_ip>
   ```

   Lorsque vous y êtes invité, saisissez le mot de passe collecté précédemment pour l'utilisateur `gitlab_replicator`. Si tout s'est passé correctement, vous devriez voir la liste des bases de données du nœud PostgreSQL **principal**.

   Un échec de connexion indique que la configuration TLS est incorrecte. Assurez-vous que le contenu de `~gitlab-psql/data/server.crt` sur le nœud PostgreSQL **principal** correspond au contenu de `~gitlab-psql/.postgresql/root.crt` sur le nœud PostgreSQL **secondaire**.

1. Répliquez les bases de données. Remplacez `PRIMARY_DATABASE_HOST` par l'IP ou le nom d'hôte de votre nœud PostgreSQL primaire :

   ```shell
   gitlab-ctl replicate-geo-database --slot-name=geo_2 --host=PRIMARY_DATABASE_HOST --sslmode=verify-ca
   ```

1. Une fois la réplication terminée, nous devons reconfigurer le package Linux une dernière fois pour s'assurer que `pg_hba.conf` est correct pour le nœud PostgreSQL secondaire :

   ```shell
   gitlab-ctl reconfigure
   ```

## Copier les secrets du site primaire vers le site secondaire {#copy-secrets-from-the-primary-site-to-the-secondary-site}

Copiez maintenant quelques secrets du déploiement Kubernetes du site primaire vers le déploiement Kubernetes du site secondaire :

- `gitlab-geo-gitlab-shell-host-keys`
- `gitlab-geo-rails-secret`
- `gitlab-geo-registry-secret`, si la réplication du Registry est activée.

1. Changez votre contexte `kubectl` vers celui de votre site primaire.
1. Collectez ces secrets depuis le déploiement primaire :

   ```shell
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-gitlab-shell-host-keys > ssh-host-keys.yaml
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-rails-secret > rails-secrets.yaml
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-registry-secret > registry-secrets.yaml
   ```

1. Changez votre contexte `kubectl` vers celui de votre site secondaire.
1. Appliquez ces secrets :

   ```shell
   kubectl --namespace gitlab apply -f ssh-host-keys.yaml
   kubectl --namespace gitlab apply -f rails-secrets.yaml
   kubectl --namespace gitlab apply -f registry-secrets.yaml
   ```

Créez ensuite un secret contenant les mots de passe de la base de données. Remplacez les mots de passe ci-dessous par les valeurs appropriées :

```shell
kubectl --namespace gitlab create secret generic geo \
   --from-literal=postgresql-password=gitlab_user_password \
   --from-literal=geo-postgresql-password=gitlab_geo_user_password
```

## Déployer le chart en tant que site Geo secondaire {#deploy-chart-as-geo-secondary-site}

_Cette section est effectuée sur le cluster Kubernetes du site secondaire._

Pour déployer ce chart en tant que site Geo secondaire, commencez [à partir de cet exemple de configuration](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/secondary.yaml).

1. Créez un fichier `secondary.yaml` basé sur l'[exemple de configuration](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/secondary.yaml) et mettez à jour la configuration pour refléter les valeurs correctes :

   ```yaml
   ## Geo Secondary
   global:
     # See docs.gitlab.com/charts/charts/globals
     # Configure host & domain
     hosts:
       domain: shanghai.example.com
       # use a unified URL (same external URL as the primary site)
       gitlab:
         name: gitlab.example.com
     # configure DB connection
     psql:
       host: geo-2.db.example.com
       port: 5432
       password:
         secret: geo
         key: postgresql-password
     # configure geo (secondary)
     geo:
       enabled: true
       role: secondary
       nodeName: Shanghai Office
       psql:
         host: geo-2.db.example.com
         port: 5431
         password:
           secret: geo
           key: geo-postgresql-password
   ```

   <!-- markdownlint-disable MD044 -->
   - [`global.hosts.domain`](../../charts/globals.md#configure-host-settings)
   - [`global.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - [`global.geo.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - `global.geo.nodeName` doit correspondre au [champ Nom d'un site Geo dans la zone d'administration](https://docs.gitlab.com/administration/geo_sites/#common-settings)
   - Définissez éventuellement `nginx-ingress-geo.enabled` pour activer un contrôleur d'ingress préconfiguré pour le trafic Geo interne. [Cela facilite la promotion du site en site primaire.](../../charts/nginx/_index.md#gitlab-geo).
   - Configurez également tous les paramètres supplémentaires, tels que :
     - [Configuration de SSL/TLS](../../installation/tools.md#tls-certificates)
     - [Utilisation de Redis externe](../external-redis/_index.md)
     - [utilisation du stockage d'objets externe](../external-object-storage/_index.md)
   - Pour les bases de données externes, `global.psql.host` est la base de données réplica secondaire en lecture seule, tandis que `global.geo.psql.host` est la base de données de suivi Geo
   <!-- markdownlint-enable MD044 -->

1. Ajoutez la configuration Ingress ou Gateway API nécessaire à votre `secondary.yaml`.

   {{< tabs >}}

   {{< tab title="NGINX Ingress" >}}

   Activez éventuellement un contrôleur NGINX supplémentaire et configurez un Ingress webservice supplémentaire pour le trafic Geo interne :

   ```yaml
   # Optional for secondary sites: Configure Geo Nginx Controller for internal Geo site traffic.
   # nginx-ingress-geo:
   #   enabled: true
   gitlab:
     webservice:
       # Configure an Ingress for internal Geo traffic
       extraIngress:
         enabled: true
         hostname: shanghai.gitlab.example.com
         useGeoClass: false # Set to true if Geo NGINX Ingress is enabled.
   ```

   {{< /tab >}}

   {{< tab title="Envoy Gateway" >}}

   En alternative à l'approche basée sur NGINX Ingress, vous pouvez exposer Geo en [configurant l'API Gateway](../../charts/globals.md#gateway-api) et le [Envoy Gateway](../../charts/envoygateway/_index.md) intégré.

   Après avoir activé l'API Gateway, configurez le nom d'hôte pour le trafic Geo interne :

   ```yaml
   global:
     geo:
       gatewayApi:
         additionalHostname: shanghai.gitlab.example.com
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. Déployez le chart en utilisant cette configuration :

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f secondary.yaml
   ```

1. Attendez que le déploiement soit terminé et que l'application soit en ligne.

## Ajouter le site Geo secondaire via le site primaire {#add-secondary-geo-site-via-primary}

Maintenant que les deux bases de données sont configurées et que les applications sont déployées, nous devons informer le site primaire de l'existence du site secondaire :

1. Visitez le site **principal**.
1. Dans le coin supérieur droit, sélectionnez **Admin**.
1. Dans la barre latérale gauche, sélectionnez **Geo > Ajouter un site**.
1. Ajoutez le site **secondaire**. Utilisez l'URL GitLab complète pour l'URL.
1. Saisissez un Nom avec le `global.geo.nodeName` du site secondaire. Ces valeurs doivent toujours correspondre exactement, caractère par caractère.
1. Saisissez l'URL interne, par exemple `https://shanghai.gitlab.example.com`.
1. Optionnellement, choisissez quels groupes ou fragments de stockage doivent être répliqués par le site **secondaire**. Laissez vide pour tout répliquer.
1. Sélectionnez **Add node**.

Une fois que le site **secondaire** est ajouté au panneau d'administration, il commence automatiquement à répliquer les données manquantes depuis le site **principal**. Ce processus est connu sous le nom de « backfill ». Pendant ce temps, le site **principal** commence à notifier chaque site **secondaire** de tout changement, afin que le site **secondaire** puisse répliquer ces changements rapidement.

## Confirmer le statut opérationnel {#confirm-operational-status}

La dernière étape consiste à vérifier la configuration Geo sur le site secondaire une fois entièrement configuré, via le Pod Toolbox.

1. Trouvez le Pod Toolbox :

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. Connectez-vous au Pod avec `kubectl exec` :

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- bash -l
   ```

1. Vérifiez le statut de la configuration Geo :

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   Vous devriez voir une sortie similaire à celle ci-dessous :

   ```plaintext
   WARNING: This version of GitLab depends on gitlab-shell 10.2.0, but you're running Unknown. Please update gitlab-shell.
   Checking Geo ...

   GitLab Geo is available ... yes
   GitLab Geo is enabled ... yes
   GitLab Geo secondary database is correctly configured ... yes
   Database replication enabled? ... yes
   Database replication working? ... yes
   GitLab Geo HTTP(S) connectivity ...
   * Can connect to the primary node ... yes
   HTTP/HTTPS repository cloning is enabled ... yes
   Machine clock is synchronized ... Exception: getaddrinfo: Servname not supported for ai_socktype
   Git user has default SSH configuration? ... yes
   OpenSSH configured to use AuthorizedKeysCommand ... no
     Reason:
     Cannot find OpenSSH configuration file at: /assets/sshd_config
     Try fixing it:
     If you are not using our official docker containers,
     make sure you have OpenSSH server installed and configured correctly on this system
     For more information see:
     doc/administration/operations/fast_ssh_key_lookup.md
   GitLab configured to disable writing to authorized_keys file ... yes
   GitLab configured to store new projects in hashed storage? ... yes
   All projects are in hashed storage? ... yes

   Checking Geo ... Finished
   ```

   - Ne vous inquiétez pas de `Exception: getaddrinfo: Servname not supported for ai_socktype`, car les conteneurs Kubernetes n'ont pas accès à l'horloge de l'hôte. _C'est normal_.
   - `OpenSSH configured to use AuthorizedKeysCommand ... no` _est attendu_. Cette tâche Rake vérifie la présence d'un serveur SSH local, qui est en réalité présent dans le chart `gitlab-shell`, déployé ailleurs et déjà configuré de manière appropriée.

## Configurer une URL distincte pour le site secondaire (Optionnel) {#configure-a-separate-url-for-the-secondary-site-optional}

Une URL unique et unifiée pour les sites primaire et secondaire est généralement plus pratique pour les utilisateurs. Par exemple, vous pouvez :

- Placer les deux sites derrière un équilibreur de charge.
- Rediriger les utilisateurs vers le site le plus proche en utilisant les fonctionnalités DNS de votre fournisseur cloud.

Dans certains cas, vous pourriez vouloir donner aux utilisateurs le contrôle sur le site qu'ils visitent. À cette fin, vous pouvez configurer le site Geo secondaire pour utiliser une URL externe unique. Par exemple :

- URL externe du cluster primaire : `https://gitlab.example.com`
- URL externe du cluster secondaire : `https://shanghai.gitlab.example.com`

1. Modifiez `secondary.yaml` et mettez à jour l'URL externe du cluster secondaire afin que le chart `webservice` puisse traiter ces requêtes :

   ```yaml
   global:
     # See docs.gitlab.com/charts/charts/globals
     # Configure host & domain
     hosts:
       domain: example.com
       # use a unique external URL for the secondary site
       gitlab:
         name: shanghai.gitlab.example.com
   ```

1. Mettez à jour l'URL externe du site secondaire dans GitLab afin qu'il puisse utiliser l'URL partout où c'est nécessaire :
   - Utilisation de l'interface Admin :
     1. Visitez le site **principal**.
     1. Dans le coin supérieur droit, sélectionnez **Admin**.
     1. Sélectionnez **Geo > Sites**.
     1. Sélectionnez l'icône crayon pour **Edit the secondary site**.
     1. Modifiez l'URL externe, par exemple `https://shanghai.gitlab.example.com`.
     1. Sélectionnez **Sauvegarder les modifications**.

1. Redéployez le chart du site secondaire :

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f secondary.yaml
   ```

1. Attendez que le déploiement soit terminé et que l'application soit en ligne.

## Registry {#registry}

Pour synchroniser le registry secondaire avec le registry primaire, vous pouvez configurer la [réplication du registry](https://docs.gitlab.com/administration/geo/replication/container_registry/#configure-container-registry-replication) en utilisant un [secret de notification](../../charts/registry/_index.md#notification-secret).

## Cert-manager et URL unifiée {#cert-manager-and-unified-url}

L'URL unifiée de Geo est souvent utilisée avec un routage géolocalisé (par exemple, avec Amazon Route 53 ou Google Cloud DNS), ce qui peut poser des problèmes si le [défi HTTP01](https://letsencrypt.org/docs/challenge-types/#http-01-challenge) est utilisé pour valider que le nom de domaine est sous votre contrôle.

Lorsque vous demandez un certificat pour un site Geo, Let's Encrypt doit résoudre le nom DNS vers le site Geo demandeur. Si le DNS résout vers un site Geo différent, le certificat pour l'URL unifiée ne sera pas émis ou renouvelé.

Pour créer et renouveler les certificats de manière fiable avec cert-manager, soit [définissez le serveur de noms du défi](https://cert-manager.io/docs/configuration/acme/http01/#setting-nameservers-for-http-01-solver-propagation-checks) vers un serveur connu pour résoudre le nom d'hôte unifié vers l'adresse IP des sites Geo, soit configurez un [DNS01](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) [Issuer](https://cert-manager.io/docs/configuration/acme/dns01/).
