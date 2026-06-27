# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'iamDataAccessService templates' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      gitlab:
        appConfig:
          iamDataAccessService:
            enabled: false
    ))
  end

  let(:enabled_values) do
    default_values.deep_merge(YAML.safe_load(%(
      global:
        appConfig:
          iamDataAccessService:
            enabled: true
            grpc:
              host: iam-data-access.example.com
              port: 5005
    )))
  end

  let(:configmaps) do
    [
      'ConfigMap/test-webservice',
      'ConfigMap/test-sidekiq',
      'ConfigMap/test-toolbox'
    ]
  end

  describe 'gitlab.yml.erb rendering' do
    context 'when disabled (default for self-managed)' do
      it 'renders the block with enabled false and the secret_file' do
        t = HelmTemplate.new(default_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        configmaps.each do |configmap|
          config = t.dig(configmap, 'data', 'gitlab.yml.erb')
          expect(config).to include('iam_data_access_service'), "Expected iam_data_access_service in #{configmap}"
          expect(config).to include('/etc/gitlab/iam-data-access/.gitlab_iam_data_access_secret')
        end
      end
    end

    context 'when enabled with grpc configured' do
      it 'renders the grpc host and port' do
        t = HelmTemplate.new(enabled_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        configmaps.each do |configmap|
          config = t.dig(configmap, 'data', 'gitlab.yml.erb')
          expect(config).to include('iam-data-access.example.com')
          expect(config).to include('5005')
        end
      end
    end
  end

  describe 'gitlab.appConfig.iamDataAccessService.authToken' do
    context 'when enabled with no custom secret/key' do
      it 'generates the default secret and key' do
        t = HelmTemplate.new(enabled_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        generate_secrets = t.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).to include('test-iam-data-access-secret')
        expect(generate_secrets).to include('iam_data_access_service_token')
      end
    end

    context 'when enabled with custom secret/key' do
      let(:values) do
        enabled_values.deep_merge(YAML.safe_load(%(
          global:
            appConfig:
              iamDataAccessService:
                authToken:
                  secret: custom-iam-data-access-secret
                  key: custom-iam-data-access-key
        )))
      end

      it 'uses the custom secret and key' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        generate_secrets = t.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).to include('custom-iam-data-access-secret')
        expect(generate_secrets).to include('custom-iam-data-access-key')
      end
    end

    context 'when disabled' do
      it 'does not generate the secret' do
        t = HelmTemplate.new(default_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        generate_secrets = t.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).not_to include('iam-data-access')
      end
    end
  end

  describe 'gitlab.appConfig.iamDataAccessService.mountSecrets' do
    let(:deployments) do
      {
        'Deployment/test-webservice-default' => 'init-webservice-secrets',
        'Deployment/test-sidekiq-all-in-1-v2' => 'init-sidekiq-secrets',
        'Deployment/test-toolbox' => 'init-toolbox-secrets'
      }
    end

    def find_secret_mount(template, deployment, volume_name)
      template.projected_volume_sources(deployment, volume_name)&.find do |item|
        item.dig('secret', 'name') == 'test-iam-data-access-secret' &&
          item.dig('secret', 'items', 0, 'key') == 'iam_data_access_service_token'
      end
    end

    context 'when disabled' do
      it 'does not mount any secrets' do
        t = HelmTemplate.new(default_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        deployments.each do |deployment, volume_name|
          expect(find_secret_mount(t, deployment, volume_name)).to be_nil, "Expected no iam-data-access secret mount in #{deployment}"
        end
      end
    end

    context 'when enabled' do
      it 'mounts the shared secret on webservice, sidekiq, and toolbox deployments' do
        t = HelmTemplate.new(enabled_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        deployments.each do |deployment, volume_name|
          expect(find_secret_mount(t, deployment, volume_name)).not_to be_nil, "Expected iam-data-access secret mount in #{deployment}"
        end
      end
    end
  end

  describe 'checkConfig' do
    context 'when disabled with no grpc' do
      it 'does not error' do
        t = HelmTemplate.new(default_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      end
    end

    context 'when enabled without grpc.port' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          global:
            appConfig:
              iamDataAccessService:
                enabled: true
                grpc:
                  host: iam-data-access.example.com
        )))
      end

      it 'errors that grpc.port is required' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).not_to eq(0)
        expect(t.stderr).to include('grpc.port is required when iamDataAccessService is enabled')
      end
    end

    context 'when enabled without grpc.host' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          global:
            appConfig:
              iamDataAccessService:
                enabled: true
                grpc:
                  port: 5005
        )))
      end

      it 'errors that grpc.host is required' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).not_to eq(0)
        expect(t.stderr).to include('grpc.host is required when iamDataAccessService is enabled')
      end
    end
  end
end
