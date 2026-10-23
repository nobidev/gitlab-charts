---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: Troubleshooting GitLab chart development environment
---

All steps noted here are for **DEVELOPMENT ENVIRONMENTS ONLY**.
Administrators may find the information insightful, but the outlined fixes
are destructive and would have a major negative impact on production
systems.

## Passwords and secrets failing or unsynchronized

Developers commonly deploy, delete, and re-deploy a release into the same
cluster multiple times. Kubernetes secrets and persistent volume claims created by StatefulSets are
intentionally not removed by `helm delete RELEASE_NAME`.

Removing only the Kubernetes secrets leads to interesting problems. For
example, a new deployment's migration pod will fail because **GitLab Rails**
cannot connect to the database because it has the wrong password.

To completely wipe a release from a development environment including
secrets, a developer must remove both the secrets and the persistent volume
claims.

```shell
# DO NOT run these commands in a production environment. Disaster will strike.
kubectl delete secrets,pvc -lrelease=RELEASE_NAME
```

> [!note]
> This deletes all Kubernetes secrets including TLS certificates and all data
> in the database. This should not be performed in a production instance.

## Database is broken and needs reset

The database environment can be reset in a development environment by:

1. Delete the PostgreSQL StatefulSet
1. Delete the PostgreSQL PersistentVolumeClaim
1. Deploy GitLab again with `helm upgrade --install`

> [!note]
> This will delete all data in the databases and should not be run in
> production.
