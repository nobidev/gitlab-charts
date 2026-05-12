---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du chart GitLab Shell
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le sous-chart `gitlab-shell` fournit un serveur SSH configuré pour l'accès Git SSH à GitLab.

## Prérequis {#requirements}

Ce chart dépend de l'accès aux services Workhorse, soit dans le cadre du chart GitLab complet, soit fourni en tant que service externe accessible depuis le cluster Kubernetes sur lequel ce chart est déployé.

## Choix de conception {#design-choices}

Afin de prendre facilement en charge les réplicas SSH et d'éviter d'utiliser un stockage partagé pour les clés SSH autorisées, nous utilisons la commande SSH [AuthorizedKeysCommand](https://man.openbsd.org/sshd_config#AuthorizedKeysCommand) pour nous authentifier auprès du point de terminaison des clés autorisées GitLab. Par conséquent, nous ne persistons pas et ne mettons pas à jour le fichier AuthorizedKeys dans ces pods.

## Configuration {#configuration}

Le chart `gitlab-shell` est configuré en deux parties : [services externes](#external-services) et [paramètres du chart](#chart-settings). Le port exposé via Ingress est configuré avec `global.shell.port` et prend la valeur par défaut `22`. Le port externe du service est également contrôlé par `global.shell.port`.

## Options de ligne de commande d'installation {#installation-command-line-options}

| Paramètre                                                | Défaut                                                 | Description |
|----------------------------------------------------------|---------------------------------------------------------|-------------|
| `affinity`                                               | `{}`                                                    | [Règles d'affinité](../_index.md#affinity) pour l'assignation des pods |
| `annotations`                                            |                                                         | Annotations de pod |
| `podLabels`                                              |                                                         | Labels de Pod supplémentaires. Ne sera pas utilisé pour les sélecteurs. |
| `common.labels`                                          |                                                         | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `config.ciphers`                                         | Voir la description.                                        | Spécifier les chiffrements autorisés. Par défaut, les [algorithmes pris en charge par Go](https://pkg.go.dev/golang.org/x/crypto/ssh#SupportedAlgorithms). Pour les builds FIPS, voir les [chiffrements approuvés FIPS](https://gitlab.com/gitlab-org/labkit/-/blob/7bb8cb3b9f0eca4a40744520ee87a696f85c9645/fips/ssh.go#L17-20). |
| `config.kexAlgorithms`                                   | Voir la description.                                        | Spécifie les algorithmes KEX (échange de clés) disponibles. Par défaut, les [algorithmes pris en charge par Go](https://pkg.go.dev/golang.org/x/crypto/ssh#SupportedAlgorithms). Pour les builds FIPS, voir les [algorithmes d'échange de clés approuvés FIPS](https://gitlab.com/gitlab-org/labkit/-/blob/7bb8cb3b9f0eca4a40744520ee87a696f85c9645/fips/ssh.go#L13). |
| `config.macs`                                            | Voir la description.                                        | Spécifie les algorithmes MAC (code d'authentification de message) disponibles. Par défaut, les [algorithmes pris en charge par Go](https://pkg.go.dev/golang.org/x/crypto/ssh#SupportedAlgorithms). Pour les builds FIPS, voir les [MACs approuvés FIPS](https://gitlab.com/gitlab-org/labkit/-/blob/7bb8cb3b9f0eca4a40744520ee87a696f85c9645/fips/ssh.go#L24-27). |
| `config.clientAliveInterval`                             | `0`                                                     | Intervalle entre les pings keepalive sur les connexions autrement inactives ; la valeur par défaut de 0 désactive ce ping |
| `config.loginGraceTime`                                  | `60`                                                    | Spécifie la durée après laquelle le serveur se déconnecte si l'utilisateur ne s'est pas connecté avec succès |
| `config.maxStartups.full`                                | `100`                                                   | La probabilité de refus de SSHd augmentera linéairement et toutes les tentatives de connexion non authentifiées seront refusées lorsque le nombre de connexions non authentifiées atteindra le nombre spécifié |
| `config.maxStartups.rate`                                | `30`                                                    | SSHd refusera les connexions avec la probabilité spécifiée lorsqu'il y aura trop de connexions non authentifiées (facultatif) |
| `config.maxStartups.start`                               | `10`                                                    | SSHd refusera les tentatives de connexion avec une certaine probabilité si le nombre de connexions non authentifiées en cours dépasse le nombre spécifié (facultatif) |
| `config.proxyProtocol`                                   | `false`                                                 | Activer la prise en charge du protocole PROXY pour le daemon `gitlab-sshd` |
| `config.proxyPolicy`                                     | `"use"`                                                 | Spécifier la politique de gestion du protocole PROXY. La valeur doit être l'une des suivantes : `use, require, ignore, reject` |
| `config.proxyHeaderTimeout`                              | `"500ms"`                                               | La durée maximale pendant laquelle `gitlab-sshd` attendra avant d'abandonner la lecture de l'en-tête du protocole PROXY. Doit inclure des unités : `ms`, `s` ou `m`. |
| `config.publicKeyAlgorithms`                             | `[]`                                                    | Liste personnalisée d'algorithmes de clé publique. Si vide, les algorithmes par défaut sont utilisés. |
| `config.gssapi.enabled`                                  | `false`                                                 | Activer la prise en charge GSS-API pour le daemon `gitlab-sshd` |
| `config.gssapi.keytab.secret`                            |                                                         | Le nom d'un secret Kubernetes contenant le keytab pour la méthode d'authentification gssapi-with-mic |
| `config.gssapi.keytab.key`                               | `keytab`                                                | Clé contenant le keytab dans le secret Kubernetes |
| `config.gssapi.krb5Config`                               |                                                         | Contenu du fichier `/etc/krb5.conf` dans le conteneur GitLab Shell |
| `config.gssapi.servicePrincipalName`                     |                                                         | Le nom du service Kerberos à utiliser par le daemon `gitlab-sshd` |
| `config.lfs.pureSSHProtocol`                             | `false`                                                 | Activer la prise en charge du protocole LFS Pure SSH |
| `config.pat.enabled`                                     | `true`                                                  | Activer le jeton d'accès personnel via SSH |
| `config.pat.allowedScopes`                               | `[]`                                                    | Un tableau de portées autorisées pour les jetons d'accès personnels générés avec SSH |
| `config.trustedUserCAKeys.secret`                        |                                                         | Nom d'un secret Kubernetes contenant les clés publiques CA d'utilisateurs de confiance pour l'authentification par certificat SSH au niveau de l'instance. S'applique uniquement lorsque `sshDaemon` est `gitlab-sshd`. |
| `config.trustedUserCAKeys.keys`                          | `[]`                                                    | Liste des noms de clés dans le secret qui contiennent des données de clé publique CA (par exemple, `["ca1.pub", "ca2.pub"]`). Les certificats signés par ces clés CA sont approuvés pour l'authentification, avec le `KeyId` du certificat utilisé comme nom d'utilisateur GitLab. |
| `opensshd.supplemental_config`                           |                                                         | Configuration supplémentaire, ajoutée à `sshd_config`. Alignement strict avec la [page de manuel](https://manpages.debian.org/bookworm/openssh-server/sshd_config.5.en.html) |
| `deployment.livenessProbe.initialDelaySeconds`           | `10`                                                    | Délai avant le lancement de la sonde de vivacité |
| `deployment.livenessProbe.periodSeconds`                 | `10`                                                    | Fréquence d'exécution de la sonde de vivacité |
| `deployment.livenessProbe.timeoutSeconds`                | `3`                                                     | Délai d'expiration de la sonde de vivacité |
| `deployment.livenessProbe.successThreshold`              | `1`                                                     | Nombre minimum de succès consécutifs pour que la sonde de vivacité soit considérée comme réussie après un échec |
| `deployment.livenessProbe.failureThreshold`              | `3`                                                     | Nombre minimum d'échecs consécutifs pour que la sonde de vivacité soit considérée comme échouée après un succès |
| `deployment.readinessProbe.initialDelaySeconds`          | `10`                                                    | Délai avant le lancement de la sonde de disponibilité |
| `deployment.readinessProbe.periodSeconds`                | `5`                                                     | Fréquence d'exécution de la sonde de disponibilité |
| `deployment.readinessProbe.timeoutSeconds`               | `3`                                                     | Délai d'expiration de la sonde de disponibilité |
| `deployment.readinessProbe.successThreshold`             | `1`                                                     | Nombre minimum de succès consécutifs pour que la sonde de disponibilité soit considérée comme réussie après un échec |
| `deployment.readinessProbe.failureThreshold`             | `2`                                                     | Nombre minimum d'échecs consécutifs pour que la sonde de disponibilité soit considérée comme échouée après un succès |
| `deployment.strategy`                                    | `{}`                                                    | Permet de configurer la stratégie de mise à jour utilisée par le déploiement |
| `deployment.terminationGracePeriodSeconds`               | `30`                                                    | Secondes pendant lesquelles Kubernetes attendra qu'un pod se termine de force |
| `enabled`                                                | `true`                                                  | Indicateur d'activation de Shell |
| `extraContainers`                                        |                                                         | Chaîne de style littéral multiligne contenant une liste de conteneurs à inclure |
| `extraInitContainers`                                    |                                                         | Liste de conteneurs init supplémentaires à inclure |
| `extraVolumeMounts`                                      |                                                         | Liste de montages de volumes supplémentaires à effectuer |
| `extraVolumes`                                           |                                                         | Liste de volumes supplémentaires à créer |
| `extraEnv`                                               |                                                         | Liste de variables d'environnement supplémentaires à exposer |
| `extraEnvFrom`                                           |                                                         | Liste des variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| `hpa.behavior`                                           | `{scaleDown: {stabilizationWindowSeconds: 300 }}`       | Behavior contient les spécifications pour le comportement de mise à l'échelle automatique ascendant et descendant (nécessite `autoscaling/v2beta2` ou version supérieure) |
| `hpa.customMetrics`                                      | `[]`                                                    | Les métriques personnalisées contiennent les spécifications à utiliser pour calculer le nombre de réplicas souhaité (remplace l'utilisation par défaut de la consommation CPU moyenne configurée dans `targetAverageUtilization`) |
| `hpa.cpu.targetType`                                     | `AverageValue`                                          | Définit le type cible du CPU pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.cpu.targetAverageValue`                             | `100m`                                                  | Définit la valeur cible CPU pour la mise à l'échelle automatique |
| `hpa.cpu.targetAverageUtilization`                       |                                                         | Définit la consommation cible CPU pour la mise à l'échelle automatique |
| `hpa.memory.targetType`                                  |                                                         | Définit le type cible de la mémoire pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.memory.targetAverageValue`                          |                                                         | Définit la valeur cible mémoire pour la mise à l'échelle automatique |
| `hpa.memory.targetAverageUtilization`                    |                                                         | Définit la consommation cible mémoire pour la mise à l'échelle automatique |
| `hpa.targetAverageValue`                                 |                                                         | **DEPRECATED** Définit la valeur cible CPU pour la mise à l'échelle automatique |
| `image.pullPolicy`                                       | `IfNotPresent`                                          | Politique de récupération de l'image Shell |
| `image.pullSecrets`                                      |                                                         | Secrets pour le dépôt d'images |
| `image.repository`                                       | `registry.gitlab.com/gitlab-org/build/cng/gitlab-shell` | Dépôt d'images Shell |
| `image.tag`                                              | `master`                                                | Tag de l'image Shell |
| `init.image.repository`                                  |                                                         | Image initContainer |
| `init.image.tag`                                         |                                                         | Tag d'image initContainer |
| `init.containerSecurityContext`                          |                                                         | Spécifique à l'initContainer : [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) |
| `init.containerSecurityContext.allowPrivilegeEscalation` | `false`                                                 | Spécifique à initContainer :  Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `init.containerSecurityContext.runAsNonRoot`             | `true`                                                  | Spécifique à initContainer :  Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `init.containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                             | Spécifique à initContainer :  Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur |
| `keda.enabled`                                           | `false`                                                 | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` à la place de `HorizontalPodAutoscalers` |
| `keda.pollingInterval`                                   | `30`                                                    | L'intervalle auquel vérifier chaque déclencheur |
| `keda.cooldownPeriod`                                    | `300`                                                   | La période d'attente après que le dernier déclencheur a signalé une activité avant de remettre la ressource à l'échelle à 0 |
| `keda.minReplicaCount`                                   | `minReplicas`                                           | Nombre minimum de réplicas vers lesquels KEDA peut réduire la ressource. |
| `keda.maxReplicaCount`                                   | `maxReplicas`                                           | Nombre maximum de réplicas vers lesquels KEDA peut augmenter la ressource. |
| `keda.fallback`                                          |                                                         | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `keda.hpaName`                                           | `keda-hpa-{scaled-object-name}`                         | Le nom de la ressource HPA que KEDA créera. |
| `keda.restoreToOriginalReplicaCount`                     |                                                         | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `keda.behavior`                                          | `hpa.behavior`                                          | Les spécifications pour le comportement de mise à l'échelle ascendant et descendant. |
| `keda.triggers`                                          |                                                         | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |
| `logging.format`                                         | `json`                                                  | Définir sur `text` pour des journaux non structurés |
| `logging.sshdLogLevel`                                   | `ERROR`                                                 | Niveau de journalisation du daemon SSH sous-jacent |
| `priorityClassName`                                      |                                                         | [Classe de priorité](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) attribuée aux pods. |
| `replicaCount`                                           | `1`                                                     | Réplicas Shell |
| `serviceLabels`                                          | `{}`                                                    | Labels de service supplémentaires |
| `service.allocateLoadBalancerNodePorts`                  | Non défini, pour utiliser la valeur par défaut de Kubernetes.               | Permet de désactiver l'allocation de NodePort sur le service LoadBalancer, voir la [documentation](https://kubernetes.io/docs/concepts/services-networking/service/#load-balancer-nodeport-allocation) |
| `service.externalTrafficPolicy`                          | `Cluster`                                               | Politique de trafic externe du service Shell (Cluster ou Local) |
| `service.internalPort`                                   | `2222`                                                  | Port interne du Shell |
| `service.nodePort`                                       |                                                         | Définit le nodePort du Shell si défini |
| `service.name`                                           | `gitlab-shell`                                          | Nom du service Shell |
| `service.type`                                           | `ClusterIP`                                             | Type de service Shell |
| `service.loadBalancerIP`                                 |                                                         | Adresse IP à attribuer au LoadBalancer (si pris en charge) |
| `service.loadBalancerSourceRanges`                       |                                                         | Liste des CIDR IP autorisés à accéder au LoadBalancer (si pris en charge) |
| `serviceAccount.annotations`                             | `{}`                                                    | Annotations ServiceAccount |
| `serviceAccount.automountServiceAccountToken`            | `false`                                                 | Indique si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods |
| `serviceAccount.create`                                  | `false`                                                 | Indique si un ServiceAccount doit être créé |
| `serviceAccount.enabled`                                 | `false`                                                 | Indique si un ServiceAccount doit être utilisé |
| `serviceAccount.name`                                    |                                                         | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé |
| `securityContext.fsGroup`                                | `1000`                                                  | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.runAsUser`                              | `1000`                                                  | ID utilisateur sous lequel le pod doit être démarré |
| `securityContext.fsGroupChangePolicy`                    |                                                         | Politique de modification de la propriété et des permissions du volume (nécessite Kubernetes 1.23) |
| `securityContext.seccompProfile.type`                    | `RuntimeDefault`                                        | Profil Seccomp à utiliser |
| `containerSecurityContext`                               |                                                         | Remplace le [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel le conteneur est démarré |
| `containerSecurityContext.runAsUser`                     | `1000`                                                  | Permet de remplacer le contexte de sécurité spécifique sous lequel le conteneur est démarré |
| `containerSecurityContext.allowPrivilegeEscalation`      | `false`                                                 | Contrôle si un processus du conteneur peut obtenir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`                  | `true`                                                  | Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `containerSecurityContext.capabilities.drop`             | `[ "ALL" ]`                                             | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) pour le conteneur Gitaly |
| `sshDaemon`                                              | `openssh`                                               | Sélectionne le daemon SSH à exécuter, valeurs possibles (`openssh`, `gitlab-sshd`) |
| `tolerations`                                            | `[]`                                                    | Labels de tolérance pour l'affectation des pods |
| `traefik.entrypoint`                                     | `gitlab-shell`                                          | Lors de l'utilisation de traefik, le point d'entrée traefik à utiliser pour GitLab Shell. Par défaut : `gitlab-shell` |
| `traefik.tcpAnnotations`                                 | `{}`                                                    | Lors de l'utilisation de traefik, les annotations à ajouter à la ressource IngressRouteTCP. Aucune annotation par défaut |
| `traefik.tcpMiddlewares`                                 | `[]`                                                    | Lors de l'utilisation de traefik, les middlewares TCP à ajouter à la ressource IngressRouteTCP. Aucun middleware par défaut |
| `workhorse.serviceName`                                  | `webservice`                                            | Nom du service Workhorse (par défaut, Workhorse fait partie des pods / du service webservice) |
| `metrics.enabled`                                        | `false`                                                 | Indique si un point de terminaison de métriques doit être disponible pour le scraping (nécessite `sshDaemon=gitlab-sshd`). |
| `metrics.port`                                           | `9122`                                                  | Port de l'endpoint de métriques |
| `metrics.path`                                           | `/metrics`                                              | Chemin de l'endpoint de métriques |
| `metrics.serviceMonitor.enabled`                         | `false`                                                 | Indique si un ServiceMonitor doit être créé pour permettre à l'opérateur Prometheus de gérer le scraping des métriques ; notez que l'activation de cette option supprime les annotations de scraping `prometheus.io` |
| `metrics.serviceMonitor.additionalLabels`                | `{}`                                                    | Labels supplémentaires à ajouter au ServiceMonitor |
| `metrics.serviceMonitor.endpointConfig`                  | `{}`                                                    | Configuration d'endpoint supplémentaire pour le ServiceMonitor |
| `metrics.annotations`                                    |                                                         | **DEPRECATED** Définit des annotations de métriques explicites. Remplacé par le contenu du template. |

## Exemples de configuration du chart {#chart-configuration-examples}

### extraEnv {#extraenv}

`extraEnv` vous permet d'exposer des variables d'environnement supplémentaires dans tous les conteneurs des pods.

Voici un exemple d'utilisation de `extraEnv` :

```yaml
extraEnv:
  SOME_KEY: some_value
  SOME_OTHER_KEY: some_other_value
```

Lorsque le conteneur est démarré, vous pouvez confirmer que les variables d'environnement sont exposées :

```shell
env | grep SOME
SOME_KEY=some_value
SOME_OTHER_KEY=some_other_value
```

### extraEnvFrom {#extraenvfrom}

`extraEnvFrom` vous permet d'exposer des variables d'environnement supplémentaires provenant d'autres sources de données dans tous les conteneurs des pods.

Voici un exemple d'utilisation de `extraEnvFrom` :

```yaml
extraEnvFrom:
  MY_NODE_NAME:
    fieldRef:
      fieldPath: spec.nodeName
  MY_CPU_REQUEST:
    resourceFieldRef:
      containerName: test-container
      resource: requests.cpu
  SECRET_THING:
    secretKeyRef:
      name: special-secret
      key: special_token
      # optional: boolean
  CONFIG_STRING:
    configMapKeyRef:
      name: useful-config
      key: some-string
      # optional: boolean
```

### image.pullSecrets {#imagepullsecrets}

`pullSecrets` vous permet de vous authentifier auprès d'un registre privé pour extraire des images pour un pod.

Des informations supplémentaires sur les registres privés et leurs méthodes d'authentification sont disponibles dans [la documentation Kubernetes](https://kubernetes.io/docs/concepts/containers/images/#specifying-imagepullsecrets-on-a-pod).

Voici un exemple d'utilisation de `pullSecrets` :

```yaml
image:
  repository: my.shell.repository
  tag: latest
  pullPolicy: Always
  pullSecrets:
  - name: my-secret-name
  - name: my-secondary-secret-name
```

### serviceAccount {#serviceaccount}

Cette section contrôle si un ServiceAccount doit être créé et si le jeton d'accès par défaut doit être monté dans les pods.

| Nom                           |  Type   | Défaut | Description |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   Map   | `{}`    | Annotations ServiceAccount. |
| `automountServiceAccountToken` | Boolean | `false` | Contrôle si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods. Vous ne devez pas activer cette option, sauf si elle est requise par certains sidecars pour fonctionner correctement (par exemple, Istio). |
| `create`                       | Boolean | `false` | Indique si un ServiceAccount doit être créé. |
| `enabled`                      | Boolean | `false` | Indique si un ServiceAccount doit être utilisé. |
| `name`                         | String  |         | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé. |

### livenessProbe/readinessProbe {#livenessprobereadinessprobe}

`deployment.livenessProbe` et `deployment.readinessProbe` fournissent un mécanisme pour aider à contrôler la terminaison des pods dans certains scénarios.

Les dépôts plus volumineux bénéficient d'un ajustement des délais des sondes de vivacité et de disponibilité pour correspondre à leurs connexions durables habituelles. Définissez une durée de sonde de disponibilité inférieure à la durée de sonde de vivacité pour minimiser les interruptions potentielles lors des opérations `clone` et `push`. Augmentez `terminationGracePeriodSeconds` et donnez à ces opérations plus de temps avant que le planificateur ne termine le pod. Considérez l'exemple ci-dessous comme point de départ pour ajuster les pods GitLab Shell afin d'améliorer la stabilité et l'efficacité avec des charges de travail de dépôt plus importantes.

```yaml
deployment:
  livenessProbe:
    initialDelaySeconds: 10
    periodSeconds: 20
    timeoutSeconds: 3
    successThreshold: 1
    failureThreshold: 10
  readinessProbe:
    initialDelaySeconds: 10
    periodSeconds: 5
    timeoutSeconds: 2
    successThreshold: 1
    failureThreshold: 3
  terminationGracePeriodSeconds: 300
```

Consultez la [documentation officielle de Kubernetes](https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/) pour plus de détails sur cette configuration.

### tolerations {#tolerations}

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

### affinity {#affinity}

Pour plus d'informations, consultez [`affinity`](../_index.md#affinity).

### annotations {#annotations}

`annotations` vous permet d'ajouter des annotations aux pods GitLab Shell.

Voici un exemple d'utilisation de `annotations`

```yaml
annotations:
  kubernetes.io/example-annotation: annotation-value
```

## Services externes {#external-services}

Ce chart doit être attaché au service Workhorse.

### Workhorse {#workhorse}

```yaml
workhorse:
  host: workhorse.example.com
  serviceName: webservice
  port: 8181
```

| Nom          |  Type   | Défaut      | Description |
|:--------------|:-------:|:-------------|:------------|
| `host`        | String  |              | Le nom d'hôte du serveur Workhorse. Cela peut être omis au profit de `serviceName`. |
| `port`        | Integer | `8181`       | Le port sur lequel se connecter au serveur Workhorse. |
| `serviceName` | String  | `webservice` | Le nom du `service` qui opère le serveur Workhorse. Par défaut, Workhorse fait partie des pods / du service webservice. Si cet attribut est présent et que `host` ne l'est pas, le chart créera le modèle du nom d'hôte du service (et du `.Release.Name` actuel) à la place de la valeur `host`. Cela est pratique lorsque Workhorse est utilisé dans le cadre du chart GitLab global. |

## Paramètres du chart {#chart-settings}

Les valeurs suivantes sont utilisées pour configurer les pods GitLab Shell.

### hostKeys.secret {#hostkeyssecret}

Le nom du `secret` Kubernetes à partir duquel récupérer les clés d'hôte SSH. Les clés dans le secret doivent commencer par les noms de clés `ssh_host_` pour être utilisées par GitLab Shell.

### authToken {#authtoken}

GitLab Shell utilise un jeton d'authentification dans sa communication avec Workhorse. Partagez le jeton entre GitLab Shell et Workhorse à l'aide d'un secret partagé.

```yaml
authToken:
 secret: gitlab-shell-secret
 key: secret
```

| Nom               |  Type  | Défaut | Description |
|:-------------------|:------:|:--------|:------------|
| `authToken.key`    | String |         | Le nom de la clé dans le secret ci-dessus qui contient le jeton d'authentification. |
| `authToken.secret` | String |         | Le nom du `Secret` Kubernetes à partir duquel extraire les données. |

### Service LoadBalancer {#loadbalancer-service}

Si `service.type` est défini sur `LoadBalancer`, vous pouvez éventuellement spécifier `service.loadBalancerIP` pour créer le `LoadBalancer` avec une IP spécifiée par l'utilisateur (si votre fournisseur cloud le prend en charge).

Vous pouvez également éventuellement spécifier une liste de `service.loadBalancerSourceRanges` pour restreindre les plages CIDR pouvant accéder au `LoadBalancer` (si votre fournisseur cloud le prend en charge).

Des informations supplémentaires sur le type de service `LoadBalancer` sont disponibles dans [la documentation Kubernetes](https://kubernetes.io/docs/concepts/services-networking/#loadbalancer)

```yaml
service:
  type: LoadBalancer
  loadBalancerIP: 1.2.3.4
  loadBalancerSourceRanges:
  - 5.6.7.8/32
  - 10.0.0.0/8
```

### Configuration supplémentaire OpenSSH {#openssh-supplemental-configuration}

Lors de l'utilisation du `sshd` d'OpenSSH (via `.sshDaemon: openssh`), il est possible de fournir une configuration supplémentaire de deux façons : `.opensshd.supplemental_config` et en montant des extraits de configuration dans `/etc/ssh/sshd_config.d/*.conf`.

Toute configuration fournie _doit_ satisfaire aux exigences fonctionnelles de `sshd_config`. Assurez-vous de lire la [page de manuel](https://man.openbsd.org/sshd_config).

#### opensshd.supplemental_config {#opensshdsupplemental_config}

Le contenu de `.opensshd.supplemental_config` sera directement placé à la fin du fichier `sshd_config` dans le conteneur. Cette valeur doit être une chaîne multiligne.

Exemple : activation des anciens clients utilisant les algorithmes d'échange de clés `ssh-rsa`. Notez que l'activation d'algorithmes dépréciés, tels que `ssh-rsa`, crée des [vulnérabilités de sécurité importantes](https://www.openssh.com/txt/release-8.8). La probabilité d'exploitation est **significantly amplified** sur les instances GitLab exposées publiquement avec ces modifications.

```yaml
opensshd:
    supplemental_config: |-
      HostKeyAlgorithms +ssh-rsa,ssh-rsa-cert-v01@openssh.com
      PubkeyAcceptedAlgorithms +ssh-rsa,ssh-rsa-cert-v01@openssh.com
      CASignatureAlgorithms +ssh-rsa
```

#### sshd_config.d {#sshd_configd}

Vous pouvez fournir des extraits de configuration complets à `sshd` en montant du contenu dans `/etc/ssh/sshd_config.d`, avec les fichiers correspondant à `*.conf`. Notez que ceux-ci sont inclus _après_ la configuration par défaut requise pour que l'application fonctionne dans le conteneur et dans le chart. Ces valeurs _ne remplaceront pas_ le contenu de `sshd_config`, mais les étendront.

Exemple : montage d'un seul élément d'une ConfigMap dans le conteneur via `extraVolumes` et `extraVolumeMounts` :

```yaml
extraVolumes: |
  - name: gitlab-sshdconfig-extra
    configMap:
      name: gitlab-sshdconfig-extra

extraVolumeMounts: |
  - name: gitlab-sshdconfig-extra
    mountPath: /etc/ssh/sshd_config.d/extra.conf
    subPath: extra.conf
```

### Certificats SSH au niveau de l'instance (`gitlab-sshd`) {#instance-level-ssh-certificates-gitlab-sshd}

Lors de l'utilisation de `gitlab-sshd` (via `sshDaemon: gitlab-sshd`), vous pouvez configurer l'authentification par certificat SSH au niveau de l'instance à l'aide de clés CA de confiance. Pour une vue d'ensemble complète, incluant la génération de clés CA, l'émission de certificats, les considérations de sécurité et le dépannage, voir [Certificats SSH au niveau de l'instance avec `gitlab-sshd`](https://docs.gitlab.com/administration/operations/gitlab_sshd_ssh_certificates/).

Pour configurer le chart :

1. Créez un secret Kubernetes contenant une ou plusieurs clés publiques CA :

   ```shell
   kubectl create secret generic my-ssh-ca-keys --from-file=ca.pub=ssh_user_ca.pub
   ```

1. Définissez les valeurs Helm pour référencer le secret :

   ```yaml
   gitlab:
     gitlab-shell:
       sshDaemon: gitlab-sshd
        config:
          trustedUserCAKeys:
            secret: my-ssh-ca-keys
            keys:
              - ca.pub
   ```

   Le champ `secret` est le nom du secret Kubernetes. Le champ `keys` liste les noms de clés dans ce secret qui contiennent des données de clé publique CA. Chaque clé est montée et transmise à `gitlab-sshd` en tant que chemin de fichier `trusted_user_ca_keys`.

### Configuration de `networkpolicy` {#configuring-the-networkpolicy}

Cette section contrôle la [NetworkPolicy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). Cette configuration est facultative et est utilisée pour limiter l'Egress et l'Ingress des pods à des endpoints spécifiques.

| Nom              |  Type   | Défaut | Description |
|:------------------|:-------:|:--------|:------------|
| `enabled`         | Boolean | `false` | Ce paramètre active la `NetworkPolicy` |
| `ingress.enabled` | Boolean | `false` | Lorsque défini sur `true`, la politique réseau `Ingress` sera activée. Cela bloquera toutes les connexions Ingress sauf si des règles sont spécifiées. |
| `ingress.rules`   |  Tableau  | `[]`    | Règles pour la politique Ingress, pour plus de détails voir <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> et l'exemple ci-dessous |
| `egress.enabled`  | Boolean | `false` | Lorsque défini sur `true`, la politique réseau `Egress` sera activée. Cela bloquera toutes les connexions egress sauf si des règles sont spécifiées. |
| `egress.rules`    |  Tableau  | `[]`    | Règles pour la politique egress, pour plus de détails voir <https://kubernetes.io/docs/concepts/services-networking/network-policies/#the-networkpolicy-resource> et l'exemple ci-dessous |

### Exemple de politique réseau {#example-network-policy}

Le service `gitlab-shell` nécessite des connexions Ingress sur le port 22 et des connexions Egress vers le port workhorse par défaut 8181. Cet exemple ajoute la politique réseau suivante :

- Autorise les requêtes Ingress :
  - Du pod `nginx-ingress` vers le port `2222`
  - Du pod `prometheus` vers le port `9122`

    L'accès depuis `prometheus` vers le port `9122` n'est nécessaire que lorsque le daemon SSH est défini sur `gitlab-sshd`

- Autorise les requêtes Egress :
  - Vers le pod `webservice` sur le port `8181`
  - Vers le pod `gitaly` sur le port `8075`

L'exemple fourni n'est qu'un exemple et peut ne pas être complet. L'exemple est basé sur l'hypothèse que `kube-dns` a été déployé dans l'espace de nommage `kube-system`, `prometheus` a été déployé dans l'espace de nommage `monitoring` et `nginx-ingress` a été déployé dans l'espace de nommage `nginx-ingress`.

```yaml
networkpolicy:
  enabled: true
  ingress:
    enabled: true
    rules:
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: nginx-ingress
            podSelector:
              matchLabels:
                app: nginx-ingress
                component: controller
        ports:
          - port: 2222
      - from:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: monitoring
            podSelector:
              matchLabels:
                app: prometheus
                component: server
                release: gitlab
        ports:
          - port: 9122
  egress:
    enabled: true
    rules:
      - to:
          - podSelector:
              matchLabels:
                app: gitaly
        ports:
          - port: 8075
      - to:
          - podSelector:
              matchLabels:
                app: webservice
        ports:
          - port: 8181
      - to:
          - namespaceSelector:
              matchLabels:
                kubernetes.io/metadata.name: kube-system
            podSelector:
              matchLabels:
                k8s-app: kube-dns
        ports:
          - port: 53
            protocol: UDP
```

## Configuration de KEDA {#configuring-keda}

Cette section `keda` active l'installation de [KEDA](https://keda.sh/) `ScaledObjects` à la place des `HorizontalPodAutoscalers` classiques. Cette configuration est facultative et peut être utilisée lorsqu'il est nécessaire d'effectuer une mise à l'échelle automatique basée sur des métriques personnalisées ou externes.

La plupart des paramètres utilisent par défaut les valeurs définies dans la section `hpa` le cas échéant.

Si les conditions suivantes sont remplies, des déclencheurs CPU et mémoire sont ajoutés automatiquement en fonction des seuils CPU et mémoire définis dans la section `hpa` :

- `triggers` n'est pas défini.
- Le paramètre `request.cpu.request` ou `request.memory.request` correspondant est également défini sur une valeur non nulle.

Si aucun déclencheur n'est défini, le `ScaledObject` n'est pas créé.

Consultez la [documentation KEDA](https://keda.sh/docs/2.10/concepts/scaling-deployments/) pour plus de détails sur ces paramètres.

| Nom                            |  Type   | Défaut                         | Description |
|:--------------------------------|:-------:|:--------------------------------|:------------|
| `enabled`                       | Boolean | `false`                         | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` à la place de `HorizontalPodAutoscalers` |
| `pollingInterval`               | Integer | `30`                            | L'intervalle auquel vérifier chaque déclencheur |
| `cooldownPeriod`                | Integer | `300`                           | La période d'attente après que le dernier déclencheur a signalé une activité avant de remettre la ressource à l'échelle à 0 |
| `minReplicaCount`               | Integer | `minReplicas`                   | Nombre minimum de réplicas vers lesquels KEDA peut réduire la ressource. |
| `maxReplicaCount`               | Integer | `maxReplicas`                   | Nombre maximum de réplicas vers lesquels KEDA peut augmenter la ressource. |
| `fallback`                      |   Map   |                                 | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `hpaName`                       | String  | `keda-hpa-{scaled-object-name}` | Le nom de la ressource HPA que KEDA créera. |
| `restoreToOriginalReplicaCount` | Boolean |                                 | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `behavior`                      |   Map   | `hpa.behavior`                  | Les spécifications pour le comportement de mise à l'échelle ascendant et descendant. |
| `triggers`                      |  Tableau  |                                 | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |

Voir [`examples/keda/gitlab-shell.yml`](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/keda/gitlab-shell.yml) pour un exemple d'utilisation de `keda`.
