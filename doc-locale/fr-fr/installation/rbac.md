---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer RBAC pour le chart GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Jusqu'à Kubernetes 1.7, il n'existait aucune permission au sein d'un cluster. Avec le lancement de la version 1.7, il existe désormais un système de contrôle d'accès basé sur les rôles ([RBAC](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)) qui détermine quels services peuvent effectuer des actions au sein d'un cluster.

RBAC affecte plusieurs aspects différents de GitLab :

- Installation de GitLab avec Helm
- Surveillance Prometheus
- GitLab Runner
- Base de données PostgreSQL intégrée au cluster (lorsque RBAC est activé pour elle)
- Gestionnaire de certificats

## Vérifier que RBAC est activé {#checking-that-rbac-is-enabled}

Essayez de lister les rôles actuels du cluster ; en cas d'échec, `RBAC` est désactivé

Cette commande renvoie `false` si `RBAC` est désactivé et `true` dans le cas contraire

`kubectl get clusterroles > /dev/null 2>&1 && echo true || echo false`

## Comptes de service {#service-accounts}

Le chart GitLab utilise des comptes de service pour effectuer certaines tâches. Ces comptes et leurs rôles associés sont créés et gérés par le chart.

Les comptes de service sont décrits dans le tableau suivant. Pour chaque compte de service, le tableau indique :

- Le suffixe du nom (le préfixe est le nom de la release).
- Une brève description. Par exemple, où il est utilisé ou à quoi il sert.
- Les rôles associés et le niveau d'accès dont ils disposent sur quelles ressources. Le niveau d'accès est soit en lecture seule (R), en écriture seule (W), soit en lecture-écriture (RW). Notez que le nom de groupe des ressources est omis.
- La portée des rôles, qui est soit le cluster (C), soit le espace de nommage (NS). Dans certains cas, la portée des rôles peut être configurée avec l'une ou l'autre valeur (indiquée par NS/C)

| Suffixe du nom      | Description                                                                               | Rôles                                                                  | Portée |
|:-----------------|:------------------------------------------------------------------------------------------|:-----------------------------------------------------------------------|:------|
| `gitlab-runner`  | Le GitLab Runner est exécuté avec ce compte.                                          | Toute ressource (RW)                                                      | NS/C  |
| `ingress-nginx`  | Utilisé par NGINX Ingress pour contrôler les points d'accès aux services.                                   | Secret, Pod, Endpoint, Ingress (R) ; Event (W) ; ConfigMap, Service (RW) | NS/C  |
| `shared-secrets` | Le job qui crée les secrets partagés s'exécute avec ce compte (dans le hook de pré-installation/mise à niveau). | Secret (RW)                                                            | NS    |
| `cert-manager`   | Le job qui contrôle le gestionnaire de certificats s'exécute avec ce compte.                         | Issuer, Certificate, CertificateRequest, Order (RW)                    | NS/C  |

Le chart GitLab dépend d'autres charts qui utilisent également RBAC et créent leurs propres comptes de service et liaisons de rôles. Voici un aperçu :

- La surveillance Prometheus crée par défaut plusieurs comptes de service qui lui sont propres. Ils sont tous associés à des rôles au niveau du cluster. Pour plus d'informations, consultez [la documentation du chart Prometheus](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#rbac-configuration).
- Le gestionnaire de certificats crée par défaut un compte de service pour gérer ses ressources personnalisées ainsi que les ressources natives au niveau du cluster. Pour plus d'informations, consultez [le modèle RBAC du chart cert-manager](https://github.com/cert-manager/cert-manager/blob/master/deploy/charts/cert-manager/templates/rbac.yaml).
