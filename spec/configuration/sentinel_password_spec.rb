require 'spec_helper'
require 'helm_template_helper'
require 'runtime_template_helper'
require 'hash_deep_merge'
require 'yaml'

describe 'Sentinel password encoding' do
  let(:configmaps) { %w[test-webservice test-sidekiq test-toolbox] }
  let(:values) do
    HelmTemplate.defaults.deep_merge(
      'global' => {
        'redis' => {
          'sentinels' => [{ 'host' => 'sentinel.example.com', 'port' => 26379 }],
          'sentinelAuth' => { 'enabled' => true, 'secret' => 'sentinel-secret', 'key' => 'password' }
        },
        'appConfig' => {
          'incomingEmail' => {
            'enabled' => true,
            'address' => 'incoming+%{key}@example.com',
            'deliveryMethod' => 'sidekiq',
            'password' => { 'secret' => 'incoming-password' }
          },
          'serviceDeskEmail' => {
            'enabled' => true,
            'address' => 'service-desk+%{key}@example.com',
            'deliveryMethod' => 'sidekiq',
            'password' => { 'secret' => 'service-desk-password' }
          }
        }
      }
    )
  end

  [
    'ordinary-password',
    'yes',
    '12345',
    'quote"value',
    'back\\slash',
    "\#{literal}",
    "two\nlines",
    'password: # text'
  ].each do |password|
    it "preserves #{password.inspect} in each consumer's runtime YAML" do
      template = HelmTemplate.new(values)
      expect(template.exit_code).to eq(0), template.stderr

      files = RuntimeTemplate.mock_files.merge(
        '/etc/gitlab/redis-sentinel/redis-sentinel-password' => password,
        '/etc/gitlab/mailroom/password_incoming_email' => 'incoming-password',
        '/etc/gitlab/mailroom/password_service_desk' => 'service-desk-password'
      )

      configmaps.each do |configmap|
        raw = template.dig("ConfigMap/#{configmap}", 'data', 'resque.yml.erb')
        config = YAML.safe_load(RuntimeTemplate.erb(raw_template: raw, files: files))

        expect(config.dig('production', 'sentinel_password')).to eq(password)
      end

      raw_exporter = template.dig('ConfigMap/test-gitlab-exporter', 'data', 'gitlab-exporter.yml.erb')
      exporter = YAML.safe_load(RuntimeTemplate.erb(raw_template: raw_exporter, files: files), aliases: true)

      expect(exporter.dig('probes', 'sidekiq', 'opts', 'redis_sentinel_password')).to eq(password)

      raw_mailroom = template.dig('ConfigMap/test-mailroom', 'data', 'mail_room.yml')
      mailroom = YAML.safe_load(RuntimeTemplate.erb(raw_template: raw_mailroom, files: files), permitted_classes: [Symbol])

      expect(mailroom[:mailboxes].length).to eq(2)
      mailroom[:mailboxes].each do |mailbox|
        expect(mailbox.dig(:delivery_options, :sentinel_password)).to eq(password)
        expect(mailbox.dig(:arbitration_options, :sentinel_password)).to eq(password)
      end
    end
  end
end
