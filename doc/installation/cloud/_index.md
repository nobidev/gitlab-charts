---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Cloud provider setup for the GitLab chart
---

{{< details >}}

- Tier: Free, Premium, Ultimate
- Offering: GitLab Self-Managed

{{< /details >}}

Before you deploy the GitLab chart, you must configure resources for
the cloud provider you choose.

The GitLab chart is intended to fit in a cluster with at least 8 vCPU
and 30 GB of RAM. If you are trying to deploy a non-production instance,
you can reduce the defaults to fit into a smaller cluster.

## Supported Kubernetes releases

The GitLab Helm chart supports the following Kubernetes releases:

| Kubernetes release | Status      | Minimum GitLab version |
|--------------------|-------------|------------------------|
| 1.36               | Supported   | 19.3                   |
| 1.35               | Supported   | 18.9                   |
| 1.34               | Supported   | 18.6                   |
| 1.33               | Deprecated  | 18.1                   |
| 1.32               | Unsupported | 17.11                  |

The GitLab Helm Chart aims to support three Kubernetes minor versions at a time and plans
to support new Kubernetes releases three months after their initial release.

For more details [refer to our Kubernetes support policy](https://handbook.gitlab.com/handbook/engineering/infrastructure/core-platform/systems/distribution/k8s-release-support-policy/).

We welcome reports made to our [issue tracker](https://gitlab.com/gitlab-org/charts/gitlab/-/work_items) about compatibility issues in releases newer than those listed above.

Some GitLab features might not work on deprecated releases or releases older than the releases listed above.

For some components, like the [agent for Kubernetes](https://docs.gitlab.com/user/clusters/agent/) and [GitLab Operator](https://docs.gitlab.com/operator/installation/), GitLab might support different cluster releases.

> [!warning]
> The [GitLab container images](../_index.md#container-images) can be deployed on x86-64 and ARM64 architectures.
> FIPS-validated images are only available for x86-64.
> See [issue 2285](https://gitlab.com/gitlab-org/build/CNG/-/work_items/2285) for ARM64 FIPS status.

- For cluster topology recommendations for an environment, see the
  [reference architectures](https://docs.gitlab.com/administration/reference_architectures/#available-reference-architectures).
- For an example of tuning the resources to fit in a 3 vCPU 12 GB cluster, see the
  [minimal GKE example values file](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/values-gke-minimum.yaml).

## Instructions for specific Cloud providers

Create and connect to a Kubernetes cluster in your environment:

- [Azure Kubernetes Service](aks.md)
- [Amazon EKS](eks.md)
- [Google Kubernetes Engine](gke.md)
- [OpenShift](openshift.md)
- [Oracle Container Engine for Kubernetes](oke.md)
