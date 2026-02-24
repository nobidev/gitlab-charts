---
stage: GitLab Delivery
group: Operate
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: ClickHouse database
---

The GitLab chart can be configured to set up GitLab with an external ClickHouse database via the HTTP interface. Required parameters:

| Parameter                                | Description |
|------------------------------------------|-------------|
| `global.clickhouse.main.url`             | URL for the database |
| `global.clickhouse.main.username`        | Database Username |
| `global.clickhouse.main.password.secret` | Name of the configured secret |
| `global.clickhouse.main.password.key`    | Which key to use as the password within the secret |
| `global.clickhouse.main.database`        | Database name |

> [!warning]
> Using ClickHouse is intended for experimenting and testing purposes only at the moment.

## Configuring the password

The password can be set manually using the `kubectl` CLI tool:

```shell
kubectl create secret generic gitlab-clickhouse-password --from-literal="main_password=PASSWORD_HERE"
```

## Starting a chart with ClickHouse

You can fill in the details related to the ClickHouse server in the `examples/kind/enable-clickhouse.yaml` file.

Start the chart:

```shell
helm upgrade --install gitlab . \
  --timeout 600s \
  --set global.image.pullPolicy=Always \
  --set global.hosts.domain=YOUR_IP.nip.io \
  --set global.hosts.externalIP=YOUR_IP \
  -f examples/kind/values-base.yaml \
  -f examples/kind/values-no-ssl.yaml \
  -f examples/clickhouse/enable-clickhouse.yaml
```

## ClickHouse setup

ClickHouse must be set up as per the guide provided in [Run and configure ClickHouse](https://docs.gitlab.com/integration/clickhouse/#run-and-configure-clickhouse).

The GitLab Helm chart will not perform the initial setup steps required to start using ClickHouse such as creating databases or creating a user with the appropriate permissions.

## ClickHouse migrations

Database migrations for ClickHouse are executed using the [GitLab-Migrations chart](../charts/gitlab/migrations/_index.md)

The [Webservice](../charts/gitlab/webservice/_index.md) and [Sidekiq](../charts/gitlab/sidekiq/_index.md) charts create Deployments with an `initContainer` called `dependencies`.
When ClickHouse is enabled for an installation, the `dependencies` `initContainer` fails if:

- ClickHouse is not available.
- Some database migrations have not been executed yet.

The behavior of this container can be controlled using these environment variables:

- `BYPASS_POST_DEPLOYMENT=true`: The dependencies check passes if all regular migrations have been executed and only post-deployment migrations are pending.
- `BYPASS_CLICKHOUSE_SCHEMA_VERSION=true` (not recommended): The dependencies check passes even if regular migrations for ClickHouse have not been executed.

Add these environment variables to the `extraEnv` configuration of the [Webservice](../charts/gitlab/webservice/_index.md) and [Sidekiq](../charts/gitlab/sidekiq/_index.md) charts.
