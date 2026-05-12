---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Restauration d'une installation GitLab"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Pour obtenir une archive tarball de sauvegarde d'une instance GitLab existante qui utilisait d'autres méthodes d'installation comme le package Linux ou le chart Helm GitLab, suivez les instructions [données dans la documentation](https://docs.gitlab.com/administration/backup_restore/backup_gitlab/).

Si vous restaurez une sauvegarde effectuée depuis une autre instance, vous devez migrer votre instance existante vers le stockage d'objets avant d'effectuer la sauvegarde. Consultez [le ticket 646](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/646).

Il est recommandé de restaurer une sauvegarde vers la même version de GitLab sur laquelle elle a été créée.

Les restaurations de sauvegarde GitLab sont effectuées en exécutant la commande `backup-utility` sur le pod Toolbox fourni dans le chart.

Avant d'effectuer la restauration pour la première fois, assurez-vous que le [Toolbox est correctement configuré](_index.md) pour accéder au [stockage d'objets](_index.md#object-storage)

L'utilitaire de sauvegarde fourni par le chart Helm GitLab prend en charge la restauration d'une archive tarball depuis l'un des emplacements suivants

1. Le bucket `gitlab-backups` dans le service de stockage d'objets associé à l'instance. Il s'agit du scénario par défaut.
1. Une URL publique accessible depuis le pod.
1. Un fichier local que vous pouvez copier vers le pod Toolbox à l'aide de `kubectl cp`

## Restauration des secrets {#restoring-the-secrets}

### Restaurer les secrets Rails {#restore-the-rails-secrets}

{{<alert type="note">}}

Les environnements hybrides déployés à l'aide du [GitLab Environment Toolkit (GET)](https://docs.gitlab.com/install/install_methods/#gitlab-environment-toolkit-get) effectuent une synchronisation automatique des secrets entre les nœuds Omnibus et Kubernetes, ce qui doit être pris en compte lors d'une restauration. Reportez-vous à [cette section](https://gitlab.com/gitlab-org/gitlab-environment-toolkit/-/blob/main/docs/environment_post_considerations.md#restores) de la documentation GET pour plus de détails.

{{</alert>}}

Le chart GitLab s'attend à ce que les secrets Rails soient fournis sous forme de Secret Kubernetes avec un contenu en YAML. Si vous restaurez le secret Rails depuis une instance de package Linux, les secrets sont stockés au format JSON dans le fichier `/etc/gitlab/gitlab-secrets.json`. Pour convertir le fichier et créer le secret au format YAML :

1. Copiez le fichier `/etc/gitlab/gitlab-secrets.json` vers le poste de travail où vous exécutez les commandes `kubectl`.
1. Installez l'outil [yq](https://github.com/mikefarah/yq) (version 4.21.1 ou ultérieure) sur votre poste de travail.
1. Exécutez la commande suivante pour convertir votre `gitlab-secrets.json` au format YAML :

   ```shell
   yq -P '{"production": .gitlab_rails}' gitlab-secrets.json -o yaml >> gitlab-secrets.yaml
   ```

1. Vérifiez que le nouveau fichier `gitlab-secrets.yaml` contient les éléments suivants :

   ```YAML
   production:
     db_key_base: <your key base value>
     secret_key_base: <your secret key base value>
     otp_key_base: <your otp key base value>
     openid_connect_signing_key: <your openid signing key>
     active_record_encryption_primary_key:
     - 'your active record encryption primary key'
     active_record_encryption_deterministic_key:
     - 'your active record encryption deterministic key'
     active_record_encryption_key_derivation_salt: 'your active record key derivation salt'
   ```

1. Vérifiez que les secrets multilignes tels que `openid_connect_signing_key` ne contiennent pas de caractères de nouvelle ligne (`\n`). Divisez les secrets multilignes en lignes séparées pour éviter [un problème de décodage](https://gitlab.com/gitlab-org/charts/gitlab/-/issues/3352#note_994430571) lors de leur utilisation par les applications.

Pour restaurer les secrets Rails depuis un fichier YAML :

1. Trouvez le nom d'objet des secrets Rails :

   ```shell
   kubectl get secrets | grep rails-secret
   ```

1. Supprimez le secret existant :

   ```shell
   kubectl delete secret <rails-secret-name>
   ```

1. Créez le nouveau secret en utilisant le même nom que l'ancien, et en transmettant votre fichier YAML local

   ```shell
   kubectl create secret generic <rails-secret-name> --from-file=secrets.yml=gitlab-secrets.yaml
   ```

### Redémarrer les pods {#restart-the-pods}

Pour utiliser les nouveaux secrets, les pods Webservice, Sidekiq et Toolbox doivent être redémarrés. La méthode la plus sûre pour redémarrer ces pods est d'exécuter :

```shell
kubectl delete pods -lapp=sidekiq,release=<helm release name>
kubectl delete pods -lapp=webservice,release=<helm release name>
kubectl delete pods -lapp=toolbox,release=<helm release name>
```

## Restauration du fichier de sauvegarde {#restoring-the-backup-file}

Les étapes de restauration d'une installation GitLab sont

1. Assurez-vous d'avoir une instance GitLab en cours d'exécution en déployant les charts. Assurez-vous que le pod Toolbox est activé et en cours d'exécution en exécutant la commande suivante

   ```shell
   kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
   ```

1. Préparez l'archive tarball dans l'un des emplacements mentionnés ci-dessus. Assurez-vous qu'elle est nommée selon le format `<backup_ID>_gitlab_backup.tar`. Découvrez ce que représente l'[ID de sauvegarde](https://docs.gitlab.com/administration/backup_restore/backup_archive_process/#backup-id).
1. Notez le nombre actuel de réplicas pour les clients de la base de données en vue du redémarrage ultérieur :

   ```shell
   kubectl get deploy -n <namespace> -lapp=sidekiq,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
   kubectl get deploy -n <namespace> -lapp=webservice,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
   kubectl get deploy -n <namespace> -lapp=prometheus,release=<helm release name> -o jsonpath='{.items[].spec.replicas}{"\n"}'
   ```

1. Arrêtez les clients de la base de données pour éviter que des verrous n'interfèrent avec le processus de restauration :

   ```shell
   kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=0
   kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=0
   kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=0
   ```

1. Exécutez l'utilitaire de sauvegarde pour restaurer l'archive tarball

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility --restore -t <backup_ID>
   ```

   Ici, `<backup_ID>` correspond au nom de l'archive tarball stockée dans le bucket `gitlab-backups`. Si vous souhaitez fournir une URL publique, utilisez la commande suivante :

   ```shell
   kubectl exec <Toolbox pod name> -it -- backup-utility --restore -f <URL>
   ```

    Vous pouvez fournir un chemin local comme URL à condition qu'il soit au format : `file:///<path>`

1. Ce processus prendra du temps en fonction de la taille de l'archive tarball.
1. Le processus de restauration effacera le contenu existant de la base de données, déplacera les dépôts existants vers des emplacements temporaires et extraira le contenu de l'archive tarball. Les dépôts seront déplacés vers leurs emplacements correspondants sur le disque et les autres données, telles que les artefacts, les téléchargements, les LFS, etc., seront téléchargées vers les buckets correspondants dans le stockage d'objets.
1. Redémarrez l'application :

   ```shell
   kubectl scale deploy -lapp=sidekiq,release=<helm release name> -n <namespace> --replicas=<value>
   kubectl scale deploy -lapp=webservice,release=<helm release name> -n <namespace> --replicas=<value>
   kubectl scale deploy -lapp=prometheus,release=<helm release name> -n <namespace> --replicas=<value>
   ```

> [!note] Lors de la restauration, l'archive tarball de sauvegarde doit être extraite sur le disque. Cela signifie que le pod Toolbox doit disposer d'un espace disque de taille suffisante. Pour plus de détails et de configuration, veuillez consulter la [documentation Toolbox](../charts/gitlab/toolbox/_index.md#persistence-configuration).

### Restaurer le token d'enregistrement du runner {#restore-the-runner-registration-token}

Après la restauration, le runner inclus ne pourra pas s'enregistrer auprès de l'instance car il ne possède plus le token d'enregistrement correct. Suivez ces [étapes de dépannage](../troubleshooting/_index.md#included-gitlab-runner-failing-to-register) pour le mettre à jour.

## Activer les paramètres liés à Kubernetes {#enable-kubernetes-related-settings}

Si la sauvegarde restaurée ne provenait pas d'une installation existante du chart, vous devrez également activer certaines fonctionnalités spécifiques à Kubernetes après la restauration. Par exemple, la [journalisation incrémentielle des jobs CI](https://docs.gitlab.com/administration/cicd/job_logs/#incremental-logging).

1. Trouvez votre pod Toolbox en exécutant la commande suivante

   ```shell
   kubectl get pods -lrelease=RELEASE_NAME,app=toolbox
   ```

1. Exécutez le script de configuration de l'instance pour activer les fonctionnalités nécessaires

   ```shell
   kubectl exec <Toolbox pod name> -it -- gitlab-rails runner -e production /scripts/custom-instance-setup
   ```

## Redémarrer les pods {#restart-the-pods-1}

Pour utiliser les nouvelles modifications, les pods Webservice et Sidekiq doivent être redémarrés. La méthode la plus sûre pour redémarrer ces pods est d'exécuter :

```shell
kubectl delete pods -lapp=sidekiq,release=<helm release name>
kubectl delete pods -lapp=webservice,release=<helm release name>
```

## (Facultatif) Réinitialiser le mot de passe de l'utilisateur root {#optional-reset-the-root-users-password}

Le processus de restauration ne met pas à jour le secret `gitlab-initial-root-password` avec la valeur de la sauvegarde. Pour vous connecter en tant que `root`, utilisez le mot de passe d'origine inclus dans la sauvegarde. Si le mot de passe n'est plus accessible, suivez les étapes ci-dessous pour le réinitialiser.

1. Attachez-vous au pod Webservice en exécutant la commande

   ```shell
   kubectl exec <Webservice pod name> -it -- bash
   ```

1. Exécutez la commande suivante pour réinitialiser le mot de passe de l'utilisateur `root`. Remplacez `#{password}` par un mot de passe de votre choix

   ```shell
   /srv/gitlab/bin/rails runner "user = User.first; user.password='#{password}'; user.password_confirmation='#{password}'; user.save!"
   ```

## Informations supplémentaires {#additional-information}

- [Introduction à la sauvegarde/restauration du chart GitLab](_index.md)
- [Sauvegarde d'une installation GitLab](backup.md)
