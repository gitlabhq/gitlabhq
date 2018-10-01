# frozen_string_literal: true

require 'spec_helper'

describe Clusters::Kubernetes::ConfigureService, '#execute' do
  let(:platform) { create(:cluster_platform_kubernetes) }
  let(:kubeclient) { platform.kubeclient }
  let(:service) { described_class.new(platform) }

  subject { service.execute }

  shared_examples 'creates a kubernetes namespace' do
    before do
      platform.cluster.projects << project

      allow(kubeclient).to receive(:get_namespace).and_return(nil)
      allow(kubeclient).to receive(:create_namespace).and_return(nil)
    end

    it 'creates a kubernetes namespace' do
      expect(kubeclient).to receive(:get_namespace).once.ordered
      expect(kubeclient).to receive(:create_namespace).once.ordered

      subject
    end

    it 'saves namespace and service account into database' do
      subject

      expect(cluster_project.namespace).to eq(namespace_name)
      expect(cluster_project.service_account_name).to eq(service_account_name)
    end
  end

  context 'no project' do
    it { is_expected.to be_nil }
  end

  context 'when platform has namespace' do
    let(:platform) { create(:cluster_platform_kubernetes, namespace: 'my-namespace') }
    let(:project) { create(:project, name: 'hello') }
    let(:cluster_project) { project.cluster_project }

    it_behaves_like 'creates a kubernetes namespace' do
      let(:namespace_name) { 'my-namespace' }
      let(:service_account_name) { 'gitlab' }
    end

    context 'when platform is RBAC' do
      let(:platform) { create(:cluster_platform_kubernetes, :rbac_enabled, namespace: 'my-namespace') }

      it_behaves_like 'creates a kubernetes namespace' do
        let(:namespace_name) { 'my-namespace' }
        let(:service_account_name) { 'gitlab-my-namespace' }
      end
    end
  end

  context 'when cluster has project related' do
    let(:project) { create(:project, name: 'hello') }
    let(:cluster_project) { project.cluster_project }

    it_behaves_like 'creates a kubernetes namespace' do
      let(:namespace_name) { "hello-#{project.id}" }
      let(:service_account_name) { 'gitlab' }
    end
  end
end
