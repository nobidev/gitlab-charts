# Portable, flake-parts-free helper library for rendering and packaging the
# GitLab Helm chart with Nix. Every function takes its inputs explicitly
# (`pkgs`, `helm`, `chartSrc`, …) so it is reusable from ANY flake — notably
# the GitLab Operator, which consumes this via `inputs.gitlab-charts.lib`
# instead of vendoring a copy of the chart.
#
# Exposed at the flake level as `self.lib` / `inputs.gitlab-charts.lib`.
rec {
  # Fetch the chart's remote subchart dependencies (`helm dependency build`)
  # into a fixed-output derivation — the one place Nix permits network access.
  # `helm dependency build` needs each http(s) repo from Chart.yaml registered
  # first; we derive those from Chart.yaml so new deps work without editing this
  # file. Local path subcharts (already under charts/) are left untouched.
  #
  # `outputHash` must be re-bootstrapped when Chart.lock changes: set it to
  # `pkgs.lib.fakeHash`, run `nix build .#chart-deps`, and paste back the
  # `got: sha256-…` value Nix prints.
  chartDeps =
    {
      pkgs,
      helm,
      chartSrc,
      outputHash,
      name ? "gitlab-chart-deps",
    }:
    pkgs.stdenvNoCC.mkDerivation {
      inherit name;
      src = chartSrc;
      nativeBuildInputs = [
        helm
        pkgs.cacert
        pkgs.coreutils
        pkgs.yq-go
      ];
      dontConfigure = true;
      dontInstall = true;
      buildPhase = ''
        export HOME="$TMPDIR"
        export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
        # We are already in the unpacked, writable chart source root.
        # Register each http(s) repo from Chart.yaml so `helm dependency build`
        # can resolve them (OCI repos need no `helm repo add`).
        yq '.dependencies[].repository' Chart.yaml 2>/dev/null \
          | while read -r url; do
              case "$url" in
                http://*|https://*)
                  helm repo add "repo-$(printf '%s' "$url" | sha1sum | cut -c1-12)" \
                    "$url" >/dev/null 2>&1 || true ;;
              esac
            done
        helm dependency build
        mkdir -p "$out"
        cp charts/*.tgz "$out"/ 2>/dev/null || true
      '';
      outputHashMode = "recursive";
      outputHashAlgo = "sha256";
      inherit outputHash;
    };

  # A writable chart tree with the fetched subcharts overlaid into charts/,
  # ready for `helm template` / `helm package`. This is the packaged artifact
  # the operator consumes in place of vendoring a chart copy.
  packagedChart =
    {
      pkgs,
      chartSrc,
      deps,
    }:
    pkgs.runCommand "gitlab-chart" { } ''
      cp -r ${chartSrc} "$out" && chmod -R u+w "$out"
      mkdir -p "$out/charts"
      cp ${deps}/*.tgz "$out/charts/" 2>/dev/null || true
    '';

  # `helm package` a prepared chart tree (subcharts already present under
  # charts/) into a versioned tarball. The output is a DIRECTORY containing
  # helm's own `<chartName>-<version>.tgz` — the exact shape a chart server
  # (`HELM_CHARTS=/charts`) expects. The operator consumes this to bundle the
  # locally-built chart into its image instead of fetching a published one, so
  # `nix run .#up` there deploys the working-tree chart end-to-end.
  packageChartTarball =
    {
      pkgs,
      helm,
      chart,
    }:
    pkgs.runCommand "gitlab-chart-tgz" { nativeBuildInputs = [ helm ]; } ''
      export HOME="$TMPDIR"
      mkdir -p "$out"
      helm package ${chart} --destination "$out"
    '';

  # Offline `helm template` render of a prepared chart (one that already has its
  # subcharts present under charts/). Pure: no cluster, no network. `name` is the
  # Helm release name (affects rendered resource names, so callers that render a
  # different chart — e.g. the operator's deploy/chart — must set it to match
  # their release). `extraArgs` is a raw string of extra flags (e.g. --set …).
  # `outName` names the output derivation only (cosmetic); defaults off `name`.
  renderChart =
    {
      pkgs,
      helm,
      chart,
      name ? "gitlab",
      namespace ? "default",
      extraArgs ? "",
      outName ? "${name}-rendered.yaml",
    }:
    pkgs.runCommand outName { nativeBuildInputs = [ helm ]; } ''
      export HOME="$TMPDIR"
      helm template ${name} ${chart} --include-crds \
        --namespace ${namespace} ${extraArgs} > "$out"
    '';

  # Parse the chart's own `version:` from a Chart.yaml path (eval-time, so
  # consumers can read it without building). Single-sources "which chart
  # version" for the operator's dynamic-pull path off the flake input. `lib` is
  # passed in (nixpkgs.lib) to keep this file free of a fixed nixpkgs.
  chartVersionFrom =
    { lib, chartYamlPath }:
    let
      lines = lib.splitString "\n" (builtins.readFile chartYamlPath);
      verLine = lib.findFirst (l: lib.hasPrefix "version:" l) null lines;
    in
    # Strip the key then trim surrounding whitespace, so spacing variations
    # (`version:1.2.3`, `version:  1.2.3 `) don't corrupt the parsed value.
    if verLine == null then "unknown" else lib.trim (lib.removePrefix "version:" verLine);

  # Local-deployment DATA for the GitLab chart — the source of truth for
  # "how we deploy GitLab locally". Consumed both by this repo's OWN Nix
  # (packages.rendered's pure render check + the nix/devstack.nix up/down apps,
  # via the flake-parts wrapper nix/dev-values.nix) AND by the GitLab Operator,
  # which builds its GitLab-CR `spec.chart.values` from `deployValues` and reads
  # `cfg` scalars (e.g. the Envoy Gateway version) — see the operator's
  # nix/manifests.nix. Pure data: no apps, no effects, depends only on `pkgs`,
  # so it is reusable from ANY flake as
  # `inputs.gitlab-charts.lib.mkDevValues { inherit pkgs; }`.
  #
  # Everything is OVERRIDABLE so a consumer reuses the shared base and only
  # states its divergences (the operator runs kind, not k3d: different namespace,
  # TLS secret names, NodePort front door, pages on):
  #   cfgOverrides     deep-merged over the default `cfg` (recursiveUpdate)
  #   valuesOverrides  deep-merged over the default `deployValues`
  #
  # Returns:
  #   cfg               scalar config (namespace, envoy/gateway names+version, …)
  #   tlsListeners      Gateway API listeners sharing the one self-signed cert
  #   deployValues      the chart values a deploy embeds (charts: `-f`; operator: CR)
  #   deployValuesFile  deployValues rendered to a YAML file
  #   renderValues      deployValues + domain + placeholder externals, for pure render
  #   renderValuesFile  renderValues rendered to a YAML file
  mkDevValues =
    {
      pkgs,
      cfgOverrides ? { },
      valuesOverrides ? { },
    }:
    let
      lib = pkgs.lib;
      yaml = (pkgs.formats.yaml { }).generate;

      # Single source of the local deployment config, overridable via
      # `cfgOverrides`. Env vars override at runtime in the charts `up` app
      # (nix/devstack.nix); the operator overrides at eval via cfgOverrides.
      cfg = lib.recursiveUpdate defaultCfg cfgOverrides;
      defaultCfg = {
        namespace = "gitlab";
        releaseName = "gitlab";
        clusterName = "gitlab";
        # Placeholder domain used ONLY for the pure `helm template` render check.
        # The real domain is derived at runtime by `up` from the host IP as
        # `<ip>.nip.io` (like the operator), overridable via GITLAB_DOMAIN, and
        # the IP alone via GITLAB_LOCAL_IP.
        renderDomain = "gitlab.example.com";
        email = "dev@example.com"; # override: GITLAB_EMAIL
        tlsSecretName = "gitlab-tls"; # self-signed wildcard, created by `up`
        # git-over-SSH host port. The chart's Gateway API `gitlab-ssh` TCP
        # listener always listens on :22 on the Envoy LoadBalancer; `up` maps
        # this host port -> Envoy :22, and sets global.shell.port to it so the
        # port advertised in clone URLs matches the reachable one. Not 22:
        # avoids clashing with the host's own sshd (and a privileged bind).
        # Matches the operator's cfg.sshPort. Override at runtime: GITLAB_SSH_PORT.
        sshPort = 32022;
        k8sTimeout = "600s";
      };

      # Every TLS Gateway listener (values.yaml → gatewayApiResources) pointed at
      # one self-signed secret instead of the chart's per-service secret names —
      # mirrors the operator's local-dev approach and needs a single cert.
      tlsListeners = [
        "gitlab-web"
        "gitlab-web-geo"
        "gitlab-smartcard-web"
        "registry-web"
        "pages-web"
        "kas-web"
        "kas-workspaces-web"
        "openbao-web"
        "ai-gateway-web"
        "ai-gateway-grpc"
      ];

      # Dev values OWNED by this flow: sizing, front door, disabled extras.
      # The external DB/Redis/object-store connections are intentionally NOT
      # here — they come from scripts/dev_dependencies.sh's generated file at
      # deploy time. `global.hosts.domain` is also NOT here: it is runtime-derived
      # (charts `up` sets it via --set; the operator injects the <ip>.nip.io
      # domain into the CR at deploy), and the pure render adds it via
      # renderValues. This is the fragment an operator CR embeds under
      # `spec.chart.values`, layered under its own valuesOverrides.
      baseDeployValues = {
        global = {
          # Front door: Envoy Gateway, bundled and installed by the chart itself
          # (installEnvoy=true, the upstream default model): the chart deploys
          # the Envoy Gateway controller and CRDs and creates the GatewayClass.
          # Local TLS is a self-signed wildcard secret created by `up` (no
          # cert-manager/ACME).
          ingress.enabled = false;
          # Advertised git-over-SSH port; `up` maps this host port -> Envoy :22
          # (the gitlab-ssh TCP listener) so the advertised port is reachable.
          shell.port = cfg.sshPort;
          gatewayApi = {
            enabled = true;
            installEnvoy = true;
            configureCertmanager = false;
          };
        };
        installCertmanager = false;
        "nginx-ingress".enabled = false;
        prometheus.install = false;
        "gitlab-runner".install = false;
        gitlab = {
          webservice = {
            minReplicas = 1;
            maxReplicas = 1;
          };
          sidekiq = {
            minReplicas = 1;
            maxReplicas = 1;
          };
          "gitlab-shell" = {
            minReplicas = 1;
            maxReplicas = 1;
          };
        };
        registry.hpa = {
          minReplicas = 1;
          maxReplicas = 1;
        };
        gatewayApiResources.gateway.listeners = lib.genAttrs tlsListeners (_: {
          tls.certificateRefs = [ { name = cfg.tlsSecretName; } ];
        });
      };
      deployValues = lib.recursiveUpdate baseDeployValues valuesOverrides;
      deployValuesFile = yaml "gitlab-dev-values.yaml" deployValues;

      # Placeholder external-service connections. These exist ONLY so the chart
      # can `helm template` for the pure render check (nix/packages.nix →
      # packages.rendered). Real deploys ignore this and use the script-generated
      # `.values/dev-external.values.yaml` (real hosts + secret names).
      renderValues = lib.recursiveUpdate deployValues {
        global = {
          # Domain is runtime-derived for real deploys; the pure render needs a
          # concrete value, so supply the placeholder here (not in deployValues).
          hosts.domain = cfg.renderDomain;
          psql = {
            host = "postgresql.internal";
            password.secret = "gitlab-postgres";
          };
          redis.host = "redis.internal";
          appConfig.object_store = {
            enabled = true;
            proxy_download = true;
            connection = {
              secret = "gitlab-object-storage";
              key = "connection";
            };
          };
        };
        # Registry + backup object storage are separate from appConfig and are
        # also required since v10 (mirrors the script-generated values file).
        registry.storage = {
          secret = "gitlab-registry-storage";
          key = "config";
        };
        gitlab.toolbox.backups.objectStorage.config = {
          secret = "gitlab-object-storage-s3cmd";
          key = "config";
        };
        "certmanager-issuer".email = cfg.email;
      };
      renderValuesFile = yaml "gitlab-render-values.yaml" renderValues;
    in
    {
      inherit
        cfg
        tlsListeners
        deployValues
        deployValuesFile
        renderValues
        renderValuesFile
        ;
    };
}
