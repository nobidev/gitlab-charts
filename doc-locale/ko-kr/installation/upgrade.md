---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Helm 차트 인스턴스 업그레이드
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

GitLab Helm 차트 인스턴스를 최신 버전의 GitLab으로 업그레이드하세요.

## 사전 요구 사항 {#prerequisites}

GitLab Helm 차트 인스턴스를 업그레이드하기 전에:

1. [업그레이드 전에 필요한 정보](https://docs.gitlab.com/update/plan_your_upgrade/)를 참조하세요.
1. GitLab Helm 차트 버전이 GitLab 버전과 동일한 번호 지정을 따르지 않으므로 [버전 매핑](version_mappings.md)을 참조하여 필요한 GitLab Helm 차트 버전을 찾으세요.
1. 업그레이드하려는 특정 릴리스에 해당하는 [CHANGELOG](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/CHANGELOG.md)를 참조하세요.
1. GitLab Helm 차트 버전 8.x보다 이전 버전에서 업그레이드하는 경우 [GitLab 문서 아카이브](https://docs.gitlab.com/archives/)를 참조하여 이전 버전의 문서에 액세스하세요.
1. [백업](../backup-restore/_index.md)을 수행하세요.

## GitLab Helm 차트 인스턴스 업그레이드 {#upgrade-a-gitlab-helm-chart-instance}

GitLab Helm 차트 인스턴스를 업그레이드하려면:

1. 업그레이드 중에 [유지 관리 모드 켜기](https://docs.gitlab.com/administration/maintenance_mode/)를 고려하여 사용자의 쓰기 작업을 제한하고 워크플로 방해를 방지합니다.
1. [GitLab Runner 업그레이드](https://docs.gitlab.com/runner/install/)를 대상 GitLab 버전과 동일한 버전으로 수행하세요.
1. 이전에 제공한 값을 추출하세요:

   ```shell
   helm get values gitlab > gitlab.yaml
   ```

1. 업그레이드할 때 유지해야 할 모든 값을 결정하세요. 명시적으로 설정하려는 최소한의 값 집합만 유지하고 업그레이드 프로세스 중에 이를 전달해야 합니다. 그렇지 않으면 GitLab 기본 값을 사용해야 합니다.

### 무중단 업그레이드 {#upgrade-with-zero-downtime}

GitLab 환경을 오프라인으로 전환하지 않고 라이브 업그레이드하세요.

#### 요구 사항 {#requirements}

무중단 업그레이드 프로세스에는 다음이 필요합니다:

- Webservice 및 Sidekiq을 위해 구성된 여러 복제본이 있는 다중 노드 GitLab Helm 차트 배포.
- 한 번에 하나의 마이너 릴리스씩 업그레이드하세요. 따라서 18.0에서 18.1로 업그레이드하되 18.2로는 업그레이드하지 마세요. 릴리스를 건너뛰면 데이터베이스 수정이 잘못된 순서로 실행되어 데이터베이스 스키마가 손상된 상태로 남을 수 있습니다.

#### 고려 사항 {#considerations}

무중단 업그레이드를 고려할 때 다음에 주의하세요:

- Kubernetes의 Gitaly는 [클라이언트 재시도를 통한](https://docs.gitlab.com/administration/settings/gitaly_timeouts/#gitaly-client-retries) 무중단 업그레이드를 지원합니다.
- 대부분의 경우 패치 릴리스가 최신이 아닌 경우 패치 릴리스에서 다음 마이너 릴리스로 안전하게 업그레이드할 수 있습니다. 예를 들어 18.0.5에서 18.1.0으로 업그레이드하는 것은 18.0.6이 존재하더라도 안전해야 합니다. 업그레이드하려는 버전에 대한 [버전별 업그레이드](https://docs.gitlab.com/update/versions/) 정보를 확인하시기를 권장합니다.
- 롤링 업데이트 중에 이전 포드와 새 포드를 동시에 실행할 수 있는 충분한 리소스가 배포에 있는지 확인하세요. 필요한 추가 리소스의 양은 maxSurge 설정에 따라 다릅니다. 예를 들어 maxSurge: 포함:  10%인 경우 새 포드가 사용할 10% 추가 용량이 필요합니다.

#### 권장 배포 설정 {#recommended-deployment-settings}

부드러운 롤링 업데이트를 보장하려면 아래 설정이 업그레이드 프로세스를 제어하고 무중단을 달성하기 위해 필요합니다.

이 설정은 기본 권장사항입니다. 배포의 리소스 가용성, 복제본 수 및 성능 요구사항에 따라 조정해야 합니다. `maxSurge` 설정을 지원할 충분한 클러스터 리소스가 있는지 확인하세요. 이 설정은 업그레이드 중에 추가 포드를 임시로 생성합니다.

> [!warning] 기존 GitLab 배포에 이 롤링 업데이트 설정이 구성되지 않은 경우 무중단 업그레이드를 시도하기 전에 적용해야 합니다. 이 설정을 처음 적용하면 포드의 롤링 재시작이 트리거되어 서비스 중단이 발생할 수 있습니다.
>
> 영향을 최소화하려면 계획된 업그레이드 전에 유지 관리 창 중에 이 설정을 적용하세요. 구성된 후에는 향후 업그레이드를 무중단으로 수행할 수 있습니다.

  ```yaml
  global:
    extraEnv:
      BYPASS_SCHEMA_VERSION: true
  gitlab:
    webservice:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 60
    sidekiq:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 600
    gitlab-shell:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 60
    registry:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 60

  nginx-ingress:
    controller:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 300
      minReadySeconds: 10
  ```

> [!note] Sidekiq에 대해 `terminationGracePeriodSeconds`을 구성할 때 가장 오래 실행되는 작업을 고려하여 유예 기간이 만료되기 전에 충분한 시간이 있는지 확인해야 합니다.

이 설정은 다음을 보장합니다:

- 업데이트 중에 최소한 하나의 포드는 항상 사용 가능합니다.
- 새 포드는 기존 포드가 종료되기 전에 시작됩니다.
- 포드는 정상 종료하고 연결을 드레인할 시간이 있습니다.
- 포드는 준비된 것으로 간주되기 전에 안정적입니다.

#### 업그레이드 프로세스 {#upgrade-process}

> [!note] 아래에 사용된 배포 이름은 기본 GitLab Helm 차트 설치를 기반으로 한 예입니다. 배포 이름은 여러 Sidekiq 큐를 배포할 때와 같이 구성에 따라 다를 수 있습니다.
>
> 설치에 대한 올바른 배포 이름을 찾으려면:
>
> ```shell
> kubectl get deployments -lapp=webservice -n <namespace>
> kubectl get deployments -lapp=sidekiq -n <namespace>
> ```

GitLab을 업그레이드하려면:

1. 배포를 일시 중지하세요:

   ```shell
   kubectl rollout pause deployment/gitlab-webservice-default
   kubectl rollout pause deployment/gitlab-sidekiq-all-in-1-v2
   ```

1. 새 버전으로 업그레이드를 시작하세요:

   ```shell
   helm upgrade gitlab gitlab/gitlab \
   --version <GitLab Helm chart version> \
   -f values.yaml \
   --set gitlab.migrations.extraEnv.SKIP_POST_DEPLOYMENT_MIGRATIONS=true
   ```

1. 사전 마이그레이션 및 업그레이드가 완료될 때까지 기다리세요:

   ```shell
   kubectl get jobs -lrelease=gitlab,chart=migrations-<GitLab version> -n <namespace>
   kubectl wait --for=condition=complete job/<job name> --timeout=600s
   ```

1. Sidekiq의 배포를 재개하세요:

   ```shell
   kubectl rollout resume deployment/gitlab-sidekiq-all-in-1-v2
   kubectl rollout status deployment/gitlab-sidekiq-all-in-1-v2 --timeout=15m
   ```

1. Webservice의 배포를 재개하세요:

   ```shell
   kubectl rollout resume deployment/gitlab-webservice-default
   kubectl rollout status deployment/gitlab-webservice-default --timeout=15m
   ```

1. 마이그레이션 후 실행:

   ```shell
   helm upgrade gitlab gitlab/gitlab \
   --version <GitLab Helm chart version> \
   -f values.yaml
   ```

1. 마이그레이션 후 작업이 완료될 때까지 기다리세요:

   ```shell
   kubectl get jobs -lrelease=gitlab,chart=migrations-<GitLab version> -n <namespace>
   kubectl wait --for=condition=complete job/<job name> --timeout=600s
   ```

   > [!note] 배포에 따라 마이그레이션을 완료하기 위한 `600s` 대기 시간이 충분하지 않을 수 있습니다. 이 시간 초과를 늘리거나 정기적으로 작업을 확인하여 다음 단계로 진행하기 전에 완료되었는지 확인할 수 있습니다.

### 중단 포함 업그레이드 {#upgrade-with-downtime}

1. 이전 단계에서 추출하고 검토한 값을 사용하여 업그레이드를 수행하세요:

   ```shell
   helm upgrade gitlab gitlab/gitlab \
   --version <new version> \
   -f gitlab.yaml \
   --set gitlab.migrations.enabled=true \
   --set ...
   ```

   주요 데이터베이스 업그레이드 중에 `gitlab.migrations.enabled`을 `false`로 설정해야 합니다. 향후 업데이트를 위해 명시적으로 `true`로 다시 설정해야 합니다.

## 업그레이드 후 {#after-you-upgrade}

1. 활성화된 경우 [유지 관리 모드 끄기](https://docs.gitlab.com/administration/maintenance_mode/#disable-maintenance-mode)를 수행합니다.
1. [업그레이드 상태 확인](https://docs.gitlab.com/update/plan_your_upgrade/#run-upgrade-health-checks)을 실행합니다.

## 관련 항목 {#related-topics}

1. [Linux 패키지 설치를 위한 무중단 업그레이드](https://docs.gitlab.com/update/zero_downtime/)
1. [업그레이드 경로](https://docs.gitlab.com/update/upgrade_paths/)
1. [GitLab 업그레이드 정보](https://docs.gitlab.com/update/versions/)
