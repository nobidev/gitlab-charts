---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Migrer depuis les charts Redis, PostgreSQL et MinIO intégrés"
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

Lors de la configuration d'un système de production, vous devez migrer depuis Redis, MinIO et PostgreSQL intégrés vers des alternatives gérées en externe.

> [!warning] Les Redis, MinIO et PostgreSQL intégrés sont [obsolètes](https://docs.gitlab.com/update/deprecations/#support-for-bundled-postgresql-redis-and-minio-in-gitlab-helm-chart) et seront supprimés dans GitLab 19.0.

Ce guide suppose que vous migrez vers des alternatives Cloud Native telles que [Valkey](https://valkey.io/) , [Garage](https://garagehq.deuxfleurs.fr/) et [CloudNativePG](https://cloudnative-pg.io/) respectivement.

Ce processus de migration vous demande d'effectuer les étapes suivantes :

- Provisionner des services externes :  Déployez et configurez les services externes de votre choix.
- Sauvegarder vos données :  Créez une sauvegarde de toutes les données des services PostgreSQL et MinIO intégrés.
- Reconfigurer GitLab :  Mettez à jour la configuration de GitLab pour utiliser les services externes à la place des services intégrés.
- Restaurer vers les nouveaux services :  Restaurez vos données de sauvegarde vers les services externes nouvellement provisionnés.
- Nettoyer les anciens services :  Supprimez manuellement les anciens services intégrés et leurs volumes persistants lorsque vous êtes certain que la migration est terminée.

## Avant de commencer {#before-you-begin}

Avant de commencer la migration depuis les services Redis, MinIO ou PostgreSQL intégrés :

- Évaluez les services qui correspondent aux [exigences d'installation](https://docs.gitlab.com/install/requirements/). Envisagez des services de fournisseurs cloud ou d'autres alternatives qui répondent à vos besoins d'infrastructure et à vos exigences organisationnelles. Pour des considérations générales sur l'architecture de référence et les fournisseurs recommandés, consultez la [documentation sur l'architecture de référence](https://docs.gitlab.com/administration/reference_architectures/#recommended-cloud-providers-and-services).
- À la suite de cette migration, la mise à niveau du chart GitLab ne mettra plus à niveau vos déploiements Redis ou PostgreSQL. Les mises à niveau majeures de GitLab peuvent nécessiter des versions plus récentes de Valkey/Redis ou de PostgreSQL. Avant de suivre ce guide, ou avant d'effectuer une mise à niveau majeure de GitLab, vérifiez les [exigences](https://docs.gitlab.com/install/requirements) pour votre version de GitLab.
- Vérifiez la taille actuelle et l'utilisation des données de vos demandes de volumes persistants MinIO, Redis et PostgreSQL. Le guide configure 5 Gio pour PostgreSQL, 2 Gio pour Valkey et 5 Gio (répliqués 3 fois) pour Garage, ce qui peut nécessiter des ajustements.
- Notez que GitLab ne peut pas vous aider avec la configuration ou le dépannage des applications tierces mentionnées dans ce document. Nous pouvons garantir que GitLab lui-même envoie des données correctement formatées à un tiers dans la configuration minimale.
- Planifiez une période d'indisponibilité pour cette migration. Pendant l'importation des données vers les nouveaux services externes, GitLab ne sera pas accessible.

## Sauvegarder GitLab {#backup-gitlab}

Commencez par [sauvegarder](../../backup-restore/_index.md) toutes les données actuelles et notez l'identifiant de la sauvegarde.

Veuillez noter que :

- Si vous migrez MinIO, vous devrez télécharger l'archive de sauvegarde sur une machine locale.
- Si vous ne migrez que MinIO, vous devrez sauvegarder uniquement les compartiments de stockage d'objets.
- Si vous ne migrez que Redis, vous pouvez ignorer les étapes de sauvegarde et de restauration.
- Si vous ne migrez que PostgreSQL, vous pouvez [ignorer](../../backup-restore/backup.md#skipping-components) la sauvegarde de tous les composants sauf `db`.
- Si vous avez activé la [base de données des métadonnées du registre](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/) , les données de métadonnées ne seront pas couvertes par le [processus de sauvegarde/restauration par défaut](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/#backup-with-metadata-database).

## Provisionner des services externes {#provision-external-services}

Pour remplacer les charts Redis, PostgreSQL et MinIO intégrés, provisionnez des remplacements gérés en externe. Pour un aperçu des options disponibles, consultez les [fournisseurs et services recommandés](https://docs.gitlab.com/administration/reference_architectures/#recommended-cloud-providers-and-services) et assurez-vous qu'ils respectent les [exigences minimales actuelles](https://docs.gitlab.com/install/requirements/).

### Provisionner Valkey ou Redis externe {#provision-external-valkey-or-redis}

1. Provisionnez votre service Valkey ou Redis externe. Par exemple, en utilisant le [chart Helm Valkey](https://github.com/valkey-io/valkey-helm) officiel :

   Cela configure une instance Valkey indépendante qui conserve les données entre les redémarrages. Les identifiants d'authentification sont stockés dans un Secret nommé `<RELEASE>-auth`.

   ```shell
   helm repo add valkey https://valkey.io/valkey-helm/
   helm install valkey valkey/valkey -n <NAMESPACE> \
     --set dataStorage.enabled=true \
     --set dataStorage.size=2Gi \
     --set metrics.enabled=true \
     --set auth.enabled=true \
     --set auth.aclUsers.default.permissions="~* &* +@all" \
     --set auth.aclUsers.default.password="<RANDOM PASSWORD>"
   ```

1. Confirmez que Valkey est opérationnel :

   ```script
   $ kubectl get deployment -n <NAMESPACE> -l app.kubernetes.io/name=valkey
   NAME     READY   UP-TO-DATE   AVAILABLE   AGE
   valkey   1/1     1            1           30m
   ```

### Provisionner PostgreSQL externe {#provision-external-postgresql}

Provisionnez votre service PostgreSQL externe. Par exemple, en utilisant [CloudNativePG](https://cloudnative-pg.io/docs/1.28/installation_upgrade) :

1. Installez l'opérateur CloudNativePG :

   ```shell
   kubectl apply --server-side -f https://raw.githubusercontent.com/cloudnative-pg/cloudnative-pg/release-1.28/releases/cnpg-1.28.0.yaml
   ```

1. Provisionnez un cluster PostgreSQL pour GitLab (la [base de données des métadonnées du registre](https://docs.gitlab.com/administration/packages/container_registry_metadata_database/) n'est pas couverte) :

   Consultez l'[API Cluster](https://cloudnative-pg.io/docs/1.28/cloudnative-pg.v1/#postgresqlcnpgiov1) pour personnaliser votre cluster.

   ```yaml
   apiVersion: postgresql.cnpg.io/v1
   kind: Cluster
   metadata:
     name: gitlab-rails-db
     namespace: <NAMESPACE>
   spec:
     instances: 1
     imageName: ghcr.io/cloudnative-pg/postgresql:17
     storage:
       size: 5Gi
     bootstrap:
       initdb:
         database: gitlabhq_production
         owner: gitlab
         postInitSQL:
           - CREATE EXTENSION IF NOT EXISTS pg_trgm;
           - CREATE EXTENSION IF NOT EXISTS btree_gist;
           - CREATE EXTENSION IF NOT EXISTS plpgsql;
           - CREATE EXTENSION IF NOT EXISTS amcheck;
           - CREATE EXTENSION IF NOT EXISTS pg_stat_statements;
   ```

1. Confirmez que le cluster PostgreSQL est en bonne santé :

   ```script
   $ kubectl get clusters -n <NAMESPACE>
   NAME                 AGE   INSTANCES   READY   STATUS                     PRIMARY
   gitlab-rails-db      20m   1           1       Cluster in healthy state   gitlab-rails-db-1
   ```

### Provisionner Garage pour le stockage d'objets externe {#provision-garage-for-external-object-storage}

Pour migrer depuis le MinIO intégré, vous devez provisionner votre propre solution de stockage d'objets externe.

Une option est [Garage](https://garagehq.deuxfleurs.fr/). Avant d'installer Garage, consultez la documentation de Garage pour :

- [Déploiement sur un cluster](https://garagehq.deuxfleurs.fr/documentation/cookbook/real-world/).
- [Déploiement sur Kubernetes](https://garagehq.deuxfleurs.fr/documentation/cookbook/kubernetes/).

Prérequis :

- Version 2.2.0 de l'application Garage.

1. Installez le chart Helm Garage :

   ```shell
   helm plugin install https://github.com/aslafy-z/helm-git
   helm repo add garage "git+https://git.deuxfleurs.fr/Deuxfleurs/garage.git@script/helm?ref=v2.2.0"
   helm install garage garage/garage -n <NAMESPACE> \
     --set persistence.data.size=5Gi \
     --set persistence.meta.size=250Mi
   ```

1. Confirmez que Garage est opérationnel :

   ```shell
   $ kubectl get statefulsets.apps -n garage -l app.kubernetes.io/name=garage
   NAME     READY   AGE
   garage   3/3     36s
   ```

1. Initialisez la disposition du cluster.

   > [!note] Cet exemple provisionne une disposition Garage avec trois zones, un nœud par zone, et utilise le facteur de réplication par défaut de trois. Consultez les [recommandations de production de Garage](https://garagehq.deuxfleurs.fr/documentation/cookbook/real-world/) et ajustez ces paramètres selon vos besoins.

   Étant donné que GitLab stocke à la fois les données d'objets primaires et les sauvegardes dans le même backend de stockage (Garage dans ce cas), toute défaillance au niveau du stockage d'objets ou de la couche de persistance pourrait affecter les deux ensembles de données. Par conséquent, en plus de [sauvegarder GitLab](../../backup-restore/_index.md) régulièrement, vous devriez également vous familiariser avec la [récupération après des défaillances de Garage](https://garagehq.deuxfleurs.fr/documentation/operations/recovering/).

   ```shell
   # Check node IDs
   kubectl exec <GARAGE_POD>  -- /garage status

   # Assign nodes to gitlab zone
   kubectl exec <GARAGE_POD>  -- /garage layout assign -z gitlab1 -c 5G <Node ID 1>
   kubectl exec <GARAGE_POD>  -- /garage layout assign -z gitlab2 -c 5G <Node ID 2>
   kubectl exec <GARAGE_POD>  -- /garage layout assign -z gitlab3 -c 5G <Node ID 3>

   # Apply the layout
   kubectl exec <GARAGE_POD>  -- /garage layout apply --version 1
   ```

1. Créez les compartiments GitLab :

   > [!note] La commande suivante utilise les noms de compartiments par défaut du chart GitLab. Si vous avez personnalisé vos noms de compartiments précédemment, ajustez-les en conséquence ici et dans les étapes ci-dessous.

   ```shell
   buckets=("git-lfs" "gitlab-artifacts" "gitlab-backups" "gitlab-ci-secure-files" \
            "gitlab-dependency-proxy" "gitlab-mr-diffs" "gitlab-packages" "gitlab-pages" \
            "gitlab-terraform-state" "gitlab-uploads" "registry" "runner-cache" "tmp" )
   for bucket in "${buckets[@]}"; do
     kubectl exec -n <NAMESPACE> <GARAGE_POD>  -- /garage bucket create "${bucket}";
   done
   ```

1. Créez une clé API, notez la clé d'accès et la clé secrète, et accordez l'accès aux compartiments créés :

   ```shell
   # Create GitLab key. Note down the access and secret key.
   # For ease of access we can create a variable 'KEY_OUTPUT' and store
   # the output of 'kubectl exec -n <NAMESPACE> <GARAGE_POD>  -- /garage key create gitlab-app-key'
   # and then parse the values for 'GARAGE_ACCESS_KEY' and 'GARAGE_SECRET_KEY'
   local KEY_OUTPUT
   KEY_OUTPUT=$(kubectl exec -n <NAMESPACE> <GARAGE_POD> -- \
       /garage key create gitlab-app-key)

   local GARAGE_ACCESS_KEY GARAGE_SECRET_KEY
   GARAGE_ACCESS_KEY=$(echo "${KEY_OUTPUT}" | grep 'Key ID:' | awk '{print $3}')
   GARAGE_SECRET_KEY=$(echo "${KEY_OUTPUT}" | grep 'Secret key:' | awk '{print $3}')

   # Grant permissions to the GitLab key.
   for bucket in "${buckets[@]}"; do
     kubectl exec -n <NAMESPACE> <GARAGE_POD>  -- /garage bucket allow --read --write --key gitlab-app-key "${bucket}";
   done
   ```

1. Créez un Secret configurant l'accès au stockage d'objets. Assurez-vous de remplacer les espaces réservés `GARAGE_ACCESS_KEY`, `GARAGE_SECRET_KEY` et `NAMESPACE` :

   ```shell
   cat <<EOF | kubectl create secret generic gitlab-object-storage --from-file=config=/dev/stdin
   provider: AWS
   region: garage
   aws_access_key_id: <GARAGE_ACCESS_KEY>
   aws_secret_access_key: <GARAGE_SECRET_KEY>
   endpoint: "http://garage.<NAMESPACE>.svc.cluster.local:3900"
   path_style: true
   EOF
   ```

1. Créez un Secret configurant l'accès pour la sauvegarde/restauration :

   ```shell
   cat <<EOF | kubectl create secret generic gitlab-object-storage-s3cmd --from-file=config=/dev/stdin
   [default]
   access_key = <GARAGE_ACCESS_KEY>
   secret_key = <GARAGE_SECRET_KEY>
   host_base = garage.<NAMESPACE>.svc.cluster.local:3900
   host_bucket = garage.<NAMESPACE>.svc.cluster.local:3900
   use_https = False
   EOF
   ```

1. Créez un Secret configurant l'accès pour le registre :

   ```shell
   cat <<EOF | kubectl create secret generic gitlab-registry-storage --from-file=config=/dev/stdin
   s3:
     accesskey: ${GARAGE_ACCESS_KEY}
     secretkey: ${GARAGE_SECRET_KEY}
     bucket: registry
     region: garage
     regionendpoint: http://garage.${NAMESPACE}.svc.cluster.local:3900
     secure: false
     v4auth: true
     pathstyle: true
   EOF
   ```

## Migrer vers des services externes {#migrate-to-external-services}

Une fois tous les remplacements provisionnés, vous pouvez maintenant désactiver les MinIO, Redis et PostgreSQL intégrés.

1. Assurez-vous que le volume persistant MinIO sera conservé pour l'instant.

   ```yaml
   minio:
     persistence:
       # keep: true # Only available in GitLab chart 9.8+
       annotations:
         helm.sh/resource-policy: "keep"
   ```

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml
   kubectl annotate pvc <RELEASE>-minio --list
   ```

   > [!note] Les volumes persistants Redis et PostgreSQL sont gérés par leur StatefulSet plutôt que par Helm. La politique de rétention par défaut est [`Retain`](https://kubernetes.io/docs/concepts/workloads/controllers/statefulset/#persistentvolumeclaim-retention). Sauf si vous avez modifié cette politique, ces deux volumes ne seront pas supprimés lorsque vous supprimerez leur StatefulSet.

1. Mettez à jour vos valeurs pour pointer vers les services nouvellement provisionnés :

   ```yaml
   global:
     # Configure DB managed by CloudNativePG.
     psql:
       host: gitlab-rails-db-rw.<NAMESPACE>.svc.cluster.local
       password:
        secret: gitlab-rails-db-app
        key: password
     # Configure Valkey service.
     redis:
       host: valkey.<NAMESPACE>.svc.cluster.local
       auth:
        secret: valkey-auth # <VALKEY RELEASE>-auth
        key: default-password
     # Configure Garage as object storage.
     appConfig:
       object_store:
         enabled: true
         # If you aren't exposing Garage through the Ingress Gateway API, set object storage download proxying to true
         proxy_download: true
         connection:
           secret: gitlab-object-storage
           key: config
       # Set to buckets created in Garage. Can be omitted if you used the default bucket names.
       artifacts:
         bucket: gitlab-artifacts
       lfs:
         bucket: git-lfs
       uploads:
         bucket: gitlab-uploads
       packages:
         bucket: gitlab-packages
       externalDiffs:
         enabled: true
         bucket: gitlab-mr-diffs
       terraformState:
         enabled: true
         bucket: gitlab-terraform-state
       ciSecureFiles:
         enabled: true
         bucket: gitlab-ci-secure-files
       dependencyProxy:
         enabled: true
         bucket: gitlab-dependency-proxy
     # Disable bundled MinIO.
     minio:
       enabled: false
   # Configure backup/restore to use Garage backend.
   gitlab:
     toolbox:
       backups:
         objectStorage:
           config:
             secret: gitlab-object-storage-s3cmd
             key: config
   # Disable Registry redirect if not exposing Garage via Ingress/Gateway API
   registry:
     storage:
       secret: gitlab-registry-storage
       key: config
       redirect:
         disable: true
   # Disable bundled PostgreSQL and Redis.
   postgresql:
     install: false
   redis:
     install: false
   ```

   Consultez la documentation associée sur [Redis](../../advanced/external-redis/_index.md) , [PostgreSQL](../../advanced/external-db/_index.md) et le [stockage d'objets](../../advanced/external-object-storage/_index.md) pour plus d'informations.

1. Si vous migrez PostgreSQL, mettez à niveau votre instance GitLab avec les migrations désactivées :

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml --set gitlab.migrations.enabled=false
   ```

1. Si vous migrez MinIO, copiez votre sauvegarde dans la toolbox et téléchargez-la vers votre nouveau stockage d'objets :

   ```shell
   # Find Toolbox Pod
   kubectl get pods -l app=toolbox
   # Copy backup archive to Pod
   kubectl cp LOCAL_BACKUP_ARCHIVE.tar <TOOLBOX_POD>:/tmp
   # Upload archive to backup bucket
   s3cmd put /tmp/LOCAL_BACKUP_ARCHIVE.tar s3://gitlab-backups/
   ```

1. Si vous migrez PostgreSQL ou MinIO, [réduisez les charges de travail et restaurez la sauvegarde](../../backup-restore/restore.md#restoring-the-backup-file).
1. Une fois la mise à niveau terminée, mettez à niveau votre instance GitLab pour exécuter toutes les migrations en attente.

   ```shell
   helm upgrade <RELEASE> gitlab/gitlab -f your-values.yaml
   ```

1. Confirmez que GitLab est opérationnel.
1. Confirmez que les [sauvegardes](../../backup-restore/backup.md) fonctionnent comme prévu en effectuant une nouvelle sauvegarde.
1. Supprimez les Secrets et les PersistentVolumeClaims liés aux PostgreSQL, MinIO et Redis intégrés.

   ```shell
   kubectl delete pvc <RELEASE>-minio redis-data-<RELEASE>-redis-master-0 data-<RELEASE>-postgresql-0
   kubectl delete secret <RELEASE>-postgresql-password <RELEASE>-redis-secret <RELEASE>-minio-secret <RELEASE>-minio-tls
   ```
