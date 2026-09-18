---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: GitLabSecrets controller contract
---

When `shared-secrets.provider` is `controller`, the chart renders an
`apps.gitlab.com/v2alpha1` `GitLabSecrets` resource instead of the secret generation hook
Job. A controller must reconcile that resource into Kubernetes Secrets.

This page specifies what the chart emits and what the controller must do. The controller
and its CustomResourceDefinition live in the
[GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator) project. Until
both exist, `provider: controller` is not supported.

## Why this exists

The hook Job needs RBAC to work with Secrets. The Operator holds no permission to create
RBAC, so it works around this by running the Job under a ServiceAccount provisioned in its
own namespace at install time. That confines the Operator to managing GitLab instances
inside that namespace.

Moving generation to a resource removes both the hook and the RBAC. For more information,
see [issue 2165](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/work_items/2165).

The privilege does not disappear. It moves from a per-namespace Role into the Operator's
existing cluster-wide grant.

## What the chart renders

One resource per release, named after the release:

```yaml
apiVersion: apps.gitlab.com/v2alpha1
kind: GitLabSecrets
metadata:
  name: gitlab
  namespace: gitlab-system
spec:
  policy: fill-missing
  secrets:
    - name: gitlab-gitaly-secret
      type: Opaque
      generators:
        - type: random
          key: token
          charset: alphanumeric
          length: 64
```

Some names in `spec.secrets` may have been chosen by the user rather than derived from the
release name. A `secret` value in the chart's values renames a Secret but does not exempt it
from generation, so treat every entry the same way. `fill-missing` is what makes this safe.

## Requirements

### Do not set an owner reference

The generated Secrets must not carry an owner reference back to the `GitLabSecrets`
resource. They must not be owned by any other object the release deletes.

Kubernetes garbage collection would remove every Secret when the resource is deleted. The
loss includes `db_key_base`, which makes every encrypted column in the database permanently
unreadable. It also includes the SSH host keys, which makes every Git client report a
changed host key.

The hook Job leaves its Secrets deliberately unowned, and
[`doc/installation/uninstall.md`](../installation/uninstall.md) documents that secrets
survive `helm uninstall` for exactly this reason. The controller must preserve that.

### Never overwrite an existing value

`spec.policy: fill-missing` is the only policy the chart emits. It means:

- If the Secret does not exist, create it and generate every key.
- If the Secret exists but a declared key is absent, generate and add only that key.
- If a declared key already has a value, leave it alone.
- Never remove a key that is not declared.

The third and fourth rules matter most for Secrets a user created by hand, and for Secrets
that predate a chart version which added a key. Filling in only what is missing is what
makes those upgrades work.

This matches `generate_secret_if_needed` in the Job, and the Job's Role, which grants
`get`, `list`, `create`, and `patch` but deliberately not `update` or `delete`.

Values are not rotated. `policy` exists so a future `rotate` can be added without changing
the resource shape.

### Label the Secrets

The Job applies `gitlab.standardLabels` and `gitlab.commonLabels` to everything it creates.
The controller should apply the same labels, which it can read from the `GitLabSecrets`
resource's own `metadata.labels`.

### Report readiness

The chart's workloads mount these Secrets with projected volumes that name specific keys.
A Pod whose Secret is missing a key stays in `ContainerCreating` and repeats
`FailedMount ... references non-existent secret key`. The Pod recovers after the key
appears, but the Operator should not apply workloads before the Secrets are ready.

Report per-secret readiness in `status` so the Operator can gate reconciliation on it
rather than polling individual Secrets:

```yaml
status:
  conditions:
    - type: Ready
      status: "True"
  secrets:
    - name: gitlab-gitaly-secret
      ready: true
```

## Generator types

The chart emits these types. Each type is the declarative form of a recipe the Job performs
in shell, in `templates/shared-secrets/_manifest_shell.tpl`. Match those recipes, because
they produced the values already in the field.

### `random`

Random characters.

| Field | Description | Default |
|-------|-------------|---------|
| `key` | Key to store the value under | required |
| `charset` | `alphanumeric` (`a-zA-Z0-9`), `hex` (`a-f0-9`), or `lowerAlphanumeric` (`a-z0-9`) | required |
| `length` | Number of characters, before encoding | required |
| `encoding` | `none`, `base64`, or `base64-nowrap` | `none` |
| `wrap` | `none` or `jsonArray` | `none` |

`charset` and `length` are always present: the chart refuses to render a `random` generator
without them, so that neither backend has to guess. `encoding` and `wrap` may be absent and
mean "do not transform the value".

`base64` wraps at 76 columns and appends a trailing newline. `base64-nowrap` does neither.
Both appear in the field, so treat them as distinct.

`wrap: jsonArray` stores the value as `["<value>"]`, encoded after wrapping.

The Job's `gen_random` reads from `/dev/urandom` and filters with `tr`, which can return
fewer characters than requested for a narrow `charset`. A controller should generate exactly
`length` characters.

### `bytes`

Random bytes rather than random characters. `encoding: raw` stores the bytes themselves.
`encoding: base64` stores them base64-encoded with no line wrapping.

| Field | Description |
|-------|-------------|
| `key` | Key to store the value under |
| `length` | Number of bytes |
| `encoding` | `raw` for the bytes themselves, `base64` for a base64 string |

### `static`

A fixed value from `value`, which may be an empty string. Used for keys another component
fills in later.

### `rsa`

A PEM-encoded RSA private key of `bits` length, equivalent to `openssl genrsa <bits>`.

### `x509`

A self-signed certificate and its key, both PEM-encoded, stored in one Secret under two
keys. Equivalent to:

```shell
openssl req -new -newkey rsa:<bits> -subj "/CN=<commonName>" -nodes -x509 -days <days>
```

| Field | Description |
|-------|-------------|
| `commonName` | Certificate subject common name |
| `bits` | RSA key size |
| `days` | Validity period |
| `certKey` | Key to store the certificate under |
| `keyKey` | Key to store the private key under |

### `sshHostKeys`

SSH host keys, equivalent to `ssh-keygen -A`. Generate one key pair per supported algorithm
and store each file under its own filename, such as `ssh_host_rsa_key` and
`ssh_host_rsa_key.pub`. The key names come from the generator, not from the manifest.

### `railsSecrets`

The most intricate type. It produces a single key, `secrets.yml`, holding a YAML document
of Rails secrets nested under the Rails environment name:

```yaml
production:
  secret_key_base: <128 hex characters>
  otp_key_base: <128 hex characters>
  db_key_base: <128 hex characters>
  encrypted_settings_key_base: <128 hex characters>
  openid_connect_signing_key: |
    -----BEGIN PRIVATE KEY-----
    ...
  active_record_encryption_primary_key:
    - <32 alphanumeric characters>
  active_record_encryption_deterministic_key:
    - <32 alphanumeric characters>
  active_record_encryption_key_derivation_salt: <32 alphanumeric characters>
```

| Field | Description |
|-------|-------------|
| `key` | Key holding the document, always `secrets.yml` |
| `env` | Rails environment, the document's top-level key |
| `fields` | The fields to generate |

Each entry in `fields` has a `path`, and a `shape` of `scalar`, `pem`, or `list`. A `scalar`
uses `charset` and `length`. A `pem` uses `bits`. A `list` uses `charset` and `length` to
produce a single-element list.

Reconciliation here is per field, not per key:

- Parse the existing `secrets.yml` if the Secret exists.
- Generate a value only for fields that are absent or null.
- Preserve every field already present, including fields the manifest does not declare.
- Never shorten or reorder a list.

The two `_key` fields are lists to support key rotation: the last key encrypts and every
key decrypts, in order. Adding a key to the end and running a background re-encryption is
the supported rotation path. Truncating either list makes existing data unreadable. For
more information, see [issue 494976](https://gitlab.com/gitlab-org/gitlab/-/issues/494976).

## Certificates

`spec.certificates` is separate from `spec.secrets`. One certificate authority produces
three related Secrets rather than keys in a single Secret, so it does not fit the
per-Secret shape. The chart emits at most one entry.

```yaml
spec:
  certificates:
    - authority:
        commonName: GitLab Helm Chart
        organization: <namespace>
        organizationalUnit: <release>
        algorithm: rsa
        keySize: 4096
        expiry: 3650d
      domain: example.com
      tlsSecret: RELEASE-wildcard-tls
      caSecret: RELEASE-wildcard-tls-ca
      caKey: cfssl_ca
      chainSecret: RELEASE-wildcard-tls-chain
      chainKey: gitlab.example.com.crt
```

Create a certificate authority from `authority`, then a wildcard certificate for `domain`
signed by it, then three Secrets:

| Secret | Type | Contents |
|--------|------|----------|
| `tlsSecret` | `kubernetes.io/tls` | The wildcard certificate and its key, in `tls.crt` and `tls.key` |
| `caSecret` | `Opaque` | The authority certificate under `caKey`. Mounted into every pod's trusted bundle. |
| `chainSecret` | `Opaque` | The authority and wildcard certificates concatenated, under `chainKey`. GitLab Runner reads this. |

The entry is absent when cert-manager is configured, when a certificate is supplied through
`global.ingress.tls.secretName`, or when TLS is disabled. Under `provider: job` the same
three Secrets come from `templates/shared-secrets/self-signed-cert-job.yml`, which runs the
`cfssl-self-sign` image. Match what that image produces.

`fill-missing` applies here too: do not reissue a certificate that already exists. The Job
never renews, so renewal on expiry would be new behavior. Decide it deliberately rather
than inheriting it by accident.

## Validate the rendered resource

```shell
helm template test . -f values.yaml --set shared-secrets.provider=controller |
  kubectl apply --dry-run=server -f -
```

The chart pins `apiVersion`, so a schema change in the Operator is a breaking change for
the chart. Keep the two in step.
