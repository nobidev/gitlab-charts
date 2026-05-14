require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'toolbox registry database configuration' do
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

  context 'when registry database backup user is configured' do
    let(:values) do
      default_values.deep_merge(YAML.safe_load(%(
        gitlab:
          toolbox:
            backups:
              registry:
                database:
                  backupUser: registry_backup_user
                  password:
                    secret: registry-db-password
                    backupPasswordKey: backupPassword
                    restorePasswordKey: restorePassword
      )))
    end

    let(:template) { HelmTemplate.new(values) }

    it 'creates the registry database user ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-toolbox-registry-db-backuprestore-users')).to be true
      expect(template.dig('ConfigMap/test-toolbox-registry-db-backuprestore-users', 'data', 'backup-user')).to include('REGISTRY_DATABASE_USER=registry_backup_user')
    end

    it 'mounts registry-db-config volume in deployment' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      registry_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'registry-db-config' }

      expect(registry_db_volume).not_to be_nil
      expect(registry_db_volume['projected']).not_to be_nil
      expect(registry_db_volume['projected']['defaultMode']).to eq(0o440)

      sources = registry_db_volume['projected']['sources']
      expect(sources.length).to eq(3)

      # Check ConfigMap for connection config
      connection_config = sources.find { |s| s['configMap'] && s['configMap']['name'] == 'test-registry-db-connection-config' }
      expect(connection_config).not_to be_nil
      expect(connection_config['configMap']['optional']).to be true
      expect(connection_config['configMap']['items']).to eq([{ 'key' => 'db-connection.env', 'path' => 'connection.env' }])

      # Check ConfigMap for users
      user_config = sources.find { |s| s['configMap'] && s['configMap']['name'] == 'test-toolbox-registry-db-backuprestore-users' }
      expect(user_config).not_to be_nil
      expect(user_config['configMap']['optional']).to be true
      expect(user_config['configMap']['items']).to include({ 'key' => 'backup-user', 'path' => 'backup-user.env' })

      # Check Secret for passwords
      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'registry-db-password' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['optional']).to be true
      expect(password_secret['secret']['items']).to include({ 'key' => 'backupPassword', 'path' => 'backup-pass' })
    end

    it 'mounts registry-db-config volume in backup job' do
      cronjob_spec = template.dig('CronJob/test-toolbox-backup', 'spec', 'jobTemplate', 'spec', 'template', 'spec')
      registry_db_volume = cronjob_spec['volumes'].find { |v| v['name'] == 'registry-db-config' }

      expect(registry_db_volume).not_to be_nil
      expect(registry_db_volume['projected']).not_to be_nil
      expect(registry_db_volume['projected']['defaultMode']).to eq(0o440)

      sources = registry_db_volume['projected']['sources']
      expect(sources.length).to eq(3)

      # Verify all sources are marked as optional
      sources.each do |source|
        if source['configMap']
          expect(source['configMap']['optional']).to be true
        elsif source['secret']
          expect(source['secret']['optional']).to be true
        end
      end
    end

    it 'mounts registry-db-config at correct path in deployment' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      container = deployment_spec['containers'].find { |c| c['name'] == 'toolbox' }
      registry_db_mount = container['volumeMounts'].find { |vm| vm['name'] == 'registry-db-config' }

      expect(registry_db_mount).not_to be_nil
      expect(registry_db_mount['mountPath']).to eq('/etc/gitlab/registry-db/')
      expect(registry_db_mount['readOnly']).to be true
    end

    it 'mounts registry-db-config at correct path in backup job' do
      cronjob_spec = template.dig('CronJob/test-toolbox-backup', 'spec', 'jobTemplate', 'spec', 'template', 'spec')
      container = cronjob_spec['containers'].find { |c| c['name'] == 'toolbox-backup' }
      registry_db_mount = container['volumeMounts'].find { |vm| vm['name'] == 'registry-db-config' }

      expect(registry_db_mount).not_to be_nil
      expect(registry_db_mount['mountPath']).to eq('/etc/gitlab/registry-db/')
      expect(registry_db_mount['readOnly']).to be true
    end
  end

  context 'when registry database restore user is configured' do
    let(:values) do
      default_values.deep_merge(YAML.safe_load(%(
        gitlab:
          toolbox:
            backups:
              registry:
                database:
                  restoreUser: registry_restore_user
                  password:
                    secret: registry-db-password
                    backupPasswordKey: backupPassword
                    restorePasswordKey: restorePassword
      )))
    end

    let(:template) { HelmTemplate.new(values) }

    it 'creates the registry database user ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-toolbox-registry-db-backuprestore-users')).to be true
      expect(template.dig('ConfigMap/test-toolbox-registry-db-backuprestore-users', 'data', 'restore-user')).to include('REGISTRY_DATABASE_USER=registry_restore_user')
    end

    it 'mounts registry-db-config volume in deployment' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      registry_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'registry-db-config' }

      expect(registry_db_volume).not_to be_nil
      expect(registry_db_volume['projected']).not_to be_nil
      expect(registry_db_volume['projected']['defaultMode']).to eq(0o440)

      sources = registry_db_volume['projected']['sources']
      expect(sources.length).to eq(3)

      # Check ConfigMap for connection config
      connection_config = sources.find { |s| s['configMap'] && s['configMap']['name'] == 'test-registry-db-connection-config' }
      expect(connection_config).not_to be_nil
      expect(connection_config['configMap']['optional']).to be true
      expect(connection_config['configMap']['items']).to eq([{ 'key' => 'db-connection.env', 'path' => 'connection.env' }])

      # Check ConfigMap for users
      user_config = sources.find { |s| s['configMap'] && s['configMap']['name'] == 'test-toolbox-registry-db-backuprestore-users' }
      expect(user_config).not_to be_nil
      expect(user_config['configMap']['optional']).to be true
      expect(user_config['configMap']['items']).to include({ 'key' => 'restore-user', 'path' => 'restore-user.env' })

      # Check Secret for passwords
      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'registry-db-password' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['optional']).to be true
      expect(password_secret['secret']['items']).to include({ 'key' => 'restorePassword', 'path' => 'restore-pass' })
    end

    it 'mounts registry-db-config volume in backup job' do
      cronjob_spec = template.dig('CronJob/test-toolbox-backup', 'spec', 'jobTemplate', 'spec', 'template', 'spec')
      registry_db_volume = cronjob_spec['volumes'].find { |v| v['name'] == 'registry-db-config' }

      expect(registry_db_volume).not_to be_nil
      expect(registry_db_volume['projected']).not_to be_nil
      expect(registry_db_volume['projected']['defaultMode']).to eq(0o440)

      sources = registry_db_volume['projected']['sources']
      expect(sources.length).to eq(3)

      # Verify all sources are marked as optional
      sources.each do |source|
        if source['configMap']
          expect(source['configMap']['optional']).to be true
        elsif source['secret']
          expect(source['secret']['optional']).to be true
        end
      end
    end

    it 'mounts registry-db-config at correct path in deployment' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      container = deployment_spec['containers'].find { |c| c['name'] == 'toolbox' }
      registry_db_mount = container['volumeMounts'].find { |vm| vm['name'] == 'registry-db-config' }

      expect(registry_db_mount).not_to be_nil
      expect(registry_db_mount['mountPath']).to eq('/etc/gitlab/registry-db/')
      expect(registry_db_mount['readOnly']).to be true
    end

    it 'mounts registry-db-config at correct path in backup job' do
      cronjob_spec = template.dig('CronJob/test-toolbox-backup', 'spec', 'jobTemplate', 'spec', 'template', 'spec')
      container = cronjob_spec['containers'].find { |c| c['name'] == 'toolbox-backup' }
      registry_db_mount = container['volumeMounts'].find { |vm| vm['name'] == 'registry-db-config' }

      expect(registry_db_mount).not_to be_nil
      expect(registry_db_mount['mountPath']).to eq('/etc/gitlab/registry-db/')
      expect(registry_db_mount['readOnly']).to be true
    end
  end

  context 'when both backup and restore users are configured' do
    let(:values) do
      default_values.deep_merge(YAML.safe_load(%(
        gitlab:
          toolbox:
            backups:
              registry:
                database:
                  backupUser: registry_backup_user
                  restoreUser: registry_restore_user
                  password:
                    secret: registry-db-password
                    backupPasswordKey: backupPassword
                    restorePasswordKey: restorePassword
      )))
    end

    let(:template) { HelmTemplate.new(values) }

    it 'creates the registry database user ConfigMap with both users' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-toolbox-registry-db-backuprestore-users')).to be true
      config_data = template.dig('ConfigMap/test-toolbox-registry-db-backuprestore-users', 'data')
      expect(config_data['backup-user']).to include('REGISTRY_DATABASE_USER=registry_backup_user')
      expect(config_data['restore-user']).to include('REGISTRY_DATABASE_USER=registry_restore_user')
    end

    it 'mounts both backup and restore password keys' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      registry_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'registry-db-config' }
      sources = registry_db_volume['projected']['sources']

      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'registry-db-password' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['items']).to include({ 'key' => 'backupPassword', 'path' => 'backup-pass' })
      expect(password_secret['secret']['items']).to include({ 'key' => 'restorePassword', 'path' => 'restore-pass' })
    end
  end

  context 'when registry database users are not configured' do
    let(:values) { default_values }
    let(:template) { HelmTemplate.new(values) }

    it 'does not create the registry database user ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-toolbox-registry-db-backuprestore-users')).to be false
    end

    it 'still mounts registry-db-config volume with optional sources' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      registry_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'registry-db-config' }

      expect(registry_db_volume).not_to be_nil
      expect(registry_db_volume['projected']['sources']).to all(
        satisfy { |s| (s['configMap'] && s['configMap']['optional']) || (s['secret'] && s['secret']['optional']) }
      )
    end
  end

  context 'when custom password secret is configured' do
    let(:values) do
      default_values.deep_merge(YAML.safe_load(%(
        gitlab:
          toolbox:
            backups:
              registry:
                database:
                  backupUser: registry_user
                  password:
                    secret: custom-registry-secret
                    backupPasswordKey: custom-backup-key
                    restorePasswordKey: custom-restore-key
      )))
    end

    let(:template) { HelmTemplate.new(values) }

    it 'uses the custom secret name and keys' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      registry_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'registry-db-config' }
      sources = registry_db_volume['projected']['sources']

      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'custom-registry-secret' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['items']).to include({ 'key' => 'custom-backup-key', 'path' => 'backup-pass' })
      expect(password_secret['secret']['items']).to include({ 'key' => 'custom-restore-key', 'path' => 'restore-pass' })
    end
  end

  context 'when using default password secret' do
    let(:values) do
      default_values.deep_merge(YAML.safe_load(%(
        gitlab:
          toolbox:
            backups:
              registry:
                database:
                  backupUser: registry_user
      )))
    end

    let(:template) { HelmTemplate.new(values) }

    it 'uses the default secret name and keys' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      registry_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'registry-db-config' }
      sources = registry_db_volume['projected']['sources']

      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'test-toolbox-registry-database-password' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['items']).to include({ 'key' => 'backupPassword', 'path' => 'backup-pass' })
      expect(password_secret['secret']['items']).to include({ 'key' => 'restorePassword', 'path' => 'restore-pass' })
    end
  end
end
