---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer MinIO avec le chart GitLab
---

[MinIO](https://min.io/) est un serveur de stockage d'objets qui expose des API compatibles S3.

MinIO peut être déployé sur plusieurs plateformes différentes. Pour lancer une nouvelle instance MinIO, suivez leur [Guide de démarrage rapide](https://min.io/docs/minio/linux/index.html). Veillez à [sécuriser l'accès au serveur MinIO avec TLS](https://min.io/docs/minio/linux/operations/network-encryption.html).

Pour connecter GitLab à une instance [MinIO](https://min.io/) externe, commencez par créer des buckets MinIO pour l'application GitLab, en utilisant les noms de buckets indiqués dans cet [exemple de fichier de configuration](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/values-external-objectstorage.yaml).

À l'aide du client MinIO, créez les buckets nécessaires avant utilisation :

```shell
mc mb gitlab-registry-storage
mc mb gitlab-lfs-storage
mc mb gitlab-artifacts-storage
mc mb gitlab-uploads-storage
mc mb gitlab-packages-storage
mc mb gitlab-backup-storage
```

Une fois les buckets créés, GitLab peut être configuré pour utiliser l'instance MinIO. Consultez l'exemple de configuration dans [`rails.minio.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/rails.minio.yaml) et [`registry.minio.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage/registry.minio.yaml) dans le dossier [examples](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/objectstorage).
