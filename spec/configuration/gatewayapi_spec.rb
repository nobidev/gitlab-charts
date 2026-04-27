# frozen_string_literal: true

require 'spec_helper'
require 'helm_template_helper'
require 'yaml'

# rubocop:disable RSpec/MultipleMemoizedHelpers - This spec need many memorized helpers to keep specs DRY.
describe 'Gateway API configuration' do
  let(:template) { HelmTemplate.new(values) }

  let(:gatewayclass) { template["GatewayClass/gitlab-gw"] }
  let(:gateway) { template["Gateway/test-gw"] }

  let(:envoyproxy) { template["EnvoyProxy/test-envoy-proxy"] }
  let(:clienttrafficpolicy) { template["ClientTrafficPolicy/test-policy"] }
  let(:securitypolicy) { template["SecurityPolicy/test-policy"] }
  let(:kas_backendtrafficpolicy) { template["BackendTrafficPolicy/test-kas"] }
  let(:webservice_smartcard_clienttrafficpolicy) { template["ClientTrafficPolicy/test-webservice"] }

  let(:shell_route) { template["TCPRoute/test-gitlab-shell"] }
  let(:webservice_route) { template["HTTPRoute/test-gitlab"] }
  let(:registry_route) { template["HTTPRoute/test-registry"] }
  let(:kas_route) { template["HTTPRoute/test-kas"] }
  let(:pages_route) { template["HTTPRoute/test-gitlab-pages"] }
  let(:routes) { [shell_route, webservice_route, registry_route, kas_route, pages_route] }

  describe "Gateway API is enabled" do
    let(:values) do
      HelmTemplate.with_defaults(%(
        nginx-ingress:
          enabled: false

        global:
          hosts:
            externalIP: 127.0.0.1
          pages:
            enabled: true
          gatewayApi:
            enabled: true
            installEnvoy: true
        ))
    end

    it 'renders the template' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
    end

    it 'creates all expected Gateway API objects' do
      expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

      # GatewayClass object
      expect(gatewayclass).not_to be_nil
      # Gateway object
      expect(gateway).not_to be_nil
      # Route objects
      expect(routes).not_to include(nil)
      # Optional policies
      expect(clienttrafficpolicy).to be_nil
      expect(securitypolicy).to be_nil
    end

    it 'picks up the static IP' do
      expect(gateway["spec"]["addresses"]).to eq([{ "type" => "IPAddress", "value" => "127.0.0.1" }])
    end

    describe 'with proxy protocol and IP allow/deny listing' do
      let(:values) do
        HelmTemplate.with_defaults(%(
          gatewayApiResources:
            envoy:
              clientTrafficPolicySpec:
                enableProxyProtocol: true
              securityPolicySpec:
                  authorization:
                    defaultAction: Deny
                    rules:
                    - action: Allow
                      principal:
                        clientCIDRs:
                         - 10.0.1.0/24
          )).deep_merge(super())
      end

      it 'creates the policies' do
        expect(clienttrafficpolicy).not_to be_nil
        expect(clienttrafficpolicy["spec"]["targetRefs"][0]["name"]).to eq("test-gw")
        expect(clienttrafficpolicy["spec"]["targetRefs"][0]).not_to have_key("namespace")
        expect(clienttrafficpolicy["spec"]["enableProxyProtocol"]).to be(true)

        expect(securitypolicy).not_to be_nil
        expect(securitypolicy["spec"]["targetRefs"][0]["name"]).to eq("test-gw")
        expect(securitypolicy["spec"]["targetRefs"][0]).not_to have_key("namespace")
        expect(securitypolicy["spec"]["authorization"]["defaultAction"]).to eq("Deny")

        expect(kas_backendtrafficpolicy).not_to be_nil
        expect(kas_backendtrafficpolicy["spec"]["targetRefs"][0]["name"]).to eq("test-kas")
        expect(kas_backendtrafficpolicy["spec"]["targetRefs"][0]["kind"]).to eq("HTTPRoute")

        # Additional policy for webservice must only be created if smartcard is enabled
        expect(webservice_smartcard_clienttrafficpolicy).to be_nil
      end
    end

    describe "Externally managed Gateway is configured" do
      let(:values) do
        HelmTemplate.with_defaults(%(
        nginx-ingress:
          enabled: false

        global:
          hosts:
            externalIP: 127.0.0.1
          pages:
            enabled: true
          gatewayApi:
            enabled: true
            installEnvoy: false
            gatewayRef:
              name: "external-gateway"
              namespace: "external-gateway-namespace"
        gitlab:
          gitlab-pages:
            gatewayRoute:
              gatewayName: "pages-gateway"
              gatewayNamespace: "pages-gateway-namespace"
        ))
      end

      it 'renders the template' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
      end

      it 'configures the manifests for the externally managed Gateway' do
        # Creates to Gateway, GatewayClass or Envoy extensions
        expect(gatewayclass).to be_nil
        expect(gateway).to be_nil
        expect(envoyproxy).to be_nil
        expect(clienttrafficpolicy).to be_nil
        expect(securitypolicy).to be_nil
        expect(kas_backendtrafficpolicy).to be_nil

        # Route objects reference external Gateway
        expect(routes).not_to include(nil)
        routes.each do |route|
          next if route == pages_route

          expect(route["spec"]["parentRefs"][0]["name"]).to eq("external-gateway")
          expect(route["spec"]["parentRefs"][0]["namespace"]).to eq("external-gateway-namespace")
        end

        expect(pages_route["spec"]["parentRefs"][0]["name"]).to eq("pages-gateway")
        expect(pages_route["spec"]["parentRefs"][0]["namespace"]).to eq("pages-gateway-namespace")
      end
    end

    context 'HTTP listener' do
      let(:values) do
        HelmTemplate.with_defaults(%(
        nginx-ingress:
          enabled: false

        global:
          gatewayApi:
            enabled: true
            installEnvoy: false
        gatewayApiResources:
          gateway:
            protocol: HTTP
            listeners:
              gitlab-web:
                protocol: HTTPS
              registry-web:
                protocol: HTTP
        ))
      end

      it 'omits the TLS block conditionally' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        gateway['spec']['listeners'].each do |listener|
          expect(listener.keys).not_to include('tls') unless listener['name'] == "gitlab-web"
        end
      end
    end

    describe 'Deploy as DaemonSet' do
      let(:values) do
        HelmTemplate.with_defaults(%(
        global:
          gatewayApi:
            enabled: true
            installEnvoy: true

        gatewayApiResources:
          envoy:
            proxySpec:
              provider:
                kubernetes:
                  envoyDaemonSet: {}
        ))
      end

      it 'disabled the default Deployment' do
        expect(envoyproxy).not_to be_nil
        expect(envoyproxy['spec']['provider']['kubernetes'].keys).not_to include('envoyDeployment')
        expect(envoyproxy['spec']['provider']['kubernetes'].keys).to include('envoyDaemonSet')
      end
    end

    context 'HTTP to HTTPS redirect' do
      let(:redirect_route) { template["HTTPRoute/test-http-redirect"] }

      context 'when httpToHttpsRedirect is enabled (default)' do
        it 'creates an http-default listener and redirect HTTPRoute' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

          http_listener = gateway['spec']['listeners'].find { |l| l['name'] == 'http-default' }
          expect(http_listener).not_to be_nil
          expect(http_listener['protocol']).to eq('HTTP')
          expect(http_listener['port']).to eq(80)
          expect(http_listener).not_to have_key('tls')
          expect(http_listener).not_to have_key('hostname')

          expect(redirect_route).not_to be_nil
          expect(redirect_route['spec']['parentRefs'].length).to eq(1)
          expect(redirect_route['spec']['parentRefs'][0]['name']).to eq('test-gw')
          expect(redirect_route['spec']['parentRefs'][0]['sectionName']).to eq('http-default')
          expect(redirect_route['spec']['rules'][0]['filters'][0]['type']).to eq('RequestRedirect')
          expect(redirect_route['spec']['rules'][0]['filters'][0]['requestRedirect']['scheme']).to eq('https')
          expect(redirect_route['spec']['rules'][0]['filters'][0]['requestRedirect']['statusCode']).to eq(301)
        end
      end

      context 'when configureCertmanager is also enabled' do
        let(:values) do
          HelmTemplate.with_defaults(%(
            global:
              gatewayApi:
                configureCertmanager: true
            )).deep_merge(super())
        end

        it 'shares a single http-default listener for both certmanager and redirect' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

          listener_names = gateway['spec']['listeners'].map { |l| l['name'] }
          expect(listener_names.count('http-default')).to eq(1)
          expect(redirect_route).not_to be_nil
          expect(redirect_route['spec']['parentRefs'][0]['sectionName']).to eq('http-default')
        end
      end

      context 'when httpToHttpsRedirect is disabled' do
        let(:values) do
          HelmTemplate.with_defaults(%(
            global:
              gatewayApi:
                httpToHttpsRedirect: false
            )).deep_merge(super())
        end

        it 'does not create http-default listener or redirect route' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(gateway['spec']['listeners'].map { |l| l['name'] }).not_to include('http-default')
          expect(redirect_route).to be_nil
        end
      end

      context 'when httpToHttpsRedirect is disabled but configureCertmanager is enabled' do
        let(:values) do
          HelmTemplate.with_defaults(%(
            global:
              gatewayApi:
                httpToHttpsRedirect: false
                configureCertmanager: true
            )).deep_merge(super())
        end

        it 'creates http-default listener for certmanager but no redirect route' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(gateway['spec']['listeners'].map { |l| l['name'] }).to include('http-default')
          expect(redirect_route).to be_nil
        end
      end

      context 'when global protocol is HTTP' do
        let(:values) do
          HelmTemplate.with_defaults(%(
          nginx-ingress:
            enabled: false

          global:
            hosts:
              externalIP: 127.0.0.1
            pages:
              enabled: true
            gatewayApi:
              enabled: true
              installEnvoy: true

          gatewayApiResources:
            gateway:
              protocol: HTTP
          ))
        end

        it 'does not create http-default listener or redirect route' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(gateway['spec']['listeners'].map { |l| l['name'] }).not_to include('http-default')
          expect(redirect_route).to be_nil
        end
      end

      context 'when using an external gateway' do
        let(:values) do
          HelmTemplate.with_defaults(%(
          nginx-ingress:
            enabled: false

          global:
            hosts:
              externalIP: 127.0.0.1
            pages:
              enabled: true
            gatewayApi:
              enabled: true
              installEnvoy: false
              gatewayRef:
                name: "external-gateway"
                namespace: "external-gateway-namespace"
          ))
        end

        it 'does not create the redirect HTTPRoute' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(redirect_route).to be_nil
        end
      end
    end

    context 'when individual services are disabled' do
      context 'when kas is disabled' do
        let(:values) do
          super().deep_merge(HelmTemplate.with_defaults(%(
            global:
              kas:
                enabled: false
          )))
        end

        it 'does not create kas HTTPRoute' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(kas_route).to be_nil
        end

        it 'does not create kas BackendTrafficPolicy' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(kas_backendtrafficpolicy).to be_nil
        end

        it 'still creates other routes' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(shell_route).not_to be_nil
          expect(webservice_route).not_to be_nil
          expect(registry_route).not_to be_nil
        end
      end

      context 'when gitlab-shell is disabled' do
        let(:values) do
          super().deep_merge(HelmTemplate.with_defaults(%(
            gitlab:
              gitlab-shell:
                enabled: false
          )))
        end

        it 'does not create gitlab-shell TCPRoute' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(shell_route).to be_nil
        end

        it 'still creates other routes' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(webservice_route).not_to be_nil
          expect(registry_route).not_to be_nil
          expect(kas_route).not_to be_nil
        end
      end

      context 'when webservice is disabled' do
        let(:values) do
          super().deep_merge(HelmTemplate.with_defaults(%(
            gitlab:
              webservice:
                enabled: false
          )))
        end

        it 'does not create webservice HTTPRoute' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(webservice_route).to be_nil
        end

        it 'still creates other routes' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(shell_route).not_to be_nil
          expect(registry_route).not_to be_nil
          expect(kas_route).not_to be_nil
        end
      end

      context 'when registry is disabled' do
        let(:values) do
          super().deep_merge(HelmTemplate.with_defaults(%(
            registry:
              enabled: false
          )))
        end

        it 'does not create registry HTTPRoute' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(registry_route).to be_nil
        end

        it 'still creates other routes' do
          expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"
          expect(shell_route).not_to be_nil
          expect(webservice_route).not_to be_nil
          expect(kas_route).not_to be_nil
        end
      end
    end

    context 'Smartcard' do
      let(:values) do
        HelmTemplate.with_defaults(%(
        nginx-ingress:
          enabled: false

        global:
          gatewayApi:
            enabled: true
            installEnvoy: true
          appConfig:
            smartcard:
              enabled: true
        ))
      end

      it 'modifies the Gateway API resources' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        expect(webservice_route['spec']['hostnames']).to include('smartcard.example.com')
        expect(webservice_smartcard_clienttrafficpolicy).not_to be_nil
        expect(gateway['spec']['listeners'].map { |l| l['name'] })
          .to include('gitlab-smartcard-web')
      end
    end

    context 'Backend TLS' do
      let(:values) do
        HelmTemplate.with_defaults(%(
        nginx-ingress:
          enabled: false

        global:
          hosts:
            registry:
              protocol: https
          kas:
            tls:
              enabled: true
              caSecretName: kas-tls-ca
          gatewayApi:
            enabled: true
            installEnvoy: true
          workhorse:
            tls:
              enabled: true

        registry:
          tls:
            enabled: true
            caSecretName: registry-tls-ca

        gitlab:
          webservice:
            workhorse:
              tls:
                enabled: true
                caSecretName: workhorse-tls-ca
        ))
      end

      it 'creates BackendTLSPolicy resources for KAS, Registry, and Webservice' do
        expect(template.exit_code).to eq(0), "Unexpected error code #{template.exit_code} -- #{template.stderr}"

        kas_policy = template["BackendTLSPolicy/test-kas"]
        expect(kas_policy).not_to be_nil
        expect(kas_policy['spec']['targetRefs'][0]['name']).to eq('test-kas')

        registry_policy = template["BackendTLSPolicy/test-registry"]
        expect(registry_policy).not_to be_nil
        expect(registry_policy['spec']['targetRefs'][0]['name']).to eq('test-registry')

        webservice_policy = template["BackendTLSPolicy/test-webservice-default"]
        expect(webservice_policy).not_to be_nil
        expect(webservice_policy['spec']['targetRefs'][0]['name']).to eq('test-webservice-default')
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
