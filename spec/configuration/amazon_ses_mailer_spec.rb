require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Amazon SES Mailer configuration' do
  let(:charts_with_ses) do
    [
      'webservice',
      'sidekiq',
      'toolbox'
    ]
  end

  let(:values) do
    HelmTemplate.with_defaults(%(
        global:
          appConfig:
            amazon_ses_mailer:
              enabled: true
              region: "us-east-1"
              access_key_id: "YOUR-AWS-ACCESS-KEY-ID"
              secret_access_key: "YOUR-AWS-SECRET-ACCESS-KEY"
              role_arn: "arn:aws:iam::123456789012:role/your-role"
    ))
  end

  let(:template) { HelmTemplate.new(values) }

  it 'populates amazon_ses_mailer to gitlab.yml', :aggregate_failures do
    expect(template.exit_code).to eq(0)
    charts_with_ses.each do |chart|
      gitlab_yml_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb')
      amazon_ses_mailer = YAML.safe_load(gitlab_yml_erb)['production']['amazon_ses_mailer']
      expect(amazon_ses_mailer['enabled']).to eq(true)
      expect(amazon_ses_mailer['region']).to eq('us-east-1')
      expect(amazon_ses_mailer['access_key_id']).to eq('YOUR-AWS-ACCESS-KEY-ID')
      expect(amazon_ses_mailer['secret_access_key']).to eq('YOUR-AWS-SECRET-ACCESS-KEY')
      expect(amazon_ses_mailer['role_arn']).to eq('arn:aws:iam::123456789012:role/your-role')
    end
  end

  context 'when disabled' do
    let(:values) { HelmTemplate.with_defaults('{}') }

    it 'does not populate amazon_ses_mailer to gitlab.yml', :aggregate_failures do
      expect(template.exit_code).to eq(0)
      charts_with_ses.each do |chart|
        gitlab_yml_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb')
        expect(YAML.safe_load(gitlab_yml_erb)['production']).not_to have_key('amazon_ses_mailer')
      end
    end
  end
end
