---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Mattermost Team EditionでGitLabチャートを設定する
---

このドキュメントでは、既存のGitLab Helmチャートのデプロイ環境に近接してMattermost Team Edition Helm Chartをインストールする方法について説明します。

Mattermost Helm Chartは別のネームスペースにインストールされているため、クラスター全体のIngressと証明書リソースを管理するために、`cert-manager`および`nginx-ingress`を設定することをお勧めします。その他の設定情報については、[Mattermost Helm設定ガイド](https://github.com/mattermost/mattermost-helm/tree/master/charts/mattermost-team-edition#configuration)を参照してください。

## 前提要件 {#prerequisites}

- Kubernetesクラスターが稼働していること。
- [Helm](https://helm.sh/docs/intro/install/) v3

{{< alert type="note" >}}

Teamエディションの場合、実行できるレプリカは1つだけです。

{{< /alert >}}

## Mattermost Team Edition Helm Chartをデプロイする {#deploy-the-mattermost-team-edition-helm-chart}

Mattermost Team Edition Helm Chartをインストールしたら、次のコマンドを使用してデプロイできます。

```shell
helm repo add mattermost https://helm.mattermost.com
helm repo update
helm upgrade --install mattermost -f values.yaml mattermost/mattermost-team-edition
```

ポッドが実行されるまで待ちます。次に、設定で指定したIngressホストを使用して、Mattermostサーバーにアクセスします。

その他の[設定](https://github.com/mattermost/mattermost-helm/tree/master/charts/mattermost-team-edition#configuration)情報については、[Mattermost Helm](https://github.com/mattermost/mattermost-helm/tree/master/charts/mattermost-team-edition#configuration)設定ガイドを参照してください。これについて何か問題が発生した場合は、[Mattermost Helm Chart](https://github.com/mattermost/mattermost-helm/issues) issue repositoryまたは[Mattermost Forum](https://forum.mattermost.com/search?q=helm)を参照してください。

## GitLab Helmチャートをデプロイする {#deploy-gitlab-helm-chart}

[GitLab Helmチャート](../../_index.md)をデプロイするには、こちらに記載されている手順に従ってください。

インストールする簡単な方法は次のとおりです。

```shell
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600s \
  --set global.hosts.domain=<your-domain> \
  --set global.hosts.externalIP=<external-ip> \
  --set certmanager-issuer.email=<email>
```

- `<your-domain>`: 目的のドメイン（`gitlab.example.com`など）。
- `<external-ip>`: Kubernetesクラスターを指す外部IP。
- `<email>`: TLS証明書を取得するために、Let's Encryptにregisterするメール。

[GitLab](../../installation/deployment.md#initial-login)インスタンスをデプロイしたら、最初のログインの手順に従ってください。

## GitLabでOAuthアプリケーションをCreateする {#create-an-oauth-application-with-gitlab}

プロセスの次の部分は、GitLab SSOインテグレーションの設定です。そのためには、Mattermostが[GitLab](https://docs.mattermost.com/deployment/sso-gitlab.html)を認証プロバイダーとして使用できるように、OAuthアプリケーションをCreateする必要があります。

{{< alert type="note" >}}

デフォルトのGitLab SSOのみが正式にサポートされています。「Double SSO」(GitLab SSOが他のSSOソリューションにチェーンされている場合) は、サポートされていません。GitLab SSOをAD、LDAP、SAML、またはMFAアドオンに接続できる場合がありますが、特別なロジックが必要なため、公式にはサポートされておらず、一部のエクスペリエンスでは機能しないことがわかっています。

{{< /alert >}}

## トラブルシューティング {#troubleshooting}

提供されたものとは異なる[プロセス](https://docs.mattermost.com/install/troubleshooting.html?&redirect_source=mm-org)に従っており、認証および/またはデプロイの問題が発生した場合は、Mattermost troubleshooting forumまでお知らせください。
