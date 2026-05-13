---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 데이터베이스로 GitLab 차트 구성하기
---

외부 PostgreSQL 인스턴스로 GitLab Helm 차트를 구성합니다. 이는 모든 배포에 필요합니다.

전제 조건:

- [필수 버전의 PostgreSQL](https://docs.gitlab.com/install/requirements/#postgresql) 배포 설치하지 않았다면 [AWS RDS PostgreSQL](https://aws.amazon.com/rds/postgresql/) 또는 [GCP Cloud SQL](https://cloud.google.com/sql/)과 같은 클라우드 제공 솔루션을 고려하세요. 대체 솔루션으로 [Linux 패키지](external-omnibus-psql.md)를 고려하세요.
- 기본적으로 `gitlabhq_production`이라는 이름의 빈 데이터베이스
- 데이터베이스에 대한 전체 액세스 권한이 있는 사용자 자세한 내용은 [외부 데이터베이스 설명서](https://docs.gitlab.com/administration/postgresql/external/)를 참조하세요.
- 데이터베이스 사용자의 암호가 포함된 [Kubernetes Secret](https://kubernetes.io/docs/concepts/configuration/secret/)
- [`amcheck`, `pg_trgm` 및 `btree_gist` 확장](https://docs.gitlab.com/install/postgresql_extensions/) GitLab에 Superuser 플래그가 있는 계정을 제공하지 않으면 데이터베이스 설치를 진행하기 전에 이러한 확장이 로드되어 있는지 확인하세요.

네트워킹 필수 요구 사항:

- 클러스터에서 데이터베이스에 도달할 수 있는지 확인하세요. 방화벽 정책이 트래픽을 허용하는지 확인하세요.
- PostgreSQL을 로드 밸런싱 클러스터로 사용하고 Kubernetes DNS를 서비스 검색에 사용할 계획이라면 PostgreSQL 보조 서비스를 헤드리스 서비스로 구성하여 각 보조 인스턴스에 대해 DNS `A` 레코드가 생성되도록 허용하세요. 예제는 [`examples/database/values-loadbalancing-discover.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/database/values-loadbalancing-discover.yaml)를 참조하세요.

외부 데이터베이스를 사용하도록 GitLab 차트를 구성하려면:

1. 다음 매개 변수를 설정하세요:

   - `global.psql.host`: 외부 데이터베이스의 호스트 이름으로 설정합니다. 도메인 또는 IP 주소일 수 있습니다.
   - `global.psql.password.secret`: [`gitlab` 사용자에 대한 데이터베이스 암호가 포함된 시크릿](../../installation/secrets.md#postgresql-password)의 이름.
   - `global.psql.password.key`: 시크릿 내에서 암호가 포함된 키입니다.

1. 선택 사항입니다. 기본값을 사용하지 않는 경우 다음 항목을 추가로 사용자 정의할 수 있습니다:

   - `global.psql.port`: 데이터베이스를 사용할 수 있는 포트입니다. `5432`로 기본값이 설정됩니다.
   - `global.psql.database`: 데이터베이스의 이름입니다.
   - `global.psql.username`: 데이터베이스에 대한 액세스 권한이 있는 사용자입니다.

1. 선택 사항입니다. 데이터베이스에 대한 상호 TLS 연결을 사용하는 경우 다음을 설정하세요:

   - `global.psql.ssl.secret`: 클라이언트 인증서, 키 및 인증서 기관이 포함된 시크릿입니다.
   - `global.psql.ssl.serverCA`: 시크릿 내에서 인증서 기관(CA)을 나타내는 키입니다.
   - `global.psql.ssl.clientCertificate`: 시크릿 내에서 클라이언트 인증서를 나타내는 키입니다.
   - `global.psql.ssl.clientKey`: 시크릿의 클라이언트입니다.

1. GitLab 차트를 배포할 때 `--set` 플래그를 사용하여 값을 추가하세요. 예를 들어:

   ```shell
   helm install gitlab gitlab/gitlab
     --set global.psql.host=psql.example
     --set global.psql.password.secret=gitlab-postgresql-password
     --set global.psql.password.key=postgres-password
   ```
