require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

describe 'Mobile push configuration' do
  let(:charts_with_mobile_push) do
    [
      'webservice',
      'sidekiq',
      'toolbox'
    ]
  end

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

      charts_with_mobile_push.each do |chart|
        gitlab_yml = YAML.safe_load(template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb'))
        apns = gitlab_yml['production']['mobile_push']['apns']
        expect(apns['auth_key_path']).to eq('/etc/gitlab/mobile_push/apns_auth_key.p8')
        expect(apns['key_id']).to eq('ABC123DEFG')
        expect(apns['team_id']).to eq('DEF456GHIJ')
        expect(apns).not_to have_key('topic')
      end

      deployments_with_mobile_push.each_value do |deployment|
        volumes = template.dig(deployment, 'spec', 'template', 'spec', 'volumes')
        key_volume = volumes.find { |volume| volume['name'] == 'mobile-push-apns-auth-key' }
        expect(key_volume).not_to be_nil
        expect(key_volume['secret']['secretName']).to eq('gitlab-mobile-push-apns-auth-key')

        rails_containers = template.dig(deployment, 'spec', 'template', 'spec', 'containers')
        mounts = rails_containers.first['volumeMounts']
        key_mount = mounts.find { |mount| mount['name'] == 'mobile-push-apns-auth-key' }
        expect(key_mount).not_to be_nil
        expect(key_mount['mountPath']).to eq('/etc/gitlab/mobile_push/apns_auth_key.p8')
        expect(key_mount['subPath']).to eq('auth_key')
        expect(key_mount['readOnly']).to be(true)
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
  end

  context 'by default' do
    let(:template) { HelmTemplate.new(HelmTemplate.defaults) }

    it 'renders no mobile_push section and no key volume', :aggregate_failures do
      expect(template.exit_code).to eq(0)

      charts_with_mobile_push.each do |chart|
        gitlab_yml = YAML.safe_load(template.dig("ConfigMap/test-#{chart}", 'data', 'gitlab.yml.erb'))
        expect(gitlab_yml['production']).not_to have_key('mobile_push')
      end

      deployments_with_mobile_push.each_value do |deployment|
        volumes = template.dig(deployment, 'spec', 'template', 'spec', 'volumes')
        expect(volumes.find { |volume| volume['name'] == 'mobile-push-apns-auth-key' }).to be_nil
      end
    end
  end
end
