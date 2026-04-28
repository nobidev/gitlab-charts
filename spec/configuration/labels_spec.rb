require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Labels configuration' do
  let(:default_values) do
    HelmTemplate.with_defaults(%(
      global:
        gatewayApi:
          installEnvoy: false
        pod:
          labels:
            environment: development
    ))
  end

  let(:ignored_charts) do
    [
      'Job/test-certmanager-startupapicheck',
      'Deployment/test-certmanager-cainjector',
      'Deployment/test-certmanager-webhook',
      'Deployment/test-certmanager',
      'Deployment/test-gitlab-runner',
      'Deployment/test-prometheus-server',
      'Deployment/test-minio',
      # not included, StatefulSet: postgresql, redis, gitlab/gitaly
    ]
  end

  let(:target_chart) do
    'Deployment/test-webservice-default'
  end

  let(:chart_values) do
    YAML.safe_load(%(
      gitlab:
        webservice:
          podLabels:
            spec/test: local
            environment: local
    ))
  end

  context 'When setting global pod labels' do
    it 'Populates labels for all Pod templates' do
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0)

      resources_by_kind = t.resources_by_kind('Deployment').reject{ |key, _| ignored_charts.include? key }

      resources_by_kind.each do |key, _|
        expect(t.dig(key, 'spec', 'template', 'metadata', 'labels')).to include(default_values['global']['pod']['labels']), key
      end
    end

    it 'Populates labels for all Job templates' do
      t = HelmTemplate.new(default_values)
      expect(t.exit_code).to eq(0)

      resources_by_kind = t.resources_by_kind('Job').reject{ |key, _| ignored_charts.include? key }

      resources_by_kind.each do |key, _|
        expect(t.dig(key, 'spec', 'template', 'metadata', 'labels')).to include(default_values['global']['pod']['labels']), key
      end
    end

    context 'When populating a chart local labels' do
      let(:local_template) do
        HelmTemplate.new(default_values.deep_merge(chart_values))
      end

      it 'Override global' do
        expect(local_template.exit_code).to eq(0)

        resources_by_kind = local_template.resources_by_kind('Deployment').reject{ |key, _| ignored_charts.include? key }
        resources_by_kind.reject!{ |key, _| target_chart.eql? key }

        resources_by_kind.each do |key, _|
          expect(local_template.dig(key, 'spec', 'template', 'metadata', 'labels')).to include(default_values['global']['pod']['labels'])
        end

        expect(local_template.dig(target_chart, 'spec', 'template', 'metadata', 'labels')).to include(chart_values['gitlab']['webservice']['podLabels'])
      end

      it 'Are only present on configured chart' do
        resources_by_kind = local_template.resources_by_kind('Deployment').reject{ |key, _| ignored_charts.include? key }
        resources_by_kind.reject!{ |key, _| target_chart.eql? key }

        resources_by_kind.each do |key, _|
          expect(local_template.dig(key, 'spec', 'template', 'metadata', 'labels')).not_to include(chart_values['gitlab']['webservice']['podLabels'])
        end
      end
    end
  end

  context 'When only local labels present' do
    let(:local_template) do
      HelmTemplate.new(HelmTemplate.with_defaults(chart_values))
    end

    it 'Are only present on configured chart' do
      expect(local_template.exit_code).to eq(0)

      resources_by_kind = local_template.resources_by_kind('Deployment').reject{ |key, _| ignored_charts.include? key }
      resources_by_kind.reject!{ |key, _| target_chart.eql? key }

      resources_by_kind.each do |key, _|
        expect(local_template.dig(key, 'spec', 'template', 'metadata', 'labels')).not_to include(chart_values['gitlab']['webservice']['podLabels'])
      end

      expect(local_template.dig(target_chart, 'spec', 'template', 'metadata', 'labels')).to include(chart_values['gitlab']['webservice']['podLabels'])
    end
  end

  context 'Standard labels' do
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
          gatewayApi:
            installEnvoy: false
      ))
    end

    # These are the labels emitted by gitlab.common.legacyStandardLabels, which is the
    # migration target for all GitLab-owned resources. This context verifies backwards
    # compatibility: every resource must carry at minimum the four legacy Helm labels:
    # app, release, heritage, and chart.
    let(:t) { HelmTemplate.new(values) }

    let(:third_party_resources) do
      [
        'Deployment/test-certmanager-webhook',
        'Deployment/test-certmanager-cainjector',
        'Deployment/test-certmanager',
        'Deployment/test-prometheus-server',
        'Job/test-certmanager-startupapicheck',
        'StatefulSet/test-postgresql',
        'StatefulSet/test-redis-master',
      ]
    end

    let(:legacy_label_keys) do
      %w[
        app
        chart
        heritage
        release
      ]
    end

    %w[Deployment StatefulSet Job].each do |kind|
      it "applies standard labels to metadata of all GitLab-owned #{kind} resources" do
        expect(t.exit_code).to eq(0), t.stderr

        resources = t.resources_by_kind(kind).reject { |key, _| third_party_resources.include?(key) }
        skip "No #{kind} resources rendered" if resources.empty?

        aggregate_failures do
          resources.each do |key, _|
            actual_keys = t.labels(key).keys
            expect(actual_keys).to include(*legacy_label_keys),
              "#{key}: expected resource labels #{actual_keys.inspect} to include #{legacy_label_keys.inspect}"
          end
        end
      end

      it "applies standard labels to pod template of all GitLab-owned #{kind} resources" do
        expect(t.exit_code).to eq(0), t.stderr

        resources = t.resources_by_kind(kind).reject { |key, _| third_party_resources.include?(key) }
        skip "No #{kind} resources rendered" if resources.empty?

        aggregate_failures do
          resources.each do |key, _|
            template_lbls = t.template_labels(key)
            skip "No pod template found for #{key}" if template_lbls.nil?

            actual_keys = template_lbls.keys
            expect(actual_keys).to include(*legacy_label_keys),
              "#{key}: expected pod template labels #{actual_keys.inspect} to include #{legacy_label_keys.inspect}"
          end
        end
      end
    end

    context 'Gateway API resources' do
      let(:t) do
        HelmTemplate.new(HelmTemplate.with_defaults(%(
          nginx-ingress:
            enabled: false
          nginx-ingress-geo:
            enabled: false

          gatewayApiResources:
            envoy:
              clientTrafficPolicySpec:
                enableProxyProtocol: true

          global:
            appConfig:
              smartcard:
                enabled: true
            gatewayApi:
              enabled: true
              installEnvoy: true
            geo:
              enabled: true
              role: primary
              gatewayApi:
                additionalHostname: geo.example.com
            psql:
              host: psql.example.com
              password:
                secret: geo-psql-password
        )))
      end

      let(:gitlab_owned_client_traffic_policies) do
        [
          'ClientTrafficPolicy/test-policy',
          'ClientTrafficPolicy/test-webservice-ctp',
          'ClientTrafficPolicy/test-webservice-ctp-geo',
          'ClientTrafficPolicy/test-webservice-ctp-smartcard'
        ]
      end

      it 'applies standard labels to metadata of all GitLab-owned ClientTrafficPolicy resources' do
        expect(t.exit_code).to eq(0), t.stderr
        expect(t.resources_by_kind('ClientTrafficPolicy').keys).to include(*gitlab_owned_client_traffic_policies)

        aggregate_failures do
          gitlab_owned_client_traffic_policies.each do |key|
            actual_keys = t.labels(key).keys
            expect(actual_keys).to include(*legacy_label_keys),
              "#{key}: expected resource labels #{actual_keys.inspect} to include #{legacy_label_keys.inspect}"
          end
        end
      end
    end
  end
end
