require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Praefect configuration' do
  let(:default_values) do
    HelmTemplate.defaults
  end

  let(:praefect_resources) do
    [
      'Service/test-praefect',
      'ConfigMap/test-praefect',
      'PodDisruptionBudget/test-praefect',
      'StatefulSet/test-praefect'
    ]
  end

  let(:internal_gitaly_resources) do
    [
      'ConfigMap/test-gitaly',
      'PodDisruptionBudget/test-gitaly',
      'Service/test-gitaly',
      'StatefulSet/test-gitaly'
    ]
  end

  let(:gitaly_resources_with_praefect) do
    [
      'ConfigMap/test-gitaly-praefect',
      'PodDisruptionBudget/test-gitaly-default',
      'Service/test-gitaly-default',
      'StatefulSet/test-gitaly-default'
    ]
  end

  context 'with Praefect disabled' do
    let(:values_praefect_disabled) do
      default_values.deep_merge(YAML.safe_load(%(
        global:
          praefect:
            enabled: false
      )))
    end

    let(:template) { HelmTemplate.new(values_praefect_disabled) }

    it 'templates successfully' do
      expect(template.exit_code).to eq(0)
    end

    it 'does not render Praefect resources' do
      praefect_resources.each do |r|
        expect(template.dig(r)).to be_falsey
      end
    end
  end

  context 'with Praefect enabled' do
    let(:values_praefect_enabled) do
      default_values.deep_merge(YAML.safe_load(%(
        global:
          praefect:
            enabled: true
      )))
    end

    let(:template) { HelmTemplate.new(values_praefect_enabled) }

    it 'templates successfully' do
      expect(template.exit_code).to eq(0)
    end

    it 'renders Praefect resources' do
      praefect_resources.each do |r|
        expect(template.dig(r)).to be_truthy
      end
    end

    it 'renders Gitaly resources' do
      gitaly_resources_with_praefect.each do |r|
        expect(template.dig(r)).to be_truthy
      end
    end

    it 'does not render internal Gitaly resources' do
      internal_gitaly_resources.each do |r|
        expect(template.dig(r)).to be_falsey
      end
    end

    it 'enables prometheus_exclude_database_from_default_metrics by default' do
      expect(template.dig('ConfigMap/test-praefect', 'data', 'config.toml.tpl')).to include('prometheus_exclude_database_from_default_metrics = true')
    end

    context 'with extraVolumes' do
      let(:values_with_extra_volumes) do
        YAML.safe_load(%(
          gitlab:
            praefect:
              extraVolumes: |-
                - name: {{ .Release.Name }}-extra
                  emptyDir: {}
        )).deep_merge(values_praefect_enabled)
      end

      let(:template) { HelmTemplate.new(values_with_extra_volumes) }

      it 'renders the templated volume exactly once in the StatefulSet' do
        volumes = template.dig('StatefulSet/test-praefect', 'spec', 'template', 'spec', 'volumes')

        expect(volumes.count { |volume| volume['name'] == 'test-extra' }).to eq(1)
      end
    end

    context 'with PostgreSQL SSL configured' do
      let(:values_with_postgresql_ssl) do
        YAML.safe_load(%(
          global:
            praefect:
              psql:
                sslMode: verify-full
            psql:
              ssl:
                secret: postgresql-ssl
                clientKey: client-key
                clientCertificate: client-certificate
                serverCA: server-ca
        )).deep_merge(values_praefect_enabled)
      end

      let(:template) { HelmTemplate.new(values_with_postgresql_ssl) }
      let(:statefulset) { template.dig('StatefulSet/test-praefect', 'spec', 'template', 'spec') }
      let(:praefect_container) { statefulset['containers'].find { |container| container['name'] == 'praefect' } }

      it 'configures the mounted certificates for a verified Praefect database connection' do
        database_config = template.dig('ConfigMap/test-praefect', 'data', 'config.toml.tpl')

        expect(database_config).to include("sslmode = 'verify-full'")
        expect(database_config).to include("sslcert = '/etc/postgresql/ssl/client-certificate.pem'")
        expect(database_config).to include("sslkey = '/etc/postgresql/ssl/client-key.pem'")
        expect(database_config).to include("sslrootcert = '/etc/postgresql/ssl/server-ca.pem'")
      end

      it 'mounts the PostgreSQL SSL secret in the Praefect container' do
        expect(praefect_container['volumeMounts']).to include(
          'name' => 'postgresql-ssl-secrets',
          'mountPath' => '/etc/postgresql/ssl/',
          'readOnly' => true
        )
        expect(statefulset['volumes']).to include(
          a_hash_including(
            'name' => 'postgresql-ssl-secrets',
            'projected' => a_hash_including(
              'sources' => include(a_hash_including('secret' => a_hash_including('name' => 'postgresql-ssl')))
            )
          )
        )
      end

      context 'with a Praefect-specific SSL secret' do
        let(:values_with_postgresql_ssl) do
          super().deep_merge(YAML.safe_load(%(
            global:
              praefect:
                psql:
                  ssl:
                    secret: praefect-postgresql-ssl
                    clientKey: praefect-client-key
                    clientCertificate: praefect-client-certificate
                    serverCA: praefect-server-ca
          )))
        end

        it 'uses the Praefect override instead of the global PostgreSQL SSL secret' do
          ssl_volume = statefulset['volumes'].find { |volume| volume['name'] == 'postgresql-ssl-secrets' }

          expect(ssl_volume.dig('projected', 'sources', 0, 'secret', 'name')).to eq('praefect-postgresql-ssl')
        end
      end
    end

    context 'without PostgreSQL SSL configured' do
      let(:statefulset) { template.dig('StatefulSet/test-praefect', 'spec', 'template', 'spec') }
      let(:praefect_container) { statefulset['containers'].find { |container| container['name'] == 'praefect' } }

      it 'does not configure or mount PostgreSQL certificates' do
        database_config = template.dig('ConfigMap/test-praefect', 'data', 'config.toml.tpl')

        expect(database_config).to include("sslmode = 'disable'")
        expect(database_config).not_to include('sslcert =')
        expect(praefect_container['volumeMounts'].map { |mount| mount['name'] }).not_to include('postgresql-ssl-secrets')
        expect(statefulset['volumes'].map { |volume| volume['name'] }).not_to include('postgresql-ssl-secrets')
      end
    end

    context 'without replacing Gitaly' do
      let(:values_with_internal_gitaly) do
        YAML.safe_load(%(
          global:
            praefect:
              replaceInternalGitaly: false
              virtualStorages:
              - name: default-praefect
        )).deep_merge(values_praefect_enabled)
      end

      let(:template) { HelmTemplate.new(values_with_internal_gitaly) }

      it 'renders internal Gitaly resources' do
        internal_gitaly_resources.each do |r|
          expect(template.dig(r)).to be_truthy
        end
      end
    end

    context 'with multiple virtual storages' do
      let(:values_multiple_virtual_storages) do
        YAML.safe_load(%(
          global:
            praefect:
              virtualStorages:
              - name: default
                gitalyReplicas: 3
              - name: vs2
                gitalyReplicas: 3
        )).deep_merge(values_praefect_enabled)
      end

      let(:gitaly_resources_with_multiple_storages) do
        [
          'PodDisruptionBudget/test-gitaly-vs2',
          'Service/test-gitaly-vs2',
          'StatefulSet/test-gitaly-vs2'
        ].concat(gitaly_resources_with_praefect)
      end

      let(:template) { HelmTemplate.new(values_multiple_virtual_storages) }

      it 'templates successfully' do
        expect(template.exit_code).to eq(0)
      end

      it 'generates Gitaly resources per virtual storage' do
        gitaly_resources_with_multiple_storages.each do |r|
          expect(template.dig(r)).to be_truthy
        end
      end
    end

    context 'with custom defaultReplicationFactors' do
      let(:values_custom_defaultreplicationfactor) do
        YAML.safe_load(%(
          global:
            praefect:
              virtualStorages:
              - name: default
                gitalyReplicas: 5
                maxUnavailable: 2
                defaultReplicationFactor: 3
              - name: secondary
                gitalyReplicas: 4
                maxUnavailable: 1
                defaultReplicationFactor: 2
        )).deep_merge(values_praefect_enabled)
      end

      let(:template) { HelmTemplate.new(values_custom_defaultreplicationfactor) }

      it 'templates successfully' do
        expect(template.exit_code).to eq(0)
      end

      it 'correctly specifies the defaultReplicationFactors' do
        vs1_selection = "name = 'default'\n" \
                        "default_replication_factor = 3"

        vs2_selection = "name = 'secondary'\n" \
                        "default_replication_factor = 2"

        expect(template.dig('ConfigMap/test-praefect', 'data', 'config.toml.tpl')).to include(vs1_selection)
        expect(template.dig('ConfigMap/test-praefect', 'data', 'config.toml.tpl')).to include(vs2_selection)
      end
    end

    context 'with separate_database_metrics false' do
      let(:values_separate_db_metrics) do
        YAML.safe_load(%(
          gitlab:
            praefect:
              metrics:
                separate_database_metrics: false
        )).deep_merge(values_praefect_enabled)
      end

      let(:template) { HelmTemplate.new(values_separate_db_metrics) }

      it 'templates successfully' do
        expect(template.exit_code).to eq(0)
      end

      it 'disables prometheus_exclude_database_from_default_metrics' do
        expect(template.dig('ConfigMap/test-praefect', 'data', 'config.toml.tpl')).to include('prometheus_exclude_database_from_default_metrics = false')
      end
    end

    context 'When customer provides additional labels' do
      let(:values) do
        YAML.safe_load(%(
          global:
            common:
              labels:
                global: global
                foo: global
            pod:
              labels:
                global_pod: true
            service:
              labels:
                global_service: true
          gitlab:
            praefect:
              common:
                labels:
                  global: praefect
                  praefect: praefect
              podLabels:
                pod: true
                global: pod
              serviceLabels:
                service: true
                global: service
        )).deep_merge(values_praefect_enabled)
      end

      it 'Populates the additional labels in the expected manner' do
        t = HelmTemplate.new(values)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        expect(t.dig('ConfigMap/test-praefect', 'metadata', 'labels')).to include('global' => 'praefect')
        expect(t.dig('PodDisruptionBudget/test-praefect', 'metadata', 'labels')).to include('global' => 'praefect')
        expect(t.dig('Service/test-praefect', 'metadata', 'labels')).to include('global' => 'service')
        expect(t.dig('Service/test-praefect', 'metadata', 'labels')).to include('foo' => 'global')
        expect(t.dig('Service/test-praefect', 'metadata', 'labels')).to include('global_service' => 'true')
        expect(t.dig('Service/test-praefect', 'metadata', 'labels')).to include('service' => 'true')
        expect(t.dig('Service/test-praefect', 'metadata', 'labels')).not_to include('global' => 'global')
        expect(t.dig('StatefulSet/test-praefect', 'metadata', 'labels')).to include('foo' => 'global')
        expect(t.dig('StatefulSet/test-praefect', 'metadata', 'labels')).to include('global' => 'praefect')
        expect(t.dig('StatefulSet/test-praefect', 'metadata', 'labels')).not_to include('global' => 'global')
        expect(t.dig('StatefulSet/test-praefect', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
        expect(t.dig('StatefulSet/test-praefect', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
        expect(t.dig('StatefulSet/test-praefect', 'spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
      end
    end
  end
end
