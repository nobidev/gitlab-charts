---
stage: GitLab Delivery
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: GitLab Helmチャートのprovenance
---

[Helm provenance](https://helm.sh/docs/topics/provenance/)を使用すると、GitLab Helmチャートの整合性とoriginを検証できます。

GitLab Helmチャートは、GNUPGキーペアで署名されています。チャートを検証するには、キーペアの公開部分をダウンロードし、エクスポートが必要になる場合があります。[GNU Privacy Handbook](https://www.gnupg.org/gph/en/manual/x56.html)には、GPGキーの管理方法に関する詳細な手順が記載されています。

## GitLab Helmチャート署名キーのダウンロードとエクスポート {#download-and-export-the-gitlab-helm-chart-signing-key}

GitLab Helmチャートのprovenanceを検証するには、公式のGitLab Helm Chart公開署名キーを使用する必要があります。キーは、最初にダウンロードしてから、ローカルのキーリングにエクスポートが必要になる場合があります。

### 公開署名キーのダウンロード {#download-the-public-signing-key}

公式のGitLab Helmチャート署名キーをダウンロードするには、以下を実行します。

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

このコマンドはキーをダウンロードし、defaultのキーリングに追加します。GitLab Helmチャート署名キーは、別のキーリングに配置する必要があります。`--no-default-keyring --keyring <keyring>` `gpg`オプションを使用すると、GitLab Chart署名キーのみを含む新しいキーリングを作成できます。

例:

```shell
$ gpg --keyring $HOME/.gnupg/gitlab.pubring.kbx --keyserver hkps://keys.openpgp.org --no-default-keyring --receive-keys '5E46F79EF5836E986A663B4AE30F9C687683D663'
gpg: keybox '$HOME/.gnupg/gitlab.pubring.kbx' created
gpg: key E30F9C687683D663: public key "GitLab, Inc. Helm charts <distribution@gitlab.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
```

### 署名キーのエクスポート {#export-the-signing-key}

defaultでは、GnuPG v2は、Helmチャートのprovenance検証と互換性のない形式でキーリングを保存します。Helmチャートを検証するには、最初にキーリングをレガシー形式にエクスポートする必要があります。キーリングを適切な形式にエクスポートするには、次のいずれかの操作を行います。

- defaultキーリングからエクスポートします。

  ```shell
  gpg --export --output gitlab.pubring.gpg '5E46F79EF5836E986A663B4AE30F9C687683D663'
  ```

- `--no-default-keyring --keyring <keyring>`オプションを使用して、別のキーリングからキーをエクスポートします。

  ```shell
  gpg --export --output $HOME/.gnupg/gitlab.pubring.gpg  --keyring $HOME/.gnupg/gitlab.pubring.kbx  --no-default-keyring '5E46F79EF5836E986A663B4AE30F9C687683D663'
  ```

## チャートの検証 {#verify-a-chart}

GitLab Helmチャートは、次のいずれかの方法で検証できます。

- チャートをダウンロードして`helm verify`を実行する。
- チャートのインストール中に`--verify`オプションを使用する。

### ダウンロードしたチャートの検証 {#verify-a-downloaded-chart}

`helm verify`コマンドを使用して、ダウンロードしたチャートを検証できます。検証可能なチャートをダウンロードするには、`helm pull --prov`コマンドを使用します。例:

```shell
helm pull --prov gitlab/gitlab
```

`--version`オプションを使用して、特定のチャートバージョンをダウンロードします。例:

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

`--verify`オプションと`helm pull command`を使用して、pullコマンドとverifyコマンドを組み合わせることができます。

例:

```shell
helm pull --prov gitlab/gitlab --verify --keyring $HOME/.gnupg/gitlab.pubring.gpg
Signed by: GitLab, Inc. Helm charts <distribution@gitlab.com>
Using Key With Fingerprint: 5E46F79EF5836E986A663B4AE30F9C687683D663
Chart Hash Verified: sha256:789ec56d929c7ec403fc05249639d0c48ff6ab831f90db7c6ac133534d0aba19
```

### インストール中のチャートの検証 {#verify-a-chart-during-installation}

`--verify`オプションを`helm install`または`helm upgrade`コマンドのいずれかで使用して、インストール中にチャートを検証できます。

- 例：`helm install`:

  ```shell
  helm install --verify --keyring $HOME/.gnupg/gitlab.pubring.gpg gitlab gitlab/gitlab --set certmanager-issuer.email=<me@example.com> --set global.hosts.domain=<example.com>
  ```

- 例：`helm upgrade`:

  ```shell
  helm upgrade --install --verify --keyring $HOME/.gnupg/gitlab.pubring.gpg gitlab gitlab/gitlab --set certmanager-issuer.email=<me@example.com> --set global.hosts.domain=<example.com>
  ```
