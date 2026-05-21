---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Prérequis du chart GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Avant de déployer GitLab dans un cluster Kubernetes, installez les prérequis suivants et décidez des options à utiliser lors de l'installation.

## Prérequis {#prerequisites}

### kubectl {#kubectl}

Installez `kubectl` en suivant [la documentation Kubernetes](https://kubernetes.io/docs/tasks/tools/#kubectl). La version que vous installez doit être [à une version mineure près](https://kubernetes.io/releases/version-skew-policy/#kubectl) de la version utilisée dans votre cluster.

### Helm {#helm}

Installez Helm v4.0 ou une version ultérieure en suivant [la documentation Helm](https://helm.sh/docs/intro/install/).

Le chart GitLab continue de prendre en charge Helm 3 jusqu'à sa fin de vie officielle, [estimée en juillet 2026](https://helm.sh/community/hips/hip-0012/#the-process--timelines).

### PostgreSQL {#postgresql}

Configurez une [instance PostgreSQL externe](../advanced/external-db/_index.md).

Consultez [les exigences GitLab](https://docs.gitlab.com/install/requirements/#postgresql) pour connaître les versions PostgreSQL prises en charge.

### Redis {#redis}

Configurez une [instance Redis externe](../advanced/external-redis/_index.md). Pour tous les paramètres de configuration disponibles, consultez la [documentation sur les variables globales Redis](../charts/globals.md#configure-redis-settings).

## Choisir d'autres options {#decide-on-other-options}

Vous utilisez les options suivantes avec `helm install` lorsque vous déployez GitLab.

### Secrets {#secrets}

Vous devez créer certains secrets, comme des clés SSH. Par défaut, ces secrets sont générés automatiquement lors du déploiement, mais si vous souhaitez les spécifier, vous pouvez consulter la [documentation sur les secrets](secrets.md).

### Réseau et DNS {#networking-and-dns}

Par défaut, pour exposer les services, GitLab utilise des serveurs virtuels basés sur le nom, configurés avec des objets `Ingress`. Ces objets sont des objets Kubernetes `Service` de type `type: LoadBalancer`.

Vous devez spécifier un domaine contenant des enregistrements pour résoudre `gitlab`, `registry` et `minio` (si activé) vers l'adresse IP appropriée pour votre chart.

Par exemple, utilisez ce qui suit avec `helm install` :

```shell
--set global.hosts.domain=example.com
```

Lorsque la prise en charge des domaines personnalisés est activée, un sous-domaine `*.<pages domain>`, qui par défaut est `<pages domain>`, devient `pages.<global.hosts.domain>`. Le domaine est résolu vers l'IP externe attribuée à Pages par `--set global.pages.externalHttp` ou `--set global.pages.externalHttps`.

Pour utiliser des domaines personnalisés, GitLab Pages peut utiliser un enregistrement CNAME qui pointe le domaine personnalisé vers un domaine `<namespace>.<pages domain>` correspondant.

#### Adresses IP dynamiques avec `external-dns` {#dynamic-ip-addresses-with-external-dns}

Si vous prévoyez d'utiliser un service d'enregistrement DNS automatique comme [`external-dns`](https://github.com/kubernetes-sigs/external-dns), vous n'avez pas besoin de configuration DNS supplémentaire pour GitLab. Cependant, vous devez déployer `external-dns` dans votre cluster. La page du projet [fournit un guide complet](https://github.com/kubernetes-sigs/external-dns#deploying-to-a-cluster) pour chaque fournisseur pris en charge.

> [!note]
> Si vous activez la prise en charge des domaines personnalisés pour GitLab Pages, `external-dns` ne fonctionnera plus pour le domaine Pages (`pages.<global.hosts.domain>` par défaut). Vous devez configurer manuellement l'entrée DNS pour pointer le domaine vers l'adresse IP externe dédiée à Pages.

Si vous provisionnez un [cluster GKE](cloud/gke.md) à l'aide du script fourni, `external-dns` est automatiquement installé dans votre cluster.

#### Adresses IP statiques {#static-ip-addresses}

Si vous prévoyez de configurer manuellement vos enregistrements DNS, ils doivent tous pointer vers une adresse IP statique. Par exemple, si vous choisissez `example.com` et que vous disposez d'une adresse IP statique `10.10.10.10`, alors `gitlab.example.com`, `registry.example.com` et `minio.example.com` (si vous utilisez MinIO) doivent tous être résolus vers `10.10.10.10`.

Si vous utilisez GKE, apprenez-en plus sur la [création de l'IP externe et de l'entrée DNS](cloud/gke.md#creating-the-external-ip). Consultez la documentation de votre fournisseur cloud ou DNS pour obtenir de l'aide supplémentaire sur ce processus.

Par exemple, utilisez ce qui suit avec `helm install` :

```shell
--set global.hosts.externalIP=10.10.10.10
```

#### Compatibilité avec la sélection de protocole Istio {#compatibility-with-istio-protocol-selection}

Les noms des ports de service suivent la convention compatible avec la [sélection explicite de port](https://istio.io/latest/docs/ops/configuration/traffic-management/protocol-selection/#explicit-protocol-selection) d'Istio. Ils ressemblent à `<protocol>-<suffix>`, par exemple `tls-gitaly` ou `https-metrics`.

Notez que Gitaly et KAS utilisent gRPC, mais utilisent le préfixe `tcp` à la place en raison des conclusions de [l'issue n° 3822](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3822) et de [l'issue n° 4908](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/4908).

### Persistance {#persistence}

Par défaut, le chart GitLab crée des demandes de volume en supposant qu'un provisionneur dynamique crée les volumes persistants sous-jacents. Si vous souhaitez personnaliser la `storageClass` ou créer et attribuer manuellement des volumes, consultez la [documentation sur le stockage](storage.md).

> [!note]
> Après le déploiement initial, toute modification de vos paramètres de stockage nécessite de modifier manuellement les objets Kubernetes. Il est donc préférable de planifier à l'avance avant de déployer votre instance de production afin d'éviter tout travail supplémentaire de migration de stockage.

### Certificats TLS {#tls-certificates}

Vous devriez exécuter GitLab avec HTTPS, ce qui nécessite des certificats TLS. Par défaut, le chart GitLab installe et configure [`cert-manager`](https://github.com/cert-manager/cert-manager) pour obtenir des certificats TLS gratuits.

Si vous disposez de votre propre certificat générique, ou si vous avez déjà `cert-manager` installé, ou si vous avez un autre moyen d'obtenir des certificats TLS, apprenez-en plus sur les [options TLS](tls.md).

Pour la configuration par défaut, vous devez spécifier une adresse e-mail pour enregistrer vos certificats TLS. Par exemple, utilisez ce qui suit avec `helm install` :

```shell
--set certmanager-issuer.email=me@example.com
```

### Prometheus {#prometheus}

Nous utilisons le [chart Prometheus amont](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration) et ne remplaçons pas les valeurs par défaut, à l'exception d'un fichier `prometheus.yml` personnalisé pour limiter la collecte de métriques à l'API Kubernetes et aux objets créés par le chart GitLab. Cependant, nous désactivons par défaut `alertmanager`, `node-exporter`, `pushgateway` et `kube-stat-metrics`.

Le fichier `prometheus.yml` indique à Prometheus de collecter des métriques à partir des ressources qui possèdent l'annotation `gitlab.com/prometheus_scrape`. De plus, les annotations `gitlab.com/prometheus_path` et `gitlab.com/prometheus_port` peuvent être utilisées pour configurer la façon dont les métriques sont découvertes. Chacune de ces annotations est comparable aux annotations `prometheus.io/{scrape,path,port}`.

Si vous surveillez ou souhaitez surveiller l'application GitLab avec votre installation de Prometheus, les annotations `prometheus.io/*` d'origine sont toujours ajoutées aux Pods et Services appropriés. Cela permet la continuité de la collecte de métriques pour les utilisateurs existants et offre la possibilité d'utiliser la configuration Prometheus par défaut pour capturer à la fois les métriques de l'application GitLab et celles des autres applications s'exécutant dans un cluster Kubernetes.

Consultez la [documentation du chart Prometheus amont](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus#configuration) pour la liste exhaustive des options de configuration et assurez-vous qu'elles sont des sous-clés de `prometheus`, car nous l'utilisons comme chart de dépendance.

Par exemple, les demandes de stockage persistant peuvent être contrôlées avec :

```yaml
prometheus:
  alertmanager:
    enabled: false
    persistentVolume:
      enabled: false
      size: 2Gi
  prometheus-pushgateway:
    enabled: false
    persistentVolume:
      enabled: false
      size: 2Gi
  server:
    persistentVolume:
      enabled: true
      size: 8Gi
```

#### Configurer Prometheus pour scraper les endpoints TLS {#configure-prometheus-to-scrape-tls-enabled-endpoints}

Prometheus peut être configuré pour scraper des métriques depuis des endpoints TLS si l'exportateur concerné prend en charge TLS et que la configuration du chart expose une configuration TLS pour l'endpoint de l'exportateur.

Il y a quelques mises en garde lors de l'utilisation de TLS et de la [découverte de services Kubernetes](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#kubernetes_sd_config) pour les [configurations de scraping](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#scrape_config) Prometheus :

- Pour les rôles de découverte [pod](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#pod) et [endpoints de service](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#endpoints), Prometheus utilise l'adresse IP interne du Pod pour définir l'adresse de la cible de scraping. Pour vérifier le certificat TLS, Prometheus doit être configuré soit avec le Common Name (CN) défini dans le certificat créé pour l'endpoint de métriques, soit avec un nom inclus dans l'extension Subject Alternative Name (SAN). Le nom n'a pas besoin d'être résolu et peut être n'importe quelle chaîne arbitraire qui constitue un [nom DNS valide](https://datatracker.ietf.org/doc/html/rfc1034#section-3.1).
- Si le certificat utilisé pour l'endpoint de l'exportateur est auto-signé ou autrement absent de l'image de base Prometheus, le pod Prometheus doit monter un certificat pour l'autorité de certification (CA) qui a signé le certificat utilisé pour l'endpoint de l'exportateur. Prometheus utilise un `ca-bundle` de Debian [dans son image de base](https://github.com/prometheus/busybox).
- Prometheus prend en charge la définition de ces deux éléments à l'aide d'un [tls_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#tls_config) qui est appliqué à chacune des configurations de scraping. Bien que Prometheus dispose d'un mécanisme robuste [relabel_config](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config) pour définir les labels cibles Prometheus basés sur les annotations de Pod et d'autres attributs découverts, la définition de `tls_config.server_name` et de `tls_config.ca_file` n'est pas possible avec `relabel_config`. Consultez cette [issue du projet Prometheus](https://github.com/prometheus/prometheus/issues/4827) pour plus de détails.

Compte tenu de ces mises en garde, la configuration la plus simple consiste à partager un « nom » et une CA pour tous les certificats utilisés pour les endpoints de l'exportateur :

1. Choisissez un nom arbitraire unique à utiliser pour `tls_config.server_name` (par exemple, `metrics.gitlab`).
1. Ajoutez ce nom à la liste SAN pour chaque certificat utilisé pour chiffrer en TLS les endpoints de l'exportateur.
1. Émettez tous les certificats depuis la même CA :
   - Ajoutez le certificat CA en tant que secret de cluster.
   - Montez ce secret dans le conteneur du serveur Prometheus en utilisant la configuration `extraSecretMounts:` du [chart Prometheus](https://github.com/prometheus-community/helm-charts/blob/main/charts/prometheus/values.yaml).
   - Définissez-le comme `tls_config.ca_file` pour le `scrape_config` Prometheus.

L'[exemple de valeurs TLS Prometheus](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/prometheus/values-tls.yaml) fournit un exemple pour cette configuration partagée en :

1. Définissant `tls_config.server_name` à `metrics.gitlab` pour les rôles `scrape_config` pod/endpoint.
1. Supposant que `metrics.gitlab` a été ajouté à la liste SAN pour chaque certificat utilisé pour l'endpoint de l'exportateur.
1. Supposant que le certificat CA a été ajouté à un secret nommé `metrics.gitlab.tls-ca` avec une clé de secret également nommée `metrics.gitlab.tls-ca` créée dans le même espace de nommage que celui dans lequel le chart Prometheus a été déployé (par exemple, `kubectl create secret generic --namespace=gitlab metrics.gitlab.tls-ca --from-file=metrics.gitlab.tls-ca=./ca.pem`).
1. Montant ce secret `metrics.gitlab.tls-ca` dans `/etc/ssl/certs/metrics.gitlab.tls-ca` à l'aide d'une entrée `extraSecretMounts:`.
1. Définissant `tls_config.ca_file` à `/etc/ssl/certs/metrics.gitlab.tls-ca`.

#### Endpoints de l'exportateur {#exporter-endpoints}

Tous les endpoints de métriques inclus dans le chart GitLab ne prennent pas en charge TLS. Si l'endpoint peut être et est TLS-activé, ils définiront également l'annotation `gitlab.com/prometheus_scheme: "https"`, ainsi que l'annotation `prometheus.io/scheme: "https"`, l'une ou l'autre pouvant être utilisée avec un `relabel_config` pour définir le label cible Prometheus `__scheme__`. L'[exemple de valeurs TLS Prometheus](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/prometheus/values-tls.yaml) inclut un `relabel_config` qui cible `__scheme__` en utilisant l'annotation `gitlab.com/prometheus_scheme: "https"`.

Le tableau suivant liste les Deployments (ou, lors de l'utilisation de l'un ou des deux parmi Gitaly et Praefect :  StatefulSets) et les endpoints de Service auxquels l'annotation `gitlab.com/prometheus_scrape: true` est appliquée.

Dans les liens de documentation ci-dessous, si le composant mentionne l'ajout d'entrées SAN, assurez-vous d'ajouter également le SAN que vous avez choisi d'utiliser pour le Prometheus `tls_config.server_name`.

| Service                                                       | Port des métriques (par défaut) | Prend en charge TLS ? | Informations supplémentaires |
|:--------------------------------------------------------------|:----------------------|:--------------|:-----------------------|
| [Gitaly](../charts/gitlab/gitaly/_index.md)                   | `9236`                | {{< yes >}}   | Activé avec `global.gitaly.tls.enabled=true`<br><br>Secret par défaut : `RELEASE-gitaly-tls`<br><br>[Docs : Exécution de Gitaly via TLS](../charts/gitlab/gitaly/_index.md#running-gitaly-over-tls) |
| [GitLab Exporter](../charts/gitlab/gitlab-exporter/_index.md) | `9168`                | {{< yes >}}   | Activé avec `gitlab.gitlab-exporter.tls.enabled=true`<br><br>Secret par défaut : `RELEASE-gitlab-exporter-tls` |
| [GitLab Pages](../charts/gitlab/gitlab-pages/_index.md)       | `9235`                | {{< yes >}}   | Activé avec `gitlab.gitlab-pages.metrics.tls.enabled=true`<br><br>Secret par défaut : `RELEASE-pages-metrics-tls`<br><br>[Docs : Paramètres généraux](../charts/gitlab/gitlab-pages/_index.md#general-settings) |
| [GitLab Runner](../charts/gitlab/gitlab-runner/_index.md)     | `9252`                | {{< no >}}    | [Issue - Ajouter la prise en charge TLS pour l'endpoint de métriques](https://gitlab.com/gitlab-org/gitlab-runner/-/issues/29176) |
| [GitLab Shell](../charts/gitlab/gitlab-shell/_index.md)       | `9122`                | {{< no >}}    | L'exportateur de métriques GitLab Shell n'est activé que lors de l'utilisation de [`gitlab-sshd`](https://docs.gitlab.com/administration/operations/gitlab_sshd/). OpenSSH est recommandé pour les environnements nécessitant TLS |
| [KAS](../charts/gitlab/kas/_index.md)                         | `8151`                | {{< yes >}}   | Peut être configuré à l'aide des options `global.kas.customConfig.observability.listen.certificate_file` et `global.kas.customConfig.observability.listen.key_file` |
| [Praefect](../charts/gitlab/praefect/_index.md)               | `9236`                | {{< yes >}}   | Activé avec `global.praefect.tls.enabled=true`<br><br>Secret par défaut : `RELEASE-praefect-tls`<br><br>[Docs : Exécution de Praefect via TLS](../charts/gitlab/praefect/_index.md#running-praefect-over-tls) |
| [Registry](../charts/registry/_index.md)                      | `5100`                | {{< yes >}}   | Activé avec `registry.debug.tls.enabled=true`<br><br>[Docs : Registry - Configuration de TLS pour le port de débogage](../charts/registry/_index.md#configuring-tls-for-the-debug-port) |
| [Sidekiq](../charts/gitlab/sidekiq/_index.md)                 | `3807`                | {{< yes >}}   | Activé avec `gitlab.sidekiq.metrics.tls.enabled=true`<br><br>Secret par défaut : `RELEASE-sidekiq-metrics-tls`<br><br>[Docs : Options de ligne de commande d'installation](../charts/gitlab/sidekiq/_index.md#installation-command-line-options) |
| [Webservice](../charts/gitlab/sidekiq/_index.md)              | `8083`                | {{< yes >}}   | Activé avec `gitlab.webservice.metrics.tls.enabled=true`<br><br>Secret par défaut : `RELEASE-webservice-metrics-tls`<br><br>[Docs : Options de ligne de commande d'installation](../charts/gitlab/webservice/_index.md#installation-command-line-options) |
| [Ingress-NGINX](../charts/nginx/_index.md)                    | `10254`               | {{< no >}}    | Ne prend pas en charge TLS sur le port métriques/healthcheck |

Pour le pod webservice, le port exposé est l'exportateur webrick autonome dans le conteneur webservice. Le port du conteneur workhorse n'est pas scrapé. Consultez la [documentation sur les métriques Webservice](../charts/gitlab/webservice/_index.md#metrics) pour plus de détails.

### E-mail sortant {#outgoing-email}

Par défaut, l'e-mail sortant est désactivé. Pour l'activer, fournissez les détails de votre serveur SMTP en utilisant les paramètres `global.smtp` et `global.email`. Vous pouvez trouver des détails sur ces paramètres dans les [options de ligne de commande](command-line-options.md#outgoing-email-configuration).

Si votre serveur SMTP nécessite une authentification, assurez-vous de lire la section sur la fourniture de votre mot de passe dans la [documentation sur les secrets](secrets.md#smtp-password). Vous pouvez désactiver les paramètres d'authentification avec `--set global.smtp.authentication=""`.

Si votre cluster Kubernetes est sur GKE, sachez que le [port 25 SMTP est bloqué](https://cloud.google.com/compute/docs/tutorials/sending-mail/#using_standard_email_ports).

### E-mail entrant {#incoming-email}

La configuration de l'e-mail entrant est documentée dans le [chart mailroom](../charts/gitlab/mailroom/_index.md#incoming-email).

### E-mail Service Desk {#service-desk-email}

La configuration de l'e-mail entrant est documentée dans le [chart mailroom](../charts/gitlab/mailroom/_index.md#service-desk-email).

### RBAC {#rbac}

Le chart GitLab crée et utilise par défaut le [RBAC](rbac.md). Si votre cluster n'a pas le RBAC activé, vous devez désactiver ces paramètres :

```shell
--set certmanager.rbac.create=false
--set nginx-ingress.rbac.createRole=false
--set prometheus.rbac.create=false
--set gitlab-runner.rbac.create=false
```

## Étapes suivantes {#next-steps}

[Configurez votre fournisseur cloud et créez votre cluster](cloud/_index.md).
