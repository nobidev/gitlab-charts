---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Kubernetes 치트시트
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

이는 GitLab Support Team이 문제 해결 중에 때때로 사용하는 Kubernetes에 관한 유용한 정보의 목록입니다. GitLab은 Support Team의 수집된 지식을 누구나 활용할 수 있도록 이를 공개합니다.

> [!warning]
> 이 명령어들은 Kubernetes 구성요소를 **변경하거나 손상시킬 수** 있으므로 자신의 책임 하에 사용하세요.

[유료 계층](https://about.gitlab.com/pricing/) 을 사용 중이고 이 명령어들을 사용하는 방법을 확실하지 않다면 [Support에 문의](https://support.gitlab.com/hc/en-us/articles/11626483177756-GitLab-Support)하는 것이 가장 좋으며, 그들이 당신이 가진 문제를 도와줄 것입니다.

## 일반 Kubernetes 명령어 {#generic-kubernetes-commands}

- GCP 프로젝트에 권한을 부여하는 방법 (다른 GCP 계정에서 프로젝트를 가지고 있으면 특히 유용할 수 있음):

  ```shell
  gcloud auth login
  ```

- Kubernetes 대시보드에 접근하는 방법:

  ```shell
  # for minikube:
  minikube dashboard —url
  # for non-local installations if access via Kubectl is configured:
  kubectl proxy
  ```

- Kubernetes 노드에 SSH를 연결하고 컨테이너를 root로 입력하는 방법 <https://github.com/kubernetes/kubernetes/issues/30656>:
  - GCP의 경우, 노드 이름을 찾은 후 `gcloud compute ssh node-name`을 실행할 수 있습니다.
  - `docker ps`을 사용하여 컨테이너를 나열합니다.
  - `docker exec --user root -ti container-id bash`을 사용하여 컨테이너를 입력합니다.
- 로컬 머신에서 Pod로 파일을 복사하는 방법:

  ```shell
  kubectl cp file-name pod-name:./destination-path
  ```

- `CrashLoopBackoff` 상태의 Pod에 대해 할 작업:
  - Kubernetes 대시보드를 통해 로그를 확인합니다.
  - Kubectl을 통해 로그를 확인합니다:

    ```shell
    kubectl logs <webservice pod> -c dependencies
    ```

- 모든 Kubernetes 클러스터 이벤트를 실시간으로 추적하는 방법:

  ```shell
  kubectl get events -w --all-namespaces
  ```

- 이전에 종료된 Pod 인스턴스의 로그를 가져오는 방법:

  ```shell
  kubectl logs <pod-name> --previous
  ```

  로그는 컨테이너/Pod 자체에 보관되지 않습니다. 모든 것은 `stdout`으로 작성됩니다. 이는 Kubernetes의 원칙이며, 자세한 내용은 [Twelve-factor app](https://12factor.net/)을 읽어주십시오.

- 클러스터에 구성된 cron 작업을 가져오는 방법

  ```shell
  kubectl get cronjobs
  ```

  [cron 기반 백업](../backup-restore/backup.md#cron-based-backup)을 구성하면 새로운 스케줄을 여기서 확인할 수 있습니다. 스케줄에 대한 일부 세부 정보는 [CronJob으로 자동화된 작업 실행](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#creating-a-cron-job)에서 찾을 수 있습니다.

## GitLab 특화 Kubernetes 정보 {#gitlab-specific-kubernetes-information}

- 별도 Pod의 로그 추적 `webservice` Pod의 예:

  ```shell
  kubectl logs gitlab-webservice-54fbf6698b-hpckq -c webservice
  ```

- 레이블을 공유하는 모든 Pod를 추적 및 따라가기 (이 경우 `webservice`):

  ```shell
  # all containers in the webservice pods
  kubectl logs -f -l app=webservice --all-containers=true --max-log-requests=50

  # only the webservice containers in all webservice pods
  kubectl logs -f -l app=webservice -c webservice --max-log-requests=50
  ```

- 한 번에 모든 컨테이너의 로그를 스트리밍할 수 있으며, Linux 패키지 설치 시 `gitlab-ctl tail` 명령어와 유사합니다:

  ```shell
  kubectl logs -f -l release=gitlab --all-containers=true --max-log-requests=100
  ```

- `gitlab` 네임스페이스의 모든 이벤트를 확인합니다 (Helm 차트를 배포할 때 다른 네임스페이스를 지정했다면 네임스페이스 이름이 다를 수 있습니다):

  ```shell
  kubectl get events -w --namespace=gitlab
  ```

- 가장 유용한 GitLab 도구(콘솔, Rake 작업 등)의 대부분은 toolbox Pod에서 찾을 수 있습니다. Pod를 입력하여 내부에서 명령어를 실행하거나 외부에서 실행할 수 있습니다.

  ```shell
  # find the pod
  kubectl --namespace gitlab get pods -lapp=toolbox

  # open the Rails console
  kubectl --namespace gitlab exec -it -c toolbox <toolbox-pod-name> -- gitlab-rails console

  # run GitLab check. The output can be confusing and invalid because of the specific structure of GitLab installed via helm chart
  gitlab-rake gitlab:check

  # open console without entering pod
  kubectl exec -it <toolbox-pod-name> -- gitlab-rails console

  # check the status of DB migrations
  kubectl exec -it <toolbox-pod-name> -- gitlab-rake db:migrate:status
  ```

- **인프라 > Kubernetes 클러스터** 통합 문제 해결:
  - `kubectl get events -w --all-namespaces`의 출력을 확인합니다.
  - `gitlab-managed-apps` 네임스페이스 내 Pod의 로그를 확인합니다.
- [초기 관리자 암호](../installation/deployment.md#initial-login)를 가져오는 방법:

  ```shell
  # find the name of the secret containing the password
  kubectl get secrets | grep initial-root
  # decode it
  kubectl get secret <secret-name> -ojsonpath={.data.password} | base64 --decode ; echo
  ```

- GitLab PostgreSQL 데이터베이스에 연결하는 방법

  ```shell
  kubectl exec -it <toolbox-pod-name> -- gitlab-rails dbconsole --include-password --database main
  ```

- Helm 설치 상태에 대한 정보를 가져오는 방법:

  ```shell
  helm status <release name>
  ```

- Helm 차트를 사용하여 설치된 GitLab을 업데이트하는 방법:

  ```shell
  helm repo update

  # get current values and redirect them to yaml file (analogue of gitlab.rb values)
  helm get values <release name> > gitlab.yaml

  # run upgrade itself
  helm upgrade <release name> <chart path> -f gitlab.yaml
  ```

  [Helm 차트를 사용하여 GitLab 업데이트](../installation/upgrade.md)도 참조하십시오.

- GitLab 구성 변경을 적용하는 방법:

  - `gitlab.yaml` 파일을 수정합니다.
  - 변경 사항을 적용하려면 다음 명령어를 실행합니다:

    ```shell
    helm upgrade <release name> <chart path> -f gitlab.yaml
    ```

- 릴리스의 매니페스트를 가져오는 방법. 모든 Kubernetes 리소스 및 종속 차트에 대한 정보가 포함되어 있어서 유용할 수 있습니다:

  ```shell
  helm get manifest <release name>
  ```

## KubeSOS 보고서용 Fast-Stats {#fast-stats-for-kubesos-reports}

[KubeSOS](https://gitlab.com/gitlab-com/support/toolbox/kubesos)는 GitLab 클러스터 구성과 GitLab Cloud Native 차트 배포의 로그를 수집하는 도구입니다. 최소한의 메모리 사용으로 GitLab 로그에서 성능 통계를 빠르게 생성하고 비교하기 위해 [fast-stats](https://gitlab.com/gitlab-com/support/toolbox/fast-stats) 도구를 사용할 수 있습니다.

- `fast-stats`을 실행합니다:

  ```shell
  cut -d  ' ' -f2- <file-name> | grep ^{ | fast-stats
  ```

- 오류 나열:

  ```shell
  cut -d  ' ' -f2- <file-name> | grep ^{ | fast-stats errors
  ```

- `fast-stats` top을 실행합니다:

  ```shell
  cut -d  ' ' -f2- <file-name> | grep ^{ | fast-stats top
  ```

- 인쇄된 행의 수를 변경합니다. 기본적으로 10행이 인쇄됩니다.

  ```shell
  cut -d  ' ' -f2- <file-name> | grep ^{ | fast-stats -l <number of rows>
  ```

## macOS에서 minikube를 통한 최소 GitLab 구성 설치 {#installation-of-minimal-gitlab-configuration-via-minikube-on-macos}

이 섹션은 [minikube를 사용한 Kubernetes 개발](../development/minikube/_index.md) 및 [Helm](../installation/tools.md)을 기반으로 합니다. 자세한 내용은 해당 문서를 참조하십시오.

- Homebrew를 통해 Kubectl을 설치합니다:

  ```shell
  brew install kubernetes-cli
  ```

- Homebrew를 통해 minikube을 설치합니다:

  ```shell
  brew install minikube
  ```

- minikube을 시작하고 구성합니다. minikube을 시작할 수 없으면 `minikube delete && minikube start`을 실행하고 단계를 반복해보세요:

  ```shell
  minikube start --cpus 3 --memory 8192 # minimum amount for GitLab to work
  minikube addons enable ingress
  ```

- Homebrew를 통해 Helm을 설치하고 초기화합니다:

  ```shell
  brew install helm
  ```

- [minikube 최소값 YAML 파일](https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml)을 워크스테이션으로 복사합니다:

  ```shell
  curl --output values.yaml "https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml"
  ```

- `minikube ip`의 출력에서 IP 주소를 찾고 이 IP 주소로 YAML 파일을 업데이트합니다.

- GitLab Helm 차트를 설치합니다:

  ```shell
  helm repo add gitlab https://charts.gitlab.io
  helm install gitlab -f <path-to-yaml-file> gitlab/gitlab
  ```

  일부 GitLab 설정을 수정하고 싶다면 위에 언급된 구성을 기반으로 자신만의 YAML 파일을 생성할 수 있습니다.

- `helm status gitlab` 및 `minikube dashboard`를 통해 설치 진행 상황을 모니터링합니다. 설치는 워크스테이션의 리소스 양에 따라 최대 20-30분이 걸릴 수 있습니다.

- 모든 Pod가 `Running` 또는 `Completed` 상태를 표시할 때, [초기 로그인](../installation/deployment.md#initial-login)에 설명된 대로 GitLab 암호를 얻고 UI를 통해 GitLab에 로그인합니다. `https://gitlab.domain`를 통해 접근 가능하며, 여기서 `domain`는 YAML 파일에 제공된 값입니다.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

## `toolbox` Pod에서 Rails 코드 패칭 {#patching-the-rails-code-in-the-toolbox-pod}

> [!warning]
> 이 작업은 정기적으로 수행해야 할 것이 아닙니다. 자신의 책임 하에 사용하세요.

운영 중인 GitLab 서비스 Pod를 패칭하려면 수정된 소스 코드가 포함된 새로운 이미지를 구축해야 합니다. 이들은 직접 패칭될 수 _없습니다_. [`toolbox` / `task-runner` Pod](../charts/gitlab/toolbox/_index.md)는 다른 일반 서비스 작업을 방해하지 않으면서 Rails 기반 Pod로 작동하는 데 필요한 모든 것을 가지고 있습니다. 이를 사용하여 독립적인 작업을 실행하고 일부 작업을 수행하기 위해 소스 코드를 임시로 수정할 수 있습니다.

> [!note]
> `toolbox` Pod를 사용하여 변경한 내용은 Pod가 다시 시작되면 유지되지 않습니다. 이들은 컨테이너 작동 기간에만 존재합니다.

`toolbox` Pod에서 소스 코드를 패칭하려면:

1. 적용할 원하는 `.patch` 파일을 가져옵니다:

   - 병합 요청의 diff를 [패치 파일](https://docs.gitlab.com/user/project/merge_requests/changes/#as-a-patch-file)로 직접 다운로드하거나
   - 또는 `curl`을 사용하여 diff를 직접 가져옵니다. 아래의 `<mr_iid>`를 병합 요청의 IID로 바꾸거나 URL을 원시 스니펫으로 변경합니다:

     ```shell
     curl --output ~/<mr_iid>.patch "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/<mr_iid>.patch"
     ```

1. `toolbox` Pod의 로컬 파일을 패칭합니다:

   ```shell
   cd /srv/gitlab
   busybox patch -p1 -f < ~/<mr_iid>.patch
   ```
