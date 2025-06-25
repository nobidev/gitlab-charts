---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのGKEリソースの準備
---

{{< details >}}

- プラン:Free, Premium, Ultimate
- 製品:GitLab Self-Managed

{{< /details >}}

完全に機能するGitLabインスタンスの場合、GitLabチャートをデプロイする前に、いくつかのリソースが必要です。以下に、これらのチャートがGitLab内でどのようにデプロイおよびテストされるかを示します。

## GKEクラスターの作成 {#creating-the-gke-cluster}

開始しやすくするために、クラスターの作成を自動化するスクリプトが用意されています。または、クラスターを手動で作成することもできます。

前提要件:

- [前提要件](../tools.md)をインストールします。
- [Google SDK](https://cloud.google.com/sdk/docs/install)をインストールします。

### スクリプト型クラスターの作成 {#scripted-cluster-creation}

[ブートストラップスクリプト](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/gke_bootstrap_script.sh)が作成され、GCP/GKEのユーザー向けにセットアッププロセスの多くを自動化します。

このスクリプトは以下を行います。

1. 新しいGKEクラスターを作成します。
1. クラスターがDNSレコードを変更できるようにします。
1. `kubectl`をセットアップし、クラスターに接続します。

このスクリプトは、環境変数とブートストラップの場合は引数`up`、clean upの場合は`down`からさまざまなパラメータを読み取ります。

下のテーブルにすべての変数の説明があります。

| 変数              | デフォルト値                     | 説明 |
|-----------------------|-----------------------------------|-------------|
| `ADMIN_USER`          | 現在のgcloudユーザー               | セットアップ中にクラスター管理者アクセスを割り当てるユーザー。 |
| `AUTOSCALE_MAX_NODES` | `NUM_NODES`                       | オートスケーラーがスケールアップするノードの最大数。 |
| `AUTOSCALE_MIN_NODES` | `0`                               | オートスケーラーがスケールダウンするノードの最小数。 |
| `CLUSTER_NAME`        | `gitlab-cluster`                  | クラスターの名前。 |
| `CLUSTER_VERSION`     | GKEの[デフォルト](https://cloud.google.com/kubernetes-engine/docs/release-notes)、GKEリリースノートを確認してください | GKEクラスターのバージョン。 |
| `INT_NETWORK`         | デフォルト                           | このクラスター内で使用するIPスペース。 |
| `MACHINE_TYPE`        | `n2d-standard-4`                  | クラスターインスタンスのタイプ。 |
| `NUM_NODES`           | `2`                               | 必要なノード数。 |
| `PREEMPTIBLE`         | `false`                           | より安価なクラスターは*最大*24時間稼働します。ノード/ディスクにSLAはありません。 |
| `PROJECT`             | デフォルトはありません。設定する必要があります。  | GCPプロジェクトのID。 |
| `RBAC_ENABLED`        | `true`                            | クラスターでRBACが有効になっているかどうかを知っている場合は、この変数を設定します。 |
| `REGION`              | `us-central1`                     | クラスターが存在するリージョン。 |
| `SUBNETWORK`          | デフォルト                           | このクラスター内で使用するサブネットワーク。 |
| `USE_STATIC_IP`       | `false`                           | 管理対象DNSを持つ一時的なIPの代わりに、GitLab用の静的IPを作成します。 |
| `ZONE_EXTENSION`      | `b`                               | クラスターインスタンスが存在するゾーン名の拡張子（`a`、`b`、`c`）。 |

スクリプトを実行するには、目的のパラメータを渡します。必須の`PROJECT`を除き、デフォルトのパラメータで動作します。

```shell
PROJECT=<gcloud project id> ./scripts/gke_bootstrap_script.sh up
```

スクリプトを使用して、作成したGKEリソースをクリーンアップすることもできます。

```shell
PROJECT=<gcloud project id> ./scripts/gke_bootstrap_script.sh down
```

クラスターを作成したら、[DNSエントリの作成](#dns-entry)に進みます。

### 手動クラスターの作成 {#manual-cluster-creation}

2つのリソース（Kubernetesクラスターと外部IP）をGCPで作成する必要があります。

#### Kubernetesクラスターの作成 {#creating-the-kubernetes-cluster}

Kubernetesクラスターを手動でプロビジョニングするには、[GKEの手順](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-zonal-cluster)に従ってください。

- 少なくとも2つのノード（それぞれ4vCPUと15GiBのRAM）を持つクラスターをお勧めします。
- クラスターのリージョンをメモしておいてください。次の手順で必要になります。

#### 外部IPの作成 {#creating-the-external-ip}

クラスターが到達可能になるように、外部IPが必要です。外部IPは、リージョンIPであり、クラスター自体と同じリージョン内にある必要があります。グローバルIPまたはクラスターのリージョン外のIPは**機能しません**。

静的IPを実行するには、次のようにします。

`gcloud compute addresses create ${CLUSTER_NAME}-external-ip --region $REGION --project $PROJECT`

新しく作成されたIPのアドレスを取得するには:

`gcloud compute addresses describe ${CLUSTER_NAME}-external-ip --region $REGION --project $PROJECT --format='value(address)'`

次のセクションでは、このIPを使用してDNS名にバインドします。

## DNSエントリ {#dns-entry}

クラスターを手動で作成した場合、またはスクリプトによる作成で`USE_STATIC_IP`オプションを使用した場合は、作成したIPを指すAレコードのワイルドカードDNSエントリを持つパブリックドメインが必要です。

[Google DNSクイックスタートガイド](https://cloud.google.com/dns/docs/set-up-dns-records-domain-name)に従って、DNSエントリを作成します。

## 次のステップ {#next-steps}

クラスターが起動して実行され、静的IPとDNSエントリの準備ができたら、[チャートのインストール](../deployment.md)に進みます。
