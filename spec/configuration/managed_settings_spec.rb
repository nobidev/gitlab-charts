require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Managed settings configuration' do
  let(:template) { HelmTemplate.new(values) }
  let(:charts) { %w[webservice sidekiq toolbox migrations] }

  context 'with default values' do
    let(:values) do
      HelmTemplate.with_defaults({})
    end

    it 'renders the template' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
    end

    it 'does not generate the managed_settings.yml', :aggregate_failures do
      charts.each do |chart|
        expect(template.dig("ConfigMap/test-#{chart}", 'data')).not_to include('managed_settings.yml.erb')
      end
    end
  end

  context 'with sidekiqTimezoneOverride set' do
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
          rails:
            managedSettings:
              settings:
                sidekiqTimezoneOverride: 'America/New_York'
      ))
    end

    it 'renders the template' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
    end

    it 'generates the managed_settings.yml with the override', :aggregate_failures do
      charts.each do |chart|
        managed_settings_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'managed_settings.yml.erb')
        managed_settings = YAML.safe_load(managed_settings_erb)
        expect(managed_settings).to eq({
          'installation' => { 'managed_by' => 'GitLab Helm Chart' },
          'managed_settings' => { 'sidekiq_timezone_override' => 'America/New_York' }
        })
      end
    end
  end

  context 'with installation.managedBy set' do
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
          rails:
            managedSettings:
              installation:
                managedBy: 'ACME Corp'
              settings:
                sidekiqTimezoneOverride: 'America/New_York'
      ))
    end

    it 'renders the template' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
    end

    it 'uses the configured name instead of the default', :aggregate_failures do
      charts.each do |chart|
        managed_settings_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'managed_settings.yml.erb')
        managed_settings = YAML.safe_load(managed_settings_erb)
        expect(managed_settings['installation']).to eq({ 'managed_by' => 'ACME Corp' })
      end
    end
  end

  context 'with installation.managedBy set but no managed settings' do
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
          rails:
            managedSettings:
              installation:
                managedBy: 'ACME Corp'
      ))
    end

    it 'renders the template' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
    end

    it 'does not generate the managed_settings.yml', :aggregate_failures do
      charts.each do |chart|
        expect(template.dig("ConfigMap/test-#{chart}", 'data')).not_to include('managed_settings.yml.erb')
      end
    end
  end
end
