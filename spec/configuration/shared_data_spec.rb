require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Shared Data ConfigMap configuration' do
  let(:default_values) do
    HelmTemplate.defaults
  end

  it 'includes standard labels, metadata, and default values' do
    t = HelmTemplate.new(default_values)
    expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

    labels = t.labels('ConfigMap/test-shared-data')
    expect(labels).to include('app' => 'gitlab')
    expect(labels).to include('chart')
    expect(labels).to include('release' => 'test')

    metadata = t.dig('ConfigMap/test-shared-data', 'metadata')
    expect(metadata['name']).to eq('test-shared-data')
    expect(metadata['namespace']).to eq('default')

    configmap_data = t.dig('ConfigMap/test-shared-data', 'data')
    expect(configmap_data).not_to be_nil
    expect(configmap_data['POSTGRESQL_SUBCHART_ENABLED']).to eq('true')
  end

  describe 'non-default data' do
    describe 'POSTGRESQL_SUBCHART_ENABLED' do
      context 'when PostgreSQL subchart is disabled via postgresql.install=false' do
        let(:values) do
          HelmTemplate.with_defaults(%(
            postgresql:
              install: false
          ))
        end

        it 'sets POSTGRESQL_SUBCHART_ENABLED to "false"' do
          t = HelmTemplate.new(values)
          expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"

          configmap_data = t.dig('ConfigMap/test-shared-data', 'data')
          expect(configmap_data['POSTGRESQL_SUBCHART_ENABLED']).to eq('false')
        end
      end
    end
  end
end
