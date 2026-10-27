require 'spec_helper'
require 'stringio'

load File.expand_path('../../scripts/ci/verify_component_image_tags.rb', __dir__)

describe 'scripts/ci/verify_component_image_tags.rb' do
  describe ImageTagVerifier do
    let(:out) { StringIO.new }
    let(:err) { StringIO.new }
    let(:manifest) { '' }

    subject(:verifier) { described_class.new(manifest: manifest, out: out, err: err) }

    describe '#collect_refs' do
      let(:manifest) do
        <<~YAML
          ---
          apiVersion: apps/v1
          kind: Deployment
          spec:
            template:
              spec:
                initContainers:
                  - name: certificates
                    image: registry.gitlab.com/gitlab-org/build/cng/certificates:master
                containers:
                  - name: registry
                    image: registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:v4.43.0-gitlab
                  - name: redis
                    image: redis:7.0
          ---
          apiVersion: batch/v1
          kind: CronJob
          spec:
            jobTemplate:
              spec:
                template:
                  spec:
                    containers:
                      - name: toolbox
                        image: registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee:v17.0.0
        YAML
      end

      it 'collects in-scope CNG images across documents, skipping floating and third-party tags' do
        expect(verifier.collect_refs(manifest)).to contain_exactly(
          'registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:v4.43.0-gitlab',
          'registry.gitlab.com/gitlab-org/build/cng/gitlab-toolbox-ee:v17.0.0'
        )
      end

      it 'raises a VerificationError on unparseable input' do
        expect { verifier.collect_refs("foo: [bar\n") }
          .to raise_error(ImageTagVerifier::VerificationError, /failed to parse/)
      end
    end

    describe '#check? and #image_tag' do
      def cng(suffix)
        "registry.gitlab.com/gitlab-org/build/cng/#{suffix}"
      end

      it 'accepts pinned CNG release tags' do
        expect(verifier.check?(cng('gitlab-container-registry:v4.43.0-gitlab'))).to be(true)
      end

      it 'accepts digest-pinned CNG images' do
        expect(verifier.check?(cng('gitaly:v17.0.0@sha256:abc123'))).to be(true)
      end

      it 'accepts a digest-only CNG image with no tag' do
        expect(verifier.check?(cng('gitaly@sha256:abc123'))).to be(true)
      end

      it 'rejects non-CNG images' do
        expect(verifier.check?('docker.io/library/redis:7.0')).to be(false)
      end

      it 'rejects floating and stable-branch tags' do
        expect(verifier.check?(cng('gitlab-webservice-ee:master'))).to be(false)
        expect(verifier.check?(cng('gitlab-webservice-ee:17-8-stable'))).to be(false)
      end

      it 'rejects an untagged image' do
        expect(verifier.check?(cng('gitaly'))).to be(false)
      end

      it 'extracts the tag, ignoring a digest suffix' do
        expect(verifier.image_tag(cng('gitaly:v17.0.0@sha256:abc'))).to eq('v17.0.0')
      end
    end

    describe '#image_present?' do
      let(:ref) { 'registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry:v4.43.0-gitlab' }

      before do
        allow(verifier).to receive(:sleep)
      end

      it 'is true when skopeo succeeds' do
        allow(verifier).to receive(:skopeo_inspect).and_return([true, ''])

        expect(verifier.image_present?(ref)).to be(true)
      end

      it 'is false when the manifest is unknown' do
        allow(verifier).to receive(:skopeo_inspect).and_return([false, 'Error: manifest unknown'])

        expect(verifier.image_present?(ref)).to be(false)
      end

      it 'raises on an authentication error instead of reporting missing' do
        allow(verifier).to receive(:skopeo_inspect).and_return([false, 'Error: unauthorized: access denied'])

        expect { verifier.image_present?(ref) }.to raise_error(ImageTagVerifier::VerificationError)
      end

      it 'retries transient failures, then succeeds' do
        allow(verifier).to receive(:skopeo_inspect)
          .and_return([false, 'timeout'], [true, ''])

        expect(verifier.image_present?(ref)).to be(true)
        expect(verifier).to have_received(:skopeo_inspect).twice
      end

      it 'raises after exhausting retries on persistent transient failures' do
        allow(verifier).to receive(:skopeo_inspect).and_return([false, 'timeout'])

        expect { verifier.image_present?(ref) }.to raise_error(ImageTagVerifier::VerificationError)
        expect(verifier).to have_received(:skopeo_inspect).exactly(ImageTagVerifier::MAX_ATTEMPTS).times
      end
    end

    describe '#not_found? and #auth_error?' do
      it 'classifies a manifest-unknown error as not found' do
        expect(verifier.not_found?('Error: manifest unknown')).to be(true)
        expect(verifier.auth_error?('Error: manifest unknown')).to be(false)
      end

      it 'classifies an unauthorized error as an auth error' do
        expect(verifier.auth_error?('unauthorized: authentication required')).to be(true)
        expect(verifier.not_found?('unauthorized: authentication required')).to be(false)
      end

      it 'does not match incidental digit runs such as a timing value' do
        expect(verifier.not_found?('request timed out after 1404ms')).to be(false)
        expect(verifier.auth_error?('request timed out after 401ms')).to be(false)
      end
    end

    describe '#login_registry' do
      before do
        allow(ENV).to receive(:[]).and_call_original
      end

      it 'logs in with CI_JOB_TOKEN when a token is available' do
        allow(ENV).to receive(:[]).with('CNG_REGISTRY_PASSWORD').and_return(nil)
        allow(ENV).to receive(:[]).with('CI_JOB_TOKEN').and_return('tok')
        allow(ENV).to receive(:[]).with('CNG_REGISTRY_USERNAME').and_return(nil)
        status = instance_double(Process::Status, success?: true)
        allow(Open3).to receive(:capture3).and_return(['', '', status])

        verifier.login_registry

        expect(Open3).to have_received(:capture3).with(
          'skopeo', 'login', '--username', 'gitlab-ci-token', '--password-stdin',
          'registry.gitlab.com', stdin_data: 'tok'
        )
      end

      it 'does nothing when no token is set' do
        allow(ENV).to receive(:[]).with('CNG_REGISTRY_PASSWORD').and_return(nil)
        allow(ENV).to receive(:[]).with('CI_JOB_TOKEN').and_return(nil)
        allow(Open3).to receive(:capture3)

        verifier.login_registry

        expect(Open3).not_to have_received(:capture3)
      end
    end

    describe '#run' do
      let(:repo) { 'registry.gitlab.com/gitlab-org/build/cng/gitlab-container-registry' }
      let(:ref) { "#{repo}:v4.43.0-gitlab" }

      before do
        allow(verifier).to receive(:login_registry)
        allow(verifier).to receive(:collect_refs).and_return([ref])
      end

      it 'returns 0 when every referenced tag exists' do
        allow(verifier).to receive(:image_present?).and_return(true)

        expect(verifier.run).to eq(0)
        expect(out.string).to match(/ok\s+#{Regexp.escape(ref)}/)
      end

      it 'returns 1 and reports the missing tag' do
        allow(verifier).to receive(:image_present?).and_return(false)

        expect(verifier.run).to eq(1)
        expect(out.string).to match(/MISSING\s+#{Regexp.escape(ref)}/)
        expect(err.string).to include(ref)
      end

      it 'returns 1 with a diagnostic when verification fails' do
        allow(verifier).to receive(:image_present?).and_raise(ImageTagVerifier::VerificationError, 'boom')

        expect(verifier.run).to eq(1)
        expect(err.string).to include('Unable to verify image tags: boom')
      end
    end
  end
end
