---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer le stockage pour le chart GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Les applications suivantes dans le chart GitLab nécessitent un stockage persistant pour maintenir leur état.

- [Gitaly](../charts/gitlab/gitaly/_index.md) (persiste les dépôts Git)
- [MinIO](../charts/minio/_index.md) (persiste les données de stockage d'objets)

L'administrateur peut choisir de provisionner ce stockage à l'aide du provisionnement de volume [dynamique](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic) ou [statique](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#static).

> **Important** :  Minimisez les tâches supplémentaires de migration de stockage après l'installation grâce à une planification préalable. Les modifications effectuées après le premier déploiement nécessitent des modifications manuelles des objets Kubernetes existants avant d'exécuter `helm upgrade`.

## Comportement typique lors de l'installation {#typical-installation-behavior}

Le programme d'installation crée le stockage à l'aide de la classe de stockage par défaut et du [provisionnement de volume dynamique](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic). Les applications se connectent à ce stockage via un [Persistent Volume Claim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims). Les administrateurs sont encouragés à utiliser le [provisionnement de volume dynamique](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#dynamic) plutôt que le [provisionnement de volume statique](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#static) lorsqu'il est disponible.

> Les administrateurs doivent déterminer la classe de stockage par défaut dans leur environnement de production à l'aide de `kubectl get storageclass`, puis l'examiner à l'aide de `kubectl describe storageclass *STORAGE_CLASS_NAME*`. Certains fournisseurs, tels qu'Amazon EKS, ne fournissent pas de classe de stockage par défaut.

## Configuration du stockage du cluster {#configuring-cluster-storage}

### Recommandations {#recommendations}

La classe de stockage par défaut doit :

- Utiliser un stockage SSD rapide lorsqu'il est disponible
- Définir `reclaimPolicy` sur `Retain`

> La désinstallation de GitLab sans que `reclaimPolicy` soit défini sur `Retain` permet aux jobs automatisés de supprimer complètement le volume, le disque et les données. Certaines plateformes définissent le `reclaimPolicy` par défaut sur `Delete`. Les revendications de volume persistant `gitaly` ne suivent pas cette règle car elles appartiennent à un [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/).

### Configurations minimales des classes de stockage {#minimal-storage-class-configurations}

Les configurations `YAML` suivantes fournissent le strict minimum requis pour créer une classe de stockage personnalisée pour GitLab. Remplacez `CUSTOM_STORAGE_CLASS_NAME` par une valeur appropriée pour l'environnement d'installation cible.

- [Exemple de classe de stockage pour GKE sur Google Cloud](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gke_storage_class.yml)
- [Exemple de classe de stockage pour EKS sur Amazon Web Services](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/eks_storage_class.yml)

> Certains utilisateurs signalent qu'Amazon EKS présente un comportement où la création de nœuds n'est pas toujours dans la même zone que les pods. La définition du paramètre ***zone*** ci-dessus permettra d'atténuer tout risque.

### Utilisation de la classe de stockage personnalisée {#using-the-custom-storage-class}

Définissez la classe de stockage personnalisée comme valeur par défaut du cluster et elle sera utilisée pour tout le provisionnement dynamique.

```shell
kubectl patch storageclass CUSTOM_STORAGE_CLASS_NAME -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

La classe de stockage personnalisée et d'autres options peuvent également être fournies par service à Helm lors de l'installation. Consultez le [fichier de configuration d'exemple](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/helm_options.yml) fourni et modifiez-le pour votre environnement.

```shell
helm install -upgrade gitlab gitlab/gitlab -f HELM_OPTIONS_YAML_FILE
```

Suivez les liens ci-dessous pour en savoir plus et pour connaître les options de persistance supplémentaires :

- [Configuration de la persistance Gitaly](../charts/gitlab/gitaly/_index.md#git-repository-persistence)
- [Configuration de la persistance MinIO](../charts/minio/_index.md#persistence)

## Utilisation du provisionnement de volume statique {#using-static-volume-provisioning}

Le provisionnement de volume dynamique est recommandé, cependant, certains clusters ou environnements peuvent ne pas le prendre en charge. Les administrateurs devront créer le [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) manuellement.

### Utilisation de Google GKE {#using-google-gke}

1. [Créez un disque persistant dans le cluster.](https://kubernetes.io/docs/concepts/storage/volumes/#creating-a-pd)

```shell
gcloud compute disks create --size=50GB --zone=*GKE_ZONE* *DISK_VOLUME_NAME*
```

1. Créez le Persistent Volume après avoir modifié l'[exemple de configuration `YAML`](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gke_pv_example.yml).

```shell
kubectl create -f *PV_YAML_FILE*
```

### Utilisation d'Amazon EKS {#using-amazon-eks}

Si vous devez déployer dans plusieurs zones, vous devriez consulter [la documentation d'Amazon sur les classes de stockage](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html) lors de la définition de votre solution de stockage.

1. [Créez un disque persistant dans le cluster.](https://kubernetes.io/docs/concepts/storage/volumes/#creating-an-ebs-volume)

```shell
aws ec2 create-volume --availability-zone=*AWS_ZONE* --size=10 --volume-type=gp2
```

1. Créez le Persistent Volume après avoir modifié l'[exemple de configuration `YAML`](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/eks_pv_example.yml).

```shell
kubectl create -f *PV_YAML_FILE*
```

### Création manuelle de PersistentVolumeClaims {#manually-creating-persistentvolumeclaims}

Le service Gitaly se déploie à l'aide d'un [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/). Créez le [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) en utilisant la convention de nommage suivante pour qu'il soit correctement reconnu et utilisé.

```plaintext
<mount-name>-<statefulset-pod-name>
```

Le `mount-name` pour Gitaly est `repo-data`. Les noms de pods StatefulSet sont créés à l'aide de :

```plaintext
<statefulset-name>-<pod-index>
```

Le chart GitLab détermine le `statefulset-name` à l'aide de :

```plaintext
<chart-release-name>-<service-name>
```

Le nom correct pour le PersistentVolumeClaim Gitaly est : `repo-data-gitlab-gitaly-0`.

> **Note** :  Si vous utilisez Praefect avec plusieurs stockages virtuels, vous aurez besoin d'un PersistentVolumeClaim par réplica Gitaly par stockage virtuel défini. Par exemple, si vous avez les stockages virtuels `default` et `vs2` définis, chacun avec 2 réplicas, vous aurez besoin des PersistentVolumeClaims suivants :
>
> - `repo-data-gitlab-gitaly-default-0`
> - `repo-data-gitlab-gitaly-default-1`
> - `repo-data-gitlab-gitaly-vs2-0`
> - `repo-data-gitlab-gitaly-vs2-1`

Modifiez la [configuration YAML d'exemple](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/gitaly_persistent_volume_claim.yml) pour votre environnement et référencez-la lors de l'invocation de `helm`.

> Les autres services qui n'utilisent pas de [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) permettent aux administrateurs de fournir le `volumeName` à la configuration. Ce chart se chargera tout de même de créer la [revendication de volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) et tentera de se lier au volume créé manuellement. Consultez la documentation du chart pour chaque application incluse.
>
> Dans la plupart des cas, modifiez simplement la [configuration YAML d'exemple](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/storage/use_manual_volumes.yml) en ne conservant que les services qui utiliseront les volumes de disque créés manuellement.

## Apporter des modifications au stockage après l'installation {#making-changes-to-storage-after-installation}

Après l'installation initiale, les modifications de stockage telles que la migration vers de nouveaux volumes ou la modification de la taille des disques nécessitent de modifier les objets Kubernetes en dehors de la commande de mise à niveau Helm.

Consultez la [documentation sur la gestion des volumes persistants](../advanced/persistent-volumes/_index.md).

## Volumes optionnels {#optional-volumes}

Pour les installations plus importantes, vous devrez peut-être ajouter un stockage persistant au Toolbox pour que les sauvegardes/restaurations fonctionnent. Consultez notre [documentation de dépannage](../backup-restore/_index.md#pod-eviction-issues) pour obtenir un guide sur la façon de procéder.
