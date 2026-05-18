---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer une base de données PostgreSQL autonome
---

Nous utiliserons le [package Linux](https://about.gitlab.com/install/#ubuntu) pour Ubuntu. Ce package fournit des versions des services dont la compatibilité avec les services des charts est garantie.

## Créer une VM avec le package Linux {#create-vm-with-the-linux-package}

Créez une VM chez le fournisseur de votre choix, ou localement. Cette procédure a été testée avec VirtualBox, KVM et Bhyve. Assurez-vous que l'instance est accessible depuis le cluster.

Installez Ubuntu Server sur la VM que vous avez créée. Assurez-vous que `openssh-server` est installé et que tous les packages sont à jour. Configurez le réseau et un nom d'hôte. Notez le nom d'hôte/l'IP, et assurez-vous qu'il est à la fois résolvable et accessible depuis votre cluster Kubernetes. Veillez à ce que des politiques de pare-feu soient en place pour autoriser le trafic.

Suivez les instructions d'installation du [package Linux](https://docs.gitlab.com/install/package/ubuntu/).

> [!note]
> Lorsque vous effectuez l'installation du package, ne fournissez pas la valeur `EXTERNAL_URL=`. Nous ne souhaitons pas que la configuration automatique se produise, car nous fournirons une configuration très spécifique à l'étape suivante.

## Configurer l'installation du package Linux {#configure-linux-package-installation}

Créez un fichier `gitlab.rb` minimal à placer dans `/etc/gitlab/gitlab.rb`. Soyez très explicite sur ce qui est activé sur ce nœud, utilisez le contenu ci-dessous.

Cet exemple n'est pas destiné à fournir [PostgreSQL pour la mise à l'échelle](https://docs.gitlab.com/administration/postgresql/).

Ces valeurs doivent être remplacées :

- `DB_USERNAME` le nom d'utilisateur par défaut est `gitlab`
- `DB_PASSSWORD` valeur non encodée
- `DB_ENCODED_PASSWORD` valeur encodée de `DB_PASSWORD`. Peut être générée en remplaçant `DB_USERNAME` et `DB_PASSWORD` par des valeurs réelles dans : `echo -n 'DB_PASSSWORDDB_USERNAME' | md5sum - | cut -d' ' -f1`
- `AUTH_CIDR_ADDRESS` configure les CIDR pour l'authentification MD5, doit correspondre aux plus petits sous-réseaux possibles de votre cluster ou de sa passerelle. Pour minikube, cette valeur est `192.168.100.0/12`

```ruby
# Change the address below if you do not want PG to listen on all available addresses
postgresql['listen_address'] = '0.0.0.0'
# Set to approximately 1/4 of available RAM.
postgresql['shared_buffers'] = "512MB"
# This password is: `echo -n '${password}${username}' | md5sum - | cut -d' ' -f1`
# The default username is `gitlab`
postgresql['sql_user_password'] = "DB_ENCODED_PASSWORD"
# Configure the CIDRs for MD5 authentication
postgresql['md5_auth_cidr_addresses'] = ['AUTH_CIDR_ADDRESSES']
# Configure the CIDRs for trusted authentication (passwordless)
postgresql['trust_auth_cidr_addresses'] = ['127.0.0.1/24']

## Configure gitlab_rails
gitlab_rails['auto_migrate'] = false
gitlab_rails['db_username'] = "gitlab"
gitlab_rails['db_password'] = "DB_PASSSWORD"


## Disable everything else
sidekiq['enable'] = false
puma['enable'] = false
registry['enable'] = false
gitaly['enable'] = false
gitlab_workhorse['enable'] = false
nginx['enable'] = false
prometheus_monitoring['enable'] = false
redis['enable'] = false
gitlab_kas['enable'] = false
```

Après avoir créé `gitlab.rb`, nous reconfigurerons le package avec `gitlab-ctl reconfigure`. Une fois la tâche terminée, vérifiez les processus en cours d'exécution avec `gitlab-ctl status`. La sortie devrait apparaître comme suit :

```plaintext
# gitlab-ctl status
run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
run: postgresql: (pid 30562) 77637s; run: log: (pid 30561) 77637s
```
