require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig template' do
  # This is not actually in _checkConfig.tpl, but it uses `required`, so
  # acts in a similar way
  describe 'certmanager-issuer.email' do
    let(:success_values) { default_required_values }
    let(:error_values) { nil }
    let(:error_output) { 'Please set certmanager-issuer.email' }

    include_examples 'config validation',
                     success_description: 'when set',
                     error_description: 'when unset'
  end

  describe 'serviceAccount' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          serviceAccount:
            enabled: true
            create: false
            name: myaccount
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          serviceAccount:
            enabled: true
            create: true
            name: myaccount
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'Please set `global.serviceAccount.create=false`' }

    include_examples 'config validation',
                     success_description: 'when global ServiceAccount name is provided with `create=false`',
                     error_description: 'when global ServiceAccount name is provided with `create=true`'
  end

  describe 'mobilePush.apns' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            mobile_push:
              apns:
                auth_key:
                  secret: gitlab-mobile-push-apns
                key_id: ABC123DEFG
                team_id: DEF456GHIJ
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            mobile_push:
              apns:
                auth_key:
                  secret: gitlab-mobile-push-apns
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'When configuring mobile push APNs, be sure to specify the key ID' }

    include_examples 'config validation',
                     success_description: 'when the APNs auth key, key ID and team ID are provided',
                     error_description: 'when the APNs auth key is provided without key ID and team ID'
  end
end
