---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트를 사용할 때 Azure Workload Identity
---

차트의 외부 객체 스토리지에 대한 기본 구성은 비밀 키를 사용합니다. [Azure Workload Identity](https://azure.github.io/azure-workload-identity/docs/)를 사용하면 단기 토큰을 이용하여 Kubernetes 클러스터에 객체 스토리지에 대한 액세스 권한을 부여할 수 있습니다. [Azure Kubernetes Service(AKS) 클러스터에서 워크로드 ID를 배포 및 구성하는 방법에 대한 Microsoft 설명서](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster)를 읽어보세요.

## 요구 사항 {#requirements}

워크로드 ID를 객체 스토리지와 함께 사용하려면 다음이 필요합니다:

1. OpenID Connect Issuer(OIDC) 발급자가 활성화된 AKS 클러스터.
1. `Storage Blob Data Contributor` 역할이 할당된 Azure 관리형 ID.
1. `azure.workload.identity/client-id: <CLIENT ID>` 주석이 있는 관리형 ID와 연결된 Kubernetes 서비스 계정.

워크로드 ID를 활성화하려면 각 Pod에 `azure.workload.identity/use: "true"` 레이블이 필요합니다. 이것은 Pod **label**이며 주석이 아닙니다.

## 차트 구성 {#chart-configuration}

### 레지스트리 {#registry}

{{< history >}}

- GitLab 17.9에서 베타 기능으로 [도입](https://gitlab.com/gitlab-org/container-registry/-/issues/1431)되었습니다.

{{< /history >}}

레지스트리에 대한 워크로드 ID 지원은 베타 단계입니다. Pod 레이블을 설정하여 워크로드 ID를 활성화할 수 있습니다:

```plaintext
--set registry.podLabels."azure\.workload\.identity/use"=true
```

[`registry-storage.yaml`](../../charts/registry/_index.md#storage) 비밀을 생성할 때 다음을 수행해야 합니다:

1. `azure_v2` 스토리지 설정을 사용하세요.
1. `credentialstype`을 `default_credentials`로 설정하세요.

예를 들어:

```yaml
azure_v2:
  accountname: accountname
  container: containername
  credentialstype: default_credentials
  realm: core.windows.net
```

`azure_v2` 스토리지 드라이버는 워크로드 ID를 지원하지만 `azure` 드라이버는 지원하지 않습니다. 현재 `azure` 드라이버를 사용 중이고 워크로드 ID를 사용하려면 `azure_v2` 드라이버로 마이그레이션하세요. 자세한 내용은 [`azure_v2` 설명서](https://gitlab.com/gitlab-org/container-registry/-/blob/3ebb5bffd3f6cfbf4479b1b8a4079d842a1c8025/docs/storage-drivers/azure_v2.md)를 참조하세요.

### LFS, 아티팩트, 업로드, 패키지 {#lfs-artifacts-uploads-packages}

LFS, 아티팩트, 업로드 및 패키지의 경우 `webservice`, `sidekiq` 및 `toolbox` 구성의 annotations 키를 통해 IAM 역할을 지정할 수 있습니다:

```shell
--set gitlab.sidekiq.podLabels."azure\.workload\.identity/use"="true"
--set gitlab.webservice.podLabels."azure\.workload\.identity/use"="true"
--set gitlab.toolbox.podLabels."azure\.workload\.identity/use"="true"
```

[`object-storage.yaml`](../../charts/globals.md#connection) 비밀의 경우 `azure_storage_access_key`을 생략하세요:

```yaml
provider: AzureRM
azure_storage_account_name: YOUR_AZURE_STORAGE_ACCOUNT_NAME
azure_storage_domain: blob.core.windows.net
```

### 백업 {#backups}

Toolbox 구성을 통해 Pod 레이블을 설정할 수 있습니다:

```shell
--set gitlab.toolbox.podLabels."azure\.workload\.identity/use"="true"
```

`gitlab.toolbox.backups.objectStorage.config.secret` 비밀에 저장된 [`azure-backup-conf.yaml`](../../backup-restore/_index.md)의 경우 `azure_storage_access_key`을 생략하세요:

```yaml
# azure-backup-conf.yaml
azure_storage_account_name: <storage account>
azure_storage_domain: blob.core.windows.net # optional
```

## 문제 해결 {#troubleshooting}

`toolbox` Pod에 로그인하여 Azure 워크로드 ID가 올바르게 설정되어 있고 GitLab이 Azure Blob 스토리지에 액세스하고 있는지 테스트할 수 있습니다(`<namespace>`를 GitLab이 있는 네임스페이스로 바꾸세요):

```shell
kubectl exec -ti $(kubectl get pod -n <namespace> -lapp=toolbox -o jsonpath='{.items[0].metadata.name}') -n <namespace> -- bash
```

먼저 필요한 환경 변수가 있는지 확인하세요:

- `AZURE_TENANT_ID`
- `AZURE_FEDERATED_TOKEN_FILE`
- `AZURE_CLIENT_ID`

예를 들어 다음과 같이 표시됩니다:

```shell
$ env | grep AZURE
AZURE_TENANT_ID=abcdefghi-c2c5-43d6-b426-1d8c9e8e7ad1
AZURE_FEDERATED_TOKEN_FILE=/var/run/secrets/azure/tokens/azure-identity-token
AZURE_AUTHORITY_HOST=https://login.microsoftonline.com/
AZURE_CLIENT_ID=123456789-abcd-12ab-89ca-cb379118f978
```

다음으로 `azcopy`을 사용하여 Blob 컨테이너의 파일을 나열하세요:

```shell
export AZCOPY_AUTO_LOGIN_TYPE=workload
azcopy --log-level debug list https://<YOUR STORAGE ACCOUNT NAME>.blob.core.windows.net/<YOUR AZURE BLOB CONTAINER NAME>
```

인증이 성공하면 Blob 컨테이너의 내용과 함께 다음 메시지가 표시됩니다:

```plaintext
INFO: Login with Workload Identity succeeded
INFO: Authenticating to source using Azure AD
```

401 또는 403 오류가 표시되면 관리형 ID 설정을 확인하세요. 다음은 몇 가지 일반적인 오류입니다:

1. Azure 스토리지 계정 및 Blob 컨테이너 이름의 철자를 확인하세요.
1. `kubectl describe pod <pod>`에서 Pod에 올바른 Kubernetes 서비스 계정과 `azure.workload.identity/use: "true"` Pod 레이블이 있는지 확인하세요.
1. 관리형 ID의 경우 페더레이션된 자격 증명 설정에 올바른 발급자 URL, 네임스페이스 및 연결된 Kubernetes 서비스 계정이 있는지 확인하세요. Azure 포털에서 또는 [`az` 명령줄 인터페이스](https://learn.microsoft.com/en-us/cli/azure/identity)를 사용하여 확인할 수 있습니다.
1. 관리형 ID에 Blob 스토리지 컨테이너에 대한 `Storage Blob Data Contributor`이 있는지 확인하세요.
