require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'geo-logcursor configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global:
        geo:
          enabled: true
          role: secondary
          psql:
            host: localhost
            password:
              secret: foobar
        hosts:
          domain: example.com
        psql:
          host: localhost
          password:
            secret: foobar
        serviceAccount:
          create: true
          enabled: true
      postgres:
        install: false
    ))
  end

  context 'security context defaults' do
    let(:template) { HelmTemplate.new(default_values) }
    let(:pod_spec) { template.dig('Deployment/test-geo-logcursor', 'spec', 'template', 'spec') }
    let(:restricted_container_context) do
      {
        'runAsUser' => 1000,
        'allowPrivilegeEscalation' => false,
        'runAsNonRoot' => true,
        'capabilities' => { 'drop' => ['ALL'] }
      }
    end

    it 'sets the RuntimeDefault seccomp profile on the pod' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(pod_spec.dig('securityContext', 'seccompProfile')).to eq({ 'type' => 'RuntimeDefault' })
    end

    it 'sets a restricted security context on all containers' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      containers = pod_spec['initContainers'] + pod_spec['containers']
      containers.each do |container|
        expect(container['securityContext']).to eq(restricted_container_context), "container #{container['name']}"
      end
    end
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
        gitlab:
          geo-logcursor:
            common:
              labels:
                global: geo-logcursor
                geo-logcursor: geo-logcursor
            podLabels:
              pod: true
              global: pod
      )))
    end
    it 'Populates the additional labels in the expected manner' do
      t = HelmTemplate.new(values)
      expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
      expect(t.dig('ConfigMap/test-geo-logcursor', 'metadata', 'labels')).to include('global' => 'geo-logcursor')
      expect(t.dig('Deployment/test-geo-logcursor', 'metadata', 'labels')).to include('foo' => 'global')
      expect(t.dig('Deployment/test-geo-logcursor', 'metadata', 'labels')).to include('global' => 'geo-logcursor')
      expect(t.dig('Deployment/test-geo-logcursor', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('Deployment/test-geo-logcursor', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
      expect(t.dig('Deployment/test-geo-logcursor', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
      expect(t.dig('Deployment/test-geo-logcursor', 'spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
      expect(t.dig('ServiceAccount/test-geo-logcursor', 'metadata', 'labels')).to include('global' => 'geo-logcursor')
    end
  end
end
