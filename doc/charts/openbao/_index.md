---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: OpenBao chart
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Beta

{{< /details >}}

{{< history >}}

- Introduced as a [experiment](https://docs.gitlab.com/policy/development_stages_support/#experiment) in GitLab 18.3 [with flags](https://docs.gitlab.com/administration/feature_flags/) named `ci_tanukey_ui` and `secrets_manager`. Disabled by default.
- [Flag](https://docs.gitlab.com/administration/feature_flags/) `ci_tanukey_ui` was merged into `secrets_manager` in GitLab 18.4.
- Made available to some users in a closed beta in GitLab 18.8.
- Public beta [introduced](https://gitlab.com/groups/gitlab-org/-/work_items/21731) in GitLab 19.0.

{{< /history >}}

> [!flag]
> The availability of this feature is controlled by a feature flag.
> For more information, see the history.

You can use the [OpenBao chart](https://gitlab.com/gitlab-org/cloud-native/charts/openbao) to install
OpenBao, which is required to enable the [GitLab secrets manager](https://docs.gitlab.com/ci/secrets/secrets_manager/).

## Known limitations

- You can't upgrade OpenBao without downtime. Zero downtime upgrades are proposed in
  [issue 595721](https://gitlab.com/gitlab-org/gitlab/-/work_items/595721).
- You can't deploy OpenBao with [GitLab Operator](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator).
  Support is proposed in [issue 1933](https://gitlab.com/gitlab-org/cloud-native/gitlab-operator/-/work_items/1933).
- A FIPS variant of the OpenBao image is already being built, but OpenBao is not FIPS validated.
  FIPS validation is tracked in [GitLab issue 574875](https://gitlab.com/gitlab-org/gitlab/-/issues/574875).
- When failing over to a Geo secondary site that uses a different domain
  (instead of updating DNS to point the primary domain to the secondary site), OpenBao requires manual
  re-provisioning of JWT authentication for all projects and groups where GitLab Secrets Manager is enabled.
  This process can be time-consuming for large deployments. A migration tool is being proposed in
  [GitLab issue 595722](https://gitlab.com/gitlab-org/gitlab/-/issues/595722). Until then, the recommended
  approach is to update DNS records so the primary domain points to the promoted secondary site.

## Setup GitLab secret manager and OpenBao

1. On an existing GitLab instance, enable OpenBao and configure its database connection.
   OpenBao requires a separate PostgreSQL database that you must create first.
   For the database and password secret, see [Database configuration](#database-configuration).

   ```yaml
   # Enable OpenBao integration
   global:
     openbao:
       enabled: true
       # Connect to the separate OpenBao database you created
       psql:
         host: "psql.openbao.example.com"
         password:
           secret: openbao-db-password
           key: password
   # Install bundled OpenBao
   openbao:
     install: true
   ```

1. In GitLab, on the top bar, select **Search or go to** and find your project.
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

A complete OpenBao backup includes the:

- OpenBao unseal key
- OpenBao PostgreSQL database

The Toolbox backs up the OpenBao database as part of the standard GitLab backup, when
backup [credentials](../gitlab/toolbox/_index.md#openbao-database-credentials) are configured.

Back up the OpenBao database at the same time as the main GitLab PostgreSQL database to avoid
data inconsistencies.

## Restore OpenBao

The Toolbox restores the OpenBao database as part of the standard GitLab restore. See
[OpenBao database credentials](../gitlab/toolbox/_index.md#openbao-database-credentials) to
configure restore credentials.

Before restoring an OpenBao backup:

1. Note the current replica count so you can restore it afterward.
1. Scale down OpenBao so the running pod does not race the `DROP TABLE` and `CREATE TABLE` statements in the dump:

   ```shell
   kubectl get deploy -lapp.kubernetes.io/name=openbao,app.kubernetes.io/instance=<helm release name> -n <namespace>
   kubectl scale deploy -lapp.kubernetes.io/name=openbao,app.kubernetes.io/instance=<helm release name> -n <namespace> --replicas=0
   ```

After the restore completes, scale OpenBao back to its previous replica count so it reads from
the restored database:

```shell
kubectl scale deploy -lapp.kubernetes.io/name=openbao,app.kubernetes.io/instance=<helm release name> -n <namespace> --replicas=<previous count>
```

## OpenBao configuration options

The following tables list all available OpenBao configuration options.
Global chart settings, such as [Ingress configuration](../globals.md#configure-ingress-settings) and [image tag suffixes](../globals.md#adding-suffix-to-all-image-tags), also apply to OpenBao.

### Installation command-line options

The table below contains all the possible charts configurations that can be supplied to
the `helm install` command using the `--set` flags.

| Parameter                                                | Default                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.logLevel`                                        | info                                                    | OpenBao log level. |
| `config.logRequestsLevel`                                | off                                                     | OpenBao request log level. To enable request logging set this to the same value as `config.logLevel` or a higher level. |
| `config.logFormat`                                       | `json`                                                  | OpenBao log format. Either `json` or `standard`. |
| `nameOverride`                                           |                                                         | Override the chart name. |
| `fullnameOverride`                                       |                                                         | Override the fully qualified app name. |
| `serviceAccount.create`                                  | true                                                    | Create a service account for OpenBao. |
| `serviceAccount.automount`                               | true                                                    | |
| `serviceAccount.annotations`                             | `{}`                                                    | Additional service account annotations. |
| `serviceAccount.name`                                    |                                                         | Override the generated service account name. |
| `role.create`                                            |                                                         | Create a role with necessary RBAC permissions. |
| `securityContext.capabilities`                           | `{ drop: ["ALL"] }`                                     | |
| `securityContext.runAsNonRoot`                           | true                                                    | |
| `securityContext.allowPrivilegeEscalation`               | false                                                   | |
| `securityContext.runAsUser`                              | 1000                                                    | |
| `podSecurityContext.seccompProfile`                      | `RuntimeDefault`                                        | |
| `podSecurityContext.runAsUser`                           | 1000                                                    | |
| `podSecurityContext.fsGroup`                             | 1000                                                    | |
| `serviceActive.type`                                     | ClusterIP                                               | Service type of the active OpenBao pod. |
| `serviceActive.annotations`                              | `{}`                                                    | Service annotations of the active OpenBao pod. |
| `serviceInactive.type`                                   | ClusterIP                                               | Service type of the standby OpenBao pods. |
| `serviceInactive.annotations`                            | `{}`                                                    | Service annotations of the standby OpenBao pods. |
| `resources`                                              | `{}`                                                    | Resource limits and requests. |
| `autoscaling.minReplicas`                                | 2                                                       | Minimum OpenBao replicas. |
| `autoscaling.maxReplicas`                                | 2                                                       | Maximum OpenBao replicas. |
| `autoscaling.targetCPUUtilizationPercentage`             | 80                                                      | Target CPU utilization for autoscaling. |
| `autoscaling.targetCPUMemoryPercentage`                  |                                                         | Target memory utilization for autoscaling. |
| `livenessProbe`                                          |                                                         | OpenBao liveness probe. Check [OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) for the default. |
| `readinessProbe`                                         |                                                         | OpenBao readiness probe. Check [OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) for the default. |
| `nodeSelector`                                           | {}                                                      | Node selector labels. |
| `tolerations`                                            | []                                                      | Toleration labels for pod assignment. |
| `affinity`                                               | {}                                                      | Affinity labels for pod assignment. |
| `podAnnotations`                                         | `{}`                                                    | Annotations to add to the OpenBao pods. |
| `podLabels`                                              | `{}`                                                    | Labels to add to the OpenBao pods. |
| `extraVolumes`                                           |                                                         | Additional volumes for the OpenBao pods. |
| `extraVolumeMounts`                                      |                                                         | Additional volume mounts for the OpenBao container. |
| `config.ui`                                              | false                                                   | Enable the OpenBao UI. |
| `config.clusterPort`                                     | 8201                                                    | OpenBao cluster port. |
| `config.apiPort`                                         | 8200                                                    | OpenBao API port. |
| `config.cacheSize`                                       | 2560                                                    | Size of the read cache used by the physical storage subsystem as a number of entries. |
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
| `global.openbao.host`                                    | `openbao.<GitLab Domain>`                                 | OpenBao host. Used to configure GitLab webservice and the OpenBao chart. |
| `global.openbao.url`                                     | Derived from host                                       | OpenBao URL for GitLab. If present, must be a complete URI. |
| `global.openbao.jwt_audience`                            | Same as `url`                                           | JWT audience claim for OpenBao authentication. Must match OpenBao `bound_audiences`. For Geo deployments, see [Geo deployment](https://docs.gitlab.com/administration/secrets_manager/#geo-deployment). |
| `global.openbao.psql`                                    | `{}`                                                    | OpenBao database config (host, database, username, password). |
| `ingress.enabled`                                        | true                                                    | Enable the OpenBao Ingress to allow Runner to reach OpenBao. |
| `ingress.hostname`                                       | External OpenBao host based on global hosts config.     | Hostname the Ingress should match. |
| `ingress.tls.enabled`                                    | true                                                    | Enable Ingress TLS. |
| `ingress.tls.secretName`                                 |                                                         | Name of the [Kubernetes TLS Secret](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls). Managed by certmanager by default. |
| `tlsSecretName`                                          |                                                         | Name of the TLS secret mounted internally. Defaults to the Ingress TLS secret. |
| `ingress.annotations`                                    | true                                                    | Annotations rendered to the Ingress. Use this to configure OpenBao for any non-NGINX Ingress controllers. |
| `ingress.configureCertmanager`                           | Global certmanager config                               | Use certmanager to manage the TLS certificate. |
| `ingress.certmanagerIssuer`                              | `<release>-issuer`                                       | Name of the certmanager issuer. |
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

> [!note]
> Enabling SSL passthrough requires cert-manager to create another Ingress to complete HTTP01 challanges.
> If you use the bundled certmanager and `Issuer`, make sure the Issuer sets the correct `IngressClass` by
> configuring [`global.ingress.useNewIngressForCerts`](../globals.md#globalingressusenewingressforcerts).

### Gateway API

The OpenBao chart allows to expose traffic via an `HTTPRoute`. If [Gateway API is enabled globally](../globals.md#gateway-api),
a listener for OpenBao will be created in the managed `Gateway` resource.

| Parameter                  | Default                                                 | Description |
|----------------------------|---------------------------------------------------------|-------------|
| `gatewayRoute.enabled`     | Defaults to value of `global.gatewayApi.enabled`        | Enable exposing OpenBao via a `HTTPRoute`. |
| `gatewayRoute.sectionName` | openbao-web                                             | Gateway section to be used by the `HTTPRoute`. |
| `gatewayRoute.gatewayName` | GitLab chart managed Gateway                            | Gateway name to be used by the `HTTPRoute`. |
| `gatewayRoute.annotations` | `{}`                                                    | Extra annotations for the `HTTPRoute`. |
| `gatewayRoute.timeouts`    | `{}`                                                    | Custom timeout config for the `HTTPRoute`. |

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
| `config.telemetry.prefixFilter`                          |                                                         | Metric prefixes to include (`+`) or exclude (`-`) from telemetry. Check [OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) for the default. |
| `config.metricsListener.enabled`                         | true                                                    | Enable a second API port to serve requests for metrics. The listener can serve all API requests, but serves requests for metrics without authentication. |
| `config.metricsListener.tlsDisable`                      | true                                                    | Disable internal TLS of the metrics listener. |
| `config.metricsListener.port`                            | 8209                                                    | Port of the metrics listener. |
| `config.metricsListener.unauthenticatedMetricsAccess`    | true                                                    | Allow requests for metrics to be served without authentication. |
| `podMonitor.enabled`                                     | false                                                   | Enable PodMonitor resource for Prometheus Operator. Requires Prometheus Operator to be installed in the cluster. |
| `podMonitor.additionalLabels`                            | `{}`                                                    | Additional labels to add to the PodMonitor resource. |
| `podMonitor.selectorLabels`                              | `{}`                                                    | Additional selector labels to filter which pods to scrape. |
| `podMonitor.endpointConfig`                              | `{}`                                                    | Additional endpoint configuration (for example, `interval`, `scrapeTimeout`). |

### Unsealing and initialization options

The OpenBao chart supports two mutually exclusive auto-unseal methods:

- [static auto unsealing](https://openbao.org/docs/configuration/seal/static/) (default)
- [AWS KMS unsealing](https://openbao.org/docs/configuration/seal/awskms/)

It also uses OpenBao declarative [self initialization](https://openbao.org/docs/configuration/self-init/).

During initialization, OpenBao generates recovery keys for emergency access when JWT authentication
is unavailable. To store and use them, see
[recovery key management](https://docs.gitlab.com/administration/secrets_manager/recovery_key/).

| Parameter                                                | Default                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `config.unseal.static.enabled`                           | true                                                    | Enable static auto unsealing. |
| `config.unseal.static.currentKeyId`                      | `static-unseal-0`                                       | ID of the current static unsealing key. |
| `config.unseal.static.currentKey`                        | `/srv/openbao/keys/static-unseal-1`                     | Path of the current static unsealing key. |
| `config.unseal.static.previousKeyId`                     |                                                         | ID of the previous static unsealing key. |
| `config.unseal.static.previousKey`                       | `/srv/openbao/keys/static-unseal-0`                     | Path of the previous static unsealing key. Only rendered if previous key ID is also set. |
| `config.unseal.awskms.enabled`                           | false                                                   | Enable AWS KMS auto-unsealing. |
| `config.unseal.awskms.kmsKeyId`                          |                                                         | KMS key ID, ARN, or alias (for example, `alias/my-openbao-key`). Required when `config.unseal.awskms.enabled` is `true`. |
| `config.unseal.awskms.region`                            |                                                         | AWS region where the KMS key resides. |
| `config.unseal.awskms.endpoint`                          |                                                         | Optional custom KMS endpoint URL (for example, a VPC endpoint). |
| `config.initialize.enabled`                              | true                                                    | Enable OpenBao self initialization. |
| `config.initialize.oidcDiscoveryUrl`                     | External GitLab host                                    | OIDC discovery URL. Defaults to the external GitLab hostname. |
| `config.initialize.boundIssuer`                          | External GitLab host                                    | Issuer URL. Defaults to the external GitLab hostname. |
| `config.initialize.boundAudiences`                       | External OpenBao host                                   | OIDC role audiences. Defaults to the external OpenBao hostname. |
| `staticUnsealSecret.generate`                            | false                                                   | Generate a static key to auto unseal OpenBao. Defaults to false as managed by GitLab charts shared-secret chart. |
| `initializeTpl`                                          |                                                         | Template passed to self initialize OpenBao. Check [OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) for the default. |

#### AWS KMS unsealing

AWS KMS unsealing delegates the unseal key to an AWS KMS key, removing the need to manage a static key secret.

When running on AWS (EKS, EC2), use [IRSA](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
or an instance profile so that no explicit AWS credentials are required.
Annotate the OpenBao service account with the IAM role ARN:

```yaml
openbao:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::<account-id>:role/<role-name>"
  config:
    unseal:
      static:
        enabled: false
      awskms:
        enabled: true
        kmsKeyId: "alias/my-openbao-key"
        region: "us-east-1"
```

The IAM role must have `kms:Encrypt`, `kms:Decrypt`, and `kms:DescribeKey` permissions on the KMS key.

### Audit event streaming options

The OpenBao chart configures [auditing devices](https://openbao.org/docs/audit/) to stream events to GitLab.

| Parameter                                                | Default                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `global.openbao.httpAudit.secret`                        | `<release>-openbao-audit-secret`                        | Name of the secret storing the token shared between OpenBao and GitLab. |
| `global.openbao.httpAudit.key`                           | `token`                                                 | Secret key storing the shared token. |
| `config.audit.http.enabled`                              | true                                                    | Enable streaming of auditing events by using HTTP to GitLab. |
| `config.audit.http.streamingUri`                         | Internal workhorse URL                                  | Endpoint to stream auditing events to. |
| `config.audit.http.authTokenPath`                        | `/srv/openbao/audit/gitlab-auth`                        | Path the token shared with GitLab is mounted at. |
| `auditTpl`                                               |                                                         | Template that configures the OpenBao audit devices. Check [OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) for the default. |
| `httpAuditSecret.generate`                               | false                                                   | Generate a secret to be shared with GitLab for authenticated auditing. Defaults to false as managed by GitLab charts shared-secret chart. |
| `initializeTpl`                                          |                                                         | Template passed to configure OpenBao auditing. Check [OpenBao values](https://gitlab.com/gitlab-org/cloud-native/charts/openbao/-/blob/main/values.yaml) for the default. |

## Database configuration

OpenBao uses a **separate logical database** (`openbao` by default)
for data isolation from the Rails backend.

Configure `global.openbao.psql` or `openbao.config.storage.postgresql.connection` with host, database, username, and password. You must create the database manually. **Password is required** and is not inherited from the main GitLab database.

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
   global:
     openbao:
       psql:
         host: "psql.openbao.example.com"
         port: 5432
         database: openbao
         username: openbao
         password:
           secret: openbao-db-password
           key: password
   ```

   This uses `global.openbao.psql`, which is the preferred location because it is also
   accessible by Toolbox for backup and restore operations. To set advanced connection
   options (such as `sslMode`, `connectTimeout`, or keepalive tuning), use
   `openbao.config.storage.postgresql.connection` alongside the global settings.

1. Deploy or upgrade OpenBao. When starting, OpenBao automatically creates its database schema in the specified database.

### PostgreSQL storage options

The following options tune the OpenBao PostgreSQL storage backend.
Set them under `openbao.config.storage.postgresql`, in addition to the connection details in `global.openbao.psql`.

| Parameter                                                    | Default    | Description |
|--------------------------------------------------------------|------------|-------------|
| `config.storage.postgresql.haEnabled`                        | true       | Enable high availability mode for PostgreSQL storage. |
| `config.storage.postgresql.haTable`                          | null       | Table used for high availability locks. Uses the OpenBao default when unset. |
| `config.storage.postgresql.maxConnectRetries`                | 20         | Maximum number of database connection retry attempts. |
| `config.storage.postgresql.maxIdleConnections`               | 2          | Maximum number of idle database connections. |
| `config.storage.postgresql.maxParallel`                      | 5          | Maximum number of parallel database operations. |
| `config.storage.postgresql.skipCreateTable`                  | null       | Skip automatic creation of the storage tables. Create them manually when set to `true`. |
| `config.storage.postgresql.connection.keepalives`            | null       | Enable TCP keepalive probes. Set to `1` to enable or `0` to disable. |
| `config.storage.postgresql.connection.keepalivesCount`       | null       | Number of TCP keepalive probes to send before dropping a connection. |
| `config.storage.postgresql.connection.keepalivesIdle`        | null       | Seconds of inactivity before the first TCP keepalive probe. |
| `config.storage.postgresql.connection.keepalivesInterval`    | null       | Seconds between TCP keepalive probes. |
| `config.storage.postgresql.connection.sslMode`               | `disable`  | PostgreSQL SSL mode, such as `disable`, `require`, or `verify-full`. |
