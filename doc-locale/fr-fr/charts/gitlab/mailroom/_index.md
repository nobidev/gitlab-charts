---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du chart Mailroom
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Le chart Mailroom gère les [e-mails entrants](https://docs.gitlab.com/administration/incoming_email/).

## Configuration {#configuration}

```yaml
image:
  repository: registry.gitlab.com/gitlab-org/build/cng/gitlab-mailroom
  # tag: v0.9.1
  pullSecrets: []
  # pullPolicy: IfNotPresent

enabled: true

init:
  image: {}
    # repository:
    # tag:
  resources:
    requests:
      cpu: 50m

annotations: {}

# Tolerations for pod scheduling
tolerations: []
affinity: {}
podLabels: {}

hpa:
  minReplicas: 1
  maxReplicas: 2
  cpu:
    targetAverageUtilization: 75

  # Note that the HPA is limited to autoscaling/v2beta1, autoscaling/v2beta2 and autoscaling/v2
  customMetrics: []
  behavior: {}

networkpolicy:
  enabled: false
  egress:
    enabled: false
    rules: []
  ingress:
    enabled: false
    rules: []
  annotations: {}

resources:
  # limits:
  #  cpu: 1
  #  memory: 2G
  requests:
    cpu: 50m
    memory: 150M

## Allow to overwrite under which User and Group we're running.
securityContext:
  runAsUser: 1000
  fsGroup: 1000

## Enable deployment to use a serviceAccount
serviceAccount:
  enabled: false
  create: false
  annotations: {}
  ## Name to be used for serviceAccount, otherwise defaults to chart fullname
  # name:
```

| Paramètre                                     | Défaut                                                    | Description |
|-----------------------------------------------|------------------------------------------------------------|-------------|
| `affinity`                                    | `{}`                                                       | [Règles d'affinité](../_index.md#affinity) pour l'assignation des pods |
| `annotations`                                 | `{}`                                                       | Annotations du pod. |
| `deployment.strategy`                         | `{}`                                                       | Permet de configurer la stratégie de mise à jour utilisée par le déploiement |
| `enabled`                                     | `true`                                                     | Indicateur d'activation de Mailroom |
| `hpa.behavior`                                | `{scaleDown: {stabilizationWindowSeconds: 300 }}`          | Behavior contient les spécifications pour le comportement de mise à l'échelle automatique ascendant et descendant (nécessite `autoscaling/v2beta2` ou version supérieure) |
| `hpa.customMetrics`                           | `[]`                                                       | Les métriques personnalisées contiennent les spécifications à utiliser pour calculer le nombre de réplicas souhaité (remplace l'utilisation par défaut de la consommation CPU moyenne configurée dans `targetAverageUtilization`) |
| `hpa.cpu.targetType`                          | `Utilization`                                              | Définit le type cible du CPU pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.cpu.targetAverageValue`                  |                                                            | Définit la valeur cible CPU pour la mise à l'échelle automatique |
| `hpa.cpu.targetAverageUtilization`            | `75`                                                       | Définit la consommation cible CPU pour la mise à l'échelle automatique |
| `hpa.memory.targetType`                       |                                                            | Définit le type cible de la mémoire pour la mise à l’échelle automatique. La valeur doit être `Utilization` ou `AverageValue` |
| `hpa.memory.targetAverageValue`               |                                                            | Définit la valeur cible mémoire pour la mise à l'échelle automatique |
| `hpa.memory.targetAverageUtilization`         |                                                            | Définit la consommation cible mémoire pour la mise à l'échelle automatique |
| `hpa.maxReplicas`                             | `2`                                                        | Nombre maximum de réplicas |
| `hpa.minReplicas`                             | `1`                                                        | Nombre minimum de réplicas |
| `image.pullPolicy`                            | `IfNotPresent`                                             | Politique de récupération de l'image Mailroom |
| `extraEnvFrom`                                |                                                            | Liste des variables d'environnement supplémentaires provenant d'autres sources de données à exposer |
| `image.pullSecrets`                           |                                                            | Secrets de récupération de l'image Mailroom |
| `image.registry`                              |                                                            | Registre d'images Mailroom |
| `image.repository`                            | `registry.gitlab.com/gitlab-org/build/cng/gitlab-mailroom` | Dépôt d'images Mailroom |
| `image.tag`                                   |                                                            | Tag de l'image Mailroom |
| `init.image.repository`                       |                                                            | Dépôt d'images init Mailroom |
| `init.image.tag`                              |                                                            | Tag de l'image init Mailroom |
| `init.resources`                              | `{ requests: { cpu: 50m }}`                                | Exigences en ressources du conteneur init Mailroom |
| `init.containerSecurityContext`               |                                                            | [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) spécifique au conteneur initContainer |
| `keda.enabled`                                | `false`                                                    | Utiliser [KEDA](https://keda.sh/) `ScaledObjects` à la place de `HorizontalPodAutoscalers` |
| `keda.pollingInterval`                        | `30`                                                       | L'intervalle auquel vérifier chaque déclencheur |
| `keda.cooldownPeriod`                         | `300`                                                      | La période d'attente après que le dernier déclencheur a signalé une activité avant de remettre la ressource à l'échelle à 0 |
| `keda.minReplicaCount`                        | `hpa.minReplicas`                                          | Nombre minimum de réplicas vers lesquels KEDA peut réduire la ressource. |
| `keda.maxReplicaCount`                        | `hpa.maxReplicas`                                          | Nombre maximum de réplicas vers lesquels KEDA peut augmenter la ressource. |
| `keda.fallback`                               |                                                            | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `keda.hpaName`                                | `keda-hpa-{scaled-object-name}`                            | Le nom de la ressource HPA que KEDA créera. |
| `keda.restoreToOriginalReplicaCount`          |                                                            | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `keda.behavior`                               | `hpa.behavior`                                             | Les spécifications pour le comportement de mise à l'échelle ascendant et descendant. |
| `keda.triggers`                               |                                                            | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |
| `podLabels`                                   | `{}`                                                       | Labels pour les pods Mailroom en cours d'exécution |
| `common.labels`                               | `{}`                                                       | Labels supplémentaires appliqués à tous les objets créés par ce chart. |
| `resources`                                   | `{ requests: { cpu: 50m, memory: 150M }}`                  | Exigences en ressources de Mailroom |
| `networkpolicy.annotations`                   | `{}`                                                       | Annotations à ajouter à la NetworkPolicy |
| `networkpolicy.egress.enabled`                | `false`                                                    | Indicateur pour activer les règles egress de NetworkPolicy |
| `networkpolicy.egress.rules`                  | `[]`                                                       | Définir une liste de règles egress pour NetworkPolicy |
| `networkpolicy.enabled`                       | `false`                                                    | Indicateur pour l'utilisation de NetworkPolicy |
| `networkpolicy.ingress.enabled`               | `false`                                                    | Indicateur pour activer les règles `ingress` de NetworkPolicy |
| `networkpolicy.ingress.rules`                 | `[]`                                                       | Définir une liste de règles `ingress` pour NetworkPolicy |
| `securityContext.fsGroup`                     | `1000`                                                     | ID de groupe sous lequel le pod doit être démarré |
| `securityContext.runAsUser`                   | `1000`                                                     | ID utilisateur sous lequel le pod doit être démarré |
| `securityContext.fsGroupChangePolicy`         |                                                            | Politique de modification de la propriété et des permissions du volume (nécessite Kubernetes 1.23) |
| `containerSecurityContext`                    |                                                            | Remplace le [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel le conteneur est démarré |
| `containerSecurityContext.runAsUser`          | `1000`                                                     | Permet de remplacer le contexte de sécurité spécifique sous lequel le conteneur est démarré |
| `serviceAccount.annotations`                  | `{}`                                                       | Annotations pour le ServiceAccount |
| `serviceAccount.automountServiceAccountToken` | `false`                                                    | Indique si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods |
| `serviceAccount.enabled`                      | `false`                                                    | Indique si un ServiceAccount doit être utilisé |
| `serviceAccount.create`                       | `false`                                                    | Indique si un ServiceAccount doit être créé |
| `serviceAccount.name`                         |                                                            | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé |
| `tolerations`                                 |                                                            | Tolerations à ajouter à Mailroom |
| `priorityClassName`                           |                                                            | [Classe de priorité](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) attribuée aux pods. |

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
| `minReplicaCount`               | Integer | `hpa.minReplicas`               | Nombre minimum de réplicas vers lesquels KEDA peut réduire la ressource. |
| `maxReplicaCount`               | Integer | `hpa.maxReplicas`               | Nombre maximum de réplicas vers lesquels KEDA peut augmenter la ressource. |
| `fallback`                      |   Map   |                                 | Configuration de repli KEDA, voir la [documentation](https://keda.sh/docs/2.10/concepts/scaling-deployments/#fallback) |
| `hpaName`                       | String  | `keda-hpa-{scaled-object-name}` | Le nom de la ressource HPA que KEDA créera. |
| `restoreToOriginalReplicaCount` | Boolean |                                 | Indique si la ressource cible doit être ramenée au nombre de réplicas d'origine après la suppression du `ScaledObject` |
| `behavior`                      |   Map   | `hpa.behavior`                  | Les spécifications pour le comportement de mise à l'échelle ascendant et descendant. |
| `triggers`                      |  Tableau  |                                 | Liste des déclencheurs pour activer la mise à l'échelle de la ressource cible, par défaut les déclencheurs calculés à partir de `hpa.cpu` et `hpa.memory` |

## E-mail entrant {#incoming-email}

Par défaut, les e-mails entrants sont désactivés. Il existe deux méthodes pour lire les e-mails entrants :

- [IMAP](#imap)
- [Microsoft Graph](#microsoft-graph)

Commencez par l'activer en définissant les [paramètres communs](../../../installation/command-line-options.md#common-settings). Configurez ensuite les [paramètres IMAP](../../../installation/command-line-options.md#imap-settings) ou les [paramètres Microsoft Graph](../../../installation/command-line-options.md#microsoft-graph-settings).

Ces méthodes peuvent être configurées dans `values.yaml`. Consultez les exemples suivants :

- [E-mail entrant avec IMAP](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-incoming-email.yaml)
- [E-mail entrant avec Microsoft Graph](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-msgraph.yaml)

### IMAP {#imap}

Pour activer les e-mails entrants via IMAP, fournissez les détails de votre serveur IMAP et les identifiants d'accès en utilisant les paramètres `global.appConfig.incomingEmail`.

De plus, les [exigences relatives au compte e-mail IMAP](https://docs.gitlab.com/administration/incoming_email/) doivent être examinées pour s'assurer que le compte IMAP ciblé peut être utilisé par GitLab pour recevoir des e-mails. Plusieurs services de messagerie courants sont également documentés sur la même page pour faciliter la configuration des e-mails entrants.

Le mot de passe IMAP devra toujours être créé en tant que Secret Kubernetes, comme décrit dans le [guide des secrets](../../../installation/secrets.md#imap-password-for-incoming-emails).

### Microsoft Graph {#microsoft-graph}

Consultez la [documentation GitLab sur la création d'une application Azure Active Directory](https://docs.gitlab.com/administration/incoming_email/#microsoft-graph).

Fournissez l'ID du tenant, l'ID du client et le secret client. Vous pouvez trouver des détails sur ces paramètres dans les [options de ligne de commande](../../../installation/command-line-options.md#incoming-email-configuration).

Créez un secret Kubernetes contenant le secret client comme décrit dans le [guide des secrets](../../../installation/secrets.md#microsoft-graph-client-secret-for-incoming-emails).

### Répondre par e-mail {#reply-by-email}

Pour utiliser la fonctionnalité de réponse par e-mail, permettant aux utilisateurs de répondre aux e-mails de notification pour commenter les tickets et les MR, vous devez configurer à la fois les paramètres d'[e-mail sortant](../../../installation/command-line-options.md#outgoing-email-configuration) et les paramètres d'e-mail entrant.

### E-mail Service Desk {#service-desk-email}

Par défaut, l'e-mail Service Desk est désactivé.

Comme pour les e-mails entrants, activez-le en définissant les [paramètres communs](../../../installation/command-line-options.md#common-settings-1). Configurez ensuite les [paramètres IMAP](../../../installation/command-line-options.md#imap-settings-1) ou les [paramètres Microsoft Graph](../../../installation/command-line-options.md#microsoft-graph-settings-1).

Ces options peuvent également être configurées dans `values.yaml`. Consultez les exemples suivants :

- [Service Desk avec IMAP](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-service-desk-email.yaml)
- [Service Desk avec Microsoft Graph](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/email/values-msgraph.yaml)

L'e-mail Service Desk _nécessite_ que les [e-mails entrants](#incoming-email) soient configurés.

#### IMAP {#imap-1}

Fournissez les détails de votre serveur IMAP et les identifiants d'accès en utilisant les paramètres `global.appConfig.serviceDeskEmail`. Vous pouvez trouver des détails sur ces paramètres dans les [options de ligne de commande](../../../installation/command-line-options.md#service-desk-email-configuration).

Créez un secret Kubernetes contenant le mot de passe IMAP comme décrit dans le [guide des secrets](../../../installation/secrets.md#imap-password-for-service-desk-emails).

#### Microsoft Graph {#microsoft-graph-1}

Consultez la [documentation GitLab sur la création d'une application Azure Active Directory](https://docs.gitlab.com/administration/incoming_email/#microsoft-graph).

Fournissez l'ID du tenant, l'ID du client et le secret client en utilisant les paramètres `global.appConfig.serviceDeskEmail`. Vous pouvez trouver des détails sur ces paramètres dans les [options de ligne de commande](../../../installation/command-line-options.md#service-desk-email-configuration).

Vous devrez également créer un secret Kubernetes contenant le secret client comme décrit dans le [guide des secrets](../../../installation/secrets.md#imap-password-for-service-desk-emails).

### serviceAccount {#serviceaccount}

Cette section contrôle si un ServiceAccount doit être créé et si le jeton d'accès par défaut doit être monté dans les pods.

| Nom                           |  Type   | Défaut | Description |
|:-------------------------------|:-------:|:--------|:------------|
| `annotations`                  |   Map   | `{}`    | Annotations ServiceAccount. |
| `automountServiceAccountToken` | Boolean | `false` | Contrôle si le jeton d'accès par défaut du ServiceAccount doit être monté dans les pods. Vous ne devez pas activer cette option, sauf si elle est requise par certains sidecars pour fonctionner correctement (par exemple, Istio). |
| `create`                       | Boolean | `false` | Indique si un ServiceAccount doit être créé. |
| `enabled`                      | Boolean | `false` | Indique si un ServiceAccount doit être utilisé. |
| `name`                         | String  |         | Nom du ServiceAccount. Si non défini, le nom complet du chart est utilisé. |

### affinity {#affinity}

Pour plus d'informations, consultez [`affinity`](../_index.md#affinity).
