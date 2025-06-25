---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャート用のOpenShiftリソースの準備
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

このドキュメントでは、このプロジェクトの自動化スクリプトを使用して、Google CloudにOpenShiftクラスターを作成する方法について説明します。

## 準備 {#preparation}

まず、GitLabメールに関連付けられたRed Hatアカウントが必要です。Red Hat Allianceの担当者にお問い合わせください。担当者からアカウント招待メールが送信されます。Red Hatアカウントを有効にすると、OpenShiftの実行に必要なライセンスとサブスクリプションにアクセスできるようになります。

Google Cloudでクラスターを起動するには、パブリックCloud DNSゾーンが登録済みドメインに接続され、Google Cloud DNSで構成されている必要があります。ドメインがまだ利用できない場合は、[このガイド](https://github.com/openshift/installer/blob/master/docs/user/gcp/dns.md)の手順に従って作成してください。

### CLIツールとプルシークレットを取得する {#get-the-cli-tools-and-pull-secret}

OpenShiftクラスター (`openshift-install`) を作成し、クラスター (`oc`) を操作するには、2つのCLIツールが必要です。

Red HatのプライベートDockerレジストリからイメージをフェッチするには、プルシークレットが必要です。すべてのデベロッパーは、Red Hatアカウントに関連付けられた異なるプルシークレットを持っています。

CLIツールとプルシークレットを取得するには、[Red Hatのクラウド](https://cloud.redhat.com/openshift/install/gcp/installer-provisioned)にアクセスし、Red Hatアカウントでログインしてください。このページで、提供されているリンクを使用して、インストーラーとコマンドラインツールの最新バージョンをダウンロードします。これらのパッケージを解凍し、`openshift-install`と`oc`を`PATH`に配置します。

プルシークレットをクリップボードにコピーし、このリポジトリのルートにあるファイル`pull_secret`にコンテンツを書き込みます。このファイルはgitignoreされています。

### Google Cloud (GCP) サービスアカウントを作成する {#create-a-google-cloud-gcp-service-account}

[これらの手順](https://docs.openshift.com/container-platform/4.9/installing/installing_gcp/installing-gcp-account.html#installation-gcp-service-account_installing-gcp-account)に従って、Google Cloud `cloud-native`プロジェクトにサービスアカウントを作成します。そのドキュメントで必須とマークされているすべてのロールをアタッチします。サービスアカウントが作成されたら、JSONキーを生成し、このリポジトリのルートに`gcloud.json`として保存します。このファイルはgitignoreされています。

## OpenShiftクラスターを作成する {#create-your-openshift-cluster}

OpenShiftクラスターを作成するには:

1. GitLab Operatorリポジトリをクローンします:

   ```shell
   git clone https://gitlab.com/gitlab-org/cloud-native/gitlab-operator.git
   ```

1. スクリプトを実行して、Google CloudでOpenShiftクラスターを作成します:

   ```shell
   cd gitlab-operator
   ./scripts/create_openshift_cluster.sh
   ```

これは、3つのコントロールプレーン (master) ノードと3つのworkerノードを持つ6ノードのクラスターになります。このプロセスには約40分かかります。コンソール出力の最後にある手順に従って、クラスターに接続します。

作成されると、[Red Hatクラウド](https://cloud.redhat.com/openshift/)にクラスターが登録されていることを確認できるはずです。すべてのインストールログとメタデータは、このリポジトリの`install-$CLUSTER_NAME/`ディレクトリに保存されます。このディレクトリはgitignoreされています。

### 設定オプション {#configuration-options}

設定は、環境変数を設定することにより、ランタイム時に適用できます。すべてのオプションにはデフォルト値があるため、オプションは必要ありません。

| 変数                         | デフォルト                                      | 説明 |
|----------------------------------|----------------------------------------------|-------------|
| `CLUSTER_NAME`                   | `ocp-$USER`                                  | クラスターの名前 |
| `BASE_DOMAIN`                    | `k8s-ft.win`                                 | クラスターのルートドメイン |
| `GCP_PROJECT_ID`                 | `cloud-native-182609`                        | Google CloudプロジェクトID |
| `GCP_REGION`                     | `us-central1`                                | クラスターのGoogle Cloudリージョン |
| `GOOGLE_APPLICATION_CREDENTIALS` | `gcloud.json`                                | Google CloudサービスアカウントJSONファイルへのパス |
| `GOOGLE_CREDENTIALS`             | `$GOOGLE_APPLICATION_CREDENTIALS`のコンテンツ | Google CloudサービスアカウントJSONファイルのコンテンツ |
| `PULL_SECRET_FILE`               | `pull_secret`                                | Red Hatプルシークレットファイルへのパス |
| `PULL_SECRET`                    | `$PULL_SECRET_FILE`のコンテンツ               | Red Hatプルシークレットファイルのコンテンツ |
| `SSH_PUBLIC_KEY_FILE`            | `$HOME/.ssh/id_rsa.pub`                      | SSH公開鍵ファイルへのパス |
| `SSH_PUBLIC_KEY`                 | `$SSH_PUBLIC_KEY_FILE`のコンテンツ            | SSH公開鍵ファイルの内容 |
| `LOG_LEVEL`                      | `info`                                       | `openshift-install`出力の詳細度 |
| `INSTALL_DIR`                    | `install-$CLUSTER_NAME`                      | 複数のクラスターの起動に役立つ、インストールアセットのディレクトリ |

{{< alert type="note" >}}

変数`CLUSTER_NAME`と`BASE_DOMAIN`は組み合わされて、クラスターのドメイン名を構築します。

{{< /alert >}}

## OpenShiftクラスターを削除する {#destroy-your-openshift-cluster}

OpenShiftクラスターを削除するには:

1. GitLab Operatorリポジトリをクローンします:

   ```shell
   git clone https://gitlab.com/gitlab-org/cloud-native/gitlab-operator.git
   ```

1. スクリプトを実行して、Google CloudでOpenShiftクラスターを削除します。これには約4分かかります:

   ```shell
   cd gitlab-operator
   ./scripts/destroy_openshift_cluster.sh
   ```

設定は、次の環境変数を設定することにより、ランタイム時に適用できます。すべてのオプションにはデフォルト値があるため、オプションは必要ありません。

| 変数                         | デフォルト------------------------------------- | 説明 |
|----------------------------------|----------------------------------------------|-------------|
| `GOOGLE_APPLICATION_CREDENTIALS` | `gcloud.json`                                | Google CloudサービスアカウントJSONファイルへのパス |
| `GOOGLE_CREDENTIALS`             | `$GOOGLE_APPLICATION_CREDENTIALS`のコンテンツ | Google CloudサービスアカウントJSONファイルのコンテンツ |
| `LOG_LEVEL`                      | `info`                                       | `openshift-install`出力の詳細度 |
| `INSTALL_DIR`                    | `install-$CLUSTER_NAME`                      | 複数のクラスターの起動に役立つ、インストールアセットのディレクトリ |

## 次のステップ {#next-steps}

クラスターが起動して実行されたら、[GitLabのインストール](https://docs.gitlab.com/operator/)を続行できます。

## リソース {#resources}

- [`openshift-installer`のソースコード](https://github.com/openshift/installer)
- [`oc`のソースコード](https://github.com/openshift/oc)
- [`openshift-installer`および`oc`パッケージ](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/)
- [OpenShift Container Project (OCP) アーキテクチャドキュメント](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.9/html/architecture/architecture)
- [OpenShift GCPドキュメント](https://docs.openshift.com/container-platform/4.9/installing/installing_gcp/installing-gcp-account.html)
- [OpenShiftトラブルシューティングガイド](https://docs.openshift.com/container-platform/4.9/support/troubleshooting/troubleshooting-installations.html)
