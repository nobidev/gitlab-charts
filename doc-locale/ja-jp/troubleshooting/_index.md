---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのトラブルシューティング
---

## アップグレードに失敗しました:ジョブに失敗しました:BackoffLimitExceeded {#upgrade-failed-job-failed-backofflimitexceeded}

[チャートの6.0バージョンへのアップグレード](../releases/6_0.md#upgrade-path-from-5x)時にこのエラーが発生した場合、適切なアップグレードパスに従っていない可能性があります。まず、最新の5.10.xバージョンにアップグレードする必要があります。

1. すべてのリリースをリストして、GitLab Helmリリース名を特定します（リリースが`default` K8sネームスペースにデプロイされていない場合は、`-n <namespace>`を含める必要があります）。

   ```shell
   helm ls
   ```

1. GitLab Helmリリースの名前が`gitlab`であると仮定すると、リリース履歴を確認し、最後に成功したリビジョンを特定する必要があります（`DESCRIPTION`でリビジョンの状態を確認できます）。

   ```shell
   helm history gitlab
   ```

1. 最後に成功したリビジョンが`1`であると仮定すると、このコマンドを使用してロールバックします。

   ```shell
   helm rollback gitlab 1
   ```

1. `<x>`を適切なチャートバージョンに置き換えて、アップグレードコマンドを再実行します。

   ```shell
   helm upgrade --version=5.10.<x>
   ```

1. この時点で、`--version`オプションを使用して特定の6.x.xチャートバージョンを渡すか、GitLabの最新バージョンにアップグレードするためのオプションを削除できます。

   ```shell
   helm upgrade --install gitlab gitlab/gitlab <other_options>
   ```

コマンドライン引数の詳細については、[Helmを使用したデプロイ](../installation/deployment.md#deploy-using-helm)セクションを参照してください。チャートバージョンとGitLabバージョンのマッピングについては、[GitLabバージョンマッピング](../installation/version_mappings.md)をお読みください。

## アップグレードに失敗しました: 「$name」にはデプロイされたリリースがありません {#upgrade-failed-name-has-no-deployed-releases}

このエラーは、最初のインストールが失敗した場合、2回目のインストール/アップグレードで発生します。

最初のインストールが完全に失敗し、GitLabが動作しなかった場合は、再度インストールする前に、まず失敗したインストールをパージする必要があります。

```shell
helm uninstall <release-name>
```

代わりに、最初のインストールコマンドがタイムアウトしたが、GitLabが正常に起動した場合は、`--force`フラグを`helm upgrade`コマンドに追加して、エラーを無視し、リリースの更新を試みることができます。

それ以外の場合、GitLabチャートのデプロイが以前に成功した後にこのエラーが発生した場合は、バグが発生しています。当社の[イシュートラッカー](https://gitlab.com/gitlab-org/charts/gitlab/-/issues)でイシューをオープンし、この問題からCIサーバーを復旧した[イシュー#630](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/630)もご確認ください。

## エラー: このコマンドには2つの引数が必要です: リリース名、チャートパス {#error-this-command-needs-2-arguments-release-name-chart-path}

このようなエラーは、`helm upgrade`を実行したときに、パラメータにスペースが含まれている場合に発生する可能性があります。次の例では、`Test Username`が原因です。

```shell
helm upgrade gitlab gitlab/gitlab --timeout 600s --set global.email.display_name=Test Username ...
```

修正するには、パラメータをシングルクォートで囲んで渡します。

```shell
helm upgrade gitlab gitlab/gitlab --timeout 600s --set global.email.display_name='Test Username' ...
```

## アプリケーションコンテナの初期化が常に実行される {#application-containers-constantly-initializing}

Sidekiq、Webservice、またはその他のRailsベースのコンテナが常に初期化状態になっている場合は、`dependencies`コンテナがパスするのを待っている可能性があります。

特定のPodのログを`dependencies`コンテナについて確認すると、次のメッセージが繰り返し表示されることがあります。

```plaintext
Checking database connection and schema version
WARNING: This version of GitLab depends on gitlab-shell 8.7.1, ...
Database Schema
Current version: 0
Codebase version: 20190301182457
```

これは、`migrations`ジョブがまだ完了していないことを示しています。このジョブの目的は、データベースのシードと、関連するすべての移行が適切に行われることを保証することです。アプリケーションコンテナは、データベースが予想されるデータベースバージョン以上になるまで待機しようとしています。これは、アプリケーションがコードベースの期待値とスキーマが一致しないために誤動作しないようにするためです。

1. `migrations`ジョブを見つけます。`kubectl get job -lapp=migrations`
1. ジョブによって実行されているPodを見つけます。`kubectl get pod -lbatch.kubernetes.io/job-name=<job-name>`
1. `STATUS`列を確認して、出力を調べます。

`STATUS`が`Running`の場合は、続行します。`STATUS`が`Completed`の場合、アプリケーションコンテナは、次のチェックがパスした直後に開始されます。

このポッドからのログを調べます。`kubectl logs <pod-name>`

このジョブの実行中に発生したエラーはすべて対処する必要があります。これらは、解決されるまでアプリケーションの使用をブロックします。考えられる問題は次のとおりです。

- 設定されたPostgreSQLデータベースへの到達不能または認証の失敗
- 設定されたRedisサービスへの到達不能または認証の失敗
- Gitalyインスタンスに到達できない

## 設定変更の適用 {#applying-configuration-changes}

次のコマンドは、`gitlab.yaml`に加えられた更新を適用するために必要な操作を実行します。

```shell
helm upgrade <release name> <chart path> -f gitlab.yaml
```

## 登録に失敗したインクルードされたGitLab Runner {#included-gitlab-runner-failing-to-register}

これは、runner登録トークンがGitLabで変更された場合に発生する可能性があります。（これは、バックアップを復元した後に頻繁に発生します）

1. GitLabインストールの`admin/runners` Webページにある新しい共有runnerトークンを見つけます。
1. Kubernetesに保存されている既存のrunnerトークンシークレットの名前を見つけます

   ```shell
   kubectl get secrets | grep gitlab-runner-secret
   ```

1. 既存のシークレットを削除します

   ```shell
   kubectl delete secret <runner-secret-name>
   ```

1. 2つのキー（共有トークンを持つ`runner-registration-token`と、空の`runner-token`）で新しいシークレットを作成します

   ```shell
   kubectl create secret generic <runner-secret-name> --from-literal=runner-registration-token=<new-shared-runner-token> --from-literal=runner-token=""
   ```

## リダイレクトが多すぎる {#too-many-redirects}

これは、NGINX Ingressの前にTLS終端があり、tlsシークレットが設定で指定されている場合に発生する可能性があります。

1. `global.ingress.annotations."nginx.ingress.kubernetes.io/ssl-redirect": "false"`を設定するように値を更新します

   値ファイル経由:

   ```yaml
   # values.yaml
   global:
     ingress:
       annotations:
         "nginx.ingress.kubernetes.io/ssl-redirect": "false"
   ```

   Helm CLI経由:

   ```shell
   helm ... --set-string global.ingress.annotations."nginx.ingress.kubernetes.io/ssl-redirect"=false
   ```

1. 変更を適用します。

{{< alert type="note" >}}

外部サービスをSSL終端に使用する場合、そのサービスはhttpsへのリダイレクトを担当します（必要に応じて）。

{{< /alert >}}

## イミュータブルフィールドエラーでアップグレードが失敗する {#upgrades-fail-with-immutable-field-error}

### spec.clusterIP {#specclusterip}

これらのチャートの3.0.0リリースより前は、実際の値（`""`）がないにもかかわらず、`spec.clusterIP`プロパティが[いくつかのサービスに入力されていました](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1710)。これはバグであり、Helm 3のプロパティの3方向マージで問題が発生します。

チャートがHelm 3でデプロイされると、さまざまなサービスから`clusterIP`プロパティを収集して、それらをHelmに提供される値に入力するか、影響を受けるサービスをKubernetesから削除しない限り、_可能なアップグレードパス_はありません。

[このチャートの3.0.0リリースでこのエラーが修正されました](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1710)が、手動による修正が必要です。

これは、影響を受けるすべてのサービスを削除するだけで解決できます。

1. 影響を受けるすべてのサービスを削除します:

   ```shell
   kubectl delete services -lrelease=RELEASE_NAME
   ```

1. Helm経由でアップグレードを実行します。
1. 今後のアップグレードでは、このエラーは発生しません。

{{< alert type="note" >}}

これにより、使用中の場合、このチャートのNGINX Ingressの`LoadBalancer`の動的な値が変更されます。`externalIP`に関する詳細については、[グローバルIngress設定ドキュメント](../charts/globals.md#configure-ingress-settings)を参照してください。DNSレコードの更新が必要になる場合があります。

{{< /alert >}}

### spec.selector {#specselector}

Sidekiqポッドは、チャートリリース`3.0.0`より前に一意のセレクターを受信しませんでした。[この問題については、ドキュメントに記載されています](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/663)。

Helmを使用した`3.0.0`へのアップグレードでは、古いSidekiqデプロイメントが自動的に削除され、Sidekiqの`Deployments`、`HPAs`、および`Pods`の名前に`-v1`が付加された新しいものが作成されます。

`3.0.0`のインストール時にSidekiqデプロイメントでこのエラーが引き続き発生する場合は、次の手順で解決してください。

1. Sidekiqサービスを削除します

   ```shell
   kubectl delete deployment --cascade -lrelease=RELEASE_NAME,app=sidekiq
   ```

1. Helm経由でアップグレードを実行します。

### 種類Deploymentで「RELEASE-NAME-cert-manager」にできません {#cannot-patch-release-name-cert-manager-with-kind-deployment}

**CertManager**バージョン`0.10`からのアップグレードでは、多くの破壊的な変更が導入されました。古いカスタムリソース定義をアンインストールし、Helmの追跡から削除して、再度インストールする必要があります。

Helmチャートはデフォルトでこれを行おうとしますが、このエラーが発生した場合は、手動でアクションを実行する必要がある場合があります。

このエラーメッセージが発生した場合、アップグレードでは、新しいカスタムリソース定義がデプロイメントに実際に適用されるようにするために、通常よりも1つ多くのステップが必要になります。

1. 古い**CertManager**デプロイメントを削除します。

   ```shell
   kubectl delete deployments -l app=cert-manager --cascade
   ```

1. 再度アップグレードを実行します。今回は、新しいカスタムリソース定義をインストールします

   ```shell
   helm upgrade --install --values - YOUR-RELEASE-NAME gitlab/gitlab < <(helm get values YOUR-RELEASE-NAME)
   ```

### 種類Deploymentで`gitlab-kube-state-metrics`にできません {#cannot-patch-gitlab-kube-state-metrics-with-kind-deployment}

**Prometheus**バージョン`11.16.9`から`15.0.4`へのアップグレードでは、[kube-state-metricsデプロイメント](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics)で使用されるセレクターが変更されます。これはデフォルトで無効になっています（`prometheus.kubeStateMetrics.enabled=false`）。

このエラーメッセージが発生した場合、つまり`prometheus.kubeStateMetrics.enabled=true`を意味する場合は、アップグレードには[追加の手順](https://artifacthub.io/packages/helm/prometheus-community/prometheus#to-15-0)が必要です。

1. 古い**kube-state-metrics**デプロイメントを削除します。

   ```shell
   kubectl delete deployments.apps -l app.kubernetes.io/instance=RELEASE_NAME,app.kubernetes.io/name=kube-state-metrics --cascade=orphan
   ```

1. Helm経由でアップグレードを実行します。

## `ImagePullBackOff`、`Failed to pull image`および`manifest unknown`エラー {#imagepullbackoff-failed-to-pull-image-and-manifest-unknown-errors}

[`global.gitlabVersion`](../charts/globals.md#gitlab-version)を使用している場合は、まずそのプロパティを削除します。[チャートとGitLabの間のバージョンマッピング](../installation/version_mappings.md)を確認し、`helm`コマンドで`gitlab/gitlab`チャートの互換性のあるバージョンを指定します。

## アップグレードに失敗しました: `helm 2to3 convert`の後の「できません...」 {#upgrade-failed-cannot-patch--after-helm-2to3-convert}

これは既知の問題です。Helm 2リリースをHelm 3に移行した後、後続のアップグレードが失敗する可能性があります。詳細な説明とについては、[Helm v2からHelm v3への移行](../installation/migration/helm.md#known-issues)を参照してください。

## アップグレードに失敗しました: mailroomのタイプが一致しません: `%!t(<nil>)` {#upgrade-failed-type-mismatch-on-mailroom-tnil}

このようなエラーは、マップを予期するキーに対して有効なマップを指定しない場合に発生する可能性があります。

たとえば、次の設定ではこのエラーが発生します。

```yaml
gitlab:
  mailroom:
```

これを修正するには、次のいずれかの操作を行います。

1. `gitlab.mailroom`に有効なマップを提供します。
1. `mailroom`キーを完全に削除します。

オプションのキーの場合、空のマップ（`{}`）は有効な値であることに注意してください。

## エラー: `cannot drop view pg_stat_statements because extension pg_stat_statements requires it` {#error-cannot-drop-view-pg_stat_statements-because-extension-pg_stat_statements-requires-it}

Helmチャートインスタンスでを復元するときに、このエラーが発生する可能性があります。次の手順をとして使用します。

1. `toolbox`ポッド内で、DBコンソールを開きます:

   ```shell
   /srv/gitlab/bin/rails dbconsole -p
   ```

1. 拡張機能をドロップします:

   ```shell
   DROP EXTENSION pg_stat_statements;
   ```

1. プロセスを実行します。
1. が完了したら、DBコンソールで拡張機能を再作成します:

   ```shell
   CREATE EXTENSION pg_stat_statements;
   ```

`pg_buffercache`拡張機能で同じ問題が発生した場合は、上記と同じ手順に従ってドロップして再作成します。

このエラーの詳細については、イシュー[\#2469](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2469)を参照してください。

## バンドルされたPostgreSQLポッドが起動に失敗しました: `database files are incompatible with server` {#bundled-postgresql-pod-fails-to-start-database-files-are-incompatible-with-server}

GitLab Helmチャートの新しいバージョンにアップグレードした後、バンドルされたPostgreSQLポッドに次のエラーメッセージが表示されることがあります。

```plaintext
gitlab-postgresql FATAL:  database files are incompatible with server
gitlab-postgresql DETAIL:  The data directory was initialized by PostgreSQL version 11, which is not compatible with this version 12.7.
```

これに対処するには、[Helmロールバック](https://helm.sh/docs/helm/helm_rollback/)を実行してチャートの以前のバージョンに戻し、[アップグレードガイド](../installation/upgrade.md)の手順に従って、バンドルされたPostgreSQLバージョンをアップグレードします。PostgreSQLが正しくアップグレードされたら、GitLab Helmチャートのアップグレードを再度試してください。

## バンドルされたNGINX Ingressポッドが起動に失敗しました: `Failed to watch *v1beta1.Ingress` {#bundled-nginx-ingress-pod-fails-to-start-failed-to-watch-v1beta1ingress}

Kubernetesバージョン1.22以降を実行している場合、バンドルされたNGINX Ingressポッドに次のエラー メッセージが表示されることがあります。

```plaintext
Failed to watch *v1beta1.Ingress: failed to list *v1beta1.Ingress: the server could not find the requested resource
```

これに対処するには、Kubernetesバージョンが1.21以前であることを確認してください。Kubernetes 1.22以降のNGINX Ingressのの詳細については、[\#2852](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2852)を参照してください。

## `/api/v4/jobs/request`エンドポイントでの負荷の増加 {#increased-load-on-apiv4jobsrequest-endpoint}

オプション`workhorse.keywatcher`が`false`に設定されている場合、`/api/*`をするデプロイメントでこの問題が発生する可能性があります。確認するには、次の手順に従います。

1. `/api/*`をするポッド内のコンテナ`gitlab-workhorse`にアクセスします:

   ```shell
   kubectl exec -it --container=gitlab-workhorse <gitlab_api_pod> -- /bin/bash
   ```

1. ファイル`/srv/gitlab/config/workhorse-config.toml`を調べます。`[redis]`設定が見つからない可能性があります:

   ```shell
   grep '\[redis\]' /srv/gitlab/config/workhorse-config.toml
   ```

`[redis]`設定が存在しない場合、デプロイメント中に`workhorse.keywatcher`フラグが`false`に設定されたため、`/api/v4/jobs/request`エンドポイントで追加の負荷が発生します。これを修正するには、`webservice`チャートで`keywatcher`を有効にします:

```yaml
workhorse:
  keywatcher: true
```

## Git over : `the remote end hung up unexpectedly` {#git-over-ssh-the-remote-end-hung-up-unexpectedly}

経由のGitオペレーションは、次のエラーで断続的に失敗する可能性があります。

```plaintext
fatal: the remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
```

このエラーには、いくつかの考えられる原因があります。

- **ネットワークタイムアウト**:

  Gitクライアントは、オブジェクトを圧縮するときなど、接続を開いてアイドル状態のままにすることがあります。HAProxyの`timeout client`のようなは、これらのアイドル状態の接続が終了する原因となる可能性があります。

  `sshd`でキープアライブを設定できます:

  ```yaml
  gitlab:
    gitlab-shell:
      config:
        clientAliveInterval: 15
  ```

- **`gitlab-shell`メモリ**:

  デフォルトでは、チャートはGitLab Shellメモリに制限を設定しません。`gitlab.gitlab-shell.resources.limits.memory`が低すぎる場合、経由のGitオペレーションはこれらのエラーで失敗する可能性があります。

  ネットワーク経由のではなく、これがメモリ制限によって引き起こされていることを確認するには、`kubectl describe nodes`を実行します。

  ```plaintext
  System OOM encountered, victim process: gitlab-shell
  Memory cgroup out of memory: Killed process 3141592 (gitlab-shell)
  ```

## エラー: `kex_exchange_identification: Connection closed by remote host` {#error-kex_exchange_identification-connection-closed-by-remote-host}

次のエラーがGitLab Shellログに表示されることがあります。

```plaintext
subcomponent":"ssh","time":"2025-02-21T19:07:52Z","message":"kex_exchange_identification: Connection closed by remote host\r"}
```

このエラーは、OpenSSH `sshd`が準備と活性プローブを処理できないことが原因です。このエラーを解決するには、設定で`sshDaemon: openssh`を`sshDaemon: gitlab-ssd`に変更して、代わりに[`gitlab-sshd`](../charts/gitlab/gitlab-shell/_index.md#configuration)を使用します:

```yaml
gitlab:
  gitlab-shell: 
    sshDaemon: gitlab-sshd
```

##  設定: `mapping values are not allowed in this context` {#yaml-configuration-mapping-values-are-not-allowed-in-this-context}

 設定に先頭のスペースが含まれている場合、次のエラーメッセージが表示されることがあります。

```plaintext
template: /var/opt/gitlab/templates/workhorse-config.toml.tpl:16:98:
  executing \"/var/opt/gitlab/templates/workhorse-config.toml.tpl\" at <data.YAML>:
    error calling YAML:
      yaml: line 2: mapping values are not allowed in this context
```

これに対処するには、設定に先頭のスペースがないことを確認します。

たとえば、これを変更します:

```yaml
  key1: value1
  key2: value2
```

... これに変更します:

```yaml
key1: value1
key2: value2
```

## と証明書 {#tls-and-certificates}

GitLabインスタンスがプライベート公開認証局（CA）を信頼する必要がある場合、GitLabはオブジェクトストレージ、Elasticsearch、Jira、Jenkinsなどの他のサービスとのハンドシェイクに失敗する可能性があります:

```plaintext
error: certificate verify failed (unable to get local issuer certificate)
```

プライベート公開認証局（CA）によって署名された証明書の部分的信頼は、次の場合に発生する可能性があります:

- 提供された証明書が個別のファイルにない。
- 証明書initコンテナが必要なすべてのステップを実行しない。

また、GitLabは主にRuby on RailsとGoで記述されており、各のライブラリの動作は異なります。この違いにより、ジョブログがGitLabでレンダリングに失敗するが、rawジョブログが問題なくダウンロードされるなどの問題が発生する可能性があります。

さらに、`proxy_download`設定によっては、信頼ストアが正しく設定されている場合、ブラウザは問題なくオブジェクトストレージにリダイレクトされます。同時に、1つ以上のGitLabコンポーネントによるハンドシェイクが引き続き失敗する可能性があります。

### 証明書の信頼設定と {#certificate-trust-setup-and-troubleshooting}

証明書の問題のの一環として、次のことを確認してください:

- 信頼する必要がある各証明書のシークレットを作成します。
- ファイルごとに1つの証明書のみを提供します。

  ```plaintext
  kubectl create secret generic custom-ca --from-file=unique_name=/path/to/cert
  ```

  この例では、証明書はキー名`unique_name`を使用して保存されます

バンドルまたはチェーンを提供する場合、一部のGitLabコンポーネントは機能しません。

`kubectl get secrets`および`kubectl describe secrets/secretname`でシークレットをします。これにより、`Data`の下の証明書のキー名が表示されます。

`global.certificates.customCAs`を使用して信頼するための追加の証明書をします[チャートグローバル](../charts/globals.md#custom-certificate-authorities)。

ポッドがデプロイされると、initコンテナは証明書をマウントし、GitLabコンポーネントがそれらを使用できるように設定します。initコンテナは`registry.gitlab.com/gitlab-org/build/cng/alpine-certificates`です。

追加の証明書は`/usr/local/share/ca-certificates`でコンテナにマウントされ、シークレットキー名が証明書ファイル名として使用されます。

initコンテナは`/scripts/bundle-certificates` ([ソース](https://gitlab.com/gitlab-org/build/CNG-mirror/-/blob/master/certificates/scripts/bundle-certificates)) を実行します。そのスクリプトでは、`update-ca-certificates`:

1. `/usr/local/share/ca-certificates`から`/etc/ssl/certs`にカスタム証明書をコピーします。
1. バンドル`ca-certificates.crt`をコンパイルします。
1. 各証明書のハッシュを生成し、Railsに必要なハッシュを使用してシンボリックリンクを作成します。証明書バンドルは、警告付きでスキップされます:

   ```plaintext
   WARNING: unique_name does not contain exactly one certificate or CRL: skipping
   ```

[initコンテナの状態とログのします](https://kubernetes.io/docs/tasks/debug/debug-application/debug-init-containers/)。たとえば、証明書initコンテナのログを表示し、警告を確認するには:

```plaintext
kubectl logs gitlab-webservice-default-pod -c certificates
```

### Railsコンソールで確認する {#check-on-the-rails-console}

ツールボックスポッドを使用して、Railsが提供した証明書を信頼するかどうかを確認します。

1. Railsコンソールを起動します（`<namespace>`をGitLabがインストールされているネームスペースに置き換えます）:

   ```shell
   kubectl exec -ti $(kubectl get pod -n <namespace> -lapp=toolbox -o jsonpath='{.items[0].metadata.name}') -n <namespace> -- bash
   /srv/gitlab/bin/rails console
   ```

1. Railsが証明書公開認証局（CA）を確認する場所を確認します:

   ```ruby
   OpenSSL::X509::DEFAULT_CERT_DIR
   ```

1. RailsコンソールでHTTPSを実行します:

   ```ruby
   ## Configure a web server to connect to:
   uri = URI.parse("https://myservice.example.com")

   require 'openssl'
   require 'net/http'
   Rails.logger.level = 0
   OpenSSL.debug=1
   http = Net::HTTP.new(uri.host, uri.port)
   http.set_debug_output($stdout)
   http.use_ssl = true

   http.verify_mode = OpenSSL::SSL::VERIFY_PEER
   # http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TLS verification disabled

   response = http.request(Net::HTTP::Get.new(uri.request_uri))
   ```

### Initコンテナの {#troubleshoot-the-init-container}

Dockerを使用して証明書コンテナを実行します。

1. ディレクトリ構造を設定し、証明書をします:

   ```shell
   mkdir -p etc/ssl/certs usr/local/share/ca-certificates

     # The secret name is: my-root-ca
     # The key name is: corporate_root

   kubectl get secret my-root-ca -ojsonpath='{.data.corporate_root}' | \
        base64 --decode > usr/local/share/ca-certificates/corporate_root

     # Check the certificate is correct:

   openssl x509 -in usr/local/share/ca-certificates/corporate_root -text -noout
   ```

1. 正しいコンテナのバージョンを決定します。

   ```shell
   kubectl get deployment -lapp=webservice -ojsonpath='{.items[0].spec.template.spec.initContainers[0].image}'
   ```

1. `etc/ssl/certs`コンテンツの準備を実行するコンテナを実行します。

   ```shell
   docker run -ti --rm \
        -v $(pwd)/etc/ssl/certs:/etc/ssl/certs \
        -v $(pwd)/usr/local/share/ca-certificates:/usr/local/share/ca-certificates \
        registry.gitlab.com/gitlab-org/build/cng/gitlab-base:v15.10.3
   ```

1. 証明書が正しくビルドされていることを確認してください。

   - `etc/ssl/certs/corporate_root.pem`が作成されているはずです。
   - ハッシュされたファイル名があり、それが証明書自体へのシンボリックリンクである必要があります（`etc/ssl/certs/1234abcd.0`など）。
   - ファイルとシンボリックリンクは次のように表示されるはずです。

     ```shell
     ls -l etc/ssl/certs/ | grep corporate_root
     ```

     次に例を示します。

     ```plaintext
     lrwxrwxrwx   1 root root      20 Oct  7 11:34 28746b42.0 -> corporate_root.pem
     -rw-r--r--   1 root root    1948 Oct  7 11:34 corporate_root.pem
     ```

## リダイレクト {#308-permanent-redirect-causing-a-redirect-loop}を引き起こす`308: Permanent Redirect`

`308: Permanent Redirect`は、ロードバランサーが暗号化されていないトラフィック（HTTP）をNGINXに送信するように設定されている場合に発生する可能性があります。NGINXはデフォルトで`HTTP`から`HTTPS`へのリダイレクトを行うため、「リダイレクト」が発生する可能性があります。

この問題を[修正するには、NGINXの`use-forwarded-headers`を有効にします](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#use-forwarded-headers)。

## `nginx-controller`ログおよび`404`エラーの「無効な単語」エラー {#invalid-word-errors-in-the-nginx-controller-logs-and-404-errors}

 6.6以降にすると、にインストールされているアプリケーションのまたはサードパーティドメインにアクセスしたときに`404`のコードが表示されたり、`gitlab-nginx-ingress-controller`ログに「無効な単語」エラーが表示されたりする場合があります:

```console
gitlab-nginx-ingress-controller-899b7d6bf-688hr controller W1116 19:03:13.162001       7 store.go:846] skipping ingress gitlab/gitlab-minio: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-688hr controller W1116 19:03:13.465487       7 store.go:846] skipping ingress gitlab/gitlab-registry: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:12.233577       6 store.go:846] skipping ingress gitlab/gitlab-kas: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:12.536534       6 store.go:846] skipping ingress gitlab/gitlab-webservice-default: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:12.848844       6 store.go:846] skipping ingress gitlab/gitlab-webservice-default-smartcard: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:13.161640       6 store.go:846] skipping ingress gitlab/gitlab-minio: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:13.465425       6 store.go:846] skipping ingress gitlab/gitlab-registry: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
```

その場合は、[ ](https://kubernetes.github.io/ingress-nginx/examples/customization/configuration-snippets/)の使用について、 とサードパーティの をしてください。`nginx-ingress.controller.config.annotation-value-word-blocklist`を調整または変更する必要がある場合があります。

詳細については、[   ](../charts/nginx/_index.md#annotation-value-word-blocklist)をしてください。

### マウントに時間がかかる {#volume-mount-takes-a-long-time}

`gitaly`や`toolbox`など、大きなをマウントするには時間がかかる場合があります。がの`securityContext`に合わせてのコンテンツのを再帰的に変更するためです。

 1.23以降では、この問題をするために`securityContext.fsGroupChangePolicy`を`OnRootMismatch`にできます。このフラグは、すべてのサブでされています。

サブの例を次に示します。

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroupChangePolicy: "OnRootMismatch"
```

詳細については、[ドキュメント](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#configure-volume-permission-and-ownership-change-policy-for-pods)をしてください。

`fsGroupChangePolicy`をしていない の場合、`securityContext`のを変更または完全に削除することで、問題をできます。

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroup: ""
      runAsUser: ""
```

{{< alert type="note" >}}

構文例では、`securityContext`が完全に削除されます。`securityContext: {}`または`securityContext:`をしても、が とが指定したをする方法では機能しません。

{{< /alert >}}

### 断続的な502エラー {#intermittent-502-errors}

のによって処理されているがメモリ制限を超えると、のOOMKillerによって強制終了されます。ただし、を強制終了しても、必ずしも 自体が強制終了または再起動されるとは限りません。この状態になると、は`502`を返します。ログでは、これは、`502`エラーのログが記録された直後にされた として表示されます。

```shell
2024-01-19T14:12:08.949263522Z {"correlation_id":"XXXXXXXXXXXX","duration_ms":1261,"error":"badgateway: failed to receive response: context canceled"....
2024-01-19T14:12:24.214148186Z {"component": "gitlab","subcomponent":"puma.stdout","timestamp":"2024-01-19T14:12:24.213Z","pid":1,"message":"- Worker 2 (PID: 7414) booted in 0.84s, phase: 0"}
```

この問題を解決するには、[ のメモリ制限を引き上げます](../charts/gitlab/webservice/_index.md#memory-requestslimits)。

### アップグレードに失敗しました-`cannot patch "gitlab-prometheus-server" with kind Deployment` {#upgrade-failed---cannot-patch-gitlab-prometheus-server-with-kind-deployment}

 9.0で、主要のサブをしました。のセレクターとが変更されたため、手動での操作が必要です。

 をするには、[ガイド](../releases/9_0.md#prometheus-upgrade)にしてください。

## ののアップロードが失敗しました {#toolbox-backup-failing-on-upload}

次のようなエラーで へのアップロードを試みると、が失敗する可能性があります:

```plaintext
An error occurred (XAmzContentSHA256Mismatch) when calling the UploadPart operation: The Content-SHA256 you specified did not match what we received
```

これは、`awscli`ツールと サービスの間に互換性がないことが原因である可能性があります。このは、Dell ECSを使用している場合にされています。このを回避するには、[データ整合性保護を無効にする](../backup-restore/backup.md#data-integrity-protection-with-awscli)ことができます。
