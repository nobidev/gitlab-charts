# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'Service trafficDistribution configuration' do
  let(:default_values) { HelmTemplate.defaults }

  def set_path(hash, path, value)
    *rest, last = path
    target = rest.reduce(hash) { |h, key| h[key] ||= {} }
    target[last] = value
  end

  def values_with_traffic_distribution(services)
    services.each_with_object({}) { |(_, path), h| set_path(h, path, 'PreferClose') }
  end

  context 'for core services, Praefect, and the gitlab-pages proxy Service' do
    let(:services) do
      {
        'Service/test-webservice-default' => %w[gitlab webservice service trafficDistribution],
        'Service/test-gitlab-shell' => %w[gitlab gitlab-shell service trafficDistribution],
        'Service/test-gitaly-default' => %w[gitlab gitaly service trafficDistribution],
        'Service/test-praefect' => %w[gitlab praefect service trafficDistribution],
        'Service/test-kas' => %w[gitlab kas service trafficDistribution],
        'Service/test-gitlab-pages' => %w[gitlab gitlab-pages service trafficDistribution],
        'Service/test-gitlab-pages-metrics' => %w[gitlab gitlab-pages service metrics trafficDistribution],
        'Service/test-gitlab-exporter' => %w[gitlab gitlab-exporter service trafficDistribution],
        'Service/test-registry' => %w[registry service trafficDistribution]
      }
    end

    let(:topology_values) do
      YAML.safe_load(%(
        global:
          praefect:
            enabled: true
          pages:
            enabled: true
      ))
    end

    context 'when service.trafficDistribution is configured for every component' do
      let(:values) do
        default_values.deep_merge(topology_values).deep_merge(values_with_traffic_distribution(services))
      end

      let(:template) { HelmTemplate.new(values) }

      it 'renders successfully' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      end

      it 'sets trafficDistribution on every Service object' do
        services.each_key do |resource|
          expect(template.dig(resource, 'spec', 'trafficDistribution')).to eq('PreferClose'), "expected #{resource} to have trafficDistribution set"
        end
      end
    end

    context 'when service.trafficDistribution is not configured' do
      let(:values) { default_values.deep_merge(topology_values) }
      let(:template) { HelmTemplate.new(values) }

      it 'renders successfully' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      end

      it 'does not set trafficDistribution on any Service object' do
        services.each_key do |resource|
          expect(template.dig(resource, 'spec')).not_to have_key('trafficDistribution'), "expected #{resource} not to have trafficDistribution set"
        end
      end
    end
  end

  context 'for the gitlab-pages custom domains Service' do
    # The custom domains Service only renders instead of, never alongside, the
    # primary gitlab-pages proxy Service tested above.
    let(:services) do
      {
        'Service/test-gitlab-pages-custom-domains' => %w[gitlab gitlab-pages service trafficDistribution]
      }
    end

    let(:topology_values) do
      YAML.safe_load(%(
        global:
          pages:
            enabled: true
            externalHttp:
              - 1.2.3.4
      ))
    end

    context 'when service.trafficDistribution is configured' do
      let(:values) do
        default_values.deep_merge(topology_values).deep_merge(values_with_traffic_distribution(services))
      end

      let(:template) { HelmTemplate.new(values) }

      it 'renders successfully' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      end

      it 'sets trafficDistribution on the custom domains Service' do
        services.each_key do |resource|
          expect(template.dig(resource, 'spec', 'trafficDistribution')).to eq('PreferClose'), "expected #{resource} to have trafficDistribution set"
        end
      end
    end

    context 'when service.trafficDistribution is not configured' do
      let(:values) { default_values.deep_merge(topology_values) }
      let(:template) { HelmTemplate.new(values) }

      it 'renders successfully' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      end

      it 'does not set trafficDistribution on the custom domains Service' do
        services.each_key do |resource|
          expect(template.dig(resource, 'spec')).not_to have_key('trafficDistribution'), "expected #{resource} not to have trafficDistribution set"
        end
      end
    end
  end
end
