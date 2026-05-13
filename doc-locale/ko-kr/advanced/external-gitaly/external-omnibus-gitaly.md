---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 독립형 Gitaly 설정
---

여기의 지침은 Ubuntu용 [Linux 패키지](https://about.gitlab.com/install/#ubuntu)를 사용합니다. 이 패키지는 차트의 서비스와 호환되도록 보장되는 서비스 버전을 제공합니다.

## Linux 패키지로 VM 생성 {#create-vm-with-the-linux-package}

선택한 제공자에서 또는 로컬로 VM을 생성합니다. VirtualBox, KVM 및 Bhyve를 사용하여 테스트했습니다. 클러스터에서 인스턴스에 도달할 수 있는지 확인합니다.

생성한 VM에 Ubuntu Server를 설치합니다. `openssh-server`이 설치되어 있고 모든 패키지가 최신 상태인지 확인합니다. 네트워킹 및 호스트명을 구성합니다. 호스트명/IP를 기록하고 Kubernetes 클러스터에서 모두 확인 가능하고 도달할 수 있는지 확인합니다. 트래픽을 허용하기 위한 방화벽 정책이 있는지 확인합니다.

[Linux 패키지](https://docs.gitlab.com/install/package/ubuntu/)의 설치 지침을 따릅니다.

> [!note] Linux 패키지 설치를 수행할 때 `EXTERNAL_URL=` 값을 제공하지 마십시오. 자동 구성이 발생하지 않도록 하려고 하며, 다음 단계에서 매우 구체적인 구성을 제공할 것입니다.

## Linux 패키지 설치 구성 {#configure-linux-package-installation}

최소의 `gitlab.rb` 파일을 생성하여 `/etc/gitlab/gitlab.rb`에 배치합니다. 이 노드에서 활성화된 항목에 대해 명확히 하고, [자체 서버에서 Gitaly 실행](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#run-gitaly-on-its-own-server)에 대한 설명서를 기반으로 다음 내용을 사용합니다.

다음 값을 교체해야 합니다:

- `AUTH_TOKEN`을(를) [`gitaly-secret` 비밀](../../installation/secrets.md#gitaly-secret)의 값으로 교체해야 합니다.
- `GITLAB_URL`을(를) GitLab 인스턴스의 URL로 교체해야 합니다.
- `SHELL_TOKEN`을(를) [`gitlab-shell-secret` 비밀](../../installation/secrets.md#gitlab-shell-secret)의 값으로 교체해야 합니다.

<!--
Updates to example must be made at:
- <https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-linux-package-installation>
- <https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/gitaly/configure_gitaly.md#configure-gitaly-server>
- All reference architecture pages
-->

```ruby
# Avoid running unnecessary services on the Gitaly server
postgresql['enable'] = false
redis['enable'] = false
nginx['enable'] = false
puma['enable'] = false
sidekiq['enable'] = false
gitlab_workhorse['enable'] = false
gitlab_exporter['enable'] = false
gitlab_kas['enable'] = false

# If you run a seperate monitoring node you can disable these services
prometheus['enable'] = false
alertmanager['enable'] = false

# If you don't run a separate monitoring node you can
# Enable Prometheus access & disable these extra services
# This makes Prometheus listen on all interfaces. You must use firewalls to restrict access to this address/port.
# prometheus['listen_address'] = '0.0.0.0:9090'
# prometheus['monitor_kubernetes'] = false

# If you don't want to run monitoring services uncomment the following (not recommended)
# node_exporter['enable'] = false

# Prevent database connections during 'gitlab-ctl reconfigure'
gitlab_rails['auto_migrate'] = false

# Configure the gitlab-shell API callback URL. Without this, `git push` will
# fail. This can be your 'front door' GitLab URL or an internal load
# balancer.
gitlab_rails['internal_api_url'] = 'GITLAB_URL'
# Token used by Gitaly and GitLab shell to authenticate with GitLab
gitaly['gitlab_secret'] = 'SHELL_TOKEN'

gitaly['configuration'] = {
    # Make Gitaly accept connections on all network interfaces. You must use
    # firewalls to restrict access to this address/port.
    # Comment out following line if you only want to support TLS connections
    listen_addr: '0.0.0.0:8075',
    # Authentication token to ensure only authorized servers can communicate with
    # Gitaly server
    auth: {
        token: 'AUTH_TOKEN',
    },
    storage: [
      {
         name: 'default',
         path: '/var/opt/gitlab/git-data',
      },
      {
         name: 'storage1',
         path: '/mnt/gitlab/git-data',
      },
   ],
}

# To use TLS for Gitaly you need to add
gitaly['tls_listen_addr'] = "0.0.0.0:8076"
gitaly['certificate_path'] = "path/to/cert.pem"
gitaly['key_path'] = "path/to/key.pem"
```

`gitlab.rb`을 생성한 후 `gitlab-ctl reconfigure`로 패키지를 다시 구성합니다. 작업이 완료되면 `gitlab-ctl status`으로 실행 중인 프로세스를 확인합니다. 출력은 다음과 같이 표시되어야 합니다:

```plaintext
# gitlab-ctl status
run: gitaly: (pid 30562) 77637s; run: log: (pid 30561) 77637s
run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
```
