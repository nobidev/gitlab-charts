---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트에 사용자 지정 Docker 이미지 사용
---

특정 시나리오(예: 오프라인 환경)에서는 인터넷에서 이미지를 다운로드하는 대신 자체 이미지를 사용하려고 할 수 있습니다. 이를 위해서는 GitLab 릴리스를 구성하는 각 차트에 대해 자신의 Docker 이미지 레지스트리/리포지토리를 지정해야 합니다.

## 기본 이미지 형식 {#default-image-format}

대부분의 경우 이미지의 기본 형식에는 태그를 제외한 이미지의 전체 경로가 포함됩니다:

```yaml
image:
  repository: repo.example.com/image
  tag: custom-tag
```

최종 결과는 `repo.example.com/image:custom-tag`입니다.

## 현재 이미지 및 태그 {#current-images-and-tags}

업그레이드를 계획할 때 현재 `values.yaml`과 GitLab 차트의 대상 버전을 사용하여 [Helm 템플릿](https://helm.sh/docs/helm/helm_template/)을 생성할 수 있습니다. 이 템플릿에는 차트의 지정된 버전에 필요한 이미지와 각각의 태그가 포함됩니다.

```shell
# Gather the latest values
helm get values gitlab > gitlab.yaml

# Use the gitlab.yaml to find the images and tags
helm template versionfinder gitlab/gitlab -f gitlab.yaml --version 7.3.0 | grep 'image:' | tr -d '[[:blank:]]' | sort --unique
```

이 명령을 사용하여 사용자 지정 구성을 확인할 수도 있습니다.

## 예제 값 파일 {#example-values-file}

[예제 값 파일](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/custom-images/values.yaml)이 사용자 지정 Docker 레지스트리/리포지토리 및 태그를 구성하는 방법을 보여줍니다. 자신의 릴리스를 위해 이 파일의 관련 섹션을 복사할 수 있습니다.

> [!note]
> 일부 차트(특히 써드파티 차트)는 이미지 레지스트리/리포지토리 및 태그를 지정하기 위한 규칙이 약간 다를 수 있습니다. 써드파티 차트에 대한 문서는 [Artifact Hub](https://artifacthub.io/)에서 찾을 수 있습니다.
