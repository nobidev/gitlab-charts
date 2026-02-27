# frozen_string_literal: true

require 'spec_helper'
require 'hash_deep_merge'
require 'helm_template_helper'
require 'yaml'

describe 'OpenBao installation' do
  let(:values) do
    HelmTemplate.with_defaults(%(
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
      openbao:
        install: true
        psql:
          database: custom_openbao_db
      ))
    end

    it 'uses the custom database' do
      expect(openbao_psql_config['connection_url'])
        .to start_with('postgres://gitlab@test-postgresql.default.svc:5432/custom_openbao_db')
    end
  end

  describe 'PostgreSQL init script' do
    let(:values) do
      HelmTemplate.with_defaults(%(
      postgresql:
        install: true
      openbao:
        install: true
      ))
    end

    it 'creates init_openbao.sh when openbao is installed' do
      init_script = template.dig('ConfigMap/test-postgresql-init-db', 'data', 'init_openbao.sh')
      expect(init_script).not_to be_nil
      expect(init_script).to include('CREATE DATABASE')
      expect(init_script).to include('openbao')
      expect(init_script).to include('OWNER')
    end

    context 'when openbao is not installed' do
      let(:values) do
        HelmTemplate.with_defaults(%(
        postgresql:
          install: true
        openbao:
          install: false
        ))
      end

      it 'does not create init_openbao.sh' do
        init_script = template.dig('ConfigMap/test-postgresql-init-db', 'data', 'init_openbao.sh')
        expect(init_script).to be_nil
      end
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
