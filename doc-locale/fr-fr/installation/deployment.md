---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Déployer le chart Helm GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Avant d'exécuter `helm install`, vous devez prendre certaines décisions concernant la façon dont vous allez exécuter GitLab. Les options peuvent être spécifiées à l'aide de l'option de ligne de commande `--set option.name=value` de Helm. Ce guide couvre les valeurs requises et les options courantes. Pour une liste complète des options, consultez [Options de ligne de commande d'installation](command-line-options.md).

> [!note]
> Le chart Helm GitLab nécessite PostgreSQL externe, Redis et un stockage d'objets pour les déploiements en production. Les versions intégrées de ces services sont incluses à des fins d'évaluation uniquement. Pour la production, suivez l'[architecture de référence Cloud Native Hybrid](_index.md#use-the-reference-architectures).

Pour un déploiement en production, vous devez avoir une solide connaissance pratique de Kubernetes. Cette méthode de déploiement implique des concepts de gestion et d'observabilité différents des déploiements traditionnels.

## Déployer avec Helm {#deploy-using-helm}

Une fois que vous avez rassemblé toutes vos options de configuration, nous pouvons récupérer les dépendances et exécuter Helm. Dans cet exemple, nous avons nommé notre release Helm `gitlab`.

```shell
helm repo add gitlab https://charts.gitlab.io/
helm repo update
helm upgrade --install gitlab gitlab/gitlab \
  --timeout 600s \
  --set global.hosts.domain=example.com \
  --set global.hosts.externalIP=10.10.10.10 \
  --set certmanager-issuer.email=me@example.com
```

Notez ce qui suit :

- Toutes les commandes Helm sont spécifiées en utilisant la syntaxe Helm v3.
- Helm v3 exige que le nom de la release soit spécifié en tant qu'argument positionnel sur la ligne de commande, sauf si l'option `--generate-name` est utilisée.
- Helm v3 exige de spécifier une durée avec une unité ajoutée à la valeur (par ex. `120s` = `2m` et `210s` = `3m30s`). L'option `--timeout` est traitée comme un nombre de secondes sans spécification d'unité.
- L'utilisation de l'option `--timeout` peut être trompeuse dans la mesure où plusieurs composants sont déployés lors d'une installation ou d'une mise à niveau Helm à laquelle `--timeout` est appliqué. La valeur `--timeout` est appliquée à l'installation de chaque composant individuellement et non à l'installation de l'ensemble des composants. Ainsi, l'intention d'annuler l'installation Helm après 3 minutes en utilisant `--timeout=3m` peut entraîner la fin de l'installation après 5 minutes, car aucun des composants installés n'a pris plus de 3 minutes à installer.

Vous pouvez également utiliser l'option `--version <installation version>` si vous souhaitez installer une version spécifique de GitLab.

Pour les correspondances entre les versions de chart et les versions de GitLab, consultez [les correspondances de versions GitLab](version_mappings.md).

Les instructions d'installation d'une branche de développement plutôt qu'une release taguée se trouvent dans la [documentation de déploiement développeur](../development/deploy.md).

## Vérification de l'intégrité et de l'origine des charts Helm GitLab {#verifying-the-integrity-and-origin-of-gitlab-helm-charts}

Vous pouvez vérifier l'intégrité et l'origine des charts Helm GitLab en utilisant [Helm provenance](https://helm.sh/docs/topics/provenance/). Pour plus d'informations, consultez [la provenance du chart Helm GitLab](chart-provenance.md).

## Surveillance du déploiement {#monitoring-the-deployment}

La liste des ressources installées s'affichera une fois le déploiement terminé, ce qui peut prendre 5 à 10 minutes.

Le statut du déploiement peut être vérifié en exécutant `helm status gitlab`, ce qui peut également être fait pendant que le déploiement est en cours si vous exécutez la commande dans un autre terminal.

## Connexion initiale {#initial-login}

Vous pouvez accéder à l'instance GitLab en visitant le domaine spécifié lors de l'installation. Le domaine par défaut serait `gitlab.example.com`, sauf si les [paramètres d'hôte globaux](../charts/globals.md#configure-host-settings) ont été modifiés. Si vous avez créé manuellement le secret pour le mot de passe root initial, vous pouvez l'utiliser pour vous connecter en tant qu'utilisateur `root`. Sinon, GitLab aurait automatiquement créé un mot de passe aléatoire pour l'utilisateur `root`. Ce mot de passe peut être extrait par la commande suivante (remplacez `<name>` par le nom de la release - qui est `gitlab` si vous avez utilisé la commande ci-dessus).

```shell
kubectl get secret <name>-gitlab-initial-root-password -ojsonpath='{.data.password}' | base64 --decode ; echo
```

## Déployer la Community Edition {#deploy-the-community-edition}

Par défaut, les charts Helm utilisent l'Enterprise Edition de GitLab. L'Enterprise Edition est une version open core gratuite de GitLab avec la possibilité de passer à un niveau payant pour débloquer des fonctionnalités supplémentaires. Si vous le souhaitez, vous pouvez utiliser à la place la Community Edition, qui est sous licence MIT Expat.

*Pour déployer la Community Edition, incluez cette option dans votre commande d'installation Helm :*

```shell
--set global.edition=ce
```

## Convertir la Community Edition en Enterprise Edition {#convert-community-edition-to-enterprise-edition}

Si vous avez [déployé la Community Edition](#deploy-the-community-edition) et souhaitez passer à l'Enterprise Edition, vous devez redéployer GitLab sans spécifier `--set global.edition=ce`. Si vous avez également spécifié des images individuelles (par exemple, `--set gitlab.unicorn.image.repository=registry.gitlab.com/gitlab-org/build/cng/gitlab-unicorn-ce`), vous devez omettre toute occurrence de ces images.

Après le déploiement, vous pouvez [activer votre licence Enterprise Edition](https://docs.gitlab.com/administration/license/).

## Prochaines étapes recommandées {#recommended-next-steps}

Après avoir terminé votre installation, envisagez de suivre les [prochaines étapes recommandées](https://docs.gitlab.com/install/next_steps/), notamment les options d'authentification et les restrictions d'inscription.
