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

  context 'when registry database user is configured' do
    let(:values) do
      YAML.safe_load(%(
        gitlab:
          toolbox:
            backups:
              registry:
                database:
                  user: registry_backup_user
                  password:
                    secret: registry-db-password
                    key: password
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'creates the registry database user ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-toolbox-registry-db-backup_restore-users')).to be true
      expect(template.dig('ConfigMap/test-toolbox-registry-db-backup_restore-users', 'data', 'db-user')).to include('REGISTRY_DATABASE_USER=registry_backup_user')
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

      # Check ConfigMap for user
      user_config = sources.find { |s| s['configMap'] && s['configMap']['name'] == 'test-toolbox-registry-db-backup_restore-users' }
      expect(user_config).not_to be_nil
      expect(user_config['configMap']['optional']).to be true
      expect(user_config['configMap']['items']).to eq([{ 'key' => 'db-user', 'path' => 'user.env' }])

      # Check Secret for password
      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'registry-db-password' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['optional']).to be true
      expect(password_secret['secret']['items']).to eq([{ 'key' => 'password', 'path' => 'pass' }])
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

  context 'when registry database user is not configured' do
    let(:values) { default_values }
    let(:template) { HelmTemplate.new(values) }

    it 'does not create the registry database user ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-toolbox-registry-db-backup_restore-users')).to be false
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
      YAML.safe_load(%(
        gitlab:
          toolbox:
            backups:
              registry:
                database:
                  user: registry_user
                  password:
                    secret: custom-registry-secret
                    key: custom-key
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'uses the custom secret name and key' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      registry_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'registry-db-config' }
      sources = registry_db_volume['projected']['sources']

      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'custom-registry-secret' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['items']).to eq([{ 'key' => 'custom-key', 'path' => 'pass' }])
    end
  end

  context 'when using default password secret' do
    let(:values) do
      YAML.safe_load(%(
        gitlab:
          toolbox:
            backups:
              registry:
                database:
                  user: registry_user
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'uses the default secret name and key' do
      deployment_spec = template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec')
      registry_db_volume = deployment_spec['volumes'].find { |v| v['name'] == 'registry-db-config' }
      sources = registry_db_volume['projected']['sources']

      password_secret = sources.find { |s| s['secret'] && s['secret']['name'] == 'test-toolbox-registry-database-password' }
      expect(password_secret).not_to be_nil
      expect(password_secret['secret']['items']).to eq([{ 'key' => 'password', 'path' => 'pass' }])
    end
  end
end
