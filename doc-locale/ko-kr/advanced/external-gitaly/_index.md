---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 Gitaly를 사용하여 GitLab 차트 구성
---

이 문서는 외부 Gitaly 서비스로 이 Helm 차트를 구성하는 방법에 대한 설명서를 제공하려고 합니다.

Gitaly를 구성하지 않은 경우 온프레미스 또는 VM에 배포하는 경우 [Linux 패키지](external-omnibus-gitaly.md)를 사용하는 것을 고려하세요.

> [!note]
> 외부 Gitaly _서비스_는 Gitaly 노드 또는 [Praefect](https://docs.gitlab.com/administration/gitaly/praefect/) 클러스터에서 제공할 수 있습니다.

## 차트 구성 {#configure-the-chart}

`gitaly` 차트와 제공하는 Gitaly 서비스를 비활성화하고 다른 서비스를 외부 서비스로 지정합니다.

다음 속성을 설정해야 합니다:

- `global.gitaly.enabled`: `false`로 설정하여 포함된 Gitaly 차트를 비활성화합니다.
- `global.gitaly.external`: 이는 [외부 Gitaly 서비스](../../charts/globals.md#external)의 배열입니다.
- `global.gitaly.authToken.secret`: [인증을 위한 토큰이 포함된 시크릿](../../installation/secrets.md#gitaly-secret)의 이름입니다.
- `global.gitaly.authToken.key`: 비밀 내의 토큰 콘텐츠를 포함하는 키입니다.

외부 Gitaly 서비스는 자신의 GitLab Shell 인스턴스를 사용합니다. 구현에 따라 이 차트의 비밀을 사용하여 구성하거나 미리 정의된 소스의 콘텐츠로 이 차트의 비밀을 구성할 수 있습니다.

다음 속성을 **may** 있습니다:

- `global.shell.authToken.secret`: [GitLab Shell의 비밀이 포함된 비밀](../../installation/secrets.md#gitlab-shell-secret)의 이름입니다.
- `global.shell.authToken.key`: 비밀 내의 비밀 콘텐츠를 포함하는 키입니다.

두 개의 외부 Gitaly 서비스`external-gitaly.yml`의 완전한 구성 예:

```yaml
global:
  gitaly:
    enabled: false
    external:
      - name: default                   # required, at least one service must be called 'default'.
        hostname: node1.git.example.com # required
        port: 8075                      # optional, default shown
      - name: default2                  # required
        hostname: node2.git.example.com # required
        port: 8075                      # optional, default shown
        tlsEnabled: false               # optional, overrides gitaly.tls.enabled
    authToken:
      secret: external-gitaly-token     # required
      key: token                        # optional, default shown
    tls:
      enabled: false                    # optional, default shown
```

또는 `address` 필드를 사용하여 DNS 기반 주소를 포함한 Gitaly 서비스의 전체 URI를 지정할 수 있습니다:

```yaml
global:
  gitaly:
    enabled: false
    external:
      - name: default                                    # required
        address: dns://8.8.8.8:53/gitaly.consul.internal # required (alternative to hostname/port)
    authToken:
      secret: *********************                      # required
      key: token                                         # optional, default shown
```

### DNS 주소 형식 {#dns-address-format}

{{< history >}}

- DNS 주소 지원은 GitLab 18.8에서 [도입되었습니다](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4716).

{{< /history >}}

`address` 필드와 DNS 기반 URI를 사용할 때 형식은 [gRPC DNS 리졸버 명세](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/grpc_load_balancing.md)를 따릅니다:

```plaintext
dns:[//authority/]host[:port]
dns+tls:[//authority/]host[:port]
```

`dns+tls`을 사용하여 연결에 대해 TLS를 활성화합니다. 이 스킴은 DNS 기반 서비스 검색과 TLS 암호화를 결합합니다.

`authority`은 `IP address[:port]` 형식입니다. `authority`에 호스트명을 지정하면 작동하지 않습니다. 기본적으로 포트 53이 사용됩니다.

예를 들어:

- `dns:///gitaly.example.com`: 기본 authority를 사용할 때 슬래시 3개 `///`에 주의하세요.
- `dns://8.8.8.8:53/gitaly.consul.internal`: 포트가 있는 사용자 정의 DNS 리졸버입니다.
- `dns://10.0.1.50:8600/praefect.service.consul.:2305`: Praefect 서비스 및 포트가 있는 사용자 정의 DNS 리졸버입니다. Kubernetes DNS 접미사 추가를 방지하기 위해 뒤에 오는 `.`에 주의하세요.
- `dns+tls:///gitaly.example.com`: 기본 authority를 사용하여 TLS를 활성화한 DNS입니다.
- `dns+tls://10.0.1.50:8600/praefect.service.consul.:2305`: TLS를 활성화한 DNS 서버입니다.

뒤에 오는 `.`은 서비스가 Kubernetes 클러스터에서 실행되지 않을 때 중요합니다. gRPC 클라이언트는 Kubernetes의 기본 DNS 접미사(일반적으로 `.svc.cluster.local`)를 추가하는 것을 방지하기 위해 이것이 필요합니다. Pod에는 일반적으로 `options ndots:5`에 정의된 `/etc/resolv.conf`이 있으며, 이는 5개 미만의 점이 있는 서비스 이름에 대해 [DNS 쿼리가 확장되도록](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) 합니다.

`dns://10.0.1.50:8600/praefect.service.consul:2305` 예시에서 `8600`은 DNS 서버 포트이고 `2305`은 Praefect 서비스 포트입니다.

Praefect를 사용한 서비스 검색에 대한 자세한 내용은 [Praefect 서비스 검색 설명서](https://docs.gitlab.com/administration/gitaly/praefect/configure/#service-discovery)를 참조하세요.

외부 Praefect 서비스를 설정하는 완전한 예.

> [!note]
> Praefect 서비스 이름은 [`default`](../../charts/globals.md#external)이어야 합니다.

```yaml
global:
  gitaly:
    enabled: false
    external:
      - name: default                   # required
        hostname: ha.git.example.com    # required
        port: 2305                      # Praefect uses port 2305
        tlsEnabled: false               # optional, overrides gitaly.tls.enabled
    authToken:
      secret: external-gitaly-token     # required
      key: token                        # optional, default shown
    tls:
      enabled: false                    # optional, default shown
```

위의 구성 파일을 `gitlab.yml`을 통한 다른 구성과 함께 사용한 설치 예:

```shell
helm upgrade --install gitlab gitlab/gitlab  \
  -f gitlab.yml \
  -f external-gitaly.yml
```

## 여러 외부 Gitaly {#multiple-external-gitaly}

구현이 이 차트 외부의 여러 Gitaly 노드를 사용하는 경우 여러 호스트도 정의할 수 있습니다. 구문은 약간 다르므로 필요한 복잡성을 허용합니다.

[예제 값 파일](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-external.yaml)이 제공되며 적절한 구성 세트를 보여줍니다. 이 값 파일의 콘텐츠는 `--set` 인자를 통해 올바르게 해석되지 않으므로 `-f / --values` 플래그를 사용하여 Helm에 전달해야 합니다.

### 외부 Gitaly를 통한 TLS 연결 {#connecting-to-external-gitaly-over-tls}

외부 [Gitaly 서버가 TLS 포트를 수신하는 경우](https://docs.gitlab.com/administration/gitaly/#enable-tls-support) GitLab 인스턴스가 TLS를 통해 통신하도록 할 수 있습니다. 이를 수행하려면 다음을 수행해야 합니다

1. Gitaly 서버의 인증서를 포함하는 Kubernetes 비밀 생성

   ```shell
   kubectl create secret generic gitlab-gitaly-tls-certificate --from-file=gitaly-tls.crt=<path to certificate>
   ```

1. 외부 Gitaly 서버의 인증서를 [사용자 정의 인증 기관](../../charts/globals.md#custom-certificate-authorities) 목록에 추가하고 값 파일에서 다음을 지정합니다

   ```yaml
   global:
     certificates:
       customCAs:
         - secret: gitlab-gitaly-tls-certificate
   ```

   또는 `helm upgrade` 명령에 `--set`을 사용하여 전달합니다

   ```shell
   --set global.certificates.customCAs[0].secret=gitlab-gitaly-tls-certificate
   ```

1. 모든 Gitaly 인스턴스에 대해 TLS를 활성화하려면 `global.gitaly.tls.enabled: true`을 설정합니다.

   ```yaml
   global:
     gitaly:
       tls:
         enabled: true
   ```

   인스턴스별로 활성화하려면 해당 항목에 `tlsEnabled: true`을 설정합니다.

   ```yaml
   global:
     gitaly:
       external:
         - name: default
           hostname: node1.git.example.com
           tlsEnabled: true
   ```

> [!note]
> 이를 위해 유효한 비밀 이름과 키를 선택할 수 있지만 `customCAs`에 지정된 모든 비밀에서 키가 고유한지 확인하여 모든 비밀 내의 키가 마운트되므로 충돌을 방지합니다. 이것은 클라이언트 쪽이므로 인증서의 키를 제공할 **do not**. 이는 _클라이언트 쪽_입니다.

## GitLab이 Gitaly에 연결할 수 있는지 테스트 {#test-that-gitlab-can-connect-to-gitaly}

GitLab이 외부 Gitaly 서버에 연결할 수 있는지 확인하려면:

```shell
kubectl exec -it <toolbox-pod> -- gitlab-rake gitlab:gitaly:check
```

Gitaly와 TLS를 사용하는 경우 GitLab 차트가 Gitaly 인증서를 신뢰하는지 확인할 수도 있습니다:

```shell
kubectl exec -it <toolbox-pod> -- echo | /usr/bin/openssl s_client -connect <gitaly-host>:<gitaly-port>
```

## Gitaly 차트에서 외부 Gitaly로 마이그레이션 {#migrate-from-gitaly-chart-to-external-gitaly}

Gitaly 차트를 사용하여 Gitaly 서비스를 제공하고 모든 저장소를 외부 Gitaly 서비스로 마이그레이션해야 하는 경우 다음 방법 중 하나로 수행할 수 있습니다:

- [저장소 스토리지 이동 API를 사용하여 마이그레이션(권장)](#migrate-with-the-repository-storage-moves-api).
- [백업/복원 방법을 사용하여 마이그레이션](#migrate-with-the-backuprestore-method).

### 저장소 스토리지 이동 API를 사용하여 마이그레이션 {#migrate-with-the-repository-storage-moves-api}

이 방법:

- [저장소 스토리지 이동 API](https://docs.gitlab.com/api/project_repository_storage_moves/)를 사용하여 Gitaly 차트에서 외부 Gitaly 서비스로 저장소를 마이그레이션합니다.
- 무중단으로 수행할 수 있습니다.
- 외부 Gitaly 서비스가 Gitaly Pod과 동일한 VPC/영역 내에 있어야 합니다.
- [Praefect 차트](../../charts/gitlab/praefect/_index.md)로 테스트되지 않았으며 지원되지 않습니다.

#### 단계 1:  외부 Gitaly 서비스 또는 Gitaly 클러스터(Praefect) 설정 {#step-1-set-up-external-gitaly-service-or-gitaly-cluster-praefect}

[외부 Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/) 또는 [외부 Gitaly 클러스터(Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/)를 설정합니다. 차트 설치에서 Gitaly 토큰과 GitLab Shell 비밀을 제공해야 합니다:

```shell
# Get the GitLab Shell secret
kubectl get secret <release>-gitlab-shell-secret -ojsonpath='{.data.secret}' | base64 -d

# Get the Gitaly token
kubectl get secret <release>-gitaly-secret -ojsonpath='{.data.token}' | base64 -d
```

{{< tabs >}}

{{< tab title="Gitaly" >}}

- 여기서 추출한 Gitaly 토큰은 `AUTH_TOKEN` 값으로 사용해야 합니다.
- 여기서 추출한 GitLab Shell 비밀은 `shellsecret` 값으로 사용해야 합니다.

{{< /tab >}}

{{< tab title="Gitaly 클러스터(Praefect)" >}}

- 여기서 추출한 Gitaly 토큰은 `PRAEFECT_EXTERNAL_TOKEN`으로 사용해야 합니다.
- 여기서 추출한 GitLab Shell 비밀은 `GITLAB_SHELL_SECRET_TOKEN`으로 사용해야 합니다.

{{< /tab >}}

{{< /tabs >}}

마지막으로 외부 Gitaly 서비스의 방화벽이 Kubernetes Pod IP 범위에 대해 구성된 Gitaly 포트의 트래픽을 허용하는지 확인합니다.

#### 단계 2:  새 Gitaly 서비스를 사용하도록 인스턴스 구성 {#step-2-configure-instance-to-use-new-gitaly-service}

1. 외부 Gitaly를 사용하도록 GitLab을 구성합니다. 주 `gitlab.yml` 구성 파일에 Gitaly 참조가 있으면 제거하고 다음 내용으로 새 `mixed-gitaly.yml` 파일을 만듭니다.

   이전에 추가 Gitaly 스토리지를 정의한 경우 새 구성에서 같은 이름의 일치하는 Gitaly 스토리지를 지정해야 합니다. 그렇지 않으면 복원 작업이 실패합니다.

   TLS를 구성하는 경우 [외부 Gitaly를 통한 TLS 연결](#connecting-to-external-gitaly-over-tls) 섹션을 참조하세요:

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```yaml
   global:
     gitaly:
       internal:
         names:
           - default
       external:
         - name: ext-gitaly                # required
           hostname: node1.git.example.com # required
           port: 8075                      # optional, default shown
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

   {{< /tab >}}

   {{< tab title="Gitaly 클러스터(Praefect)" >}}

   ```yaml
   global:
     gitaly:
       internal:
         names:
           - default
       external:
         - name: ext-gitaly-cluster        # required
           hostname: ha.git.example.com    # required
           port: 2305                      # Praefect uses port 2305
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. `gitlab.yml` 및 `mixed-gitaly.yml` 파일을 사용하여 새 구성을 적용합니다:

   ```shell
   helm upgrade --install gitlab gitlab/gitlab \
     -f gitlab.yml \
     -f mixed-gitaly.yml
   ```

1. Toolbox Pod에서 GitLab이 외부 Gitaly에 성공적으로 연결할 수 있는지 확인합니다:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:gitaly:check
   ```

1. 외부 Gitaly가 차트 설치에 다시 연결할 수 있는지 확인합니다:

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   Gitaly 서비스가 GitLab API에 성공적으로 콜백을 수행할 수 있는지 확인합니다:

   ```shell
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

   {{< /tab >}}

   {{< tab title="Gitaly 클러스터(Praefect)" >}}

   모든 Praefect 노드에서 Praefect 서비스가 Gitaly 노드에 연결할 수 있는지 확인합니다:

   ```shell
   # Run on Praefect nodes
   sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dial-nodes
   ```

   모든 Gitaly 노드에서 Gitaly 서비스가 GitLab API에 성공적으로 콜백을 수행할 수 있는지 확인합니다:

   ```shell
   # Run on Gitaly nodes
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

      {{< /tab >}}

   {{< /tabs >}}

#### 단계 3:  Gitaly Pod IP 및 호스트명 가져오기 {#step-3-get-the-gitaly-pod-ip-and-hostnames}

저장소 스토리지 이동 API가 성공하려면 외부 Gitaly 서비스가 Pod 서비스 호스트명을 사용하여 Gitaly Pod에 다시 연결할 수 있어야 합니다. Pod 서비스 호스트명을 확인할 수 있도록 각 Gitaly 프로세스를 실행 중인 외부 Gitaly 서비스의 호스트 파일에 호스트명을 추가해야 합니다.

1. Gitaly Pod 및 각 내부 IP 주소/호스트명 목록을 가져옵니다:

   ```shell
   kubectl get pods -l app=gitaly -o jsonpath='{range .items[*]}{.status.podIP}{"\t"}{.spec.hostname}{"."}{.spec.subdomain}{"."}{.metadata.namespace}{".svc\n"}{end}'
   ```

1. 마지막 단계의 출력을 각 Gitaly 프로세스를 실행 중인 외부 Gitaly 서비스의 `/etc/hosts` 파일에 추가합니다.
1. 각 Gitaly 프로세스를 실행 중인 외부 Gitaly 서비스에서 Gitaly Pod 호스트명을 ping할 수 있는지 확인합니다:

   ```shell
   ping <gitaly pod hostname>
   ```

연결이 확인되면 저장소 스토리지 이동을 예약할 수 있습니다.

#### 단계 4:  저장소 스토리지 이동 예약 {#step-4-schedule-the-repository-storage-move}

[저장소 이동](https://docs.gitlab.com/administration/operations/moving_repositories/#moving-repositories)에 표시된 단계를 따라 이동을 예약합니다.

#### 단계 5:  최종 구성 및 검증 {#step-5-final-configuration-and-validation}

1. 여러 Gitaly 스토리지가 있는 경우 [새 저장소가 저장되는 위치를 구성](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored)합니다.
1. 외부 Gitaly 구성을 포함하는 통합 `gitlab.yml`을 생성하는 것을 고려합니다:

   ```shell
   helm get values <RELEASE_NAME> -o yaml > gitlab.yml
   ```

1. `gitlab.yml` 파일에서 내부 Gitaly 부분차트를 비활성화하고 새로운 `default` 저장소를 외부 Gitaly 서비스로 지정합니다. [GitLab은 기본 저장소 스토리지가 필요합니다](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#gitlab-requires-a-default-repository-storage):

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```yaml
   global:
     gitaly:
       enabled: false                      # Disable the internal Gitaly subchart
       external:
         - name: ext-gitaly                # required
           hostname: node1.git.example.com # required
           port: 8075                      # optional, default shown
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
         - name: default                   # Add the default repository storage, use the same settings as ext-gitaly
           hostname: node1.git.example.com
           port: 8075
           tlsEnabled: false
   ```

   {{< /tab >}}

   {{< tab title="Gitaly 클러스터(Praefect)" >}}

   ```yaml
   global:
     gitaly:
       enabled: false                      # Disable the internal Gitaly subchart
       external:
         - name: ext-gitaly-cluster        # required
           hostname: ha.git.example.com    # required
           port: 2305                      # Praefect uses port 2305
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
         - name: default                   # Add the default repository storage, use the same settings as ext-gitaly-cluster
           hostname: ha.git.example.com
           port: 2305
           tlsEnabled: false
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. 새 구성을 적용합니다:

   ```shell
   helm upgrade --install gitlab gitlab/gitlab \
     -f gitlab.yml
   ```

1. 선택 사항입니다. [Gitaly Pod IP 및 호스트명 가져오기](#step-3-get-the-gitaly-pod-ip-and-hostnames) 단계를 진행한 후 각 외부 Gitaly `/etc/hosts` 파일에 대한 변경 사항을 제거합니다.
1. 모든 것이 예상대로 작동하는지 확인한 후 Gitaly PVC를 삭제할 수 있습니다:

   경고:  모든 것이 예상대로 작동하는지 다시 확인할 때까지 Gitaly PVC를 삭제하지 마세요.

   ```shell
   kubectl delete pvc repo-data-<release>-gitaly-0
   ```

### 백업/복원 방법을 사용하여 마이그레이션 {#migrate-with-the-backuprestore-method}

이 방법:

- Gitaly 차트 PersistentVolumeClaim(PVC)에서 저장소를 백업한 다음 외부 Gitaly 서비스로 복원합니다.
- 모든 사용자에게 다운타임이 발생합니다.
- [Praefect 차트](../../charts/gitlab/praefect/_index.md)로 테스트되지 않았으며 지원되지 않습니다.

#### 단계 1:  GitLab 차트의 현재 릴리스 개정 가져오기 {#step-1-get-the-current-release-revision-of-the-gitlab-chart}

마이그레이션 중에 문제가 발생할 가능성은 낮지만 GitLab 차트의 현재 릴리스 개정을 가져옵니다. 출력을 복사하고 [롤백](#rollback)을 수행해야 할 경우를 대비하여 보관해 두세요:

```shell
helm history <release> --max=1
```

#### 단계 2:  외부 Gitaly 서비스 또는 Gitaly 클러스터(Praefect) 설정 {#step-2-setup-external-gitaly-service-or-gitaly-cluster-praefect}

[외부 Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/) 또는 [외부 Gitaly 클러스터(Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/)를 설정합니다. 차트 설치에서 Gitaly 토큰과 GitLab Shell 비밀을 제공해야 합니다:

```shell
# Get the GitLab Shell secret
kubectl get secret <release>-gitlab-shell-secret -ojsonpath='{.data.secret}' | base64 -d

# Get the Gitaly token
kubectl get secret <release>-gitaly-secret -ojsonpath='{.data.token}' | base64 -d
```

{{< tabs >}}

{{< tab title="Gitaly" >}}

- 여기서 추출한 Gitaly 토큰은 `AUTH_TOKEN` 값으로 사용해야 합니다.
- 여기서 추출한 GitLab Shell 비밀은 `shellsecret` 값으로 사용해야 합니다.

{{< /tab >}}

{{< tab title="Gitaly 클러스터(Praefect)" >}}

- 여기서 추출한 Gitaly 토큰은 `PRAEFECT_EXTERNAL_TOKEN`으로 사용해야 합니다.
- 여기서 추출한 GitLab Shell 비밀은 `GITLAB_SHELL_SECRET_TOKEN`으로 사용해야 합니다.

{{< /tab >}}

{{< /tabs >}}

#### 단계 3:  마이그레이션 중에 Git 변경이 수행되지 않는지 확인 {#step-3-verify-no-git-changes-can-be-made-during-migration}

마이그레이션의 데이터 무결성을 보장하려면 다음 단계에서 Git 저장소에 대한 변경 사항이 수행되지 않도록 방지합니다:

##### 1\. 유지보수 모드 활성화 {#1-enable-maintenance-mode}

GitLab Enterprise Edition을 사용 중인 경우 UI, API 또는 Rails 콘솔을 통해 [유지보수 모드](https://docs.gitlab.com/administration/maintenance_mode/#enable-maintenance-mode)를 활성화합니다:

```shell
kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Gitlab::CurrentSettings.update!(maintenance_mode: true)'
```

##### 2\. Runner Pod 축소 {#2-scale-down-runner-pods}

GitLab Community Edition을 사용 중인 경우 클러스터에서 실행 중인 모든 GitLab Runner Pod를 축소해야 합니다. 이는 Runner가 GitLab에 연결하여 CI/CD 작업을 처리하는 것을 방지합니다.

GitLab Enterprise Edition을 사용 중인 경우 [유지보수 모드](https://docs.gitlab.com/administration/maintenance_mode/#enable-maintenance-mode)가 클러스터의 Runner가 GitLab에 연결하는 것을 방지하므로 이 단계는 선택 사항입니다.

```shell
# Make note of the current number of replicas for Runners so we can scale up to this number later
kubectl get deploy -lapp=gitlab-gitlab-runner,release=<release> -o jsonpath='{.items[].spec.replicas}{"\n"}'

# Scale down the Runners pods to zero
kubectl scale deploy -lapp=gitlab-gitlab-runner,release=<release> --replicas=0
```

##### 3\. CI 작업이 실행되지 않는지 확인 {#3-confirm-no-ci-jobs-are-running}

관리 영역에서 **CI/CD > 작업**로 이동합니다. 이 페이지에는 모든 작업이 표시되지만 **실행중** 상태의 작업이 없는지 확인하세요. 다음 단계로 진행하기 전에 작업이 완료될 때까지 기다려야 합니다.

##### 4\. Sidekiq cron 작업 비활성화 {#4-disable-sidekiq-cron-jobs}

마이그레이션 중에 Sidekiq 작업이 예약 및 실행되는 것을 방지하려면 모든 Sidekiq cron 작업을 비활성화합니다:

```shell
kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:disable!)'
```

##### 5\. 백그라운드 작업이 실행되지 않는지 확인 {#5-confirm-no-background-jobs-are-running}

다음 단계로 진행하기 전에 대기열에 있거나 진행 중인 모든 작업이 완료될 때까지 기다려야 합니다.

1. 관리 영역에서 [**모니터링**](https://docs.gitlab.com/administration/admin_area/#background-jobs)으로 이동하고 **Background Jobs**을 선택합니다.
1. Sidekiq 대시보드에서 **Queues**를 선택한 후 **Live Poll**을 선택합니다.
1. **바쁨** 및 **Enqueued**이 0으로 떨어질 때까지 기다립니다.

   ![Sidekiq 백그라운드 작업](img/sidekiq_bg_jobs_v16_5.png)

##### 6\. Sidekiq 및 Webservice Pod 축소 {#6-scale-down-sidekiq-and-webservice-pods}

일관된 백업이 생성되도록 Sidekiq 및 Webservice Pod를 축소합니다. 두 서비스 모두 나중에 확장됩니다:

- Sidekiq Pod는 복원 단계 중에 다시 확장됩니다
- Webservice Pod는 외부 Gitaly 서비스로 전환한 후 연결을 테스트하기 위해 다시 확장됩니다

```shell
# Make note of the current number of replicas for Sidekiq and Webservice so we can scale up to this number later
kubectl get deploy -lapp=sidekiq,release=<release> -o jsonpath='{.items[].spec.replicas}{"\n"}'
kubectl get deploy -lapp=webservice,release=<release> -o jsonpath='{.items[].spec.replicas}{"\n"}'

# Scale down the Sidekiq and Webservice pods to zero
kubectl scale deploy -lapp=sidekiq,release=<release> --replicas=0
kubectl scale deploy -lapp=webservice,release=<release> --replicas=0
```

##### 7\. 클러스터로의 외부 연결 제한 {#7-restrict-external-connections-to-the-cluster}

사용자 및 외부 GitLab Runner가 GitLab을 변경하는 것을 방지하려면 GitLab으로의 모든 불필요한 연결을 제한해야 합니다.

이 단계가 완료되면 복원이 완료될 때까지 GitLab은 브라우저에서 완전히 사용할 수 없습니다.

마이그레이션 중에 클러스터를 새로운 외부 Gitaly 서비스에 액세스할 수 있게 유지하려면 외부 Gitaly 서비스의 IP 주소를 `nginx-ingress` 구성에 유일한 외부 예외로 추가해야 합니다.

1. 다음 내용으로 `ingress-only-allow-ext-gitaly.yml` 파일을 만듭니다:

   ```yaml
   nginx-ingress:
     controller:
       service:
         loadBalancerSourceRanges:
          - "x.x.x.x/32"
   ```

   `x.x.x.x`은 외부 Gitaly 서비스의 IP 주소입니다.

1. `gitlab.yml` 및 `ingress-only-allow-ext-gitaly.yml` 파일 모두를 사용하여 새 구성을 적용합니다:

   ```shell
   helm upgrade <release> gitlab/gitlab \
     -f gitlab.yml \
     -f ingress-only-allow-ext-gitaly.yml
   ```

##### 8\. 저장소 체크섬 목록 생성 {#8-create-list-of-repository-checksums}

백업을 실행하기 전에 [모든 GitLab 저장소를 확인](https://docs.gitlab.com/administration/raketasks/check/#check-all-gitlab-repositories)하고 저장소 체크섬 목록을 생성합니다. 마이그레이션 후 체크섬을 `diff`할 수 있도록 파일에 출력을 연결합니다:

```shell
kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:git:checksum_projects > ~/checksums-before.txt
```

#### 단계 4:  모든 저장소 백업 {#step-4-backup-all-repositories}

저장소만 [백업을 생성](../../backup-restore/backup.md#create-the-backup)합니다:

```shell
kubectl exec <toolbox pod name> -it -- backup-utility --skip artifacts,ci_secure_files,db,external_diffs,lfs,packages,pages,registry,terraform_state,uploads
```

#### 단계 5:  새 Gitaly 서비스를 사용하도록 인스턴스 구성 {#step-5-configure-instance-to-use-new-gitaly-service}

1. Gitaly 부분차트를 비활성화하고 외부 Gitaly를 사용하도록 GitLab을 구성합니다. 주 `gitlab.yml` 구성 파일에 Gitaly 참조가 있으면 제거하고 다음 내용으로 새 `external-gitaly.yml` 파일을 만듭니다.

   이전에 추가 Gitaly 스토리지를 정의한 경우 새 구성에서 같은 이름의 일치하는 Gitaly 스토리지를 지정해야 합니다. 그렇지 않으면 복원 작업이 실패합니다.

   TLS를 구성하는 경우 [외부 Gitaly를 통한 TLS 연결](#connecting-to-external-gitaly-over-tls) 섹션을 참조하세요:

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```yaml
   global:
     gitaly:
       enabled: false
       external:
         - name: default                   # required
           hostname: node1.git.example.com # required
           port: 8075                      # optional, default shown
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

   {{< /tab >}}

   {{< tab title="Gitaly 클러스터(Praefect)" >}}

   ```yaml
   global:
     gitaly:
       enabled: false
       external:
         - name: default                   # required
           hostname: ha.git.example.com    # required
           port: 2305                      # Praefect uses port 2305
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. `gitlab.yml`, `ingress-only-allow-ext-gitaly.yml` 및 `external-gitaly.yml` 파일을 사용하여 새 구성을 적용합니다:

   ```shell
   helm upgrade --install gitlab gitlab/gitlab \
     -f gitlab.yml \
     -f ingress-only-allow-ext-gitaly.yml \
     -f external-gitaly.yml
   ```

1. Webservice Pod를 원래 복제본 수로 확장합니다(실행 중이 아닌 경우). 이는 다음 단계에서 GitLab에서 외부 Gitaly로의 연결을 테스트할 수 있도록 하기 위해 필요합니다.

   ```shell
   kubectl scale deploy -lapp=webservice,release=<release> --replicas=<value>
   ```

1. Toolbox Pod에서 GitLab이 외부 Gitaly에 성공적으로 연결할 수 있는지 확인합니다:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:gitaly:check
   ```

1. 외부 Gitaly가 차트 설치에 다시 연결할 수 있는지 확인합니다:

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   Gitaly 서비스가 GitLab API에 성공적으로 콜백을 수행할 수 있는지 확인합니다:

   ```shell
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

   {{< /tab >}}

   {{< tab title="Gitaly 클러스터(Praefect)" >}}

   모든 Praefect 노드에서 Praefect 서비스가 Gitaly 노드에 연결할 수 있는지 확인합니다:

   ```shell
   # Run on Praefect nodes
   sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dial-nodes
   ```

   모든 Gitaly 노드에서 Gitaly 서비스가 GitLab API에 성공적으로 콜백을 수행할 수 있는지 확인합니다:

   ```shell
   # Run on Gitaly nodes
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

      {{< /tab >}}

   {{< /tabs >}}

#### 단계 6:  저장소 백업 복원 및 검증 {#step-6-restore-and-validate-repository-backup}

1. 이전에 생성한 [백업 파일을 복원](../../backup-restore/restore.md#restoring-the-backup-file)합니다. 결과적으로 저장소는 구성된 외부 Gitaly 또는 Gitaly 클러스터(Praefect)로 복사됩니다.

1. [모든 GitLab 저장소를 확인](https://docs.gitlab.com/administration/raketasks/check/#check-all-gitlab-repositories)하고 저장소 체크섬 목록을 생성합니다. 다음 단계에서 체크섬을 `diff`할 수 있도록 파일에 출력을 연결합니다:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:git:checksum_projects  > ~/checksums-after.txt
   ```

1. 저장소 마이그레이션 전후의 저장소 체크섬을 비교합니다. 체크섬이 동일하면 이 명령은 출력을 반환하지 않습니다:

   ```shell
   diff ~/checksums-before.txt ~/checksums-after.txt
   ```

   특정 줄에 대한 `diff` 출력에서 빈 체크섬이 `0000000000000000000000000000000000000000`로 변경되는 것을 관찰하면 이는 예상된 동작이며 안전하게 무시할 수 있습니다.

#### 단계 7:  최종 구성 및 검증 {#step-7-final-configuration-and-validation}

1. 외부 사용자 및 GitLab Runner가 GitLab에 다시 연결할 수 있도록 하려면 `gitlab.yml` 및 `external-gitaly.yml` 파일을 적용합니다. `ingress-only-allow-ext-gitaly.yml`을 지정하지 않으므로 IP 제한을 제거합니다:

    ```shell
    helm upgrade <release> gitlab/gitlab \
      -f gitlab.yml \
      -f external-gitaly.yml
    ```

    외부 Gitaly 구성을 포함하는 통합 `gitlab.yml`을 생성하는 것을 고려합니다:

    ```shell
    helm get values <release> gitlab/gitlab -o yaml > gitlab.yml
    ```

1. GitLab Enterprise Edition을 사용 중인 경우 UI, API 또는 Rails 콘솔을 통해 [유지보수 모드](https://docs.gitlab.com/administration/maintenance_mode/#enable-maintenance-mode)를 비활성화합니다:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Gitlab::CurrentSettings.update!(maintenance_mode: false)'
   ```

1. 여러 Gitaly 스토리지가 있는 경우 [새 저장소가 저장되는 위치를 구성](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored)합니다.
1. Sidekiq cron 작업을 활성화합니다:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:enable!)'
   ```

1. Runner Pod를 원래 복제본 수로 확장합니다(실행 중이 아닌 경우):

   ```shell
   kubectl scale deploy -lapp=gitlab-gitlab-runner,release=<release> --replicas=<value>
   ```

1. 모든 것이 예상대로 작동하는지 확인한 후 Gitaly PVC를 삭제할 수 있습니다:

   경고:  [단계 6](#step-6-restore-and-validate-repository-backup)에 따라 체크섬이 일치하는지 확인하고 모든 것이 예상대로 작동하는지 다시 확인할 때까지 Gitaly PVC를 삭제하지 마세요.

   ```shell
   kubectl delete pvc repo-data-<release>-gitaly-0
   ```

#### 롤백 {#rollback}

문제가 발생하면 변경 사항을 롤백하여 Gitaly 부분차트를 다시 사용하도록 할 수 있습니다.

원본 Gitaly PVC가 있어야 롤백이 성공합니다.

1. [단계 1에서 얻은 개정 번호를 사용하여 GitLab 차트를 이전 릴리스로 롤백합니다: GitLab 차트의 현재 릴리스 개정 가져오기](#step-1-get-the-current-release-revision-of-the-gitlab-chart):

   ```shell
   helm rollback <release> <revision>
   ```

1. Webservice Pod를 원래 복제본 수로 확장합니다(실행 중이 아닌 경우):

   ```shell
   kubectl scale deploy -lapp=webservice,release=<release> --replicas=<value>
   ```

1. Sidekiq Pod를 원래 복제본 수로 확장합니다(실행 중이 아닌 경우):

   ```shell
   kubectl scale deploy -lapp=sidekiq,release=<release> --replicas=<value>
   ```

1. 이전에 비활성화한 경우 Sidekiq cron 작업을 활성화합니다:

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:enable!)'
   ```

1. Runner Pod를 원래 복제본 수로 확장합니다(실행 중이 아닌 경우):

   ```shell
   kubectl scale deploy -lapp=gitlab-gitlab-runner,release=<release> --replicas=<value>
   ```

1. GitLab Enterprise Edition을 사용 중인 경우 [유지보수 모드](https://docs.gitlab.com/administration/maintenance_mode/#disable-maintenance-mode)를 비활성화합니다(활성화되어 있는 경우).

### 관련 설명서 {#related-documentation}

- [Gitaly 클러스터(Praefect)로 마이그레이션](https://docs.gitlab.com/administration/gitaly/praefect/#migrate-to-gitaly-cluster-praefect)
