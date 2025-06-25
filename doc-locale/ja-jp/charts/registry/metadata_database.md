---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: コンテナレジストリメタデータデータベースを管理します
---

{{< details >}}

- プラン:Free, Premium, Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/groups/gitlab-org/-/epics/5521)：GitLab 16.4で[ベータ](https://docs.gitlab.com/policy/development_stages_support/#beta)版[機能](https://gitlab.com/groups/gitlab-org/-/epics/5521)として
- GitLab 17.3で[一般提供](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)。

{{< /history >}}

メタデータデータベースにより、オンラインガベージコレクションなど、多くの新しいレジストリ機能が有効になり、多くのレジストリ操作の効率性が向上します。このページには、データベースの作成方法に関する情報が記載されています。

## メタデータデータベース機能のサポート {#metadata-database-feature-support}

既存のレジストリをメタデータデータベースに移行し、オンラインガベージコレクションを使用できます。

データベースが有効になっている一部の機能は、GitLab.comでのみ有効になっており、レジストリデータベースの自動データベースプロビジョニングは利用できません。[コンテナレジストリ](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#metadata-database-feature-support)データベースに関連する[機能](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#metadata-database-feature-support)の[状態](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#metadata-database-feature-support)については、[管理ドキュメント](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#metadata-database-feature-support)の[機能](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#metadata-database-feature-support)の[サポート](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#metadata-database-feature-support)セクションを[レビュー](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#metadata-database-feature-support)してください。

## データベースの作成 {#create-the-database}

以下の手順に従って、データベースとロールを手動で作成します。

{{< alert type="note" >}}

これらの手順は、バンドルされたPostgreSQLサーバーを使用していることを前提としています。独自のサーバーを使用している場合、接続方法に多少の違いがあります。

{{< /alert >}}

1. データベースのパスワードでシークレットを作成します。

   ```shell
   kubectl create secret generic RELEASE_NAME-registry-database-password --from-literal=password=randomstring
   ```

1. データベースインスタンスにログインします:

   ```shell
   kubectl exec -it $(kubectl get pods -l app.kubernetes.io/name=postgresql -o custom-columns=NAME:.metadata.name --no-headers) -- bash
   ```

   ```shell
   PGPASSWORD=${POSTGRES_POSTGRES_PASSWORD} psql -U postgres -d template1
   ```

1. データベースユーザーを作成します:

   ```sql
   CREATE ROLE registry WITH LOGIN;
   ```

1. データベースユーザーパスワードを設定します。

   1. パスワードをフェッチします:

      ```shell
      kubectl get secret RELEASE_NAME-registry-database-password -o jsonpath="{.data.password}" | base64 --decode
      ```

   1. `psql`プロンプトでパスワードを設定します:

      ```sql
      \password registry
      ```

1. データベースを作成します:

   ```sql
   CREATE DATABASE registry WITH OWNER registry;
   ```

1. PostgreSQLコマンドラインから、次に`exit`を使用してコンテナから安全に終了します:

   ```shell
   template1=# exit
   ...@gitlab-postgresql-0/$ exit
   ```

## Helmチャートインストールでメタデータデータベースを有効にする {#enable-the-metadata-database-for-helm-charts-installations}

前提要件:

- GitLab 17.3以降。
- レジストリポッドからアクセス可能なPostgreSQLデータベースバージョン12以降。
- KubernetesクラスターおよびHelmデプロイメントへのローカルアクセス。
- レジストリポッドへのSSHアクセス。

状況に一致する手順に従ってください:

- [新規インストール](#new-installations)または初めてコンテナ[レジストリ](#new-installations)を有効にします。
- 既存のコンテナイメージをメタデータデータベースに移行します:
  - [ワンステップ移行](#one-step-migration)。比較的小規模なレジストリ、またはダウンタイムを回避するための要件がない場合にのみお勧めします。
  - [3段階移行](#three-step-migration)。大規模なコンテナレジストリに推奨。

{{< alert type="note" >}}

さまざまな[テスト](https://gitlab.com/gitlab-org/gitlab/-/issues/423459#completed-tests-and-user-reports)およびユーザー[レジストリ](https://gitlab.com/gitlab-org/gitlab/-/issues/423459#completed-tests-and-user-reports)の[インポート](https://gitlab.com/gitlab-org/gitlab/-/issues/423459#completed-tests-and-user-reports)時間のリストについては、[イシュー423459のこのテーブル](https://gitlab.com/gitlab-org/gitlab/-/issues/423459#completed-tests-and-user-reports)を参照してください。レジストリデプロイメントは一意であり、インポート時間はイシューで報告されているものよりも長くなる可能性があります。

{{< /alert >}}

### 始める前に {#before-you-start}

[レジストリ](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#before-you-start)管理[ガイド](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#before-you-start)の[開始する前に](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#before-you-start)セクションをお読みください。

### 新規インストール {#new-installations}

データベースを有効にするには:

1. [データベースとKubernetesシークレットを作成します](#create-the-database)。
1. リリースの現在のHelm値を取得し、ファイルに保存します。たとえば、`gitlab`という名前のリリースと`values.yml`という名前のファイルの場合:

   ```shell
   helm get values gitlab > values.yml
   ```

1. 次の行を`values.yml`ファイルに追加します:

   ```yaml
   registry:
     enabled: true
     database:
       enabled: true
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full
       # these settings are inherited from `global.psql.ssl`
       ssl:
         secret: gitlab-registry-postgresql-ssl # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. 任意。スキーマ移行が正しく適用されていることを確認できます。次のいずれかを実行できます:
   - たとえば、移行ジョブのログ出力をレビューします:

     ```shell
     kubectl logs jobs/gitlab-registry-migrations-1
     ...
     OK: applied 154 migrations in 13.752s
     ```

   - または、Postgresデータベースに接続して、`schema_migrations`テーブルをクエリします:

     ```sql
     SELECT * FROM schema_migrations;
     ```

     すべての行に対して`applied_at`列のタイムスタンプが入力されていることを確認します。

レジストリは、メタデータデータベースを使用する準備ができました!

### 既存のレジストリ {#existing-registries}

既存のコンテナレジストリデータを、ワンステップまたは3つのステップで移行できます。いくつかの要因が移行の期間に影響します:

- 既存のレジストリデータのサイズ。
- PostgresSQLインスタンスの仕様。
- クラスターで実行されているレジストリポッドの数。
- レジストリ、PostgresSQL、および設定されたオブジェクトストレージ間のネットワークレイテンシー。

{{< alert type="note" >}}

[移行](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5293)プロセスを自動化する作業は、[イシュー5293](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5293)で[追跡](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5293)されています。

{{< /alert >}}

#### 要件 {#requirements}

ワンステップまたは3段階移行を試みる前に、次の手順を完了する必要があります:

1. [データベースとKubernetesシークレットを作成します](#create-the-database)。
1. リリースの現在のHelm値を取得し、ファイルに保存します。たとえば、`gitlab`という名前のリリースと`values.yml`という名前のファイルの場合:

   ```shell
   helm get values gitlab > values.yml
   ```

#### ワンステップ移行 {#one-step-migration}

ワンステップ移行を行うときは、次のことに注意してください:

- 移行中、レジストリは`read-only`モードのままにする必要があります。
- 移行が実行されているポッドが終了した場合は、プロセスを完全に再起動する必要があります。このプロセスを改善する作業は、[イシュー5293](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5293)で[追跡](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5293)されています。

既存のコンテナレジストリをワンステップでメタデータデータベースに移行するには:

1. [要件](#requirements)セクションに記載されている手順に従ってください。
1. `values.yml`ファイルの`registry:`セクションを見つけ、`database`セクションを追加します。設定:
   - `database.configure`を`true`に設定します。
   - `database.enabled`を`false`に設定します。
   - `maintenance.readonly.enabled`を`true`に設定します。
   - `migrations.enabled`を`true`に設定します。

   ```yaml
   registry:
     enabled: true
     maintenance:
       readonly:
         enabled: true  # must remain set to true while the migration is executed
     database:
       configure: true  # must be true for the migration step
       enabled: false  # must be false!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. Helmインストールをアップグレードして、デプロイメントの変更を適用します:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. SSH経由でレジストリポッドの1つに接続します。たとえば、`gitlab-registry-5ddcd9f486-bvb57`という名前のポッドの場合:

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. ホームディレクトリに変更し、次のコマンドを実行します:

   ```shell
   cd ~
   /usr/bin/registry database import /etc/docker/registry/config.yml
   ```

1. コマンドが正常に完了した場合、すべてのイメージが完全にインポートされました。これで、データベースを有効にし、設定で読み取り専用モードをオフにすることができます:

   ```yaml
   registry:
     enabled: true
     maintenance:
       readonly:
         enabled: false
     database:
       configure: true  # once database.enabled is set to true, this option can be removed
       enabled: true
       name: registry
       user: registry
       password:
         secret: gitlab-registry-database-password
         key: password
       migrations:
         enabled: true
   ```

1. Helmインストールをアップグレードして、デプロイメントの変更を適用します:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

メタデータデータベースをすべての操作に使用できるようになりました!

#### 3段階移行 {#three-step-migration}

既存のコンテナレジストリデータを、3つの個別のステップでメタデータデータベースに移行できます。これは、次の場合に推奨されます:

- レジストリに大量のデータが含まれている。
- 移行中のダウンタイムを最小限に抑える必要がある。

3つのステップで移行するには、次のことを行う必要があります:

1. リポジトリの事前インポート
1. すべてのリポジトリデータをインポートします
1. 一般的なblobをインポートする

{{< alert type="note" >}}

ユーザーは、ステップ1の[インポート](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)が[1時間あたり2～4 TBのレートで完了したと報告しています](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)。スピードが遅い場合、100TBを超えるデータを持つレジストリでは、48時間以上かかることがあります。

{{< /alert >}}

##### ステップ1リポジトリの事前インポート {#step-1-pre-import-repositories}

インスタンスが大きい場合、レジストリのサイズによっては、このプロセスを完了するのに数時間または数日かかることがあります。このプロセス中もレジストリを使用できます。

{{< alert type="warning" >}}

[移行](https://gitlab.com/gitlab-org/container-registry/-/issues/1162)を[再起動](https://gitlab.com/gitlab-org/container-registry/-/issues/1162)することは[まだ不可能](https://gitlab.com/gitlab-org/container-registry/-/issues/1162)であるため、[移行](https://gitlab.com/gitlab-org/container-registry/-/issues/1162)を完了まで実行することが重要です。操作を停止する必要がある場合は、このステップを再起動する必要があります。

{{< /alert >}}

1. [要件](#requirements)セクションに記載されている手順に従ってください。
1. `values.yml`ファイルの`registry:`セクションを見つけ、`database`セクションを追加します。設定:
   - `database.configure`を`true`に設定します。
   - `database.enabled`を`false`に設定します。
   - `migrations.enabled`を`true`に設定します。

   ```yaml
   registry:
     enabled: true
     database:
       configure: true
       enabled: false  # must be false!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. ファイルを保存し、Helmインストールをアップグレードして、デプロイメントの変更を適用します:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. SSHでレジストリポッドの1つに接続します。たとえば、`gitlab-registry-5ddcd9f486-bvb57`という名前のポッドの場合:

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. ホームディレクトリに変更し、次のコマンドを実行します:

   ```shell
   cd ~
   /usr/bin/registry database import --step-one /etc/docker/registry/config.yml
   ```

`registry import complete`が表示されると、最初のステップが完了します。

{{< alert type="note" >}}

要件となるダウンタイムを削減するために、できるだけ早く次のステップをスケジュールするようにしてください。ステップ1が完了してから1週間以内が理想的です。次のステップの前にレジストリに書き込まれた新しいデータは、そのステップに時間がかかる原因となります。

{{< /alert >}}

##### ステップ2すべてのリポジトリデータをインポートします {#step-2-import-all-repository-data}

このステップでは、レジストリを`read-only`モードに設定する必要があります。このプロセス中にダウンタイムに十分な時間を確保してください。

1. `values.yml`ファイルでレジストリを`read-only`モードに設定します:

   ```yaml
   registry:
     enabled: true
     maintenance:
       readonly:
         enabled: true   # must be true!
     database:
       configure: true
       enabled: false  # must be false!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. ファイルを保存し、Helmインストールをアップグレードして、デプロイメントの変更を適用します:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. SSHでレジストリポッドの1つに接続します。たとえば、`gitlab-registry-5ddcd9f486-bvb57`という名前のポッドの場合:

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. ホームディレクトリに変更し、次のコマンドを実行します:

   ```shell
   cd ~
   /usr/bin/registry database import --step-two /etc/docker/registry/config.yml
   ```

1. コマンドが正常に完了した場合、すべてのイメージが完全にインポートされました。これで、データベースを有効にし、設定で読み取り専用モードをオフにすることができます:

   ```yaml
   registry:
     enabled: true
     maintenance:        # this section can be removed
       readonly:
         enabled: false
     database:
       configure: true  # once database.enabled is set to true, this option can be removed
       enabled: true   # must be true!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. ファイルを保存し、Helmインストールをアップグレードして、デプロイメントの変更を適用します:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

メタデータデータベースをすべての操作に使用できるようになりました!

##### ステップ3一般的なblobをインポートする {#step-3-import-common-blobs}

レジストリは、メタデータにデータベースを完全に使用するようになりましたが、潜在的に未使用のレイヤーblobにはまだアクセスできません。

プロセスを完了するには、移行の最後のステップを実行します:

```shell
cd ~
/usr/bin/registry database import --step-three /etc/docker/registry/config.yml
```

コマンドが正常に完了すると、レジストリがデータベースに完全に移行されます!

## データベース移行 {#database-migrations}

コンテナレジストリは、次の2種類の移行をサポートしています:

- **標準スキーマ移行**:新しいアプリケーションコードをデプロイする前に実行する必要があるデータベース構造への変更。これらは、デプロイの遅延を回避するために高速である必要があります。

- **デプロイ**後の**移行**アプリケーションの実行中に実行できるデータベース構造への変更。大規模なテーブルにインデックスを作成するなど、より長い操作に使用され、スタートアップの遅延とアップグレードのダウンタイムの延長を回避します。

### データベース移行を適用する {#apply-database-migrations}

デフォルトでは、`database.migrations.enabled`が`true`に設定されている場合、レジストリチャートは標準スキーマとデプロイ後の移行の両方を自動的に適用します。

アップグレード中のダウンタイムを削減するために、デプロイ後の移行をスキップし、アプリケーションの起動後に手動で適用できます:

1. レジストリデプロイメントの場合、`ExtraEnv`を使用して`SKIP_POST_DEPLOYMENT_MIGRATIONS`環境変数を`true`に設定します:

   ```yaml
   registry:
     extraEnv:
       SKIP_POST_DEPLOYMENT_MIGRATIONS: true
   ```

1. [アップグレード](_index.md#running-administrative-commands-against-the-container-registry)後、[レジストリ](_index.md#running-administrative-commands-against-the-container-registry)[ポッド](_index.md#running-administrative-commands-against-the-container-registry)に接続します

1. 保留中のデプロイ後の移行を適用します:

   ```shell
   registry database migrate up /etc/docker/registry/config.yml
   ```

{{< alert type="note" >}}

`migrate up`コマンドは、移行の適用方法を制御するために使用できる追加のフラグをいくつか提供します。詳細については、`registry database migrate up --help`を実行してください。

{{< /alert >}}

## トラブルシューティング {#troubleshooting}

### エラー： `panic: interface conversion: interface {} is nil, not bool` {#error-panic-interface-conversion-interface--is-nil-not-bool}

[既存のレジストリ](#existing-registries)をインポートする際に、このエラーが表示されることがあります。

```shell
panic: interface conversion: interface {} is nil, not bool
```

これは既知の[イシュー](https://gitlab.com/gitlab-org/container-registry/-/merge_requests/2041)で、レジストリバージョン`v4.15.2-gitlab`およびGitLab 17.9で修正されています。

このイシューを回避するには、レジストリのバージョンをアップグレードしてください。

1. `values.yml`ファイルで、レジストリイメージのtagを設定します。

   ```yaml
   registry:
     image:
       tag: v4.15.2-gitlab
   ```

1. Helmインストールをアップグレードします。

   ```shell
   helm upgrade gitlab -f values.yml
   ```

または、レジストリの設定を手動でアップデートすることもできます。

- `/etc/docker/registry/config.yml`で、ストレージプロバイダーの`parallelwalk`を`false`に設定します。たとえば、S3の場合:

  ```yaml
  storage:
    s3:
      parallelwalk: false
  ```
