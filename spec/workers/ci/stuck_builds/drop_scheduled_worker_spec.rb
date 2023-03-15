# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::StuckBuilds::DropScheduledWorker, feature_category: :continuous_integration do
  include ExclusiveLeaseHelpers

  let(:worker)     { described_class.new }
  let(:lease_uuid) { SecureRandom.uuid }

  describe '#perform' do
    subject { worker.perform }

    it_behaves_like 'an idempotent worker'

    it 'executes an instance of Ci::StuckBuilds::DropScheduledService with an exclusive lease' do
      expect_to_obtain_exclusive_lease(worker.lease_key, lease_uuid)

      expect_next_instance_of(Ci::StuckBuilds::DropScheduledService) do |service|
        expect(service).to receive(:execute).exactly(:once)
      end

      expect_to_cancel_exclusive_lease(worker.lease_key, lease_uuid)

      subject
    end
  end
end
