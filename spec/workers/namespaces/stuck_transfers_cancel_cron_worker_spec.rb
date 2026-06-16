# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::StuckTransfersCancelCronWorker, feature_category: :groups_and_projects do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }

  it_behaves_like 'an idempotent worker'

  describe '#perform' do
    it 'delegates to CancelStuckTransfersService' do
      expect_next_instance_of(Namespaces::CancelStuckTransfersService) do |service|
        expect(service).to receive(:execute)
      end

      worker.perform
    end

    context 'when another instance is already running' do
      before do
        stub_exclusive_lease_taken(described_class.name.underscore, timeout: 30.minutes)
      end

      it 'does not execute the service' do
        expect(Namespaces::CancelStuckTransfersService).not_to receive(:new)

        worker.perform
      end
    end
  end
end
