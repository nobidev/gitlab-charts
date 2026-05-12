---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Rôles IAM pour AWS lors de l'utilisation du chart GitLab"
---

La configuration par défaut pour le stockage d'objets externe dans les charts utilise des clés d'accès et des clés secrètes. Il est également possible d'utiliser des rôles IAM en combinaison avec [`kube2iam`](https://github.com/jtblin/kube2iam), [`kiam`](https://github.com/uswitch/kiam), ou [IRSA](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/).

## Rôle IAM {#iam-role}

Le rôle IAM aura besoin des permissions de lecture, d'écriture et de liste sur les compartiments S3. Vous pouvez choisir d'avoir un rôle par compartiment ou de les combiner.

## Configuration du chart {#chart-configuration}

Les rôles IAM peuvent être spécifiés en ajoutant des annotations et en modifiant les secrets, comme indiqué ci-dessous :

### Registry {#registry}

Un rôle IAM peut être spécifié via la clé d'annotations :

```plaintext
--set registry.annotations."iam\.amazonaws\.com/role"=<role name>
```

Lors de la création du secret [`registry-storage.yaml`](../../charts/registry/_index.md#storage), omettez la clé d'accès et la clé secrète :

```yaml
s3:
  bucket: gitlab-registry
  v4auth: true
  region: us-east-1
```

*Remarque* : Si vous fournissez la paire de clés, le rôle IAM sera ignoré. Consultez la [documentation AWS](https://docs.aws.amazon.com/sdk-for-java/v1/developer-guide/credentials.html#credentials-default) pour plus de détails.

### LFS, Artefacts, Téléversements, Packages {#lfs-artifacts-uploads-packages}

Pour LFS, les artefacts, les téléversements et les packages, un rôle IAM peut être spécifié via la clé d'annotations dans la configuration `webservice` et `sidekiq` :

```shell
--set gitlab.sidekiq.annotations."iam\.amazonaws\.com/role"=<role name>
--set gitlab.webservice.annotations."iam\.amazonaws\.com/role"=<role name>
```

Pour le secret [`object-storage.yaml`](../../charts/globals.md#connection), omettez la clé d'accès et la clé secrète. Comme la base de code GitLab Rails utilise Fog pour le stockage S3, la clé [`use_iam_profile`](https://docs.gitlab.com/administration/cicd/secure_files/#s3-compatible-connection-settings) doit être ajoutée pour que Fog utilise le rôle :

```yaml
provider: AWS
use_iam_profile: true
region: us-east-1
```

> [!note] N'incluez PAS `endpoint` dans cette configuration. IRSA utilise des [jetons STS, qui utilisent des points de terminaison spécialisés](https://docs.aws.amazon.com/STS/latest/APIReference/welcome.html). Lorsque `endpoint` est fourni, le client AWS tentera [d'envoyer un message `AssumeRoleWithWebIdentity` à ce point de terminaison et échouera](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3148#note_889357676).

### Sauvegardes {#backups}

La configuration de Toolbox permet de définir des annotations pour téléverser des sauvegardes vers S3 :

```shell
--set gitlab.toolbox.annotations."iam\.amazonaws\.com/role"=<role name>
```

Le secret [`s3cmd.config`](_index.md#backups-storage-example) doit être créé sans les clés d'accès et secrètes :

```ini
[default]
bucket_location = us-east-1
```

### Utilisation des rôles IAM pour les comptes de service {#using-iam-roles-for-service-accounts}

Si GitLab s'exécute dans un cluster AWS EKS (version 1.14 ou supérieure), vous pouvez utiliser un rôle AWS IAM pour vous authentifier auprès du stockage d'objets S3 sans avoir besoin de générer ou de stocker des jetons d'accès. Plus d'informations sur l'utilisation des rôles IAM dans un cluster EKS peuvent être trouvées dans la documentation [Introducing fine-grained IAM roles for service accounts](https://aws.amazon.com/blogs/opensource/introducing-fine-grained-iam-roles-service-accounts/) d'AWS.

Les annotations IRSA appropriées pour les rôles peuvent être appliquées aux ServiceAccounts dans ce chart Helm de l'une des deux façons suivantes :

1. Les ServiceAccounts qui ont été pré-créés comme décrit dans la documentation AWS ci-dessus. Cela garantit les annotations appropriées sur le ServiceAccount et le fournisseur OIDC lié.
1. ServiceAccounts générés par le chart avec des annotations définies. Nous permettons la configuration d'annotations sur les ServiceAccounts à la fois globalement et par chart.

Pour utiliser les rôles IAM pour les ServiceAccounts dans les clusters EKS, l'annotation spécifique doit être `eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/<IAM_ROLE_NAME>`.

Pour activer les rôles IAM pour les ServiceAccounts pour GitLab s'exécutant dans un cluster AWS EKS, suivez les instructions sur [IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).

#### Utilisation de comptes de service pré-créés {#using-pre-created-service-accounts}

Définissez les options suivantes lors du déploiement du chart GitLab. Il est important de noter que le ServiceAccount est activé mais non créé.

```yaml
global:
  serviceAccount:
    enabled: true
    create: false
    name: <SERVICE ACCT NAME>
```

Un contrôle granulaire des ServiceAccounts est également disponible :

```yaml
registry:
  serviceAccount:
    create: false
    name: gitlab-registry
gitlab:
  migrations:
    serviceAccount:
      create: false
      name: gitlab-migrations
  webservice:
    serviceAccount:
      create: false
      name: gitlab-webservice
  sidekiq:
    serviceAccount:
      create: false
      name: gitlab-sidekiq
  toolbox:
    serviceAccount:
      create: false
      name: gitlab-toolbox
```

Assurez-vous que la politique de confiance du rôle IAM est configurée pour [faire confiance à ces comptes de service Kubernetes](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html).

#### Utilisation de comptes de service appartenant au chart {#using-chart-owned-service-accounts}

L'annotation `eks.amazonaws.com/role-arn` peut être appliquée à tous les ServiceAccounts créés par les charts appartenant à GitLab en configurant `global.serviceAccount.annotations`.

```yaml
global:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/name
```

Des annotations peuvent également être ajoutées par ServiceAccount en ajoutant la définition correspondante pour chaque chart. Il peut s'agir du même rôle ou de rôles individuels.

```yaml
registry:
  serviceAccount:
    annotations:
      eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab-registry
gitlab:
  migrations:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab
  webservice:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab
  sidekiq:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab
  toolbox:
    serviceAccount:
      annotations:
        eks.amazonaws.com/role-arn: arn:aws:iam::xxxxxxxxxxxx:role/gitlab-toolbox
```

## Dépannage {#troubleshooting}

Vous pouvez tester si le rôle IAM est correctement configuré et que GitLab accède à S3 en utilisant le rôle IAM en vous connectant au pod `toolbox` et en utilisant `awscli` (remplacez `<namespace>` par le espace de nommage où GitLab est installé) :

```shell
kubectl exec -ti $(kubectl get pod -n <namespace> -lapp=toolbox -o jsonpath='{.items[0].metadata.name}') -n <namespace> -- bash
```

Avec le package `awscli` installé, vérifiez que vous êtes en mesure de communiquer avec l'API AWS :

```shell
aws sts get-caller-identity
```

Une réponse normale affichant l'identifiant utilisateur temporaire, le numéro de compte et l'ARN IAM (ce ne sera pas l'ARN IAM du rôle utilisé pour accéder à S3) sera renvoyée si la connexion à l'API AWS a réussi. Une connexion échouée nécessitera un dépannage supplémentaire pour déterminer pourquoi le pod `toolbox` n'est pas en mesure de communiquer avec les API AWS.

Si la connexion aux API AWS est réussie, la commande suivante assumera le rôle IAM qui a été créé et vérifiera qu'un jeton STS peut être récupéré pour accéder à S3. Les variables `AWS_ROLE_ARN` et `AWS_WEB_IDENTITY_TOKEN_FILE` sont définies dans l'environnement lorsque l'annotation du rôle IAM a été ajoutée au pod et ne nécessitent pas d'être définies :

```shell
aws sts assume-role-with-web-identity --role-arn $AWS_ROLE_ARN  --role-session-name gitlab --web-identity-token file://$AWS_WEB_IDENTITY_TOKEN_FILE
```

Si le rôle IAM n'a pas pu être assumé, un message d'erreur similaire au suivant sera affiché :

```plaintext
An error occurred (AccessDenied) when calling the AssumeRoleWithWebIdentity operation: Not authorized to perform sts:AssumeRoleWithWebIdentity
```

Sinon, les informations d'identification STS et les informations sur le rôle IAM seront affichées.

## `WebIdentityErr: failed to retrieve credentials` {#webidentityerr-failed-to-retrieve-credentials}

Si vous voyez cette erreur dans les journaux, cela indique que `endpoint` a été configuré dans votre secret [`object-storage.yaml`](../../charts/globals.md#connection). Supprimez ce paramètre et redémarrez les pods `webservice` et `sidekiq`.
