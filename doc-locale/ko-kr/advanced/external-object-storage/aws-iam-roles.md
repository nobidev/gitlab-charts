---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트를 사용할 때 AWS용 IAM 역할
---

차트의 외부 객체 저장소의 기본 구성은 액세스 키와 비밀 키를 사용합니다. [`kube2iam`](https://github.com/jtblin/kube2iam) , [`kiam`](https://github.com/uswitch/kiam) 또는 [IRSA](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/)와 함께 IAM 역할을 사용하는 것도 가능합니다.

## IAM 역할 {#iam-role}

IAM 역할은 S3 버킷에 대한 읽기, 쓰기 및 목록 권한이 필요합니다. 버킷당 하나의 역할을 가지도록 선택하거나 이를 결합할 수 있습니다.

## 차트 구성 {#chart-configuration}

IAM 역할은 아래에 지정된 대로 주석을 추가하고 비밀을 변경하여 지정할 수 있습니다:

### 레지스트리 {#registry}

IAM 역할은 주석 키를 통해 지정할 수 있습니다:

```plaintext
--set registry.annotations."iam\.amazonaws\.com/role"=<role name>
```

[`registry-storage.yaml`](../../charts/registry/_index.md#storage) 비밀을 생성할 때 액세스 키와 비밀 키를 생략합니다:

```yaml
s3:
  bucket: gitlab-registry
  v4auth: true
  region: us-east-1
```

*참고*:  키 쌍을 제공하면 IAM 역할은 무시됩니다. 자세한 내용은 [AWS 설명서](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html#credentials-default)를 참조하세요.

### LFS, 아티팩트, 업로드, 패키지 {#lfs-artifacts-uploads-packages}

LFS, 아티팩트, 업로드 및 패키지의 경우 IAM 역할은 `webservice` 및 `sidekiq` 구성의 주석 키를 통해 지정할 수 있습니다:

```shell
--set gitlab.sidekiq.annotations."iam\.amazonaws\.com/role"=<role name>
--set gitlab.webservice.annotations."iam\.amazonaws\.com/role"=<role name>
```

[`object-storage.yaml`](../../charts/globals.md#connection) 비밀의 경우 액세스 키와 비밀 키를 생략합니다. GitLab Rails 코드베이스가 S3 저장소용 Fog를 사용하기 때문에 [`use_iam_profile`](https://docs.gitlab.com/administration/cicd/secure_files/#s3-compatible-connection-settings) 키를 추가하여 Fog가 역할을 사용하도록 해야 합니다:

```yaml
provider: AWS
use_iam_profile: true
region: us-east-1
```

> [!note] 이 구성에 `endpoint`를 포함하지 마십시오. IRSA는 [전문화된 엔드포인트를 사용하는 STS 토큰](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html)을 활용합니다. `endpoint`가 제공되면 AWS 클라이언트는 [`AssumeRoleWithWebIdentity` 메시지를 이 엔드포인트로 전송하려고 시도하고 실패합니다](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3148#note_889357676).

### 백업 {#backups}

Toolbox 구성을 사용하면 백업을 S3로 업로드하도록 주석을 설정할 수 있습니다:

```shell
--set gitlab.toolbox.annotations."iam\.amazonaws\.com/role"=<role name>
```

[`s3cmd.config`](_index.md#backups-storage-example) 비밀은 액세스 키와 비밀 키 없이 생성되어야 합니다:

```ini
[default]
bucket_location = us-east-1
```

### 서비스 계정용 IAM 역할 사용 {#using-iam-roles-for-service-accounts}

GitLab이 AWS EKS 클러스터(버전 1.14 이상)에서 실행 중인 경우 액세스 토큰을 생성하거나 저장할 필요 없이 S3 객체 저장소에 인증하기 위해 AWS IAM 역할을 사용할 수 있습니다. EKS 클러스터에서 IAM 역할 사용에 관한 자세한 정보는 AWS의 [서비스 계정에 대한 세분화된 IAM 역할 소개](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/) 설명서에서 찾을 수 있습니다.

역할에 적합한 IRSA 주석은 다음 두 가지 방법 중 하나로 이 Helm 차트 전체의 ServiceAccounts에 적용할 수 있습니다:

1. 위의 AWS 설명서에 설명된 대로 사전에 생성된 ServiceAccounts입니다. 이는 ServiceAccount의 적절한 주석과 연결된 OIDC 공급자를 보장합니다.
1. 정의된 주석이 있는 차트 생성 ServiceAccounts입니다. ServiceAccounts의 주석 구성을 전역적으로 그리고 차트별 기준으로 모두 허용합니다.

EKS 클러스터에서 ServiceAccounts용 IAM 역할을 사용하려면 특정 주석이 `eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME>`이어야 합니다.

AWS EKS 클러스터에서 실행 중인 GitLab의 ServiceAccounts용 IAM 역할을 활성화하려면 [서비스 계정용 IAM 역할](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)의 지침을 따르세요.

#### 사전 생성된 서비스 계정 사용 {#using-pre-created-service-accounts}

GitLab 차트가 배포될 때 다음 옵션을 설정합니다. ServiceAccount가 활성화되었지만 생성되지 않았음을 유의하는 것이 중요합니다.

```yaml
global:
  serviceAccount:
    enabled: true
    create: false
    name: <SERVICE ACCT NAME>
```

세분화된 ServiceAccounts 제어도 사용 가능합니다:

```yaml
registry:
  serviceAccount:
    create: false
    name: gitlab-registry
gitlab:
  migrations:
    serviceAccount:
      create: false
      name: gitlab-migrations
  webservice:
    serviceAccount:
      create: false
      name: gitlab-webservice
  sidekiq:
    serviceAccount:
      create: false
      name: gitlab-sidekiq
  toolbox:
    serviceAccount:
      create: false
      name: gitlab-toolbox
```

IAM 역할의 신뢰 정책이 [이러한 Kubernetes 서비스 계정을 신뢰하도록](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html) 구성되었는지 확인합니다.

#### 차트 소유 서비스 계정 사용 {#using-chart-owned-service-accounts}

`eks.amazonaws.com/role-arn` 주석은 `global.serviceAccount.annotations`를 구성하여 GitLab 소유 차트에서 생성한 모든 ServiceAccounts에 적용할 수 있습니다.

```yaml
global:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/name
```

각 차트의 일치하는 정의를 추가하여 ServiceAccount별로 주석을 추가할 수도 있습니다. 이들은 동일한 역할이거나 개별 역할일 수 있습니다.

```yaml
registry:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab-registry
gitlab:
  migrations:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab
  webservice:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab
  sidekiq:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab
  toolbox:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab-toolbox
```

## 문제 해결 {#troubleshooting}

IAM 역할이 올바르게 설정되었는지, GitLab이 `toolbox` pod에 로그인하고 `awscli`를 사용하여 IAM 역할을 사용하여 S3에 액세스하고 있는지 확인할 수 있습니다(`<namespace>`를 GitLab이 설치된 네임스페이스로 바꿈):

```shell
kubectl exec -ti $(kubectl get pod -n <namespace> -lapp=toolbox -o jsonpath='{.items[0].metadata.name}') -n <namespace> -- bash
```

`awscli` 패키지가 설치되었으면 AWS API와 통신할 수 있는지 확인합니다:

```shell
aws sts get-caller-identity
```

AWS API에 대한 연결이 성공한 경우 임시 사용자 ID, 계정 번호 및 IAM ARN(S3에 액세스하는 데 사용되는 역할의 IAM ARN이 아님)을 보여주는 정상 응답이 반환됩니다. 연결이 실패하면 `toolbox` pod가 AWS API와 통신할 수 없는 이유를 파악하기 위해 추가 문제 해결이 필요합니다.

AWS API에 대한 연결이 성공하면 다음 명령은 생성된 IAM 역할을 가정하고 S3에 액세스하기 위해 STS 토큰을 검색할 수 있는지 확인합니다. `AWS_ROLE_ARN` 및 `AWS_WEB_IDENTITY_TOKEN_FILE` 변수는 IAM 역할 주석이 pod에 추가되었을 때 환경에서 정의되며 정의할 필요가 없습니다:

```shell
aws sts assume-role-with-web-identity --role-arn $AWS_ROLE_ARN  --role-session-name gitlab --web-identity-token file://$AWS_WEB_IDENTITY_TOKEN_FILE
```

IAM 역할을 가정할 수 없으면 다음과 유사한 오류 메시지가 표시됩니다:

```plaintext
An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

그렇지 않으면 STS 자격 증명 및 IAM 역할 정보가 표시됩니다.

## `WebIdentityErr: failed to retrieve credentials` {#webidentityerr-failed-to-retrieve-credentials}

로그에서 이 오류가 표시되면 `endpoint`이 [`object-storage.yaml`](../../charts/globals.md#connection) 비밀에 구성되었음을 시사합니다. 이 설정을 제거하고 `webservice` 및 `sidekiq` pod를 다시 시작합니다.
