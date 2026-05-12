---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation de HAProxy
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le [HAProxy Helm Chart](https://github.com/haproxytech/helm-charts/tree/main/kubernetes-ingress) peut remplacer le [chart Helm NGINX intégré](../nginx/_index.md) en tant que contrôleur Ingress, et est documenté dans la [liste des contrôleurs Ingress supplémentaires](https://kubernetes.io/docs/concepts/services-networking/ingress-controllers/#additional-controllers) de Kubernetes.

HAProxy prendra également en charge Git via SSH.

Nous utilisons par défaut [NGINX](../nginx/_index.md) principalement en raison de l'expérience historique avec cet outil, mais HAProxy est une alternative valide qui peut être préférable pour ceux qui ont plus d'expérience avec HAProxy en particulier. De plus, il offre la [conformité FIPS](#fips-compliant-haproxy) alors que le [contrôleur NGINX Ingress](https://github.com/kubernetes/ingress-nginx) ne le fait pas actuellement.

## Configuration de HAProxy {#configuring-haproxy}

Consultez la [documentation du chart Helm HAProxy](https://www.haproxy.com/documentation/kubernetes-ingress/enterprise/configuration-reference/) ou le [fichier de valeurs Helm](https://github.com/haproxytech/helm-charts/blob/main/kubernetes-ingress/values.yaml) pour les détails de configuration.

Consultez l'[exemple de configuration HAProxy](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-haproxy-ingress.yaml) pour le YAML détaillé des valeurs testées avec les charts Helm GitLab.

### Paramètres globaux {#global-settings}

Nous partageons certains paramètres globaux communs entre nos charts. Consultez la [documentation Global Ingress](../globals.md#configure-ingress-settings) pour les options de configuration communes, telles que les noms d'hôte GitLab et Registry.

### HAProxy conforme FIPS {#fips-compliant-haproxy}

[HAProxy Enterprise](https://www.haproxy.com/products/haproxy-enterprise-kubernetes-ingress-controller) assure la conformité FIPS. Notez que HAProxy Enterprise nécessite une licence.

Vous trouverez ci-dessous des liens pour plus d'informations sur HAProxy Enterprise :

- [Page d'accueil HAProxy Enterprise](https://www.haproxy.com/products/haproxy-enterprise)
- [Article de blog sur la conformité FIPS de HAProxy](https://www.haproxy.com/blog/become-fips-compliant-with-haproxy-enterprise-on-red-hat-enterprise-linux-8)
- [Opérateur OpenShift certifié](https://catalog.redhat.com/software/container-stacks/detail/5ec3f9fc110f56bd24f2dd57)
- [Comment utiliser une image depuis un registre privé](https://github.com/haproxytech/helm-charts/blob/kubernetes-ingress-1.22.0/haproxy/README.md#installing-from-a-private-registry)
- [Comment trouver l'image HAProxy Enterprise](https://www.haproxy.com/documentation/haproxy-enterprise/getting-started/installation/docker/)
