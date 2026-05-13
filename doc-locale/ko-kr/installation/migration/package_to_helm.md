---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Linux 패키지에서 Helm 차트로 마이그레이션
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

이 가이드는 패키지 기반 GitLab 설치에서 Helm 차트로 마이그레이션하는 데 도움이 됩니다.

## 사전 요구사항 {#prerequisites}

마이그레이션 전에 몇 가지 사전 요구사항을 충족해야 합니다:

- 패키지 기반 GitLab 인스턴스가 실행 중이어야 합니다. `gitlab-ctl status`을 실행하고 서비스에서 `down` 상태를 보고하지 않는지 확인합니다.
- 마이그레이션 전에 Git 저장소의 [무결성을 확인](https://docs.gitlab.com/administration/raketasks/check/)하는 것이 좋습니다.
- 패키지 기반 설치와 동일한 GitLab 버전을 실행하는 Helm 차트 기반 배포가 필요합니다.
- 번들 MinIO 차트는 프로덕션 준비가 완료되지 않았습니다. 프로덕션 급 배포를 구성하려면 [참조 아키텍처](https://docs.gitlab.com/administration/reference_architectures/)를 확인하세요. 번들된 MinIO에서 마이그레이션하려면 [마이그레이션 가이드](bundled_chart_migration.md)를 확인하세요.
- GitLab Helm 차트를 배포하기 전에 PostgreSQL과 Redis를 외부 서비스로 구성해야 합니다. [외부 데이터베이스](../../advanced/external-db/_index.md) 및 [외부 Redis](../../advanced/external-redis/_index.md)를 참조하세요.

## 마이그레이션 단계 {#migration-steps}

1. 패키지 기반 설치에서 오브젝트 스토리지로 기존 데이터 마이그레이션:

   1. [오브젝트 스토리지로 마이그레이션](https://docs.gitlab.com/administration/object_storage/#migrate-to-object-storage)합니다.

   1. 패키지 기반 GitLab 인스턴스를 방문하여 마이그레이션된 데이터를 사용할 수 있는지 확인합니다. 예를 들어 사용자, 그룹 및 프로젝트 아바타가 제대로 렌더링되고, 이슈에 추가된 이미지 및 기타 파일이 올바르게 로드되는지 확인합니다.

1. [백업 tarball 생성](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/) 및 [이미 마이그레이션된 모든 디렉토리 제외](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#excluding-specific-directories-from-the-backup)합니다.

   로컬 백업(기본값)의 경우 백업 파일은 `/var/opt/gitlab/backups`에 저장되며, [위치를 명시적으로 변경](https://docs.gitlab.com/omnibus/settings/backups/#manually-manage-backup-directory)하지 않는 한 그렇습니다. [원격 스토리지 백업](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#upload-backups-to-a-remote-cloud-storage)의 경우 백업 파일이 구성된 버킷에 저장됩니다.
1. 패키지 기반 설치에서 [복원](../../backup-restore/restore.md)을 시작으로 Helm 차트로 복원합니다. `/etc/gitlab/gitlab-secrets.json`의 값을 Helm에서 사용할 YAML 파일로 마이그레이션해야 합니다.
1. 변경 사항이 적용되도록 모든 Pod를 다시 시작합니다:

   ```shell
   kubectl delete pods -lrelease=<helm release name>
   ```

1. Helm 기반 배포를 방문하고 패키지 기반 설치에 존재했던 프로젝트, 그룹, 사용자, 이슈 등이 복원되었는지 확인합니다. 또한 업로드된 파일(아바타, 이슈에 업로드된 파일 등)이 제대로 로드되는지 확인하세요.
