---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser le chart GitLab-Migrations
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le sous-chart `migrations` fournit un [job](https://kubernetes.io/docs/concepts/workloads/controllers/job/) de migration unique qui gère l'initialisation et la migration des bases de données utilisées par GitLab. Le chart s'exécute à l'aide de la base de code GitLab Rails.

Si [ClickHouse](../../../development/clickhouse.md) est activé, ce sous-chart exécute également les migrations pour [ClickHouse](../../../development/clickhouse.md).

Après la migration, ce job modifie également les paramètres de l'application dans la base de données pour désactiver les [écritures dans le fichier de clés autorisées](https://docs.gitlab.com/administration/operations/fast_ssh_key_lookup/#setting-up-fast-lookup-via-gitlab-shell). Dans les charts, nous ne prenons en charge que l'utilisation de l'API GitLab Authorized Keys avec le SSH `AuthorizedKeysCommand` au lieu de la prise en charge de l'écriture dans un fichier de clés autorisées.

## Prérequis {#requirements}

Ce chart dépend de Redis et de PostgreSQL, soit dans le cadre du chart GitLab complet, soit fournis en tant que services externes accessibles depuis le cluster Kubernetes sur lequel ce chart est déployé.

Si ClickHouse est activé pour une installation, ce chart dépend également de ClickHouse.

## Choix de conception {#design-choices}

Le chart `migrations` crée un nouveau [job](https://kubernetes.io/docs/concepts/workloads/controllers/job/) de migrations à chaque installation du chart, ou lors de la mise à niveau du chart avec une nouvelle [version de chart](https://helm.sh/docs/topics/charts/#charts-and-versioning) , [appVersion](https://helm.sh/docs/topics/charts/#the-appversion-field), ou une modification de l'une des valeurs.

Lors de l'utilisation de `helm install` et de `helm upgrade` pour installer et mettre à niveau ce chart, les jobs créés par ce chart resteront en tant qu'objets dans le cluster jusqu'à la prochaine mise à niveau du chart. Cela nous permet d'observer les logs de migration. Une fois qu'une forme d'expédition de logs sera en place, nous pourrons reconsidérer la persistance de ces objets.

Si des déploiements sont effectués à l'aide de manifestes générés par `helm template` et `kubectl apply` ou des outils similaires, les anciens objets de job de migration ne sont pas supprimés du cluster.

Le conteneur utilisé dans ce chart présente quelques optimisations supplémentaires que nous n'utilisons pas actuellement ici. Principalement, la capacité à ignorer rapidement l'exécution des migrations si elles sont déjà à jour, sans avoir besoin de démarrer l'application Rails pour vérifier. Cette optimisation nécessite que nous persistions le statut de migration. Ce que nous ne faisons pas avec ce chart pour le moment. À l'avenir, nous introduirons la prise en charge du stockage du statut des migrations dans ce chart.

## Configuration {#configuration}

Le chart `migrations` est configuré en deux parties : les services externes et les paramètres du chart.

## Options de ligne de commande d'installation {#installation-command-line-options}

Le tableau ci-dessous contient toutes les configurations de charts possibles qui peuvent être fournies à la commande `helm install` à l'aide des indicateurs `--set`

| Paramètre                                                | Défaut                                                      | Description |
|----------------------------------------------------------|--------------------------------------------------------------|-------------|
| `common.labels`                                          | `{}`                                                         | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee` | Dépôt d'images Migrations |
| `image.tag`                                              |                                                              | Tag d'image Migrations |
| `image.pullPolicy`                                       | `Always`                                                     | Politique de récupération Migrations |
| `image.pullSecrets`                                      |                                                              | Secrets pour le dépôt d'images |
| `init.image.repository`                                  | `registry.gitlab.com/gitlab-org/build/cng/gitlab-base`       | Dépôt d'images `initContainer` |
| `init.image.tag`                                         | `master`                                                     | Tag d'image `initContainer` |
| `init.image.containerSecurityContext`                    | `{}`                                                         | Remplacements `initContainer` `securityContext` |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                      | Spécifique à `initContainer` :  Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                       | Spécifique à `initContainer` :  Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                                  | Spécifique à `initContainer` :  Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur |
| `enabled`                                                | `true`                                                       | Indicateur d'activation des migrations |
| `tolerations`                                            | `[]`                                                         | Labels de tolérance pour l'affectation des pods |
| `affinity`                                               | `{}`                                                         | [Règles d'affinité](../_index.md#affinity) pour l'affectation des pods |
| `annotations`                                            | `{}`                                                         | Annotations pour la spécification du job |
| `podAnnotations`                                         | `{}`                                                         | Annotations pour la spécification du pod |
| `podLabels`                                              |                                                              | Labels de pod supplémentaires. Ne sera pas utilisé pour les sélecteurs. |
| `psql.password.secret`                                   | `gitlab-postgres`                                            | Secret `psql` |
| `psql.password.key`                                      | `psql-password`                                              | Clé du mot de passe `psql` dans le secret `psql` |
| `psql.port`                                              |                                                              | Définit le port du serveur PostgreSQL. A la priorité sur `global.psql.port` |
| `resources.requests.cpu`                                 | `250m`                                                       | CPU minimum pour GitLab Migrations |
| `resources.requests.memory`                              | `200Mi`                                                      | Mémoire minimum pour GitLab Migrations |
| `securityContext.fsGroup`                                | `1000`                                                       | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.runAsUser`                              | `1000`                                                       | ID utilisateur sous lequel le pod doit être démarré |
| `securityContext.fsGroupChangePolicy`                    |                                                              | Politique de changement de propriété et d'autorisation du volume (nécessite Kubernetes 1.23) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                             | Profil Seccomp à utiliser |
| `containerSecurityContext.runAsUser`                     | `1000`                                                       | Remplace le [`securityContext`](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel le conteneur est démarré |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                      | Contrôle si un processus du conteneur peut obtenir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                       | Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                                  | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `serviceAccount.annotations`                             | `{}`                                                         | Annotations ServiceAccount |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                      | Indique si le token d'accès ServiceAccount par défaut doit être monté dans les pods |
| `serviceAccount.create`                                  | `false`                                                      | Indique si un ServiceAccount doit être créé |
| `serviceAccount.enabled`                                 | `false`                                                      | Indique si un ServiceAccount doit être utilisé |
| `serviceAccount.name`                                    |                                                              | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé |
| `extraInitContainers`                                    |                                                              | Liste de conteneurs init supplémentaires à inclure |
| `extraContainers`                                        |                                                              | Chaîne de style littéral multiligne contenant une liste de conteneurs à inclure |
| `extraVolumes`                                           |                                                              | Liste de volumes supplémentaires à créer |
| `extraVolumeMounts`                                      |                                                              | Liste de montages de volumes supplémentaires à effectuer |
| `extraEnv`                                               |                                                              | Liste de variables d'environnement supplémentaires à exposer |
| `extraEnvFrom`                                           |                                                              | Liste de variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| `priorityClassName`                                      |                                                              | [Classe de priorité](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) assignée aux pods. |

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

`extraEnvFrom` vous permet d'exposer des variables d'environnement supplémentaires provenant d'autres sources de données dans tous les conteneurs des pods.

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
  CONFIG_STRING:
    configMapKeyRef:
      name: useful-config
      key: some-string
      # optional: boolean
```

### `image.pullSecrets` {#imagepullsecrets}

`pullSecrets` vous permet de vous authentifier auprès d'un registre privé pour récupérer des images pour un pod.

Des informations supplémentaires sur les registres privés et leurs méthodes d'authentification sont disponibles dans [la documentation Kubernetes](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Voici un exemple d'utilisation de `pullSecrets` :

```yaml
image:
  repository: my.migrations.repository
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

Cette section contrôle si un ServiceAccount doit être créé et si le token d'accès par défaut doit être monté dans les pods.

| Nom                           |  Type   | Défaut | Description |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   Map   | `{}`    | Annotations ServiceAccount. |
| `automountServiceAccountToken` | Boolean | `false` | Contrôle si le token d'accès ServiceAccount par défaut doit être monté dans les pods. Vous ne devriez pas activer cela sauf si cela est requis par certains sidecars pour fonctionner correctement (par exemple, Istio). |
| `create`                       | Boolean | `false` | Indique si un ServiceAccount doit être créé. |
| `enabled`                      | Boolean | `false` | Indique si un ServiceAccount doit être utilisé. |
| `name`                         | String  |         | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé. |

### `affinity` {#affinity}

Pour plus d'informations, voir [`affinity`](../_index.md#affinity).

## Utiliser la Community Edition de ce chart {#using-the-community-edition-of-this-chart}

Par défaut, les charts Helm utilisent l'Enterprise Edition de GitLab. Si vous le souhaitez, vous pouvez utiliser la Community Edition à la place. En savoir plus sur la [différence entre les deux](https://about.gitlab.com/install/ce-or-ee/).

Pour utiliser la Community Edition, définissez `image.repository` sur `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ce`

## Services externes {#external-services}

### Redis {#redis}

```yaml
redis:
  host: redis.example.com
  port: 6379
  sentinels:
    - host: sentinel1.example.com
      port: 26379
  password:
    secret: gitlab-redis
    key: redis-password
```

#### `host` {#host}

Le nom d'hôte du serveur Redis avec la base de données à utiliser. Si vous utilisez des Redis Sentinels, l'attribut `host` doit être défini sur le nom du cluster tel que spécifié dans le fichier `sentinel.conf`.

#### `port` {#port}

Le port sur lequel se connecter au serveur Redis. La valeur par défaut est `6379`.

#### `password` {#password}

L'attribut `password` pour Redis possède deux sous-clés :

- `secret` définit le nom du `Secret` Kubernetes à partir duquel récupérer
- `key` définit le nom de la clé dans le secret ci-dessus qui contient le mot de passe.

#### `sentinels` {#sentinels}

L'attribut `sentinels` permet une connexion à un cluster Redis HA. Les sous-clés décrivent chaque connexion Sentinel.

- `host` définit le nom d'hôte pour le service Sentinel
- `port` définit le numéro de port pour atteindre le service Sentinel, la valeur par défaut est `26379`

### PostgreSQL {#postgresql}

```yaml
psql:
  host: psql.example.com
  port: 5432
  database: gitlabhq_production
  username: gitlab
  preparedStatements: false
  password:
    secret: gitlab-postgres
    key: psql-password
```

#### `host` {#host-1}

Le nom d'hôte du serveur PostgreSQL avec la base de données à utiliser.

#### `port` {#port-1}

Le port sur lequel se connecter au serveur PostgreSQL. La valeur par défaut est `5432`.

#### `database` {#database}

Le nom de la base de données à utiliser sur le serveur PostgreSQL. La valeur par défaut est `gitlabhq_production`.

#### `preparedStatements` {#preparedstatements}

Indique si des instructions préparées doivent être utilisées lors de la communication avec le serveur PostgreSQL. La valeur par défaut est `false`.

#### `username` {#username}

Le nom d'utilisateur avec lequel s'authentifier auprès de la base de données. La valeur par défaut est `gitlab`

#### `password` {#password-1}

L'attribut `password` pour PostgreSQL possède deux sous-clés :

- `secret` définit le nom du `Secret` Kubernetes à partir duquel récupérer.
- `key` définit le nom de la clé dans le secret ci-dessus qui contient le mot de passe.

### ClickHouse (optionnel) {#clickhouse-optional}

``` yaml
global:
  clickhouse:
    enabled: true
    main:
      url: https://clickhouse.example.com
      database: default
      username: default
      password:
        secret: gitlab-clickhouse-password
        key: main_password
```

Si ClickHouse est activé pour une installation, ce Chart exécutera également les migrations pour la base de données ClickHouse. La configuration de ClickHouse doit être fournie sous la clé `global.clickhouse`.

#### `main.url` {#mainurl}

URL de l'instance ClickHouse.

#### `main.database` {#maindatabase}

Nom de la base de données dans ClickHouse.

#### `main.username` {#mainusername}

Nom d'utilisateur à utiliser pour s'authentifier dans ClickHouse.

#### `main.password` {#mainpassword}

L'attribut `password` pour ClickHouse contient deux sous-clés :

- `secret` définit le nom du secret Kubernetes à partir duquel récupérer.
- `key` définit le nom de la clé dans le `secret` ci-dessus qui contient le mot de passe.
