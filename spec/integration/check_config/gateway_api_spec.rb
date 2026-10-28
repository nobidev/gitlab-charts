require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig Gateway API' do
  describe 'gatewayApi.externalTlsTermination' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          gatewayApi:
            externalTlsTermination: true
      )).deep_merge!(default_required_values)
    end

    include_examples 'config validation', success_description: 'when global.hosts.https is true'

    {
      'global.hosts.https is false' => [
        { 'global' => { 'hosts' => { 'https' => false } } },
        'global.gatewayApi.externalTlsTermination requires global.hosts.https to be true'
      ],
      'smartcard is enabled' => [
        { 'global' => { 'appConfig' => { 'smartcard' => { 'enabled' => true } } } },
        'Smartcard authentication is not supported with global.gatewayApi.externalTlsTermination'
      ],
      'a listener uses HTTPS' => [
        { 'gatewayApiResources' => { 'gateway' => { 'listeners' => { 'gitlab-web' => { 'protocol' => 'HTTPS' } } } } },
        'gatewayApiResources.gateway.listeners.gitlab-web.protocol setting must not be HTTPS or TLS'
      ],
      'a listener other than http-default uses HTTP' => [
        { 'gatewayApiResources' => { 'gateway' => { 'listeners' => { 'gitlab-web' => { 'protocol' => 'HTTP' } } } } },
        'gatewayApiResources.gateway.listeners.gitlab-web.protocol setting must be empty'
      ]
    }.each do |description, (overrides, message)|
      context description do
        let(:error_values) { overrides.deep_merge(success_values) }
        let(:error_output) { message }

        include_examples 'config validation', error_description: "when #{description}"
      end
    end
  end
end
