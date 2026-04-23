# frozen_string_literal: true

require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'openbao config check' do
  describe 'when openbao.install is true' do
    context 'when global.openbao.psql is configured' do
      let(:success_values) do
        YAML.safe_load(%(
          openbao:
            install: true
          global:
            openbao:
              psql:
                host: gitlab-checkconfig-test-postgresql.default.svc
                username: gitlab
                password:
                  secret: openbao-db-password
                  key: password
        )).deep_merge!(default_required_values)
      end

      let(:values) { success_values }

      include_context 'check config setup'

      it 'succeeds', :aggregate_failures do
        expect(exit_code).to eq(0)
        expect(stdout).to include('name: gitlab-checkconfig-test')
        expect(stderr).to be_empty
      end
    end

    context 'when global.openbao.psql and openbao.config.storage.postgresql.connection are both configured' do
      let(:success_values) do
        YAML.safe_load(%(
          openbao:
            install: true
            config:
              storage:
                postgresql:
                  connection:
                    host: psql.openbao.example.com
                    database: openbao
                    username: openbao
                    password:
                      secret: openbao-db-password
                      key: password
          global:
            openbao:
              psql:
                host: global-psql.example.com
                database: openbao
                username: openbao
                password:
                  secret: openbao-db-password
                  key: password
        )).deep_merge!(default_required_values)
      end

      let(:values) { success_values }

      include_context 'check config setup'

      it 'succeeds', :aggregate_failures do
        expect(exit_code).to eq(0)
        expect(stdout).to include('name: gitlab-checkconfig-test')
        expect(stderr).to be_empty
      end
    end

    context 'when openbao.config.storage.postgresql.connection is configured' do
      let(:success_values) do
        YAML.safe_load(%(
          openbao:
            install: true
            config:
              storage:
                postgresql:
                  connection:
                    host: psql.openbao.example.com
                    database: openbao
                    username: openbao
                    password:
                      secret: openbao-db-password
                      key: password
        )).deep_merge!(default_required_values)
      end

      let(:values) { success_values }

      include_context 'check config setup'

      it 'succeeds', :aggregate_failures do
        expect(exit_code).to eq(0)
        expect(stdout).to include('name: gitlab-checkconfig-test')
        expect(stderr).to be_empty
      end
    end

    context 'when database not configured' do
      let(:error_values) do
        v = YAML.safe_load(%(
          openbao:
            install: true
        )).deep_merge!(default_required_values)

        v["global"].delete("psql")
        v
      end

      let(:error_output) { 'OpenBao is enabled but no database was configured' }

      include_examples 'config validation',
                       success_description: nil,
                       error_description: 'when no database configured'
    end

    context 'when only global.psql is configured but no dedicated OpenBao database' do
      let(:error_values) do
        YAML.safe_load(%(
          openbao:
            install: true
          global:
            psql:
              host: main-db.example.com
              password:
                secret: gitlab-db-password
                key: password
        )).deep_merge!(default_required_values)
      end

      let(:error_output) { 'OpenBao is enabled but no database was configured' }

      include_examples 'config validation',
                       success_description: nil,
                       error_description: 'when main DB is present but no dedicated OpenBao DB configured'
    end

    context 'when database is configured without a password' do
      let(:error_values) do
        v = YAML.safe_load(%(
          openbao:
            install: true
          global:
            openbao:
              psql:
                host: gitlab-checkconfig-test-postgresql.default.svc
                username: gitlab
        )).deep_merge!(default_required_values)

        v["global"]["psql"].delete('password')
        v
      end

      let(:error_output) { 'no database password configured' }

      include_examples 'config validation',
                       success_description: nil,
                       error_description: 'when database host but no password'
    end
  end
end
