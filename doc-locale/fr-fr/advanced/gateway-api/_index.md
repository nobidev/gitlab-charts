---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer les extensions Gateway API et Envoy Gateway
---

Le chart GitLab prend en charge Gateway API et intègre [Envoy Gateway](https://gateway.envoyproxy.io/) comme l'un des fournisseurs disponibles. Depuis GitLab 19.0, le chart GitLab utilise par défaut Gateway API avec le chart Envoy Gateway intégré. NGINX Ingress est déprécié mais reste disponible jusqu'à sa suppression complète dans GitLab 20.0.

## Configuration globale {#global-configuration}

| Nom                                                |  Type   | Défaut        | Description |
|:----------------------------------------------------|:-------:|:---------------|:------------|
| `global.gatewayApi.enabled`                         | Boolean | true           | Activer le déploiement des ressources GatewayAPI. Valeur par défaut basculée à `true` dans GitLab 19.0. |
| `global.gatewayApi.configureCertmanager`            | Boolean | true           | Configurer cert-manager pour obtenir des certificats depuis Let's Encrypt via un solveur Gateway API HTTP-01. Nécessite `certmanager-issuer.email`. |
| `global.gatewayApi.gatewayRef.name`                 | String  |                | Nom du Gateway rendu à toutes les ressources Gateway API. Utilisez ceci pour référencer un Gateway géré en externe et pour désactiver le Gateway fourni par le chart. |
| `global.gatewayApi.gatewayRef.namespace`            | String  |                | Espace de nommage du Gateway rendu à toutes les ressources Gateway API. Utilisez ceci pour référencer un Gateway géré en externe dans un autre espace de nommage et pour désactiver le Gateway fourni par le chart. |
| `global.gatewayApi.httpToHttpsRedirect`             | Boolean | true           | Créer un HTTPRoute qui redirige tout le trafic HTTP vers HTTPS avec un code de statut 301. Effectif uniquement lorsque `protocol` est `HTTPS` et que le Gateway est géré (sans `gatewayRef`). |
| `global.gatewayApi.installEnvoy`                    | Boolean | true           | Installer le sous-chart Envoy Gateway et configurer un `GatewayClass` et des [extensions Envoy Gateway API](../../charts/envoygateway/_index.md). Valeur par défaut basculée à `true` dans GitLab 19.0. |

### Configuration des ressources Gateway API gérées {#configuring-managed-gateway-api-resources}

Le chart GitLab vous permet de personnaliser le `Gateway`, le `GatewayClass` et les extensions Envoy Gateway gérés.

| Nom                           |  Type   | Défaut        | Description |
|:-------------------------------|:-------:|:---------------|:------------|
| `gatewayApiResources.class.name`                   | String  | `gitlab-gw`    | Nom de la classe de Gateway liée au Gateway. |
| `gatewayApiResources.class.controllerName`         | String  | `gateway.envoyproxy.io/gitlab-gatewayclass-controller` | Nom du contrôleur de la GatewayClass. |
| `gatewayApiResources.gateway.addresses`            | Array   | false          | Tableau d'adresses à ajouter au Gateway. |
| `gatewayApiResources.gateway.protocol`             | String  | `HTTPS`        | Protocole d'écoute par défaut. |
| `gatewayApiResources.gateway.annotations`          | Map     | `{}`           | Annotations à ajouter au Gateway géré. |
| `gatewayApiResources.gateway.infrastructure`       | Object  | `{}`           | [GatewayInfrastructure](https://gateway-api.sigs.k8s.io/reference/spec/#gatewayinfrastructure) ajouté au Gateway géré. |
| `gatewayApiResources.gateway.listeners`            | Object  |                | Configuration des écouteurs pour le Gateway géré. Voir ci-dessous pour un exemple. |

#### Configuration des écouteurs {#listener-configuration}

La configuration d'écouteur par défaut ne spécifie qu'un protocole pour les écouteurs avec un protocole prédéfini. Les écouteurs dont le protocole dépend de votre configuration héritent du protocole de niveau racine :

```yaml
protocol: HTTPS
listeners:
  http-default:
    protocol: HTTP
  gitlab-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: gitlab-tls
  gitlab-web-geo:
    tls:
      mode: Terminate
      certificateRefs:
        - name: gitlab-web-geo-tls
  gitlab-smartcard-web:
    protocol: ""
    tls:
      mode: Terminate
      certificateRefs:
        - name: gitlab-smartcard-tls
  gitlab-ssh:
    protocol: "TCP"
  registry-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: registry-tls
  pages-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: pages-tls
  kas-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: kas-tls
  kas-workspaces-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: kas-workspaces-tls
  minio-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: minio-tls
  openbao-web:
    tls:
      mode: Terminate
      certificateRefs:
        - name: openbao-tls
```

#### Extensions Envoy Gateway {#envoy-gateway-extensions}

Si le sous-chart Envoy Gateway intégré est utilisé, vous pouvez personnaliser le `EnvoyProxy` et créer optionnellement un `ClientTrafficPolicy` et une `SecurityPolicy` liés au `Gateway` géré.

| Nom                                                |  Type   | Défaut        | Description |
|:----------------------------------------------------|:-------:|:---------------|:------------|
| `gatewayApiResources.envoy.proxySpec`               | Object  | voir les valeurs     | Spécification de `EnvoyProxy`. Activé uniquement si `global.gatewayApi.installEnvoy` est true.|
| `gatewayApiResources.envoy.clientTrafficPolicySpec` | Object  | voir les valeurs     | Spécification `ClientTrafficPolicy` d'Envoy. Activé uniquement si `global.gatewayApi.installEnvoy` est true.|
| `gatewayApiResources.envoy.securityPolicySpec`      | Object  | voir les valeurs     | Spécification `SecurityPolicy` d'Envoy. Activé uniquement si `global.gatewayApi.installEnvoy` est true.|

#### Métriques Envoy Gateway {#envoy-gateway-metrics}

Le Prometheus intégré est configuré pour collecter des métriques à la fois depuis Envoy Gateway et le proxy Envoy géré. Si vous avez activé les définitions de ressources personnalisées (CRD) de Prometheus Operator, un ServiceMonitor sera créé pour Envoy Gateway et un PodMonitor sera créé pour le proxy Envoy.

```yaml
gatewayApiResources:
  envoy:
    metrics:
      envoyGateway:
        serviceMonitor:
          enabled: false
          additionalLabels: {}
          endpointConfig: {}
      envoyProxy:
        podMonitor:
          enabled: false
          additionalLabels: {}
          endpointConfig: {}
```

#### Configuration des routes {#route-configuration}

Le Webservice, KAS, Registry et GitLab Pages sont exposés via un `HTTPRoute` tandis que GitLab Shell est exposé via un `TCPRoute`. Les routes peuvent être personnalisées au niveau du chart :

```yaml
subchart:
  gatewayRoute:
    # Enable/disable this route, defaults to `global.gatewayApi.enabled`.
    enabled: true
    # Gateway section, defaults to matching listener.
    sectionName: "section"
    # Gateway reference, defaults to managed Gateway or globally configured external Gateway.
    gatewayName: "gateway"
    gatewayNamespace: "release-namespace"
    # Extra annotations
    annotations: {}
    # Timeout configuration
    timeouts:
      request: 15s
      backendRequest: 15s
    # Gateway API filters applied to the route rules
    filters: []
```

Les délais d'attente sont pris en charge sur toutes les routes sauf KAS (qui utilise un `BackendTrafficPolicy` pour ses exigences GRPC/WSS). Les filtres sont pris en charge sur toutes les ressources `HTTPRoute`.

Le champ `filters` accepte une liste d'objets [Gateway API HTTPRouteFilter](https://gateway-api.sigs.k8s.io/reference/spec/#gateway.networking.k8s.io/v1.HTTPRouteFilter). Les types de filtres courants incluent `RequestHeaderModifier`, `ResponseHeaderModifier`, `RequestRedirect`, `URLRewrite` et `RequestMirror`.

Exemple d'assainissement des en-têtes :

```yaml
registry:
  gatewayRoute:
    filters:
    - type: ResponseHeaderModifier
      responseHeaderModifier:
        set:
        - name: X-Content-Type-Options
          value: nosniff
        remove:
        - X-Powered-By
```

Si vous configurez plusieurs déploiements de webservice, les règles de route (y compris les filtres) peuvent être personnalisées par règle. Consultez la [documentation Gateway API du Webservice](../../charts/gitlab/webservice/_index.md#gateway-api) pour plus de détails.

### TLS entre le Gateway et les services backend {#tls-between-gateway-and-backend-services}

Lorsque TLS est activé sur un service backend (Webservice, KAS ou Registry), le chart crée une ressource `BackendTLSPolicy` qui indique au Gateway d'établir une connexion TLS.

Contrairement à l'implémentation NGINX Ingress, où la vérification des certificats peut être désactivée (par exemple avec `workhorse.tls.verify: false` pour les certificats auto-signés), Gateway API vérifie toujours la connexion TLS backend. Un secret de certificat CA doit donc être fourni pour que la vérification réussisse.

#### Activer TLS interne pour Webservice {#enable-internal-tls-for-webservice}

Le TLS backend pour Webservice nécessite que [Workhorse TLS](../../charts/gitlab/webservice/_index.md#gitlab-workhorse) soit activé globalement. Le nom d'hôte de validation utilise par défaut le nom DNS du service (`<service-name>.<namespace>.svc`) et peut être remplacé par `webservice.backendTLSPolicy.hostname` :

```yaml
global:
  workhorse:
    tls:
      enabled: true
gitlab:
  webservice:
    workhorse:
      tls:
        enabled: true
        caSecretName: workhorse-tls-ca
    backendTLSPolicy:
      hostname: workhorse.example.internal
```

Pour plus d'informations sur la configuration des remplacements optionnels au niveau du déploiement, consultez la [documentation Gateway API du Webservice](../../charts/gitlab/webservice/_index.md#tls-between-gateway-and-workhorse).

#### Activer TLS interne pour GitLab Relay (KAS) {#enable-internal-tls-for-gitlab-relay-kas}

Le TLS backend pour KAS est contrôlé par `global.kas.tls.enabled`. Le nom d'hôte de validation utilise par défaut le nom DNS du service (`<service-name>.<namespace>.svc`) et peut être remplacé par `kas.backendTLSPolicy.hostname` :

> [!warning]
> Les workspaces GitLab ne prennent pas encore en charge le TLS interne. Si vous utilisez des workspaces, n'activez pas le TLS interne pour GitLab Relay car cela entraînera des erreurs de protocole et TLS.

```yaml
global:
  kas:
    tls:
      enabled: true
      caSecretName: kas-tls-ca
gitlab:
  kas:
    backendTLSPolicy:
      hostname: kas.example.internal
```

#### Activer TLS interne pour Registry {#enable-internal-tls-for-registry}

Le TLS backend pour Registry est contrôlé par `registry.tls.enabled`. Le nom d'hôte de validation utilise par défaut le nom DNS du service (`<service-name>.<namespace>.svc`) et peut être remplacé par `registry.backendTLSPolicy.hostname` :

```yaml
global:
  hosts:
    registry:
      protocol: https
registry:
  tls:
    enabled: true
    caSecretName: registry-tls-ca
  backendTLSPolicy:
    hostname: registry.example.internal
```

### GitLab Geo {#gitlab-geo}

Pour configurer [GitLab Geo](https://docs.gitlab.com/administration/geo/) à l'aide de Gateway API, un nom d'hôte supplémentaire peut être configuré en définissant `global.geo.gatewayApi.additionalHostname`.

L'indicateur doit être défini sur l'URL interne sur les sites primaires et sur l'URL externe/unifiée sur les sites secondaires. Consultez le [guide de configuration de Geo](../geo/_index.md) pour plus d'informations.

### Utilisation d'un fournisseur Gateway API externe {#using-an-external-gateway-api-provider}

Le chart peut être configuré pour utiliser un fournisseur Gateway API externe, mais tous les fournisseurs ne répondent pas aux exigences pour exposer GitLab.

Assurez-vous que votre fournisseur Gateway API prend en charge :

1. `HTTPRoutes`, `TCPRoute` (pour SSH) et `GRPCRoutes` (pour les futures fonctionnalités KAS)
1. Les correspondances `RegularExpression` dans `HTTPRoutes`

Notez que nous testons uniquement avec le chart Envoy Gateway intégré. La prise en charge d'autres fournisseurs est proposée dans la mesure du possible. Nous accueillons toute contribution documentant des configurations fonctionnelles avec d'autres fournisseurs Gateway API.

#### Configuration des fournisseurs Gateway API externes {#setting-up-external-gateway-api-providers}

{{< tabs >}}

{{< tab title="Envoy Gateway" >}}

- Pour que GitLab fonctionne avec Envoy Gateway, les barres obliques échappées dans le trafic doivent rester inchangées. Cela peut être configuré avec une [PatchPolicy](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/0e07dbab91c9ba4df48c9424b769e92a219e7528/templates/envoypatchpolicy.yaml#L21).
- Notez que `EnvoyPatchPolicies` sont désactivées par défaut et qu'Envoy Gateway doit être [configuré pour les activer](https://gateway.envoyproxy.io/docs/tasks/extensibility/envoy-patch-policy/#enable-envoypatchpolicy).

{{< /tab >}}

{{< /tabs >}}

#### Configurer un Gateway géré en externe {#configure-an-externally-managed-gateway}

Pour configurer le chart GitLab afin d'utiliser un Gateway externe, désactivez le `Gateway` géré par le chart et configurez votre Gateway géré en externe :

```yaml
global:
  gatewayApi:
    enabled: true
    # Don't install Envoy Gateway subchart and custom resources.
    installEnvoy: false
    gatewayRef:
      name: "custom-gateway"
      namespace: "custom-gateway-namespace"
```

#### Configurer une GatewayClass gérée en externe {#configure-an-externally-managed-gatewayclass}

Pour configurer le chart GitLab afin d'utiliser la ressource `Gateway` gérée par le chart, mais une `GatewayClass` externe, désactivez le sous-chart Envoy Gateway intégré et configurez votre `GatewayClass` :

```yaml
global:
  gatewayApi:
    enabled: true
    # Don't install Envoy Gateway subchart and custom resources.
    installEnvoy: false
    class:
      # Name of the GatewayClass backed by your Gateway API controller.
      name: custom-class
```
