# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'global dnsConfig configuration' do
  let(:template) { HelmTemplate.new(values) }

  let(:dns_config) do
    {
      'options' => [
        { 'name' => 'ndots', 'value' => '2' }
      ]
    }
  end

  let(:other_dns_config) do
    {
      'options' => [
        { 'name' => 'ndots', 'value' => '3' },
        { 'name' => 'edns0' }
      ]
    }
  end

  let(:global_dns_config_resources) do
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

  let(:base_values_with_dns_config) do
    HelmTemplate.with_defaults(%(
      global:
        dnsConfig:
          options:
            - name: ndots
              value: "2"
    ))
  end

  context 'when global.dnsConfig is set' do
    let(:values) { base_values_with_dns_config }

    it 'applies dnsConfig to all expected Deployments and StatefulSets' do
      global_dns_config_resources.each do |resource|
        expect(template.dig(resource, 'spec', 'template', 'spec', 'dnsConfig'))
          .to eq(dns_config), "Expected dnsConfig on #{resource}"
      end
    end

    it 'applies dnsConfig to the migrations Job' do
      job = template.resources_by_kind('Job').keys.find { |k| k.include?('migrations') }
      expect(job).not_to be_nil, 'Expected a migrations Job to be present'
      expect(template.dig(job, 'spec', 'template', 'spec', 'dnsConfig')).to eq(dns_config)
    end

    it 'applies dnsConfig to the certmanager-issuer Job' do
      job = template.resources_by_kind('Job').keys.find { |k| k.start_with?('Job/test-issuer-') }
      expect(job).not_to be_nil, 'Expected a certmanager-issuer Job to be present'
      expect(template.dig(job, 'spec', 'template', 'spec', 'dnsConfig')).to eq(dns_config)
    end

    it 'applies dnsConfig to the upgrade-check Job' do
      job = template.resources_by_kind('Job').keys.find { |k| k.include?('upgrade-check') }
      expect(job).not_to be_nil, 'Expected an upgrade-check Job to be present'
      expect(template.dig(job, 'spec', 'template', 'spec', 'dnsConfig')).to eq(dns_config)
    end

    it 'applies dnsConfig to the shared-secrets Job' do
      job = template.resources_by_kind('Job').keys.find { |k| k.include?('shared-secrets') && !k.include?('selfsign') }
      expect(job).not_to be_nil, 'Expected a shared-secrets Job to be present'
      expect(template.dig(job, 'spec', 'template', 'spec', 'dnsConfig')).to eq(dns_config)
    end

    context 'when mailroom is enabled' do
      let(:values) do
        base_values_with_dns_config.deep_merge(YAML.safe_load(%(
          global:
            appConfig:
              incomingEmail:
                enabled: true
                password:
                  secret: mailroom-password
        )))
      end

      it 'applies dnsConfig to the mailroom Deployment' do
        expect(template.dig('Deployment/test-mailroom', 'spec', 'template', 'spec', 'dnsConfig'))
          .to eq(dns_config)
      end
    end

    context 'when self-signed cert job is enabled' do
      let(:values) do
        base_values_with_dns_config.deep_merge(YAML.safe_load(%(
          installCertmanager: false
          global:
            ingress:
              configureCertmanager: false
            gatewayApi:
              configureCertmanager: false
        )))
      end

      it 'applies dnsConfig to the self-signed-cert Job' do
        job = template.resources_by_kind('Job').keys.find { |k| k.end_with?('selfsign') }
        expect(job).not_to be_nil, 'Expected a self-signed-cert Job to be present'
        expect(template.dig(job, 'spec', 'template', 'spec', 'dnsConfig')).to eq(dns_config)
      end
    end

    context 'when geo-logcursor is enabled' do
      let(:values) do
        base_values_with_dns_config.deep_merge(YAML.safe_load(%(
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

      it 'applies dnsConfig to the geo-logcursor Deployment' do
        expect(template.dig('Deployment/test-geo-logcursor', 'spec', 'template', 'spec', 'dnsConfig'))
          .to eq(dns_config)
      end
    end
  end

  context 'when global.dnsConfig is not set' do
    let(:values) { HelmTemplate.with_defaults(%(global: {})) }

    it 'does not set dnsConfig on any always-rendered Deployment or StatefulSet' do
      global_dns_config_resources.each do |resource|
        expect(template.dig(resource, 'spec', 'template', 'spec', 'dnsConfig'))
          .to be_nil, "Expected no dnsConfig on #{resource}"
      end
    end
  end

  context 'when praefect is enabled' do
    let(:values) do
      base_values_with_dns_config.deep_merge(YAML.safe_load(%(
        global:
          praefect:
            enabled: true
      )))
    end

    it 'applies dnsConfig to the praefect StatefulSet' do
      expect(template.dig('StatefulSet/test-praefect', 'spec', 'template', 'spec', 'dnsConfig'))
        .to eq(dns_config)
    end
  end

  context 'when gitlab-pages is enabled' do
    let(:values) do
      base_values_with_dns_config.deep_merge(YAML.safe_load(%(
        global:
          pages:
            enabled: true
      )))
    end

    it 'applies dnsConfig to the gitlab-pages Deployment' do
      expect(template.dig('Deployment/test-gitlab-pages', 'spec', 'template', 'spec', 'dnsConfig'))
        .to eq(dns_config)
    end
  end

  context 'when registry database migrations are enabled' do
    let(:values) do
      base_values_with_dns_config.deep_merge(YAML.safe_load(%(
        registry:
          database:
            enabled: true
            migrations:
              enabled: true
      )))
    end

    it 'applies dnsConfig to the registry migrations Job' do
      job = template.resources_by_kind('Job').keys.find { |k| k.include?('registry') && k.include?('migrations') }
      expect(job).not_to be_nil, 'Expected a registry migrations Job to be present'
      expect(template.dig(job, 'spec', 'template', 'spec', 'dnsConfig')).to eq(dns_config)
    end
  end

  context 'when local dnsConfig overrides global' do
    context 'for kas' do
      let(:values) do
        base_values_with_dns_config.deep_merge(YAML.safe_load(%(
          gitlab:
            kas:
              dnsConfig:
                options:
                  - name: ndots
                    value: "3"
                  - name: edns0
        )))
      end

      it 'uses the local dnsConfig for kas and global for others' do
        expect(template.dig('Deployment/test-kas', 'spec', 'template', 'spec', 'dnsConfig'))
          .to eq(other_dns_config)
        expect(template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec', 'dnsConfig'))
          .to eq(dns_config)
      end
    end

    context 'for webservice' do
      let(:values) do
        base_values_with_dns_config.deep_merge(YAML.safe_load(%(
          gitlab:
            webservice:
              dnsConfig:
                options:
                  - name: ndots
                    value: "3"
                  - name: edns0
        )))
      end

      it 'uses the local dnsConfig for webservice and global for others' do
        expect(template.dig('Deployment/test-webservice-default', 'spec', 'template', 'spec', 'dnsConfig'))
          .to eq(other_dns_config)
        expect(template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec', 'dnsConfig'))
          .to eq(dns_config)
      end
    end

    context 'for sidekiq' do
      let(:values) do
        base_values_with_dns_config.deep_merge(YAML.safe_load(%(
          gitlab:
            sidekiq:
              dnsConfig:
                options:
                  - name: ndots
                    value: "3"
                  - name: edns0
        )))
      end

      it 'uses the local dnsConfig for sidekiq' do
        sidekiq = template.resources_by_kind('Deployment').keys.find { |k| k.include?('sidekiq') }
        expect(sidekiq).not_to be_nil, 'Expected a sidekiq Deployment to be present'
        expect(template.dig(sidekiq, 'spec', 'template', 'spec', 'dnsConfig')).to eq(other_dns_config)
      end
    end

    context 'for shared-secrets' do
      let(:values) do
        base_values_with_dns_config.deep_merge(YAML.safe_load(%(
          shared-secrets:
            dnsConfig:
              options:
                - name: ndots
                  value: "3"
                - name: edns0
        )))
      end

      it 'uses the local dnsConfig for the shared-secrets Job' do
        job = template.resources_by_kind('Job').keys.find { |k| k.include?('shared-secrets') && !k.include?('selfsign') }
        expect(job).not_to be_nil, 'Expected a shared-secrets Job to be present'
        expect(template.dig(job, 'spec', 'template', 'spec', 'dnsConfig')).to eq(other_dns_config)
      end

      context 'when self-signed cert job is also rendered' do
        let(:values) do
          base_values_with_dns_config.deep_merge(YAML.safe_load(%(
            installCertmanager: false
            global:
              ingress:
                configureCertmanager: false
              gatewayApi:
                configureCertmanager: false
            shared-secrets:
              dnsConfig:
                options:
                  - name: ndots
                    value: "3"
                  - name: edns0
          )))
        end

        it 'uses the local dnsConfig for the self-signed-cert Job' do
          job = template.resources_by_kind('Job').keys.find { |k| k.end_with?('selfsign') }
          expect(job).not_to be_nil, 'Expected a self-signed-cert Job to be present'
          expect(template.dig(job, 'spec', 'template', 'spec', 'dnsConfig')).to eq(other_dns_config)
        end
      end
    end

    context 'for upgradeCheck' do
      let(:values) do
        base_values_with_dns_config.deep_merge(YAML.safe_load(%(
          upgradeCheck:
            dnsConfig:
              options:
                - name: ndots
                  value: "3"
                - name: edns0
        )))
      end

      it 'uses the local dnsConfig for the upgrade-check Job' do
        job = template.resources_by_kind('Job').keys.find { |k| k.include?('upgrade-check') }
        expect(job).not_to be_nil, 'Expected an upgrade-check Job to be present'
        expect(template.dig(job, 'spec', 'template', 'spec', 'dnsConfig')).to eq(other_dns_config)
      end
    end

    context 'for toolbox backup cron' do
      let(:values) do
        base_values_with_dns_config.deep_merge(YAML.safe_load(%(
          gitlab:
            toolbox:
              backups:
                cron:
                  enabled: true
                  dnsConfig:
                    options:
                      - name: ndots
                        value: "3"
                      - name: edns0
        )))
      end

      it 'uses the cron-local dnsConfig for the backup CronJob and global for the toolbox Deployment' do
        cronjob = template.resources_by_kind('CronJob').keys.find { |k| k.include?('backup') }
        expect(cronjob).not_to be_nil, 'Expected a backup CronJob to be present'
        expect(template.dig(cronjob, 'spec', 'jobTemplate', 'spec', 'template', 'spec', 'dnsConfig'))
          .to eq(other_dns_config)
        expect(template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec', 'dnsConfig'))
          .to eq(dns_config)
      end
    end

    context 'for toolbox database-reindex cron' do
      let(:values) do
        base_values_with_dns_config.deep_merge(YAML.safe_load(%(
          gitlab:
            toolbox:
              databaseReindex:
                cron:
                  enabled: true
                  dnsConfig:
                    options:
                      - name: ndots
                        value: "3"
                      - name: edns0
        )))
      end

      it 'uses the cron-local dnsConfig for the database-reindex CronJob' do
        cronjob = template.resources_by_kind('CronJob').keys.find { |k| k.include?('reindex') }
        expect(cronjob).not_to be_nil, 'Expected a database-reindex CronJob to be present'
        expect(template.dig(cronjob, 'spec', 'jobTemplate', 'spec', 'template', 'spec', 'dnsConfig'))
          .to eq(other_dns_config)
      end
    end

    context 'for sidekiq per-pod-queue override' do
      let(:values) do
        base_values_with_dns_config.deep_merge(YAML.safe_load(%(
          gitlab:
            sidekiq:
              pods:
                - name: all-in-1
                  concurrency: 20
                  dnsConfig:
                    options:
                      - name: ndots
                        value: "3"
                      - name: edns0
        )))
      end

      it 'uses the per-pod dnsConfig for the sidekiq Deployment' do
        sidekiq = template.resources_by_kind('Deployment').keys.find { |k| k.include?('sidekiq') }
        expect(sidekiq).not_to be_nil, 'Expected a sidekiq Deployment to be present'
        expect(template.dig(sidekiq, 'spec', 'template', 'spec', 'dnsConfig')).to eq(other_dns_config)
      end
    end

    context 'for webservice per-deployment override' do
      let(:values) do
        base_values_with_dns_config.deep_merge(YAML.safe_load(%(
          gitlab:
            webservice:
              deployments:
                default:
                  ingress:
                    path: /
                  dnsConfig:
                    options:
                      - name: ndots
                        value: "3"
                      - name: edns0
        )))
      end

      it 'uses the per-deployment dnsConfig for the webservice Deployment' do
        expect(template.dig('Deployment/test-webservice-default', 'spec', 'template', 'spec', 'dnsConfig'))
          .to eq(other_dns_config)
      end
    end
  end
end
