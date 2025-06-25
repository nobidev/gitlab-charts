---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: UBIベースのイメージでGitLabチャートをConfigureする
---

GitLabは、イメージの[Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image)バージョンを提供しており、標準イメージをUBIベースのイメージに置き換えることができます。これらのイメージは、`-ubi`拡張子を持つ標準イメージと同じtagを使用します。

{{< alert type="note" >}}

GitLab 17.3より前のUBIベースのイメージは、`-ubi8`拡張子を使用します。

{{< /alert >}}

GitLabチャートは、UBIに基づかないサードパーティ製のイメージを使用します。これらのイメージは主に、Redis、PostgreSQLなどの外部サービスをGitLabに提供します。UBIのみをベースとするGitLabインスタンスをdeployする場合は、内部サービスを無効にし、外部のdeploymentまたはサービスを使用する必要があります。

無効にして外部から提供する必要があるサービスは次のとおりです。

- PostgreSQL
- MinIO（オブジェクトストア）
- Redis

無効にする必要があるサービスは次のとおりです。

- CertManager (Let's Encryptインテグレーション)
- Prometheus
- GitLab Runner

## サンプル値 {#sample-values}

純粋なUBI GitLabのdeploymentを構築するのに役立つ、[`examples/ubi/values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/ubi/values.yaml)のGitLabチャート値の例を提供します。
