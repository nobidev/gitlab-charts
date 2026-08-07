# frozen_string_literal: true

require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Orbit config check' do
  let(:success_values) do
    YAML.safe_load(%(
      global:
        appConfig:
          orbit:
            enabled: true
    )).deep_merge!(default_required_values)
  end

  let(:error_output) do
    <<~OUTPUT.chomp
      CONFIGURATION CHECKS:

      global.appConfig:
          `global.appConfig.orbit` and `global.appConfig.knowledgeGraph` cannot both be set. Move the legacy `knowledgeGraph` configuration to `orbit`.
    OUTPUT
  end

  context 'when both configuration roots are non-empty' do
    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            orbit:
              enabled: true
            knowledgeGraph:
              enabled: true
      )).deep_merge!(default_required_values)
    end

    include_examples 'config validation',
                     success_description: 'when only the canonical configuration root is set',
                     error_description: 'when both configuration roots are set'
  end

  context 'when both configuration roots are empty' do
    let(:error_values) do
      YAML.safe_load(%(
        global:
          appConfig:
            orbit: {}
            knowledgeGraph: {}
      )).deep_merge!(default_required_values)
    end

    include_examples 'config validation',
                     success_description: nil,
                     error_description: 'when both empty configuration roots are set'
  end
end
