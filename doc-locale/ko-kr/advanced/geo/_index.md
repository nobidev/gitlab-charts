---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Geo로 GitLab 차트 구성하기
---

GitLab Geo는 지리적으로 분산된 애플리케이션 배포를 가능하게 합니다.

외부 데이터베이스 서비스를 사용할 수 있지만, 이 문서는 [Linux 패키지](https://docs.gitlab.com/omnibus/)를 사용하여 PostgreSQL에 대해 가장 플랫폼 중립적인 가이드를 제공하고 `gitlab-ctl`에 포함된 자동화를 활용하는 데 중점을 두고 있습니다.

이 가이드에서는 두 클러스터 모두 동일한 외부 URL을 가집니다. 이 기능은 차트 버전 7.3 이후에서 지원됩니다. [Geo 사이트를 위한 통합 URL 설정](https://docs.gitlab.com/administration/geo/secondary_proxy/#set-up-a-unified-url-for-geo-sites)을 참조하세요. 선택적으로 [세컨더리 사이트를 위한 별도의 URL 구성](#configure-a-separate-url-for-the-secondary-site-optional)할 수 있습니다.

알려진 문제는 [Geo 문서](https://docs.gitlab.com/administration/geo/#known-issues)를 참조하세요.

> [!note] Geo의 모든 측면을 설명하기 위해 [정의된 용어](https://docs.gitlab.com/administration/geo/glossary/)를 참조하세요(주로 `site`과 `node` 간의 구별).

## 요구 사항 {#requirements}

GitLab Geo를 GitLab Helm 차트와 함께 사용하려면 다음 요구 사항을 충족해야 합니다:

- [외부 PostgreSQL](../external-db/_index.md) 서비스를 사용합니다. 차트에 포함된 PostgreSQL은 외부 네트워크에 노출되지 않으며, 복제에 필요한 WAL 지원이 없기 때문입니다.
- 제공되는 데이터베이스는 다음을 충족해야 합니다:
  - 복제를 지원합니다.
  - 프라이머리 데이터베이스는 프라이머리 사이트와 모든 세컨더리 데이터베이스 노드(복제용)에서 접근할 수 있어야 합니다.
  - 세컨더리 데이터베이스는 세컨더리 사이트에서만 접근할 수 있으면 됩니다.
  - 프라이머리와 세컨더리 데이터베이스 노드 간 SSL을 지원합니다.
- 프라이머리 사이트는 모든 세컨더리 사이트에서 HTTP(S)를 통해 접근할 수 있어야 합니다. 세컨더리 사이트는 프라이머리 사이트에서 HTTP(S)를 통해 접근할 수 있어야 합니다.
- [Geo 실행을 위한 요구 사항](https://docs.gitlab.com/administration/geo/#requirements-for-running-geo)을 참조하여 전체 요구 사항 목록을 확인하세요.

## 개요 {#overview}

이 가이드는 Linux 패키지를 사용하여 만든 2개의 데이터베이스 노드, 필요한 PostgreSQL 서비스만 구성하고, GitLab Helm 차트의 2개 배포를 사용합니다. _최소_ 필요 구성을 목표로 합니다. 이 문서는 애플리케이션에서 데이터베이스로의 SSL, 다른 데이터베이스 공급자 지원 또는 [세컨더리 사이트를 프라이머리로 승격](https://docs.gitlab.com/administration/geo/disaster_recovery/)을 포함하지 않습니다.

아래의 개요는 순서대로 따라야 합니다:

1. [Linux 패키지 데이터베이스 노드 설정](#set-up-linux-package-database-nodes)
1. [Kubernetes 클러스터 설정](#set-up-kubernetes-clusters)
1. [정보 수집](#collect-information)
1. [프라이머리 데이터베이스 구성](#configure-primary-database)
1. [Geo 프라이머리 사이트로 차트 배포](#deploy-chart-as-geo-primary-site)
1. [Geo 프라이머리 사이트 설정](#set-the-geo-primary-site)
1. [세컨더리 데이터베이스 구성](#configure-secondary-database)
1. [프라이머리 사이트에서 세컨더리 사이트로 비밀 복사](#copy-secrets-from-the-primary-site-to-the-secondary-site)
1. [Geo 세컨더리 사이트로 차트 배포](#deploy-chart-as-geo-secondary-site)
1. [프라이머리를 통해 세컨더리 Geo 사이트 추가](#add-secondary-geo-site-via-primary)
1. [운영 상태 확인](#confirm-operational-status)
1. [세컨더리 사이트를 위한 별도의 URL 구성(선택사항)](#configure-a-separate-url-for-the-secondary-site-optional)
1. [레지스트리](#registry)
1. [Cert-manager 및 통합 URL](#cert-manager-and-unified-url)

## Linux 패키지 데이터베이스 노드 설정 {#set-up-linux-package-database-nodes}

이 프로세스에는 두 개의 노드가 필요합니다. 하나는 프라이머리 데이터베이스 노드이고, 다른 하나는 세컨더리 데이터베이스 노드입니다. 온프레미스 또는 클라우드 공급자에서 모든 머신 인프라 공급자를 사용할 수 있습니다.

다음의 통신이 필요합니다:

- 복제를 위해 두 데이터베이스 노드 간.
- 각 데이터베이스 노드와 해당 Kubernetes 배포 간:
  - 프라이머리는 TCP 포트 `5432`을(를) 노출해야 합니다.
  - 세컨더리는 TCP 포트 `5432` & `5431`을(를) 노출해야 합니다.

[Linux 패키지에서 지원하는 운영 체제](https://docs.gitlab.com/install/requirements/#operating-systems) 를 설치한 후 [Linux 패키지를 설치](https://about.gitlab.com/install/)하세요. 설치할 때 `EXTERNAL_URL` 환경 변수를 제공하지 마세요. 재구성하기 전에 최소 구성 파일을 제공할 것입니다.

운영 체제 및 GitLab 패키지를 설치한 후 사용할 서비스에 대한 구성을 만들 수 있습니다. 그 전에 정보를 수집해야 합니다.

## Kubernetes 클러스터 설정 {#set-up-kubernetes-clusters}

이 프로세스에는 두 개의 Kubernetes 클러스터를 사용해야 합니다. 이들은 모든 공급자, 온프레미스 또는 클라우드 공급자에서 올 수 있습니다.

다음의 통신이 필요합니다:

- 해당 데이터베이스 노드로:
  - 프라이머리는 TCP `5432`로 아웃바운드합니다.
  - 세컨더리는 TCP `5432`과(와) `5431`로 아웃바운드합니다.
- 두 Kubernetes Ingress는 HTTPS를 통해.

프로비저닝되는 각 클러스터는 다음을 가져야 합니다:

- 이 차트의 기본 설치를 지원할 충분한 리소스.
- 지속적 스토리지에 대한 액세스:
  - [외부 객체 저장소](../external-object-storage/_index.md)를 사용하는 경우 MinIO는 필요하지 않습니다.
  - [외부 Gitaly](../external-gitaly/_index.md)를 사용하는 경우 Gitaly는 필요하지 않습니다.
  - [외부 Redis](../external-redis/_index.md)를 사용하는 경우 Redis는 필요하지 않습니다.

## 정보 수집 {#collect-information}

구성을 계속하려면 다양한 소스에서 다음 정보를 수집해야 합니다. 이를 수집하고 이 문서의 나머지 부분에서 사용할 메모를 작성하세요.

- 프라이머리 데이터베이스:
  - IP 주소
  - 호스트명(선택사항)
- 세컨더리 데이터베이스:
  - IP 주소
  - 호스트명(선택사항)
- 프라이머리 클러스터:
  - 외부 URL
  - 내부 URL
  - 노드의 IP 주소
- 세컨더리 클러스터:
  - 내부 URL
  - 노드의 IP 주소
- 데이터베이스 암호(_암호를 미리 결정해야 함_):
  - `gitlab` (`postgresql['sql_user_password']`, `global.psql.password`에서 사용)
  - `gitlab_geo` (`geo_postgresql['sql_user_password']`, `global.geo.psql.password`에서 사용)
  - `gitlab_replicator` (복제에 필요)
- GitLab 라이선스 파일

각 클러스터의 내부 URL은 모든 클러스터가 다른 모든 클러스터에 요청할 수 있도록 클러스터에 고유해야 합니다. 예를 들면:

- 모든 클러스터의 외부 URL: `https://gitlab.example.com`
- 프라이머리 클러스터의 내부 URL: `https://london.gitlab.example.com`
- 세컨더리 클러스터의 내부 URL: `https://shanghai.gitlab.example.com`

이 가이드는 DNS 설정을 다루지 않습니다.

`gitlab`과(와) `gitlab_geo` 데이터베이스 사용자 암호는 평문 암호와 PostgreSQL 해시된 암호 두 가지 형식으로 존재해야 합니다. 해시된 형식을 얻으려면 Linux 패키지 설치 인스턴스 중 하나에서 다음 명령을 수행하세요. 암호를 입력하고 확인한 후 메모할 적절한 해시 값을 출력합니다.

1. `gitlab-ctl pg-password-md5 gitlab`
1. `gitlab-ctl pg-password-md5 gitlab_geo`

## 프라이머리 데이터베이스 구성 {#configure-primary-database}

_이 섹션은 프라이머리 Linux 패키지 설치 데이터베이스 노드에서 수행됩니다._

프라이머리 데이터베이스 노드의 Linux 패키지 설치를 구성하려면 이 예제 구성에서 시작하세요:

```ruby
### Geo Primary
external_url 'http://gitlab.example.com'
roles ['geo_primary_role']
# The unique identifier for the Geo node.
gitlab_rails['geo_node_name'] = 'London Office'
# Allow cross-site origins for ActionCable requests.
gitlab_rails['action_cable_allowed_origins'] = ['https://gitlab.example.com']
gitlab_rails['auto_migrate'] = false
## turn off everything but the DB
sidekiq['enable']=false
puma['enable']=false
gitlab_workhorse['enable']=false
nginx['enable']=false
geo_logcursor['enable']=false
gitaly['enable']=false
redis['enable']=false
gitlab_kas['enable']=false
prometheus_monitoring['enable'] = false
## Configure the DB for network
postgresql['enable'] = true
postgresql['listen_address'] = '0.0.0.0'
postgresql['sql_user_password'] = 'gitlab_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - primary application deployment
# - secondary database node(s)
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
```

다음 항목들을 교체해야 합니다:

- `external_url`은(는) 프라이머리 사이트의 호스트 이름을 반영하도록 업데이트되어야 합니다.
- `gitlab_rails['geo_node_name']`은(는) 사이트의 고유한 이름으로 교체되어야 합니다. [공통 설정](https://docs.gitlab.com/administration/geo_sites/#common-settings)의 Name 필드를 참조하세요.
- `gitlab_rails['action_cable_allowed_origins']`은(는) 모든 클러스터의 **external URLs**을 포함하는 배열로 교체되어야 합니다: 프라이머리와 세컨더리 모두 또는 동일한 외부 URL을 가진 경우 통합 URL.
- `gitlab_user_password_hash`은(는) `gitlab` 암호의 해시된 형식으로 교체되어야 합니다.
- `postgresql['md5_auth_cidr_addresses']`은(는) 명시적 IP 주소 또는 CIDR 표기법의 주소 블록 목록으로 업데이트될 수 있습니다.

`md5_auth_cidr_addresses`은(는) `[ '127.0.0.1/24', '10.41.0.0/16']` 형식이어야 합니다. Linux 패키지의 자동화가 이를 사용하여 연결되기 때문에 이 목록에 `127.0.0.1`을(를) 포함하는 것이 중요합니다. 이 목록의 주소에는 세컨더리 데이터베이스의 IP 주소(호스트명 아님)와 프라이머리 Kubernetes 클러스터의 모든 노드가 포함되어야 합니다. 이를 _사용할 수_ 있습니다 `['0.0.0.0/0']`, 그러나 _모범 사례가 아닙니다_.

위의 구성이 준비되면:

1. 내용을 `/etc/gitlab/gitlab.rb`에 배치하세요
1. `gitlab-ctl reconfigure`을(를) 실행하세요. TCP 수신에 관한 문제가 발생하면 `gitlab-ctl restart postgresql`를 사용하여 직접 다시 시작해 보세요.
1. `gitlab-ctl set-replication-password`을(를) 실행하여 `gitlab_replicator` 사용자의 암호를 설정하세요.
1. 프라이머리 데이터베이스 노드의 공개 인증서를 검색합니다. 이는 세컨더리 데이터베이스가 복제할 수 있도록 필요합니다(이 출력을 저장하세요):

   ```shell
   cat ~gitlab-psql/data/server.crt
   ```

## Geo 프라이머리 사이트로 차트 배포 {#deploy-chart-as-geo-primary-site}

_이 섹션은 프라이머리 사이트의 Kubernetes 클러스터에서 수행됩니다._

이 차트를 Geo 프라이머리로 배포하려면 [이 예제 구성에서 시작](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml)하세요:

1. 차트에서 사용할 데이터베이스 암호를 포함하는 비밀을 만듭니다. `PASSWORD`을(를) `gitlab` 데이터베이스 사용자의 암호로 교체하세요:

   ```shell
   kubectl --namespace gitlab create secret generic geo --from-literal=postgresql-password=PASSWORD
   ```

1. `primary.yaml` 파일을 [예제 구성](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/primary.yaml)에 기반하여 만들고 구성을 업데이트하여 올바른 값을 반영하세요:

   ```yaml
   ### Geo Primary
   global:
     # See docs.gitlab.com/charts/charts/globals
     # Configure host & domain
     hosts:
       domain: example.com
       # optionally configure a static IP for the default LoadBalancer
       # externalIP:
       # optionally configure a static IP for the Geo LoadBalancer
       # externalGeoIP:
     # configure DB connection
     psql:
       host: geo-1.db.example.com
       port: 5432
       password:
         secret: geo
         key: postgresql-password
     # configure geo (primary)
     geo:
       nodeName: London Office
       enabled: true
       role: primary
   ```

   <!-- markdownlint-disable MD044 -->
   - [`global.hosts.domain`](../../charts/globals.md#configure-host-settings)
   - [`global.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - `global.geo.nodeName`은(는) [관리 영역의 Geo 사이트의 Name 필드](https://docs.gitlab.com/administration/geo_sites/#common-settings)와 일치해야 합니다
   - 다음과 같은 추가 설정도 구성하세요:
     - [SSL/TLS 구성](../../installation/tools.md#tls-certificates)
     - [외부 Redis 사용](../external-redis/_index.md)
     - [외부 객체 저장소 사용](../external-object-storage/_index.md)
   <!-- markdownlint-enable MD044 -->

1. `primary.yaml`에 필요한 Ingress 또는 Gateway API 구성을 추가하세요.

   {{< tabs >}}

   {{< tab title="NGINX Ingress" >}}

   내부(사이트 간) Geo 트래픽을 위해 추가 NGINX 컨트롤러와 추가 webservice Ingress를 구성하세요:

   ```yaml
   # Configure Geo Nginx Controller for internal Geo site traffic
   nginx-ingress-geo:
     enabled: true
   gitlab:
     webservice:
       # Use the Geo NGINX controller.
       ingress:
         useGeoClass: true
       # Configure an Ingress for internal Geo traffic
       extraIngress:
         enabled: true
         hostname: gitlab.london.example.com
         useGeoClass: true
   ```

   {{< /tab >}}

   {{< tab title="Envoy Gateway" >}}

   NGINX Ingress 기반 접근 방식의 대안으로, [Gateway API를 구성](../../charts/globals.md#gateway-api) 하고 번들된 [Envoy Gateway](../../charts/envoygateway/_index.md)를 노출하여 Geo를 노출할 수 있습니다.

   Gateway API를 활성화한 후 내부 Geo 트래픽을 위한 호스트명을 구성하세요:

   ```yaml
   global:
     geo:
       gatewayApi:
         additionalHostname: gitlab.london.example.com
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. 이 구성을 사용하여 차트를 배포하세요:

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f primary.yaml
   ```

   > [!note] `gitlab` 네임스페이스를 사용하고 있다고 가정합니다. 다른 네임스페이스를 사용하려면 이 문서의 나머지 부분에서 `--namespace gitlab`에서도 교체해야 합니다.

1. 배포가 완료되고 애플리케이션이 온라인 상태가 될 때까지 기다리세요. 애플리케이션에 접근할 수 있으면 로그인하세요.

1. GitLab에 로그인하고 [GitLab 구독을 활성화](https://docs.gitlab.com/administration/license/)하세요. 이 단계는 Geo가 작동하는 데 필요합니다.

## Geo 프라이머리 사이트 설정 {#set-the-geo-primary-site}

차트가 배포되고 라이선스가 업로드되었으므로 이를 프라이머리 사이트로 구성할 수 있습니다. Toolbox Pod를 통해 이를 수행할 것입니다.

1. Toolbox Pod 찾기

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. `gitlab-rake geo:set_primary_node`을(를) `kubectl exec`와 함께 실행하세요:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake geo:set_primary_node
   ```

1. Rails runner 명령을 사용하여 프라이머리 사이트의 내부 URL을 설정하세요. `https://primary.gitlab.example.com`을(를) 실제 내부 URL로 교체하세요:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rails runner "GeoNode.primary_node.update!(internal_url: 'https://primary.gitlab.example.com')"
   ```

1. Geo 구성의 상태를 확인하세요:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- gitlab-rake gitlab:geo:check
   ```

   아래와 유사한 출력이 표시되어야 합니다:

   ```plaintext
   WARNING: This version of GitLab depends on gitlab-shell 10.2.0, but you're running Unknown. Please update gitlab-shell.
   Checking Geo ...

   GitLab Geo is available ... yes
   GitLab Geo is enabled ... yes
   GitLab Geo secondary database is correctly configured ... not a secondary node
   Database replication enabled? ... not a secondary node
   Database replication working? ... not a secondary node
   GitLab Geo HTTP(S) connectivity ... not a secondary node
   HTTP/HTTPS repository cloning is enabled ... yes
   Machine clock is synchronized ... Exception: getaddrinfo: Servname not supported for ai_socktype
   Git user has default SSH configuration? ... yes
   OpenSSH configured to use AuthorizedKeysCommand ... no
     Reason:
     Cannot find OpenSSH configuration file at: /assets/sshd_config
     Try fixing it:
     If you are not using our official docker containers,
     make sure you have OpenSSH server installed and configured correctly on this system
     For more information see:
     doc/administration/operations/fast_ssh_key_lookup.md
   GitLab configured to disable writing to authorized_keys file ... yes
   GitLab configured to store new projects in hashed storage? ... yes
   All projects are in hashed storage? ... yes

   Checking Geo ... Finished
   ```

   - `Exception: getaddrinfo: Servname not supported for ai_socktype`에 대해 걱정하지 마세요. Kubernetes 컨테이너는 호스트 시계에 접근할 수 없습니다. _이것은 괜찮습니다_.
   - `OpenSSH configured to use AuthorizedKeysCommand ... no` _예상됩니다_. 이 Rake 작업은 로컬 SSH 서버를 확인하고 있으며, 이는 실제로 다른 곳에 배포된 `gitlab-shell` 차트에 있으며 이미 적절히 구성되어 있습니다.

## 세컨더리 데이터베이스 구성 {#configure-secondary-database}

_이 섹션은 세컨더리 Linux 패키지 설치 데이터베이스 노드에서 수행됩니다._

세컨더리 데이터베이스 노드의 Linux 패키지 설치를 구성하려면 이 예제 구성에서 시작하세요:

```ruby
### Geo Secondary
# external_url must match the Primary cluster's external_url
external_url 'http://gitlab.example.com'
roles ['geo_secondary_role']
gitlab_rails['enable'] = true
# The unique identifier for the Geo node.
gitlab_rails['geo_node_name'] = 'Shanghai Office'
gitlab_rails['auto_migrate'] = false
geo_secondary['auto_migrate'] = false
## turn off everything but the DB
sidekiq['enable']=false
puma['enable']=false
gitlab_workhorse['enable']=false
nginx['enable']=false
geo_logcursor['enable']=false
gitaly['enable']=false
redis['enable']=false
prometheus_monitoring['enable'] = false
gitlab_kas['enable']=false
## Configure the DBs for network
postgresql['enable'] = true
postgresql['listen_address'] = '0.0.0.0'
postgresql['sql_user_password'] = 'gitlab_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - secondary application deployment
# - secondary database node(s)
postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
geo_postgresql['listen_address'] = '0.0.0.0'
geo_postgresql['sql_user_password'] = 'gitlab_geo_user_password_hash'
# !! CAUTION !!
# This list of CIDR addresses should be customized
# - secondary application deployment
# - secondary database node(s)
geo_postgresql['md5_auth_cidr_addresses'] = ['0.0.0.0/0']
gitlab_rails['db_password']='gitlab_user_password'
```

다음 항목들을 교체해야 합니다:

- `gitlab_rails['geo_node_name']`은(는) 사이트의 고유한 이름으로 교체되어야 합니다. [공통 설정](https://docs.gitlab.com/administration/geo_sites/#common-settings)의 Name 필드를 참조하세요.
- `gitlab_user_password_hash`은(는) `gitlab` 암호의 해시된 형식으로 교체되어야 합니다.
- `postgresql['md5_auth_cidr_addresses']`을(를) 명시적 IP 주소 또는 CIDR 표기법의 주소 블록 목록으로 업데이트해야 합니다.
- `gitlab_geo_user_password_hash`은(는) `gitlab_geo` 암호의 해시된 형식으로 교체되어야 합니다.
- `geo_postgresql['md5_auth_cidr_addresses']`을(를) 명시적 IP 주소 또는 CIDR 표기법의 주소 블록 목록으로 업데이트해야 합니다.
- `gitlab_user_password`을(를) 업데이트해야 하며, Linux 패키지가 PostgreSQL 구성을 자동화할 수 있도록 여기에서 사용됩니다.

`md5_auth_cidr_addresses`은(는) `[ '127.0.0.1/24', '10.41.0.0/16']` 형식이어야 합니다. Linux 패키지의 자동화가 이를 사용하여 연결되기 때문에 이 목록에 `127.0.0.1`을(를) 포함하는 것이 중요합니다. 이 목록의 주소에는 세컨더리 Kubernetes 클러스터의 모든 노드의 IP 주소가 포함되어야 합니다. 이를 _사용할 수_ 있습니다 `['0.0.0.0/0']`, 그러나 _모범 사례가 아닙니다_.

위의 구성이 준비되면:

1. **프라이머리** 사이트의 PostgreSQL 노드에 대한 TCP 연결을 확인하세요:

   ```shell
   openssl s_client -connect <primary_node_ip>:5432 </dev/null
   ```

   출력에는 다음이 표시되어야 합니다:

   ```plaintext
   CONNECTED(00000003)
   write:errno=0
   ```

   이 단계가 실패하면 잘못된 IP 주소를 사용하거나 방화벽이 서버에 대한 액세스를 차단할 수 있습니다. IP 주소를 확인하고 공개 및 개인 주소 간의 차이에 주의를 기울이고, 방화벽이 있는 경우 **세컨더리** PostgreSQL 노드가 TCP 포트 5432의 **프라이머리** PostgreSQL 노드에 연결할 수 있는지 확인하세요.

1. 내용을 `/etc/gitlab/gitlab.rb`에 배치하세요
1. `gitlab-ctl reconfigure`을(를) 실행하세요. TCP 수신에 관한 문제가 발생하면 `gitlab-ctl restart postgresql`를 사용하여 직접 다시 시작해 보세요.
1. 위의 프라이머리 PostgreSQL 노드의 인증서 내용을 `primary.crt`에 배치하세요
1. **세컨더리** PostgreSQL 노드에서 PostgreSQL TLS 검증을 설정하세요:

   `primary.crt` 파일을 설치하세요:

   ```shell
   install \
      -D \
      -o gitlab-psql \
      -g gitlab-psql \
      -m 0400 \
      -T primary.crt ~gitlab-psql/.postgresql/root.crt
   ```

   PostgreSQL은 이제 TLS 연결을 검증할 때 정확한 인증서만 인식합니다. 인증서는 개인 키에 액세스할 수 있는 사람에 의해서만 복제될 수 있으며, 이는 **only** **프라이머리** PostgreSQL 노드에만 있습니다.

1. `gitlab-psql` 사용자가 **프라이머리** 사이트의 PostgreSQL에 연결할 수 있는지 테스트하세요(기본 Linux 패키지 데이터베이스 이름은 `gitlabhq_production`입니다):

   ```shell
   sudo \
      -u gitlab-psql /opt/gitlab/embedded/bin/psql \
      --list \
      -U gitlab_replicator \
      -d "dbname=gitlabhq_production sslmode=verify-ca" \
      -W \
      -h <primary_database_node_ip>
   ```

   메시지가 표시되면 `gitlab_replicator` 사용자에 대해 이전에 수집한 암호를 입력하세요. 모든 것이 올바르게 작동했으면 **프라이머리** PostgreSQL 노드의 데이터베이스 목록을 볼 수 있습니다.

   여기에 연결하지 못하면 TLS 구성이 잘못되었음을 나타냅니다. **프라이머리** PostgreSQL 노드의 `~gitlab-psql/data/server.crt` 내용이 **세컨더리** PostgreSQL 노드의 `~gitlab-psql/.postgresql/root.crt` 내용과 일치하는지 확인하세요.

1. 데이터베이스를 복제하세요. `PRIMARY_DATABASE_HOST`을(를) 프라이머리 PostgreSQL 노드의 IP 또는 호스트명으로 교체하세요:

   ```shell
   gitlab-ctl replicate-geo-database --slot-name=geo_2 --host=PRIMARY_DATABASE_HOST --sslmode=verify-ca
   ```

1. 복제가 완료된 후, Linux 패키지를 한 번 더 재구성하여 `pg_hba.conf`이(가) 세컨더리 PostgreSQL 노드에 올바른지 확인해야 합니다:

   ```shell
   gitlab-ctl reconfigure
   ```

## 프라이머리 사이트에서 세컨더리 사이트로 비밀 복사 {#copy-secrets-from-the-primary-site-to-the-secondary-site}

이제 프라이머리 사이트의 Kubernetes 배포에서 세컨더리 사이트의 Kubernetes 배포로 몇 가지 비밀을 복사하세요:

- `gitlab-geo-gitlab-shell-host-keys`
- `gitlab-geo-rails-secret`
- `gitlab-geo-registry-secret`, 레지스트리 복제가 활성화된 경우.

1. `kubectl` 컨텍스트를 프라이머리의 컨텍스트로 변경하세요.
1. 프라이머리 배포에서 이러한 비밀을 수집하세요:

   ```shell
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-gitlab-shell-host-keys > ssh-host-keys.yaml
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-rails-secret > rails-secrets.yaml
   kubectl get --namespace gitlab -o yaml secret gitlab-geo-registry-secret > registry-secrets.yaml
   ```

1. `kubectl` 컨텍스트를 세컨더리의 컨텍스트로 변경하세요.
1. 이러한 비밀을 적용하세요:

   ```shell
   kubectl --namespace gitlab apply -f ssh-host-keys.yaml
   kubectl --namespace gitlab apply -f rails-secrets.yaml
   kubectl --namespace gitlab apply -f registry-secrets.yaml
   ```

다음으로 데이터베이스 암호를 포함하는 비밀을 만듭니다. 아래의 암호를 적절한 값으로 교체하세요:

```shell
kubectl --namespace gitlab create secret generic geo \
   --from-literal=postgresql-password=gitlab_user_password \
   --from-literal=geo-postgresql-password=gitlab_geo_user_password
```

## Geo 세컨더리 사이트로 차트 배포 {#deploy-chart-as-geo-secondary-site}

_이 섹션은 세컨더리 사이트의 Kubernetes 클러스터에서 수행됩니다._

이 차트를 Geo 세컨더리 사이트로 배포하려면 [이 예제 구성에서 시작](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/secondary.yaml)하세요.

1. `secondary.yaml` 파일을 [예제 구성](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/geo/secondary.yaml)에 기반하여 만들고 구성을 업데이트하여 올바른 값을 반영하세요:

   ```yaml
   ## Geo Secondary
   global:
     # See docs.gitlab.com/charts/charts/globals
     # Configure host & domain
     hosts:
       domain: shanghai.example.com
       # use a unified URL (same external URL as the primary site)
       gitlab:
         name: gitlab.example.com
     # configure DB connection
     psql:
       host: geo-2.db.example.com
       port: 5432
       password:
         secret: geo
         key: postgresql-password
     # configure geo (secondary)
     geo:
       enabled: true
       role: secondary
       nodeName: Shanghai Office
       psql:
         host: geo-2.db.example.com
         port: 5431
         password:
           secret: geo
           key: geo-postgresql-password
   ```

   <!-- markdownlint-disable MD044 -->
   - [`global.hosts.domain`](../../charts/globals.md#configure-host-settings)
   - [`global.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - [`global.geo.psql.host`](../../charts/globals.md#configure-postgresql-settings)
   - `global.geo.nodeName`은(는) [관리 영역의 Geo 사이트의 Name 필드](https://docs.gitlab.com/administration/geo_sites/#common-settings)와 일치해야 합니다
   - 선택적으로 `nginx-ingress-geo.enabled`을(를) 설정하여 내부 Geo 트래픽에 대해 사전 구성된 ingress 컨트롤러를 활성화하세요. [이렇게 하면 사이트를 프라이머리로 승격하기가 더 쉬워집니다.](../../charts/nginx/_index.md#gitlab-geo).
   - 다음과 같은 추가 설정도 구성하세요:
     - [SSL/TLS 구성](../../installation/tools.md#tls-certificates)
     - [외부 Redis 사용](../external-redis/_index.md)
     - [외부 객체 저장소 사용](../external-object-storage/_index.md)
   - 외부 데이터베이스의 경우, `global.psql.host`은(는) 세컨더리 읽기 전용 복제 데이터베이스이고, `global.geo.psql.host`은(는) Geo 추적 데이터베이스입니다
   <!-- markdownlint-enable MD044 -->

1. `secondary.yaml`에 필요한 Ingress 또는 Gateway API 구성을 추가하세요.

   {{< tabs >}}

   {{< tab title="NGINX Ingress" >}}

   선택적으로 추가 NGINX 컨트롤러를 활성화하고 내부 Geo 트래픽을 위해 추가 webservice Ingress를 구성하세요:

   ```yaml
   # Optional for secondary sites: Configure Geo Nginx Controller for internal Geo site traffic.
   # nginx-ingress-geo:
   #   enabled: true
   gitlab:
     webservice:
       # Configure an Ingress for internal Geo traffic
       extraIngress:
         enabled: true
         hostname: shanghai.gitlab.example.com
         useGeoClass: false # Set to true if Geo NGINX Ingress is enabled.
   ```

   {{< /tab >}}

   {{< tab title="Envoy Gateway" >}}

   NGINX Ingress 기반 접근 방식의 대안으로, [Gateway API를 구성](../../charts/globals.md#gateway-api) 하고 번들된 [Envoy Gateway](../../charts/envoygateway/_index.md)를 노출하여 Geo를 노출할 수 있습니다.

   Gateway API를 활성화한 후 내부 Geo 트래픽을 위한 호스트명을 구성하세요:

   ```yaml
   global:
     geo:
       gatewayApi:
         additionalHostname: shanghai.gitlab.example.com
   ```

   {{< /tab >}}

   {{< /tabs >}}

1. 이 구성을 사용하여 차트를 배포하세요:

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f secondary.yaml
   ```

1. 배포가 완료되고 애플리케이션이 온라인 상태가 될 때까지 기다리세요.

## 프라이머리를 통해 세컨더리 Geo 사이트 추가 {#add-secondary-geo-site-via-primary}

이제 두 데이터베이스가 구성되고 애플리케이션이 배포되었으므로 프라이머리 사이트가 세컨더리 사이트가 존재한다는 것을 알아야 합니다:

1. **프라이머리** 사이트를 방문하세요.
1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
1. 왼쪽 사이드바에서 **Geo > 사이트 추가**를 선택하세요.
1. **세컨더리** 사이트를 추가하세요. URL에 대해 전체 GitLab URL을 사용하세요.
1. 세컨더리 사이트의 `global.geo.nodeName`로 Name을 입력하세요. 이 값들은 정확히 일치해야 하며, 문자별로 일치해야 합니다.
1. 내부 URL을 입력하세요. 예: `https://shanghai.gitlab.example.com`.
1. 선택적으로 **세컨더리** 사이트에서 복제할 그룹 또는 저장소 샤드를 선택하세요. 모두 복제하려면 공백으로 두세요.
1. **Add node**를 선택하세요.

**세컨더리** 사이트가 관리 패널에 추가된 후, **프라이머리** 사이트에서 누락된 데이터 복제를 자동으로 시작합니다. 이 프로세스를 "백필"이라고 합니다. 한편, **프라이머리** 사이트는 **세컨더리** 사이트에 변경 사항을 알려주기 시작하므로 **세컨더리** 사이트가 해당 변경 사항을 신속하게 복제할 수 있습니다.

## 운영 상태 확인 {#confirm-operational-status}

마지막 단계는 Toolbox Pod를 통해 완전히 구성된 세컨더리 사이트의 Geo 구성을 다시 확인하는 것입니다.

1. Toolbox Pod 찾기:

   ```shell
   kubectl --namespace gitlab get pods -lapp=toolbox
   ```

1. `kubectl exec`를 사용하여 Pod에 연결하세요:

   ```shell
   kubectl --namespace gitlab exec -ti gitlab-geo-toolbox-XXX -- bash -l
   ```

1. Geo 구성의 상태를 확인하세요:

   ```shell
   gitlab-rake gitlab:geo:check
   ```

   아래와 유사한 출력이 표시되어야 합니다:

   ```plaintext
   WARNING: This version of GitLab depends on gitlab-shell 10.2.0, but you're running Unknown. Please update gitlab-shell.
   Checking Geo ...

   GitLab Geo is available ... yes
   GitLab Geo is enabled ... yes
   GitLab Geo secondary database is correctly configured ... yes
   Database replication enabled? ... yes
   Database replication working? ... yes
   GitLab Geo HTTP(S) connectivity ...
   * Can connect to the primary node ... yes
   HTTP/HTTPS repository cloning is enabled ... yes
   Machine clock is synchronized ... Exception: getaddrinfo: Servname not supported for ai_socktype
   Git user has default SSH configuration? ... yes
   OpenSSH configured to use AuthorizedKeysCommand ... no
     Reason:
     Cannot find OpenSSH configuration file at: /assets/sshd_config
     Try fixing it:
     If you are not using our official docker containers,
     make sure you have OpenSSH server installed and configured correctly on this system
     For more information see:
     doc/administration/operations/fast_ssh_key_lookup.md
   GitLab configured to disable writing to authorized_keys file ... yes
   GitLab configured to store new projects in hashed storage? ... yes
   All projects are in hashed storage? ... yes

   Checking Geo ... Finished
   ```

   - `Exception: getaddrinfo: Servname not supported for ai_socktype`에 대해 걱정하지 마세요. Kubernetes 컨테이너는 호스트 시계에 접근할 수 없습니다. _이것은 괜찮습니다_.
   - `OpenSSH configured to use AuthorizedKeysCommand ... no` _예상됩니다_. 이 Rake 작업은 로컬 SSH 서버를 확인하고 있으며, 이는 실제로 다른 곳에 배포된 `gitlab-shell` 차트에 있으며 이미 적절히 구성되어 있습니다.

## 세컨더리 사이트를 위한 별도의 URL 구성(선택사항) {#configure-a-separate-url-for-the-secondary-site-optional}

프라이머리 및 세컨더리 사이트에 대한 단일 통합 URL은 일반적으로 사용자에게 더 편합니다. 예를 들어 다음을 수행할 수 있습니다:

- 두 사이트를 로드 밸런서 뒤에 배치하세요.
- 클라우드 공급자의 DNS 기능을 사용하여 사용자를 가장 가까운 사이트로 라우팅하세요.

경우에 따라 사용자가 방문할 사이트를 제어할 수 있도록 하려고 할 수 있습니다. 이 목적을 위해 세컨더리 Geo 사이트를 고유한 외부 URL을 사용하도록 구성할 수 있습니다. 예를 들면:

- 프라이머리 클러스터의 외부 URL: `https://gitlab.example.com`
- 세컨더리 클러스터의 외부 URL: `https://shanghai.gitlab.example.com`

1. `secondary.yaml`을(를) 편집하고 `webservice` 차트가 해당 요청을 처리할 수 있도록 세컨더리 클러스터의 외부 URL을 업데이트하세요:

   ```yaml
   global:
     # See docs.gitlab.com/charts/charts/globals
     # Configure host & domain
     hosts:
       domain: example.com
       # use a unique external URL for the secondary site
       gitlab:
         name: shanghai.gitlab.example.com
   ```

1. GitLab에서 세컨더리 사이트의 외부 URL을 업데이트하여 필요한 곳에서 URL을 사용할 수 있도록 하세요:
   - 관리 UI 사용:
     1. **프라이머리** 사이트를 방문하세요.
     1. 오른쪽 위 모서리에서 **운영자**를 선택하세요.
     1. **Geo > 사이트**를 선택하세요.
     1. 연필 아이콘을 선택하여 **Edit the secondary site**하세요.
     1. 외부 URL을 편집하세요. 예: `https://shanghai.gitlab.example.com`.
     1. **변경사항 저장**을 선택하세요.

1. 세컨더리 사이트의 차트를 다시 배포하세요:

   ```shell
   helm upgrade --install gitlab-geo gitlab/gitlab --namespace gitlab -f secondary.yaml
   ```

1. 배포가 완료되고 애플리케이션이 온라인 상태가 될 때까지 기다리세요.

## 레지스트리 {#registry}

세컨더리 레지스트리를 프라이머리 레지스트리와 동기화하려면 [레지스트리 복제](https://docs.gitlab.com/administration/geo/replication/container_registry/#configure-container-registry-replication) 를 구성하고 [알림 비밀](../../charts/registry/_index.md#notification-secret)을(를) 사용할 수 있습니다.

## Cert-manager 및 통합 URL {#cert-manager-and-unified-url}

Geo의 통합 URL은 종종 지리 위치 인식 라우팅(예: Amazon Route 53 또는 Google Cloud DNS 사용)과 함께 사용되며, 도메인 이름이 사용자의 제어 하에 있음을 확인하기 위해 [HTTP01 도전](https://letsencrypt.org/docs/challenge-types/#http-01-challenge)이 사용되는 경우 문제가 발생할 수 있습니다.

Geo 사이트를 위해 인증서를 요청하면 Let's Encrypt는 DNS 이름을 요청하는 Geo 사이트로 확인해야 합니다. DNS가 다른 Geo 사이트로 확인되면 통합 URL에 대한 인증서가 발급되거나 갱신되지 않습니다.

cert-manager를 사용하여 인증서를 안정적으로 만들고 갱신하려면 [챌린지 네임서버 설정](https://cert-manager.io/docs/configuration/acme/http01/#setting-nameservers-for-http-01-solver-propagation-checks) 을 통합 호스트명을 Geo 사이트 IP 주소로 확인하는 것으로 알려진 서버로 설정하거나 [DNS01](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge) [발급자](https://cert-manager.io/docs/configuration/acme/dns01/)를 구성하세요.
