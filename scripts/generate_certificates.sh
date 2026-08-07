#!/bin/bash
#
# generate_service_certificates.sh <service>
#--------------------------------------
# Script to generate a key and certificate for GitLab services, including Gitaly
# and Praefect to enable TLS support.
#
# Generates `<service>.crt` & `<service>.key` in a temporary directory, and
# places them into the current working directory.
#
# By default generates a key and certificated for `gitaly` in `default` namespace
# and `gitlab` release. Use `RELEASE_NAME` and `NAMESPACE` environment variables
# for non-default namespace and release.
#
# The certificate covers both the partial Service name (`<service>.<namespace>.svc`)
# and the fully qualified name (`<service>.<namespace>.svc.cluster.local`). It stays
# valid whether or not `global.clusterDomain` is set on the chart.
#
# Use `CLUSTER_DOMAIN` if the cluster does not use `cluster.local`. Set it to an
# empty string to cover the partial name only.
#
# After generation, create a TLS secret:
#
#   kubectl create secret tls <service>-tls --cert=gitaly.crt --key=gitaly.key
#
# Then, configure the chart to use this:
#   global:
#     <service>:
#       tls:
#         enabled: true
#         secretName: <service>-tls
#--------------------------------------

VALID_DAYS=${VALID_DAYS-365}
CERT_NAME=${1-gitaly}
RELEASE_NAME=${RELEASE_NAME-gitlab}
NAMESPACE=${NAMESPACE-default}
DNS_SUFFIX=${DNS_SUFFIX:-.svc}
CLUSTER_DOMAIN=${CLUSTER_DOMAIN-cluster.local}

WORKDIR=`pwd`
TEMP_DIR=$(mktemp -d)
pushd ${TEMP_DIR} || exit

SERVICE_NAME="${RELEASE_NAME}-${CERT_NAME}"
SERVICE_NAME="${SERVICE_NAME:0:63}"

# Cover the partial name, and the fully qualified name unless DNS_SUFFIX already
# carries the cluster domain.
SUFFIXES=("${DNS_SUFFIX}")
if [ -n "${CLUSTER_DOMAIN}" ] && [ "${DNS_SUFFIX}" = "${DNS_SUFFIX%".${CLUSTER_DOMAIN}"}" ]; then
  SUFFIXES+=("${DNS_SUFFIX}.${CLUSTER_DOMAIN}")
fi

(
echo "[req_ext]"
echo "subjectAltName = @san"
echo ""
echo "[san]"
entry=0
for suffix in "${SUFFIXES[@]}"; do
  # The wildcard covers the per-pod addresses of headless Services, such as Gitaly.
  entry=$((entry + 1)); echo "DNS.${entry} = ${SERVICE_NAME}.${NAMESPACE}${suffix}"
  entry=$((entry + 1)); echo "DNS.${entry} = *.${SERVICE_NAME}.${NAMESPACE}${suffix}"
done
echo ""
) > san.conf

openssl req -x509 -nodes -newkey rsa:4096 \
  -keyout "${CERT_NAME}.key" \
  -out "${CERT_NAME}.crt" \
  -days ${VALID_DAYS} \
  -subj "/CN=${CERT_NAME}" \
  -reqexts req_ext -extensions req_ext \
  -config <(cat /etc/ssl/openssl.cnf san.conf )

mv ${CERT_NAME}.* $WORKDIR/

popd
rm -rf ${TEMP_DIR}
