#!/bin/bash

# Sourced from scripts/ci/autodevops.sh. So we should not set flags, like `set -eo...`, as it impacts the caller shell.

# Pebble is Let's Encrypt's miniature ACME test server, used by cert-manager's
# own e2e suite. It runs inside the k3d cluster so the chart's cert-manager
# ACME integration can be exercised end-to-end without a public IP: Pebble's
# HTTP-01 validation request originates in-cluster and reaches the Gateway or
# Ingress through the nip.io hostname mapped to the k3d loadbalancer.
# See: https://github.com/letsencrypt/pebble

# Note: Pebble's image tags carry no v prefix, unlike its GitHub release tags.
PEBBLE_IMAGE="${PEBBLE_IMAGE:-ghcr.io/letsencrypt/pebble:2.10.1}"

function pebble_pki_dir() {
  echo -n "${CI_PROJECT_DIR:-$(pwd)}/pebble-pki"
}

function deploy_pebble() {
  if [ -z "${NAMESPACE}" ]; then
    echo "Error: NAMESPACE environment variable is not set"
    exit 1
  fi

  local pki_dir
  pki_dir="$(pebble_pki_dir)"
  mkdir -p "${pki_dir}"

  echo "Installing Pebble (in-cluster ACME test server)"

  # Throwaway CA + server certificate for Pebble's ACME API (ports 14000/15000).
  # This is NOT the CA that signs the GitLab certificates — Pebble generates its
  # issuing root dynamically at startup (fetched below from /roots/0). SANs must
  # cover the in-cluster service DNS used in certmanager-issuer.server.
  openssl req -x509 -newkey rsa:2048 -nodes -days 7 \
    -keyout "${pki_dir}/api-ca.key" -out "${pki_dir}/api-ca.pem" \
    -subj "/CN=Pebble API CA (CI)"
  openssl req -newkey rsa:2048 -nodes \
    -keyout "${pki_dir}/api-tls.key" -out "${pki_dir}/api-tls.csr" \
    -subj "/CN=pebble"
  openssl x509 -req -in "${pki_dir}/api-tls.csr" \
    -CA "${pki_dir}/api-ca.pem" -CAkey "${pki_dir}/api-ca.key" -CAcreateserial \
    -days 7 -out "${pki_dir}/api-tls.crt" \
    -extfile <(printf "subjectAltName=DNS:pebble,DNS:pebble.%s.svc,DNS:pebble.%s.svc.cluster.local" "${NAMESPACE}" "${NAMESPACE}")

  kubectl create secret tls pebble-api-tls -n "${NAMESPACE}" \
    --cert="${pki_dir}/api-tls.crt" --key="${pki_dir}/api-tls.key" \
    --dry-run=client -o yaml | kubectl apply -f -

  # Mounted into the cert-manager controller (certmanager.volumes in the
  # *-https-k3d values files) so it trusts Pebble's ACME API endpoint.
  kubectl create configmap pebble-api-ca -n "${NAMESPACE}" \
    --from-file=ca.pem="${pki_dir}/api-ca.pem" \
    --dry-run=client -o yaml | kubectl apply -f -

  kubectl apply -n "${NAMESPACE}" -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: pebble-config
data:
  pebble-config.json: |
    {
      "pebble": {
        "listenAddress": "0.0.0.0:14000",
        "managementListenAddress": "0.0.0.0:15000",
        "certificate": "/etc/pebble/certs/tls.crt",
        "privateKey": "/etc/pebble/certs/tls.key",
        "httpPort": 80,
        "tlsPort": 443,
        "ocspResponderURL": "",
        "externalAccountBindingRequired": false
      }
    }
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: pebble
  labels:
    app: pebble
spec:
  replicas: 1
  selector:
    matchLabels:
      app: pebble
  template:
    metadata:
      labels:
        app: pebble
    spec:
      containers:
        - name: pebble
          image: ${PEBBLE_IMAGE}
          args: ["-config", "/etc/pebble/config/pebble-config.json"]
          env:
            # Deterministic behavior for CI: disable Pebble's chaos features
            # (random validation sleeps and nonce rejections).
            - name: PEBBLE_VA_NOSLEEP
              value: "1"
            - name: PEBBLE_WFE_NONCEREJECT
              value: "0"
          ports:
            # httpPort/tlsPort in pebble-config.json are the ports Pebble dials
            # OUT to for HTTP-01/TLS-ALPN-01 validation; it only listens on:
            - containerPort: 14000 # ACME directory (TLS)
            - containerPort: 15000 # management API (issuing roots)
          readinessProbe:
            tcpSocket:
              port: 14000
            initialDelaySeconds: 2
            periodSeconds: 2
          resources:
            requests:
              cpu: 50m
              memory: 64Mi
            limits:
              memory: 128Mi
          volumeMounts:
            - name: config
              mountPath: /etc/pebble/config
            - name: certs
              mountPath: /etc/pebble/certs
      volumes:
        - name: config
          configMap:
            name: pebble-config
        - name: certs
          secret:
            secretName: pebble-api-tls
---
apiVersion: v1
kind: Service
metadata:
  name: pebble
spec:
  selector:
    app: pebble
  ports:
    - name: acme
      port: 14000
      targetPort: 14000
    - name: mgmt
      port: 15000
      targetPort: 15000
EOF

  kubectl rollout status deployment/pebble -n "${NAMESPACE}" --timeout=120s

  pebble_fetch_issuing_root
}

# Pebble regenerates its issuing root on every process start, so it can only be
# fetched at runtime (management API /roots/0). It is the trust anchor for:
# - global.certificates.customCAs (GitLab pods trusting their own external URL)
# - gitlab-runner.certsSecretName (runner registration; the key must be named
#   <gitlab-hostname>.crt per the runner chart's self-signed cert convention)
# - the job shell (SSL_CERT_FILE for RSpec) and scripts/ci/verify_certmanager.sh
function pebble_fetch_issuing_root() {
  local pki_dir root_pem pebble_host pf_pid fetched
  pki_dir="$(pebble_pki_dir)"
  root_pem="${pki_dir}/issuing-root.pem"
  pebble_host="pebble.${NAMESPACE}.svc.cluster.local"

  echo "Fetching Pebble's dynamically-generated issuing root CA"
  kubectl port-forward -n "${NAMESPACE}" svc/pebble 15000:15000 >/dev/null 2>&1 &
  pf_pid=$!

  fetched=false
  for _ in $(seq 1 30); do
    # --resolve keeps hostname verification against the API cert's service SANs.
    if curl -sf --cacert "${pki_dir}/api-ca.pem" \
         --resolve "${pebble_host}:15000:127.0.0.1" \
         "https://${pebble_host}:15000/roots/0" -o "${root_pem}" \
       && grep -q "BEGIN CERTIFICATE" "${root_pem}"; then
      fetched=true
      break
    fi
    sleep 2
  done
  kill "${pf_pid}" 2>/dev/null || true

  if [ "${fetched}" != "true" ]; then
    echo "ERROR: could not fetch Pebble issuing root from the management API (/roots/0)"
    exit 1
  fi

  kubectl create secret generic pebble-issuing-ca -n "${NAMESPACE}" \
    --from-file=pebble-issuing-ca.crt="${root_pem}" \
    --from-file="gitlab-${HOST_SUFFIX}.${KUBE_INGRESS_BASE_DOMAIN}.crt"="${root_pem}" \
    --dry-run=client -o yaml | kubectl apply -f -
}

function remove_pebble() {
  echo "Removing Pebble"
  kubectl delete -n "${NAMESPACE}" --ignore-not-found \
    deployment/pebble service/pebble \
    configmap/pebble-config configmap/pebble-api-ca \
    secret/pebble-api-tls secret/pebble-issuing-ca
}
