---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation de Traefik
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le [chart Helm Traefik](https://artifacthub.io/packages/helm/traefik/traefik) peut remplacer le [chart Helm NGINX intégré](../nginx/_index.md) en tant que contrôleur Ingress.

Traefik va [traduire les objets Ingress Kubernetes natifs](https://doc.traefik.io/traefik/providers/kubernetes-ingress/) en objets [IngressRoute](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroute).

Traefik prend également en charge Git via SSH grâce aux objets [IngressRouteTCP](https://doc.traefik.io/traefik/routing/providers/kubernetes-crd/#kind-ingressroutetcp) , qui sont déployés par le chart GitLab Shell lorsque [`global.ingress.provider`](../globals.md#configure-ingress-settings) est configuré en tant que `traefik`.

## Configurer Traefik {#configuring-traefik}

Consultez la [documentation du chart Helm Traefik](https://github.com/traefik/traefik-helm-chart/tree/master/traefik) pour obtenir des détails sur la configuration.

Consultez l'[exemple de configuration Traefik](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-traefik-ingress.yaml) pour un YAML détaillé des valeurs testées avec les charts Helm GitLab.

### Paramètres globaux {#global-settings}

Nous partageons certains paramètres globaux communs entre nos charts. Consultez la [documentation Global Ingress](../globals.md#configure-ingress-settings) pour les options de configuration communes, telles que les noms d'hôte GitLab et Registry.

### Traefik conforme FIPS {#fips-compliant-traefik}

[Traefik Enterprise](https://doc.traefik.io/traefik-enterprise/) assure la conformité FIPS. Notez que Traefik Enterprise nécessite une licence, qui n'est pas incluse dans ce chart.

Voici des liens pour plus d'informations sur Traefik Enterprise :

- [Fonctionnalités de Traefik Enterprise](https://doc.traefik.io/traefik/providers/kubernetes-ingress/)
- [Image FIPS de Traefik Enterprise](https://doc.traefik.io/traefik-enterprise/operations/fips-image/)
- [Chart Helm de Traefik Enterprise](https://doc.traefik.io/traefik-enterprise/installing/kubernetes/helm/)
- [Opérateur Traefik Enterprise sur ArtifactHub](https://artifacthub.io/packages/olm/community-operators/traefikee-operator)
- [Opérateur OpenShift certifié Traefik Enterprise sur RedHat Catalog](https://catalog.redhat.com/software/container-stacks/detail/5e98745a6c5dcb34dfbb1a0a)
