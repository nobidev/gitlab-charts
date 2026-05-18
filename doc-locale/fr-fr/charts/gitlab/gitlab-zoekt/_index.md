---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Graphique Zoekt
---

{{< details >}}

- Niveau :  Premium, Ultimate
- Offre :  GitLab.com, GitLab Self-Managed
- Statut :  Disponibilité limitée

{{< /details >}}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/105049) en tant que [bêta](https://docs.gitlab.com/policy/development_stages_support/#beta) dans GitLab 15.9 [avec des flags](https://docs.gitlab.com/administration/feature_flags/) nommés `index_code_with_zoekt` et `search_code_with_zoekt`. Désactivé par défaut.
- [Activé sur GitLab.com et GitLab Self-Managed](https://gitlab.com/gitlab-org/gitlab/-/issues/388519) dans GitLab 16.6.
- La recherche de code globale a été [introduite](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/147077) dans GitLab 16.11 [avec un flag](https://docs.gitlab.com/administration/feature_flags/) nommé `zoekt_cross_namespace_search`. Désactivé par défaut.
- Les feature flags `index_code_with_zoekt` et `search_code_with_zoekt` ont été [supprimés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/148378) dans GitLab 17.1.
- Le feature flag `zoekt_rollout_worker` a été [ajouté](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/175666) dans GitLab 17.9. Désactivé par défaut.
- [Passage](https://gitlab.com/groups/gitlab-org/-/epics/17918) de la version bêta à la disponibilité limitée dans GitLab 18.6.
- Les feature flags [`zoekt_cross_namespace_search`](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/213413) et [`zoekt_rollout_worker`](https://gitlab.com/gitlab-org/gitlab/-/issues/519660) ont été supprimés dans GitLab 18.7.

{{< /history >}}

> [!warning]
> Cette fonctionnalité est en [disponibilité limitée](https://docs.gitlab.com/policy/development_stages_support/#limited-availability). Pour plus d'informations, consultez l'epic [9404](https://gitlab.com/groups/gitlab-org/-/epics/9404). Donnez votre avis dans le ticket [420920](https://gitlab.com/gitlab-org/gitlab/-/issues/420920).

## Graphique Zoekt avec une instance de package Linux {#zoekt-chart-with-a-linux-package-instance}

Utilisez le graphique Zoekt pour connecter Zoekt à une instance de package Linux.

Prérequis :

- Un cluster Zoekt dédié basé sur les [recommandations de dimensionnement](https://docs.gitlab.com/integration/exact_code_search/zoekt/#sizing-recommendations) actuelles.

Pour utiliser le graphique Zoekt avec une instance de package Linux :

1. Créez un espace de nommage appelé `zoekt` :

   ```shell
   kubectl create namespace zoekt
   ```

1. Clonez le [graphique `gitlab-zoekt`](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/) localement et accédez à son répertoire :

   ```shell
   git clone https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt.git
   cd gitlab-zoekt
   ```

1. [Activez un équilibreur de charge](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt/-/blob/v2.7.0/doc/load_balancer.md). Étant donné que le graphique Zoekt est un service headless, un équilibreur de charge est requis.

1. Dans `values.yaml` :

   1. Utilisez le secret `gitlab_shell` du fichier `/etc/gitlab/gitlab-secrets.json` pour créer le secret `kubectl` :

      ```shell
      kubectl create secret generic gitlab-zoekt-secret --from-literal=secret-key="<gitlab-shell-secret>" -n zoekt
      ```

   1. Ajoutez le secret :

      ```yaml
      internalApi:
       secretName: 'gitlab-zoekt-secret'
       secretKey: 'secret-key'
      ```

   1. Ajoutez l'URL de l'instance GitLab et l'URL du service avec un port IP d'équilibreur de charge `:8080` :

      ```yaml
       internalApi:
         gitlabUrl: 'https://<gitlab_url>' # Internal URL to connect to GitLab
         serviceUrl: 'http://<loadbalancer_internal_ip>:8080' # URL to reach Zoekt service - LB internal URL
      ```

1. Dans GitLab, [modifiez l'interface d'écoute de Gitaly](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#change-the-gitaly-listening-interface) :

   ```ruby
   gitaly['configuration'] = {
     listen_addr: '0.0.0.0:8075',
     storage: [
       {
         name: 'default',
         path: '/var/opt/gitlab/git-data/repositories',
       },
     ]
   }
   gitlab_rails['repositories_storages'] = {
     'default'  => { 'gitaly_address' => 'tcp://<gitlab_url>:8075' },
   }
   ```

1. Installez Zoekt en utilisant `helm` :

   ```shell
   helm install gitlab-zoekt . -f values.yaml --version <latest_version> --namespace zoekt
   ```

1. Confirmez que les pods ont été créés. Vous devez avoir à la fois les pods de la passerelle et `gitlab-zoekt-0` :

   ```shell
   kubectl get pods
   NAME                                  READY   STATUS    RESTARTS   AGE
   gitlab-zoekt-0                        3/3     Running   0          13d
   gitlab-zoekt-gateway-b78dbc78-hzw28   1/1     Running   0          13d
   ```

   Installez ou mettez à niveau le graphique Helm GitLab si vous apportez d'autres modifications à `values.yaml`.

1. [Activez la recherche de code exacte](https://docs.gitlab.com/integration/zoekt/#enable-exact-code-search).
1. Pour indexer un groupe principal, effectuez l'une des opérations suivantes :
   - [Indexez automatiquement tous les espaces de nommage racine](https://docs.gitlab.com/integration/zoekt/#index-root-namespaces-automatically).
   - Indexez manuellement un groupe principal spécifique :

     ```ruby
     node = ::Search::Zoekt::Node.online.last
     namespace = Namespace.find_by_full_path('<top-level-group-to-index>')
     Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
     ```

## Graphique Zoekt avec le graphique Helm GitLab {#zoekt-chart-with-the-gitlab-helm-chart}

Le graphique Zoekt prend en charge la [recherche de code exacte](https://docs.gitlab.com/user/search/exact_code_search/). Vous pouvez installer le graphique en définissant `gitlab-zoekt.install` sur `true`. Pour plus d'informations, voir [`gitlab-zoekt`](https://gitlab.com/gitlab-org/cloud-native/charts/gitlab-zoekt).

### Activer le graphique Zoekt {#enable-the-zoekt-chart}

Pour activer le graphique Zoekt, définissez les valeurs suivantes :

```shell
--set gitlab-zoekt.install=true \
--set gitlab-zoekt.replicas=2 \         # Number of Zoekt pods. If you want to use only one pod, you can skip this setting.
--set gitlab-zoekt.indexStorage=128Gi   # Disk size for the Zoekt node. Zoekt requires up to three times the repository's default branch's storage size, depending on the number of large and binary files.
```

### Définir l'utilisation du CPU et de la mémoire {#set-cpu-and-memory-usage}

Vous pouvez définir des demandes et des limites pour le graphique Zoekt en modifiant les [paramètres par défaut](https://gitlab.com/gitlab-com/gl-infra/k8s-workloads/gitlab-com/-/blob/master/releases/gitlab/values/gprd.yaml.gotmpl#L6-45) de GitLab.com.

## Configurer Zoekt dans GitLab {#configure-zoekt-in-gitlab}

{{< history >}}

- Les shards ont été [renommés](https://gitlab.com/gitlab-org/gitlab/-/merge_requests/134717) en nœuds dans GitLab 16.6.

{{< /history >}}

Pour configurer Zoekt pour un groupe principal dans GitLab :

1. Connectez-vous à la console Rails du pod toolbox :

   ```shell
   kubectl exec <toolbox pod name> -it -c toolbox -- gitlab-rails console -e production
   ```

1. [Activez la recherche de code exacte](https://docs.gitlab.com/integration/zoekt/#enable-exact-code-search).
1. Pour indexer un groupe principal, effectuez l'une des opérations suivantes :
   - [Indexez automatiquement tous les espaces de nommage racine](https://docs.gitlab.com/integration/zoekt/#index-root-namespaces-automatically).
   - Indexez manuellement un groupe principal spécifique :

     {{< tabs >}}

     {{< tab title="GitLab 17.7 et versions ultérieures" >}}

     ```shell
     node = ::Search::Zoekt::Node.online.last
     namespace = Namespace.find_by_full_path('<top-level-group-to-index>')
     Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
     ```

     {{< /tab >}}

     {{< tab title="GitLab 17.6 et versions antérieures" >}}

     ```shell
     node = ::Search::Zoekt::Node.online.last
     namespace = Namespace.find_by_full_path('<top-level-group-to-index>')
     enabled_namespace = Search::Zoekt::EnabledNamespace.find_or_create_by(namespace: namespace)
     replica = enabled_namespace.replicas.find_or_create_by(namespace_id: enabled_namespace.root_namespace_id)
     replica.ready!
     node.indices.create!(zoekt_enabled_namespace_id: enabled_namespace.id, namespace_id: namespace.id, zoekt_replica_id: replica.id, state: :ready)
     ```

     {{< /tab >}}

     {{< /tabs >}}

Zoekt peut désormais indexer les projets de ce groupe après la mise à jour ou la création d'un projet. Pour l'indexation initiale, attendez au moins quelques minutes que Zoekt commence à indexer l'espace de nommage.
