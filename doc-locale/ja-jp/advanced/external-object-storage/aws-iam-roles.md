---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートを使用する際のAWSのIAMロール
---

チャート内の外部オブジェクトストレージのデフォルト設定では、アクセスキーとシークレットキーを使用します。[`kube2iam`](https://github.com/jtblin/kube2iam)、[`kiam`](https://github.com/uswitch/kiam)、または[IRSA](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/)と組み合わせてIAMロールを使用することも可能です。

## IAMロール {#iam-role}

IAMロールは、S3バケットに対する読み取り、書き込み、およびリストの権限を必要とします。バケットごとにロールを設定するか、それらを結合するかを選択できます。

## チャートの設定 {#chart-configuration}

IAMロールは、以下に示すように、アノテーションを追加し、シークレットを変更することで指定できます。

### レジストリ {#registry}

IAMロールは、アノテーションキーを介して指定できます。

```plaintext
--set registry.annotations."iam\.amazonaws\.com/role"=<role name>
```

[`registry-storage.yaml`](../../charts/registry/_index.md#storage)シークレットを作成する際に、アクセスキーとシークレットキーを省略します。

```yaml
s3:
  bucket: gitlab-registry
  v4auth: true
  region: us-east-1
```

*ノート*:キーペアを指定すると、IAMロールは無視されます。詳細については、[AWSのドキュメント](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html#credentials-default)を参照してください。

### LFS、アーティファクト、アップロード、パッケージ {#lfs-artifacts-uploads-packages}

LFS、アーティファクト、アップロード、パッケージの場合、`webservice`および`sidekiq`の設定のアノテーションキーを介してIAMロールを指定できます。

```shell
--set gitlab.sidekiq.annotations."iam\.amazonaws\.com/role"=<role name>
--set gitlab.webservice.annotations."iam\.amazonaws\.com/role"=<role name>
```

[`object-storage.yaml`](../../charts/globals.md#connection)シークレットの場合、アクセスキーとシークレットキーを省略します。GitLab RailsのコードベースはS3ストレージにFogを使用しているため、Fogがロールを使用するには、[`use_iam_profile`](https://docs.gitlab.com/administration/cicd/secure_files/#s3-compatible-connection-settings)キーを追加する必要があります。

```yaml
provider: AWS
use_iam_profile: true
region: us-east-1
```

{{< alert type="note" >}}

この設定に`endpoint`を含めないでください。IRSAは[STSトークンを使用します。これらは、専用のエンドポイントを使用します](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html)。`endpoint`が指定されている場合、AWSクライアントは[このエンドポイントに`AssumeRoleWithWebIdentity`メッセージを送信しようとし、失敗します](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3148#note_889357676)。

{{< /alert >}}

### バックアップ {#backups}

Toolboxの設定により、S3にバックアップをアップロードするためのアノテーションを設定できます。

```shell
--set gitlab.toolbox.annotations."iam\.amazonaws\.com/role"=<role name>
```

[`s3cmd.config`](_index.md#backups-storage-example)シークレットは、アクセスキーとシークレットキーなしで作成されます。

```ini
[default]
bucket_location = us-east-1
```

### サービスアカウントaccount>でのIAMロールの使用 {#using-iam-roles-for-service-accounts}

GitLabがAWS Amazon EKSクラスター (バージョン1.14以降) で実行されている場合、アクセストークンを生成または保存する必要なく、AWS IAMロールを使用してS3オブジェクトストレージに認証できます。Amazon EKSクラスターでIAMロールを使用する方法の詳細については、AWSの[サービスアカウント向けのきめ細かいIAMロールの概要](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/)に関するドキュメントを参照してください。

ロールに対する適切なIRSAアノテーションは、次の2つの方法のいずれかで、このHelm ChartChart>全体のサービスアカウントaccount>に適用できます。

1. 上記のAWSドキュメントで説明されているように、事前に作成されたサービスアカウントaccount>。これにより、サービスアカウントaccount>とリンクされたOIDCプロバイダーに対する適切なアノテーションが保証されます。
1. アノテーションが定義された、チャートによって生成されたサービスアカウントaccount>。アノテーションの設定は、グローバルとチャートごとの両方でサービスアカウントaccount>で許可されています。

Amazon EKSクラスター内のGitLabのサービスアカウントaccount>にIAMロールを使用するには、特定のアノテーションを`eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME>`にする必要があります。

AWS Amazon EKSクラスターで実行されているGitLabのサービスアカウントaccount>にIAMロールを有効にするには、[サービスアカウントのIAMロール](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)の手順に従ってください。

#### 事前に作成されたサービスアカウントaccount>の使用 {#using-pre-created-service-accounts}

GitLabチャートをデプロイするときは、次のオプションを設定します。サービスアカウントaccount>が有効になっているが、作成されていないことに注意することが重要です。

```yaml
global:
  serviceAccount:
    enabled: true
    create: false
    name: <SERVICE ACCT NAME>
```

きめ細かいサービスアカウントaccount>制御も利用可能です。

```yaml
registry:
  serviceAccount:
    create: false
    name: gitlab-registry
gitlab:
  migrations:
    serviceAccount:
      create: false
      name: gitlab-migrations
  webservice:
    serviceAccount:
      create: false
      name: gitlab-webservice
  sidekiq:
    serviceAccount:
      create: false
      name: gitlab-sidekiq
  toolbox:
    serviceAccount:
      create: false
      name: gitlab-toolbox
```

IAMロールの信頼ポリシーが、[これらのKubernetesサービスアカウントaccount>を信頼する](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html)ように設定されていることを確認してください。

#### チャートが所有するサービスアカウントaccount>の使用 {#using-chart-owned-service-accounts}

アノテーション`eks.amazonaws.com/role-arn`は、`global.serviceAccount.annotations`を設定することにより、GitLabが所有するチャートによって作成された_すべて_のサービスアカウントaccount>に適用できます。

```yaml
global:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/name
```

アノテーションはサービスアカウントaccount>ごとに追加することもできますが、各チャートに一致する定義を追加します。これらは同じロール、または個々のロールにすることができます。

```yaml
registry:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab-registry
gitlab:
  migrations:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab
  webservice:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab
  sidekiq:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab
  toolbox:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab-toolbox
```

## トラブルシューティング {#troubleshooting}

IAMロールが正しくセットアップされ、GitLabがIAMロールを使用してS3にアクセスしているかどうかをテストするには、`toolbox`ポッドにログインし、`awscli`を使用します (インストールされているGitLabのネームスペースで`<namespace>`を置き換えます)。

```shell
kubectl exec -ti $(kubectl get pod -n <namespace> -lapp=toolbox -o jsonpath='{.items[0].metadata.name}') -n <namespace> -- bash
```

`awscli`パッケージがインストールされている状態で、AWS APIと通信できることを検証します。

```shell
aws sts get-caller-identity
```

AWS APIへの接続が成功した場合、一時的なユーザーID、アカウント番号、およびIAM ARN (これはS3へのアクセスに使用されるロールのIAM ARNではありません) を示す正常な応答が返されます。接続が失敗した場合、`toolbox`ポッドがAWS APIと通信できない理由を特定するために、より多くのトラブルシューティングが必要になります。

AWS APIへの接続が成功した場合、次のコマンドは作成されたIAMロールを想定し、S3へのアクセス用にSTSトークンを取得できることを検証します。IAMロールのアノテーションがポッドに追加された場合、`AWS_ROLE_ARN`および`AWS_WEB_IDENTITY_TOKEN_FILE`の変数は環境で定義されており、定義する必要はありません。

```shell
aws sts assume-role-with-web-identity --role-arn $AWS_ROLE_ARN  --role-session-name gitlab --web-identity-token file://$AWS_WEB_IDENTITY_TOKEN_FILE
```

IAMロールを想定できなかった場合は、次のようなエラーメッセージが表示されます。

```plaintext
An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

それ以外の場合は、STS認証情報とIAMロールの情報が表示されます。

## `WebIdentityErr: failed to retrieve credentials` {#webidentityerr-failed-to-retrieve-credentials}

ログにこのエラーが表示された場合は、`endpoint`が[`object-storage.yaml`](../../charts/globals.md#connection)シークレットに設定されていることを示唆しています。この設定を削除し、`webservice`および`sidekiq`ポッドを再起動します。
