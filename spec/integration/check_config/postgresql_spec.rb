require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig postgresql' do
  describe 'database' do
    let(:success_values) { default_required_values }

    let(:error_values) do
      v = default_required_values.clone
      v["global"].delete("psql")
      v
    end

    let(:error_output) { 'You must configure an PostgreSQL connetion.' }

    include_examples 'config validation',
                     success_description: 'when PostgreSQL is configured globally',
                     error_description: 'when PostgreSQL is not configured globally'
  end

  describe 'database with decomposed main' do
    let(:success_values) do
      v = default_required_values.clone
      v["global"]["psql"] = {
        "main" => {
          "host" => "psql-main.example.com",
          "password" => { "secret" => "psql-secret", "key" => "password" }
        }
      }
      v
    end

    include_examples 'config validation',
                     success_description: 'when only `global.psql.main` host and password are configured'
  end

  describe 'database.externaLoadBalancing' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          psql:
            host: primary
            password:
              secret: bar
            load_balancing:
              hosts: [a, b, c]
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          psql:
            host: primary
            password:
              secret: bar
            load_balancing:
              invalid: item
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'You must specify `load_balancing.hosts` or `load_balancing.discover`' }

    include_examples 'config validation',
                     success_description: 'when database load balancing is configured per requirements',
                     error_description: 'when database load balancing is missing required elements'

    describe 'database.externaLoadBalancing.hosts' do
      let(:success_values) do
        YAML.safe_load(%(
          global:
            psql:
              host: primary
              password:
                secret: bar
              load_balancing:
                hosts: [a, b, c]
        )).deep_merge!(default_required_values)
      end

      let(:error_values) do
        YAML.safe_load(%(
          global:
            psql:
              host: primary
              password:
                secret: bar
              load_balancing:
                hosts: a
        )).deep_merge!(default_required_values)
      end

      let(:error_output) { 'Database load balancing using `hosts` is configured, but does not appear to be a list' }

      include_examples 'config validation',
                       success_description: 'when database load balancing is configured for hosts, with an array',
                       error_description: 'when database load balancing is configured for hosts, without an array'
    end

    describe 'database.externaLoadBalancing.discover' do
      let(:success_values) do
        YAML.safe_load(%(
          global:
            psql:
              host: primary
              password:
                secret: bar
              load_balancing:
                discover:
                  record: secondary
        )).deep_merge!(default_required_values)
      end

      let(:error_values) do
        YAML.safe_load(%(
          global:
            psql:
              host: primary
              password:
                secret: bar
              load_balancing:
                discover: true
        )).deep_merge!(default_required_values)
      end

      let(:error_output) { 'Database load balancing using `discover` is configured, but does not appear to be a map' }

      include_examples 'config validation',
                       success_description: 'when database load balancing is configured for discover, with a map',
                       error_description: 'when database load balancing is configured for discover, without a map'
    end
  end
end
