---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Shared-Secrets Job 사용하기
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공:  GitLab Self-Managed

{{< /details >}}

`shared-secrets` 작업은 명시적으로 수동으로 지정하지 않는 한 설치 전체에서 사용되는 다양한 비밀정보를 프로비저닝하는 책임이 있습니다. 여기에는 다음이 포함됩니다:

1. 초기 루트 비밀번호
1. 모든 공개 서비스용 자체 서명된 TLS 인증서:  GitLab, MinIO 및 Registry
1. Registry 인증 인증서
1. MinIO, Registry, GitLab Shell 및 Gitaly 비밀정보
1. Redis 및 PostgreSQL 비밀번호
1. SSH 호스트 키
1. [암호화된 자격 증명](https://docs.gitlab.com/administration/encrypted_configuration/)용 GitLab Rails 비밀

## 설치 명령줄 옵션 {#installation-command-line-options}

아래 표에는 `helm install` 명령을 사용하여 `--set` 플래그로 제공할 수 있는 모든 가능한 구성이 포함되어 있습니다:

| 매개변수                    | 기본값                                                    | 설명 |
|------------------------------|------------------------------------------------------------|-------------|
| `enabled`                    | `true`                                                     | [아래 참조](#disable-functionality) |
| `env`                        | `production`                                               | Rails 환경 |
| `podLabels`                  |                                                            | 추가 Pod 레이블입니다. 선택기에 사용되지 않습니다. |
| `annotations`                |                                                            | 추가 Pod 주석입니다. |
| `image.pullPolicy`           | `Always`                                                   | **DEPRECATED**:  대신 `global.kubectl.image.pullPolicy`을 사용하세요. |
| `image.pullSecrets`          |                                                            | **DEPRECATED**:  대신 `global.kubectl.image.pullSecrets`을 사용하세요. |
| `image.repository`           | `registry.gitlab.com/gitlab-org/build/cng/kubectl`         | **DEPRECATED**:  대신 `global.kubectl.image.repository`을 사용하세요. |
| `image.tag`                  | `1f8690f03f7aeef27e727396927ab3cc96ac89e7`                 | **DEPRECATED**:  대신 `global.kubectl.image.tag`을 사용하세요. |
| `priorityClassName`          |                                                            | [우선순위 클래스](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)가 Pod에 할당됨 |
| `rbac.create`                | `true`                                                     | RBAC 역할 및 바인딩 생성 |
| `resources`                  |                                                            | 리소스 요청, 제한 |
| `securityContext.fsGroup`    | `65534`                                                    | 파일 시스템을 마운트할 사용자 ID |
| `securityContext.runAsUser`  | `65534`                                                    | 컨테이너를 실행할 사용자 ID |
| `selfsign.caSubject`         | `GitLab Helm Chart`                                        | 자체 서명된 CA 주체 |
| `selfsign.image.repository`  | `registry.gitlab.com/gitlab-org/build/cnf/cfssl-self-sign` | 자체 서명된 이미지 저장소 |
| `selfsign.image.pullSecrets` |                                                            | 이미지 저장소용 비밀정보 |
| `selfsign.image.tag`         |                                                            | 자체 서명된 이미지 태그 |
| `selfsign.keyAlgorithm`      | `rsa`                                                      | 자체 서명된 인증서 키 알고리즘 |
| `selfsign.keySize`           | `4096`                                                     | 자체 서명된 인증서 키 크기 |
| `serviceAccount.enabled`     | `true`                                                     | 작업에서 serviceAccountName 정의 |
| `serviceAccount.create`      | `true`                                                     | ServiceAccount 생성 |
| `serviceAccount.name`        | `RELEASE_NAME-shared-secrets`                              | 작업에서 지정할 서비스 계정 이름(그리고 `serviceAccount.create=true`인 경우 serviceAccount 자체에서) |
| `tolerations`                | `[]`                                                       | Pod 할당을 위한 허용 레이블 |

## 작업 구성 예제 {#job-configuration-examples}

### `tolerations` {#tolerations}

`tolerations`을 사용하면 오염된 작업자 노드에서 Pod을 예약할 수 있습니다

다음은 `tolerations`의 사용 예입니다:

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

## 기능 사용 안 함 {#disable-functionality}

일부 사용자는 이 작업에서 제공하는 기능을 명시적으로 사용 안 함으로 설정하기를 원할 수 있습니다. 이를 위해 `enabled` 플래그를 부울 값으로 제공했으며, 기본값은 `true`입니다.

작업을 사용 안 함으로 설정하려면 `--set shared-secrets.enabled=false`을 전달하거나 `-f` 플래그를 통해 다음을 `helm`에 전달하세요:

```yaml
shared-secrets:
  enabled: false
```

> [!note] 이 작업을 사용 안 함으로 설정하면 모든 비밀정보를 **must** 수동으로 생성하고 필요한 모든 비밀정보 콘텐츠를 제공해야 합니다. 자세한 내용은 [installation/secrets](../installation/secrets.md#manual-secret-creation-optional)를 참조하세요.
