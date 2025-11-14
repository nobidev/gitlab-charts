# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'Gateway API configuration' do
  let(:template) { HelmTemplate.new(values) }
  let(:gatewayclass) { template["GatewayClass/gitlab-gw"] }
  let(:gateway) { template["Gateway/test-gw"] }

  let(:shell_route) { template["TCPRoute/test-gitlab-shell"] }
  let(:webservice_route) { template["HTTPRoute/test-gitlab"] }
  let(:registry_route) { template["HTTPRoute/test-registry"] }
  let(:kas_route) { template["HTTPRoute/test-kas"] }
  let(:pages_route) { template["HTTPRoute/test-gitlab-pages"] }

  describe "Gateway API is enabled" do
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
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

    it 'creates Gateway and GatewayClass' do
      expect(gatewayclass).not_to be_nil
      expect(gateway).not_to be_nil
    end

    it 'creates the routes' do
      expect(pages_route).not_to be_nil
      expect(registry_route).not_to be_nil
      expect(shell_route).not_to be_nil
      expect(kas_route).not_to be_nil
      expect(webservice_route).not_to be_nil
    end
  end
end
