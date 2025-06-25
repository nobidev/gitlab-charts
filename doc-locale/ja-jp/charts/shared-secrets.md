---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Shared-Secretsジョブの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

`shared-secrets`ジョブは、特に手動で指定しない限り、インストール全体で使用されるさまざまなシークレットのプロビジョニングを行います。内容は以下のとおりです。

1. 初期rootパスワード
1. すべてのパブリックサービスに対する自己署名TLS証明書:GitLab、MinIO、およびレジストリ
1. レジストリ認証
1. MinIO、レジストリ、GitLab Shell、およびGitalyシークレット
1. RedisおよびPostgreSQLパスワード
1. SSHホストキー
1. [暗号化された認証情報](https://docs.gitlab.com/administration/encrypted_configuration/)のGitLab Railsシークレット

## インストールコマンドラインオプション {#installation-command-line-options}

以下のテーブルには、`--set`フラグを使用して`helm install`コマンドに指定できるすべての設定が含まれています。

| パラメータ                    | デフォルト                                                    | 説明 |
|------------------------------|------------------------------------------------------------|-------------|
| `enabled`                    | `true`                                                     | [下記参照](#disable-functionality) |
| `env`                        | `production`                                               | Rails環境 |
| `podLabels`                  |                                                            | 補足のPodラベル。セレクターには使用されません。 |
| `annotations`                |                                                            | 補足のPodアノテーション。 |
| `image.pullPolicy`           | `Always`                                                   | **非推奨**:代わりに`global.kubectl.image.pullPolicy`を使用してください。 |
| `image.pullSecrets`          |                                                            | **非推奨**:代わりに`global.kubectl.image.pullSecrets`を使用してください。 |
| `image.repository`           | `registry.gitlab.com/gitlab-org/build/cng/kubectl`         | **非推奨**:代わりに`global.kubectl.image.repository`を使用してください。 |
| `image.tag`                  | `1f8690f03f7aeef27e727396927ab3cc96ac89e7`                 | **非推奨**:代わりに`global.kubectl.image.tag`を使用してください。 |
| `priorityClassName`          |                                                            | ポッドに割り当てられた[優先度クラス](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) |
| `rbac.create`                | `true`                                                     | RBACロールとバインディングを作成 |
| `resources`                  |                                                            | リソースリクエスト、制限 |
| `securityContext.fsGroup`    | `65534`                                                    | ファイルシステムのマウントに使用するユーザーID |
| `securityContext.runAsUser`  | `65534`                                                    | コンテナの実行に使用するユーザーID |
| `selfsign.caSubject`         | `GitLab Helm Chart`                                        | selfsign CAサブジェクト |
| `selfsign.image.repository`  | `registry.gitlab.com/gitlab-org/build/cnf/cfssl-self-sign` | selfsignイメージリポジトリ |
| `selfsign.image.pullSecrets` |                                                            | イメージリポジトリのシークレット |
| `selfsign.image.tag`         |                                                            | selfsignイメージtag |
| `selfsign.keyAlgorithm`      | `rsa`                                                      | selfsign証明書キーアルゴリズム |
| `selfsign.keySize`           | `4096`                                                     | selfsign証明書キーサイズ |
| `serviceAccount.enabled`     | `true`                                                     | ジョブのserviceAccountNameを定義します |
| `serviceAccount.create`      | `true`                                                     | ServiceAccountの作成 |
| `serviceAccount.name`        | `RELEASE_NAME-shared-secrets`                              | ジョブ（および`serviceAccount.create=true`の場合はserviceAccount自体）で指定するサービスアカウント名 |
| `tolerations`                | `[]`                                                       | ポッド割り当てのTolerationラベル |

## ジョブ設定の例 {#job-configuration-examples}

### `tolerations` {#tolerations}

`tolerations`を使用すると、taintされたworkerノードでポッドをスケジュールできます

`tolerations`の使用例を以下に示します。

```yaml
tolerations:
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoExecute"
```

## 機能の無効化 {#disable-functionality}

一部のユーザーは、このジョブによって提供される機能を明示的に無効にしたい場合があります。これを行うために、ブール値として`enabled`フラグを提供しました。`true`がデフォルトです。

ジョブを無効にするには、`--set shared-secrets.enabled=false`を渡すか、`-f`フラグを介してYAMLで以下を`helm`に渡します。

```yaml
shared-secrets:
  enabled: false
```

{{< alert type="note" >}}

このジョブを無効にする場合は、すべてのシークレットを手動で作成し、必要なシークレットコンテンツをすべて提供**する**必要があります。詳細については、[installation/secrets](../installation/secrets.md#manual-secret-creation-optional)を参照してください。

{{< /alert >}}
