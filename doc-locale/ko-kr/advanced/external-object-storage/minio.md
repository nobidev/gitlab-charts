---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트를 사용하여 MinIO 구성
---

[MinIO](https://min.io/)는 S3 호환 API를 제공하는 객체 스토리지 서버입니다.

MinIO는 여러 다른 플랫폼에 배포할 수 있습니다. 새 MinIO 인스턴스를 시작하려면 [빠른 시작 가이드](https://min.io/docs/minio/linux/index.html)를 따르세요. [MinIO 서버에 대한 TLS를 사용한 보안 액세스](https://min.io/docs/minio/linux/operations/network-encryption.html)를 확인하세요.

GitLab을 외부 [MinIO](https://min.io/) 인스턴스에 연결하려면 먼저 GitLab 애플리케이션용 MinIO 버킷을 생성하고 이 [예제 구성 파일](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/values-external-objectstorage.yaml)의 버킷 이름을 사용하세요.

MinIO 클라이언트를 사용하여 사용하기 전에 필요한 버킷을 생성하세요:

```shell
mc mb gitlab-registry-storage
mc mb gitlab-lfs-storage
mc mb gitlab-artifacts-storage
mc mb gitlab-uploads-storage
mc mb gitlab-packages-storage
mc mb gitlab-backup-storage
```

버킷이 생성되면 GitLab을 MinIO 인스턴스를 사용하도록 구성할 수 있습니다. [`rails.minio.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.minio.yaml) 및 [`registry.minio.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.minio.yaml) 의 예제 구성을 [examples](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage) 폴더에서 참조하세요.
