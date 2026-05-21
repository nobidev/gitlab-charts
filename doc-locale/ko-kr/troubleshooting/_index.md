---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트 문제 해결
---

## 업그레이드 실패: "$name"에 배포된 릴리스가 없음 {#upgrade-failed-name-has-no-deployed-releases}

초기 설치가 실패한 경우 두 번째 설치/업그레이드 시 이 오류가 발생합니다.

초기 설치가 완전히 실패하고 GitLab이 작동하지 않은 경우 다시 설치하기 전에 먼저 실패한 설치를 제거해야 합니다.

```shell
helm uninstall <release-name>
```

초기 설치 명령이 시간 초과되었지만 GitLab이 여전히 정상 실행된 경우, `--force` 플래그를 `helm upgrade` 명령에 추가하여 오류를 무시하고 릴리스를 업데이트할 수 있습니다.

반대로 GitLab 차트의 이전 배포에 성공한 후에 이 오류를 받은 경우 버그를 발견한 것입니다. 저희 [문제 추적기](https://gitlab.com/gitlab-org/charts/gitlab/-/issues) 에서 문제를 열어주십시오. 또한 이 문제에서 CI 서버를 복구한 [문제 #630](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/630)을 확인해주십시오.

## 오류: 이 명령은 2개의 인수가 필요합니다: 릴리스 이름, 차트 경로 {#error-this-command-needs-2-arguments-release-name-chart-path}

`helm upgrade`을 실행할 때 매개변수에 공백이 있으면 이와 같은 오류가 발생할 수 있습니다. 다음 예에서 `Test Username`가 원인입니다:

```shell
helm upgrade gitlab gitlab/gitlab --timeout 600s --set global.email.display_name=Test Username ...
```

이를 해결하려면 매개변수를 단일 따옴표로 전달하십시오:

```shell
helm upgrade gitlab gitlab/gitlab --timeout 600s --set global.email.display_name='Test Username' ...
```

## 애플리케이션 컨테이너가 계속 초기화 중 {#application-containers-constantly-initializing}

Sidekiq, Webservice 또는 다른 Rails 기반 컨테이너가 계속 초기화 중 상태에 있으면 `dependencies` 컨테이너가 통과할 때까지 기다리고 있을 가능성이 높습니다.

특정 Pod의 `dependencies` 컨테이너 로그를 확인하면 다음이 반복되는 것을 볼 수 있습니다:

```plaintext
Checking database connection and schema version
WARNING: This version of GitLab depends on gitlab-shell 8.7.1, ...
Database Schema
Current version: 0
Codebase version: 20190301182457
```

이것은 `migrations` Job이 아직 완료되지 않았음을 나타냅니다. 이 Job의 목적은 데이터베이스가 시드되었는지 확인하고 모든 관련 마이그레이션이 있는지 확인하는 것입니다. 애플리케이션 컨테이너는 데이터베이스가 예상 데이터베이스 버전 이상이 될 때까지 기다리려고 합니다. 이것은 애플리케이션이 코드베이스의 예상과 스키마가 일치하지 않아 오작동하지 않도록 하기 위함입니다.

1. `migrations` Job을 찾습니다. `kubectl get job -lapp=migrations`
1. Job에서 실행 중인 Pod을 찾습니다. `kubectl get pod -lbatch.kubernetes.io/job-name=<job-name>`
1. 출력을 검토하여 `STATUS` 열을 확인합니다.

`STATUS`이 `Running`이면 계속합니다. `STATUS`이 `Completed`이면 다음 검사가 통과한 후 곧 애플리케이션 컨테이너가 시작됩니다.

이 Pod의 로그를 검토합니다. `kubectl logs <pod-name>`

이 작업 실행 중 발생한 모든 오류를 해결해야 합니다. 이들은 해결될 때까지 애플리케이션 사용을 차단합니다. 가능한 문제:

- 구성된 PostgreSQL 데이터베이스에 접근할 수 없거나 인증 실패
- 구성된 Redis 서비스에 접근할 수 없거나 인증 실패
- Gitaly 인스턴스에 접근 실패

## 구성 변경 적용 {#applying-configuration-changes}

다음 명령은 `gitlab.yaml`에 대한 변경사항을 적용하는 데 필요한 작업을 수행합니다:

```shell
helm upgrade <release name> <chart path> -f gitlab.yaml
```

## 포함된 GitLab Runner가 등록되지 않음 {#included-gitlab-runner-failing-to-register}

GitLab에서 실행자 등록 토큰이 변경된 경우 이 오류가 발생할 수 있습니다. (백업을 복구한 후에 자주 발생합니다)

1. GitLab 설치의 `admin/runners` 웹페이지에 있는 새로운 공유 실행자 토큰을 찾습니다.
1. Kubernetes에 저장된 기존 실행자 토큰 Secret의 이름을 찾습니다

   ```shell
   kubectl get secrets | grep gitlab-runner-secret
   ```

1. 기존 Secret을 삭제합니다

   ```shell
   kubectl delete secret <runner-secret-name>
   ```

1. 2개의 키로 새 Secret을 만듭니다. (`runner-registration-token`에 공유 토큰 포함, `runner-token`는 빈 값)

   ```shell
   kubectl create secret generic <runner-secret-name> --from-literal=runner-registration-token=<new-shared-runner-token> --from-literal=runner-token=""
   ```

## 너무 많은 리디렉션 {#too-many-redirects}

NGINX Ingress 앞에 TLS 종료가 있고 tls-secrets이 구성에 지정된 경우 이 오류가 발생할 수 있습니다.

1. 값을 설정하도록 업데이트합니다: `global.ingress.annotations."nginx.ingress.kubernetes.io/ssl-redirect": "false"`

   값 파일을 통해:

   ```yaml
   # values.yaml
   global:
     ingress:
       annotations:
         "nginx.ingress.kubernetes.io/ssl-redirect": "false"
   ```

   Helm CLI를 통해:

   ```shell
   helm ... --set-string global.ingress.annotations."nginx.ingress.kubernetes.io/ssl-redirect"=false
   ```

1. 변경사항을 적용합니다.

> [!note]
> SSL 종료를 위해 외부 서비스를 사용할 때 해당 서비스는 필요에 따라 https로 리디렉션할 책임이 있습니다.

## 업그레이드가 불변 필드 오류로 실패함 {#upgrades-fail-with-immutable-field-error}

### spec.clusterIP {#specclusterip}

이 차트의 3.0.0 릴리스 이전에는 `spec.clusterIP` 속성이 실제 값(`""`)이 없음에도 불구하고 [여러 Services로 채워져 있었습니다](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1710). 이것은 버그였으며 Helm 3의 속성 3-방향 병합에 문제를 야기합니다.

차트가 Helm 3으로 배포되면 _업그레이드 경로가 없었을 것입니다_. 단, 다양한 Services에서 `clusterIP` 속성을 수집하여 Helm에 제공된 값으로 채우거나 영향을 받은 서비스를 Kubernetes에서 제거해야 합니다.

[이 차트의 3.0.0 릴리스가 이 오류를 수정했습니다](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1710). 하지만 수동 수정이 필요합니다.

이는 영향을 받은 모든 서비스를 제거하여 해결할 수 있습니다.

1. 영향을 받은 모든 서비스를 제거합니다:

   ```shell
   kubectl delete services -lrelease=RELEASE_NAME
   ```

1. Helm을 통해 업그레이드를 수행합니다.
1. 향후 업그레이드는 이 오류를 만나지 않습니다.

> [!note]
> 이는 이 차트에서 NGINX Ingress에 대한 `LoadBalancer`의 동적 값을 변경합니다(사용 중인 경우). `externalIP`에 관한 자세한 내용은 [글로벌 Ingress 설정 문서](../charts/globals.md#configure-ingress-settings)를 참조하십시오. DNS 레코드를 업데이트해야 할 수 있습니다!

### spec.selector {#specselector}

Sidekiq Pod은 차트 릴리스 `3.0.0` 이전에 고유한 선택자를 받지 못했습니다. [이에 대한 문제는 다음에 기록되었습니다](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/663).

`3.0.0`로 업그레이드하면 Helm은 자동으로 이전 Sidekiq 배포를 삭제하고 Sidekiq `Deployments`, `HPAs`, `Pods`의 이름에 `-v1`를 추가하여 새로 만듭니다.

`3.0.0`을 설치할 때 Sidekiq 배포에서 이 오류를 계속 겪고 있다면 다음 단계를 사용하여 해결하십시오:

1. Sidekiq 서비스를 제거합니다

   ```shell
   kubectl delete deployment --cascade -lrelease=RELEASE_NAME,app=sidekiq
   ```

1. Helm을 통해 업그레이드를 수행합니다.

### "RELEASE-NAME-cert-manager"를 Deployment 종류로 패치할 수 없음 {#cannot-patch-release-name-cert-manager-with-kind-deployment}

**CertManager** 버전 `0.10`에서 업그레이드하면 여러 주요 변경사항이 도입되었습니다. 이전 Custom Resource Definitions을 제거하고 Helm의 추적에서 제거한 후 다시 설치해야 합니다.

Helm 차트는 기본적으로 이를 수행하려고 시도하지만 이 오류가 발생하면 수동으로 조치해야 할 수 있습니다.

이 오류 메시지가 나타나면 새 Custom Resource Definitions이 배포에 실제로 적용되도록 일반적인 것보다 한 단계 더 업그레이드해야 합니다.

1. 이전 **CertManager** Deployment를 제거합니다.

   ```shell
   kubectl delete deployments -l app=cert-manager --cascade
   ```

1. 업그레이드를 다시 실행합니다. 이번에는 새 Custom Resource Definitions을 설치합니다

   ```shell
   helm upgrade --install --values - YOUR-RELEASE-NAME gitlab/gitlab < <(helm get values YOUR-RELEASE-NAME)
   ```

### `gitlab-kube-state-metrics`를 Deployment 종류로 패치할 수 없음 {#cannot-patch-gitlab-kube-state-metrics-with-kind-deployment}

**Prometheus** 버전 `11.16.9`에서 `15.0.4`로 업그레이드하면 [kube-state-metrics Deployment](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics)에 사용되는 선택자 레이블이 변경됩니다. 기본적으로 비활성화됨 (`prometheus.kubeStateMetrics.enabled=false`).

이 오류 메시지가 나타난다는 것은 `prometheus.kubeStateMetrics.enabled=true`를 의미하며, 업그레이드하려면 [추가 단계](https://artifacthub.io/packages/helm/prometheus-community/prometheus#to-15-0)가 필요합니다:

1. 이전 **kube-state-metrics** Deployment를 제거합니다.

   ```shell
   kubectl delete deployments.apps -l app.kubernetes.io/instance=RELEASE_NAME,app.kubernetes.io/name=kube-state-metrics --cascade=orphan
   ```

1. Helm을 통해 업그레이드를 수행합니다.

## `ImagePullBackOff`, `Failed to pull image` 및 `manifest unknown` 오류 {#imagepullbackoff-failed-to-pull-image-and-manifest-unknown-errors}

[`global.gitlabVersion`](../charts/globals.md#gitlab-version)를 사용하는 경우 해당 속성을 제거하여 시작합니다. [차트와 GitLab 간의 버전 매핑](../installation/version_mappings.md)을 확인하고 `helm` 명령에서 `gitlab/gitlab` 차트의 호환되는 버전을 지정합니다.

## 업그레이드 실패: `helm 2to3 convert` 후 "패치할 수 없음 ..." {#upgrade-failed-cannot-patch--after-helm-2to3-convert}

이것은 알려진 문제입니다. Helm 2 릴리스를 Helm 3으로 마이그레이션한 후 후속 업그레이드가 실패할 수 있습니다. 전체 설명과 해결 방법은 [Helm v2에서 Helm v3로 마이그레이션](../installation/migration/helm.md#known-issues)에서 찾을 수 있습니다.

## 업그레이드 실패: mailroom에서 타입 불일치: `%!t(<nil>)` {#upgrade-failed-type-mismatch-on-mailroom-tnil}

맵을 기대하는 키에 대해 유효한 맵을 제공하지 않으면 이와 같은 오류가 발생할 수 있습니다.

예를 들어 다음 구성은 이 오류를 야기합니다:

```yaml
gitlab:
  mailroom:
```

이를 해결하려면 다음 중 하나를 수행하십시오:

1. `gitlab.mailroom`에 대해 유효한 맵을 제공합니다.
1. `mailroom` 키를 완전히 제거합니다.

선택적 키의 경우 빈 맵(`{}`)은 유효한 값입니다.

## 번들된 NGINX Ingress Pod이 시작되지 않음: `Failed to watch *v1beta1.Ingress` {#bundled-nginx-ingress-pod-fails-to-start-failed-to-watch-v1beta1ingress}

Kubernetes 버전 1.22 이상을 실행하는 경우 다음 오류 메시지가 번들된 NGINX Ingress 컨트롤러 Pod에 나타날 수 있습니다:

```plaintext
Failed to watch *v1beta1.Ingress: failed to list *v1beta1.Ingress: the server could not find the requested resource
```

이를 해결하려면 Kubernetes 버전이 1.21 이상인지 확인하십시오. Kubernetes 1.22 이상의 NGINX Ingress 지원에 대한 자세한 내용은 [\#2852](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2852)를 참조하십시오.

## `/api/v4/jobs/request` 엔드포인트의 로드 증가 {#increased-load-on-apiv4jobsrequest-endpoint}

`/api/*`을 처리하는 배포에 대해 `workhorse.keywatcher` 옵션이 `false`로 설정된 경우 이 문제가 발생할 수 있습니다. 확인하려면 다음 단계를 사용하십시오:

1. `/api/*`을 처리하는 Pod에서 `gitlab-workhorse` 컨테이너에 액세스합니다:

   ```shell
   kubectl exec -it --container=gitlab-workhorse <gitlab_api_pod> -- /bin/bash
   ```

1. `/srv/gitlab/config/workhorse-config.toml` 파일을 검토합니다. `[redis]` 구성이 누락되었을 수 있습니다:

   ```shell
   grep '\[redis\]' /srv/gitlab/config/workhorse-config.toml
   ```

`[redis]` 구성이 없으면 `workhorse.keywatcher` 플래그가 배포 중 `false`으로 설정되어 `/api/v4/jobs/request` 엔드포인트에 추가 로드가 발생합니다. 이를 해결하려면 `webservice` 차트에서 `keywatcher`를 활성화합니다:

```yaml
workhorse:
  keywatcher: true
```

## SSH를 통한 Git: `the remote end hung up unexpectedly` {#git-over-ssh-the-remote-end-hung-up-unexpectedly}

SSH를 통한 Git 작업은 다음 오류로 간헐적으로 실패할 수 있습니다:

```plaintext
fatal: the remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
```

이 오류의 가능한 원인은 다음과 같습니다:

- **네트워크 타임아웃**:

  Git 클라이언트는 때때로 연결을 열어두고 유휴 상태로 두기도 합니다(예: 객체 압축). HAProxy의 `timeout client`와 같은 설정은 이러한 유휴 연결이 종료될 수 있습니다.

  `sshd`에서 keepalive를 설정할 수 있습니다:

  ```yaml
  gitlab:
    gitlab-shell:
      config:
        clientAliveInterval: 15
  ```

- **`gitlab-shell` 메모리**:

  기본적으로 차트는 GitLab Shell 메모리에 제한을 설정하지 않습니다. `gitlab.gitlab-shell.resources.limits.memory`이 너무 낮게 설정되면 SSH를 통한 Git 작업이 이러한 오류로 실패할 수 있습니다.

  `kubectl describe nodes`을 실행하여 이것이 네트워크 타임아웃이 아닌 메모리 제한으로 인한 것인지 확인합니다.

  ```plaintext
  System OOM encountered, victim process: gitlab-shell
  Memory cgroup out of memory: Killed process 3141592 (gitlab-shell)
  ```

## 오류: `kex_exchange_identification: Connection closed by remote host` {#error-kex_exchange_identification-connection-closed-by-remote-host}

GitLab Shell 로그에 다음 오류가 나타날 수 있습니다:

```plaintext
subcomponent":"ssh","time":"2025-02-21T19:07:52Z","message":"kex_exchange_identification: Connection closed by remote host\r"}
```

이 오류는 OpenSSH `sshd`이 준비 및 활성 상태 프로브를 처리할 수 없기 때문에 발생합니다. 이 오류를 해결하려면 `sshDaemon: openssh`을 `sshDaemon: gitlab-ssd`로 변경하여 구성에서 대신 [`gitlab-sshd`](../charts/gitlab/gitlab-shell/_index.md#configuration)를 사용하십시오:

```yaml
gitlab:
  gitlab-shell:
    sshDaemon: gitlab-sshd
```

## YAML 구성: `mapping values are not allowed in this context` {#yaml-configuration-mapping-values-are-not-allowed-in-this-context}

YAML 구성에 선행 공백이 포함된 경우 다음 오류 메시지가 나타날 수 있습니다:

```plaintext
template: /var/opt/gitlab/templates/workhorse-config.toml.tpl:16:98:
  executing \"/var/opt/gitlab/templates/workhorse-config.toml.tpl\" at <data.YAML>:
    error calling YAML:
      yaml: line 2: mapping values are not allowed in this context
```

이를 해결하려면 구성에 선행 공백이 없는지 확인하십시오.

예를 들어 다음을 변경합니다:

```yaml
  key1: value1
  key2: value2
```

... 이것으로:

```yaml
key1: value1
key2: value2
```

## TLS 및 인증서 {#tls-and-certificates}

GitLab 인스턴스가 개인 TLS 인증서 기관을 신뢰해야 하는 경우 GitLab이 개체 저장소, Elasticsearch, Jira 또는 Jenkins와 같은 다른 서비스와 핸드셰이크하지 못할 수 있습니다:

```plaintext
error: certificate verify failed (unable to get local issuer certificate)
```

개인 인증서 기관에서 서명한 인증서의 부분 신뢰는 다음과 같은 경우에 발생할 수 있습니다:

- 제공된 인증서가 별도 파일에 없습니다.
- 인증서 init 컨테이너가 필요한 모든 단계를 수행하지 않습니다.

또한 GitLab은 주로 Ruby on Rails 및 Go로 작성되어 있으며 각 언어의 TLS 라이브러리는 다르게 작동합니다. 이 차이로 인해 GitLab UI에서 작업 로그 렌더링이 실패하지만 원본 작업 로그는 문제 없이 다운로드되는 등의 문제가 발생할 수 있습니다.

`proxy_download` 구성에 따라 신뢰 저장소가 올바르게 구성되면 브라우저가 개체 저장소로 리디렉션되고 문제가 없습니다. 동시에 하나 이상의 GitLab 구성 요소의 TLS 핸드셰이크는 여전히 실패할 수 있습니다.

### 인증서 신뢰 설정 및 문제 해결 {#certificate-trust-setup-and-troubleshooting}

인증서 문제 해결의 일부로 다음을 확인하십시오:

- 신뢰해야 할 각 인증서에 대한 시크릿을 만듭니다.
- 파일당 하나의 인증서만 제공합니다.

  ```plaintext
  kubectl create secret generic custom-ca --from-file=unique_name=/path/to/cert
  ```

  이 예에서 인증서는 `unique_name` 키 이름을 사용하여 저장됩니다

번들 또는 체인을 제공하면 일부 GitLab 구성 요소가 작동하지 않습니다.

`kubectl get secrets` 및 `kubectl describe secrets/secretname`를 사용하여 Secret을 쿼리합니다. 이는 `Data` 아래에 인증서의 키 이름을 표시합니다.

`global.certificates.customCAs` [차트 글로벌에서](../charts/globals.md#custom-certificate-authorities)를 사용하여 추가 인증서를 신뢰하도록 제공합니다.

Pod이 배포되면 init 컨테이너가 인증서를 마운트하고 GitLab 구성 요소가 사용할 수 있도록 설정합니다. init 컨테이너는 `registry.gitlab.com/gitlab-org/build/cng/alpine-certificates`입니다.

추가 인증서는 `/usr/local/share/ca-certificates`에서 컨테이너로 마운트되며 Secret 키 이름을 인증서 파일 이름으로 사용합니다.

init 컨테이너는 `/scripts/bundle-certificates`를 실행합니다 ([소스](https://gitlab.com/gitlab-org/build/CNG-mirror/-/blob/master/certificates/scripts/bundle-certificates)). 그 스크립트에서 `update-ca-certificates`:

1. 사용자 정의 인증서를 `/usr/local/share/ca-certificates`에서 `/etc/ssl/certs`로 복사합니다.
1. 번들 `ca-certificates.crt`을 컴파일합니다.
1. 각 인증서에 대한 해시를 생성하고 Rails에 필요한 해시를 사용하여 symlink을 만듭니다. 인증서 번들은 경고와 함께 건너뜁니다:

   ```plaintext
   WARNING: unique_name does not contain exactly one certificate or CRL: skipping
   ```

[init 컨테이너의 상태 및 로그 문제 해결](https://kubernetes.io/docs/tasks/debug/debug-application/debug-init-containers/). 예를 들어 인증서 init 컨테이너의 로그를 보고 경고를 확인하려면:

```plaintext
kubectl logs gitlab-webservice-default-pod -c certificates
```

### Rails 콘솔에서 확인 {#check-on-the-rails-console}

toolbox Pod을 사용하여 Rails가 제공한 인증서를 신뢰하는지 확인합니다.

1. Rails 콘솔을 시작합니다 (`<namespace>`을 GitLab이 설치된 네임스페이스로 바꿉니다):

   ```shell
   kubectl exec -ti $(kubectl get pod -n <namespace> -lapp=toolbox -o jsonpath='{.items[0].metadata.name}') -n <namespace> -- bash
   /srv/gitlab/bin/rails console
   ```

1. Rails가 인증서 기관을 확인하는 위치를 확인합니다:

   ```ruby
   OpenSSL::X509::DEFAULT_CERT_DIR
   ```

1. Rails 콘솔에서 HTTPS 쿼리를 실행합니다:

   ```ruby
   ## Configure a web server to connect to:
   uri = URI.parse("https://myservice.example.com")

   require 'openssl'
   require 'net/http'
   Rails.logger.level = 0
   OpenSSL.debug=1
   http = Net::HTTP.new(uri.host, uri.port)
   http.set_debug_output($stdout)
   http.use_ssl = true

   http.verify_mode = OpenSSL::SSL::VERIFY_PEER
   # http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TLS verification disabled

   response = http.request(Net::HTTP::Get.new(uri.request_uri))
   ```

### init 컨테이너 문제 해결 {#troubleshoot-the-init-container}

Docker를 사용하여 인증서 컨테이너를 실행합니다.

1. 디렉토리 구조를 설정하고 인증서로 채웁니다:

   ```shell
   mkdir -p etc/ssl/certs usr/local/share/ca-certificates

     # The secret name is: my-root-ca
     # The key name is: corporate_root

   kubectl get secret my-root-ca -ojsonpath='{.data.corporate_root}' | \
        base64 --decode > usr/local/share/ca-certificates/corporate_root

     # Check the certificate is correct:

   openssl x509 -in usr/local/share/ca-certificates/corporate_root -text -noout
   ```

1. 올바른 컨테이너 버전을 확인합니다:

   ```shell
   kubectl get deployment -lapp=webservice -ojsonpath='{.items[0].spec.template.spec.initContainers[0].image}'
   ```

1. `etc/ssl/certs` 콘텐츠의 준비를 수행하는 컨테이너를 실행합니다:

   ```shell
   docker run -ti --rm \
        -v $(pwd)/etc/ssl/certs:/etc/ssl/certs \
        -v $(pwd)/usr/local/share/ca-certificates:/usr/local/share/ca-certificates \
        registry.gitlab.com/gitlab-org/build/cng/gitlab-base:v15.10.3
   ```

1. 인증서가 올바르게 구성되었는지 확인합니다:

   - `etc/ssl/certs/corporate_root.pem`이 생성되었습니다.
   - 인증서 자체에 대한 symlink인 해시된 파일명이 있어야 합니다 (예: `etc/ssl/certs/1234abcd.0`).
   - 파일과 기호 링크가 다음을 표시해야 합니다:

     ```shell
     ls -l etc/ssl/certs/ | grep corporate_root
     ```

     예를 들어:

     ```plaintext
     lrwxrwxrwx   1 root root      20 Oct  7 11:34 28746b42.0 -> corporate_root.pem
     -rw-r--r--   1 root root    1948 Oct  7 11:34 corporate_root.pem
     ```

## `308: Permanent Redirect`이 리디렉션 루프를 발생시킴 {#308-permanent-redirect-causing-a-redirect-loop}

`308: Permanent Redirect`은 로드 밸런서가 암호화되지 않은 트래픽(HTTP)을 NGINX로 보내도록 구성된 경우 발생할 수 있습니다. NGINX는 기본적으로 `HTTP`를 `HTTPS`로 리디렉션하므로 "리디렉션 루프"에 빠질 수 있습니다.

이를 해결하려면 [NGINX의 `use-forwarded-headers` 설정을 활성화합니다](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#use-forwarded-headers).

## `nginx-controller` 로그의 "잘못된 단어" 오류 및 `404` 오류 {#invalid-word-errors-in-the-nginx-controller-logs-and-404-errors}

Helm 차트 6.6 이상으로 업그레이드한 후 GitLab이나 클러스터에 설치된 타사 도메인을 방문할 때 `404` 반환 코드가 표시되고 `gitlab-nginx-ingress-controller` 로그에서 "잘못된 단어" 오류도 표시될 수 있습니다:

```console
gitlab-nginx-ingress-controller-899b7d6bf-688hr controller W1116 19:03:13.162001       7 store.go:846] skipping ingress gitlab/gitlab-minio: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-688hr controller W1116 19:03:13.465487       7 store.go:846] skipping ingress gitlab/gitlab-registry: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:12.233577       6 store.go:846] skipping ingress gitlab/gitlab-kas: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:12.536534       6 store.go:846] skipping ingress gitlab/gitlab-webservice-default: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:12.848844       6 store.go:846] skipping ingress gitlab/gitlab-webservice-default-smartcard: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:13.161640       6 store.go:846] skipping ingress gitlab/gitlab-minio: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:13.465425       6 store.go:846] skipping ingress gitlab/gitlab-registry: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
```

그 경우 GitLab 값 및 모든 타사 Ingress 객체에서 [구성 스니펫](https://kubernetes.github.io/ingress-nginx/examples/customization/configuration-snippets/)의 사용 여부를 검토하십시오. `nginx-ingress.controller.config.annotation-value-word-blocklist` 설정을 조정하거나 수정해야 할 수도 있습니다.

자세한 내용은 [주석 값 단어 차단 목록](../charts/nginx/_index.md#annotation-value-word-blocklist)을 참조하십시오.

### 볼륨 마운트는 오래 걸림 {#volume-mount-takes-a-long-time}

`gitaly` 또는 `toolbox` 차트 볼륨과 같은 대용량 볼륨을 마운트하는 것은 Pod의 `securityContext`과 일치하도록 Kubernetes가 볼륨의 내용 권한을 재귀적으로 변경하기 때문에 시간이 오래 걸릴 수 있습니다.

Kubernetes 1.23부터는 `securityContext.fsGroupChangePolicy`을 `OnRootMismatch`로 설정하여 이 문제를 완화할 수 있습니다. 이 플래그는 모든 GitLab 하위 차트에서 지원됩니다.

예를 들어 Gitaly 하위 차트의 경우:

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroupChangePolicy: "OnRootMismatch"
```

자세한 내용은 [Kubernetes 문서](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#configure-volume-permission-and-ownership-change-policy-for-pods)를 참조하십시오.

`fsGroupChangePolicy`을 지원하지 않는 Kubernetes 버전의 경우 `securityContext`의 설정을 변경하거나 완전히 삭제하여 문제를 완화할 수 있습니다.

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroup: ""
      runAsUser: ""
```

> [!note]
> 예 구문은 `securityContext` 설정을 완전히 제거합니다. `securityContext: {}` 또는 `securityContext:`를 설정하면 Helm이 기본값을 사용자가 제공한 구성과 병합하는 방식 때문에 작동하지 않습니다.

### 간헐적 502 오류 {#intermittent-502-errors}

Puma 작업자가 처리하는 요청이 메모리 제한 임계값을 초과하면 노드의 OOMKiller에 의해 종료됩니다. 그러나 요청을 종료해도 반드시 webservice Pod 자체가 종료되거나 다시 시작되지 않습니다. 이 상황으로 인해 요청이 `502` 타임아웃을 반환합니다. 로그에서는 `502` 오류가 기록된 직후 Puma 작업자가 생성되는 것으로 나타납니다.

```shell
2024-01-19T14:12:08.949263522Z {"correlation_id":"XXXXXXXXXXXX","duration_ms":1261,"error":"badgateway: failed to receive response: context canceled"....
2024-01-19T14:12:24.214148186Z {"component": "gitlab","subcomponent":"puma.stdout","timestamp":"2024-01-19T14:12:24.213Z","pid":1,"message":"- Worker 2 (PID: 7414) booted in 0.84s, phase: 0"}
```

이 문제를 해결하려면 [webservice Pod의 메모리 제한을 높입니다](../charts/gitlab/webservice/_index.md#memory-requestslimits).

### 업그레이드 실패 - `cannot patch "gitlab-prometheus-server" with kind Deployment` {#upgrade-failed---cannot-patch-gitlab-prometheus-server-with-kind-deployment}

차트 9.0을 사용하면 주요 버전 Prometheus 하위 차트를 업데이트했습니다. 선택자 레이블과 Prometheus 버전이 변경되었으며 수동 상호작용이 필요합니다.

Prometheus 차트를 업그레이드하려면 [마이그레이션 가이드](../releases/9_0.md#prometheus-upgrade)를 따르십시오.

## Webservice 준비 프로브가 실패 {#webservice-readiness-probe-fails}

GitLab 차트 버전 9.2(GitLab 18.2)부터 IPv4 및 IPv6 모두에 대한 듀얼 스택 지원이 기본적으로 활성화됩니다. GitLab 18.2 이전 버전을 사용자 정의 모니터링 IP 허용 목록으로 실행하는 경우 webservice Pod의 Kubernetes 프로브가 실패할 수 있습니다.

```plaintext
Events:
  Type     Reason                Age                   From                     Message
  ----     ------                ----                  ----                     -------
[snip]
  Warning  Unhealthy             43m (x15 over 44m)    kubelet                  Startup probe failed: HTTP probe failed with statuscode: 404
```

Webservice 프로브를 수정하려면 다음 중 하나를 수행하십시오:

- Webservice 이미지를 업그레이드하여 차트 버전과 일치시킵니다.
- 모니터링 허용 목록을 IPv6 매핑된 동등 주소로 확장합니다 (예: `::ffff:10.0.0.0` ~ `10.0.0.0`).
- 모니터링 엔드포인트를 IPv4 전용(`gitlab.webservice.monitoring.listenAddr=0.0.0.0`)으로 명시적으로 구성합니다.
- [노드/커널 레벨에서 IP 매핑을 비활성화합니다.](https://docs.kernel.org/networking/ip-sysctl.html#proc-sys-net-ipv6-variables)

## 잘못됨: `spec.progressDeadlineSeconds` {#invalid-specprogressdeadlineseconds}

Helm `v3.18.0`을 사용하는 경우 차트를 업그레이드할 때 이 오류가 발생합니다:

```shell
Error: UPGRADE FAILED: cannot patch "gitlab-nginx-ingress-controller" with kind Deployment: Deployment.apps "gitlab-nginx-ingress-controller" is invalid: spec.progressDeadlineSeconds: Invalid value: 0: must be greater than minReadySeconds
```

이를 해결하려면 Helm 클라이언트를 `v3.18.1` 이상으로 업그레이드합니다. 또는 `v3.17.x`로 다운그레이드할 수 있습니다.

이는 [Helm 문제 30878](https://github.com/helm/helm/issues/30878) 때문입니다.

## 마이그레이션 실패: `TypeError: Invalid type for configuration.` {#migrations-failing-typeerror-invalid-type-for-configuration}

기본적으로 GitLab 차트는 2개의 데이터베이스 연결을 설정합니다:

- 기본 Rails 애플리케이션 데이터베이스로.
- CI 데이터베이스로.

두 연결이 동일한 데이터베이스를 대상으로 할 때 구성 충돌을 방지하기 위해 하나의 데이터베이스만 데이터베이스 작업을 활성화해야 합니다(`databaseTasks: true`).

두 연결 모두 데이터베이스 작업이 활성화된 경우 마이그레이션이 이 오류로 실패합니다:

```plaintext
Running db:schema:load:main rake task
rake aborted!
TypeError: Invalid type for configuration. Expected Symbol, String, or Hash. Got nil
```

이 문제를 해결하려면 다음 중 하나를 수행하십시오:

- 값을 변경하여 `global.psql.databaseTasks`을 생략합니다.
- `databaseTasks`을 명시적으로 구성하고 데이터베이스 작업에 데이터베이스를 선택합니다. 예를 들어:

  ```yaml
  global:
    psql:
      main:
        databaseTasks: true
      ci:
        databaseTasks: false
  ```
