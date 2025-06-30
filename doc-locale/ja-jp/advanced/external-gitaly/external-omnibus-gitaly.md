---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スタンドアロンGitalyの設定
---

この手順では、Ubuntu用の[Linuxパッケージ](https://about.gitlab.com/install/#ubuntu)を使用します。このパッケージは、chartsのサービスとの互換性が保証されているサービスのバージョンを提供します。

## 仮想マシンをLinuxパッケージで作成 {#create-vm-with-the-linux-package}

任意のプロバイダーで、またはローカルで仮想マシンを作成します。これは、VirtualBox、KVM、Bhyveでテストされました。インスタンスがクラスターから到達可能であることを確認してください。

作成した仮想マシンにUbuntu Serverをインストールします。`openssh-server`がインストールされていること、およびすべてのパッケージが最新の状態であることを確認してください。ネットワーク構築とホスト名を設定します。ホスト名/IPをメモし、それがKubernetesクラスターから解決可能で、到達可能であることを確認します。トラフィックを許可するために、ファイアウォールポリシーが適切に設定されていることを確認してください。

[Linuxパッケージ](https://about.gitlab.com/install/#ubuntu)のインストール手順に従ってください。Linuxパッケージのインストールを実行するときは、行わないでください、`EXTERNAL_URL=`の値を指定します。次の手順で非常に具体的な設定を行うため、自動設定は不要です。

## Linuxパッケージのインストールを設定 {#configure-linux-package-installation}

最小限の`gitlab.rb`ファイルを`/etc/gitlab/gitlab.rb`に配置するように作成します。*非常に*、このノードで有効になっていることを明示的に指定します。[Gitalyを独自のサーバー上で実行](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#run-gitaly-on-its-own-server)するためのドキュメントに基づいた次のコンテンツを使用します。

注: 以下の値は置き換える必要があります_

- `AUTH_TOKEN`を[`gitaly-secret`シークレット](../../installation/secrets.md#gitaly-secret)の値に置き換える必要があります
- `GITLAB_URL`は、GitLabインスタンスのURLに置き換える必要があります
- `SHELL_TOKEN`を[`gitlab-shell-secret`シークレット](../../installation/secrets.md#gitlab-shell-secret)の値に置き換える必要があります

<!--
Updates to example must be made at:
- https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-omnibus-gitlab
- https://gitlab.com/gitlab-org/gitlab/blob/master/doc/administration/gitaly/index.md#gitaly-server-configuration
- all reference architecture pages
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
}

git_data_dirs({
 'default' => {
   'path' => '/var/opt/gitlab/git-data'
 },
 'storage1' => {
   'path' => '/mnt/gitlab/git-data'
 },
})

# To use TLS for Gitaly you need to add
gitaly['tls_listen_addr'] = "0.0.0.0:8076"
gitaly['certificate_path'] = "path/to/cert.pem"
gitaly['key_path'] = "path/to/key.pem"
```

`gitlab.rb`を作成したら、`gitlab-ctl reconfigure`を使用してパッケージを再設定します。タスクが完了したら、`gitlab-ctl status`を使用して実行中のプロセスを確認します。出力は次のようになります。

```plaintext
# gitlab-ctl status
run: gitaly: (pid 30562) 77637s; run: log: (pid 30561) 77637s
run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
```
