---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートを使用したGKEのワークロードアイデンティティフェデレーション
---

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3434)：GitLab 17.0。

{{< /history >}}

チャート内の外部オブジェクトストレージのデフォルト設定では、シークレットキーが使用されます。[GKEのワークロードアイデンティティフェデレーション](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity)を使用すると、短寿命トークンを使用してKubernetesクラスターにオブジェクトストレージへのアクセスを許可できます。既存のGKEクラスターがある場合は、[ノードプールを更新してワークロードアイデンティティフェデレーションを使用する方法に関するGoogleドキュメント](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#option_2_node_pool_modification)をお読みください。

ワークロードアイデンティティを使用するには、`google_json_key_string`の[`object-storage.yaml`](../../charts/globals.md#connection)シークレットの`google_json_key_string`を省略します。

```yaml
provider: Google
google_project: your-project-id
google_client_email: null  # Will use workload identity
google_json_key_string: null  # Will use workload identity
```

## トラブルシューティング {#troubleshooting}

[Kubernetesサービスアカウントが](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubernetes-sa-to-iam)、`iam.gke.io/gcp-service-account`アノテーションを介してIAMサービスアカウントにリンクされていることを確認してください。

toolboxポッド内でメタデータエンドポイントにクエリを実行して、ワークロードアイデンティティが適切に設定されているかどうかを確認できます。クラスターに関連付けられたサービスアカウントが返されるはずです。

```shell
$ curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email
example@your-example-project.iam.gserviceaccount.com
```

このアカウントは、次のスコープにもアクセスできる必要があります。

```shell
$ curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/scopes
https://www.googleapis.com/auth/cloud-platform
https://www.googleapis.com/auth/userinfo.email
```
