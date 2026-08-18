require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'Mobile push configuration' do
  let(:deployments_with_mobile_push) do
    {
      'webservice' => 'Deployment/test-webservice-default',
      'sidekiq' => 'Deployment/test-sidekiq-all-in-1-v2',
      'toolbox' => 'Deployment/test-toolbox'
    }
  end

  context 'when the APNs auth key is configured' do
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
          appConfig:
            mobilePush:
              apns:
                authKey:
                  secret: gitlab-mobile-push-apns-auth-key
                  key: auth_key
                keyId: "ABC123DEFG"
                teamId: "DEF456GHIJ"
      ))
    end

    let(:template) { HelmTemplate.new(values) }

    it 'populates mobile_push into gitlab.yml and mounts the key', :aggregate_failures do
      expect(template.exit_code).to eq(0)

      deployments_with_mobile_push.each_key do |chart|
        gitlab_yml = YAML.safe_load(template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb'))
        apns = gitlab_yml['production']['mobile_push']['apns']
        expect(apns['auth_key_path']).to eq('/etc/gitlab/mobile_push/apns_auth_key.p8')
        expect(apns['key_id']).to eq('ABC123DEFG')
        expect(apns['team_id']).to eq('DEF456GHIJ')
        expect(apns).not_to have_key('topic')
      end

      deployments_with_mobile_push.each do |chart, deployment|
        item = template.find_projected_secret_key(
          deployment, "init-#{chart}-secrets", 'gitlab-mobile-push-apns-auth-key', 'auth_key'
        )
        expect(item).to eq('key' => 'auth_key', 'path' => 'mobile_push/apns_auth_key.p8')

        configure = template.dig("ConfigMap/test-#{chart}", 'data', 'configure')
        expect(configure).to include('mobile_push')
      end
    end

    context 'with a topic' do
      let(:values) do
        HelmTemplate.with_defaults(%(
          global:
            appConfig:
              mobilePush:
                apns:
                  authKey:
                    secret: gitlab-mobile-push-apns-auth-key
                  keyId: "ABC123DEFG"
                  teamId: "DEF456GHIJ"
                  topic: "com.example.app"
        ))
      end

      it 'renders the topic', :aggregate_failures do
        expect(template.exit_code).to eq(0)

        gitlab_yml = YAML.safe_load(template.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb'))
        expect(gitlab_yml['production']['mobile_push']['apns']['topic']).to eq('com.example.app')
      end
    end

    context 'with a whitespace-only topic and padded key ID' do
      let(:values) do
        HelmTemplate.with_defaults(%(
          global:
            appConfig:
              mobilePush:
                apns:
                  authKey:
                    secret: gitlab-mobile-push-apns-auth-key
                  keyId: "  ABC123DEFG  "
                  teamId: "DEF456GHIJ"
                  topic: "   "
        ))
      end

      it 'strips the key ID and excludes the topic so the Rails default applies', :aggregate_failures do
        expect(template.exit_code).to eq(0)

        gitlab_yml = YAML.safe_load(template.dig('ConfigMap/test-webservice', 'data', 'gitlab.yml.erb'))
        expect(gitlab_yml['production']['mobile_push']['apns']['key_id']).to eq('ABC123DEFG')
        expect(gitlab_yml['production']['mobile_push']['apns']).not_to have_key('topic')
      end
    end
  end

  context 'by default' do
    let(:template) { HelmTemplate.new(HelmTemplate.defaults) }

    it 'renders no mobile_push section and no key volume', :aggregate_failures do
      expect(template.exit_code).to eq(0)

      deployments_with_mobile_push.each_key do |chart|
        gitlab_yml = YAML.safe_load(template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb'))
        expect(gitlab_yml['production']).not_to have_key('mobile_push')
      end

      deployments_with_mobile_push.each do |chart, deployment|
        found = template.find_projected_secret(
          deployment, "init-#{chart}-secrets", 'gitlab-mobile-push-apns-auth-key'
        )
        expect(found).to be(false)
      end
    end
  end
end
