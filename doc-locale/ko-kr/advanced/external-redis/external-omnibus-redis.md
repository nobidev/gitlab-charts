---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 독립형 Redis 설정
---

여기의 지침은 Ubuntu용 [Linux 패키지](https://about.gitlab.com/install/#ubuntu)를 사용합니다. 이 패키지는 차트의 서비스와 호환되도록 보장되는 서비스 버전을 제공합니다.

## Linux 패키지로 VM 생성 {#create-vm-with-the-linux-package}

선택한 제공자에서 또는 로컬로 VM을 생성합니다. VirtualBox, KVM 및 Bhyve를 사용하여 테스트했습니다. 클러스터에서 인스턴스에 도달할 수 있는지 확인합니다.

생성한 VM에 Ubuntu Server를 설치합니다. `openssh-server`이 설치되어 있고 모든 패키지가 최신 상태인지 확인합니다. 네트워킹 및 호스트명을 구성합니다. 호스트명/IP를 기록하고 Kubernetes 클러스터에서 모두 확인 가능하고 도달할 수 있는지 확인합니다. 트래픽을 허용하기 위한 방화벽 정책이 있는지 확인합니다.

[Linux 패키지](https://docs.gitlab.com/install/package/ubuntu/)의 설치 지침을 따릅니다.

> [!note]
> 패키지 설치를 수행할 때 `EXTERNAL_URL=` 값을 제공하지 마세요. 자동 구성이 발생하지 않도록 하려고 하며, 다음 단계에서 매우 구체적인 구성을 제공할 것입니다.

## Linux 패키지 설치 구성 {#configure-linux-package-installation}

최소의 `gitlab.rb` 파일을 생성하여 `/etc/gitlab/gitlab.rb`에 배치합니다. 이 노드에서 활성화된 항목에 대해 _매우_ 명시적이며, 아래 내용을 사용합니다.

> [!note]
> 이 예시는 [Redis for scaling](https://docs.gitlab.com/administration/redis/)을 제공하기 위한 것이 아닙니다.

- `REDIS_PASSWORD`을 [`gitlab-redis` secret](../../installation/secrets.md#redis-password)의 값으로 바꿔야 합니다.

```Ruby
# Listen on all addresses
redis['bind'] = '0.0.0.0'
# Set the defaul port, must be set.
redis['port'] = 6379
# Set password, as in the secret `gitlab-redis` populated in Kubernetes
redis['password'] = 'REDIS_PASSWORD'

## Disable everything else
gitlab_rails['enable'] = false
sidekiq['enable'] = false
puma['enable']=false
registry['enable'] = false
gitaly['enable'] = false
gitlab_workhorse['enable'] = false
nginx['enable'] = false
prometheus_monitoring['enable'] = false
postgresql['enable'] = false
```

`gitlab.rb`을 생성한 후 `gitlab-ctl reconfigure`로 패키지를 다시 구성합니다. 작업이 완료된 후 `gitlab-ctl status`로 실행 중인 프로세스를 확인합니다. 출력은 다음과 유사하게 표시되어야 합니다:

```plaintext
# gitlab-ctl status
run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
run: redis: (pid 30562) 77637s; run: log: (pid 30561) 77637s
```
