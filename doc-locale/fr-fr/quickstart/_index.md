---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Tester le chart GitLab sur GKE ou EKS
---

Ce guide constitue une documentation concise mais complète sur la manière d'installer le chart GitLab avec les valeurs par défaut sur Google Kubernetes Engine (GKE) ou Amazon Elastic Kubernetes Service (EKS).

> [!note] 
> Le chart par défaut inclut un service MinIO intégré à des fins d'évaluation uniquement. PostgreSQL et Redis doivent être configurés de manière externe. Pour déployer GitLab en production, suivez le [guide d'installation](../installation/_index.md).

## Prérequis {#prerequisites}

Pour suivre ce guide, vous devez disposer des éléments suivants :

- Un domaine qui vous appartient, auquel vous pouvez ajouter un enregistrement DNS.
- Un cluster Kubernetes.
- Une installation fonctionnelle de `kubectl`.
- Une installation fonctionnelle de Helm v3.

### Domaine disponible {#available-domain}

Vous devez avoir accès à un domaine accessible sur Internet auquel vous pouvez ajouter un enregistrement DNS. Il peut s'agir d'un sous-domaine tel que `poc.domain.com`, mais les serveurs Let's Encrypt doivent pouvoir résoudre les adresses afin d'émettre des certificats.

### Créer un cluster Kubernetes {#create-a-kubernetes-cluster}

Un cluster avec un total d'au moins huit CPU virtuels et 30 Go de RAM est recommandé.

Vous pouvez soit consulter les instructions de vos fournisseurs de cloud sur la façon de créer un cluster Kubernetes, soit utiliser les scripts fournis par GitLab pour [automatiser la création du cluster](../installation/cloud/_index.md).

> [!warning] 
> Les nœuds Kubernetes prennent en charge les architectures x86-64 et ARM64. Les images validées FIPS sont uniquement disponibles pour x86-64. Consultez le [ticket 2285](https://gitlab.com/gitlab-org/build/CNG/-/issues/2285) pour connaître le statut FIPS ARM64.

### Installer kubectl {#install-kubectl}

Pour installer kubectl, consultez la [documentation d'installation Kubernetes](https://kubernetes.io/docs/tasks/tools/). La documentation couvre la plupart des systèmes d'exploitation ainsi que le Google Cloud SDK, que vous avez peut-être installé lors de l'étape précédente.

Après avoir créé le cluster, vous devez [configurer `kubectl`](https://cloud.google.com/kubernetes-engine/docs/how-to/cluster-access-for-kubectl#generate_kubeconfig_entry) avant de pouvoir interagir avec le cluster depuis la ligne de commande.

### Installer Helm {#install-helm}

Pour ce guide, nous utilisons la dernière release de Helm v3 (version v3.9.4 ou ultérieure). Pour installer Helm, consultez la [documentation d'installation Helm](https://helm.sh/docs/intro/install/).

## Ajouter le dépôt Helm GitLab {#add-the-gitlab-helm-repository}

Ajoutez le dépôt Helm GitLab à la configuration de `helm` :

```shell
helm repo add gitlab https://charts.gitlab.io/
```

## Installer GitLab {#install-gitlab}

C'est la puissance de ce chart : il suffit d'une seule commande pour entièrement installer et configurer GitLab avec SSL.

Pour configurer le chart, vous avez besoin de :

- Le domaine ou sous-domaine sous lequel GitLab doit fonctionner.
- Votre adresse e-mail, afin que Let's Encrypt puisse émettre un certificat.

Pour installer le chart, exécutez la commande d'installation avec deux arguments `--set` :

```shell
helm install gitlab gitlab/gitlab \
  --set global.hosts.domain=DOMAIN \
  --set certmanager-issuer.email=me@example.com
```

Cette étape peut prendre plusieurs minutes afin que toutes les ressources soient allouées, que les services démarrent et que l'accès soit disponible.

Une fois terminé, vous pouvez procéder à la collecte de l'adresse IP qui a été allouée dynamiquement pour le NGINX Ingress installé.

## Récupérer l'adresse IP {#retrieve-the-ip-address}

Vous pouvez utiliser `kubectl` pour récupérer l'adresse qui a été allouée dynamiquement par GKE au NGINX Ingress que vous venez d'installer et configurée dans le cadre du chart GitLab :

```shell
kubectl get ingress -lrelease=gitlab
```

Les données de sortie devraient ressembler à ce qui suit :

```plaintext
NAME               HOSTS                 ADDRESS         PORTS     AGE
gitlab-minio       minio.domain.tld      35.239.27.235   80, 443   118m
gitlab-registry    registry.domain.tld   35.239.27.235   80, 443   118m
gitlab-webservice  gitlab.domain.tld     35.239.27.235   80, 443   118m
```

Vous remarquerez qu'il y a trois entrées, toutes avec la même adresse IP. Prenez cette adresse IP et ajoutez-la à votre DNS pour le domaine que vous avez choisi d'utiliser. Vous pouvez ajouter plusieurs enregistrements de type `A`, mais pour simplifier, nous recommandons un seul enregistrement « générique » :

- Dans Google Cloud DNS, créez un enregistrement `A` avec le nom `*`. Nous suggérons également de définir le TTL à `1` minute au lieu de `5` minutes.
- Sur AWS EKS, l'adresse sera une URL plutôt qu'une adresse IP. [Créez un enregistrement alias Route 53](https://repost.aws/knowledge-center/route-53-create-alias-records) `*.domain.tld` pointant vers cette URL.

## Se connecter à GitLab {#sign-in-to-gitlab}

Vous pouvez accéder à GitLab à l'adresse `gitlab.domain.tld`. Par exemple, si vous définissez `global.hosts.domain=my.domain.tld`, vous accéderez alors à `gitlab.my.domain.tld`.

Pour vous connecter, vous devez récupérer le mot de passe de l'utilisateur `root`. Celui-ci est automatiquement généré au moment de l'installation et stocké dans un secret Kubernetes. Récupérons ce mot de passe depuis le secret et décodons-le :

```shell
kubectl get secret gitlab-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

Vous pouvez maintenant vous connecter à GitLab avec le nom d'utilisateur `root` et le mot de passe récupéré. Vous pouvez modifier ce mot de passe via les préférences utilisateur après vous être connecté ; nous le générons uniquement pour sécuriser la première connexion en votre nom.

## Dépannage {#troubleshooting}

Si vous rencontrez des problèmes lors de ce guide, voici quelques points que vous devriez vérifier :

1. Le `gitlab.my.domain.tld` est résolu vers l'adresse IP de l'Ingress que vous avez récupérée.
2. Si vous obtenez un avertissement de certificat, un problème est survenu avec Let's Encrypt, généralement lié au DNS ou à la nécessité de réessayer.

Pour d'autres conseils de dépannage, consultez notre guide de [dépannage](../troubleshooting/_index.md).

### L'installation Helm retourne `roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden` {#helm-install-returns-rolesrbacauthorizationk8sio-gitlab-shared-secrets-is-forbidden}

Après avoir exécuté :

```shell
helm install gitlab gitlab/gitlab  \
  --set global.hosts.domain=DOMAIN \
  --set certmanager-issuer.email=user@example.com
```

Vous pourriez voir une erreur similaire à :

```shell
Error: failed pre-install: warning: Hook pre-install templates/shared-secrets-rbac-config.yaml failed: roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden: user "some-user@some-domain.com" (groups=["system:authenticated"]) is attempting to grant RBAC permissions not currently held:
{APIGroups:[""], Resources:["secrets"], Verbs:["get" "list" "create" "patch"]}
```

Cela signifie que le contexte `kubectl` que vous utilisez pour vous connecter au cluster ne dispose pas des autorisations nécessaires pour créer des ressources avec [contrôle d'accès basé sur les rôles](../installation/rbac.md).
