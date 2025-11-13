# frozen_string_literal: true

require 'spec_helper'
require 'hash_deep_merge'
require 'helm_template_helper'
require 'yaml'

describe 'database traffic capture configuration' do
  let(:charts) { %w[webservice sidekiq toolbox] }
  let(:default_values) { HelmTemplate.defaults }

  context 'when no configuration is set' do
    let(:helm_template) { HelmTemplate.new(default_values) }

    it 'generates no database traffic capture configuration in the gitlab.yml file' do
      charts.each do |chart|
        expect(gitlab_yml_database_traffic_capture(chart)).to be_nil
      end
    end
  end

  context 'when partial configuration is set' do
    let(:helm_template) { HelmTemplate.new(database_traffic_capture_values.deep_merge!(default_values)) }
    let(:database_traffic_capture_values) do
      {
        'global' => {
          'appConfig' => {
            'databaseTrafficCapture' => {
              'config' => {}
            }
          }
        }
      }
    end

    it 'generates no database traffic capture configuration in the gitlab.yml file' do
      charts.each do |chart|
        expect(gitlab_yml_database_traffic_capture(chart)).to be_nil
      end
    end
  end

  context 'when partial configuration with the provider name is set' do
    let(:helm_template) { HelmTemplate.new(database_traffic_capture_values.deep_merge!(default_values)) }
    let(:database_traffic_capture_values) do
      {
        'global' => {
          'appConfig' => {
            'databaseTrafficCapture' => {
              'config' => {
                'storage' => {
                  'connector' => {
                    'provider' => 'provider'
                  }
                }
              }
            }
          }
        }
      }
    end

    it 'generates database traffic capture configuration in the gitlab.yml file with defaults' do
      expected_values = {
        'config' => {
          'storage' => {
            'connector' => {
              'provider' => 'provider',
              'project_id' => nil,
              'bucket' => nil
            }
          }
        }
      }

      charts.each do |chart|
        expect(gitlab_yml_database_traffic_capture(chart)).to eq(expected_values)
      end
    end
  end

  context 'when custom configuration is set' do
    let(:helm_template) { HelmTemplate.new(database_traffic_capture_values.deep_merge!(default_values)) }
    let(:database_traffic_capture_values) do
      {
        'global' => {
          'appConfig' => {
            'databaseTrafficCapture' => {
              'config' => {
                'storage' => {
                  'connector' => {
                    'provider' => 'provider-name',
                    'projectId' => 'project-id',
                    'bucket' => 'bucket-name'
                  }
                }
              }
            }
          }
        }
      }
    end

    it 'generates database traffic capture configuration in the gitlab.yml file' do
      expected_values = {
        'config' => {
          'storage' => {
            'connector' => {
              'provider' => 'provider-name',
              'project_id' => 'project-id',
              'bucket' => 'bucket-name'
            }
          }
        }
      }

      charts.each do |chart|
        expect(gitlab_yml_database_traffic_capture(chart)).to eq(expected_values)
      end
    end
  end

  def gitlab_yml_database_traffic_capture(chart)
    YAML.safe_load(
      helm_template.resources_by_kind('ConfigMap')["ConfigMap/test-#{chart}"]['data']['gitlab.yml.erb']
    )['production']['database_traffic_capture']
  end
end
