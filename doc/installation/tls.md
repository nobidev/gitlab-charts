---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configure TLS for the GitLab chart
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

This chart terminates TLS on whichever routing path you deploy. You have the choice of how to
acquire the TLS certificates for your deployment. Extensive details can be found in
[global Ingress settings](../charts/globals.md#configure-ingress-settings) and
[Gateway API settings](../charts/globals.md#gateway-api).

## Routing paths and TLS settings

Since GitLab 19.0 (chart 10.0), Gateway API is the default routing path and NGINX Ingress is
deprecated. Each path has its own settings for cert-manager and for certificate secrets, and the
settings for one path have no effect on the other. Before you follow any recipe on this page,
determine which path you use and apply the matching settings.

The examples on this page are Helm values. Save the one you need to a file and apply it with:

```shell
helm repo update
helm dep update
helm install gitlab gitlab/gitlab -f values.yaml
```

The Ingress examples cover TLS only. They assume you have already enabled the Ingress path with
`global.ingress.enabled` and an [Ingress controller](../advanced/external-ingress/_index.md).

### cert-manager settings

Installing `cert-manager` is controlled by the `installCertmanager` setting (`true` by default).
Creating Issuers and managing TLS through them is controlled separately per routing path:

| Setting | Routing path | Default | Also requires |
| ------- | ------------ | ------- | ------------- |
| `global.gatewayApi.configureCertmanager` | Gateway API | `true`  | `global.gatewayApi.enabled` |
| `global.ingress.configureCertmanager`    | Ingress     | `false` | — |

Both routing paths create independent HTTP01 Issuers.

The chart creates an `Issuer` when either path has cert-manager wired in, so deactivating it
completely means setting both settings to `false`. Setting only
`global.ingress.configureCertmanager=false` is not enough, because the Gateway API setting defaults
to `true`: on a cluster where cert-manager is not installed, the Job that applies the `Issuer` then
fails and the deployment does not complete.

> [!note]
> In chart versions before 10.5 (GitLab 19.5), the Gateway API `Issuer` did not require
> `global.gatewayApi.enabled`, so deactivating Gateway API alone left the `Issuer` in place.

### Certificate secret settings

Each routing path reads certificate secrets from a different place:

| Routing path | Setting |
| ------------ | ------- |
| Gateway API  | `gatewayApiResources.gateway.tls.secretName`, or `gatewayApiResources.gateway.listeners.<listener>.tls.certificateRefs` per listener |
| Ingress      | `global.ingress.tls.secretName`, or `<service>.ingress.tls.secretName` per service |

The Gateway listeners default to fixed secret names, which cert-manager populates when
`global.gatewayApi.configureCertmanager` is `true`. When you provide your own certificates instead,
set `gatewayApiResources.gateway.tls.secretName` to serve one certificate from every listener that
terminates TLS. When it is set, it replaces the `certificateRefs` of all of those listeners, so
leave it empty if you need a different certificate per listener and set `certificateRefs` on each
one instead:

| Listener | Rendered when | Default secret |
| -------- | ------------- | -------------- |
| `gitlab-web` | `gitlab.webservice.enabled` is `true` (the default) | `gitlab-tls` |
| `registry-web` | `registry.enabled` is `true` (the default) | `registry-tls` |
| `kas-web` | `global.kas.enabled` is `true` (the default) | `kas-tls` |
| `gitlab-web-geo` | `global.geo.enabled` and `global.geo.gatewayApi.additionalHostname` are set | `gitlab-web-geo-tls` |
| `gitlab-smartcard-web` | `global.appConfig.smartcard.enabled` is `true` | `gitlab-smartcard-tls` |
| `pages-web` | `global.pages.enabled` is `true` | `pages-tls` |
| `kas-workspaces-web` | `global.workspaces.enabled` is `true` | `kas-workspaces-tls` |
| `openbao-web` | `openbao.install` is `true` | `openbao-tls` |
| `ai-gateway-web` | `ai-gateway.install` is `true` | `ai-gateway-tls` |
| `ai-gateway-grpc` | `ai-gateway.install` is `true` | `ai-gateway-grpc-tls` |

The `gitlab-ssh` listener uses TCP and has no TLS configuration.

An override of the `certificateRefs` field merges with the listener defaults, so you do not need to repeat
`mode: Terminate`.

## Option 1: cert-manager and Let's Encrypt

Let’s Encrypt is a free, automated, and open Certificate Authority. Certificates can be automatically requested
using various tools. This chart comes ready to integrate with a popular choice [cert-manager](https://github.com/cert-manager/cert-manager).

- If you are already using cert-manager, configure
  [appropriate annotations](https://cert-manager.io/docs/usage/gateway/) on the Gateway with
  `gatewayApiResources.gateway.annotations`, or
  [Ingress annotations](https://cert-manager.io/docs/usage/ingress/#supported-annotations)
  with `global.ingress.annotations`.
- If you don't already have cert-manager installed in your cluster, install and configure it as a
  dependency of this chart.

### Internal cert-manager and Issuer

Only the issuer email needs to be provided by default. See
[cert-manager settings](#cert-manager-settings) for the settings that control this behavior.

{{< tabs >}}

{{< tab title="Gateway API" >}}

```yaml
certmanager-issuer:
  email: you@example.com
```

{{< /tab >}}

{{< tab title="Ingress" >}}

```yaml
certmanager-issuer:
  email: you@example.com
global:
  ingress:
    configureCertmanager: true
  gatewayApi:
    configureCertmanager: false
```

{{< /tab >}}

{{< /tabs >}}

### External cert-manager and internal Issuer

It is possible to make use of an external `cert-manager` but provide an Issuer as a part of this chart.

{{< tabs >}}

{{< tab title="Gateway API" >}}

The chart's Issuer is created by default, so only `installCertmanager` needs to change:

```yaml
installCertmanager: false
certmanager-issuer:
  email: you@example.com
```

{{< /tab >}}

{{< tab title="Ingress" >}}

Activate the Ingress Issuer and its annotation, and deactivate the Gateway API Issuer so that only
one is created:

```yaml
installCertmanager: false
certmanager-issuer:
  email: you@example.com
global:
  ingress:
    configureCertmanager: true
    annotations:
      kubernetes.io/tls-acme: "true"
  gatewayApi:
    configureCertmanager: false
```

{{< /tab >}}

{{< /tabs >}}

### External cert-manager and Issuer (external)

To make use of an external `cert-manager` and `Issuer` resource, so that self-signed certificates
are not activated, you must:

1. Deactivate both chart Issuers, so that the chart does not create one of its own.
1. Add annotations to activate the external `cert-manager`. For more information, see the
   [Gateway API](https://cert-manager.io/docs/usage/gateway/) or
   [Ingress](https://cert-manager.io/docs/usage/ingress/#supported-annotations) documentation.
1. Name TLS secrets for each service, which deactivates
   [self-signed behaviors](#option-4-use-auto-generated-self-signed-wildcard-certificate).

{{< tabs >}}

{{< tab title="Gateway API" >}}

cert-manager writes the certificates into the secrets named by the listeners, so the defaults can
be kept and only the annotation is required:

```yaml
installCertmanager: false
global:
  ingress:
    configureCertmanager: false
  gatewayApi:
    configureCertmanager: false
gatewayApiResources:
  gateway:
    annotations:
      cert-manager.io/cluster-issuer: <your-cluster-issuer>
```

{{< /tab >}}

{{< tab title="Ingress" >}}

```yaml
installCertmanager: false
global:
  ingress:
    configureCertmanager: false
    annotations:
      kubernetes.io/tls-acme: "true"
  gatewayApi:
    configureCertmanager: false
gitlab:
  webservice:
    ingress:
      tls:
        secretName: RELEASE-gitlab-tls
  kas:
    ingress:
      tls:
        secretName: RELEASE-kas-tls
registry:
  ingress:
    tls:
      secretName: RELEASE-registry-tls
```

{{< /tab >}}

{{< /tabs >}}

## Option 2: Use your own wildcard certificate

Add your full chain certificate and key to the cluster as a `Secret`, e.g.:

```shell
kubectl create secret tls <tls-secret-name> --cert=<path/to-full-chain.crt> --key=<path/to.key>
```

{{< tabs >}}

{{< tab title="Gateway API" >}}

Serve that one secret from every listener:

```yaml
installCertmanager: false
global:
  ingress:
    configureCertmanager: false
  gatewayApi:
    configureCertmanager: false
gatewayApiResources:
  gateway:
    tls:
      secretName: <tls-secret-name>
```

{{< /tab >}}

{{< tab title="Ingress" >}}

One setting covers all services:

```yaml
installCertmanager: false
global:
  ingress:
    configureCertmanager: false
    tls:
      secretName: <tls-secret-name>
  gatewayApi:
    configureCertmanager: false
```

{{< /tab >}}

{{< /tabs >}}

### Use AWS ACM to manage certificates

If you are using AWS ACM to create your wildcard certificate, it is not possible to specify it via secret because ACM certificates cannot be downloaded.
Instead, specify them via `nginx-ingress.controller.service.annotations`:

```yaml
nginx-ingress:
  controller:
    service:
      annotations:
        ...
        service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:{region}:{user id}:certificate/{id}
```

## Option 3: Use individual certificate per service

Add your full chain certificates to the cluster as secrets, and then reference each one from the
service that serves it.

{{< tabs >}}

{{< tab title="Gateway API" >}}

```yaml
installCertmanager: false
global:
  ingress:
    configureCertmanager: false
  gatewayApi:
    configureCertmanager: false
gatewayApiResources:
  gateway:
    listeners:
      gitlab-web:
        tls:
          certificateRefs:
            - name: RELEASE-gitlab-tls
      registry-web:
        tls:
          certificateRefs:
            - name: RELEASE-registry-tls
      kas-web:
        tls:
          certificateRefs:
            - name: RELEASE-kas-tls
```

{{< /tab >}}

{{< tab title="Ingress" >}}

```yaml
installCertmanager: false
global:
  ingress:
    configureCertmanager: false
    tls:
      enabled: true
  gatewayApi:
    configureCertmanager: false
gitlab:
  webservice:
    ingress:
      tls:
        secretName: RELEASE-gitlab-tls
  kas:
    ingress:
      tls:
        secretName: RELEASE-kas-tls
registry:
  ingress:
    tls:
      secretName: RELEASE-registry-tls
```

{{< /tab >}}

{{< /tabs >}}

> [!note]
> If you are configuring your GitLab instance to talk with other services, it may be necessary to [provide the certificate chains](../charts/globals.md#custom-certificate-authorities) for those services to GitLab through the Helm chart as well.

## Option 4: Use auto-generated self-signed wildcard certificate

These charts also provide the capability to provide a auto-generated self-signed wildcard certificate.
This can be useful in environments where Let's Encrypt is not an option, but security via SSL is still
desired. This functionality is provided by the [shared-secrets](../charts/shared-secrets.md) job.

> [!note]
>
> - The `gitlab-runner` chart does not function properly with self-signed certificates. We recommend
>   disabling it, as shown below.
> - If you're disabling TLS globally, with something like `global.ingress.tls.enabled: false`, the self-signed certificates won't be generated.

The `shared-secrets` job produces a CA certificate, wildcard certificate, and a certificate chain
for use by all externally accessible services. The secrets containing these are `RELEASE-wildcard-tls`,
`RELEASE-wildcard-tls-ca`, and `RELEASE-wildcard-tls-chain`. The `RELEASE-wildcard-tls-ca` contains the public
CA certificate that can be distributed to users and systems that will access the deployed GitLab instance.
The `RELEASE-wildcard-tls-chain` contains both the CA certificate and the wildcard certificate which you can
also use directly for GitLab Runner via `gitlab-runner.certsSecretName=RELEASE-wildcard-tls-chain`.

{{< tabs >}}

{{< tab title="Gateway API" >}}

The Gateway listeners are not wired to the generated wildcard secret automatically, so point them
at `RELEASE-wildcard-tls` yourself:

```yaml
installCertmanager: false
gitlab-runner:
  install: false
global:
  ingress:
    configureCertmanager: false
  gatewayApi:
    configureCertmanager: false
gatewayApiResources:
  gateway:
    tls:
      secretName: RELEASE-wildcard-tls
```

{{< /tab >}}

{{< tab title="Ingress" >}}

The wildcard secret is used automatically:

```yaml
installCertmanager: false
gitlab-runner:
  install: false
global:
  ingress:
    configureCertmanager: false
  gatewayApi:
    configureCertmanager: false
```

{{< /tab >}}

{{< /tabs >}}

## TLS requirement for GitLab Pages

For [GitLab Pages with TLS support](https://docs.gitlab.com/administration/pages/#wildcard-domains-with-tls-support),
a wildcard certificate applicable for `*.<pages domain>` (default value of
`<pages domain>` is `pages.<base domain>`) is required.

Because a wild card certificate is required, it can not be automatically created
by cert-manager and Let's Encrypt. cert-manager is therefore by default disabled
for GitLab Pages (via `gitlab-pages.ingress.configureCertmanager`), so you will
have to provide your own k8s Secret containing a wild card certificate. If you
have an external cert-manager configured using `global.ingress.annotations`, you
probably also want to override such annotations in
`gitlab-pages.ingress.annotations`.

{{< tabs >}}

{{< tab title="Gateway API" >}}

The Pages certificate is referenced by the `pages-web` listener, which defaults to the `pages-tls`
secret. Override it with `certificateRefs` field:

```yaml
global:
  pages:
    enabled: true
gatewayApiResources:
  gateway:
    listeners:
      pages-web:
        tls:
          certificateRefs:
            - name: <secret name>
```

{{< /tab >}}

{{< tab title="Ingress" >}}

The default name of this secret is `<RELEASE>-pages-tls`. A different name can be specified using
the `gitlab.gitlab-pages.ingress.tls.secretName` setting:

```yaml
global:
  pages:
    enabled: true
gitlab:
  gitlab-pages:
    ingress:
      tls:
        secretName: <secret name>
```

{{< /tab >}}

{{< /tabs >}}

> [!note]
> There is no per-listener equivalent of `gitlab-pages.ingress.configureCertmanager` on the Gateway
> API path. The cert-manager annotation applies to the whole Gateway, including the `pages-web`
> listener, and cert-manager cannot satisfy an HTTP-01 challenge for the Pages wildcard domain. If
> you enable Pages together with the chart's cert-manager integration, provide the Pages certificate
> yourself as shown above.

## Troubleshooting

This section contains possible solutions for problems you might encounter.

### Deployment stalls with a failing issuer Job

If you deactivated cert-manager but the `RELEASE-issuer-<suffix>` Job fails, the chart is still
wiring cert-manager in on one of the two routing paths. Check both settings:

```shell
helm get values <release> --all | grep -A2 configureCertmanager
```

`global.gatewayApi.configureCertmanager` defaults to `true`, so setting only
`global.ingress.configureCertmanager=false` leaves the Gateway API `Issuer` in place. On chart
versions before 10.5 (GitLab 19.5), `global.gatewayApi.enabled=false` does not deactivate it
either. See [cert-manager settings](#cert-manager-settings).

Under the GitLab Operator this surfaces only as a reconcile error in the controller log, with the
GitLab CR held at `phase: Preparing` and no events on the resource.

### SSL termination errors

If you are using Let's Encrypt as your TLS provider and you are facing certificate-related errors, you have a few options to debug this:

1. Check your domain with [letsdebug](https://letsdebug.net/) for any possible errors.
1. If letsdebug returns not errors, see if there's a problem related to cert-manager:

   ```shell
   kubectl describe certificate,order,challenge --all-namespaces
   ```

   If you see any errors, try removing the certificate object to force requesting a new one.

1. If nothing of the above works, consider removing [existing cert-manager resources](https://cert-manager.io/docs/installation/kubectl/#uninstalling)
   and reinstalling cert-manager. If you are using the internal
   cert-manager, delete the deployments with `certmanager` in the name,
   and re-install the Helm Chart. For example, assuming a release named `gitlab`:

   ```shell
   kubectl -n <namespace> delete deployment gitlab-certmanager gitlab-certmanager-cainjector gitlab-certmanager-webhook
   helm upgrade --install -n <namespace> gitlab gitlab/gitlab
   ```
