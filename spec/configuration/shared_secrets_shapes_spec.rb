# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'fileutils'
require 'yaml'
require 'hash_deep_merge'

# Reads the value *shapes* back out of the rendered shared-secrets script.
#
# Deliberately self-contained rather than sharing helpers with shared_secrets_spec.rb:
# this is a stacked change, and a shared helper would conflict the moment either file
# moves. Every extractor below raises rather than skipping what it does not recognise --
# an unfamiliar spelling in _manifest_shell.tpl is exactly the drift worth failing on,
# and silently dropping it would leave the fixture looking unchanged.
module SecretShapes
  # `tr` character classes, as gitlab.secrets.shell.charset spells them.
  CHARSETS = {
    'a-zA-Z0-9' => 'alphanumeric',
    'a-f0-9' => 'hex',
    'a-z0-9' => 'lowerAlphanumeric'
  }.freeze

  # A `random` generator's command substitution, with its optional base64 pipe.
  GEN_RANDOM = /\$\(gen_random '(?<charset>[^']+)' (?<length>\d+)(?<pipe>[^)]*)\)/
  RANDOM_VALUE = /\A#{GEN_RANDOM}\z/
  WRAPPED_VALUE = /\A\[\\"#{GEN_RANDOM}\\"\]\z/
  BYTES_VALUE = /\A\$\(gen_random_base64 (?<length>\d+)\)\z/
  STATIC_VALUE = /\A(?<value>".*")\z/

  # Prepare steps. Each names the scratch file a --from-file argument later reads, which
  # is how a --from-file is classified back to the generator type that produced it.
  X509_PREPARE = %r{^openssl req -new -newkey rsa:(?<bits>\d+) -subj "/CN=(?<cn>[^"]*)".*-keyout (?<key_file>\S+) -out (?<cert_file>\S+) -days (?<days>\d+)$}
  RSA_PREPARE = /^openssl genrsa -out (?<file>\S+) (?<bits>\d+)$/
  BYTES_PREPARE = /^gen_random_bytes (?<length>\d+) > (?<file>\S+)$/

  # The railsSecrets fields, from the "Generate defaults" block.
  RAILS_SCALAR = /^  (?<path>\w+)="\$\{\k<path>:-#{GEN_RANDOM}\}"(?: #.*)?$/
  RAILS_PEM = /^  (?<path>\w+)="\$\{\k<path>:-\$\(openssl genrsa (?<bits>\d+)\)\}"$/
  RAILS_LIST = /^  (?<path>\w+)=\$\{\k<path>:-"- #{GEN_RANDOM}"\}$/

  RAILS_DEFAULTS_BLOCK = /# Generate defaults for any unset secrets\n(.*?)\n\n/m

  module_function

  # One sorted line per (secret, key), so the fixture is stable across renders and a
  # diff reads as one line per changed key.
  def extract(script)
    shapes = prepare_shapes(script)
    (generated_shapes(script, shapes) + rails_shapes(script)).sort
  end

  def charset_name(klass)
    CHARSETS.fetch(klass) do
      raise "unrecognised tr character class #{klass.inspect}. If a charset was added " \
        'to gitlab.secrets.shell.charset, teach CHARSETS about it.'
    end
  end

  def encoding_name(pipe)
    case pipe
    when '' then nil
    when ' | base64' then 'base64'
    when ' | base64 -w 0' then 'base64-nowrap'
    else
      raise "unrecognised encoding pipe #{pipe.inspect} in a gen_random substitution"
    end
  end

  # Charset, length and encoding of a `random` generator, as fixture fields.
  def random_fields(match)
    fields = ["charset=#{charset_name(match[:charset])}", "length=#{match[:length]}"]
    encoding = encoding_name(match[:pipe])
    fields << "encoding=#{encoding}" if encoding
    fields
  end

  # Maps every scratch file named by a prepare step to the shape of what it will hold.
  def prepare_shapes(script)
    shapes = {}

    script.scan(X509_PREPARE) do
      match = Regexp.last_match
      common = "x509 bits=#{match[:bits]} cn=#{match[:cn]} days=#{match[:days]}"
      shapes[match[:key_file]] = "#{common} role=key"
      shapes[match[:cert_file]] = "#{common} role=cert"
    end

    script.scan(RSA_PREPARE) do
      match = Regexp.last_match
      shapes[match[:file]] = "rsa bits=#{match[:bits]}"
    end

    script.scan(BYTES_PREPARE) do
      match = Regexp.last_match
      shapes[match[:file]] = "bytes encoding=raw length=#{match[:length]}"
    end

    shapes
  end

  # Every secret created through generate_secret_if_needed.
  def generated_shapes(script, shapes)
    script.scan(/^generate_secret_if_needed\s+(\S+)(.*)$/).flat_map do |name, arguments|
      secret = name.delete('"')
      tokens = arguments.strip.split(/\s+(?=--from-)/)
      raise "#{secret} is created with no --from-* arguments" if tokens.empty?

      tokens.map do |token|
        key, shape = argument_shape(token, shapes)
        "#{secret}/#{key}: #{shape}"
      end
    end
  end

  # One kubectl argument -> [key, shape].
  def argument_shape(argument, shapes)
    case argument
    when /\A--from-file host_keys\z/
      ['host_keys', 'sshHostKeys']
    when /\A--from-file=(?<key>[^=\s]+)=(?<file>\S+)\z/
      match = Regexp.last_match
      shape = shapes.fetch(match[:file]) do
        raise "--from-file reads #{match[:file].inspect}, which no prepare step creates"
      end
      [match[:key], shape]
    when /\A--from-literal=(?<key>[^=\s]+)=(?<value>.*)\z/m
      match = Regexp.last_match
      [match[:key], literal_shape(match[:value])]
    else
      raise "unrecognised kubectl argument #{argument.inspect}"
    end
  end

  def literal_shape(value)
    case value
    when RANDOM_VALUE
      (['random'] + random_fields(Regexp.last_match)).join(' ')
    when WRAPPED_VALUE
      (['random'] + random_fields(Regexp.last_match) + ['wrap=jsonArray']).join(' ')
    when BYTES_VALUE
      "bytes encoding=base64 length=#{Regexp.last_match[:length]}"
    when STATIC_VALUE
      "static value=#{Regexp.last_match[:value]}"
    else
      raise "unrecognised generated value #{value.inspect}. A new generator spelling " \
        'in _manifest_shell.tpl needs a matching shape here.'
    end
  end

  # The Rails secret, which is applied with `kubectl apply` rather than
  # generate_secret_if_needed because it merges into whatever already exists. Its fields
  # are keyed `<secret>/<key>[<field path>]` so they sort together under their secret.
  def rails_shapes(script)
    name = script[/^\s*rails_secret=(\S+)$/, 1]
    raise 'no rails_secret= assignment found in the rendered script' unless name

    secret = name.delete('"')
    key = script[/^\s{2}(\S+): \|-$/, 1]
    raise 'the railsSecrets stringData key was not found in the rendered script' unless key

    block = script[RAILS_DEFAULTS_BLOCK, 1]
    raise 'the railsSecrets defaults block is missing from the rendered script' if block.nil?

    block.lines.map(&:chomp).reject(&:empty?).map do |line|
      path, shape = rails_field_shape(line)
      "#{secret}/#{key}[#{path}]: #{shape}"
    end
  end

  def rails_field_shape(line)
    case line
    when RAILS_PEM
      match = Regexp.last_match
      [match[:path], "rails-pem bits=#{match[:bits]}"]
    when RAILS_LIST
      match = Regexp.last_match
      [match[:path], (['rails-list'] + random_fields(match)).join(' ')]
    when RAILS_SCALAR
      match = Regexp.last_match
      [match[:path], (['rails-scalar'] + random_fields(match)).join(' ')]
    else
      raise "unrecognised railsSecrets field #{line.inspect}"
    end
  end
end

# A value-shape baseline for the generated secrets.
#
# shared_secrets_spec.rb pins *which* (secret, key) pairs exist, under both backends,
# across the flag matrix. Nothing there pins *what goes inside* them. An edit to
# _manifest.tpl that turns `charset: hex` into `alphanumeric`, changes a `length`, swaps
# `base64` for `base64 -w 0`, or drops a `jsonArray` wrap passes every existing spec:
# the pair set is unchanged, `manifest validation` only asserts that a charset is
# present rather than unchanged, and both projections read the same manifest, so they
# would drift together rather than disagree.
#
# That kind of change is close to invisible in production. Secrets are created once --
# generate_secret_if_needed never touches an existing Secret, and the controller is told
# `policy: fill-missing` -- so an existing install keeps whatever it was first given and
# the damage lands only on new installs, and on keys added to the manifest later. By
# then nobody is looking at the diff that caused it.
#
# Shapes are read out of the *rendered shell script*, not out of _manifest.tpl. Reading
# the manifest would skip _manifest_shell.tpl, so a projection bug -- the manifest
# saying `charset: hex` while the shell emits `a-zA-Z0-9` -- would pass unnoticed.
# Parsing the script covers the manifest and its shell projection in one assertion.
# Nothing random is captured: this snapshots the recipe, never a value.
#
# Expectations live in committed fixtures, one per flag combination, rather than as
# hand-written per-entry expectations. A new secret that only had to match a list
# someone remembered to extend would pass when they forgot, which is the exact failure
# mode being guarded against. A fixture turns a new or changed secret into a reviewable
# diff line in the merge request that caused it.
#
# To update the fixtures after an intentional manifest change:
#
#   UPDATE_FIXTURES=1 bundle exec rspec spec/configuration/shared_secrets_shapes_spec.rb
#
# then read the resulting diff and commit it alongside the manifest change.
describe 'shared-secrets value shapes' do
  fixture_dir = File.expand_path('../fixtures/secret_shapes', __dir__)

  # The same combinations shared_secrets_spec.rb uses for 'the two backends stay in
  # step', so that a "combination" means the same thing in both specs. One flat fixture
  # would make enabling a flag look like a regression.
  {
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
  }.each do |name, extra|
    context "with #{name}" do
      let(:template) { HelmTemplate.new(HelmTemplate.with_defaults(extra)) }
      let(:fixture) { File.join(fixture_dir, "#{name.tr(' ', '-')}.txt") }

      it 'generates the recorded value shapes' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        script = template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
        expect(script).not_to be_nil

        shapes = SecretShapes.extract(script)
        expect(shapes).not_to be_empty

        rendered = "#{shapes.join("\n")}\n"

        if ENV['UPDATE_FIXTURES']
          FileUtils.mkdir_p(fixture_dir)
          File.write(fixture, rendered)
        end

        expect(File.exist?(fixture)).to be(true),
                                        "#{fixture} is missing. Regenerate the fixtures " \
                                          'with UPDATE_FIXTURES=1 and review the diff.'
        # Read with an explicit encoding: the rendered string is UTF-8, and letting the
        # fixture pick up a US-ASCII default external encoding puts a distracting
        # encoding mismatch at the top of an otherwise readable diff.
        expect(rendered).to eq(File.read(fixture, encoding: 'UTF-8'))
      end
    end
  end

  it 'covers db_key_base, the value nothing else can replace' do
    # Belt and braces around the fixtures. If the railsSecrets extraction ever stopped
    # finding fields, a regenerated fixture would happily record their absence, and
    # db_key_base is the one value worth naming out loud: without it every encrypted
    # column in the database is unreadable. The threat being guarded is a committed
    # fixture that has lost them, so this asserts against the fixture on disk -- the
    # 'with defaults' context above already holds the render to that same file, and
    # re-rendering here would only buy a second `helm template` call.
    #
    # Read with an explicit encoding, for the same reason the comparison above does.
    recorded = File.read(File.join(fixture_dir, 'defaults.txt'), encoding: 'UTF-8')

    expect(recorded).to match(/\[db_key_base\]: rails-scalar charset=hex length=128$/)
    expect(recorded).to match(/\[openid_connect_signing_key\]: rails-pem bits=\d+$/)
  end
end
