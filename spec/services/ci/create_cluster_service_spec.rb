require 'spec_helper'

describe Ci::CreateClusterService do
  describe '#execute' do
    let(:access_token) { 'xxx' }
    let(:project) { create(:project) }
    let(:user) { create(:user) }
    let(:result) { described_class.new(project, user, params).execute(access_token) }

    context 'when correct params' do
      let(:params) do
        {
          gcp_project_id: 'gcp-project',
          gcp_cluster_name: 'test-cluster',
          gcp_cluster_zone: 'us-central1-a',
          gcp_cluster_size: 1
        }
      end

      it 'creates a cluster object' do
        expect(ClusterProvisionWorker).to receive(:perform_async)
        expect { result }.to change { Gcp::Cluster.count }.by(1)
        expect(result.gcp_project_id).to eq('gcp-project')
        expect(result.gcp_cluster_name).to eq('test-cluster')
        expect(result.gcp_cluster_zone).to eq('us-central1-a')
        expect(result.gcp_cluster_size).to eq(1)
        expect(result.gcp_token).to eq(access_token)
      end
    end

    context 'when invalid params' do
      let(:params) do
        {
          gcp_project_id: 'gcp-project',
          gcp_cluster_name: 'test-cluster',
          gcp_cluster_zone: 'us-central1-a',
          gcp_cluster_size: 'ABC'
        }
      end

      it 'returns an error' do
        expect(ClusterProvisionWorker).not_to receive(:perform_async)
        expect { result }.to change { Gcp::Cluster.count }.by(0)
      end
    end
  end
end
