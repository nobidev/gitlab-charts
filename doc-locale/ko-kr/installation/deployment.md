---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Helm 차트 배포
---

{{< details >}}

- Tier:  Free, Premium, Ultimate
- Offering:  GitLab Self-Managed

{{< /details >}}

`helm install`를 실행하기 전에 GitLab을 어떻게 실행할지에 대해 몇 가지 결정을 내려야 합니다. Helm의 `--set option.name=value` 명령줄 옵션을 사용하여 옵션을 지정할 수 있습니다. 이 가이드는 필수 값과 일반적인 옵션을 다룹니다. 옵션의 전체 목록을 보려면 [설치 명령줄 옵션](command-line-options.md)을 읽으세요.

> [!note]
> GitLab Helm 차트는 프로덕션 배포를 위해 외부 PostgreSQL, Redis 및 객체 저장소가 필요합니다. 이 서비스의 번들 버전은 평가 목적으로만 포함되어 있습니다. 프로덕션의 경우 [Cloud Native Hybrid 참조 아키텍처](_index.md#use-the-reference-architectures)를 따르세요.

프로덕션 배포의 경우 Kubernetes에 대한 강력한 실무 지식이 있어야 합니다. 이 배포 방법은 기존 배포와는 다른 관리, 관찰성 및 개념을 가지고 있습니다.

## Helm을 사용하여 배포 {#deploy-using-helm}

모든 구성 옵션을 수집한 후 모든 종속성을 얻고 Helm을 실행할 수 있습니다. 이 예제에서는 Helm 릴리스를 `gitlab`이라고 명명했습니다.

```shell
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600s \
  --set global.hosts.domain=example.com \
  --set global.hosts.externalIP=10.10.10.10 \
  --set certmanager-issuer.email=me@example.com
```

다음을 참고하세요:

- 모든 Helm 명령은 Helm v3 구문을 사용하여 지정됩니다.
- Helm v3는 `--generate-name` 옵션을 사용하지 않으면 명령줄에서 위치 인수로 릴리스 이름을 지정해야 합니다.
- Helm v3는 값에 추가된 단위가 있는 기간을 지정해야 합니다(예: `120s` = `2m`, `210s` = `3m30s`). `--timeout` 옵션은 단위 사양 없이 초 단위로 처리됩니다.
- `--timeout` 옵션의 사용은 Helm 설치 또는 업그레이드 중에 배포되는 여러 구성 요소가 있고 `--timeout`이 적용되는 방식이 기만적입니다. `--timeout` 값은 각 구성 요소의 설치에 개별적으로 적용되며 모든 구성 요소의 설치에는 적용되지 않습니다. 따라서 `--timeout=3m`을 사용하여 3분 후 Helm 설치를 중단할 의도가 있어도 설치된 구성 요소가 설치하는 데 3분 이상 걸리지 않았기 때문에 5분 후에 설치가 완료될 수 있습니다.

GitLab의 특정 버전을 설치하려면 `--version <installation version>` 옵션을 사용할 수도 있습니다.

차트 버전과 GitLab 버전 간의 매핑을 보려면 [GitLab 버전 매핑](version_mappings.md)을 읽으세요.

태그된 릴리스가 아닌 개발 분기를 설치하기 위한 지침은 [개발자 배포 설명서](../development/deploy.md)에서 찾을 수 있습니다.

## GitLab Helm 차트의 무결성 및 출처 확인 {#verifying-the-integrity-and-origin-of-gitlab-helm-charts}

[Helm provenance](https://helm.sh/docs/topics/provenance/)를 사용하여 GitLab Helm 차트의 무결성 및 출처를 확인할 수 있습니다. 자세한 내용은 [GitLab Helm Chart provenance](chart-provenance.md)를 참고하세요.

## 배포 모니터링 {#monitoring-the-deployment}

이것은 배포가 완료되면 설치된 리소스 목록을 출력하며 5-10분이 걸릴 수 있습니다.

배포 상태는 `helm status gitlab`을 실행하여 확인할 수 있으며, 다른 터미널에서 명령을 실행하는 경우 배포가 진행 중일 때도 수행할 수 있습니다.

## 초기 로그인 {#initial-login}

설치 중에 지정된 도메인을 방문하여 GitLab 인스턴스에 액세스할 수 있습니다. 기본 도메인은 `gitlab.example.com`이며, [전역 호스트 설정](../charts/globals.md#configure-host-settings)이 변경되지 않은 경우입니다. 초기 루트 암호의 비밀번호를 수동으로 생성한 경우 해당 암호를 사용하여 `root` 사용자로 로그인할 수 있습니다. 그렇지 않으면 GitLab이 `root` 사용자에 대해 자동으로 임의의 암호를 생성했을 것입니다. 이것은 다음 명령으로 추출할 수 있습니다(`<name>`를 릴리스 이름으로 바꾸세요. 위의 명령을 사용한 경우 `gitlab`입니다).

```shell
kubectl get secret <name>-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

## Community Edition 배포 {#deploy-the-community-edition}

기본적으로 Helm 차트는 GitLab의 Enterprise Edition을 사용합니다. Enterprise Edition은 추가 기능을 잠금 해제하기 위해 유료 계층으로 업그레이드할 수 있는 옵션이 있는 GitLab의 무료 오픈 코어 버전입니다. 원하는 경우 MIT Expat 라이선스에 따라 라이선스된 Community Edition을 대신 사용할 수 있습니다.

*Community Edition을 배포하려면 Helm install 명령에 이 옵션을 포함하세요:*

```shell
--set global.edition=ce
```

## Community Edition을 Enterprise Edition으로 변환 {#convert-community-edition-to-enterprise-edition}

[Community Edition을 배포](#deploy-the-community-edition)했는데 Enterprise Edition으로 변환하려면 `--set global.edition=ce`을 지정하지 않고 GitLab을 다시 배포해야 합니다. 또한 개별 이미지를 지정한 경우(예: `--set gitlab.unicorn.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-unicorn-ce`), 이러한 이미지의 발생을 모두 생략해야 합니다.

배포 후 [Enterprise Edition 라이선스를 활성화](https://docs.gitlab.com/administration/license/)할 수 있습니다.

## 권장 다음 단계 {#recommended-next-steps}

설치를 완료한 후 인증 옵션 및 가입 제한을 포함하여 [권장 다음 단계](https://docs.gitlab.com/install/next_steps/)를 수행하는 것을 고려하세요.
