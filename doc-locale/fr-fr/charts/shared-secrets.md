---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Utilisation du job Shared-Secrets
---

{{< details >}}

- Niveau : Free, Premium, Ultimate
- Offre : GitLab Self-Managed

{{< /details >}}

Le job `shared-secrets` est responsable du provisionnement d'une variété de secrets utilisés dans l'ensemble de l'installation, sauf indication manuelle contraire. Cela inclut :

1. Mot de passe root initial
1. Certificats TLS auto-signés pour tous les services publics :  GitLab, MinIO et Registry
1. Certificats d'authentification Registry
1. Secrets MinIO, Registry, GitLab Shell et Gitaly
1. Mots de passe Redis et PostgreSQL
1. Clés d'hôte SSH
1. Secret Rails GitLab pour [les identifiants chiffrés](https://docs.gitlab.com/administration/encrypted_configuration/)

## Options de ligne de commande d'installation {#installation-command-line-options}

Le tableau ci-dessous contient toutes les configurations possibles pouvant être fournies à la commande `helm install` à l'aide du flag `--set` :

| Paramètre                    | Défaut                                                    | Description |
|------------------------------|------------------------------------------------------------|-------------|
| `enabled`                    | `true`                                                     | [Voir ci-dessous](#disable-functionality) |
| `env`                        | `production`                                               | Environnement Rails |
| `podLabels`                  |                                                            | Labels de pod supplémentaires. Ne sera pas utilisé pour les sélecteurs. |
| `annotations`                |                                                            | Annotations de pod supplémentaires. |
| `image.pullPolicy`           | `Always`                                                   | **DEPRECATED** : Utilisez `global.kubectl.image.pullPolicy` à la place. |
| `image.pullSecrets`          |                                                            | **DEPRECATED** : Utilisez `global.kubectl.image.pullSecrets` à la place. |
| `image.repository`           | `registry.gitlab.com/gitlab-org/build/cng/kubectl`         | **DEPRECATED** : Utilisez `global.kubectl.image.repository` à la place. |
| `image.tag`                  | `1f8690f03f7aeef27e727396927ab3cc96ac89e7`                 | **DEPRECATED** : Utilisez `global.kubectl.image.tag` à la place. |
| `priorityClassName`          |                                                            | [Classe de priorité](https://kubernetes.io/docs/concepts/scheduling-eviction/pod-priority-preemption/) assignée aux pods |
| `rbac.create`                | `true`                                                     | Créer des rôles et des liaisons RBAC |
| `resources`                  |                                                            | Requêtes de ressources, limites |
| `securityContext.fsGroup`    | `65534`                                                    | ID utilisateur pour monter les systèmes de fichiers |
| `securityContext.runAsUser`  | `65534`                                                    | ID utilisateur pour exécuter le conteneur |
| `selfsign.caSubject`         | `GitLab Helm Chart`                                        | Sujet CA selfsign |
| `selfsign.image.repository`  | `registry.gitlab.com/gitlab-org/build/cnf/cfssl-self-sign` | Dépôt d'image selfsign |
| `selfsign.image.pullSecrets` |                                                            | Secrets pour le dépôt d'image |
| `selfsign.image.tag`         |                                                            | Tag d'image selfsign |
| `selfsign.keyAlgorithm`      | `rsa`                                                      | Algorithme de clé du certificat selfsign |
| `selfsign.keySize`           | `4096`                                                     | Taille de clé du certificat selfsign |
| `serviceAccount.enabled`     | `true`                                                     | Définir serviceAccountName sur le(s) job(s) |
| `serviceAccount.create`      | `true`                                                     | Créer un compte de service |
| `serviceAccount.name`        | `RELEASE_NAME-shared-secrets`                              | Nom du compte de service à spécifier sur le(s) job(s) (et sur le serviceAccount lui-même si `serviceAccount.create=true`) |
| `tolerations`                | `[]`                                                       | Labels de tolérance pour l'assignation des pods |

## Exemples de configuration de job {#job-configuration-examples}

### `tolerations` {#tolerations}

`tolerations` vous permet de planifier des pods sur des nœuds worker marqués (tainted)

Voici un exemple d'utilisation de `tolerations` :

```yaml
tolerations:
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
- key: "node_label"
  operator: "Equal"
  value: "true"
  effect: "NoExecute"
```

## Désactiver la fonctionnalité {#disable-functionality}

Certains utilisateurs peuvent souhaiter désactiver explicitement la fonctionnalité fournie par ce job. Pour ce faire, nous avons fourni le flag `enabled` en tant que booléen, dont la valeur par défaut est `true`.

Pour désactiver le job, passez `--set shared-secrets.enabled=false`, ou passez ce qui suit dans un YAML via le flag `-f` à `helm` :

```yaml
shared-secrets:
  enabled: false
```

> [!note] Si vous désactivez ce job, vous **devez** créer manuellement tous les secrets et fournir tout le contenu secret nécessaire. Consultez [installation/secrets](../installation/secrets.md#manual-secret-creation-optional) pour plus de détails.
