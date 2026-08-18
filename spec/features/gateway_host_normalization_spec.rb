require 'spec_helper'
require 'net/http'

# A trailing dot in the Host/:authority header is a valid absolute FQDN
# (the dot is the DNS root; clients use it to skip resolv.conf search
# domains). NGINX normalizes it away, while Envoy matches literally and
# Gateway API hostnames cannot carry the dot, so without
# ClientTrafficPolicy headers.host.stripTrailingHostDot every request
# gets 404 route_not_found before reaching the webservice.
describe 'Gateway Host header normalization' do
  let(:uri) { URI("#{gitlab_url}/users/sign_in") }

  it 'routes requests whose Host header carries a trailing dot' do
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'

    request = Net::HTTP::Get.new(uri.request_uri)
    request['Host'] = "#{uri.host}."

    response = http.request(request)

    expect(response.code.to_i).to eq(200),
      "expected 200 for dotted Host '#{request['Host']}', got #{response.code} #{response.message}"
  end
end
