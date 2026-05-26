---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Helm 차트 배포 옵션
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

이 페이지는 GitLab 차트의 일반적으로 사용되는 값을 나열합니다. 사용 가능한 옵션의 전체 목록은 각 서브차트의 설명서를 참조하세요.

`helm install` 명령에 값을 전달할 수 있으며 YAML 파일과 `--values <values file>` 플래그를 사용하거나 여러 `--set` 플래그를 사용할 수 있습니다. 릴리스에 필요한 재정의만 포함하는 값 파일을 사용하는 것이 좋습니다.

기본 `values.yaml` 파일의 소스는 [GitLab 차트 저장소](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/values.yaml)를 참조하세요. 이 내용은 릴리스마다 변경되지만 Helm 자체를 사용하여 버전별로 이를 검색할 수 있습니다:

```shell
helm inspect values gitlab/gitlab
```

## 기본 구성 {#basic-configuration}

| 매개변수                                            | 기본값                                       | 설명 |
|------------------------------------------------------|-----------------------------------------------|-------------|
| `gitlab.migrations.initialRootPassword.key`          | `password`                                    | 마이그레이션 암호의 루트 계정 암호를 가리키는 키 |
| `gitlab.migrations.initialRootPassword.secret`       | `{Release.Name}-gitlab-initial-root-password` | 루트 계정 암호를 포함하는 암호의 전역 이름 |
| `global.gitlab.license.key`                          | `license`                                     | 라이선스 암호의 엔터프라이즈 라이선스를 가리키는 키 |
| `global.gitlab.license.secret`                       | _없음_                                        | 엔터프라이즈 라이선스를 포함하는 암호의 전역 이름 |
| `global.application.create`                          | `false`                                       | GitLab을 위한 [Application resource](https://github.com/kubernetes-sigs/application) 생성 |
| `global.edition`                                     | `ee`                                          | 설치할 GitLab 버전입니다. Enterprise Edition (`ee`) 또는 Community Edition (`ce`) |
| `global.gitaly.enabled`                              | `true`                                        | Gitaly 활성화 플래그 |
| `global.hosts.domain`                                | 필수                                      | 모든 공개적으로 노출된 서비스에 사용될 도메인 이름 |
| `global.hosts.externalIP`                            | 필수                                      | NGINX Ingress Controller에 할당할 정적 IP |
| `global.hosts.ssh`                                   | `gitlab.{global.hosts.domain}`                | Git SSH 액세스에 사용될 도메인 이름 |
| `global.imagePullPolicy`                             | `IfNotPresent`                                | 더 이상 사용되지 않음:  `global.image.pullPolicy`를 대신 사용하세요 |
| `global.image.pullPolicy`                            | _없음_ (기본 동작은 `IfNotPresent`)   | 모든 차트에 대한 기본 imagePullPolicy 설정 |
| `global.image.pullSecrets`                           | _없음_                                        | 모든 차트에 대해 기본 imagePullSecrets 설정(`name` 및 값 쌍의 목록 사용) |
| `global.minio.enabled`                               | `true`                                        | MinIO 활성화 플래그 |
| `global.psql.host`                                   | 필수                                      | 외부 PostgreSQL 인스턴스의 호스트 이름 |
| `global.psql.password.key`                           | 필수                                      | PostgreSQL 암호의 PostgreSQL 암호를 가리키는 키 |
| `global.psql.password.secret`                        | 필수                                      | PostgreSQL 암호를 포함하는 암호의 전역 이름 |
| `global.registry.bucket`                             | `registry`                                    | 레지스트리 버킷 이름 |
| `global.service.annotations`                         | `{}`                                          | 모든 `Service`에 추가할 주석 |
| `global.rails.sessionStore.sessionCookieTokenPrefix` | `""`                                          | 생성된 세션 쿠키의 접두사 |
| `global.deployment.annotations`                      | `{}`                                          | 모든 `Deployment`에 추가할 주석 |
| `global.time_zone`                                   | UTC                                           | 전역 시간대 |

## TLS 구성 {#tls-configuration}

| 매개변수                                           | 기본값 | 설명 |
|-----------------------------------------------------|---------|-------------|
| `certmanager-issuer.email`                          | `false` | Let's Encrypt 계정의 이메일 |
| `gitlab.webservice.ingress.tls.secretName`          | _없음_  | GitLab의 TLS 인증서 및 키를 포함하는 `Secret` |
| `gitlab.webservice.ingress.tls.smartcardSecretName` | _없음_  | GitLab 스마트카드 인증 도메인의 TLS 인증서 및 키를 포함하는 `Secret` |
| `global.hosts.https`                                | `true`  | HTTPS를 통해 제공 |
| `global.ingress.configureCertmanager`               | `false` | cert-manager를 구성하여 Let's Encrypt에서 인증서 가져오기(Ingress 활성화된 경우에만 사용) |
| `global.gatewayApi.configureCertmanager`            | `true`  | cert-manager를 구성하여 Gateway API HTTP-01 솔버를 통해 Let's Encrypt에서 인증서 가져오기 |
| `global.ingress.tls.secretName`                     | _없음_  | 와일드카드 TLS 인증서 및 키를 포함하는 `Secret` |
| `minio.ingress.tls.secretName`                      | _없음_  | MinIO의 TLS 인증서 및 키를 포함하는 `Secret` |
| `registry.ingress.tls.secretName`                   | _없음_  | 레지스트리의 TLS 인증서 및 키를 포함하는 `Secret` |

## 발신 이메일 구성 {#outgoing-email-configuration}

| 매개변수                         | 기본값               | 설명 |
|-----------------------------------|-----------------------|-------------|
| `global.email.display_name`       | `GitLab`              | GitLab의 이메일 발신자로 나타나는 이름 |
| `global.email.from`               | `gitlab@example.com`  | GitLab의 이메일 발신자로 나타나는 이메일 주소 |
| `global.email.reply_to`           | `noreply@example.com` | GitLab의 이메일에 나열된 회신 주소 |
| `global.email.smime.certName`     | `tls.crt`             | S/MIME 인증서 파일을 찾기 위한 암호 개체 키 값 |
| `global.email.smime.enabled`      | `false`               | 발신 이메일에 S/MIME 서명 추가 |
| `global.email.smime.keyName`      | `tls.key`             | S/MIME 키 파일을 찾기 위한 암호 개체 키 값 |
| `global.email.smime.secretName`   | `""`                  | X.509 인증서를 찾기 위한 Kubernetes 암호 개체([S/MIME 인증서](secrets.md#smime-certificate) 생성용) |
| `global.email.subject_suffix`     | `""`                  | GitLab의 모든 발신 이메일 제목에 접미사 |
| `global.smtp.address`             | `smtp.mailgun.org`    | 원격 메일 서버의 호스트 이름 또는 IP |
| `global.smtp.authentication`      | `plain`               | SMTP 인증 유형("plain", "login", "cram_md5" 또는 인증 없음을 위한 "") |
| `global.smtp.domain`              | `""`                  | SMTP의 선택적 HELO 도메인 |
| `global.smtp.enabled`             | `false`               | 발신 이메일 활성화 |
| `global.smtp.openssl_verify_mode` | `peer`                | TLS 확인 모드("none", "peer", "client_once" 또는 "fail_if_no_peer_cert") |
| `global.smtp.password.key`        | `password`            | `global.smtp.password.secret`의 SMTP 암호를 포함하는 키 |
| `global.smtp.password.secret`     | `""`                  | SMTP 암호를 포함하는 `Secret`의 이름 |
| `global.smtp.port`                | `2525`                | SMTP 포트 |
| `global.smtp.starttls_auto`       | `false`               | 메일 서버에서 활성화된 경우 STARTTLS 사용 |
| `global.smtp.tls`                 | _없음_                | SMTP/TLS 활성화(SMTPS:  직접 TLS 연결을 통한 SMTP) |
| `global.smtp.user_name`           | `""`                  | SMTP 인증용 사용자 이름 https |
| `global.smtp.open_timeout`        | `30`                  | 연결을 열려고 시도하는 동안 대기할 시간(초). |
| `global.smtp.read_timeout`        | `60`                  | 한 블록을 읽는 동안 대기할 시간(초). |
| `global.smtp.pool`                | `false`               | SMTP 연결 풀링 활성화 |

### Microsoft Graph Mailer 설정 {#microsoft-graph-mailer-settings}

| 매개변수                                                      | 기본값                             | 설명 |
|----------------------------------------------------------------|-------------------------------------|-------------|
| `global.appConfig.microsoft_graph_mailer.enabled`              | `false`                             | Microsoft Graph API를 통한 발신 이메일 활성화 |
| `global.appConfig.microsoft_graph_mailer.user_id`              | `""`                                | Microsoft Graph API를 사용하는 사용자의 고유 식별자 |
| `global.appConfig.microsoft_graph_mailer.tenant`               | `""`                                | 응용 프로그램이 작동하려는 디렉터리 테넌트, GUID 또는 도메인 이름 형식 |
| `global.appConfig.microsoft_graph_mailer.client_id`            | `""`                                | 앱에 할당된 응용 프로그램 ID. 앱을 등록한 포털에서 이 정보를 찾을 수 있습니다 |
| `global.appConfig.microsoft_graph_mailer.client_secret.key`    | `secret`                            | `global.appConfig.microsoft_graph_mailer.client_secret.secret`에서 앱 등록 포털의 앱에 대해 생성한 클라이언트 암호를 포함하는 키 |
| `global.appConfig.microsoft_graph_mailer.client_secret.secret` | `""`                                | 앱 등록 포털의 앱에 대해 생성한 클라이언트 암호를 포함하는 `Secret`의 이름 |
| `global.appConfig.microsoft_graph_mailer.azure_ad_endpoint`    | `https://login.microsoftonline.com` | Azure Active Directory 엔드포인트의 URL |
| `global.appConfig.microsoft_graph_mailer.graph_endpoint`       | `https://graph.microsoft.com`       | Microsoft Graph 엔드포인트의 URL |

## 수신 이메일 구성 {#incoming-email-configuration}

### 공통 설정 {#common-settings}

[수신 이메일 구성 예제 설명서](https://docs.gitlab.com/administration/incoming_email/#configuration-examples)를 참조하세요.

| 매개변수                                            | 기본값                                    | 설명 |
|------------------------------------------------------|--------------------------------------------|-------------|
| `global.appConfig.incomingEmail.address`             | 비어있음                                      | 회신 중인 항목을 참조하는 이메일 주소(예: `gitlab-incoming+%{key}@gmail.com`). `+%{key}` 접미사는 이메일 주소 내에 완전히 포함되어야 하며 다른 값으로 바뀌지 않아야 합니다. |
| `global.appConfig.incomingEmail.enabled`             | `false`                                    | 수신 이메일 활성화 |
| `global.appConfig.incomingEmail.deleteAfterDelivery` | `true`                                     | 메시지를 삭제된 것으로 표시할지 여부. IMAP의 경우 삭제된 것으로 표시된 메시지는 `expungedDeleted`이 `true`로 설정된 경우 제거됩니다. Microsoft Graph의 경우 이를 false로 설정하여 받은편지함에 메시지를 유지하세요. 삭제된 메시지는 시간이 지나면 자동으로 제거됩니다. |
| `global.appConfig.incomingEmail.expungeDeleted`      | `false`                                    | 배달 후 삭제된 것으로 표시된 메시지를 사서함에서 제거(영구적으로)할지 여부. Microsoft Graph가 삭제된 메시지를 자동으로 제거하기 때문에 IMAP에만 관련이 있습니다. |
| `global.appConfig.incomingEmail.logger.logPath`      | `/dev/stdout`                              | JSON 구조화 로그를 쓸 경로; 이 로깅을 비활성화하려면 ""로 설정 |
| `global.appConfig.incomingEmail.inboxMethod`         | `imap`                                     | IMAP(`imap`) 또는 Microsoft Graph API with OAuth2(`microsoft_graph`)로 메일 읽기 |
| `global.appConfig.incomingEmail.deliveryMethod`      | `webhook`                                  | 사서함이 Rails 앱에 이메일 내용을 처리할 수 있도록 보낼 수 있는 방법. `sidekiq` 또는 `webhook` |
| `gitlab.appConfig.incomingEmail.authToken.key`       | `authToken`                                | 수신 이메일 암호의 수신 이메일 토큰 키. 배달 방법이 webhook일 때 유효합니다. |
| `gitlab.appConfig.incomingEmail.authToken.secret`    | `{Release.Name}-incoming-email-auth-token` | 수신 이메일 인증 암호. 배달 방법이 webhook일 때 유효합니다. |

### IMAP 설정 {#imap-settings}

| 매개변수                                        | 기본값    | 설명 |
|--------------------------------------------------|------------|-------------|
| `global.appConfig.incomingEmail.host`            | 비어있음      | IMAP의 호스트 |
| `global.appConfig.incomingEmail.idleTimeout`     | `60`       | IDLE 명령 시간 초과 |
| `global.appConfig.incomingEmail.mailbox`         | `inbox`    | 수신 메일이 도착할 사서함. |
| `global.appConfig.incomingEmail.password.key`    | `password` | `global.appConfig.incomingEmail.password.secret`에서 IMAP 암호를 포함하는 키 |
| `global.appConfig.incomingEmail.password.secret` | 비어있음      | IMAP 암호를 포함하는 `Secret`의 이름 |
| `global.appConfig.incomingEmail.port`            | `993`      | IMAP 포트 |
| `global.appConfig.incomingEmail.ssl`             | `true`     | IMAP 서버가 SSL을 사용하는지 여부 |
| `global.appConfig.incomingEmail.startTls`        | `false`    | IMAP 서버가 StartTLS를 사용하는지 여부 |
| `global.appConfig.incomingEmail.user`            | 비어있음      | IMAP 인증용 사용자 이름 |

### Microsoft Graph 설정 {#microsoft-graph-settings}

| 매개변수                                            | 기본값 | 설명 |
|------------------------------------------------------|---------|-------------|
| `global.appConfig.incomingEmail.tenantId`            | 비어있음   | Microsoft Azure Active Directory의 테넌트 ID |
| `global.appConfig.incomingEmail.clientId`            | 비어있음   | OAuth2 앱의 클라이언트 ID |
| `global.appConfig.incomingEmail.clientSecret.key`    | 비어있음   | `appConfig.incomingEmail.clientSecret.secret`에서 OAuth2 클라이언트 암호를 포함하는 키 |
| `global.appConfig.incomingEmail.clientSecret.secret` | secret  | OAuth2 클라이언트 암호를 포함하는 `Secret`의 이름 |
| `global.appConfig.incomingEmail.pollInterval`        | `60`    | 새 메일을 폴링할 빈도(초 단위) |
| `global.appConfig.incomingEmail.azureAdEndpoint`     | 비어있음   | Azure Active Directory 엔드포인트의 URL(예: `https://login.microsoftonline.com`) |
| `global.appConfig.incomingEmail.graphEndpoint`       | 비어있음   | Microsoft Graph 엔드포인트의 URL(예: `https://graph.microsoft.com`) |

[암호 생성 지침](secrets.md)을 참조하세요.

## Service Desk 이메일 구성 {#service-desk-email-configuration}

Service Desk의 요구사항으로 수신 메일은 [구성](#incoming-email-configuration)되어야 합니다. 수신 메일과 Service Desk 모두의 이메일 주소는 [이메일 서브 주소 지정](https://docs.gitlab.com/administration/incoming_email/#email-sub-addressing)을 사용해야 합니다. 각 섹션에서 이메일 주소를 설정할 때 사용자 이름에 추가되는 태그는 `+%{key}`이어야 합니다.

### 공통 설정 {#common-settings-1}

| 매개변수                                               | 기본값                                        | 설명 |
|---------------------------------------------------------|------------------------------------------------|-------------|
| `global.appConfig.serviceDeskEmail.address`             | 비어있음                                          | 회신 중인 항목을 참조하는 이메일 주소(예: `project_contact+%{key}@gmail.com`) |
| `global.appConfig.serviceDeskEmail.enabled`             | `false`                                        | Service Desk 이메일 활성화 |
| `global.appConfig.serviceDeskEmail.deleteAfterDelivery` | `true`                                         | 메시지를 삭제된 것으로 표시할지 여부. IMAP의 경우 삭제된 것으로 표시된 메시지는 `expungedDeleted`이 `true`로 설정된 경우 제거됩니다. Microsoft Graph의 경우 이를 false로 설정하여 받은편지함에 메시지를 유지하세요. 삭제된 메시지는 시간이 지나면 자동으로 제거됩니다. |
| `global.appConfig.serviceDeskEmail.expungeDeleted`      | `false`                                        | 배달 후 삭제된 것으로 표시된 메시지를 사서함에서 제거(영구적으로)할지 여부. Microsoft Graph가 삭제된 메시지를 자동으로 제거하기 때문에 IMAP에만 관련이 있습니다. |
| `global.appConfig.serviceDeskEmail.logger.logPath`      | `/dev/stdout`                                  | JSON 구조화 로그를 쓸 경로; 이 로깅을 비활성화하려면 ""로 설정 |
| `global.appConfig.serviceDeskEmail.inboxMethod`         | `imap`                                         | IMAP(`imap`) 또는 Microsoft Graph API with OAuth2(`microsoft_graph`)로 메일 읽기 |
| `global.appConfig.serviceDeskEmail.deliveryMethod`      | `webhook`                                      | 사서함이 Rails 앱에 이메일 내용을 처리할 수 있도록 보낼 수 있는 방법. `sidekiq` 또는 `webhook` |
| `gitlab.appConfig.serviceDeskEmail.authToken.key`       | `authToken`                                    | Service Desk 이메일 암호의 Service Desk 이메일 토큰 키. 배달 방법이 webhook일 때 유효합니다. |
| `gitlab.appConfig.serviceDeskEmail.authToken.secret`    | `{Release.Name}-service-desk-email-auth-token` | service-desk 이메일 인증 암호. 배달 방법이 webhook일 때 유효합니다. |

### IMAP 설정 {#imap-settings-1}

| 매개변수                                           | 기본값    | 설명 |
|-----------------------------------------------------|------------|-------------|
| `global.appConfig.serviceDeskEmail.host`            | 비어있음      | IMAP의 호스트 |
| `global.appConfig.serviceDeskEmail.idleTimeout`     | `60`       | IDLE 명령 시간 초과 |
| `global.appConfig.serviceDeskEmail.mailbox`         | `inbox`    | Service Desk 메일이 도착할 사서함. |
| `global.appConfig.serviceDeskEmail.password.key`    | `password` | `global.appConfig.serviceDeskEmail.password.secret`에서 IMAP 암호를 포함하는 키 |
| `global.appConfig.serviceDeskEmail.password.secret` | 비어있음      | IMAP 암호를 포함하는 `Secret`의 이름 |
| `global.appConfig.serviceDeskEmail.port`            | `993`      | IMAP 포트 |
| `global.appConfig.serviceDeskEmail.ssl`             | `true`     | IMAP 서버가 SSL을 사용하는지 여부 |
| `global.appConfig.serviceDeskEmail.startTls`        | `false`    | IMAP 서버가 StartTLS를 사용하는지 여부 |
| `global.appConfig.serviceDeskEmail.user`            | 비어있음      | IMAP 인증용 사용자 이름 |

### Microsoft Graph 설정 {#microsoft-graph-settings-1}

| 매개변수                                               | 기본값 | 설명 |
|---------------------------------------------------------|---------|-------------|
| `global.appConfig.serviceDeskEmail.tenantId`            | 비어있음   | Microsoft Azure Active Directory의 테넌트 ID |
| `global.appConfig.serviceDeskEmail.clientId`            | 비어있음   | OAuth2 앱의 클라이언트 ID |
| `global.appConfig.serviceDeskEmail.clientSecret.key`    | 비어있음   | `appConfig.serviceDeskEmail.clientSecret.secret`에서 OAuth2 클라이언트 암호를 포함하는 키 |
| `global.appConfig.serviceDeskEmail.clientSecret.secret` | secret  | OAuth2 클라이언트 암호를 포함하는 `Secret`의 이름 |
| `global.appConfig.serviceDeskEmail.pollInterval`        | `60`    | 새 메일을 폴링할 빈도(초 단위) |
| `global.appConfig.serviceDeskEmail.azureAdEndpoint`     | 비어있음   | Azure Active Directory 엔드포인트의 URL(예: `https://login.microsoftonline.com`) |
| `global.appConfig.serviceDeskEmail.graphEndpoint`       | 비어있음   | Microsoft Graph 엔드포인트의 URL(예: `https://graph.microsoft.com`) |

[암호 생성 지침](secrets.md)을 참조하세요.

## 기본 프로젝트 기능 구성 {#default-project-features-configuration}

| 매개변수                                                    | 기본값 | 설명 |
|--------------------------------------------------------------|---------|-------------|
| `global.appConfig.defaultProjectsFeatures.builds`            | `true`  | 프로젝트 빌드 활성화 |
| `global.appConfig.defaultProjectsFeatures.containerRegistry` | `true`  | 컨테이너 레지스트리 프로젝트 기능 활성화 |
| `global.appConfig.defaultProjectsFeatures.issues`            | `true`  | 프로젝트 문제 활성화 |
| `global.appConfig.defaultProjectsFeatures.mergeRequests`     | `true`  | 프로젝트 병합 요청 활성화 |
| `global.appConfig.defaultProjectsFeatures.snippets`          | `true`  | 프로젝트 코드 조각 활성화 |
| `global.appConfig.defaultProjectsFeatures.wiki`              | `true`  | 프로젝트 위키 활성화 |

## GitLab Shell {#gitlab-shell}

| 매개변수                        | 기본값 | 설명 |
|----------------------------------|---------|-------------|
| `global.shell.authToken`         |         | 공유 암호를 포함하는 암호 |
| `global.shell.hostKeys`          |         | SSH 호스트 키를 포함하는 암호 |
| `global.shell.port`              |         | SSH에 대해 Ingress에 노출할 포트 번호 |
| `global.shell.tcp.proxyProtocol` | `false` | SSH Ingress에서 ProxyProtocol 활성화 |

## RBAC 설정 {#rbac-settings}

| 매개변수                              | 기본값 | 설명 |
|----------------------------------------|---------|-------------|
| `certmanager.rbac.create`              | `true`  | RBAC 리소스 생성 및 사용 |
| `gitlab-runner.rbac.create`            | `true`  | RBAC 리소스 생성 및 사용 |
| `nginx-ingress.rbac.create`            | `false` | 기본 RBAC 리소스 생성 및 사용 |
| `nginx-ingress.rbac.createClusterRole` | `false` | 클러스터 역할 생성 및 사용 |
| `nginx-ingress.rbac.createRole`        | `true`  | 네임스페이스 역할 생성 및 사용 |
| `prometheus.rbac.create`               | `true`  | RBAC 리소스 생성 및 사용 |

`nginx-ingress.rbac.create`을 `false`로 설정하여 RBAC 규칙을 직접 구성하는 경우 특정 RBAC 규칙을 추가해야 할 수 있습니다 [차트 버전에 따라](../releases/8_0.md#upgrade-to-86x-851-843-836).

## Advanced NGINX Ingress 구성 {#advanced-nginx-ingress-configuration}

NGINX Ingress 값 접두사를 `nginx-ingress`로 지정하세요. 예를 들어 `nginx-ingress.controller.image.tag`를 사용하여 컨트롤러 이미지 태그를 설정하세요.

[`nginx-ingress` 차트](../charts/nginx/_index.md)를 참조하세요.

## 외부 Redis 구성 {#external-redis-configuration}

전체 설정 지침은 [GitLab 차트를 외부 Redis로 구성](../advanced/external-redis/_index.md)을 참조하세요.

## Advanced 레지스트리 구성 {#advanced-registry-configuration}

| 매개변수                                           | 기본값                                     | 설명 |
|-----------------------------------------------------|---------------------------------------------|-------------|
| `registry.authEndpoint`                             | 기본적으로 정의되지 않음                        | 인증 엔드포인트 |
| `registry.enabled`                                  | `true`                                      | Docker 레지스트리 활성화 |
| `registry.httpSecret`                               |                                             | Https 암호 |
| `registry.minio.bucket`                             | `registry`                                  | MinIO 레지스트리 버킷 이름 |
| `registry.service.annotations`                      | `{}`                                        | `Service`에 추가할 주석 |
| `registry.securityContext.fsGroup`                  | `1000`                                      | 포드가 시작되어야 하는 그룹 ID |
| `registry.securityContext.runAsUser`                | `1000`                                      | 포드가 시작되어야 하는 사용자 ID |
| `registry.tokenIssuer`                              | `gitlab-issuer`                             | JWT 토큰 발급자 |
| `registry.tokenService`                             | `container_registry`                        | JWT 토큰 서비스 |
| `registry.profiling.stackdriver.enabled`            | `false`                                     | Stackdriver를 사용하여 지속적 프로파일링 활성화 |
| `registry.profiling.stackdriver.credentials.secret` | `gitlab-registry-profiling-creds`           | 자격 증명을 포함하는 암호의 이름 |
| `registry.profiling.stackdriver.credentials.key`    | `credentials`                               | 자격 증명이 저장되는 암호 키 |
| `registry.profiling.stackdriver.service`            | `RELEASE-registry` (템플릿화된 Service 이름) | 프로필을 기록할 Stackdriver 서비스의 이름 |
| `registry.profiling.stackdriver.projectid`          | 실행 중인 GCP 프로젝트                   | 프로필을 보고할 GCP 프로젝트 |

## Advanced MinIO 구성 {#advanced-minio-configuration}

| 매개변수                            | 기본값                        | 설명 |
|--------------------------------------|--------------------------------|-------------|
| `minio.defaultBuckets`               | `[{"name": "registry"}]`       | MinIO 기본 버킷 |
| `minio.image`                        | `minio/minio`                  | MinIO 이미지 |
| `minio.imagePullPolicy`              |                                | MinIO 이미지 풀 정책 |
| `minio.imageTag`                     | `RELEASE.2017-12-28T01-21-00Z` | MinIO 이미지 태그 |
| `minio.minioConfig.browser`          | `on`                           | MinIO 브라우저 플래그 |
| `minio.minioConfig.domain`           |                                | MinIO 도메인 |
| `minio.minioConfig.region`           | `us-east-1`                    | MinIO 영역 |
| `minio.mountPath`                    | `/export`                      | MinIO 구성 파일 마운트 경로 |
| `minio.persistence.accessMode`       | `ReadWriteOnce`                | MinIO 지속성 액세스 모드 |
| `minio.persistence.enabled`          | `true`                         | MinIO 지속성 활성화 플래그 |
| `minio.persistence.matchExpressions` |                                | MinIO 레이블 식 일치 바인드 |
| `minio.persistence.matchLabels`      |                                | MinIO 레이블 값 일치 바인드 |
| `minio.persistence.size`             | `10Gi`                         | MinIO 지속성 볼륨 크기 |
| `minio.persistence.storageClass`     |                                | MinIO storageClassName 프로비저닝 |
| `minio.persistence.subPath`          |                                | MinIO 지속성 볼륨 마운트 경로 |
| `minio.persistence.volumeName`       |                                | MinIO 기존 지속성 볼륨 이름 |
| `minio.resources.requests.cpu`       | `250m`                         | MinIO 최소 요청 CPU |
| `minio.resources.requests.memory`    | `256Mi`                        | MinIO 최소 요청 메모리 |
| `minio.service.annotations`          | `{}`                           | `Service`에 추가할 주석 |
| `minio.servicePort`                  | `9000`                         | MinIO 서비스 포트 |
| `minio.serviceType`                  | `ClusterIP`                    | MinIO 서비스 유형 |

## Advanced GitLab 구성 {#advanced-gitlab-configuration}

| 매개변수                                                  | 기본값                                                         | 설명 |
|------------------------------------------------------------|-----------------------------------------------------------------|-------------|
| `gitlab-runner.checkInterval`                              | `30s`                                                           | 폴링 간격 |
| `gitlab-runner.concurrent`                                 | `20`                                                            | 동시 작업 수 |
| `gitlab-runner.imagePullPolicy`                            | `IfNotPresent`                                                  | 이미지 풀 정책 |
| `gitlab-runner.image`                                      | `gitlab/gitlab-runner:alpine-v10.5.0`                           | 러너 이미지 |
| `gitlab-runner.gitlabUrl`                                  | GitLab 외부 URL                                             | Runner가 GitLab Server에 등록하는 데 사용하는 URL |
| `gitlab-runner.install`                                    | `true`                                                          | `gitlab-runner` 차트 설치 |
| `gitlab-runner.rbac.clusterWideAccess`                     | `false`                                                         | 작업의 컨테이너를 클러스터 전체에 배포 |
| `gitlab-runner.rbac.create`                                | `true`                                                          | RBAC 서비스 계정을 생성할지 여부 |
| `gitlab-runner.rbac.serviceAccountName`                    | `default`                                                       | 생성할 RBAC 서비스 계정의 이름 |
| `gitlab-runner.resources.limits.cpu`                       |                                                                 | 러너 리소스 |
| `gitlab-runner.resources.limits.memory`                    |                                                                 | 러너 리소스 |
| `gitlab-runner.resources.requests.cpu`                     |                                                                 | 러너 리소스 |
| `gitlab-runner.resources.requests.memory`                  |                                                                 | 러너 리소스 |
| `gitlab-runner.runners.privileged`                         | `false`                                                         | 특권 모드에서 실행, `dind`에 필요 |
| `gitlab-runner.runners.cache.secretName`                   | `gitlab-minio`                                                  | `accesskey` 및 `secretkey`을 얻을 암호 |
| `gitlab-runner.runners.config`                             | [차트 설명서](../charts/gitlab/gitlab-runner/_index.md#default-runner-configuration) 참조 | 문자열로 러너 구성 |
| `gitlab-runner.unregisterRunners`                          | `true`                                                          | 차트가 설치될 때 로컬 `config.toml`의 모든 러너 등록 해제. 토큰이 `glrt-`로 시작하면 러너 관리자가 삭제되고 러너는 아닙니다. 러너 관리자는 `config.toml`을 포함하는 러너 및 머신으로 식별됩니다. 러너가 등록 토큰으로 등록된 경우 러너가 삭제됩니다. |
| `gitlab.geo-logcursor.securityContext.fsGroup`             | `1000`                                                          | 포드가 시작되어야 하는 그룹 ID |
| `gitlab.geo-logcursor.securityContext.runAsUser`           | `1000`                                                          | 포드가 시작되어야 하는 사용자 ID |
| `gitlab.gitaly.authToken.key`                              | `token`                                                         | 암호의 Gitaly 토큰 키 |
| `gitlab.gitaly.authToken.secret`                           | `{.Release.Name}-gitaly-secret`                                 | Gitaly 암호 이름 |
| `gitlab.gitaly.image.pullPolicy`                           |                                                                 | Gitaly 이미지 풀 정책 |
| `gitlab.gitaly.image.repository`                           | `registry.gitlab.com/gitlab-org/build/cng/gitaly`               | Gitaly 이미지 저장소 |
| `gitlab.gitaly.image.tag`                                  | `master`                                                        | Gitaly 이미지 태그 |
| `gitlab.gitaly.persistence.accessMode`                     | `ReadWriteOnce`                                                 | Gitaly 지속성 액세스 모드 |
| `gitlab.gitaly.persistence.enabled`                        | `true`                                                          | Gitaly 지속성 활성화 플래그 |
| `gitlab.gitaly.persistence.matchExpressions`               |                                                                 | 레이블 식 일치 바인드 |
| `gitlab.gitaly.persistence.matchLabels`                    |                                                                 | 레이블 값 일치 바인드 |
| `gitlab.gitaly.persistence.size`                           | `50Gi`                                                          | Gitaly 지속성 볼륨 크기 |
| `gitlab.gitaly.persistence.storageClass`                   |                                                                 | 프로비저닝용 storageClassName |
| `gitlab.gitaly.persistence.subPath`                        |                                                                 | Gitaly 지속성 볼륨 마운트 경로 |
| `gitlab.gitaly.persistence.volumeName`                     |                                                                 | 기존 지속성 볼륨 이름 |
| `gitlab.gitaly.securityContext.fsGroup`                    | `1000`                                                          | 포드가 시작되어야 하는 그룹 ID |
| `gitlab.gitaly.securityContext.runAsUser`                  | `1000`                                                          | 포드가 시작되어야 하는 사용자 ID |
| `gitlab.gitaly.service.annotations`                        | `{}`                                                            | `Service`에 추가할 주석 |
| `gitlab.gitaly.service.externalPort`                       | `8075`                                                          | Gitaly 서비스 노출 포트 |
| `gitlab.gitaly.service.internalPort`                       | `8075`                                                          | Gitaly 내부 포트 |
| `gitlab.gitaly.service.name`                               | `gitaly`                                                        | Gitaly 서비스 이름 |
| `gitlab.gitaly.service.type`                               | `ClusterIP`                                                     | Gitaly 서비스 유형 |
| `gitlab.gitaly.serviceName`                                | `gitaly`                                                        | Gitaly 서비스 이름 |
| `gitlab.gitaly.shell.authToken.key`                        | `secret`                                                        | Shell 키   |
| `gitlab.gitaly.shell.authToken.secret`                     | `{Release.Name}-gitlab-shell-secret`                            | Shell 암호 |
| `gitlab.gitlab-exporter.securityContext.fsGroup`           | `1000`                                                          | 포드가 시작되어야 하는 그룹 ID |
| `gitlab.gitlab-exporter.securityContext.runAsUser`         | `1000`                                                          | 포드가 시작되어야 하는 사용자 ID |
| `gitlab.gitlab-shell.authToken.key`                        | `secret`                                                        | Shell 인증 암호 키 |
| `gitlab.gitlab-shell.authToken.secret`                     | `{Release.Name}-gitlab-shell-secret`                            | Shell 인증 암호 |
| `gitlab.gitlab-shell.enabled`                              | `true`                                                          | Shell 활성화 플래그 |
| `gitlab.gitlab-shell.image.pullPolicy`                     |                                                                 | Shell 이미지 풀 정책 |
| `gitlab.gitlab-shell.image.repository`                     | `registry.gitlab.com/gitlab-org/build/cng/gitlab-shell`         | Shell 이미지 저장소 |
| `gitlab.gitlab-shell.image.tag`                            | `master`                                                        | Shell 이미지 태그 |
| `gitlab.gitlab-shell.replicaCount`                         | `1`                                                             | Shell 복제본 |
| `gitlab.gitlab-shell.securityContext.fsGroup`              | `1000`                                                          | 포드가 시작되어야 하는 그룹 ID |
| `gitlab.gitlab-shell.securityContext.runAsUser`            | `1000`                                                          | 포드가 시작되어야 하는 사용자 ID |
| `gitlab.gitlab-shell.service.annotations`                  | `{}`                                                            | `Service`에 추가할 주석 |
| `gitlab.gitlab-shell.service.internalPort`                 | `2222`                                                          | Shell 내부 포트 |
| `gitlab.gitlab-shell.service.name`                         | `gitlab-shell`                                                  | Shell 서비스 이름 |
| `gitlab.gitlab-shell.service.type`                         | `ClusterIP`                                                     | Shell 서비스 유형 |
| `gitlab.gitlab-shell.webservice.serviceName`               | `global.webservice.serviceName`에서 상속됨                  | Webservice 서비스 이름 |
| `gitlab.mailroom.securityContext.fsGroup`                  | `1000`                                                          | 포드가 시작되어야 하는 그룹 ID |
| `gitlab.mailroom.securityContext.runAsUser`                | `1000`                                                          | 포드가 시작되어야 하는 사용자 ID |
| `gitlab.migrations.bootsnap.enabled`                       | `true`                                                          | 마이그레이션 Bootsnap 활성화 플래그 |
| `gitlab.migrations.enabled`                                | `true`                                                          | 마이그레이션 활성화 플래그 |
| `gitlab.migrations.image.pullPolicy`                       |                                                                 | 마이그레이션 풀 정책 |
| `gitlab.migrations.image.repository`                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee`    | 마이그레이션 이미지 저장소 |
| `gitlab.migrations.image.tag`                              | `master`                                                        | 마이그레이션 이미지 태그 |
| `gitlab.migrations.psql.password.key`                      | `psql-password`                                                 | PostgreSQL 암호의 PostgreSQL 암호 키 |
| `gitlab.migrations.psql.password.secret`                   | `gitlab-postgres`                                               | PostgreSQL 암호 |
| `gitlab.migrations.psql.port`                              |                                                                 | PostgreSQL 서버 포트를 설정하세요. `global.psql.port`보다 우선합니다 |
| `gitlab.migrations.securityContext.fsGroup`                | `1000`                                                          | 포드가 시작되어야 하는 그룹 ID |
| `gitlab.migrations.securityContext.runAsUser`              | `1000`                                                          | 포드가 시작되어야 하는 사용자 ID |
| `gitlab.sidekiq.concurrency`                               | `20`                                                            | Sidekiq 기본 동시성 |
| `gitlab.sidekiq.enabled`                                   | `true`                                                          | Sidekiq 활성화 플래그 |
| `gitlab.sidekiq.gitaly.authToken.key`                      | `token`                                                         | Gitaly 암호의 Gitaly 토큰 키 |
| `gitlab.sidekiq.gitaly.authToken.secret`                   | `{.Release.Name}-gitaly-secret`                                 | Gitaly 암호 |
| `gitlab.sidekiq.gitaly.serviceName`                        | `gitaly`                                                        | Gitaly 서비스 이름 |
| `gitlab.sidekiq.image.pullPolicy`                          |                                                                 | Sidekiq 이미지 풀 정책 |
| `gitlab.sidekiq.image.repository`                          | `registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ee`    | Sidekiq 이미지 저장소 |
| `gitlab.sidekiq.image.tag`                                 | `master`                                                        | Sidekiq 이미지 태그 |
| `gitlab.sidekiq.psql.password.key`                         | `psql-password`                                                 | PostgreSQL 암호의 PostgreSQL 암호 키 |
| `gitlab.sidekiq.psql.password.secret`                      | `gitlab-postgres`                                               | PostgreSQL 암호 |
| `gitlab.sidekiq.psql.port`                                 |                                                                 | PostgreSQL 서버 포트를 설정하세요. `global.psql.port`보다 우선합니다 |
| `gitlab.sidekiq.replicas`                                  | `1`                                                             | Sidekiq 복제본 |
| `gitlab.sidekiq.resources.requests.cpu`                    | `100m`                                                          | Sidekiq 최소 필요 CPU |
| `gitlab.sidekiq.resources.requests.memory`                 | `600M`                                                          | Sidekiq 최소 필요 메모리 |
| `gitlab.sidekiq.securityContext.fsGroup`                   | `1000`                                                          | 포드가 시작되어야 하는 그룹 ID |
| `gitlab.sidekiq.securityContext.runAsUser`                 | `1000`                                                          | 포드가 시작되어야 하는 사용자 ID |
| `gitlab.sidekiq.timeout`                                   | `5`                                                             | Sidekiq 작업 시간 초과 |
| `gitlab.toolbox.annotations`                               | `{}`                                                            | 도구 상자에 추가할 주석 |
| `gitlab.toolbox.backups.cron.enabled`                      | `false`                                                         | Backup CronJob 활성화 플래그 |
| `gitlab.toolbox.backups.cron.extraArgs`                    |                                                                 | 백업 유틸리티에 전달할 인수 문자열 |
| `gitlab.toolbox.backups.cron.persistence.accessMode`       | `ReadWriteOnce`                                                 | Backup cron 지속성 액세스 모드 |
| `gitlab.toolbox.backups.cron.persistence.enabled`          | `false`                                                         | Backup cron 지속성 활성화 플래그 |
| `gitlab.toolbox.backups.cron.persistence.matchExpressions` |                                                                 | 레이블 식 일치 바인드 |
| `gitlab.toolbox.backups.cron.persistence.matchLabels`      |                                                                 | 레이블 값 일치 바인드 |
| `gitlab.toolbox.backups.cron.persistence.size`             | `10Gi`                                                          | Backup cron 지속성 볼륨 크기 |
| `gitlab.toolbox.backups.cron.persistence.storageClass`     |                                                                 | 프로비저닝용 storageClassName |
| `gitlab.toolbox.backups.cron.persistence.subPath`          |                                                                 | Backup cron 지속성 볼륨 마운트 경로 |
| `gitlab.toolbox.backups.cron.persistence.volumeName`       |                                                                 | 기존 지속성 볼륨 이름 |
| `gitlab.toolbox.backups.cron.resources.requests.cpu`       | `50m`                                                           | Backup cron 최소 필요 CPU |
| `gitlab.toolbox.backups.cron.resources.requests.memory`    | `350M`                                                          | Backup cron 최소 필요 메모리 |
| `gitlab.toolbox.backups.cron.schedule`                     | `0 1 * * *`                                                     | Cron 스타일 스케줄 문자열 |
| `gitlab.toolbox.backups.objectStorage.backend`             | `s3`                                                            | 사용할 개체 저장소 공급자(`s3`, `gcs` 또는 `azure`) |
| `gitlab.toolbox.backups.objectStorage.config.gcpProject`   | `""`                                                            | 백엔드가 `gcs`일 때 사용할 GCP 프로젝트 |
| `gitlab.toolbox.backups.objectStorage.config.key`          | `""`                                                            | 암호의 자격 증명을 포함하는 키 |
| `gitlab.toolbox.backups.objectStorage.config.secret`       | `""`                                                            | 개체 저장소 자격 증명 암호 |
| `gitlab.toolbox.backups.objectStorage.config`              | `{}`                                                            | 개체 저장소의 인증 정보 |
| `gitlab.toolbox.bootsnap.enabled`                          | `true`                                                          | Toolbox에서 Bootsnap 캐시 활성화 |
| `gitlab.toolbox.enabled`                                   | `true`                                                          | Toolbox 활성화 플래그 |
| `gitlab.toolbox.image.pullPolicy`                          | `IfNotPresent`                                                  | Toolbox 이미지 풀 정책 |
| `gitlab.toolbox.image.repository`                          | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee`    | Toolbox 이미지 저장소 |
| `gitlab.toolbox.image.tag`                                 | `master`                                                        | Toolbox 이미지 태그 |
| `gitlab.toolbox.init.image.repository`                     |                                                                 | Toolbox init 이미지 저장소 |
| `gitlab.toolbox.init.image.tag`                            |                                                                 | Toolbox init 이미지 태그 |
| `gitlab.toolbox.init.resources.requests.cpu`               | `50m`                                                           | Toolbox init 최소 필요 CPU |
| `gitlab.toolbox.persistence.accessMode`                    | `ReadWriteOnce`                                                 | Toolbox 지속성 액세스 모드 |
| `gitlab.toolbox.persistence.enabled`                       | `false`                                                         | Toolbox 지속성 활성화 플래그 |
| `gitlab.toolbox.persistence.matchExpressions`              |                                                                 | 레이블 식 일치 바인드 |
| `gitlab.toolbox.persistence.matchLabels`                   |                                                                 | 레이블 값 일치 바인드 |
| `gitlab.toolbox.persistence.size`                          | `10Gi`                                                          | Toolbox 지속성 볼륨 크기 |
| `gitlab.toolbox.persistence.storageClass`                  |                                                                 | 프로비저닝용 storageClassName |
| `gitlab.toolbox.persistence.subPath`                       |                                                                 | Toolbox 지속성 볼륨 마운트 경로 |
| `gitlab.toolbox.persistence.volumeName`                    |                                                                 | 기존 지속성 볼륨 이름 |
| `gitlab.toolbox.psql.port`                                 |                                                                 | PostgreSQL 서버 포트를 설정하세요. `global.psql.port`보다 우선합니다 |
| `gitlab.toolbox.resources.requests.cpu`                    | `50m`                                                           | Toolbox 최소 필요 CPU |
| `gitlab.toolbox.resources.requests.memory`                 | `350M`                                                          | Toolbox 최소 필요 메모리 |
| `gitlab.toolbox.securityContext.fsGroup`                   | `1000`                                                          | 포드가 시작되어야 하는 그룹 ID |
| `gitlab.toolbox.securityContext.runAsUser`                 | `1000`                                                          | 포드가 시작되어야 하는 사용자 ID |
| `gitlab.webservice.enabled`                                | `true`                                                          | webservice 활성화 플래그 |
| `gitlab.webservice.gitaly.authToken.key`                   | `token`                                                         | Gitaly 암호의 Gitaly 토큰 키 |
| `gitlab.webservice.gitaly.authToken.secret`                | `{.Release.Name}-gitaly-secret`                                 | Gitaly 암호 이름 |
| `gitlab.webservice.gitaly.serviceName`                     | `gitaly`                                                        | Gitaly 서비스 이름 |
| `gitlab.webservice.image.pullPolicy`                       |                                                                 | webservice 이미지 풀 정책 |
| `gitlab.webservice.image.repository`                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ee` | webservice 이미지 저장소 |
| `gitlab.webservice.image.tag`                              | `master`                                                        | webservice 이미지 태그 |
| `gitlab.webservice.psql.password.key`                      | `psql-password`                                                 | PostgreSQL 암호의 PostgreSQL 암호 키 |
| `gitlab.webservice.psql.password.secret`                   | `gitlab-postgres`                                               | PostgreSQL 암호 이름 |
| `gitlab.webservice.psql.port`                              |                                                                 | PostgreSQL 서버 포트를 설정하세요. `global.psql.port`보다 우선합니다 |
| `global.registry.enabled`                                  | `true`                                                          | 레지스트리 활성화. `registry.enabled`을 미러 |
| `global.registry.api.port`                                 | `5000`                                                          | 레지스트리 포트 |
| `global.registry.api.protocol`                             | `http`                                                          | 레지스트리 프로토콜 |
| `global.registry.api.serviceName`                          | `registry`                                                      | 레지스트리 서비스 이름 |
| `global.registry.tokenIssuer`                              | `gitlab-issuer`                                                 | 레지스트리 토큰 발급자 |
| `gitlab.webservice.replicaCount`                           | `1`                                                             | webservice 복제본 수 |
| `gitlab.webservice.resources.requests.cpu`                 | `200m`                                                          | webservice 최소 CPU |
| `gitlab.webservice.resources.requests.memory`              | `1.4G`                                                          | webservice 최소 메모리 |
| `gitlab.webservice.securityContext.fsGroup`                | `1000`                                                          | 포드가 시작되어야 하는 그룹 ID |
| `gitlab.webservice.securityContext.runAsUser`              | `1000`                                                          | 포드가 시작되어야 하는 사용자 ID |
| `gitlab.webservice.service.annotations`                    | `{}`                                                            | `Service`에 추가할 주석 |
| `gitlab.webservice.http.enabled`                           | `true`                                                          | webservice HTTP 활성화 |
| `gitlab.webservice.service.externalPort`                   | `8080`                                                          | webservice 노출 포트 |
| `gitlab.webservice.service.internalPort`                   | `8080`                                                          | webservice 내부 포트 |
| `gitlab.webservice.tls.enabled`                            | `false`                                                         | webservice TLS 활성화 |
| `gitlab.webservice.tls.secretName`                         | `{Release.Name}-webservice-tls`                                 | webservice TLS 키의 암호 이름 |
| `gitlab.webservice.service.tls.externalPort`               | `8081`                                                          | webservice TLS 노출 포트 |
| `gitlab.webservice.service.tls.internalPort`               | `8081`                                                          | webservice TLS 내부 포트 |
| `gitlab.webservice.service.type`                           | `ClusterIP`                                                     | webservice 서비스 유형 |
| `gitlab.webservice.service.workhorseExternalPort`          | `8181`                                                          | Workhorse 노출 포트 |
| `gitlab.webservice.service.workhorseInternalPort`          | `8181`                                                          | Workhorse 내부 포트 |
| `gitlab.webservice.shell.authToken.key`                    | `secret`                                                        | shell 암호의 shell 토큰 키 |
| `gitlab.webservice.shell.authToken.secret`                 | `{Release.Name}-gitlab-shell-secret`                            | Shell 토큰 암호 |
| `gitlab.webservice.workerProcesses`                        | `2`                                                             | webservice 워커 수 |
| `gitlab.webservice.workerTimeout`                          | `60`                                                            | webservice 워커 시간 초과 |
| `gitlab.webservice.workhorse.extraArgs`                    | `""`                                                            | workhorse의 추가 매개변수 문자열 |
| `gitlab.webservice.workhorse.image`                        | `registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ee`  | Workhorse 이미지 저장소 |
| `gitlab.webservice.workhorse.sentryDSN`                    | `""`                                                            | 오류 보고를 위한 Sentry 인스턴스 DSN |
| `gitlab.webservice.workhorse.tag`                          |                                                                 | Workhorse 이미지 태그 |

## 외부 차트 {#external-charts}

GitLab은 다른 여러 차트를 사용합니다. 이들은 [부모-자식 관계로 처리됩니다](https://helm.sh/docs/topics/charts/#chart-dependencies). 구성하려는 모든 속성이 `chart-name.property`로 제공되는지 확인하세요.

### Prometheus {#prometheus}

Prometheus 값 접두사를 `prometheus`로 지정하세요. 예를 들어 `prometheus.server.persistentVolume.size`를 사용하여 지속성 저장소 값을 설정하세요. Prometheus를 비활성화하려면 `prometheus.install=false`를 설정하세요.

구성 옵션의 전체 목록은 [Prometheus 차트 설명서](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus)를 참조하세요.

## 자신의 이미지 가져오기 {#bringing-your-own-images}

특정 시나리오(예: 오프라인 환경)에서는 인터넷에서 이미지를 끌어오기보다는 자신의 이미지를 가져오고 싶을 수 있습니다. 이를 위해서는 GitLab 릴리스를 구성하는 각 차트에 대해 자신의 Docker 이미지 레지스트리/저장소를 지정해야 합니다.

자세한 내용은 [사용자 정의 이미지 설명서](../advanced/custom-images/_index.md)를 참조하세요.
