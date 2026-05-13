---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 독립 실행형 PostgreSQL 데이터베이스 설정
---

[Linux 패키지](https://about.gitlab.com/install/#ubuntu)를 Ubuntu용으로 사용할 것입니다. 이 패키지는 차트의 서비스와 호환되도록 보장되는 서비스 버전을 제공합니다.

## Linux 패키지로 VM 생성 {#create-vm-with-the-linux-package}

선택한 제공자에서 또는 로컬로 VM을 생성합니다. VirtualBox, KVM 및 Bhyve를 사용하여 테스트했습니다. 클러스터에서 인스턴스에 도달할 수 있는지 확인합니다.

생성한 VM에 Ubuntu Server를 설치합니다. `openssh-server`이 설치되어 있고 모든 패키지가 최신 상태인지 확인합니다. 네트워킹 및 호스트명을 구성합니다. 호스트명/IP를 기록하고 Kubernetes 클러스터에서 모두 확인 가능하고 도달할 수 있는지 확인합니다. 트래픽을 허용하기 위한 방화벽 정책이 있는지 확인합니다.

[Linux 패키지](https://docs.gitlab.com/install/package/ubuntu/)의 설치 지침을 따릅니다.

> [!note] 패키지 설치를 수행할 때 `EXTERNAL_URL=` 값을 제공하지 마세요. 자동 구성이 발생하지 않도록 하려고 하며, 다음 단계에서 매우 구체적인 구성을 제공할 것입니다.

## Linux 패키지 설치 구성 {#configure-linux-package-installation}

최소의 `gitlab.rb` 파일을 생성하여 `/etc/gitlab/gitlab.rb`에 배치합니다. 이 노드에서 활성화되는 내용에 대해 매우 명시적으로 명시하고 아래 내용을 사용합니다.

이 예는 [PostgreSQL for scaling](https://docs.gitlab.com/administration/postgresql/)을 제공하는 것을 의도하지 않았습니다.

다음 값을 교체해야 합니다:

- `DB_USERNAME` 기본 사용자명은 `gitlab`
- `DB_PASSSWORD` 인코딩되지 않은 값
- `DB_ENCODED_PASSWORD`은(는) `DB_PASSWORD`의 인코딩된 값입니다. `DB_USERNAME` 및 `DB_PASSWORD`를 실제 값으로 바꾸어 생성할 수 있습니다: `echo -n 'DB_PASSSWORDDB_USERNAME' | md5sum - | cut -d' ' -f1`
- `AUTH_CIDR_ADDRESS` MD5 인증을 위한 CIDR을 구성하며, 클러스터 또는 게이트웨이의 가장 작은 가능한 서브넷이어야 합니다. minikube의 경우 이 값은 `192.168.100.0/12`

```ruby
# Change the address below if you do not want PG to listen on all available addresses
postgresql['listen_address'] = '0.0.0.0'
# Set to approximately 1/4 of available RAM.
postgresql['shared_buffers'] = "512MB"
# This password is: `echo -n '${password}${username}' | md5sum - | cut -d' ' -f1`
# The default username is `gitlab`
postgresql['sql_user_password'] = "DB_ENCODED_PASSWORD"
# Configure the CIDRs for MD5 authentication
postgresql['md5_auth_cidr_addresses'] = ['AUTH_CIDR_ADDRESSES']
# Configure the CIDRs for trusted authentication (passwordless)
postgresql['trust_auth_cidr_addresses'] = ['127.0.0.1/24']

## Configure gitlab_rails
gitlab_rails['auto_migrate'] = false
gitlab_rails['db_username'] = "gitlab"
gitlab_rails['db_password'] = "DB_PASSSWORD"


## Disable everything else
sidekiq['enable'] = false
puma['enable'] = false
registry['enable'] = false
gitaly['enable'] = false
gitlab_workhorse['enable'] = false
nginx['enable'] = false
prometheus_monitoring['enable'] = false
redis['enable'] = false
gitlab_kas['enable'] = false
```

`gitlab.rb`을(를) 생성한 후 `gitlab-ctl reconfigure`으로 패키지를 재구성합니다. 작업이 완료되면 `gitlab-ctl status`으로 실행 중인 프로세스를 확인합니다. 출력은 다음과 같이 표시되어야 합니다:

```plaintext
# gitlab-ctl status
run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
run: postgresql: (pid 30562) 77637s; run: log: (pid 30561) 77637s
```
