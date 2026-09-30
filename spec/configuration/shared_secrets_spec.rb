# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'
require 'shellwords'

describe 'shared-secrets provisioning' do
  let(:default_values) { HelmTemplate.with_defaults('{}') }

  # Every conditional entry in the manifest, so the matrix below exercises each one.
  let(:all_features) do
    HelmTemplate.with_defaults(%(
      global:
        kas:
          enabled: true
        pages:
          enabled: true
          accessControl: true
        praefect:
          enabled: true
    ))
  end

  def generate_secrets_script(template)
    template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
  end

  def as_controller(values)
    values.deep_merge(YAML.safe_load(%(
      shared-secrets:
        provider: controller
    )))
  end

  # The set of (secret name, key name) pairs the job backend would create, parsed back
  # out of the rendered shell.
  def job_backend_pairs(script)
    pairs = script.scan(/^generate_secret_if_needed\s+(\S+)(.*)$/).flat_map do |name, args|
      secret = name.delete('"')
      keys = args.scan(/--from-(?:literal|file)=("?)([^"=\s]+)\1=/).map { |_, key| key }
      keys << 'host_keys' if args.include?('--from-file host_keys')
      keys.map { |key| [secret, key] }
    end

    # The Rails secret is the one entry applied with `kubectl apply` instead of
    # generate_secret_if_needed, because it merges into whatever already exists.
    rails = script[/^\s*rails_secret=(\S+)$/, 1]
    if rails
      key = script[/^\s{2}(\S+): \|-$/, 1]
      pairs << [rails.delete('"'), key]
    end

    pairs
  end

  # The same set, read out of the GitLabSecrets resource.
  def generator_keys(generator)
    case generator['type']
    when 'x509' then [generator['keyKey'], generator['certKey']]
    when 'sshHostKeys' then ['host_keys']
    else [generator['key']]
    end
  end

  def controller_backend_pairs(cr)
    cr['spec']['secrets'].flat_map do |secret|
      keys = secret['generators'].flat_map { |generator| generator_keys(generator) }
      keys.map { |key| [secret['name'], key] }
    end
  end

  # The value of every `--from-literal` argument the job passes, keyed by (secret, key).
  def job_backend_literals(script)
    script.scan(/^generate_secret_if_needed\s+(\S+)(.*)$/).each_with_object({}) do |(name, args), literals|
      args.split(/ (?=--from-)/).grep(/\A--from-literal=/).each do |arg|
        key, value = arg.delete_prefix('--from-literal=').split('=', 2)
        literals[[name.delete('"'), key.delete('"')]] = value
      end
    end
  end

  # The job's shell for a `random` generator, rebuilt from its GitLabSecrets fields the
  # way gitlab.secrets.shell.value builds it. `fetch` fails on a value it does not know.
  def random_job_value(generator)
    charset = { 'alphanumeric' => 'a-zA-Z0-9', 'hex' => 'a-f0-9', 'lowerAlphanumeric' => 'a-z0-9' }
    encoding = { nil => '', 'none' => '', 'base64' => ' | base64 -w 0' }
    command = "gen_random '#{charset.fetch(generator['charset'])}' #{generator['length']}"
    value = "$(#{command}#{encoding.fetch(generator['encoding'])})"

    case generator.fetch('wrap', 'none')
    when 'none' then value
    when 'jsonArray' then %([\\"#{value}\\"])
    else raise ArgumentError, "unknown wrap #{generator['wrap'].inspect}"
    end
  end

  describe 'provider: job (the default)' do
    let(:template) { HelmTemplate.new(default_values) }

    it 'renders the hook Job, its ConfigMap, and its RBAC' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

      expect(template.resources_by_kind('ConfigMap')).to include('ConfigMap/test-shared-secrets')
      expect(template.resources('shared-secrets').grep(/^Job/)).not_to be_empty
      expect(template.resource_exists?('Role/test-shared-secrets')).to be true
      expect(template.resource_exists?('RoleBinding/test-shared-secrets')).to be true
    end

    it 'renders no GitLabSecrets resource' do
      expect(template.resources_by_kind('GitLabSecrets')).to be_empty
    end

    it 'drives every secret through the manifest' do
      # A representative sample across generator types. If these are missing, the
      # manifest is not reaching the script.
      script = generate_secrets_script(template)

      expect(script).to include('generate_secret_if_needed "test-gitaly-secret" --from-literal=token=')
      expect(script).to include('openssl req -new -newkey rsa:4096')
      expect(script).to include('ssh-keygen -A')
      expect(script).to include('rails_secret="test-rails-secret"')
    end

    it 'indents every line of a rotated key list' do
      # A rotated active_record_encryption key list arrives from fetch_rails_value as
      # multi-line text. Prefixing only the first line leaves later entries at column 0
      # and kubectl rejects the document, breaking the upgrade.
      script = generate_secrets_script(template)

      %w[active_record_encryption_primary_key active_record_encryption_deterministic_key].each do |field|
        expect(script).to include(%(#{field}:\n$(echo "${#{field}}" | awk '{print "        " $0}')))
        expect(script).not_to include(%(#{field}:\n        $#{field}\n))
      end
    end
  end

  describe 'provider: controller' do
    let(:values) { as_controller(default_values) }

    let(:template) { HelmTemplate.new(values) }
    let(:resource) { template.resources_by_kind('GitLabSecrets').values.first }

    it 'renders exactly one GitLabSecrets resource' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      expect(template.resources_by_kind('GitLabSecrets').length).to eq(1)
    end

    it 'uses the agreed group, version, and kind' do
      expect(resource['apiVersion']).to eq('apps.gitlab.com/v2alpha1')
      expect(resource['kind']).to eq('GitLabSecrets')
    end

    it 'declares the never-rotate policy' do
      expect(resource.dig('spec', 'policy')).to eq('fill-missing')
    end

    it 'renders no hook Job, ConfigMap, or RBAC' do
      expect(template.resource_exists?('ConfigMap/test-shared-secrets')).to be false
      expect(template.resource_exists?('Role/test-shared-secrets')).to be false
      expect(template.resource_exists?('RoleBinding/test-shared-secrets')).to be false
      expect(template.resources('shared-secrets').grep(/^Job/)).to be_empty
    end

    it 'renders no Secret objects, so helm uninstall cannot delete secret material' do
      # doc/installation/uninstall.md promises the chart never creates Secrets through
      # Helm. Rendering stubs here would make db_key_base a release member.
      expect(template.resources_by_kind('Secret')).to be_empty
    end

    it 'carries no ownerReference expectations that would let GC delete the secrets' do
      resource['spec']['secrets'].each do |secret|
        expect(secret).not_to have_key('ownerReferences')
      end
    end

    it 'strips chart-only bookkeeping fields from the spec' do
      resource['spec']['secrets'].each do |secret|
        expect(secret.keys).to contain_exactly('name', 'type', 'generators')
        secret['generators'].each do |generator|
          generator.fetch('fields', []).each do |field|
            expect(field).not_to have_key('note')
          end
        end
      end
    end

    it 'keeps numeric parameters as integers' do
      # Helm decodes YAML numbers as float64 and the Operator's renderer as int64.
      # gitlab.secrets.load coerces with `int` so both agree.
      lengths = resource['spec']['secrets'].flat_map { |s| s['generators'] }
                                           .filter_map { |g| g['length'] }
      expect(lengths).not_to be_empty
      expect(lengths).to all(be_a(Integer))
    end
  end

  # Value sets the rendered-manifest specs below iterate over.
  value_matrix = {
    'defaults' => '{}',
    'all optional features' => %(
      global:
        kas:
          enabled: true
        pages:
          enabled: true
          accessControl: true
        praefect:
          enabled: true
        appConfig:
          incomingEmail:
            enabled: true
            address: incoming+%{key}@example.com
            password:
              secret: mailroom-password
          serviceDeskEmail:
            enabled: true
            address: servicedesk+%{key}@example.com
            password:
              secret: mailroom-password
    ),
    'praefect with an external database' => %(
      global:
        praefect:
          enabled: true
          psql:
            host: db.example.com
    ),
    'a renamed secret' => %(
      global:
        gitaly:
          authToken:
            secret: my-gitaly
    )
  }

  describe 'the two backends stay in step' do
    # This is the spec that stops the manifest's two projections from drifting.
    value_matrix.each do |name, extra|
      context "with #{name}" do
        let(:base) { HelmTemplate.with_defaults(extra) }

        it 'produces the same (secret, key) pairs under either provider' do
          job = HelmTemplate.new(base)
          expect(job.exit_code).to eq(0), "Unexpected error code #{job.exit_code} -- #{job.stderr}"

          controller = HelmTemplate.new(as_controller(base))
          expect(controller.exit_code).to eq(0), "Unexpected error code #{controller.exit_code} -- #{controller.stderr}"

          from_job = job_backend_pairs(generate_secrets_script(job))
          from_controller = controller_backend_pairs(
            controller.resources_by_kind('GitLabSecrets').values.first
          )

          expect(from_job).not_to be_empty
          expect(from_controller.sort).to eq(from_job.sort)
        end

        it 'renders every random generator as the exact job recipe for its fields' do
          # One generate_secret_if_needed call serves both of the job's paths: it creates
          # the Secret, or patches in missing keys from the same arguments. Pinning the
          # argument pins what either path stores.
          job = HelmTemplate.new(base)
          expect(job.exit_code).to eq(0), "Unexpected error code #{job.exit_code} -- #{job.stderr}"

          controller = HelmTemplate.new(as_controller(base))
          expect(controller.exit_code).to eq(0), "Unexpected error code #{controller.exit_code} -- #{controller.stderr}"

          secrets = controller.resources_by_kind('GitLabSecrets').values.first['spec']['secrets']
          expected = secrets.each_with_object({}) do |secret, recipes|
            secret['generators'].select { |generator| generator['type'] == 'random' }.each do |generator|
              recipes[[secret['name'], generator['key']]] = random_job_value(generator)
            end
          end

          expect(expected).not_to be_empty
          expect(job_backend_literals(generate_secrets_script(job)).slice(*expected.keys)).to eq(expected)
        end
      end
    end
  end

  describe 'a custom secret name' do
    # Setting `secret` renames the Secret. It does not hand its contents to the user.
    # Both backends still fill it in, which is what lets an existing release pick up
    # secret fields added in a later chart version -- a new key inside the Rails
    # secrets.yml, for instance. Nothing is ever overwritten: the job patches in only
    # missing keys, and the controller is told `policy: fill-missing`.
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
          gitaly:
            authToken:
              secret: my-gitaly
          shell:
            authToken:
              secret: my-shell
      ))
    end

    it 'is what the job backend generates into' do
      template = HelmTemplate.new(values)
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

      script = generate_secrets_script(template)
      expect(script).to include('generate_secret_if_needed "my-gitaly"')
      expect(script).to include('generate_secret_if_needed "my-shell"')
      expect(script).not_to include('test-gitaly-secret')
    end

    it 'is what the GitLabSecrets resource names' do
      template = HelmTemplate.new(as_controller(values))
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

      names = template.resources_by_kind('GitLabSecrets').values.first['spec']['secrets'].map { |s| s['name'] }
      expect(names).to include('my-gitaly', 'my-shell')
      expect(names).not_to include('test-gitaly-secret')
    end
  end

  describe 'a user-supplied name or key that YAML would read as another type' do
    # gitlab.secrets.load parses the manifest with fromYamlArray, so a bare `0777` becomes
    # the integer 511 and a bare `null` becomes nothing. Each of these is a valid Secret
    # name or key except `~`, which is here as the other spelling of YAML null.
    retyped = %w[0777 null true yes on 1e3 ~ 1.0]

    # The value paths whose helpers return bare output. Every other name and key helper
    # the manifest uses already quotes its output.
    paths = [
      %w[global pages authSecret secret],
      %w[global oauth gitlab-pages secret],
      %w[global openbao httpAudit secret],
      %w[global pages authSecret key],
      %w[global oauth gitlab-pages appIdKey],
      %w[global oauth gitlab-pages appSecretKey],
      %w[global openbao httpAudit key],
      %w[global openbao unseal currentKeyField]
    ]

    # Passed with --set-string, as a user quoting them in values.yaml would. HelmTemplate
    # writes values with YAML.dump, which leaves `1e3` bare, and Helm reads that back as
    # the float 1000 before any template runs.
    def set_string_args(assigned)
      assigned.map { |path, value| "--set-string #{Shellwords.escape("#{path.join('.')}=#{value}")}" }.join(' ')
    end

    def retyped_values
      HelmTemplate.with_defaults(%(
        global:
          pages:
            enabled: true
            accessControl: true
          openbao:
            enabled: true
            psql:
              host: openbao-db.example.com
              password:
                secret: openbao-db-password
        openbao:
          install: true
          config:
            unseal:
              static:
                enabled: true
      ))
    end

    # (secret, key, --from-* source) the job has to pass, in the order of `paths`.
    def expected_arguments(assigned)
      auth_secret, oauth_secret, audit_secret, auth_key, app_id_key, app_secret_key, audit_key, unseal_key = assigned.values
      [
        [auth_secret, auth_key, 'literal'],
        [oauth_secret, app_id_key, 'literal'],
        [oauth_secret, app_secret_key, 'literal'],
        [audit_secret, audit_key, 'literal'],
        ['test-openbao-unseal', unseal_key, 'file']
      ]
    end

    # Rotate the strings across the paths so every (path, string) pair is rendered once,
    # and no two Secret names in one render collide.
    retyped.each_index do |offset|
      assigned = paths.each_with_index.to_h { |path, index| [path, retyped[(offset + index) % retyped.size]] }

      context "with #{assigned.values.first.inspect} as the Pages auth secret name" do
        it 'passes the exact string to the job, unquoted inside the argument' do
          template = HelmTemplate.new(retyped_values, 'test', set_string_args(assigned))
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

          script = generate_secrets_script(template)
          expected_arguments(assigned).each do |secret, key, source|
            call = /^generate_secret_if_needed "#{Regexp.escape(secret)}" .*--from-#{source}=#{Regexp.escape(key)}=/
            expect(script).to match(call)
          end

          assigned.each_value do |string|
            expect(script).not_to include(%(\\"#{string}\\"), %(""#{string}""), %("\\"#{string}), %(="#{string}"=))
          end
        end

        it 'gives the GitLabSecrets resource the same strings' do
          template = HelmTemplate.new(as_controller(retyped_values), 'test', set_string_args(assigned))
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

          pairs = controller_backend_pairs(template.resources_by_kind('GitLabSecrets').values.first)
          expected_arguments(assigned).each do |secret, key, _|
            expect(pairs).to include([secret, key])
          end

          pairs.flatten.each do |string|
            expect(string).to be_a(String)
            expect(string).not_to start_with('"')
          end
        end
      end
    end

    it 'does not quote twice what a quoting helper returns' do
      values = HelmTemplate.with_defaults(%(
        global:
          gitaly:
            authToken:
              secret: "0777"
              key: "null"
      ))

      job = HelmTemplate.new(values)
      expect(job.exit_code).to eq(0), "Unexpected error code #{job.exit_code} -- #{job.stderr}"
      expect(generate_secrets_script(job)).to include('generate_secret_if_needed "0777" --from-literal=null=')

      controller = HelmTemplate.new(as_controller(values))
      expect(controller.exit_code).to eq(0), "Unexpected error code #{controller.exit_code} -- #{controller.stderr}"
      expect(controller_backend_pairs(controller.resources_by_kind('GitLabSecrets').values.first))
        .to include(%w[0777 null])
    end
  end

  describe 'shared-secrets.enabled: false' do
    %w[job controller].each do |provider|
      it "renders nothing with provider #{provider}" do
        values = HelmTemplate.with_defaults(%(
          shared-secrets:
            enabled: false
            provider: #{provider}
        ))
        template = HelmTemplate.new(values)
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        expect(template.resources_by_kind('GitLabSecrets')).to be_empty
        expect(template.resource_exists?('ConfigMap/test-shared-secrets')).to be false
        expect(template.resources('shared-secrets').grep(/^Job/)).to be_empty
      end
    end
  end

  describe 'provider validation' do
    it 'rejects an unknown provider' do
      values = HelmTemplate.with_defaults(%(
        shared-secrets:
          provider: sealed-secrets
      ))
      template = HelmTemplate.new(values)

      expect(template.exit_code).not_to eq(0)
      expect(template.stderr).to include('shared-secrets: unknown provider')
    end

    it 'accepts provider: controller with no certificate configured' do
      # The controller requests the self-signed certificate through spec.certificates,
      # so nothing extra needs configuring.
      template = HelmTemplate.new(as_controller(HelmTemplate.with_defaults('{}')))
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
    end
  end

  describe 'the certificates section' do
    def certificates(extra)
      template = HelmTemplate.new(as_controller(HelmTemplate.with_defaults(extra)))
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      template.resources_by_kind('GitLabSecrets').values.first.dig('spec', 'certificates')
    end

    it 'requests the wildcard certificate and its two companions' do
      certs = certificates('{}')
      expect(certs.length).to eq(1)

      entry = certs.first
      expect(entry['tlsSecret']).to eq('test-wildcard-tls')
      expect(entry['caSecret']).to eq('test-wildcard-tls-ca')
      expect(entry['caKey']).to eq('cfssl_ca')
      expect(entry['chainSecret']).to eq('test-wildcard-tls-chain')
      expect(entry.dig('authority', 'keySize')).to be_a(Integer)
    end

    {
      'cert-manager is configured' => %(
        global:
          ingress:
            configureCertmanager: true
      ),
      'a certificate is supplied' => %(
        global:
          ingress:
            tls:
              secretName: my-wildcard-tls
      ),
      'TLS is disabled' => %(
        global:
          ingress:
            tls:
              enabled: false
      )
    }.each do |name, extra|
      it "omits the certificate when #{name}" do
        expect(certificates(extra)).to be_nil
      end
    end

    it 'is requested by exactly one backend at a time' do
      # Under `job` the self-signed certificate Job does the work, so the resource must
      # not also ask a controller for it, and vice versa.
      job = HelmTemplate.new(HelmTemplate.with_defaults('{}'))
      expect(job.resources('shared-secrets').grep(/selfsign/)).not_to be_empty

      controller = HelmTemplate.new(as_controller(HelmTemplate.with_defaults('{}')))
      expect(controller.resources('shared-secrets').grep(/selfsign/)).to be_empty
    end
  end

  describe 'manifest validation' do
    # charset must reach both backends explicitly. If the chart defaulted it, the
    # GitLabSecrets resource would omit the field and the controller would pick its own.
    it 'refuses a random generator with no charset' do
      # Rendered by mutating the manifest is not possible from a spec, so assert the
      # guard exists and that every shipped entry satisfies it.
      manifest = File.read('templates/shared-secrets/_manifest.tpl')
      expect(manifest).to include('must set a charset')
    end

    it 'gives every random generator an explicit charset' do
      manifest = File.read('templates/shared-secrets/_manifest.tpl')
      bodies = manifest.scan(/- type: random\n(.*?)(?=\n\s*- type:|\n\n|\Z)/m).flatten

      expect(bodies).not_to be_empty
      expect(bodies).to all(include('charset:'))
    end

    # `base64` is standard base64 with no wrapping and no newline under both backends.
    # The job's recipe for it is pinned in 'the two backends stay in step'.
    value_matrix.each do |name, extra|
      it "gives every random generator an encoding of none or base64 with #{name}" do
        template = HelmTemplate.new(as_controller(HelmTemplate.with_defaults(extra)))
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        encodings = template.resources_by_kind('GitLabSecrets').values.first['spec']['secrets']
                            .flat_map { |secret| secret['generators'] }
                            .select { |generator| generator['type'] == 'random' }
                            .map { |generator| generator['encoding'] }

        expect(encodings).to include('base64')
        expect(encodings).to all(be_nil.or(eq('none')).or(eq('base64')))
      end
    end
  end

  describe 'conditional entries' do
    {
      'test-gitlab-kas-secret' => 'global.kas.enabled',
      'test-gitlab-pages-secret' => 'global.pages.enabled',
      'test-praefect-secret' => 'global.praefect.enabled'
    }.each do |secret_name, flag|
      it "omits #{secret_name} unless #{flag} is set" do
        off = HelmTemplate.new(HelmTemplate.with_defaults(%(
          global:
            kas:
              enabled: false
            pages:
              enabled: false
            praefect:
              enabled: false
        )))
        expect(off.exit_code).to eq(0), "Unexpected error code #{off.exit_code} -- #{off.stderr}"
        expect(generate_secrets_script(off)).not_to include(secret_name)
      end
    end

    it 'includes them all when every flag is set' do
      template = HelmTemplate.new(all_features)
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

      script = generate_secrets_script(template)
      expect(script).to include('test-gitlab-kas-secret')
      expect(script).to include('test-gitlab-pages-secret')
      expect(script).to include('test-praefect-secret')
    end

    it 'omits the praefect database password when an external database is configured' do
      template = HelmTemplate.new(HelmTemplate.with_defaults(%(
        global:
          praefect:
            enabled: true
            psql:
              host: db.example.com
      )))
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

      script = generate_secrets_script(template)
      expect(script).to include('test-praefect-secret')
      expect(script).not_to include('test-praefect-dbsecret')
    end
  end
end
