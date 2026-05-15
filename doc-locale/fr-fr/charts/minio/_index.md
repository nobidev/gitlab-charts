---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utilisation de MinIO pour le stockage d'objets"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

> [!note]
> Le chart MinIO intégré n'est pas prêt pour la production. Pour un déploiement de chart GitLab prêt pour la production, utilisez une solution de stockage d'objets externe.
>
> Pour obtenir des informations sur la migration depuis le chart MinIO intégré, consultez [migrer depuis Redis, PostgreSQL et MinIO intégrés](../../installation/migration/bundled_chart_migration.md).

Ce chart est basé sur [`stable/minio`](https://github.com/helm/charts/tree/master/stable/minio) version [`0.4.3`](https://github.com/helm/charts/tree/aaaf98b5d25c26cc2d483925f7256f2ce06be080/stable/minio), et hérite de la plupart des paramètres de celui-ci.

## Choix de conception {#design-choices}

Les choix de conception liés au [chart en amont](https://github.com/helm/charts/tree/master/stable/minio) se trouvent dans le fichier README du projet.

GitLab a choisi de modifier ce chart afin de simplifier la configuration des secrets et de supprimer toute utilisation des secrets dans les variables d'environnement. GitLab a ajouté des `initContainer`s pour contrôler le remplissage des secrets dans le `config.json`, ainsi qu'un indicateur `enabled` à l'échelle du chart.

Ce chart n'utilise qu'un seul secret :

- `global.minio.credentials.secret` :  Un secret global contenant les valeurs `accesskey` et `secretkey` qui seront utilisées pour l'authentification auprès du ou des buckets.

## Configuration {#configuration}

Nous décrirons ci-dessous toutes les sections principales de la configuration. Lors de la configuration depuis le chart parent, ces valeurs seront :

```yaml
minio:
  init:
  ingress:
    enabled:
    apiVersion:
    tls:
      enabled:
      secretName:
    annotations:
    configureCertmanager:
    proxyReadTimeout:
    proxyBodySize:
    proxyBuffering:
  tolerations:
  persistence:  # Upstream
    volumeName:
    matchLabels:
    matchExpressions:
    annotations:
  serviceType:  # Upstream
  servicePort:  # Upstream
  defaultBuckets:
  minioConfig:  # Upstream
```

### Options de ligne de commande d'installation {#installation-command-line-options}

Le tableau ci-dessous contient toutes les configurations possibles des charts qui peuvent être fournies à la commande `helm install` à l'aide des drapeaux `--set` :

| Paramètre                                                | Défaut                        | Description |
|----------------------------------------------------------|--------------------------------|-------------|
| `common.labels`                                          | `{}`                           | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                        | Spécifique à initContainer :  Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                         | Spécifique à initContainer :  Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                    | Spécifique à initContainer :  Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur |
| `defaultBuckets`                                         | `[{"name": "registry"}]`       | Buckets par défaut de MinIO |
| `deployment.strategy`                                    | `{ type: 'Recreate' }`         | Permet de configurer la stratégie de mise à jour utilisée par le déploiement |
| `image`                                                  | `minio/minio`                  | Image MinIO |
| `imagePullPolicy`                                        | `Always`                       | Politique de récupération d'image MinIO |
| `imageTag`                                               | `RELEASE.2017-12-28T01-21-00Z` | Tag d'image MinIO |
| `minioConfig.browser`                                    | `on`                           | Indicateur de navigateur MinIO |
| `minioConfig.domain`                                     |                                | Domaine MinIO |
| `minioConfig.region`                                     | `us-east-1`                    | Région MinIO |
| `minioMc.image`                                          | `minio/mc`                     | Image MinIO mc |
| `minioMc.tag`                                            | `latest`                       | Tag d'image MinIO mc |
| `mountPath`                                              | `/export`                      | Chemin de montage du fichier de configuration MinIO |
| `persistence.accessMode`                                 | `ReadWriteOnce`                | Mode d'accès de persistance MinIO |
| `persistence.annotations`                                |                                | Annotations PersistentVolumeClaim de MinIO |
| `persistence.enabled`                                    | `true`                         | Indicateur d'activation de la persistance MinIO |
| `persistence.matchExpressions`                           |                                | Correspondances d'expressions de label MinIO à lier |
| `persistence.matchLabels`                                |                                | Correspondances de valeurs de label MinIO à lier |
| `persistence.size`                                       | `10Gi`                         | Taille du volume de persistance MinIO |
| `persistence.storageClass`                               |                                | storageClassName MinIO pour le provisionnement |
| `persistence.subPath`                                    |                                | Chemin de montage du volume de persistance MinIO |
| `persistence.volumeName`                                 |                                | Nom du volume persistant existant MinIO |
| `priorityClassName`                                      |                                | [Classe de priorité](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) attribuée aux pods. |
| `pullSecrets`                                            |                                | Secrets pour le dépôt d'images |
| `resources.requests.cpu`                                 | `250m`                         | CPU minimum demandé pour MinIO |
| `resources.requests.memory`                              | `256Mi`                        | Mémoire minimum demandée pour MinIO |
| `securityContext.fsGroup`                                | `1000`                         | ID de groupe pour démarrer le pod |
| `securityContext.runAsUser`                              | `1000`                         | ID d'utilisateur pour démarrer le pod |
| `securityContext.fsGroupChangePolicy`                    |                                | Politique de modification de la propriété et des permissions du volume (nécessite Kubernetes 1.23) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`               | Profil Seccomp à utiliser |
| `containerSecurityContext.runAsUser`                     | `1000`                         | Permet de remplacer le contexte de sécurité spécifique sous lequel le conteneur est démarré |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                        | Contrôle si un processus du conteneur Gitaly peut obtenir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`                  | `true`                         | Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                    | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `serviceAccount.automountServiceAccountToken`            | `false`                        | Indique si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods |
| `servicePort`                                            | `9000`                         | Port de service MinIO |
| `serviceType`                                            | `ClusterIP`                    | Type de service MinIO |
| `tolerations`                                            | `[]`                           | Labels de tolérance pour l'affectation des pods |
| `jobAnnotations`                                         | `{}`                           | Annotations pour la spécification du job |

## Exemples de configuration du chart {#chart-configuration-examples}

### `pullSecrets` {#pullsecrets}

`pullSecrets` vous permet de vous authentifier auprès d'un registre privé pour extraire des images pour un pod.

Des informations supplémentaires sur les registres privés et leurs méthodes d'authentification sont disponibles dans [la documentation Kubernetes](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Voici un exemple d'utilisation de `pullSecrets` :

```yaml
image: my.minio.repository
imageTag: latest
imagePullPolicy: Always
pullSecrets:
- name: my-secret-name
- name: my-secondary-secret-name
```

### `serviceAccount` {#serviceaccount}

Cette section contrôle si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods.

| Nom                           |  Type   | Défaut | Description |
|:-------------------------------|:-------:|:--------|:------------|
| `automountServiceAccountToken` | Boolean | `false` | Contrôle si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods. Vous ne devez pas activer cette option, sauf si elle est requise par certains sidecars pour fonctionner correctement (par exemple, Istio). |

### `tolerations` {#tolerations}

`tolerations` vous permet de planifier des pods sur des nœuds worker avec des teintes

Voici un exemple d'utilisation de `tolerations` :

```yaml
tolerations:
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoExecute"
```

## Activer le sous-chart {#enable-the-sub-chart}

La façon dont nous avons choisi d'implémenter les sous-charts compartimentés inclut la possibilité de désactiver les composants que vous ne souhaitez pas inclure dans un déploiement donné. Pour cette raison, le premier paramètre à définir est `enabled:`.

Par défaut, MinIO est activé immédiatement, mais n'est pas recommandé pour une utilisation en production. Lorsque vous êtes prêt à le désactiver, exécutez `--set global.minio.enabled: false`.

## Configurer le `initContainer` {#configure-the-initcontainer}

Bien que rarement modifiés, les comportements de `initContainer` peuvent être modifiés via les éléments suivants :

```yaml
init:
  image:
    repository:
    tag:
    pullPolicy: IfNotPresent
  script:
```

### Image initContainer {#initcontainer-image}

Les paramètres d'image de l'initContainer sont identiques à ceux d'une configuration d'image normale. Par défaut, les valeurs locales au chart sont laissées vides, et les paramètres globaux `global.gitlabBase.image.repository` ainsi que le tag d'image associé au `global.gitlabVersion` actuel seront utilisés pour renseigner l'image de l'initContainer. La configuration globale peut être remplacée par des valeurs locales au chart (par ex. `minio.init.image.tag`).

### Script initContainer {#initcontainer-script}

L'initContainer reçoit les éléments suivants :

- Le secret contenant les éléments d'authentification montés dans `/config`, généralement `accesskey` et `secretkey`.
- La ConfigMap contenant le modèle `config.json`, et `configure` contenant un script à exécuter avec `sh`, monté dans `/config`.
- Un `emptyDir` monté à `/minio` qui sera transmis au conteneur du démon.

L'initContainer est censé remplir `/minio/config.json` avec une configuration complète, en utilisant le script `/config/configure`. Lorsque le conteneur `minio-config` a terminé cette tâche, le répertoire `/minio` sera transmis au conteneur `minio`, et utilisé pour fournir le `config.json` au serveur [MinIO](https://min.io).

## Configuration de l'Ingress {#configuring-the-ingress}

Ces paramètres contrôlent l'Ingress MinIO.

| Nom                   |  Type   | Défaut | Description |
|:-----------------------|:-------:|:--------|:------------|
| `apiVersion`           | String  |         | Valeur à utiliser dans le champ `apiVersion`. |
| `annotations`          | String  |         | Ce champ correspond exactement au standard `annotations` pour [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/). |
| `enabled`              | Boolean | `false` | Paramètre qui contrôle la création d'objets Ingress pour les services qui les prennent en charge. Lorsque `false`, le paramètre `global.ingress.enabled` est utilisé. |
| `configureCertmanager` | Boolean |         | Active/désactive l'annotation Ingress `cert-manager.io/issuer` et `acme.cert-manager.io/http01-edit-in-place`.. Pour plus d'informations, voir les [exigences TLS pour GitLab Pages](../../installation/tls.md). |
| `tls.enabled`          | Boolean | `true`  | Lorsque défini sur `false`, vous désactivez TLS pour MinIO. Cela est principalement utile lorsque vous ne pouvez pas utiliser la terminaison TLS au niveau de l'Ingress, par exemple lorsque vous disposez d'un proxy avec terminaison TLS avant le contrôleur Ingress. |
| `tls.secretName`       | String  |         | Le nom du Secret TLS Kubernetes contenant un certificat et une clé valides pour l'URL MinIO. Si non défini, `global.ingress.tls.secretName` est utilisé à la place. |

## Configuration de l'image {#configuring-the-image}

Les valeurs par défaut de `image`, `imageTag` et `imagePullPolicy` sont [documentées en amont](https://github.com/helm/charts/tree/master/stable/minio#configuration).

## Persistance {#persistence}

Ce chart provisionne un `PersistentVolumeClaim` et monte le volume persistant correspondant à l'emplacement par défaut `/export`. Vous aurez besoin d'un stockage physique disponible dans le cluster Kubernetes pour que cela fonctionne. Si vous préférez utiliser `emptyDir`, désactivez `PersistentVolumeClaim` par : `persistence.enabled: false`.

Les comportements de [`persistence`](https://github.com/helm/charts/tree/master/stable/minio#persistence) sont [documentés en amont](https://github.com/helm/charts/tree/master/stable/minio#configuration).

GitLab a ajouté quelques éléments :

```yaml
persistence:
  volumeName:
  matchLabels:
  matchExpressions:
```

| Nom               |  Type  | Défaut | Description |
|:-------------------|:------:|:--------|:------------|
| `volumeName`       | String | `false` | Lorsque `volumeName` est fourni, le `PersistentVolumeClaim` utilisera le `PersistentVolume` fourni par nom, au lieu de créer un `PersistentVolume` dynamiquement. Cela remplace le comportement en amont. |
| `matchLabels`      |  Map   | `true`  | Accepte une Map de noms de labels et de valeurs de labels à faire correspondre lors du choix d'un volume à lier. Ceci est utilisé dans la section `PersistentVolumeClaim` `selector`. Consultez la [documentation sur les volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector). |
| `matchExpressions` | Tableau  |         | Accepte un tableau d'objets de conditions de label à faire correspondre lors du choix d'un volume à lier. Ceci est utilisé dans la section `PersistentVolumeClaim` `selector`. Consultez la [documentation sur les volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/#selector). |

## `defaultBuckets` {#defaultbuckets}

`defaultBuckets` fournit un mécanisme pour créer automatiquement des buckets sur le pod MinIO lors de *l'installation*. Cette propriété contient un tableau d'éléments, chacun avec jusqu'à trois propriétés : `name`, `policy` et `purge`.

```yaml
defaultBuckets:
  - name: public
    policy: public
    purge: true
  - name: private
  - name: public-read
    policy: download
```

| Nom     |  Type   | Défaut | Description |
|:---------|:-------:|:--------|:------------|
| `name`   | String  |         | Le nom du bucket créé. La valeur fournie doit être conforme aux [règles de nommage des buckets AWS](https://docs.aws.amazon.com/AmazonS3/latest/dev/BucketRestrictions.html), ce qui signifie qu'elle doit être compatible avec le DNS et contenir uniquement les caractères a-z, 0-9 et - (tiret) dans des chaînes de 3 à 63 caractères. La propriété `name` est obligatoire pour toutes les entrées. |
| `policy` |         | `none`  | La valeur de `policy` contrôle la politique d'accès du bucket sur MinIO. La propriété `policy` n'est pas obligatoire, et la valeur par défaut est `none`. En ce qui concerne l'accès **anonymous**, les valeurs possibles sont : `none` (pas d'accès anonyme), `download` (accès anonyme en lecture seule), `upload` (accès anonyme en écriture seule) ou `public` (accès anonyme en lecture/écriture). |
| `purge`  | Boolean |         | La propriété `purge` est fournie comme moyen de supprimer de force tout bucket existant, au moment de l'installation. Cela n'intervient que lors de l'utilisation d'un `PersistentVolume` préexistant pour la propriété volumeName de [persistence](#persistence). Si vous utilisez un `PersistentVolume` créé dynamiquement, cela n'aura aucun effet utile car cela ne se produit qu'à l'installation du chart et il n'y aura aucune donnée dans le `PersistentVolume` qui vient d'être créé. Cette propriété n'est pas obligatoire, mais vous pouvez spécifier cette propriété avec une valeur de `true` afin de forcer la suppression d'un bucket avec `mc rm -r --force`. |

## Contexte de sécurité {#security-context}

Ces options permettent de contrôler quel `user` et/ou quel `group` est utilisé pour démarrer le pod.

Pour des informations détaillées sur le contexte de sécurité, veuillez consulter la [documentation officielle Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/).

## Type de service et port {#service-type-and-port}

Ces éléments sont [documentés en amont](https://github.com/helm/charts/tree/master/stable/minio#configuration), et le résumé principal est :

```yaml
## Expose the MinIO service to be accessed from outside the cluster (LoadBalancer service).
## or access it from within the cluster (ClusterIP service). Set the service type and the port to serve it.
## ref: http://kubernetes.io/docs/user-guide/services/
##
serviceType: LoadBalancer
servicePort: 9000
```

Le chart ne s'attend pas à être de type `type: NodePort`, donc **do not** le définissez pas ainsi.

## Éléments en amont {#upstream-items}

La [documentation en amont](https://github.com/helm/charts/tree/master/stable/minio) pour ce qui suit s'applique également complètement à ce chart :

- `resources`
- `nodeSelector`
- `minioConfig`

Des explications supplémentaires sur les paramètres `minioConfig` se trouvent dans la [documentation MinIO notify](https://min.io/docs/minio/kubernetes/upstream/index.html). Cela inclut des détails sur la publication de notifications lorsque des objets de bucket sont consultés ou modifiés.
