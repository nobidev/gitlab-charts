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

  context 'security context' do
    let(:pod_spec) { template.dig('Deployment/test-geo-logcursor', 'spec', 'template', 'spec') }
    let(:restricted_container_context) do
      {
        'allowPrivilegeEscalation' => false,
        'runAsNonRoot' => true,
        'capabilities' => { 'drop' => ['ALL'] }
      }
    end

    context 'with default values' do
      let(:template) { HelmTemplate.new(default_values) }

      it 'renders a restricted pod and container security context' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
        expect(pod_spec['securityContext']).to include('runAsUser' => 1000, 'seccompProfile' => { 'type' => 'RuntimeDefault' })

        pod_spec['initContainers'].each do |container|
          expect(container['securityContext']).to eq(restricted_container_context), "container #{container['name']}"
        end
        pod_spec['containers'].each do |container|
          expect(container['securityContext']).to eq(restricted_container_context.merge('runAsUser' => 1000)), "container #{container['name']}"
        end
      end
    end

    context 'with a custom pod runAsUser' do
      let(:template) do
        HelmTemplate.new(default_values.deep_merge(YAML.safe_load(%(
          gitlab:
            geo-logcursor:
              securityContext:
                runAsUser: 2000
        ))))
      end

      it 'lets the init containers inherit the pod user' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
        expect(pod_spec.dig('securityContext', 'runAsUser')).to eq(2000)

        pod_spec['initContainers'].each do |container|
          expect(container['securityContext']).not_to have_key('runAsUser'), "container #{container['name']}"
        end
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
