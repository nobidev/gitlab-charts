require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig mobilePush' do
  describe 'mobilePush.apns' do
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
end
