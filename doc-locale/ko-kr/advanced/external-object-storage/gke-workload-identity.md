---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트를 사용한 GKE의 워크로드 아이덴티티 페더레이션
---

{{< history >}}

- [GitLab 17.0에서 도입됨](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3434).

{{< /history >}}

차트의 외부 객체 스토리지에 대한 기본 구성은 비밀 키를 사용합니다. [GKE의 워크로드 아이덴티티 페더레이션](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity)을 사용하면 단기 토큰을 사용하여 Kubernetes 클러스터에 객체 스토리지에 대한 액세스 권한을 부여할 수 있습니다. 기존 GKE 클러스터가 있는 경우 [노드 풀을 업데이트하여 워크로드 아이덴티티 페더레이션을 사용하는 방법에 대한 Google 설명서](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#option_2_node_pool_modification)를 읽으세요.

워크로드 아이덴티티를 사용하려면 [`object-storage.yaml`](../../charts/globals.md#connection) 비밀에서 `google_json_key_string`을(를) 생략하세요:

```yaml
provider: Google
google_project: your-project-id
google_client_email: null  # Will use workload identity
google_json_key_string: null  # Will use workload identity
```

## 문제 해결 {#troubleshooting}

[Kubernetes ServiceAccount가 IAM 서비스 계정에 연결](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubernetes-sa-to-iam)되어 있는지 `iam.gke.io/gcp-service-account` 주석을 통해 확인하세요.

도구 상자 포드 내의 메타데이터 엔드포인트를 쿼리하여 워크로드 아이덴티티가 올바르게 구성되어 있는지 확인할 수 있습니다. 클러스터와 연결된 서비스 계정이 반환되어야 합니다:

```shell
$ curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email
example@your-example-project.iam.gserviceaccount.com
```

이 계정은 다음 범위에 액세스할 수 있어야 합니다:

```shell
$ curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/scopes
https://www.googleapis.com/auth/cloud-platform
https://www.googleapis.com/auth/userinfo.email
```
