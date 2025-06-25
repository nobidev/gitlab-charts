---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: スタンドアロンRedisの設定
---

ここで説明する手順では、Ubuntuの[Linuxパッケージ](https://about.gitlab.com/install/#ubuntu)を使用します。このパッケージは、チャートのサービスと互換性があることが保証されているサービスのバージョンを提供します。

## LinuxパッケージでVMを作成する {#create-vm-with-the-linux-package}

お好みのプロバイダーまたはローカルで仮想マシン（VM）を作成します。これは、VirtualBox、KVM、およびBhyveでテストされました。インスタンスがクラスターから到達可能であることを確認してください。

作成した仮想マシン（VM）にUbuntu Serverをインストールします。`openssh-server`がインストールされていること、およびすべてのパッケージが最新であることを確認してください。ネットワーク構築とホスト名を設定します。ホスト名/アドレスをメモし、それがKubernetesクラスターから解決可能で、到達可能であることを確認します。トラフィックを許可するようにファイアウォールポリシーが設定されていることを確認してください。

[Linuxパッケージ](https://about.gitlab.com/install/#ubuntu)のインストール手順に従ってください。パッケージのインストールを実行するときは、**___** `EXTERNAL_URL=`値を指定しないでください。次の手順で非常に具体的な設定を行うため、自動設定は不要です。

## Linuxパッケージインストールの設定 {#configure-linux-package-installation}

`/etc/gitlab/gitlab.rb`に配置される最小限の`gitlab.rb`ファイルを作成します。このノードで有効になっているものを___明示的に指定し、以下の内容を使用します。

{{< alert type="note" >}}

この例は、[スケーリング用のRedis](https://docs.gitlab.com/administration/redis/)を提供することを目的としていません。

{{< /alert >}}

- `REDIS_PASSWORD`は、[`gitlab-redis`シークレット](../../installation/secrets.md#redis-password)の値に置き換える必要があります。

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

`gitlab.rb`を作成したら、`gitlab-ctl reconfigure`でパッケージを再設定します。タスクが完了したら、`gitlab-ctl status`で実行中のプロセスを確認します。出力は次のように表示されます。

```plaintext
# gitlab-ctl status
run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
run: redis: (pid 30562) 77637s; run: log: (pid 30561) 77637s
```
