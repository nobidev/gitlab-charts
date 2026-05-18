---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer le chart GitLab avec un contrôleur Ingress externe
---

Ce chart configure des ressources `Ingress` avec un NGINX Ingress intégré. Bien que le chart fasse des efforts pour migrer d'Ingress vers Gateway API, vous pouvez continuer à utiliser des Ingresses avec un contrôleur Ingress externe.

## Préparer le contrôleur Ingress externe {#prepare-the-external-ingress-controller}

### NGINX {#nginx}

> [!warning]
> NGINX Ingress a été déprécié et ne recevra plus de correctifs de sécurité après mars 2026. Lisez l'[annonce officielle](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/) pour plus d'informations.

Consultez la [documentation externe NGINX Ingress](nginx.md) pour configurer et préparer un déploiement NGINX Ingress externe à utiliser avec GitLab.

### Traefik {#traefik}

Traefik doit être configuré pour exposer le port 22 pour GitLab Shell (le démon SSH de GitLab) :

```yaml
ports:
  gitlab-shell:
    expose: true
    port: 2222
    exposedPort: 22
```

## Personnaliser les options Ingress de GitLab {#customize-the-gitlab-ingress-options}

Le contrôleur NGINX Ingress utilise une annotation pour indiquer quel contrôleur Ingress gérera un `Ingress` particulier (voir la [documentation](https://github.com/kubernetes/ingress-nginx#annotation-ingressclass)). Vous pouvez configurer la classe Ingress à utiliser avec ce chart à l'aide du paramètre `global.ingress.class`. Assurez-vous de définir cela dans vos options Helm.

```shell
--set global.ingress.class=myingressclass
```

Bien que cela ne soit pas nécessairement requis, si vous utilisez un contrôleur Ingress externe, vous souhaiterez probablement désactiver le contrôleur Ingress déployé par défaut avec ce chart :

```shell
--set nginx-ingress.enabled=false
```

## Gestion personnalisée des certificats {#custom-certificate-management}

Si vous utilisez un contrôleur Ingress externe, vous utilisez peut-être également une instance cert-manager externe ou gérez vos certificats d'une autre manière personnalisée. Pour une documentation complète sur vos options TLS, consultez [configurer TLS pour le chart GitLab](../../installation/tls.md) ; cependant, pour les besoins de cette discussion, voici les deux valeurs qui devront être définies pour désactiver le chart cert-manager et indiquer aux charts de composants GitLab de ne pas rechercher les ressources de certificats intégrées :

```shell
--set installCertmanager=false
--set global.ingress.configureCertmanager=false
```
