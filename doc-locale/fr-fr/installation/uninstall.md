---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Désinstaller le chart Helm GitLab
---

Pour désinstaller le chart Helm GitLab, exécutez la commande suivante :

```shell
helm uninstall gitlab
```

Dans un souci de continuité, ces charts comportent certains objets Kubernetes qui ne sont pas supprimés lors de l'exécution de `helm uninstall`. Ce sont des éléments que nous vous demandons de supprimer _consciemment_, car ils affectent le redéploiement si vous choisissez de le faire.

- Les PVC pour les données avec état, que vous devez _consciemment_ supprimer
  - Gitaly :  Il s'agit des données de votre dépôt.
  - PostgreSQL (si interne) :  Il s'agit de vos métadonnées.
  - Redis (si interne) :  Il s'agit du cache et des files d'attente de job, qui peuvent être supprimés en toute sécurité.
- Les Secrets, s'ils sont générés par notre job shared-secrets. Ces charts sont conçus pour ne jamais générer de Secrets Kubernetes via Helm directement. De ce fait, Helm ne peut pas les supprimer. Ils contiennent des mots de passe, des secrets de chiffrement, etc. Ils ne doivent pas être détruits sans discernement.
- ConfigMaps
  - `ingress-controller-leader-RELEASE-nginx` :  Celui-ci est généré par le contrôleur Ingress NGINX lui-même et échappe au contrôle de notre chart. Il peut être supprimé en toute sécurité.

Les PVC et les Secrets ont le label `release` défini, vous pouvez donc les trouver avec :

```shell
kubectl get pvc,secret -lrelease=gitlab
```

> [!warning]
> Si vous ne supprimez pas manuellement le secret `RELEASE-gitlab-initial-root-password`, il sera réutilisé dans la prochaine release. Vous devez supprimer manuellement ce mot de passe s'il est exposé de quelque manière que ce soit, par exemple dans une démo enregistrée. Cela garantit que le mot de passe exposé ne pourra pas être utilisé pour se connecter à l'instance dans les futures releases.
