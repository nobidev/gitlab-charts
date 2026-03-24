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

  describe 'gitlab.appConfig.iamAuthService.authToken.key' do
    context 'when no custom key name provided' do
      let(:values) do
        YAML.safe_load(%(
          global:
            appConfig:
              iamAuthService:
                enabled: true
        )).deep_merge!(default_values)
      end

      it 'returns the default key name' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        generate_secrets = template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).to include('iam_auth_service_token')
      end
    end

    context 'when custom key name provided' do
      let(:values) do
        YAML.safe_load(%(
          global:
            appConfig:
              iamAuthService:
                enabled: true
                authToken:
                  key: custom-iam-key
        )).deep_merge!(default_values)
      end

      it 'returns the custom key name' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        generate_secrets = template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).to include('custom-iam-key')
      end
    end
  end

  describe 'gitlab.appConfig.iamAuthService.authToken.secret' do
    context 'when custom secret name provided' do
      let(:values) do
        YAML.safe_load(%(
          global:
            appConfig:
              iamAuthService:
                enabled: true
        )).deep_merge!(default_values)
      end

      it 'returns the default secret name' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        generate_secrets = template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).to include('test-iam-auth-secret')
      end
    end

    context 'when iamAuthService is enabled with custom secret' do
      let(:values) do
        YAML.safe_load(%(
          global:
            appConfig:
              iamAuthService:
                enabled: true
                authToken:
                  secret: custom-iam-auth-secret
        )).deep_merge!(default_values)
      end

      it 'returns the custom secret name' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        generate_secrets = template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).to include('custom-iam-auth-secret')
      end
    end
  end

  describe 'gitlab.appConfig.iamAuthService.mountSecrets' do
    let(:webservice_secret_mounts) do
      template.projected_volume_sources(
        'Deployment/test-webservice-default',
        'init-webservice-secrets'
      )
    end

    let(:shared_secret_mount) do
      webservice_secret_mounts.find do |item|
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

        expect(shared_secret_mount).to be_nil
      end
    end

    context 'when iamAuthService is enabled' do
      let(:values) do
        YAML.safe_load(%(
          global:
            appConfig:
              iamAuthService:
                enabled: true
        )).deep_merge!(default_values)
      end

      it 'mounts shared secret on webservice deployment' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        expect(shared_secret_mount).not_to be_nil
      end
    end
  end
end
