---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Helm 차트 제거
---

GitLab Helm 차트를 제거하려면 다음 명령을 실행하세요:

```shell
helm uninstall gitlab
```

연속성을 위해 이러한 차트에는 `helm uninstall`을 수행할 때 제거되지 않는 일부 Kubernetes 객체가 있습니다. 이러한 항목들은 _의도적으로_ 제거해야 하며, 이는 재배포 시 영향을 미칩니다.

- 상태 저장 데이터용 PVC로, _의도적으로_ 제거해야 합니다.
  - Gitaly:  이것은 저장소 데이터입니다.
  - PostgreSQL (내부인 경우):  이것은 메타데이터입니다.
  - Redis (내부인 경우):  이것은 캐시 및 작업 큐이며, 안전하게 제거할 수 있습니다.
- 공유 시크릿 작업으로 생성된 경우의 시크릿입니다. 이러한 차트는 Helm을 통해 직접 Kubernetes 시크릿을 생성하지 않도록 설계되었습니다. 따라서 Helm은 이를 제거할 수 없습니다. 이들은 암호, 암호화 시크릿 등을 포함합니다. 이들은 무분별하게 삭제되어서는 안 됩니다.
- ConfigMaps
  - `ingress-controller-leader-RELEASE-nginx`: 이것은 NGINX Ingress 컨트롤러 자체에서 생성되며, 차트 제어 범위 외에 있습니다. 안전하게 제거할 수 있습니다.

PVC 및 시크릿에는 `release` 레이블이 설정되어 있으므로 다음과 같이 찾을 수 있습니다:

```shell
kubectl get pvc,secret -lrelease=gitlab
```

> [!warning]
> 시크릿 `RELEASE-gitlab-initial-root-password`을 수동으로 삭제하지 않으면 다음 릴리스에서 재사용됩니다. 노출된 방식에 관계없이 이 비밀번호를 수동으로 삭제해야 합니다. 예를 들어 기록된 데모에서입니다. 이는 노출된 비밀번호가 향후 릴리스에서 인스턴스에 로그인하는 데 사용될 수 없음을 보장합니다.
