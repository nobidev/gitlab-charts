---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのシークレットを設定する
---

{{< details >}}

- プラン:Free, Premium, Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

GitLabを稼働させるには、さまざまなシークレットが必要です。

GitLabコンポーネント:

- レジストリ認証証明書
- GitLab ShellのSSHホストキーと証明書
- 個々のGitLabサービス用パスワード
- GitLab PagesのTLS証明書

オプションの外部サービス:

- SMTPサーバー
- LDAP
- OmniAuth
- 受信メール用IMAP (mail_roomサービス経由)
- Service Deskメール用IMAP (mail_roomサービス経由)
- 受信メール用OAuth2を使用したMicrosoft Graph (mail_roomサービス経由)
- Service Deskメール用OAuth2を使用したMicrosoft Graph (mail_roomサービス経由)
- 送信メール用OAuth2を使用したMicrosoft Graph
- S/MIME証明書
- スマートカード認証
- OAuthインテグレーション

手動で提供されないシークレットは、ランダムな値で自動的に生成されます。HTTPS証明書の自動生成はLet's Encryptによって提供されます。

自動生成されたシークレットを利用するには、[次の手順](#next-steps)に進みます。

独自のシークレットを指定するには、[手動でのシークレットの作成](#manual-secret-creation-optional)に進みます。

## 手動でのシークレットの作成 (オプション) {#manual-secret-creation-optional}

このドキュメントの前の手順に従った場合は、`gitlab`をリリース名として使用します。

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
  - [GitLab Service Deskメール認証トークン](#gitlab-service-desk-email-auth-token)
  - [Zoekt Basic認証パスワード](#zoekt-basic-auth-password)
- [外部サービス](#external-services)
  - [OmniAuth](#omniauth)
  - [LDAPパスワード](#ldap-password)
  - [SMTPパスワード](#smtp-password)
  - [受信メール用IMAPパスワード](#imap-password-for-incoming-emails)
  - [Service Desk用IMAPパスワード](#imap-password-for-service-desk-emails)
  - [受信メール用Microsoft Graphクライアントシークレット](#microsoft-graph-client-secret-for-incoming-emails)
  - [Service Desk用Microsoft Graphクライアントシークレット](#microsoft-graph-client-secret-for-service-desk-emails)
  - [送信メール用Microsoft Graphクライアントシークレット](#microsoft-graph-client-secret-for-outgoing-emails)
  - [S/MIME証明書](#smime-certificate)
  - [スマートカード認証](#smartcard-authentication)

### レジストリ認証証明書 {#registry-authentication-certificates}

GitLabとレジストリ間の通信はIngressの背後で行われるため、ほとんどの場合、この通信には自己署名証明書を使用すれば十分です。このトラフィックがネットワーク経由で公開されている場合は、公開的に有効な証明書を生成する必要があります。

以下の例では、自己署名証明書が必要であると想定しています。

証明書とキーのペアを生成します:

```shell
mkdir -p certs
openssl req -new -newkey rsa:4096 -subj "/CN=gitlab-issuer" -nodes -x509 -keyout certs/registry-example-com.key -out certs/registry-example-com.crt
```

これらの証明書を含むシークレットを作成します。`registry-auth.key`および`registry-auth.crt`キーを`<name>-registry-secret`シークレット内に作成します。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-registry-secret --from-file=registry-auth.key=certs/registry-example-com.key --from-file=registry-auth.crt=certs/registry-example-com.crt
```

このシークレットは、`global.registry.certificate.secret`設定によって参照されます。

### レジストリの機密通知ヘッダー {#registry-sensitive-notification-headers}

詳細については、[レジストリ通知の設定に関するドキュメント](../charts/globals.md#configure-registry-settings)を確認してください。

シークレットの内容は、項目が1つしか含まれていない場合でも、項目のリストである必要があります。コンテンツが単なる文字列の場合、チャートは必要に応じてそれをリストに変換**しません**。

`RandomFooBar`の値を持つ`registry-authorization-header`シークレットが作成される例を考えてみましょう。

```shell
kubectl create secret generic registry-authorization-header --from-literal=value="[RandomFooBar]"
```

デフォルトでは、シークレット内で使用されるキーは「value」です。ただし、ユーザーは別のキーを使用できますが、ヘッダーマップ項目で`key`として指定されていることを確認する必要があります。

### SSHホストキー {#ssh-host-keys}

OpenSSH証明書とキーのペアを生成します:

```shell
mkdir -p hostKeys
ssh-keygen -t rsa  -f hostKeys/ssh_host_rsa_key -N ""
ssh-keygen -t dsa  -f hostKeys/ssh_host_dsa_key -N ""
ssh-keygen -t ecdsa  -f hostKeys/ssh_host_ecdsa_key -N ""
ssh-keygen -t ed25519  -f hostKeys/ssh_host_ed25519_key -N ""
```

これらの証明書を含むシークレットを作成します。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-shell-host-keys --from-file hostKeys
```

このシークレットは、`global.shell.hostKeys.secret`設定によって参照されます。

このシークレットがローテーションされると、すべてのSSHクライアントに`hostname mismatch`エラーが表示されます。

### 初期Enterpriseライセンス {#initial-enterprise-license}

{{< alert type="warning" >}}

この方法は、インストール時にのみライセンスを追加します。Web UIの管理者エリアを使用して、ライセンスを更新またはアップグレードしてください。

{{< /alert >}}

GitLabインスタンスのEnterpriseライセンスを格納するためのKubernetesシークレットを作成します。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-license --from-file=license=/tmp/license.gitlab
```

次に、`--set global.gitlab.license.secret=<name>-gitlab-license`を使用して、ライセンスを構成に注入します。

`global.gitlab.license.key`オプションを使用して、ライセンスシークレットのライセンスを指すデフォルトの`license`キーを変更することもできます。

### 初期rootパスワード {#initial-root-password}

初期rootパスワードを格納するためのKubernetesシークレットを作成します。パスワードは6文字以上にする必要があります。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-initial-root-password --from-literal=password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)
```

### Redisパスワード {#redis-password}

Redisのランダムな64文字の英数字パスワードを生成します。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-redis-secret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

既存のRedisクラスターを使用してデプロイする場合は、ランダムに生成されたパスワードの代わりに、base64エンコードされたRedisクラスターへのアクセスに使用するパスワードを使用してください。

このシークレットは、`global.redis.auth.secret`設定によって参照されます。

### GitLab Shellシークレット {#gitlab-shell-secret}

GitLab Shell用のランダムな64文字の英数字シークレットを生成します。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-shell-secret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは、`global.shell.authToken.secret`設定によって参照されます。

### Gitalyシークレット {#gitaly-secret}

Gitalyのランダムな64文字の英数字トークンを生成します。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-gitaly-secret --from-literal=token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは、`global.gitaly.authToken.secret`設定によって参照されます。

### Praefectシークレット {#praefect-secret}

Praefectのランダムな64文字の英数字トークンを生成します。`<name>`をリリース名に置き換えます:

```shell
kubectl create secret generic <name>-praefect-secret --from-literal=token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは、`global.praefect.authToken.secret`設定によって参照されます。

### GitLab Railsシークレット {#gitlab-rails-secret}

{{< history >}}

- `active_record_encryption_*`キーは[GitLab 17.8](../releases/8_0.md#upgrade-to-880)で追加されました。

{{< /history >}}

`<name>`をリリース名に置き換えます。

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

データベースの暗号化キーが含まれているため、このシークレットをローテーションする**ことは推奨されません**。シークレットがローテーションされると、[シークレットファイルが失われた場合](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#when-the-secrets-file-is-lost)と同じ動作になります。

### GitLab Workhorseシークレット {#gitlab-workhorse-secret}

Workhorseシークレットを生成します。これは、長さが32文字で、base64エンコードされている必要があります。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-workhorse-secret --from-literal=shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`global.workhorse.secret`設定によって参照されます。

### GitLab Runnerシークレット {#gitlab-runner-secret}

`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-runner-secret --from-literal=runner-registration-token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは、`gitlab-runner.runners.secret`設定によって参照されます。

### GitLab KASシークレット {#gitlab-kas-secret}

KASサブチャートをインストールせずにこのチャートをデプロイする場合でも、GitLab RailsにはKASのシークレットが必要です。それでも、以下の手順に従ってこのシークレットを手動で作成するか、チャートにシークレットを自動生成させることができます。

`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-kas-secret --from-literal=kas_shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`global.appConfig.gitlab_kas.key`設定によって参照されます。

### GitLab KAS APIシークレット {#gitlab-kas-api-secret}

チャートにシークレットを自動生成させるか、このシークレットを手動で作成できます ( `<name>`をリリース名に置き換えます):

```shell
kubectl create secret generic <name>-kas-private-api --from-literal=kas_private_api_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`gitlab.kas.privateApi.secret`設定によって参照されます。

### GitLab KAS WebSocketトークンシークレット {#gitlab-kas-websocket-token-secret}

チャートにシークレットを自動生成させるか、このシークレットを手動で作成できます ( `<name>`をリリース名に置き換えます):

```shell
kubectl create secret generic <name>-kas-websocket-token --from-literal=kas_websocket_token_secret=$(head -c 72 /dev/urandom | base64 -w0)
```

このシークレットは、`gitlab.kas.websocketToken.secret`設定によって参照されます。

### GitLab Suggested Reviewersシークレット {#gitlab-suggested-reviewers-secret}

{{< alert type="note" >}}

レビュアーの推奨シークレットは自動的に作成され、GitLab.comでのみ使用されます。このシークレットはGitLab Self-Managedでは必要ありません。

{{< /alert >}}

GitLab Railsには、レビュアーの推奨のシークレットが必要です。チャートにシークレットを自動生成させるか、このシークレットを手動で作成できます ( `<name>`をリリース名に置き換えます):

```shell
kubectl create secret generic <name>-gitlab-suggested-reviewers --from-literal=suggested_reviewers_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`global.appConfig.suggested_reviewers.secret`設定によって参照されます。

### MinIOシークレット {#minio-secret}

MinIO用のランダムな20文字と64文字の英数字キーのセットを生成します。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-minio-secret --from-literal=accesskey=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 20) --from-literal=secretkey=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは、`global.minio.credentials.secret`設定によって参照されます。

### PostgreSQLパスワード {#postgresql-password}

ランダムな64文字の英数字パスワードを生成します。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-postgresql-password \
    --from-literal=postgresql-password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64) \
    --from-literal=postgresql-postgres-password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

このシークレットは、`global.psql.password.secret`設定によって参照されます。

#### バンドルされたPostgreSQLサブチャートのPostgreSQLパスワードの変更 {#changing-the-postgresql-password-for-the-bundled-postgresql-subchart}

{{< alert type="warning" >}}

デフォルトのHelm Chart構成は**本番環境を対象としていません**。これにはバンドルされたPostgreSQLサブチャートが含まれます。

{{< /alert >}}

バンドルされたPostgreSQLサブチャートは、データベースが最初に作成されたときに、シークレットからのパスワードを使用してデータベースを構成するだけです。既存のデータベースでパスワードを変更するには、追加の手順を実行する必要があります。

この操作は、変更が行われている間、ユーザーに中断をもたらすことに注意してください。

PostgreSQLシークレットをローテーションするには:

1. PostgreSQLシークレットの一般的な[シークレットのローテーション](#rotating-secrets)手順を完了します。
1. PostgreSQLポッドにExecし、データベース内のパスワードを更新します:

   ```shell
   # Exec into the PostgreSQL pod
   kubectl exec -it <name>-postgresql-0 -- sh

   # Inside the pod, update the passwords in the database
   sed -i 's/^\(local .*\)md5$/\1trust/' /opt/bitnami/postgresql/conf/pg_hba.conf
   pg_ctl reload ; sleep 1
   echo "ALTER USER postgres WITH PASSWORD '$(echo $POSTGRES_POSTGRES_PASSWORD)' ; ALTER USER gitlab WITH PASSWORD '$(echo POSTGRES_PASSWORD)'" | psql -U postgres -d gitlabhq_production -f -
   sed -i 's/^\(local .*\)trust$/\1md5/' /opt/bitnami/postgresql/conf/pg_hba.conf
   pg_ctl reload
   ```

1. `gitlab-exporter`、`postgresql`、`toolbox`、`sidekiq`、および`webservice`ポッドを`kubectl delete pod`コマンドを使用して削除し、新しいポッドが新しいシークレットとともにロードされ、データベースに接続できるようにします。

### GitLab Pagesシークレット {#gitlab-pages-secret}

GitLab Pagesのシークレットを生成します。これは、長さが32文字で、base64エンコードされている必要があります。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-gitlab-pages-secret --from-literal=shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`global.pages.apiSecret.secret`設定によって参照されます。

### レジストリHTTPシークレット {#registry-http-secret}

すべてのレジストリポッドで共有されるランダムな64文字の英数字キーを生成します。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-registry-httpsecret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64 | base64)
```

このシークレットは、`global.registry.httpSecret.secret`設定によって参照されます。

### レジストリ通知シークレット {#registry-notification-secret}

すべてのレジストリポッドとGitLab webserviceポッドで共有されるランダムな32文字の英数字キーを生成します。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-registry-notification --from-literal=secret=[\"$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)\"]
```

このシークレットは、`global.registry.notificationSecret.secret`設定によって参照されます。

### Praefect DBパスワード {#praefect-db-password}

ランダムな64文字の英数字パスワードを生成します。`<name>`をリリース名に置き換えます:

```shell
kubectl create secret generic <name>-praefect-dbsecret \
    --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64) \
```

このシークレットは、`global.praefect.dbSecret`設定によって参照されます。

## 外部サービス {#external-services}

一部のチャートには、自動的に生成できない機能を有効にするための追加のシークレットがあります。

### OmniAuth {#omniauth}

デプロイされたGitLabで[OmniAuthプロバイダー](https://docs.gitlab.com/integration/omniauth/)の使用を有効にするには、[Globalsチャートの手順](../charts/globals.md#omniauth)に従ってください

### LDAPパスワード {#ldap-password}

LDAPサーバーに接続するためにパスワード認証が必要な場合は、パスワードをKubernetesシークレットに格納する必要があります。

```shell
kubectl create secret generic ldap-main-password --from-literal=password=yourpasswordhere
```

次に、`--set global.appConfig.ldap.servers.main.password.secret=ldap-main-password`を使用して、パスワードを構成に挿入します。

{{< alert type="note" >}}

Helmプロパティを構成するときは、_実際のパスワード_ではなく、`Secret`名を使用してください。

{{< /alert >}}

### SMTPパスワード {#smtp-password}

認証を必要とするSMTPサーバーを使用している場合は、パスワードをKubernetesシークレットに格納します。

```shell
kubectl create secret generic smtp-password --from-literal=password=yourpasswordhere
```

次に、Helmコマンドで`--set global.smtp.password.secret=smtp-password`を使用します。

{{< alert type="note" >}}

Helmプロパティを構成するときは、_実際のパスワード_ではなく、`Secret`名を使用してください。

{{< /alert >}}

### 受信メール用IMAPパスワード {#imap-password-for-incoming-emails}

GitLabは、アプリのパスワード、トークン、IMAPパスワードなどの認証文字列を使用して受信メールにアクセスします。

[GitLab受信メールのドキュメントでメールプロバイダーを検索](https://docs.gitlab.com/administration/incoming_email/)し、必要な認証文字列をKubernetesシークレットとして設定します。

```shell
kubectl create secret generic incoming-email-password --from-literal="password=auth_string_for_your_provider_here"
```

次に、[ドキュメント内](command-line-options.md#incoming-email-configuration)で指定されている他の必要な設定とともに、Helmコマンドで`--set global.appConfig.incomingEmail.password.secret=incoming-email-password`を使用します。

{{< alert type="note" >}}

Helmプロパティを構成するときは、_実際のパスワード_ではなく、`Secret`名を使用してください。

{{< /alert >}}

### Service Deskメール用IMAPパスワード {#imap-password-for-service-desk-emails}

GitLabは、アプリのパスワード、トークン、IMAPパスワードなどの認証文字列を使用して[Service Deskメール](https://docs.gitlab.com/user/project/service_desk/configure/#custom-email-address)にアクセスします。

[GitLab受信メールのドキュメントでメールプロバイダーを検索](https://docs.gitlab.com/administration/incoming_email/)し、必要な認証文字列をKubernetesシークレットとして設定します。

```shell
kubectl create secret generic service-desk-email-password --from-literal="password=auth_string_for_your_provider_here"
```

次に、[ドキュメント内](command-line-options.md#service-desk-email-configuration)で指定されている他の必要な設定とともに、Helmコマンドで`--set global.appConfig.serviceDeskEmail.password.secret=service-desk-email-password`を使用します。

{{< alert type="note" >}}

Helmプロパティを構成するときは、_実際のパスワード_ではなく、`Secret`名を使用してください。

{{< /alert >}}

### GitLab受信メール認証トークン {#gitlab-incoming-email-auth-token}

受信メールがWebhook配信メソッドを使用するように構成されている場合、mail_roomサービスとwebserviceの間に共有シークレットが必要です。これは、長さが32文字で、base64エンコードされている必要があります。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-incoming-email-auth-token --from-literal=authToken=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`global.incomingEmail.authToken`設定によって参照されます。

### GitLab Service Deskメール認証トークン {#gitlab-service-desk-email-auth-token}

Service DeskメールがWebhook配信メソッドを使用するように構成されている場合、mail_roomサービスとwebserviceの間に共有シークレットが必要です。これは、長さが32文字で、base64エンコードされている必要があります。`<name>`をリリース名に置き換えます。

```shell
kubectl create secret generic <name>-service-desk-email-auth-token --from-literal=authToken=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

このシークレットは、`global.serviceDeskEmail.authToken`設定によって参照されます。

### Zoekt Basic認証パスワード {#zoekt-basic-auth-password}

シークレットを自動生成するようにGitLabチャートに任せることも、このシークレットを手動で作成することもできます（`<name>`をリリースの名前に置き換えてください）。

```shell
password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
kubectl create secret generic <name>-zoekt-basicauth --from-literal=gitlab_username=gitlab --from-literal=gitlab_password="$password"
```

このシークレットは、`gitlab.zoekt.gateway.basicAuth.secretName`設定によって参照されます。

### 受信メール用のMicrosoft Graphクライアントシークレット {#microsoft-graph-client-secret-for-incoming-emails}

[受信](https://docs.gitlab.com/administration/incoming_email/)メールへのアクセスをGitLabに許可するには、IMAPアカウントのパスワードをKubernetesのシークレットに保存します。

```shell
kubectl create secret generic incoming-email-client-secret --from-literal=secret=your-secret-here
```

次に、`--set global.appConfig.incomingEmail.clientSecret.secret=incoming-email-client-secret`を[ドキュメント](command-line-options.md#incoming-email-configuration)に指定されている他の必要な設定とともに、Helmコマンドで使用します。

{{< alert type="note" >}}

Helmプロパティを構成する際は、`Secret`名を使用し、_実際のパスワード_は使用しないでください。

{{< /alert >}}

### サービスデスクメール用のMicrosoft Graphクライアントシークレット {#microsoft-graph-client-secret-for-service-desk-emails}

[サービスデスク](https://docs.gitlab.com/user/project/service_desk/configure/#custom-email-address)メールへのアクセスをGitLabに許可するには、IMAPアカウントのパスワードをKubernetesのシークレットに保存します。

```shell
kubectl create secret generic service-desk-email-client-secret --from-literal=secret=your-secret-here
```

次に、`--set global.appConfig.serviceDeskEmail.clientSecret.secret=service-desk-email-client-secret`を[ドキュメント](command-line-options.md#service-desk-email-configuration)に指定されている他の必要な設定とともに、Helmコマンドで使用します。

{{< alert type="note" >}}

Helmプロパティを構成する際は、`Secret`名を使用し、_実際のパスワード_は使用しないでください。

{{< /alert >}}

### 送信メール用のMicrosoft Graphクライアントシークレット {#microsoft-graph-client-secret-for-outgoing-emails}

Kubernetesのシークレットにパスワードを保存します。

```shell
kubectl create secret generic microsoft-graph-mailer-client-secret --from-literal=secret=your-secret-here
```

次に、`--set global.appConfig.microsoft_graph_mailer.client_secret.secret=microsoft-graph-mailer-client-secret`をHelmコマンドで使用します。

{{< alert type="note" >}}

Helmプロパティを構成する際は、`Secret`名を使用し、_実際のパスワード_は使用しないでください。

{{< /alert >}}

### S/MIME証明書 {#smime-certificate}

[送信](https://en.wikipedia.org/wiki/S/MIME)メールメッセージは、S/MIME標準を使用してデジタル署名できます。S/MIME証明書は、TLSタイプのシークレットとしてKubernetesのシークレットに保存する必要があります。

```shell
kubectl create secret tls smime-certificate --key=file.key --cert file.crt
```

不透明型として既存のシークレットがある場合は、`global.email.smime.keyName`および`global.email.smime.certName`の値を、特定のシークレットに合わせて調整する必要があります。

S/MIME設定は、`values.yaml`ファイルまたはコマンドラインで設定できます。`--set global.email.smime.enabled=true`を使用してS/MIMEを有効にし、`--set global.email.smime.secretName=smime-certificate`を使用してS/MIME証明書を含むシークレットを指定します。

### スマートカード認証 {#smartcard-authentication}

[スマートカード](https://docs.gitlab.com/administration/auth/smartcard/)認証では、カスタム公開認証局（CA）を使用してクライアント証明書に署名します。クライアント証明書が有効かどうかをVerifyするために、このカスタムCAの証明書をWebサービスのポッドにデプロイする必要があります。これはK8sのシークレットとして提供されます。

```shell
kubectl create secret generic <secret name> --from-file=ca.crt=<path to CA certificate>
```

証明書が保存されているシークレット内のキー名は、必ず`ca.crt`にしてください。

### OAuthインテグレーション {#oauth-integration}

GitLab PagesなどのさまざまなサービスのOAuthインテグレーションを構成するには、OAuth認証情報を含むシークレットが必要です。このシークレットには、アプリID（`appid`キーにデフォルトで格納）と、アプリシークレット（`appsecret`キーにデフォルトで格納）が含まれている必要があり、どちらも英数字の文字列で、少なくとも64文字の長さであることが推奨されます。

```shell
kubectl create secret generic oauth-gitlab-pages-secret --from-literal=appid=<app id> --from-literal=appsecret=<app secret>
```

このシークレットは、`global.oauth.<service name>.secret`設定を使用して指定できます。`appid`および`appsecret`以外のキーを使用する場合は、`global.oauth.<service name>.appIdKey`および`global.oauth.<service name>.appSecretKey`設定を使用して指定できます。

## 次の手順 {#next-steps}

すべての[シークレット](deployment.md)を生成および保存したら、GitLabのデプロイに進むことができます。

## シークレットのローテーション {#rotating-secrets}

セキュリティ上の目的で必要な場合は、シークレットをローテーションできます。

1. [現在のシークレットをバックアップ](../backup-restore/backup.md#back-up-the-secrets)します。
1. 便宜上、ローテーションする各シークレットについて、`-v2` (`gitlab-shell-host-keys-v2`など) というサフィックスが付いた新しい[シークレット](#manual-secret-creation-optional)を手動シークレットCreateの手順に従ってCreateします。
1. 新しいシークレット名を指すように、`values.yaml`ファイル内のシークレット キーを更新します。ほとんどのシークレット名は、[手動](#manual-secret-creation-optional)シークレットCreateセクションのそれぞれのシークレットで説明されています。
1. 更新された`values.yaml`ファイルを使用して、GitLabチャート リリースをアップグレードします。
1. [PostgreSQL](#changing-the-postgresql-password-for-the-bundled-postgresql-subchart)のシークレットをローテーションする場合は、ローテーションを完了するための追加の手順があります。
1. GitLabが期待どおりに動作していることを確認します。その場合は、古いシークレットを削除しても安全です。
