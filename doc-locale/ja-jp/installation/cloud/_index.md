---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLabチャートのクラウドプロバイダーの設定
---

{{< details >}}

- プラン:Free、Premium、Ultimate
- 提供:GitLab Self-Managed

{{< /details >}}

GitLabチャートをデプロイする前に、選択したクラウドプロバイダーのリソースを構成する必要があります。

GitLabチャートは、少なくとも8つのvCPUと30GiBのRAMを持つクラスターに適合するように設計されています。本番環境以外のインスタンスをデプロイする場合は、より小さなクラスターに合うようにデフォルト値を小さくすることができます。

## サポートされているKubernetesリリース {#supported-kubernetes-releases}

GitLab Helmチャートは、以下のKubernetesリリースをサポートしています。

| Kubernetesリリース | 状態      | 最小GitLabバージョン | アーキテクチャ | サポート終了 |
|--------------------|-------------|------------------------|---------------|-------------|
| 1.33               | サポート対象   | 18.1                   | x86-64        | 2026-06-28  |
| 1.32               | サポート対象   | 17.11                  | x86-64        | 2026-02-28  |
| 1.31               | サポート対象   | 17.6                   | x86-64        | 2025-10-28  |
| 1.30               | 非推奨  | 17.6                   | x86-64        | 2025-06-28  |
| 1.29               | サポート対象外 | 17.0                   | x86-64        | 2025-02-28  |
| 1.28               | サポート対象外 | 17.0                   | x86-64        | 2024-10-28  |
| 1.27               | サポート対象外 | 16.6                   | x86-64        | 2024-06-28  |
| 1.26               | サポート対象外 | 16.5                   | x86-64        | 2024-02-28  |
| 1.25               | サポート対象外 | 16.5                   | x86-64        | 2023-10-28  |
| 1.24               | サポート対象外 | 16.5                   | x86-64        | 2023-07-28  |
| 1.23               | サポート対象外 | 16.5                   | x86-64        | 2023-02-28  |
| 1.22               | サポート対象外 | 16.5                   | x86-64        | 2022-10-28  |

GitLab Helmチャートは、新しいマイナーKubernetesリリースを初期リリースから3か月後にサポートすることを目指しています。上記のリリースよりも新しいリリースの互換性の問題については、[イシュートラッカー](https://gitlab.com/gitlab-org/charts/gitlab/-/issues)へのご報告をお待ちしております。

一部のGitLabの機能は、非推奨のリリースや、上記のリリースよりも古いリリースでは動作しない可能性があります。

一部のコンポーネント（[Kubernetes用エージェント](https://docs.gitlab.com/user/clusters/agent/)、[GitLab Operator](https://docs.gitlab.com/operator/installation/)など）では、GitLabが異なるクラスターリリースをサポートしている場合があります。

{{< alert type="warning" >}}

Kubernetesノードは、x86-64アーキテクチャを使用する必要があります。AArch64/ARM64を含む複数のアーキテクチャのサポートは、現在開発中です。詳細については、[イシュー2899](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2899)を参照してください。

{{< /alert >}}

- 環境のクラスタートポロジに関する推奨事項については、[参照アーキテクチャ](https://docs.gitlab.com/administration/reference_architectures/#available-reference-architectures)を参照してください。
- 3つのvCPU、12GiBのクラスターに適合するようにリソースを調整する例については、[最小GKEサンプルvaluesファイル](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-gke-minimum.yaml)を参照してください。

## 特定のクラウドプロバイダー向けの手順 {#instructions-for-specific-cloud-providers}

環境内にKubernetesクラスターを作成して接続します。

- [Azure Kubernetes Service](aks.md)
- [Amazon EKS](eks.md)
- [Google Kubernetes Engine](gke.md)
- [OpenShift](openshift.md)
- [Oracle Container Engine for Kubernetes](oke.md)
