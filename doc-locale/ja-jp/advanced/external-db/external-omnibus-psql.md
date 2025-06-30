---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スタンドアロンのPostgreSQLデータベースをセットアップ
---

Ubuntu用の[Linuxパッケージ](https://about.gitlab.com/install/#ubuntu)を利用します。このパッケージは、のサービスと互換性があることが保証されているサービスのを提供します。

## LinuxパッケージでVMを作成 {#create-vm-with-the-linux-package}

任意のプロバイダーで、またはローカルでを作成します。これは、VirtualBox、KVM、およびBhyveでテストされました。がから到達可能であることを確認します。

作成したにUbuntu Serverをインストールします。`openssh-server`がインストールされていること、およびすべてのが最新であることを確認します。とホスト名を設定します。ホスト名/ をメモし、それがKubernetesから解決可能で、到達可能であることを確認します。トラフィックを許可するために、ファイアウォールが適切に設定されていることを確認してください。

[Linuxパッケージ](https://about.gitlab.com/install/#ubuntu)のインストール手順に従ってください。パッケージのインストールを実行するときは、しないでください`EXTERNAL_URL=`値を指定します。次の手順で非常に具体的なを提供するので、自動が発生しないようにします。

## Linuxパッケージのインストールを設定 {#configure-linux-package-installation}

最小限の`gitlab.rb`ファイルを作成して、`/etc/gitlab/gitlab.rb`に配置します。こので何が有効になっているかを非常に明確にし、以下のコンテンツを使用してください。

*ノート*:この例は、[スケーリング用のPostgreSQL](https://docs.gitlab.com/administration/postgresql/)を提供するものではありません。

注:以下の値は置き換える必要があります

- `DB_USERNAME`デフォルトのユーザー名は`gitlab`です
- `DB_PASSSWORD`エンコードされていない
- `DB_ENCODED_PASSWORD``DB_PASSWORD`のエンコードされた。`DB_USERNAME`と`DB_PASSWORD`を次の実際のに置き換えることで生成できます: `echo -n 'DB_PASSSWORDDB_USERNAME' | md5sum - | cut -d' ' -f1`
- `AUTH_CIDR_ADDRESS` MD5用のCIDRを設定します。これは、またはそのゲートウェイの可能な限り小さいサブネットである必要があります。minikubeの場合、この値は`192.168.100.0/12`です

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

`gitlab.rb`を作成したら、`gitlab-ctl reconfigure`でを再設定します。タスクが完了したら、`gitlab-ctl status`で実行中のプロセスを確認します。は次のようになります:

```plaintext
# gitlab-ctl status
run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
run: postgresql: (pid 30562) 77637s; run: log: (pid 30561) 77637s
```
