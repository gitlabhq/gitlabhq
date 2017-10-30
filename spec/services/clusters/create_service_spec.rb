require 'spec_helper'

describe Clusters::CreateService do
  let(:access_token) { 'xxx' }
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:result) { described_class.new(project, user, params).execute(access_token) }

  context 'when correct params' do
    let(:params) do
      {
        name: 'test-cluster',
        platform_type: :kubernetes,
        provider_type: :gcp,
        platform_kubernetes_attributes: {
          namespace: 'custom-namespace'
        },
        provider_gcp_attributes: {
          gcp_project_id: 'gcp-project',
          zone: 'us-central1-a',
          num_nodes: 1,
          machine_type: 'machine_type-a'
        }
      }
    end

    it 'creates a cluster object and performs a worker' do
      expect(ClusterProvisionWorker).to receive(:perform_async)
      expect { result }.to change { Clusters::Cluster.count }.by(1)
      expect(result.name).to eq('test-cluster')
      expect(result.user).to eq(user)
      expect(result.project).to eq(project)
      expect(result.provider.gcp_project_id).to eq('gcp-project')
      expect(result.provider.zone).to eq('us-central1-a')
      expect(result.provider.num_nodes).to eq(1)
      expect(result.provider.machine_type).to eq('machine_type-a')
      expect(result.provider.access_token).to eq(access_token)
      expect(result.platform.namespace).to eq('custom-namespace')
    end
  end

  context 'when invalid params' do
    let(:params) do
      {
        name: 'test-cluster',
        platform_type: :kubernetes,
        provider_type: :user,
        provider_gcp_attributes: {
          gcp_project_id: 'gcp-project',
          zone: 'us-central1-a',
          num_nodes: 'ABC'
        }
      }
    end

    it 'returns an error' do
      expect(ClusterProvisionWorker).not_to receive(:perform_async)
      expect { result }.to change { Clusters::Cluster.count }.by(0)
      expect(result.errors[:"provider_gcp.num_nodes"]).to be_present
    end
  end
end
