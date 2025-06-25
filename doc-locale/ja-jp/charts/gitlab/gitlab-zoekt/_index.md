---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Zoektチャート
---

{{< details >}}

- プラン:Premium、Ultimate
- 提供形態:GitLab.com、GitLab Self-Managed
- 状態:ベータ

{{< /details >}}

{{< history >}}

- [導入](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049)：GitLab 15.9で[ベータ](https://docs.gitlab.com/policy/development_stages_support/#beta)版として[フラグ](https://docs.gitlab.com/administration/feature_flags/)付きで導入（`index_code_with_zoekt`と`search_code_with_zoekt`）。デフォルトでは無効。
- GitLab 16.6で[GitLab.comで有効化](https://gitlab.com/gitlab-org/gitlab/-/issues/388519)。
- 機能フラグ`index_code_with_zoekt`と`search_code_with_zoekt`は、GitLab 17.1で[削除](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378)されました。

{{< /history >}}

{{< alert type="warning" >}}

この機能は[ベータ](https://docs.gitlab.com/policy/development_stages_support/#beta)版であり、予告なしに変更される場合があります。詳細については、[エピック9404](https://gitlab.com/groups/gitlab-org/-/epics/9404)を参照してください。

{{< /alert >}}

Zoektチャートは、[完全一致コードの検索](https://docs.gitlab.com/user/search/exact_code_search/)をサポートします。`gitlab-zoekt.install`を`true`に設定すると、このチャートをインストールできます。詳細については、[`gitlab-zoekt`](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt)を参照してください。

## Zoektチャートを有効にする {#enable-the-zoekt-chart}

Zoektチャートを有効にするには、次の値を設定します。

```shell
--set gitlab-zoekt.install=true \
--set gitlab-zoekt.replicas=2 \         # Number of Zoekt pods. If you want to use only one pod, you can skip this setting.
--set gitlab-zoekt.indexStorage=128Gi   # Disk size for the Zoekt node. Zoekt requires up to three times the repository's default branch's storage size, depending on the number of large and binary files.
```

## CPUとメモリの使用量を設定する {#set-cpu-and-memory-usage}

次のGitLab.comのデフォルト設定を変更して、Zoektチャートのリクエストと制限を定義できます。

```yaml
  webserver:
    resources:
      requests:
        cpu: 4
        memory: 32Gi
      limits:
        cpu: 16
        memory: 128Gi
  indexer:
    resources:
      requests:
        cpu: 4
        memory: 6Gi
      limits:
        cpu: 16
        memory: 12Gi
  gateway:
    resources:
      requests:
        cpu: 2
        memory: 512Mi
      limits:
        cpu: 4
        memory: 1Gi
```

## GitLabでZoektを設定する {#configure-zoekt-in-gitlab}

{{< history >}}

- GitLab 16.6でシャードはノードに[名称変更](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134717)されました。

{{< /history >}}

GitLabのトップレベルグループに対してZoektを設定するには、次の手順に従います。

1. toolboxポッドのRailsコンソールに接続します。

   ```shell
   kubectl exec <toolbox pod name> -it -c toolbox -- gitlab-rails console -e production
   ```

1. [完全一致コードの検索を有効](https://docs.gitlab.com/integration/exact_code_search/zoekt/#enable-exact-code-search)にします。
1. インデックス作成を設定します。

   {{< tabs >}}

   {{< tab title="GitLab 17.7以降" >}}

   ```shell
   node = ::Search::Zoekt::Node.online.last
   namespace = Namespace.find_by_full_path('<top-level-group-to-index>')
   enabled_namespace = Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
   replica = enabled_namespace.replicas.find_or_create_by(namespace_id: enabled_namespace.root_namespace_id)
   node.indices.create!(zoekt_enabled_namespace_id: enabled_namespace.id, namespace_id: namespace.id, zoekt_replica_id: replica.id)
   ```

   {{< /tab >}}

   {{< tab title="GitLab 17.6以前" >}}

   ```shell
   node = ::Search::Zoekt::Node.online.last
   namespace = Namespace.find_by_full_path('<top-level-group-to-index>')
   enabled_namespace = Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
   replica = enabled_namespace.replicas.find_or_create_by(namespace_id: enabled_namespace.root_namespace_id)
   replica.ready!
   node.indices.create!(zoekt_enabled_namespace_id: enabled_namespace.id, namespace_id: namespace.id, zoekt_replica_id: replica.id, state: :ready)
   ```

      {{< /tab >}}

   {{< /tabs >}}

Zoektは、プロジェクトが更新または作成された後、そのグループ内のプロジェクトのインデックスを作成できるようになりました。最初のインデックス作成では、Zoektがネームスペースのインデックス作成を開始するまで、少なくとも数分待ちます。
