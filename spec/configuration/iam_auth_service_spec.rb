# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'iamAuthService configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      gitlab:
        iamAuthService:
          enabled: false
    ))
  end

  let(:values) { default_values }
  let(:template) { HelmTemplate.new(values) }
  let(:webservice_deployment) { template["Deployment/test-webservice-default"] }

  describe 'IAM Auth service configuration' do
    context 'when iamAuthService is disabled' do
      it 'does not generate iamAuthService secret' do
        generate_secrets = template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).not_to include('iamAuthService')
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

      it 'generates secret service token' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        generate_secrets = t.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(generate_secrets).to include('test-iam-auth-secret')
        expect(generate_secrets).to include('iam_auth_service_token')
        expect(generate_secrets).to include("$(gen_random 'a-zA-Z0-9' 32 | base64)")
      end

      describe 'custom secret and key names' do
        context 'when custom secret name is provided' do
          let(:values) do
            YAML.safe_load(%(
              global:
                appConfig:
                  iamAuthService:
                    enabled: true
                    secret: custom-iam-auth-secret
            )).deep_merge!(default_values)
          end

          it 'uses the custom secret name' do
            t = HelmTemplate.new(values)
            expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

            generate_secrets = t.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')

            expect(generate_secrets).to include('custom-iam-auth-secret')
          end
        end

        context 'when custom key name is provided' do
          let(:values) do
            YAML.safe_load(%(
              global:
                appConfig:
                  iamAuthService:
                    enabled: true
                    key: custom-iam-key
            )).deep_merge!(default_values)
          end

          it 'uses the custom key name' do
            t = HelmTemplate.new(values)
            expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

            generate_secrets = t.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')

            expect(generate_secrets).to include('custom-iam-key')
          end
        end
      end
    end
  end
end
