---
stage: GitLab Duo Self-Hosted
group: Custom models
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: AI Gateway chart
---

{{< details >}}

- Tier: Premium, Ultimate
- Offering: GitLab Self-Managed
- Status: Experiment

{{< /details >}}

The AI Gateway chart deploys the AI Gateway as a sub-chart alongside your GitLab instance.
It enables GitLab Duo Self-Hosted and the GitLab Duo Agent Platform on Kubernetes.
This feature is an [experiment](https://docs.gitlab.com/ee/policy/experiment-beta-support.html).

Prerequisites:

- TLS is required for the GitLab URL. In production mode, the AI gateway requires the GitLab endpoint to be secured to perform authentication with the GitLab instance.
  Because this configuration is set correctly by default, no action is required.
- Either:
  - A cloud license applied with [usage billing](https://docs.gitlab.com/subscriptions/gitlab_credits/) enabled.
  - An offline license with the
    [GitLab Duo Agent Platform Self-Hosted](https://docs.gitlab.com/subscriptions/subscription-add-ons/#gitlab-duo-agent-platform-self-hosted) addon.

## Known issues

TLS is not enabled for the AI Gateway. Internal traffic to the AI Gateway service is not secured.
Because this service is not accessible externally, we don't expect this known issue to be of any concern.

## Configure and deploy the chart

To configure and deploy the chart:

1. Deploy the chart with the following configuration:

   ```yaml
   global:
     hosts:
       domain: <YOUR_DOMAIN>

   ai-gateway:
     install: true
   ```

1. After the chart is deployed and your instance is available, on in the upper-right corner of your GitLab instance, select **Admin**.
1. In the left sidebar, select **GitLab Duo**.
1. Select **Change configuration** and:
   1. Change the **Local AI Gateway URL** to `http://<RELEASE_NAME>-ai-gateway`.
   1. Change the **Local URL for the GitLab Duo Agent Platform service** to `<RELEASE_NAME>-ai-gateway:50052`.
   1. Clear the **Use TLS for the GitLab Duo Agent Platform service**.
   1. If you are using an offline license, make sure you select a model for the **Code Suggestions** and the **GitLab Duo Agent Platform** features.
      For more information, see [configure GitLab to use self-hosted models](https://docs.gitlab.com/administration/gitlab_duo_self_hosted/configure_duo_features/).
1. Select **Save changes**.
1. On the **GitLab Duo** page (`/admin/gitlab_duo`), select **Run health check** to verify that everything is working correctly.
