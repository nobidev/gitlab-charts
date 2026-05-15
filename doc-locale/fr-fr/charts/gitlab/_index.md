---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Sous-charts Helm GitLab
---

Le chart Helm GitLab est composé de plusieurs sous-charts, qui fournissent les composants principaux de GitLab :

- [Gitaly](gitaly/_index.md)
- [GitLab Exporter](gitlab-exporter/_index.md)
- [GitLab Pages](gitlab-pages/_index.md)
- [GitLab Runner](gitlab-runner/_index.md)
- [GitLab Shell](gitlab-shell/_index.md)
- [GitLab agent server (KAS)](kas/_index.md)
- [Mailroom](mailroom/_index.md)
- [Migrations](migrations/_index.md)
- [Praefect](praefect/_index.md)
- [Sidekiq](sidekiq/_index.md)
- [Spamcheck](spamcheck/_index.md)
- [Toolbox](toolbox/_index.md)
- [Webservice](webservice/_index.md)

Les paramètres de chaque sous-chart doivent être placés sous la clé `gitlab`. Par exemple, les paramètres de GitLab Shell seraient similaires à :

```yaml
gitlab:
  gitlab-shell:
    ...
```

Utilisez ces charts pour les dépendances facultatives :

- [MinIO](../minio/_index.md)
- [NGINX](../nginx/_index.md)
- [HAProxy](../haproxy/_index.md)
- [PostgreSQL](https://artifacthub.io/packages/helm/bitnami/postgresql)
- [Redis](https://artifacthub.io/packages/helm/bitnami/redis)
- [Registry](../registry/_index.md)
- [Traefik](../traefik/_index.md)

Utilisez ces charts comme ajouts facultatifs :

- [Prometheus](https://artifacthub.io/packages/helm/prometheus-community/prometheus)
- [_Unprivileged_](https://docs.gitlab.com/runner/install/kubernetes_helm_chart_configuration/#access-gitlab-with-a-custom-certificate) [GitLab Runner](https://docs.gitlab.com/runner/) qui utilise l'exécuteur Kubernetes
- SSL automatiquement provisionné via [Let's Encrypt](https://letsencrypt.org/) , qui utilise [Jetstack](https://venafi.com/jetstack-consult/) 's [cert-manager](https://cert-manager.io/docs/) avec [certmanager-issuer](../certmanager-issuer/_index.md)

## Paramètres facultatifs des sous-charts Helm GitLab {#gitlab-helm-subchart-optional-parameters}

### affinity {#affinity}

{{< history >}}

- [Introduit](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/3770) dans GitLab 17.3 (Charts 8.3) pour tous les sous-charts Helm GitLab à l'exception de `webservice` et `sidekiq`.

{{< /history >}}

`affinity` est un paramètre facultatif dans tous les sous-charts Helm GitLab. Lorsque vous le définissez, il prend la priorité sur la valeur [globale `affinity`](../globals.md#affinity). Pour plus d'informations sur `affinity`, consultez [la documentation Kubernetes correspondante](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#affinity-and-anti-affinity).

> [!note]
> Les charts Helm `webservice` et `sidekiq` ne peuvent utiliser que la valeur [globale `affinity`](../globals.md#affinity). Suivez l'ticket [25403](https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25403) pour savoir quand l'`affinity` local sera implémenté pour `webservice` et `sidekiq`.

Avec `affinity`, vous pouvez définir l'un ou l'autre, ou les deux :

- Règles `podAntiAffinity` pour :
  - Ne pas planifier de pods dans le même domaine que les pods correspondant à l'expression associée à la `topology key`.
  - Définir deux modes de règles `podAntiAffinity` : requis (`requiredDuringSchedulingIgnoredDuringExecution`) et préféré (`preferredDuringSchedulingIgnoredDuringExecution`). En utilisant la variable `antiAffinity` dans `values.yaml`, définissez le paramètre sur `soft` pour que le mode préféré soit appliqué, ou définissez-le sur `hard` pour que le mode requis soit appliqué.
- Règles `nodeAffinity` pour :
  - Planifier des pods sur des nœuds appartenant à une zone ou à des zones spécifiques.
  - Définir deux modes de règles `nodeAffinity` : requis (`requiredDuringSchedulingIgnoredDuringExecution`) et préféré (`preferredDuringSchedulingIgnoredDuringExecution`). Lorsqu'il est défini sur `soft`, le mode préféré est appliqué. Lorsqu'il est défini sur `hard`, le mode requis est appliqué. Cette règle est implémentée uniquement pour le chart `registry` et le chart `gitlab` ainsi que tous ses sous-charts, à l'exception de `webservice` et `sidekiq`.

`nodeAffinity` n'implémente que l'[opérateur `In`](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#operators).

L'exemple suivant définit `affinity`, avec `nodeAffinity` et `antiAffinity` tous deux définis sur `hard` :

```yaml
nodeAffinity: "hard"
antiAffinity: "hard"
affinity:
  nodeAffinity:
    key: "test.com/zone"
    values:
    - us-east1-a
    - us-east1-b
  podAntiAffinity:
    topologyKey: "test.com/hostname"
```
