require 'spec_helper'
require 'net/http'
require 'open3'
require 'openssl'
require 'securerandom'
require 'base64'

# Exercises the agent endpoints that KAS advertises, through whatever routes them in the
# deployment under test (NGINX or Traefik Ingress, Envoy Gateway, ...). The assertions only rely
# on responses that KAS itself produces, so a controller answering in its place fails them.
describe 'KAS agent endpoints' do
  before(:all) do
    set_admin_token
  end

  before do
    skip 'KAS is disabled' unless kas['enabled']
  end

  let(:kas) { ApiHelper.invoke_get_request('metadata').fetch('kas') }
  let(:agent_url) { URI(kas.fetch('externalUrl')) }
  let(:tls) { %w[grpcs wss].include?(agent_url.scheme) }
  let(:host) { agent_url.hostname }
  let(:port) { agent_url.port || (tls ? 443 : 80) }

  it 'serves native gRPC on the advertised address' do
    skip "agents are pointed at #{agent_url}" unless agent_url.scheme.start_with?('grpc')

    # An unauthenticated call to a unary RPC: KAS answers with gRPC status UNAUTHENTICATED,
    # without touching any agent state.
    status_line, headers = grpc_call('/gitlab.agent.agent_registrar.rpc.AgentRegistrar/Register')
    received = describe_response(status_line, headers)

    expect(status_line).to start_with('HTTP/2 200'), "expected a gRPC response, got #{received}"
    expect(headers['content-type']).to start_with('application/grpc'), "expected a gRPC response, got #{received}"
    expect(headers['grpc-status']).to eq('16'), "expected UNAUTHENTICATED, got #{received}"
  end

  it 'serves WebSocket on the agent address' do
    # Agents installed with a wss:// address keep using WebSocket when the chart advertises grpcs://.
    key = Base64.strict_encode64(SecureRandom.random_bytes(16))
    status_line, headers, body = websocket_handshake(agent_url.path.empty? ? '/' : agent_url.path, key)
    received = describe_response(status_line, headers, body)

    expect(status_line).to start_with('HTTP/1.1 101'), "expected a WebSocket upgrade, got #{received}"
    expect(headers['sec-websocket-accept']).to eq(websocket_accept(key)), "expected a valid Sec-WebSocket-Accept, got #{received}"
  end

  it 'serves the Kubernetes API proxy' do
    uri = URI("#{kas.fetch('externalK8sProxyUrl').chomp('/')}/api")
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 30, read_timeout: 30) do |http|
      http.get(uri.request_uri)
    end

    received = describe_response("HTTP/#{response.http_version} #{response.code} #{response.message}", response.to_hash, response.body)

    expect(response.code).to eq('401'), "expected 401 from KAS, got #{received}"
    expect(response['gitlab-unauthorized']).to eq('true'), "expected the Gitlab-Unauthorized header from KAS, got #{received}"
  end

  def grpc_call(path)
    url = "#{tls ? 'https' : 'http'}://#{agent_url.host}:#{port}#{path}"
    cmd = %W[
      curl --silent --show-error --max-time 30 #{tls ? '--http2' : '--http2-prior-knowledge'}
      --dump-header - --output /dev/null
      --header content-type:application/grpc --header te:trailers
      --data-binary @- #{url}
    ]
    # An empty request message: no compression flag, zero length.
    stdout, stderr, status = Open3.capture3(*cmd, stdin_data: "\0\0\0\0\0", binmode: true)
    raise "gRPC request to #{url} failed: #{stderr}" unless status.success?

    parse_head(stdout)
  end

  def websocket_handshake(path, key)
    socket = nil
    response = +''

    # Covers the TLS handshake too, which a stalled server could otherwise block forever.
    Timeout.timeout(30) do
      socket = Socket.tcp(host, port)
      socket = start_tls(socket) if tls
      socket.write([
        "GET #{path} HTTP/1.1",
        "Host: #{agent_url.host}",
        'Connection: Upgrade',
        'Upgrade: websocket',
        'Sec-WebSocket-Version: 13',
        "Sec-WebSocket-Key: #{key}",
        '', ''
      ].join("\r\n"))

      response << socket.readpartial(4096) until response.include?("\r\n\r\n")
    end

    head, body = response.split("\r\n\r\n", 2)
    [*parse_head(head), body]
  ensure
    socket&.close
  end

  def start_tls(socket)
    context = OpenSSL::SSL::SSLContext.new
    context.set_params(verify_mode: OpenSSL::SSL::VERIFY_PEER)

    OpenSSL::SSL::SSLSocket.new(socket, context).tap do |ssl|
      ssl.hostname = host
      ssl.sync_close = true
      ssl.connect
    end
  end

  def websocket_accept(key)
    # RFC 6455 defines the accept value as a SHA-1 digest.
    Base64.strict_encode64(OpenSSL::Digest.digest('SHA1', "#{key}258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
  end

  # Describes a response for failure messages, so that an answer from the controller in front of
  # KAS can be told apart from one by KAS itself.
  def describe_response(status_line, headers, body = nil)
    description = "#{status_line.inspect} with headers #{headers.inspect}"
    description += " and body #{body[0, 512].inspect}" unless body.to_s.empty?
    description
  end

  # Returns the status line and the headers, with downcased names, of a raw HTTP response head.
  def parse_head(head)
    status_line, *lines = head.split(/\r?\n/).reject(&:empty?)
    headers = lines.to_h do |line|
      name, value = line.split(':', 2)
      [name.strip.downcase, value.to_s.strip]
    end

    [status_line, headers]
  end
end
