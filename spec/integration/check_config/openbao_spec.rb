# frozen_string_literal: true

require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig openbao' do
  describe 'openbao.database' do
    context 'when OpenBao is enabled with in-chart PostgreSQL' do
      let(:success_values) do
        YAML.safe_load(%(
          openbao:
            install: true
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

    context 'when OpenBao is enabled with external PostgreSQL and explicit database config' do
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
          postgresql:
            install: false
          global:
            psql:
              host: gitlab-db.example.com
              password:
                secret: gitlab-db-password
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

    context 'when OpenBao is enabled with external PostgreSQL but no database configured' do
      let(:error_values) do
        YAML.safe_load(%(
          openbao:
            install: true
          postgresql:
            install: false
          global:
            psql:
              host: gitlab-db.example.com
              password:
                secret: gitlab-db-password
        )).deep_merge!(default_required_values)
      end

      let(:error_output) { 'OpenBao is enabled but no database was configured' }

      include_examples 'config validation',
                       success_description: nil,
                       error_description: 'when OpenBao is enabled with external PostgreSQL but no database configured'
    end
  end
end
