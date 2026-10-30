# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'
require 'shellwords'

# Each example renders the chart once and makes all of its checks against that render,
# since every `it` would otherwise run its own `helm template`.
describe 'AI Gateway configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      ai-gateway:
        install: true
    ))
  end

  let(:values) { default_values }
  let(:extra_args) { '' }
  let(:template) { HelmTemplate.new(values, 'test', extra_args) }

  let(:default_key_refs) do
    {
      'AIGW_SELF_SIGNED_JWT__SIGNING_KEY' => %w[test-ai-gateway-aigw-signing-secret aigwSigningKey],
      'AIGW_SELF_SIGNED_JWT__VALIDATION_KEY' => %w[test-ai-gateway-aigw-validation-secret aigwValidationKey],
      'DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY' => %w[test-ai-gateway-duo-workflow-signing-secret duoWorkflowSigningKey],
      'DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY' => %w[test-ai-gateway-duo-workflow-validation-secret duoWorkflowValidationKey]
    }
  end

  def expect_rendered(template)
    expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
  end

  def config(template)
    template.dig('ConfigMap/test-ai-gateway', 'data')
  end

  # The (secret, key) pair each JWT key environment variable reads, keyed by variable name.
  def key_refs(template)
    template.env('Deployment/test-ai-gateway', 'ai-gateway')
            .select { |env| env['name'].include?('SELF_SIGNED_JWT') }
            .to_h { |env| [env['name'], env['valueFrom']['secretKeyRef'].values_at('name', 'key')] }
  end

  def generate_secrets_script(template)
    template.dig('ConfigMap/test-shared-secrets', 'data', 'generate-secrets')
  end

  describe 'GitLab URL' do
    context 'with defaults' do
      it 'uses the GitLab URL from global.hosts', :aggregate_failures do
        expect_rendered(template)
        expect(config(template)).to include(
          'AIGW_GITLAB_URL' => 'https://gitlab.example.com',
          'AIGW_GITLAB_API_URL' => 'https://gitlab.example.com/api/v4',
          'DUO_WORKFLOW_AUTH__OIDC_GITLAB_URL' => 'https://gitlab.example.com'
        )
      end
    end

    context 'with ai-gateway.gitlab.url set' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          ai-gateway:
            gitlab:
              url: https://gitlab.internal.example.com/
        )))
      end

      it 'uses it over global.hosts, and derives the API URL from it', :aggregate_failures do
        expect_rendered(template)
        expect(config(template)).to include(
          'AIGW_GITLAB_URL' => 'https://gitlab.internal.example.com/',
          'AIGW_GITLAB_API_URL' => 'https://gitlab.internal.example.com/api/v4',
          'DUO_WORKFLOW_AUTH__OIDC_GITLAB_URL' => 'https://gitlab.internal.example.com/'
        )
      end
    end

    context 'with ai-gateway.gitlab.url and ai-gateway.gitlab.apiUrl set' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          ai-gateway:
            gitlab:
              url: https://gitlab.internal.example.com
              apiUrl: https://api.internal.example.com/api/v4
        )))
      end

      it 'uses both', :aggregate_failures do
        expect_rendered(template)
        expect(config(template)).to include(
          'AIGW_GITLAB_URL' => 'https://gitlab.internal.example.com',
          'AIGW_GITLAB_API_URL' => 'https://api.internal.example.com/api/v4'
        )
      end
    end
  end

  describe 'JWT key secrets' do
    context 'with defaults' do
      it 'reads and generates the chart-generated secrets, and renders no subchart jwt-keys secret', :aggregate_failures do
        expect_rendered(template)
        expect(key_refs(template)).to eq(default_key_refs)

        script = generate_secrets_script(template)
        default_key_refs.each_value do |secret, key|
          expect(script).to match(/^generate_secret_if_needed "#{secret}" --from-file=#{key}=/)
        end

        expect(template.resource_exists?('Secret/test-ai-gateway-jwt-keys')).to be false
      end
    end

    context 'with user-supplied secrets' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          ai-gateway:
            aigwSigningKey:
              secret: my-aigw-signing
              key: signing.key
            aigwValidationKey:
              secret: my-aigw-validation
              key: validation.key
            duoWorkflowSigningKey:
              secret: my-duo-workflow-signing
              key: signing.key
            duoWorkflowValidationKey:
              secret: my-duo-workflow-validation
              key: validation.key
        )))
      end

      let(:custom_key_refs) do
        {
          'AIGW_SELF_SIGNED_JWT__SIGNING_KEY' => %w[my-aigw-signing signing.key],
          'AIGW_SELF_SIGNED_JWT__VALIDATION_KEY' => %w[my-aigw-validation validation.key],
          'DUO_WORKFLOW_SELF_SIGNED_JWT__SIGNING_KEY' => %w[my-duo-workflow-signing signing.key],
          'DUO_WORKFLOW_SELF_SIGNED_JWT__VALIDATION_KEY' => %w[my-duo-workflow-validation validation.key]
        }
      end

      # Setting `secret` renames the Secret, as everywhere else in the chart. The job
      # leaves an existing Secret alone and only creates one that is missing.
      it 'reads them, and generates into them instead of the default names', :aggregate_failures do
        expect_rendered(template)
        expect(key_refs(template)).to eq(custom_key_refs)

        script = generate_secrets_script(template)
        custom_key_refs.each_value do |secret, key|
          expect(script).to match(/^generate_secret_if_needed "#{secret}" --from-file=#{Regexp.escape(key)}=/)
        end
        default_key_refs.each_value do |secret, _|
          expect(script).not_to include(secret)
        end
      end

      it 'names them in the GitLabSecrets resource', :aggregate_failures do
        controller = HelmTemplate.new(values.deep_merge(YAML.safe_load(%(
          shared-secrets:
            provider: controller
        ))))
        expect_rendered(controller)

        names = controller.resources_by_kind('GitLabSecrets').values.first['spec']['secrets'].map { |s| s['name'] }
        expect(names).to include(*custom_key_refs.values.map(&:first))
      end
    end

    context 'with only a secret name set' do
      let(:values) do
        default_values.deep_merge(YAML.safe_load(%(
          ai-gateway:
            aigwSigningKey:
              secret: my-aigw-signing
        )))
      end

      it 'keeps the default key, and the defaults for the other secrets', :aggregate_failures do
        expect_rendered(template)
        expect(key_refs(template)).to eq(
          default_key_refs.merge('AIGW_SELF_SIGNED_JWT__SIGNING_KEY' => %w[my-aigw-signing aigwSigningKey])
        )
      end
    end

    context 'with a secret name YAML would read as another type' do
      let(:extra_args) do
        "--set-string #{Shellwords.escape('ai-gateway.aigwSigningKey.secret=0777')}"
      end

      it 'keeps the name a string', :aggregate_failures do
        expect_rendered(template)
        expect(key_refs(template)['AIGW_SELF_SIGNED_JWT__SIGNING_KEY']).to eq(%w[0777 aigwSigningKey])
        expect(generate_secrets_script(template)).to include('generate_secret_if_needed "0777"')
      end
    end
  end
end
