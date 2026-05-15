---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Migrer du chart Helm vers le paquet Linux
---

{{< details >}}

- Édition :  version gratuite, GitLab Premium, GitLab Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Pour migrer d'une installation Helm vers une installation de paquet Linux (Omnibus) :

1. Dans le coin supérieur droit, sélectionnez **Admin**.
2. Dans la barre latérale gauche, sélectionnez **Vue d'ensemble > Composants** pour vérifier votre version actuelle de GitLab.
3. Préparez une machine propre et [installez le paquet Linux](https://docs.gitlab.com/update/package/) correspondant à la version de votre chart Helm GitLab.
4. [Vérifiez l'intégrité des dépôts Git](https://docs.gitlab.com/administration/raketasks/check/) sur votre instance de chart Helm GitLab avant la migration.
5. Créez [une sauvegarde de votre instance de chart Helm GitLab](../../backup-restore/backup.md) et assurez-vous de [sauvegarder les secrets](../../backup-restore/backup.md#back-up-the-secrets).
6. Sauvegardez `/etc/gitlab/gitlab-secrets.json` sur votre instance de paquet Linux.
7. Installez l'outil [yq](https://github.com/mikefarah/yq) (version 4.21.1 ou ultérieure) sur le poste de travail où vous exécutez des commandes `kubectl`.
8. Créez une copie de votre fichier `/etc/gitlab/gitlab-secrets.json` sur votre poste de travail.
9. Exécutez la commande suivante pour obtenir les secrets de votre instance de chart Helm GitLab. Remplacez `GITLAB_NAMESPACE` et `RELEASE` par les valeurs appropriées :

   ```shell
   kubectl get secret -n GITLAB_NAMESPACE RELEASE-rails-secret -ojsonpath='{.data.secrets\.yml}' | yq '@base64d | from_yaml | .production' -o json > rails-secrets.json
   yq eval-all 'select(filename == "gitlab-secrets.json").gitlab_rails = select(filename == "rails-secrets.json") | select(filename == "gitlab-secrets.json")' -ojson  gitlab-secrets.json rails-secrets.json > gitlab-secrets-updated.json
   ```

10. Le résultat est `gitlab-secrets-updated.json`, que vous pouvez utiliser pour remplacer l'ancienne version de `/etc/gitlab/gitlab-secrets.json` sur votre instance de paquet Linux.
11. Après avoir remplacé `/etc/gitlab/gitlab-secrets.json`, reconfigurez votre instance de paquet Linux :

   ```shell
   sudo gitlab-ctl reconfigure
   ```

12. Dans l'instance de paquet Linux, configurez le [stockage d'objets](https://docs.gitlab.com/administration/object_storage/) et assurez-vous qu'il fonctionne en testant LFS (Large File Storage), les artefacts, les importations, etc.
13. Si vous utilisez le registre de conteneurs, [configurez son stockage d'objets séparément](https://docs.gitlab.com/administration/packages/container_registry/#use-object-storage). Il ne prend pas en charge le stockage d'objets consolidé.
14. Synchronisez les données de votre stockage d'objets connecté à l'instance du chart Helm avec le nouveau stockage connecté à l'instance du paquet Linux. Quelques remarques :

   - Pour les stockages compatibles S3, utilisez l'utilitaire `s3cmd` pour copier les données.
   - Si vous prévoyez d'utiliser un stockage d'objets compatible S3 comme MinIO avec votre instance de paquet Linux, vous devez configurer les options `endpoint` pointant vers votre MinIO et définir `path_style` sur `true` dans `/etc/gitlab/gitlab.rb`.
   - Vous pouvez réutiliser votre ancien stockage d'objets avec la nouvelle instance de paquet Linux. Dans ce cas, vous n'avez pas besoin de synchroniser les données entre deux stockages d'objets. Cependant, le stockage pourrait être déprovisionné lorsque vous désinstallez le chart Helm GitLab si vous utilisez l'instance MinIO intégrée.

15. Copiez la sauvegarde Helm GitLab dans `/var/opt/gitlab/backups` sur votre instance GitLab de paquet Linux, puis [effectuez la restauration](https://docs.gitlab.com/administration/backup_restore/restore_gitlab/#restore-for-linux-package-installations).
16. (Facultatif) Restaurez les clés d'hôte SSH pour éviter les erreurs de non-correspondance d'hôte sur les clients Git SSH :

   1. Convertissez le [secret `<name>-gitlab-shell-host-keys`](../secrets.md#ssh-host-keys) en fichiers à l'aide du script suivant (outils requis : `jq`, `base64` et `kubectl`) :

      ```shell
      mkdir ssh
      HOSTKEYS_JSON="hostkeys.json"
      GITLAB_NAMESPACE="my_namespace"
      kubectl get secret -n ${GITLAB_NAMESPACE} gitlab-gitlab-shell-host-keys -o json > ${HOSTKEYS_JSON}

      for k in $(jq -r '.data | keys | .[]' ${HOSTKEYS_JSON}); \
      do \
        jq -r --arg host_key ${k} '.data[$host_key]' ${HOSTKEYS_JSON}  | base64 --decode > ssh/$k ; \
      done
      ```

   2. Importez les fichiers convertis vers les nœuds Rails de GitLab.
   3. Sur le nœud Rails cible :
      1. Sauvegardez le répertoire `/etc/ssh/`, par exemple :

         ```shell
         sudo tar -czvf /root/ssh_dir.tar.gz -C /etc ssh
         ```

      2. Supprimez les clés d'hôte existantes :

         ```shell
         sudo find /etc/ssh -type f -name "/etc/ssh/ssh_*_key*" -delete
         ```

      3. Déplacez les fichiers de clés d'hôte convertis à leur emplacement (`/etc/ssh`) :

         ```shell
         for f in ssh/*; do sudo install -b -D  -o root -g root -m 0600 $f /etc/${f} ; done
         ```

      4. Redémarrez le daemon SSH :

         ```shell
         sudo systemctl restart ssh.service
         ```

17. Une fois la restauration terminée, exécutez les [tâches Rake doctor](https://docs.gitlab.com/administration/raketasks/check/) pour vous assurer que les secrets sont valides.
18. Une fois tout vérifié, vous pouvez [désinstaller](../uninstall.md) l'instance du chart Helm GitLab.
