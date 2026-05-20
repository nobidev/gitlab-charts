---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer le chart GitLab avec des images conformes FIPS
---

GitLab propose des versions [conformes FIPS](https://docs.gitlab.com/development/fips_gitlab/) de ses images, vous permettant d'exécuter GitLab sur des clusters FIPS activés.

Ces images sont basées sur les [Red Hat Universal Base Images](https://access.redhat.com/articles/4238681). Pour fonctionner en mode FIPS entièrement conforme, il est attendu que tous les hôtes soient configurés pour le mode FIPS.

## Exemples de valeurs {#sample-values}

Nous fournissons un exemple de valeurs pour le chart GitLab dans [`examples/fips/values.yaml`](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/examples/fips/values.yaml), qui peut vous aider à créer un déploiement GitLab compatible FIPS.

Notez le commentaire sous la clé `nginx-ingress.controller` qui fournit la configuration nécessaire pour utiliser une image NGINX Ingress Controller compatible FIPS. Cette image est maintenue dans notre [duplication du NGINX Ingress Controller](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-ingress-nginx).
