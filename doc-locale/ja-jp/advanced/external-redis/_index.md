---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部RedisでGitLabチャートを設定する
---

このドキュメントでは、外部RedisサービスでこのHelm Chartを設定する方法について説明します。

Redisを設定していない場合は、[Linuxを使用して、オンプレミスまたはへのを検討してください。](external-omnibus-redis.md)

現在サポートされているRedisの[インストール要件](https://docs.gitlab.com/install/requirements/#redis)の詳細については、こちらを参照してください。

## チャートを {#configure-the-chart}構成する

`redis`と、それが提供するRedisサービスを無効にして、他のサービスを外部サービスにポイントします。

次のパラメータを設定する必要があります。

- `redis.install`:`false`に設定して、Redisを含めないようにします。
- `global.redis.host`:外部Redisのホスト名に設定します。ドメインまたはアドレスを指定できます。
- `global.redis.auth.enabled`:外部Redisがパスワードを必要としない場合は、`false`に設定します。
- `global.redis.auth.secret`:[用のを含むの名前。](../../installation/secrets.md#redis-password)
- `global.redis.auth.key`:内の。これには、コンテンツが含まれています。

以下に示す項目は、を使用していない場合は、さらにカスタマイズできます。

- `global.redis.port`:データベースが利用可能なポートは、デフォルトで`6379`です。
- `global.redis.database`:Redisサーバーで接続するデータベースは、デフォルトで`0`です。

たとえば、これらの値をデプロイ時にHelmの`--set`フラグを介して渡します。

```shell
helm install gitlab gitlab/gitlab  \
  --set redis.install=false \
  --set global.redis.host=redis.example \
  --set global.redis.auth.secret=gitlab-redis \
  --set global.redis.auth.key=redis-password \
```

Sentinelサーバーが実行されているRedis HAクラスターに接続している場合、`global.redis.host`属性は、`sentinel.conf`で指定されているように、Redisインスタンスグループの名前（`mymaster`や`resque`など）に設定する必要があります。Redis masterのホスト名には設定しないでください。Sentinelサーバーは、`--set`フラグの`global.redis.sentinels[0].host`および`global.redis.sentinels[0].port`を使用して参照できます。インデックスはゼロから始まります。

## 複数のRedisインスタンスを {#use-multiple-redis-instances}使用する

は、複数のRedisにわたって、リソースを大量に消費するいくつかのRedisの分割をしています。このは、これらの永続クラスを他のRedisにすることをしています。

複数のRedisインスタンスを使用するための[チャート](../../charts/globals.md#multiple-redis-support)の設定に関する詳細については、[グローバル](../../charts/globals.md#multiple-redis-support)ドキュメントを参照してください。

## セキュアなRedisスキーム（SSL）を {#specify-secure-redis-scheme-ssl}指定する

SSLを使用してRedisに接続するには、`rediss`（二重の`s`に注意）スキームパラメータを使用します。

```shell
--set global.redis.scheme=rediss
```

## `redis.yml`をオーバーライド {#redisyml-override}

GitLab 15.8で導入された[`redis.yml`設定ファイル](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106854)のコンテンツをオーバーライドする場合は、`global.redis.redisYmlOverride`の下で値を定義することで実行できます。そのキーの下にあるすべての値とサブ値は、`redis.yml`にそのままレンダリングされます。

`global.redis.redisYmlOverride`は、外部Redisサービスで使用することを目的としています。`redis.install`を`false`に設定する必要があります。詳細については、[Redisをを参照してください。](../../charts/globals.md#configure-redis-settings)

例:

```yaml
redis:
  install: false
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

`/path/to/secret`に`THE SECRET`が含まれており、`/path/to/secret/raredis-override-password`に`RARE SECRET`が含まれていると仮定すると、次が`redis.yml`にレンダリングされます。

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

### 注意すべき点 {#things-to-look-out-for}

`redisYmlOverride`の柔軟性の裏側は、ユーザーフレンドリーでないことです。例:

1. `redis.yml`にパスワードを挿入するには、次のいずれかを実行します。
   - 既存の[パスワード定義](../../charts/globals.md#multiple-redis-support)を使用し、HelmにそれをERBステートメントに置き換えさせます。
   - コンテナでシークレットがマウントされているパスを使用して、正しいERB `<%= File.read('/path/to/secret').strip.to_json %>`ステートメントを自分で記述します。
1. `redisYmlOverride`では、 Railsのに従う必要があります。たとえば、「SharedState」インスタンスは`sharedState`と呼ばれず、`shared_state`と呼ばれます。
1. の継承はありません。たとえば、単一のSentinelセットを共有する3つのRedisがある場合は、Sentinelを3回繰り返す必要があります。
1. CNGイメージは、[有効な`resque.yml`と`cable.yml`を想定している](https://gitlab.com/gitlab-org/build/CNG/-/blob/4d314e505edb25ccefd4297d212bfbbb5bc562f9/gitlab-rails/scripts/lib/checks/redis.rb#L54)ため、`resque.yml`ファイルを取得するには、少なくとも`global.redis.host`を設定する必要があります。

## トラブルシューティング {#troubleshooting}

<!-- markdownlint-disable line-length -->

### `ERR Error running script (call to f_5962bd591b624c0e0afce6631ff54e7e4402ebd8): @user_script:7: ERR syntax error` {#err-error-running-script-call-to-f_5962bd591b624c0e0afce6631ff54e7e4402ebd8-user_script7-err-syntax-error}

Helm Chart 7.2以降で外部Redis 5を使用している場合、`webservice`および`sidekiq`ポッドのログにこのエラーが表示されることがあります。Redis 5 [はされていません。](https://docs.gitlab.com/install/requirements/#redis)

問題をするには、外部Redisを6.xにしてください。

<!-- markdownlint-enable line-length -->
