# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Cells::LostTransactionRecoveryWorker, feature_category: :cell do
  let(:worker) { described_class.new }
  let(:mock_reconciliation_service) { instance_double(Cells::Leases::ReconciliationService) }

  it { is_expected.to be_a(CronjobQueue) }

  it_behaves_like 'an idempotent worker'

  describe '#perform' do
    context 'when cells_claims_leases is disabled' do
      before do
        allow(::Current).to receive(:cells_claims_leases?).and_return(false)
      end

      it 'does not execute reconciliation service' do
        expect(Cells::Leases::ReconciliationService).not_to receive(:new)

        worker.perform
      end
    end

    context 'when cells_claims_leases is enabled' do
      let(:result) do
        {
          processed: 12,
          committed: 7,
          rolled_back: 3,
          pending: 1,
          orphaned: 1
        }
      end

      before do
        allow(::Current).to receive(:cells_claims_leases?).and_return(true)
        allow(Cells::Leases::ReconciliationService).to receive(:new).and_return(mock_reconciliation_service)
        allow(mock_reconciliation_service).to receive(:execute).and_return(result)
      end

      it 'executes the reconciliation service' do
        expect(mock_reconciliation_service).to receive(:execute)

        worker.perform
      end

      it 'logs reconciliation summary with correct counts' do
        expect(worker).to receive(:log_hash_metadata_on_done).with(
          message: 'Lost transaction recovery completed',
          feature_category: :cell,
          processed_leases: 12,
          committed_leases: 7,
          rolled_back_leases: 3,
          pending_leases: 1,
          orphaned_leases: 1
        )

        worker.perform
      end
    end

    context 'when service raises a standard error' do
      let(:error) { StandardError.new('Service failed') }

      before do
        allow(::Current).to receive(:cells_claims_leases?).and_return(true)
        allow(Cells::Leases::ReconciliationService).to receive(:new).and_return(mock_reconciliation_service)
        allow(mock_reconciliation_service).to receive(:execute).and_raise(error)
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(error, hash_including(feature_category: :cell))

        expect { worker.perform }.to raise_error(StandardError)
      end

      it 're-raises the error for Sidekiq retry' do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)

        expect { worker.perform }.to raise_error(StandardError, 'Service failed')
      end

      it 'does not log reconciliation summary' do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)

        expect(Gitlab::AppLogger).not_to receive(:info)

        expect { worker.perform }.to raise_error(StandardError)
      end
    end

    context 'when service raises a GRPC error' do
      let(:grpc_error) { GRPC::Unavailable.new('Service unavailable') }

      before do
        allow(::Current).to receive(:cells_claims_leases?).and_return(true)
        allow(Cells::Leases::ReconciliationService).to receive(:new).and_return(mock_reconciliation_service)
        allow(mock_reconciliation_service).to receive(:execute).and_raise(grpc_error)
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception)
          .with(grpc_error, hash_including(feature_category: :cell))

        expect { worker.perform }.to raise_error(GRPC::Unavailable)
      end

      it 're-raises the error for Sidekiq retry' do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)

        expect { worker.perform }.to raise_error(GRPC::Unavailable, /Service unavailable/)
      end

      it 'does not log reconciliation summary' do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)

        expect(Gitlab::AppLogger).not_to receive(:info)

        expect { worker.perform }.to raise_error(StandardError)
      end
    end
  end
end
