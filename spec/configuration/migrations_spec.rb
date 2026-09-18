require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'migrations configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global: {}
      gitlab:
        migrations:
          networkpolicy:
            enabled: true
          serviceAccount:
            enabled: true
            create: true
    ))
  end

  context 'When customer provides additional labels' do
    let(:values) do
      default_values.deep_merge(YAML.safe_load(%(
        global:
          common:
            labels:
              global: global
              foo: global
          pod:
            labels:
              global_pod: true
          job:
            nameSuffixOverride: '1'
        gitlab:
          migrations:
            common:
              labels:
                global: migrations
                migrations: migrations
            podLabels:
              pod: true
              global: pod
      )))
    end
    it 'Populates the additional labels in the expected manner' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      expect(t.dig('ConfigMap/test-migrations', 'metadata', 'labels')).to include('global' => 'migrations')
      expect(t.dig('Job/test-migrations-1', 'metadata', 'labels')).to include('foo' => 'global')
      expect(t.dig('Job/test-migrations-1', 'metadata', 'labels')).to include('global' => 'migrations')
      expect(t.dig('Job/test-migrations-1', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('Job/test-migrations-1', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
      expect(t.dig('Job/test-migrations-1', 'spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
      expect(t.dig('Job/test-migrations-1', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
      expect(t.dig('ServiceAccount/test-migrations', 'metadata', 'labels')).to include('global' => 'migrations')
    end
  end

  context 'When customer provides additional annotations' do
    let(:values) do
      default_values.deep_merge(YAML.safe_load(%(
        global:
          job:
            nameSuffixOverride: '1'
        gitlab:
          migrations:
            annotations:
              foo: bar
              bar: foo
            podAnnotations:
              foo: foo
              baz: baz
      )))
    end
    it 'Populates the additional annotations in the expected manner' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      expect(t.dig('Job/test-migrations-1', 'metadata', 'annotations')).to include('foo' => 'bar')
      expect(t.dig('Job/test-migrations-1', 'metadata', 'annotations')).to include('bar' => 'foo')
      expect(t.dig('Job/test-migrations-1', 'metadata', 'annotations')).not_to include('baz' => 'baz')
      expect(t.dig('ConfigMap/test-migrations', 'metadata', 'annotations')).to include('foo' => 'bar')
      expect(t.dig('Job/test-migrations-1', 'spec', 'template', 'metadata', 'annotations')).to include('foo' => 'foo')
      expect(t.dig('Job/test-migrations-1', 'spec', 'template', 'metadata', 'annotations')).to include('bar' => 'foo')
      expect(t.dig('Job/test-migrations-1', 'spec', 'template', 'metadata', 'annotations')).to include('baz' => 'baz')
    end
  end

  context 'The shared pod-spec fragments' do
    # Guards the DRY extraction in _migrations-shared.tpl against indentation or
    # structural drift: the migrations Job must keep the init container, config
    # volume mounts, and config/secret volumes the shared helpers render.
    def migrations_job
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      jobs = t.resources_by_kind('Job').select do |key, _|
        key.start_with?('Job/test-migrations-') && !key.start_with?('Job/test-migrations-bbm-')
      end
      expect(jobs.length).to eq(1)
      jobs.values[0]
    end

    it 'renders the configure init container' do
      pod = migrations_job['spec']['template']['spec']
      expect(pod['initContainers'].map { |c| c['name'] }).to include('configure')
    end

    it 'mounts the migrations config and secrets on the main container' do
      container = migrations_job['spec']['template']['spec']['containers'].find { |c| c['name'] == 'migrations' }
      expect(container['volumeMounts'].map { |m| m['name'] }).to include('migrations-config', 'migrations-secrets')
    end

    it 'renders the config and secret volumes' do
      volumes = migrations_job['spec']['template']['spec']['volumes'].map { |v| v['name'] }
      expect(volumes).to include('migrations-config', 'init-migrations-secrets', 'migrations-secrets')
    end
  end

  context 'When customer provides no job suffix' do
    let(:kind) { "Job" }
    let(:name) { "test-migrations" }
    let(:id_prefix) { "#{kind}/#{name}-" }
    def run_template_and_get_job
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      jobs = t.resources_by_kind(kind).select { |key, _| key.start_with? id_prefix }
      expect(jobs.length).to eq(1)
      jobs.values[0]
    end
    it 'generates a stable hash per default' do
      # run template and expect the job name to end with a suffix
      job1 = run_template_and_get_job
      expect(job1['metadata']['name']).to match(/#{name}-[a-z0-9]+/)
      suffix = job1['metadata']['name'].split('-').last
      # run template again and expect the same suffix
      job2 = run_template_and_get_job
      expect(job2['metadata']['name']).to match(/#{name}-#{suffix}/)
    end
  end
end
