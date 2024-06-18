# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PartitioningWorker, feature_category: :ci_scaling do
  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    let(:default_service) { instance_double(Ci::Partitions::SetupDefaultService) }

    it 'calls setup default service' do
      expect(Ci::Partitions::SetupDefaultService).to receive(:new).and_return(default_service)
      expect(default_service).to receive(:execute)

      perform
    end

    context 'when current partition does not exist' do
      before do
        allow(Ci::Partition).to receive(:current).and_return(nil)
      end

      it 'does not call services', :aggregate_failures do
        expect(Ci::Partitions::CreateService).not_to receive(:new)
        expect(Ci::Partitions::SyncService).not_to receive(:new)

        perform
      end
    end

    context 'when current partition exists' do
      let(:create_service) { instance_double(Ci::Partitions::CreateService) }
      let(:sync_service) { instance_double(Ci::Partitions::SyncService) }

      it 'calls create service' do
        expect(Ci::Partitions::CreateService).to receive(:new).and_return(create_service)
        expect(create_service).to receive(:execute)

        perform
      end

      it 'calls sync service' do
        expect(Ci::Partitions::SyncService).to receive(:new).and_return(sync_service)
        expect(sync_service).to receive(:execute)

        perform
      end
    end
  end
end
