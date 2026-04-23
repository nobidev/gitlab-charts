require 'spec_helper'
require 'check_config_helper'
require 'hash_deep_merge'

describe 'checkConfig workhorse' do
  describe 'monitoring TLS' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          workhorse:
            tls:
              enabled: true
        gitlab:
          webservice:
            workhorse:
              monitoring:
                exporter:
                  tls:
                    enabled: true
        )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          workhorse:
            tls:
              enabled: false
        gitlab:
          webservice:
            workhorse:
              monitoring:
                exporter:
                  tls:
                    enabled: true
        )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'The monitoring exporter TLS depends on the main workhorse listener using TLS.' }

    include_examples 'config validation',
                     success_description: 'when main and exporter TLS is enabled',
                     error_description: 'when main TLS is not enabled but exporter TLS is'
  end

  describe 'Redis TLS certificates' do
    describe 'no TLS configured' do
      let(:success_values) do
        YAML.safe_load(%(
          global:
            redis:
              host: redis.example.com
        )).deep_merge!(default_required_values)
      end

      include_examples 'config validation',
                       success_description: 'when no redisTLS or sentinelTLS is configured'
    end

    describe 'redisTLS certificate validation' do
      let(:success_values) do
        YAML.safe_load(%(
          global:
            redis:
              host: redis.example.com
              redisTLS:
                cert:
                  secret: redis-cert
                  key: cert
                key:
                  secret: redis-key
                  key: key
                caFile:
                  secret: redis-ca
                  key: ca.crt
        )).deep_merge!(default_required_values)
      end

      let(:error_values) do
        YAML.safe_load(%(
          global:
            redis:
              host: redis.example.com
              redisTLS:
                cert:
                  secret: redis-cert
        )).deep_merge!(default_required_values)
      end

      let(:error_output) { 'Certificate configuration must have both \'secret\' and \'key\' fields.' }

      include_examples 'config validation',
                       success_description: 'when redisTLS cert references have both secret and key sub-fields',
                       error_description: 'when a redisTLS cert reference is missing the key sub-field'
    end

    describe 'sentinelTLS certificate validation' do
      let(:success_values) do
        YAML.safe_load(%(
          global:
            redis:
              host: redis.example.com
              sentinels:
                - host: sentinel1.example.com
                  port: 26379
              sentinelTLS:
                enabled: true
                cert:
                  secret: sentinel-cert
                  key: cert
                key:
                  secret: sentinel-key
                  key: key
                caFile:
                  secret: sentinel-ca
                  key: ca.crt
        )).deep_merge!(default_required_values)
      end

      let(:error_values) do
        YAML.safe_load(%(
          global:
            redis:
              host: redis.example.com
              sentinels:
                - host: sentinel1.example.com
                  port: 26379
              sentinelTLS:
                enabled: true
                caFile:
                  secret: sentinel-ca
        )).deep_merge!(default_required_values)
      end

      let(:error_output) { 'Certificate configuration must have both \'secret\' and \'key\' fields.' }

      include_examples 'config validation',
                       success_description: 'when sentinelTLS cert references have both secret and key sub-fields',
                       error_description: 'when a sentinelTLS cert reference is missing the key sub-field'
    end

    describe 'per-instance Redis TLS validation' do
      let(:success_values) do
        YAML.safe_load(%(
          global:
            redis:
              host: redis.example.com
              cache:
                redisTLS:
                  cert:
                    secret: cache-cert
                    key: cert
                  key:
                    secret: cache-key
                    key: key
        )).deep_merge!(default_required_values)
      end

      let(:error_values) do
        YAML.safe_load(%(
          global:
            redis:
              host: redis.example.com
              cache:
                redisTLS:
                  cert:
                    secret: cache-cert
                  key:
                    secret: cache-key
        )).deep_merge!(default_required_values)
      end

      let(:error_output) { 'Certificate configuration must have both \'secret\' and \'key\' fields.' }

      include_examples 'config validation',
                       success_description: 'when per-instance redisTLS cert references have both secret and key sub-fields',
                       error_description: 'when a per-instance redisTLS cert reference is missing the key sub-field'
    end
  end
end
