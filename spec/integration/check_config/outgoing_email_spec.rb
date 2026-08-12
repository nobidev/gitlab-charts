require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig outgoingEmail' do
  describe 'outgoingEmail.mailerExclusive' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            amazon_ses_mailer:
              enabled: true
              region: us-east-1
              role_arn: arn:aws:iam::123456789012:role/ses-mailer
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            amazon_ses_mailer:
              enabled: true
              region: us-east-1
              role_arn: arn:aws:iam::123456789012:role/ses-mailer
            microsoft_graph_mailer:
              enabled: true
              user_id: MY-USER-ID
              tenant: MY-TENANT-ID
              client_id: MY-CLIENT-ID
              client_secret:
                secret: secret
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'mutually exclusive' }

    include_examples 'config validation',
                     success_description: 'when only one outgoing email mailer is enabled',
                     error_description: 'when both Amazon SES and Microsoft Graph mailers are enabled'
  end
end
