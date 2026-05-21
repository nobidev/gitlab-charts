---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer le chart GitLab avec des volumes persistants
---

Certains des services inclus nécessitent un stockage persistant, configuré via des [Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) qui spécifient les disques auxquels votre cluster a accès. La documentation sur la configuration du stockage nécessaire pour installer ce chart se trouve dans notre [Guide de stockage](../../installation/storage.md).

Les modifications de stockage après l'installation doivent être gérées manuellement par les administrateurs de votre cluster. La gestion automatisée de ces volumes après l'installation n'est pas prise en charge par le chart GitLab.

Voici des exemples de modifications non gérées automatiquement après l'installation initiale :

- Montage de volumes différents sur les Pods
- Modification des accessModes effectifs ou de la [Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- Augmentation de la taille du stockage de votre volume. Dans Kubernetes 1.11, si vous avez configuré `allowVolumeExpansion` sur true dans votre [Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/), [l'augmentation de la taille du stockage de votre volume est prise en charge](https://kubernetes.io/blog/2018/07/12/resizing-persistent-volumes-using-kubernetes/).

L'automatisation de ces modifications est complexe pour les raisons suivantes :

1. Kubernetes ne permet pas de modifier la plupart des champs d'un [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) existant
1. Sauf [configuration manuelle](../../installation/storage.md), le [PVC](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) est la seule référence aux [PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) provisionnés dynamiquement
1. `Delete` est la [reclaimPolicy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy) par défaut pour les [PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) provisionnés dynamiquement

Cela signifie que pour apporter des modifications, nous devons supprimer le [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) et en créer un nouveau avec nos modifications. Mais en raison de la [reclaimPolicy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy) par défaut, la suppression du [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) peut entraîner la suppression des [PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) et du disque sous-jacent. Et à moins d'être configuré avec les volumeNames et/ou les labelSelectors appropriés, le chart ne connaît pas le volume auquel s'associer.

Nous continuerons à chercher comment simplifier ce processus, mais pour l'instant, un processus manuel doit être suivi pour apporter des modifications à votre stockage.

## Localiser les volumes GitLab {#locate-the-gitlab-volumes}

Trouvez les volumes/revendications en cours d'utilisation :

```shell
kubectl --namespace <namespace> get PersistentVolumeClaims -l release=<chart release name> -ojsonpath='{range .items[*]}{.spec.volumeName}{"\t"}{.metadata.labels.app}{"\n"}{end}'
```

- `<namespace>` doit être remplacé par l'espace de nommage dans lequel vous avez installé le chart GitLab.
- `<chart release name>` doit être remplacé par le nom que vous avez utilisé pour installer le chart GitLab.

La commande affiche une liste des noms de volumes, suivie du nom du service auquel ils sont associés.

Par exemple :

```shell
$ kubectl --namespace helm-charts-win get PersistentVolumeClaims -l release=review-update-app-h8qogp -ojsonpath='{range .items[*]}{.spec.volumeName}{"\t"}{.metadata.labels.app}{"\n"}{end}'
pvc-6247502b-8c2d-11e8-8267-42010a9a0113  gitaly
pvc-61bbc05e-8c2d-11e8-8267-42010a9a0113  minio
pvc-61bc6069-8c2d-11e8-8267-42010a9a0113  postgresql
pvc-61bcd6d2-8c2d-11e8-8267-42010a9a0113  prometheus
pvc-61bdf136-8c2d-11e8-8267-42010a9a0113  redis
```

## Avant d'apporter des modifications au stockage {#before-making-storage-changes}

La personne apportant les modifications doit disposer d'un accès administrateur au cluster et d'un accès approprié aux solutions de stockage utilisées. Souvent, les modifications devront d'abord être appliquées dans la solution de stockage, puis les résultats devront être mis à jour dans Kubernetes.

Avant d'apporter des modifications, vous devez vous assurer que vos [PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) utilisent la [reclaimPolicy](https://kubernetes.io/docs/concepts/storage/storage-classes/#reclaim-policy) `Retain` afin qu'ils ne soient pas supprimés pendant que vous effectuez des modifications.

Tout d'abord, [trouvez les volumes/revendications en cours d'utilisation](#locate-the-gitlab-volumes).

Ensuite, modifiez chaque volume et changez la valeur de `persistentVolumeReclaimPolicy` sous le champ `spec`, en lui attribuant la valeur `Retain` plutôt que `Delete`

Par exemple :

```shell
kubectl --namespace helm-charts-win edit PersistentVolume pvc-6247502b-8c2d-11e8-8267-42010a9a0113
```

Résultat de la modification :

```yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    kubernetes.io/createdby: gce-pd-dynamic-provisioner
    pv.kubernetes.io/bound-by-controller: "yes"
    pv.kubernetes.io/provisioned-by: kubernetes.io/gce-pd
  creationTimestamp: 2018-07-20T14:58:43Z
  labels:
    failure-domain.beta.kubernetes.io/region: europe-west2
    failure-domain.beta.kubernetes.io/zone: europe-west2-b
  name: pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  resourceVersion: "48362431"
  selfLink: /api/v1/persistentvolumes/pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  uid: 650bd649-8c2d-11e8-8267-42010a9a0113
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 50Gi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: repo-data-review-update-app-h8qogp-gitaly-0
    namespace: helm-charts-win
    resourceVersion: "48362307"
    uid: 6247502b-8c2d-11e8-8267-42010a9a0113
  gcePersistentDisk:
    fsType: ext4
    pdName: gke-cloud-native-81a17-pvc-6247502b-8c2d-11e8-8267-42010a9a0113
# Changed the following line
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
status:
  phase: Bound
```

## Apporter des modifications au stockage {#making-storage-changes}

Tout d'abord, apportez les modifications souhaitées au disque en dehors du cluster. (Redimensionner le disque dans GKE, ou créer un nouveau disque à partir d'un instantané ou d'un clone, etc.).

La façon dont vous procédez, et si cela peut être fait en direct, sans interruption de service, dépend des solutions de stockage que vous utilisez et ne peut pas être couverte par ce document.

Ensuite, évaluez si ces modifications doivent être répercutées dans les objets Kubernetes. Par exemple : en augmentant la taille du stockage sur disque, les paramètres de taille de stockage dans le [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) ne seront utilisés que lorsqu'une nouvelle ressource de volume sera demandée. Vous n'aurez donc besoin d'augmenter les valeurs dans le [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) que si vous avez l'intention d'augmenter le nombre de disques (pour une utilisation dans des pods Gitaly supplémentaires).

Si vous avez besoin que les modifications soient répercutées dans Kubernetes, assurez-vous d'avoir mis à jour votre politique de récupération sur les volumes comme décrit dans la section [Avant d'apporter des modifications au stockage](#before-making-storage-changes).

Les chemins que nous avons documentés pour les modifications de stockage sont les suivants :

- [Modifications d'un volume existant](#changes-to-an-existing-volume)
- [Basculement vers un volume différent](#switching-to-a-different-volume)

### Modifications d'un volume existant {#changes-to-an-existing-volume}

Commencez par [localiser le nom du volume](#locate-the-gitlab-volumes) que vous modifiez.

Utilisez `kubectl edit` pour apporter les modifications de configuration souhaitées au volume. (Ces modifications doivent uniquement être des mises à jour pour refléter l'état réel du disque attaché)

Par exemple :

```shell
kubectl --namespace helm-charts-win edit PersistentVolume pvc-6247502b-8c2d-11e8-8267-42010a9a0113
```

Résultat de la modification :

```yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    kubernetes.io/createdby: gce-pd-dynamic-provisioner
    pv.kubernetes.io/bound-by-controller: "yes"
    pv.kubernetes.io/provisioned-by: kubernetes.io/gce-pd
  creationTimestamp: 2018-07-20T14:58:43Z
  labels:
    failure-domain.beta.kubernetes.io/region: europe-west2
    failure-domain.beta.kubernetes.io/zone: europe-west2-b
  name: pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  resourceVersion: "48362431"
  selfLink: /api/v1/persistentvolumes/pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  uid: 650bd649-8c2d-11e8-8267-42010a9a0113
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    # Updated the storage size
    storage: 100Gi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: repo-data-review-update-app-h8qogp-gitaly-0
    namespace: helm-charts-win
    resourceVersion: "48362307"
    uid: 6247502b-8c2d-11e8-8267-42010a9a0113
  gcePersistentDisk:
    fsType: ext4
    pdName: gke-cloud-native-81a17-pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
status:
  phase: Bound
```

Maintenant que les modifications ont été répercutées dans le [volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes), nous devons mettre à jour la [revendication](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims).

Suivez les instructions de la section [Apporter des modifications au PersistentVolumeClaim](#make-changes-to-the-persistentvolumeclaim).

#### Mettre à jour le volume pour le lier à la revendication {#update-the-volume-to-bind-to-the-claim}

Dans un terminal séparé, commencez à surveiller le changement de statut de la [revendication](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) vers « lié », puis passez à l'étape suivante pour rendre le volume disponible pour utilisation dans la nouvelle revendication.

```shell
kubectl --namespace <namespace> get --watch PersistentVolumeClaim <claim name>
```

Modifiez le volume pour le rendre disponible à la nouvelle revendication. Supprimez la section `.spec.claimRef`.

```shell
kubectl --namespace <namespace> edit PersistentVolume <volume name>
```

Résultat de la modification :

```yaml
# Please edit the object below. Lines beginning with a '#' will be ignored,
# and an empty file will abort the edit. If an error occurs while saving this file will be
# reopened with the relevant failures.
#
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    kubernetes.io/createdby: gce-pd-dynamic-provisioner
    pv.kubernetes.io/bound-by-controller: "yes"
    pv.kubernetes.io/provisioned-by: kubernetes.io/gce-pd
  creationTimestamp: 2018-07-20T14:58:43Z
  labels:
    failure-domain.beta.kubernetes.io/region: europe-west2
    failure-domain.beta.kubernetes.io/zone: europe-west2-b
  name: pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  resourceVersion: "48362431"
  selfLink: /api/v1/persistentvolumes/pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  uid: 650bd649-8c2d-11e8-8267-42010a9a0113
spec:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 100Gi
  gcePersistentDisk:
    fsType: ext4
    pdName: gke-cloud-native-81a17-pvc-6247502b-8c2d-11e8-8267-42010a9a0113
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
status:
  phase: Released
```

Peu après avoir apporté la modification au [Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes), le terminal surveillant le statut de la revendication devrait afficher `Bound`.

Enfin, [appliquez les modifications au chart GitLab](#apply-the-changes-to-the-gitlab-chart)

### Basculement vers un volume différent {#switching-to-a-different-volume}

Si vous souhaitez basculer vers un nouveau volume, en utilisant un disque qui contient une copie des données appropriées de l'ancien volume, vous devez d'abord créer le nouveau [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) dans Kubernetes.

Pour créer un Persistent Volume pour votre disque, vous devrez localiser la [documentation spécifique au pilote](https://kubernetes.io/docs/concepts/storage/volumes/#types-of-volumes) pour votre type de stockage. Vous pouvez utiliser un Persistent Volume existant de la même [Storage Class](https://kubernetes.io/docs/concepts/storage/storage-classes/) comme point de départ :

```shell
kubectl --namespace <namespace> get PersistentVolume <volume name> -o yaml > <volume name>.bak.yaml
```

Il y a quelques points à garder à l'esprit lors de la consultation de la documentation du pilote :

- Vous devez utiliser le pilote pour créer un [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes), et non un objet Pod avec un volume comme indiqué dans une grande partie de la documentation.
- Vous ne souhaitez **pas** créer un [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) pour le volume, nous modifierons plutôt la revendication existante.

La documentation du pilote comprend souvent des exemples d'utilisation du pilote dans un Pod, par exemple :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: registry.k8s.io/test-webserver
    name: test-container
    volumeMounts:
    - mountPath: /test-pd
      name: test-volume
  volumes:
  - name: test-volume
    # This GCE PD must already exist.
    gcePersistentDisk:
      pdName: my-data-disk
      fsType: ext4
```

Ce que vous voulez réellement, c'est créer un [Persistent Volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes), comme suit :

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: test-volume
spec:
  capacity:
    storage: 400Gi
  accessModes:
  - ReadWriteOnce
  gcePersistentDisk:
    pdName: my-data-disk
    fsType: ext4
```

Vous créez généralement un fichier `yaml` local avec les informations du [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes), puis émettez une commande de création vers Kubernetes pour créer l'objet à partir du fichier.

```shell
kubectl --namespace <your namespace> create -f <local-pv-file>.yaml
```

Une fois votre volume créé, vous pouvez passer à [Apporter des modifications au PersistentVolumeClaim](#make-changes-to-the-persistentvolumeclaim)

## Apporter des modifications au PersistentVolumeClaim {#make-changes-to-the-persistentvolumeclaim}

Trouvez le [PersistentVolumeClaim](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) que vous souhaitez modifier.

```shell
kubectl --namespace <namespace> get PersistentVolumeClaims -l release=<chart release name> -ojsonpath='{range .items[*]}{.metadata.name}{"\t"}{.metadata.labels.app}{"\n"}{end}'
```

- `<namespace>` doit être remplacé par l'espace de nommage dans lequel vous avez installé le chart GitLab.
- `<chart release name>` doit être remplacé par le nom que vous avez utilisé pour installer le chart GitLab.

La commande affichera une liste des noms de PersistentVolumeClaim, suivie du nom du service auquel ils sont associés.

Ensuite, enregistrez une copie de la [revendication](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) sur votre système de fichiers local :

```shell
kubectl --namespace <namespace> get PersistentVolumeClaim <claim name> -o yaml > <claim name>.bak.yaml
```

Exemple de résultat :

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  annotations:
    pv.kubernetes.io/bind-completed: "yes"
    pv.kubernetes.io/bound-by-controller: "yes"
    volume.beta.kubernetes.io/storage-provisioner: kubernetes.io/gce-pd
  creationTimestamp: 2018-07-20T14:58:38Z
  labels:
    app: gitaly
    release: review-update-app-h8qogp
  name: repo-data-review-update-app-h8qogp-gitaly-0
  namespace: helm-charts-win
  resourceVersion: "48362433"
  selfLink: /api/v1/namespaces/helm-charts-win/persistentvolumeclaims/repo-data-review-update-app-h8qogp-gitaly-0
  uid: 6247502b-8c2d-11e8-8267-42010a9a0113
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 50Gi
  storageClassName: standard
  volumeName: pvc-6247502b-8c2d-11e8-8267-42010a9a0113
status:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 50Gi
  phase: Bound
```

Créez un nouveau fichier YAML pour un nouvel objet PVC. Faites-lui utiliser les mêmes champs `metadata.name`, `metadata.labels`, `metadata.namespace` et `spec` (avec vos mises à jour appliquées) et supprimez les autres paramètres :

Exemple :

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app: gitaly
    release: review-update-app-h8qogp
  name: repo-data-review-update-app-h8qogp-gitaly-0
  namespace: helm-charts-win
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      # This is our updated field
      storage: 100Gi
  storageClassName: standard
  volumeName: pvc-6247502b-8c2d-11e8-8267-42010a9a0113
```

Supprimez maintenant l'ancienne [revendication](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) :

```shell
kubectl --namespace <namespace> delete PersistentVolumeClaim <claim name>
```

Vous devrez peut-être effacer `finalizers` pour permettre à la suppression de se terminer :

```shell
kubectl --namespace <namespace> patch PersistentVolumeClaim <claim name> -p '{"metadata":{"finalizers":null}}'
```

Créez la nouvelle revendication :

```shell
kubectl --namespace <namespace> create -f <new claim yaml file>
```

Si vous liez au même [PersistentVolume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) qui était précédemment lié à la revendication, passez à [la mise à jour du volume pour le lier à la revendication](#update-the-volume-to-bind-to-the-claim)

Sinon, si vous avez lié la revendication à un nouveau volume, passez à [l'application des modifications au chart GitLab](#apply-the-changes-to-the-gitlab-chart)

## Appliquer les modifications au chart GitLab {#apply-the-changes-to-the-gitlab-chart}

Après avoir apporté des modifications aux [PersistentVolumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistent-volumes) et aux [PersistentVolumeClaims](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims), vous souhaiterez également émettre une mise à jour Helm avec les modifications appliquées aux paramètres du chart.

Consultez le [guide de stockage d'installation](../../installation/storage.md#using-the-custom-storage-class) pour les options.

Si vous avez apporté des modifications à la [revendication de volume](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#persistentvolumeclaims) Gitaly, vous devrez supprimer le [StatefulSet](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/) Gitaly avant de pouvoir émettre une mise à jour Helm. En effet, le modèle de volume du StatefulSet est immuable et ne peut pas être modifié.

Vous pouvez supprimer le StatefulSet sans supprimer les pods Gitaly :

```shell
kubectl --namespace <namespace> delete --cascade=orphan StatefulSet <release-name>-gitaly
```

La commande de mise à jour Helm recréera le StatefulSet, qui adoptera et mettra à jour les pods Gitaly.

Mettez à jour le chart et incluez la configuration mise à jour :

Exemple :

```shell
helm upgrade --install review-update-app-h8qogp gitlab/gitlab \
  --set gitlab.gitaly.persistence.size=100Gi \
  <your other config settings>
```
