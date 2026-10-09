# frozen_string_literal: true

require 'spec_helper'
require 'hash_deep_merge'
require 'helm_template_helper'
require 'yaml'

describe 'cells configuration' do
  let(:charts) { %w[migrations webservice sidekiq toolbox] }
  let(:default_values) do
    HelmTemplate.defaults
  end

  context 'when no cell configuration is set' do
    let(:helm_template) do
      HelmTemplate.new(default_values)
    end

    it 'generates no cell configuration in the gitlab.yml file' do
      charts.each do |chart|
        expect(gitlab_yml_cell(chart)).to eq(nil)
      end
    end
  end

  context 'when custom cell configuration is set' do
    let(:cell_values) do
      {
        'global' => {
          'appConfig' => {
            'cell' => {
              'enabled' => true,
              'id' => 1,
              'database' => {
                'skipSequenceAlteration' => false
              },
              'topologyServiceClient' => {
                'address' => 'topology-service.gitlab.example.com:443',
                'tls' => {
                  'enabled' => false
                }
              }
            }
          }
        }
      }
    end
    let(:helm_template) do
      HelmTemplate.new(default_values.deep_merge(cell_values))
    end

    it 'generates cell configuration in the gitlab.yml file' do
      expected_values = {
        'enabled' => true,
        'id' => 1,
        'database' =>
          {
            'skip_sequence_alteration' => false
          },
        'topology_service_client' => {
          'address' => 'topology-service.gitlab.example.com:443',
          'tls' => {
            'enabled' => false
          }
        }
      }

      charts.each do |chart|
        expect(gitlab_yml_cell(chart)).to eq(expected_values)
      end
    end
  end

  describe 'service TLS is configured' do
    let(:cell_values) do
      {
        'global' => {
          'appConfig' => {
            'cell' => {
              'enabled' => true,
              'id' => 1,
              'database' => {
                'skipSequenceAlteration' => false
              },
              'topologyServiceClient' => {
                'address' => 'topology-service.gitlab.example.com:443',
                'tls' => {
                  'enabled' => true
                }
              }
            }
          }
        }
      }
    end

    let(:helm_template) do
      HelmTemplate.new(default_values.deep_merge(cell_values))
    end

    it 'generates configuration in the gitlab.yml file with TLS' do
      expected_values = {
        "enabled" => true,
        "id" => 1,
        "database" =>
          {
            "skip_sequence_alteration" => false
          },
        "topology_service_client" => {
          "address" => "topology-service.gitlab.example.com:443",
          'certificate_file' => "/srv/gitlab/config/topology-service/tls.crt",
          "private_key_file" => "/srv/gitlab/config/topology-service/tls.key",
          "tls" => {
            "enabled" => true
          }
        }
      }

      charts.each do |chart|
        expect(gitlab_yml_cell(chart)).to eq(expected_values)
      end
    end
  end

  [false, true].product([false, true]).each do |cell_enabled, tls_enabled|
    context "with Cells enabled=#{cell_enabled} and Topology Service TLS enabled=#{tls_enabled}" do
      let(:tls_expected) { cell_enabled && tls_enabled }
      let(:helm_template) do
        HelmTemplate.new(default_values.deep_merge(
          'global' => {
            'appConfig' => {
              'cell' => {
                'enabled' => cell_enabled,
                'topologyServiceClient' => {
                  'tls' => { 'enabled' => tls_enabled, 'secret' => 'topology-tls' }
                }
              }
            }
          }
        ))
      end
      let(:pod_spec) { helm_template.dig('Deployment/test-toolbox', 'spec', 'template', 'spec') }

      it 'projects TLS credentials only when both global settings are enabled' do
        sources = pod_spec['volumes'].flat_map { |volume| volume.dig('projected', 'sources') || [] }

        expect(sources.any? { |source| source.dig('secret', 'name') == 'topology-tls' }).to eq(tls_expected)
      end

      it 'mounts TLS files only when both global settings are enabled' do
        mounts = pod_spec['containers'].flat_map { |container| container['volumeMounts'] }
        paths = mounts.map { |mount| mount['mountPath'] }

        expect(paths.include?('/srv/gitlab/config/topology-service/tls.crt')).to eq(tls_expected)
        expect(paths.include?('/srv/gitlab/config/topology-service/tls.key')).to eq(tls_expected)
      end

      it 'copies TLS credentials only when both global settings are enabled' do
        configure = helm_template.dig('ConfigMap/test-toolbox', 'data', 'configure')

        expect(configure.include?('/init-config/topology-service')).to eq(tls_expected)
      end
    end
  end

  def gitlab_yml_cell(chart)
    YAML.safe_load(
      helm_template.resources_by_kind('ConfigMap')["ConfigMap/test-#{chart}"]['data']['gitlab.yml.erb']
    )['production']['cell']
  end
end
