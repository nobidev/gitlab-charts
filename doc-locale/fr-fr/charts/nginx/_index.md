---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation de NGINX
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

> [!warning] NGINX Ingress est obsolète et ne recevra plus de correctifs de sécurité après mars 2026. Dans GitLab 19.0, le NGINX Ingress intégré sera désactivé par défaut et sa suppression complète est prévue pour la version 20.0.
>
> Pour plus d'informations, consultez l'[annonce de dépréciation](https://docs.gitlab.com/update/deprecations/#support-for-nginx-ingress). Vous devriez migrer vers la [passerelle Envoy intégrée](../envoygateway/_index.md) ou un [contrôleur Ingress externe](../../advanced/external-ingress/_index.md) dès que possible.

Nous fournissons un déploiement NGINX complet à utiliser comme contrôleur Ingress. Tous les fournisseurs Kubernetes ne prennent pas nativement en charge l'[Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/#tls) NGINX, afin de garantir la compatibilité.

> [!note]
>
> - Le chart NGINX de GitLab est une duplication du chart NGINX Helm en amont. Consultez [Ajustements apportés à la duplication NGINX](#adjustments-to-the-nginx-fork) pour plus de détails sur ce qui a été modifié dans notre duplication.
> - Une seule valeur `global.hosts.domain` est possible. La prise en charge de plusieurs domaines est suivie dans le ticket [3147](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3147).

## Configuration de NGINX {#configuring-nginx}

Consultez la [documentation du chart NGINX](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/charts/nginx-ingress/README.md#configuration) pour les détails de configuration.

### Paramètres globaux {#global-settings}

Nous partageons certains paramètres globaux communs entre nos charts. Consultez la [documentation sur les paramètres globaux](../globals.md) pour les options de configuration communes, telles que les noms d'hôte de GitLab et du registre.

## Configurer les hôtes à l'aide des paramètres globaux {#configure-hosts-using-the-global-settings}

Les noms d'hôte du serveur GitLab et du serveur de registre peuvent être configurés à l'aide de notre chart [Paramètres globaux](../globals.md).

## GitLab Geo {#gitlab-geo}

Un second sous-chart NGINX est intégré et préconfiguré pour le trafic GitLab Geo, qui prend en charge les mêmes paramètres que le contrôleur par défaut. Le contrôleur peut être activé avec `nginx-ingress-geo.enabled=true`.

Ce contrôleur est configuré pour ne pas modifier les en-têtes `X-Forwarded-*` entrants. Assurez-vous de faire de même si vous souhaitez utiliser un fournisseur différent pour le trafic Geo.

La valeur du contrôleur par défaut (`nginx-ingress-geo.controller.ingressClassResource.controllerValue`) est définie sur `k8s.io/nginx-ingress-geo` et le nom de l'IngressClass sur `{ReleaseName}-nginx-geo` afin d'éviter toute interférence avec le contrôleur par défaut. Le nom de l'IngressClass peut être remplacé par `global.geo.ingressClass`.

La gestion des en-têtes personnalisés n'est requise que pour les sites Geo primaires afin de gérer le trafic transmis depuis les sites secondaires. Elle ne doit être utilisée sur les sites secondaires que si le site est sur le point d'être promu en site primaire.

Notez que la modification de l'IngressClass lors d'un basculement entraînera la prise en charge du trafic entrant par l'autre contrôleur. Étant donné que l'autre contrôleur dispose d'une adresse IP d'équilibreur de charge différente, cela peut nécessiter des modifications supplémentaires de votre configuration DNS.

Cela peut être évité en activant le contrôleur Geo Ingress sur tous les sites Geo et en configurant les Ingresses de service web par défaut et supplémentaires pour utiliser l'IngressClass associé (`useGeoClass=true`).

## Liste de blocage des mots de valeur d'annotation {#annotation-value-word-blocklist}

{{< history >}}

- Introduit dans le [chart GitLab Helm 6.6](https://gitlab.com/gitlab-org/charts/gitlab/-/merge_requests/2713).

{{< /history >}}

Dans les situations où les opérateurs de cluster ont besoin d'un plus grand contrôle sur la configuration NGINX générée, le NGINX Ingress autorise les [extraits de configuration](https://kubernetes.github.io/ingress-nginx/examples/customization/configuration-snippets/) qui insèrent des « extraits » de configuration NGINX brute non couverts par les annotations standard et les entrées ConfigMap.

L'inconvénient de ces extraits de configuration est qu'ils permettent aux opérateurs de cluster de déployer des objets Ingress qui incluent des scripts LUA et des configurations similaires susceptibles de compromettre la sécurité de votre installation GitLab et du cluster lui-même, notamment en exposant des jetons de compte de service et des secrets.

Consultez [CVE-2021-25742](https://nvd.nist.gov/vuln/detail/CVE-2021-25742) et [ce problème `ingress-nginx` en amont](https://github.com/kubernetes/ingress-nginx/issues/7837) pour plus de détails.

Afin de remédier à CVE-2021-25742 dans les déploiements de charts Helm de GitLab, nous définissons un [annotation-value-word-blocklist](https://gitlab.com/gitlab-org/charts/gitlab/-/blob/v6.6.0/values.yaml#L836) à l'aide des [paramètres suggérés par la communauté `nginx-ingress`](https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/configmap/#annotation-value-word-blocklist)

Si vous utilisez des extraits de configuration dans votre configuration GitLab Ingress, ou si vous utilisez le contrôleur GitLab NGINX Ingress avec des objets Ingress tiers qui utilisent des extraits de configuration, vous pourriez rencontrer des erreurs `404` lorsque vous tentez d'accéder à vos domaines tiers GitLab, ainsi que des erreurs « mot invalide » dans vos journaux `nginx-controller`. Dans ce cas, examinez et ajustez votre paramètre `nginx-ingress.controller.config.annotation-value-word-blocklist`.

Consultez également [les erreurs « Invalid Word » dans les journaux `nginx-controller` et les erreurs `404` dans notre documentation de dépannage du chart](../../troubleshooting/_index.md#invalid-word-errors-in-the-nginx-controller-logs-and-404-errors).

## Ajustements apportés à la duplication NGINX {#adjustments-to-the-nginx-fork}

> [!note] Notre [duplication](https://gitlab.com/gitlab-org/charts/gitlab/tree/master/charts/nginx-ingress) du chart NGINX a été extraite depuis [GitHub](https://github.com/kubernetes/ingress-nginx).

Les ajustements suivants ont été apportés à la duplication NGINX :

- Prise en charge d'une ConfigMap TCP externe pour exposer GitLab Shell via SSH.
- Diverses modifications pour prendre en charge la configuration globale du chart, telles que les valeurs HPA ou PDB.
- Ne pas utiliser de nouveaux labels de sélecteur pour éviter les interruptions lors des mises à niveau.
- Diverses modifications pour modéliser certains paramètres, requis pour les configurations GitLab Geo avec une URL unifiée.

Consultez le [répertoire source](https://gitlab.com/gitlab-org/charts/gitlab/-/tree/master/scripts/nginx-patches) pour tous les correctifs appliqués à la duplication.
