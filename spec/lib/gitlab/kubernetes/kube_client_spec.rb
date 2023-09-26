# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Kubernetes::KubeClient do
  include StubRequests
  include KubernetesHelpers

  let(:api_url) { 'https://kubernetes.example.com/prefix' }
  let(:kubeclient_options) { { auth_options: { bearer_token: 'xyz' } } }

  let(:client) { described_class.new(api_url, **kubeclient_options) }

  before do
    stub_kubeclient_discover(api_url)
  end

  def method_call(client, method_name)
    case method_name
    when /\A(get_|delete_)/
      client.public_send(method_name)
    when /\A(create_|update_|patch_)/
      client.public_send(method_name, {})
    else
      raise "Unknown method name #{method_name}"
    end
  end

  shared_examples 'a Kubeclient' do
    it 'is a Kubeclient::Client' do
      is_expected.to be_an_instance_of Kubeclient::Client
    end

    it 'has the kubeclient options' do
      expect(subject.auth_options).to eq({ bearer_token: 'xyz' })
    end
  end

  shared_examples 'redirection not allowed' do |method_name|
    context 'api_url is redirected' do
      before do
        redirect_url = 'https://not-under-our-control.example.com/api/v1/pods'

        stub_request(:get, %r{\A#{api_url}/})
          .to_return(status: 302, headers: { location: redirect_url })

        stub_request(:get, redirect_url)
          .to_return(status: 200, body: '{}')
      end

      it 'does not follow redirects' do
        expect { method_call(client, method_name) }.to raise_error(Kubeclient::HttpError)
      end
    end
  end

  shared_examples 'dns rebinding not allowed' do |method_name|
    it 'does not allow DNS rebinding' do
      stub_dns(api_url, ip_address: '8.8.8.8')
      client

      stub_dns(api_url, ip_address: '192.168.2.120')
      expect { method_call(client, method_name) }.to raise_error(ArgumentError, /is blocked/)
    end
  end

  describe '.graceful_request' do
    context 'successful' do
      before do
        allow(client).to receive(:foo).and_return(true)
      end

      it 'returns connected status and foo response' do
        result = described_class.graceful_request(1) { client.foo }

        expect(result).to eq({ status: :connected, response: true })
      end
    end

    context 'errored' do
      using RSpec::Parameterized::TableSyntax

      where(:error, :connection_status, :error_status) do
        SocketError                                      | :unreachable            | :connection_error
        OpenSSL::X509::CertificateError                  | :authentication_failure | :authentication_error
        StandardError                                    | :unknown_failure        | :unknown_error
        Kubeclient::HttpError.new(408, "timed out", nil) | :unreachable            | :http_error
        Kubeclient::HttpError.new(408, "timeout", nil)   | :unreachable            | :http_error
        Kubeclient::HttpError.new(408, "", nil)          | :authentication_failure | :http_error
      end

      with_them do
        before do
          allow(client).to receive(:foo).and_raise(error)
        end

        it 'returns error status' do
          result = described_class.graceful_request(1) { client.foo }

          expect(result).to eq({ status: connection_status, connection_error: error_status })
        end
      end
    end
  end

  describe '#initialize' do
    shared_examples 'local address' do
      it 'blocks local addresses' do
        expect { client }.to raise_error(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)
      end

      context 'when local requests are allowed' do
        before do
          stub_application_setting(allow_local_requests_from_web_hooks_and_services: true)
        end

        it 'allows local addresses' do
          expect { client }.not_to raise_error
        end
      end
    end

    context 'localhost address' do
      let(:api_url) { 'http://localhost:22' }

      it_behaves_like 'local address'
    end

    context 'private network address' do
      let(:api_url) { 'http://192.168.1.2:3003' }

      it_behaves_like 'local address'
    end

    context 'when a non HTTP/HTTPS URL is provided' do
      let(:api_url) { 'ssh://192.168.1.2' }

      it 'raises an error' do
        expect { client }.to raise_error(Gitlab::HTTP_V2::UrlBlocker::BlockedUrlError)
      end
    end

    it 'falls back to default options, but allows overriding' do
      client = described_class.new(api_url)
      defaults = Gitlab::Kubernetes::KubeClient::DEFAULT_KUBECLIENT_OPTIONS
      expect(client.kubeclient_options[:timeouts]).to eq(defaults[:timeouts])

      client = described_class.new(api_url, timeouts: { read: 7 })
      expect(client.kubeclient_options[:timeouts][:read]).to eq(7)
      expect(client.kubeclient_options[:timeouts][:open]).to eq(defaults[:timeouts][:open])
    end
  end

  describe '#core_client' do
    subject { client.core_client }

    it_behaves_like 'a Kubeclient'

    it 'has the core API endpoint' do
      expect(subject.api_endpoint.to_s).to match(%r{/api\Z})
    end

    it 'has the api_version' do
      expect(subject.instance_variable_get(:@api_version)).to eq('v1')
    end
  end

  describe '#rbac_client' do
    subject { client.rbac_client }

    it_behaves_like 'a Kubeclient'

    it 'has the RBAC API group endpoint' do
      expect(subject.api_endpoint.to_s).to match(%r{/apis/rbac.authorization.k8s.io\Z})
    end

    it 'has the api_version' do
      expect(subject.instance_variable_get(:@api_version)).to eq('v1')
    end
  end

  describe '#istio_client' do
    subject { client.istio_client }

    it_behaves_like 'a Kubeclient'

    it 'has the Istio API group endpoint' do
      expect(subject.api_endpoint.to_s).to match(%r{/apis/networking.istio.io\Z})
    end

    it 'has the api_version' do
      expect(subject.instance_variable_get(:@api_version)).to eq('v1alpha3')
    end
  end

  describe '#knative_client' do
    subject { client.knative_client }

    it_behaves_like 'a Kubeclient'

    it 'has the extensions API group endpoint' do
      expect(subject.api_endpoint.to_s).to match(%r{/apis/serving.knative.dev\Z})
    end

    it 'has the api_version' do
      expect(subject.instance_variable_get(:@api_version)).to eq('v1alpha1')
    end
  end

  describe '#networking_client' do
    subject { client.networking_client }

    it_behaves_like 'a Kubeclient'

    it 'has the networking API group endpoint' do
      expect(subject.api_endpoint.to_s).to match(%r{/apis/networking.k8s.io\Z})
    end

    it 'has the api_version' do
      expect(subject.instance_variable_get(:@api_version)).to eq('v1')
    end
  end

  describe '#metrics_client' do
    subject { client.metrics_client }

    it_behaves_like 'a Kubeclient'

    it 'has the metrics API group endpoint' do
      expect(subject.api_endpoint.to_s).to match(%r{/apis/metrics.k8s.io\Z})
    end

    it 'has the api_version' do
      expect(subject.instance_variable_get(:@api_version)).to eq('v1beta1')
    end
  end

  describe 'core API' do
    let(:core_client) { client.core_client }

    [
      :get_nodes,
      :get_pods,
      :get_secrets,
      :get_config_map,
      :get_pod,
      :get_namespace,
      :get_secret,
      :get_service,
      :get_service_account,
      :delete_namespace,
      :delete_pod,
      :delete_service_account,
      :create_config_map,
      :create_namespace,
      :create_pod,
      :create_secret,
      :create_service_account,
      :update_config_map,
      :update_secret,
      :update_service_account
    ].each do |method|
      describe "##{method}" do
        include_examples 'redirection not allowed', method
        include_examples 'dns rebinding not allowed', method

        it 'delegates to the core client' do
          expect(client).to delegate_method(method).to(:core_client)
        end

        it 'responds to the method' do
          expect(client).to respond_to method
        end
      end
    end
  end

  describe 'rbac API group' do
    let(:rbac_client) { client.rbac_client }

    [
      :create_role,
      :get_role,
      :update_role,
      :delete_role_binding,
      :update_role_binding,
      :update_cluster_role_binding
    ].each do |method|
      describe "##{method}" do
        include_examples 'redirection not allowed', method
        include_examples 'dns rebinding not allowed', method

        it 'delegates to the rbac client' do
          expect(client).to delegate_method(method).to(:rbac_client)
        end

        it 'responds to the method' do
          expect(client).to respond_to method
        end
      end
    end
  end

  describe 'apps/v1 API group' do
    let(:apps_client) { client.apps_client }

    describe 'get_deployments' do
      include_examples 'redirection not allowed', 'get_deployments'
      include_examples 'dns rebinding not allowed', 'get_deployments'

      it 'delegates to the apps client' do
        expect(client).to delegate_method(:get_deployments).to(:apps_client)
      end

      it 'responds to the method' do
        expect(client).to respond_to :get_deployments
      end
    end
  end

  describe 'networking.k8s.io/v1 API group' do
    let(:networking_client) { client.networking_client }

    [:get_ingresses, :patch_ingress].each do |method|
      describe "##{method}" do
        include_examples 'redirection not allowed', method
        include_examples 'dns rebinding not allowed', method

        it 'delegates to the networking client' do
          expect(client).to delegate_method(method).to(:networking_client)
        end

        it 'responds to the method' do
          expect(client).to respond_to method
        end
      end
    end
  end

  describe 'istio API group' do
    let(:istio_client) { client.istio_client }

    [
      :create_gateway,
      :get_gateway,
      :update_gateway
    ].each do |method|
      describe "##{method}" do
        include_examples 'redirection not allowed', method
        include_examples 'dns rebinding not allowed', method

        it 'delegates to the istio client' do
          expect(client).to delegate_method(method).to(:istio_client)
        end

        it 'responds to the method' do
          expect(client).to respond_to method
        end
      end
    end
  end

  describe 'non-entity methods' do
    it 'does not proxy for non-entity methods' do
      expect(client).not_to respond_to :proxy_url
    end

    it 'throws an error' do
      expect { client.proxy_url }.to raise_error(NoMethodError)
    end
  end

  describe '#get_pod_log' do
    let(:core_client) { client.core_client }

    it 'is delegated to the core client' do
      expect(client).to delegate_method(:get_pod_log).to(:core_client)
    end
  end

  describe '#watch_pod_log' do
    let(:core_client) { client.core_client }

    it 'is delegated to the core client' do
      expect(client).to delegate_method(:watch_pod_log).to(:core_client)
    end
  end

  shared_examples 'create_or_update method using put' do
    let(:update_method) { "update_#{resource_type}" }

    it 'calls the update method' do
      expect(client).to receive(update_method).with(resource)

      subject
    end
  end

  shared_examples 'create_or_update method' do
    let(:get_method) { "get_#{resource_type}" }
    let(:update_method) { "update_#{resource_type}" }
    let(:create_method) { "create_#{resource_type}" }

    context 'resource exists' do
      before do
        expect(client).to receive(get_method).and_return(resource)
      end

      it 'calls the update method' do
        expect(client).to receive(update_method).with(resource)

        subject
      end
    end

    context 'resource does not exist' do
      before do
        expect(client).to receive(get_method).and_raise(Kubeclient::ResourceNotFoundError.new(404, 'Not found', nil))
      end

      it 'calls the create method' do
        expect(client).to receive(create_method).with(resource)

        subject
      end
    end
  end

  describe '#create_or_update_cluster_role_binding' do
    let(:resource_type) { 'cluster_role_binding' }

    let(:resource) do
      ::Kubeclient::Resource.new(metadata: { name: 'name', namespace: 'namespace' })
    end

    subject { client.create_or_update_cluster_role_binding(resource) }

    it_behaves_like 'create_or_update method using put'
  end

  describe '#create_or_update_role_binding' do
    let(:resource_type) { 'role_binding' }

    let(:resource) do
      ::Kubeclient::Resource.new(metadata: { name: 'name', namespace: 'namespace' })
    end

    subject { client.create_or_update_role_binding(resource) }

    it_behaves_like 'create_or_update method using put'
  end

  describe '#create_or_update_service_account' do
    let(:resource_type) { 'service_account' }

    let(:resource) do
      ::Kubeclient::Resource.new(metadata: { name: 'name', namespace: 'namespace' })
    end

    subject { client.create_or_update_service_account(resource) }

    it_behaves_like 'create_or_update method'
  end

  describe '#create_or_update_secret' do
    let(:resource_type) { 'secret' }

    let(:resource) do
      ::Kubeclient::Resource.new(metadata: { name: 'name', namespace: 'namespace' })
    end

    subject { client.create_or_update_secret(resource) }

    it_behaves_like 'create_or_update method'
  end

  describe 'methods that do not exist on any client' do
    it 'throws an error' do
      expect { client.non_existent_method }.to raise_error(NoMethodError)
    end

    it 'returns false for respond_to' do
      expect(client.respond_to?(:non_existent_method)).to be_falsey
    end
  end
end
