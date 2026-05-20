---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer Redis en mode autonome
---

Les instructions ici utilisent le [package Linux](https://about.gitlab.com/install/#ubuntu) pour Ubuntu. Ce package fournit des versions des services dont la compatibilité avec les services des charts est garantie.

## Créer une VM avec le package Linux {#create-vm-with-the-linux-package}

Créez une VM chez le fournisseur de votre choix, ou localement. Cela a été testé avec VirtualBox, KVM et Bhyve. Assurez-vous que l'instance est accessible depuis le cluster.

Installez Ubuntu Server sur la VM que vous avez créée. Assurez-vous que `openssh-server` est installé et que tous les packages sont à jour. Configurez le réseau et un nom d'hôte. Notez le nom d'hôte/l'IP et assurez-vous qu'il est à la fois résolvable et accessible depuis votre cluster Kubernetes. Assurez-vous que des politiques de pare-feu sont en place pour autoriser le trafic.

Suivez les instructions d'installation du [package Linux](https://docs.gitlab.com/install/package/ubuntu/).

> [!note]
> Lorsque vous effectuez l'installation du package, ne fournissez pas la valeur `EXTERNAL_URL=`. Nous ne souhaitons pas que la configuration automatique se produise, car nous fournirons une configuration très spécifique à l'étape suivante.

## Configurer l'installation du package Linux {#configure-linux-package-installation}

Créez un fichier `gitlab.rb` minimal à placer dans `/etc/gitlab/gitlab.rb`. Soyez _très_ explicite sur ce qui est activé sur ce nœud, utilisez le contenu ci-dessous.

> [!note]
> Cet exemple n'est pas destiné à fournir [Redis pour la mise à l'échelle](https://docs.gitlab.com/administration/redis/).

- `REDIS_PASSWORD` doit être remplacé par la valeur dans le [secret `gitlab-redis`](../../installation/secrets.md#redis-password).

```Ruby
# Listen on all addresses
redis['bind'] = '0.0.0.0'
# Set the defaul port, must be set.
redis['port'] = 6379
# Set password, as in the secret `gitlab-redis` populated in Kubernetes
redis['password'] = 'REDIS_PASSWORD'

## Disable everything else
gitlab_rails['enable'] = false
sidekiq['enable'] = false
puma['enable']=false
registry['enable'] = false
gitaly['enable'] = false
gitlab_workhorse['enable'] = false
nginx['enable'] = false
prometheus_monitoring['enable'] = false
postgresql['enable'] = false
```

Après avoir créé `gitlab.rb`, reconfigurez le package avec `gitlab-ctl reconfigure`. Une fois la tâche terminée, vérifiez les processus en cours d'exécution avec `gitlab-ctl status`. La sortie devrait ressembler à :

```plaintext
# gitlab-ctl status
run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
run: redis: (pid 30562) 77637s; run: log: (pid 30561) 77637s
```
