require 'spec_helper'
require 'helm_template_helper'
require 'runtime_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'gitlab-shell configuration' do
  let(:t) { HelmTemplate.new(values) }
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global: {}
      gitlab:
        gitlab-shell:
          networkpolicy:
            enabled: true
          serviceAccount:
            enabled: true
            create: true
    ))
  end

  def expect_successful_exit_code
    expect(t.exit_code).to eq(0), "Unexpected error code #{t.exit_code} -- #{t.stderr}"
  end

  context 'when service.type is LoadBalancer' do
    let(:values) do
      default_values.deep_merge(YAML.safe_load(%(
        gitlab:
          gitlab-shell:
            service:
              type: LoadBalancer
      )))
    end

    it 'renders the type' do
      expect_successful_exit_code

      expect(t.dig('Service/test-gitlab-shell', 'spec', 'type')).to eq('LoadBalancer')
      expect(t.dig('Service/test-gitlab-shell', 'spec').keys).to_not include('allocateLoadBalancerNodePorts')
    end

    context 'when allocateLoadBalancerNodePorts is set' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
        gitlab:
          gitlab-shell:
            service:
              type: LoadBalancer
              allocateLoadBalancerNodePorts: false
        )))
      end

      it 'renders allocateLoadBalancerNodePorts' do
        expect_successful_exit_code

        expect(t.dig('Service/test-gitlab-shell', 'spec', 'type')).to eq('LoadBalancer')
        expect(t.dig('Service/test-gitlab-shell', 'spec', 'allocateLoadBalancerNodePorts')).to be(false)
      end
    end
  end

  context 'when the traefik ingress provider is enabled' do
    let(:traefik_values) do
      default_values.deep_merge(YAML.safe_load(%(
        global:
          ingress:
            provider: traefik
      )))
    end

    let(:route_spec) { t.dig('IngressRouteTCP/test-gitlab-shell', 'spec') }

    context 'with default values' do
      let(:values) { traefik_values }

      # With no class configured the field is omitted rather than rendered empty.
      # A default Traefik install leaves providers.kubernetescrd.ingressClass
      # empty, so a classless route is processed; rendering an empty string would
      # instead be dropped by a scoped provider.
      it 'omits ingressClassName' do
        expect_successful_exit_code

        expect(route_spec).not_to have_key('ingressClassName')
      end
    end

    context 'when global.ingress.class is set' do
      let(:values) do
        traefik_values.deep_merge(YAML.safe_load(%(
          global:
            ingress:
              class: global-class
        )))
      end

      it 'inherits the global ingress class' do
        expect_successful_exit_code

        expect(route_spec['ingressClassName']).to eq('global-class')
      end
    end

    context 'when gitlab-shell.traefik.ingressClassName is set' do
      let(:values) do
        traefik_values.deep_merge(YAML.safe_load(%(
          global:
            ingress:
              class: global-class
          gitlab:
            gitlab-shell:
              traefik:
                ingressClassName: shell-class
        )))
      end

      it 'prefers the gitlab-shell specific class over the global default' do
        expect_successful_exit_code

        expect(route_spec['ingressClassName']).to eq('shell-class')
      end
    end
  end

  context 'when gitlab-sshd is enabled' do
    using RSpec::Parameterized::TableSyntax

    let(:proxy_protocol) { true }
    let(:proxy_policy) { "require" }
    let(:proxy_header_timeout) { "1s" }
    let(:grace_period) { 30 }
    let(:client_alive_interval) { 15 }
    let(:login_grace_time) { 60 }

    let(:values) do
      default_values.deep_merge(YAML.safe_load(%(
        gitlab:
          gitlab-shell:
            sshDaemon: "gitlab-sshd"
            deployment:
              terminationGracePeriodSeconds: #{grace_period}
            config:
              clientAliveInterval: #{client_alive_interval}
              proxyProtocol: #{proxy_protocol}
              proxyPolicy: #{proxy_policy}
              proxyHeaderTimeout: #{proxy_header_timeout}
              loginGraceTime: #{login_grace_time}
      )))
    end

    let(:config) { t.dig('ConfigMap/test-gitlab-shell', 'data', 'config.yml.tpl') }

    let(:rendered_config) do
      rendered = RuntimeTemplate.gomplate(raw_template: config)
      YAML.safe_load(rendered, aliases: true)
    end

    it 'renders gitlab-sshd config' do
      expect_successful_exit_code

      expect(rendered_config['sshd']['proxy_protocol']).to eq(proxy_protocol)
      expect(rendered_config['sshd']['proxy_policy']).to eq(proxy_policy)
      expect(rendered_config['sshd']['client_alive_interval']).to eq(client_alive_interval)
      expect(rendered_config['sshd']['proxy_header_timeout']).to eq(proxy_header_timeout)
      expect(rendered_config['sshd']['login_grace_time']).to eq(login_grace_time)

      expect(rendered_config['sshd']['ciphers']).to be_empty
      expect(rendered_config['sshd']['kex_algorithms']).to be_empty
      expect(rendered_config['sshd']['macs']).to be_empty
      expect(rendered_config['sshd']['public_key_algorithms']).to be_empty
    end

    it 'sets 5 seconds smaller grace period' do
      expect(rendered_config['sshd']['grace_period']).to eq(grace_period - 5)
    end

    context 'when algorithms are configured' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          gitlab:
            gitlab-shell:
              sshDaemon: "gitlab-sshd"
              deployment:
                terminationGracePeriodSeconds: #{grace_period}
              config:
                clientAliveInterval: #{client_alive_interval}
                proxyProtocol: #{proxy_protocol}
                proxyPolicy: #{proxy_policy}
                proxyHeaderTimeout: #{proxy_header_timeout}
                loginGraceTime: #{login_grace_time}
                ciphers:
                  - aes128-gcm@openssh.com
                kexAlgorithms:
                  - curve25519-sha256
                macs:
                  - hmac-sha2-256-etm@openssh.com
                publicKeyAlgorithms:
                  - ssh-rsa
        )))
      end

      it 'renders gitlab-sshd config' do
        expect_successful_exit_code

        expect(rendered_config['sshd']['ciphers']).to eq(['aes128-gcm@openssh.com'])
        expect(rendered_config['sshd']['kex_algorithms']).to eq(['curve25519-sha256'])
        expect(rendered_config['sshd']['macs']).to eq(['hmac-sha2-256-etm@openssh.com'])
        expect(rendered_config['sshd']['public_key_algorithms']).to eq(['ssh-rsa'])
      end
    end
  end

  context 'when PROXY protocol is set' do
    using RSpec::Parameterized::TableSyntax

    where(:ssh_daemon, :in_proxy_protocol, :out_proxy_protocol, :proxy_policy, :expected_suffix) do
      "openssh"     | false | false | "use"     | "::"
      "openssh"     | true  | false | "use"     | ":PROXY:"
      "openssh"     | true  | true  | "use"     | ":PROXY:PROXY"
      "openssh"     | false | true  | "use"     | "::PROXY"

      "gitlab-sshd" | false | false | "use"     | "::PROXY"
      "gitlab-sshd" | true  | false | "use"     | ":PROXY:PROXY"
      "gitlab-sshd" | true  | true  | "use"     | ":PROXY:PROXY"
      "gitlab-sshd" | false | true  | "use"     | "::PROXY"

      "gitlab-sshd" | true  | true  | "require" | ":PROXY:PROXY"
      "gitlab-sshd" | true  | false | "require" | ":PROXY:PROXY"

      "gitlab-sshd" | true  | true  | "ignore"  | ":PROXY:PROXY"
      "gitlab-sshd" | true  | false | "ignore"  | ":PROXY:PROXY"

      "gitlab-sshd" | true  | false | "reject"  | ":PROXY:"
      # out_proxy_protocol = false and "reject" case handled by checkConfig
    end

    with_them do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          global:
            shell:
              tcp:
                proxyProtocol: #{in_proxy_protocol}
          gitlab:
            gitlab-shell:
              sshDaemon: "#{ssh_daemon}"
              config:
                proxyProtocol: #{out_proxy_protocol}
                proxyPolicy: #{proxy_policy}
        )))
      end

      it 'should render NGINX ingress TCP data correctly' do
        expect_successful_exit_code

        data = t.dig('ConfigMap/test-nginx-ingress-tcp', 'data')

        expect(data.keys).to eq(['22'])
        expect(data['22']).to eq("default/test-gitlab-shell:22#{expected_suffix}")
      end
    end
  end

  context 'When customer provides additional labels' do
    let(:values) do
      default_values.deep_merge(YAML.safe_load(%(
        global:
          common:
            labels:
              global: global
              foo: global
          pod:
            labels:
              global_pod: true
          service:
            labels:
              global_service: true
        gitlab:
          gitlab-shell:
            common:
              labels:
                global: shell
                shell: shell
            podLabels:
              pod: true
              global: pod
            serviceLabels:
              service: true
              global: service
      )))
    end

    it 'Populates the additional labels in the expected manner' do
      expect_successful_exit_code

      expect(t.dig('ConfigMap/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('Deployment/test-gitlab-shell', 'metadata', 'labels')).to include('foo' => 'global')
      expect(t.dig('Deployment/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('Deployment/test-gitlab-shell', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'metadata', 'labels')).to include('global' => 'pod')
      expect(t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'metadata', 'labels')).to include('pod' => 'true')
      expect(t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'metadata', 'labels')).to include('global_pod' => 'true')
      expect(t.dig('HorizontalPodAutoscaler/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('NetworkPolicy/test-gitlab-shell-v1', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('PodDisruptionBudget/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
      expect(t.dig('Service/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'service')
      expect(t.dig('Service/test-gitlab-shell', 'metadata', 'labels')).to include('global_service' => 'true')
      expect(t.dig('Service/test-gitlab-shell', 'metadata', 'labels')).to include('service' => 'true')
      expect(t.dig('Service/test-gitlab-shell', 'metadata', 'labels')).not_to include('global' => 'global')
      expect(t.dig('ServiceAccount/test-gitlab-shell', 'metadata', 'labels')).to include('global' => 'shell')
    end
  end

  context 'for LFS Pure SSH protocol support' do
    let(:lfs_pure_ssh_protocol) { nil }

    let(:values) do
      vals = { 'gitlab' => { 'gitlab-shell' => { 'config' => { 'lfs' => {} } } } }
      vals['gitlab']['gitlab-shell']['config']['lfs']['pureSSHProtocol'] = lfs_pure_ssh_protocol unless lfs_pure_ssh_protocol.nil?

      default_values.deep_merge(vals)
    end

    let(:config) { t.dig('ConfigMap/test-gitlab-shell', 'data', 'config.yml.tpl') }

    let(:rendered_config) do
      rendered = RuntimeTemplate.gomplate(raw_template: config)
      YAML.safe_load(rendered, aliases: true)
    end

    context 'when unset' do
      it 'renders lfs.pure_ssh_protocol as disabled by default' do
        expect_successful_exit_code

        expect(rendered_config['lfs']['pure_ssh_protocol']).to eq(false)
      end
    end

    context 'when disabled' do
      let(:lfs_pure_ssh_protocol) { false }

      it 'renders lfs.pure_ssh_protocol as disabled' do
        expect_successful_exit_code

        expect(rendered_config['lfs']['pure_ssh_protocol']).to eq(false)
      end
    end

    context 'when enabled' do
      let(:lfs_pure_ssh_protocol) { true }

      it 'renders lfs.pure_ssh_protocol as enabled' do
        expect_successful_exit_code

        expect(rendered_config['lfs']['pure_ssh_protocol']).to eq(true)
      end
    end
  end

  context 'for PAT' do
    let(:enabled) { nil }
    let(:allowed_scopes) { nil }

    let(:values) do
      vals = { 'gitlab' => { 'gitlab-shell' => { 'config' => { 'pat' => {} } } } }
      vals['gitlab']['gitlab-shell']['config']['pat']['enabled'] = enabled unless enabled.nil?
      vals['gitlab']['gitlab-shell']['config']['pat']['allowedScopes'] = allowed_scopes unless allowed_scopes.nil?

      default_values.deep_merge(vals)
    end

    let(:config) { t.dig('ConfigMap/test-gitlab-shell', 'data', 'config.yml.tpl') }

    let(:rendered_config) do
      rendered = RuntimeTemplate.gomplate(raw_template: config)
      YAML.safe_load(rendered, aliases: true)
    end

    context 'when unset' do
      it 'renders default settings for pat' do
        expect_successful_exit_code

        expect(rendered_config['pat']['enabled']).to eq(true)
        expect(rendered_config['pat']['allowed_scopes']).to eq([])
      end
    end

    context 'when PAT disabled' do
      let(:enabled) { false }

      it 'renders pat.enabled as disabled' do
        expect_successful_exit_code

        expect(rendered_config['pat']['enabled']).to eq(false)
        expect(rendered_config['pat']['allowed_scopes']).to eq([])
      end
    end

    context 'when PAT enabled' do
      let(:enabled) { true }

      it 'renders pat.enabled as enabled' do
        expect_successful_exit_code

        expect(rendered_config['pat']['enabled']).to eq(true)
        expect(rendered_config['pat']['allowed_scopes']).to eq([])
      end
    end

    context 'when PAT allowed_scopes are set' do
      let(:allowed_scopes) { ['read_repository', 'read_api'] }

      it 'renders pat.allowed_scopes' do
        expect_successful_exit_code

        expect(rendered_config['pat']['enabled']).to eq(true)
        expect(rendered_config['pat']['allowed_scopes']).to match_array(['read_repository', 'read_api'])
      end
    end
  end

  context 'for trusted user CA keys (instance-level SSH certificates)' do
    let(:config) { t.dig('ConfigMap/test-gitlab-shell', 'data', 'config.yml.tpl') }

    let(:rendered_config) do
      rendered = RuntimeTemplate.gomplate(raw_template: config)
      YAML.safe_load(rendered, aliases: true)
    end

    context 'when unset (default)' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          gitlab:
            gitlab-shell:
              sshDaemon: "gitlab-sshd"
        )))
      end

      it 'does not render trusted_user_ca_keys in sshd config' do
        expect_successful_exit_code

        expect(rendered_config['sshd']).not_to have_key('trusted_user_ca_keys')
      end

      it 'does not add CA keys source to projected volume' do
        expect_successful_exit_code

        volumes = t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'spec', 'volumes')
        init_secrets_volume = volumes.find { |v| v['name'] == 'shell-init-secrets' }
        secret_names = init_secrets_volume['projected']['sources'].map { |s| s['secret']['name'] }
        expect(secret_names).not_to include('my-ca-keys-secret')
      end
    end

    context 'when secret is set but keys is empty' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          gitlab:
            gitlab-shell:
              sshDaemon: "gitlab-sshd"
              config:
                trustedUserCAKeys:
                  secret: my-ca-keys-secret
                  keys: []
        )))
      end

      it 'does not render trusted_user_ca_keys in sshd config' do
        expect_successful_exit_code

        expect(rendered_config['sshd']).not_to have_key('trusted_user_ca_keys')
      end

      it 'does not add CA keys source to projected volume' do
        expect_successful_exit_code

        volumes = t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'spec', 'volumes')
        init_secrets_volume = volumes.find { |v| v['name'] == 'shell-init-secrets' }
        secret_names = init_secrets_volume['projected']['sources'].map { |s| s['secret']['name'] }
        expect(secret_names).not_to include('my-ca-keys-secret')
      end
    end

    context 'when secret is configured with keys' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          gitlab:
            gitlab-shell:
              sshDaemon: "gitlab-sshd"
              config:
                trustedUserCAKeys:
                  secret: my-ca-keys-secret
                  keys:
                    - ca1.pub
                    - ca2.pub
        )))
      end

      it 'renders trusted_user_ca_keys with correct file paths' do
        expect_successful_exit_code

        expect(rendered_config['sshd']['trusted_user_ca_keys']).to eq([
          '/etc/gitlab-secrets/ssh/trusted-ca-keys/ca1.pub',
          '/etc/gitlab-secrets/ssh/trusted-ca-keys/ca2.pub'
        ])
      end

      it 'includes trusted CA keys in the shell-init-secrets projected volume' do
        expect_successful_exit_code

        volumes = t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'spec', 'volumes')
        init_secrets_volume = volumes.find { |v| v['name'] == 'shell-init-secrets' }
        ca_source = init_secrets_volume['projected']['sources'].find do |s|
          s['secret']['name'] == 'my-ca-keys-secret'
        end
        expect(ca_source).not_to be_nil
        expect(ca_source['secret']['items']).to contain_exactly(
          { 'key' => 'ca1.pub', 'path' => 'ssh/trusted-ca-keys/ca1.pub' },
          { 'key' => 'ca2.pub', 'path' => 'ssh/trusted-ca-keys/ca2.pub' }
        )
      end

      it 'includes CA key copy commands in configure script' do
        expect_successful_exit_code

        configure_script = t.dig('ConfigMap/test-gitlab-shell', 'data', 'configure')
        expect(configure_script).to include('trusted-ca-keys')
      end
    end
  end

  describe 'Topology Service client' do
    let(:config) { t.dig('ConfigMap/test-gitlab-shell', 'data', 'config.yml.tpl') }

    let(:rendered_config) do
      rendered = RuntimeTemplate.gomplate(raw_template: config)
      YAML.safe_load(rendered, aliases: true)
    end

    # Helper that builds values with the global topology service address
    # configured, plus the GitLab Shell opt-in toggle and the global Cells
    # setting. The two are separate concerns: `config.topologyService.enabled`
    # turns on GitLab Shell's use of the service, while the global Cells setting
    # (`global.appConfig.cell.enabled`) drives mTLS.
    def topology_values(shell_enabled:, cell_enabled:)
      default_values.deep_merge(YAML.safe_load(%(
        global:
          appConfig:
            cell:
              enabled: #{cell_enabled}
              id: 1
              topologyServiceClient:
                address: "topology-grpc.staging.runway.gitlab.net:443"
                tls:
                  secret: cell-1-staging-mtls-cert
        gitlab:
          gitlab-shell:
            config:
              topologyService:
                enabled: #{shell_enabled}
      )))
    end

    def topology_service_secret_source
      volumes = t.dig('Deployment/test-gitlab-shell', 'spec', 'template', 'spec', 'volumes')
      init_secrets_volume = volumes.find { |v| v['name'] == 'shell-init-secrets' }
      init_secrets_volume['projected']['sources'].find do |s|
        (s.dig('secret', 'items') || []).any? { |i| i['path'].to_s.include?('shell/topology-service') }
      end
    end

    context 'when GitLab Shell does not opt in (default)' do
      let(:values) { default_values }

      it 'does not render a topology_service block (protects self-managed/GDK)' do
        expect_successful_exit_code

        expect(rendered_config).not_to have_key('topology_service')
      end

      it 'does not add the topology service secret to the projected volume' do
        expect_successful_exit_code

        expect(topology_service_secret_source).to be_nil
      end
    end

    # GitLab Shell does not inherit the global setting; the topology service
    # client must be explicitly enabled via config.topologyService.enabled.
    context 'when the global topology service is configured but GitLab Shell does not opt in' do
      let(:values) { topology_values(shell_enabled: false, cell_enabled: true) }

      it 'does not render a topology_service block' do
        expect_successful_exit_code

        expect(rendered_config).not_to have_key('topology_service')
      end

      it 'does not add the topology service secret to the projected volume' do
        expect_successful_exit_code

        expect(topology_service_secret_source).to be_nil
      end
    end

    context 'when GitLab Shell opts in with global Cells enabled' do
      let(:values) { topology_values(shell_enabled: true, cell_enabled: true) }

      it 'renders the topology_service config with the mTLS section' do
        expect_successful_exit_code

        expect(rendered_config['topology_service']).to eq(
          'enabled' => true,
          'address' => 'topology-grpc.staging.runway.gitlab.net:443',
          'tls' => {
            'enabled' => true,
            'cert_file' => '/etc/gitlab-secrets/shell/topology-service/tls.crt',
            'key_file' => '/etc/gitlab-secrets/shell/topology-service/tls.key'
          }
        )
      end

      it 'adds the topology service secret to the shell-init-secrets projected volume' do
        expect_successful_exit_code

        ts_source = topology_service_secret_source
        expect(ts_source).not_to be_nil
        expect(ts_source['secret']['name']).to eq('cell-1-staging-mtls-cert')
        expect(ts_source['secret']['items']).to contain_exactly(
          { 'key' => 'tls.crt', 'path' => 'shell/topology-service/tls.crt' },
          { 'key' => 'tls.key', 'path' => 'shell/topology-service/tls.key' }
        )
      end

      it 'includes topology service cert copy commands in the configure script' do
        expect_successful_exit_code

        configure_script = t.dig('ConfigMap/test-gitlab-shell', 'data', 'configure')
        expect(configure_script).to include('shell/topology-service/tls.crt')
        expect(configure_script).to include('shell/topology-service/tls.key')
      end

      # Regression test for INC-11083 / !5119: the topology-service copies write
      # files that are subsequently chmod 0400'd into the shared init-secrets
      # emptyDir. Without `cp -f`, a re-run of the configure script (init-container
      # retry or rollout overlap) cannot overwrite the previously written 0400
      # files and fails with "Permission denied", crash-looping the init container.
      it 'copies topology service certs with the force flag (idempotent re-run)' do
        expect_successful_exit_code

        configure_script = t.dig('ConfigMap/test-gitlab-shell', 'data', 'configure')
        expect(configure_script).to match(%r{cp\s+(-\w+\s+)*-f(\s+-\w+)*\s+/\$\{config_dir\}/shell/topology-service/tls\.crt})
        expect(configure_script).to match(%r{cp\s+(-\w+\s+)*-f(\s+-\w+)*\s+/\$\{config_dir\}/shell/topology-service/tls\.key})
      end
    end

    # Separation of concerns: GitLab Shell can use the topology service without
    # mTLS. The global Cells setting drives mTLS, so when Cells is disabled the
    # client config omits the tls section and no certs are mounted or copied.
    context 'when GitLab Shell opts in with global Cells disabled' do
      let(:values) { topology_values(shell_enabled: true, cell_enabled: false) }

      it 'renders the topology_service config without the mTLS section' do
        expect_successful_exit_code

        expect(rendered_config['topology_service']).to eq(
          'enabled' => true,
          'address' => 'topology-grpc.staging.runway.gitlab.net:443'
        )
      end

      it 'does not add the topology service secret to the projected volume' do
        expect_successful_exit_code

        expect(topology_service_secret_source).to be_nil
      end

      it 'does not include topology service cert copy commands in the configure script' do
        expect_successful_exit_code

        configure_script = t.dig('ConfigMap/test-gitlab-shell', 'data', 'configure')
        expect(configure_script).not_to include('shell/topology-service')
      end
    end

    context 'when GitLab Shell opts in without a topology service address' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          gitlab:
            gitlab-shell:
              config:
                topologyService:
                  enabled: true
        )))
      end

      it 'fails rendering with a clear error about the missing address' do
        expect(t.exit_code).not_to eq(0)
        expect(t.stderr).to include('global.appConfig.cell.topologyServiceClient.address must be set')
      end
    end
  end

  describe 'configure script idempotency (INC-11083 regression)' do
    let(:values) { default_values }

    let(:configure_script) { t.dig('ConfigMap/test-gitlab-shell', 'data', 'configure') }

    # The SSH host keys are copied and then chmod 0400'd into the shared
    # init-secrets emptyDir. Without `cp -f`, a second execution of the configure
    # script against the same emptyDir cannot overwrite the 0400 files and exits
    # non-zero under `set -e`, causing Init:CrashLoopBackOff (INC-11083 / !5119).
    it 'copies SSH host keys with the force flag so re-runs do not fail with Permission denied' do
      expect_successful_exit_code

      expect(configure_script).to match(%r{cp\s+(-\w+\s+)*-f(\s+-\w+)*\s+/\$\{config_dir\}/ssh_host_\*})
    end
  end
end
