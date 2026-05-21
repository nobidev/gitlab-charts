---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Helm v2에서 Helm v3로 마이그레이션
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

[Helm v2는 공식적으로 지원 중단됨](https://helm.sh/blog/helm-v2-deprecation-timeline/)2020년 11월. GitLab Helm 차트 버전 5.0 (GitLab App 버전 14.0)부터 Helm v2.x를 사용한 설치 및 업그레이드는 더 이상 지원되지 않습니다. 향후 GitLab 업데이트를 받으려면 Helm v3로 마이그레이션해야 합니다.

## Helm v2와 Helm v3 간의 변경 사항 {#changes-between-helm-v2-and-helm-v3}

Helm v3는 Helm v2와 역호환되지 않는 많은 변경 사항을 도입합니다. 주요 변경 사항에는 Tiller 요구 사항 제거 및 클러스터에서 릴리스 정보 저장 방식이 포함됩니다. [Helm v3 변경 사항 개요](https://helm.sh/docs/topics/v2_v3_migration/#overview-of-helm-3-changes) 및 [Helm v2 이후 변경 사항 FAQ](https://helm.sh/docs/faq/changes_since_helm2/)에서 자세히 알아보세요.

애플리케이션을 배포하는 데 사용하는 Helm 차트가 최신/이전 버전의 Helm과 호환되지 않을 수 있습니다. Helm v2로 배포하고 관리하는 여러 애플리케이션이 있다면, Helm v3과 호환되는지 확인해야 하며, 필요한 경우 이들도 변환할 수 있습니다. GitLab Helm 차트는 GitLab Helm 차트 버전 v3.0.0부터 Helm v3.0.2 이상을 지원합니다. Helm v2는 더 이상 지원되지 않습니다.

현재 실행 중인 애플리케이션의 입장에서 Helm v2에서 v3로 마이그레이션을 수행할 때 변경된 사항이 없습니다. 일반적으로 Helm v2에서 v3로의 마이그레이션을 수행하는 것은 매우 안전하지만, 예방 조치로 Helm v2의 백업을 하는 것이 좋습니다.

## Helm v2에서 Helm v3로 마이그레이션하는 방법 {#how-to-migrate-from-helm-v2-to-helm-v3}

[Helm 2to3 플러그인](https://github.com/helm/helm-2to3)을 사용하여 GitLab 릴리스를 Helm v2에서 Helm v3로 마이그레이션할 수 있습니다. 이 마이그레이션 플러그인에 대한 더 자세한 설명과 몇 가지 예시는 Helm 블로그 게시물을 참조하세요:  [Helm v2에서 Helm v3로 마이그레이션하는 방법](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/).

GitLab Helm 설치를 관리하는 여러 사람이 있다면, 각 로컬 머신에서 `helm3 2to3 move config`을(를) 실행해야 할 수도 있습니다. `helm3 2to3 convert`은(는) 한 번만 실행하면 됩니다.

## 알려진 문제 {#known-issues}

### "UPGRADE FAILED: cannot patch" 오류가 마이그레이션 후 표시됨 {#upgrade-failed-cannot-patch-error-is-shown-after-the-migration}

마이그레이션 후 **subsequent upgrades may fail** 다음과 유사한 오류가 발생합니다:

```shell
Error: UPGRADE FAILED: cannot patch "..." with kind Deployment: Deployment.apps "..." is invalid: spec.selector:
Invalid value: v1.LabelSelector{...}: field is immutable
```

또는

```shell
Error: UPGRADE FAILED: cannot patch "..." with kind StatefulSet: StatefulSet.apps "..." is invalid:
spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', and 'updateStrategy' are forbidden
```

이는 [Cert Manager](https://github.com/jetstack/cert-manager/issues/2451) 및 [Redis](https://github.com/bitnami/charts/issues/3482) 종속성에서 Helm 2에서 3으로의 마이그레이션과 관련된 알려진 문제 때문입니다. 간단히 말해서, 일부 배포 및 StatefulSet의 `heritage` 레이블은 변경할 수 없으며 `Tiller`(Helm 2로 설정됨)에서 `Helm`(Helm 3으로 설정됨)로 변경할 수 없습니다. 따라서 강제로 교체해야 합니다.

이 문제를 해결하려면 다음 지침을 사용하세요:

> [!note]
> 이 지침은 특히 Redis StatefulSet 리소스를 강제로 교체합니다. 이 StatefulSet에 연결된 데이터 볼륨이 안전하고 그대로 유지되는지 확인해야 합니다.

1. cert-manager 배포 교체 (활성화된 경우).

```shell
kubectl get deployments -l app=cert-manager -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true -f -
kubectl get deployments -l app=cainjector -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true -f -
```

1. (선택 사항) Redis StatefulSet에 의해 요청되는 PV에서 `persistentVolumeReclaimPolicy`을(를) `Retain`(으)로 설정합니다. 이는 PV가 실수로 삭제되지 않도록 하기 위한 것입니다.

```shell
kubectl patch pv <PV-NAME> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

1. 기존 Redis PVC의 `heritage` 레이블을 `Helm`(으)로 설정합니다.

```shell
kubectl label pvc -l app=redis --overwrite heritage=Helm
```

1. Redis StatefulSet을 **without cascading** 교체합니다.

```shell
kubectl get statefulsets.apps -l app=redis -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true --cascade=false -f -
```

### Helm 업그레이드를 실행할 때 마이그레이션 후 RBAC 문제 {#rbac-issues-after-the-migration-when-running-helm-upgrade}

변환이 완료된 후 Helm 업그레이드를 실행할 때 다음 오류가 발생할 수 있습니다:

```shell
Error: UPGRADE FAILED: pre-upgrade hooks failed: warning: Hook pre-upgrade gitlab/templates/shared-secrets/rbac-config.yaml failed: roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden: user "your-user-name@domain.tld" (groups=["system:authenticated"]) is attempting to grant RBAC permissions not currently held:
{APIGroups:[""], Resources:["secrets"], Verbs:["get" "list" "create" "patch"]}
```

Helm2는 Tiller 서비스 계정을 사용하여 이러한 작업을 수행했습니다. Helm3은 더 이상 Tiller를 사용하지 않으며, 클러스터 관리자로 `helm upgrade`을(를) 실행하더라도 사용자 계정에 명령을 실행할 수 있는 적절한 RBAC 권한이 있어야 합니다. 자신에게 전체 RBAC 권한을 부여하려면 다음을 실행하세요:

```shell
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=your-user-name@domain.tld
```

그 후 `helm upgrade`이(가) 정상 작동합니다.
