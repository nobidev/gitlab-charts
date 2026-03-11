require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Knowledge Graph configuration' do
  let(:enabled_values) do
    HelmTemplate.with_defaults(%(
      global:
        appConfig:
          knowledgeGraph:
            enabled: true
            jwtSecret:
              secret: test-kg-secret
              key: test-kg-key
            grpcEndpoint: "gkg.example.com:50054"
    ))
  end

  let(:disabled_values) { HelmTemplate.with_defaults({}) }

  context 'when enabled' do
    let(:template) { HelmTemplate.new(enabled_values) }

    it 'renders knowledge_graph in gitlab.yml', :aggregate_failures do
      expect(template.exit_code).to eq(0)

      gitlab_yml_erb = template.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb')
      gitlab_yml = YAML.safe_load(gitlab_yml_erb)
      kg = gitlab_yml['production']['knowledge_graph']

      expect(kg).not_to be_nil
      expect(kg['enabled']).to be(true)
      expect(kg['grpc_endpoint']).to eq('gkg.example.com:50054')
    end

    it 'mounts the jwt secret on webservice deployment', :aggregate_failures do
      secret = template.get_projected_secret(
        'Deployment/test-webservice-default',
        'init-webservice-secrets',
        'test-kg-secret'
      )

      expect(secret).not_to be_nil
      expect(secret['items'][0]['key']).to eq('test-kg-key')
      expect(secret['items'][0]['path']).to eq('knowledge_graph/.gitlab_knowledge_graph_secret')
    end
  end

  context 'when disabled' do
    let(:template) { HelmTemplate.new(disabled_values) }

    it 'does not render knowledge_graph in gitlab.yml' do
      expect(template.exit_code).to eq(0)

      gitlab_yml_erb = template.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb')
      gitlab_yml = YAML.safe_load(gitlab_yml_erb)

      expect(gitlab_yml['production']['knowledge_graph']).to be_nil
    end

    it 'does not mount the jwt secret' do
      has_secret = template.find_projected_secret(
        'Deployment/test-webservice-default',
        'init-webservice-secrets',
        'test-kg-secret'
      )

      expect(has_secret).to be(false)
    end
  end
end
