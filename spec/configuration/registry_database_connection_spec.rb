require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'registry database connection configuration' do
  let(:default_values) do
    HelmTemplate.defaults
  end

  context 'when registry database is enabled' do
    let(:values) do
      YAML.safe_load(%(
        registry:
          enabled: true
          database:
            enabled: true
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'creates the registry database connection ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-registry-db-connection-config')).to be true
    end

    it 'populates database connection environment variables' do
      config_data = template.dig('ConfigMap/test-registry-db-connection-config', 'data', 'db-connection.env')

      expect(config_data).to include('REGISTRY_DATABASE_HOST=')
      expect(config_data).to include('REGISTRY_DATABASE_PORT=')
      expect(config_data).to include('REGISTRY_DATABASE_NAME=')
      expect(config_data).to include('REGISTRY_DATABASE_SSLMODE=')
    end
  end

  context 'when registry database is configured, and not enabled' do
    let(:values) do
      YAML.safe_load(%(
        registry:
          enabled: true
          database:
            configure: true
            enabled: false
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'creates the registry database connection ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-registry-db-connection-config')).to be true
    end
  end

  context 'when registry database is not enabled or configured' do
    let(:values) do
      YAML.safe_load(%(
        registry:
          enabled: true
          database:
            enabled: false
            configure: false
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'does not create the registry database connection ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-registry-db-connection-config')).to be false
    end
  end

  context 'when global.psql.ssl is configured' do
    let(:values) do
      YAML.safe_load(%(
        global:
          psql:
            ssl:
              secret: postgresql-ssl-secret
              clientCertificate: client-cert.pem
              clientKey: client-key.pem
              serverCA: server-ca.pem
        registry:
          enabled: true
          database:
            enabled: true
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'includes SSL certificate paths in connection config' do
      config_data = template.dig('ConfigMap/test-registry-db-connection-config', 'data', 'db-connection.env')

      expect(config_data).to include('REGISTRY_DATABASE_SSL_CERT=/etc/gitlab/postgres/ssl/client-certificate.pem')
      expect(config_data).to include('REGISTRY_DATABASE_SSL_KEY=/etc/gitlab/postgres/ssl/client-key.pem')
      expect(config_data).to include('REGISTRY_DATABASE_SSL_ROOTCERT=/etc/gitlab/postgres/ssl/server-ca.pem')
    end
  end

  context 'when global.psql.ssl is not configured' do
    let(:values) do
      YAML.safe_load(%(
        registry:
          enabled: true
          database:
            enabled: true
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'does not include SSL certificate paths in connection config' do
      config_data = template.dig('ConfigMap/test-registry-db-connection-config', 'data', 'db-connection.env')

      expect(config_data).not_to include('REGISTRY_DATABASE_SSL_CERT')
      expect(config_data).not_to include('REGISTRY_DATABASE_SSL_KEY')
      expect(config_data).not_to include('REGISTRY_DATABASE_SSL_ROOTCERT')
    end
  end

  context 'when database connecttimeout is configured' do
    let(:values) do
      YAML.safe_load(%(
        registry:
          enabled: true
          database:
            enabled: true
            connecttimeout: 30
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'includes connection timeout in connection config' do
      config_data = template.dig('ConfigMap/test-registry-db-connection-config', 'data', 'db-connection.env')

      expect(config_data).to include('REGISTRY_DATABASE_CONNECTION_TIMEOUT=30')
    end
  end

  context 'when database connecttimeout is not configured' do
    let(:values) do
      YAML.safe_load(%(
        registry:
          enabled: true
          database:
            enabled: true
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'does not include connection timeout in connection config' do
      config_data = template.dig('ConfigMap/test-registry-db-connection-config', 'data', 'db-connection.env')

      expect(config_data).not_to include('REGISTRY_DATABASE_CONNECTION_TIMEOUT')
    end
  end

  context 'when registry is disabled' do
    let(:values) do
      YAML.safe_load(%(
        registry:
          enabled: false
          database:
            enabled: true
      )).deep_merge(default_values)
    end

    let(:template) { HelmTemplate.new(values) }

    it 'does not create the registry database connection ConfigMap' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resource_exists?('ConfigMap/test-registry-db-connection-config')).to be false
    end
  end
end
