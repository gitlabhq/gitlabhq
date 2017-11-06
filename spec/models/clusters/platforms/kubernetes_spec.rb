require 'spec_helper'

describe Clusters::Platforms::Kubernetes, :use_clean_rails_memory_store_caching do
  include KubernetesHelpers
  include ReactiveCachingHelpers

  it { is_expected.to belong_to(:cluster) }
  it { is_expected.to respond_to :ca_pem }

  describe 'before_validation' do
    context 'when namespace includes upper case' do
      let(:kubernetes) { create(:cluster_platform_kubernetes, :configured, namespace: namespace) }
      let(:namespace) { 'ABC' }

      it 'converts to lower case' do
        expect(kubernetes.namespace).to eq('abc')
      end
    end
  end

  describe 'validation' do
    subject { kubernetes.valid? }

    context 'when validates namespace' do
      let(:kubernetes) { build(:cluster_platform_kubernetes, :configured, namespace: namespace) }

      context 'when namespace is blank' do
        let(:namespace) { '' }

        it { is_expected.to be_truthy }
      end

      context 'when namespace is longer than 63' do
        let(:namespace) { 'a' * 64 }

        it { is_expected.to be_falsey }
      end

      context 'when namespace includes invalid character' do
        let(:namespace) { '!!!!!!' }

        it { is_expected.to be_falsey }
      end

      context 'when namespace is vaild' do
        let(:namespace) { 'namespace-123' }

        it { is_expected.to be_truthy }
      end
    end

    context 'when validates api_url' do
      let(:kubernetes) { build(:cluster_platform_kubernetes, :configured) }

      before do
        kubernetes.api_url = api_url
      end

      context 'when api_url is invalid url' do
        let(:api_url) { '!!!!!!' }

        it { expect(kubernetes.save).to be_falsey }
      end

      context 'when api_url is nil' do
        let(:api_url) { nil }

        it { expect(kubernetes.save).to be_falsey }
      end

      context 'when api_url is valid url' do
        let(:api_url) { 'https://111.111.111.111' }

        it { expect(kubernetes.save).to be_truthy }
      end
    end

    context 'when validates token' do
      let(:kubernetes) { build(:cluster_platform_kubernetes, :configured) }

      before do
        kubernetes.token = token
      end

      context 'when token is nil' do
        let(:token) { nil }

        it { expect(kubernetes.save).to be_falsey }
      end
    end
  end

  describe 'after_save from Clusters::Cluster' do
    context 'when platform_kubernetes is being cerated' do
      let(:enabled) { true }
      let(:project) { create(:project) }
      let(:cluster) { build(:cluster, provider_type: :gcp, platform_type: :kubernetes, platform_kubernetes: platform, provider_gcp: provider, enabled: enabled, projects: [project]) }
      let(:platform) { build(:cluster_platform_kubernetes, :configured) }
      let(:provider) { build(:cluster_provider_gcp) }
      let(:kubernetes_service) { project.kubernetes_service }

      it 'updates KubernetesService' do
        cluster.save!

        expect(kubernetes_service.active).to eq(enabled)
        expect(kubernetes_service.api_url).to eq(platform.api_url)
        expect(kubernetes_service.namespace).to eq(platform.namespace)
        expect(kubernetes_service.ca_pem).to eq(platform.ca_cert)
      end
    end

    context 'when platform_kubernetes has been created' do
      let(:enabled) { false }
      let!(:project) { create(:project) }
      let!(:cluster) { create(:cluster, :provided_by_gcp, projects: [project]) }
      let(:platform) { cluster.platform }
      let(:kubernetes_service) { project.kubernetes_service }

      it 'updates KubernetesService' do
        cluster.update(enabled: enabled)

        expect(kubernetes_service.active).to eq(enabled)
      end
    end

    context 'when kubernetes_service has been configured without cluster integration' do
      let!(:project) { create(:project) }
      let(:cluster) { build(:cluster, provider_type: :gcp, platform_type: :kubernetes, platform_kubernetes: platform, provider_gcp: provider, projects: [project]) }
      let(:platform) { build(:cluster_platform_kubernetes, :configured, api_url: 'https://111.111.111.111') }
      let(:provider) { build(:cluster_provider_gcp) }

      before do
        create(:kubernetes_service, project: project)
      end

      it 'raises an error' do
        expect { cluster.save! }.to raise_error('Kubernetes service already configured')
      end
    end
  end

  describe '#actual_namespace' do
    subject { kubernetes.actual_namespace }

    let!(:cluster) { create(:cluster, :project, platform_kubernetes: kubernetes) }
    let(:project) { cluster.project }
    let(:kubernetes) { create(:cluster_platform_kubernetes, :configured, namespace: namespace) }

    context 'when namespace is present' do
      let(:namespace) { 'namespace-123' }

      it { is_expected.to eq(namespace) }
    end

    context 'when namespace is not present' do
      let(:namespace) { nil }

      it { is_expected.to eq("#{project.path}-#{project.id}") }
    end
  end

  describe '.namespace_for_project' do
    subject { described_class.namespace_for_project(project) }

    let(:project) { create(:project) }

    it { is_expected.to eq("#{project.path}-#{project.id}") }
  end

  describe '#default_namespace' do
    subject { kubernetes.default_namespace }

    let(:kubernetes) { create(:cluster_platform_kubernetes, :configured) }

    context 'when cluster belongs to a project' do
      let!(:cluster) { create(:cluster, :project, platform_kubernetes: kubernetes) }
      let(:project) { cluster.project }

      it { is_expected.to eq("#{project.path}-#{project.id}") }
    end

    context 'when cluster belongs to nothing' do
      let!(:cluster) { create(:cluster, platform_kubernetes: kubernetes) }

      it { is_expected.to be_nil }
    end
  end
end
