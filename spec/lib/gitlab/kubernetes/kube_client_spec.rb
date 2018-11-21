# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Kubernetes::KubeClient do
  include KubernetesHelpers

  let(:api_url) { 'https://kubernetes.example.com/prefix' }
  let(:kubeclient_options) { { auth_options: { bearer_token: 'xyz' } } }

  let(:client) { described_class.new(api_url, kubeclient_options) }

  before do
    stub_kubeclient_discover(api_url)
  end

  shared_examples 'a Kubeclient' do
    it 'is a Kubeclient::Client' do
      is_expected.to be_an_instance_of Kubeclient::Client
    end

    it 'has the kubeclient options' do
      expect(subject.auth_options).to eq({ bearer_token: 'xyz' })
    end
  end

  describe '#core_client' do
    subject { client.core_client }

    it_behaves_like 'a Kubeclient'

    it 'has the core API endpoint' do
      expect(subject.api_endpoint.to_s).to match(%r{\/api\Z})
    end

    it 'has the api_version' do
      expect(subject.instance_variable_get(:@api_version)).to eq('v1')
    end
  end

  describe '#rbac_client' do
    subject { client.rbac_client }

    it_behaves_like 'a Kubeclient'

    it 'has the RBAC API group endpoint' do
      expect(subject.api_endpoint.to_s).to match(%r{\/apis\/rbac.authorization.k8s.io\Z})
    end

    it 'has the api_version' do
      expect(subject.instance_variable_get(:@api_version)).to eq('v1')
    end
  end

  describe '#extensions_client' do
    subject { client.extensions_client }

    it_behaves_like 'a Kubeclient'

    it 'has the extensions API group endpoint' do
      expect(subject.api_endpoint.to_s).to match(%r{\/apis\/extensions\Z})
    end

    it 'has the api_version' do
      expect(subject.instance_variable_get(:@api_version)).to eq('v1beta1')
    end
  end

  describe '#knative_client' do
    subject { client.knative_client }

    it_behaves_like 'a Kubeclient'

    it 'has the extensions API group endpoint' do
      expect(subject.api_endpoint.to_s).to match(%r{\/apis\/serving.knative.dev\Z})
    end

    it 'has the api_version' do
      expect(subject.instance_variable_get(:@api_version)).to eq('v1alpha1')
    end
  end

  describe 'core API' do
    let(:core_client) { client.core_client }

    [
      :get_pods,
      :get_secrets,
      :get_config_map,
      :get_pod,
      :get_namespace,
      :get_secret,
      :get_service,
      :get_service_account,
      :delete_pod,
      :create_config_map,
      :create_namespace,
      :create_pod,
      :create_secret,
      :create_service_account,
      :update_config_map,
      :update_service_account
    ].each do |method|
      describe "##{method}" do
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
      :create_cluster_role_binding,
      :get_cluster_role_binding,
      :update_cluster_role_binding
    ].each do |method|
      describe "##{method}" do
        it 'delegates to the rbac client' do
          expect(client).to delegate_method(method).to(:rbac_client)
        end

        it 'responds to the method' do
          expect(client).to respond_to method
        end
      end
    end
  end

  describe 'extensions API group' do
    let(:api_groups) { ['apis/extensions'] }
    let(:extensions_client) { client.extensions_client }

    describe '#get_deployments' do
      it 'delegates to the extensions client' do
        expect(client).to delegate_method(:get_deployments).to(:extensions_client)
      end

      it 'responds to the method' do
        expect(client).to respond_to :get_deployments
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

  describe 'methods that do not exist on any client' do
    it 'throws an error' do
      expect { client.non_existent_method }.to raise_error(NoMethodError)
    end

    it 'returns false for respond_to' do
      expect(client.respond_to?(:non_existent_method)).to be_falsey
    end
  end
end
