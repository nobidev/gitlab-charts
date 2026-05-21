---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Mettre à niveau les instances du chart Helm GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Mettez à niveau une instance du chart Helm GitLab vers une version ultérieure de GitLab.

## Prérequis {#prerequisites}

Avant de mettre à niveau une instance du chart Helm GitLab :

1. Consultez les [informations nécessaires avant la mise à niveau](https://docs.gitlab.com/update/plan_your_upgrade/).
1. Les versions du chart Helm GitLab ne suivent pas la même numérotation que les versions de GitLab. Consultez les [correspondances de versions](version_mappings.md) pour trouver la version du chart Helm GitLab dont vous avez besoin.
1. Consultez le [CHANGELOG](https://gitlab.com/gitlab-org/charts/gitlab/blob/master/CHANGELOG.md) correspondant à la release spécifique vers laquelle vous souhaitez effectuer la mise à niveau.
1. Si vous effectuez une mise à niveau à partir d'une version du chart Helm GitLab antérieure à la version 8.x, consultez les [archives de la documentation GitLab](https://docs.gitlab.com/archives/) pour accéder aux anciennes versions de la documentation.
1. Effectuez une [sauvegarde](../backup-restore/_index.md).

## Mettre à niveau une instance du chart Helm GitLab {#upgrade-a-gitlab-helm-chart-instance}

Pour mettre à niveau une instance du chart Helm GitLab :

1. Envisagez d'[activer le mode maintenance](https://docs.gitlab.com/administration/maintenance_mode/) pendant la mise à niveau pour restreindre les opérations d'écriture des utilisateurs et éviter de perturber les workflows.
1. [Mettez à niveau GitLab Runner](https://docs.gitlab.com/runner/install/) vers la même version que votre version cible de GitLab.
1. Extrayez les valeurs que vous avez précédemment fournies :

   ```shell
   helm get values gitlab > gitlab.yaml
   ```

1. Déterminez toutes les valeurs que vous devez conserver lors de la mise à niveau. Vous ne devez conserver qu'un ensemble minimal de valeurs que vous souhaitez définir explicitement et les transmettre au cours du processus de mise à niveau. Dans les autres cas, vous devez vous appuyer sur les valeurs par défaut de GitLab.

### Mise à niveau sans interruption de service {#upgrade-with-zero-downtime}

Mettez à niveau un environnement GitLab en production sans le mettre hors ligne.

#### Exigences {#requirements}

Le processus de mise à niveau sans interruption de service requiert :

- Un déploiement multi-nœuds du chart Helm GitLab avec plusieurs réplicas configurés pour Webservice et Sidekiq.
- Effectuez la mise à niveau d'une version mineure à la fois. Par exemple, de la version 18.0 à la version 18.1, et non à la version 18.2. Si vous ignorez des releases, les modifications de la base de données risquent d'être exécutées dans le mauvais ordre et de laisser le schéma de la base de données dans un état défaillant.

#### Considérations {#considerations}

Avant d'envisager une mise à niveau sans interruption de service, tenez compte des points suivants :

- Gitaly sur Kubernetes prend en charge les mises à niveau sans interruption de service [grâce aux nouvelles tentatives du client](https://docs.gitlab.com/administration/settings/gitaly_timeouts/#gitaly-client-retries).
- La plupart du temps, vous pouvez effectuer en toute sécurité la mise à niveau d'une version de patch vers la version mineure suivante si la version de patch n'est pas la dernière. Par exemple, la mise à niveau de la version 18.0.5 à la version 18.1.0 devrait être sûre même si la version 18.0.6 existe. Nous vous recommandons de consulter les notes de [mise à niveau spécifiques à la version](https://docs.gitlab.com/update/versions/) pour la version vers laquelle vous effectuez la mise à niveau.
- Assurez-vous que votre déploiement dispose de ressources suffisantes pour exécuter simultanément les anciens et les nouveaux pods pendant la mise à jour progressive. La quantité de ressources supplémentaires requises dépend de vos paramètres maxSurge. Par exemple, avec maxSurge :  10 %, vous avez besoin d'une capacité supplémentaire de 10 % pour les nouveaux pods.

#### Paramètres de déploiement recommandés {#recommended-deployment-settings}

Pour garantir des mises à jour progressives sans heurts, les paramètres ci-dessous sont nécessaires pour contrôler le processus de mise à niveau et atteindre un fonctionnement sans interruption de service.

Ces paramètres constituent des recommandations de base. Vous devrez les ajuster en fonction de la disponibilité des ressources de votre déploiement, du nombre de réplicas et des exigences de performances. Assurez-vous de disposer de ressources de cluster suffisantes pour prendre en charge le paramètre `maxSurge`, qui crée temporairement des pods supplémentaires lors d'une mise à niveau.

> [!warning]
> Si vous disposez d'un déploiement GitLab existant sans ces paramètres de mise à jour progressive configurés, vous devez les appliquer avant de tenter une mise à niveau sans interruption de service. L'application de ces paramètres pour la première fois déclenche un redémarrage progressif de vos pods, ce qui peut provoquer de brèves interruptions de service.
>
> Pour minimiser l'impact, appliquez ces paramètres pendant une fenêtre de maintenance avant votre mise à niveau planifiée. Une fois configurées, les futures mises à niveau pourront être effectuées sans interruption de service.

  ```yaml
  global:
    extraEnv:
      BYPASS_SCHEMA_VERSION: true
  gitlab:
    webservice:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 60
    sidekiq:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 600
    gitlab-shell:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 60
    registry:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 60

  nginx-ingress:
    controller:
      deployment:
        strategy:
          type: RollingUpdate
          rollingUpdate:
            maxSurge: "10%"
            maxUnavailable: 0
      terminationGracePeriodSeconds: 300
      minReadySeconds: 10
  ```

> [!note]
> Lors de la configuration de `terminationGracePeriodSeconds` pour Sidekiq, vous devrez prendre en compte vos jobs dont l'exécution est la plus longue afin de vous assurer qu'ils disposent de suffisamment de temps pour se terminer avant l'expiration de la période de grâce.

Ces paramètres garantissent :

- Qu'au moins un pod est toujours disponible pendant les mises à jour.
- Que les nouveaux pods sont démarrés avant que les anciens ne soient arrêtés.
- Que les pods disposent du temps nécessaire pour s'arrêter progressivement et vider les connexions.
- Que les pods sont stables avant d'être considérés comme prêts.

#### Processus de mise à niveau {#upgrade-process}

> [!note]
> Les noms de déploiement utilisés ci-dessous sont des exemples basés sur une installation par défaut du chart Helm GitLab. Les noms de déploiement peuvent varier en fonction de votre configuration, par exemple lors du déploiement de plusieurs files d'attente Sidekiq.
>
> Pour trouver les noms de déploiement corrects pour votre installation :
>
> ```shell
> kubectl get deployments -lapp=webservice -n <namespace>
> kubectl get deployments -lapp=sidekiq -n <namespace>
> ```

Pour mettre à niveau GitLab :

1. Suspendez les déploiements :

   ```shell
   kubectl rollout pause deployment/gitlab-webservice-default
   kubectl rollout pause deployment/gitlab-sidekiq-all-in-1-v2
   ```

1. Démarrez la mise à niveau vers la nouvelle version :

   ```shell
   helm upgrade gitlab gitlab/gitlab \
   --version <GitLab Helm chart version> \
   -f values.yaml \
   --set gitlab.migrations.extraEnv.SKIP_POST_DEPLOYMENT_MIGRATIONS=true
   ```

1. Attendez la fin des pré-migrations et des mises à niveau :

   ```shell
   kubectl get jobs -lrelease=gitlab,chart=migrations-<GitLab version> -n <namespace>
   kubectl wait --for=condition=complete job/<job name> --timeout=600s
   ```

1. Reprenez les déploiements pour Sidekiq :

   ```shell
   kubectl rollout resume deployment/gitlab-sidekiq-all-in-1-v2
   kubectl rollout status deployment/gitlab-sidekiq-all-in-1-v2 --timeout=15m
   ```

1. Reprenez les déploiements pour Webservice :

   ```shell
   kubectl rollout resume deployment/gitlab-webservice-default
   kubectl rollout status deployment/gitlab-webservice-default --timeout=15m
   ```

1. Exécutez les post-migrations :

   ```shell
   helm upgrade gitlab gitlab/gitlab \
   --version <GitLab Helm chart version> \
   -f values.yaml
   ```

1. Attendez la fin des post-migrations :

   ```shell
   kubectl get jobs -lrelease=gitlab,chart=migrations-<GitLab version> -n <namespace>
   kubectl wait --for=condition=complete job/<job name> --timeout=600s
   ```

   > [!note]
   > Selon votre déploiement, un délai d'attente de `600s` pour que les migrations se terminent peut ne pas être suffisant. Vous pouvez augmenter ce délai d'expiration selon vos besoins ou vérifier périodiquement l'état du job pour vous assurer qu'il est terminé avant de passer à l'étape suivante.

### Mise à niveau avec interruption de service {#upgrade-with-downtime}

1. Effectuez la mise à niveau, avec les valeurs extraites et vérifiées lors des étapes précédentes :

   ```shell
   helm upgrade gitlab gitlab/gitlab \
   --version <new version> \
   -f gitlab.yaml \
   --set gitlab.migrations.enabled=true \
   --set ...
   ```

   Lors d'une mise à niveau majeure de la base de données, vous devez définir `gitlab.migrations.enabled` sur `false`. Assurez-vous de le redéfinir explicitement sur `true` pour les futures mises à jour.

## Après la mise à niveau {#after-you-upgrade}

1. Si activé, [désactivez le mode maintenance](https://docs.gitlab.com/administration/maintenance_mode/#disable-maintenance-mode).
1. Exécutez les [vérifications d'intégrité après la mise à niveau](https://docs.gitlab.com/update/plan_your_upgrade/#run-upgrade-health-checks).

## Sujets connexes {#related-topics}

1. [Mises à niveau sans interruption de service pour les installations de packages Linux](https://docs.gitlab.com/update/zero_downtime/)
1. [Chemins de mise à niveau](https://docs.gitlab.com/update/upgrade_paths/)
1. [Notes de mise à niveau GitLab](https://docs.gitlab.com/update/versions/)
