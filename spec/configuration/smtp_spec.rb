require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'SMTP configuration' do
  let(:values) do
    HelmTemplate.with_defaults(%(
      global:
        smtp:
          enabled: true
          password:
            secret: gitlab-smtp
            key: password
    ))
  end
  let(:template) { HelmTemplate.new values }
  let(:smtp_secret) do
    template.get_projected_secret('Deployment/test-webservice-default', 'init-webservice-secrets', 'gitlab-smtp')
  end

  context 'authentication enabled' do
    let(:values) do
      YAML.safe_load(%(
        global:
          smtp:
            authentication: plain
      )).deep_merge(super())
    end

    it 'does mount the password secret' do
      expect(smtp_secret).to_not eq(nil)
      expect(smtp_secret['items'][0]['key']).to eq('password')
      expect(smtp_secret['items'][0]['path']).to eq('smtp/smtp-password')
    end

    context 'with user_name as plain text' do
      let(:values) do
        YAML.safe_load(%(
          global:
            smtp:
              user_name: "myuser"
        )).deep_merge(super())
      end

      it 'renders user_name as a plain string in smtp_settings.rb' do
        configmap = template.dig('ConfigMap/test-webservice', 'data', 'smtp_settings.rb')
        expect(configmap).to include('user_name: "myuser"')
        expect(configmap).not_to include('File.read("/etc/gitlab/smtp/smtp-username")')
      end

      it 'does not mount a user_name secret' do
        username_secret = template.get_projected_secret('Deployment/test-webservice-default', 'init-webservice-secrets', 'gitlab-smtp-username')
        expect(username_secret).to eq(nil)
      end
    end

    context 'with user_name from a Kubernetes Secret' do
      let(:values) do
        YAML.safe_load(%(
          global:
            smtp:
              user_name_secret:
                secret: gitlab-smtp-username
                key: username
        )).deep_merge(super())
      end

      it 'renders user_name as File.read in smtp_settings.rb' do
        configmap = template.dig('ConfigMap/test-webservice', 'data', 'smtp_settings.rb')
        expect(configmap).to include('File.read("/etc/gitlab/smtp/smtp-username")')
        expect(configmap).not_to include('user_name: ""')
      end

      it 'does mount the user_name secret' do
        username_secret = template.get_projected_secret('Deployment/test-webservice-default', 'init-webservice-secrets', 'gitlab-smtp-username')
        expect(username_secret).to_not eq(nil)
        expect(username_secret['items'][0]['key']).to eq('username')
        expect(username_secret['items'][0]['path']).to eq('smtp/smtp-username')
      end
    end
  end

  context 'authentication disabled' do
    context 'via empty string' do
      let(:values) do
        YAML.safe_load(%(
          global:
            smtp:
              authentication: ""
        )).deep_merge(super())
      end

      it 'does not mount the password secret' do
        expect(smtp_secret).to eq(nil)
      end
    end

    context 'via none string' do
      let(:values) do
        YAML.safe_load(%(
          global:
            smtp:
              authentication: "none"
      )).deep_merge(super())
      end

      it 'does not mount the password secret' do
        expect(smtp_secret).to eq(nil)
      end
    end
  end
end
