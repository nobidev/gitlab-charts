# Reproducible dev shell: `nix develop`.
#
# Tools are single-sourced from mise.toml via tool2nix (kubectl, minikube,
# helm, stern, yq, gomplate, and the doc linters). On top of those we add the
# Ruby toolchain the RSpec/rubocop/danger suite needs — mise.toml does not pin
# Ruby, so it is added here explicitly (RSpec suite targets Ruby 3.3).
{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = inputs.tool2nix.lib.mkShellWith pkgs ../mise.toml {
        packages = with pkgs; [
          ruby_3_3
          bundler
          # tool2nix resolves "yq" to the Python yq; the chart tooling expects
          # the Go yq, so put it on PATH explicitly (mirrors the operator note).
          yq-go
          git
        ];
      };
    };
}
