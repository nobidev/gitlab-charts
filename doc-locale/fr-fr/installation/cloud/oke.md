---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Préparation des ressources OKE pour le chart GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Pour disposer d'une instance GitLab pleinement fonctionnelle, vous avez besoin de quelques ressources avant de déployer le chart GitLab sur [Oracle Container Engine for Kubernetes (OKE)](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengoverview.htm). Découvrez comment [préparer](https://docs.oracle.com/en-us/iaas/Content/ContEng/Concepts/contengprerequisites.htm) votre location Oracle Cloud Infrastructure avant de créer le cluster OKE.

## Création du cluster OKE {#creating-the-oke-cluster}

Prérequis :

- Installez les [prérequis](../tools.md).

Pour provisionner le cluster Kubernetes manuellement, suivez les [instructions OKE](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingclusterusingoke.htm). Consultez la liste des [shapes](https://docs.oracle.com/en-us/iaas/Content/ContEng/Reference/contengimagesshapes.htm#shapes) de calcul disponibles pour les nœuds worker pris en charge par OKE.

Un cluster avec 4 OCPUs et 30 Go de RAM est recommandé.

### Accès externe à GitLab {#external-access-to-gitlab}

Par défaut, le chart GitLab déploie un contrôleur Ingress qui crée un équilibreur de charge public Oracle Cloud Infrastructure avec une shape de 100 Mbps. Le service Load Balancer attribue une adresse IP publique flottante qui ne provient pas du sous-réseau hôte.

Pour modifier la shape et d'autres configurations (port, SSL, listes de sécurité, etc.) lors de l'installation du chart, vous pouvez utiliser l'argument de ligne de commande suivant `nginx-ingress.controller.service.annotations`. Par exemple, pour spécifier un Load Balancer avec une shape de 400 Mbps :

```shell
--set nginx-ingress.controller.service.annotations."service\.beta\.kubernetes\.io/oci-load-balancer-shape"="400Mbps"
```

Une fois déployé, vous pouvez vérifier les annotations associées au service du contrôleur Ingress :

```plaintext
$ kubectl get service gitlab-nginx-ingress-controller -o yaml

apiVersion: v1
kind: Service
metadata:
  annotations:
    ...
    service.beta.kubernetes.io/oci-load-balancer-shape: 400Mbps
    ...
```

Consultez la [documentation OKE Load Balancer](https://docs.oracle.com/en-us/iaas/Content/ContEng/Tasks/contengcreatingloadbalancer.htm) pour plus d'informations.

## Étapes suivantes {#next-steps}

Une fois le cluster opérationnel, poursuivez avec l'[installation du chart](../deployment.md). Définissez le nom de domaine DNS via l'option `global.hosts.domain`, mais omettez le paramètre d'IP statique via l'option `global.hosts.externalIP`.

Après avoir effectué le déploiement, vous pouvez interroger l'adresse IP du Load Balancer à associer au type d'enregistrement DNS :

```shell
kubectl get ingress/<RELEASE>-webservice-default -ojsonpath='{.status.loadBalancer.ingress[0].ip}'
```

`<RELEASE>` doit être remplacé par le nom de release utilisé dans `helm install <RELEASE>`.
