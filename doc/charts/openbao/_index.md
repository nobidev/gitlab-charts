---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: OpenBao chart
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- Introduced as a [experiment](https://docs.gitlab.com/policy/development_stages_support/#experiment) in GitLab 18.3.
- Promoted to [beta](https://docs.gitlab.com/policy/development_stages_support/#beta) in GitLab 18.6.

{{< /history >}}

{{< alert type="warning" >}}

This feature is in [beta](https://docs.gitlab.com/policy/development_stages_support/#beta) and subject to change without notice.
For more information, see [epic 14234](https://gitlab.com/groups/gitlab-org/-/epics/14243).

{{< /alert >}}

The OpenBao chart provides support to install OpenBao as a prerequisite to enable the [GitLab secrets manager](https://docs.gitlab.com/ci/secrets/secrets_manager/).
For more information, see the [openbao chart repository](https://gitlab.com/gitlab-org/cloud-native/charts/openbao).

## Known issues

- OpenBao updates imply downtime. Zero downtime upgrades are proposed in [issue 13](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/issues/13).
- The OpenBao chart needs a existing cert-manager in the cluster to locate the `Certificate` custom resource definition. If you're using the bundled cert-manager, follow a
  two-stage installation:
  1. Deploy GitLab initially with OpenBao disabled.
  1. Upgrade the deployment to enable OpenBao.
- GitLab Geo is unsupported. Basic validation passed, but failover and recommended setups are not tested and documented yet.
  Full validation will be part of [issue #568357](https://gitlab.com/gitlab-org/gitlab/-/issues/568357).
- OpenBao can not be deployed with the [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator).

## Prerequisites

- GitLab Ultimate (developer) license.
- A Kubernetes cluster with a public IP.
- A cert-manager installation (can be the cert-manager bundled with this chart).

## Setup GitLab and OpenBao

1. Install or upgrade GitLab with your [developer license](../environment_setup.md#developer-license)
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

1. Enable the necessary feature flags in a rails console:

   ```script
   Feature.enable(:secrets_manager)
   ```

1. In GitLab, on the left sidebar, select **Search or go to** and find your project.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Turn on the **Secrets Manager** toggle, and wait for the Secrets Manager to be provisioned.

## Rolling back OpenBao upgrades

During an OpenBao upgrade, there can be changes to the PostgreSQL data that are not backwards
compatible, which can cause compatibility issues if the OpenBao upgrade must be rolled back.

You should always [backup your database](#database-backup) before upgrading OpenBao.
If you need to roll back an OpenBao upgrade, also restore the database backup matching the OpenBao version.

Check the [upstream documentation](https://openbao.org/docs/upgrading/) for more details.

## Backup and Restore

A complete OpenBao backup requires securing two critical components: unseal keys and the
PostgreSQL database.

### Unseal Keys

Back up the OpenBao unseal keys following the [secret backup procedures](../../backup-restore/backup.md#back-up-the-secrets)
documented for OpenBao Secrets. These keys are essential for accessing your OpenBao data
after restoration.

### Database Backup

{{< alert type="warning" >}}

Before restoring a OpenBao backup, make sure OpenBao is scaled down, as it will try to
recreate its database schema, which can lead to unexpected errors.

```shell
kubectl scale deploy -lapp=openbao,release=<helm release name> -n <namespace> --replicas=0
```

{{< /alert >}}

By default, the OpenBao PostgreSQL data is backed up and restored as part of the chart's
built-in backup procedure.

If you've configured OpenBao to use a different database (logical or physical), this
database must be backed up manually. The default backup tooling only covers the standard
PostgreSQL setup, because the tooling has no awareness of other external databases.
To avoid any synchronisation issues, the GitLab and OpenBao database should be backed up
at the same time.

## Configuration

The following tables list all available OpenBao configuration options.

### Installation command line options

The table below contains all the possible charts configurations that can be supplied to
the `helm install` command using the `--set` flags.

| Parameter                                                | Default                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `serviceAccount.create`                                  | true                                                    | Create a service account for OpenBao. |
| `serviceAccount.automount`                               | true                                                    | |
| `serviceAccount.annotations`                             | `{}`                                                    | Additional service account annotations. |
| `serviceAccount.name`                                    |                                                         | Override the generated service account name. |
| `role.create`                                            |                                                         | Create a role with necessary RBAC permissions. |
| `securityContext.capabilities`                           | `{ drop: ["ALL"] }`                                     | |
| `securityContext.runAsNonRoot`                           | true                                                    | |
| `securityContext.allowPrivilegeEscalation`               | false                                                   | |
| `securityContext.runAsUser`                              | 65532                                                   | |
| `podSecurityContext.seccompProfile`                      | `RuntimeDefault`                                        | |
| `podSecurityContext.runAsUser`                           | 65532                                                   | |
| `podSecurityContext.fsGroup`                             | 65532                                                   | |
| `serviceActive.type`                                     | ClusterIP                                               | Service type of the active OpenBao pod. |
| `serviceActive.annotations`                              | `{}`                                                    | Service annotations of the active OpenBao pod. |
| `serviceInactive.type`                                   | ClusterIP                                               | Service type of the standby OpenBao pods. |
| `serviceInactive.annotations`                            | `{}`                                                    | Service annotations of the standby OpenBao pods. |
| `resources`                                              | `{}`                                                    | Resource limits and requests. |
| `autoscaling.minReplicas`                                | 2                                                       | Minimum OpenBao replicas. |
| `autoscaling.maxReplicas`                                | 4                                                       | Maximum OpenBao replicas. |
| `autoscaling.targetCPUUtilizationPercentage`             | 80                                                      | Target CPU utilization for autoscaling. |
| `autoscaling.targetCPUMemoryPercentage`                  |                                                         | Target memory utilization for autoscaling. |
| `livenessProbe`                                          |                                                         | OpenBao liveness probe. Check [OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) for the default. |
| `readinessProbe`                                         |                                                         | OpenBao readiness probe. Check [OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) for the default. |
| `nodeSelector`                                           | {}                                                      | Node selector labels. |
| `tolerations`                                            | []                                                      | Toleration labels for pod assignment. |
| `affinity`                                               | {}                                                      | Affinity labels for pod assignment. |
| `config.ui`                                              | true                                                    | Enable the OpenBao UI. |
| `config.clusterPort`                                     | 8201                                                    | OpenBao cluster port. |
| `config.apiPort`                                         | 8200                                                    | OpenBao API port. |
| `config.cacheSize`                                       | 8200                                                    | Size of the read cache used by the physical storage subsystem as a number of entries. |
| `config.maxRequestSize`                                  | 786432                                                  | Maximum request size in bytes. Default is 768KB. |
| `config.maxRequestJsonMemory`                            | 1048576                                                 | Maximum size of the JSON-parsed request body in bytes. Default is 1MB. |

### Image

This chart deploys a [Cloud Native GitLab image](https://gitlab.com/gitlab-org/build/CNG) to deploy OpenBao.
The OpenBao build includes [modifications](https://gitlab.com/gitlab-org/govern/secrets-management/openbao-internal)
from the upstream version. As a result, some functionality may differ from the standard OpenBao releases.

| Parameter                                                | Default                                                   | Description |
|----------------------------------------------------------|-----------------------------------------------------------|-------------|
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-openbao` | Repository of the OpenBao image. |
| `image.pullPolicy`                                       | `IfNotPresent`                                            | Image pull policy. |
| `image.tag`                                              |                                                           | Override this to deploy a custom OpenBao version. |
| `imagePullSecrets`                                       | `[]`                                                      | Secrets to pull images from private repositories. |

### Ingress and TLS

The OpenBao chart defaults to end-to-end TLS encryption, which means the Ingress passes the TLS encryption to OpenBao.

| Parameter                                                | Default                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `global.openbao.host`                                    | openbao.<GitLab Domain>                                 | OpenBao host. Used to configure GitLab webservice and the OpenBao chart. |
| `ingress.enabled`                                        | true                                                    | Enable the OpenBao Ingress to allow Runner to reach OpenBao. |
| `ingress.hostname`                                       | External OpenBao host based on global hosts config.     | Hostname the Ingress should match. |
| `ingress.tls.enabled`                                    | true                                                    | Enable Ingress TLS. |
| `ingress.tls.secretName`                                 |                                                         | The name of the [Kubernetes TLS Secret](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls). Managed by certmanager by default. |
| `ingress.annotations`                                    | true                                                    | Annotations rendered to the Ingress. Use this to configure OpenBao for any non-NGINX Ingress controllers. |
| `ingress.configureCertmanager`                           | Global certmanager config                               | Use certmanager to manage the TLS certificate. |
| `ingress.certmanagerIssuerRef.name`                      | <release>-issuer                                        | Name of the certmanager issuer. |
| `ingress.certmanagerIssuerRef.kind`                      | Issuer                                                  | Kind of certmanager issuer to use. Must be Issuer or ClusterIssuer. |
| `config.tlsDisable`                                      | false                                                   | Disable internal TLS. If disabled, Ingress TLS passthrough is also disabled. |
| `config.metricsListener.tlsDisable`                      | false                                                   | Disable internal TLS of the metrics listener. |

### Monitoring

OpenBao is preconfigured to expose Prometheus metrics which will be scraped by the bundled Prometheus subchart.

| Parameter                                                | Default                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.telemetry.enabled`                               | true                                                    | Enable telemetry / monitoring. |
| `config.telemetry.disableHostname`                       | true                                                    | Prefix gauge values with local hostname. |
| `config.telemetry.prometheusRetentionTime`               | `24h`                                                   | Metrics retention time. |
| `config.telemetry.metricsPrefix`                         | `openbao`                                               | Prefix for all metrics. |
| `config.telemetry.usageGaugePeriod`                      | 0                                                       | Interval at which high-cardinality usage data is collected, such as token counts, entity counts, and secret counts. |
| `config.telemetry.numLeaseMetricsBuckets`                | 1                                                       | Number of expiry buckets for leases. |
| `config.metricsListener.enabled`                         | true                                                    | Enable a second API port to serve requests for metrics. The listener can serve all API requests, but serves requests for metrics without authentication. |
| `config.metricsListener.tlsDisable`                      | false                                                   | Disable internal TLS of the metrics listener. |
| `config.metricsListener.port`                            | 8209                                                    | Port of the metrics listener. |
| `config.metricsListener.unauthenticatedMetricsAccess`    | true                                                    | Allow requests for metrics to be served without authentication. |

### Unsealing and initialization

The OpenBao chart makes use of [static auto unsealing](https://openbao.org/docs/configuration/seal/static/) and OpenBao's
declarative [self initialization](https://openbao.org/docs/configuration/self-init/).

| Parameter                                                | Default                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.unseal.static.enabled`                           | true                                                    | Enable static auto unsealing. |
| `config.unseal.static.currentKeyId`                      | `static-unseal-0`                                       | ID of the current static unsealing key. |
| `config.unseal.static.currentKey`                        | `/srv/openbao/keys/static-unseal-0`                     | Path of the current static unsealing key. |
| `config.unseal.static.oreviousKeyId`                     |                                                         | ID of the previous static unsealing key. |
| `config.unseal.static.previousKey`                       | `/srv/openbao/keys/static-unseal-1`                     | Path of the previous static unsealing key. Only rendered if previous key ID is also set. |
| `config.initialize.enabled`                              | true                                                    | Enable OpenBao self initialization. |
| `config.initialize.oidcDiscoveryUrl`                     | External GitLab host                                    | OIDC discovery URL. Defaults to the external GitLab hostname. |
| `config.initialize.boundIssuer`                          | External OpenBao host                                   | OIDC issuer. Defaults to the external OpenBao hostname. |
| `config.initialize.boundAudiences`                       | External OpenBao host                                   | OIDC role audiences. Defaults to the external OpenBao hostname. |
| `staticUnsealSecret.generate`                            | false                                                   | Generate a static key to auto unseal OpenBao. Defaults to false as managed by GitLab charts shared-secret chart. |
| `initializeTpl`                                          |                                                         | Template passed to self initialize OpenBao. Check [OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) for the default. |

### Auditing

The OpenBao chart configures [auditing devices](https://openbao.org/docs/audit/) to stream events to GitLab rails.

| Parameter                                                | Default                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.audit.http.enabled`                              | true                                                    | Enable streaming of auditing events via HTTP to GitLab rails. |
| `config.audit.http.streamingUri`                         | Internal workhorse URL                                  | Endpoint to stream auditing events to. |
| `config.audit.http.authTokenPath`                        | `/srv/openbao/audit/gitlab-auth`                        | Path the token shared with GitLab rails is mounted at. |
| `httpAuditSecret.generate`                               | false                                                   | Generate a secret to be shared with GitLab rails for authenticated auditing. Defaults to false as managed by GitLab charts shared-secret chart. |
| `initializeTpl`                                          |                                                         | Template passed to configure OpenBao auditing. Check [OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) for the default. |

### Configuring the database

By default, OpenBao connects to the main Rails database with the same
credentials and configuration.

If you want to use an external database, you need to:

1. Create a PostgreSQL user and database on your database server:

   ```sql
   -- Create the OpenBao user
   CREATE USER openbao WITH PASSWORD '<password>';

   -- Create the OpenBao database
   CREATE DATABASE openbao OWNER openbao;
   ```

1. Create a Kubernetes secret containing the password:

   ```shell
   kubectl create secret -n bao generic openbao-db-password --from-literal=password="<password>"
   ```

1. Configure OpenBao to connect to your external database:

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
             # connectTimeout:
             # keepalives:
             # keepalivesIdle:
             # keepalivesInterval:
             # keepalivesCount:
             # tcpUserTimeout:
             # sslMode: "disable"
             password:
               secret: openbao-db-passowrd
               key: password
   ```

1. Deploy or upgrade OpenBao. When starting, OpenBao automatically create its database schema in the specified database.
