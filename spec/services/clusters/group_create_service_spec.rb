require 'spec_helper'

describe Clusters::GroupCreateService do
  let(:access_token) { 'xxx' }
  let(:group) { create(:group) }
  let(:user) { create(:user) }

  subject { described_class.new(group, user, params).execute(access_token) }

  context 'when provider is gcp' do
    context 'when group has no clusters' do
      context 'when correct params' do
        include_context 'valid cluster create params'

        before do
          stub_feature_flags(rbac_clusters: false)
        end

        it 'creates a cluster object and performs a worker' do
          expect(ClusterProvisionWorker).to receive(:perform_async)

          expect { subject }
            .to change { Clusters::Cluster.count }.by(1)
            .and change { Clusters::Providers::Gcp.count }.by(1)

          expect(subject.name).to eq('test-cluster')
          expect(subject.user).to eq(user)
          expect(subject.groups).to eq([group])
          expect(subject.provider.gcp_project_id).to eq('gcp-project')
          expect(subject.provider.zone).to eq('us-central1-a')
          expect(subject.provider.num_nodes).to eq(1)
          expect(subject.provider.machine_type).to eq('machine_type-a')
          expect(subject.provider.access_token).to eq(access_token)
          expect(subject.provider).to be_legacy_abac
          expect(subject.platform).to be_nil
        end
      end

      context 'when invalid params' do
        include_context 'invalid cluster create params'

        include_examples 'create cluster service error'
      end
    end

    context 'when group has a cluster' do
      include_context 'valid cluster create params'
      let!(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, groups: [group]) }

      it 'does not create a cluster' do
        expect(ClusterProvisionWorker).not_to receive(:perform_async)
        expect { subject }.to raise_error(ArgumentError).and change { Clusters::Cluster.count }.by(0)
      end
    end
  end
end
