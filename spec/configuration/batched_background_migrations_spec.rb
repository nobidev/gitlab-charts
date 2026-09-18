require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'batched background migrations wait Job' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global: {}
    ))
  end

  let(:bbm_job) do
    t = HelmTemplate.new(values)
    expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
    jobs = t.resources_by_kind('Job').select { |key, _| key.start_with?('Job/test-migrations-bbm-') }
    [t, jobs]
  end

  context 'when migrations.batchedBackgroundMigrationsCheck.enabled is false (default)' do
    let(:values) { default_values }

    it 'does not render the wait Job' do
      _t, jobs = bbm_job
      expect(jobs).to be_empty
    end
  end

  context 'when migrations.batchedBackgroundMigrationsCheck.enabled is true' do
    let(:values) do
      default_values.deep_merge(YAML.safe_load(%(
        gitlab:
          migrations:
            batchedBackgroundMigrationsCheck:
              enabled: true
      )))
    end

    it 'renders exactly one wait Job' do
      _t, jobs = bbm_job
      expect(jobs.length).to eq(1)
    end

    it 'carries the distinguishing label the Operator selects on, plus the migrations app and target-version labels' do
      _t, jobs = bbm_job
      job = jobs.values[0]
      labels = job['metadata']['labels']
      expect(labels).to include('gitlab.com/batched-background-migrations-check' => 'true')
      expect(labels).to include('app' => 'migrations')
      expect(labels).to have_key('gitlab.com/target-version')
      pod_labels = job['spec']['template']['metadata']['labels']
      expect(pod_labels).to include('gitlab.com/batched-background-migrations-check' => 'true')
    end

    it 'runs the toolbox wait-for-batched-background-migrations script' do
      _t, jobs = bbm_job
      container = jobs.values[0]['spec']['template']['spec']['containers'].find { |c| c['name'] == 'migrations' }
      expect(container).not_to be_nil
      expect(container['args'].join("\n")).to include('/scripts/wait-for-batched-background-migrations')
    end

    it 'does not bypass the schema version, since it only reads migration counts' do
      _t, jobs = bbm_job
      container = jobs.values[0]['spec']['template']['spec']['containers'].find { |c| c['name'] == 'migrations' }
      env_names = (container['env'] || []).map { |e| e['name'] }
      expect(env_names).not_to include('BYPASS_SCHEMA_VERSION')
    end

    it 'is not rendered when the migrations component itself is disabled' do
      disabled = values.deep_merge(YAML.safe_load(%(
        gitlab:
          migrations:
            enabled: false
      )))
      t = HelmTemplate.new(disabled)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      jobs = t.resources_by_kind('Job').select { |key, _| key.start_with?('Job/test-migrations-bbm-') }
      expect(jobs).to be_empty
    end
  end
end
