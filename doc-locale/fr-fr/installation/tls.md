---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer TLS pour le chart GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Ce chart est capable d'effectuer la terminaison TLS à l'aide du contrôleur NGINX Ingress. Vous avez le choix de la méthode pour acquérir les certificats TLS pour votre déploiement. Des détails complets sont disponibles dans [les paramètres globaux d'Ingress](../charts/globals.md#configure-ingress-settings).

## Option 1 : cert-manager et Let's Encrypt {#option-1-cert-manager-and-lets-encrypt}

Let's Encrypt est une autorité de certification gratuite, automatisée et ouverte. Les certificats peuvent être demandés automatiquement à l'aide de divers outils. Ce chart est prêt à s'intégrer avec un choix populaire, [cert-manager](https://github.com/cert-manager/cert-manager).

*Si vous utilisez déjà cert-manager*, vous pouvez utiliser `global.ingress.annotations` pour configurer les [annotations appropriées](https://cert-manager.io/docs/usage/ingress/#supported-annotations) pour votre déploiement de cert-manager.

*Si cert-manager n'est pas encore installé dans votre cluster*, vous pouvez l'installer et le configurer en tant que dépendance de ce chart.

### cert-manager et Issuer internes {#internal-cert-manager-and-issuer}

```shell
helm repo update
helm dep update
helm install gitlab gitlab/gitlab \
  --set certmanager-issuer.email=you@example.com
```

L'installation de `cert-manager` est contrôlée par le paramètre `installCertmanager` (`true` par défaut). La connexion de cert-manager au chart est contrôlée par `global.gatewayApi.configureCertmanager` pour l'API Gateway (le chemin de routage par défaut depuis GitLab 19.0, `true` par défaut) et par `global.ingress.configureCertmanager` pour NGINX Ingress (`false` par défaut, à définir sur `true` lors de l'utilisation d'Ingress). Seul l'e-mail de l'émetteur doit être fourni par défaut.

### cert-manager externe et Issuer interne {#external-cert-manager-and-internal-issuer}

Il est possible d'utiliser un `cert-manager` externe tout en fournissant un Issuer dans ce chart.

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set certmanager-issuer.email=you@example.com \
  --set global.ingress.annotations."kubernetes\.io/tls-acme"=true
```

### cert-manager externe et Issuer (externe) {#external-cert-manager-and-issuer-external}

Pour utiliser un `cert-manager` et une ressource `Issuer` externes, vous devez fournir plusieurs éléments afin que les certificats auto-signés ne soient pas activés.

1. Annotations pour activer le `cert-manager` externe (voir la [documentation](https://cert-manager.io/docs/usage/ingress/#supported-annotations) pour plus de détails)
1. Noms des secrets TLS pour chaque service (cela désactive les [comportements auto-signés](#option-4-use-auto-generated-self-signed-wildcard-certificate))

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.annotations."kubernetes\.io/tls-acme"=true \
  --set gitlab.webservice.ingress.tls.secretName=RELEASE-gitlab-tls \
  --set registry.ingress.tls.secretName=RELEASE-registry-tls \
  --set minio.ingress.tls.secretName=RELEASE-minio-tls \
  --set gitlab.kas.ingress.tls.secretName=RELEASE-kas-tls
```

## Option 2 :  Utiliser votre propre certificat wildcard {#option-2-use-your-own-wildcard-certificate}

Ajoutez votre certificat de chaîne complète et votre clé au cluster en tant que `Secret`, par exemple :

```shell
kubectl create secret tls <tls-secret-name> --cert=<path/to-full-chain.crt> --key=<path/to.key>
```

Incluez l'option pour

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.tls.secretName=<tls-secret-name>
```

### Utiliser AWS ACM pour gérer les certificats {#use-aws-acm-to-manage-certificates}

Si vous utilisez AWS ACM pour créer votre certificat wildcard, il n'est pas possible de le spécifier via un secret, car les certificats ACM ne peuvent pas être téléchargés. Spécifiez-les plutôt via `nginx-ingress.controller.service.annotations` :

```yaml
nginx-ingress:
  controller:
    service:
      annotations:
        ...
        service.beta.kubernetes.io/aws-load-balancer-ssl-cert: arn:aws:acm:{region}:{user id}:certificate/{id}
```

## Option 3 :  Utiliser un certificat individuel par service {#option-3-use-individual-certificate-per-service}

Ajoutez vos certificats de chaîne complète au cluster en tant que secrets, puis transmettez ces noms de secrets à chaque Ingress.

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set global.ingress.tls.enabled=true \
  --set gitlab.webservice.ingress.tls.secretName=RELEASE-gitlab-tls \
  --set registry.ingress.tls.secretName=RELEASE-registry-tls \
  --set minio.ingress.tls.secretName=RELEASE-minio-tls \
  --set gitlab.kas.ingress.tls.secretName=RELEASE-kas-tls
```

> [!note] Si vous configurez votre instance GitLab pour communiquer avec d'autres services, il peut être nécessaire de [fournir les chaînes de certificats](../charts/globals.md#custom-certificate-authorities) pour ces services à GitLab via le chart Helm également.

## Option 4 :  Utiliser un certificat wildcard auto-signé généré automatiquement {#option-4-use-auto-generated-self-signed-wildcard-certificate}

Ces charts offrent également la possibilité de fournir un certificat wildcard auto-signé généré automatiquement. Cela peut être utile dans les environnements où Let's Encrypt n'est pas une option, mais où la sécurité via SSL est tout de même souhaitée. Cette fonctionnalité est fournie par le job [shared-secrets](../charts/shared-secrets.md).

> [!note]
>
> - Le chart `gitlab-runner` ne fonctionne pas correctement avec les certificats auto-signés. Nous vous recommandons de le désactiver, comme indiqué ci-dessous.
> - Si vous désactivez TLS globalement, avec quelque chose comme `--set global.ingress.tls.enabled=false`, les certificats auto-signés ne seront pas générés.

```shell
helm install gitlab gitlab/gitlab \
  --set installCertmanager=false \
  --set global.ingress.configureCertmanager=false \
  --set gitlab-runner.install=false
```

Le job `shared-secrets` produira alors un certificat CA, un certificat wildcard et une chaîne de certificats destinés à tous les services accessibles de l'extérieur. Les secrets contenant ces éléments seront `RELEASE-wildcard-tls`, `RELEASE-wildcard-tls-ca` et `RELEASE-wildcard-tls-chain`. Le `RELEASE-wildcard-tls-ca` contient le certificat CA public qui peut être distribué aux utilisateurs et aux systèmes qui accéderont à l'instance GitLab déployée. Le `RELEASE-wildcard-tls-chain` contient à la fois le certificat CA et le certificat wildcard, que vous pouvez également utiliser directement pour GitLab Runner via `gitlab-runner.certsSecretName=RELEASE-wildcard-tls-chain`.

## Exigence TLS pour GitLab Pages {#tls-requirement-for-gitlab-pages}

Pour [GitLab Pages avec prise en charge TLS](https://docs.gitlab.com/administration/pages/#wildcard-domains-with-tls-support), un certificat wildcard applicable pour `*.<pages domain>` (la valeur par défaut de `<pages domain>` est `pages.<base domain>`) est requis.

Étant donné qu'un certificat wildcard est requis, il ne peut pas être créé automatiquement par cert-manager et Let's Encrypt. cert-manager est donc désactivé par défaut pour GitLab Pages (via `gitlab-pages.ingress.configureCertmanager`), vous devrez donc fournir votre propre Secret k8s contenant un certificat wildcard. Si vous avez un cert-manager externe configuré à l'aide de `global.ingress.annotations`, vous souhaiterez probablement également remplacer ces annotations dans `gitlab-pages.ingress.annotations`.

Par défaut, le nom de ce secret est `<RELEASE>-pages-tls`. Un nom différent peut être spécifié à l'aide du paramètre `gitlab.gitlab-pages.ingress.tls.secretName` :

```shell
helm install gitlab gitlab/gitlab \
  --set global.pages.enabled=true \
  --set gitlab.gitlab-pages.ingress.tls.secretName=<secret name>
```

## Dépannage {#troubleshooting}

Cette section contient des solutions possibles aux problèmes que vous pourriez rencontrer.

### Erreurs de terminaison SSL {#ssl-termination-errors}

Si vous utilisez Let's Encrypt comme fournisseur TLS et que vous rencontrez des erreurs liées aux certificats, vous disposez de quelques options pour déboguer ce problème :

1. Vérifiez votre domaine avec [letsdebug](https://letsdebug.net/) pour détecter d'éventuelles erreurs.
1. Si letsdebug ne retourne aucune erreur, vérifiez s'il y a un problème lié à cert-manager :

   ```shell
   kubectl describe certificate,order,challenge --all-namespaces
   ```

   Si vous voyez des erreurs, essayez de supprimer l'objet certificat pour forcer la demande d'un nouveau.

1. Si rien de ce qui précède ne fonctionne, envisagez de supprimer les [ressources cert-manager existantes](https://cert-manager.io/docs/installation/kubectl/#uninstalling) et de réinstaller cert-manager. Si vous utilisez le cert-manager interne, supprimez les déploiements contenant `certmanager` dans leur nom et réinstallez le chart Helm. Par exemple, en supposant une release nommée `gitlab` :

   ```shell
   kubectl -n <namespace> delete deployment gitlab-certmanager gitlab-certmanager-cainjector gitlab-certmanager-webhook
   helm upgrade --install -n <namespace> gitlab gitlab/gitlab
   ```
