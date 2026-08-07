# `nix flake check` — offline validation, no cluster needed. CI can run the
# exact same check on any runner.
#
# NOTE: the RSpec suite is intentionally NOT wired as a flake check: bundler
# resolves gems over the network, which the check sandbox forbids. Run it in
# the dev shell (`bundle install && bundle exec rspec`). What we validate here
# is that the chart renders and is structurally sane.
{ ... }:
{
  perSystem =
    { pkgs, self', ... }:
    {
      checks.render =
        pkgs.runCommand "check-render" { nativeBuildInputs = [ pkgs.yq-go ]; } ''
          # Building `rendered` already proves `helm template` succeeds; these
          # assertions prove it is non-empty and has at least one Deployment.
          test -s ${self'.packages.rendered}
          yq eval-all -e 'select(.kind == "Deployment") | .metadata.name' \
            ${self'.packages.rendered} >/dev/null
          touch "$out"
        '';
    };
}
