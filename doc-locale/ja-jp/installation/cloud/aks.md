---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャート用のAKSリソースの準備
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

完全に機能するGitLabインスタンスの場合、[Azure Kubernetes Service（AKS）](https://learn.microsoft.com/en-us/azure/aks/what-is-aks)にGitLabチャートをデプロイする前に、いくつかのリソースが必要です。

## AKSクラスターの作成 {#creating-the-aks-cluster}

より簡単に開始できるように、クラスターの作成を自動化するスクリプトが用意されています。または、クラスターを手動で作成することもできます。

前提要件:

- [前提要件](../tools.md)をインストールします。
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)をインストールし、それを使用して[Azureにサインイン](https://learn.microsoft.com/en-us/cli/azure/get-started-with-azure-cli#how-to-sign-into-the-azure-cli)します。
- [`jq`をインストールします](https://stedolan.github.io/jq/download/)。

### スクリプト型クラスターの作成 {#scripted-cluster-creation}

[ブートストラップスクリプト](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/aks_bootstrap_script.sh)が作成され、Azureでのユーザーのセットアッププロセスの多くを自動化します。

環境変数またはコマンドライン引数から追加のオプションパラメータを指定して、`up`、`down`、または`creds`の引数を読み取ります。

- クラスターを作成するには:

  ```shell
  ./scripts/aks_bootstrap_script.sh up
  ```

  これは次のようになります:

  1. 新しいリソース グループを作成します (オプション)。
  1. 新しいAKSクラスターを作成します。
  1. 新しいパブリックIPを作成します（オプション）。

- 作成されたAKSリソースをcleanするには:

  ```shell
  ./scripts/aks_bootstrap_script.sh down
  ```

  これは次のようになります:

  1. 指定されたリソース グループを削除します (オプション)。
  1. AKSクラスターを削除します。
  1. クラスターによって作成されたリソース グループを削除します。

  `down`引数は、すべてのリソースを削除して即座に終了するコマンドを送信します。実際の削除が完了するまでに数分かかる場合があります。

- `kubectl`をクラスターに接続するには:

  ```shell
  ./scripts/aks_bootstrap_script.sh creds
  ```

次のテーブルでは、使用可能なすべての変数を説明します。

| 変数                  | デフォルト値      | スコープ   | 説明 |
|---------------------------|--------------------|---------|-------------|
| `-g --resource-group`     | `gitlab-resources` | すべて     | 使用するリソース グループの名前。 |
| `-n --cluster-name`       | `gitlab-cluster`   | すべて     | 使用するクラスターの名前。 |
| `-r --region`             | `eastus`           | `up`    | クラスターをインストールするリージョン。 |
| `-v --cluster-version`    | 最新             | `up`    | クラスターの作成に使用するKubernetesのバージョン。 |
| `-c --node-count`         | `2`                | `up`    | 使用するノードの数。 |
| `-s --node-vm-size`       | `Standard_D4s_v3`  | `up`    | 使用するノードのタイプ。 |
| `-p --public-ip-name`     | `gitlab-ext-ip`    | `up`    | 作成するパブリックIPの名前。 |
| `--create-resource-group` | `false`            | `up`    | 作成されたすべてのリソースを保持する新しいリソース グループを作成します。 |
| `--create-public-ip`      | `false`            | `up`    | 新しいクラスターで使用するパブリックIPを作成します。 |
| `--delete-resource-group` | `false`            | `down`  | downコマンドを使用するときにリソース グループを削除します。 |
| `-f --kubctl-config-file` | `~/.kube/config`   | `creds` | 更新するKubernetes設定ファイル。代わりに、`-`を使用してYAMLを`stdout`に出力します。 |

### 手動クラスターの作成 {#manual-cluster-creation}

8vCPUと30GBのRAMを備えたクラスターをお勧めします。

最新の手順については、Microsoftの[AKSのチュートリアル](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-portal)に従ってください。

## GitLabへの外部アクセス {#external-access-to-gitlab}

クラスターが到達可能になるように、外部IPが必要です。最新の手順については、Microsoftの[静的IPアドレスの作成](https://learn.microsoft.com/en-us/azure/aks/static-ip)ガイドに従ってください。

## 次の手順 {#next-steps}

クラスターが稼働状態になり、静的IPとDNSエントリの準備ができたら、[チャートのインストール](../deployment.md)に進みます。
