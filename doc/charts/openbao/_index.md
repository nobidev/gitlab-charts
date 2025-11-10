---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: OpenBao chart
---

{{< details >}}

- Tier: Ultimate
- Offering: GitLab.com, GitLab Self-Managed
- Status: Experiment

{{< /details >}}

{{< history >}}

- Introduced as a [experiment](https://docs.gitlab.com/policy/development_stages_support/#experiment) in GitLab 18.3 [with flags](https://docs.gitlab.com/administration/feature_flags/) named `ci_tanukey_ui` and `secrets_manager`. Disabled by default.
- [Flag](https://docs.gitlab.com/administration/feature_flags/) `ci_tanukey_ui` was merged into `secrets_manager` in GitLab 18.4.

{{< /history >}}

{{< alert type="flag" >}}

The availability of this feature is controlled by a feature flag.
For more information, see the history.

{{< /alert >}}

You can use the [OpenBao chart](https://gitlab.com/gitlab-org/cloud-native/charts/openbao) to install
OpenBao, which is required to enable the [GitLab secrets manager](https://docs.gitlab.com/ci/secrets/secrets_manager/).

## Known issues

- You can't upgrade OpenBao without downtime. Zero downtime upgrades are proposed in
  [OpenBao chart issue 13](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/issues/13).
- GitLab Geo is unsupported. Basic validation passed, but failover and recommended setups are not tested and documented yet.
  Full validation is discussed in [GitLab issue 568357](https://gitlab.com/gitlab-org/gitlab/-/issues/568357).
- You can't deploy OpenBao with [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator).  
- A FIPS variant of the OpenBao image is already being build, but OpenBao is not FIPS validated.
  FIPS validation is tracked in [GitLab issue 574875](https://gitlab.com/gitlab-org/gitlab/-/issues/574875).

## Setup GitLab secret manager and OpenBao

1. On an existing GitLab instance, enable OpenBao:

   ```yaml
   # Enable OpenBao integration
   global:
     openbao:
       enabled: true
   # Install bundled OpenBao
   openbao:
     install: true
   ```

1. In GitLab, on the left sidebar, select **Search or go to** and find your project. If you've [turned on the new navigation](https://docs.gitlab.com/user/interface_redesign/#turn-new-navigation-on-or-off), this field is on the top bar.
1. Select **Settings > General**.
1. Expand **Visibility, project features, permissions**.
1. Turn on the **Secrets Manager** toggle, and wait for the Secrets Manager to be provisioned.

## Rolling back OpenBao upgrades

OpenBao upgrades can make changes to the PostgreSQL data that are not backwards compatible,
which can cause compatibility issues if the OpenBao upgrade must be rolled back.

You should always [back up](#back-up-openbao) before upgrading OpenBao.
If you need to roll back an OpenBao upgrade, also restore the database backup matching the OpenBao version.

For more information, see [OpenBao upgrade documentation](https://openbao.org/docs/upgrading/).

## Back up OpenBao

To completely back up OpenBao, you require:

- Unseal keys. These keys are essential for accessing your OpenBao data after restoration. Follow the
  [secret backup procedures](../../backup-restore/backup.md#back-up-the-secrets) for OpenBao secrets.
- The PostgreSQL database.

By default, the OpenBao PostgreSQL data is backed up as part of the chart's
built-in backup procedure.

If you've configured OpenBao to use a different database (logical or physical), this
database must be backed up manually. The default backup tooling only covers the standard
PostgreSQL setup because the tooling has no awareness of other external databases.
To avoid any synchronisation issues, the GitLab and OpenBao database should be backed up
at the same time.

## Restore OpenBao

By default, the OpenBao PostgreSQL data is restored as part of the chart's
built-in restore procedure.

If you've configured OpenBao to use a different database (logical or physical), the
OpenBao database backup cannot be restored by the built-in backup utility, and must
be restored manually.

Before restoring a OpenBao backup, make sure OpenBao is scaled down because it will try to
recreate its database schema, which can lead to unexpected errors. To scale down OpenBao, run:

```shell
kubectl scale deploy -lapp=openbao,release=<helm release name> -n <namespace> --replicas=0
```

## OpenBao configuration options

The following tables list all available OpenBao configuration options.

### Installation command-line options

The table below contains all the possible charts configurations that can be supplied to
the `helm install` command using the `--set` flags.

| Parameter                                                | Default                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `logLevel`                                               | info                                                    | OpenBao log level. |
| `logRequestLevel`                                        | off                                                     | OpenBao request log level. To enable request logging set this to the same value as `logLevel` or a higher level. |
| `logFormat`                                              | `json`                                                  | OpenBao log format. Either `json` or `standard`. |
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
| `config.ui`                                              | false                                                   | Enable the OpenBao UI. |
| `config.clusterPort`                                     | 8201                                                    | OpenBao cluster port. |
| `config.apiPort`                                         | 8200                                                    | OpenBao API port. |
| `config.cacheSize`                                       | 8200                                                    | Size of the read cache used by the physical storage subsystem as a number of entries. |
| `config.maxRequestSize`                                  | 786432                                                  | Maximum request size in bytes. Default is 768KB. |
| `config.maxRequestJsonMemory`                            | 1048576                                                 | Maximum size of the JSON-parsed request body in bytes. Default is 1MB. |

### Container image options

The OpenBao chart deploys a [cloud-native GitLab container image](https://gitlab.com/gitlab-org/build/CNG) to deploy OpenBao.
The OpenBao build includes [modifications](https://gitlab.com/gitlab-org/govern/secrets-management/openbao-internal)
from the upstream version. As a result, some functionality may differ from the standard OpenBao releases.

| Parameter                                                | Default                                                   | Description |
|----------------------------------------------------------|-----------------------------------------------------------|-------------|
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-openbao` | Repository of the OpenBao image. |
| `image.pullPolicy`                                       | `IfNotPresent`                                            | Image pull policy. |
| `image.tag`                                              |                                                           | Override this to deploy a custom OpenBao version. |
| `imagePullSecrets`                                       | `[]`                                                      | Secrets to pull images from private repositories. |

### Ingress and TLS configuration options

The OpenBao chart defaults to Ingress-terminated TLS encryption.

| Parameter                                                | Default                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `global.openbao.host`                                    | openbao.<GitLab Domain>                                 | OpenBao host. Used to configure GitLab webservice and the OpenBao chart. |
| `ingress.enabled`                                        | true                                                    | Enable the OpenBao Ingress to allow Runner to reach OpenBao. |
| `ingress.hostname`                                       | External OpenBao host based on global hosts config.     | Hostname the Ingress should match. |
| `ingress.tls.enabled`                                    | true                                                    | Enable Ingress TLS. |
| `ingress.tls.secretName`                                 |                                                         | Name of the [Kubernetes TLS Secret](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls). Managed by certmanager by default. |
| `ingress.annotations`                                    | true                                                    | Annotations rendered to the Ingress. Use this to configure OpenBao for any non-NGINX Ingress controllers. |
| `ingress.configureCertmanager`                           | Global certmanager config                               | Use certmanager to manage the TLS certificate. |
| `ingress.certmanagerIssuer`                              | <release>-issuer                                        | Name of the certmanager issuer. |
| `ingress.sslPassthroughNginx`                            | false                                                   | Annotate the Ingress to pass through incoming TLS connections to OpenBao. If certmanager is configured, new HTTP01 challanges will be through another Ingress. |
| `config.tlsDisable`                                      | true                                                    | Disable internal TLS. If disabled, Ingress TLS passthrough is also disabled. |
| `config.metricsListener.tlsDisable`                      | true                                                    | Disable internal TLS of the metrics listener. |

You should operate OpenBao with end-to-end encrypted TLS. To enable end-to-end TLS configure, OpenBao
to expect a TLS connection and pass the TLS connection through NGINX Ingress:

```yaml
global:
  ingress:
    useNewIngressForCerts: true
config:
  tlsDisable: false
ingress:
  sslPassthroughNginx: true
```

Note: Enabling SSL passthrough requires cert-manager to create another Ingress to complete HTTP01 challanges.
If you use the bundled certmanager and `Issuer`, make sure the Issuer sets the correct `IngressClass` by
configuring [`global.ingress.useNewIngressForCerts`](../globals.md#globalingressusenewingressforcerts).

### Monitoring configuration options

OpenBao is preconfigured to expose Prometheus metrics which will be scraped by the bundled Prometheus subchart.

| Parameter                                                | Default                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.telemetry.enabled`                               | true                                                    | Enable telemetry and monitoring. |
| `config.telemetry.disableHostname`                       | true                                                    | Prefix gauge values with local hostname. |
| `config.telemetry.prometheusRetentionTime`               | `24h`                                                   | Metrics retention time. |
| `config.telemetry.metricsPrefix`                         | `openbao`                                               | Prefix for all metrics. |
| `config.telemetry.usageGaugePeriod`                      | 0                                                       | Interval at which high-cardinality usage data is collected, such as token counts, entity counts, and secret counts. |
| `config.telemetry.numLeaseMetricsBuckets`                | 1                                                       | Number of expiry buckets for leases. |
| `config.metricsListener.enabled`                         | true                                                    | Enable a second API port to serve requests for metrics. The listener can serve all API requests, but serves requests for metrics without authentication. |
| `config.metricsListener.tlsDisable`                      | true                                                    | Disable internal TLS of the metrics listener. |
| `config.metricsListener.port`                            | 8209                                                    | Port of the metrics listener. |
| `config.metricsListener.unauthenticatedMetricsAccess`    | true                                                    | Allow requests for metrics to be served without authentication. |

### Unsealing and initialization options

The OpenBao chart makes use of [static auto unsealing](https://openbao.org/docs/configuration/seal/static/) and OpenBao
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

### Audit event streaming options

The OpenBao chart configures [auditing devices](https://openbao.org/docs/audit/) to stream events to GitLab.

| Parameter                                                | Default                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.audit.http.enabled`                              | true                                                    | Enable streaming of auditing events by using HTTP to GitLab. |
| `config.audit.http.streamingUri`                         | Internal workhorse URL                                  | Endpoint to stream auditing events to. |
| `config.audit.http.authTokenPath`                        | `/srv/openbao/audit/gitlab-auth`                        | Path the token shared with GitLab is mounted at. |
| `httpAuditSecret.generate`                               | false                                                   | Generate a secret to be shared with GitLab for authenticated auditing. Defaults to false as managed by GitLab charts shared-secret chart. |
| `initializeTpl`                                          |                                                         | Template passed to configure OpenBao auditing. Check [OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) for the default. |

## Configure an external database

By default, OpenBao connects to the main GitLab database with the same credentials and configuration.

To configure an external database:

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

1. Deploy or upgrade OpenBao. When starting, OpenBao automatically creates its database schema in the specified database.
