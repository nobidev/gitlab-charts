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
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'creates the openbao database connection ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-toolbox-openbao-db-connection-config')).to be true
    end

    it 'renders connection parameters in the ConfigMap without OPENBAO_DATABASE_USER' do
      config_data = template.dig('ConfigMap/test-toolbox-openbao-db-connection-config', 'data', 'db-connection.env')
      expect(config_data).to include('OPENBAO_DATABASE_HOST="openbao-db.example.com"')
      expect(config_data).to include('OPENBAO_DATABASE_PORT="5432"')
      expect(config_data).to include('OPENBAO_DATABASE_NAME="openbao"')
      expect(config_data).not_to include('OPENBAO_DATABASE_USER')
    end

    it 'mounts openbao-db-config volume with 3 sources in deployment' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      openbao_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'openbao-db-config' }

      expect(openbao_db_volume).not_to be_nil
      expect(openbao_db_volume['projected']).not_to be_nil
      expect(openbao_db_volume['projected']['defaultMode']).to eq(0o440)

      sources = openbao_db_volume['projected']['sources']
      expect(sources.length).to eq(3)

      connection_config = sources.find { |s| s['configMap'] && s['configMap']['name'] == 'test-toolbox-openbao-db-connection-config' }
      expect(connection_config).not_to be_nil
      expect(connection_config['configMap']['optional']).to be true
      expect(connection_config['configMap']['items']).to eq([{ 'key' => 'db-connection.env', 'path' => 'connection.env' }])

      users_config = sources.find { |s| s['configMap'] && s['configMap']['name'] == 'test-toolbox-openbao-db-backuprestore-users' }
      expect(users_config).not_to be_nil
      expect(users_config['configMap']['optional']).to be true
      expect(users_config['configMap']['items']).to eq([
        { 'key' => 'backup-user', 'path' => 'backup-user.env' },
        { 'key' => 'restore-user', 'path' => 'restore-user.env' }
      ])

      password_secret = sources.find { |s| s['secret'] }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['optional']).to be true
      expect(password_secret['secret']['items']).to eq([
        { 'key' => 'backupPassword', 'path' => 'backup-pass' },
        { 'key' => 'restorePassword', 'path' => 'restore-pass' }
      ])
    end

    it 'mounts openbao-db-config volume with 3 sources in backup job' do
      cronjob_spec = template.dig('CronJob/test-toolbox-backup', 'spec', 'jobTemplate', 'spec', 'template', 'spec')
      openbao_db_volume = cronjob_spec['volumes'].find { |v| v['name'] == 'openbao-db-config' }

      expect(openbao_db_volume).not_to be_nil
      expect(openbao_db_volume['projected']).not_to be_nil
      expect(openbao_db_volume['projected']['defaultMode']).to eq(0o440)

      sources = openbao_db_volume['projected']['sources']
      expect(sources.length).to eq(3)

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

  context 'when backupUser and restoreUser are configured' do
    let(:values) do
      YAML.safe_load(%(
        global:
          openbao:
            psql:
              host: openbao-db.example.com
        gitlab:
          toolbox:
            backups:
              openbao:
                database:
                  backupUser: openbao_backup
                  restoreUser: openbao_restore
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'creates the openbao backuprestore-users ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-toolbox-openbao-db-backuprestore-users')).to be true
    end

    it 'renders backup-user and restore-user in the ConfigMap' do
      config_data = template.dig('ConfigMap/test-toolbox-openbao-db-backuprestore-users', 'data')
      expect(config_data['backup-user']).to include('OPENBAO_DATABASE_USER=openbao_backup')
      expect(config_data['restore-user']).to include('OPENBAO_DATABASE_USER=openbao_restore')
    end
  end

  context 'when neither backupUser nor restoreUser is configured' do
    let(:values) do
      YAML.safe_load(%(
        global:
          openbao:
            psql:
              host: openbao-db.example.com
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'does not create the openbao backuprestore-users ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-toolbox-openbao-db-backuprestore-users')).to be false
    end
  end

  context 'when custom password secret is configured' do
    let(:values) do
      YAML.safe_load(%(
        global:
          openbao:
            psql:
              host: openbao-db.example.com
        gitlab:
          toolbox:
            backups:
              openbao:
                database:
                  password:
                    secret: custom-openbao-secret
                    backupPasswordKey: myBackupKey
                    restorePasswordKey: myRestoreKey
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'uses the custom secret name and per-operation keys' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      openbao_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'openbao-db-config' }
      sources = openbao_db_volume['projected']['sources']

      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'custom-openbao-secret' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['items']).to eq([
        { 'key' => 'myBackupKey', 'path' => 'backup-pass' },
        { 'key' => 'myRestoreKey', 'path' => 'restore-pass' }
      ])
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

    it 'uses the default secret name and default backup/restore keys' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      openbao_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'openbao-db-config' }
      sources = openbao_db_volume['projected']['sources']

      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'test-toolbox-openbao-database-password' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['items']).to eq([
        { 'key' => 'backupPassword', 'path' => 'backup-pass' },
        { 'key' => 'restorePassword', 'path' => 'restore-pass' }
      ])
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

  context 'when global.psql.ssl is set and sslMode is non-disable' do
    let(:values) do
      YAML.safe_load(%(
        global:
          psql:
            ssl:
              secret: gitlab-ssl
              clientCertificate: client.crt
              clientKey: client.key
              serverCA: server-ca.crt
          openbao:
            psql:
              host: openbao-db.example.com
              sslMode: verify-full
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'renders SSL cert paths in the ConfigMap' do
      config_data = template.dig('ConfigMap/test-toolbox-openbao-db-connection-config', 'data', 'db-connection.env')
      expect(config_data).to include('OPENBAO_DATABASE_SSLCERT=/etc/gitlab/postgres/ssl/client-certificate.pem')
      expect(config_data).to include('OPENBAO_DATABASE_SSLKEY=/etc/gitlab/postgres/ssl/client-key.pem')
      expect(config_data).to include('OPENBAO_DATABASE_ROOTCERT=/etc/gitlab/postgres/ssl/server-ca.pem')
    end
  end

  context 'when global.psql.ssl is set but sslMode is disable' do
    let(:values) do
      YAML.safe_load(%(
        global:
          psql:
            ssl:
              secret: gitlab-ssl
              clientCertificate: client.crt
              clientKey: client.key
              serverCA: server-ca.crt
          openbao:
            psql:
              host: openbao-db.example.com
              sslMode: disable
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'does not render SSL cert paths when sslMode is disable' do
      config_data = template.dig('ConfigMap/test-toolbox-openbao-db-connection-config', 'data', 'db-connection.env')
      expect(config_data).not_to include('OPENBAO_DATABASE_SSLCERT')
      expect(config_data).not_to include('OPENBAO_DATABASE_SSLKEY')
      expect(config_data).not_to include('OPENBAO_DATABASE_ROOTCERT')
    end
  end

  context 'when global.psql.ssl is set and sslMode is not configured (defaults to disable)' do
    let(:values) do
      YAML.safe_load(%(
        global:
          psql:
            ssl:
              secret: gitlab-ssl
              clientCertificate: client.crt
              clientKey: client.key
              serverCA: server-ca.crt
          openbao:
            psql:
              host: openbao-db.example.com
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'does not render SSL cert paths when sslMode defaults to disable' do
      config_data = template.dig('ConfigMap/test-toolbox-openbao-db-connection-config', 'data', 'db-connection.env')
      expect(config_data).not_to include('OPENBAO_DATABASE_SSLCERT')
      expect(config_data).not_to include('OPENBAO_DATABASE_SSLKEY')
      expect(config_data).not_to include('OPENBAO_DATABASE_ROOTCERT')
    end
  end
end
