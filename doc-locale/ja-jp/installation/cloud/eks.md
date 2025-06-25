---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャート用のEKSリソースの準備
---

{{< details >}}

- プラン:Free, Premium, Ultimateプラン
- 提供:GitLab Self-Managed

{{< /details >}}

完全に機能するGitLabインスタンスの場合、GitLabチャートをデプロイする前に、いくつかのリソースが必要です。

## EKSクラスターの作成 {#creating-the-eks-cluster}

より簡単に開始できるように、クラスターの作成を自動化するスクリプトが用意されています。または、クラスターを手動で作成することもできます。

前提要件:

- [前提要件](../tools.md)をインストールします。
- [`eksctl`](https://github.com/weaveworks/eksctl#installation)をインストールします。

クラスターを手動で作成するには、[Amazon AWS Getting started with Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)を参照してください。EKSクラスターにはEC2マネージドノードを使用し、[Fargate](https://docs.aws.amazon.com/en_us/eks/latest/userguide/fargate.html)は使用しないでください。Fargateには多くの制限があり、GitLab Helmチャートでの使用はサポートされていません。

### スクリプト型クラスターの作成 {#scripted-cluster-creation}

[ブートストラップスクリプト](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/eks_bootstrap_script)が作成され、EKSのユーザー向けに設定プロセスの大部分を自動化します。スクリプトを実行する前に、このリポジトリをクローンする必要があります。

スクリプトは以下を行います。

1. 新しいEKSクラスターを作成します。
1. `kubectl`をセットアップし、クラスターに接続します。

認証するために、`eksctl`はAWSコマンドラインと同じオプションを使用します。[環境変数](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html)、または[設定ファイル](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)の使用方法については、AWSドキュメントを参照してください。

スクリプトは、環境変数、またはコマンドライン引数、およびブートストラップの場合は`up`、clean upの場合は`down`の引数からさまざまなパラメータを読み込みます。

以下のテーブルは、すべての変数を記述しています。

| 変数          | デフォルト値    | 説明 |
|-------------------|------------------|-------------|
| `REGION`          | `us-east-2`      | クラスターが存在するリージョン |
| `CLUSTER_NAME`    | `gitlab-cluster` | クラスターの名前 |
| `CLUSTER_VERSION` | `1.29`           | EKSクラスターのバージョン |
| `NUM_NODES`       | `2`              | 必要なノード数 |
| `MACHINE_TYPE`    | `m5.xlarge`      | デプロイするノードのタイプ |

目的のパラメータを渡して、スクリプトを実行します。デフォルトのパラメータで動作します。

```shell
./scripts/eks_bootstrap_script up
```

スクリプトは、作成されたEKSリソースのクリーンアップにも使用できます。

```shell
./scripts/eks_bootstrap_script down
```

### 手動クラスターの作成 {#manual-cluster-creation}

- 8vCPUおよび30GiBのRAMを備えたクラスターをお勧めします。

最新の手順については、Amazonの[EKSの開始方法ガイド](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)に従ってください。

管理者は、このプロセスを簡素化するために[Kubernetes用の新しいAWS Service Operator](https://aws.amazon.com/blogs/opensource/aws-service-operator-kubernetes-available/)を検討することもできます。

{{< alert type="note" >}}

AWS Service Operatorを有効にするには、クラスター内でロールを管理する方法が必要です。その管理タスクを処理する初期サービスは、サードパーティのデベロッパーによって提供されます。管理者は、デプロイを計画する際に、そのことを念頭に置いておく必要があります。

{{< /alert >}}

## 永続ボリュームの管理 {#persistent-volume-management}

Kubernetesでボリューム要求を管理するには、次の2つの方法があります。

- 永続ボリュームを手動で作成します。
- 動的プロビジョニングによる自動永続ボリュームの作成。

現在、永続ボリュームの手動プロビジョニングを使用することをお勧めします。Amazon EKSクラスターはデフォルトで複数のゾーンにまたがっています。特定のゾーンにロックされたストレージクラスを使用するように構成されていない場合、動的プロビジョニングは、ポッドがストレージボリュームとは異なるゾーンに存在し、データにアクセスできなくなるシナリオにつながる可能性があります。詳細については、[永続ボリュームをプロビジョニング](../storage.md)する方法を参照してください。

Amazon EKS 1.23以降のクラスターでは、手動プロビジョニングと動的プロビジョニングのどちらの場合でも、クラスターに[Amazon EBS CSIアドオン](https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html#adding-ebs-csi-eks-add-on)をインストールする必要があります。

```shell
eksctl utils associate-iam-oidc-provider --cluster **CLUSTER_NAME** --approve

eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster **CLUSTER_NAME** \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve \
    --role-only \
    --role-name *ROLE_NAME*

eksctl create addon --name aws-ebs-csi-driver --cluster **CLUSTER_NAME** --service-account-role-arn arn:aws:iam::*AWS_ACCOUNT_ID*:role/*ROLE_NAME* --force

kubectl annotate serviceaccount ebs-csi-controller-sa -n kube-system eks.amazonaws.com/role-arn=arn:aws:iam::*AWS_ACCOUNT_ID*:role/*ROLE_NAME*
```

## GitLabへの外部アクセス {#external-access-to-gitlab}

デフォルトでは、GitLabチャートをインストールすると、関連付けられたElastic Load Balancer（ELB）を作成するIngressがデプロイされます。ELBのDNS名は事前に不明であるため、[Let's Encrypt](https://letsencrypt.org/)を利用してHTTPS証明書を自動的にプロビジョニングすることは困難です。

[独自の証明書を使用](../tls.md#option-2-use-your-own-wildcard-certificate)し、CNAMEレコードを使用して、目的のDNS名を作成されたELBにマップすることをお勧めします。ホスト名を取得する前にELBを最初に作成する必要があるため、次の手順に従ってGitLabをインストールしてください。

{{< alert type="note" >}}

AWS Load Balancerが必要な環境では、[AmazonのElastic Load Balancer](https://docs.aws.amazon.com/eks/latest/userguide/load-balancing.html)には特別な設定が必要です。[クラウドプロバイダーのロードバランサー](../../charts/globals.md#cloud-provider-loadbalancers)を参照してください

{{< /alert >}}

## 次のステップ {#next-steps}

クラスターが起動して実行されたら、[チャートのインストール](../deployment.md)を続行します。`global.hosts.domain`オプションを使用してドメイン名を設定しますが、既存のElastic IPを使用する予定がない限り、`global.hosts.externalIP`オプションを使用して静的IP設定を省略します。

Helmのインストール後、次のコマンドを使用して、ELBのホスト名を取得し、CNAMEレコードに配置できます。

```shell
kubectl get ingress/RELEASE-webservice-default -ojsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

`RELEASE`は、`helm install <RELEASE>`で使用されているリリース名に置き換える必要があります。
