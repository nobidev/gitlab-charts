---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GKEまたはEKSでのGitLabチャートのテスト
---

このガイドは、Google Kubernetes Engine（GKE）またはAmazon Elastic Kubernetes Service（Amazon EKS）にデフォルト値でGitLabチャートをインストールする方法に関する、簡潔かつ完全なドキュメントとして提供することを目的としています。

デフォルトでは、GitLabチャートには、クラスター内PostgreSQL、Redis、およびMinIOのデプロイメントが含まれています。これらは**トライアル**目的のみを対象としており、**本番環境**での使用は推奨されません。これらのチャートを継続的な負荷がかかる本番環境にデプロイする場合は、完全な[インストールガイド](../installation/_index.md)に従ってください。

## 前提要件 {#prerequisites}

このガイドを完了するには、以下が必要です。

- DNSレコードを追加できる、お客様が所有するドメイン。
- Kubernetesクラスター。
- `kubectl`の動作するインストール。
- 動作するHelm v3のインストール。

### 利用可能なドメイン {#available-domain}

DNSレコードを追加できる、インターネットからアクセス可能なドメインにアクセスできる必要があります。これは`poc.domain.com`などのサブドメインにすることができますが、Let's Encryptサーバーは、証明書を発行するためにアドレスを解決できる必要があります。

### KubernetesクラスターのCreate {#create-a-kubernetes-cluster}

合計で少なくとも8つの仮想CPUと30 GiBのRAMを備えたクラスターをお勧めします。

Kubernetes[クラスター](../installation/cloud/_index.md)の作成方法については、[クラウドプロバイダー](../installation/cloud/_index.md)の手順を参照するか、GitLab提供のスクリプトを使用して[クラスター](../installation/cloud/_index.md)の作成を自動化できます。

{{< alert type="warning" >}}

Kubernetesノードは、x86-64アーキテクチャを使用する必要があります。AArch64/ARM64を含む複数のアーキテクチャのサポートは、積極的に開発中です。詳細については、[イシュー2899](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2899)を参照してください。

{{< /alert >}}

### kubectlのインストール {#install-kubectl}

[kubectl](https://kubernetes.io/docs/tasks/tools/)をインストールするには、[Kubernetes](https://kubernetes.io/docs/tasks/tools/)インストールに関するドキュメントを参照してください。このドキュメントでは、ほとんどのオペレーティングシステムとGoogle Cloud SDKについて説明しています。これらは、前の手順でインストールした可能性があります。

[クラスター](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#generate_kubeconfig_entry)を作成したら、`kubectl`を[設定](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#generate_kubeconfig_entry)して、[コマンドライン](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#generate_kubeconfig_entry)から[クラスター](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#generate_kubeconfig_entry)とやり取りできるようにする必要があります。

### Helmのインストール {#install-helm}

このガイドでは、Helm v3の最新リリース（v3.9.4以降）を使用します。Helmをインストールするには、[Helm](https://helm.sh/docs/intro/install/)インストールに関するドキュメントを参照してください。

## GitLab Helmリポジトリの追加 {#add-the-gitlab-helm-repository}

GitLab Helmリポジトリを`helm`の設定に追加します。

```shell
helm repo add gitlab https://charts.gitlab.io/
```

## GitLabのインストール {#install-gitlab}

このチャートが提供できるものの素晴らしさをご紹介します。1つのコマンド。はい、どうぞ。すべてインストールされ、SSLで設定されたGitLab。

チャートを設定するには、以下が必要です。

- GitLabが動作するドメインまたはサブドメイン。
- お客様のメールアドレス。これにより、Let's Encryptが証明書を発行できます。

チャートをインストールするには、2つの`--set`引数を使用してインストールコマンドを実行します。

```shell
helm install gitlab gitlab/gitlab \
  --set global.hosts.domain=DOMAIN \
  --set certmanager-issuer.email=me@example.com
```

この手順では、すべてのリソースの割り当て、サービスの起動、およびアクセスが利用可能になるまでに数分かかる場合があります。

完了したら、インストールされているNGINX Ingressに動的に割り当てられたIPアドレスのフェッチに進むことができます。

## IPアドレスのRetrieve {#retrieve-the-ip-address}

`kubectl`を使用して、インストールおよび設定したNGINX IngressにGKEによって動的に割り当てられたアドレスを、GitLabチャートの一部としてフェッチできます。

```shell
kubectl get ingress -lrelease=gitlab
```

出力は次のようになります。

```plaintext
NAME               HOSTS                 ADDRESS         PORTS     AGE
gitlab-minio       minio.domain.tld      35.239.27.235   80, 443   118m
gitlab-registry    registry.domain.tld   35.239.27.235   80, 443   118m
gitlab-webservice  gitlab.domain.tld     35.239.27.235   80, 443   118m
```

3つのエントリがあり、すべて同じIPアドレスであることがわかります。このIPアドレスを取得し、使用することを選択したドメインのDNSに追加します。タイプ`A`のレコードを複数追加できますが、簡単にするために、単一の「ワイルドカード」レコードをお勧めします。

- Google Cloud DNSで、名前`*`の`A`レコードをCreateします。また、TTLを`1`分ではなく、`5`分に設定することをお勧めします。
- AWS EKSでは、アドレスはIPアドレスではなくURLになります。[Route 53エイリアスレコードを作成](https://repost.aws/knowledge-center/route-53-create-alias-records) `*.domain.tld`このURLを指します。

## GitLabへのSign in {#sign-in-to-gitlab}

`gitlab.domain.tld`でGitLabにアクセスできます。たとえば、`global.hosts.domain=my.domain.tld`を設定した場合は、`gitlab.my.domain.tld`にアクセスします。

サインインするには、`root`ユーザーのパスワードを収集する必要があります。これはインストール時に自動的に生成され、Kubernetesシークレットに保存されます。シークレットからそのパスワードをフェッチしてデコードしましょう。

```shell
kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

これで、ユーザー名`root`と取得したパスワードを使用してGitLabにサインインできます。ログイン後、ユーザー設定からこのパスワードを変更できます。これは、お客様に代わって最初のログインをSecureにできるようにするためにのみ生成するものです。

## トラブルシューティング {#troubleshooting}

このガイドで問題が発生した場合は、動作していることを確認する必要のある、可能性の高い項目を次に示します。

1. `gitlab.my.domain.tld`は、取得したIngressのIPアドレスに解決されます。
1. 証明書の警告が表示された場合は、Let's Encryptに問題が発生しています。通常はDNS、または再試行の要件に関連しています。

その他の[トラブルシューティング](../troubleshooting/_index.md)のヒントについては、[トラブルシューティング](../troubleshooting/_index.md)ガイドを参照してください。

### Helmインストールが`roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden` {#helm-install-returns-rolesrbacauthorizationk8sio-gitlab-shared-secrets-is-forbidden}を返します

実行後:

```shell
helm install gitlab gitlab/gitlab  \
  --set global.hosts.domain=DOMAIN \
  --set certmanager-issuer.email=user@example.com
```

次のようなエラーが表示されることがあります。

```shell
Error: failed pre-install: warning: Hook pre-install templates/shared-secrets-rbac-config.yaml failed: roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden: user "some-user@some-domain.com" (groups=["system:authenticated"]) is attempting to grant RBAC permissions not currently held:
{APIGroups:[""], Resources:["secrets"], Verbs:["get" "list" "create" "patch"]}
```

これは、クラスターへの接続に使用している`kubectl`コンテキストに、[RBAC](../installation/rbac.md)リソースを作成するために必要な権限がないことを意味します。
