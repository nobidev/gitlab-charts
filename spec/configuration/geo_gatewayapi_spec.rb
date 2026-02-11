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
            additionalHostname: shanghai.example.com
        hosts:
          domain: london.example.com
    ))
  end

  it 'configures gateway and route for external and internal traffic' do
    expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

    expect(gateway).not_to be_nil
    expect(webservice_route).not_to be_nil

    geo_listener = gateway['spec']['listeners'].find { |l| l['name'] == 'gitlab-web-geo' }
    expect(geo_listener).not_to be_nil
    expect(geo_listener['hostname']).to eq('shanghai.example.com')

    expect(webservice_route['spec']['parentRefs'].count).to eq(2)
    expect(webservice_route['spec']['parentRefs'][0]['sectionName']).to eq('gitlab-web')
    expect(webservice_route['spec']['parentRefs'][1]['sectionName']).to eq('gitlab-web-geo')
  end
end
