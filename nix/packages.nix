# Pure build artifacts you can inspect/cache/diff without a cluster.
#
#   nix build .#chart-deps      → the fetched subchart tarballs (FOD)
#   nix build .#gitlab-chart    → the packaged chart (subcharts overlaid)
#   nix build .#rendered        → offline `helm template` output
#
# `chart-deps` is a fixed-output derivation; bootstrap its hash with the
# fakeHash procedure (see nix/lib.nix / nix/README.md) whenever Chart.lock
# changes.
{ ... }:
{
  perSystem =
    {
      pkgs,
      helm,
      chartsLib,
      devValues,
      ...
    }:
    let
      deps = chartsLib.chartDeps {
        inherit pkgs helm;
        chartSrc = ../.;
        # Bootstrap: replace with the real hash from `nix build .#chart-deps`.
        outputHash = "sha256-sjIgfRjwE4F0b1revoiLJeeYtbgN7L+PplsQ+3dbT5Q=";
      };
      chart = chartsLib.packagedChart {
        inherit pkgs deps;
        chartSrc = ../.;
      };
    in
    {
      packages = {
        chart-deps = deps;
        gitlab-chart = chart;
        # `helm package`d tarball of the working-tree chart (dir with one
        # gitlab-<version>.tgz). The operator bundles THIS into its dev image's
        # /charts so `nix run .#up` there deploys the local chart, no fetch.
        gitlab-chart-tgz = chartsLib.packageChartTarball { inherit pkgs helm chart; };
        # Offline render for the pure smoke check. Uses the placeholder dev
        # values from nix/dev-values.nix (dummy external-service connections) —
        # just enough for the chart to template without a cluster.
        rendered = chartsLib.renderChart {
          inherit pkgs helm chart;
          name = devValues.cfg.releaseName;
          namespace = devValues.cfg.namespace;
          extraArgs = "-f ${devValues.renderValuesFile}";
        };
        # The chart version as a file, for shell/CI use (`cat $(nix build --print-out-paths .#chart-version)`).
        chart-version = pkgs.writeText "chart-version" (chartsLib.chartVersionFrom {
          inherit (pkgs) lib;
          chartYamlPath = ../Chart.yaml;
        });
        default = chart;
      };
    };
}
