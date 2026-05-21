---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Provenance du chart Helm GitLab
---

Vous pouvez vérifier l'intégrité et l'origine des charts Helm GitLab en utilisant [Helm provenance](https://helm.sh/docs/topics/provenance/).

Les charts Helm GitLab sont signés avec une paire de clés GNUPG. La partie publique de la paire de clés doit être téléchargée et éventuellement exportée avant de pouvoir être utilisée pour vérifier les charts. Le [GNU Privacy Handbook](https://www.gnupg.org/gph/en/manual/x56.html) contient des instructions détaillées sur la gestion des clés GPG.

## Télécharger et exporter la clé de signature du chart Helm GitLab {#download-and-export-the-gitlab-helm-chart-signing-key}

La clé de signature publique officielle du chart Helm GitLab doit être utilisée pour vérifier la provenance des charts Helm GitLab. La clé doit d'abord être téléchargée, puis éventuellement exportée dans un trousseau local.

### Télécharger la clé de signature publique {#download-the-public-signing-key}

Pour télécharger la clé de signature officielle du chart Helm GitLab, exécutez :

```shell
gpg --receive-keys --keyserver hkps://keys.openpgp.org '5E46F79EF5836E986A663B4AE30F9C687683D663'
```

Par exemple :

```shell
$ gpg --receive-keys --keyserver hkps://keys.openpgp.org '5E46F79EF5836E986A663B4AE30F9C687683D663'
gpg: key E30F9C687683D663: public key "GitLab, Inc. Helm charts <distribution@gitlab.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
```

Cette commande télécharge la clé et l'ajoute à votre trousseau par défaut. Vous devriez placer la clé de signature du chart Helm GitLab dans un trousseau séparé. Vous pouvez utiliser les options `--no-default-keyring --keyring <keyring>` `gpg` pour créer un nouveau trousseau contenant uniquement la clé de signature du chart GitLab.

Par exemple :

```shell
$ gpg --keyring $HOME/.gnupg/gitlab.pubring.kbx --keyserver hkps://keys.openpgp.org --no-default-keyring --receive-keys '5E46F79EF5836E986A663B4AE30F9C687683D663'
gpg: keybox '$HOME/.gnupg/gitlab.pubring.kbx' created
gpg: key E30F9C687683D663: public key "GitLab, Inc. Helm charts <distribution@gitlab.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
```

### Exporter la clé de signature {#export-the-signing-key}

Par défaut, GnuPG v2 stocke les trousseaux dans un format incompatible avec la vérification de provenance des charts Helm. Vous devez d'abord exporter le trousseau au format hérité avant de pouvoir l'utiliser pour vérifier un chart Helm. Pour exporter le trousseau dans le format approprié, effectuez l'une des opérations suivantes :

- Exporter depuis le trousseau par défaut :

  ```shell
  gpg --export --output gitlab.pubring.gpg '5E46F79EF5836E986A663B4AE30F9C687683D663'
  ```

- Utilisez les options `--no-default-keyring --keyring <keyring>` pour exporter la clé depuis un trousseau séparé :

  ```shell
  gpg --export --output $HOME/.gnupg/gitlab.pubring.gpg  --keyring $HOME/.gnupg/gitlab.pubring.kbx  --no-default-keyring '5E46F79EF5836E986A663B4AE30F9C687683D663'
  ```

## Vérifier un chart {#verify-a-chart}

Un chart Helm GitLab peut être vérifié de l'une ou l'autre des façons suivantes :

- Télécharger le chart et exécuter `helm verify`.
- Utiliser l'option `--verify` lors de l'installation du chart.

### Vérifier un chart téléchargé {#verify-a-downloaded-chart}

Vous pouvez utiliser la commande `helm verify` pour vérifier un chart téléchargé. Pour télécharger un chart vérifiable, utilisez la commande `helm pull --prov`. Par exemple :

```shell
helm pull --prov gitlab/gitlab
```

Utilisez l'option `--version` pour télécharger une version de chart spécifique. Par exemple :

```shell
helm pull --prov gitlab/gitlab --version 7.9.0
```

Vous pouvez ensuite utiliser la commande `helm verify` pour vérifier le chart téléchargé.

Par exemple :

```shell
helm verify --keyring $HOME/.gnupg/gitlab.pubring.gpg gitlab-7.9.0.tgz
Signed by: GitLab, Inc. Helm charts <distribution@gitlab.com>
Using Key With Fingerprint: 5E46F79EF5836E986A663B4AE30F9C687683D663
Chart Hash Verified: sha256:789ec56d929c7ec403fc05249639d0c48ff6ab831f90db7c6ac133534d0aba19
```

Vous pouvez combiner les commandes pull et verify en utilisant l'option `--verify` avec la `helm pull command`.

Par exemple :

```shell
helm pull --prov gitlab/gitlab --verify --keyring $HOME/.gnupg/gitlab.pubring.gpg
Signed by: GitLab, Inc. Helm charts <distribution@gitlab.com>
Using Key With Fingerprint: 5E46F79EF5836E986A663B4AE30F9C687683D663
Chart Hash Verified: sha256:789ec56d929c7ec403fc05249639d0c48ff6ab831f90db7c6ac133534d0aba19
```

### Vérifier un chart lors de l'installation {#verify-a-chart-during-installation}

Vous pouvez vérifier un chart lors de l'installation en utilisant l'option `--verify` avec la commande `helm install` ou `helm upgrade`.

- Par exemple, `helm install` :

  ```shell
  helm install --verify --keyring $HOME/.gnupg/gitlab.pubring.gpg gitlab gitlab/gitlab --set certmanager-issuer.email=<me@example.com> --set global.hosts.domain=<example.com>
  ```

- Par exemple, `helm upgrade` :

  ```shell
  helm upgrade --install --verify --keyring $HOME/.gnupg/gitlab.pubring.gpg gitlab gitlab/gitlab --set certmanager-issuer.email=<me@example.com> --set global.hosts.domain=<example.com>
  ```
