# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StuckCiJobsWorker do
  include ExclusiveLeaseHelpers

  let(:worker_lease_key)  { StuckCiJobsWorker::EXCLUSIVE_LEASE_KEY }
  let(:worker_lease_uuid) { SecureRandom.uuid }
  let(:worker2)           { described_class.new }

  subject(:worker) { described_class.new }

  before do
    stub_exclusive_lease(worker_lease_key, worker_lease_uuid)
  end

  describe '#perform' do
    it 'enqueues a Ci::StuckBuilds::DropRunningWorker job' do
      expect(Ci::StuckBuilds::DropRunningWorker).to receive(:perform_in).with(20.minutes).exactly(:once)

      worker.perform
    end

    it 'enqueues a Ci::StuckBuilds::DropScheduledWorker job' do
      expect(Ci::StuckBuilds::DropScheduledWorker).to receive(:perform_in).with(40.minutes).exactly(:once)

      worker.perform
    end

    it 'executes an instance of Ci::StuckBuilds::DropService' do
      expect_next_instance_of(Ci::StuckBuilds::DropService) do |service|
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

      context 'when the DropService fails' do
        it 'ensures cancellation of the exclusive lease' do
          expect_to_cancel_exclusive_lease(worker_lease_key, worker_lease_uuid)

          allow_next_instance_of(Ci::StuckBuilds::DropService) do |service|
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
