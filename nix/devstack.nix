# The charts-specific "one command → local GitLab" devstack apps.
#
#   nix run .#up      create a k3d cluster, provision external deps, deploy GitLab
#   nix run .#down    tear it all back down
#
# NOT a reusable flakeModule: these apps hardcode THIS repo's dev flow —
# scripts/dev_dependencies.sh, working-tree `helm upgrade --install .`, k3d,
# .values/dev-external.values.yaml. The operator writes its own `up` (same
# shape, different deploy step). The reusable *data* these apps deploy lives in
# nix/dev-values.nix and is exported as `flakeModules.devValues`.
#
# It is an ADDITIVE layer over the repo's existing local-dev flow documented in
# doc/development/external-dependencies.md: the external prerequisites (Valkey
# for Redis, CloudNativePG for Postgres, Garage for object storage) are
# provisioned by the maintained `scripts/dev_dependencies.sh`, which also writes
# `.values/dev-external.values.yaml`. This module just orchestrates that script
# + `helm`, deploying the single-sourced `devValues.deployValues` overlay.
#
# Full-stack `up` targets k3d first (built-in klipper LoadBalancer, matches CI).
# The bare cluster lifecycle (nix/cluster.nix) stays backend-agnostic; adding a
# minikube/kind `up` means adding their front-door networking recipe here.
{ ... }:
{
  perSystem =
    {
      pkgs,
      helm,
      devValues,
      ...
    }:
    let
      lib = pkgs.lib;
      # Deploy config comes from the shared data module (nix/dev-values.nix); the
      # app text below references ${cfg.*} / ${deployValuesFile} as before.
      inherit (devValues) cfg deployValuesFile;

      # Guard: the wrapped script uses repo-relative paths, so `up`/`down` must
      # run from the chart repo root. Fail early with a clear message otherwise.
      repoRootGuard = ''
        if [ ! -f scripts/dev_dependencies.sh ]; then
          echo "error: run this from the chart repository root (scripts/dev_dependencies.sh not found)" >&2
          exit 1
        fi
      '';

      upTools = [
        pkgs.bash
        pkgs.k3d
        pkgs.kubectl
        helm
        pkgs.coreutils
        pkgs.git
        pkgs.gnugrep
        pkgs.gawk # host-IP parsing on Linux
        pkgs.openssl # self-signed TLS secret
        # macOS `ipconfig` / Linux `ip`/`hostname` are used from the inherited
        # PATH (writeShellApplication prepends runtimeInputs, keeps $PATH), so
        # they are not pinned here (iproute2 is Linux-only and would break darwin).
      ];

      up = pkgs.writeShellApplication {
        name = "gitlab-up";
        runtimeInputs = upTools;
        text = ''
          ${repoRootGuard}
          ns="''${NAMESPACE:-${cfg.namespace}}"
          name="''${CLUSTER_NAME:-${cfg.clusterName}}"
          email="''${GITLAB_EMAIL:-${cfg.email}}"
          # git-over-SSH host port -> Envoy :22 (gitlab-ssh listener), also the
          # advertised clone-URL port. Applied at cluster CREATE time only.
          sshport="''${GITLAB_SSH_PORT:-${toString cfg.sshPort}}"

          # Derive the domain from the host IP as <ip>.nip.io, like the operator.
          # GITLAB_DOMAIN overrides the whole domain; GITLAB_LOCAL_IP the IP only.
          detect_host_ip() {
            local ip="" iface=""
            # macOS: resolve the interface backing the default route, then its
            # IPv4. `route -n get default` is BSD syntax; on Linux it fails
            # harmlessly and we fall through to `ip route get` below.
            if command -v route >/dev/null 2>&1 && command -v ipconfig >/dev/null 2>&1; then
              iface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2}')"
              [ -n "$iface" ] && ip="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
            fi
            if [ -z "$ip" ] && command -v ipconfig >/dev/null 2>&1; then
              for iface in en0 en1 en2; do
                ip="$(ipconfig getifaddr "$iface" 2>/dev/null || true)"
                [ -n "$ip" ] && break
              done
            fi
            if [ -z "$ip" ] && command -v ip >/dev/null 2>&1; then
              ip="$(ip route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++) if($i=="src"){print $(i+1); exit}}')"
            fi
            if [ -z "$ip" ] && command -v hostname >/dev/null 2>&1; then
              ip="$(hostname -I 2>/dev/null | awk '{print $1}')"
            fi
            printf '%s' "$ip"
          }
          ip="''${GITLAB_LOCAL_IP:-$(detect_host_ip)}"
          domain="''${GITLAB_DOMAIN:-}"
          if [ -z "$domain" ]; then
            if [ -z "$ip" ]; then
              echo "error: could not detect a host IP; set GITLAB_LOCAL_IP or GITLAB_DOMAIN" >&2
              exit 1
            fi
            domain="$ip.nip.io"
          fi

          echo "==> [1/5] k3d cluster '$name' (80/443 + SSH $sshport->22 -> klipper LB; k3s Traefik disabled)"
          if ! k3d cluster list -o json | grep -q "\"name\":\"$name\""; then
            k3d cluster create "$name" \
              -p "80:80@loadbalancer" -p "443:443@loadbalancer" \
              -p "$sshport:22@loadbalancer" \
              --k3s-arg "--disable=traefik@server:*"
          else
            echo "    cluster '$name' already exists — reusing"
          fi

          echo "==> [2/5] external dependencies (Valkey / CloudNativePG / Garage)"
          NAMESPACE="$ns" bash scripts/dev_dependencies.sh setup

          echo "==> [3/5] self-signed TLS secret '${cfg.tlsSecretName}' for *.$domain"
          certdir="$(mktemp -d)"
          openssl req -x509 -nodes -newkey rsa:2048 -days 365 \
            -keyout "$certdir/tls.key" -out "$certdir/tls.crt" \
            -subj "/CN=*.$domain" \
            -addext "subjectAltName=DNS:$domain,DNS:*.$domain" 2>/dev/null
          kubectl create secret tls "${cfg.tlsSecretName}" \
            --cert="$certdir/tls.crt" --key="$certdir/tls.key" \
            --namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
          rm -rf "$certdir"

          # `helm dependency update` fetches the chart's subcharts, including the
          # bundled gateway-helm (gated on installEnvoy=true), so the deploy below
          # installs the Envoy Gateway controller + CRDs and creates the
          # GatewayClass itself (the upstream default model).
          echo "==> [4/5] chart dependencies"
          helm dependency update .

          # Optional user-supplied values file(s): a space-separated list in
          # GITLAB_EXTRA_VALUES, layered LAST so they win over the dev overlay.
          # e.g. GITLAB_EXTRA_VALUES="runner.yaml sizing.yaml" nix run .#up
          extra_values_args=()
          if [ -n "''${GITLAB_EXTRA_VALUES:-}" ]; then
            read -ra _extra_files <<< "''${GITLAB_EXTRA_VALUES}"
            for f in "''${_extra_files[@]}"; do
              if [ ! -f "$f" ]; then
                echo "error: GITLAB_EXTRA_VALUES file not found: $f" >&2
                exit 1
              fi
              echo "    + extra values: $f"
              extra_values_args+=( -f "$f" )
            done
          fi

          echo "==> [5/5] deploy GitLab"
          helm upgrade --install "${cfg.releaseName}" . \
            --namespace "$ns" --create-namespace \
            --timeout ${cfg.k8sTimeout} \
            -f .values/dev-external.values.yaml \
            -f ${deployValuesFile} \
            "''${extra_values_args[@]}" \
            --set global.hosts.domain="$domain" \
            --set global.shell.port="$sshport" \
            --set certmanager-issuer.email="$email"

          echo "==> done. namespace=$ns domain=$domain"
          echo "    URL:  https://gitlab.$domain  (self-signed cert — expect a browser warning)"
          echo "    SSH:  ssh://git@gitlab.$domain:$sshport  (git-over-SSH via the gitlab-ssh gateway listener)"
          echo "    Root password:"
          echo "      kubectl -n $ns get secret ${cfg.releaseName}-gitlab-initial-root-password -o jsonpath='{.data.password}' | base64 -d ; echo"
          echo "    Envoy LB service (port-forward this if the domain isn't reachable):"
          echo "      kubectl -n $ns get svc -l gateway.envoyproxy.io/owning-gateway-name"
        '';
      };

      down = pkgs.writeShellApplication {
        name = "gitlab-down";
        runtimeInputs = upTools;
        text = ''
          ${repoRootGuard}
          ns="''${NAMESPACE:-${cfg.namespace}}"
          name="''${CLUSTER_NAME:-${cfg.clusterName}}"

          echo "==> uninstalling GitLab release"
          helm uninstall "${cfg.releaseName}" --namespace "$ns" || true
          # Deleting the k3d cluster below removes the external deps with it; the
          # explicit teardown is kept so `down` also cleans up a reused cluster
          # (CLUSTER_NAME pointing at a cluster we did not create here).
          echo "==> tearing down external dependencies"
          NAMESPACE="$ns" bash scripts/dev_dependencies.sh teardown || true
          echo "==> deleting k3d cluster '$name'"
          k3d cluster delete "$name" || true
        '';
      };
    in
    {
      apps.up = {
        type = "app";
        program = lib.getExe up;
      };
      apps.down = {
        type = "app";
        program = lib.getExe down;
      };
    };
}
