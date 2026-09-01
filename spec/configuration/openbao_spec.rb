# frozen_string_literal: true

require 'spec_helper'
require 'hash_deep_merge'
require 'helm_template_helper'
require 'yaml'

describe 'OpenBao installation' do
  let(:template) { HelmTemplate.new(values) }
  let(:webservice_deployment) { template["Deployment/test-webservice-default"] }
  let(:openbao_deployment) { template["Deployment/test-openbao"] }
  let(:openbao_psql_config) do
    config = template.dig("ConfigMap/test-openbao-config", 'data', 'config.json')

    JSON.parse(config)['storage']['postgresql']
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

    it 'sets the connection_url' do
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
        config:
          storage:
            postgresql:
              connection:
                host: test-postgresql.default.svc
                username: gitlab
                database: custom_openbao_db
                password:
                  secret: gitlab-postgresql-password
                  key: postgresql-password
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

  describe 'unseal key configuration' do
    let(:openbao_volumes) { openbao_deployment["spec"]["template"]["spec"]["volumes"] }
    let(:openbao_mounts) { openbao_deployment["spec"]["template"]["spec"]["containers"].first["volumeMounts"] }
    let(:generate_secrets) { template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets') }
    let(:seal_config) do
      config = template.dig('ConfigMap/test-openbao-config', 'data', 'config.json')

      JSON.parse(config)['seal']
    end

    let(:base_values) do
      %(
      global:
        openbao:
          enabled: true
          psql:
            host: test-postgresql.default.svc
            username: gitlab
            password:
              secret: gitlab-postgresql-password
              key: postgresql-password
      openbao:
        install: true
      )
    end

    context 'with the default static unseal' do
      let(:values) { HelmTemplate.with_defaults(base_values) }

      it 'generates the static unseal secret' do
        expect(generate_secrets).to include('test-openbao-unseal')
      end

      it 'generates the secret under the default key field' do
        expect(generate_secrets).to include('--from-file=key=bao-unseal')
      end

      it 'mounts the current key' do
        expect(openbao_mounts).to include(
          'name' => 'unseal',
          'mountPath' => '/srv/openbao/keys/gl-unseal-1',
          'subPath' => 'key',
          'readOnly' => true
        )
      end

      it 'does not mount a previous key' do
        expect(openbao_mounts.count { |m| m['name'] == 'unseal' }).to eq(1)
      end

      it 'renders the current key in the seal config' do
        expect(seal_config['static']).to include(
          'current_key_id' => 'gl-unseal-1',
          'current_key' => 'file:///srv/openbao/keys/gl-unseal-1'
        )
      end

      it 'does not render a previous key in the seal config' do
        expect(seal_config['static']).not_to include('previous_key_id', 'previous_key')
      end
    end

    context 'with static unseal key rotation' do
      let(:values) do
        HelmTemplate.with_defaults(%(
        global:
          openbao:
            enabled: true
            unseal:
              currentKeyField: gl-unseal-2
              previousKeyField: key
            psql:
              host: test-postgresql.default.svc
              username: gitlab
              password:
                secret: gitlab-postgresql-password
                key: postgresql-password
        openbao:
          install: true
          config:
            unseal:
              static:
                currentKeyId: gl-unseal-2
                currentKey: /srv/openbao/keys/gl-unseal-2
                previousKeyId: gl-unseal-1
                previousKey: /srv/openbao/keys/gl-unseal-1
        ))
      end

      it 'mounts each key from its configured field' do
        expect(openbao_mounts).to include(
          a_hash_including('name' => 'unseal', 'mountPath' => '/srv/openbao/keys/gl-unseal-2', 'subPath' => 'gl-unseal-2'),
          a_hash_including('name' => 'unseal', 'mountPath' => '/srv/openbao/keys/gl-unseal-1', 'subPath' => 'key')
        )
      end

      it 'generates the secret under the current field only' do
        expect(generate_secrets).to include('--from-file=gl-unseal-2=bao-unseal')
        expect(generate_secrets).not_to include('--from-file=key=bao-unseal')
      end

      it 'renders the current key in the seal config' do
        expect(seal_config['static']).to include(
          'current_key_id' => 'gl-unseal-2',
          'current_key' => 'file:///srv/openbao/keys/gl-unseal-2'
        )
      end

      it 'renders the previous key in the seal config' do
        expect(seal_config['static']).to include(
          'previous_key_id' => 'gl-unseal-1',
          'previous_key' => 'file:///srv/openbao/keys/gl-unseal-1'
        )
      end
    end

    context 'with AWS KMS unseal' do
      let(:values) do
        HelmTemplate.with_defaults(base_values + %(
        config:
          unseal:
            static:
              enabled: false
            awskms:
              enabled: true
              kmsKeyId: alias/my-openbao-key
              region: us-east-1
        ))
      end

      it 'does not generate the static unseal secret' do
        expect(generate_secrets).not_to include('test-openbao-unseal')
      end

      it 'does not mount the unseal secret' do
        expect(openbao_mounts.map { |m| m['name'] }).not_to include('unseal')
        expect(openbao_volumes.map { |v| v['name'] }).not_to include('unseal')
      end

      it 'still mounts the audit secret' do
        expect(openbao_mounts.map { |m| m['name'] }).to include('audit')
      end

      it 'renders the awskms seal config without a static block' do
        expect(seal_config).to have_key('awskms')
        expect(seal_config).not_to have_key('static')
      end
    end

    context 'with previousKeyId set but previousKey empty' do
      let(:values) do
        HelmTemplate.with_defaults(base_values + %(
        config:
          unseal:
            static:
              currentKeyId: gl-unseal-2
              currentKey: /srv/openbao/keys/gl-unseal-2
              previousKeyId: gl-unseal-1
              previousKey: ""
        ))
      end

      it 'errors that previousKey is required when previousKeyId is set' do
        expect(template.exit_code).not_to eq(0)
        expect(template.stderr).to include('config.unseal.static.previousKey is required when previousKeyId is set')
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
