---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab 차트를 위한 OKE 리소스 준비
---

{{< details >}}

- 계층:  무료, 프리미엄, 최종
- 제공:  GitLab 자체 관리

{{< /details >}}

완전히 기능하는 GitLab 인스턴스를 위해서는 GitLab 차트를 [Oracle Container Engine for Kubernetes (OKE)](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengoverview.htm)에 배포하기 전에 몇 가지 리소스가 필요합니다. OKE 클러스터를 만들기 전에 Oracle Cloud Infrastructure 테넌시를 [준비](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengprerequisites.htm)하는 방법을 확인하세요.

## OKE 클러스터 생성 {#creating-the-oke-cluster}

전제 조건:

- [전제 조건](../tools.md)을 설치하세요.

Kubernetes 클러스터를 수동으로 프로비저닝하려면 [OKE 지침](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke.htm)을 따르세요. OKE에서 지원하는 워커 노드에 사용 가능한 컴퓨팅 [형태](https://docs.oracle.com/en-us/iaas/Content/ContEng/Reference/contengimagesshapes.htm#shapes) 목록을 확인하세요.

4개의 OCPU와 30GB의 RAM이 있는 클러스터가 권장됩니다.

### GitLab에 대한 외부 액세스 {#external-access-to-gitlab}

기본적으로 GitLab 차트는 100Mbps 형태로 Oracle Cloud Infrastructure 공개 로드 밸런서를 생성하는 Ingress Controller를 배포합니다. 로드 밸런서 서비스는 호스트 서브넷에서 나오지 않는 부동 공용 IP 주소를 할당합니다.

차트 설치 중에 형태 및 기타 구성(포트, SSL, 보안 목록 등)을 변경하려면 다음 명령줄 인수 `nginx-ingress.controller.service.annotations`을 사용할 수 있습니다. 예를 들어 400Mbps 형태로 로드 밸런서를 지정하려면:

```shell
--set nginx-ingress.controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-shape"="400Mbps"
```

배포된 후에는 Ingress Controller 서비스와 관련된 주석을 확인할 수 있습니다:

```plaintext
$ kubectl get service gitlab-nginx-ingress-controller -o yaml

apiVersion: v1
kind: Service
metadata:
  annotations:
    ...
    service.beta.kubernetes.io/oci-load-balancer-shape: 400Mbps
    ...
```

자세한 내용은 [OKE 로드 밸런서 설명서](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingloadbalancer.htm)를 확인하세요.

## 다음 단계 {#next-steps}

클러스터가 실행 중이면 [차트 설치](../deployment.md)를 계속하세요. `global.hosts.domain` 옵션을 통해 DNS 도메인 이름을 설정하되 `global.hosts.externalIP` 옵션을 통한 정적 IP 설정은 생략하세요.

배포를 완료한 후 로드 밸런서의 IP 주소를 쿼리하여 DNS 레코드 유형과 연결할 수 있습니다:

```shell
kubectl get ingress/<RELEASE>-webservice-default -ojsonpath='{.status.loadBalancer.ingress[0].ip}'
```

`<RELEASE>`은 `helm install <RELEASE>`에서 사용되는 릴리스 이름으로 대체되어야 합니다.
