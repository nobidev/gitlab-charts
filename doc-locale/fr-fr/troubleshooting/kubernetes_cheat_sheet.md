---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Aide-mémoire Kubernetes
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Voici une liste d'informations utiles concernant Kubernetes que l'équipe Support de GitLab utilise parfois lors du dépannage. GitLab rend ces informations publiques afin que chacun puisse bénéficier des connaissances collectées par l'équipe Support.

> [!warning] Ces commandes **can alter or break** vos composants Kubernetes. Utilisez-les à vos propres risques.

Si vous bénéficiez d'un [niveau payant](https://about.gitlab.com/pricing/) et que vous n'êtes pas sûr(e) de savoir comment utiliser ces commandes, il est préférable de [contacter le Support](https://support.gitlab.com/hc/en-us/articles/11626483177756-GitLab-Support), qui vous aidera à résoudre tout problème que vous rencontrez.

## Commandes Kubernetes génériques {#generic-kubernetes-commands}

- Comment s'authentifier auprès de votre projet GCP (peut être particulièrement utile si vous avez des projets sous différents comptes GCP) :

  ```shell
  gcloud auth login
  ```

- Comment accéder au tableau de bord Kubernetes :

  ```shell
  # for minikube:
  minikube dashboard —url
  # for non-local installations if access via Kubectl is configured:
  kubectl proxy
  ```

- Comment se connecter en SSH à un nœud Kubernetes et accéder au conteneur en tant que root <https://github.com/kubernetes/kubernetes/issues/30656> :
  - Pour GCP, vous pouvez trouver le nom du nœud et exécuter `gcloud compute ssh node-name`.
  - Listez les conteneurs à l'aide de `docker ps`.
  - Accédez au conteneur à l'aide de `docker exec --user root -ti container-id bash`.
- Comment copier un fichier d'une machine locale vers un pod :

  ```shell
  kubectl cp file-name pod-name:./destination-path
  ```

- Que faire avec les pods ayant le statut `CrashLoopBackoff` :
  - Vérifiez les journaux via le tableau de bord Kubernetes.
  - Vérifiez les journaux via Kubectl :

    ```shell
    kubectl logs <webservice pod> -c dependencies
    ```

- Comment suivre en temps réel tous les événements du cluster Kubernetes :

  ```shell
  kubectl get events -w --all-namespaces
  ```

- Comment obtenir les journaux de l'instance de pod précédemment terminée :

  ```shell
  kubectl logs <pod-name> --previous
  ```

  Aucun journal n'est conservé dans les conteneurs/pods eux-mêmes. Tout est écrit dans `stdout`. C'est le principe de Kubernetes. Consultez [Twelve-factor app](https://12factor.net/) pour plus de détails.

- Comment obtenir les cron jobs configurés sur un cluster

  ```shell
  kubectl get cronjobs
  ```

  Lorsqu'on configure des [sauvegardes basées sur cron](../backup-restore/backup.md#cron-based-backup), vous pourrez voir le nouveau calendrier ici. Des détails sur les planifications peuvent être trouvés dans [Running Automated Tasks with a CronJob](https://kubernetes.io/docs/tasks/job/automated-tasks-with-cron-jobs/#creating-a-cron-job)

## Informations Kubernetes spécifiques à GitLab {#gitlab-specific-kubernetes-information}

- Suivi des journaux d'un pod distinct. Exemple pour un pod `webservice` :

  ```shell
  kubectl logs gitlab-webservice-54fbf6698b-hpckq -c webservice
  ```

- Suivre tous les pods partageant un label (dans ce cas, `webservice`) :

  ```shell
  # all containers in the webservice pods
  kubectl logs -f -l app=webservice --all-containers=true --max-log-requests=50

  # only the webservice containers in all webservice pods
  kubectl logs -f -l app=webservice -c webservice --max-log-requests=50
  ```

- Il est possible de diffuser les journaux de tous les conteneurs à la fois, de façon similaire à la commande `gitlab-ctl tail` dans une installation de paquet Linux :

  ```shell
  kubectl logs -f -l release=gitlab --all-containers=true --max-log-requests=100
  ```

- Vérifiez tous les événements dans l'espace de nommage `gitlab` (le nom de l'espace de nommage peut être différent si vous en avez spécifié un autre lors du déploiement du chart Helm) :

  ```shell
  kubectl get events -w --namespace=gitlab
  ```

- La plupart des outils GitLab utiles (console, tâches Rake, etc.) se trouvent dans le pod toolbox. Vous pouvez y accéder et exécuter des commandes à l'intérieur, ou les exécuter depuis l'extérieur.

  ```shell
  # find the pod
  kubectl --namespace gitlab get pods -lapp=toolbox

  # open the Rails console
  kubectl --namespace gitlab exec -it -c toolbox <toolbox-pod-name> -- gitlab-rails console

  # run GitLab check. The output can be confusing and invalid because of the specific structure of GitLab installed via helm chart
  gitlab-rake gitlab:check

  # open console without entering pod
  kubectl exec -it <toolbox-pod-name> -- gitlab-rails console

  # check the status of DB migrations
  kubectl exec -it <toolbox-pod-name> -- gitlab-rake db:migrate:status
  ```

- Dépannage de l'intégration **Infrastructure > Clusters Kubernetes** :
  - Vérifiez la sortie de `kubectl get events -w --all-namespaces`.
  - Vérifiez les journaux des pods dans l'espace de nommage `gitlab-managed-apps`.
- Comment obtenir votre [mot de passe administrateur initial](../installation/deployment.md#initial-login) :

  ```shell
  # find the name of the secret containing the password
  kubectl get secrets | grep initial-root
  # decode it
  kubectl get secret <secret-name> -ojsonpath={.data.password} | base64 --decode ; echo
  ```

- Comment se connecter à une base de données PostgreSQL de GitLab.

  ```shell
  kubectl exec -it <toolbox-pod-name> -- gitlab-rails dbconsole --include-password --database main
  ```

- Comment obtenir des informations sur le statut d'installation de Helm :

  ```shell
  helm status <release name>
  ```

- Comment mettre à jour GitLab installé à l'aide d'un chart Helm :

  ```shell
  helm repo update

  # get current values and redirect them to yaml file (analogue of gitlab.rb values)
  helm get values <release name> > gitlab.yaml

  # run upgrade itself
  helm upgrade <release name> <chart path> -f gitlab.yaml
  ```

  Voir aussi [Mettre à jour GitLab à l'aide du chart Helm](../installation/upgrade.md).

- Comment appliquer des modifications à la configuration de GitLab :

  - Modifiez le fichier `gitlab.yaml`.
  - Exécutez la commande suivante pour appliquer les modifications :

    ```shell
    helm upgrade <release name> <chart path> -f gitlab.yaml
    ```

- Comment obtenir le manifeste pour une release. Il peut être utile car il contient les informations sur toutes les ressources Kubernetes et les charts dépendants :

  ```shell
  helm get manifest <release name>
  ```

## Fast-Stats pour les rapports KubeSOS {#fast-stats-for-kubesos-reports}

[KubeSOS](https://gitlab.com/gitlab-com/support/toolbox/kubesos) est un outil qui collecte la configuration du cluster GitLab et les journaux des déploiements de charts GitLab Cloud Native. Vous pouvez utiliser [fast-stats](https://gitlab.com/gitlab-com/support/toolbox/fast-stats), un outil à faible utilisation de mémoire, pour créer et comparer rapidement des statistiques de performance à partir des journaux GitLab.

- Exécutez `fast-stats` :

  ```shell
  cut -d  ' ' -f2- <file-name> | grep ^{ | fast-stats
  ```

- Lister les erreurs :

  ```shell
  cut -d  ' ' -f2- <file-name> | grep ^{ | fast-stats errors
  ```

- Exécutez `fast-stats` top :

  ```shell
  cut -d  ' ' -f2- <file-name> | grep ^{ | fast-stats top
  ```

- Modifiez le nombre de lignes affichées. Par défaut, 10 lignes sont affichées.

  ```shell
  cut -d  ' ' -f2- <file-name> | grep ^{ | fast-stats -l <number of rows>
  ```

## Installation d'une configuration GitLab minimale via minikube sur macOS {#installation-of-minimal-gitlab-configuration-via-minikube-on-macos}

Cette section est basée sur [Developing for Kubernetes with minikube](../development/minikube/_index.md) et [Helm](../installation/tools.md). Référez-vous à ces documents pour plus de détails.

- Installez Kubectl via Homebrew :

  ```shell
  brew install kubernetes-cli
  ```

- Installez minikube via Homebrew :

  ```shell
  brew install minikube
  ```

- Démarrez minikube et configurez-le. Si minikube ne peut pas démarrer, essayez d'exécuter `minikube delete && minikube start` et répétez les étapes :

  ```shell
  minikube start --cpus 3 --memory 8192 # minimum amount for GitLab to work
  minikube addons enable ingress
  ```

- Installez Helm via Homebrew et initialisez-le :

  ```shell
  brew install helm
  ```

- Copiez le [fichier YAML des valeurs minimales pour minikube](https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml) sur votre poste de travail :

  ```shell
  curl --output values.yaml "https://gitlab.com/gitlab-org/charts/gitlab/raw/master/examples/values-minikube-minimum.yaml"
  ```

- Trouvez l'adresse IP dans la sortie de `minikube ip` et mettez à jour le fichier YAML avec cette adresse IP.

- Installez le chart Helm de GitLab :

  ```shell
  helm repo add gitlab https://charts.gitlab.io
  helm install gitlab -f <path-to-yaml-file> gitlab/gitlab
  ```

  Si vous souhaitez modifier certains paramètres de GitLab, vous pouvez utiliser la configuration mentionnée ci-dessus comme base et créer votre propre fichier YAML.

- Surveillez la progression de l'installation via `helm status gitlab` et `minikube dashboard`. L'installation peut prendre jusqu'à 20 à 30 minutes selon la quantité de ressources disponibles sur votre poste de travail.

- Lorsque tous les pods affichent le statut `Running` ou `Completed`, obtenez le mot de passe GitLab comme décrit dans [Initial login](../installation/deployment.md#initial-login), puis connectez-vous à GitLab via l'interface utilisateur. Il sera accessible via `https://gitlab.domain` où `domain` est la valeur fournie dans le fichier YAML.

<!-- ## Troubleshooting

Include any troubleshooting steps that you can foresee. If you know beforehand what issues
one might have when setting this up, or when something is changed, or on upgrading, it's
important to describe those, too. Think of things that may go wrong and include them here.
This is important to minimize requests for support, and to avoid doc comments with
questions that you know someone might ask.

Each scenario can be a third-level heading, e.g. `### Getting error message X`.
If you have none to add when creating a doc, leave this section in place
but commented out to help encourage others to add to it in the future. -->

## Patcher le code Rails dans le pod `toolbox` {#patching-the-rails-code-in-the-toolbox-pod}

> [!warning] Cette tâche n'est pas quelque chose qui devrait être effectuée régulièrement. Utilisez-la à vos propres risques.

Patcher des pods de service GitLab opérationnels nécessite la création de nouvelles images avec le code source modifié à l'intérieur. Ceux-ci ne peuvent _pas_ être directement patchés. Le [pod `toolbox` / `task-runner`](../charts/gitlab/toolbox/_index.md) possède tout ce qui est nécessaire pour fonctionner comme un pod basé sur Rails, sans interférer avec les autres opérations de service normales. Vous pouvez l'utiliser pour exécuter des tâches indépendantes et pour modifier temporairement le code source afin d'effectuer certaines tâches.

> [!note] Si vous apportez des modifications à l'aide du pod `toolbox`, celles-ci ne seront pas persistées si le pod est redémarré. Elles ne sont présentes que pendant la durée de vie de l'opération du conteneur.

Pour patcher le code source dans le pod `toolbox` :

1. Récupérez le fichier `.patch` souhaité à appliquer :

   - Soit téléchargez le diff d'une merge request directement en tant que [fichier patch](https://docs.gitlab.com/user/project/merge_requests/changes/#as-a-patch-file).
   - Ou récupérez le diff directement à l'aide de `curl`. Remplacez `<mr_iid>` ci-dessous par l'IID de la merge request, ou modifiez l'URL pour pointer vers un snippet brut :

     ```shell
     curl --output ~/<mr_iid>.patch "https://gitlab.com/gitlab-org/gitlab/-/merge_requests/<mr_iid>.patch"
     ```

1. Patcher les fichiers locaux sur le pod `toolbox` :

   ```shell
   cd /srv/gitlab
   busybox patch -p1 -f < ~/<mr_iid>.patch
   ```
