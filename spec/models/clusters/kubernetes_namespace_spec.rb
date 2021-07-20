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

  describe '.with_environment_name' do
    let(:cluster) { create(:cluster, :group) }
    let(:environment) { create(:environment, name: name) }

    let(:name) { 'production' }

    subject { described_class.with_environment_name(name) }

    context 'there is no associated environment' do
      let!(:namespace) { create(:cluster_kubernetes_namespace, cluster: cluster, project: environment.project) }

      it { is_expected.to be_empty }
    end

    context 'there is an assicated environment' do
      let!(:namespace) do
        create(
          :cluster_kubernetes_namespace,
          cluster: cluster,
          project: environment.project,
          environment: environment
        )
      end

      context 'with a matching name' do
        it { is_expected.to eq [namespace] }
      end

      context 'without a matching name' do
        let(:environment) { create(:environment, name: 'staging') }

        it { is_expected.to be_empty }
      end
    end
  end

  describe 'namespace uniqueness validation' do
    let_it_be(:cluster) { create(:cluster, :project, :provided_by_gcp) }

    let(:kubernetes_namespace) { build(:cluster_kubernetes_namespace, cluster: cluster, namespace: 'my-namespace') }

    subject { kubernetes_namespace }

    context 'when cluster is using the namespace' do
      before do
        create(:cluster_kubernetes_namespace,
               cluster: kubernetes_namespace.cluster,
               environment: kubernetes_namespace.environment,
               namespace: 'my-namespace')
      end

      it { is_expected.not_to be_valid }
    end

    context 'when cluster is not using the namespace' do
      it { is_expected.to be_valid }
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
