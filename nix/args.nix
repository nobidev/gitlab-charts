# Shared perSystem module args, so every other module reads one set of tools.
#
# - `mise`      — the mise.toml-pinned tools resolved through tool2nix.
# - `helm`      — the same helm the dev shell uses (mise.helm), so the pure
#                 render matches the interactive shell.
# - `chartsLib` — the portable helper library (nix/lib.nix).
#
# Defined once here; flake-parts merges it into the per-system submodule so
# devshell.nix / packages.nix / checks.nix all receive these as function args.
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      mise = inputs.tool2nix.lib.packagesAttrsFrom pkgs ../mise.toml;
    in
    {
      _module.args = {
        inherit mise;
        helm = mise.helm;
        chartsLib = import ./lib.nix;
      };
    };
}
