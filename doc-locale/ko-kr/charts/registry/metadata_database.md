---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 컨테이너 레지스트리 메타데이터 데이터베이스
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제품:  GitLab Self-Managed

{{< /details >}}

{{< history >}}

- [도입됨](https://gitlab.com/groups/gitlab-org/-/epics/5521) GitLab 16.4에서 [베타](https://docs.gitlab.com/policy/development_stages_support/#beta) 기능으로.
- [일반 공급](https://gitlab.com/gitlab-org/gitlab/-/issues/423459) GitLab 17.3에서 시작.

{{< /history >}}

메타데이터 데이터베이스는 온라인 가비지 수집을 포함한 많은 새로운 레지스트리 기능을 제공하며 많은 레지스트리 작업의 효율성을 높입니다.

기존 레지스트리가 있는 경우 메타데이터 데이터베이스로 마이그레이션할 수 있습니다.

일부 데이터베이스 활성화 기능은 GitLab.com에서만 활성화되며 레지스트리 데이터베이스에 대한 자동 데이터베이스 프로비저닝은 사용할 수 없습니다. [관리 문서](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#metadata-database-feature-support)의 기능 지원 섹션을 검토하여 컨테이너 레지스트리 데이터베이스와 관련된 기능의 상태를 확인하세요.

## 외부 메타데이터 데이터베이스 생성 {#create-an-external-metadata-database}

프로덕션에서는 외부 메타데이터 데이터베이스를 생성해야 합니다.

필수 조건:

- [외부 PostgreSQL 서버](../../advanced/external-db/_index.md)를 설정하세요.

외부 PostgreSQL 서버를 설정한 후:

1. 메타데이터 데이터베이스 암호의 비밀을 생성하세요:

   ```shell
   kubectl create secret generic RELEASE_NAME-registry-database-password --from-literal=password=<your_registry_password>
   ```

1. 데이터베이스 서버에 로그인하세요.
1. 다음 SQL 명령을 사용하여 사용자 및 데이터베이스를 생성하세요:

   ```sql
   -- Create the registry user
   CREATE USER registry WITH PASSWORD '<your_registry_password>';

   -- Create the registry database
   CREATE DATABASE registry OWNER registry;
   ```

1. 클라우드 관리형 서비스의 경우 필요에 따라 추가 역할을 부여하세요:

   {{< tabs >}}

   {{< tab title="Amazon RDS" >}}

   ```sql
   GRANT rds_superuser TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Azure database" >}}

   ```sql
   GRANT azure_pg_admin TO registry;
   ```

   {{< /tab >}}

   {{< tab title="Google Cloud SQL" >}}

   ```sql
   GRANT cloudsqlsuperuser TO registry;
   ```

   {{< /tab >}}

   {{< /tabs >}}

## 기본 제공 메타데이터 데이터베이스 생성 {#create-a-built-in-metadata-database}

> [!warning] 기본 제공 클라우드 네이티브 메타데이터 데이터베이스는 평가판 용도로만 사용할 수 있습니다. 프로덕션에서는 사용하지 마세요.

## 메타데이터 데이터베이스 활성화 {#enable-the-metadata-database}

데이터베이스를 생성한 후 활성화하세요. 기존 컨테이너 레지스트리를 마이그레이션할 때 추가 단계가 필요합니다.

### 필수 조건 {#prerequisites}

필수 조건:

- GitLab 17.3 이상.
- [필수 PostgreSQL 버전](https://docs.gitlab.com/install/requirements/#postgresql)의 배포로 레지스트리 팟(Pod)에서 액세스 가능해야 합니다.
- Kubernetes 클러스터 및 Helm 배포에 대한 로컬 액세스.
- 레지스트리 팟(Pod)에 대한 SSH 액세스.

또한 Registry 관리 가이드의 [시작하기 전에](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#before-you-start) 섹션을 읽으세요.

> [!note] 다양한 테스트 및 사용자 레지스트리에 대한 가져오기 시간 목록은 [문제 423459의 이 테이블](https://gitlab.com/gitlab-org/gitlab/-/issues/423459#completed-tests-and-user-reports)을 참조하세요. 레지스트리 배포는 고유하며 가져오기 시간이 문제에서 보고된 것보다 길 수 있습니다.

### 새 레지스트리에 대해 활성화 {#enable-for-new-registries}

새 컨테이너 레지스트리에 대해 데이터베이스를 활성화하려면:

1. 릴리스의 현재 Helm 값을 가져와 파일에 저장하세요. 예를 들어 `gitlab`이라는 릴리스와 `values.yml`이라는 파일의 경우:

   ```shell
   helm get values gitlab > values.yml
   ```

1. `values.yml` 파일에 다음 줄을 추가하세요:

   ```yaml
   registry:
     enabled: true
     database:
       enabled: true
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full
       # these settings are inherited from `global.psql.ssl`
       ssl:
         secret: gitlab-registry-postgresql-ssl # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. 선택 사항. 스키마 마이그레이션이 제대로 적용되었는지 확인하세요. 다음 중 하나를 수행할 수 있습니다:

   - 마이그레이션 작업의 로그 출력을 검토하세요. 예를 들면:

     ```shell
     kubectl logs jobs/gitlab-registry-migrations-1
     ...
     OK: applied 154 migrations in 13.752s
     ```

   - 또는 Postgres 데이터베이스에 연결하고 `schema_migrations` 테이블을 쿼리하세요:

     ```sql
     SELECT * FROM schema_migrations;
     ```

     `applied_at` 열 타임스탬프가 모든 행에 대해 채워져 있는지 확인하세요.

레지스트리가 메타데이터 데이터베이스를 사용할 준비가 되었습니다!

### 기존 레지스트리 활성화 및 가져오기 {#enable-for-and-import-existing-registries}

기존 컨테이너 레지스트리 데이터를 한 단계 또는 세 단계로 가져올 수 있습니다. 마이그레이션 기간에 영향을 미치는 여러 가지 요소가 있습니다:

- 기존 레지스트리 데이터의 크기.
- PostgreSQL 인스턴스의 사양.
- 클러스터에서 실행 중인 레지스트리 팟(Pod)의 개수.
- 레지스트리, PostgreSQL 및 구성된 Object Storage 간의 네트워크 지연.

> [!note] 가져오기 프로세스를 자동화하는 작업은 [문제 5293](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/5293)에서 추적 중입니다.

한 단계 또는 세 단계 가져오기를 시도하기 전에 릴리스의 현재 Helm 값을 가져와 파일로 저장하세요. 예를 들어 `gitlab`이라는 릴리스와 `values.yml`이라는 파일의 경우:

```shell
helm get values gitlab > values.yml
```

#### 한 단계로 가져오기 {#import-in-one-step}

한 단계 가져오기를 수행할 때 다음을 주의하세요:

- 가져오기 중에 레지스트리는 `read-only` 모드로 유지되어야 합니다.
- 가져오기가 실행 중인 팟(Pod)이 종료된 경우 처음부터 다시 시작하지 않고도 가져오기를 재개할 수 있습니다. [중단된 가져오기 재개](#resume-interrupted-imports)를 참조하세요.

기존 컨테이너 레지스트리를 메타데이터 데이터베이스로 한 단계로 가져오려면:

1. `registry:` 섹션을 `values.yml` 파일에서 찾고 `database` 섹션을 추가하세요. 설정:
   - `database.configure`을 `true`로 설정하세요.
   - `database.enabled`을 `false`로 설정하세요.
   - `maintenance.readonly.enabled`을 `true`로 설정하세요.
   - `migrations.enabled`을 `true`로 설정하세요.

   ```yaml
   registry:
     enabled: true
     maintenance:
       readonly:
         enabled: true  # must remain set to true while the migration is executed
     database:
       configure: true  # must be true for the migration step
       enabled: false  # must be false!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. Helm 설치를 업그레이드하여 배포의 변경 사항을 적용하세요:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. 예를 들어 `gitlab-registry-5ddcd9f486-bvb57`이라는 팟(Pod)에 대해 SSH를 통해 레지스트리 팟(Pod) 중 하나에 연결하세요:

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. 홈 디렉터리로 변경한 후 다음 명령을 실행하세요:

   ```shell
   cd ~
   /usr/bin/registry database import /etc/docker/registry/config.yml
   ```

1. 명령이 성공적으로 완료되면 모든 이미지가 완전히 가져워집니다. 이제 데이터베이스를 활성화하고 구성에서 읽기 전용 모드를 끌 수 있습니다:

   ```yaml
   registry:
     enabled: true
     maintenance:
       readonly:
         enabled: false
     database:
       configure: true  # once database.enabled is set to true, this option can be removed
       enabled: true
       name: registry
       user: registry
       password:
         secret: gitlab-registry-database-password
         key: password
       migrations:
         enabled: true
   ```

1. Helm 설치를 업그레이드하여 배포의 변경 사항을 적용하세요:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

이제 모든 작업에 메타데이터 데이터베이스를 사용할 수 있습니다!

#### 세 단계로 가져오기 {#import-in-three-steps}

기존 컨테이너 레지스트리 데이터를 세 가지 별도 단계로 메타데이터 데이터베이스로 가져올 수 있으며, 다음 경우에 권장됩니다:

- 레지스트리에 많은 양의 데이터가 포함되어 있습니다.
- 마이그레이션 중 다운타임을 최소화해야 합니다.

세 단계로 가져오려면 다음을 수행해야 합니다:

1. 저장소 사전 가져오기
1. 모든 저장소 데이터 가져오기
1. 일반 BLOB 가져오기

> [!note] 사용자는 1단계 가져오기가 [시간당 2~4TB의 속도](https://gitlab.com/gitlab-org/gitlab/-/issues/423459)로 완료되었다고 보고했습니다. 더 느린 속도로 100TB 이상의 데이터가 있는 레지스트리는 48시간 이상이 소요될 수 있습니다.

##### 단계 1. 저장소 사전 가져오기 {#step-1-pre-import-repositories}

더 큰 인스턴스의 경우 이 프로세스는 레지스트리 크기에 따라 몇 시간 또는 심지어 며칠이 걸릴 수 있습니다. 이 프로세스 중에 레지스트리를 계속 사용할 수 있습니다.

> [!note] 가져오기가 중단되면 처음부터 다시 시작하지 않고도 재개할 수 있습니다. [중단된 가져오기 재개](#resume-interrupted-imports)를 참조하세요.

1. `registry:` 섹션을 `values.yml` 파일에서 찾고 `database` 섹션을 추가하세요. 설정:
   - `database.configure`을 `true`로 설정하세요.
   - `database.enabled`을 `false`로 설정하세요.
   - `migrations.enabled`을 `true`로 설정하세요.

   ```yaml
   registry:
     enabled: true
     database:
       configure: true
       enabled: false  # must be false!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. 파일을 저장하고 Helm 설치를 업그레이드하여 배포의 변경 사항을 적용하세요:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. SSH를 사용하여 레지스트리 팟(Pod) 중 하나에 연결하세요. 예를 들어 `gitlab-registry-5ddcd9f486-bvb57`이라는 팟(Pod)의 경우:

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. 홈 디렉터리로 변경한 후 다음 명령을 실행하세요:

   ```shell
   cd ~
   /usr/bin/registry database import --step-one /etc/docker/registry/config.yml
   ```

1단계는 `registry import complete`이 표시될 때 완료됩니다.

> [!note] 다음 단계를 가능한 한 빨리 예약하여 필요한 다운타임의 양을 줄이는 것이 좋습니다. 이상적으로 1단계가 완료된 후 1주일 미만. 다음 단계 전에 레지스트리에 기록된 새 데이터로 인해 해당 단계가 더 오래 걸립니다.

##### 단계 2. 모든 저장소 데이터 가져오기 {#step-2-import-all-repository-data}

이 단계에서는 레지스트리를 `read-only` 모드로 설정해야 합니다. 이 프로세스 중에 충분한 다운타임을 허용하세요.

1. `values.yml` 파일에서 레지스트리를 `read-only` 모드로 설정하세요:

   ```yaml
   registry:
     enabled: true
     maintenance:
       readonly:
         enabled: true   # must be true!
     database:
       configure: true
       enabled: false  # must be false!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. 파일을 저장하고 Helm 설치를 업그레이드하여 배포의 변경 사항을 적용하세요:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

1. SSH를 사용하여 레지스트리 팟(Pod) 중 하나에 연결하세요. 예를 들어 `gitlab-registry-5ddcd9f486-bvb57`이라는 팟(Pod)의 경우:

   ```shell
   kubectl exec -ti gitlab-registry-5ddcd9f486-bvb57 bash
   ```

1. 홈 디렉터리로 변경한 후 다음 명령을 실행하세요:

   ```shell
   cd ~
   /usr/bin/registry database import --step-two /etc/docker/registry/config.yml
   ```

1. 명령이 성공적으로 완료되면 모든 이미지가 완전히 가져워집니다. 이제 데이터베이스를 활성화하고 구성에서 읽기 전용 모드를 끌 수 있습니다:

   ```yaml
   registry:
     enabled: true
     maintenance:        # this section can be removed
       readonly:
         enabled: false
     database:
       configure: true  # once database.enabled is set to true, this option can be removed
       enabled: true   # must be true!
       name: registry  # must match the database name you created above
       user: registry  # must match the database username you created above
       password:
         secret: gitlab-registry-database-password  # must match the secret name
         key: password  # must match the secret key to read the password from
       sslmode: verify-full  # SSL connection mode. See https://www.postgresql.org/docs/current/libpq-ssl.html#LIBPQ-SSL-PROTECTION for more options.
       ssl:
         secret: gitlab-registry-postgresql-ssl  # you will need to create this secret manually
         clientKey: client-key.pem
         clientCertificate: client-cert.pem
         serverCA: server-ca.pem
       migrations:
         enabled: true  # this option will execute the schema migration as part of the registry deployment
   ```

1. 파일을 저장하고 Helm 설치를 업그레이드하여 배포의 변경 사항을 적용하세요:

   ```shell
   helm upgrade gitlab gitlab/gitlab -f values.yml
   ```

이제 모든 작업에 메타데이터 데이터베이스를 사용할 수 있습니다!

##### 단계 3. 일반 BLOB 가져오기 {#step-3-import-common-blobs}

레지스트리는 현재 메타데이터에 대해 데이터베이스를 완전히 사용하고 있지만 잠재적으로 사용되지 않은 레이어 BLOB에 액세스할 수 없습니다.

프로세스를 완료하려면 마이그레이션의 최종 단계를 실행하세요:

```shell
cd ~
/usr/bin/registry database import --step-three /etc/docker/registry/config.yml
```

명령이 성공적으로 완료된 후 레지스트리는 이제 데이터베이스로 완전히 마이그레이션되었습니다!

#### 중단된 가져오기 재개 {#resume-interrupted-imports}

{{< history >}}

- [도입됨](https://gitlab.com/gitlab-org/container-registry/-/issues/1162) GitLab 18.5에서.

{{< /history >}}

가져오기가 중단되면 가져오기 명령을 다시 실행하면 지난 72시간 동안 사전 가져운 저장소가 자동으로 건너뜁니다. `--pre-import-skip-recent` 플래그는 이 기간을 제어합니다.

건너뛰기 기간을 사용자 정의하려면 가져오기 명령에 `--pre-import-skip-recent`을(를) 추가하세요((`--step-one`, `--step-two`, `--step-three`, 또는 한 단계 가져오기를 포함한 모든 가져오기 변형 작동):

- 지난 6시간 동안 가져운 저장소 건너뛰기:

  ```shell
  /usr/bin/registry database import --pre-import-skip-recent 6h /etc/docker/registry/config.yml
  ```

- 건너뛰기 비활성화(모든 것을 다시 가져오기):

  ```shell
  /usr/bin/registry database import --pre-import-skip-recent 0 /etc/docker/registry/config.yml
  ```

유효한 기간 단위는 [Go 기간 문자열](https://pkg.go.dev/time#ParseDuration)을(를) 참조하세요.

## 백업 및 복원 {#backup-and-restore}

레지스트리 메타데이터 데이터베이스를 Toolbox 백업 및 복원 작업에 포함하려면 레지스트리 데이터베이스 자격증명으로 Toolbox 차트를 구성하세요. Toolbox 차트 문서의 [레지스트리 메타데이터 데이터베이스 자격증명](../gitlab/toolbox/_index.md#registry-metadata-database-credentials) 섹션을 참조하세요.

## 데이터베이스 마이그레이션 {#database-migrations}

컨테이너 레지스트리는 두 가지 유형의 마이그레이션을 지원합니다:

- **Regular schema migrations**:  새 애플리케이션 코드를 배포하기 전에 실행해야 하는 데이터베이스 구조의 변경. 이러한 항목은 배포 지연을 피하기 위해 빨라야 합니다.
- **Post-deployment migrations**:  애플리케이션이 실행 중인 동안 실행할 수 있는 데이터베이스 구조의 변경. 큰 테이블에 인덱스를 생성하는 것과 같은 더 긴 작업에 사용되며 시작 지연 및 확장된 업그레이드 다운타임을 피합니다.

### 데이터베이스 마이그레이션 적용 {#apply-database-migrations}

기본적으로 `database.migrations.enabled`이(가) `true`로 설정된 경우 레지스트리 차트는 일반 스키마 및 배포 후 마이그레이션을 자동으로 적용합니다.

업그레이드 중 다운타임을 줄이려면 배포 후 마이그레이션을 건너뛰고 애플리케이션 시작 후 수동으로 적용할 수 있습니다:

1. `SKIP_POST_DEPLOYMENT_MIGRATIONS` 환경 변수를 `ExtraEnv`을(를) 사용하여 레지스트리 배포에 대해 `true`로 설정하세요:

   ```yaml
   registry:
     extraEnv:
       SKIP_POST_DEPLOYMENT_MIGRATIONS: true
   ```

1. 업그레이드 후 [레지스트리 팟(Pod)에 연결](_index.md#running-administrative-commands-against-the-container-registry)하세요.
1. 보류 중인 배포 후 마이그레이션을 적용하세요:

   ```shell
   registry database migrate up /etc/docker/registry/config.yml
   ```

> [!note] `migrate up` 명령은 마이그레이션 적용 방법을 제어하는 데 사용할 수 있는 몇 가지 추가 플래그를 제공합니다. 자세한 내용은 `registry database migrate up --help`을(를) 실행하세요.

## 문제 해결 {#troubleshooting}

### 오류: `panic: interface conversion: interface {} is nil, not bool` {#error-panic-interface-conversion-interface--is-nil-not-bool}

기존 레지스트리를 가져올 때 이 오류가 표시될 수 있습니다:

```shell
panic: interface conversion: interface {} is nil, not bool
```

이는 레지스트리 버전 `v4.15.2-gitlab`에서 수정되고 GitLab 17.9 이상에서 수정된 알려진 [문제](https://gitlab.com/gitlab-org/container-registry/-/merge_requests/2041)입니다.

이 문제를 해결하려면 레지스트리 버전을 업그레이드하세요:

1. `values.yml` 파일에서 레지스트리 이미지 태그를 설정하세요:

   ```yaml
   registry:
     image:
       tag: v4.15.2-gitlab
   ```

1. Helm 설치를 업그레이드하세요:

   ```shell
   helm upgrade gitlab -f values.yml
   ```

또는 레지스트리 구성을 수동으로 업데이트할 수 있습니다:

- `/etc/docker/registry/config.yml`에서 저장소 공급자에 대해 `parallelwalk`을(를) `false`로 설정하세요. 예를 들어, S3의 경우:

  ```yaml
  storage:
    s3:
      parallelwalk: false
  ```
