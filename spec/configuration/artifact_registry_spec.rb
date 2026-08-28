# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'artifactRegistry templates' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global:
        appConfig:
          artifactRegistry:
            enabled: false
    ))
  end

  let(:url_only_values) do
    default_values.deep_merge(YAML.safe_load(%(
      global:
        appConfig:
          artifactRegistry:
            enabled: true
            apiUrl: https://artifact-registry.example.com
    )))
  end

  let(:enabled_values) do
    url_only_values.deep_merge(YAML.safe_load(%(
      global:
        appConfig:
          artifactRegistry:
            authToken:
              secret: gitlab-artifact-registry-credential-v1
              key: token
    )))
  end

  let(:configmaps) do
    [
      'ConfigMap/test-webservice',
      'ConfigMap/test-sidekiq',
      'ConfigMap/test-toolbox'
    ]
  end

  let(:deployments) do
    {
      'Deployment/test-webservice-default' => 'init-webservice-secrets',
      'Deployment/test-sidekiq-all-in-1-v2' => 'init-sidekiq-secrets',
      'Deployment/test-toolbox' => 'init-toolbox-secrets'
    }
  end

  # The mounted token's path is spelled independently in the projected volume and
  # in the rendered secret_file, so the two are compared rather than each being
  # matched against a literal the test itself supplies.
  def rendered_secret_file(config)
    config[/artifact_registry:\s*\n\s+api_url:.*\n\s+service_token:\s*\n\s+secret_file:\s*(\S+)/, 1]
  end

  def secret_mount(template, deployment, volume_name)
    template.projected_volume_sources(deployment, volume_name)&.find do |item|
      item.dig('secret', 'name') == 'gitlab-artifact-registry-credential-v1'
    end
  end

  describe 'gitlab.yml.erb rendering' do
    context 'when unset' do
      it 'renders no artifact_registry key at all' do
        t = HelmTemplate.new(default_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        configmaps.each do |configmap|
          config = t.dig(configmap, 'data', 'gitlab.yml.erb')
          expect(config).not_to include('artifact_registry'), "Expected no artifact_registry in #{configmap}"
        end
      end
    end

    context 'when enabled with apiUrl and no token secret' do
      it 'renders api_url and no service_token' do
        t = HelmTemplate.new(url_only_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        configmaps.each do |configmap|
          config = t.dig(configmap, 'data', 'gitlab.yml.erb')
          expect(config).to include('artifact_registry:'), "Expected artifact_registry in #{configmap}"
          expect(config).to include('https://artifact-registry.example.com')
          expect(config).not_to include('service_token'), "Expected no service_token in #{configmap}"
        end
      end
    end

    context 'when enabled with a token secret' do
      it 'renders the nested service_token.secret_file' do
        t = HelmTemplate.new(enabled_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        configmaps.each do |configmap|
          config = t.dig(configmap, 'data', 'gitlab.yml.erb')
          expect(rendered_secret_file(config)).not_to be_nil, "Expected service_token.secret_file in #{configmap}"
        end
      end
    end
  end

  describe 'gitlab.appConfig.artifactRegistry.mountSecrets' do
    context 'when unset' do
      it 'does not mount any secrets' do
        t = HelmTemplate.new(default_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        deployments.each do |deployment, volume_name|
          expect(secret_mount(t, deployment, volume_name)).to be_nil, "Expected no mount in #{deployment}"
        end
      end
    end

    context 'when enabled with apiUrl and no token secret' do
      it 'does not mount any secrets' do
        t = HelmTemplate.new(url_only_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        deployments.each do |deployment, volume_name|
          expect(secret_mount(t, deployment, volume_name)).to be_nil, "Expected no mount in #{deployment}"
        end
      end
    end

    context 'when enabled with a token secret' do
      it 'mounts the operator-supplied secret on webservice, sidekiq, and toolbox' do
        t = HelmTemplate.new(enabled_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        deployments.each do |deployment, volume_name|
          mount = secret_mount(t, deployment, volume_name)
          expect(mount).not_to be_nil, "Expected a mount in #{deployment}"
          expect(mount.dig('secret', 'items', 0, 'key')).to eq('token')
        end
      end

      it 'mounts the token where the rendered secret_file points' do
        t = HelmTemplate.new(enabled_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        secret_file = rendered_secret_file(t.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb'))

        deployments.each do |deployment, volume_name|
          projected_path = secret_mount(t, deployment, volume_name).dig('secret', 'items', 0, 'path')
          expect(File.join('/etc/gitlab', projected_path)).to eq(secret_file), "Path disagreement in #{deployment}"
        end
      end

      it 'copies the secret directory out of the init container' do
        t = HelmTemplate.new(enabled_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

        projected_path = secret_mount(t, 'Deployment/test-webservice-default', 'init-webservice-secrets')
          .dig('secret', 'items', 0, 'path')
        configure = t.dig('ConfigMap/test-webservice', 'data', 'configure')

        expect(configure).to include(File.dirname(projected_path))
      end
    end
  end

  describe 'secret generation' do
    it 'never generates a token, because the value is shared with the Artifact Registry service' do
      t = HelmTemplate.new(enabled_values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

      generate_secrets = t.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
      expect(generate_secrets).not_to include('artifact-registry')
      expect(generate_secrets).not_to include('artifact_registry')
    end
  end

  describe 'checkConfig' do
    context 'when unset' do
      it 'does not error' do
        t = HelmTemplate.new(default_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      end
    end

    context 'when enabled without apiUrl' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          global:
            appConfig:
              artifactRegistry:
                enabled: true
        )))
      end

      it 'errors that apiUrl is required' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).not_to eq(0)
        expect(t.stderr).to include('apiUrl is required when artifactRegistry is enabled')
      end
    end

    context 'when enabled with apiUrl and no token secret' do
      it 'does not error' do
        t = HelmTemplate.new(url_only_values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      end
    end
  end
end
