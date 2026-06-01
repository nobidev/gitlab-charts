---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Helm 서브차트
---

GitLab Helm 차트는 여러 서브차트로 구성되어 있으며, 이는 핵심 GitLab 구성 요소를 제공합니다:

- [Gitaly](gitaly/_index.md)
- [GitLab 내보내기](gitlab-exporter/_index.md)
- [GitLab Pages](gitlab-pages/_index.md)
- [GitLab Runner](gitlab-runner/_index.md)
- [GitLab Shell](gitlab-shell/_index.md)
- [GitLab 에이전트 서버(KAS)](kas/_index.md)
- [Mailroom](mailroom/_index.md)
- [마이그레이션](migrations/_index.md)
- [Praefect](praefect/_index.md)
- [Sidekiq](sidekiq/_index.md)
- [Spamcheck](spamcheck/_index.md)
- [Toolbox](toolbox/_index.md)
- [Webservice](webservice/_index.md)

각 서브차트의 매개변수는 `gitlab` 키 아래에 있어야 합니다. 예를 들어, GitLab Shell 매개변수는 다음과 같을 것입니다:

```yaml
gitlab:
  gitlab-shell:
    ...
```

이 차트를 선택적 종속성으로 사용하세요:

- [MinIO](../minio/_index.md)
- [NGINX](../nginx/_index.md)
- [HAProxy](../haproxy/_index.md)
- [PostgreSQL](https://artifacthub.io/packages/helm/bitnami/postgresql)
- [Redis](https://artifacthub.io/packages/helm/bitnami/redis)
- [Registry](../registry/_index.md)
- [Traefik](../traefik/_index.md)

이 차트를 선택적 추가 사항으로 사용하세요:

- [Prometheus](https://artifacthub.io/packages/helm/prometheus-community/prometheus)
- [_권한이 없는_](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#access-gitlab-with-a-custom-certificate) [GitLab Runner](https://docs.gitlab.com/runner/)(Kubernetes 실행자 사용)
- [Let's Encrypt](https://letsencrypt.org/) 에서 자동으로 프로비저닝된 SSL이며, [Jetstack](https://venafi.com/jetstack-consult/) 의 [cert-manager](https://cert-manager.io/docs/) 를 [certmanager-issuer](../certmanager-issuer/_index.md)와 함께 사용합니다.

## GitLab Helm 서브차트 선택적 매개변수 {#gitlab-helm-subchart-optional-parameters}

### affinity {#affinity}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3770) \- GitLab 17.3(Charts 8.3)에서 모든 GitLab Helm 서브차트에 대해, `webservice`과 `sidekiq` 제외

{{< /history >}}

`affinity`은 모든 GitLab Helm 서브차트에서 선택적 매개변수입니다. 이를 설정하면 [전역 `affinity`](../globals.md#affinity) 값보다 우선합니다. `affinity`에 대한 자세한 내용은 [관련 Kubernetes 설명서](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity)를 참조하세요.

> [!note]
> `webservice`과 `sidekiq` Helm 차트는 [전역 `affinity`](../globals.md#affinity) 값만 사용할 수 있습니다. [문제 25403](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25403)을 팔로우하여 로컬 `affinity`이 `webservice`과 `sidekiq`에 구현되는 시기를 알아보세요.

`affinity`을 사용하면 다음 중 하나 또는 둘 다를 설정할 수 있습니다:

- `podAntiAffinity` 규칙:
  - `topology key`에 해당하는 표현식과 일치하는 파드와 동일한 도메인에서 파드를 스케줄하지 않습니다.
  - `podAntiAffinity` 규칙의 두 모드를 설정합니다: 필수(`requiredDuringSchedulingIgnoredDuringExecution`) 및 선호(`preferredDuringSchedulingIgnoredDuringExecution`). `values.yaml`에서 변수 `antiAffinity`을 사용하여 선호 모드를 적용하도록 설정을 `soft`로 설정하거나 필수 모드를 적용하도록 `hard`로 설정합니다.
- `nodeAffinity` 규칙:
  - 특정 영역 또는 여러 영역에 속하는 노드에 파드를 스케줄합니다.
  - `nodeAffinity` 규칙의 두 모드를 설정합니다: 필수(`requiredDuringSchedulingIgnoredDuringExecution`) 및 선호(`preferredDuringSchedulingIgnoredDuringExecution`). `soft`로 설정하면 선호 모드가 적용됩니다. `hard`로 설정하면 필수 모드가 적용됩니다. 이 규칙은 `registry` 차트 및 `gitlab` 차트와 모든 서브차트에 대해서만 구현되며, `webservice`과 `sidekiq` 제외입니다.

`nodeAffinity`은 [`In` 연산자](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#operators)만 구현합니다.

다음 예제는 `affinity`을 설정하고, `nodeAffinity`과 `antiAffinity` 모두 `hard`로 설정합니다:

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
