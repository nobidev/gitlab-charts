---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Helm v2からHelm v3への移行
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

[Helm v2は2020年11月に正式に非推奨](https://helm.sh/blog/helm-v2-deprecation-timeline/)となりました。GitLab Helmチャートバージョン5.0（GitLabアプリケーションバージョン14.0）以降、Helm v2.xを使用したインストールとアップグレードはサポートされなくなりました。今後のGitLabの更新を入手するには、Helm v3に移行する必要があります。

## Helm v2とHelm v3の変更点 {#changes-between-helm-v2-and-helm-v3}

Helm v3では、Helm v2との下位互換性のない多くの変更が導入されています。主な変更点としては、Tiller要件の削除や、クラスターでのリリース情報の保存方法などがあります。詳しくは、[Helm v3の変更点の概要](https://helm.sh/docs/topics/v2_v3_migration/#overview-of-helm-3-changes)と[Helm v2 FAQからの変更点](https://helm.sh/docs/faq/changes_since_helm2/)をご覧ください。

アプリケーションのデプロイに使用するHelm Chartは、新旧バージョンのHelmと互換性がない場合があります。複数のアプリケーションをHelm v2でデプロイおよび管理している場合は、それらも変換する場合に備えて、Helm v3との互換性を確認する必要があります。GitLab Helmチャートは、GitLab Helmチャートのバージョンv3.0.0以降、Helm v3.0.2以上をサポートしています。Helm v2はサポートされなくなりました。

現在実行中のアプリケーションの観点からは、Helm v2からv3への移行を実行しても何も変更されません。通常、Helm v2からv3への移行を実行してもかなり安全ですが、念のため、Helm v2のバックアップを作成してください。

## Helm v2からHelm v3への移行方法 {#how-to-migrate-from-helm-v2-to-helm-v3}

[Helm 2to3プラグイン](https://github.com/helm/helm-2to3)を使用して、GitLabのリリースをHelm v2からHelm v3に移行できます。この移行プラグインに関する詳細な説明といくつかの例については、Helmのブログ記事を参照してください:[Helm v2からHelm v3への移行方法](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/)。

GitLab Helmのインストールを複数のユーザーが管理している場合は、各ローカルマシンで`helm3 2to3 move config`を実行する必要がある場合があります。`helm3 2to3 convert`を実行する必要があるのは1回だけです。

## 既知のイシュー {#known-issues}

### 「UPGRADE FAILED: cannot patch」エラーが移行後に表示される {#upgrade-failed-cannot-patch-error-is-shown-after-the-migration}

移行後、**その後のアップグレードが失敗**し、次のようなエラーが表示される場合があります。

```shell
Error: UPGRADE FAILED: cannot patch "..." with kind Deployment: Deployment.apps "..." is invalid: spec.selector:
Invalid value: v1.LabelSelector{...}: field is immutable
```

または

```shell
Error: UPGRADE FAILED: cannot patch "..." with kind StatefulSet: StatefulSet.apps "..." is invalid:
spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', and 'updateStrategy' are forbidden
```

これは、[Cert Manager](https://github.com/jetstack/cert-manager/issues/2451)と[Redis](https://github.com/bitnami/charts/issues/3482)の依存関係におけるHelm 2から3への移行に関する既知のイシューが原因です。一言で言えば、一部のデプロイメントとステートフルセットの`heritage`ラベルは不変であり、`Tiller`（Helm 2で設定）から`Helm`（Helm 3で設定）に変更できません。そのため、_強制的に_置き換える必要があります。

これを回避するには、次の手順を使用します:

{{< alert type="note" >}}

これらの手順は、特にRedis StatefulSetで、_リソースを強制的に置き換えます_。このStatefulSetにアタッチされているデータボリュームが安全で、そのまま残っていることを確認する必要があります。

{{< /alert >}}

1. （有効になっている場合は）cert-managerデプロイメントを置き換えます。

```shell
kubectl get deployments -l app=cert-manager -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true -f -
kubectl get deployments -l app=cainjector -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true -f -
```

1. （オプション）Redis StatefulSetによって要求されるPVの`persistentVolumeReclaimPolicy`を`Retain`に設定します。これは、PVが誤って削除されないようにするためです。

```shell
kubectl patch pv <PV-NAME> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

1. 既存のRedis PVCの`heritage`ラベルを`Helm`に設定します。

```shell
kubectl label pvc -l app=redis --overwrite heritage=Helm
```

1. **カスケードなしで**Redis StatefulSetを置き換えます。

```shell
kubectl get statefulsets.apps -l app=redis -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true --cascade=false -f -
```

### Helmのアップグレード実行時の移行後のRBACに関するイシュー {#rbac-issues-after-the-migration-when-running-helm-upgrade}

変換が完了した後、Helmのアップグレードを実行すると、次のエラーが発生する場合があります。

```shell
Error: UPGRADE FAILED: pre-upgrade hooks failed: warning: Hook pre-upgrade gitlab/templates/shared-secrets/rbac-config.yaml failed: roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden: user "your-user-name@domain.tld" (groups=["system:authenticated"]) is attempting to grant RBAC permissions not currently held:
{APIGroups:[""], Resources:["secrets"], Verbs:["get" "list" "create" "patch"]}
```

Helm2は、Tillerサービスアカウントを使用してこのようなオペレーションを実行していました。Helm3はTillerを使用しなくなり、クラスター管理者として`helm upgrade`を実行している場合でも、コマンドを実行するには、ユーザーアカウントに適切なRBAC権限が必要です。自分自身に完全なRBAC権限を付与するには、次を実行します:

```shell
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=your-user-name@domain.tld
```

その後、`helm upgrade`は正常に動作するはずです。
