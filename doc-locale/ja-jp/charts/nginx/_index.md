---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: NGINXの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

Ingressコントローラーとして使用される完全なNGINXデプロイを提供します。すべてのKubernetesプロバイダーがネイティブでNGINX [Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls)をサポートしているわけではありません。互換性を確保するためです。

{{< alert type="note" >}}

- GitLab NGINXチャートは、アップストリームNGINX Helmチャートのフォークです。私たちのフォークで何が変更されたかについて詳しくは、[NGINXフォークへの調整](#adjustments-to-the-nginx-fork)をご覧ください。
- 1つの`global.hosts.domain`の値のみが可能です。複数のドメインのサポートは、[イシュー3147](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3147)で追跡されています。

{{< /alert >}}

## NGINXの設定 {#configuring-nginx}

設定の詳細については、[NGINXチャートのドキュメント](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/nginx-ingress/README.md#configuration)を参照してください。

### グローバル設定 {#global-settings}

チャート間でいくつかの共通グローバル設定を共有します。GitLabやレジストリのホスト名など、共通の[設定](../globals.md)オプションについては、[グローバルドキュメント](../globals.md)を参照してください。

## グローバル設定を使用したホストの設定 {#configure-hosts-using-the-global-settings}

GitLabサーバーとレジストリサーバーのホスト名は、[グローバル設定](../globals.md)チャートを使用して設定できます。

## GitLab Geo {#gitlab-geo}

2番目のNGINXサブチャートがバンドルされており、GitLab Geoトラフィック用に事前設定されています。これは、デフォルトコントローラーと同じ設定をサポートします。コントローラーは`nginx-ingress-geo.enabled=true`で有効にできます。

このコントローラーは、受信`X-Forwarded-*`ヘッダーを変更しないように構成されています。Geoトラフィックに別のプロバイダーを使用する場合は、同じことを確認してください。

デフォルトコントローラーの値（`nginx-ingress-geo.controller.ingressClassResource.controllerValue`）は`k8s.io/nginx-ingress-geo`に設定され、IngressClass名は`{ReleaseName}-nginx-geo`に設定され、デフォルトコントローラーとの干渉を回避します。IngressClass名は、`global.geo.ingressClass`でオーバーライドできます。

カスタムヘッダー処理は、セカンダリサイトから転送されたトラフィックを処理するために、プライマリGeoサイトでのみ必要です。サイトがプライマリにプロモートされる予定の場合、セカンダリでのみ使用する必要があります。

フェイルオーバー中にIngressClassを変更すると、他のコントローラーが受信トラフィックを処理することに注意してください。他のコントローラーには異なるロードバランサーIPが割り当てられているため、DNS設定に追加の変更が必要になる場合があります。

これは、すべてのGeoサイトでGeo Ingressコントローラーを有効にし、関連付けられたIngressClass（`useGeoClass=true`）を使用するようにデフォルトおよび追加のウェブサービスIngressを設定することで回避できます。

## アノテーション値のワードブロックリスト {#annotation-value-word-blocklist}

{{< history >}}

- [GitLab Helmチャート6.6](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2713)で導入。

{{< /history >}}

クラスターオペレーターが生成されたNGINX[設定](https://kubernetes.github.io/ingress-nginx/examples/customization/configuration-snippets/)をより詳細に制御する必要がある状況では、NGINX Ingressは、標準のアノテーションとConfigMap[エントリ](https://kubernetes.github.io/ingress-nginx/examples/customization/configuration-snippets/)で処理されないraw NGINX[設定](https://kubernetes.github.io/ingress-nginx/examples/customization/configuration-snippets/)の「スニペット」を挿入する[設定スニペット](https://kubernetes.github.io/ingress-nginx/examples/customization/configuration-snippets/)を許可します。

これらの設定スニペットの欠点は、クラスターオペレーターが、LUAスクリプトや、GitLabインストールとクラスター自体のセキュリティを侵害する可能性のある同様の設定（serviceaccountトークンやシークレットの公開など）を含むIngressオブジェクトをデプロイできることです。

詳細については、[CVE-2021-25742](https://nvd.nist.gov/vuln/detail/CVE-2021-25742)および[このアップストリーム`ingress-nginx`イシュー](https://github.com/kubernetes/ingress-nginx/issues/7837)を参照してください。

GitLabのHelmチャート[デプロイ](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/v6.6.0/values.yaml#L836)でCVE-2021-25742を[緩和](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/v6.6.0/values.yaml#L836)するために、`nginx-ingress`コミュニティからの推奨[設定](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#annotation-value-word-blocklist)を使用して、[アノテーション値ワードブロックリスト](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/v6.6.0/values.yaml#L836)を設定します

GitLab Ingress設定で設定スニペットを使用している場合、または設定スニペットを使用するサードパーティのIngressオブジェクトでGitLab NGINX Ingressコントローラーを使用している場合は、GitLabサードパーティドメインにアクセスしようとすると`404`エラーが発生し、`nginx-controller`ログに「無効な単語」エラーが発生する可能性があります。その場合は、`nginx-ingress.controller.config.annotation-value-word-blocklist`設定を確認して調整してください。

チャートの[トラブルシューティングドキュメント](../../troubleshooting/_index.md#invalid-word-errors-in-the-nginx-controller-logs-and-404-errors)の`nginx-controller`ログおよび`404`エラーの「無効な単語」エラーも参照してください。

## NGINXフォークへの調整 {#adjustments-to-the-nginx-fork}

{{< alert type="note" >}}

NGINX[チャート](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts/nginx-ingress)の[フォーク](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts/nginx-ingress)は、[GitHub](https://github.com/kubernetes/ingress-nginx)から[プル](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts/nginx-ingress)されました。

{{< /alert >}}

次の調整がNGINXフォークに加えられました。

- `tcp-configmap.yaml`：新しい`tcpExternalConfig`設定に応じてオプション
- 別のチャートからテンプレート化されたTCP ConfigMap名を使用する機能
  - `controller-configmap-tcp.yaml`：`.metadata.name`はテンプレート`ingress-nginx.tcp-configmap`です
  - `controller-deployment.yaml`：`.spec.template.spec.containers[0].args`は、ConfigMap名に`ingress-nginx.tcp-configmap`テンプレートを使用します
  - GitLabチャートは`ingress-nginx.tcp-configmap`をオーバーライドして、`gitlab/gitlab-org/charts/gitlab-shell`がTCPサービスを設定できるようにします
- リリース名に基づいて、テンプレート化されたIngress名を使用する機能
- `controller.service.loadBalancerIP`を`externalIpTpl`に置き換えます（デフォルトは`global.hosts.externalIP`）
- `common.labels`設定オプションを介して共通ラベルを追加するサポートを追加
- `controller-deployment.yaml`:
  - `podlabels`と`global.pod.labels`を`.spec.template.metadata.labels`に追加
- `default-backend-deployment.yaml`:
  - `podlabels`と`global.pod.labels`を`.spec.template.metadata.labels`に追加
- NGINXのデフォルトのnodeSelectorsを無効にします。
- PDB `maxUnavailable`のサポートを追加しました。
- `charts/nginx-ingress/templates/_helpers.tpl`のNGINXの`isControllerTagValid`ヘルパーを削除します
  - 2020年に[実装](https://github.com/kubernetes/ingress-nginx/pull/5252)されてから、チェックは更新されていませんでした。
  - [\#3383](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3383)の一部として、`ubi`を含む[タグ](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3383)を参照する必要があります。これは、`semverCompare`がとにかく期待どおりに機能しないことを意味します。
- HPAでautoscaling/v2beta2およびautoscaling/v2 APIのサポートを追加し、HPA設定を拡張して、メモリーとカスタムメトリクス、および動作設定をサポートしました。
- PodDisruptionBudgetのAPIバージョンの条件付きサポートを追加しました。
- 外部サービスと内部サービス（`controller.service.internal.enabled`で有効になっている場合）に対して、GitLab Shell（SSHアクセス）を個別に有効/無効にするには、次のブール値を追加します。
  - `controller.service.enableShell`。
  - `controller.service.internal.enableShell`。（`controller.service.enableHttp(s)`の既存のチャートパターンに従います）
- テンプレート呼び出し`{{ include "ingress-nginx.automountServiceAccountToken" . }}`を`controller-serviceaccount.yaml`に追加します
- テンプレートを`_helpers.tpl`に追加します：

  ```go
  {{/*
  Set if the default ServiceAccount token should be mounted by Kubernetes or not.

  Default is 'true'
  */}}
  {{- define "ingress-nginx.automountServiceAccountToken" -}}
  automountServiceAccountToken: {{ pluck "automountServiceAccountToken" .Values.serviceAccount .Values.global.serviceAccount | first }}
  {{- end -}}
  ```

- テンプレート呼び出し`{{ include "ingress-nginx.defaultBackend.automountServiceAccountToken" . }}`を`default-backend-serviceaccount.yaml`に追加します
- テンプレートを`_helpers.tpl`に追加します：

  ```go
  {{/*
  Set if the default ServiceAccount token should be mounted by Kubernetes or not.

  Default is 'true'
  */}}
  {{- define "ingress-nginx.defaultBackend.automountServiceAccountToken" -}}
  automountServiceAccountToken: {{ pluck "automountServiceAccountToken" .Values.defaultBackend.serviceAccount .Values.global.serviceAccount | first }}
  {{- end -}}
  ```

- Pod Security Standards Profile Restrictedに準拠するために、次の属性を追加します。
  - `controller-deployment.yaml`
    - `spec.template.spec.containers[0].securityContext.runAsNonRoot`
    - `spec.template.spec.containers[0].securityContext.seccompProfile`
- 次の新しいRBACルールを追加します。これは、チャートが4.0.6の場合に必要ですが、コントローラーイメージを1.11.2にバンプしました。チャートを4.11.2にすると、このパッチを削除できます。これは、コントローラーがエンドポイントの追跡にendpointslicesを使用するようになったために必要でした。これは、`charts/nginx-ingress/templates/clusterrole.yaml`と`charts/nginx-ingress/templates/controller-role.yaml`の両方に追加されました。

  ```yaml
  - apiGroups:
      - discovery.k8s.io
    resources:
      - endpointslices
    verbs:
      - list
      - watch
      - get
  ```

  また、v1.3.1からv1.11.2以降への移行をサポートするために、独自のRBACルールを設定したユーザーは、RBACルールを適宜更新してください。v1.3.1イメージにフォールバックしなくなりました。
