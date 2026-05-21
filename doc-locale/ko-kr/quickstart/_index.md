---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GKE 또는 EKS에서 GitLab 차트 테스트
---

이 가이드는 Google Kubernetes Engine (GKE) 또는 Amazon Elastic Kubernetes Service (EKS)에서 기본값으로 GitLab 차트를 설치하는 방법에 대한 간결하면서도 완전한 설명서입니다.

> [!note]
> 기본 차트에는 평가 목적으로만 사용되는 번들 MinIO 서비스가 포함되어 있습니다. PostgreSQL과 Redis는 외부에서 구성해야 합니다. 프로덕션 환경에서 GitLab을 배포하려면 [설치 가이드](../installation/_index.md)를 따르세요.

## 사전 요구사항 {#prerequisites}

이 가이드를 완료하려면 다음이 필요합니다:

- DNS 레코드를 추가할 수 있는 소유한 도메인입니다.
- Kubernetes 클러스터입니다.
- `kubectl`의 작동하는 설치입니다.
- Helm v3의 작동하는 설치입니다.

### 사용 가능한 도메인 {#available-domain}

DNS 레코드를 추가할 수 있는 인터넷에 액세스 가능한 도메인에 대한 액세스 권한이 있어야 합니다. `poc.domain.com`과 같은 서브도메인일 수 있지만 Let's Encrypt 서버가 주소를 확인할 수 있어야 인증서를 발급할 수 있습니다.

### Kubernetes 클러스터 생성 {#create-a-kubernetes-cluster}

최소 8개의 가상 CPU와 30GB의 RAM을 보유한 클러스터를 권장합니다.

클라우드 제공자의 지침에 따라 Kubernetes 클러스터를 만들거나 GitLab에서 제공하는 스크립트를 사용하여 [클러스터 생성을 자동화](../installation/cloud/_index.md)할 수 있습니다.

> [!warning]
> Kubernetes 노드는 x86-64 및 ARM64 아키텍처를 지원합니다. FIPS 검증 이미지는 x86-64 전용으로만 사용 가능합니다. ARM64 FIPS 상태는 [이슈 2285](https://gitlab.com/gitlab-org/build/CNG/-/issues/2285)를 참조하세요.

### kubectl 설치 {#install-kubectl}

kubectl을 설치하려면 [Kubernetes 설치 설명서](https://kubernetes.io/docs/tasks/tools/)를 참조하세요. 설명서는 대부분의 운영 체제와 이전 단계에서 설치했을 수 있는 Google Cloud SDK를 다룹니다.

클러스터를 만든 후 명령줄에서 클러스터와 상호 작용하기 전에 [`kubectl`을 구성](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#generate_kubeconfig_entry)해야 합니다.

### Helm 설치 {#install-helm}

이 가이드에서는 Helm v3의 최신 릴리스(v3.9.4 이상)를 사용합니다. Helm을 설치하려면 [Helm 설치 설명서](https://helm.sh/docs/intro/install/)를 참조하세요.

## GitLab Helm 저장소 추가 {#add-the-gitlab-helm-repository}

GitLab Helm 저장소를 `helm`의 구성에 추가합니다:

```shell
helm repo add gitlab https://charts.gitlab.io/
```

## GitLab 설치 {#install-gitlab}

이 차트의 기능이 얼마나 멋있는지 알아보세요. 한 줄의 명령입니다. 짠! 모든 GitLab이 설치되고 SSL로 구성되었습니다.

차트를 구성하려면 다음이 필요합니다:

- GitLab이 작동할 도메인 또는 서브도메인입니다.
- Let's Encrypt가 인증서를 발급할 수 있도록 하는 이메일 주소입니다.

차트를 설치하려면 두 개의 `--set` 인수로 설치 명령을 실행합니다:

```shell
helm install gitlab gitlab/gitlab \
  --set global.hosts.domain=DOMAIN \
  --set certmanager-issuer.email=me@example.com
```

이 단계는 모든 리소스를 할당하고, 서비스를 시작하고, 액세스를 가능하게 하는 데 몇 분이 걸릴 수 있습니다.

완료되면 설치된 NGINX Ingress에 동적으로 할당된 IP 주소를 수집할 수 있습니다.

## IP 주소 검색 {#retrieve-the-ip-address}

`kubectl`을 사용하여 GKE에서 동적으로 할당한 주소를 가져올 수 있습니다. 방금 설치하고 구성한 NGINX Ingress는 GitLab 차트의 일부입니다:

```shell
kubectl get ingress -lrelease=gitlab
```

출력은 다음과 같이 표시됩니다:

```plaintext
NAME               HOSTS                 ADDRESS         PORTS     AGE
gitlab-minio       minio.domain.tld      35.239.27.235   80, 443   118m
gitlab-registry    registry.domain.tld   35.239.27.235   80, 443   118m
gitlab-webservice  gitlab.domain.tld     35.239.27.235   80, 443   118m
```

동일한 IP 주소를 가진 세 개의 항목이 있음을 알 수 있습니다. 이 IP 주소를 사용할 도메인에 대한 DNS에 추가합니다. `A` 유형의 여러 레코드를 추가할 수 있지만 간단하게 하기 위해 단일 "와일드카드" 레코드를 권장합니다:

- Google Cloud DNS에서 이름이 `*`인 `A` 레코드를 만듭니다. TTL을 `1` 분으로 설정하는 것을 권장합니다 (`5` 분 대신).
- AWS EKS에서 주소는 IP 주소가 아닌 URL입니다. [Route 53 별칭 레코드 생성](https://repost.aws/knowledge-center/route-53-create-alias-records) `*.domain.tld` (이 URL을 가리킴).

## GitLab에 로그인 {#sign-in-to-gitlab}

`gitlab.domain.tld`에서 GitLab에 액세스할 수 있습니다. 예를 들어 `global.hosts.domain=my.domain.tld`을 설정한 경우 `gitlab.my.domain.tld`를 방문할 수 있습니다.

로그인하려면 `root` 사용자의 암호를 수집해야 합니다. 이는 설치 시 자동으로 생성되고 Kubernetes Secret에 저장됩니다. 비밀에서 해당 암호를 가져와서 디코딩해 봅시다:

```shell
kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

이제 사용자 이름 `root`과 검색한 암호로 GitLab에 로그인할 수 있습니다. 로그인한 후 사용자 환경 설정을 통해 이 암호를 변경할 수 있습니다. 우리는 사용자를 대신하여 첫 번째 로그인을 보호할 수 있도록 생성했습니다.

## 문제 해결 {#troubleshooting}

이 가이드 중에 문제가 발생하면 다음은 작동 중인지 확인해야 하는 몇 가지 가능성 있는 항목입니다:

1. `gitlab.my.domain.tld`이 검색한 Ingress의 IP 주소로 해석됩니다.
1. 인증서 경고가 표시되면 Let's Encrypt에 문제가 있습니다. 일반적으로 DNS와 관련되어 있거나 재시도 요구 사항이 있습니다.

추가 문제 해결 팁은 [문제 해결](../troubleshooting/_index.md) 가이드를 참조하세요.

### Helm install이 `roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden`를 반환합니다. {#helm-install-returns-rolesrbacauthorizationk8sio-gitlab-shared-secrets-is-forbidden}

다음을 실행한 후:

```shell
helm install gitlab gitlab/gitlab  \
  --set global.hosts.domain=DOMAIN \
  --set certmanager-issuer.email=user@example.com
```

다음과 유사한 오류가 표시될 수 있습니다:

```shell
Error: failed pre-install: warning: Hook pre-install templates/shared-secrets-rbac-config.yaml failed: roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden: user "some-user@some-domain.com" (groups=["system:authenticated"]) is attempting to grant RBAC permissions not currently held:
{APIGroups:[""], Resources:["secrets"], Verbs:["get" "list" "create" "patch"]}
```

이는 클러스터에 연결하는 데 사용 중인 `kubectl` 컨텍스트가 [RBAC](../installation/rbac.md) 리소스를 생성하는 데 필요한 권한이 없음을 의미합니다.
