---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer le chart GitLab avec des images basées sur UBI
---

GitLab propose des versions [Red Hat UBI](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image) de ses images, vous permettant de remplacer les images standard par des images basées sur UBI. Ces images utilisent le même tag que les images standard avec l'extension `-ubi`.

> [!note] Les images basées sur UBI antérieures à GitLab 17.3 utilisent l'extension `-ubi8`.

Le chart GitLab utilise des images tierces qui ne sont pas basées sur UBI. Ces images proposent principalement des services externes à GitLab, tels que Redis, PostgreSQL, etc. Si vous souhaitez déployer une instance GitLab basée exclusivement sur UBI, vous devez désactiver les services internes et utiliser des déploiements ou des services externes.

Les services qui doivent être désactivés et fournis en externe sont :

- PostgreSQL
- MinIO (Object Store)
- Redis

Les services qui doivent être désactivés sont :

- CertManager (intégration Let's Encrypt)
- Prometheus
- GitLab Runner

## Exemples de valeurs {#sample-values}

Nous fournissons un exemple de valeurs pour le chart GitLab dans [`examples/ubi/values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/ubi/values.yaml) qui peut vous aider à créer un déploiement GitLab entièrement basé sur UBI.
