require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

# Only the registry still runs a `configure` init container.
describe 'configure init container' do
  let(:template) do
    HelmTemplate.new(HelmTemplate.with_defaults(%(
      global:
        appConfig:
          incomingEmail:
            enabled: true
            password:
              secret: mailroom-password
        pages:
          enabled: true
        geo:
          enabled: true
          role: secondary
          psql:
            host: geo.db.example.com
            password:
              secret: geo-psql
              key: password
      gitlab:
        toolbox:
          backups:
            cron:
              enabled: true
          databaseReindex:
            cron:
              enabled: true
    )))
  end

  it 'is only rendered for the registry' do
    expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

    pods = %w[Deployment StatefulSet Job CronJob].flat_map { |kind| template.resources_by_kind(kind).to_a }
    with_configure = pods.filter_map do |name, resource|
      spec = resource.dig('spec', 'template', 'spec') || resource.dig('spec', 'jobTemplate', 'spec', 'template', 'spec')
      name if (spec['initContainers'] || []).any? { |c| c['name'] == 'configure' }
    end
    scripts = template.resources_by_kind('ConfigMap').select { |_, cm| cm['data']&.key?('configure') }.keys

    expect(pods.length).to be > 10
    expect(with_configure.reject { |name| name.start_with?('Deployment/test-registry', 'Job/test-registry-migrations') }).to be_empty
    expect(scripts).to be_empty
  end
end
