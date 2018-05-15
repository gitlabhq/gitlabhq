require 'spec_helper'

describe Clusters::CreateService do
  let(:access_token) { 'xxx' }
  let(:project) { create(:project) }
  let(:user) { create(:user) }

  subject { described_class.new(project, user, params).execute(access_token) }

  context 'when provider is gcp' do
    context 'when project has no clusters' do
      context 'when correct params' do
        include_context 'valid cluster create params'

        include_examples 'create cluster service success'
      end

      context 'when invalid params' do
        include_context 'invalid cluster create params'

        include_examples 'create cluster service error'
      end
    end

    context 'when project has a cluster' do
      include_context 'valid cluster create params'
      let!(:cluster) { create(:cluster, :provided_by_gcp, :production_environment, projects: [project]) }

      it 'does not create a cluster' do
        expect(ClusterProvisionWorker).not_to receive(:perform_async)
        expect { subject }.to raise_error(ArgumentError).and change { Clusters::Cluster.count }.by(0)
      end
    end
  end
end
