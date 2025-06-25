---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのRBACの設定
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

Kubernetes 1.7までは、クラスター内に権限がありませんでした。1.7のリリースにより、クラスター内でサービスが実行できる[RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)（ロールベースのアクセス制御）システムが導入されました。

RBACは、GitLabのいくつかの異なる側面に影響を与えます。

- Helmを使用したGitLabのインストール
- Prometheusモニタリング
- GitLab Runner
- クラスター内PostgreSQLデータベース (RBACが有効な場合)
- 証明書マネージャー

## RBACが有効になっていることの確認 {#checking-that-rbac-is-enabled}

現在のクラスターロールをリストしてみてください。失敗した場合は、`RBAC`が無効になっています

このコマンドは、`RBAC`が無効の場合は`false`を、それ以外の場合は`true`を出力します

`kubectl get clusterroles > /dev/null 2>&1 && echo true || echo false`

## サービスアカウント {#service-accounts}

GitLabチャートは、サービスアカウントを使用して特定のタスクを実行します。これらのアカウントとそれに関連付けられたロールは、チャートによって作成および管理されます。

サービスアカウントについては、次のテーブルで説明します。各サービスアカウントについて、テーブルには以下が示されています。

- 名前のサフィックス (プレフィックスはリリースの名前)。
- 簡単な説明。たとえば、どこで使用されているか、何に使用されているか。
- 関連付けられたロールと、どのリソースに対するアクセスレベル。アクセスレベルは、読み取り専用 (R)、書き込み専用 (W)、または読み取り/書き込み (RW) のいずれかです。リソースのグループ名が省略されていることに注意してください。
- ロールのスコープ。クラスター (C) またはネームスペース (NS) のいずれかです。インスタンスによっては、ロールのスコープはいずれかの値で構成できます (NS/Cで示されます)

| 名前のサフィックス | 説明 | ロール | スコープ
| ---         | ---         | ---   | ---
| `gitlab-runner` | GitLab Runnerは、このアカウントで実行されます。 | 任意のリソース (RW) | NS/C
| `ingress-nginx` | NGINX Ingressによって使用され、サービスのエンドポイントへのアクセスを制御します。 | シークレット、Pod、エンドポイント、Ingress (R)、イベント (W)、ConfigMap、サービス (RW) | NS/C
| `shared-secrets` | 共有シークレットを作成するジョブは、このアカウントで実行されます。(インストール前/アップグレードのフック時) | シークレット(RW) | NS
| `cert-manager` | 証明書マネージャーを制御するジョブは、このアカウントで実行されます。 | Issuer、Certificate、CertificateRequest、Order (RW)  | NS/C

GitLabチャートは、RBACを使用し、独自のサービスアカウントとロールバインディングを作成する他のチャートに依存しています。概要を以下に示します。

- Prometheusモニタリングは、デフォルトで複数の独自のサービスアカウントを作成します。これらはすべて、クラスターレベルのロールに関連付けられています。詳細については、[Prometheusチャートのドキュメント](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#rbac-configuration)を参照してください。
- 証明書マネージャーは、カスタムリソースとネイティブリソースをクラスターレベルで管理するために、デフォルトでサービスアカウントを作成します。詳細については、[cert-managerチャートRBACテンプレート](https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/templates/rbac.yaml)を参照してください。
- クラスター内PostgreSQLデータベースを使用する場合 (これはデフォルトです)、サービスアカウントは有効になりません。有効にすることはできますが、PostgreSQLサービスの実行にのみ使用され、特定のロールに関連付けられていません。詳細については、[PostgreSQLチャート](https://github.com/bitnami/charts/tree/main/bitnami/postgresql)を参照してください。
