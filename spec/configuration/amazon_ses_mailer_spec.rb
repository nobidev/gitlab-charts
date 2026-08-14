require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Amazon SES Mailer configuration' do
  let(:charts_with_ses) do
    [
      'webservice',
      'sidekiq',
      'toolbox'
    ]
  end

  let(:charts_with_ses_init_secret_mounts) do
    {
      'test-sidekiq-all-in-1-v2' => 'init-sidekiq-secrets',
      'test-webservice-default' => 'init-webservice-secrets',
      'test-toolbox' => 'init-toolbox-secrets'
    }
  end

  let(:values) do
    HelmTemplate.with_defaults(%(
        global:
          appConfig:
            amazon_ses_mailer:
              enabled: true
              region: "us-east-1"
              role_arn: "arn:aws:iam::123456789012:role/ses-mailer"
              access_key_id: "AKIAEXAMPLE"
              secret_access_key:
                secret: amazon-ses-mailer-secret-access-key
                key: secret_access_key
    ))
  end

  let(:template) { HelmTemplate.new(values) }

  it 'populates amazon_ses_mailer to gitlab.yml', :aggregate_failures do
    expect(template.exit_code).to eq(0)
    charts_with_ses.each do |chart|
      gitlab_yml_erb = template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb')
      expect(gitlab_yml_erb).to include(%(secret_access_key: <%= File.read('/etc/gitlab/amazon_ses_mailer/secret_access_key').strip.to_json %>))
      amazon_ses_mailer = YAML.safe_load(gitlab_yml_erb)['production']['amazon_ses_mailer']
      expect(amazon_ses_mailer['enabled']).to be(true)
      expect(amazon_ses_mailer['region']).to eq('us-east-1')
      expect(amazon_ses_mailer['role_arn']).to eq('arn:aws:iam::123456789012:role/ses-mailer')
      expect(amazon_ses_mailer['access_key_id']).to eq('AKIAEXAMPLE')

      # check that the configure script includes `amazon_ses_mailer`
      configure = template.dig("ConfigMap/test-#{chart}", 'data', 'configure')
      expect(configure).to match(/# optional\nfor secret in .* amazon_ses_mailer .*; do/m)
    end
  end

  it 'populates amazon-ses-mailer-secret-access-key into deployments' do
    charts_with_ses_init_secret_mounts.each do |deployment, mount|
      expect(template.find_projected_secret("Deployment/#{deployment}", mount, 'amazon-ses-mailer-secret-access-key')).to be true
    end
  end

  describe "when toolbox backup cronjob is enabled" do
    let(:values_with_backup_cronjob) do
      YAML.safe_load(%(
        gitlab:
          toolbox:
            backups:
              cron:
                enabled: true
      )).deep_merge(values)
    end

    let(:template) { HelmTemplate.new(values_with_backup_cronjob) }

    it 'populates amazon-ses-mailer-secret-access-key into cronjob' do
      job_template_spec = template.dig('CronJob/test-toolbox-backup', 'spec', 'jobTemplate')
      job_pod_volumes = job_template_spec.dig('spec', 'template', 'spec', 'volumes')
      init_secret = job_pod_volumes.find { |s| s['name'] == 'init-toolbox-secrets' }
      secret_names = init_secret["projected"]["sources"].map do |item|
        item['secret']['name']
      end
      expect(secret_names).to include('amazon-ses-mailer-secret-access-key')
    end
  end

  describe "when toolbox database-reindex cronjob is enabled" do
    let(:values_with_reindex_cronjob) do
      YAML.safe_load(%(
        gitlab:
          toolbox:
            databaseReindex:
              cron:
                enabled: true
      )).deep_merge(values)
    end

    let(:template) { HelmTemplate.new(values_with_reindex_cronjob) }

    it 'populates amazon-ses-mailer-secret-access-key into cronjob' do
      job_template_spec = template.dig('CronJob/test-toolbox-db-reindex', 'spec', 'jobTemplate')
      job_pod_volumes = job_template_spec.dig('spec', 'template', 'spec', 'volumes')
      init_secret = job_pod_volumes.find { |s| s['name'] == 'init-toolbox-secrets' }
      secret_names = init_secret["projected"]["sources"].map do |item|
        item['secret']['name']
      end
      expect(secret_names).to include('amazon-ses-mailer-secret-access-key')
    end
  end

  describe 'when using an IAM role without static credentials' do
    let(:values) do
      HelmTemplate.with_defaults(%(
          global:
            appConfig:
              amazon_ses_mailer:
                enabled: true
                region: "us-east-1"
                role_arn: "arn:aws:iam::123456789012:role/ses-mailer"
      ))
    end

    it 'omits access_key_id and secret_access_key from gitlab.yml', :aggregate_failures do
      expect(template.exit_code).to eq(0)
      gitlab_yml_erb = template.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb')
      amazon_ses_mailer = YAML.safe_load(gitlab_yml_erb)['production']['amazon_ses_mailer']
      expect(amazon_ses_mailer['enabled']).to be(true)
      expect(amazon_ses_mailer['region']).to eq('us-east-1')
      expect(amazon_ses_mailer).not_to have_key('access_key_id')
      expect(amazon_ses_mailer).not_to have_key('secret_access_key')
    end
  end

  describe 'when region is not set' do
    let(:values) do
      HelmTemplate.with_defaults(%(
          global:
            appConfig:
              amazon_ses_mailer:
                enabled: true
      ))
    end

    it 'omits region from gitlab.yml so the AWS SDK can resolve it', :aggregate_failures do
      expect(template.exit_code).to eq(0)
      gitlab_yml_erb = template.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb')
      amazon_ses_mailer = YAML.safe_load(gitlab_yml_erb)['production']['amazon_ses_mailer']
      expect(amazon_ses_mailer['enabled']).to be(true)
      expect(amazon_ses_mailer).not_to have_key('region')
    end
  end
end
