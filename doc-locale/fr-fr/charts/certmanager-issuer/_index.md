---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: "Utilisation de certmanager-issuer pour la création d'un émetteur CertManager"
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Ce chart est un assistant pour le [chart Helm CertManager de Jetstack](https://cert-manager.io/docs/installation/helm/). Il provisionne automatiquement un objet Issuer, utilisé par CertManager lors de la demande de certificats TLS pour les Ingresses GitLab.

## Configuration {#configuration}

Nous décrivons ci-dessous toutes les sections principales de la configuration. Lors de la configuration depuis le chart parent, ces valeurs sont :

```yaml
certmanager-issuer:
  # Configure an ACME Issuer in cert-manager. Only used if global.ingress.configureCertmanager is true.
  server: https://acme-v02.api.letsencrypt.org/directory

  # Provide an email to associate with your TLS certificates
  # email:

  rbac:
    create: true

  resources:
    requests:
      cpu: 50m

  # Priority class assigned to pods
  priorityClassName: ""

  common:
    labels: {}
```

## Paramètres d'installation {#installation-parameters}

Ce tableau contient toutes les configurations de charts possibles pouvant être fournies à la commande `helm install` en utilisant les indicateurs `--set` :

| Paramètre                                           | Défaut                                          | Description |
|-----------------------------------------------------|--------------------------------------------------|-------------|
| `server`                                            | `https://acme-v02.api.letsencrypt.org/directory` | Serveur Let's Encrypt à utiliser avec l'[émetteur ACME CertManager](https://cert-manager.io/docs/configuration/acme/). |
| `email`                                             |                                                  | Vous devez fournir une adresse e-mail à associer à vos certificats TLS. Let's Encrypt utilise cette adresse pour vous contacter au sujet des certificats arrivant à expiration et des problèmes liés à votre compte. |
| `rbac.create`                                       | `true`                                           | Lorsque `true`, crée des ressources liées à RBAC pour permettre la manipulation des objets Issuer CertManager. |
| `resources.requests.cpu`                            | `50m`                                            | Ressources CPU demandées pour le job de création d'Issuer. |
| `common.labels`                                     |                                                  | Labels communs à appliquer au ServiceAccount, au job, au ConfigMap et à l'Issuer. |
| `priorityClassName`                                 |                                                  | [Classe de priorité](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) assignée aux pods. |
| `containerSecurityContext`                          |                                                  | Remplacer le [securityContext](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.25/#securitycontext-v1-core) du conteneur sous lequel Certmanager est démarré |
| `containerSecurityContext.runAsUser`                | `65534`                                          | ID utilisateur sous lequel le conteneur doit être démarré |
| `containerSecurityContext.runAsGroup`               | `65534`                                          | ID de groupe sous lequel le conteneur doit être démarré |
| `containerSecurityContext.allowPrivilegeEscalation` | `false`                                          | Contrôle si un processus peut obtenir plus de privilèges que son processus parent |
| `containerSecurityContext.runAsNonRoot`             | `true`                                           | Contrôle si le conteneur s'exécute avec un utilisateur non root |
| `containerSecurityContext.capabilities.drop`        | `[ "ALL" ]`                                      | Supprime les [capacités Linux](https://man7.org/linux/man-pages/man7/capabilities.7.html) du conteneur |
| `ttlSecondsAfterFinished`                           | `1800`                                           | Contrôle le moment où un job terminé devient éligible à la suppression en cascade. |
