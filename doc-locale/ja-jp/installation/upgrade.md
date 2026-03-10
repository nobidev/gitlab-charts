---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Helmチャートインスタンスのアップグレード
---

{{< details >}}

- プラン: Free、Premium、Ultimate
- 提供形態: GitLab Self-Managed

{{< /details >}}

GitLab Helmチャートインスタンスを、より新しいバージョンのGitLabにアップグレードします。

## 前提条件 {#prerequisites}

GitLab Helmチャートインスタンスをアップグレードする前に:

1. [アップグレードする前に必要な情報](https://docs.gitlab.com/update/plan_your_upgrade/)を参照してください。
1. GitLab HelmチャートのバージョンはGitLabのバージョンと同じ番号体系ではないため、必要なGitLab Helmチャートのバージョンを見つけるには、[バージョンマッピング](version_mappings.md)を参照してください。
1. アップグレード先の特定リリースに対応する[変更履歴](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/CHANGELOG.md)を参照してください。
1. 8.x以前のバージョンのGitLab Helmチャートバージョンからアップグレードする場合は、[GitLabドキュメントアーカイブ](https://docs.gitlab.com/archives/)を参照して、ドキュメントの古いバージョンにアクセスしてください。
1. [バックアップ](../backup-restore/_index.md)を実行します。

## GitLab Helmチャートインスタンスのアップグレード {#upgrade-a-gitlab-helm-chart-instance}

GitLab Helmチャートインスタンスをアップグレードするには:

1. ワークフローを妨げないように、アップグレード中に[メンテナンスモードをオンにすること](https://docs.gitlab.com/administration/maintenance_mode/)を検討して、ユーザーが書き込み操作を実行できないように制限します。
1. ターゲットのGitLabバージョンと同じバージョンに[GitLab Runner](https://docs.gitlab.com/runner/install/)をアップグレードします。
1. 以前に提供された値を抽出します:

   ```shell
   helm get values gitlab > gitlab.yaml
   ```

1. アップグレード時に引き継ぐ必要のあるすべての値を決定します。明示的に設定する最小限の値のセットのみを保持し、アップグレードプロセス中にそれらを渡す必要があります。それ以外の場合は、GitLabのデフォルト値を使用する必要があります。

### ダウンタイムなしでアップグレード {#upgrade-with-zero-downtime}

オフラインにせずに、ライブGitLab環境をアップグレードします。

#### 要件 {#requirements}

ダウンタイムなしのアップグレードプロセスには、以下が必要です:

- WebサービスとSidekiq用に複数のレプリカが設定されたマルチノードGitLab Helmチャートデプロイ。
- 一度に1つのマイナーリリースをアップグレードします。したがって、18.0から18.1へはアップグレードできますが、18.2へはアップグレードできません。リリースをスキップすると、データベースの変更が間違った順序で実行され、データベーススキーマが破損した状態になる可能性があります。

#### 考慮事項 {#considerations}

ダウンタイムなしのアップグレードを検討する場合は、以下に注意してください:

- [Gitaly in Kubernetesはダウンタイムなしのアップグレードをサポートしていません](https://gitlab.com/gitlab-org/gitaly/-/work_items/6934)。ダウンタイムが必要です。
- ほとんどの場合、パッチリリースが最新でない場合、パッチリリースから次のマイナーリリースに安全にアップグレードできます。たとえば、18.0.5から18.1.0へのアップグレードは、18.0.6が存在する場合でも安全です。アップグレードするバージョンの[バージョン固有のアップグレード](https://docs.gitlab.com/update/versions/)に関する注記を確認することを推奨します。
- デプロイに、ローリングアップデート中に新旧両方のポッドを同時に実行するのに十分なリソースがあることを確認してください。必要な追加リソースの量は、maxSurge設定によって異なります。たとえば、maxSurgeの場合: 10%の場合、新しいポッドで使用するために10%の追加容量が必要です。

#### 推奨されるデプロイ設定 {#recommended-deployment-settings}

スムーズなローリングアップデートを保証するには、以下の設定は、アップグレードプロセスを制御し、ダウンタイムなしを達成するために必要です。

これらの設定は、ベースラインの推奨事項です。これらは、デプロイのリソース可用性、レプリカ数、およびパフォーマンス要件に基づいて調整する必要があります。アップグレード中に一時的に追加のポッドを作成する`maxSurge`設定をサポートするのに十分なクラスターリソースがあることを確認してください。

> [!warning]
> これらのローリングアップデート設定が設定されていない既存のGitLabデプロイがある場合は、ダウンタイムなしのアップグレードを試みる前に、それらを適用する必要があります。これらの設定を初めて適用すると、ポッドのローリング再起動がトリガーされ、短いサービス中断が発生する可能性があります。
>
> 影響を最小限に抑えるには、計画されたアップグレードの前に、メンテナンス時間中にこれらの設定を適用します。設定後、将来のアップグレードはダウンタイムなしで実行できます。

  ```yaml
  global:
    extraEnv:
      BYPASS_SCHEMA_VERSION: true
  gitlab:
    webservice:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 60
    sidekiq:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 600
    gitlab-shell:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 60
    registry:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 60

  nginx-ingress:
    controller:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 300
      minReadySeconds: 10
  ```

> [!note]
> Sidekiqの`terminationGracePeriodSeconds`を設定するときは、猶予期間が満了する前に、最も長く実行されているジョブが完了するのに十分な時間があることを確認する必要があります。

これらの設定により、以下が保証されます:

- アップデート中、少なくとも1つのポッドが常に利用可能です。
- 古いポッドが終了する前に、新しいポッドが起動されます。
- ポッドには、正常にシャットダウンして接続をドレインする時間があります。
- ポッドは、準備完了と見なされる前に安定しています。

#### アップグレードプロセス {#upgrade-process}

> [!note]
> 以下で使用されるデプロイメント名は、デフォルトのGitLab Helmチャートインストールに基づいた例です。デプロイメント名は、複数のSidekiqキューをデプロイする場合など、設定によって異なる場合があります。
>
> インストールに適したデプロイメント名を見つけるには:
>
> ```shell
> kubectl get deployments -lapp=webservice -n <namespace>
> kubectl get deployments -lapp=sidekiq -n <namespace>
> ```

GitLabをアップグレードするには

1. デプロイメントを一時停止します:

   ```shell
   kubectl rollout pause deployment/gitlab-webservice-default
   kubectl rollout pause deployment/gitlab-sidekiq-all-in-1-v2
   ```

1. 新しいバージョンへのアップグレードを開始します:
   
   ```shell
   helm upgrade gitlab gitlab/gitlab \
   --version <GitLab Helm chart version> \
   -f values.yaml \
   --set gitlab.migrations.extraEnv.SKIP_POST_DEPLOYMENT_MIGRATIONS=true
   ```

1. 事前移行とアップグレードの完了を待ちます:

   ```shell
   kubectl get jobs -lrelease=gitlab,chart=migrations-<GitLab version> -n <namespace>
   kubectl wait --for=condition=complete job/<job name> --timeout=600s
   ```

1. Sidekiqのデプロイメントの一時停止を解除します:

   ```shell
   kubectl rollout resume deployment/gitlab-sidekiq-all-in-1-v2
   kubectl rollout status deployment/gitlab-sidekiq-all-in-1-v2 --timeout=15m
   ```

1. Webサービスのデプロイメントの一時停止を解除します:

   ```shell
   kubectl rollout resume deployment/gitlab-webservice-default
   kubectl rollout status deployment/gitlab-webservice-default --timeout=15m
   ```

1. 移行後の処理を実行します:

   ```shell
   helm upgrade gitlab gitlab/gitlab \
   --version <GitLab Helm chart version> \
   -f values.yaml
   ```

1. 移行後の処理が完了するまで待ちます:

   ```shell
   kubectl get jobs -lrelease=gitlab,chart=migrations-<GitLab version> -n <namespace>
   kubectl wait --for=condition=complete job/<job name> --timeout=600s
   ```

   > [!note]
   > デプロイによっては、移行の完了までの`600s`タイムアウト時間が十分でない場合があります。このタイムアウトをニーズに合わせて長くしたり、ジョブを定期的にチェックして、次の手順に進む前に完了していることを確認したりできます。

### ダウンタイムありでアップグレード {#upgrade-with-downtime}

1. 前の手順で抽出およびレビューした値を使用して、アップグレードを実行します:

   ```shell
   helm upgrade gitlab gitlab/gitlab \
   --version <new version> \
   -f gitlab.yaml \
   --set gitlab.migrations.enabled=true \
   --set ...
   ```

   メジャーデータベースのアップグレード中は、`gitlab.migrations.enabled`を`false`に設定する必要があります。将来のアップデートのために、明示的に`true`に戻すようにしてください。

## アップグレード後 {#after-you-upgrade}

1. 有効になっている場合は、[メンテナンスモードをオフにします](https://docs.gitlab.com/administration/maintenance_mode/#disable-maintenance-mode)。
1. [アップグレードヘルスチェック](https://docs.gitlab.com/update/plan_your_upgrade/#run-upgrade-health-checks)を実行します。

## 関連トピック {#related-topics}

1. [Linuxパッケージインストールでのダウンタイムなしのアップグレード](https://docs.gitlab.com/update/zero_downtime/)
1. [アップグレードパス](https://docs.gitlab.com/update/upgrade_paths/)
1. [GitLabアップグレードノート](https://docs.gitlab.com/update/versions/)
