# Backend-agnostic local cluster helpers (impure — they touch a live cluster).
#
#   nix run .#cluster-up     create a local cluster
#   nix run .#cluster-down   delete it
#
# The backend is chosen at runtime via CLUSTER_BACKEND (k3d | minikube | kind),
# defaulting to k3d to mirror the CI review-app path. CLUSTER_NAME overrides the
# cluster name. This module is self-contained (it computes its own tools from
# inputs) so the operator can import it directly as a flake-parts module via
# `inputs.gitlab-charts.flakeModules.cluster`.
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      lib = pkgs.lib;
      mise = inputs.tool2nix.lib.packagesAttrsFrom pkgs ../mise.toml;

      cfg = {
        clusterName = "gitlab";
      };

      # All three backends on PATH; the app selects one at runtime. The daemon
      # (docker/colima/podman) is assumed to be provided by the host — we do not
      # pull a container runtime into the closure.
      backendTools = [
        pkgs.k3d
        mise.minikube
        pkgs.kind
      ];
      commonTools = [
        pkgs.bash
        pkgs.kubectl
        pkgs.coreutils
      ];

      mkApp = drv: {
        type = "app";
        program = lib.getExe drv;
      };

      clusterUp = pkgs.writeShellApplication {
        name = "cluster-up";
        runtimeInputs = backendTools ++ commonTools;
        text = ''
          backend="''${CLUSTER_BACKEND:-k3d}"
          name="''${CLUSTER_NAME:-${cfg.clusterName}}"
          echo "Creating '$name' cluster via $backend…"
          case "$backend" in
            k3d)      k3d cluster create "$name" ;;
            minikube) minikube start -p "$name" ;;
            kind)     kind create cluster --name "$name" ;;
            *) echo "unknown CLUSTER_BACKEND=$backend (expected k3d|minikube|kind)" >&2; exit 1 ;;
          esac
          kubectl cluster-info
        '';
      };

      clusterDown = pkgs.writeShellApplication {
        name = "cluster-down";
        runtimeInputs = backendTools;
        text = ''
          backend="''${CLUSTER_BACKEND:-k3d}"
          name="''${CLUSTER_NAME:-${cfg.clusterName}}"
          echo "Deleting '$name' cluster via $backend…"
          case "$backend" in
            k3d)      k3d cluster delete "$name" ;;
            minikube) minikube delete -p "$name" ;;
            kind)     kind delete cluster --name "$name" ;;
            *) echo "unknown CLUSTER_BACKEND=$backend (expected k3d|minikube|kind)" >&2; exit 1 ;;
          esac
        '';
      };
    in
    {
      apps.cluster-up = mkApp clusterUp;
      apps.cluster-down = mkApp clusterDown;
    };
}
