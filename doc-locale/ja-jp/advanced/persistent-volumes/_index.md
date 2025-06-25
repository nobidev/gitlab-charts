---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 永続ボリュームでGitLabチャートを設定する
---

含まれているサービスの一部では、クラスターがアクセスできるディスクを指定する[永続ボリューム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)を介して設定された永続ストレージが必要です。このチャートのインストールに必要なストレージ[設定](../../installation/storage.md)に関するドキュメントは、[ストレージガイド](../../installation/storage.md)にあります。

インストール後のストレージの変更は、クラスターの管理者によって手動で処理する必要があります。インストール後のこれらのボリュームの自動管理は、GitLabチャートでは処理されません。

最初のインストール後に自動的に管理されない変更の例を以下に示します。

- ポッドへの異なるボリュームのマウント
- 有効なaccessModesまたは[Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/)の変更
- ボリューム*<sup>1</sup>のストレージサイズの展開

<sup>1</sup> Kubernetes 1.11では、`allowVolumeExpansion`が[Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/)でtrueに設定されている場合、[ボリュームのストレージサイズの展開がサポートされます](https://kubernetes.io/blog/2018/07/12/resizing-persistent-volumes-using-kubernetes/)。

これらの変更の自動化は、次の理由により複雑になります。

1. Kubernetesでは、既存の[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)のほとんどのフィールドへの変更は許可されていません
1. [手動で設定](../../installation/storage.md)されていない限り、[PVC](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)は、動的にプロビジョニングされた[PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)への唯一の参照です
1. `Delete`は、動的にプロビジョニングされた[PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)のデフォルトの[reclaimPolicy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy)です

つまり、変更を行うには、[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)を削除し、変更を加えて新しいものを作成する必要があります。ただし、デフォルトの[reclaimPolicy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy)により、[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)を削除すると、[PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)と基盤となるディスクが削除される可能性があります。また、適切なvolumeNamesやlabelSelectorsで設定されていない限り、チャートはアタッチするボリュームを認識しません。

このプロセスをより簡単にする方法を引き続き検討していきますが、今のところ、ストレージを変更するには手動プロセスに従う必要があります。

## GitLabボリュームの特定 {#locate-the-gitlab-volumes}

使用されているボリューム/クレームを見つけます:

```shell
kubectl --namespace <namespace> get PersistentVolumeClaims -l release=<chart release name> -ojsonpath='{range .items[*]}{.spec.volumeName}{"\t"}{.metadata.labels.app}{"\n"}{end}'
```

- `<namespace>`は、GitLabチャートをインストールしたネームスペースに置き換える必要があります。
- `<chart release name>`は、GitLabチャートのインストールに使用した名前に置き換える必要があります。

このコマンドは、ボリューム名のリストと、それらが対象とするサービスの名前を出力します。

次に例を示します。

```shell
$ kubectl --namespace helm-charts-win get PersistentVolumeClaims -l release=review-update-app-h8qogp -ojsonpath='{range .items[*]}{.spec.volumeName}{"\t"}{.metadata.labels.app}{"\n"}{end}'
pvc-6247502b-8c2d-11e8-8267-42010a9a0113  gitaly
pvc-61bbc05e-8c2d-11e8-8267-42010a9a0113  minio
pvc-61bc6069-8c2d-11e8-8267-42010a9a0113  postgresql
pvc-61bcd6d2-8c2d-11e8-8267-42010a9a0113  prometheus
pvc-61bdf136-8c2d-11e8-8267-42010a9a0113  redis
```

## ストレージを変更する前に {#before-making-storage-changes}

変更を行う担当者は、クラスターへの管理者アクセス権と、使用されているストレージソリューションへの適切なアクセス権を持っている必要があります。多くの場合、変更はまずストレージソリューションで適用する必要があり、次に結果をKubernetesで更新する必要があります。

変更を行う前に、[PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)が`Retain` [reclaimPolicy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy)を使用していることを確認して、変更中に削除されないようにする必要があります。

まず、[使用されているボリューム/クレームを見つけます](#locate-the-gitlab-volumes)。

次に、各ボリュームを編集し、`spec`フィールドの`persistentVolumeReclaimPolicy`の値を、`Delete`ではなく`Retain`に変更します

次に例を示します。

```shell
kubectl --namespace helm-charts-win edit PersistentVolume pvc-6247502b-8c2d-11e8-8267-42010a9a0113
```

出力の編集:

```yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    kubernetes.io/createdby: gce-pd-dynamic-provisioner
    pv.kubernetes.io/bound-by-controller: "yes"
    pv.kubernetes.io/provisioned-by: kubernetes.io/gce-pd
  creationTimestamp: 2018-07-20T14:58:43Z
  labels:
    failure-domain.beta.kubernetes.io/region: europe-west2
    failure-domain.beta.kubernetes.io/zone: europe-west2-b
  name: pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  resourceVersion: "48362431"
  selfLink: /api/v1/persistentvolumes/pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  uid: 650bd649-8c2d-11e8-8267-42010a9a0113
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 50Gi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: repo-data-review-update-app-h8qogp-gitaly-0
    namespace: helm-charts-win
    resourceVersion: "48362307"
    uid: 6247502b-8c2d-11e8-8267-42010a9a0113
  gcePersistentDisk:
    fsType: ext4
    pdName: gke-cloud-native-81a17-pvc-6247502b-8c2d-11e8-8267-42010a9a0113
# Changed the following line
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
status:
  phase: Bound
```

## ストレージの変更 {#making-storage-changes}

まず、クラスターの外部でディスクに必要な変更を加えます。(GKEでディスクのサイズを変更するか、スナップショットまたはクローンなどから新しいディスクを作成します)。

これを行う方法、およびダウンタイムなしでライブで実行できるかどうかは、使用しているストレージソリューションによって異なり、このドキュメントでは説明できません。

次に、これらの変更をKubernetesオブジェクトに反映させる必要があるかどうかを評価します。たとえば、ディスクストレージサイズを展開する場合、[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)のストレージサイズ[設定](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)は、新しいボリュームリソースがリクエストされた場合にのみ使用されます。したがって、(追加のGitalyポッドで使用するために) より多くのディスクをスケールアップする場合は、[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)の値を増やすだけで済みます。

Kubernetesに変更を反映させる必要がある場合は、[ストレージを変更する前に](#before-making-storage-changes)セクションで説明されているように、ボリュームのリクレイムポリシーを更新したことを確認してください。

ストレージの変更に関してドキュメント化されているパスは次のとおりです。

- [既存のボリュームへの変更](#changes-to-an-existing-volume)
- [別のボリュームへの切り替え](#switching-to-a-different-volume)

### 既存のボリュームへの変更 {#changes-to-an-existing-volume}

まず、変更する[ボリューム名](#locate-the-gitlab-volumes)を特定します。

`kubectl edit`を使用して、ボリュームに必要な設定の変更を加えます。(これらの変更は、アタッチされたディスクの実際の状態を反映するための更新のみである必要があります)

次に例を示します。

```shell
kubectl --namespace helm-charts-win edit PersistentVolume pvc-6247502b-8c2d-11e8-8267-42010a9a0113
```

出力の編集:

```yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    kubernetes.io/createdby: gce-pd-dynamic-provisioner
    pv.kubernetes.io/bound-by-controller: "yes"
    pv.kubernetes.io/provisioned-by: kubernetes.io/gce-pd
  creationTimestamp: 2018-07-20T14:58:43Z
  labels:
    failure-domain.beta.kubernetes.io/region: europe-west2
    failure-domain.beta.kubernetes.io/zone: europe-west2-b
  name: pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  resourceVersion: "48362431"
  selfLink: /api/v1/persistentvolumes/pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  uid: 650bd649-8c2d-11e8-8267-42010a9a0113
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    # Updated the storage size
    storage: 100Gi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: repo-data-review-update-app-h8qogp-gitaly-0
    namespace: helm-charts-win
    resourceVersion: "48362307"
    uid: 6247502b-8c2d-11e8-8267-42010a9a0113
  gcePersistentDisk:
    fsType: ext4
    pdName: gke-cloud-native-81a17-pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
status:
  phase: Bound
```

変更が[ボリューム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)に反映されたので、[クレーム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)を更新する必要があります。

[PersistentVolumeClaimを変更する](#make-changes-to-the-persistentvolumeclaim)セクションの手順に従ってください。

#### クレームにバインドするようにボリュームを更新する {#update-the-volume-to-bind-to-the-claim}

別のターミナルで、[クレーム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)のステータスがboundに変わるタイミングを監視し始め、次のステップに進んで、ボリュームを新しいクレームで使用できるようにします。

```shell
kubectl --namespace <namespace> get --watch PersistentVolumeClaim <claim name>
```

ボリュームを編集して、新しいクレームで使用できるようにします。`.spec.claimRef`セクションを削除します。

```shell
kubectl --namespace <namespace> edit PersistentVolume <volume name>
```

出力の編集:

```yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    kubernetes.io/createdby: gce-pd-dynamic-provisioner
    pv.kubernetes.io/bound-by-controller: "yes"
    pv.kubernetes.io/provisioned-by: kubernetes.io/gce-pd
  creationTimestamp: 2018-07-20T14:58:43Z
  labels:
    failure-domain.beta.kubernetes.io/region: europe-west2
    failure-domain.beta.kubernetes.io/zone: europe-west2-b
  name: pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  resourceVersion: "48362431"
  selfLink: /api/v1/persistentvolumes/pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  uid: 650bd649-8c2d-11e8-8267-42010a9a0113
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 100Gi
  gcePersistentDisk:
    fsType: ext4
    pdName: gke-cloud-native-81a17-pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
status:
  phase: Released
```

[ボリューム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)への変更後まもなく、クレーム[ステータス](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)を監視しているターミナルに`Bound`と表示されるはずです。

最後に、[GitLabチャートに変更を適用します](#apply-the-changes-to-the-gitlab-chart)

### 別のボリュームへの切り替え {#switching-to-a-different-volume}

新しいボリュームの使用に切り替える場合は、古いボリュームからの適切なデータのコピーを持つディスクを使用して、最初にKubernetesで新しい[Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)を作成する必要があります。

ディスクの永続ボリュームを作成するには、ストレージタイプの[ドライバー固有のドキュメント](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes)を見つける必要があります。開始点として、同じ[Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/)の既存のPersistent Volumeを使用することもできます:

```shell
kubectl --namespace <namespace> get PersistentVolume <volume name> -o yaml > <volume name>.bak.yaml
```

ドライバーのドキュメントに従う場合は、いくつかの注意点があります。

- 多くのドキュメントに示されているように、ボリュームを持つPodオブジェクトではなく、ドライバーを使用して[Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)を作成する必要があります。
- ボリュームの[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)を**作成する**必要はありません。代わりに、既存のクレームを編集します。

ドライバーのドキュメントには、多くの場合、Podでドライバーを使用する例が含まれています。次に例を示します。

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: registry.k8s.io/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /test-pd
      name: test-volume
  volumes:
  - name: test-volume
    # This GCE PD must already exist.
    gcePersistentDisk:
      pdName: my-data-disk
      fsType: ext4
```

実際に必要なのは、次のように[Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)を作成することです。

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: test-volume
spec:
  capacity:
    storage: 400Gi
  accessModes:
  - ReadWriteOnce
  gcePersistentDisk:
    pdName: my-data-disk
    fsType: ext4
```

通常、[PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)情報を含むローカル`yaml`ファイルを作成し、createコマンドをKubernetesに発行して、ファイルを使用してオブジェクトを作成します。

```shell
kubectl --namespace <your namespace> create -f <local-pv-file>.yaml
```

ボリュームが作成されたら、[PersistentVolumeClaimの変更](#make-changes-to-the-persistentvolumeclaim)に進むことができます

## PersistentVolumeClaimを変更する {#make-changes-to-the-persistentvolumeclaim}

変更する[PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)を見つけます。

```shell
kubectl --namespace <namespace> get PersistentVolumeClaims -l release=<chart release name> -ojsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.app}{"\n"}{end}'
```

- `<namespace>`は、GitLabチャートをインストールしたネームスペースに置き換える必要があります。
- `<chart release name>`は、GitLabチャートのインストールに使用した名前に置き換える必要があります。

このコマンドは、PersistentVolumeClaim名のリストと、それらが対象とするサービスの名前を出力します。

次に、[クレーム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)のコピーをローカルファイルシステムに保存します:

```shell
kubectl --namespace <namespace> get PersistentVolumeClaim <claim name> -o yaml > <claim name>.bak.yaml
```

出力例:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  annotations:
    pv.kubernetes.io/bind-completed: "yes"
    pv.kubernetes.io/bound-by-controller: "yes"
    volume.beta.kubernetes.io/storage-provisioner: kubernetes.io/gce-pd
  creationTimestamp: 2018-07-20T14:58:38Z
  labels:
    app: gitaly
    release: review-update-app-h8qogp
  name: repo-data-review-update-app-h8qogp-gitaly-0
  namespace: helm-charts-win
  resourceVersion: "48362433"
  selfLink: /api/v1/namespaces/helm-charts-win/persistentvolumeclaims/repo-data-review-update-app-h8qogp-gitaly-0
  uid: 6247502b-8c2d-11e8-8267-42010a9a0113
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: standard
  volumeName: pvc-6247502b-8c2d-11e8-8267-42010a9a0113
status:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 50Gi
  phase: Bound
```

新しいPVCオブジェクトの新しいYAMLファイルを作成します。同じ`metadata.name`、`metadata.labels`、`metadata.namespace`、および`spec`フィールド(更新を適用)を使用し、その他の設定を削除します:

例:

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app: gitaly
    release: review-update-app-h8qogp
  name: repo-data-review-update-app-h8qogp-gitaly-0
  namespace: helm-charts-win
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      # This is our updated field
      storage: 100Gi
  storageClassName: standard
  volumeName: pvc-6247502b-8c2d-11e8-8267-42010a9a0113
```

次に、古い[クレーム](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)を削除します:

```shell
kubectl --namespace <namespace> delete PersistentVolumeClaim <claim name>
```

削除を完了するには、`finalizers`をクリアする必要がある場合があります:

```shell
kubectl --namespace <namespace> patch PersistentVolumeClaim <claim name> -p '{"metadata":{"finalizers":null}}'
```

新しいクレームを作成します:

```shell
kubectl --namespace <namespace> create -f <new claim yaml file>
```

クレームに以前バインドされていた同じ[PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)にバインドする場合は、[クレームにバインドするようにボリュームを更新](#update-the-volume-to-bind-to-the-claim)に進みます

それ以外の場合、クレームを新しいボリュームにバインドした場合は、[GitLabチャートに変更を適用](#apply-the-changes-to-the-gitlab-chart)に進みます

## GitLabチャートに変更を適用する {#apply-the-changes-to-the-gitlab-chart}

[PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)および[PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)に変更を加えた後、変更がチャート[設定](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)にも適用された状態でHelmアップデートを発行することもできます。

オプションについては、[インストールストレージガイド](../../installation/storage.md#using-the-custom-storage-class)を参照してください。

> **メモ**:Gitaly [volume claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)に変更を加えた場合は、Helmアップデートを発行できるようになる前に、Gitaly [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)を削除する必要があります。これは、StatefulSetのVolume Templateがイミュータブルであり、変更できないためです。
>
> Gitalyポッドを削除せずに、StatefulSetを削除できます:`kubectl --namespace <namespace> delete --cascade=false StatefulSet <release-name>-gitaly` Helm updateコマンドはStatefulSetを再作成し、Gitalyポッドを採用して更新します。

チャートを更新し、更新された設定を含めます:

例:

```shell
helm upgrade --install review-update-app-h8qogp gitlab/gitlab \
  --set gitlab.gitaly.persistence.size=100Gi \
  <your other config settings>
```
