require 'spec_helper'
require 'check_config_helper'
require 'hash_deep_merge'

describe 'checkConfig toolbox' do
  describe 'gitaly.toolbox.replicas' do
    let(:success_values) do
      YAML.safe_load(%(
        gitlab:
          toolbox:
            replicas: 1
            persistence:
              enabled: true
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        gitlab:
          toolbox:
            replicas: 2
            persistence:
              enabled: true
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'more than 1 replica, but also with a PersistentVolumeClaim' }

    include_examples 'config validation',
                     success_description: 'when toolbox has persistence enabled and one replica',
                     error_description: 'when toolbox has persistence enabled and more than one replica'
  end
end
