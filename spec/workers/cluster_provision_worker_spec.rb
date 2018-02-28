require 'spec_helper'

describe ClusterProvisionWorker do
  describe '#perform' do
    context 'when cluster exists' do
      let(:cluster) { create(:gcp_cluster) }

      it 'provision a cluster' do
        expect_any_instance_of(Ci::ProvisionClusterService).to receive(:execute)

        described_class.new.perform(cluster.id)
      end
    end

    context 'when cluster does not exist' do
      it 'does not provision a cluster' do
        expect_any_instance_of(Ci::ProvisionClusterService).not_to receive(:execute)

        described_class.new.perform(123)
      end
    end
  end
end
