require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'
require 'runtime_template_helper'

describe 'registry configure init container' do
  let(:tricky) { %(a&b@c\\1d"e#f {% fail "evaluated" %} 'q' $(id)\nnext line) }
  let(:header) { %(Bearer a&b@c\\1d"e#f {% fail "evaluated" %}) }

  let(:default_values) do
    HelmTemplate.defaults.deep_merge(YAML.safe_load(%(
      global:
        hosts:
          registry:
            protocol: https
        psql:
          ssl:
            secret: registry-db-ssl
            clientCertificate: client.crt
            clientKey: client.key
            serverCA: server-ca.crt
        registry:
          notifications:
            endpoints:
              - name: listener
                url: https://listener.example.com
                headers:
                  X-Plain: [plain]
                  Authorization:
                    secret: registry-authorization-header
                    key: header
      registry:
        storage:
          extraKey: gcs.json
        tls:
          enabled: true
        middleware:
          storage:
            - name: cloudfront
              options:
                baseurl: https://cdn.example.com
                privatekeySecret:
                  secret: cloudfront-key
                  key: private.pem
        profiling:
          stackdriver:
            enabled: true
            credentials:
              secret: profiling-key
        database:
          enabled: true
        redis:
          cache:
            enabled: true
            password:
              enabled: true
          rateLimiting:
            enabled: true
            password:
              enabled: true
          loadBalancing:
            enabled: true
            password:
              enabled: true
    )))
  end

  let(:storage_config) { "s3:\n  bucket: registry\n  secretkey: 'sk&@\\1\"\#{%'\n  secure: yes\n" }

  let(:config_files) do
    {
      '/config/httpSecret' => "#{tricky}\n",
      '/config/database_password' => "#{tricky}\n\n",
      '/config/registry/redis-password' => "cache-#{tricky}",
      '/config/registry/redis-rateLimiting-password' => "rate-limiting-#{tricky}",
      '/config/registry/redis-loadBalancing-password' => "load-balancing-#{tricky}",
      '/config/notifications/SECRET_registry-authorization-header_header' => "#{[header, 'second'].to_json}\n",
      '/config/storage/config' => storage_config
    }
  end

  let(:values) { default_values }
  let(:template) { HelmTemplate.new(values) }
  let(:configmap) { template.dig('ConfigMap/test-registry', 'data') }
  let(:job_name) { template.resources_by_kind('Job').keys.find { |name| name.start_with?('Job/test-registry-migrations') } }

  def configure_container(item)
    template.find_container(item, 'configure', true)
  end

  def gomplate(raw_template, files = config_files)
    YAML.safe_load(RuntimeTemplate.gomplate(raw_template: raw_template.dup, files: files), permitted_classes: [Symbol])
  end

  def volume(item, name)
    template.volumes(item).find { |volume| volume['name'] == name }
  end

  def projected_sources(item, name)
    volume(item, name).dig('projected', 'sources')
  end

  def registry_files_items(item)
    projected_sources(item, 'registry-files').flat_map { |source| source.dig('secret', 'items') }
  end

  context 'with default values' do
    it 'renders config.yml with gomplate and no shell' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

      command = ['gomplate', '--left-delim', '{%', '--right-delim', '%}', '--file', '/templates/config.yml.tpl', '--out', '/registry/config.yml']
      [configure_container('Deployment/test-registry'), configure_container(job_name)].each do |container|
        expect(container['command']).to eq(command)
        expect(container).not_to have_key('args')
      end

      expect(configmap).not_to have_key('configure')
      expect(projected_sources(job_name, 'registry-secrets').flat_map(&:keys)).not_to include('configMap')
    end

    it 'reads every secret as data' do
      config = gomplate(configmap['config.yml.tpl'])

      expect(config.dig('http', 'secret')).to eq(tricky)
      expect(config.dig('database', 'password')).to eq(tricky)
      expect(config.dig('redis', 'cache', 'password')).to eq("cache-#{tricky}")
      expect(config.dig('redis', 'ratelimiter', 'password')).to eq("rate-limiting-#{tricky}")
      expect(config.dig('redis', 'loadbalancing', 'password')).to eq("load-balancing-#{tricky}")

      migrations_config = gomplate(configmap['migrations-config.yml.tpl'])
      expect(migrations_config.dig('database', 'password')).to eq(tricky)
    end

    it 'renders notification secret headers as the YAML list in the secret' do
      headers = gomplate(configmap['config.yml.tpl']).dig('notifications', 'endpoints', 0, 'headers')

      expect(headers['Authorization']).to eq([header, 'second'])
      expect(headers['X-Plain']).to eq(['plain'])
    end

    it 'inserts the storage secret as YAML and defaults delete.enabled to true' do
      storage = gomplate(configmap['config.yml.tpl'])['storage']

      expect(storage['s3']).to eq('bucket' => 'registry', 'secretkey' => 'sk&@\\1"#{%', 'secure' => true)
      expect(storage['delete']).to eq('enabled' => true)
      expect(storage.dig('maintenance', 'uploadpurging', 'enabled')).to be(true)
    end

    context 'when the storage secret sets delete.enabled' do
      let(:storage_config) { "filesystem:\n  rootdirectory: /var/lib/registry\ndelete:\n  enabled: false\n" }

      it 'keeps the configured value' do
        rendered = RuntimeTemplate.gomplate(raw_template: configmap['config.yml.tpl'].dup, files: config_files)

        expect(YAML.safe_load(rendered, permitted_classes: [Symbol]).dig('storage', 'delete')).to eq('enabled' => false)
        expect(rendered.scan(/^\s*delete:/).length).to eq(1)
      end
    end

    {
      'flow style' => "delete: {enabled: false}\n",
      'a comment before enabled' => "delete:\n  # keep tags\n  enabled: false\n",
      'a blank line before enabled' => "delete:\n\n  enabled: false\n"
    }.each do |form, delete_config|
      context "when the storage secret sets delete.enabled in #{form}" do
        let(:storage_config) { "filesystem:\n  rootdirectory: /var/lib/registry\n#{delete_config}" }

        it 'keeps the configured value' do
          rendered = RuntimeTemplate.gomplate(raw_template: configmap['config.yml.tpl'].dup, files: config_files)

          expect(YAML.safe_load(rendered, permitted_classes: [Symbol]).dig('storage', 'delete')).to eq('enabled' => false)
          expect(rendered.scan(/^\s*delete:/).length).to eq(1)
        end
      end
    end

    {
      'an empty delete block' => "delete: {}\n",
      'a null delete key' => "delete:\n"
    }.each do |form, delete_config|
      context "when the storage secret has #{form}" do
        let(:storage_config) { "filesystem:\n  rootdirectory: /var/lib/registry\n#{delete_config}" }

        it 'defaults delete.enabled to true, as the configure script did' do
          expect(gomplate(configmap['config.yml.tpl']).dig('storage', 'delete')).to eq('enabled' => true)
        end
      end
    end

    context 'when the storage secret repeats a key' do
      let(:storage_config) { "s3:\n  bucket: first\n  bucket: second\n" }

      it 'inserts it unchanged for the registry to parse' do
        rendered = RuntimeTemplate.gomplate(raw_template: configmap['config.yml.tpl'].dup, files: config_files)

        expect(rendered).to include("storage:\n  s3:\n    bucket: first\n    bucket: second\n  delete:\n    enabled: true\n")
      end
    end

    context 'when the storage secret has CRLF line endings' do
      let(:storage_config) { "s3:\r\n  bucket: registry\r\ndelete:\r\n  enabled: false\r\n" }

      it 'inserts it as YAML and keeps delete.enabled' do
        storage = gomplate(configmap['config.yml.tpl'])['storage']

        expect(storage['s3']).to eq('bucket' => 'registry')
        expect(storage['delete']).to eq('enabled' => false)
      end
    end

    context 'when a notification header secret is a block list' do
      before do
        config_files['/config/notifications/SECRET_registry-authorization-header_header'] = "- #{header}\n- second\n"
      end

      it 'renders each item' do
        headers = gomplate(configmap['config.yml.tpl']).dig('notifications', 'endpoints', 0, 'headers')

        expect(headers['Authorization']).to eq([header, 'second'])
      end
    end

    context 'when values contain the gomplate delimiter' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          registry:
            tokenService: 'svc{% fail "evaluated" %}{%- x'
        )))
      end

      it 'renders the value as text' do
        expect(gomplate(configmap['config.yml.tpl']).dig('auth', 'token', 'service')).to eq('svc{% fail "evaluated" %}{%- x')
      end
    end

    context 'when a value repeats an action the chart emits' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          registry:
            database:
              user: 'u{% file.Read "/config/httpSecret" | strings.TrimRight "\\n" | data.ToJSON %}'
        )))
      end

      it 'renders the value as text' do
        config = gomplate(configmap['config.yml.tpl'])

        expect(config.dig('database', 'user')).to match(%r{\Au\{% file\.Read "\S*/config/httpSecret" \| strings\.TrimRight "\\n" \| data\.ToJSON %\}\z})
        expect(config.dig('http', 'secret')).to eq(tricky)
      end
    end

    context 'when a value holds a NUL character' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          registry:
            tokenService: "svc\\0gomplate-action-0\\0"
        )))
      end

      it 'fails to render' do
        expect(template.exit_code).not_to eq(0)
        expect(template.stderr).to include('a value rendered into the registry configuration contains a NUL character')
      end
    end

    context 'with Sentinel and a value with the gomplate delimiter in the same template' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          global:
            redis:
              sentinels:
                - host: sentinel.example.com
                  port: 26379
              sentinelAuth:
                enabled: true
                secret: redis-sentinel
                key: password
          registry:
            tokenService: 'svc{%'
        )))
      end

      it 'evaluates the chart actions and escapes the value' do
        files = config_files.merge('/config/redis-sentinel/redis-sentinel-password' => " sentinel#{tricky} ")
        config = gomplate(configmap['config.yml.tpl'], files)

        expect(config.dig('redis', 'cache', 'sentinelpassword')).to eq("sentinel#{tricky}".strip)
        expect(config.dig('auth', 'token', 'service')).to eq('svc{%')
      end
    end

    it 'gives the configure container only the files the template reads' do
      paths = projected_sources('Deployment/test-registry', 'registry-secrets').flat_map do |source|
        expect(source).to have_key('secret')
        source.dig('secret', 'items').map { |item| item['path'] }
      end

      expect(paths).to contain_exactly(
        'httpSecret',
        'storage/config',
        'notifications/SECRET_registry-authorization-header_header',
        'database_password',
        'registry/redis-password',
        'registry/redis-rateLimiting-password',
        'registry/redis-loadBalancing-password'
      )
      expect(projected_sources(job_name, 'registry-secrets').flat_map { |source| source.dig('secret', 'items').map { |item| item['path'] } })
        .to eq(['database_password'])
    end

    it 'mounts the files config.yml references into the registry container' do
      mounts = template.find_container('Deployment/test-registry', 'registry')['volumeMounts']
                 .select { |mount| mount['mountPath'].start_with?('/etc/docker/registry') }

      expect(mounts).to all(include('readOnly' => true))
      expect(mounts.to_h { |mount| [mount['mountPath'], [mount['name'], mount['subPath']]] }).to eq(
        '/etc/docker/registry/config.yml' => ['registry-server-config', 'config.yml'],
        '/etc/docker/registry/certificate.crt' => ['registry-files', 'certificate.crt'],
        '/etc/docker/registry/storage' => ['registry-files', 'storage'],
        '/etc/docker/registry/middleware.storage' => ['registry-files', 'middleware.storage'],
        '/etc/docker/registry/profiling-key.json' => ['registry-files', 'profiling-key.json'],
        '/etc/docker/registry/tls' => ['registry-files', 'tls'],
        '/etc/docker/registry/ssl' => ['registry-files', 'ssl']
      )

      expect(registry_files_items('Deployment/test-registry').to_h { |item| [item['path'], item['mode']] }).to eq(
        'certificate.crt' => nil,
        'storage/gcs.json' => 0o440,
        'middleware.storage/0/private.pem' => 0o440,
        'profiling-key.json' => 0o440,
        'tls/tls.crt' => 0o440,
        'tls/tls.key' => 0o440,
        'ssl/client-certificate.pem' => 0o440,
        'ssl/client-key.pem' => 0o440,
        'ssl/server-ca.pem' => 0o440
      )
    end

    it 'mounts only the database files into the migrations container' do
      mounts = template.find_container(job_name, 'migrations')['volumeMounts']
                 .select { |mount| mount['mountPath'].start_with?('/etc/docker/registry') }

      expect(mounts.map { |mount| mount['mountPath'] }).to eq(['/etc/docker/registry/config.yml', '/etc/docker/registry/ssl'])
      expect(registry_files_items(job_name).map { |item| item['path'] }).to eq(
        ['ssl/client-certificate.pem', 'ssl/client-key.pem', 'ssl/server-ca.pem']
      )
    end

    context 'without an fsGroup' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          registry:
            securityContext:
              fsGroup: ""
        )))
      end

      it 'makes key material readable by the registry user' do
        modes = registry_files_items('Deployment/test-registry').to_h { |item| [item['path'], item['mode']] }

        expect(modes.delete('certificate.crt')).to be_nil
        expect(modes.keys).to include('storage/gcs.json', 'middleware.storage/0/private.pem', 'profiling-key.json', 'tls/tls.key', 'ssl/client-key.pem')
        expect(modes.values).to all(eq(0o444))
      end
    end
  end

  context 'with a custom init.script' do
    let(:values) do
      default_values.deep_merge(YAML.safe_load(%(
        registry:
          init:
            script: |-
              sed -i -e 's@HTTP_SECRET@'"$(cat /config/httpSecret)"'@' /registry/config.yml
      )))
    end

    it 'keeps the legacy configure script and placeholders' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

      expect(configmap['configure']).to eq(%(sed -i -e 's@HTTP_SECRET@'"$(cat /config/httpSecret)"'@' /registry/config.yml))
      expect(configure_container('Deployment/test-registry')['args']).to eq(['sh', '/config/configure'])
      expect(configure_container(job_name)['args']).to eq(['sh', '/config/configure'])
      expect(configure_container('Deployment/test-registry')).not_to have_key('command')

      config = configmap['config.yml.tpl']
      expect(config).to include('secret: "HTTP_SECRET"')
      expect(config).to include('password: "DB_PASSWORD_FILE"')
      expect(config).to include('password: "REDIS_CACHE_PASSWORD"')
      expect(config).to include('password: "REDIS_RATE_LIMITING_PASSWORD"')
      expect(config).to include('password: "REDIS_LOAD_BALANCING_PASSWORD"')
      expect(config).to include('Authorization: SECRET_registry-authorization-header_header')
      expect(config).not_to include('/config/storage/config')
      expect(configmap['migrations-config.yml.tpl']).to include('password: "DB_PASSWORD_FILE"')
    end

    it 'renders the configure containers and their Secrets as before' do
      expected = YAML.safe_load(File.read('spec/fixtures/registry-legacy-configure.yaml'))

      expect(configure_container('Deployment/test-registry').except('image')).to eq(expected['deploy_configure'])
      expect(configure_container(job_name).except('image')).to eq(expected['job_configure'])
      expect(volume('Deployment/test-registry', 'registry-secrets')).to eq(expected['deploy_secrets'])
      expect(volume(job_name, 'registry-secrets')).to eq(expected['job_secrets'])
      expect(configmap['config.yml.tpl']).to eq(expected['config.yml.tpl'])
      expect(configmap['migrations-config.yml.tpl']).to eq(expected['migrations-config.yml.tpl'])
    end

    it 'mounts the configure output directory as before' do
      mounts = template.find_container('Deployment/test-registry', 'registry')['volumeMounts']
                 .select { |mount| mount['mountPath'].start_with?('/etc/docker/registry') }

      expect(mounts).to eq([{ 'name' => 'registry-server-config', 'mountPath' => '/etc/docker/registry/', 'readOnly' => true }])
      expect(volume('Deployment/test-registry', 'registry-files')).to be_nil
      expect(volume(job_name, 'registry-files')).to be_nil
      expect(projected_sources(job_name, 'registry-secrets').first).to eq(
        'configMap' => { 'name' => 'test-registry', 'items' => [{ 'key' => 'configure', 'path' => 'configure' }] }
      )
    end
  end
end
