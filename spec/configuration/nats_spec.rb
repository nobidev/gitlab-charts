require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'NATS configuration' do
  let(:configmaps) do
    ['ConfigMap/test-webservice', 'ConfigMap/test-sidekiq', 'ConfigMap/test-toolbox']
  end

  let(:configured_values) do
    HelmTemplate.with_defaults(%(
      global:
        appConfig:
          nats:
            servers:
              - "tls://nats.example.com:4222"
              - "tls://nats2.example.com:4222"
            connectTimeout: 2
            streamReplicas: 3
    ))
  end

  let(:tls_values) do
    HelmTemplate.with_defaults(%(
      global:
        appConfig:
          nats:
            servers:
              - "tls://nats.example.com:4222"
            tls:
              enabled: true
              secret: test-nats-tls
    ))
  end

  let(:per_component_tls_values) do
    HelmTemplate.with_defaults(%(
      global:
        appConfig:
          nats:
            servers:
              - "tls://nats.example.com:4222"
            tls:
              enabled: true
              secret: test-nats-tls
      gitlab:
        webservice:
          nats:
            tls:
              secret: test-webservice-nats-tls
        sidekiq:
          nats:
            tls:
              secret: test-sidekiq-nats-tls
    ))
  end

  # TLS enabled globally with no shared secret; only webservice and sidekiq set
  # their own. Toolbox has none and must not mount a non-existent secret.
  let(:per_component_no_global_secret_values) do
    HelmTemplate.with_defaults(%(
      global:
        appConfig:
          nats:
            servers:
              - "tls://nats.example.com:4222"
            tls:
              enabled: true
      gitlab:
        webservice:
          nats:
            tls:
              secret: test-webservice-nats-tls
        sidekiq:
          nats:
            tls:
              secret: test-sidekiq-nats-tls
    ))
  end

  let(:default_values) { HelmTemplate.with_defaults({}) }

  context 'when configured' do
    let(:template) { HelmTemplate.new(configured_values) }

    it 'renders nats in gitlab.yml for all Rails components', :aggregate_failures do
      expect(template.exit_code).to eq(0), template.stderr

      configmaps.each do |configmap|
        gitlab_yml_erb = template.dig(configmap, 'data', 'gitlab.yml.erb')
        gitlab_yml = YAML.safe_load(gitlab_yml_erb)
        nats = gitlab_yml['production']['nats']

        expect(nats).not_to be_nil, "Expected nats to be rendered in #{configmap}"
        expect(nats['servers']).to eq(['tls://nats.example.com:4222', 'tls://nats2.example.com:4222'])
        expect(nats['connect_timeout']).to eq(2)
        expect(nats['stream_replicas']).to eq(3)
        expect(nats['tls']).to be_nil
      end
    end

    it 'does not mount a TLS secret when TLS is disabled' do
      has_secret = template.find_projected_secret(
        'Deployment/test-webservice-default',
        'init-webservice-secrets',
        'test-nats-tls'
      )

      expect(has_secret).to be(false)
    end
  end

  context 'when configured with mutual TLS' do
    let(:template) { HelmTemplate.new(tls_values) }

    it 'renders nats tls file paths in gitlab.yml', :aggregate_failures do
      expect(template.exit_code).to eq(0), template.stderr

      gitlab_yml_erb = template.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb')
      gitlab_yml = YAML.safe_load(gitlab_yml_erb)
      tls = gitlab_yml['production']['nats']['tls']

      expect(tls).not_to be_nil
      expect(tls['ca_file']).to eq('/srv/gitlab/config/nats/ca.crt')
      expect(tls['cert']).to eq('/srv/gitlab/config/nats/tls.crt')
      expect(tls['key']).to eq('/srv/gitlab/config/nats/tls.key')
    end

    it 'mounts the TLS secret on the webservice deployment', :aggregate_failures do
      secret = template.get_projected_secret(
        'Deployment/test-webservice-default',
        'init-webservice-secrets',
        'test-nats-tls'
      )

      expect(secret).not_to be_nil
      paths = secret['items'].map { |item| item['path'] }
      expect(paths).to contain_exactly('nats/ca.crt', 'nats/tls.crt', 'nats/tls.key')
    end

    it 'mounts the TLS files into the webservice container', :aggregate_failures do
      container = template.find_container('Deployment/test-webservice-default', 'webservice')
      nats_mounts = container['volumeMounts'].select { |mount| mount['mountPath'].start_with?('/srv/gitlab/config/nats/') }

      by_path = nats_mounts.to_h { |mount| [mount['mountPath'], mount['subPath']] }
      expect(by_path).to eq(
        '/srv/gitlab/config/nats/ca.crt' => 'nats/ca.crt',
        '/srv/gitlab/config/nats/tls.crt' => 'nats/tls.crt',
        '/srv/gitlab/config/nats/tls.key' => 'nats/tls.key'
      )
    end

    it 'mounts the TLS secret on the sidekiq deployment' do
      secret = template.get_projected_secret(
        'Deployment/test-sidekiq-all-in-1-v2',
        'init-sidekiq-secrets',
        'test-nats-tls'
      )

      expect(secret).not_to be_nil
    end

    it 'renders the NATS TLS copy commands in the configure script', :aggregate_failures do
      configmaps.each do |configmap|
        configure = template.dig(configmap, 'data', 'configure')

        expect(configure).to include('cp -v -L /init-config/nats/ca.crt /init-secrets/nats/ca.crt'),
          "Expected configure script to copy NATS TLS files in #{configmap}"
        expect(configure).to include('cp -v -L /init-config/nats/tls.crt /init-secrets/nats/tls.crt')
        expect(configure).to include('cp -v -L /init-config/nats/tls.key /init-secrets/nats/tls.key')
      end
    end
  end

  context 'when configured with per-component TLS secrets' do
    let(:template) { HelmTemplate.new(per_component_tls_values) }

    it 'mounts the component-specific client certificate on each deployment', :aggregate_failures do
      expect(template.exit_code).to eq(0), template.stderr

      webservice_secret = template.get_projected_secret(
        'Deployment/test-webservice-default',
        'init-webservice-secrets',
        'test-webservice-nats-tls'
      )
      expect(webservice_secret).not_to be_nil

      sidekiq_secret = template.get_projected_secret(
        'Deployment/test-sidekiq-all-in-1-v2',
        'init-sidekiq-secrets',
        'test-sidekiq-nats-tls'
      )
      expect(sidekiq_secret).not_to be_nil
    end

    it 'falls back to the global secret for components without an override' do
      # toolbox has no per-component override, so it uses global.appConfig.nats.tls.secret
      toolbox_secret = template.get_projected_secret(
        'Deployment/test-toolbox',
        'init-toolbox-secrets',
        'test-nats-tls'
      )

      expect(toolbox_secret).not_to be_nil
    end

    context 'with a toolbox override' do
      let(:template) do
        HelmTemplate.new(per_component_tls_values.deep_merge(
          'gitlab' => { 'toolbox' => { 'nats' => { 'tls' => { 'secret' => 'test-toolbox-nats-tls' } } } }
        ))
      end

      it 'uses the component-local secret instead of the global one', :aggregate_failures do
        expect(template.exit_code).to eq(0), template.stderr

        override = template.get_projected_secret(
          'Deployment/test-toolbox',
          'init-toolbox-secrets',
          'test-toolbox-nats-tls'
        )
        expect(override).not_to be_nil

        has_global = template.find_projected_secret(
          'Deployment/test-toolbox',
          'init-toolbox-secrets',
          'test-nats-tls'
        )
        expect(has_global).to be(false)
      end
    end
  end

  context 'when TLS is enabled with per-component secrets but no global secret' do
    let(:template) { HelmTemplate.new(per_component_no_global_secret_values) }

    it 'renders without error' do
      expect(template.exit_code).to eq(0), template.stderr
    end

    it 'mounts each connecting component using its own secret', :aggregate_failures do
      webservice_secret = template.get_projected_secret(
        'Deployment/test-webservice-default',
        'init-webservice-secrets',
        'test-webservice-nats-tls'
      )
      expect(webservice_secret).not_to be_nil

      sidekiq_secret = template.get_projected_secret(
        'Deployment/test-sidekiq-all-in-1-v2',
        'init-sidekiq-secrets',
        'test-sidekiq-nats-tls'
      )
      expect(sidekiq_secret).not_to be_nil
    end

    it 'does not mount any NATS secret on toolbox when it has no configured secret', :aggregate_failures do
      sources = template.projected_volume_sources(
        'Deployment/test-toolbox',
        'init-toolbox-secrets'
      )
      nats_paths = sources.flat_map { |source| (source['secret'] || {})['items'].to_a }
        .map { |item| item['path'] }
        .select { |path| path.to_s.start_with?('nats/') }

      expect(nats_paths).to be_empty
    end

    it 'does not render NATS TLS copy commands in the toolbox configure script' do
      configure = template.dig('ConfigMap/test-toolbox', 'data', 'configure')

      expect(configure).not_to include('/init-secrets/nats/')
    end

    it 'keeps the rendered tls block consistent with the mounted secret', :aggregate_failures do
      webservice_nats = YAML.safe_load(
        template.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb')
      )['production']['nats']
      expect(webservice_nats['tls']).not_to be_nil

      toolbox_nats = YAML.safe_load(
        template.dig('ConfigMap/test-toolbox', 'data', 'gitlab.yml.erb')
      )['production']['nats']
      expect(toolbox_nats).not_to be_nil
      expect(toolbox_nats['tls']).to be_nil
    end
  end

  context 'when unconfigured' do
    let(:template) { HelmTemplate.new(default_values) }

    it 'does not render nats in gitlab.yml' do
      expect(template.exit_code).to eq(0), template.stderr

      configmaps.each do |configmap|
        gitlab_yml_erb = template.dig(configmap, 'data', 'gitlab.yml.erb')
        gitlab_yml = YAML.safe_load(gitlab_yml_erb)

        expect(gitlab_yml['production']['nats']).to be_nil, "Expected no nats block in #{configmap}"
      end
    end

    it 'does not mount a TLS secret' do
      has_secret = template.find_projected_secret(
        'Deployment/test-webservice-default',
        'init-webservice-secrets',
        'test-nats-tls'
      )

      expect(has_secret).to be(false)
    end
  end
end
