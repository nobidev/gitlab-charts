---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer le chart GitLab avec un Gitaly externe
---

Ce document vise à fournir une documentation sur la façon de configurer ce chart Helm avec un service Gitaly externe.

Si vous n'avez pas Gitaly configuré, pour un déploiement sur site ou sur une VM, envisagez d'utiliser notre [package Linux](external-omnibus-gitaly.md).

> [!note]
> Les _services_ Gitaly externes peuvent être fournis par des nœuds Gitaly ou des clusters [Praefect](https://docs.gitlab.com/administration/gitaly/praefect/).

## Configurer le chart {#configure-the-chart}

Désactivez le chart `gitaly` et le service Gitaly qu'il fournit, et pointez les autres services vers le service externe.

Vous devez définir les propriétés suivantes :

- `global.gitaly.enabled` : Définissez sur `false` pour désactiver le chart Gitaly inclus.
- `global.gitaly.external` : Il s'agit d'un tableau de [service(s) Gitaly externe(s)](../../charts/globals.md#external).
- `global.gitaly.authToken.secret` : Le nom du [secret qui contient le token d'authentification](../../installation/secrets.md#gitaly-secret).
- `global.gitaly.authToken.key` : La clé dans le secret, qui contient le contenu du token.

Les services Gitaly externes utiliseront leurs propres instances de GitLab Shell. Selon votre implémentation, vous pouvez les configurer avec les secrets de ce chart, ou vous pouvez configurer les secrets de ce chart avec le contenu d'une source prédéfinie.

Vous **pouvez** avoir besoin de définir les propriétés suivantes :

- `global.shell.authToken.secret` : Le nom du [secret qui contient le secret pour GitLab Shell](../../installation/secrets.md#gitlab-shell-secret).
- `global.shell.authToken.key` : La clé dans le secret, qui contient le contenu du secret.

Un exemple de configuration complet, avec deux services Gitaly externes (`external-gitaly.yml`) :

```yaml
global:
  gitaly:
    enabled: false
    external:
      - name: default                   # required, at least one service must be called 'default'.
        hostname: node1.git.example.com # required
        port: 8075                      # optional, default shown
      - name: default2                  # required
        hostname: node2.git.example.com # required
        port: 8075                      # optional, default shown
        tlsEnabled: false               # optional, overrides gitaly.tls.enabled
    authToken:
      secret: external-gitaly-token     # required
      key: token                        # optional, default shown
    tls:
      enabled: false                    # optional, default shown
```

Vous pouvez également utiliser le champ `address` pour spécifier un URI complet pour les services Gitaly, y compris les adresses DNS :

```yaml
global:
  gitaly:
    enabled: false
    external:
      - name: default                                    # required
        address: dns://8.8.8.8:53/gitaly.consul.internal # required (alternative to hostname/port)
    authToken:
      secret: *********************                      # required
      key: token                                         # optional, default shown
```

### Format d'adresse DNS {#dns-address-format}

{{< history >}}

- La prise en charge des adresses DNS a été [introduite](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/4716) dans GitLab 18.8.

{{< /history >}}

Lors de l'utilisation du champ `address` avec des URI basées sur DNS, le format suit la [spécification du résolveur DNS gRPC](https://gitlab.com/gitlab-org/gitaly/-/blob/master/doc/grpc_load_balancing.md) :

```plaintext
dns:[//authority/]host[:port]
dns+tls:[//authority/]host[:port]
```

Utilisez `dns+tls` pour activer TLS pour la connexion. Ce schéma combine la découverte de services basée sur DNS avec le chiffrement TLS.

`authority` est sous la forme de `IP address[:port]`. La spécification d'un nom d'hôte dans `authority` ne fonctionne pas. Le port 53 est utilisé par défaut.

Par exemple :

- `dns:///gitaly.example.com` : Notez les trois barres obliques `///` lorsque l'autorité par défaut est utilisée.
- `dns://8.8.8.8:53/gitaly.consul.internal` : Résolveur DNS personnalisé avec port.
- `dns://10.0.1.50:8600/praefect.service.consul.:2305` : Résolveur DNS personnalisé avec service Praefect et port. Notez le point final `.` pour éviter d'ajouter le suffixe DNS Kubernetes.
- `dns+tls:///gitaly.example.com` : DNS avec TLS activé en utilisant l'autorité par défaut.
- `dns+tls://10.0.1.50:8600/praefect.service.consul.:2305` : Serveur DNS avec TLS activé.

Le point final `.` est important lorsque le service ne s'exécute pas dans le cluster Kubernetes. Le client gRPC en a besoin pour éviter d'ajouter le suffixe DNS par défaut pour Kubernetes (généralement `.svc.cluster.local`). Un pod a généralement `options ndots:5` défini dans `/etc/resolv.conf`, ce qui [entraîne l'expansion de la requête DNS](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/) pour les noms de service comportant moins de 5 points.

Dans l'exemple `dns://10.0.1.50:8600/praefect.service.consul:2305`, `8600` est le port du serveur DNS et `2305` est le port du service Praefect.

Pour plus d'informations sur la découverte de services avec Praefect, consultez la [documentation sur la découverte de services Praefect](https://docs.gitlab.com/administration/gitaly/praefect/configure/#service-discovery).

Un exemple complet de configuration d'un service Praefect externe.

> [!note]
> Le nom du service Praefect [doit être `default`](../../charts/globals.md#external).

```yaml
global:
  gitaly:
    enabled: false
    external:
      - name: default                   # required
        hostname: ha.git.example.com    # required
        port: 2305                      # Praefect uses port 2305
        tlsEnabled: false               # optional, overrides gitaly.tls.enabled
    authToken:
      secret: external-gitaly-token     # required
      key: token                        # optional, default shown
    tls:
      enabled: false                    # optional, default shown
```

Exemple d'installation utilisant le fichier de configuration ci-dessus conjointement avec d'autres configurations via `gitlab.yml` :

```shell
helm upgrade --install gitlab gitlab/gitlab  \
  -f gitlab.yml \
  -f external-gitaly.yml
```

## Gitaly externe multiple {#multiple-external-gitaly}

Si votre implémentation utilise plusieurs nœuds Gitaly externes à ces charts, vous pouvez également définir plusieurs hôtes. La syntaxe est légèrement différente, afin de permettre la complexité requise.

Un [exemple de fichier de valeurs](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/examples/gitaly/values-multiple-external.yaml) est fourni, qui présente l'ensemble de configuration approprié. Le contenu de ce fichier de valeurs n'est pas interprété correctement via les arguments `--set`, il doit donc être transmis à Helm avec l'indicateur `-f / --values`.

### Connexion à Gitaly externe via TLS {#connecting-to-external-gitaly-over-tls}

Si votre [serveur Gitaly externe écoute sur le port TLS](https://docs.gitlab.com/administration/gitaly/#enable-tls-support), vous pouvez faire en sorte que votre instance GitLab communique avec lui via TLS. Pour ce faire, vous devez

1. Créer un secret Kubernetes contenant le certificat du serveur Gitaly

   ```shell
   kubectl create secret generic gitlab-gitaly-tls-certificate --from-file=gitaly-tls.crt=<path to certificate>
   ```

1. Ajouter le certificat du serveur Gitaly externe à la liste des [autorités de certification personnalisées](../../charts/globals.md#custom-certificate-authorities). Dans le fichier de valeurs, spécifiez les éléments suivants

   ```yaml
   global:
     certificates:
       customCAs:
         - secret: gitlab-gitaly-tls-certificate
   ```

   ou le transmettre à la commande `helm upgrade` en utilisant `--set`

   ```shell
   --set global.certificates.customCAs[0].secret=gitlab-gitaly-tls-certificate
   ```

1. Pour activer TLS pour toutes les instances Gitaly, définissez `global.gitaly.tls.enabled: true`.

   ```yaml
   global:
     gitaly:
       tls:
         enabled: true
   ```

   Pour activer TLS pour des instances individuelles, définissez `tlsEnabled: true` pour cette entrée.

   ```yaml
   global:
     gitaly:
       external:
         - name: default
           hostname: node1.git.example.com
           tlsEnabled: true
   ```

> [!note]
> Vous pouvez choisir n'importe quel nom de secret et clé valides pour cela, mais assurez-vous que la clé est unique parmi tous les secrets spécifiés dans `customCAs` pour éviter les collisions, car toutes les clés dans les secrets seront montées. Vous **n'avez pas besoin** de fournir la clé pour le certificat, car il s'agit du _côté client_.

## Tester que GitLab peut se connecter à Gitaly {#test-that-gitlab-can-connect-to-gitaly}

Pour vérifier que GitLab peut se connecter au serveur Gitaly externe :

```shell
kubectl exec -it <toolbox-pod> -- gitlab-rake gitlab:gitaly:check
```

Si vous utilisez Gitaly avec TLS, vous pouvez également vérifier si le chart GitLab fait confiance au certificat Gitaly :

```shell
kubectl exec -it <toolbox-pod> -- echo | /usr/bin/openssl s_client -connect <gitaly-host>:<gitaly-port>
```

## Migrer du chart Gitaly vers un Gitaly externe {#migrate-from-gitaly-chart-to-external-gitaly}

Si vous utilisez le chart Gitaly pour fournir le service Gitaly et que vous devez migrer tous vos dépôts vers un service Gitaly externe, cela peut être effectué avec l'une des méthodes suivantes :

- [Migrer avec l'API de déplacement de stockage de dépôt (recommandé)](#migrate-with-the-repository-storage-moves-api).
- [Migrer avec la méthode de sauvegarde/restauration](#migrate-with-the-backuprestore-method).

### Migrer avec l'API de déplacement de stockage de dépôt {#migrate-with-the-repository-storage-moves-api}

Cette méthode :

- Utilise l'[API de déplacement de stockage de dépôt](https://docs.gitlab.com/api/project_repository_storage_moves/) pour migrer les dépôts du chart Gitaly vers le service Gitaly externe.
- Peut être effectuée sans interruption de service.
- Nécessite que le service Gitaly externe réside dans le même VPC/zone que les pods Gitaly.
- N'a pas été testé avec le [chart Praefect](../../charts/gitlab/praefect/_index.md) et n'est pas pris en charge.

#### Étape 1 :  Configurer le service Gitaly externe ou le cluster Gitaly (Praefect) {#step-1-set-up-external-gitaly-service-or-gitaly-cluster-praefect}

Configurez un [Gitaly externe](https://docs.gitlab.com/administration/gitaly/configure_gitaly/) ou un [cluster Gitaly externe (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/). Vous devez fournir le token Gitaly et le secret GitLab Shell de votre installation Chart dans le cadre de ces étapes :

```shell
# Get the GitLab Shell secret
kubectl get secret <release>-gitlab-shell-secret -ojsonpath='{.data.secret}' | base64 -d

# Get the Gitaly token
kubectl get secret <release>-gitaly-secret -ojsonpath='{.data.token}' | base64 -d
```

{{< tabs >}}

{{< tab title="Gitaly" >}}

- Le token Gitaly extrait ici doit être utilisé pour la valeur `AUTH_TOKEN`.
- Le secret GitLab Shell extrait ici doit être utilisé pour la valeur `shellsecret`.

{{< /tab >}}

{{< tab title="Gitaly Cluster (Praefect)" >}}

- Le token Gitaly extrait ici doit être utilisé pour `PRAEFECT_EXTERNAL_TOKEN`.
- Le secret GitLab Shell extrait ici doit être utilisé pour `GITLAB_SHELL_SECRET_TOKEN`.

{{< /tab >}}

{{< /tabs >}}

Enfin, assurez-vous que le pare-feu du service Gitaly externe autorise le trafic sur le port Gitaly configuré pour votre plage d'adresses IP de pods Kubernetes.

#### Étape 2 : Configurer l'instance pour utiliser le nouveau service Gitaly {#step-2-configure-instance-to-use-new-gitaly-service}

1. Configurez GitLab pour utiliser le Gitaly externe. Si des références à Gitaly figurent dans votre fichier de configuration principal `gitlab.yml`, supprimez-les et créez un nouveau fichier `mixed-gitaly.yml` avec le contenu suivant.

   Si vous avez précédemment défini des stockages Gitaly supplémentaires, vous devez vous assurer qu'un stockage Gitaly correspondant avec le même nom est spécifié dans la nouvelle configuration, sinon l'opération de restauration échoue.

   Reportez-vous à la section [connexion à Gitaly externe via TLS](#connecting-to-external-gitaly-over-tls) si vous configurez TLS :

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```yaml
   global:
     gitaly:
       internal:
         names:
           - default
       external:
         - name: ext-gitaly                # required
           hostname: node1.git.example.com # required
           port: 8075                      # optional, default shown
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster (Praefect)" >}}

   ```yaml
   global:
     gitaly:
       internal:
         names:
           - default
       external:
         - name: ext-gitaly-cluster        # required
           hostname: ha.git.example.com    # required
           port: 2305                      # Praefect uses port 2305
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. Appliquez la nouvelle configuration en utilisant les fichiers `gitlab.yml` et `mixed-gitaly.yml` :

   ```shell
   helm upgrade --install gitlab gitlab/gitlab \
     -f gitlab.yml \
     -f mixed-gitaly.yml
   ```

1. Sur le pod Toolbox, confirmez que GitLab peut se connecter au Gitaly externe avec succès :

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:gitaly:check
   ```

1. Assurez-vous que le Gitaly externe peut se reconnecter à votre installation Chart :

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   Assurez-vous que le service Gitaly peut effectuer des rappels vers l'API GitLab avec succès :

   ```shell
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster (Praefect)" >}}

   Sur tous les nœuds Praefect, assurez-vous que le service Praefect peut se connecter aux nœuds Gitaly :

   ```shell
   # Run on Praefect nodes
   sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dial-nodes
   ```

   Sur tous les nœuds Gitaly, assurez-vous que le service Gitaly peut effectuer des rappels vers l'API GitLab avec succès :

   ```shell
   # Run on Gitaly nodes
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

      {{< /tab >}}

   {{< /tabs >}}

#### Étape 3 : Obtenir l'adresse IP et les noms d'hôte du pod Gitaly {#step-3-get-the-gitaly-pod-ip-and-hostnames}

Pour que l'API de déplacement de stockage de dépôt réussisse, le service Gitaly externe doit pouvoir se reconnecter aux pods Gitaly en utilisant le nom d'hôte du service pod. Afin que les noms d'hôte du service pod soient résolvables, nous devons ajouter les noms d'hôte au fichier hosts sur chaque service Gitaly externe exécutant le processus Gitaly.

1. Récupérez la liste des pods Gitaly et leurs adresses IP/noms d'hôte internes respectifs :

   ```shell
   kubectl get pods -l app=gitaly -o jsonpath='{range .items[*]}{.status.podIP}{"\t"}{.spec.hostname}{"."}{.spec.subdomain}{"."}{.metadata.namespace}{".svc\n"}{end}'
   ```

1. Ajoutez la sortie de la dernière étape au fichier `/etc/hosts` sur chaque service Gitaly externe exécutant le processus Gitaly.
1. Confirmez que les noms d'hôte du pod Gitaly peuvent être pings depuis chaque service Gitaly externe exécutant le processus Gitaly :

   ```shell
   ping <gitaly pod hostname>
   ```

Une fois la connectivité confirmée, nous pouvons procéder à la planification du déplacement du stockage de dépôt.

#### Étape 4 : Planifier le déplacement du stockage de dépôt {#step-4-schedule-the-repository-storage-move}

Planifiez le déplacement en suivant les étapes indiquées dans [déplacer des dépôts](https://docs.gitlab.com/administration/operations/moving_repositories/#moving-repositories).

#### Étape 5 : Configuration finale et validation {#step-5-final-configuration-and-validation}

1. Si vous avez plusieurs stockages Gitaly, [configurez l'emplacement de stockage des nouveaux dépôts](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored).
1. Envisagez de générer un fichier `gitlab.yml` consolidé pour l'avenir, qui inclut la configuration Gitaly externe :

   ```shell
   helm get values <RELEASE_NAME> -o yaml > gitlab.yml
   ```

1. Désactivez le sous-chart Gitaly interne dans le fichier `gitlab.yml` et pointez le nouveau stockage de dépôt `default` vers le service Gitaly externe. [GitLab requiert un stockage de dépôt par défaut](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#gitlab-requires-a-default-repository-storage) :

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```yaml
   global:
     gitaly:
       enabled: false                      # Disable the internal Gitaly subchart
       external:
         - name: ext-gitaly                # required
           hostname: node1.git.example.com # required
           port: 8075                      # optional, default shown
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
         - name: default                   # Add the default repository storage, use the same settings as ext-gitaly
           hostname: node1.git.example.com
           port: 8075
           tlsEnabled: false
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster (Praefect)" >}}

   ```yaml
   global:
     gitaly:
       enabled: false                      # Disable the internal Gitaly subchart
       external:
         - name: ext-gitaly-cluster        # required
           hostname: ha.git.example.com    # required
           port: 2305                      # Praefect uses port 2305
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
         - name: default                   # Add the default repository storage, use the same settings as ext-gitaly-cluster
           hostname: ha.git.example.com
           port: 2305
           tlsEnabled: false
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. Appliquez la nouvelle configuration :

   ```shell
   helm upgrade --install gitlab gitlab/gitlab \
     -f gitlab.yml
   ```

1. Facultatif. Supprimez les modifications apportées à chaque fichier `/etc/hosts` du Gitaly externe après avoir suivi l'étape [obtenir l'adresse IP et les noms d'hôte du pod Gitaly](#step-3-get-the-gitaly-pod-ip-and-hostnames).
1. Une fois que vous avez confirmé que tout fonctionne comme prévu, vous pouvez supprimer le PVC Gitaly :

   AVERTISSEMENT : Ne supprimez pas le PVC Gitaly avant d'avoir vérifié deux fois que tout fonctionne comme prévu.

   ```shell
   kubectl delete pvc repo-data-<release>-gitaly-0
   ```

### Migrer avec la méthode de sauvegarde/restauration {#migrate-with-the-backuprestore-method}

Cette méthode :

- Sauvegarde vos dépôts depuis le PersistentVolumeClaim (PVC) du chart Gitaly, puis les restaure vers le service Gitaly externe.
- Entraîne une interruption de service pour tous les utilisateurs.
- N'a pas été testé avec le [chart Praefect](../../charts/gitlab/praefect/_index.md) et n'est pas pris en charge.

#### Étape 1 :  Obtenir la révision de release actuelle du chart GitLab {#step-1-get-the-current-release-revision-of-the-gitlab-chart}

Dans le cas improbable où quelque chose se passe mal lors de la migration, obtenez la révision de release actuelle du chart GitLab. Copiez la sortie et mettez-la de côté au cas où nous aurions besoin d'effectuer un [rollback](#rollback) :

```shell
helm history <release> --max=1
```

#### Étape 2 : Configurer le service Gitaly externe ou le cluster Gitaly (Praefect) {#step-2-setup-external-gitaly-service-or-gitaly-cluster-praefect}

Configurez un [Gitaly externe](https://docs.gitlab.com/administration/gitaly/configure_gitaly/) ou un [cluster Gitaly externe (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/). Vous devez fournir le token Gitaly et le secret GitLab Shell de votre installation de chart dans le cadre de ces étapes :

```shell
# Get the GitLab Shell secret
kubectl get secret <release>-gitlab-shell-secret -ojsonpath='{.data.secret}' | base64 -d

# Get the Gitaly token
kubectl get secret <release>-gitaly-secret -ojsonpath='{.data.token}' | base64 -d
```

{{< tabs >}}

{{< tab title="Gitaly" >}}

- Le token Gitaly extrait ici doit être utilisé pour la valeur `AUTH_TOKEN`.
- Le secret GitLab Shell extrait ici doit être utilisé pour la valeur `shellsecret`.

{{< /tab >}}

{{< tab title="Gitaly Cluster (Praefect)" >}}

- Le token Gitaly extrait ici doit être utilisé pour `PRAEFECT_EXTERNAL_TOKEN`.
- Le secret GitLab Shell extrait ici doit être utilisé pour `GITLAB_SHELL_SECRET_TOKEN`.

{{< /tab >}}

{{< /tabs >}}

#### Étape 3 : Vérifier qu'aucune modification Git ne peut être effectuée pendant la migration {#step-3-verify-no-git-changes-can-be-made-during-migration}

Pour garantir l'intégrité des données de la migration, empêchez toute modification de vos dépôts Git en suivant les étapes ci-dessous :

##### 1\. Activer le mode de maintenance {#1-enable-maintenance-mode}

Si vous utilisez GitLab Enterprise Edition, activez le [mode de maintenance](https://docs.gitlab.com/administration/maintenance_mode/#enable-maintenance-mode) via l'interface utilisateur, l'API ou la console Rails :

```shell
kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Gitlab::CurrentSettings.update!(maintenance_mode: true)'
```

##### 2\. Réduire les pods Runner {#2-scale-down-runner-pods}

Si vous utilisez GitLab Community Edition, vous devez réduire les pods GitLab Runner en cours d'exécution dans le cluster. Cela empêche les runners de se connecter à GitLab pour traiter les jobs CI/CD.

Si vous utilisez GitLab Enterprise Edition, cette étape est facultative car le [mode de maintenance](https://docs.gitlab.com/administration/maintenance_mode/#enable-maintenance-mode) empêche les runners du cluster de se connecter à GitLab.

```shell
# Make note of the current number of replicas for Runners so we can scale up to this number later
kubectl get deploy -lapp=gitlab-gitlab-runner,release=<release> -o jsonpath='{.items[].spec.replicas}{"\n"}'

# Scale down the Runners pods to zero
kubectl scale deploy -lapp=gitlab-gitlab-runner,release=<release> --replicas=0
```

##### 3\. Confirmer qu'aucun job CI n'est en cours d'exécution {#3-confirm-no-ci-jobs-are-running}

Dans la zone d'administration, accédez à **CI/CD > Jobs**. Cette page affiche tous les jobs, mais confirmez qu'aucun job n'a le statut **En cours**. Vous devez attendre que les jobs soient terminés avant de passer à l'étape suivante.

##### 4\. Désactiver les jobs cron Sidekiq {#4-disable-sidekiq-cron-jobs}

Pour éviter que les jobs Sidekiq ne soient planifiés et exécutés pendant la migration, désactivez tous les jobs cron Sidekiq :

```shell
kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:disable!)'
```

##### 5\. Confirmer qu'aucun job en arrière-plan n'est en cours d'exécution {#5-confirm-no-background-jobs-are-running}

Nous devons attendre que les jobs en file d'attente ou en cours soient terminés avant de passer à l'étape suivante.

1. Dans la zone d'administration, accédez à [**Surveillance**](https://docs.gitlab.com/administration/admin_area/#background-jobs) et sélectionnez **Background Jobs**.
1. Sous le tableau de bord Sidekiq, sélectionnez **Queues** et ensuite **Live Poll**.
1. Attendez que **Occupé(e)** et **Enqueued** descendent à 0.

   ![Jobs Sidekiq en arrière-plan](img/sidekiq_bg_jobs_v16_5.png)

##### 6\. Réduire les pods Sidekiq et Webservice {#6-scale-down-sidekiq-and-webservice-pods}

Réduisez les pods Sidekiq et Webservice pour vous assurer qu'une sauvegarde cohérente est effectuée. Les deux services sont remontés à une étape ultérieure :

- Les pods Sidekiq sont remontés lors de l'étape de restauration
- Les pods Webservice sont remontés après le basculement vers le service Gitaly externe pour tester la connectivité

```shell
# Make note of the current number of replicas for Sidekiq and Webservice so we can scale up to this number later
kubectl get deploy -lapp=sidekiq,release=<release> -o jsonpath='{.items[].spec.replicas}{"\n"}'
kubectl get deploy -lapp=webservice,release=<release> -o jsonpath='{.items[].spec.replicas}{"\n"}'

# Scale down the Sidekiq and Webservice pods to zero
kubectl scale deploy -lapp=sidekiq,release=<release> --replicas=0
kubectl scale deploy -lapp=webservice,release=<release> --replicas=0
```

##### 7\. Restreindre les connexions externes au cluster {#7-restrict-external-connections-to-the-cluster}

Pour empêcher les utilisateurs et les runners GitLab externes d'apporter des modifications à GitLab, nous devons restreindre toutes les connexions inutiles à GitLab.

Une fois ces étapes terminées, GitLab est complètement indisponible dans le navigateur jusqu'à la fin de la restauration.

Afin de maintenir l'accessibilité du cluster au nouveau service Gitaly externe pendant la migration, nous devons ajouter l'adresse IP du service Gitaly externe à la configuration `nginx-ingress` comme seule exception externe.

1. Créez un fichier `ingress-only-allow-ext-gitaly.yml` avec le contenu suivant :

   ```yaml
   nginx-ingress:
     controller:
       service:
         loadBalancerSourceRanges:
          - "x.x.x.x/32"
   ```

   `x.x.x.x` doit être l'adresse IP du service Gitaly externe.

1. Appliquez la nouvelle configuration en utilisant les fichiers `gitlab.yml` et `ingress-only-allow-ext-gitaly.yml` :

   ```shell
   helm upgrade <release> gitlab/gitlab \
     -f gitlab.yml \
     -f ingress-only-allow-ext-gitaly.yml
   ```

##### 8\. Créer la liste des sommes de contrôle des dépôts {#8-create-list-of-repository-checksums}

Avant d'exécuter la sauvegarde, [vérifiez tous les dépôts GitLab](https://docs.gitlab.com/administration/raketasks/check/#check-all-gitlab-repositories) et créez une liste de sommes de contrôle des dépôts. Redirigez la sortie vers un fichier afin de pouvoir effectuer un `diff` des sommes de contrôle après la migration :

```shell
kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:git:checksum_projects > ~/checksums-before.txt
```

#### Étape 4 : Sauvegarder tous les dépôts {#step-4-backup-all-repositories}

[Créez une sauvegarde](../../backup-restore/backup.md#create-the-backup) de vos dépôts uniquement :

```shell
kubectl exec <toolbox pod name> -it -- backup-utility --skip artifacts,ci_secure_files,db,external_diffs,lfs,packages,pages,registry,terraform_state,uploads
```

#### Étape 5 : Configurer l'instance pour utiliser le nouveau service Gitaly {#step-5-configure-instance-to-use-new-gitaly-service}

1. Désactivez le sous-chart Gitaly et configurez GitLab pour utiliser le Gitaly externe. Si des références à Gitaly figurent dans votre fichier de configuration principal `gitlab.yml`, supprimez-les et créez un nouveau fichier `external-gitaly.yml` avec le contenu suivant.

   Si vous avez précédemment défini des stockages Gitaly supplémentaires, vous devez vous assurer qu'un stockage Gitaly correspondant avec le même nom est spécifié dans la nouvelle configuration, sinon l'opération de restauration échoue.

   Reportez-vous à la section [connexion à Gitaly externe via TLS](#connecting-to-external-gitaly-over-tls) si vous configurez TLS :

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   ```yaml
   global:
     gitaly:
       enabled: false
       external:
         - name: default                   # required
           hostname: node1.git.example.com # required
           port: 8075                      # optional, default shown
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster (Praefect)" >}}

   ```yaml
   global:
     gitaly:
       enabled: false
       external:
         - name: default                   # required
           hostname: ha.git.example.com    # required
           port: 2305                      # Praefect uses port 2305
           tlsEnabled: false               # optional, overrides gitaly.tls.enabled
   ```

      {{< /tab >}}

   {{< /tabs >}}

1. Appliquez la nouvelle configuration en utilisant les fichiers `gitlab.yml`, `ingress-only-allow-ext-gitaly.yml` et `external-gitaly.yml` :

   ```shell
   helm upgrade --install gitlab gitlab/gitlab \
     -f gitlab.yml \
     -f ingress-only-allow-ext-gitaly.yml \
     -f external-gitaly.yml
   ```

1. Remontez vos pods Webservice au nombre de réplicas d'origine s'ils ne sont pas en cours d'exécution. Cela est nécessaire pour pouvoir tester la connexion GitLab au Gitaly externe dans les étapes suivantes.

   ```shell
   kubectl scale deploy -lapp=webservice,release=<release> --replicas=<value>
   ```

1. Sur le pod Toolbox, confirmez que GitLab peut se connecter au Gitaly externe avec succès :

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:gitaly:check
   ```

1. Assurez-vous que le Gitaly externe peut se reconnecter à votre installation Chart :

   {{< tabs >}}

   {{< tab title="Gitaly" >}}

   Assurez-vous que le service Gitaly peut effectuer des rappels vers l'API GitLab avec succès :

   ```shell
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

   {{< /tab >}}

   {{< tab title="Gitaly Cluster (Praefect)" >}}

   Sur tous les nœuds Praefect, assurez-vous que le service Praefect peut se connecter aux nœuds Gitaly :

   ```shell
   # Run on Praefect nodes
   sudo /opt/gitlab/embedded/bin/praefect -config /var/opt/gitlab/praefect/config.toml dial-nodes
   ```

   Sur tous les nœuds Gitaly, assurez-vous que le service Gitaly peut effectuer des rappels vers l'API GitLab avec succès :

   ```shell
   # Run on Gitaly nodes
   sudo /opt/gitlab/embedded/bin/gitaly check /var/opt/gitlab/gitaly/config.toml
   ```

      {{< /tab >}}

   {{< /tabs >}}

#### Étape 6 : Restaurer et valider la sauvegarde du dépôt {#step-6-restore-and-validate-repository-backup}

1. [Restaurez le fichier de sauvegarde](../../backup-restore/restore.md#restoring-the-backup-file) créé précédemment. Par conséquent, les dépôts sont copiés vers le Gitaly externe ou le cluster Gitaly (Praefect) configuré.

1. [Vérifiez tous les dépôts GitLab](https://docs.gitlab.com/administration/raketasks/check/#check-all-gitlab-repositories) et créez une liste de sommes de contrôle des dépôts. Redirigez la sortie vers un fichier afin de pouvoir effectuer un `diff` des sommes de contrôle à l'étape suivante :

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rake gitlab:git:checksum_projects  > ~/checksums-after.txt
   ```

1. Comparez les sommes de contrôle des dépôts avant et après la migration des dépôts. Si les sommes de contrôle sont identiques, cette commande ne retourne aucune sortie :

   ```shell
   diff ~/checksums-before.txt ~/checksums-after.txt
   ```

   Si vous observez une somme de contrôle vide changeant en `0000000000000000000000000000000000000000` dans la sortie `diff` pour une ligne spécifique, cela est attendu et peut être ignoré en toute sécurité.

#### Étape 7 : Configuration finale et validation {#step-7-final-configuration-and-validation}

1. Pour permettre aux utilisateurs externes et aux runners GitLab de se reconnecter à GitLab, appliquez les fichiers `gitlab.yml` et `external-gitaly.yml`. Comme nous ne spécifions pas `ingress-only-allow-ext-gitaly.yml`, les restrictions IP sont supprimées :

    ```shell
    helm upgrade <release> gitlab/gitlab \
      -f gitlab.yml \
      -f external-gitaly.yml
    ```

    Envisagez de générer un fichier `gitlab.yml` consolidé pour l'avenir, qui inclut la configuration Gitaly externe :

    ```shell
    helm get values <release> gitlab/gitlab -o yaml > gitlab.yml
    ```

1. Si vous utilisez GitLab Enterprise Edition, désactivez le [mode de maintenance](https://docs.gitlab.com/administration/maintenance_mode/#enable-maintenance-mode) via l'interface utilisateur, l'API ou la console Rails :

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Gitlab::CurrentSettings.update!(maintenance_mode: false)'
   ```

1. Si vous avez plusieurs stockages Gitaly, [configurez l'emplacement de stockage des nouveaux dépôts](https://docs.gitlab.com/administration/repository_storage_paths/#configure-where-new-repositories-are-stored).
1. Activez les jobs cron Sidekiq :

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:enable!)'
   ```

1. Remontez vos pods Runner au nombre de réplicas d'origine s'ils ne sont pas en cours d'exécution :

   ```shell
   kubectl scale deploy -lapp=gitlab-gitlab-runner,release=<release> --replicas=<value>
   ```

1. Une fois que vous avez confirmé que tout fonctionne comme prévu, vous pouvez supprimer le PVC Gitaly :

   AVERTISSEMENT : Ne supprimez pas le PVC Gitaly avant d'avoir confirmé que les sommes de contrôle correspondent conformément à [l'étape 6](#step-6-restore-and-validate-repository-backup) et vérifié deux fois que tout fonctionne comme prévu.

   ```shell
   kubectl delete pvc repo-data-<release>-gitaly-0
   ```

#### Rollback {#rollback}

Si vous rencontrez des problèmes, vous pouvez effectuer un rollback des modifications apportées afin que le sous-chart Gitaly soit à nouveau utilisé.

Le PVC Gitaly d'origine doit exister pour effectuer un rollback avec succès.

1. Effectuez un rollback du chart GitLab vers la release précédente en utilisant le numéro de révision obtenu à [l'étape 1 : Obtenir la révision de release actuelle du chart GitLab](#step-1-get-the-current-release-revision-of-the-gitlab-chart) :

   ```shell
   helm rollback <release> <revision>
   ```

1. Remontez vos pods Webservice au nombre de réplicas d'origine s'ils ne sont pas en cours d'exécution :

   ```shell
   kubectl scale deploy -lapp=webservice,release=<release> --replicas=<value>
   ```

1. Remontez vos pods Sidekiq au nombre de réplicas d'origine s'ils ne sont pas en cours d'exécution :

   ```shell
   kubectl scale deploy -lapp=sidekiq,release=<release> --replicas=<value>
   ```

1. Activez les jobs cron Sidekiq si vous les avez précédemment désactivés :

   ```shell
   kubectl exec <toolbox pod name> -it -- gitlab-rails runner 'Sidekiq::Cron::Job.all.map(&:enable!)'
   ```

1. Remontez vos pods Runner au nombre de réplicas d'origine s'ils ne sont pas en cours d'exécution :

   ```shell
   kubectl scale deploy -lapp=gitlab-gitlab-runner,release=<release> --replicas=<value>
   ```

1. Si vous utilisez GitLab Enterprise Edition, désactivez le [mode de maintenance](https://docs.gitlab.com/administration/maintenance_mode/#disable-maintenance-mode) s'il est activé.

### Documentation connexe {#related-documentation}

- [Migrer vers le cluster Gitaly (Praefect)](https://docs.gitlab.com/administration/gitaly/praefect/#migrate-to-gitaly-cluster-praefect)
