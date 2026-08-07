# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'
require 'hash_deep_merge'

describe 'global clusterDomain configuration' do
  let(:template) { HelmTemplate.new(values) }

  # Every in-cluster Service address in the rendered manifest. Scanning the whole
  # manifest, rather than a list of known resources, means a new call site cannot be
  # missed. Third-party subcharts build their addresses from `$(POD_NAMESPACE)`
  # instead of the release namespace, so they do not match and stay out of scope.
  let(:rendered_addresses) do
    template.stdout.scan(/[a-z0-9][a-z0-9.-]*\.default\.svc(?:\.[a-z0-9][a-z0-9.-]*)?/).uniq.sort
  end

  # Enables internal TLS on every component that renders a Service address, so the
  # BackendTLSPolicy validation hostnames are covered alongside the config files.
  let(:internal_tls) do
    %(
      global:
        workhorse:
          tls:
            enabled: true
        gitaly:
          tls:
            enabled: true
        kas:
          tls:
            enabled: true
            verify: true
            caSecretName: kas-ca
        hosts:
          registry:
            protocol: https
      registry:
        tls:
          enabled: true
          verify: true
          caSecretName: registry-ca
    )
  end

  context 'when global.clusterDomain is not set' do
    let(:values) { HelmTemplate.defaults }

    it 'addresses every Service by its partial name' do
      expect(template.exit_code).to eq(0)
      expect(rendered_addresses).to eq(
        %w[
          test-gitaly-0.test-gitaly.default.svc
          test-kas.default.svc
          test-registry.default.svc
          test-webservice-default.default.svc
        ]
      )
    end
  end

  context 'when global.clusterDomain is set' do
    let(:values) do
      HelmTemplate.with_defaults(internal_tls).deep_merge(YAML.safe_load(%(
        global:
          clusterDomain: cluster.local
          praefect:
            enabled: true
            virtualStorages:
              - name: default
                gitalyReplicas: 2
                maxUnavailable: 1
                tlsSecretName: praefect-tls
      )))
    end

    it 'addresses every Service by its fully qualified name' do
      expect(template.exit_code).to eq(0)
      expect(rendered_addresses).to eq(
        %w[
          test-gitaly-default-0.test-gitaly-default.default.svc.cluster.local
          test-gitaly-default-1.test-gitaly-default.default.svc.cluster.local
          test-kas.default.svc.cluster.local
          test-praefect.default.svc.cluster.local
          test-registry.default.svc.cluster.local
          test-webservice-default.default.svc.cluster.local
        ]
      )
    end
  end

  # The NGINX `proxy-ssl-name` annotations are a separate set of call sites from the
  # Gateway API validation hostnames, including the smartcard and gRPC Ingresses.
  context 'when global.clusterDomain is set with NGINX Ingress' do
    let(:values) do
      HelmTemplate.with_defaults(internal_tls).deep_merge(YAML.safe_load(%(
        global:
          clusterDomain: cluster.local
          gatewayApi:
            enabled: false
          ingress:
            enabled: true
            provider: nginx
          appConfig:
            smartcard:
              enabled: true
              CASecret: smartcard-ca
        gitlab:
          kas:
            ingress:
              grpc:
                enabled: true
          webservice:
            workhorse:
              tls:
                verify: true
      )))
    end

    it 'addresses every Service by its fully qualified name' do
      expect(template.exit_code).to eq(0)
      expect(rendered_addresses).not_to be_empty
      expect(rendered_addresses).to all(end_with('.svc.cluster.local'))
    end
  end

  # A trailing dot fails TLS SAN matching and is rejected by the Gateway API
  # PreciseHostname type, so a domain that is empty once trimmed must be ignored.
  context 'when global.clusterDomain is only dots' do
    let(:values) do
      HelmTemplate.with_defaults(%(
        global:
          clusterDomain: "..."
      ))
    end

    it 'falls back to the partial name rather than emitting a trailing dot' do
      expect(template.exit_code).to eq(0)
      expect(rendered_addresses).not_to be_empty
      expect(rendered_addresses).to all(end_with('.default.svc'))
    end
  end
end
