require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'Outgoing email configuration' do
  let(:charts_with_outgoing_email) do
    [
      'webservice',
      'sidekiq',
      'toolbox'
    ]
  end

  let(:values) { HelmTemplate.with_defaults(nil) }
  let(:template) { HelmTemplate.new(values) }

  it 'enables outgoing email by default', :aggregate_failures do
    charts_with_outgoing_email.each do |chart|
      gitlab_yml_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb')
      email_enabled = YAML.safe_load(gitlab_yml_erb).dig('production', 'gitlab', 'email_enabled')

      expect(email_enabled).to be(true)
    end
  end

  context 'when outgoing email is disabled' do
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
          email:
            enabled: false
      ))
    end

    it 'disables outgoing email for all Rails components', :aggregate_failures do
      charts_with_outgoing_email.each do |chart|
        gitlab_yml_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb')
        email_enabled = YAML.safe_load(gitlab_yml_erb).dig('production', 'gitlab', 'email_enabled')

        expect(email_enabled).to be(false)
      end
    end
  end
end
