# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StuckCiJobsWorker, feature_category: :continuous_integration do
  include ExclusiveLeaseHelpers

  let(:worker)     { described_class.new }
  let(:lease_uuid) { SecureRandom.uuid }

  describe '#perform' do
    subject { worker.perform }

    it 'enqueues a Ci::StuckBuilds::DropRunningWorker job' do
      expect(Ci::StuckBuilds::DropRunningWorker).to receive(:perform_in).with(15.minutes).exactly(:once)

      subject
    end

    it 'enqueues a Ci::StuckBuilds::DropScheduledWorker job' do
      expect(Ci::StuckBuilds::DropScheduledWorker).to receive(:perform_in).with(30.minutes).exactly(:once)

      subject
    end

    it 'enqueues a Ci::StuckBuilds::DropCancelingWorker job' do
      expect(Ci::StuckBuilds::DropCancelingWorker).to receive(:perform_in).with(45.minutes).exactly(:once)

      subject
    end

    it 'executes an instance of Ci::StuckBuilds::DropPendingService' do
      expect_to_obtain_exclusive_lease(worker.lease_key, lease_uuid)

      expect_next_instance_of(Ci::StuckBuilds::DropPendingService) do |service|
        expect(service).to receive(:execute).exactly(:once)
      end

      expect_to_cancel_exclusive_lease(worker.lease_key, lease_uuid)

      subject
    end
  end
end
