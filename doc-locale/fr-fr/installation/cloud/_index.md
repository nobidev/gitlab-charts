---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configuration du fournisseur cloud pour le chart GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Avant de déployer le chart GitLab, vous devez configurer les ressources pour le fournisseur cloud de votre choix.

Le chart GitLab est conçu pour s'adapter à un cluster disposant d'au moins 8 vCPU et 30 Go de RAM. Si vous cherchez à déployer une instance hors production, vous pouvez réduire les valeurs par défaut pour l'adapter à un cluster plus petit.

## Versions Kubernetes prises en charge {#supported-kubernetes-releases}

Le chart Helm GitLab prend en charge les versions Kubernetes suivantes :

| Version Kubernetes | Statut      | Version GitLab minimale |
|--------------------|-------------|------------------------|
| 1.35               | Prise en charge   | 18.9                   |
| 1.34               | Prise en charge   | 18.6                   |
| 1.33               | Prise en charge   | 18.1                   |
| 1.32               | Obsolète  | 17.11                  |
| 1.31               | Non prise en charge | 17.6                   |

Le chart Helm GitLab vise à prendre en charge trois versions mineures de Kubernetes à la fois et prévoit de prendre en charge les nouvelles releases Kubernetes trois mois après leur release initiale.

Pour plus de détails, [consultez notre politique de support Kubernetes](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/systems/distribution/k8s-release-support-policy/).

Nous accueillons favorablement les rapports soumis à notre [outil de suivi des tickets](https://gitlab.com/gitlab-org/charts/gitlab/-/issues) concernant les problèmes de compatibilité dans les releases plus récentes que celles listées ci-dessus.

Certaines fonctionnalités de GitLab peuvent ne pas fonctionner sur les releases obsolètes ou les releases plus anciennes que celles listées ci-dessus.

Pour certains composants, comme l'[agent pour Kubernetes](https://docs.gitlab.com/user/clusters/agent/) et [GitLab Operator](https://docs.gitlab.com/operator/installation/), GitLab peut prendre en charge différentes releases de cluster.

> [!warning]
> Les [images de conteneurs GitLab](../_index.md#container-images) peuvent être déployées sur les architectures x86-64 et ARM64. Les images validées FIPS sont uniquement disponibles pour x86-64. Consultez le [ticket 2285](https://gitlab.com/gitlab-org/build/CNG/-/issues/2285) pour connaître le statut FIPS d'ARM64.

- Pour obtenir des recommandations sur la topologie de cluster pour un environnement, consultez les [architectures de référence](https://docs.gitlab.com/administration/reference_architectures/#available-reference-architectures).
- Pour un exemple d'ajustement des ressources afin de les adapter à un cluster de 3 vCPU et 12 Go, consultez le [fichier de valeurs d'exemple minimal pour GKE](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/values-gke-minimum.yaml).

## Instructions pour des fournisseurs cloud spécifiques {#instructions-for-specific-cloud-providers}

Créez un cluster Kubernetes dans votre environnement et connectez-vous-y :

- [Azure Kubernetes Service](aks.md)
- [Amazon EKS](eks.md)
- [Google Kubernetes Engine](gke.md)
- [OpenShift](openshift.md)
- [Oracle Container Engine for Kubernetes](oke.md)
