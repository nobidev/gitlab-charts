---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configure the GitLab chart with an external Ingress Controller
---

This chart configures `Ingress` resources with a bundled NGINX Ingress.
While the chart is making efforts to migrate from Ingress towards Gateway
API, you can keep using Ingresses with an external Ingress controller.

## Prepare the external Ingress controller

### NGINX

> [!warning]
> NGINX Ingress was deprecated and won't receive security patches after March 2026.
> Read the [official announcement](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/)
> for more information.

Check the [external NGINX Ingress documentation](nginx.md) to configure and prepare a external NGINX
Ingress deployment to be used with GitLab.

### Traefik

Traefik must be configured to expose port 22 for GitLab Shell (GitLabs SSH daemon):

```yaml
ports:
  gitlab-shell:
    expose: true
    port: 2222
    exposedPort: 22
```

## Customize the GitLab Ingress options

The NGINX Ingress Controller uses an annotation to mark which Ingress Controller
will service a particular `Ingress` (see [docs](https://github.com/kubernetes/ingress-nginx#annotation-ingressclass)).
You can configure the Ingress class to use with this chart using the
`global.ingress.class` setting. Make sure to set this in your Helm options.

```shell
--set global.ingress.class=myingressclass
```

While not necessarily required, if you're using an external Ingress Controller, you will likely want to
disable the Ingress Controller that is deployed by default with this chart:

```shell
--set nginx-ingress.enabled=false
```

## Custom certificate management

If you are using an external Ingress Controller, you may also be using an external cert-manager instance
or managing your certificates in some other custom manner. For full documentation about your
TLS options, see [configure TLS for the GitLab chart](../../installation/tls.md),
however for the purposes of this discussion, here are the two values that would need to be set to disable the cert-manager chart and tell
the GitLab component charts to not look for the built in certificate resources:

```shell
--set installCertmanager=false
--set global.ingress.configureCertmanager=false
```
