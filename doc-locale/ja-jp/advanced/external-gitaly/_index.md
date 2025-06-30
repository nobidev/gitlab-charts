---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部GitalyでGitLabチャートを設定する
---

このドキュメントは、このHelm Chartを外部Gitalyサービスで設定する方法について説明することを目的としています。

Gitalyが設定されていない場合は、オンプレミスまたはVMへのデプロイメントについて、[Linuxパッケージ](external-omnibus-gitaly.md)の使用を検討してください。

{{< alert type="note" >}}

外部Gitaly _サービス_は、Gitalyノードまたは[Praefect](https://docs.gitlab.com/administration/gitaly/praefect/)クラスターによって提供できます。

{{< /alert >}}

## チャートを設定する {#configure-the-chart}

`gitaly`チャートと、提供されているGitalyサービスを無効にし、他のサービスを外部サービスに向けるようにします。

次のプロパティを設定する必要があります。

- `global.gitaly.enabled`: `false`に設定して、含まれているGitaly Chartを無効にします。
- `global.gitaly.external`: これは、[外部Gitalyサービス](../../charts/globals.md#external)の配列です。
- `global.gitaly.authToken.secret`: [認証用のトークンを含むシークレット](../../installation/secrets.md#gitaly-secret)の名前。
- `global.gitaly.authToken.key`: トークンのコンテンツを含むシークレット内のキー。

外部Gitalyサービスは、GitLab Shellの独自のインスタンスを使用します。実装によっては、このChartのシークレットを使用してそれらを構成することも、定義済みのソースからのコンテンツを使用してこのChartのシークレットを構成することもできます。

次のプロパティの設定が必要になる**場合**があります。

- `global.shell.authToken.secret`: [GitLab Shellのシークレットを含むシークレット](../../installation/secrets.md#gitlab-shell-secret)の名前。
- `global.shell.authToken.key`: シークレットのコンテンツを含むシークレット内のキー。

2つの外部サービスを含む完全な構成例（`external-gitaly.yml`）。

```yaml
global:
  gitaly:
    enabled: false
    external:
      - name: default                   # required
        hostname: node1.git.example.com # required
        port: 8075                      # optional, default shown
      - name: praefect                  # required
        hostname: ha.git.example.com    # required
        port: 2305                      # Praefect uses port 2305
        tlsEnabled: false               # optional, overrides gitaly.tls.enabled
    authToken:
      secret: external-gitaly-token     # required
      key: token                        # optional, default shown
    tls:
      enabled: false                    # optional, default shown
```

`gitlab.yml`を介して他の構成と組み合わせて上記の構成ファイルを使用するインストール例:

```shell
helm upgrade --install gitlab gitlab/gitlab  \
  -f gitlab.yml \
  -f external-gitaly.yml
```

## 複数の外部Gitaly {#multiple-external-gitaly}

実装で、これらのChartの外部にある複数のGitalyノードを使用する場合は、複数のホストを定義することもできます。構文は、必要な複雑さを許容するために、若干異なります。

適切な設定セットを示す[値のサンプルファイル](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-external.yaml)が用意されています。この値ファイルの内容は`--set`引数では正しく解釈されないため、`-f / --values`フラグを指定してHelmに渡す必要があります。

### TLS経由で外部Gitalyに接続する {#connecting-to-external-gitaly-over-tls}

外部[GitalyサーバーがTLSポート経由でリッスン](https://docs.gitlab.com/administration/gitaly/#enable-tls-support)している場合は、GitLabインスタンスがTLS経由で通信するように設定できます。これを行うには、次の手順に従ってください。

1. Gitalyサーバーの証明書を含むKubernetesシークレットを作成します

   ```shell
   kubectl create secret generic gitlab-gitaly-tls-certificate --from-file=gitaly-tls.crt=<path to certificate>
   ```

1. [カスタム認証局](../../charts/globals.md#custom-certificate-authorities)のリストに外部Gitalyサーバーの証明書を追加します。値ファイルで、以下を指定します

   ```yaml
   global:
     certificates:
       customCAs:
         - secret: gitlab-gitaly-tls-certificate
   ```

   または、`--set`を使用して、`helm upgrade`コマンドに渡します

   ```shell
   --set global.certificates.customCAs[0].secret=gitlab-gitaly-tls-certificate
   ```

1. すべてのGitalyインスタンスに対してTLSを有効にするには、`global.gitaly.tls.enabled: true`を設定します。

   ```yaml
   global:
     gitaly:
       tls:
         enabled: true
   ```

   インスタンスごとに有効にするには、そのエントリに`tlsEnabled: true`を設定します。

   ```yaml
   global:
     gitaly:
       external:
         - name: default
           hostname: node1.git.example.com
           tlsEnabled: true
   ```

{{< alert type="note" >}}

これには有効なシークレット名とキーを任意に選択できますが、シークレット内のすべてのキーがマウントされるため、`customCAs`で指定されたすべてのシークレット間でキーが一意であることを確認してください。これは_クライアント側_であるため、証明書のキーを指定する**必要はありません**。

{{< /alert >}}

## GitLabがGitalyに接続できることをテストする {#test-that-gitlab-can-connect-to-gitaly}

GitLabが外部Gitalyサーバーに接続できることを確認するには:

```shell
kubectl exec -it <toolbox-pod> -- gitlab-rake gitlab:gitaly:check
```

TLSでGitalyを使用している場合は、GitLab ChartがGitaly証明書を信頼しているかどうかを確認することもできます。

```shell
kubectl exec -it <toolbox-pod> -- echo | /usr/bin/openssl s_client -connect <gitaly-host>:<gitaly-port>
```

## Gitaly Chartから外部Gitalyへの移行 {#migrate-from-gitaly-chart-to-external-gitaly}

Gitaly Chartを使用してGitalyサービスを提供しており、すべてのリポジトリを外部Gitalyサービスに移行する必要がある場合は、次のいずれかの方法で実行できます。

- [リポジトリストレージ移動APIで移行する（推奨）](#migrate-with-the-repository-storage-moves-api)。
- [バックアップ/復元方式で移行する](#migrate-with-the-backuprestore-method)。

### リポジトリストレージ移動APIを使用した移行 {#migrate-with-the-repository-storage-moves-api}

この方法:

- [リポジトリストレージ移動API](https://docs.gitlab.com/api/project_repository_storage_moves/)を使用して、リポジトリをGitaly Chartから外部Gitalyサービスに移行します。
- ダウンタイムなしで実行できます。
- 外部GitalyサービスがGitalyポッドと同じVPC/ゾーン内にある必要があります。
- [Praefect Chart](../../charts/gitlab/praefect/_index.md)ではテストされておらず、サポートされていません。

#### ステップ1:外部GitalyサービスまたはGitalyクラスターをセットアップする {#step-1-set-up-external-gitaly-service-or-gitaly-cluster}

[外部Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/)または[外部Gitalyクラスター](https://docs.gitlab.com/administration/gitaly/praefect/)をセットアップします。これらのステップの一部として、ChartインストールからのGitalyトークンとGitLab Shellシークレットを提供する必要があります:

```shell
# Get the GitLab Shell secret
kubectl get secret <release>-gitlab-shell-secret -ojsonpath='{.data.secret}' | base64 -d

# Get the Gitaly token
kubectl get secret <release>-gitaly-secret -ojsonpath='{.data.token}' | base64 -d
```

{{< tabs >}}

{{< tab title="Gitaly" >}}

- ここで抽出されたGitalyトークンは、`AUTH_TOKEN`の値に使用する必要があります。
- ここで抽出されたGitLab Shellシークレットは、`shellsecret`の値に使用する必要があります。

{{< /tab >}}

{{< tab title="Gitalyクラスター" >}}

- ここで抽出されたGitalyトークンは、`PRAEFECT_EXTERNAL_TOKEN`に使用する必要があります。
- ここで抽出されたGitLab Shellシークレットは、`GITLAB_SHELL_SECRET_TOKEN`に使用する必要があります。

{{< /tab >}}

{{< /tabs >}}

最後に、外部Gitalyサービスのファイアウォールが、構成されたGitalyポートでKubernetesポッドIP範囲のトラフィックを許可していることを確認します。

#### ステップ2: 新しいGitalyサービスを使用するようにインスタンスを設定する {#step-2-configure-instance-to-use-new-gitaly-service}

1. 外部Gitalyを使用するようにGitLabを設定します。メインの`gitlab.yml`設定ファイルにGitalyへの参照がある場合は、それらを削除し、次の内容で新しい`mixed-gitaly.yml`ファイルを作成します。

   以前に追加のGitalyストレージを定義した場合は、新しい設定で同じ名前の一致するGitalyストレージが指定されていることを確認する必要があります。そうしない場合、復元操作は失敗します。

   TLSを構成する場合は、[TLS経由で外部Gitalyへの接続](#connecting-to-external-gitaly-over-tls)セクションを参照してください:

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```yaml
   global:
     gitaly:
       internal:
         names:
           - default
       external:
         - name: ext-gitaly                # required
           hostname: node1.git.example.com # required
           port: 8075                      # optional, default shown
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

   {{< /tab >}}

   {{< tab title="Gitalyクラスター" >}}

   ```yaml
   global:
     gitaly:
       internal:
         names:
           - default
       external:
         - name: ext-gitaly-cluster        # required
           hostname: ha.git.example.com    # required
           port: 2305                      # Praefect uses port 2305
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. `gitlab.yml`ファイルと`mixed-gitaly.yml`ファイルを使用して、新しい設定を適用します:

   ```shell
   helm upgrade --install gitlab gitlab/gitlab \
     -f gitlab.yml \
     -f mixed-gitaly.yml
   ```

1. Toolboxポッドで、GitLabが外部Gitalyに正常に接続できることを確認します:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:gitaly:check
   ```

1. 外部GitalyがChartインストールに接続できることを確認します:

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   GitalyサービスがGitLab APIへのコールバックを正常に実行できることを確認します:

   ```shell
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

   {{< /tab >}}

   {{< tab title="Gitalyクラスター" >}}

   すべてのPraefectノードで、PraefectサービスがGitalyノードに接続できることを確認します:

   ```shell
   # Run on Praefect nodes
   sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dial-nodes
   ```

   すべてのGitalyノードで、GitalyサービスがGitLab APIへのコールバックを正常に実行できることを確認します:

   ```shell
   # Run on Gitaly nodes
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

      {{< /tab >}}

   {{< /tabs >}}

#### ステップ3G: italyポッドのIPとホスト名を取得する {#step-3-get-the-gitaly-pod-ip-and-hostnames}

リポジトリストレージ移動APIを成功させるには、外部Gitalyサービスがポッドサービスホスト名を使用してGitalyポッドに接続できる必要があります。ポッドサービスホスト名を解決できるようにするには、Gitalyプロセスを実行している各外部Gitalyサービスのhostsファイルにホスト名を追加する必要があります。

1. Gitalyポッドのリストと、それぞれの内部IPアドレス/ホスト名をフェッチします:

   ```shell
   kubectl get pods -l app=gitaly -o jsonpath='{range .items[*]}{.status.podIP}{"\t"}{.spec.hostname}{"."}{.spec.subdomain}{"."}{.metadata.namespace}{".svc\n"}{end}'
   ```

1. Gitalyプロセスを実行している各外部Gitalyサービスの`/etc/hosts`ファイルに、最後のステップからの出力を追加します。
1. Gitalyポッドのホスト名が、Gitalyプロセスを実行している各外部Gitalyサービスからpingできることを確認します:

   ```shell
   ping <gitaly pod hostname>
   ```

接続が確認されたら、リポジトリストレージの移動のスケジュールに進むことができます。

#### ステップ4: リポジトリストレージの移動をスケジュールする {#step-4-schedule-the-repository-storage-move}

[リポジトリの移動](https://docs.gitlab.com/administration/operations/moving_repositories/#moving-repositories)で示されているステップに従って、移動をスケジュールします。

#### ステップ5: 最終的な設定と検証 {#step-5-final-configuration-and-validation}

1. 複数のGitalyストレージがある場合は、[新しいリポジトリの保存場所を設定](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored)します。

1. 外部Gitaly構成を含む、将来のために統合された`gitlab.yml`を生成することを検討してください:

   ```shell
   helm get values <RELEASE_NAME> -o yaml > gitlab.yml
   ```

1. `gitlab.yml`ファイルで内部Gitalyサブチャートを無効にし、新しい`default`リポジトリストレージを外部Gitalyサービスに向けます。[GitLabにはデフォルトのリポジトリストレージが必要です](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#gitlab-requires-a-default-repository-storage):

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```yaml
   global:
     gitaly:
       enabled: false                      # Disable the internal Gitaly subchart
       external:
         - name: ext-gitaly                # required
           hostname: node1.git.example.com # required
           port: 8075                      # optional, default shown
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
         - name: default                   # Add the default repository storage, use the same settings as ext-gitaly
           hostname: node1.git.example.com
           port: 8075
           tlsEnabled: false
   ```

   {{< /tab >}}

   {{< tab title="Gitalyクラスター" >}}

   ```yaml
   global:
     gitaly:
       enabled: false                      # Disable the internal Gitaly subchart
       external:
         - name: ext-gitaly-cluster        # required
           hostname: ha.git.example.com    # required
           port: 2305                      # Praefect uses port 2305
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
         - name: default                   # Add the default repository storage, use the same settings as ext-gitaly-cluster
           hostname: ha.git.example.com
           port: 2305
           tlsEnabled: false
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. 新しい設定を適用します:

   ```shell
   helm upgrade --install gitlab gitlab/gitlab \
     -f gitlab.yml
   ```

1. オプション。[GitalyポッドのIPとホスト名を取得する](#step-3-get-the-gitaly-pod-ip-and-hostnames)ステップに従って、各外部Gitaly `/etc/hosts`ファイルに加えられた変更を削除します。

1. すべてが期待どおりに動作していることを確認したら、Gitaly PVCを削除できます:

   警告:すべてが期待どおりに動作していることを再確認するまで、Gitaly PVCを削除しないでください。

   ```shell
   kubectl delete pvc repo-data-<release>-gitaly-0
   ```

### バックアップ/復元方式で移行する {#migrate-with-the-backuprestore-method}

この方法:

- リポジトリをGitaly Chart PersistentVolumeClaim (PVC) からバックアップし、それらを外部Gitalyサービスに復元します。
- すべてのユーザーにダウンタイムが発生します。
- [Praefect Chart](../../charts/gitlab/praefect/_index.md)ではテストされておらず、サポートされていません。

#### ステップ1: GitLab Chartの現在のリリースのリビジョンを取得する {#step-1-get-the-current-release-revision-of-the-gitlab-chart}

移行中に問題が発生する可能性は低いですが、GitLab Chartの現在のリリースのリビジョンを取得してください。出力をコピーして、[ロールバック](#rollback)を実行する必要がある場合に備えて、脇に置いてください:

```shell
helm history <release> --max=1
```

#### ステップ2: 外部GitalyサービスまたはGitalyクラスターをセットアップする {#step-2-setup-external-gitaly-service-or-gitaly-cluster}

[外部Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/)または[外部Gitalyクラスター](https://docs.gitlab.com/administration/gitaly/praefect/)をセットアップします。これらのステップの一部として、ChartインストールからのGitalyトークンとGitLab Shellシークレットを提供する必要があります:

```shell
# Get the GitLab Shell secret
kubectl get secret <release>-gitlab-shell-secret -ojsonpath='{.data.secret}' | base64 -d

# Get the Gitaly token
kubectl get secret <release>-gitaly-secret -ojsonpath='{.data.token}' | base64 -d
```

{{< tabs >}}

{{< tab title="Gitaly" >}}

- ここで抽出されたGitalyトークンは、`AUTH_TOKEN`の値に使用する必要があります。
- ここで抽出されたGitLab Shellシークレットは、`shellsecret`の値に使用する必要があります。

{{< /tab >}}

{{< tab title="Gitalyクラスター" >}}

- ここで抽出されたGitalyトークンは、`PRAEFECT_EXTERNAL_TOKEN`に使用する必要があります。
- ここで抽出されたGitLab Shellシークレットは、`GITLAB_SHELL_SECRET_TOKEN`に使用する必要があります。

{{< /tab >}}

{{< /tabs >}}

#### ステップ3: 移行中にGitの変更が行われないことを確認する {#step-3-verify-no-git-changes-can-be-made-during-migration}

移行のデータ整合性を確保するために、次の手順でGitリポジトリに加えられる変更を防ぎます:

**1.メンテナンスモードを有効にする**

GitLab Enterprise Editionを使用している場合は、UI、API、またはRailsコンソールから[メンテナンスモード](https://docs.gitlab.com/administration/maintenance_mode/#enable-maintenance-mode)を有効にします:

```shell
kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Gitlab::CurrentSettings.update!(maintenance_mode: true)'
```

**2.Runnerポッドをスケールダウンする**

GitLab Community Editionを使用している場合は、クラスターで実行されているGitLab Runnerポッドをスケールダウンする必要があります。これにより、RunnerがGitLabに接続してCI/CDジョブを処理できなくなります。

GitLab Enterprise Editionを使用している場合、このステップはオプションです。[メンテナンスモード](https://docs.gitlab.com/administration/maintenance_mode/#enable-maintenance-mode)により、クラスター内のRunnerがGitLabに接続できなくなるためです。

```shell
# Make note of the current number of replicas for Runners so we can scale up to this number later
kubectl get deploy -lapp=gitlab-gitlab-runner,release=<release> -o jsonpath='{.items[].spec.replicas}{"\n"}'

# Scale down the Runners pods to zero
kubectl scale deploy -lapp=gitlab-gitlab-runner,release=<release> --replicas=0
```

**3.CIジョブが実行されていないことを確認する**

管理者エリアで、**CI/CD > ジョブ**に移動します。このページにはすべてのジョブが表示されますが、**実行中**状態のジョブがないことを確認します。次のステップに進む前に、ジョブが完了するまで待つ必要があります。

**4.Sidekiq cronジョブを無効にする**

移行中にSidekiqジョブがスケジュールおよび実行されないようにするには、すべてのSidekiq cronジョブを無効にします:

```shell
kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:disable!)'
```

**5\.バックグラウンドジョブが実行されていないことを確認する**

次のステップに進む前に、エンキューされたジョブまたは進行中のジョブが完了するまで待つ必要があります。

1. 管理者エリアで、[**モニタリング**](https://docs.gitlab.com/administration/admin_area/#background-jobs)に移動し、**バックグラウンドジョブ**を選択します。
1. Sidekiqダッシュボードで、**キュー**を選択し、次に**ライブポール**を選択します。
1. **ビジー**と**エンキュー済み**が0になるまで待ちます。

   ![Sidekiqのバックグラウンドジョブ](img/sidekiq_bg_jobs_v16_5.png)

**6.SidekiqポッドとWebserviceポッドをスケールダウンする**

整合性のあるバックアップを確実に行うために、SidekiqポッドとWebserviceポッドをスケールダウンします。両方のサービスは後の段階でスケールアップされます:

- Sidekiqポッドは復元ステップ中にスケールバックされます
- Webserviceポッドは、接続をテストするために外部Gitalyサービスに切り替えた後にスケールバックされます

```shell
# Make note of the current number of replicas for Sidekiq and Webservice so we can scale up to this number later
kubectl get deploy -lapp=sidekiq,release=<release> -o jsonpath='{.items[].spec.replicas}{"\n"}'
kubectl get deploy -lapp=webservice,release=<release> -o jsonpath='{.items[].spec.replicas}{"\n"}'

# Scale down the Sidekiq and Webservice pods to zero
kubectl scale deploy -lapp=sidekiq,release=<release> --replicas=0
kubectl scale deploy -lapp=webservice,release=<release> --replicas=0
```

**7.クラスターへの外部接続を制限する**

ユーザーと外部GitLab RunnerがGitLabに変更を加えないようにするには、GitLabへの不要な接続をすべて制限する必要があります。

これらのステップが完了すると、復元が完了するまで、ブラウザでGitLabを完全に使用できなくなります。

移行中にクラスターを新しい外部Gitalyサービスがアクセスできるようにするには、外部GitalyサービスのIPアドレスを唯一の外部例外として`nginx-ingress`構成に追加する必要があります。

1. 次の内容で`ingress-only-allow-ext-gitaly.yml`ファイルを作成します:

   ```yaml
   nginx-ingress:
     controller:
       service:
         loadBalancerSourceRanges:
          - "x.x.x.x/32"
   ```

   `x.x.x.x`は、外部GitalyサービスのIPアドレスである必要があります。

1. `gitlab.yml`ファイルと`ingress-only-allow-ext-gitaly.yml`ファイルの両方を使用して、新しい設定を適用します:

   ```shell
   helm upgrade <release> gitlab/gitlab \
     -f gitlab.yml \
     -f ingress-only-allow-ext-gitaly.yml
   ```

**8.リポジトリチェックサムのリストを作成する**

バックアップを実行する前に、[すべてのGitLabリポジトリを確認](https://docs.gitlab.com/administration/raketasks/check/#check-all-gitlab-repositories)し、リポジトリチェックサムのリストを作成します。移行後にチェックサムを`diff`できるように、出力をファイルにパイプします:

```shell
kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:git:checksum_projects > ~/checksums-before.txt
```

#### ステップ4: すべてのリポジトリをバックアップする {#step-4-backup-all-repositories}

リポジトリの[バックアップを作成](../../backup-restore/backup.md#create-the-backup)します:

```shell
kubectl exec <toolbox pod name> -it -- backup-utility --skip artifacts,ci_secure_files,db,external_diffs,lfs,packages,pages,registry,terraform_state,uploads
```

#### ステップ5: 新しいGitalyサービスを使用するようにインスタンスを設定する {#step-5-configure-instance-to-use-new-gitaly-service}

1. Gitalyサブチャートを無効にし、外部Gitalyを使用するようにGitLabを設定します。メインの`gitlab.yml`設定ファイルにGitalyへの参照がある場合は、それらを削除し、次の内容で新しい`external-gitaly.yml`ファイルを作成します:

   以前に追加のGitalyストレージを定義した場合は、新しい設定で同じ名前の一致するGitalyストレージが指定されていることを確認する必要があります。そうしない場合、復元操作は失敗します。

   TLSを構成する場合は、[TLS経由で外部Gitalyへの接続](#connecting-to-external-gitaly-over-tls)セクションを参照してください:

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```yaml
   global:
     gitaly:
       enabled: false
       external:
         - name: default                   # required
           hostname: node1.git.example.com # required
           port: 8075                      # optional, default shown
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

   {{< /tab >}}

   {{< tab title="Gitalyクラスター" >}}

   ```yaml
   global:
     gitaly:
       enabled: false
       external:
         - name: default                   # required
           hostname: ha.git.example.com    # required
           port: 2305                      # Praefect uses port 2305
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. `gitlab.yml`ファイル、`ingress-only-allow-ext-gitaly.yml`ファイル、および`external-gitaly.yml`ファイルを使用して、新しい設定を適用します:

   ```shell
   helm upgrade --install gitlab gitlab/gitlab \
     -f gitlab.yml \
     -f ingress-only-allow-ext-gitaly.yml \
     -f external-gitaly.yml
   ```

1. Webserviceポッドが実行されていない場合は、元のレプリカ数にスケールアップします。これは、次のステップでGitLabから外部Gitalyへの接続をテストするために必要です。

   ```shell
   kubectl scale deploy -lapp=webservice,release=<release> --replicas=<value>
   ```

1. Toolboxポッドで、GitLabが外部Gitalyに正常に接続できることを確認します:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:gitaly:check
   ```

1. 外部GitalyがChartインストールに接続できることを確認します:

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   GitalyサービスがGitLab APIへのコールバックを正常に実行できることを確認します:

   ```shell
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

   {{< /tab >}}

   {{< tab title="Gitalyクラスター" >}}

   すべてのPraefectノードで、PraefectサービスがGitalyノードに接続できることを確認します:

   ```shell
   # Run on Praefect nodes
   sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dial-nodes
   ```

   すべてのGitalyノードで、GitalyサービスがGitLab APIへのコールバックを正常に実行できることを確認します:

   ```shell
   # Run on Gitaly nodes
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

      {{< /tab >}}

   {{< /tabs >}}

#### ステップ6: リポジトリのバックアップを復元して検証する {#step-6-restore-and-validate-repository-backup}

1. 以前に作成した[バックアップファイルを復元](../../backup-restore/restore.md#restoring-the-backup-file)します。その結果、リポジトリは構成された外部GitalyまたはGitalyクラスターにコピーされます。

1. [すべてのGitLabリポジトリを確認](https://docs.gitlab.com/administration/raketasks/check/#check-all-gitlab-repositories)し、リポジトリチェックサムのリストを作成します。次のステップでチェックサムを`diff`できるように、出力をファイルにパイプします。

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:git:checksum_projects  > ~/checksums-after.txt
   ```

1. リポジトリのの前後で、リポジトリのチェックサムを比較します。チェックサムが同一の場合、このコマンドは出力を返しません。

   ```shell
   diff ~/checksums-before.txt ~/checksums-after.txt
   ```

   特定の行の`diff`出力で空白のチェックサムが`0000000000000000000000000000000000000000`に変化している場合、これは想定どおりであり、無視しても問題ありません。

#### ステップ7: 最終設定と {#step-7-final-configuration-and-validation}

1. 外部ユーザーとGitLabがGitLabに再度できるように、`gitlab.yml`ファイルと`external-gitaly.yml`ファイルを適用します。`ingress-only-allow-ext-gitaly.yml`を指定しないため、制限が削除されます。

    ```shell
    helm upgrade <release> gitlab/gitlab \
      -f gitlab.yml \
      -f external-gitaly.yml
    ```

    外部のを含む、将来のために`gitlab.yml`を生成することを検討してください。

    ```shell
    helm get values <release> gitlab/gitlab -o yaml > gitlab.yml
    ```

1. Edition（EE）/>を使用している場合は、[メンテナンスモード](https://docs.gitlab.com/administration/maintenance_mode/#enable-maintenance-mode)を、、またはのいずれかで無効にします。

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Gitlab::CurrentSettings.update!(maintenance_mode: false)'
   ```

1. 複数のストレージがある場合は、[新しいリポジトリの保存場所をしてください](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored)。

1. を有効にします:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:enable!)'
   ```

1. が実行されていない場合は、 を元の数にします:

   ```shell
   kubectl scale deploy -lapp=gitlab-gitlab-runner,release=<release> --replicas=<value>
   ```

1. すべてが期待どおりに動作していることを確認したら、 を削除できます:

   警告:すべてが期待どおりに動作していることを再確認するまで、[手順6](#step-6-restore-and-validate-repository-backup)に従ってチェックサムが一致することを確認するまで、 を削除しないでください。

   ```shell
   kubectl delete pvc repo-data-<release>-gitaly-0
   ```

#### {#rollback}

問題が発生した場合は、サブが再度使用されるように、変更をできます。

を正常に行うには、元の が存在している必要があります。

1. [手順1で取得したリビジョン番号を使用して、 を以前のにします: の現在のリビジョンを取得します](#step-1-get-the-current-release-revision-of-the-gitlab-chart):

   ```shell
   helm rollback <release> <revision>
   ```

1. が実行されていない場合は、 を元の数にします:

   ```shell
   kubectl scale deploy -lapp=webservice,release=<release> --replicas=<value>
   ```

1. が実行されていない場合は、 を元の数にします:

   ```shell
   kubectl scale deploy -lapp=sidekiq,release=<release> --replicas=<value>
   ```

1. 以前に無効にした場合は、 を有効にします:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:enable!)'
   ```

1. が実行されていない場合は、 を元の数にします:

   ```shell
   kubectl scale deploy -lapp=gitlab-gitlab-runner,release=<release> --replicas=<value>
   ```

1. Edition（EE）/>を使用している場合は、有効になっている場合は、[メンテナンスモード](https://docs.gitlab.com/administration/maintenance_mode/#disable-maintenance-mode)を無効にします。

### 関連ドキュメント {#related-documentation}

- [にする](https://docs.gitlab.com/administration/gitaly/#migrate-to-gitaly-cluster)
