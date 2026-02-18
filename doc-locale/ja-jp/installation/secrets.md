---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのシークレットを設定する
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLabを運用するには、さまざまなシークレットが必要です:

GitLabコンポーネント:

- レジストリ認証認証局証明書
- GitLab ShellのSSHホストキーと証明書
- 個々のGitLabサービス用パスワード
- GitLab PagesのTLS証明書

オプションの外部サービス:

- SMTPサーバー
- LDAP
- OmniAuth
- 受信メール用IMAP（mail_roomサービス経由）
- サービスデスクのメール用IMAP（mail_roomサービス経由）
- 受信メール用OAuth2を使用したMicrosoft Graph（mail_roomサービス経由）
- サービスデスクのメール用OAuth2を使用したMicrosoft Graph（mail_roomサービス経由）
- 送信メール用OAuth2を使用したMicrosoft Graph
- S/MIME証明書
- スマートカード認証
- OAuthインテグレーション

手動で指定されていないシークレットは、すべてランダムな値で自動的に生成されます。HTTPS証明書の自動生成は、Let's Encryptによって提供されます。

自動生成されたシークレットを利用するには、[次のステップ](#next-steps)に進みます。

独自のシークレットを指定するには、[手動でのシークレット作成](#manual-secret-creation-optional)に進みます。

## 手動でのシークレット作成（オプション） {#manual-secret-creation-optional}

このドキュメントの前の手順に従った場合は、`gitlab`をリリース名として使用します。

- [TLS証明書](tls.md)
- [レジストリ認証認証局証明書](#registry-authentication-certificates)
- [レジストリ機密通知ヘッダー](#registry-sensitive-notification-headers)
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
  - [Zoekt基本認証パスワード](#zoekt-basic-auth-password)
- [外部サービス](#external-services)
  - [OmniAuth](#omniauth)
  - [LDAPパスワード](#ldap-password)
  - [SMTPパスワード](#smtp-password)
  - [受信メールのIMAPパスワード](#imap-password-for-incoming-emails)
  - [サービスデスクのIMAPパスワード](#imap-password-for-service-desk-emails)
  - [受信メールのMicrosoft Graphクライアントのシークレットキー](#microsoft-graph-client-secret-for-incoming-emails)
  - [サービスデスクのMicrosoft Graphクライアントのシークレットキー](#microsoft-graph-client-secret-for-service-desk-emails)
  - [送信メールのMicrosoft Graphクライアントのシークレットキー](#microsoft-graph-client-secret-for-outgoing-emails)
  - [S/MIME証明書](#smime-certificate)
  - [スマートカード認証](#smartcard-authentication)

### レジストリ認証認証局証明書 {#registry-authentication-certificates}

GitLabとレジストリ間の通信はIngressの背後で行われるため、ほとんどの場合、この通信に自己署名証明書を使用するだけで十分です。このトラフィックがネットワーク経由で公開されている場合は、公開されている有効な証明書を生成する必要があります。

以下の例では、自己署名証明書が必要であることを前提としています。

認証局 - キーペアを生成します:

```shell
mkdir -p certs
openssl req -new -newkey rsa:4096 -subj "/CN=gitlab-issuer" -nodes -x509 -keyout certs/registry-example-com.key -out certs/registry-example-com.crt
```

これらの証明書を含むシークレットを作成します。`registry-auth.key`および`registry-auth.crt`キーを`<name>-registry-secret`シークレット内に作成します。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-registry-secret --from-file=registry-auth.key=certs/registry-example-com.key --from-file=registry-auth.crt=certs/registry-example-com.crt
```

このシークレットは、`global.registry.certificate.secret`設定によって参照されます。

### レジストリ機密通知ヘッダー {#registry-sensitive-notification-headers}

詳細については、[レジストリ通知の構成に関するドキュメント](../charts/globals.md#configure-registry-settings)を確認してください。

シークレットの内容は、項目が1つだけの場合でも、項目のリストである必要があります。コンテンツが単なる文字列である場合、チャートは必要に応じてリストに変換**しません**。

値`RandomFooBar`を持つ`registry-authorization-header`シークレットが作成される例を考えてみましょう。

```shell
kubectl create secret generic registry-authorization-header --from-literal=value="[RandomFooBar]"
```

デフォルトでは、シークレット内で使用されるキーは「value」です。ただし、ユーザーは別のキーを使用できますが、ヘッダーマップ項目で`key`として指定されていることを確認する必要があります。

### SSHホストキー {#ssh-host-keys}

OpenSSH認証局-キーペアを生成します:

```shell
mkdir -p hostKeys
ssh-keygen -t rsa  -f hostKeys/ssh_host_rsa_key -N ""
ssh-keygen -t ecdsa  -f hostKeys/ssh_host_ecdsa_key -N ""
ssh-keygen -t ed25519  -f hostKeys/ssh_host_ed25519_key -N ""
```

これらの証明書を含むシークレットを作成します。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-shell-host-keys --from-file hostKeys
```

このシークレットは、`global.shell.hostKeys.secret`設定によって参照されます。

このシークレットがローテーションされると、すべてのSSHクライアントに`hostname mismatch`エラーが表示されます。

### 初期エンタープライズライセンス {#initial-enterprise-license}

{{< alert type="warning" >}}

この方法は、インストール時にのみライセンスを追加します。Webインターフェースの管理者エリアを使用して、ライセンスを更新またはアップグレードします。

{{< /alert >}}

GitLabインスタンスのエンタープライズライセンスを格納するためのKubernetesシークレットを作成します。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-license --from-file=license=/tmp/license.gitlab
```

次に、`--set global.gitlab.license.secret=<name>-gitlab-license`を使用して、ライセンスを設定に挿入します。

`global.gitlab.license.key`オプションを使用して、ライセンスシークレット内のライセンスを指すデフォルトの`license`キーを変更することもできます。

### 初期rootパスワード {#initial-root-password}

初期rootパスワードを格納するためのKubernetesシークレットを作成します。パスワードは6文字以上にする必要があります。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-initial-root-password --from-literal=password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)
```

### Redisパスワード {#redis-password}

Redisのランダムな64文字の英数字パスワードを生成します。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-redis-secret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

既存のRedisクラスタリングを使用してデプロイする場合は、ランダムに生成されたものではなく、base64でエンコードされたRedisクラスタリングにアクセスするためのパスワードを使用してください。

このシークレットは、`global.redis.auth.secret`設定によって参照されます。

### GitLab Shellシークレット {#gitlab-shell-secret}

GitLab Shellのランダムな64文字の英数字シークレットを生成します。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-shell-secret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは、`global.shell.authToken.secret`設定によって参照されます。

### Gitalyシークレット {#gitaly-secret}

Gitalyのランダムな64文字の英数字トークンを生成します。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-gitaly-secret --from-literal=token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは、`global.gitaly.authToken.secret`設定によって参照されます。

### Praefectシークレット {#praefect-secret}

Praefectのランダムな64文字の英数字トークンを生成します。`<name>`をリリースの名前に置き換えます:

```shell
kubectl create secret generic <name>-praefect-secret --from-literal=token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは、`global.praefect.authToken.secret`設定によって参照されます。

### GitLab Railsシークレット {#gitlab-rails-secret}

{{< history >}}

- `active_record_encryption_*`キーは、[GitLab 17.8](../releases/8_0.md#upgrade-to-880)で追加されました。

{{< /history >}}

`<name>`をリリースの名前に置き換えます。

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

このシークレットは、`global.railsSecrets.secret`設定によって参照されます。

データベース暗号化キーが含まれているため、このシークレットをローテーションすることは**推奨されません**。シークレットがローテーションされると、[シークレットファイルが失われた場合](https://docs.gitlab.com/administration/backup_restore/troubleshooting_backup_gitlab/#when-the-secrets-file-is-lost)と同じ動作が示されます。

### GitLab Workhorseシークレット {#gitlab-workhorse-secret}

workhorseシークレットを生成します。これは、長さが32文字で、base64でエンコードされている必要があります。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-workhorse-secret --from-literal=shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`global.workhorse.secret`設定によって参照されます。

### GitLab Runnerシークレット {#gitlab-runner-secret}

`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-runner-secret --from-literal=runner-registration-token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは、`gitlab-runner.runners.secret`設定によって参照されます。

### GitLab KASシークレット {#gitlab-kas-secret}

このチャートをKASサブチャートをインストールせずにデプロイする場合でも、GitLab RailsにはKASのシークレットが存在する必要があります。それでも、以下の手順に従ってこのシークレットを手動で作成するか、チャートにシークレットを自動生成させることができます。

`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-kas-secret --from-literal=kas_shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`global.appConfig.gitlab_kas.secret`設定によって参照されます。

### GitLab KAS APIシークレット {#gitlab-kas-api-secret}

チャートにシークレットを自動生成させるか、このシークレットを手動で作成できます（`<name>`をリリースの名前に置き換えます）:

```shell
kubectl create secret generic <name>-kas-private-api --from-literal=kas_private_api_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`gitlab.kas.privateApi.secret`設定によって参照されます。

### GitLab KAS WebSocketトークンシークレット {#gitlab-kas-websocket-token-secret}

チャートにシークレットを自動生成させるか、このシークレットを手動で作成できます（`<name>`をリリースの名前に置き換えます）:

```shell
kubectl create secret generic <name>-kas-websocket-token --from-literal=kas_websocket_token_secret=$(head -c 72 /dev/urandom | base64 -w0)
```

このシークレットは、`gitlab.kas.websocketToken.secret`設定によって参照されます。

### MinIOシークレット {#minio-secret}

MinIOのランダムな20文字と64文字の英数字キーのセットを生成します。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-minio-secret --from-literal=accesskey=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 20) --from-literal=secretkey=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは、`global.minio.credentials.secret`設定によって参照されます。

### PostgreSQLパスワード {#postgresql-password}

ランダムな64文字の英数字パスワードを生成します。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-postgresql-password \
    --from-literal=postgresql-password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64) \
    --from-literal=postgresql-postgres-password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは、`global.psql.password.secret`設定によって参照されます。

#### バンドルされたPostgreSQLサブチャートのPostgreSQLパスワードの変更 {#changing-the-postgresql-password-for-the-bundled-postgresql-subchart}

{{< alert type="warning" >}}

デフォルトのHelm Chart設定は**本番環境を対象としたものではありません**。これには、バンドルされたPostgreSQLサブチャートも含まれます。

{{< /alert >}}

バンドルされたPostgreSQLサブチャートは、データベースが最初に作成されたときに、シークレットからのパスワードを使用してデータベースを構成するだけです。既存のデータベースでパスワードを変更するには、追加の手順を実行する必要があります。

この操作を行うと、変更が行われている間、ユーザーは中断されることに注意してください。

PostgreSQLシークレットをローテーションするには:

1. PostgreSQLシークレットの一般的な[シークレットのローテーション](#rotating-secrets)手順を完了します。
1. PostgreSQLポッドにExecして、データベース内のパスワードを更新します:

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

   **メモ**: レジストリユーザーのパスワードの更新は、[レジストリメタデータデータベース](../charts/registry/metadata_database.md)機能が有効になっている場合にのみ必要です。レジストリユーザーが存在しない場合、`ALTER USER registry`コマンドはエラーを生成しますが、他のパスワードの更新には影響しません。

1. 新しいポッドに新しいシークレットが読み込まれ、データベースに接続できるように、`gitlab-exporter`、`postgresql`、`toolbox`、`sidekiq`、`webservice`、`registry`のポッドを`kubectl delete pod`コマンドを使用して削除します。

### GitLab Pagesシークレット {#gitlab-pages-secret}

GitLab Pagesシークレットを生成します。これは、長さが32文字で、base64でエンコードされている必要があります。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-pages-secret --from-literal=shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`global.pages.apiSecret.secret`設定によって参照されます。

### レジストリHTTPシークレット {#registry-http-secret}

すべてのレジストリポッドで共有される、ランダムな64文字の英数字キーを生成します。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-registry-httpsecret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64 | base64)
```

このシークレットは、`global.registry.httpSecret.secret`設定によって参照されます。

### レジストリ通知シークレット {#registry-notification-secret}

すべてのレジストリポッドと、GitLab Webサービスのポッドで共有される、ランダムな32文字の英数字キーを生成します。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-registry-notification --from-literal=secret=[\"$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)\"]
```

このシークレットは、`global.registry.notificationSecret.secret`設定によって参照されます。

### Praefect DBパスワード {#praefect-db-password}

ランダムな64文字の英数字パスワードを生成します。`<name>`をリリースの名前に置き換えます:

```shell
kubectl create secret generic <name>-praefect-dbsecret \
    --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64) \
```

このシークレットは、`global.praefect.dbSecret`設定によって参照されます。

## 外部サービス {#external-services}

一部のチャートには、自動生成できない機能を有効にするための追加のシークレットがあります。

### OmniAuth {#omniauth}

デプロイされたGitLabで[OmniAuthプロバイダー](https://docs.gitlab.com/integration/omniauth/)の使用を有効にするには、[Globalsチャートの手順](../charts/globals.md#omniauth)に従ってください。

### LDAPパスワード {#ldap-password}

LDAPサーバーへの接続でパスワード認証が必要な場合は、パスワードをKubernetesのシークレットに保存する必要があります。

```shell
kubectl create secret generic ldap-main-password --from-literal=password=yourpasswordhere
```

次に、`--set global.appConfig.ldap.servers.main.password.secret=ldap-main-password`を使用して、パスワードを設定に挿入します。

{{< alert type="note" >}}

Helmプロパティを設定する場合は、`Secret`名を使用し、_実際のパスワード_は使用しないでください。

{{< /alert >}}

### SMTPパスワード {#smtp-password}

認証を必要とするSMTPサーバーを使用している場合は、パスワードをKubernetesのシークレットに保存します。

```shell
kubectl create secret generic smtp-password --from-literal=password=yourpasswordhere
```

次に、`--set global.smtp.password.secret=smtp-password`をHelmコマンドで使用します。

{{< alert type="note" >}}

Helmプロパティを設定する場合は、`Secret`名を使用し、_実際のパスワード_は使用しないでください。

{{< /alert >}}

### 受信メールのIMAPパスワード {#imap-password-for-incoming-emails}

GitLabは、メールへの受信アクセスに、アプリのパスワード、トークン、IMAPパスワードなどの認証文字列を使用します。

[GitLabの受信メールドキュメントでメールプロバイダーを見つけ](https://docs.gitlab.com/administration/incoming_email/)、必要な認証文字列をKubernetesのシークレットとして設定します。

```shell
kubectl create secret generic incoming-email-password --from-literal="password=auth_string_for_your_provider_here"
```

次に、`--set global.appConfig.incomingEmail.password.secret=incoming-email-password`をHelmコマンドで使用し、[ドキュメント](command-line-options.md#incoming-email-configuration)で指定されているその他の必要な設定と一緒に使用します。

{{< alert type="note" >}}

Helmプロパティを設定する場合は、`Secret`名を使用し、_実際のパスワード_は使用しないでください。

{{< /alert >}}

### サービスデスクのメールのIMAPパスワード {#imap-password-for-service-desk-emails}

GitLabは、[サービスデスクのメール](https://docs.gitlab.com/user/project/service_desk/configure/#custom-email-address)へのアクセスに、アプリのパスワード、トークン、IMAPパスワードなどの認証文字列を使用します。

[GitLabの受信メールドキュメントでメールプロバイダーを見つけ](https://docs.gitlab.com/administration/incoming_email/)、必要な認証文字列をKubernetesのシークレットとして設定します。

```shell
kubectl create secret generic service-desk-email-password --from-literal="password=auth_string_for_your_provider_here"
```

次に、`--set global.appConfig.serviceDeskEmail.password.secret=service-desk-email-password`をHelmコマンドで使用し、[ドキュメント](command-line-options.md#service-desk-email-configuration)で指定されているその他の必要な設定と一緒に使用します。

{{< alert type="note" >}}

Helmプロパティを設定する場合は、`Secret`名を使用し、_実際のパスワード_は使用しないでください。

{{< /alert >}}

### GitLabの受信メール認証トークン {#gitlab-incoming-email-auth-token}

受信メールがWebhook配信方法を使用するように設定されている場合、mail_roomサービスとwebserviceの間に共有シークレットが必要です。これは、長さが32文字で、base64でエンコードされている必要があります。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-incoming-email-auth-token --from-literal=authToken=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`global.incomingEmail.authToken`設定によって参照されます。

### GitLabサービスデスクのメール認証トークン {#gitlab-service-desk-email-auth-token}

サービスデスクのメールがWebhook配信方法を使用するように設定されている場合、mail_roomサービスとwebserviceの間に共有シークレットが必要です。これは、長さが32文字で、base64でエンコードされている必要があります。`<name>`をリリースの名前に置き換えます。

```shell
kubectl create secret generic <name>-service-desk-email-auth-token --from-literal=authToken=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`global.serviceDeskEmail.authToken`設定によって参照されます。

### Zoekt基本認証パスワード {#zoekt-basic-auth-password}

このシークレットの自動生成をチャートに任せるか、手動で作成できます（`<name>`をリリースの名前に置き換えます）:

```shell
password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
kubectl create secret generic <name>-zoekt-basicauth --from-literal=gitlab_username=gitlab --from-literal=gitlab_password="$password"
```

このシークレットは、`gitlab.zoekt.gateway.basicAuth.secretName`設定によって参照されます。

### 受信メールのMicrosoft Graphクライアントのシークレットキー {#microsoft-graph-client-secret-for-incoming-emails}

GitLabが[受信メール](https://docs.gitlab.com/administration/incoming_email/)にアクセスできるようにするには、KubernetesのシークレットにIMAPアカウントのパスワードを保存します:

```shell
kubectl create secret generic incoming-email-client-secret --from-literal=secret=your-secret-here
```

次に、`--set global.appConfig.incomingEmail.clientSecret.secret=incoming-email-client-secret`をHelmコマンドで使用し、[ドキュメント](command-line-options.md#incoming-email-configuration)で指定されているその他の必要な設定と一緒に使用します。

{{< alert type="note" >}}

Helmプロパティを設定する場合は、`Secret`名を使用し、_実際のパスワード_は使用しないでください。

{{< /alert >}}

### サービスデスクのメールのMicrosoft Graphクライアントのシークレットキー {#microsoft-graph-client-secret-for-service-desk-emails}

GitLabが[サービスデスクのメール](https://docs.gitlab.com/user/project/service_desk/configure/#custom-email-address)にアクセスできるようにするには、KubernetesのシークレットにIMAPアカウントのパスワードを保存します:

```shell
kubectl create secret generic service-desk-email-client-secret --from-literal=secret=your-secret-here
```

次に、`--set global.appConfig.serviceDeskEmail.clientSecret.secret=service-desk-email-client-secret`をHelmコマンドで使用し、[ドキュメント](command-line-options.md#service-desk-email-configuration)で指定されているその他の必要な設定と一緒に使用します。

{{< alert type="note" >}}

Helmプロパティを設定する場合は、`Secret`名を使用し、_実際のパスワード_は使用しないでください。

{{< /alert >}}

### 送信メールのMicrosoft Graphクライアントのシークレットキー {#microsoft-graph-client-secret-for-outgoing-emails}

パスワードをKubernetesのシークレットに保存します:

```shell
kubectl create secret generic microsoft-graph-mailer-client-secret --from-literal=secret=your-secret-here
```

次に、`--set global.appConfig.microsoft_graph_mailer.client_secret.secret=microsoft-graph-mailer-client-secret`をHelmコマンドで使用します。

{{< alert type="note" >}}

Helmプロパティを設定する場合は、`Secret`名を使用し、_実際のパスワード_は使用しないでください。

{{< /alert >}}

### S/MIME証明書 {#smime-certificate}

送信メールメッセージは、[S/MIME](https://en.wikipedia.org/wiki/S/MIME)標準を使用してデジタル署名できます。S/MIME証明書は、TLSタイプのシークレットとしてKubernetesのシークレットに保存する必要があります。

```shell
kubectl create secret tls smime-certificate --key=file.key --cert file.crt
```

非透過型タイプの既存のシークレットがある場合、特定のシークレットに合わせて`global.email.smime.keyName`と`global.email.smime.certName`の値を調整する必要があります。

S/MIME設定は、`values.yaml`ファイルまたはコマンドラインから設定できます。`--set global.email.smime.enabled=true`を使用してS/MIMEを有効にし、`--set global.email.smime.secretName=smime-certificate`を使用してS/MIME証明書を含むシークレットを指定します。

### スマートカード認証 {#smartcard-authentication}

[スマートカード認証](https://docs.gitlab.com/administration/auth/smartcard/)は、カスタム認証局（CA）を使用してクライアント証明書に署名します。このカスタムCAの証明書は、クライアント証明書が有効かどうかを検証するために、Webサービスポッドに挿入する必要があります。これは、k8sシークレットとして提供されます。

```shell
kubectl create secret generic <secret name> --from-file=ca.crt=<path to CA certificate>
```

証明書が保存されているシークレット内のキー名は、必ず`ca.crt`にする必要があります。

### OAuthインテグレーション {#oauth-integration}

GitLab PagesのようなさまざまなサービスのOAuthインテグレーションを設定するには、OAuth認証情報を含むシークレットが必要です。このシークレットには、アプリID（デフォルトでは、`appid`キーの下に保存）、アプリのシークレット（デフォルトでは、`appsecret`キーの下に保存）が含まれている必要があります。これらは両方とも、64文字以上の英数字文字列にすることをお勧めします。

```shell
kubectl create secret generic oauth-gitlab-pages-secret --from-literal=appid=<app id> --from-literal=appsecret=<app secret>
```

このシークレットは、`global.oauth.<service name>.secret`設定を使用して指定できます。`appid`と`appsecret`以外のキーを使用する場合は、`global.oauth.<service name>.appIdKey`と`global.oauth.<service name>.appSecretKey`の設定を使用して指定できます。

## 次の手順 {#next-steps}

すべてのシークレットが生成および保存されたら、[GitLabのデプロイ](deployment.md)に進むことができます。

## シークレットのローテーション {#rotating-secrets}

セキュリティ上の目的で必要な場合は、シークレットをローテーションできます。

1. [現在のシークレットをバックアップします](../backup-restore/backup.md#back-up-the-secrets)。
1. 便宜上、ローテーションする各シークレットについて、[手動シークレット作成](#manual-secret-creation-optional)手順に従って、`-v2`（例: `gitlab-shell-host-keys-v2`）というサフィックスが付いた新しいシークレットを作成します。
1. 新しいシークレット名を指すように、`values.yaml`ファイル内のシークレットキーを更新します。ほとんどのシークレット名は、[手動シークレット作成](#manual-secret-creation-optional)セクションのそれぞれのシークレットの下に記載されています。
1. 更新された`values.yaml`ファイルを使用して、GitLabチャートリリースをアップグレードします。
1. PostgreSQLのシークレットをローテーションする場合は、[追加の手順でローテーションを完了させる](#changing-the-postgresql-password-for-the-bundled-postgresql-subchart)必要があります。
1. GitLabが期待どおりに動作していることを確認します。問題がなければ、古いシークレットを削除しても安全です。
