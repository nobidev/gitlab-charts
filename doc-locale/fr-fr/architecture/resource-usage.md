---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation des ressources
---

## Demandes de ressources {#resource-requests}

Tous nos conteneurs incluent des valeurs de demande de ressources prédéfinies. Par défaut, nous n'avons pas mis en place de limites de ressources. Si vos nœuds ne disposent pas d'une capacité mémoire excédentaire, une option consiste à appliquer des limites de mémoire, bien qu'il soit préférable d'ajouter plus de mémoire (ou des nœuds). (Vous souhaitez éviter de manquer de mémoire sur l'un de vos nœuds Kubernetes, car le [gestionnaire de mémoire insuffisante](https://www.kernel.org/doc/gorman/html/understand/understand016.html) du noyau Linux peut mettre fin à des processus Kube essentiels)

Afin de définir nos valeurs de demande par défaut, nous exécutons l'application et trouvons un moyen de générer différents niveaux de charge pour chaque service. Nous surveillons le service et décidons de ce que nous pensons être la meilleure valeur par défaut.

Nous mesurerons :

- **Idle Load** \- Aucune valeur par défaut ne doit être inférieure à ces valeurs, mais un processus inactif n'est pas utile, donc en règle générale nous ne définirons pas de valeur par défaut basée sur cette valeur.

- **Minimal Load** \- Les valeurs requises pour effectuer la quantité de travail utile la plus basique. En règle générale, pour le CPU, cette valeur sera utilisée comme valeur par défaut, mais les demandes de mémoire comportent le risque que le noyau supprime des processus, nous éviterons donc de l'utiliser comme valeur de mémoire par défaut.

- **Average Loads** \- Ce qui est considéré comme *moyen* dépend fortement de l'installation ; pour nos valeurs par défaut, nous tenterons de prendre quelques mesures à quelques-uns de ce que nous considérons comme des charges raisonnables. (nous listerons les charges utilisées). Si le service dispose d'un autoscaler de pods, nous essaierons généralement de définir la valeur cible de mise à l'échelle en fonction de ceux-ci. Et aussi les demandes de mémoire par défaut.

- **Stressful Task** \- Mesurer l'utilisation de la tâche la plus stressante que le service doit effectuer. (Pas nécessairement sous charge). Lors de l'application de limites de ressources, essayez de définir la limite au-dessus de cette valeur et des valeurs de charge moyenne.

- **Heavy Load** \- Essayez de concevoir un test de stress pour le service, puis mesurez l'utilisation des ressources nécessaire pour le réaliser. Nous n'utilisons actuellement pas ces valeurs pour les valeurs par défaut, mais les utilisateurs souhaiteront probablement définir des limites de ressources quelque part entre les charges moyennes/tâches stressantes et cette valeur.

### GitLab Shell {#gitlab-shell}

La charge a été testée à l'aide d'une boucle bash appelant `nohup git clone <project> <random-path-name>` afin d'avoir une certaine simultanéité. Dans les tests futurs, nous essaierons d'inclure une charge simultanée soutenue, afin de mieux correspondre aux types de tests que nous avons effectués pour les autres services.

- **Idle values**
  - 0 tâche, 2 pods
    - cpu : 0
    - mémoire : `5M`
- **Minimal Load**
  - 1 tâche (un clone vide), 2 pods
    - cpu : 0
    - mémoire : `5M`
- **Average Loads**
  - 5 clones simultanés, 2 pods
    - cpu : `100m`
    - mémoire : `5M`
  - 20 clones simultanés, 2 pods
    - cpu : `80m`
    - mémoire : `6M`
- **Stressful Task**
  - Clone SSH du noyau Linux (17 Mo/s)
    - cpu : `280m`
    - mémoire : `17M`
  - Push SSH du noyau Linux (2 Mo/s)
    - cpu : `140m`
    - mémoire : `13M`
    - *La vitesse de connexion en upload était probablement un facteur lors de nos tests*
- **Heavy Load**
  - 100 clones simultanés, 4 pods
    - cpu : `110m`
    - mémoire : `7M`
- **Default Requests**
  - cpu : 0 (à partir de la charge minimale)
  - mémoire : `6M` (à partir de la charge moyenne)
  - moyenne CPU cible : `100m` (à partir des charges moyennes)
- **Recommended Limits**
  - cpu : > `300m` (supérieur à la tâche stressante)
  - mémoire : > `20M` (supérieur à la tâche stressante)

Consultez la [documentation de dépannage](../troubleshooting/_index.md#git-over-ssh-the-remote-end-hung-up-unexpectedly) pour plus de détails sur ce qui pourrait se passer si `gitlab.gitlab-shell.resources.limits.memory` est défini trop bas.

### Webservice {#webservice}

Les ressources Webservice ont été analysées lors des tests avec l'[architecture de référence à 10 000 utilisateurs](https://docs.gitlab.com/administration/reference_architectures/10k_users/). Les notes peuvent être consultées dans la [documentation sur les ressources Webservice](../charts/gitlab/webservice/_index.md#resources).

### Sidekiq {#sidekiq}

Les ressources Sidekiq ont été analysées lors des tests avec l'[architecture de référence à 10 000 utilisateurs](https://docs.gitlab.com/administration/reference_architectures/10k_users/). Les notes peuvent être consultées dans la [documentation sur les ressources Sidekiq](../charts/gitlab/sidekiq/_index.md#resources).

### KAS {#kas}

Jusqu'à ce que nous en apprenions davantage sur les besoins de nos utilisateurs, nous nous attendons à ce que nos utilisateurs utilisent KAS de la manière suivante.

- **Idle values**
  - 0 agent connecté, 2 pods
    - cpu : `10m`
    - mémoire : `55M`
- **Minimal Load** :
  - 1 agent connecté, 2 pods
    - cpu : `10m`
    - mémoire : `55M`
- **Average Load** : 1 agent est connecté au cluster.
  - 5 agents connectés, 2 pods
    - cpu : `10m`
    - mémoire : `65M`
- **Stressful Task** :
  - 20 agents connectés, 2 pods
    - cpu : `30m`
    - mémoire : `95M`
- **Heavy Load** :
  - 50 agents connectés, 2 pods
    - cpu : `40m`
    - mémoire : `150M`
- **Extra Heavy Load** :
  - 200 agents connectés, 2 pods
    - cpu : `50m`
    - mémoire : `315M`

Les valeurs par défaut des ressources KAS définies par ce chart sont plus que suffisantes pour gérer même le scénario de 50 agents. Si vous prévoyez d'atteindre ce que nous considérons comme une **Extra Heavy Load**, vous devriez envisager d'ajuster la valeur par défaut pour effectuer une mise à l'échelle.

- **Defaults** : 2 pods, chacun avec
  - cpu : `100m`
  - mémoire : `100M`

Pour plus d'informations sur la façon dont ces chiffres ont été calculés, consultez la [discussion du ticket](https://gitlab.com/gitlab-org/gitlab/-/issues/296789#note_542196438).
