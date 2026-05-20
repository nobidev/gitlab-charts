---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer le chart GitLab avec un Redis externe
---

Configurez le chart Helm de GitLab avec une instance Redis ou Valkey externe, requise pour tous les déploiements.

Si vous n'avez pas Redis configuré, pour une installation sur site ou un déploiement sur VM, envisagez d'utiliser notre [package Linux](external-omnibus-redis.md).

Pour plus d'informations sur les versions Redis actuellement prises en charge, consultez [Configuration requise pour l'installation](https://docs.gitlab.com/install/requirements/#redis).

## Configurer le chart {#configure-the-chart}

Vous devez définir les paramètres suivants :

- `global.redis.host` : À définir avec le nom d'hôte du Redis externe ; peut être un domaine ou une adresse IP.
- `global.redis.auth.enabled` : À définir sur `false` si le Redis externe ne nécessite pas de mot de passe.
- `global.redis.auth.secret` : Le nom du [secret contenant le jeton d'accès personnel d'authentification](../../installation/secrets.md#redis-password).
- `global.redis.auth.key` : La clé dans le secret, qui contient le contenu du jeton.

Les éléments ci-dessous peuvent être davantage personnalisés si vous n'utilisez pas les valeurs par défaut :

- `global.redis.port` : Le port sur lequel la base de données est disponible, par défaut `6379`.
- `global.redis.database` : La base de données à laquelle se connecter sur le serveur Redis, par défaut `0`.

Par exemple, transmettez ces valeurs via l'indicateur `--set` de Helm lors du déploiement :

```shell
helm install gitlab gitlab/gitlab  \
  --set global.redis.host=redis.example \
  --set global.redis.auth.secret=gitlab-redis \
  --set global.redis.auth.key=redis-password \
```

Si vous vous connectez à un cluster Redis HA doté de serveurs Sentinel, l'attribut `global.redis.host` doit être défini sur le nom du groupe d'instances Redis (tel que `mymaster` ou `resque`), tel que spécifié dans le `sentinel.conf`, et non sur le nom d'hôte du maître Redis. Les serveurs Sentinel peuvent être référencés à l'aide des valeurs `global.redis.sentinels[0].host` et `global.redis.sentinels[0].port` pour l'indicateur `--set`. L'index est basé sur zéro.

## Utiliser plusieurs instances Redis {#use-multiple-redis-instances}

GitLab prend en charge la répartition de plusieurs opérations Redis gourmandes en ressources sur plusieurs instances Redis. Ce chart prend en charge la distribution de ces classes de persistance vers d'autres instances Redis.

Des informations plus détaillées sur la configuration du chart pour l'utilisation de plusieurs instances Redis sont disponibles dans la documentation [globals](../../charts/globals.md#multiple-redis-support).

## Spécifier le schéma Redis sécurisé (SSL) {#specify-secure-redis-scheme-ssl}

Pour vous connecter à Redis via SSL, utilisez le paramètre de schéma `rediss` (notez le double `s`) :

```shell
--set global.redis.scheme=rediss
```

### Configurer les certificats TLS Redis {#configure-redis-tls-certificates}

Pour configurer les certificats TLS Redis, consultez la [documentation globals](../../charts/globals.md#redis-tls-configuration).

## Remplacement de `redis.yml` {#redisyml-override}

Si vous souhaitez remplacer le contenu du [fichier de configuration `redis.yml` introduit dans GitLab 15.8](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106854), vous pouvez le faire en définissant des valeurs sous `global.redis.redisYmlOverride`. Toutes les valeurs et sous-valeurs sous cette clé seront rendues dans `redis.yml` telles quelles.

Le paramètre `global.redis.redisYmlOverride` est destiné à être utilisé avec des services Redis externes. Consultez [configurer les paramètres Redis](../../charts/globals.md#configure-redis-settings) pour plus de détails.

Exemple :

```yaml
global:
  redis:
    redisYmlOverride:
      raredis:
        host: rare-redis.example.com:6379
        password:
          enabled: true
          secret: secretname
          key: password
      exotic_redis:
        host: redis.example.com:6379
        password: <%= File.read('/path/to/secret').strip.to_json %>
      mystery_setting:
        deeply:
          nested: value
```

En supposant que `/path/to/secret` contient `THE SECRET` et que `/path/to/secret/raredis-override-password` contient `RARE SECRET`, cela entraînera le rendu suivant dans `redis.yml` :

```yaml
production:
  raredis:
    host: rare-redis.example.com:6379
    password: "RARE SECRET"
  exotic_redis:
    host: redis.example.com:6379
    password: "THE SECRET"
  mystery_setting:
    deeply:
      nested: value
```

### Points à surveiller {#things-to-look-out-for}

L'inconvénient de la flexibilité de `redisYmlOverride` est qu'il est moins convivial. Par exemple :

1. Pour insérer des mots de passe dans `redis.yml`, vous pouvez soit :
   - Utiliser la [définition de mot de passe](../../charts/globals.md#multiple-redis-support) existante et laisser Helm la remplacer par une instruction ERB.
   - Écrire vous-même les instructions ERB `<%= File.read('/path/to/secret').strip.to_json %>` correctes, en utilisant le chemin auquel le secret est monté dans le conteneur.
1. Dans `redisYmlOverride`, vous devez respecter les conventions de nommage de GitLab Rails. Par exemple, l'instance « SharedState » ne s'appelle pas `sharedState` mais `shared_state`.
1. Il n'y a pas d'héritage des valeurs de configuration. Par exemple, si vous avez trois instances Redis partageant un même ensemble de Sentinels, vous devez répéter la configuration Sentinel trois fois.
1. Les images CNG [attendent un `resque.yml` et un `cable.yml` valides](https://gitlab.com/gitlab-org/build/CNG/-/blob/4d314e505edb25ccefd4297d212bfbbb5bc562f9/gitlab-rails/scripts/lib/checks/redis.rb#L54), vous devez donc encore configurer au minimum `global.redis.host` pour obtenir un fichier `resque.yml`.

## Dépannage {#troubleshooting}

### Erreur : `ERR Error running script (...): @user_script:7: ERR syntax error` {#error-err-error-running-script--user_script7-err-syntax-error}

Vous pourriez voir l'erreur suivante dans les journaux des pods `webservice` et `sidekiq` si vous utilisez Redis 5 externe avec le chart Helm 7.2 ou ultérieur. Redis 5 [n'est pas pris en charge](https://docs.gitlab.com/install/requirements/#redis).

- `ERR Error running script (call to f_5962bd591b624c0e0afce6631ff54e7e4402ebd8): @user_script:7: ERR syntax error`

Pour corriger ce problème, mettez à niveau votre instance Redis externe vers la version 6.x ou ultérieure.
