require 'spec_helper'

describe WaitForClusterCreationWorker do
  describe '#perform' do
    context 'when cluster exists' do
      let(:cluster) { create(:gcp_cluster) }

      it 'fetches gcp operation status' do
        expect_any_instance_of(Ci::FetchGcpOperationService).to receive(:execute)

        described_class.new.perform(cluster.id)
      end

      # TODO: context 'when operation.status is runnning'
    end

    context 'when cluster does not exist' do
      it 'does not provision a cluster' do
        expect_any_instance_of(Ci::FetchGcpOperationService).to receive(:execute).with(nil)

        described_class.new.perform(123)
      end
    end
  end
end
