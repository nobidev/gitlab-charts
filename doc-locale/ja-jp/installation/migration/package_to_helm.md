---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: LinuxパッケージからHelm Chartへの移行
---

{{< details >}}

- プラン:Free, Premium, Ultimateプラン
- 提供:GitLab Self-Managed

{{< /details >}}

このガイドでは、パッケージベースのGitLabインスタンスからHelm Chartへの移行について説明します。

## 前提要件 {#prerequisites}

移行を行う前に、いくつかの前提要件を満たす必要があります。

- パッケージベースのGitLabインスタンスが起動して実行されている必要があります。`gitlab-ctl status`を実行して、サービスが`down`状態をレポートしていないことを確認します。
- 移行の前に、Gitリポジトリの[整合性をVerify](https://docs.gitlab.com/administration/raketasks/check/)することをお勧めします。
- パッケージベースのインストールと同じGitLabのバージョンを実行している、Helm Chartベースのデプロイが必要です。
- Helm Chartベースのデプロイで使用するオブジェクトストレージを設定する必要があります。本番環境で使用する場合は、[外部オブジェクトストレージ](../../advanced/external-object-storage/_index.md)を使用し、それにアクセスするための認証情報を準備しておくことをお勧めします。組み込みのMinIOサービスを使用している場合は、そこからログイン認証情報を取得する方法について、[ドキュメントをお読みください](minio.md)。

## 移行手順 {#migration-steps}

1. パッケージベースのインストールからオブジェクトストレージに既存のデータを移行します。

   1. [オブジェクトストレージに移行します](https://docs.gitlab.com/administration/object_storage/#migrate-to-object-storage)。

   1. パッケージベースのGitLabインスタンスにアクセスし、移行されたデータが利用可能であることを確認します。たとえば、ユーザー、グループ、プロジェクトのアバターが正常に表示されているか、イシューに追加された画像やその他のファイルが正しく読み込まれているかなどを確認します。

1. [バックアップtarballを作成](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/)し、[既に移行されたディレクトリをすべて除外します](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#excluding-specific-directories-from-the-backup)。

   ローカルバックアップ（デフォルト）の場合、バックアップファイルは`/var/opt/gitlab/backups`に保存されます。場所を[明示的に変更した場合](https://docs.gitlab.com/omnibus/settings/backups/#manually-manage-backup-directory)を除きます。[リモートストレージバックアップ](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/#upload-backups-to-a-remote-cloud-storage)の場合、バックアップファイルは設定されたバケットに保存されます。
1. シークレットから開始して、[パッケージベースのインストールから復元](../../backup-restore/restore.md)してHelm Chartに移行します。`/etc/gitlab/gitlab-secrets.json`の値を、Helmで使用されるYAMLファイルに移行する必要があります。
1. 変更が適用されるように、すべてのポッドを再起動します。

   ```shell
   kubectl delete pods -lrelease=<helm release name>
   ```

1. Helmベースのデプロイにアクセスし、パッケージベースのインストールに存在していたプロジェクト、グループ、ユーザー、イシューなどが復元されていることを確認します。また、アップロードされたファイル（アバター、イシューにアップロードされたファイルなど）が正常に読み込まれているかどうかを確認します。
