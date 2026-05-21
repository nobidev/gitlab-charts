---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트용 GKE 리소스 준비
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

완전히 작동하는 GitLab 인스턴스를 위해 GitLab 차트를 배포하기 전에 몇 가지 리소스가 필요합니다. 다음은 이러한 차트가 GitLab 내에서 배포되고 테스트되는 방법입니다.

## GKE 클러스터 생성 {#creating-the-gke-cluster}

더 쉽게 시작하기 위해 클러스터 생성을 자동화하는 스크립트가 제공됩니다. 또는 클러스터를 수동으로 생성할 수도 있습니다.

전제 조건:

- [전제 조건](../tools.md)을 설치하세요.
- [Google SDK](https://cloud.google.com/sdk/docs/install)를 설치하세요.

### 스크립트된 클러스터 생성 {#scripted-cluster-creation}

[부트스트랩 스크립트](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/gke_bootstrap_script.sh)가 GCP/GKE 사용자용 설정 프로세스의 대부분을 자동화하기 위해 생성되었습니다.

스크립트는 다음을 수행합니다:

1. 새 GKE 클러스터를 생성합니다.
1. 클러스터가 DNS 레코드를 수정할 수 있도록 허용합니다.
1. `kubectl`을 설정하고 클러스터에 연결합니다.

스크립트는 환경 변수와 부트스트랩용 `up` 또는 정리용 `down` 인수에서 다양한 매개변수를 읽습니다.

아래 표는 모든 변수를 설명합니다.

| 변수              | 기본값                     | 설명 |
|-----------------------|-----------------------------------|-------------|
| `ADMIN_USER`          | 현재 gcloud 사용자               | 설정 중에 cluster-admin 액세스 권한을 할당할 사용자입니다. |
| `AUTOSCALE_MAX_NODES` | `NUM_NODES`                       | 자동 스케일러가 확장해야 하는 최대 노드 수입니다. |
| `AUTOSCALE_MIN_NODES` | `0`                               | 자동 스케일러가 축소해야 하는 최소 노드 수입니다. |
| `CLUSTER_NAME`        | `gitlab-cluster`                  | 클러스터의 이름입니다. |
| `CLUSTER_VERSION`     | GKE 기본값이며, [GKE 릴리스 노트](https://cloud.google.com/kubernetes-engine/docs/release-notes)를 확인하세요. | GKE 클러스터의 버전입니다. |
| `INT_NETWORK`         | 기본값                           | 이 클러스터 내에서 사용할 IP 공간입니다. |
| `MACHINE_TYPE`        | `n2d-standard-4`                  | 클러스터 인스턴스의 유형입니다. |
| `NUM_NODES`           | `2`                               | 필요한 노드의 수입니다. |
| `PREEMPTIBLE`         | `false`                           | 더 저렴하며, 클러스터는 *최대* 24시간 동안 실행됩니다. 노드/디스크에 대한 SLA가 없습니다. |
| `PROJECT`             | 기본값이 없으며 설정해야 합니다.  | GCP 프로젝트의 ID입니다. |
| `RBAC_ENABLED`        | `true`                            | 클러스터에 RBAC이 활성화되어 있는지 알고 있다면 이 변수를 설정하세요. |
| `REGION`              | `us-central1`                     | 클러스터가 위치한 리전입니다. |
| `SUBNETWORK`          | 기본값                           | 이 클러스터 내에서 사용할 서브네트워크입니다. |
| `USE_STATIC_IP`       | `false`                           | 관리되는 DNS와 함께 임시 IP 대신 GitLab용 정적 IP를 생성합니다. |
| `ZONE_EXTENSION`      | `b`                               | 클러스터 인스턴스가 위치한 영역 이름의 확장자(`a`, `b`, `c`)입니다. |

스크립트를 실행할 때 원하는 매개변수를 전달하세요. 필수인 `PROJECT`을 제외한 기본 매개변수로 작동할 수 있습니다:

```shell
PROJECT=<gcloud project id> ./scripts/gke_bootstrap_script.sh up
```

스크립트를 사용하여 생성된 GKE 리소스를 정리할 수도 있습니다:

```shell
PROJECT=<gcloud project id> ./scripts/gke_bootstrap_script.sh down
```

클러스터가 생성되면 [DNS 항목 생성](#dns-entry)으로 계속 진행합니다.

### 수동 클러스터 생성 {#manual-cluster-creation}

GCP에서 두 개의 리소스(Kubernetes 클러스터 및 외부 IP)를 생성해야 합니다.

#### Kubernetes 클러스터 생성 {#creating-the-kubernetes-cluster}

Kubernetes 클러스터를 수동으로 프로비저닝하려면 [GKE 지침](https://cloud.google.com/kubernetes-engine/docs/how-to/creating-a-zonal-cluster)을 따르세요.

- 최소 2개의 노드(각각 4vCPU 및 15GB RAM)를 포함하는 클러스터를 권장합니다.
- 클러스터의 리전을 기록해두세요. 다음 단계에서 필요합니다.

#### 외부 IP 생성 {#creating-the-external-ip}

클러스터에 도달할 수 있도록 외부 IP가 필요합니다. 외부 IP는 리전별이어야 하며 클러스터 자체와 동일한 리전에 있어야 합니다. 글로벌 IP 또는 클러스터 리전 외부의 IP는 **작동하지 않습니다**.

정적 IP를 생성하려면:

`gcloud compute addresses create ${CLUSTER_NAME}-external-ip --region $REGION --project $PROJECT`

새로 생성된 IP의 주소를 가져오려면:

`gcloud compute addresses describe ${CLUSTER_NAME}-external-ip --region $REGION --project $PROJECT --format='value(address)'`

이 IP를 사용하여 다음 섹션의 DNS 이름과 바인딩합니다.

## DNS 항목 {#dns-entry}

클러스터를 수동으로 생성했거나 스크립트된 생성과 함께 `USE_STATIC_IP` 옵션을 사용한 경우 방금 생성한 IP를 가리키는 A 레코드 와일드카드 DNS 항목이 있는 공개 도메인이 필요합니다.

[Google DNS 빠른 시작 가이드](https://cloud.google.com/dns/docs/set-up-dns-records-domain-name)를 따라 DNS 항목을 생성합니다.

## 다음 단계 {#next-steps}

클러스터가 실행 중이고 정적 IP 및 DNS 항목이 준비되면 [차트 설치](../deployment.md)를 계속 진행합니다.
