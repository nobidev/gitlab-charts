require 'spec_helper'
require 'fileutils'
require 'net/http'

describe 'Envoy upstream connection lifecycle', :envoy_connection_lifecycle do
  CONNECTIONS = 24
  CYCLES = 3
  IDLE_SECONDS = 5
  DRAIN_TIMEOUT = 30
  METRIC = 'envoy_cluster_upstream_cx_active'.freeze
  OVERFLOW_METRIC = 'envoy_cluster_upstream_cx_overflow'.freeze
  ARTIFACT_DIR = 'envoy-connection-lifecycle'.freeze

  def kubectl(*args)
    stdout, stderr, status = Open3.capture3('kubectl', *args)
    raise "kubectl #{args.join(' ')} failed: #{stderr}" unless status.success?

    stdout.strip
  end

  def gateway_name
    kubectl('get', 'gateway', '-n', ENV.fetch('NAMESPACE'), '-o', 'jsonpath={.items[0].metadata.name}')
  end

  def proxy_pod(gateway)
    kubectl(
      'get', 'pods', '-n', ENV.fetch('NAMESPACE'),
      '-l', "gateway.envoyproxy.io/owning-gateway-name=#{gateway}",
      '-o', 'jsonpath={.items[0].metadata.name}'
    )
  end

  def webservice_route
    kubectl(
      'get', 'httproute', '-n', ENV.fetch('NAMESPACE'), '-l', 'app=webservice',
      '-o', 'jsonpath={.items[0].metadata.name}'
    )
  end

  def with_metrics_port_forward(pod)
    stdin, stdout, stderr, wait_thread = Open3.popen3(
      'kubectl', 'port-forward', '-n', ENV.fetch('NAMESPACE'), pod, '19001:19001'
    )
    stdin.close
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30

    loop do
      raise "Envoy metrics port-forward exited: #{stderr.read}" if wait_thread.join(0)

      begin
        Net::HTTP.get(URI('http://127.0.0.1:19001/stats/prometheus'))
        break
      rescue Errno::ECONNREFUSED, Net::OpenTimeout
        raise 'Timed out waiting for the Envoy metrics port-forward' if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

        sleep 1
      end
    end

    yield
  ensure
    Process.kill('TERM', wait_thread.pid) unless wait_thread.nil? || wait_thread.join(0)
    unless wait_thread.nil? || wait_thread.join(10)
      Process.kill('KILL', wait_thread.pid)
      wait_thread.join
    end
    stdout&.close
    stderr&.close
  end

  def metrics
    Net::HTTP.get(URI('http://127.0.0.1:19001/stats/prometheus'))
  end

  def metric_value(metrics, metric, cluster = nil)
    metrics.scan(/^#{Regexp.escape(metric)}(\{[^}]*\})?\s+([0-9.eE+-]+)$/).sum do |labels, value|
      cluster.nil? || labels.to_s.include?(%(envoy_cluster_name="#{cluster}")) ? value.to_f : 0
    end
  end

  def webservice_cluster(metrics, route)
    prefix = "httproute/#{ENV.fetch('NAMESPACE')}/#{route}/"
    metrics.scan(/^#{Regexp.escape(METRIC)}(\{[^}]*\})?\s+[0-9.eE+-]+$/).each do |labels|
      match = labels.first.to_s.match(/envoy_cluster_name="([^"]+)"/)
      return match[1] if match && match[1].start_with?(prefix)
    end

    raise "Could not find an Envoy upstream cluster for HTTPRoute #{route} after the first request burst"
  end

  def write_metrics(phase, metrics)
    File.write(File.join(ARTIFACT_DIR, "envoy-metrics-#{phase}.prometheus"), metrics)
  end

  def persistent_connections
    uri = URI("http://#{ENV.fetch('GITLAB_URL')}")
    Array.new(CONNECTIONS) do
      Net::HTTP.start(uri.host, uri.port, open_timeout: 30, read_timeout: 30)
    end
  end

  def request_burst(connections)
    ready = Queue.new
    release = Queue.new
    errors = Queue.new
    threads = connections.map do |connection|
      Thread.new do
        ready << true
        release.pop
        response = connection.get('/users/sign_in', 'Host' => ENV.fetch('GITLAB_URL'))
        errors << "GET /users/sign_in returned HTTP #{response.code}, expected 200" unless response.code == '200'
      rescue StandardError => error
        errors << error
      end
    end

    CONNECTIONS.times { ready.pop }
    CONNECTIONS.times { release << true }
    threads.each(&:join)
    raise errors.pop unless errors.empty?
  end

  def wait_for_drain(baseline, cluster)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + DRAIN_TIMEOUT
    loop do
      snapshot = metrics
      write_metrics('drain', snapshot)
      current = metric_value(snapshot, METRIC, cluster)
      return if current <= baseline

      raise "Upstream connections did not drain to baseline #{baseline}" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

      sleep 2
    end
  end

  it 'drains webservice upstream connections after bursts and idle periods' do
    FileUtils.mkdir_p(ARTIFACT_DIR)
    gateway = gateway_name
    pod = proxy_pod(gateway)
    route = webservice_route
    puts "Gateway: #{gateway}; Envoy proxy pod: #{pod}; webservice HTTPRoute: #{route}"

    cluster = nil
    baseline = 0
    connections = []
    with_metrics_port_forward(pod) do
      snapshot = metrics
      write_metrics('baseline', snapshot)
      connections = persistent_connections

      (1..CYCLES).each do |cycle|
        request_burst(connections)
        snapshot = metrics
        write_metrics("cycle-#{cycle}", snapshot)
        cluster ||= webservice_cluster(snapshot, route)
        current = metric_value(snapshot, METRIC, cluster)
        expect(current).to be > baseline,
          "Cycle #{cycle}: active upstream connections rose to #{current}, expected more than baseline #{baseline}"

        sleep IDLE_SECONDS
        snapshot = metrics
        write_metrics("cycle-#{cycle}-idle", snapshot)
        idle = metric_value(snapshot, METRIC, cluster)
        expect(idle).to be > baseline,
          "Cycle #{cycle}: upstream connections returned to #{idle} during the idle period"
      end
    ensure
      connections.each(&:finish)
    end

    with_metrics_port_forward(pod) do
      wait_for_drain(baseline, cluster)
      snapshot = metrics
      write_metrics('final', snapshot)
      overflow = metric_value(snapshot, OVERFLOW_METRIC, cluster)
      expect(overflow).to eq(0), "Envoy rejected #{overflow} webservice upstream connections"
    end
  end
end
