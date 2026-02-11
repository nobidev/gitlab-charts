---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 外部NGINX IngressコントローラーでGitLabチャートを設定する
---

{{< alert type="warning" >}}

NGINX Ingressは非推奨となり、2026年3月以降はセキュリティパッチを受け取ることはありません。

詳細については、[公式発表](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)をお読みください。

{{< /alert >}}

GitLabチャートは現在、フォークしたNGINX Ingressを管理およびバンドルしています。このガイドは、バンドルされたものではなく、外部のNGINX IngressをGitLabチャートで使用するように設定するのに役立ちます。

## 外部IngressコントローラーのTCPサービス {#tcp-services-in-the-external-ingress-controller}

GitLab Shellコンポーネントでは、TCPトラフィックが（デフォルトでは）ポート22をパススルーする必要があります（これは変更可能です）。IngressはTCPサービスを直接サポートしていないため、追加の設定が必要です。ご使用のNGINX Ingressコントローラーは、（Kubernetesスペックファイルを使用して）[直接デプロイされた](https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md)か、[公式Helmチャート経由](https://github.com/kubernetes/ingress-nginx)でデプロイされている可能性があります。TCPパススルーの設定は、デプロイ方法によって異なります。

### ダイレクトデプロイ {#direct-deployment}

ダイレクトデプロイでは、NGINX Ingressコントローラーは`ConfigMap`を使用してTCPサービスの設定を処理します。詳細については、Ingress NGINXコントローラーのドキュメントで[TCPおよびUDPサービスの公開](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md)に関する情報を参照してください。GitLabチャートがネームスペース`gitlab`にデプロイされ、Helmリリースが`mygitlab`という名前の場合、`ConfigMap`は次のようになります:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-configmap-example
data:
  22: "gitlab/mygitlab-gitlab-shell:22"
```

その`ConfigMap`を入手したら、`--tcp-services-configmap`オプションを使用して、NGINX Ingressコントローラーの[ドキュメント](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md)の説明に従って有効にできます。

```yaml
args:
  - /nginx-ingress-controller
  - --tcp-services-configmap=gitlab/tcp-configmap-example
```

最後に、NGINX Ingressコントローラーの`Service`が、80および443に加えてポート22を公開していることを確認してください。

### Helmデプロイ {#helm-deployment}

[Helmチャート](https://github.com/kubernetes/ingress-nginx)を使用してNGINX Ingressコントローラーをインストールした、またはインストールする予定がある場合は、コマンドラインを使用してチャートに値を追加する必要があります:

```shell
--set tcp.22="gitlab/mygitlab-gitlab-shell:22"
```

または`values.yaml`ファイル:

```yaml
tcp:
  22: "gitlab/mygitlab-gitlab-shell:22"
```

値の形式は、上記の「直接デプロイ」セクションで説明されているものと同じです。

### GitLabチャートを設定する {#configure-gitlab-chart}

外部NGINX Ingressコントローラーを使用するように[GitLab Ingressを設定](_index.md)します。
