require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig mobilePush' do
  describe 'mobilePush.apns (key ID and team ID)' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            mobilePush:
              apns:
                authKey:
                  secret: gitlab-mobile-push-apns
                keyId: ABC123DEFG
                teamId: DEF456GHIJ
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            mobilePush:
              apns:
                authKey:
                  secret: gitlab-mobile-push-apns
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'When configuring mobile push APNs, be sure to specify the key ID' }

    include_examples 'config validation',
                     success_description: 'when the APNs auth key, key ID and team ID are provided',
                     error_description: 'when the APNs auth key is provided without key ID and team ID'
  end

  describe 'mobilePush.apns (auth key secret)' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            mobilePush:
              apns:
                authKey:
                  secret: gitlab-mobile-push-apns
                keyId: ABC123DEFG
                teamId: DEF456GHIJ
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            mobilePush:
              apns:
                keyId: ABC123DEFG
                teamId: DEF456GHIJ
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'When configuring mobile push APNs, be sure to provide the Kubernetes secret' }

    include_examples 'config validation',
                     success_description: 'when the APNs auth key, key ID and team ID are provided',
                     error_description: 'when APNs key ID and team ID are provided without the auth key'
  end

  describe 'mobilePush.apns (topic only)' do
    let(:success_values) { default_required_values }

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            mobilePush:
              apns:
                topic: com.example.app
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'When configuring mobile push APNs, be sure to provide the Kubernetes secret' }

    include_examples 'config validation',
                     success_description: 'when no APNs settings are provided',
                     error_description: 'when only the APNs topic is provided'
  end

  describe 'mobilePush.apns (team ID only missing)' do
    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            mobilePush:
              apns:
                authKey:
                  secret: gitlab-mobile-push-apns
                keyId: ABC123DEFG
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'When configuring mobile push APNs, be sure to specify the Apple team ID' }

    include_examples 'config validation',
                     error_description: 'when only the APNs team ID is not provided'
  end

  describe 'mobilePush.apns (whitespace-only values)' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            mobilePush:
              apns:
                authKey:
                  secret: "   "
                keyId: "   "
                teamId: "   "
                topic: "   "
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            mobilePush:
              apns:
                authKey:
                  secret: gitlab-mobile-push-apns
                keyId: "   "
                teamId: DEF456GHIJ
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'When configuring mobile push APNs, be sure to specify the key ID' }

    include_examples 'config validation',
                     success_description: 'when all APNs settings are whitespace-only, treating them as unset',
                     error_description: 'when the APNs key ID is whitespace-only'
  end

  describe 'mobilePush.apns (non-string values)' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            mobilePush:
              apns:
                authKey:
                  secret: gitlab-mobile-push-apns
                keyId: "1234567890"
                teamId: DEF456GHIJ
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            mobilePush:
              apns:
                authKey:
                  secret: gitlab-mobile-push-apns
                keyId: 1234567890
                teamId: DEF456GHIJ
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'Quote the value of: `global.appConfig.mobilePush.apns.keyId`' }

    include_examples 'config validation',
                     success_description: 'when a numeric-looking APNs key ID is quoted',
                     error_description: 'when the APNs key ID is an unquoted number'
  end
end
