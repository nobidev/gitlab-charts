---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트의 스토리지 구성
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공 방식:  GitLab Self-Managed

{{< /details >}}

GitLab 차트 내의 다음 애플리케이션은 상태를 유지하기 위해 지속성 스토리지가 필요합니다.

- [Gitaly](../charts/gitlab/gitaly/_index.md) (Git 저장소를 지속성으로 보관)
- [MinIO](../charts/minio/_index.md) (객체 스토리지 데이터를 지속성으로 보관)

관리자는 [동적](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic) 또는 [정적](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#static) 볼륨 프로비저닝을 사용하여 이 스토리지를 프로비저닝하도록 선택할 수 있습니다.

> **Important**:  사전 계획을 통해 설치 후 추가 스토리지 마이그레이션 작업을 최소화합니다. 첫 번째 배포 후 변경 사항은 `helm upgrade`을 실행하기 전에 기존 Kubernetes 객체를 수동으로 편집해야 합니다.

## 일반적인 설치 동작 {#typical-installation-behavior}

설치 관리자는 기본 스토리지 클래스와 [동적 볼륨 프로비저닝](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic)을 사용하여 스토리지를 생성합니다. 애플리케이션은 [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)을 통해 이 스토리지에 연결됩니다. 관리자는 사용 가능한 경우 [정적 볼륨 프로비저닝](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#static) 대신 [동적 볼륨 프로비저닝](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic)을 사용하는 것이 좋습니다.

> 관리자는 `kubectl get storageclass`을 사용하여 프로덕션 환경의 기본 스토리지 클래스를 결정한 후 `kubectl describe storageclass *STORAGE_CLASS_NAME*`를 사용하여 검토해야 합니다. Amazon EKS와 같은 일부 공급자는 기본 스토리지 클래스를 제공하지 않습니다.

## 클러스터 스토리지 구성 {#configuring-cluster-storage}

### 권장 사항 {#recommendations}

기본 스토리지 클래스는 다음을 수행해야 합니다:

- 사용 가능한 경우 빠른 SSD 스토리지 사용
- `reclaimPolicy`을 `Retain`로 설정합니다.

> `reclaimPolicy`을 `Retain`로 설정하지 않고 GitLab을 제거하면 자동화된 작업이 볼륨, 디스크 및 데이터를 완전히 삭제할 수 있습니다. 일부 플랫폼은 기본 `reclaimPolicy`을 `Delete`로 설정합니다. `gitaly` 지속성 볼륨 클레임은 [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)에 속하기 때문에 이 규칙을 따르지 않습니다.

### 최소 스토리지 클래스 구성 {#minimal-storage-class-configurations}

다음 `YAML` 구성은 GitLab을 위한 사용자 정의 스토리지 클래스를 생성하는 데 필요한 최소 요소를 제공합니다. `CUSTOM_STORAGE_CLASS_NAME`을 대상 설치 환경에 적합한 값으로 바꿉니다.

- [Google Cloud에서 GKE에 대한 예제 스토리지 클래스](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gke_storage_class.yml)
- [Amazon Web Services의 EKS에 대한 예제 스토리지 클래스](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/eks_storage_class.yml)

> 일부 사용자는 Amazon EKS가 노드 생성이 항상 Pod과 동일한 영역에 있지 않은 동작을 나타낸다고 보고합니다. 위의 ***zone*** 매개변수를 설정하면 모든 위험을 완화할 수 있습니다.

### 사용자 정의 스토리지 클래스 사용 {#using-the-custom-storage-class}

사용자 정의 스토리지 클래스를 클러스터 기본값으로 설정하면 모든 동적 프로비저닝에 사용됩니다.

```shell
kubectl patch storageclass CUSTOM_STORAGE_CLASS_NAME -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

또는 사용자 정의 스토리지 클래스 및 기타 옵션을 설치 중에 Helm에 서비스별로 제공할 수 있습니다. 제공된 [예제 구성 파일](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/helm_options.yml)을 확인하고 환경에 맞게 수정합니다.

```shell
helm install -upgrade gitlab gitlab/gitlab -f HELM_OPTIONS_YAML_FILE
```

추가 읽기 및 추가 지속성 옵션에 대한 아래의 링크를 따릅니다:

- [Gitaly 지속성 구성](../charts/gitlab/gitaly/_index.md#git-repository-persistence)
- [MinIO 지속성 구성](../charts/minio/_index.md#persistence)

## 정적 볼륨 프로비저닝 사용 {#using-static-volume-provisioning}

동적 볼륨 프로비저닝이 권장되지만 일부 클러스터 또는 환경은 이를 지원하지 않을 수 있습니다. 관리자는 [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes)을 수동으로 생성해야 합니다.

### Google GKE 사용 {#using-google-gke}

1. [클러스터에서 지속성 디스크를 생성합니다.](https://kubernetes.io/docs/concepts/storage/volumes/#creating-a-pd)

```shell
gcloud compute disks create --size=50GB --zone=*GKE_ZONE* *DISK_VOLUME_NAME*
```

1. [예제 `YAML` 구성](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gke_pv_example.yml)을 수정한 후 Persistent Volume을 생성합니다.

```shell
kubectl create -f *PV_YAML_FILE*
```

### Using Amazon EKS {#using-amazon-eks}

여러 영역에 배포해야 하는 경우 스토리지 솔루션을 정의할 때 [Amazon의 자체 스토리지 클래스 설명서](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)를 검토해야 합니다.

1. [클러스터에서 지속성 디스크를 생성합니다.](https://kubernetes.io/docs/concepts/storage/volumes/#creating-an-ebs-volume)

```shell
aws ec2 create-volume --availability-zone=*AWS_ZONE* --size=10 --volume-type=gp2
```

1. [예제 `YAML` 구성](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/eks_pv_example.yml)을 수정한 후 Persistent Volume을 생성합니다.

```shell
kubectl create -f *PV_YAML_FILE*
```

### 수동으로 PersistentVolumeClaim 생성 {#manually-creating-persistentvolumeclaims}

Gitaly 서비스는 [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)을 사용하여 배포됩니다. [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)을 올바르게 인식하고 사용하기 위해 다음 명명 규칙을 사용하여 생성합니다.

```plaintext
<mount-name>-<statefulset-pod-name>
```

Gitaly의 `mount-name`은 `repo-data`입니다. StatefulSet Pod 이름은 다음을 사용하여 생성됩니다:

```plaintext
<statefulset-name>-<pod-index>
```

GitLab 차트는 `statefulset-name`을 다음을 사용하여 결정합니다:

```plaintext
<chart-release-name>-<service-name>
```

Gitaly PersistentVolumeClaim의 올바른 이름은 `repo-data-gitlab-gitaly-0`입니다.

> **노트**:  Praefect와 여러 Virtual Storage를 사용하는 경우 정의된 Virtual Storage당 Gitaly 복제본당 하나의 PersistentVolumeClaim이 필요합니다. 예를 들어 `default`와 `vs2` Virtual Storage가 정의되어 있고 각각 2개의 복제본이 있으면 다음 PersistentVolumeClaim이 필요합니다:
>
> - `repo-data-gitlab-gitaly-default-0`
> - `repo-data-gitlab-gitaly-default-1`
> - `repo-data-gitlab-gitaly-vs2-0`
> - `repo-data-gitlab-gitaly-vs2-1`

환경에 맞게 [예제 YAML 구성](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gitaly_persistent_volume_claim.yml)을 수정하고 `helm`을 호출할 때 참조합니다.

> [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/)을 사용하지 않는 다른 서비스는 관리자가 `volumeName`을 구성에 제공할 수 있습니다. 이 차트는 여전히 [볼륨 클레임](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims)을 생성하고 수동으로 생성된 볼륨에 바인딩하려고 시도합니다. 포함된 각 애플리케이션의 차트 설명서를 확인합니다.
>
> 대부분의 경우 [예제 YAML 구성](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/use_manual_volumes.yml)을 수정하여 수동으로 생성된 디스크 볼륨을 사용할 서비스만 유지합니다.

## 설치 후 스토리지 변경 {#making-changes-to-storage-after-installation}

초기 설치 후 새 볼륨으로 마이그레이션하거나 디스크 크기 변경과 같은 스토리지 변경은 Helm 업그레이드 명령 외부에서 Kubernetes 객체를 편집해야 합니다.

[지속성 볼륨 관리 설명서](../advanced/persistent-volumes/_index.md)를 참조하세요.

## 선택적 볼륨 {#optional-volumes}

더 큰 설치의 경우 백업/복원이 작동하도록 Toolbox에 지속성 스토리지를 추가해야 할 수 있습니다. 이를 수행하는 방법에 대한 [문제 해결 설명서](../backup-restore/_index.md#pod-eviction-issues)를 참조하세요.
