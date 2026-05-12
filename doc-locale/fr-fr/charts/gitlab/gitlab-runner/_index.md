---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du chart GitLab Runner
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le sous-chart GitLab Runner fournit un GitLab Runner pour l'exécution des jobs CI. Il est activé par défaut et devrait fonctionner immédiatement avec la prise en charge de la mise en cache utilisant un stockage d'objets compatible s3.

> [!note] Le GitLab Runner fourni en bundle est proposé à des fins d'évaluation uniquement. Pour les déploiements en production, installez GitLab Runner sur une machine distincte pour des [raisons de sécurité et de performances](https://docs.gitlab.com/install/requirements/#gitlab-runner). Pour plus d'informations, consultez la [documentation sur les architectures de référence](../../../installation/_index.md#use-the-reference-architectures).

## Prérequis {#requirements}

Dans GitLab 16.0, nous avons introduit un nouveau flux de création de runner qui utilise des tokens d'authentification de runner pour enregistrer les runners. Le flux hérité qui utilise des tokens d'enregistrement est obsolète et désactivé par défaut dans GitLab 17.0. Il sera supprimé dans GitLab 18.0.

Pour utiliser le flux recommandé :

- [Générez un token d'authentification.](https://docs.gitlab.com/ci/runners/new_creation_workflow/#prevent-your-runner-registration-workflow-from-breaking)
- Mettez à jour le secret du runner (`<release>-gitlab-runner-secret`) manuellement, car la configuration n'est pas gérée par le job [`shared-secrets`](../../shared-secrets.md).
- Définissez `gitlab-runner.runners.locked` sur `null` :

  ```yaml
  gitlab-runner:
    runners:
      locked: null
  ```

Si vous souhaitez utiliser le flux hérité (non recommandé) :

- Vous devez [réactiver le flux hérité](https://docs.gitlab.com/administration/settings/continuous_integration/#enable-runner-registrations-tokens).
- Le token d'enregistrement est renseigné par le job [`shared-secrets`](../../shared-secrets.md).
- Vous devez migrer vers le nouveau flux avant GitLab 18.0, qui supprimera la prise en charge du flux hérité.

## Configuration {#configuration}

Pour plus d'informations, consultez la documentation sur [l'utilisation et la configuration](https://docs.gitlab.com/runner/install/kubernetes/).

## Déploiement d'un runner autonome {#deploying-a-stand-alone-runner}

Par défaut, nous déduisons `gitlabUrl`, générons automatiquement un token d'enregistrement et le générons via le chart `migrations`. Ce comportement ne fonctionnera pas si vous avez l'intention de le déployer avec une instance GitLab en cours d'exécution.

Dans ce cas, vous devrez définir la valeur `gitlabUrl` comme étant l'URL de l'instance GitLab en cours d'exécution. Vous devrez également créer manuellement le secret `gitlab-runner` et le renseigner avec le `registrationToken` fourni par l'instance GitLab en cours d'exécution.

## Utilisation de Docker-in-Docker {#using-docker-in-docker}

Pour exécuter Docker-in-Docker, le conteneur du runner doit être privilégié afin d'avoir accès aux capacités nécessaires. Pour l'activer, définissez la valeur `privileged` sur `true`. Consultez la [documentation en amont](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#use-privileged-containers-for-the-runners) pour comprendre pourquoi la valeur par défaut n'est pas `true`.

### Problèmes de sécurité {#security-concerns}

Les conteneurs privilégiés disposent de capacités étendues, par exemple ils peuvent monter des fichiers arbitraires depuis l'hôte sur lequel ils s'exécutent. Assurez-vous d'exécuter le conteneur dans un environnement isolé de sorte qu'aucun élément important ne s'exécute à ses côtés.

## Configuration par défaut du runner {#default-runner-configuration}

La configuration par défaut du runner utilisée dans le chart GitLab a été personnalisée pour utiliser MinIO inclus pour le cache par défaut. Si vous définissez la valeur `config` du runner, vous devrez également configurer votre propre configuration de cache.

```yaml
gitlab-runner:
  runners:
    config: |
      [[runners]]
        [runners.kubernetes]
        image = "ubuntu:22.04"
        {{- if .Values.global.minio.enabled }}
        [runners.cache]
          Type = "s3"
          Path = "gitlab-runner"
          Shared = true
          [runners.cache.s3]
            ServerAddress = {{ include "gitlab-runner.cache-tpl.s3ServerAddress" . }}
            BucketName = "runner-cache"
            BucketLocation = "us-east-1"
            Insecure = false
        {{ end }}
```

Toute la configuration personnalisée du chart GitLab Runner est disponible dans le [fichier `values.yaml` de niveau supérieur](https://gitlab.com/gitlab-org/charts/gitlab/raw/master/values.yaml) sous la clé `gitlab-runner`.
