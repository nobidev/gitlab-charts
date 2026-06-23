---
stage: GitLab Duo Self-Hosted
group: Custom models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AI Gateway chart
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Experiment

{{< /details >}}

The AI Gateway chart deploys the AI Gateway as a sub-chart alongside your GitLab instance.
It enables GitLab Duo Self-Hosted and the GitLab Duo Agent Platform on Kubernetes.
This feature is an [experiment](https://docs.gitlab.com/ee/policy/experiment-beta-support.html).

Prerequisites:

- TLS is required for the GitLab URL. In production mode, the AI gateway requires the GitLab endpoint to be secured to perform authentication with the GitLab instance.
  Because this configuration is set correctly by default, no action is required.
- Either:
  - A cloud license applied with [usage billing](https://docs.gitlab.com/subscriptions/gitlab_credits/) enabled.
  - An offline license with the
    [GitLab Duo Agent Platform Self-Hosted](https://docs.gitlab.com/subscriptions/subscription-add-ons/#gitlab-duo-agent-platform-self-hosted) addon.

## Configure and deploy the chart

To configure and deploy the chart:

1. Deploy the chart with the following configuration:

   ```yaml
   global:
     hosts:
       domain: <YOUR_DOMAIN>

   ai-gateway:
     install: true
   ```

1. Get the service hostname of the AI-Gateway with the following command:

   ```shell
   kubectl get svc -n <NAMESPACE> -l app.kubernetes.io/name=ai-gateway \
   -o jsonpath='{range .items[*]}{.metadata.name}.{.metadata.namespace}.svc{"\n"}{end}'
   ```

1. After the chart is deployed and your instance is available, on in the upper-right corner of your GitLab instance, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration** and:
   - Change the **Local AI Gateway URL** to `http://<SERVICE_HOST_NAME>`.
   - Change the **Local URL for the GitLab Duo Agent Platform service** to `<SERVICE_HOST_NAME>:50052`.
   - Clear the checkbox **Use TLS for the GitLab Duo Agent Platform service**.
   - If you are using an offline license, make sure you select a model for the **Code Suggestions** and the **GitLab Duo Agent Platform** features.
   For more information, see [configure GitLab to use self-hosted models](https://docs.gitlab.com/administration/gitlab_duo_self_hosted/configure_duo_features/).
1. Select **Save changes**.
1. On the **GitLab Duo** page (`/admin/gitlab_duo`), select **Run health check** to verify that everything is working correctly.

## Configure internal TLS

{{< history >}}

- [Introduced](https://gitlab.com/gitlab-org/distribution/team-tasks/-/work_items/1842) in GitLab 19.1.

{{< /history >}}

Prerequisites:

- The `self-hosted-v19.1.X-ee` or later tag for the
  AI-Gateway [container image](https://gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/container_registry/3809284?orderBy=PUBLISHED_AT&search%5B%5D=self-hosted).
- A certificate for both possible service hostnames `<RELEASE_NAME>-ai-gateway` and `<RELEASE_NAME>-ai-gateway.<NAMESPACE>.svc`.

To configure TLS:

1. Add the issuing certificate to the secrets of your cluster with the following command:

   ```shell
   kubectl create secret tls aigw-tls --cert=<PATH-TO-CERT-FILE> --key=<PATH-TO-KEY-FILE> -n <NAMESPACE>
   ```

1. Add the issuing certificate in the [Custom Certificate Authorities](../globals.md#custom-certificate-authorities).
1. Deploy the chart with the following configuration:

   ```yaml
   global:
     hosts:
       domain: <YOUR_DOMAIN>
     # Custom authority configured before
     certificates:
       customCAs:
         - secret: secret-custom-ca

   ai-gateway:
     image:
       # A 19.1 or later tag is required
       tag: self-hosted-v19.1.0-ee
     install: true
     # Make sure the probes access the service under the right scheme
     livenessProbe:
       httpGet:
         scheme: HTTPS
     readinessProbe:
       httpGet:
         scheme: HTTPS
     # The name of the secret where the certificate and its keys are stored
     tls:
       secretName: aigw-tls
   ```

Go to your GitLab Duo configuration page and change the following:

- Change the **Local AI Gateway URL** to `https://<SERVICE_HOST_NAME>`.
- Change the **Local URL for the GitLab Duo Agent Platform service** to `<SERVICE_HOST_NAME>:50052`.
- Enable the **Use TLS for the GitLab Duo Agent Platform service**.
- If you are using an offline license, make sure you select a model for the **Code Suggestions** and the **GitLab
  Duo Agent Platform** features. For more information, see [configure GitLab to use self-hosted models](https://docs.gitlab.com/administration/gitlab_duo_self_hosted/configure_duo_features/).

## Configure external access for GitLab Duo Workflow runners

GitLab Duo Workflow runners connect to the AI Gateway over gRPC from outside the cluster.
To expose the AI Gateway externally, enable the `externalAccess` option.
This creates either a Gateway API `HTTPRoute` (when `global.gatewayApi.enabled: true`)
or a Kubernetes `Ingress` (when `global.ingress.enabled: true`).

### Prerequisites

- Set `ai-gateway.host.name` to the fully qualified domain name (FQDN) for the AI Gateway.
  This hostname is deployment-specific and is not derived from `global.hosts.domain`.
- The AI Gateway service listens on port 443 (HTTPS/TLS).

### Configure with Gateway API (Envoy)

Use this configuration when `global.gatewayApi.enabled: true`:

```yaml
global:
  hosts:
    domain: <YOUR_DOMAIN>
  gatewayApi:
    enabled: true

ai-gateway:
  install: true
  host:
    name: aigw.example.com   # Required: FQDN for external access
    tls: {}
      # secretName: my-aigw-tls  # Optional: custom TLS secret
  externalAccess:
    enabled: true
```

### Configure with Kubernetes Ingress (NGINX)

Use this configuration when `global.ingress.enabled: true`:

```yaml
global:
  hosts:
    domain: <YOUR_DOMAIN>
  ingress:
    enabled: true
    provider: nginx

ai-gateway:
  install: true
  host:
    name: aigw.example.com   # Required: FQDN for external access
    tls: {}
      # secretName: my-aigw-tls  # Optional: custom TLS secret
  externalAccess:
    enabled: true
```

### Configuration values

| Value | Description |
|-------|-------------|
| `ai-gateway.host.name` | Required when `externalAccess.enabled: true`. The FQDN for the AI Gateway external endpoint, for example `aigw.example.com`. |
| `ai-gateway.host.tls.secretName` | Optional. Name of the Kubernetes TLS secret for the ingress. Falls back to the cert-manager generated secret or the wildcard self-signed certificate. |
| `ai-gateway.externalAccess.enabled` | Set to `true` to expose the AI Gateway externally. Defaults to `false`. |
