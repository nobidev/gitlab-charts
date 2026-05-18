---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer Gitaly en mode autonome
---

Les instructions ici utilisent le [package Linux](https://about.gitlab.com/install/#ubuntu) pour Ubuntu. Ce package fournit des versions des services dont la compatibilité avec les services des charts est garantie.

## Créer une VM avec le package Linux {#create-vm-with-the-linux-package}

Créez une VM chez le fournisseur de votre choix, ou localement. Cela a été testé avec VirtualBox, KVM et Bhyve. Assurez-vous que l'instance est accessible depuis le cluster.

Installez Ubuntu Server sur la VM que vous avez créée. Assurez-vous que `openssh-server` est installé et que tous les packages sont à jour. Configurez le réseau et un nom d'hôte. Notez le nom d'hôte/l'IP et assurez-vous qu'il est à la fois résolvable et accessible depuis votre cluster Kubernetes. Assurez-vous que des politiques de pare-feu sont en place pour autoriser le trafic.

Suivez les instructions d'installation du [package Linux](https://docs.gitlab.com/install/package/ubuntu/).

> [!note]
> Lorsque vous effectuez l'installation du package Linux, ne fournissez pas la valeur `EXTERNAL_URL=`. Nous ne souhaitons pas que la configuration automatique se produise, car nous fournirons une configuration très spécifique à l'étape suivante.

## Configurer l'installation du package Linux {#configure-linux-package-installation}

Créez un fichier `gitlab.rb` minimal à placer dans `/etc/gitlab/gitlab.rb`. Soyez très explicite sur ce qui est activé sur ce nœud, en utilisant le contenu suivant basé sur la documentation pour [l'exécution de Gitaly sur son propre serveur](https://docs.gitlab.com/administration/gitaly/configure_gitaly/#run-gitaly-on-its-own-server).

Ces valeurs doivent être remplacées :

- `AUTH_TOKEN` doit être remplacé par la valeur dans le [secret `gitaly-secret`](../../installation/secrets.md#gitaly-secret)
- `GITLAB_URL` doit être remplacé par l'URL de l'instance GitLab
- `SHELL_TOKEN` doit être remplacé par la valeur dans le [secret `gitlab-shell-secret`](../../installation/secrets.md#gitlab-shell-secret)

<!--
Updates to example must be made at:
- <https://gitlab.com/gitlab-org/charts/gitlab/blob/master/doc/advanced/external-gitaly/external-omnibus-gitaly.md#configure-linux-package-installation>
- <https://gitlab.com/gitlab-org/gitlab/-/blob/master/doc/administration/gitaly/configure_gitaly.md#configure-gitaly-server>
- All reference architecture pages
-->

```ruby
# Avoid running unnecessary services on the Gitaly server
postgresql['enable'] = false
redis['enable'] = false
nginx['enable'] = false
puma['enable'] = false
sidekiq['enable'] = false
gitlab_workhorse['enable'] = false
gitlab_exporter['enable'] = false
gitlab_kas['enable'] = false

# If you run a seperate monitoring node you can disable these services
prometheus['enable'] = false
alertmanager['enable'] = false

# If you don't run a separate monitoring node you can
# Enable Prometheus access & disable these extra services
# This makes Prometheus listen on all interfaces. You must use firewalls to restrict access to this address/port.
# prometheus['listen_address'] = '0.0.0.0:9090'
# prometheus['monitor_kubernetes'] = false

# If you don't want to run monitoring services uncomment the following (not recommended)
# node_exporter['enable'] = false

# Prevent database connections during 'gitlab-ctl reconfigure'
gitlab_rails['auto_migrate'] = false

# Configure the gitlab-shell API callback URL. Without this, `git push` will
# fail. This can be your 'front door' GitLab URL or an internal load
# balancer.
gitlab_rails['internal_api_url'] = 'GITLAB_URL'
# Token used by Gitaly and GitLab shell to authenticate with GitLab
gitaly['gitlab_secret'] = 'SHELL_TOKEN'

gitaly['configuration'] = {
    # Make Gitaly accept connections on all network interfaces. You must use
    # firewalls to restrict access to this address/port.
    # Comment out following line if you only want to support TLS connections
    listen_addr: '0.0.0.0:8075',
    # Authentication token to ensure only authorized servers can communicate with
    # Gitaly server
    auth: {
        token: 'AUTH_TOKEN',
    },
    storage: [
      {
         name: 'default',
         path: '/var/opt/gitlab/git-data',
      },
      {
         name: 'storage1',
         path: '/mnt/gitlab/git-data',
      },
   ],
}

# To use TLS for Gitaly you need to add
gitaly['tls_listen_addr'] = "0.0.0.0:8076"
gitaly['certificate_path'] = "path/to/cert.pem"
gitaly['key_path'] = "path/to/key.pem"
```

Après avoir créé `gitlab.rb`, reconfigurez le package avec `gitlab-ctl reconfigure`. Une fois la tâche terminée, vérifiez les processus en cours d'exécution avec `gitlab-ctl status`. La sortie devrait apparaître comme suit :

```plaintext
# gitlab-ctl status
run: gitaly: (pid 30562) 77637s; run: log: (pid 30561) 77637s
run: logrotate: (pid 4856) 1859s; run: log: (pid 31262) 77460s
```
