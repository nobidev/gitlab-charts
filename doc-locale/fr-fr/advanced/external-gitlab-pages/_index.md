---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer le chart GitLab avec GitLab Pages externe
---

Ce document vise à fournir de la documentation sur la façon de configurer ce chart Helm avec une instance GitLab Pages, configurée en dehors du cluster à l'aide d'un package Linux. [L'issue 418259](https://gitlab.com/gitlab-org/gitlab/-/issues/418259) propose d'ajouter de la documentation pour une instance de package Linux avec GitLab Pages externe utilisant le chart Helm.

## Prérequis {#requirements}

1. [Le stockage d'objets externe](../external-object-storage/_index.md), tel que recommandé pour les instances de production, doit être utilisé.
1. Forme encodée en Base64 d'une clé secrète API de 32 octets permettant à Pages d'interagir avec GitLab Pages.

## Limitations connues {#known-limitations}

1. [Le contrôle d'accès GitLab Pages](https://docs.gitlab.com/user/project/pages/pages_access_control/) n'est pas pris en charge nativement.

## Configurer l'instance GitLab Pages externe {#configure-external-gitlab-pages-instance}

1. [Installez GitLab](https://about.gitlab.com/install/) à l'aide du package Linux.

1. Modifiez le fichier `/etc/gitlab/gitlab.rb` et remplacez son contenu par l'extrait suivant. Mettez à jour les valeurs ci-dessous pour qu'elles correspondent à votre configuration :

   ```ruby
   roles ['pages_role']

   # Root domain where Pages will be served.
   pages_external_url '<Pages root domain>'  # Example: 'http://pages.example.io'

   # Information regarding GitLab instance
   gitlab_pages['gitlab_server'] = '<GitLab URL>'  # Example: 'https://gitlab.example.com'
   gitlab_pages['api_secret_key'] = '<Base64 encoded form of API secret key>'
   ```

1. Appliquez les modifications en exécutant `sudo gitlab-ctl reconfigure`.

## Configurer le chart {#configure-the-chart}

1. Créez un bucket nommé `gitlab-pages` dans le stockage d'objets pour stocker les déploiements Pages.

1. Créez un secret `gitlab-pages-api-key` avec la forme encodée en Base64 de la clé secrète API comme valeur.

   ```shell
   kubectl create secret generic gitlab-pages-api-key --from-literal="shared_secret=<Base 64 encoded API Secret Key>"
   ```

1. Référez-vous à l'extrait de configuration suivant et ajoutez les entrées nécessaires à votre fichier de valeurs.

   ```yaml
   global:
     pages:
       path: '/srv/gitlab/shared/pages'
       host: <Pages root domain>
       port: '80'  # Set to 443 if Pages is served over HTTPS
       https: false  # Set to true if Pages is served over HTTPS
       artifactsServer: true
       objectStore:
         enabled: true
         bucket: 'gitlab-pages'
       apiSecret:
         secret: gitlab-pages-api-key
         key: shared_secret
     extraEnv:
       PAGES_UPDATE_LEGACY_STORAGE: true  # Bypass automatic disabling of disk storage
   ```

   > [!note] En définissant la variable d'environnement `PAGES_UPDATE_LEGACY_STORAGE` sur true, le feature flag `pages_update_legacy_storage` est activé, ce qui déploie Pages sur le disque local. Lorsque vous migrez vers le stockage d'objets, pensez à supprimer cette variable.

1. [Déployez le chart](../../installation/deployment.md#deploy-using-helm) en utilisant cette configuration.
