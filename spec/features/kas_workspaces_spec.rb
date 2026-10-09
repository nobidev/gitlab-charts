require 'spec_helper'
require 'net/http'
require 'securerandom'

# Requests the KAS workspaces server through whatever routes it in the deployment under test
# (NGINX or Traefik Ingress, Envoy Gateway, ...). Unauthenticated requests are redirected to
# GitLab's OAuth authorization endpoint, a response only the workspaces server produces.
describe 'KAS workspaces server' do
  before(:all) do
    set_admin_token
  end

  before do
    skip 'KAS is disabled' unless kas['enabled']
    skip 'WORKSPACES_HOST is not set' if workspaces_host.to_s.empty?
  end

  let(:kas) { ApiHelper.invoke_get_request('metadata').fetch('kas') }
  # The scheme and host the KAS HTTP routes are served on.
  let(:kas_url) { URI(kas.fetch('externalK8sProxyUrl')) }
  let(:workspaces_host) { ENV['WORKSPACES_HOST'] }

  it 'serves the workspaces server API on the KAS host' do
    expect_oauth_redirect(kas_url.dup.tap { |uri| uri.path = '/workspaces/' })
  end

  it 'serves workspaces on the wildcard workspaces host' do
    expect_oauth_redirect(kas_url.dup.tap do |uri|
      uri.host = "3000-#{SecureRandom.hex(4)}.#{workspaces_host}"
      uri.path = '/'
    end)
  end

  def expect_oauth_redirect(uri)
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 30, read_timeout: 30) do |http|
      http.get(uri.request_uri)
    end

    expect(response.code).to eq('307'), "expected a redirect from #{uri}, got #{response.code}"

    location = URI(response['location'])
    redirect_uri = URI(URI.decode_www_form(location.query.to_s).to_h.fetch('redirect_uri'))

    expect(location.path).to end_with('/oauth/authorize')
    expect(redirect_uri.host).to eq(kas_url.host)
    expect(redirect_uri.path).to eq('/workspaces/oauth/redirect')
  end
end
