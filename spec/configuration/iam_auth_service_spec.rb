# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'iamAuthService templates' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      gitlab:
        appConfig:
          iamAuthService:
            enabled: false
    ))
  end

  let(:values) { default_values }
  let(:template) { HelmTemplate.new(values) }

  let(:enabled_values) do
    YAML.safe_load(%(
      global:
        appConfig:
          iamAuthService:
            enabled: true
            http:
              host: iam-auth.example.com
              port: 443
            grpc:
              host: iam-auth.example.com
              port: 5004
            issuer: https://iam-auth.example.com
    ))
  end

  describe 'gitlab.appConfig.iamAuthService.authToken.key' do
    context 'when no custom key name provided' do
      let(:values) do
        enabled_values.deep_merge!(default_values)
      end

      it 'returns the default key name' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        generate_secrets = template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).to include('iam_auth_service_token')
      end
    end

    context 'when custom key name provided' do
      let(:values) do
        enabled_values.deep_merge!(YAML.safe_load(%(
          global:
            appConfig:
              iamAuthService:
                authToken:
                  key: custom-iam-key
        ))).deep_merge!(default_values)
      end

      it 'returns the custom key name' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        generate_secrets = template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).to include('custom-iam-key')
      end
    end
  end

  describe 'gitlab.appConfig.iamAuthService.authToken.secret' do
    context 'when no custom secret name provided' do
      let(:values) do
        enabled_values.deep_merge!(default_values)
      end

      it 'returns the default secret name' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        generate_secrets = template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).to include('test-iam-auth-secret')
      end
    end

    context 'when iamAuthService is enabled with custom secret' do
      let(:values) do
        enabled_values.deep_merge!(YAML.safe_load(%(
          global:
            appConfig:
              iamAuthService:
                authToken:
                  secret: custom-iam-auth-secret
        ))).deep_merge!(default_values)
      end

      it 'returns the custom secret name' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        generate_secrets = template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).to include('custom-iam-auth-secret')
      end
    end
  end

  describe 'gitlab.appConfig.iamAuthService.mountSecrets' do
    let(:deployments) do
      {
        'Deployment/test-webservice-default' => 'init-webservice-secrets',
        'Deployment/test-sidekiq-all-in-1-v2' => 'init-sidekiq-secrets',
        'Deployment/test-toolbox' => 'init-toolbox-secrets'
      }
    end

    def find_iam_auth_secret_mount(deployment, volume_name)
      template.projected_volume_sources(deployment, volume_name)&.find do |item|
        item.dig('secret', 'name') == 'test-iam-auth-secret' && item.dig('secret', 'items')[0]['key'] == 'iam_auth_service_token'
      end
    end

    context 'when iamAuthService is disabled' do
      let(:values) do
        YAML.safe_load(%(
          global:
            appConfig:
              iamAuthService:
                enabled: false
        )).deep_merge!(default_values)
      end

      it 'does not mount any secrets' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        deployments.each do |deployment, volume_name|
          expect(find_iam_auth_secret_mount(deployment, volume_name)).to be_nil, "Expected no iam-auth secret mount in #{deployment}"
        end
      end
    end

    context 'when iamAuthService is enabled' do
      let(:values) do
        enabled_values.deep_merge!(default_values)
      end

      it 'mounts shared secret on webservice, sidekiq, and toolbox deployments' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        deployments.each do |deployment, volume_name|
          expect(find_iam_auth_secret_mount(deployment, volume_name)).not_to be_nil, "Expected iam-auth secret mount in #{deployment}"
        end
      end
    end
  end
end
