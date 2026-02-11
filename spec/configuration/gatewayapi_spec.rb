# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'Gateway API configuration' do
  let(:template) { HelmTemplate.new(values) }
  let(:gatewayclass) { template["GatewayClass/gitlab-gw"] }
  let(:gateway) { template["Gateway/test-gw"] }
  let(:envoyproxy) { template["EnvoyProxy/test-envoy-proxy"] }
  let(:envoypatchpolicy) { template["EnvoyPatchPolicy/test-policy"] }
  let(:clienttrafficpolicy) { template["ClientTrafficPolicy/test-policy"] }
  let(:securitypolicy) { template["SecurityPolicy/test-policy"] }

  let(:shell_route) { template["TCPRoute/test-gitlab-shell"] }
  let(:webservice_route) { template["HTTPRoute/test-gitlab"] }
  let(:registry_route) { template["HTTPRoute/test-registry"] }
  let(:kas_route) { template["HTTPRoute/test-kas"] }
  let(:pages_route) { template["HTTPRoute/test-gitlab-pages"] }
  let(:routes) { [shell_route, webservice_route, registry_route, kas_route, pages_route] }

  describe "Gateway API is enabled" do
    let(:values) do
      HelmTemplate.with_defaults(%(
        nginx-ingress:
          enabled: false

        global:
          hosts:
            externalIP: 127.0.0.1
          pages:
            enabled: true
          gatewayApi:
            enabled: true
            installEnvoy: true
        ))
    end

    it 'renders the template' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
    end

    it 'creates all expected Gateway API objects' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

      # GatewayClass object
      expect(gatewayclass).not_to be_nil
      # Gateway object
      expect(gateway).not_to be_nil
      # Route objects
      expect(routes).not_to include(nil)
      # Optional policies
      expect(clienttrafficpolicy).to be_nil
      expect(securitypolicy).to be_nil
    end

    it 'picks up the static IP' do
      expect(gateway["spec"]["addresses"]).to eq([{ "type" => "IPAddress", "value" => "127.0.0.1" }])
    end

    describe 'with proxy protocol and IP allow/deny listing' do
      let(:values) do
        HelmTemplate.with_defaults(%(
          global:
            gatewayApi:
              envoyClientTrafficPolicySpec:
                enableProxyProtocol: true
              envoySecurityPolicySpec:
                  authorization:
                    defaultAction: Deny
                    rules:
                    - action: Allow
                      principal:
                        clientCIDRs:
                         - 10.0.1.0/24
          )).deep_merge(super())
      end

      it 'creates the policies' do
        expect(clienttrafficpolicy).not_to be_nil
        expect(clienttrafficpolicy["spec"]["targetRefs"][0]["name"]).to eq("test-gw")
        expect(clienttrafficpolicy["spec"]["targetRefs"][0]).not_to have_key("namespace")
        expect(clienttrafficpolicy["spec"]["enableProxyProtocol"]).to be(true)

        expect(securitypolicy).not_to be_nil
        expect(securitypolicy["spec"]["targetRefs"][0]["name"]).to eq("test-gw")
        expect(securitypolicy["spec"]["targetRefs"][0]).not_to have_key("namespace")
        expect(securitypolicy["spec"]["authorization"]["defaultAction"]).to eq("Deny")
      end
    end

    describe "Externally managed Gateway is configured" do
      let(:values) do
        HelmTemplate.with_defaults(%(
        nginx-ingress:
          enabled: false

        global:
          hosts:
            externalIP: 127.0.0.1
          pages:
            enabled: true
          gatewayApi:
            enabled: true
            installEnvoy: false
            gatewayRef:
              name: "external-gateway"
              namespace: "external-gateway-namespace"
        gitlab:
          gitlab-pages:
            gatewayRoute:
              gatewayName: "pages-gateway"
              gatewayNamespace: "pages-gateway-namespace"
        ))
      end

      it 'renders the template' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      end

      it 'configures the manifests for the externally managed Gateway' do
        # Creates to Gateway, GatewayClass or Envoy extensions
        expect(gatewayclass).to be_nil
        expect(gateway).to be_nil
        expect(envoyproxy).to be_nil
        expect(clienttrafficpolicy).to be_nil
        expect(securitypolicy).to be_nil

        # Route objects reference external Gateway
        expect(routes).not_to include(nil)
        routes.each do |route|
          next if route == pages_route

          expect(route["spec"]["parentRefs"][0]["name"]).to eq("external-gateway")
          expect(route["spec"]["parentRefs"][0]["namespace"]).to eq("external-gateway-namespace")
        end

        expect(pages_route["spec"]["parentRefs"][0]["name"]).to eq("pages-gateway")
        expect(pages_route["spec"]["parentRefs"][0]["namespace"]).to eq("pages-gateway-namespace")
      end
    end
  end
end
