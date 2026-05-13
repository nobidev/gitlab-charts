---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 Redis를 사용하여 GitLab 차트 구성
---

외부 Redis 또는 Valkey 인스턴스를 사용하여 GitLab Helm 차트를 구성합니다. 이는 모든 배포에 필요합니다.

Redis가 구성되지 않은 경우, 온프레미스 또는 VM에 배포할 때 [Linux 패키지](external-omnibus-redis.md)를 사용하는 것을 고려하세요.

현재 지원되는 Redis 버전에 대한 자세한 내용은 [설치 시스템 요구 사항](https://docs.gitlab.com/install/requirements/#redis)을 참조하세요.

## 차트 구성 {#configure-the-chart}

다음 매개 변수를 설정해야 합니다:

- `global.redis.host`: 외부 Redis의 호스트 이름으로 설정하며, 도메인 또는 IP 주소일 수 있습니다.
- `global.redis.auth.enabled`: 외부 Redis에 암호가 필요하지 않은 경우 `false`로 설정합니다.
- `global.redis.auth.secret`: [인증을 위한 토큰이 포함된 시크릿](../../installation/secrets.md#redis-password)의 이름입니다.
- `global.redis.auth.key`: 토큰 내용이 포함된 시크릿의 키입니다.

기본값을 사용하지 않는 경우 아래 항목을 추가로 사용자 지정할 수 있습니다:

- `global.redis.port`: 데이터베이스를 사용할 수 있는 포트는 기본값이 `6379`입니다.
- `global.redis.database`: Redis 서버에서 연결할 데이터베이스는 기본값이 `0`입니다.

예를 들어, 배포할 때 Helm의 `--set` 플래그를 통해 이러한 값을 전달합니다:

```shell
helm install gitlab gitlab/gitlab  \
  --set global.redis.host=redis.example \
  --set global.redis.auth.secret=gitlab-redis \
  --set global.redis.auth.key=redis-password \
```

Sentinel 서버가 실행 중인 Redis HA 클러스터에 연결하는 경우, `global.redis.host` 속성을 Redis 인스턴스 그룹의 이름(예: `mymaster` 또는 `resque`)으로 설정해야 합니다. `sentinel.conf`에 지정된 대로 설정하되, Redis 마스터의 호스트 이름으로 설정하지 않습니다. Sentinel 서버는 `global.redis.sentinels[0].host` 및 `global.redis.sentinels[0].port` 값을 사용하여 `--set` 플래그로 참조할 수 있습니다. 인덱스는 0부터 시작합니다.

## 여러 Redis 인스턴스 사용 {#use-multiple-redis-instances}

GitLab은 리소스 집약적인 여러 Redis 작업을 여러 Redis 인스턴스에 분산하도록 지원합니다. 이 차트는 해당 지속성 클래스를 다른 Redis 인스턴스에 분산하도록 지원합니다.

여러 Redis 인스턴스를 사용하기 위한 차트 구성에 대한 자세한 정보는 [globals](../../charts/globals.md#multiple-redis-support) 설명서에서 찾을 수 있습니다.

## 보안 Redis 스킴 지정 (SSL) {#specify-secure-redis-scheme-ssl}

SSL을 사용하여 Redis에 연결하려면 `rediss`(더블 `s` 주의) 스킴 매개 변수를 사용하세요:

```shell
--set global.redis.scheme=rediss
```

### Redis TLS 인증서 구성 {#configure-redis-tls-certificates}

Redis TLS 인증서를 구성하려면 [globals 설명서](../../charts/globals.md#redis-tls-configuration)를 읽으세요.

## `redis.yml` 재정의 {#redisyml-override}

[GitLab 15.8에서 도입된 `redis.yml` 구성 파일](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/106854)의 내용을 재정의하려면 `global.redis.redisYmlOverride` 아래에 값을 정의하여 이렇게 할 수 있습니다. 해당 키 아래의 모든 값 및 하위 값은 `redis.yml`로 그대로 렌더링됩니다.

`global.redis.redisYmlOverride` 설정은 외부 Redis 서비스와 함께 사용하기 위한 것입니다. 자세한 내용은 [Redis 설정 구성](../../charts/globals.md#configure-redis-settings)을 참조하세요.

예:

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

`/path/to/secret`에 `THE SECRET`이 포함되어 있고 `/path/to/secret/raredis-override-password`에 `RARE SECRET`이 포함되어 있다고 가정하면, 이는 `redis.yml`에서 다음과 같이 렌더링되도록 합니다:

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

### 주의할 사항 {#things-to-look-out-for}

`redisYmlOverride`의 유연성의 단점은 사용자 친화적이지 않다는 것입니다. 예를 들어:

1. `redis.yml`에 암호를 삽입하려면 다음 중 하나를 수행할 수 있습니다:
   - 기존 [암호 정의](../../charts/globals.md#multiple-redis-support)를 사용하고 Helm이 ERB 문으로 바꾸도록 하세요.
   - 올바른 ERB `<%= File.read('/path/to/secret').strip.to_json %>` 문을 작성하고, 시크릿이 컨테이너에서 마운트된 경로를 사용하세요.
1. `redisYmlOverride`에서 GitLab Rails의 명명 규칙을 따라야 합니다. 예를 들어, "SharedState" 인스턴스는 `sharedState`이 아니라 `shared_state`라고 부릅니다.
1. 구성 값의 상속이 없습니다. 예를 들어, 세 개의 Redis 인스턴스가 단일 Sentinel 세트를 공유하는 경우 Sentinel 구성을 세 번 반복해야 합니다.
1. CNG 이미지는 [`resque.yml` 및 `cable.yml`가 유효](https://gitlab.com/gitlab-org/build/CNG/-/blob/4d314e505edb25ccefd4297d212bfbbb5bc562f9/gitlab-rails/scripts/lib/checks/redis.rb#L54)하기를 기대하므로, `resque.yml` 파일을 얻기 위해 최소한 `global.redis.host`을 구성해야 합니다.

## 문제 해결 {#troubleshooting}

### 오류: `ERR Error running script (...): @user_script:7: ERR syntax error` {#error-err-error-running-script--user_script7-err-syntax-error}

Helm 차트 7.2 이상에서 외부 Redis 5를 사용하는 경우 `webservice` 및 `sidekiq` 포드의 로그에서 다음 오류가 표시될 수 있습니다. Redis 5 [는 지원되지 않습니다](https://docs.gitlab.com/install/requirements/#redis).

- `ERR Error running script (call to f_5962bd591b624c0e0afce6631ff54e7e4402ebd8): @user_script:7: ERR syntax error`

이를 해결하려면 외부 Redis 인스턴스를 6.x 이상으로 업그레이드합니다.
