---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Helmチャートをアンインストールする
---

GitLab Helmチャートをアンインストールするには、次のコマンドを実行します。

```shell
helm uninstall gitlab
```

継続性を保つために、これらのチャートには、`helm uninstall`を実行しても削除されないKubernetesオブジェクトがいくつかあります。これらは、再デプロイする場合に影響があるため、_意識して_削除する必要がある項目です。

- ステートフルデータ用のPVC。これらは_意識して_削除する必要があります。
  - Gitaly:これは、リポジトリデータです。
  - PostgreSQL（内部の場合）：これはメタデータです。
  - Redis（内部の場合）：これはキャッシュとジョブキューであり、安全に削除できます。
- シークレット（共有シークレットジョブによって生成される場合）。これらのチャートは、KubernetesシークレットをHelm経由で直接生成しないように設計されています。そのため、Helmで削除できません。これには、パスワード、暗号化シークレットなどが含まれています。これらは軽率に削除しないでください。
- ConfigMaps
  - `ingress-controller-leader-RELEASE-nginx`:これは、NGINX Ingressコントローラー自体によって生成され、チャートの制御外にあります。安全に削除できます。

PVCとシークレットには、`release`ラベルが設定されているため、以下を使用してこれらを見つけることができます。

```shell
kubectl get pvc,secret -lrelease=gitlab
```

{{< alert type="warning" >}}

シークレット`RELEASE-gitlab-initial-root-password`を手動で削除しない場合、次のリリースで再利用されます。記録されたデモなどで、このパスワードが何らかの形で公開されている場合は、手動で削除する必要があります。これにより、公開されたパスワードが将来のリリースでインスタンスへのサインインに使用できなくなります。

{{< /alert >}}
