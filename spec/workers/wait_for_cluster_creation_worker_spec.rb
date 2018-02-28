require 'spec_helper'

describe WaitForClusterCreationWorker do
  describe '#perform' do
    context 'when cluster exists' do
      let(:cluster) { create(:gcp_cluster) }
      let(:operation) { double }

      before do
        allow(operation).to receive(:status).and_return(status)
        allow(operation).to receive(:start_time).and_return(1.minute.ago)
        allow(operation).to receive(:status_message).and_return('error')
        allow_any_instance_of(Ci::FetchGcpOperationService).to receive(:execute).and_yield(operation)
      end

      context 'when operation status is RUNNING' do
        let(:status) { 'RUNNING' }

        it 'reschedules worker' do
          expect(described_class).to receive(:perform_in)

          described_class.new.perform(cluster.id)
        end

        context 'when operation timeout' do
          before do
            allow(operation).to receive(:start_time).and_return(30.minutes.ago.utc)
          end

          it 'sets an error message on cluster' do
            described_class.new.perform(cluster.id)

            expect(cluster.reload).to be_errored
          end
        end
      end

      context 'when operation status is DONE' do
        let(:status) { 'DONE' }

        it 'finalizes cluster creation' do
          expect_any_instance_of(Ci::FinalizeClusterCreationService).to receive(:execute)

          described_class.new.perform(cluster.id)
        end
      end

      context 'when operation status is others' do
        let(:status) { 'others' }

        it 'sets an error message on cluster' do
          described_class.new.perform(cluster.id)

          expect(cluster.reload).to be_errored
        end
      end
    end

    context 'when cluster does not exist' do
      it 'does not provision a cluster' do
        expect_any_instance_of(Ci::FetchGcpOperationService).not_to receive(:execute)

        described_class.new.perform(1234)
      end
    end
  end
end
