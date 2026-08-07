# Flake-parts adapter that surfaces the shared deploy-config DATA as a
# `perSystem` arg (`devValues`) for this repo's own modules (packages.nix builds
# the render from it; devstack.nix's up/down deploy it).
#
# The data itself lives in nix/lib.nix (`chartsLib.mkDevValues`) so it is
# reusable from ANY flake — the operator, a flake-utils flake, consumes it
# directly via `inputs.gitlab-charts.lib.mkDevValues { inherit pkgs; }` and
# CANNOT import this flake-parts module. Keeping the data in lib.nix and this
# module as a thin wrapper means both consumers read one source.
#
# This module IS still exported as `flakeModules.devValues` for any *flake-parts*
# consumer that would rather get `devValues` as a perSystem arg than call the
# lib function itself. It is self-contained — it imports nix/lib.nix directly
# (both files travel together in the flake source) rather than reading the
# `chartsLib` arg from args.nix — so importing it standalone cannot fail eval.
{ ... }:
let
  chartsLib = import ./lib.nix;
in
{
  perSystem =
    { pkgs, ... }:
    {
      _module.args.devValues = chartsLib.mkDevValues { inherit pkgs; };
    };
}
