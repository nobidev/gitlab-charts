# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'AI Gateway external access configuration' do
  let(:default_values) { HelmTemplate.defaults }

  let(:aigw_hostname) { 'aigw.example.com' }

  let(:base_aigw_values) do
    YAML.safe_load(%(
      ai-gateway:
        install: true
        host:
          name: #{aigw_hostname}
        externalAccess:
          enabled: true
    ))
  end

  describe 'templates/ai-gateway-httproute.yaml' do
    let(:httproute_name) { 'HTTPRoute/test-ai-gateway' }

    context 'when externalAccess is disabled (default)' do
      it 'does not render the HTTPRoute' do
        values = default_values.deep_merge(YAML.safe_load(%(
          global:
            gatewayApi:
              enabled: true
          ai-gateway:
            install: true
            externalAccess:
              enabled: false
        )))
        template = HelmTemplate.new(values)
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
        expect(template.resources_by_kind('HTTPRoute')[httproute_name]).to be_nil
      end
    end

    context 'when gatewayApi is disabled' do
      it 'does not render the HTTPRoute' do
        values = default_values.deep_merge(base_aigw_values).deep_merge(YAML.safe_load(%(
          global:
            gatewayApi:
              enabled: false
        )))
        template = HelmTemplate.new(values)
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
        expect(template.resources_by_kind('HTTPRoute')[httproute_name]).to be_nil
      end
    end

    context 'when externalAccess and gatewayApi are both enabled' do
      let(:values) do
        default_values.deep_merge(base_aigw_values).deep_merge(YAML.safe_load(%(
          global:
            gatewayApi:
              enabled: true
        )))
      end

      let(:template) { HelmTemplate.new(values) }

      it 'renders the HTTPRoute successfully' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
        expect(template.resources_by_kind('HTTPRoute')[httproute_name]).not_to be_nil
      end

      it 'sets the correct hostname' do
        route = template.resources_by_kind('HTTPRoute')[httproute_name]
        expect(route['spec']['hostnames']).to eq([aigw_hostname])
      end

      it 'routes to the ai-gateway service on port 443' do
        route = template.resources_by_kind('HTTPRoute')[httproute_name]
        backend = route.dig('spec', 'rules', 0, 'backendRefs', 0)
        expect(backend['name']).to eq('test-ai-gateway')
        expect(backend['port']).to eq(443)
      end

      it 'sets request timeout to 0s for long-lived gRPC connections' do
        route = template.resources_by_kind('HTTPRoute')[httproute_name]
        timeouts = route.dig('spec', 'rules', 0, 'timeouts')
        expect(timeouts['request']).to eq('0s')
      end
    end

    context 'when ai-gateway.host.name is empty and externalAccess is enabled' do
      it 'fails with a clear error message' do
        values = default_values.deep_merge(YAML.safe_load(%(
          global:
            gatewayApi:
              enabled: true
          ai-gateway:
            install: true
            host:
              name: ""
            externalAccess:
              enabled: true
        )))
        template = HelmTemplate.new(values)
        expect(template.exit_code).not_to eq(0)
        expect(template.stderr).to include('ai-gateway.host.name must be set when ai-gateway.externalAccess.enabled is true')
      end
    end
  end

  describe 'templates/ai-gateway-ingress.yaml' do
    let(:ingress_name) { 'Ingress/test-ai-gateway' }

    context 'when externalAccess is disabled (default)' do
      it 'does not render the Ingress' do
        values = default_values.deep_merge(YAML.safe_load(%(
          global:
            ingress:
              enabled: true
          ai-gateway:
            install: true
            externalAccess:
              enabled: false
        )))
        template = HelmTemplate.new(values)
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
        expect(template.resources_by_kind('Ingress')[ingress_name]).to be_nil
      end
    end

    context 'when global.ingress.enabled is false' do
      it 'does not render the Ingress' do
        values = default_values.deep_merge(base_aigw_values).deep_merge(YAML.safe_load(%(
          global:
            ingress:
              enabled: false
        )))
        template = HelmTemplate.new(values)
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
        expect(template.resources_by_kind('Ingress')[ingress_name]).to be_nil
      end
    end

    context 'when externalAccess and global.ingress are both enabled' do
      let(:values) do
        default_values.deep_merge(base_aigw_values).deep_merge(YAML.safe_load(%(
          global:
            ingress:
              enabled: true
        )))
      end

      let(:template) { HelmTemplate.new(values) }

      it 'renders the Ingress successfully' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
        expect(template.resources_by_kind('Ingress')[ingress_name]).not_to be_nil
      end

      it 'sets the correct hostname in the rules' do
        ingress = template.resources_by_kind('Ingress')[ingress_name]
        expect(ingress.dig('spec', 'rules', 0, 'host')).to eq(aigw_hostname)
      end

      it 'routes to the ai-gateway service on port 443' do
        ingress = template.resources_by_kind('Ingress')[ingress_name]
        backend = ingress.dig('spec', 'rules', 0, 'http', 'paths', 0, 'backend')
        service_name = backend.dig('service', 'name') || backend['serviceName']
        service_port = backend.dig('service', 'port', 'number') || backend['servicePort']
        expect(service_name).to eq('test-ai-gateway')
        expect(service_port).to eq(443)
      end

      it 'includes gRPC-compatible nginx annotations when provider is nginx' do
        values_with_nginx = values.deep_merge(YAML.safe_load(%(
          global:
            ingress:
              provider: nginx
        )))
        t = HelmTemplate.new(values_with_nginx)
        expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
        annotations = t.dig(ingress_name, 'metadata', 'annotations')
        expect(annotations['nginx.ingress.kubernetes.io/backend-protocol']).to eq('GRPC')
        expect(annotations['nginx.ingress.kubernetes.io/proxy-buffering']).to eq('off')
      end
    end

    context 'when ai-gateway.host.name is empty and externalAccess is enabled' do
      it 'fails with a clear error message' do
        values = default_values.deep_merge(YAML.safe_load(%(
          global:
            ingress:
              enabled: true
          ai-gateway:
            install: true
            host:
              name: ""
            externalAccess:
              enabled: true
        )))
        template = HelmTemplate.new(values)
        expect(template.exit_code).not_to eq(0)
        expect(template.stderr).to include('ai-gateway.host.name must be set when ai-gateway.externalAccess.enabled is true')
      end
    end

    describe 'TLS secret resolution' do
      let(:base_values) do
        default_values.deep_merge(base_aigw_values).deep_merge(YAML.safe_load(%(
          global:
            ingress:
              enabled: true
              tls:
                enabled: true
        )))
      end

      context 'when global.ingress.configureCertmanager is true' do
        it 'uses the cert-manager generated secret name' do
          values = base_values.deep_merge(YAML.safe_load(%(
            global:
              ingress:
                configureCertmanager: true
          )))
          template = HelmTemplate.new(values)
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          ingress = template.resources_by_kind('Ingress')[ingress_name]
          tls_secret = ingress.dig('spec', 'tls', 0, 'secretName')
          expect(tls_secret).to eq('test-ai-gateway-tls')
        end
      end

      context 'when a custom tls.secretName is provided' do
        it 'uses the custom secret name' do
          values = base_values.deep_merge(YAML.safe_load(%(
            ai-gateway:
              host:
                tls:
                  secretName: my-custom-aigw-tls
          )))
          template = HelmTemplate.new(values)
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          ingress = template.resources_by_kind('Ingress')[ingress_name]
          tls_secret = ingress.dig('spec', 'tls', 0, 'secretName')
          expect(tls_secret).to eq('my-custom-aigw-tls')
        end
      end

      context 'when no cert-manager and no custom secret' do
        it 'falls back to the wildcard self-signed cert name' do
          values = base_values.deep_merge(YAML.safe_load(%(
            global:
              ingress:
                configureCertmanager: false
          )))
          template = HelmTemplate.new(values)
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          ingress = template.resources_by_kind('Ingress')[ingress_name]
          tls_secret = ingress.dig('spec', 'tls', 0, 'secretName')
          expect(tls_secret).to eq('test-wildcard-tls')
        end
      end
    end
  end
end
