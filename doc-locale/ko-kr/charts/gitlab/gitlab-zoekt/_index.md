---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Zoekt 차트
---

{{< details >}}

- 계층:  Premium, Ultimate
- 제공:  GitLab.com, GitLab 자체 관리
- 상태: 제한된 가용성

{{< /details >}}

{{< history >}}

- [GitLab 15.9에 도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) 되었으며 [베타](https://docs.gitlab.com/policy/development_stages_support/#beta) 버전이고 [플래그](https://docs.gitlab.com/administration/feature_flags/) `index_code_with_zoekt` 및 `search_code_with_zoekt`로 명명되었습니다. 기본적으로 비활성화됩니다.
- GitLab 16.6에서 [GitLab.com 및 GitLab Self-Managed에서 활성화](https://gitlab.com/gitlab-org/gitlab/-/issues/388519)됨.
- 전역 코드 검색이 GitLab 16.11에서 [도입](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077) 되었으며 [플래그](https://docs.gitlab.com/administration/feature_flags/) `zoekt_cross_namespace_search`로 명명되었습니다. 기본적으로 비활성화됩니다.
- 기능 플래그 `index_code_with_zoekt` 및 `search_code_with_zoekt`이 GitLab 17.1에서 [제거](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378)됨.
- 기능 플래그 `zoekt_rollout_worker`이 GitLab 17.9에서 [추가](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175666)됨. 기본적으로 비활성화됩니다.
- GitLab 18.6에서 베타에서 제한된 가용성으로 [변경](https://gitlab.com/groups/gitlab-org/-/epics/17918)됨.
- 기능 플래그 [`zoekt_cross_namespace_search`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213413) 및 [`zoekt_rollout_worker`](https://gitlab.com/gitlab-org/gitlab/-/issues/519660)이 GitLab 18.7에서 제거됨.

{{< /history >}}

> [!warning] 이 기능은 [제한된 가용성](https://docs.gitlab.com/policy/development_stages_support/#limited-availability) 상태입니다. 자세한 내용은 [에픽 9404](https://gitlab.com/groups/gitlab-org/-/epics/9404)를 참조하세요. [이슈 420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920)에서 피드백을 제공하세요.

## Linux 패키지 인스턴스가 있는 Zoekt 차트 {#zoekt-chart-with-a-linux-package-instance}

Zoekt 차트를 사용하여 Zoekt을 Linux 패키지 인스턴스에 연결하세요.

전제 조건:

- 현재 [크기 조정 권장 사항](https://docs.gitlab.com/integration/exact_code_search/zoekt/#sizing-recommendations)을 기반으로 하는 전용 Zoekt 클러스터.

Linux 패키지 인스턴스에서 Zoekt 차트를 사용하려면:

1. `zoekt`이라고 불리는 네임스페이스 생성:

   ```shell
   kubectl create namespace zoekt
   ```

1. [`gitlab-zoekt` 차트](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/)를 로컬로 복제하고 해당 디렉토리로 변경:

   ```shell
   git clone https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt.git
   cd gitlab-zoekt
   ```

1. [로드 밸런서 활성화](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/-/blob/v2.7.0/doc/load_balancer.md). Zoekt 차트가 헤드리스 서비스이므로 로드 밸런서가 필요합니다.

1. `values.yaml`에서:

   1. `gitlab_shell` 비밀을 `/etc/gitlab/gitlab-secrets.json` 파일에서 `kubectl` 비밀을 생성하는 데 사용:

      ```shell
      kubectl create secret generic gitlab-zoekt-secret --from-literal=secret-key="<gitlab-shell-secret>" -n zoekt
      ```

   1. 비밀 추가:

      ```yaml
      internalApi:
       secretName: 'gitlab-zoekt-secret'
       secretKey: 'secret-key'
      ```

   1. GitLab 인스턴스 URL 및 `:8080`의 로드 밸런서 IP 포트를 가진 서비스 URL 추가:

      ```yaml
       internalApi:
         gitlabUrl: 'https://<gitlab_url>' # Internal URL to connect to GitLab
         serviceUrl: 'http://<loadbalancer_internal_ip>:8080' # URL to reach Zoekt service - LB internal URL
      ```

1. GitLab에서 [Gitaly 수신 인터페이스 변경](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#change-the-gitaly-listening-interface):

   ```ruby
   gitaly['configuration'] = {
     listen_addr: '0.0.0.0:8075',
     storage: [
       {
         name: 'default',
         path: '/var/opt/gitlab/git-data/repositories',
       },
     ]
   }
   gitlab_rails['repositories_storages'] = {
     'default'  => { 'gitaly_address' => 'tcp://<gitlab_url>:8075' },
   }
   ```

1. `helm`을 사용하여 Zoekt 설치:

   ```shell
   helm install gitlab-zoekt . -f values.yaml --version <latest_version> --namespace zoekt
   ```

1. Pod이 생성되었는지 확인합니다. 게이트웨이 및 `gitlab-zoekt-0` Pod이 있어야 합니다:

   ```shell
   kubectl get pods
   NAME                                  READY   STATUS    RESTARTS   AGE
   gitlab-zoekt-0                        3/3     Running   0          13d
   gitlab-zoekt-gateway-b78dbc78-hzw28   1/1     Running   0          13d
   ```

   `values.yaml`에 추가 변경을 하면 GitLab Helm 차트를 설치하거나 업그레이드합니다.

1. [정확한 코드 검색 활성화](https://docs.gitlab.com/integration/zoekt/#enable-exact-code-search).
1. 최상위 그룹을 색인하려면 다음 중 하나를 수행하세요:
   - [모든 루트 네임스페이스 자동으로 색인](https://docs.gitlab.com/integration/zoekt/#index-root-namespaces-automatically).
   - 특정 최상위 그룹을 수동으로 색인:

     ```ruby
     node = ::Search::Zoekt::Node.online.last
     namespace = Namespace.find_by_full_path('<top-level-group-to-index>')
     Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
     ```

## GitLab Helm 차트가 있는 Zoekt 차트 {#zoekt-chart-with-the-gitlab-helm-chart}

Zoekt 차트는 [정확한 코드 검색](https://docs.gitlab.com/user/search/exact_code_search/)을 지원합니다. `gitlab-zoekt.install`을 `true`로 설정하여 차트를 설치할 수 있습니다. 자세한 내용은 [`gitlab-zoekt`](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt)를 참조하세요.

### Zoekt 차트 활성화 {#enable-the-zoekt-chart}

Zoekt 차트를 활성화하려면 다음 값을 설정하세요:

```shell
--set gitlab-zoekt.install=true \
--set gitlab-zoekt.replicas=2 \         # Number of Zoekt pods. If you want to use only one pod, you can skip this setting.
--set gitlab-zoekt.indexStorage=128Gi   # Disk size for the Zoekt node. Zoekt requires up to three times the repository's default branch's storage size, depending on the number of large and binary files.
```

### CPU 및 메모리 사용량 설정 {#set-cpu-and-memory-usage}

GitLab.com [기본 설정](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/gprd.yaml.gotmpl#L6-45)을 수정하여 Zoekt 차트에 대한 요청 및 제한을 정의할 수 있습니다.

## GitLab에서 Zoekt 구성 {#configure-zoekt-in-gitlab}

{{< history >}}

- 분할이 GitLab 16.6에서 노드로 [이름 변경](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134717)됨.

{{< /history >}}

GitLab에서 최상위 그룹에 대해 Zoekt을 구성하려면:

1. 도구 상자 Pod의 Rails 콘솔에 연결:

   ```shell
   kubectl exec <toolbox pod name> -it -c toolbox -- gitlab-rails console -e production
   ```

1. [정확한 코드 검색 활성화](https://docs.gitlab.com/integration/zoekt/#enable-exact-code-search).
1. 최상위 그룹을 색인하려면 다음 중 하나를 수행하세요:
   - [모든 루트 네임스페이스 자동으로 색인](https://docs.gitlab.com/integration/zoekt/#index-root-namespaces-automatically).
   - 특정 최상위 그룹을 수동으로 색인:

     {{< tabs >}}

     {{< tab title="GitLab 17.7 이상" >}}

     ```shell
     node = ::Search::Zoekt::Node.online.last
     namespace = Namespace.find_by_full_path('<top-level-group-to-index>')
     Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
     ```

     {{< /tab >}}

     {{< tab title="GitLab 17.6 이전" >}}

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

Zoekt는 프로젝트가 업데이트되거나 생성된 후 해당 그룹의 프로젝트를 색인할 수 있습니다. 초기 색인을 위해 Zoekt가 네임스페이스 색인을 시작할 때까지 최소 몇 분 정도 기다리세요.
