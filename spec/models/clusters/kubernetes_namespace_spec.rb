# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::KubernetesNamespace, type: :model do
  it { is_expected.to belong_to(:cluster_project) }
  it { is_expected.to belong_to(:project) }
  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to have_one(:platform_kubernetes) }

  describe 'has_service_account_token' do
    subject { described_class.has_service_account_token }

    context 'namespace has service_account_token' do
      let!(:namespace) { create(:cluster_kubernetes_namespace, :with_token) }

      it { is_expected.to include(namespace) }
    end

    context 'namespace has no service_account_token' do
      let!(:namespace) { create(:cluster_kubernetes_namespace) }

      it { is_expected.not_to include(namespace) }
    end
  end

  describe 'namespace uniqueness validation' do
    let(:cluster_project) { create(:cluster_project) }
    let(:kubernetes_namespace) { build(:cluster_kubernetes_namespace, namespace: 'my-namespace') }

    subject { kubernetes_namespace }

    context 'when cluster is using the namespace' do
      before do
        create(:cluster_kubernetes_namespace,
               cluster: kubernetes_namespace.cluster,
               namespace: 'my-namespace')
      end

      it { is_expected.not_to be_valid }
    end

    context 'when cluster is not using the namespace' do
      it { is_expected.to be_valid }
    end
  end

  describe '#set_defaults' do
    let(:kubernetes_namespace) { build(:cluster_kubernetes_namespace) }
    let(:cluster) { kubernetes_namespace.cluster }
    let(:platform) { kubernetes_namespace.platform_kubernetes }

    subject { kubernetes_namespace.set_defaults }

    describe '#namespace' do
      before do
        platform.update_column(:namespace, namespace)
      end

      context 'when platform has a namespace assigned' do
        let(:namespace) { 'platform-namespace' }

        it 'copies the namespace' do
          subject

          expect(kubernetes_namespace.namespace).to eq('platform-namespace')
        end
      end

      context 'when platform does not have namespace assigned' do
        let(:project) { kubernetes_namespace.project }
        let(:namespace) { nil }
        let(:project_slug) { "#{project.path}-#{project.id}" }

        it 'fallbacks to project namespace' do
          subject

          expect(kubernetes_namespace.namespace).to eq(project_slug)
        end
      end
    end

    describe '#service_account_name' do
      let(:service_account_name) { "#{kubernetes_namespace.namespace}-service-account" }

      it 'sets a service account name based on namespace' do
        subject

        expect(kubernetes_namespace.service_account_name).to eq(service_account_name)
      end
    end
  end

  describe '#predefined_variables' do
    let(:kubernetes_namespace) { create(:cluster_kubernetes_namespace, cluster: cluster, service_account_token: token) }
    let(:cluster) { create(:cluster, :project, platform_kubernetes: platform) }
    let(:platform) { create(:cluster_platform_kubernetes, api_url: api_url, ca_cert: ca_pem, token: token) }

    let(:api_url) { 'https://kube.domain.com' }
    let(:ca_pem) { File.read(Rails.root.join('spec/fixtures/clusters/sample_cert.pem')) }
    let(:token) { 'token' }

    let(:kubeconfig) do
      config_file = expand_fixture_path('config/kubeconfig.yml')
      config = YAML.safe_load(File.read(config_file))
      config.dig('users', 0, 'user')['token'] = token
      config.dig('contexts', 0, 'context')['namespace'] = kubernetes_namespace.namespace
      config.dig('clusters', 0, 'cluster')['certificate-authority-data'] =
        Base64.strict_encode64(ca_pem)

      YAML.dump(config)
    end

    it 'sets the variables' do
      expect(kubernetes_namespace.predefined_variables).to include(
        { key: 'KUBE_SERVICE_ACCOUNT', value: kubernetes_namespace.service_account_name, public: true },
        { key: 'KUBE_NAMESPACE', value: kubernetes_namespace.namespace, public: true },
        { key: 'KUBE_TOKEN', value: kubernetes_namespace.service_account_token, public: false, masked: true },
        { key: 'KUBECONFIG', value: kubeconfig, public: false, file: true }
      )
    end
  end
end
