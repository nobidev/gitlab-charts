---
status: Experimental / Internal Use Only
group: Self Managed
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Enabling OpenBao (Development Only)
---

This guide is meant to target developers who want to enable the OpenBao integration
with GitLab.

## Prerequisites

- GitLab Ultimate (developer) license.
- A Kubernetes cluster with a public IP.
- A cert-manager installation (can be the cert-manager bundled with this chart).

## Setup GitLab and OpenBao

1. Install/upgrade GitLab with your a [developer license](../environment_setup.md#developer-license)
   and enable OpenBao:

   ```yaml
   # Enable OpenBao integration
   global:
     openbao:
       enabled: true
   # Install bundled OpenBao
   openbao:
     install: true
   ```

1. Initialise OpenBao. Make sure to pass the correct namespace, release and external GitLab and OpenBao URLs.

   ```script
   export NAMESPACE=gitlab
   export RELEASE=gitlab
   curl -s "https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/scripts/dev/init-bao.sh" \
     | bash -s -- https://gitlab.example.com https://openbao.example.com
   ```

   First, the script initialises OpenBao and stores the unseal and root keys as Kubernetes secrets.
   Then, it sets up the authentication policies and revokes the original root token.

1. Enable the necessary feature flags in a rails console:

   ```script
   Feature.enable(:secrets_manager)
   Feature.enable(:ci_tanukey_ui)   
   ```

1. In GitLab, on the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Turn on the **Secrets Manager** toggle, and wait for the Secrets Manager to be provisioned.

## Configuration

## Configuring the database

By default, OpenBao connects to the main rails database with the same
credentials and configuration.

If you want to use another database, you can override these settings:

```yaml
openbao:
  config:
    storage:
      postgresql:
        connection:
          host: "psql.openbao.example.com"
          port: 5432
          database: openbao
          username: openbao
          connectTimeout:
          keepalives:
          keepalivesIdle:
          keepalivesInterval:
          keepalivesCount:
          tcpUserTimeout:
          sslMode: "disable"
          password: {}
          # secret:
          # key:
```

## Limitations

Current known limitations:

1. OpenBao updates imply downtime.
1. Certmanager must be installed before OpenBao, so Helm can locale the Certificate CRD.
