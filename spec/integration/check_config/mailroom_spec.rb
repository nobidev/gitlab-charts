require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig mailroom' do
  describe 'incomingEmail.microsoftGraph' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              inboxMethod: microsoft_graph
              tenantId: MY-TENANT-ID
              clientId: MY-CLIENT-ID
              clientSecret:
                secret: secret
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              inboxMethod: microsoft_graph
              clientSecret:
                secret: secret
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'be sure to specify the tenant ID' }

    include_examples 'config validation',
                     success_description: 'when incomingEmail is configured with Microsoft Graph',
                     error_description: 'when incomingEmail is missing required Microsoft Graph settings'
  end

  describe 'serviceDesk.microsoftGraph' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              inboxMethod: microsoft_graph
              tenantId: MY-TENANT-ID
              clientId: MY-CLIENT-ID
              clientSecret:
                secret: secret
            serviceDesk:
              enabled: true
              inboxMethod: microsoft_graph
              tenantId: MY-TENANT-ID
              clientId: MY-CLIENT-ID
              clientSecret:
                secret: secret
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              inboxMethod: microsoft_graph
              tenantId: MY-TENANT-ID
              clientId: MY-CLIENT-ID
              clientSecret:
                secret: secret
            serviceDesk:
              enabled: true
              inboxMethod: microsoft_graph
              clientSecret:
                secret: secret
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'be sure to specify the tenant ID' }

    include_examples 'config validation',
                     success_description: 'when serviceDesk is configured with Microsoft Graph',
                     error_description: 'when serviceDesk is missing required Microsoft Graph settings'
  end

  describe 'incomingEmail.deliveryMethod' do
    include_context 'check config setup'

    context 'with valid incoming mail sidekiq config' do
      let(:values) do
        YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              password:
                secret: "password"
              deliveryMethod: sidekiq
            serviceDeskEmail:
              enabled: false
        )).deep_merge(default_required_values)
      end

      it 'succeeds' do
        expect(stderr).to be_empty
        expect(exit_code).to eq(0)
        expect(stdout).to include('name: gitlab-checkconfig-test')
      end
    end

    context 'with valid incoming mail webhook config' do
      let(:values) do
        YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              password:
                secret: "password"
              deliveryMethod: webhook
            serviceDeskEmail:
              enabled: false
        )).deep_merge(default_required_values)
      end

      it 'succeeds' do
        expect(stderr).to be_empty
        expect(exit_code).to eq(0)
        expect(stdout).to include('name: gitlab-checkconfig-test')
      end
    end

    context 'delivery method is unknown' do
      let(:values) do
        YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              password:
                secret: "password"
              deliveryMethod: somethingElse
            serviceDeskEmail:
              enabled: false
        )).deep_merge(default_required_values)
      end

      it 'returns an error' do
        expect(exit_code).to be > 0
        expect(stdout).to be_empty
        expect(stderr).to include('Delivery method should be either "sidekiq" or "webhook"')
      end
    end
  end

  describe 'serviceDeskEmail.deliveryMethod' do
    include_context 'check config setup'

    context 'with valid service desk mail sidekiq config' do
      let(:values) do
        YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              address: "something+%{key}@gmail.com"
              password:
                secret: "password"
              deliveryMethod: sidekiq
            serviceDeskEmail:
              enabled: true
              address: "something+%{key}@gmail.com"
              password:
                secret: "password"
              deliveryMethod: sidekiq
        )).deep_merge(default_required_values)
      end

      it 'succeeds' do
        expect(stderr).to be_empty
        expect(exit_code).to eq(0)
        expect(stdout).to include('name: gitlab-checkconfig-test')
      end
    end

    context 'with valid service desk mail sidekiq config' do
      let(:values) do
        YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              address: "something+%{key}@gmail.com"
              password:
                secret: "password"
              deliveryMethod: sidekiq
            serviceDeskEmail:
              enabled: true
              address: "something+%{key}@gmail.com"
              password:
                secret: "password"
              deliveryMethod: webhook
        )).deep_merge(default_required_values)
      end

      it 'succeeds' do
        expect(stderr).to be_empty
        expect(exit_code).to eq(0)
        expect(stdout).to include('name: gitlab-checkconfig-test')
      end
    end

    context 'delivery method is unknown' do
      let(:values) do
        YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              address: "something+%{key}@gmail.com"
              password:
                secret: "password"
              deliveryMethod: sidekiq
            serviceDeskEmail:
              enabled: true
              address: "something+%{key}@gmail.com"
              password:
                secret: "password"
              deliveryMethod: somethingElse
        )).deep_merge(default_required_values)
      end

      it 'returns an error' do
        expect(exit_code).to be > 0
        expect(stdout).to be_empty
        expect(stderr).to include('Delivery method should be either "sidekiq" or "webhook"')
      end
    end
  end

  describe 'mailroom.publicKeyFiles' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              password:
                secret: password
              publicKeyFiles:
                secret: incoming-email-public-keys
                keys: [current.pub]
      )).deep_merge!(default_required_values)
    end

    context 'when a secret is named without any keys' do
      let(:error_values) do
        YAML.safe_load(%(
          global:
            appConfig:
              incomingEmail:
                enabled: true
                password:
                  secret: password
                publicKeyFiles:
                  secret: incoming-email-public-keys
                  keys: []
        )).deep_merge!(default_required_values)
      end

      let(:error_output) { 'is set but `keys` is empty' }

      include_examples 'config validation',
                       success_description: 'when publicKeyFiles names a secret and its keys',
                       error_description: 'when publicKeyFiles names a secret without keys'
    end

    context 'when keys are named without a secret' do
      let(:error_values) do
        YAML.safe_load(%(
          global:
            appConfig:
              incomingEmail:
                enabled: true
                address: "incoming+%{key}@example.com"
                password:
                  secret: password
              serviceDeskEmail:
                enabled: true
                address: "service-desk+%{key}@example.com"
                password:
                  secret: password
                publicKeyFiles:
                  secret: ""
                  keys: [current.pub]
        )).deep_merge!(default_required_values)
      end

      let(:error_output) { 'is set but `secret` is empty' }

      include_examples 'config validation',
                       success_description: 'when publicKeyFiles names a secret and its keys',
                       error_description: 'when publicKeyFiles names keys without a secret'
    end

    context 'when the mailbox is disabled' do
      include_context 'check config setup'

      let(:values) do
        YAML.safe_load(%(
          global:
            appConfig:
              serviceDeskEmail:
                enabled: false
                publicKeyFiles:
                  secret: ""
                  keys: [current.pub]
        )).deep_merge!(default_required_values)
      end

      it 'succeeds, as nothing is mounted for a disabled mailbox' do
        expect(stderr).to be_empty
        expect(exit_code).to eq(0)
      end
    end

    context 'with the sidekiq delivery method' do
      include_context 'check config setup'

      let(:values) do
        YAML.safe_load(%(
          global:
            appConfig:
              incomingEmail:
                enabled: true
                password:
                  secret: password
                deliveryMethod: sidekiq
                publicKeyFiles:
                  secret: incoming-email-public-keys
                  keys: []
        )).deep_merge!(default_required_values)
      end

      it 'succeeds, as sidekiq delivery sends no token to verify' do
        expect(stderr).to be_empty
        expect(exit_code).to eq(0)
      end
    end
  end
end
