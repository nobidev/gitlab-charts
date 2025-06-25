---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Helmチャートのデプロイオプション
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

このページには、一般的に使用されるGitLabチャートの値がリストされています。利用可能なオプションの完全なリストについては、各サブチャートのドキュメントを参照してください。

YAMLファイルと`--values <values file>`フラグを使用するか、複数の`--set`フラグを使用して、`helm install`コマンドに値を渡すことができます。リリースに必要なオーバーライドのみを含む値ファイルを使用することをお勧めします。

デフォルトの`values.yaml`ファイルのソースは、[こちら](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/values.yaml)にあります。これらの内容はリリースによって異なりますが、Helm自体を使用して、バージョンごとにこれらを取得できます。

```shell
helm inspect values gitlab/gitlab
```

## 基本設定 {#basic-configuration}

| パラメータ                                            | デフォルト                                       | 説明 |
|------------------------------------------------------|-----------------------------------------------|-------------|
| `gitlab.migrations.initialRootPassword.key`          | `password`                                    | 移行シークレット内のルートアカウントパスワードを指すキー |
| `gitlab.migrations.initialRootPassword.secret`       | `{Release.Name}-gitlab-initial-root-password` | ルートアカウントパスワードを含むシークレットのグローバル名 |
| `global.gitlab.license.key`                          | `license`                                     | ライセンスシークレット内のEnterpriseライセンスを指すキー |
| `global.gitlab.license.secret`                       | _なし_                                        | Enterpriseライセンスを含むシークレットのグローバル名 |
| `global.application.create`                          | `false`                                       | GitLabの[アプリケーションリソース](https://github.com/kubernetes-sigs/application)を作成します |
| `global.edition`                                     | `ee`                                          | インストールするGitLabのエディション。Enterprise Edition（`ee`）またはCommunity Edition（`ce`） |
| `global.gitaly.enabled`                              | `true`                                        | Gitaly有効フラグ |
| `global.hosts.domain`                                | 必須                                      | 公開されているすべてのサービスに使用されるドメイン名 |
| `global.hosts.externalIP`                            | 必須                                      | NGINX Ingressコントローラーに割り当てる静的IP |
| `global.hosts.ssh`                                   | `gitlab.{global.hosts.domain}`                | Git SSHアクセスに使用されるドメイン名 |
| `global.imagePullPolicy`                             | `IfNotPresent`                                | 非推奨:`global.image.pullPolicy`の代わりに使用してください |
| `global.image.pullPolicy`                            | _なし_ (デフォルトの動作は`IfNotPresent`です)   | すべてのチャートのデフォルトのimagePullPolicyを設定します |
| `global.image.pullSecrets`                           | _なし_                                        | すべてのチャートのデフォルトのimagePullSecretsを設定します（`name`と値のペアのリストを使用） |
| `global.minio.enabled`                               | `true`                                        | MinIO有効フラグ |
| `global.psql.host`                                   | _インクラスターの非本番環境PostgreSQLを使用_   | 外部psqlのグローバルホスト名、サブチャートのpsql設定をオーバーライドします |
| `global.psql.password.key`                           | _インクラスターの非本番環境PostgreSQLを使用_   | psqlシークレット内のpsqlパスワードを指すキー |
| `global.psql.password.secret`                        | _インクラスターの非本番環境PostgreSQLを使用_   | psqlパスワードを含むシークレットのグローバル名 |
| `global.registry.bucket`                             | `registry`                                    | レジストリバケット名 |
| `global.service.annotations`                         | `{}`                                          | すべての`Service`に追加するアノテーション |
| `global.rails.sessionStore.sessionCookieTokenPrefix` | `""`                                          | 生成されたセッションCookieのプレフィックス |
| `global.deployment.annotations`                      | `{}`                                          | すべての`Deployment`に追加するアノテーション |
| `global.time_zone`                                   | UTC                                           | グローバルタイムゾーン |

## TLS設定 {#tls-configuration}

| パラメータ                                           | デフォルト | 説明 |
|-----------------------------------------------------|---------|-------------|
| `certmanager-issuer.email`                          | `false` | Let's Encryptアカウントのメール |
| `gitlab.webservice.ingress.tls.secretName`          | _なし_  | GitLabのTLS証明書とキーを含む既存の`Secret` |
| `gitlab.webservice.ingress.tls.smartcardSecretName` | _なし_  | GitLabスマートカード認証ドメインのTLS証明書とキーを含む既存の`Secret` |
| `global.hosts.https`                                | `true`  | https経由で提供 |
| `global.ingress.configureCertmanager`               | `true`  | Let's Encryptから証明書を取得するようにcert-managerを設定します |
| `global.ingress.tls.secretName`                     | _なし_  | ワイルドカードTLS証明書とキーを含む既存の`Secret` |
| `minio.ingress.tls.secretName`                      | _なし_  | MinIOのTLS証明書とキーを含む既存の`Secret` |
| `registry.ingress.tls.secretName`                   | _なし_  | レジストリのTLS証明書とキーを含む既存の`Secret` |

## 送信メールの設定 {#outgoing-email-configuration}

| パラメータ                         | デフォルト               | 説明 |
|-----------------------------------|-----------------------|-------------|
| `global.email.display_name`       | `GitLab`              | GitLabからのメールの送信者として表示される名前 |
| `global.email.from`               | `gitlab@example.com`  | GitLabからのメールの送信者として表示されるメールアドレス |
| `global.email.reply_to`           | `noreply@example.com` | GitLabからのメールにリストされている返信先メール |
| `global.email.smime.certName`     | `tls.crt`             | S/MIME証明書ファイルの場所を特定するためのシークレットオブジェクトキー値 |
| `global.email.smime.enabled`      | `false`               | 送信メールにS/MIME署名を追加します |
| `global.email.smime.keyName`      | `tls.key`             | S/MIMEキーファイルの場所を特定するためのシークレットオブジェクトキー値 |
| `global.email.smime.secretName`   | `""`                  | X.509証明書を検索するKubernetesシークレットオブジェクト（作成用の[S/MIME証明書](secrets.md#smime-certificate)） |
| `global.email.subject_suffix`     | `""`                  | GitLabからのすべての送信メールの件名のサフィックス |
| `global.smtp.address`             | `smtp.mailgun.org`    | リモートメールサーバーのホスト名またはIP |
| `global.smtp.authentication`      | `plain`               | SMTP認証のタイプ（「plain」、「login」、「cram_md5」、または認証なしの場合は「」） |
| `global.smtp.domain`              | `""`                  | SMTPのオプションのHELOドメイン |
| `global.smtp.enabled`             | `false`               | 送信メールを有効にする |
| `global.smtp.openssl_verify_mode` | `peer`                | TLS検証モード（「none」、「peer」、「client_once」、または「fail_if_no_peer_cert」） |
| `global.smtp.password.key`        | `password`            | `global.smtp.password.secret`内のSMTPパスワードを含むキー |
| `global.smtp.password.secret`     | `""`                  | SMTPパスワードを含む`Secret`の名前 |
| `global.smtp.port`                | `2525`                | SMTPのポート |
| `global.smtp.starttls_auto`       | `false`               | メールサーバーで有効になっている場合は、STARTTLSを使用します |
| `global.smtp.tls`                 | _なし_                | SMTP/TLSを有効にします（SMTPS:ダイレクトTLS接続経由のSMTP) |
| `global.smtp.user_name`           | `""`                  | SMTP認証httpsのユーザー名 |
| `global.smtp.open_timeout`        | `30`                  | 接続を試行中に待機する秒数。 |
| `global.smtp.read_timeout`        | `60`                  | 1つのブロックの読み取り中に待機する秒数。 |
| `global.smtp.pool`                | `false`               | SMTP接続プーリングを有効にします |

### Microsoft Graph Mailerの設定 {#microsoft-graph-mailer-settings}

| パラメータ                                                      | デフォルト                             | 説明 |
|----------------------------------------------------------------|-------------------------------------|-------------|
| `global.appConfig.microsoft_graph_mailer.enabled`              | `false`                             | Microsoft Graph API経由で送信メールを有効にする |
| `global.appConfig.microsoft_graph_mailer.user_id`              | `""`                                | Microsoft Graph APIを使用するユーザーの一意の識別子 |
| `global.appConfig.microsoft_graph_mailer.tenant`               | `""`                                | アプリケーションが動作を計画しているディレクトリテナント（GUIDまたはドメイン名形式） |
| `global.appConfig.microsoft_graph_mailer.client_id`            | `""`                                | アプリに割り当てられているアプリケーションID。この情報は、アプリを登録したポータルにあります |
| `global.appConfig.microsoft_graph_mailer.client_secret.key`    | `secret`                            | アプリ登録ポータルでアプリ用に生成したクライアントシークレットを含む`global.appConfig.microsoft_graph_mailer.client_secret.secret`内のキー |
| `global.appConfig.microsoft_graph_mailer.client_secret.secret` | `""`                                | アプリ登録ポータルでアプリ用に生成したクライアントシークレットを含む`Secret`の名前 |
| `global.appConfig.microsoft_graph_mailer.azure_ad_endpoint`    | `https://login.microsoftonline.com` | Azure Active DirectoryエンドポイントのURL |
| `global.appConfig.microsoft_graph_mailer.graph_endpoint`       | `https://graph.microsoft.com`       | Microsoft GraphエンドポイントのURL |

## 受信メールの設定 {#incoming-email-configuration}

### 共通設定 {#common-settings}

詳細については、[受信メール設定の例のドキュメント](https://docs.gitlab.com/administration/incoming_email/#configuration-examples)を参照してください。

| パラメータ                                            | デフォルト                                    | 説明 |
|------------------------------------------------------|--------------------------------------------|-------------|
| `global.appConfig.incomingEmail.address`             | 空                                      | 返信されるアイテムを参照するメールアドレス（例：`gitlab-incoming+%{key}@gmail.com`）。`+%{key}`サフィックスは、メールアドレス全体に含める必要があり、別の値に置き換えないでください。 |
| `global.appConfig.incomingEmail.enabled`             | `false`                                    | 受信メールを有効にする |
| `global.appConfig.incomingEmail.deleteAfterDelivery` | `true`                                     | メッセージを削除済みとしてマークするかどうか。IMAPの場合、削除済みとしてマークされたメッセージは、`expungedDeleted`が`true`に設定されている場合に消滅します。Microsoft Graphの場合、削除されたメッセージはしばらくすると自動的に消滅するため、インボックスにメッセージを保持するには、これをfalseに設定します。 |
| `global.appConfig.incomingEmail.expungeDeleted`      | `false`                                    | 配信後に削除済みとしてマークされたメッセージをメールボックスから消去（完全に削除）するかどうか。Microsoft Graphが削除されたメッセージを自動的に消去するため、IMAPにのみ関連します。 |
| `global.appConfig.incomingEmail.logger.logPath`      | `/dev/stdout`                              | JSON構造化されたログを書き込むパス。このログの生成を無効にするには、「」に設定します |
| `global.appConfig.incomingEmail.inboxMethod`         | `imap`                                     | IMAP（`imap`）またはOAuth2を使用したMicrosoft Graph API（`microsoft_graph`）でメールを読み取ります |
| `global.appConfig.incomingEmail.deliveryMethod`      | `webhook`                                  | Mailroomがメールコンテンツを処理のためにRailsアプリに送信する方法。`sidekiq`または`webhook`のいずれか |
| `gitlab.appConfig.incomingEmail.authToken.key`       | `authToken`                                | 受信メールシークレット内の受信メールトークンへのキー。配信方法がWebhookの場合に有効です。 |
| `gitlab.appConfig.incomingEmail.authToken.secret`    | `{Release.Name}-incoming-email-auth-token` | 受信メール認証シークレット。配信方法がWebhookの場合に有効です。 |

### IMAP設定 {#imap-settings}

| パラメータ                                        | デフォルト    | 説明 |
|--------------------------------------------------|------------|-------------|
| `global.appConfig.incomingEmail.host`            | 空      | IMAPのホスト |
| `global.appConfig.incomingEmail.idleTimeout`     | `60`       | IDLEコマンドのタイムアウト |
| `global.appConfig.incomingEmail.mailbox`         | `inbox`    | 受信メールの最終的な送信先となるメールボックス。 |
| `global.appConfig.incomingEmail.password.key`    | `password` | `global.appConfig.incomingEmail.password.secret`内のIMAPパスワードを含むキー |
| `global.appConfig.incomingEmail.password.secret` | 空      | IMAPパスワードを含む`Secret`の名前 |
| `global.appConfig.incomingEmail.port`            | `993`      | IMAPのポート |
| `global.appConfig.incomingEmail.ssl`             | `true`     | IMAPサーバーがSSLを使用するかどうか |
| `global.appConfig.incomingEmail.startTls`        | `false`    | IMAPサーバーがStartTLSを使用するかどうか |
| `global.appConfig.incomingEmail.user`            | 空      | IMAP認証のユーザー名 |

### Microsoft Graphの設定 {#microsoft-graph-settings}

| パラメータ                                            | デフォルト | 説明 |
|------------------------------------------------------|---------|-------------|
| `global.appConfig.incomingEmail.tenantId`            | 空   | Microsoft Azure Active DirectoryのテナントID |
| `global.appConfig.incomingEmail.clientId`            | 空   | OAuth2アプリのクライアントID |
| `global.appConfig.incomingEmail.clientSecret.key`    | 空   | OAuth2クライアントシークレットを含む`appConfig.incomingEmail.clientSecret.secret`内のキー |
| `global.appConfig.incomingEmail.clientSecret.secret` | シークレット  | OAuth2クライアントシークレットを含む`Secret`の名前 |
| `global.appConfig.incomingEmail.pollInterval`        | `60`    | 新しいメールのポーリング頻度（秒単位） |
| `global.appConfig.incomingEmail.azureAdEndpoint`     | 空   | Azure Active DirectoryエンドポイントのURL（例：`https://login.microsoftonline.com`） |
| `global.appConfig.incomingEmail.graphEndpoint`       | 空   | Microsoft GraphエンドポイントのURL（例：`https://graph.microsoft.com`） |

[シークレットの作成手順](secrets.md)を参照してください。

## サービスデスクのメール設定 {#service-desk-email-configuration}

サービスデスクの要件として、受信メールを[設定](#incoming-email-configuration)する必要があります。受信メールとサービスデスクの両方のメールアドレスで、[メールサブアドレス](https://docs.gitlab.com/administration/incoming_email/#email-sub-addressing)を使用する必要があることに注意してください。各セクションでメールアドレスを設定する場合、ユーザー名に追加されるtagは`+%{key}`である必要があります。

### 共通設定 {#common-settings-1}

| パラメータ                                               | デフォルト                                        | 説明 |
|---------------------------------------------------------|------------------------------------------------|-------------|
| `global.appConfig.serviceDeskEmail.address`             | 空                                          | 返信されるアイテムを参照するメールアドレス（例：`project_contact+%{key}@gmail.com`） |
| `global.appConfig.serviceDeskEmail.enabled`             | `false`                                        | サービスデスクのメールを有効にする |
| `global.appConfig.serviceDeskEmail.deleteAfterDelivery` | `true`                                         | メッセージを削除済みとしてマークするかどうか。IMAPの場合、削除済みとしてマークされたメッセージは、`expungedDeleted`が`true`に設定されている場合に消滅します。Microsoft Graphの場合、削除されたメッセージはしばらくすると自動的に消滅するため、インボックスにメッセージを保持するには、これをfalseに設定します。 |
| `global.appConfig.serviceDeskEmail.expungeDeleted`      | `false`                                        | 配信後に削除済みとしてマークされたメッセージをメールボックスから消去（完全に削除）するかどうか。Microsoft Graphが削除されたメッセージを自動的に消去するため、IMAPにのみ関連します。 |
| `global.appConfig.serviceDeskEmail.logger.logPath`      | `/dev/stdout`                                  | JSON構造化されたログを書き込むパス。このログの生成を無効にするには、「」に設定します |
| `global.appConfig.serviceDeskEmail.inboxMethod`         | `imap`                                         | IMAP（`imap`）またはOAuth2を使用したMicrosoft Graph API（`microsoft_graph`）でメールを読み取ります |
| `global.appConfig.serviceDeskEmail.deliveryMethod`      | `webhook`                                      | Mailroomがメールコンテンツを処理のためにRailsアプリに送信する方法。`sidekiq`または`webhook`のいずれか |
| `gitlab.appConfig.serviceDeskEmail.authToken.key`       | `authToken`                                    | サービスデスクのメールシークレット内のサービスデスクのメールトークンへのキー。配信方法がWebhookの場合に有効です。 |
| `gitlab.appConfig.serviceDeskEmail.authToken.secret`    | `{Release.Name}-service-desk-email-auth-token` | サービスデスクメール認証シークレット。配信方法がWebhookの場合に有効です。 |

### IMAP設定 {#imap-settings-1}

| パラメータ                                           | デフォルト    | 説明 |
|-----------------------------------------------------|------------|-------------|
| `global.appConfig.serviceDeskEmail.host`            | 空      | IMAPのホスト |
| `global.appConfig.serviceDeskEmail.idleTimeout`     | `60`       | IDLEコマンドのタイムアウト |
| `global.appConfig.serviceDeskEmail.mailbox`         | `inbox`    | サービスデスクメールの最終的な送信先となるメールボックス。 |
| `global.appConfig.serviceDeskEmail.password.key`    | `password` | `global.appConfig.serviceDeskEmail.password.secret`内のIMAPパスワードを含むキー |
| `global.appConfig.serviceDeskEmail.password.secret` | 空      | IMAPパスワードを含む`Secret`の名前 |
| `global.appConfig.serviceDeskEmail.port`            | `993`      | IMAPのポート |
| `global.appConfig.serviceDeskEmail.ssl`             | `true`     | IMAPサーバーがSSLを使用するかどうか |
| `global.appConfig.serviceDeskEmail.startTls`        | `false`    | IMAPサーバーがStartTLSを使用するかどうか |
| `global.appConfig.serviceDeskEmail.user`            | 空      | IMAP認証のユーザー名 |

### Microsoft Graphの設定 {#microsoft-graph-settings-1}

| パラメータ                                               | デフォルト | 説明 |
|---------------------------------------------------------|---------|-------------|
| `global.appConfig.serviceDeskEmail.tenantId`            | 空   | Microsoft Azure Active DirectoryのテナントID |
| `global.appConfig.serviceDeskEmail.clientId`            | 空   | OAuth2アプリのクライアントID |
| `global.appConfig.serviceDeskEmail.clientSecret.key`    | 空   | OAuth2クライアントシークレットを含む`appConfig.serviceDeskEmail.clientSecret.secret`内のキー |
| `global.appConfig.serviceDeskEmail.clientSecret.secret` | シークレット  | OAuth2クライアントシークレットを含む`Secret`の名前 |
| `global.appConfig.serviceDeskEmail.pollInterval`        | `60`    | 新しいメールのポーリング頻度（秒単位） |
| `global.appConfig.serviceDeskEmail.azureAdEndpoint`     | 空   | Azure Active DirectoryエンドポイントのURL（例：`https://login.microsoftonline.com`） |
| `global.appConfig.serviceDeskEmail.graphEndpoint`       | 空   | Microsoft GraphエンドポイントのURL（例：`https://graph.microsoft.com`） |

[シークレットの作成手順](secrets.md)を参照してください。

## デフォルトのプロジェクトの機能の設定 {#default-project-features-configuration}

| パラメータ                                                    | デフォルト | 説明 |
|--------------------------------------------------------------|---------|-------------|
| `global.appConfig.defaultProjectsFeatures.builds`            | `true`  | プロジェクトのビルドを有効にする |
| `global.appConfig.defaultProjectsFeatures.containerRegistry` | `true`  | コンテナレジストリプロジェクトの機能を有効にする |
| `global.appConfig.defaultProjectsFeatures.issues`            | `true`  | プロジェクトイシューを有効にする |
| `global.appConfig.defaultProjectsFeatures.mergeRequests`     | `true`  | プロジェクトマージリクエストを有効にする |
| `global.appConfig.defaultProjectsFeatures.snippets`          | `true`  | プロジェクトスニペットを有効にする |
| `global.appConfig.defaultProjectsFeatures.wiki`              | `true`  | プロジェクトWikiを有効にする |

## GitLab Shell {#gitlab-shell}

| パラメータ                        | デフォルト | 説明 |
|----------------------------------|---------|-------------|
| `global.shell.authToken`         |         | 共有シークレットを含むシークレット |
| `global.shell.hostKeys`          |         | SSHホストキーを含むシークレット |
| `global.shell.port`              |         | SSHのIngressで公開するポート番号 |
| `global.shell.tcp.proxyProtocol` | `false` | SSH IngressでProxyProtocolを有効にする |

## RBAC設定 {#rbac-settings}

| パラメータ                              | デフォルト | 説明 |
|----------------------------------------|---------|-------------|
| `certmanager.rbac.create`              | `true`  | RBACリソースを作成して使用する |
| `gitlab-runner.rbac.create`            | `true`  | RBACリソースを作成して使用する |
| `nginx-ingress.rbac.create`            | `false` | デフォルトのRBACリソースを作成して使用する |
| `nginx-ingress.rbac.createClusterRole` | `false` | クラスターロールを作成して使用する |
| `nginx-ingress.rbac.createRole`        | `true`  | 名前空間ロールを作成して使用する |
| `prometheus.rbac.create`               | `true`  | RBACリソースを作成して使用する |

`nginx-ingress.rbac.create`を`false`に設定してRBACルールを自分で構成する場合、[チャートバージョンに応じて](../releases/8_0.md#upgrade-to-86x-851-843-836)特定のRBACルールを追加する必要がある場合があります。

## 高度なNGINX Ingressの設定 {#advanced-nginx-ingress-configuration}

NGINX Ingressの値を`nginx-ingress`でプレフィックスします。たとえば、`nginx-ingress.controller.image.tag`を使用してコントローラーイメージのtagを設定します。

[`nginx-ingress`チャート](../charts/nginx/_index.md)を参照してください。

## 高度なインクラスターRedisの設定 {#advanced-in-cluster-redis-configuration}

| パラメータ                 | デフォルト               | 説明 |
|---------------------------|-----------------------|-------------|
| `redis.install`           | `true`                | `bitnami/redis`チャートをインストールします |
| `redis.existingSecret`    | `gitlab-redis-secret` | Redisサーバーで使用するシークレットを指定します |
| `redis.existingSecretKey` | `redis-password`      | パスワードが保存されているシークレットキー |

Redisサービスの追加設定では、[Redisチャート](https://github.com/bitnami/charts/tree/main/bitnami/redis)の設定を使用してください。

## 高度なレジストリ設定 {#advanced-registry-configuration}

| パラメータ                                           | デフォルト                                     | 説明 |
|-----------------------------------------------------|---------------------------------------------|-------------|
| `registry.authEndpoint`                             | デフォルトでは未定義                        | 認証エンドポイント |
| `registry.enabled`                                  | `true`                                      | Dockerレジストリを有効にする |
| `registry.httpSecret`                               |                                             | Httpsシークレット |
| `registry.minio.bucket`                             | `registry`                                  | MinIOレジストリバケット名 |
| `registry.service.annotations`                      | `{}`                                        | `Service`に追加する注釈 |
| `registry.securityContext.fsGroup`                  | `1000`                                      | ポッドの起動に使用するグループID |
| `registry.securityContext.runAsUser`                | `1000`                                      | ポッドの起動に使用するユーザーID |
| `registry.tokenIssuer`                              | `gitlab-issuer`                             | JWTトークン発行者 |
| `registry.tokenService`                             | `container_registry`                        | JWTトークンサービス |
| `registry.profiling.stackdriver.enabled`            | `false`                                     | Stackdriverを使用した継続的なプロファイリングを有効にする |
| `registry.profiling.stackdriver.credentials.secret` | `gitlab-registry-profiling-creds`           | 認証情報を含むシークレットの名前 |
| `registry.profiling.stackdriver.credentials.key`    | `credentials`                               | 認証情報の保存先のシークレットキー |
| `registry.profiling.stackdriver.service`            | `RELEASE-registry`（テンプレート化されたサービス名） | プロファイルの記録先のStackdriverサービスの名前 |
| `registry.profiling.stackdriver.projectid`          | 実行中のGCPプロジェクト                   | プロファイルのレポート先のGCPプロジェクト |

## 高度なMinIO設定 {#advanced-minio-configuration}

| パラメータ                            | デフォルト                        | 説明 |
|--------------------------------------|--------------------------------|-------------|
| `minio.defaultBuckets`               | `[{"name": "registry"}]`       | MinIOのデフォルトバケット |
| `minio.image`                        | `minio/minio`                  | MinIOイメージ |
| `minio.imagePullPolicy`              |                                | MinIOイメージのプルポリシー |
| `minio.imageTag`                     | `RELEASE.2017-12-28T01-21-00Z` | MinIOイメージtag |
| `minio.minioConfig.browser`          | `on`                           | MinIOブラウザーフラグ |
| `minio.minioConfig.domain`           |                                | MinIOドメイン |
| `minio.minioConfig.region`           | `us-east-1`                    | MinIOリージョン |
| `minio.mountPath`                    | `/export`                      | MinIO設定ファイルのmountパス |
| `minio.persistence.accessMode`       | `ReadWriteOnce`                | MinIOの永続アクセスモード |
| `minio.persistence.enabled`          | `true`                         | MinIOの永続フラグを有効にする |
| `minio.persistence.matchExpressions` |                                | バインドするMinIOラベル式の一致 |
| `minio.persistence.matchLabels`      |                                | バインドするMinIOラベル値の一致 |
| `minio.persistence.size`             | `10Gi`                         | MinIOの永続ボリュームサイズ |
| `minio.persistence.storageClass`     |                                | プロビジョニング用のMinIO storageClassName |
| `minio.persistence.subPath`          |                                | MinIOの永続ボリュームのmountパス |
| `minio.persistence.volumeName`       |                                | MinIOの既存の永続ボリューム名 |
| `minio.resources.requests.cpu`       | `250m`                         | リクエストされたMinIOの最小CPU |
| `minio.resources.requests.memory`    | `256Mi`                        | リクエストされたMinIOの最小メモリ |
| `minio.service.annotations`          | `{}`                           | `Service`に追加する注釈 |
| `minio.servicePort`                  | `9000`                         | MinIOサービスポート |
| `minio.serviceType`                  | `ClusterIP`                    | MinIOサービスタイプ |

## 高度なGitLab設定 {#advanced-gitlab-configuration}

| パラメータ                                                  | デフォルト                                                         | 説明 |
|------------------------------------------------------------|-----------------------------------------------------------------|-------------|
| `gitlab-runner.checkInterval`                              | `30s`                                                           | ポーリングの間隔 |
| `gitlab-runner.concurrent`                                 | `20`                                                            | 同時ジョブ数 |
| `gitlab-runner.imagePullPolicy`                            | `IfNotPresent`                                                  | イメージのプルポリシー |
| `gitlab-runner.image`                                      | `gitlab/gitlab-runner:alpine-v10.5.0`                           | runnerイメージ |
| `gitlab-runner.gitlabUrl`                                  | GitLabの外部URL                                             | RunnerがGitLabサーバーに登録するために使用するURL |
| `gitlab-runner.install`                                    | `true`                                                          | `gitlab-runner`チャートをインストールする |
| `gitlab-runner.rbac.clusterWideAccess`                     | `false`                                                         | ジョブのコンテナをクラスター全体にデプロイする |
| `gitlab-runner.rbac.create`                                | `true`                                                          | RBACサービスアカウントを作成するかどうか |
| `gitlab-runner.rbac.serviceAccountName`                    | `default`                                                       | 作成するRBACサービスアカウントの名前 |
| `gitlab-runner.resources.limits.cpu`                       |                                                                 | runnerリソース |
| `gitlab-runner.resources.limits.memory`                    |                                                                 | runnerリソース |
| `gitlab-runner.resources.requests.cpu`                     |                                                                 | runnerリソース |
| `gitlab-runner.resources.requests.memory`                  |                                                                 | runnerリソース |
| `gitlab-runner.runners.privileged`                         | `false`                                                         | 特権モードで実行する（`dind`に必要） |
| `gitlab-runner.runners.cache.secretName`                   | `gitlab-minio`                                                  | `accesskey`と`secretkey`を取得するためのシークレット |
| `gitlab-runner.runners.config`                             | [チャートのドキュメント](../charts/gitlab/gitlab-runner/_index.md#default-runner-configuration)を参照してください | 文字列としてのRunnerの設定 |
| `gitlab-runner.unregisterRunners`                          | `true`                                                          | チャートのインストール時に、ローカルの`config.toml`にあるすべてのrunnerを登録解除します。トークンのプレフィックスが`glrt-`の場合、runnerではなく、Runnerマネージャーが削除されます。Runnerマネージャーは、runnerと`config.toml`を含むマシンによって識別されます。Runnerが登録トークンで登録された場合、runnerは削除されます。 |
| `gitlab.geo-logcursor.securityContext.fsGroup`             | `1000`                                                          | ポッドの起動に使用するグループID |
| `gitlab.geo-logcursor.securityContext.runAsUser`           | `1000`                                                          | ポッドの起動に使用するユーザーID |
| `gitlab.gitaly.authToken.key`                              | `token`                                                         | シークレット内のGitalyトークンのキー |
| `gitlab.gitaly.authToken.secret`                           | `{.Release.Name}-gitaly-secret`                                 | Gitalyシークレット名 |
| `gitlab.gitaly.image.pullPolicy`                           |                                                                 | Gitalyイメージのプルポリシー |
| `gitlab.gitaly.image.repository`                           | `registry.gitlab.com/gitlab-org/build/cng/gitaly`               | Gitalyイメージリポジトリ |
| `gitlab.gitaly.image.tag`                                  | `master`                                                        | Gitalyイメージtag |
| `gitlab.gitaly.persistence.accessMode`                     | `ReadWriteOnce`                                                 | Gitalyの永続アクセスモード |
| `gitlab.gitaly.persistence.enabled`                        | `true`                                                          | Gitalyの永続フラグを有効にする |
| `gitlab.gitaly.persistence.matchExpressions`               |                                                                 | バインドするラベル式の一致 |
| `gitlab.gitaly.persistence.matchLabels`                    |                                                                 | バインドするラベル値の一致 |
| `gitlab.gitaly.persistence.size`                           | `50Gi`                                                          | Gitalyの永続ボリュームサイズ |
| `gitlab.gitaly.persistence.storageClass`                   |                                                                 | プロビジョニング用のstorageClassName |
| `gitlab.gitaly.persistence.subPath`                        |                                                                 | Gitalyの永続ボリュームのmountパス |
| `gitlab.gitaly.persistence.volumeName`                     |                                                                 | 既存の永続ボリューム名 |
| `gitlab.gitaly.securityContext.fsGroup`                    | `1000`                                                          | ポッドの起動に使用するグループID |
| `gitlab.gitaly.securityContext.runAsUser`                  | `1000`                                                          | ポッドの起動に使用するユーザーID |
| `gitlab.gitaly.service.annotations`                        | `{}`                                                            | `Service`に追加する注釈 |
| `gitlab.gitaly.service.externalPort`                       | `8075`                                                          | Gitalyサービス公開ポート |
| `gitlab.gitaly.service.internalPort`                       | `8075`                                                          | Gitaly内部ポート |
| `gitlab.gitaly.service.name`                               | `gitaly`                                                        | Gitalyサービス名 |
| `gitlab.gitaly.service.type`                               | `ClusterIP`                                                     | Gitalyサービスタイプ |
| `gitlab.gitaly.serviceName`                                | `gitaly`                                                        | Gitalyサービス名 |
| `gitlab.gitaly.shell.authToken.key`                        | `secret`                                                        | Shellキー   |
| `gitlab.gitaly.shell.authToken.secret`                     | `{Release.Name}-gitlab-shell-secret`                            | Shellシークレット |
| `gitlab.gitlab-exporter.securityContext.fsGroup`           | `1000`                                                          | ポッドの起動に使用するグループID |
| `gitlab.gitlab-exporter.securityContext.runAsUser`         | `1000`                                                          | ポッドの起動に使用するユーザーID |
| `gitlab.gitlab-shell.authToken.key`                        | `secret`                                                        | Shell認証シークレットキー |
| `gitlab.gitlab-shell.authToken.secret`                     | `{Release.Name}-gitlab-shell-secret`                            | Shell認証シークレット |
| `gitlab.gitlab-shell.enabled`                              | `true`                                                          | Shellの有効フラグ |
| `gitlab.gitlab-shell.image.pullPolicy`                     |                                                                 | Shellイメージのプルポリシー |
| `gitlab.gitlab-shell.image.repository`                     | `registry.gitlab.com/gitlab-org/build/cng/gitlab-shell`         | Shellイメージリポジトリ |
| `gitlab.gitlab-shell.image.tag`                            | `master`                                                        | Shellイメージtag |
| `gitlab.gitlab-shell.replicaCount`                         | `1`                                                             | Shellレプリカ |
| `gitlab.gitlab-shell.securityContext.fsGroup`              | `1000`                                                          | ポッドの起動に使用するグループID |
| `gitlab.gitlab-shell.securityContext.runAsUser`            | `1000`                                                          | ポッドの起動に使用するユーザーID |
| `gitlab.gitlab-shell.service.annotations`                  | `{}`                                                            | `Service`に追加する注釈 |
| `gitlab.gitlab-shell.service.internalPort`                 | `2222`                                                          | Shell内部ポート |
| `gitlab.gitlab-shell.service.name`                         | `gitlab-shell`                                                  | Shellサービス名 |
| `gitlab.gitlab-shell.service.type`                         | `ClusterIP`                                                     | Shellサービスタイプ |
| `gitlab.gitlab-shell.webservice.serviceName`               | `global.webservice.serviceName`から継承                  | Webserviceサービス名 |
| `gitlab.mailroom.securityContext.fsGroup`                  | `1000`                                                          | ポッドの起動に使用するグループID |
| `gitlab.mailroom.securityContext.runAsUser`                | `1000`                                                          | ポッドの起動に使用するユーザーID |
| `gitlab.migrations.bootsnap.enabled`                       | `true`                                                          | 移行Bootsnapの有効フラグ |
| `gitlab.migrations.enabled`                                | `true`                                                          | 移行の有効フラグ |
| `gitlab.migrations.image.pullPolicy`                       |                                                                 | 移行のプルポリシー |
| `gitlab.migrations.image.repository`                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee`    | 移行イメージリポジトリ |
| `gitlab.migrations.image.tag`                              | `master`                                                        | 移行イメージtag |
| `gitlab.migrations.psql.password.key`                      | `psql-password`                                                 | psqlシークレット内のpsqlパスワードへのキー |
| `gitlab.migrations.psql.password.secret`                   | `gitlab-postgres`                                               | psqlシークレット |
| `gitlab.migrations.psql.port`                              |                                                                 | PostgreSQLサーバーポートを設定します。`global.psql.port`より優先されます |
| `gitlab.migrations.securityContext.fsGroup`                | `1000`                                                          | ポッドの起動に使用するグループID |
| `gitlab.migrations.securityContext.runAsUser`              | `1000`                                                          | ポッドの起動に使用するユーザーID |
| `gitlab.sidekiq.concurrency`                               | `20`                                                            | Sidekiqのデフォルトの並行処理 |
| `gitlab.sidekiq.enabled`                                   | `true`                                                          | Sidekiqの有効フラグ |
| `gitlab.sidekiq.gitaly.authToken.key`                      | `token`                                                         | Gitalyシークレット内のGitalyトークンへのキー |
| `gitlab.sidekiq.gitaly.authToken.secret`                   | `{.Release.Name}-gitaly-secret`                                 | Gitalyシークレット |
| `gitlab.sidekiq.gitaly.serviceName`                        | `gitaly`                                                        | Gitalyサービス名 |
| `gitlab.sidekiq.image.pullPolicy`                          |                                                                 | Sidekiqイメージのプルポリシー |
| `gitlab.sidekiq.image.repository`                          | `registry.gitlab.com/gitlab-org/build/cng/gitlab-sidekiq-ee`    | Sidekiqイメージリポジトリ |
| `gitlab.sidekiq.image.tag`                                 | `master`                                                        | Sidekiqイメージtag |
| `gitlab.sidekiq.psql.password.key`                         | `psql-password`                                                 | psqlシークレット内のpsqlパスワードへのキー |
| `gitlab.sidekiq.psql.password.secret`                      | `gitlab-postgres`                                               | psqlパスワードシークレット |
| `gitlab.sidekiq.psql.port`                                 |                                                                 | PostgreSQLサーバーポートを設定します。`global.psql.port`より優先されます |
| `gitlab.sidekiq.replicas`                                  | `1`                                                             | Sidekiqレプリカ |
| `gitlab.sidekiq.resources.requests.cpu`                    | `100m`                                                          | Sidekiqに必要な最小CPU |
| `gitlab.sidekiq.resources.requests.memory`                 | `600M`                                                          | Sidekiqに必要な最小メモリ |
| `gitlab.sidekiq.securityContext.fsGroup`                   | `1000`                                                          | ポッドの起動に使用するグループID |
| `gitlab.sidekiq.securityContext.runAsUser`                 | `1000`                                                          | ポッドの起動に使用するユーザーID |
| `gitlab.sidekiq.timeout`                                   | `5`                                                             | Sidekiqジョブのタイムアウト |
| `gitlab.toolbox.annotations`                               | `{}`                                                            | ツールボックスに追加する注釈 |
| `gitlab.toolbox.backups.cron.enabled`                      | `false`                                                         | バックアップCronJobの有効フラグ |
| `gitlab.toolbox.backups.cron.extraArgs`                    |                                                                 | バックアップユーティリティに渡す引数の文字列 |
| `gitlab.toolbox.backups.cron.persistence.accessMode`       | `ReadWriteOnce`                                                 | バックアップcronの永続アクセスモード |
| `gitlab.toolbox.backups.cron.persistence.enabled`          | `false`                                                         | バックアップcronの永続フラグを有効にする |
| `gitlab.toolbox.backups.cron.persistence.matchExpressions` |                                                                 | バインドするラベル式の一致 |
| `gitlab.toolbox.backups.cron.persistence.matchLabels`      |                                                                 | バインドするラベル値の一致 |
| `gitlab.toolbox.backups.cron.persistence.size`             | `10Gi`                                                          | バックアップcronの永続ボリュームサイズ |
| `gitlab.toolbox.backups.cron.persistence.storageClass`     |                                                                 | プロビジョニング用のstorageClassName |
| `gitlab.toolbox.backups.cron.persistence.subPath`          |                                                                 | バックアップcronの永続ボリュームのmountパス |
| `gitlab.toolbox.backups.cron.persistence.volumeName`       |                                                                 | 既存の永続ボリューム名 |
| `gitlab.toolbox.backups.cron.resources.requests.cpu`       | `50m`                                                           | バックアップcronに必要な最小CPU |
| `gitlab.toolbox.backups.cron.resources.requests.memory`    | `350M`                                                          | バックアップcronに必要な最小メモリ |
| `gitlab.toolbox.backups.cron.schedule`                     | `0 1 * * *`                                                     | Cronスタイルのスケジュール文字列 |
| `gitlab.toolbox.backups.objectStorage.backend`             | `s3`                                                            | 使用するオブジェクトストレージプロバイダー（`s3`、`gcs`、または`azure`） |
| `gitlab.toolbox.backups.objectStorage.config.gcpProject`   | `""`                                                            | バックエンドが`gcs`の場合に使用するGCPプロジェクト |
| `gitlab.toolbox.backups.objectStorage.config.key`          | `""`                                                            | シークレット内の認証情報を含むキー |
| `gitlab.toolbox.backups.objectStorage.config.secret`       | `""`                                                            | オブジェクトストレージの認証情報シークレット |
| `gitlab.toolbox.backups.objectStorage.config`              | `{}`                                                            | オブジェクトストレージの認証情報 |
| `gitlab.toolbox.bootsnap.enabled`                          | `true`                                                          | ツールボックスでBootsnapキャッシュを有効にする |
| `gitlab.toolbox.enabled`                                   | `true`                                                          | ツールボックスの有効フラグ |
| `gitlab.toolbox.image.pullPolicy`                          | `IfNotPresent`                                                  | ツールボックスイメージのプルポリシー |
| `gitlab.toolbox.image.repository`                          | `registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee`    | ツールボックスイメージリポジトリ |
| `gitlab.toolbox.image.tag`                                 | `master`                                                        | ツールボックスイメージtag |
| `gitlab.toolbox.init.image.repository`                     |                                                                 | ツールボックス初期化イメージリポジトリ |
| `gitlab.toolbox.init.image.tag`                            |                                                                 | ツールボックス初期化イメージtag |
| `gitlab.toolbox.init.resources.requests.cpu`               | `50m`                                                           | ツールボックスの初期化に必要な最小CPU |
| `gitlab.toolbox.persistence.accessMode`                    | `ReadWriteOnce`                                                 | ツールボックスの永続アクセスモード |
| `gitlab.toolbox.persistence.enabled`                       | `false`                                                         | ツールボックスの永続フラグを有効にする |
| `gitlab.toolbox.persistence.matchExpressions`              |                                                                 | バインドするラベル式の一致 |
| `gitlab.toolbox.persistence.matchLabels`                   |                                                                 | バインドするラベル値の一致 |
| `gitlab.toolbox.persistence.size`                          | `10Gi`                                                          | ツールボックスの永続ボリュームサイズ |
| `gitlab.toolbox.persistence.storageClass`                  |                                                                 | プロビジョニング用のstorageClassName |
| `gitlab.toolbox.persistence.subPath`                       |                                                                 | ツールボックスの永続ボリュームのmountパス |
| `gitlab.toolbox.persistence.volumeName`                    |                                                                 | 既存の永続ボリューム名 |
| `gitlab.toolbox.psql.port`                                 |                                                                 | PostgreSQLサーバーポートを設定します。`global.psql.port`より優先されます |
| `gitlab.toolbox.resources.requests.cpu`                    | `50m`                                                           | ツールボックスに必要な最小CPU |
| `gitlab.toolbox.resources.requests.memory`                 | `350M`                                                          | ツールボックスに必要な最小メモリ |
| `gitlab.toolbox.securityContext.fsGroup`                   | `1000`                                                          | ポッドの起動に使用するグループID |
| `gitlab.toolbox.securityContext.runAsUser`                 | `1000`                                                          | ポッドの起動に使用するユーザーID |
| `gitlab.webservice.enabled`                                | `true`                                                          | webserviceの有効フラグ |
| `gitlab.webservice.gitaly.authToken.key`                   | `token`                                                         | Gitalyシークレット内のGitalyトークンへのキー |
| `gitlab.webservice.gitaly.authToken.secret`                | `{.Release.Name}-gitaly-secret`                                 | Gitalyシークレット名 |
| `gitlab.webservice.gitaly.serviceName`                     | `gitaly`                                                        | Gitalyサービス名 |
| `gitlab.webservice.image.pullPolicy`                       |                                                                 | webserviceイメージのプルポリシー |
| `gitlab.webservice.image.repository`                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-webservice-ee` | webserviceイメージリポジトリ |
| `gitlab.webservice.image.tag`                              | `master`                                                        | webserviceイメージtag |
| `gitlab.webservice.psql.password.key`                      | `psql-password`                                                 | psqlシークレット内のpsqlパスワードへのキー |
| `gitlab.webservice.psql.password.secret`                   | `gitlab-postgres`                                               | psqlシークレット名 |
| `gitlab.webservice.psql.port`                              |                                                                 | PostgreSQLサーバーポートを設定します。`global.psql.port`より優先されます |
| `global.registry.enabled`                                  | `true`                                                          | レジストリを有効にします。`registry.enabled`をミラーリングします |
| `global.registry.api.port`                                 | `5000`                                                          | レジストリポート |
| `global.registry.api.protocol`                             | `http`                                                          | レジストリプロトコル |
| `global.registry.api.serviceName`                          | `registry`                                                      | レジストリサービス名 |
| `global.registry.tokenIssuer`                              | `gitlab-issuer`                                                 | レジストリトークン発行者 |
| `gitlab.webservice.replicaCount`                           | `1`                                                             | webserviceレプリカ数 |
| `gitlab.webservice.resources.requests.cpu`                 | `200m`                                                          | webserviceの最小CPU |
| `gitlab.webservice.resources.requests.memory`              | `1.4G`                                                          | webserviceの最小メモリ |
| `gitlab.webservice.securityContext.fsGroup`                | `1000`                                                          | ポッドの起動に使用するグループID |
| `gitlab.webservice.securityContext.runAsUser`              | `1000`                                                          | ポッドの起動に使用するユーザーID |
| `gitlab.webservice.service.annotations`                    | `{}`                                                            | `Service`に追加する注釈 |
| `gitlab.webservice.http.enabled`                           | `true`                                                          | webservice HTTPを有効にする |
| `gitlab.webservice.service.externalPort`                   | `8080`                                                          | webservice公開ポート |
| `gitlab.webservice.service.internalPort`                   | `8080`                                                          | webservice内部ポート |
| `gitlab.webservice.tls.enabled`                            | `false`                                                         | webservice TLSを有効にする |
| `gitlab.webservice.tls.secretName`                         | `{Release.Name}-webservice-tls`                                 | TLSキーのwebserviceシークレット名 |
| `gitlab.webservice.service.tls.externalPort`               | `8081`                                                          | webservice TLS公開ポート |
| `gitlab.webservice.service.tls.internalPort`               | `8081`                                                          | webservice TLS内部ポート |
| `gitlab.webservice.service.type`                           | `ClusterIP`                                                     | webserviceサービスタイプ |
| `gitlab.webservice.service.workhorseExternalPort`          | `8181`                                                          | Workhorse公開ポート |
| `gitlab.webservice.service.workhorseInternalPort`          | `8181`                                                          | Workhorse内部ポート |
| `gitlab.webservice.shell.authToken.key`                    | `secret`                                                        | Shellシークレット内のShellトークンへのキー |
| `gitlab.webservice.shell.authToken.secret`                 | `{Release.Name}-gitlab-shell-secret`                            | Shellトークンシークレット |
| `gitlab.webservice.workerProcesses`                        | `2`                                                             | webserviceのworker数 |
| `gitlab.webservice.workerTimeout`                          | `60`                                                            | webservice workerのタイムアウト |
| `gitlab.webservice.workhorse.extraArgs`                    | `""`                                                            | workhorseの追加パラメータの文字列 |
| `gitlab.webservice.workhorse.image`                        | `registry.gitlab.com/gitlab-org/build/cng/gitlab-workhorse-ee`  | Workhorseイメージリポジトリ |
| `gitlab.webservice.workhorse.sentryDSN`                    | `""`                                                            | エラーレポート用のSentryインスタンスのDSN |
| `gitlab.webservice.workhorse.tag`                          |                                                                 | Workhorseイメージtag |

## 外部チャート {#external-charts}

GitLabは他のいくつかのチャートを利用します。これらは[親子関係](https://helm.sh/docs/topics/charts/#chart-dependencies)として扱われます。設定するプロパティは`chart-name.property`として指定してください。

### Prometheus {#prometheus}

Prometheusの値のプレフィックスは`prometheus`です。たとえば、`prometheus.server.persistentVolume.size`を使用して永続ストレージ値を設定します。Prometheusを無効にするには、`prometheus.install=false`を設定します。

設定オプションの詳しいリストについては、[Prometheusチャートのドキュメント](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus)を参照してください。

### PostgreSQL {#postgresql}

PostgreSQLの値のプレフィックスは`postgresql`です。たとえば、`postgresql.primary.persistence.storageClass`を使用して、プライマリのストレージクラスを設定します。

構成オプションの完全なリストについては、[Bitnami PostgreSQLチャートのドキュメント](https://artifacthub.io/packages/helm/bitnami/postgresql)を参照してください。

## 独自のイメージの持ち込み {#bringing-your-own-images}

特定のシナリオ（オフライン環境など）では、インターネットからプルするのではなく、独自のイメージを持ち込む必要がある場合があります。これには、GitLabリリースを構成する各チャートに対して、独自のDockerイメージ レジストリ/リポジトリを指定する必要があります。

詳細については、[カスタムイメージに関するドキュメント](../advanced/custom-images/_index.md)を参照してください。
