---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트를 위한 AKS 리소스 준비
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

완전히 기능하는 GitLab 인스턴스를 위해, [Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/what-is-aks)에 GitLab 차트를 배포하기 전에 몇 가지 리소스가 필요합니다.

## AKS 클러스터 생성 {#creating-the-aks-cluster}

더 쉽게 시작하기 위해 클러스터 생성을 자동화하는 스크립트가 제공됩니다. 또는 클러스터를 수동으로 생성할 수도 있습니다.

전제 조건:

- [전제 조건](../tools.md)을 설치하세요.
- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) 를 설치하고 [Azure에 로그인](https://learn.microsoft.com/en-us/cli/azure/get-started-with-azure-cli#how-to-sign-into-the-azure-cli)하세요.
- [`jq`를 설치](https://stedolan.github.io/jq/download/)하세요.

### 스크립트된 클러스터 생성 {#scripted-cluster-creation}

Azure의 사용자를 위해 설정 프로세스의 많은 부분을 자동화하기 위해 [부트스트랩 스크립트](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/aks_bootstrap_script.sh)가 만들어졌습니다.

`up`, `down` 또는 `creds`의 인수를 읽고, 환경 변수 또는 명령줄 인수의 추가 선택적 매개변수를 포함합니다:

- 클러스터를 생성하려면:

  ```shell
  ./scripts/aks_bootstrap_script.sh up
  ```

  이것은 다음을 수행합니다:

  1. 새 리소스 그룹 생성(선택 사항).
  1. 새 AKS 클러스터 생성.
  1. 새 공용 IP 생성(선택 사항).

- 생성된 AKS 리소스를 정리하려면:

  ```shell
  ./scripts/aks_bootstrap_script.sh down
  ```

  이것은 다음을 수행합니다:

  1. 지정된 리소스 그룹 삭제(선택 사항).
  1. AKS 클러스터 삭제.
  1. 클러스터에서 생성한 리소스 그룹 삭제.

  `down` 인수는 모든 리소스를 삭제하는 명령을 보내고 즉시 완료합니다. 실제 삭제는 완료하는 데 몇 분이 걸릴 수 있습니다.

- `kubectl`을 클러스터에 연결하려면:

  ```shell
  ./scripts/aks_bootstrap_script.sh creds
  ```

아래 표는 사용 가능한 모든 변수를 설명합니다.

| 변수                   | 기본값      | 범위   | 설명 |
|----------------------------|--------------------|---------|-------------|
| `-g --resource-group`      | `gitlab-resources` | 모두     | 사용할 리소스 그룹의 이름. |
| `-n --cluster-name`        | `gitlab-cluster`   | 모두     | 사용할 클러스터의 이름. |
| `-r --region`              | `eastus`           | `up`    | 클러스터를 설치할 지역. |
| `-v --cluster-version`     | 최신             | `up`    | 클러스터를 생성하는 데 사용할 Kubernetes의 버전. |
| `-c --node-count`          | `2`                | `up`    | 사용할 노드의 수. |
| `-s --node-vm-size`        | `Standard_D4s_v3`  | `up`    | 사용할 노드의 유형. |
| `-p --public-ip-name`      | `gitlab-ext-ip`    | `up`    | 생성할 공용 IP의 이름. |
| `--create-resource-group`  | `false`            | `up`    | 생성된 모든 리소스를 보유할 새 리소스 그룹을 생성합니다. |
| `--create-public-ip`       | `false`            | `up`    | 새 클러스터에서 사용할 공용 IP를 생성합니다. |
| `--delete-resource-group`  | `false`            | `down`  | down 명령을 사용할 때 리소스 그룹을 삭제합니다. |
| `-f --kubectl-config-file` | `~/.kube/config`   | `creds` | 업데이트할 Kubernetes 구성 파일. `-`을 사용하여 YAML을 `stdout`에 대신 인쇄합니다. |

### 수동 클러스터 생성 {#manual-cluster-creation}

8vCPU 및 30GB RAM이 있는 클러스터가 권장됩니다.

가장 최신의 지침을 보려면 Microsoft의 [AKS 안내](https://learn.microsoft.com/en-us/azure/aks/learn/quick-kubernetes-deploy-portal)를 따르세요.

## GitLab에 대한 외부 액세스 {#external-access-to-gitlab}

클러스터에 도달할 수 있도록 외부 IP가 필요합니다. 가장 최신의 지침을 보려면 Microsoft의 [정적 IP 주소 생성](https://learn.microsoft.com/en-us/azure/aks/static-ip) 가이드를 따르세요.

## 다음 단계 {#next-steps}

클러스터가 실행 중이고 정적 IP와 DNS 항목이 준비되면 [차트 설치](../deployment.md)를 계속하세요.
