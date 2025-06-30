---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートにカスタムのDockerイメージを使用する
---

特定のシナリオ(オフライン環境など)では、インターネットからDockerイメージをプルするのではなく、独自のDockerイメージを使用したい場合があります。これを行うには、GitLabのリリースを構成する各チャートに対して、独自のDockerイメージレジストリ/リポジトリを指定する必要があります。

## デフォルトイメージ形式 {#default-image-format}

ほとんどの場合、イメージに対するデフォルトの形式には、tagを除外するイメージへのフルパスが含まれています。

```yaml
image:
  repository: repo.example.com/image
  tag: custom-tag
```

最終的な結果は`repo.example.com/image:custom-tag`になります。

## 現在のイメージとtag {#current-images-and-tags}

アップグレードをPlanする場合、現在の`values.yaml`とGitLabチャートのターゲットバージョンを使用して、[Helmテンプレート](https://helm.sh/docs/helm/helm_template/)を生成できます。このテンプレートには、指定されたチャートのバージョンに必要なイメージとそれぞれのタグが含まれます。

```shell
# Gather the latest values
helm get values gitlab > gitlab.yaml

# Use the gitlab.yaml to find the images and tags
helm template versionfinder gitlab/gitlab -f gitlab.yaml --version 7.3.0 | grep 'image:' | tr -d '[[:blank:]]' | sort --unique
```

このコマンドを使用して、カスタム設定をVerifyすることもできます。

## 値ファイルの例 {#example-values-file}

カスタムのDockerレジストリ/リポジトリとタグをConfigureする方法を示す[値ファイルの例](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/custom-images/values.yaml)があります。このファイルの関連セクションをコピーして、独自のリリースに使用できます。

{{< alert type="note" >}}

一部のチャート(特にサードパーティのチャート)では、イメージのレジストリ/リポジトリとタグの指定方法が若干異なる場合があります。サードパーティ[チャート](https://artifacthub.io/)のドキュメントは、[Artifact Hub](https://artifacthub.io/)にあります。

{{< /alert >}}
