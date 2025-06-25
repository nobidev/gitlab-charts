---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのストレージを設定
---

{{< details >}}

- プラン:Free、Premium、Ultimateプラン
- 提供:GitLab Self-Managed

{{< /details >}}

GitLabチャート内の以下のアプリケーションは、状態を保持するために永続ストレージを必要とします。

- [Gitaly](../charts/gitlab/gitaly/_index.md) (Gitリポジトリを永続化)
- [PostgreSQL](https://github.com/bitnami/charts/tree/main/bitnami/postgresql) (GitLabデータベースデータを永続化)
- [Redis](https://github.com/bitnami/charts/tree/main/bitnami/redis) (GitLabジョブデータを永続化)
- [MinIO](../charts/minio/_index.md) (オブジェクトストレージデータを永続化)

管理者は、[動的](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic)または[静的](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#static)ボリューム[プロビジョニング](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#static)を使用して、このストレージを[プロビジョニング](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#static)できます。

> **重要**:事前計画により、インストール後の追加ストレージ移行タスクを最小限に抑える。最初のデプロイ後に加えられた変更では、`helm upgrade`を実行する前に、既存のKubernetesオブジェクトを手動で編集する必要があります。

## 一般的なインストール動作 {#typical-installation-behavior}

インストーラーは、[デフォルト](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic)のストレージクラスと[動的ボリュームプロビジョニング](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic)を使用してストレージを作成します。アプリケーションは、[Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)を通じてこのストレージに接続します。管理者は、利用可能な場合は[静的ボリュームプロビジョニング](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic)の代わりに[動的ボリュームプロビジョニング](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#static)を使用することをお勧めします。

> 管理者は、`kubectl get storageclass`を使用して本番環境のデフォルトのストレージクラスを特定し、`kubectl describe storageclass *STORAGE_CLASS_NAME*`を使用して調べます。Amazon EKSなど、一部のプロバイダーはデフォルトのストレージクラスを提供していません。

## クラスター・ストレージの設定 {#configuring-cluster-storage}

### 推奨事項 {#recommendations}

デフォルトのストレージクラスは以下である必要があります。

- 利用可能な場合は、高速SSDストレージを使用する
- `reclaimPolicy`を`Retain`に設定

> `reclaimPolicy`が`Retain`に設定されていない状態でGitLabをアンインストールすると、自動化されたジョブがボリューム、ディスク、データを完全に削除できます。一部のプラットフォームでは、`reclaimPolicy`のデフォルトを`Delete`に設定しています。`gitaly`永続ボリュームクレームは、[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)に属しているため、このルールに従いません。

### 最小限のストレージクラスの構成 {#minimal-storage-class-configurations}

次の`YAML`構成は、GitLabのカスタムストレージクラスを作成するために必要な最小限の要件を提供します。`CUSTOM_STORAGE_CLASS_NAME`を、ターゲットインストール環境に合った値に置き換えます。

- [Google Cloud](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gke_storage_class.yml)上のGKEの[サンプル](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gke_storage_class.yml)ストレージクラス
- [Amazon Web Services](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/eks_storage_class.yml)上のEKSの[サンプル](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/eks_storage_class.yml)ストレージクラス

> Amazon EKSでは、ノードの作成が常にポッドと同じゾーン内にあるとは限らないという動作が確認されています。上記の***zone***パラメータを設定すると、リスクが*緩和*されます。

### カスタムストレージクラスの使用 {#using-the-custom-storage-class}

カスタムストレージクラスをクラスターデフォルトに設定すると、すべての動的プロビジョニングに使用されます。

```shell
kubectl patch storageclass CUSTOM_STORAGE_CLASS_NAME -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

または、インストールの際に、カスタムストレージクラスとその他のオプションをサービスごとにHelmに提供できます。提供されている[設定ファイル](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/helm_options.yml)を表示し、ご使用の[環境](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/helm_options.yml)に合わせて変更してください。

```shell
helm install -upgrade gitlab gitlab/gitlab -f HELM_OPTIONS_YAML_FILE
```

詳細な情報と追加の永続オプションについては、以下のリンクを参照してください。

- [Gitaly](../charts/gitlab/gitaly/_index.md#git-repository-persistence) [永続](../charts/gitlab/gitaly/_index.md#git-repository-persistence)設定
- [MinIO](../charts/minio/_index.md#persistence) [永続](../charts/minio/_index.md#persistence)設定
- [Redis](https://github.com/bitnami/charts/tree/main/bitnami/redis#persistence) [永続](https://github.com/bitnami/charts/tree/main/bitnami/redis#persistence)設定
- [アップストリーム](https://github.com/bitnami/charts/tree/main/bitnami/postgresql#configuration-and-installation-details)PostgreSQLチャート設定

> **メモ**:高度な永続オプションの一部は、PostgreSQLとその他とで異なるため、変更を行う前に、それぞれのドキュメントを確認することが重要です。

## 静的ボリュームプロビジョニングの使用 {#using-static-volume-provisioning}

動的ボリュームプロビジョニングが推奨されますが、一部のクラスターまたは環境ではサポートされていない場合があります。管理者は、[Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)を手動で作成する必要があります。

### Google GKEの使用 {#using-google-gke}

1. クラスター内に[永続](https://kubernetes.io/docs/concepts/storage/volumes/#creating-a-pd)ディスクを作成します。

```shell
gcloud compute disks create --size=50GB --zone=*GKE_ZONE* *DISK_VOLUME_NAME*
```

1. [サンプル`YAML`設定](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gke_pv_example.yml)を変更したら、[Persistent Volume](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gke_pv_example.yml)を作成します。

```shell
kubectl create -f *PV_YAML_FILE*
```

### Amazon EKSの使用 {#using-amazon-eks}

{{< alert type="note" >}}

複数の[ゾーン](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)に[デプロイ](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)する[必要](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)がある[場合](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)は、ストレージソリューションを定義する[際](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)に、[Amazon](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)独自のストレージクラスに関する[ドキュメント](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)を[レビュー](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)する[必要](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)があります。

{{< /alert >}}

1. クラスター内に[永続](https://kubernetes.io/docs/concepts/storage/volumes/#creating-an-ebs-volume)ディスクを作成します。

```shell
aws ec2 create-volume --availability-zone=*AWS_ZONE* --size=10 --volume-type=gp2
```

1. [サンプル`YAML`設定](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/eks_pv_example.yml)を変更したら、[Persistent Volume](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/eks_pv_example.yml)を作成します。

```shell
kubectl create -f *PV_YAML_FILE*
```

### PersistentVolumeClaimの手動作成 {#manually-creating-persistentvolumeclaims}

[Gitaly](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)サービスは、[StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)を使用して[デプロイ](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)します。[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)は、正しく認識されて使用されるように、次の命名規則を使用して作成します。

```plaintext
<mount-name>-<statefulset-pod-name>
```

Gitalyの`mount-name`は`repo-data`です。StatefulSetポッド名は、以下を使用して作成されます。

```plaintext
<statefulset-name>-<pod-index>
```

GitLabチャートは、以下を使用して`statefulset-name`を決定します。

```plaintext
<chart-release-name>-<service-name>
```

Gitaly PersistentVolumeClaimの正しい名前は、`repo-data-gitlab-gitaly-0`です。

> **メモ**:複数の仮想ストレージでPraefectを使用する場合、定義された仮想ストレージごとに、Gitalyレプリカごとに1つのPersistentVolumeClaimが必要になります。例えば、`default`および`vs2`仮想ストレージが定義されていて、それぞれに2つのレプリカがある場合、次のPersistentVolumeClaimが必要です。
>
> - `repo-data-gitlab-gitaly-default-0`
> - `repo-data-gitlab-gitaly-default-1`
> - `repo-data-gitlab-gitaly-vs2-0`
> - `repo-data-gitlab-gitaly-vs2-1`

ご使用の[環境](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gitaly_persistent_volume_claim.yml)に合わせて[サンプル](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gitaly_persistent_volume_claim.yml) [YAML](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gitaly_persistent_volume_claim.yml)設定を修正し、`helm`を[実行する](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gitaly_persistent_volume_claim.yml)際に参照してください。

> [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)を使用しないその他のサービスでは、管理者は`volumeName`を[設定](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)に提供できます。このチャートは、[ボリューム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)クレームの作成を引き続き行い、手動で作成されたボリュームへのバインドを試みます。含まれる各アプリケーションについて、チャートのドキュメントを確認してください。
>
> [ほとんど](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/use_manual_volumes.yml)の[場合](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/use_manual_volumes.yml)、手動で作成されたディスクボリュームを使用するサービスのみを保持して、[サンプル](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/use_manual_volumes.yml)YAML設定

## インストール後にストレージを変更する {#making-changes-to-storage-after-installation}

初期インストール後、新しいボリュームへの移行、ディスクサイズの変更などのストレージ変更では、Helmアップグレードコマンドの外部でKubernetesオブジェクトを編集する必要があります。

[永続ボリュームドキュメント](../advanced/persistent-volumes/_index.md)の管理

## オプションのボリューム {#optional-volumes}

大規模なインストールでは、バックアップ/リストアを機能させるために、Toolboxに永続ストレージを追加する必要がある場合があります。これを行う[方法](../backup-restore/_index.md#pod-eviction-issues)については、[トラブルシューティングドキュメント](../backup-restore/_index.md#pod-eviction-issues)を参照してください。
