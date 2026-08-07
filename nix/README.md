# Nix workflow

The root flake is an **additive** layer over the existing mise/RSpec/CI
workflow — a reproducible dev shell plus pure build artifacts and a couple of
impure cluster helpers. Nothing about the existing workflow changes.

Enter the shell with `nix develop`. Every command also works standalone
(e.g. `nix run .#cluster-up`, `nix build .#gitlab-chart`).

The flake is built with [flake-parts](https://flake.parts) and split into a
**pure** half (cacheable, cluster-free, validated by `nix flake check`) and an
**impure** half (effects against a live cluster, run as `nix run .#…` apps).

## Prerequisites

Nix with flakes enabled. Install Nix by following the docs for your OS
([nixos.org/download](https://nixos.org/download)). On **non-NixOS** systems
(macOS / other Linux), enable flakes by adding
`experimental-features = nix-command flakes` to `~/.config/nix/nix.conf` (see the
[Flakes docs](https://nix.dev/concepts/flakes)); on NixOS, enable them in your
system configuration instead.

## Layout

| File | Role |
| --- | --- |
| `flake.nix` | flake-parts entry; wires the modules; exports `lib` + `flakeModules` |
| `nix/lib.nix` | portable helpers (chart deps / package / render) — no flake deps |
| `nix/args.nix` | shared perSystem args (`mise`, `helm`, `chartsLib`) |
| `nix/devshell.nix` | `nix develop` shell (mise tools + Ruby) |
| `nix/packages.nix` | `chart-deps`, `gitlab-chart`, `gitlab-chart-tgz`, `rendered` |
| `nix/checks.nix` | `nix flake check` — offline render validation |
| `nix/cluster.nix` | backend-agnostic `cluster-up` / `cluster-down` (bare lifecycle) |
| `nix/dev-values.nix` | shared deploy-config **data** (`devValues`: `cfg`, `deployValues`, render values) — reusable |
| `nix/devstack.nix` | charts-specific full-stack `up` / `down` **apps** (cluster + deps + GitLab) |

## Which command do I use?

| Goal | Command |
| --- | --- |
| Dev shell | `nix develop` |
| Fetched subcharts (FOD) | `nix build .#chart-deps` |
| Packaged chart (subcharts overlaid) | `nix build .#gitlab-chart` |
| Rendered manifests (offline) | `nix build .#rendered` |
| Validate render offline (CI-equivalent) | `nix flake check` |
| **Local GitLab, one command** | `nix run .#up` |
| Tear the whole devstack down | `nix run .#down` |
| Bare cluster (no GitLab) | `nix run .#cluster-up` / `.#cluster-down` |

## One command → local GitLab (`nix run .#up`)

From the **chart repo root**:

```bash
nix run .#up      # k3d cluster → external deps → deploy GitLab (working tree)
nix run .#down    # uninstall GitLab → remove deps → delete the cluster
```

`up` is an additive wrapper over the existing local-dev flow (see
[doc/development/external-dependencies.md](../doc/development/external-dependencies.md)):

1. Creates a **k3d** cluster with `80/443` (plus host `32022 → 22` for
   git-over-SSH) mapped to the built-in klipper LoadBalancer, and **k3s's
   bundled Traefik disabled** (it otherwise owns the Gateway API CRDs and ports
   80/443). Reuses an existing cluster of the same name (port maps apply at
   create time only; recreate to change them).
2. Runs `scripts/dev_dependencies.sh setup` — provisions **Valkey** (Redis),
   **CloudNativePG** (Postgres) and **Garage** (object storage), and writes
   `.values/dev-external.values.yaml`.
3. Creates a **self-signed wildcard TLS secret** (`gitlab-tls`) for the domain,
   so the front door has TLS without cert-manager/ACME.
4. `helm dependency update` + `helm upgrade --install` of the **working tree**
   chart. The chart bundles **Envoy Gateway** (`installEnvoy=true`, the upstream
   default model): it installs the Envoy Gateway controller and CRDs and creates
   the matching **`GatewayClass`** itself. The deploy layers the generated
   external-deps values with the dev overlay from `nix/dev-values.nix`
   (`deployValues`: Gateway API front door, all Gateway listeners pointed at the
   one self-signed secret, single replicas, prometheus/runner off), then any
   files listed in `GITLAB_EXTRA_VALUES` last (see Overrides below).
5. Prints the URL + how to read the initial root password.

> [!IMPORTANT]
> `up` deploys the **working-tree** chart with `helm`. Keep nix build artifacts
> out of the chart: `.helmignore` excludes `result*` / `flake.*` / `nix/`.
> A stray `./result` symlink (from `nix build`) would otherwise be followed by
> Helm and its contents bundled into the release, blowing the Secret size cap.

The domain defaults to **`<host-ip>.nip.io`** (auto-detected, like the operator),
so `https://gitlab.<ip>.nip.io` reaches GitLab through the k3d LoadBalancer.

Overrides: `GITLAB_DOMAIN` (whole domain), `GITLAB_LOCAL_IP` (IP only),
`GITLAB_EMAIL`, `NAMESPACE`, `CLUSTER_NAME`, `GITLAB_SSH_PORT` (git-over-SSH host
port, default `32022`; sets both the k3d host mapping and the advertised
`global.shell.port`, applied at cluster create time), and `GITLAB_EXTRA_VALUES`, a
space-separated list of your own values files, appended as trailing `helm -f`
flags **after** the dev overlay so they win over it (the runtime `--set`
values `global.hosts.domain` and `certmanager-issuer.email` still take
precedence over any file):

```bash
echo 'gitlab-runner: { install: true }' > runner.yaml
GITLAB_EXTRA_VALUES="runner.yaml" nix run .#up          # single file
GITLAB_EXTRA_VALUES="runner.yaml sizing.yaml" nix run .#up   # layered, last wins
```

The dev values overlay lives in one place (`devValues.deployValues`, defined in
`nix/dev-values.nix`) so the same config can feed either this direct
`helm install` or, in the operator repo, a GitLab CR's `spec.chart.values`.

> [!NOTE]
> **First cut: k3d only, Envoy Gateway front door, self-signed TLS.** The cert
> is self-signed (browser warning expected). If `<ip>.nip.io` isn't reachable,
> port-forward the Envoy LB service (the command is printed at the end of `up`).
> minikube/kind full-stack variants are a later iteration; the bare
> `cluster-up`/`cluster-down` lifecycle stays backend-agnostic regardless.

## Cluster backend

`cluster-up` / `cluster-down` are backend-agnostic. Select the backend at
runtime; **k3d** is the default (mirrors CI).

```bash
nix run .#cluster-up                      # k3d
CLUSTER_BACKEND=minikube nix run .#cluster-up
CLUSTER_BACKEND=kind CLUSTER_NAME=dev nix run .#cluster-up
```

A container runtime (docker / colima / podman) must be running on the host —
the flake does not pull one into the closure.

## Tools (mise + tool2nix)

Both the dev shell and the pure `helm` render resolve their tools from
`mise.toml` via `tool2nix` (`packagesAttrsFrom`), so they share one set.

Caveats (same as the operator's flake):

- `tool2nix` maps mise tools to **nixpkgs** attributes, so versions track
  nixpkgs, not the exact mise pin.
- `yq` resolves to the Python yq; the dev shell also puts `yq-go` on PATH for
  the Go `yq` the chart tooling expects.
- Ruby is **not** in `mise.toml`, so `ruby`/`bundler` are added directly in
  `nix/devshell.nix` for the RSpec/rubocop/danger suite. Run tests the usual
  way inside the shell: `bundle install && bundle exec rspec`.

## Re-bootstrapping the chart-deps hash

`packages.chart-deps` is a fixed-output derivation. When `Chart.lock` changes,
refresh its hash: set `outputHash` to `pkgs.lib.fakeHash` in `nix/packages.nix`
(already the case on first setup), run `nix build .#chart-deps`, and paste the
`got: sha256-…` value Nix prints back in.

## Sharing with the GitLab Operator

Charts is the source of truth, so the shared Nix logic lives here:

- **`inputs.gitlab-charts.lib`** — the portable `nix/lib.nix` helpers, all
  flake-agnostic so the operator's **flake-utils** flake consumes them directly:
  - `chartDeps` / `packagedChart` / `renderChart` — the operator renders its OWN
    operator chart with these (no second copy of the FOD-fetch + offline-render
    plumbing); see the operator's `nix/manifests.nix`.
  - `chartVersion` — the chart's own version (parsed from `Chart.yaml` at eval
    time), used by the operator as the default chart version to deploy.
  - **`mkDevValues { pkgs, cfgOverrides ? {}, valuesOverrides ? {} }`** — the
    shared local-deploy config (`cfg`, `tlsListeners`, `deployValues`, render
    values), overridable. The operator reuses `deployValues` as its GitLab CR
    base, stating only its divergences:

    ```nix
    # operator flake.nix (flake-utils)
    chartsDev = inputs.gitlab-charts.lib.mkDevValues {
      inherit pkgs;
      cfgOverrides = { namespace = "gitlab-system"; tlsSecretName = "custom-gitlab-tls"; };
    };
    # spec.chart.values = recursiveUpdate chartsDev.deployValues operatorOverrides
    ```

- **`inputs.gitlab-charts.packages.gitlab-chart-tgz`** — the chart as a
  `helm package`d `gitlab-<version>.tgz` (in a directory). The operator bundles
  this into its dev image's `/charts` so its `nix run .#up` deploys the
  **working-tree** chart end-to-end (no fetch from `charts.gitlab.io`), with the
  CR pinned to `lib.chartVersion`. (`packages.gitlab-chart` is the same chart as
  an unpacked tree, available for other consumers.)
- **`inputs.gitlab-charts.flakeModules.devValues`** — the same deploy-config
  data as a **flake-parts** module (thin wrapper over `lib.mkDevValues`). Only
  useful to a *flake-parts* consumer that wants `devValues` as a `perSystem`
  arg. The operator uses `lib.mkDevValues` above, **not** this — flake-parts
  modules don't compose into a flake-utils flake.
- **`inputs.gitlab-charts.flakeModules.{cluster,devshell}`** — importable
  flake-parts modules (`cluster` is self-contained; `devshell` is charts-bound
  via its Ruby toolchain). Same flake-parts-only caveat applies.

The `up` / `down` apps in `nix/devstack.nix` are **charts-specific** and
deliberately not exported: they hardcode this repo's dev flow
(`scripts/dev_dependencies.sh`, working-tree `helm upgrade --install .`, k3d).
The operator writes its own deploy app of the same shape, swapping the deploy
step for a GitLab CR apply. It DOES reuse `deployValues` as its CR base (via
`mkDevValues` above) and only overrides its divergences through
`recursiveUpdate` (kind NodePort vs k3d LoadBalancer, its own TLS secret names,
pages enabled). So the shared base stays authoritative for sizing, disabled
extras, the Gateway front door, and the listener set, and the operator carries
only its deltas.

Local dual-repo development uses a path override, no publish needed:

```bash
# from the operator checkout
nix develop --override-input gitlab-charts path:../gitlab-charts
nix build .#operator-manifest --override-input gitlab-charts path:../gitlab-charts
```
