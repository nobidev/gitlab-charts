require 'spec_helper'
require 'check_config_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'checkConfig gitaly' do
  describe 'gitaly.tls with Praefect' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          praefect:
            enabled: true
            virtualStorages:
            - name: default
              gitalyReplicas: 3
              maxUnavailable: 2
              tlsSecretName: gitaly-default-tls
            - name: vs1
              gitalyReplicas: 2
              maxUnavailable: 1
              tlsSecretName: gitaly-vs2-tls
          gitaly:
            enabled: true
            tls:
              enabled: true
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          praefect:
            enabled: true
            virtualStorages:
            - name: default
              gitalyReplicas: 3
              maxUnavailable: 2
              tlsSecretName: gitaly-default-tls
            - name: vs2
              gitalyReplicas: 2
              maxUnavailable: 1
          gitaly:
            enabled: true
            tls:
              enabled: true
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'global.praefect.virtualStorages[1].tlsSecretName not specified (\'vs2\')' }

    include_examples 'config validation',
                     success_description: 'when TLS is enabled correctly',
                     error_description: 'when TLS is enabled but there is no certificate'
  end

  describe 'gitaly.extern.repos' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          gitaly:
            enabled: false
            external:
            - name: default
              hostname: bar
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          gitaly:
            enabled: false
            external: []
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'external Gitaly repos needs to be specified if global.gitaly.enabled is not set' }

    include_examples 'config validation',
                     success_description: 'when Gitaly is disabled and external repos are enabled',
                     error_description: 'when Gitaly and external repos are disabled'
  end

  describe 'gitaly.duplicate.repos' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          gitaly:
            internal:
              names:
              - default
            external:
              - name: foo
                hostname: bar
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          gitaly:
            internal:
              names:
              - default
              - foo
            external:
              - name: foo
                hostname: bar
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'Each storage name must be unique.' }

    include_examples 'config validation',
                     success_description: 'when Gitaly is enabled and storage names are unique',
                     error_description: 'when Gitaly is enabled and storage names are not unique'
  end

  describe 'gitaly.duplicate.repos with praefect' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          gitaly:
            internal:
              names:
              - default
              - foo
          praefect:
            enabled: true
            replaceInternalGitaly: false
            virtualStorages:
            - name: defaultPraefect
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          gitaly:
            internal:
              names:
              - default
              - foo
          praefect:
            enabled: true
            replaceInternalGitaly: false
            virtualStorages:
            - name: foo
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'Each storage name must be unique.' }

    include_examples 'config validation',
                     success_description: 'when Gitaly and Praefect are enabled and storage names are unique',
                     error_description: 'when Gitaly and Praefect are enabled and storage names are not unique'
  end

  describe 'gitaly.default.repo' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          gitaly:
            internal:
              names:
              - default
            external:
              - name: external1
                hostname: foo
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          gitaly:
            internal:
              names:
              - foo
            external:
              - name: bar
                hostname: baz
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'There must be one (and only one) storage named \'default\'.' }

    include_examples 'config validation',
                     success_description: 'when Gitaly is enabled and one storage is named "default"',
                     error_description: 'when Gitaly is enabled and no storages are named "default"'
  end

  describe 'gitaly.default.repo with praefect' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          gitaly:
            internal:
              names:
                - default
            external:
              - name: external1
                hostname: foo
          praefect:
            enabled: true
            replaceInternalGitaly: false
            virtualStorages:
            - name: praefect1
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          gitaly:
            internal:
              names:
                - internal1
            external:
              - name: external1
                hostname: baz
          praefect:
            enabled: true
            replaceInternalGitaly: false
            virtualStorages:
            - name: praefect1
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { 'There must be one (and only one) storage named \'default\'.' }

    include_examples 'config validation',
                     success_description: 'when Gitaly and Praefect are enabled and one storage is named "default"',
                     error_description: 'when Gitaly and Praefect are enabled and no storages are named "default"'
  end

  describe 'praefect with defaultReplicationFactor' do
    let(:success_values) do
      YAML.safe_load(%(
        global:
          praefect:
            enabled: true
            virtualStorages:
            - name: default
              gitalyReplicas: 3
              defaultReplicationFactor: 2
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        global:
          praefect:
            enabled: true
            virtualStorages:
            - name: default
              gitalyReplicas: 2
              defaultReplicationFactor: 3
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { '\'defaultReplicationFactor\' is not correct.' }

    include_examples 'config validation',
                     success_description: 'when Praefect is enabled and defaultReplicationFactor is equal to or lower than than gitalyReplicas',
                     error_description: 'when Praefect is enabled and defaultReplicationFactor is greater than than gitalyReplicas'
  end

  describe 'gitaly.storagePathFormat' do
    let(:success_values) do
      YAML.safe_load(%(
        gitlab:
          gitaly:
            storagePathFormat: /home/git/repositories/git-data/%s/repositories
      )).deep_merge!(default_required_values)
    end

    let(:error_values) do
      YAML.safe_load(%(
        gitlab:
          gitaly:
            storagePathFormat: /var/opt/gitlab/git-data/%s/repositories
      )).deep_merge!(default_required_values)
    end

    let(:error_output) { '`gitlab.gitaly.storagePathFormat` must be an absolute path below' }

    include_examples 'config validation',
                     success_description: 'when storagePathFormat is below the repository volume and contains one %s',
                     error_description: 'when storagePathFormat is not below the repository volume'

    [
      'git-data/%s/repositories',
      '/home/git/repositories/git-data',
      '/home/git/repositories/%s/%s',
      '/home/git/repositories/%d',
      '/home/git/repositories/../%s',
      %(/home/git/repositories/'%s'),
      %(/home/git/repositories/"%s"),
      '/home/git/repositories/a\\b%s',
      "/home/git/repositories/%s\n",
      "/home/git/repositories/%s\tdata"
    ].each do |format|
      context "with #{format.inspect}" do
        let(:error_values) do
          default_required_values.deep_merge('gitlab' => { 'gitaly' => { 'storagePathFormat' => format } })
        end

        include_examples 'config validation', error_description: 'when storagePathFormat is not valid'
      end
    end

    describe 'with storage names in internal.names' do
      let(:success_values) do
        default_required_values.deep_merge(
          'gitlab' => { 'gitaly' => {
            'storagePathFormat' => '/home/git/repositories/git-data/%s/repositories',
            'internal' => { 'names' => %w[default storage-2 storage_3.data] }
          } }
        )
      end

      let(:error_output) { 'each storage name in' }

      include_examples 'config validation',
                       success_description: 'when all storage names are plain path elements'

      ['../../../tmp/secondary', 'git/data', '..', '.', 'secondary$HOME', 'secondary`id`', 'a b'].each do |name|
        context "with #{name.inspect}" do
          let(:error_values) do
            success_values.deep_merge('gitlab' => { 'gitaly' => { 'internal' => { 'names' => ['default', name] } } })
          end

          include_examples 'config validation', error_description: 'when a storage name is not a plain path element'
        end
      end
    end

    describe 'with storage names in internal.names and no storagePathFormat' do
      let(:success_values) do
        default_required_values.deep_merge('gitlab' => { 'gitaly' => { 'internal' => { 'names' => ['default', 'secondary$HOME'] } } })
      end

      include_examples 'config validation',
                       success_description: 'when storagePathFormat is not set, the storage names are not checked'
    end
  end
end
