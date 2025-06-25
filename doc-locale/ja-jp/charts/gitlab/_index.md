---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Helmサブチャート
---

GitLab Helmチャートは複数のサブチャートで構成されており、コアのGitLabコンポーネントを提供します。

- [Gitaly](gitaly/_index.md)
- [GitLab Exporter](gitlab-exporter/_index.md)
- [GitLab Pages](gitlab-pages/_index.md)
- [GitLab Runner](gitlab-runner/_index.md)
- [GitLab Shell](gitlab-shell/_index.md)
- [GitLabエージェントサーバー (KAS)](kas/_index.md)
- [Mailroom](mailroom/_index.md)
- [移行](migrations/_index.md)
- [Praefect](praefect/_index.md)
- [Sidekiq](sidekiq/_index.md)
- [Spamcheck](spamcheck/_index.md)
- [Toolbox](toolbox/_index.md)
- [Webservice](webservice/_index.md)

各サブチャートのパラメータは、`gitlab`キーの下にある必要があります。たとえば、GitLab Shellのパラメータは次のようになります。

```yaml
gitlab:
  gitlab-shell:
    ...
```

オプションのdependenciesには、これらのチャートを使用してください。

- [MinIO](../minio/_index.md)
- [NGINX](../nginx/_index.md)
- [HAProxy](../haproxy/_index.md)
- [PostgreSQL](https://artifacthub.io/packages/helm/bitnami/postgresql)
- [Redis](https://artifacthub.io/packages/helm/bitnami/redis)
- [レジストリ](../registry/_index.md)
- [Traefik](../traefik/_index.md)

オプションの追加として、これらのチャートを使用します。

- [Prometheus](https://artifacthub.io/packages/helm/prometheus-community/prometheus)
- Kubernetes executorを使用する[_特権のない_](https://docs.gitlab.com/runner/install/kubernetes.html#running-docker-in-docker-containers-with-gitlab-runner) [GitLab Runner](https://docs.gitlab.com/runner/)
- [Let's Encrypt](https://letsencrypt.org/)から自動[プロビジョニング](https://cert-manager.io/docs/)された[SSL](https://venafi.com/jetstack-consult/)。[Jetstack](https://venafi.com/jetstack-consult/)の[cert-manager](https://cert-manager.io/docs/)と[certmanager-issuer](../certmanager-issuer/_index.md)を使用します

## GitLab Helmサブチャートのオプションパラメータ {#gitlab-helm-subchart-optional-parameters}

### affinity {#affinity}

{{< history >}}

- `webservice`および`sidekiq`を除くすべてのGitLab Helmサブチャートに対して、GitLab 17.3 (Charts 8.3) で[導入されました](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3770)。

{{< /history >}}

`affinity`は、すべてのGitLab Helmサブチャートのオプションパラメータです。設定すると、[グローバル`affinity`](../globals.md#affinity)値よりも優先されます。`affinity`の詳細については、[関連するKubernetesドキュメント](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)を参照してください。

{{< alert type="note" >}}

`webservice`および`sidekiq` [Helm Chart](../globals.md#affinity)は、[グローバル`affinity`](../globals.md#affinity)値のみを使用できます。ローカル`affinity`が`webservice`および`sidekiq`に実装される時期については、[イシュー25403](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25403)を参照してください。

{{< /alert >}}

`affinity`を使用すると、次のいずれかまたは両方を設定できます。

- 次の`podAntiAffinity`ルール：
  - `topology key`に対応する式に一致するポッドと同じドメインにポッドをスケジュールしません。
  - 2つのモードの`podAntiAffinity`ルールを設定します。必須 (`requiredDuringSchedulingIgnoredDuringExecution`) および優先 (`preferredDuringSchedulingIgnoredDuringExecution`)。`values.yaml`の`antiAffinity`変数を使用して、優先モードが適用されるように設定を`soft`に設定するか、必須モードが適用されるように`hard`に設定します。
- 次の`nodeAffinity`ルール：
  - 特定のゾーンに属するノードにポッドをスケジュールします。
  - 2つのモードの`nodeAffinity`ルールを設定します。必須 (`requiredDuringSchedulingIgnoredDuringExecution`) および優先 (`preferredDuringSchedulingIgnoredDuringExecution`)。`soft`に設定すると、優先モードが適用されます。`hard`に設定すると、必須モードが適用されます。このルールは、`registry` chart、`gitlab` chart、および`webservice`および`sidekiq`を除くすべてのサブchartに対してのみ実装されます。

`nodeAffinity`は、[`In`演算子](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#operators)のみを実装します。

次の例では、`affinity`を設定し、`nodeAffinity`と`antiAffinity`の両方を`hard`に設定します。

```yaml
nodeAffinity: "hard"
antiAffinity: "hard"
affinity:
  nodeAffinity:
    key: "test.com/zone"
    values:
    - us-east1-a
    - us-east1-b
  podAntiAffinity:
    topologyKey: "test.com/hostname"
```
