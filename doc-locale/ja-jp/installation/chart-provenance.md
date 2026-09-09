---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Helm GitLabチャートのプロベナンス
---

[Helm来歴](https://helm.sh/docs/topics/provenance/)を使用することにより、GitLab Helmチャートの整合性と起源を検証できます。

GitLab Helmチャートは、GNUPGキーペアで署名されています。チャートを検証するには、キーペアの公開部分をダウンロードし、場合によってはエクスポートする必要があります。[GNU Privacyハンドブック](https://www.gnupg.org/gph/en/manual/x56.html)には、GPGキーを管理する方法が詳しく記載されています。

## GitLab Helmチャート署名キーをダウンロードしてエクスポートする {#download-and-export-the-gitlab-helm-chart-signing-key}

公式のGitLab Helmチャート公開署名キーは、GitLab Helmチャートのプロベナンスを検証するために使用する必要があります。キーは、最初にダウンロードしてから、ローカルキーリングにエクスポートする必要があります。

### 公開署名キーをダウンロードする {#download-the-public-signing-key}

公式のGitLab Helmチャート署名キーをダウンロードするには、以下を実行します:

```shell
gpg --receive-keys --keyserver hkps://keys.openpgp.org '5E46F79EF5836E986A663B4AE30F9C687683D663'
```

例: 

```shell
$ gpg --receive-keys --keyserver hkps://keys.openpgp.org '5E46F79EF5836E986A663B4AE30F9C687683D663'
gpg: key E30F9C687683D663: public key "GitLab, Inc. Helm charts <distribution@gitlab.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
```

このコマンドはキーをダウンロードし、デフォルトのキーリングに追加します。GitLab Helmチャート署名キーを個別のキーリングに配置する必要があります。`--no-default-keyring --keyring <keyring>` `gpg`オプションを使用して、GitLabチャート署名キーのみを含む新しいキーリングを作成できます。

例: 

```shell
$ gpg --keyring $HOME/.gnupg/gitlab.pubring.kbx --keyserver hkps://keys.openpgp.org --no-default-keyring --receive-keys '5E46F79EF5836E986A663B4AE30F9C687683D663'
gpg: keybox '$HOME/.gnupg/gitlab.pubring.kbx' created
gpg: key E30F9C687683D663: public key "GitLab, Inc. Helm charts <distribution@gitlab.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
```

### 署名キーをエクスポートする {#export-the-signing-key}

デフォルトでは、GnuPG v2は、Helmチャートのプロベナンス検証と互換性のない形式でキーリングを格納します。Helmチャートを検証するために使用する前に、キーリングをレガシー形式にエクスポートする必要があります。キーリングを適切な形式でエクスポートするには、次のいずれかの操作を行います:

- デフォルトのキーリングからエクスポートします:

  ```shell
  gpg --export --output gitlab.pubring.gpg '5E46F79EF5836E986A663B4AE30F9C687683D663'
  ```

- `--no-default-keyring --keyring <keyring>`オプションを使用して、個別のキーリングからキーをエクスポートします:

  ```shell
  gpg --export --output $HOME/.gnupg/gitlab.pubring.gpg  --keyring $HOME/.gnupg/gitlab.pubring.kbx  --no-default-keyring '5E46F79EF5836E986A663B4AE30F9C687683D663'
  ```

## チャートを検証する {#verify-a-chart}

GitLab Helmチャートは、次のいずれかの方法で検証できます:

- チャートをダウンロードして、`helm verify`を実行する。
- チャートのインストール中に`--verify`オプションを使用する。

### ダウンロードしたチャートを検証する {#verify-a-downloaded-chart}

`helm verify`コマンドを使用して、ダウンロードしたチャートを検証できます。検証可能なチャートをダウンロードするには、`helm pull --prov`コマンドを使用します。例: 

```shell
helm pull --prov gitlab/gitlab
```

`--version`オプションを使用して、指定されたチャートのバージョンをダウンロードします。例: 

```shell
helm pull --prov gitlab/gitlab --version 7.9.0
```

次に、`helm verify`コマンドを使用して、ダウンロードしたチャートを検証できます。

例: 

```shell
helm verify --keyring $HOME/.gnupg/gitlab.pubring.gpg gitlab-7.9.0.tgz
Signed by: GitLab, Inc. Helm charts <distribution@gitlab.com>
Using Key With Fingerprint: 5E46F79EF5836E986A663B4AE30F9C687683D663
Chart Hash Verified: sha256:789ec56d929c7ec403fc05249639d0c48ff6ab831f90db7c6ac133534d0aba19
```

`--verify`オプションと`helm pull command`を使用して、プルコマンドと検証コマンドを組み合わせることができます。

例: 

```shell
helm pull --prov gitlab/gitlab --verify --keyring $HOME/.gnupg/gitlab.pubring.gpg
Signed by: GitLab, Inc. Helm charts <distribution@gitlab.com>
Using Key With Fingerprint: 5E46F79EF5836E986A663B4AE30F9C687683D663
Chart Hash Verified: sha256:789ec56d929c7ec403fc05249639d0c48ff6ab831f90db7c6ac133534d0aba19
```

### インストール中にチャートを検証する {#verify-a-chart-during-installation}

`--verify`オプションを`helm install`または`helm upgrade`コマンドのいずれかで使用して、インストール中にチャートを検証できます。

- たとえば、`helm install`を選択します:

  ```shell
  helm install --verify --keyring $HOME/.gnupg/gitlab.pubring.gpg gitlab gitlab/gitlab --set certmanager-issuer.email=<me@example.com> --set global.hosts.domain=<example.com>
  ```

- たとえば、`helm upgrade`を選択します:

  ```shell
  helm upgrade --install --verify --keyring $HOME/.gnupg/gitlab.pubring.gpg gitlab gitlab/gitlab --set certmanager-issuer.email=<me@example.com> --set global.hosts.domain=<example.com>
  ```
