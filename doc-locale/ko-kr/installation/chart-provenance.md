---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLab Helm 차트 출처 검증
---

test change

[Helm 출처 검증](https://helm.sh/docs/topics/provenance/)을 사용하여 GitLab Helm 차트의 무결성과 출처를 확인할 수 있습니다.

GitLab Helm 차트는 GNUPG 키 쌍으로 서명됩니다. 키 쌍의 공개 부분은 차트를 확인하기 전에 다운로드하고 내보내야 합니다. [GNU 개인정보 보호 핸드북](https://www.gnupg.org/gph/en/manual/x56.html)에는 GPG 키를 관리하는 방법에 대한 자세한 지침이 있습니다.

## GitLab Helm 차트 서명 키 다운로드 및 내보내기 {#download-and-export-the-gitlab-helm-chart-signing-key}

GitLab Helm 차트의 공식 공개 서명 키를 사용하여 GitLab Helm 차트의 출처를 확인해야 합니다. 키를 먼저 다운로드한 후 로컬 키링으로 내보내야 합니다.

### 공개 서명 키 다운로드 {#download-the-public-signing-key}

공식 GitLab Helm 차트 서명 키를 다운로드하려면 다음을 실행합니다:

```shell
gpg --receive-keys --keyserver hkps://keys.openpgp.org '5E46F79EF5836E986A663B4AE30F9C687683D663'
```

예시:

```shell
$ gpg --receive-keys --keyserver hkps://keys.openpgp.org '5E46F79EF5836E986A663B4AE30F9C687683D663'
gpg: key E30F9C687683D663: public key "GitLab, Inc. Helm charts <distribution@gitlab.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
```

이 명령은 키를 다운로드하여 기본 키링에 추가합니다. GitLab Helm 차트 서명 키를 별도의 키링에 넣어야 합니다. `--no-default-keyring --keyring <keyring>` `gpg` 옵션을 사용하여 GitLab 차트 서명 키만 포함하는 새 키링을 만들 수 있습니다.

예시:

```shell
$ gpg --keyring $HOME/.gnupg/gitlab.pubring.kbx --keyserver hkps://keys.openpgp.org --no-default-keyring --receive-keys '5E46F79EF5836E986A663B4AE30F9C687683D663'
gpg: keybox '$HOME/.gnupg/gitlab.pubring.kbx' created
gpg: key E30F9C687683D663: public key "GitLab, Inc. Helm charts <distribution@gitlab.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
```

### 서명 키 내보내기 {#export-the-signing-key}

기본적으로 GnuPG v2는 Helm 차트 출처 검증과 호환되지 않는 형식으로 키링을 저장합니다. Helm 차트를 확인하기 위해 키링을 레거시 형식으로 먼저 내보내야 합니다. 키링을 올바른 형식으로 내보내려면 다음 중 하나를 수행합니다:

- 기본 키링에서 내보내기:

  ```shell
  gpg --export --output gitlab.pubring.gpg '5E46F79EF5836E986A663B4AE30F9C687683D663'
  ```

- `--no-default-keyring --keyring <keyring>` 옵션을 사용하여 별도의 키링에서 키를 내보냅니다:

  ```shell
  gpg --export --output $HOME/.gnupg/gitlab.pubring.gpg  --keyring $HOME/.gnupg/gitlab.pubring.kbx  --no-default-keyring '5E46F79EF5836E986A663B4AE30F9C687683D663'
  ```

## 차트 확인 {#verify-a-chart}

GitLab Helm 차트는 다음 중 하나의 방법으로 확인할 수 있습니다:

- 차트를 다운로드하고 `helm verify`을 실행합니다.
- 차트 설치 중 `--verify` 옵션을 사용합니다.

### 다운로드한 차트 확인 {#verify-a-downloaded-chart}

`helm verify` 명령을 사용하여 다운로드한 차트를 확인할 수 있습니다. 확인 가능한 차트를 다운로드하려면 `helm pull --prov` 명령을 사용합니다. 예시:

```shell
helm pull --prov gitlab/gitlab
```

`--version` 옵션을 사용하여 특정 차트 버전을 다운로드합니다. 예시:

```shell
helm pull --prov gitlab/gitlab --version 7.9.0
```

그런 다음 `helm verify` 명령을 사용하여 다운로드한 차트를 확인할 수 있습니다.

예시:

```shell
helm verify --keyring $HOME/.gnupg/gitlab.pubring.gpg gitlab-7.9.0.tgz
Signed by: GitLab, Inc. Helm charts <distribution@gitlab.com>
Using Key With Fingerprint: 5E46F79EF5836E986A663B4AE30F9C687683D663
Chart Hash Verified: sha256:789ec56d929c7ec403fc05249639d0c48ff6ab831f90db7c6ac133534d0aba19
```

`--verify` 옵션을 `helm pull command`과 함께 사용하여 pull 및 verify 명령을 결합할 수 있습니다.

예시:

```shell
helm pull --prov gitlab/gitlab --verify --keyring $HOME/.gnupg/gitlab.pubring.gpg
Signed by: GitLab, Inc. Helm charts <distribution@gitlab.com>
Using Key With Fingerprint: 5E46F79EF5836E986A663B4AE30F9C687683D663
Chart Hash Verified: sha256:789ec56d929c7ec403fc05249639d0c48ff6ab831f90db7c6ac133534d0aba19
```

### 설치 중 차트 확인 {#verify-a-chart-during-installation}

`--verify` 옵션을 `helm install` 또는 `helm upgrade` 명령 중 하나와 함께 사용하여 설치 중에 차트를 확인할 수 있습니다.

- 예시, `helm install`:

  ```shell
  helm install --verify --keyring $HOME/.gnupg/gitlab.pubring.gpg gitlab gitlab/gitlab --set certmanager-issuer.email=<me@example.com> --set global.hosts.domain=<example.com>
  ```

- 예시, `helm upgrade`:

  ```shell
  helm upgrade --install --verify --keyring $HOME/.gnupg/gitlab.pubring.gpg gitlab gitlab/gitlab --set certmanager-issuer.email=<me@example.com> --set global.hosts.domain=<example.com>
  ```
