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
- Read custom CA certificates from `/usr/local/share/ca-certificates`.
  This directory is a read-only projected volume.
  Its files are the keys of the Secrets and ConfigMaps in `global.certificates.customCAs`.
  The chart also adds internal CA certificates, such as the Gitaly TLS certificate.
  Files can be symbolic links, and their names do not always end in `.crt`.
- Write a trust store with the system and custom CA certificates to `/etc/ssl/certs` and
  `/etc/pki/ca-trust/extracted/pem`.
  Both directories are in-memory `emptyDir` volumes.
  They can contain output from an earlier run if the container restarts, so replace their contents.
  The application containers mount only these directories, so do not link to files outside of them.
- Exit with a non-zero status if it cannot write the complete trust store.

## Output files

The application containers read these files:

| File | Description |
|------|-------------|
| `/etc/ssl/certs/ca-certificates.crt` | Required. The bundle of all trusted CA certificates. For example, the `kas` and SMTP settings reference this file. |
| `/etc/ssl/certs/<hash>.0` | OpenSSL subject hash links. Gitaly and Praefect set `SSL_CERT_DIR` to `/etc/ssl/certs`. The Debian-based image writes these links. |
| `/etc/ssl/certs/ca-bundle.crt` | The bundle in the Red Hat location. The UBI-based image writes this file. |
| `/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem` | The bundle in the Red Hat location. The UBI-based image writes this file. |
