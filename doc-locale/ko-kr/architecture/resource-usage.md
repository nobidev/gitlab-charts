---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 리소스 사용
---

## 리소스 요청 {#resource-requests}

저희의 모든 컨테이너에는 미리 정의된 리소스 요청 값이 포함되어 있습니다. 기본적으로 리소스 제한을 설정하지 않았습니다. 노드에 여유 메모리 용량이 없으면 메모리 제한을 적용하는 것이 한 가지 옵션이지만, 메모리(또는 노드)를 추가하는 것이 더 바람직합니다. (Kubernetes 노드에서 메모리가 부족해지는 것을 피하고 싶을 것입니다. Linux 커널의 [out of memory manager](https://www.kernel.org/doc/gorman/html/understand/understand016.html)가 필수 Kube 프로세스를 종료할 수 있기 때문입니다)

기본 요청 값을 결정하기 위해 애플리케이션을 실행하고 각 서비스에 대해 다양한 수준의 부하를 생성하는 방법을 찾아냅니다. 서비스를 모니터링하고 최선의 기본값이 무엇인지 판단합니다.

다음을 측정할 것입니다:

- **Idle Load** \- 기본값은 이 값 이하로 설정되지 않아야 하지만, 유휴 프로세스는 유용하지 않으므로 일반적으로 이 값을 기반으로 기본값을 설정하지 않습니다.

- **Minimal Load** \- 가장 기본적인 유용한 작업을 수행하는 데 필요한 값입니다. 일반적으로 CPU의 경우 이를 기본값으로 사용하지만 메모리 요청에는 커널이 프로세스를 제거할 위험이 있으므로 메모리 기본값으로는 이를 사용하지 않습니다.

- **Average Loads** - *평균*으로 간주되는 것은 설치에 따라 크게 달라지며, 기본값의 경우 합리적이라고 생각되는 부하에서 몇 가지 측정을 수행하려고 합니다. (사용된 부하를 나열할 것입니다). 서비스에 pod 자동 스케일러가 있으면 일반적으로 이러한 값을 기반으로 스케일링 대상 값을 설정하려고 합니다. 그리고 기본 메모리 요청도 설정합니다.

- **Stressful Task** \- 서비스가 수행해야 하는 가장 스트레스가 많은 작업의 사용량을 측정합니다. (부하 상태에서는 필요하지 않음). 리소스 제한을 적용할 때 제한을 이 값과 평균 부하 값 위에 설정하세요.

- **Heavy Load** \- 서비스에 대한 스트레스 테스트를 수행한 후 이를 수행하는 데 필요한 리소스 사용량을 측정합니다. 현재 이러한 값을 기본값으로 사용하지는 않지만 사용자가 평균 부하/스트레스 작업과 이 값 사이에 리소스 제한을 설정하고 싶을 것입니다.

### GitLab Shell {#gitlab-shell}

`nohup git clone <project> <random-path-name>`을(를) 호출하는 bash 루프를 사용하여 부하를 테스트했습니다. 향후 테스트에서는 지속적인 동시 부하를 포함하려고 노력할 것이며, 이는 다른 서비스에 대해 수행한 테스트 유형과 더 잘 일치합니다.

- **Idle values**
  - 0개 작업, 2개 Pod
    - cpu:  0
    - 메모리: `5M`
- **Minimal Load**
  - 1개 작업(비어있는 clone 1개), 2개 Pod
    - cpu:  0
    - 메모리: `5M`
- **Average Loads**
  - 5개 동시 clone, 2개 Pod
    - cpu: `100m`
    - 메모리: `5M`
  - 20개 동시 clone, 2개 Pod
    - cpu: `80m`
    - 메모리: `6M`
- **Stressful Task**
  - SSH clone Linux 커널(17MB/s)
    - cpu: `280m`
    - 메모리: `17M`
  - SSH push Linux 커널(2MB/s)
    - cpu: `140m`
    - 메모리: `13M`
    - *업로드 연결 속도가 테스트 중에 영향을 미쳤을 가능성이 있습니다*
- **Heavy Load**
  - 100개 동시 clone, 4개 Pod
    - cpu: `110m`
    - 메모리: `7M`
- **Default Requests**
  - cpu:  0(최소 부하에서)
  - 메모리: `6M`(평균 부하에서)
  - 목표 CPU 평균: `100m`(평균 부하에서)
- **Recommended Limits**
  - cpu: > `300m`(스트레스 작업보다 큼)
  - 메모리: > `20M`(스트레스 작업보다 큼)

[문제 해결 설명서](../troubleshooting/_index.md#git-over-ssh-the-remote-end-hung-up-unexpectedly)에서 `gitlab.gitlab-shell.resources.limits.memory`가 너무 낮게 설정되면 어떤 일이 발생할 수 있는지에 대한 자세한 내용을 확인하세요.

### 웹서비스 {#webservice}

웹서비스 리소스는 [10k 참조 아키텍처](https://docs.gitlab.com/administration/reference_architectures/10k_users/)를 사용하여 테스트 중에 분석되었습니다. 참고 사항은 [웹서비스 리소스 설명서](../charts/gitlab/webservice/_index.md#resources)에서 찾을 수 있습니다.

### Sidekiq {#sidekiq}

Sidekiq 리소스는 [10k 참조 아키텍처](https://docs.gitlab.com/administration/reference_architectures/10k_users/)를 사용하여 테스트 중에 분석되었습니다. 참고 사항은 [Sidekiq 리소스 설명서](../charts/gitlab/sidekiq/_index.md#resources)에서 찾을 수 있습니다.

### KAS {#kas}

사용자의 필요 사항을 더 알게 될 때까지 사용자가 KAS를 다음과 같은 방식으로 사용할 것으로 예상됩니다.

- **Idle values**
  - 0개 에이전트 연결, 2개 Pod
    - cpu: `10m`
    - 메모리: `55M`
- **Minimal Load**:
  - 1개 에이전트 연결, 2개 Pod
    - cpu: `10m`
    - 메모리: `55M`
- **Average Load**:  1개 에이전트가 클러스터에 연결되어 있습니다.
  - 5개 에이전트 연결, 2개 Pod
    - cpu: `10m`
    - 메모리: `65M`
- **Stressful Task**:
  - 20개 에이전트 연결, 2개 Pod
    - cpu: `30m`
    - 메모리: `95M`
- **Heavy Load**:
  - 50개 에이전트 연결, 2개 Pod
    - cpu: `40m`
    - 메모리: `150M`
- **Extra Heavy Load**:
  - 200개 에이전트 연결, 2개 Pod
    - cpu: `50m`
    - 메모리: `315M`

KAS 리소스 기본값은 50개 에이전트 시나리오도 처리하기에 충분합니다. 우리가 **Extra Heavy Load**라고 간주하는 수준에 도달하려고 계획 중이라면 기본값을 조정하여 확장하는 것을 고려해야 합니다.

- **Defaults**:  각각 2개 Pod
  - cpu: `100m`
  - 메모리: `100M`

이러한 숫자가 어떻게 계산되었는지에 대한 자세한 내용은 [문제 토론](https://gitlab.com/gitlab-org/gitlab/-/issues/296789#note_542196438)을(를) 참조하세요.
