---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Configurer les secrets pour le chart GitLab
---

{{< details >}}

- Niveau :  Free, Premium, Ultimate
- Offre :  GitLab Self-Managed

{{< /details >}}

GitLab nécessite différents secrets pour fonctionner :

Composants GitLab :

- Certificats d'authentification du registre
- Clés hôtes SSH et certificats pour GitLab Shell
- Mots de passe pour les services GitLab individuels
- Certificat TLS pour GitLab Pages

Services externes optionnels :

- Serveur SMTP
- LDAP
- OmniAuth
- IMAP pour les e-mails entrants (via le service mail_room)
- IMAP pour les e-mails du Service Desk (via le service mail_room)
- Microsoft Graph avec OAuth2 pour les e-mails entrants (via le service mail_room)
- Microsoft Graph avec OAuth2 pour les e-mails du Service Desk (via le service mail_room)
- Microsoft Graph avec OAuth2 pour les e-mails sortants
- Certificat S/MIME
- Authentification par carte à puce
- Intégration OAuth

Tout secret non fourni manuellement sera automatiquement généré avec une valeur aléatoire. La génération automatique de certificats HTTPS est fournie par Let's Encrypt.

Pour utiliser les secrets générés automatiquement, passez aux [étapes suivantes](#next-steps).

Pour spécifier vos propres secrets, passez à la [création manuelle de secrets](#manual-secret-creation-optional).

## Création manuelle de secrets (optionnel) {#manual-secret-creation-optional}

Utilisez `gitlab` comme nom de release si vous avez suivi les étapes précédentes de cette documentation.

- [Certificats TLS](tls.md)
- [Certificats d'authentification du registre](#registry-authentication-certificates)
- [En-têtes de notification sensibles du registre](#registry-sensitive-notification-headers)
- [Clés hôtes SSH](#ssh-host-keys)
- Mots de passe :
  - [Mot de passe root initial](#initial-root-password)
  - [Mot de passe Redis](#redis-password)
  - [Secret GitLab Shell](#gitlab-shell-secret)
  - [Secret Gitaly](#gitaly-secret)
  - [Secret Praefect](#praefect-secret)
  - [Secret GitLab Rails](#gitlab-rails-secret)
  - [Secret GitLab Workhorse](#gitlab-workhorse-secret)
  - [Secret GitLab Runner](#gitlab-runner-secret)
  - [Mot de passe PostgreSQL](#postgresql-password)
  - [Mot de passe de la base de données Praefect](#praefect-db-password)
  - [Secret MinIO](#minio-secret)
  - [Secret HTTP du registre](#registry-http-secret)
  - [Secret de notification du registre](#registry-notification-secret)
  - [Secret GitLab Pages](#gitlab-pages-secret)
  - [Jeton d'authentification des e-mails entrants GitLab](#gitlab-incoming-email-auth-token)
  - [Jeton d'authentification des e-mails du Service Desk GitLab](#gitlab-service-desk-email-auth-token)
  - [Secret de l'API interne de l'indexeur Zoekt](#zoekt-indexer-internal-api-secret)
- [Services externes](#external-services)
  - [OmniAuth](#omniauth)
  - [Mot de passe LDAP](#ldap-password)
  - [Mot de passe SMTP](#smtp-password)
  - [Mot de passe IMAP pour les e-mails entrants](#imap-password-for-incoming-emails)
  - [Mot de passe IMAP pour le Service Desk](#imap-password-for-service-desk-emails)
  - [Secret client Microsoft Graph pour les e-mails entrants](#microsoft-graph-client-secret-for-incoming-emails)
  - [Secret client Microsoft Graph pour le Service Desk](#microsoft-graph-client-secret-for-service-desk-emails)
  - [Secret client Microsoft Graph pour les e-mails sortants](#microsoft-graph-client-secret-for-outgoing-emails)
  - [Certificat S/MIME](#smime-certificate)
  - [Authentification par carte à puce](#smartcard-authentication)

### Certificats d'authentification du registre {#registry-authentication-certificates}

La communication entre GitLab et le registre passe par un Ingress, il est donc suffisant dans la plupart des cas d'utiliser des certificats auto-signés pour cette communication. Si ce trafic est exposé sur un réseau, vous devez générer des certificats valides publiquement.

Dans l'exemple ci-dessous, nous supposons que nous avons besoin de certificats auto-signés.

Générez une paire certificat-clé :

```shell
mkdir -p certs
openssl req -new -newkey rsa:4096 -subj "/CN=gitlab-issuer" -nodes -x509 -keyout certs/registry-example-com.key -out certs/registry-example-com.crt
```

Créez un secret contenant ces certificats. Nous allons créer les clés `registry-auth.key` et `registry-auth.crt` à l'intérieur du secret `<name>-registry-secret`. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-registry-secret --from-file=registry-auth.key=certs/registry-example-com.key --from-file=registry-auth.crt=certs/registry-example-com.crt
```

Ce secret est référencé par le paramètre `global.registry.certificate.secret`.

### En-têtes de notification sensibles du registre {#registry-sensitive-notification-headers}

Consultez la [documentation relative à la configuration des notifications du registre](../charts/globals.md#configure-registry-settings) pour plus de détails.

Le contenu du secret doit être une liste d'éléments, même s'il ne contient qu'un seul élément. Si le contenu est simplement une chaîne de caractères, les charts **WILL NOT** automatiquement celui-ci en liste.

Considérez l'exemple dans lequel le secret `registry-authorization-header` avec la valeur `RandomFooBar` est créé.

```shell
kubectl create secret generic registry-authorization-header --from-literal=value="[RandomFooBar]"
```

Par défaut, la clé utilisée dans le secret est « value ». Cependant, les utilisateurs peuvent utiliser une clé différente, mais doivent s'assurer qu'elle est spécifiée comme `key` sous l'élément de mappage d'en-tête.

### Clés hôtes SSH {#ssh-host-keys}

Générez les paires certificat-clé OpenSSH :

```shell
mkdir -p hostKeys
ssh-keygen -t rsa  -f hostKeys/ssh_host_rsa_key -N ""
ssh-keygen -t ecdsa  -f hostKeys/ssh_host_ecdsa_key -N ""
ssh-keygen -t ed25519  -f hostKeys/ssh_host_ed25519_key -N ""
```

Créez le secret contenant ces certificats. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-gitlab-shell-host-keys --from-file hostKeys
```

Ce secret est référencé par le paramètre `global.shell.hostKeys.secret`.

Si ce secret est renouvelé, tous les clients SSH verront des erreurs `hostname mismatch`.

### Licence Enterprise initiale {#initial-enterprise-license}

> [!warning]
> Cette méthode n'ajoutera une licence qu'au moment de l'installation. Utilisez la zone d'administration dans l'interface utilisateur web pour renouveler ou mettre à niveau les licences.

Créez un secret Kubernetes pour stocker la licence Enterprise de l'instance GitLab. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-gitlab-license --from-file=license=/tmp/license.gitlab
```

Utilisez ensuite `--set global.gitlab.license.secret=<name>-gitlab-license` pour injecter la licence dans votre configuration.

Vous pouvez également utiliser l'option `global.gitlab.license.key` pour modifier la clé `license` par défaut pointant vers la licence dans le secret de licence.

### Mot de passe root initial {#initial-root-password}

Créez un secret Kubernetes pour stocker le mot de passe root initial. Le mot de passe doit comporter au moins 6 caractères. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-gitlab-initial-root-password --from-literal=password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)
```

### Mot de passe Redis {#redis-password}

Générez un mot de passe alphanumérique aléatoire de 64 caractères pour Redis. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-redis-secret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

Si vous déployez avec un cluster Redis déjà existant, veuillez utiliser le mot de passe d'accès au cluster Redis encodé en base64 plutôt qu'un mot de passe généré aléatoirement.

Ce secret est référencé par le paramètre `global.redis.auth.secret`.

### Secret GitLab Shell {#gitlab-shell-secret}

Générez un secret alphanumérique aléatoire de 64 caractères pour GitLab Shell. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-gitlab-shell-secret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

Ce secret est référencé par le paramètre `global.shell.authToken.secret`.

### Secret Gitaly {#gitaly-secret}

Générez un token alphanumérique aléatoire de 64 caractères pour Gitaly. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-gitaly-secret --from-literal=token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

Ce secret est référencé par le paramètre `global.gitaly.authToken.secret`.

### Secret Praefect {#praefect-secret}

Générez un token alphanumérique aléatoire de 64 caractères pour Praefect. Remplacez `<name>` par le nom de la release :

```shell
kubectl create secret generic <name>-praefect-secret --from-literal=token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

Ce secret est référencé par le paramètre `global.praefect.authToken.secret`.

### Secret GitLab Rails {#gitlab-rails-secret}

{{< history >}}

- Les clés `active_record_encryption_*` ont été ajoutées dans [GitLab 17.8](../releases/8_0.md#upgrade-to-880).

{{< /history >}}

Remplacez `<name>` par le nom de la release.

```shell
cat << EOF > secrets.yml
production:
  secret_key_base: $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-f0-9' | head -c 128)
  otp_key_base: $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-f0-9' | head -c 128)
  db_key_base: $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-f0-9' | head -c 128)
  encrypted_settings_key_base: $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-f0-9' | head -c 128)
  openid_connect_signing_key: |
$(openssl genrsa 2048 | awk '{print "    " $0}')
  active_record_encryption_primary_key:
    - $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)
  active_record_encryption_deterministic_key:
    - $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)
  active_record_encryption_key_derivation_salt: $(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)
EOF

kubectl create secret generic <name>-rails-secret --from-file=secrets.yml
```

Ce secret est référencé par le paramètre `global.railsSecrets.secret`.

Il n'est pas recommandé de renouveler ce secret car il contient les clés de chiffrement de la base de données. Si le secret est renouvelé, le comportement résultant sera le même que celui observé [lorsque le fichier de secrets est perdu](https://docs.gitlab.com/administration/backup_restore/troubleshooting_backup_gitlab/#when-the-secrets-file-is-lost).

### Secret GitLab Workhorse {#gitlab-workhorse-secret}

Générez le secret workhorse. Il doit avoir une longueur de 32 caractères et être encodé en base64. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-gitlab-workhorse-secret --from-literal=shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

Ce secret est référencé par le paramètre `global.workhorse.secret`.

### Secret GitLab Runner {#gitlab-runner-secret}

Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-gitlab-runner-secret --from-literal=runner-registration-token=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

Ce secret est référencé par le paramètre `gitlab-runner.runners.secret`.

### Secret GitLab KAS {#gitlab-kas-secret}

GitLab Rails nécessite qu'un secret pour KAS soit présent, même si l'on déploie ce chart sans installer le sous-chart KAS. Néanmoins, il est possible de créer ce secret manuellement en suivant la procédure ci-dessous ou de laisser le chart le générer automatiquement.

Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-gitlab-kas-secret --from-literal=kas_shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

Ce secret est référencé par le paramètre `global.appConfig.gitlab_kas.secret`.

### Secret de l'API GitLab KAS {#gitlab-kas-api-secret}

Vous pouvez laisser le chart générer automatiquement le secret, ou vous pouvez créer ce secret manuellement (remplacez `<name>` par le nom de la release) :

```shell
kubectl create secret generic <name>-kas-private-api --from-literal=kas_private_api_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

Ce secret est référencé par le paramètre `gitlab.kas.privateApi.secret`.

### Secret du token WebSocket GitLab KAS {#gitlab-kas-websocket-token-secret}

Vous pouvez laisser le chart générer automatiquement le secret, ou vous pouvez créer ce secret manuellement (remplacez `<name>` par le nom de la release) :

```shell
kubectl create secret generic <name>-kas-websocket-token --from-literal=kas_websocket_token_secret=$(head -c 72 /dev/urandom | base64 -w0)
```

Ce secret est référencé par le paramètre `gitlab.kas.websocketToken.secret`.

### Secret MinIO {#minio-secret}

Générez un ensemble de clés alphanumériques aléatoires de 20 et 64 caractères pour MinIO. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-minio-secret --from-literal=accesskey=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 20) --from-literal=secretkey=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

Ce secret est référencé par le paramètre `global.minio.credentials.secret`.

### Mot de passe PostgreSQL {#postgresql-password}

Générez un mot de passe alphanumérique aléatoire de 64 caractères. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-postgresql-password \
    --from-literal=postgresql-password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64) \
    --from-literal=postgresql-postgres-password=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

Ce secret est référencé par le paramètre `global.psql.password.secret`.

### Secret GitLab Pages {#gitlab-pages-secret}

Générez le secret GitLab Pages. Il doit avoir une longueur de 32 caractères et être encodé en base64. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-gitlab-pages-secret --from-literal=shared_secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

Ce secret est référencé par le paramètre `global.pages.apiSecret.secret`.

### Secret HTTP du registre {#registry-http-secret}

Générez une clé alphanumérique aléatoire de 64 caractères partagée par tous les pods du registre. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-registry-httpsecret --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64 | base64)
```

Ce secret est référencé par le paramètre `global.registry.httpSecret.secret`.

### Secret de notification du registre {#registry-notification-secret}

Générez une clé alphanumérique aléatoire de 32 caractères partagée par tous les pods du registre et les pods du webservice GitLab. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-registry-notification --from-literal=secret=[\"$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32)\"]
```

Ce secret est référencé par le paramètre `global.registry.notificationSecret.secret`.

### Mot de passe de la base de données Praefect {#praefect-db-password}

Générez un mot de passe alphanumérique aléatoire de 64 caractères. Remplacez `<name>` par le nom de la release :

```shell
kubectl create secret generic <name>-praefect-dbsecret \
    --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64) \
```

Ce secret est référencé par le paramètre `global.praefect.dbSecret`.

## Services externes {#external-services}

Certains charts ont des secrets supplémentaires pour activer des fonctionnalités qui ne peuvent pas être générées automatiquement.

### OmniAuth {#omniauth}

Pour activer l'utilisation des [fournisseurs OmniAuth](https://docs.gitlab.com/integration/omniauth/) avec le GitLab déployé, veuillez suivre les [instructions dans le chart Globals](../charts/globals.md#omniauth)

### Mot de passe LDAP {#ldap-password}

Si vous avez besoin d'une authentification par mot de passe pour vous connecter à votre serveur LDAP, vous devez stocker le mot de passe dans un secret Kubernetes.

```shell
kubectl create secret generic ldap-main-password --from-literal=password=yourpasswordhere
```

Utilisez ensuite `--set global.appConfig.ldap.servers.main.password.secret=ldap-main-password` pour injecter le mot de passe dans votre configuration.

> [!note]
> Utilisez le nom du `Secret`, et non le _mot de passe réel_, lors de la configuration de la propriété Helm.

### Mot de passe SMTP {#smtp-password}

Si vous utilisez un serveur SMTP qui nécessite une authentification, stockez le mot de passe dans un secret Kubernetes.

```shell
kubectl create secret generic smtp-password --from-literal=password=yourpasswordhere
```

Utilisez ensuite `--set global.smtp.password.secret=smtp-password` dans votre commande Helm.

> [!note]
> Utilisez le nom du `Secret`, et non le _mot de passe réel_, lors de la configuration de la propriété Helm.

### Mot de passe IMAP pour les e-mails entrants {#imap-password-for-incoming-emails}

GitLab utilise des chaînes d'authentification telles que les mots de passe d'application, les tokens ou les mots de passe IMAP pour accéder aux e-mails entrants.

[Trouvez votre fournisseur de messagerie dans la documentation des e-mails entrants de GitLab](https://docs.gitlab.com/administration/incoming_email/) et définissez sa chaîne d'authentification requise en tant que secret Kubernetes.

```shell
kubectl create secret generic incoming-email-password --from-literal="password=auth_string_for_your_provider_here"
```

Utilisez ensuite `--set global.appConfig.incomingEmail.password.secret=incoming-email-password` dans votre commande Helm avec les autres paramètres requis tels que spécifiés [dans la documentation](command-line-options.md#incoming-email-configuration).

> [!note]
> Utilisez le nom du `Secret`, et non le _mot de passe réel_, lors de la configuration de la propriété Helm.

### Mot de passe IMAP pour les e-mails du Service Desk {#imap-password-for-service-desk-emails}

GitLab utilise des chaînes d'authentification telles que les mots de passe d'application, les tokens ou les mots de passe IMAP pour accéder aux [e-mails du Service Desk](https://docs.gitlab.com/user/project/service_desk/configure/#custom-email-address).

[Trouvez votre fournisseur de messagerie dans la documentation des e-mails entrants de GitLab](https://docs.gitlab.com/administration/incoming_email/) et définissez sa chaîne d'authentification requise en tant que secret Kubernetes.

```shell
kubectl create secret generic service-desk-email-password --from-literal="password=auth_string_for_your_provider_here"
```

Utilisez ensuite `--set global.appConfig.serviceDeskEmail.password.secret=service-desk-email-password` dans votre commande Helm avec les autres paramètres requis tels que spécifiés [dans la documentation](command-line-options.md#service-desk-email-configuration).

> [!note]
> Utilisez le nom du `Secret`, et non le _mot de passe réel_, lors de la configuration de la propriété Helm.

### Jeton d'authentification des e-mails entrants GitLab {#gitlab-incoming-email-auth-token}

Lorsque les e-mails entrants sont configurés pour utiliser la méthode de livraison par webhook, un secret partagé doit exister entre le service mail_room et le webservice. Il doit avoir une longueur de 32 caractères et être encodé en base64. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-incoming-email-auth-token --from-literal=authToken=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

Ce secret est référencé par le paramètre `global.incomingEmail.authToken`.

### Jeton d'authentification des e-mails du Service Desk GitLab {#gitlab-service-desk-email-auth-token}

Lorsque les e-mails du Service Desk sont configurés pour utiliser la méthode de livraison par webhook, un secret partagé doit exister entre le service mail_room et le webservice. Il doit avoir une longueur de 32 caractères et être encodé en base64. Remplacez `<name>` par le nom de la release.

```shell
kubectl create secret generic <name>-service-desk-email-auth-token --from-literal=authToken=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 32 | base64)
```

Ce secret est référencé par le paramètre `global.serviceDeskEmail.authToken`.

### Secret de l'API interne de l'indexeur Zoekt {#zoekt-indexer-internal-api-secret}

Lorsque le [sous-chart GitLab-zoekt](../charts/gitlab/gitlab-zoekt/_index.md) est installé, l'indexeur Zoekt s'authentifie auprès de l'API interne de GitLab via JWT. Par défaut, ce secret réutilise le [secret GitLab Shell](#gitlab-shell-secret), qui est généré automatiquement.

Si vous souhaitez utiliser un secret distinct pour Zoekt, vous pouvez en créer un manuellement (remplacez `<name>` par le nom de la release) :

```shell
kubectl create secret generic <name>-zoekt-internal-api --from-literal=secret=$(head -c 512 /dev/urandom | LC_CTYPE=C tr -cd 'a-zA-Z0-9' | head -c 64)
```

Configurez ensuite le chart pour l'utiliser :

```shell
--set global.zoekt.indexer.internalApi.secretName=<name>-zoekt-internal-api \
--set global.zoekt.indexer.internalApi.secretKey=secret
```

Si non spécifié, `global.zoekt.indexer.internalApi.secretName` prend par défaut la valeur du secret de token d'authentification de GitLab Shell (`global.shell.authToken.secret`).

### Secret client Microsoft Graph pour les e-mails entrants {#microsoft-graph-client-secret-for-incoming-emails}

Pour permettre à GitLab d'accéder aux [e-mails entrants](https://docs.gitlab.com/administration/incoming_email/), stockez le mot de passe du compte IMAP dans un secret Kubernetes :

```shell
kubectl create secret generic incoming-email-client-secret --from-literal=secret=your-secret-here
```

Ensuite, utilisez `--set global.appConfig.incomingEmail.clientSecret.secret=incoming-email-client-secret` dans votre commande Helm avec les autres paramètres requis tels que spécifiés [dans la documentation](command-line-options.md#incoming-email-configuration).

> [!note]
> Utilisez le nom du `Secret`, et non le _mot de passe réel_, lors de la configuration de la propriété Helm.

### Secret client Microsoft Graph pour les e-mails du Service Desk {#microsoft-graph-client-secret-for-service-desk-emails}

Pour permettre à GitLab d'accéder aux [e-mails du service_desk](https://docs.gitlab.com/user/project/service_desk/configure/#custom-email-address), stockez le mot de passe du compte IMAP dans un secret Kubernetes :

```shell
kubectl create secret generic service-desk-email-client-secret --from-literal=secret=your-secret-here
```

Ensuite, utilisez `--set global.appConfig.serviceDeskEmail.clientSecret.secret=service-desk-email-client-secret` dans votre commande Helm avec les autres paramètres requis tels que spécifiés [dans la documentation](command-line-options.md#service-desk-email-configuration).

> [!note]
> Utilisez le nom du `Secret`, et non le _mot de passe réel_, lors de la configuration de la propriété Helm.

### Secret client Microsoft Graph pour les e-mails sortants {#microsoft-graph-client-secret-for-outgoing-emails}

Stockez le mot de passe dans un secret Kubernetes :

```shell
kubectl create secret generic microsoft-graph-mailer-client-secret --from-literal=secret=your-secret-here
```

Ensuite, utilisez `--set global.appConfig.microsoft_graph_mailer.client_secret.secret=microsoft-graph-mailer-client-secret` dans votre commande Helm.

> [!note]
> Utilisez le nom du `Secret`, et non le _mot de passe réel_, lors de la configuration de la propriété Helm.

### Certificat S/MIME {#smime-certificate}

Les messages d'e-mail sortants peuvent être signés numériquement à l'aide de la norme [S/MIME](https://en.wikipedia.org/wiki/S/MIME). Le certificat S/MIME doit être stocké dans un secret Kubernetes en tant que secret de type TLS.

```shell
kubectl create secret tls smime-certificate --key=file.key --cert file.crt
```

Si un secret existant est de type opaque, les valeurs `global.email.smime.keyName` et `global.email.smime.certName` devront être ajustées pour ce secret spécifique.

Les paramètres S/MIME peuvent être définis via le fichier `values.yaml` ou en ligne de commande. Utilisez `--set global.email.smime.enabled=true` pour activer S/MIME et `--set global.email.smime.secretName=smime-certificate` pour spécifier le secret qui contient le certificat S/MIME.

### Authentification par carte à puce {#smartcard-authentication}

L'[authentification par carte à puce](https://docs.gitlab.com/administration/auth/smartcard/) utilise une autorité de certification (CA) personnalisée pour signer les certificats clients. Le certificat de cette CA personnalisée doit être injecté dans le pod Webservice pour qu'il puisse vérifier si un certificat client est valide ou non. Celui-ci est fourni en tant que secret k8s.

```shell
kubectl create secret generic <secret name> --from-file=ca.crt=<path to CA certificate>
```

Le nom de la clé à l'intérieur du secret où le certificat est stocké DOIT ÊTRE `ca.crt`.

### Intégration OAuth {#oauth-integration}

Pour configurer l'intégration OAuth de divers services tels que GitLab Pages, des secrets contenant des identifiants OAuth sont nécessaires. Le secret doit contenir un App ID (par défaut, stocké sous la clé `appid`) et un App Secret (par défaut, stocké sous la clé `appsecret`), qui sont tous deux recommandés comme étant des chaînes alphanumériques d'au moins 64 caractères.

```shell
kubectl create secret generic oauth-gitlab-pages-secret --from-literal=appid=<app id> --from-literal=appsecret=<app secret>
```

Ce secret peut être spécifié à l'aide du paramètre `global.oauth.<service name>.secret`. Si des clés autres que `appid` et `appsecret` sont utilisées, elles peuvent être spécifiées à l'aide des paramètres `global.oauth.<service name>.appIdKey` et `global.oauth.<service name>.appSecretKey`.

## Étapes suivantes {#next-steps}

Une fois tous les secrets générés et stockés, vous pouvez procéder au [déploiement de GitLab](deployment.md).

## Renouvellement des secrets {#rotating-secrets}

Les secrets peuvent être renouvelés si nécessaire pour des raisons de sécurité.

1. [Sauvegardez vos secrets actuels](../backup-restore/backup.md#back-up-the-secrets).
1. Pour votre commodité, créez de nouveaux secrets avec le suffixe `-v2` (par exemple `gitlab-shell-host-keys-v2`) en suivant les étapes de [création manuelle de secrets](#manual-secret-creation-optional) pour chaque secret que vous souhaitez renouveler.
1. Mettez à jour les clés de secrets dans votre fichier `values.yaml` pour pointer vers les nouveaux noms de secrets. La plupart des noms de secrets sont documentés sous chaque secret respectif dans la section [création manuelle de secrets](#manual-secret-creation-optional).
1. Mettez à niveau la release du chart GitLab avec le fichier `values.yaml` mis à jour.
1. Confirmez que GitLab fonctionne comme prévu. Si c'est le cas, il devrait être sûr de supprimer les anciens secrets.
