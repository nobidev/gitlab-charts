---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트의 비밀 구성
---

{{< details >}}

- 계층:  무료, 프리미엄, 궁극의
- 제공:  GitLab 자체 관리

{{< /details >}}

GitLab이 작동하려면 다양한 비밀이 필요합니다:

GitLab 구성 요소:

- 레지스트리 인증 인증서
- GitLab Shell용 SSH 호스트 키 및 인증서
- 개별 GitLab 서비스의 암호
- GitLab Pages용 TLS 인증서

선택 외부 서비스:

- SMTP 서버
- LDAP
- OmniAuth
- 수신 이메일용 IMAP (mail_room 서비스 경유)
- Service Desk 이메일용 IMAP (mail_room 서비스 경유)
- 수신 이메일용 Microsoft Graph와 OAuth2 (mail_room 서비스 경유)
- Service Desk 이메일용 Microsoft Graph와 OAuth2 (mail_room 서비스 경유)
- 발신 이메일용 Microsoft Graph와 OAuth2
- S/MIME 인증서
- 스마트카드 인증
- OAuth 통합

수동으로 제공되지 않은 모든 비밀은 임의의 값으로 자동 생성됩니다. HTTPS 인증서의 자동 생성은 Let's Encrypt에서 제공합니다.

자동 생성된 비밀을 사용하려면 [다음 단계](#next-steps)로 계속하세요.

자신의 비밀을 지정하려면 [수동 비밀 생성](#manual-secret-creation-optional)으로 진행하세요.

## 수동 비밀 생성 (선택 사항) {#manual-secret-creation-optional}

이 설명서의 이전 단계를 따른 경우 `gitlab`을(를) 릴리스 이름으로 사용하세요.

- [TLS 인증서](tls.md)
- [레지스트리 인증 인증서](#registry-authentication-certificates)
- [레지스트리 민감한 알림 헤더](#registry-sensitive-notification-headers)
- [SSH 호스트 키](#ssh-host-keys)
- 암호:
  - [초기 루트 암호](#initial-root-password)
  - [Redis 암호](#redis-password)
  - [GitLab Shell 비밀](#gitlab-shell-secret)
  - [Gitaly 비밀](#gitaly-secret)
  - [Praefect 비밀](#praefect-secret)
  - [GitLab Rails 비밀](#gitlab-rails-secret)
  - [GitLab Workhorse 비밀](#gitlab-workhorse-secret)
  - [GitLab Runner 비밀](#gitlab-runner-secret)
  - [PostgreSQL 암호](#postgresql-password)
  - [Praefect DB 암호](#praefect-db-password)
  - [MinIO 비밀](#minio-secret)
  - [레지스트리 HTTP 비밀](#registry-http-secret)
  - [레지스트리 알림 비밀](#registry-notification-secret)
  - [GitLab Pages 비밀](#gitlab-pages-secret)
  - [GitLab 수신 이메일 인증 토큰](#gitlab-incoming-email-auth-token)
  - [GitLab Service Desk 이메일 인증 토큰](#gitlab-service-desk-email-auth-token)
  - [Zoekt 인덱서 내부 API 비밀](#zoekt-indexer-internal-api-secret)
- [외부 서비스](#external-services)
  - [OmniAuth](#omniauth)
  - [LDAP 암호](#ldap-password)
  - [SMTP 암호](#smtp-password)
  - [수신 이메일용 IMAP 암호](#imap-password-for-incoming-emails)
  - [Service Desk용 IMAP 암호](#imap-password-for-service-desk-emails)
  - [수신 이메일용 Microsoft Graph 클라이언트 비밀](#microsoft-graph-client-secret-for-incoming-emails)
  - [Service Desk용 Microsoft Graph 클라이언트 비밀](#microsoft-graph-client-secret-for-service-desk-emails)
  - [발신 이메일용 Microsoft Graph 클라이언트 비밀](#microsoft-graph-client-secret-for-outgoing-emails)
  - [S/MIME 인증서](#smime-certificate)
  - [스마트카드 인증](#smartcard-authentication)

### 레지스트리 인증 인증서 {#registry-authentication-certificates}

GitLab과 레지스트리 간의 통신은 Ingress 뒤에서 발생하므로 대부분의 경우 이 통신을 위해 자체 서명된 인증서를 사용하는 것으로 충분합니다. 이 트래픽이 네트워크를 통해 노출되는 경우 공개적으로 유효한 인증서를 생성해야 합니다.

아래 예시에서는 자체 서명된 인증서가 필요하다고 가정합니다.

인증서-키 쌍 생성:

```shell
mkdir -p certs
openssl req -new -newkey rsa:4096 -subj "/CN=gitlab-issuer" -nodes -x509 -keyout certs/registry-example-com.key -out certs/registry-example-com.crt
```

이 인증서를 포함하는 비밀을 생성합니다. `registry-auth.key` 및 `registry-auth.crt` 키를 `<name>-registry-secret` 비밀 내에 생성합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-registry-secret --from-file=registry-auth.key=certs/registry-example-com.key --from-file=registry-auth.crt=certs/registry-example-com.crt
```

이 비밀은 `global.registry.certificate.secret` 설정에서 참조됩니다.

### 레지스트리 민감한 알림 헤더 {#registry-sensitive-notification-headers}

더 많은 정보는 [레지스트리 알림 구성에 관한 설명서](../charts/globals.md#configure-registry-settings)를 확인하세요.

비밀 내용은 단일 항목만 포함하더라도 항목 목록이어야 합니다. 내용이 문자열인 경우 차트는 **WILL NOT** 목록으로 변환하지 않습니다.

`registry-authorization-header` 비밀이 `RandomFooBar` 값으로 생성되는 예를 생각해봅시다.

```shell
kubectl create secret generic registry-authorization-header --from-literal=value="[RandomFooBar]"
```

기본적으로 비밀 내에서 사용되는 키는 "value"입니다. 그러나 사용자는 다른 키를 사용할 수 있지만 헤더 맵 항목 아래에 `key`으로 지정되어 있는지 확인해야 합니다.

### SSH 호스트 키 {#ssh-host-keys}

OpenSSH 인증서-키 쌍을 생성합니다:

```shell
mkdir -p hostKeys
ssh-keygen -t rsa  -f hostKeys/ssh_host_rsa_key -N ""
ssh-keygen -t ecdsa  -f hostKeys/ssh_host_ecdsa_key -N ""
ssh-keygen -t ed25519  -f hostKeys/ssh_host_ed25519_key -N ""
```

이 인증서를 포함하는 비밀을 생성합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-gitlab-shell-host-keys --from-file hostKeys
```

이 비밀은 `global.shell.hostKeys.secret` 설정에서 참조됩니다.

이 비밀이 회전하면 모든 SSH 클라이언트에 `hostname mismatch` 오류가 표시됩니다.

### 초기 엔터프라이즈 라이선스 {#initial-enterprise-license}

> [!warning] 이 방법은 설치 시에만 라이선스를 추가합니다. 웹 사용자 인터페이스의 관리자 영역을 사용하여 라이선스를 갱신하거나 업그레이드합니다.

GitLab 인스턴스의 엔터프라이즈 라이선스를 저장할 Kubernetes 비밀을 생성합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-gitlab-license --from-file=license=/tmp/license.gitlab
```

그런 다음 `--set global.gitlab.license.secret=<name>-gitlab-license`을(를) 사용하여 라이선스를 구성에 주입합니다.

또한 `global.gitlab.license.key` 옵션을 사용하여 라이선스 비밀의 라이선스를 가리키는 기본 `license` 키를 변경할 수 있습니다.

### 초기 루트 암호 {#initial-root-password}

초기 루트 암호를 저장할 Kubernetes 비밀을 생성합니다. 암호는 최소 6자 이상이어야 합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-gitlab-initial-root-password --from-literal=password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)
```

### Redis 암호 {#redis-password}

Redis용 무작위 64자 영숫자 암호를 생성합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-redis-secret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

이미 존재하는 Redis 클러스터로 배포하는 경우 무작위로 생성된 암호 대신 base64로 인코딩된 Redis 클러스터에 액세스하기 위한 암호를 사용하세요.

이 비밀은 `global.redis.auth.secret` 설정에서 참조됩니다.

### GitLab Shell 비밀 {#gitlab-shell-secret}

GitLab Shell용 무작위 64자 영숫자 비밀을 생성합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-gitlab-shell-secret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

이 비밀은 `global.shell.authToken.secret` 설정에서 참조됩니다.

### Gitaly 비밀 {#gitaly-secret}

Gitaly용 무작위 64자 영숫자 토큰을 생성합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-gitaly-secret --from-literal=token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

이 비밀은 `global.gitaly.authToken.secret` 설정에서 참조됩니다.

### Praefect 비밀 {#praefect-secret}

Praefect용 무작위 64자 영숫자 토큰을 생성합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다:

```shell
kubectl create secret generic <name>-praefect-secret --from-literal=token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

이 비밀은 `global.praefect.authToken.secret` 설정에서 참조됩니다.

### GitLab Rails 비밀 {#gitlab-rails-secret}

{{< history >}}

- `active_record_encryption_*` 키는 [GitLab 17.8](../releases/8_0.md#upgrade-to-880)에서 추가되었습니다.

{{< /history >}}

`<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
cat << EOF > secrets.yml
production:
  secret_key_base: $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-f0-9' | head -c 128)
  otp_key_base: $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-f0-9' | head -c 128)
  db_key_base: $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-f0-9' | head -c 128)
  encrypted_settings_key_base: $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-f0-9' | head -c 128)
  openid_connect_signing_key: |
$(openssl genrsa 2048 | awk '{print "    " $0}')
  active_record_encryption_primary_key:
    - $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)
  active_record_encryption_deterministic_key:
    - $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)
  active_record_encryption_key_derivation_salt: $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)
EOF

kubectl create secret generic <name>-rails-secret --from-file=secrets.yml
```

이 비밀은 `global.railsSecrets.secret` 설정에서 참조됩니다.

이 비밀은 데이터베이스 암호화 키를 포함하고 있으므로 회전을 권장하지 않습니다. 비밀이 회전하면 [비밀 파일이 손실](https://docs.gitlab.com/administration/backup_restore/troubleshooting_backup_gitlab/#when-the-secrets-file-is-lost)되었을 때 나타나는 동일한 동작이 나타납니다.

### GitLab Workhorse 비밀 {#gitlab-workhorse-secret}

workhorse 비밀을 생성합니다. 이는 32자 길이이고 base64로 인코딩되어야 합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-gitlab-workhorse-secret --from-literal=shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

이 비밀은 `global.workhorse.secret` 설정에서 참조됩니다.

### GitLab Runner 비밀 {#gitlab-runner-secret}

`<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-gitlab-runner-secret --from-literal=runner-registration-token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

이 비밀은 `gitlab-runner.runners.secret` 설정에서 참조됩니다.

### GitLab KAS 비밀 {#gitlab-kas-secret}

GitLab Rails는 KAS 부분 차트를 설치하지 않고 이 차트를 배포하는 경우에도 KAS에 대한 비밀이 있어야 합니다. 그래도 아래 절차를 따라 이 비밀을 수동으로 생성하거나 차트가 비밀을 자동 생성하도록 할 수 있습니다.

`<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-gitlab-kas-secret --from-literal=kas_shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

이 비밀은 `global.appConfig.gitlab_kas.secret` 설정에서 참조됩니다.

### GitLab KAS API 비밀 {#gitlab-kas-api-secret}

차트가 비밀을 자동 생성하도록 할 수 있습니다. 또는 이 비밀을 수동으로 생성할 수 있습니다 (`<name>`을(를) 릴리스의 이름으로 바꿈):

```shell
kubectl create secret generic <name>-kas-private-api --from-literal=kas_private_api_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

이 비밀은 `gitlab.kas.privateApi.secret` 설정에서 참조됩니다.

### GitLab KAS WebSocket 토큰 비밀 {#gitlab-kas-websocket-token-secret}

차트가 비밀을 자동 생성하도록 할 수 있습니다. 또는 이 비밀을 수동으로 생성할 수 있습니다 (`<name>`을(를) 릴리스의 이름으로 바꿈):

```shell
kubectl create secret generic <name>-kas-websocket-token --from-literal=kas_websocket_token_secret=$(head -c 72 /dev/urandom | base64 -w0)
```

이 비밀은 `gitlab.kas.websocketToken.secret` 설정에서 참조됩니다.

### MinIO 비밀 {#minio-secret}

MinIO용 무작위 20 & 64자 영숫자 키 세트를 생성합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-minio-secret --from-literal=accesskey=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 20) --from-literal=secretkey=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

이 비밀은 `global.minio.credentials.secret` 설정에서 참조됩니다.

### PostgreSQL 암호 {#postgresql-password}

무작위 64자 영숫자 암호를 생성합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-postgresql-password \
    --from-literal=postgresql-password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64) \
    --from-literal=postgresql-postgres-password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

이 비밀은 `global.psql.password.secret` 설정에서 참조됩니다.

### GitLab Pages 비밀 {#gitlab-pages-secret}

GitLab Pages 비밀을 생성합니다. 이는 32자 길이이고 base64로 인코딩되어야 합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-gitlab-pages-secret --from-literal=shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

이 비밀은 `global.pages.apiSecret.secret` 설정에서 참조됩니다.

### 레지스트리 HTTP 비밀 {#registry-http-secret}

모든 레지스트리 pod에서 공유하는 무작위 64자 영숫자 키를 생성합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-registry-httpsecret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64 | base64)
```

이 비밀은 `global.registry.httpSecret.secret` 설정에서 참조됩니다.

### 레지스트리 알림 비밀 {#registry-notification-secret}

모든 레지스트리 pod 및 GitLab webservice pod에서 공유하는 무작위 32자 영숫자 키를 생성합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-registry-notification --from-literal=secret=[\"$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)\"]
```

이 비밀은 `global.registry.notificationSecret.secret` 설정에서 참조됩니다.

### Praefect DB 암호 {#praefect-db-password}

무작위 64자 영숫자 암호를 생성합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다:

```shell
kubectl create secret generic <name>-praefect-dbsecret \
    --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64) \
```

이 비밀은 `global.praefect.dbSecret` 설정에서 참조됩니다.

## 외부 서비스 {#external-services}

일부 차트는 자동으로 생성할 수 없는 기능을 사용하도록 설정하는 추가 비밀이 있습니다.

### OmniAuth {#omniauth}

배포된 GitLab에서 [OmniAuth Providers](https://docs.gitlab.com/integration/omniauth/) 사용을 활성화하려면 [Globals 차트의 지침](../charts/globals.md#omniauth)을 따르세요.

### LDAP 암호 {#ldap-password}

LDAP 서버에 연결하기 위해 암호 인증이 필요한 경우 Kubernetes 비밀에 암호를 저장해야 합니다.

```shell
kubectl create secret generic ldap-main-password --from-literal=password=yourpasswordhere
```

그런 다음 `--set global.appConfig.ldap.servers.main.password.secret=ldap-main-password`을(를) 사용하여 구성에 암호를 주입합니다.

> [!note] `Secret` 이름을 사용하고, Helm 속성을 구성할 때 _실제 암호_를 사용하지 마세요.

### SMTP 암호 {#smtp-password}

인증이 필요한 SMTP 서버를 사용하는 경우 Kubernetes 비밀에 암호를 저장합니다.

```shell
kubectl create secret generic smtp-password --from-literal=password=yourpasswordhere
```

그런 다음 Helm 명령에서 `--set global.smtp.password.secret=smtp-password`을(를) 사용합니다.

> [!note] `Secret` 이름을 사용하고, Helm 속성을 구성할 때 _실제 암호_를 사용하지 마세요.

### 수신 이메일용 IMAP 암호 {#imap-password-for-incoming-emails}

GitLab은 앱 암호, 토큰 또는 IMAP 암호와 같은 인증 문자열을 사용하여 수신 이메일에 액세스합니다.

[GitLab 수신 이메일 설명서에서 이메일 공급자를 찾고](https://docs.gitlab.com/administration/incoming_email/) 필요한 인증 문자열을 Kubernetes 비밀로 설정합니다.

```shell
kubectl create secret generic incoming-email-password --from-literal="password=auth_string_for_your_provider_here"
```

그런 다음 Helm 명령에서 `--set global.appConfig.incomingEmail.password.secret=incoming-email-password`을(를) 사용하고 [문서](command-line-options.md#incoming-email-configuration)에 지정된 대로 다른 필수 설정을 함께 사용합니다.

> [!note] `Secret` 이름을 사용하고, Helm 속성을 구성할 때 _실제 암호_를 사용하지 마세요.

### Service Desk 이메일용 IMAP 암호 {#imap-password-for-service-desk-emails}

GitLab은 앱 암호, 토큰 또는 IMAP 암호와 같은 인증 문자열을 사용하여 [Service Desk 이메일](https://docs.gitlab.com/user/project/service_desk/configure/#custom-email-address)에 액세스합니다.

[GitLab 수신 이메일 설명서에서 이메일 공급자를 찾고](https://docs.gitlab.com/administration/incoming_email/) 필요한 인증 문자열을 Kubernetes 비밀로 설정합니다.

```shell
kubectl create secret generic service-desk-email-password --from-literal="password=auth_string_for_your_provider_here"
```

그런 다음 Helm 명령에서 `--set global.appConfig.serviceDeskEmail.password.secret=service-desk-email-password`을(를) 사용하고 [문서](command-line-options.md#service-desk-email-configuration)에 지정된 대로 다른 필수 설정을 함께 사용합니다.

> [!note] `Secret` 이름을 사용하고, Helm 속성을 구성할 때 _실제 암호_를 사용하지 마세요.

### GitLab 수신 이메일 인증 토큰 {#gitlab-incoming-email-auth-token}

수신 이메일이 webhook 전달 방법을 사용하도록 구성된 경우 mail_room 서비스와 webservice 간에 공유 비밀이 있어야 합니다. 이는 32자 길이이고 base64로 인코딩되어야 합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-incoming-email-auth-token --from-literal=authToken=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

이 비밀은 `global.incomingEmail.authToken` 설정에서 참조됩니다.

### GitLab Service Desk 이메일 인증 토큰 {#gitlab-service-desk-email-auth-token}

Service Desk 이메일이 webhook 전달 방법을 사용하도록 구성된 경우 mail_room 서비스와 webservice 간에 공유 비밀이 있어야 합니다. 이는 32자 길이이고 base64로 인코딩되어야 합니다. `<name>`을(를) 릴리스의 이름으로 바꿉니다.

```shell
kubectl create secret generic <name>-service-desk-email-auth-token --from-literal=authToken=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

이 비밀은 `global.serviceDeskEmail.authToken` 설정에서 참조됩니다.

### Zoekt 인덱서 내부 API 비밀 {#zoekt-indexer-internal-api-secret}

[GitLab-zoekt 부분 차트](../charts/gitlab/gitlab-zoekt/_index.md)가 설치되면 Zoekt 인덱서는 JWT를 사용하여 GitLab 내부 API에 인증합니다. 기본적으로 이 비밀은 [GitLab Shell 비밀](#gitlab-shell-secret)을(를) 재사용하며, 이는 자동 생성됩니다.

Zoekt에 대해 별도의 비밀을 사용하려면 수동으로 하나를 생성할 수 있습니다 (`<name>`을(를) 릴리스의 이름으로 바꿈):

```shell
kubectl create secret generic <name>-zoekt-internal-api --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

그런 다음 차트가 이를 사용하도록 구성합니다:

```shell
--set global.zoekt.indexer.internalApi.secretName=<name>-zoekt-internal-api \
--set global.zoekt.indexer.internalApi.secretKey=secret
```

지정하지 않으면 `global.zoekt.indexer.internalApi.secretName`의 기본값은 GitLab Shell 인증 토큰 비밀 (`global.shell.authToken.secret`)입니다.

### 수신 이메일용 Microsoft Graph 클라이언트 비밀 {#microsoft-graph-client-secret-for-incoming-emails}

GitLab이 [수신 이메일](https://docs.gitlab.com/administration/incoming_email/)에 액세스하도록 하려면 IMAP 계정의 암호를 Kubernetes 비밀에 저장합니다:

```shell
kubectl create secret generic incoming-email-client-secret --from-literal=secret=your-secret-here
```

그런 다음 Helm 명령에서 `--set global.appConfig.incomingEmail.clientSecret.secret=incoming-email-client-secret`을(를) 사용하고 [문서](command-line-options.md#incoming-email-configuration)에 지정된 대로 다른 필수 설정을 함께 사용합니다.

> [!note] `Secret` 이름을 사용하고, Helm 속성을 구성할 때 _실제 암호_를 사용하지 마세요.

### Service Desk 이메일용 Microsoft Graph 클라이언트 비밀 {#microsoft-graph-client-secret-for-service-desk-emails}

GitLab이 [service_desk 이메일](https://docs.gitlab.com/user/project/service_desk/configure/#custom-email-address)에 액세스하도록 하려면 IMAP 계정의 암호를 Kubernetes 비밀에 저장합니다:

```shell
kubectl create secret generic service-desk-email-client-secret --from-literal=secret=your-secret-here
```

그런 다음 Helm 명령에서 `--set global.appConfig.serviceDeskEmail.clientSecret.secret=service-desk-email-client-secret`을(를) 사용하고 [문서](command-line-options.md#service-desk-email-configuration)에 지정된 대로 다른 필수 설정을 함께 사용합니다.

> [!note] `Secret` 이름을 사용하고, Helm 속성을 구성할 때 _실제 암호_를 사용하지 마세요.

### 발신 이메일용 Microsoft Graph 클라이언트 비밀 {#microsoft-graph-client-secret-for-outgoing-emails}

Kubernetes 비밀에 암호를 저장합니다:

```shell
kubectl create secret generic microsoft-graph-mailer-client-secret --from-literal=secret=your-secret-here
```

그런 다음 Helm 명령에서 `--set global.appConfig.microsoft_graph_mailer.client_secret.secret=microsoft-graph-mailer-client-secret`을(를) 사용합니다.

> [!note] `Secret` 이름을 사용하고, Helm 속성을 구성할 때 _실제 암호_를 사용하지 마세요.

### S/MIME 인증서 {#smime-certificate}

발신 이메일 메시지는 [S/MIME](https://en.wikipedia.org/wiki/S/MIME) 표준을 사용하여 디지털로 서명될 수 있습니다. S/MIME 인증서는 TLS 유형 비밀로 Kubernetes 비밀에 저장되어야 합니다.

```shell
kubectl create secret tls smime-certificate --key=file.key --cert file.crt
```

불투명 유형의 기존 비밀이 있는 경우 `global.email.smime.keyName` 및 `global.email.smime.certName` 값을 특정 비밀에 맞게 조정해야 합니다.

S/MIME 설정은 `values.yaml` 파일을 통해 또는 명령줄에서 설정할 수 있습니다. `--set global.email.smime.enabled=true`을(를) 사용하여 S/MIME을 활성화하고 `--set global.email.smime.secretName=smime-certificate`을(를) 사용하여 S/MIME 인증서를 포함하는 비밀을 지정합니다.

### 스마트카드 인증 {#smartcard-authentication}

[스마트카드 인증](https://docs.gitlab.com/administration/auth/smartcard/)은 사용자 정의 인증 기관 (CA)을 사용하여 클라이언트 인증서에 서명합니다. 이 사용자 정의 CA의 인증서를 Webservice pod에 주입하여 클라이언트 인증서가 유효한지 확인해야 합니다. 이는 k8s 비밀로 제공됩니다.

```shell
kubectl create secret generic <secret name> --from-file=ca.crt=<path to CA certificate>
```

인증서가 저장된 비밀 내의 키 이름은 `ca.crt`이어야 합니다.

### OAuth 통합 {#oauth-integration}

GitLab Pages와 같은 다양한 서비스의 OAuth 통합을 구성하려면 OAuth 자격 증명을 포함하는 비밀이 필요합니다. 비밀은 App ID (기본적으로 `appid` 키 아래에 저장됨)와 App Secret (기본적으로 `appsecret` 키 아래에 저장됨)을 포함해야 하며, 둘 다 최소 64자 길이의 영숫자 문자열이어야 합니다.

```shell
kubectl create secret generic oauth-gitlab-pages-secret --from-literal=appid=<app id> --from-literal=appsecret=<app secret>
```

이 비밀은 `global.oauth.<service name>.secret` 설정을 사용하여 지정할 수 있습니다. `appid` 및 `appsecret` 이외의 키를 사용하는 경우 `global.oauth.<service name>.appIdKey` 및 `global.oauth.<service name>.appSecretKey` 설정을 사용하여 지정할 수 있습니다.

## 다음 단계 {#next-steps}

모든 비밀이 생성되고 저장되면 [GitLab 배포](deployment.md)를 계속할 수 있습니다.

## 비밀 회전 {#rotating-secrets}

비밀은 보안상의 이유로 필요한 경우 회전할 수 있습니다.

1. [현재 비밀을 백업하세요](../backup-restore/backup.md#back-up-the-secrets).
1. 편의상 `-v2` 접미사가 있는 새 비밀을 생성합니다 (예: `gitlab-shell-host-keys-v2`) 및 회전하려는 각 비밀에 대해 [수동 비밀 생성](#manual-secret-creation-optional) 단계를 따릅니다.
1. `values.yaml` 파일의 비밀 키를 업데이트하여 새 비밀 이름을 가리키도록 합니다. 대부분의 비밀 이름은 [수동 비밀 생성](#manual-secret-creation-optional) 섹션의 각 비밀 아래에 설명되어 있습니다.
1. 업데이트된 `values.yaml` 파일로 GitLab 차트 릴리스를 업그레이드합니다.
1. GitLab이 예상대로 작동하는지 확인합니다. 그렇다면 이전 비밀을 안전하게 삭제할 수 있습니다.
