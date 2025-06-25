---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Runnerチャートの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimateプラン
- 提供:GitLab Self-Managed

{{< /details >}}

GitLab Runnerサブチャートは、CIジョブを実行するためのGitLab Runnerを提供します。これはデフォルトで有効になっており、S3互換のオブジェクトストレージを使用したキャッシュのサポートにより、すぐに使用できるはずです。

{{< alert type="warning" >}}

含まれているGitLab Runnerチャートのデフォルト設定は、**本番環境を対象としていません**。これは、すべてのGitLabサービスがクラスターにデプロイされる概念実証 (PoC) 実装として提供されます。本番環境のデプロイメントでは、[セキュリティとパフォーマンス上の理由](https://docs.gitlab.com/install/requirements/#gitlab-runner)から、GitLab Runnerを別のマシンにインストールします。詳細については、[リファレンスアーキテクチャドキュメント](../../../installation/_index.md#use-the-reference-architectures)を参照してください。

{{< /alert >}}

## 要件 {#requirements}

GitLab 16.0では、Runner認証トークンを使用してRunnerをregisterする新しいRunner作成GitLabワークフローが導入されました。登録トークンを使用するレガシーGitLabワークフローは非推奨となり、GitLab 17.0ではデフォルトで無効になっています。GitLab 18.0で削除されます。

推奨されるGitLabワークフローを使用するには:

- [Runner認証トークンを生成します。](https://docs.gitlab.com/ci/runners/new_creation_workflow/#prevent-your-runner-registration-workflow-from-breaking)
- `<release>-gitlab-runner-secret` Runnerシークレットを手動で更新します。設定は[`shared-secrets`](../../shared-secrets.md)ジョブで処理されないためです。
- `gitlab-runner.runners.locked`を`null`に設定します:

  ```yaml
  gitlab-runner:
    runners:
      locked: null
  ```

レガシーGitLabワークフローを使用する場合（非推奨）:

- [レガシーGitLabワークフローを再度有効にする](https://docs.gitlab.com/administration/settings/continuous_integration/#enable-runner-registrations-tokens)必要があります。
- 登録トークンは、[`shared-secrets`](../../shared-secrets.md)ジョブによって入力されます。
- GitLab 18.0より前に新しいGitLabワークフローに移行する必要があります。これにより、レガシーGitLabワークフローのサポートが削除されます。

## 設定 {#configuration}

詳細については、[使用方法と設定](https://docs.gitlab.com/runner/install/kubernetes/)に関するドキュメントを参照してください。

## スタンドアロンrunnerのデプロイ {#deploying-a-stand-alone-runner}

デフォルトでは、`gitlabUrl`を推測し、登録トークンを自動的に生成し、`migrations`チャートを介して生成します。実行中のGitLabインスタンスとともにデプロイする場合、この動作は機能しません。

この場合、`gitlabUrl`値を実行中のGitLabインスタンスのURLに設定する必要があります。また、`gitlab-runner`シークレットを手動で作成し、実行中のGitLabによって提供される`registrationToken`を入力する必要があります。

## Docker-in-Dockerの使用 {#using-docker-in-docker}

Docker-in-Dockerを実行するには、必要な機能にアクセスできるように、runnerコンテナに特権を与える必要があります。これを有効にするには、`privileged`の値を`true`に設定します。これがデフォルトで`true`にならない理由については、[アップストリームドキュメント](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#use-privileged-containers-for-the-runners)を参照してください。

### セキュリティに関する懸念 {#security-concerns}

特権コンテナには拡張機能があり、たとえば、実行元のホストから任意のファイルをマウントできます。重要なものが隣で実行されないように、コンテナを分離された環境で実行してください。

## デフォルトのrunner設定 {#default-runner-configuration}

GitLabチャートで使用されるデフォルトのrunner設定は、デフォルトで含まれているMinIOをキャッシュに使用するようにカスタマイズされています。runner `config`値を設定する場合は、独自のキャッシュ設定も設定する必要があります。

```yaml
gitlab-runner:
  runners:
    config: |
      [[runners]]
        [runners.kubernetes]
        image = "ubuntu:22.04"
        {{- if .Values.global.minio.enabled }}
        [runners.cache]
          Type = "s3"
          Path = "gitlab-runner"
          Shared = true
          [runners.cache.s3]
            ServerAddress = {{ include "gitlab-runner.cache-tpl.s3ServerAddress" . }}
            BucketName = "runner-cache"
            BucketLocation = "us-east-1"
            Insecure = false
        {{ end }}
```

カスタマイズされたすべてのGitLab Runnerチャートの設定は、`gitlab-runner`キーの下の[トップレベル`values.yaml`ファイル](https://gitlab.com/gitlab-org/charts/gitlab/raw/master/values.yaml)で利用できます。
