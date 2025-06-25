---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートを使用する際のAzureワークロードアイデンティティ
---

チャート内の外部オブジェクトストレージのデフォルト設定は、シークレットキーを使用します。[Azureワークロードアイデンティティ](https://azure.github.io/azure-workload-identity/docs/)を使用すると、有効期間の短いトークンを使用して、Kubernetesクラスターへのオブジェクトストレージへのアクセスを許可できます。[Azure Kubernetes Service (AKS) クラスターにワークロードアイデンティティをデプロイおよび設定する方法に関するMicrosoftのドキュメント](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster)をお読みください。

## 要件 {#requirements}

オブジェクトストレージでワークロードアイデンティティを使用するには、以下が必要です。

1. OpenID Connect (OIDC) Issuerが有効になっているAKSクラスター。
1. `Storage Blob Data Contributor`ロールが割り当てられたAzureマネージドID。
1. アノテーション`azure.workload.identity/client-id: <CLIENT ID>`を使用して、マネージドIDに関連付けられたKubernetesサービスアカウント。

ワークロードアイデンティティをアクティブ化するには、各ポッドに`azure.workload.identity/use: "true"`ラベルが必要です。これはポッド**ラベル**であり、アノテーションではありません。

## チャートの設定 {#chart-configuration}

### レジストリ {#registry}

{{< history >}}

- GitLab 17.9で[ベータ](https://gitlab.com/gitlab-org/container-registry/-/issues/1431)機能として[導入](https://gitlab.com/gitlab-org/container-registry/-/issues/1431)。

{{< /history >}}

レジストリに対するワークロードアイデンティティのサポートはベータ版です。ワークロードアイデンティティは、ポッドラベルを設定することで有効にできます。

```plaintext
--set registry.podLabels."azure\.workload\.identity/use"=true
```

[`registry-storage.yaml`](../../charts/registry/_index.md#storage)シークレットを作成する際は、以下を行う必要があります。

1. `azure_v2`ストレージ設定を使用します。
1. `credentialstype`を`default_credentials`に設定します。

次に例を示します。

```yaml
azure_v2:
  accountname: accountname
  container: containername
  credentialstype: default_credentials
  realm: core.windows.net
```

`azure_v2`ストレージドライバーはワークロードアイデンティティをサポートしますが、`azure`ドライバーはサポートしません。現在`azure`ドライバーを使用しており、ワークロードアイデンティティを使用する場合は、`azure_v2`ドライバーに移行してください。詳細については、[`azure_v2`ドキュメント](https://gitlab.com/gitlab-org/container-registry/-/blob/3ebb5bffd3f6cfbf4479b1b8a4079d842a1c8025/docs/storage-drivers/azure_v2.md)を参照してください。

### LFS、アーティファクト、アップロード、パッケージ {#lfs-artifacts-uploads-packages}

LFS、アーティファクト、アップロード、およびパッケージの場合、IAMロールは、`webservice`、`sidekiq`、および`toolbox`設定のアノテーションキーを介して指定できます。

```shell
--set gitlab.sidekiq.podLabels."azure\.workload\.identity/use"="true"
--set gitlab.webservice.podLabels."azure\.workload\.identity/use"="true"
--set gitlab.toolbox.podLabels."azure\.workload\.identity/use"="true"
```

[`object-storage.yaml`](../../charts/globals.md#connection)シークレットの場合は、`azure_storage_access_key`を省略します。

```yaml
provider: AzureRM
azure_storage_account_name: YOUR_AZURE_STORAGE_ACCOUNT_NAME
azure_storage_domain: blob.core.windows.net
```

### バックアップ {#backups}

Toolboxの設定では、ポッドラベルを設定できます。

```shell
--set gitlab.toolbox.podLabels."azure\.workload\.identity/use"="true"
```

`gitlab.toolbox.backups.objectStorage.config.secret`シークレットに保存されている[`azure-backup-conf.yaml`](../../backup-restore/_index.md)の場合は、`azure_storage_access_key`を省略します。

```yaml
# azure-backup-conf.yaml
azure_storage_account_name: <storage account>
azure_storage_domain: blob.core.windows.net # optional
```

## トラブルシューティング {#troubleshooting}

Azureワークロードアイデンティティが正しく設定され、GitLabがAzure Blobストレージにアクセスしているかどうかを`toolbox`ポッドにログインしてテストできます (GitLabが存在するネームスペースで`<namespace>`を置き換えます)。

```shell
kubectl exec -ti $(kubectl get pod -n <namespace> -lapp=toolbox -o jsonpath='{.items[0].metadata.name}') -n <namespace> -- bash
```

まず、必要な環境変数が存在するかどうかを確認します。

- `AZURE_TENANT_ID`
- `AZURE_FEDERATED_TOKEN_FILE`
- `AZURE_CLIENT_ID`

たとえば、次のように表示されます。

```shell
$ env | grep AZURE
AZURE_TENANT_ID=abcdefghi-c2c5-43d6-b426-1d8c9e8e7ad1
AZURE_FEDERATED_TOKEN_FILE=/var/run/secrets/azure/tokens/azure-identity-token
AZURE_AUTHORITY_HOST=https://login.microsoftonline.com/
AZURE_CLIENT_ID=123456789-abcd-12ab-89ca-cb379118f978
```

次に、`azcopy`を使用してblobコンテナ内のファイルを一覧表示します。

```shell
export AZCOPY_AUTO_LOGIN_TYPE=workload
azcopy --log-level debug list https://<YOUR STORAGE ACCOUNT NAME>.blob.core.windows.net/<YOUR AZURE BLOB CONTAINER NAME>
```

認証が成功すると、次のメッセージがblobコンテナの内容とともに表示されます。

```plaintext
INFO: Login with Workload Identity succeeded
INFO: Authenticating to source using Azure AD
```

401または403エラーが表示された場合は、マネージドIDの設定を確認してください。一般的なエラーを次に示します。

1. Azureストレージアカウントとblobコンテナ名のスペルを確認します。
1. `kubectl describe pod <pod>`を使用して、ポッドに正しいKubernetesサービスアカウントと`azure.workload.identity/use: "true"`ポッドラベルがあることを確認します。
1. マネージドIDの場合は、フェデレーション認証情報の設定に、正しい発行者URL、ネームスペース、および関連付けられたKubernetesサービスアカウントがあることを確認してください。これは、Azure portalで確認するか、[`az`コマンドラインインターフェイス](https://learn.microsoft.com/en-us/cli/azure/identity)を使用して確認できます。
1. マネージドIDにblobストレージコンテナの`Storage Blob Data Contributor`があることを確認します。
