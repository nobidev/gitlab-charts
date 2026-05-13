---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트를 위한 OpenShift 리소스 준비
---

{{< details >}}

- 계층:  Free, Premium, Ultimate
- 제공 방식:  GitLab Self-Managed

{{< /details >}}

이 문서는 이 프로젝트의 자동화 스크립트를 사용하여 Google Cloud에서 OpenShift 클러스터를 생성하는 과정을 안내합니다.

## 준비 {#preparation}

먼저 GitLab 이메일과 연결된 Red Hat 계정이 있어야 합니다. Red Hat Alliance 담당자에게 문의하면 계정 초대 이메일을 보내도록 준비할 것입니다. Red Hat 계정을 활성화하면 OpenShift를 실행하는 데 필요한 라이선스 및 구독에 액세스할 수 있습니다.

Google Cloud에서 클러스터를 실행하려면 공용 Cloud DNS 영역이 등록된 도메인에 연결되고 Google Cloud DNS에서 구성되어야 합니다. 도메인을 아직 사용할 수 없으면 [이 가이드](https://github.com/openshift/installer/blob/master/docs/user/gcp/dns.md)의 단계를 따라 도메인을 생성합니다.

### CLI 도구 및 Pull Secret 가져오기 {#get-the-cli-tools-and-pull-secret}

OpenShift 클러스터를 생성하기 위해 두 개의 CLI 도구(`openshift-install`) 및 클러스터와 상호 작용하기 위해(`oc`)가 필요합니다.

Red Hat의 개인 Docker 레지스트리에서 이미지를 가져오려면 pull secret이 필요합니다. 모든 개발자는 Red Hat 계정과 연결된 다른 pull secret을 가지고 있습니다.

CLI 도구 및 pull secret을 가져오려면 [Red Hat의 클라우드](https://cloud.redhat.com/openshift/install/gcp/installer-provisioned)로 이동하여 Red Hat 계정으로 로그인합니다. 이 페이지에서 제공된 링크를 통해 설치 프로그램 및 명령줄 도구의 최신 버전을 다운로드합니다. 이 패키지를 추출하고 `openshift-install` 및 `oc`을(를) `PATH`에 배치합니다.

pull secret을 클립보드에 복사하고 콘텐츠를 이 저장소의 루트에 있는 `pull_secret` 파일에 씁니다. 이 파일은 gitignored됩니다.

### Google Cloud (GCP) Service Account 생성 {#create-a-google-cloud-gcp-service-account}

[이 지침](https://docs.openshift.com/container-platform/4.9/installing/installing_gcp/installing-gcp-account.html#installation-gcp-service-account_installing-gcp-account)에 따라 Google Cloud `cloud-native` 프로젝트에서 Service Account를 생성합니다. 해당 문서에서 필수로 표시된 모든 역할을 연결합니다. Service Account가 생성되면 JSON 키를 생성하고 이 저장소의 루트에 `gcloud.json`으로 저장합니다. 이 파일은 gitignored됩니다.

## OpenShift 클러스터 생성 {#create-your-openshift-cluster}

OpenShift 클러스터를 생성하려면:

1. GitLab Operator 저장소를 복제합니다:

   ```shell
   git clone https://gitlab.com/gitlab-org/cloud-native/gitlab-operator.git
   ```

1. Google Cloud에서 OpenShift 클러스터를 생성하는 스크립트를 실행합니다:

   ```shell
   cd gitlab-operator
   ./scripts/create_openshift_cluster.sh
   ```

이것은 3개의 컨트롤 플레인(마스터) 노드와 3개의 워커 노드가 있는 6개 노드 클러스터가 됩니다. 이 프로세스는 약 40분이 소요됩니다. 콘솔 출력의 끝에 있는 지침을 따라 클러스터에 연결합니다.

생성되면 [Red Hat cloud](https://cloud.redhat.com/openshift/)에 등록된 클러스터를 볼 수 있어야 합니다. 모든 설치 로그 및 메타데이터는 이 저장소의 `install-$CLUSTER_NAME/` 디렉터리에 저장됩니다. 이 디렉터리는 gitignored됩니다.

### 구성 옵션 {#configuration-options}

런타임 중에 환경 변수를 설정하여 구성을 적용할 수 있습니다. 모든 옵션에는 기본값이 있으므로 옵션이 필요하지 않습니다.

| 변수                         | 기본값                                      | 설명 |
|----------------------------------|----------------------------------------------|-------------|
| `CLUSTER_NAME`                   | `ocp-$USER`                                  | 클러스터의 이름 |
| `BASE_DOMAIN`                    | `k8s-ft.win`                                 | 클러스터의 루트 도메인 |
| `GCP_PROJECT_ID`                 | `cloud-native-182609`                        | Google Cloud 프로젝트 ID |
| `GCP_REGION`                     | `us-central1`                                | 클러스터의 Google Cloud 지역 |
| `GOOGLE_APPLICATION_CREDENTIALS` | `gcloud.json`                                | Google Cloud service account JSON 파일의 경로 |
| `GOOGLE_CREDENTIALS`             | `$GOOGLE_APPLICATION_CREDENTIALS`의 콘텐츠 | Google Cloud service account JSON 파일의 콘텐츠 |
| `PULL_SECRET_FILE`               | `pull_secret`                                | Red Hat pull secret 파일의 경로 |
| `PULL_SECRET`                    | `$PULL_SECRET_FILE`의 콘텐츠               | Red Hat pull secret 파일의 콘텐츠 |
| `SSH_PUBLIC_KEY_FILE`            | `$HOME/.ssh/id_rsa.pub`                      | SSH 공개 키 파일의 경로 |
| `SSH_PUBLIC_KEY`                 | `$SSH_PUBLIC_KEY_FILE`의 콘텐츠            | SSH 공개 키 파일의 콘텐츠 |
| `LOG_LEVEL`                      | `info`                                       | `openshift-install` 출력의 상세함 |
| `INSTALL_DIR`                    | `install-$CLUSTER_NAME`                      | 설치 자산용 디렉터리, 여러 클러스터를 시작하는 데 유용함 |

> [!note] `CLUSTER_NAME` 및 `BASE_DOMAIN` 변수를 조합하여 클러스터의 도메인 이름을 구성합니다.

## OpenShift 클러스터 삭제 {#destroy-your-openshift-cluster}

OpenShift 클러스터를 삭제하려면:

1. GitLab Operator 저장소를 복제합니다:

   ```shell
   git clone https://gitlab.com/gitlab-org/cloud-native/gitlab-operator.git
   ```

1. Google Cloud에서 OpenShift 클러스터를 삭제하는 스크립트를 실행합니다. 이것은 약 4분이 소요됩니다:

   ```shell
   cd gitlab-operator
   ./scripts/destroy_openshift_cluster.sh
   ```

런타임 중에 다음 환경 변수를 설정하여 구성을 적용할 수 있습니다. 모든 옵션에는 기본값이 있으며 옵션이 필요하지 않습니다.

| 변수                         | 기본값                                      | 설명 |
|----------------------------------|----------------------------------------------|-------------|
| `GOOGLE_APPLICATION_CREDENTIALS` | `gcloud.json`                                | Google Cloud service account JSON 파일의 경로 |
| `GOOGLE_CREDENTIALS`             | `$GOOGLE_APPLICATION_CREDENTIALS`의 콘텐츠 | Google Cloud service account JSON 파일의 콘텐츠 |
| `LOG_LEVEL`                      | `info`                                       | `openshift-install` 출력의 상세함 |
| `INSTALL_DIR`                    | `install-$CLUSTER_NAME`                      | 설치 자산용 디렉터리, 여러 클러스터를 시작하는 데 유용함 |

## 다음 단계 {#next-steps}

클러스터가 가동 중이면 [GitLab 설치](https://docs.gitlab.com/operator/)를 계속할 수 있습니다.

## 리소스 {#resources}

- [`openshift-installer` 소스 코드](https://github.com/openshift/installer)
- [`oc` 소스 코드](https://github.com/openshift/oc)
- [`openshift-installer` 및 `oc` 패키지](https://mirror.openshift.com/pub/openshift-v4/clients/ocp/)
- [OpenShift Container Project (OCP) 아키텍처 문서](https://access.redhat.com/documentation/en-us/openshift_container_platform/4.9/html/architecture/architecture)
- [OpenShift GCP 문서](https://docs.openshift.com/container-platform/4.9/installing/installing_gcp/installing-gcp-account.html)
- [OpenShift 문제 해결 가이드](https://docs.openshift.com/container-platform/4.9/support/troubleshooting/troubleshooting-installations.html)
