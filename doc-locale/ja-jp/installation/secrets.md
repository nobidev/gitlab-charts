---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabチャートのシークレットを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabが動作するには、さまざまなシークレットが必要です:

GitLabコンポーネント:

- レジストリ認証証明書
- GitLab Shell用のSSHホストキーと証明書
- 個々のGitLabサービス用パスワード
- GitLab Pages用TLS証明書

オプションの外部サービス:

- SMTPサーバー
- LDAP
- OmniAuth
- 受信メール用IMAP (mail_roomサービス経由)
- サービスデスクメール用IMAP (mail_roomサービス経由)
- 受信メール用Microsoft Graph with OAuth2 (mail_roomサービス経由)
- サービスデスクメール用Microsoft Graph with OAuth2 (mail_roomサービス経由)
- 送信メール用Microsoft Graph with OAuth2
- S/MIME証明書
- スマートカード認証
- OAuthインテグレーション

手動で提供されなかったシークレットは、ランダムな値で自動的に生成されます。HTTPS証明書の自動生成はLet's Encryptによって提供されます。

自動生成されたシークレットを利用するには、[次のステップ](#next-steps)に進んでください。

独自のシークレットを指定するには、[手動シークレット作成](#manual-secret-creation-optional)に進んでください。

## 手動シークレット作成 (オプション) {#manual-secret-creation-optional}

このドキュメントの以前のステップに従った場合は、`gitlab`をリリース名として使用してください。

- [TLS証明書](tls.md)
- [レジストリ認証証明書](#registry-authentication-certificates)
- [レジストリの機密通知ヘッダー](#registry-sensitive-notification-headers)
- [SSHホストキー](#ssh-host-keys)
- パスワード:
  - [初期rootパスワード](#initial-root-password)
  - [Redisパスワード](#redis-password)
  - [GitLab Shellシークレット](#gitlab-shell-secret)
  - [Gitalyシークレット](#gitaly-secret)
  - [Praefectシークレット](#praefect-secret)
  - [GitLab Railsシークレット](#gitlab-rails-secret)
  - [GitLab Workhorseシークレット](#gitlab-workhorse-secret)
  - [GitLab Runnerシークレット](#gitlab-runner-secret)
  - [PostgreSQLパスワード](#postgresql-password)
  - [Praefect DBパスワード](#praefect-db-password)
  - [MinIOシークレット](#minio-secret)
  - [レジストリHTTPシークレット](#registry-http-secret)
  - [レジストリ通知シークレット](#registry-notification-secret)
  - [GitLab Pagesシークレット](#gitlab-pages-secret)
  - [GitLab受信メール認証トークン](#gitlab-incoming-email-auth-token)
  - [GitLabサービスデスクメール認証トークン](#gitlab-service-desk-email-auth-token)
  - [Zoektインデクサー内部APIシークレット](#zoekt-indexer-internal-api-secret)
- [外部サービス](#external-services)
  - [OmniAuth](#omniauth)
  - [LDAPパスワード](#ldap-password)
  - [SMTPパスワード](#smtp-password)
  - [受信メール用IMAPパスワード](#imap-password-for-incoming-emails)
  - [サービスデスクメール用IMAPパスワード](#imap-password-for-service-desk-emails)
  - [受信メール用Microsoft Graphクライアントシークレット](#microsoft-graph-client-secret-for-incoming-emails)
  - [サービスデスク用Microsoft Graphクライアントシークレット](#microsoft-graph-client-secret-for-service-desk-emails)
  - [送信メール用Microsoft Graphクライアントシークレット](#microsoft-graph-client-secret-for-outgoing-emails)
  - [S/MIME証明書](#smime-certificate)
  - [スマートカード認証](#smartcard-authentication)

### レジストリ認証証明書 {#registry-authentication-certificates}

GitLabとレジストリ間の通信はIngressを介して行われるため、ほとんどの場合、この通信には自己署名証明書で十分です。このトラフィックがネットワーク経由で公開される場合は、公開されている有効な証明書を生成する必要があります。

以下の例では、自己署名証明書が必要であると仮定しています。

証明書とキーペアを生成します:

```shell
mkdir -p certs
openssl req -new -newkey rsa:4096 -subj "/CN=gitlab-issuer" -nodes -x509 -keyout certs/registry-example-com.key -out certs/registry-example-com.crt
```

これらの証明書を含むシークレットを作成します。`<name>-registry-secret`シークレット内に`registry-auth.key`と`registry-auth.crt`のキーを作成します。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-registry-secret --from-file=registry-auth.key=certs/registry-example-com.key --from-file=registry-auth.crt=certs/registry-example-com.crt
```

このシークレットは`global.registry.certificate.secret`設定で参照されます。

### レジストリの機密通知ヘッダー {#registry-sensitive-notification-headers}

詳細については、[レジストリ通知の設定に関するドキュメント](../charts/globals.md#configure-registry-settings)を確認してください。

シークレットの内容は、単一の項目であっても項目リストである必要があります。内容が単なる文字列の場合、チャートは必要に応じてリストに変換**WILL NOT**。

値`RandomFooBar`を持つ`registry-authorization-header`シークレットが作成される例を考えてみましょう。

```shell
kubectl create secret generic registry-authorization-header --from-literal=value="[RandomFooBar]"
```

デフォルトでは、シークレット内で使用されるキーは「value」です。ただし、ユーザーは別のキーを使用できますが、ヘッダーマップ項目として`key`の下に指定されていることを確認する必要があります。

### SSHホストキー {#ssh-host-keys}

OpenSSH証明書キーペアを生成します:

```shell
mkdir -p hostKeys
ssh-keygen -t rsa  -f hostKeys/ssh_host_rsa_key -N ""
ssh-keygen -t ecdsa  -f hostKeys/ssh_host_ecdsa_key -N ""
ssh-keygen -t ed25519  -f hostKeys/ssh_host_ed25519_key -N ""
```

これらの証明書を含むシークレットを作成します。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-gitlab-shell-host-keys --from-file hostKeys
```

このシークレットは`global.shell.hostKeys.secret`設定で参照されます。

このシークレットがローテーションされると、すべてのSSHクライアントに`hostname mismatch`エラーが表示されます。

### 初期Enterpriseライセンス {#initial-enterprise-license}

> [!warning]
> この方法は、インストール時にのみライセンスを追加します。ライセンスを更新またはアップグレードするには、ウェブユーザーインターフェースの管理者エリアを使用してください。

GitLabインスタンスのEnterpriseライセンスを保存するためのKubernetesシークレットを作成します。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-gitlab-license --from-file=license=/tmp/license.gitlab
```

次に、`--set global.gitlab.license.secret=<name>-gitlab-license`を使用して、ライセンスを設定に注入します。

`global.gitlab.license.key`オプションを使用して、ライセンスシークレット内のライセンスを指すデフォルトの`license`キーを変更することもできます。

### 初期rootパスワード {#initial-root-password}

初期rootパスワードを保存するためのKubernetesシークレットを作成します。パスワードは6文字以上である必要があります。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-gitlab-initial-root-password --from-literal=password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)
```

### Redisパスワード {#redis-password}

Redis用のランダムな64文字の英数字パスワードを生成します。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-redis-secret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

既存のRedisクラスターでデプロイする場合は、ランダムに生成されたパスワードではなく、base64エンコードされたRedisクラスターにアクセスするためのパスワードを使用してください。

このシークレットは`global.redis.auth.secret`設定で参照されます。

### GitLab Shellシークレット {#gitlab-shell-secret}

GitLab Shell用のランダムな64文字の英数字シークレットを生成します。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-gitlab-shell-secret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは`global.shell.authToken.secret`設定で参照されます。

### Gitalyシークレット {#gitaly-secret}

Gitaly用のランダムな64文字の英数字トークンを生成します。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-gitaly-secret --from-literal=token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは`global.gitaly.authToken.secret`設定で参照されます。

### Praefectシークレット {#praefect-secret}

Praefect用のランダムな64文字の英数字トークンを生成します。`<name>`をリリース名に置き換えてください:

```shell
kubectl create secret generic <name>-praefect-secret --from-literal=token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは`global.praefect.authToken.secret`設定で参照されます。

### GitLab Railsシークレット {#gitlab-rails-secret}

{{< history >}}

- `active_record_encryption_*`キーは[GitLab 17.8](../releases/8_0.md#upgrade-to-880)で追加されました。

{{< /history >}}

`<name>`をリリース名に置き換えてください。

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

このシークレットは`global.railsSecrets.secret`設定で参照されます。

このシークレットにはデータベース暗号化キーが含まれているため、ローテーションすることはお勧めしません。シークレットがローテーションされた場合、その結果は[シークレットファイルが失われた場合](https://docs.gitlab.com/administration/backup_restore/troubleshooting_backup_gitlab/#when-the-secrets-file-is-lost)と同じ動作を示します。

### GitLab Workhorseシークレット {#gitlab-workhorse-secret}

Workhorseシークレットを生成します。これは32文字の長さで、base64エンコードされている必要があります。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-gitlab-workhorse-secret --from-literal=shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは`global.workhorse.secret`設定で参照されます。

### GitLab Runnerシークレット {#gitlab-runner-secret}

`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-gitlab-runner-secret --from-literal=runner-registration-token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは`gitlab-runner.runners.secret`設定で参照されます。

### GitLabKASシークレット {#gitlab-kas-secret}

GitLab Railsでは、KASサブチャートをインストールせずにこのチャートをデプロイする場合でも、KAS用のシークレットが必要です。ただし、以下の手順に従ってこのシークレットを手動で作成することも、チャートにシークレットを自動生成させることもできます。

`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-gitlab-kas-secret --from-literal=kas_shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは`global.appConfig.gitlab_kas.secret`設定で参照されます。

### GitLabKASAPIシークレット {#gitlab-kas-api-secret}

チャートにシークレットを自動生成させることも、手動でこのシークレットを作成することもできます (`<name>`をリリース名に置き換えてください):

```shell
kubectl create secret generic <name>-kas-private-api --from-literal=kas_private_api_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは`gitlab.kas.privateApi.secret`設定で参照されます。

### GitLabKAS WebSocketトークンシークレット {#gitlab-kas-websocket-token-secret}

チャートにシークレットを自動生成させることも、手動でこのシークレットを作成することもできます (`<name>`をリリース名に置き換えてください):

```shell
kubectl create secret generic <name>-kas-websocket-token --from-literal=kas_websocket_token_secret=$(head -c 72 /dev/urandom | base64 -w0)
```

このシークレットは`gitlab.kas.websocketToken.secret`設定で参照されます。

### MinIOシークレット {#minio-secret}

MinIO用のランダムな20および64文字の英数字キーのセットを生成します。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-minio-secret --from-literal=accesskey=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 20) --from-literal=secretkey=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは`global.minio.credentials.secret`設定で参照されます。

### PostgreSQLパスワード {#postgresql-password}

ランダムな64文字の英数字パスワードを生成します。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-postgresql-password \
    --from-literal=postgresql-password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64) \
    --from-literal=postgresql-postgres-password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは`global.psql.password.secret`設定で参照されます。

#### バンドルされているPostgreSQLサブチャートのPostgreSQLパスワードの変更 {#changing-the-postgresql-password-for-the-bundled-postgresql-subchart}

> [!note]
> バンドルされているPostgreSQLサブチャートは、評価目的でのみ提供されます。本番環境では、[外部PostgreSQLインスタンス](../advanced/external-db/_index.md)を使用してください。

バンドルされているPostgreSQLサブチャートは、データベースが最初に作成されるときにのみ、シークレットからのパスワードでデータベースを設定します。既存のデータベースのパスワードを変更するには、追加の手順を実行する必要があります。

変更中はユーザーに影響が出る可能性があることに注意してください。

PostgreSQLシークレットをローテーションするには:

1. PostgreSQLシークレットの一般的な[シークレットのローテーション](#rotating-secrets)手順を完了してください。
1. PostgreSQLポッドにexecして、データベース内のパスワードを更新します:

   ```shell
   # Exec into the PostgreSQL pod
   kubectl exec -it <name>-postgresql-0 -- sh

   # Inside the pod, update the passwords in the database
   sed -i 's/^\(local .*\)md5$/\1trust/' /opt/bitnami/postgresql/conf/pg_hba.conf
   pg_ctl reload ; sleep 1
   echo "ALTER USER postgres WITH PASSWORD '$(echo $POSTGRES_POSTGRES_PASSWORD)' ; ALTER USER gitlab WITH PASSWORD '$(echo $POSTGRES_PASSWORD)' ; ALTER USER registry WITH PASSWORD '$(echo $REGISTRY_POSTGRES_PASSWORD)'" | psql -U postgres -d gitlabhq_production -f -
   sed -i 's/^\(local .*\)trust$/\1md5/' /opt/bitnami/postgresql/conf/pg_hba.conf
   pg_ctl reload
   ```

   **注**: レジストリユーザーのパスワード更新は、[レジストリメタデータデータベース](../charts/registry/metadata_database.md)機能が有効になっている場合にのみ必要です。レジストリユーザーが存在しない場合、`ALTER USER registry`コマンドはエラーを生成しますが、他のパスワード更新には影響しません。

1. `gitlab-exporter`、`postgresql`、`toolbox`、`sidekiq`、`webservice`、および`registry`のポッドを`kubectl delete pod`コマンドを使用して削除し、新しいポッドに新しいシークレットを読み込むことで、データベースに接続できるようにします。

### GitLab Pagesシークレット {#gitlab-pages-secret}

GitLab Pagesシークレットを生成します。これは32文字の長さで、base64エンコードされている必要があります。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-gitlab-pages-secret --from-literal=shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは`global.pages.apiSecret.secret`設定で参照されます。

### レジストリHTTPシークレット {#registry-http-secret}

すべてのレジストリポッドで共有されるランダムな64文字の英数字キーを生成します。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-registry-httpsecret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64 | base64)
```

このシークレットは`global.registry.httpSecret.secret`設定で参照されます。

### レジストリ通知シークレット {#registry-notification-secret}

すべてのレジストリポッドとGitLabウェブサービスポッドで共有されるランダムな32文字の英数字キーを生成します。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-registry-notification --from-literal=secret=[\"$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)\"]
```

このシークレットは`global.registry.notificationSecret.secret`設定で参照されます。

### Praefect DBパスワード {#praefect-db-password}

ランダムな64文字の英数字パスワードを生成します。`<name>`をリリース名に置き換えてください:

```shell
kubectl create secret generic <name>-praefect-dbsecret \
    --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64) \
```

このシークレットは`global.praefect.dbSecret`設定で参照されます。

## 外部サービス {#external-services}

一部のチャートには、自動的に生成できない機能を有効にするためのさらなるシークレットがあります。

### OmniAuth {#omniauth}

デプロイされたGitLabで[OmniAuthプロバイダー](https://docs.gitlab.com/integration/omniauth/)の使用を有効にするには、[Globalsチャート内の指示](../charts/globals.md#omniauth)に従ってください。

### LDAPパスワード {#ldap-password}

LDAPサーバーに接続するためにパスワード認証が必要な場合は、パスワードをKubernetesシークレットに保存する必要があります。

```shell
kubectl create secret generic ldap-main-password --from-literal=password=yourpasswordhere
```

次に、`--set global.appConfig.ldap.servers.main.password.secret=ldap-main-password`を使用してパスワードを設定に注入します。

> [!note]
> Helmプロパティを設定する際は、_実際のパスワード_ではなく`Secret`名を使用してください。

### SMTPパスワード {#smtp-password}

認証が必要なSMTPサーバーを使用している場合は、パスワードをKubernetesシークレットに保存します。

```shell
kubectl create secret generic smtp-password --from-literal=password=yourpasswordhere
```

次に、`--set global.smtp.password.secret=smtp-password`をHelmコマンドで使用します。

> [!note]
> Helmプロパティを設定する際は、_実際のパスワード_ではなく`Secret`名を使用してください。

### 受信メール用IMAPパスワード {#imap-password-for-incoming-emails}

GitLabは、受信メールにアクセスするために、アプリパスワード、トークン、IMAPパスワードなどの認証文字列を使用します。

GitLab受信メールドキュメントで[メールプロバイダーを見つけて](https://docs.gitlab.com/administration/incoming_email/)、必要な認証文字列をKubernetesシークレットとして設定します。

```shell
kubectl create secret generic incoming-email-password --from-literal="password=auth_string_for_your_provider_here"
```

次に、`--set global.appConfig.incomingEmail.password.secret=incoming-email-password`をHelmコマンドで、[ドキュメント](command-line-options.md#incoming-email-configuration)で指定されている他の必要な設定とともに使用します。

> [!note]
> Helmプロパティを設定する際は、_実際のパスワード_ではなく`Secret`名を使用してください。

### サービスデスクメール用IMAPパスワード {#imap-password-for-service-desk-emails}

GitLabは、[サービスデスクメール](https://docs.gitlab.com/user/project/service_desk/configure/#custom-email-address)にアクセスするために、アプリパスワード、トークン、IMAPパスワードなどの認証文字列を使用します。

GitLab受信メールドキュメントで[メールプロバイダーを見つけて](https://docs.gitlab.com/administration/incoming_email/)、必要な認証文字列をKubernetesシークレットとして設定します。

```shell
kubectl create secret generic service-desk-email-password --from-literal="password=auth_string_for_your_provider_here"
```

次に、`--set global.appConfig.serviceDeskEmail.password.secret=service-desk-email-password`をHelmコマンドで、[ドキュメント](command-line-options.md#service-desk-email-configuration)で指定されている他の必要な設定とともに使用します。

> [!note]
> Helmプロパティを設定する際は、_実際のパスワード_ではなく`Secret`名を使用してください。

### GitLab受信メール認証トークン {#gitlab-incoming-email-auth-token}

受信メールがWebhook配信方法を使用するように設定されている場合、mail_roomサービスとウェブサービス間で共有シークレットが必要です。これは32文字の長さで、base64エンコードされている必要があります。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-incoming-email-auth-token --from-literal=authToken=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは`global.incomingEmail.authToken`設定で参照されます。

### GitLabサービスデスクメール認証トークン {#gitlab-service-desk-email-auth-token}

サービスデスクメールがWebhook配信方法を使用するように設定されている場合、mail_roomサービスとウェブサービス間で共有シークレットが必要です。これは32文字の長さで、base64エンコードされている必要があります。`<name>`をリリース名に置き換えてください。

```shell
kubectl create secret generic <name>-service-desk-email-auth-token --from-literal=authToken=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは`global.serviceDeskEmail.authToken`設定で参照されます。

### Zoektインデクサー内部APIシークレット {#zoekt-indexer-internal-api-secret}

[GitLab-Zoektサブチャート](../charts/gitlab/gitlab-zoekt/_index.md)がインストールされている場合、ZoektインデクサーはJWTを使用してGitLab内部APIに認証するします。デフォルトでは、このシークレットは自動生成された[GitLab Shellシークレット](#gitlab-shell-secret)を再利用します。

Zoekt用に別のシークレットを使用したい場合は、手動で作成できます (`<name>`をリリース名に置き換えてください):

```shell
kubectl create secret generic <name>-zoekt-internal-api --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

次に、チャートを設定して使用します:

```shell
--set global.zoekt.indexer.internalApi.secretName=<name>-zoekt-internal-api \
--set global.zoekt.indexer.internalApi.secretKey=secret
```

指定されていない場合、`global.zoekt.indexer.internalApi.secretName`はGitLab Shell認証トークンシークレット (`global.shell.authToken.secret`) にデフォルト設定されます。

### 受信メール用Microsoft Graphクライアントシークレット {#microsoft-graph-client-secret-for-incoming-emails}

GitLabが[受信メール](https://docs.gitlab.com/administration/incoming_email/)にアクセスできるように、IMAPアカウントのパスワードをKubernetesシークレットに保存します:

```shell
kubectl create secret generic incoming-email-client-secret --from-literal=secret=your-secret-here
```

次に、`--set global.appConfig.incomingEmail.clientSecret.secret=incoming-email-client-secret`をHelmコマンドで、[ドキュメント](command-line-options.md#incoming-email-configuration)で指定されている他の必要な設定とともに使用します。

> [!note]
> Helmプロパティを設定する際は、_実際のパスワード_ではなく`Secret`名を使用してください。

### サービスデスクメール用Microsoft Graphクライアントシークレット {#microsoft-graph-client-secret-for-service-desk-emails}

GitLabが[サービスデスクメール](https://docs.gitlab.com/user/project/service_desk/configure/#custom-email-address)にアクセスできるように、IMAPアカウントのパスワードをKubernetesシークレットに保存します:

```shell
kubectl create secret generic service-desk-email-client-secret --from-literal=secret=your-secret-here
```

次に、`--set global.appConfig.serviceDeskEmail.clientSecret.secret=service-desk-email-client-secret`をHelmコマンドで、[ドキュメント](command-line-options.md#service-desk-email-configuration)で指定されている他の必要な設定とともに使用します。

> [!note]
> Helmプロパティを設定する際は、_実際のパスワード_ではなく`Secret`名を使用してください。

### 送信メール用Microsoft Graphクライアントシークレット {#microsoft-graph-client-secret-for-outgoing-emails}

パスワードをKubernetesシークレットに保存します:

```shell
kubectl create secret generic microsoft-graph-mailer-client-secret --from-literal=secret=your-secret-here
```

次に、`--set global.appConfig.microsoft_graph_mailer.client_secret.secret=microsoft-graph-mailer-client-secret`をHelmコマンドで使用します。

> [!note]
> Helmプロパティを設定する際は、_実際のパスワード_ではなく`Secret`名を使用してください。

### S/MIME証明書 {#smime-certificate}

送信メールメッセージは、[S/MIME](https://en.wikipedia.org/wiki/S/MIME)標準を使用してデジタル署名できます。S/MIME証明書は、TLSタイプのKubernetesシークレットとして保存する必要があります。

```shell
kubectl create secret tls smime-certificate --key=file.key --cert file.crt
```

不透明なタイプとして既存のシークレットがある場合は、特定のシークレットに合わせて`global.email.smime.keyName`と`global.email.smime.certName`の値を調整する必要があります。

S/MIME設定は、`values.yaml`ファイルまたはコマンドラインで設定できます。S/MIMEを有効にするには`--set global.email.smime.enabled=true`を使用し、S/MIME証明書を含むシークレットを指定するには`--set global.email.smime.secretName=smime-certificate`を使用します。

### スマートカード認証 {#smartcard-authentication}

[スマートカード認証](https://docs.gitlab.com/administration/auth/smartcard/)は、カスタム認証局 (CA) を使用してクライアント証明書に署名します。このカスタムCAの証明書は、クライアント証明書が有効かどうかを検証するために、ウェブサービスポッドに注入する必要があります。これはK8sシークレットとして提供されます。

```shell
kubectl create secret generic <secret name> --from-file=ca.crt=<path to CA certificate>
```

証明書が保存されているシークレット内のキー名は`ca.crt`でなければなりません。

### OAuthインテグレーション {#oauth-integration}

GitLab PagesのようなさまざまなサービスのOAuthインテグレーションを設定するには、OAuth認証情報を含むシークレットが必要です。シークレットには、App ID (通常、`appid`キーの下にデフォルトで保存されます) とApp Secret (通常、`appsecret`キーの下にデフォルトで保存されます) を含める必要があります。これらは両方とも、少なくとも64文字の英数字文字列であることが推奨されます。

```shell
kubectl create secret generic oauth-gitlab-pages-secret --from-literal=appid=<app id> --from-literal=appsecret=<app secret>
```

このシークレットは、`global.oauth.<service name>.secret`設定を使用して指定できます。`appid`と`appsecret`以外のキーが使用されている場合は、`global.oauth.<service name>.appIdKey`と`global.oauth.<service name>.appSecretKey`設定を使用して指定できます。

## 次の手順 {#next-steps}

すべてのシークレットが生成され保存されたら、[GitLabをデプロイ](deployment.md)できます。

## シークレットのローテーション {#rotating-secrets}

シークレットは、セキュリティ上の目的で必要な場合にローテーションできます。

1. 現在の[シークレットをバックアップ](../backup-restore/backup.md#back-up-the-secrets)します。
1. 便宜上、ローテーションしたい各シークレットの手動[シークレット作成](#manual-secret-creation-optional)手順に従って、`-v2` (例: `gitlab-shell-host-keys-v2`) がサフィックスとして付加された新しいシークレットを作成してください。
1. `values.yaml`ファイル内のシークレットキーを更新して、新しいシークレット名を指すようにします。ほとんどのシークレット名は、[手動シークレット作成](#manual-secret-creation-optional)セクションの各シークレットの下にドキュメント化されています。
1. 更新された`values.yaml`ファイルでGitLabチャートリリースをアップグレードします。
1. PostgreSQLシークレットをローテーションする場合は、[ローテーションを完了するための追加手順](#changing-the-postgresql-password-for-the-bundled-postgresql-subchart)があります。
1. GitLabが期待どおりに動作していることを確認します。そうなった場合、古いシークレットを削除しても安全です。
