require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Expose Geo with Gateway API' do
  let(:gateway) { template["Gateway/test-gw"] }
  let(:webservice_route) { template["HTTPRoute/test-gitlab"] }
  let(:template) { HelmTemplate.new(values) }

  let(:values) do
    HelmTemplate.with_defaults(%(
      nginx-ingress:
        enabled: false
      nginx-ingress-geo:
        enabled: false

      global:
        gatewayApi:
          enabled: true
          installEnvoy: true
        psql:
          host: psq.example.com
          password:
            secret: bar
        geo:
          enabled: true
          role: primary
          gatewayApi:
            internalHostname: internal.primary.example.com
        hosts:
          domain: primary.example.com
    ))
  end

  it 'configures gateway and route for external and internal traffic' do
    expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

    expect(gateway).not_to be_nil
    expect(webservice_route).not_to be_nil

    geo_listener = gateway['spec']['listeners'].find { |l| l['name'] == 'gitlab-geo-internal' }
    expect(geo_listener).not_to be_nil
    expect(geo_listener['hostname']).to eq('internal.primary.example.com')

    expect(webservice_route['spec']['parentRefs']).to eq([
      { 'name' => 'test-gw', 'sectionName' => 'gitlab-web' },
      { 'name' => 'test-gw', 'sectionName' => 'gitlab-geo-internal' }
    ])
  end
end
