require 'spec_helper'

describe Clusters::CreateService do
  let(:access_token) { 'xxx' }
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject { described_class.new(project, user, params).execute(access_token) }

  context 'when provider is gcp' do
    shared_context 'valid params' do
      let(:params) do
        {
          name: 'test-cluster',
          provider_type: :gcp,
          provider_gcp_attributes: {
            gcp_project_id: 'gcp-project',
            zone: 'us-central1-a',
            num_nodes: 1,
            machine_type: 'machine_type-a'
          }
        }
      end
    end

    shared_context 'invalid params' do
      let(:params) do
        {
          name: 'test-cluster',
          provider_type: :gcp,
          provider_gcp_attributes: {
            gcp_project_id: '!!!!!!!',
            zone: 'us-central1-a',
            num_nodes: 1,
            machine_type: 'machine_type-a'
          }
        }
      end
    end

    shared_examples 'create cluster' do
      it 'creates a cluster object and performs a worker' do
        expect(ClusterProvisionWorker).to receive(:perform_async)

        expect { subject }
          .to change { Clusters::Cluster.count }.by(1)
          .and change { Clusters::Providers::Gcp.count }.by(1)

        expect(subject.name).to eq('test-cluster')
        expect(subject.user).to eq(user)
        expect(subject.project).to eq(project)
        expect(subject.provider.gcp_project_id).to eq('gcp-project')
        expect(subject.provider.zone).to eq('us-central1-a')
        expect(subject.provider.num_nodes).to eq(1)
        expect(subject.provider.machine_type).to eq('machine_type-a')
        expect(subject.provider.access_token).to eq(access_token)
        expect(subject.platform).to be_nil
      end
    end

    shared_examples 'error' do
      it 'returns an error' do
        expect(ClusterProvisionWorker).not_to receive(:perform_async)
        expect { subject }.to change { Clusters::Cluster.count }.by(0)
        expect(subject.errors[:"provider_gcp.gcp_project_id"]).to be_present
      end
    end

    context 'when project has no clusters' do
      context 'when correct params' do
        include_context 'valid params'

        include_examples 'create cluster'
      end

      context 'when invalid params' do
        include_context 'invalid params'

        include_examples 'error'
      end
    end

    context 'when project has a cluster' do
      let!(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, projects: [project]) }

      before do
        allow(project).to receive(:feature_available?).and_call_original
      end

      context 'when license has multiple clusters feature' do
        before do
          allow(project).to receive(:feature_available?).with(:multiple_clusters).and_return(true)
        end

        context 'when correct params' do
          include_context 'valid params'

          include_examples 'create cluster'
        end

        context 'when invalid params' do
          include_context 'invalid params'

          include_examples 'error'
        end
      end

      context 'when license does not have multiple clusters feature' do
        include_context 'valid params'

        before do
          allow(project).to receive(:feature_available?).with(:multiple_clusters).and_return(false)
        end

        it 'does not create a cluster' do
          expect(ClusterProvisionWorker).not_to receive(:perform_async)
          expect { subject }.to raise_error(ArgumentError).and change { Clusters::Cluster.count }.by(0)
        end
      end
    end
  end
end
