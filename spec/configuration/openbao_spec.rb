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
    it 'uses the main PostgreSQL database' do
      expect(openbao_psql_config['connection_url'])
        .to start_with('postgres://gitlab@test-postgresql.default.svc:5432/gitlabhq_production')
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

  describe 'seal configuration' do
    let(:openbao_seal_config) do
      config = template.dig("ConfigMap/test-openbao-config", 'data', 'config.json')
      JSON.parse(config)['seal']
    end

    describe 'unseal method validation' do
      context 'when both static and AWS KMS are enabled' do
        let(:values) do
          HelmTemplate.with_defaults(%(
          openbao:
            install: true
            config:
              unseal:
                static:
                  enabled: true
                awskms:
                  enabled: true
                  kmsKeyId: "alias/my-openbao-key"
          ))
        end

        it 'fails to render' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).not_to eq(0)
          expect(t.stderr).to include('OpenBao: only one unseal method can be enabled at a time (static, awskms).')
        end
      end

      context 'when neither static nor awskms is enabled' do
        let(:values) do
          HelmTemplate.with_defaults(%(
          openbao:
            install: true
            config:
              unseal:
                static:
                  enabled: false
                awskms:
                  enabled: false
          ))
        end

        it 'fails to render' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).not_to eq(0)
          expect(t.stderr).to include('OpenBao: one unseal method must be enabled (static, awskms).')
        end
      end
    end

    describe 'static unsealing' do
      context 'when currentKeyId is empty' do
        let(:values) do
          HelmTemplate.with_defaults(%(
          openbao:
            install: true
            config:
              unseal:
                static:
                  enabled: true
                  currentKeyId: ""
                  currentKey: "/srv/openbao/keys/static-unseal-1"
          ))
        end

        it 'fails to render' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).not_to eq(0)
          expect(t.stderr).to include('OpenBao: config.unseal.static.currentKeyId is required when static unsealing is enabled.')
        end
      end

      context 'when currentKey is empty' do
        let(:values) do
          HelmTemplate.with_defaults(%(
          openbao:
            install: true
            config:
              unseal:
                static:
                  enabled: true
                  currentKeyId: "static-unseal-0"
                  currentKey: ""
          ))
        end

        it 'fails to render' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).not_to eq(0)
          expect(t.stderr).to include('OpenBao: config.unseal.static.currentKey is required when static unsealing is enabled.')
        end
      end

      context 'with valid configuration' do
        let(:values) do
          HelmTemplate.with_defaults(%(
          openbao:
            install: true
            config:
              unseal:
                static:
                  enabled: true
                  currentKeyId: "static-unseal-0"
                  currentKey: "/srv/openbao/keys/static-unseal-0"
          ))
        end

        it 'renders current_key_id and current_key' do
          expect(openbao_seal_config['static']).to include(
            'current_key_id' => 'static-unseal-0',
            'current_key' => 'file:///srv/openbao/keys/static-unseal-0'
          )
        end

        it 'does not render previous key fields when previousKeyId is unset' do
          expect(openbao_seal_config['static']).not_to have_key('previous_key_id')
          expect(openbao_seal_config['static']).not_to have_key('previous_key')
        end
      end

      context 'with key rotation configured' do
        let(:values) do
          HelmTemplate.with_defaults(%(
          openbao:
            install: true
            config:
              unseal:
                static:
                  enabled: true
                  currentKeyId: "static-unseal-1"
                  currentKey: "/srv/openbao/keys/static-unseal-1"
                  previousKeyId: "static-unseal-0"
                  previousKey: "/srv/openbao/keys/static-unseal-0"
          ))
        end

        it 'renders previous key fields' do
          expect(openbao_seal_config['static']).to include(
            'current_key_id' => 'static-unseal-1',
            'current_key' => 'file:///srv/openbao/keys/static-unseal-1',
            'previous_key_id' => 'static-unseal-0',
            'previous_key' => 'file:///srv/openbao/keys/static-unseal-0'
          )
        end
      end
    end

    describe 'AWS KMS unsealing' do
      let(:values) do
        HelmTemplate.with_defaults(%(
        openbao:
          install: true
          config:
            unseal:
              static:
                enabled: false
              awskms:
                enabled: true
                kmsKeyId: "alias/my-openbao-key"
                region: "us-east-1"
        ))
      end

      context 'when kmsKeyId is empty' do
        let(:values) do
          HelmTemplate.with_defaults(%(
          openbao:
            install: true
            config:
              unseal:
                static:
                  enabled: false
                awskms:
                  enabled: true
                  kmsKeyId: ""
          ))
        end

        it 'fails to render' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).not_to eq(0)
          expect(t.stderr).to include('OpenBao: config.unseal.awskms.kmsKeyId is required when AWS KMS unsealing is enabled.')
        end
      end

      context 'with valid configuration' do
        it 'renders kms_key_id and region' do
          expect(openbao_seal_config['awskms']).to include(
            'kms_key_id' => 'alias/my-openbao-key',
            'region' => 'us-east-1'
          )
        end

        it 'does not render a static seal config' do
          expect(openbao_seal_config).not_to have_key('static')
        end
      end

      context 'with endpoint configured' do
        let(:values) do
          HelmTemplate.with_defaults(%(
          openbao:
            install: true
            config:
              unseal:
                static:
                  enabled: false
                awskms:
                  enabled: true
                  kmsKeyId: "alias/my-openbao-key"
                  region: "us-east-1"
                  endpoint: "https://kms.us-east-1.amazonaws.com"
          ))
        end

        it 'renders endpoint' do
          expect(openbao_seal_config['awskms']).to include(
            'kms_key_id' => 'alias/my-openbao-key',
            'region' => 'us-east-1',
            'endpoint' => 'https://kms.us-east-1.amazonaws.com'
          )
        end
      end

      context 'without optional region and endpoint' do
        let(:values) do
          HelmTemplate.with_defaults(%(
          openbao:
            install: true
            config:
              unseal:
                static:
                  enabled: false
                awskms:
                  enabled: true
                  kmsKeyId: "alias/my-openbao-key"
          ))
        end

        it 'omits region and endpoint from the seal config' do
          expect(openbao_seal_config['awskms']).to include('kms_key_id' => 'alias/my-openbao-key')
          expect(openbao_seal_config['awskms']).not_to have_key('region')
          expect(openbao_seal_config['awskms']).not_to have_key('endpoint')
        end
      end

      context 'when region and endpoint are explicitly empty strings' do
        let(:values) do
          HelmTemplate.with_defaults(%(
          openbao:
            install: true
            config:
              unseal:
                static:
                  enabled: false
                awskms:
                  enabled: true
                  kmsKeyId: "alias/my-openbao-key"
                  region: ""
                  endpoint: ""
          ))
        end

        it 'omits region and endpoint from the seal config' do
          expect(openbao_seal_config['awskms']).not_to have_key('region')
          expect(openbao_seal_config['awskms']).not_to have_key('endpoint')
        end
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
