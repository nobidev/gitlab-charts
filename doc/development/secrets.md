---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Add a generated secret
---

The chart generates secrets from one declarative manifest,
`templates/shared-secrets/_manifest.tpl`. Add an entry there and both provisioning
backends pick it up. Do not add generation logic anywhere else.

## How the manifest is used

`gitlab.secrets.manifest` lists every secret the chart generates. Two templates project
that list into a backend, selected by `shared-secrets.provider`:

| Provider | Template | Result |
|----------|----------|--------|
| `job` | `templates/shared-secrets/_manifest_shell.tpl` | Shell for the pre-install and pre-upgrade hook Job |
| `controller` | `templates/shared-secrets/gitlabsecrets.yaml` | An `apps.gitlab.com/v2alpha1` `GitLabSecrets` resource |

A spec asserts both backends produce the same set of secret and key names, so an entry
that works in one works in the other.

## Add an entry

Each secret needs a name helper and a key helper. Both helpers form the contract with the
templates that consume the secret, so they must exist regardless of how the value is
generated. Add them next to the other helpers for your component, for example in
`templates/_gitaly.tpl`.

Then add one entry to the manifest:

```yaml
{{- if .Values.global.appConfig.knowledgeGraph.enabled }}
- name: {{ include "gitlab.knowledgeGraph.authToken.secret" . }}
  comment: Knowledge Graph JWT signing key
  generators:
    - type: bytes
      key: {{ include "gitlab.knowledgeGraph.authToken.key" . }}
      length: 32
      encoding: base64
{{- end }}
```

The entry above is the whole change. Under `provider: job` it becomes:

```shell
generate_secret_if_needed "RELEASE-knowledge-graph-secret" \
  --from-literal="authToken"=$(gen_random_bytes 32 | base64 -w0)
```

Under `provider: controller` it becomes an element of `spec.secrets`.

## Entry fields

| Field | Description |
|-------|-------------|
| `name` | Secret name. Always resolve it through the name helper. |
| `comment` | Label for humans. The job backend emits it as a shell comment. |
| `generators` | One or more generators. Most produce a single key. |

Wrap the entry in `{{- if }}` when the secret belongs to an optional feature. Generate a
secret only when its feature is enabled.

### A custom secret name is still filled in

A user can point the chart at a differently named Secret, usually through a `secret` value
such as `global.gitaly.authToken.secret`. That renames the Secret. It does not hand its
contents over.

Both backends still fill in missing keys, by design. A release that renamed a Secret years
ago still picks up keys added to it in later chart versions, such as a new field inside the
Rails `secrets.yml`. Skipping these secrets would break those upgrades silently.

Nothing is ever overwritten. `generate_secret_if_needed` patches in only the keys that are
absent, and the controller backend is told `policy: fill-missing`.

## Generator types

| Type | Parameters | Use for |
|------|-----------|---------|
| `random` | `key`, `charset`, `length`, `encoding`, `wrap` | Tokens and passwords |
| `bytes` | `key`, `length`, `encoding`, `file` | Random bytes rather than random characters |
| `static` | `key`, `value` | A fixed value, such as an empty placeholder |
| `rsa` | `key`, `bits`, `file` | RSA private keys |
| `x509` | `commonName`, `bits`, `days`, `certKey`, `keyKey`, `certFile`, `keyFile` | Self-signed certificate and key pairs |
| `sshHostKeys` | None | SSH host keys from `ssh-keygen -A` |
| `railsSecrets` | `key`, `env`, `fields` | The Rails `secrets.yml` document |

`charset` is one of `alphanumeric`, `hex`, or `lowerAlphanumeric`, and is required on every
`random` generator and every non-`pem` Rails field. There is no default on purpose. The
controller reads the same field, so a value the chart filled in silently would reach the
controller as absent and let it choose a different alphabet.

`encoding` is `none`, `base64`, or `base64-nowrap`. The two base64 spellings differ.
`base64` wraps at 76 columns and appends a newline. `base64-nowrap` does neither.
Existing secrets use both, so the chart keeps them distinct. Prefer `base64-nowrap` for
new secrets.

`wrap: jsonArray` stores the value as a single-element JSON array. Only the container
registry notification secret needs it.

On `bytes`, `encoding: raw` stores the bytes themselves and `encoding: base64` stores them
base64-encoded.

`file`, `certFile` and `keyFile` name scratch paths in the job's temporary directory. They
are job-backend detail and are stripped before the manifest reaches the controller. Set
`file` whenever the value has to reach `kubectl` as a file rather than a literal, which is
every `rsa` generator and any `bytes` generator using `encoding: raw`.

## Constraints

Never put shell in the manifest. Entries carry descriptors, and the job backend turns them
into commands. A `$(...)` in the manifest cannot be consumed by the controller backend,
which breaks the single source of truth.

Numbers pass through `gitlab.secrets.load`, which coerces them with `int`. Helm decodes
YAML numbers as float64 while the GitLab Operator's renderer uses int64. Without that
coercion, `length: 4096` behaves differently in each.

Generated secrets are never rotated. `generate_secret_if_needed` creates a secret once and
afterwards only patches in keys that are missing, and the controller backend declares
`policy: fill-missing` for the same reason. Adding a key to an existing secret is safe.
Changing the recipe for a key that already exists has no effect on installed releases.

## Document the secret

Add a section to [`doc/installation/secrets.md`](../installation/secrets.md) describing how
to create the secret by hand. Users who set `shared-secrets.enabled=false` create every
secret themselves and rely on that page.

## Test the change

```shell
bundle exec rspec spec/configuration/shared_secrets_spec.rb
```

To see what your entry produces:

```shell
helm template test . -f values.yaml | grep -A5 'your-secret-name'
helm template test . -f values.yaml --set shared-secrets.provider=controller
```
