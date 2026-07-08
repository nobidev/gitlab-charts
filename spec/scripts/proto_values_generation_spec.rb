# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'open3'

# Validates the committed proto-derived values artifacts (see
# doc/development/validation.md and scripts/generate-values.sh). The full
# regenerate-and-diff drift check runs in CI, where buf is available; these
# specs assert the properties of the committed output without regenerating, so
# they do not require buf or network access.
describe 'proto-derived chart values' do
  root = File.expand_path('../..', __dir__)

  describe 'generated Go module (operator-importable types)' do
    it 'compiles with go build' do
      pkg = File.join(root, 'pkg', 'values')
      skip 'Go toolchain not available' unless system('which go > /dev/null 2>&1')

      _out, err, status = Open3.capture3('go', 'build', './...', chdir: pkg)

      expect(status.success?).to be(true), "go build failed:\n#{err}"
    end
  end

  describe 'out/values.schema.json' do
    schema = JSON.parse(File.read(File.join(root, 'out', 'values.schema.json')))
    defs = schema.fetch('$defs')

    def props(defs, message)
      defs.fetch("charts.values.v1.#{message}.schema.strict.json").fetch('properties')
    end

    it 'declares JSON Schema Draft 2020-12 and roots at GitLabValues' do
      expect(schema['$schema']).to eq('https://json-schema.org/draft/2020-12/schema')
      expect(schema['$ref']).to eq('#/$defs/charts.values.v1.GitLabValues.schema.strict.json')
    end

    it 'covers the in-repo sub-charts and top-level chart concerns' do
      expect(props(defs, 'GitLabServices').keys).to include(
        'gitaly', 'praefect', 'gitlab-shell', 'webservice', 'sidekiq', 'kas',
        'gitlab-pages', 'gitlab-exporter', 'geo-logcursor', 'mailroom',
        'migrations', 'toolbox'
      )
      expect(props(defs, 'GitLabValues').keys).to include(
        'gitlab', 'global', 'registry', 'certmanager-issuer', 'upgradeCheck',
        'shared-secrets', 'gatewayApiResources', 'installCertmanager'
      )
    end

    it 'applies the camelCase helm_naming convention to property keys' do
      # global.hosts uses camelCase keys derived from snake_case proto fields.
      expect(props(defs, 'GlobalHosts').keys).to include('hostSuffix', 'externalIP')
    end

    it 'honours field-level helm_name overrides (hyphenated and snake_case keys)' do
      # Hyphenated Helm keys a naming convention cannot express.
      expect(props(defs, 'GitLabServices')).to have_key('gitlab-shell')
      expect(props(defs, 'GitLabValues')).to have_key('certmanager-issuer')
      # snake_case keys preserved verbatim (Rails-style appConfig settings).
      expect(props(defs, 'GlobalAppConfig').keys).to include('object_store', 'cron_jobs')
    end

    it 'maps buf.validate constraints to JSON Schema keywords' do
      port = props(defs, 'GlobalPsql').fetch('port')
      expect(port['minimum']).to eq(1)
      expect(port['maximum']).to eq(65_535)

      expect(props(defs, 'GlobalConfig').dig('edition', 'enum')).to contain_exactly('ce', 'ee')
    end

    it 'surfaces lifecycle_stage annotations as a vendor extension' do
      expect(props(defs, 'GitalyMetrics').dig('metricsPort', 'x-gitlab-lifecycle-stage'))
        .to eq('deprecated')
      expect(props(defs, 'RegistryDatabase').dig('loadBalancing', 'x-gitlab-lifecycle-stage'))
        .to eq('experimental')
    end

    it 'makes optional fields nullable so empty (default-filled) keys validate' do
      expect(props(defs, 'GlobalPsql').dig('port', 'type')).to include('null')
    end

    it 'keeps additionalProperties:false on modeled messages to catch typos' do
      psql = defs.fetch('charts.values.v1.GlobalPsql.schema.strict.json')
      expect(psql['additionalProperties']).to be(false)
    end

    it 'allows bundled external sub-charts as unchecked passthrough at the root' do
      expect(props(defs, 'GitLabValues').keys)
        .to include('prometheus', 'nginx-ingress', 'gitlab-runner', 'gitlab-zoekt', 'openbao')
    end

    it 'derives required only from buf.validate, not proto-strict presence' do
      # No field is annotated `(buf.validate.field).required` yet, so no modeled
      # message declares a `required` array. Unconditional requirements are added
      # in the proto; cross-field ones stay in protovalidate (see check-config).
      with_required = defs.values.count { |d| d.is_a?(Hash) && d.key?('required') }
      expect(with_required).to eq(0)
    end
  end
end
