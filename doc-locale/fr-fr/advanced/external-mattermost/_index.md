---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer le chart GitLab avec Mattermost Team Edition
---

Ce document décrit comment installer le chart Helm Mattermost Team Edition à proximité d'un déploiement existant du chart Helm GitLab.

Comme le chart Helm Mattermost est installé dans un espace de nommage distinct, il est recommandé de configurer `cert-manager` et `nginx-ingress` pour gérer les ressources Ingress et les certificats à l'échelle du cluster. Pour plus d'informations sur la configuration, consultez le [guide de configuration Helm de Mattermost](https://github.com/mattermost/mattermost-helm/tree/master/charts/mattermost-team-edition#configuration).

## Prérequis {#prerequisites}

- Un cluster Kubernetes en cours d'exécution.
- [Helm v3](https://helm.sh/docs/intro/install/)

> [!note] Pour la Team Edition, vous ne pouvez avoir qu'une seule réplique en cours d'exécution.

## Déployer le chart Helm Mattermost Team Edition {#deploy-the-mattermost-team-edition-helm-chart}

Une fois le chart Helm Mattermost Team Edition installé, vous pouvez le déployer à l'aide de la commande suivante :

```shell
helm repo add mattermost https://helm.mattermost.com
helm repo update
helm upgrade --install mattermost -f values.yaml mattermost/mattermost-team-edition
```

Attendez que les pods soient en cours d'exécution. Ensuite, à l'aide de l'hôte Ingress que vous avez spécifié dans la configuration, accédez à votre serveur Mattermost.

Pour plus d'informations sur la configuration, consultez le [guide de configuration Helm de Mattermost](https://github.com/mattermost/mattermost-helm/tree/master/charts/mattermost-team-edition#configuration). Si vous rencontrez des problèmes, veuillez consulter le [dépôt d'issues du chart Helm Mattermost](https://github.com/mattermost/mattermost-helm/issues) ou le [forum Mattermost](https://forum.mattermost.com/search?q=helm).

## Déployer le chart Helm GitLab {#deploy-gitlab-helm-chart}

Pour déployer le chart Helm GitLab, suivez les [instructions d'installation](../../_index.md).

Voici une façon simplifiée de l'installer :

```shell
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600s \
  --set global.hosts.domain=<your-domain> \
  --set global.hosts.externalIP=<external-ip> \
  --set certmanager-issuer.email=<email>
```

- `<your-domain>` : votre domaine souhaité, tel que `gitlab.example.com`.
- `<external-ip>` : l'adresse IP externe pointant vers votre cluster Kubernetes.
- `<email>` : adresse e-mail à enregistrer dans Let's Encrypt pour récupérer les certificats TLS.

Une fois l'instance GitLab déployée, suivez les instructions relatives à la [connexion initiale](../../installation/deployment.md#initial-login).

## Créer une application OAuth avec GitLab {#create-an-oauth-application-with-gitlab}

La prochaine étape du processus consiste à configurer l'intégration SSO de GitLab. Pour ce faire, vous devez [créer l'application OAuth](https://docs.mattermost.com/deployment/sso-gitlab.html) pour permettre à Mattermost d'utiliser GitLab comme fournisseur d'authentification.

> [!note] Seul le SSO GitLab par défaut est officiellement pris en charge. Le « Double SSO », où le SSO GitLab est chaîné à d'autres solutions SSO, n'est pas pris en charge. Il peut être possible de connecter le SSO GitLab avec des modules complémentaires AD, LDAP, SAML ou MFA dans certains cas, mais en raison de la logique spéciale requise, ils ne sont pas officiellement pris en charge et il est avéré qu'ils ne fonctionnent pas dans certains contextes.

## Dépannage {#troubleshooting}

Si vous suivez un processus autre que celui fourni et rencontrez des problèmes d'authentification et/ou de déploiement, faites-le nous savoir dans le [forum de dépannage Mattermost](https://docs.mattermost.com/install/troubleshooting.html?&redirect_source=mm-org).
