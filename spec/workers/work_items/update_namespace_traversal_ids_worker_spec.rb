# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WorkItems::UpdateNamespaceTraversalIdsWorker, feature_category: :portfolio_management do
  let_it_be(:namespace) { create(:group) }

  let(:namespace_id) { namespace.id }
  let(:worker) { described_class.new }

  let(:update_traversal_id_service) { WorkItems::UpdateNamespaceTraversalIdsService }

  it 'has a concurrency limit' do
    expect(::Gitlab::SidekiqMiddleware::ConcurrencyLimit::WorkersMap.limit_for(worker: described_class)).to eq(200)
  end

  describe '#perform' do
    subject(:perform) { worker.perform(namespace_id) }

    before do
      allow(update_traversal_id_service).to receive(:execute)
    end

    it 'calls the service layer logic' do
      worker.perform(namespace_id)

      expect(update_traversal_id_service).to have_received(:execute).with(namespace)
    end

    context 'when the service fails to obtain lock' do
      before do
        allow(update_traversal_id_service).to receive(:execute)
          .and_raise(Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError)
        allow(Gitlab::AppLogger).to receive(:info)
      end

      it 'schedules a new job' do
        expect(described_class).to receive(:perform_in)
          .with(described_class::RETRY_IN_IF_LOCKED, namespace_id)

        expect(Sidekiq.logger).to receive(:info).once.with(
          class: described_class.name,
          message: "Couldn't obtain the lock. Rescheduling the job.",
          namespace_id: namespace_id
        )

        worker.perform(namespace_id)
      end
    end

    context 'when there is no namespace associated with the namespace_id' do
      let(:namespace_id) { non_existing_record_id }

      it 'does not call the service layer logic' do
        perform

        expect(update_traversal_id_service).not_to have_received(:execute)
      end
    end
  end
end
