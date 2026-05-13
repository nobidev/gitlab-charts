---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Configurer les charts à l'aide des paramètres globaux"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour réduire la duplication de configuration lors de l'installation de notre chart Helm wrapper, plusieurs paramètres de configuration peuvent être définis dans la section `global` de `values.yaml`. Ces paramètres globaux sont utilisés dans plusieurs charts, tandis que tous les autres paramètres sont limités à leur chart respectif. Consultez la [documentation Helm sur les paramètres globaux](https://helm.sh/docs/chart_template_guide/subcharts_and_globals/#global-chart-values) pour plus d'informations sur le fonctionnement des variables globales.

## Configurer les paramètres d'hôte {#configure-host-settings}

Les paramètres d'hôte globaux de GitLab se trouvent sous la clé `global.hosts`.

```yaml
global:
  hosts:
    domain: example.com
    hostSuffix: staging
    https: false
    externalIP:
    gitlab:
      name: gitlab.example.com
      https: false
    registry:
      name: registry.example.com
      https: false
    minio:
      name: minio.example.com
      https: false
    smartcard:
      name: smartcard.example.com
    kas:
      name: kas.example.com
    pages:
      name: pages.example.com
      https: false
    ssh: gitlab.example.com
```

| Nom                      |  Type   | Défaut       | Description |
|:--------------------------|:-------:|:--------------|:------------|
| `domain`                  | Chaîne  | `example.com` | Le domaine de base. GitLab et Registry seront exposés sur le sous-domaine de ce paramètre. La valeur par défaut est `example.com`, mais ce paramètre n'est pas utilisé pour les hôtes dont la propriété `name` est configurée. Consultez les sections `gitlab.name`, `minio.name` et `registry.name` ci-dessous. |
| `externalIP`              |         | `nil`         | Définit l'adresse IP externe qui sera revendiquée auprès du fournisseur. Cela sera intégré dans le [chart NGINX](nginx/_index.md#configuring-nginx), à la place du paramètre plus complexe `nginx.service.loadBalancerIP`. |
| `externalGeoIP`           |         | `nil`         | Identique à `externalIP` mais pour le [chart NGINX Geo](nginx/_index.md#gitlab-geo). Nécessaire pour configurer une IP statique pour les sites [GitLab Geo](../advanced/geo/_index.md) utilisant une URL unifiée. Doit être différent de `externalIP`. |
| `https`                   | Booléen | `true`        | Si défini sur true, vous devez vous assurer que le chart NGINX a accès aux certificats. Dans les cas où vous avez une terminaison TLS devant vos Ingresses, vous voudrez probablement consulter [`global.ingress.tls.enabled`](#configure-ingress-settings). Définissez sur false pour que les URL externes utilisent `http://` au lieu de `https`. |
| `hostSuffix`              | Chaîne  |               | [Voir ci-dessous](#hostsuffix). |
| `gitlab.https`            | Booléen | `false`       | Si `hosts.https` ou `gitlab.https` sont `true`, l'URL externe de GitLab utilisera `https://` au lieu de `http://`. |
| `gitlab.name`             | Chaîne  |               | Le nom d'hôte pour GitLab. Si défini, ce nom d'hôte est utilisé, quels que soient les paramètres `global.hosts.domain` et `global.hosts.hostSuffix`. |
| `gitlab.hostnameOverride` | Chaîne  |               | Remplace le nom d'hôte utilisé dans la configuration Ingress du Webservice. Utile si GitLab doit être accessible derrière un WAF qui réécrit le nom d'hôte en un nom d'hôte interne (par ex. : `gitlab.example.com` --> `gitlab.cluster.local`). |
| `gitlab.serviceName`      | Chaîne  | `webservice`  | Le nom du `service` qui opère le serveur GitLab. Le chart va générer le nom d'hôte du service (et du `.Release.Name` actuel) pour créer le `serviceName` interne approprié. |
| `gitlab.servicePort`      | Chaîne  | `workhorse`   | Le port nommé du `service` où le serveur GitLab est accessible. |
| `keda.enabled`            | Booléen | `false`       | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` au lieu de `HorizontalPodAutoscalers` |
| `minio.https`             | Booléen | `false`       | Si `hosts.https` ou `minio.https` sont `true`, l'URL externe de MinIO utilisera `https://` au lieu de `http://`. |
| `minio.name`              | Chaîne  | `minio`       | Le nom d'hôte pour MinIO. Si défini, ce nom d'hôte est utilisé, quels que soient les paramètres `global.hosts.domain` et `global.hosts.hostSuffix`. |
| `minio.serviceName`       | Chaîne  | `minio`       | Le nom du `service` qui opère le serveur MinIO. Le chart va générer le nom d'hôte du service (et du `.Release.Name` actuel) pour créer le `serviceName` interne approprié. |
| `minio.servicePort`       | Chaîne  | `minio`       | Le port nommé du `service` où le serveur MinIO est accessible. |
| `registry.https`          | Booléen | `false`       | Si `hosts.https` ou `registry.https` sont `true`, l'URL externe du Registry utilisera `https://` au lieu de `http://`. |
| `registry.name`           | Chaîne  | `registry`    | Le nom d'hôte pour le Registry. Si défini, ce nom d'hôte est utilisé, quels que soient les paramètres `global.hosts.domain` et `global.hosts.hostSuffix`. |
| `registry.serviceName`    | Chaîne  | `registry`    | Le nom du `service` qui opère le serveur Registry. Le chart va générer le nom d'hôte du service (et du `.Release.Name` actuel) pour créer le `serviceName` interne approprié. |
| `registry.servicePort`    | Chaîne  | `registry`    | Le port nommé du `service` où le serveur Registry est accessible. |
| `smartcard.name`          | Chaîne  | `smartcard`   | Le nom d'hôte pour l'authentification par carte à puce. Si défini, ce nom d'hôte est utilisé, quels que soient les paramètres `global.hosts.domain` et `global.hosts.hostSuffix`. |
| `kas.name`                | Chaîne  | `kas`         | Le nom d'hôte pour le KAS. Si défini, ce nom d'hôte est utilisé, quels que soient les paramètres `global.hosts.domain` et `global.hosts.hostSuffix`. |
| `kas.https`               | Booléen | `false`       | Si `hosts.https` ou `kas.https` sont `true`, l'URL externe du KAS utilisera `wss://` au lieu de `ws://`. |
| `pages.name`              | Chaîne  | `pages`       | Le nom d'hôte pour GitLab Pages. Si défini, ce nom d'hôte est utilisé, quels que soient les paramètres `global.hosts.domain` et `global.hosts.hostSuffix`. |
| `pages.https`             | Chaîne  |               | Si `global.pages.https` ou `global.hosts.pages.https` ou `global.hosts.https` sont `true`, l'URL de GitLab Pages dans l'interface utilisateur des paramètres du projet utilisera `https://` au lieu de `http://`. |
| `ssh`                     | Chaîne  |               | Le nom d'hôte pour le clonage des dépôts via SSH. Si défini, ce nom d'hôte est utilisé, quels que soient les paramètres `global.hosts.domain` et `global.hosts.hostSuffix`. |

### `hostSuffix` {#hostsuffix}

Le `hostSuffix` est ajouté au sous-domaine lors de la création d'un nom d'hôte à partir du `domain` de base, mais n'est pas utilisé pour les hôtes qui ont leur propre `name` défini.

Non défini par défaut. Si défini, le suffixe est ajouté au sous-domaine avec un tiret. L'exemple ci-dessous résulterait en l'utilisation de noms d'hôtes externes tels que `gitlab-staging.example.com` et `registry-staging.example.com` :

```yaml
global:
  hosts:
    domain: example.com
    hostSuffix: staging
```

## Configurer les paramètres de l'Autoscaler Horizontal de Pods {#configure-horizontal-pod-autoscaler-settings}

Les paramètres d'hôte globaux de GitLab pour HPA se trouvent sous la clé `global.hpa` :

| Nom         |  Type  | Défaut | Description |
|:-------------|:------:|:--------|:------------|
| `apiVersion` | Chaîne |         | Version d'API à utiliser dans les définitions d'objets `HorizontalPodAutoscaler`. |

## Configurer les paramètres `PodDisruptionBudget` {#configure-poddisruptionbudget-settings}

Les paramètres d'hôte globaux de GitLab pour PDB se trouvent sous la clé `global.pdb` :

| Nom         |  Type  | Défaut | Description |
|:-------------|:------:|:--------|:------------|
| `apiVersion` | Chaîne |         | Version d'API à utiliser dans les définitions d'objets `PodDisruptionBudget`. |

## Configurer les paramètres `CronJob` {#configure-cronjob-settings}

Les paramètres d'hôte globaux de GitLab pour `CronJobs` se trouvent sous la clé `global.batch.cronJob` :

| Nom         |  Type  | Défaut | Description |
|:-------------|:------:|:--------|:------------|
| `apiVersion` | Chaîne |         | Version d'API à utiliser dans les définitions d'objets `CronJob`. |

## Configurer les paramètres de surveillance {#configure-monitoring-settings}

Les paramètres globaux de GitLab pour `ServiceMonitors` et `PodMonitors` se trouvent sous la clé `global.monitoring` :

| Nom      |  Type   | Défaut | Description |
|:----------|:-------:|:--------|:------------|
| `enabled` | Booléen | `false` | Activer les ressources de surveillance quelle que soit la disponibilité de l'API `monitoring.coreos.com/v1`. |

## Configurer les paramètres Ingress {#configure-ingress-settings}

Les paramètres d'hôte globaux de GitLab pour Ingress se trouvent sous la clé `global.ingress` :

| Nom                           |  Type   | Défaut        | Description |
|:-------------------------------|:-------:|:---------------|:------------|
| `apiVersion`                   | Chaîne  |                | Version d'API à utiliser dans les définitions d'objets Ingress. |
| `annotations.*annotation-key*` | Chaîne  |                | Où `annotation-key` est une chaîne qui sera utilisée avec la valeur comme annotation sur chaque Ingress. Par exemple : `global.ingress.annotations."nginx\.ingress\.kubernetes\.io/enable-access-log"=true`. Aucune annotation globale n'est fournie par défaut. |
| `configureCertmanager`         | Booléen | `false`        | [Voir ci-dessous](#globalingressconfigurecertmanager). |
| `useNewIngressForCerts`        | Booléen | `false`        | [Voir ci-dessous](#globalingressusenewingressforcerts). |
| `class`                        | Chaîne  | `gitlab-nginx` | Paramètre global qui contrôle l'annotation `kubernetes.io/ingress.class` ou `spec.IngressClassName` dans les ressources `Ingress`. Définissez sur `none` pour désactiver, ou `""` pour vide. Remarque : pour `none` ou `""`, définissez `nginx-ingress.enabled=false` pour empêcher les charts de déployer des ressources Ingress inutiles. |
| `enabled`                      | Booléen | `false`        | Paramètre global qui contrôle la création d'objets Ingress pour les services qui les prennent en charge. Depuis GitLab 19.0, le chart utilise par défaut Gateway API ; définissez ce paramètre sur `true` pour revenir à Ingress. |
| `tls.enabled`                  | Booléen | `true`         | Lorsque défini sur `false`, cela désactive TLS dans GitLab. Cela est utile dans les cas où vous ne pouvez pas utiliser la terminaison TLS des Ingresses, par exemple lorsque vous disposez d'un proxy avec terminaison TLS devant le contrôleur Ingress. Si vous souhaitez désactiver complètement https, ce paramètre doit être défini sur `false` conjointement avec [`global.hosts.https`](#configure-host-settings). |
| `tls.secretName`               | Chaîne  |                | Le nom du [Secret TLS Kubernetes](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls) qui contient un certificat et une clé **wildcard** pour le domaine utilisé dans `global.hosts.domain`. |
| `path`                         | Chaîne  | `/`            | Valeur par défaut pour les entrées `path` dans les [objets Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/) |
| `pathType`                     | Chaîne  | `Prefix`       | Un [type de chemin](https://kubernetes.io/docs/concepts/services-networking/ingress/#path-types) vous permet de spécifier comment un chemin doit être mis en correspondance. Notre valeur par défaut actuelle est `Prefix`, mais vous pouvez utiliser `ImplementationSpecific` ou `Exact` selon votre cas d'utilisation. |
| `provider`                     | Chaîne  | `nginx`        | Paramètre global qui définit le fournisseur Ingress à utiliser. `nginx` est utilisé comme fournisseur par défaut. |

Des [exemples de configurations pour divers fournisseurs cloud](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/examples) se trouvent dans le dossier examples.

- [`AWS`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/ingress.yaml)
- [`GKE`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/gke/ingress.yaml)

### Chemin Ingress {#ingress-path}

Ce chart utilise `global.ingress.path` pour aider les utilisateurs qui doivent modifier la définition des entrées `path` pour leurs objets Ingress. De nombreux utilisateurs n'ont pas besoin de ce paramètre et ne doivent pas le configurer.

Pour les utilisateurs qui ont besoin que leurs définitions `path` se terminent par `/*` pour correspondre au comportement de leur équilibreur de charge / proxy, comme lors de l'utilisation de `ingress.class: gce` dans GCP, `ingress.class: alb` dans AWS, ou un autre fournisseur similaire.

Ce paramètre garantit que toutes les entrées `path` dans les ressources Ingress de ce chart sont affichées avec cette valeur. La seule exception est lors du remplissage des [paramètres de déploiements `gitlab/webservice`](gitlab/webservice/_index.md#deployments-settings), où `path` doit être spécifié.

### LoadBalancers des fournisseurs cloud {#cloud-provider-loadbalancers}

Les implémentations de LoadBalancer des différents fournisseurs cloud ont un impact sur la configuration des ressources Ingress et du contrôleur NGINX déployé dans le cadre de ce chart. Le tableau suivant fournit des exemples.

| Fournisseur | Couche | Exemple de snippet |
|:---------|------:|:----------------|
| AWS      |     4 | [`aws/elb-layer4-loadbalancer`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/elb-layer4-loadbalancer.yaml) |
| AWS      |     7 | [`aws/elb-layer7-loadbalancer`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/elb-layer7-loadbalancer.yaml) |
| AWS      |     7 | [`aws/alb-full`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/alb-full.yaml) |

### `global.ingress.configureCertmanager` {#globalingressconfigurecertmanager}

Paramètre global qui contrôle la configuration automatique de [cert-manager](https://cert-manager.io/docs/installation/helm/) pour les objets Ingress. Si `true`, dépend de la définition de `certmanager-issuer.email`.

Si `false` et que `global.ingress.tls.secretName` n'est pas défini, et que `global.ingress.tls.enabled` est true ou non défini, alors ceci activera la génération automatique de certificat auto-signé, qui crée un certificat **wildcard** pour tous les objets Ingress.

Si vous souhaitez utiliser un `cert-manager` externe, vous devez fournir les éléments suivants :

- `gitlab.webservice.ingress.tls.secretName`
- `registry.ingress.tls.secretName`
- `minio.ingress.tls.secretName`
- `global.ingress.annotations`

### `global.ingress.useNewIngressForCerts` {#globalingressusenewingressforcerts}

Paramètre global qui modifie le comportement du `cert-manager` pour effectuer la validation du défi ACME avec un nouvel Ingress créé dynamiquement à chaque fois.

La logique par défaut (lorsque `global.ingress.useNewIngressForCerts` est `false`) réutilise les Ingresses existants pour la validation. Cette valeur par défaut n'est pas adaptée à certaines situations. Définir l'indicateur sur `true` signifie qu'un nouvel objet Ingress est créé pour chaque validation.

`global.ingress.useNewIngressForCerts` ne peut pas être défini sur `true` lorsqu'il est utilisé avec des contrôleurs GKE Ingress.

## Gateway API {#gateway-api}

Pour plus d'informations sur tous les paramètres liés à Gateway API et à l'Envoy Gateway intégré, consultez [Gateway API](../advanced/gateway-api/_index.md).

## Version de GitLab {#gitlab-version}

> [!note] Cette valeur ne doit être utilisée qu'à des fins de développement, ou sur demande explicite du support GitLab. Veuillez éviter d'utiliser cette valeur dans le fichier de configuration sur les environnements de production. Définissez la version comme décrit dans [Déployer avec Helm](../installation/deployment.md#deploy-using-helm) à la place.

La version de GitLab utilisée dans le tag d'image par défaut pour les charts peut être modifiée à l'aide de la clé `global.gitlabVersion` :

```shell
--set global.gitlabVersion=11.0.1
```

Cela affecte le tag d'image par défaut utilisé dans les charts `webservice`, `sidekiq` et `migration`. Notez que les tags d'image `gitaly`, `gitlab-shell` et `gitlab-runner` doivent être mis à jour séparément vers des versions compatibles avec la version de GitLab.

## Ajout d'un suffixe à tous les tags d'image {#adding-suffix-to-all-image-tags}

Si vous souhaitez ajouter un suffixe au nom de toutes les images utilisées dans le chart Helm, vous pouvez utiliser la clé `global.image.tagSuffix`. Un exemple de ce cas d'utilisation pourrait être si vous souhaitez utiliser des images de conteneurs conformes à la norme FIPS de GitLab, qui sont toutes construites avec l'extension `-fips` pour le tag d'image.

```shell
--set global.image.tagSuffix="-fips"
```

## Fuseau horaire personnalisé pour tous les conteneurs {#custom-time-zone-for-all-containers}

Si vous souhaitez définir un fuseau horaire personnalisé pour tous les conteneurs GitLab, vous pouvez utiliser la clé `global.time_zone`. Référez-vous à `TZ identifier` dans la [liste des fuseaux horaires de la base de données tz](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones) pour les valeurs disponibles. La valeur par défaut est `UTC`.

```shell
--set global.time_zone="America/Chicago"
```

## Configurer les paramètres PostgreSQL {#configure-postgresql-settings}

Les paramètres PostgreSQL globaux de GitLab se trouvent sous la clé `global.psql`.

```yaml
global:
  psql:
    host: psql.example.com
    port: 5432
    database: gitlabhq_production
    username: gitlab
    applicationName:
    preparedStatements: false
    databaseTasks: true
    connectTimeout:
    keepalives:
    keepalivesIdle:
    keepalivesInterval:
    keepalivesCount:
    tcpUserTimeout:
    password:
      useSecret: true
      secret: gitlab-postgres
      key: psql-password
      file:
```

| Nom                 |  Type   | Défaut               | Description |
|:---------------------|:-------:|:----------------------|:------------|
| `host`               | Chaîne  |                       | Le nom d'hôte du serveur PostgreSQL externe. Obligatoire. |
| `database`           | Chaîne  | `gitlabhq_production` | Le nom de la base de données à utiliser sur le serveur PostgreSQL. |
| `password.useSecret` | Booléen | `true`                | Contrôle si le mot de passe pour PostgreSQL est lu depuis un secret ou un fichier. |
| `password.file`      | Chaîne  |                       | Définit le chemin vers le fichier qui contient le mot de passe pour PostgreSQL. Ignoré si `password.useSecret` est true |
| `password.key`       | Chaîne  |                       | L'attribut `password.key` pour PostgreSQL définit le nom de la clé dans le secret (ci-dessous) qui contient le mot de passe. Ignoré si `password.useSecret` est false. |
| `password.secret`    | Chaîne  |                       | L'attribut `password.secret` pour PostgreSQL définit le nom du `Secret` Kubernetes depuis lequel récupérer les données. Ignoré si `password.useSecret` est false. |
| `port`               | Entier | `5432`                | Le port sur lequel se connecter au serveur PostgreSQL. |
| `username`           | Chaîne  | `gitlab`              | Le nom d'utilisateur avec lequel s'authentifier auprès de la base de données. |
| `preparedStatements` | Booléen | `false`               | Indique si les instructions préparées doivent être utilisées lors de la communication avec le serveur PostgreSQL. |
| `databaseTasks`      | Booléen | `true`                | Indique si GitLab doit effectuer des tâches de base de données pour une base de données donnée. Désactivé automatiquement lorsque le partage host/port/database correspond à `main`. |
| `connectTimeout`     | Entier |                       | Le nombre de secondes d'attente pour une connexion à la base de données. |
| `keepalives`         | Entier |                       | Contrôle si les `keepalives` TCP côté client sont utilisés (`1`, signifie activé, `0`, signifie désactivé). |
| `keepalivesIdle`     | Entier |                       | Le nombre de secondes d'inactivité après lesquelles TCP doit envoyer un message keepalive au serveur. Une valeur de zéro utilise la valeur par défaut du système. |
| `keepalivesInterval` | Entier |                       | Le nombre de secondes après lesquelles un message keepalive TCP non acquitté par le serveur doit être retransmis. Une valeur de zéro utilise la valeur par défaut du système. |
| `keepalivesCount`    | Entier |                       | Le nombre de `keepalives` TCP qui peuvent être perdus avant que la connexion du client au serveur soit considérée comme morte. Une valeur de zéro utilise la valeur par défaut du système. |
| `tcpUserTimeout`     | Entier |                       | Le nombre de millisecondes pendant lesquelles les données transmises peuvent rester non acquittées avant qu'une connexion soit fermée de force. Une valeur de zéro utilise la valeur par défaut du système. |
| `applicationName`    | Chaîne  |                       | Le nom de l'application se connectant à la base de données. Définissez sur une chaîne vide (`""`) pour désactiver. Par défaut, cela sera défini sur le nom du processus en cours d'exécution (par ex. `sidekiq`, `puma`). |

### PostgreSQL par chart {#postgresql-per-chart}

Dans certains déploiements complexes, il peut être souhaitable de configurer différentes parties de ce chart avec différentes configurations pour PostgreSQL. À partir de `v4.2.0`, toutes les propriétés disponibles dans `global.psql` peuvent être définies par chart, par exemple `gitlab.sidekiq.psql`. Les paramètres locaux remplaceront les valeurs globales lorsqu'ils sont fournis, héritant de ceux non présents dans `global.psql`, à l'exception de `psql.load_balancing`.

L'[équilibrage de charge PostgreSQL](#postgresql-load-balancing) n'héritera jamais du global, par conception.

### PostgreSQL SSL {#postgresql-ssl}

La prise en charge SSL est uniquement en TLS mutuel. Consultez le [ticket #2034](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2034) et le [ticket #1817](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1817).

Si vous souhaitez connecter GitLab à une base de données PostgreSQL via TLS mutuel, créez un secret contenant la clé client, le certificat client et l'autorité de certification du serveur en tant que clés de secret différentes. Décrivez ensuite la structure du secret à l'aide du mappage `global.psql.ssl`.

```yaml
global:
  psql:
    ssl:
      secret: db-example-ssl-secrets # Name of the secret
      clientCertificate: cert.pem    # Secret key storing the certificate
      clientKey: key.pem             # Secret key of the certificate's key
      serverCA: server-ca.pem        # Secret key containing the CA for the database server
```

| Nom                |  Type  | Défaut | Description |
|:--------------------|:------:|:--------|:------------|
| `secret`            | Chaîne |         | Nom du `Secret` Kubernetes contenant les clés suivantes |
| `clientCertificate` | Chaîne |         | Nom de la clé dans le `Secret` contenant le certificat client. |
| `clientKey`         | Chaîne |         | Nom de la clé dans le `Secret` contenant le fichier de clé du certificat client. |
| `serverCA`          | Chaîne |         | Nom de la clé dans le `Secret` contenant l'autorité de certification du serveur. |

Vous devrez peut-être également définir les valeurs `extraEnv` pour exporter les valeurs d'environnement pointant vers les clés correctes.

```yaml
global:
  extraEnv:
      PGSSLCERT: '/etc/gitlab/postgres/ssl/client-certificate.pem'
      PGSSLKEY: '/etc/gitlab/postgres/ssl/client-key.pem'
      PGSSLROOTCERT: '/etc/gitlab/postgres/ssl/server-ca.pem'
```

### Équilibrage de charge PostgreSQL {#postgresql-load-balancing}

Cette fonctionnalité nécessite l'utilisation d'un [PostgreSQL externe](../advanced/external-db/_index.md), car ce chart ne déploie pas PostgreSQL en mode HA.

Les composants Rails dans GitLab ont la capacité d'[utiliser des clusters PostgreSQL pour équilibrer les requêtes en lecture seule](https://docs.gitlab.com/administration/postgresql/database_load_balancing/).

Cette fonctionnalité peut être configurée de deux manières :

- En utilisant une liste statique de noms d'hôtes pour les secondaires.
- En utilisant un mécanisme de découverte de service basé sur DNS.

La configuration avec une liste statique est simple :

```yaml
global:
  psql:
    host: primary.database
    load_balancing:
       hosts:
       - secondary-1.database
       - secondary-2.database
```

La configuration de la découverte de service peut être plus complexe. Pour des détails complets sur cette configuration, les paramètres et leurs comportements associés, consultez [Service Discovery](https://docs.gitlab.com/administration/postgresql/database_load_balancing/#service-discovery) dans la [documentation d'administration GitLab](https://docs.gitlab.com/administration/).

```yaml
global:
  psql:
    host: primary.database
    load_balancing:
      discover:
        record:  secondary.postgresql.service.consul
        # record_type: A
        # nameserver: localhost
        # port: 8600
        # interval: 60
        # disconnect_timeout: 120
        # use_tcp: false
        # max_replica_pools: 30
```

Un réglage fin supplémentaire est également disponible, concernant la [gestion des lectures obsolètes](https://docs.gitlab.com/administration/postgresql/database_load_balancing/#handling-stale-reads). La documentation d'administration GitLab couvre ces éléments en détail, et ces propriétés peuvent être ajoutées directement sous `load_balancing`.

```yaml
global:
  psql:
    load_balancing:
      max_replication_difference: # See documentation
      max_replication_lag_time:   # See documentation
      replica_check_interval:     # See documentation
```

## Configurer les paramètres Redis {#configure-redis-settings}

Les paramètres Redis globaux de GitLab se trouvent sous la clé `global.redis`.

Une instance Redis externe est requise. Suivez la [documentation avancée](../advanced/external-redis/_index.md) pour la configurer.

```yaml
global:
  redis:
    host: redis.example.com
    database: 7
    port: 6379
    auth:
      enabled: true
      secret: gitlab-redis
      key: redis-password
    scheme:
```

| Nom             |  Type   | Défaut | Description |
|:-----------------|:-------:|:--------|:------------|
| `connectTimeout` | Entier |         | Le nombre de secondes d'attente pour une connexion Redis. Si aucune valeur n'est spécifiée, le client utilise par défaut 1 seconde. |
| `readTimeout`    | Entier |         | Le nombre de secondes d'attente pour une lecture Redis. Si aucune valeur n'est spécifiée, le client utilise par défaut 1 seconde. |
| `writeTimeout`   | Entier |         | Le nombre de secondes d'attente pour une écriture Redis. Si aucune valeur n'est spécifiée, le client utilise par défaut 1 seconde. |
| `host`           | Chaîne  |         | Le nom d'hôte du serveur Redis. Obligatoire lorsque `redisYmlOverride` n'est pas utilisé. |
| `port`           | Entier | `6379`  | Le port sur lequel se connecter au serveur Redis. |
| `database`       | Entier | `0`     | La base de données à laquelle se connecter sur le serveur Redis. |
| `user`           | Chaîne  |         | L'utilisateur utilisé pour s'authentifier auprès de Redis (Redis 6.0+). |
| `auth.enabled`   | Booléen | `true`  | Le `auth.enabled` fournit un commutateur pour utiliser un mot de passe avec l'instance Redis. |
| `auth.key`       | Chaîne  |         | L'attribut `auth.key` pour Redis définit le nom de la clé dans le secret (ci-dessous) qui contient le mot de passe. |
| `auth.secret`    | Chaîne  |         | L'attribut `auth.secret` pour Redis définit le nom du `Secret` Kubernetes depuis lequel récupérer les données. |
| `scheme`         | Chaîne  | `redis` | Le schéma URI à utiliser pour générer les URL Redis. Les valeurs valides sont `redis`, `rediss` et `tcp`. Lors de l'utilisation du schéma `rediss` (connexion chiffrée SSL), le certificat utilisé par le serveur doit faire partie des chaînes de confiance du système. Cela peut être fait en les ajoutant à la liste des [autorités de certification personnalisées](#custom-certificate-authorities). |
| `redisTLS`       | Objet  |         | Configuration TLS pour les connexions Redis. Consultez la [configuration TLS Redis](#redis-tls-configuration) ci-dessous. |

### Prise en charge de Redis Sentinel {#redis-sentinel-support}

Le chart GitLab prend en charge la connexion à un cluster [Redis Sentinel](https://redis.io/docs/latest/operate/oss_and_stack/management/sentinel/). Définissez `global.redis.host` sur le nom maître Sentinel (tel que spécifié dans `sentinel.conf`) et listez les nœuds Sentinel sous `global.redis.sentinels`.

```yaml
global:
  redis:
    host: redis.example.com
    port: 6379
    sentinels:
      - host: sentinel1.example.com
        port: 26379
      - host: sentinel2.example.com
        port: 26379
    auth:
      enabled: true
      secret: gitlab-redis
      key: redis-password
```

| Nom                |  Type   | Défaut | Description |
|:--------------------|:-------:|:--------|:------------|
| `host`              | Chaîne  |         | L'attribut `host` doit être défini sur le nom du cluster tel que spécifié dans le `sentinel.conf`. |
| `sentinels.[].host` | Chaîne  |         | Le nom d'hôte du serveur Redis Sentinel pour une configuration Redis HA. |
| `sentinels.[].port` | Entier | `26379` | Le port sur lequel se connecter au serveur Redis Sentinel. |

Tous les attributs Redis précédents dans la section générale [configurer les paramètres Redis](#configure-redis-settings) continuent de s'appliquer avec la prise en charge de Sentinel, sauf s'ils sont re-spécifiés dans le tableau ci-dessus.

#### Prise en charge des mots de passe Redis Sentinel {#redis-sentinel-password-support}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3792) dans GitLab 17.1.

{{< /history >}}

```yaml
global:
  redis:
    host: redis.example.com
    port: 6379
    sentinels:
      - host: sentinel1.example.com
        port: 26379
      - host: sentinel2.example.com
        port: 26379
    auth:
      enabled: true
      secret: gitlab-redis
      key: redis-password
    sentinelAuth:
      enabled: false
      secret: gitlab-redis-sentinel
      key: sentinel-password
```

| Nom                   |  Type   | Défaut | Description |
|:-----------------------|:-------:|:--------|:------------|
| `sentinelAuth.enabled` | Booléen | `false` | Le `sentinelAuth.enabled` fournit un commutateur pour utiliser un mot de passe avec l'instance Redis Sentinel. |
| `sentinelAuth.key`     | Chaîne  |         | L'attribut `sentinelAuth.key` pour Redis définit le nom de la clé dans le secret (ci-dessous) qui contient le mot de passe. |
| `sentinelAuth.secret`  | Chaîne  |         | L'attribut `sentinelAuth.secret` pour Redis définit le nom du `Secret` Kubernetes depuis lequel récupérer les données. |

`global.redis.sentinelAuth` peut être utilisé pour configurer un mot de passe Sentinel pour toutes les instances Sentinel.

Notez que `sentinelAuth` ne peut pas être remplacé par des [paramètres spécifiques à l'instance Redis](#multiple-redis-support) ou [`global.redis.redisYmlOverride`](../advanced/external-redis/_index.md#redisyml-override).

### Prise en charge de plusieurs instances Redis {#multiple-redis-support}

Le chart GitLab prend en charge l'exécution avec des instances Redis séparées pour différentes classes de persistance, actuellement :

| Instance          | Objectif |
|:------------------|:--------|
| `actioncable`     | Backend de file d'attente Pub/Sub pour ActionCable |
| `cache`           | Stocker les données en cache |
| `kas`             | Stocker les données spécifiques à KAS |
| `queues`          | Stocker les jobs Sidekiq en arrière-plan |
| `rateLimiting`    | Stocker l'utilisation de la limite de débit pour RackAttack et les limites d'application |
| `repositoryCache` | Stocker les données relatives au dépôt |
| `sessions`        | Stocker les données de session utilisateur |
| `sharedState`     | Stocker diverses données persistantes telles que les verrous distribués |
| `traceChunks`     | Stocker temporairement les traces de job |
| `workhorse`       | Backend de file d'attente Pub/Sub pour Workhorse |

N'importe quel nombre d'instances peut être spécifié. Toute instance non spécifiée sera gérée par l'instance Redis principale spécifiée par `global.redis.host`. La seule exception concerne le [serveur d'agent GitLab (KAS)](gitlab/kas/_index.md), qui recherche la configuration Redis dans l'ordre suivant :

1. `global.redis.kas`
1. `global.redis.sharedState`
1. `global.redis.host`

Par exemple :

```yaml
global:
  redis:
    host: redis.example
    port: 6379
    auth:
      enabled: true
      secret: redis-secret
      key: redis-password
    actioncable:
      host: cable.redis.example
      port: 6379
      auth:
        enabled: true
        secret: cable-secret
        key: cable-password
    cache:
      host: cache.redis.example
      port: 6379
      auth:
        enabled: true
        secret: cache-secret
        key: cache-password
    kas:
      host: kas.redis.example
      port: 6379
      auth:
        enabled: true
        secret: kas-secret
        key: kas-password
    queues:
      host: queues.redis.example
      port: 6379
      auth:
        enabled: true
        secret: queues-secret
        key: queues-password
    rateLimiting:
      host: rateLimiting.redis.example
      port: 6379
      auth:
        enabled: true
        secret: rateLimiting-secret
        key: rateLimiting-password
    repositoryCache:
      host: repositoryCache.redis.example
      port: 6379
      auth:
        enabled: true
        secret: repositoryCache-secret
        key: repositoryCache-password
    sessions:
      host: sessions.redis.example
      port: 6379
      auth:
        enabled: true
        secret: sessions-secret
        key: sessions-password
    sharedState:
      host: shared.redis.example
      port: 6379
      auth:
        enabled: true
        secret: shared-secret
        key: shared-password
    traceChunks:
      host: traceChunks.redis.example
      port: 6379
      auth:
        enabled: true
        secret: traceChunks-secret
        key: traceChunks-password
    workhorse:
      host: workhorse.redis.example
      port: 6379
      auth:
        enabled: true
        secret: workhorse-secret
        key: workhorse-password
```

Le tableau suivant décrit les attributs pour chaque dictionnaire des instances Redis.

| Nom                |  Type   | Défaut | Description |
|:--------------------|:-------:|:--------|:------------|
| `.host`             | Chaîne  |         | Le nom d'hôte du serveur Redis avec la base de données à utiliser. |
| `.port`             | Entier | `6379`  | Le port sur lequel se connecter au serveur Redis. |
| `.auth.enabled` | Booléen | `true`  | Le `auth.enabled` fournit un commutateur pour utiliser un mot de passe avec l'instance Redis. |
| `.auth.key`     | Chaîne  |         | L'attribut `auth.key` pour Redis définit le nom de la clé dans le secret (ci-dessous) qui contient le mot de passe. |
| `.auth.secret`  | Chaîne  |         | L'attribut `auth.secret` pour Redis définit le nom du `Secret` Kubernetes depuis lequel récupérer les données. |

La définition Redis principale est requise car il existe des classes de persistance supplémentaires qui n'ont pas été séparées.

Chaque définition d'instance peut également utiliser la prise en charge de Redis Sentinel. Les configurations Sentinel **ne sont pas partagées** et doivent être spécifiées pour chaque instance qui utilise des Sentinels. Veuillez vous référer à la [configuration Sentinel](#redis-sentinel-support) pour les attributs utilisés pour configurer les serveurs Sentinel.

### Spécifier le schéma Redis sécurisé (SSL) {#specify-secure-redis-scheme-ssl}

Pour se connecter à Redis avec SSL :

1. Mettez à jour votre configuration pour utiliser le paramètre de schéma `rediss` (double `s`).
1. Dans votre configuration, définissez `authClients` sur `false` :

   ```yaml
   global:
     redis:
       scheme: rediss
   redis:
     tls:
       enabled: true
       authClients: false
   ```

   Cette configuration est requise car [Redis utilise par défaut le TLS mutuel](https://redis.io/docs/latest/operate/oss_and_stack/management/security/encryption/), que tous les composants du chart ne prennent pas en charge.

1. Configurez TLS sur votre serveur Redis externe et assurez-vous que les composants du chart font confiance à l'autorité de certification utilisée pour créer les certificats Redis.
1. Optionnel. Si vous utilisez une autorité de certification personnalisée, consultez la configuration globale des [autorités de certification personnalisées](#custom-certificate-authorities).

### Configuration TLS Redis {#redis-tls-configuration}

Lors de l'utilisation du schéma `rediss`, vous pouvez éventuellement configurer des certificats client et des certificats CA pour les connexions Redis à l'aide du paramètre `redisTLS` :

```yaml
global:
  redis:
    scheme: rediss
    redisTLS:
      cert:
        secret: redis-client-cert
        key: cert
      key:
        secret: redis-client-key
        key: key
      caFile:
        secret: redis-ca
        key: ca.crt
```

La configuration `redisTLS` prend en charge :

| Nom                |  Type  | Défaut | Description |
|:--------------------|:------:|:--------|:------------|
| `cert.secret`       | Chaîne |         | Le nom du secret Kubernetes contenant le certificat client |
| `cert.key`          | Chaîne |         | La clé dans le secret contenant le certificat client |
| `key.secret`        | Chaîne |         | Le nom du secret Kubernetes contenant la clé privée client |
| `key.key`           | Chaîne |         | La clé dans le secret contenant la clé privée client |
| `caFile.secret`     | Chaîne |         | Le nom du secret Kubernetes contenant le certificat CA |
| `caFile.key`        | Chaîne |         | La clé dans le secret contenant le certificat CA |

Les trois (`cert`, `key` et `caFile`) sont optionnels. Si non spécifié, le système utilise les certificats CA par défaut.

#### Configuration TLS Sentinel {#sentinel-tls-configuration}

Lors de l'utilisation de Redis Sentinel avec TLS, vous pouvez configurer des certificats client et des certificats CA pour les connexions Sentinel à l'aide du paramètre `sentinelTLS` :

```yaml
global:
  redis:
    sentinels:
      - host: sentinel1.example.com
        port: 26379
      - host: sentinel2.example.com
        port: 26379
    sentinelTLS:
      enabled: true
      cert:
        secret: sentinel-client-cert
        key: cert
      key:
        secret: sentinel-client-key
        key: key
      caFile:
        secret: sentinel-ca
        key: ca.crt
```

La configuration `sentinelTLS` prend en charge :

| Nom                |  Type   | Défaut | Description |
|:--------------------|:-------:|:--------|:------------|
| `enabled`           | Booléen | `false` | Définissez sur `true` pour activer TLS pour les connexions Sentinel |
| `cert.secret`       | Chaîne  |         | Le nom du secret Kubernetes contenant le certificat client |
| `cert.key`          | Chaîne  |         | La clé dans le secret contenant le certificat client |
| `key.secret`        | Chaîne  |         | Le nom du secret Kubernetes contenant la clé privée client |
| `key.key`           | Chaîne  |         | La clé dans le secret contenant la clé privée client |
| `caFile.secret`     | Chaîne  |         | Le nom du secret Kubernetes contenant le certificat CA |
| `caFile.key`        | Chaîne  |         | La clé dans le secret contenant le certificat CA |

Toutes les options de certificat sont optionnelles. Si non spécifié, le système utilise les certificats CA par défaut.

### Serveurs Redis sans mot de passe {#password-less-redis-servers}

Certains services Redis tels que Google Cloud Memorystore n'utilisent pas de mots de passe ni la commande `AUTH` associée. L'utilisation et l'exigence d'un mot de passe peuvent être désactivées via le paramètre de configuration suivant :

```yaml
global:
  redis:
    auth:
      enabled: false
    host: ${REDIS_PRIVATE_IP}
```

## Configurer les paramètres du Registry {#configure-registry-settings}

Les paramètres globaux du Registry se trouvent sous la clé `global.registry`.

```yaml
global:
  registry:
    bucket: registry
    certificate:
    httpSecret:
    notificationSecret:
    notifications: {}
    ## Settings used by other services, referencing registry:
    enabled: true
    host:
    api:
      protocol: http
      serviceName: registry
      port: 5000
    tokenIssuer: gitlab-issuer
```

Pour plus de détails sur les paramètres `bucket`, `certificate`, `httpSecret` et `notificationSecret`, consultez la documentation dans le [chart registry](registry/_index.md).

Pour plus de détails sur `enabled`, `host`, `api` et `tokenIssuer`, consultez la documentation pour les [options de ligne de commande](../installation/command-line-options.md) et le [Webservice](gitlab/webservice/_index.md)

`host` est utilisé pour remplacer la référence au nom d'hôte du registry externe généré automatiquement.

### `notifications` {#notifications}

Ce paramètre est utilisé pour configurer les [notifications du Registry](https://distribution.github.io/distribution/about/notifications/). Il prend en entrée une map (suivant la spécification upstream), mais avec la fonctionnalité supplémentaire de fournir des en-têtes sensibles en tant que secrets Kubernetes. Par exemple, considérez l'extrait suivant où l'en-tête Authorization contient des données sensibles tandis que les autres en-têtes contiennent des données ordinaires :

```yaml
global:
  registry:
    notifications:
      events:
        includereferences: true
      endpoints:
        - name: CustomListener
          url: https://mycustomlistener.com
          timeout: 500mx
          # DEPRECATED: use `maxretries` instead https://gitlab.com/gitlab-org/container-registry/-/issues/1243.
          # When using `maxretries`, `threshold` is ignored: https://gitlab.com/gitlab-org/container-registry/-/blob/master/docs/configuration.md?ref_type=heads#endpoints
          threshold: 5
          maxretries: 5
          backoff: 1s
          headers:
            X-Random-Config: [plain direct]
            Authorization:
              secret: registry-authorization-header
              key: password
```

Dans cet exemple, l'en-tête `X-Random-Config` est un en-tête ordinaire et sa valeur peut être fournie en texte brut dans le fichier `values.yaml` ou via l'indicateur `--set`. Cependant, l'en-tête `Authorization` est sensible, il est donc préférable de le monter depuis un secret Kubernetes. Pour plus de détails concernant la structure du secret, consultez la [documentation sur les secrets](../installation/secrets.md#registry-sensitive-notification-headers)

## Configurer les paramètres Gitaly {#configure-gitaly-settings}

Les paramètres Gitaly globaux se trouvent sous la clé `global.gitaly`.

```yaml
global:
  gitaly:
    internal:
      names:
        - default
        - default2
    external:
      - name: node1
        hostname: node1.example.com
        port: 8075
    authToken:
      secret: gitaly-secret
      key: token
    tls:
      enabled: true
      secretName: gitlab-gitaly-tls
```

### Hôtes Gitaly {#gitaly-hosts}

[Gitaly](https://gitlab.com/gitlab-org/gitaly) est un service qui fournit un accès RPC de haut niveau aux dépôts Git, gérant tous les appels Git effectués par GitLab.

Les administrateurs peuvent choisir d'utiliser les nœuds Gitaly de la manière suivante :

- [Interne au chart](#internal), en tant que partie d'un `StatefulSet` via le [chart Gitaly](gitlab/gitaly/_index.md).
- [Externe au chart](#external), en tant que serveurs externes.
- [Environnement mixte](#mixed) utilisant à la fois des nœuds internes et externes.

Consultez la documentation sur les [chemins de stockage des dépôts](https://docs.gitlab.com/administration/repository_storage_paths/) pour des détails sur la gestion des nœuds qui seront utilisés pour les nouveaux projets.

Si `gitaly.host` est fourni, les propriétés `gitaly.internal` et `gitaly.external` *seront ignorées*. Consultez les [paramètres Gitaly dépréciés](#deprecated-gitaly-settings).

Le jeton d'authentification Gitaly doit être identique pour tous les services Gitaly à ce moment, qu'ils soient internes ou externes. Assurez-vous qu'ils sont alignés. Consultez le [ticket #1992](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1992) pour plus de détails.

#### `internal` {#internal}

La clé `internal` est actuellement composée d'une seule clé, `names`, qui est une liste de [noms de stockage](https://docs.gitlab.com/administration/repository_storage_paths/) à gérer par le chart. Pour chaque nom répertorié, *dans l'ordre logique*, un pod sera créé, nommé `${releaseName}-gitaly-${ordinal}`, où `ordinal` est l'index dans la liste `names`. Si le provisionnement dynamique est activé, le `PersistentVolumeClaim` correspondra.

Cette liste est par défaut à `['default']`, ce qui fournit 1 pod lié à un seul [chemin de stockage](https://docs.gitlab.com/administration/repository_storage_paths/).

La mise à l'échelle manuelle de cet élément est requise, en ajoutant ou en supprimant des entrées dans `gitaly.internal.names`. Lors de la réduction, tout dépôt qui n'a pas été déplacé vers un autre nœud deviendra indisponible. Étant donné que le chart Gitaly est un `StatefulSet`, les disques provisionnés dynamiquement *ne seront pas* réclamés. Cela signifie que les disques de données persisteront et que les données qu'ils contiennent seront accessibles lorsque l'ensemble sera de nouveau mis à l'échelle en rajoutant un nœud à la liste `names`.

Un exemple de [configuration de plusieurs nœuds internes](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-internal.yaml) se trouve dans le dossier examples.

#### `external` {#external}

La clé `external` fournit une configuration pour les nœuds Gitaly externes au cluster. Chaque élément de cette liste possède les clés suivantes :

- `name` : Le nom du [stockage](https://docs.gitlab.com/administration/repository_storage_paths/). Une entrée avec [`name: default` est requise](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#gitlab-requires-a-default-repository-storage).
- `address` : (optionnel) Un URI complet pour le service Gitaly (par exemple, `dns://8.8.8.8:53/gitaly.example.com` ou `dns+tls://8.8.8.8:53/gitaly.example.com` pour TLS). Lorsqu'il est spécifié, il a priorité sur `hostname` et `port`. Consultez le [guide de configuration avancée](../advanced/external-gitaly/_index.md#dns-address-format) pour plus de détails.
- `hostname` : L'hôte des services Gitaly. Obligatoire si `address` n'est pas spécifié.
- `port` : (optionnel) Le numéro de port pour atteindre l'hôte. La valeur par défaut est `8075`. Ignoré si `address` est spécifié.
- `tlsEnabled` : (optionnel) Remplace `global.gitaly.tls.enabled` pour cette entrée particulière. Ignoré si `address` est spécifié.

Nous fournissons un guide de [configuration avancée](../advanced/_index.md) pour [l'utilisation d'un service Gitaly externe](../advanced/external-gitaly/_index.md). Vous pouvez également trouver des exemples de [configuration de plusieurs services externes](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-external.yaml) dans le dossier examples.

Vous pouvez utiliser un [Praefect](https://docs.gitlab.com/administration/gitaly/praefect/) externe pour fournir des services Gitaly hautement disponibles. La configuration des deux est interchangeable car, du point de vue des clients, il n'y a pas de différence.

#### Mixte {#mixed}

Il est possible d'utiliser à la fois des nœuds Gitaly internes et externes, mais soyez conscient que :

- Il [doit toujours y avoir un nœud nommé `default`](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#gitlab-requires-a-default-repository-storage), ce qu'Internal fournit par défaut.
- Les nœuds externes seront peuplés en premier, puis les nœuds internes.

Un exemple de [configuration de nœuds internes et externes mixtes](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-mixed.yaml) est disponible dans le dossier examples.

### `authToken` {#authtoken}

L'attribut `authToken` pour Gitaly comporte deux sous-clés :

- `secret` définit le nom du `Secret` Kubernetes à utiliser.
- `key` définit le nom de la clé dans le secret ci-dessus qui contient le `authToken`.

Tous les nœuds Gitaly **doivent** partager le même jeton d'authentification.

### Paramètres Gitaly obsolètes {#deprecated-gitaly-settings}

| Nom                         |  Type   | Défaut | Description |
|:-----------------------------|:-------:|:--------|:------------|
| `host` *(obsolète)*        | Chaîne  |         | Le nom d'hôte du serveur Gitaly à utiliser. Ce paramètre peut être omis au profit de `serviceName`. Si ce paramètre est utilisé, il remplacera toutes les valeurs de `internal` ou `external`. |
| `port` *(obsolète)*        | Entier | `8075`  | Le port sur lequel se connecter au serveur Gitaly. |
| `serviceName` *(obsolète)* | Chaîne  |         | Le nom du `service` qui exploite le serveur Gitaly. Si ce paramètre est présent et que `host` ne l'est pas, le chart utilisera le nom d'hôte du service (et le `.Release.Name` actuel) à la place de la valeur `host`. C'est pratique lorsqu'on utilise Gitaly dans le cadre du chart GitLab global. |

### Paramètres TLS {#tls-settings}

La configuration de Gitaly pour fonctionner via TLS est détaillée [dans la documentation du chart Gitaly](gitlab/gitaly/_index.md#running-gitaly-over-tls).

## Configurer les paramètres Praefect {#configure-praefect-settings}

Les paramètres globaux de Praefect se trouvent sous la clé `global.praefect`.

Praefect est désactivé par défaut. Lorsqu'il est activé sans paramètres supplémentaires, 3 réplicas Gitaly seront créés, et la base de données Praefect devra être créée manuellement sur l'instance PostgreSQL par défaut.

### Activer Praefect {#enable-praefect}

Pour activer Praefect avec les paramètres par défaut, définissez `global.praefect.enabled=true`.

Pour plus d'informations, consultez [Gitaly Cluster (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/).

### Paramètres globaux pour Praefect {#global-settings-for-praefect}

```yaml
global:
  praefect:
    enabled: false
    virtualStorages:
    - name: default
      gitalyReplicas: 3
      maxUnavailable: 1
    dbSecret: {}
    psql: {}
```

| Nom              | Type    | Défaut    | Description |
|-------------------|---------|------------|-------------|
| `enabled`         | Booléen | `false`    | Indique si Praefect doit être activé ou non. |
| `virtualStorages` | Liste    |            | La liste des stockages virtuels souhaités (chacun soutenu par un `StatefulSet` Gitaly). Consultez [les stockages virtuels multiples](https://docs.gitlab.com/administration/gitaly/praefect/#multiple-virtual-storages) pour les valeurs par défaut. |
| `dbSecret.secret` | Chaîne  |            | Le nom du secret à utiliser pour l'authentification auprès de la base de données. |
| `dbSecret.key`    | Chaîne  |            | Le nom de la clé dans `dbSecret.secret` à utiliser. |
| `psql.host`       | Chaîne  |            | Le nom d'hôte du serveur de base de données à utiliser (lors de l'utilisation d'une base de données externe). |
| `psql.port`       | Chaîne  |            | Le numéro de port du serveur de base de données (lors de l'utilisation d'une base de données externe). |
| `psql.user`       | Chaîne  | `praefect` | L'utilisateur de base de données à utiliser. |
| `psql.dbName`     | Chaîne  | `praefect` | Le nom de la base de données à utiliser. |

## Configurer les paramètres MinIO {#configure-minio-settings}

Les paramètres globaux MinIO de GitLab se trouvent sous la clé `global.minio`. Pour plus de détails sur ces paramètres, consultez la documentation du [chart MinIO](minio/_index.md).

```yaml
global:
  minio:
    enabled: true
    credentials: {}
```

## Configurer les paramètres `appConfig` {#configure-appconfig-settings}

Les charts [Webservice](gitlab/webservice/_index.md), [Sidekiq](gitlab/sidekiq/_index.md) et [Gitaly](gitlab/gitaly/_index.md) partagent plusieurs paramètres, qui sont configurés avec la clé `global.appConfig`.

```yaml
global:
  appConfig:
    # cdnHost:
    relativeUrlRoot: ""
    contentSecurityPolicy:
      enabled: false
      report_only: true
      # directives: {}
    enableUsagePing: true
    enableSeatLink: true
    enableImpersonation: true
    applicationSettingsCacheSeconds: 60
    usernameChangingEnabled: true
    issueClosingPattern:
    defaultTheme:
    defaultColorMode:
    defaultSyntaxHighlightingTheme:
    defaultProjectsFeatures:
      issues: true
      mergeRequests: true
      wiki: true
      snippets: true
      builds: true
      containerRegistry: true
    webhookTimeout:
    gravatar:
      plainUrl:
      sslUrl:
    extra:
      googleAnalyticsId:
      matomoUrl:
      matomoSiteId:
      matomoDisableCookies:
      oneTrustId:
      googleTagManagerNonceId:
      bizible:
    object_store:
      enabled: false
      proxy_download: true
      storage_options: {}
      connection: {}
    lfs:
      enabled: true
      proxy_download: true
      bucket: git-lfs
      connection: {}
    artifacts:
      enabled: true
      proxy_download: true
      bucket: gitlab-artifacts
      connection: {}
    uploads:
      enabled: true
      proxy_download: true
      bucket: gitlab-uploads
      connection: {}
    packages:
      enabled: true
      proxy_download: true
      bucket: gitlab-packages
      connection: {}
    externalDiffs:
      enabled:
      when:
      proxy_download: true
      bucket: gitlab-mr-diffs
      connection: {}
    terraformState:
      enabled: false
      bucket: gitlab-terraform-state
      connection: {}
    ciSecureFiles:
      enabled: false
      bucket: gitlab-ci-secure-files
      connection: {}
    dependencyProxy:
      enabled: false
      bucket: gitlab-dependency-proxy
      connection: {}
    backups:
      bucket: gitlab-backups
    microsoft_graph_mailer:
      enabled: false
      user_id: "YOUR-USER-ID"
      tenant: "YOUR-TENANT-ID"
      client_id: "YOUR-CLIENT-ID"
      client_secret:
        secret:
        key: secret
      azure_ad_endpoint: "https://login.microsoftonline.com"
      graph_endpoint: "https://graph.microsoft.com"
    incomingEmail:
      enabled: false
      address: ""
      host: "imap.gmail.com"
      port: 993
      ssl: true
      startTls: false
      user: ""
      password:
        secret:
        key: password
      mailbox: inbox
      idleTimeout: 60
      inboxMethod: "imap"
      clientSecret:
        key: secret
      pollInterval: 60
      deliveryMethod: webhook
      authToken: {}

    serviceDeskEmail:
      enabled: false
      address: ""
      host: "imap.gmail.com"
      port: 993
      ssl: true
      startTls: false
      user: ""
      password:
        secret:
        key: password
      mailbox: inbox
      idleTimeout: 60
      inboxMethod: "imap"
      clientSecret:
        key: secret
      pollInterval: 60
      deliveryMethod: webhook
      authToken: {}

    cron_jobs: {}
    sentry:
      enabled: false
      dsn:
      clientside_dsn:
      environment:
    gitlab_docs:
      enabled: false
      host: ""
    oidcProvider:
      openidIdTokenExpireInSeconds: 120
    smartcard:
      enabled: false
      CASecret:
      clientCertificateRequiredHost:
    sidekiq:
      routingRules: []
```

### Paramètres généraux de l'application {#general-application-settings}

{{< history >}}

- Paramètre `relativeUrlRoot` [introduit](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/6121) dans GitLab 18.4.

{{< /history >}}

Les paramètres `appConfig` pouvant être utilisés pour ajuster les propriétés générales de l'application Rails sont décrits ci-dessous :

| Nom                                |  Type   | Défaut | Description |
|:------------------------------------|:-------:|:--------|:------------|
| `cdnHost`                           | Chaîne  | (vide) | Définit une URL de base pour un CDN afin de servir les ressources statiques (par exemple, `https://mycdnsubdomain.fictional-cdn.com`). |
| `relativeUrlRoot`                   | Chaîne  | (vide) | Définit une [racine d'URL relative](#configure-a-relative-url-root) pour GitLab (par exemple, `/gitlab`). Une fois configuré, GitLab sera accessible au chemin spécifié plutôt qu'au chemin racine. |
| `contentSecurityPolicy`             | Structure  |         | [Voir ci-dessous](#content-security-policy). |
| `enableUsagePing`                   | Booléen | `true`  | Un indicateur pour désactiver la [prise en charge du ping d'utilisation](https://docs.gitlab.com/administration/settings/usage_statistics/). |
| `enableSeatLink`                    | Booléen | `true`  | Un indicateur pour désactiver la prise en charge du lien de siège. |
| `enableImpersonation`               |         | `nil`   | Un indicateur pour désactiver [l'usurpation d'identité des utilisateurs par les administrateurs](https://docs.gitlab.com/api/rest/authentication/#disable-impersonation). |
| `applicationSettingsCacheSeconds`   | Entier | `60`    | Une valeur d'intervalle (en secondes) pour invalider le [cache des paramètres d'application](https://docs.gitlab.com/administration/application_settings_cache/). |
| `usernameChangingEnabled`           | Booléen | `true`  | Un indicateur pour décider si les utilisateurs sont autorisés à modifier leur nom d'utilisateur. |
| `issueClosingPattern`               | Chaîne  | (vide) | [Modèle pour fermer les tickets automatiquement](https://docs.gitlab.com/administration/issue_closing_pattern/). |
| `defaultTheme`                      | Entier |         | [ID numérique du thème par défaut pour l'instance GitLab](https://gitlab.com/gitlab-org/gitlab-foss/blob/master/lib/gitlab/themes.rb#L17-27). Il prend un nombre indiquant l'ID du thème. |
| `defaultColorMode`                  | Entier |         | [Mode de couleur par défaut pour l'instance GitLab](https://gitlab.com/gitlab-org/gitlab/-/blob/66788a1de8c3dd3c5566d0f30fe1c2a1bae64bf9/lib/gitlab/color_modes.rb#L17-19). Il prend un nombre indiquant l'ID du mode de couleur. |
| `defaultSyntaxHighlightingTheme`    | Entier |         | [Thème de coloration syntaxique par défaut pour l'instance GitLab](https://gitlab.com/gitlab-org/gitlab/-/blob/66788a1de8c3dd3c5566d0f30fe1c2a1bae64bf9/lib/gitlab/color_schemes.rb#L12-17). Il prend un nombre indiquant l'ID du thème de coloration syntaxique. |
| `defaultProjectsFeatures.*feature*` | Booléen | `true`  | [Voir ci-dessous](#defaultprojectsfeatures). |
| `gitTimeout`                        | Entier | `nil`   | Délai d'attente (en secondes) pour les opérations d'import, de récupération et de clonage Git effectuées via GitLab Shell. |
| `webhookTimeout`                    | Entier | (vide) | Temps d'attente en secondes avant qu'un [hook soit considéré comme ayant échoué](https://docs.gitlab.com/user/project/integrations/webhooks/#auto-disabled-webhooks). |
| `graphQlTimeout`                    | Entier | (vide) | Temps en secondes dont Rails dispose pour [compléter une requête GraphQL](https://docs.gitlab.com/api/graphql/#limits). |

#### Politique de sécurité du contenu {#content-security-policy}

La définition d'une politique de sécurité du contenu (CSP) peut aider à contrer les attaques de cross-site scripting (XSS) JavaScript. Consultez la documentation GitLab pour les détails de configuration. [Documentation sur la politique de sécurité du contenu](https://docs.gitlab.com/omnibus/settings/configuration/#set-a-content-security-policy)

GitLab fournit automatiquement des valeurs par défaut sécurisées pour la CSP.

```yaml
global:
  appConfig:
    contentSecurityPolicy:
      enabled: true
      report_only: false
```

Pour ajouter une CSP personnalisée :

```yaml
global:
  appConfig:
    contentSecurityPolicy:
      enabled: true
      report_only: false
      directives:
        default_src: "'self'"
        script_src: "'self' 'unsafe-inline' 'unsafe-eval' https://www.recaptcha.net https://apis.google.com"
        frame_ancestors: "'self'"
        frame_src: "'self' https://www.recaptcha.net/ https://content.googleapis.com https://content-compute.googleapis.com https://content-cloudbilling.googleapis.com https://content-cloudresourcemanager.googleapis.com"
        img_src: "* data: blob:"
        style_src: "'self' 'unsafe-inline'"
```

Une configuration incorrecte des règles CSP pourrait empêcher GitLab de fonctionner correctement. Avant de déployer une politique, vous pouvez également modifier `report_only` en `true` pour tester la configuration.

#### Configurer une racine d'URL relative {#configure-a-relative-url-root}

{{< details >}}

- Statut : Bêta

{{< /details >}}

> [!warning] La configuration d'une URL relative pour GitLab présente des [problèmes connus avec Geo](https://gitlab.com/gitlab-org/gitlab/-/issues/456427) et des [limitations de test](https://gitlab.com/gitlab-org/gitlab/-/issues/439943). Si vous utilisez déjà une URL relative et souhaitez migrer vers un sous-domaine, consultez le [guide de migration](https://docs.gitlab.com/administration/operations/migrate_to_subdomain).

Bien que vous devriez installer GitLab sur son propre domaine ou sous-domaine, vous pouvez l'installer sous une URL relative si nécessaire. Par exemple, `https://example.com/gitlab`.

Les ingresses de tous les déploiements webservice auront ce chemin comme préfixe.

```yaml
global:
  appConfig:
    relativeUrlRoot: "/gitlab"
  hosts:
    domain: example.com
    gitlab:
      name: example.com
```

#### `defaultProjectsFeatures` {#defaultprojectsfeatures}

Indicateurs pour décider si les nouveaux projets doivent être créés avec les fonctionnalités respectives par défaut. Tous les indicateurs sont définis par défaut sur `true`.

```yaml
defaultProjectsFeatures:
  issues: true
  mergeRequests: true
  wiki: true
  snippets: true
  builds: true
  containerRegistry: true
```

### Paramètres Gravatar/Libravatar {#gravatarlibravatar-settings}

Par défaut, les charts fonctionnent avec le service d'avatar Gravatar disponible sur gravatar.com. Cependant, un service Libravatar personnalisé peut également être utilisé si nécessaire :

| Nom                |  Type  | Défaut | Description |
|:--------------------|:------:|:--------|:------------|
| `gravatar.plainURL` | Chaîne | (vide) | [URL HTTP vers l'instance Libravatar (au lieu d'utiliser gravatar.com)](https://docs.gitlab.com/administration/libravatar/). |
| `gravatar.sslUrl`   | Chaîne | (vide) | [URL HTTPS vers l'instance Libravatar (au lieu d'utiliser gravatar.com)](https://docs.gitlab.com/administration/libravatar/). |

### Connexion des services Analytics à l'instance GitLab {#hooking-analytics-services-to-the-gitlab-instance}

Les paramètres pour configurer les services Analytics tels que Google Analytics et Matomo sont définis sous la clé `extra` en dessous de `appConfig` :

| Nom                            |  Type   | Défaut | Description |
|:--------------------------------|:-------:|:--------|:------------|
| `extra.googleAnalyticsId`       | Chaîne  | (vide) | ID de suivi pour Google Analytics. |
| `extra.matomoSiteId`            | Chaîne  | (vide) | ID de site Matomo. |
| `extra.matomoUrl`               | Chaîne  | (vide) | URL Matomo. |
| `extra.matomoDisableCookies`    | Booléen | (vide) | Désactiver les cookies Matomo (correspond à `disableCookies` dans le script Matomo) |
| `extra.oneTrustId`              | Chaîne  | (vide) | ID OneTrust. |
| `extra.googleTagManagerNonceId` | Chaîne  | (vide) | ID Google Tag Manager. |
| `extra.bizible`                 | Booléen | `false` | Définir sur true pour activer le script Bizible |

### Stockage d'objets consolidé {#consolidated-object-storage}

En plus de la section suivante qui décrit comment configurer les paramètres individuels pour le stockage d'objets, nous avons ajouté une configuration de stockage d'objets consolidée pour faciliter l'utilisation d'une configuration partagée pour ces éléments. En utilisant `object_store`, vous pouvez configurer une `connection` une seule fois, et elle sera utilisée pour toutes les fonctionnalités reposant sur le stockage d'objets qui ne sont pas individuellement configurées avec une propriété `connection`.

```yaml
object_store:
  enabled: true
  proxy_download: true
  storage_options:
  connection:
    secret:
    key:
```

| Nom              |  Type   | Défaut | Description |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | Booléen | `false` | Activer l'utilisation du stockage d'objets consolidé. |
| `proxy_download`  | Booléen | `true`  | Activer le proxy de tous les téléchargements via GitLab, à la place des téléchargements directs depuis le `bucket`. |
| `storage_options` | Chaîne  | `{}`    | [Voir ci-dessous](#storage_options). |
| `connection`      | Chaîne  | `{}`    | [Voir ci-dessous](#connection). |

La structure des propriétés est partagée et toutes les propriétés ici peuvent être remplacées par les éléments individuels ci-dessous. La structure de la propriété `connection` est identique.

> [!note] Les propriétés `bucket`, `enabled` et `proxy_download` sont les seules propriétés qui doivent être configurées au niveau de chaque élément (`global.appConfig.artifacts.bucket`, ...) si vous souhaitez déroger aux valeurs par défaut.

Lors de l'utilisation du fournisseur `AWS` pour la [connexion](#connection) (qui correspond à tout fournisseur compatible S3, tel que le MinIO inclus), GitLab Workhorse peut délester tous les téléchargements liés au stockage. Cette option sera automatiquement activée pour vous lors de l'utilisation de cette configuration consolidée.

### Spécifier les buckets {#specify-buckets}

Chaque type d'objet doit être stocké dans des buckets différents. Par défaut, GitLab utilise ces noms de buckets pour chaque type :

| Type d'objet                  | Nom du bucket |
|------------------------------|-------------|
| Artefacts CI                 | `gitlab-artifacts` |
| Git LFS                      | `git-lfs`   |
| Paquets                     | `gitlab-packages` |
| Téléchargements                      | `gitlab-uploads` |
| Diffs de merge request externes | `gitlab-mr-diffs` |
| État Terraform              | `gitlab-terraform-state` |
| Fichiers sécurisés CI              | `gitlab-ci-secure-files` |
| Proxy de dépendances             | `gitlab-dependency-proxy` |
| Pages                        | `gitlab-pages` |

Vous pouvez utiliser ces valeurs par défaut ou configurer les noms de buckets :

```shell
--set global.appConfig.artifacts.bucket=<BUCKET NAME> \
--set global.appConfig.lfs.bucket=<BUCKET NAME> \
--set global.appConfig.packages.bucket=<BUCKET NAME> \
--set global.appConfig.uploads.bucket=<BUCKET NAME> \
--set global.appConfig.externalDiffs.bucket=<BUCKET NAME> \
--set global.appConfig.terraformState.bucket=<BUCKET NAME> \
--set global.appConfig.ciSecureFiles.bucket=<BUCKET NAME> \
--set global.appConfig.dependencyProxy.bucket=<BUCKET NAME>
```

#### `storage_options` {#storage_options}

Les `storage_options` sont utilisées pour configurer le [chiffrement côté serveur S3](https://docs.gitlab.com/administration/object_storage/#server-side-encryption-headers).

Définir un chiffrement par défaut sur un bucket S3 est le moyen le plus simple d'activer le chiffrement, mais vous pouvez souhaiter [définir une politique de bucket pour s'assurer que seuls des objets chiffrés sont téléchargés](https://repost.aws/knowledge-center/s3-bucket-store-kms-encrypted-objects). Pour ce faire, vous devez configurer GitLab pour envoyer les en-têtes de chiffrement appropriés dans la section de configuration `storage_options` :

| Paramètre                             | Description |
|-------------------------------------|-------------|
| `server_side_encryption`            | Mode de chiffrement (`AES256` ou `aws:kms`) |
| `server_side_encryption_kms_key_id` | Nom de ressource Amazon. Nécessaire uniquement lorsque `aws:kms` est utilisé dans `server_side_encryption`. Consultez la [documentation Amazon sur l'utilisation du chiffrement KMS](https://docs.aws.amazon.com/AmazonS3/latest/userguide/UsingKMSEncryption.html) |

Exemple :

```yaml
  enabled: true
  proxy_download: true
  connection:
    secret: gitlab-rails-storage
    key: connection
  storage_options:
    server_side_encryption: aws:kms
    server_side_encryption_kms_key_id: arn:aws:kms:us-west-2:111122223333:key/1234abcd-12ab-34cd-56ef-1234567890ab
```

### LFS, artefacts, téléchargements, paquets, diffs de MR externes et proxy de dépendances {#lfs-artifacts-uploads-packages-external-mr-diffs-and-dependency-proxy}

Les détails sur ces paramètres sont présentés ci-dessous. La documentation n'est pas répétée individuellement, car ils sont structurellement identiques à l'exception de la valeur par défaut de la propriété `bucket`.

```yaml
  enabled: true
  proxy_download: true
  bucket:
  connection:
    secret:
    key:
```

| Nom             |  Type   | Défaut                                                      | Description |
|:-----------------|:-------:|:-------------------------------------------------------------|:------------|
| `enabled`        | Booléen | La valeur par défaut est `true` pour LFS, les artefacts, les téléchargements et les paquets | Activer l'utilisation de ces fonctionnalités avec le stockage d'objets. |
| `proxy_download` | Booléen | `true`                                                       | Activer le proxy de tous les téléchargements via GitLab, à la place des téléchargements directs depuis le `bucket`. |
| `bucket`         | Chaîne  | Divers                                                      | Nom du bucket à utiliser depuis le fournisseur de stockage d'objets. La valeur par défaut sera `git-lfs`, `gitlab-artifacts`, `gitlab-uploads` ou `gitlab-packages`, selon le service. |
| `connection`     | Chaîne  | `{}`                                                         | [Voir ci-dessous](#connection). |

#### `connection` {#connection}

La propriété `connection` a été transférée vers un secret Kubernetes. Le contenu de ce secret doit être un fichier au format YAML. La valeur par défaut est `{}` et sera ignorée si `global.minio.enabled` est `true`.

Cette propriété comporte deux sous-clés : `secret` et `key`.

- `secret` est le nom d'un secret Kubernetes. Cette valeur est requise pour utiliser le stockage d'objets externe.
- `key` est le nom de la clé dans le secret qui contient le bloc YAML. La valeur par défaut est `connection`.

Les clés de configuration valides se trouvent dans la documentation de [l'administration des artefacts de job GitLab](https://docs.gitlab.com/administration/cicd/secure_files/#s3-compatible-connection-settings). Cela correspond à [Fog](https://github.com/fog/fog.github.com), et diffère selon les modules de fournisseur.

Des exemples pour les fournisseurs [AWS](https://fog.github.io/storage/#using-amazon-s3-and-fog) et [Google](https://fog.github.io/storage/#google-cloud-storage) se trouvent dans [`examples/objectstorage`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage).

- [`rails.s3.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.s3.yaml)
- [`rails.gcs.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.gcs.yaml)
- [`rails.azurerm.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/objectstorage/rails.azurerm.yaml)

Une fois un fichier YAML contenant le contenu de la `connection` créé, utilisez ce fichier pour créer le secret dans Kubernetes.

```shell
kubectl create secret generic gitlab-rails-storage \
    --from-file=connection=rails.yaml
```

#### `when` (uniquement pour les diffs de MR externes) {#when-only-for-external-mr-diffs}

Le paramètre `externalDiffs` possède une clé supplémentaire `when` pour [stocker conditionnellement des diffs spécifiques dans le stockage d'objets](https://docs.gitlab.com/administration/merge_request_diffs/#alternative-in-database-storage). Ce paramètre est laissé vide par défaut dans les charts, pour qu'une valeur par défaut soit assignée par le code Rails.

#### `cdn` (uniquement pour les artefacts CI) {#cdn-only-for-ci-artifacts}

Le paramètre `artifacts` possède une clé supplémentaire `cdn` [pour configurer Google CDN devant un bucket Google Cloud Storage](../advanced/external-object-storage/_index.md#google-cloud-cdn).

### Paramètres des e-mails entrants {#incoming-email-settings}

Les paramètres des e-mails entrants sont expliqués dans la [page des options de ligne de commande](../installation/command-line-options.md#incoming-email-configuration).

### Paramètres KAS {#kas-settings}

#### Secret personnalisé {#custom-secret}

Vous pouvez optionnellement personnaliser le nom du `secret` KAS ainsi que le `key`, soit en utilisant l'option `--set variable` de Helm :

```shell
--set global.appConfig.gitlab_kas.secret=custom-secret-name \
--set global.appConfig.gitlab_kas.key=custom-secret-key \
```

ou en configurant votre `values.yaml` :

```yaml
global:
  appConfig:
    gitlab_kas:
      secret: "custom-secret-name"
      key: "custom-secret-key"
```

Si vous souhaitez personnaliser la valeur du secret, consultez la [documentation sur les secrets](../installation/secrets.md#gitlab-kas-secret).

#### URL personnalisées {#custom-urls}

Les URL utilisées pour KAS par le backend GitLab peuvent être personnalisées à l'aide de l'option `--set variable` de Helm :

```shell
--set global.appConfig.gitlab_kas.externalUrl="wss://custom-kas-url.example.com" \
--set global.appConfig.gitlab_kas.internalUrl="grpc://custom-internal-url" \
--set global.appConfig.gitlab_kas.clientTimeoutSeconds=10 # Optional, default is 5 seconds
```

ou en configurant votre `values.yaml` :

```yaml
global:
  appConfig:
    gitlab_kas:
      externalUrl: "wss://custom-kas-url.example.com"
      internalUrl: "grpc://custom-internal-url"
      clientTimeoutSeconds: 10 # Optional, default is 5 seconds
```

#### KAS externe {#external-kas}

Le backend GitLab peut être informé de l'existence d'un serveur KAS externe (c'est-à-dire non géré par le chart) en l'activant explicitement et en configurant les URL requises. Vous pouvez le faire en utilisant l'option `--set variable` de Helm :

```shell
--set global.appConfig.gitlab_kas.enabled=true \
--set global.appConfig.gitlab_kas.externalUrl="wss://custom-kas-url.example.com" \
--set global.appConfig.gitlab_kas.internalUrl="grpc://custom-internal-url" \
--set global.appConfig.gitlab_kas.clientTimeoutSeconds=10 # Optional, default is 5 seconds
```

ou en configurant votre `values.yaml` :

```yaml
global:
  appConfig:
    gitlab_kas:
      enabled: true
      externalUrl: "wss://custom-kas-url.example.com"
      internalUrl: "grpc://custom-internal-url"
      clientTimeoutSeconds: 10 # Optional, default is 5 seconds
```

#### Paramètres TLS {#tls-settings-1}

KAS prend en charge la communication TLS entre ses pods `kas` et les autres composants du chart GitLab.

Prérequis :

- Utilisez [GitLab 15.5.1 ou une version ultérieure](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/101571#note_1146419137). Vous pouvez définir votre version de GitLab avec `global.gitlabVersion: <version>`. Si vous devez forcer une mise à jour d'image après un déploiement initial, définissez également `global.image.pullPolicy: Always`.
- [Créez l'autorité de certification](../advanced/internal-tls/_index.md) et les certificats auxquels vos pods `kas` feront confiance.

Pour configurer `kas` afin d'utiliser les certificats que vous avez créés, définissez les valeurs suivantes.

| Valeur                         | Description |
|-------------------------------|-------------|
| `global.kas.tls.enabled`      | Monte le volume des certificats et active la communication TLS vers les points de terminaison `kas`. |
| `global.kas.tls.secretName`   | Spécifie quel secret TLS Kubernetes stocke vos certificats. |
| `global.kas.tls.verify`       | Lorsque défini sur `true`, demande à NGINX Ingress de vérifier le certificat TLS backend de KAS. Doit être défini sur `false` pour les certificats auto-signés. Si vous utilisez [Gateway API](../advanced/gateway-api/_index.md#tls-between-gateway-and-backend-services), le contrôleur Gateway API vérifie toujours le certificat. |
| `global.kas.tls.caSecretName` | Spécifie quel secret TLS Kubernetes stocke votre CA personnalisée. |

Par exemple, vous pouvez utiliser ce qui suit dans votre fichier `values.yaml` pour déployer votre chart :

```yaml
.internal-ca: &internal-ca gitlab-internal-tls-ca # The secret name you used to share your TLS CA.
.internal-tls: &internal-tls gitlab-internal-tls # The secret name you used to share your TLS certificate.

global:
  certificates:
    customCAs:
    - secret: *internal-ca
  hosts:
    domain: gitlab.example.com # Your gitlab domain
  kas:
    tls:
      enabled: true
      secretName: *internal-tls
      caSecretName: *internal-ca
```

### Paramètres du graphe de connaissances {#knowledge-graph-settings}

Utilisez ces paramètres pour configurer l'intégration du [GitLab Knowledge Graph](https://gitlab.com/gitlab-org/orbit/knowledge-graph).

```yaml
global:
  appConfig:
    knowledgeGraph:
      enabled: false
      jwtSecret:
        secret:
        key:
      grpcEndpoint:
```

| Nom                | Type    | Défaut | Description |
|:--------------------|:-------:|:--------|:------------|
| `enabled`           | Booléen | `false` | Activer ou désactiver l'intégration du graphe de connaissances. |
| `jwtSecret.secret`  | Chaîne  |         | Nom du secret Kubernetes contenant la clé JWT partagée. |
| `jwtSecret.key`     | Chaîne  |         | Clé dans le secret qui contient la valeur de la clé partagée JWT. |
| `grpcEndpoint`      | Chaîne  |         | Point de terminaison gRPC pour le service du graphe de connaissances (par ex. `gkg.example.com:50054`). |

### LDAP {#ldap}

Le paramètre `ldap.servers` permet de configurer l'authentification des utilisateurs [LDAP](https://docs.gitlab.com/administration/auth/ldap/). Il est présenté sous forme de carte, qui sera traduite en configuration de serveurs LDAP appropriée dans `gitlab.yml`, comme lors d'une installation depuis les sources.

La configuration des mots de passe peut être effectuée en fournissant un `secret` qui contient le mot de passe. Ce mot de passe sera ensuite injecté dans la configuration GitLab au moment de l'exécution.

Un exemple d'extrait de configuration :

```yaml
ldap:
  preventSignin: false
  servers:
    # 'main' is the GitLab 'provider ID' of this LDAP server
    main:
      label: 'LDAP'
      host: '_your_ldap_server'
      port: 636
      uid: 'sAMAccountName'
      bind_dn: 'cn=administrator,cn=Users,dc=domain,dc=net'
      base: 'dc=domain,dc=net'
      password:
        secret: my-ldap-password-secret
        key: the-key-containing-the-password
```

Exemple d'éléments de configuration `--set`, lors de l'utilisation du chart global :

```shell
--set global.appConfig.ldap.servers.main.label='LDAP' \
--set global.appConfig.ldap.servers.main.host='your_ldap_server' \
--set global.appConfig.ldap.servers.main.port='636' \
--set global.appConfig.ldap.servers.main.uid='sAMAccountName' \
--set global.appConfig.ldap.servers.main.bind_dn='cn=administrator\,cn=Users\,dc=domain\,dc=net' \
--set global.appConfig.ldap.servers.main.base='dc=domain\,dc=net' \
--set global.appConfig.ldap.servers.main.password.secret='my-ldap-password-secret' \
--set global.appConfig.ldap.servers.main.password.key='the-key-containing-the-password'
```

> [!note] Les virgules sont considérées comme des [caractères spéciaux](https://helm.sh/docs/intro/using_helm/#the-format-and-limitations-of---set) dans les éléments `--set` de Helm. Échappez les virgules dans les valeurs telles que `bind_dn` : `--set global.appConfig.ldap.servers.main.bind_dn='cn=administrator\,cn=Users\,dc=domain\,dc=net'`.

#### Désactiver la connexion web LDAP {#disable-ldap-web-sign-in}

Il peut être utile d'empêcher l'utilisation des identifiants LDAP via l'interface web lorsqu'une alternative telle que SAML est préférée. Cela permet d'utiliser LDAP pour la synchronisation des groupes, tout en permettant à votre fournisseur d'identité SAML de gérer des vérifications supplémentaires comme la authentification à deux facteurs personnalisée.

Lorsque la connexion web LDAP est désactivée, les utilisateurs ne verront pas d'onglet LDAP sur la page de connexion. Cela ne désactive pas [l'utilisation des identifiants LDAP pour l'accès Git](https://docs.gitlab.com/administration/settings/sign_in_restrictions/#allow-password-authentication-for-git-over-https).

Pour désactiver l'utilisation de LDAP pour la connexion web, définissez `global.appConfig.ldap.preventSignin: true`.

#### Utilisation d'une CA personnalisée ou de certificats LDAP auto-signés {#using-a-custom-ca-or-self-signed-ldap-certificates}

Si le serveur LDAP utilise une CA personnalisée ou un certificat auto-signé, vous devez :

1. S'assurer que le certificat CA personnalisé/auto-signé est créé en tant que Secret ou ConfigMap dans le cluster/espace de nommage :

   ```shell
   # Secret
   kubectl -n gitlab create secret generic my-custom-ca-secret --from-file=unique_name.crt=my-custom-ca.pem

   # ConfigMap
   kubectl -n gitlab create configmap my-custom-ca-configmap --from-file=unique_name.crt=my-custom-ca.pem
   ```

1. Puis, spécifiez :

   ```shell
   # Configure a custom CA from a Secret
   --set global.certificates.customCAs[0].secret=my-custom-ca-secret

   # Or from a ConfigMap
   --set global.certificates.customCAs[0].configMap=my-custom-ca-configmap

   # Configure the LDAP integration to trust the custom CA
   --set global.appConfig.ldap.servers.main.ca_file=/etc/ssl/certs/unique_name.pem
   ```

Cela garantit que le certificat CA est monté dans les pods concernés à `/etc/ssl/certs/unique_name.pem` et spécifie son utilisation dans la configuration LDAP.

Consultez [Autorités de certification personnalisées](#custom-certificate-authorities) pour plus d'informations.

### `duoAuth` {#duoauth}

Utilisez ces paramètres pour activer l'[authentification à deux facteurs (2FA) avec Cisco Duo](https://docs.gitlab.com/user/profile/account/two_factor_authentication/#enable-two-factor-authentication).

```yaml
global:
  appConfig:
    duoAuth:
      enabled:
      hostname:
      integrationKey:
      secretKey:
      #  secret:
      #  key:
```

| Nom             |  Type   | Défaut | Description |
|:-----------------|:-------:|:--------|:------------|
| `enabled`        | Booléen | `false` | Activer ou désactiver l'intégration avec Cisco Duo |
| `hostname`       | Chaîne  |         | Nom d'hôte de l'API Cisco Duo |
| `integrationKey` | Chaîne  |         | Clé d'intégration de l'API Cisco Duo |
| `secretKey`      |         |         | Clé secrète de l'API Cisco Duo qui doit être [configurée avec le nom du secret et le nom de la clé](#configure-the-cisco-duo-secret-key) |

### Configurer la clé secrète Cisco Duo {#configure-the-cisco-duo-secret-key}

Pour configurer l'intégration de l'authentification Cisco Duo dans le chart Helm GitLab, vous devez fournir un secret dans le paramètre `global.appConfig.duoAuth.secretKey.secret` contenant la valeur secret_key de l'authentification Cisco Duo.

Pour créer un objet secret Kubernetes afin de stocker le `secretKey` de votre compte Cisco Duo, depuis la ligne de commande, exécutez :

```shell
kubectl create secret generic <secret_object_name> --from-literal=secretKey=<duo_secret_key_value>
```

### OmniAuth {#omniauth}

GitLab peut exploiter OmniAuth pour permettre aux utilisateurs de se connecter via GitHub, Google et d'autres services populaires. Une documentation étendue est disponible dans la [documentation OmniAuth](https://docs.gitlab.com/integration/omniauth/#configure-common-settings) pour GitLab.

```yaml
omniauth:
  enabled: false
  autoSignInWithProvider:
  syncProfileFromProvider: []
  syncProfileAttributes: ['email']
  allowSingleSignOn: ['saml']
  blockAutoCreatedUsers: true
  autoLinkLdapUser: false
  autoLinkSamlUser: false
  autoLinkUser: ['openid_connect']
  externalProviders: []
  allowBypassTwoFactor: []
  providers: []
  # - secret: gitlab-google-oauth2
  #   key: provider
  # - name: group_saml
```

| Nom                      | Type             | Défaut |
|:--------------------------|:-----------------|:--------|
| `allowBypassTwoFactor`    | Booléen ou tableau | `false` |
| `allowSingleSignOn`       | Booléen ou tableau | `['saml']` |
| `autoLinkLdapUser`        | Booléen          | `false` |
| `autoLinkSamlUser`        | Booléen          | `false` |
| `autoLinkUser`            | Booléen ou tableau | `false` |
| `autoSignInWithProvider`  |                  | `nil`   |
| `blockAutoCreatedUsers`   | Booléen          | `true`  |
| `enabled`                 | Booléen          | `false` |
| `externalProviders`       |                  | `[]`    |
| `providers`               |                  | `[]`    |
| `syncProfileAttributes`   |                  | `['email']` |
| `syncProfileFromProvider` |                  | `[]`    |

#### `providers` {#providers}

`providers` est présenté sous forme de tableau de cartes utilisées pour remplir `gitlab.yml` comme lors d'une installation depuis les sources. Consultez la documentation GitLab pour la sélection disponible de [fournisseurs pris en charge](https://docs.gitlab.com/integration/omniauth/#supported-providers). La valeur par défaut est `[]`.

Cette propriété comporte deux sous-clés : `secret` et `key` :

- `secret` : *(obligatoire)* Le nom d'un `Secret` Kubernetes contenant le bloc de fournisseur.
- `key` : *(facultatif)* Le nom de la clé dans le `Secret` contenant le bloc de fournisseur. La valeur par défaut est `provider`

Alternativement, si le fournisseur n'a pas d'autre configuration que son nom, vous pouvez utiliser un second formulaire avec uniquement un attribut `name`, et optionnellement un attribut `label` ou `icon`. Les fournisseurs éligibles sont :

- [`group_saml`](https://docs.gitlab.com/integration/saml/#configure-group-saml-sso-on-gitlab-self-managed)
- [`kerberos`](https://docs.gitlab.com/integration/saml/#configure-group-saml-sso-on-gitlab-self-managed)

Le `Secret` pour ces entrées contient des blocs au format YAML ou JSON, tels que décrits dans [les fournisseurs OmniAuth](https://docs.gitlab.com/integration/omniauth/). Pour créer ce secret, suivez les instructions appropriées pour récupérer ces éléments, et créez un fichier YAML ou JSON.

Exemple de configuration de Google OAuth 2.0 :

```yaml
name: google_oauth2
label: Google
app_id: 'APP ID'
app_secret: 'APP SECRET'
args:
  access_type: offline
  approval_prompt: ''
```

Exemple de configuration SAML :

```yaml
name: saml
label: 'SAML'
args:
  assertion_consumer_service_url: 'https://gitlab.example.com/users/auth/saml/callback'
  idp_cert_fingerprint: 'xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx:xx'
  idp_sso_target_url: 'https://SAML_IDP/app/xxxxxxxxx/xxxxxxxxx/sso/saml'
  issuer: 'https://gitlab.example.com'
  name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:transient'
```

Exemple de configuration du fournisseur OmniAuth Microsoft Azure OAuth 2.0 :

```yaml
name: azure_activedirectory_v2
label: Azure
args:
  client_id: '<CLIENT_ID>'
  client_secret: '<CLIENT_SECRET>'
  tenant_id: '<TENANT_ID>'
```

Ce contenu peut être enregistré sous `provider.yaml`, puis un secret créé à partir de celui-ci :

```shell
kubectl create secret generic -n NAMESPACE SECRET_NAME --from-file=provider=provider.yaml
```

Une fois créés, les `providers` sont activés en fournissant les cartes dans la configuration, comme indiqué ci-dessous :

```yaml
omniauth:
  providers:
    - secret: gitlab-google-oauth2
    - secret: azure_activedirectory_v2
    - secret: gitlab-azure-oauth2
    - secret: gitlab-cas3
```

Exemple de configuration [Group SAML](https://docs.gitlab.com/integration/saml/#configuring-group-saml-on-a-self-managed-gitlab-instance) :

```yaml
omniauth:
  providers:
    - name: group_saml
```

Exemple d'éléments de configuration `--set`, lors de l'utilisation du chart global :

```shell
--set global.appConfig.omniauth.providers[0].secret=gitlab-google-oauth2 \
```

En raison de la complexité d'utilisation des arguments `--set`, un utilisateur peut souhaiter utiliser un extrait YAML, passé à `helm` avec `-f omniauth.yaml`.

### Paramètres liés aux tâches cron {#cron-jobs-related-settings}

Sidekiq inclut des jobs de maintenance qui peuvent être configurés pour s'exécuter périodiquement à l'aide de planifications de style cron. Quelques exemples sont inclus ci-dessous. Consultez les sections `cron_jobs` et `ee_cron_jobs` dans l'exemple de [`gitlab.yml`](https://gitlab.com/gitlab-org/gitlab/blob/master/config/gitlab.yml.example) pour plus d'exemples de jobs.

Ces paramètres sont partagés entre les pods Sidekiq, Webservice (pour afficher les info-bulles dans l'interface utilisateur) et Toolbox (à des fins de débogage).

```yaml
global:
  appConfig:
    cron_jobs:
      stuck_ci_jobs_worker:
        cron: "0 * * * *"
      pipeline_schedule_worker:
        cron: "3-59/10 * * * *"
      expire_build_artifacts_worker:
        cron: "*/7 * * * *"
```

### Paramètres Sentry {#sentry-settings}

Utilisez ces paramètres pour activer le [rapport d'erreurs GitLab avec Sentry](https://docs.gitlab.com/omnibus/settings/configuration/#error-reporting-and-logging-with-sentry).

```yaml
global:
  appConfig:
    sentry:
      enabled:
      dsn:
      clientside_dsn:
      environment:
```

| Nom             |  Type   | Défaut | Description |
|:-----------------|:-------:|:--------|:------------|
| `enabled`        | Booléen | `false` | Activer ou désactiver l'intégration |
| `dsn`            | Chaîne  |         | DSN Sentry pour les erreurs backend |
| `clientside_dsn` | Chaîne  |         | DSN Sentry pour les erreurs frontend |
| `environment`    | Chaîne  |         | Consultez les [environnements Sentry](https://docs.sentry.io/concepts/key-terms/environments/) |

### Paramètres `gitlab_docs` {#gitlab_docs-settings}

Utilisez ces paramètres pour activer `gitlab_docs`.

```yaml
global:
  appConfig:
    gitlab_docs:
      enabled:
      host:
```

| Nom      |  Type   | Défaut | Description |
|:----------|:-------:|:--------|:------------|
| `enabled` | Booléen | `false` | Activer ou désactiver le `gitlab_docs` |
| `host`    | Chaîne  | `""`    | hôte de la documentation   |

### Expiration du jeton OpenID Connect {#openid-connect-token-expiration}

Configurer l'expiration du jeton du fournisseur OpenID Connect (OIDC).

```yaml
global:
  appConfig:
    oidcProvider:
      openidIdTokenExpireInSeconds: 120
```

| Nom                           | Type    | Défaut | Description |
|--------------------------------|---------|---------|-------------|
| `openidIdTokenExpireInSeconds` | Entier | 120     | Durée (en secondes) avant l'expiration des jetons d'ID. |

### Paramètres d'authentification par carte à puce {#smartcard-authentication-settings}

```yaml
global:
  appConfig:
    smartcard:
      enabled: false
      CASecret:
      clientCertificateRequiredHost:
      sanExtensions: false
      requiredForGitAccess: false
```

| Nom                            |  Type   | Défaut | Description |
|:--------------------------------|:-------:|:--------|:------------|
| `enabled`                       | Booléen | `false` | Activer ou désactiver l'authentification par carte à puce |
| `CASecret`                      | Chaîne  |         | Nom du secret contenant le certificat CA |
| `clientCertificateRequiredHost` | Chaîne  |         | Nom d'hôte à utiliser pour l'authentification par carte à puce. Par défaut, le nom d'hôte de carte à puce fourni ou calculé est utilisé. |
| `sanExtensions`                 | Booléen | `false` | Activer l'utilisation des extensions SAN pour faire correspondre les utilisateurs aux certificats. |
| `requiredForGitAccess`          | Booléen | `false` | Exiger une session de navigateur avec connexion par carte à puce pour l'accès Git. |

L'authentification par carte à puce fonctionne directement avec la [passerelle Envoy intégrée](envoygateway/_index.md), sans configuration supplémentaire. Pour utiliser le [NGINX Ingress intégré](nginx/_index.md) à la place, vous devez activer les annotations d'extraits.

L'activation des annotations d'extraits permet d'injecter une configuration NGINX personnalisée via des annotations, ce qui peut présenter un risque de sécurité dans certains environnements. Veuillez consulter la [documentation en amont](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#allow-snippet-annotations) avant d'activer les annotations.

```yaml
nginx-ingress:
  enabled: true
  controller:
    config:
      allow-snippet-annotations: "true"
      annotations-risk-level: "Critical"
```

### Paramètres des règles de routage Sidekiq {#sidekiq-routing-rules-settings}

GitLab prend en charge le routage d'un job d'un worker vers une file d'attente souhaitée avant qu'il ne soit planifié. Les clients Sidekiq font correspondre un job à une liste configurée de règles de routage. Les règles sont évaluées du début à la fin, et dès qu'une correspondance est trouvée pour un worker donné, le traitement de ce worker est arrêté (la première correspondance l'emporte). Si le worker ne correspond à aucune règle, il revient au nom de file d'attente généré à partir du nom du worker.

Par défaut, les règles de routage ne sont pas configurées (ou indiquées avec un tableau vide), tous les jobs sont acheminés vers la file d'attente générée à partir du nom du worker.

La liste des règles de routage est un tableau ordonné de tuples de requêtes et de files d'attente correspondantes :

- La requête suit la syntaxe de [requête de correspondance de worker](https://docs.gitlab.com/administration/sidekiq/processing_specific_job_classes/#worker-matching-query).
- Le `<queue_name>` doit correspondre à un nom de file d'attente Sidekiq valide `sidekiq.pods[].queues` défini sous [`sidekiq.pods`](gitlab/sidekiq/_index.md#per-pod-settings). Si le nom de la file d'attente est `nil`, ou une chaîne vide, le worker est acheminé vers la file d'attente générée par le nom du worker. Consultez [l'exemple complet de configuration Sidekiq](gitlab/sidekiq/_index.md#full-example-of-sidekiq-configuration) comme référence.

La requête prend en charge la correspondance par caractère générique `*`, qui correspond à tous les workers. Par conséquent, la requête avec caractère générique doit rester à la fin de la liste, sinon les règles suivantes sont ignorées :

```yaml
global:
  appConfig:
    sidekiq:
      routingRules:
      - ["resource_boundary=cpu", "cpu-boundary"]
      - ["feature_category=pages", null]
      - ["feature_category=search", "search"]
      - ["feature_category=memory|resource_boundary=memory", "memory-bound"]
      - ["*", "default"]
```

## Configurer les paramètres Rails {#configure-rails-settings}

Une grande partie de la suite GitLab est basée sur Rails. Par conséquent, de nombreux conteneurs de ce projet fonctionnent avec cette pile. Ces paramètres s'appliquent à tous ces conteneurs et fournissent un moyen d'accès facile pour les définir globalement plutôt qu'individuellement.

```yaml
global:
  rails:
    bootsnap:
      enabled: true
```

## Configurer les paramètres Workhorse {#configure-workhorse-settings}

Plusieurs composants de la suite GitLab communiquent avec les API via GitLab Workhorse. Il fait actuellement partie du chart Webservice. Ces paramètres sont utilisés par tous les charts qui doivent contacter GitLab Workhorse, offrant un accès facile pour les définir globalement plutôt qu'individuellement.

```yaml
global:
  workhorse:
    serviceName: webservice-default
    host: api.example.com
    port: 8181
```

| Nom          | Type    | Défaut              | Description |
|:--------------|:--------|:---------------------|:------------|
| `serviceName` | Chaîne  | `webservice-default` | Nom du service vers lequel diriger le trafic API interne. N'incluez pas le nom du Release, car il sera intégré au template. Doit correspondre à une entrée dans `gitlab.webservice.deployments`. Consultez le [chart `gitlab/webservice`](gitlab/webservice/_index.md#deployments-settings) |
| `scheme`      | Chaîne  | `http`               | Schéma du point de terminaison API |
| `host`        | Chaîne  |                      | Nom d'hôte entièrement qualifié ou adresse IP d'un point de terminaison API. Remplace la présence de `serviceName`. |
| `port`        | Entier | `8181`               | Numéro de port du serveur API associé. |
| `tls.enabled` | Booléen | `false`              | Lorsque défini sur `true`, active la prise en charge TLS pour Workhorse. |

### Cache Bootsnap {#bootsnap-cache}

Notre base de code Rails utilise le Gem [Shopify Bootsnap](https://github.com/Shopify/bootsnap). Les paramètres ici sont utilisés pour configurer ce comportement.

`bootsnap.enabled` contrôle l'activation de cette fonctionnalité. Sa valeur par défaut est `true`.

Les tests ont montré que l'activation de Bootsnap entraîne une amélioration globale des performances de l'application. Lorsqu'un cache précompilé est disponible, certains conteneurs d'applications constatent des gains supérieurs à 33 %. À l'heure actuelle, GitLab ne fournit pas ce cache précompilé avec ses conteneurs, ce qui entraîne un gain de « seulement » 14 %. Ce gain a un coût sans cache précompilé, entraînant un pic intense de petites opérations d'E/S au démarrage initial de chaque Pod. Pour cette raison, nous avons exposé une méthode de désactivation de Bootsnap dans les environnements où cela poserait un problème.

Dans la mesure du possible, nous recommandons de laisser cette option activée.

## Configurer GitLab Shell {#configure-gitlab-shell}

Plusieurs éléments sont disponibles pour la configuration globale du chart [GitLab Shell](gitlab/gitlab-shell/_index.md).

```yaml
global:
  shell:
    port:
    authToken: {}
    hostKeys: {}
    tcp:
      proxyProtocol: false
```

| Nom                |  Type   | Défaut | Description |
|:--------------------|:-------:|:--------|:------------|
| `port`              | Entier | `22`    | Consultez [`port`](#port) ci-dessous pour une documentation spécifique. |
| `authToken`         |         |         | Consultez [`authToken`](gitlab/gitlab-shell/_index.md#authtoken) dans la documentation spécifique au chart GitLab Shell. |
| `hostKeys`          |         |         | Consultez [`hostKeys`](gitlab/gitlab-shell/_index.md#hostkeyssecret) dans la documentation spécifique au chart GitLab Shell. |
| `tcp.proxyProtocol` | Booléen | `false` | Consultez [le protocole proxy TCP](#tcp-proxy-protocol) ci-dessous pour une documentation spécifique. |

### Port {#port}

Vous pouvez contrôler le port utilisé par l'Ingress pour passer le trafic SSH, ainsi que le port utilisé dans les URL SSH fournies par GitLab via `global.shell.port`. Cela se reflète dans le port sur lequel le service écoute, ainsi que dans les URL de clone SSH fournies dans l'interface utilisateur du projet.

```yaml
global:
  shell:
    port: 32022
```

Vous pouvez combiner `global.shell.port` et `nginx-ingress.controller.service.type=NodePort` pour définir un NodePort pour l'objet Service du contrôleur NGINX. Notez que si `nginx-ingress.controller.service.nodePorts.gitlab-shell` est défini, il remplacera `global.shell.port` lors de la définition du NodePort pour NGINX.

```yaml
global:
  shell:
    port: 32022

nginx-ingress:
  controller:
    service:
      type: NodePort
```

### Protocole proxy TCP {#tcp-proxy-protocol}

Vous pouvez activer la gestion du [protocole proxy](https://www.haproxy.com/blog/use-the-proxy-protocol-to-preserve-a-clients-ip-address) sur le SSH Ingress pour gérer correctement une connexion provenant d'un proxy en amont qui ajoute l'en-tête de protocole proxy. Ce faisant, cela empêchera SSH de recevoir les en-têtes supplémentaires et ne perturbera pas SSH.

Un environnement courant où l'on doit activer la gestion du protocole proxy est lors de l'utilisation d'AWS avec un ELB gérant les connexions entrantes vers le cluster. Vous pouvez consulter l'[exemple d'équilibreur de charge AWS layer 4](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/aws/elb-layer4-loadbalancer.yaml) pour le configurer correctement.

```yaml
global:
  shell:
    tcp:
      proxyProtocol: true # default false
```

## Configurer GitLab Pages {#configure-gitlab-pages}

Les paramètres globaux de GitLab Pages utilisés par d'autres charts sont documentés sous la clé `global.pages`.

```yaml
global:
  pages:
    enabled:
    accessControl:
    path:
    host:
    port:
    https:
    externalHttp:
    externalHttps:
    customDomainMode:
    artifactsServer:
    objectStore:
      enabled:
      bucket:
      proxy_download: true
      connection: {}
        secret:
        key:
    localStore:
      enabled: false
      path:
    apiSecret: {}
      secret:
      key:
    namespaceInPath: false
```

| Nom                            |  Type   | Défaut                    | Description |
|:--------------------------------|:-------:|:---------------------------|:------------|
| `enabled`                       | Booléen | `false`                    | Détermine si le chart GitLab Pages doit être installé dans le cluster |
| `accessControl`                 | Booléen | `false`                    | Active le contrôle d'accès GitLab Pages |
| `path`                          | Chaîne  | `/srv/gitlab/shared/pages` | Chemin où les fichiers liés au déploiement des Pages seront stockés. Remarque : Non utilisé par défaut, car le stockage d'objets est utilisé. |
| `host`                          | Chaîne  |                            | Domaine racine des Pages. |
| `port`                          | Chaîne  |                            | Port à utiliser pour construire les URL des Pages dans l'interface utilisateur. Si non défini, la valeur par défaut de 80 ou 443 est définie en fonction de la situation HTTPS des Pages. |
| `https`                         | Booléen | `true`                     | Indique si l'interface utilisateur de GitLab doit afficher les URL HTTPS pour les Pages ou non. A la priorité sur `global.hosts.pages.https` et `global.hosts.https`. |
| `externalHttp`                  |  Liste   | `[]`                       | Liste des adresses IP par lesquelles les requêtes HTTP atteignent le démon Pages. Pour la prise en charge des [domaines personnalisés](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/). |
| `externalHttps`                 |  Liste   | `[]`                       | Liste des adresses IP par lesquelles les requêtes HTTPS atteignent le démon Pages. Pour la prise en charge des [domaines personnalisés](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/). |
| `customDomainMode`              | Chaîne  |                            | À configurer pour activer les [domaines personnalisés](https://docs.gitlab.com/user/project/pages/custom_domains_ssl_tls_certification/) : `http` ou `https`. |
| `artifactsServer`               | Booléen | `true`                     | Activer la consultation des artefacts dans GitLab Pages. |
| `objectStore.enabled`           | Booléen | `true`                     | Activer l'utilisation du stockage d'objets pour Pages. |
| `objectStore.bucket`            | Chaîne  | `gitlab-pages`             | Bucket à utiliser pour stocker le contenu lié à Pages |
| `objectStore.connection.secret` | Chaîne  |                            | Secret contenant les détails de connexion pour le stockage d'objets. |
| `objectStore.connection.key`    | Chaîne  |                            | Clé dans le secret de connexion où sont stockés les détails de connexion. |
| `localStore.enabled`            | Booléen | `false`                    | Activer l'utilisation du stockage local pour le contenu lié à Pages (par opposition à `objectStore`) |
| `localStore.path`               | Chaîne  | `/srv/gitlab/shared/pages` | Chemin où les fichiers de pages seront stockés ; utilisé uniquement si `localStore` est défini sur true. |
| `apiSecret.secret`              | Chaîne  |                            | Secret contenant la clé API de 32 bits sous forme encodée en Base64. |
| `apiSecret.key`                 | Chaîne  |                            | Clé dans le secret de clé API où est stockée la clé API. |
| `namespaceInPath`               | Booléen | `false`                    | (Bêta) Activer ou désactiver l'espace de nommage dans le chemin d'URL pour la prise en charge sans configuration DNS avec caractère générique. Pour plus d'informations, consultez la [documentation sur le domaine Pages sans DNS avec caractère générique](gitlab/gitlab-pages/_index.md#pages-domain-without-wildcard-dns). |

## Configurer Webservice {#configure-webservice}

Les paramètres globaux de Webservice (également utilisés par d'autres charts) se trouvent sous la clé `global.webservice`.

```yaml
global:
  webservice:
    workerTimeout: 60
```

### `workerTimeout` {#workertimeout}

Configurez le délai d'attente des requêtes (en secondes) après lequel un processus de travail Webservice est arrêté par le processus maître Webservice. La valeur par défaut est de 60 secondes.

Le paramètre `global.webservice.workerTimeout` n'affecte pas la durée maximale des requêtes. Pour définir la durée maximale des requêtes, définissez les variables d'environnement suivantes :

```yaml
gitlab:
  webservice:
    workerTimeout: 60
    extraEnv:
      GITLAB_RAILS_RACK_TIMEOUT: "60"
      GITLAB_RAILS_WAIT_TIMEOUT: "90"
```

## Autorités de certification personnalisées {#custom-certificate-authorities}

> [!note] Ces paramètres n'affectent pas les charts tiers intégrés.

Certains utilisateurs peuvent avoir besoin d'ajouter des autorités de certification personnalisées, par exemple lors de l'utilisation de certificats SSL émis en interne pour les services TLS. Pour fournir cette fonctionnalité, nous proposons un mécanisme permettant d'injecter ces autorités de certification racine personnalisées dans l'application via des Secrets ou des ConfigMaps.

Pour créer un Secret ou un ConfigMap :

```shell
# Create a Secret from a certificate file
kubectl create secret generic secret-custom-ca --from-file=unique_name.crt=/path/to/cert

# Create a ConfigMap from a certificate file
kubectl create configmap cm-custom-ca --from-file=unique_name.crt=/path/to/cert
```

Pour configurer un Secret, un ConfigMap ou les deux, spécifiez-les dans les paramètres globaux :

```yaml
global:
  certificates:
    customCAs:
      - secret: secret-custom-CAs           # Mount all keys of a Secret
      - secret: secret-custom-CAs           # Mount only the specified keys of a Secret
        keys:
          - unique_name.crt
      - configMap: cm-custom-CAs            # Mount all keys of a ConfigMap
      - configMap: cm-custom-CAs            # Mount only the specified keys of a ConfigMap
        keys:
          - unique_name_1.crt
          - unique_name_2.crt
```

> [!note] L'extension `.crt` dans le nom de clé du Secret est importante pour le [package Debian update-ca-certificates](https://manpages.debian.org/bullseye/ca-certificates/update-ca-certificates.8.en.html). Cette étape garantit que le fichier CA personnalisé est monté avec cette extension et est traité dans les `initContainers` de Certificates. Auparavant, lorsque l'image d'aide aux certificats était basée sur Alpine, l'extension de fichier n'était pas réellement requise, même si la [documentation](https://gitlab.alpinelinux.org/alpine/ca-certificates/-/blob/master/update-ca-certificates.8) indique qu'elle l'est. L'utilitaire `update-ca-trust` basé sur UBI ne semble pas avoir la même exigence.

Vous pouvez fournir n'importe quel nombre de Secrets ou de ConfigMaps, chacun contenant n'importe quel nombre de clés contenant des certificats CA encodés en PEM. Ceux-ci sont configurés en tant qu'entrées sous `global.certificates.customCAs`. Toutes les clés sont montées, sauf si `keys:` est fourni avec une liste de clés spécifiques à monter. Toutes les clés montées dans tous les Secrets et ConfigMaps doivent être uniques. Les Secrets et les ConfigMaps peuvent être nommés de n'importe quelle façon, mais ils *ne doivent pas* contenir des noms de clés qui entrent en collision.

## Ressource Application {#application-resource}

GitLab peut éventuellement inclure une [ressource Application](https://github.com/kubernetes-sigs/application), qui peut être créée pour identifier l'application GitLab dans le cluster. Nécessite que le [CRD Application](https://github.com/kubernetes-sigs/application#installing-the-crd), version `v1beta1`, soit déjà déployé dans le cluster.

Pour activer, définissez `global.application.create` sur `true` :

```yaml
global:
  application:
    create: true
```

Certains environnements, tels que Google GKE Marketplace, ne permettent pas la création de ressources ClusterRole. Définissez les valeurs suivantes pour désactiver les composants ClusterRole dans la définition de ressource personnalisée Application ainsi que dans les charts pertinents fournis avec Cloud Native GitLab.

```yaml
global:
  application:
    allowClusterRoles: false
nginx:
  controller:
    scope:
      enabled: true
gitlab-runner:
  rbac:
    clusterWideAccess: false
installCertmanager: false
```

## Image de base GitLab {#gitlab-base-image}

Le chart Helm GitLab utilise une image de base GitLab commune pour diverses tâches d'initialisation. Cette image prend en charge les builds UBI et partage des couches avec d'autres images.

## Comptes de service {#service-accounts}

Les charts Helm GitLab permettent aux pods de s'exécuter en utilisant des [comptes de service](https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/) personnalisés. Ceci est configuré avec les paramètres suivants dans `global.serviceAccount` :

```yaml
global:
  serviceAccount:
    enabled: false
    create: true
    annotations: {}
    automountServiceAccountToken: false
    ## Name to be used for serviceAccount, otherwise defaults to chart fullname
    # name:
```

- Le paramètre `global.serviceAccount.enabled` contrôle la référence à un compte de service pour chaque composant via `spec.serviceAccountName`.
- Le paramètre `global.serviceAccount.create` contrôle la création d'objets compte de service via Helm.
- Le paramètre `global.serviceAccount.name` contrôle le nom de l'objet compte de service et le nom référencé par chaque composant.
- Le paramètre `global.serviceAccount.automountServiceAccountToken` contrôle si le jeton d'accès ServiceAccount par défaut doit être monté dans les pods. Vous ne devriez pas activer ceci, sauf si certains sidecars en ont besoin pour fonctionner correctement (par exemple, Istio).

> [!note] N'utilisez pas `global.serviceAccount.create=true` avec `global.serviceAccount.name`, car cela demande aux charts de créer plusieurs objets ServiceAccount avec le même nom. À la place, utilisez `global.serviceAccount.create=false` si vous spécifiez un nom global.

## Annotations {#annotations}

Des annotations personnalisées peuvent être appliquées aux objets Deployment, Service et Ingress.

```yaml
global:
  deployment:
    annotations:
      environment: production

  service:
    annotations:
      environment: production

  ingress:
    annotations:
      environment: production
```

## Node Selector {#node-selector}

Des `nodeSelector`s personnalisés peuvent être appliqués à tous les composants globalement. Tous les paramètres globaux par défaut peuvent également être remplacés sur chaque sous-chart individuellement.

```yaml
global:
  nodeSelector:
    disktype: ssd
```

> [!note] Les charts maintenus en externe ne respectent pas `global.nodeSelector` pour le moment et pourraient nécessiter une configuration séparée en fonction des valeurs de chart disponibles. Cela inclut Prometheus, cert-manager, Redis, etc.

## Labels {#labels}

### Labels communs {#common-labels}

Les labels peuvent être appliqués à presque tous les objets créés par divers objets en utilisant la configuration `common.labels`. Ceci peut être appliqué sous la clé `global`, ou sous la configuration d'un chart spécifique. Exemple :

```yaml
global:
  common:
    labels:
      environment: production
gitlab:
  gitlab-shell:
    common:
      labels:
        foo: bar
```

Avec l'exemple de configuration ci-dessus, presque tous les composants déployés par le chart Helm recevront l'ensemble de labels `environment: production`. Tous les composants du chart GitLab Shell recevront l'ensemble de labels `foo: bar`. Certains charts permettent une imbrication supplémentaire. Par exemple, les charts Sidekiq et Webservice permettent des déploiements supplémentaires en fonction de vos besoins de configuration :

```yaml
gitlab:
  sidekiq:
    pods:
      - name: pod-0
        common:
          labels:
            baz: bat
```

Dans l'exemple ci-dessus, tous les composants associés au déploiement Sidekiq `pod-0` recevront également l'ensemble de labels `baz: bat`. Référez-vous aux charts Sidekiq et Webservice pour plus de détails.

Certains charts dont nous dépendons sont exclus de cette configuration de labels. Seuls les [sous-charts du composant GitLab](gitlab/_index.md) recevront ces labels supplémentaires.

### `pod` {#pod}

Des labels personnalisés peuvent être appliqués à divers déploiements et jobs. Ces labels sont complémentaires aux labels existants ou préconfigurés construits par ce chart Helm. Ces labels complémentaires ne seront **pas** utilisés pour `matchSelectors`.

```yaml
global:
  pod:
    labels:
      environment: production
```

### `service` {#service}

Des labels personnalisés peuvent être appliqués aux services. Ces labels sont complémentaires aux labels existants ou préconfigurés construits par ce chart Helm.

```yaml
global:
  service:
    labels:
      environment: production
```

## Tracing {#tracing}

Les charts Helm GitLab prennent en charge le tracing, et vous pouvez le configurer avec :

```yaml
global:
  tracing:
    connection:
      string: 'opentracing://jaeger?http_endpoint=http%3A%2F%2Fjaeger.example.com%3A14268%2Fapi%2Ftraces&sampler=const&sampler_param=1'
    urlTemplate: 'http://jaeger-ui.example.com/search?service={{ service }}&tags=%7B"correlation_id"%3A"{{ correlation_id }}"%7D'
```

- `global.tracing.connection.string` est utilisé pour configurer où les spans de tracing seront envoyés. Vous pouvez en savoir plus dans la [documentation sur le tracing GitLab](https://docs.gitlab.com/development/distributed_tracing/).
- `global.tracing.urlTemplate` est utilisé comme modèle pour le rendu de l'URL d'informations de tracing dans la barre de performances GitLab.

## `extraEnv` {#extraenv}

`extraEnv` vous permet d'exposer des variables d'environnement supplémentaires dans tous les conteneurs des pods déployés via les charts GitLab (`charts/gitlab/charts`). Les variables d'environnement supplémentaires définies au niveau global seront fusionnées avec celles fournies au niveau du chart, avec la priorité donnée à celles fournies au niveau du chart.

Voici un exemple d'utilisation de `extraEnv` :

```yaml
global:
  extraEnv:
    SOME_KEY: some_value
    SOME_OTHER_KEY: some_other_value
```

## `extraEnvFrom` {#extraenvfrom}

`extraEnvFrom` permet d'exposer des variables d'environnement supplémentaires provenant d'autres sources de données dans tous les conteneurs des pods. Des variables d'environnement supplémentaires peuvent être définies au niveau `global` (`global.extraEnvFrom`) et au niveau d'un sous-chart (`<subchart_name>.extraEnvFrom`).

Les charts Sidekiq et Webservice prennent en charge des remplacements locaux supplémentaires. Consultez leur documentation pour plus de détails.

Voici un exemple d'utilisation de `extraEnvFrom` :

```yaml
global:
  extraEnvFrom:
    MY_NODE_NAME:
      fieldRef:
        fieldPath: spec.nodeName
    MY_CPU_REQUEST:
      resourceFieldRef:
        containerName: test-container
        resource: requests.cpu
gitlab:
  kas:
    extraEnvFrom:
      CONFIG_STRING:
        configMapKeyRef:
          name: useful-config
          key: some-string
          # optional: boolean
```

> [!note] L'implémentation ne prend pas en charge la réutilisation d'un nom de valeur avec différents types de contenu. Vous pouvez remplacer le même nom avec un contenu similaire, mais ne mélangez pas les sources comme `secretKeyRef`, `configMapKeyRef`, etc.

## Configurer les paramètres OAuth {#configure-oauth-settings}

L'intégration OAuth est configurée prête à l'emploi pour les services qui la prennent en charge. Les services spécifiés dans `global.oauth` sont automatiquement enregistrés en tant qu'applications clientes OAuth dans GitLab lors du déploiement. Par défaut, cette liste inclut GitLab Pages, si le contrôle d'accès est activé.

```yaml
global:
  oauth:
    gitlab-pages: {}
    # secret
    # appid
    # appsecret
    # redirectUri
    # authScope
```

| Nom           | Type   | Défaut | Description |
|:---------------|:-------|:--------|:------------|
| `secret`       | Chaîne |         | Nom du secret contenant les informations d'identification OAuth pour le service. |
| `appIdKey`     | Chaîne |         | Clé dans le secret sous laquelle l'identifiant d'application du service est stocké. La valeur par défaut définie est `appid`. |
| `appSecretKey` | Chaîne |         | Clé dans le secret sous laquelle le secret d'application du service est stocké. La valeur par défaut définie est `appsecret`. |
| `redirectUri`  | Chaîne |         | URI vers laquelle l'utilisateur doit être redirigé après une autorisation réussie. |
| `authScope`    | Chaîne | `api`   | Portée utilisée pour l'authentification avec l'API GitLab. |

Consultez la [documentation sur les secrets](../installation/secrets.md#oauth-integration) pour plus de détails sur le secret.

## Kerberos {#kerberos}

Pour configurer l'intégration Kerberos dans le chart Helm GitLab, vous devez fournir un secret dans le paramètre `global.appConfig.kerberos.keytab.secret` contenant un [keytab](https://web.mit.edu/kerberos/krb5-devel/doc/basic/keytab_def.html) Kerberos avec un principal de service pour votre hôte GitLab. Vos administrateurs Kerberos peuvent vous aider à créer un fichier keytab si vous n'en avez pas.

Vous pouvez créer un secret en utilisant l'extrait suivant (en supposant que vous installez le chart dans l'espace de nommage `gitlab` et que `gitlab.keytab` est le fichier keytab contenant le principal de service) :

```shell
kubectl create secret generic gitlab-kerberos-keytab --namespace=gitlab --from-file=keytab=./gitlab.keytab
```

L'intégration Kerberos pour Git est activée en définissant `global.appConfig.kerberos.enabled=true`. Cela ajoutera également le fournisseur `kerberos` à la liste des fournisseurs [OmniAuth](https://docs.gitlab.com/integration/omniauth/) activés pour l'authentification par ticket dans le navigateur.

Si laissé à `false`, le chart Helm montera quand même le `keytab` dans les pods toolbox, Sidekiq et Webservice, qui peuvent être utilisés avec les [paramètres OmniAuth](#omniauth) configurés manuellement pour Kerberos.

Vous pouvez fournir une configuration client Kerberos dans `global.appConfig.kerberos.krb5Config`.

```yaml
global:
  appConfig:
    kerberos:
      enabled: true
      keytab:
        secret: gitlab-kerberos-keytab
        key: keytab
      servicePrincipalName: ""
      krb5Config: |
        [libdefaults]
            default_realm = EXAMPLE.COM
      dedicatedPort:
        enabled: false
        port: 8443
        https: true
      simpleLdapLinkingAllowedRealms:
        - example.com
```

Consultez la [documentation Kerberos](https://docs.gitlab.com/integration/kerberos/) pour plus de détails.

### Port dédié pour Kerberos {#dedicated-port-for-kerberos}

GitLab prend en charge l'utilisation d'un [port dédié pour la négociation Kerberos](https://docs.gitlab.com/integration/kerberos/#http-git-access-with-kerberos-token-passwordless-authentication) lors de l'utilisation du protocole HTTP pour les opérations Git afin de contourner une limitation de Git qui revient à l'authentification de base lorsqu'il est présenté avec les en-têtes `negotiate` dans l'échange d'authentification.

L'utilisation du port dédié est actuellement requise lors de l'utilisation de GitLab CI/CD, car l'assistant GitLab Runner repose sur les informations d'identification dans l'URL pour cloner depuis GitLab.

Ceci peut être activé avec les paramètres `global.appConfig.kerberos.dedicatedPort` :

```yaml
global:
  appConfig:
    kerberos:
      [...]
      dedicatedPort:
        enabled: true
        port: 8443
        https: true
```

Cela active une URL de clone supplémentaire dans l'interface utilisateur de GitLab dédiée à la négociation Kerberos. Le paramètre `https: true` est uniquement destiné à la génération d'URL et n'expose pas de configuration TLS supplémentaire. TLS est terminé et configuré dans l'Ingress pour GitLab.

> [!note] En raison d'une limitation actuelle avec [notre fork du chart Helm `nginx-ingress`](nginx/_index.md) - la spécification d'un `dedicatedPort` n'exposera pas actuellement le port pour une utilisation dans le contrôleur `nginx-ingress` du chart. Les opérateurs de cluster devront exposer ce port eux-mêmes. Suivez [ce ticket du chart](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3531) pour plus de détails et des solutions de contournement potentielles.

### Domaines autorisés personnalisés LDAP {#ldap-custom-allowed-realms}

Le paramètre `global.appConfig.kerberos.simpleLdapLinkingAllowedRealms` peut être utilisé pour spécifier un ensemble de domaines utilisés pour lier les identités LDAP et Kerberos lorsque le DN LDAP d'un utilisateur ne correspond pas au domaine Kerberos de l'utilisateur. Consultez la [section Domaines autorisés personnalisés dans la documentation d'intégration Kerberos](https://docs.gitlab.com/integration/kerberos/#custom-allowed-realms) pour plus de détails.

## E-mail sortant {#outgoing-email}

La configuration des e-mails sortants est disponible via `global.smtp.*`, `global.appConfig.microsoft_graph_mailer.*` et `global.email.*`.

```yaml
global:
  email:
    display_name: 'GitLab'
    from: 'gitlab@example.com'
    reply_to: 'noreply@example.com'
  smtp:
    enabled: true
    address: 'smtp.example.com'
    tls: true
    authentication: 'plain'
    user_name: 'example'
    password:
      secret: 'smtp-password'
      key: 'password'
  appConfig:
    microsoft_graph_mailer:
      enabled: false
      user_id: "YOUR-USER-ID"
      tenant: "YOUR-TENANT-ID"
      client_id: "YOUR-CLIENT-ID"
      client_secret:
        secret:
        key: secret
      azure_ad_endpoint: "https://login.microsoftonline.com"
      graph_endpoint: "https://graph.microsoft.com"
```

Plus d'informations sur les options de configuration disponibles sont disponibles dans la [documentation sur les e-mails sortants](../installation/command-line-options.md#outgoing-email-configuration).

Des exemples plus détaillés sont disponibles dans la [documentation des paramètres SMTP du package Linux](https://docs.gitlab.com/omnibus/settings/smtp/).

## Plateforme {#platform}

La clé `platform` est réservée aux fonctionnalités spécifiques ciblant une plateforme particulière telle que GKE ou EKS.

## Affinité {#affinity}

La configuration de l'affinité est disponible via `global.antiAffinity` et `global.affinity`. L'affinité vous permet de contraindre les nœuds sur lesquels votre pod est éligible à être planifié, en fonction des labels des nœuds ou des labels des pods déjà en cours d'exécution sur un nœud. Cela permet de répartir les pods dans le cluster ou de sélectionner des nœuds spécifiques, assurant une meilleure résilience en cas de défaillance d'un nœud.

```yaml
global:
  antiAffinity: soft
  affinity:
    podAntiAffinity:
      topologyKey: "kubernetes.io/hostname"
```

| Nom                                   | Type   | Défaut                  | Description |
|:---------------------------------------|:-------|:-------------------------|:------------|
| `antiAffinity`                         | Chaîne | `soft`                   | Anti-affinité de pod à appliquer sur les pods. |
| `affinity.podAntiAffinity.topologyKey` | Chaîne | `kubernetes.io/hostname` | Clé de topologie d'anti-affinité de pod. |

- `global.antiAffinity` peut prendre deux valeurs :
  - `soft` : Définir une anti-affinité `preferredDuringSchedulingIgnoredDuringExecution` où le planificateur Kubernetes essaiera d'appliquer la règle mais ne garantira pas le résultat.
  - `hard` : Définir une anti-affinité `requiredDuringSchedulingIgnoredDuringExecution` où la règle doit être respectée pour qu'un pod soit planifié sur un nœud.
- `global.affinity.podAntiAffinity.topologyKey` définit un attribut de nœud utilisé pour les diviser en zones logiques. Les valeurs les plus courantes de `topologyKey` sont :
  - `kubernetes.io/hostname`
  - `topology.kubernetes.io/zone`
  - `topology.kubernetes.io/region`

Références Kubernetes sur [l'affinité et l'anti-affinité entre pods](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity).

## Priorité des pods et préemption {#pod-priority-and-preemption}

Les priorités des pods peuvent être configurées via `global.priorityClassName` ou par sous-chart via `priorityClassName`. La définition de la priorité des pods vous permet d'indiquer au planificateur d'expulser les pods de priorité inférieure pour rendre possible la planification des pods en attente.

```yaml
global:
  priorityClassName: system-cluster-critical
```

| Nom                | Type   | Défaut | Description |
|:--------------------|:-------|:--------|:------------|
| `priorityClassName` | Chaîne |         | Classe de priorité assignée aux pods. |

## Rotation des journaux {#log-rotation}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger/-/merge_requests/10) dans GitLab 15.6.

{{< /history >}}

Par défaut, le chart Helm GitLab ne fait pas tourner les journaux. Cela peut entraîner des problèmes de stockage éphémère pour les conteneurs qui s'exécutent pendant une longue période.

Pour activer la rotation des journaux, définissez la variable d'environnement `GITLAB_LOGGER_TRUNCATE_LOGS` sur `true`. Pour plus d'informations, consultez la [documentation de GitLab Logger](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger#configuration). En particulier, consultez les informations sur :

- [`GITLAB_LOGGER_TRUNCATE_INTERVAL`](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger#truncate-logs-interval).
- [`GITLAB_LOGGER_MAX_FILESIZE`](https://gitlab.com/gitlab-org/cloud-native/gitlab-logger#max-log-file-size).

## Jobs {#jobs}

À l'origine, les jobs dans GitLab étaient suffixés avec le Helm `.Release.Revision`, ce qui n'était pas idéal car cela entraînait toujours une mise à jour du job lors de l'exécution de `helm upgrade --install`, même si rien n'avait changé. Cela empêchait également le bon fonctionnement avec les workflows basés sur `helm template`, par exemple lors de l'utilisation d'ArgoCD. La décision d'utiliser le `.Release.Revision` dans le nom était basée sur les prémisses que le job ne pourrait être exécuté qu'une seule fois et que `helm uninstall` ne supprimerait pas les jobs, ce qui s'est avéré (désormais) incorrect.

Avec GitLab Helm chart 7.9 et versions ultérieures, les noms de jobs sont par défaut suffixés avec un hash basé sur la version d'application du chart et les valeurs du chart, qui peuvent également contenir le `global.gitlabVersion`. Cette approche garantit que les noms de jobs restent stables à travers plusieurs exécutions de `helm template` et `helm upgrade --install` (si rien n'a changé), et il est même possible de modifier les valeurs des champs immuables du job sans erreurs lors des déploiements (les jobs sont simplement remplacés par de nouveaux en raison des nouveaux noms).

Il est possible de remplacer le hash généré par défaut avec un suffixe personnalisé en définissant `global.job.nameSuffixOverride`. Le champ prend en charge le templating, il est donc possible de reproduire l'ancien comportement consistant à utiliser le `.Release.Revision` comme suffixe de nom :

```yaml
global:
  job:
    nameSuffixOverride: '{{ .Release.Revision }}'
```

Si vous souhaitez toujours déclencher intentionnellement un changement, par exemple parce que vous travaillez avec des tags flottants tels que `latest` pour toutes vos versions, vous pouvez remplacer le hash généré par défaut avec une valeur dynamique telle qu'un horodatage :

```yaml
global:
  job:
    nameSuffixOverride: '{{ dateInZone "2006-01-02-15-04-05" (now) "UTC" }}'
```

Vous pouvez également l'utiliser avec `helm` en ligne de commande :

```shell
helm <command> <options> --set global.job.nameSuffixOverride=$(date +%Y-%m-%d-%H-%M-%S)
```

| Nom                 | Type   | Défaut | Description |
|:---------------------|:-------|:--------|:------------|
| `nameSuffixOverride` | Chaîne |         | Suffixe personnalisé pour remplacer le hash généré automatiquement |

## Traefik {#traefik}

Les paramètres Traefik peuvent être configurés via `globals.traefik`.

```yaml
global:
  traefik:
    apiVersion: ""
```

| Nom         | Type   | Défaut | Description |
|:-------------|:-------|:--------|:------------|
| `apiVersion` | Chaîne |         | Remplace la valeur `apiVersion` par défaut des ressources Traefik |
