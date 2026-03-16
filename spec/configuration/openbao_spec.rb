# frozen_string_literal: true

require 'spec_helper'
require 'hash_deep_merge'
require 'helm_template_helper'
require 'yaml'

describe 'OpenBao installation' do
  let(:values) do
    HelmTemplate.with_defaults(%(
    global:
      openbao:
        psql:
          host: test-postgresql.default.svc
          username: gitlab
          password:
            secret: gitlab-postgresql-password
            key: postgresql-password
    openbao:
      install: true
    ))
  end

  let(:template) { HelmTemplate.new(values) }
  let(:webservice_deployment) { template["Deployment/test-webservice-default"] }
  let(:openbao_deployment) { template["Deployment/test-openbao"] }
  let(:openbao_psql_config) do
    config = template.dig("ConfigMap/test-openbao-config", 'data', 'config.json')

    JSON.parse(config)['storage']['postgresql']
  end

  describe 'by default' do
    it 'uses the separate OpenBao logical database' do
      expect(openbao_psql_config['connection_url'])
        .to start_with('postgres://gitlab@test-postgresql.default.svc:5432/openbao')
    end
  end

  describe 'with a custom DB' do
    let(:values) do
      HelmTemplate.with_defaults(%(
      global:
        psql:
          keepalivesInterval: 10
          keepalivesIdle: 2
      openbao:
        install: true
        config:
          storage:
            postgresql:
              connection:
                host: psql.openbao.example.com
                port: 5555
                database: baodb
                username: baouser
                password:
                  secret: openbao-db-password
                  key: password
                keepalivesIdle: 3
      ))
    end

    it 'uses the custom PostgreSQL database' do
      expect(openbao_psql_config['connection_url'])
        .to start_with('postgres://baouser@psql.openbao.example.com:5555/baodb')
    end

    it 'merges connection arguments' do
      expect(openbao_psql_config['connection_url']).to include(
        'keepalives_interval=10',
        'keepalives_idle=3'
      )
    end
  end

  describe 'with custom database name' do
    let(:values) do
      HelmTemplate.with_defaults(%(
      global:
        openbao:
          psql:
            host: test-postgresql.default.svc
            username: gitlab
            database: custom_openbao_db
            password:
              secret: gitlab-postgresql-password
              key: postgresql-password
      openbao:
        install: true
    ))
    end

    it 'uses the custom database' do
      expect(openbao_psql_config['connection_url'])
        .to start_with('postgres://gitlab@test-postgresql.default.svc:5432/custom_openbao_db')
    end
  end

  describe 'when both connection.database and global.openbao.psql.database are set' do
    let(:values) do
      HelmTemplate.with_defaults(%(
      global:
        openbao:
          psql:
            database: should_be_ignored
      openbao:
        install: true
        config:
          storage:
            postgresql:
              connection:
                host: psql.openbao.example.com
                database: connection_wins
                username: baouser
                password:
                  secret: openbao-db-password
                  key: password
      ))
    end

    it 'connection.database takes precedence over global.openbao.psql.database' do
      expect(openbao_psql_config['connection_url'])
        .to start_with('postgres://baouser@psql.openbao.example.com:5432/connection_wins')
    end
  end

  describe 'with custom http audit secret' do
    let(:values) do
      HelmTemplate.with_defaults(%(
      global:
        openbao:
          enabled: true
          httpAudit:
            secret: audit-secret
            key: audit-key
          psql:
            host: test-postgresql.default.svc
            username: gitlab
            password:
              secret: gitlab-postgresql-password
              key: postgresql-password
      openbao:
        install: true
      ))
    end

    let(:expected_volume) do
      { "name" => "audit", "secret" => { "secretName" => "audit-secret" } }
    end

    it 'mounts the custom secret to webservice' do
      expect(template.get_projected_secret('Deployment/test-webservice-default', 'init-webservice-secrets', 'audit-secret')).to eq(
        { "items" => [{ "key" => "audit-key", "path" => "openbao/.gitlab_openbao_authentication_token_secret" }], "name" => "audit-secret" }
      )
    end

    it 'mounts the custom secret to OpenBao' do
      expect(openbao_deployment["spec"]["template"]["spec"]["volumes"]).to include(
        { "name" => "audit", "secret" => { "secretName" => "audit-secret" } }
      )
    end
  end
end
