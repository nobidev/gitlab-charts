---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 지속적인 볼륨을 사용하여 GitLab 차트 구성
---

포함된 일부 서비스는 [지속적인 볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)을 통해 구성된 지속적인 스토리지가 필요하며, 클러스터가 액세스할 수 있는 디스크를 지정합니다. 이 차트를 설치하는 데 필요한 스토리지 구성 설명서는 [스토리지 가이드](../../installation/storage.md)에서 찾을 수 있습니다.

설치 후 스토리지 변경은 클러스터 관리자가 수동으로 처리해야 합니다. 설치 후 이러한 볼륨의 자동 관리는 GitLab 차트에서 처리되지 않습니다.

초기 설치 후 자동으로 관리되지 않는 변경 사항의 예:

- 팟(Pod)에 다른 볼륨 탑재
- 효과적인 accessModes 또는 [스토리지 클래스](https://kubernetes.io/docs/concepts/storage/storage-classes/) 변경
- 볼륨의 스토리지 크기 확장. Kubernetes 1.11에서 `allowVolumeExpansion`이 [스토리지 클래스](https://kubernetes.io/docs/concepts/storage/storage-classes/) 에서 true로 구성된 경우 [볼륨의 스토리지 크기 확장이 지원됩니다](https://kubernetes.io/blog/2018/07/12/resizing-persistent-volumes-using-kubernetes/).

이러한 변경 사항 자동화가 복잡한 이유:

1. Kubernetes는 기존 [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)의 대부분의 필드 변경을 허용하지 않습니다.
1. [수동으로 구성](../../installation/storage.md) 하지 않으면 [PVC](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) 는 동적으로 프로비저닝된 [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)에 대한 유일한 참조입니다.
1. `Delete`은 동적으로 프로비저닝된 [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) 의 기본 [reclaimPolicy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy)입니다.

즉, 변경 작업을 수행하려면 [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)을 삭제하고 변경 사항이 포함된 새 항목을 만들어야 합니다. 하지만 기본 [reclaimPolicy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy) 때문에 [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) 을 삭제하면 [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)과 기본 디스크가 삭제될 수 있습니다. 그리고 적절한 volumeNames 및/또는 labelSelectors로 구성하지 않으면 차트가 연결할 볼륨을 모릅니다.

이 프로세스를 더 쉽게 하기 위해 계속 노력하겠지만 지금은 스토리지 변경을 수행하기 위해 수동 프로세스를 따라야 합니다.

## GitLab 볼륨 찾기 {#locate-the-gitlab-volumes}

사용 중인 볼륨/클레임 찾기:

```shell
kubectl --namespace <namespace> get PersistentVolumeClaims -l release=<chart release name> -ojsonpath='{range .items[*]}{.spec.volumeName}{"\t"}{.metadata.labels.app}{"\n"}{end}'
```

- `<namespace>`을 GitLab 차트를 설치한 네임스페이스로 바꿔야 합니다.
- `<chart release name>`을 GitLab 차트를 설치하는 데 사용한 이름으로 바꿔야 합니다.

명령은 볼륨 이름 목록과 그 볼륨이 사용되는 서비스의 이름을 출력합니다.

예를 들어:

```shell
$ kubectl --namespace helm-charts-win get PersistentVolumeClaims -l release=review-update-app-h8qogp -ojsonpath='{range .items[*]}{.spec.volumeName}{"\t"}{.metadata.labels.app}{"\n"}{end}'
pvc-6247502b-8c2d-11e8-8267-42010a9a0113  gitaly
pvc-61bbc05e-8c2d-11e8-8267-42010a9a0113  minio
pvc-61bc6069-8c2d-11e8-8267-42010a9a0113  postgresql
pvc-61bcd6d2-8c2d-11e8-8267-42010a9a0113  prometheus
pvc-61bdf136-8c2d-11e8-8267-42010a9a0113  redis
```

## 스토리지 변경 전 {#before-making-storage-changes}

변경을 수행하는 사용자는 클러스터에 대한 관리자 액세스 권한과 사용 중인 스토리지 솔루션에 대한 적절한 액세스 권한이 있어야 합니다. 종종 변경 사항을 먼저 스토리지 솔루션에 적용한 후 결과를 Kubernetes에서 업데이트해야 합니다.

변경을 수행하기 전에 [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)이 `Retain` [reclaimPolicy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy)를 사용하고 있는지 확인하여 변경 중에 제거되지 않도록 해야 합니다.

먼저 [사용 중인 볼륨/클레임을 찾습니다](#locate-the-gitlab-volumes).

다음으로 각 볼륨을 편집하고 `spec` 필드 아래의 `persistentVolumeReclaimPolicy` 값을 `Delete` 대신 `Retain`이 되도록 변경합니다.

예를 들어:

```shell
kubectl --namespace helm-charts-win edit PersistentVolume pvc-6247502b-8c2d-11e8-8267-42010a9a0113
```

편집 출력:

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

## 스토리지 변경 {#making-storage-changes}

먼저 클러스터 외부의 디스크에 원하는 변경을 수행합니다. (GKE에서 디스크 크기를 조정하거나 스냅샷 또는 복제본에서 새 디스크를 만드는 등).

이 작업을 수행하는 방법과 다운타임 없이 라이브로 수행할 수 있는지 여부는 사용 중인 스토리지 솔루션에 따라 다르며 이 문서에서 다룰 수 없습니다.

다음으로 이러한 변경 사항을 Kubernetes 개체에 반영해야 하는지 평가합니다. 예를 들어 디스크 스토리지 크기를 확장할 때 [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)의 스토리지 크기 설정은 새 볼륨 리소스가 요청될 때만 사용됩니다. 따라서 더 많은 디스크를 확장하려는 경우(추가 Gitaly 팟에서 사용하기 위해) [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)의 값을 늘려야 합니다.

Kubernetes에 변경 사항을 반영해야 하는 경우 [스토리지 변경 전](#before-making-storage-changes) 섹션에 설명된 대로 볼륨의 회수 정책을 업데이트했는지 확인하세요.

스토리지 변경에 대해 문서화한 경로는 다음과 같습니다:

- [기존 볼륨 변경](#changes-to-an-existing-volume)
- [다른 볼륨으로 전환](#switching-to-a-different-volume)

### 기존 볼륨 변경 {#changes-to-an-existing-volume}

먼저 변경할 [볼륨 이름을 찾습니다](#locate-the-gitlab-volumes).

`kubectl edit`을 사용하여 볼륨에 대한 원하는 구성 변경을 수행합니다. (이러한 변경은 연결된 디스크의 실제 상태를 반영하기 위한 업데이트만 수행해야 합니다.)

예를 들어:

```shell
kubectl --namespace helm-charts-win edit PersistentVolume pvc-6247502b-8c2d-11e8-8267-42010a9a0113
```

편집 출력:

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

변경 사항이 [볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) 에 반영되었으므로 이제 [클레임](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)을 업데이트해야 합니다.

[PersistentVolumeClaim 변경](#make-changes-to-the-persistentvolumeclaim) 섹션의 지침을 따릅니다.

#### 클레임에 바인딩할 볼륨 업데이트 {#update-the-volume-to-bind-to-the-claim}

별도의 터미널에서 [클레임](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) 상태가 바운드로 변경되는 시점을 확인하고 다음 단계로 진행하여 새 클레임에서 사용할 수 있도록 볼륨을 만듭니다.

```shell
kubectl --namespace <namespace> get --watch PersistentVolumeClaim <claim name>
```

새 클레임에서 사용할 수 있도록 볼륨을 편집합니다. `.spec.claimRef` 섹션을 제거합니다.

```shell
kubectl --namespace <namespace> edit PersistentVolume <volume name>
```

편집 출력:

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

[볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)을 변경한 직후 클레임 상태를 감시하는 터미널에 `Bound`이 표시되어야 합니다.

마지막으로 [GitLab 차트에 변경 사항 적용](#apply-the-changes-to-the-gitlab-chart)

### 다른 볼륨으로 전환 {#switching-to-a-different-volume}

새 볼륨으로 전환하려면 이전 볼륨에서 적절한 데이터의 복사본이 있는 디스크를 사용하여 먼저 Kubernetes에 새 [지속적인 볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)을 만들어야 합니다.

디스크에 대한 지속적인 볼륨을 만들기 위해 스토리지 유형에 대한 [드라이버별 설명서](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes)를 찾아야 합니다. 동일한 [스토리지 클래스](https://kubernetes.io/docs/concepts/storage/storage-classes/)의 기존 지속적인 볼륨을 시작점으로 사용할 수도 있습니다:

```shell
kubectl --namespace <namespace> get PersistentVolume <volume name> -o yaml > <volume name>.bak.yaml
```

드라이버 설명서를 따를 때 주의할 사항이 몇 가지 있습니다:

- 많은 설명서에 나와 있는 것처럼 [지속적인 볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)을 만들어야 합니다. 볼륨이 있는 팟 개체는 아닙니다.
- 볼륨에 대한 **not**을 만들고 싶지 [않습니다](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims). 대신 기존 클레임을 편집할 것입니다.

드라이버 설명서에는 팟에서 드라이버를 사용하는 예가 포함되어 있습니다(예:):

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

실제로 원하는 것은 [지속적인 볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)을 만드는 것입니다:

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

일반적으로 [지속적인 볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) 정보가 포함된 로컬 `yaml` 파일을 만든 후 Kubernetes에 create 명령을 실행하여 파일을 사용하여 개체를 만듭니다.

```shell
kubectl --namespace <your namespace> create -f <local-pv-file>.yaml
```

볼륨이 생성되면 [PersistentVolumeClaim 변경](#make-changes-to-the-persistentvolumeclaim)으로 이동할 수 있습니다.

## PersistentVolumeClaim 변경 {#make-changes-to-the-persistentvolumeclaim}

변경할 [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)을 찾습니다.

```shell
kubectl --namespace <namespace> get PersistentVolumeClaims -l release=<chart release name> -ojsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.app}{"\n"}{end}'
```

- `<namespace>`을 GitLab 차트를 설치한 네임스페이스로 바꿔야 합니다.
- `<chart release name>`을 GitLab 차트를 설치하는 데 사용한 이름으로 바꿔야 합니다.

명령은 PersistentVolumeClaim 이름 목록과 그 이름이 사용되는 서비스의 이름을 출력합니다.

그런 다음 [클레임](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)의 복사본을 로컬 파일 시스템에 저장합니다:

```shell
kubectl --namespace <namespace> get PersistentVolumeClaim <claim name> -o yaml > <claim name>.bak.yaml
```

출력 예:

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

새 PVC 개체에 대한 새 YAML 파일을 만듭니다. 동일한 `metadata.name`, `metadata.labels`, `metadata.namespace` 및 `spec` 필드(적용된 업데이트 포함)를 사용하고 다른 설정은 삭제합니다:

예:

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

이제 이전 [클레임](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)을 삭제합니다:

```shell
kubectl --namespace <namespace> delete PersistentVolumeClaim <claim name>
```

삭제를 완료하려면 `finalizers`을 지워야 할 수도 있습니다:

```shell
kubectl --namespace <namespace> patch PersistentVolumeClaim <claim name> -p '{"metadata":{"finalizers":null}}'
```

새 클레임을 만듭니다:

```shell
kubectl --namespace <namespace> create -f <new claim yaml file>
```

이전에 클레임에 바인딩된 동일한 [지속적인 볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) 에 바인딩하는 경우 [클레임에 바인딩할 볼륨을 업데이트](#update-the-volume-to-bind-to-the-claim)로 진행합니다.

그렇지 않으면 클레임을 새 볼륨에 바인딩한 경우 [GitLab 차트에 변경 사항 적용](#apply-the-changes-to-the-gitlab-chart)으로 이동합니다.

## GitLab 차트에 변경 사항 적용 {#apply-the-changes-to-the-gitlab-chart}

[지속적인 볼륨](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) 및 [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)을 변경한 후 차트 설정에 적용된 변경 사항과 함께 Helm 업데이트를 발행하려고 합니다.

옵션에 대해서는 [설치 스토리지 가이드](../../installation/storage.md#using-the-custom-storage-class)를 참조하세요.

Gitaly [볼륨 클레임](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) 을 변경한 경우 Helm 업데이트를 발행할 수 있기 전에 Gitaly [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)을 삭제해야 합니다. 이는 StatefulSet의 볼륨 템플릿이 불변이며 변경할 수 없기 때문입니다.

Gitaly 팟을 삭제하지 않고 StatefulSet을 삭제할 수 있습니다:

```shell
kubectl --namespace <namespace> delete --cascade=orphan StatefulSet <release-name>-gitaly
```

Helm 업데이트 명령은 StatefulSet을 다시 만들고 Gitaly 팟을 채택하고 업데이트합니다.

차트를 업데이트하고 업데이트된 구성을 포함합니다:

예:

```shell
helm upgrade --install review-update-app-h8qogp gitlab/gitlab \
  --set gitlab.gitaly.persistence.size=100Gi \
  <your other config settings>
```
