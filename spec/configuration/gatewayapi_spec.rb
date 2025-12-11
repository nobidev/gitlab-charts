# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'Gateway API configuration' do
  let(:template) { HelmTemplate.new(values) }
  let(:gatewayclass) { template["GatewayClass/gitlab-gw"] }
  let(:gateway) { template["Gateway/test-gw"] }
  let(:clienttrafficpolicy) { template["ClientTrafficPolicy/test-policy"] }
  let(:securitypolicy) { template["SecurityPolicy/test-policy"] }

  let(:shell_route) { template["TCPRoute/test-gitlab-shell"] }
  let(:webservice_route) { template["HTTPRoute/test-gitlab"] }
  let(:registry_route) { template["HTTPRoute/test-registry"] }
  let(:kas_route) { template["HTTPRoute/test-kas"] }
  let(:pages_route) { template["HTTPRoute/test-gitlab-pages"] }

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

      # GatewayClass Object
      expect(gatewayclass).not_to be_nil
      # Gateway Object
      expect(gateway).not_to be_nil
      # Route objects
      expect(pages_route).not_to be_nil
      expect(registry_route).not_to be_nil
      expect(shell_route).not_to be_nil
      expect(kas_route).not_to be_nil
      expect(webservice_route).not_to be_nil
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
        expect(clienttrafficpolicy["spec"]["enableProxyProtocol"]).to be(true)

        expect(securitypolicy).not_to be_nil
        expect(securitypolicy["spec"]["targetRefs"][0]["name"]).to eq("test-gw")
        expect(securitypolicy["spec"]["authorization"]["defaultAction"]).to eq("Deny")
      end
    end
  end
end
