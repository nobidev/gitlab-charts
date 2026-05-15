---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer vers Envoy Gateway
---

{{< details >}}

- Édition :  version gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

À partir de GitLab 19.0, le chart GitLab désactivera le contrôleur NGINX Ingress intégré et utilisera par défaut l'API Gateway ainsi que l'Envoy Gateway intégré. Tous les contrôleurs Ingress intégrés, notamment HAProxy et Traefik, sont obsolètes et seront supprimés dans la version 20.0. Les Ingresses ne sont pas obsolètes et resteront disponibles après la version 20.0, mais nécessiteront un [contrôleur Ingress externe](../../advanced/external-ingress/_index.md).

Vous pouvez migrer du contrôleur NGINX Ingress intégré vers l'API Gateway avec l'une des méthodes suivantes :

- Une [migration en une étape](#migrate-in-one-step)
- Une [migration en plusieurs étapes](#migrate-with-zero-downtime) sans temps d'arrêt

## Migrer en une étape {#migrate-in-one-step}

> [!warning] 
> Prévoyez environ 5 minutes de temps d'arrêt pendant la migration. La durée réelle peut varier en fonction de votre déploiement, de votre infrastructure et de votre configuration. Pour une approche sans temps d'arrêt, consultez la [migration sans temps d'arrêt](#migrate-with-zero-downtime).

Pour migrer de l'Ingress (NGINX) vers l'API Gateway et Envoy Gateway :

1. Installez les CRD d'Envoy et de l'API Gateway :

   ```script
   helm template eg-crds oci://docker.io/envoyproxy/gateway-crds-helm \
     --version v1.7.2 \
     --set crds.gatewayAPI.enabled=true \
     --set crds.envoyGateway.enabled=true \
     | kubectl apply --server-side -f -
   ```

2. Vous pouvez également installer les CRD de l'API Gateway via votre fournisseur cloud ou [les appliquer manuellement](https://gateway-api.sigs.k8s.io/guides/#installing-gateway-api) à votre cluster.

3. Désactivez le contrôleur NGINX Ingress et les ressources Ingress :

   ```yaml
   # Disable bundled NGINX Ingress controller.
   nginx-ingress:
     enabled: false

   global:
     # Disable rendering of Ingress resources.
     ingress:
       enabled: false
   ```

4. Configurez Certmanager pour l'API Gateway :

   ```yaml
   # Configure bundled certmanager for Gateway API support.
   certmanager:
     config:
       apiVersion: controller.config.cert-manager.io/v1alpha1
       kind: ControllerConfiguration
       enableGatewayAPI: true

   global:
     gatewayApi:
       configureCertmanager: true
   ```

5. Activez les ressources Envoy et de l'API Gateway :

   ```yaml
   global:
     # Disable rendering of Ingress resources.
     gatewayApi:
       # Install a Gateway and Routes for each component.
       enabled: true
       # Install the bundled Envoy Gateway chart, a GatewayClass, a EnvoyPatchPolicy, and the EnvoyProxy resources.
       installEnvoy: true
   ```

6. Configurez la Gateway pour lui associer une adresse IP statique. Par défaut, l'adresse IP configurée via `global.hosts.externalIP` est réutilisée.

   ```yaml
   # Depending on your cloud provider you might to migrate additional annotations.
   global:
     hosts:
       # Only used by Envoy if bundled NGINX Ingress is disabled and no custom
       # gateway addresses are defined.
       externalIP: "10.10.0.1"
   gatewayApiResources:
     gateway:
       addresses:
       - type: IPAddress
         value: "10.10.0.2"
       infrastructure:
         annotations: {}
   ```

   {{< tabs >}}

   {{< tab title="GKE" >}}

   Au lieu d'utiliser `global.hosts.externalIP` ou `gatewayApiResources.gateway.addresses`, configurez les annotations pour le LoadBalancer provisionné :

   ```yaml
   gatewayApiResources:
     gateway:
       infrastructure:
         annotations:
           networking.gke.io/load-balancer-type: External
           networking.gke.io/load-balancer-ip-addresses: gitlab-ip-address
           cloud.google.com/l4-rbs: enabled
   ```

   {{< /tab >}}

   {{< tab title="EKS" >}}

   Pour migrer un LoadBalancer EKS, migrez vos annotations du service du contrôleur NGINX vers la configuration d'Envoy Gateway :

   ```yaml
   gatewayApiResources:
     gateway:
       infrastructure:
         annotations:
           service.beta.kubernetes.io/aws-load-balancer-type: nlb
           service.beta.kubernetes.io/aws-load-balancer-eip-allocations: "gitlab-allocation-id"
           service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
   ```

   {{< /tab >}}

   {{< /tabs >}}

7. Mettez à niveau votre release du chart GitLab avec les valeurs mises à jour.

## Migrer sans temps d'arrêt {#migrate-with-zero-downtime}

Pour effectuer une migration sans temps d'arrêt, vous pouvez exécuter NGINX Ingress et Envoy Gateway côte à côte afin que deux LoadBalancers fonctionnent simultanément. Une fois qu'Envoy Gateway est entièrement configuré pour gérer le trafic GitLab, mettez à jour les enregistrements DNS de GitLab pour pointer vers le LoadBalancer géré par Envoy Gateway.

1. Activez les ressources Envoy Gateway et de l'API Gateway sans désactiver NGINX Ingress :

   ```yaml
   nginx-ingress:
     enabled: true

   global:
     hosts:
       # External LoadBalancer IP bound by NGINX Ingress
       externalIp: "10.10.0.1"
     # Enable Gateway API and configure another
     gatewayApi:
       enabled: true
       installEnvoy: true
   gatewayApiResources:
     gateway:
       addresses:
        - type: IPAddress
          value: "10.10.0.2"
       infrastructure:
         annotations: {}
   ```

2. Configurez vos certificats TLS ou un émetteur certmanager pour la Gateway gérée :

   > [!note] 
   > Vous ne pouvez pas utiliser l'émetteur fourni par le chart GitLab à cette fin. L'émetteur utilise [HTTP01](https://cert-manager.io/docs/configuration/acme/http01/), qui ne sera pas en mesure de récupérer les certificats tant que vos enregistrements DNS n'auront pas été mis à jour.

   1. Configurez un [émetteur DNS01](https://cert-manager.io/docs/configuration/acme/dns01/) ou personnalisez les [listeners](../../charts/globals.md) pour utiliser des certificats déjà existants.

   2. Si vous avez créé un émetteur personnalisé, activez la prise en charge de l'API Gateway par certmanager et annotez la Gateway gérée :

      ```yaml
      # Enable Gateway API support for bundled certmanager.
      certmanager:
        config:
          apiVersion: controller.config.cert-manager.io/v1alpha1
          kind: ControllerConfiguration
          enableGatewayAPI: true

      global:
        gatewayApi:
          # Do not configure HTTP01 issues.
          configureCertmanager: false
      gatewayApiResources:
        gateway:
          # Annotate Gateway to use custom DNS01 issuer.
          annotations:
            cert-manager.io/issuer: gitlab-dns01
      ```

3. Assurez-vous que GitLab est accessible si le domaine résout vers l'adresse IP du LoadBalancer Envoy Gateway :

   ```script
   $ curl -Lso /dev/null \
     --write-out 'Status: %{http_code} TLS: %{ssl_verify_result} (0=OK)' \
     --resolve gitlab.example.com:443:10.10.0.2 \
     "https://gitlab.example.com"
   Status: 200 TLS: 0 (0=OK)
   ```

4. Mettez à jour vos entrées DNS pour qu'elles résolvent vers le LoadBalancer Envoy Gateway.
5. Attendez que les entrées DNS se propagent à tous les clients.
6. Désactivez le contrôleur NGINX Ingress et les objets Ingress :

   ```yaml
   nginx-ingress:
     enabled: false

   global:
     ingress:
       enabled: false
   ```
