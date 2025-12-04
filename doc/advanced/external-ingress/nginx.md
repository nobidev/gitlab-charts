---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: Configure the GitLab chart with an external NGINX Ingress Controller
---

{{< alert type="warning" >}}

NGINX Ingress was deprecated and won't receive security patches after March 2026.

https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/

{{< /alert >}}

GitLab chart currently manages and bundles a forked NGINX Ingress. This guide
helps to configure an external NGINX Ingress to be used with GitLab chart
instead of the bundled one.

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

### Configure GitLab chart

[Configure the GitLab Ingresses to use your external NGINX Ingress controller.](../external-ingress/_index.md)