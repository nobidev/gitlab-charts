# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'toolbox openbao database configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      gitlab:
        toolbox:
          backups:
            cron:
              enabled: true
              persistence:
                enabled: true
          enabled: true
          persistence:
            enabled: true
          serviceAccount:
            enabled: true
            create: true
    ))
  end

  context 'when global.openbao.psql.host is set' do
    let(:values) do
      YAML.safe_load(%(
        global:
          openbao:
            psql:
              host: openbao-db.example.com
              port: 5432
              database: openbao
              username: openbao
              password:
                secret: openbao-db-password
                key: password
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'creates the openbao database connection ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-toolbox-openbao-db-connection-config')).to be true
    end

    it 'renders connection parameters in the ConfigMap' do
      config_data = template.dig('ConfigMap/test-toolbox-openbao-db-connection-config', 'data', 'db-connection.env')
      expect(config_data).to include('OPENBAO_DATABASE_HOST="openbao-db.example.com"')
      expect(config_data).to include('OPENBAO_DATABASE_PORT="5432"')
      expect(config_data).to include('OPENBAO_DATABASE_NAME="openbao"')
      expect(config_data).to include('OPENBAO_DATABASE_USER="openbao"')
    end

    it 'mounts openbao-db-config volume in deployment' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      openbao_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'openbao-db-config' }

      expect(openbao_db_volume).not_to be_nil
      expect(openbao_db_volume['projected']).not_to be_nil
      expect(openbao_db_volume['projected']['defaultMode']).to eq(0o440)

      sources = openbao_db_volume['projected']['sources']
      expect(sources.length).to eq(2)

      connection_config = sources.find { |s| s['configMap'] && s['configMap']['name'] == 'test-toolbox-openbao-db-connection-config' }
      expect(connection_config).not_to be_nil
      expect(connection_config['configMap']['optional']).to be true
      expect(connection_config['configMap']['items']).to eq([{ 'key' => 'db-connection.env', 'path' => 'connection.env' }])

      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'openbao-db-password' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['optional']).to be true
      expect(password_secret['secret']['items']).to eq([{ 'key' => 'password', 'path' => 'backup-pass' }])
    end

    it 'mounts openbao-db-config volume in backup job' do
      cronjob_spec = template.dig('CronJob/test-toolbox-backup', 'spec', 'jobTemplate', 'spec', 'template', 'spec')
      openbao_db_volume = cronjob_spec['volumes'].find { |v| v['name'] == 'openbao-db-config' }

      expect(openbao_db_volume).not_to be_nil
      expect(openbao_db_volume['projected']).not_to be_nil
      expect(openbao_db_volume['projected']['defaultMode']).to eq(0o440)

      sources = openbao_db_volume['projected']['sources']
      expect(sources.length).to eq(2)

      sources.each do |source|
        if source['configMap']
          expect(source['configMap']['optional']).to be true
        elsif source['secret']
          expect(source['secret']['optional']).to be true
        end
      end
    end

    it 'mounts openbao-db-config at correct path in deployment' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      container = deployment_spec['containers'].find { |c| c['name'] == 'toolbox' }
      openbao_db_mount = container['volumeMounts'].find { |vm| vm['name'] == 'openbao-db-config' }

      expect(openbao_db_mount).not_to be_nil
      expect(openbao_db_mount['mountPath']).to eq('/etc/gitlab/openbao-db/')
      expect(openbao_db_mount['readOnly']).to be true
    end

    it 'mounts openbao-db-config at correct path in backup job' do
      cronjob_spec = template.dig('CronJob/test-toolbox-backup', 'spec', 'jobTemplate', 'spec', 'template', 'spec')
      container = cronjob_spec['containers'].find { |c| c['name'] == 'toolbox-backup' }
      openbao_db_mount = container['volumeMounts'].find { |vm| vm['name'] == 'openbao-db-config' }

      expect(openbao_db_mount).not_to be_nil
      expect(openbao_db_mount['mountPath']).to eq('/etc/gitlab/openbao-db/')
      expect(openbao_db_mount['readOnly']).to be true
    end
  end

  context 'when global.openbao.psql.host is not set' do
    let(:values) { default_values }
    let(:template) { HelmTemplate.new(values) }

    it 'does not create the openbao database connection ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-toolbox-openbao-db-connection-config')).to be false
    end

    it 'still mounts openbao-db-config volume with all sources optional in deployment' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      openbao_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'openbao-db-config' }

      expect(openbao_db_volume).not_to be_nil
      expect(openbao_db_volume['projected']['sources']).to all(
        satisfy { |s| (s['configMap'] && s['configMap']['optional']) || (s['secret'] && s['secret']['optional']) }
      )
    end
  end

  context 'when custom password secret is configured' do
    let(:values) do
      YAML.safe_load(%(
        global:
          openbao:
            psql:
              host: openbao-db.example.com
              password:
                secret: custom-openbao-secret
                key: custom-password-key
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'uses the custom secret name and key' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      openbao_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'openbao-db-config' }
      sources = openbao_db_volume['projected']['sources']

      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'custom-openbao-secret' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['items']).to eq([{ 'key' => 'custom-password-key', 'path' => 'backup-pass' }])
    end
  end

  context 'when using the default password secret' do
    let(:values) do
      YAML.safe_load(%(
        global:
          openbao:
            psql:
              host: openbao-db.example.com
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'uses the default secret name and default key' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      openbao_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'openbao-db-config' }
      sources = openbao_db_volume['projected']['sources']

      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'test-toolbox-openbao-database-password' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['items']).to eq([{ 'key' => 'password', 'path' => 'backup-pass' }])
    end
  end

  context 'when sslMode is configured' do
    let(:values) do
      YAML.safe_load(%(
        global:
          openbao:
            psql:
              host: openbao-db.example.com
              sslMode: require
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'renders the configured sslMode in the ConfigMap' do
      config_data = template.dig('ConfigMap/test-toolbox-openbao-db-connection-config', 'data', 'db-connection.env')
      expect(config_data).to include('OPENBAO_DATABASE_SSLMODE="require"')
    end
  end

  context 'when sslMode is not configured (defaults to disable)' do
    let(:values) do
      YAML.safe_load(%(
        global:
          openbao:
            psql:
              host: openbao-db.example.com
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'renders OPENBAO_DATABASE_SSLMODE as disable in the ConfigMap' do
      config_data = template.dig('ConfigMap/test-toolbox-openbao-db-connection-config', 'data', 'db-connection.env')
      expect(config_data).to include('OPENBAO_DATABASE_SSLMODE="disable"')
    end
  end

  context 'when connectTimeout is configured' do
    let(:values) do
      YAML.safe_load(%(
        global:
          openbao:
            psql:
              host: openbao-db.example.com
              connectTimeout: "5"
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'includes OPENBAO_DATABASE_CONNECT_TIMEOUT in the ConfigMap' do
      config_data = template.dig('ConfigMap/test-toolbox-openbao-db-connection-config', 'data', 'db-connection.env')
      expect(config_data).to include('OPENBAO_DATABASE_CONNECT_TIMEOUT="5"')
    end
  end

  context 'when connectTimeout is not configured' do
    let(:values) do
      YAML.safe_load(%(
        global:
          openbao:
            psql:
              host: openbao-db.example.com
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'omits OPENBAO_DATABASE_CONNECT_TIMEOUT from the ConfigMap' do
      config_data = template.dig('ConfigMap/test-toolbox-openbao-db-connection-config', 'data', 'db-connection.env')
      expect(config_data).not_to include('OPENBAO_DATABASE_CONNECT_TIMEOUT')
    end
  end
end
