require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Certificates configuration' do
  # we're skipping anything not using this feature
  let(:skip_items) do
    [
      'nginx',
      'gitlab-runner',
      'test-kas',
      # cert-manager Pods (2)
      'cainjector',
      'cert-manager', 'certmanager',
      'prometheus',
      'envoy-gateway'
    ]
  end

  let(:default_values) do
    HelmTemplate.defaults
  end

  context 'Custom CA certificates' do
    context 'When present' do
      let(:single_ca) do
        default_values.deep_merge(YAML.safe_load(%(
          global:
            certificates:
              customCAs:
              - secret: rspec-custom-ca-secret-1
              - secret: rspec-custom-ca-secret-2
                keys:
                  - custom-ca-1.crt
                  - custom-ca-2.crt
              - configMap: rspec-custom-ca-configmap-1
              - configMap: rspec-custom-ca-configmap-2
                keys:
                  - custom-ca-3.crt
                  - custom-ca-4.crt
        )))
      end

      subject(:present) { HelmTemplate.new(single_ca) }

      it 'templates successfully' do
        expect(present.exit_code).to eq(0)
      end

      it 'populates volumes with extra Secret'  do
        present.resources_by_kind('Deployment').each do |resource|
          next if skip_items.any? { |i| resource[0].include? i }
          sources = present.projected_volume_sources(resource[0],'custom-ca-certificates')
          expect(sources).to be_truthy, "unable to locate 'custom-ca-certificates' volume for #{resource[0]}"
          expect(sources[0]['secret']['name']).to eq('rspec-custom-ca-secret-1')
          expect(sources[0]['secret']).not_to have_key('items')
          expect(sources[1]['secret']['name']).to eq('rspec-custom-ca-secret-2')
          expect(sources[1]['secret']['items'][0]['key']).to eq('custom-ca-1.crt')
          expect(sources[1]['secret']['items'][0]['path']).to eq('custom-ca-1.crt')
          expect(sources[1]['secret']['items'][1]['key']).to eq('custom-ca-2.crt')
          expect(sources[1]['secret']['items'][1]['path']).to eq('custom-ca-2.crt')
        end

        present.resources_by_kind('StatefulSet').each do |resource|
          next if skip_items.any? { |i| resource[0].include? i }
          sources = present.projected_volume_sources(resource[0],'custom-ca-certificates')
          expect(sources).to be_truthy, "unable to locate 'custom-ca-certificates' volume for #{resource[0]}"
          expect(sources[0]['secret']['name']).to eq('rspec-custom-ca-secret-1')
          expect(sources[0]['secret']).not_to have_key('items')
          expect(sources[1]['secret']['name']).to eq('rspec-custom-ca-secret-2')
          expect(sources[1]['secret']['items'][0]['key']).to eq('custom-ca-1.crt')
          expect(sources[1]['secret']['items'][0]['path']).to eq('custom-ca-1.crt')
          expect(sources[1]['secret']['items'][1]['key']).to eq('custom-ca-2.crt')
          expect(sources[1]['secret']['items'][1]['path']).to eq('custom-ca-2.crt')
        end
      end

      it 'populates volumes with extra ConfigMap'  do
        present.resources_by_kind('Deployment').each do |resource|
          next if skip_items.any? { |i| resource[0].include? i }
          sources = present.projected_volume_sources(resource[0],'custom-ca-certificates')
          expect(sources).to be_truthy, "unable to locate 'custom-ca-certificates' volume for #{resource[0]}"
          expect(sources[2]['configMap']['name']).to eq('rspec-custom-ca-configmap-1')
          expect(sources[2]['configMap']).not_to have_key('items')
          expect(sources[3]['configMap']['name']).to eq('rspec-custom-ca-configmap-2')
          expect(sources[3]['configMap']['items'][0]['key']).to eq('custom-ca-3.crt')
          expect(sources[3]['configMap']['items'][0]['path']).to eq('custom-ca-3.crt')
          expect(sources[3]['configMap']['items'][1]['key']).to eq('custom-ca-4.crt')
          expect(sources[3]['configMap']['items'][1]['path']).to eq('custom-ca-4.crt')
        end

        present.resources_by_kind('StatefulSet').each do |resource|
          next if skip_items.any? { |i| resource[0].include? i }
          sources = present.projected_volume_sources(resource[0],'custom-ca-certificates')
          expect(sources).to be_truthy, "unable to locate 'custom-ca-certificates' volume for #{resource[0]}"
          expect(sources[2]['configMap']['name']).to eq('rspec-custom-ca-configmap-1')
          expect(sources[2]['configMap']).not_to have_key('items')
          expect(sources[3]['configMap']['name']).to eq('rspec-custom-ca-configmap-2')
          expect(sources[3]['configMap']['items'][0]['key']).to eq('custom-ca-3.crt')
          expect(sources[3]['configMap']['items'][0]['path']).to eq('custom-ca-3.crt')
          expect(sources[3]['configMap']['items'][1]['key']).to eq('custom-ca-4.crt')
          expect(sources[3]['configMap']['items'][1]['path']).to eq('custom-ca-4.crt')
        end
      end

      it 'populates volumeMounts with extra volume'  do
        present.resources_by_kind('Deployment').each do |resource|
          next if skip_items.any? { |i| resource[0].include? i }
          volume_mount = present.find_volume_mount(resource[0],'certificates', 'custom-ca-certificates', true)
          expect(volume_mount).to be_truthy, "unable to locate 'custom-ca-certificates' mount in 'certificates' container of #{resource[0]}"
        end

        present.resources_by_kind('StatefulSet').each do |resource|
          next if skip_items.any? { |i| resource[0].include? i }
          volume_mount = present.find_volume_mount(resource[0],'certificates', 'custom-ca-certificates', true)
          expect(volume_mount).to be_truthy, "unable to locate 'custom-ca-certificates' mount in 'certificates' container of #{resource[0]}"
        end
      end
    end
  end

  context 'Dependency-waiting init containers' do
    let(:registry_db_values) do
      default_values.deep_merge(YAML.safe_load(%(
        registry:
          database:
            enabled: true
            sslmode: verify-full
            password:
              secret: registry-psql-secret
              key: password
      )))
    end

    subject(:template) { HelmTemplate.new(registry_db_values) }

    it 'templates successfully' do
      expect(template.exit_code).to eq(0)
    end

    it 'mounts the certificates volumes into every dependencies init container' do
      volumes = %w[etc-ssl-certs etc-pki-ca-trust-extracted-pem]

      checked = []

      %w[Deployment StatefulSet Job].each do |kind|
        template.resources_by_kind(kind).each_key do |name|
          next unless template.find_container(name, 'dependencies', true)

          checked << name

          volumes.each do |volume|
            mount = template.find_volume_mount(name, 'dependencies', volume, true)
            expect(mount).to be_truthy,
              "unable to locate '#{volume}' mount in 'dependencies' init container of #{name}"
          end
        end
      end

      expect(checked).to include('Deployment/test-registry')
    end
  end
end
