require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig iamAuthService' do
  let(:enabled_values) do
    YAML.safe_load(%(
      global:
        appConfig:
          iamAuthService:
            enabled: true
            http:
              host: iam-auth.example.com
              port: 443
            grpc:
              host: iam-auth.example.com
              port: 5004
            jwtIssuer: https://iam-auth.example.com
    )).deep_merge!(default_required_values)
  end

  describe 'gitlab.checkConfig.iamAuthService.http.host' do
    let(:success_values) { enabled_values }

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            iamAuthService:
              enabled: true
              http:
                port: 443
              grpc:
                host: iam-auth.example.com
                port: 5004
              jwtIssuer: https://iam-auth.example.com
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'http.host is required when iamAuthService is enabled' }

    include_examples 'config validation',
                     success_description: 'when iamAuthService is enabled and http.host is set',
                     error_description: 'when iamAuthService is enabled but http.host is missing'
  end

  describe 'gitlab.checkConfig.iamAuthService.http.port' do
    let(:success_values) { enabled_values }

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            iamAuthService:
              enabled: true
              http:
                host: iam-auth.example.com
              grpc:
                host: iam-auth.example.com
                port: 5004
              jwtIssuer: https://iam-auth.example.com
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'http.port is required when iamAuthService is enabled' }

    include_examples 'config validation',
                     success_description: 'when iamAuthService is enabled and http.port is set',
                     error_description: 'when iamAuthService is enabled but http.port is missing'
  end

  describe 'gitlab.checkConfig.iamAuthService.grpc.host' do
    let(:success_values) { enabled_values }

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            iamAuthService:
              enabled: true
              http:
                host: iam-auth.example.com
                port: 443
              grpc:
                port: 5004
              jwtIssuer: https://iam-auth.example.com
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'grpc.host is required when iamAuthService is enabled' }

    include_examples 'config validation',
                     success_description: 'when iamAuthService is enabled and grpc.host is set',
                     error_description: 'when iamAuthService is enabled but grpc.host is missing'
  end

  describe 'gitlab.checkConfig.iamAuthService.grpc.port' do
    let(:success_values) { enabled_values }

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            iamAuthService:
              enabled: true
              http:
                host: iam-auth.example.com
                port: 443
              grpc:
                host: iam-auth.example.com
              jwtIssuer: https://iam-auth.example.com
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'grpc.port is required when iamAuthService is enabled' }

    include_examples 'config validation',
                     success_description: 'when iamAuthService is enabled and grpc.port is set',
                     error_description: 'when iamAuthService is enabled but grpc.port is missing'
  end

  describe 'gitlab.checkConfig.iamAuthService.jwtIssuer' do
    let(:success_values) { enabled_values }

    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            iamAuthService:
              enabled: true
              http:
                host: iam-auth.example.com
                port: 443
              grpc:
                host: iam-auth.example.com
                port: 443
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'jwtIssuer is required when iamAuthService is enabled' }

    include_examples 'config validation',
                     success_description: 'when iamAuthService is enabled and jwtIssuer is set',
                     error_description: 'when iamAuthService is enabled but jwtIssuer is missing'
  end
end
