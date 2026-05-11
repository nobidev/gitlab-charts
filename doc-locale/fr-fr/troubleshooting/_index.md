---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Dépannage du chart GitLab
---

## UPGRADE FAILED : "$name" n'a pas de releases déployées {#upgrade-failed-name-has-no-deployed-releases}

Cette erreur se produit lors de votre deuxième installation/mise à niveau si votre installation initiale a échoué.

Si votre installation initiale a complètement échoué et que GitLab n'a jamais été opérationnel, vous devez d'abord purger l'installation échouée avant de réinstaller.

```shell
helm uninstall <release-name>
```

Si, au contraire, la commande d'installation initiale a expiré, mais que GitLab a quand même démarré avec succès, vous pouvez ajouter l'option `--force` à la commande `helm upgrade` pour ignorer l'erreur et tenter de mettre à jour la release.

Sinon, si vous avez reçu cette erreur après avoir précédemment effectué des déploiements réussis du chart GitLab, vous êtes en présence d'un bug. Veuillez ouvrir un ticket sur notre [système de suivi des tickets](https://gitlab.com/gitlab-org/charts/gitlab/-/issues) , et consultez également [le ticket #630](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/630) où nous avons récupéré notre serveur CI de ce problème.

## Erreur : cette commande nécessite 2 arguments : nom de la release, chemin du chart {#error-this-command-needs-2-arguments-release-name-chart-path}

Une telle erreur peut se produire lorsque vous exécutez `helm upgrade` et qu'il y a des espaces dans les paramètres. Dans l'exemple suivant, `Test Username` est la cause du problème :

```shell
helm upgrade gitlab gitlab/gitlab --timeout 600s --set global.email.display_name=Test Username ...
```

Pour résoudre ce problème, passez les paramètres entre guillemets simples :

```shell
helm upgrade gitlab gitlab/gitlab --timeout 600s --set global.email.display_name='Test Username' ...
```

## Les conteneurs d'application s'initialisent en permanence {#application-containers-constantly-initializing}

Si vous constatez que Sidekiq, Webservice ou d'autres conteneurs basés sur Rails sont en permanence dans un état d'initialisation, vous attendez probablement que le conteneur `dependencies` passe.

Si vous vérifiez les logs d'un Pod donné spécifiquement pour le conteneur `dependencies`, vous pouvez voir les éléments suivants se répéter :

```plaintext
Checking database connection and schema version
WARNING: This version of GitLab depends on gitlab-shell 8.7.1, ...
Database Schema
Current version: 0
Codebase version: 20190301182457
```

Cela indique que le job `migrations` n'est pas encore terminé. L'objectif de ce job est à la fois de s'assurer que la base de données est initialisée et que toutes les migrations pertinentes sont en place. Les conteneurs d'application tentent d'attendre que la base de données soit à la version attendue ou au-dessus. Cela permet de s'assurer que l'application ne dysfonctionne pas en raison d'un schéma ne correspondant pas aux attentes de la base de code.

1. Trouvez le job `migrations`. `kubectl get job -lapp=migrations`
1. Trouvez le Pod exécuté par le job. `kubectl get pod -lbatch.kubernetes.io/job-name=<job-name>`
1. Examinez la sortie en vérifiant la colonne `STATUS`.

Si `STATUS` est `Running`, continuez. Si `STATUS` est `Completed`, les conteneurs d'application devraient démarrer peu après la prochaine vérification réussie.

Examinez les logs de ce pod. `kubectl logs <pod-name>`

Tout échec survenant pendant l'exécution de ce job doit être traité. Ces problèmes bloqueront l'utilisation de l'application jusqu'à leur résolution. Les problèmes possibles sont :

- Base de données PostgreSQL configurée inaccessible ou échec d'authentification
- Services Redis configurés inaccessibles ou échec d'authentification
- Impossible d'atteindre une instance Gitaly

## Application des modifications de configuration {#applying-configuration-changes}

La commande suivante effectuera les opérations nécessaires pour appliquer toutes les mises à jour apportées à `gitlab.yaml` :

```shell
helm upgrade <release name> <chart path> -f gitlab.yaml
```

## Le GitLab Runner inclus ne parvient pas à s'enregistrer {#included-gitlab-runner-failing-to-register}

Cela peut se produire lorsque le jeton d'enregistrement du runner a été modifié dans GitLab. (Cela se produit souvent après la restauration d'une sauvegarde)

1. Trouvez le nouveau jeton de runner partagé sur la page Web `admin/runners` de votre installation GitLab.
1. Trouvez le nom du Secret du jeton de runner existant stocké dans Kubernetes

   ```shell
   kubectl get secrets | grep gitlab-runner-secret
   ```

1. Supprimez le secret existant

   ```shell
   kubectl delete secret <runner-secret-name>
   ```

1. Créez le nouveau secret avec deux clés (`runner-registration-token` avec votre jeton partagé, et un `runner-token` vide)

   ```shell
   kubectl create secret generic <runner-secret-name> --from-literal=runner-registration-token=<new-shared-runner-token> --from-literal=runner-token=""
   ```

## Trop de redirections {#too-many-redirects}

Cela peut se produire lorsque vous avez une terminaison TLS avant l'Ingress NGINX et que les tls-secrets sont spécifiés dans la configuration.

1. Mettez à jour vos valeurs pour définir `global.ingress.annotations."nginx.ingress.kubernetes.io/ssl-redirect": "false"`

   Via un fichier de valeurs :

   ```yaml
   # values.yaml
   global:
     ingress:
       annotations:
         "nginx.ingress.kubernetes.io/ssl-redirect": "false"
   ```

   Via la CLI Helm :

   ```shell
   helm ... --set-string global.ingress.annotations."nginx.ingress.kubernetes.io/ssl-redirect"=false
   ```

1. Appliquez la modification.

> [!note] Lors de l'utilisation d'un service externe pour la terminaison SSL, ce service est responsable de la redirection vers https (si souhaité).

## Les mises à niveau échouent avec une erreur de champ immuable {#upgrades-fail-with-immutable-field-error}

### spec.clusterIP {#specclusterip}

Avant la version 3.0.0 de ces charts, la propriété `spec.clusterIP` [avait été renseignée dans plusieurs Services](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1710) malgré l'absence de valeur réelle (`""`). C'était un bug, et cela cause des problèmes avec la fusion tripartite des propriétés de Helm 3.

Une fois le chart déployé avec Helm 3, il n'y aurait _aucun chemin de mise à niveau possible_ sans récupérer les propriétés `clusterIP` des différents Services et les intégrer dans les valeurs fournies à Helm, ou sans supprimer les services concernés de Kubernetes.

La [version 3.0.0 de ce chart a corrigé cette erreur](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/1710), mais cela nécessite une correction manuelle.

Ce problème peut être résolu en supprimant simplement tous les services concernés.

1. Supprimez tous les services concernés :

   ```shell
   kubectl delete services -lrelease=RELEASE_NAME
   ```

1. Effectuez une mise à niveau via Helm.
1. Les futures mises à niveau ne rencontreront pas cette erreur.

> [!note] Cela modifiera toute valeur dynamique du `LoadBalancer` pour l'Ingress NGINX de ce chart, si utilisé. Consultez la [documentation des paramètres Ingress globaux](../charts/globals.md#configure-ingress-settings) pour plus de détails concernant `externalIP`. Vous devrez peut-être mettre à jour les enregistrements DNS !

### spec.selector {#specselector}

Les pods Sidekiq ne recevaient pas de sélecteur unique avant la version `3.0.0` du chart. [Les problèmes liés à ceci ont été documentés dans](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/663).

Les mises à niveau vers `3.0.0` via Helm suppriment automatiquement les anciens déploiements Sidekiq et en créent de nouveaux en ajoutant `-v1` au nom des `Deployments`, `HPAs` et `Pods` Sidekiq.

Si vous continuez à rencontrer cette erreur sur le déploiement Sidekiq lors de l'installation de `3.0.0`, résolvez-la en suivant les étapes suivantes :

1. Supprimez les services Sidekiq

   ```shell
   kubectl delete deployment --cascade -lrelease=RELEASE_NAME,app=sidekiq
   ```

1. Effectuez une mise à niveau via Helm.

### cannot patch "RELEASE-NAME-cert-manager" with kind Deployment {#cannot-patch-release-name-cert-manager-with-kind-deployment}

La mise à niveau depuis **CertManager** version `0.10` a introduit un certain nombre de changements incompatibles. Les anciennes définitions de ressources personnalisées (Custom Resource Definitions) doivent être désinstallées, supprimées du suivi de Helm, puis réinstallées.

Le chart Helm tente de le faire par défaut, mais si vous rencontrez cette erreur, vous devrez peut-être effectuer une action manuelle.

Si ce message d'erreur est apparu, la mise à niveau nécessite une étape supplémentaire par rapport à la normale afin de s'assurer que les nouvelles définitions de ressources personnalisées sont effectivement appliquées au déploiement.

1. Supprimez l'ancien déploiement **CertManager**.

   ```shell
   kubectl delete deployments -l app=cert-manager --cascade
   ```

1. Exécutez à nouveau la mise à niveau. Cette fois, installez les nouvelles définitions de ressources personnalisées

   ```shell
   helm upgrade --install --values - YOUR-RELEASE-NAME gitlab/gitlab < <(helm get values YOUR-RELEASE-NAME)
   ```

### cannot patch `gitlab-kube-state-metrics` with kind Deployment {#cannot-patch-gitlab-kube-state-metrics-with-kind-deployment}

La mise à niveau depuis **Prometheus** version `11.16.9` vers `15.0.4` modifie les labels de sélecteur utilisés sur le [déploiement kube-state-metrics](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-state-metrics), qui est désactivé par défaut (`prometheus.kubeStateMetrics.enabled=false`).

Si ce message d'erreur est rencontré, ce qui signifie `prometheus.kubeStateMetrics.enabled=true`, la mise à niveau nécessite [une étape supplémentaire](https://artifacthub.io/packages/helm/prometheus-community/prometheus#to-15-0) :

1. Supprimez l'ancien déploiement **kube-state-metrics**.

   ```shell
   kubectl delete deployments.apps -l app.kubernetes.io/instance=RELEASE_NAME,app.kubernetes.io/name=kube-state-metrics --cascade=orphan
   ```

1. Effectuez une mise à niveau via Helm.

## Erreurs `ImagePullBackOff`, `Failed to pull image` et `manifest unknown` {#imagepullbackoff-failed-to-pull-image-and-manifest-unknown-errors}

Si vous utilisez [`global.gitlabVersion`](../charts/globals.md#gitlab-version), commencez par supprimer cette propriété. Vérifiez les [correspondances de versions entre le chart et GitLab](../installation/version_mappings.md) et spécifiez une version compatible du chart `gitlab/gitlab` dans votre commande `helm`.

## UPGRADE FAILED : "cannot patch ..." après `helm 2to3 convert` {#upgrade-failed-cannot-patch--after-helm-2to3-convert}

Il s'agit d'un problème connu. Après la migration d'une release Helm 2 vers Helm 3, les mises à niveau suivantes peuvent échouer. Vous pouvez trouver l'explication complète et la solution de contournement dans [Migration de Helm v2 vers Helm v3](../installation/migration/helm.md#known-issues).

## UPGRADE FAILED : type mismatch on mailroom: `%!t(<nil>)` {#upgrade-failed-type-mismatch-on-mailroom-tnil}

Une telle erreur peut se produire si vous ne fournissez pas une map valide pour une clé qui attend une map.

Par exemple, la configuration ci-dessous provoquera cette erreur :

```yaml
gitlab:
  mailroom:
```

Pour résoudre ce problème, vous pouvez :

1. Fournir une map valide pour `gitlab.mailroom`.
1. Supprimer entièrement la clé `mailroom`.

Notez que pour les clés optionnelles, une map vide (`{}`) est une valeur valide.

## Le pod NGINX Ingress intégré ne parvient pas à démarrer : `Failed to watch *v1beta1.Ingress` {#bundled-nginx-ingress-pod-fails-to-start-failed-to-watch-v1beta1ingress}

Le message d'erreur suivant peut apparaître dans le pod du contrôleur NGINX Ingress intégré si vous exécutez Kubernetes version 1.22 ou ultérieure :

```plaintext
Failed to watch *v1beta1.Ingress: failed to list *v1beta1.Ingress: the server could not find the requested resource
```

Pour remédier à cela, assurez-vous que la version de Kubernetes est 1.21 ou antérieure. Consultez [\#2852](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/2852) pour plus d'informations sur la prise en charge de NGINX Ingress pour Kubernetes 1.22 ou ultérieur.

## Charge accrue sur le point de terminaison `/api/v4/jobs/request` {#increased-load-on-apiv4jobsrequest-endpoint}

Vous pouvez rencontrer ce problème si l'option `workhorse.keywatcher` a été définie sur `false` pour le déploiement gérant `/api/*`. Utilisez les étapes suivantes pour vérifier :

1. Accédez au conteneur `gitlab-workhorse` dans le pod gérant `/api/*` :

   ```shell
   kubectl exec -it --container=gitlab-workhorse <gitlab_api_pod> -- /bin/bash
   ```

1. Inspectez le fichier `/srv/gitlab/config/workhorse-config.toml`. La configuration `[redis]` est peut-être manquante :

   ```shell
   grep '\[redis\]' /srv/gitlab/config/workhorse-config.toml
   ```

Si la configuration `[redis]` n'est pas présente, l'indicateur `workhorse.keywatcher` a été défini sur `false` lors du déploiement, provoquant ainsi la charge supplémentaire sur le point de terminaison `/api/v4/jobs/request`. Pour résoudre ce problème, activez `keywatcher` dans le chart `webservice` :

```yaml
workhorse:
  keywatcher: true
```

## Git via SSH : `the remote end hung up unexpectedly` {#git-over-ssh-the-remote-end-hung-up-unexpectedly}

Les opérations Git via SSH peuvent échouer de manière intermittente avec l'erreur suivante :

```plaintext
fatal: the remote end hung up unexpectedly
fatal: early EOF
fatal: index-pack failed
```

Cette erreur peut avoir plusieurs causes potentielles :

- **Network timeouts** :

  Les clients Git ouvrent parfois une connexion et la laissent inactive, comme lors de la compression d'objets. Des paramètres comme `timeout client` dans HAProxy peuvent provoquer la fermeture de ces connexions inactives.

  Vous pouvez définir un keepalive dans `sshd` :

  ```yaml
  gitlab:
    gitlab-shell:
      config:
        clientAliveInterval: 15
  ```

- **Mémoire `gitlab-shell`** :

  Par défaut, le chart ne définit pas de limite sur la mémoire de GitLab Shell. Si `gitlab.gitlab-shell.resources.limits.memory` est défini trop bas, les opérations Git via SSH peuvent échouer avec ces erreurs.

  Exécutez `kubectl describe nodes` pour confirmer que cela est causé par des limites de mémoire plutôt que par des délais d'expiration réseau.

  ```plaintext
  System OOM encountered, victim process: gitlab-shell
  Memory cgroup out of memory: Killed process 3141592 (gitlab-shell)
  ```

## Erreur : `kex_exchange_identification: Connection closed by remote host` {#error-kex_exchange_identification-connection-closed-by-remote-host}

L'erreur suivante peut apparaître dans les logs de GitLab Shell :

```plaintext
subcomponent":"ssh","time":"2025-02-21T19:07:52Z","message":"kex_exchange_identification: Connection closed by remote host\r"}
```

Cette erreur est causée par OpenSSH `sshd` qui ne parvient pas à gérer les sondes de disponibilité et de vivacité. Pour résoudre cette erreur, utilisez [`gitlab-sshd`](../charts/gitlab/gitlab-shell/_index.md#configuration) à la place en remplaçant `sshDaemon: openssh` par `sshDaemon: gitlab-ssd` dans la configuration :

```yaml
gitlab:
  gitlab-shell:
    sshDaemon: gitlab-sshd
```

## Configuration YAML : `mapping values are not allowed in this context` {#yaml-configuration-mapping-values-are-not-allowed-in-this-context}

Le message d'erreur suivant peut apparaître lorsque la configuration YAML contient des espaces en début de ligne :

```plaintext
template: /var/opt/gitlab/templates/workhorse-config.toml.tpl:16:98:
  executing \"/var/opt/gitlab/templates/workhorse-config.toml.tpl\" at <data.YAML>:
    error calling YAML:
      yaml: line 2: mapping values are not allowed in this context
```

Pour remédier à cela, assurez-vous qu'il n'y a pas d'espaces en début de ligne dans la configuration.

Par exemple, modifiez ceci :

```yaml
  key1: value1
  key2: value2
```

... en cela :

```yaml
key1: value1
key2: value2
```

## TLS et certificats {#tls-and-certificates}

Si votre instance GitLab doit faire confiance à une autorité de certification TLS privée, GitLab pourrait ne pas parvenir à établir une liaison avec d'autres services comme le stockage d'objets, Elasticsearch, Jira ou Jenkins :

```plaintext
error: certificate verify failed (unable to get local issuer certificate)
```

Une confiance partielle des certificats signés par des autorités de certification privées peut se produire si :

- Les certificats fournis ne sont pas dans des fichiers séparés.
- Le conteneur init des certificats n'effectue pas toutes les étapes requises.

De plus, GitLab est principalement écrit en Ruby on Rails et en Go, et les bibliothèques TLS de chaque langage fonctionnent différemment. Cette différence peut entraîner des problèmes comme des job logs qui ne s'affichent pas dans l'interface GitLab, mais dont les job logs bruts peuvent être téléchargés sans problème.

De plus, selon la configuration `proxy_download`, votre navigateur est redirigé vers le stockage d'objets sans problème si le magasin de confiance est correctement configuré. Dans le même temps, les liaisons TLS par un ou plusieurs composants GitLab pourraient toujours échouer.

### Configuration et dépannage de la confiance des certificats {#certificate-trust-setup-and-troubleshooting}

Dans le cadre du dépannage des problèmes de certificats, assurez-vous de :

- Créer des secrets pour chaque certificat dont vous avez besoin de faire confiance.
- Fournir un seul certificat par fichier.

  ```plaintext
  kubectl create secret generic custom-ca --from-file=unique_name=/path/to/cert
  ```

  Dans cet exemple, le certificat est stocké en utilisant le nom de clé `unique_name`

Si vous fournissez un bundle ou une chaîne, certains composants GitLab ne fonctionneront pas.

Interrogez les secrets avec `kubectl get secrets` et `kubectl describe secrets/secretname`, qui affiche le nom de clé du certificat sous `Data`.

Fournissez des certificats supplémentaires à approuver en utilisant `global.certificates.customCAs` [dans les paramètres globaux du chart](../charts/globals.md#custom-certificate-authorities).

Lorsqu'un pod est déployé, un conteneur init monte les certificats et les configure afin que les composants GitLab puissent les utiliser. Le conteneur init est `registry.gitlab.com/gitlab-org/build/cng/alpine-certificates`.

Les certificats supplémentaires sont montés dans le conteneur à `/usr/local/share/ca-certificates`, en utilisant le nom de clé du secret comme nom de fichier du certificat.

Le conteneur init exécute `/scripts/bundle-certificates` ([source](https://gitlab.com/gitlab-org/build/CNG-mirror/-/blob/master/certificates/scripts/bundle-certificates)). Dans ce script, `update-ca-certificates` :

1. Copie les certificats personnalisés depuis `/usr/local/share/ca-certificates` vers `/etc/ssl/certs`.
1. Compile un bundle `ca-certificates.crt`.
1. Génère des hachages pour chaque certificat et crée un lien symbolique en utilisant le hachage, ce qui est requis pour Rails. Les bundles de certificats sont ignorés avec un avertissement :

   ```plaintext
   WARNING: unique_name does not contain exactly one certificate or CRL: skipping
   ```

[Dépannez le statut et les logs du conteneur init](https://kubernetes.io/docs/tasks/debug/debug-application/debug-init-containers/). Par exemple, pour afficher les logs du conteneur init des certificats et vérifier les avertissements :

```plaintext
kubectl logs gitlab-webservice-default-pod -c certificates
```

### Vérification sur la console Rails {#check-on-the-rails-console}

Utilisez le pod toolbox pour vérifier si Rails fait confiance aux certificats que vous avez fournis.

1. Démarrez une console Rails (remplacez `<namespace>` par l'espace de nommage où GitLab est installé) :

   ```shell
   kubectl exec -ti $(kubectl get pod -n <namespace> -lapp=toolbox -o jsonpath='{.items[0].metadata.name}') -n <namespace> -- bash
   /srv/gitlab/bin/rails console
   ```

1. Vérifiez l'emplacement que Rails utilise pour les autorités de certification :

   ```ruby
   OpenSSL::X509::DEFAULT_CERT_DIR
   ```

1. Exécutez une requête HTTPS dans la console Rails :

   ```ruby
   ## Configure a web server to connect to:
   uri = URI.parse("https://myservice.example.com")

   require 'openssl'
   require 'net/http'
   Rails.logger.level = 0
   OpenSSL.debug=1
   http = Net::HTTP.new(uri.host, uri.port)
   http.set_debug_output($stdout)
   http.use_ssl = true

   http.verify_mode = OpenSSL::SSL::VERIFY_PEER
   # http.verify_mode = OpenSSL::SSL::VERIFY_NONE # TLS verification disabled

   response = http.request(Net::HTTP::Get.new(uri.request_uri))
   ```

### Dépannage du conteneur init {#troubleshoot-the-init-container}

Exécutez le conteneur des certificats avec Docker.

1. Configurez une structure de répertoires et remplissez-la avec vos certificats :

   ```shell
   mkdir -p etc/ssl/certs usr/local/share/ca-certificates

     # The secret name is: my-root-ca
     # The key name is: corporate_root

   kubectl get secret my-root-ca -ojsonpath='{.data.corporate_root}' | \
        base64 --decode > usr/local/share/ca-certificates/corporate_root

     # Check the certificate is correct:

   openssl x509 -in usr/local/share/ca-certificates/corporate_root -text -noout
   ```

1. Déterminez la version correcte du conteneur :

   ```shell
   kubectl get deployment -lapp=webservice -ojsonpath='{.items[0].spec.template.spec.initContainers[0].image}'
   ```

1. Exécutez le conteneur, qui effectue la préparation du contenu de `etc/ssl/certs` :

   ```shell
   docker run -ti --rm \
        -v $(pwd)/etc/ssl/certs:/etc/ssl/certs \
        -v $(pwd)/usr/local/share/ca-certificates:/usr/local/share/ca-certificates \
        registry.gitlab.com/gitlab-org/build/cng/gitlab-base:v15.10.3
   ```

1. Vérifiez que vos certificats ont été correctement générés :

   - `etc/ssl/certs/corporate_root.pem` devrait avoir été créé.
   - Il devrait y avoir un nom de fichier haché, qui est un lien symbolique vers le certificat lui-même (tel que `etc/ssl/certs/1234abcd.0`).
   - Le fichier et le lien symbolique devraient s'afficher avec :

     ```shell
     ls -l etc/ssl/certs/ | grep corporate_root
     ```

     Par exemple :

     ```plaintext
     lrwxrwxrwx   1 root root      20 Oct  7 11:34 28746b42.0 -> corporate_root.pem
     -rw-r--r--   1 root root    1948 Oct  7 11:34 corporate_root.pem
     ```

## `308: Permanent Redirect` provoquant une boucle de redirection {#308-permanent-redirect-causing-a-redirect-loop}

`308: Permanent Redirect` peut se produire si votre équilibreur de charge est configuré pour envoyer du trafic non chiffré (HTTP) vers NGINX. Comme NGINX redirige par défaut `HTTP` vers `HTTPS`, vous pouvez vous retrouver dans une « boucle de redirection ».

Pour résoudre ce problème, [activez le paramètre `use-forwarded-headers` de NGINX](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#use-forwarded-headers).

## Erreurs "Invalid Word" dans les logs `nginx-controller` et erreurs `404` {#invalid-word-errors-in-the-nginx-controller-logs-and-404-errors}

Après une mise à niveau vers le chart Helm 6.6 ou ultérieur, vous pouvez rencontrer des codes de retour `404` lors de la visite de vos domaines GitLab ou tiers pour des applications installées dans votre cluster, et voir également des erreurs "invalid word" dans les logs `gitlab-nginx-ingress-controller` :

```console
gitlab-nginx-ingress-controller-899b7d6bf-688hr controller W1116 19:03:13.162001       7 store.go:846] skipping ingress gitlab/gitlab-minio: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-688hr controller W1116 19:03:13.465487       7 store.go:846] skipping ingress gitlab/gitlab-registry: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:12.233577       6 store.go:846] skipping ingress gitlab/gitlab-kas: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:12.536534       6 store.go:846] skipping ingress gitlab/gitlab-webservice-default: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:12.848844       6 store.go:846] skipping ingress gitlab/gitlab-webservice-default-smartcard: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:13.161640       6 store.go:846] skipping ingress gitlab/gitlab-minio: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
gitlab-nginx-ingress-controller-899b7d6bf-lqcks controller W1116 19:03:13.465425       6 store.go:846] skipping ingress gitlab/gitlab-registry: nginx.ingress.kubernetes.io/configuration-snippet annotation contains invalid word proxy_pass
```

Dans ce cas, examinez vos valeurs GitLab et tous les objets Ingress tiers pour l'utilisation de [snippets de configuration](https://kubernetes.github.io/ingress-nginx/examples/customization/configuration-snippets/). Vous devrez peut-être ajuster ou modifier le paramètre `nginx-ingress.controller.config.annotation-value-word-blocklist`.

Consultez [Annotation value word blocklist](../charts/nginx/_index.md#annotation-value-word-blocklist) pour plus de détails.

### Le montage d'un volume prend beaucoup de temps {#volume-mount-takes-a-long-time}

Le montage de volumes volumineux, tels que les volumes du chart `gitaly` ou `toolbox`, peut prendre beaucoup de temps car Kubernetes modifie récursivement les permissions du contenu du volume pour correspondre au `securityContext` du Pod.

À partir de Kubernetes 1.23, vous pouvez définir `securityContext.fsGroupChangePolicy` sur `OnRootMismatch` pour atténuer ce problème. Cet indicateur est pris en charge par tous les sous-charts GitLab.

Par exemple, pour le sous-chart Gitaly :

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroupChangePolicy: "OnRootMismatch"
```

Consultez la [documentation Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/security-context/#configure-volume-permission-and-ownership-change-policy-for-pods) pour plus de détails.

Pour les versions de Kubernetes ne prenant pas en charge `fsGroupChangePolicy`, vous pouvez atténuer le problème en modifiant ou en supprimant complètement les paramètres du `securityContext`.

```yaml
gitlab:
  gitaly:
    securityContext:
      fsGroup: ""
      runAsUser: ""
```

> [!note] L'exemple de syntaxe élimine entièrement le paramètre `securityContext`. La définition de `securityContext: {}` ou `securityContext:` ne fonctionne pas en raison de la façon dont Helm fusionne les valeurs par défaut avec la configuration fournie par l'utilisateur.

### Erreurs 502 intermittentes {#intermittent-502-errors}

Lorsqu'une requête traitée par un worker Puma dépasse le seuil de limite de mémoire, elle est terminée par l'OOMKiller du nœud. Cependant, l'arrêt de la requête ne tue ni ne redémarre nécessairement le pod webservice lui-même. Cette situation entraîne le retour d'un délai d'expiration `502` par la requête. Dans les logs, cela apparaît comme un worker Puma créé peu après l'enregistrement de l'erreur `502`.

```shell
2024-01-19T14:12:08.949263522Z {"correlation_id":"XXXXXXXXXXXX","duration_ms":1261,"error":"badgateway: failed to receive response: context canceled"....
2024-01-19T14:12:24.214148186Z {"component": "gitlab","subcomponent":"puma.stdout","timestamp":"2024-01-19T14:12:24.213Z","pid":1,"message":"- Worker 2 (PID: 7414) booted in 0.84s, phase: 0"}
```

Pour résoudre ce problème, [augmentez les limites de mémoire pour les pods webservice](../charts/gitlab/webservice/_index.md#memory-requestslimits).

### Échec de la mise à niveau - `cannot patch "gitlab-prometheus-server" with kind Deployment` {#upgrade-failed---cannot-patch-gitlab-prometheus-server-with-kind-deployment}

Avec le chart 9.0, nous avons mis à jour la version majeure du sous-chart Prometheus. Les labels de sélecteur et la version de Prometheus ont été modifiés et nécessitent une intervention manuelle.

Veuillez suivre le [guide de migration](../releases/9_0.md#prometheus-upgrade) pour mettre à niveau le chart Prometheus.

## Échec de la sonde de disponibilité Webservice {#webservice-readiness-probe-fails}

À partir de la version 9.2 du chart GitLab (GitLab 18.2), la prise en charge de la double pile pour IPv4 et IPv6 est activée par défaut. Si vous exécutez une version de GitLab antérieure à 18.2 avec une liste d'adresses IP autorisées personnalisée pour la surveillance, cela peut entraîner l'échec des sondes Kubernetes pour les Pods webservice.

```plaintext
Events:
  Type     Reason                Age                   From                     Message
  ----     ------                ----                  ----                     -------
[snip]
  Warning  Unhealthy             43m (x15 over 44m)    kubelet                  Startup probe failed: HTTP probe failed with statuscode: 404
```

Pour corriger les sondes Webservice, vous pouvez :

- Mettre à niveau l'image Webservice pour qu'elle corresponde à la version du chart.
- Étendre votre liste d'adresses autorisées de surveillance avec les adresses équivalentes mappées IPv6 (par exemple `::ffff:10.0.0.0` pour `10.0.0.0`).
- Configurer explicitement le point de terminaison de surveillance pour écouter uniquement sur IPv4 (`gitlab.webservice.monitoring.listenAddr=0.0.0.0`).
- [Désactiver le mappage IP au niveau du nœud/noyau.](https://docs.kernel.org/networking/ip-sysctl.html#proc-sys-net-ipv6-variables)

## invalid : `spec.progressDeadlineSeconds` {#invalid-specprogressdeadlineseconds}

Si vous utilisez Helm `v3.18.0`, vous obtiendrez cette erreur lors de la mise à niveau de votre chart :

```shell
Error: UPGRADE FAILED: cannot patch "gitlab-nginx-ingress-controller" with kind Deployment: Deployment.apps "gitlab-nginx-ingress-controller" is invalid: spec.progressDeadlineSeconds: Invalid value: 0: must be greater than minReadySeconds
```

Pour résoudre ce problème, mettez à niveau votre client Helm vers `v3.18.1` ou une version ultérieure. Vous pouvez également le rétrograder vers `v3.17.x`.

Cela est dû à un [problème Helm 30878](https://github.com/helm/helm/issues/30878).

## Migrations en échec : `TypeError: Invalid type for configuration.` {#migrations-failing-typeerror-invalid-type-for-configuration}

Par défaut, le chart GitLab configure deux connexions à la base de données :

- Vers la base de données principale de l'application Rails.
- Vers la base de données CI.

Lorsque les deux connexions ciblent la même base de données, une seule base de données doit avoir les tâches de base de données activées (`databaseTasks: true`) pour éviter les conflits de configuration.

Si les deux connexions ont les tâches de base de données activées, les migrations échouent avec cette erreur :

```plaintext
Running db:schema:load:main rake task
rake aborted!
TypeError: Invalid type for configuration. Expected Symbol, String, or Hash. Got nil
```

Pour résoudre ce problème, vous pouvez :

- Modifier vos valeurs pour omettre `global.psql.databaseTasks`.
- Configurer `databaseTasks` explicitement et choisir une base de données pour les tâches de base de données. Par exemple :

  ```yaml
  global:
    psql:
      main:
        databaseTasks: true
      ci:
        databaseTasks: false
  ```
