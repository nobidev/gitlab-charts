---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Workload Identity Federation pour GKE avec le chart GitLab
---

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3434) dans GitLab 17.0.

{{< /history >}}

La configuration par défaut pour le stockage d'objets externe dans les charts utilise des clés secrètes. [Workload Identity Federation pour GKE](https://cloud.google.com/kubernetes-engine/docs/concepts/workload-identity) permet d'accorder l'accès au stockage d'objets au cluster Kubernetes à l'aide de jetons de courte durée. Si vous disposez d'un cluster GKE existant, consultez la [documentation Google sur la mise à jour du pool de nœuds pour utiliser Workload Identity Federation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#option_2_node_pool_modification).

Pour utiliser la workload identity, omettez `google_json_key_string` pour le secret [`object-storage.yaml`](../../charts/globals.md#connection) :

```yaml
provider: Google
google_project: your-project-id
google_client_email: null  # Will use workload identity
google_json_key_string: null  # Will use workload identity
```

## Dépannage {#troubleshooting}

Assurez-vous que le [ServiceAccount Kubernetes est lié au compte de service IAM](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#kubernetes-sa-to-iam) via l'annotation `iam.gke.io/gcp-service-account`.

Vous pouvez vérifier si Workload Identity est correctement configuré en interrogeant le point de terminaison de métadonnées à l'intérieur du pod toolbox. Le compte de service associé au cluster doit être retourné :

```shell
$ curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email
example@your-example-project.iam.gserviceaccount.com
```

Ce compte doit également être en mesure d'accéder aux portées suivantes :

```shell
$ curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/scopes
https://www.googleapis.com/auth/cloud-platform
https://www.googleapis.com/auth/userinfo.email
```
