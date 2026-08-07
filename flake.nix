{
  # Nix dev shell + build/test/cluster helpers for the GitLab Helm chart.
  #
  # This flake is an ADDITIVE layer over the existing mise/RSpec/CI workflow —
  # none of which change. Enter the dev shell with `nix develop`; every command
  # also works standalone (e.g. `nix run .#cluster-up`).
  #
  # It is split into a PURE half (cacheable, cluster-free, validated by
  # `nix flake check`) and an IMPURE half (effects against a live cluster, run
  # as thin `nix run .#…` shell apps):
  #
  #   Pure packages (no cluster, no network at eval time):
  #     packages.chart-deps     the chart's remote subcharts, fetched in a
  #                             fixed-output derivation (the one place Nix
  #                             allows network access).
  #     packages.gitlab-chart   a writable chart tree with the subcharts
  #                             overlaid into charts/, ready to template/package.
  #     packages.gitlab-chart-tgz  the `helm package`d tarball of that tree; THIS
  #                             is what the GitLab Operator consumes (via
  #                             `inputs.gitlab-charts.packages.gitlab-chart-tgz`)
  #                             to bundle the local chart into its dev image.
  #     packages.rendered       `helm template` output, rendered offline.
  #
  #   Impure apps: `cluster-up` / `cluster-down` — backend-agnostic
  #     (k3d | minikube | kind, default k3d via CLUSTER_BACKEND).
  #
  # Shared logic lives here (charts is the source of truth) and is exported for
  # the operator to reuse: `flake.lib` (portable render/package helpers) and
  # `flake.flakeModules` (the cluster + devshell flake-parts modules).
  description = "GitLab Helm chart — reproducible dev shell + build/test/cluster via Nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";

    # Dev-shell + build tools resolved from the existing mise.toml (single-sourced).
    # See https://gitlab.com/sbordei/tool2nix
    tool2nix.url = "gitlab:sbordei/tool2nix";
    tool2nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

      imports = [
        ./nix/args.nix # shared perSystem args: mise / helm / chartsLib
        ./nix/dev-values.nix # shared deploy-config DATA (devValues); before packages.nix
        ./nix/devshell.nix
        ./nix/packages.nix
        ./nix/checks.nix
        ./nix/cluster.nix
        ./nix/devstack.nix
      ];

      # Flake-level, non-per-system outputs shared with the operator.
      flake =
        let
          chartsLib = import ./nix/lib.nix;
        in
        {
          # Portable, flake-parts-free helper library (render/package the chart).
          # Consumed by the operator as `inputs.gitlab-charts.lib`. Being
          # flake-agnostic (plain functions, no flake-parts), it is the surface
          # the operator's flake-utils flake reads. What the operator actually
          # consumes from it: `chartDeps`/`packagedChart`/`renderChart` (to render
          # its own operator chart without a second copy of that plumbing),
          # `mkDevValues` (its GitLab-CR values + the Envoy Gateway version, with
          # its own overrides), and `chartVersion` — the chart's own version
          # parsed from Chart.yaml at eval time, used as the default chart version
          # to deploy. (Nested under `lib` because a bare top-level output would
          # be an "unknown flake output".)
          lib = chartsLib // {
            chartVersion = chartsLib.chartVersionFrom {
              lib = inputs.nixpkgs.lib;
              chartYamlPath = ./Chart.yaml;
            };
          };

          # Reusable flake-parts modules. The operator can `imports = [ … ]` these
          # after adding `inputs.gitlab-charts` (both flakes already provide the
          # nixpkgs + tool2nix inputs these modules read).
          flakeModules = {
            cluster = ./nix/cluster.nix; # self-contained cluster lifecycle
            devshell = ./nix/devshell.nix; # charts-bound (Ruby) — see README caveat
            devValues = ./nix/dev-values.nix; # shared deploy-config DATA
            # nix/devstack.nix (the up/down apps) is intentionally NOT exported:
            # it hardcodes this repo's dev flow, so it is not reusable. The
            # operator reuses `devValues` and writes its own deploy app.
          };
        };
    };
}
