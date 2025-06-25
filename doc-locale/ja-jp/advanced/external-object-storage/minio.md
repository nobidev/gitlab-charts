---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートでMinIOを設定
---

[MinIO](https://min.io/)は、S3互換APIを公開するオブジェクトストレージサーバーです。

MinIOは、いくつかの異なるプラットフォームにデプロイできます。新しいMinIO[インスタンス](https://min.io/docs/minio/linux/index.html)を起動するには、[クイックスタートガイド](https://min.io/docs/minio/linux/index.html)に従ってください。[TLSでMinIOサーバーへのアクセスをSecure](https://min.io/docs/minio/linux/operations/network-encryption.html)にしてください。

GitLabを外部[MinIO](https://min.io/)インスタンスに[接続中](https://min.io/)するには、まずこの[設定ファイル](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/values-external-objectstorage.yaml)の[バケット](https://min.io/)名を使用して、GitLabアプリケーション用のMinIO[バケット](https://min.io/)をCreateしてください。

[MinIOクライアント](https://min.io/docs/minio/kubernetes/upstream/)を使用して、使用前に必要な[バケット](https://min.io/docs/minio/kubernetes/upstream/)をCreateしてください。

```shell
mc mb gitlab-registry-storage
mc mb gitlab-lfs-storage
mc mb gitlab-artifacts-storage
mc mb gitlab-uploads-storage
mc mb gitlab-packages-storage
mc mb gitlab-backup-storage
```

バケットが作成されると、GitLabがMinIOインスタンスを使用するようにConfigureできます。[examples](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage)フォルダーの[`rails.minio.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.minio.yaml)と[`registry.minio.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.minio.yaml)の[設定](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.minio.yaml)例を参照してください。
