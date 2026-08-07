# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Orbit configuration' do # rubocop:disable Metrics/BlockLength
  let(:orbit_values) do
    HelmTemplate.with_defaults(%(
      global:
        appConfig:
          orbit:
            enabled: true
            jwtSecret:
              secret: test-orbit-secret
              key: test-orbit-key
            grpcEndpoint: "orbit.example.com:50054"
    ))
  end

  let(:legacy_values) do
    HelmTemplate.with_defaults(%(
      global:
        appConfig:
          knowledgeGraph:
            enabled: true
            jwtSecret:
              secret: test-orbit-secret
              key: test-orbit-key
            grpcEndpoint: "orbit.example.com:50054"
    ))
  end

  let(:disabled_values) { HelmTemplate.with_defaults({}) }

  let(:disabled_orbit_values) do
    HelmTemplate.with_defaults(%(
      global:
        appConfig:
          orbit:
            enabled: false
    ))
  end

  shared_examples 'Orbit configuration' do
    it 'renders knowledge_graph in gitlab.yml', :aggregate_failures do
      expect(template.exit_code).to eq(0), template.stderr

      gitlab_yml_erb = template.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb')
      gitlab_yml = YAML.safe_load(gitlab_yml_erb)
      orbit = gitlab_yml['production']['knowledge_graph']

      expect(orbit).not_to be_nil
      expect(orbit['enabled']).to be(true)
      expect(orbit['grpc_endpoint']).to eq('orbit.example.com:50054')
    end

    it 'mounts the jwt secret on webservice deployment', :aggregate_failures do
      secret = template.get_projected_secret(
        'Deployment/test-webservice-default',
        'init-webservice-secrets',
        'test-orbit-secret'
      )

      expect(secret).not_to be_nil
      expect(secret['items'][0]['key']).to eq('test-orbit-key')
      expect(secret['items'][0]['path']).to eq('knowledge_graph/.gitlab_knowledge_graph_secret')
    end
  end

  context 'with Orbit configuration' do
    let(:template) { HelmTemplate.new(orbit_values) }

    it_behaves_like 'Orbit configuration'
  end

  context 'with legacy Knowledge Graph configuration' do
    let(:template) { HelmTemplate.new(legacy_values) }

    it_behaves_like 'Orbit configuration'
  end

  context 'when comparing primary and legacy configuration' do
    let(:orbit_template) { HelmTemplate.new(orbit_values) }
    let(:legacy_template) { HelmTemplate.new(legacy_values) }

    it 'renders identical Rails configuration and secret mounts', :aggregate_failures do
      config_maps = %w[test-webservice test-sidekiq test-toolbox]
      secret_mounts = [
        %w[Deployment/test-webservice-default init-webservice-secrets],
        %w[Deployment/test-sidekiq-all-in-1-v2 init-sidekiq-secrets],
        %w[Deployment/test-toolbox init-toolbox-secrets]
      ]

      config_maps.each do |config_map|
        orbit_config = orbit_template.dig("ConfigMap/#{config_map}", 'data', 'gitlab.yml.erb')
        legacy_config = legacy_template.dig("ConfigMap/#{config_map}", 'data', 'gitlab.yml.erb')

        expect(orbit_config).to eq(legacy_config)
      end

      secret_mounts.each do |deployment, mount|
        orbit_secret = orbit_template.get_projected_secret(deployment, mount, 'test-orbit-secret')
        legacy_secret = legacy_template.get_projected_secret(deployment, mount, 'test-orbit-secret')

        expect(orbit_secret).to eq(legacy_secret)
      end
    end
  end

  context 'when Orbit is explicitly disabled' do
    let(:template) { HelmTemplate.new(disabled_orbit_values) }

    it 'does not render knowledge_graph or mount the jwt secret', :aggregate_failures do
      expect(template.exit_code).to eq(0), template.stderr

      gitlab_yml_erb = template.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb')
      gitlab_yml = YAML.safe_load(gitlab_yml_erb)

      expect(gitlab_yml['production']['knowledge_graph']).to be_nil
      expect(
        template.find_projected_secret(
          'Deployment/test-webservice-default',
          'init-webservice-secrets',
          'test-orbit-secret'
        )
      ).to be(false)
    end
  end

  context 'when disabled' do
    let(:template) { HelmTemplate.new(disabled_values) }

    it 'does not render knowledge_graph in gitlab.yml' do
      expect(template.exit_code).to eq(0), template.stderr

      gitlab_yml_erb = template.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb')
      gitlab_yml = YAML.safe_load(gitlab_yml_erb)

      expect(gitlab_yml['production']['knowledge_graph']).to be_nil
    end

    it 'does not mount the jwt secret' do
      has_secret = template.find_projected_secret(
        'Deployment/test-webservice-default',
        'init-webservice-secrets',
        'test-orbit-secret'
      )

      expect(has_secret).to be(false)
    end
  end
end # rubocop:enable Metrics/BlockLength
