require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig object storage' do
  describe 'gitlab.checkConfig.objectStorage.registry.configured' do
    let(:success_values) { HelmTemplate.defaults }

    let(:error_values) do
      values = HelmTemplate.defaults
      values['registry'].delete('storage')
      values
    end

    let(:error_output) { 'prepare an external object storage solution for the Registry' }

    include_examples 'config validation',
                     success_description: 'when registry is enabled and storage secret is configured',
                     error_description: 'when registry is enabled and storage secret is missing'
  end

  describe 'gitlab.checkConfig.objectStorage.registry.configured (registry disabled)' do
    let(:success_values) do
      values = HelmTemplate.defaults
      values['registry'] = { 'enabled' => false }
      values
    end

    include_examples 'config validation',
                     success_description: 'when registry is disabled, no storage secret is required'
  end

  describe 'gitlab.checkConfig.objectStorage.pages.configured' do
    let(:success_values) do
      HelmTemplate.with_defaults(%(
        global:
          pages:
            enabled: true
      ))
    end

    let(:error_values) do
      values = HelmTemplate.defaults
      values['global']['pages'] = {
        'enabled' => true,
        'objectStore' => {
          'enabled' => true,
          'connection' => {}
        }
      }
      values
    end

    let(:error_output) { 'prepare an external object storage solution for Pages' }

    include_examples 'config validation',
                     success_description: 'when pages is enabled and connection is configured',
                     error_description: 'when pages is enabled but the object storage connection is empty'
  end

  describe 'gitlab.checkConfig.objectStorage.pages.configured (pages object store disabled)' do
    let(:success_values) do
      values = HelmTemplate.defaults
      values['global']['pages'] = {
        'enabled' => true,
        'objectStore' => {
          'enabled' => false,
          'connection' => {}
        }
      }
      values
    end

    include_examples 'config validation',
                     success_description: 'when pages is enabled but objectStore is disabled, no connection is required'
  end

  describe 'gitlab.checkConfig.objectStorage.backup.configured' do
    let(:success_values) { default_required_values }

    let(:error_values) do
      values = HelmTemplate.defaults
      values['gitlab']['toolbox']['backups']['objectStorage']['config'] = {}
      values
    end

    let(:error_output) { 'prepare an external object storage solution for backup and restore' }

    include_examples 'config validation',
                     success_description: 'when toolbox is enabled and backup secret is configured',
                     error_description: 'when toolbox is enabled but backup secret is missing'
  end

  describe 'gitlab.checkConfig.objectStorage.backup.configured (GKE workload identity)' do
    let(:success_values) do
      values = HelmTemplate.defaults
      values['gitlab']['toolbox']['backups']['objectStorage'] = {
        'backend' => 'gcs',
        'config' => {}
      }
      values
    end

    include_examples 'config validation',
                     success_description: 'when toolbox uses GKE workload identity (gcs backend with empty config)'
  end

  describe 'gitlab.checkConfig.objectStorage.backup.configured (toolbox disabled)' do
    let(:success_values) do
      values = HelmTemplate.defaults
      values['gitlab']['toolbox'] = { 'enabled' => false }
      values['gitlab']['toolbox']['backups'] = { 'objectStorage' => { 'config' => {} } }
      values
    end

    include_examples 'config validation',
                     success_description: 'when toolbox is disabled, no backup secret is required'
  end

  describe 'gitlab.checkConfig.objectStorage.consolidatedConfig' do
    let(:success_values) { HelmTemplate.defaults }

    let(:error_values) do
      HelmTemplate.with_defaults(%(
        global:
          appConfig:
            lfs:
              enabled: true
              connection:
                secret: lfs-secret
                key: connection
      ))
    end

    let(:error_output) { 'When consolidated object storage is enabled, for each item `bucket` must be specified and the `connection` must be empty' }

    include_examples 'config validation',
                     success_description: 'when consolidated object storage is enabled and types only define a bucket',
                     error_description: 'when consolidated object storage is enabled but a type defines a connection'
  end

  describe 'gitlab.checkConfig.objectStorage.consolidatedConfig (missing bucket)' do
    let(:error_values) do
      HelmTemplate.with_defaults(%(
        global:
          appConfig:
            lfs:
              enabled: true
              bucket: ""
      ))
    end

    let(:error_output) { 'When consolidated object storage is enabled, for each item `bucket` must be specified and the `connection` must be empty' }

    include_examples 'config validation',
                     error_description: 'when consolidated object storage is enabled but a type has an empty bucket'
  end

  describe 'gitlab.checkConfig.objectStorage.typeSpecificConfig' do
    let(:success_values) { HelmTemplate.unconsolidated_defaults }

    let(:error_values) do
      values = HelmTemplate.defaults
      values['global']['appConfig']['object_store']['enabled'] = false
      values
    end

    let(:error_output) { 'When type-specific object storage is enabled the `connection` property can not be empty' }

    include_examples 'config validation',
                     success_description: 'when type-specific object storage is configured with connections for each enabled type',
                     error_description: 'when type-specific object storage is used but enabled types have empty connections'
  end
end
