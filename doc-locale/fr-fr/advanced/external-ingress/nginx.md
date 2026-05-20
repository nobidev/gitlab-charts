---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer le chart GitLab avec un contrôleur NGINX Ingress externe
---

> [!warning]
> Le chart GitLab utilise par défaut l'API Gateway et Envoy Gateway depuis la version 19.0. Le NGINX Ingress intégré est obsolète et sera supprimé dans GitLab 20.0. Consultez l'[avis d'obsolescence](https://docs.gitlab.com/update/deprecations/#support-for-nginx-ingress-haproxy-and-traefik-charts) et l'[annonce de retrait](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/) pour plus d'informations.

Le chart GitLab gère et intègre actuellement un NGINX Ingress dupliqué. Ce guide vous aide à configurer un NGINX Ingress externe à utiliser avec le chart GitLab à la place de celui intégré.

## Services TCP dans le contrôleur Ingress externe {#tcp-services-in-the-external-ingress-controller}

Le composant GitLab Shell nécessite que le trafic TCP passe par le port 22 (par défaut ; cela peut être modifié). Ingress ne prend pas directement en charge les services TCP, une configuration supplémentaire est donc nécessaire. Votre contrôleur NGINX Ingress peut avoir été [déployé directement](https://github.com/kubernetes/ingress-nginx/blob/master/docs/deploy/index.md) (c.-à-d. avec un fichier de spécification Kubernetes) ou via le [chart Helm officiel](https://github.com/kubernetes/ingress-nginx). La configuration du passage TCP diffère selon l'approche de déploiement.

### Déploiement direct {#direct-deployment}

Dans un déploiement direct, le contrôleur NGINX Ingress gère la configuration des services TCP avec un `ConfigMap`. Pour plus d'informations, consultez [l'exposition des services TCP et UDP](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md) dans la documentation du contrôleur Ingress NGINX. En supposant que votre chart GitLab est déployé dans l'espace de nommage `gitlab` et que votre release Helm est nommée `mygitlab`, votre `ConfigMap` devrait ressembler à ceci :

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: tcp-configmap-example
data:
  22: "gitlab/mygitlab-gitlab-shell:22"
```

Une fois que vous avez ce `ConfigMap`, vous pouvez l'activer comme décrit dans la [documentation](https://github.com/kubernetes/ingress-nginx/blob/master/docs/user-guide/exposing-tcp-udp-services.md) du contrôleur NGINX Ingress en utilisant l'option `--tcp-services-configmap`.

```yaml
args:
  - /nginx-ingress-controller
  - --tcp-services-configmap=gitlab/tcp-configmap-example
```

Enfin, assurez-vous que le `Service` de votre contrôleur NGINX Ingress expose le port 22 en plus des ports 80 et 443.

### Déploiement Helm {#helm-deployment}

Si vous avez installé ou prévoyez d'installer le contrôleur NGINX Ingress en utilisant son [chart Helm](https://github.com/kubernetes/ingress-nginx), vous devez ajouter une valeur au chart via la ligne de commande :

```shell
--set tcp.22="gitlab/mygitlab-gitlab-shell:22"
```

ou un fichier `values.yaml` :

```yaml
tcp:
  22: "gitlab/mygitlab-gitlab-shell:22"
```

Le format de la valeur est identique à celui décrit ci-dessus dans la section « Déploiement direct ».

### Configurer le chart GitLab {#configure-gitlab-chart}

[Configurez les Ingresses GitLab](_index.md) pour utiliser votre contrôleur NGINX Ingress externe.
