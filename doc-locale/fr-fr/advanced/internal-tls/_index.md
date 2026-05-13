---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utiliser TLS entre les composants du chart GitLab
---

Les charts GitLab peuvent utiliser le protocole TLS (transport-layer security) entre les différents composants. Cela vous oblige à fournir des certificats pour les services que vous souhaitez activer, et à configurer ces services pour utiliser ces certificats ainsi que l'autorité de certification (CA) qui les a signés.

## Préparation {#preparation}

Chaque chart dispose d'une documentation concernant l'activation du TLS pour ce service, ainsi que les différents paramètres nécessaires pour garantir une configuration appropriée.

### Génération de certificats à usage interne {#generating-certificates-for-internal-use}

> [!note] GitLab ne prétend pas fournir une infrastructure PKI de haute qualité, ni des autorités de certification.

Pour les besoins de cette documentation, nous fournissons ci-dessous un script de **Proof of Concept**, qui utilise [CFSSL de Cloudflare](https://github.com/cloudflare/cfssl/) pour produire une autorité de certification auto-signée et un certificat générique utilisable pour tous les services.

Ce script :

- Génère une paire de clés CA.
- Signe un certificat destiné à couvrir tous les points de terminaison de service des composants GitLab.
- Crée deux objets Kubernetes Secret :
  - Un secret de type `kuberetes.io/tls` qui contient le certificat serveur et la paire de clés.
  - Un secret de type `Opaque` qui contient **uniquement** le certificat public de la CA sous la forme `ca.crt`, comme requis par NGINX Ingress.

Prérequis :

- Bash, ou un shell compatible.
- `cfssl` est disponible dans votre shell et dans `PATH`.
- `kubectl` est disponible et configuré pour pointer vers votre cluster Kubernetes où GitLab sera installé ultérieurement.
  - Assurez-vous d'avoir créé l'espace de nommage dans lequel vous souhaitez installer ces certificats avant d'exécuter le script.

Vous pouvez copier le contenu de ce script sur votre ordinateur et rendre le fichier résultant exécutable. Nous suggérons `poc-gitlab-internal-tls.sh`.

```shell
#!/bin/bash
set -e
#############
## make and change into a working directory
pushd $(mktemp -d)

#############
## setup environment
NAMESPACE=${NAMESPACE:-default}
RELEASE=${RELEASE:-gitlab}
## stop if variable is unset beyond this point
set -u
## known expected patterns for SAN
CERT_SANS="*.${NAMESPACE}.svc,${RELEASE}-metrics.${NAMESPACE}.svc,*.${RELEASE}-gitaly.${NAMESPACE}.svc"

#############
## generate default CA config
cfssl print-defaults config > ca-config.json
## generate a CA
echo '{"CN":"'${RELEASE}.${NAMESPACE}.internal.ca'","key":{"algo":"ecdsa","size":256}}' | \
  cfssl gencert -initca - | \
  cfssljson -bare ca -
## generate certificate
echo '{"CN":"'${RELEASE}.${NAMESPACE}.internal'","key":{"algo":"ecdsa","size":256}}' | \
  cfssl gencert -config=ca-config.json -ca=ca.pem -ca-key=ca-key.pem -profile www -hostname="${CERT_SANS}" - |\
  cfssljson -bare ${RELEASE}-services

#############
## load certificates into K8s
kubectl -n ${NAMESPACE} create secret tls ${RELEASE}-internal-tls \
  --cert=${RELEASE}-services.pem \
  --key=${RELEASE}-services-key.pem
kubectl -n ${NAMESPACE} create secret generic ${RELEASE}-internal-tls-ca \
  --from-file=ca.crt=ca.pem
```

> [!note] Ce script _ne préserve pas_ la clé privée de la CA. Il s'agit d'un assistant de preuve de concept, et _n'est pas destiné à un usage en production_.

Le script attend que deux variables d'environnement soient définies :

1. `NAMESPACE` : L'espace de nommage Kubernetes dans lequel vous installerez GitLab ultérieurement. La valeur par défaut est `default`, comme avec `kubectl`.
1. `RELEASE` : Le nom de release Helm que vous utiliserez ultérieurement pour installer GitLab. La valeur par défaut est `gitlab`.

Pour exécuter ce script, vous pouvez utiliser `export` pour les deux variables, ou les faire précéder le nom du script avec leurs valeurs.

```shell
export NAMESPACE=testing
export RELEASE=gitlab

./poc-gitlab-internal-tls.sh
```

Une fois le script exécuté, vous trouverez les deux secrets créés, et le répertoire de travail temporaire contient tous les certificats et leurs clés.

```plaintext
$ pwd
/tmp/tmp.swyMgf9mDs
$ kubectl -n ${NAMESPACE} get secret | grep internal-tls
testing-internal-tls      kubernetes.io/tls                     2      11s
testing-internal-tls-ca   Opaque                                1      10s
$ ls -1
ca-config.json
ca.csr
ca-key.pem
ca.pem
testing-services.csr
testing-services-key.pem
testing-services.pem
```

#### CN et SAN requis pour le certificat {#required-certificate-cn-and-sans}

Les différents composants GitLab communiquent entre eux via les noms DNS de leurs services. Pour que la vérification du certificat TLS réussisse, chaque certificat nécessite un SAN qui inclut le nom de service du composant, ou un caractère générique acceptable pour l'entrée DNS du service Kubernetes.

- `service-name.namespace.svc`
- `*.namespace.svc`

Ne pas garantir ces SAN dans les certificats _entraînera_ une instance non fonctionnelle, et des journaux pouvant être assez cryptiques, faisant référence à « connection failure » ou « SSL verification failed ».

Vous pouvez utiliser `helm template` pour récupérer une liste complète de tous les noms d'objets Service, si nécessaire. Si votre GitLab a été déployé sans TLS, vous pouvez interroger Kubernetes pour obtenir ces noms :

`kubectl -n ${NAMESPACE} get service -lrelease=${RELEASE}`

## Trafic Ingress {#ingress-traffic}

Par défaut, le trafic réseau en provenance du contrôleur Ingress ou Gateway API vers les services backend est censé ne pas être chiffré. Pour activer le TLS interne pour ces connexions, une configuration supplémentaire est nécessaire en fonction de votre solution réseau.

### NGINX Ingress {#nginx-ingress}

Lorsque le TLS interne est activé, le chart GitLab annote automatiquement les objets Ingress de sorte que NGINX Ingress initie des connexions TLS vers les services backend et vérifie leurs certificats par rapport à la CA configurée. Aucune configuration utilisateur supplémentaire n'est requise.

Si vous utilisez une implémentation Ingress différente, vous devez ajouter des annotations ou une configuration spécifiques au fournisseur pour activer les connexions TLS entre le contrôleur et les backends.

### Envoy Gateway {#envoy-gateway}

Le chart fournit des ressources `BackendTLSPolicy` pour configurer Envoy Gateway, ou d'autres contrôleurs Gateway API conformes aux spécifications, afin d'initier des connexions TLS avec les backends.

Pour plus de détails, consultez la documentation [Gateway API](../gateway-api/_index.md#tls-between-gateway-and-backend-services).

## Configuration {#configuration}

Des exemples de configurations sont disponibles dans [examples/internal-tls](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/master/examples/internal-tls/).

Pour les besoins de cette documentation, nous avons fourni `shared-cert-values.yaml` qui configure les composants GitLab pour utiliser les certificats générés avec le script ci-dessus, dans [la génération de certificats à usage interne](#generating-certificates-for-internal-use).

Éléments clés à configurer :

1. [Autorités de certification personnalisées](../../charts/globals.md#custom-certificate-authorities) globales.
1. TLS par composant pour les écouteurs de service. (Consultez la documentation de chaque chart, sous [charts/](../../charts/_index.md))

Ce processus est grandement simplifié en utilisant la fonctionnalité d'ancre native de YAML. Un extrait tronqué de `shared-cert-values.yaml` illustre ceci :

```yaml
.internal-ca: &internal-ca gitlab-internal-tls-ca
.internal-tls: &internal-tls gitlab-internal-tls

global:
  certificates:
    customCAs:
    - secret: *internal-ca
  workhorse:
    tls:
      enabled: true
gitlab:
  webservice:
    tls:
      secretName: *internal-tls
    workhorse:
       tls:
          verify: true # default
          secretName: *internal-tls
          caSecretName: *internal-ca
```

## Résultat {#result}

Lorsque tous les composants ont été configurés pour fournir TLS sur leurs écouteurs de service, toutes les communications entre les composants GitLab traverseront le réseau avec la sécurité TLS, y compris les connexions de NGINX Ingress vers chaque composant GitLab.

NGINX Ingress terminera tout TLS _entrant_, déterminera les services appropriés auxquels transmettre le trafic, puis établira une nouvelle connexion TLS vers le composant GitLab. Lorsqu'il est configuré comme indiqué ici, il _vérifiera_ également les certificats servis par les composants GitLab par rapport à la CA.

Cela peut être vérifié en se connectant au pod Toolbox et en interrogeant les différents services des composants. Voici un exemple de connexion au port de service principal du pod Webservice qu'utilise NGINX Ingress :

```plaintext
$ kubectl -n ${NAMESPACE} get pod -lapp=toolbox,release=${RELEASE}
NAME                              READY   STATUS    RESTARTS   AGE
gitlab-toolbox-5c447bfdb4-pfmpc   1/1     Running   0          65m
$ kubectl exec -ti gitlab-toolbox-5c447bfdb4-pfmpc -c toolbox -- \
    curl -Iv "https://gitlab-webservice-default.testing.svc:8181"
```

La sortie doit être similaire à l'exemple suivant :

```plaintext
*   Trying 10.60.0.237:8181...
* Connected to gitlab-webservice-default.testing.svc (10.60.0.237) port 8181 (#0)
* ALPN, offering h2
* ALPN, offering http/1.1
* successfully set certificate verify locations:
*  CAfile: /etc/ssl/certs/ca-certificates.crt
*  CApath: /etc/ssl/certs
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.3 (IN), TLS handshake, Encrypted Extensions (8):
* TLSv1.3 (IN), TLS handshake, Certificate (11):
* TLSv1.3 (IN), TLS handshake, CERT verify (15):
* TLSv1.3 (IN), TLS handshake, Finished (20):
* TLSv1.3 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.3 (OUT), TLS handshake, Finished (20):
* SSL connection using TLSv1.3 / TLS_AES_128_GCM_SHA256
* ALPN, server did not agree to a protocol
* Server certificate:
*  subject: CN=gitlab.testing.internal
*  start date: Jul 18 19:15:00 2022 GMT
*  expire date: Jul 18 19:15:00 2023 GMT
*  subjectAltName: host "gitlab-webservice-default.testing.svc" matched cert's "*.testing.svc"
*  issuer: CN=gitlab.testing.internal.ca
*  SSL certificate verify ok.
> HEAD / HTTP/1.1
> Host: gitlab-webservice-default.testing.svc:8181
```

## Dépannage {#troubleshooting}

Si votre instance GitLab semble inaccessible depuis le navigateur en affichant une erreur HTTP 503, NGINX Ingress rencontre probablement un problème lors de la vérification des certificats des composants GitLab.

Vous pouvez contourner ce problème en définissant temporairement `gitlab.webservice.workhorse.tls.verify` sur `false`.

Le contrôleur NGINX Ingress peut être connecté et affichera un message dans `nginx.conf`, concernant les problèmes de vérification du ou des certificats.

Exemple de contenu, lorsque le Secret n'est pas accessible :

```plaintext
# Location denied. Reason: "error obtaining certificate: local SSL certificate
  testing/gitlab-internal-tls-ca was not found"
return 503;
```

Problèmes courants à l'origine de cette situation :

- Le certificat CA ne se trouve pas dans une clé nommée `ca.crt` dans le Secret.
- Le Secret n'a pas été correctement fourni, ou peut ne pas exister dans l'espace de nommage.
