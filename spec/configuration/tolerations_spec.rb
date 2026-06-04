# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'global tolerations configuration' do
  let(:template) { HelmTemplate.new(values) }

  let(:toleration) do
    [{ 'key' => 'test-key', 'operator' => 'Equal', 'value' => 'test-value', 'effect' => 'NoSchedule' }]
  end

  let(:other_toleration) do
    [{ 'key' => 'local-key', 'operator' => 'Exists', 'effect' => 'NoExecute' }]
  end

  let(:global_tolerations_resources) do
    [
      'Deployment/test-webservice-default',
      'Deployment/test-sidekiq-all-in-1-v2',
      'Deployment/test-toolbox',
      'Deployment/test-kas',
      'Deployment/test-gitlab-shell',
      'Deployment/test-registry',
      'Deployment/test-gitlab-exporter',
      'StatefulSet/test-gitaly'
    ]
  end

  let(:base_values_with_tolerations) do
    HelmTemplate.with_defaults(%(
      global:
        tolerations:
          - key: test-key
            operator: Equal
            value: test-value
            effect: NoSchedule
    ))
  end

  context 'when global.tolerations is set' do
    let(:values) { base_values_with_tolerations }

    it 'applies tolerations to all expected Deployments and StatefulSets' do
      global_tolerations_resources.each do |resource|
        expect(template.dig(resource, 'spec', 'template', 'spec', 'tolerations'))
          .to eq(toleration), "Expected tolerations on #{resource}"
      end
    end

    it 'applies tolerations to the migrations Job' do
      job = template.resources_by_kind('Job').keys.find { |k| k.include?('migrations') }
      expect(job).not_to be_nil, 'Expected a migrations Job to be present'
      expect(template.dig(job, 'spec', 'template', 'spec', 'tolerations')).to eq(toleration)
    end

    it 'applies tolerations to the certmanager-issuer Job' do
      job = template.resources_by_kind('Job').keys.find { |k| k.start_with?('Job/test-issuer-') }
      expect(job).not_to be_nil, 'Expected a certmanager-issuer Job to be present'
      expect(template.dig(job, 'spec', 'template', 'spec', 'tolerations')).to eq(toleration)
    end

    it 'applies tolerations to the upgrade-check Job' do
      job = template.resources_by_kind('Job').keys.find { |k| k.include?('upgrade-check') }
      expect(job).not_to be_nil, 'Expected an upgrade-check Job to be present'
      expect(template.dig(job, 'spec', 'template', 'spec', 'tolerations')).to eq(toleration)
    end

    it 'applies tolerations to the shared-secrets Job' do
      job = template.resources_by_kind('Job').keys.find { |k| k.include?('shared-secrets') && !k.include?('selfsign') }
      expect(job).not_to be_nil, 'Expected a shared-secrets Job to be present'
      expect(template.dig(job, 'spec', 'template', 'spec', 'tolerations')).to eq(toleration)
    end

    context 'when mailroom is enabled' do
      let(:values) do
        base_values_with_tolerations.deep_merge(YAML.safe_load(%(
          global:
            appConfig:
              incomingEmail:
                enabled: true
                password:
                  secret: mailroom-password
        )))
      end

      it 'applies tolerations to the mailroom Deployment' do
        expect(template.dig('Deployment/test-mailroom', 'spec', 'template', 'spec', 'tolerations'))
          .to eq(toleration)
      end
    end

    context 'when self-signed cert job is enabled' do
      let(:values) do
        base_values_with_tolerations.deep_merge(YAML.safe_load(%(
          installCertmanager: false
          global:
            ingress:
              configureCertmanager: false
            gatewayApi:
              configureCertmanager: false
        )))
      end

      it 'applies tolerations to the self-signed-cert Job' do
        job = template.resources_by_kind('Job').keys.find { |k| k.end_with?('selfsign') }
        expect(job).not_to be_nil, 'Expected a self-signed-cert Job to be present'
        expect(template.dig(job, 'spec', 'template', 'spec', 'tolerations')).to eq(toleration)
      end
    end

    context 'when geo-logcursor is enabled' do
      let(:values) do
        base_values_with_tolerations.deep_merge(YAML.safe_load(%(
          global:
            geo:
              enabled: true
              role: secondary
              psql:
                host: localhost
                password:
                  secret: geo-psql-secret
            hosts:
              domain: example.com
            serviceAccount:
              create: true
              enabled: true
          postgres:
            install: false
        )))
      end

      it 'applies tolerations to the geo-logcursor Deployment' do
        expect(template.dig('Deployment/test-geo-logcursor', 'spec', 'template', 'spec', 'tolerations'))
          .to eq(toleration)
      end
    end
  end

  context 'when global.tolerations is not set' do
    let(:values) { HelmTemplate.with_defaults(%(global: {})) }

    it 'does not set tolerations on any always-rendered Deployment or StatefulSet' do
      global_tolerations_resources.each do |resource|
        expect(template.dig(resource, 'spec', 'template', 'spec', 'tolerations'))
          .to be_nil, "Expected no tolerations on #{resource}"
      end
    end
  end

  context 'when praefect is enabled' do
    let(:values) do
      base_values_with_tolerations.deep_merge(YAML.safe_load(%(
        global:
          praefect:
            enabled: true
      )))
    end

    it 'applies tolerations to the praefect StatefulSet' do
      expect(template.dig('StatefulSet/test-praefect', 'spec', 'template', 'spec', 'tolerations'))
        .to eq(toleration)
    end
  end

  context 'when gitlab-pages is enabled' do
    let(:values) do
      base_values_with_tolerations.deep_merge(YAML.safe_load(%(
        global:
          pages:
            enabled: true
      )))
    end

    it 'applies tolerations to the gitlab-pages Deployment' do
      expect(template.dig('Deployment/test-gitlab-pages', 'spec', 'template', 'spec', 'tolerations'))
        .to eq(toleration)
    end
  end

  context 'when registry database migrations are enabled' do
    let(:values) do
      base_values_with_tolerations.deep_merge(YAML.safe_load(%(
        registry:
          database:
            enabled: true
            migrations:
              enabled: true
      )))
    end

    it 'applies tolerations to the registry migrations Job' do
      job = template.resources_by_kind('Job').keys.find { |k| k.include?('registry') && k.include?('migrations') }
      expect(job).not_to be_nil, 'Expected a registry migrations Job to be present'
      expect(template.dig(job, 'spec', 'template', 'spec', 'tolerations')).to eq(toleration)
    end
  end

  context 'when local tolerations override global' do
    context 'for kas' do
      let(:values) do
        base_values_with_tolerations.deep_merge(YAML.safe_load(%(
          gitlab:
            kas:
              tolerations:
                - key: local-key
                  operator: Exists
                  effect: NoExecute
        )))
      end

      it 'uses the local toleration for kas and global for others' do
        expect(template.dig('Deployment/test-kas', 'spec', 'template', 'spec', 'tolerations'))
          .to eq(other_toleration)
        expect(template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec', 'tolerations'))
          .to eq(toleration)
      end
    end

    context 'for webservice' do
      let(:values) do
        base_values_with_tolerations.deep_merge(YAML.safe_load(%(
          gitlab:
            webservice:
              tolerations:
                - key: local-key
                  operator: Exists
                  effect: NoExecute
        )))
      end

      it 'uses the local toleration for webservice and global for others' do
        expect(template.dig('Deployment/test-webservice-default', 'spec', 'template', 'spec', 'tolerations'))
          .to eq(other_toleration)
        expect(template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec', 'tolerations'))
          .to eq(toleration)
      end
    end

    context 'for sidekiq' do
      let(:values) do
        base_values_with_tolerations.deep_merge(YAML.safe_load(%(
          gitlab:
            sidekiq:
              tolerations:
                - key: local-key
                  operator: Exists
                  effect: NoExecute
        )))
      end

      it 'uses the local toleration for sidekiq' do
        sidekiq = template.resources_by_kind('Deployment').keys.find { |k| k.include?('sidekiq') }
        expect(sidekiq).not_to be_nil, 'Expected a sidekiq Deployment to be present'
        expect(template.dig(sidekiq, 'spec', 'template', 'spec', 'tolerations')).to eq(other_toleration)
      end
    end

    context 'for shared-secrets' do
      let(:values) do
        base_values_with_tolerations.deep_merge(YAML.safe_load(%(
          shared-secrets:
            tolerations:
              - key: local-key
                operator: Exists
                effect: NoExecute
        )))
      end

      it 'uses the local toleration for the shared-secrets Job' do
        job = template.resources_by_kind('Job').keys.find { |k| k.include?('shared-secrets') && !k.include?('selfsign') }
        expect(job).not_to be_nil, 'Expected a shared-secrets Job to be present'
        expect(template.dig(job, 'spec', 'template', 'spec', 'tolerations')).to eq(other_toleration)
      end

      context 'when self-signed cert job is also rendered' do
        let(:values) do
          base_values_with_tolerations.deep_merge(YAML.safe_load(%(
            installCertmanager: false
            global:
              ingress:
                configureCertmanager: false
              gatewayApi:
                configureCertmanager: false
            shared-secrets:
              tolerations:
                - key: local-key
                  operator: Exists
                  effect: NoExecute
          )))
        end

        it 'uses the local toleration for the self-signed-cert Job' do
          job = template.resources_by_kind('Job').keys.find { |k| k.end_with?('selfsign') }
          expect(job).not_to be_nil, 'Expected a self-signed-cert Job to be present'
          expect(template.dig(job, 'spec', 'template', 'spec', 'tolerations')).to eq(other_toleration)
        end
      end
    end

    context 'for toolbox backup cron' do
      let(:values) do
        base_values_with_tolerations.deep_merge(YAML.safe_load(%(
          gitlab:
            toolbox:
              backups:
                cron:
                  enabled: true
                  tolerations:
                    - key: local-key
                      operator: Exists
                      effect: NoExecute
        )))
      end

      it 'uses the cron-local toleration for the backup CronJob and global for the toolbox Deployment' do
        cronjob = template.resources_by_kind('CronJob').keys.find { |k| k.include?('backup') }
        expect(cronjob).not_to be_nil, 'Expected a backup CronJob to be present'
        expect(template.dig(cronjob, 'spec', 'jobTemplate', 'spec', 'template', 'spec', 'tolerations'))
          .to eq(other_toleration)
        expect(template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec', 'tolerations'))
          .to eq(toleration)
      end
    end

    context 'for toolbox database-reindex cron' do
      let(:values) do
        base_values_with_tolerations.deep_merge(YAML.safe_load(%(
          gitlab:
            toolbox:
              databaseReindex:
                cron:
                  enabled: true
                  tolerations:
                    - key: local-key
                      operator: Exists
                      effect: NoExecute
        )))
      end

      it 'uses the cron-local toleration for the database-reindex CronJob' do
        cronjob = template.resources_by_kind('CronJob').keys.find { |k| k.include?('reindex') }
        expect(cronjob).not_to be_nil, 'Expected a database-reindex CronJob to be present'
        expect(template.dig(cronjob, 'spec', 'jobTemplate', 'spec', 'template', 'spec', 'tolerations'))
          .to eq(other_toleration)
      end
    end
  end
end
