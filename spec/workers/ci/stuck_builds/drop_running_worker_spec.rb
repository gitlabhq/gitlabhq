# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StuckBuilds::DropRunningWorker do
  include ExclusiveLeaseHelpers

  let(:worker_lease_key)  { Ci::StuckBuilds::DropRunningWorker::EXCLUSIVE_LEASE_KEY }
  let(:worker_lease_uuid) { SecureRandom.uuid }
  let(:worker2)           { described_class.new }

  subject(:worker) { described_class.new }

  before do
    stub_exclusive_lease(worker_lease_key, worker_lease_uuid)
  end

  describe '#perform' do
    it_behaves_like 'an idempotent worker'

    it 'executes an instance of Ci::StuckBuilds::DropRunningService' do
      expect_next_instance_of(Ci::StuckBuilds::DropRunningService) do |service|
        expect(service).to receive(:execute).exactly(:once)
      end

      worker.perform
    end

    context 'with an exclusive lease' do
      it 'does not execute concurrently' do
        expect(worker).to receive(:remove_lease).exactly(:once)
        expect(worker2).not_to receive(:remove_lease)

        worker.perform

        stub_exclusive_lease_taken(worker_lease_key)

        worker2.perform
      end

      it 'can execute in sequence' do
        expect(worker).to receive(:remove_lease).at_least(:once)
        expect(worker2).to receive(:remove_lease).at_least(:once)

        worker.perform
        worker2.perform
      end

      it 'cancels exclusive leases after worker perform' do
        expect_to_cancel_exclusive_lease(worker_lease_key, worker_lease_uuid)

        worker.perform
      end

      context 'when the DropRunningService fails' do
        it 'ensures cancellation of the exclusive lease' do
          expect_to_cancel_exclusive_lease(worker_lease_key, worker_lease_uuid)

          allow_next_instance_of(Ci::StuckBuilds::DropRunningService) do |service|
            expect(service).to receive(:execute) do
              raise 'The query timed out'
            end
          end

          expect { worker.perform }.to raise_error(/The query timed out/)
        end
      end
    end
  end
end
