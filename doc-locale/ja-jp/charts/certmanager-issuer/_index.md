---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: CertManager Issuer作成のためのcertmanager-issuerの使用
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

このチャートは、[JetstackのCertManager Helm Chart](https://cert-manager.io/docs/installation/helm/)のヘルパーです。GitLab IngressのTLS証明書をリクエストする際にCertManagerが使用するIssuerオブジェクトを自動的にプロビジョニングします。

## 設定 {#configuration}

ここでは、設定の主要なセクションについて説明します。親チャートから設定する場合、これらの値は次のとおりです。

```yaml
certmanager-issuer:
  # Configure an ACME Issuer in cert-manager. Only used if global.ingress.configureCertmanager is true.
  server: https://acme-v02.api.letsencrypt.org/directory

  # Provide an email to associate with your TLS certificates
  # email:

  rbac:
    create: true

  resources:
    requests:
      cpu: 50m

  # Priority class assigned to pods
  priorityClassName: ""

  common:
    labels: {}
```

## インストールパラメータ {#installation-parameters}

このには、`helm install`フラグを使用して`--set`コマンドに指定できるすべての可能な設定が含まれています。

| パラメータ                                           | デフォルト                                          | 説明 |
|-----------------------------------------------------|--------------------------------------------------|-------------|
| `server`                                            | `https://acme-v02.api.letsencrypt.org/directory` | [ACME CertManager Issuer](https://cert-manager.io/docs/configuration/acme/)で使用するLet's Encryptサーバー。 |
| `email`                                             |                                                  | TLS証明書に関連付けるを指定する必要があります。Let's Encryptはこのアドレスを使用して、期限切れの証明書、およびアカウントに関連するについて連絡します。 |
| `rbac.create`                                       | `true`                                           | `true`の場合、CertManager Issuerの操作を許可するために、関連のリソースを作成します。 |
| `resources.requests.cpu`                            | `50m`                                            | Issuer作成のリクエストされたCPU。 |
| `common.labels`                                     |                                                  | ServiceAccount、、ConfigMap、およびIssuerに適用する共通。 |
| `priorityClassName`                                 |                                                  | [優先](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/)クラスがにされます。 |
| `containerSecurityContext`                          |                                                  | Certmanagerの起動元の[securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core)をする |
| `containerSecurityContext.runAsUser`                | `65534`                                          | の起動元のユーザーID |
| `containerSecurityContext.runAsGroup`               | `65534`                                          | の起動元のグループ |
| `containerSecurityContext.allowPrivilegeEscalation` | `false`                                          | プロセスがプロセスよりも多くの特権を取得できるかどうかを制御します |
| `containerSecurityContext.runAsNonRoot`             | `true`                                           | を非ルートユーザーで実行するかどうかを制御します |
| `containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                      | の[Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html)機能を削除します |
| `ttlSecondsAfterFinished`                           | `1800`                                           | 完了したがカスケード削除の対象となるタイミングを制御します。 |
