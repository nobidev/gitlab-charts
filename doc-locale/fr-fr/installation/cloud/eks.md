---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Préparation des ressources EKS pour le chart GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Pour une instance GitLab entièrement fonctionnelle, vous avez besoin de quelques ressources avant de déployer le chart GitLab.

## Création du cluster EKS {#creating-the-eks-cluster}

Pour faciliter le démarrage, un script est fourni pour automatiser la création du cluster. Vous pouvez également créer un cluster manuellement.

Prérequis :

- Installez les [prérequis](../tools.md).
- Installez [`eksctl`](https://github.com/weaveworks/eksctl#installation).

Pour créer le cluster manuellement, consultez [Amazon AWS Getting started with Amazon EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started-eksctl.html). Utilisez des nœuds gérés EC2 pour le cluster EKS, et non [Fargate](https://docs.aws.amazon.com/en_us/eks/latest/userguide/fargate.html). Fargate présente un certain nombre de limitations et n'est pas pris en charge pour une utilisation avec le chart Helm GitLab.

### Création scriptée du cluster {#scripted-cluster-creation}

Un [script de bootstrap](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/scripts/eks_bootstrap_script) a été créé pour automatiser une grande partie du processus de configuration pour les utilisateurs sur EKS. Vous devez cloner ce dépôt avant d'exécuter le script.

Le script va :

1. Créer un nouveau cluster EKS.
1. Configurer `kubectl` et le connecter au cluster.

Pour l'authentification, `eksctl` utilise les mêmes options que la ligne de commande AWS. Consultez la documentation AWS pour savoir comment utiliser les [variables d'environnement](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-envvars.html) ou les [fichiers de configuration](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html).

Le script lit divers paramètres à partir de variables d'environnement ou d'arguments de ligne de commande, et l'argument `up` pour le bootstrap ou `down` pour le nettoyage.

Le tableau ci-dessous décrit toutes les variables.

| Variable          | Valeur par défaut    | Description |
|-------------------|------------------|-------------|
| `REGION`          | `us-east-2`      | La région où se trouve votre cluster |
| `CLUSTER_NAME`    | `gitlab-cluster` | Le nom du cluster |
| `CLUSTER_VERSION` | `1.29`           | La version de votre cluster EKS |
| `NUM_NODES`       | `2`              | Le nombre de nœuds requis |
| `MACHINE_TYPE`    | `m5.xlarge`      | Le type de nœuds à déployer |

Exécutez le script en transmettant les paramètres souhaités. Il peut fonctionner avec les paramètres par défaut.

```shell
./scripts/eks_bootstrap_script up
```

Le script peut également être utilisé pour nettoyer les ressources EKS créées :

```shell
./scripts/eks_bootstrap_script down
```

### Création manuelle du cluster {#manual-cluster-creation}

- Nous recommandons un cluster avec 8 vCPU et 30 Go de RAM.

Pour les instructions les plus récentes, suivez le [guide de démarrage EKS](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html) d'Amazon.

Les administrateurs peuvent également envisager le [nouvel opérateur de service AWS pour Kubernetes](https://aws.amazon.com/blogs/opensource/aws-service-operator-kubernetes-available/) pour simplifier ce processus.

> [!note] L'activation de l'opérateur de service AWS nécessite une méthode de gestion des rôles au sein du cluster. Les services initiaux gérant cette tâche de gestion sont fournis par des développeurs tiers. Les administrateurs doivent en tenir compte lors de la planification du déploiement.

## Gestion des volumes persistants {#persistent-volume-management}

Il existe deux méthodes pour gérer les demandes de volumes sur Kubernetes :

- Créer manuellement un volume persistant.
- Création automatique de volumes persistants via le provisionnement dynamique.

Nous recommandons actuellement d'utiliser le provisionnement manuel des volumes persistants. Les clusters Amazon EKS s'étendent par défaut sur plusieurs zones. Le provisionnement dynamique, s'il n'est pas configuré pour utiliser une classe de stockage verrouillée sur une zone particulière, conduit à un scénario où les pods peuvent exister dans une zone différente de celle des volumes de stockage et être incapables d'accéder aux données. Pour plus d'informations, consultez comment [provisionner des volumes persistants](../storage.md).

Dans les clusters Amazon EKS 1.23 et versions ultérieures, que vous utilisiez le provisionnement manuel ou dynamique, vous devez installer le [module complémentaire Amazon EBS CSI](https://docs.aws.amazon.com/eks/latest/userguide/managing-ebs-csi.html#adding-ebs-csi-eks-add-on) sur le cluster.

```shell
eksctl utils associate-iam-oidc-provider --cluster **CLUSTER_NAME** --approve

eksctl create iamserviceaccount \
    --name ebs-csi-controller-sa \
    --namespace kube-system \
    --cluster **CLUSTER_NAME** \
    --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
    --approve \
    --role-only \
    --role-name *ROLE_NAME*

eksctl create addon --name aws-ebs-csi-driver --cluster **CLUSTER_NAME** --service-account-role-arn arn:aws:iam::*AWS_ACCOUNT_ID*:role/*ROLE_NAME* --force

kubectl annotate serviceaccount ebs-csi-controller-sa -n kube-system eks.amazonaws.com/role-arn=arn:aws:iam::*AWS_ACCOUNT_ID*:role/*ROLE_NAME*
```

## Accès externe à GitLab {#external-access-to-gitlab}

Par défaut, l'installation du chart GitLab déploie un Ingress qui crée un Elastic Load Balancer (ELB) associé. Étant donné que les noms DNS de l'ELB ne peuvent pas être connus à l'avance, il est difficile d'utiliser [Let's Encrypt](https://letsencrypt.org/) pour provisionner automatiquement des certificats HTTPS.

Nous recommandons d'[utiliser vos propres certificats](../tls.md#option-2-use-your-own-wildcard-certificate), puis de mapper le nom DNS souhaité vers l'ELB créé à l'aide d'un enregistrement CNAME. Étant donné que l'ELB doit être créé en premier avant que son nom d'hôte puisse être récupéré, suivez les prochaines instructions pour installer GitLab.

> [!note] Pour les environnements où des LoadBalancers AWS sont requis, les [Elastic Load Balancers d'Amazon](https://docs.aws.amazon.com/eks/latest/userguide/load-balancing.html) nécessitent une configuration spécialisée. Consultez [Cloud provider LoadBalancers](../../charts/globals.md#cloud-provider-loadbalancers)

## Étapes suivantes {#next-steps}

Continuez avec l'[installation du chart](../deployment.md) une fois que votre cluster est opérationnel. Définissez le nom de domaine via l'option `global.hosts.domain`, mais omettez le paramètre d'IP statique via l'option `global.hosts.externalIP` sauf si vous prévoyez d'utiliser une Elastic IP existante.

Après l'installation Helm, vous pouvez récupérer le nom d'hôte de votre ELB à placer dans l'enregistrement CNAME avec la commande suivante :

```shell
kubectl get ingress/RELEASE-webservice-default -ojsonpath='{.status.loadBalancer.ingress[0].hostname}'
```

`RELEASE` doit être remplacé par le nom de la release utilisé dans `helm install <RELEASE>`.
