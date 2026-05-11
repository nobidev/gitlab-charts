---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migration de Helm v2 vers Helm v3
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

[Helm v2 a été officiellement déprécié](https://helm.sh/blog/helm-v2-deprecation-timeline/) en novembre 2020. À partir de la version 5.0 du chart Helm de GitLab (version 14.0 de l'application GitLab), l'installation et les mises à niveau avec Helm v2.x ne sont plus prises en charge. Pour bénéficier des futures mises à jour de GitLab, vous devrez migrer vers Helm v3.

## Changements entre Helm v2 et Helm v3 {#changes-between-helm-v2-and-helm-v3}

Helm v3 introduit de nombreux changements qui ne sont pas rétrocompatibles avec Helm v2. Parmi les changements majeurs figurent la suppression des prérequis Tiller et la façon dont les informations de release sont stockées sur le cluster. Pour en savoir plus, consultez la [présentation des changements de Helm v3](https://helm.sh/docs/topics/v2_v3_migration/#overview-of-helm-3-changes) et la [FAQ sur les changements depuis Helm v2](https://helm.sh/docs/faq/changes_since_helm2/).

Le chart Helm que vous utilisez pour déployer l'application peut ne pas être compatible avec les versions plus récentes ou plus anciennes de Helm. Si vous avez plusieurs applications déployées et gérées avec Helm v2, vous devrez vérifier si elles sont compatibles avec Helm v3 au cas où vous souhaiteriez également les convertir. Le chart Helm de GitLab prend en charge Helm v3.0.2 ou supérieur à partir de la version v3.0.0 du chart Helm de GitLab. Helm v2 n'est plus pris en charge.

Du point de vue de l'application en cours d'exécution, rien ne change lorsque vous effectuez la migration de Helm v2 vers v3. Il est généralement assez sûr d'effectuer la migration de Helm v2 vers v3 ; cependant, assurez-vous de faire des sauvegardes de Helm v2 par précaution.

## Comment migrer de Helm v2 vers Helm v3 {#how-to-migrate-from-helm-v2-to-helm-v3}

Vous pouvez utiliser le [plugin Helm 2to3](https://github.com/helm/helm-2to3) pour migrer les releases GitLab de Helm v2 vers Helm v3. Pour une explication plus détaillée avec quelques exemples sur ce plugin de migration, référez-vous à l'article de blog Helm :  [Comment migrer de Helm v2 vers Helm v3](https://helm.sh/blog/migrate-from-helm-v2-to-helm-v3/).

Si plusieurs personnes gèrent votre installation Helm de GitLab, vous devrez peut-être exécuter `helm3 2to3 move config` sur chaque machine locale. Vous n'aurez besoin d'exécuter `helm3 2to3 convert` qu'une seule fois.

## Problèmes connus {#known-issues}

### L'erreur « UPGRADE FAILED: cannot patch » s'affiche après la migration {#upgrade-failed-cannot-patch-error-is-shown-after-the-migration}

Après la migration, les **subsequent upgrades may fail** avec une erreur similaire à la suivante :

```shell
Error: UPGRADE FAILED: cannot patch "..." with kind Deployment: Deployment.apps "..." is invalid: spec.selector:
Invalid value: v1.LabelSelector{...}: field is immutable
```

ou

```shell
Error: UPGRADE FAILED: cannot patch "..." with kind StatefulSet: StatefulSet.apps "..." is invalid:
spec: Forbidden: updates to statefulset spec for fields other than 'replicas', 'template', and 'updateStrategy' are forbidden
```

Cela est dû à des problèmes connus avec la migration de Helm 2 vers 3 dans les dépendances [Cert Manager](https://github.com/jetstack/cert-manager/issues/2451) et [Redis](https://github.com/bitnami/charts/issues/3482). En résumé, le label `heritage` sur certains Deployments et StatefulSets est immuable et ne peut pas être modifié de `Tiller` (défini par Helm 2) à `Helm` (défini par Helm 3). Ils doivent donc être remplacés de force.

Pour contourner ce problème, suivez les instructions ci-dessous :

> [!note] 
> Ces instructions remplacent les ressources de force, notamment le StatefulSet Redis. Vous devez vous assurer que le volume de données attaché à ce StatefulSet est sûr et reste intact.

1. Remplacez les Deployments cert-manager (si activés).

```shell
kubectl get deployments -l app=cert-manager -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true -f -
kubectl get deployments -l app=cainjector -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true -f -
```

1. (Facultatif) Définissez `persistentVolumeReclaimPolicy` sur `Retain` sur le PV revendiqué par le StatefulSet Redis. Cela permet de s'assurer que le PV ne sera pas supprimé par inadvertance.

```shell
kubectl patch pv <PV-NAME> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

1. Définissez le label `heritage` du PVC Redis existant sur `Helm`.

```shell
kubectl label pvc -l app=redis --overwrite heritage=Helm
```

1. Remplacez le StatefulSet Redis **without cascading**.

```shell
kubectl get statefulsets.apps -l app=redis -o yaml | sed "s/Tiller/Helm/g" | kubectl replace --force=true --cascade=false -f -
```

### Problèmes RBAC après la migration lors de l'exécution de Helm upgrade {#rbac-issues-after-the-migration-when-running-helm-upgrade}

Vous pouvez rencontrer l'erreur suivante lors de l'exécution de Helm upgrade une fois la conversion terminée :

```shell
Error: UPGRADE FAILED: pre-upgrade hooks failed: warning: Hook pre-upgrade gitlab/templates/shared-secrets/rbac-config.yaml failed: roles.rbac.authorization.k8s.io "gitlab-shared-secrets" is forbidden: user "your-user-name@domain.tld" (groups=["system:authenticated"]) is attempting to grant RBAC permissions not currently held:
{APIGroups:[""], Resources:["secrets"], Verbs:["get" "list" "create" "patch"]}
```

Helm2 utilisait le compte de service Tiller pour effectuer ces opérations. Helm3 n'utilise plus Tiller, et votre compte utilisateur doit disposer des permissions RBAC appropriées pour exécuter la commande, même si vous exécutez `helm upgrade` en tant qu'administrateur du cluster. Pour vous accorder les permissions RBAC complètes, exécutez :

```shell
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=your-user-name@domain.tld
```

Après cela, `helm upgrade` devrait fonctionner correctement.
