---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 외부 NGINX Ingress Controller를 사용하여 GitLab chart 구성
---

> [!warning]
> GitLab chart는 버전 19.0부터 Gateway API 및 Envoy Gateway를 기본값으로 사용합니다. 번들된 NGINX Ingress는 더 이상 사용되지 않으며 GitLab 20.0에서 제거됩니다. [지원 중단 공지](https://docs.gitlab.com/update/deprecations/#support-for-nginx-ingress-haproxy-and-traefik-charts) 및 [사용 중지 공지](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)를 확인하여 자세히 알아보세요.

GitLab chart는 현재 포크된 NGINX Ingress를 관리하고 번들합니다. 이 가이드는 번들된 Ingress 대신 외부 NGINX Ingress를 GitLab chart와 함께 사용하도록 구성하는 데 도움이 됩니다.

## 외부 Ingress Controller의 TCP 서비스 {#tcp-services-in-the-external-ingress-controller}

GitLab Shell 구성 요소는 포트 22(기본값, 변경 가능)를 통해 TCP 트래픽이 통과하도록 요구합니다. Ingress는 TCP 서비스를 직접 지원하지 않으므로 추가 구성이 필요합니다. NGINX Ingress Controller는 [직접 배포](https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md) 되었거나(즉, Kubernetes 사양 파일 사용) [공식 Helm chart](https://github.com/kubernetes/ingress-nginx)를 통해 배포되었을 수 있습니다. TCP 패스스루 구성은 배포 방식에 따라 달라집니다.

### 직접 배포 {#direct-deployment}

직접 배포에서 NGINX Ingress Controller는 `ConfigMap`를 사용하여 TCP 서비스 구성을 처리합니다. 자세한 내용은 Ingress NGINX Controller 설명서의 [TCP 및 UDP 서비스 노출](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md)을 참조하세요. GitLab chart가 `gitlab` 네임스페이스에 배포되고 Helm 릴리스가 `mygitlab`로 명명되었다고 가정하면, `ConfigMap`는 다음과 같아야 합니다:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-configmap-example
data:
  22: "gitlab/mygitlab-gitlab-shell:22"
```

`ConfigMap`을 확보한 후, NGINX Ingress Controller [문서](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md)에 설명된 대로 `--tcp-services-configmap` 옵션을 사용하여 활성화할 수 있습니다.

```yaml
args:
  - /nginx-ingress-controller
  - --tcp-services-configmap=gitlab/tcp-configmap-example
```

마지막으로 NGINX Ingress Controller의 `Service`이 80 및 443에 추가로 포트 22를 노출하는지 확인하세요.

### Helm 배포 {#helm-deployment}

[Helm chart](https://github.com/kubernetes/ingress-nginx)를 사용하여 NGINX Ingress Controller를 설치했거나 설치할 계획이라면, 명령줄을 사용하여 차트에 값을 추가해야 합니다:

```shell
--set tcp.22="gitlab/mygitlab-gitlab-shell:22"
```

또는 `values.yaml` 파일:

```yaml
tcp:
  22: "gitlab/mygitlab-gitlab-shell:22"
```

값의 형식은 위의 "직접 배포" 섹션에서 설명한 것과 동일합니다.

### GitLab chart 구성 {#configure-gitlab-chart}

[GitLab Ingress 구성](_index.md)을 수행하여 외부 NGINX Ingress controller를 사용합니다.
