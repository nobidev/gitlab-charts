---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트를 위한 EKS 리소스 준비
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공 형식:  GitLab Self-Managed

{{< /details >}}

완전히 기능하는 GitLab 인스턴스를 위해서는 GitLab 차트를 배포하기 전에 몇 가지 리소스가 필요합니다.

## EKS 클러스터 생성 {#creating-the-eks-cluster}

더 쉽게 시작하기 위해 클러스터 생성을 자동화하는 스크립트가 제공됩니다. 또는 클러스터를 수동으로 생성할 수도 있습니다.

필수 조건:

- [필수 조건](../tools.md)을 설치합니다.
- [`eksctl`](https://github.com/weaveworks/eksctl#installation)을 설치합니다.

클러스터를 수동으로 생성하려면 [Amazon AWS Getting started with Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html)를 참조하세요. EKS 클러스터에는 EC2 관리형 노드를 사용하고 [Fargate](https://docs.aws.amazon.com/en_us/eks/latest/userguide/fargate.html)는 사용하지 마세요. Fargate는 여러 제한 사항이 있으며 GitLab Helm 차트와 함께 사용하는 것이 지원되지 않습니다.

### 스크립트된 클러스터 생성 {#scripted-cluster-creation}

[부트스트랩 스크립트](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/eks_bootstrap_script)가 EKS 사용자를 위한 설정 프로세스의 대부분을 자동화하기 위해 만들어졌습니다. 스크립트를 실행하기 전에 이 저장소를 복제해야 합니다.

스크립트는 다음을 수행합니다:

1. 새로운 EKS 클러스터를 생성합니다.
1. `kubectl`을 설정하고 클러스터에 연결합니다.

인증하기 위해 `eksctl`은 AWS 명령줄과 동일한 옵션을 사용합니다. AWS 설명서에서 [환경 변수](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) 또는 [구성 파일](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)을 사용하는 방법을 참조하세요.

스크립트는 환경 변수 또는 명령줄 인수에서 다양한 매개변수를 읽으며, 부트스트랩의 경우 `up` 인수 또는 정리의 경우 `down` 인수를 사용합니다.

아래 표는 모든 변수를 설명합니다.

| 변수          | 기본값    | 설명 |
|-------------------|------------------|-------------|
| `REGION`          | `us-east-2`      | 클러스터가 있는 리전 |
| `CLUSTER_NAME`    | `gitlab-cluster` | 클러스터의 이름 |
| `CLUSTER_VERSION` | `1.29`           | EKS 클러스터의 버전 |
| `NUM_NODES`       | `2`              | 필요한 노드의 수 |
| `MACHINE_TYPE`    | `m5.xlarge`      | 배포할 노드의 유형 |

원하는 매개변수를 전달하여 스크립트를 실행합니다. 기본 매개변수로도 작동할 수 있습니다.

```shell
./scripts/eks_bootstrap_script up
```

스크립트를 사용하여 생성된 EKS 리소스를 정리할 수도 있습니다:

```shell
./scripts/eks_bootstrap_script down
```

### 수동 클러스터 생성 {#manual-cluster-creation}

- 8vCPU와 30GB RAM이 있는 클러스터를 권장합니다.

가장 최근의 지시사항을 확인하려면 Amazon의 [EKS 시작 가이드](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)를 따르세요.

관리자는 또한 이 프로세스를 단순화하기 위해 [새로운 AWS Service Operator for Kubernetes](https://aws.amazon.com/blogs/opensource/aws-service-operator-kubernetes-available/)를 고려할 수 있습니다.

> [!note] AWS Service Operator를 활성화하려면 클러스터 내에서 역할을 관리하는 방법이 필요합니다. 해당 관리 작업을 처리하는 초기 서비스는 타사 개발자에 의해 제공됩니다. 관리자는 배포를 계획할 때 이를 염두에 두어야 합니다.

## 지속형 볼륨 관리 {#persistent-volume-management}

Kubernetes에서 볼륨 클레임을 관리하는 두 가지 방법이 있습니다:

- 지속형 볼륨을 수동으로 생성합니다.
- 동적 프로비저닝을 통한 자동 지속형 볼륨 생성.

현재는 지속형 볼륨의 수동 프로비저닝을 사용하는 것을 권장합니다. Amazon EKS 클러스터는 기본적으로 여러 영역에 걸쳐 있습니다. 동적 프로비저닝이 특정 영역에 잠긴 스토리지 클래스를 사용하도록 구성되지 않으면, Pod가 스토리지 볼륨과 다른 영역에 존재하여 데이터에 액세스할 수 없는 상황이 발생할 수 있습니다. 자세한 내용은 [지속형 볼륨 프로비저닝](../storage.md) 방법을 참조하세요.

Amazon EKS 1.23 이상 클러스터에서는 수동 또는 동적 프로비저닝 여부와 관계없이 클러스터에 [Amazon EBS CSI add-on](https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html#adding-ebs-csi-eks-add-on)을 설치해야 합니다.

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

## GitLab에 대한 외부 액세스 {#external-access-to-gitlab}

기본적으로 GitLab 차트를 설치하면 Ingress가 배포되어 관련 Elastic Load Balancer (ELB)가 생성됩니다. ELB의 DNS 이름을 미리 알 수 없으므로 [Let's Encrypt](https://letsencrypt.org/)를 사용하여 HTTPS 인증서를 자동으로 프로비저닝하기가 어렵습니다.

[자신의 인증서 사용](../tls.md#option-2-use-your-own-wildcard-certificate)을 권장하며, 그 다음 CNAME 레코드를 사용하여 원하는 DNS 이름을 생성된 ELB에 매핑합니다. ELB는 호스트명을 검색할 수 있기 전에 먼저 생성되어야 하므로, 다음 지침을 따라 GitLab을 설치합니다.

> [!note] AWS LoadBalancer가 필요한 환경의 경우, [Amazon's Elastic Load Balancers](https://docs.aws.amazon.com/eks/latest/userguide/load-balancing.html)는 특별한 구성이 필요합니다. [Cloud provider LoadBalancers](../../charts/globals.md#cloud-provider-loadbalancers)를 참조하세요.

## 다음 단계 {#next-steps}

클러스터가 준비되어 실행 중이면 [차트 설치](../deployment.md)를 계속합니다. `global.hosts.domain` 옵션을 통해 도메인 이름을 설정하되, `global.hosts.externalIP` 옵션을 통한 정적 IP 설정은 기존 Elastic IP를 사용할 계획이 없는 한 생략합니다.

Helm 설치 후 다음을 사용하여 CNAME 레코드에 배치할 ELB의 호스트명을 가져올 수 있습니다:

```shell
kubectl get ingress/RELEASE-webservice-default -ojsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

`RELEASE`은 `helm install <RELEASE>`에서 사용된 릴리스 이름으로 대체되어야 합니다.
