---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure the GitLab chart with an external NGINX Ingress Controller
---

This chart configures `Ingress` resources for use with the official
[NGINX Ingress](https://github.com/kubernetes/ingress-nginx) implementation. The
NGINX Ingress Controller is deployed as a part of this chart. If you want to
reuse an existing NGINX Ingress Controller already available in your cluster,
this guide will help.

## TCP services in the external Ingress Controller

The GitLab Shell component requires TCP traffic to pass through on
port 22 (by default; this can be changed). Ingress does not directly support TCP services, so some additional configuration is necessary. Your NGINX Ingress Controller may have been [deployed directly](https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md) (i.e. with a Kubernetes spec file) or through the [official Helm chart](https://github.com/kubernetes/ingress-nginx). The configuration of the TCP pass through will differ depending on the deployment approach.

### Direct deployment

In a direct deployment, the NGINX Ingress Controller handles configuring TCP services with a
`ConfigMap`. For more information, see
[exposing TCP and UDP services](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md)
in the Ingress NGINX Controller documentation.
Assuming your GitLab chart is deployed to the namespace `gitlab` and your Helm
release is named `mygitlab`, your `ConfigMap` should be something like this:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-configmap-example
data:
  22: "gitlab/mygitlab-gitlab-shell:22"
```

After you have that `ConfigMap`, you can enable it as described in the NGINX
Ingress Controller [docs](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md)
using the `--tcp-services-configmap` option.

```yaml
args:
  - /nginx-ingress-controller
  - --tcp-services-configmap=gitlab/tcp-configmap-example
```

Finally make sure that the `Service` for your NGINX Ingress Controller is exposing
port 22 in addition to 80 and 443.

### Helm deployment

If you have installed or plan to install the NGINX Ingress Controller using it's [Helm chart](https://github.com/kubernetes/ingress-nginx),
then you have to add a value to the chart using the command line:

```shell
--set tcp.22="gitlab/mygitlab-gitlab-shell:22"
```

or a `values.yaml` file:

```yaml
tcp:
  22: "gitlab/mygitlab-gitlab-shell:22"
```

The format for the value is the same as describe above in the "Direct Deployment" section.

### Proxy request buffering

The GitLab webservice needs a customized NGINX [`proxy_request_buffering`](https://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_request_buffering)
settings based on the request path. This helps with SSH handling especially in Geo setups and more
performant uploads and project imports.

The default NGINX annotation always applies to all traffic received and can't select
requests based on the request path. To address that, the bundled NGINX uses a
[custom NGINX template](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/custom-template/).

To also apply these changes to an external NGINX, you can either configure your NGINX
Ingress with these values:

```yaml
controller:
  customTemplate:
    configMapName: '<gitlab release>-nginx-tpl'
    configMapKey: "nginx.tpl"
```

#### Using a server snippet

{{< alert type="warning" >}}

NGINX Ingress snippets have the potential to access Secrets and service account tokens,
creating security risks. Review [CVE-2021-25742](https://github.com/kubernetes/kubernetes/issues/126811)
to determine whether using snippets is appropriate for your security requirements and environment."

{{< /alert >}}

As an alternative to using a custom NGINX template, you can configure a [`server-snippet`](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/#server-snippet).
Server snippets are disabled by default and can be enabled by deploying NGINX with
the `controller.allowSnippetAnnotations=true` value. Once snippet annotations are
enabled, you can configure `proxy_request_buffering` through the webservice chart:

```yaml
gitlab:
  webservice:
    ingress:
      annotations:
        nginx.ingress.kubernetes.io/server-snippet: |-
          location ~ /api/v\\d/jobs/\\d+/artifacts$|/import/gitlab_project$|\\.git/git-receive-pack$|\\.git/ssh-receive-pack$|\\.git/ssh-upload-pack$|\\.git/gitlab-lfs/objects|\\.git/info/lfs/objects/batch$ {
            proxy_request_buffering off;
            proxy_cache             off;

            set $proxy_upstream_name "<release>-nginx-<release>-webservice-default-8181";
            proxy_pass http://upstream_balancer;
          }
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

The full scope of your TLS options are documented [elsewhere](../../installation/tls.md).

If you are using an external Ingress Controller, you may also be using an external cert-manager instance
or managing your certificates in some other custom manner. For full documentation about your
TLS options, see [configure TLS for the GitLab chart](../../installation/tls.md),
however for the purposes of this discussion, here are the two values that would need to be set to disable the cert-manager chart and tell
the GitLab component charts to NOT look for the built in certificate resources:

```shell
--set installCertmanager=false
--set global.ingress.configureCertmanager=false
```
