require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'cells-mailroom configuration' do
  let(:values) do
    HelmTemplate.with_defaults(%(
      global:
        appConfig:
          cell:
            enabled: true
            topologyServiceClient:
              address: "ts.example.com:443"
              tls:
                enabled: true
                secret: ts-tls
          incomingEmail:
            enabled: true
            address: "incoming+%{key}@example.com"
            user: "incoming@example.com"
            password:
              secret: incoming-pw
      gitlab:
        cells-mailroom:
          enabled: true
          signingKey:
            secret: cells-mailroom-signing-key
    ))
  end

  let(:template) { HelmTemplate.new(values) }
  let(:raw_gitlab_yml) { template.dig('ConfigMap/test-cells-mailroom', 'data', 'gitlab.yml') }
  let(:gitlab_yml) { YAML.safe_load(raw_gitlab_yml.gsub(/password: .*/, 'password: x'))['production'] }

  context 'when disabled by default' do
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
          appConfig:
            incomingEmail:
              enabled: true
              address: "incoming+%{key}@example.com"
              password:
                secret: incoming-pw
      ))
    end

    it 'renders no cells-mailroom resources' do
      expect(template.exit_code).to eq(0)
      expect(template['Deployment/test-cells-mailroom']).to be_nil
      expect(template['ConfigMap/test-cells-mailroom']).to be_nil
    end
  end

  context 'when enabled' do
    it 'renders a Deployment and ConfigMap but no Service' do
      expect(template.exit_code).to eq(0)
      expect(template['Deployment/test-cells-mailroom']).not_to be_nil
      expect(template['ConfigMap/test-cells-mailroom']).not_to be_nil
      expect(template['Service/test-cells-mailroom']).to be_nil
    end

    it 'renders the incoming_email mailbox with delivery cleanup settings' do
      incoming = gitlab_yml['incoming_email']
      expect(incoming['enabled']).to be true
      expect(incoming['user']).to eq('incoming@example.com')
      expect(incoming['delete_after_delivery']).to be true
      expect(incoming['expunge_deleted']).to be false
      expect(incoming['signing_key_file']).to eq('/etc/gitlab/cells-mailroom/signing_key')
    end

    it 'reads the IMAP password from a mounted file at runtime' do
      expect(raw_gitlab_yml).to include(
        %(password: <%= File.read("/etc/gitlab/mailroom/password_incoming_email").strip.to_json %>)
      )
    end

    it 'renders the topology service client with mTLS cert paths' do
      ts = gitlab_yml['cell']['topology_service_client']
      expect(ts['address']).to eq('ts.example.com:443')
      expect(ts['tls']['enabled']).to be true
      expect(ts['private_key_file']).to eq('/srv/gitlab/config/topology-service/tls.key')
      expect(ts['certificate_file']).to eq('/srv/gitlab/config/topology-service/tls.crt')
      expect(ts).not_to have_key('ca_file')
    end

    it 'renders the cell endpoint scheme and port' do
      endpoint = gitlab_yml['cell']['email_forwarding']['cell_endpoint']
      expect(endpoint['scheme']).to eq('https')
      expect(endpoint['port']).to eq(8181)
    end

    it 'renders the health check with a port so the service starts the server' do
      health = gitlab_yml['cell']['email_forwarding']['health_check']
      expect(health['address']).to eq('0.0.0.0')
      expect(health['port']).to eq(8080)
    end

    it 'drives the liveness probe from the same health check port' do
      probe = template.dig('Deployment/test-cells-mailroom', 'spec', 'template', 'spec', 'containers', 0, 'livenessProbe')
      expect(probe['httpGet']['path']).to eq('/liveness')
      expect(probe['httpGet']['port']).to eq(8080)
    end

    it 'projects the IMAP password, signing key and topology cert secrets' do
      sources = template.projected_volume_sources('Deployment/test-cells-mailroom', 'init-cells-mailroom-secrets')
      names = sources.map { |s| s['secret']['name'] }
      expect(names).to include('incoming-pw', 'cells-mailroom-signing-key', 'ts-tls')
    end

    it 'projects the Redis password secret needed by the arbitration config' do
      # The arbitration redis_url embeds ERB that reads the Redis password file
      # at startup, so the secret must be mounted or the pod crash-loops.
      sources = template.projected_volume_sources('Deployment/test-cells-mailroom', 'init-cells-mailroom-secrets')
      redis = sources.select { |s| s['secret']['items'].any? { |i| i['path'].start_with?('redis/') } }
      expect(redis).not_to be_empty
    end

    it 'copies secrets with the shared configure script rather than a fail-open copy' do
      configure = template.dig('ConfigMap/test-cells-mailroom', 'data', 'configure')
      expect(configure).to include('set -e')
      expect(configure).to include('topology-service/tls.crt')
      expect(configure).not_to include('2>/dev/null || true')
    end

    it 'reuses the shared mailroom arbitration namespace via redis config' do
      arbitration = gitlab_yml['cell']['email_forwarding']['arbitration']
      expect(arbitration['redis_url']).to include('redis')
    end
  end

  context 'when a mailbox uses the microsoft_graph inbox method' do
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
          appConfig:
            cell:
              enabled: true
              topologyServiceClient:
                address: "ts.example.com:443"
                tls:
                  enabled: true
                  secret: ts-tls
            incomingEmail:
              enabled: true
              inboxMethod: microsoft_graph
              address: "incoming+%{key}@example.com"
              user: "incoming@example.com"
              tenantId: tenant
              clientId: client
              clientSecret:
                secret: incoming-graph
              password:
                secret: incoming-pw
        gitlab:
          mailroom:
            enabled: false
          cells-mailroom:
            enabled: true
            signingKey:
              secret: cells-mailroom-signing-key
      ))
    end

    it 'fails the render with a clear message' do
      expect(template.exit_code).not_to eq(0)
      expect(template.stderr).to include('does not support the microsoft_graph inbox method')
    end
  end

  context 'with service_desk_email also enabled' do
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
          appConfig:
            cell:
              enabled: true
              topologyServiceClient:
                address: "ts.example.com:443"
                tls:
                  enabled: true
                  secret: ts-tls
            incomingEmail:
              enabled: true
              address: "incoming+%{key}@example.com"
              user: "incoming@example.com"
              password:
                secret: incoming-pw
            serviceDeskEmail:
              enabled: true
              address: "support+%{key}@example.com"
              user: "support@example.com"
              password:
                secret: sd-pw
        gitlab:
          cells-mailroom:
            enabled: true
            signingKey:
              secret: cells-mailroom-signing-key
      ))
    end

    it 'renders both mailboxes with their own signing key file' do
      expect(template.exit_code).to eq(0)
      expect(gitlab_yml['incoming_email']['enabled']).to be true
      expect(gitlab_yml['service_desk_email']['enabled']).to be true
      expect(gitlab_yml['service_desk_email']['signing_key_file']).to eq('/etc/gitlab/cells-mailroom/signing_key')
    end

    it 'projects both IMAP password secrets' do
      sources = template.projected_volume_sources('Deployment/test-cells-mailroom', 'init-cells-mailroom-secrets')
      names = sources.map { |s| s['secret']['name'] }
      expect(names).to include('incoming-pw', 'sd-pw')
    end
  end
end

describe 'mailroom asymmetric JWT public keys' do
  let(:public_key_files) do
    %(
            publicKeyFiles:
              secret: incoming-email-public-keys
              keys: [current.pub]
    )
  end

  let(:values) do
    HelmTemplate.with_defaults(%(
      global:
        appConfig:
          incomingEmail:
            enabled: true
            address: "incoming+%{key}@example.com"
            password:
              secret: incoming-pw
      #{public_key_files}
    ))
  end

  let(:template) { HelmTemplate.new(values) }
  let(:rails_config) { template.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb') }

  it 'renders public_key_files in the Rails gitlab.yml' do
    expect(rails_config).to include('public_key_files:')
    expect(rails_config).to include('/etc/gitlab/mailroom/incoming_email_public_key_current.pub')
  end

  it 'keeps the symmetric secret_file alongside it, so both token types verify' do
    expect(rails_config).to include('/etc/gitlab/mailroom/incoming_email_webhook_secret')
  end

  it 'projects each named field from the one public key secret' do
    sources = template.projected_volume_sources('Deployment/test-webservice-default', 'init-webservice-secrets')
    match = sources.select { |s| s['secret']['name'] == 'incoming-email-public-keys' }

    expect(match.length).to eq(1)
    expect(match.first['secret']['items']).to contain_exactly(
      a_hash_including('key' => 'current.pub', 'path' => 'mailroom/incoming_email_public_key_current.pub')
    )
  end

  context 'with a second key trusted during rotation' do
    let(:public_key_files) do
      %(
            publicKeyFiles:
              secret: incoming-email-public-keys
              keys: [current.pub, previous.pub]
      )
    end

    it 'lists both keys so tokens signed with either are accepted' do
      expect(rails_config).to include('/etc/gitlab/mailroom/incoming_email_public_key_current.pub')
      expect(rails_config).to include('/etc/gitlab/mailroom/incoming_email_public_key_previous.pub')
    end

    it 'mounts both fields from the same secret' do
      sources = template.projected_volume_sources('Deployment/test-webservice-default', 'init-webservice-secrets')
      match = sources.select { |s| s['secret']['name'] == 'incoming-email-public-keys' }

      expect(match.first['secret']['items'].map { |i| i['key'] }).to eq(['current.pub', 'previous.pub'])
    end
  end

  context 'when not configured' do
    let(:public_key_files) { '' }

    it 'renders no public_key_files, so only symmetric tokens are accepted' do
      expect(template.exit_code).to eq(0)
      expect(rails_config).not_to include('public_key_files:')
    end
  end

  context 'when a secret is named without any keys' do
    let(:public_key_files) do
      %(
            publicKeyFiles:
              secret: incoming-email-public-keys
              keys: []
      )
    end

    it 'fails the render rather than mounting nothing' do
      expect(template.exit_code).not_to eq(0)
      expect(template.stderr).to include('is set but `keys` is empty')
    end
  end

  context 'when keys are named without a secret' do
    let(:public_key_files) do
      %(
            publicKeyFiles:
              secret: ""
              keys: [current.pub]
      )
    end

    it 'fails the render rather than mounting nothing' do
      expect(template.exit_code).not_to eq(0)
      expect(template.stderr).to include('is set but `secret` is empty')
    end
  end
end
