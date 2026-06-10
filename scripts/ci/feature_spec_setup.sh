#!/bin/bash
set -e

# No-op for the k3d review environment.
#
# This previously fetched the bundled MinIO credentials
# (${RELEASE_NAME}-minio-secret) into /etc/gitlab/minio. The k3d review env uses
# external Garage object storage (USE_EXTERNAL_GARAGE) — there is no bundled
# minio-secret — and the backup specs reach object storage via the chart config,
# not these files. master/9-11 carry an empty feature_spec_setup.sh for the same
# reason.
