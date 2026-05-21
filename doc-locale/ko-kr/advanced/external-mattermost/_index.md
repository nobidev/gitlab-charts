---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mattermost Team Edition을 사용하여 GitLab 차트 구성
---

이 문서는 기존 GitLab Helm 차트 배포 근처에 Mattermost Team Edition Helm 차트를 설치하는 방법을 설명합니다.

Mattermost Helm 차트가 별도의 네임스페이스에 설치되므로 `cert-manager`과 `nginx-ingress`을 클러스터 전체 Ingress 및 인증서 리소스를 관리하도록 구성하는 것이 좋습니다. 추가 구성 정보는 [Mattermost Helm 구성 가이드](https://github.com/mattermost/mattermost-helm/tree/master/charts/mattermost-team-edition#configuration)를 참조하세요.

## 사전 요구사항 {#prerequisites}

- 실행 중인 Kubernetes 클러스터.
- [Helm v3](https://helm.sh/docs/intro/install/)

> [!note]
> Team Edition의 경우 하나의 복제본만 실행할 수 있습니다.

## Mattermost Team Edition Helm 차트 배포 {#deploy-the-mattermost-team-edition-helm-chart}

Mattermost Team Edition Helm 차트를 설치한 후 다음 명령을 사용하여 배포할 수 있습니다:

```shell
helm repo add mattermost https://helm.mattermost.com
helm repo update
helm upgrade --install mattermost -f values.yaml mattermost/mattermost-team-edition
```

포드가 실행될 때까지 기다립니다. 그런 다음 구성에서 지정한 Ingress 호스트를 사용하여 Mattermost 서버에 액세스합니다.

추가 구성 정보는 [Mattermost Helm 구성 가이드](https://github.com/mattermost/mattermost-helm/tree/master/charts/mattermost-team-edition#configuration) 를 참조하세요. 이 문제와 관련하여 문제가 발생하면 [Mattermost Helm 차트 이슈 저장소](https://github.com/mattermost/mattermost-helm/issues) 또는 [Mattermost Forum](https://forum.mattermost.com/search?q=helm)을 확인하시기 바랍니다.

## GitLab Helm 차트 배포 {#deploy-gitlab-helm-chart}

GitLab Helm 차트를 배포하려면 [설치 지침](../../_index.md)을 따르세요.

간단한 설치 방법은 다음과 같습니다:

```shell
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600s \
  --set global.hosts.domain=<your-domain> \
  --set global.hosts.externalIP=<external-ip> \
  --set certmanager-issuer.email=<email>
```

- `<your-domain>`: 원하는 도메인(예: `gitlab.example.com`)입니다.
- `<external-ip>`: Kubernetes 클러스터를 가리키는 외부 IP입니다.
- `<email>`: TLS 인증서를 검색하기 위해 Let's Encrypt에 등록할 이메일입니다.

GitLab 인스턴스를 배포한 후 [초기 로그인](../../installation/deployment.md#initial-login)에 대한 지침을 따르세요.

## GitLab을 사용하여 OAuth 애플리케이션 만들기 {#create-an-oauth-application-with-gitlab}

프로세스의 다음 부분은 GitLab SSO 통합을 설정하는 것입니다. 이를 위해 Mattermost가 GitLab을 인증 제공자로 사용하도록 [OAuth 애플리케이션을 만들어야](https://docs.mattermost.com/deployment/sso-gitlab.html) 합니다.

> [!note]
> 기본 GitLab SSO만 공식적으로 지원됩니다. GitLab SSO가 다른 SSO 솔루션으로 연결되는 "이중 SSO"는 지원되지 않습니다. 경우에 따라 GitLab SSO를 AD, LDAP, SAML 또는 MFA 추가 기능과 연결할 수 있지만 필요한 특수 논리로 인해 공식적으로 지원되지 않으며 일부 경험에서는 작동하지 않는 것으로 알려져 있습니다.

## 문제 해결 {#troubleshooting}

제공된 프로세스가 아닌 다른 프로세스를 따르고 있으며 인증 및/또는 배포 문제가 발생하는 경우 [Mattermost 문제 해결 포럼](https://docs.mattermost.com/install/troubleshooting.html?&redirect_source=mm-org)에서 알려주세요.
