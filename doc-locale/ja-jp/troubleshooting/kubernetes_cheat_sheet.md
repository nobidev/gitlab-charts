---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Kubernetesチートシート
---

{{< details >}}

- プラン:Free, Premium, Ultimateプラン
- 提供:GitLab Self-Managed

{{< /details >}}

これは、GitLabサポートがトラブルシューティングの際に使用するKubernetesに関する有用な情報の一覧です。誰でもサポートチームが集めた知識を利用できるように、GitLabはこれを公開しています

{{< alert type="warning" >}}

これらのコマンドは、Kubernetesコンポーネントを**変更または破損させる可能性**があるため、ご自身の責任で使用してください。

{{< /alert >}}

[有料プラン](https://about.gitlab.com/pricing/)をご利用で、これらのコマンドの使用方法が不明な場合は、[サポートにお問い合わせ](https://about.gitlab.com/support/)いただくことをお勧めします。サポートがお客様が抱えている問題について支援します。

## 一般的なKubernetesコマンド {#generic-kubernetes-commands}

- GCPプロジェクトへの認証方法 (異なるGCPアカウントでプロジェクトを使用している場合に特に役立ちます)。

  ```shell
  gcloud auth login
  ```

- Kubernetesダッシュボードへのアクセス方法:

  ```shell
  # for minikube:
  minikube dashboard —url
  # for non-local installations if access via Kubectl is configured:
  kubectl proxy
  ```

- KubernetesノードにSSHで接続し、rootとしてコンテナに入る方法<https://github.com/kubernetes/kubernetes/issues/30656>:

  - GCPの場合、ノード名を見つけて、`gcloud compute ssh node-name`を実行できます。
  - `docker ps`を使用してコンテナを一覧表示します。
  - `docker exec --user root -ti container-id bash`を使用してコンテナに入ります。

- ローカルマシンからポッドにファイルをコピーする方法:

  ```shell
  kubectl cp file-name pod-name:./destination-path
  ```

- `CrashLoopBackoff`ステータスのポッドの対処法:

  - Kubernetesダッシュボードからログを確認します。
  - Kubectl経由でログを確認します。

    ```shell
    kubectl logs <webservice pod> -c dependencies
    ```

- すべてのKubernetesクラスターイベントをリアルタイムで追跡する方法:

  ```shell
  kubectl get events -w --all-namespaces
  ```

- 以前に終了したポッドインスタンスのログを取得する方法:

  ```shell
  kubectl logs <pod-name> --previous
  ```

  ログはコンテナ/ポッド自体には保持されません。すべて`stdout`に書き込まれます。これはKubernetesの原則です。詳細については、[Twelve-factor app](https://12factor.net/)を参照してください。

- クラスターで設定されたcronジョブを取得する方法

  ```shell
  kubectl get cronjobs
  ```

  [cronベースのバックアップ](../backup-restore/backup.md#cron-based-backup)を設定すると、ここに新しいスケジュールが表示されます。スケジュールの詳細については、[CronJobで自動タスクを実行する](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#creating-a-cron-job)を参照してください

## GitLab固有のKubernetes情報 {#gitlab-specific-kubernetes-information}

- 個別のポッドのログの追跡。`webservice`ポッドの例:

  ```shell
  kubectl logs gitlab-webservice-54fbf6698b-hpckq -c webservice
  ```

- ラベルを共有するすべてのポッドを追跡およびフォローします (この場合は`webservice`)。

  ```shell
  # all containers in the webservice pods
  kubectl logs -f -l app=webservice --all-containers=true --max-log-requests=50

  # only the webservice containers in all webservice pods
  kubectl logs -f -l app=webservice -c webservice --max-log-requests=50
  ```

- Linuxパッケージインストールでコマンド`gitlab-ctl tail`と同様に、すべてのコンテナから一度にログをストリーミングできます。

  ```shell
  kubectl logs -f -l release=gitlab --all-containers=true --max-log-requests=100
  ```

- `gitlab`ネームスペース内のすべてのイベントを確認します (Helm Chartのデプロイ時に別のネームスペースを指定した場合は、ネームスペース名が異なる場合があります)。

  ```shell
  kubectl get events -w --namespace=gitlab
  ```

- 便利なGitLabツール (コンソール、Rakeタスクなど) のほとんどは、toolboxポッドにあります。中に入ってコマンドを実行したり、外からコマンドを実行したりできます。

  ```shell
  # find the pod
  kubectl --namespace gitlab get pods -lapp=toolbox

  # open the Rails console
  kubectl --namespace gitlab exec -it -c toolbox <toolbox-pod-name> -- gitlab-rails console

  # run GitLab check. The output can be confusing and invalid because of the specific structure of GitLab installed via helm chart
  gitlab-rake gitlab:check

  # open console without entering pod
  kubectl exec -it <toolbox-pod-name> -- gitlab-rails console

  # check the status of DB migrations
  kubectl exec -it <toolbox-pod-name> -- gitlab-rake db:migrate:status
  ```

- **インフラストラクチャ > Kubernetesクラスター**インテグレーションのトラブルシューティング:

  - `kubectl get events -w --all-namespaces`の出力を確認します。
  - `gitlab-managed-apps`ネームスペース内のポッドのログを確認します。

- [初期管理者パスワード](../installation/deployment.md#initial-login)の取得方法:

  ```shell
  # find the name of the secret containing the password
  kubectl get secrets | grep initial-root
  # decode it
  kubectl get secret <secret-name> -ojsonpath={.data.password} | base64 --decode ; echo
  ```

- GitLab PostgreSQLデータベースに接続する方法。

  ```shell
  kubectl exec -it <toolbox-pod-name> -- gitlab-rails dbconsole --include-password --database main
  ```

- Helmインストール状態に関する情報を取得する方法:

  ```shell
  helm status <release name>
  ```

- Helm Chartを使用してインストールされたGitLabを更新する方法:

  ```shell
  helm repo update

  # get current values and redirect them to yaml file (analogue of gitlab.rb values)
  helm get values <release name> > gitlab.yaml

  # run upgrade itself
  helm upgrade <release name> <chart path> -f gitlab.yaml
  ```

  [Helm Chartを使用したGitLabの更新](../installation/upgrade.md)も参照してください。

- GitLab設定への変更を適用する方法:

  - `gitlab.yaml`ファイルを修正します。
  - 変更を適用するには、次のコマンドを実行します:

    ```shell
    helm upgrade <release name> <chart path> -f gitlab.yaml
    ```

- リリースのmanifestを取得する方法。すべてのKubernetesリソースと依存関係のあるチャートに関する情報が含まれているため、役立ちます:

  ```shell
  helm get manifest <release name>
  ```

## KubeSOSレポートのFast-Stats {#fast-stats-for-kubesos-reports}

[KubeSOS](https://gitlab.com/gitlab-com/support/toolbox/kubesos)は、GitLabクラスターの構成と、GitLab Cloud Nativeチャートのデプロイからのログを収集するツールです。最小限のメモリ使用量のツールである[fast-stats](https://gitlab.com/gitlab-com/support/toolbox/fast-stats)を使用して、GitLabログのパフォーマンス統計をすばやく作成して比較できます。

- `fast-stats`の実行:

  ```shell
  cut -d  ' ' -f2- <file-name> | grep ^{ | fast-stats
  ```

- エラーの一覧表示:

  ```shell
  cut -d  ' ' -f2- <file-name> | grep ^{ | fast-stats errors
  ```

- `fast-stats` topの実行:

  ```shell
  cut -d  ' ' -f2- <file-name> | grep ^{ | fast-stats top
  ```

- 印刷される行数を変更します。デフォルトでは、10行が出力されます。

  ```shell
  cut -d  ' ' -f2- <file-name> | grep ^{ | fast-stats -l <number of rows>
  ```

## macOSでのminikube経由での最小GitLab構成のインストール {#installation-of-minimal-gitlab-configuration-via-minikube-on-macos}

このセクションは、[minikubeでのKubernetesの開発](../development/minikube/_index.md)と[Helm](../installation/tools.md)に基づいています。詳細については、それらのドキュメントを参照してください。

- Homebrew経由でKubectlをインストールします:

  ```shell
  brew install kubernetes-cli
  ```

- Homebrew経由でminikubeをインストールします:

  ```shell
  brew cask install minikube
  ```

- minikubeを起動して構成します。minikubeを起動できない場合は、`minikube delete && minikube start`を実行して手順を繰り返してください:

  ```shell
  minikube start --cpus 3 --memory 8192 # minimum amount for GitLab to work
  minikube addons enable ingress
  ```

- Homebrew経由でHelmをインストールして初期化します:

  ```shell
  brew install helm
  ```

- [minikubeの最小値YAMLファイル](https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml)をワークステーションにコピーします:

  ```shell
  curl --output values.yaml "https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml"
  ```

- `minikube ip`の出力でIPアドレスを見つけ、このIPアドレスでYAMLファイルを更新します。

- GitLab Helmチャートをインストールします:

  ```shell
  helm repo add gitlab https://charts.gitlab.io
  helm install gitlab -f <path-to-yaml-file> gitlab/gitlab
  ```

  GitLab設定を一部変更する場合は、上記の構成をベースとして使用し、独自のYAMLファイルを作成できます。

- `helm status gitlab`と`minikube dashboard`を使用して、インストール処理を監視します。インストールには、ワークステーションのリソース量に応じて最大20 ～ 30分かかる場合があります。

- すべてのポッドが`Running`または`Completed`のステータスを表示したら、[最初のログイン](../installation/deployment.md#initial-login)の説明に従ってGitLabパスワードを取得し、UIを使用してGitLabにログインします。`https://gitlab.domain`経由でアクセスできるようになります。ここで、`domain`はYAMLファイルで指定された値です。

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

## `toolbox`ポッドでのRailsコードのパッチ適用 {#patching-the-rails-code-in-the-toolbox-pod}

{{< alert type="warning" >}}

このタスクは、定期的に実行する必要があるものではありません。ご自身の責任で使用してください。

{{< /alert >}}

運用GitLabサービスポッドにパッチを適用するには、変更されたソースコードを含む新しいイメージをビルドする必要があります。これらは直接パッチを適用_できません_。[`toolbox`/`task-runner`ポッド](../charts/gitlab/toolbox/_index.md)には、他の通常のサービスオペレーションを妨げることなく、Railsベースのポッドとして動作するために必要なものがすべて含まれています。これを使用して、独立したタスクを実行したり、ソースコードを一時的に変更して、いくつかのタスクを実行したりできます。

{{< alert type="note" >}}

`toolbox`ポッドを使用して変更を加えた場合、ポッドを再起動しても、それらの変更は保持されません。これらは、コンテナの操作の有効期間中のみ存在します。

{{< /alert >}}

`toolbox`ポッドでソースコードにパッチを適用するには:

1. 適用する目的の`.patch`ファイルをフェッチします:

   - マージリクエストの差分を[パッチファイル](https://docs.gitlab.com/user/project/merge_requests/reviews/#download-merge-request-changes-as-a-patch-file)として直接ダウンロードします。
   - または、`curl`を使用して差分を直接フェッチします。以下の`<mr_iid>`をマージリクエストのIIDに置き換えるか、生の スニペット を指すようにURLを変更します:

     ```shell
     curl --output ~/<mr_iid>.patch "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/<mr_iid>.patch"
     ```

1. `toolbox`ポッドでローカルファイルにパッチを適用します:

   ```shell
   cd /srv/gitlab
   busybox patch -p1 -f < ~/<mr_iid>.patch
   ```
