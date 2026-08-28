require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig iamDataAccessService' do
  describe 'gitlab.checkConfig.iamDataAccessService.grpc.secure' do
    def values_with_secure(secure)
      YAML.safe_load(%(
        global:
          appConfig:
            iamDataAccessService:
              enabled: true
              grpc:
                host: iam-data-access.example.com
                port: 5005
                secure: #{secure}
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'grpc.secure must be a boolean' }

    context 'with a boolean' do
      let(:success_values) { values_with_secure('false') }

      include_examples 'config validation',
                       success_description: 'when iamDataAccessService is enabled and grpc.secure is a boolean'
    end

    context 'with a quoted string' do
      let(:error_values) { values_with_secure('"false"') }

      include_examples 'config validation',
                       error_description: 'when iamDataAccessService is enabled and grpc.secure is a string'
    end

    context 'with an integer' do
      let(:error_values) { values_with_secure('0') }

      include_examples 'config validation',
                       error_description: 'when iamDataAccessService is enabled and grpc.secure is an integer'
    end

    context 'with no value' do
      let(:error_values) { values_with_secure('') }

      include_examples 'config validation',
                       error_description: 'when iamDataAccessService is enabled and grpc.secure is empty'
    end
  end
end
