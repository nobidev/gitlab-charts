---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Certificates image contract
---

The `certificates` init container builds the CA trust store for each Pod from the image in
`global.certificates.image`.
Any image used there must work like the [Cloud Native GitLab `certificates` image](https://gitlab.com/gitlab-org/build/CNG/-/tree/master/certificates).

## Requirements

- Provide an executable at `/scripts/bundle-certificates`.
  The chart runs it as the container `command` with no arguments, so the image entrypoint and default
  command do not run.
  It runs with the init container security context, as a non-root user.
- Read CA certificates from `/usr/local/share/ca-certificates`.
  This directory is a read-only projected volume.
  Its files are the keys of the Secrets and ConfigMaps in `global.certificates.customCAs`.
  The chart also adds internal CA certificates, such as the Gitaly TLS certificate.
  Files can be symbolic links.
  Keys in `global.certificates.customCAs` must end in `.crt`, because the Debian-based image reads
  only `*.crt` files.
- Write a trust store with the system and custom CA certificates to every file in
  [Output files](#output-files).
  The output directories are in-memory `emptyDir` volumes.
  They can contain output from an earlier run if the container restarts, so replace their contents.
  The application containers mount only these directories, so do not link to files outside of them.
- Exit with a non-zero status if it cannot write the complete trust store.
  The Cloud Native GitLab scripts do not stop on errors yet, so this requirement is the target behavior.

## Output files

The base image of each application container decides which of these files its processes read.
The certificates image and the application images can use different base images, so write all of them.

| File | Description |
|------|-------------|
| `/etc/ssl/certs/ca-certificates.crt` | The bundle of all trusted CA certificates. For example, the `kas` and SMTP settings reference this file. The Debian-based and UBI-based images write this file. |
| `/etc/ssl/certs/<hash>.0` | OpenSSL subject hash links. Gitaly and Praefect set `SSL_CERT_DIR` to `/etc/ssl/certs`. Only the Debian-based image writes these links. |
| `/etc/ssl/certs/ca-bundle.crt` | The bundle in the Red Hat location. Only the UBI-based image writes this file. |
| `/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem` | The bundle in the Red Hat location. Only the UBI-based image writes this file. |

The Debian-based and UBI-based images each write only some of these files today.
